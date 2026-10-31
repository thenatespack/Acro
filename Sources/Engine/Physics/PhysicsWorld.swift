import Foundation

/// A rigid body simulation: static, kinematic and dynamic bodies with one collider each,
/// joints, a broadphase AABB tree, contact manifolds and a sequential-impulse solver with
/// warm starting, friction, restitution and sleeping.
///
/// Use it directly (`addBody`, `step` or `advance(by:)`), or let a `World` drive it from
/// components (`world.addPhysics(physics)`, see PhysicsECS.swift).
///
/// The simulation is deterministic: bodies, contacts and joints live in arrays in creation
/// order, new pairs are sorted, and nothing iterates a dictionary or reads a clock, so the
/// same calls give bit-identical results. Steps 1 and 2 run on `jobs` (each moved body's
/// query and each contact's narrowphase on its own, merged in a fixed order), so the thread
/// count doesn't change them either.
///
/// One step (`step(_:)`):
/// 1. New pairs: every body whose fat box moved queries the tree; new pairs become contacts.
/// 2. Narrowphase for contacts with a moving body (manifolds of up to four points, matched to
///    last step's points for warm starting); contacts whose fat boxes separated are removed.
///    Begin / end / trigger events.
/// 3. Islands (bodies connected by touching contacts and joints): an island with an awake
///    body wakes as a whole.
/// 4. The solver (ContactSolver.swift): `substeps` substeps of gravity and forces, soft
///    contacts (with speculative points that stop a body at the surface), friction and joints,
///    then restitution.
/// 5. Sleep: an island whose bodies have all been slow for `timeToSleep` goes to sleep.
@MainActor
public final class PhysicsWorld {
    public var gravity = Vec3(0, -9.81, 0)
    /// The solver runs this many substeps per step (more: stiffer stacks and joints).
    public var substeps = 4
    /// Constraint iterations per substep.
    public var velocityIterations = 2
    /// Contact stiffness: overlapping bodies are pushed apart by a spring of this frequency
    /// (capped at a quarter of the substep rate) and damping ratio; joints pull their anchors
    /// back together at twice the frequency (same cap), with `jointDampingRatio`.
    public var contactHertz: Float = 60
    public var contactDampingRatio: Float = 10
    public var jointDampingRatio: Float = 2
    /// The step `advance(by:)` takes.
    public var fixedTimestep: Float = 1.0 / 60.0
    /// `advance(by:)` drops time beyond this many steps per call.
    public var maxStepsPerAdvance = 8
    /// Seconds a body must be slow before its island may sleep.
    public var timeToSleep: Float = 0.5
    public var sleepLinearVelocity: Float = 0.05
    public var sleepAngularVelocity: Float = 0.08
    /// Overlap left alone, to keep contacts alive between steps.
    public var linearSlop: Float = 0.002
    /// Points within this distance (plus how far the bodies can close in a step) count as
    /// contacts (speculative), so bodies stop at surfaces instead of sinking into them.
    public var speculativeDistance: Float = 0.04
    /// Approach speeds below this don't bounce.
    public var restitutionThreshold: Float = 1
    /// Runs the pair search and the narrowphase in parallel (the solver stays on the calling
    /// thread). Results are the same for any thread count.
    public var jobs = JobSystem.shared

    /// Events of the steps since the last `clearEvents()` (`advance(by:)` and the ECS
    /// integration clear them once per frame).
    public private(set) var events: [PhysicsEvent] = []
    /// Called for each event at the end of the step that produced it.
    public var onEvent: ((PhysicsEvent) -> Void)?

    /// Total steps taken.
    public private(set) var stepCount = 0

    var bodies: [Body] = []
    var freeBodies: [Int] = []
    var contacts: [Contact] = []
    /// Pair keys of `contacts`, for lookups only (never iterated).
    var contactKeys: Set<UInt64> = []
    var joints: [JointData] = []
    var freeJoints: [Int] = []
    /// Pairs connected by a joint that doesn't collide them (keys, lookups only).
    var jointPairs: [UInt64: Int] = [:]
    var tree = AABBTree()
    /// Bodies whose proxy moved since the last pair search.
    var movedProxies: [Int] = []
    var accumulator: Float = 0

    // ECS bookkeeping (PhysicsECS.swift).
    var bodyForEntity: [Entity: Int] = [:]
    var jointForEntity: [Entity: Int] = [:]

    /// Fat boxes are this much larger than their shape.
    static let aabbMargin: Float = 0.08

    public init() {
        // Slot 0 is the world: the static body joints without a second body attach to.
        var ground = Body()
        ground.isAlive = true
        ground.motion = .static
        bodies.append(ground)
    }

    public var bodyCount: Int { bodies.count - 1 - freeBodies.count }
    /// Bodies currently awake (dynamic and moving kinematic ones).
    public var awakeBodyCount: Int { bodies.filter { $0.isAlive && $0.isAwake && $0.motion != .static }.count }
    public var contactCount: Int { contacts.count }
    /// Contacts whose shapes touch.
    public var touchingContactCount: Int { contacts.filter { $0.touching && !$0.isTrigger }.count }

    // MARK: - Bodies

    @discardableResult
    public func addBody(_ d: BodyDescriptor) -> BodyID {
        let index = freeBodies.popLast() ?? {
            bodies.append(Body())
            return bodies.count - 1
        }()
        var body = Body()
        body.generation = bodies[index].generation &+ 1
        body.isAlive = true
        body.motion = d.motion
        body.pose = Pose(position: d.pose.position, rotation: d.pose.rotation.normalized)
        body.linearVelocity = d.motion == .static ? .zero : d.linearVelocity
        body.angularVelocity = d.motion == .static ? .zero : d.angularVelocity
        body.linearDamping = d.linearDamping
        body.angularDamping = d.angularDamping
        body.gravityScale = d.gravityScale
        body.allowSleep = d.allowSleep
        body.entity = d.entity
        body.previousPose = body.pose
        bodies[index] = body
        setShape(index, d.shape, offset: d.shapeOffset, scale: d.scale, material: d.material, isTrigger: d.isTrigger,
                 layer: d.layer, mask: d.mask)
        bodies[index].isAwake = d.motion != .static && !d.startsAsleep
        return BodyID(index: index, generation: body.generation)
    }

    /// Removes the body, its contacts (reporting `collisionEnded` / `triggerExited`) and its joints.
    public func removeBody(_ id: BodyID) {
        guard let i = index(of: id) else { return }
        removeBody(at: i)
    }

    func removeBody(at i: Int) {
        if let proxy = bodies[i].proxy { tree.remove(proxy) }
        var kept: [Contact] = []
        var ended: [PhysicsEvent] = []
        for c in contacts {
            if c.a == i || c.b == i {
                contactKeys.remove(c.key)
                if c.touching { ended.append(endEvent(c)) }
                // Bodies resting on a removed one must fall.
                wake(c.a == i ? c.b : c.a)
            } else {
                kept.append(c)
            }
        }
        contacts = kept
        for j in joints.indices where joints[j].isAlive && (joints[j].a == i || joints[j].b == i) { removeJoint(at: j) }
        movedProxies.removeAll { $0 == i }
        if let entity = bodies[i].entity, bodyForEntity[entity] == i { bodyForEntity[entity] = nil }
        let generation = bodies[i].generation
        bodies[i] = Body()
        bodies[i].generation = generation
        freeBodies.append(i)
        emit(ended)
    }

    public func contains(_ id: BodyID) -> Bool { index(of: id) != nil }

    func index(of id: BodyID) -> Int? {
        let i = Int(id.index)
        guard i > 0, i < bodies.count, bodies[i].isAlive, bodies[i].generation == id.generation else { return nil }
        return i
    }

    func id(_ i: Int) -> BodyID { BodyID(index: i, generation: bodies[i].generation) }

    /// Every body, in creation-slot order.
    public var bodyIDs: [BodyID] { bodies.indices.dropFirst().filter { bodies[$0].isAlive }.map(id) }

    public func pose(of id: BodyID) -> Pose? { index(of: id).map { bodies[$0].pose } }
    public func motion(of id: BodyID) -> MotionType? { index(of: id).map { bodies[$0].motion } }
    public func entity(of id: BodyID) -> Entity? { index(of: id).flatMap { bodies[$0].entity } }
    public func isAwake(_ id: BodyID) -> Bool { index(of: id).map { bodies[$0].isAwake } ?? false }
    public func mass(of id: BodyID) -> Float { index(of: id).map { bodies[$0].mass } ?? 0 }
    /// The center of mass in world space.
    public func centerOfMass(of id: BodyID) -> Vec3? { index(of: id).map { bodies[$0].center } }
    /// The collider's world bounds.
    public func bounds(of id: BodyID) -> AABB? {
        guard let i = index(of: id), let shape = bodies[i].shape else { return nil }
        return shape.bounds(at: bodies[i].shapePose)
    }

    public func linearVelocity(of id: BodyID) -> Vec3 { index(of: id).map { bodies[$0].linearVelocity } ?? .zero }

    /// The velocity of the body's material at a world point: what a character standing there
    /// is carried at. A kinematic body reports how it moved in the last step (its own velocity
    /// is zero between steps), a dynamic one its current velocity; static bodies are still.
    public func velocity(of id: BodyID, at point: Vec3) -> Vec3 {
        guard let i = index(of: id) else { return .zero }
        let b = bodies[i]
        switch b.motion {
        case .static: return .zero
        case .kinematic: return b.carryLinear + cross(b.carryAngular, point - b.center)
        case .dynamic: return b.linearVelocity + cross(b.angularVelocity, point - b.center)
        }
    }
    public func angularVelocity(of id: BodyID) -> Vec3 { index(of: id).map { bodies[$0].angularVelocity } ?? .zero }

    public func setLinearVelocity(_ id: BodyID, _ v: Vec3) {
        guard let i = index(of: id), bodies[i].motion != .static else { return }
        bodies[i].linearVelocity = v
        wake(i)
    }

    public func setAngularVelocity(_ id: BodyID, _ w: Vec3) {
        guard let i = index(of: id), bodies[i].motion != .static else { return }
        bodies[i].angularVelocity = w
        wake(i)
    }

    /// Teleports the body (wakes it; velocities are kept).
    public func setPose(_ id: BodyID, _ pose: Pose) {
        guard let i = index(of: id) else { return }
        setPose(at: i, pose)
    }

    func setPose(at i: Int, _ pose: Pose) {
        bodies[i].pose = Pose(position: pose.position, rotation: pose.rotation.normalized)
        bodies[i].previousPose = bodies[i].pose
        bodies[i].kinematicTarget = nil
        bodies[i].updateDerived()
        refreshProxy(i, force: true)
        wake(i)
        // Static bodies moved by hand: wake what touches them.
        if bodies[i].motion == .static {
            for c in contacts where c.a == i || c.b == i { wake(c.a == i ? c.b : c.a) }
        }
    }

    /// Moves a kinematic body to `pose` over the next step of length `dt`, giving it the
    /// velocity that gets it there (so it pushes dynamic bodies and carries them by friction).
    public func moveKinematic(_ id: BodyID, to pose: Pose, dt: Float) {
        guard let i = index(of: id), bodies[i].motion == .kinematic, dt > 0 else { return }
        moveKinematic(at: i, to: pose, dt: dt)
    }

    func moveKinematic(at i: Int, to pose: Pose, dt: Float) {
        let target = Pose(position: pose.position, rotation: pose.rotation.normalized)
        let body = bodies[i]
        let targetCenter = target.transform(body.localCenter)
        bodies[i].linearVelocity = (targetCenter - body.center) / dt
        var dq = target.rotation * body.pose.rotation.conjugate
        if dq.w < 0 { dq = Quat(vector: -dq.vector) }
        let s = length(dq.imaginary)
        let angle = 2 * atan2f(s, dq.w)
        bodies[i].angularVelocity = s > 1e-9 ? dq.imaginary / s * (angle / dt) : .zero
        bodies[i].kinematicTarget = target
        if bodies[i].linearVelocity != .zero || bodies[i].angularVelocity != .zero { wake(i) }
    }

    /// An impulse (N·s) at a world point (default: the center of mass). Wakes the body.
    public func applyImpulse(_ id: BodyID, _ impulse: Vec3, at point: Vec3? = nil) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].linearVelocity += impulse * bodies[i].invMass
        if let point {
            bodies[i].angularVelocity += bodies[i].invInertiaWorld * cross(point - bodies[i].center, impulse)
        }
        wake(i)
    }

    /// A force (N) at a world point (default: the center of mass), applied during the next step.
    public func applyForce(_ id: BodyID, _ force: Vec3, at point: Vec3? = nil) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].force += force
        if let point { bodies[i].torque += cross(point - bodies[i].center, force) }
        wake(i)
    }

    public func applyTorque(_ id: BodyID, _ torque: Vec3) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].torque += torque
        wake(i)
    }

    public func wake(_ id: BodyID) {
        if let i = index(of: id) { wake(i) }
    }

    func wake(_ i: Int) {
        guard bodies[i].motion != .static, !bodies[i].isAwake else { return }
        bodies[i].isAwake = true
        bodies[i].sleepTime = 0
    }

    /// Puts a dynamic body to sleep now (it stays asleep until something touches it).
    public func sleep(_ id: BodyID) {
        guard let i = index(of: id), bodies[i].motion != .static else { return }
        bodies[i].isAwake = false
        bodies[i].linearVelocity = .zero
        bodies[i].angularVelocity = .zero
    }

    /// Changes how a body moves (mass is recomputed; static bodies stop).
    public func setMotion(_ id: BodyID, _ motion: MotionType) {
        guard let i = index(of: id), bodies[i].motion != motion else { return }
        bodies[i].motion = motion
        if motion == .static {
            bodies[i].linearVelocity = .zero
            bodies[i].angularVelocity = .zero
            bodies[i].isAwake = false
        } else {
            bodies[i].isAwake = true
        }
        bodies[i].updateMass()
        refreshProxy(i, force: true)
    }

    /// Replaces the body's collider (mass and contacts are updated).
    func setShape(_ i: Int, _ shape: ColliderShape?, offset: Pose, scale: Vec3, material: ColliderMaterial,
                  isTrigger: Bool, layer: UInt32, mask: UInt32) {
        bodies[i].shape = shape.map { Shape($0, scale: scale) }
        bodies[i].shapeOffset = offset
        bodies[i].material = material
        bodies[i].isTrigger = isTrigger
        bodies[i].layer = layer
        bodies[i].mask = mask
        bodies[i].updateMass()
        refreshProxy(i, force: true)
        // Drop contacts so they are rebuilt (and re-filtered) from scratch.
        for c in contacts where c.a == i || c.b == i { wake(c.a == i ? c.b : c.a) }
        removeContacts(of: i)
        wake(i)
    }

    /// Updates the body's fat box in the tree when its shape left it (or always, with `force`).
    func refreshProxy(_ i: Int, force: Bool = false) {
        guard let shape = bodies[i].shape else {
            if let proxy = bodies[i].proxy {
                tree.remove(proxy)
                bodies[i].proxy = nil
            }
            return
        }
        let box = shape.bounds(at: bodies[i].shapePose)
        if let proxy = bodies[i].proxy {
            if !force && bodies[i].fatBox.contains(box) { return }
            var fat = box.expanded(by: Self.aabbMargin)
            if bodies[i].motion != .static { fat = fat.swept(by: bodies[i].linearVelocity * fixedTimestep) }
            bodies[i].fatBox = fat
            tree.update(proxy, box: fat)
        } else {
            bodies[i].fatBox = box.expanded(by: Self.aabbMargin)
            bodies[i].proxy = tree.insert(bodies[i].fatBox, item: i)
        }
        if !movedProxies.contains(i) { movedProxies.append(i) }
    }

    private func removeContacts(of i: Int) {
        var ended: [PhysicsEvent] = []
        contacts.removeAll { c in
            guard c.a == i || c.b == i else { return false }
            contactKeys.remove(c.key)
            if c.touching { ended.append(endEvent(c)) }
            return true
        }
        emit(ended)
    }

    // MARK: - Joints

    @discardableResult
    public func addJoint(_ d: JointDescriptor) -> JointID? {
        guard let a = index(of: d.bodyA) else { return nil }
        let b = d.bodyB.flatMap(index(of:)) ?? 0
        if d.bodyB != nil && b == 0 { return nil }
        let index = freeJoints.popLast() ?? {
            joints.append(JointData())
            return joints.count - 1
        }()
        var joint = JointData()
        joint.generation = joints[index].generation &+ 1
        joint.isAlive = true
        joint.kind = d.kind
        joint.a = a
        joint.b = b
        joint.entity = d.entity
        joint.collideConnected = d.collideConnected
        let bodyA = bodies[a], bodyB = bodies[b]
        let anchorB = d.kind == .distance ? (d.anchorB ?? d.anchor) : d.anchor
        joint.localAnchorA = bodyA.pose.rotation.conjugate * (d.anchor - bodyA.center)
        joint.localAnchorB = bodyB.pose.rotation.conjugate * (anchorB - bodyB.center)
        let axis = normalize(d.axis)
        joint.localAxisA = bodyA.pose.rotation.conjugate * axis
        joint.localAxisB = bodyB.pose.rotation.conjugate * axis
        joint.relativeRotation = bodyA.pose.rotation.conjugate * bodyB.pose.rotation
        joint.length = length(anchorB - d.anchor)
        joints[index] = joint
        if !d.collideConnected {
            let key = pairKey(a, b)
            jointPairs[key, default: 0] += 1
            contacts.removeAll { c in
                guard c.key == key else { return false }
                contactKeys.remove(key)
                return true
            }
        }
        wake(a)
        wake(b)
        return JointID(index: UInt32(index), generation: joint.generation)
    }

    public func removeJoint(_ id: JointID) {
        let i = Int(id.index)
        guard i < joints.count, joints[i].isAlive, joints[i].generation == id.generation else { return }
        removeJoint(at: i)
    }

    func removeJoint(at i: Int) {
        let joint = joints[i]
        if !joint.collideConnected {
            let key = pairKey(joint.a, joint.b)
            if let n = jointPairs[key], n > 1 { jointPairs[key] = n - 1 } else { jointPairs[key] = nil }
            // Let the pair be found again.
            for k in [joint.a, joint.b] where k != 0 && bodies[k].isAlive && !movedProxies.contains(k) { movedProxies.append(k) }
        }
        wake(joint.a)
        wake(joint.b)
        if let entity = joint.entity, jointForEntity[entity] == i { jointForEntity[entity] = nil }
        let generation = joint.generation
        joints[i] = JointData()
        joints[i].generation = generation
        freeJoints.append(i)
    }

    public func contains(_ id: JointID) -> Bool {
        let i = Int(id.index)
        return i < joints.count && joints[i].isAlive && joints[i].generation == id.generation
    }

    public var jointCount: Int { joints.filter(\.isAlive).count }

    // MARK: - Stepping

    /// Advances by `dt` in fixed steps of `fixedTimestep`, carrying the remainder to the next
    /// call (at most `maxStepsPerAdvance` steps; the rest is dropped). Clears `events` first.
    /// Returns the number of steps taken.
    @discardableResult
    public func advance(by dt: Float) -> Int {
        clearEvents()
        accumulator += max(dt, 0)
        var steps = 0
        while accumulator + fixedTimestep * 1e-4 >= fixedTimestep {
            if steps == maxStepsPerAdvance {
                accumulator = 0
                break
            }
            accumulator = max(accumulator - fixedTimestep, 0)
            step(fixedTimestep)
            steps += 1
        }
        return steps
    }

    /// How far `advance(by:)` is between the last step and the next one, in [0, 1).
    public var interpolationAlpha: Float { min(accumulator / fixedTimestep, 1) }

    /// Draw the ECS bodies at poses interpolated between the last two steps (by the world's
    /// `time.alpha`) instead of the latest one; a body's `RigidBody.interpolation` overrides
    /// this. Only the `Transform`s shown change: the simulation and `pose(of:)` stay exact.
    public var interpolatesPoses = false

    /// The body's pose `alpha` of the way from its pose before the last step to its current
    /// one (default: `interpolationAlpha`), for rendering without the ECS.
    public func interpolatedPose(of id: BodyID, alpha: Float? = nil) -> Pose? {
        guard let i = index(of: id) else { return nil }
        return interpolated(i, alpha ?? interpolationAlpha)
    }

    func interpolated(_ i: Int, _ alpha: Float) -> Pose {
        let b = bodies[i]
        guard b.motion != .static, b.previousPose != b.pose else { return b.pose }
        return Pose(position: b.previousPose.position + (b.pose.position - b.previousPose.position) * alpha,
                    rotation: Quat.slerp(b.previousPose.rotation, b.pose.rotation, alpha).normalized)
    }

    public func clearEvents() { events.removeAll(keepingCapacity: true) }

    /// One simulation step of `dt` seconds.
    public func step(_ dt: Float) {
        guard dt > 0 else { return }
        let firstEvent = events.count
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion != .static { bodies[i].previousPose = bodies[i].pose }
        findNewPairs()
        updateContacts(dt)
        Profiler.scope("islands") { buildIslandsAndWake() }
        Profiler.scope("solver") { solve(dt) }
        Profiler.scope("sleep update") { updateSleep(dt) }
        // Kinematic bodies fall asleep after every step (their target is spent) but did move.
        for i in bodies.indices where bodies[i].isAlive && (bodies[i].isAwake || bodies[i].motion == .kinematic) && bodies[i].motion != .static {
            refreshProxy(i)
        }
        stepCount += 1
        if let onEvent {
            for event in events[firstEvent...] { onEvent(event) }
        }
    }

    private func findNewPairs() {
        guard !movedProxies.isEmpty else { return }
        let moved = movedProxies.sorted()
        movedProxies.removeAll(keepingCapacity: true)
        // Tree queries only read, so the moved bodies query on the job system; the pairs are
        // sorted below, so the order they are found in doesn't matter.
        let (bodies, tree, existing) = (self.bodies, self.tree, self.contactKeys)
        let found = jobs.parallelMap(moved.count, batchSize: 32, name: "physics pairs") { k -> [UInt64] in
            let i = moved[k]
            guard bodies[i].isAlive && bodies[i].proxy != nil else { return [] }
            var pairs: [UInt64] = []
            tree.query(bodies[i].fatBox) { other in
                if other != i && shouldCollide(i, other) {
                    let key = pairKey(i, other)
                    if !existing.contains(key) { pairs.append(key) }
                }
                return true
            }
            return pairs
        }
        var newPairs = found.flatMap { $0 }
        newPairs.sort()
        var last: UInt64?
        for key in newPairs where key != last {
            last = key
            let a = Int(key >> 32), b = Int(key & 0xFFFF_FFFF)
            contactKeys.insert(key)
            contacts.append(Contact(a: a, b: b, key: key, isTrigger: bodies[a].isTrigger || bodies[b].isTrigger,
                                    friction: (bodies[a].material.friction * bodies[b].material.friction).squareRoot(),
                                    restitution: max(bodies[a].material.restitution, bodies[b].material.restitution)))
        }
    }

    func pairKey(_ a: Int, _ b: Int) -> UInt64 { UInt64(min(a, b)) << 32 | UInt64(max(a, b)) }

    private func shouldCollide(_ i: Int, _ j: Int) -> Bool {
        let a = bodies[i], b = bodies[j]
        guard a.shape != nil, b.shape != nil else { return false }
        guard a.layer & b.mask != 0, b.layer & a.mask != 0 else { return false }
        if a.isTrigger && b.isTrigger { return false }
        if a.motion != .dynamic && b.motion != .dynamic {
            // Only triggers see non-dynamic bodies, and only moving (kinematic) ones.
            guard a.isTrigger || b.isTrigger else { return false }
            if a.motion == .static && b.motion == .static { return false }
        }
        if a.shape!.isMesh && b.shape!.isMesh { return false }
        if jointPairs[pairKey(i, j)] != nil { return false }
        return true
    }

    /// What the narrowphase made of a contact this step.
    private enum ContactUpdate {
        /// Both bodies asleep or still: the manifold stays as it is.
        case inactive
        /// The fat boxes parted: the contact goes.
        case separated
        /// The new manifold (a trigger's has no points) and whether the shapes touch.
        case updated(points: [ManifoldPoint], touching: Bool)
    }

    /// The narrowphase of one contact. It reads only the contact and its bodies, so contacts
    /// are processed in parallel on the job system.
    private nonisolated static func narrowphase(_ c: Contact, _ a: Body, _ b: Body, dt: Float, speculativeDistance: Float,
                                                linearSlop: Float) -> ContactUpdate {
        let active = (a.isAwake && a.motion != .static) || (b.isAwake && b.motion != .static)
        guard active else { return .inactive }
        guard a.fatBox.overlaps(b.fatBox) else { return .separated }
        if c.isTrigger {
            let points = Narrowphase.collide(a.shape!, a.shapePose, b.shape!, b.shapePose, margin: 0)
            return .updated(points: [], touching: points.contains { $0.separation <= 0 })
        }
        // Look as far ahead as the bodies can close in one step, so fast bodies are
        // caught by speculative points instead of tunneling.
        let closing = length(b.linearVelocity - a.linearVelocity) + length(a.angularVelocity) * a.shape!.extent
            + length(b.angularVelocity) * b.shape!.extent
        let found = Narrowphase.collide(a.shape!, a.shapePose, b.shape!, b.shapePose,
                                        margin: speculativeDistance + closing * dt)
        var points: [ManifoldPoint] = []
        points.reserveCapacity(found.count)
        for p in found {
            var m = ManifoldPoint(localA: a.pose.rotation.conjugate * (p.pointA - a.center),
                                  localB: b.pose.rotation.conjugate * (p.pointB - b.center),
                                  normal: p.normal, separation: p.separation, position: (p.pointA + p.pointB) * 0.5)
            // Warm start from the old point nearest on body A (same feature, roughly).
            var best = 0.02 * 0.02 as Float
            for old in c.points where dot(old.normal, m.normal) > 0.95 {
                let d = lengthSquared(old.localA - m.localA)
                if d < best {
                    best = d
                    m.normalImpulse = old.normalImpulse
                }
            }
            points.append(m)
        }
        return .updated(points: points, touching: points.contains { $0.separation <= linearSlop * 2 })
    }

    private func updateContacts(_ dt: Float) {
        // The narrowphase in parallel (each contact on its own), then removals and events in
        // contact order, so nothing depends on the thread count.
        let (previous, bodies) = (contacts, self.bodies)
        let (speculativeDistance, linearSlop) = (self.speculativeDistance, self.linearSlop)
        let updates = jobs.parallelMap(previous.count, batchSize: 16, name: "narrowphase") { k in
            Self.narrowphase(previous[k], bodies[previous[k].a], bodies[previous[k].b], dt: dt,
                             speculativeDistance: speculativeDistance, linearSlop: linearSlop)
        }
        var kept: [Contact] = []
        kept.reserveCapacity(previous.count)
        var newEvents: [PhysicsEvent] = []
        for (k, var c) in previous.enumerated() {
            let a = bodies[c.a], b = bodies[c.b]
            let wasTouching = c.touching
            switch updates[k] {
            case .inactive:
                if c.isTrigger && c.touching { newEvents.append(triggerEvent(.triggerStayed, c)) }
                kept.append(c)
                continue
            case .separated:
                contactKeys.remove(c.key)
                if c.touching { newEvents.append(endEvent(c)) }
                continue
            case .updated(let points, let touching):
                c.points = points
                c.touching = touching
            }
            if c.isTrigger {
                if c.touching { newEvents.append(triggerEvent(wasTouching ? .triggerStayed : .triggerEntered, c)) }
                if wasTouching && !c.touching { newEvents.append(triggerEvent(.triggerExited, c)) }
            } else {
                let points = c.points
                if points.isEmpty {
                    c.tangentImpulse = .zero
                    c.twistImpulse = 0
                }
                if c.touching && !wasTouching {
                    let deepest = points.min { $0.separation < $1.separation }!
                    newEvents.append(PhysicsEvent(kind: .collisionBegan, bodyA: id(c.a), bodyB: id(c.b), entityA: a.entity,
                                                  entityB: b.entity, point: deepest.position, normal: deepest.normal))
                } else if wasTouching && !c.touching {
                    newEvents.append(endEvent(c))
                }
            }
            kept.append(c)
        }
        contacts = kept
        emit(newEvents)
    }

    private func triggerEvent(_ kind: PhysicsEvent.Kind, _ c: Contact) -> PhysicsEvent {
        // The trigger first.
        let (t, o) = bodies[c.a].isTrigger ? (c.a, c.b) : (c.b, c.a)
        return PhysicsEvent(kind: kind, bodyA: id(t), bodyB: id(o), entityA: bodies[t].entity, entityB: bodies[o].entity,
                            point: .zero, normal: .zero)
    }

    private func endEvent(_ c: Contact) -> PhysicsEvent {
        if c.isTrigger { return triggerEvent(.triggerExited, c) }
        return PhysicsEvent(kind: .collisionEnded, bodyA: id(c.a), bodyB: id(c.b), entityA: bodies[c.a].entity,
                            entityB: bodies[c.b].entity, point: .zero, normal: .zero)
    }

    private func emit(_ newEvents: [PhysicsEvent]) {
        events += newEvents
    }

    // MARK: - Islands and sleep

    /// Island root per body (union-find over touching contacts and joints between dynamic bodies).
    private var islandParent: [Int] = []

    private func findRoot(_ i: Int) -> Int {
        var i = i
        while islandParent[i] != i {
            islandParent[i] = islandParent[islandParent[i]]
            i = islandParent[i]
        }
        return i
    }

    private func union(_ a: Int, _ b: Int) {
        let ra = findRoot(a), rb = findRoot(b)
        if ra != rb { islandParent[max(ra, rb)] = min(ra, rb) }
    }

    private func buildIslandsAndWake() {
        islandParent = Array(bodies.indices)
        var awakeRoot = [Bool](repeating: false, count: bodies.count)
        for c in contacts where c.touching && !c.isTrigger {
            if bodies[c.a].motion == .dynamic && bodies[c.b].motion == .dynamic { union(c.a, c.b) }
        }
        for j in joints where j.isAlive && bodies[j.a].motion == .dynamic && bodies[j.b].motion == .dynamic { union(j.a, j.b) }
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion == .dynamic && bodies[i].isAwake {
            awakeRoot[findRoot(i)] = true
        }
        // Moving kinematic bodies wake what they touch.
        for c in contacts where c.touching && !c.isTrigger {
            for (k, other) in [(c.a, c.b), (c.b, c.a)] where bodies[k].motion == .kinematic && bodies[k].isAwake {
                if bodies[other].motion == .dynamic {
                    awakeRoot[findRoot(other)] = true
                    bodies[other].sleepTime = 0
                }
            }
        }
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion == .dynamic && !bodies[i].isAwake {
            if awakeRoot[findRoot(i)] { wake(i) }
        }
    }

    private func updateSleep(_ dt: Float) {
        let linear = sleepLinearVelocity * sleepLinearVelocity, angular = sleepAngularVelocity * sleepAngularVelocity
        var islandMinimum = [Float](repeating: .infinity, count: bodies.count)
        for i in bodies.indices where bodies[i].isAlive && bodies[i].motion == .dynamic && bodies[i].isAwake {
            let b = bodies[i]
            if !b.allowSleep || lengthSquared(b.linearVelocity) > linear || lengthSquared(b.angularVelocity) > angular {
                bodies[i].sleepTime = 0
            } else {
                bodies[i].sleepTime += dt
            }
            let root = findRoot(i)
            islandMinimum[root] = min(islandMinimum[root], bodies[i].sleepTime)
        }
        for i in bodies.indices where bodies[i].isAlive && bodies[i].isAwake {
            switch bodies[i].motion {
            case .dynamic:
                if islandMinimum[findRoot(i)] >= timeToSleep {
                    bodies[i].isAwake = false
                    bodies[i].linearVelocity = .zero
                    bodies[i].angularVelocity = .zero
                }
            case .kinematic:
                // A kinematic body nobody moves stops counting as moving.
                if bodies[i].linearVelocity == .zero && bodies[i].angularVelocity == .zero && bodies[i].kinematicTarget == nil {
                    bodies[i].isAwake = false
                }
            case .static:
                break
            }
        }
    }
}

/// A body's state. Static and kinematic bodies have zero inverse mass and inertia.
struct Body {
    var generation: UInt32 = 0
    var isAlive = false
    var motion: MotionType = .static
    /// The body's frame (the entity's position and rotation).
    var pose = Pose()
    /// Center of mass in the body frame, and in the world.
    var localCenter = Vec3.zero
    var center = Vec3.zero
    var linearVelocity = Vec3.zero
    var angularVelocity = Vec3.zero
    var force = Vec3.zero, torque = Vec3.zero
    var mass: Float = 0
    var invMass: Float = 0
    var invInertiaLocal = Mat3.zero
    var invInertiaWorld = Mat3.zero
    var linearDamping: Float = 0
    var angularDamping: Float = 0
    var gravityScale: Float = 1
    var allowSleep = true
    var isAwake = false
    var sleepTime: Float = 0
    /// Where `moveKinematic` puts the body at the end of the step.
    var kinematicTarget: Pose?
    /// The velocities a kinematic body had in the last step (it is back to zero afterwards).
    var carryLinear = Vec3.zero
    var carryAngular = Vec3.zero
    /// The pose before the last step, for interpolation (never read by the simulation).
    var previousPose = Pose()
    /// The `Transform` the ECS interpolation wrote for display, until the next fixed step.
    var smoothed: Transform?

    var shape: Shape?
    /// The collider's pose in the body frame.
    var shapeOffset = Pose()
    var material = ColliderMaterial()
    var isTrigger = false
    var layer: UInt32 = 1
    var mask: UInt32 = .max
    var proxy: Int?
    var fatBox = AABB(min: .zero, max: .zero)

    var entity: Entity?
    /// ECS sync: what the body was made from and last wrote back (PhysicsECS.swift).
    var sync = BodySync()

    var shapePose: Pose { pose * shapeOffset }
    /// Velocities change in the solver (awake dynamic bodies).
    var isSolverActive: Bool { motion == .dynamic && isAwake }

    mutating func updateMass() {
        if motion == .dynamic, let shape, !shape.isMesh {
            let props = shape.massProperties(density: max(material.density, 1e-6))
            let r = Mat3(shapeOffset.rotation)
            mass = props.mass
            invMass = props.mass > 0 ? 1 / props.mass : 0
            localCenter = shapeOffset.transform(props.center)
            invInertiaLocal = (r * props.inertia * r.transpose).inverse
        } else {
            mass = 0
            invMass = 0
            localCenter = shape.map { shapeOffset.transform($0.localBounds.center) } ?? .zero
            invInertiaLocal = .zero
            if motion == .dynamic {
                // A dynamic body without a usable shape: a unit point mass.
                mass = 1
                invMass = 1
                localCenter = .zero
                invInertiaLocal = .identity
            }
        }
        updateDerived()
    }

    mutating func updateDerived() {
        center = pose.transform(localCenter)
        let r = Mat3(pose.rotation)
        invInertiaWorld = r * invInertiaLocal * r.transpose
    }
}

struct ManifoldPoint {
    /// Anchors relative to each body's center of mass, in the body's frame.
    var localA: Vec3
    var localB: Vec3
    /// World normal from A to B, as found.
    var normal: Vec3
    var separation: Float
    /// World position (for events and debug drawing).
    var position: Vec3
    var normalImpulse: Float = 0
}

struct Contact {
    var a: Int, b: Int
    var key: UInt64
    var isTrigger: Bool
    var friction: Float
    var restitution: Float
    var points: [ManifoldPoint] = []
    var touching = false
    /// Friction impulses at the manifold center (warm starting).
    var tangentImpulse = Vec2.zero
    var twistImpulse: Float = 0

    init(a: Int, b: Int, key: UInt64, isTrigger: Bool, friction: Float, restitution: Float) {
        self.a = a
        self.b = b
        self.key = key
        self.isTrigger = isTrigger
        self.friction = friction
        self.restitution = restitution
    }
}
