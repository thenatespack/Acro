import Foundation

// The runtime of an exported game (GameExporter.swift): one executable with Engine and the
// game module linked in statically, and an asset pack. Its generated `main.swift` is just
//
// ```swift
// import Engine
// @_silgen_name("swift_game_engine_module_v1") func gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32
// GamePlayer.main(module: gameModuleEntry)
// ```
//
// `main` registers the engine's components and the module's, mounts the pack read-only
// (`AssetDatabase(mounting:)`: no importers, no `Assets/` or `Library/`), loads the start scene
// from it and plays it the way the editor's play mode does (physics when it has colliders,
// sprite animation, the module's systems); game code switches between the cooked scenes with
// `context.loadScene(_:)`. A module without cooked scenes runs its own `Game`
// (`makeGame`), which reaches the pack through `GamePlayer.assets`.
//
// Options: `--pack <file>` (default: the one `.pack` in the app's Resources folder or next to
// the executable; `ENGINE_PACK` too), `--scene <path>` (a cooked scene other than the start
// scene), `--backend metal|vulkan`, `--size <w>x<h>`, `--version` (prints the engine version).
// A pack cooked by another engine version gets a warning on stderr and is played anyway.

@MainActor
public enum GamePlayer {
    /// The mounted pack's database (set by `main` before the game starts).
    public private(set) static var assets: AssetDatabase?

    /// What `main` found on the command line.
    public struct Options: Equatable, Sendable {
        public var pack: String?
        public var scene: String?
        public var backend: GraphicsBackend?
        /// `--size`; nil: the project's runtime window size, else 1280 x 720.
        public var width: Int?
        public var height: Int?
        /// `--version`: print the engine version and exit.
        public var version = false

        public init() {}

        public static let usage = "Usage: <game> [--pack <file.pack>] [--scene <path>] [--backend metal|vulkan] [--size <w>x<h>] [--version]"

        /// Parses `arguments` (without the program name).
        public static func parse(_ arguments: [String]) throws -> Options {
            var options = Options()
            var rest = arguments[...]
            func value(_ flag: String) throws -> String {
                guard let next = rest.popFirst() else { throw GamePlayerError.badArguments("\(flag) needs a value\n\(usage)") }
                return next
            }
            while let argument = rest.popFirst() {
                switch argument {
                case "--pack": options.pack = try value(argument)
                case "--version": options.version = true
                case "--scene": options.scene = try value(argument)
                case "--backend":
                    let name = try value(argument)
                    guard let backend = GraphicsBackend(rawValue: name) else { throw GamePlayerError.badArguments("Unknown backend '\(name)'") }
                    options.backend = backend
                case "--size":
                    let parts = try value(argument).split(separator: "x").compactMap { Int($0) }
                    guard parts.count == 2, parts.allSatisfy({ $0 > 0 }) else { throw GamePlayerError.badArguments("--size takes <w>x<h>") }
                    options.width = parts[0]
                    options.height = parts[1]
                // macOS passes -psn_… to apps opened from the Finder on old systems.
                case let other where other.hasPrefix("-psn_"): continue
                default: throw GamePlayerError.badArguments("Unknown option '\(argument)'\n\(usage)")
                }
            }
            return options
        }
    }

    /// Finds the pack: `explicit`, `ENGINE_PACK`, else the only `.pack` in the main bundle's
    /// Resources folder (a macOS app) or next to the executable.
    public static func findPack(explicit: String? = nil) throws -> URL {
        if let path = explicit ?? ProcessInfo.processInfo.environment["ENGINE_PACK"] { return URL(fileURLWithPath: path) }
        var folders: [URL] = []
        if let resources = Bundle.main.resourceURL { folders.append(resources) }
        if let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() { folders.append(executable.deletingLastPathComponent()) }
        for folder in folders {
            let packs = ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [])
                .filter { $0.hasSuffix(".pack") }.sorted()
            if let first = packs.first { return folder.appendingPathComponent(first) }
        }
        throw GamePlayerError.noPack(folders.map(\.path))
    }

    /// The engine's own components, so scene files that use them load (the editor registers
    /// the same through its component catalog).
    public static func registerEngineComponents() {
        ComponentRegistry.register(Transform.self, Name.self, Camera.self, DirectionalLight.self, PointLight.self, SpotLight.self,
                                   SceneEnvironment.self, PostProcessSettings.self, PlanarReflection.self, MeshRenderer.self, LineRenderer.self, MeshArray.self, Decal.self, Saveable.self,
                                   Sprite.self, SpriteAnimator.self, PrefabInstance.self, Spin.self, FieldAnimator.self, LightFlicker.self,
                                   CameraPath.self)
        PhysicsWorld.registerComponents()
        PhysicsWorld2D.registerComponents()
        AudioSystem.registerComponents()
        ParticleSystem.registerComponents()
        TextMeshComponents.registerComponents()
    }

    /// Calls a statically linked module's entry point (`GameModuleABI.entryPoint`) and checks
    /// its ABI version.
    public static func register(module entry: (UnsafeMutableRawPointer) -> Int32) throws -> GameModule {
        let module = GameModule()
        let version = withExtendedLifetime(module) { entry(Unmanaged.passUnretained(module).toOpaque()) }
        guard version == GameModuleABI.version else { throw GameModuleError.versionMismatch(version) }
        return module
    }

    /// The game to run: the pack's scene with the module's systems, or the module's own game.
    public static func makeGame(module: GameModule, assets: AssetDatabase, scene: String?) throws -> any Game {
        guard let pack = assets.pack else { throw GamePlayerError.noPack([]) }
        if !pack.manifest.scenes.isEmpty || scene != nil {
            _ = try pack.scene(scene)  // fail here, before a window opens, on an unknown scene
            return PackSceneGame(module: module, assets: assets, scene: scene)
        }
        guard let makeGame = module.makeGame else {
            throw GamePlayerError.nothingToRun("\(pack.name) has no scenes and \(module.name) has no Game of its own")
        }
        return makeGame()
    }

    /// A warning when the pack was cooked by another engine version than this game's (nil: same,
    /// or not recorded). The game still plays it: the pack format has its own version check.
    public static func packVersionWarning(_ manifest: AssetPackManifest) -> String? {
        guard let mismatch = EngineVersionMismatch.check(manifest.engineVersion) else { return nil }
        return "Warning: \(manifest.name)'s asset pack was cooked by engine \(mismatch.saved), but this game runs engine \(mismatch.current); rebuild the game if anything looks wrong"
    }

    /// The exported executable's whole `main`: parses the command line, mounts the pack,
    /// registers the module and runs the game. Exits with a message on failure.
    public static func main(module entry: (UnsafeMutableRawPointer) -> Int32,
                            arguments: [String] = Array(CommandLine.arguments.dropFirst())) -> Never {
        do {
            let options = try Options.parse(arguments)
            if options.version {
                print(EngineVersion.displayName)
                exit(0)
            }
            registerEngineComponents()
            let module = try register(module: entry)
            for component in module.components { ComponentRegistry.register(component.type) }
            let pack = try AssetPack(url: try findPack(explicit: options.pack))
            if let warning = packVersionWarning(pack.manifest) { FileHandle.standardError.write(Data((warning + "\n").utf8)) }
            let assets = AssetDatabase(mounting: pack)
            self.assets = assets
            let game = try makeGame(module: module, assets: assets, scene: options.scene)
            var config = EngineConfig(title: module.name.isEmpty ? pack.manifest.name : module.name, showDebugOverlay: false)
            // The project's runtime settings, then the command line's size.
            pack.manifest.runtime?.apply(to: &config)
            if let width = options.width { config.width = width }
            if let height = options.height { config.height = height }
            if let backend = options.backend { config.backend = backend }
            let engine = try Engine(config: config)
            try engine.run(game)
            exit(0)
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }
    }
}

public enum GamePlayerError: Error, Equatable, CustomStringConvertible {
    case badArguments(String)
    case noPack([String])
    case nothingToRun(String)

    public var description: String {
        switch self {
        case .badArguments(let message): message
        case .noPack(let folders): "No asset pack found (looked in \(folders.joined(separator: ", "))); pass --pack <file> or set ENGINE_PACK"
        case .nothingToRun(let message): message
        }
    }
}

/// Plays a cooked scene: the scene from the pack, drawn by a `SceneRenderer` whose assets
/// come from the pack, with the play-mode systems and the module's (`ScenePlayback`). Game
/// code switches to another cooked scene with `context.loadScene(_:)`.
@MainActor
final class PackSceneGame: Game {
    let module: GameModule
    let assets: AssetDatabase
    /// The scene to start with (nil: the pack's start scene).
    let scene: String?
    private var renderer: SceneRenderer!
    private(set) var playback: ScenePlayback!

    init(module: GameModule, assets: AssetDatabase, scene: String?) {
        self.module = module
        self.assets = assets
        self.scene = scene
    }

    func setup(engine: Engine) throws {
        renderer = try SceneRenderer(engine: engine)
        // The editor's checker material (its starter scene's floor), so scenes made there look the same.
        try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                      key: "checker")
        renderer.assets = assets
        guard let pack = assets.pack else { throw GamePlayerError.noPack([]) }
        let context = GameContext(input: engine.input)
        context.scenes = pack.manifest.scenes.map(\.path)
        playback = ScenePlayback(module: module, context: context, runtime: pack.manifest.runtime ?? ProjectRuntimeSettings(),
                                 audio: engine.audio, assets: { [assets] in assets }) { path in try pack.scene(path) }
        guard let start = scene ?? pack.manifest.startScene else {
            throw GamePlayerError.nothingToRun("\(pack.name) has no scenes")
        }
        try playback.load(start)
        engine.world = playback.world
    }

    /// Runs before the world's update, so a scene asked for last frame loads between updates.
    func update(engine: Engine, dt: Float) { playback.applyPendingScene() }
    func renderOffscreen(engine: Engine, frame: Frame) { renderer.renderOffscreen(world: playback.world, engine: engine, frame: frame) }
    func render(engine: Engine, pass: RenderPass) { renderer.draw(pass) }
}
