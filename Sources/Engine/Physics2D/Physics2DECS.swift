import Foundation

// Drives a PhysicsWorld2D from a World's components, like PhysicsECS.swift does for 3D. Each
// fixed step:
// 1. ECS -> physics: bodies for new `Collider2D`s, removed for despawned entities or removed
//    colliders; edited colliders and rigid bodies applied; a `Transform` the game changed
//    teleports a dynamic or static body and moves a kinematic one (with velocity, so it
//    pushes); `Joint2D`s created once both bodies exist, recreated when edited.
// 2. `physics.step(dt)`.
// 3. physics -> ECS: dynamic bodies write their x / y position and rotation about z into
//    `Transform` and their velocities into `RigidBody2D`, only when they changed.
// Interpolation: a body drawn between steps (`RigidBody2D.interpolation`, or the world's
// `interpolatesPoses`) gets a `Transform` between its last two poses by `time.alpha`, written
// by the "physics2d.interpolate" system in `.update`. "physics2d.restore" puts the exact
// `Transform` back before the next fixed step (first in `.fixedUpdate`, so game systems and
// the sync see exact values); a `Transform` the game changed meanwhile is kept and applied.
// The simulation never reads the interpolated poses.
// The sync walks components in the world's storage order and bodies in slot order, so it is
// as deterministic as the world itself.

extension World {
    /// Simulates `physics` from this world's `Collider2D`, `RigidBody2D` and `Joint2D`
    /// components: adds a `.fixedUpdate` system "physics2d" that syncs, steps by the fixed
    /// timestep and writes results back, and an `.update` system "physics2d.events" (first in
    /// its stage). "physics2d.restore" (first in `.fixedUpdate`) and "physics2d.interpolate"
    /// (`.update`, after the events) draw interpolated bodies between steps.
    /// `physics.events` then holds the events of the current frame's fixed steps; read them
    /// in `.update` / `.lateUpdate` systems or after `world.update`, or set `physics.onEvent`.
    public func addPhysics2D(_ physics: PhysicsWorld2D) {
        PhysicsWorld2D.registerComponents()
        addSystem("physics2d.restore", stage: .fixedUpdate, before: systemNames(in: .fixedUpdate).first) { _ in
            physics.restoreExactTransforms(in: self)
        }
        addSystem("physics2d", stage: .fixedUpdate) { world in
            if world.time.fixedStepsThisFrame == 1 { physics.clearEvents() }
            physics.syncFromWorld(world, dt: world.time.delta)
            physics.step(world.time.delta)
            physics.syncToWorld(world)
        }
        addSystem("physics2d.events", stage: .update, before: systemNames(in: .update).first) { world in
            // A frame without fixed steps has no events (don't report the last frame's twice).
            if world.time.fixedStepsThisFrame == 0 { physics.clearEvents() }
        }
        addSystem("physics2d.interpolate", stage: .update, after: "physics2d.events") { world in
            physics.applyInterpolation(in: world)
        }
    }

    /// The systems `addPhysics2D` adds.
    public static let physics2DSystemNames = ["physics2d.restore", "physics2d", "physics2d.events", "physics2d.interpolate"]

    /// Removes the systems added by `addPhysics2D` (the components stay).
    public func removePhysics2D() {
        for name in Self.physics2DSystemNames { removeSystem(named: name) }
    }
}

extension PhysicsWorld2D {
    /// The body made for `entity`'s `Collider2D`, if any.
    public func body(for entity: Entity) -> Body2DID? {
        guard let i = bodyForEntity[entity], bodies[i].isAlive, bodies[i].entity == entity else { return nil }
        return id(i)
    }

    /// The joint made for `entity`'s `Joint2D`, if any.
    public func joint(for entity: Entity) -> Joint2DID? {
        guard let i = jointForEntity[entity], joints[i].isAlive else { return nil }
        return Joint2DID(index: UInt32(i), generation: joints[i].generation)
    }

    /// Removes every body and joint (e.g. before rebuilding a scene).
    public func removeAll() {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive { removeBody(at: i) }
        clearEvents()
        accumulator = 0
    }

    /// The pose of an entity's `Transform`: x / y and the rotation about z.
    static func pose(of transform: Transform) -> Pose2D {
        let q = transform.rotation
        let angle = atan2f(2 * (q.w * q.imaginary.z + q.imaginary.x * q.imaginary.y),
                           1 - 2 * (q.imaginary.y * q.imaginary.y + q.imaginary.z * q.imaginary.z))
        return Pose2D(position: Vec2(transform.position.x, transform.position.y), angle: angle)
    }

    /// `base` (for its z and scale) placed at `pose`.
    static func transform(for pose: Pose2D, base: Transform) -> Transform {
        var transform = base
        transform.position = Vec3(pose.position.x, pose.position.y, base.position.z)
        transform.rotation = Quat(0, 0, sinf(pose.angle * 0.5), cosf(pose.angle * 0.5))
        return transform
    }

    /// ECS -> physics (step 1 above). `addPhysics2D` calls this; call it yourself for a custom loop.
    public func syncFromWorld(_ world: World, dt: Float) {
        var colliders: [(Entity, Collider2D)] = []
        world.query(Collider2D.self) { e, c in colliders.append((e, c)) }
        var planned: Set<Entity> = []
        for (e, _) in colliders { planned.insert(e) }

        for i in bodies.indices.dropFirst() where bodies[i].isAlive {
            guard let e = bodies[i].entity else { continue }
            if !world.isAlive(e) || !planned.contains(e) || bodyForEntity[e] != i { removeBody(at: i) }
        }

        for (e, collider) in colliders {
            let transform = world.get(Transform.self, for: e) ?? Transform()
            let rigidBody = world.get(RigidBody2D.self, for: e)
            let pose = Self.pose(of: transform)
            let motion = rigidBody?.motion ?? .static
            let offset = Pose2D(position: collider.offset, angle: collider.rotation)
            guard let i = bodyForEntity[e], bodies[i].isAlive, bodies[i].entity == e else {
                let rb = rigidBody ?? RigidBody2D(.static)
                let id = addBody(BodyDescriptor2D(
                    motion: motion, pose: pose, shape: collider.shape, shapeOffset: offset, material: collider.material,
                    isTrigger: collider.isTrigger, isOneWay: collider.isOneWay, layer: collider.layer, mask: collider.mask,
                    linearVelocity: rb.linearVelocity, angularVelocity: rb.angularVelocity, linearDamping: rb.linearDamping,
                    angularDamping: rb.angularDamping, gravityScale: rb.gravityScale, allowSleep: rb.allowSleep,
                    startsAsleep: rb.startsAsleep, fixedRotation: rb.fixedRotation, entity: e))
                let index = Int(id.index)
                bodyForEntity[e] = index
                bodies[index].sync = BodySync2D(transform: transform, rigidBody: rigidBody, collider: collider)
                continue
            }
            if collider != bodies[i].sync.collider {
                setShape(i, collider.shape, offset: offset, material: collider.material, isTrigger: collider.isTrigger,
                         isOneWay: collider.isOneWay, layer: collider.layer, mask: collider.mask)
                bodies[i].sync.collider = collider
            }
            if motion != bodies[i].motion { setMotion(at: i, motion) }
            if let rb = rigidBody, rb != bodies[i].sync.rigidBody {
                let old = bodies[i].sync.rigidBody
                bodies[i].linearDamping = rb.linearDamping
                bodies[i].angularDamping = rb.angularDamping
                bodies[i].gravityScale = rb.gravityScale
                bodies[i].allowSleep = rb.allowSleep
                if rb.fixedRotation != bodies[i].fixedRotation {
                    bodies[i].fixedRotation = rb.fixedRotation
                    updateMass(i)
                }
                if motion != .static {
                    if rb.linearVelocity != old?.linearVelocity { bodies[i].linearVelocity = rb.linearVelocity; wake(i) }
                    if rb.angularVelocity != old?.angularVelocity { bodies[i].angularVelocity = rb.angularVelocity; wake(i) }
                }
                bodies[i].sync.rigidBody = rb
            }
            if transform != bodies[i].sync.transform {
                if motion == .kinematic { moveKinematic(at: i, to: pose, dt: dt) } else { setPose(at: i, pose) }
                bodies[i].sync.transform = transform
            }
        }

        syncJoints(world)
    }

    private func syncJoints(_ world: World) {
        var components: [(Entity, Joint2D)] = []
        world.query(Joint2D.self) { e, j in components.append((e, j)) }
        for j in joints.indices where joints[j].isAlive {
            guard let e = joints[j].entity else { continue }
            if !world.isAlive(e) || world.get(Joint2D.self, for: e) != joints[j].source || jointForEntity[e] != j { removeJoint(at: j) }
        }
        for (e, component) in components where jointForEntity[e] == nil {
            guard let a = body(for: e) else { continue }
            var b: Body2DID?
            if let other = component.connectedBody {
                guard let found = body(for: other) else { continue }
                b = found
            }
            let poseA = bodies[Int(a.index)].pose
            let anchor = poseA.transform(component.anchor)
            var anchorB: Vec2?
            if let connected = component.connectedAnchor {
                anchorB = b.map { bodies[Int($0.index)].pose.transform(connected) } ?? connected
            }
            guard let joint = addJoint(Joint2DDescriptor(
                kind: component.kind, bodyA: a, bodyB: b, anchor: anchor, anchorB: anchorB,
                collideConnected: component.collideConnected, entity: e, enableLimit: component.enableLimit,
                lowerAngle: component.lowerAngle, upperAngle: component.upperAngle, enableMotor: component.enableMotor,
                motorSpeed: component.motorSpeed, maxMotorTorque: component.maxMotorTorque, length: component.length,
                hertz: component.hertz, dampingRatio: component.dampingRatio, minLength: component.minLength,
                maxLength: component.maxLength ?? .infinity)) else { continue }
            jointForEntity[e] = Int(joint.index)
            joints[Int(joint.index)].source = component
        }
    }

    /// Physics -> ECS (step 3 above).
    public func syncToWorld(_ world: World) {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive && bodies[i].motion == .dynamic {
            guard let e = bodies[i].entity, world.isAlive(e) else { continue }
            let body = bodies[i]
            if var rb = world.get(RigidBody2D.self, for: e),
               rb.linearVelocity != body.linearVelocity || rb.angularVelocity != body.angularVelocity {
                rb.linearVelocity = body.linearVelocity
                rb.angularVelocity = body.angularVelocity
                world.add(rb, to: e)
                bodies[i].sync.rigidBody = rb
            }
            guard let current = world.get(Transform.self, for: e) else { continue }
            let transform = Self.transform(for: body.pose, base: current)
            if transform != current { world.add(transform, to: e) }
            bodies[i].sync.transform = transform
        }
    }

    // MARK: - Interpolation

    /// Writes interpolated `Transform`s (by `world.time.alpha`) for the bodies that want them.
    /// `addPhysics2D` calls this in `.update`; call it yourself for a custom loop.
    public func applyInterpolation(in world: World) {
        let alpha = world.time.alpha
        for i in bodies.indices.dropFirst() where bodies[i].isAlive && bodies[i].motion != .static {
            guard let e = bodies[i].entity, world.isAlive(e), let base = bodies[i].sync.transform,
                  let current = world.get(Transform.self, for: e) else { continue }
            let mode = bodies[i].sync.rigidBody?.interpolation ?? .inherit
            guard mode == .on || (mode == .inherit && interpolatesPoses) else {
                if bodies[i].smoothed != nil { restoreExactTransform(i, in: world) }
                continue
            }
            // The game moved it since: that edit wins and is applied by the next sync.
            if current != base && current != bodies[i].smoothed {
                bodies[i].smoothed = nil
                continue
            }
            let shown = Self.transform(for: interpolated(i, alpha), base: base)
            if shown != current { world.add(shown, to: e) }
            bodies[i].smoothed = shown == base ? nil : shown
        }
    }

    /// Puts the exact simulated `Transform` back on every body drawn interpolated (done before
    /// each fixed step; call it before saving a scene or reading exact poses from `Transform`s).
    public func restoreExactTransforms(in world: World) {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive && bodies[i].smoothed != nil {
            restoreExactTransform(i, in: world)
        }
    }

    private func restoreExactTransform(_ i: Int, in world: World) {
        if let e = bodies[i].entity, world.isAlive(e), let base = bodies[i].sync.transform,
           world.get(Transform.self, for: e) == bodies[i].smoothed {
            world.add(base, to: e)
        }
        bodies[i].smoothed = nil
    }
}
