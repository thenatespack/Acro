import Foundation

// Scene files: entities, their components and the hierarchy, as JSON.
//
// ```json
// {
//   "entities" : [
//     {
//       "components" : {
//         "Transform" : {
//           "position" : [0, 1, 0],
//           "rotation" : [0, 0, 0, 1],
//           "scale" : [1, 1, 1]
//         }
//       },
//       "id" : 0,
//       "uid" : "3f2a9c1e5b7d4086a1c2d3e4f5a6b7c8"
//     },
//     {
//       "components" : {
//         "Follow" : {
//           "target" : { "$entity" : 0 }
//         }
//       },
//       "id" : 1,
//       "parent" : 0
//     }
//   ],
//   "format" : "SwiftGameEngine.Scene",
//   "version" : 2
// }
// ```
//
// - JSON because it's readable, diffs well and needs nothing beyond Foundation. Keys are
//   sorted, output is indented, and entity references and short numeric arrays (vectors,
//   quaternions, matrices) sit on one line. Saving the same world twice gives identical bytes, and loading a file
//   into an empty world and saving it again reproduces the file.
// - Entities are listed depth first: each root (in slot order, or in the order passed to
//   `save`), then its children in hierarchy order. `id` is the position in the list (it is
//   written out for readers and checked on load), and a parent always comes before its
//   children. Entities whose parent isn't saved are roots of the file.
// - Components are keyed by `componentName`. `GlobalTransform` and other components with
//   `isSerialized == false` are skipped; transforms are re-propagated after loading.
// - Entity references inside components are `{"$entity": id}` with file-local ids, or
//   `null` for an entity that wasn't saved (a stale handle, or one outside the saved
//   subtree). Loading maps ids to the new entities; `null` loads as nil for an optional
//   `Entity?` and as `Entity.invalid` otherwise.
// - `uid` is the entity's persistent `EntityID` (see EntityID.swift), written when it has
//   one. Loading keeps the uid unless another entity in the world already has it (loading
//   the same file twice), in which case the new entity gets a fresh one, or when asked to
//   regenerate them all (`EntityIDPolicy`). Entities without a uid get one if the world
//   has `assignsEntityIDs`.
// - Unknown component names don't fail the load: see `UnresolvedComponents`.
// - Systems are code and aren't saved; only data is. Neither are world timing and settings.
// - `version` is bumped on incompatible format changes. Older versions are migrated in
//   `SceneFile.init(from:)`; newer ones are rejected. Version 2 added `uid`; version 1
//   files have none (ids are assigned on load if the world wants them) and otherwise
//   load unchanged.

/// What `World.load` does with the `uid`s in a file.
public enum EntityIDPolicy: Sendable {
    /// Keep each uid unless the world already has an entity with it (the default). Loading a
    /// file into an empty world, or restoring entities that were despawned, gives the same
    /// ids back; loading it again gives the second copy new ones.
    case keepUnique
    /// Give every loaded entity a new id: for duplicating and instancing, where the copy
    /// must not be mistaken for the original.
    case regenerate
}

/// Errors from saving, loading and editing scenes.
public enum SceneError: Error, Equatable, CustomStringConvertible {
    /// The data isn't a scene file.
    case notASceneFile
    /// The file was written by a newer engine.
    case unsupportedVersion(Int)
    /// Two component types share a `componentName`, so the file couldn't say which is meant.
    case componentNameConflict(String)
    /// `load(_:under:)` was given a stale parent.
    case staleParent
    /// The entity doesn't have the component.
    case noSuchComponent(String)
    /// `setField` was given a path that doesn't name a field of the component.
    case noSuchField(String)
    /// `setField` was given a value of the wrong kind for the field.
    case typeMismatch(path: String, expected: String)

    public var description: String {
        switch self {
        case .notASceneFile: "Not a scene file"
        case .unsupportedVersion(let v): "Scene file version \(v) is newer than this engine supports (\(SceneFile.currentVersion))"
        case .componentNameConflict(let name): "Several component types are named '\(name)'; set componentName on one of them"
        case .staleParent: "The parent entity is not alive"
        case .noSuchComponent(let name): "The entity has no '\(name)' component"
        case .noSuchField(let path): "No field '\(path)'"
        case .typeMismatch(let path, let expected): "Field '\(path)' expects \(expected)"
        }
    }
}

extension World {
    /// Saves the whole world, or the subtrees under `roots` (descendants are included; a
    /// root that is a descendant of another is saved once, in place), as a scene file.
    /// Throws `SceneError.componentNameConflict` if a component's name is taken by another
    /// type, or an `EncodingError` from a component's `encode(to:)`.
    public func save(_ roots: [Entity]? = nil) throws -> Data {
        let order = saveOrder(roots)
        var ids: [Entity: Int] = [:]
        ids.reserveCapacity(order.count)
        for (id, entity) in order.enumerated() { ids[entity] = id }

        var records: [SceneFile.EntityRecord] = []
        records.reserveCapacity(order.count)
        for (id, entity) in order.enumerated() {
            var components: [String: SceneFile.ComponentValue] = [:]
            for store in storeOrder {
                let type = store.componentType
                guard type.isSerialized, let component = store.component(of: entity) else { continue }
                guard ComponentRegistry.owns(type) else { throw SceneError.componentNameConflict(type.componentName) }
                components[type.componentName] = .typed(component)
            }
            if let unresolved = get(UnresolvedComponents.self, for: entity) {
                for (name, raw) in unresolved.components where components[name] == nil {
                    components[name] = .raw(raw)
                }
            }
            let parent = parents[Int(entity.index)].flatMap { ids[$0] }
            records.append(SceneFile.EntityRecord(id: id, parent: parent, uid: entityIDs[Int(entity.index)], components: components))
        }

        let encoder = SceneCoder.encoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.userInfo[.sceneEncoding] = SceneEncodingContext(ids: ids)
        let json = try encoder.encode(SceneFile(entities: records))
        return Data(SceneCoder.collapsingNumericArrays(json))
    }

    /// Loads a scene file into this world, adding to what is there, and returns the file's
    /// root entities (in file order). With `parent`, the roots become its children (e.g. to
    /// instance a prefab). Entity ids follow `ids`. Nothing is spawned if the file fails to
    /// decode. Can't be called from inside a query.
    @discardableResult
    public func load(_ data: Data, under parent: Entity? = nil, ids policy: EntityIDPolicy = .keepUnique) throws -> [Entity] {
        precondition(!isIterating, "load(_:) can't run inside a query")
        if let parent, !isAlive(parent) { throw SceneError.staleParent }

        // Component decoding needs the entity each file id will become (for references),
        // before the file has been read; `spawn` hands out free slots last-in first-out,
        // then new slots, so predict that.
        let reusable = freeSlots.reversed().map { Entity(index: $0, generation: generations[Int($0)]) }
        let context = SceneDecodingContext(reusable: reusable, nextIndex: UInt32(generations.count))
        let decoder = SceneCoder.decoder()
        decoder.userInfo[.sceneDecoding] = context
        let file = try decoder.decode(SceneFile.self, from: data)
        guard context.maxReferencedID < file.entities.count else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Reference to entity \(context.maxReferencedID), which isn't in the file"))
        }

        var entities: [Entity] = []
        entities.reserveCapacity(file.entities.count)
        for _ in file.entities { entities.append(spawnEntity()) }
        for (id, entity) in entities.enumerated() {
            precondition(entity == context.entity(id: id), "Scene load: spawn order changed")
        }
        for (record, entity) in zip(file.entities, entities) {
            if policy == .keepUnique, let uid = record.uid, setEntityID(uid, for: entity) { continue }
            // New entity, or its id is taken: it counts as having had one, so it gets one.
            if assignsEntityIDs || record.uid != nil { ensureID(of: entity) }
        }

        var roots: [Entity] = []
        var unresolvedNames: Set<String> = []
        for (record, entity) in zip(file.entities, entities) {
            var unresolved: [String: JSONValue] = [:]
            for (name, value) in record.components {
                switch value {
                case .typed(let component): add(component, to: entity)
                case .raw(let raw): unresolved[name] = raw
                }
            }
            if !unresolved.isEmpty {
                add(UnresolvedComponents(components: unresolved), to: entity)
                unresolvedNames.formUnion(unresolved.keys)
            }
            if let p = record.parent {
                setParent(entity, to: entities[p])
            } else {
                roots.append(entity)
                if let parent { setParent(entity, to: parent) }
            }
        }
        if !unresolvedNames.isEmpty {
            print("Scene: unknown components \(unresolvedNames.sorted().joined(separator: ", ")) kept as UnresolvedComponents")
        }
        propagateTransforms()
        return roots
    }

    /// The entities `save` writes, in file order.
    private func saveOrder(_ requested: [Entity]?) -> [Entity] {
        var roots: [Entity]
        if let requested {
            var seen = Set<Entity>()
            let alive = requested.filter { isAlive($0) && seen.insert($0).inserted }
            // A requested entity under another requested one is saved as part of that subtree.
            roots = alive.filter { entity in !alive.contains { isDescendant(entity, of: $0) } }
        } else {
            roots = self.roots
        }
        var order: [Entity] = []
        var stack: [Entity] = []
        for root in roots {
            stack.append(root)
            while let entity = stack.popLast() {
                order.append(entity)
                stack.append(contentsOf: childLists[Int(entity.index)].reversed())
            }
        }
        return order
    }
}

// MARK: File structure

struct SceneFile: Codable {
    static let format = "SwiftGameEngine.Scene"
    static let currentVersion = 2

    var entities: [EntityRecord]

    struct EntityRecord: Codable {
        var id: Int
        var parent: Int?
        var uid: EntityID?
        var components: [String: ComponentValue]

        private enum CodingKeys: String, CodingKey { case id, parent, uid, components }

        init(id: Int, parent: Int?, uid: EntityID?, components: [String: ComponentValue]) {
            self.id = id
            self.parent = parent
            self.uid = uid
            self.components = components
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            parent = try container.decodeIfPresent(Int.self, forKey: .parent)
            uid = try container.decodeIfPresent(EntityID.self, forKey: .uid)
            components = [:]
            let context = decoder.userInfo[.sceneDecoding] as? SceneDecodingContext
            let map = try container.nestedContainer(keyedBy: JSONKey.self, forKey: .components)
            for key in map.allKeys {
                let name = key.stringValue
                if let type = context?.registry[name], type.isSerialized {
                    components[name] = .typed(try Self.decode(type, from: map, forKey: key))
                } else {
                    components[name] = .raw(try map.decode(JSONValue.self, forKey: key))
                }
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(parent, forKey: .parent)
            try container.encodeIfPresent(uid, forKey: .uid)
            var map = container.nestedContainer(keyedBy: JSONKey.self, forKey: .components)
            for (name, value) in components {
                switch value {
                case .typed(let component): try map.encode(AnyComponent(component), forKey: JSONKey(name))
                case .raw(let raw): try map.encode(raw, forKey: JSONKey(name))
                }
            }
        }

        private static func decode<C: Component>(
            _: C.Type, from container: KeyedDecodingContainer<JSONKey>, forKey key: JSONKey
        ) throws -> any Component {
            try container.decode(C.self, forKey: key)
        }
    }

    enum ComponentValue {
        case typed(any Component)
        case raw(JSONValue)
    }

    private enum CodingKeys: String, CodingKey { case format, version, entities }

    init(entities: [EntityRecord]) {
        self.entities = entities
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard (try? container.decode(String.self, forKey: .format)) == Self.format else { throw SceneError.notASceneFile }
        let version = try container.decode(Int.self, forKey: .version)
        guard version <= Self.currentVersion else { throw SceneError.unsupportedVersion(version) }
        // Version 1 has no `uid`s; they decode as nil. Nothing else changed.
        entities = try container.decode([EntityRecord].self, forKey: .entities)
        for (index, record) in entities.enumerated() {
            guard record.id == index, (record.parent.map { $0 >= 0 && $0 < index }) ?? true else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [CodingKeys.entities],
                    debugDescription: "Entity \(index): ids must count up from 0 and parents must come before their children"))
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.format, forKey: .format)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encode(entities, forKey: .entities)
    }
}

/// Encodes a component existential through its concrete type's `encode(to:)`.
struct AnyComponent: Encodable {
    let value: any Component
    init(_ value: any Component) { self.value = value }
    func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
}

// MARK: Entity references

extension CodingUserInfoKey {
    static let sceneEncoding = CodingUserInfoKey(rawValue: "Engine.SceneEncoding")!
    static let sceneDecoding = CodingUserInfoKey(rawValue: "Engine.SceneDecoding")!
}

/// While saving: the file id of every saved entity.
final class SceneEncodingContext: Sendable {
    let ids: [Entity: Int]
    init(ids: [Entity: Int]) { self.ids = ids }
}

/// While loading: the entity each file id will become, and a copy of the component
/// registry (decoding isn't main-actor isolated).
final class SceneDecodingContext: @unchecked Sendable {
    let reusable: [Entity]
    let nextIndex: UInt32
    let registry: [String: any Component.Type]
    /// The largest id an entity reference used, checked against the entity count after
    /// decoding (references may point forward, so it can't be checked while decoding).
    var maxReferencedID = -1

    @MainActor init(reusable: [Entity], nextIndex: UInt32) {
        self.reusable = reusable
        self.nextIndex = nextIndex
        registry = Dictionary(uniqueKeysWithValues: ComponentRegistry.names.map { ($0, ComponentRegistry.type(named: $0)!) })
    }

    func entity(id: Int) -> Entity {
        id < reusable.count ? reusable[id] : Entity(index: nextIndex + UInt32(id - reusable.count), generation: 0)
    }
}

extension Entity: Codable {
    static let codingKey = "$entity"
    private struct Key: CodingKey {
        var stringValue: String { Entity.codingKey }
        var intValue: Int? { nil }
        init() {}
        init?(stringValue: String) { if stringValue != Entity.codingKey { return nil } }
        init?(intValue: Int) { nil }
    }

    /// In a scene file, `{"$entity": id}` or `null` (see World+Serialization.swift);
    /// elsewhere `{"$entity": [index, generation]}`.
    public init(from decoder: any Decoder) throws {
        if try decoder.singleValueContainer().decodeNil() {
            self = .invalid
            return
        }
        let container = try decoder.container(keyedBy: Key.self)
        if let context = decoder.userInfo[.sceneDecoding] as? SceneDecodingContext {
            let id = try container.decode(Int.self, forKey: Key())
            guard id >= 0 && id < Int(Int32.max) else {
                throw DecodingError.dataCorruptedError(forKey: Key(), in: container, debugDescription: "Bad entity id \(id)")
            }
            context.maxReferencedID = max(context.maxReferencedID, id)
            self = context.entity(id: id)
        } else {
            var pair = try container.nestedUnkeyedContainer(forKey: Key())
            self.init(index: try pair.decode(UInt32.self), generation: try pair.decode(UInt32.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        if let context = encoder.userInfo[.sceneEncoding] as? SceneEncodingContext {
            guard let id = context.ids[self] else {
                var container = encoder.singleValueContainer()
                try container.encodeNil()
                return
            }
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(id, forKey: Key())
        } else {
            var container = encoder.container(keyedBy: Key.self)
            var pair = container.nestedUnkeyedContainer(forKey: Key())
            try pair.encode(index)
            try pair.encode(generation)
        }
    }
}

// MARK: Coders

enum SceneCoder {
    // JSON has no NaN or infinity; spell them as strings rather than failing.
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return decoder
    }

    /// Puts arrays of up to 16 numbers (`[0, 1, 0]`) and entity references
    /// (`{ "$entity" : 3 }`) on one line, leaving the rest of the pretty-printed JSON alone.
    static func collapsingNumericArrays(_ json: Data) -> [UInt8] {
        let bytes = [UInt8](json)
        var out: [UInt8] = []
        out.reserveCapacity(bytes.count)
        var i = 0
        var inString = false
        while i < bytes.count {
            let c = bytes[i]
            if inString {
                out.append(c)
                if c == UInt8(ascii: "\\"), i + 1 < bytes.count {
                    out.append(bytes[i + 1])
                    i += 2
                    continue
                }
                if c == UInt8(ascii: "\"") { inString = false }
                i += 1
                continue
            }
            if c == UInt8(ascii: "\"") { inString = true }
            if c == UInt8(ascii: "{"), let (digits, end) = entityReference(bytes, from: i + 1) {
                out.append(contentsOf: entityPrefix)
                out.append(contentsOf: bytes[digits])
                out.append(UInt8(ascii: " "))
                out.append(UInt8(ascii: "}"))
                i = end + 1
                continue
            }
            if c == UInt8(ascii: "["), let end = numericArrayEnd(bytes, from: i + 1) {
                // Copy the numbers without the line breaks and indentation.
                out.append(c)
                for j in (i + 1)..<end where bytes[j] != UInt8(ascii: " ") && bytes[j] != UInt8(ascii: "\n") {
                    out.append(bytes[j])
                    if bytes[j] == UInt8(ascii: ",") { out.append(UInt8(ascii: " ")) }
                }
                out.append(UInt8(ascii: "]"))
                i = end + 1
                continue
            }
            out.append(c)
            i += 1
        }
        return out
    }

    private static let entityKey = Array("\"\(Entity.codingKey)\" : ".utf8)
    private static let entityPrefix = Array("{ ".utf8) + entityKey

    /// For an object starting at `start` that is just an entity reference: the range of the
    /// id's digits and the index of the closing `}`.
    private static func entityReference(_ bytes: [UInt8], from start: Int) -> (Range<Int>, Int)? {
        var j = skippingSpace(bytes, from: start)
        guard j + entityKey.count < bytes.count, bytes[j..<(j + entityKey.count)].elementsEqual(entityKey) else { return nil }
        j += entityKey.count
        let digits = j
        while j < bytes.count, bytes[j] >= UInt8(ascii: "0") && bytes[j] <= UInt8(ascii: "9") { j += 1 }
        guard j > digits else { return nil }
        let end = skippingSpace(bytes, from: j)
        guard end < bytes.count, bytes[end] == UInt8(ascii: "}") else { return nil }
        return (digits..<j, end)
    }

    private static func skippingSpace(_ bytes: [UInt8], from start: Int) -> Int {
        var j = start
        while j < bytes.count, bytes[j] == UInt8(ascii: " ") || bytes[j] == UInt8(ascii: "\n") { j += 1 }
        return j
    }

    /// The index of the `]` closing an array that starts at `start` and holds at most 16
    /// numbers and nothing else.
    private static func numericArrayEnd(_ bytes: [UInt8], from start: Int) -> Int? {
        var j = start
        var commas = 0
        while j < bytes.count {
            switch bytes[j] {
            case UInt8(ascii: "]"):
                return j
            case UInt8(ascii: ","):
                commas += 1
                if commas == 16 { return nil }
                j += 1
            case UInt8(ascii: "0")...UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "+"), UInt8(ascii: "."),
                 UInt8(ascii: "e"), UInt8(ascii: "E"), UInt8(ascii: " "), UInt8(ascii: "\n"):
                j += 1
            default:
                return nil
            }
        }
        return nil
    }
}
