import Foundation
import EngineCore
import EngineScene

// The signed distance to a closed triangle mesh, for sculpt children without an analytic field
// (sweeps, lofts and any deformed shape; see MeshBuildSculpt.swift).
//
// - The mesh is welded by position (seams and crease splits share corners again), degenerate
//   triangles are dropped, and a bounding volume hierarchy (median splits along the longest axis,
//   up to 4 triangles a leaf) is built over the rest.
// - Distance: the nearest point on any triangle (closer child boxes first, boxes further than
//   the best so far skipped), exact.
// - Sign: from the angle-weighted pseudo-normal of the nearest feature (the face, one of its
//   edges or one of its corners; Bærentzen & Aanæs 2005), which is exact for a closed, outward
//   mesh at any distance.
// - Everything is in flat, manually allocated float buffers: the field is evaluated hundreds of
//   thousands of times per sculpt, and unoptimized builds pay dearly for arrays and SIMD types.

/// A closed triangle mesh as a signed distance function (negative inside). See the notes at the top of this file.
final class MeshDistanceField: @unchecked Sendable {
    /// Triangles: 9 corner coordinates each.
    private let corners: UnsafeMutablePointer<Float>
    /// Per triangle 7 pseudo-normals (face, corners a b c, edges ab bc ca), 3 floats each.
    private let normals: UnsafeMutablePointer<Float>
    /// Nodes: lo xyz, hi xyz, then (leaf) first triangle and count or (inner) right child and -1.
    private let nodeBoxes: UnsafeMutablePointer<Float>
    private let nodeLinks: UnsafeMutablePointer<Int32>
    let triangleCount: Int
    let nodeCount: Int
    /// The mesh's box.
    let lo: Vec3
    let hi: Vec3

    /// Nil when the mesh has no triangle with an area.
    init?(_ geometry: MeshGeometry) {
        // Weld by position (relative to the mesh's size).
        let b = geometry.bounds
        let extent = max(b.halfExtent.x, b.halfExtent.y, b.halfExtent.z, 1e-6) * 2
        let quantum = extent * 1e-6
        var ids: [SIMD3<Int64>: Int32] = [:]
        var points: [Vec3] = []
        let welded = geometry.vertices.map { v -> Int32 in
            let p = v.position
            let key = SIMD3<Int64>(Int64((p.x / quantum).rounded()), Int64((p.y / quantum).rounded()), Int64((p.z / quantum).rounded()))
            if let id = ids[key] { return id }
            ids[key] = Int32(points.count)
            points.append(p)
            return Int32(points.count - 1)
        }
        var tris: [SIMD3<Int32>] = []
        var faceNormals: [Vec3] = []
        tris.reserveCapacity(geometry.indices.count / 3)
        for t in stride(from: 0, to: geometry.indices.count - 2, by: 3) {
            let a = welded[Int(geometry.indices[t])], b = welded[Int(geometry.indices[t + 1])], c = welded[Int(geometry.indices[t + 2])]
            guard a != b, b != c, a != c else { continue }
            let n = cross(points[Int(b)] - points[Int(a)], points[Int(c)] - points[Int(a)])
            let l = length(n)
            guard l > 1e-14 else { continue }
            tris.append(SIMD3(a, b, c))
            faceNormals.append(n / l)
        }
        guard !tris.isEmpty else { return nil }

        // Pseudo-normals: corners weighted by their angle, edges the sum of their faces.
        var vertexNormals = [Vec3](repeating: .zero, count: points.count)
        var edgeNormals: [SIMD2<Int32>: Vec3] = [:]
        edgeNormals.reserveCapacity(tris.count * 3 / 2)
        for (t, tri) in tris.enumerated() {
            let n = faceNormals[t]
            for k in 0..<3 {
                let i = tri[k], j = tri[(k + 1) % 3], l = tri[(k + 2) % 3]
                let e1 = points[Int(j)] - points[Int(i)], e2 = points[Int(l)] - points[Int(i)]
                let c = dot(e1, e2) / max(length(e1) * length(e2), 1e-30)
                vertexNormals[Int(i)] += n * acosf(min(max(c, -1), 1))
                edgeNormals[SIMD2(min(i, j), max(i, j)), default: .zero] += n
            }
        }

        // The hierarchy, built over triangle order (leaves are runs of `order`).
        var order = Array(0..<tris.count)
        let centroids = tris.map { (points[Int($0.x)] + points[Int($0.y)] + points[Int($0.z)]) / 3 }
        var boxes: [(Vec3, Vec3)] = []
        var links: [SIMD2<Int32>] = []
        func boxOf(_ range: Range<Int>) -> (Vec3, Vec3) {
            var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
            for k in range {
                let t = tris[order[k]]
                for v in [t.x, t.y, t.z] {
                    lo = pointwiseMin(lo, points[Int(v)])
                    hi = pointwiseMax(hi, points[Int(v)])
                }
            }
            return (lo, hi)
        }
        func build(_ range: Range<Int>) -> Int {
            let node = boxes.count
            boxes.append(boxOf(range))
            links.append(SIMD2(Int32(range.lowerBound), Int32(range.count)))
            guard range.count > 4 else { return node }
            var clo = Vec3(repeating: .infinity), chi = Vec3(repeating: -.infinity)
            for k in range {
                clo = pointwiseMin(clo, centroids[order[k]])
                chi = pointwiseMax(chi, centroids[order[k]])
            }
            let e = chi - clo
            let axis = e.x >= e.y && e.x >= e.z ? 0 : e.y >= e.z ? 1 : 2
            order[range].sort { centroids[$0][axis] < centroids[$1][axis] }
            let mid = range.lowerBound + range.count / 2
            _ = build(range.lowerBound..<mid)  // the left child is the next node
            let right = build(mid..<range.upperBound)
            links[node] = SIMD2(Int32(right), -1)
            return node
        }
        _ = build(0..<tris.count)

        triangleCount = tris.count
        nodeCount = boxes.count
        corners = .allocate(capacity: tris.count * 9)
        normals = .allocate(capacity: tris.count * 21)
        nodeBoxes = .allocate(capacity: boxes.count * 6)
        nodeLinks = .allocate(capacity: boxes.count * 2)
        func unit(_ v: Vec3) -> Vec3 {
            let l = length(v)
            return l > 0 ? v / l : v
        }
        for (k, t) in order.enumerated() {
            let tri = tris[t]
            let feature = [faceNormals[t], vertexNormals[Int(tri.x)], vertexNormals[Int(tri.y)], vertexNormals[Int(tri.z)],
                           edgeNormals[SIMD2(min(tri.x, tri.y), max(tri.x, tri.y))] ?? faceNormals[t],
                           edgeNormals[SIMD2(min(tri.y, tri.z), max(tri.y, tri.z))] ?? faceNormals[t],
                           edgeNormals[SIMD2(min(tri.z, tri.x), max(tri.z, tri.x))] ?? faceNormals[t]].map(unit)
            for c in 0..<3 {
                let p = points[Int(tri[c])]
                corners[k * 9 + c * 3] = p.x
                corners[k * 9 + c * 3 + 1] = p.y
                corners[k * 9 + c * 3 + 2] = p.z
            }
            for (f, n) in feature.enumerated() {
                normals[k * 21 + f * 3] = n.x
                normals[k * 21 + f * 3 + 1] = n.y
                normals[k * 21 + f * 3 + 2] = n.z
            }
        }
        for (i, box) in boxes.enumerated() {
            nodeBoxes[i * 6] = box.0.x; nodeBoxes[i * 6 + 1] = box.0.y; nodeBoxes[i * 6 + 2] = box.0.z
            nodeBoxes[i * 6 + 3] = box.1.x; nodeBoxes[i * 6 + 4] = box.1.y; nodeBoxes[i * 6 + 5] = box.1.z
            nodeLinks[i * 2] = links[i].x
            nodeLinks[i * 2 + 1] = links[i].y
        }
        lo = boxes[0].0
        hi = boxes[0].1
    }

    deinit {
        corners.deallocate()
        normals.deallocate()
        nodeBoxes.deallocate()
        nodeLinks.deallocate()
    }

    /// The squared distance from the point to node `i`'s box.
    @inline(__always) private func boxDistanceSquared(_ i: Int, _ x: Float, _ y: Float, _ z: Float) -> Float {
        let b = nodeBoxes + i * 6
        let dx = max(max(b[0] - x, x - b[3]), 0), dy = max(max(b[1] - y, y - b[4]), 0), dz = max(max(b[2] - z, z - b[5]), 0)
        return dx * dx + dy * dy + dz * dz
    }

    /// The signed distance from (`x`, `y`, `z`) to the mesh (negative inside).
    func distance(_ x: Float, _ y: Float, _ z: Float) -> Float {
        var best = Float.greatestFiniteMagnitude
        var bestDX: Float = 0, bestDY: Float = 0, bestDZ: Float = 0
        var bestTriangle = 0, bestFeature = 0
        // A fixed stack: the tree's depth is about log2(triangles / 4) + 1.
        var stack: (Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32,
                    Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32,
                    Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32,
                    Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32)
            = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        return withUnsafeMutableBytes(of: &stack) { raw -> Float in
            let stack = raw.baseAddress!.assumingMemoryBound(to: Int32.self)
            var top = 0
            var node = 0
            while true {
                let first = Int(nodeLinks[node * 2]), count = Int(nodeLinks[node * 2 + 1])
                if count >= 0 {
                    for t in first..<(first + count) {
                        let (d2, dx, dy, dz, feature) = closest(t, x, y, z)
                        if d2 < best {
                            best = d2
                            (bestDX, bestDY, bestDZ) = (dx, dy, dz)
                            bestTriangle = t
                            bestFeature = feature
                        }
                    }
                } else {
                    // Visit the nearer child first; push the other if it can still hold something closer.
                    let left = node + 1, right = first
                    let dl = boxDistanceSquared(left, x, y, z), dr = boxDistanceSquared(right, x, y, z)
                    let (near, far, dn, df) = dl <= dr ? (left, right, dl, dr) : (right, left, dr, dl)
                    if dn < best {
                        if df < best, top < 64 {
                            stack[top] = Int32(far)
                            top += 1
                        }
                        node = near
                        continue
                    }
                }
                // Pop the next box that can still hold something closer.
                var next = -1
                while top > 0 {
                    top -= 1
                    let candidate = Int(stack[top])
                    if boxDistanceSquared(candidate, x, y, z) < best {
                        next = candidate
                        break
                    }
                }
                if next < 0 { break }
                node = next
            }
            let n = normals + bestTriangle * 21 + bestFeature * 3
            // (dx, dy, dz) runs from the nearest point to the query point.
            let side = bestDX * n[0] + bestDY * n[1] + bestDZ * n[2]
            let d = best.squareRoot()
            return side < 0 ? -d : d
        }
    }

    /// The squared distance from the point to triangle `t`, the offset from its nearest point to
    /// the point, and that point's feature (0 face, 1...3 corners a b c, 4...6 edges ab bc ca).
    /// Ericson, Real-Time Collision Detection, 5.1.5.
    @inline(__always) private func closest(_ t: Int, _ px: Float, _ py: Float, _ pz: Float) -> (Float, Float, Float, Float, Int) {
        let c = corners + t * 9
        let ax = c[0], ay = c[1], az = c[2]
        let abx = c[3] - ax, aby = c[4] - ay, abz = c[5] - az
        let acx = c[6] - ax, acy = c[7] - ay, acz = c[8] - az
        let apx = px - ax, apy = py - ay, apz = pz - az
        @inline(__always) func result(_ qx: Float, _ qy: Float, _ qz: Float, _ feature: Int) -> (Float, Float, Float, Float, Int) {
            let dx = px - qx, dy = py - qy, dz = pz - qz
            return (dx * dx + dy * dy + dz * dz, dx, dy, dz, feature)
        }
        let d1 = abx * apx + aby * apy + abz * apz, d2 = acx * apx + acy * apy + acz * apz
        if d1 <= 0 && d2 <= 0 { return result(ax, ay, az, 1) }
        let bpx = px - c[3], bpy = py - c[4], bpz = pz - c[5]
        let d3 = abx * bpx + aby * bpy + abz * bpz, d4 = acx * bpx + acy * bpy + acz * bpz
        if d3 >= 0 && d4 <= d3 { return result(c[3], c[4], c[5], 2) }
        let vc = d1 * d4 - d3 * d2
        if vc <= 0 && d1 >= 0 && d3 <= 0 {
            let v = d1 / (d1 - d3)
            return result(ax + abx * v, ay + aby * v, az + abz * v, 4)
        }
        let cpx = px - c[6], cpy = py - c[7], cpz = pz - c[8]
        let d5 = abx * cpx + aby * cpy + abz * cpz, d6 = acx * cpx + acy * cpy + acz * cpz
        if d6 >= 0 && d5 <= d6 { return result(c[6], c[7], c[8], 3) }
        let vb = d5 * d2 - d1 * d6
        if vb <= 0 && d2 >= 0 && d6 <= 0 {
            let w = d2 / (d2 - d6)
            return result(ax + acx * w, ay + acy * w, az + acz * w, 6)
        }
        let va = d3 * d6 - d5 * d4
        if va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0 {
            let w = (d4 - d3) / ((d4 - d3) + (d5 - d6))
            return result(c[3] + (c[6] - c[3]) * w, c[4] + (c[7] - c[4]) * w, c[5] + (c[8] - c[5]) * w, 5)
        }
        let denom = 1 / (va + vb + vc)
        let v = vb * denom, w = vc * denom
        return result(ax + abx * v + acx * w, ay + aby * v + acy * w, az + abz * v + acz * w, 0)
    }

    /// A lower bound of the distance from any point of the box `boxLo`...`boxHi` to the mesh
    /// (from the hierarchy's boxes, a few levels deep).
    func lowerBound(boxLo: Vec3, boxHi: Vec3) -> Float {
        var best = Float.greatestFiniteMagnitude
        var stack: [(Int, Int)] = [(0, 0)]
        func gap(_ i: Int) -> Float {
            let b = nodeBoxes + i * 6
            let gx = max(max(b[0] - boxHi.x, boxLo.x - b[3]), 0)
            let gy = max(max(b[1] - boxHi.y, boxLo.y - b[4]), 0)
            let gz = max(max(b[2] - boxHi.z, boxLo.z - b[5]), 0)
            return gx * gx + gy * gy + gz * gz
        }
        while let (node, depth) = stack.popLast() {
            let g = gap(node)
            guard g < best else { continue }
            if nodeLinks[node * 2 + 1] >= 0 || depth >= 12 {
                best = min(best, g)
                if best == 0 { break }
                continue
            }
            stack.append((Int(nodeLinks[node * 2]), depth + 1))
            stack.append((node + 1, depth + 1))
        }
        return best.squareRoot()
    }
}
