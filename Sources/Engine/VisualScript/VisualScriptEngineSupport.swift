import Foundation
import EngineAssets
import EngineCore
import EngineScene

// Helpers shared by the engine's builder nodes (animation graphs, dialogue, timelines, behavior
// trees, UI layouts): finding the component a node drives, and raising builder events on the
// right graphs.

extension VisualScriptNodeContext {
    /// `entity` input (unconnected: this entity), or the first descendant (breadth first) that has a `C`.
    func entity<C: Component>(_ name: String = "entity", with type: C.Type) throws -> Entity {
        let root = try liveEntity(name)
        guard let found = VisualScriptEngineSupport.find(C.self, from: root, in: world) else {
            throw VisualScriptError("\(world.get(Name.self, for: root)?.value ?? "the entity") has no \(C.componentName)")
        }
        return found
    }
}

@MainActor
enum VisualScriptEngineSupport {
    /// The first entity at or under `root` (breadth first) with a `C`.
    static func find<C: Component>(_ type: C.Type, from root: Entity, in world: World) -> Entity? {
        var queue = [root]
        var index = 0
        while index < queue.count {
            let e = queue[index]
            index += 1
            if world.has(C.self, for: e) { return e }
            queue += world.children(of: e)
        }
        return nil
    }

    /// The setting on builder event nodes that makes them hear every entity's events (default:
    /// only those of the script's own entity or its descendants).
    static let anyEntityKey = VisualScriptConfigKey("anyEntity", .bool, doc: "Hear every entity's events (default: only this entity's and its children's)")

    /// Raises `event` for something that happened on `source`: on the graph of `source` or its
    /// nearest ancestor running one, and on every graph whose matching node has `anyEntity`.
    /// `matches` filters the event nodes further (by their config).
    static func raise(_ event: String, from source: Entity, outputs: [String: VisualScriptValue], in runtime: VisualScriptRuntime,
                      where matches: @escaping (VisualScriptNode) -> Bool = { _ in true }) {
        var owner: Entity?
        var current: Entity? = source
        while let e = current {
            if runtime.instances[e] != nil { owner = e; break }
            current = runtime.world.parent(of: e)
        }
        for instance in runtime.instances.values.sorted(by: { $0.entity.index < $1.entity.index }) {
            guard instance.program.handles(event) else { continue }
            let mine = instance.entity == owner
            runtime.raise(event, on: instance, outputs: outputs) { node in
                (mine || node.source.config["anyEntity"] == .bool(true)) && matches(node.source)
            }
        }
    }

    /// Whether a node's `name` config is empty (any) or equals `name`.
    static func nameMatches(_ node: VisualScriptNode, _ name: String, key: String = "name") -> Bool {
        let wanted = node.configString(key) ?? ""
        return wanted.isEmpty || wanted == name
    }

    /// An event node made for a builder: `anyEntity` plus `config`, these outputs after `out`.
    static func event(_ id: String, _ title: String, _ doc: String, event: String, config: [VisualScriptConfigKey] = [],
                      outputs: [VisualScriptPin]) -> VisualScriptNodeDefinition {
        VisualScriptNodeDefinition(id: id, title: title, category: "Events", doc: doc, kind: .event, config: config + [anyEntityKey],
                                   event: event, outputs: outputs, run: nil)
    }

    static func action(_ id: String, _ title: String, _ category: String, _ doc: String, _ inputs: [VisualScriptPin] = [],
                       _ outputs: [VisualScriptPin] = [], _ run: @escaping @MainActor (VisualScriptNodeContext) throws -> VisualScriptFlow) -> VisualScriptNodeDefinition {
        VisualScriptNodeDefinition(id: id, title: title, category: category, doc: doc, kind: .action, inputs: inputs, outputs: outputs, run: run)
    }

    static func pure(_ id: String, _ title: String, _ category: String, _ doc: String, _ inputs: [VisualScriptPin] = [],
                     _ outputs: [VisualScriptPin] = [], _ run: @escaping @MainActor (VisualScriptNodeContext) throws -> Void) -> VisualScriptNodeDefinition {
        VisualScriptNodeDefinition(id: id, title: title, category: category, doc: doc, kind: .pure, inputs: inputs, outputs: outputs) { c in
            try run(c)
            return .stop
        }
    }

    static let entityPin = VisualScriptPin("entity", .entity, doc: "Unconnected: this entity (or the first child that has the component)")
}

/// State an event source keeps between frames (last seen states, queued events).
@MainActor
final class VisualScriptSourceState<Value> {
    var value: Value
    init(_ value: Value) { self.value = value }
}
