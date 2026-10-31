/// Marks an entity that viewport clicks and marquees pass through (editor helpers, a floor
/// that shouldn't steal clicks). Saved with the scene like any other component.
public struct Unpickable: Component, Codable, Equatable, Sendable {
    public static let componentName = "Unpickable"
    public init() {}
}

/// Where the meshes `ScenePicker` tests against come from. `SceneRenderer` is one (it keeps a
/// CPU copy of every registered mesh); `PickMeshLibrary` is a standalone one.
@MainActor public protocol PickMeshSource: AnyObject {
    /// Local-space bounds of the mesh named by `mesh`, or nil if no such mesh exists. Called
    /// for every candidate entity, so it should be cheap.
    func pickBounds(_ mesh: MeshHandle) -> Bounds?
    /// The mesh's triangles, for entities whose bounds the ray hits.
    func pickGeometry(_ mesh: MeshHandle) -> MeshGeometry?
}

extension SceneRenderer: PickMeshSource {
    public func pickBounds(_ mesh: MeshHandle) -> Bounds? { prep.meshes[mesh.key] }
    public func pickGeometry(_ mesh: MeshHandle) -> MeshGeometry? { geometry(mesh) }
}

/// Meshes for picking without a `SceneRenderer` (tools, tests, servers). The built-in cube,
/// plane and sphere are registered from the start, like in `SceneRenderer`.
@MainActor public final class PickMeshLibrary: PickMeshSource {
    private var meshes: [String: (geometry: MeshGeometry, bounds: Bounds)] = [:]

    public init() {
        register(.cube(), key: MeshHandle.cube.key)
        register(.plane(), key: MeshHandle.plane.key)
        register(.sphere(), key: MeshHandle.sphere.key)
    }

    public func register(_ geometry: MeshGeometry, key: String) {
        meshes[key] = (geometry, geometry.bounds)
    }

    public func pickBounds(_ mesh: MeshHandle) -> Bounds? { meshes[mesh.key]?.bounds }
    public func pickGeometry(_ mesh: MeshHandle) -> MeshGeometry? { meshes[mesh.key]?.geometry }
}

/// The closest entity under a ray (`ScenePicker.pick`).
public struct PickHit: Sendable, Equatable {
    public var entity: Entity
    /// World-space hit point.
    public var point: Vec3
    /// Distance from the ray's origin.
    public var distance: Float
    /// World-space normal of the hit triangle, facing back along the ray.
    public var normal: Vec3
    /// Index of the triangle in the mesh (its indices start at `3 * triangle`).
    public var triangle: Int
}

/// Counters from the last pick.
public struct PickStats: Sendable, Equatable {
    /// Entities considered (visible, pickable, with a known mesh).
    public var entities = 0
    /// Entities whose world bounds the ray hit.
    public var boundsHits = 0
    /// Entities whose triangles were tested (the rest were farther than a hit already found).
    public var meshTests = 0
    public var triangleTests = 0
}

/// Finds entities under the pointer: the closest one along a ray, or all whose bounds fall
/// into a screen rectangle (marquee).
///
/// Entities qualify when they have a `GlobalTransform` and a visible `MeshRenderer` whose mesh
/// `meshes` knows, no `Unpickable`, and pass `filter`. Positions come from `GlobalTransform`,
/// so they are as of the last `world.update` / `propagateTransforms()`, i.e. what was drawn.
///
/// A pick tests the ray against every candidate's world bounds first, then, nearest bounds
/// first, against the triangles of each mesh in its local space (the ray is transformed by the
/// inverse model matrix, so non-uniform scale and parents are exact), stopping once the next
/// bounds start beyond the closest hit. Triangles count from both sides unless `cullsBackFaces`.
@MainActor
public final class ScenePicker {
    public var meshes: any PickMeshSource
    /// Extra condition an entity must meet (e.g. not locked, on a visible layer).
    public var filter: ((Entity) -> Bool)?
    /// Ignore triangles facing away from the ray (as the renderer culls single-sided ones).
    public var cullsBackFaces = false
    /// Screen-space icons (`ViewportBillboards`) that `pick(at:in:world:)` tests along with the
    /// meshes: a visible billboard under the point wins; one behind geometry (drawn faded) only
    /// when no mesh under the point is nearer. They must be laid out for the same view.
    public var billboards: ViewportBillboards?
    public private(set) var stats = PickStats()

    private struct Candidate {
        var entity: Entity
        var model: Mat4
        var mesh: MeshHandle
        var enter: Float
    }
    private var candidates: [Candidate] = []

    public init(meshes: any PickMeshSource) {
        self.meshes = meshes
    }

    /// The closest entity under `point` (viewport points) in `view`.
    public func pick(at point: Vec2, in view: ViewportProjection, world: World) -> PickHit? {
        let ray = view.ray(through: point)
        let meshHit = pick(ray, in: world)
        guard let billboard = billboards?.hit(at: point), world.isAlive(billboard.entity), isPickable(billboard.entity, in: world)
        else { return meshHit }
        if let meshHit, billboard.isOccluded, meshHit.distance < billboard.distance { return meshHit }
        return hit(for: billboard, ray: ray)
    }

    /// The closest entity hit by `ray`.
    public func pick(_ ray: Ray, in world: World) -> PickHit? {
        stats = PickStats()
        candidates.removeAll(keepingCapacity: true)
        world.query(GlobalTransform.self, MeshRenderer.self) { entity, transform, renderer in
            guard renderer.isVisible, let bounds = meshes.pickBounds(renderer.mesh), isPickable(entity, in: world) else { return }
            stats.entities += 1
            guard let (enter, _) = ray.intersect(bounds.transformed(by: transform.matrix)) else { return }
            candidates.append(Candidate(entity: entity, model: transform.matrix, mesh: renderer.mesh, enter: enter))
        }
        stats.boundsHits = candidates.count
        // Nearest bounds first; ties by entity so the result doesn't depend on store order.
        candidates.sort { $0.enter != $1.enter ? $0.enter < $1.enter : $0.entity.index < $1.entity.index }

        var best: PickHit?
        for candidate in candidates {
            if let best, candidate.enter > best.distance { break }
            guard let geometry = meshes.pickGeometry(candidate.mesh) else { continue }
            stats.meshTests += 1
            if let hit = intersect(ray, geometry, model: candidate.model, entity: candidate.entity, closerThan: best?.distance ?? .infinity) {
                best = hit
            }
        }
        return best
    }

    private func isPickable(_ entity: Entity, in world: World) -> Bool {
        !world.has(Unpickable.self, for: entity) && (filter?(entity) ?? true)
    }

    /// The closest triangle of `geometry` (placed by `model`) hit by `ray` nearer than `limit`.
    private func intersect(_ ray: Ray, _ geometry: MeshGeometry, model: Mat4, entity: Entity, closerThan limit: Float) -> PickHit? {
        // In local space, with an unnormalized direction: t stays the world distance.
        let inverse = model.inverse
        let o = inverse * Vec4(ray.origin, 1), d = inverse * Vec4(ray.direction, 0)
        let origin = Vec3(o.x, o.y, o.z), direction = Vec3(d.x, d.y, d.z)
        guard origin.x.isFinite, direction.x.isFinite else { return nil }  // a zero scale
        var best: (t: Float, triangle: Int)?
        var closest = limit
        let mirrored = Self.determinant(model) < 0
        geometry.vertices.withUnsafeBufferPointer { vertices in
            geometry.indices.withUnsafeBufferPointer { indices in
                let count = indices.count / 3
                stats.triangleTests += count
                for triangle in 0..<count {
                    let a = vertices[Int(indices[triangle * 3])].position
                    let b = vertices[Int(indices[triangle * 3 + 1])].position
                    let c = vertices[Int(indices[triangle * 3 + 2])].position
                    guard let hit = Ray.intersectTriangle(origin: origin, direction: direction, a, b, c), hit.t < closest else { continue }
                    // A mirroring model matrix flips the winding as seen in the world.
                    if cullsBackFaces && hit.frontFacing == mirrored { continue }
                    closest = hit.t
                    best = (hit.t, triangle)
                }
            }
        }
        guard let best else { return nil }
        let corners = (0..<3).map { k -> Vec3 in
            let p = model * Vec4(geometry.vertices[Int(geometry.indices[best.triangle * 3 + k])].position, 1)
            return Vec3(p.x, p.y, p.z)
        }
        var normal = normalize(cross(corners[1] - corners[0], corners[2] - corners[0]))
        if dot(normal, ray.direction) > 0 { normal = -normal }
        return PickHit(entity: entity, point: ray.point(at: best.t), distance: best.t, normal: normal, triangle: best.triangle)
    }

    /// Entities whose bounds (the mesh bounds as an oriented box) are at least partly inside
    /// `rect` (viewport points) and in front of the camera, in query order. Conservative near
    /// the rectangle's corners, like frustum culling.
    public func entities(in rect: UIRect, view: ViewportProjection, world: World) -> [Entity] {
        guard rect.width > 0, rect.height > 0 else { return [] }
        let frustum = Frustum(viewProjection: view.viewProjection(restrictedTo: rect))
        var result: [Entity] = []
        world.query(GlobalTransform.self, MeshRenderer.self) { entity, transform, renderer in
            guard renderer.isVisible, let bounds = meshes.pickBounds(renderer.mesh), isPickable(entity, in: world) else { return }
            if Self.intersects(frustum, bounds: bounds, model: transform.matrix) { result.append(entity) }
        }
        return result
    }

    /// The separating-plane test for the box `bounds` transformed by `model` (exact per plane).
    static func intersects(_ frustum: Frustum, bounds: Bounds, model m: Mat4) -> Bool {
        let c = m * Vec4(bounds.center, 1)
        let center = Vec3(c.x, c.y, c.z)
        let axes = [m.c0, m.c1, m.c2].enumerated().map { i, column in Vec3(column.x, column.y, column.z) * bounds.halfExtent[i] }
        for plane in frustum.planes {
            let normal = Vec3(plane.x, plane.y, plane.z)
            let reach = abs(dot(normal, axes[0])) + abs(dot(normal, axes[1])) + abs(dot(normal, axes[2]))
            if dot(normal, center) + plane.w < -reach { return false }
        }
        return true
    }

    static func determinant(_ m: Mat4) -> Float {
        dot(Vec3(m.c0.x, m.c0.y, m.c0.z), cross(Vec3(m.c1.x, m.c1.y, m.c1.z), Vec3(m.c2.x, m.c2.y, m.c2.z)))
    }
}
