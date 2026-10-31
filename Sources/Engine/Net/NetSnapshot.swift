import Foundation

// Networking prototype (card 624): the replicated state of a world and its wire format.
//
// A `NetWorldState` is every replicated entity's components, each already encoded to bytes
// (Transform as 10 raw floats, everything else as sorted-key JSON from its Codable
// conformance). Comparing bytes is then all the delta encoder needs: a snapshot against a
// baseline the client acknowledged carries only the components whose bytes changed, the
// entities that appeared, and the ids of the ones that went away.

/// Replicated entities by id, each with its replicated components' encoded bytes by
/// `componentName`.
public typealias NetWorldState = [EntityID: [String: [UInt8]]]

/// One server snapshot: a full state, or a delta against `baselineTick`.
public struct NetSnapshot: Equatable, Sendable {
    public var tick: UInt32
    /// The tick of the state this is a delta against; nil for a full snapshot.
    public var baselineTick: UInt32?
    /// The server's simulation time when the snapshot was taken (seconds).
    public var serverTime: Double
    /// Entities that are new or changed, with only their changed components (all of them for
    /// new entities). A component name mapped to nil was removed.
    public var changed: [EntityID: [String: [UInt8]?]]
    public var removed: [EntityID]

    /// The delta that turns `baseline` (nil: an empty world) into `state`.
    public init(tick: UInt32, serverTime: Double, state: NetWorldState, baseline: NetWorldState?, baselineTick: UInt32?) {
        self.tick = tick
        self.serverTime = serverTime
        self.baselineTick = baseline == nil ? nil : baselineTick
        changed = [:]
        removed = []
        let base = baseline ?? [:]
        for (id, components) in state {
            let old = base[id]
            var diff: [String: [UInt8]?] = [:]
            for (name, bytes) in components where old?[name] != bytes {
                diff[name] = bytes
            }
            if let old {
                for name in old.keys where components[name] == nil { diff[name] = .some(nil) }
            }
            if !diff.isEmpty || old == nil { changed[id] = diff }
        }
        removed = base.keys.filter { state[$0] == nil }.sorted()
    }

    init(tick: UInt32, baselineTick: UInt32?, serverTime: Double, changed: [EntityID: [String: [UInt8]?]], removed: [EntityID]) {
        self.tick = tick
        self.baselineTick = baselineTick
        self.serverTime = serverTime
        self.changed = changed
        self.removed = removed
    }

    /// `baseline` with this delta applied: the full state at `tick`.
    public func applied(to baseline: NetWorldState?) -> NetWorldState {
        var state = baseline ?? [:]
        for id in removed { state[id] = nil }
        for (id, diff) in changed {
            var components = state[id] ?? [:]
            for (name, bytes) in diff { components[name] = bytes }
            state[id] = components
        }
        return state
    }

    // MARK: Wire format
    //
    // tick u32, baseline u32 (0xFFFFFFFF: none), serverTime f64, name table (count, strings),
    // changed entities (count; id 16 bytes, component count; name index, flag 0 removed / 1
    // bytes, length, bytes), removed ids (count, 16 bytes each). Counts and lengths are
    // LEB128 varints; numbers little-endian. Entities are sorted by id so encoding is
    // deterministic.

    public func encoded() -> [UInt8] {
        var w = ByteWriter()
        w.u32(tick)
        w.u32(baselineTick ?? .max)
        w.f64(serverTime)
        let names = Array(Set(changed.values.flatMap(\.keys))).sorted()
        let nameIndex = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($1, $0) })
        w.varint(names.count)
        for name in names { w.string(name) }
        w.varint(changed.count)
        for id in changed.keys.sorted() {
            let diff = changed[id]!
            w.entityID(id)
            w.varint(diff.count)
            for name in diff.keys.sorted() {
                w.varint(nameIndex[name]!)
                if let bytes = diff[name]! {
                    w.u8(1)
                    w.varint(bytes.count)
                    w.bytes(bytes)
                } else {
                    w.u8(0)
                }
            }
        }
        w.varint(removed.count)
        for id in removed { w.entityID(id) }
        return w.data
    }

    public init(decoding bytes: [UInt8]) throws {
        var r = ByteReader(bytes)
        let tick = try r.u32()
        let baseline = try r.u32()
        let time = try r.f64()
        var names: [String] = []
        for _ in 0..<(try r.varint(max: 4096)) { names.append(try r.string()) }
        var changed: [EntityID: [String: [UInt8]?]] = [:]
        for _ in 0..<(try r.varint(max: 1 << 20)) {
            let id = try r.entityID()
            var diff: [String: [UInt8]?] = [:]
            for _ in 0..<(try r.varint(max: 4096)) {
                let index = try r.varint(max: 4096)
                guard index < names.count else { throw NetError.malformed("name index") }
                switch try r.u8() {
                case 0: diff[names[index]] = .some(nil)
                case 1: diff[names[index]] = try r.bytes(r.varint(max: 1 << 24))
                default: throw NetError.malformed("component flag")
                }
            }
            changed[id] = diff
        }
        var removed: [EntityID] = []
        for _ in 0..<(try r.varint(max: 1 << 20)) { removed.append(try r.entityID()) }
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        self.init(tick: tick, baselineTick: baseline == .max ? nil : baseline, serverTime: time, changed: changed, removed: removed)
    }
}

public enum NetError: Error, Equatable, CustomStringConvertible {
    case malformed(String)
    case unknownComponent(String)

    public var description: String {
        switch self {
        case .malformed(let what): "malformed packet (\(what))"
        case .unknownComponent(let name): "unknown component '\(name)'"
        }
    }
}

// MARK: Component encoding

/// Encodes replicated components to bytes and back. Transform, which changes every tick for
/// anything moving, is 40 raw bytes; other components use their Codable conformance as
/// JSON with sorted keys (stable bytes for the delta comparison). Components holding `Entity`
/// handles don't replicate meaningfully (handles are per world): refer to `EntityID`s.
@MainActor
public enum NetComponentCoder {
    public static func encode(_ component: any Component) throws -> [UInt8] {
        if let transform = component as? Transform {
            var w = ByteWriter()
            for v in [transform.position.x, transform.position.y, transform.position.z,
                      transform.rotation.vector.x, transform.rotation.vector.y, transform.rotation.vector.z, transform.rotation.vector.w,
                      transform.scale.x, transform.scale.y, transform.scale.z] {
                w.f32(v)
            }
            return w.data
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return Array(try encoder.encode(component))
    }

    public static func decode(_ bytes: [UInt8], as name: String) throws -> any Component {
        if name == Transform.componentName { return try decodeTransform(bytes) }
        guard let type = ComponentRegistry.type(named: name) else { throw NetError.unknownComponent(name) }
        return try decode(type, bytes)
    }

    public static func decodeTransform(_ bytes: [UInt8]) throws -> Transform {
        var r = ByteReader(bytes)
        var f: [Float] = []
        for _ in 0..<10 { f.append(try r.f32()) }
        return Transform(position: Vec3(f[0], f[1], f[2]), rotation: Quat(f[3], f[4], f[5], f[6]), scale: Vec3(f[7], f[8], f[9]))
    }

    private static func decode<C: Component>(_ type: C.Type, _ bytes: [UInt8]) throws -> any Component {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return try decoder.decode(type, from: Data(bytes))
    }
}

// MARK: Bytes

struct ByteWriter {
    var data: [UInt8] = []
    mutating func u8(_ v: UInt8) { data.append(v) }
    mutating func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    mutating func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    mutating func u64(_ v: UInt64) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    mutating func f32(_ v: Float) { u32(v.bitPattern) }
    mutating func f64(_ v: Double) { u64(v.bitPattern) }
    mutating func bytes(_ b: [UInt8]) { data.append(contentsOf: b) }
    mutating func varint(_ v: Int) {
        var v = UInt64(v)
        while v >= 0x80 {
            data.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        data.append(UInt8(v))
    }
    mutating func string(_ s: String) {
        varint(s.utf8.count)
        data.append(contentsOf: s.utf8)
    }
    mutating func entityID(_ id: EntityID) {
        u64(id.high)
        u64(id.low)
    }
}

/// Reads what `ByteWriter` wrote; every read is bounds-checked and throws on short or
/// oversized input (packets come from the network: never trust lengths).
struct ByteReader {
    let data: [UInt8]
    var offset = 0
    init(_ data: [UInt8]) { self.data = data }
    var isAtEnd: Bool { offset == data.count }

    mutating func u8() throws -> UInt8 {
        guard offset < data.count else { throw NetError.malformed("truncated") }
        defer { offset += 1 }
        return data[offset]
    }
    private mutating func little<T: FixedWidthInteger>(_: T.Type) throws -> T {
        let size = MemoryLayout<T>.size
        guard data.count - offset >= size else { throw NetError.malformed("truncated") }
        var v: T = 0
        for i in 0..<size { v |= T(data[offset + i]) << (8 * i) }
        offset += size
        return v
    }
    mutating func u16() throws -> UInt16 { try little(UInt16.self) }
    mutating func u32() throws -> UInt32 { try little(UInt32.self) }
    mutating func u64() throws -> UInt64 { try little(UInt64.self) }
    mutating func f32() throws -> Float { Float(bitPattern: try u32()) }
    mutating func f64() throws -> Double { Double(bitPattern: try u64()) }
    mutating func bytes(_ count: Int) throws -> [UInt8] {
        guard count >= 0, data.count - offset >= count else { throw NetError.malformed("truncated") }
        defer { offset += count }
        return Array(data[offset..<offset + count])
    }
    mutating func varint(max: Int) throws -> Int {
        var v: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            let b = try u8()
            guard shift < 63 else { throw NetError.malformed("varint") }
            v |= UInt64(b & 0x7F) << shift
            if b < 0x80 { break }
            shift += 7
        }
        guard v <= UInt64(Swift.max(max, 0)) else { throw NetError.malformed("count \(v) over \(max)") }
        return Int(v)
    }
    mutating func string() throws -> String {
        let bytes = try bytes(varint(max: 1024))
        return String(decoding: bytes, as: UTF8.self)
    }
    mutating func entityID() throws -> EntityID {
        EntityID(high: try u64(), low: try u64())
    }
}
