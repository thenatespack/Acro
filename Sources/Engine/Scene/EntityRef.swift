// Persistent entity references for component fields.
//
// An `Entity` field is a handle: fine inside one subtree (scene files and undo remap handles
// between the entities they save), but it goes stale when its target is despawned and brought
// back by undo, and a reference from inside a saved subtree to an entity outside it loads as
// nil. `EntityRef` names its target by `EntityID` instead, so it survives everything ids
// survive: save/load, undo of a delete (the entity comes back with the same id), snapshot /
// restore and play mode. It resolves through `World.entity(for:)` (O(1)) and is nil while the
// target doesn't exist.
//
// ```swift
// struct Follow: Component {
//     var target = EntityRef()
// }
// world.add(Follow(target: world.ref(to: player)), to: camera)
// if let player = world.resolve(follow.target) { … }
// ```
//
// ## Copies
//
// Loading entities that get new ids (`World.load(_:ids: .regenerate)`: duplicating, prefab
// instances, a file loaded twice) remaps every `EntityRef` that points into the loaded data to
// the copy, so references inside a duplicated subtree point at the duplicates, and references
// to entities outside it are left alone. See World+Serialization.swift.
//
// ## Encoding
//
// `{"$ref": "<32 hex digits>"}`, or `null` for none, everywhere (scene files, JSON, reflection
// trees), so tools can tell a reference from a string. Decoding also accepts the bare id string
// (what the inspector and `component.setField` write) and "" for none. Reflection shows it as
// an optional string field holding the id (`FieldDescriptor.isEntityReference`), which the
// editor turns into an entity picker.

/// A reference to an entity by `EntityID` that survives save/load, undo, duplication and
/// play mode; see the notes at the top of this file. Resolve it with `World.resolve(_:)`.
public struct EntityRef: Hashable, Sendable, Codable, CustomStringConvertible {
    /// The target's id, or nil for no target.
    public var id: EntityID?

    public init(_ id: EntityID? = nil) {
        self.id = id
    }

    /// No target.
    public static let none = EntityRef()

    public var isNone: Bool { id == nil }

    public var description: String { id.map { "EntityRef(\($0))" } ?? "EntityRef(none)" }

    static let codingKey = "$ref"

    public init(from decoder: any Decoder) throws {
        let single = try decoder.singleValueContainer()
        let text: String
        if single.decodeNil() {
            id = nil
            return
        } else if let string = try? single.decode(String.self) {
            text = string
        } else {
            let container = try decoder.container(keyedBy: JSONKey.self)
            guard let value = try container.decodeIfPresent(String.self, forKey: JSONKey(Self.codingKey)) else {
                id = nil
                return
            }
            text = value
        }
        guard !text.isEmpty else {
            id = nil
            return
        }
        guard let parsed = EntityID(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad entity id '\(text)'"))
        }
        // While loading entities that got new ids, a reference into the loaded data follows it.
        if let context = decoder.userInfo[.sceneDecoding] as? SceneDecodingContext, let mapped = context.uidRemap[parsed] {
            id = mapped
        } else {
            id = parsed
        }
    }

    public func encode(to encoder: any Encoder) throws {
        guard let id else {
            var single = encoder.singleValueContainer()
            try single.encodeNil()
            return
        }
        var container = encoder.container(keyedBy: JSONKey.self)
        try container.encode(id.description, forKey: JSONKey(Self.codingKey))
    }
}

extension World {
    /// A reference to `entity`, giving it an id first if it has none (`EntityRef.none` for a
    /// stale handle).
    public func ref(to entity: Entity) -> EntityRef {
        EntityRef(ensureID(of: entity))
    }

    /// The live entity `ref` names, or nil (no target, or it doesn't exist now).
    public func resolve(_ ref: EntityRef) -> Entity? {
        ref.id.flatMap { entity(for: $0) }
    }
}
