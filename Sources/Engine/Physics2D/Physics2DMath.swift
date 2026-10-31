import Foundation

// Math for the 2D physics: rotations as (cos, sin), poses, boxes and small vector helpers. The
// helpers have their own names (`dot2`, `cross2`, ...) so they never compete with the 3D ones.

@inlinable func dot2(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
/// The z component of the 3D cross product.
@inlinable func cross2(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.y - a.y * b.x }
/// `w x v` for a rotation about z of speed `w`.
@inlinable func cross2(_ w: Float, _ v: Vec2) -> Vec2 { Vec2(-w * v.y, w * v.x) }
@inlinable func lengthSquared2(_ v: Vec2) -> Float { v.x * v.x + v.y * v.y }
@inlinable func length2(_ v: Vec2) -> Float { lengthSquared2(v).squareRoot() }
/// The unit vector of `v`, or zero.
@inlinable func normalize2(_ v: Vec2) -> Vec2 {
    let l = length2(v)
    return l > 1e-12 ? v / l : .zero
}
/// `v` turned a quarter clockwise: the outward normal of a counter-clockwise edge.
@inlinable func rightPerp(_ v: Vec2) -> Vec2 { Vec2(v.y, -v.x) }
@inlinable func leftPerp(_ v: Vec2) -> Vec2 { Vec2(-v.y, v.x) }

/// A rotation about z, stored as cosine and sine (no trigonometry in the solver).
public struct Rot2: Equatable, Sendable, Codable {
    public var c: Float
    public var s: Float

    public static let identity = Rot2(c: 1, s: 0)

    public init(c: Float, s: Float) {
        self.c = c
        self.s = s
    }

    public init(angle: Float) {
        c = cosf(angle)
        s = sinf(angle)
    }

    /// Radians in (-pi, pi].
    public var angle: Float { atan2f(s, c) }
    @inlinable public func rotate(_ v: Vec2) -> Vec2 { Vec2(c * v.x - s * v.y, s * v.x + c * v.y) }
    @inlinable public func inverseRotate(_ v: Vec2) -> Vec2 { Vec2(c * v.x + s * v.y, -s * v.x + c * v.y) }
    @inlinable public var inverse: Rot2 { Rot2(c: c, s: -s) }
    /// `a` after `b`.
    @inlinable public static func * (a: Rot2, b: Rot2) -> Rot2 { Rot2(c: a.c * b.c - a.s * b.s, s: a.s * b.c + a.c * b.s) }

    /// Rotated by `w * h` radians (a small step), renormalized.
    @inlinable func integrated(_ w: Float, _ h: Float) -> Rot2 {
        let c2 = c - h * w * s, s2 = s + h * w * c
        let m = 1 / (c2 * c2 + s2 * s2).squareRoot()
        return Rot2(c: c2 * m, s: s2 * m)
    }
}

/// A position and an angle: a body's frame.
public struct Pose2D: Equatable, Sendable, Codable {
    public var position: Vec2
    public var rotation: Rot2

    public static let identity = Pose2D()

    public init(position: Vec2 = .zero, rotation: Rot2 = .identity) {
        self.position = position
        self.rotation = rotation
    }

    public init(position: Vec2, angle: Float) {
        self.init(position: position, rotation: Rot2(angle: angle))
    }

    public var angle: Float { rotation.angle }
    @inlinable public func transform(_ p: Vec2) -> Vec2 { position + rotation.rotate(p) }
    @inlinable public func inverseTransform(_ p: Vec2) -> Vec2 { rotation.inverseRotate(p - position) }
    /// `b` placed in `a`'s frame: the pose that applies `b` first, then `a`.
    @inlinable public static func * (a: Pose2D, b: Pose2D) -> Pose2D {
        Pose2D(position: a.transform(b.position), rotation: a.rotation * b.rotation)
    }
    @inlinable public var inverse: Pose2D {
        let r = rotation.inverse
        return Pose2D(position: r.rotate(-position), rotation: r)
    }
}

/// An axis-aligned box.
public struct AABB2: Equatable, Sendable {
    public var min: Vec2
    public var max: Vec2

    public init(min: Vec2, max: Vec2) {
        self.min = min
        self.max = max
    }

    @inlinable public var center: Vec2 { (min + max) * 0.5 }
    @inlinable public var halfExtent: Vec2 { (max - min) * 0.5 }
    @inlinable var perimeter: Float { 2 * ((max.x - min.x) + (max.y - min.y)) }
    @inlinable public func overlaps(_ o: AABB2) -> Bool {
        min.x <= o.max.x && max.x >= o.min.x && min.y <= o.max.y && max.y >= o.min.y
    }
    @inlinable public func contains(_ o: AABB2) -> Bool {
        min.x <= o.min.x && min.y <= o.min.y && max.x >= o.max.x && max.y >= o.max.y
    }
    @inlinable public func union(_ o: AABB2) -> AABB2 {
        AABB2(min: Vec2(Swift.min(min.x, o.min.x), Swift.min(min.y, o.min.y)),
              max: Vec2(Swift.max(max.x, o.max.x), Swift.max(max.y, o.max.y)))
    }
    @inlinable public func expanded(by margin: Float) -> AABB2 {
        AABB2(min: min - Vec2(repeating: margin), max: max + Vec2(repeating: margin))
    }
    /// Also covers the box moved by `d`.
    @inlinable public func swept(by d: Vec2) -> AABB2 {
        AABB2(min: Vec2(Swift.min(min.x, min.x + d.x), Swift.min(min.y, min.y + d.y)),
              max: Vec2(Swift.max(max.x, max.x + d.x), Swift.max(max.y, max.y + d.y)))
    }

    /// The ray's entry distance in [0, maxT], or nil (slab test).
    func raycast(origin: Vec2, inverseDirection inv: Vec2, maxT: Float) -> Float? {
        var tMin: Float = 0, tMax = maxT
        for k in 0..<2 {
            var t1 = (min[k] - origin[k]) * inv[k], t2 = (max[k] - origin[k]) * inv[k]
            if t1.isNaN { t1 = -.infinity }
            if t2.isNaN { t2 = .infinity }
            tMin = Swift.max(tMin, Swift.min(t1, t2))
            tMax = Swift.min(tMax, Swift.max(t1, t2))
        }
        return tMin <= tMax ? tMin : nil
    }
}

/// The parameters (0...1) of the closest points of segments p1-q1 and p2-q2.
func closestFractions(_ p1: Vec2, _ q1: Vec2, _ p2: Vec2, _ q2: Vec2) -> (Float, Float) {
    let d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2
    let a = dot2(d1, d1), e = dot2(d2, d2), f = dot2(d2, r)
    var s: Float = 0, t: Float = 0
    if a <= 1e-12 && e <= 1e-12 { return (0, 0) }
    if a <= 1e-12 {
        t = min(max(f / e, 0), 1)
    } else {
        let c = dot2(d1, r)
        if e <= 1e-12 {
            s = min(max(-c / a, 0), 1)
        } else {
            let b = dot2(d1, d2), denom = a * e - b * b
            s = denom > 1e-12 * a * e ? min(max((b * f - c * e) / denom, 0), 1) : 0
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
    return (s, t)
}
