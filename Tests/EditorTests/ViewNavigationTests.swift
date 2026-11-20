import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersAnimation
@testable import EditorBuildersLogic
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineUI

// Getting around the Scene view (EditorNavigateCommands.swift): Return to Origin (`view.home`,
// Home), Go to Object (`view.goTo`, Cmd/Ctrl+G and its search popup), double-clicking a
// Hierarchy row, and `builder.select` (EditorBuilderSelect.swift).

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ViewNavigationTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// An editor without a window, on the starter scene.
@MainActor private func makeApp() -> EditorApp {
    let app = EditorApp(options: EditorOptions(deterministic: true))
    app.setupWithoutWindow()
    app.syncPanels()
    return app
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: try JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor private func id(_ name: String, _ session: EditorSession) -> EntityID {
    var found: EntityID?
    session.world.query(Name.self) { entity, n in if n.value == name { found = session.world.id(of: entity) } }
    return found!
}

@MainActor private func near(_ a: Vec3, _ b: Vec3, _ tolerance: Float = 1e-3) -> Bool { length(a - b) < tolerance }

@MainActor @Suite struct ViewNavigationTests {
    @Test func cameraReturnsHome() {
        var camera = EditorCamera(pivot: Vec3(9, 9, 9), yaw: 2, pitch: -1, distance: 3)
        camera.fovY = 1
        camera.returnHome()
        #expect(camera.pivot == Vec3(0, 0.5, 0) && camera.yaw == EditorCamera.home.yaw && camera.pitch == EditorCamera.home.pitch)
        #expect(camera.distance == 15 && camera.fovY == 1, "the lens stays")
        camera.returnHome(pivot: Vec3(1, 2, 3), distance: 1e6)
        #expect(camera.pivot == Vec3(1, 2, 3) && camera.distance == EditorCamera.distanceRange.upperBound)
    }

    @Test func homeShortcutMenuAndCommand() throws {
        let app = makeApp()
        let session = app.session
        app.viewport.camera = EditorCamera(pivot: Vec3(5, 5, 5), yaw: 1, pitch: 1, distance: 2)
        let result = try call(session, "view.home")
        #expect(app.viewport.camera == EditorCamera.home)
        #expect((result["distance"] as? Double) == 15)
        try call(session, "view.home", ["pivot": [1, 0, 2], "distance": 4])
        #expect(app.viewport.camera.pivot == Vec3(1, 0, 2) && app.viewport.camera.distance == 4)
        #expect(throws: (any Error).self) { try call(session, "view.home", ["distance": -1]) }

        // Home on the keyboard, and the View menu's entries.
        let shortcuts = EditorShortcuts()
        #expect(shortcuts.action(for: KeyEvent(key: .home)) == .returnHome)
        #expect(shortcuts.action(for: KeyEvent(key: .g, modifiers: .shortcut)) == .goToObject)
        #expect(shortcuts.action(for: KeyEvent(key: .g)) == nil, "plain G stays free for builder tools")
        app.invoke(.returnHome)
        #expect(app.viewport.camera == EditorCamera.home)
        app.toolbar.showViewMenu()
        let menu = try #require(app.ui.overlays.last as? PopupMenu)
        let home = try #require(menu.items.firstIndex { $0.hasPrefix("Return to Origin") })
        let goTo = try #require(menu.items.firstIndex { $0.hasPrefix("Go to Object") })
        #expect(menu.itemCommandIDs[home] == "view.home" && menu.itemCommandIDs[goTo] == "view.goTo")
        app.viewport.camera.pivot = Vec3(3, 3, 3)
        menu.onSelect?(home)
        #expect(app.viewport.camera == EditorCamera.home)
        app.ui.dismissOverlay(menu)
        // Without a window there is nothing to aim.
        let headless = EditorSession(document: EditorDocument(), log: EditorLog())
        #expect(!headless.commands.isAvailable("view.home") && !headless.commands.isAvailable("view.goTo"))
    }

    @Test func goToFindsByNameSelectsAndFrames() throws {
        let app = makeApp()
        let session = app.session
        let sphere = id("Blue Sphere", session)
        var result = try call(session, "view.goTo", ["name": "blue sphere"])
        #expect(result["entity"] as? String == sphere.description && result["path"] as? String == "Props/Blue Sphere")
        #expect(session.selection.ids == [sphere])
        let center = session.world.worldMatrix(of: session.world.entity(for: sphere)!).translation
        #expect(near(app.viewport.camera.pivot, center, 0.05), "framed: \(app.viewport.camera.pivot) vs \(center)")
        // A path, part of a name, an id.
        result = try call(session, "view.goTo", ["name": "Props/Red Cube"])
        #expect(result["entity"] as? String == id("Red Cube", session).description)
        result = try call(session, "view.goTo", ["name": "pilla"])
        #expect(result["name"] as? String == "Green Pillar")
        let spinner = id("Spinner", session)
        result = try call(session, "view.goTo", ["entity": spinner.description])
        #expect(session.selection.ids == [spinner])
        // A whole name wins over names that contain it ("Hub" vs nothing else; "Arm" is in two).
        result = try call(session, "view.goTo", ["name": "hub"])
        #expect(result["name"] as? String == "Hub")
        do {
            try call(session, "view.goTo", ["name": "arm"])
            Issue.record("an ambiguous name should fail")
        } catch {
            let text = "\(error)"
            #expect(text.contains("matches 2 entities") && text.contains("Arm A") && text.contains("Arm B"), "\(text)")
            #expect(text.contains(id("Arm A", session).description), "candidates come with their ids")
        }
        #expect(throws: (any Error).self) { try call(session, "view.goTo", ["name": "Nothing Like It"]) }
        #expect(throws: (any Error).self) { try call(session, "view.goTo") }
    }

    @Test func goToPopupFiltersAsYouTypeAndPicks() throws {
        let app = makeApp()
        let session = app.session
        let ui = try #require(app.ui)
        #expect(app.showGoToObject())
        let dialog = try #require(ui.overlays.last as? GoToObjectDialog)
        #expect(ui.focusedWidget === dialog.field)
        #expect(dialog.shown.count == ViewGoToCommand.candidates(in: session).count && dialog.shown.count >= 12, "every entity before typing")
        ui.synthesizeText("ar")
        #expect(dialog.shown.map(\.name) == ["Arm A", "Arm B", "Green Pillar"], "names that start with it first, then ones that contain it")
        ui.synthesizeKey(KeyEvent(key: .down))
        #expect(dialog.list.selectedRow == 1)
        ui.synthesizeKey(KeyEvent(key: .enter))
        #expect(ui.overlays.isEmpty, "picking closes it")
        #expect(session.selection.ids == [id("Arm B", session)])

        // A click on a row picks it; Esc closes without picking; the shortcut opens it.
        app.invoke(.goToObject)
        let again = try #require(ui.overlays.last as? GoToObjectDialog)
        ui.synthesizeText("sun")
        ui.layoutIfNeeded()
        ui.synthesizeClick(at: again.list.rowRect(0).center)
        #expect(session.selection.ids == [id("Sun", session)])
        app.invoke(.goToObject)
        #expect(ui.overlays.last is GoToObjectDialog)
        ui.synthesizeKey(KeyEvent(key: .escape))
        #expect(ui.overlays.isEmpty)
        #expect(session.selection.ids == [id("Sun", session)])
        // Every control in it runs view.goTo.
        app.showGoToObject()
        for element in ui.accessibilityElements() where element.role.isInteractive && element.path.contains("goToObject") {
            #expect(element.command == "view.goTo", "\(element.path)")
        }
    }

    @Test func doubleClickingAHierarchyRowFramesIt() throws {
        let app = makeApp()
        let session = app.session
        let ui = try #require(app.ui)
        app.viewport.camera = EditorCamera.home
        ui.layoutIfNeeded()
        let row = try #require(ui.accessibilityElements().first { $0.label == "Spinner" && $0.isOnScreen && $0.role != .textField })
        ui.synthesizeClick(at: row.clickPoint, count: 2)
        let spinner = id("Spinner", session)
        #expect(session.selection.ids == [spinner])
        #expect(app.hierarchy.tree.renamingNode == nil, "double click frames instead of renaming")
        let center = session.world.worldMatrix(of: session.world.entity(for: spinner)!).translation
        #expect(length(app.viewport.camera.pivot - center) < 1.5, "framed near \(center): \(app.viewport.camera.pivot)")
        #expect(app.viewport.camera.pivot != EditorCamera.home.pivot)
    }

    @Test func builderSelectSetsATabsSelection() throws {
        let app = makeApp()
        let session = app.session
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        try session.commands.run(ProjectNewCommand.self, .init(path: folder.appendingPathComponent("Game").path))
        // Nothing open in front yet.
        #expect(throws: (any Error).self) { try call(session, "builder.select", ["item": "x"]) }

        // Dialogue: nodes by id.
        let dialogue = try call(session, "dialogue.new", ["name": "ViewNavigationTestsTalk"])
        let dialogueID = try #require(dialogue["asset"] as? String)
        try call(session, "dialogue.open", ["asset": dialogueID])
        var result = try call(session, "builder.select")
        #expect(result["panel"] as? String == EditorLayout.dialogueBuilder, "the tab in front")
        let nodes = try #require(result["items"] as? [String])
        let target = try #require(nodes.last)
        result = try call(session, "builder.select", ["panel": "Dialogue", "item": target])
        #expect(result["selected"] as? [String] == [target])
        #expect(app.dialogueWorkspace.selectedNode == target)
        #expect(throws: (any Error).self) { try call(session, "builder.select", ["panel": "dialogue", "item": "no-such-node"]) }
        result = try call(session, "builder.select", ["panel": "dialogue", "item": ""])
        #expect((result["selected"] as? [String])?.isEmpty == true)

        // Animation Graph: states, parameters and layers bring up their editors.
        let graph = try call(session, "animGraph.new", ["name": "ViewNavigationTestsHero"])
        try call(session, "animGraph.open", ["asset": try #require(graph["asset"] as? String)])
        result = try call(session, "builder.select", ["panel": "animationGraph"])
        let items = try #require(result["items"] as? [String])
        let state = try #require(items.first { $0.hasPrefix("state:") })
        result = try call(session, "builder.select", ["panel": "Animation Graph", "item": state])
        #expect(result["selected"] as? [String] == [state])
        let form = try #require(app.builderWorkspace(AnimationGraphWorkspace.self)?.form)
        #expect(form.selection == .state(String(state.dropFirst("state:".count))))
        if let parameter = items.first(where: { $0.hasPrefix("parameter:") }) {
            result = try call(session, "builder.select", ["panel": "animationGraph", "item": parameter])
            #expect((result["selected"] as? [String])?.contains(parameter) == true)
            #expect(form.selectedParameter == String(parameter.dropFirst("parameter:".count)))
        }
        #expect(throws: (any Error).self) { try call(session, "builder.select", ["panel": "No Such Tab"]) }
    }
}
