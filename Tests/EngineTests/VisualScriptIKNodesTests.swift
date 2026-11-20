import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineRendering

// Visual script nodes for IK and ragdolls (Sources/Engine/VisualScript/VisualScriptIKNodes.swift).

@MainActor
@Suite struct VisualScriptIKNodesTests {
    private func node(_ id: String, _ type: String, inputs: [String: JSONValue] = [:]) -> VisualScriptNode {
        VisualScriptNode(id: id, type: type, inputs: inputs)
    }

    private func vec(_ v: Vec3) -> JSONValue { .array([.double(Double(v.x)), .double(Double(v.y)), .double(Double(v.z))]) }

    @Test func nodesAreRegisteredAndValidate() {
        VisualScriptNodes.registerEngineNodes()
        for id in ["ik.setTarget", "ik.setWeight", "ragdoll.enable", "ragdoll.applyImpulse", "ragdoll.state"] {
            #expect(VisualScriptNodes.definition(id) != nil, "\(id)")
        }
        let graph = VisualScriptGraph(nodes: [node("s", "event.start"), node("t", "ik.setTarget", inputs: ["node": .string("Look")])],
                                      links: [VisualScriptLink(from: "s.out", to: "t.in")])
        let issues = VisualScriptValidator.validate(graph).filter { $0.severity != .info }
        #expect(issues.isEmpty, "\(issues)")
    }

    @Test func setTargetWeightRagdollAndImpulse() {
        let rig = IKTestsRig(ik: [AnimationIKNode(name: "Hand.L", type: .twoBoneIK, bones: ["upperArm.L", "lowerArm.L", "hand.L"])])
        let physics = PhysicsWorld()
        rig.world.addPhysics(physics)
        rig.world.add(CharacterRig(template: .humanoid).ragdoll(CharacterRagdoll()), to: rig.root)
        VisualScriptNodes.registerEngineNodes()
        let host = VisualScriptHost()
        var lines: [String] = []
        host.log = { lines.append($0) }
        let runtime = rig.world.addVisualScripts(host: host)
        let target = Vec3(0.45, 1.15, 0.35)
        runtime.graphs["VisualScriptIKNodesTests.g"] = VisualScriptGraph(
            nodes: [node("s", "event.start"),
                    node("t", "ik.setTarget", inputs: ["node": .string("Hand.L"), "target": vec(target)]),
                    node("w", "ik.setWeight", inputs: ["node": .string("Hand.L"), "weight": .double(0.5)]),
                    node("i", "ragdoll.applyImpulse", inputs: ["bone": .string("head"), "impulse": vec(Vec3(0, 0, -20)), "weight": .double(0.7)]),
                    node("bad", "ik.setWeight", inputs: ["node": .string("Nope")])],
            links: [VisualScriptLink(from: "s.out", to: "t.in"), VisualScriptLink(from: "t.out", to: "w.in"),
                    VisualScriptLink(from: "w.out", to: "i.in"), VisualScriptLink(from: "i.out", to: "bad.in")])
        rig.world.add(VisualScript(graph: "VisualScriptIKNodesTests.g"), to: rig.root)
        rig.step(2)
        let animator = rig.world.get(Animator.self, for: rig.root)!
        #expect(animator.ikNode("Hand.L")?.target == target)
        #expect(animator.ikNode("Hand.L")?.weight == 0.5)
        let ragdoll = rig.world.get(Ragdoll.self, for: rig.root)!
        #expect(ragdoll.mode == .partial && ragdoll.weight == 0.7)
        #expect(lines.contains { $0.contains("no IK node 'Nope'") }, "\(lines)")

        // Enable: limp; disable: back up.
        runtime.graphs["VisualScriptIKNodesTests.limp"] = VisualScriptGraph(
            nodes: [node("s", "event.start"), node("e", "ragdoll.enable", inputs: ["enabled": .bool(true)])],
            links: [VisualScriptLink(from: "s.out", to: "e.in")])
        rig.world.add(VisualScript(graph: "VisualScriptIKNodesTests.limp"), to: rig.root)
        rig.step(2)
        #expect(rig.world.get(Ragdoll.self, for: rig.root)?.mode == .full)
    }
}
