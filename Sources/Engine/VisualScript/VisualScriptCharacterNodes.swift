#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// Visual script nodes for the character controller's version 2 moves (crouch, ledges, mantling,
// climbing; CharacterControllerMoves.swift) and physics materials (PhysicsMaterial.swift): set
// the inputs, read the state and the hand points for IK, ask what is under a point.

@MainActor
enum VisualScriptCharacterNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.character") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = S.entityPin
        func edit(_ c: VisualScriptNodeContext, _ body: (inout CharacterController) -> Void) throws {
            let target = try c.entity(with: CharacterController.self)
            c.world.modify(CharacterController.self, for: target, body)
        }
        return [
            S.action("character.crouch", "Crouch", "Physics",
                     "Makes `entity`'s CharacterController crouch (a `crouchHeight` capsule) or stand up again; it stays crouched until there is room above.",
                     [entity, VisualScriptPin("crouch", .bool, default: .bool(true))]) { c in
                let crouch = try c.bool("crouch")
                try edit(c) { $0.crouch = crouch }
                return .next
            },
            S.action("character.grabLedge", "Grab Ledge", "Physics",
                     "Makes `entity`'s CharacterController grab a ledge within reach on the next step (in the direction it moves, else the nearest). Read `hanging` from Character State.",
                     [entity]) { c in
                try edit(c) { $0.grabLedge = true }
                return .next
            },
            S.action("character.mantle", "Mantle", "Physics",
                     "Makes `entity`'s CharacterController pull up onto the ledge it hangs from, or onto a low wall it walks toward (between step height and its height).",
                     [entity]) { c in
                try edit(c) { $0.mantle = true }
                return .next
            },
            S.action("character.drop", "Let Go", "Physics",
                     "Makes `entity`'s CharacterController let go of the ledge it hangs from or the wall it climbs.",
                     [entity]) { c in
                try edit(c) { $0.drop = true }
                return .next
            },
            S.pure("character.state", "Character State", "Physics",
                   "`entity`'s CharacterController: its mode (walking, hanging, mantling, climbing), whether it is grounded or crouching and can stand up, the ledge point and wall normal, the hand points (IK targets, e.g. for Set IK Target) and the physics material under its feet.",
                   [entity],
                   [VisualScriptPin("mode", .string), VisualScriptPin("grounded", .bool), VisualScriptPin("crouching", .bool),
                    VisualScriptPin("canStand", .bool), VisualScriptPin("hanging", .bool), VisualScriptPin("climbing", .bool),
                    VisualScriptPin("ledgePoint", .vec3), VisualScriptPin("wallNormal", .vec3),
                    VisualScriptPin("leftHand", .vec3), VisualScriptPin("rightHand", .vec3), VisualScriptPin("ground", .string)]) { c in
                let target = try c.entity(with: CharacterController.self)
                let controller = c.world.get(CharacterController.self, for: target) ?? CharacterController()
                let feet = c.world.get(Transform.self, for: target)?.position ?? .zero
                let physics = c.host.physics()
                c.set("mode", .string(controller.mode.rawValue))
                c.set("grounded", .bool(controller.isGrounded))
                c.set("crouching", .bool(controller.isCrouching))
                c.set("canStand", .bool(physics?.canStand(controller, at: feet, body: physics?.body(for: target)) ?? !controller.isCrouching))
                c.set("hanging", .bool(controller.mode == .hanging))
                c.set("climbing", .bool(controller.mode == .climbing))
                c.set("ledgePoint", .vec3(controller.ledgePoint))
                c.set("wallNormal", .vec3(controller.ledgeNormal))
                let hands = controller.handTargets
                c.set("leftHand", .vec3(hands?.left ?? .zero))
                c.set("rightHand", .vec3(hands?.right ?? .zero))
                var ground = ""
                if let physics, controller.isGrounded {
                    ground = controller.groundBody.map { physics.surfaceMaterialName(of: $0, at: feet) } ?? ""
                }
                c.set("ground", .string(ground))
            },
            S.action("physics.materialAt", "Material Under Point", "Physics",
                     "The physics material under `point` (a ray down up to `distance`): its name (a built-in such as grass or ice, or a .physmat path), friction and bounce, and the entity there.",
                     [VisualScriptPin("point", .vec3), VisualScriptPin("distance", .float, default: .float(2))],
                     [VisualScriptPin("hit", .bool), VisualScriptPin("material", .string), VisualScriptPin("friction", .float),
                      VisualScriptPin("bounce", .float), VisualScriptPin("climbable", .bool), VisualScriptPin("entity", .entity)]) { c in
                guard let physics = c.host.physics() else { throw VisualScriptError("no 3D physics in this scene (add a collider)") }
                let own = physics.body(for: c.entity).map { [$0] } ?? []
                let probe = physics.materialUnder(try c.vec3("point"), maxDistance: try c.float("distance"), filter: QueryFilter(excluding: own))
                c.set("hit", .bool(probe != nil))
                c.set("material", .string(probe?.name ?? ""))
                c.set("friction", .float(Double(probe?.material.friction ?? 0)))
                c.set("bounce", .float(Double(probe?.material.bounce ?? 0)))
                c.set("climbable", .bool(probe?.material.climbable ?? false))
                c.set("entity", .entity(probe?.hit.entity ?? .invalid))
                return .next
            },
        ]
    }
}
