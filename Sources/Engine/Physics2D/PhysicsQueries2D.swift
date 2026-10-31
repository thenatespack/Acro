import Foundation

// Scene queries of the 2D physics: ray casts, circle casts and overlap tests. Results are in a
// deterministic order (by distance, ties by creation order; overlaps by body slot). A ray that
// starts inside a collider hits it at distance 0 with the normal pointing back at the ray.

extension PhysicsWorld2D {
    private func accepts(_ f: Fixture2D, _ filter: QueryFilter2D) -> Bool {
        guard f.layer & filter.mask != 0, filter.includeTriggers || !f.isTrigger else { return false }
        return filter.excluding.isEmpty || !filter.excluding.contains(id(f.body))
    }

    /// The nearest hit of the ray `origin + t * direction` (t in 0...maxDistance).
    public func raycast(from origin: Vec2, direction: Vec2, maxDistance: Float = .infinity,
                        filter: QueryFilter2D = .default) -> RaycastHit2D? {
        castRay(origin: origin, direction: direction, maxDistance: maxDistance, extra: 0, filter: filter, all: false).first
    }

    /// Every hit along the ray, nearest first (one per collider).
    public func raycastAll(from origin: Vec2, direction: Vec2, maxDistance: Float = .infinity,
                           filter: QueryFilter2D = .default) -> [RaycastHit2D] {
        castRay(origin: origin, direction: direction, maxDistance: maxDistance, extra: 0, filter: filter, all: true)
    }

    /// Sweeps a circle of `radius` from `origin` along `direction`; the nearest thing it
    /// touches. `point` is the touching point on the surface.
    public func circleCast(radius: Float, from origin: Vec2, direction: Vec2, maxDistance: Float,
                           filter: QueryFilter2D = .default) -> RaycastHit2D? {
        var hit = castRay(origin: origin, direction: direction, maxDistance: maxDistance, extra: max(radius, 0), filter: filter,
                          all: false).first
        if hit != nil { hit!.point -= hit!.normal * radius }
        return hit
    }

    private func castRay(origin: Vec2, direction: Vec2, maxDistance: Float, extra: Float, filter: QueryFilter2D,
                         all: Bool) -> [RaycastHit2D] {
        let d = normalize2(direction)
        guard d != .zero, maxDistance >= 0 else { return [] }
        let maxT = maxDistance.isFinite ? maxDistance : 1e9
        var hits: [(hit: RaycastHit2D, fixture: Int)] = []
        func test(_ f: Int) -> Float? {
            let fixture = fixtures[f]
            guard accepts(fixture, filter) else { return nil }
            let body = bodies[fixture.body]
            let local = fixture.geom.castRay(origin: body.pose.inverseTransform(origin), direction: body.pose.rotation.inverseRotate(d),
                                             maxT: maxT, extra: extra)
            guard let (t, normal) = local else { return nil }
            hits.append((RaycastHit2D(body: id(fixture.body), entity: body.entity, point: origin + d * t,
                                      normal: body.pose.rotation.rotate(normal), distance: t), f))
            return t
        }
        if extra == 0 {
            var limit = maxT
            tree.raycast(origin: origin, direction: d, maxT: maxT) { f in
                if let t = test(f), !all { limit = min(limit, t) }
                return limit
            }
        } else {
            // The swept box of the cast.
            let end = origin + d * maxT
            let box = AABB2(min: Vec2(min(origin.x, end.x), min(origin.y, end.y)), max: Vec2(max(origin.x, end.x), max(origin.y, end.y)))
            tree.query(box.expanded(by: extra)) { f in
                _ = test(f)
                return true
            }
        }
        // One hit per body is not promised: a chain's segments each report; keep the nearest per body.
        hits.sort { $0.hit.distance != $1.hit.distance ? $0.hit.distance < $1.hit.distance : $0.fixture < $1.fixture }
        var result: [RaycastHit2D] = []
        var seen: Set<Body2DID> = []
        for h in hits where seen.insert(h.hit.body).inserted { result.append(h.hit) }
        return all ? result : Array(result.prefix(1))
    }

    /// The bodies whose collider contains the point, by body slot.
    public func overlapPoint(_ point: Vec2, filter: QueryFilter2D = .default) -> [Body2DID] {
        overlapCircle(center: point, radius: 0, filter: filter)
    }

    /// The bodies whose collider touches the circle, by body slot.
    public func overlapCircle(center: Vec2, radius: Float, filter: QueryFilter2D = .default) -> [Body2DID] {
        let box = AABB2(min: center - Vec2(repeating: radius), max: center + Vec2(repeating: radius))
        var found: Set<Int> = []
        tree.query(box) { f in
            let fixture = fixtures[f]
            if accepts(fixture, filter) {
                let body = bodies[fixture.body]
                let local = body.pose.inverseTransform(center)
                if fixture.geom.distance(to: local).distance <= radius + fixture.geom.radius { found.insert(fixture.body) }
            }
            return true
        }
        return found.sorted().map(id)
    }

    /// The bodies whose collider touches the box (`angle` radians about its center), by body slot.
    public func overlapBox(center: Vec2, halfExtents: Vec2, angle: Float = 0, filter: QueryFilter2D = .default) -> [Body2DID] {
        let pose = Pose2D(position: center, angle: angle)
        guard let query = ColliderShape2D.box(halfExtents: halfExtents).geoms(offset: .identity).first else { return [] }
        var found: Set<Int> = []
        tree.query(query.bounds(at: pose)) { f in
            let fixture = fixtures[f]
            if accepts(fixture, filter),
               let m = Narrowphase2D.collide(query, pose, fixture.geom, bodies[fixture.body].pose, margin: 0, slop: linearSlop),
               m.points.contains(where: { $0.separation <= 0 }) {
                found.insert(fixture.body)
            }
            return true
        }
        return found.sorted().map(id)
    }
}
