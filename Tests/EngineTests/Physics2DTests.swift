import Foundation
import Testing
@testable import Engine

private func approx(_ a: Float, _ b: Float, _ eps: Float = 1e-3) -> Bool { abs(a - b) <= eps }
private func approx(_ a: Vec2, _ b: Vec2, _ eps: Float = 1e-3) -> Bool { length2(a - b) <= eps }

private func contacts(_ a: ColliderShape2D, _ pa: Pose2D, _ b: ColliderShape2D, _ pb: Pose2D, margin: Float = 0) -> Manifold2D? {
    Narrowphase2D.collide(a.geoms(offset: .identity)[0], pa, b.geoms(offset: .identity)[0], pb, margin: margin, slop: 0.005)
}

/// A static floor box with its top at y = 0.
@MainActor @discardableResult private func addFloor(_ physics: PhysicsWorld2D, friction: Float = 0.6) -> Body2DID {
    physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, -0.5)), shape: .box(Vec2(50, 0.5)),
                                     material: ColliderMaterial(friction: friction)))
}

@MainActor private func run(_ physics: PhysicsWorld2D, _ steps: Int) {
    for _ in 0..<steps { physics.step(1.0 / 60) }
}

// MARK: - Shapes and narrowphase

@Test func circleCircleContact() {
    let m = contacts(.circle(radius: 1), Pose2D(), .circle(radius: 0.5), Pose2D(position: Vec2(1.4, 0)))!
    #expect(m.points.count == 1 && approx(m.points[0].separation, -0.1))
    #expect(approx(m.normal, Vec2(1, 0)) && approx(m.points[0].point, Vec2(0.95, 0)))
    #expect(contacts(.circle(radius: 1), Pose2D(), .circle(radius: 0.5), Pose2D(position: Vec2(1.6, 0))) == nil)
    // Within the margin: a speculative point with positive separation.
    let near = contacts(.circle(radius: 1), Pose2D(), .circle(radius: 0.5), Pose2D(position: Vec2(1.52, 0)), margin: 0.05)!
    #expect(approx(near.points[0].separation, 0.02))
}

@Test func boxOnBoxGivesTwoPoints() {
    let m = contacts(.box(Vec2(2, 0.5)), Pose2D(), .box(Vec2(0.5, 0.5)), Pose2D(position: Vec2(0.3, 0.98), angle: 0))!
    #expect(m.points.count == 2)
    #expect(approx(m.normal, Vec2(0, 1)))
    for p in m.points {
        #expect(approx(p.separation, -0.02))
        #expect(approx(p.point.y, 0.49))
    }
    // The same pair from the other side flips the normal.
    let flipped = contacts(.box(Vec2(0.5, 0.5)), Pose2D(position: Vec2(0.3, 0.98)), .box(Vec2(2, 0.5)), Pose2D())!
    #expect(flipped.points.count == 2 && approx(flipped.normal, Vec2(0, -1)))
    // A tilted box resting on a corner: one deep point, one speculative at most.
    let tilted = contacts(.box(Vec2(2, 0.5)), Pose2D(), .box(Vec2(0.5, 0.5)), Pose2D(position: Vec2(0, 1.2), angle: .pi / 4))!
    #expect(approx(tilted.normal, Vec2(0, 1), 1e-2))
    let lowest: Float = 1.2 - 0.5 * Float(2).squareRoot() - 0.5
    #expect(approx(tilted.points.map(\.separation).min()!, lowest, 1e-3))
}

@Test func cornerToCornerUsesTheClosestPoints() {
    // Two boxes diagonal to each other, apart: the gap is the distance between the corners.
    let m = contacts(.box(Vec2(0.5, 0.5)), Pose2D(), .box(Vec2(0.5, 0.5)), Pose2D(position: Vec2(1.3, 1.3)), margin: 1)!
    #expect(m.points.count == 1)
    #expect(approx(m.points[0].separation, (0.3 * 0.3 * 2).squareRoot(), 1e-3))
    #expect(approx(m.normal, normalize2(Vec2(1, 1)), 1e-3))
}

@Test func capsuleContacts() {
    let lying = Pose2D(position: Vec2(0, 0.79), angle: .pi / 2)
    let m = contacts(.capsule(radius: 0.3, halfHeight: 0.6), lying, .box(Vec2(2, 0.5)), Pose2D())!
    #expect(m.points.count == 2)
    #expect(approx(m.normal, Vec2(0, -1)))
    for p in m.points { #expect(approx(p.separation, -0.01)) }
    // Standing on its end: one point under the bottom cap.
    let standing = contacts(.capsule(radius: 0.3, halfHeight: 0.6), Pose2D(position: Vec2(0, 1.39)), .box(Vec2(2, 0.5)), Pose2D())!
    #expect(standing.points.count == 1 && approx(standing.points[0].separation, -0.01))
    // Capsule against a circle beside its middle.
    let side = contacts(.capsule(radius: 0.3, halfHeight: 0.6), Pose2D(), .circle(radius: 0.2), Pose2D(position: Vec2(0.45, 0.1)))!
    #expect(approx(side.normal, Vec2(1, 0)) && approx(side.points[0].separation, -0.05))
}

@Test func edgeAndPolygonContacts() {
    let triangle = ColliderShape2D.polygon(points: [Vec2(-0.5, 0), Vec2(0.5, 0), Vec2(0, 0.8)])
    let ground = ColliderShape2D.edge(from: Vec2(-5, 0), to: Vec2(5, 0))
    let m = contacts(ground, Pose2D(), triangle, Pose2D(position: Vec2(0, -0.02)))!
    #expect(m.points.count == 2 && approx(m.normal, Vec2(0, 1)))
    // A circle on a segment's end is a point-vertex contact.
    let end = contacts(ground, Pose2D(), .circle(radius: 0.5), Pose2D(position: Vec2(5.3, 0.3)))!
    #expect(approx(end.points[0].separation, (0.3 * 0.3 * 2).squareRoot() - 0.5, 1e-3))
}

@Test func polygonHullIsConvexAndCapped() {
    let ring = (0..<20).map { k -> Vec2 in
        let a = Float(k) / 20 * 2 * .pi
        return Vec2(cosf(a), sinf(a))
    }
    let hull = ColliderShape2D.convexHull(ring + [Vec2(0, 0), Vec2(0.1, 0.1)])
    #expect(hull.count == Geom2D.maxVertices)
    for i in hull.indices {
        let a = hull[i], b = hull[(i + 1) % hull.count], c = hull[(i + 2) % hull.count]
        #expect(cross2(b - a, c - b) > 0)
    }
    // Collinear points disappear, clockwise input is fixed.
    #expect(ColliderShape2D.convexHull([Vec2(0, 0), Vec2(0, 1), Vec2(1, 1), Vec2(1, 0), Vec2(0.5, 0)]).count == 4)
}

@Test func massFromDensity() {
    let g = ColliderShape2D.box(Vec2(1, 0.5)).geoms(offset: .identity)[0].massData(density: 2)
    #expect(approx(g.mass, 4) && approx(g.inertia, 4 * (4 + 1) / 12))
    let c = ColliderShape2D.circle(radius: 1).geoms(offset: Pose2D(position: Vec2(1, 0)))[0].massData(density: 1)
    #expect(approx(c.mass, .pi, 1e-4) && approx(c.center, Vec2(1, 0)) && approx(c.inertia, .pi / 2, 1e-4))
    let capsule = ColliderShape2D.capsule(radius: 0.5, halfHeight: 0.5).geoms(offset: .identity)[0].massData(density: 1)
    #expect(approx(capsule.mass, 1 + .pi * 0.25, 1e-4))
}

// MARK: - Dynamics

@MainActor @Test func boxStackStaysStandingAndSleeps() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    var boxes: [Body2DID] = []
    for k in 0..<8 {
        boxes.append(physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 0.5 + Float(k) * 1.001)), shape: .box(Vec2(0.5, 0.5)))))
    }
    run(physics, 240)
    for (k, b) in boxes.enumerated() {
        let p = physics.pose(of: b)!
        #expect(abs(p.position.x) < 0.02, "box \(k) slid: \(p.position)")
        #expect(abs(p.position.y - (0.5 + Float(k))) < 0.06, "box \(k) at \(p.position)")
    }
    #expect(physics.awakeBodyCount == 0)
    // A body hitting the sleeping stack wakes it.
    let ball = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(-0.2, 12)), shape: .circle(radius: 0.4)))
    run(physics, 120)
    #expect(physics.pose(of: ball)!.position.y < 12)
    #expect(physics.awakeBodyCount > 0 || physics.pose(of: ball)!.position.y < 1)
}

@MainActor @Test func pyramidIsStable() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    let rows = 8
    var bodies: [(Body2DID, Vec2)] = []
    for row in 0..<rows {
        for k in 0..<(rows - row) {
            let p = Vec2((Float(k) - Float(rows - row - 1) / 2) * 1.02, 0.5 + Float(row) * 1.0)
            bodies.append((physics.addBody(BodyDescriptor2D(pose: Pose2D(position: p), shape: .box(Vec2(0.5, 0.5)))), p))
        }
    }
    run(physics, 300)
    for (b, start) in bodies {
        let p = physics.pose(of: b)!
        #expect(length2(p.position - start) < 0.15, "moved from \(start) to \(p.position)")
        #expect(abs(p.angle) < 0.05)
    }
}

@MainActor @Test func restitutionAndFriction() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    let bouncy = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 3)), shape: .circle(radius: 0.25),
                                                  material: ColliderMaterial(restitution: 0.8)))
    var peak: Float = 0, bounced = false
    for _ in 0..<150 {
        physics.step(1.0 / 60)
        let v = physics.linearVelocity(of: bouncy).y
        if v > 0 { bounced = true }
        if bounced { peak = max(peak, physics.pose(of: bouncy)!.position.y) }
    }
    // v after = 0.8 v before: the second peak is 0.64 of the drop (2.75 m).
    #expect(approx(peak - 0.25, 2.75 * 0.64, 0.15))

    // A box on a 20 degree slope: it stays with friction 0.5 (tan 20 = 0.36), slides without.
    func slide(friction: Float) -> Float {
        let w = PhysicsWorld2D()
        let angle: Float = 20 * .pi / 180
        w.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: .zero, angle: angle), shape: .box(Vec2(20, 0.5)),
                                   material: ColliderMaterial(friction: friction)))
        let up = Vec2(-sinf(angle), cosf(angle))
        let box = w.addBody(BodyDescriptor2D(pose: Pose2D(position: up * 1.0, angle: angle), shape: .box(Vec2(0.5, 0.5)),
                                             material: ColliderMaterial(friction: friction)))
        let start = w.pose(of: box)!.position
        run(w, 120)
        return length2(w.pose(of: box)!.position - start)
    }
    #expect(slide(friction: 0.5) < 0.1)
    #expect(slide(friction: 0.05) > 2)
}

@MainActor @Test func kinematicPlatformCarriesABox() {
    let physics = PhysicsWorld2D()
    let platform = physics.addBody(BodyDescriptor2D(motion: .kinematic, pose: Pose2D(position: Vec2(0, -0.25)), shape: .box(Vec2(3, 0.25))))
    let box = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 0.5)), shape: .box(Vec2(0.5, 0.5)),
                                               material: ColliderMaterial(friction: 1)))
    run(physics, 30)
    for k in 1...60 {
        physics.moveKinematic(platform, to: Pose2D(position: Vec2(Float(k) * 0.02, -0.25)), dt: 1.0 / 60)
        physics.step(1.0 / 60)
    }
    #expect(approx(physics.pose(of: platform)!.position.x, 1.2))
    #expect(abs(physics.pose(of: box)!.position.x - 1.2) < 0.15)
}

// MARK: - Joints

@MainActor @Test func revoluteJointHoldsAndSwings() {
    let physics = PhysicsWorld2D()
    let anchor = Vec2(0, 5)
    let bob = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(2, 5)), shape: .circle(radius: 0.2)))
    let ground = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: anchor), shape: .circle(radius: 0.1)))
    physics.addJoint(Joint2DDescriptor(kind: .revolute, bodyA: ground, bodyB: bob, anchor: anchor))
    var lowest: Float = 10
    for _ in 0..<240 {
        physics.step(1.0 / 60)
        let p = physics.pose(of: bob)!.position
        #expect(abs(length2(p - anchor) - 2) < 0.03)
        lowest = min(lowest, p.y)
    }
    #expect(lowest < 3.1)
}

@MainActor @Test func revoluteLimitsAndMotor() {
    let physics = PhysicsWorld2D()
    let hinge = Vec2(0, 5)
    let wall = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: hinge), shape: .circle(radius: 0.1)))
    let arm = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(1, 5)), shape: .box(Vec2(1, 0.1))))
    // A hanging arm that gravity pulls down, limited to -30...45 degrees.
    let joint = physics.addJoint(Joint2DDescriptor(kind: .revolute, bodyA: wall, bodyB: arm, anchor: hinge, enableLimit: true,
                                                    lowerAngle: -30 * .pi / 180, upperAngle: 45 * .pi / 180))!
    run(physics, 180)
    let angle = physics.jointAngle(joint)!
    #expect(approx(angle, -30 * .pi / 180, 0.03), "angle \(angle)")
    // Limits can be removed and a motor added: it turns up against gravity at the set speed.
    physics.setLimits(joint, lower: nil, upper: nil)
    physics.setMotor(joint, speed: 2, maxTorque: 1000)
    run(physics, 30)
    #expect(approx(physics.angularVelocity(of: arm), 2, 0.05))
    // The motor's torque is capped: a weak motor can't hold the arm up.
    physics.setMotor(joint, speed: 2, maxTorque: 0.01)
    run(physics, 120)
    #expect(physics.angularVelocity(of: arm) < 1)
}

@MainActor @Test func distanceJointRodAndSpring() {
    // A rod keeps its length.
    let physics = PhysicsWorld2D()
    let post = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 6)), shape: .circle(radius: 0.1)))
    let weight = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(3, 6)), shape: .circle(radius: 0.3)))
    physics.addJoint(Joint2DDescriptor(kind: .distance, bodyA: post, bodyB: weight, anchor: Vec2(0, 6), anchorB: Vec2(3, 6)))
    run(physics, 200)
    #expect(abs(length2(physics.pose(of: weight)!.position - Vec2(0, 6)) - 3) < 0.05)

    // A spring stretches under the weight and oscillates around its equilibrium.
    let spring = PhysicsWorld2D()
    let hook = spring.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 10)), shape: .circle(radius: 0.1)))
    let mass = spring.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 8)), shape: .circle(radius: 0.25),
                                               material: ColliderMaterial(density: 5), ), )
    spring.addJoint(Joint2DDescriptor(kind: .distance, bodyA: hook, bodyB: mass, anchor: Vec2(0, 10), anchorB: Vec2(0, 8),
                                      hertz: 1.5, dampingRatio: 0.05, minLength: 1, maxLength: 4))
    var lowest: Float = 10, highest: Float = 0
    for _ in 0..<360 {
        spring.step(1.0 / 60)
        let y = spring.pose(of: mass)!.position.y
        lowest = min(lowest, y)
        highest = max(highest, y)
    }
    // Equilibrium: 9.81 / (2 pi 1.5)^2 = 0.11 m below rest; the swing goes both ways around it.
    #expect(lowest < 7.9 && highest > 7.99 && lowest > 6)
    #expect(spring.pose(of: mass)!.position.y > 6)
}

@MainActor @Test func weldJointKeepsBodiesTogether() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    let a = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 3)), shape: .box(Vec2(0.5, 0.5))))
    let b = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(1, 3)), shape: .box(Vec2(0.5, 0.5))))
    physics.addJoint(Joint2DDescriptor(kind: .weld, bodyA: a, bodyB: b, anchor: Vec2(0.5, 3)))
    physics.setLinearVelocity(a, Vec2(1, 3))
    physics.setAngularVelocity(a, 2)
    run(physics, 240)
    let pa = physics.pose(of: a)!, pb = physics.pose(of: b)!
    #expect(abs(length2(pb.position - pa.position) - 1) < 0.03)
    let relative = (pb.rotation * pa.rotation.inverse).angle
    #expect(abs(relative) < 0.03)
}

@MainActor @Test func bridgeOfPlanksHolds() {
    let physics = PhysicsWorld2D()
    let left = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(-0.5, 0)), shape: .box(Vec2(0.5, 1))))
    let right = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(10.5, 0)), shape: .box(Vec2(0.5, 1))))
    var previous = left
    var planks: [Body2DID] = []
    for k in 0..<10 {
        let plank = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0.5 + Float(k), 1)), shape: .box(Vec2(0.5, 0.125)),
                                                     material: ColliderMaterial(friction: 0.6)))
        physics.addJoint(Joint2DDescriptor(kind: .revolute, bodyA: previous, bodyB: plank, anchor: Vec2(Float(k), 1)))
        planks.append(plank)
        previous = plank
    }
    physics.addJoint(Joint2DDescriptor(kind: .revolute, bodyA: previous, bodyB: right, anchor: Vec2(10, 1)))
    let crate = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(5, 2.5)), shape: .box(Vec2(0.5, 0.5))))
    run(physics, 300)
    // Sags but stays connected: planks are still next to each other and the crate is on it.
    for k in 1..<planks.count {
        let d = physics.pose(of: planks[k])!.position - physics.pose(of: planks[k - 1])!.position
        #expect(length2(d) < 1.1)
    }
    let c = physics.pose(of: crate)!.position
    #expect(c.y > 0 && c.y < 2.5 && abs(c.x - 5) < 1)
}

@MainActor @Test func mouseJointDragsABody() {
    let physics = PhysicsWorld2D()
    physics.gravity = .zero
    let box = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 0)), shape: .box(Vec2(0.5, 0.5))))
    let joint = physics.addMouseJoint(body: box, target: Vec2(0.4, 0.4), maxForce: 2000)!
    var target = Vec2(0.4, 0.4)
    for _ in 0..<120 {
        target += Vec2(0.05, 0.02)
        physics.setMouseTarget(joint, target)
        physics.step(1.0 / 60)
    }
    // The grabbed point follows the target.
    let grabbed = physics.pose(of: box)!.transform(Vec2(0.4, 0.4))
    #expect(length2(grabbed - target) < 0.5)
    #expect(physics.pose(of: box)!.position.x > 4)
    physics.removeJoint(joint)
    #expect(physics.jointCount == 0)
}

// MARK: - Queries

@MainActor @Test func rayAndShapeCasts() {
    let physics = PhysicsWorld2D()
    let box = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(5, 0)), shape: .box(Vec2(1, 1))))
    let ball = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(10, 0)), shape: .circle(radius: 1),
                                                layer: 2))
    let hit = physics.raycast(from: Vec2(0, 0), direction: Vec2(1, 0))!
    #expect(hit.body == box && approx(hit.distance, 4) && approx(hit.normal, Vec2(-1, 0)) && approx(hit.point, Vec2(4, 0)))
    let all = physics.raycastAll(from: Vec2(0, 0), direction: Vec2(1, 0))
    #expect(all.map(\.body) == [box, ball] && approx(all[1].distance, 9))
    // Layers, exclusion and range.
    #expect(physics.raycast(from: Vec2(0, 0), direction: Vec2(1, 0), filter: QueryFilter2D(mask: 2))?.body == ball)
    #expect(physics.raycast(from: Vec2(0, 0), direction: Vec2(1, 0), filter: QueryFilter2D(excluding: [box]))?.body == ball)
    #expect(physics.raycast(from: Vec2(0, 0), direction: Vec2(1, 0), maxDistance: 3) == nil)
    #expect(physics.raycast(from: Vec2(0, 5), direction: Vec2(1, 0)) == nil)
    // A circle cast stops a radius short; it also catches what the ray misses.
    let cast = physics.circleCast(radius: 0.5, from: Vec2(0, 1.2), direction: Vec2(1, 0), maxDistance: 20)!
    #expect(cast.body == box)
    // It meets the box's rounded corner at (4, 1), where the ray at y = 1.2 passes above the box.
    #expect(approx(cast.distance, 4 - Float(0.21).squareRoot(), 1e-3))
    #expect(physics.raycast(from: Vec2(0, 1.2), direction: Vec2(1, 0)) == nil)
    // Starting inside a collider hits at 0.
    #expect(physics.raycast(from: Vec2(5, 0), direction: Vec2(0, 1))?.distance == 0)
}

@MainActor @Test func overlapQueries() {
    let physics = PhysicsWorld2D()
    let a = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 0)), shape: .box(Vec2(1, 1))))
    let b = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(3, 0)), shape: .circle(radius: 1), layer: 2))
    let c = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 4)), shape: .capsule(radius: 0.5, halfHeight: 1)))
    #expect(physics.overlapPoint(Vec2(0.5, 0.5)) == [a])
    #expect(physics.overlapPoint(Vec2(2, 2)).isEmpty)
    #expect(physics.overlapCircle(center: Vec2(1.8, 0), radius: 0.9) == [a, b])
    #expect(physics.overlapCircle(center: Vec2(1.8, 0), radius: 0.9, filter: QueryFilter2D(mask: 2)) == [b])
    #expect(physics.overlapCircle(center: Vec2(0, 5.8), radius: 0.4) == [c])
    #expect(physics.overlapBox(center: Vec2(1.5, 0.5), halfExtents: Vec2(0.6, 0.4)) == [a, b])
    #expect(physics.overlapBox(center: Vec2(1.5, 2.5), halfExtents: Vec2(0.3, 0.3)).isEmpty)
    // Rotated: a thin box turned to reach the capsule.
    #expect(physics.overlapBox(center: Vec2(0, 2.2), halfExtents: Vec2(0.1, 1.2)) == [a, c])
}

// MARK: - Events, triggers, one-way

@MainActor @Test func contactAndTriggerEvents() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    let zone = physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 2)), shape: .box(Vec2(1, 0.5)),
                                                isTrigger: true))
    let ball = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 4)), shape: .circle(radius: 0.3)))
    var seen: [PhysicsEvent2D.Kind] = []
    var began: PhysicsEvent2D?
    for _ in 0..<150 {
        physics.step(1.0 / 60)
        for e in physics.events {
            if e.kind != .triggerStayed { seen.append(e.kind) }
            if e.kind == .collisionBegan { began = e }
            if e.kind == .triggerEntered { #expect(e.bodyA == zone && e.bodyB == ball) }
        }
        physics.clearEvents()
    }
    #expect(seen == [.triggerEntered, .triggerExited, .collisionBegan])
    #expect(approx(began!.normal, Vec2(0, 1)) && began!.point.y < 0.05)
    // Removing the ball ends the contact.
    physics.removeBody(ball)
    #expect(physics.events.contains { $0.kind == .collisionEnded })
}

@MainActor @Test func oneWayPlatformPassesFromBelowAndSupportsFromAbove() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, 2)), shape: .box(Vec2(2, 0.1)), isOneWay: true))
    // Thrown up from below: passes through, then lands on top.
    let up = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 0.5)), shape: .box(Vec2(0.3, 0.3)),
                                              linearVelocity: Vec2(0, 9)))
    // Dropped from above: stays on top.
    let down = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(1, 4)), shape: .circle(radius: 0.3)))
    run(physics, 240)
    #expect(approx(physics.pose(of: up)!.position.y, 2.1 + 0.3, 0.05))
    #expect(approx(physics.pose(of: down)!.position.y, 2.1 + 0.3, 0.05))
    // Under the platform a body just bumps the floor.
    let under = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(-1, 1.2)), shape: .circle(radius: 0.3),
                                                 linearVelocity: Vec2(0, 6)))
    run(physics, 200)
    #expect(physics.pose(of: under)!.position.y > 2.3)
}

@MainActor @Test func chainTerrainSupportsBodies() {
    let physics = PhysicsWorld2D()
    let hills = [Vec2(-1, 6)] + (0...20).map { Vec2(Float($0), 0.5 * sinf(Float($0) * 0.5)) } + [Vec2(21, 6)]
    physics.addBody(BodyDescriptor2D(motion: .static, shape: .chain(points: hills, isLoop: false)))
    let ball = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(2, 3)), shape: .circle(radius: 0.3),
                                                material: ColliderMaterial(friction: 0.8)))
    let box = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(12, 3)), shape: .box(Vec2(0.4, 0.4))))
    run(physics, 400)
    for b in [ball, box] {
        let p = physics.pose(of: b)!.position
        let ground = 0.5 * sinf(p.x * 0.5)
        #expect(p.y > ground && p.y < ground + 1.0, "\(p) over \(ground)")
    }
}

// MARK: - Determinism

@MainActor private func simulate() -> [Pose2D] {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    var bodies: [Body2DID] = []
    for k in 0..<30 {
        let x = Float(k % 5) * 0.9 - 2, y = 1 + Float(k / 5) * 1.1
        let shape: ColliderShape2D = k % 3 == 0 ? .circle(radius: 0.4) : (k % 3 == 1 ? .box(Vec2(0.4, 0.3)) : .capsule(radius: 0.2, halfHeight: 0.3))
        bodies.append(physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(x, y), angle: Float(k) * 0.3), shape: shape,
                                                       material: ColliderMaterial(restitution: k % 4 == 0 ? 0.5 : 0))))
    }
    physics.addJoint(Joint2DDescriptor(kind: .distance, bodyA: bodies[0], bodyB: bodies[1], anchor: Vec2(-2, 1), anchorB: Vec2(-1.1, 1), hertz: 3))
    run(physics, 200)
    return bodies.map { physics.pose(of: $0)! }
}

@MainActor @Test func physics2DSimulationIsDeterministic() {
    let a = simulate(), b = simulate()
    #expect(a == b)
    #expect(a.contains { $0.position.y > 0.1 })
}

// MARK: - ECS

@MainActor @Test func physics2DBodiesFollowComponentsAndSerialize() throws {
    let world = World()
    let physics = PhysicsWorld2D()
    world.addPhysics2D(physics)
    _ = world.spawn(Transform(position: Vec3(0, -0.5, 0)), Collider2D(.box(halfExtents: Vec2(40, 0.5))), Name("Floor"))
    let box = world.spawn(Transform(position: Vec3(0, 3, 2), rotation: Quat(angle: 0.3, axis: Vec3(0, 0, 1))),
                          Collider2D(.box(halfExtents: Vec2(0.5, 0.5)), friction: 0.7), RigidBody2D(), Name("Box"))
    let pendulum = world.spawn(Transform(position: Vec3(5, 5, 0)), Collider2D(.circle(radius: 0.3)), RigidBody2D(),
                               Joint2D(.revolute, anchor: Vec2(0, 1)))
    let zone = world.spawn(Transform(position: Vec3(0, 1.5, 0)), Collider2D(.box(halfExtents: Vec2(2, 0.2)), isTrigger: true))
    var entered: [Entity] = []
    world.addSystem("watch") { _ in
        for e in physics.events where e.kind == .triggerEntered && e.entityA == zone { entered.append(e.entityB!) }
    }
    for _ in 0..<120 { world.update(dt: 1.0 / 60) }

    // The box landed on the floor (z kept); its RigidBody2D holds its velocity.
    let t = world.get(Transform.self, for: box)!
    #expect(abs(t.position.y - 0.5) < 0.06 && t.position.z == 2)
    #expect(length2(world.get(RigidBody2D.self, for: box)!.linearVelocity) < 0.1)
    #expect(entered == [box])
    // The revolute joint pins the circle to a point 1 m above it.
    #expect(approx(Vec2(world.get(Transform.self, for: pendulum)!.position.x, world.get(Transform.self, for: pendulum)!.position.y), Vec2(5, 5), 0.05))
    #expect(physics.joint(for: pendulum) != nil)

    // Moving an entity teleports its body; removing the collider removes the body.
    world.modify(Transform.self, for: box) { $0.position = Vec3(10, 5, 2) }
    world.update(dt: 1.0 / 60)
    #expect(world.get(Transform.self, for: box)!.position.x == 10)
    world.remove(Collider2D.self, from: zone)
    world.update(dt: 1.0 / 60)
    #expect(physics.body(for: zone) == nil && physics.bodyCount == 3)

    // Round trip through a scene file.
    let data = try world.save()
    let copy = World()
    PhysicsWorld2D.registerComponents()
    _ = try copy.load(data)
    #expect(try copy.save() == data)
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"RigidBody2D\"") && text.contains("\"Collider2D\"") && text.contains("\"Joint2D\""))
    var loaded: [Collider2D] = []
    copy.query(Collider2D.self) { _, c in loaded.append(c) }
    #expect(loaded.contains { $0.friction == 0.7 && $0.shape == .box(halfExtents: Vec2(0.5, 0.5)) })
    let copyPhysics = PhysicsWorld2D()
    copy.addPhysics2D(copyPhysics)
    copy.update(dt: 1.0 / 60)
    #expect(copyPhysics.bodyCount == 3 && copyPhysics.jointCount == 1)
}

@MainActor @Test func shapesRoundTripThroughJSON() throws {
    let shapes: [ColliderShape2D] = [
        .circle(radius: 0.5), .box(halfExtents: Vec2(1, 2)), .polygon(points: [Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)]),
        .capsule(radius: 0.25, halfHeight: 1), .edge(from: Vec2(0, 0), to: Vec2(1, 1)),
        .chain(points: [Vec2(0, 0), Vec2(1, 0), Vec2(2, 1)], isLoop: true),
    ]
    for shape in shapes {
        let collider = Collider2D(shape, offset: Vec2(0, 1), rotation: 0.5, isTrigger: true, isOneWay: true, layer: 4, mask: 5)
        let decoded = try JSONDecoder().decode(Collider2D.self, from: JSONEncoder().encode(collider))
        #expect(decoded == collider)
    }
    let joint = Joint2D(.distance, anchor: Vec2(1, 2), length: 3, hertz: 2, maxLength: 5)
    #expect(try JSONDecoder().decode(Joint2D.self, from: JSONEncoder().encode(joint)) == joint)
}

@MainActor @Test func physics2DInterpolationDoesNotChangeTheSimulation() {
    func run(interpolated: Bool) -> (Vec3, Vec3) {
        let world = World()
        let physics = PhysicsWorld2D()
        physics.interpolatesPoses = interpolated
        world.addPhysics2D(physics)
        world.spawn(Transform(position: Vec3(0, -0.5, 0)), Collider2D(.box(halfExtents: Vec2(40, 0.5))))
        let ball = world.spawn(Transform(position: Vec3(0, 3, 0)), Collider2D(.circle(radius: 0.3), restitution: 0.4), RigidBody2D())
        var shown: Vec3 = .zero
        for _ in 0..<100 {
            world.update(dt: 1.0 / 45)
            shown = world.get(Transform.self, for: ball)!.position
        }
        // The exact pose of the body, whatever the displayed Transform says.
        let p = physics.pose(of: physics.body(for: ball)!)!.position
        return (shown, Vec3(p.x, p.y, 0))
    }
    let exact = run(interpolated: false), smooth = run(interpolated: true)
    #expect(exact.1 == smooth.1)
    #expect(exact.0 == Vec3(exact.1.x, exact.1.y, 0))
}

@MainActor @Test func removePhysics2DRemovesItsSystems() {
    let world = World()
    func names() -> [String] { SystemStage.allCases.flatMap { world.systemNames(in: $0) } }
    world.addPhysics2D(PhysicsWorld2D())
    for name in World.physics2DSystemNames { #expect(names().contains(name), "\(name)") }
    #expect(Set(names()) == Set(World.physics2DSystemNames))
    world.removePhysics2D()
    #expect(names().isEmpty)
}

@MainActor @Test func physics2DDebugDrawShowsCollidersContactsAndJoints() {
    let physics = PhysicsWorld2D()
    addFloor(physics)
    let a = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(0, 0.5)), shape: .box(Vec2(0.5, 0.5))))
    let b = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(2, 1)), shape: .capsule(radius: 0.2, halfHeight: 0.3)))
    physics.addJoint(Joint2DDescriptor(kind: .distance, bodyA: a, bodyB: b, anchor: Vec2(0, 0.5), anchorB: Vec2(2, 1)))
    run(physics, 5)
    let draw = DebugDraw()
    physics.drawDebug(into: draw, options: [.colliders])
    let colliders = draw.segmentCount
    #expect(colliders > 20)
    physics.drawDebug(into: draw, options: [.contacts, .joints, .bounds, .centersOfMass])
    #expect(draw.segmentCount > colliders + 10)
    // Everything lies in the z = 0.5 plane.
    let plane = DebugDraw()
    physics.drawDebug(into: plane, z: 0.5)
    for depth in DebugDepth.allCases { for s in plane.segments[depth] ?? [] { #expect(s.start.z == 0.5 && s.end.z == 0.5) } }
}
