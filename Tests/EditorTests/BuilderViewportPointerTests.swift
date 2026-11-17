import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineUI

// The builder tabs' 3D views get the pointer: the stacks laid out around a view must not catch
// the hit, or the UI claims the pointer (`UIContext.wantsPointer`) and the view can't orbit.

@MainActor @Suite struct BuilderViewportPointerTests {
    private func run(_ session: EditorSession, _ command: String, _ arguments: [String: Any]) throws -> [String: Any] {
        let data = try session.commands.run(CommandID(command), json: JSONSerialization.data(withJSONObject: arguments))
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private func center(_ rect: UIRect) -> Vec2 { Vec2(rect.x + rect.width / 2, rect.y + rect.height / 2) }

    @Test func everyBuilderViewPassesThePointerThrough() {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        var checked = 0
        for (module, tab) in zip(EditorBuilderRegistry.modules, app.builderTabs) {
            guard let workspace = tab.workspace as? EditorViewportBuilder else { continue }
            app.showBuilderPanel(module.panelID)
            app.ui.layoutIfNeeded()
            let view = workspace.viewportWidget
            guard view.isEffectivelyVisible, view.frame.width > 0, view.frame.height > 0 else { continue }
            let hit = app.ui.hitTest(center(view.frame))
            #expect(hit == nil, "\(module.title): the pointer over its view hits \(hit.map { "\(type(of: $0)) '\($0.name)'" } ?? "")")
            checked += 1
        }
        #expect(checked >= 5, "most builder views are shown and checked (\(checked))")
    }

    @Test func meshBuilderOrbitsOnRightDrag() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("BuilderViewportPointerTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let session = app.session
        _ = try run(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try run(session, "meshBuild.new", ["name": "Box", "build": ["parts": [["name": "Box", "shape": "box"]]]])
        _ = try run(session, "meshBuild.open", ["asset": try #require(created["asset"] as? String)])
        let workspace = try #require(app.meshWorkspace)
        workspace.update(input: nil, dt: 1.0 / 60)
        app.syncPanels()
        app.ui.layoutIfNeeded()

        let start = center(workspace.viewportWidget.frame)
        var input = ViewportInput(mousePosition: start)
        input.pointerOverUI = app.ui.hitTest(start) != nil
        #expect(!input.pointerOverUI)
        let before = workspace.viewport.camera
        input.pressed = [.right]
        input.down = [.right]
        workspace.update(input: input, dt: 1.0 / 60)
        input.pressed = []
        input.mousePosition = start + Vec2(40, 10)
        input.mouseDelta = Vec2(40, 10)
        workspace.update(input: input, dt: 1.0 / 60)
        #expect(workspace.viewport.camera.yaw != before.yaw)
    }
}
