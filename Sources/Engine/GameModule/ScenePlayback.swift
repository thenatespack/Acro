import Foundation

/// Plays scene files with a game module outside the editor, the way the editor's play mode
/// does: the play systems (physics and 2D physics when the scene has colliders, sprite
/// animation when the scene has animators, spatial audio whenever `audio` is set, the built-in
/// animators) and the module's systems, over one world. Spatial audio starts even when the
/// scene has no `AudioEmitter`: a module spawns emitters while it runs. Switches scenes when
/// game code calls `context.loadScene(_:)`: `applyPendingScene()`
/// (called by the host between world updates) clears the world, loads the new scene and
/// restarts the systems. Used by exported games (`GamePlayer`) and `GameRunner`.
///
/// The world stays the same object across scenes (the engine and renderer keep it); entity
/// handles from the old scene go stale.
@MainActor
public final class ScenePlayback {
    public let world: World
    public let module: GameModule
    public let context: GameContext
    /// Gravity and the fixed timestep, applied to the world and each scene's physics.
    public var runtime: ProjectRuntimeSettings
    /// Sound for `AudioEmitter`s; nil: none.
    public var audio: AudioSystem?
    /// Where emitters' clips load from.
    public var assets: () -> AssetDatabase?
    /// A scene file's bytes for a path given to `loadScene`.
    public let sceneData: @MainActor (String) throws -> Data
    /// Writes a line to the host's log.
    public var log: @MainActor (String) -> Void

    public private(set) var physics: PhysicsWorld?
    public private(set) var physics2D: PhysicsWorld2D?
    private var spatialAudio: SpatialAudioHandle?
    private var systemsAdded = false

    private static let spriteSystem = "scenePlayback.spriteAnimation"

    public init(module: GameModule, context: GameContext, world: World = World(), runtime: ProjectRuntimeSettings = ProjectRuntimeSettings(),
                audio: AudioSystem? = nil, assets: @escaping () -> AssetDatabase? = { nil },
                log: @escaping @MainActor (String) -> Void = { print($0) },
                sceneData: @escaping @MainActor (String) throws -> Data) {
        self.module = module
        self.context = context
        self.world = world
        self.runtime = runtime
        self.audio = audio
        self.assets = assets
        self.log = log
        self.sceneData = sceneData
    }

    /// Replaces the world's entities with the scene at `path` and (re)starts the systems.
    /// Throws, leaving the current scene playing, when the scene can't be read or decoded.
    public func load(_ path: String) throws {
        let data = try sceneData(path)
        // Validate in a scratch world first, so a bad file doesn't leave an empty world.
        _ = try World().load(data)
        removeSystems()
        for root in world.roots { world.despawn(root) }
        _ = try world.load(data)
        world.propagateTransforms()
        context.scene = path
        addSystems()
    }

    /// Loads the scene game code asked for with `context.loadScene(_:)`, if any; logs a failure
    /// and keeps the current scene. Call between world updates. Returns whether it switched.
    @discardableResult
    public func applyPendingScene() -> Bool {
        guard let path = context.takePendingScene() else { return false }
        do {
            try load(path)
            log("Scene: \(path)")
            return true
        } catch {
            log("Scene '\(path)' failed to load: \(error)")
            return false
        }
    }

    private func addSystems() {
        runtime.apply(to: world)
        if world.count(of: Collider.self) > 0 {
            let physics = PhysicsWorld()
            runtime.apply(to: physics)
            world.addPhysics(physics)
            self.physics = physics
        }
        if world.count(of: Collider2D.self) > 0 {
            let physics = PhysicsWorld2D()
            runtime.apply(to: physics)
            world.addPhysics2D(physics)
            physics2D = physics
        }
        if world.count(of: SpriteAnimator.self) > 0 { world.addSpriteAnimationSystem(name: Self.spriteSystem) }
        // Not gated on an emitter already in the scene: game code spawns them after this returns.
        if let audio { spatialAudio = world.addSpatialAudio(audio, assets: assets) }
        world.addBuiltinAnimationSystems()
        for warning in module.addSystems(to: world, context: context) { log(warning) }
        systemsAdded = true
    }

    private func removeSystems() {
        guard systemsAdded else { return }
        if physics != nil {
            world.removePhysics()
            physics = nil
        }
        if physics2D != nil {
            world.removePhysics2D()
            physics2D = nil
        }
        world.removeSystem(named: Self.spriteSystem)
        spatialAudio?.remove()
        spatialAudio = nil
        module.removeSystems(from: world)
        systemsAdded = false
    }
}
