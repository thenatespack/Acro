#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineScene

// Visual script nodes for dialogue (`.dialogue` on a `DialoguePlayer`, run by the dialogue
// system): start, advance, choose and stop conversations, read and set dialogue variables,
// read what is on screen, and events for `event` nodes, lines, choices and the end.

@MainActor
enum VisualScriptDialogueNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.dialogue") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func director(_ c: VisualScriptNodeContext) throws -> DialogueDirector {
        guard let director = c.world.dialogues else { throw VisualScriptError("no dialogue system is running") }
        return director
    }

    /// `entity`'s runner (its own DialoguePlayer or a child's).
    static func runner(_ c: VisualScriptNodeContext) throws -> (Entity, DialogueRunner) {
        let director = try director(c)
        let target = try c.entity(with: DialoguePlayer.self)
        guard let runner = director.runner(for: target) else { throw VisualScriptError("the DialoguePlayer's dialogue can't be read") }
        return (target, runner)
    }

    static func value(_ v: VisualScriptValue) -> DialogueValue {
        switch v {
        case .bool(let b): .bool(b)
        case .int(let i): .number(Double(i))
        case .float(let f): .number(f)
        default: .text(v.asString)
        }
    }

    static func value(_ v: DialogueValue) -> VisualScriptValue {
        switch v {
        case .bool(let b): .bool(b)
        case .number(let d): d.rounded() == d && abs(d) < 1e15 ? .int(Int(d)) : .float(d)
        case .text(let s): .string(s)
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity with the DialoguePlayer (unconnected: this entity or a child)")
        let name = VisualScriptPin("name", .string, required: true, doc: "The variable's name")
        return [
            S.action("dialogue.start", "Start Dialogue", "Dialogue",
                     "Starts `entity`'s conversation (its DialoguePlayer) at `node` (empty: the component's start node or the dialogue's start) and shows it.",
                     [entity, VisualScriptPin("node", .string)], [VisualScriptPin("active", .bool)]) { c in
                let director = try director(c)
                let target = try c.entity(with: DialoguePlayer.self)
                let node = try c.string("node")
                guard let runner = director.start(target, at: node.isEmpty ? nil : node) else {
                    throw VisualScriptError("the DialoguePlayer's dialogue can't be read")
                }
                c.set("active", .bool(runner.isActive))
                return .next
            },
            S.action("dialogue.advance", "Advance Dialogue", "Dialogue", "Moves `entity`'s conversation past the line on screen (as the player clicking).",
                     [entity]) { c in
                try runner(c).1.advance()
                return .next
            },
            S.action("dialogue.choose", "Choose Dialogue Option", "Dialogue",
                     "Picks option `option` (from 0, as listed on screen) of `entity`'s conversation; `chosen` is false when no such option is shown.",
                     [entity, VisualScriptPin("option", .int)], [VisualScriptPin("chosen", .bool)]) { c in
                let runner = try runner(c).1
                c.set("chosen", .bool(runner.choose(try c.int("option"))))
                return .next
            },
            S.action("dialogue.stop", "Stop Dialogue", "Dialogue", "Ends `entity`'s conversation (unconnected and without a DialoguePlayer: the one on screen).",
                     [entity]) { c in
                let director = try director(c)
                if let target = VisualScriptEngineSupport.find(DialoguePlayer.self, from: try c.liveEntity("entity"), in: c.world) {
                    director.stop(target)
                } else if !c.isConnected("entity") {
                    director.stop()
                } else {
                    throw VisualScriptError("the entity has no DialoguePlayer")
                }
                return .next
            },
            S.pure("dialogue.getVariable", "Get Dialogue Variable", "Dialogue",
                   "A dialogue variable: from `entity`'s conversation when connected, else the value shared by every dialogue (set by any of them).",
                   [name, VisualScriptPin("entity", .entity, doc: "Unconnected: the shared value")],
                   [VisualScriptPin("value", .any), VisualScriptPin("found", .bool)]) { c in
                let director = try director(c)
                let key = try c.string("name")
                let found: DialogueValue? = c.isConnected("entity") ? try runner(c).1.variable(key)
                    : director.variable(key) ?? director.activeRunner?.variable(key)
                c.set("value", found.map(value) ?? .none)
                c.set("found", .bool(found != nil))
            },
            S.action("dialogue.setVariable", "Set Dialogue Variable", "Dialogue",
                     "Sets a dialogue variable (numbers, bools, text): in `entity`'s conversation when connected, else in every dialogue and the shared store.",
                     [name, VisualScriptPin("value", .any), VisualScriptPin("entity", .entity, doc: "Unconnected: every dialogue")]) { c in
                let key = try c.string("name"), new = value(try c.input("value"))
                if c.isConnected("entity") { try runner(c).1.setVariable(key, new) } else { try director(c).setVariable(key, new) }
                return .next
            },
            S.pure("dialogue.state", "Dialogue State", "Dialogue",
                   "What `entity`'s conversation shows: whether it is going, the speaker and line (or the choice prompt) and the options' text.",
                   [entity], [VisualScriptPin("active", .bool), VisualScriptPin("speaker", .string), VisualScriptPin("text", .string),
                              VisualScriptPin("options", .array), VisualScriptPin("node", .string)]) { c in
                let runner = try runner(c).1
                var speaker = "", text = "", options: [VisualScriptValue] = []
                switch runner.state {
                case .line(let line): speaker = line.speaker?.displayName ?? line.speakerID; text = line.text
                case .choices(let choices):
                    speaker = choices.speaker?.displayName ?? choices.speakerID
                    text = choices.prompt
                    options = choices.options.map { .string($0.text) }
                case .idle, .finished: break
                }
                c.set("active", .bool(runner.isActive))
                c.set("speaker", .string(speaker))
                c.set("text", .string(text))
                c.set("options", .array(options))
                c.set("node", .string(runner.currentNode ?? ""))
            },
            S.event("event.dialogueEvent", "On Dialogue Event",
                    "Runs when this entity's conversation reaches an `event` node (config name; empty: any). `args` holds the node's arguments.",
                    event: "dialogueEvent", config: [VisualScriptConfigKey("name", doc: "The event's name (empty: any)")],
                    outputs: [VisualScriptPin("name", .string), VisualScriptPin("args", .map), VisualScriptPin("entity", .entity)]),
            S.event("event.dialogueLine", "On Dialogue Line", "Runs when this entity's conversation shows a line.",
                    event: "dialogueLine",
                    outputs: [VisualScriptPin("speaker", .string), VisualScriptPin("text", .string), VisualScriptPin("node", .string), VisualScriptPin("entity", .entity)]),
            S.event("event.dialogueChoices", "On Dialogue Choices", "Runs when this entity's conversation shows options (`options`: their text).",
                    event: "dialogueChoices",
                    outputs: [VisualScriptPin("prompt", .string), VisualScriptPin("options", .array), VisualScriptPin("node", .string), VisualScriptPin("entity", .entity)]),
            S.event("event.dialogueEnded", "On Dialogue Ended", "Runs when this entity's conversation finishes or is stopped.",
                    event: "dialogueEnded", outputs: [VisualScriptPin("entity", .entity)]),
        ]
    }

    /// What the dialogue event source remembers between frames.
    final class Watch {
        weak var director: DialogueDirector?
        var listener: DialogueListener?
        var queued: [(Entity, DialogueEvent)] = []
        var states: [Entity: DialogueRunner.State] = [:]
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        let watch = Watch()
        runtime.addEventSource("engine.dialogue") { runtime in
            guard let director = runtime.world.dialogues else { return }
            if watch.director !== director {
                if let old = watch.director, let listener = watch.listener { old.removeListener(listener) }
                watch.director = director
                watch.queued.removeAll()
                watch.states.removeAll()
                watch.listener = director.onEvent { [weak watch] entity, event in watch?.queued.append((entity, event)) }
            }
            guard !runtime.instances.isEmpty else {
                watch.queued.removeAll()
                return
            }
            let events = watch.queued
            watch.queued.removeAll()
            for (entity, event) in events {
                VisualScriptEngineSupport.raise("dialogueEvent", from: entity,
                                                outputs: ["name": .string(event.name), "args": .map(event.args.mapValues(VisualScriptValue.fromJSON)),
                                                          "entity": .entity(entity)],
                                                in: runtime) { VisualScriptEngineSupport.nameMatches($0, event.name) }
            }
            var players: [Entity] = []
            runtime.world.query(DialoguePlayer.self) { entity, _ in players.append(entity) }
            var seen = Set<Entity>()
            for entity in players {
                seen.insert(entity)
                guard let runner = director.runner(for: entity) else { continue }
                let state = runner.state
                let before = watch.states[entity]
                guard before != state else { continue }
                watch.states[entity] = state
                switch state {
                case .line(let line):
                    VisualScriptEngineSupport.raise("dialogueLine", from: entity,
                                                    outputs: ["speaker": .string(line.speaker?.displayName ?? line.speakerID), "text": .string(line.text),
                                                              "node": .string(line.node), "entity": .entity(entity)], in: runtime)
                case .choices(let choices):
                    VisualScriptEngineSupport.raise("dialogueChoices", from: entity,
                                                    outputs: ["prompt": .string(choices.prompt), "options": .array(choices.options.map { .string($0.text) }),
                                                              "node": .string(choices.node), "entity": .entity(entity)], in: runtime)
                case .finished, .idle:
                    if let before, before != .idle && before != .finished {
                        VisualScriptEngineSupport.raise("dialogueEnded", from: entity, outputs: ["entity": .entity(entity)], in: runtime)
                    }
                }
            }
            watch.states = watch.states.filter { seen.contains($0.key) }
        }
    }
}
