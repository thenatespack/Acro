// Scene queries: raycasts (closest and all), shape casts and overlap tests, all through the
// broadphase tree and filtered by layer mask, triggers and an exclusion list. Results are
// sorted by distance, ties by body, so they are deterministic.

extension PhysicsWorld {
    /// The closest body hit by `ray` within `maxDistance`.
    public func raycast(_ ray: Ray, maxDistance: Float = .infinity, filter: QueryFilter = .default) -> RaycastHit? {
        var best: RaycastHit?
        let limit = maxDistance.isFinite ? maxDistance : 1e9
        tree.raycast(origin: ray.origin, direction: ray.direction, maxT: limit) { i in
            guard accepts(i, filter), let hit = raycast(body: i, ray, maxDistance: best?.distance ?? limit) else {
                return best?.distance ?? limit
            }
            if best == nil || hit.distance < best!.distance || (hit.distance == best!.distance && hit.body < best!.body) {
                best = hit
            }
            return best!.distance
        }
        return best
    }

    /// Every body hit by `ray` within `maxDistance` (the nearest hit on each), nearest first.
    public func raycastAll(_ ray: Ray, maxDistance: Float = .infinity, filter: QueryFilter = .default) -> [RaycastHit] {
        var hits: [RaycastHit] = []
        let limit = maxDistance.isFinite ? maxDistance : 1e9
        tree.raycast(origin: ray.origin, direction: ray.direction, maxT: limit) { i in
            if accepts(i, filter), let hit = raycast(body: i, ray, maxDistance: limit) { hits.append(hit) }
            return limit
        }
        return hits.sorted { $0.distance != $1.distance ? $0.distance < $1.distance : $0.body < $1.body }
    }

    /// Sweeps `shape` (convex: box, sphere, capsule or hull) from `pose` along `direction` up
    /// to `maxDistance`; returns the first body it touches. A shape that already overlaps
    /// something hits it at distance 0.
    public func shapeCast(_ shape: ColliderShape, pose: Pose, direction: Vec3, maxDistance: Float,
                          filter: QueryFilter = .default) -> RaycastHit? {
        let baked = Shape(shape, scale: .one)
        guard let moving = WorldConvex(baked, pose), maxDistance > 0 else { return nil }
        let dir = normalize(direction)
        let translation = dir * maxDistance
        let swept = baked.bounds(at: pose).swept(by: translation)
        var best: RaycastHit?
        tree.query(swept) { i in
            guard accepts(i, filter), let target = bodies[i].shape else { return true }
            let targetPose = bodies[i].shapePose
            var hit: (fraction: Float, point: Vec3, normal: Vec3, triangle: Int?)?
            castAgainst(target, targetPose, moving, translation, swept) { h in
                if hit == nil || h.fraction < hit!.fraction { hit = h }
            }
            if let hit {
                let candidate = RaycastHit(body: id(i), entity: bodies[i].entity, point: hit.point, normal: hit.normal,
                                           distance: hit.fraction * maxDistance, triangle: hit.triangle)
                if best == nil || candidate.distance < best!.distance || (candidate.distance == best!.distance && candidate.body < best!.body) {
                    best = candidate
                }
            }
            return true
        }
        return best
    }

    /// Casts `moving` against `target` (a compound's parts one by one), reporting each hit.
    private func castAgainst(_ target: Shape, _ targetPose: Pose, _ moving: WorldConvex, _ translation: Vec3, _ swept: AABB,
                             _ found: ((fraction: Float, point: Vec3, normal: Vec3, triangle: Int?)) -> Void) {
        switch target.kind {
        case .compound(let parts):
            for part in parts { castAgainst(part.shape, targetPose * part.pose, moving, translation, swept, found) }
        case .mesh(let mesh):
            mesh.forEachTriangle(overlapping: Narrowphase.localBounds(swept, in: targetPose)) { t in
                let (a, b, c) = mesh.triangle(t)
                let tri = WorldConvex.triangle(targetPose.transform(a), targetPose.transform(b), targetPose.transform(c))
                if let h = castConvex(moving, translation: translation, against: tri) { found((h.fraction, h.point, h.normal, t)) }
            }
        default:
            if let h = castConvex(moving, translation: translation, against: WorldConvex(target, targetPose)!) {
                found((h.fraction, h.point, h.normal, nil))
            }
        }
    }

    /// `shapeCast` with a sphere.
    public func sphereCast(center: Vec3, radius: Float, direction: Vec3, maxDistance: Float,
                           filter: QueryFilter = .default) -> RaycastHit? {
        shapeCast(.sphere(radius: radius), pose: Pose(position: center), direction: direction, maxDistance: maxDistance, filter: filter)
    }

    /// `shapeCast` with a box.
    public func boxCast(center: Vec3, halfExtents: Vec3, rotation: Quat = .identity, direction: Vec3, maxDistance: Float,
                        filter: QueryFilter = .default) -> RaycastHit? {
        shapeCast(.box(halfExtents: halfExtents), pose: Pose(position: center, rotation: rotation), direction: direction,
                  maxDistance: maxDistance, filter: filter)
    }

    /// Bodies whose collider overlaps `shape` at `pose`, in body order.
    public func overlap(_ shape: ColliderShape, pose: Pose, filter: QueryFilter = .default) -> [BodyID] {
        let baked = Shape(shape, scale: .one)
        var found: [Int] = []
        tree.query(baked.bounds(at: pose)) { i in
            guard accepts(i, filter), let target = bodies[i].shape else { return true }
            let points = Narrowphase.collide(baked, pose, target, bodies[i].shapePose, margin: 0)
            if points.contains(where: { $0.separation <= 0 }) { found.append(i) }
            return true
        }
        return found.sorted().map(id)
    }

    public func overlapSphere(center: Vec3, radius: Float, filter: QueryFilter = .default) -> [BodyID] {
        overlap(.sphere(radius: radius), pose: Pose(position: center), filter: filter)
    }

    public func overlapBox(center: Vec3, halfExtents: Vec3, rotation: Quat = .identity, filter: QueryFilter = .default) -> [BodyID] {
        overlap(.box(halfExtents: halfExtents), pose: Pose(position: center, rotation: rotation), filter: filter)
    }

    /// Bodies whose collider's bounding box overlaps `box` (cheap; no exact shape test).
    public func overlapBounds(_ box: AABB, filter: QueryFilter = .default) -> [BodyID] {
        var found: [Int] = []
        tree.query(box) { i in
            if accepts(i, filter), let shape = bodies[i].shape, shape.bounds(at: bodies[i].shapePose).overlaps(box) { found.append(i) }
            return true
        }
        return found.sorted().map(id)
    }

    // MARK: - Internals

    func accepts(_ i: Int, _ filter: QueryFilter) -> Bool {
        let b = bodies[i]
        guard b.isAlive, b.shape != nil, b.layer & filter.mask != 0 else { return false }
        if b.isTrigger && !filter.includeTriggers { return false }
        return filter.excluding.isEmpty || !filter.excluding.contains(id(i))
    }

    private func raycast(body i: Int, _ ray: Ray, maxDistance: Float) -> RaycastHit? {
        guard let shape = bodies[i].shape else { return nil }
        let pose = bodies[i].shapePose
        // In the shape's local space.
        let o = pose.inverseTransform(ray.origin), d = pose.rotation.conjugate * ray.direction
        guard let r = Self.raycastLocal(shape, o, d, maxT: maxDistance), r.t <= maxDistance else { return nil }
        return RaycastHit(body: id(i), entity: bodies[i].entity, point: ray.point(at: r.t), normal: pose.rotation * r.normal,
                          distance: r.t, triangle: r.triangle)
    }

    /// Ray (unit `d`) against `shape` in its own space; a compound's nearest part.
    private static func raycastLocal(_ shape: Shape, _ o: Vec3, _ d: Vec3, maxT: Float) -> (t: Float, normal: Vec3, triangle: Int?)? {
        switch shape.kind {
        case .sphere:
            return raySphere(o, d, .zero, shape.radius).map { ($0.t, $0.normal, nil) }
        case .capsule(let h):
            return rayCapsule(o, d, Vec3(0, -h, 0), Vec3(0, h, 0), shape.radius).map { ($0.t, $0.normal, nil) }
        case .polyhedron(let p):
            return rayPolyhedron(o, d, p, maxT: maxT).map { ($0.t, $0.normal, nil) }
        case .mesh(let mesh):
            return mesh.raycast(origin: o, direction: d, maxT: maxT).map { ($0.t, $0.normal, $0.triangle) }
        case .compound(let parts):
            var best: (t: Float, normal: Vec3, triangle: Int?)?
            for part in parts {
                let po = part.pose.inverseTransform(o), pd = part.pose.rotation.conjugate * d
                if let hit = raycastLocal(part.shape, po, pd, maxT: best?.t ?? maxT), best == nil || hit.t < best!.t {
                    best = (hit.t, part.pose.rotation * hit.normal, nil)
                }
            }
            return best
        }
    }

    /// Ray (unit `d`) against a sphere; an origin inside hits at 0 facing back along the ray.
    static func raySphere(_ o: Vec3, _ d: Vec3, _ c: Vec3, _ r: Float) -> (t: Float, normal: Vec3)? {
        let m = o - c
        let cc = dot(m, m) - r * r
        if cc <= 0 { return (0, -d) }
        let b = dot(m, d)
        if b > 0 { return nil }
        let disc = b * b - cc
        if disc < 0 { return nil }
        let t = -b - disc.squareRoot()
        return (max(t, 0), normalize(m + d * t))
    }

    static func rayCapsule(_ o: Vec3, _ d: Vec3, _ a: Vec3, _ b: Vec3, _ r: Float) -> (t: Float, normal: Vec3)? {
        if lengthSquared(o - closestPointOnSegment(o, a, b)) <= r * r { return (0, -d) }
        var best: (t: Float, normal: Vec3)?
        for c in [a, b] {
            if let hit = raySphere(o, d, c, r), best == nil || hit.t < best!.t { best = hit }
        }
        // The cylinder: solve in the plane perpendicular to the axis.
        let axis = b - a
        let len2 = dot(axis, axis)
        if len2 > 1e-12 {
            let m = o - a
            let dp = d - axis * (dot(d, axis) / len2), mp = m - axis * (dot(m, axis) / len2)
            let qa = dot(dp, dp), qb = dot(mp, dp), qc = dot(mp, mp) - r * r
            let disc = qb * qb - qa * qc
            if qa > 1e-12 && disc >= 0 {
                let t = (-qb - disc.squareRoot()) / qa
                let p = o + d * t
                let s = dot(p - a, axis) / len2
                if t >= 0 && s >= 0 && s <= 1 && (best == nil || t < best!.t) {
                    best = (t, normalize(p - (a + axis * s)))
                }
            }
        }
        return best
    }

    /// Cyrus–Beck clipping of the ray against the face planes.
    static func rayPolyhedron(_ o: Vec3, _ d: Vec3, _ p: ConvexPolyhedron, maxT: Float) -> (t: Float, normal: Vec3)? {
        var enter: Float = 0, exit = maxT
        var normal = -d
        for f in p.faces {
            let denom = dot(f.normal, d)
            let dist = f.offset - dot(f.normal, o)
            if abs(denom) < 1e-12 {
                if dist < 0 { return nil }
                continue
            }
            let t = dist / denom
            if denom < 0 {
                if t > enter {
                    enter = t
                    normal = f.normal
                }
            } else {
                exit = min(exit, t)
            }
            if enter > exit { return nil }
        }
        return (enter, normal)
    }
}
