#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene

// Visual script nodes for animation graphs (`.animgraph` on an `Animator`): set parameters and
// triggers, play a state, read the state, and events for clip events and state changes.

@MainActor
enum VisualScriptAnimationNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.animation") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = S.entityPin
        let parameter = VisualScriptPin("parameter", .string, required: true, doc: "The Animator parameter's name")
        func edit(_ c: VisualScriptNodeContext, _ body: (inout Animator) -> Void) throws {
            let target = try c.entity(with: Animator.self)
            c.world.modify(Animator.self, for: target, body)
        }
        return [
            S.action("animator.setFloat", "Set Animator Float", "Animation",
                     "Sets the float parameter `parameter` of `entity`'s Animator (blend spaces and transitions read it).",
                     [entity, parameter, VisualScriptPin("value", .float)]) { c in
                let name = try c.string("parameter"), value = try c.float("value")
                try edit(c) { $0.setFloat(name, value) }
                return .next
            },
            S.action("animator.setBool", "Set Animator Bool", "Animation", "Sets the bool parameter `parameter` of `entity`'s Animator.",
                     [entity, parameter, VisualScriptPin("value", .bool)]) { c in
                let name = try c.string("parameter"), value = try c.bool("value")
                try edit(c) { $0.setBool(name, value) }
                return .next
            },
            S.action("animator.setTrigger", "Set Animator Trigger", "Animation",
                     "Sets the trigger `parameter` of `entity`'s Animator; the transition that tests it clears it.",
                     [entity, parameter]) { c in
                let name = try c.string("parameter")
                try edit(c) { $0.setTrigger(name) }
                return .next
            },
            S.action("animator.resetTrigger", "Reset Animator Trigger", "Animation", "Clears the trigger `parameter` of `entity`'s Animator.",
                     [entity, parameter]) { c in
                let name = try c.string("parameter")
                try edit(c) { $0.resetTrigger(name) }
                return .next
            },
            S.action("animator.play", "Play Animator State", "Animation",
                     "Crossfades `entity`'s Animator to the state `state` over `fade` seconds (0: cut).",
                     [entity, VisualScriptPin("state", .string, required: true), VisualScriptPin("fade", .float, default: .float(0.25))]) { c in
                let target = try c.entity(with: Animator.self)
                let state = try c.string("state"), fade = max(try c.float("fade"), 0)
                guard c.world.get(Animator.self, for: target)?.stateMachine.index(of: state) != nil else {
                    throw VisualScriptError("the Animator has no state '\(state)'")
                }
                c.world.modify(Animator.self, for: target) { $0.play(state, fade: fade) }
                return .next
            },
            S.action("animator.setSpeed", "Set Animator Speed", "Animation", "Sets `entity`'s Animator playback speed (1: normal, 0: frozen).",
                     [entity, VisualScriptPin("speed", .float, default: .float(1))]) { c in
                let speed = try c.float("speed")
                try edit(c) { $0.speed = speed }
                return .next
            },
            S.pure("animator.state", "Animator State", "Animation",
                   "`entity`'s Animator: the current state, how far through it (0...1 per loop) and whether it is crossfading.",
                   [entity], [VisualScriptPin("state", .string), VisualScriptPin("normalizedTime", .float), VisualScriptPin("inTransition", .bool)]) { c in
                let animator = try c.world.get(Animator.self, for: c.entity(with: Animator.self))
                c.set("state", .string(animator?.currentState ?? ""))
                c.set("normalizedTime", .float(Double(animator?.normalizedTime ?? 0)))
                c.set("inTransition", .bool(animator?.isInTransition ?? false))
            },
            S.pure("animator.getParameter", "Get Animator Parameter", "Animation",
                   "The value of `entity`'s Animator parameter `parameter` as a number and as a bool (triggers: whether set).",
                   [entity, parameter], [VisualScriptPin("value", .float), VisualScriptPin("on", .bool), VisualScriptPin("found", .bool)]) { c in
                let animator = try c.world.get(Animator.self, for: c.entity(with: Animator.self))
                let value = animator?.parameters[try c.string("parameter")]
                switch value {
                case .float(let f)?: c.set("value", .float(Double(f))); c.set("on", .bool(f != 0))
                case .bool(let b)?, .trigger(let b)?: c.set("value", .float(b ? 1 : 0)); c.set("on", .bool(b))
                case nil: c.set("value", .float(0)); c.set("on", .bool(false))
                }
                c.set("found", .bool(value != nil))
            },
            S.event("event.animationEvent", "On Animation Event",
                    "Runs when an Animator on this entity (or a child) passes a clip event (config name; empty: any). `state` is the state playing it.",
                    event: "animationEvent", config: [VisualScriptConfigKey("name", doc: "The clip event's name (empty: any)")],
                    outputs: [VisualScriptPin("name", .string), VisualScriptPin("state", .string), VisualScriptPin("entity", .entity)]),
            S.event("event.animationState", "On Animation State Entered",
                    "Runs when an Animator on this entity (or a child) moves to another state (config state; empty: any).",
                    event: "animationState", config: [VisualScriptConfigKey("state", doc: "The state's name (empty: any)")],
                    outputs: [VisualScriptPin("state", .string), VisualScriptPin("previous", .string), VisualScriptPin("entity", .entity)]),
        ]
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        let lastStates = VisualScriptSourceState<[Entity: String]>([:])
        runtime.addEventSource("engine.animation") { runtime in
            let world = runtime.world
            guard !runtime.instances.isEmpty, world.count(of: Animator.self) > 0 else {
                lastStates.value.removeAll()
                return
            }
            var fired: [(Entity, [FiredAnimationEvent], String?, String?)] = []
            var seen = Set<Entity>()
            world.query(Animator.self) { entity, animator in
                seen.insert(entity)
                let state = animator.currentState
                let previous = lastStates.value[entity]
                let changed = state != nil && previous != nil && state != previous
                if state != nil { lastStates.value[entity] = state }
                if !animator.events.isEmpty || changed { fired.append((entity, animator.events, changed ? state : nil, previous)) }
            }
            lastStates.value = lastStates.value.filter { seen.contains($0.key) }
            for (entity, events, entered, previous) in fired {
                for event in events {
                    VisualScriptEngineSupport.raise("animationEvent", from: entity,
                                                    outputs: ["name": .string(event.name), "state": .string(event.state), "entity": .entity(entity)],
                                                    in: runtime) { VisualScriptEngineSupport.nameMatches($0, event.name) }
                }
                if let entered {
                    VisualScriptEngineSupport.raise("animationState", from: entity,
                                                    outputs: ["state": .string(entered), "previous": .string(previous ?? ""), "entity": .entity(entity)],
                                                    in: runtime) { VisualScriptEngineSupport.nameMatches($0, entered, key: "state") }
                }
            }
        }
    }
}
