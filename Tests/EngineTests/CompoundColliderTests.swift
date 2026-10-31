import Foundation
import Testing
@testable import Engine

private func approx(_ a: Float, _ b: Float, _ eps: Float = 1e-3) -> Bool { abs(a - b) <= eps * max(1, abs(b)) }
private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-3) -> Bool { length(a - b) <= eps }

private let dt: Float = 1.0 / 60

// MARK: - Mass and shape

@Test func compoundOfTwoBoxesHasTheMassPropertiesOfOneBox() {
    let one = Shape(.box(Vec3(1, 0.5, 0.5))).massProperties(density: 500)
    let two = Shape(.compound(parts: [
        CompoundPart(.box(Vec3(0.5, 0.5, 0.5)), offset: Vec3(-0.5, 0, 0)),
        CompoundPart(.box(Vec3(0.5, 0.5, 0.5)), offset: Vec3(0.5, 0, 0)),
    ])).massProperties(density: 500)
    #expect(approx(two.mass, one.mass) && approx(two.center, one.center))
    for (a, b) in [(two.inertia.c0, one.inertia.c0), (two.inertia.c1, one.inertia.c1), (two.inertia.c2, one.inertia.c2)] {
        #expect(approx(a, b, 2e-3 * length(one.inertia.c0)))
    }
}

@Test func compoundCombinesCenterAndInertiaWithTheParallelAxisTerm() {
    // A heavy and a light sphere 2 m apart: the center sits near the heavy one.
    let r: Float = 0.5
    let shape = Shape(.compound(parts: [
        CompoundPart(.sphere(radius: r), offset: Vec3(-1, 0, 0), density: 3000),
        CompoundPart(.sphere(radius: r), offset: Vec3(1, 0, 0), density: 1000),
    ]))
    let m1 = 3000 * 4 / 3 * Float.pi * r * r * r, m2 = m1 / 3
    let props = shape.massProperties(density: 1)
    #expect(approx(props.mass, m1 + m2))
    let cx = (-m1 + m2) / (m1 + m2)
    #expect(approx(props.center, Vec3(cx, 0, 0)))
    // About y: each sphere's own 2/5 m r^2 plus m d^2.
    let iy = 0.4 * m1 * r * r + m1 * (cx + 1) * (cx + 1) + 0.4 * m2 * r * r + m2 * (1 - cx) * (1 - cx)
    #expect(approx(props.inertia.c1.y, iy))
    // Along x (the axis through both): only the spheres' own.
    #expect(approx(props.inertia.c0.x, 0.4 * (m1 + m2) * r * r))
}

@Test func compoundBoundsRotatedPartsAndRoundTrip() throws {
    let shape = Shape(.compound(parts: [
        CompoundPart(.box(Vec3(0.5, 0.1, 0.5)), offset: Vec3(0, 1, 0)),
        CompoundPart(.capsule(radius: 0.1, halfHeight: 0.5), offset: Vec3(0.4, 0.4, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 0, 1))),
        // A nested compound is flattened, a mesh is left out.
        CompoundPart(.compound(parts: [CompoundPart(.sphere(radius: 0.2), offset: Vec3(0, 0, 1))]), offset: Vec3(0, -1, 0)),
        CompoundPart(.triangleMesh(vertices: [Vec3(0, 0, 0), Vec3(9, 0, 0), Vec3(0, 0, 9)], indices: [0, 2, 1])),
    ]))
    guard case .compound(let parts) = shape.kind else {
        Issue.record("not a compound")
        return
    }
    #expect(parts.count == 3)
    let box = shape.bounds(at: Pose(position: Vec3(0, 5, 0)))
    #expect(approx(box.min, Vec3(-0.5, 5 - 1.2, -0.5)) && approx(box.max, Vec3(1, 5 + 1.1, 1.2)))
    let compound = ColliderShape.compound(parts: [CompoundPart(.box(Vec3(0.5, 0.5, 0.5)), offset: Vec3(0, 1, 0), density: 200)])
    let collider = Collider(compound, friction: 0.3)
    #expect(try JSONDecoder().decode(Collider.self, from: JSONEncoder().encode(collider)) == collider)
}

// MARK: - Physics

/// A table: a top and four legs, as one compound on a body at its middle.
@MainActor private func addTable(_ physics: PhysicsWorld, at p: Vec3, rotation: Quat = .identity) -> BodyID {
    var parts = [CompoundPart(.box(Vec3(0.6, 0.05, 0.4)), offset: Vec3(0, 0.375, 0))]
    for (x, z) in [(-0.5, -0.3), (0.5, -0.3), (-0.5, 0.3), (0.5, 0.3)] as [(Float, Float)] {
        parts.append(CompoundPart(.box(Vec3(0.04, 0.35, 0.04)), offset: Vec3(x, -0.05, z)))
    }
    return physics.addBody(BodyDescriptor(pose: Pose(position: p, rotation: rotation), shape: .compound(parts: parts),
                                          material: ColliderMaterial(friction: 0.6, density: 300)))
}

@MainActor @Test func compoundTableFallsAndRestsOnItsLegs() {
    let physics = PhysicsWorld()
    physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(20, 0.5, 20))))
    let table = addTable(physics, at: Vec3(0, 1.5, 0), rotation: Quat(angle: 0.1, axis: Vec3(0, 0, 1)))
    for _ in 0..<240 { physics.step(dt) }
    let pose = physics.pose(of: table)!
    // The legs' feet are at -0.4 from the body origin: it rests with the origin 0.4 up, level.
    #expect(abs(pose.position.y - 0.4) < 0.02)
    #expect(abs((pose.rotation * Vec3(0, 1, 0)).y - 1) < 1e-3)
    #expect(!physics.isAwake(table))
    // Mass: the top and four legs at 300 kg/m^3.
    let expected: Float = 300 * (8 * 0.6 * 0.05 * 0.4 + 4 * 8 * 0.04 * 0.35 * 0.04)
    #expect(approx(physics.mass(of: table), expected))
}

@MainActor @Test func compoundSpinsAboutItsCombinedCenter() {
    // A heavy block on a light plank: an impulse at the plank's end spins the body about the
    // combined center of mass (which is nowhere near the body origin), not about the origin.
    let physics = PhysicsWorld()
    physics.gravity = .zero
    let body = physics.addBody(BodyDescriptor(shape: .compound(parts: [
        CompoundPart(.box(Vec3(1, 0.1, 0.1)), density: 100),
        CompoundPart(.box(Vec3(0.2, 0.2, 0.2)), offset: Vec3(0.8, 0, 0), density: 4000),
    ]), linearDamping: 0, angularDamping: 0))
    let center = physics.centerOfMass(of: body)!
    #expect(center.x > 0.5 && center.x < 0.8)
    physics.applyImpulse(body, Vec3(0, 1, 0), at: Vec3(-1, 0, 0))
    let mass = physics.mass(of: body)
    #expect(approx(physics.linearVelocity(of: body).y, 1 / mass))
    // The point of the body at the origin moves with v + w x r (r = origin - center): the
    // origin is on the far side of the center from the heavy block, so it swings with the impulse.
    let v = physics.linearVelocity(of: body), w = physics.angularVelocity(of: body)
    let originVelocity = v + cross(w, Vec3(0, 0, 0) - center)
    #expect(w.z < 0 && originVelocity.y > v.y)
}

@MainActor @Test func queriesSeeEveryPartOfACompound() {
    let physics = PhysicsWorld()
    let table = addTable(physics, at: Vec3(0, 2, 0))
    physics.setMotion(table, .static)
    // A ray down through a leg and through the gap between legs.
    let leg = physics.raycast(Ray(origin: Vec3(0.5, 5, 0.3), direction: Vec3(0, -1, 0)))
    #expect(leg?.body == table && approx(leg!.point.y, 2 + 0.375 + 0.05) && approx(leg!.normal, Vec3(0, 1, 0)))
    // From the side below the top, between the legs: no hit; at a leg: a hit on its face.
    #expect(physics.raycast(Ray(origin: Vec3(-3, 1.8, 0), direction: Vec3(1, 0, 0))) == nil)
    let side = physics.raycast(Ray(origin: Vec3(-3, 1.8, 0.3), direction: Vec3(1, 0, 0)))
    #expect(side?.body == table && approx(side!.point.x, -0.54) && approx(side!.normal, Vec3(-1, 0, 0)))
    // Shape casts hit a leg or the top; overlaps find it only where a part is.
    let cast = physics.sphereCast(center: Vec3(0.5, 4, -0.3), radius: 0.1, direction: Vec3(0, -1, 0), maxDistance: 5)
    #expect(cast?.body == table && approx(cast!.distance, 4 - 2.425 - 0.1, 2e-3))
    #expect(physics.overlapSphere(center: Vec3(0, 1.7, 0), radius: 0.2).isEmpty)
    #expect(physics.overlapSphere(center: Vec3(0.5, 1.7, 0.3), radius: 0.2) == [table])
    #expect(physics.overlapBounds(AABB(min: Vec3(-0.1, 1.5, -0.1), max: Vec3(0.1, 1.6, 0.1))) == [table])
}

@MainActor @Test func debugDrawOutlinesEveryPart() {
    let physics = PhysicsWorld()
    _ = addTable(physics, at: Vec3(0, 2, 0))
    let draw = DebugDraw()
    physics.drawDebug(into: draw, options: .colliders)
    #expect(draw.segmentCount == 5 * 12)
}

// MARK: - ECS

@MainActor @Test func childCollidersJoinTheirRigidBodyAsACompound() throws {
    let world = World()
    let physics = PhysicsWorld()
    world.addPhysics(physics)
    _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)), Collider(.box(Vec3(0.5, 0.5, 0.5))))
    // A table entity with no collider of its own: a top and legs as children, scaled by 1.5.
    let table = world.spawn(Transform(position: Vec3(0, 1.2, 0), scale: Vec3(repeating: 1.5)), RigidBody(), Name("Table"))
    let top = world.spawn(Transform(position: Vec3(0, 0.375, 0)), Collider(.box(Vec3(0.6, 0.05, 0.4)), density: 300))
    _ = world.setParent(top, to: table)
    for (x, z) in [(-0.5, -0.3), (0.5, -0.3), (-0.5, 0.3), (0.5, 0.3)] as [(Float, Float)] {
        let leg = world.spawn(Transform(position: Vec3(x, -0.05, z)), Collider(.box(Vec3(0.04, 0.35, 0.04)), density: 300))
        _ = world.setParent(leg, to: table)
    }
    for _ in 0..<240 { world.update(dt: Double(dt)) }
    #expect(physics.bodyCount == 2 && physics.body(for: top) == nil)
    let body = physics.body(for: table)!
    let t = world.get(Transform.self, for: table)!
    // Legs' feet 0.4 below the origin, times the scale.
    #expect(abs(t.position.y - 0.6) < 0.03 && t.scale == Vec3(repeating: 1.5))
    #expect(approx(physics.mass(of: body), 300 * 1.5 * 1.5 * 1.5 * (8 * 0.6 * 0.05 * 0.4 + 4 * 8 * 0.04 * 0.35 * 0.04)))
    // The children follow the body through the hierarchy.
    world.propagateTransforms()
    let topWorld = Transform(matrix: world.worldMatrix(of: top)).position
    #expect(approx(topWorld, t.position + Vec3(0, 0.375 * 1.5, 0), 1e-3))

    // Removing a part's collider rebuilds the body's shape; adding a child makes it a part too.
    world.remove(Collider.self, from: top)
    world.update(dt: Double(dt))
    #expect(physics.mass(of: body) < 300 * 1.5 * 1.5 * 1.5 * 8 * 4 * 0.04 * 0.35 * 0.04 * 1.01)
    // Saved scenes keep the hierarchy; the copy builds the same body.
    let copy = World()
    PhysicsWorld.registerComponents()
    _ = try copy.load(try world.save())
    let copyPhysics = PhysicsWorld()
    copy.addPhysics(copyPhysics)
    copy.update(dt: Double(dt))
    #expect(copyPhysics.bodyCount == 2)
}

// MARK: - Interpolation

@MainActor private func fallingBall(interpolation: PoseInterpolation, world options: Bool = false) -> (World, PhysicsWorld, Entity) {
    let world = World()
    let physics = PhysicsWorld()
    physics.interpolatesPoses = options
    world.addPhysics(physics)
    _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)), Collider(.box(Vec3(0.5, 0.5, 0.5))))
    let ball = world.spawn(Transform(position: Vec3(0, 10, 0)), Collider(.sphere(radius: 0.25), restitution: 0.3),
                           RigidBody(interpolation: interpolation))
    return (world, physics, ball)
}

@MainActor @Test func interpolationSmoothsTheDisplayedTransformBetweenSteps() {
    let (world, physics, ball) = fallingBall(interpolation: .on)
    // Frames of 1/45 s against steps of 1/60 s: 0 or 1 steps per frame, alpha in between.
    var shown: [Float] = []
    var exact: [Float] = []
    for _ in 0..<40 {
        world.update(dt: 1.0 / 45)
        shown.append(world.get(Transform.self, for: ball)!.position.y)
        exact.append(physics.pose(of: physics.body(for: ball)!)!.position.y)
    }
    // Falling: the displayed height trails the exact one by alpha of the last step, so it is
    // strictly between the last two exact heights and never ahead of the exact one.
    var between = 0
    for k in 1..<shown.count where shown[k] != exact[k] {
        #expect(shown[k] > exact[k] && shown[k] <= exact[k - 1] + 1e-5 || shown[k] >= exact[k])
        between += 1
    }
    #expect(between > 20)
    // Smooth: while it falls freely the displayed height drops a bit more every frame, never
    // the 0 / 2 steps of the raw simulation.
    let deltas = Array(zip(shown, shown.dropFirst()).map { $0 - $1 }.dropFirst(5).prefix(15))
    #expect(deltas.allSatisfy { $0 > 0 })
    #expect(zip(deltas, deltas.dropFirst()).allSatisfy { $1 / $0 > 0.9 && $1 / $0 < 1.3 })
}

@MainActor @Test func interpolationDoesNotChangeTheSimulation() {
    func run(_ interpolation: PoseInterpolation, worldOption: Bool) -> [Pose] {
        let (world, physics, ball) = fallingBall(interpolation: interpolation, world: worldOption)
        let crate = world.spawn(Transform(position: Vec3(0.1, 12, 0)), Collider(.box(Vec3(0.5, 0.5, 0.5))), RigidBody(interpolation: interpolation))
        var poses: [Pose] = []
        for frame in 0..<200 {
            world.update(dt: frame % 3 == 0 ? 1.0 / 45 : 1.0 / 75)
            poses.append(physics.pose(of: physics.body(for: ball)!)!)
            poses.append(physics.pose(of: physics.body(for: crate)!)!)
        }
        return poses
    }
    let off = run(.off, worldOption: false)
    #expect(run(.on, worldOption: false) == off)
    #expect(run(.inherit, worldOption: true) == off)
    #expect(run(.off, worldOption: true) == off)
}

@MainActor @Test func interpolationFollowsTheWorldOptionAndYieldsToGameEdits() {
    // Inherit: off by default, on with the world option.
    for option in [false, true] {
        let (world, physics, ball) = fallingBall(interpolation: .inherit, world: option)
        var differs = 0
        for _ in 0..<30 {
            world.update(dt: 1.0 / 45)
            if world.get(Transform.self, for: ball)!.position != physics.pose(of: physics.body(for: ball)!)!.position { differs += 1 }
        }
        #expect(option ? differs > 10 : differs == 0)
    }
    // A teleport by game code wins and the interpolation restarts from there.
    let (world, physics, ball) = fallingBall(interpolation: .on)
    for _ in 0..<10 { world.update(dt: 1.0 / 45) }
    world.modify(Transform.self, for: ball) { $0.position = Vec3(7, 5, 0) }
    world.update(dt: 1.0 / 45)
    world.update(dt: 1.0 / 45)
    let shown = world.get(Transform.self, for: ball)!.position
    let exact = physics.pose(of: physics.body(for: ball)!)!.position
    #expect(abs(exact.x - 7) < 1e-4 && abs(shown.x - 7) < 1e-4 && abs(shown.y - 5) < 0.3)
    // Exact transforms can be put back before saving.
    physics.restoreExactTransforms(in: world)
    #expect(world.get(Transform.self, for: ball)!.position == exact)
    // Without the ECS: the pose between the last two steps.
    let plain = PhysicsWorld()
    let body = plain.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 10, 0)), shape: .sphere(radius: 0.25)))
    plain.advance(by: 1.5 * dt)
    let a = plain.interpolatedPose(of: body, alpha: 0)!.position.y, b = plain.interpolatedPose(of: body, alpha: 1)!.position.y
    #expect(a > b && abs(plain.interpolatedPose(of: body)!.position.y - (a + (b - a) * 0.5)) < 1e-4)
    #expect(b == plain.pose(of: body)!.position.y)
}
