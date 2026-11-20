import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// Inverse kinematics: the solvers (two-bone, FABRIK), IK nodes on an Animator's pose (two-bone,
// aim, chain, foot placement against physics), weights driven by parameters, `.animgraph` ik.

/// A character skeleton as entities (`CharacterRig` bones under a root) with a still Animator.
@MainActor
struct IKTestsRig {
    let world = World()
    let library = AnimationLibrary()
    let root: Entity
    var bones: [String: Entity] = [:]

    init(template: CharacterTemplate = .humanoid, at position: Vec3 = .zero, ik: [AnimationIKNode]? = nil) {
        root = world.spawn(Transform(position: position), Name("IKTests.Hero"))
        let rig = CharacterRig(template: template)
        var entities: [Entity] = []
        for bone in rig.bones {
            let e = world.spawn(Transform(position: bone.offset), Name(bone.name))
            _ = world.setParent(e, to: bone.parent.map { entities[$0] } ?? root)
            entities.append(e)
            bones[bone.name] = e
        }
        let clip = library.register(AnimationClip(name: "still", channels: [], duration: 1), key: "IKTests.still")
        let targets = world.animationRig(of: root)
        var animator = Animator(targets: targets.targets, restPose: targets.restPose, clip: clip)
        animator.ik = ik
        world.add(animator, to: root)
        world.addAnimationSystem(library)
    }

    func position(_ bone: String) -> Vec3 { Transform(matrix: world.worldMatrix(of: bones[bone]!)).position }
    func rotation(_ bone: String) -> Quat { Transform(matrix: world.worldMatrix(of: bones[bone]!)).rotation }

    func step(_ frames: Int = 1) {
        for _ in 0..<frames { world.update(dt: 1.0 / 60.0) }
    }
}

@MainActor
@Suite struct IKTests {
    @Test func twoBoneReachesAndKeepsLengths() {
        let a = Vec3(0, 1, 0), b = Vec3(0, 0.5, 0), c = Vec3(0, 0, 0)
        let target = Vec3(0.3, 0.4, 0.2)
        let solved = IKSolver.twoBone(root: a, middle: b, end: c, target: target, pole: Vec3(0, 0, 1))
        #expect(length(solved.end - target) < 1e-3)
        #expect(abs(length(solved.middle - a) - 0.5) < 1e-3)
        #expect(abs(length(solved.end - solved.middle) - 0.5) < 1e-3)
        // The knee bends toward the pole (+z) relative to the reach line.
        let dir = normalize(target - a)
        let mid = solved.middle - a
        #expect(dot(mid - dir * dot(mid, dir), Vec3(0, 0, 1)) > 0)
    }

    @Test func twoBoneOutOfReachStretchesTowardTheTarget() {
        let solved = IKSolver.twoBone(root: .zero, middle: Vec3(0, -0.5, 0.01), end: Vec3(0, -1, 0), target: Vec3(3, 0, 0))
        #expect(abs(length(solved.end) - 1) < 1e-3)
        #expect(dot(normalize(solved.end), Vec3(1, 0, 0)) > 0.999)
    }

    @Test func fabrikReachesTargetWithBoneLengths() {
        let joints = (0...4).map { Vec3(0, Float($0) * 0.25, 0) }
        let target = Vec3(0.5, 0.6, 0.1)
        let solved = IKSolver.fabrik(joints, target: target, iterations: 20, tolerance: 1e-4)
        #expect(length(solved.last! - target) < 1e-3)
        #expect(solved[0] == joints[0])
        for k in 0..<4 { #expect(abs(length(solved[k + 1] - solved[k]) - 0.25) < 1e-3) }
        // Out of reach: straight at it.
        let far = IKSolver.fabrik(joints, target: Vec3(5, 0, 0))
        #expect(abs(length(far.last!) - 1) < 1e-3)
    }

    @Test func twoBoneNodeMovesTheHandToTheTarget() {
        let target = Vec3(0.45, 1.15, 0.35)
        var rig = IKTestsRig(ik: [AnimationIKNode(name: "Hand.L", type: .twoBoneIK, bones: ["upperArm.L", "lowerArm.L", "hand.L"],
                                                  target: target, pole: Vec3(0, 0, -1))])
        let shoulder = rig.position("upperArm.L")
        let restUpper = length(rig.position("lowerArm.L") - shoulder)
        rig.step()
        #expect(length(rig.position("hand.L") - target) < 0.01)
        #expect(abs(length(rig.position("lowerArm.L") - shoulder) - restUpper) < 1e-3, "bone lengths are kept")
        #expect(length(rig.position("upperArm.L") - shoulder) < 1e-4, "the root stays")
        // Weight 0 by parameter: back to the rest pose.
        rig.world.modify(Animator.self, for: rig.root) {
            $0.ik![0].weightParameter = "IKTests.reach"
            $0.setFloat("IKTests.reach", 0)
        }
        rig.step()
        #expect(length(rig.position("hand.L") - target) > 0.2)
        // Half weight: half way along.
        rig.world.modify(Animator.self, for: rig.root) { $0.setFloat("IKTests.reach", 0.5) }
        rig.step()
        rig.world.modify(Animator.self, for: rig.root) { $0.setFloat("IKTests.reach", 0) }
        rig.step()
        let rest = rig.position("hand.L")
        rig.world.modify(Animator.self, for: rig.root) { $0.setFloat("IKTests.reach", 0.5) }
        rig.step()
        #expect(length(rig.position("hand.L") - (rest + target) / 2) < 0.02)
        _ = rig
    }

    @Test func setIKTargetFollowsAMovingPointAndEntity() {
        let rig = IKTestsRig(ik: [AnimationIKNode(name: "Hand.R", type: .twoBoneIK, bones: ["upperArm.R", "lowerArm.R", "hand.R"])])
        rig.step()
        let rest = rig.position("hand.R")
        rig.world.modify(Animator.self, for: rig.root) { $0.setIKTarget("Hand.R", Vec3(-0.4, 1.2, 0.4)) }
        rig.step()
        #expect(length(rig.position("hand.R") - Vec3(-0.4, 1.2, 0.4)) < 0.01)
        #expect(length(rig.position("hand.R") - rest) > 0.1)
        let ball = rig.world.spawn(Transform(position: Vec3(-0.3, 1.1, 0.4)), Name("IKTests.Ball"))
        rig.world.modify(Animator.self, for: rig.root) { $0.ik![0].targetEntity = "IKTests.Ball" }
        rig.step()
        #expect(length(rig.position("hand.R") - Vec3(-0.3, 1.1, 0.4)) < 0.01)
        rig.world.modify(Transform.self, for: ball) { $0.position = Vec3(-0.2, 1.3, 0.4) }
        rig.step()
        #expect(length(rig.position("hand.R") - Vec3(-0.2, 1.3, 0.4)) < 0.01)
    }

    @Test func aimTurnsTheHeadTowardTheTarget() {
        let target = Vec3(2, 1.6, 2)
        let rig = IKTestsRig(at: Vec3(1, 0, -1), ik: [AnimationIKNode(name: "Look", type: .aim, bones: ["spine", "chest", "neck", "head"],
                                                                         target: target, maxAngle: 60)])
        rig.step()
        let forward = rig.rotation("head") * Vec3(0, 0, 1)
        let wanted = normalize(target - rig.position("head"))
        #expect(dot(normalize(forward), wanted) > 0.99)
        // The turn is shared: the spine turned too, but less than the head's total.
        let spine = rig.rotation("spine") * Vec3(0, 0, 1)
        #expect(dot(normalize(spine), Vec3(0, 0, 1)) < 0.999)
    }

    @Test func chainIKBendsATail() {
        let rig = IKTestsRig(template: .quadruped, ik: [AnimationIKNode(name: "Tail", type: .chainIK, bones: ["tail", "tailTip"],
                                                                        target: nil)])
        rig.step()
        let tipBefore = rig.position("tailTip")
        let hips = rig.position("hips"), tail = rig.position("tail")
        let goal = tail + normalize(Vec3(0.6, 0.5, -0.2)) * length(tipBefore - tail)
        rig.world.modify(Animator.self, for: rig.root) { $0.setIKTarget("Tail", goal) }
        rig.step()
        #expect(length(rig.position("tailTip") - goal) < 0.02)
        #expect(length(rig.position("hips") - hips) < 1e-4)
    }

    @Test func footPlacementStandsOnAStep() {
        let rig = IKTestsRig(ik: [AnimationIKNode.humanoidFeet()])
        let physics = PhysicsWorld()
        rig.world.addPhysics(physics)
        // Floor at y = 0 under the right foot, a 0.2 m pit under the left one.
        let leftX = rig.position("foot.L").x
        _ = rig.world.spawn(Transform(position: Vec3(-0.5, -0.5, 0)), Collider(.box(Vec3(0.5, 0.5, 1))))
        _ = rig.world.spawn(Transform(position: Vec3(leftX, -0.7, 0)), Collider(.box(Vec3(0.06, 0.5, 1))))
        let restAnkle = rig.position("foot.R").y
        let restHips = rig.position("hips").y
        rig.step(3)
        #expect(abs(rig.position("foot.L").y - (restAnkle - 0.2)) < 0.01, "the left foot reaches down into the pit")
        #expect(abs(rig.position("foot.R").y - restAnkle) < 0.01, "the right foot stays on the floor")
        #expect(abs(rig.position("hips").y - (restHips - 0.2)) < 0.01, "the pelvis drops")
        // A slope turns the foot.
        _ = rig
    }

    @Test func footPlacementAlignsToSlopesAndLocksPlantedFeet() {
        let rig = IKTestsRig(ik: [AnimationIKNode.humanoidFeet()])
        let physics = PhysicsWorld()
        rig.world.addPhysics(physics)
        let tilt = Quat(angle: 0.2, axis: Vec3(1, 0, 0))
        _ = rig.world.spawn(Transform(position: Vec3(0, -0.5, 0), rotation: tilt), Collider(.box(Vec3(2, 0.5, 2))))
        rig.step(2)
        let up = rig.rotation("foot.L") * Vec3(0, 1, 0)
        #expect(dot(normalize(up), tilt * Vec3(0, 1, 0)) > 0.99, "the foot lies on the slope")
        // Moving the character a little keeps planted feet where they were.
        let planted = rig.position("foot.L")
        rig.world.modify(Transform.self, for: rig.root) { $0.position.x += 0.05 }
        rig.step()
        #expect(abs(rig.position("foot.L").x - planted.x) < 0.01)
    }

    @Test func noPhysicsLeavesFootPlacementAlone() {
        let rig = IKTestsRig(ik: [AnimationIKNode.humanoidFeet()])
        let before = rig.position("foot.L")
        rig.step()
        #expect(length(rig.position("foot.L") - before) < 1e-5)
    }

    @Test func graphIKNodesDecodeCheckAndReachTheAnimator() throws {
        let json = """
        {"parameters": [{"name": "look", "type": "float", "default": 1}, {"name": "on", "type": "bool"}],
         "states": [{"name": "Idle", "clip": "IKTests.still"}],
         "ik": [{"name": "Look", "type": "aim", "bones": ["chest", "head"], "weightParameter": "look"},
                {"name": "Hand", "type": "twoBoneIK", "bones": ["a", "b"], "weightParameter": "on"},
                {"type": "footPlacement"},
                {"name": "Look", "type": "chainIK", "bones": ["tail"], "weightParameter": "nope"}]}
        """
        let graph = try AssetJSON.decoder().decode(AnimationGraph.self, from: Data(json.utf8))
        #expect(graph.ik.count == 4)
        #expect(graph.ik[2].name == "footPlacement" && graph.ik[2].rayHeight == 0.6)
        let problems = AnimationGraphCheck.problems(graph)
        #expect(problems.contains { $0.contains("two IK nodes are named 'Look'") })
        #expect(problems.contains { $0.contains("'Hand' (twoBoneIK) needs 3 bones") })
        #expect(problems.contains { $0.contains("weightParameter 'on' isn't a float") })
        #expect(problems.contains { $0.contains("weightParameter 'nope' doesn't exist") })
        #expect(problems.contains { $0.contains("has no legs") })
        #expect(problems.contains { $0.contains("chainIK) needs at least 2 bones") })
        // Round trip keeps the nodes; files without ik don't gain the key.
        let again = try AssetJSON.decoder().decode(AnimationGraph.self, from: try graph.fileData())
        #expect(again.ik == graph.ik)
        let plain = String(decoding: try AnimationGraph.starter().fileData(), as: UTF8.self)
        #expect(!plain.contains("\"ik\""))
        // Applying the graph replaces the animator's nodes and keeps run-time targets.
        var animator = Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: []))
        animator.ik = [AnimationIKNode(name: "Look", type: .aim, bones: ["head"], target: Vec3(1, 2, 3))]
        animator.apply(graph)
        #expect(animator.ik?.count == 4)
        #expect(animator.ikNode("Look")?.target == Vec3(1, 2, 3))
        #expect(animator.effectiveWeight(animator.ik![0]) == 1)
    }

    @Test func characterIKNodesNameRealBones() {
        for template in CharacterTemplate.allCases {
            let rig = CharacterRig(template: template)
            let names = Set(rig.bones.map(\.name))
            for node in rig.ikNodes(CharacterIK(footPlacement: true, lookAt: true, handIK: true)) {
                #expect(node.problems(bones: names).isEmpty, "\(template): \(node.problems(bones: names))")
            }
        }
    }
}
