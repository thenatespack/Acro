// GJK distance between convex point sets (the cores of convex shapes), and the queries
// built on it: conservative-advancement shape casts.

struct GJKResult {
    /// Distance between the two hulls (0 when they intersect).
    var distance: Float
    /// The closest points on each hull (meaningless when they intersect).
    var pointA: Vec3
    var pointB: Vec3
}

/// The distance between the convex hulls of `a` and `b` (Gilbert–Johnson–Keerthi, with
/// Ericson's closest-point routines for the simplex). Both must be non-empty.
func gjkDistance(_ a: [Vec3], _ b: [Vec3]) -> GJKResult {
    struct Vertex {
        var a: Vec3, b: Vec3
        var w: Vec3 { a - b }
    }
    func support(_ d: Vec3) -> Vertex {
        var ia = 0, ib = 0
        var best = dot(a[0], d)
        for i in 1..<a.count {
            let v = dot(a[i], d)
            if v > best { best = v; ia = i }
        }
        best = -dot(b[0], d)
        for i in 1..<b.count {
            let v = -dot(b[i], d)
            if v > best { best = v; ib = i }
        }
        return Vertex(a: a[ia], b: b[ib])
    }

    var simplex = [Vertex(a: a[0], b: b[0])]
    var weights: [Float] = [1]
    var v = simplex[0].w
    for _ in 0..<64 {
        let vv = dot(v, v)
        if vv < 1e-14 { break }
        let s = support(-v)
        // No progress toward the origin: v is (within tolerance) the closest point.
        if vv - dot(v, s.w) <= 1e-6 * vv { break }
        if simplex.contains(where: { lengthSquared($0.w - s.w) < 1e-14 }) { break }
        let previous = (simplex, weights, v)
        simplex.append(s)
        let (closest, w, keep) = closestOnSimplex(simplex.map(\.w))
        if dot(closest, closest) >= vv {
            (simplex, weights, v) = previous
            break
        }
        simplex = keep.map { simplex[$0] }
        weights = keep.map { w[$0] }
        v = closest
        if simplex.count == 4 { v = .zero; break }
    }
    var pa = Vec3.zero, pb = Vec3.zero
    for (vertex, weight) in zip(simplex, weights) {
        pa += vertex.a * weight
        pb += vertex.b * weight
    }
    return GJKResult(distance: length(v), pointA: pa, pointB: pb)
}

/// The point of the simplex (1–4 points) closest to the origin, the barycentric weight of
/// every input point, and the indices of the points with nonzero weight.
private func closestOnSimplex(_ p: [Vec3]) -> (Vec3, [Float], [Int]) {
    switch p.count {
    case 1:
        return (p[0], [1], [0])
    case 2:
        let ab = p[1] - p[0]
        let denom = dot(ab, ab)
        let t = denom > 0 ? -dot(p[0], ab) / denom : 0
        if t <= 0 { return (p[0], [1, 0], [0]) }
        if t >= 1 { return (p[1], [0, 1], [1]) }
        return (p[0] + ab * t, [1 - t, t], [0, 1])
    case 3:
        let (point, w) = closestOnTriangle(p[0], p[1], p[2])
        return (point, w, (0..<3).filter { w[$0] > 0 })
    default:
        // Faces with the index of the opposite vertex.
        let faces = [(0, 1, 2, 3), (0, 2, 3, 1), (0, 3, 1, 2), (1, 3, 2, 0)]
        var best: (Vec3, [Float], [Int])?
        var bestDistance = Float.infinity
        var inside = true
        for (i, j, k, opposite) in faces {
            let n = cross(p[j] - p[i], p[k] - p[i])
            let signOrigin = dot(-p[i], n), signOpposite = dot(p[opposite] - p[i], n)
            // The origin is on the far side of this face (or the tetrahedron is flat).
            guard abs(signOpposite) < 1e-12 || signOrigin * signOpposite < 0 else { continue }
            inside = false
            let (point, w) = closestOnTriangle(p[i], p[j], p[k])
            let d = dot(point, point)
            if d < bestDistance {
                bestDistance = d
                var weights: [Float] = [0, 0, 0, 0]
                weights[i] = w[0]
                weights[j] = w[1]
                weights[k] = w[2]
                best = (point, weights, (0..<4).filter { weights[$0] > 0 })
            }
        }
        if inside || best == nil { return (.zero, [0.25, 0.25, 0.25, 0.25], [0, 1, 2, 3]) }
        return best!
    }
}

/// The point of triangle abc closest to the origin and its barycentric weights
/// (Ericson, Real-Time Collision Detection 5.1.5).
private func closestOnTriangle(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> (Vec3, [Float]) {
    let ab = b - a, ac = c - a, ap = -a
    let d1 = dot(ab, ap), d2 = dot(ac, ap)
    if d1 <= 0 && d2 <= 0 { return (a, [1, 0, 0]) }
    let bp = -b
    let d3 = dot(ab, bp), d4 = dot(ac, bp)
    if d3 >= 0 && d4 <= d3 { return (b, [0, 1, 0]) }
    let vc = d1 * d4 - d3 * d2
    if vc <= 0 && d1 >= 0 && d3 <= 0 {
        let v = d1 / (d1 - d3)
        return (a + ab * v, [1 - v, v, 0])
    }
    let cp = -c
    let d5 = dot(ab, cp), d6 = dot(ac, cp)
    if d6 >= 0 && d5 <= d6 { return (c, [0, 0, 1]) }
    let vb = d5 * d2 - d1 * d6
    if vb <= 0 && d2 >= 0 && d6 <= 0 {
        let w = d2 / (d2 - d6)
        return (a + ac * w, [1 - w, 0, w])
    }
    let va = d3 * d6 - d5 * d4
    if va <= 0 && d4 - d3 >= 0 && d5 - d6 >= 0 {
        let w = (d4 - d3) / ((d4 - d3) + (d5 - d6))
        return (b + (c - b) * w, [0, 1 - w, w])
    }
    let denom = 1 / (va + vb + vc)
    let v = vb * denom, w = vc * denom
    return (a + ab * v + ac * w, [1 - v - w, v, w])
}

/// Sweeps convex `moving` along `translation` until it touches `target` (conservative
/// advancement: step by the gap over the closing speed). Returns the fraction of the
/// translation, the contact point and the target's surface normal there, or nil if it never
/// touches. Shapes that overlap at the start hit at fraction 0 with the normal against the
/// motion. Stops within `tolerance` of the surface.
func castConvex(_ moving: WorldConvex, translation: Vec3, against target: WorldConvex,
                tolerance: Float = 1e-3) -> (fraction: Float, point: Vec3, normal: Vec3)? {
    let total = length(translation)
    let radii = moving.radius + target.radius
    var t: Float = 0
    for _ in 0..<40 {
        let offset = translation * t
        let r = gjkDistance(moving.points.map { $0 + offset }, target.points)
        let gap = r.distance - radii
        if gap <= tolerance {
            if r.distance < 1e-6 || t == 0 && gap < 0 {
                if t == 0 { return (0, r.pointA, total > 0 ? -translation / total : Vec3(0, 1, 0)) }
                return (t, r.pointB, -translation / max(total, 1e-9))
            }
            let n = (r.pointB - r.pointA) / r.distance
            var normal = -n
            // Face on face, the closest points' direction is only as good as float precision at
            // this tiny gap; use the target's face normal when the point is on that face.
            if let poly = target.poly {
                for f in poly.faces where dot(f.normal, normal) > 0.99 && abs(dot(f.normal, r.pointB) - f.offset) < 1e-3 {
                    normal = f.normal
                    break
                }
            }
            return (t, r.pointB - n * target.radius, normal)
        }
        guard total > 0, r.distance > 1e-9 else { return nil }
        let n = (r.pointB - r.pointA) / r.distance
        let closing = dot(translation, n)
        if closing <= 1e-9 { return nil }
        t += (gap - tolerance * 0.5) / closing
        if t > 1 { return nil }
    }
    return nil
}
