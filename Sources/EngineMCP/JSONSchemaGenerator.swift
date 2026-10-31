import Foundation

// JSON Schemas derived from `Decodable` types, for tool input and output schemas.
//
// ```swift
// struct Arguments: Codable { var name: String; var position: [Float]?; var mode: Mode }   // Mode: String, CaseIterable
// JSONSchemaGenerator().schema(for: Arguments.self)
// // {"type": "object", "properties": {"name": {"type": "string"}, "position": {"type": "array",
// //  "items": {"type": "number"}}, "mode": {"type": "string", "enum": ["a", "b"]}}, "required": ["name", "mode"]}
// ```
//
// ## How
//
// The type decodes itself from a probing `Decoder` that records what `init(from:)` asks for and
// hands back placeholder values: keys asked for with `decode` are required, with
// `decodeIfPresent` optional (so synthesized optionals come out right, and so do hand-written
// decoders with defaults); keyed containers become objects, unkeyed ones arrays (with a fixed
// length when the decoder reads a fixed number of elements without checking `isAtEnd`; SIMD
// vectors are recognised directly), single values their primitive type. `CaseIterable & Encodable` types become
// an `enum` of their encoded cases. Since this follows the decoding code rather than the
// stored properties, the schema matches what the type actually accepts.
//
// What a probe can't see: string formats a type validates in `init(from:)` (an id parsed from a
// string comes out as a plain string), types that try several shapes (`try?` decoding comes
// out as the first shape tried), and documentation. For those, register an override (or adopt
// `JSONSchemaProviding`) with the schema and, when the type validates its input, a sample
// value to hand to the decoder that contains it.

/// A type that states its own JSON Schema instead of being probed.
public protocol JSONSchemaProviding {
    static var jsonSchema: JSON { get }
    /// A value to hand back to a decoder that contains this type (needed when its
    /// `init(from:)` would reject placeholder input such as an empty string).
    static var jsonSchemaSample: Self? { get }
}

extension JSONSchemaProviding {
    public static var jsonSchemaSample: Self? { nil }
}

/// Derives JSON Schemas from `Decodable` types; see the notes at the top of this file.
public struct JSONSchemaGenerator {
    private struct Override {
        var schema: JSON
        var sample: Any?
    }

    private var overrides: [ObjectIdentifier: Override] = [:]
    /// Deeper nesting (recursive types) comes out as `{}` (any value).
    public var maxDepth = 24

    public init() {}

    /// Uses `schema` for `type` wherever it appears. `sample` is handed to decoders that
    /// contain it (needed when `type` validates its input).
    public mutating func override<T: Decodable>(_ type: T.Type, schema: JSON, sample: T? = nil) {
        overrides[ObjectIdentifier(type)] = Override(schema: schema, sample: sample)
    }

    /// The schema of `type`.
    public func schema<T: Decodable>(for type: T.Type) -> JSON {
        let node = SchemaNode()
        _ = probe(type, into: node, depth: 0)
        return node.json
    }

    /// Records `type`'s schema in `node` and returns a value of it if one could be made.
    func probe<T: Decodable>(_ type: T.Type, into node: SchemaNode, depth: Int) -> T? {
        if let override = overrides[ObjectIdentifier(type)] {
            node.kind = .schema(override.schema)
            return override.sample as? T ?? probeValue(type, depth: depth)
        }
        if depth > maxDepth {
            node.kind = .schema([:])
            return nil
        }
        if let primitive = Self.primitive(type) {
            node.kind = .schema(primitive.schema)
            return primitive.sample as? T
        }
        if let provider = type as? any JSONSchemaProviding.Type {
            node.kind = .schema(provider.jsonSchema)
            return provider.jsonSchemaSample as? T ?? probeValue(type, depth: depth)
        }
        if let vector = type as? any SIMD.Type {
            // SIMD vectors check the container's count before decoding, which a probe can't know.
            let shape = Self.simdShape(vector)
            node.kind = .schema(["type": "array", "items": ["type": shape.floating ? "number" : "integer"],
                                 "minItems": .int(Int64(shape.count)), "maxItems": .int(Int64(shape.count))])
            return shape.zero as? T
        }
        if let enumeration = type as? any (CaseIterable & Encodable).Type, let cases = Self.cases(of: enumeration) {
            node.kind = .schema(cases.schema)
            return cases.first as? T
        }
        if let dictionary = type as? any StringKeyedDictionary.Type {
            let values = SchemaNode()
            dictionary.probeValue(self, into: values, depth: depth + 1)
            node.kind = .dictionary(values)
            return dictionary.empty as? T
        }
        let decoder = SchemaProbe(generator: self, node: node, depth: depth + 1)
        return try? T(from: decoder)
    }

    /// A value of `type` from a throwaway probe (for overrides without a sample).
    private func probeValue<T: Decodable>(_ type: T.Type, depth: Int) -> T? {
        try? T(from: SchemaProbe(generator: self, node: SchemaNode(), depth: depth + 1))
    }

    private static func primitive(_ type: Any.Type) -> (schema: JSON, sample: Any)? {
        switch type {
        case is String.Type: (["type": "string"], "")
        case is Bool.Type: (["type": "boolean"], false)
        case is Int.Type: (["type": "integer"], Int(0))
        case is Int8.Type: (["type": "integer"], Int8(0))
        case is Int16.Type: (["type": "integer"], Int16(0))
        case is Int32.Type: (["type": "integer"], Int32(0))
        case is Int64.Type: (["type": "integer"], Int64(0))
        case is UInt.Type: (["type": "integer", "minimum": 0], UInt(0))
        case is UInt8.Type: (["type": "integer", "minimum": 0], UInt8(0))
        case is UInt16.Type: (["type": "integer", "minimum": 0], UInt16(0))
        case is UInt32.Type: (["type": "integer", "minimum": 0], UInt32(0))
        case is UInt64.Type: (["type": "integer", "minimum": 0], UInt64(0))
        case is Float.Type: (["type": "number"], Float(0))
        case is Double.Type: (["type": "number"], Double(0))
        case is JSON.Type: ([:], JSON.null)
        default: nil
        }
    }

    private static func simdShape<V: SIMD>(_ type: V.Type) -> (count: Int, floating: Bool, zero: Any) {
        let zero = V()
        return (zero.scalarCount, V.Scalar.self is any BinaryFloatingPoint.Type, zero)
    }

    private struct Cases {
        var schema: JSON
        var first: Any?
    }

    private static func cases<C: CaseIterable & Encodable>(of type: C.Type) -> Cases? {
        let all = Array(type.allCases)
        let values = all.compactMap { try? JSON(encoding: $0) }
        guard !all.isEmpty, values.count == all.count else { return nil }
        let schema: JSON
        if values.allSatisfy({ $0.stringValue != nil }) {
            schema = ["type": "string", "enum": .array(values)]
        } else if values.allSatisfy({ if case .int = $0 { true } else { false } }) {
            schema = ["type": "integer", "enum": .array(values)]
        } else {
            schema = ["enum": .array(values)]
        }
        return Cases(schema: schema, first: all.first)
    }
}

// MARK: Recording

/// What a probe learned about one value; turned into a schema once decoding is done.
final class SchemaNode {
    enum Kind {
        case unknown
        case schema(JSON)
        case object(ObjectShape)
        case array(ArrayShape)
        case dictionary(SchemaNode)
    }

    final class ObjectShape {
        var properties: [(key: String, node: SchemaNode, required: Bool)] = []

        func add(_ key: String, _ node: SchemaNode, required: Bool) {
            if let i = properties.firstIndex(where: { $0.key == key }) {
                properties[i].required = properties[i].required || required
            } else {
                properties.append((key, node, required))
            }
        }
    }

    final class ArrayShape {
        var items: [SchemaNode] = []
        /// The decoder checked `isAtEnd`: any length. Otherwise exactly `items.count`.
        var variableLength = false
    }

    var kind: Kind = .unknown

    var json: JSON {
        switch kind {
        case .unknown:
            return [:]
        case .schema(let schema):
            return schema
        case .object(let shape):
            var properties: [String: JSON] = [:]
            for property in shape.properties { properties[property.key] = property.node.json }
            var object: [String: JSON] = ["type": "object", "properties": .object(properties)]
            let required = shape.properties.filter(\.required).map { JSON.string($0.key) }
            if !required.isEmpty { object["required"] = .array(required) }
            return .object(object)
        case .array(let shape):
            var object: [String: JSON] = ["type": "array", "items": shape.items.first?.json ?? [:]]
            if !shape.variableLength {
                object["minItems"] = .int(Int64(shape.items.count))
                object["maxItems"] = .int(Int64(shape.items.count))
            }
            return .object(object)
        case .dictionary(let values):
            return ["type": "object", "additionalProperties": values.json]
        }
    }
}

/// `[String: Value]`, which decodes through a keyed container whose keys it lists itself.
protocol StringKeyedDictionary {
    static var empty: Self { get }
    static func probeValue(_ generator: JSONSchemaGenerator, into node: SchemaNode, depth: Int)
}

extension Dictionary: StringKeyedDictionary where Key == String, Value: Decodable {
    static var empty: Self { [:] }
    static func probeValue(_ generator: JSONSchemaGenerator, into node: SchemaNode, depth: Int) {
        _ = generator.probe(Value.self, into: node, depth: depth)
    }
}

/// Thrown when a required value can't be made (its type rejects placeholders and has no
/// sample): the containing type's schema keeps what was recorded before it.
private struct ProbeAbort: Error {}

private struct SchemaProbe: Decoder {
    let generator: JSONSchemaGenerator
    let node: SchemaNode
    let depth: Int
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    init(generator: JSONSchemaGenerator, node: SchemaNode, depth: Int) {
        self.generator = generator
        self.node = node
        self.depth = depth
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let shape: SchemaNode.ObjectShape
        if case .object(let existing) = node.kind {
            shape = existing
        } else {
            shape = SchemaNode.ObjectShape()
            node.kind = .object(shape)
        }
        return KeyedDecodingContainer(KeyedProbe<Key>(probe: self, shape: shape))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let shape: SchemaNode.ArrayShape
        if case .array(let existing) = node.kind {
            shape = existing
        } else {
            shape = SchemaNode.ArrayShape()
            node.kind = .array(shape)
        }
        return UnkeyedProbe(probe: self, shape: shape)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SingleProbe(probe: self)
    }

    /// Probes a nested value of `type` into `node`; throws if no value can be made.
    func value<T: Decodable>(_ type: T.Type, into node: SchemaNode) throws -> T {
        guard let value = generator.probe(type, into: node, depth: depth) else { throw ProbeAbort() }
        return value
    }
}

private struct KeyedProbe<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let probe: SchemaProbe
    let shape: SchemaNode.ObjectShape
    var codingPath: [any CodingKey] { probe.codingPath }
    var allKeys: [Key] { [] }

    func contains(_ key: Key) -> Bool { true }
    func decodeNil(forKey key: Key) throws -> Bool { false }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: true)
        return try probe.value(type, into: node)
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: false)
        _ = probe.generator.probe(type, into: node, depth: probe.depth)
        return nil
    }

    // The primitive overloads, routed through the generic ones (the protocol's defaults for the
    // IfPresent variants would call `decode` and mark the key required).
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try decode(type as Bool.Type, key) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try decode(type as String.Type, key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try decode(type as Double.Type, key) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try decode(type as Float.Type, key) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try decode(type as Int.Type, key) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try decode(type as Int8.Type, key) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try decode(type as Int16.Type, key) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try decode(type as Int32.Type, key) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try decode(type as Int64.Type, key) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try decode(type as UInt.Type, key) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try decode(type as UInt8.Type, key) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try decode(type as UInt16.Type, key) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try decode(type as UInt32.Type, key) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try decode(type as UInt64.Type, key) }

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? { try optional(type, key) }
    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? { try optional(type, key) }
    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { try optional(type, key) }
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { try optional(type, key) }
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { try optional(type, key) }
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? { try optional(type, key) }
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? { try optional(type, key) }
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? { try optional(type, key) }
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { try optional(type, key) }
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? { try optional(type, key) }
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? { try optional(type, key) }
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? { try optional(type, key) }
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? { try optional(type, key) }
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? { try optional(type, key) }

    private func decode<T: Decodable>(_ type: T.Type, _ key: Key) throws -> T {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: true)
        return try probe.value(type, into: node)
    }

    private func optional<T: Decodable>(_ type: T.Type, _ key: Key) throws -> T? {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: false)
        _ = probe.generator.probe(type, into: node, depth: probe.depth)
        return nil
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
        -> KeyedDecodingContainer<NestedKey> {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: true)
        return try SchemaProbe(generator: probe.generator, node: node, depth: probe.depth + 1).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: true)
        return try SchemaProbe(generator: probe.generator, node: node, depth: probe.depth + 1).unkeyedContainer()
    }

    func superDecoder() throws -> any Decoder {
        SchemaProbe(generator: probe.generator, node: SchemaNode(), depth: probe.depth + 1)
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        let node = SchemaNode()
        shape.add(key.stringValue, node, required: true)
        return SchemaProbe(generator: probe.generator, node: node, depth: probe.depth + 1)
    }
}

private struct UnkeyedProbe: UnkeyedDecodingContainer {
    let probe: SchemaProbe
    let shape: SchemaNode.ArrayShape
    var codingPath: [any CodingKey] { probe.codingPath }
    var count: Int? { nil }
    var currentIndex = 0

    init(probe: SchemaProbe, shape: SchemaNode.ArrayShape) {
        self.probe = probe
        self.shape = shape
    }

    /// One element is enough to learn the element type; a decoder that loops until the end
    /// stops after it.
    var isAtEnd: Bool {
        shape.variableLength = true
        return currentIndex >= 1
    }

    mutating func decodeNil() throws -> Bool { false }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let node = SchemaNode()
        if currentIndex >= shape.items.count { shape.items.append(node) }
        currentIndex += 1
        return try probe.value(type, into: node)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        let node = SchemaNode()
        if currentIndex >= shape.items.count { shape.items.append(node) }
        currentIndex += 1
        return try SchemaProbe(generator: probe.generator, node: node, depth: probe.depth + 1).container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        let node = SchemaNode()
        if currentIndex >= shape.items.count { shape.items.append(node) }
        currentIndex += 1
        return try SchemaProbe(generator: probe.generator, node: node, depth: probe.depth + 1).unkeyedContainer()
    }

    mutating func superDecoder() throws -> any Decoder {
        SchemaProbe(generator: probe.generator, node: SchemaNode(), depth: probe.depth + 1)
    }
}

private struct SingleProbe: SingleValueDecodingContainer {
    let probe: SchemaProbe
    var codingPath: [any CodingKey] { probe.codingPath }

    func decodeNil() -> Bool { false }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        // The value is the probe's own: record into its node.
        try probe.value(type, into: probe.node)
    }

    func decode(_ type: Bool.Type) throws -> Bool { try probe.value(type, into: probe.node) }
    func decode(_ type: String.Type) throws -> String { try probe.value(type, into: probe.node) }
    func decode(_ type: Double.Type) throws -> Double { try probe.value(type, into: probe.node) }
    func decode(_ type: Float.Type) throws -> Float { try probe.value(type, into: probe.node) }
    func decode(_ type: Int.Type) throws -> Int { try probe.value(type, into: probe.node) }
    func decode(_ type: Int8.Type) throws -> Int8 { try probe.value(type, into: probe.node) }
    func decode(_ type: Int16.Type) throws -> Int16 { try probe.value(type, into: probe.node) }
    func decode(_ type: Int32.Type) throws -> Int32 { try probe.value(type, into: probe.node) }
    func decode(_ type: Int64.Type) throws -> Int64 { try probe.value(type, into: probe.node) }
    func decode(_ type: UInt.Type) throws -> UInt { try probe.value(type, into: probe.node) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try probe.value(type, into: probe.node) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try probe.value(type, into: probe.node) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try probe.value(type, into: probe.node) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try probe.value(type, into: probe.node) }
}
