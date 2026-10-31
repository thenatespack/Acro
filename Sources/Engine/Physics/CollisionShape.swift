// Collision shapes: the serializable description (`ColliderShape`) and the baked, scaled
// form the simulation uses (`Shape`): spheres and capsules are a core point / segment plus
// a radius; boxes, convex hulls and mesh triangles are convex polyhedra; triangle meshes
// keep a bounding volume hierarchy over their triangles.

/// Collision geometry in a collider's local space, before the entity's scale is applied.
public enum ColliderShape: Codable, Equatable, Sendable {
    /// A box from `-halfExtents` to `halfExtents` (`.box(halfExtents: Vec3(0.5))` fits `MeshHandle.cube`).
    case box(halfExtents: Vec3)
    /// A sphere around the origin (0.5 fits `MeshHandle.sphere`).
    case sphere(radius: Float)
    /// A capsule along local Y: a cylinder from `-halfHeight` to `halfHeight` with
    /// hemispherical caps, so its total height is `2 * (halfHeight + radius)`.
    case capsule(radius: Float, halfHeight: Float)
    /// The convex hull of `points`. Hulls are built once per collider by brute force, so keep
    /// them small (up to 64 points; extra points are dropped).
    case convexHull(points: [Vec3])
    /// A triangle mesh (counter-clockwise front faces, though collisions are two-sided). Only
    /// static and kinematic bodies may use it; on a dynamic body it acts as kinematic.
    case triangleMesh(vertices: [Vec3], indices: [UInt32])

    /// A box with half extents `h`.
    public static func box(_ h: Vec3) -> ColliderShape { .box(halfExtents: h) }
}

/// Mass, center of mass and inertia tensor (about the center of mass, in the shape's frame).
public struct MassProperties: Equatable, Sendable {
    public var mass: Float
    public var center: Vec3
    public var inertia: Mat3

    public init(mass: Float, center: Vec3 = .zero, inertia: Mat3) {
        self.mass = mass
        self.center = center
        self.inertia = inertia
    }
}

/// A convex polyhedron: vertices, outward faces (counter-clockwise from outside) and the
/// distinct edge directions SAT needs.
struct ConvexPolyhedron: Sendable {
    struct Face: Sendable {
        var normal: Vec3
        /// `dot(normal, p)` for points `p` on the face.
        var offset: Float
        var indices: [Int]
    }

    var vertices: [Vec3]
    var faces: [Face]
    /// Each edge once, as vertex index pairs, with the index of its direction.
    var edges: [(a: Int, b: Int, direction: Int)]
    /// Unit edge directions, parallel ones merged.
    var edgeDirections: [Vec3]
    var centroid: Vec3

    init(vertices: [Vec3], faces: [Face]) {
        self.vertices = vertices
        self.faces = faces
        centroid = vertices.reduce(Vec3.zero, +) / Float(max(vertices.count, 1))
        var edges: [(a: Int, b: Int, direction: Int)] = []
        var directions: [Vec3] = []
        for face in faces {
            for k in 0..<face.indices.count {
                let a = face.indices[k], b = face.indices[(k + 1) % face.indices.count]
                let (lo, hi) = (min(a, b), max(a, b))
                if edges.contains(where: { $0.a == lo && $0.b == hi }) { continue }
                let d = normalize(vertices[hi] - vertices[lo])
                var index = directions.firstIndex { abs(dot($0, d)) > 0.9999 }
                if index == nil {
                    directions.append(d)
                    index = directions.count - 1
                }
                edges.append((lo, hi, index!))
            }
        }
        self.edges = edges
        edgeDirections = directions
    }

    /// The box from `-h` to `h`.
    static func box(_ h: Vec3) -> ConvexPolyhedron {
        let v = (0..<8).map { i in Vec3(i & 1 == 0 ? -h.x : h.x, i & 2 == 0 ? -h.y : h.y, i & 4 == 0 ? -h.z : h.z) }
        func face(_ n: Vec3, _ offset: Float, _ indices: [Int]) -> Face { Face(normal: n, offset: offset, indices: indices) }
        return ConvexPolyhedron(vertices: v, faces: [
            face(Vec3(-1, 0, 0), h.x, [0, 4, 6, 2]), face(Vec3(1, 0, 0), h.x, [1, 3, 7, 5]),
            face(Vec3(0, -1, 0), h.y, [0, 1, 5, 4]), face(Vec3(0, 1, 0), h.y, [2, 6, 7, 3]),
            face(Vec3(0, 0, -1), h.z, [0, 2, 3, 1]), face(Vec3(0, 0, 1), h.z, [4, 5, 7, 6]),
        ])
    }

    /// A triangle as a flat polyhedron with a front and a back face.
    static func triangle(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> ConvexPolyhedron {
        let n = normalize(cross(b - a, c - a))
        return ConvexPolyhedron(vertices: [a, b, c], faces: [
            Face(normal: n, offset: dot(n, a), indices: [0, 1, 2]),
            Face(normal: -n, offset: -dot(n, a), indices: [0, 2, 1]),
        ])
    }

    /// The convex hull of `points` (at most 64 used), or nil if they are all (nearly) coplanar.
    /// Brute force: every plane through three points with all points on one side is a face
    /// plane; each face is the 2D hull of the points on it.
    static func hull(_ input: [Vec3]) -> ConvexPolyhedron? {
        var points: [Vec3] = []
        for p in input.prefix(64) where !points.contains(where: { lengthSquared($0 - p) < 1e-10 }) { points.append(p) }
        guard points.count >= 4 else { return nil }
        let extent = AABB(enclosing: points).halfExtent
        let eps = max(extent.x, extent.y, extent.z) * 1e-4
        var planes: [(normal: Vec3, offset: Float)] = []
        let n = points.count
        for i in 0..<n {
            for j in (i + 1)..<n {
                for k in (j + 1)..<n {
                    var normal = cross(points[j] - points[i], points[k] - points[i])
                    let len = length(normal)
                    if len < 1e-8 { continue }
                    normal /= len
                    var offset = dot(normal, points[i])
                    var above = false, below = false
                    for p in points {
                        let d = dot(normal, p) - offset
                        if d > eps { above = true } else if d < -eps { below = true }
                        if above && below { break }
                    }
                    if above && below { continue }
                    if above { normal = -normal; offset = -offset }
                    if planes.contains(where: { dot($0.normal, normal) > 0.9999 && abs($0.offset - offset) < eps }) { continue }
                    planes.append((normal, offset))
                }
            }
        }
        guard planes.count >= 4 else { return nil }
        // Keep only points that are corners of some face, then index faces into them.
        var faceLoops: [(normal: Vec3, offset: Float, loop: [Vec3])] = []
        for plane in planes {
            let onPlane = points.filter { abs(dot(plane.normal, $0) - plane.offset) <= eps }
            let loop = hull2D(onPlane, normal: plane.normal)
            if loop.count >= 3 { faceLoops.append((plane.normal, plane.offset, loop)) }
        }
        var vertices: [Vec3] = []
        var faces: [Face] = []
        for face in faceLoops {
            var indices: [Int] = []
            for p in face.loop {
                if let i = vertices.firstIndex(where: { lengthSquared($0 - p) < 1e-12 }) {
                    indices.append(i)
                } else {
                    vertices.append(p)
                    indices.append(vertices.count - 1)
                }
            }
            faces.append(Face(normal: face.normal, offset: face.offset, indices: indices))
        }
        return ConvexPolyhedron(vertices: vertices, faces: faces)
    }

    /// The convex polygon around coplanar `points`, counter-clockwise seen from the side
    /// `normal` points to (Andrew's monotone chain in the plane).
    private static func hull2D(_ points: [Vec3], normal: Vec3) -> [Vec3] {
        let (u, v) = tangentBasis(normal)
        let sorted = points.map { (p: $0, q: Vec2(dot($0, u), dot($0, v))) }
            .sorted { $0.q.x != $1.q.x ? $0.q.x < $1.q.x : $0.q.y < $1.q.y }
        guard sorted.count >= 3 else { return sorted.map(\.p) }
        func turn(_ o: Vec2, _ a: Vec2, _ b: Vec2) -> Float { (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) }
        var hull: [(p: Vec3, q: Vec2)] = []
        for pass in 0..<2 {
            let start = hull.count
            for item in (pass == 0 ? sorted : sorted.reversed()) {
                while hull.count >= start + 2 && turn(hull[hull.count - 2].q, hull[hull.count - 1].q, item.q) <= 1e-9 {
                    hull.removeLast()
                }
                hull.append(item)
            }
            hull.removeLast()
        }
        // (u, v, normal) is right-handed, so counter-clockwise in (u, v) is counter-clockwise from outside.
        return hull.map(\.p)
    }

    func transformed(by pose: Pose) -> ConvexPolyhedron {
        var copy = self
        copy.vertices = vertices.map(pose.transform)
        copy.centroid = pose.transform(centroid)
        copy.edgeDirections = edgeDirections.map { pose.rotation * $0 }
        for i in copy.faces.indices {
            let n = pose.rotation * faces[i].normal
            copy.faces[i].normal = n
            copy.faces[i].offset = faces[i].offset + dot(n, pose.position)
        }
        return copy
    }

    /// Mass properties of the solid at `density`: a fan of tetrahedra from the centroid,
    /// summing covariance matrices (Blow and Binstock, "How to find the inertia tensor").
    func massProperties(density: Float) -> MassProperties {
        let canonical = Mat3(Vec3(2, 1, 1), Vec3(1, 2, 1), Vec3(1, 1, 2)) * (1.0 / 120.0)
        let o = centroid
        var volume: Float = 0, weighted = Vec3.zero
        var covariance = Mat3.zero
        for face in faces {
            for k in 1..<(face.indices.count - 1) {
                let a = vertices[face.indices[0]] - o, b = vertices[face.indices[k]] - o, c = vertices[face.indices[k + 1]] - o
                let det = dot(a, cross(b, c))
                volume += det / 6
                weighted += (a + b + c) * (det / 24)
                let m = Mat3(a, b, c)
                covariance = covariance + m * canonical * m.transpose * det
            }
        }
        guard volume > 1e-12 else { return MassProperties(mass: 0, center: o, inertia: .zero) }
        let mass = density * volume
        let center = weighted / volume
        // Covariance about the centroid -> about the center of mass (parallel axis), then inertia.
        let c = covariance * density - Mat3.outer(center, center) * mass
        let inertia = Mat3.identity * c.trace - c
        return MassProperties(mass: mass, center: o + center, inertia: inertia)
    }
}

/// A collider shape baked at a scale: what collision detection works on. Immutable, so bodies
/// can share one.
final class Shape: @unchecked Sendable {
    enum Kind {
        case sphere
        /// Along local Y, cylinder half height.
        case capsule(halfHeight: Float)
        case polyhedron(ConvexPolyhedron)
        case mesh(TriangleMesh)
    }

    let kind: Kind
    /// Sphere and capsule radius; zero for the others.
    let radius: Float
    let localBounds: AABB
    /// The box's half extents, for the cheaper box raycast.
    let boxHalfExtents: Vec3?

    var isMesh: Bool { if case .mesh = kind { true } else { false } }
    /// The farthest a point of the shape gets from its origin (roughly).
    var extent: Float { max(length(localBounds.min), length(localBounds.max)) }

    /// Bakes `shape` at `scale` (a capsule scales its radius by the larger of x and z and its
    /// length by y; a sphere by the largest axis; hulls and meshes per vertex). Degenerate
    /// input gives a tiny sphere.
    init(_ shape: ColliderShape, scale: Vec3 = .one) {
        let s = absolute(scale)
        var boxHalf: Vec3?
        switch shape {
        case .box(let h):
            let h = pointwiseMax(absolute(h) * s, Vec3(repeating: 1e-4))
            kind = .polyhedron(.box(h))
            radius = 0
            boxHalf = h
            localBounds = AABB(min: -h, max: h)
        case .sphere(let r):
            radius = max(abs(r) * max(s.x, s.y, s.z), 1e-4)
            kind = .sphere
            localBounds = AABB(min: Vec3(repeating: -radius), max: Vec3(repeating: radius))
        case .capsule(let r, let hh):
            radius = max(abs(r) * max(s.x, s.z), 1e-4)
            let h = abs(hh) * s.y
            kind = .capsule(halfHeight: h)
            localBounds = AABB(min: -Vec3(radius, h + radius, radius), max: Vec3(radius, h + radius, radius))
        case .convexHull(let points):
            if let hull = ConvexPolyhedron.hull(points.map { $0 * scale }) {
                kind = .polyhedron(hull)
                radius = 0
                localBounds = AABB(enclosing: hull.vertices)
            } else {
                kind = .sphere
                radius = 0.01
                localBounds = AABB(min: Vec3(repeating: -0.01), max: Vec3(repeating: 0.01))
            }
        case .triangleMesh(let vertices, let indices):
            let mesh = TriangleMesh(vertices: vertices.map { $0 * scale }, indices: indices)
            kind = .mesh(mesh)
            radius = 0
            localBounds = mesh.bounds
        }
        boxHalfExtents = boxHalf
    }

    /// The core of a convex shape in local space: the points whose hull, grown by `radius`, is
    /// the shape (a point for a sphere, a segment for a capsule, the vertices of a polyhedron).
    var corePoints: [Vec3] {
        switch kind {
        case .sphere: [.zero]
        case .capsule(let h): [Vec3(0, -h, 0), Vec3(0, h, 0)]
        case .polyhedron(let p): p.vertices
        case .mesh: []
        }
    }

    func bounds(at pose: Pose) -> AABB {
        switch kind {
        case .sphere:
            return AABB(min: pose.position - Vec3(repeating: radius), max: pose.position + Vec3(repeating: radius))
        case .capsule(let h):
            let axis = pose.rotation * Vec3(0, h, 0)
            let a = pose.position - axis, b = pose.position + axis
            return AABB(min: pointwiseMin(a, b) - Vec3(repeating: radius), max: pointwiseMax(a, b) + Vec3(repeating: radius))
        case .polyhedron, .mesh:
            // The local box rotated: |R| * half extent around the rotated center.
            let m = Mat3(pose.rotation)
            let c = pose.transform(localBounds.center)
            let e = m.transformExtent(localBounds.halfExtent)
            return AABB(min: c - e, max: c + e)
        }
    }

    /// Mass properties at `density` (zero for meshes).
    func massProperties(density: Float) -> MassProperties {
        switch kind {
        case .sphere:
            let m = density * 4 / 3 * .pi * radius * radius * radius
            return MassProperties(mass: m, inertia: Mat3(diagonal: Vec3(repeating: 0.4 * m * radius * radius)))
        case .capsule(let h):
            let r = radius
            let cylinder = density * .pi * r * r * 2 * h
            let caps = density * 4 / 3 * .pi * r * r * r
            let iy = cylinder * r * r / 2 + caps * 0.4 * r * r
            let ix = cylinder * (r * r / 4 + h * h / 3) + caps * (0.4 * r * r + h * h + 0.75 * h * r)
            return MassProperties(mass: cylinder + caps, inertia: Mat3(diagonal: Vec3(ix, iy, ix)))
        case .polyhedron(let p):
            if let h = boxHalfExtents {
                let m = density * 8 * h.x * h.y * h.z
                let d = h * h
                return MassProperties(mass: m, inertia: Mat3(diagonal: Vec3(d.y + d.z, d.x + d.z, d.x + d.y) * (m / 3)))
            }
            return p.massProperties(density: density)
        case .mesh:
            return MassProperties(mass: 0, inertia: .zero)
        }
    }
}

extension ColliderShape {
    /// The faces of a `.convexHull`'s hull as polygons (counter-clockwise seen from outside),
    /// e.g. to build a render mesh that matches the collider. Empty for other shapes.
    public var hullFaces: [[Vec3]] {
        guard case .convexHull(let points) = self, let hull = ConvexPolyhedron.hull(points) else { return [] }
        return hull.faces.map { face in face.indices.map { hull.vertices[$0] } }
    }
}
