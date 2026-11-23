// Continuous collision and contact queries.
//
// Continuous collision (`RigidBody.continuous`): speculative contacts already stop most fast
// bodies, but a small body moving several meters per step (a bullet), or a thin spinning one,
// can skip past a thin wall between two steps. After the solver moves the bodies, each awake
// continuous body that went further than half its smallest size is swept (a shape cast, its
// start rotation) from its pose before the step to its pose after it; if something solid was in
// the way, the body is put back just in front of it and its velocity into the surface is removed
// (or bounced, by the pair's restitution). The next step's contact then pushes and bounces as
// usual. Bodies it already touched at the start are left to the solver. Serial, in body order,
// so it is deterministic.
import EngineCore
import EngineGraphics
import EngineScene

/// A touching contact whose bodies slide along each other (`PhysicsWorld.slidingContacts`).
public struct ContactSlide: Equatable, Sendable {
    public var bodyA: BodyID
    public var bodyB: BodyID
    public var entityA: Entity?
    public var entityB: Entity?
    /// The manifold's center and normal (from A to B).
    public var point: Vec3
    public var normal: Vec3
    /// The relative speed along the surface, m/s.
    public var speed: Float
}

extension PhysicsWorld {
    /// The velocity of body `b`'s material at `p` (kinematic bodies: how they moved last step).
    nonisolated static func pointVelocity(_ b: Body, _ p: Vec3) -> Vec3 {
        switch b.motion {
        case .static: .zero
        case .kinematic: b.linearVelocity + cross(b.angularVelocity, p - b.center)
        case .dynamic: b.linearVelocity + cross(b.angularVelocity, p - b.center)
        }
    }

    /// Touching contacts (not triggers) whose bodies slide along each other faster than
    /// `minSpeed`, in contact order: what scrape effects play for.
    public func slidingContacts(minSpeed: Float = 0.1) -> [ContactSlide] {
        var found: [ContactSlide] = []
        for c in contacts where c.touching && !c.isTrigger && !c.points.isEmpty {
            let a = bodies[c.a], b = bodies[c.b]
            guard (a.isAwake && a.motion != .static) || (b.isAwake && b.motion != .static) else { continue }
            var center = Vec3.zero
            var normal = Vec3.zero
            for p in c.points {
                center += p.position
                normal += p.normal
            }
            center /= Float(c.points.count)
            guard lengthSquared(normal) > 1e-12 else { continue }
            normal = normalize(normal)
            let relative = Self.pointVelocity(a, center) - Self.pointVelocity(b, center)
            let tangent = relative - normal * dot(relative, normal)
            let speed = length(tangent)
            if speed >= minSpeed {
                found.append(ContactSlide(bodyA: id(c.a), bodyB: id(c.b), entityA: a.entity, entityB: b.entity, point: center,
                                          normal: normal, speed: speed))
            }
        }
        return found
    }

    /// Whether `body` is swept for continuous collision.
    public func isContinuous(_ body: BodyID) -> Bool { index(of: body).map { bodies[$0].continuous } ?? false }

    /// Turns continuous collision on or off for `body` (the ECS sync sets it from `RigidBody.continuous`).
    public func setContinuous(_ body: BodyID, _ on: Bool) {
        if let i = index(of: body) { bodies[i].continuous = on }
    }

    /// The step's continuous collision pass (see the notes at the top of PhysicsContinuous.swift).
    func sweepContinuousBodies() {
        for i in bodies.indices where bodies[i].isAlive && bodies[i].continuous && bodies[i].motion == .dynamic && bodies[i].isAwake {
            guard let shape = bodies[i].shape, !shape.isMesh else { continue }
            let from = bodies[i].previousPose, to = bodies[i].pose
            let motion = to.position - from.position
            let distance = length(motion)
            let size = shape.localBounds.max - shape.localBounds.min
            guard distance > max(min(size.x, size.y, size.z) * 0.5, linearSlop * 4) else { continue }
            let start = from * bodies[i].shapeOffset
            // The moving shape's convex pieces at the start pose.
            var pieces: [WorldConvex] = []
            if case .compound(let parts) = shape.kind {
                for part in parts { if let w = WorldConvex(part.shape, start * part.pose) { pieces.append(w) } }
            } else if let w = WorldConvex(shape, start) {
                pieces.append(w)
            }
            guard !pieces.isEmpty else { continue }
            let swept = shape.bounds(at: start).swept(by: motion)
            var candidates: [Int] = []
            tree.query(swept) { j in
                if j != i, self.sweepHits(i, j) { candidates.append(j) }
                return true
            }
            var best: (fraction: Float, normal: Vec3, body: Int)?
            for j in candidates.sorted() {
                guard let target = bodies[j].shape else { continue }
                var hit: (fraction: Float, normal: Vec3)?
                var touchedAtStart = false
                for piece in pieces {
                    castAgainst(target, bodies[j].shapePose, piece, motion, swept) { h in
                        if h.fraction <= 0 {
                            touchedAtStart = true
                        } else if hit == nil || h.fraction < hit!.fraction {
                            hit = (h.fraction, h.normal)
                        }
                    }
                }
                // Already touching at the start: the contact solver handles it.
                guard !touchedAtStart, let hit, dot(hit.normal, motion) < 0 else { continue }
                if best == nil || hit.fraction < best!.fraction { best = (hit.fraction, hit.normal, j) }
            }
            guard let best else { continue }
            // Stop just in front of the surface (one slop short), keep the step's rotation.
            let travel = max(best.fraction * distance - linearSlop * 2, 0)
            let position = from.position + motion / distance * travel
            bodies[i].pose = Pose(position: position, rotation: to.rotation)
            bodies[i].updateDerived()
            let n = best.normal
            let v = bodies[i].linearVelocity - Self.pointVelocity(bodies[best.body], position)
            let into = dot(v, n)
            if into < 0 {
                let restitution = max(bodies[i].material.restitution, bodies[best.body].material.restitution)
                let bounce = -into > restitutionThreshold ? restitution : 0
                bodies[i].linearVelocity -= n * (into * (1 + bounce))
            }
            refreshProxy(i, force: true)
            if bodies[best.body].motion == .dynamic { wake(best.body) }
        }
    }

    /// Whether continuous body `i` is stopped by body `j` (they would collide).
    private func sweepHits(_ i: Int, _ j: Int) -> Bool {
        let a = bodies[i], b = bodies[j]
        guard b.isAlive, b.shape != nil, !b.isTrigger, !a.isTrigger else { return false }
        guard a.layer & b.mask != 0, b.layer & a.mask != 0 else { return false }
        if a.group != 0 && a.group == b.group { return false }
        if jointPairs[pairKey(i, j)] != nil { return false }
        return true
    }
}
