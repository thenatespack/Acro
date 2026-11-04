import Engine
import Foundation

// Build Game (`game.build`, the toolbar's Build Game button with a project open): cooks the
// project's scenes into a pack and exports a standalone game (GameExporter: the game module
// and Engine linked into one release executable, a .app on macOS, a folder with a launcher on
// Linux). The cook plan is taken from the open project's database on the main actor; cooking
// and the release build run on a background thread, their progress lines go to the console
// as they come (drained each frame by `poll`), and the command finishes with the output path.

public enum EditorBuildCommands {
    public static let all: [any EditorCommand.Type] = [GameBuildCommand.self]
}

/// `game.build`'s result.
public struct GameBuildResult: Codable, Equatable, Sendable {
    /// The app (macOS), game folder (Linux) or, for `cookOnly`, the pack.
    public var outputPath: String
    public var packPath: String
    public var cook: CookReport
    /// The executable (nil for `cookOnly`).
    public var executablePath: String?
    public var buildSeconds: Double?
    public var totalSeconds: Double
    public var summary: String
}

public enum GameBuildCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Scenes to cook, the start scene first (paths relative to the project folder or
        /// `Assets/`). Default: Project.json's `build.scenes`, else the open scene's file.
        public var scenes: [String]?
        /// The output folder, relative to the project folder. Default: `build.output` or
        /// `Build`, plus the platform, architecture and configuration ("Build/macos-arm64",
        /// "Build/linux-x86_64-debug").
        public var output: String?
        /// `macos`, `linux` or `windows`. Default: this machine's. A game can only be built for
        /// this machine's platform (no cross-compiling); `cookOnly` cooks for any.
        public var platform: CookPlatform?
        /// `release` (optimized, the default) or `debug` (unoptimized, with assertions and debug info).
        public var configuration: BuildConfiguration?
        /// `x86_64` or `arm64`. Default: this machine's. macOS builds either; elsewhere only this
        /// machine's, unless `docker`.
        public var architecture: BuildArchitecture?
        /// Build in a Docker container (Linux only): a Linux game from any machine, for either architecture.
        public var docker: Bool?
        /// `bc` or `astc`. Default: `build.textureFamily`, else ASTC on macOS and BC elsewhere.
        public var textureFamily: TextureFamily?
        /// `compress` (every 8-bit texture block-compressed, the default) or `asImported`.
        public var textures: TextureCookMode?
        /// Only cook the pack (`<output>/<name>.pack` and its manifest), without building the game.
        public var cookOnly: Bool?

        public init(scenes: [String]? = nil, output: String? = nil, platform: CookPlatform? = nil,
                    configuration: BuildConfiguration? = nil, architecture: BuildArchitecture? = nil, docker: Bool? = nil,
                    textureFamily: TextureFamily? = nil, textures: TextureCookMode? = nil, cookOnly: Bool? = nil) {
            self.scenes = scenes
            self.output = output
            self.platform = platform
            self.configuration = configuration
            self.architecture = architecture
            self.docker = docker
            self.textureFamily = textureFamily
            self.textures = textures
            self.cookOnly = cookOnly
        }
    }

    public typealias Result = GameBuildResult

    public static let id: CommandID = "game.build"
    public static let title = "Build Game"
    public static let doc = """
        Exports the project as a standalone game: cooks every asset reachable from the scenes into one pack (textures \
        block-compressed for the target GPU family, no source files), builds the game module (a generated one that only plays the scenes when the project has no game code) and Engine in release and \
        links them into one executable, and lays out a runnable app (macOS: <output>/<Name>.app; Linux: <output>/<Name>/ \
        with run.sh). Runs in the background (the first build compiles Engine in release, minutes; later ones seconds); \
        progress and errors go to the console. Returns the output path, the pack's contents and sizes, and timings. \
        `platform`, `architecture` (x86_64 or arm64) and `configuration` (release or debug) pick what is built; \
        only this machine's platform can be built (macOS builds either architecture, other platforms only their own), \
        except with `docker: true`, which builds a Linux game in a container from any machine for either architecture \
        (Docker must be installed and running; the first build takes many minutes). `output` may be any folder. \
        `cookOnly` writes just the pack (for any platform). The output folder is replaced.
        """
    public static func isAvailable(in session: EditorSession) -> Bool {
        unavailableReason(in: session) == nil
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        if session.project == nil { return "no project is open" }
        if session.gameExport.isBusy { return "a build is already running" }
        if session.batch != nil { return "a batch is open (edit.endBatch first)" }
        return nil
    }
    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<GameBuildResult> {
        try session.gameExport.start(arguments)
    }
}

/// The session's Build Game state: at most one export at a time.
@MainActor
public final class EditorGameExport {
    unowned let session: EditorSession
    /// The last finished build's result.
    public private(set) var lastResult: GameBuildResult?
    /// The last build's error, if it failed.
    public private(set) var lastError: String?
    /// What the Export Game dialog last exported (its starting choice next time).
    public var lastChoice: ExportDialog.Choice?
    /// Called when a build starts or finishes (toolbar refresh).
    public var onChange: (() -> Void)?
    private var job: ExportJob?

    init(session: EditorSession) {
        self.session = session
    }

    public var isBusy: Bool { job != nil }

    func start(_ arguments: GameBuildCommand.Arguments) throws -> CommandFuture<GameBuildResult> {
        guard let assets = session.assets, let project = session.project else { throw CommandError.failed("No project is open") }
        let build = project.settings.build ?? GameBuildSettings()
        var scenes = arguments.scenes ?? build.scenes ?? []
        if scenes.isEmpty, let url = session.document.url {
            scenes = [project.assetPath(for: url) ?? url.path]
        }
        guard !scenes.isEmpty else {
            throw CommandError.failed("Nothing to build: save the scene, pass scenes, or set \"build\": {\"scenes\": […]} in Project.json")
        }
        let platform = arguments.platform ?? .current
        let configuration = arguments.configuration ?? .release
        let architecture = arguments.architecture ?? .current
        let target = CookTarget(platform: platform, textureFamily: arguments.textureFamily ?? build.textureFamily)
        let output = arguments.output.map { URL(fileURLWithPath: $0, relativeTo: project.root).standardizedFileURL }
        let start = Date()
        let future = CommandFuture<GameBuildResult>()
        let job = ExportJob()
        assets.waitForAll()  // what the editor is importing now goes in as imported
        if arguments.cookOnly == true {
            var options = CookOptions(scenes: scenes, include: build.include ?? [], target: target,
                                      textures: arguments.textures ?? build.textures ?? .compress, packName: build.name ?? project.name)
            let folder = output ?? project.root.appendingPathComponent(build.output ?? "Build", isDirectory: true)
                .appendingPathComponent("\(target.platform.rawValue)-pack", isDirectory: true)
            guard session.checkFileAccess(folder, GameBuildCommand.title) else { throw CommandError.failed("The output is outside the project folder") }
            options.target = target
            let plan = try AssetCooker.plan(database: assets, options: options)
            session.log.info("Build: cooking \(scenes.joined(separator: ", ")) (\(target.platform.rawValue), \(target.textureFamily.rawValue) textures)")
            run(job, future: future) { progress in
                let report = try plan.run(to: folder, progress: progress)
                return GameBuildResult(outputPath: report.packPath, packPath: report.packPath, cook: report, executablePath: nil,
                                       buildSeconds: nil, totalSeconds: Date().timeIntervalSince(start), summary: report.summary)
            }
        } else {
            let game = session.gameModule.settings
            let docker = arguments.docker ?? false
            if let reason = Self.unbuildableReason(platform: platform, architecture: architecture, docker: docker) {
                throw CommandError.failed(reason)
            }
            var options = try GameExporter.options(for: project, game: game, gameBase: game != nil ? session.gameModule.baseURL : nil,
                                                   scenes: scenes, output: output, target: target,
                                                   configuration: configuration, architecture: architecture)
            if let textures = arguments.textures { options.cook.textures = textures }
            options.useDocker = docker
            guard session.checkFileAccess(options.output, GameBuildCommand.title) else {
                throw CommandError.failed("The output is outside the project folder")
            }
            let exporter = try GameExporter.prepare(database: assets, options: options)
            session.log.info("Build: exporting \(options.name) (\(options.gameTarget), \(platform.rawValue) \(architecture.rawValue) "
                             + "\(configuration.rawValue)\(docker ? ", in Docker" : "")) to \(options.output.path)")
            run(job, future: future) { progress in
                let report = try exporter.run(progress: progress)
                return GameBuildResult(outputPath: report.outputPath, packPath: report.packPath, cook: report.cook,
                                       executablePath: report.executablePath, buildSeconds: report.buildSeconds,
                                       totalSeconds: report.totalSeconds, summary: report.summary)
            }
        }
        return future
    }

    /// Why this machine can't build a game for `platform` / `architecture` (in Docker with `docker`), or nil when it can.
    public static func unbuildableReason(platform: CookPlatform, architecture: BuildArchitecture, docker: Bool = false) -> String? {
        GameExporter.unbuildableReason(platform: platform, architecture: architecture, useDocker: docker)
    }

    private func run(_ job: ExportJob, future: CommandFuture<GameBuildResult>,
                     _ work: @escaping @Sendable (@escaping @Sendable (String) -> Void) throws -> GameBuildResult) {
        job.future = future
        self.job = job
        lastError = nil
        onChange?()
        DispatchQueue.global(qos: .userInitiated).async {
            let outcome = Result { try work { job.post($0) } }
            job.finish(outcome)
        }
    }

    /// Called every frame (`EditorSession.tick`): progress lines to the console, and the result.
    func poll() {
        guard let job else { return }
        let (lines, outcome) = job.take()
        for line in lines { session.log.info("Build: \(line)") }
        guard let outcome else { return }
        self.job = nil
        switch outcome {
        case .success(let result):
            lastResult = result
            session.log.info("Build: done: \(result.outputPath)")
            job.future?.resolve(result)
        case .failure(let error):
            let message = "\(error)"
            let lines = message.split(separator: "\n").map(String.init)
            // Compiler output: the error lines, else the end of it.
            let errors = lines.filter { $0.contains("error:") }
            for line in errors.isEmpty ? Array(lines.suffix(30)) : errors { session.log.error("Build: \(line)") }
            lastError = lines.first ?? message
            job.future?.fail(CommandError.failed("Build Game failed: \(lastError ?? message)"))
        }
        onChange?()
    }
}

/// One background export: progress lines and the outcome, handed to the main actor by `take`.
private final class ExportJob: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []
    private var outcome: Result<GameBuildResult, any Error>?
    /// Main actor only.
    nonisolated(unsafe) var future: CommandFuture<GameBuildResult>?

    func post(_ line: String) { lock.withLock { lines.append(line) } }
    func finish(_ outcome: Result<GameBuildResult, any Error>) { lock.withLock { self.outcome = outcome } }

    func take() -> ([String], Result<GameBuildResult, any Error>?) {
        lock.withLock {
            defer { lines.removeAll() }
            return (lines, outcome)
        }
    }
}
