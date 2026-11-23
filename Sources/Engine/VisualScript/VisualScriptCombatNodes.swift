import Foundation
import EngineAssets
import EngineCore
import EngineScene

// Visual script nodes for combat and interaction (Gameplay/): apply damage and heal, read
// health, hit stop and camera shake, use and enable interactables, and the events On Hit, On Hit
// Dealt, On Death and On Interact.

@MainActor
enum VisualScriptCombatNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.combat") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func hitOutputs() -> [VisualScriptPin] {
        [VisualScriptPin("attacker", .entity), VisualScriptPin("victim", .entity), VisualScriptPin("damage", .float),
         VisualScriptPin("type", .string), VisualScriptPin("point", .vec3), VisualScriptPin("normal", .vec3),
         VisualScriptPin("bone", .string), VisualScriptPin("region", .string), VisualScriptPin("killed", .bool),
         VisualScriptPin("health", .float)]
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = S.entityPin
        let typeKey = VisualScriptConfigKey("type", doc: "Only hits of this damage type (empty: any)")
        return [
            S.event("event.hit", "On Hit", "Runs when this entity (or a child) takes a hit: `attacker`, `victim`, `damage` dealt, its `type`, the world `point` and `normal` (out of the victim), the hurtbox's `bone` and `region`, whether it `killed` and the `health` left.",
                    event: "hit", config: [typeKey], outputs: hitOutputs()),
            S.event("event.hitDealt", "On Hit Dealt", "Runs when this entity's hitbox (or Apply Damage from it) hits something; outputs as On Hit.",
                    event: "hitDealt", config: [typeKey], outputs: hitOutputs()),
            S.event("event.death", "On Death", "Runs when this entity's Health reaches 0: `attacker`, `victim` and the killing blow's `type`.",
                    event: "death", outputs: [VisualScriptPin("attacker", .entity), VisualScriptPin("victim", .entity), VisualScriptPin("type", .string)]),
            S.event("event.interact", "On Interact", "Runs when an interactor uses this entity's Interactable: who (`interactor`), the `verb` shown and what it did (`result`: opened, closed, locked, unlocked, on, off, looted, picked up, used).",
                    event: "interact",
                    outputs: [VisualScriptPin("interactor", .entity), VisualScriptPin("target", .entity), VisualScriptPin("verb", .string),
                              VisualScriptPin("result", .string)]),
            S.action("combat.applyDamage", "Apply Damage", "Combat",
                     "Damages `entity` (or its nearest ancestor with a Health) by `amount` of damage `type`, times `multiplier` and its resistance; `attacker` (unconnected: none) is reported with the hit and its team is spared. Runs the hit's effects (flash, hit stop, shake, ragdoll) and On Hit. `applied` is the damage dealt (0 when it was dead, invulnerable or on the attacker's team).",
                     [entity, VisualScriptPin("amount", .float, default: .float(10)), VisualScriptPin("type", .string, default: .string("physical")),
                      VisualScriptPin("attacker", .entity), VisualScriptPin("point", .vec3), VisualScriptPin("bone", .string),
                      VisualScriptPin("knockback", .float, default: .float(3)), VisualScriptPin("multiplier", .float, default: .float(1))],
                     [VisualScriptPin("applied", .float), VisualScriptPin("killed", .bool)]) { c in
                let target = try c.liveEntity("entity")
                let attacker: Entity? = c.isConnected("attacker") ? try c.liveEntity("attacker") : nil
                let point: Vec3? = c.isConnected("point") ? try c.vec3("point") : nil
                let event = c.world.applyDamage(try c.float("amount"), to: target, type: try c.string("type"), from: attacker, point: point,
                                                bone: try c.string("bone"), multiplier: try c.float("multiplier"), knockback: try c.float("knockback"))
                c.set("applied", .float(Double(event?.damage ?? 0)))
                c.set("killed", .bool(event?.killed ?? false))
                return .next
            },
            S.action("combat.heal", "Heal", "Combat", "Heals `entity` (or its nearest ancestor with a Health) by `amount`, up to its max (not the dead).",
                     [entity, VisualScriptPin("amount", .float, default: .float(10))], [VisualScriptPin("health", .float)]) { c in
                guard let health = c.world.heal(try c.float("amount"), try c.liveEntity("entity")) else { throw VisualScriptError("the entity has no Health") }
                c.set("health", .float(Double(health)))
                return .next
            },
            S.pure("combat.health", "Get Health", "Combat", "`entity`'s Health (or its nearest ancestor's): current, max, current / max and whether it is dead.",
                   [entity], [VisualScriptPin("current", .float), VisualScriptPin("max", .float), VisualScriptPin("fraction", .float), VisualScriptPin("dead", .bool)]) { c in
                let target = try c.liveEntity("entity")
                let health = c.world.damageable(target).flatMap { c.world.get(Health.self, for: $0) }
                c.set("current", .float(Double(health?.current ?? 0)))
                c.set("max", .float(Double(health?.max ?? 0)))
                c.set("fraction", .float(Double(health?.fraction ?? 0)))
                c.set("dead", .bool(health?.dead ?? false))
            },
            S.action("combat.hitStop", "Hit Stop", "Combat", "Freezes game time (dt times `scale`) for `seconds` of real time: the frame of impact lingers.",
                     [VisualScriptPin("seconds", .float, default: .float(0.08)), VisualScriptPin("scale", .float, default: .float(0))]) { c in
                c.world.hitStop(Double(try c.float("seconds")), scale: Double(try c.float("scale")))
                return .next
            },
            S.action("combat.shake", "Camera Shake", "Combat", "Shakes the active camera: adds `amount` (0...1) of trauma, which decays over about a second.",
                     [VisualScriptPin("amount", .float, default: .float(0.4))]) { c in
                guard let feel = c.world.gameplay?.feel else { throw VisualScriptError("no gameplay systems are running (play mode adds them)") }
                feel.shake(try c.float("amount"))
                return .next
            },
            S.action("interaction.setEnabled", "Set Interactable Enabled", "Interaction",
                     "Turns `entity`'s Interactable on or off (off: it can't be focused or used).",
                     [entity, VisualScriptPin("enabled", .bool, default: .bool(true))]) { c in
                let target = try c.entity(with: Interactable.self)
                let enabled = try c.bool("enabled")
                c.world.modify(Interactable.self, for: target) { $0.enabled = enabled }
                return .next
            },
            S.action("interaction.use", "Interact", "Interaction",
                     "`interactor` uses `entity`'s Interactable as if it pressed the action: doors open or close, levers flip, containers hand over their items, pickups are taken. `result` says what happened (empty when it couldn't be used).",
                     [entity, VisualScriptPin("interactor", .entity)], [VisualScriptPin("result", .string)]) { c in
                let target = try c.entity(with: Interactable.self)
                let interactor = try c.liveEntity("interactor")
                guard let interaction = c.world.gameplay?.interaction else { throw VisualScriptError("no gameplay systems are running (play mode adds them)") }
                c.set("result", .string(interaction.interact(interactor, with: target, in: c.world)?.result ?? ""))
                return .next
            },
            S.pure("interaction.focus", "Get Interaction Focus", "Interaction",
                   "The interactable `entity` (an Interactor; unconnected: this entity) focuses now, its prompt (\"[E] Open\") and whether it has one.",
                   [entity], [VisualScriptPin("target", .entity), VisualScriptPin("prompt", .string), VisualScriptPin("has", .bool)]) { c in
                let interactor = try c.liveEntity("entity")
                let target = c.world.interactionFocus(of: interactor)
                c.set("target", .entity(target ?? .invalid))
                c.set("prompt", .string(c.world.gameplay?.interaction.prompts[interactor] ?? ""))
                c.set("has", .bool(target != nil))
            },
        ]
    }

    /// What the combat event source remembers between frames: the last hit and use it raised.
    final class Watch {
        var hits = 0
        var uses = 0
        weak var interaction: InteractionSystem?
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        let watch = Watch()
        // Events from before the scripts started aren't theirs.
        watch.hits = runtime.world.combat.lastSequence
        watch.interaction = runtime.world.gameplay?.interaction
        watch.uses = watch.interaction?.lastSequence ?? 0
        runtime.addEventSource("engine.combat") { runtime in
            let world = runtime.world
            let hits = Array(world.combat.events(after: watch.hits))
            watch.hits = world.combat.lastSequence
            if let interaction = world.gameplay?.interaction {
                if watch.interaction !== interaction {
                    watch.interaction = interaction
                    watch.uses = 0
                }
                let uses = Array(interaction.events(after: watch.uses))
                watch.uses = interaction.lastSequence
                for use in uses where !runtime.instances.isEmpty {
                    VisualScriptEngineSupport.raise("interact", from: use.target,
                                                    outputs: ["interactor": .entity(use.interactor), "target": .entity(use.target),
                                                              "verb": .string(use.verb), "result": .string(use.result)], in: runtime)
                }
            }
            guard !runtime.instances.isEmpty else { return }
            for hit in hits {
                let outputs: [String: VisualScriptValue] = [
                    "attacker": .entity(hit.attacker ?? .invalid), "victim": .entity(hit.victim), "damage": .float(Double(hit.damage)),
                    "type": .string(hit.type), "point": .vec3(hit.point), "normal": .vec3(hit.normal), "bone": .string(hit.bone),
                    "region": .string(hit.region), "killed": .bool(hit.killed), "health": .float(Double(hit.health)),
                ]
                let ofType: (VisualScriptNode) -> Bool = { VisualScriptEngineSupport.nameMatches($0, hit.type, key: "type") }
                if world.isAlive(hit.victim) {
                    VisualScriptEngineSupport.raise("hit", from: hit.victim, outputs: outputs, in: runtime, where: ofType)
                }
                if let attacker = hit.attacker, world.isAlive(attacker) {
                    VisualScriptEngineSupport.raise("hitDealt", from: attacker, outputs: outputs, in: runtime, where: ofType)
                }
                if hit.killed, world.isAlive(hit.victim) {
                    VisualScriptEngineSupport.raise("death", from: hit.victim,
                                                    outputs: ["attacker": .entity(hit.attacker ?? .invalid), "victim": .entity(hit.victim),
                                                              "type": .string(hit.type)], in: runtime)
                }
            }
        }
    }
}
