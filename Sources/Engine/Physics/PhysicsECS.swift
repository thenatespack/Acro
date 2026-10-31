// Drives a PhysicsWorld from a World's components. Each fixed step:
// 1. ECS -> physics: bodies for new `Collider`s, removed for despawned entities or removed
//    colliders; edited colliders and rigid bodies applied; a `Transform` the game changed
//    teleports a dynamic or static body and moves a kinematic one (with velocity, so it
//    pushes); `Joint`s created once both bodies exist, recreated when edited.
// 2. `physics.step(dt)`.
// 3. physics -> ECS: dynamic bodies write their pose into `Transform` (relative to the parent
//    for children) and their velocities into `RigidBody`, only when they changed.
// The sync walks components in the world's storage order and bodies in slot order, so it is
// as deterministic as the world itself.

extension World {
    /// Simulates `physics` from this world's `Collider`, `RigidBody` and `Joint` components:
    /// adds a `.fixedUpdate` system "physics" that syncs, steps by the fixed timestep and
    /// writes results back, and an `.update` system "physics.events" (first in its stage).
    /// `physics.events` then holds the events of the current frame's fixed steps; read them
    /// in `.update` / `.lateUpdate` systems or after `world.update`, or set `physics.onEvent`.
    public func addPhysics(_ physics: PhysicsWorld) {
        PhysicsWorld.registerComponents()
        addSystem("physics", stage: .fixedUpdate) { world in
            if world.time.fixedStepsThisFrame == 1 { physics.clearEvents() }
            physics.syncFromWorld(world, dt: world.time.delta)
            physics.step(world.time.delta)
            physics.syncToWorld(world)
        }
        addSystem("physics.events", stage: .update, before: systemNames(in: .update).first) { world in
            // A frame without fixed steps has no events (don't report the last frame's twice).
            if world.time.fixedStepsThisFrame == 0 { physics.clearEvents() }
        }
    }
}

extension PhysicsWorld {
    /// The body made for `entity`'s `Collider`, if any.
    public func body(for entity: Entity) -> BodyID? {
        guard let i = bodyForEntity[entity], bodies[i].isAlive, bodies[i].entity == entity else { return nil }
        return id(i)
    }

    /// The joint made for `entity`'s `Joint`, if any.
    public func joint(for entity: Entity) -> JointID? {
        guard let i = jointForEntity[entity], joints[i].isAlive else { return nil }
        return JointID(index: UInt32(i), generation: joints[i].generation)
    }

    /// Removes every body and joint (e.g. before rebuilding a scene).
    public func removeAll() {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive { removeBody(at: i) }
        clearEvents()
        accumulator = 0
    }

    /// ECS -> physics (step 1 above). `addPhysics` calls this; call it yourself for a custom loop.
    public func syncFromWorld(_ world: World, dt: Float) {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive {
            guard let e = bodies[i].entity else { continue }
            if !world.isAlive(e) || !world.has(Collider.self, for: e) || bodyForEntity[e] != i { removeBody(at: i) }
        }

        var colliders: [(Entity, Collider)] = []
        world.query(Collider.self) { e, c in colliders.append((e, c)) }
        for (e, collider) in colliders {
            let transform = world.get(Transform.self, for: e) ?? Transform()
            let rigidBody = world.get(RigidBody.self, for: e)
            let (pose, scale) = worldPose(of: e, transform, in: world)
            let motion = rigidBody?.motion ?? .static
            guard let i = bodyForEntity[e], bodies[i].isAlive, bodies[i].entity == e else {
                let rb = rigidBody ?? RigidBody(.static)
                let id = addBody(BodyDescriptor(
                    motion: motion, pose: pose, shape: collider.shape,
                    shapeOffset: Pose(position: collider.offset, rotation: collider.rotation), scale: scale,
                    material: collider.material, isTrigger: collider.isTrigger, layer: collider.layer, mask: collider.mask,
                    linearVelocity: rb.linearVelocity, angularVelocity: rb.angularVelocity, linearDamping: rb.linearDamping,
                    angularDamping: rb.angularDamping, gravityScale: rb.gravityScale, allowSleep: rb.allowSleep,
                    startsAsleep: rb.startsAsleep, entity: e))
                let index = Int(id.index)
                bodyForEntity[e] = index
                bodies[index].sync = BodySync(transform: transform, rigidBody: rigidBody, collider: collider, scale: scale)
                continue
            }
            if collider != bodies[i].sync.collider || scale != bodies[i].sync.scale {
                setShape(i, collider.shape, offset: Pose(position: collider.offset, rotation: collider.rotation), scale: scale,
                         material: collider.material, isTrigger: collider.isTrigger, layer: collider.layer, mask: collider.mask)
                bodies[i].sync.collider = collider
                bodies[i].sync.scale = scale
            }
            if motion != bodies[i].motion { setMotion(id(i), motion) }
            if let rb = rigidBody, rb != bodies[i].sync.rigidBody {
                let old = bodies[i].sync.rigidBody
                bodies[i].linearDamping = rb.linearDamping
                bodies[i].angularDamping = rb.angularDamping
                bodies[i].gravityScale = rb.gravityScale
                bodies[i].allowSleep = rb.allowSleep
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
        var components: [(Entity, Joint)] = []
        world.query(Joint.self) { e, j in components.append((e, j)) }
        for j in joints.indices where joints[j].isAlive {
            guard let e = joints[j].entity else { continue }
            if !world.isAlive(e) || world.get(Joint.self, for: e) != joints[j].source || jointForEntity[e] != j { removeJoint(at: j) }
        }
        for (e, component) in components where jointForEntity[e] == nil {
            guard let a = body(for: e) else { continue }
            var b: BodyID?
            if let other = component.connectedBody {
                guard let found = body(for: other) else { continue }
                b = found
            }
            let poseA = bodies[Int(a.index)].pose
            let anchor = poseA.transform(component.anchor)
            var anchorB: Vec3?
            if let connected = component.connectedAnchor {
                anchorB = b.map { bodies[Int($0.index)].pose.transform(connected) } ?? connected
            }
            guard let joint = addJoint(JointDescriptor(kind: component.kind, bodyA: a, bodyB: b, anchor: anchor, anchorB: anchorB,
                                                       axis: poseA.rotation * component.axis,
                                                       collideConnected: component.collideConnected, entity: e)) else { continue }
            jointForEntity[e] = Int(joint.index)
            joints[Int(joint.index)].source = component
        }
    }

    /// Physics -> ECS (step 3 above).
    public func syncToWorld(_ world: World) {
        for i in bodies.indices.dropFirst() where bodies[i].isAlive && bodies[i].motion == .dynamic {
            guard let e = bodies[i].entity, world.isAlive(e) else { continue }
            let body = bodies[i]
            if var rb = world.get(RigidBody.self, for: e),
               rb.linearVelocity != body.linearVelocity || rb.angularVelocity != body.angularVelocity {
                rb.linearVelocity = body.linearVelocity
                rb.angularVelocity = body.angularVelocity
                world.add(rb, to: e)
                bodies[i].sync.rigidBody = rb
            }
            guard var transform = world.get(Transform.self, for: e) else { continue }
            if let parent = world.parent(of: e), world.has(Transform.self, for: parent) {
                let parentWorld = Transform(matrix: world.worldMatrix(of: parent))
                let p = parentWorld.rotation.conjugate * (body.pose.position - parentWorld.position)
                transform.position = p / parentWorld.scale
                transform.rotation = (parentWorld.rotation.conjugate * body.pose.rotation).normalized
            } else {
                transform.position = body.pose.position
                transform.rotation = body.pose.rotation
            }
            if transform != world.get(Transform.self, for: e) { world.add(transform, to: e) }
            bodies[i].sync.transform = transform
        }
    }

    /// The entity's world position and rotation, and its world scale.
    private func worldPose(of e: Entity, _ transform: Transform, in world: World) -> (Pose, Vec3) {
        if let parent = world.parent(of: e), world.has(Transform.self, for: parent) {
            let t = Transform(matrix: world.worldMatrix(of: e))
            return (Pose(position: t.position, rotation: t.rotation), t.scale)
        }
        return (Pose(position: transform.position, rotation: transform.rotation.normalized), transform.scale)
    }
}
