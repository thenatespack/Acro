import Foundation
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene

// Visual script nodes for behavior trees (`.btree` on a `BehaviorTreeRunner`): read and set the
// tree's blackboard, start and stop the tree, and an event for what trees do (attack hits).

@MainActor
enum VisualScriptBehaviorNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.behavior") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func value(_ v: VisualScriptValue) -> BehaviorValue {
        switch v {
        case .bool(let b): return .bool(b)
        case .int(let i): return .number(Double(i))
        case .float(let f): return .number(f)
        case .vec2(let p): return .vector(Vec3(p.x, 0, p.y))
        case .vec3(let p): return .vector(p)
        case .entity(let e): return .entity(e)
        case .array(let items) where !items.isEmpty && items.allSatisfy({ if case .vec3 = $0 { true } else { false } }):
            return .points(items.map(\.asVec3))
        default: return .text(v.asString)
        }
    }

    static func value(_ v: BehaviorValue) -> VisualScriptValue {
        switch v {
        case .number(let d): .float(d)
        case .bool(let b): .bool(b)
        case .text(let s): .string(s)
        case .vector(let p): .vec3(p)
        case .points(let list): .array(list.map { .vec3($0) })
        case .entity(let e): .entity(e)
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity running the tree (unconnected: this entity or a child)")
        let key = VisualScriptPin("key", .string, required: true, doc: "The blackboard key")
        return [
            S.pure("behavior.getBlackboard", "Get Blackboard", "AI",
                   "The value at `key` on the blackboard of `entity`'s behavior tree (numbers, bools, text, vectors, entities, point lists).",
                   [entity, key], [VisualScriptPin("value", .any), VisualScriptPin("found", .bool)]) { c in
                let target = try c.entity(with: BehaviorTreeRunner.self)
                let found = c.world.blackboardValue(try c.string("key"), for: target)
                c.set("value", found.map(value) ?? .none)
                c.set("found", .bool(found != nil))
            },
            S.action("behavior.setBlackboard", "Set Blackboard", "AI",
                     "Sets `key` on the blackboard of `entity`'s behavior tree to `value`. Leaves read it on their next tick.",
                     [entity, key, VisualScriptPin("value", .any)]) { c in
                let target = try c.entity(with: BehaviorTreeRunner.self)
                let name = try c.string("key")
                c.world.setBlackboardValue(value(try c.input("value")), forKey: name, of: target)
                return .next
            },
            S.action("behavior.clearBlackboard", "Remove Blackboard Key", "AI", "Removes `key` from the blackboard of `entity`'s behavior tree.",
                     [entity, key]) { c in
                c.world.setBlackboardValue(nil, forKey: try c.string("key"), of: try c.entity(with: BehaviorTreeRunner.self))
                return .next
            },
            S.action("behavior.setRunning", "Run Behavior Tree", "AI", "Starts (`running` true) or stops `entity`'s behavior tree.",
                     [entity, VisualScriptPin("running", .bool, default: .bool(true))]) { c in
                let running = try c.bool("running")
                c.world.modify(BehaviorTreeRunner.self, for: try c.entity(with: BehaviorTreeRunner.self)) { $0.isRunning = running }
                return .next
            },
            S.pure("behavior.status", "Behavior Tree Status", "AI", "What `entity`'s tree root returned last tick (success, failure, running; empty before it ran) and the running node path.",
                   [entity], [VisualScriptPin("status", .string), VisualScriptPin("running", .array)]) { c in
                let state = c.world.get(BehaviorTreeState.self, for: try c.entity(with: BehaviorTreeRunner.self))
                c.set("status", .string(state?.rootStatus?.rawValue ?? ""))
                c.set("running", .array((state?.runningPath ?? []).map { .string($0) }))
            },
            S.event("event.behaviorEvent", "On Behavior Event",
                    "Runs when this entity's behavior tree raises an event (config name, e.g. attack; empty: any): the node, its target and amount (damage).",
                    event: "behaviorEvent", config: [VisualScriptConfigKey("name", doc: "The event's name (empty: any)")],
                    outputs: [VisualScriptPin("name", .string), VisualScriptPin("node", .string), VisualScriptPin("target", .entity),
                              VisualScriptPin("amount", .float), VisualScriptPin("entity", .entity)]),
        ]
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        runtime.addEventSource("engine.behavior") { runtime in
            let world = runtime.world
            guard !runtime.instances.isEmpty, world.count(of: BehaviorTreeState.self) > 0 else { return }
            var fired: [(Entity, [BehaviorEvent])] = []
            world.query(BehaviorTreeState.self) { entity, state in if !state.events.isEmpty { fired.append((entity, state.events)) } }
            for (entity, events) in fired {
                for event in events {
                    VisualScriptEngineSupport.raise("behaviorEvent", from: entity,
                                                    outputs: ["name": .string(event.name), "node": .string(event.node), "target": .entity(event.target ?? .invalid),
                                                              "amount": .float(event.amount), "entity": .entity(entity)],
                                                    in: runtime) { VisualScriptEngineSupport.nameMatches($0, event.name) }
                }
            }
        }
    }
}
