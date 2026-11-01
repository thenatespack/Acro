import Foundation
import CZlib

// Networking (cards 624, 662): the replicated state of a world and its wire format.
//
// A `NetWorldState` is every replicated entity's components, each already encoded to bytes
// (Transform quantized, or as 10 raw floats; everything else in the compact binary Codable
// format). Comparing bytes is then all the delta encoder needs: a snapshot against a baseline
// the client acknowledged carries only the components whose bytes changed, the entities that
// appeared, and the ids of the ones that went away.

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
    // changed entities (count; reference, component count; components), removed entities
    // (count, index gaps).
    //
    // A reference is 0 followed by the 16-byte id for an entity the baseline doesn't have, or
    // the gap to the entity's index among the baseline's ids in sorted order (both sides have
    // the baseline) from the previous referenced one (index + 1 for the first): sorted entities
    // make that one byte each almost always. A component is a varint name index << 2 | kind
    // (0 removed; 1 bytes; 2 a Transform delta against the baseline's, see
    // `NetComponentCoder.transformDelta`), then for kinds 1 and 2 a length and the bytes.
    // Counts and lengths are LEB128 varints; numbers little-endian. Entities are sorted by id
    // so encoding is deterministic.

    /// The wire bytes. A delta refers to entities by their index in `baseline`, which must be
    /// the state at `baselineTick` (the decoder passes the same one).
    public func encoded(baseline: NetWorldState? = nil) -> [UInt8] {
        var w = ByteWriter()
        w.u32(tick)
        w.u32(baselineTick ?? .max)
        w.f64(serverTime)
        let names = Array(Set(changed.values.flatMap(\.keys))).sorted()
        let nameIndex = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($1, $0) })
        w.varint(names.count)
        for name in names { w.string(name) }
        let base = baselineTick == nil ? nil : baseline
        let baseIndex = Self.indexTable(base)
        w.varint(changed.count)
        var previous = -1
        for id in changed.keys.sorted() {
            let diff = changed[id]!
            if let index = baseIndex[id] {
                w.varint(index - previous)
                previous = index
            } else {
                w.varint(0)
                w.entityID(id)
            }
            w.varint(diff.count)
            for name in diff.keys.sorted() {
                let n = nameIndex[name]! << 2
                guard let bytes = diff[name]! else {
                    w.varint(n)
                    continue
                }
                if name == Transform.componentName, let old = base?[id]?[name],
                   let delta = NetComponentCoder.transformDelta(from: old, to: bytes), delta.count < bytes.count {
                    w.varint(n | 2)
                    w.varint(delta.count)
                    w.bytes(delta)
                } else {
                    w.varint(n | 1)
                    w.varint(bytes.count)
                    w.bytes(bytes)
                }
            }
        }
        // Removed ids come from the baseline, so they always have an index.
        let removedIndices = removed.compactMap { baseIndex[$0] }.sorted()
        w.varint(removedIndices.count)
        previous = -1
        for index in removedIndices {
            w.varint(index - previous - 1)
            previous = index
        }
        return w.data
    }

    /// The tick and baseline tick of an encoded snapshot (to find the baseline before decoding).
    public static func header(of bytes: [UInt8]) throws -> (tick: UInt32, baselineTick: UInt32?) {
        var r = ByteReader(bytes)
        let tick = try r.u32()
        let baseline = try r.u32()
        return (tick, baseline == .max ? nil : baseline)
    }

    /// Decodes a snapshot; a delta needs the state at its `baselineTick` (entities are referred
    /// to by their index in it).
    public init(decoding bytes: [UInt8], baseline: NetWorldState? = nil) throws {
        var r = ByteReader(bytes)
        let tick = try r.u32()
        let baselineRaw = try r.u32()
        let time = try r.f64()
        let baselineTick: UInt32? = baselineRaw == .max ? nil : baselineRaw
        if baselineTick != nil, baseline == nil { throw NetError.malformed("delta without its baseline") }
        let base = baselineTick == nil ? [:] : baseline ?? [:]
        let baseIDs = base.keys.sorted()
        var names: [String] = []
        for _ in 0..<(try r.varint(max: 4096)) { names.append(try r.string()) }
        var changed: [EntityID: [String: [UInt8]?]] = [:]
        var previous = -1
        for _ in 0..<(try r.varint(max: 1 << 20)) {
            let reference = try r.varint(max: baseIDs.count)
            let id: EntityID
            if reference == 0 {
                id = try r.entityID()
            } else {
                previous += reference
                guard previous < baseIDs.count else { throw NetError.malformed("entity reference") }
                id = baseIDs[previous]
            }
            var diff: [String: [UInt8]?] = [:]
            for _ in 0..<(try r.varint(max: 4096)) {
                let header = try r.varint(max: 4096 << 2)
                let index = header >> 2
                guard index < names.count else { throw NetError.malformed("name index") }
                let name = names[index]
                switch header & 3 {
                case 0: diff[name] = .some(nil)
                case 1: diff[name] = try r.bytes(r.varint(max: 1 << 24))
                case 2:
                    guard name == Transform.componentName, let old = base[id]?[name] else { throw NetError.malformed("delta without a base") }
                    diff[name] = try NetComponentCoder.applyTransformDelta(try r.bytes(r.varint(max: 64)), to: old)
                default: throw NetError.malformed("component kind")
                }
            }
            changed[id] = diff
        }
        var removed: [EntityID] = []
        previous = -1
        for _ in 0..<(try r.varint(max: 1 << 20)) {
            previous += try r.varint(max: 1 << 20) + 1
            guard previous < baseIDs.count else { throw NetError.malformed("removed index") }
            removed.append(baseIDs[previous])
        }
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        self.init(tick: tick, baselineTick: baselineTick, serverTime: time, changed: changed, removed: removed)
    }

    private static func indexTable(_ baseline: NetWorldState?) -> [EntityID: Int] {
        guard let baseline else { return [:] }
        var table: [EntityID: Int] = [:]
        table.reserveCapacity(baseline.count)
        for (i, id) in baseline.keys.sorted().enumerated() { table[id] = i }
        return table
    }

    /// About the encoded size of one entity's entry (for byte budgets).
    static func entrySize(_ diff: [String: [UInt8]?], base: [String: [UInt8]]?) -> Int {
        var size = (base != nil ? 1 : 17) + 1
        for (name, bytes) in diff {
            size += 1
            guard let bytes else { continue }
            if name == Transform.componentName, let old = base?[name], let delta = NetComponentCoder.transformDelta(from: old, to: bytes) {
                size += 1 + min(delta.count, bytes.count)
            } else {
                size += bytes.count + (bytes.count < 128 ? 1 : 2)
            }
        }
        return size
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

/// How a replicated entity's `Transform` is sent.
public enum NetTransformEncoding: String, Codable, Sendable {
    /// Position in 1/1024 m steps (zigzag varints), rotation as smallest-three in 32 bits
    /// (within 0.2 degrees), scale omitted when one: 12-14 bytes for an unscaled entity within
    /// 500 m of the origin, and a delta of the changed fields against the client's baseline in
    /// snapshots (2-8 bytes for something moving and turning).
    case quantized
    /// 41 bytes, bit-exact (what client-side prediction reconciles from).
    case exact
}

/// A component with a hand-written network encoding, used by `NetComponentCoder` instead of
/// its Codable conformance (for hot types: `CharacterController` has one). Equal values must
/// give equal bytes.
public protocol NetCustomEncoding {
    func netEncoded() -> [UInt8]
    static func netDecoded(_ bytes: [UInt8]) throws -> Self
}

/// Encodes replicated components to bytes and back. Transform, which changes every tick for
/// anything moving, has its own encoding (quantized or exact, see `NetTransformEncoding`);
/// types conforming to `NetCustomEncoding` theirs; other components use their Codable
/// conformance through `NetBinaryEncoder`. `Entity` handles inside them are sent as `EntityID`s
/// and become the client's handles (see NetEntityMapping.swift); `EntityRef`s are ids already.
public enum NetComponentCoder {
    /// Position quantization step (metres) of `.quantized` Transforms.
    public static let positionStep: Float = 1.0 / 1024
    /// Positions further than this from the origin are sent exact.
    static let quantizedRange: Float = 1_048_576

    public static func encode(_ component: any Component, transform encoding: NetTransformEncoding = .quantized) throws -> [UInt8] {
        try encode(component, transform: encoding, entities: nil)
    }

    /// With `entities`, `Entity` handles are written as their targets' ids.
    static func encode(_ component: any Component, transform encoding: NetTransformEncoding, entities: NetEntityMapping?) throws -> [UInt8] {
        if let transform = component as? Transform { return encodeTransform(transform, encoding) }
        if let custom = component as? any NetCustomEncoding { return custom.netEncoded() }
        var encoder = NetBinaryEncoder()
        if let entities { encoder.userInfo[.netEntities] = entities }
        return try encoder.encode(component)
    }

    @MainActor
    public static func decode(_ bytes: [UInt8], as name: String) throws -> any Component {
        try decode(bytes, as: name, entities: nil)
    }

    /// With `entities`, ids written for `Entity` handles become that world's handles.
    @MainActor
    static func decode(_ bytes: [UInt8], as name: String, entities: NetEntityMapping?) throws -> any Component {
        if name == Transform.componentName { return try decodeTransform(bytes) }
        guard let type = ComponentRegistry.type(named: name) else { throw NetError.unknownComponent(name) }
        if let custom = type as? any NetCustomEncoding.Type, let component = try custom.netDecoded(bytes) as? any Component {
            return component
        }
        return try decode(type, bytes, entities: entities)
    }

    public static func encodeTransform(_ t: Transform, _ encoding: NetTransformEncoding = .quantized) -> [UInt8] {
        QuantizedTransform(t, encoding).bytes
    }

    public static func decodeTransform(_ bytes: [UInt8]) throws -> Transform {
        try QuantizedTransform(bytes: bytes).transform
    }

    /// The changed fields of quantized Transform `new` against `old`: a mask (bits 0-2 position
    /// axes, 3 rotation) then the axis differences as zigzag varints and the new rotation. Nil
    /// when that isn't possible (exact encodings, flags or scale changed).
    static func transformDelta(from old: [UInt8], to new: [UInt8]) -> [UInt8]? {
        guard let a = try? QuantizedTransform(bytes: old), let b = try? QuantizedTransform(bytes: new),
              !a.isExact, !b.isExact, a.flags == b.flags, a.scale == b.scale else { return nil }
        var mask: UInt8 = 0
        for axis in 0..<3 where a.position[axis] != b.position[axis] { mask |= 1 << axis }
        if a.rotation != b.rotation { mask |= 8 }
        var w = ByteWriter()
        w.u8(mask)
        for axis in 0..<3 where mask & (1 << axis) != 0 { w.varint64(zigzagEncode(b.position[axis] &- a.position[axis])) }
        if mask & 8 != 0 { w.u32(b.rotation) }
        return w.data
    }

    /// `old` with a `transformDelta` applied: the new Transform's bytes.
    static func applyTransformDelta(_ delta: [UInt8], to old: [UInt8]) throws -> [UInt8] {
        var q = try QuantizedTransform(bytes: old)
        guard !q.isExact else { throw NetError.malformed("delta of an exact transform") }
        var r = ByteReader(delta)
        let mask = try r.u8()
        guard mask & 0xF0 == 0 else { throw NetError.malformed("transform delta mask") }
        for axis in 0..<3 where mask & (1 << axis) != 0 {
            q.position[axis] = q.position[axis] &+ zigzagDecode(try r.varint64())
        }
        if mask & 8 != 0 {
            guard q.flags & QuantizedTransform.identityRotation == 0 else { throw NetError.malformed("rotation delta") }
            q.rotation = try r.u32()
        }
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        return q.bytes
    }

    @MainActor
    private static func decode<C: Component>(_ type: C.Type, _ bytes: [UInt8], entities: NetEntityMapping?) throws -> any Component {
        var decoder = NetBinaryDecoder()
        if let entities { decoder.userInfo[.netEntities] = entities }
        return try decoder.decode(type, from: bytes)
    }
}

/// A Transform's wire form: flags, then 10 raw floats (exact) or integer position steps, a
/// packed rotation (unless identity) and scale (unless one: one float when uniform).
struct QuantizedTransform: Equatable {
    static let exact: UInt8 = 1
    static let identityRotation: UInt8 = 2
    static let unitScale: UInt8 = 4
    static let uniformScale: UInt8 = 8

    var flags: UInt8
    var position: [Int64] = [0, 0, 0]
    var rotation: UInt32 = 0
    var scale: [Float] = []
    var exactValues: [Float] = []
    var isExact: Bool { flags & Self.exact != 0 }

    init(_ t: Transform, _ encoding: NetTransformEncoding) {
        let p = t.position
        let inRange = [p.x, p.y, p.z].allSatisfy { $0.isFinite && abs($0) < NetComponentCoder.quantizedRange }
            && [t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w].allSatisfy(\.isFinite)
        guard encoding == .quantized, inRange else {
            flags = Self.exact
            exactValues = [p.x, p.y, p.z, t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w, t.scale.x, t.scale.y, t.scale.z]
            return
        }
        flags = 0
        if t.rotation == .identity { flags |= Self.identityRotation } else { rotation = Self.packRotation(t.rotation) }
        if t.scale == .one {
            flags |= Self.unitScale
        } else if t.scale.x == t.scale.y && t.scale.y == t.scale.z {
            flags |= Self.uniformScale
            scale = [t.scale.x]
        } else {
            scale = [t.scale.x, t.scale.y, t.scale.z]
        }
        position = [p.x, p.y, p.z].map { Int64(($0 / NetComponentCoder.positionStep).rounded()) }
    }

    init(bytes: [UInt8]) throws {
        var r = ByteReader(bytes)
        flags = try r.u8()
        guard flags & 0xF0 == 0 else { throw NetError.malformed("transform flags") }
        if isExact {
            for _ in 0..<10 { exactValues.append(try r.f32()) }
        } else {
            for axis in 0..<3 { position[axis] = zigzagDecode(try r.varint64()) }
            if flags & Self.identityRotation == 0 { rotation = try r.u32() }
            if flags & Self.unitScale == 0 {
                scale.append(try r.f32())
                if flags & Self.uniformScale == 0 {
                    scale.append(try r.f32())
                    scale.append(try r.f32())
                }
            }
        }
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
    }

    var bytes: [UInt8] {
        var w = ByteWriter()
        w.u8(flags)
        if isExact {
            for v in exactValues { w.f32(v) }
            return w.data
        }
        for v in position { w.varint64(zigzagEncode(v)) }
        if flags & Self.identityRotation == 0 { w.u32(rotation) }
        for v in scale { w.f32(v) }
        return w.data
    }

    var transform: Transform {
        if isExact {
            let f = exactValues
            return Transform(position: Vec3(f[0], f[1], f[2]), rotation: Quat(f[3], f[4], f[5], f[6]), scale: Vec3(f[7], f[8], f[9]))
        }
        let s: Vec3 = scale.isEmpty ? .one : scale.count == 1 ? Vec3(repeating: scale[0]) : Vec3(scale[0], scale[1], scale[2])
        return Transform(position: Vec3(Float(position[0]), Float(position[1]), Float(position[2])) * NetComponentCoder.positionStep,
                         rotation: flags & Self.identityRotation != 0 ? .identity : Self.unpackRotation(rotation), scale: s)
    }

    /// Smallest three: the index of the largest component (2 bits), the other three in 10 bits
    /// each over [-1/sqrt(2), 1/sqrt(2)], the sign chosen so the dropped one is positive.
    static func packRotation(_ q: Quat) -> UInt32 {
        var v = q.vector
        let l = (v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w).squareRoot()
        if l > 0 { v /= l }
        var largest = 0
        for i in 1..<4 where abs(v[i]) > abs(v[largest]) { largest = i }
        if v[largest] < 0 { v = -v }
        var packed = UInt32(largest) << 30
        var shift: UInt32 = 20
        for i in 0..<4 where i != largest {
            let unit = min(max(v[i] * Float(2).squareRoot() * 0.5 + 0.5, 0), 1)
            packed |= UInt32((unit * 1023).rounded()) << shift
            shift &-= 10
        }
        return packed
    }

    static func unpackRotation(_ packed: UInt32) -> Quat {
        let largest = Int(packed >> 30)
        var v = Vec4.zero
        var shift: UInt32 = 20
        var sum: Float = 0
        for i in 0..<4 where i != largest {
            let unit = Float((packed >> shift) & 1023) / 1023
            v[i] = (unit - 0.5) * 2 / Float(2).squareRoot()
            sum += v[i] * v[i]
            shift &-= 10
        }
        v[largest] = max(0, 1 - sum).squareRoot()
        return Quat(vector: v)
    }
}

extension CharacterController: NetCustomEncoding {
    /// Every coded field in a fixed order: floats raw (prediction reconciles from them, so they
    /// must be exact), the mask and iteration count as varints, the four flags in one byte:
    /// 93-97 bytes instead of ~330 through the generic binary coder.
    public func netEncoded() -> [UInt8] {
        var w = ByteWriter()
        for v in [radius, height, skinWidth, maxSlopeAngle, stepHeight, gravityScale, jumpSpeed, pushForce] { w.f32(v) }
        w.varint64(UInt64(collisionMask))
        w.varint64(zigzagEncode(Int64(maxIterations)))
        for v in [moveVelocity, groundNormal, groundVelocity, launchVelocity] {
            w.f32(v.x)
            w.f32(v.y)
            w.f32(v.z)
        }
        w.f32(verticalVelocity)
        w.u8((jump ? 1 : 0) | (isGrounded ? 2 : 0) | (isSliding ? 4 : 0))
        return w.data
    }

    public static func netDecoded(_ bytes: [UInt8]) throws -> CharacterController {
        var r = ByteReader(bytes)
        var c = CharacterController()
        var f: [Float] = []
        for _ in 0..<8 { f.append(try r.f32()) }
        (c.radius, c.height, c.skinWidth, c.maxSlopeAngle, c.stepHeight, c.gravityScale, c.jumpSpeed, c.pushForce) =
            (f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7])
        let mask = try r.varint64()
        guard mask <= UInt64(UInt32.max) else { throw NetError.malformed("collision mask") }
        c.collisionMask = UInt32(mask)
        let iterations = zigzagDecode(try r.varint64())
        guard abs(iterations) < 1 << 20 else { throw NetError.malformed("iterations") }
        c.maxIterations = Int(iterations)
        var vectors: [Vec3] = []
        for _ in 0..<4 { vectors.append(Vec3(try r.f32(), try r.f32(), try r.f32())) }
        (c.moveVelocity, c.groundNormal, c.groundVelocity, c.launchVelocity) = (vectors[0], vectors[1], vectors[2], vectors[3])
        c.verticalVelocity = try r.f32()
        let flags = try r.u8()
        guard flags < 8, r.isAtEnd else { throw NetError.malformed("character flags") }
        c.jump = flags & 1 != 0
        c.isGrounded = flags & 2 != 0
        c.isSliding = flags & 4 != 0
        return c
    }
}


// MARK: Compression

/// zlib for snapshot payloads: the uncompressed length (varint), then a zlib stream.
enum NetCompression {
    /// The largest payload `inflate` accepts (a defence against decompression bombs).
    static let maxInflatedSize = 1 << 22

    static func deflate(_ bytes: [UInt8], level: Int32 = 6) -> [UInt8] {
        var bound = compressBound(uLong(bytes.count))
        var out = [UInt8](repeating: 0, count: Int(bound))
        let status = out.withUnsafeMutableBufferPointer { o in
            bytes.withUnsafeBufferPointer { i in compress2(o.baseAddress, &bound, i.baseAddress, uLong(bytes.count), level) }
        }
        precondition(status == Z_OK, "compress2 failed (\(status))")
        var w = ByteWriter()
        w.varint(bytes.count)
        w.bytes(Array(out[0..<Int(bound)]))
        return w.data
    }

    static func inflate(_ bytes: [UInt8]) throws -> [UInt8] {
        var r = ByteReader(bytes)
        let size = try r.varint(max: maxInflatedSize)
        let stream = Array(bytes[r.offset...])
        var out = [UInt8](repeating: 0, count: max(size, 1))
        var length = uLong(size)
        let status = out.withUnsafeMutableBufferPointer { o in
            stream.withUnsafeBufferPointer { i in uncompress(o.baseAddress, &length, i.baseAddress, uLong(stream.count)) }
        }
        guard status == Z_OK, Int(length) == size else { throw NetError.malformed("compressed payload") }
        return Array(out[0..<size])
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
    mutating func varint(_ v: Int) { varint64(UInt64(v)) }
    mutating func varint64(_ v: UInt64) {
        var v = v
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
    var remaining: Int { data.count - offset }

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
    mutating func rest() -> [UInt8] {
        defer { offset = data.count }
        return Array(data[offset...])
    }
    mutating func varint64() throws -> UInt64 {
        var v: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            let b = try u8()
            guard shift < 64, shift < 63 || b <= 1 else { throw NetError.malformed("varint") }
            v |= UInt64(b & 0x7F) << shift
            if b < 0x80 { break }
            shift += 7
        }
        return v
    }
    mutating func varint(max: Int) throws -> Int {
        let v = try varint64()
        guard v <= UInt64(Swift.max(max, 0)) else { throw NetError.malformed("count \(v) over \(max)") }
        return Int(v)
    }
    mutating func string(maxLength: Int = 1024) throws -> String {
        let bytes = try bytes(varint(max: maxLength))
        return String(decoding: bytes, as: UTF8.self)
    }
    mutating func entityID() throws -> EntityID {
        EntityID(high: try u64(), low: try u64())
    }
}
