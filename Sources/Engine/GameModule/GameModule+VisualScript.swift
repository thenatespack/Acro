import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EnginePhysics
import EngineRendering
import EngineScene
import EngineUI

// Visual scripts and game code together: game modules add nodes, Swift sends events to graphs
// and listens for theirs, and hosts install the VM with the game's input, log and scene switching.

extension GameModule {
    /// Who owns the nodes this module registers (`VisualScriptNodes.unregister(owner:)` when it unloads).
    public var scriptNodeOwner: String { "gameModule@\(UInt(bitPattern: ObjectIdentifier(self).hashValue))" }

    /// Adds a node to visual scripts, listed with the built-in ones (search, `vscript.nodes`).
    /// An action node (the default) gets `in` / `out` exec pins and runs `run` when the flow
    /// reaches it; a `pure` node runs whenever an input it feeds is read. Read inputs and set
    /// outputs through the context:
    ///
    /// ```swift
    /// game.scriptNode("mygame.heal", title: "Heal", inputs: [VisualScriptPin("amount", .float, default: .float(10))],
    ///                 outputs: [VisualScriptPin("health", .float)]) { node in
    ///     let amount = try node.float("amount")
    ///     let health = node.world.modify(Health.self, for: node.entity) { $0.points += amount; return $0.points } ?? 0
    ///     node.set("health", .float(Double(health)))
    /// }
    /// ```
    ///
    /// Throw `VisualScriptError("…")` to stop the flow with a message in the console. The node
    /// is removed when the module unloads; ids should start with the game's name.
    public func scriptNode(_ id: String, title: String? = nil, category: String = "Game", doc: String = "",
                           inputs: [VisualScriptPin] = [], outputs: [VisualScriptPin] = [], pure: Bool = false,
                           _ run: @escaping @MainActor (VisualScriptNodeContext) throws -> Void) {
        let definition = VisualScriptNodeDefinition(
            id: id, title: title ?? id, category: category, doc: doc, kind: pure ? .pure : .action, inputs: inputs, outputs: outputs) { context in
            try run(context)
            return pure ? .stop : .next
        }
        definition.owner = scriptNodeOwner
        VisualScriptNodes.register(definition)
    }

    /// Adds an event node (`event.custom` with a fixed name, as its own node type): graphs
    /// using it run when Swift calls `world.sendScriptEvent(name, …)` (or a graph sends `name`).
    public func scriptEvent(_ name: String, title: String? = nil, doc: String = "") {
        let definition = VisualScriptNodeDefinition(
            id: "event.\(name)", title: title ?? "On \(name)", category: "Game", doc: doc.isEmpty ? "Runs when the event '\(name)' is sent." : doc,
            kind: .event, event: "custom",
            signature: { _ in VisualScriptSignature(outputs: [.exec("out"), VisualScriptPin("sender", .entity), VisualScriptPin("value", .any)]) },
            run: nil)
        definition.owner = scriptNodeOwner
        VisualScriptNodes.register(definition)
        VisualScriptNodes.customEventNames[definition.id] = name
    }
}

extension World {
    /// Runs this world's `VisualScript` components with a game's services: `context`'s input,
    /// log and scene switching, `assets` for graphs and the assets they use, and the play
    /// session's physics. Also wires up the engine's builder events (sprite clips, animation graphs,
    /// dialogue, timelines, behavior trees, UI buttons). `uiLayer` is where `ui.show` puts layouts. Remove with `removeVisualScripts(_:)`.
    @MainActor @discardableResult
    public func addVisualScripts(context: GameContext, assets: @escaping () -> AssetDatabase?,
                                 physics: @escaping () -> PhysicsWorld? = { nil },
                                 physics2D: @escaping () -> PhysicsWorld2D? = { nil },
                                 uiLayer: Widget? = nil) -> VisualScriptRuntime {
        VisualScriptEngineNodes.register()
        let host = VisualScriptHost()
        host.input = context.input
        host.log = context.log
        host.assets = assets
        host.physics = physics
        host.physics2D = physics2D
        host.loadScene = { [weak context] path in context?.loadScene(path) }
        host.reloadScene = { [weak context] in context?.reloadScene() }
        if let uiLayer { host.services[VisualScriptUI.layerService] = uiLayer }
        let runtime = addVisualScripts(host: host)
        VisualScriptEngineNodes.addEventSources(to: runtime)
        return runtime
    }

    /// Sends the custom event `name` to `target`'s graph (nil: every graph) of the visual scripts
    /// running in this world. Returns false when none are running.
    @MainActor @discardableResult
    public func sendScriptEvent(_ name: String, to target: Entity? = nil, value: VisualScriptValue = .none) -> Bool {
        guard let runtime = VisualScriptRuntime.runtime(for: self) else { return false }
        runtime.send(name, to: target, value: value)
        return true
    }
}

extension VisualScriptNodes {
    /// Registers the nodes of engine features above the VM's module (sprites, animation graphs,
    /// dialogue, timelines, behavior trees, UI layouts), so tools and validation know them
    /// before anything plays. `addVisualScripts(context:assets:)` calls it too. Idempotent.
    public static func registerEngineNodes() { VisualScriptEngineNodes.register() }
}

/// Nodes for engine features above the VM's module, registered when a host installs the VM
/// with `addVisualScripts(context:assets:)` (or `VisualScriptNodes.registerEngineNodes()`).
/// Each builder's nodes live in their own file (Sources/Engine/VisualScript/).
@MainActor
enum VisualScriptEngineNodes {
    static func register() {
        VisualScriptAnimationNodes.register()
        VisualScriptDialogueNodes.register()
        VisualScriptTimelineNodes.register()
        VisualScriptBehaviorNodes.register()
        VisualScriptUINodes.register()
        VisualScriptBuilderLinkNodes.register()
        VisualScriptNodes.addProvider("engine.sprites") {
            VisualScriptNodes.register(VisualScriptNodeDefinition(
                id: "event.spriteEvent", title: "On Sprite Event", category: "Events",
                doc: "Runs when this entity's sprite clip reaches a clip event (config name; empty: any). `name` is the event's name.",
                kind: .event, config: [VisualScriptConfigKey("name")], event: "spriteEvent",
                outputs: [VisualScriptPin("name", .string)], run: nil))
            VisualScriptNodes.register(VisualScriptNodeDefinition(
                id: "event.spriteFinished", title: "On Sprite Clip Finished", category: "Events",
                doc: "Runs when this entity's `once` sprite clip ends. `clip` is its name.",
                kind: .event, event: "spriteFinished", outputs: [VisualScriptPin("clip", .string)], run: nil))
            VisualScriptNodes.register(VisualScriptNodeDefinition(
                id: "sprite.play", title: "Play Sprite Clip", category: "Animation",
                doc: "Plays the clip named `clip` on `entity`'s SpriteAnimator (`restart` starts it over when it is already playing).",
                kind: .action,
                inputs: [VisualScriptPin("entity", .entity), VisualScriptPin("clip", .string, required: true), VisualScriptPin("restart", .bool)]) { c in
                let target = try c.liveEntity("entity")
                let clip = try c.string("clip"), restart = try c.bool("restart")
                guard c.world.modify(SpriteAnimator.self, for: target, { $0.play(clip, restart: restart) }) != nil else {
                    throw VisualScriptError("the entity has no SpriteAnimator")
                }
                return .next
            })
        }
    }

    static func addEventSources(to runtime: VisualScriptRuntime) {
        VisualScriptAnimationNodes.addEventSource(to: runtime)
        VisualScriptDialogueNodes.addEventSource(to: runtime)
        VisualScriptTimelineNodes.addEventSource(to: runtime)
        VisualScriptBehaviorNodes.addEventSource(to: runtime)
        VisualScriptUINodes.addEventSource(to: runtime)
        VisualScriptBuilderLinkNodes.addEventSource(to: runtime)
        runtime.addEventSource("engine.sprites") { runtime in
            guard runtime.world.count(of: SpriteAnimator.self) > 0 else { return }
            var fired: [(Entity, [String], String?)] = []
            runtime.world.query(SpriteAnimator.self) { entity, animator in
                guard runtime.instances[entity] != nil, !animator.events.isEmpty || animator.justFinished else { return }
                fired.append((entity, animator.events, animator.justFinished ? animator.current : nil))
            }
            for (entity, events, finished) in fired {
                guard let instance = runtime.instances[entity] else { continue }
                for name in events {
                    runtime.raise("spriteEvent", on: instance, outputs: ["name": .string(name)]) { node in
                        let wanted = node.source.configString("name") ?? ""
                        return wanted.isEmpty || wanted == name
                    }
                }
                if let finished { runtime.raise("spriteFinished", on: instance, outputs: ["clip": .string(finished)]) }
            }
        }
    }
}
