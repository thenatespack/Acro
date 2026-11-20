import Foundation
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// Visual script nodes for inverse kinematics (`Animator.ik`) and ragdolls (`Ragdoll`): set an
// IK node's target or weight, make a character go limp or get up, push a bone.

@MainActor
enum VisualScriptIKNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.ik") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = S.entityPin
        let node = VisualScriptPin("node", .string, required: true, doc: "The IK node's name (Animator.ik, e.g. Look, Feet, Hand.R)")
        let bone = VisualScriptPin("bone", .string, required: true, doc: "The bone's name (its body, or the nearest ragdoll body above it)")
        func editAnimator(_ c: VisualScriptNodeContext, _ name: String, _ body: (inout Animator) -> Bool) throws {
            let target = try c.entity(with: Animator.self)
            var found = false
            c.world.modify(Animator.self, for: target) { found = body(&$0) }
            guard found else {
                let names = c.world.get(Animator.self, for: target)?.ik?.map(\.name) ?? []
                throw VisualScriptError("the Animator has no IK node '\(name)' (nodes: \(names.isEmpty ? "none" : names.joined(separator: ", ")))")
            }
        }
        func editRagdoll(_ c: VisualScriptNodeContext, _ body: (inout Ragdoll) -> Void) throws {
            let target = try c.entity(with: Ragdoll.self)
            c.world.modify(Ragdoll.self, for: target, body)
        }
        return [
            S.action("ik.setTarget", "Set IK Target", "Animation",
                     "Sets the world-space point the IK node `node` of `entity`'s Animator reaches or looks at (connect an entity's position to follow it).",
                     [entity, node, VisualScriptPin("target", .vec3)]) { c in
                let name = try c.string("node"), target = try c.vec3("target")
                try editAnimator(c, name) { $0.setIKTarget(name, target) }
                return .next
            },
            S.action("ik.setWeight", "Set IK Weight", "Animation",
                     "Sets how much the IK node `node` of `entity`'s Animator applies (0: the animation alone, 1: fully).",
                     [entity, node, VisualScriptPin("weight", .float, default: .float(1))]) { c in
                let name = try c.string("node"), weight = try c.float("weight")
                try editAnimator(c, name) { $0.setIKWeight(name, weight) }
                return .next
            },
            S.action("ragdoll.enable", "Enable Ragdoll", "Physics",
                     "Turns `entity`'s Ragdoll on (the character goes limp: physics takes over) or off (it gets up: the pose blends back to the animation).",
                     [entity, VisualScriptPin("enabled", .bool, default: .bool(true))]) { c in
                let enabled = try c.bool("enabled")
                try editRagdoll(c) { enabled ? $0.goLimp() : $0.getUp() }
                return .next
            },
            S.action("ragdoll.applyImpulse", "Apply Impulse to Bone", "Physics",
                     "Pushes `bone` of `entity`'s Ragdoll with `impulse` (N·s, world space) at `point` (unconnected: the body's center). With `react`, an animated character flinches: physics shows `weight` of the pose for `duration` seconds.",
                     [entity, bone, VisualScriptPin("impulse", .vec3), VisualScriptPin("point", .vec3),
                      VisualScriptPin("react", .bool, default: .bool(true)), VisualScriptPin("weight", .float, default: .float(0.6)),
                      VisualScriptPin("duration", .float, default: .float(0.6))]) { c in
                let name = try c.string("bone"), impulse = try c.vec3("impulse")
                let point: Vec3? = c.isConnected("point") ? try c.vec3("point") : nil
                let react = try c.bool("react"), weight = try c.float("weight"), duration = try c.float("duration")
                try editRagdoll(c) {
                    if react {
                        $0.hit(bone: name, impulse: impulse, at: point, weight: weight, duration: duration)
                    } else {
                        $0.applyImpulse(bone: name, impulse: impulse, at: point)
                    }
                }
                return .next
            },
            S.pure("ragdoll.state", "Ragdoll State", "Physics",
                   "`entity`'s Ragdoll: its mode (animated, partial, full) and how much of the physics pose shows (0...1).",
                   [entity], [VisualScriptPin("mode", .string), VisualScriptPin("blend", .float), VisualScriptPin("limp", .bool)]) { c in
                let ragdoll = try c.world.get(Ragdoll.self, for: c.entity(with: Ragdoll.self))
                c.set("mode", .string(ragdoll?.mode.rawValue ?? ""))
                c.set("blend", .float(Double(ragdoll?.blend ?? 0)))
                c.set("limp", .bool(ragdoll?.mode == .full))
            },
        ]
    }
}
