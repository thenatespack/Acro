import Engine
import Foundation

// The editor's game module: game code loaded from a dynamic library (see
// Sources/Engine/GameModule/GameModule.swift) and reloaded with the scene kept.
//
// Where it comes from: `--game <target | module.dylib>` or the open project's `Project.json`
// (`"game": {"target": "MyGame", "package": ".."}`), `--game` winning. A target is built with
// `swift build --target` and its objects linked into a module (`GameModuleBuilder`); a library
// is loaded as it is (after its `buildCommand`, if any).
//
// Loading registers the module's components with `ComponentRegistry` and the Add Component
// catalog and turns any of the scene's `UnresolvedComponents` with those names into real
// components. Its systems are added to the world when play starts and removed on stop.
//
// Reloading ("Reload Game Code", `game.reload`):
// 1. Build (in the background; the editor keeps running) and link the new module, then load it
//    under a unique name. A failure stops here: the old module keeps running, the build's errors
//    go to the console.
// 2. Take the old module out: its systems leave the world, and every component of its types,
//    in the live world and (while playing) in the play-mode snapshot, is serialized through the
//    registry into `UnresolvedComponents` JSON (`World.detachComponents(named:)`); its types
//    are unregistered. Entities, handles, ids, hierarchy, other components and the play state
//    stay as they are.
// 3. Register the new module's types and decode the JSON back
//    (`World.resolveUnresolvedComponents(defaults:)`): fields that are new take the default
//    component's values, removed fields are dropped, a field whose type changed is reset.
//    Components whose type is gone stay JSON (saved unchanged, shown in the inspector) and are
//    reported. While playing, the new systems are added and the game goes on.
// 4. The undo history is cleared (its steps hold values of the old types); unsaved changes
//    stay unsaved.
//
// The old library stays mapped but unused (see `LoadedGameModule`).

/// What loading or reloading a game module did (`game.reload`, `game.load`).
public struct GameReloadReport: Codable, Equatable, Sendable {
    /// The module's name.
    public var module: String
    /// Its component types and systems.
    public var components: [String]
    public var systems: [String]
    /// Component types this version added, and the ones it dropped (their data is kept as
    /// JSON: name → entities holding it).
    public var added: [String]
    public var removed: [String: Int]
    /// Components decoded back into the new types (scene and play snapshot).
    public var restored: Int
    /// Per component: fields reset to the default because the saved value no longer decodes.
    public var resetFields: [String: [String]]
    /// Per component: why it couldn't be decoded (kept as JSON).
    public var failed: [String: String]
    public var warnings: [String]
    /// Whether it was built first; build and link times (nil when not done); load (map and
    /// register) and swap (snapshot, unload, restore) times; all in seconds.
    public var built: Bool
    public var buildSeconds: Double?
    public var linkSeconds: Double?
    public var loadSeconds: Double
    public var swapSeconds: Double
    public var totalSeconds: Double
    /// Whether the game was playing (it kept playing).
    public var playing: Bool
}

/// The game module the editor has loaded, and its reloading (see the notes above).
@MainActor
public final class EditorGameModule {
    unowned let session: EditorSession
    /// Where the module comes from; nil: no game.
    public private(set) var settings: GameModuleSettings?
    /// The folder relative paths in `settings` resolve against.
    public private(set) var baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    /// From `--game`: wins over a project's setting.
    public var commandLineSettings: GameModuleSettings?
    /// The loaded module, if any.
    public private(set) var loaded: LoadedGameModule?
    /// The last load or reload's report.
    public private(set) var lastReport: GameReloadReport?
    /// The last failure, cleared by a successful load.
    public private(set) var lastError: String?
    /// Called when the module, the settings or the busy state change.
    public var onChange: (() -> Void)?

    /// The component names the loaded module registered (some may have been refused).
    private var registeredNames: [String] = []
    private var systemsInWorld = false
    private var job: ReloadJob?
    private var watcher: FileWatcher?
    private var watchReloadPending = false
    private lazy var context = GameContext(input: session.gameInput) { [unowned self] message in session.log.info(message) }

    init(session: EditorSession) {
        self.session = session
    }

    /// Whether a module source is configured.
    public var isConfigured: Bool { settings != nil }
    /// Whether a build or reload is running.
    public var isBusy: Bool { job != nil }

    // MARK: Configuration

    /// Sets where the module comes from (relative paths against `base`), without loading it.
    public func configure(_ settings: GameModuleSettings?, base: URL) {
        self.settings = settings
        baseURL = base
        watcher?.stop()
        watcher = nil
        if settings?.watch == true, let target = settings?.target, let package = try? packageURL() {
            let sources = package.appendingPathComponent("Sources", isDirectory: true).appendingPathComponent(target, isDirectory: true)
            let watcher = FileWatcher(directory: sources)
            watcher.startCollecting(interval: 0.5)
            self.watcher = watcher
            session.log.info("Game: watching \(sources.path) for changes")
        }
        onChange?()
    }

    /// A project was opened: load its game, unless `--game` named one.
    func projectOpened(_ project: Project) {
        guard commandLineSettings == nil, let game = project.settings.game, game != settings else { return }
        configure(game, base: project.root)
        _ = try? reload(build: false)
    }

    /// The package holding the target.
    func packageURL() throws -> URL {
        if let package = settings?.package {
            return URL(fileURLWithPath: package, relativeTo: baseURL).standardizedFileURL
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        guard let found = GameModuleBuilder.findPackage(from: baseURL) ?? GameModuleBuilder.findPackage(from: cwd) else {
            throw CommandError.failed("No Package.swift at or above \(baseURL.path): set the game's \"package\"")
        }
        return found
    }

    // MARK: Load / reload / unload

    /// Builds (with `build`, in the background), links and loads the configured module, then
    /// swaps it in (see the notes at the top of the file). Without `build` it finishes at once.
    /// A failure leaves the current module loaded.
    public func reload(build: Bool = true) throws -> CommandFuture<GameReloadReport> {
        guard let settings else {
            throw CommandError.failed("No game module: start the editor with --game <target | library>, or set \"game\" in Project.json")
        }
        guard job == nil else { throw CommandError.failed("The game is already being rebuilt") }
        let start = Date()
        let future = CommandFuture<GameReloadReport>()
        if let target = settings.target {
            let builder = GameModuleBuilder(packageURL: try packageURL(), target: target, buildCommand: settings.buildCommand)
            let output = try GameModuleLoader.uniqueCopyURL(for: URL(fileURLWithPath: "\(target).\(GameModuleLoader.libraryExtension)"))
            if build {
                session.log.info("Game: building \(target) (\(builder.command.joined(separator: " ")))")
                startJob(future: future, start: start, output: output) { job in
                    job.build = builder.build()
                    guard job.build?.succeeded == true else { return }
                    if builder.engineChangedSinceHostBuilt() { job.error = GameModuleError.engineChanged.description; return }
                    do { job.link = try builder.link(to: output) } catch { job.error = "\(error)" }
                }
                return future
            }
            let link: GameModuleBuilder.StepResult
            do { link = try builder.link(to: output) } catch { throw fail(error) }
            finish(future, outcome: .init(output: output, link: link), start: start)
            return future
        }
        guard let library = settings.library else { throw CommandError.failed("The game setting names neither a target nor a library") }
        let url = URL(fileURLWithPath: library, relativeTo: baseURL).standardizedFileURL
        if build, let command = settings.buildCommand {
            session.log.info("Game: building (\(command.joined(separator: " ")))")
            let folder = baseURL
            startJob(future: future, start: start, output: url, copy: true) { job in
                job.build = GameModuleBuilder.run(command, in: folder)
            }
            return future
        }
        finish(future, outcome: .init(output: url, copy: true), start: start)
        return future
    }

    /// Takes the module out (its components stay in the scene as JSON) and forgets the settings.
    public func unload() throws {
        guard job == nil else { throw CommandError.failed("The game is being rebuilt") }
        if let loaded {
            try detach(loaded)
            self.loaded = nil
            clearUndoHistory()
            session.log.info("Game: unloaded \(loaded.module.name)")
        }
        configure(nil, base: baseURL)
        session.changed()
    }

    /// Called every frame: finishes a background build, and starts one for watched changes.
    func poll() {
        if let job, job.isDone {
            self.job = nil
            finish(job.future, outcome: job.outcome, start: job.start)
            onChange?()
        }
        if let watcher, !watcher.takeChanges().isEmpty { watchReloadPending = true }
        if watchReloadPending, job == nil, session.batch == nil {
            watchReloadPending = false
            session.log.info("Game: sources changed, reloading")
            _ = try? session.commands.start(GameReloadCommand.self, .init())
        }
    }

    private func startJob(future: CommandFuture<GameReloadReport>, start: Date, output: URL, copy: Bool = false,
                          _ work: @escaping @Sendable (ReloadJob.Outcome) -> Void) {
        let job = ReloadJob(future: future, start: start, outcome: ReloadJob.Outcome(output: output, copy: copy))
        self.job = job
        onChange?()
        let outcome = job.outcome
        DispatchQueue.global(qos: .userInitiated).async {
            work(outcome)
            job.markDone()
        }
    }

    /// After building and linking: load, swap, report.
    private func finish(_ future: CommandFuture<GameReloadReport>, outcome: ReloadJob.Outcome, start: Date) {
        if let build = outcome.build, !build.succeeded {
            future.fail(fail(GameModuleError.buildFailed(build.output), buildOutput: build.output))
            return
        }
        if let error = outcome.error {
            future.fail(fail(CommandError.failed(error)))
            return
        }
        do {
            let loadStart = Date()
            let new = try GameModuleLoader.load(outcome.output, copy: outcome.copy)
            let loadSeconds = Date().timeIntervalSince(loadStart)
            var report = try swap(to: new)
            report.built = outcome.build != nil
            report.buildSeconds = outcome.build?.seconds
            report.linkSeconds = outcome.link?.seconds
            report.loadSeconds = loadSeconds
            report.totalSeconds = Date().timeIntervalSince(start)
            lastReport = report
            lastError = nil
            log(report)
            future.resolve(report)
        } catch {
            future.fail(fail(error))
        }
    }

    /// Logs a failure (build errors line by line) and returns the error to fail with.
    private func fail(_ error: any Error, buildOutput: String? = nil) -> any Error {
        if let buildOutput {
            let errors = Self.compilerErrors(in: buildOutput)
            let lines = buildOutput.split(separator: "\n").map { Self.strippingEscapes(String($0)) }
            for line in errors.isEmpty ? Array(lines.suffix(30)) : errors { session.log.error(line) }
            let summary = "Build failed (\(max(errors.count, 1)) error\(errors.count == 1 ? "" : "s")); the old game code keeps running"
            lastError = summary
            onChange?()
            return CommandError.failed(summary)
        }
        let message = (error as? GameModuleError)?.description ?? (error as? CommandError)?.description ?? "\(error)"
        lastError = message
        onChange?()
        return CommandError.failed(loaded == nil ? message : message + " (the old game code keeps running)")
    }

    /// The compiler's diagnostics in build output ("file.swift:12:5: error: …"), once each
    /// (the swift-build backend repeats them), terminal colors removed; else lines with "error:".
    static func compilerErrors(in output: String) -> [String] {
        let lines = output.split(separator: "\n").map { strippingEscapes(String($0)).trimmingCharacters(in: .whitespaces) }
        var seen = Set<String>()
        let diagnostics = lines.filter { line in
            line.range(of: #"^\S.*:\d+:\d+: error: "#, options: .regularExpression) != nil && seen.insert(line).inserted
        }
        return diagnostics.isEmpty ? lines.filter { $0.contains("error:") && seen.insert($0).inserted } : diagnostics
    }

    private static func strippingEscapes(_ line: String) -> String {
        line.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m|\u{1B}\\]8;;[^\u{1B}]*\u{1B}\\\\", with: "", options: .regularExpression)
    }

    private func log(_ report: GameReloadReport) {
        var parts = ["\(report.components.count) components", "\(report.systems.count) systems"]
        if let build = report.buildSeconds { parts.append(String(format: "build %.2f s", build)) }
        if let link = report.linkSeconds { parts.append(String(format: "link %.2f s", link)) }
        parts.append(String(format: "load %.0f ms, swap %.0f ms", report.loadSeconds * 1000, report.swapSeconds * 1000))
        session.log.info("Game: loaded \(report.module) (\(parts.joined(separator: ", ")))")
        for (name, count) in report.removed.sorted(by: { $0.key < $1.key }) {
            session.log.warning("Game: component \(name) no longer exists; \(count) entit\(count == 1 ? "y keeps" : "ies keep") its data as JSON")
        }
        for (name, fields) in report.resetFields.sorted(by: { $0.key < $1.key }) {
            session.log.warning("Game: \(name) fields reset to defaults (their type changed): \(fields.joined(separator: ", "))")
        }
        for (name, reason) in report.failed.sorted(by: { $0.key < $1.key }) {
            session.log.warning("Game: couldn't restore \(name) (kept as JSON): \(reason)")
        }
        for warning in report.warnings { session.log.warning("Game: \(warning)") }
    }

    // MARK: Swapping

    /// Takes the loaded module out and puts `new` in (steps 2–4 in the notes).
    private func swap(to new: LoadedGameModule) throws -> GameReloadReport {
        let start = Date()
        session.onWillReplaceWorld?()
        let old = loaded
        let oldNames = Set(registeredNames)
        if let old { try detach(old) }

        var warnings: [String] = []
        var names: [String] = []
        for component in new.module.components {
            if let existing = ComponentRegistry.type(named: component.name), ObjectIdentifier(existing) != ObjectIdentifier(component.type) {
                warnings.append("component name '\(component.name)' is taken by \(existing); \(component.type) skipped")
                continue
            }
            guard !names.contains(component.name) else { continue }
            ComponentRegistry.register(component.type)
            let make = component.makeDefault
            EditorComponentCatalog.register(named: component.name, make: make)
            names.append(component.name)
        }
        loaded = new
        registeredNames = names
        AssetChoices.resetCaches()

        // Decode the JSON back, in the scene and in the play-mode snapshot.
        let defaults: (String) -> (any Component)? = { EditorComponentCatalog.makeDefault(named: $0) }
        var resolve = session.world.resolveUnresolvedComponents(defaults: defaults)
        try session.transformPlaySnapshot { world in
            let report = world.resolveUnresolvedComponents(defaults: defaults)
            resolve.resolved += report.resolved
            resolve.resetFields.merge(report.resetFields) { $0.union($1) }
            resolve.failures.merge(report.failures) { first, _ in first }
        }
        if session.isPlaying { addSystems() }
        if old != nil { clearUndoHistory() }

        let unresolved = session.world.unresolvedComponentCounts()
        let removed = oldNames.subtracting(names).reduce(into: [String: Int]()) { $0[$1] = unresolved[$1] ?? 0 }
        session.changed()
        onChange?()
        return GameReloadReport(
            module: new.module.name, components: names, systems: new.module.systems.map(\.name),
            added: names.filter { !oldNames.contains($0) }, removed: removed, restored: resolve.resolved,
            resetFields: resolve.resetFields.mapValues { $0.sorted() }, failed: resolve.failures, warnings: warnings,
            built: false, buildSeconds: nil, linkSeconds: nil, loadSeconds: 0, swapSeconds: Date().timeIntervalSince(start),
            totalSeconds: 0, playing: session.isPlaying)
    }

    /// Removes `module`'s systems and moves its components into JSON everywhere; unregisters
    /// its types. On failure (a component that doesn't encode) nothing changes.
    private func detach(_ module: LoadedGameModule) throws {
        let names = Set(registeredNames)
        // Encode everything before changing anything.
        let world = session.world
        do {
            try session.transformPlaySnapshot { try $0.detachComponents(named: names) }
        } catch {
            throw CommandError.failed("Couldn't serialize the play-mode snapshot's game components: \(error)")
        }
        do {
            try world.detachComponents(named: names)
        } catch {
            try? session.transformPlaySnapshot { $0.resolveUnresolvedComponents(defaults: { EditorComponentCatalog.makeDefault(named: $0) }) }
            throw CommandError.failed("Couldn't serialize the scene's game components: \(error)")
        }
        if systemsInWorld {
            module.module.removeSystems(from: world)
            systemsInWorld = false
        }
        ComponentRegistry.unregister(names)
        EditorComponentCatalog.unregister(names)
        registeredNames = []
    }

    private func clearUndoHistory() {
        let undo = session.undo
        let dirty = undo.isDirty
        undo.clear()
        if dirty { undo.markUnsaved() }
        session.log.info("Game: undo history cleared (its steps may hold values of the old game code)")
    }

    // MARK: Play mode

    /// Play started: the module's systems join the world.
    func addSystems() {
        guard let loaded, !systemsInWorld else { return }
        for warning in loaded.module.addSystems(to: session.world, context: context) { session.log.warning("Game: \(warning)") }
        systemsInWorld = true
    }

    /// Play stopped: they leave it.
    func removeSystems() {
        guard let loaded, systemsInWorld else { return }
        loaded.module.removeSystems(from: session.world)
        systemsInWorld = false
    }

    // MARK: Info

    /// `game.info`'s answer.
    public var info: GameInfoResult {
        GameInfoResult(
            configured: settings != nil, settings: settings, loaded: loaded != nil, module: loaded?.module.name,
            summary: loaded?.module.summary, components: registeredNames, systems: loaded?.module.systems.map(\.name) ?? [],
            library: loaded?.sourceURL.path, busy: isBusy, lastError: lastError, lastReport: lastReport,
            unresolved: session.world.unresolvedComponentCounts())
    }
}

/// A background build and link; `markDone` from the worker, read on the main actor.
private final class ReloadJob: @unchecked Sendable {
    /// What the worker produced. Written by the worker only, before `markDone`.
    final class Outcome: @unchecked Sendable {
        let output: URL
        let copy: Bool
        var build: GameModuleBuilder.StepResult?
        var link: GameModuleBuilder.StepResult?
        var error: String?

        init(output: URL, link: GameModuleBuilder.StepResult? = nil, copy: Bool = false) {
            self.output = output
            self.link = link
            self.copy = copy
        }
    }

    let future: CommandFuture<GameReloadReport>
    let start: Date
    let outcome: Outcome
    private let lock = NSLock()
    private var done = false

    init(future: CommandFuture<GameReloadReport>, start: Date, outcome: Outcome) {
        self.future = future
        self.start = start
        self.outcome = outcome
    }

    var isDone: Bool { lock.withLock { done } }
    func markDone() { lock.withLock { done = true } }
}

/// `game.info`'s result.
public struct GameInfoResult: Codable, Equatable, Sendable {
    /// Whether a module source is set (`--game`, Project.json, `game.load`), and which.
    public var configured: Bool
    public var settings: GameModuleSettings?
    /// Whether a module is loaded; its name, summary, components and systems.
    public var loaded: Bool
    public var module: String?
    public var summary: String?
    public var components: [String]
    public var systems: [String]
    /// The library that was loaded.
    public var library: String?
    /// Whether a build or reload is running.
    public var busy: Bool
    public var lastError: String?
    public var lastReport: GameReloadReport?
    /// Components the scene holds as JSON because their type isn't loaded: name → entities.
    public var unresolved: [String: Int]
}

extension EditorSession {
    /// Applies `body` to the play-mode snapshot, through a scratch world, while playing.
    func transformPlaySnapshot(_ body: (World) throws -> Void) throws {
        guard let snapshot = playSnapshot else { return }
        let scratch = World()
        scratch.restore(snapshot)
        try body(scratch)
        playSnapshot = scratch.snapshot()
    }
}
