// Small math types the physics code needs on top of Math.swift: a 3x3 matrix (inertia
// tensors), a rigid pose (position + rotation, no scale) and an axis-aligned box.

/// A 3x3 column-major matrix, used for inertia tensors and their inverses.
public struct Mat3: Equatable, Sendable {
    public var c0, c1, c2: Vec3

    @inlinable public init(_ c0: Vec3, _ c1: Vec3, _ c2: Vec3) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
    }

    public static let identity = Mat3(Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1))
    public static let zero = Mat3(.zero, .zero, .zero)

    @inlinable public init(diagonal d: Vec3) { self.init(Vec3(d.x, 0, 0), Vec3(0, d.y, 0), Vec3(0, 0, d.z)) }

    /// The rotation matrix of a unit quaternion.
    @inlinable public init(_ q: Quat) {
        self.init(q * Vec3(1, 0, 0), q * Vec3(0, 1, 0), q * Vec3(0, 0, 1))
    }

    @inlinable public static func * (m: Mat3, v: Vec3) -> Vec3 { m.c0 * v.x + m.c1 * v.y + m.c2 * v.z }
    @inlinable public static func * (a: Mat3, b: Mat3) -> Mat3 { Mat3(a * b.c0, a * b.c1, a * b.c2) }
    @inlinable public static func * (m: Mat3, s: Float) -> Mat3 { Mat3(m.c0 * s, m.c1 * s, m.c2 * s) }
    @inlinable public static func + (a: Mat3, b: Mat3) -> Mat3 { Mat3(a.c0 + b.c0, a.c1 + b.c1, a.c2 + b.c2) }
    @inlinable public static func - (a: Mat3, b: Mat3) -> Mat3 { Mat3(a.c0 - b.c0, a.c1 - b.c1, a.c2 - b.c2) }

    @inlinable public var transpose: Mat3 {
        Mat3(Vec3(c0.x, c1.x, c2.x), Vec3(c0.y, c1.y, c2.y), Vec3(c0.z, c1.z, c2.z))
    }

    /// `|M| * v` with every element made non-negative: the half extent of a box with half
    /// extent `v` after transforming by `M`.
    @inlinable func transformExtent(_ v: Vec3) -> Vec3 {
        let x: Vec3 = absolute(c0) * v.x
        let y: Vec3 = absolute(c1) * v.y
        let z: Vec3 = absolute(c2) * v.z
        return x + y + z
    }

    @inlinable public var trace: Float { c0.x + c1.y + c2.z }

    /// The inverse, or zero for a singular matrix (so a body with no inertia doesn't rotate).
    public var inverse: Mat3 {
        let r0 = cross(c1, c2), r1 = cross(c2, c0), r2 = cross(c0, c1)
        let det = dot(c0, r0)
        guard abs(det) > 1e-20 else { return .zero }
        // The rows of the inverse are the cross products over the determinant.
        return Mat3(r0, r1, r2).transpose * (1 / det)
    }

    /// `skew(v) * u == cross(v, u)`.
    @inlinable public static func skew(_ v: Vec3) -> Mat3 {
        Mat3(Vec3(0, v.z, -v.y), Vec3(-v.z, 0, v.x), Vec3(v.y, -v.x, 0))
    }

    /// The outer product `a bᵀ`.
    @inlinable public static func outer(_ a: Vec3, _ b: Vec3) -> Mat3 { Mat3(a * b.x, a * b.y, a * b.z) }
}

/// A rigid transform: rotation, then translation (no scale).
public struct Pose: Equatable, Sendable {
    public var position: Vec3
    public var rotation: Quat

    public init(position: Vec3 = .zero, rotation: Quat = .identity) {
        self.position = position
        self.rotation = rotation
    }

    public static let identity = Pose()

    /// A point from this pose's local space to its parent's.
    @inlinable public func transform(_ p: Vec3) -> Vec3 { position + rotation * p }
    /// A point from the parent's space into this pose's local space.
    @inlinable public func inverseTransform(_ p: Vec3) -> Vec3 { rotation.conjugate * (p - position) }

    /// `a * b` applies `b` first: a child pose `b` placed in `a`.
    @inlinable public static func * (a: Pose, b: Pose) -> Pose {
        Pose(position: a.transform(b.position), rotation: (a.rotation * b.rotation).normalized)
    }

    public var inverse: Pose {
        let r = rotation.conjugate
        return Pose(position: r * -position, rotation: r)
    }

    public var matrix: Mat4 { Mat4(translation: position, rotation: rotation, scale: .one) }
}

/// An axis-aligned bounding box from `min` to `max`.
public struct AABB: Equatable, Sendable {
    public var min: Vec3
    public var max: Vec3

    public init(min: Vec3, max: Vec3) {
        self.min = min
        self.max = max
    }

    /// The box around `points` (empty input gives a zero box at the origin).
    public init<S: Sequence>(enclosing points: S) where S.Element == Vec3 {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for p in points {
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        if lo.x > hi.x { lo = .zero; hi = .zero }
        self.init(min: lo, max: hi)
    }

    @inlinable public var center: Vec3 { (min + max) * 0.5 }
    @inlinable public var halfExtent: Vec3 { (max - min) * 0.5 }
    public var bounds: Bounds { Bounds(center: center, halfExtent: halfExtent) }

    /// Twice-ish the surface area (the tree's cost heuristic only compares them).
    @inlinable var perimeter: Float {
        let d = max - min
        return d.x * d.y + d.y * d.z + d.z * d.x
    }

    @inlinable public func overlaps(_ o: AABB) -> Bool {
        !(o.min.x > max.x || o.max.x < min.x || o.min.y > max.y || o.max.y < min.y || o.min.z > max.z || o.max.z < min.z)
    }

    @inlinable public func contains(_ o: AABB) -> Bool {
        min.x <= o.min.x && min.y <= o.min.y && min.z <= o.min.z && max.x >= o.max.x && max.y >= o.max.y && max.z >= o.max.z
    }

    @inlinable public func union(_ o: AABB) -> AABB { AABB(min: pointwiseMin(min, o.min), max: pointwiseMax(max, o.max)) }

    @inlinable public func expanded(by margin: Float) -> AABB {
        AABB(min: min - Vec3(repeating: margin), max: max + Vec3(repeating: margin))
    }

    /// The box grown to also cover itself moved by `d`.
    @inlinable public func swept(by d: Vec3) -> AABB {
        AABB(min: min + pointwiseMin(d, .zero), max: max + pointwiseMax(d, .zero))
    }

    /// Where a ray `origin + t * direction` enters the box, for t in [0, maxT]; nil if it misses.
    func raycast(origin: Vec3, inverseDirection inv: Vec3, maxT: Float) -> Float? {
        let t0 = (min - origin) * inv, t1 = (max - origin) * inv
        let lo = pointwiseMin(t0, t1), hi = pointwiseMax(t0, t1)
        // NaN (0 * inf, a ray in a slab's plane) must not reject: replace with the open interval.
        let enter = Swift.max(Swift.max(lo.x.isNaN ? -.infinity : lo.x, lo.y.isNaN ? -.infinity : lo.y),
                              Swift.max(lo.z.isNaN ? -.infinity : lo.z, 0))
        let exit = Swift.min(Swift.min(hi.x.isNaN ? .infinity : hi.x, hi.y.isNaN ? .infinity : hi.y),
                             Swift.min(hi.z.isNaN ? .infinity : hi.z, maxT))
        return enter <= exit ? enter : nil
    }
}

// MARK: - Helpers

/// Two unit vectors perpendicular to unit `n` and to each other (a deterministic choice).
@inlinable func tangentBasis(_ n: Vec3) -> (Vec3, Vec3) {
    // Duff et al., "Building an Orthonormal Basis, Revisited".
    let sign: Float = n.z >= 0 ? 1 : -1
    let a = -1 / (sign + n.z)
    let b = n.x * n.y * a
    return (Vec3(1 + sign * n.x * n.x * a, sign * b, -sign * n.x), Vec3(b, sign + n.y * n.y * a, -n.y))
}

/// Componentwise absolute value.
@inlinable func absolute(_ v: Vec3) -> Vec3 { Vec3(abs(v.x), abs(v.y), abs(v.z)) }

@inlinable func lengthSquared(_ v: Vec3) -> Float { dot(v, v) }

extension Quat {
    /// The rotation after spinning at angular velocity `w` (world space) for `dt` seconds.
    @inlinable func integrated(_ w: Vec3, _ dt: Float) -> Quat {
        let q = Quat(w.x, w.y, w.z, 0) * self
        return Quat(vector: vector + q.vector * (0.5 * dt)).normalized
    }
}

/// The closest points between segments `p1 q1` and `p2 q2` (Ericson, Real-Time Collision
/// Detection 5.1.9). A degenerate segment (a point) works too.
func closestPointsBetweenSegments(_ p1: Vec3, _ q1: Vec3, _ p2: Vec3, _ q2: Vec3) -> (Vec3, Vec3) {
    let d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2
    let a = dot(d1, d1), e = dot(d2, d2), f = dot(d2, r)
    let eps: Float = 1e-12
    var s: Float = 0, t: Float = 0
    if a <= eps && e <= eps { return (p1, p2) }
    if a <= eps {
        t = min(max(f / e, 0), 1)
    } else {
        let c = dot(d1, r)
        if e <= eps {
            s = min(max(-c / a, 0), 1)
        } else {
            let b = dot(d1, d2)
            let denom = a * e - b * b
            s = denom > eps * a * e ? min(max((b * f - c * e) / denom, 0), 1) : 0
            t = (b * s + f) / e
            if t < 0 {
                t = 0
                s = min(max(-c / a, 0), 1)
            } else if t > 1 {
                t = 1
                s = min(max((b - c) / a, 0), 1)
            }
        }
    }
    return (p1 + d1 * s, p2 + d2 * t)
}

/// The closest point to `p` on segment `a b`.
@inlinable func closestPointOnSegment(_ p: Vec3, _ a: Vec3, _ b: Vec3) -> Vec3 {
    let ab = b - a
    let len2 = dot(ab, ab)
    guard len2 > 1e-12 else { return a }
    return a + ab * min(max(dot(p - a, ab) / len2, 0), 1)
}
