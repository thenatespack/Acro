// Drives a PhysicsWorld from a World's components. Each fixed step:
// 1. ECS -> physics: bodies for new `Collider`s (child colliders under a `RigidBody` entity
//    become parts of its compound shape), removed for despawned entities or removed
//    colliders; edited colliders and rigid bodies applied; a `Transform` the game changed
//    teleports a dynamic or static body and moves a kinematic one (with velocity, so it
//    pushes); `Joint`s created once both bodies exist, recreated when edited.
// 2. `physics.step(dt)`.
// 3. physics -> ECS: dynamic bodies write their pose into `Transform` (relative to the parent
//    for children) and their velocities into `RigidBody`, only when they changed.
// Interpolation: a body drawn between steps (`RigidBody.interpolation`, or the world's
// `interpolatesPoses`) gets a `Transform` between its last two poses by `time.alpha`, written
// by the "physics.interpolate" system in `.update`. "physics.restore" puts the exact
// `Transform` back before the next fixed step (first in `.fixedUpdate`, so game systems and
// the sync see exact values); a `Transform` the game changed meanwhile is kept and applied.
// The simulation never reads the interpolated poses.
// The sync walks components in the world's storage order and bodies in slot order, so it is
// as deterministic as the world itself.

extension World {
    /// Simulates `physics` from this world's `Collider`, `RigidBody` and `Joint` components:
    /// adds a `.fixedUpdate` system "physics" that syncs, steps by the fixed timestep and
    /// writes results back, and an `.update` system "physics.events" (first in its stage).
    /// "character" (just before it) moves `CharacterController`s. "physics.restore" (first in `.fixedUpdate`) and "physics.interpolate" (`.update`, after
    /// the events) draw interpolated bodies between steps.
    /// `physics.events` then holds the events of the current frame's fixed steps; read them
    /// in `.update` / `.lateUpdate` systems or after `world.update`, or set `physics.onEvent`.
    public func addPhysics(_ physics: PhysicsWorld) {
        PhysicsWorld.registerComponents()
        addSystem("physics.restore", stage: .fixedUpdate, before: systemNames(in: .fixedUpdate).first) { _ in
            physics.restoreExactTransforms(in: self)
        }
        addSystem("character", stage: .fixedUpdate) { world in
            physics.updateCharacters(in: world, dt: world.time.delta)
        }
        addSystem("physics", stage: .fixedUpdate) { world in
            if world.time.fixedStepsThisFrame == 1 { physics.clearEvents() }
            Profiler.scope("physics sync in") { physics.syncFromWorld(world, dt: world.time.delta) }
            physics.step(world.time.delta)
            Profiler.scope("physics sync out") { physics.syncToWorld(world) }
        }
        addSystem("physics.events", stage: .update, before: systemNames(in: .update).first) { world in
            // A frame without fixed steps has no events (don't report the last frame's twice).
            if world.time.fixedStepsThisFrame == 0 { physics.clearEvents() }
        }
        addSystem("physics.interpolate", stage: .update, after: "physics.events") { world in
            physics.applyInterpolation(in: world)
        }
    }

    /// The systems `addPhysics` adds.
    public static let physicsSystemNames = ["physics.restore", "character", "physics", "physics.events", "physics.interpolate"]

    /// Removes the systems added by `addPhysics` (the components stay).
    public func removePhysics() {
        for name in Self.physicsSystemNames { removeSystem(named: name) }
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
        // Which entities get a body: every collider that isn't a part of another body, and
        // the `RigidBody` entities that have only child colliders.
        var colliders: [(Entity, Collider)] = []
        world.query(Collider.self) { e, c in colliders.append((e, c)) }
        var members: [Entity: [(part: CompoundPart, collider: Collider)]] = [:]
        var compoundRoots: [Entity] = []
        var joined: Set<Entity> = []
        for (e, c) in colliders where !c.isTrigger && !world.has(RigidBody.self, for: e) {
            guard let root = compoundRoot(of: e, in: world) else { continue }
            joined.insert(e)
            if members[root] == nil { compoundRoots.append(root) }
            members[root, default: []].append((compoundPart(of: e, c, under: root, in: world), c))
        }
        var plan: [(Entity, Collider)] = []
        var planned: Set<Entity> = []
        for (e, c) in colliders where !joined.contains(e) {
            plan.append((e, effectiveCollider(c, members[e])))
            planned.insert(e)
        }
        for root in compoundRoots where !planned.contains(root) {
            plan.append((root, effectiveCollider(nil, members[root])))
            planned.insert(root)
        }

        for i in bodies.indices.dropFirst() where bodies[i].isAlive {
            guard let e = bodies[i].entity else { continue }
            if !world.isAlive(e) || !planned.contains(e) || bodyForEntity[e] != i { removeBody(at: i) }
        }

        for (e, collider) in plan {
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
            guard let current = world.get(Transform.self, for: e) else { continue }
            let transform = localTransform(for: body.pose, base: current, entity: e, in: world)
            if transform != current { world.add(transform, to: e) }
            bodies[i].sync.transform = transform
        }
    }

    /// `base` (for its scale) placed at the world pose `pose`, as the entity's local `Transform`.
    private func localTransform(for pose: Pose, base: Transform, entity e: Entity, in world: World) -> Transform {
        var transform = base
        if let parent = world.parent(of: e), world.has(Transform.self, for: parent) {
            let parentWorld = Transform(matrix: world.worldMatrix(of: parent))
            let p = parentWorld.rotation.conjugate * (pose.position - parentWorld.position)
            transform.position = p / parentWorld.scale
            transform.rotation = (parentWorld.rotation.conjugate * pose.rotation).normalized
        } else {
            transform.position = pose.position
            transform.rotation = pose.rotation
        }
        return transform
    }

    // MARK: - Interpolation

    /// Writes interpolated `Transform`s (by `world.time.alpha`) for the bodies that want them.
    /// `addPhysics` calls this in `.update`; call it yourself for a custom loop.
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
            let shown = localTransform(for: interpolated(i, alpha), base: base, entity: e, in: world)
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

    // MARK: - Compound colliders

    /// The nearest ancestor with a `RigidBody`, which the collider on `e` joins as a part.
    private func compoundRoot(of e: Entity, in world: World) -> Entity? {
        var current = world.parent(of: e)
        while let c = current {
            if world.has(RigidBody.self, for: c) { return c }
            current = world.parent(of: c)
        }
        return nil
    }

    /// The collider on `e` as a part of `root`'s body: placed by the `Transforms` between them
    /// (the chain below `root`, so it is exact and independent of where the body is) and the
    /// collider's own offset; `root`'s world scale is baked into the shapes later.
    private func compoundPart(of e: Entity, _ c: Collider, under root: Entity, in world: World) -> CompoundPart {
        var chain = Mat4.identity
        var current = e
        while current != root, let parent = world.parent(of: current) {
            chain = (world.get(Transform.self, for: current) ?? Transform()).matrix * chain
            current = parent
        }
        let relative = Transform(matrix: chain)
        let rootScale = worldPose(of: root, world.get(Transform.self, for: root) ?? Transform(), in: world).1
        return CompoundPart(c.shape, offset: relative.position * rootScale + relative.rotation * c.offset,
                            rotation: (relative.rotation * c.rotation).normalized, scale: relative.scale, density: c.density)
    }

    /// `own` (the body entity's collider, if any) with the child colliders `members` joined into
    /// one compound; `own` alone when there are none.
    private func effectiveCollider(_ own: Collider?, _ members: [(part: CompoundPart, collider: Collider)]?) -> Collider {
        guard let members, !members.isEmpty else { return own! }
        var parts: [CompoundPart] = []
        if let own { parts.append(CompoundPart(own.shape, offset: own.offset, rotation: own.rotation, density: own.density)) }
        parts += members.map(\.part)
        let base = own ?? members[0].collider
        return Collider(.compound(parts: parts), friction: base.friction, restitution: base.restitution, density: base.density,
                        isTrigger: own?.isTrigger ?? false, layer: base.layer, mask: base.mask)
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
