import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Parity between the editor's UI and its MCP tools: every toolbar button, menu item, shortcut,
// context-menu entry, dialog button, field and drag-and-drop target maps to a command that the
// MCP server serves as a tool. It walks the whole UI (with a project open, an entity selected
// and each menu and dialog opened in turn), so adding UI without a command fails here.

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ParityTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @Suite struct ParityTests {
    /// The tools an MCP client sees.
    private func toolNames(_ session: EditorSession) -> Set<String> {
        Set(EditorMCP(session: session).tools.map(\.name))
    }

    /// Interactive elements whose command is missing or not a tool, as "path (role): problem".
    private func problems(_ elements: [UIAccessibilityElement], tools: Set<String>) -> [String] {
        elements.filter { $0.role.isInteractive }.compactMap { element in
            guard let command = element.command else { return "\(element.path) (\(element.role.rawValue)): no command" }
            return tools.contains(command) ? nil : "\(element.path) (\(element.role.rawValue)): '\(command)' isn't an MCP tool"
        }
    }

    @Test func everyUIElementRunsACommandThatIsATool() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let session = app.session
        let ui = app.ui!
        // A project with a folder, a material and a selected entity, so every panel shows its controls.
        let project = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: project.path))
        try session.commands.run(AssetNewFolderCommand.self, .init(name: "Props"))
        try session.commands.run(AssetNewMaterialCommand.self, .init(name: "Red"))
        app.syncPanels()
        let tools = toolNames(session)
        var seen: [String: String] = [:]  // path → command, for the report below

        func check(_ what: String) {
            let elements = ui.accessibilityElements()
            for element in elements where element.role.isInteractive { seen[element.path] = element.command ?? "-" }
            let issues = problems(elements, tools: tools)
            #expect(issues.isEmpty, "\(what): \(issues.joined(separator: "; "))")
        }
        func closeOverlays() {
            for overlay in ui.overlays.reversed() { ui.dismissOverlay(overlay) }
            app.syncPanels()
        }
        func click(_ label: String, role: UIAccessibilityRole = .button, button: MouseButton = .left) throws {
            let element = try #require(ui.accessibilityElements().first { $0.label == label && $0.role == role && $0.isOnScreen },
                                       "no \(role) '\(label)'")
            ui.synthesizeClick(at: element.clickPoint, button: button)
            app.syncPanels()
        }

        check("the panels")
        // Every tab's content, the asset inspector and the console / activity / stats tabs.
        for panel in ["console", "activity", "stats", "assets"] {
            app.dock.focusPanel(panel)
            app.syncPanels()
            check("the \(panel) panel")
        }
        // Menus and dialogs, one at a time.
        try click("Create")
        #expect(ui.overlays.last is PopupMenu)
        check("the Create menu")
        closeOverlays()
        try click("Add Component")
        check("the Add Component menu")
        closeOverlays()
        try click("Play speed (time scale)", role: .dropdown)
        check("the time scale menu")
        closeOverlays()
        try click("Delete")
        #expect(ui.overlays.last?.name == "deleteEntitiesDialog")
        check("the delete dialog")
        closeOverlays()
        // The asset browser: right-click a file and a folder, and the asset inspector.
        try click("Red.material", role: .listItem, button: .right)
        #expect((ui.overlays.last as? PopupMenu)?.items.contains("Rename") == true)
        check("a file's context menu")
        closeOverlays()
        try click("Red.material", role: .listItem)
        check("the material inspector")
        try click("Props", role: .listItem, button: .right)
        #expect((ui.overlays.last as? PopupMenu)?.items.contains("Open") == true)
        check("a folder's context menu")
        closeOverlays()
        try click("Delete", role: .button)  // the Assets panel's Delete (the hierarchy's needs a selection)
        check("the asset delete dialog")
        closeOverlays()
        // Rename and import bars.
        try click("Rename", role: .button)
        check("the rename bar")

        #expect(seen.count > 60, "only \(seen.count) interactive elements were seen")
    }

    @Test func uiWithoutACommandIsCaught() {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        app.toolbar.view.addChild(Button("Mystery", name: "mystery"))
        app.syncPanels()
        let issues = problems(app.ui.accessibilityElements(), tools: toolNames(app.session))
        #expect(issues == ["editorRoot/toolbar/mystery (button): no command"])
    }

    @Test func everyShortcutAndDropTargetIsATool() {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let tools = toolNames(session)
        for command in EditorShortcuts.boundCommands {
            #expect(tools.contains(command.rawValue), "shortcut command \(command) isn't a tool")
        }
        for drag in EditorParity.drags {
            #expect(tools.contains(drag.command.rawValue), "dragging \(drag.source) onto \(drag.target): \(drag.command) isn't a tool")
        }
        for target in EditorParity.sampleDropTargets {
            for command in EditorParity.dropCommands(for: target) {
                #expect(tools.contains(command.rawValue), "drop on \(target): \(command) isn't a tool")
            }
        }
        // And every command is a tool (ids that are valid MCP tool names).
        #expect(Set(session.commands.all.map(\.id.rawValue)) == tools)
    }
}
