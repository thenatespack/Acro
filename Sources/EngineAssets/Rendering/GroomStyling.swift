/// Helpers for styled card hair (GroomGeometry.swift): the hair's bounds frame, the part, fringe
/// and length profile (`GroomShaper`), closest-point queries on the base mesh (`GroomSurface`),
/// colliders, and the distance from each vertex to the hair's edge (the hairline).
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// The bounding box of the furry area: the frame of the style keys given in bounds units
/// (-1...1 per axis; the face toward +Z, up +Y).
struct GroomFrame {
    var center: Vec3
    var extent: Vec3

    init(_ base: MeshGeometry, lengths: [Float]) {
        var lo = Vec3(repeating: .greatestFiniteMagnitude), hi = Vec3(repeating: -.greatestFiniteMagnitude)
        for (i, v) in base.vertices.enumerated() where i < lengths.count && lengths[i] > 0.01 {
            lo = pointwiseMin(lo, v.position)
            hi = pointwiseMax(hi, v.position)
        }
        if lo.x > hi.x {
            for v in base.vertices {
                lo = pointwiseMin(lo, v.position)
                hi = pointwiseMax(hi, v.position)
            }
        }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        center = (lo + hi) * 0.5
        extent = pointwiseMax((hi - lo) * 0.5, Vec3(repeating: 1e-4))
    }

    func local(_ p: Vec3) -> Vec3 { (p - center) / extent }
    func world(_ q: Vec3) -> Vec3 { center + q * extent }
}

/// The part, the fringe, the length profile and the comb and cut strokes, evaluated at any point.
struct GroomShaper {
    let groom: GroomBuild
    let frame: GroomFrame
    /// The part line in mesh space (front to crown), empty when there is no part.
    let partLine: [Vec3]

    init(groom: GroomBuild, frame: GroomFrame) {
        self.groom = groom
        self.frame = frame
        let part = groom.part
        guard part.isActive else { partLine = []; return }
        switch part.style {
        case .curve: partLine = part.points
        default:
            let offset = part.style == .side && part.offset == 0 ? 0.4 : (part.style == .center ? 0 : part.offset)
            let x = min(max(offset.isFinite ? offset : 0, -1), 1), crown = min(max(part.crown.isFinite ? part.crown : -0.3, -1), 1)
            partLine = [frame.world(Vec3(x, 1, 1)), frame.world(Vec3(x, 1, crown))]
        }
    }

    /// The closest point on the part line to `p`.
    func partClosest(_ p: Vec3) -> Vec3? {
        guard let first = partLine.first else { return nil }
        if partLine.count == 1 { return first }
        var best = first, bestD = Float.greatestFiniteMagnitude
        for i in 0..<(partLine.count - 1) {
            let q = Self.closestOnSegment(p, partLine[i], partLine[i + 1])
            let d = dot2(p - q)
            if d < bestD { bestD = d; best = q }
        }
        return best
    }

    /// True on the bare line of the part (seen from above).
    func onPartLine(_ p: Vec3) -> Bool {
        guard groom.part.isActive, groom.part.width > 0, let q = partClosest(p), frame.local(p).y > 0 else { return false }
        let d = Vec2(p.x - q.x, p.z - q.z)
        return (d.x * d.x + d.y * d.y).squareRoot() < groom.part.width * 0.5
    }

    /// 0...1: how much `p` belongs to the fringe.
    func fringeWeight(_ p: Vec3) -> Float {
        let f = groom.fringe
        guard f.amount > 0 else { return 0 }
        let q = frame.local(p)
        let half = min(max(f.amount, 0), 1) * 0.75
        let across = abs(q.x - f.sweep * 0.25)
        return Self.smoothstep(0.1, 0.55, q.z) * (1 - Self.smoothstep(half, half + 0.25, across)) * Self.smoothstep(-0.5, 0.1, q.y)
    }

    /// The length factor at `p` from the mask's `base`: the length profile, the fringe, then the cut strokes.
    func lengthFactor(at p: Vec3, base: Float) -> Float {
        var l = base
        if l > 0.01, !groom.lengthProfile.isFlat {
            let q = frame.local(p)
            let d = length(q) > 1e-5 ? normalize(q) : Vec3(0, 1, 0)
            let wf = max(d.z, 0) * max(d.z, 0), wb = max(-d.z, 0) * max(-d.z, 0), wt = max(d.y, 0) * max(d.y, 0), ws = d.x * d.x
            let sum = wf + wb + wt + ws
            let pr = groom.lengthProfile
            if sum > 1e-5 { l *= max((wf * pr.front + wb * pr.back + wt * pr.top + ws * pr.sides) / sum, 0) }
        }
        let fw = fringeWeight(p)
        if fw > 0, l > 0.01 {
            let target = max(groom.fringe.length, 0) / groom.clampedLength
            l += (target - l) * fw
        }
        for stroke in groom.cut where stroke.radius > 0 {
            let w = GroomGeometry.clamp01(stroke.strength) * GroomGeometry.falloff(length(p - stroke.center) / stroke.radius)
            if w > 0 { l += (min(max(stroke.length, 0), 2) - l) * w }
        }
        return min(max(l, 0), 2)
    }

    /// The comb vector at `p` (normal `n`) from the base comb (`combDirection` or the flow map):
    /// the part, the fringe, then the comb strokes.
    func comb(at p: Vec3, normal n: Vec3, base: Vec3) -> Vec3 {
        var c = base
        let strength = max(GroomGeometry.clamp01(groom.combStrength), length(base))
        if let q = partClosest(p) {
            var away = GroomGeometry.tangential(p - q, n)
            if dot2(away) < 1e-8 { away = GroomGeometry.tangential(Vec3(0, -1, 0), n) }
            let w = GroomGeometry.clamp01(groom.part.strength)
            let dir = GroomGeometry.safeNormalize(GroomGeometry.safeNormalize(c, fallback: .zero) * (1 - w) + away * w, fallback: away)
            c = dir * strength
        }
        let sweep = GroomGeometry.clamp01(groom.sweepBack) * GroomShaper.smoothstep(-0.1, 0.7, frame.local(p).z)
        if sweep > 0 {
            // Away from a point in front of the face: up and back over the top, back along the sides.
            let away = GroomGeometry.tangential(p - frame.world(Vec3(0, -0.4, 1.6)), n)
            if dot2(away) > 0 {
                c = GroomGeometry.safeNormalize(GroomGeometry.safeNormalize(c, fallback: .zero) * (1 - sweep) + away * sweep, fallback: away) * strength
            }
        }
        let fw = fringeWeight(p)
        if fw > 0 {
            let dir = GroomGeometry.tangential(Vec3(groom.fringe.sweep * 0.8, -0.7, 1), n)
            c += (dir * max(strength, 0.8) - c) * fw
        }
        for stroke in groom.comb where stroke.radius > 0 {
            let w = GroomGeometry.clamp01(stroke.strength) * GroomGeometry.falloff(length(p - stroke.center) / stroke.radius)
            if w > 0 { c += (GroomGeometry.tangential(stroke.direction, n) - c) * w }
        }
        return c
    }

    static func closestOnSegment(_ p: Vec3, _ a: Vec3, _ b: Vec3) -> Vec3 {
        let ab = b - a
        let l2 = dot2(ab)
        guard l2 > 1e-12 else { return a }
        let t = min(max(dot(p - a, ab) / l2, 0), 1)
        return a + ab * t
    }

    static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

/// Closest-point queries on a mesh's triangles through a uniform grid.
package final class GroomSurface {
    package struct Hit {
        var point: Vec3
        /// The smooth (vertex) normal there.
        var normal: Vec3
        /// The triangle's own normal, facing like `normal`.
        var faceNormal: Vec3
        var triangle: Int
        /// Weights of the triangle's corners.
        var weights: Vec3
    }

    let positions: [Vec3]
    let normals: [Vec3]
    let triangles: [SIMD3<Int32>]
    let cell: Float
    /// A dense grid over the mesh's bounds: cell c's triangles are cellTriangles[cellStart[c]..<cellStart[c + 1]].
    private let origin: Vec3
    private let dims: SIMD3<Int32>
    private var cellStart: [Int32] = []
    private var cellTriangles: [Int32] = []
    /// Each triangle's bounding sphere (center, radius).
    private let bounds: [Vec4]
    /// Triangles the current query has tested (a triangle sits in several cells).
    private var stamps: [UInt32]
    private var stamp: UInt32 = 0

    package init(_ base: MeshGeometry, cell requested: Float) {
        positions = base.vertices.map(\.position)
        normals = base.vertices.map(\.normal)
        var tris: [SIMD3<Int32>] = []
        var edge: Float = 0
        var t = 0
        while t + 2 < base.indices.count {
            let tri = SIMD3(Int32(base.indices[t]), Int32(base.indices[t + 1]), Int32(base.indices[t + 2]))
            t += 3
            guard Int(max(tri.x, max(tri.y, tri.z))) < base.vertices.count else { continue }
            tris.append(tri)
            edge += length(base.vertices[Int(tri.y)].position - base.vertices[Int(tri.x)].position)
        }
        triangles = tris
        bounds = tris.map { tri in
            let a = base.vertices[Int(tri.x)].position, b = base.vertices[Int(tri.y)].position, c = base.vertices[Int(tri.z)].position
            let center = (a + b + c) / 3
            return Vec4(center.x, center.y, center.z, max(length(a - center), length(b - center), length(c - center)))
        }
        stamps = [UInt32](repeating: 0, count: tris.count)
        let average = tris.isEmpty ? 0.01 : edge / Float(tris.count)
        var lo = Vec3(repeating: .greatestFiniteMagnitude), hi = Vec3(repeating: -.greatestFiniteMagnitude)
        for p in positions where p.x.isFinite && p.y.isFinite && p.z.isFinite { lo = pointwiseMin(lo, p); hi = pointwiseMax(hi, p) }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        var size = max(requested.isFinite ? requested : 0.01, average, 1e-4)
        // At most about two million cells.
        let span = hi - lo
        while (span.x / size + 1) * (span.y / size + 1) * (span.z / size + 1) > 2_000_000 { size *= 1.5 }
        cell = size
        origin = lo
        dims = SIMD3(Int32(span.x / size) + 1, Int32(span.y / size) + 1, Int32(span.z / size) + 1)
        // Count, then fill (CSR).
        let cellCount = Int(dims.x) * Int(dims.y) * Int(dims.z)
        var counts = [Int32](repeating: 0, count: cellCount + 1)
        var ranges: [(SIMD3<Int32>, SIMD3<Int32>)] = []
        ranges.reserveCapacity(tris.count)
        for tri in tris {
            let a = positions[Int(tri.x)], b = positions[Int(tri.y)], c = positions[Int(tri.z)]
            ranges.append((cellOf(pointwiseMin(a, pointwiseMin(b, c))), cellOf(pointwiseMax(a, pointwiseMax(b, c)))))
        }
        for (l, h) in ranges {
            for z in l.z...h.z { for y in l.y...h.y { for x in l.x...h.x { counts[index(x, y, z) + 1] += 1 } } }
        }
        for c in 0..<cellCount { counts[c + 1] += counts[c] }
        var fill = counts
        var slots = [Int32](repeating: 0, count: Int(counts[cellCount]))
        for (i, (l, h)) in ranges.enumerated() {
            for z in l.z...h.z {
                for y in l.y...h.y {
                    for x in l.x...h.x {
                        let c = index(x, y, z)
                        slots[Int(fill[c])] = Int32(i)
                        fill[c] += 1
                    }
                }
            }
        }
        cellStart = counts
        cellTriangles = slots
    }

    /// The cell holding `p`, clamped to the grid.
    private func cellOf(_ p: Vec3) -> SIMD3<Int32> {
        let q = (p - origin) / cell
        func axis(_ v: Float, _ n: Int32) -> Int32 { v.isFinite ? min(max(Int32(max(min(v, 1e6), -1)), 0), n - 1) : 0 }
        return SIMD3(axis(q.x, dims.x), axis(q.y, dims.y), axis(q.z, dims.z))
    }

    private func index(_ x: Int32, _ y: Int32, _ z: Int32) -> Int { (Int(z) * Int(dims.y) + Int(y)) * Int(dims.x) + Int(x) }

    /// The closest point on the mesh within `radius` of `p`.
    package func closest(_ p: Vec3, within radius: Float) -> Hit? {
        guard !triangles.isEmpty else { return nil }
        // Outside the mesh's bounds by more than the radius: nothing near.
        let top = origin + Vec3(Float(dims.x), Float(dims.y), Float(dims.z)) * cell
        if p.x < origin.x - radius || p.y < origin.y - radius || p.z < origin.z - radius
            || p.x > top.x + radius || p.y > top.y + radius || p.z > top.z + radius { return nil }
        let lo = cellOf(p - Vec3(repeating: radius)), hi = cellOf(p + Vec3(repeating: radius))
        var best: (d2: Float, tri: Int, point: Vec3, w: Vec3)?
        var limit = radius * radius
        stamp &+= 1
        for z in lo.z...hi.z {
            for y in lo.y...hi.y {
                for x in lo.x...hi.x {
                    let c = index(x, y, z)
                    for slot in Int(cellStart[c])..<Int(cellStart[c + 1]) {
                        let i = cellTriangles[slot]
                        guard stamps[Int(i)] != stamp else { continue }
                        stamps[Int(i)] = stamp
                        // Too far even for its bounding sphere.
                        let bound = bounds[Int(i)]
                        let reach = limit.squareRoot() + bound.w
                        if dot2(p - Vec3(bound.x, bound.y, bound.z)) > reach * reach { continue }
                        let tri = triangles[Int(i)]
                        let (q, w) = Self.closestOnTriangle(p, positions[Int(tri.x)], positions[Int(tri.y)], positions[Int(tri.z)])
                        let d2 = dot2(p - q)
                        if d2 < limit || (d2 == limit && best == nil) {
                            limit = d2
                            best = (d2, Int(i), q, w)
                        }
                    }
                }
            }
        }
        guard let best else { return nil }
        let tri = triangles[best.tri]
        let a = Int(tri.x), b = Int(tri.y), c = Int(tri.z)
        var face = cross(positions[b] - positions[a], positions[c] - positions[a])
        let smooth = normals[a] * best.w.x + normals[b] * best.w.y + normals[c] * best.w.z
        face = GroomGeometry.safeNormalize(face, fallback: Vec3(0, 1, 0))
        let n = GroomGeometry.safeNormalize(smooth, fallback: face)
        if dot(face, n) < 0 { face = -face }
        return Hit(point: best.point, normal: n, faceNormal: face, triangle: best.tri, weights: best.w)
    }

    /// Moves `p` out to `offset` above the surface when it is below that and the surface is right
    /// under it (not off an open edge). Returns the surface normal when it pushed.
    package func pushOut(_ p: inout Vec3, offset: Float, within radius: Float) -> Vec3? {
        guard let hit = closest(p, within: radius) else { return nil }
        let v = p - hit.point
        let d = dot(v, hit.faceNormal)
        let dist = length(v)
        guard d < offset, dist < 1e-6 || abs(d) >= 0.7 * dist else { return nil }
        p = hit.point + hit.normal * offset
        return hit.normal
    }

    /// The closest point on triangle abc to p, and its corner weights (Ericson, Real-Time Collision Detection 5.1.5).
    static func closestOnTriangle(_ p: Vec3, _ a: Vec3, _ b: Vec3, _ c: Vec3) -> (Vec3, Vec3) {
        let ab = b - a, ac = c - a, ap = p - a
        let d1 = dot(ab, ap), d2 = dot(ac, ap)
        if d1 <= 0 && d2 <= 0 { return (a, Vec3(1, 0, 0)) }
        let bp = p - b
        let d3 = dot(ab, bp), d4 = dot(ac, bp)
        if d3 >= 0 && d4 <= d3 { return (b, Vec3(0, 1, 0)) }
        let vc = d1 * d4 - d3 * d2
        if vc <= 0 && d1 >= 0 && d3 <= 0 {
            let v = d1 / (d1 - d3)
            return (a + ab * v, Vec3(1 - v, v, 0))
        }
        let cp = p - c
        let d5 = dot(ab, cp), d6 = dot(ac, cp)
        if d6 >= 0 && d5 <= d6 { return (c, Vec3(0, 0, 1)) }
        let vb = d5 * d2 - d1 * d6
        if vb <= 0 && d2 >= 0 && d6 <= 0 {
            let w = d2 / (d2 - d6)
            return (a + ac * w, Vec3(1 - w, 0, w))
        }
        let va = d3 * d6 - d5 * d4
        if va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0 {
            let w = (d4 - d3) / ((d4 - d3) + (d5 - d6))
            return (b + (c - b) * w, Vec3(0, 1 - w, w))
        }
        let denom = 1 / (va + vb + vc)
        let v = vb * denom, w = vc * denom
        return (a + ab * v + ac * w, Vec3(1 - v - w, v, w))
    }
}

extension GroomCollider {
    /// Moves `p` out to `offset` outside the shape; returns the outward direction when it pushed.
    package func pushOut(_ p: inout Vec3, offset: Float) -> Vec3? {
        if let end {
            let q = GroomShaper.closestOnSegment(p, center, end)
            let v = p - q
            let d = length(v)
            let r = max(radius, 0) + offset
            guard d < r else { return nil }
            let dir = d > 1e-6 ? v / d : Vec3(0, 0, 1)
            p = q + dir * r
            return dir
        }
        let radii = pointwiseMax(self.radii ?? Vec3(repeating: radius), Vec3(repeating: 1e-4))
        let u = (p - center) / radii
        let m = length(u)
        let target = 1 + offset / radii.min()
        guard m < target else { return nil }
        let dir = m > 1e-6 ? u / m : Vec3(0, 1, 0)
        p = center + dir * target * radii
        // The ellipsoid's normal there.
        return GroomGeometry.safeNormalize(dir / radii, fallback: dir)
    }
}

extension GroomGeometry {
    /// Meters from each vertex to the hair's edge (an open mesh edge or a bald vertex), walking
    /// along the mesh's edges; vertices at the same spot count as one.
    static func edgeDistances(_ base: MeshGeometry, lengths: [Float]) -> [Float] {
        let count = base.vertices.count
        // Weld seams.
        var weld = [Int](repeating: 0, count: count)
        var byPosition: [SIMD3<Int32>: Int] = [:]
        var welded = 0
        for (i, v) in base.vertices.enumerated() {
            let p = v.position * 1e4
            let k = SIMD3(Int32(p.x.rounded()), Int32(p.y.rounded()), Int32(p.z.rounded()))
            if let w = byPosition[k] { weld[i] = w } else { byPosition[k] = welded; weld[i] = welded; welded += 1 }
        }
        var position = [Vec3](repeating: .zero, count: welded)
        var bald = [Bool](repeating: false, count: welded)
        for i in 0..<count {
            position[weld[i]] = base.vertices[i].position
            if i < lengths.count, lengths[i] <= 0.01 { bald[weld[i]] = true }
        }
        // Edges of furry triangles and how many triangles use each.
        var edgeUse: [SIMD2<Int32>: Int] = [:]
        var neighbors = [[Int32]](repeating: [], count: welded)
        var t = 0
        while t + 2 < base.indices.count {
            let c = [weld[Int(base.indices[t])], weld[Int(base.indices[t + 1])], weld[Int(base.indices[t + 2])]]
            t += 3
            guard c[0] != c[1], c[1] != c[2], c[0] != c[2] else { continue }
            for k in 0..<3 {
                let a = c[k], b = c[(k + 1) % 3]
                let e = SIMD2(Int32(min(a, b)), Int32(max(a, b)))
                let n = edgeUse[e, default: 0]
                edgeUse[e] = n + 1
                if n == 0 { neighbors[a].append(Int32(b)); neighbors[b].append(Int32(a)) }
            }
        }
        var distance = [Float](repeating: .greatestFiniteMagnitude, count: welded)
        var queue: [(Float, Int)] = []
        for (e, n) in edgeUse where n == 1 { distance[Int(e.x)] = 0; distance[Int(e.y)] = 0 }
        for i in 0..<welded where bald[i] { distance[i] = 0 }
        for i in 0..<welded where distance[i] == 0 { queue.append((0, i)) }
        // Dijkstra with a binary heap.
        var heap = Heap(queue)
        while let (d, i) = heap.pop() {
            guard d <= distance[i] else { continue }
            for j in neighbors[i] {
                let nd = d + length(position[Int(j)] - position[i])
                if nd < distance[Int(j)] { distance[Int(j)] = nd; heap.push((nd, Int(j))) }
            }
        }
        return (0..<count).map { distance[weld[$0]] }
    }

    /// A min-heap of (distance, vertex).
    private struct Heap {
        var items: [(Float, Int)] = []
        init(_ start: [(Float, Int)]) { for s in start { push(s) } }
        mutating func push(_ x: (Float, Int)) {
            items.append(x)
            var i = items.count - 1
            while i > 0 {
                let parent = (i - 1) / 2
                guard items[i].0 < items[parent].0 else { break }
                items.swapAt(i, parent)
                i = parent
            }
        }
        mutating func pop() -> (Float, Int)? {
            guard let top = items.first else { return nil }
            let last = items.removeLast()
            if !items.isEmpty {
                items[0] = last
                var i = 0
                while true {
                    let l = 2 * i + 1, r = l + 1
                    var m = i
                    if l < items.count, items[l].0 < items[m].0 { m = l }
                    if r < items.count, items[r].0 < items[m].0 { m = r }
                    if m == i { break }
                    items.swapAt(i, m)
                    i = m
                }
            }
            return top
        }
    }
}

/// The squared length of `v`.
@inline(__always) func dot2(_ v: Vec3) -> Float { dot(v, v) }
