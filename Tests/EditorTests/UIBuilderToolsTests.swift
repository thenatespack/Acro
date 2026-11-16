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

// The UI / HUD Builder as an agent uses it (ui.* tools, JSON in and out) and as a user does (the UI Builder tab).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("UIBuilderToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct UIBuilderToolsTests {
    @MainActor private func project(_ folder: URL) throws -> EditorSession {
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return session
    }

    @Test func newEditGetSetAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)

        let created = try call(session, "uiLayout.new", ["name": "hud", "folder": "UI",
                                                   "widgets": [["id": "ammo", "type": "label", "anchor": "bottomLeft", "text": "Ammo {ammo}"]]])
        #expect(created["path"] as? String == "UI/hud.ui")
        #expect(created["events"] as? [String] == ["pause"])
        #expect((created["valueKeys"] as? [String])?.contains("ammo") == true)
        #expect((created["widgets"] as? [String])?.contains("health (bar, in status)") == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isUIBuildFile(id))

        let edited = try call(session, "uiLayout.edit", [
            "path": "UI/hud.ui",
            "addWidgets": [["id": "coins", "type": "label", "parent": "status", "text": "Coins {coins}"],
                           ["id": "icon", "type": "image", "image": "UI/none.png"]],
            "updateWidgets": ["score": ["fontSize": 32, "color": "accent"]],
            "moveWidgets": [["id": "coins", "index": 0]],
            "bindings": ["health": "hp"],
            "values": ["hp": 40, "coins": 3],
            "colors": ["accent": "#33AAFF"],
        ])
        let warnings = try #require(edited["warnings"] as? [String])
        #expect(warnings.contains { $0.contains("no image asset 'UI/none.png'") }, "\(warnings)")
        let build = try #require(session.assets?.uiBuild(of: id))
        #expect(build.children(of: "status").map(\.id) == ["coins", "healthLabel", "health"])
        #expect(build.widget("score")?.fontSize == 32 && build.widget("health")?.bind == "hp")
        #expect(build.values["hp"] == .int(40) && build.colors["accent"] == "#33AAFF")
        #expect(throws: (any Error).self) { try call(session, "uiLayout.edit", ["asset": id.description, "removeWidgets": ["nobody"]]) }
        #expect(throws: (any Error).self) { try call(session, "uiLayout.new", ["preset": "nope"]) }

        let got = try call(session, "uiLayout.get", ["asset": id.description])
        let layout = try #require(got["layout"] as? [String: Any])
        #expect((layout["widgets"] as? [Any])?.count == build.widgets.count)
        #expect(got["events"] as? [String] == ["pause"])

        #expect(session.performUndo())
        #expect(session.assets?.uiBuild(of: id)?.widget("coins") == nil, "one edit, one undo step")

        let set = try call(session, "uiLayout.set", ["asset": id.description, "layout": ["theme": "light", "widgets": [["id": "only", "type": "button", "text": "Hi"]]]])
        #expect(set["widgets"] as? [String] == ["only (button)"])
        #expect(set["events"] as? [String] == ["only"])
        #expect(session.assets?.uiBuild(of: id)?.theme == "light")

        let menu = try call(session, "uiLayout.new", ["name": "main", "preset": "menu"])
        #expect(menu["events"] as? [String] == ["options", "play", "quit"])
    }

    @Test func workspaceEditsSelectsDragsAndFollowsUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let id = try #require(session.createUIBuildAsset(in: "", name: "hud"))

        let workspace = UIBuilderWorkspace(session: session)
        var opened: AssetID?
        session.onOpenUIBuild = { opened = $0; workspace.open($0) }
        try call(session, "uiLayout.open", ["asset": id.description, "previewSize": [844, 390], "values": ["health": 10], "select": "score"])
        #expect(opened == id && session.openUIBuild == id && workspace.asset == id)
        workspace.update()
        #expect(workspace.selected == "score")
        #expect(workspace.previewSize == Vec2(844, 390))
        #expect((workspace.canvas.preview.widget("health") as? ProgressBar)?.value == 0.1, "preview values from uiLayout.open")
        #expect(throws: (any Error).self) { try call(session, "uiLayout.open", ["asset": id.description, "select": "nobody"]) }

        // A field change is one undo step.
        workspace.setField("score", "text", .string("Points {score}"))
        #expect(workspace.hasPendingEdit)
        workspace.update()
        #expect(session.assets?.uiBuild(of: id)?.widget("score")?.text == "Points {score}")
        #expect((workspace.canvas.preview.widget("score") as? IconLabel)?.text == "Points 1200")

        // Adding goes into the selected container.
        workspace.select("status")
        workspace.update()
        workspace.addWidget(.button)
        workspace.update()
        #expect(workspace.selected == "button")
        #expect(workspace.build.widget("button")?.parent == "status")
        workspace.moveSelected(by: -1)
        workspace.update()
        #expect(workspace.build.children(of: "status").map(\.id) == ["healthLabel", "button", "health"])
        workspace.duplicateSelected()
        workspace.update()
        #expect(workspace.build.widget("button2")?.parent == "status")
        workspace.deleteSelected()
        workspace.update()
        #expect(workspace.build.widget("button2") == nil && workspace.selected == nil)

        // Renaming keeps the selection on the widget.
        workspace.setField("score", "id", .string("points"))
        workspace.update()
        #expect(workspace.selected == "points" && workspace.build.widget("points") != nil)

        // Dragging in the preview moves a widget from its anchor, written once on release.
        let canvas = workspace.canvas
        canvas.layout(in: UIRect(x: 0, y: 0, width: 844 + 32, height: 390 + 32))
        #expect(abs(canvas.previewScale - 1) < 0.001)
        let pause = try #require(canvas.preview.widget("pause"))
        let start = Vec2(canvas.screenRect.x, canvas.screenRect.y) + pause.frame.center
        #expect(canvas.pick(canvas.screenPoint(start)) == "pause")
        #expect(canvas.handleEvent(.pointerDown(PointerEvent(position: start))))
        workspace.update()
        #expect(workspace.selected == "pause")
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: start + Vec2(-30, -20))))
        #expect(workspace.shownBuild.widget("pause")?.offset == Vec2(30, 20), "bottom-right anchored: moving up-left grows the offset")
        #expect(session.assets?.uiBuild(of: id)?.widget("pause")?.offset == .zero, "not written while dragging")
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: start + Vec2(-30, -20))))
        workspace.update()
        #expect(session.assets?.uiBuild(of: id)?.widget("pause")?.offset == Vec2(30, 20))

        // Undo is seen by the workspace without a reopen.
        #expect(session.performUndo())
        workspace.update()
        #expect(workspace.build.widget("pause")?.offset == .zero)

        // Layout-level edits.
        workspace.editLayout("Set Theme", UIBuildEdit(values: ["score": .int(5)], theme: "dark"))
        workspace.update()
        #expect(session.assets?.uiBuild(of: id)?.theme == "dark")
        #expect(UIBuilderWorkspace.parseValue("12") == .int(12) && UIBuilderWorkspace.parseValue("") == .null
                && UIBuilderWorkspace.parseValue("true") == .bool(true) && UIBuilderWorkspace.parseValue("hi") == .string("hi"))
        workspace.close()
        #expect(workspace.asset == nil)
    }
}
