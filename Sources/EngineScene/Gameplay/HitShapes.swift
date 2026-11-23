// Hit shapes: the spheres, capsules and boxes of hitboxes (what hurts) and hurtboxes (what can
// be hurt), in the space of the entity (usually a bone) they are attached to, and their
// world-space volumes with an overlap test that reports a contact point and normal.
//
// ```json
// {"kind": "capsule", "radius": 0.08, "from": [0, 0, 0], "to": [0, 0.3, 0]}
// {"kind": "sphere", "radius": 0.12, "from": [0, 0.1, 0]}
// {"kind": "box", "from": [0, 0.5, 0], "size": [0.3, 0.5, 0.2]}
// ```
//
// Every key is optional. A capsule runs from `from` to `to`; a sphere sits at `from`; a box is
// centered on `from` with half extents `size`, turned with its entity.
import EngineCore

/// The kind of a `HitShape`.
public enum HitShapeKind: String, Codable, Sendable, CaseIterable {
    case sphere, capsule, box
}

/// A sphere, capsule or box in its entity's space (see the notes at the top of HitShapes.swift).
public struct HitShape: Codable, Equatable, Sendable {
    public var kind: HitShapeKind
    /// Sphere and capsule radius, meters (scaled by the entity's largest scale).
    public var radius: Float
    /// The sphere's center, the capsule's first end, the box's center.
    public var from: Vec3
    /// The capsule's second end.
    public var to: Vec3
    /// The box's half extents.
    public var size: Vec3

    public init(kind: HitShapeKind = .sphere, radius: Float = 0.1, from: Vec3 = .zero, to: Vec3 = .zero, size: Vec3 = Vec3(0.1, 0.1, 0.1)) {
        self.kind = kind
        self.radius = radius
        self.from = from
        self.to = to
        self.size = size
    }

    public static func sphere(radius: Float, at center: Vec3 = .zero) -> HitShape { HitShape(kind: .sphere, radius: radius, from: center, to: center) }
    public static func capsule(from a: Vec3, to b: Vec3, radius: Float) -> HitShape { HitShape(kind: .capsule, radius: radius, from: a, to: b) }
    public static func box(center: Vec3 = .zero, halfExtents: Vec3) -> HitShape { HitShape(kind: .box, radius: 0, from: center, to: center, size: halfExtents) }

    private enum CodingKeys: String, CodingKey { case kind, radius, from, to, size }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = HitShape()
        kind = try c.decodeIfPresent(HitShapeKind.self, forKey: .kind) ?? d.kind
        radius = try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius
        from = try c.decodeIfPresent(Vec3.self, forKey: .from) ?? d.from
        to = try c.decodeIfPresent(Vec3.self, forKey: .to) ?? from
        size = try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size
    }

    /// The shape placed by `matrix` (its entity's local-to-world matrix).
    public func volume(_ matrix: Mat4) -> HitVolume {
        func point(_ p: Vec3) -> Vec3 {
            let v = matrix * Vec4(p.x, p.y, p.z, 1)
            return Vec3(v.x, v.y, v.z)
        }
        let axes = [Vec3(matrix.c0.x, matrix.c0.y, matrix.c0.z), Vec3(matrix.c1.x, matrix.c1.y, matrix.c1.z),
                    Vec3(matrix.c2.x, matrix.c2.y, matrix.c2.z)]
        let scales = axes.map { length($0) }
        let largest = max(scales[0], scales[1], scales[2])
        switch kind {
        case .sphere:
            let c = point(from)
            return HitVolume(kind: .capsule, a: c, b: c, radius: max(radius, 0) * largest)
        case .capsule:
            return HitVolume(kind: .capsule, a: point(from), b: point(to), radius: max(radius, 0) * largest)
        case .box:
            let units = axes.enumerated().map { i, axis in scales[i] > 1e-8 ? axis / scales[i] : Vec3(i == 0 ? 1 : 0, i == 1 ? 1 : 0, i == 2 ? 1 : 0) }
            let half = Vec3(abs(size.x) * scales[0], abs(size.y) * scales[1], abs(size.z) * scales[2])
            let c = point(from)
            return HitVolume(kind: .box, a: c, b: c, radius: 0, axes: units, halfExtents: half)
        }
    }
}

/// A hit shape in world space: a capsule (a sphere when `a == b`) or an oriented box.
public struct HitVolume: Equatable, Sendable {
    public enum Kind: String, Sendable { case capsule, box }
    public var kind: Kind
    /// The capsule's segment; the box's center (both).
    public var a: Vec3
    public var b: Vec3
    public var radius: Float
    /// The box's unit axes and half extents along them.
    public var axes: [Vec3]
    public var halfExtents: Vec3

    public init(kind: Kind, a: Vec3, b: Vec3, radius: Float, axes: [Vec3] = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)],
                halfExtents: Vec3 = .zero) {
        self.kind = kind
        self.a = a
        self.b = b
        self.radius = radius
        self.axes = axes
        self.halfExtents = halfExtents
    }

    /// The middle of the shape.
    public var center: Vec3 { (a + b) * 0.5 }

    /// Where two volumes touch, if they do: `point` on `other`'s surface (or inside it), `normal`
    /// out of `other` toward this volume, `depth` how far they overlap.
    public func contact(with other: HitVolume) -> (point: Vec3, normal: Vec3, depth: Float)? {
        switch (kind, other.kind) {
        case (.capsule, .capsule):
            let (p, q) = HitVolume.closestPoints(a, b, other.a, other.b)
            let d = p - q
            let distance = length(d)
            let reach = radius + other.radius
            guard distance <= reach else { return nil }
            let normal = distance > 1e-6 ? d / distance : HitVolume.fallbackNormal(center - other.center)
            return (q + normal * min(other.radius, distance), normal, reach - distance)
        case (.capsule, .box):
            let (onSegment, onBox, distance) = other.closestToSegment(a, b)
            guard distance <= radius else { return nil }
            let normal = distance > 1e-6 ? (onSegment - onBox) / distance : HitVolume.fallbackNormal(onSegment - other.center)
            return (onBox, normal, radius - distance)
        case (.box, .capsule):
            guard let hit = other.contact(with: self) else { return nil }
            // Point on this box, which is `other`'s nearest point here: move to the capsule's surface.
            let point = hit.point - hit.normal * hit.depth
            return (point, -hit.normal, hit.depth)
        case (.box, .box):
            guard let depth = HitVolume.boxOverlap(self, other) else { return nil }
            // The point of `other` nearest this box's center, and the way out of `other` toward it.
            let near = other.closestPoint(to: center)
            let normal = HitVolume.fallbackNormal(center - other.center)
            return (near, normal, depth)
        }
    }

    // MARK: Geometry

    private static func fallbackNormal(_ v: Vec3) -> Vec3 {
        let l = length(v)
        return l > 1e-6 ? v / l : Vec3(0, 1, 0)
    }

    /// The closest points of segments p1-q1 and p2-q2 (Ericson, Real-Time Collision Detection 5.1.9).
    static func closestPoints(_ p1: Vec3, _ q1: Vec3, _ p2: Vec3, _ q2: Vec3) -> (Vec3, Vec3) {
        let d1 = q1 - p1, d2 = q2 - p2, r = p1 - p2
        let a = dot(d1, d1), e = dot(d2, d2), f = dot(d2, r)
        var s: Float = 0, t: Float = 0
        if a <= 1e-9 && e <= 1e-9 { return (p1, p2) }
        if a <= 1e-9 {
            t = min(max(f / e, 0), 1)
        } else {
            let c = dot(d1, r)
            if e <= 1e-9 {
                s = min(max(-c / a, 0), 1)
            } else {
                let b = dot(d1, d2)
                let denom = a * e - b * b
                s = denom != 0 ? min(max((b * f - c * e) / denom, 0), 1) : 0
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

    /// The box's point nearest `p` (`p` itself when inside).
    func closestPoint(to p: Vec3) -> Vec3 {
        let d = p - a
        var result = a
        for i in 0..<3 {
            let extent = halfExtents[i]
            result += axes[i] * min(max(dot(d, axes[i]), -extent), extent)
        }
        return result
    }

    /// The segment's and the box's nearest points and their distance (0 when the segment enters
    /// the box). The distance along the segment is convex, so a ternary search finds it.
    func closestToSegment(_ p: Vec3, _ q: Vec3) -> (Vec3, Vec3, Float) {
        func at(_ t: Float) -> (Vec3, Vec3, Float) {
            let s = p + (q - p) * t
            let c = closestPoint(to: s)
            return (s, c, length(s - c))
        }
        var lo: Float = 0, hi: Float = 1
        for _ in 0..<40 {
            let m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3
            if at(m1).2 <= at(m2).2 { hi = m2 } else { lo = m1 }
        }
        return at((lo + hi) / 2)
    }

    /// Separating axis test of two oriented boxes: the smallest overlap along the 15 axes, nil if
    /// some axis separates them.
    static func boxOverlap(_ x: HitVolume, _ y: HitVolume) -> Float? {
        var candidates = x.axes + y.axes
        for u in x.axes { for v in y.axes { candidates.append(cross(u, v)) } }
        let offset = y.a - x.a
        var smallest = Float.greatestFiniteMagnitude
        for axis in candidates {
            let l = length(axis)
            guard l > 1e-6 else { continue }
            let n = axis / l
            func reach(_ box: HitVolume) -> Float { (0..<3).reduce(0) { $0 + abs(dot(box.axes[$1], n)) * box.halfExtents[$1] } }
            let overlap = reach(x) + reach(y) - abs(dot(offset, n))
            if overlap < 0 { return nil }
            smallest = min(smallest, overlap)
        }
        return smallest
    }
}
