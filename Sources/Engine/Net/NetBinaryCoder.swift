// Networking (card 662): a compact binary format for Codable values, used for replicated
// components other than Transform (which has its own quantized encoding).
//
// Self-describing like JSON (so custom `init(from:)`s that check `contains` or decode keys in
// any order still work, and `decodeIfPresent` / optionals behave), but binary: one tag byte per
// value, integers as zigzag / plain LEB128 varints, floats as their raw 4 or 8 bytes (exact),
// strings and keys length-prefixed UTF-8, map keys sorted so equal values give equal bytes
// (snapshots detect changes by comparing bytes). A small component is roughly half its
// sorted-key JSON; keys are still spelled out (they dominate small structs).

/// Encodes `Encodable` values to the compact binary format `NetBinaryDecoder` reads.
public struct NetBinaryEncoder {
    /// Handed to the values' `encode(to:)` (replication maps `Entity` handles to ids through it).
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> [UInt8] {
        let root = NetValueBox()
        try NetValueBox.encode(value, into: root, codingPath: [], userInfo: userInfo)
        var w = ByteWriter()
        root.write(to: &w)
        return w.data
    }
}

/// Decodes what `NetBinaryEncoder` wrote. Malformed input throws (`NetError.malformed` or a
/// `DecodingError`), never traps; nesting is limited to `maxDepth`.
public struct NetBinaryDecoder {
    public static let maxDepth = 64
    /// Handed to the values' `init(from:)` (replication maps entity ids to handles through it).
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    public func decode<T: Decodable>(_ type: T.Type, from bytes: [UInt8]) throws -> T {
        var r = ByteReader(bytes)
        let value = try NetValue.read(&r, depth: 0)
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        return try T(from: NetValueDecoder(value: value, codingPath: [], userInfo: userInfo))
    }
}

// MARK: Values

enum NetValueTag: UInt8 {
    case null = 0, `false`, `true`, int, uint, f32, f64, string, array, map
}

/// A decoded value tree.
indirect enum NetValue {
    case null
    case bool(Bool)
    case int(Int64)
    case uint(UInt64)
    case f32(Float)
    case f64(Double)
    case string(String)
    case array([NetValue])
    case map([String: NetValue])

    static func read(_ r: inout ByteReader, depth: Int) throws -> NetValue {
        guard depth < NetBinaryDecoder.maxDepth else { throw NetError.malformed("nesting") }
        guard let tag = NetValueTag(rawValue: try r.u8()) else { throw NetError.malformed("value tag") }
        switch tag {
        case .null: return .null
        case .false: return .bool(false)
        case .true: return .bool(true)
        case .int: return .int(zigzagDecode(try r.varint64()))
        case .uint: return .uint(try r.varint64())
        case .f32: return .f32(try r.f32())
        case .f64: return .f64(try r.f64())
        case .string: return .string(try r.string(maxLength: 1 << 20))
        case .array:
            let count = try r.varint(max: r.data.count - r.offset) // every element is at least one byte
            var items: [NetValue] = []
            items.reserveCapacity(count)
            for _ in 0..<count { items.append(try read(&r, depth: depth + 1)) }
            return .array(items)
        case .map:
            let count = try r.varint(max: (r.data.count - r.offset) / 2)
            var items: [String: NetValue] = [:]
            for _ in 0..<count {
                let key = try r.string(maxLength: 1024)
                items[key] = try read(&r, depth: depth + 1)
            }
            return .map(items)
        }
    }

    var kind: String {
        switch self {
        case .null: "nil"
        case .bool: "a bool"
        case .int, .uint: "an integer"
        case .f32, .f64: "a float"
        case .string: "a string"
        case .array: "an array"
        case .map: "a map"
        }
    }
}

@inline(__always) func zigzagEncode(_ v: Int64) -> UInt64 { UInt64(bitPattern: (v << 1) ^ (v >> 63)) }
@inline(__always) func zigzagDecode(_ v: UInt64) -> Int64 { Int64(bitPattern: v >> 1) ^ -Int64(bitPattern: v & 1) }

// MARK: Encoding

/// One value being encoded; containers fill it in place.
final class NetValueBox {
    enum Content {
        case unset, null, bool(Bool), int(Int64), uint(UInt64), f32(Float), f64(Double), string(String)
        case array([NetValueBox])
        case map([String: NetValueBox])
    }
    var content: Content = .unset

    func write(to w: inout ByteWriter) {
        switch content {
        case .unset, .null: w.u8(NetValueTag.null.rawValue)
        case .bool(let b): w.u8(b ? NetValueTag.true.rawValue : NetValueTag.false.rawValue)
        case .int(let v):
            w.u8(NetValueTag.int.rawValue)
            w.varint64(zigzagEncode(v))
        case .uint(let v):
            w.u8(NetValueTag.uint.rawValue)
            w.varint64(v)
        case .f32(let v):
            w.u8(NetValueTag.f32.rawValue)
            w.f32(v)
        case .f64(let v):
            w.u8(NetValueTag.f64.rawValue)
            w.f64(v)
        case .string(let s):
            w.u8(NetValueTag.string.rawValue)
            w.string(s)
        case .array(let items):
            w.u8(NetValueTag.array.rawValue)
            w.varint(items.count)
            for item in items { item.write(to: &w) }
        case .map(let items):
            w.u8(NetValueTag.map.rawValue)
            w.varint(items.count)
            for key in items.keys.sorted() {
                w.string(key)
                items[key]!.write(to: &w)
            }
        }
    }

    /// Primitives directly; anything else through its own `encode(to:)`.
    static func encode<T: Encodable>(_ value: T, into box: NetValueBox, codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any]) throws {
        switch value {
        case let v as Bool: box.content = .bool(v)
        case let v as Float: box.content = .f32(v)
        case let v as Double: box.content = .f64(v)
        case let v as String: box.content = .string(v)
        case let v as Int: box.content = .int(Int64(v))
        case let v as Int8: box.content = .int(Int64(v))
        case let v as Int16: box.content = .int(Int64(v))
        case let v as Int32: box.content = .int(Int64(v))
        case let v as Int64: box.content = .int(v)
        case let v as UInt: box.content = .uint(UInt64(v))
        case let v as UInt8: box.content = .uint(UInt64(v))
        case let v as UInt16: box.content = .uint(UInt64(v))
        case let v as UInt32: box.content = .uint(UInt64(v))
        case let v as UInt64: box.content = .uint(v)
        default: try value.encode(to: NetValueEncoder(box: box, codingPath: codingPath, userInfo: userInfo))
        }
    }
}

private struct NetValueEncoder: Encoder {
    let box: NetValueBox
    var codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        if case .map = box.content {} else { box.content = .map([:]) }
        return KeyedEncodingContainer(KeyedContainer<Key>(box: box, codingPath: codingPath, userInfo: userInfo))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        if case .array = box.content {} else { box.content = .array([]) }
        return UnkeyedContainer(box: box, codingPath: codingPath, userInfo: userInfo)
    }

    func singleValueContainer() -> any SingleValueEncodingContainer { SingleContainer(box: box, codingPath: codingPath, userInfo: userInfo) }

    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let box: NetValueBox
        var codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]

        private func child(_ key: Key) -> NetValueBox {
            let child = NetValueBox()
            if case .map(var items) = box.content {
                box.content = .unset // keep `items` uniquely referenced while it is mutated
                items[key.stringValue] = child
                box.content = .map(items)
            }
            return child
        }
        mutating func encodeNil(forKey key: Key) throws { child(key).content = .null }
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            try NetValueBox.encode(value, into: child(key), codingPath: codingPath + [key], userInfo: userInfo)
        }
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            NetValueEncoder(box: child(key), codingPath: codingPath + [key], userInfo: userInfo).container(keyedBy: keyType)
        }
        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            NetValueEncoder(box: child(key), codingPath: codingPath + [key], userInfo: userInfo).unkeyedContainer()
        }
        mutating func superEncoder() -> any Encoder { NetValueEncoder(box: child(Key(stringValue: "super")!), codingPath: codingPath, userInfo: userInfo) }
        mutating func superEncoder(forKey key: Key) -> any Encoder { NetValueEncoder(box: child(key), codingPath: codingPath + [key], userInfo: userInfo) }
    }

    struct UnkeyedContainer: UnkeyedEncodingContainer {
        let box: NetValueBox
        var codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        var count: Int {
            if case .array(let items) = box.content { return items.count }
            return 0
        }

        private func append() -> NetValueBox {
            let child = NetValueBox()
            if case .array(var items) = box.content {
                box.content = .unset
                items.append(child)
                box.content = .array(items)
            }
            return child
        }
        mutating func encodeNil() throws { append().content = .null }
        mutating func encode<T: Encodable>(_ value: T) throws { try NetValueBox.encode(value, into: append(), codingPath: codingPath, userInfo: userInfo) }
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            NetValueEncoder(box: append(), codingPath: codingPath, userInfo: userInfo).container(keyedBy: keyType)
        }
        mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            NetValueEncoder(box: append(), codingPath: codingPath, userInfo: userInfo).unkeyedContainer()
        }
        mutating func superEncoder() -> any Encoder { NetValueEncoder(box: append(), codingPath: codingPath, userInfo: userInfo) }
    }

    struct SingleContainer: SingleValueEncodingContainer {
        let box: NetValueBox
        var codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        mutating func encodeNil() throws { box.content = .null }
        mutating func encode<T: Encodable>(_ value: T) throws { try NetValueBox.encode(value, into: box, codingPath: codingPath, userInfo: userInfo) }
    }
}

// MARK: Decoding

private struct NetValueDecoder: Decoder {
    let value: NetValue
    var codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    func mismatch(_ expected: String) -> DecodingError {
        .typeMismatch(Any.self, .init(codingPath: codingPath, debugDescription: "expected \(expected), found \(value.kind)"))
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard case .map(let items) = value else { throw mismatch("a map") }
        return KeyedDecodingContainer(KeyedContainer<Key>(items: items, codingPath: codingPath, userInfo: userInfo))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        guard case .array(let items) = value else { throw mismatch("an array") }
        return UnkeyedContainer(items: items, codingPath: codingPath, userInfo: userInfo)
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer { self }

    static func decode<T: Decodable>(_ type: T.Type, from value: NetValue, codingPath: [any CodingKey],
                                     userInfo: [CodingUserInfoKey: Any]) throws -> T {
        let d = NetValueDecoder(value: value, codingPath: codingPath, userInfo: userInfo)
        switch type {
        case is Bool.Type:
            guard case .bool(let b) = value else { throw d.mismatch("a bool") }
            return b as! T
        case is Float.Type:
            switch value {
            case .f32(let v): return v as! T
            case .f64(let v): return Float(v) as! T
            case .int(let v): return Float(v) as! T
            case .uint(let v): return Float(v) as! T
            default: throw d.mismatch("a float")
            }
        case is Double.Type:
            switch value {
            case .f32(let v): return Double(v) as! T
            case .f64(let v): return v as! T
            case .int(let v): return Double(v) as! T
            case .uint(let v): return Double(v) as! T
            default: throw d.mismatch("a float")
            }
        case is String.Type:
            guard case .string(let s) = value else { throw d.mismatch("a string") }
            return s as! T
        case is Int.Type: return try d.integer(Int.self) as! T
        case is Int8.Type: return try d.integer(Int8.self) as! T
        case is Int16.Type: return try d.integer(Int16.self) as! T
        case is Int32.Type: return try d.integer(Int32.self) as! T
        case is Int64.Type: return try d.integer(Int64.self) as! T
        case is UInt.Type: return try d.integer(UInt.self) as! T
        case is UInt8.Type: return try d.integer(UInt8.self) as! T
        case is UInt16.Type: return try d.integer(UInt16.self) as! T
        case is UInt32.Type: return try d.integer(UInt32.self) as! T
        case is UInt64.Type: return try d.integer(UInt64.self) as! T
        default: return try T(from: d)
        }
    }

    func integer<I: FixedWidthInteger>(_ type: I.Type) throws -> I {
        switch value {
        case .int(let v): if let i = I(exactly: v) { return i }
        case .uint(let v): if let i = I(exactly: v) { return i }
        default: throw mismatch("an integer")
        }
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "integer out of range for \(I.self)"))
    }

    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let items: [String: NetValue]
        var codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        var allKeys: [Key] { items.keys.sorted().compactMap { Key(stringValue: $0) } }

        func contains(_ key: Key) -> Bool { items[key.stringValue] != nil }
        private func value(_ key: Key) throws -> NetValue {
            guard let v = items[key.stringValue] else {
                throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "no value for '\(key.stringValue)'"))
            }
            return v
        }
        func decodeNil(forKey key: Key) throws -> Bool {
            if case .null = try value(key) { return true }
            return false
        }
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            try NetValueDecoder.decode(type, from: value(key), codingPath: codingPath + [key], userInfo: userInfo)
        }
        func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            try NetValueDecoder(value: value(key), codingPath: codingPath + [key], userInfo: userInfo).container(keyedBy: type)
        }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            try NetValueDecoder(value: value(key), codingPath: codingPath + [key], userInfo: userInfo).unkeyedContainer()
        }
        func superDecoder() throws -> any Decoder {
            NetValueDecoder(value: items["super"] ?? .null, codingPath: codingPath, userInfo: userInfo)
        }
        func superDecoder(forKey key: Key) throws -> any Decoder {
            NetValueDecoder(value: items[key.stringValue] ?? .null, codingPath: codingPath + [key], userInfo: userInfo)
        }
    }

    struct UnkeyedContainer: UnkeyedDecodingContainer {
        let items: [NetValue]
        var codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        var currentIndex = 0
        var count: Int? { items.count }
        var isAtEnd: Bool { currentIndex >= items.count }

        init(items: [NetValue], codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.items = items
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private mutating func next() throws -> NetValue {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(Any.self, .init(codingPath: codingPath, debugDescription: "unkeyed container is at its end"))
            }
            defer { currentIndex += 1 }
            return items[currentIndex]
        }
        mutating func decodeNil() throws -> Bool {
            guard !isAtEnd else { return false }
            if case .null = items[currentIndex] {
                currentIndex += 1
                return true
            }
            return false
        }
        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
            try NetValueDecoder.decode(type, from: next(), codingPath: codingPath, userInfo: userInfo)
        }
        mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            try NetValueDecoder(value: next(), codingPath: codingPath, userInfo: userInfo).container(keyedBy: type)
        }
        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
            try NetValueDecoder(value: next(), codingPath: codingPath, userInfo: userInfo).unkeyedContainer()
        }
        mutating func superDecoder() throws -> any Decoder { NetValueDecoder(value: try next(), codingPath: codingPath, userInfo: userInfo) }
    }
}

extension NetValueDecoder: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        if case .null = value { return true }
        return false
    }
    func decode<T: Decodable>(_ type: T.Type) throws -> T { try NetValueDecoder.decode(type, from: value, codingPath: codingPath, userInfo: userInfo) }
}
