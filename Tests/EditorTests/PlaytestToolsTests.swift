import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets

// Agent playtesting in the editor over MCP, on a copy of the SampleGame project: a recorded
// session (playtest.start, input.action, input.gamepad, play.step, playtest.assert), saved and
// replayed with the same checks; the committed PlayerMoves playtest passing in the editor as it
// does headless; and the tools' errors.

private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// An editor MCP server with an initialized in-memory client, on a copy of SampleGame.
@MainActor private struct Client {
    let session: EditorSession
    let mcp: EditorMCP
    let connection: MCPMemoryConnection
    let folder: URL

    init() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("PlaytestToolsTests-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: packageRoot.appendingPathComponent("Projects/SampleGame"), to: folder)
        let log = EditorLog()
        log.echoesToStandardOutput = false
        session = EditorSession(document: EditorDocument(), log: log)
        #expect(session.openProject(path: folder.path))
        #expect(session.open(path: "Scenes/Main.scene"))
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = call("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:]])
    }

    func call(_ method: String, _ params: JSON? = nil) -> JSON {
        let id = JSON.string(UUID().uuidString)
        var message: JSON = ["jsonrpc": "2.0", "id": id, "method": .string(method)]
        if let params { message["params"] = params }
        connection.send(message)
        mcp.pump()
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
    }

    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)",
                sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    func failure(_ name: String, _ arguments: JSON = [:]) -> String {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == true, "\(name) should fail")
        return result["content"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }

    func remove() { try? FileManager.default.removeItem(at: folder) }
}

@MainActor @Suite struct PlaytestToolsTests {
    @Test func recordSaveAndReplayASession() throws {
        let client = try Client()
        defer { client.remove() }
        let session = client.session
        let before = try session.world.save()
        #expect(client.failure("input.action", ["action": "right"]).contains("not playing"))

        let started = client.tool("playtest.start", ["name": "walk and jump"])
        #expect(started["playing"] == true && started["paused"] == true && started["frame"]?.intValue == 0)
        client.tool("play.step", ["frames": 1])
        let actions = client.tool("input.actions")["actions"]?.arrayValue ?? []
        #expect(actions.compactMap { $0["name"]?.stringValue } == ["jump", "left", "right"])
        #expect(actions.first?["origin"] == "script")
        client.tool("input.action", ["action": "right", "duration": 0.5])
        client.tool("input.action", ["action": "jump"])
        client.tool("play.step", ["frames": 40])
        client.tool("input.gamepad", ["axis": "leftStickX", "value": -1, "duration": 0.25])
        client.tool("input.inject", ["steps": [["key": "space"]]])
        client.tool("play.step", ["frames": 20])
        let moved = client.tool("playtest.assert", ["label": "half a meter back", "entity": "Player", "field": "position.x",
                                                    "near": [0.5], "tolerance": 0.05])
        #expect(moved["passed"] == true, "\(moved)")
        let jumps = client.tool("playtest.assert", ["entity": "Player", "variable": "jumps", "equals": 2])
        #expect(jumps["passed"] == true, "\(jumps)")
        let failing = client.tool("playtest.assert", ["label": "flew", "entity": "Player", "field": "position.y", "min": 5])
        #expect(failing["passed"] == false && failing["message"]?.stringValue?.contains("below 5") == true)

        let result = client.tool("playtest.result")
        #expect(result["passed"] == false && result["passedCount"]?.intValue == 2 && result["failedCount"]?.intValue == 1)
        #expect(result["recording"] == true)
        let saved = client.tool("playtest.save", ["path": "Playtests/WalkAndJump"])
        #expect(saved["path"]?.stringValue?.hasSuffix("Playtests/WalkAndJump.playtest.json") == true)
        #expect(saved["frames"]?.intValue == 61 && saved["assertions"]?.intValue == 3)
        let stopped = client.tool("playtest.stop")
        #expect(stopped["failedCount"]?.intValue == 1 && !session.isPlaying)
        #expect(try session.world.save() == before)

        let file = client.folder.appendingPathComponent("Playtests/WalkAndJump.playtest.json")
        let recording = try Playtest(contentsOf: file)
        #expect(recording.scene == "Scenes/Main.scene" && recording.name == "walk and jump")
        #expect(recording.steps.compactMap(\.action) == ["right", "jump"])
        #expect(recording.steps.contains { $0.gamepad?.axis == .leftStickX } && recording.steps.contains { $0.input != nil })

        // Replaying gives the same checks, with the same values.
        let replay = client.tool("playtest.run", ["path": "Playtests/WalkAndJump.playtest.json"])
        #expect(replay["passedCount"]?.intValue == 2 && replay["failedCount"]?.intValue == 1 && replay["errors"]?.arrayValue?.isEmpty == true)
        #expect(replay["checks"]?.arrayValue?.map { $0["actual"] ?? nil } == result["checks"]?.arrayValue?.map { $0["actual"] ?? nil })
        #expect(!session.isPlaying)
        #expect(try session.world.save() == before)
    }

    @Test func committedPlaytestPassesInTheEditor() throws {
        let client = try Client()
        defer { client.remove() }
        let result = client.tool("playtest.run", ["path": "Playtests/PlayerMoves.playtest.json"])
        #expect(result["passed"] == true, "\(result)")
        #expect(result["passedCount"]?.intValue == 8)
        // From another scene, the run opens the playtest's.
        #expect(client.session.newDocument())
        let again = client.tool("playtest.run", ["path": "Playtests/PlayerMoves.playtest.json", "keepPlaying": true])
        #expect(again["passed"] == true && client.session.isPlaying)
        #expect(client.session.document.url?.lastPathComponent == "Main.scene")
        client.tool("play.stop")
    }

    @Test func errorsAndSessionsWithoutRecording() throws {
        let client = try Client()
        defer { client.remove() }
        #expect(client.failure("playtest.save", ["path": "x"]).contains("playtest.start first"))
        #expect(client.failure("playtest.run", [:]).contains("give `path` or `playtest`"))
        client.tool("playtest.start", ["record": false, "actions": ["dash": ["key.leftShift"]]])
        #expect(client.failure("input.action", ["action": "fly"]).contains("no input action 'fly'"))
        client.tool("input.action", ["action": "dash", "down": true])
        client.tool("play.step", ["frames": 2])
        #expect(client.session.gameInput.isDown(.leftShift))
        client.tool("input.clear")
        client.tool("play.step")
        #expect(!client.session.gameInput.isDown(.leftShift))
        #expect(client.failure("playtest.save", ["path": "x"]).contains("nothing recorded"))
        // Assertions outside a started session go into an implicit one.
        client.tool("play.stop")
        let check = client.tool("playtest.assert", ["count": ["name": "Player"], "equals": 1])
        #expect(check["passed"] == true)
        // An inline playtest with a step that can't run reports it.
        let result = client.tool("playtest.run", ["playtest": ["steps": [["frames": 1], ["action": "nope"]]]])
        #expect(result["passed"] == false && result["errors"]?.arrayValue?.first?.stringValue?.contains("step 1") == true)
    }
}
