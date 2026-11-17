import Foundation
import EngineCore
import EngineScene
import EngineAssets

// Deformers: a part's `deform` list bends, twists, tapers and roughens its finished mesh (any shape
// but a group), in order, in the part's own space (meters, after `size`) and before a mirror copy's
// reflection, so mirrored copies deform symmetrically.
//
// ```json
// {"name": "Trunk", "shape": "cylinder", "size": [0.4, 3, 0.4],
//  "deform": [{"taper": [0.5, 0.5]}, {"bend": {"axis": "x", "degrees": 20}}, {"noise": {"amount": 0.02, "scale": 0.15}}]}
// ```
//
// - `taper` [x, z]: the scale across X and Z at the top of the part relative to its bottom
//   (1 = unchanged), growing evenly with height, about the part's vertical center line.
// - `bend` {axis, degrees}: the part's Y extent curves into an arc so its top leans toward +axis
//   (x or z; negative degrees lean the other way) by that many degrees; its length is kept and
//   its bottom stays put.
// - `twist` degrees: turns about the vertical center line, 0 at the bottom up to that at the top
//   (counter-clockwise seen from above).
// - `noise` {amount m, scale m, seed}: moves the surface in and out by up to about `amount`, in
//   lumps about `scale` across (three octaves of gradient noise); the same seed gives the same lumps.
//
// The mesh is split first so it can curve: every edge longer than its largest side / 2^(level+1)
// is halved (`subdivide`, 0...6, default 3; 0 turns it off), and with noise also edges longer than a
// third of its scale, within a budget of `maxDeformTriangles` per part. When the budget stops the
// splitting before the noise's finest lumps fit, the octaves the mesh is too coarse to show fade
// out (instead of turning into spikes) and the part warns if even the largest lumps don't fit.
// Normals are recomputed afterwards: smooth where the mesh was smooth, hard edges (a box's, a
// lathe's sharp rims) stay hard.

extension MeshBuildPart {
    /// Subdivision levels `subdivide` takes.
    public static let subdivideRange = 0...6
    /// The default level when a part has deformers.
    public static let defaultSubdivide = 3
    /// The most triangles subdivision makes for one part (its budget).
    public static let maxDeformTriangles = 8_000

    /// Problems with `deform` and `subdivide` (cheap: no mesh is built).
    var deformWarnings: [String] {
        var warnings: [String] = []
        let deform = deform ?? []
        if !deform.isEmpty && shape == .group { warnings.append("a group has no mesh to deform; its deform is ignored") }
        for (i, d) in deform.enumerated() {
            let label = deform.count > 1 ? "deform \(i + 1)" : "deform"
            if d.taper == nil && d.bend == nil && d.twist == nil && d.noise == nil {
                warnings.append("\(label) has none of taper, bend, twist or noise; it does nothing")
            }
            if let t = d.taper, !(t.x.isFinite && t.y.isFinite) || t.x < 0 || t.y < 0 {
                warnings.append("\(label): taper must be two scales ≥ 0 ([x, z], 1 = unchanged); it was ignored")
            }
            if let b = d.bend {
                if b.axis == .y { warnings.append("\(label): bend axis must be x or z (the way the top leans); it was ignored") }
                if !b.degrees.isFinite { warnings.append("\(label): bend degrees must be a number; it was ignored") }
            }
            if let t = d.twist, !t.isFinite { warnings.append("\(label): twist must be a number of degrees; it was ignored") }
            if let n = d.noise {
                if !n.amount.isFinite || !n.scale.isFinite || n.scale <= 0 {
                    warnings.append("\(label): noise needs an amount (m) and a scale > 0 (m); it was ignored")
                }
            }
        }
        if let subdivide {
            if deform.isEmpty { warnings.append("subdivide only matters with deform (it splits the mesh so it can bend); it is ignored") }
            if !Self.subdivideRange.contains(subdivide) {
                warnings.append("subdivide must be 0...6; \(min(max(subdivide, 0), 6)) was used")
            }
        }
        return warnings
    }

    /// `g` (the shape in the part's space) split finely and run through `deform` in order, with
    /// its normals recomputed. Unchanged when there are no deformers.
    func deformed(_ geometry: MeshGeometry) -> MeshGeometry {
        var warnings: [String] = []
        return deformed(geometry, warnings: &warnings)
    }

    /// `deformed(_:)`, adding a sentence to `warnings` when the triangle budget is too small for its noise.
    func deformed(_ geometry: MeshGeometry, warnings: inout [String]) -> MeshGeometry {
        let steps = (deform ?? []).filter { $0 != MeshBuildDeform() }
        guard !steps.isEmpty, !geometry.vertices.isEmpty else { return geometry }
        var g = geometry
        g.snapCoincident()  // seams that differ by rounding must split and move as one
        let level = min(max(subdivide ?? Self.defaultSubdivide, 0), 6)
        if level > 0 {
            let b = g.bounds
            let extent = max(b.halfExtent.x, b.halfExtent.y, b.halfExtent.z) * 2
            var target = extent / Float(2 << level)
            for d in steps { if let n = d.noise, n.scale.isFinite, n.scale > 0 { target = min(target, n.scale / 3) } }
            if target > 0 { g.subdivide(maxEdge: target, maxTriangles: Self.maxDeformTriangles) }
        }
        // The finest lump the mesh can show: about two of its (typical longest) edges.
        let resolvable = 2 * g.typicalEdge
        if let coarsest = steps.compactMap({ $0.noise }).filter({ $0.scale.isFinite && $0.scale > 0 && $0.amount != 0 })
            .map(\.scale).max(), coarsest < resolvable * 0.75 {
            warnings.append(String(format: "noise lumps of %g m are finer than the %d-triangle budget lets this part show (about %.2g m); "
                                   + "they were smoothed away: use a larger noise scale, a smaller part, or a look's normal map (bark, stone) "
                                   + "for fine relief", coarsest, Self.maxDeformTriangles, resolvable))
        }
        var moved = false
        for d in steps {
            if let t = d.taper, t.x.isFinite, t.y.isFinite, t.x >= 0, t.y >= 0 { g.taper(t); moved = true }
            if let t = d.twist, t.isFinite { g.twist(degrees: t); moved = true }
            if let b = d.bend, b.axis != .y, b.degrees.isFinite { g.bend(toward: b.axis, degrees: b.degrees); moved = true }
            if let n = d.noise, n.amount.isFinite, n.scale.isFinite, n.scale > 0 {
                if moved { g.refreshNormals() }  // push along the deformed surface's normals
                g.displace(noise: n, finest: resolvable)
                moved = true
            }
        }
        g.refreshNormals()
        return g
    }
}

extension MeshGeometry {
    // MARK: Deformers

    /// The vertical extent and center line the deformers work about.
    private var deformFrame: (bottom: Float, height: Float, center: Vec3) {
        let b = bounds
        return (b.center.y - b.halfExtent.y, b.halfExtent.y * 2, b.center)
    }

    /// Scales X and Z about the center line from 1 at the bottom to `top` at the top.
    mutating func taper(_ top: Vec2) {
        let (bottom, height, c) = deformFrame
        guard height > 0 else { return }
        for i in vertices.indices {
            var p = vertices[i].position
            let t = (p.y - bottom) / height
            p.x = c.x + (p.x - c.x) * (1 + (top.x - 1) * t)
            p.z = c.z + (p.z - c.z) * (1 + (top.y - 1) * t)
            vertices[i].position = p
        }
    }

    /// Turns about the center line, 0 at the bottom to `degrees` at the top (counter-clockwise from above).
    mutating func twist(degrees: Float) {
        let (bottom, height, c) = deformFrame
        guard height > 0, degrees != 0 else { return }
        for i in vertices.indices {
            var p = vertices[i].position
            let a = degrees * .pi / 180 * (p.y - bottom) / height
            let x = p.x - c.x, z = p.z - c.z
            p.x = c.x + x * cosf(a) + z * sinf(a)
            p.z = c.z - x * sinf(a) + z * cosf(a)
            vertices[i].position = p
        }
    }

    /// Curves the Y extent into an arc (length kept, bottom in place) so the top leans `degrees`
    /// toward +`axis` (x or z).
    mutating func bend(toward axis: MeshBuildAxis, degrees: Float) {
        let (bottom, height, c) = deformFrame
        let theta = degrees * .pi / 180
        guard height > 0, abs(theta) > 1e-6, axis != .y else { return }
        let k = axis.index
        let radius = height / theta  // signed: the arc's center is at +radius along the axis
        for i in vertices.indices {
            var p = vertices[i].position
            let phi = theta * (p.y - bottom) / height
            let d = p[k] - c[k]
            p[k] = c[k] + radius - (radius - d) * cosf(phi)
            p.y = bottom + (radius - d) * sinf(phi)
            vertices[i].position = p
        }
    }

    /// The mean of the triangles' longest edges (0 for no triangles).
    var typicalEdge: Float {
        var sum: Float = 0, count = 0
        for t in stride(from: 0, to: indices.count - 2, by: 3) {
            let a = vertices[Int(indices[t])].position, b = vertices[Int(indices[t + 1])].position
            let c = vertices[Int(indices[t + 2])].position
            sum += max(length(b - a), length(c - b), length(a - c))
            count += 1
        }
        return count > 0 ? sum / Float(count) : 0
    }

    /// Moves each point along the surface's (welded) normal by fractal noise of `noise`. Points at
    /// one position move together, so hard edges don't open. Octaves whose lumps are smaller than
    /// `finest` meters (what the mesh's spacing can show) fade out.
    mutating func displace(noise: MeshBuildDeform.Noise, finest: Float = 0) {
        let groups = weldGroups()
        let seed = UInt32(truncatingIfNeeded: noise.seed)
        let offset = Vec3(Float(MeshDeformNoise.hash(1, 2, 3, seed) % 1000), Float(MeshDeformNoise.hash(4, 5, 6, seed) % 1000),
                          Float(MeshDeformNoise.hash(7, 8, 9, seed) % 1000)) * 0.137
        for group in groups {
            var n = Vec3.zero
            for v in group { n += vertices[v].normal }
            guard length(n) > 1e-9 else { continue }
            n = normalize(n)
            let p = vertices[group[0]].position
            let h = MeshDeformNoise.fbm(p / noise.scale + offset, seed: seed, finest: finest / noise.scale) * noise.amount
            for v in group { vertices[v].position = p + n * h }
        }
    }

    // MARK: Subdivision and normals

    /// How close two vertices must be to count as one point (seams whose ends differ by rounding).
    static let weldTolerance: Float = 1e-5

    /// Vertex indices grouped by position: each vertex joins the first group whose first vertex is
    /// within `weldTolerance` (searched in the neighboring grid cells, so rounding never splits a pair).
    func weldGroups() -> [[Int]] {
        let tolerance = Self.weldTolerance, size = 2 * tolerance
        var cells: [SIMD3<Int32>: [Int]] = [:]  // cell → groups whose first vertex is in it
        var groups: [[Int]] = []
        func cell(_ p: Vec3) -> SIMD3<Int32> {
            let q = p / size
            return SIMD3<Int32>(Int32(clamping: Int(q.x.rounded(.down))), Int32(clamping: Int(q.y.rounded(.down))),
                                Int32(clamping: Int(q.z.rounded(.down))))
        }
        for (i, v) in vertices.enumerated() {
            let p = v.position
            // Cells twice the tolerance wide: a match is in the one or two cells per axis that
            // [p - tolerance, p + tolerance] touches.
            let lo = cell(p - Vec3(repeating: tolerance)), hi = cell(p + Vec3(repeating: tolerance))
            var found: Int?
            search: for x in lo.x...hi.x {
                for y in lo.y...hi.y {
                    for z in lo.z...hi.z {
                        guard let candidates = cells[SIMD3(x, y, z)] else { continue }
                        for g in candidates where length(vertices[groups[g][0]].position - p) <= tolerance {
                            found = g
                            break search
                        }
                    }
                }
            }
            let c = cell(p)
            if let found {
                groups[found].append(i)
            } else {
                cells[c, default: []].append(groups.count)
                groups.append([i])
            }
        }
        return groups
    }

    /// Moves vertices that are nearly at one point exactly onto it, so later steps treat them alike.
    mutating func snapCoincident() {
        for group in weldGroups() where group.count > 1 {
            let p = vertices[group[0]].position
            for v in group.dropFirst() { vertices[v].position = p }
        }
    }

    /// Splits every edge longer than `maxEdge` at its middle (positions, normals and UVs halfway),
    /// pass after pass until none is, or until another pass would pass `maxTriangles`. The choice is
    /// made per edge from its length alone, so triangles on either side of an edge (even across a
    /// hard edge's split vertices) split it alike and the surface stays closed.
    mutating func subdivide(maxEdge: Float, maxTriangles: Int) {
        guard maxEdge > 0, maxEdge.isFinite else { return }
        let limit = maxEdge * maxEdge
        for _ in 0..<12 {
            var midpoints: [UInt64: UInt32] = [:]
            func long(_ a: UInt32, _ b: UInt32) -> Bool {
                let d = vertices[Int(a)].position - vertices[Int(b)].position
                return dot(d, d) > limit
            }
            var splitting = 0
            for t in stride(from: 0, to: indices.count - 2, by: 3) {
                let a = indices[t], b = indices[t + 1], c = indices[t + 2]
                splitting += (long(a, b) ? 1 : 0) + (long(b, c) ? 1 : 0) + (long(c, a) ? 1 : 0)
            }
            guard splitting > 0, indices.count / 3 + splitting <= maxTriangles else { return }
            func midpoint(_ a: UInt32, _ b: UInt32) -> UInt32 {
                let key = UInt64(min(a, b)) << 32 | UInt64(max(a, b))
                if let m = midpoints[key] { return m }
                let va = vertices[Int(a)], vb = vertices[Int(b)]
                let n = va.normal + vb.normal
                appendMidpoint(MeshVertex(position: (va.position + vb.position) * 0.5,
                                          normal: length(n) > 1e-9 ? normalize(n) : va.normal, uv: (va.uv + vb.uv) * 0.5),
                               between: Int(a), Int(b))
                let m = UInt32(vertices.count - 1)
                midpoints[key] = m
                return m
            }
            var result: [UInt32] = []
            result.reserveCapacity(indices.count * 2)
            for t in stride(from: 0, to: indices.count - 2, by: 3) {
                var (a, b, c) = (indices[t], indices[t + 1], indices[t + 2])
                var (sab, sbc, sca) = (long(a, b), long(b, c), long(c, a))
                func turn() { (a, b, c) = (b, c, a); (sab, sbc, sca) = (sbc, sca, sab) }
                switch (sab ? 1 : 0) + (sbc ? 1 : 0) + (sca ? 1 : 0) {
                case 0:
                    result += [a, b, c]
                case 1:
                    while !sab { turn() }
                    let m = midpoint(a, b)
                    result += [a, m, c, m, b, c]
                case 2:
                    while sca { turn() }
                    let m0 = midpoint(a, b), m1 = midpoint(b, c)
                    result += [m0, b, m1, a, m0, m1, a, m1, c]
                default:
                    let m0 = midpoint(a, b), m1 = midpoint(b, c), m2 = midpoint(c, a)
                    result += [a, m0, m2, m0, b, m1, m2, m1, c, m0, m1, m2]
                }
            }
            indices = result
        }
    }

    /// Recomputes every normal from the triangles around it (weighted by their corner angles).
    /// Vertices at the same position share their triangles when their current normals are within
    /// `sharpAngle` degrees of each other, so a seam heals while a hard edge (vertices split with
    /// different normals) stays hard.
    mutating func refreshNormals(sharpAngle: Float = profileSharpAngle) {
        var sums = [Vec3](repeating: .zero, count: vertices.count)
        func angle(_ e1: Vec3, _ e2: Vec3) -> Float {
            let l = length(e1) * length(e2)
            return l > 0 ? acosf(min(max(dot(e1, e2) / l, -1), 1)) : 0
        }
        for t in stride(from: 0, to: indices.count - 2, by: 3) {
            let ia = Int(indices[t]), ib = Int(indices[t + 1]), ic = Int(indices[t + 2])
            let a = vertices[ia].position, b = vertices[ib].position, c = vertices[ic].position
            let face = cross(b - a, c - a)
            let area = length(face)
            guard area > 1e-14 else { continue }
            let n = face / area
            sums[ia] += n * angle(b - a, c - a)
            sums[ib] += n * angle(c - b, a - b)
            sums[ic] += n * angle(a - c, b - c)
        }
        let cosSharp = cosf(sharpAngle * .pi / 180)
        var normals = vertices.map(\.normal)
        for group in weldGroups() {
            if group.count == 1 {
                if length(sums[group[0]]) > 1e-12 { normals[group[0]] = normalize(sums[group[0]]) }
                continue
            }
            for v in group {
                var s = Vec3.zero
                for w in group where w == v || dot(vertices[v].normal, vertices[w].normal) >= cosSharp { s += sums[w] }
                if length(s) > 1e-12 { normals[v] = normalize(s) }
            }
        }
        for i in vertices.indices { vertices[i].normal = normals[i] }
    }
}

/// Seeded 3D gradient noise for the `noise` deformer.
enum MeshDeformNoise {
    static func hash(_ x: Int32, _ y: Int32, _ z: Int32, _ seed: UInt32) -> UInt32 {
        var h = UInt32(bitPattern: x) &* 0x8DA6_B343 ^ UInt32(bitPattern: y) &* 0xD816_3841 ^ UInt32(bitPattern: z) &* 0xCB1A_B31F
        h ^= seed &* 0x9E37_79B9
        h ^= h >> 13
        h &*= 0x5BD1_E995
        h ^= h >> 15
        return h
    }

    private static let gradients: [Vec3] = [
        Vec3(1, 1, 0), Vec3(-1, 1, 0), Vec3(1, -1, 0), Vec3(-1, -1, 0), Vec3(1, 0, 1), Vec3(-1, 0, 1),
        Vec3(1, 0, -1), Vec3(-1, 0, -1), Vec3(0, 1, 1), Vec3(0, -1, 1), Vec3(0, 1, -1), Vec3(0, -1, -1),
    ]

    /// Perlin-style gradient noise, about -1...1.
    static func gradient(_ p: Vec3, seed: UInt32) -> Float {
        let f = Vec3(floorf(p.x), floorf(p.y), floorf(p.z))
        let x = Int32(clamping: Int(f.x)), y = Int32(clamping: Int(f.y)), z = Int32(clamping: Int(f.z))
        let d = p - f
        func fade(_ t: Float) -> Float { t * t * t * (t * (t * 6 - 15) + 10) }
        func corner(_ i: Int32, _ j: Int32, _ k: Int32) -> Float {
            let g = gradients[Int(hash(x &+ i, y &+ j, z &+ k, seed) % 12)]
            return dot(g, d - Vec3(Float(i), Float(j), Float(k)))
        }
        let u = fade(d.x), v = fade(d.y), w = fade(d.z)
        func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
        return lerp(lerp(lerp(corner(0, 0, 0), corner(1, 0, 0), u), lerp(corner(0, 1, 0), corner(1, 1, 0), u), v),
                    lerp(lerp(corner(0, 0, 1), corner(1, 0, 1), u), lerp(corner(0, 1, 1), corner(1, 1, 1), u), v), w)
    }

    /// Three octaves of `gradient`, about -1...1. Octaves whose wavelength (1 for the first, then
    /// halving) is below `finest` fade out.
    static func fbm(_ p: Vec3, seed: UInt32, finest: Float = 0) -> Float {
        var sum: Float = 0, amplitude: Float = 1, q = p, wavelength: Float = 1
        for octave in 0..<3 {
            let keep = finest > 0 ? min(max((wavelength / finest - 0.5) * 2, 0), 1) : 1
            if keep > 0 { sum += gradient(q, seed: seed &+ UInt32(octave) &* 101) * amplitude * keep }
            amplitude *= 0.5
            wavelength /= 2.03
            q = q * 2.03 + Vec3(17.1, 31.7, 5.3)
        }
        return min(max(sum / 1.75 * 1.5, -1), 1)
    }
}
