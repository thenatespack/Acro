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

/// The components the editor knows how to create from nothing ("Add Component"): every entry
/// pairs a registered component type with a factory for its default value. Components without
/// a factory can still be loaded, inspected, edited and removed, just not added from the menu.
///
/// Built in: Transform, Camera, DirectionalLight, SceneEnvironment, MeshRenderer (a cube) and
/// Spin. `Name` is left out on purpose: the inspector header edits it. Games register their own
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
        register(SceneEnvironment.self) { SceneEnvironment() }
        register(MeshRenderer.self) { MeshRenderer(mesh: .cube) }
        register(Spin.self) { Spin() }
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

extension World {
    /// Adds the editor's systems (`Spin`). They run only when the world updates, which the
    /// editor does in play mode.
    @MainActor public func addEditorSystems() {
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
