#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineAssets

// Simplifies a meshed body piece (HumanSurface) by quadric error edge collapses (Garland and
// Heckbert 1997), each vertex collapsing onto a neighbor (so its normal, occlusion, tag and
// weights come from the field, unchanged). Flat areas (cloth, the back of the head) lose most of
// their triangles; creases (lids, lips, nostrils, ears, fingers) keep theirs. Collapses that would
// flip a triangle, pinch the surface (more than two shared neighbors) or cross a tag border are
// skipped.

extension HumanSurface {
    /// Collapses edges while the cheapest collapse moves the surface less than `tolerance`
    /// (meters, about) and more than `keep` of the triangles remain.
    mutating func simplify(tolerance: Float, keep: Float = 0.15) {
        let vertexCount = positions.count
        guard vertexCount > 0, !triangles.isEmpty else { return }
        var faces = triangles.map { SIMD3<Int32>(Int32($0.x), Int32($0.y), Int32($0.z)) }
        var faceAlive = [Bool](repeating: true, count: faces.count)
        var vertexFaces = [[Int32]](repeating: [], count: vertexCount)
        for (f, t) in faces.enumerated() {
            for n in 0..<3 { vertexFaces[Int(t[n])].append(Int32(f)) }
        }
        // Quadrics: 10 floats (symmetric 4x4) per vertex from its faces' planes, area weighted.
        var quadrics = [Float](repeating: 0, count: vertexCount * 10)
        func addPlane(_ q: inout [Float], _ v: Int, _ n: Vec3, _ d: Float, _ w: Float) {
            let a = n.x, b = n.y, c = n.z
            let o = v * 10
            q[o] += w * a * a; q[o + 1] += w * a * b; q[o + 2] += w * a * c; q[o + 3] += w * a * d
            q[o + 4] += w * b * b; q[o + 5] += w * b * c; q[o + 6] += w * b * d
            q[o + 7] += w * c * c; q[o + 8] += w * c * d; q[o + 9] += w * d * d
        }
        for t in faces {
            let p0 = positions[Int(t.x)], p1 = positions[Int(t.y)], p2 = positions[Int(t.z)]
            let c = cross(p1 - p0, p2 - p0)
            let area = length(c)
            guard area > 1e-14 else { continue }
            let n = c / area
            let d = -dot(n, p0)
            for k in 0..<3 { addPlane(&quadrics, Int(t[k]), n, d, area) }
        }
        func error(_ v: Int, _ p: Vec3) -> Float {
            let o = v * 10, q = quadrics
            let x = p.x, y = p.y, z = p.z
            return q[o] * x * x + 2 * q[o + 1] * x * y + 2 * q[o + 2] * x * z + 2 * q[o + 3] * x
                + q[o + 4] * y * y + 2 * q[o + 5] * y * z + 2 * q[o + 6] * y
                + q[o + 7] * z * z + 2 * q[o + 8] * z + q[o + 9]
        }
        // Mean face area per vertex, to turn quadric error (area x distance²) into distance².
        var vertexArea = [Float](repeating: 0, count: vertexCount)
        for t in faces {
            let a = length(cross(positions[Int(t.y)] - positions[Int(t.x)], positions[Int(t.z)] - positions[Int(t.x)]))
            for k in 0..<3 { vertexArea[Int(t[k])] += a }
        }
        // Boundary vertices (open edges, e.g. a cut) stay.
        var edgeCount: [Int64: Int] = [:]
        func key(_ a: Int32, _ b: Int32) -> Int64 { Int64(min(a, b)) << 32 | Int64(max(a, b)) }
        for t in faces { for n in 0..<3 { edgeCount[key(t[n], t[(n + 1) % 3]), default: 0] += 1 } }
        var locked = [Bool](repeating: false, count: vertexCount)
        for (k, count) in edgeCount where count != 2 {
            locked[Int(k >> 32)] = true
            locked[Int(k & 0xffff_ffff)] = true
        }
        // Collapse costs: moving `from` onto `to`.
        struct Candidate { var cost: Float; var from: Int32; var to: Int32; var stamp: Int32 }
        var stamps = [Int32](repeating: 0, count: vertexCount)
        var heap: [Candidate] = []
        func push(_ c: Candidate) {
            heap.append(c)
            var i = heap.count - 1
            while i > 0 {
                let parent = (i - 1) / 2
                guard heap[parent].cost > heap[i].cost else { break }
                heap.swapAt(parent, i)
                i = parent
            }
        }
        func pop() -> Candidate? {
            guard let first = heap.first else { return nil }
            let last = heap.removeLast()
            if !heap.isEmpty {
                heap[0] = last
                var i = 0
                while true {
                    let l = 2 * i + 1, r = l + 1
                    var m = i
                    if l < heap.count && heap[l].cost < heap[m].cost { m = l }
                    if r < heap.count && heap[r].cost < heap[m].cost { m = r }
                    if m == i { break }
                    heap.swapAt(i, m)
                    i = m
                }
            }
            return first
        }
        func neighbors(_ v: Int) -> [Int32] {
            var s: [Int32] = []
            s.reserveCapacity(8)
            for f in vertexFaces[v] where faceAlive[Int(f)] {
                let t = faces[Int(f)]
                for n in 0..<3 where Int(t[n]) != v && !s.contains(t[n]) { s.append(t[n]) }
            }
            return s
        }
        func consider(_ v: Int) {
            guard !locked[v] else { return }
            var best: Candidate?
            for u in neighbors(v) where tags[Int(u)] == tags[v] {
                let p = positions[Int(u)]
                let cost = (error(v, p) + error(Int(u), p)) / max(vertexArea[v] + vertexArea[Int(u)], 1e-14)
                if best == nil || cost < best!.cost { best = Candidate(cost: cost, from: Int32(v), to: u, stamp: stamps[v]) }
            }
            if let best { push(best) }
        }
        for v in 0..<vertexCount { consider(v) }
        let limit = tolerance * tolerance
        var alive = faces.count
        let target = Int(Float(faces.count) * keep)
        while alive > target, let c = pop() {
            guard c.cost <= limit else { break }
            let v = Int(c.from), u = Int(c.to)
            guard stamps[v] == c.stamp, !locked[v] else { continue }
            // Still an edge, and the link condition: exactly two shared neighbors.
            let nv = neighbors(v), nu = neighbors(u)
            guard nv.contains(Int32(u)), nv.reduce(0, { $0 + (nu.contains($1) ? 1 : 0) }) == 2 else { stamps[v] += 1; continue }
            // No flipped or sliver triangles.
            let target = positions[u]
            var ok = true
            for f in vertexFaces[v] where faceAlive[Int(f)] {
                let t = faces[Int(f)]
                if t.x == Int32(u) || t.y == Int32(u) || t.z == Int32(u) { continue }
                var moved = [positions[Int(t.x)], positions[Int(t.y)], positions[Int(t.z)]]
                let before = cross(moved[1] - moved[0], moved[2] - moved[0])
                for k in 0..<3 where Int(t[k]) == v { moved[k] = target }
                let after = cross(moved[1] - moved[0], moved[2] - moved[0])
                let la = length(after), lb = length(before)
                if la < 1e-14 || dot(after, before) < 0.2 * la * lb { ok = false; break }
            }
            guard ok else { stamps[v] += 1; continue }
            // Collapse v onto u.
            for f in vertexFaces[v] where faceAlive[Int(f)] {
                var t = faces[Int(f)]
                if t.x == Int32(u) || t.y == Int32(u) || t.z == Int32(u) {
                    faceAlive[Int(f)] = false
                    alive -= 1
                    continue
                }
                for k in 0..<3 where Int(t[k]) == v { t[k] = Int32(u) }
                faces[Int(f)] = t
                vertexFaces[u].append(f)
            }
            vertexFaces[v] = []
            vertexFaces[u].removeAll { !faceAlive[Int($0)] }
            for k in 0..<10 { quadrics[u * 10 + k] += quadrics[v * 10 + k] }
            vertexArea[u] += vertexArea[v]
            stamps[v] += 1
            stamps[u] += 1
            consider(u)
            for w in nu where Int(w) != v {
                stamps[Int(w)] += 1
                consider(Int(w))
            }
        }
        // Compact.
        var map = [Int32](repeating: -1, count: vertexCount)
        var newPositions: [Vec3] = [], newNormals: [Vec3] = [], newOcclusion: [Float] = [], newTags: [UInt8] = [], newWeights: [[Float]] = []
        var newTriangles: [SIMD3<UInt32>] = [], newBlocks: [Int32] = []
        for (f, t) in faces.enumerated() where faceAlive[f] {
            var out = SIMD3<UInt32>(0, 0, 0)
            for k in 0..<3 {
                let v = Int(t[k])
                if map[v] < 0 {
                    map[v] = Int32(newPositions.count)
                    newPositions.append(positions[v]); newNormals.append(normals[v]); newOcclusion.append(occlusion[v])
                    newTags.append(tags[v]); newWeights.append(weights[v]); newBlocks.append(blocks[v])
                }
                out[k] = UInt32(map[v])
            }
            newTriangles.append(out)
        }
        positions = newPositions
        normals = newNormals
        occlusion = newOcclusion
        tags = newTags
        weights = newWeights
        blocks = newBlocks
        triangles = newTriangles
    }
}
