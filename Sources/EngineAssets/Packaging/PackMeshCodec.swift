#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

// Compressed meshes in asset packs (blob encoding "mesh1", AssetPack.swift). A mesh file in the
// Library is raw memory: 64-byte `MeshVertex`es, UInt32 indices, then any skin and paint, about
// 76 bytes per vertex. In a pack it is quantized and delta coded, then deflated:
//
// - positions on a power-of-two grid: 16 bits across the mesh's largest extent, never coarser
//   than 2^-10 (about 1 mm in metres). The grid is absolute (x rounds to the nearest multiple of
//   the step, not relative to the bounds), so meshes of similar size that share an edge round
//   it the same way and don't open cracks;
// - normals and tangent directions octahedral, 12 bits per component (under 0.05° of error);
//   tangent w (handedness and baked AO, MeshVertex) as a 16-bit signed fraction, 0 kept as 0
//   (no tangents: `hasTangents`), any other value at least 1/32767 so its sign survives;
// - UVs on a power-of-two grid: 16 bits across their extent, never coarser than 2^-14 (a quarter
//   texel at 4096 texels per unit);
// - indices, skin joints and weights (16-bit unorm) as they are; paint floats bit for bit.
//
// Each value becomes a stream of integers: delta coded against the previous vertex (or index),
// zigzagged, and stored as byte planes (all low bytes, then all next bytes...), which deflate
// compresses well; on Racing's meshes 90 MB become 9 MB. Decoding (`decode`) rebuilds exactly the
// Library's raw file layout, so `AssetArtifacts.decode` reads it unchanged.
//
// The encoder refuses meshes it can't quantize within these bounds (non-finite values, normals
// that aren't unit length, out-of-range weights): those are stored deflated, losslessly.
//
// The blob in the pack is the payload's size (UInt32) and the payload deflated (zlib). Payload,
// little-endian:
//
// ```
// 0   "AQM1"
// 4   UInt32 vertexCount, UInt32 indexCount
// 12  UInt8 flags (1 skinned, 2 painted, 4 has tangents), UInt8 direction bits (12)
// 14  Int8 position exponent, Int8 u exponent, Int8 v exponent, UInt8 0
// 18  streams: per stream a UInt8 (bits 0-2 the byte width 0-4, bit 3 delta coded), then
//     width × count bytes: px py pz nu nv u v [tu tv tw] index [joints ×4, weights ×4] [paint ×8]
// ```
package enum PackMeshCodec {
    static let magic: [UInt8] = Array("AQM1".utf8)
    static let directionBits = 12
    static let positionBits = 16
    static let coarsestPositionExponent = -10
    static let uvBits = 16
    static let coarsestUVExponent = -14

    /// The mesh file's bytes (the Library's raw layout) compressed, or nil when it can't be
    /// quantized within the bounds above (the caller stores it losslessly instead).
    package static func encode(_ raw: Data, vertexCount n: Int, indexCount: Int, skinned: Bool, painted: Bool) -> [UInt8]? {
        let stride = MemoryLayout<MeshVertex>.stride
        let vertexBytes = n * stride, indexEnd = vertexBytes + indexCount * 4
        let skinBytes = skinned ? n * AssetArtifacts.influenceBytes : 0
        let paintBytes = painted ? n * MemoryLayout<VertexPaint>.stride : 0
        guard n > 0, n <= Int(Int32.max), indexCount <= Int(Int32.max), raw.count == indexEnd + skinBytes + paintBytes else { return nil }
        return raw.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8]? in
            let vertices = bytes.bindMemory(to: MeshVertex.self).prefix(n)
            // Bounds.
            var low = Vec3(repeating: .infinity), high = Vec3(repeating: -.infinity)
            var uvLow = Vec2(repeating: .infinity), uvHigh = Vec2(repeating: -.infinity)
            var tangents = false
            for v in vertices {
                guard v.position.x.isFinite, v.position.y.isFinite, v.position.z.isFinite, v.uv.x.isFinite, v.uv.y.isFinite else { return nil }
                low = pointwiseMin(low, v.position); high = pointwiseMax(high, v.position)
                uvLow = pointwiseMin(uvLow, v.uv); uvHigh = pointwiseMax(uvHigh, v.uv)
                if v.tangent.w != 0 { tangents = true }
            }
            let extent = (0..<3).map { Double(high[$0]) - Double(low[$0]) }.max()!
            let positionExponent = gridExponent(extent: extent, magnitude: Double(max((-low).max(), high.max())),
                                                bits: positionBits, coarsest: coarsestPositionExponent)
            let uExponent = gridExponent(extent: Double(uvHigh.x) - Double(uvLow.x), magnitude: Double(max(abs(uvLow.x), abs(uvHigh.x))),
                                         bits: uvBits, coarsest: coarsestUVExponent)
            let vExponent = gridExponent(extent: Double(uvHigh.y) - Double(uvLow.y), magnitude: Double(max(abs(uvLow.y), abs(uvHigh.y))),
                                         bits: uvBits, coarsest: coarsestUVExponent)
            let positionScale = Double(sign: .plus, exponent: -positionExponent, significand: 1)
            let uScale = Double(sign: .plus, exponent: -uExponent, significand: 1)
            let vScale = Double(sign: .plus, exponent: -vExponent, significand: 1)

            var streams = [[Int32]](repeating: [Int32](repeating: 0, count: n), count: tangents ? 10 : 7)
            for (i, v) in vertices.enumerated() {
                streams[0][i] = Int32((Double(v.position.x) * positionScale).rounded())
                streams[1][i] = Int32((Double(v.position.y) * positionScale).rounded())
                streams[2][i] = Int32((Double(v.position.z) * positionScale).rounded())
                guard let normal = octahedral(v.normal) else { return nil }
                streams[3][i] = normal.0; streams[4][i] = normal.1
                streams[5][i] = Int32((Double(v.uv.x) * uScale).rounded())
                streams[6][i] = Int32((Double(v.uv.y) * vScale).rounded())
                if tangents {
                    let w = v.tangent.w
                    guard w.isFinite, abs(w) <= 1.0001 else { return nil }
                    if w == 0 { continue }  // decodes to an all-zero tangent
                    guard let t = octahedral(Vec3(v.tangent.x, v.tangent.y, v.tangent.z)) else { return nil }
                    streams[7][i] = t.0; streams[8][i] = t.1
                    let q = Int32((min(max(w, -1), 1) * 32767).rounded())
                    streams[9][i] = q != 0 ? q : (w < 0 ? -1 : 1)
                }
            }
            var out = magic
            append(UInt32(n), to: &out)
            append(UInt32(indexCount), to: &out)
            out.append((skinned ? 1 : 0) | (painted ? 2 : 0) | (tangents ? 4 : 0))
            out.append(UInt8(directionBits))
            out.append(UInt8(bitPattern: Int8(positionExponent)))
            out.append(UInt8(bitPattern: Int8(uExponent)))
            out.append(UInt8(bitPattern: Int8(vExponent)))
            out.append(0)
            for stream in streams { appendStream(stream, delta: true, to: &out) }
            appendStream((0..<indexCount).map { Int32(bitPattern: bytes.loadUnaligned(fromByteOffset: vertexBytes + $0 * 4, as: UInt32.self)) },
                         delta: true, to: &out)
            if skinned {
                var joints = [[Int32]](repeating: [Int32](repeating: 0, count: n), count: 4)
                var weights = joints
                for i in 0..<n {
                    let base = indexEnd + i * AssetArtifacts.influenceBytes
                    for c in 0..<4 {
                        joints[c][i] = Int32(bytes.loadUnaligned(fromByteOffset: base + c * 2, as: UInt16.self))
                        let w = bytes.loadUnaligned(fromByteOffset: base + 8 + c * 4, as: Float.self)
                        guard w.isFinite, w >= 0, w <= 1.0001 else { return nil }
                        weights[c][i] = Int32((min(w, 1) * 65535).rounded())
                    }
                }
                for stream in joints + weights { appendStream(stream, delta: true, to: &out) }
            }
            if painted {
                let base = indexEnd + skinBytes, floats = MemoryLayout<VertexPaint>.stride / 4
                for c in 0..<floats {
                    appendStream((0..<n).map { Int32(bitPattern: bytes.loadUnaligned(fromByteOffset: base + ($0 * floats + c) * 4, as: UInt32.self)) },
                                 delta: false, to: &out)
                }
            }
            return out
        }
    }

    /// The raw mesh file (the Library's layout, `size` bytes) from `encode`'s payload, nil when
    /// it is damaged or decodes to another size.
    package static func decode(_ payload: [UInt8], size: Int) -> [UInt8]? {
        payload.withUnsafeBytes { input -> [UInt8]? in
            guard input.count >= 18, Array(input.prefix(4)) == magic else { return nil }
            let vertexCount = input.loadUnaligned(fromByteOffset: 4, as: UInt32.self).littleEndian
            let indexCount = input.loadUnaligned(fromByteOffset: 8, as: UInt32.self).littleEndian
            let flags = input[12], bits = Int(input[13])
            let skinned = flags & 1 != 0, painted = flags & 2 != 0, tangents = flags & 4 != 0
            let positionExponent = Int(Int8(bitPattern: input[14]))
            let uExponent = Int(Int8(bitPattern: input[15])), vExponent = Int(Int8(bitPattern: input[16]))
            // The sizes in 64 bits first: on wasm32 `Int` would overflow before the comparison.
            let stride = MemoryLayout<MeshVertex>.stride
            let perVertex = UInt64(stride + (skinned ? AssetArtifacts.influenceBytes : 0) + (painted ? MemoryLayout<VertexPaint>.stride : 0))
            guard vertexCount > 0, bits >= 2, bits <= 16,
                  UInt64(vertexCount) * perVertex + UInt64(indexCount) * 4 == UInt64(size) else { return nil }
            let n = Int(vertexCount), indices = Int(indexCount)
            let vertexBytes = n * stride, indexEnd = vertexBytes + indices * 4
            let skinBytes = skinned ? n * AssetArtifacts.influenceBytes : 0
            let paintBytes = painted ? n * MemoryLayout<VertexPaint>.stride : 0
            var reader = StreamReader(input: input, offset: 18)

            var out = [UInt8](repeating: 0, count: indexEnd + skinBytes + paintBytes)
            let ok = out.withUnsafeMutableBytes { output -> Bool in
                var scratch = [Int32](repeating: 0, count: max(n, indices))
                let vertices = output.baseAddress!.bindMemory(to: MeshVertex.self, capacity: n)
                // One stream into `scratch`, then each value through `store`.
                func stream(_ count: Int, _ store: (Int, Int32) -> Void) -> Bool {
                    guard scratch.withUnsafeMutableBufferPointer({ reader.read(count: count, into: $0.baseAddress!) }) else { return false }
                    scratch.withUnsafeBufferPointer { values in for i in 0..<count { store(i, values[i]) } }
                    return true
                }
                // In Double, so values beyond 2^24 steps still round once.
                let positionStep = Double(sign: .plus, exponent: positionExponent, significand: 1)
                let uStep = Double(sign: .plus, exponent: uExponent, significand: 1)
                let vStep = Double(sign: .plus, exponent: vExponent, significand: 1)
                let scale = Float((1 << (bits - 1)) - 1)
                var octU = [Int32](repeating: 0, count: n)
                guard stream(n, { vertices[$0].position.x = Float(Double($1) * positionStep) }),
                      stream(n, { vertices[$0].position.y = Float(Double($1) * positionStep) }),
                      stream(n, { vertices[$0].position.z = Float(Double($1) * positionStep) }),
                      stream(n, { octU[$0] = $1 }),
                      stream(n, { vertices[$0].normal = direction(octU[$0], $1, scale) }),
                      stream(n, { vertices[$0].uv.x = Float(Double($1) * uStep) }),
                      stream(n, { vertices[$0].uv.y = Float(Double($1) * vStep) }) else { return false }
                if tangents {
                    var octV = [Int32](repeating: 0, count: n)
                    guard stream(n, { octU[$0] = $1 }), stream(n, { octV[$0] = $1 }),
                          stream(n, { i, w in
                              guard w != 0 else { vertices[i].tangent = .zero; return }
                              let t = direction(octU[i], octV[i], scale)
                              vertices[i].tangent = Vec4(t.x, t.y, t.z, max(Float(w) / 32767, -1))
                          }) else { return false }
                }
                let raw = output.baseAddress!
                guard stream(indices, { raw.storeBytes(of: UInt32(bitPattern: $1).littleEndian, toByteOffset: vertexBytes + $0 * 4, as: UInt32.self) })
                else { return false }
                if skinned {
                    for c in 0..<4 {
                        guard stream(n, { raw.storeBytes(of: UInt16(truncatingIfNeeded: $1), toByteOffset: indexEnd + $0 * AssetArtifacts.influenceBytes + c * 2, as: UInt16.self) })
                        else { return false }
                    }
                    for c in 0..<4 {
                        guard stream(n, { raw.storeBytes(of: Float($1) / 65535, toByteOffset: indexEnd + $0 * AssetArtifacts.influenceBytes + 8 + c * 4, as: Float.self) })
                        else { return false }
                    }
                }
                if painted {
                    let base = indexEnd + skinBytes, floats = MemoryLayout<VertexPaint>.stride / 4
                    for c in 0..<floats {
                        guard stream(n, { raw.storeBytes(of: UInt32(bitPattern: $1), toByteOffset: base + ($0 * floats + c) * 4, as: UInt32.self) })
                        else { return false }
                    }
                }
                return reader.offset == input.count
            }
            return ok ? out : nil
        }
    }

    // MARK: Quantization

    /// The exponent of the power-of-two step for values spanning `extent` (largest `magnitude`):
    /// `bits` across the extent, no coarser than 2^coarsest, fine enough to stay within Int32.
    static func gridExponent(extent: Double, magnitude: Double, bits: Int, coarsest: Int) -> Int {
        var e = coarsest
        if extent > 0 { e = min(e, Int((log2(extent / Double((1 << bits) - 1))).rounded(.up))) } else { e = min(e, -24) }
        if magnitude > 0 { e = max(e, Int((log2(magnitude / Double(1 << 30))).rounded(.up))) }
        return min(max(e, -100), 100)
    }

    /// `v` as octahedral coordinates of `directionBits`, nil unless it is (nearly) unit length.
    static func octahedral(_ v: Vec3) -> (Int32, Int32)? {
        let length = length(v)
        guard length.isFinite, length > 0.95, length < 1.05 else { return nil }
        let l1 = abs(v.x) + abs(v.y) + abs(v.z)
        var u = v.x / l1, w = v.y / l1
        if v.z < 0 {
            let fu = (1 - abs(w)) * (u >= 0 ? 1 : -1), fw = (1 - abs(u)) * (w >= 0 ? 1 : -1)
            u = fu; w = fw
        }
        let scale = Float((1 << (directionBits - 1)) - 1)
        return (Int32((u * scale).rounded()), Int32((w * scale).rounded()))
    }

    /// The unit vector of octahedral coordinates (`scale` = 2^(bits-1) - 1).
    @inline(__always) static func direction(_ qu: Int32, _ qv: Int32, _ scale: Float) -> Vec3 {
        let u = max(min(Float(qu) / scale, 1), -1), v = max(min(Float(qv) / scale, 1), -1)
        var d = Vec3(u, v, 1 - abs(u) - abs(v))
        if d.z < 0 {
            let x = (1 - abs(v)) * (u >= 0 ? 1 : -1), y = (1 - abs(u)) * (v >= 0 ? 1 : -1)
            d.x = x; d.y = y
        }
        return normalize(d)
    }

    // MARK: Streams

    static func append(_ value: UInt32, to out: inout [UInt8]) {
        withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
    }

    /// `values` delta coded (or not), zigzagged, as byte planes after a header byte.
    static func appendStream(_ values: [Int32], delta: Bool, to out: inout [UInt8]) {
        var coded = [UInt32](repeating: 0, count: values.count)
        var previous: Int32 = 0, largest: UInt32 = 0
        for (i, value) in values.enumerated() {
            let d = delta ? value &- previous : value
            previous = value
            let z = UInt32(bitPattern: (d << 1) ^ (d >> 31))
            coded[i] = z
            largest |= z
        }
        let width = largest == 0 ? 0 : largest < 1 << 8 ? 1 : largest < 1 << 16 ? 2 : largest < 1 << 24 ? 3 : 4
        out.append(UInt8(width) | (delta ? 8 : 0))
        for plane in 0..<width {
            let shift = UInt32(plane * 8)
            out.append(contentsOf: coded.lazy.map { UInt8(truncatingIfNeeded: $0 >> shift) })
        }
    }

    /// Reads `appendStream`'s streams.
    struct StreamReader {
        let input: UnsafeRawBufferPointer
        var offset: Int

        init(input: UnsafeRawBufferPointer, offset: Int) {
            self.input = input
            self.offset = offset
        }

        /// The next stream's `count` values into `values`; false when the payload is too short.
        mutating func read(count: Int, into values: UnsafeMutablePointer<Int32>) -> Bool {
            guard offset < input.count else { return false }
            let header = input[offset]
            let width = Int(header & 7), delta = header & 8 != 0
            guard width <= 4, header >> 4 == 0, count <= (input.count - offset - 1) / max(width, 1) else { return false }
            offset += 1
            let base = input.baseAddress!.assumingMemoryBound(to: UInt8.self) + offset
            for i in 0..<count { values[i] = 0 }
            if width > 0 {
                let raw = UnsafeMutableRawPointer(values).assumingMemoryBound(to: UInt32.self)
                for plane in 0..<width {
                    let bytes = base + plane * count, shift = UInt32(plane * 8)
                    for i in 0..<count { raw[i] |= UInt32(bytes[i]) << shift }
                }
                offset += width * count
            }
            var previous: Int32 = 0
            for i in 0..<count {
                let z = UInt32(bitPattern: values[i])
                let d = Int32(bitPattern: (z >> 1) ^ (0 &- (z & 1)))
                if delta { previous = previous &+ d; values[i] = previous } else { values[i] = d }
            }
            return true
        }
    }
}
