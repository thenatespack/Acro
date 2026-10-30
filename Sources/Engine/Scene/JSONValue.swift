import Foundation

/// An untyped JSON value: what a scene file holds for a component whose type isn't
/// registered (`UnresolvedComponents`), and the intermediate form `setField` patches.
///
/// Entity references (`{"$entity": …}`, see `Entity`'s Codable) are recognised and kept as
/// `.entity` handles, so they are remapped like typed ones when the data is saved again.
public enum JSONValue: Hashable, Sendable, Codable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
    case entity(Entity)

    public init(from decoder: any Decoder) throws {
        let single = try decoder.singleValueContainer()
        if single.decodeNil() { self = .null; return }
        if let value = try? single.decode(Bool.self) { self = .bool(value); return }
        if let value = try? single.decode(Int64.self) { self = .int(value); return }
        if let value = try? single.decode(Double.self) { self = .double(value); return }
        if let value = try? single.decode(String.self) { self = .string(value); return }
        if let value = try? single.decode([JSONValue].self) { self = .array(value); return }
        let keyed = try decoder.container(keyedBy: JSONKey.self)
        if keyed.allKeys.count == 1, keyed.allKeys[0].stringValue == Entity.codingKey {
            self = .entity(try Entity(from: decoder))
            return
        }
        var object: [String: JSONValue] = [:]
        for key in keyed.allKeys { object[key.stringValue] = try keyed.decode(JSONValue.self, forKey: key) }
        self = .object(object)
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .entity(let entity):
            try entity.encode(to: encoder)
        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values { try container.encode(value) }
        case .object(let values):
            var container = encoder.container(keyedBy: JSONKey.self)
            for (key, value) in values { try container.encode(value, forKey: JSONKey(key)) }
        default:
            var container = encoder.singleValueContainer()
            switch self {
            case .null: try container.encodeNil()
            case .bool(let value): try container.encode(value)
            case .int(let value): try container.encode(value)
            case .double(let value): try container.encode(value)
            case .string(let value): try container.encode(value)
            case .array, .object, .entity: break
            }
        }
    }

    /// Encodes `value` (outside a scene file, so entities stay live handles).
    static func encoding<T: Encodable>(_ value: T) throws -> JSONValue {
        try SceneCoder.decoder().decode(JSONValue.self, from: SceneCoder.encoder().encode(value))
    }

    /// Decodes a `T` from this value (outside a scene file).
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try SceneCoder.decoder().decode(T.self, from: SceneCoder.encoder().encode(self))
    }
}

/// A coding key with any name.
struct JSONKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// Components of an entity whose names weren't registered when its scene was loaded (a
/// type that was renamed without keeping its `componentName`, or one from a module that
/// isn't linked). They are kept as raw JSON, keyed by component name, so saving the entity
/// writes them back unchanged (entity references inside are remapped); a warning is
/// printed on load. Once the types are registered, `World.resolveUnresolvedComponents()`
/// turns them into real components.
public struct UnresolvedComponents: Component, Equatable, Sendable {
    public static let componentName = "UnresolvedComponents"
    /// Saved under the original names instead (see `World.save`).
    public static var isSerialized: Bool { false }
    public static var fieldHints: [String: FieldHints] { ["components": FieldHints(readOnly: true)] }

    public internal(set) var components: [String: JSONValue]
}

extension World {
    /// Turns the `UnresolvedComponents` entries whose names are now registered into real
    /// components. Returns how many were resolved. Entries that fail to decode stay raw.
    @discardableResult
    public func resolveUnresolvedComponents() -> Int {
        precondition(!isIterating, "resolveUnresolvedComponents() can't run inside a query")
        var pending: [(Entity, UnresolvedComponents)] = []
        query(UnresolvedComponents.self) { pending.append(($0, $1)) }
        var resolved = 0
        for (entity, unresolved) in pending {
            var remaining = unresolved.components
            for (name, raw) in unresolved.components.sorted(by: { $0.key < $1.key }) {
                guard let type = ComponentRegistry.type(named: name),
                      let component = try? Self.decodeComponent(type, from: raw) else { continue }
                add(component, to: entity)
                remaining[name] = nil
                resolved += 1
            }
            if remaining.isEmpty {
                remove(UnresolvedComponents.self, from: entity)
            } else {
                add(UnresolvedComponents(components: remaining), to: entity)
            }
        }
        return resolved
    }

    private static func decodeComponent<C: Component>(_ type: C.Type, from raw: JSONValue) throws -> any Component {
        try raw.decode(C.self)
    }
}
