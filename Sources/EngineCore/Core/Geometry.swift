// Geometric primitives shared by physics, rendering, UI and the editor tools.

/// A half-line from `origin` along `direction` (unit length).
public struct Ray: Sendable, Equatable {
    public var origin: Vec3
    /// Unit length, so `t` in `point(at:)` is a distance.
    public var direction: Vec3

    /// `direction` is normalized.
    @inlinable public init(origin: Vec3, direction: Vec3) {
        self.origin = origin
        self.direction = normalize(direction)
    }

    @inlinable public func point(at t: Float) -> Vec3 { origin + direction * t }

    /// Where the ray enters and leaves an axis-aligned box (slab test), as distances along it,
    /// or nil if it misses or the box is behind the origin. `enter` is 0 when the origin is inside.
    @inlinable public func intersect(_ bounds: Bounds) -> (enter: Float, exit: Float)? {
        Self.intersect(origin: origin, direction: direction, bounds: bounds)
    }

    /// The slab test for any direction (not necessarily unit length; distances are then in
    /// multiples of it). Axes the direction is parallel to only pass if the origin is inside
    /// the slab.
    @usableFromInline static func intersect(origin: Vec3, direction: Vec3, bounds: Bounds) -> (enter: Float, exit: Float)? {
        let lo = bounds.center - bounds.halfExtent, hi = bounds.center + bounds.halfExtent
        var enter: Float = 0, exit = Float.infinity
        for axis in 0..<3 {
            let o = origin[axis], d = direction[axis]
            if d == 0 {
                if o < lo[axis] || o > hi[axis] { return nil }
                continue
            }
            let inverse = 1 / d
            var t0 = (lo[axis] - o) * inverse, t1 = (hi[axis] - o) * inverse
            if t0 > t1 { swap(&t0, &t1) }
            enter = max(enter, t0)
            exit = min(exit, t1)
            if enter > exit { return nil }
        }
        return (enter, exit)
    }

    /// The distance to triangle `a b c` (either side), or nil if the ray misses it or it is
    /// behind the origin (Möller–Trumbore).
    @inlinable public func intersect(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> Float? {
        Self.intersectTriangle(origin: origin, direction: direction, a, b, c)?.t
    }

    /// Möller–Trumbore for any direction: the hit's ray parameter `t` and barycentrics (u, v)
    /// of b and c, and whether the triangle faces the ray (counter-clockwise seen from the origin).
    @usableFromInline package static func intersectTriangle(origin: Vec3, direction: Vec3, _ a: Vec3, _ b: Vec3, _ c: Vec3)
        -> (t: Float, u: Float, v: Float, frontFacing: Bool)? {
        let e1 = b - a, e2 = c - a
        let p = cross(direction, e2)
        let det = dot(e1, p)
        // Relative to the edge lengths, so tiny and huge triangles behave the same.
        let scale = dot(e1, e1) * dot(e2, e2) * dot(direction, direction)
        guard det * det > 1e-14 * scale else { return nil }  // parallel to the plane, or degenerate
        let inverse = 1 / det
        let s = origin - a
        let u = dot(s, p) * inverse
        guard u >= 0, u <= 1 else { return nil }
        let q = cross(s, e1)
        let v = dot(direction, q) * inverse
        guard v >= 0, u + v <= 1 else { return nil }
        let t = dot(e2, q) * inverse
        guard t >= 0 else { return nil }
        return (t, u, v, det > 0)
    }

    /// The distance to the plane through `point` with normal `normal`, or nil if the ray is
    /// (nearly) parallel to it or the plane is behind the origin.
    @inlinable public func intersectPlane(point: Vec3, normal: Vec3) -> Float? {
        let n = normalize(normal)
        let denominator = dot(direction, n)
        guard abs(denominator) > 1e-6 else { return nil }
        let t = dot(point - origin, n) / denominator
        return t >= 0 ? t : nil
    }

    /// The parameter `s` of the point on the infinite line `linePoint + s * lineDirection`
    /// (unit direction) closest to this ray (treated as a full line), or nil when they are
    /// (nearly) parallel. The constraint math of axis drags.
    @inlinable public func closestParameter(onLine linePoint: Vec3, direction lineDirection: Vec3) -> Float? {
        let a = normalize(lineDirection)
        let b = dot(a, direction)
        let denominator = 1 - b * b
        guard denominator > 1e-6 else { return nil }
        let w = linePoint - origin
        return (b * dot(direction, w) - dot(a, w)) / denominator
    }
}

/// An axis-aligned box as center and half-extent.
public struct Bounds: Equatable, Sendable {
    public var center: Vec3
    public var halfExtent: Vec3

    @inlinable public init(center: Vec3, halfExtent: Vec3) {
        self.center = center
        self.halfExtent = halfExtent
    }

    /// The smallest box around `points` (a zero box at the origin when empty).
    @inlinable public init<S: Sequence>(enclosing points: S) where S.Element == Vec3 {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for p in points {
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        center = (lo + hi) / 2
        halfExtent = (hi - lo) / 2
    }

    /// The axis-aligned box around this box transformed by the affine matrix `m`.
    @inlinable public func transformed(by m: Mat4) -> Bounds {
        let c = m.c0 * center.x + m.c1 * center.y + m.c2 * center.z + m.c3
        let ax = Vec3(abs(m.c0.x), abs(m.c0.y), abs(m.c0.z))
        let ay = Vec3(abs(m.c1.x), abs(m.c1.y), abs(m.c1.z))
        let az = Vec3(abs(m.c2.x), abs(m.c2.y), abs(m.c2.z))
        return Bounds(center: Vec3(c.x, c.y, c.z), halfExtent: ax * halfExtent.x + ay * halfExtent.y + az * halfExtent.z)
    }
}
