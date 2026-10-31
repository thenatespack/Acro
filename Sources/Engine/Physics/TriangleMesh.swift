/// Triangles for static collision geometry, with a bounding volume hierarchy over them for
/// box and ray queries. Built once (median splits along the longest axis); immutable.
final class TriangleMesh: @unchecked Sendable {
    let vertices: [Vec3]
    /// Three vertex indices per triangle.
    let indices: [UInt32]
    let bounds: AABB

    private struct Node {
        var bounds: AABB
        /// Children for an inner node; `first` and `count` into `order` for a leaf.
        var left = -1, right = -1
        var first = 0, count = 0
    }

    private var nodes: [Node] = []
    /// Triangle indices, grouped by leaf.
    private var order: [Int] = []
    /// Per triangle edge (vertex k to k + 1): the vertex of the neighboring triangle across it
    /// that isn't on the edge, or -1 for a boundary edge.
    private(set) var edgeNeighbors: [Int] = []

    var triangleCount: Int { indices.count / 3 }

    init(vertices: [Vec3], indices: [UInt32]) {
        self.vertices = vertices
        let count = indices.count / 3 * 3
        self.indices = (0..<count).allSatisfy { Int(indices[$0]) < vertices.count } ? Array(indices.prefix(count)) : []
        bounds = AABB(enclosing: vertices)
        order = Array(0..<(self.indices.count / 3))
        edgeNeighbors = Self.findNeighbors(vertices, self.indices)
        if !order.isEmpty {
            let boxes = order.map { triangleBounds($0) }
            _ = build(0, order.count, boxes)
        }
    }

    /// Matches each edge with the triangle sharing it (vertices welded by position). The
    /// dictionaries are only used for lookups, so the result doesn't depend on hashing.
    private static func findNeighbors(_ vertices: [Vec3], _ indices: [UInt32]) -> [Int] {
        var welded: [SIMD3<UInt32>: Int] = [:]
        let weld = vertices.indices.map { i -> Int in
            let key = SIMD3<UInt32>(vertices[i].x.bitPattern, vertices[i].y.bitPattern, vertices[i].z.bitPattern)
            if let first = welded[key] { return first }
            welded[key] = i
            return i
        }
        var edges: [SIMD2<Int>: (triangle: Int, edge: Int)] = [:]
        var neighbors = [Int](repeating: -1, count: indices.count)
        for t in 0..<(indices.count / 3) {
            for k in 0..<3 {
                let a = weld[Int(indices[t * 3 + k])], b = weld[Int(indices[t * 3 + (k + 1) % 3])]
                let key = SIMD2(min(a, b), max(a, b))
                if let other = edges[key] {
                    neighbors[t * 3 + k] = Int(indices[t * 3 + (k + 2) % 3])
                    neighbors[other.triangle * 3 + other.edge] = Int(indices[other.triangle * 3 + (other.edge + 2) % 3])
                } else {
                    edges[key] = (t, k)
                }
            }
        }
        return neighbors
    }

    func triangle(_ i: Int) -> (Vec3, Vec3, Vec3) {
        (vertices[Int(indices[i * 3])], vertices[Int(indices[i * 3 + 1])], vertices[Int(indices[i * 3 + 2])])
    }

    private func triangleBounds(_ i: Int) -> AABB {
        let (a, b, c) = triangle(i)
        return AABB(min: pointwiseMin(a, pointwiseMin(b, c)), max: pointwiseMax(a, pointwiseMax(b, c)))
    }

    private func build(_ start: Int, _ end: Int, _ boxes: [AABB]) -> Int {
        var box = boxes[order[start]]
        for i in (start + 1)..<end { box = box.union(boxes[order[i]]) }
        let index = nodes.count
        nodes.append(Node(bounds: box))
        if end - start <= 4 {
            nodes[index].first = start
            nodes[index].count = end - start
            return index
        }
        let extent = box.max - box.min
        let axis = extent.x > extent.y && extent.x > extent.z ? 0 : (extent.y > extent.z ? 1 : 2)
        // Ties broken by triangle index so the tree doesn't depend on sort stability.
        order[start..<end].sort { a, b in
            let ca = boxes[a].center[axis], cb = boxes[b].center[axis]
            return ca != cb ? ca < cb : a < b
        }
        let mid = (start + end) / 2
        let left = build(start, mid, boxes)
        let right = build(mid, end, boxes)
        nodes[index].left = left
        nodes[index].right = right
        return index
    }

    /// Calls `body` with each triangle whose bounds overlap `box`, in a fixed order.
    func forEachTriangle(overlapping box: AABB, _ body: (Int) -> Void) {
        guard !nodes.isEmpty else { return }
        var stack = [0]
        while let n = stack.popLast() {
            let node = nodes[n]
            guard node.bounds.overlaps(box) else { continue }
            if node.left < 0 {
                for i in node.first..<(node.first + node.count) where triangleBounds(order[i]).overlaps(box) { body(order[i]) }
            } else {
                stack.append(node.right)
                stack.append(node.left)
            }
        }
    }

    /// The nearest triangle hit by `origin + t * direction` for t in [0, maxT] (both sides).
    func raycast(origin: Vec3, direction: Vec3, maxT: Float) -> (t: Float, normal: Vec3, triangle: Int)? {
        guard !nodes.isEmpty else { return nil }
        let inv = Vec3(1, 1, 1) / direction
        var best: (t: Float, normal: Vec3, triangle: Int)?
        var limit = maxT
        var stack = [0]
        while let n = stack.popLast() {
            let node = nodes[n]
            guard node.bounds.raycast(origin: origin, inverseDirection: inv, maxT: limit) != nil else { continue }
            if node.left < 0 {
                for i in node.first..<(node.first + node.count) {
                    let tri = order[i]
                    let (a, b, c) = triangle(tri)
                    if let t = Self.rayTriangle(origin, direction, a, b, c), t <= limit,
                       best == nil || t < best!.t || (t == best!.t && tri < best!.triangle) {
                        var normal = normalize(cross(b - a, c - a))
                        if dot(normal, direction) > 0 { normal = -normal }
                        best = (t, normal, tri)
                        limit = t
                    }
                }
            } else {
                stack.append(node.right)
                stack.append(node.left)
            }
        }
        return best
    }

    /// Möller–Trumbore, two-sided.
    static func rayTriangle(_ o: Vec3, _ d: Vec3, _ a: Vec3, _ b: Vec3, _ c: Vec3) -> Float? {
        let e1 = b - a, e2 = c - a
        let p = cross(d, e2)
        let det = dot(e1, p)
        if abs(det) < 1e-12 { return nil }
        let inv = 1 / det
        let s = o - a
        let u = dot(s, p) * inv
        if u < 0 || u > 1 { return nil }
        let q = cross(s, e1)
        let v = dot(d, q) * inv
        if v < 0 || u + v > 1 { return nil }
        let t = dot(e2, q) * inv
        return t >= 0 ? t : nil
    }
}
