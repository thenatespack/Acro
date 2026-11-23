import Engine
import Foundation

// Runs a game module standalone, the way the editor's play mode runs it:
// `swift run GameRunner SampleGame [scene.json]` builds the SampleGame target, links it into a
// module (GameModuleBuilder) and runs it; a path to a .dylib / .so loads that instead. A
// module with a `Game` (`makeGame`) runs it; otherwise the scene file is loaded and drawn by a
// SceneRenderer with the module's systems running (a scene inside a project gets the project's
// assets: placed models, characters and their clips, animation graphs). `--server` runs it headless as a UDP server
// and `--connect host:port` as a client of one (NetRun.swift). `--check` only loads it and
// checks that it shares this process's Engine, then exits (no window: CI uses it).
// `--playtest <file | folder>` replays recorded playtests headless and exits non-zero when one
// fails; `--mcp` serves the scene headless to an MCP client for agent playtesting (Playtest.swift).

let usage = """
    Usage: GameRunner <target | module.dylib> [scene.json] [--package <folder>] [--no-build] [--backend metal|vulkan]
           GameRunner <target | module.dylib> [scene.json] --server [--port 7777] [--host 0.0.0.0]
           GameRunner <target | module.dylib> [scene.json] --connect <host:port> [--headless]
           GameRunner <target | module.dylib> --check
           GameRunner <target | module.dylib | none> [scene.json] --playtest <file.playtest.json | folder> [--playtest …] [--report <out.json>]
           GameRunner <target | module.dylib | none> <scene.json> --mcp
      Networked runs: [--duration <seconds>] [--replicate auto|all|marked]
           GameRunner --version
    """

// Double-clicked on Windows, the console closes on exit: show errors and crashes in a message box.
StartupErrors.install(title: "GameRunner")

func fail(_ message: String) -> Never {
    StartupErrors.fatal(message)
}

var config = EngineConfig(title: "Game", width: 1280, height: 720)
var positional: [String] = []
var packagePath: String?
var build = true
var server = false
var connect: (host: String, port: UInt16)?
var port: UInt16 = 7777
var host = "0.0.0.0"
var headless = false
var check = false
var duration: Double?
var replication = "auto"
var playtests: [String] = []
var reportPath: String?
var mcp = false
var arguments = Array(CommandLine.arguments.dropFirst())
@MainActor func value(_ option: String) -> String {
    guard !arguments.isEmpty else { fail("\(option) needs a value") }
    return arguments.removeFirst()
}
while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--package":
        guard !arguments.isEmpty else { fail("--package needs a folder") }
        packagePath = arguments.removeFirst()
    case "--no-build":
        build = false
    case "--backend":
        guard let name = arguments.first, let backend = GraphicsBackend(rawValue: name) else { fail("--backend needs metal or vulkan") }
        arguments.removeFirst()
        config.backend = backend
    case "--server":
        server = true
    case "--port":
        guard let number = UInt16(value("--port")) else { fail("--port needs a port number") }
        port = number
    case "--host":
        host = value("--host")
    case "--connect":
        let address = value("--connect")
        guard let colon = address.lastIndex(of: ":"), let number = UInt16(address[address.index(after: colon)...]) else {
            fail("--connect needs host:port")
        }
        connect = (String(address[..<colon]), number)
    case "--headless":
        headless = true
    case "--check":
        check = true
    case "--duration":
        guard let seconds = Double(value("--duration")), seconds > 0 else { fail("--duration needs seconds") }
        duration = seconds
    case "--replicate":
        replication = value("--replicate")
        guard ["auto", "all", "marked"].contains(replication) else { fail("--replicate is auto, all or marked") }
    case "--playtest":
        playtests.append(value("--playtest"))
    case "--report":
        reportPath = value("--report")
    case "--mcp":
        mcp = true
    case "--version":
        print(EngineVersion.displayName)
        exit(0)
    case "--help", "-h":
        print(usage)
        exit(0)
    default:
        if argument.hasPrefix("-") { fail("Unknown option '\(argument)'\n\(usage)") }
        positional.append(argument)
    }
}
guard let moduleArgument = positional.first else { fail(usage) }
let scenePath = positional.dropFirst().first
if server && connect != nil { fail("--server and --connect exclude each other") }
if headless && connect == nil { fail("--headless goes with --connect (--server is always headless)") }
if (mcp || !playtests.isEmpty) && (server || connect != nil || check) { fail("--playtest and --mcp run alone (not with --server, --connect or --check)") }
if mcp && !playtests.isEmpty { fail("--mcp and --playtest exclude each other") }
if mcp && scenePath == nil { fail("--mcp needs a scene file") }
if reportPath != nil && playtests.isEmpty { fail("--report goes with --playtest") }
// The MCP client reads standard output: claim it before anything prints.
let mcpOutput = mcp ? PlaytestMCP.claimStandardOutput() : nil

/// Loads the module: builds and links a target, or loads a library file.
@MainActor func loadModule() throws -> LoadedGameModule {
    let settings = GameModuleSettings(argument: moduleArgument)
    if let library = settings.library {
        return try GameModuleLoader.load(URL(fileURLWithPath: library))
    }
    let start = URL(fileURLWithPath: packagePath ?? FileManager.default.currentDirectoryPath)
    guard let package = GameModuleBuilder.findPackage(from: start) else { fail("No Package.swift at or above \(start.path)") }
    let builder = GameModuleBuilder(packageURL: package, target: moduleArgument)
    if build {
        print("Building \(moduleArgument)…")
        let result = builder.build()
        guard result.succeeded else { throw GameModuleError.buildFailed(result.output) }
    }
    if builder.engineChangedSinceHostBuilt() { throw GameModuleError.engineChanged }
    let output = try GameModuleLoader.uniqueCopyURL(for: URL(fileURLWithPath: "\(moduleArgument).\(GameModuleLoader.libraryExtension)"))
    try builder.link(to: output)
    return try GameModuleLoader.load(output, copy: false)
}

/// Runs a module without a `Game`: its systems over a scene file, with the play systems
/// (`ScenePlayback`). `context.loadScene(path)` loads another scene file: `path` as given when
/// it exists, else relative to the first scene's folder or to an `Assets/` folder above it.
@MainActor final class SceneHost: Game {
    let module: GameModule
    let sceneURL: URL
    var renderer: SceneRenderer!
    var playback: ScenePlayback!
    /// The game's UI over the scene: `UILayoutPlayer` layouts (`world.gameUI`).
    let ui = UIContext.gameUI()
    /// The project the scene is in (its layouts, dialogues and timelines), when there is one.
    var assets: AssetDatabase?

    init(module: GameModule, sceneURL: URL) {
        self.module = module
        self.sceneURL = sceneURL
    }

    /// The file for a scene path game code asked for.
    static func resolve(_ path: String, from start: URL) -> URL {
        PlaytestHeadlessHost.resolve(path, from: start)
    }

    func setup(engine: Engine) throws {
        renderer = try SceneRenderer(engine: engine)
        try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                      key: "checker")
        let start = sceneURL
        // A scene inside a project gets the project's assets (prefab meshes, character clips, UI layouts…).
        assets = ScenePlayback.projectAssets(containing: sceneURL)
        renderer.assets = assets
        if let assets { print("Assets: \(assets.project.name) (\(assets.allRecords.count) assets)") }
        playback = ScenePlayback(module: module, context: GameContext(input: engine.input), audio: engine.audio,
                                 assets: { [weak self] in self?.assets }) { path in
            try Data(contentsOf: SceneHost.resolve(path, from: start))
        }
        playback.uiRoot = ui.root
        if let assets { playback.uiImages = UIBuildView.imageLoader(renderer: renderer, assets: assets) }
        try playback.load(sceneURL.path)
        engine.world = playback.world
    }

    /// Runs before the world's update, so a scene asked for last frame loads between updates.
    func update(engine: Engine, dt: Float) {
        playback.applyPendingScene()
        ui.update(engine: engine, dt: dt)
    }

    /// After the world's update, so the UI shows this frame's values.
    func renderOffscreen(engine: Engine, frame: Frame) {
        renderer.renderOffscreen(world: playback.world, engine: engine, frame: frame)
        ui.draw(into: engine.ui)
    }

    func render(engine: Engine, pass: RenderPass) { renderer.draw(pass) }
}

MainActor.assumeIsolated {
    do {
        // "none": no game code, only the engine's play systems (visual scripts, physics…).
        let loaded = moduleArgument == "none" ? nil : try loadModule()
        let module = loaded?.module ?? GameModule()
        if loaded == nil { module.name = "none" }
        // Scenes name components by their registered names.
        for component in module.components { ComponentRegistry.register(component.type) }
        ComponentRegistry.register(Spin.self, FieldAnimator.self, LightFlicker.self, CameraPath.self, TimelinePlayer.self, TilemapMotion.self, PathFollower.self, UILayoutPlayer.self,
                                   VisualScript.self)
        SkeletalAnimation.registerComponents()  // MeshRenderer, Skin, Animator: placed models and characters
        GameplayComponents.register()  // Health, Hitbox, Hurtbox, Interactable, Door…
        CameraRig.register()
        print("Loaded \(module.name): \(module.componentNames.joined(separator: ", "))")
        if check {
            // The module filled in this process's GameModule through Engine's API (on Windows,
            // imports bound to this executable), and its component types must work with Engine's
            // registry here. A smoke test for loading, not for the module's behavior.
            var problems: [String] = []
            if module.abiMinorVersion <= 0 { problems.append("the module recorded no ABI minor version") }
            for component in module.components {
                guard let registered = ComponentRegistry.type(named: component.name) else {
                    problems.append("\(component.name) isn't in the registry"); continue
                }
                if ObjectIdentifier(registered) != ObjectIdentifier(component.type) {
                    problems.append("\(component.name) is registered as another type")
                }
                if ObjectIdentifier(type(of: component.makeDefault())) != ObjectIdentifier(component.type) {
                    problems.append("\(component.name)'s default value has another type")
                }
            }
            guard problems.isEmpty else { fail("Check failed:\n" + problems.joined(separator: "\n")) }
            print("Check passed: \(module.components.count) components, ABI \(GameModuleABI.version).\(module.abiMinorVersion), loaded from \(loaded?.loadedURL.lastPathComponent ?? "nothing")")
            exit(0)
        }
        if !playtests.isEmpty {
            exit(PlaytestRun.run(module: module, scenePath: scenePath, playtests: playtests, reportPath: reportPath))
        }
        if let mcpOutput, let scenePath {
            try PlaytestRun.serve(module: module, sceneURL: URL(fileURLWithPath: scenePath), output: mcpOutput)
            exit(0)
        }
        let sceneURL = scenePath.map { URL(fileURLWithPath: $0) }
        if server || connect != nil {
            #if canImport(Darwin) || canImport(Glibc)
            var options = NetRunOptions(role: connect.map { .client(host: $0.host, port: $0.port) } ?? .server)
            options.port = port
            options.host = host
            options.headless = headless
            options.duration = duration
            options.replication = NetRunOptions.Replication(rawValue: replication) ?? .auto
            if server {
                try NetRun.runServer(module: module, sceneURL: sceneURL, options: options)
                exit(0)
            }
            if let connect, headless {
                try NetRun.runHeadlessClient(module: module, sceneURL: sceneURL, host: connect.host, port: connect.port, options: options)
                exit(0)
            }
            if let connect {
                config.title = "\(module.name) (client of \(connect.host):\(connect.port))"
                let engine = try Engine(config: config)
                try engine.run(NetClientGame(module: module, sceneURL: sceneURL, host: connect.host, port: connect.port, options: options))
                exit(0)
            }
            #else
            fail("Networked runs need UDP sockets (macOS or Linux)")
            #endif
        }
        let game: any Game
        if let scenePath {
            game = SceneHost(module: module, sceneURL: URL(fileURLWithPath: scenePath))
        } else if let makeGame = module.makeGame {
            game = makeGame()
        } else {
            fail("\(module.name) has no Game of its own: pass a scene file")
        }
        config.title = module.name
        let engine = try Engine(config: config)
        try engine.run(game)
    } catch {
        fail("\(error)")
    }
}
