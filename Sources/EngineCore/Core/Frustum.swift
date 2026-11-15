/// The six planes of a view-projection matrix's clip volume, for culling on the CPU.
/// Works for standard and reversed-Z projections (clip depth in [0, 1] either way).
///
/// The planes are stored inline rather than in an array: culling loops in other engine modules
/// copy frustums per item, and an array would be retained and released on every copy.
public struct Frustum: Sendable {
    @usableFromInline var p0, p1, p2, p3, p4, p5: Vec4

    /// xyz: inward normal, w: offset. A point p is inside a plane when dot(xyz, p) + w >= 0.
    /// Always six: left, right, bottom, top, near, far.
    public var planes: [Vec4] {
        get { [p0, p1, p2, p3, p4, p5] }
        set {
            precondition(newValue.count == 6, "A frustum has six planes")
            (p0, p1, p2, p3, p4, p5) = (newValue[0], newValue[1], newValue[2], newValue[3], newValue[4], newValue[5])
        }
    }

    @inlinable public init(viewProjection m: Mat4) {
        func row(_ i: Int) -> Vec4 { Vec4(m.c0[i], m.c1[i], m.c2[i], m.c3[i]) }
        let (x, y, z, w) = (row(0), row(1), row(2), row(3))
        // -w <= x <= w, -w <= y <= w, 0 <= z <= w
        (p0, p1, p2, p3, p4, p5) = (w + x, w - x, w + y, w - y, z, w - z)
    }

    /// Whether an axis-aligned box might be visible (false only if it is fully outside one plane).
    @inlinable public func intersects(center: Vec3, halfExtent: Vec3) -> Bool {
        @inline(__always) func outside(_ plane: Vec4) -> Bool {
            let normal = Vec3(plane.x, plane.y, plane.z)
            let reach = dot(halfExtent, Vec3(abs(normal.x), abs(normal.y), abs(normal.z)))
            return dot(normal, center) + plane.w < -reach
        }
        return !(outside(p0) || outside(p1) || outside(p2) || outside(p3) || outside(p4) || outside(p5))
    }

    /// Whether a box swept along `offset` (everything between its start and end positions)
    /// might be visible, e.g. the region a caster's shadow can fall in.
    @inlinable public func intersects(center: Vec3, halfExtent: Vec3, sweptBy offset: Vec3) -> Bool {
        let reach = Vec3(abs(offset.x), abs(offset.y), abs(offset.z)) / 2
        return intersects(center: center + offset / 2, halfExtent: halfExtent + reach)
    }
}
