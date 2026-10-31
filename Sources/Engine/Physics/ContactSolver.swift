// The solver: sequential impulses with soft contacts and substepping (after Box2D v3's "soft
// step"). Each step's contact manifolds are solved over `substeps` substeps; each substep
// integrates velocities, warm starts, solves contacts and joints `velocityIterations` times
// with a soft push-out bias, integrates positions, then relaxes (solves joints and contacts
// again without the bias, so the push-out adds no energy). Restitution is a final pass using
// the approach speed from before the step.
//
// Per contact point there is a normal impulse (no pulling; a speculative point, still
// apart, lets the bodies approach up to the gap). Friction acts per manifold at its center:
// two tangent impulses and a twist impulse about the normal, clamped by the friction cone of
// the summed normal impulses (per-point friction can lock opposing impulses between points,
// which makes stacks creep). Separations are recomputed every substep from the bodies' poses
// and the points' anchors. All impulses accumulate and carry over to the next step (warm
// starting).
//
// Islands in parallel: bodies joined by the step's constraints (contacts with points, joints)
// form solver islands, and the islands are solved on the job system, each in a
// `SolverIsland` holding copies of its bodies. An island's dynamic bodies belong to it alone;
// static and kinematic bodies it touches are copied in as read-only neighbours (their
// velocities don't change in the solver, and every island integrates a kinematic copy exactly
// as the world integrates the body itself). An island runs the same substeps, iterations and
// constraint order (the world's, filtered to the island) as one solver over the whole world
// would, and no island reads what another writes, so the result is bit-identical to a single
// serial solve, for any thread count. Small islands are grouped into one job (independent
// islands stay independent when solved together).

struct ContactConstraintPoint {
    /// Anchors in each body's frame (relative to its center of mass) and their world offsets.
    var localA: Vec3, localB: Vec3
    var rA = Vec3.zero, rB = Vec3.zero
    var normal: Vec3
    var normalMass: Float = 0
    var normalImpulse: Float
    /// Normal speed before the step, for restitution.
    var approachSpeed: Float
    var maxNormalImpulse: Float = 0
}

struct ContactConstraint {
    var contact: Int
    var a: Int, b: Int
    var friction: Float
    var restitution: Float
    var points: [ContactConstraintPoint]
    // Friction at the manifold's center (anchored on each body).
    var centerA: Vec3, centerB: Vec3
    var rA = Vec3.zero, rB = Vec3.zero
    var normal: Vec3
    var tangent1: Vec3, tangent2: Vec3
    var tangentMass = Vec2.zero
    var twistMass: Float = 0
    /// The average distance of the points from the center: twist friction's lever arm.
    var twistRadius: Float
    var tangentImpulse: Vec2
    var twistImpulse: Float
}

/// Soft constraint coefficients for a spring of `hertz` and `dampingRatio`, at step `h`.
struct Softness {
    var biasRate: Float
    var massScale: Float
    var impulseScale: Float

    init(hertz: Float, dampingRatio: Float, h: Float) {
        let omega = 2 * Float.pi * hertz
        let a1 = 2 * dampingRatio + h * omega
        let a2 = h * omega * a1
        let a3 = 1 / (1 + a2)
        biasRate = omega / a1
        massScale = a2 * a3
        impulseScale = a3
    }
}

/// The step's solver settings, shared by every island.
struct SolverSettings: Sendable {
    var substeps: Int
    var velocityIterations: Int
    /// The substep.
    var h: Float
    var softness: Softness
    var jointSoftness: Softness
    var gravity: Vec3
    var linearSlop: Float
    var restitutionThreshold: Float
}

/// The bodies, contacts and joints of one solver job: whole islands, in world order.
struct SolverUnit {
    /// Dynamic bodies the unit owns (world indices, ascending); written back after the solve.
    var members: [Int] = []
    /// Static and kinematic bodies its constraints touch (read-only copies).
    var neighbours: [Int] = []
    /// Contacts and joints (world indices, ascending).
    var contacts: [Int] = []
    var joints: [Int] = []
    /// Roughly how long it takes: bodies plus constraint rows.
    var work = 0
}

/// Splits a step's constraints into islands and groups them into `SolverUnit`s.
///
/// Islands: dynamic bodies joined by a constraint the solver runs (a contact with points or a
/// joint, with an awake dynamic body). Static and kinematic bodies don't join islands. Units are
/// consecutive islands (numbered by their lowest body) grouped until they have `minimumWork`,
/// so a job is worth its overhead; grouping never changes results, as islands are independent.
struct SolverPlanner {
    static let minimumWork = 256

    /// Union-find over body indices.
    private var parent: [Int]
    private(set) var inSolver: [Bool]
    private var activeContacts: [(index: Int, a: Int, b: Int, rows: Int)] = []
    private var activeJoints: [(index: Int, a: Int, b: Int)] = []
    private let isDynamic: [Bool]

    /// Per body: dynamic, and dynamic and awake (dead bodies: false for both).
    init(isDynamic: [Bool], isAwakeDynamic: [Bool]) {
        self.isDynamic = isDynamic
        parent = Array(isDynamic.indices)
        inSolver = isAwakeDynamic
    }

    private mutating func find(_ i: Int) -> Int {
        var i = i
        while parent[i] != i {
            parent[i] = parent[parent[i]]
            i = parent[i]
        }
        return i
    }

    private mutating func link(_ a: Int, _ b: Int) {
        if isDynamic[a] { inSolver[a] = true }
        if isDynamic[b] { inSolver[b] = true }
        if isDynamic[a] && isDynamic[b] {
            let ra = find(a), rb = find(b)
            if ra != rb { parent[max(ra, rb)] = min(ra, rb) }
        }
    }

    /// Adds the solver's contacts in world order.
    mutating func addContact(_ index: Int, _ a: Int, _ b: Int, points: Int) {
        activeContacts.append((index, a, b, 2 * points))
        link(a, b)
    }

    /// Adds the solver's joints in world order.
    mutating func addJoint(_ index: Int, _ a: Int, _ b: Int) {
        activeJoints.append((index, a, b))
        link(a, b)
    }

    /// The units, and each member's index in its unit (-1 for bodies no unit owns). A
    /// constraint without a dynamic body (possible in 2D: a joint between kinematic bodies)
    /// goes to a unit of its own with no members.
    mutating func units() -> ([SolverUnit], [Int32]) {
        let count = parent.count
        var islandOfRoot = [Int32](repeating: -1, count: count)
        var islandWork: [Int] = []
        for i in 0..<count where inSolver[i] {
            let r = find(i)
            if islandOfRoot[r] < 0 {
                islandOfRoot[r] = Int32(islandWork.count)
                islandWork.append(0)
            }
            islandWork[Int(islandOfRoot[r])] += 1
        }
        // The island a constraint belongs to: its dynamic body's (-1: none).
        func island(_ a: Int, _ b: Int) -> Int {
            let d = isDynamic[a] ? a : isDynamic[b] ? b : -1
            return d < 0 ? -1 : Int(islandOfRoot[find(d)])
        }
        let contactIslands = activeContacts.map { island($0.a, $0.b) }
        let jointIslands = activeJoints.map { island($0.a, $0.b) }
        for (c, k) in zip(activeContacts, contactIslands) where k >= 0 { islandWork[k] += c.rows }
        for k in jointIslands where k >= 0 { islandWork[k] += 4 }

        var unitOfIsland = [Int](repeating: 0, count: islandWork.count)
        var units: [SolverUnit] = []
        for (k, work) in islandWork.enumerated() {
            if units.isEmpty || units[units.count - 1].work >= Self.minimumWork { units.append(SolverUnit()) }
            units[units.count - 1].work += work
            unitOfIsland[k] = units.count - 1
        }
        var orphans: Int?
        func unit(ofIsland k: Int) -> Int {
            if k >= 0 { return unitOfIsland[k] }
            if orphans == nil {
                orphans = units.count
                units.append(SolverUnit())
            }
            return orphans!
        }
        var local = [Int32](repeating: -1, count: count)
        for i in 0..<count where inSolver[i] {
            let u = unitOfIsland[Int(islandOfRoot[find(i)])]
            local[i] = Int32(units[u].members.count)
            units[u].members.append(i)
        }
        // Static and kinematic neighbours, once per unit, in order of first use.
        var neighbourSets: [Int: Set<Int>] = [:]
        func addNeighbours(_ u: Int, _ a: Int, _ b: Int) {
            for i in [a, b] where !isDynamic[i] {
                if neighbourSets[u, default: []].insert(i).inserted { units[u].neighbours.append(i) }
            }
        }
        for (c, k) in zip(activeContacts, contactIslands) {
            let u = unit(ofIsland: k)
            units[u].contacts.append(c.index)
            addNeighbours(u, c.a, c.b)
        }
        for (j, k) in zip(activeJoints, jointIslands) {
            let u = unit(ofIsland: k)
            units[u].joints.append(j.index)
            addNeighbours(u, j.a, j.b)
        }
        return (units, local)
    }
}

extension PhysicsWorld {
    func solve(_ dt: Float) {
        let n = max(substeps, 1)
        let h = dt / Float(n)
        let contactHertz = min(self.contactHertz, 0.25 / h)
        // Joints are stiffer than contacts, but no stiffer than a quarter of the substep rate
        // either: at half of it (120 Hz at 240) a resting chain jitters and never sleeps.
        let settings = SolverSettings(
            substeps: n, velocityIterations: velocityIterations, h: h,
            softness: Softness(hertz: contactHertz, dampingRatio: contactDampingRatio, h: h),
            jointSoftness: Softness(hertz: min(2 * contactHertz, 0.25 / h), dampingRatio: jointDampingRatio, h: h),
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
                    for (j, p) in c.points.enumerated() { contacts[c.contact].points[j].normalImpulse = p.normalImpulse }
                    contacts[c.contact].tangentImpulse = c.tangentImpulse
                    contacts[c.contact].twistImpulse = c.twistImpulse
                }
            }
        }
        // Kinematic bodies aren't in any island (islands move copies of them): they move here,
        // substep by substep, as the islands moved theirs.
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isAwake && bodies[i].motion == .kinematic {
            for _ in 0..<n { SolverIsland.integratePosition(&bodies[i], h) }
        }
        finishKinematicMoves()
    }

    private func planSolverUnits() -> ([SolverUnit], [Int32]) {
        var planner = SolverPlanner(isDynamic: bodies.map { $0.isAlive && $0.motion == .dynamic },
                                    isAwakeDynamic: bodies.map { $0.isAlive && $0.isSolverActive })
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
    private func solveUnits(_ units: [SolverUnit], local: [Int32], settings: SolverSettings) -> [SolverIsland] {
        let (bodies, contacts, joints) = (self.bodies, self.contacts, self.joints)
        // Biggest units first, so a big island doesn't start last.
        let order = units.indices.sorted { (units[$0].work, $1) > (units[$1].work, $0) }
        let byOrder = jobs.parallelMap(order.count, name: "solve islands") { k in
            var island = SolverIsland(unit: units[order[k]], bodies: bodies, contacts: contacts, joints: joints,
                                      local: local, settings: settings)
            island.solve()
            return island
        }
        var result = [SolverIsland?](repeating: nil, count: units.count)
        for (k, u) in order.enumerated() { result[u] = byOrder[k] }
        return result.map { $0! }
    }

    /// Kinematic bodies moved with `moveKinematic` land exactly on their target and stop until
    /// moved again; forces are cleared.
    private func finishKinematicMoves() {
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion != .static {
            bodies[i].force = .zero
            bodies[i].torque = .zero
            if bodies[i].motion == .kinematic {
                // What `velocity(of:at:)` reports until the next step: how far the body moved.
                bodies[i].carryLinear = bodies[i].kinematicTarget == nil ? .zero : bodies[i].linearVelocity
                bodies[i].carryAngular = bodies[i].kinematicTarget == nil ? .zero : bodies[i].angularVelocity
            }
            if bodies[i].motion == .kinematic, let target = bodies[i].kinematicTarget {
                bodies[i].pose = target
                bodies[i].kinematicTarget = nil
                bodies[i].linearVelocity = .zero
                bodies[i].angularVelocity = .zero
                bodies[i].updateDerived()
            }
        }
    }
}

/// One solver job: copies of a unit's bodies (members, then neighbours), its joints and its
/// contact constraints, with body indices local to `bodies`. Runs on any thread.
struct SolverIsland {
    /// The fastest push-out of overlapping bodies, m/s.
    static let maxPushOut: Float = 3

    var bodies: [Body] = []
    var joints: [JointData] = []
    var constraints: [ContactConstraint] = []
    let settings: SolverSettings
    var linearSlop: Float { settings.linearSlop }
    var restitutionThreshold: Float { settings.restitutionThreshold }

    init(unit: SolverUnit, bodies world: [Body], contacts: [Contact], joints worldJoints: [JointData], local: [Int32],
         settings: SolverSettings) {
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
            prepareJoints()
            warmStart(constraints)
            warmStartJoints()
            for iteration in 0..<settings.velocityIterations {
                solveJoints(softness: jointSoftness, useBias: true)
                // Alternate the order (symmetric Gauss-Seidel), so the order's bias cancels out.
                let reversed = iteration % 2 == 1
                for k in constraints.indices {
                    let index = reversed ? constraints.count - 1 - k : k
                    solveContact(&constraints[index], softness: softness, h: h, reversed: reversed)
                }
            }
            integratePositions(h)
            // Relax: remove the velocity the push-out added.
            solveJoints(softness: jointSoftness, useBias: false)
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
            b.linearVelocity += (gravity * b.gravityScale + b.force * b.invMass) * dt
            b.angularVelocity += b.invInertiaWorld * b.torque * dt
            b.linearVelocity *= 1 / (1 + dt * b.linearDamping)
            b.angularVelocity *= 1 / (1 + dt * b.angularDamping)
            // Keep a single step's rotation sane.
            let maxAngular: Float = 0.5 * .pi / dt
            let w2 = lengthSquared(b.angularVelocity)
            if w2 > maxAngular * maxAngular { b.angularVelocity *= maxAngular / w2.squareRoot() }
            bodies[i] = b
        }
    }

    mutating func integratePositions(_ dt: Float) {
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isAwake && bodies[i].motion != .static {
            Self.integratePosition(&bodies[i], dt)
        }
    }

    static func integratePosition(_ body: inout Body, _ dt: Float) {
        body.center += body.linearVelocity * dt
        body.pose.rotation = body.pose.rotation.integrated(body.angularVelocity, dt)
        body.pose.position = body.center - body.pose.rotation * body.localCenter
        body.updateDerived()
    }

    /// The constraint of world contact `ci`, between local bodies `ia` and `ib`.
    private func makeContactConstraint(_ ci: Int, _ c: Contact, _ ia: Int, _ ib: Int) -> ContactConstraint {
        let a = bodies[ia], b = bodies[ib]
        var points: [ContactConstraintPoint] = []
        points.reserveCapacity(c.points.count)
        var center = Vec3.zero, normalSum = Vec3.zero
        for m in c.points {
            let rA = a.pose.rotation * m.localA, rB = b.pose.rotation * m.localB
            let dv = b.linearVelocity + cross(b.angularVelocity, rB) - a.linearVelocity - cross(a.angularVelocity, rA)
            points.append(ContactConstraintPoint(localA: m.localA, localB: m.localB, normal: m.normal,
                                                 normalImpulse: m.normalImpulse, approachSpeed: dot(dv, m.normal)))
            center += m.position
            normalSum += m.normal
        }
        center /= Float(c.points.count)
        let n = normalize(normalSum)
        let (t1, t2) = tangentBasis(n)
        return ContactConstraint(
            contact: ci, a: ia, b: ib, friction: c.friction, restitution: c.restitution, points: points,
            centerA: a.pose.rotation.conjugate * (center - a.center), centerB: b.pose.rotation.conjugate * (center - b.center),
            normal: n, tangent1: t1, tangent2: t2,
            twistRadius: c.points.reduce(0) { $0 + length($1.position - center) } / Float(c.points.count),
            tangentImpulse: c.tangentImpulse, twistImpulse: c.twistImpulse)
    }

    /// Anchor offsets (and effective masses) from the bodies' current rotations.
    private func updateAnchors(_ c: inout ContactConstraint, massesToo: Bool = true) {
        let a = bodies[c.a], b = bodies[c.b]
        func mass(_ rA: Vec3, _ rB: Vec3, _ d: Vec3) -> Float {
            let ca = cross(rA, d), cb = cross(rB, d)
            let k = a.invMass + b.invMass + dot(ca, a.invInertiaWorld * ca) + dot(cb, b.invInertiaWorld * cb)
            return k > 0 ? 1 / k : 0
        }
        for j in c.points.indices {
            c.points[j].rA = a.pose.rotation * c.points[j].localA
            c.points[j].rB = b.pose.rotation * c.points[j].localB
            if massesToo { c.points[j].normalMass = mass(c.points[j].rA, c.points[j].rB, c.points[j].normal) }
        }
        c.rA = a.pose.rotation * c.centerA
        c.rB = b.pose.rotation * c.centerB
        if massesToo {
            c.tangentMass = Vec2(mass(c.rA, c.rB, c.tangent1), mass(c.rA, c.rB, c.tangent2))
            let k = dot(c.normal, a.invInertiaWorld * c.normal) + dot(c.normal, b.invInertiaWorld * c.normal)
            c.twistMass = k > 0 ? 1 / k : 0
        }
    }

    private mutating func warmStart(_ constraints: [ContactConstraint]) {
        for c in constraints {
            for p in c.points { apply(p.normal * p.normalImpulse, c.a, p.rA, c.b, p.rB) }
            apply(c.tangent1 * c.tangentImpulse.x + c.tangent2 * c.tangentImpulse.y, c.a, c.rA, c.b, c.rB)
            applyAngular(c.normal * c.twistImpulse, c.a, c.b)
        }
    }

    /// One pass over a manifold. With `softness`, overlapping points get a soft push-out bias;
    /// without (the relax pass), only the velocity constraints.
    private mutating func solveContact(_ c: inout ContactConstraint, softness: Softness?, h: Float, reversed: Bool) {
        // Friction first, bounded by the current normal impulses.
        let total = c.points.reduce(0) { $0 + $1.normalImpulse }
        let limit = c.friction * total
        let dv = relativeVelocity(c.a, c.rA, c.b, c.rB)
        let old = c.tangentImpulse
        var t = old - Vec2(dot(dv, c.tangent1), dot(dv, c.tangent2)) * c.tangentMass
        // Clamp to the cone (a circle), not a square.
        let len = (t.x * t.x + t.y * t.y).squareRoot()
        if len > limit { t *= limit / len }
        c.tangentImpulse = t
        let delta = t - old
        apply(c.tangent1 * delta.x + c.tangent2 * delta.y, c.a, c.rA, c.b, c.rB)

        if c.twistRadius > 0 {
            let spin = dot(bodies[c.b].angularVelocity - bodies[c.a].angularVelocity, c.normal)
            let twistLimit = limit * c.twistRadius
            let twist = min(max(c.twistImpulse - spin * c.twistMass, -twistLimit), twistLimit)
            applyAngular(c.normal * (twist - c.twistImpulse), c.a, c.b)
            c.twistImpulse = twist
        }

        let a = c.a, b = c.b
        for k in c.points.indices {
            let j = reversed ? c.points.count - 1 - k : k
            var p = c.points[j]
            // The current separation, from the anchors (surface points) on the moved bodies.
            let s = dot(bodies[b].center + p.rB - bodies[a].center - p.rA, p.normal)
            var bias: Float = 0, massScale: Float = 1, impulseScale: Float = 0
            if s > 0 {
                bias = s / h  // speculative: may close the gap, no more
            } else if let softness {
                bias = max(softness.biasRate * min(s + linearSlop, 0), -Self.maxPushOut)
                massScale = softness.massScale
                impulseScale = softness.impulseScale
            }
            let vn = dot(relativeVelocity(a, p.rA, b, p.rB), p.normal)
            let impulse = -p.normalMass * massScale * (vn + bias) - impulseScale * p.normalImpulse
            let total = max(p.normalImpulse + impulse, 0)
            apply(p.normal * (total - p.normalImpulse), a, p.rA, b, p.rB)
            p.normalImpulse = total
            p.maxNormalImpulse = max(p.maxNormalImpulse, total)
            c.points[j] = p
        }
    }

    /// Bounces points that were approaching fast and got pushed apart.
    private mutating func applyRestitution(_ constraints: inout [ContactConstraint]) {
        for k in constraints.indices where constraints[k].restitution > 0 {
            let c = constraints[k]
            for j in c.points.indices {
                let p = c.points[j]
                guard p.approachSpeed < -restitutionThreshold, p.maxNormalImpulse > 0 else { continue }
                let vn = dot(relativeVelocity(c.a, p.rA, c.b, p.rB), p.normal)
                let lambda = -p.normalMass * (vn + c.restitution * p.approachSpeed)
                let total = max(p.normalImpulse + lambda, 0)
                apply(p.normal * (total - p.normalImpulse), c.a, p.rA, c.b, p.rB)
                constraints[k].points[j].normalImpulse = total
            }
        }
    }

    @inline(__always)
    private func relativeVelocity(_ a: Int, _ rA: Vec3, _ b: Int, _ rB: Vec3) -> Vec3 {
        bodies[b].linearVelocity + cross(bodies[b].angularVelocity, rB) - bodies[a].linearVelocity - cross(bodies[a].angularVelocity, rA)
    }

    /// `impulse` pushes B and pulls A.
    @inline(__always)
    private mutating func apply(_ impulse: Vec3, _ a: Int, _ rA: Vec3, _ b: Int, _ rB: Vec3) {
        bodies[a].linearVelocity -= impulse * bodies[a].invMass
        bodies[a].angularVelocity -= bodies[a].invInertiaWorld * cross(rA, impulse)
        bodies[b].linearVelocity += impulse * bodies[b].invMass
        bodies[b].angularVelocity += bodies[b].invInertiaWorld * cross(rB, impulse)
    }

    @inline(__always)
    private mutating func applyAngular(_ impulse: Vec3, _ a: Int, _ b: Int) {
        bodies[a].angularVelocity -= bodies[a].invInertiaWorld * impulse
        bodies[b].angularVelocity += bodies[b].invInertiaWorld * impulse
    }
}
