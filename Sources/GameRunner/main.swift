import Engine
import Foundation

// Runs a game module standalone, the way the editor's play mode runs it:
// `swift run GameRunner SampleGame [scene.json]` builds the SampleGame target, links it into a
// module (GameModuleBuilder) and runs it; a path to a .dylib / .so loads that instead. A
// module with a `Game` (`makeGame`) runs it; otherwise the scene file is loaded and drawn by a
// SceneRenderer with the module's systems running.

let usage = """
    Usage: GameRunner <target | module.dylib> [scene.json] [--package <folder>] [--no-build] [--backend metal|vulkan]
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

var config = EngineConfig(title: "Game", width: 1280, height: 720)
var positional: [String] = []
var packagePath: String?
var build = true
var arguments = Array(CommandLine.arguments.dropFirst())
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
        print("Loaded \(module.name): \(module.componentNames.joined(separator: ", "))")
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
