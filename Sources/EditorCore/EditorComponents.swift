import Engine

/// Rotates its entity about `axis` at `speed` radians per second while the world's systems run
/// (play mode). The starter scene uses it so that pressing Play visibly does something.
public struct Spin: Component, Equatable, Sendable {
    public static let componentName = "Spin"
    public static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(step: 0.05, tooltip: "Radians per second"), "axis": FieldHints(step: 0.1)]
    }

    public var axis: Vec3
    public var speed: Float

    public init(axis: Vec3 = Vec3(0, 1, 0), speed: Float = 1) {
        self.axis = axis
        self.speed = speed
    }
}

/// Moves its entity with the keyboard in play mode: W / S (or up / down) along -Z / +Z, A / D
/// (or left / right) along -X / +X, at `speed` units per second, reading the session's
/// `gameInput`, so injected input (`input.inject`) drives it. A dynamic `RigidBody` gets the
/// horizontal velocity instead, so physics stays in charge. The simplest playable character.
public struct KeyboardMover: Component, Equatable, Sendable {
    public static let componentName = "KeyboardMover"
    public static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(range: 0...100, step: 0.1, tooltip: "Units per second")]
    }

    public var speed: Float

    public init(speed: Float = 3) {
        self.speed = speed
    }
}

/// The components the editor knows how to create from nothing ("Add Component"): every entry
/// pairs a registered component type with a factory for its default value. Components without
/// a factory can still be loaded, inspected, edited and removed, just not added from the menu.
///
/// Built in: Transform, Camera, the lights, SceneEnvironment, PostProcess, MeshRenderer (a cube),
/// the physics components (a unit box Collider, a dynamic RigidBody, a ball Joint to the world,
/// a CharacterController), AudioListener and AudioEmitter (no sound until one is picked), the 2D physics components (a dynamic RigidBody2D, a unit
/// box Collider2D, a revolute Joint2D to the world), ParticleEmitter, Sprite (atlas "sprites", frame 0), SpriteAnimator (one looping "idle" clip), Saveable, Spin and
/// KeyboardMover. `Name` is left out on purpose: the inspector header edits it. Games register their own
/// with `register(_:make:)`, or `register(_:)` for types with a no-argument initializer.
@MainActor
public enum EditorComponentCatalog {
    private static var factories: [String: () -> any Component] = [:]
    private static var registeredBuiltins = false

    /// Makes `type` addable, created by `make`. Also registers it with `ComponentRegistry`.
    public static func register<C: Component>(_ type: C.Type, make: @escaping () -> C) {
        ComponentRegistry.register(type)
        factories[C.componentName] = make
    }

    /// Makes `type` addable, created with `init()`.
    public static func register<C: DefaultConstructibleComponent>(_ type: C.Type) {
        register(type) { C() }
    }

    /// Registers the engine's and editor's components. Idempotent; the editor calls it at startup.
    public static func registerBuiltins() {
        guard !registeredBuiltins else { return }
        registeredBuiltins = true
        ComponentRegistry.register(Transform.self, Name.self, Camera.self, DirectionalLight.self, SceneEnvironment.self,
                                   MeshRenderer.self, Spin.self)
        register(Transform.self) { Transform() }
        register(Camera.self) { Camera() }
        register(DirectionalLight.self) { DirectionalLight() }
        register(PointLight.self) { PointLight() }
        register(SpotLight.self) { SpotLight() }
        register(SceneEnvironment.self) { SceneEnvironment() }
        register(PostProcessSettings.self) { PostProcessSettings() }
        register(MeshRenderer.self) { MeshRenderer(mesh: .cube) }
        PhysicsWorld.registerComponents()
        register(Collider.self) { Collider(.box(halfExtents: Vec3(0.5, 0.5, 0.5))) }
        register(RigidBody.self) { RigidBody(.dynamic) }
        register(Joint.self) { Joint(.ball) }
        register(CharacterController.self) { CharacterController() }
        AudioSystem.registerComponents()
        register(AudioListener.self) { AudioListener() }
        register(AudioEmitter.self) { AudioEmitter() }
        PhysicsWorld2D.registerComponents()
        register(RigidBody2D.self) { RigidBody2D(.dynamic) }
        register(Collider2D.self) { Collider2D(.box(halfExtents: Vec2(0.5, 0.5))) }
        register(Joint2D.self) { Joint2D(.revolute) }
        ParticleSystem.registerComponents()
        register(ParticleEmitter.self) { ParticleEmitter() }
        register(Sprite.self) { Sprite(atlas: SpriteAtlasHandle("sprites")) }
        register(SpriteAnimator.self) { SpriteAnimator(clips: [SpriteClip("idle", frames: [0], fps: 12)]) }
        register(Saveable.self) { Saveable() }
        register(Spin.self) { Spin() }
        register(KeyboardMover.self) { KeyboardMover() }
    }

    /// Makes the component type registered as `name` addable, created by `make` (game modules,
    /// whose types are only known as `any Component.Type`). Register the type first.
    public static func register(named name: String, make: @escaping () -> any Component) {
        factories[name] = make
    }

    /// Makes the named components unaddable again (a game module was unloaded). Doesn't
    /// unregister them from `ComponentRegistry`.
    public static func unregister(_ names: some Sequence<String>) {
        for name in names { factories[name] = nil }
    }

    /// A new default value of the component registered as `name`, or nil if it has no factory.
    public static func makeDefault(named name: String) -> (any Component)? {
        factories[name]?()
    }

    /// Every addable component name, sorted.
    public static var addableNames: [String] { factories.keys.sorted() }

    /// The addable components `entity` doesn't have yet, sorted.
    public static func addableNames(for entity: Entity, in world: World) -> [String] {
        let present = Set(world.componentTypes(of: entity).map { $0.componentName })
        return addableNames.filter { !present.contains($0) }
    }
}

/// A component with a sensible default value (`init()`), addable with
/// `EditorComponentCatalog.register(_:)`.
public protocol DefaultConstructibleComponent: Component {
    init()
}

extension Spin: DefaultConstructibleComponent {
    public init() { self.init(axis: Vec3(0, 1, 0), speed: 1) }
}

extension KeyboardMover: DefaultConstructibleComponent {
    public init() { self.init(speed: 3) }
}

extension World {
    /// Adds the editor's systems (`Spin`, and `KeyboardMover` reading `input`). They run only
    /// when the world updates, which the editor does in play mode.
    @MainActor public func addEditorSystems(input: Input? = nil) {
        if let input, !systemNames(in: .update).contains("editor.keyboardMover") {
            addSystem("editor.keyboardMover", stage: .update) { world in
                let move = Vec3(input.axis(negative: .a, positive: .d) + input.axis(negative: .left, positive: .right), 0,
                                input.axis(negative: .w, positive: .s) + input.axis(negative: .up, positive: .down))
                let direction = length(move) > 0 ? normalize(move) : .zero
                let dt = world.time.delta
                var bodies: [(Entity, Vec3)] = []
                world.queryMutating(Transform.self, KeyboardMover.self) { entity, transform, mover in
                    if let body = world.get(RigidBody.self, for: entity), body.motion == .dynamic {
                        bodies.append((entity, direction * mover.speed))
                    } else {
                        transform.position += direction * mover.speed * dt
                    }
                }
                // A dynamic body keeps its fall; the mover sets the horizontal velocity.
                for (entity, velocity) in bodies {
                    world.modify(RigidBody.self, for: entity) { body in
                        body.linearVelocity = Vec3(velocity.x, body.linearVelocity.y, velocity.z)
                    }
                }
            }
        }
        guard !systemNames(in: .update).contains("editor.spin") else { return }
        addSystem("editor.spin", stage: .update) { world in
            let dt = world.time.delta
            world.queryMutating(Transform.self, Spin.self) { _, transform, spin in
                guard spin.speed != 0, length(spin.axis) > 0 else { return }
                transform.rotation = (Quat(angle: spin.speed * dt, axis: normalize(spin.axis)) * transform.rotation).normalized
            }
        }
    }
}
