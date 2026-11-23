import Foundation
import EngineAssets
import EngineCore
import EngineRendering
import EngineScene
import EngineUI

// Visual script nodes that link graphs to more of the builders' runtime pieces:
// - path followers (`PathFollower` on a `.path`): play, pause, resume, stop, seek, read where it
//   is, and an event for the ends of the path;
// - navigation (`world.findPath`, `world.bakeNavigation`: the navmesh, else the grid);
// - the game UI layer (`world.gameUI`, which shows `UILayoutPlayer`s and `ui.show` layouts):
//   values every layout reads, hiding everything, and an event for any layout's widgets;
// - timelines: clearing a held fade (`holdFade`) and the conversations dialogue keys start;
// - which `.ui` layout shows a `DialoguePlayer`'s conversation (`DialoguePlayer.uiLayout`).

@MainActor
enum VisualScriptBuilderLinkNodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.builderLinks") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        pathFollowerNodes() + navigationNodes() + gameUINodes() + timelineNodes() + dialogueNodes()
    }

    // MARK: Path followers

    static func pathFollowerNodes() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity with the PathFollower (unconnected: this entity or a child)")
        func control(_ id: String, _ title: String, _ doc: String, _ body: @escaping (inout PathFollower) -> Void) -> VisualScriptNodeDefinition {
            S.action(id, title, "Path", doc, [entity]) { c in
                c.world.modify(PathFollower.self, for: try c.entity(with: PathFollower.self), body)
                return .next
            }
        }
        return [
            S.action("pathFollower.play", "Play Path Follower", "Path",
                     "Moves `entity` along its PathFollower's path (from the start offset when stopped or finished, or always with `restart`). "
                     + "With `path` (a .path file) it follows that one, adding a PathFollower to the entity if it has none. Applies on the follower system's next update.",
                     [VisualScriptPin("entity", .entity, doc: "Unconnected: this entity (or a child with a PathFollower)"),
                      VisualScriptPin("path", .asset, doc: "Optional: the .path to follow (asset:<id> or a path under Assets/)"),
                      VisualScriptPin("speed", .float, doc: "Optional: meters per second (0: unchanged)"),
                      VisualScriptPin("restart", .bool)]) { c in
                let file = try c.string("path").trimmingCharacters(in: .whitespaces)
                let speed = try c.float("speed")
                let restart = try c.bool("restart")
                let root = try c.liveEntity("entity")
                if let target = S.find(PathFollower.self, from: root, in: c.world) {
                    c.world.modify(PathFollower.self, for: target) { follower in
                        let changed = !file.isEmpty && follower.path != file
                        if changed { follower.path = file }
                        if speed > 0 { follower.speed = speed }
                        follower.play(from: restart || changed ? follower.startOffset : nil)
                    }
                } else {
                    guard !file.isEmpty else { throw VisualScriptError("the entity has no PathFollower (give `path` to add one)") }
                    var follower = PathFollower(path: file, playOnStart: false)
                    if speed > 0 { follower.speed = speed }
                    follower.play()
                    c.world.add(follower, to: root)
                }
                return .next
            },
            control("pathFollower.pause", "Pause Path Follower", "Stops `entity` where it is on its path.") { $0.pause() },
            control("pathFollower.resume", "Resume Path Follower", "Carries on a paused path follower.") { $0.resume() },
            control("pathFollower.stop", "Stop Path Follower", "Stops `entity` and puts it back at its start offset.") { $0.stop() },
            S.action("pathFollower.seek", "Seek Path Follower", "Path",
                     "Moves `entity` to `distance` meters along its path without firing end events (a stopped follower waits there, paused).",
                     [entity, VisualScriptPin("distance", .float)]) { c in
                let distance = max(try c.float("distance"), 0)
                c.world.modify(PathFollower.self, for: try c.entity(with: PathFollower.self)) { $0.seek(to: distance) }
                return .next
            },
            S.pure("pathFollower.state", "Path Follower State", "Path",
                   "Where `entity` is on its path: meters along it, the path's length (0 until it loads), `progress` 0...1, its state "
                   + "(stopped, playing, paused, finished), whether it moves and its direction (+1 forward, -1 back).",
                   [entity], [VisualScriptPin("distance", .float), VisualScriptPin("length", .float), VisualScriptPin("progress", .float),
                              VisualScriptPin("state", .string), VisualScriptPin("playing", .bool), VisualScriptPin("direction", .float)]) { c in
                let follower = c.world.get(PathFollower.self, for: try c.entity(with: PathFollower.self))
                let length = follower?.length ?? 0
                c.set("distance", .float(Double(follower?.distance ?? 0)))
                c.set("length", .float(Double(length)))
                c.set("progress", .float(length > 0 ? Double((follower?.distance ?? 0) / length) : 0))
                c.set("state", .string(follower?.state.rawValue ?? ""))
                c.set("playing", .bool(follower?.isPlaying ?? false))
                c.set("direction", .float(Double(follower?.direction ?? 1)))
            },
            S.event("event.pathFollower", "On Path Follower Event",
                    "Runs when this entity's PathFollower reaches an end of its path: `kind` reachedEnd, reachedStart, looped (after "
                    + "reachedEnd, going round) or finished (stopped at the end in `once` mode); config kind filters (empty: any).",
                    event: "pathFollower",
                    config: [VisualScriptConfigKey("kind", doc: "reachedEnd, reachedStart, looped or finished (empty: any)")],
                    outputs: [VisualScriptPin("kind", .string), VisualScriptPin("distance", .float), VisualScriptPin("entity", .entity)]),
        ]
    }

    // MARK: Navigation

    static func navigationNodes() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        return [
            S.pure("navigation.findPath", "Find Path", "Navigation",
                   "A walkable path from `from` to `to` on the world's navmesh, or its grid without one (`world.findPath`; both are baked "
                   + "from the static colliders the first time they are needed). `points` are world positions from start to goal; `found` is false "
                   + "when there is no grid or no way through. With `partial`, an unreachable goal gives the path to the nearest reachable cell.",
                   [VisualScriptPin("from", .vec3), VisualScriptPin("to", .vec3), VisualScriptPin("partial", .bool)],
                   [VisualScriptPin("points", .array), VisualScriptPin("found", .bool), VisualScriptPin("length", .float),
                    VisualScriptPin("count", .int)]) { c in
                let from = try c.vec3("from"), to = try c.vec3("to"), partial = try c.bool("partial")
                if c.world.navigation == nil { c.world.bakeNavigation() }
                let points = c.world.findPath(from: from, to: to, partial: partial) ?? []
                var meters: Float = 0
                for i in points.indices.dropFirst() { meters += length(points[i] - points[i - 1]) }
                c.set("points", .array(points.map { .vec3($0) }))
                c.set("found", .bool(!points.isEmpty))
                c.set("length", .float(Double(meters)))
                c.set("count", .int(points.count))
            },
            S.action("navigation.bake", "Bake Navigation", "Navigation",
                     "Bakes the world's navmesh and navigation grid again from its static colliders (after the level changed); `baked` is false when there is nothing to bake.",
                     [], [VisualScriptPin("baked", .bool)]) { c in
                c.set("baked", .bool(c.world.bakeNavigation() != nil))
                return .next
            },
        ]
    }

    // MARK: Game UI layer

    static func gameUI(_ c: VisualScriptNodeContext) throws -> GameUILayer {
        guard let layer = c.world.gameUI else {
            throw VisualScriptError("this world has no game UI layer (the editor's Game view, GameRunner and exported games have one)")
        }
        return layer
    }

    static func json(_ value: VisualScriptValue) -> JSONValue {
        switch value {
        case .bool(let b): .bool(b)
        case .int(let i): .int(Int64(i))
        case .float(let f): .double(f)
        case .none: .null
        default: .string(value.asString)
        }
    }

    static func gameUINodes() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        return [
            S.action("gameUI.setValue", "Set Game UI Value", "UI",
                     "Sets `key` on the game UI layer (`world.gameUI`): every layout on it reads it (UILayoutPlayer layouts and ones `ui.show` added), "
                     + "now and when shown later. Numbers, bools and text.",
                     [VisualScriptPin("key", .string, required: true), VisualScriptPin("value", .any)]) { c in
                try gameUI(c).set(try c.string("key"), json(try c.input("value")))
                return .next
            },
            S.pure("gameUI.getValue", "Get Game UI Value", "UI",
                   "The value `key` on the game UI layer: set by a graph or game code, or by a slider, toggle or text field bound to it.",
                   [VisualScriptPin("key", .string, required: true)], [VisualScriptPin("value", .any), VisualScriptPin("found", .bool)]) { c in
                let found = try gameUI(c).value(try c.string("key"))
                c.set("value", found.map(VisualScriptValue.fromJSON) ?? .none)
                c.set("found", .bool(found != nil))
            },
            S.pure("gameUI.layout", "Entity UI Layout", "UI",
                   "Whether `entity`'s UILayoutPlayer layout is on the game UI layer, and the .ui file it shows.",
                   [VisualScriptPin("entity", .entity, doc: "The entity with the UILayoutPlayer (unconnected: this entity or a child)")],
                   [VisualScriptPin("shown", .bool), VisualScriptPin("layout", .string)]) { c in
                let target = try c.entity(with: UILayoutPlayer.self)
                c.set("shown", .bool(c.world.uiLayout(for: target) != nil))
                c.set("layout", .string(c.world.get(UILayoutPlayer.self, for: target)?.layout ?? ""))
            },
            S.action("gameUI.hideAll", "Hide All Game UI", "UI",
                     "Hides everything on the game UI layer: turns off every UILayoutPlayer's `visible` (turn it on again to show one) and "
                     + "takes off the layouts graphs (`ui.show`) and game code added.") { c in
                let layer = try gameUI(c)
                var players: [Entity] = []
                c.world.query(UILayoutPlayer.self) { entity, player in if player.visible { players.append(entity) } }
                for entity in players { c.world.modify(UILayoutPlayer.self, for: entity) { $0.visible = false } }
                VisualScriptUI.of(c.runtime).removeOwned()
                var owned = Set<ObjectIdentifier>()
                c.world.query(UILayoutPlayer.self) { entity, _ in
                    if let view = layer.view(for: entity) { owned.insert(ObjectIdentifier(view)) }
                }
                for widget in layer.container.children where !owned.contains(ObjectIdentifier(widget)) { layer.remove(widget) }
                return .next
            },
            S.event("event.gameUI", "On Game UI Event",
                    "Runs when a widget of a layout on the game UI layer sends its event (a button press, a slider, toggle or text field "
                    + "change): `event`, the widget's id, its `value` (none for buttons) and the bound `key`. config event filters (empty: any). "
                    + "Heard by the graph of the entity whose UILayoutPlayer shows the layout; layouts shown by code reach graphs with anyEntity.",
                    event: "gameUI", config: [VisualScriptConfigKey("event", doc: "The widget's event name (empty: any)")],
                    outputs: [VisualScriptPin("event", .string), VisualScriptPin("widget", .string), VisualScriptPin("value", .any),
                              VisualScriptPin("key", .string), VisualScriptPin("entity", .entity)]),
        ]
    }

    // MARK: Timelines

    static func timelineNodes() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity with the TimelinePlayer (unconnected: this entity or a child)")
        return [
            S.action("timeline.clearFade", "Clear Timeline Fade", "Timeline",
                     "Takes the screen fade off `entity`'s timeline: a finished timeline whose file has `holdFade` keeps its last fade until this "
                     + "(or until it stops or plays again). While it plays, the fade track sets it again on the next update.", [entity]) { c in
                let target = try c.entity(with: TimelinePlayer.self)
                c.world.modify(TimelinePlayer.self, for: target) { $0.clearFade() }
                c.world.remove(ScreenFade.self, from: target)
                return .next
            },
            S.pure("timeline.dialogue", "Timeline Dialogue", "Timeline",
                   "The conversations `entity`'s timeline started with dialogue keys: `waiting` while a key with `wait` holds the playhead, "
                   + "`conversation` the entity whose conversation it waits for (else the newest one it started), for the Dialogue nodes.",
                   [entity], [VisualScriptPin("waiting", .bool), VisualScriptPin("conversation", .entity), VisualScriptPin("count", .int)]) { c in
                let player = c.world.get(TimelinePlayer.self, for: try c.entity(with: TimelinePlayer.self))
                let started = (player?.startedDialogues ?? []).filter { c.world.isAlive($0) }
                c.set("waiting", .bool(player?.isWaitingForDialogue ?? false))
                c.set("conversation", (player?.waitingDialogue ?? started.last).map { .entity($0) } ?? .none)
                c.set("count", .int(started.count))
            },
            S.action("timeline.releaseDialogue", "Release Timeline Dialogue", "Timeline",
                     "Ends the conversation a `wait` dialogue key holds `entity`'s timeline for, so the timeline carries on (as when the player "
                     + "finishes it); `released` is false when it isn't waiting.", [entity], [VisualScriptPin("released", .bool)]) { c in
                let target = try c.entity(with: TimelinePlayer.self)
                guard let waiting = c.world.get(TimelinePlayer.self, for: target)?.waitingDialogue else {
                    c.set("released", .bool(false))
                    return .next
                }
                c.world.dialogues?.stop(waiting)
                c.set("released", .bool(true))
                return .next
            },
        ]
    }

    // MARK: Dialogue layouts

    static func dialogueNodes() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let entity = VisualScriptPin("entity", .entity, doc: "The entity with the DialoguePlayer (unconnected: this entity or a child)")
        return [
            S.action("dialogue.setLayout", "Set Dialogue Layout", "Dialogue",
                     "Picks the .ui layout that shows `entity`'s conversation (`DialoguePlayer.uiLayout`; see DialogueLayoutKeys). Empty goes "
                     + "back to the dialogue file's own layout, else the default box. A conversation on screen switches at once.",
                     [entity, VisualScriptPin("layout", .asset, doc: "A .ui file (asset:<id> or a path under Assets/); empty: the default")]) { c in
                let layout = try c.string("layout").trimmingCharacters(in: .whitespaces)
                c.world.modify(DialoguePlayer.self, for: try c.entity(with: DialoguePlayer.self)) { $0.uiLayout = layout }
                return .next
            },
            S.pure("dialogue.layout", "Dialogue Layout", "Dialogue",
                   "The .ui layout `entity`'s conversation uses: the DialoguePlayer's own, else its dialogue file's (empty: the default box).",
                   [entity], [VisualScriptPin("layout", .string), VisualScriptPin("own", .bool)]) { c in
                let target = try c.entity(with: DialoguePlayer.self)
                let own = c.world.get(DialoguePlayer.self, for: target)?.uiLayout ?? ""
                let file = own.isEmpty ? c.world.dialogues?.runner(for: target)?.dialogue.uiLayout ?? "" : own
                c.set("layout", .string(file))
                c.set("own", .bool(!own.isEmpty))
            },
        ]
    }

    // MARK: Events

    /// What the game UI event source remembers between frames.
    final class GameUIWatch {
        weak var layer: GameUILayer?
        var listener: GameUIListener?
        var queued: [(UIBuildEvent, Entity?)] = []
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        runtime.addEventSource("engine.pathFollower") { runtime in
            let world = runtime.world
            guard !runtime.instances.isEmpty, world.count(of: PathFollower.self) > 0 else { return }
            for (entity, event) in world.pathFollowerEvents() {
                VisualScriptEngineSupport.raise("pathFollower", from: entity,
                                                outputs: ["kind": .string(event.kind.rawValue), "distance": .float(Double(event.distance)),
                                                          "entity": .entity(entity)],
                                                in: runtime) { VisualScriptEngineSupport.nameMatches($0, event.kind.rawValue, key: "kind") }
            }
        }
        let watch = GameUIWatch()
        runtime.addEventSource("engine.gameUI") { runtime in
            let layer = runtime.world.gameUI
            if watch.layer !== layer {
                if let old = watch.layer, let listener = watch.listener { old.removeListener(listener) }
                watch.layer = layer
                watch.queued.removeAll()
                watch.listener = layer?.onEvent { [weak watch] event, entity in watch?.queued.append((event, entity)) }
            }
            guard !watch.queued.isEmpty else { return }
            let events = watch.queued
            watch.queued.removeAll()
            guard !runtime.instances.isEmpty else { return }
            for (event, entity) in events {
                let outputs: [String: VisualScriptValue] = [
                    "event": .string(event.name), "widget": .string(event.widget), "value": event.value.map(VisualScriptValue.fromJSON) ?? .none,
                    "key": .string(event.key ?? ""), "entity": entity.map { .entity($0) } ?? .none,
                ]
                let matches: (VisualScriptNode) -> Bool = { VisualScriptEngineSupport.nameMatches($0, event.name, key: "event") }
                if let entity, runtime.world.isAlive(entity) {
                    VisualScriptEngineSupport.raise("gameUI", from: entity, outputs: outputs, in: runtime, where: matches)
                } else {
                    // Shown by code: no owner, so only nodes with anyEntity hear it.
                    for instance in runtime.instances.values.sorted(by: { $0.entity.index < $1.entity.index }) where instance.program.handles("gameUI") {
                        runtime.raise("gameUI", on: instance, outputs: outputs) { node in
                            node.source.config["anyEntity"] == .bool(true) && matches(node.source)
                        }
                    }
                }
            }
        }
    }
}
