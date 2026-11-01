import Engine
import Foundation

// Runs a game module standalone, the way the editor's play mode runs it:
// `swift run GameRunner SampleGame [scene.json]` builds the SampleGame target, links it into a
// module (GameModuleBuilder) and runs it; a path to a .dylib / .so loads that instead. A
// module with a `Game` (`makeGame`) runs it; otherwise the scene file is loaded and drawn by a
// SceneRenderer with the module's systems running. `--server` runs it headless as a UDP server
// and `--connect host:port` as a client of one (NetRun.swift).

let usage = """
    Usage: GameRunner <target | module.dylib> [scene.json] [--package <folder>] [--no-build] [--backend metal|vulkan]
           GameRunner <target | module.dylib> [scene.json] --server [--port 7777] [--host 0.0.0.0]
           GameRunner <target | module.dylib> [scene.json] --connect <host:port> [--headless]
      Networked runs: [--duration <seconds>] [--replicate auto|all|marked]
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
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
var duration: Double?
var replication = "auto"
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
    case "--duration":
        guard let seconds = Double(value("--duration")), seconds > 0 else { fail("--duration needs seconds") }
        duration = seconds
    case "--replicate":
        replication = value("--replicate")
        guard ["auto", "all", "marked"].contains(replication) else { fail("--replicate is auto, all or marked") }
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

/// Runs a module without a `Game`: its systems over a scene file.
@MainActor final class SceneHost: Game {
    let module: GameModule
    let sceneURL: URL
    let world = World()
    var renderer: SceneRenderer!

    init(module: GameModule, sceneURL: URL) {
        self.module = module
        self.sceneURL = sceneURL
    }

    func setup(engine: Engine) throws {
        renderer = try SceneRenderer(engine: engine)
        try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                      key: "checker")
        world.addBuiltinAnimationSystems()
        try world.load(Data(contentsOf: sceneURL))
        for warning in module.addSystems(to: world, context: GameContext(input: engine.input)) { print(warning) }
        engine.world = world
    }

    func update(engine: Engine, dt: Float) {}
    func renderOffscreen(engine: Engine, frame: Frame) { renderer.renderOffscreen(world: world, engine: engine, frame: frame) }
    func render(engine: Engine, pass: RenderPass) { renderer.draw(pass) }
}

MainActor.assumeIsolated {
    do {
        let loaded = try loadModule()
        let module = loaded.module
        // Scenes name components by their registered names.
        for component in module.components { ComponentRegistry.register(component.type) }
        ComponentRegistry.register(Spin.self, FieldAnimator.self, LightFlicker.self, CameraPath.self)
        print("Loaded \(module.name): \(module.componentNames.joined(separator: ", "))")
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
