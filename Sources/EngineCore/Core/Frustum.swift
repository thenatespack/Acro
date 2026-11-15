/// The six planes of a view-projection matrix's clip volume, for culling on the CPU.
/// Works for standard and reversed-Z projections (clip depth in [0, 1] either way).
public struct Frustum: Sendable {
    /// xyz: inward normal, w: offset. A point p is inside a plane when dot(xyz, p) + w >= 0.
    public var planes: [Vec4]

    public init(viewProjection m: Mat4) {
        func row(_ i: Int) -> Vec4 { Vec4(m.c0[i], m.c1[i], m.c2[i], m.c3[i]) }
        let (x, y, z, w) = (row(0), row(1), row(2), row(3))
        // -w <= x <= w, -w <= y <= w, 0 <= z <= w
        planes = [w + x, w - x, w + y, w - y, z, w - z]
    }

    /// Whether an axis-aligned box might be visible (false only if it is fully outside one plane).
    public func intersects(center: Vec3, halfExtent: Vec3) -> Bool {
        for plane in planes {
            let normal = Vec3(plane.x, plane.y, plane.z)
            let reach = dot(halfExtent, Vec3(abs(normal.x), abs(normal.y), abs(normal.z)))
            if dot(normal, center) + plane.w < -reach { return false }
        }
        return true
    }

    /// Whether a box swept along `offset` (everything between its start and end positions)
    /// might be visible, e.g. the region a caster's shadow can fall in.
    public func intersects(center: Vec3, halfExtent: Vec3, sweptBy offset: Vec3) -> Bool {
        let reach = Vec3(abs(offset.x), abs(offset.y), abs(offset.z)) / 2
        return intersects(center: center + offset / 2, halfExtent: halfExtent + reach)
    }
}
