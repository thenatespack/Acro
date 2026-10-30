// Shared inputs of the editor viewport tools (`ScenePicker`, `SelectionOutlineRenderer`,
// `TransformGizmo`): the view they work in, the pointer, the selection, and the ray and
// intersection math they are built on. Nothing here depends on an editor app; hosts feed
// plain values every frame.

/// A half-line from `origin` along `direction` (unit length).
public struct Ray: Sendable, Equatable {
    public var origin: Vec3
    /// Unit length, so `t` in `point(at:)` is a distance.
    public var direction: Vec3

    /// `direction` is normalized.
    public init(origin: Vec3, direction: Vec3) {
        self.origin = origin
        self.direction = normalize(direction)
    }

    public func point(at t: Float) -> Vec3 { origin + direction * t }

    /// Where the ray enters and leaves an axis-aligned box (slab test), as distances along it,
    /// or nil if it misses or the box is behind the origin. `enter` is 0 when the origin is inside.
    public func intersect(_ bounds: Bounds) -> (enter: Float, exit: Float)? {
        Self.intersect(origin: origin, direction: direction, bounds: bounds)
    }

    /// The slab test for any direction (not necessarily unit length; distances are then in
    /// multiples of it). Axes the direction is parallel to only pass if the origin is inside
    /// the slab.
    static func intersect(origin: Vec3, direction: Vec3, bounds: Bounds) -> (enter: Float, exit: Float)? {
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
    public func intersect(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> Float? {
        Self.intersectTriangle(origin: origin, direction: direction, a, b, c)?.t
    }

    /// Möller–Trumbore for any direction: the hit's ray parameter `t` and barycentrics (u, v)
    /// of b and c, and whether the triangle faces the ray (counter-clockwise seen from the origin).
    static func intersectTriangle(origin: Vec3, direction: Vec3, _ a: Vec3, _ b: Vec3, _ c: Vec3)
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
    public func intersectPlane(point: Vec3, normal: Vec3) -> Float? {
        let n = normalize(normal)
        let denominator = dot(direction, n)
        guard abs(denominator) > 1e-6 else { return nil }
        let t = dot(point - origin, n) / denominator
        return t >= 0 ? t : nil
    }

    /// The parameter `s` of the point on the infinite line `linePoint + s * lineDirection`
    /// (unit direction) closest to this ray (treated as a full line), or nil when they are
    /// (nearly) parallel. The constraint math of axis drags.
    public func closestParameter(onLine linePoint: Vec3, direction lineDirection: Vec3) -> Float? {
        let a = normalize(lineDirection)
        let b = dot(a, direction)
        let denominator = 1 - b * b
        guard denominator > 1e-6 else { return nil }
        let w = linePoint - origin
        return (b * dot(direction, w) - dot(a, w)) / denominator
    }
}

/// A pointer event in a viewport.
public struct ViewportPointer: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        /// Moved with the primary button up (hover).
        case moved
        /// The primary button went down.
        case pressed
        /// Moved with the primary button down.
        case dragged
        /// The primary button went up.
        case released
    }

    /// Viewport points, origin at the top left, y down.
    public var position: Vec2
    public var phase: Phase
    public var modifiers: KeyModifiers

    public init(position: Vec2, phase: Phase, modifiers: KeyModifiers = []) {
        self.position = position
        self.phase = phase
        self.modifiers = modifiers
    }
}

/// The camera and size of a viewport, in the units the tools work in: points with the origin
/// at the top left (y down), like the UI and `Input.mousePosition`. `pixelScale` converts to
/// the pixels of the render target (`engine.ui.scale` for a target sized with
/// `resize(toPoints:scale:)`).
///
/// Clip conventions are the engine's: right-handed, clip depth 0 at the near plane and 1 at
/// the far one (swapped with `reversedZ`), y up in clip space.
public struct ViewportProjection: Sendable {
    /// World to camera.
    public let view: Mat4
    public let projection: Mat4
    public let reversedZ: Bool
    /// Viewport size in points.
    public let size: Vec2
    /// Render-target pixels per point.
    public let pixelScale: Float

    public init(view: Mat4, projection: Mat4, reversedZ: Bool = false, size: Vec2, pixelScale: Float = 1) {
        self.view = view
        self.projection = projection
        self.reversedZ = reversedZ
        self.size = Vec2(max(size.x, 1), max(size.y, 1))
        self.pixelScale = max(pixelScale, 1e-3)
        viewProjection = projection * view
        inverseViewProjection = viewProjection.inverse
        let e = view.inverse.c3
        eye = Vec3(e.x, e.y, e.z)
        forward = normalize(-Vec3(view.c0.z, view.c1.z, view.c2.z))
    }

    /// The view a `SceneRenderer.renderView` draws, shown at `size` points.
    public init(_ sceneView: SceneView, size: Vec2, pixelScale: Float = 1) {
        self.init(view: sceneView.view, projection: sceneView.projection, reversedZ: sceneView.reversedZ, size: size,
                  pixelScale: pixelScale)
    }

    public let viewProjection: Mat4
    public let inverseViewProjection: Mat4
    /// The camera position.
    public let eye: Vec3
    /// The direction the camera looks in (unit).
    public let forward: Vec3

    /// Whether the projection is perspective (clip w depends on depth).
    public var isPerspective: Bool { projection.c2.w != 0 }

    /// The size of the render target in pixels.
    public var pixelSize: (width: Int, height: Int) {
        RenderTargetSizing.pixels(points: size, scale: pixelScale)
    }

    /// Normalized device coordinates (x right, y up, both -1...1) of a point in points.
    public func ndc(_ point: Vec2) -> Vec2 {
        Vec2(point.x / size.x * 2 - 1, 1 - point.y / size.y * 2)
    }

    /// The world position at `point` and clip depth `depth` (0 near, 1 far; the other way
    /// round with reversed-Z), or nil where the projection has no finite point (an infinite far plane).
    public func unproject(_ point: Vec2, depth: Float) -> Vec3? {
        let n = ndc(point)
        let h = inverseViewProjection * Vec4(n.x, n.y, depth, 1)
        guard abs(h.w) > 1e-20 else { return nil }
        return Vec3(h.x, h.y, h.z) / h.w
    }

    /// The ray from the near plane through `point` (in points). For a perspective projection
    /// it points away from the eye; for an orthographic one it is parallel to `forward`.
    public func ray(through point: Vec2) -> Ray {
        let nearDepth: Float = reversedZ ? 1 : 0, farDepth: Float = reversedZ ? 0 : 1
        let n = ndc(point)
        let hNear = inverseViewProjection * Vec4(n.x, n.y, nearDepth, 1)
        let hFar = inverseViewProjection * Vec4(n.x, n.y, farDepth, 1)
        let near = Vec3(hNear.x, hNear.y, hNear.z) / hNear.w
        var direction: Vec3
        if abs(hFar.w) > 1e-12 * max(abs(hFar.x), abs(hFar.y), abs(hFar.z), 1) {
            direction = Vec3(hFar.x, hFar.y, hFar.z) / hFar.w - near
        } else {
            direction = Vec3(hFar.x, hFar.y, hFar.z)  // far plane at infinity: a direction
        }
        if dot(direction, forward) < 0 { direction = -direction }
        return Ray(origin: near, direction: direction)
    }

    /// Clip-space position of a world point.
    public func clip(_ world: Vec3) -> Vec4 { viewProjection * Vec4(world, 1) }

    /// Whether a world point is in front of the near plane.
    public func isInFront(_ world: Vec3) -> Bool {
        let c = clip(world)
        return c.w > 0 && (reversedZ ? c.z <= c.w : c.z >= 0)
    }

    /// A world point in viewport points (and its clip w), or nil behind the camera.
    public func project(_ world: Vec3) -> Vec2? {
        let c = clip(world)
        guard c.w > 1e-6 else { return nil }
        return Vec2((c.x / c.w + 1) * 0.5 * size.x, (1 - c.y / c.w) * 0.5 * size.y)
    }

    /// World units per point at `world`'s depth: multiply a size in points by this to get a
    /// world size that looks that big on screen (constant-screen-size gizmos). nil behind the camera.
    public func worldUnitsPerPoint(at world: Vec3) -> Float? {
        let w = clip(world).w
        guard w > 1e-6 else { return nil }
        // A world length L at clip w spans L * P[1][1] / w in NDC, i.e. L * P[1][1] * height / (2 w) points.
        return 2 * w / (abs(projection.c1.y) * size.y)
    }

    /// The unit direction from `world` toward the viewer: toward the eye for a perspective
    /// projection, against `forward` for an orthographic one.
    public func directionToViewer(from world: Vec3) -> Vec3 {
        guard isPerspective else { return -forward }
        let d = eye - world
        return dot(d, d) > 1e-12 ? normalize(d) : -forward
    }

    /// The view-projection whose clip volume is the part of this view inside `rect` (in
    /// points), for selecting what a marquee covers with `Frustum`.
    public func viewProjection(restrictedTo rect: UIRect) -> Mat4 {
        let lo = ndc(Vec2(rect.x, rect.maxY)), hi = ndc(Vec2(rect.maxX, rect.y))
        let scale = Vec2(2 / max(hi.x - lo.x, 1e-6), 2 / max(hi.y - lo.y, 1e-6))
        let offset = -(lo + hi) / 2 * scale
        // x' = x * sx + w * ox (and y), applied in clip space.
        let crop = Mat4(Vec4(scale.x, 0, 0, 0), Vec4(0, scale.y, 0, 0), Vec4(0, 0, 1, 0), Vec4(offset.x, offset.y, 0, 1))
        return crop * viewProjection
    }
}

/// An ordered set of selected entities by `EntityID`, the last one being the primary (active)
/// selection. A convenience for hosts; the tools themselves take `[Entity]` plus a primary.
public struct EditorSelection: Sendable, Equatable {
    public private(set) var ids: [EntityID] = []

    public init(_ ids: [EntityID] = []) {
        for id in ids { add(id) }
    }

    /// The most recently selected entity.
    public var primary: EntityID? { ids.last }
    public var isEmpty: Bool { ids.isEmpty }
    public func contains(_ id: EntityID) -> Bool { ids.contains(id) }

    /// Selects only `id` (nil clears).
    public mutating func select(_ id: EntityID?) { ids = id.map { [$0] } ?? [] }
    /// Adds `id` (or makes it the primary if already selected).
    public mutating func add(_ id: EntityID) {
        ids.removeAll { $0 == id }
        ids.append(id)
    }
    /// Removes `id` if selected, else adds it as the primary.
    public mutating func toggle(_ id: EntityID) {
        if contains(id) { remove(id) } else { add(id) }
    }
    public mutating func remove(_ id: EntityID) { ids.removeAll { $0 == id } }
    public mutating func clear() { ids = [] }

    /// The live entities, in selection order (ids without a live entity are skipped).
    @MainActor public func entities(in world: World) -> [Entity] { ids.compactMap { world.entity(for: $0) } }
    @MainActor public func primaryEntity(in world: World) -> Entity? { primary.flatMap { world.entity(for: $0) } }

    /// A click on `entity` (nil: empty space) with `modifiers`: shift toggles it in the
    /// selection, otherwise it becomes the only selected entity. Gives it an id if needed.
    @MainActor public mutating func click(_ entity: Entity?, modifiers: KeyModifiers, in world: World) {
        let id = entity.flatMap { world.ensureID(of: $0) }
        if modifiers.contains(.shift) {
            if let id { toggle(id) }
        } else {
            select(id)
        }
    }
}
