import Foundation

// Contact manifolds of two `Geom2D`s: up to two points. Circles, capsules and segments are
// the rounded polygons of 1 and 2 vertices, so there are three cases: circle - circle,
// polygon - circle (closest feature), and polygon - polygon (separating axis on the edge
// normals of both, then the incident edge clipped against the reference edge's sides; close
// but disjoint corners go through the closest points of the two edges instead, so rounded
// corners work).

struct ContactPoint2D {
    /// World position midway between the two surfaces.
    var point: Vec2
    /// Negative when overlapping. Radii are accounted for.
    var separation: Float
    /// Identifies the feature pair, so a point can be matched to last step's for warm starting.
    var id: UInt16
}

struct Manifold2D {
    /// World unit vector from A to B.
    var normal: Vec2
    var points: [ContactPoint2D]
}

enum Narrowphase2D {
    /// The manifold of `a` (placed by `pa`) and `b`, with the points whose separation is at most
    /// `margin` (speculative points have a positive one), or nil when they are further apart.
    static func collide(_ a: Geom2D, _ pa: Pose2D, _ b: Geom2D, _ pb: Pose2D, margin: Float, slop: Float) -> Manifold2D? {
        // Work in A's frame.
        let xf = pa.inverse * pb
        let bg = b.placed(xf)
        let local: Manifold2D?
        switch (a.count, b.count) {
        case (1, 1):
            local = circles(a.verts[0], a.radius, bg.verts[0], bg.radius, margin: margin)
        case (_, 1):
            local = polygonCircle(a, bg.verts[0], bg.radius, margin: margin)
        case (1, _):
            local = polygonCircle(bg, a.verts[0], a.radius, margin: margin).map(flipped)
        default:
            local = polygons(a, bg, margin: margin, slop: slop)
        }
        guard var m = local else { return nil }
        m.normal = pa.rotation.rotate(m.normal)
        for i in m.points.indices { m.points[i].point = pa.transform(m.points[i].point) }
        return m
    }

    /// The same contact seen from the other body.
    private static func flipped(_ m: Manifold2D) -> Manifold2D {
        Manifold2D(normal: -m.normal, points: m.points)
    }

    private static func circles(_ ca: Vec2, _ ra: Float, _ cb: Vec2, _ rb: Float, margin: Float) -> Manifold2D? {
        let d = cb - ca, dist = length2(d)
        let separation = dist - ra - rb
        guard separation <= margin else { return nil }
        let n = dist > 1e-9 ? d / dist : Vec2(0, 1)
        let pa = ca + n * ra, pb = cb - n * rb
        return Manifold2D(normal: n, points: [ContactPoint2D(point: (pa + pb) * 0.5, separation: separation, id: 0)])
    }

    /// Polygon (or segment, or capsule) `p` against a circle; the normal points from `p` to the circle.
    private static func polygonCircle(_ p: Geom2D, _ c: Vec2, _ cr: Float, margin: Float) -> Manifold2D? {
        let n = p.count
        var best = -Float.infinity, edge = 0
        for i in 0..<n {
            let s = dot2(p.normals[i], c - p.verts[i])
            if s > best {
                best = s
                edge = i
            }
        }
        let radius = p.radius + cr
        guard best <= radius + margin else { return nil }
        let v1 = p.verts[edge], v2 = p.verts[(edge + 1) % n]
        let u1 = dot2(c - v1, v2 - v1), u2 = dot2(c - v2, v1 - v2)
        var normal = p.normals[edge], core = c - normal * best, separation = best - radius
        var id = UInt16(edge)
        if u1 <= 0 || u2 <= 0 {
            let v = u1 <= 0 ? v1 : v2
            let d = c - v, dist = length2(d)
            guard dist <= radius + margin else { return nil }
            if dist > 1e-9 { normal = d / dist }
            core = v
            separation = dist - radius
            id = UInt16(0x100 + (u1 <= 0 ? edge : (edge + 1) % n))
        }
        let onP = core + normal * p.radius, onC = c - normal * cr
        return Manifold2D(normal: normal, points: [ContactPoint2D(point: (onP + onC) * 0.5, separation: separation, id: id)])
    }

    /// How far B's vertices are in front of A's edge with the greatest margin: the edge and the gap.
    private static func maxSeparation(_ a: Geom2D, _ b: Geom2D) -> (edge: Int, separation: Float) {
        var best = -Float.infinity, edge = 0
        for i in 0..<a.count {
            var s = Float.infinity
            for w in b.verts { s = min(s, dot2(a.normals[i], w - a.verts[i])) }
            if s > best {
                best = s
                edge = i
            }
        }
        return (edge, best)
    }

    private static func polygons(_ a: Geom2D, _ b: Geom2D, margin: Float, slop: Float) -> Manifold2D? {
        let (edgeA, sepA) = maxSeparation(a, b), (edgeB, sepB) = maxSeparation(b, a)
        let radius = a.radius + b.radius
        guard sepA <= radius + margin, sepB <= radius + margin else { return nil }

        // The reference polygon owns the reference edge; the other one the incident edge.
        let flip = sepB > sepA + 0.1 * slop
        let (ref, inc, edge, separation) = flip ? (b, a, edgeB, sepB) : (a, b, edgeA, sepA)
        let normal = ref.normals[edge]
        var incident = 0, minDot = Float.infinity
        for j in 0..<inc.count {
            let d = dot2(normal, inc.normals[j])
            if d < minDot {
                minDot = d
                incident = j
            }
        }
        let i12 = (edge + 1) % ref.count, i22 = (incident + 1) % inc.count
        let v11 = ref.verts[edge], v12 = ref.verts[i12], v21 = inc.verts[incident], v22 = inc.verts[i22]
        let tag: UInt16 = flip ? 0x8000 : 0

        if separation > 0.1 * slop {
            // Disjoint cores: if the closest points of the two edges are corners, it is a
            // corner contact (matters for rounded shapes).
            let (s, t) = closestFractions(v11, v12, v21, v22)
            if (s == 0 || s == 1) && (t == 0 || t == 1) {
                let pr = s == 0 ? v11 : v12, pi = t == 0 ? v21 : v22
                let d = pi - pr, dist = length2(d)
                guard dist <= radius + margin else { return nil }
                let n = dist > 1e-9 ? d / dist : normal
                let onRef = pr + n * ref.radius, onInc = pi - n * inc.radius
                let id = tag | 0x4000 | UInt16(edge << 4 | incident)
                return Manifold2D(normal: flip ? -n : n,
                                  points: [ContactPoint2D(point: (onRef + onInc) * 0.5, separation: dist - radius, id: id)])
            }
        }

        // Clip the incident edge to the sides of the reference edge.
        let tangent = normalize2(v12 - v11)
        let lower1: Float = 0, upper1 = dot2(v12 - v11, tangent)
        let upper2 = dot2(v21 - v11, tangent), lower2 = dot2(v22 - v11, tangent)
        let span = upper2 - lower2
        let vLower = lower2 < lower1 && span > 1e-9 ? v22 + (v21 - v22) * ((lower1 - lower2) / span) : v22
        let vUpper = upper2 > upper1 && span > 1e-9 ? v22 + (v21 - v22) * ((upper1 - lower2) / span) : v21
        let sLower = dot2(vLower - v11, normal), sUpper = dot2(vUpper - v11, normal)
        // Midway between the surfaces.
        let pLower = vLower + normal * (0.5 * (ref.radius - inc.radius - sLower))
        let pUpper = vUpper + normal * (0.5 * (ref.radius - inc.radius - sUpper))
        var points: [ContactPoint2D] = []
        if sUpper - radius <= margin {
            points.append(ContactPoint2D(point: pUpper, separation: sUpper - radius, id: tag | UInt16(edge << 4 | incident)))
        }
        if sLower - radius <= margin {
            points.append(ContactPoint2D(point: pLower, separation: sLower - radius, id: tag | UInt16(edge << 4 | i22)))
        }
        guard !points.isEmpty else { return nil }
        return Manifold2D(normal: flip ? -normal : normal, points: points)
    }
}
