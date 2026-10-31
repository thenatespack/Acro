import Foundation

// Collision shapes of the 2D physics. `ColliderShape2D` is the (Codable) description; a body
// turns it into `Geom2D`s: convex rounded polygons placed in the body's frame. Everything the
// narrowphase and the queries handle is one of three cases of a `Geom2D`: a circle (1 vertex),
// a segment or capsule (2 vertices, radius 0 or more) and a convex polygon (3...8 vertices).

/// What a 2D collider is shaped like. Lengths are meters; the shape is placed in the body's
/// frame by the collider's offset and rotation.
public enum ColliderShape2D: Codable, Equatable, Sendable {
    case circle(radius: Float)
    /// A box centered on the origin (rotate it with the collider's rotation for an oriented box).
    case box(halfExtents: Vec2)
    /// The convex hull of `points`; at most 8 hull vertices (the least significant are dropped).
    case polygon(points: [Vec2])
    /// A segment along the local y axis of length `2 * halfHeight`, swollen by `radius`.
    case capsule(radius: Float, halfHeight: Float)
    /// A line segment (no thickness, no mass): terrain and walls, always static in practice.
    case edge(from: Vec2, to: Vec2)
    /// Connected segments (terrain). Collides from both sides; `isLoop` closes it.
    case chain(points: [Vec2], isLoop: Bool)

    /// A box of `halfExtents` centered on the origin.
    public static func box(_ halfExtents: Vec2) -> ColliderShape2D { .box(halfExtents: halfExtents) }
}

/// A convex polygon with an optional radius, in the body's frame. A circle has one vertex, a
/// segment or capsule two (its normals are the two sides of the segment).
struct Geom2D {
    static let maxVertices = 8

    var verts: [Vec2]
    /// Outward normal of edge i (from vertex i to i + 1, counter-clockwise).
    var normals: [Vec2]
    var radius: Float

    var count: Int { verts.count }

    init(verts: [Vec2], radius: Float) {
        self.verts = verts
        self.radius = radius
        normals = []
        let n = verts.count
        if n >= 2 {
            normals = (0..<n).map { rightPerp(normalize2(verts[($0 + 1) % n] - verts[$0])) }
        }
    }

    static func circle(_ center: Vec2, _ radius: Float) -> Geom2D { Geom2D(verts: [center], radius: radius) }

    /// A copy placed by `pose`.
    func placed(_ pose: Pose2D) -> Geom2D {
        var g = self
        g.verts = verts.map(pose.transform)
        g.normals = normals.map(pose.rotation.rotate)
        return g
    }

    /// The tight box of the geom in the frame `pose` maps it into.
    func bounds(at pose: Pose2D) -> AABB2 {
        var lo = Vec2(repeating: .infinity), hi = Vec2(repeating: -.infinity)
        for v in verts {
            let p = pose.transform(v)
            lo = Vec2(min(lo.x, p.x), min(lo.y, p.y))
            hi = Vec2(max(hi.x, p.x), max(hi.y, p.y))
        }
        return AABB2(min: lo - Vec2(repeating: radius), max: hi + Vec2(repeating: radius))
    }

    /// The largest distance of the surface from the body's origin.
    var extent: Float { (verts.map(length2).max() ?? 0) + radius }

    /// How far the surface reaches along `dir` (a unit vector) in the geom's frame.
    func support(_ dir: Vec2) -> Float { (verts.map { dot2($0, dir) }.max() ?? 0) + radius }

    /// Signed distance from `p` to the core (without `radius`): negative inside a polygon;
    /// with the closest point and the direction from it to `p`.
    func distance(to p: Vec2) -> (distance: Float, closest: Vec2, normal: Vec2) {
        let n = verts.count
        if n == 1 {
            let d = p - verts[0], l = length2(d)
            return (l, verts[0], l > 1e-9 ? d / l : Vec2(0, 1))
        }
        if n >= 3 {
            var best = -Float.infinity, edge = 0
            for i in 0..<n {
                let s = dot2(normals[i], p - verts[i])
                if s > best {
                    best = s
                    edge = i
                }
            }
            if best <= 0 { return (best, p - normals[edge] * best, normals[edge]) }
        }
        var bestDistance = Float.infinity
        var closest = verts[0], normal = Vec2(0, 1)
        for i in 0..<(n == 2 ? 1 : n) {
            let a = verts[i], b = verts[(i + 1) % n]
            let e = b - a, l2 = lengthSquared2(e)
            let t = l2 > 1e-12 ? min(max(dot2(p - a, e) / l2, 0), 1) : 0
            let q = a + e * t
            let d = length2(p - q)
            if d < bestDistance {
                bestDistance = d
                closest = q
                normal = d > 1e-9 ? (p - q) / d : normals[i]
            }
        }
        return (bestDistance, closest, normal)
    }

    /// The first entry of the ray `o + t d` (`d` a unit vector) into the geom grown by `extra`,
    /// for t in [0, maxT]: its distance and surface normal. A ray starting inside hits at 0.
    func castRay(origin o: Vec2, direction d: Vec2, maxT: Float, extra: Float = 0) -> (t: Float, normal: Vec2)? {
        let r = radius + extra
        if distance(to: o).distance <= r { return (0, -d) }
        var best = maxT, normal = Vec2.zero, hit = false
        func circle(_ c: Vec2) {
            let m = o - c, b = dot2(m, d), cc = lengthSquared2(m) - r * r
            guard cc <= 0 || b <= 0 else { return }
            let disc = b * b - cc
            guard disc >= 0 else { return }
            let t = -b - disc.squareRoot()
            if t >= 0 && (t < best || (!hit && t <= best)) {
                best = t
                normal = normalize2(o + d * t - c)
                hit = true
            }
        }
        if verts.count == 1 {
            if r > 0 { circle(verts[0]) }
            return hit ? (best, normal) : nil
        }
        let n = verts.count
        for i in 0..<n {
            let nrm = normals[i]
            guard dot2(d, nrm) < 0 else { continue }
            let a = verts[i] + nrm * r, e = verts[(i + 1) % n] - verts[i]
            let denom = cross2(d, e)
            guard abs(denom) > 1e-12 else { continue }
            let t = cross2(a - o, e) / denom, u = cross2(a - o, d) / denom
            if u >= 0 && u <= 1 && t >= 0 && (t < best || (t <= best && !hit)) {
                best = t
                normal = nrm
                hit = true
            }
        }
        if r > 0 { for v in verts { circle(v) } }
        return hit ? (best, normal) : nil
    }

    /// Mass, center and rotational inertia about the center, for `density` (kg/m²).
    func massData(density: Float) -> (mass: Float, center: Vec2, inertia: Float) {
        switch verts.count {
        case 1:
            let m = density * .pi * radius * radius
            return (m, verts[0], 0.5 * m * radius * radius)
        case 2:
            guard radius > 0 else { return (0, (verts[0] + verts[1]) * 0.5, 0) }
            let length = length2(verts[1] - verts[0])
            let boxMass = density * 2 * radius * length, circleMass = density * .pi * radius * radius
            let h = 0.5 * length, lc = 4 * radius / (3 * .pi)
            let circleInertia = circleMass * (0.5 * radius * radius + h * h + 2 * h * lc)
            let boxInertia = boxMass * (4 * radius * radius + length * length) / 12
            return (boxMass + circleMass, (verts[0] + verts[1]) * 0.5, circleInertia + boxInertia)
        default:
            let origin = verts[0]
            var area: Float = 0, center = Vec2.zero, inertia: Float = 0
            for i in 1..<(verts.count - 1) {
                let e1 = verts[i] - origin, e2 = verts[i + 1] - origin
                let d = cross2(e1, e2), triangle = 0.5 * d
                area += triangle
                center += (e1 + e2) * (triangle / 3)
                let intx2 = e1.x * e1.x + e2.x * e1.x + e2.x * e2.x
                let inty2 = e1.y * e1.y + e2.y * e1.y + e2.y * e2.y
                inertia += (0.25 / 3) * d * (intx2 + inty2)
            }
            guard area > 1e-9 else { return (0, origin, 0) }
            center /= area
            let mass = density * area
            return (mass, origin + center, density * inertia - mass * dot2(center, center))
        }
    }
}

extension ColliderShape2D {
    /// The geoms of the shape placed by `offset` in the body's frame (a chain makes one per segment).
    func geoms(offset: Pose2D) -> [Geom2D] {
        let base: [Geom2D]
        switch self {
        case .circle(let r):
            base = [.circle(.zero, max(r, 0))]
        case .box(let h):
            let x = abs(h.x), y = abs(h.y)
            base = [Geom2D(verts: [Vec2(-x, -y), Vec2(x, -y), Vec2(x, y), Vec2(-x, y)], radius: 0)]
        case .polygon(let points):
            let hull = Self.convexHull(points)
            switch hull.count {
            case 0: base = []
            case 1: base = [.circle(hull[0], 0)]
            default: base = [Geom2D(verts: hull, radius: 0)]
            }
        case .capsule(let r, let h):
            base = [Geom2D(verts: [Vec2(0, -abs(h)), Vec2(0, abs(h))], radius: max(r, 0))]
        case .edge(let a, let b):
            base = [Geom2D(verts: [a, b], radius: 0)]
        case .chain(let points, let isLoop):
            var segments: [Geom2D] = []
            let n = points.count
            for i in 0..<(isLoop ? n : max(n - 1, 0)) where points[i] != points[(i + 1) % n] {
                segments.append(Geom2D(verts: [points[i], points[(i + 1) % n]], radius: 0))
            }
            base = segments
        }
        return base.map { $0.placed(offset) }
    }

    /// Whether the shape has area (an edge or chain has none).
    var isSolid: Bool {
        switch self {
        case .edge, .chain: return false
        default: return true
        }
    }

    /// Counter-clockwise hull by the monotone chain, at most `Geom2D.maxVertices` vertices (the
    /// vertex whose removal changes the area least is dropped until it fits). Collinear and
    /// duplicate points are removed.
    static func convexHull(_ points: [Vec2]) -> [Vec2] {
        let sorted = points.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        var unique: [Vec2] = []
        for p in sorted where unique.last.map({ length2($0 - p) > 1e-5 }) ?? true { unique.append(p) }
        guard unique.count > 2 else { return unique }
        var hull: [Vec2] = []
        for pass in 0..<2 {
            let start = hull.count
            for p in (pass == 0 ? unique : unique.reversed()) {
                while hull.count >= start + 2 && cross2(hull[hull.count - 1] - hull[hull.count - 2], p - hull[hull.count - 2]) <= 1e-7 {
                    hull.removeLast()
                }
                hull.append(p)
            }
            hull.removeLast()
        }
        while hull.count > Geom2D.maxVertices {
            var smallest = 0, area = Float.infinity
            for i in hull.indices {
                let a = hull[(i + hull.count - 1) % hull.count], b = hull[i], c = hull[(i + 1) % hull.count]
                let t = abs(cross2(b - a, c - a))
                if t < area {
                    area = t
                    smallest = i
                }
            }
            hull.remove(at: smallest)
        }
        return hull
    }
}
