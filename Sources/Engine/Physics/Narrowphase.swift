// Narrowphase: contact points between two shapes. Convex shapes are a core (point, segment
// or polyhedron) plus a radius. Pairs are dispatched on that:
// - sphere/capsule vs sphere/capsule: closest points between segments (two points for
//   parallel capsules);
// - sphere/capsule vs polyhedron: GJK distance while the cores are apart, else SAT; a capsule
//   lying on a face is clipped to it for two points;
// - polyhedron vs polyhedron (boxes, hulls, mesh triangles): SAT over face normals and edge
//   pairs, then the incident face clipped against the reference face (up to four points) or
//   one point for an edge-edge contact;
// - triangle meshes: each triangle near the other shape as a flat polyhedron, the points
//   reduced to four;
// - compounds: each part against the other shape, the points reduced to four.

/// One contact point, in world space. `normal` points from shape A to shape B.
struct ContactPoint {
    /// On A's surface.
    var pointA: Vec3
    /// On B's surface.
    var pointB: Vec3
    var normal: Vec3
    /// Distance along the normal between the surfaces; negative when they overlap.
    var separation: Float

    var flipped: ContactPoint { ContactPoint(pointA: pointB, pointB: pointA, normal: -normal, separation: separation) }
}

/// A convex shape placed in the world.
struct WorldConvex {
    var points: [Vec3]
    var radius: Float
    /// The polyhedron whose vertices are `points`, for boxes, hulls and triangles.
    var poly: ConvexPolyhedron?

    init(points: [Vec3], radius: Float, poly: ConvexPolyhedron? = nil) {
        self.points = points
        self.radius = radius
        self.poly = poly
    }

    /// Nil for meshes.
    init?(_ shape: Shape, _ pose: Pose) {
        switch shape.kind {
        case .sphere:
            self.init(points: [pose.position], radius: shape.radius)
        case .capsule(let h):
            self.init(points: [pose.transform(Vec3(0, -h, 0)), pose.transform(Vec3(0, h, 0))], radius: shape.radius)
        case .polyhedron(let p):
            let world = p.transformed(by: pose)
            self.init(points: world.vertices, radius: 0, poly: world)
        case .mesh, .compound:
            return nil
        }
    }

    static func triangle(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> WorldConvex {
        WorldConvex(points: [a, b, c], radius: 0, poly: .triangle(a, b, c))
    }
}

enum Narrowphase {
    /// Points closer than `margin` count (speculative contacts); a pair further apart gives none.
    static func collide(_ a: Shape, _ poseA: Pose, _ b: Shape, _ poseB: Pose, margin: Float) -> [ContactPoint] {
        switch (a.kind, b.kind) {
        case (.compound(let parts), _):
            // Each part against the other shape; the union reduced to a four point manifold.
            var points: [ContactPoint] = []
            for part in parts { points += collide(part.shape, poseA * part.pose, b, poseB, margin: margin) }
            return reduce(points)
        case (_, .compound(let parts)):
            var points: [ContactPoint] = []
            for part in parts { points += collide(a, poseA, part.shape, poseB * part.pose, margin: margin) }
            return reduce(points)
        case (.mesh, .mesh):
            return []
        case (.mesh(let mesh), _):
            return collide(mesh: mesh, poseA, WorldConvex(b, poseB)!, margin: margin)
        case (_, .mesh(let mesh)):
            return collide(mesh: mesh, poseB, WorldConvex(a, poseA)!, margin: margin).map(\.flipped)
        default:
            return collide(WorldConvex(a, poseA)!, WorldConvex(b, poseB)!, margin: margin)
        }
    }

    static func collide(_ a: WorldConvex, _ b: WorldConvex, margin: Float) -> [ContactPoint] {
        switch (a.poly, b.poly) {
        case (nil, nil): return roundedVsRounded(a, b, margin: margin)
        case (nil, let p?): return roundedVsPoly(a, p, margin: margin)
        case (let p?, nil): return roundedVsPoly(b, p, margin: margin).map(\.flipped)
        case (let p?, let q?): return polyVsPoly(p, q, margin: margin)
        }
    }

    /// Mesh (A) against a convex shape (B).
    static func collide(mesh: TriangleMesh, _ pose: Pose, _ convex: WorldConvex, margin: Float) -> [ContactPoint] {
        let box = AABB(enclosing: convex.points).expanded(by: convex.radius + margin)
        var points: [ContactPoint] = []
        mesh.forEachTriangle(overlapping: localBounds(box, in: pose)) { i in
            let (a, b, c) = mesh.triangle(i)
            let corners = [pose.transform(a), pose.transform(b), pose.transform(c)]
            let tri = WorldConvex.triangle(corners[0], corners[1], corners[2])
            for p in collide(tri, convex, margin: margin) {
                points.append(smoothInternalEdge(p, mesh: mesh, pose: pose, triangle: i, corners: corners, convex))
            }
        }
        return reduce(points)
    }

    /// A shape sliding over a flat mesh touches the edges between triangles, and their edge
    /// normals would bump it. A point on an edge that isn't convex (the neighbor across it is
    /// level or rises) gets the triangle's face normal instead, with the depth along it.
    private static func smoothInternalEdge(_ p: ContactPoint, mesh: TriangleMesh, pose: Pose, triangle: Int,
                                           corners: [Vec3], _ convex: WorldConvex) -> ContactPoint {
        var face = normalize(cross(corners[1] - corners[0], corners[2] - corners[0]))
        if dot(face, p.normal) < 0 { face = -face }
        guard dot(face, p.normal) < 0.9999 else { return p }
        let scale = max(length(corners[1] - corners[0]), length(corners[2] - corners[0]), 1e-3)
        var onEdge = false
        for k in 0..<3 {
            let e0 = corners[k], e1 = corners[(k + 1) % 3]
            guard lengthSquared(closestPointOnSegment(p.pointA, e0, e1) - p.pointA) < (1e-4 * scale) * (1e-4 * scale) else { continue }
            onEdge = true
            let neighbor = mesh.edgeNeighbors[triangle * 3 + k]
            // A boundary or convex edge keeps its normal.
            if neighbor < 0 || dot(pose.transform(mesh.vertices[neighbor]) - e0, face) < -1e-3 * scale { return p }
        }
        guard onEdge else { return p }
        var lowest = convex.points[0]
        for q in convex.points where dot(q, face) < dot(lowest, face) { lowest = q }
        let pointB = lowest - face * convex.radius
        let separation = dot(pointB - corners[0], face)
        return ContactPoint(pointA: pointB - face * separation, pointB: pointB, normal: face, separation: separation)
    }

    /// A world box expressed as a box in `pose`'s local space.
    static func localBounds(_ box: AABB, in pose: Pose) -> AABB {
        let inverse = pose.inverse
        let m = Mat3(inverse.rotation)
        let c = inverse.transform(box.center)
        let e = m.transformExtent(box.halfExtent)
        return AABB(min: c - e, max: c + e)
    }

    // MARK: - Rounded shapes

    private static func roundedVsRounded(_ a: WorldConvex, _ b: WorldConvex, margin: Float) -> [ContactPoint] {
        let a0 = a.points[0], a1 = a.points[a.points.count - 1]
        let b0 = b.points[0], b1 = b.points[b.points.count - 1]
        let (pa, pb) = closestPointsBetweenSegments(a0, a1, b0, b1)
        let d = length(pb - pa)
        let radii = a.radius + b.radius
        if d > radii + margin { return [] }
        var n = Vec3(0, 1, 0)
        if d > 1e-6 {
            n = (pb - pa) / d
        } else if a.points.count == 2 {
            n = tangentBasis(normalize(a1 - a0)).0
        }
        // Parallel capsules side by side: one point at each end of the overlap.
        if a.points.count == 2 && b.points.count == 2 && d > 1e-6 {
            let da = a1 - a0, db = b1 - b0
            let la = dot(da, da)
            if la > 1e-10 && abs(dot(normalize(da), normalize(db))) > 0.98 {
                let t0 = dot(b0 - a0, da) / la, t1 = dot(b1 - a0, da) / la
                let lo = max(min(t0, t1), 0), hi = min(max(t0, t1), 1)
                if (hi - lo) * la.squareRoot() > 0.01 {
                    var points: [ContactPoint] = []
                    for t in [lo, hi] {
                        let qa = a0 + da * t, qb = closestPointOnSegment(qa, b0, b1)
                        let dd = length(qb - qa)
                        let nn = dd > 1e-6 ? (qb - qa) / dd : n
                        if dd - radii <= margin {
                            points.append(ContactPoint(pointA: qa + nn * a.radius, pointB: qb - nn * b.radius, normal: nn, separation: dd - radii))
                        }
                    }
                    if points.count == 2 { return points }
                }
            }
        }
        return [ContactPoint(pointA: pa + n * a.radius, pointB: pb - n * b.radius, normal: n, separation: d - radii)]
    }

    /// A sphere or capsule (A) against a polyhedron (B).
    private static func roundedVsPoly(_ s: WorldConvex, _ p: ConvexPolyhedron, margin: Float) -> [ContactPoint] {
        let r = s.radius
        let gjk = gjkDistance(s.points, p.vertices)
        if gjk.distance > r + margin { return [] }
        let isSegment = s.points.count == 2

        if gjk.distance > 1e-4 {
            let n = (gjk.pointB - gjk.pointA) / gjk.distance
            if isSegment {
                // A capsule lying on a face: clip its segment to the face for two points.
                var face = 0
                var best = -Float.infinity
                for (i, f) in p.faces.enumerated() where dot(f.normal, -n) > best {
                    best = dot(f.normal, -n)
                    face = i
                }
                let f = p.faces[face]
                let axis = normalize(s.points[1] - s.points[0])
                if best > 0.98 && abs(dot(axis, f.normal)) < 0.2 {
                    let clipped = clipSegment(s.points[0], s.points[1], to: f, of: p)
                    if clipped.count == 2 {
                        let points = clipped.compactMap { q -> ContactPoint? in
                            let height = dot(q, f.normal) - f.offset
                            guard height - r <= margin else { return nil }
                            return ContactPoint(pointA: q - f.normal * r, pointB: q - f.normal * height, normal: -f.normal, separation: height - r)
                        }
                        if !points.isEmpty { return points }
                    }
                }
            }
            return [ContactPoint(pointA: gjk.pointA + n * r, pointB: gjk.pointB, normal: n, separation: gjk.distance - r)]
        }

        // The core is inside the polyhedron: the axis of least penetration (SAT).
        var bestFace = 0
        var faceSeparation = -Float.infinity
        for (i, f) in p.faces.enumerated() {
            let lowest = s.points.map { dot(f.normal, $0) }.min()!
            let separation = lowest - r - f.offset
            if separation > faceSeparation {
                faceSeparation = separation
                bestFace = i
            }
        }
        if isSegment {
            let axis = s.points[1] - s.points[0]
            var edgeBest: (separation: Float, normal: Vec3, direction: Int)?
            for (j, e) in p.edgeDirections.enumerated() {
                var n = cross(axis, e)
                let len = length(n)
                if len < 1e-5 { continue }
                n /= len
                let (sMin, sMax) = project(s.points, n)
                let (pMin, pMax) = project(p.vertices, n)
                let forward = pMin - (sMax + r), backward = (sMin - r) - pMax
                let candidate = forward >= backward ? (forward, n) : (backward, -n)
                if edgeBest == nil || candidate.0 > edgeBest!.separation { edgeBest = (candidate.0, candidate.1, j) }
            }
            if let e = edgeBest, e.separation > 0.95 * faceSeparation + 0.005 {
                let n = e.normal  // from the capsule to the polyhedron
                var best: (Vec3, Vec3)?
                var lowest = Float.infinity
                for edge in p.edges where edge.direction == e.direction {
                    let h = dot(n, p.vertices[edge.a])
                    if h < lowest {
                        lowest = h
                        best = (p.vertices[edge.a], p.vertices[edge.b])
                    }
                }
                if let (e0, e1) = best {
                    let (q, onEdge) = closestPointsBetweenSegments(s.points[0], s.points[1], e0, e1)
                    return [ContactPoint(pointA: q + n * r, pointB: onEdge, normal: n, separation: dot(onEdge - q, n) - r)]
                }
            }
        }
        let f = p.faces[bestFace]
        var cores = s.points
        if isSegment {
            let clipped = clipSegment(s.points[0], s.points[1], to: f, of: p)
            if !clipped.isEmpty { cores = clipped }
        }
        return cores.map { q in
            let height = dot(q, f.normal) - f.offset
            return ContactPoint(pointA: q - f.normal * r, pointB: q - f.normal * height, normal: -f.normal, separation: height - r)
        }
    }

    // MARK: - Polyhedra

    private static func polyVsPoly(_ a: ConvexPolyhedron, _ b: ConvexPolyhedron, margin: Float) -> [ContactPoint] {
        let (faceA, separationA) = bestFace(a, against: b)
        if separationA > margin { return [] }
        let (faceB, separationB) = bestFace(b, against: a)
        if separationB > margin { return [] }

        var edge: (separation: Float, normal: Vec3, i: Int, j: Int)?
        for (i, ea) in a.edgeDirections.enumerated() {
            for (j, eb) in b.edgeDirections.enumerated() {
                var n = cross(ea, eb)
                let len = length(n)
                if len < 1e-4 { continue }
                n /= len
                let (aMin, aMax) = project(a.vertices, n)
                let (bMin, bMax) = project(b.vertices, n)
                let forward = bMin - aMax, backward = aMin - bMax
                let candidate = forward >= backward ? (forward, n) : (backward, -n)
                if candidate.0 > margin { return [] }
                if edge == nil || candidate.0 > edge!.separation { edge = (candidate.0, candidate.1, i, j) }
            }
        }

        // Prefer face contacts (stable manifolds), and A's face over B's, unless clearly worse.
        let faceSeparation = max(separationA, separationB)
        if let e = edge, e.separation > 0.95 * faceSeparation + 0.005 {
            return [edgeContact(a, b, e.normal, e.i, e.j)]
        }
        if separationB > 0.95 * separationA + 0.005 {
            return faceContact(reference: b, faceB, incident: a, margin: margin).map(\.flipped)
        }
        return faceContact(reference: a, faceA, incident: b, margin: margin)
    }

    /// The face of `p` along whose normal `other` is furthest out, and that separation.
    private static func bestFace(_ p: ConvexPolyhedron, against other: ConvexPolyhedron) -> (Int, Float) {
        var best = 0
        var separation = -Float.infinity
        for (i, f) in p.faces.enumerated() {
            let s = project(other.vertices, f.normal).0 - f.offset
            if s > separation {
                separation = s
                best = i
            }
        }
        return (best, separation)
    }

    /// Points for a face of `reference` against `incident`, normal from reference to incident.
    private static func faceContact(reference: ConvexPolyhedron, _ faceIndex: Int, incident: ConvexPolyhedron,
                                    margin: Float) -> [ContactPoint] {
        let face = reference.faces[faceIndex]
        let n = face.normal
        // The incident face: the one most opposed to the reference normal.
        var incidentFace = 0
        var lowest = Float.infinity
        for (i, f) in incident.faces.enumerated() where dot(f.normal, n) < lowest {
            lowest = dot(f.normal, n)
            incidentFace = i
        }
        var polygon = incident.faces[incidentFace].indices.map { incident.vertices[$0] }
        let count = face.indices.count
        for k in 0..<count {
            let v0 = reference.vertices[face.indices[k]], v1 = reference.vertices[face.indices[(k + 1) % count]]
            let side = normalize(cross(v1 - v0, n))
            // A little slack, so equal faces (a stack of equal boxes) keep the incident corners
            // instead of trading them for clipped points from step to step.
            polygon = clip(polygon, normal: side, offset: dot(side, v0) + 0.002)
            if polygon.isEmpty { break }
        }
        var points: [ContactPoint] = []
        for q in polygon {
            let s = dot(n, q) - face.offset
            if s <= margin { points.append(ContactPoint(pointA: q - n * s, pointB: q, normal: n, separation: s)) }
        }
        return reduce(points)
    }

    private static func edgeContact(_ a: ConvexPolyhedron, _ b: ConvexPolyhedron, _ n: Vec3, _ i: Int, _ j: Int) -> ContactPoint {
        func extreme(_ p: ConvexPolyhedron, _ direction: Int, _ sign: Float) -> (Vec3, Vec3) {
            var best = p.edges[0]
            var value = -Float.infinity
            for e in p.edges where e.direction == direction {
                let h = sign * dot(n, p.vertices[e.a])
                if h > value {
                    value = h
                    best = e
                }
            }
            return (p.vertices[best.a], p.vertices[best.b])
        }
        let (a0, a1) = extreme(a, i, 1), (b0, b1) = extreme(b, j, -1)
        let (pa, pb) = closestPointsBetweenSegments(a0, a1, b0, b1)
        return ContactPoint(pointA: pa, pointB: pb, normal: n, separation: dot(pb - pa, n))
    }

    // MARK: - Helpers

    private static func project(_ points: [Vec3], _ axis: Vec3) -> (Float, Float) {
        var lo = Float.infinity, hi = -Float.infinity
        for p in points {
            let d = dot(p, axis)
            lo = min(lo, d)
            hi = max(hi, d)
        }
        return (lo, hi)
    }

    /// Sutherland–Hodgman: the part of `polygon` with `dot(normal, p) <= offset`.
    private static func clip(_ polygon: [Vec3], normal: Vec3, offset: Float) -> [Vec3] {
        var out: [Vec3] = []
        out.reserveCapacity(polygon.count + 2)
        for k in 0..<polygon.count {
            let p = polygon[k], q = polygon[(k + 1) % polygon.count]
            let dp = dot(normal, p) - offset, dq = dot(normal, q) - offset
            if dp <= 0 { out.append(p) }
            if (dp < 0 && dq > 0) || (dp > 0 && dq < 0) { out.append(p + (q - p) * (dp / (dp - dq))) }
        }
        return out
    }

    /// The part of segment `p q` inside the prism over face `f` (empty if none).
    private static func clipSegment(_ p: Vec3, _ q: Vec3, to f: ConvexPolyhedron.Face, of poly: ConvexPolyhedron) -> [Vec3] {
        var p = p, q = q
        let count = f.indices.count
        for k in 0..<count {
            let v0 = poly.vertices[f.indices[k]], v1 = poly.vertices[f.indices[(k + 1) % count]]
            let side = normalize(cross(v1 - v0, f.normal))
            let offset = dot(side, v0)
            let dp = dot(side, p) - offset, dq = dot(side, q) - offset
            if dp > 0 && dq > 0 { return [] }
            if dp > 0 { p = p + (q - p) * (dp / (dp - dq)) } else if dq > 0 { q = q + (p - q) * (dq / (dq - dp)) }
        }
        return lengthSquared(q - p) < 1e-12 ? [p] : [p, q]
    }

    /// At most four points spanning the largest area: the extreme one along a fixed tangent,
    /// the one furthest from it, then the two adding the most area. Chosen by position, not
    /// depth, so the choice doesn't flicker as depths change slightly.
    static func reduce(_ points: [ContactPoint]) -> [ContactPoint] {
        guard points.count > 4 else { return points }
        var chosen: [Int] = []
        let (axis, _) = tangentBasis(points[0].normal)
        var first = 0
        for i in points.indices where dot(points[i].pointB, axis) > dot(points[first].pointB, axis) { first = i }
        chosen.append(first)
        func position(_ i: Int) -> Vec3 { points[i].pointB }
        func argmax(_ score: (Int) -> Float) -> Int {
            var best = -1
            var value = -Float.infinity
            for i in points.indices where !chosen.contains(i) {
                let s = score(i)
                if s > value {
                    value = s
                    best = i
                }
            }
            return best
        }
        chosen.append(argmax { lengthSquared(position($0) - position(first)) })
        let p0 = position(chosen[0]), p1 = position(chosen[1])
        chosen.append(argmax { lengthSquared(cross(p1 - p0, position($0) - p0)) })
        let p2 = position(chosen[2])
        chosen.append(argmax { i in
            let q = position(i)
            return max(lengthSquared(cross(p1 - p0, q - p0)), lengthSquared(cross(p2 - p1, q - p1)), lengthSquared(cross(p0 - p2, q - p2)))
        })
        return chosen.sorted().map { points[$0] }
    }
}
