// The 2D solver: sequential impulses with soft contacts and substepping (after Box2D v3's
// "soft step"), the 2D version of ContactSolver.swift. Each step's contact manifolds are solved
// over `substeps` substeps; each substep integrates velocities, warm starts, solves joints and
// contacts `velocityIterations` times with a soft push-out bias, integrates positions, then
// relaxes (solves again without the bias, so the push-out adds no energy). Restitution is a
// final pass using the approach speed from before the step.
//
// Per contact point there is a normal impulse (no pulling; a speculative point, still apart,
// lets the bodies approach up to the gap) and a friction impulse along the tangent, clamped by
// the friction cone of that point's normal impulse. Separations are recomputed every substep
// from the bodies' poses and the points' anchors. All impulses accumulate and carry over to
// the next step (warm starting).

struct ContactConstraintPoint2D {
    /// Anchors in each body's frame (relative to its center of mass) and their world offsets.
    var localA: Vec2, localB: Vec2
    var rA = Vec2.zero, rB = Vec2.zero
    var normalMass: Float = 0
    var tangentMass: Float = 0
    var normalImpulse: Float
    var tangentImpulse: Float
    /// Normal speed before the step, for restitution.
    var approachSpeed: Float
    var maxNormalImpulse: Float = 0
}

struct ContactConstraint2D {
    var contact: Int
    var a: Int, b: Int
    var friction: Float
    var restitution: Float
    var normal: Vec2
    var points: [ContactConstraintPoint2D]
}

/// Soft constraint coefficients for a spring of `hertz` and `dampingRatio`, at step `h`.
struct Softness2D {
    var biasRate: Float
    var massScale: Float
    var impulseScale: Float

    init(hertz: Float, dampingRatio: Float, h: Float) {
        guard hertz > 0 else {
            biasRate = 0
            massScale = 1
            impulseScale = 0
            return
        }
        let omega = 2 * Float.pi * hertz
        let a1 = 2 * dampingRatio + h * omega
        let a2 = h * omega * a1
        let a3 = 1 / (1 + a2)
        biasRate = omega / a1
        massScale = a2 * a3
        impulseScale = a3
    }

    /// Rigid: no bias, full mass.
    static let rigid = Softness2D(hertz: 0, dampingRatio: 0, h: 0)
}

/// The step's solver settings, shared by every island.
struct SolverSettings2D: Sendable {
    var substeps: Int
    var velocityIterations: Int
    /// The substep.
    var h: Float
    var softness: Softness2D
    var jointSoftness: Softness2D
    var gravity: Vec2
    var linearSlop: Float
    var restitutionThreshold: Float
}

// Islands in parallel, as in 3D (see ContactSolver.swift and `SolverPlanner`): each unit of
// islands is solved in a `SolverIsland2D` on the job system, with its dynamic bodies' copies
// written back and kinematic bodies moved by the world, so results are bit-identical to one
// serial solve for any thread count. A mouse joint's spin damping only acts on a dynamic
// body (a kinematic one is a read-only neighbour).
extension PhysicsWorld2D {
    func solve(_ dt: Float) {
        let n = max(substeps, 1)
        let h = dt / Float(n)
        let contactHertz = min(self.contactHertz, 0.25 / h)
        let settings = SolverSettings2D(
            substeps: n, velocityIterations: velocityIterations, h: h,
            softness: Softness2D(hertz: contactHertz, dampingRatio: contactDampingRatio, h: h),
            jointSoftness: Softness2D(hertz: 2 * contactHertz, dampingRatio: jointDampingRatio, h: h),
            gravity: gravity, linearSlop: linearSlop, restitutionThreshold: restitutionThreshold)
        let (units, local) = Profiler.scope("solver islands") { planSolverUnits() }
        let solved = solveUnits(units, local: local, settings: settings)
        Profiler.scope("solver write back") {
            for (unit, island) in zip(units, solved) {
                for (k, i) in unit.members.enumerated() { bodies[i] = island.bodies[k] }
                for (k, j) in unit.joints.enumerated() {
                    var joint = island.joints[k]
                    joint.a = joints[j].a
                    joint.b = joints[j].b
                    joints[j] = joint
                }
                for c in island.constraints {
                    for (j, p) in c.points.enumerated() {
                        contacts[c.contact].points[j].normalImpulse = p.normalImpulse
                        contacts[c.contact].points[j].tangentImpulse = p.tangentImpulse
                    }
                }
            }
        }
        // Kinematic bodies aren't in any island (islands move copies of them).
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isAwake && bodies[i].motion == .kinematic {
            for _ in 0..<n { SolverIsland2D.integratePosition(&bodies[i], h) }
        }
        finishKinematicMoves()
    }

    private func planSolverUnits() -> ([SolverUnit], [Int32]) {
        var planner = SolverPlanner(isDynamic: bodies.map { $0.isAlive && $0.motion == .dynamic },
                                    isAwakeDynamic: bodies.map { $0.isAlive && $0.motion == .dynamic && $0.isAwake })
        for (ci, c) in contacts.enumerated() where !c.isTrigger && !c.points.isEmpty {
            guard bodies[c.a].isSolverActive || bodies[c.b].isSolverActive else { continue }
            planner.addContact(ci, c.a, c.b, points: c.points.count)
        }
        for j in joints.indices where joints[j].isAlive {
            guard bodies[joints[j].a].isSolverActive || bodies[joints[j].b].isSolverActive else { continue }
            planner.addJoint(j, joints[j].a, joints[j].b)
        }
        return planner.units()
    }

    /// The units on the job system (each job reads the world's arrays and returns its island).
    private func solveUnits(_ units: [SolverUnit], local: [Int32], settings: SolverSettings2D) -> [SolverIsland2D] {
        let (bodies, contacts, joints) = (self.bodies, self.contacts, self.joints)
        let order = units.indices.sorted { (units[$0].work, $1) > (units[$1].work, $0) }
        let byOrder = jobs.parallelMap(order.count, name: "solve islands") { k in
            var island = SolverIsland2D(unit: units[order[k]], bodies: bodies, contacts: contacts, joints: joints,
                                        local: local, settings: settings)
            island.solve()
            return island
        }
        var result = [SolverIsland2D?](repeating: nil, count: units.count)
        for (k, u) in order.enumerated() { result[u] = byOrder[k] }
        return result.map { $0! }
    }

    /// Kinematic bodies moved with `moveKinematic` land exactly on their target and stop until
    /// moved again; forces are cleared.
    private func finishKinematicMoves() {
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion != .static {
            bodies[i].force = .zero
            bodies[i].torque = 0
            if bodies[i].motion == .kinematic {
                // What `velocity(of:at:)` reports until the next step: how far the body moved.
                bodies[i].carryLinear = bodies[i].kinematicTarget == nil ? .zero : bodies[i].linearVelocity
                bodies[i].carryAngular = bodies[i].kinematicTarget == nil ? 0 : bodies[i].angularVelocity
            }
            if bodies[i].motion == .kinematic, let target = bodies[i].kinematicTarget {
                bodies[i].pose = target
                bodies[i].kinematicTarget = nil
                bodies[i].linearVelocity = .zero
                bodies[i].angularVelocity = 0
                bodies[i].updateDerived()
            }
        }
    }
}

/// One 2D solver job: copies of a unit's bodies (members, then neighbours), its joints and its
/// contact constraints, with body indices local to `bodies`. Runs on any thread.
struct SolverIsland2D {
    /// The fastest push-out of overlapping bodies, m/s.
    static let maxPushOut: Float = 3

    var bodies: [Body2D] = []
    var joints: [JointData2D] = []
    var constraints: [ContactConstraint2D] = []
    let settings: SolverSettings2D
    var linearSlop: Float { settings.linearSlop }
    var restitutionThreshold: Float { settings.restitutionThreshold }

    init(unit: SolverUnit, bodies world: [Body2D], contacts: [Contact2D], joints worldJoints: [JointData2D], local: [Int32],
         settings: SolverSettings2D) {
        self.settings = settings
        bodies.reserveCapacity(unit.members.count + unit.neighbours.count)
        for i in unit.members { bodies.append(world[i]) }
        var neighbourIndex: [Int: Int] = [:]
        for i in unit.neighbours {
            neighbourIndex[i] = bodies.count
            bodies.append(world[i])
        }
        func map(_ i: Int) -> Int { local[i] >= 0 ? Int(local[i]) : neighbourIndex[i]! }
        joints.reserveCapacity(unit.joints.count)
        for j in unit.joints {
            var joint = worldJoints[j]
            joint.a = map(joint.a)
            joint.b = map(joint.b)
            joints.append(joint)
        }
        constraints.reserveCapacity(unit.contacts.count)
        for ci in unit.contacts {
            constraints.append(makeContactConstraint(ci, contacts[ci], map(contacts[ci].a), map(contacts[ci].b)))
        }
    }

    mutating func solve() {
        var constraints = self.constraints
        self.constraints = []
        let h = settings.h, softness = settings.softness, jointSoftness = settings.jointSoftness
        for _ in 0..<settings.substeps {
            integrateVelocities(h)
            for k in constraints.indices { updateAnchors(&constraints[k]) }
            prepareJoints(h: h)
            warmStart(constraints)
            warmStartJoints()
            for iteration in 0..<settings.velocityIterations {
                solveJoints(h: h, softness: jointSoftness, useBias: true)
                // Alternate the order (symmetric Gauss-Seidel), so the order's bias cancels out.
                let reversed = iteration % 2 == 1
                for k in constraints.indices {
                    let index = reversed ? constraints.count - 1 - k : k
                    solveContact(&constraints[index], softness: softness, h: h, reversed: reversed)
                }
            }
            integratePositions(h)
            // Relax: remove the velocity the push-out added.
            solveJoints(h: h, softness: jointSoftness, useBias: false)
            for k in constraints.indices {
                updateAnchors(&constraints[k], massesToo: false)
                solveContact(&constraints[k], softness: nil, h: h, reversed: false)
            }
        }
        applyRestitution(&constraints)
        self.constraints = constraints
    }

    mutating func integrateVelocities(_ dt: Float) {
        let gravity = settings.gravity
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isSolverActive {
            var b = bodies[i]
            if b.motion == .dynamic {
                b.linearVelocity += (gravity * b.gravityScale + b.force * b.invMass) * dt
                b.angularVelocity += b.invInertia * b.torque * dt
                b.linearVelocity *= 1 / (1 + dt * b.linearDamping)
                b.angularVelocity *= 1 / (1 + dt * b.angularDamping)
                // Keep a single step's rotation sane.
                let maxAngular: Float = 0.5 * .pi / dt
                b.angularVelocity = min(max(b.angularVelocity, -maxAngular), maxAngular)
            }
            bodies[i] = b
        }
    }

    mutating func integratePositions(_ dt: Float) {
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isSolverActive {
            Self.integratePosition(&bodies[i], dt)
        }
    }

    static func integratePosition(_ body: inout Body2D, _ dt: Float) {
        body.center += body.linearVelocity * dt
        body.pose.rotation = body.pose.rotation.integrated(body.angularVelocity, dt)
        body.pose.position = body.center - body.pose.rotation.rotate(body.localCenter)
    }

    /// The constraint of world contact `ci`, between local bodies `ia` and `ib`.
    private func makeContactConstraint(_ ci: Int, _ c: Contact2D, _ ia: Int, _ ib: Int) -> ContactConstraint2D {
        let a = bodies[ia], b = bodies[ib]
        var points: [ContactConstraintPoint2D] = []
        points.reserveCapacity(c.points.count)
        for m in c.points {
            let rA = a.pose.rotation.rotate(m.localA), rB = b.pose.rotation.rotate(m.localB)
            let dv = b.linearVelocity + cross2(b.angularVelocity, rB) - a.linearVelocity - cross2(a.angularVelocity, rA)
            points.append(ContactConstraintPoint2D(localA: m.localA, localB: m.localB, normalImpulse: m.normalImpulse,
                                                   tangentImpulse: m.tangentImpulse, approachSpeed: dot2(dv, c.normal)))
        }
        return ContactConstraint2D(contact: ci, a: ia, b: ib, friction: c.friction,
                                   restitution: c.restitution, normal: c.normal, points: points)
    }

    /// Anchor offsets (and effective masses) from the bodies' current rotations.
    private func updateAnchors(_ c: inout ContactConstraint2D, massesToo: Bool = true) {
        let a = bodies[c.a], b = bodies[c.b]
        let tangent = rightPerp(c.normal)
        for j in c.points.indices {
            let rA = a.pose.rotation.rotate(c.points[j].localA), rB = b.pose.rotation.rotate(c.points[j].localB)
            c.points[j].rA = rA
            c.points[j].rB = rB
            if massesToo {
                let rnA = cross2(rA, c.normal), rnB = cross2(rB, c.normal)
                let kn = a.invMass + b.invMass + a.invInertia * rnA * rnA + b.invInertia * rnB * rnB
                c.points[j].normalMass = kn > 0 ? 1 / kn : 0
                let rtA = cross2(rA, tangent), rtB = cross2(rB, tangent)
                let kt = a.invMass + b.invMass + a.invInertia * rtA * rtA + b.invInertia * rtB * rtB
                c.points[j].tangentMass = kt > 0 ? 1 / kt : 0
            }
        }
    }

    private mutating func warmStart(_ constraints: [ContactConstraint2D]) {
        for c in constraints {
            let tangent = rightPerp(c.normal)
            for p in c.points { apply(c.normal * p.normalImpulse + tangent * p.tangentImpulse, c.a, p.rA, c.b, p.rB) }
        }
    }

    /// One pass over a manifold. With `softness`, overlapping points get a soft push-out bias;
    /// without (the relax pass), only the velocity constraints.
    private mutating func solveContact(_ c: inout ContactConstraint2D, softness: Softness2D?, h: Float, reversed: Bool) {
        let a = c.a, b = c.b
        let n = c.normal, tangent = rightPerp(n)
        // Friction first, bounded by the current normal impulses.
        for k in c.points.indices {
            let j = reversed ? c.points.count - 1 - k : k
            var p = c.points[j]
            let vt = dot2(relativeVelocity(a, p.rA, b, p.rB), tangent)
            let limit = c.friction * p.normalImpulse
            let total = min(max(p.tangentImpulse - p.tangentMass * vt, -limit), limit)
            apply(tangent * (total - p.tangentImpulse), a, p.rA, b, p.rB)
            p.tangentImpulse = total
            c.points[j] = p
        }
        for k in c.points.indices {
            let j = reversed ? c.points.count - 1 - k : k
            var p = c.points[j]
            // The current separation, from the anchors (surface points) on the moved bodies.
            let s = dot2(bodies[b].center + p.rB - bodies[a].center - p.rA, n)
            var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
            if s > 0 {
                bias = s / h  // speculative: may close the gap, no more
            } else if let softness {
                bias = max(softness.biasRate * min(s + linearSlop, 0), -Self.maxPushOut)
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            let vn = dot2(relativeVelocity(a, p.rA, b, p.rB), n)
            let impulse = -p.normalMass * massScale * (vn + bias) - impulseScale * p.normalImpulse
            let total = max(p.normalImpulse + impulse, 0)
            apply(n * (total - p.normalImpulse), a, p.rA, b, p.rB)
            p.normalImpulse = total
            p.maxNormalImpulse = max(p.maxNormalImpulse, total)
            c.points[j] = p
        }
    }

    /// Bounces points that were approaching fast and got pushed apart.
    private mutating func applyRestitution(_ constraints: inout [ContactConstraint2D]) {
        for k in constraints.indices where constraints[k].restitution > 0 {
            let c = constraints[k]
            for j in c.points.indices {
                let p = c.points[j]
                guard p.approachSpeed < -restitutionThreshold, p.maxNormalImpulse > 0 else { continue }
                let vn = dot2(relativeVelocity(c.a, p.rA, c.b, p.rB), c.normal)
                let lambda = -p.normalMass * (vn + c.restitution * p.approachSpeed)
                let total = max(p.normalImpulse + lambda, 0)
                apply(c.normal * (total - p.normalImpulse), c.a, p.rA, c.b, p.rB)
                constraints[k].points[j].normalImpulse = total
            }
        }
    }

    @inline(__always)
    func relativeVelocity(_ a: Int, _ rA: Vec2, _ b: Int, _ rB: Vec2) -> Vec2 {
        bodies[b].linearVelocity + cross2(bodies[b].angularVelocity, rB) - bodies[a].linearVelocity - cross2(bodies[a].angularVelocity, rA)
    }

    /// `impulse` pushes B and pulls A.
    @inline(__always)
    mutating func apply(_ impulse: Vec2, _ a: Int, _ rA: Vec2, _ b: Int, _ rB: Vec2) {
        bodies[a].linearVelocity -= impulse * bodies[a].invMass
        bodies[a].angularVelocity -= bodies[a].invInertia * cross2(rA, impulse)
        bodies[b].linearVelocity += impulse * bodies[b].invMass
        bodies[b].angularVelocity += bodies[b].invInertia * cross2(rB, impulse)
    }
}
