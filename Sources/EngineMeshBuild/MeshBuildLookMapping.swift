#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// How a look's textures land on a part: texture coordinates in tiles of `lookScale` meters,
// computed from the mesh's positions so the grain has the same size on parts of any size.
//
// - Round shapes (sphere, dome, cylinder, cone, capsule, torus, tube, lathe) are wrapped around
//   their Y axis: around the part in a whole number of tiles (no seam), along Y in meters; faces
//   looking mostly up or down (caps, poles, a torus's top) are projected flat from above.
// - Every other shape gets a box projection: each triangle is projected along the axis its face
//   points most along. Vertices are split where neighboring triangles project differently, so no
//   triangle smears the texture across a projection change (the cost of real triplanar mapping
//   without its extra shader work).
//
// The texture's U axis (grain, brushing, planks) runs along the part's `grain` axis: by default Y
// for round shapes (a post, a log) and the longest side for the others (a plank, a beam). A
// per-part offset keeps neighboring parts from showing the same patch of texture.

extension MeshBuildPart {
    /// The part's look, if `look` names one.
    public var resolvedLook: MeshBuildLook? {
        guard let look, !look.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return MeshBuildLook.named(look)
    }

    /// Problems with the look fields (empty when fine).
    public var lookWarnings: [String] {
        var warnings: [String] = []
        if let look, !look.trimmingCharacters(in: .whitespaces).isEmpty, MeshBuildLook.named(look) == nil,
           MeshBuildLeafLook.named(look) == nil, shape != .foliage {
            warnings.append("unknown look '\(look)'; looks: \(MeshBuildLook.nameList); leaf looks: \(MeshBuildLeafLook.nameList)")
        }
        if let lookScale, !(lookScale.isFinite && lookScale > 0) { warnings.append("lookScale must be a number of meters > 0") }
        if let wear, !(wear.isFinite && wear >= 0 && wear <= 1) { warnings.append("wear must be between 0 and 1") }
        return warnings
    }

    /// Shapes wrapped around their Y axis by the look mapping.
    var isRoundShape: Bool {
        switch shape {
        case .sphere, .hemisphere, .cylinder, .cone, .capsule, .torus, .tube, .lathe: true
        default: false
        }
    }

    /// The axis the look's grain runs along (index 0...2 in the part's space).
    var lookGrainAxis: Int {
        if let grain { return grain.index }
        if isRoundShape { return 1 }
        let s = Vec3(abs(size.x), abs(size.y), abs(size.z))
        if shape == .plane { return s.x >= s.z ? 0 : 2 }
        return s.x >= s.y && s.x >= s.z ? 0 : s.y >= s.z ? 1 : 2
    }

    /// Meters per texture tile of the part's look.
    var effectiveLookScale: Float {
        let scale = lookScale ?? resolvedLook?.defaultScale ?? 1
        return scale.isFinite && scale > 0.001 ? scale : resolvedLook?.defaultScale ?? 1
    }

    /// The look's texture coordinates on `geometry` (the part's mesh, in its space).
    func applyingLookUVs(to geometry: MeshGeometry) -> MeshGeometry {
        let offset = Vec2(TileNoise.hash01(Int(Self.nameHash(name)), 1), TileNoise.hash01(Int(Self.nameHash(name)), 2))
        if isRoundShape {
            let b = geometry.bounds
            var radius: Float = 0
            for v in geometry.vertices { radius = max(radius, (v.position.x * v.position.x + v.position.z * v.position.z).squareRoot()) }
            if shape != .lathe { radius = max(b.halfExtent.x, b.halfExtent.z) }
            return geometry.lookProjected(round: true, grain: lookGrainAxis, scale: effectiveLookScale, radius: radius, offset: offset)
        }
        return geometry.lookProjected(round: false, grain: lookGrainAxis, scale: effectiveLookScale, radius: 0, offset: offset)
    }

    static func nameHash(_ name: String) -> UInt32 {
        var h: UInt32 = 2_166_136_261
        for byte in name.utf8 { h = (h ^ UInt32(byte)) &* 16_777_619 }
        return h
    }
}

extension MeshGeometry {
    /// A copy with look texture coordinates (in tiles of `scale` meters, see the notes at the top
    /// of this file), vertices split where the projection changes. Tangents are cleared.
    func lookProjected(round: Bool, grain: Int, scale: Float, radius: Float, offset: Vec2) -> MeshGeometry {
        let inv = 1 / max(scale, 1e-4)
        let around = max(1, (2 * Float.pi * radius * inv).rounded())
        var result = MeshGeometry(vertices: [], indices: [])
        result.vertices.reserveCapacity(vertices.count)
        result.indices.reserveCapacity(indices.count)
        // (source vertex, projection group) -> new vertex.
        var remap: [UInt64: UInt32] = [:]

        func boxUV(_ p: Vec3, axis d: Int) -> Vec2 {
            let others = [0, 1, 2].filter { $0 != d }
            // On an end face (the grain points out of it) keep U level: planks stay horizontal on walls.
            let (uAxis, vAxis) = grain != d ? (grain, others.first { $0 != grain }!)
                : others.contains(1) ? (others.first { $0 != 1 }!, 1) : (others[0], others[1])
            // Keep "up" up on the walls: V runs down the Y axis.
            let vSign: Float = vAxis == 1 ? -1 : 1
            return Vec2(p[uAxis], p[vAxis] * vSign) * inv
        }

        for t in stride(from: 0, to: indices.count - 2, by: 3) {
            let ids = [Int(indices[t]), Int(indices[t + 1]), Int(indices[t + 2])]
            let p = ids.map { vertices[$0].position }
            var n = vertices[ids[0]].normal + vertices[ids[1]].normal + vertices[ids[2]].normal
            if length(n) < 1e-6 { n = cross(p[1] - p[0], p[2] - p[0]) }
            let a = Vec3(abs(n.x), abs(n.y), abs(n.z))
            var group: UInt64
            var uvs: [Vec2]
            if round && a.y <= 0.7 * length(n) {
                // Around Y. Angles of corners on the axis (a cone's tip) come from the others.
                var angles = p.map { q -> Float? in
                    let r = (q.x * q.x + q.z * q.z).squareRoot()
                    return r > 1e-5 * max(radius, 1e-3) ? atan2f(q.x, q.z) : nil
                }
                let known = angles.compactMap { $0 }
                guard !known.isEmpty else { continue }
                let reference = known[0]
                var wrapped = false
                for k in 0..<3 {
                    guard var angle = angles[k] else { continue }
                    // Keep the triangle on one side of the seam at ±180°.
                    if angle - reference > .pi { angle -= 2 * .pi; wrapped = true }
                    if reference - angle > .pi { angle += 2 * .pi; wrapped = true }
                    angles[k] = angle
                }
                let filled = known.count == 3 ? angles.map { $0! } : {
                    let mean = angles.compactMap { $0 }.reduce(0, +) / Float(angles.compactMap { $0 }.count)
                    return angles.map { $0 ?? mean }
                }()
                group = known.count == 3 ? (wrapped ? 1 : 0) : UInt64(16 + t)  // tip corners stay per triangle
                if reference < 0 && wrapped { group = 2 }
                uvs = (0..<3).map { k in
                    let aroundTiles = filled[k] / (2 * .pi) * around
                    let along = p[k].y * inv
                    // Grain along Y: U runs up the part; otherwise U runs around it.
                    return grain == 1 ? Vec2(along, aroundTiles) : Vec2(aroundTiles, -along)
                }
            } else if round {
                group = n.y >= 0 ? 3 : 4
                uvs = p.map { boxUV($0, axis: 1) }
            } else {
                let d = a.x >= a.y && a.x >= a.z ? 0 : a.y >= a.z ? 1 : 2
                group = UInt64(5 + d * 2 + (n[d] < 0 ? 1 : 0))
                uvs = p.map { boxUV($0, axis: d) }
            }
            for k in 0..<3 {
                let key = UInt64(ids[k]) << 32 | group
                if let existing = remap[key], result.vertices[Int(existing)].uv == uvs[k] + offset {
                    result.indices.append(existing)
                    continue
                }
                var vertex = vertices[ids[k]]
                vertex.uv = uvs[k] + offset
                vertex.tangent = .zero
                let index = UInt32(result.vertices.count)
                result.append(vertex: vertex, from: self, ids[k])
                if remap[key] == nil { remap[key] = index }
                result.indices.append(index)
            }
        }
        result.skin = nil
        return result
    }

    /// A copy whose triangles are split until no edge is longer than `maxEdge` (stopping early at
    /// about `maxTriangles`). Edges are split at their midpoints on both sides (keyed by position,
    /// so split normals and UV seams don't crack), with normals and UVs interpolated.
    func tessellated(maxEdge: Float, maxTriangles: Int) -> MeshGeometry {
        guard maxEdge > 0, maxEdge.isFinite else { return self }
        var g = self
        g.skin = nil
        let limit2 = maxEdge * maxEdge
        func key(_ p: Vec3) -> SIMD3<Int32> {
            SIMD3(Int32(clamping: Int((p.x * 1e5).rounded())), Int32(clamping: Int((p.y * 1e5).rounded())),
                  Int32(clamping: Int((p.z * 1e5).rounded())))
        }
        struct EdgeKey: Hashable {
            var a: SIMD3<Int32>
            var b: SIMD3<Int32>
            init(_ p: SIMD3<Int32>, _ q: SIMD3<Int32>) {
                let pFirst = p.x != q.x ? p.x < q.x : p.y != q.y ? p.y < q.y : p.z < q.z
                (a, b) = pFirst ? (p, q) : (q, p)
            }
        }
        var midpoints: [UInt64: UInt32] = [:]
        func midpoint(_ i: UInt32, _ j: UInt32) -> UInt32 {
            let k = i < j ? UInt64(i) << 32 | UInt64(j) : UInt64(j) << 32 | UInt64(i)
            if let m = midpoints[k] { return m }
            let a = g.vertices[Int(i)], b = g.vertices[Int(j)]
            var n = a.normal + b.normal
            let len = length(n)
            n = len > 1e-6 ? n / len : a.normal
            g.appendMidpoint(MeshVertex(position: (a.position + b.position) / 2, normal: n, uv: (a.uv + b.uv) / 2), between: Int(i), Int(j))
            let m = UInt32(g.vertices.count - 1)
            midpoints[k] = m
            return m
        }
        for _ in 0..<16 {
            let count = g.indices.count / 3
            guard count < maxTriangles else { break }
            // Mark each triangle's longest edge if it is too long.
            var marked = Set<EdgeKey>()
            for t in 0..<count {
                let i = (g.indices[t * 3], g.indices[t * 3 + 1], g.indices[t * 3 + 2])
                let p = (g.vertices[Int(i.0)].position, g.vertices[Int(i.1)].position, g.vertices[Int(i.2)].position)
                let l = (dot(p.1 - p.0, p.1 - p.0), dot(p.2 - p.1, p.2 - p.1), dot(p.0 - p.2, p.0 - p.2))
                let longest = max(l.0, l.1, l.2)
                guard longest > limit2 else { continue }
                if l.0 == longest { marked.insert(EdgeKey(key(p.0), key(p.1))) }
                else if l.1 == longest { marked.insert(EdgeKey(key(p.1), key(p.2))) }
                else { marked.insert(EdgeKey(key(p.2), key(p.0))) }
            }
            guard !marked.isEmpty else { break }
            var next: [UInt32] = []
            next.reserveCapacity(g.indices.count * 2)
            for t in 0..<count {
                var c = [g.indices[t * 3], g.indices[t * 3 + 1], g.indices[t * 3 + 2]]
                let keys = c.map { key(g.vertices[Int($0)].position) }
                var split = [marked.contains(EdgeKey(keys[0], keys[1])), marked.contains(EdgeKey(keys[1], keys[2])),
                             marked.contains(EdgeKey(keys[2], keys[0]))]
                switch split.filter({ $0 }).count {
                case 0:
                    next += c
                case 1:
                    // Rotate so edge 0-1 is the split one.
                    while !split[0] { c = [c[1], c[2], c[0]]; split = [split[1], split[2], split[0]] }
                    let m = midpoint(c[0], c[1])
                    next += [c[0], m, c[2], m, c[1], c[2]]
                case 2:
                    // Rotate so edges 0-1 and 1-2 are split.
                    while !(split[0] && split[1]) { c = [c[1], c[2], c[0]]; split = [split[1], split[2], split[0]] }
                    let m01 = midpoint(c[0], c[1]), m12 = midpoint(c[1], c[2])
                    next += [m01, c[1], m12, c[0], m01, m12, c[0], m12, c[2]]
                default:
                    let m01 = midpoint(c[0], c[1]), m12 = midpoint(c[1], c[2]), m20 = midpoint(c[2], c[0])
                    next += [c[0], m01, m20, m01, c[1], m12, m20, m12, c[2], m01, m12, m20]
                }
            }
            g.indices = next
        }
        return g
    }
}
