import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Dialogues: the file model, validation, expressions, the runner, editing, the importer, the
// DialoguePlayer system and the default DialogueBox.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("DialogueTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Dialogue")
}

private let gate = """
{
  "start": "hello",
  "speakers": [{"id": "guard", "name": "Gate Guard", "color": "#E0A040"}],
  "variables": [{"name": "gold", "type": "number", "default": 5}, {"name": "paid", "type": "bool"}],
  "nodes": [
    {"id": "hello", "type": "line", "speaker": "guard", "text": "Toll is 10. You have {gold}.", "key": "gate.hello", "next": "ask"},
    {"id": "ask", "type": "choice", "text": "Well?", "choices": [
      {"text": "Pay", "key": "gate.pay", "next": "pay", "condition": "gold >= 10"},
      {"text": "Leave", "next": "bye"}]},
    {"id": "pay", "type": "set", "changes": [{"variable": "gold", "op": "subtract", "value": 10}, {"variable": "paid", "value": true}], "next": "open"},
    {"id": "open", "type": "event", "event": "openGate", "args": {"speed": 2}, "next": "check"},
    {"id": "check", "type": "condition", "condition": "paid && gold == 0", "next": "broke", "else": "bye"},
    {"id": "broke", "type": "line", "speaker": "guard", "text": "Spent it all, eh?", "next": "bye"},
    {"id": "bye", "type": "end"}
  ]
}
"""

private func decode(_ json: String) throws -> DialogueAsset { try DialogueAsset.decode(Data(json.utf8)) }

@MainActor
@Suite struct DialogueTests {
    // MARK: Model

    @Test func everyKeyIsOptionalAndRoundTrips() throws {
        let empty = try decode("{}")
        #expect(empty.nodes.isEmpty && empty.start.isEmpty)
        let node = try decode(#"{"nodes": [{"id": "a"}]}"#).nodes[0]
        #expect(node.type == .line && node.next.isEmpty && node.position == nil)
        let variable = try decode(#"{"variables": [{"name": "x", "default": true}]}"#).variables[0]
        #expect(variable.type == .bool, "the type is guessed from the default")

        let dialogue = try decode(gate)
        let again = try DialogueAsset.decode(try dialogue.fileData())
        #expect(again == dialogue)
        #expect(dialogue.node("check")?.elseNext == "bye")
        #expect(dialogue.speaker("guard")?.parsedColor != nil)
    }

    @Test func validationFindsProblems() throws {
        #expect(try decode(gate).validate().isEmpty)
        let bad = try decode("""
            {"start": "nope", "speakers": [{"id": "a", "color": "red"}], "variables": [{"name": "n", "type": "number"}],
             "nodes": [
              {"id": "x", "type": "line", "speaker": "ghost", "text": "{missing}", "next": "y"},
              {"id": "x", "type": "choice"},
              {"id": "c", "type": "condition", "condition": "n >"},
              {"id": "s", "type": "set", "changes": [{"variable": "n", "op": "toggle"}, {"variable": "q", "value": 1}]},
              {"id": "e", "type": "event"}
             ]}
            """)
        let messages = bad.validate(assetExists: { _ in false }).map(\.description)
        func has(_ text: String) -> Bool { messages.contains { $0.contains(text) } }
        #expect(has("start node 'nope'"))
        #expect(has("used by more than one node"))
        #expect(has("speaker 'ghost'"))
        #expect(has("{missing}"))
        #expect(has("'y', which doesn't exist"))
        #expect(has("no options"))
        #expect(has("the condition 'n >'"))
        #expect(has("toggle needs a bool"))
        #expect(has("'q' isn't a declared variable"))
        #expect(has("the event has no name"))
        #expect(has("isn't #RRGGBB"))
        let unreachable = try decode(#"{"nodes": [{"id": "a", "type": "end"}, {"id": "b", "type": "end"}]}"#).validate()
        #expect(unreachable.contains { $0.node == "b" && $0.message.contains("no path") })
    }

    @Test func expressions() throws {
        let vars: [String: DialogueValue] = ["gold": 12, "paid": false, "name": "Ann", "rep.town": 3]
        func eval(_ s: String) throws -> DialogueValue { try DialogueExpression(s).evaluate { vars[$0] } }
        #expect(try eval("gold >= 10 && !paid") == .bool(true))
        #expect(try eval("gold > 20 or paid") == .bool(false))
        #expect(try eval("(gold - 2) * 2 / 4") == .number(5))
        #expect(try eval("name == \"Ann\"") == .bool(true))
        #expect(try eval("name + '!'") == .text("Ann!"))
        #expect(try eval("rep.town = 3") == .bool(true), "a single = compares")
        #expect(try eval("-gold + 2") == .number(-10))
        #expect(try eval("unknown") == .bool(false))
        #expect(try DialogueExpression("a && (b || c)").variableNames == ["a", "b", "c"])
        #expect(throws: DialogueExpression.ParseError.self) { try DialogueExpression("gold >") }
        #expect(throws: DialogueExpression.ParseError.self) { try DialogueExpression("(gold") }
        #expect(throws: DialogueExpression.ParseError.self) { try DialogueExpression("") }
    }

    // MARK: Runner

    @Test func runnerWalksTheGraph() throws {
        let runner = DialogueRunner(try decode(gate))
        var events: [DialogueEvent] = []
        var changes: [String] = []
        runner.onEvent { events.append($0) }
        runner.onVariableChange { name, _ in changes.append(name) }
        runner.start()
        guard case .line(let line) = runner.state else { Issue.record("expected a line"); return }
        #expect(line.text == "Toll is 10. You have 5.")
        #expect(line.speaker?.displayName == "Gate Guard")
        runner.advance()
        guard case .choices(let poor) = runner.state else { Issue.record("expected choices"); return }
        #expect(poor.options.map(\.text) == ["Leave"], "the pay option's condition is false")
        #expect(poor.prompt == "Well?")

        runner.setVariable("gold", 10)
        runner.start(at: "ask")
        guard case .choices(let rich) = runner.state else { Issue.record("expected choices"); return }
        #expect(rich.options.map(\.text) == ["Pay", "Leave"])
        #expect(runner.choose(0))
        // pay → open (event) → check (paid && gold == 0) → broke
        guard case .line(let broke) = runner.state else { Issue.record("expected a line"); return }
        #expect(broke.node == "broke")
        #expect(runner.number("gold") == 0 && runner.bool("paid") == true)
        #expect(events == [DialogueEvent(name: "openGate", args: ["speed": .int(2)], node: "open")])
        #expect(changes == ["gold", "gold", "paid"])
        runner.advance()
        #expect(runner.state == .finished)
        #expect(!runner.isActive)
        #expect(runner.choose(0) == false)
    }

    @Test func localizationAndHotReload() throws {
        let runner = DialogueRunner(try decode(gate))
        runner.useLocalization(["gate.hello": "Péage: 10. Vous avez {gold}."])
        runner.start()
        guard case .line(let line) = runner.state else { Issue.record("expected a line"); return }
        #expect(line.text == "Péage: 10. Vous avez 5.")

        var edited = try decode(gate)
        edited.nodes[0].key = ""
        edited.nodes[0].text = "New text {gold}"
        edited.variables.append(DialogueVariable(name: "visits", type: .number, defaultValue: .int(1)))
        runner.setVariable("gold", 7)
        runner.replace(edited)
        guard case .line(let reloaded) = runner.state else { Issue.record("expected a line"); return }
        #expect(reloaded.text == "New text 7", "variables survive a reload")
        #expect(runner.number("visits") == 1)
        edited.nodes.remove(at: 0)
        edited.start = "ask"
        runner.replace(edited)
        #expect(runner.state == .finished, "the shown node was deleted")
    }

    @Test func listenersCanRestartFromAnEventAndLoopsStop() throws {
        let looping = try decode(#"{"variables": [{"name": "n"}], "nodes": [{"id": "a", "type": "set", "changes": [{"variable": "n", "op": "add", "value": 1}], "next": "a"}]}"#)
        let runner = DialogueRunner(looping)
        runner.maxStepsWithoutStopping = 50
        runner.start()
        #expect(runner.state == .finished)
        #expect(runner.number("n") == 50)
        #expect(runner.history.contains { if case .warning = $0 { return true } else { return false } })

        let events = try decode("""
            {"nodes": [{"id": "e", "type": "event", "event": "go", "next": "x"}, {"id": "x", "type": "line", "text": "X"},
                       {"id": "y", "type": "line", "text": "Y"}]}
            """)
        let jumper = DialogueRunner(events)
        jumper.onEvent { [unowned jumper] _ in jumper.start(at: "y") }
        jumper.start()
        guard case .line(let line) = jumper.state else { Issue.record("expected a line"); return }
        #expect(line.node == "y")
    }

    // MARK: Editing

    @Test func editsAddConnectRenameAndRemove() throws {
        var d = try decode(gate)
        d = try d.applying(DialogueEdit(addNodes: [DialogueNode(type: .line, text: "Hi"), DialogueNode(id: "hello", type: .end)],
                                        connect: [DialogueConnection(from: "ask", to: "line", text: "Chat"),
                                                  DialogueConnection(from: "check", to: "line", branch: "else"),
                                                  DialogueConnection(from: "line", to: "bye")]))
        #expect(d.node("line")?.text == "Hi")
        #expect(d.node("hello2")?.type == .end, "a taken id gets a number")
        #expect(d.node("ask")?.choices.last == DialogueChoice(text: "Chat", next: "line"))
        #expect(d.node("check")?.elseNext == "line")
        #expect(d.node("line")?.next == "bye")
        #expect(d.nodes.allSatisfy { $0.position != nil }, "new nodes are placed")

        d = try d.applying(DialogueEdit(updateNodes: ["bye": .object(["id": .string("farewell")]), "hello": .object(["text": .string("Yo")])]))
        #expect(d.node("hello")?.text == "Yo" && d.node("hello")?.speaker == "guard", "other fields stay")
        #expect(d.node("broke")?.next == "farewell", "links follow a rename")
        d = try d.applying(DialogueEdit(removeNodes: ["farewell"], start: "ask"))
        #expect(d.node("broke")?.next == "")
        #expect(d.start == "ask")
        #expect(throws: DialogueError.self) { try d.applying(DialogueEdit(updateNodes: ["zzz": .object([:])])) }
        #expect(throws: DialogueError.self) { try d.applying(DialogueEdit(connect: [DialogueConnection(from: "ask", to: "nowhere")])) }

        d = try d.applying(DialogueEdit(variables: [DialogueVariable(name: "gold", type: .number, defaultValue: .int(50))],
                                        removeVariables: ["paid"], generateKeys: "gate", layout: true))
        #expect(d.variable("gold")?.initialValue == .number(50))
        #expect(d.variable("paid") == nil)
        #expect(d.node("broke")?.key == "gate.broke")
        #expect(d.node("hello")?.key == "gate.hello", "existing keys stay")
        #expect(d.node("ask")?.choices[1].key == "gate.ask.1")
        #expect(d.node("ask")?.position?.x == 0, "layout puts the start in the first column")
        #expect(d.node("pay")?.position?.x == DialogueAsset.layoutSpacing.x)
        #expect(d.localizationEntries.contains { $0.key == "gate.pay" && $0.text == "Pay" })
    }

    // MARK: Importer and the DialoguePlayer system

    @Test func importerAndDialoguePlayerSystem() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let assets = AssetDatabase(project: project)
        let id = try assets.createDialogue(try decode(gate), at: "Talk/gate.dialogue")
        #expect(assets.isDialogue(id))
        #expect(assets.dialogue(path: "Assets/Talk/gate.dialogue")?.nodes.count == 7)
        #expect(assets.dialogue(path: "asset:\(id)")?.start == "hello")

        var broken = try decode(gate)
        broken.speakers[0].portrait = "Art/none.png"
        let warnings = try assets.writeDialogue(broken, to: id)
        #expect(warnings.contains { $0.contains("Art/none.png") })

        let world = World()
        let director = world.addDialogueSystem(assets: { assets })
        #expect(world.dialogues === director)
        let npc = world.spawn(DialoguePlayer(dialogue: "Talk/gate.dialogue", autoStart: true))
        let other = world.spawn(DialoguePlayer(dialogue: "Talk/gate.dialogue", startNode: "ask"))
        var seen: [(Entity, String)] = []
        director.onEvent { entity, event in seen.append((entity, event.name)) }
        let box = RecordingPresenter()
        director.presenter = box
        world.update(dt: 1.0 / 60)
        #expect(director.activeEntity == npc)
        guard case .line(let line)? = world.dialogue(for: npc)?.state else { Issue.record("expected the auto-started line"); return }
        #expect(line.node == "hello")
        #expect(box.shown.last == "hello")

        // Shared variables reach every loaded runner and later ones.
        director.setVariable("gold", 20)
        #expect(world.dialogue(for: other)?.number("gold") == 20)
        let runner = try #require(director.start(other))
        guard case .choices(let choices) = runner.state else { Issue.record("expected choices"); return }
        #expect(choices.options.count == 2)
        #expect(box.shown.last == "ask")
        runner.choose(0)
        #expect(seen.map(\.1) == ["openGate"] && seen.first?.0 == other)
        #expect(director.variable("gold") == .number(10), "runner changes write back to the shared store")

        // Hot reload: rewriting the file swaps the graph into the runner.
        var edited = broken
        edited.nodes[0].text = "Changed!"
        try assets.writeDialogue(edited, to: id)
        world.update(dt: 1.0 / 60)
        guard case .line(let changed)? = world.dialogue(for: npc)?.state else { Issue.record("expected a line"); return }
        #expect(changed.text == "Changed!")

        // Finishing hides the box; despawning drops the runner.
        world.dialogue(for: other)?.stop()
        world.despawn(npc)
        world.update(dt: 1.0 / 60)
        #expect(director.activeEntity == nil)
        #expect(box.shown.last == "-")
        world.removeDialogueSystem()
        #expect(world.dialogues == nil)
        #expect(!world.systemNames(in: .update).contains(DialogueDirector.systemName))
    }

    // MARK: DialogueBox

    @Test func dialogueBoxShowsLinesAndChoices() throws {
        let ui = UIContext()
        ui.setViewport(size: Vec2(800, 600), scale: 1)
        let box = DialogueBox()
        box.charactersPerSecond = 0
        ui.root.addChild(box)
        let runner = DialogueRunner(try decode(gate))
        runner.setVariable("gold", 10)
        box.present(runner)
        #expect(box.isHidden, "an idle runner hides the box")
        runner.start()
        box.present(runner)
        #expect(!box.isHidden)
        #expect(box.nameLabel.text == "Gate Guard")
        #expect(box.textView.text == "Toll is 10. You have 10.")
        #expect(box.textView.isComplete)
        box.continueOrComplete()
        box.present(runner)
        #expect(box.optionButtons.count == 2)
        #expect(box.textView.text == "Well?")
        #expect(box.handleEvent(.key(KeyEvent(key: .num2))))
        #expect(runner.state == .finished)
        box.present(runner)
        #expect(box.isHidden)

        box.charactersPerSecond = 10
        runner.start()
        box.present(runner)
        #expect(!box.textView.isComplete, "typing out")
        box.continueOrComplete()
        #expect(box.textView.isComplete, "the first continue shows the whole line")
        #expect(runner.currentNode == "hello")
    }
}

@MainActor private final class RecordingPresenter: DialoguePresenter {
    var shown: [String] = []
    func present(_ runner: DialogueRunner?) { shown.append(runner?.currentNode ?? "-") }
}
