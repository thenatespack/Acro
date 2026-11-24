import EngineAssets
import EngineCore
import EngineScene
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

// A scene played without a window for playtests: `ScenePlayback` (the play systems and the
// module's) over one world, an `Input` nothing but the playtest feeds, and frames run on
// demand at a fixed dt. No renderer, so no screenshots; everything else game code sees (input,
// physics, visual scripts, behavior trees, timelines) runs as in the editor's play mode.
// GameRunner's `--playtest` and headless `--mcp` use it.
//
// ```swift
// let host = try PlaytestHeadlessHost(module: module, sceneURL: url)
// let result = host.run(try Playtest(contentsOf: recordingURL))
// exit(result.passed ? 0 : 1)
// ```

/// Plays a scene headless for a playtest; see the notes at the top of this file.
@MainActor
public final class PlaytestHeadlessHost {
    public let module: GameModule
    public let sceneURL: URL
    public let input = Input()
    public private(set) var inputPlayer = InputPlayer()
    public private(set) var playback: ScenePlayback
    /// The project the scene is in, when there is one (its assets and runtime settings).
    public let assets: AssetDatabase?
    public private(set) var frame = 0
    public private(set) var time: Double = 0
    /// The current playtest session (a new one on `restart`).
    public private(set) var driver: PlaytestDriver!
    public var log: @MainActor (String) -> Void

    public var world: World { playback.world }

    /// Loads the scene at `sceneURL` with `module`'s systems. A scene inside a project gets its
    /// assets and runtime settings (gravity, fixed timestep). Throws when the scene can't load.
    public init(module: GameModule, sceneURL: URL, assets: AssetDatabase? = nil, log: @escaping @MainActor (String) -> Void = { print($0) }) throws {
        self.module = module
        self.sceneURL = sceneURL
        self.log = log
        // Nothing renders here, so nothing else registers the engine's components before the scene loads.
        GamePlayer.registerEngineComponents()
        ComponentRegistry.register(VisualScript.self)
        let assets = assets ?? ScenePlayback.projectAssets(containing: sceneURL)
        self.assets = assets
        playback = Self.makePlayback(module: module, sceneURL: sceneURL, input: input, assets: assets, log: log)
        try playback.load(sceneURL.path)
        driver = makeDriver(name: nil, record: false)
    }

    private static func makePlayback(module: GameModule, sceneURL: URL, input: Input, assets: AssetDatabase?,
                                     log: @escaping @MainActor (String) -> Void) -> ScenePlayback {
        let playback = ScenePlayback(module: module, context: GameContext(input: input, log: log),
                                     runtime: assets?.project.settings.runtime ?? ProjectRuntimeSettings(),
                                     assets: { assets }, log: log) { path in
            try Data(contentsOf: PlaytestHeadlessHost.resolve(path, from: sceneURL))
        }
        return playback
    }

    /// The scene path stored in recordings: relative to the project's `Assets/` when it is in one.
    public var scenePath: String {
        assets?.project.assetPath(for: sceneURL) ?? sceneURL.path
    }

    private func makeDriver(name: String?, record: Bool, actions: [String: [String]] = [:]) -> PlaytestDriver {
        let target = PlaytestTarget(world: { [unowned self] in playback.world }, input: { [unowned self] in input },
                                    inputPlayer: { [unowned self] in inputPlayer }, frame: { [unowned self] in frame },
                                    time: { [unowned self] in time }, fixedStep: { [unowned self] in playback.world.fixedTimestep },
                                    runFrames: { [unowned self] count, dt in runFrames(count, dt: dt) })
        return PlaytestDriver(target: target, name: name, scene: scenePath, actions: actions, record: record)
    }

    /// Reloads the scene from its file, resets input and time, and starts a new playtest session
    /// (`record`: recording from frame 0).
    public func restart(name: String? = nil, record: Bool = false, actions: [String: [String]] = [:]) throws {
        let fresh = Self.makePlayback(module: module, sceneURL: sceneURL, input: input, assets: assets, log: log)
        try fresh.load(sceneURL.path)
        playback = fresh
        input.reset()
        inputPlayer = InputPlayer()
        frame = 0
        time = 0
        driver = makeDriver(name: name, record: record, actions: actions)
    }

    /// Runs `count` frames of `dt` seconds (default the world's fixed step).
    public func runFrames(_ count: Int, dt: Double? = nil) {
        let dt = dt ?? playback.world.fixedTimestep
        for _ in 0..<max(count, 0) {
            playback.applyPendingScene()
            input.beginFrame()
            inputPlayer.apply(to: input)
            driver?.applyFrameInput(to: input)
            input.endEvents()
            playback.world.update(dt: dt)
            inputPlayer.advance(by: dt)
            frame += 1
            time += dt
        }
    }

    /// Plays `playtest` from the start of the scene and returns its result.
    public func run(_ playtest: Playtest) -> PlaytestResult {
        do {
            if frame > 0 || driver.result.checks.count > 0 { try restart(name: playtest.name) }
        } catch {
            return PlaytestResult(name: playtest.name, checks: [], errors: ["The scene didn't reload: \(error)"], frames: 0, time: 0)
        }
        return driver.run(playtest)
    }

    // MARK: Files

    /// The file for a scene path: `path` as given when it exists, else relative to `start`'s
    /// folder, or under the project above it ("Scenes/Main.scene" in `Assets/`, "Assets/…" in
    /// the project folder).
    public static func resolve(_ path: String, from start: URL) -> URL {
        let fm = FileManager.default
        let expanded = path.pathExpandingTilde
        if expanded.hasPrefix("/") || fm.fileExists(atPath: expanded) { return URL(fileURLWithPath: expanded) }
        var candidates: [URL] = []
        var folder = start.deletingLastPathComponent().standardizedFileURL
        candidates.append(folder.appendingPathComponent(path))
        while folder.path != "/" && !folder.path.isEmpty {
            if folder.lastPathComponent == "Assets" {
                candidates.append(folder.appendingPathComponent(path))
                candidates.append(folder.deletingLastPathComponent().appendingPathComponent(path))
                break
            }
            if Project.exists(at: folder) {
                candidates.append(folder.appendingPathComponent("Assets").appendingPathComponent(path))
                candidates.append(folder.appendingPathComponent(path))
                break
            }
            folder = folder.deletingLastPathComponent()
        }
        return candidates.first { fm.fileExists(atPath: $0.path) } ?? candidates[0]
    }
}
