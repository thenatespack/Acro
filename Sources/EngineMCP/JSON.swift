import Foundation

/// A JSON value: what MCP messages, tool arguments and results, and JSON Schemas are made of.
/// Objects encode with sorted keys (`data()`), so output is deterministic.
public enum JSON: Hashable, Sendable, Codable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSON])
    case object([String: JSON])

    public init(from decoder: any Decoder) throws {
        let single = try decoder.singleValueContainer()
        if single.decodeNil() { self = .null; return }
        if let value = try? single.decode(Bool.self) { self = .bool(value); return }
        if let value = try? single.decode(Int64.self) { self = .int(value); return }
        if let value = try? single.decode(Double.self) { self = .double(value); return }
        if let value = try? single.decode(String.self) { self = .string(value); return }
        if let value = try? single.decode([JSON].self) { self = .array(value); return }
        self = .object(try single.decode([String: JSON].self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let values): try container.encode(values)
        case .object(let values): try container.encode(values)
        }
    }

    /// Parses JSON text.
    public init(data: Data) throws {
        self = try JSONDecoder().decode(JSON.self, from: data)
    }

    /// Parses JSON text.
    public init(parsing text: String) throws {
        try self.init(data: Data(text.utf8))
    }

    /// `value` as JSON (through its `Encodable` conformance).
    public init<T: Encodable>(encoding value: T) throws {
        self = try JSON(data: Self.encoder.encode(value))
    }

    /// Decodes a `T` from this value.
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: data())
    }

    /// Compact JSON text with sorted keys (one line, as the stdio transport needs).
    public func data() -> Data {
        // Encoding a JSON value can't fail: every case is a valid JSON value (non-finite
        // doubles are written as null).
        (try? Self.encoder.encode(self.finite)) ?? Data("null".utf8)
    }

    /// Compact JSON text with sorted keys.
    public var text: String { String(decoding: data(), as: UTF8.self) }

    /// Indented JSON text with sorted keys (for text renderings of results).
    public var prettyText: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return (try? encoder.encode(finite)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    /// NaN and infinities replaced by null (JSONEncoder refuses them).
    private var finite: JSON {
        switch self {
        case .double(let d) where !d.isFinite: .null
        case .array(let values): .array(values.map(\.finite))
        case .object(let values): .object(values.mapValues(\.finite))
        default: self
        }
    }

    // MARK: Access

    /// The member `key` of an object (nil for other values or a missing key).
    public subscript(key: String) -> JSON? {
        get {
            guard case .object(let values) = self else { return nil }
            return values[key]
        }
        set {
            guard case .object(var values) = self else { return }
            values[key] = newValue
            self = .object(values)
        }
    }

    public var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    public var intValue: Int? {
        switch self {
        case .int(let i): return Int(exactly: i)
        case .double(let d): return Int(exactly: d)
        default: return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .int(let i): return Double(i)
        case .double(let d): return d
        default: return nil
        }
    }

    public var arrayValue: [JSON]? {
        if case .array(let a) = self { return a }
        return nil
    }

    public var objectValue: [String: JSON]? {
        if case .object(let o) = self { return o }
        return nil
    }

    public var isNull: Bool { self == .null }
}

extension JSON: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral,
                ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral,
                ExpressibleByDictionaryLiteral {
    public init(nilLiteral: ()) { self = .null }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(integerLiteral value: Int64) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(stringLiteral value: String) { self = .string(value) }
    public init(arrayLiteral elements: JSON...) { self = .array(elements) }
    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}

extension JSON {
    /// Numbers compare by value: `1` equals `1.0` (JSON text doesn't tell them apart).
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null): true
        case (.bool(let x), .bool(let y)): x == y
        case (.string(let x), .string(let y)): x == y
        case (.array(let x), .array(let y)): x == y
        case (.object(let x), .object(let y)): x == y
        case (.int(let x), .int(let y)): x == y
        case (.int, .double), (.double, .int), (.double, .double): lhs.doubleValue == rhs.doubleValue
        default: false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null: hasher.combine(0)
        case .bool(let b): hasher.combine(b)
        case .int, .double: hasher.combine(doubleValue)
        case .string(let s): hasher.combine(s)
        case .array(let a): hasher.combine(a)
        case .object(let o): hasher.combine(o)
        }
    }
}

extension JSON: CustomStringConvertible {
    public var description: String { text }
}
