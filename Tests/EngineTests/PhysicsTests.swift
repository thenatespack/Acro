import Foundation
import Testing
@testable import Engine

private func approx(_ a: Float, _ b: Float, _ eps: Float = 1e-3) -> Bool { abs(a - b) <= eps }
private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-3) -> Bool { length(a - b) <= eps }

private func contacts(_ a: ColliderShape, _ pa: Pose, _ b: ColliderShape, _ pb: Pose, margin: Float = 0) -> [ContactPoint] {
    Narrowphase.collide(Shape(a), pa, Shape(b), pb, margin: margin)
}

/// A static floor box with its top at y = 0.
@MainActor private func addFloor(_ physics: PhysicsWorld, size: Float = 50) -> BodyID {
    physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(size, 0.5, size))))
}

// MARK: - Shapes and narrowphase

@Test func sphereSphereContact() {
    let points = contacts(.sphere(radius: 1), Pose(), .sphere(radius: 0.5), Pose(position: Vec3(1.4, 0, 0)))
    #expect(points.count == 1)
    #expect(approx(points[0].separation, -0.1))
    #expect(approx(points[0].normal, Vec3(1, 0, 0)))
    #expect(approx(points[0].pointA, Vec3(1, 0, 0)) && approx(points[0].pointB, Vec3(0.9, 0, 0)))
    #expect(contacts(.sphere(radius: 1), Pose(), .sphere(radius: 0.5), Pose(position: Vec3(1.6, 0, 0))).isEmpty)
    // Within the margin: a speculative point with positive separation.
    let near = contacts(.sphere(radius: 1), Pose(), .sphere(radius: 0.5), Pose(position: Vec3(1.52, 0, 0)), margin: 0.05)
    #expect(near.count == 1 && approx(near[0].separation, 0.02))
}

@Test func boxOnBoxGivesFourPoints() {
    let points = contacts(.box(Vec3(2, 0.5, 2)), Pose(), .box(Vec3(0.5, 0.5, 0.5)),
                          Pose(position: Vec3(0.3, 0.98, -0.2), rotation: Quat(angle: 0.4, axis: Vec3(0, 1, 0))))
    #expect(points.count == 4)
    for p in points {
        #expect(approx(p.normal, Vec3(0, 1, 0)))
        #expect(approx(p.separation, -0.02))
        #expect(approx(p.pointA.y, 0.5))
    }
    // Edge on edge: two boxes rotated 45° about perpendicular axes, one above the other.
    let edge = contacts(.box(Vec3(0.5, 0.5, 0.5)), Pose(rotation: Quat(angle: .pi / 4, axis: Vec3(1, 0, 0))),
                        .box(Vec3(0.5, 0.5, 0.5)), Pose(position: Vec3(0, 1.4, 0), rotation: Quat(angle: .pi / 4, axis: Vec3(0, 0, 1))))
    #expect(edge.count == 1)
    #expect(approx(edge[0].normal, Vec3(0, 1, 0), 1e-2))
    #expect(approx(edge[0].separation, 1.4 - 2 * Float(0.5).squareRoot(), 1e-3))
}

@Test func capsuleLyingOnBoxGivesTwoPoints() {
    let lying = Pose(position: Vec3(0, 0.79, 0), rotation: Quat(angle: .pi / 2, axis: Vec3(0, 0, 1)))
    let points = contacts(.capsule(radius: 0.3, halfHeight: 0.6), lying, .box(Vec3(2, 0.5, 2)), Pose())
    #expect(points.count == 2)
    for p in points {
        #expect(approx(p.normal, Vec3(0, -1, 0)))
        #expect(approx(p.separation, -0.01))
    }
    // Standing up: one point under the bottom cap.
    let standing = contacts(.capsule(radius: 0.3, halfHeight: 0.6), Pose(position: Vec3(0, 1.39, 0)), .box(Vec3(2, 0.5, 2)), Pose())
    #expect(standing.count == 1 && approx(standing[0].pointA, Vec3(0, 0.49, 0)))
    // Capsule against capsule, parallel: two points.
    let pair = contacts(.capsule(radius: 0.3, halfHeight: 0.6), Pose(), .capsule(radius: 0.3, halfHeight: 0.6), Pose(position: Vec3(0.55, 0.2, 0)))
    #expect(pair.count == 2 && pair.allSatisfy { approx($0.separation, -0.05) && approx($0.normal, Vec3(1, 0, 0)) })
}

@Test func sphereInsideBoxUsesLeastPenetration() {
    let points = contacts(.sphere(radius: 0.25), Pose(position: Vec3(0.3, 0, 0)), .box(Vec3(0.5, 0.5, 0.5)), Pose())
    #expect(points.count == 1)
    // Pushed out through +x: the normal from sphere to box points -x.
    #expect(approx(points[0].normal, Vec3(-1, 0, 0)))
    #expect(approx(points[0].separation, -0.45))
}

@Test func convexHullFromCubeCorners() {
    let corners = (0..<8).map { i in Vec3(i & 1 == 0 ? -1 : 1, i & 2 == 0 ? -1 : 1, i & 4 == 0 ? -1 : 1) }
    // Interior and face points must not become vertices.
    let hull = ConvexPolyhedron.hull(corners + [.zero, Vec3(0, 1, 0), Vec3(0.5, 1, 0.5)])!
    #expect(hull.vertices.count == 8)
    #expect(hull.faces.count == 6)
    #expect(hull.edges.count == 12)
    #expect(hull.edgeDirections.count == 3)
    for face in hull.faces {
        #expect(face.indices.count == 4)
        // Counter-clockwise from outside.
        let p = face.indices.map { hull.vertices[$0] }
        #expect(dot(cross(p[1] - p[0], p[2] - p[0]), face.normal) > 0)
    }
    let mass = hull.massProperties(density: 2)
    let box = Shape(.box(Vec3(1, 1, 1))).massProperties(density: 2)
    #expect(approx(mass.mass, 16) && approx(mass.center, .zero))
    #expect(approx(mass.inertia.c0, box.inertia.c0, 1e-2) && approx(mass.inertia.c1, box.inertia.c1, 1e-2))
    // A tetrahedron hull against a sphere.
    let tetra: ColliderShape = .convexHull(points: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)])
    let points = contacts(tetra, Pose(), .sphere(radius: 0.5), Pose(position: Vec3(0.2, 0.2, -0.4)))
    #expect(points.count == 1 && approx(points[0].normal, Vec3(0, 0, -1)) && approx(points[0].separation, -0.1))
}

@Test func gjkDistanceBetweenBoxes() {
    let a = ConvexPolyhedron.box(Vec3(0.5, 0.5, 0.5)).vertices
    let b = ConvexPolyhedron.box(Vec3(0.5, 0.5, 0.5)).vertices.map { $0 + Vec3(3, 2, 0) }
    let r = gjkDistance(a, b)
    #expect(approx(r.distance, (4 + 1 as Float).squareRoot()))
    #expect(approx(r.pointA, Vec3(0.5, 0.5, r.pointA.z)) && approx(r.pointB, Vec3(2.5, 1.5, r.pointB.z)))
    #expect(gjkDistance(a, a.map { $0 + Vec3(0.5, 0, 0) }).distance == 0)
}

@Test func sphereOnTriangleMesh() {
    // Two triangles making a 4x4 square at y = 0.
    let mesh: ColliderShape = .triangleMesh(vertices: [Vec3(-2, 0, -2), Vec3(2, 0, -2), Vec3(2, 0, 2), Vec3(-2, 0, 2)],
                                            indices: [0, 2, 1, 0, 3, 2])
    let points = contacts(mesh, Pose(), .sphere(radius: 0.5), Pose(position: Vec3(0.3, 0.45, 0.1)))
    #expect(!points.isEmpty)
    for p in points { #expect(approx(p.normal, Vec3(0, 1, 0)) && approx(p.separation, -0.05)) }
    let box = contacts(mesh, Pose(), .box(Vec3(0.5, 0.5, 0.5)), Pose(position: Vec3(0, 0.49, 0)))
    #expect(box.count == 4 && box.allSatisfy { approx($0.normal, Vec3(0, 1, 0)) })
}

// MARK: - Simulation

@MainActor @Test func boxStackSettlesAndSleeps() {
    let physics = PhysicsWorld()
    _ = addFloor(physics)
    let boxes = (0..<8).map { k in
        physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 0.5 + Float(k) * 1.0, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
    }
    for _ in 0..<240 { physics.step(1.0 / 60) }
    for (k, box) in boxes.enumerated() {
        let p = physics.pose(of: box)!.position
        #expect(abs(p.x) < 0.02 && abs(p.z) < 0.02)
        #expect(abs(p.y - (0.5 + Float(k))) < 0.03)
    }
    #expect(boxes.allSatisfy { !physics.isAwake($0) })
}

@MainActor @Test func pyramidStaysStanding() {
    let physics = PhysicsWorld()
    _ = addFloor(physics)
    var boxes: [(BodyID, Vec3)] = []
    for row in 0..<6 {
        for k in 0..<(6 - row) {
            let p = Vec3(Float(k) * 1.02 - Float(5 - row) * 0.51, 0.5 + Float(row), 0)
            boxes.append((physics.addBody(BodyDescriptor(pose: Pose(position: p), shape: .box(Vec3(0.5, 0.5, 0.5)))), p))
        }
    }
    for _ in 0..<300 { physics.step(1.0 / 60) }
    for (box, start) in boxes { #expect(length(physics.pose(of: box)!.position - start) < 0.05) }
}

@MainActor @Test func fallingSphereBouncesWithRestitution() {
    let physics = PhysicsWorld()
    physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(10, 0.5, 10)),
                                   material: ColliderMaterial(restitution: 0.8)))
    let ball = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 5, 0)), shape: .sphere(radius: 0.5),
                                              material: ColliderMaterial(restitution: 0.8), linearDamping: 0))
    var bounced = false, lowest: Float = 10
    for _ in 0..<120 {
        physics.step(1.0 / 60)
        let v = physics.linearVelocity(of: ball)
        lowest = min(lowest, physics.pose(of: ball)!.position.y)
        if v.y > 4 { bounced = true }
    }
    #expect(bounced)
    #expect(lowest > 0.45)
}

@MainActor @Test func sphereRollsDownRampOntoMesh() {
    let physics = PhysicsWorld()
    var vertices: [Vec3] = []
    var indices: [UInt32] = []
    for z in 0...10 {
        for x in 0...10 { vertices.append(Vec3(Float(x) * 2 - 10, sinf(Float(x)) * 0.1, Float(z) * 2 - 10)) }
    }
    for z in 0..<10 {
        for x in 0..<10 {
            let i = UInt32(z * 11 + x)
            indices += [i, i + 11, i + 1, i + 1, i + 11, i + 12]
        }
    }
    physics.addBody(BodyDescriptor(motion: .static, shape: .triangleMesh(vertices: vertices, indices: indices)))
    physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(-4, 1.5, 0), rotation: Quat(angle: -0.4, axis: Vec3(0, 0, 1))),
                                   shape: .box(Vec3(3, 0.2, 1.5))))
    let ball = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(-6, 4, 0)), shape: .sphere(radius: 0.4)))
    let capsule = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(-6, 4, 0.9), rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))),
                                                 shape: .capsule(radius: 0.3, halfHeight: 0.4)))
    for _ in 0..<240 { physics.step(1.0 / 60) }
    let p = physics.pose(of: ball)!.position, q = physics.pose(of: capsule)!.position
    #expect(p.x > -2)  // rolled down and on
    #expect(p.y > 0.2 && p.y < 0.6)  // resting on the mesh, not through it
    #expect(q.x > -3 && q.y > 0.1 && q.y < 0.6)
}

@MainActor @Test func hingePendulumKeepsItsPivot() {
    let physics = PhysicsWorld()
    let pivot = Vec3(0, 5, 0)
    let link = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(1, 5, 0)), shape: .box(Vec3(0.5, 0.1, 0.1))))
    physics.addJoint(JointDescriptor(kind: .hinge, bodyA: link, anchor: pivot, axis: Vec3(0, 0, 1)))
    var swung = false
    for _ in 0..<120 {
        physics.step(1.0 / 60)
        let pose = physics.pose(of: link)!
        // The hinge end stays put, and it only rotates about z.
        #expect(approx(pose.transform(Vec3(-1, 0, 0)), pivot, 0.03))
        #expect(abs(dot(pose.rotation * Vec3(0, 0, 1), Vec3(0, 0, 1))) > 0.999)
        if pose.position.y < 4.2 { swung = true }
    }
    #expect(swung)

    // A fixed joint holds two bodies together as one.
    let a = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(5, 5, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
    let b = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(6, 5, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
    physics.addJoint(JointDescriptor(kind: .fixed, bodyA: a, anchor: Vec3(5, 5, 0)))
    physics.addJoint(JointDescriptor(kind: .fixed, bodyA: a, bodyB: b, anchor: Vec3(5.5, 5, 0)))
    for _ in 0..<60 { physics.step(1.0 / 60) }
    #expect(approx(physics.pose(of: b)!.position, Vec3(6, 5, 0), 0.05))
}

@MainActor @Test func simulationIsDeterministic() {
    func run() -> [Pose] {
        let physics = PhysicsWorld()
        _ = addFloor(physics)
        var ids: [BodyID] = []
        for k in 0..<30 {
            let shape: ColliderShape = k % 3 == 0 ? .sphere(radius: 0.4) : (k % 3 == 1 ? .box(Vec3(0.4, 0.3, 0.5)) : .capsule(radius: 0.25, halfHeight: 0.3))
            let p = Vec3(Float(k % 5) * 0.7 - 1.4, 1 + Float(k) * 0.6, Float(k % 3) * 0.5)
            ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: p, rotation: Quat(angle: Float(k), axis: Vec3(1, 1, 0))), shape: shape)))
        }
        for _ in 0..<180 { physics.step(1.0 / 60) }
        return ids.map { physics.pose(of: $0)! }
    }
    let a = run(), b = run()
    #expect(a == b)
}

// MARK: - Queries

@MainActor @Test func raycastsHitClosestAndAll() {
    let physics = PhysicsWorld()
    let near = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(5, 0, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
    let far = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(10, 0, 0)), shape: .sphere(radius: 1)))
    let capsule = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(15, 0, 0)), shape: .capsule(radius: 0.5, halfHeight: 1),
                                                 layer: 2))
    let trigger = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(2, 0, 0)), shape: .sphere(radius: 0.5), isTrigger: true))
    let ray = Ray(origin: .zero, direction: Vec3(1, 0, 0))

    let hit = physics.raycast(ray)!
    #expect(hit.body == near && approx(hit.distance, 4.5) && approx(hit.normal, Vec3(-1, 0, 0)) && approx(hit.point, Vec3(4.5, 0, 0)))
    let all = physics.raycastAll(ray)
    #expect(all.map(\.body) == [near, far, capsule])
    #expect(approx(all[1].distance, 9) && approx(all[2].distance, 14.5))
    #expect(physics.raycastAll(ray, filter: QueryFilter(includeTriggers: true)).first?.body == trigger)
    #expect(physics.raycastAll(ray, filter: QueryFilter(mask: 2)).map(\.body) == [capsule])
    #expect(physics.raycast(ray, filter: QueryFilter(excluding: [near]))?.body == far)
    #expect(physics.raycast(ray, maxDistance: 4) == nil)
    // Hitting a rotated box from above, and the capsule's side.
    #expect(approx(physics.raycast(Ray(origin: Vec3(5, 10, 0), direction: Vec3(0, -1, 0)))!.distance, 9.5))
    let side = physics.raycast(Ray(origin: Vec3(15, 0.5, -5), direction: Vec3(0, 0, 1)))!
    #expect(side.body == capsule && approx(side.distance, 4.5) && approx(side.normal, Vec3(0, 0, -1)))
}

@MainActor @Test func shapeCastsAndOverlaps() {
    let physics = PhysicsWorld()
    let floor = addFloor(physics)
    let wall = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(5, 1, 0)), shape: .box(Vec3(0.5, 1, 2))))
    let hit = physics.sphereCast(center: Vec3(0, 1, 0), radius: 0.5, direction: Vec3(1, 0, 0), maxDistance: 10)!
    #expect(hit.body == wall && approx(hit.distance, 4, 2e-3) && approx(hit.normal, Vec3(-1, 0, 0)))
    let down = physics.boxCast(center: Vec3(0, 3, 0), halfExtents: Vec3(0.5, 0.5, 0.5), direction: Vec3(0, -1, 0), maxDistance: 10)!
    #expect(down.body == floor && approx(down.distance, 2.5, 2e-3) && approx(down.normal, Vec3(0, 1, 0)))
    #expect(physics.sphereCast(center: Vec3(0, 1, 0), radius: 0.5, direction: Vec3(-1, 0, 0), maxDistance: 10) == nil)

    #expect(physics.overlapSphere(center: Vec3(4.2, 1, 0), radius: 0.4) == [wall])
    #expect(physics.overlapSphere(center: Vec3(4, 1.5, 0), radius: 0.4).isEmpty)
    #expect(physics.overlapBox(center: Vec3(4.5, 0, 0), halfExtents: Vec3(0.2, 0.2, 0.2)) == [floor, wall])
    #expect(physics.overlapBox(center: Vec3(4.5, 0, 0), halfExtents: Vec3(0.2, 0.2, 0.2), filter: QueryFilter(excluding: [floor])) == [wall])
}

// MARK: - Events

@MainActor @Test func triggerAndCollisionEvents() {
    let physics = PhysicsWorld()
    let floor = addFloor(physics)
    let zone = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, 3, 0)), shape: .box(Vec3(1, 0.5, 1)), isTrigger: true))
    let ball = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 6, 0)), shape: .sphere(radius: 0.25)))
    var log: [PhysicsEvent] = []
    physics.onEvent = { log.append($0) }
    for _ in 0..<120 { physics.step(1.0 / 60) }
    let kinds = log.map(\.kind)
    let entered = kinds.firstIndex(of: .triggerEntered)!, exited = kinds.firstIndex(of: .triggerExited)!
    let began = kinds.firstIndex(of: .collisionBegan)!
    #expect(entered < exited && exited < began)
    #expect(kinds[(entered + 1)..<exited].allSatisfy { $0 == .triggerStayed } && exited - entered > 2)
    #expect(log[entered].bodyA == zone && log[entered].bodyB == ball)
    #expect(Set([log[began].bodyA, log[began].bodyB]) == [floor, ball])
    #expect(physics.events.count == log.count)
    #expect(kinds.filter { $0 == .triggerEntered }.count == 1)
    // Removing the ball ends its collision.
    physics.clearEvents()
    physics.removeBody(ball)
    #expect(physics.events.map(\.kind) == [.collisionEnded])
}

// MARK: - ECS

@MainActor @Test func ecsBodiesFollowComponentsAndSerialize() throws {
    let world = World()
    let physics = PhysicsWorld()
    world.addPhysics(physics)
    _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)), Collider(.box(Vec3(0.5, 0.5, 0.5))), Name("Floor"))
    let box = world.spawn(Transform(position: Vec3(0, 3, 0), scale: Vec3(1, 2, 1)), Collider(.box(Vec3(0.5, 0.5, 0.5)), friction: 0.7),
                          RigidBody(), Name("Box"))
    let pivot = world.spawn(Transform(position: Vec3(5, 5, 0)), Collider(.sphere(radius: 0.3)), RigidBody(), Joint(.ball, anchor: Vec3(0, 1, 0)))
    let zone = world.spawn(Transform(position: Vec3(0, 1.5, 0)), Collider(.box(Vec3(2, 0.2, 2)), isTrigger: true))
    var entered: [Entity] = []
    world.addSystem("watch") { _ in
        for e in physics.events where e.kind == .triggerEntered && e.entityA == zone { entered.append(e.entityB!) }
    }
    for _ in 0..<90 { world.update(dt: 1.0 / 60) }

    // The box (scaled to 1 x 2 x 1) landed on the scaled floor; its RigidBody holds its velocity.
    let t = world.get(Transform.self, for: box)!
    #expect(abs(t.position.y - 1) < 0.03 && t.scale == Vec3(1, 2, 1))
    #expect(length(world.get(RigidBody.self, for: box)!.linearVelocity) < 0.1)
    #expect(entered == [box])
    // The ball joint holds the sphere 1 m below the pivot point.
    #expect(approx(world.get(Transform.self, for: pivot)!.position, Vec3(5, 5, 0), 0.03))
    #expect(physics.joint(for: pivot) != nil)

    // Moving an entity teleports its body; removing the collider removes the body.
    world.modify(Transform.self, for: box) { $0.position = Vec3(10, 5, 0) }
    world.update(dt: 1.0 / 60)
    #expect(world.get(Transform.self, for: box)!.position.x == 10)
    world.remove(Collider.self, from: zone)
    world.update(dt: 1.0 / 60)
    #expect(physics.body(for: zone) == nil && physics.bodyCount == 3)

    // Round trip through a scene file.
    let data = try world.save()
    let copy = World()
    PhysicsWorld.registerComponents()
    _ = try copy.load(data)
    #expect(try copy.save() == data)
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"RigidBody\"") && text.contains("\"Collider\"") && text.contains("\"Joint\""))
    var loaded: [Collider] = []
    copy.query(Collider.self) { _, c in loaded.append(c) }
    #expect(loaded.contains { $0.friction == 0.7 && $0.shape == .box(halfExtents: Vec3(0.5, 0.5, 0.5)) })
    // The copy simulates the same way.
    let copyPhysics = PhysicsWorld()
    copy.addPhysics(copyPhysics)
    copy.update(dt: 1.0 / 60)
    #expect(copyPhysics.bodyCount == 3 && copyPhysics.jointCount == 1)
}

@MainActor @Test func colliderShapesRoundTripThroughJSON() throws {
    let shapes: [ColliderShape] = [
        .box(Vec3(1, 2, 3)), .sphere(radius: 0.5), .capsule(radius: 0.25, halfHeight: 1),
        .convexHull(points: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)]),
        .triangleMesh(vertices: [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 0, 1)], indices: [0, 2, 1]),
    ]
    for shape in shapes {
        let collider = Collider(shape, offset: Vec3(0, 1, 0), isTrigger: true, layer: 4, mask: 5)
        let decoded = try JSONDecoder().decode(Collider.self, from: JSONEncoder().encode(collider))
        #expect(decoded == collider)
    }
    let joint = Joint(.hinge, connectedTo: nil, anchor: Vec3(1, 0, 0), axis: Vec3(0, 0, 1))
    #expect(try JSONDecoder().decode(Joint.self, from: JSONEncoder().encode(joint)) == joint)
}

@MainActor @Test func debugDrawShowsCollidersContactsAndJoints() {
    let physics = PhysicsWorld()
    _ = addFloor(physics)
    let box = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 0.49, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
    physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(3, 1, 0)), shape: .capsule(radius: 0.3, halfHeight: 0.5)))
    physics.addJoint(JointDescriptor(kind: .ball, bodyA: box, anchor: Vec3(0, 2, 0)))
    physics.step(1.0 / 60)
    let draw = DebugDraw()
    physics.drawDebug(into: draw, options: [])
    #expect(draw.isEmpty)
    physics.drawDebug(into: draw, options: .colliders)
    let colliders = draw.segmentCount
    #expect(colliders >= 24)  // two boxes' edges plus the capsule
    physics.drawDebug(into: draw, options: [.contacts, .bounds, .joints])
    #expect(draw.segmentCount > colliders + 4 * 3 + 12)
}
