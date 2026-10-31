import Foundation
import Testing
@testable import Engine

/// Solver islands and transform propagation on the job system: bit-identical results for any
/// thread count (card 654).
@MainActor @Suite struct ParallelIslandsTests {
    static let threadCounts = [2, 4, 7]

    /// Everything a 3D body's future depends on.
    struct BodyState3D: Equatable {
        var pose: Pose
        var linear: Vec3
        var angular: Vec3
        var awake: Bool
    }

    /// Six separate piles, a hanging chain (hinges and ball joints), a kinematic platform
    /// carrying a box stack, a sleeping stack woken by a falling ball and a fixed pair: every
    /// body's state after 120 steps.
    func simulate3D(threads: Int, steps: Int = 120) -> (states: [BodyState3D], units: Int) {
        let physics = PhysicsWorld()
        physics.jobs = JobSystem(threadCount: threads)
        defer { physics.jobs.shutdown() }
        physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(60, 0.5, 60))))
        var ids: [BodyID] = []
        for pile in 0..<6 {
            let origin = Vec3(Float(pile % 3) * 8 - 8, 0, Float(pile / 3) * 8 - 4)
            for i in 0..<27 {
                let p = origin + Vec3(Float(i % 3) * 0.9 - 0.9, 0.6 + Float(i / 9) * 1.1, Float((i / 3) % 3) * 0.9 - 0.9 + Float(i % 5) * 0.01)
                let shape: ColliderShape = i % 3 == 0 ? .box(Vec3(0.4, 0.3, 0.4)) : i % 3 == 1 ? .sphere(radius: 0.4) : .capsule(radius: 0.25, halfHeight: 0.25)
                ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: p), shape: shape,
                                                          material: ColliderMaterial(restitution: i % 4 == 0 ? 0.4 : 0),
                                                          angularVelocity: Vec3(Float(i % 5) * 0.2, 0, Float(i % 3) * 0.1))))
            }
        }
        // A chain hanging from the world, swinging.
        var previous: BodyID?
        for link in 0..<8 {
            let p = Vec3(20, 10 - Float(link) * 0.6, 0)
            let id = physics.addBody(BodyDescriptor(pose: Pose(position: p), shape: .capsule(radius: 0.1, halfHeight: 0.2),
                                                    linearVelocity: Vec3(link == 7 ? 3 : 0, 0, 1)))
            physics.addJoint(JointDescriptor(kind: link % 2 == 0 ? .hinge : .ball, bodyA: id, bodyB: previous,
                                             anchor: p + Vec3(0, 0.3, 0), axis: Vec3(0, 0, 1)))
            previous = id
            ids.append(id)
        }
        // Two boxes glued together, a distance rod to the world.
        let glueA = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(-20, 3, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
        let glueB = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(-19, 3, 0)), shape: .box(Vec3(0.5, 0.5, 0.5))))
        physics.addJoint(JointDescriptor(kind: .fixed, bodyA: glueA, bodyB: glueB, anchor: Vec3(-19.5, 3, 0)))
        physics.addJoint(JointDescriptor(kind: .distance, bodyA: glueB, anchor: Vec3(-19, 3.5, 0), anchorB: Vec3(-19, 6, 0)))
        ids += [glueA, glueB]
        // A kinematic platform under a small stack, moved every step.
        let platform = physics.addBody(BodyDescriptor(motion: .kinematic, pose: Pose(position: Vec3(0, 0.25, 15)), shape: .box(Vec3(2, 0.25, 2))))
        for k in 0..<4 {
            ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(Float(k % 2) - 0.5, 1 + Float(k / 2) * 0.9, 15)),
                                                      shape: .box(Vec3(0.4, 0.4, 0.4)))))
        }
        // A sleeping stack and a ball that wakes it.
        for k in 0..<3 {
            ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(10, 0.4 + Float(k) * 0.8, 15)),
                                                      shape: .box(Vec3(0.4, 0.4, 0.4)), startsAsleep: true)))
        }
        ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(10.1, 8, 15)), shape: .sphere(radius: 0.3))))

        var maxUnits = 0
        for step in 0..<steps {
            let t = Float(step) / 60
            physics.moveKinematic(platform, to: Pose(position: Vec3(sinf(t * 2) * 3, 0.25, 15), rotation: Quat(angle: t * 0.5, axis: Vec3(0, 1, 0))),
                                  dt: 1.0 / 60.0)
            physics.step(1.0 / 60.0)
            maxUnits = max(maxUnits, planUnits(physics).count)
        }
        #expect(physics.contactCount > 200)
        ids.append(platform)
        return (ids.map { BodyState3D(pose: physics.pose(of: $0)!, linear: physics.linearVelocity(of: $0),
                                      angular: physics.angularVelocity(of: $0), awake: physics.isAwake($0)) }, maxUnits)
    }

    /// The units the next solve would use (same plan as `solve`).
    func planUnits(_ physics: PhysicsWorld) -> [SolverUnit] {
        var planner = SolverPlanner(isDynamic: physics.bodies.map { $0.isAlive && $0.motion == .dynamic },
                                    isAwakeDynamic: physics.bodies.map { $0.isAlive && $0.isSolverActive })
        for (ci, c) in physics.contacts.enumerated() where !c.isTrigger && !c.points.isEmpty {
            guard physics.bodies[c.a].isSolverActive || physics.bodies[c.b].isSolverActive else { continue }
            planner.addContact(ci, c.a, c.b, points: c.points.count)
        }
        return planner.units().0
    }

    @Test func islands3DAreIdenticalForAnyThreadCount() {
        let reference = simulate3D(threads: 1)
        // The piles are solved as separate jobs.
        #expect(reference.units >= 4)
        for threads in Self.threadCounts {
            #expect(simulate3D(threads: threads).states == reference.states, "\(threads) threads")
        }
    }

    struct BodyState2D: Equatable {
        var pose: Pose2D
        var linear: Vec2
        var angular: Float
        var awake: Bool
    }

    /// Five separate 2D piles, a revolute chain with a motor and limits, a spring, a mouse
    /// joint and a kinematic paddle: every body's state after 150 steps.
    func simulate2D(threads: Int) -> [BodyState2D] {
        let physics = PhysicsWorld2D()
        physics.jobs = JobSystem(threadCount: threads)
        defer { physics.jobs.shutdown() }
        physics.addBody(BodyDescriptor2D(motion: .static, pose: Pose2D(position: Vec2(0, -0.5)), shape: .box(halfExtents: Vec2(80, 0.5))))
        var ids: [Body2DID] = []
        for pile in 0..<5 {
            let x0 = Float(pile) * 7 - 14
            for i in 0..<40 {
                let p = Vec2(x0 + Float(i % 5) * 0.85 - 1.7 + Float(i % 3) * 0.01, 0.5 + Float(i / 5) * 0.9)
                let shape: ColliderShape2D = i % 3 == 0 ? .box(halfExtents: Vec2(0.4, 0.3)) : i % 3 == 1 ? .circle(radius: 0.4)
                    : .capsule(radius: 0.2, halfHeight: 0.2)
                ids.append(physics.addBody(BodyDescriptor2D(pose: Pose2D(position: p, rotation: Rot2(angle: Float(i) * 0.3)), shape: shape,
                                                            material: ColliderMaterial(restitution: i % 4 == 0 ? 0.3 : 0, density: 1),
                                                            angularVelocity: Float(i % 5) * 0.3)))
            }
        }
        var previous: Body2DID?
        for link in 0..<6 {
            let p = Vec2(30, 10 - Float(link) * 0.8)
            let id = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: p), shape: .box(halfExtents: Vec2(0.1, 0.35)),
                                                      linearVelocity: Vec2(link == 5 ? 4 : 0, 0)))
            physics.addJoint(Joint2DDescriptor(kind: .revolute, bodyA: id, bodyB: previous, anchor: p + Vec2(0, 0.4),
                                               enableLimit: link == 2, lowerAngle: -0.5, upperAngle: 0.5,
                                               enableMotor: link == 4, motorSpeed: 2, maxMotorTorque: 5))
            previous = id
            ids.append(id)
        }
        let spring = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(-30, 5)), shape: .circle(radius: 0.5)))
        physics.addJoint(Joint2DDescriptor(kind: .distance, bodyA: spring, anchor: Vec2(-30, 5), anchorB: Vec2(-30, 8), hertz: 3,
                                           dampingRatio: 0.2, minLength: 1, maxLength: 4))
        let held = physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(-25, 2)), shape: .box(halfExtents: Vec2(0.5, 0.5))))
        let mouse = physics.addMouseJoint(body: held, target: Vec2(-25, 2), maxForce: 200)!
        let paddle = physics.addBody(BodyDescriptor2D(motion: .kinematic, pose: Pose2D(position: Vec2(40, 0.3)), shape: .box(halfExtents: Vec2(2, 0.2))))
        for k in 0..<3 { ids.append(physics.addBody(BodyDescriptor2D(pose: Pose2D(position: Vec2(40 + Float(k) - 1, 1)), shape: .circle(radius: 0.3)))) }
        ids += [spring, held, paddle]
        for step in 0..<150 {
            let t = Float(step) / 60
            physics.setMouseTarget(mouse, Vec2(-25 + sinf(t * 3) * 2, 3))
            physics.moveKinematic(paddle, to: Pose2D(position: Vec2(40 + sinf(t * 2), 0.3), rotation: Rot2(angle: sinf(t) * 0.2)), dt: 1.0 / 60.0)
            physics.step(1.0 / 60.0)
        }
        #expect(physics.contactCount > 150)
        return ids.map { BodyState2D(pose: physics.pose(of: $0)!, linear: physics.linearVelocity(of: $0),
                                     angular: physics.angularVelocity(of: $0), awake: physics.isAwake($0)) }
    }

    @Test func islands2DAreIdenticalForAnyThreadCount() {
        let reference = simulate2D(threads: 1)
        for threads in Self.threadCounts {
            #expect(simulate2D(threads: threads) == reference, "\(threads) threads")
        }
    }

    /// Islands: dynamic bodies joined through constraints; static and kinematic bodies are
    /// shared neighbours that don't join them; a constraint without a dynamic body gets a unit
    /// of its own.
    @Test func plannerSplitsIslandsAndSharesStaticBodies() {
        // 0 static ground, 1 kinematic, 2...7 dynamic.
        let dynamic = [false, false, true, true, true, true, true, true]
        var planner = SolverPlanner(isDynamic: dynamic, isAwakeDynamic: [false, false, true, true, true, true, false, false])
        planner.addContact(0, 0, 2, points: 4)      // ground - 2
        planner.addContact(1, 2, 3, points: 2)      // 2 - 3: one island
        planner.addContact(2, 0, 4, points: 4)      // ground - 4: the ground doesn't join 4 to 2
        planner.addContact(3, 1, 5, points: 1)      // kinematic - 5
        planner.addJoint(0, 4, 6)                   // 4 - 6 (6 asleep: pulled into the solver)
        planner.addJoint(1, 1, 0)                   // kinematic - world: no dynamic body
        let (units, local) = planner.units()
        let members = units.flatMap(\.members)
        #expect(Set(members) == [2, 3, 4, 5, 6])
        #expect(members.count == 5)
        #expect(!members.contains(7))
        #expect(local[0] == -1 && local[1] == -1 && local[7] == -1)
        // Small islands share a unit; every contact and joint is in exactly one unit.
        #expect(units.flatMap(\.contacts).sorted() == [0, 1, 2, 3])
        #expect(units.flatMap(\.joints).sorted() == [0, 1])
        let orphan = units.first { $0.members.isEmpty }
        #expect(orphan?.joints == [1])
        #expect(orphan?.neighbours.sorted() == [0, 1])
        for unit in units { #expect(Set(unit.neighbours).count == unit.neighbours.count) }
        // Members' local indices are their place in their unit.
        for unit in units {
            for (k, i) in unit.members.enumerated() { #expect(local[i] == Int32(k)) }
        }
    }

    /// Hundreds of roots with three levels below them, moved and re-propagated: the same
    /// matrices for any thread count.
    func propagate(threads: Int) -> [Mat4] {
        let jobs = JobSystem(threadCount: threads)
        defer { jobs.shutdown() }
        let world = World()
        var entities: [Entity] = []
        for r in 0..<700 {
            let root = world.spawn(Transform(position: Vec3(Float(r % 30), 0, Float(r / 30)), rotation: Quat(angle: Float(r) * 0.1, axis: Vec3(0, 1, 0))))
            entities.append(root)
            var parent = root
            for depth in 1...3 {
                for sibling in 0..<2 {
                    let child = world.spawn(Transform(position: Vec3(0.5, Float(depth), Float(sibling)), rotation: Quat(angle: 0.3, axis: Vec3(1, 0, 0)),
                                                      scale: Vec3(repeating: 0.9)))
                    world.setParent(child, to: parent)
                    entities.append(child)
                    if sibling == 1 { parent = child }
                }
            }
        }
        world.propagateTransforms(jobs: jobs)
        var matrices = entities.map { world.get(GlobalTransform.self, for: $0)!.matrix }
        // Move every third root and every fifth entity, then propagate again (dirty subtrees only).
        for (k, entity) in entities.enumerated() where k % 3 == 0 || k % 5 == 0 {
            world.modify(Transform.self, for: entity) { $0.position.y += Float(k % 7) * 0.25 }
        }
        world.propagateTransforms(jobs: jobs)
        matrices += entities.map { world.get(GlobalTransform.self, for: $0)!.matrix }
        return matrices
    }

    @Test func transformPropagationIsIdenticalForAnyThreadCount() {
        let reference = propagate(threads: 1)
        for threads in Self.threadCounts {
            #expect(propagate(threads: threads) == reference, "\(threads) threads")
        }
    }
}
