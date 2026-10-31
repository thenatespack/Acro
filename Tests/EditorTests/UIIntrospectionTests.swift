import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The editor's UI as tools: the accessibility snapshot of every panel, and clicks, typing, keys,
// drags, scrolls and hovers through the same UIContext event path real input takes, plus the
// dock's panel tools. The app runs without a window (`setupWithoutWindow`), as `--headless` does.

/// The editor with its panels laid out at 1440x900 points, no window or GPU.
@MainActor private func makeApp() -> EditorApp {
    let app = EditorApp(options: EditorOptions(deterministic: true))
    app.setupWithoutWindow()
    return app
}

/// An MCP client of `app`'s session.
@MainActor private struct Client {
    let app: EditorApp
    let mcp: EditorMCP
    let connection: MCPMemoryConnection
    var session: EditorSession { app.session }

    init(_ app: EditorApp = makeApp()) {
        self.app = app
        mcp = EditorMCP(session: app.session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": "initialize",
                         "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "ui-test"]]])
        mcp.pump()
        _ = connection.output.take()
    }

    func call(_ name: String, _ arguments: JSON) -> JSON {
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": "tools/call", "params": ["name": .string(name), "arguments": arguments]])
        mcp.pump()
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
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
}

@MainActor private func entity(_ name: String, _ session: EditorSession) -> Entity {
    let world = session.world
    return world.roots.flatMap { world.subtreeOrder($0) }.first { session.displayName(of: $0) == name }!
}

@MainActor @Suite struct UIIntrospectionTests {
    @Test func everyWidgetHasAUsableLabelAndAPath() throws {
        let app = makeApp()
        let elements = app.ui.accessibilityElements()
        #expect(elements.count > 50)
        // Paths are unique, so each one names one element.
        #expect(Set(elements.map(\.path)).count == elements.count)
        for element in elements where element.role.isInteractive || element.role == .viewport {
            let label = element.label ?? ""
            #expect(!label.trimmingCharacters(in: .whitespaces).isEmpty, "\(element.path) (\(element.role)) has no label")
        }
        let save = try #require(app.ui.accessibilityElement(path: "editorRoot/toolbar/save"))
        #expect(save.role == .button && save.label == "Save" && save.command == "scene.save" && save.isOnScreen)
        // Tree rows, dock tabs and the viewport are elements too.
        #expect(elements.contains { $0.role == .treeItem && $0.label == "Blue Sphere" && $0.isSelected })
        #expect(elements.contains { $0.role == .tab && $0.label == "Inspector" && $0.command == "panel.focus" })
        #expect(elements.contains { $0.itemKey == "close:console" && $0.label == "Close Console" && $0.command == "panel.close" })
        #expect(elements.contains { $0.role == .viewport && $0.command == "view.pick" })
        // The inspector names its fields after the property ("Position X"), editors after their rows.
        let x = try #require(elements.first { $0.label == "Position X" })
        #expect(x.role == .numberField && x.command == "component.setField" && x.value == "0.000")
    }

    @Test func snapshotIsCompactAndScopes() throws {
        let client = Client()
        let snapshot = client.tool("ui.snapshot")
        let elements = snapshot["elements"]?.arrayValue ?? []
        #expect(snapshot["window"] == [1440, 900])
        #expect(elements.contains { $0["path"] == "editorRoot/toolbar/play" && $0["command"] == "play.toggle" })
        // Separators and anonymous stacks are left out; depths count what is kept.
        #expect(!elements.contains { $0["role"] == "separator" })
        #expect(elements.first?["depth"] == 0)
        let all = client.tool("ui.snapshot", ["all": true])["elements"]?.arrayValue ?? []
        #expect(all.count > elements.count)

        let toolbar = client.tool("ui.snapshot", ["root": "editorRoot/toolbar", "maxDepth": 1])["elements"]?.arrayValue ?? []
        #expect(toolbar.allSatisfy { $0["path"]?.stringValue?.hasPrefix("editorRoot/toolbar") == true })
        #expect(toolbar.first?["path"] == "editorRoot/toolbar" && toolbar.count > 15)
        let found = client.tool("ui.find", ["command": "entity.create"])["elements"]?.arrayValue ?? []
        #expect(found.contains { $0["label"] == "Create" })
        #expect(client.failure("ui.snapshot", ["root": "nope"]).contains("no element"))
    }

    @Test func clickMenusCreateWithAnAIStep() throws {
        let client = Client()
        let session = client.session
        let count = session.world.entityCount
        let opened = client.tool("ui.click", ["label": "Create", "role": "button"])["opened"]?.arrayValue ?? []
        let cube = try #require(opened.first { $0["label"] == "Cube" })
        #expect(cube["path"] == "menu/item:Cube" && cube["command"] == "entity.create")
        client.tool("ui.click", ["path": "menu/item:Cube"])
        #expect(session.world.entityCount == count + 1)
        #expect(session.undo.undoLabel == "AI: Create Cube")
        #expect(session.activity.entries.map(\.tool) == ["ui.click", "ui.click"])
        #expect(session.activity.entries.last?.undoLabel == "AI: Create Cube")

        // The hierarchy shows it at once; a click selects it, Shift extends the selection.
        client.tool("ui.click", ["label": "Red Cube", "role": "treeItem"])
        #expect(session.selection.primary == session.world.id(of: entity("Red Cube", session)))
        client.tool("ui.click", ["label": "Blue Sphere", "role": "treeItem", "modifiers": ["shift"]])
        #expect(session.selection.ids.count >= 2)

        // Ambiguity and disabled controls are reported with what to do.
        #expect(client.failure("ui.click", ["label": "Close"]).contains("pass `path`"))
        session.run(SelectionClearCommand.self)
        #expect(client.failure("ui.click", ["path": "editorRoot/dock/hierarchyPanel/hstack/duplicate"]).contains("disabled")
                || client.failure("ui.click", ["label": "Duplicate", "role": "button"]).contains("disabled"))
    }

    /// The acceptance test: an inspector edit made purely through UI actions gives the same
    /// result as the command.
    @Test func inspectorEditThroughTheUIMatchesTheCommand() throws {
        let viaUI = Client()
        viaUI.tool("ui.click", ["label": "Red Cube", "role": "treeItem"])
        let typed = viaUI.tool("ui.type", ["label": "Position X", "text": "2.5", "submit": true])
        #expect(typed["target"]?["label"] == "Position X")
        viaUI.tool("ui.type", ["label": "Name", "role": "textField", "text": "Crate", "submit": true])

        let viaCommand = Client()
        let id = try #require(viaCommand.session.world.id(of: entity("Red Cube", viaCommand.session)))
        viaCommand.tool("component.setField", ["entity": .string(id.description), "component": "Transform", "path": "position.x", "value": 2.5])
        viaCommand.tool("entity.rename", ["entity": .string(id.description), "name": "Crate"])

        let a = viaUI.session, b = viaCommand.session
        let sa = String(decoding: try a.world.save(), as: UTF8.self), sb = String(decoding: try b.world.save(), as: UTF8.self)
        #expect(sa == sb, "\(zip(sa.split(separator: "\n"), sb.split(separator: "\n")).filter { $0.0 != $0.1 }.prefix(6).map { "\($0.0) | \($0.1)" })")
        #expect(a.world.get(Transform.self, for: entity("Crate", a))?.position.x == 2.5)
        #expect(a.undo.undoDepth == b.undo.undoDepth)
        #expect(a.undo.undoHistory.allSatisfy { $0.hasPrefix("AI: ") })
        // Undo through the UI (the shortcut) takes both back, like the command path's edit.undo.
        // The name field still has focus, where Cmd+Z would undo typing: Esc leaves it first.
        viaUI.tool("ui.key", ["keys": ["escape", "mod+z", "mod+z"]])
        viaCommand.tool("edit.undo")
        viaCommand.tool("edit.undo")
        #expect(try a.world.save() == b.world.save())
    }

    @Test func keysDragsScrollsAndHovers() throws {
        let client = Client()
        let session = client.session
        // Hover reads the tooltip, with the real shortcut.
        let hover = client.tool("ui.hover", ["path": "editorRoot/toolbar/save"])
        #expect(hover["tooltip"] == .string("Save the scene (\(EditorShortcuts().shortcutText(for: .save)))"))

        // Dragging a row onto another reparents it (entity.reparent, keeping world transforms).
        client.tool("ui.drag", ["from": ["label": "Red Cube", "role": "treeItem"], "to": ["label": "Green Pillar", "role": "treeItem"]])
        let world = session.world
        #expect(world.parent(of: entity("Red Cube", session)) == entity("Green Pillar", session))
        #expect(session.undo.undoLabel?.hasPrefix("AI: ") == true)

        // F2 renames the selected row in place; typing and Enter commit it.
        client.tool("ui.click", ["label": "Sun", "role": "treeItem"])
        client.tool("ui.key", ["keys": ["f2"]])
        client.tool("ui.type", ["text": "Key Light", "replace": true, "submit": true])
        #expect(session.displayName(of: entity("Key Light", session)) == "Key Light")

        // Escape with nothing focused clears the selection (the shortcut).
        client.app.ui.focus(nil)
        client.tool("ui.key", ["keys": ["escape"]])
        #expect(session.selection.ids.isEmpty)
        #expect(client.failure("ui.key", ["keys": ["hyper+q"]]).contains("Unknown modifier"))

        // Scrolling the console list goes through the scroll view.
        for i in 0..<80 { session.log.info("line \(i)") }
        client.tool("panel.focus", ["panel": "console"])
        client.tool("ui.scroll", ["label": "Console scroll", "dy": 5])
    }

    @Test func viewportClicksPickThroughTheViewport() throws {
        let client = Client()
        let session = client.session
        #expect(!session.selection.ids.isEmpty)  // the starter scene selects the sphere
        let viewport = try #require(client.app.ui.accessibilityElements().first { $0.role == .viewport })
        // The sky in the top-left corner: a click there clears the selection, as the user's would.
        let point: JSON = [.double(Double(viewport.frame.x + 12)), .double(Double(viewport.frame.y + 12))]
        let result = client.tool("ui.click", ["point": point])
        #expect(result["viewport"] == true)
        #expect(session.selection.ids.isEmpty)
        // At the sphere's pixel the click selects it (picked against the meshes).
        let sphere = entity("Blue Sphere", session)
        let rect = viewport.frame
        let view = client.app.viewport.view(aspect: rect.width / rect.height)
        let projection = ViewportProjection(view, size: Vec2(rect.width, rect.height), pixelScale: 1)
        let center = try #require(projection.project(session.world.worldMatrix(of: sphere).translation))
        client.tool("ui.click", ["point": [.double(Double(rect.x + center.x)), .double(Double(rect.y + center.y))]])
        #expect(session.selection.primary == session.world.id(of: sphere))
    }

    @Test func panelsOpenCloseFocusAndDock() throws {
        let client = Client()
        let panels = client.tool("panel.list")["panels"]?.arrayValue ?? []
        #expect(panels.map { $0["id"]?.stringValue ?? "" }.sorted() == EditorLayout.panelIDs.sorted())
        #expect(panels.first { $0["id"] == "activity" }?["open"] == true)
        #expect(panels.first { $0["id"] == "assets" }?["selected"] == true)

        let dock = client.app.dock
        client.tool("panel.close", ["panel": "console"])
        #expect(!dock.isOpen("console"))
        #expect(client.failure("panel.close", ["panel": "viewport"]).contains("can't be closed"))
        client.tool("panel.open", ["panel": "console"])
        #expect(dock.isOpen("console") && EditorLayout.activePanel(in: dock.layout, groupOf: "console") == "console")
        client.tool("panel.focus", ["panel": "stats"])
        #expect(EditorLayout.activePanel(in: dock.layout, groupOf: "stats") == "stats")
        client.tool("panel.dock", ["panel": "inspector", "tabWith": "hierarchy"])
        #expect(EditorLayout.activePanel(in: dock.layout, groupOf: "hierarchy") == "inspector")
        client.tool("panel.dock", ["panel": "stats", "edge": "left", "fraction": 0.2])
        #expect(dock.isOpen("stats"))
        #expect(client.failure("panel.dock", ["panel": "stats"]).contains("tabWith"))
        #expect(client.failure("panel.open", ["panel": "nope"]).contains("no panel"))
        client.tool("layout.reset")
        #expect(dock.layout == EditorLayout.defaultLayout)

        // Closing a tab through its close button is the same as panel.close.
        client.tool("ui.click", ["label": "Close Stats"])
        #expect(!dock.isOpen("stats"))
    }

    @Test func toolsNeedTheUI() {
        // A plain session (no EditorApp) has no UI to drive.
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        #expect(!session.commands.isAvailable(UISnapshotCommand.id))
        #expect(session.commands.unavailableReason(UIClickCommand.id)?.contains("UI isn't running") == true)
    }

    @Test func keyChordsParse() throws {
        #expect(try UIKeyParsing.chord("mod+shift+z") == KeyEvent(key: .z, modifiers: [.shortcut, .shift]))
        #expect(try UIKeyParsing.chord("Enter") == KeyEvent(key: .enter))
        #expect(try UIKeyParsing.chord("ctrl+1") == KeyEvent(key: .num1, modifiers: .control))
        #expect(try UIKeyParsing.chord("esc") == KeyEvent(key: .escape))
        #expect(throws: CommandError.self) { try UIKeyParsing.chord("mod+nope") }
    }

    @Test func readableNames() {
        #expect(Widget.readableName("scenePath") == "Scene path")
        #expect(Widget.readableName("Light.intensity") == "Light intensity")
        #expect(Widget.readableName("") == nil)
    }
}
