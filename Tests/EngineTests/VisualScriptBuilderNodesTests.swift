import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineUI
@testable import EngineRendering

// Visual script nodes for the other builders: animation graphs, dialogue, timelines, behavior
// trees and UI layouts (Sources/Engine/VisualScript/), and their events.

private func node(_ id: String, _ type: String, config: [String: JSONValue] = [:], inputs: [String: JSONValue] = [:]) -> VisualScriptNode {
    VisualScriptNode(id: id, type: type, config: config, inputs: inputs)
}

private func link(_ from: String, _ to: String) -> VisualScriptLink { VisualScriptLink(from: from, to: to) }

/// Visual scripts on `world` with the engine's builder nodes and events, graph "g" on a new entity.
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

    /// One frame with `key` pressed.
    func press(_ key: Key, dt: Double = 1.0 / 60) {
        input.beginFrame()
        input.inject(.key(key, down: true))
        input.endEvents()
        world.update(dt: dt)
    }
}

private func makeProject(_ name: String) throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptBuilderNodesTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: name)
}

@MainActor
@Suite struct VisualScriptBuilderNodesTests {
    @Test func nodesAreRegisteredAndValidate() {
        VisualScriptNodes.registerEngineNodes()
        for id in ["animator.setFloat", "animator.setTrigger", "animator.play", "animator.state", "event.animationEvent", "event.animationState",
                   "dialogue.start", "dialogue.choose", "dialogue.getVariable", "dialogue.setVariable", "event.dialogueEvent", "event.dialogueEnded",
                   "timeline.play", "timeline.pause", "timeline.skip", "timeline.seek", "event.timelineEvent", "event.timelineFinished",
                   "behavior.getBlackboard", "behavior.setBlackboard", "event.behaviorEvent",
                   "ui.show", "ui.setValue", "ui.press", "event.uiButton"] {
            #expect(VisualScriptNodes.definition(id) != nil, "\(id)")
        }
        #expect(VisualScriptNodes.definition("event.timelineEvent")?.config.contains { $0.name == "anyEntity" } == true)
        let graph = VisualScriptGraph(nodes: [node("e", "event.timelineEvent", config: ["name": .string("boom")]), node("p", "timeline.pause")],
                                      links: [link("e.out", "p.in")])
        let issues = VisualScriptValidator.validate(graph).filter { $0.severity != .info }
        #expect(issues.isEmpty, "\(issues)")
    }

    @Test func animatorParametersStatesAndEvents() {
        let world = World()
        let library = AnimationLibrary()
        library.register(AnimationClip(name: "idle", channels: [], duration: 1, events: [AnimationEvent(time: 0.05, name: "step")]), key: "idle")
        library.register(AnimationClip(name: "run", channels: [], duration: 1), key: "run")
        let graph = AnimationGraph(
            parameters: [AnimationGraphParameter(name: "speed"), AnimationGraphParameter(name: "jump", type: .trigger)],
            states: [AnimationGraphState(name: "Idle", clip: "idle"), AnimationGraphState(name: "Run", clip: "run")],
            transitions: [AnimationGraphTransition(from: "Idle", to: "Run", conditions: [AnimationGraphCondition(parameter: "speed", test: .greater, value: 0.5)], duration: 0)],
            initialState: "Idle")
        world.addAnimationSystem(library)
        let rig = Rig(world)
        let hero = world.spawn(Transform(), Name("Hero"))
        // The Animator sits on a child: unconnected entity inputs find it.
        let body = world.spawn(Transform(), Animator(targets: [], restPose: [], stateMachine: graph.stateMachine, parameters: graph.parameterDefaults))
        world.setParent(body, to: hero)
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "step", type: .string), VisualScriptVariable(name: "entered", type: .string),
                        VisualScriptVariable(name: "state", type: .string), VisualScriptVariable(name: "speed", type: .float)],
            nodes: [node("key", "event.keyPressed", config: ["key": .string("space")]),
                    node("set", "animator.setFloat", inputs: ["parameter": .string("speed"), "value": .double(2)]),
                    node("ev", "event.animationEvent", config: ["name": .string("step")]),
                    node("setStep", "var.set", config: ["variable": .string("step")]),
                    node("st", "event.animationState"),
                    node("setEntered", "var.set", config: ["variable": .string("entered")]),
                    node("tick", "event.update"),
                    node("read", "animator.state"),
                    node("param", "animator.getParameter", inputs: ["parameter": .string("speed")]),
                    node("setState", "var.set", config: ["variable": .string("state")]),
                    node("setSpeed", "var.set", config: ["variable": .string("speed")])],
            links: [link("key.out", "set.in"), link("ev.out", "setStep.in"), link("ev.state", "setStep.value"),
                    link("st.out", "setEntered.in"), link("st.state", "setEntered.value"),
                    link("tick.out", "setState.in"), link("read.state", "setState.value"),
                    link("setState.out", "setSpeed.in"), link("param.value", "setSpeed.value")]), on: hero)
        rig.step(6)
        #expect(rig.runtime.variable("step", of: hero) == .string("Idle"), "the clip event reached the parent's graph")
        #expect(rig.runtime.variable("state", of: hero) == .string("Idle"))
        rig.press(.space)
        rig.step(2)
        #expect(world.get(Animator.self, for: body)?.currentState == "Run")
        #expect(rig.runtime.variable("entered", of: hero) == .string("Run"))
        #expect(rig.runtime.variable("speed", of: hero) == .float(2))
        #expect(rig.lines.isEmpty, "\(rig.lines)")

        // Play a state directly; a missing state is an error.
        rig.run(VisualScriptGraph(nodes: [node("s", "event.start"), node("p", "animator.play", inputs: ["entity": .null, "state": .string("Idle"), "fade": .int(0)]),
                                          node("bad", "animator.play", inputs: ["state": .string("Nope")])],
                                  links: [link("s.out", "p.in"), link("p.out", "bad.in")]), on: world.spawn(Transform()), name: "player")
        rig.lines.removeAll()
        rig.step(1)
        #expect(rig.lines.contains { $0.contains("has no Animator") }, "\(rig.lines)")
    }

    @Test func dialogueStartChooseVariablesAndEvents() throws {
        let project = try makeProject("Talk")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        _ = try assets.createDialogue(try DialogueAsset.decode(Data("""
            {"start": "hi", "variables": [{"name": "gold", "type": "number", "default": 5}],
             "nodes": [
              {"id": "hi", "type": "line", "speaker": "guard", "text": "Hello", "next": "ask"},
              {"id": "ask", "type": "choice", "text": "Well?", "choices": [{"text": "Pay", "next": "pay"}, {"text": "Leave", "next": "bye"}]},
              {"id": "pay", "type": "event", "event": "paid", "args": {"amount": 3}, "next": "bye"},
              {"id": "bye", "type": "end"}
             ]}
            """.utf8)), at: "Talk/guard.dialogue")
        let world = World()
        let director = world.addDialogueSystem(assets: { assets })
        let rig = Rig(world, assets: assets)
        let npc = world.spawn(Transform(), DialoguePlayer(dialogue: "Talk/guard.dialogue"))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "lines", type: .int), VisualScriptVariable(name: "options", type: .int),
                        VisualScriptVariable(name: "paid", type: .float), VisualScriptVariable(name: "ended", type: .bool),
                        VisualScriptVariable(name: "gold", type: .float)],
            nodes: [node("start", "event.start"),
                    node("setGold", "dialogue.setVariable", inputs: ["name": .string("gold"), "value": .int(9)]),
                    node("talk", "dialogue.start"),
                    node("line", "event.dialogueLine"), node("countLine", "var.set", config: ["variable": .string("lines")], inputs: ["value": .int(1)]),
                    node("adv", "dialogue.advance"),
                    node("choices", "event.dialogueChoices"), node("len", "array.length"),
                    node("setOptions", "var.set", config: ["variable": .string("options")]),
                    node("pick", "dialogue.choose", inputs: ["option": .int(0)]),
                    node("ev", "event.dialogueEvent", config: ["name": .string("paid")]),
                    node("amount", "map.get", inputs: ["key": .string("amount")]),
                    node("setPaid", "var.set", config: ["variable": .string("paid")]),
                    node("end", "event.dialogueEnded"), node("setEnded", "var.set", config: ["variable": .string("ended")], inputs: ["value": .bool(true)]),
                    node("get", "dialogue.getVariable", inputs: ["name": .string("gold")]),
                    node("setGoldVar", "var.set", config: ["variable": .string("gold")])],
            links: [link("start.out", "setGold.in"), link("setGold.out", "talk.in"),
                    link("line.out", "countLine.in"), link("countLine.out", "adv.in"),
                    link("choices.out", "setOptions.in"), link("choices.options", "len.array"), link("len.length", "setOptions.value"),
                    link("setOptions.out", "pick.in"),
                    link("ev.out", "setPaid.in"), link("ev.args", "amount.map"), link("amount.value", "setPaid.value"),
                    link("end.out", "setEnded.in"), link("setEnded.out", "setGoldVar.in"), link("get.value", "setGoldVar.value")]), on: npc)
        rig.step(4)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(director.variable("gold") == .number(9))
        #expect(rig.runtime.variable("lines", of: npc) == .int(1))
        #expect(rig.runtime.variable("options", of: npc) == .int(2))
        #expect(rig.runtime.variable("paid", of: npc) == .float(3))
        #expect(rig.runtime.variable("ended", of: npc) == .bool(true))
        #expect(rig.runtime.variable("gold", of: npc) == .float(9))
    }

    @Test func timelineControlsAndEvents() throws {
        let world = World()
        let timeline = Timeline(duration: 2, tracks: [
            TimelineTrack(id: "e", kind: .event, keys: [TimelineKey(time: 0.5, name: "boom", value: "big"), TimelineKey(time: 1.5, name: "late")]),
        ])
        try #require(world.addTimelinePlayers(source: .fixed(["cut": timeline])) != nil)
        let rig = Rig(world)
        let director = world.spawn(Transform(), TimelinePlayer(timeline: "cut", playOnStart: false))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "heard", type: .string), VisualScriptVariable(name: "done", type: .bool),
                        VisualScriptVariable(name: "late", type: .bool)],
            nodes: [node("start", "event.start"), node("play", "timeline.play"),
                    node("ev", "event.timelineEvent", config: ["name": .string("boom")]),
                    node("set", "var.set", config: ["variable": .string("heard")]),
                    node("pause", "timeline.pause"),
                    node("late", "event.timelineEvent", config: ["name": .string("late")]),
                    node("setLate", "var.set", config: ["variable": .string("late")], inputs: ["value": .bool(true)]),
                    node("fin", "event.timelineFinished"),
                    node("setDone", "var.set", config: ["variable": .string("done")], inputs: ["value": .bool(true)])],
            links: [link("start.out", "play.in"), link("ev.out", "set.in"), link("ev.value", "set.value"), link("set.out", "pause.in"),
                    link("late.out", "setLate.in"), link("fin.out", "setDone.in")]), on: director)
        rig.step(8, dt: 0.1)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(rig.runtime.variable("heard", of: director) == .string("big"))
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .paused, "the event paused it")

        // Another entity's graph drives it through a wire: seek, resume, then skip to the end.
        let remote = world.spawn(Transform())
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "target", type: .entity)],
            nodes: [node("k", "event.keyPressed", config: ["key": .string("space")]), node("t", "var.get", config: ["variable": .string("target")]),
                    node("seek", "timeline.seek", inputs: ["time": .double(1.2)]), node("resume", "timeline.resume"),
                    node("state", "timeline.state"), node("skip", "timeline.skip"), node("mine", "timeline.pause")],
            links: [link("k.out", "seek.in"), link("t.value", "seek.entity"), link("seek.out", "resume.in"), link("t.value", "resume.entity"),
                    link("resume.out", "skip.in"), link("t.value", "skip.entity"), link("t.value", "state.entity"), link("skip.out", "mine.in")]),
                on: remote, name: "remote")
        rig.step(1)
        #expect(rig.runtime.setVariable("target", of: remote, to: .entity(director)))
        rig.press(.space)
        rig.step(2)
        #expect(world.get(TimelinePlayer.self, for: director)?.state == .finished)
        #expect(rig.runtime.variable("late", of: director) == .bool(true), "skipping fires the keys not reached")
        #expect(rig.runtime.variable("done", of: director) == .bool(true))
        #expect(rig.lines.contains { $0.contains("has no TimelinePlayer") }, "unconnected: its own entity, which has none")
    }

    @Test func behaviorTreeBlackboard() {
        let world = World()
        world.assignsEntityIDs = true
        BehaviorTreeLibrary.register(BehaviorTree.preset(.guardian), as: "VisualScriptBuilderNodesTests.guard")
        world.addBehaviorTrees()
        let rig = Rig(world)
        let npc = world.spawn(Transform(), BehaviorTreeRunner(tree: "VisualScriptBuilderNodesTests.guard"))
        rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "alert", type: .float), VisualScriptVariable(name: "found", type: .bool)],
            nodes: [node("start", "event.start"),
                    node("set", "behavior.setBlackboard", inputs: ["key": .string("alert"), "value": .double(3)]),
                    node("get", "behavior.getBlackboard", inputs: ["key": .string("alert")]),
                    node("setVar", "var.set", config: ["variable": .string("alert")]),
                    node("clear", "behavior.clearBlackboard", inputs: ["key": .string("alert")]),
                    node("again", "behavior.getBlackboard", inputs: ["key": .string("alert")]),
                    node("setFound", "var.set", config: ["variable": .string("found")]),
                    node("stop", "behavior.setRunning", inputs: ["running": .bool(false)])],
            links: [link("start.out", "set.in"), link("set.out", "setVar.in"), link("get.value", "setVar.value"),
                    link("setVar.out", "clear.in"), link("clear.out", "setFound.in"), link("again.found", "setFound.value"),
                    link("setFound.out", "stop.in")]), on: npc)
        rig.step(2)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(rig.runtime.variable("alert", of: npc) == .float(3))
        #expect(rig.runtime.variable("found", of: npc) == .bool(false))
        #expect(world.get(BehaviorTreeRunner.self, for: npc)?.isRunning == false)
    }

    @Test func uiLayoutsShowSetPressAndButtonEvents() throws {
        let project = try makeProject("UI")
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        _ = try assets.createUIBuild(try AssetJSON.decoder().decode(UIBuild.self, from: Data("""
            {"values": {"health": 50},
             "widgets": [{"id": "hp", "type": "bar", "bind": "health", "max": 100},
                         {"id": "go", "type": "button", "text": "Go", "event": "start"}]}
            """.utf8)), at: "UI/hud.ui")
        let world = World()
        let rig = Rig(world, assets: assets)
        let layer = Widget()
        rig.host.services[VisualScriptUI.layerService] = layer
        let hero = rig.run(VisualScriptGraph(
            variables: [VisualScriptVariable(name: "health", type: .float), VisualScriptVariable(name: "clicked", type: .string)],
            nodes: [node("start", "event.start"), node("show", "ui.show", inputs: ["layout": .string("UI/hud.ui")]),
                    node("set", "ui.setValue", inputs: ["view": .string("hud"), "key": .string("health"), "value": .int(80)]),
                    node("get", "ui.getValue", inputs: ["view": .string("hud"), "key": .string("health")]),
                    node("setVar", "var.set", config: ["variable": .string("health")]),
                    node("press", "ui.press", inputs: ["view": .string("hud"), "button": .string("go")]),
                    node("btn", "event.uiButton", config: ["event": .string("start")]),
                    node("setClicked", "var.set", config: ["variable": .string("clicked")])],
            links: [link("start.out", "show.in"), link("show.out", "set.in"), link("set.out", "setVar.in"), link("get.value", "setVar.value"),
                    link("setVar.out", "press.in"), link("btn.out", "setClicked.in"), link("btn.button", "setClicked.value")]))
        rig.step(2)
        #expect(rig.lines.isEmpty, "\(rig.lines)")
        #expect(layer.children.count == 1)
        #expect(rig.runtime.scriptUI.names == ["hud"])
        #expect(rig.runtime.variable("health", of: hero) == .float(80))
        #expect(rig.runtime.variable("clicked", of: hero) == .string("go"))

        // Game code can hand views over too; removing the scripts takes down the layouts graphs showed.
        let mine = UIBuildView(UIBuild())
        #expect(world.scriptUI(mine, name: "menu"))
        #expect(rig.runtime.scriptUI.names == ["hud", "menu"])
        world.removeVisualScripts(rig.runtime)
        #expect(layer.children.isEmpty)
    }
}
