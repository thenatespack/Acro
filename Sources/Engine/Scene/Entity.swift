/// A handle to an entity in a `World`: a slot index plus the slot's generation. Despawning
/// bumps the slot's generation, so handles kept from before become stale: `isAlive` returns
/// false, lookups return nil and mutations are ignored, even after the slot is reused.
///
/// Entities are `Codable` so components can hold references (`var target: Entity`). Scene
/// files store them as file-local ids and loading maps them to the new entities (see
/// World+Serialization.swift); elsewhere they encode as their index and generation.
public struct Entity: Hashable, Sendable, CustomStringConvertible {
    public let index: UInt32
    public let generation: UInt32

    @inlinable init(index: UInt32, generation: UInt32) {
        self.index = index
        self.generation = generation
    }

    /// A handle that is never alive in any world. Loading a scene gives it to non-optional
    /// entity references whose target wasn't saved.
    public static let invalid = Entity(index: .max, generation: .max)

    public var description: String { "Entity(\(index)v\(generation))" }
}

/// Anything stored on an entity. Components are plain value types (structs); conform and
/// add them with `World.add(_:to:)`.
///
/// Components are `Codable`, which scene files (`World.save`), snapshots for the editor and
/// the inspector's reflection (`fields()`, `setField`, see Reflection.swift) build on.
/// Synthesized conformance is enough when every stored property is Codable: numbers, `Bool`,
/// `String`, `Vec2/3/4`, `Quat`, `Entity`, enums, arrays, optionals and nested structs.
///
/// `World.components(of:)` returns an entity's components as `any Component`, and `add` /
/// `remove` accept existentials (`any Component`, `any Component.Type`), so tools can move
/// components around without knowing their types statically.
public protocol Component: Codable {
    /// Name in scene files and tools; `ComponentRegistry` maps it back to the type. Defaults
    /// to the type's name, which changes when the type is renamed and can clash between
    /// modules, so saved components should set it explicitly
    /// (`static let componentName = "Health"`) and keep it once files exist.
    static var componentName: String { get }

    /// Whether scene files store this component (default true). False for derived data that
    /// is recomputed after loading, such as `GlobalTransform`.
    static var isSerialized: Bool { get }

    /// Display hints for the inspector, keyed by field path (`"speed"`, `"light.color"`;
    /// `*` matches any array index, as in `"points.*"`). See `FieldHints`.
    static var fieldHints: [String: FieldHints] { get }
}

extension Component {
    public static var componentName: String { String(describing: Self.self) }
    public static var isSerialized: Bool { true }
    public static var fieldHints: [String: FieldHints] { [:] }
}
