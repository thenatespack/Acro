/// Maps `componentName`s to component types, so scene files, undo records and the editor's
/// "Add Component" menu can refer to component types by name.
///
/// The registry is global rather than per `World`: which types exist is a property of the
/// program, not of a world. An empty world loading a scene has never seen its types (its
/// `registeredComponentTypes` lists only types added to it), and the editor's world, the
/// play-mode world and prefab worlds all need the same mapping.
///
/// Every type a world stores is registered automatically the first time it is added, and
/// the engine's own components are registered up front. Call `register` at startup for the
/// rest, typically every game component, so that loading a scene doesn't depend on which
/// types happen to have been used already. A name that isn't registered when a scene loads
/// is kept as raw data (`UnresolvedComponents`) rather than failing.
///
/// Main-actor isolated, like `World`.
@MainActor
public enum ComponentRegistry {
    private static var byName: [String: any Component.Type] = [
        Transform.componentName: Transform.self,
        GlobalTransform.componentName: GlobalTransform.self,
    ]

    /// Registers `types` under their `componentName`. Registering a type again is a no-op;
    /// registering a different type under a taken name is a programmer error (give one of
    /// them an explicit `componentName`).
    public static func register(_ types: any Component.Type...) {
        for type in types {
            let name = type.componentName
            if let existing = byName[name] {
                precondition(existing == type, "Component name '\(name)' is used by both \(existing) and \(type); set componentName on one of them")
            } else {
                byName[name] = type
            }
        }
    }

    /// Called when a world first stores `type`. Unlike `register`, a name clash isn't fatal
    /// here (two unrelated modules may both have a `Position`); the first type keeps the
    /// name, and saving the other throws `SceneError.componentNameConflict`.
    static func registerImplicitly(_ type: any Component.Type) {
        let name = type.componentName
        if byName[name] == nil { byName[name] = type }
    }

    /// The type registered as `name`, if any.
    public static func type(named name: String) -> (any Component.Type)? {
        byName[name]
    }

    /// Every registered name, sorted.
    public static var names: [String] { byName.keys.sorted() }

    /// Whether `type` is the type registered under its own name.
    static func owns(_ type: any Component.Type) -> Bool {
        byName[type.componentName] == type
    }
}
