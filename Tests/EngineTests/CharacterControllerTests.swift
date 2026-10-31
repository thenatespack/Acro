import Foundation
import Testing
@testable import Engine

private let dt: Float = 1.0 / 60

/// A static box from `min` to `max`.
@MainActor @discardableResult
private func addBox(_ physics: PhysicsWorld, min lo: Vec3, max hi: Vec3, rotation: Quat = .identity) -> BodyID {
    physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: (lo + hi) * 0.5, rotation: rotation),
                                   shape: .box((hi - lo) * 0.5), material: ColliderMaterial(friction: 0.5)))
}

/// A world with a floor whose top is at y = 0.
@MainActor private func makeWorld() -> PhysicsWorld {
    let physics = PhysicsWorld()
    addBox(physics, min: Vec3(-50, -1, -50), max: Vec3(50, 0, 50))
    return physics
}

/// Walks the character for `steps` fixed steps with `velocity` (stepping the world too).
@MainActor
private func walk(_ physics: PhysicsWorld, _ c: inout CharacterController, _ position: inout Vec3, _ velocity: Vec3, steps: Int,
                  body: BodyID? = nil, each: ((Vec3, CharacterController) -> Void)? = nil) {
    for _ in 0..<steps {
        c.moveVelocity = velocity
        position = physics.moveCharacter(&c, from: position, dt: dt, body: body)
        physics.step(dt)
        each?(position, c)
    }
}

/// Settles a character dropped slightly above the floor.
@MainActor private func settle(_ physics: PhysicsWorld, _ c: inout CharacterController, at start: Vec3) -> Vec3 {
    var position = start
    walk(physics, &c, &position, .zero, steps: 30)
    return position
}

@MainActor @Test func characterStandsOnTheFloorWithASkin() {
    let physics = makeWorld()
    var c = CharacterController()
    let position = settle(physics, &c, at: Vec3(0, 0.5, 0))
    #expect(c.isGrounded && !c.isSliding)
    #expect(abs(position.y - c.skinWidth) < 0.004)
    #expect(abs(c.groundNormal.y - 1) < 1e-3)
}

@MainActor @Test func characterSlidesAlongAWall() {
    let physics = makeWorld()
    addBox(physics, min: Vec3(3, 0, -20), max: Vec3(4, 3, 20))
    var c = CharacterController()
    var position = settle(physics, &c, at: Vec3(0, 0.1, 0))
    // Into the wall at 45 degrees: it stops a skin short of it and keeps sliding along z.
    walk(physics, &c, &position, Vec3(3, 0, 3), steps: 90)
    #expect(abs(position.x - (3 - c.radius - c.skinWidth)) < 0.01)
    #expect(position.z > 3.5)
    #expect(c.isGrounded && position.y < 0.05)
    // A corner: two walls, it ends up in the crease without passing either.
    addBox(physics, min: Vec3(-20, 0, 6), max: Vec3(20, 3, 7))
    walk(physics, &c, &position, Vec3(3, 0, 3), steps: 90)
    #expect(position.x < 3 - c.radius + 0.01 && position.z < 6 - c.radius + 0.01)
}

@MainActor @Test func characterStepsUpStairsUpToTheStepHeight() {
    // A stair of 0.3 (under stepHeight 0.35) is climbed; one of 0.5 blocks.
    for (rise, climbs) in [(Float(0.3), true), (0.5, false)] {
        let physics = makeWorld()
        addBox(physics, min: Vec3(2, 0, -5), max: Vec3(10, rise, 5))
        var c = CharacterController()
        var position = settle(physics, &c, at: Vec3(0, 0.1, 0))
        walk(physics, &c, &position, Vec3(2, 0, 0), steps: 180)
        if climbs {
            #expect(position.x > 4 && abs(position.y - (rise + c.skinWidth)) < 0.01 && c.isGrounded)
        } else {
            #expect(position.x < 2 - c.radius + 0.01 && position.y < 0.05)
        }
    }
}

@MainActor @Test func characterClimbsAStaircaseAndStaysOnItGoingDown() {
    let physics = makeWorld()
    // Eight treads of 0.2 up, a landing, eight down.
    for k in 0..<8 {
        addBox(physics, min: Vec3(2 + Float(k) * 0.5, 0, -5), max: Vec3(2 + Float(k + 1) * 0.5 + 0.6, 0.2 * Float(k + 1), 5))
    }
    addBox(physics, min: Vec3(6, 0, -5), max: Vec3(8, 1.6, 5))
    for k in 0..<8 {
        addBox(physics, min: Vec3(8 + Float(k) * 0.5, 0, -5), max: Vec3(8 + Float(k + 1) * 0.5, 1.6 - 0.2 * Float(k + 1) + 0.0001, 5))
    }
    var c = CharacterController()
    var position = settle(physics, &c, at: Vec3(0, 0.1, 0))
    var peak: Float = 0
    var airborneOnTheWayDown = 0
    walk(physics, &c, &position, Vec3(2.5, 0, 0), steps: 300) { p, ch in
        peak = max(peak, p.y)
        if p.x > 8.2 && p.x < 11.5 && !ch.isGrounded { airborneOnTheWayDown += 1 }
    }
    #expect(peak > 1.5)
    #expect(airborneOnTheWayDown == 0)
    #expect(position.y < 0.3 && c.isGrounded)
}

@MainActor @Test func characterRespectsTheSlopeLimit() {
    // A slab rising toward +x at `angle`, its lower end flush with the floor at x = 2.
    func ramp(_ physics: PhysicsWorld, angle: Float) {
        let rotation = Quat(angle: angle, axis: Vec3(0, 0, 1))
        let half = Vec3(5, 0.25, 5)
        physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(2, 0, 0) - rotation * Vec3(-half.x, half.y, 0), rotation: rotation),
                                       shape: .box(half)))
    }
    // 30 degrees (limit 45): walked up.
    let easy = makeWorld()
    ramp(easy, angle: 30 * .pi / 180)
    var c = CharacterController()
    var position = settle(easy, &c, at: Vec3(0, 0.1, 0))
    walk(easy, &c, &position, Vec3(2, 0, 0), steps: 150)
    #expect(position.y > 1.2 && c.isGrounded)
    #expect(abs(c.groundNormal.y - cosf(30 * .pi / 180)) < 0.02)

    // 60 degrees: it can't get up, whatever it does at the foot of it.
    let steep = makeWorld()
    ramp(steep, angle: 60 * .pi / 180)
    var d = CharacterController()
    position = settle(steep, &d, at: Vec3(0, 0.1, 0))
    walk(steep, &d, &position, Vec3(2, 0, 0), steps: 150)
    #expect(position.y < 0.4)

    // Put on the steep slope, it slides down it.
    var e = CharacterController()
    position = Vec3(4, 3.5, 0)
    var slid = false
    walk(steep, &e, &position, .zero, steps: 90) { _, ch in slid = slid || ch.isSliding }
    #expect(slid && position.y < 2.5 && position.x < 4)

    // A limit of 70 degrees makes the same slope walkable.
    var f = CharacterController(maxSlopeAngle: 70)
    position = settle(steep, &f, at: Vec3(0, 0.1, 0))
    walk(steep, &f, &position, Vec3(1.5, 0, 0), steps: 180)
    #expect(position.y > 1.5)
}

@MainActor @Test func characterJumpsAndLands() {
    let physics = makeWorld()
    var c = CharacterController()
    var position = settle(physics, &c, at: Vec3(0, 0.1, 0))
    c.jump = true
    var apex: Float = 0
    var airborne = 0
    walk(physics, &c, &position, .zero, steps: 120) { p, ch in
        apex = max(apex, p.y)
        if !ch.isGrounded { airborne += 1 }
    }
    // v^2 / 2g = 1.54 m, about 1.12 s in the air.
    #expect(abs(apex - 5.5 * 5.5 / (2 * 9.81)) < 0.1)
    #expect(airborne > 55 && airborne < 75)
    #expect(c.isGrounded && !c.jump && abs(position.y - c.skinWidth) < 0.004)
}

@MainActor @Test func characterIsCarriedByAMovingPlatform() {
    let physics = makeWorld()
    let platform = physics.addBody(BodyDescriptor(motion: .kinematic, pose: Pose(position: Vec3(0, 0.25, 0)),
                                                  shape: .box(Vec3(2, 0.25, 2)), allowSleep: false))
    var c = CharacterController()
    var position = Vec3(0, 0.5, 0)
    var platformX: Float = 0
    for step in 0..<180 {
        // 1 m/s to +x, then back.
        platformX += (step < 90 ? 1 : -1) * dt
        physics.moveKinematic(platform, to: Pose(position: Vec3(platformX, 0.25, 0)), dt: dt)
        c.moveVelocity = .zero
        position = physics.moveCharacter(&c, from: position, dt: dt)
        physics.step(dt)
        if step == 80 { #expect(abs(position.x - platformX) < 0.1 && c.isGrounded && c.groundVelocity.x > 0.9) }
    }
    #expect(abs(position.x) < 0.1 && c.isGrounded && abs(position.y - (0.5 + c.skinWidth)) < 0.01)

    // Rising platforms lift it, and walking off one keeps its velocity while airborne.
    let lift = physics.addBody(BodyDescriptor(motion: .kinematic, pose: Pose(position: Vec3(10, 0.25, 0)),
                                              shape: .box(Vec3(2, 0.25, 2)), allowSleep: false))
    var d = CharacterController()
    position = Vec3(10, 0.5, 0)
    var y: Float = 0.25
    for _ in 0..<60 {
        y += dt
        physics.moveKinematic(lift, to: Pose(position: Vec3(10, y, 0)), dt: dt)
        position = physics.moveCharacter(&d, from: position, dt: dt)
        physics.step(dt)
    }
    #expect(abs(position.y - (y + 0.25 + d.skinWidth)) < 0.02 && d.isGrounded)
}

@MainActor @Test func characterPushesDynamicBodies() {
    func run(pushForce: Float) -> (crate: Float, character: Float) {
        let physics = makeWorld()
        let crate = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(2, 0.5, 0)), shape: .box(Vec3(0.5, 0.5, 0.5)),
                                                   material: ColliderMaterial(friction: 0.3, density: 40)))
        var c = CharacterController(pushForce: pushForce)
        var position = settle(physics, &c, at: Vec3(0, 0.1, 0))
        walk(physics, &c, &position, Vec3(2, 0, 0), steps: 180)
        return (physics.pose(of: crate)!.position.x - 2, position.x)
    }
    let pushing = run(pushForce: 400)
    #expect(pushing.crate > 1 && pushing.character > 2)
    // Without the force it is just an obstacle.
    let blocked = run(pushForce: 0)
    #expect(abs(blocked.crate) < 0.05 && blocked.character < 1.3)
}

@MainActor @Test func characterMovesItsKinematicBodyAndFiresTriggers() {
    let physics = makeWorld()
    var c = CharacterController()
    let body = physics.addBody(BodyDescriptor(motion: .kinematic, pose: Pose(position: Vec3(0, 0, 0)), shape: c.colliderShape,
                                              shapeOffset: Pose(position: c.colliderOffset), allowSleep: false))
    let zone = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(3, 1, 0)), shape: .box(Vec3(0.5, 1, 2)),
                                              isTrigger: true))
    var log: [PhysicsEvent] = []
    physics.onEvent = { log.append($0) }
    var position = Vec3.zero
    walk(physics, &c, &position, Vec3(2, 0, 0), steps: 90, body: body)
    walk(physics, &c, &position, Vec3(-2, 0, 0), steps: 120, body: body)
    let kinds = log.filter { $0.bodyA == zone && $0.bodyB == body }.map(\.kind)
    #expect(kinds.first == .triggerEntered && kinds.last == .triggerExited && kinds.contains(.triggerStayed))
    #expect(length(physics.pose(of: body)!.position - position) < 1e-4)
}

@MainActor private func scenario() -> [Vec3] {
    let physics = makeWorld()
    addBox(physics, min: Vec3(2, 0, -5), max: Vec3(10, 0.3, 5))
    let crate = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(5, 1, 0)), shape: .box(Vec3(0.4, 0.4, 0.4))))
    var c = CharacterController()
    var position = Vec3(0, 0.5, 0)
    var trace: [Vec3] = []
    for step in 0..<240 {
        c.moveVelocity = Vec3(2, 0, sinf(Float(step) * 0.05))
        c.jump = step % 70 == 69
        position = physics.moveCharacter(&c, from: position, dt: dt)
        physics.step(dt)
        trace.append(position)
        trace.append(physics.pose(of: crate)!.position)
    }
    return trace
}

@MainActor @Test func characterMovementIsDeterministic() {
    let a = scenario(), b = scenario()
    #expect(a == b)
    #expect(a.last!.x > 3)
}

// MARK: - ECS

@MainActor @Test func characterComponentMovesTheEntityAndFiresTriggers() throws {
    let world = World()
    let physics = PhysicsWorld()
    world.addPhysics(physics)
    _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)), Collider(.box(Vec3(0.5, 0.5, 0.5))))
    let zone = world.spawn(Transform(position: Vec3(3, 1, 0)), Collider(.box(Vec3(0.5, 1, 2)), isTrigger: true))
    let controller = CharacterController()
    let hero = world.spawn(Transform(position: Vec3(0, 0.3, 0)), controller,
                           Collider(controller.colliderShape, offset: controller.colliderOffset), RigidBody(.kinematic, interpolation: .on))
    var entered: [Entity] = []
    physics.onEvent = { if $0.kind == .triggerEntered && $0.entityA == zone { entered.append($0.entityB!) } }
    for step in 0..<150 {
        world.modify(CharacterController.self, for: hero) { $0.moveVelocity = step > 20 ? Vec3(2, 0, 0) : .zero }
        world.update(dt: Double(dt))
    }
    #expect(entered == [hero])
    let t = world.get(Transform.self, for: hero)!
    #expect(t.position.x > 3 && abs(t.position.y - 0.02) < 0.02)
    #expect(world.get(CharacterController.self, for: hero)!.isGrounded)
    let body = physics.body(for: hero)!
    #expect(abs(physics.pose(of: body)!.position.x - t.position.x) <= 2 * dt + 1e-3)

    // Round trip: the component serializes (its ground body isn't saved).
    physics.restoreExactTransforms(in: world)
    let data = try world.save()
    let copy = World()
    _ = try copy.load(data)
    var loaded: [CharacterController] = []
    copy.query(CharacterController.self) { _, c in loaded.append(c) }
    #expect(loaded.count == 1 && loaded[0].radius == 0.3 && loaded[0].groundBody == nil && loaded[0].isGrounded)
}
