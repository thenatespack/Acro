/// A handle to an entity in a `World`: a slot index plus the slot's generation. Despawning
/// bumps the slot's generation, so handles kept from before become stale: `isAlive` returns
/// false, lookups return nil and mutations are ignored, even after the slot is reused.
public struct Entity: Hashable, Sendable, CustomStringConvertible {
    public let index: UInt32
    public let generation: UInt32

    @inlinable init(index: UInt32, generation: UInt32) {
        self.index = index
        self.generation = generation
    }

    public var description: String { "Entity(\(index)v\(generation))" }
}

/// Anything stored on an entity. Components are plain value types (structs); conform and
/// add them with `World.add(_:to:)`.
///
/// Hook for the editor and serialization: `World.components(of:)` returns an entity's
/// components as `any Component`, and `add` / `remove` accept existentials (`any Component`,
/// `any Component.Type`), so tools can move components around without knowing their types
/// statically. Reflection (field lists, a name → type registry) builds on `componentName`.
public protocol Component {
    /// Stable name for tools and serialized data. Defaults to the type's name.
    static var componentName: String { get }
}

extension Component {
    public static var componentName: String { String(describing: Self.self) }
}
