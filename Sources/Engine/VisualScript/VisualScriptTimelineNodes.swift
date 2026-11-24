#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene

// Visual script nodes for timelines (`.timeline` on a `TimelinePlayer`): play, pause, resume,
// stop, skip and seek, read the playhead, and events for event keys and the end.

@MainActor
enum VisualScriptTimelineNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.timeline") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity with the TimelinePlayer (unconnected: this entity or a child)")
        func control(_ id: String, _ title: String, _ doc: String, _ body: @escaping (inout TimelinePlayer) -> Void) -> VisualScriptNodeDefinition {
            S.action(id, title, "Timeline", doc, [entity]) { c in
                c.world.modify(TimelinePlayer.self, for: try c.entity(with: TimelinePlayer.self), body)
                return .next
            }
        }
        return [
            S.action("timeline.play", "Play Timeline", "Timeline",
                     "Plays `entity`'s TimelinePlayer (from the start when stopped or finished, or always with `restart`). With `timeline` "
                     + "(a .timeline file) it plays that one, adding a TimelinePlayer to the entity if it has none. Applies on the timeline system's next update.",
                     [VisualScriptPin("entity", .entity, doc: "Unconnected: this entity (or a child with a TimelinePlayer)"),
                      VisualScriptPin("timeline", .asset, doc: "Optional: the .timeline to play (asset:<id> or a path under Assets/)"),
                      VisualScriptPin("restart", .bool)]) { c in
                let file = try c.string("timeline").trimmingCharacters(in: .whitespaces)
                let restart = try c.bool("restart")
                let root = try c.liveEntity("entity")
                if let target = S.find(TimelinePlayer.self, from: root, in: c.world) {
                    c.world.modify(TimelinePlayer.self, for: target) { player in
                        let changed = !file.isEmpty && player.timeline != file
                        if changed { player.timeline = file }
                        player.play(from: restart || changed ? 0 : nil)
                    }
                } else {
                    guard !file.isEmpty else { throw VisualScriptError("the entity has no TimelinePlayer (give `timeline` to add one)") }
                    var player = TimelinePlayer(timeline: file, playOnStart: false)
                    player.play(from: 0)
                    c.world.add(player, to: root)
                }
                return .next
            },
            control("timeline.pause", "Pause Timeline", "Freezes `entity`'s timeline where it is (the scene stays posed).") { $0.pause() },
            control("timeline.resume", "Resume Timeline", "Carries on a paused timeline.") { $0.resume() },
            control("timeline.stop", "Stop Timeline", "Stops `entity`'s timeline, removing the sounds and effects it started.") { $0.stop() },
            control("timeline.skip", "Skip Timeline", "Jumps to the end, firing the event keys not reached yet (only for skippable timelines).") { $0.skip() },
            S.action("timeline.seek", "Seek Timeline", "Timeline", "Moves `entity`'s playhead to `time` seconds without firing the keys in between.",
                     [entity, VisualScriptPin("time", .float)]) { c in
                let time = max(try c.float("time"), 0)
                c.world.modify(TimelinePlayer.self, for: try c.entity(with: TimelinePlayer.self)) { $0.seek(to: time) }
                return .next
            },
            S.pure("timeline.state", "Timeline State", "Timeline", "`entity`'s timeline: seconds in, its state (stopped, playing, paused, finished) and whether it plays.",
                   [entity], [VisualScriptPin("time", .float), VisualScriptPin("state", .string), VisualScriptPin("playing", .bool)]) { c in
                let player = c.world.get(TimelinePlayer.self, for: try c.entity(with: TimelinePlayer.self))
                c.set("time", .float(Double(player?.time ?? 0)))
                c.set("state", .string(player?.state.rawValue ?? ""))
                c.set("playing", .bool(player?.isPlaying ?? false))
            },
            S.event("event.timelineEvent", "On Timeline Event",
                    "Runs when this entity's timeline passes an event key (config name; empty: any), with the key's value, time and track.",
                    event: "timelineEvent", config: [VisualScriptConfigKey("name", doc: "The event key's name (empty: any)")],
                    outputs: [VisualScriptPin("name", .string), VisualScriptPin("value", .string), VisualScriptPin("time", .float),
                              VisualScriptPin("track", .string), VisualScriptPin("entity", .entity)]),
            S.event("event.timelineFinished", "On Timeline Finished", "Runs when this entity's timeline reaches its end (or is skipped there).",
                    event: "timelineFinished", outputs: [VisualScriptPin("entity", .entity)]),
        ]
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        runtime.addEventSource("engine.timeline") { runtime in
            let world = runtime.world
            guard !runtime.instances.isEmpty, world.count(of: TimelinePlayer.self) > 0 else { return }
            var fired: [(Entity, [TimelineFiredEvent], Bool)] = []
            world.query(TimelinePlayer.self) { entity, player in
                if !player.events.isEmpty || player.didFinish { fired.append((entity, player.events, player.didFinish)) }
            }
            for (entity, events, finished) in fired {
                for event in events {
                    VisualScriptEngineSupport.raise("timelineEvent", from: entity,
                                                    outputs: ["name": .string(event.name), "value": .string(event.value), "time": .float(Double(event.time)),
                                                              "track": .string(event.track), "entity": .entity(entity)],
                                                    in: runtime) { VisualScriptEngineSupport.nameMatches($0, event.name) }
                }
                if finished { VisualScriptEngineSupport.raise("timelineFinished", from: entity, outputs: ["entity": .entity(entity)], in: runtime) }
            }
        }
    }
}
