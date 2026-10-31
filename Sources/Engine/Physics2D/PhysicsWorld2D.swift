import Foundation

/// A 2D rigid body simulation: static, kinematic and dynamic bodies with one collider each
/// (circle, box, convex polygon, capsule, edge, chain), joints, a broadphase AABB tree,
/// contact manifolds of up to two points and a sequential-impulse solver with warm starting,
/// friction, restitution and sleeping. Same design as the 3D `PhysicsWorld`, after Box2D v3's
/// soft step; units are meters, kilograms (density is kg/m²) and radians, y up.
///
/// Use it directly (`addBody`, `step` or `advance(by:)`), or let a `World` drive it from
/// components (`world.addPhysics2D(physics)`, see Physics2DECS.swift).
///
/// The simulation is deterministic: bodies, fixtures, contacts and joints live in arrays in
/// creation order, new pairs are sorted, and nothing iterates a dictionary or reads a clock,
/// so the same calls give bit-identical results.
///
/// One step (`step(_:)`):
/// 1. New pairs: every collider whose fat box moved queries the tree; new pairs become contacts.
/// 2. Narrowphase for contacts with a moving body (manifolds matched to last step's points
///    for warm starting); contacts whose fat boxes separated are removed. One-way platforms,
///    begin / end / trigger events.
/// 3. Islands (bodies connected by touching contacts and joints): an island with an awake
///    body wakes as a whole.
/// 4. The solver (ContactSolver2D.swift): `substeps` substeps of gravity and forces, soft
///    contacts (with speculative points that stop a body at the surface), friction and joints,
///    then restitution.
/// 5. Sleep: an island whose bodies have all been slow for `timeToSleep` goes to sleep.
@MainActor
public final class PhysicsWorld2D {
    public var gravity = Vec2(0, -9.81)
    /// The solver runs this many substeps per step (more: stiffer stacks and joints).
    public var substeps = 4
    /// Constraint iterations per substep.
    public var velocityIterations = 1
    /// Contact stiffness: overlapping bodies are pushed apart by a spring of this frequency
    /// (capped at a quarter of the substep rate) and damping ratio; joints use twice the frequency.
    public var contactHertz: Float = 30
    public var contactDampingRatio: Float = 10
    public var jointDampingRatio: Float = 2
    /// The step `advance(by:)` takes.
    public var fixedTimestep: Float = 1.0 / 60.0
    /// `advance(by:)` drops time beyond this many steps per call.
    public var maxStepsPerAdvance = 8
    /// Seconds a body must be slow before its island may sleep.
    public var timeToSleep: Float = 0.5
    public var sleepLinearVelocity: Float = 0.05
    public var sleepAngularVelocity: Float = 0.05
    /// Overlap left alone, to keep contacts alive between steps.
    public var linearSlop: Float = 0.005
    /// Points within this distance (plus how far the bodies can close in a step) count as
    /// contacts (speculative), so bodies stop at surfaces instead of sinking into them.
    public var speculativeDistance: Float = 0.02
    /// Approach speeds below this don't bounce.
    public var restitutionThreshold: Float = 1
    /// Solves independent islands in parallel (the rest of the step stays on the calling
    /// thread). Results are the same for any thread count.
    public var jobs = JobSystem.shared

    /// Events of the steps since the last `clearEvents()` (`advance(by:)` and the ECS
    /// integration clear them once per frame).
    public private(set) var events: [PhysicsEvent2D] = []
    /// Called for each event at the end of the step that produced it.
    public var onEvent: ((PhysicsEvent2D) -> Void)?

    /// Total steps taken.
    public private(set) var stepCount = 0

    var bodies: [Body2D] = []
    var freeBodies: [Int] = []
    var fixtures: [Fixture2D] = []
    var freeFixtures: [Int] = []
    var contacts: [Contact2D] = []
    /// Pair keys of `contacts`, for lookups only (never iterated).
    var contactKeys: Set<UInt64> = []
    var joints: [JointData2D] = []
    var freeJoints: [Int] = []
    /// Body pairs connected by a joint that doesn't collide them (keys, lookups only).
    var jointPairs: [UInt64: Int] = [:]
    var tree = AABBTree2D()
    /// Fixtures whose proxy moved since the last pair search.
    var movedProxies: [Int] = []
    var accumulator: Float = 0

    // ECS bookkeeping (Physics2DECS.swift).
    var bodyForEntity: [Entity: Int] = [:]
    var jointForEntity: [Entity: Int] = [:]

    /// Fat boxes are this much larger than their shape.
    static let aabbMargin: Float = 0.1

    public init() {
        // Slot 0 is the world: the static body joints without a second body attach to.
        var ground = Body2D()
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
    public func addBody(_ d: BodyDescriptor2D) -> Body2DID {
        let index = freeBodies.popLast() ?? {
            bodies.append(Body2D())
            return bodies.count - 1
        }()
        var body = Body2D()
        body.generation = bodies[index].generation &+ 1
        body.isAlive = true
        body.motion = d.motion
        body.pose = d.pose
        body.linearVelocity = d.motion == .static ? .zero : d.linearVelocity
        body.angularVelocity = d.motion == .static ? 0 : d.angularVelocity
        body.linearDamping = d.linearDamping
        body.angularDamping = d.angularDamping
        body.gravityScale = d.gravityScale
        body.allowSleep = d.allowSleep
        body.fixedRotation = d.fixedRotation
        body.entity = d.entity
        body.previousPose = body.pose
        bodies[index] = body
        setShape(index, d.shape, offset: d.shapeOffset, material: d.material, isTrigger: d.isTrigger, isOneWay: d.isOneWay,
                 layer: d.layer, mask: d.mask)
        bodies[index].isAwake = d.motion != .static && !d.startsAsleep
        return Body2DID(index: index, generation: body.generation)
    }

    /// Removes the body, its contacts (reporting `collisionEnded` / `triggerExited`) and its joints.
    public func removeBody(_ id: Body2DID) {
        guard let i = index(of: id) else { return }
        removeBody(at: i)
    }

    func removeBody(at i: Int) {
        for f in bodies[i].fixtures { removeFixture(f) }
        var kept: [Contact2D] = []
        var ended: [PhysicsEvent2D] = []
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
        if let entity = bodies[i].entity, bodyForEntity[entity] == i { bodyForEntity[entity] = nil }
        let generation = bodies[i].generation
        bodies[i] = Body2D()
        bodies[i].generation = generation
        freeBodies.append(i)
        emit(ended)
    }

    public func contains(_ id: Body2DID) -> Bool { index(of: id) != nil }

    func index(of id: Body2DID) -> Int? {
        let i = Int(id.index)
        guard i > 0, i < bodies.count, bodies[i].isAlive, bodies[i].generation == id.generation else { return nil }
        return i
    }

    func id(_ i: Int) -> Body2DID { Body2DID(index: i, generation: bodies[i].generation) }

    /// Every body, in creation-slot order.
    public var bodyIDs: [Body2DID] { bodies.indices.dropFirst().filter { bodies[$0].isAlive }.map(id) }

    public func pose(of id: Body2DID) -> Pose2D? { index(of: id).map { bodies[$0].pose } }
    public func motion(of id: Body2DID) -> MotionType? { index(of: id).map { bodies[$0].motion } }
    public func entity(of id: Body2DID) -> Entity? { index(of: id).flatMap { bodies[$0].entity } }
    public func isAwake(_ id: Body2DID) -> Bool { index(of: id).map { bodies[$0].isAwake } ?? false }
    public func mass(of id: Body2DID) -> Float { index(of: id).map { bodies[$0].mass } ?? 0 }
    /// The center of mass in world space.
    public func centerOfMass(of id: Body2DID) -> Vec2? { index(of: id).map { bodies[$0].center } }
    /// The collider's world bounds.
    public func bounds(of id: Body2DID) -> AABB2? {
        guard let i = index(of: id), let first = bodies[i].fixtures.first else { return nil }
        var box = fixtures[first].geom.bounds(at: bodies[i].pose)
        for f in bodies[i].fixtures.dropFirst() { box = box.union(fixtures[f].geom.bounds(at: bodies[i].pose)) }
        return box
    }

    public func linearVelocity(of id: Body2DID) -> Vec2 { index(of: id).map { bodies[$0].linearVelocity } ?? .zero }
    public func angularVelocity(of id: Body2DID) -> Float { index(of: id).map { bodies[$0].angularVelocity } ?? 0 }

    /// The velocity of the body's material at a world point (a kinematic body reports how it
    /// moved in the last step; its own velocity is zero between steps).
    public func velocity(of id: Body2DID, at point: Vec2) -> Vec2 {
        guard let i = index(of: id) else { return .zero }
        let b = bodies[i]
        switch b.motion {
        case .static: return .zero
        case .kinematic: return b.carryLinear + cross2(b.carryAngular, point - b.center)
        case .dynamic: return b.linearVelocity + cross2(b.angularVelocity, point - b.center)
        }
    }

    public func setLinearVelocity(_ id: Body2DID, _ v: Vec2) {
        guard let i = index(of: id), bodies[i].motion != .static else { return }
        bodies[i].linearVelocity = v
        wake(i)
    }

    public func setAngularVelocity(_ id: Body2DID, _ w: Float) {
        guard let i = index(of: id), bodies[i].motion != .static else { return }
        bodies[i].angularVelocity = w
        wake(i)
    }

    /// Adds `impulse` (N s) at the world point `point` (the center of mass by default).
    public func applyImpulse(_ id: Body2DID, _ impulse: Vec2, at point: Vec2? = nil) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].linearVelocity += impulse * bodies[i].invMass
        if let point { bodies[i].angularVelocity += bodies[i].invInertia * cross2(point - bodies[i].center, impulse) }
        wake(i)
    }

    /// Adds a force (N) for the next step only, at the world point `point` (default: the center of mass).
    public func applyForce(_ id: Body2DID, _ force: Vec2, at point: Vec2? = nil) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].force += force
        if let point { bodies[i].torque += cross2(point - bodies[i].center, force) }
        wake(i)
    }

    public func applyTorque(_ id: Body2DID, _ torque: Float) {
        guard let i = index(of: id), bodies[i].motion == .dynamic else { return }
        bodies[i].torque += torque
        wake(i)
    }

    public func wake(_ id: Body2DID) {
        if let i = index(of: id) { wake(i) }
    }

    func wake(_ i: Int) {
        guard i > 0, bodies[i].isAlive, bodies[i].motion != .static else { return }
        bodies[i].isAwake = true
        bodies[i].sleepTime = 0
    }

    /// Teleports the body (waking it and its neighbors); velocities are kept.
    public func setPose(_ id: Body2DID, _ pose: Pose2D) {
        guard let i = index(of: id) else { return }
        setPose(at: i, pose)
    }

    func setPose(at i: Int, _ pose: Pose2D) {
        bodies[i].pose = pose
        bodies[i].previousPose = pose
        bodies[i].updateDerived()
        bodies[i].kinematicTarget = nil
        wake(i)
        refreshProxies(i, force: true)
    }

    /// Moves a kinematic body to `pose` during the next step of `dt` seconds: it gets the
    /// velocity that gets it there (so it pushes and carries bodies) and lands exactly.
    public func moveKinematic(_ id: Body2DID, to pose: Pose2D, dt: Float) {
        guard let i = index(of: id) else { return }
        moveKinematic(at: i, to: pose, dt: dt)
    }

    func moveKinematic(at i: Int, to pose: Pose2D, dt: Float) {
        guard bodies[i].motion == .kinematic, dt > 0 else { return setPose(at: i, pose) }
        let delta = pose.rotation * bodies[i].pose.rotation.inverse
        bodies[i].linearVelocity = (pose.position - bodies[i].pose.position) / dt
        bodies[i].angularVelocity = delta.angle / dt
        bodies[i].kinematicTarget = pose
        wake(i)
    }

    public func setMotion(_ id: Body2DID, _ motion: MotionType) {
        guard let i = index(of: id) else { return }
        setMotion(at: i, motion)
    }

    func setMotion(at i: Int, _ motion: MotionType) {
        guard bodies[i].motion != motion else { return }
        bodies[i].motion = motion
        bodies[i].kinematicTarget = nil
        if motion == .static {
            bodies[i].linearVelocity = .zero
            bodies[i].angularVelocity = 0
            bodies[i].isAwake = false
        } else {
            bodies[i].isAwake = true
            bodies[i].sleepTime = 0
        }
        updateMass(i)
        // Pairs are filtered by motion type: look again.
        removeContacts(of: i)
        refreshProxies(i, force: true)
    }

    // MARK: - Colliders

    /// Replaces the body's collider.
    public func setShape(_ id: Body2DID, _ shape: ColliderShape2D?, offset: Pose2D = .identity,
                         material: ColliderMaterial = ColliderMaterial(density: 1), isTrigger: Bool = false,
                         isOneWay: Bool = false, layer: UInt32 = 1, mask: UInt32 = .max) {
        guard let i = index(of: id) else { return }
        setShape(i, shape, offset: offset, material: material, isTrigger: isTrigger, isOneWay: isOneWay, layer: layer, mask: mask)
    }

    func setShape(_ i: Int, _ shape: ColliderShape2D?, offset: Pose2D, material: ColliderMaterial, isTrigger: Bool,
                  isOneWay: Bool, layer: UInt32, mask: UInt32) {
        removeContacts(of: i)
        for f in bodies[i].fixtures { removeFixture(f) }
        bodies[i].fixtures = []
        bodies[i].shape = shape
        bodies[i].shapeOffset = offset
        bodies[i].material = material
        bodies[i].isTrigger = isTrigger
        bodies[i].isOneWay = isOneWay
        bodies[i].layer = layer
        bodies[i].mask = mask
        if let shape {
            for geom in shape.geoms(offset: offset) {
                var fixture = Fixture2D()
                fixture.isAlive = true
                fixture.body = i
                fixture.geom = geom
                fixture.material = material
                fixture.isTrigger = isTrigger
                fixture.isOneWay = isOneWay
                fixture.layer = layer
                fixture.mask = mask
                let f = freeFixtures.popLast() ?? {
                    fixtures.append(Fixture2D())
                    return fixtures.count - 1
                }()
                fixtures[f] = fixture
                bodies[i].fixtures.append(f)
            }
        }
        updateMass(i)
        refreshProxies(i, force: true)
        wake(i)
    }

    private func removeFixture(_ f: Int) {
        if let proxy = fixtures[f].proxy { tree.remove(proxy) }
        fixtures[f] = Fixture2D()
        freeFixtures.append(f)
        movedProxies.removeAll { $0 == f }
    }

    /// Mass, center of mass and inertia from the collider and density.
    func updateMass(_ i: Int) {
        var b = bodies[i]
        b.mass = 0
        b.invMass = 0
        b.invInertia = 0
        b.localCenter = .zero
        if b.motion == .dynamic {
            var mass: Float = 0, center = Vec2.zero, inertiaAboutOrigin: Float = 0
            if let shape = b.shape, shape.isSolid {
                for f in b.fixtures {
                    let data = fixtures[f].geom.massData(density: b.material.density)
                    mass += data.mass
                    center += data.center * data.mass
                    inertiaAboutOrigin += data.inertia + data.mass * dot2(data.center, data.center)
                }
            }
            if mass > 0 {
                center /= mass
                b.mass = mass
                b.invMass = 1 / mass
                b.localCenter = center
                let inertia = inertiaAboutOrigin - mass * dot2(center, center)
                if inertia > 0 && !b.fixedRotation { b.invInertia = 1 / inertia }
            } else {
                // A dynamic body without area (an edge, or no shape): 1 kg, doesn't rotate.
                b.mass = 1
                b.invMass = 1
            }
        }
        b.updateDerived()
        var extent: Float = 0
        for f in b.fixtures { extent = max(extent, fixtures[f].geom.extent) }
        b.extent = extent
        bodies[i] = b
    }

    /// Updates the broadphase boxes of the body's colliders; they only change when the shape
    /// leaves its fat box (or `force`).
    func refreshProxies(_ i: Int, force: Bool = false) {
        for f in bodies[i].fixtures {
            let box = fixtures[f].geom.bounds(at: bodies[i].pose)
            if let proxy = fixtures[f].proxy {
                if !force && fixtures[f].fatBox.contains(box) { continue }
                var fat = box.expanded(by: Self.aabbMargin)
                if bodies[i].motion != .static { fat = fat.swept(by: bodies[i].linearVelocity * fixedTimestep) }
                fixtures[f].fatBox = fat
                tree.update(proxy, box: fat)
            } else {
                fixtures[f].fatBox = box.expanded(by: Self.aabbMargin)
                fixtures[f].proxy = tree.insert(fixtures[f].fatBox, item: f)
            }
            if !movedProxies.contains(f) { movedProxies.append(f) }
        }
    }

    private func removeContacts(of i: Int) {
        var ended: [PhysicsEvent2D] = []
        contacts.removeAll { c in
            guard c.a == i || c.b == i else { return false }
            contactKeys.remove(c.key)
            if c.touching { ended.append(endEvent(c)) }
            return true
        }
        emit(ended)
    }

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
    /// `time.alpha`) instead of the latest one; a body's `RigidBody2D.interpolation` overrides
    /// this. Only the `Transform`s shown change: the simulation and `pose(of:)` stay exact.
    public var interpolatesPoses = false

    /// The body's pose `alpha` of the way from its pose before the last step to its current
    /// one (default: `interpolationAlpha`), for rendering without the ECS.
    public func interpolatedPose(of id: Body2DID, alpha: Float? = nil) -> Pose2D? {
        guard let i = index(of: id) else { return nil }
        return interpolated(i, alpha ?? interpolationAlpha)
    }

    func interpolated(_ i: Int, _ alpha: Float) -> Pose2D {
        let b = bodies[i]
        guard b.motion != .static, b.previousPose != b.pose else { return b.pose }
        let q0 = b.previousPose.rotation, q1 = b.pose.rotation
        // Shortest way round, then renormalize (nlerp).
        let sign: Float = q0.c * q1.c + q0.s * q1.s < 0 ? -1 : 1
        let c = q0.c + (q1.c * sign - q0.c) * alpha, s = q0.s + (q1.s * sign - q0.s) * alpha
        let m = (c * c + s * s).squareRoot()
        return Pose2D(position: b.previousPose.position + (b.pose.position - b.previousPose.position) * alpha,
                      rotation: m > 1e-9 ? Rot2(c: c / m, s: s / m) : q1)
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
            refreshProxies(i)
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
        var newPairs: [UInt64] = []
        for f in moved where fixtures[f].isAlive && fixtures[f].proxy != nil {
            tree.query(fixtures[f].fatBox) { other in
                if other != f && shouldCollide(f, other) {
                    let key = pairKey(f, other)
                    if !contactKeys.contains(key) { newPairs.append(key) }
                }
                return true
            }
        }
        newPairs.sort()
        var last: UInt64?
        for key in newPairs where key != last {
            last = key
            let fa = Int(key >> 32), fb = Int(key & 0xFFFF_FFFF)
            let a = fixtures[fa], b = fixtures[fb]
            contactKeys.insert(key)
            var contact = Contact2D(fa: fa, fb: fb, a: a.body, b: b.body, key: key, isTrigger: a.isTrigger || b.isTrigger,
                                    friction: (a.material.friction * b.material.friction).squareRoot(),
                                    restitution: max(a.material.restitution, b.material.restitution))
            if a.isOneWay || b.isOneWay { contact.oneWay = .undecided }
            contacts.append(contact)
        }
    }

    /// Key of a pair of fixtures (or of bodies, for `jointPairs`), smaller index first.
    func pairKey(_ a: Int, _ b: Int) -> UInt64 { UInt64(min(a, b)) << 32 | UInt64(max(a, b)) }

    private func shouldCollide(_ fi: Int, _ fj: Int) -> Bool {
        let fa = fixtures[fi], fb = fixtures[fj]
        guard fa.body != fb.body else { return false }
        guard fa.layer & fb.mask != 0, fb.layer & fa.mask != 0 else { return false }
        if fa.isTrigger && fb.isTrigger { return false }
        let a = bodies[fa.body], b = bodies[fb.body]
        if a.motion != .dynamic && b.motion != .dynamic {
            // Only triggers see non-dynamic bodies, and only moving (kinematic) ones.
            guard fa.isTrigger || fb.isTrigger else { return false }
            if a.motion == .static && b.motion == .static { return false }
        }
        if jointPairs[pairKey(fa.body, fb.body)] != nil { return false }
        return true
    }

    private func updateContacts(_ dt: Float) {
        var kept: [Contact2D] = []
        kept.reserveCapacity(contacts.count)
        var newEvents: [PhysicsEvent2D] = []
        for var c in contacts {
            let a = bodies[c.a], b = bodies[c.b]
            let fa = fixtures[c.fa], fb = fixtures[c.fb]
            let active = (a.isAwake && a.motion != .static) || (b.isAwake && b.motion != .static)
            if !active {
                // Both asleep or still: keep the manifold as it is.
                if c.isTrigger && c.touching { newEvents.append(triggerEvent(.triggerStayed, c)) }
                kept.append(c)
                continue
            }
            if !fa.fatBox.overlaps(fb.fatBox) {
                contactKeys.remove(c.key)
                if c.touching { newEvents.append(endEvent(c)) }
                continue
            }
            let wasTouching = c.touching
            if c.isTrigger {
                let m = Narrowphase2D.collide(fa.geom, a.pose, fb.geom, b.pose, margin: 0, slop: linearSlop)
                c.touching = m?.points.contains { $0.separation <= 0 } ?? false
                c.points = []
                if c.touching { newEvents.append(triggerEvent(wasTouching ? .triggerStayed : .triggerEntered, c)) }
                if wasTouching && !c.touching { newEvents.append(triggerEvent(.triggerExited, c)) }
            } else {
                // Look as far ahead as the bodies can close in one step, so fast bodies are
                // caught by speculative points instead of tunneling.
                let closing = length2(b.linearVelocity - a.linearVelocity) + abs(a.angularVelocity) * a.extent
                    + abs(b.angularVelocity) * b.extent
                var manifold = Narrowphase2D.collide(fa.geom, a.pose, fb.geom, b.pose,
                                                     margin: speculativeDistance + closing * dt, slop: linearSlop)
                if let m = manifold, c.oneWay != .none, !oneWayAllows(&c, m, fa, fb, a, b) { manifold = nil }
                var points: [ManifoldPoint2D] = []
                if let m = manifold {
                    c.normal = m.normal
                    points.reserveCapacity(m.points.count)
                    for p in m.points {
                        let onA = p.point - m.normal * (p.separation * 0.5), onB = p.point + m.normal * (p.separation * 0.5)
                        var mp = ManifoldPoint2D(localA: a.pose.rotation.inverseRotate(onA - a.center),
                                                 localB: b.pose.rotation.inverseRotate(onB - b.center),
                                                 separation: p.separation, position: p.point, id: p.id)
                        // Warm start from last step's point of the same feature.
                        if let old = c.points.first(where: { $0.id == p.id }) {
                            mp.normalImpulse = old.normalImpulse
                            mp.tangentImpulse = old.tangentImpulse
                        }
                        points.append(mp)
                    }
                }
                c.points = points
                c.touching = points.contains { $0.separation <= linearSlop * 2 }
                if c.touching && !wasTouching {
                    let deepest = points.min { $0.separation < $1.separation }!
                    newEvents.append(PhysicsEvent2D(kind: .collisionBegan, bodyA: id(c.a), bodyB: id(c.b), entityA: a.entity,
                                                    entityB: b.entity, point: deepest.position, normal: c.normal))
                } else if wasTouching && !c.touching {
                    newEvents.append(endEvent(c))
                }
            }
            kept.append(c)
        }
        contacts = kept
        emit(newEvents)
    }

    /// One-way platforms: decides when the pair first meets (a body whose lowest point is below
    /// the platform's top passes through until the pair separates) and, once solid, only
    /// supports from the top side.
    private func oneWayAllows(_ c: inout Contact2D, _ m: Manifold2D, _ fa: Fixture2D, _ fb: Fixture2D, _ a: Body2D, _ b: Body2D) -> Bool {
        let platformIsA = fa.isOneWay
        let platform = platformIsA ? a : b, other = platformIsA ? b : a
        let platformGeom = platformIsA ? fa.geom : fb.geom, otherGeom = platformIsA ? fb.geom : fa.geom
        let up = platform.pose.rotation.rotate(Vec2(0, 1))
        if c.oneWay == .undecided {
            let top = platformGeom.verts.map { dot2(platform.pose.transform($0), up) }.max()! + platformGeom.radius
            let bottom = otherGeom.verts.map { dot2(other.pose.transform($0), up) }.min()! - otherGeom.radius
            c.oneWay = bottom >= top - 0.05 ? .solid : .passing
        }
        guard c.oneWay == .solid else { return false }
        // The normal from the platform to the other body must point up.
        return dot2(platformIsA ? m.normal : -m.normal, up) > 0.1
    }

    private func triggerEvent(_ kind: PhysicsEvent2D.Kind, _ c: Contact2D) -> PhysicsEvent2D {
        // The trigger first.
        let (t, o) = fixtures[c.fa].isTrigger ? (c.a, c.b) : (c.b, c.a)
        return PhysicsEvent2D(kind: kind, bodyA: id(t), bodyB: id(o), entityA: bodies[t].entity, entityB: bodies[o].entity,
                              point: .zero, normal: .zero)
    }

    private func endEvent(_ c: Contact2D) -> PhysicsEvent2D {
        if c.isTrigger { return triggerEvent(.triggerExited, c) }
        return PhysicsEvent2D(kind: .collisionEnded, bodyA: id(c.a), bodyB: id(c.b), entityA: bodies[c.a].entity,
                              entityB: bodies[c.b].entity, point: .zero, normal: .zero)
    }

    private func emit(_ newEvents: [PhysicsEvent2D]) {
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
            if !b.allowSleep || lengthSquared2(b.linearVelocity) > linear || b.angularVelocity * b.angularVelocity > angular {
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
                    bodies[i].angularVelocity = 0
                }
            case .kinematic:
                // A kinematic body nobody moves stops counting as moving.
                if bodies[i].linearVelocity == .zero && bodies[i].angularVelocity == 0 && bodies[i].kinematicTarget == nil {
                    bodies[i].isAwake = false
                }
            case .static:
                break
            }
        }
    }
}

/// A collider of a body: a geom in the body's frame with its place in the broadphase.
struct Fixture2D {
    var isAlive = false
    var body = 0
    var geom = Geom2D(verts: [], radius: 0)
    var material = ColliderMaterial()
    var isTrigger = false
    var isOneWay = false
    var layer: UInt32 = 1
    var mask: UInt32 = .max
    var proxy: Int?
    var fatBox = AABB2(min: .zero, max: .zero)
}

/// A body's state. Static and kinematic bodies have zero inverse mass and inertia.
struct Body2D {
    var generation: UInt32 = 0
    var isAlive = false
    var motion = MotionType.static
    /// The body's frame (origin and rotation); `center` is the center of mass in the world.
    var pose = Pose2D.identity
    var previousPose = Pose2D.identity
    var center = Vec2.zero
    var localCenter = Vec2.zero
    var linearVelocity = Vec2.zero
    var angularVelocity: Float = 0
    var force = Vec2.zero
    var torque: Float = 0
    var mass: Float = 0
    var invMass: Float = 0
    var invInertia: Float = 0
    var linearDamping: Float = 0
    var angularDamping: Float = 0
    var gravityScale: Float = 1
    var allowSleep = true
    var fixedRotation = false
    var isAwake = false
    var sleepTime: Float = 0
    var extent: Float = 0
    var fixtures: [Int] = []
    // What the collider was made from (kept to remake it).
    var shape: ColliderShape2D?
    var shapeOffset = Pose2D.identity
    var material = ColliderMaterial()
    var isTrigger = false
    var isOneWay = false
    var layer: UInt32 = 1
    var mask: UInt32 = .max
    var entity: Entity?
    /// Where `moveKinematic` is taking the body, and how it moved in the last step.
    var kinematicTarget: Pose2D?
    var carryLinear = Vec2.zero
    var carryAngular: Float = 0
    // ECS sync state (Physics2DComponents.swift).
    var sync = BodySync2D()
    /// The interpolated `Transform` currently shown, if any.
    var smoothed: Transform?

    /// Awake and moved by the solver.
    var isSolverActive: Bool { isAwake && motion != .static }

    mutating func updateDerived() {
        center = pose.transform(localCenter)
    }
}

enum OneWayState {
    case none, undecided, solid, passing
}

struct ManifoldPoint2D {
    /// Anchors on the surfaces, relative to each body's center of mass, in the body's frame.
    var localA: Vec2, localB: Vec2
    var separation: Float
    var position: Vec2
    var id: UInt16
    var normalImpulse: Float = 0
    var tangentImpulse: Float = 0
}

struct Contact2D {
    var fa: Int, fb: Int
    var a: Int, b: Int
    var key: UInt64
    var isTrigger: Bool
    var friction: Float
    var restitution: Float
    var normal = Vec2(0, 1)
    var points: [ManifoldPoint2D] = []
    var touching = false
    var oneWay = OneWayState.none
}
