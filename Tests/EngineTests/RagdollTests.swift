import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// Joint limits (hinge range, ball swing cone and twist) and ragdolls: bodies built from a
// skeleton, going limp, hit reactions, getting up, the character builder's automatic bodies.

@MainActor
@Suite struct RagdollTests {
    /// A pendulum: a static anchor and a box hanging from it, kicked sideways.
    private func pendulum(_ kind: JointKind, limits: JointLimits?, kick: Vec3) -> (PhysicsWorld, BodyID, JointID) {
        let physics = PhysicsWorld()
        physics.gravity = .zero
        let anchor = physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, 2, 0)), shape: .sphere(radius: 0.05)))
        let bob = physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 1.5, 0)), shape: .capsule(radius: 0.05, halfHeight: 0.4),
                                                 angularDamping: 0))
        let joint = physics.addJoint(JointDescriptor(kind: kind, bodyA: anchor, bodyB: bob, anchor: Vec3(0, 2, 0),
                                                     axis: kind == .hinge ? Vec3(0, 0, 1) : Vec3(0, -1, 0), limits: limits))!
        physics.setAngularVelocity(bob, kick)
        return (physics, bob, joint)
    }

    @Test func hingeLimitsStopTheSwing() {
        let (physics, bob, _) = pendulum(.hinge, limits: .degrees(min: -20, max: 30), kick: Vec3(0, 0, 6))
        var largest: Float = 0, smallest: Float = 0
        for _ in 0..<120 {
            physics.step(1.0 / 60.0)
            let down = physics.pose(of: bob)!.rotation * Vec3(0, -1, 0)
            let angle = atan2f(down.x, -down.y)  // +z rotation swings the bottom toward +x
            largest = max(largest, angle)
            smallest = min(smallest, angle)
        }
        #expect(largest < 32 * .pi / 180 && largest > 25 * .pi / 180, "\(largest * 180 / .pi)")
        #expect(smallest > -2 * .pi / 180)
        // The other way stops at the lower limit.
        let (back, bob2, _) = pendulum(.hinge, limits: .degrees(min: -20, max: 30), kick: Vec3(0, 0, -6))
        var lowest: Float = 0
        for _ in 0..<120 {
            back.step(1.0 / 60.0)
            let down = back.pose(of: bob2)!.rotation * Vec3(0, -1, 0)
            lowest = min(lowest, atan2f(down.x, -down.y))
        }
        #expect(lowest > -22 * .pi / 180 && lowest < -15 * .pi / 180, "\(lowest * 180 / .pi)")
    }

    @Test func ballSwingConeAndTwistLimits() {
        let (physics, bob, _) = pendulum(.ball, limits: .degrees(swing: 25, min: -10, max: 10), kick: Vec3(4, 0, 3))
        var widest: Float = 0
        for _ in 0..<120 {
            physics.step(1.0 / 60.0)
            let down = physics.pose(of: bob)!.rotation * Vec3(0, -1, 0)
            widest = max(widest, acosf(min(max(-down.y, -1), 1)))
        }
        #expect(widest < 27 * .pi / 180 && widest > 15 * .pi / 180, "\(widest * 180 / .pi)")
        let (twisting, bob2, _) = pendulum(.ball, limits: .degrees(swing: 25, min: -10, max: 10), kick: Vec3(0, 6, 0))
        var twist: Float = 0
        for _ in 0..<120 {
            twisting.step(1.0 / 60.0)
            let side = twisting.pose(of: bob2)!.rotation * Vec3(1, 0, 0)
            twist = max(twist, abs(atan2f(-side.z, side.x)))
        }
        #expect(twist < 12 * .pi / 180 && twist > 5 * .pi / 180, "\(twist * 180 / .pi)")
        // Without limits it spins freely.
        let (free, bob3, _) = pendulum(.ball, limits: nil, kick: Vec3(0, 6, 0))
        for _ in 0..<20 { free.step(1.0 / 60.0) }
        let side = free.pose(of: bob3)!.rotation * Vec3(1, 0, 0)
        #expect(abs(atan2f(-side.z, side.x)) > 1)
    }

    @Test func jointComponentPassesItsLimits() {
        let world = World()
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        let a = world.spawn(Transform(position: Vec3(0, 2, 0)), Collider(.sphere(radius: 0.1)))
        let b = world.spawn(Transform(position: Vec3(0, 1.5, 0)), Collider(.sphere(radius: 0.1)), RigidBody(),
                            Joint(.hinge, connectedTo: a, anchor: Vec3(0, 0.5, 0), axis: Vec3(0, 0, 1), limits: .degrees(min: -10, max: 10)))
        world.update(dt: 1.0 / 60.0)
        let id = try! #require(physics.joint(for: b))
        #expect(physics.joints[Int(id.index)].limits == .degrees(min: -10, max: 10))
        // Scenes keep them.
        let copy = World()
        _ = try! copy.load(try! world.save())
        var found: Joint?
        copy.query(Joint.self) { _, j in found = j }
        #expect(found?.limits == .degrees(min: -10, max: 10))
    }

    /// A humanoid skeleton with a ragdoll, standing on a floor.
    private func ragdollRig() -> (IKTestsRig, PhysicsWorld) {
        let rig = IKTestsRig(at: Vec3(0, 0.02, 0))
        let physics = PhysicsWorld()
        rig.world.addPhysics(physics)
        _ = rig.world.spawn(Transform(position: Vec3(0, -0.5, 0)), Name("RagdollTests.Floor"), Collider(.box(Vec3(5, 0.5, 5))))
        let character = CharacterRig(template: .humanoid)
        rig.world.add(character.ragdoll(CharacterRagdoll()), to: rig.root)
        return (rig, physics)
    }

    @Test func ragdollBuildsBodiesAndJointsThatFollowTheAnimation() {
        let (rig, physics) = ragdollRig()
        rig.step()
        let bodies = physics.ragdollBodies(of: rig.root)
        #expect(bodies.count == 11)
        #expect(physics.ragdollJoints(of: rig.root).count == 10)
        #expect(bodies.allSatisfy { physics.motion(of: $0) == .kinematic })
        let mass = physics.ragdollLayout(of: rig.root).reduce(Float(0)) { $0 + $1.mass }
        #expect(abs(mass - 70) < 0.5, "\(mass)")
        // Hit boxes: a ray finds the head bone.
        let head = rig.position("head")
        let hit = physics.raycast(Ray(origin: head + Vec3(0, 0.1, 2), direction: Vec3(0, 0, -1)))
        #expect(hit?.entity == rig.bones["head"])
        #expect(physics.ragdollBody(of: rig.root, bone: "hand.L", in: rig.world) == physics.ragdollBody(of: rig.root, bone: "lowerArm.L", in: rig.world))
        // Moving the character moves the hit boxes.
        rig.world.modify(Transform.self, for: rig.root) { $0.position.x = 2 }
        rig.step(2)
        #expect(abs(physics.pose(of: bodies[0])!.position.x - rig.position("hips").x) < 1e-3)
        // The ECS sync leaves them alone, and the transforms stay animated.
        #expect(physics.bodyCount == 12)
        #expect(rig.world.get(Ragdoll.self, for: rig.root)?.blend == 0)
        // Dynamic, the bodies weigh what the layout says.
        rig.world.modify(Ragdoll.self, for: rig.root) { $0.goLimp() }
        rig.step()
        let dynamicMass = bodies.reduce(Float(0)) { $0 + physics.mass(of: $1) }
        #expect(abs(dynamicMass - 70) < 0.5, "\(dynamicMass)")
    }

    @Test func goingLimpFallsAndGettingUpBlendsBack() {
        let (rig, physics) = ragdollRig()
        rig.step()
        let standingHead = rig.position("head")
        rig.world.modify(Ragdoll.self, for: rig.root) {
            $0.goLimp()
            $0.applyImpulse(bone: "chest", impulse: Vec3(0, 0, -30))
        }
        rig.step(150)
        let ragdoll = rig.world.get(Ragdoll.self, for: rig.root)!
        #expect(ragdoll.blend == 1 && ragdoll.impulses.isEmpty)
        let head = rig.position("head")
        #expect(head.y < 0.5, "the character lies on the floor: head at \(head)")
        #expect(head.y > 0, "and not through it")
        let bodies = physics.ragdollBodies(of: rig.root)
        #expect(bodies.allSatisfy { physics.motion(of: $0) == .dynamic })
        // The bones follow the bodies: the root bone is at its body.
        #expect(length(rig.position("hips") - physics.pose(of: bodies[0])!.position) < 0.02)
        // Limbs stay within their limits: no knee bends forward.
        let thigh = rig.position("lowerLeg.L") - rig.position("upperLeg.L")
        let shin = rig.position("foot.L") - rig.position("lowerLeg.L")
        #expect(length(thigh) > 0.3 && length(shin) > 0.3)
        // Getting up: the root moves under the pelvis and the pose blends back to the animation.
        let pelvis = physics.pose(of: bodies[0])!.position
        rig.world.modify(Ragdoll.self, for: rig.root) { $0.getUp() }
        rig.step()
        let root = Transform(matrix: rig.world.worldMatrix(of: rig.root)).position
        #expect(abs(root.x - pelvis.x) < 1e-3 && abs(root.z - pelvis.z) < 1e-3)
        #expect(abs(root.y) < 0.01, "on the floor")
        #expect(rig.world.get(Ragdoll.self, for: rig.root)!.blend > 0)
        rig.step(60)
        #expect(rig.world.get(Ragdoll.self, for: rig.root)!.blend == 0)
        #expect(abs(rig.position("head").y - standingHead.y) < 0.03, "standing again")
        #expect(bodies.allSatisfy { physics.motion(of: $0) == .kinematic })
    }

    @Test func hitReactionShowsPartOfThePhysicsThenRecovers() {
        let (rig, physics) = ragdollRig()
        rig.step()
        let head = rig.position("head")
        rig.world.modify(Ragdoll.self, for: rig.root) { $0.hit(bone: "head", impulse: Vec3(0, 0, -25), weight: 0.8, duration: 0.3) }
        rig.step(6)
        let ragdoll = rig.world.get(Ragdoll.self, for: rig.root)!
        #expect(ragdoll.mode == .partial && abs(ragdoll.blend - 0.8) < 1e-4)
        #expect(rig.position("head").z < head.z - 0.01, "the head is knocked back")
        rig.step(60)
        let after = rig.world.get(Ragdoll.self, for: rig.root)!
        #expect(after.mode == .animated && after.blend == 0)
        #expect(length(rig.position("head") - head) < 1e-3)
        #expect(physics.ragdollBodies(of: rig.root).allSatisfy { physics.motion(of: $0) == .kinematic })
    }

    @Test func ragdollIsRebuiltWhenItsBonesChangeAndRemovedWithTheComponent() {
        let (rig, physics) = ragdollRig()
        rig.step()
        #expect(physics.bodyCount == 12)
        rig.world.modify(Ragdoll.self, for: rig.root) { $0.bones.removeLast(4) }
        rig.step()
        #expect(physics.bodyCount == 8)
        rig.world.remove(Ragdoll.self, from: rig.root)
        rig.step()
        #expect(physics.bodyCount == 1)
        #expect(physics.jointCount == 0)
    }

    @Test func ragdollBodiesNeverCollideWithEachOther() {
        let (rig, physics) = ragdollRig()
        rig.world.modify(Ragdoll.self, for: rig.root) { $0.goLimp() }
        rig.step(3)
        let bodies = Set(physics.ragdollBodies(of: rig.root).map(\.index))
        for contact in physics.contacts {
            #expect(!(bodies.contains(UInt32(contact.a)) && bodies.contains(UInt32(contact.b))))
        }
    }

    @Test func characterRagdollBonesForEveryTemplate() throws {
        for template in CharacterTemplate.allCases {
            let rig = CharacterRig(template: template)
            let bones = rig.ragdollBones()
            #expect(bones.count >= 3, "\(template)")
            let names = Set(rig.bones.map(\.name))
            for bone in bones {
                #expect(names.contains(bone.bone), "\(template) \(bone.bone)")
                if let end = bone.end { #expect(names.contains(end), "\(template) \(end)") }
                #expect(bone.radius > 0.005, "\(template) \(bone.bone)")
            }
            #expect(rig.ragdollMass > 0)
        }
        // Overrides change single values.
        let rig = CharacterRig(template: .humanoid)
        let changed = rig.ragdollBones(CharacterRagdoll(bones: [CharacterRagdollBone(bone: "lowerLeg.L", radius: 0.2, maxAngle: 90)]))
        let knee = try #require(changed.first { $0.bone == "lowerLeg.L" })
        #expect(knee.radius == 0.2 && knee.maxAngle == 90 && knee.joint == .hinge)
        // Problems for unknown bones and bad ranges.
        var build = CharacterBuild()
        build.ragdoll = CharacterRagdoll(bones: [CharacterRagdollBone(bone: "tail"), CharacterRagdollBone(bone: "head", minAngle: 20, maxAngle: 10)])
        #expect(build.problems.contains { $0.contains("'tail' has no body") })
        #expect(build.problems.contains { $0.contains("minAngle 20.0 is above maxAngle 10.0") })
    }

    @Test func ragdollComponentDecodesWithEveryKeyOptional() throws {
        let ragdoll = try AssetJSON.decoder().decode(Ragdoll.self, from: Data(#"{"bones": [{"bone": "hips"}], "mode": "full"}"#.utf8))
        #expect(ragdoll.bones[0].radius == 0.08 && ragdoll.bones[0].joint == .ball)
        #expect(ragdoll.mode == .full && ragdoll.blend == 1 && ragdoll.mass == 70)
        let again = try AssetJSON.decoder().decode(Ragdoll.self, from: try AssetJSON.encode(ragdoll))
        #expect(again == ragdoll)
    }
}
