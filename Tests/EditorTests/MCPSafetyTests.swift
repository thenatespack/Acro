import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// What keeps AI clients in check: "AI: " undo steps, the activity log and reverting an AI batch,
// confirm: true for destructive tools (and asking the user), the project sandbox, read-only
// mode, settings that only the editor changes, and the status bar.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MCPSafetyTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url.resolvingSymlinksInPath()
}

/// An editor MCP server with an initialized in-memory client named "safety-test".
@MainActor private struct Client {
    let session: EditorSession
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init(session: EditorSession = makeSession(), workspace: URL? = nil) {
        self.session = session
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        if let workspace { mcp.workspaceRoot = workspace }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = request("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "safety-test"]])
    }

    func request(_ method: String, _ params: JSON, id: String = UUID().uuidString) -> JSON? {
        connection.send(["jsonrpc": "2.0", "id": .string(id), "method": .string(method), "params": params])
        mcp.pump()
        return reply(id)
    }

    func reply(_ id: String) -> JSON? {
        guard let reply = connection.output.take().first(where: { $0["id"] == .string(id) }) else { return nil }
        return reply["result"] ?? reply["error"] ?? nil
    }

    func call(_ name: String, _ arguments: JSON = [:]) -> JSON {
        request("tools/call", ["name": .string(name), "arguments": arguments]) ?? nil
    }

    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = call(name, arguments)
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)",
                sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    func failure(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> String {
        let result = call(name, arguments)
        #expect(result["isError"] == true, "\(name) should fail", sourceLocation: sourceLocation)
        return result["content"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }

    var toolNames: [String] {
        (request("tools/list", [:])?["tools"]?.arrayValue ?? []).compactMap { $0["name"]?.stringValue }
    }
}

@MainActor @Suite struct MCPSafetyTests {
    @Test func aiStepsAreLabeledAndLogged() throws {
        let client = Client()
        let session = client.session
        client.tool("entity.create", ["template": "cube", "name": "Crate"])
        #expect(session.undo.undoLabel == "AI: Create Cube")
        // The user's own edits keep their labels.
        session.run(EntityCreateCommand.self, .init(template: .sphere))
        #expect(session.undo.undoLabel == "Create Sphere")
        #expect(session.undo.labelPrefix == nil && session.fileAccessRoots == nil)

        _ = client.failure("entity.rename", ["entity": "00000000000000000000000000000abc", "name": "x"])
        let entries = session.activity.entries
        #expect(entries.map(\.tool) == ["entity.create", "entity.rename"])
        #expect(entries[0].outcome == .ok && entries[0].client == "safety-test")
        #expect(entries[0].arguments.contains("\"template\":\"cube\""))
        #expect(entries[0].undoLabel == "AI: Create Cube" && entries[0].undoDepth == 1)
        #expect(entries[1].outcome == .error && entries[1].undoLabel == nil)

        let listed = client.tool("activity.list", ["limit": 1])
        #expect(listed["entries"]?.arrayValue?.count == 1 && listed["next"] == 3)  // activity.list records itself after reading
        #expect(listed["revertableSteps"] == 0)  // the user's sphere is on top
    }

    @Test func revertUndoesTheLastAIBatch() throws {
        let client = Client()
        let session = client.session
        let start = session.world.entityCount
        session.run(EntityCreateCommand.self, .init(template: .empty, name: "Mine"))
        client.tool("entity.create", ["template": "cube"])
        client.tool("edit.batch", ["label": "Two spheres", "calls": [
            ["command": "entity.create", "arguments": ["template": "sphere"]],
            ["command": "entity.create", "arguments": ["template": "sphere"]],
        ]])
        #expect(session.undo.undoHistory.prefix(2) == ["AI: Two spheres", "AI: Create Cube"])
        #expect(session.world.entityCount == start + 4)

        // Revert one call: its step and the AI steps after it.
        let batch = try #require(session.activity.entries.last { $0.tool == "edit.batch" })
        let first = try #require(session.activity.entries.first { $0.tool == "entity.create" })
        let one = client.tool("activity.revert", ["entry": .int(Int64(batch.id))])
        #expect(one["undone"] == ["AI: Two spheres"])
        client.tool("edit.redo")
        // Revert the whole batch: down to the user's step, which stays.
        let all = client.tool("activity.revert")
        #expect(all["undone"] == ["AI: Two spheres", "AI: Create Cube"])
        #expect(session.world.entityCount == start + 1 && session.undo.undoLabel == "Create Empty")
        #expect(client.failure("activity.revert").contains("wasn't made by an AI client"))

        // With a step of the user's on top, reverting an earlier AI call is refused.
        client.tool("edit.redo")
        session.run(EntityCreateCommand.self, .init(template: .empty))
        let refused = client.failure("activity.revert", ["entry": .int(Int64(first.id))])
        #expect(refused.contains("isn't available") || refused.contains("undo those first"))
        #expect(throws: CommandError.self) { try session.revertAIChanges(through: first.id) }
    }

    @Test func destructiveToolsNeedConfirm() throws {
        let client = Client()
        let session = client.session
        session.run(EntityCreateCommand.self, .init(template: .cube, name: "Unsaved"))
        let refused = client.failure("scene.new")
        #expect(refused.contains("confirm: true"))
        #expect(session.world.entityCount > 0 && session.undo.canUndo)  // nothing ran
        #expect(session.activity.entries.last?.outcome == .refused)
        // The schema says so.
        let tools = client.request("tools/list", [:])?["tools"]?.arrayValue ?? []
        let schema = tools.first { $0["name"] == "scene.new" }?["inputSchema"]
        #expect(schema?["required"]?.arrayValue?.contains("confirm") == true)
        #expect(schema?["properties"]?["confirm"]?["type"] == "boolean")
        #expect(tools.first { $0["name"] == "entity.create" }?["inputSchema"]?["properties"]?["confirm"] == nil)
        // A batch holding a destructive call needs it too.
        let batch = client.failure("edit.batch", ["label": "x", "calls": [["command": "scene.new"]]])
        #expect(batch.contains("scene.new") && batch.contains("confirm"))

        client.tool("scene.new", ["confirm": true])
        #expect(!session.undo.canUndo)
    }

    @Test func filesStayInsideTheProject() throws {
        let workspace = temporaryDirectory()
        let outside = temporaryDirectory()
        let client = Client(workspace: workspace)
        let session = client.session
        // Without a project: the workspace folder. Relative paths land in it.
        client.tool("scene.saveAs", ["path": "level.json", "confirm": true])
        #expect(FileManager.default.fileExists(atPath: workspace.appendingPathComponent("level.json").path))
        #expect(client.failure("scene.saveAs", ["path": .string(outside.appendingPathComponent("x.json").path), "confirm": true])
            .contains("outside the project folder"))
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("x.json").path))
        #expect(client.failure("scene.open", ["path": "../escape.json", "confirm": true]).contains(".."))
        #expect(client.failure("scene.open", ["path": "~/Desktop/x.json", "confirm": true]).contains("outside"))
        // Symbolic links out of the folder don't help.
        try FileManager.default.createSymbolicLink(at: workspace.appendingPathComponent("link"), withDestinationURL: outside)
        #expect(client.failure("scene.saveAs", ["path": "link/y.json", "confirm": true]).contains("outside"))

        // With a project: its folder. Imports from outside it are refused.
        client.tool("project.new", ["path": "Game"])
        let project = try #require(session.project).root
        let model = outside.appendingPathComponent("tex.png")
        try Data([0x89]).write(to: model)
        #expect(client.failure("asset.import", ["sources": .array([.string(model.path)])]).contains("outside"))
        #expect(client.failure("asset.newFolder", ["folder": "../../", "name": "x"]).contains(".."))
        #expect(client.failure("project.open", ["path": .string(outside.path)]).contains("outside"))
        client.tool("scene.saveAs", ["path": "main.json", "confirm": true])
        #expect(FileManager.default.fileExists(atPath: project.appendingPathComponent("main.json").path))
        // The scene file now lives in the project; one opened from elsewhere can't be overwritten.
        session.fileAccessRoots = nil
        #expect(session.save(as: outside.appendingPathComponent("user.json").path))  // the user can
        #expect(client.failure("scene.save", ["confirm": true]).contains("outside"))
        // The user's own actions are never confined.
        #expect(session.fileAccessRoots == nil)
    }

    @Test func readOnlyModeListsAndRunsOnlyReadOnlyTools() throws {
        let client = Client()
        let session = client.session
        let everything = client.toolNames
        session.aiSettings.readOnly = true
        let readOnly = client.toolNames
        #expect(readOnly.count < everything.count && readOnly.contains("entity.find") && readOnly.contains("ui.snapshot") == everything.contains("ui.snapshot"))
        #expect(!readOnly.contains("entity.create") && !readOnly.contains("ui.click"))
        for name in readOnly { #expect(session.commands.info(CommandID(name))?.isReadOnly == true) }
        let count = session.world.entityCount
        let refused = client.call("tools/call", ["name": "entity.create", "arguments": ["template": "cube"]])
        #expect(session.world.entityCount == count)
        _ = refused
        client.tool("entity.find", ["name": "Floor"])
    }

    @Test func settingsChangeOnlyInTheEditor() throws {
        let client = Client()
        let session = client.session
        let settings = client.tool("ai.settings")
        #expect(settings["readOnly"] == false && settings["httpEnabled"] == true)
        #expect(client.failure("ai.settings", ["readOnly": false]).contains("only be changed in the editor"))
        #expect(client.failure("edit.batch", ["label": "x", "calls": [["command": "ai.settings", "arguments": ["readOnly": false]]]])
            .contains("only be changed"))
        // The editor's own UI runs the command directly.
        session.run(AISettingsCommand.self, .init(askBeforeDestructive: true))
        #expect(session.aiSettings.askBeforeDestructive)

        // Prefs keep them, and older prefs files without them still load.
        let prefs = EditorPrefs(lastScenePath: "a.json", ai: AISettings(readOnly: true, httpEnabled: false))
        let decoded = try JSONDecoder().decode(EditorPrefs.self, from: JSONEncoder().encode(prefs))
        #expect(decoded.ai == AISettings(readOnly: true, httpEnabled: false))
        let old = try JSONDecoder().decode(EditorPrefs.self, from: Data(#"{"version": 1, "lastScenePath": "a.json"}"#.utf8))
        #expect(old.ai == nil)
        #expect(try JSONDecoder().decode(AISettings.self, from: Data("{}".utf8)) == AISettings())
    }

    @Test func askingTheUserBeforeDestructiveCalls() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let client = Client(session: app.session)
        let session = app.session
        session.run(AISettingsCommand.self, .init(askBeforeDestructive: true))
        session.run(EntityCreateCommand.self, .init(template: .cube, name: "Precious"))

        // The call waits for the user, who declines.
        #expect(client.request("tools/call", ["name": "scene.new", "arguments": ["confirm": true]], id: "ask") == nil)
        #expect(session.activity.entries.last?.outcome == .running)
        let dialog = try #require(app.ui.overlays.last as? ConfirmDialog)
        #expect(dialog.name == "aiConfirmDialog")
        dialog.cancelButton.activate()
        client.mcp.pump()
        let declined = try #require(client.reply("ask"))
        #expect(declined["isError"] == true)
        #expect(session.world.roots.contains { session.displayName(of: $0) == "Precious" })
        #expect(session.activity.entries.last?.outcome == .refused)

        // Allowed this time: it runs.
        #expect(client.request("tools/call", ["name": "scene.new", "arguments": ["confirm": true]], id: "ask2") == nil)
        let again = try #require(app.ui.overlays.last as? ConfirmDialog)
        again.confirmButton.activate()
        client.mcp.pump()
        #expect(client.reply("ask2")?["isError"] == false)
        #expect(!session.world.roots.contains { session.displayName(of: $0) == "Precious" })
        #expect(session.activity.entries.last?.outcome == .ok)

        // Without a window to ask in it is refused.
        let plain = Client()
        plain.session.aiSettings.askBeforeDestructive = true
        #expect(plain.failure("scene.new", ["confirm": true]).contains("no editor window"))
    }

    @Test func activityPanelAndStatusBar() throws {
        var options = EditorOptions(deterministic: true)
        options.mcp.stdio = false
        let app = EditorApp(options: options)
        app.setupWithoutWindow()
        let session = app.session
        // Without an MCP server there is no status bar.
        #expect(StatusBar.status(app: app) == nil)
        #expect(app.statusBar.view.isHidden)

        let client = Client(session: session)
        client.tool("entity.create", ["template": "cube"])
        app.dock.focusPanel(EditorLayout.activity)
        app.syncPanels()
        let rows = app.ui.accessibilityElements().filter { $0.path.contains("activityRow.") && $0.role == .label }
        #expect(rows.contains { $0.label?.contains("entity.create") == true })
        let revert = try #require(app.ui.accessibilityElements().first { $0.label == "Revert" && $0.command == "activity.revert" })
        #expect(revert.isEnabled)
        let revertAllButton = try #require(app.ui.root.descendant(named: "activityRevertAll"))
        let revertAll = try #require(app.ui.accessibilityElement(for: revertAllButton))
        #expect(revertAll.isEnabled && revertAll.command == "activity.revert")
        // Revert in the panel undoes the AI's cube.
        let count = session.world.entityCount
        app.ui.synthesizeClick(at: revertAll.clickPoint)
        #expect(session.world.entityCount == count - 1)

        // The read-only checkbox is an AI setting.
        let readOnly = try #require(app.ui.root.descendant(named: "aiReadOnly") as? Checkbox)
        readOnly.toggle()
        #expect(session.aiSettings.readOnly)
    }

    @Test func statusBarShowsConnectedAndActing() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let mcp = EditorMCP(session: app.session)
        mcp.server.log = { _ in }
        app.attachMCPForTesting(mcp)
        #expect(StatusBar.status(app: app)?.text == "AI: off")
        let connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        connection.send(["jsonrpc": "2.0", "id": 1, "method": "initialize",
                         "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "claude-code"]]])
        mcp.pump()
        connection.send(["jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": ["name": "entity.find", "arguments": [:]]])
        mcp.pump()
        let acting = try #require(StatusBar.status(app: app))
        #expect(acting.acting && acting.text == "AI acting: entity.find")
        app.session.aiSettings.readOnly = true
        #expect(StatusBar.status(app: app)?.text.hasSuffix("· read-only") == true)
        app.syncPanels()
        #expect(!app.statusBar.view.isHidden)
    }
}
