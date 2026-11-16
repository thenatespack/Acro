import Foundation
import Testing
@testable import EditorCore
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

// The dialogue builder as an agent uses it (dialogue.* tools, JSON in and out) and as a user does (the Dialogue tab).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("DialogueToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct DialogueToolsTests {
    @MainActor private func project(_ folder: URL) throws -> EditorSession {
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return session
    }

    @Test func newEditPlayAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)

        let created = try call(session, "dialogue.new", ["name": "gate", "folder": "Talk", "empty": true])
        #expect(created["path"] as? String == "Talk/gate.dialogue")
        #expect((created["warnings"] as? [String])?.contains { $0.contains("no nodes") } == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isDialogueFile(id))

        let edited = try call(session, "dialogue.edit", [
            "path": "Talk/gate.dialogue",
            "speakers": [["id": "guard", "name": "Gate Guard"]],
            "variables": [["name": "gold", "type": "number", "default": 5], ["name": "paid", "type": "bool"]],
            "addNodes": [
                ["id": "hello", "type": "line", "speaker": "guard", "text": "Toll is 10. You have {gold}."],
                ["id": "ask", "type": "choice"],
                ["id": "pay", "type": "set", "changes": [["variable": "gold", "op": "subtract", "value": 10], ["variable": "paid", "value": true]]],
                ["id": "open", "type": "event", "event": "openGate"],
                ["id": "bye", "type": "end"],
            ],
            "connect": [
                ["from": "hello", "to": "ask"],
                ["from": "ask", "to": "pay", "text": "Pay"],
                ["from": "ask", "to": "bye", "text": "Leave"],
                ["from": "pay", "to": "open"],
                ["from": "open", "to": "bye"],
            ],
            "start": "hello",
            "generateKeys": "gate",
        ])
        #expect((edited["warnings"] as? [String]) == [])
        #expect((edited["nodes"] as? [String])?.first == "hello (line): Toll is 10. You have {gold}.")
        let stored = try #require(session.assets?.dialogueContents(of: id))
        #expect(stored.node("ask")?.choices.map(\.next) == ["pay", "bye"])
        #expect(stored.node("hello")?.key == "gate.hello")

        // Add a condition to the Pay option, then play both ways.
        try call(session, "dialogue.edit", ["asset": id.description, "updateNodes": ["ask": ["choices": [
            ["text": "Pay", "next": "pay", "condition": "gold >= 10"], ["text": "Leave", "next": "bye"]]]]])
        let poor = try call(session, "dialogue.play", ["asset": id.description])
        #expect(poor["state"] as? String == "waiting")
        #expect(poor["node"] as? String == "ask")
        let poorSteps = try #require(poor["transcript"] as? [[String: Any]])
        #expect(poorSteps.first?["text"] as? String == "Toll is 10. You have 5.")
        #expect(poorSteps.first?["speaker"] as? String == "Gate Guard")
        #expect(poorSteps.last?["options"] as? [String] == ["Leave"])

        let rich = try call(session, "dialogue.play", ["asset": id.description, "variables": ["gold": 12], "choices": [0]])
        #expect(rich["state"] as? String == "finished")
        #expect(rich["events"] as? [String] == ["openGate"])
        let variables = try #require(rich["variables"] as? [String: Any])
        #expect(variables["gold"] as? Int == 2)
        #expect(variables["paid"] as? Bool == true)

        let localized = try call(session, "dialogue.play", ["asset": id.description, "strings": ["gate.hello": "Bonjour {gold}"], "maxLines": 1])
        #expect((localized["transcript"] as? [[String: Any]])?.first?["text"] as? String == "Bonjour 5")

        // Undo puts the option's condition back the way it was.
        #expect(session.performUndo())
        #expect(session.assets?.dialogueContents(of: id)?.node("ask")?.choices[0].condition == "")

        let got = try call(session, "dialogue.get", ["path": "Talk/gate.dialogue"])
        #expect((got["localizationKeys"] as? [String: String])?["gate.ask.0"] == "Pay")

        // Bad edits are reported, not written.
        #expect(throws: (any Error).self) { try call(session, "dialogue.edit", ["asset": id.description, "connect": [["from": "hello", "to": "nowhere"]]]) }
    }

    @Test func setOpenAndTheWorkspace() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let created = try call(session, "dialogue.new", ["name": "intro"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect((created["warnings"] as? [String]) == [], "the starter has no problems")

        let set = try call(session, "dialogue.set", ["asset": id.description, "dialogue": [
            "nodes": [["id": "a", "type": "line", "text": "One", "next": "b"], ["id": "b", "type": "line", "text": "Two"]]]])
        #expect(set["start"] as? String == "a")
        #expect(session.assets?.dialogueContents(of: id)?.nodes.allSatisfy { $0.position != nil } == true)

        var opened: AssetID?
        session.onOpenDialogue = { opened = $0 }
        try call(session, "dialogue.open", ["asset": id.description])
        #expect(opened == id && session.openDialogue == id)

        // The tab: add a node after the selected one, link, preview, undo.
        let workspace = DialogueWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.update()
        #expect(workspace.selectedNode == "a")
        workspace.addNode(.event)
        workspace.update()
        let afterAdd = try #require(session.assets?.dialogueContents(of: id))
        #expect(afterAdd.node("event")?.type == .event)
        #expect(afterAdd.node("a")?.next == "b", "a's link was taken, so the new node isn't linked from it")
        #expect(workspace.selectedNode == "event")
        workspace.connect("b", "event")
        workspace.update()
        #expect(session.assets?.dialogueContents(of: id)?.node("b")?.next == "event")

        workspace.playFrom(nil)
        #expect(workspace.graph.current == "a")
        #expect(workspace.previewBox.textView.text == "One")
        workspace.previewBox.textView.complete()
        workspace.previewBox.continueOrComplete()
        #expect(workspace.graph.current == "b")

        // An edit through the tools shows up in the open preview.
        try call(session, "dialogue.edit", ["asset": id.description, "updateNodes": ["b": ["text": "Deux"]]])
        workspace.update()
        #expect(workspace.previewBox.textView.text == "Deux")

        #expect(session.performUndo())
        #expect(session.performUndo())
        workspace.update()
        #expect(session.assets?.dialogueContents(of: id)?.node("b")?.next == "", "undo unlinks again")
        workspace.deleteSelected()
        workspace.update()
        #expect(session.assets?.dialogueContents(of: id)?.node("event") == nil)
    }

    @Test func dialoguePlayerIsAddableAndPlaysInPlayMode() throws {
        EditorComponentCatalog.registerBuiltins()
        #expect(EditorComponentCatalog.addableNames.contains(DialoguePlayer.componentName))
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        try call(session, "dialogue.new", ["name": "npc"])
        let npc = session.world.spawn(DialoguePlayer(dialogue: "npc.dialogue", autoStart: true))
        session.play()
        defer { session.stop() }
        session.tick(dt: 1.0 / 60)
        guard case .line(let line)? = session.world.dialogue(for: npc)?.state else { Issue.record("expected the starter's first line"); return }
        #expect(line.text == "Hello there, traveler.")
    }
}
