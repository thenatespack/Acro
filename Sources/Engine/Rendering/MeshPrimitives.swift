import Foundation

// More built-in primitives: cylinder, capsule, cone and torus. All are centered on the origin, wind
// counter-clockwise from outside and have unit-length normals and 0-1 UVs.

extension MeshGeometry {
    typealias LatheRing = (r: Float, y: Float, nr: Float, ny: Float, v: Float)

    /// Appends a lathe surface: rings of `segments + 1` vertices (the first and last coincide, for the
    /// UV seam), each given by position `(r, y)` and the outward profile normal `(nr, ny)`. The
    /// profile runs from +Y downward. Triangles collapsed at a zero-radius ring are skipped.
    fileprivate mutating func appendLathe(_ profile: [LatheRing], segments: Int) {
        let base = UInt32(vertices.count)
        for p in profile {
            for s in 0...segments {
                let u = Float(s) / Float(segments), phi = u * 2 * .pi
                let sp = sinf(phi), cp = cosf(phi)
                vertices.append(MeshVertex(position: Vec3(p.r * sp, p.y, p.r * cp),
                                           normal: Vec3(p.nr * sp, p.ny, p.nr * cp), uv: Vec2(u, p.v)))
            }
        }
        let stride = UInt32(segments + 1)
        for ring in 0..<profile.count - 1 {
            for s in 0..<UInt32(segments) {
                let a = base + UInt32(ring) * stride + s, b = a + 1, c = a + stride, d = c + 1
                // Same winding as `sphere`: a (top, phi), c (below), d (below, phi+), b (top, phi+).
                if profile[ring].r > 0 { indices += [a, c, b] }
                if profile[ring + 1].r > 0 { indices += [b, c, d] }
            }
        }
    }

    /// Appends a flat disc at height `y` facing up or down, with planar UVs.
    fileprivate mutating func appendCap(radius: Float, y: Float, up: Bool, segments: Int) {
        let base = UInt32(vertices.count)
        let n = Vec3(0, up ? 1 : -1, 0)
        vertices.append(MeshVertex(position: Vec3(0, y, 0), normal: n, uv: Vec2(0.5, 0.5)))
        for s in 0...segments {
            let phi = Float(s) / Float(segments) * 2 * .pi
            let sp = sinf(phi), cp = cosf(phi)
            vertices.append(MeshVertex(position: Vec3(radius * sp, y, radius * cp), normal: n,
                                       uv: Vec2(0.5 + 0.5 * sp, 0.5 + 0.5 * cp * (up ? 1 : -1))))
        }
        for s in 0..<UInt32(segments) {
            // Seen from +Y, phi grows from +Z toward +X (clockwise), so the top winds center, phi, phi+.
            if up { indices += [base, base + s + 1, base + s + 2] } else { indices += [base, base + s + 2, base + s + 1] }
        }
    }

    /// A capped cylinder along Y, centered on the origin. Caps have flat normals and planar UVs; the
    /// side's V runs 0 (top) to 1 (bottom).
    public static func cylinder(radius: Float = 0.5, height: Float = 1, segments: Int = 32) -> MeshGeometry {
        precondition(segments >= 3)
        let h = height / 2
        var g = MeshGeometry(vertices: [], indices: [])
        g.appendCap(radius: radius, y: h, up: true, segments: segments)
        g.appendLathe([(radius, h, 1, 0, 0), (radius, -h, 1, 0, 1)], segments: segments)
        g.appendCap(radius: radius, y: -h, up: false, segments: segments)
        return g
    }

    /// A capsule along Y centered on the origin: a cylinder between two hemispheres of `radius`,
    /// `height` overall (`radius` is clamped to `height / 2`). `rings` is the stacks per hemisphere.
    public static func capsule(radius: Float = 0.25, height: Float = 1, segments: Int = 32, rings: Int = 8) -> MeshGeometry {
        precondition(segments >= 3 && rings >= 1)
        let r = min(radius, height / 2)
        let half = height / 2 - r
        func v(_ y: Float) -> Float { (height / 2 - y) / max(height, 1e-6) }
        var profile: [LatheRing] = []
        for i in 0...rings {  // top pole down to the equator
            let a = Float(i) / Float(rings) * .pi / 2
            let y = half + r * cosf(a)
            profile.append((r * sinf(a), y, sinf(a), cosf(a), v(y)))
        }
        for i in 0...rings {  // equator down to the bottom pole
            let a = Float(i) / Float(rings) * .pi / 2
            let y = -half - r * sinf(a)
            profile.append((r * cosf(a), y, cosf(a), -sinf(a), v(y)))
        }
        var g = MeshGeometry(vertices: [], indices: [])
        g.appendLathe(profile, segments: segments)
        return g
    }

    /// A cone along Y, centered on the origin: apex at `+height / 2`, a flat base disc at `-height / 2`.
    public static func cone(radius: Float = 0.5, height: Float = 1, segments: Int = 32) -> MeshGeometry {
        precondition(segments >= 3)
        let h = height / 2
        // The side's normal is perpendicular to the slant: (height, radius) normalized in (r, y).
        let len = (radius * radius + height * height).squareRoot()
        let nr = height / len, ny = radius / len
        var g = MeshGeometry(vertices: [], indices: [])
        // The apex ring has radius 0 but per-segment normals, so shading is smooth up to the tip.
        g.appendLathe([(0, h, nr, ny, 0), (radius, -h, nr, ny, 1)], segments: segments)
        g.appendCap(radius: radius, y: -h, up: false, segments: segments)
        return g
    }

    /// A torus in the XZ plane around Y, centered on the origin: `majorRadius` from the center to the
    /// tube's center, `minorRadius` the tube's radius (defaults: outer diameter 1).
    public static func torus(majorRadius: Float = 0.35, minorRadius: Float = 0.15, segments: Int = 32, sides: Int = 16) -> MeshGeometry {
        precondition(segments >= 3 && sides >= 3)
        var g = MeshGeometry(vertices: [], indices: [])
        for i in 0...segments {
            let u = Float(i) / Float(segments), phi = u * 2 * .pi
            let sp = sinf(phi), cp = cosf(phi)
            for j in 0...sides {
                let v = Float(j) / Float(sides), theta = v * 2 * .pi
                let ct = cosf(theta), st = sinf(theta)
                // theta = 0 on the outer equator, growing toward +Y.
                let n = Vec3(ct * sp, st, ct * cp)
                g.vertices.append(MeshVertex(position: Vec3(majorRadius * sp, 0, majorRadius * cp) + n * minorRadius,
                                             normal: n, uv: Vec2(u, v)))
            }
        }
        let stride = UInt32(sides + 1)
        for i in 0..<UInt32(segments) {
            for j in 0..<UInt32(sides) {
                let a = i * stride + j, b = a + 1, c = a + stride, d = c + 1
                g.indices += [a, c, b, b, c, d]
            }
        }
        return g
    }

    /// The built-in primitive named by `handle` (cube, plane, sphere, cylinder, capsule, cone, torus), or nil.
    public static func builtin(_ handle: MeshHandle) -> MeshGeometry? {
        switch handle {
        case .cube: .cube()
        case .plane: .plane()
        case .sphere: .sphere()
        case .cylinder: .cylinder()
        case .capsule: .capsule()
        case .cone: .cone()
        case .torus: .torus()
        default: nil
        }
    }

    /// The handles `builtin(_:)` knows, in registration order.
    public static let builtinHandles: [MeshHandle] = [.cube, .plane, .sphere, .cylinder, .capsule, .cone, .torus]
}
