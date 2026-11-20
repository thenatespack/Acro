import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineUI
@testable import EngineRendering

// Visual script nodes linking graphs to path followers, grid navigation, the game UI layer,
// timeline fades and dialogue keys, and dialogue layouts (VisualScriptBuilderLinkNodes.swift).

private func node(_ id: String, _ type: String, config: [String: JSONValue] = [:], inputs: [String: JSONValue] = [:]) -> VisualScriptNode {
    VisualScriptNode(id: id, type: type, config: config, inputs: inputs)
}

private func link(_ from: String, _ to: String) -> VisualScriptLink { VisualScriptLink(from: from, to: to) }

private func vec(_ x: Double, _ y: Double, _ z: Double) -> JSONValue { .array([.double(x), .double(y), .double(z)]) }

/// Visual scripts on `world` with the engine's nodes and events.
@MainActor
private final class Rig {
    let world: World
    let host = VisualScriptHost()
    let runtime: VisualScriptRuntime
    let input = Input()
    var lines: [String] = []

    init(_ world: World, assets: AssetDatabase? = nil) {
        self.world = world
        VisualScriptNodes.registerEngineNodes()
        host.assets = { assets }
        host.input = input
        runtime = world.addVisualScripts(host: host)
        VisualScriptEngineNodes.addEventSources(to: runtime)
        host.log = { [unowned self] in lines.append($0) }
    }

    @discardableResult
    func run(_ graph: VisualScriptGraph, on entity: Entity? = nil, name: String = "g") -> Entity {
        runtime.graphs[name] = graph
        if let entity {
            world.add(VisualScript(graph: name), to: entity)
            return entity
        }
        return world.spawn(Transform(), VisualScript(graph: name))
    }

    func step(_ frames: Int = 1, dt: Double = 1.0 / 60) {
        for _ in 0..<frames {
            input.beginFrame()
            input.endEvents()
            world.update(dt: dt)
        }
    }

    func press(_ key: Key, dt: Double = 1.0 / 60) {
        input.beginFrame()
        input.inject(.key(key, down: true))
        input.endEvents()
        world.update(dt: dt)
    }
}

private func makeProject(_ name: String) throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptBuilderLinkNodesTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: name)
}

@MainActor
@Suite struct VisualScriptBuilderLinkNodesTests {
    @Test func nodesAreRegisteredAndValidate() {
        VisualScriptNodes.registerEngineNodes()
        for id in ["pathFollower.play", "pathFollower.pause", "pathFollower.resume", "pathFollower.stop", "pathFollower.seek",
                   "pathFollower.state", "event.pathFollower", "navigation.findPath", "navigation.bake",
                   "gameUI.setValue", "gameUI.getValue", "gameUI.layout", "gameUI.hideAll", "event.gameUI",
                   "timeline.clearFade", "timeline.dialogue", "timeline.releaseDialogue", "dialogue.setLayout", "dialogue.layout"] {
            #expect(VisualScriptNodes.definition(id) != nil, "\(id)")
        }
        let graph = VisualScriptGraph(nodes: [node("e", "event.pathFollower", config: ["kind": .string("finished")]), node("p", "pathFollower.pause")],
                                      links: [link("e.out", "p.in")])
        let issues = VisualScriptValidator.validate(graph).filter { $0.severity != .info }
        #expect(issues.isEmpty, "\(issues)")
    }

    @Test func pathFollowersPlaySeekAndReportTheirEnds() throws {
        let world = World()
        let road = PathBuild(points: [PathPoint(Vec3(0, 0, 0)), PathPoint(Vec3(0, 0, -10))], profiles: [PathProfile(shape: .flat, width: 2)])
        try #require(world.addPathFollowers(source: .fixed(["road": road])) != nil)
        let rig = Rig(world)
        let bus = world.spawn(Transform(), Name("VisualScriptBuilderLinkNodesTestsBus"),
                              PathFollower(path: "road", speed: 5, mode: .once, playOnStart: false))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "finished", type: .bool), VisualScriptVariable(name: "kinds", type: .int),
                        VisualScriptVariable(name: "progress", type: .float), VisualScriptVariable(name: "state", type: .string)],
            nodes: [node("start", "event.start"), node("play", "pathFollower.play"),
                    node("ev", "event.pathFollower"), node("count", "var.set", config: ["variable": .string("kinds")], inputs: ["value": .int(1)]),
                    node("fin", "event.pathFollower", config: ["kind": .string("finished")]),
                    node("setFin", "var.set", config: ["variable": .string("finished")], inputs: ["value": .bool(true)]),
                    node("tick", "event.update"), node("read", "pathFollower.state"),
                    node("setProgress", "var.set", config: ["variable": .string("progress")]),
                    node("setState", "var.set", config: ["variable": .string("state")])],
            links: [link("start.out", "play.in"), link("ev.out", "count.in"), link("fin.out", "setFin.in"),
                    link("tick.out", "setProgress.in"), link("read.progress", "setProgress.value"),
                    link("setProgress.out", "setState.in"), link("read.state", "setState.value")]), on: bus)
        rig.step(10, dt: 0.1)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        let halfway = try #require(world.get(PathFollower.self, for: bus))
        #expect(halfway.isPlaying && abs(halfway.distance - 4.5) < 0.6, "\(halfway.distance)")
        #expect(rig.runtime.variable("finished", of: bus) == .bool(false))
        rig.step(15, dt: 0.1)
        #expect(world.get(PathFollower.self, for: bus)?.state == .finished)
        #expect(rig.runtime.variable("finished", of: bus) == .bool(true))
        #expect(rig.runtime.variable("kinds", of: bus) == .int(1))
        #expect(rig.runtime.variable("progress", of: bus) == .float(1))
        #expect(rig.runtime.variable("state", of: bus) == .string("finished"))

        // Another graph puts a follower on a bare entity and seeks it.
        let cart = world.spawn(Transform())
        // (A follower takes one request per update, so each key sends one.)
        rig.run(VisualScriptGraph(
            nodes: [node("k", "event.keyPressed", config: ["key": .string("space")]),
                    node("play", "pathFollower.play", inputs: ["path": .string("road"), "speed": .double(1)]),
                    node("s", "event.keyPressed", config: ["key": .string("s")]),
                    node("seek", "pathFollower.seek", inputs: ["distance": .double(7)]),
                    node("p", "event.keyPressed", config: ["key": .string("p")]), node("pause", "pathFollower.pause")],
            links: [link("k.out", "play.in"), link("s.out", "seek.in"), link("p.out", "pause.in")]), on: cart, name: "cart")
        rig.press(.space)
        rig.step(2)
        #expect(world.get(PathFollower.self, for: cart)?.isPlaying == true)
        rig.press(.s)
        rig.step(1)
        rig.press(.p)
        rig.step(2)
        let follower = try #require(world.get(PathFollower.self, for: cart))
        #expect(follower.speed == 1 && follower.state == .paused && abs(follower.distance - 7) < 0.1, "\(follower.speed) \(follower.state) \(follower.distance)")
        #expect(rig.lines.isEmpty, "\(rig.lines)")
    }

    @Test func findPathBakesTheGridAndGoesAroundWalls() {
        let world = World()
        world.assignsEntityIDs = true
        world.spawn(Transform(position: Vec3(0, -0.5, 0)), Collider(.box(Vec3(12, 0.5, 12))))
        world.spawn(Transform(position: Vec3(0, 1, 0)), Collider(.box(Vec3(6, 1, 0.25))))
        let rig = Rig(world)
        let walker = rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "found", type: .bool), VisualScriptVariable(name: "count", type: .int),
                        VisualScriptVariable(name: "length", type: .float), VisualScriptVariable(name: "blocked", type: .bool)],
            nodes: [node("start", "event.start"),
                    node("find", "navigation.findPath", inputs: ["from": vec(0, 0, -5), "to": vec(0, 0, 5)]),
                    node("setFound", "var.set", config: ["variable": .string("found")]),
                    node("setCount", "var.set", config: ["variable": .string("count")]),
                    node("setLength", "var.set", config: ["variable": .string("length")]),
                    node("off", "navigation.findPath", inputs: ["from": vec(0, 0, -5), "to": vec(0, 0, 40)]),
                    node("setBlocked", "var.set", config: ["variable": .string("blocked")])],
            links: [link("start.out", "setFound.in"), link("find.found", "setFound.value"), link("setFound.out", "setCount.in"),
                    link("find.count", "setCount.value"), link("setCount.out", "setLength.in"), link("find.length", "setLength.value"),
                    link("setLength.out", "setBlocked.in"), link("off.found", "setBlocked.value")]))
        rig.step(1)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(world.navigation != nil, "baked on first use")
        #expect(rig.runtime.variable("found", of: walker) == .bool(true))
        if case .int(let count)? = rig.runtime.variable("count", of: walker) { #expect(count >= 3, "goes round the wall") }
        if case .float(let meters)? = rig.runtime.variable("length", of: walker) { #expect(meters > 10.5, "longer than straight through: \(meters)") }
        #expect(rig.runtime.variable("blocked", of: walker) == .bool(false), "a goal off the grid has no path")
    }

    @Test func gameUIValuesLayoutsAndEvents() throws {
        let project = try makeProject("GameUI")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        _ = try assets.createUIBuild(try AssetJSON.decoder().decode(UIBuild.self, from: Data("""
            {"widgets": [{"id": "hp", "type": "bar", "bind": "health", "max": 100},
                         {"id": "go", "type": "button", "text": "Go", "event": "start"}]}
            """.utf8)), at: "UI/hud.ui")
        let world = World()
        let layer = world.addGameUI(assets: { assets }, in: Widget())
        let rig = Rig(world, assets: assets)
        let hud = world.spawn(Transform(), UILayoutPlayer(layout: "UI/hud.ui"))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "health", type: .float), VisualScriptVariable(name: "clicked", type: .string),
                        VisualScriptVariable(name: "shown", type: .bool)],
            nodes: [node("start", "event.start"),
                    node("set", "gameUI.setValue", inputs: ["key": .string("health"), "value": .int(70)]),
                    node("get", "gameUI.getValue", inputs: ["key": .string("health")]),
                    node("setVar", "var.set", config: ["variable": .string("health")]),
                    node("ev", "event.gameUI", config: ["event": .string("start")]),
                    node("setClicked", "var.set", config: ["variable": .string("clicked")]),
                    node("tick", "event.update"), node("layout", "gameUI.layout"),
                    node("setShown", "var.set", config: ["variable": .string("shown")])],
            links: [link("start.out", "set.in"), link("set.out", "setVar.in"), link("get.value", "setVar.value"),
                    link("ev.out", "setClicked.in"), link("ev.widget", "setClicked.value"),
                    link("tick.out", "setShown.in"), link("layout.shown", "setShown.value")]), on: hud)
        rig.step(2)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(layer.value("health") == .int(70))
        #expect(rig.runtime.variable("health", of: hud) == .float(70))
        #expect(rig.runtime.variable("shown", of: hud) == .bool(true))
        let view = try #require(world.uiLayout(for: hud))
        #expect(view.value("health") == .int(70), "layer values reach the layout")
        #expect(view.press("go"))
        rig.step(1)
        #expect(rig.runtime.variable("clicked", of: hud) == .string("go"), "the layout's own entity hears it")

        // Hide everything.
        rig.run(VisualScriptGraph(nodes: [node("k", "event.keyPressed", config: ["key": .string("h")]), node("hide", "gameUI.hideAll")],
                                  links: [link("k.out", "hide.in")]), name: "hider")
        let shown = UIBuildView(UIBuild())
        layer.add(shown)
        rig.press(.h)
        #expect(world.get(UILayoutPlayer.self, for: hud)?.visible == false, "players are switched off, not removed")
        #expect(shown.parent == nil, "layouts code added are taken off")
        #expect(layer.view(for: hud) != nil)
    }

    @Test func timelineFadesHoldUntilClearedAndDialogueKeysAreReported() throws {
        let project = try makeProject("Cut")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        _ = try assets.createDialogue(try DialogueAsset.decode(Data("""
            {"start": "hi", "nodes": [{"id": "hi", "type": "line", "speaker": "guard", "text": "Wait", "next": "bye"}, {"id": "bye", "type": "end"}]}
            """.utf8)), at: "Talk/wait.dialogue")
        let world = World()
        world.addDialogueSystem(assets: { assets })
        let fade = Timeline(duration: 0.5, holdFade: true, tracks: [
            TimelineTrack(id: "f", kind: .fade, keys: [TimelineKey(time: 0, amount: 0), TimelineKey(time: 0.5, amount: 1)]),
        ])
        let talk = Timeline(duration: 1, tracks: [
            TimelineTrack(id: "d", kind: .dialogue, keys: [TimelineKey(time: 0.1, dialogue: "Talk/wait.dialogue", wait: true)]),
        ])
        try #require(world.addTimelinePlayers(source: .fixed(["fade": fade, "talk": talk])) != nil)
        let rig = Rig(world, assets: assets)
        let director = world.spawn(Transform(), TimelinePlayer(timeline: "fade"))
        rig.run(VisualScriptGraph(nodes: [node("k", "event.keyPressed", config: ["key": .string("c")]), node("clear", "timeline.clearFade")],
                                  links: [link("k.out", "clear.in")]), on: director)
        rig.step(8, dt: 0.1)
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .finished)
        #expect(world.get(ScreenFade.self, for: director)?.amount == 1, "holdFade keeps the last fade")
        rig.press(.c)
        rig.step(3)
        #expect(world.get(ScreenFade.self, for: director) == nil, "cleared, and not posed back")

        // A wait key holds the timeline; the graph sees the conversation and lets it go.
        let cutscene = world.spawn(Transform(), TimelinePlayer(timeline: "talk"))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "waiting", type: .bool), VisualScriptVariable(name: "talking", type: .bool),
                        VisualScriptVariable(name: "released", type: .bool)],
            nodes: [node("tick", "event.update"), node("state", "timeline.dialogue"),
                    node("setWaiting", "var.set", config: ["variable": .string("waiting")]),
                    node("dstate", "dialogue.state"), node("setTalking", "var.set", config: ["variable": .string("talking")]),
                    node("k", "event.keyPressed", config: ["key": .string("r")]), node("release", "timeline.releaseDialogue"),
                    node("setReleased", "var.set", config: ["variable": .string("released")])],
            links: [link("tick.out", "setWaiting.in"), link("state.waiting", "setWaiting.value"),
                    link("setWaiting.out", "setTalking.in"), link("state.conversation", "dstate.entity"), link("dstate.active", "setTalking.value"),
                    link("k.out", "release.in"), link("release.released", "setReleased.value"), link("release.out", "setReleased.in")]),
                on: cutscene, name: "talk")
        rig.step(5, dt: 0.1)
        #expect(world.get(TimelinePlayer.self, for: cutscene)?.isWaitingForDialogue == true)
        #expect(rig.runtime.variable("waiting", of: cutscene) == .bool(true))
        #expect(rig.runtime.variable("talking", of: cutscene) == .bool(true))
        let held = world.get(TimelinePlayer.self, for: cutscene)?.time ?? 0
        rig.press(.r)
        rig.step(3, dt: 0.1)
        #expect(rig.runtime.variable("released", of: cutscene) == .bool(true))
        #expect(world.get(TimelinePlayer.self, for: cutscene)?.isWaitingForDialogue == false)
        #expect((world.get(TimelinePlayer.self, for: cutscene)?.time ?? 0) > held, "it carries on")
    }

    @Test func dialogueLayoutIsSetAndRead() throws {
        let project = try makeProject("Box")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        _ = try assets.createDialogue(try DialogueAsset.decode(Data("""
            {"start": "hi", "uiLayout": "UI/file.ui", "nodes": [{"id": "hi", "type": "line", "text": "Hi"}]}
            """.utf8)), at: "Talk/box.dialogue")
        let world = World()
        world.addDialogueSystem(assets: { assets })
        let rig = Rig(world, assets: assets)
        let npc = world.spawn(Transform(), DialoguePlayer(dialogue: "Talk/box.dialogue"))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "before", type: .string), VisualScriptVariable(name: "after", type: .string),
                        VisualScriptVariable(name: "own", type: .bool)],
            nodes: [node("start", "event.start"), node("read", "dialogue.layout"),
                    node("setBefore", "var.set", config: ["variable": .string("before")]),
                    node("set", "dialogue.setLayout", inputs: ["layout": .string("UI/mine.ui")]),
                    node("again", "dialogue.layout"),
                    node("setAfter", "var.set", config: ["variable": .string("after")]),
                    node("setOwn", "var.set", config: ["variable": .string("own")])],
            links: [link("start.out", "setBefore.in"), link("read.layout", "setBefore.value"), link("setBefore.out", "set.in"),
                    link("set.out", "setAfter.in"), link("again.layout", "setAfter.value"), link("setAfter.out", "setOwn.in"),
                    link("again.own", "setOwn.value")]), on: npc)
        rig.step(1)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(rig.runtime.variable("before", of: npc) == .string("UI/file.ui"), "the file's own layout")
        #expect(rig.runtime.variable("after", of: npc) == .string("UI/mine.ui"))
        #expect(rig.runtime.variable("own", of: npc) == .bool(true))
        #expect(world.get(DialoguePlayer.self, for: npc)?.uiLayout == "UI/mine.ui")
    }
}
