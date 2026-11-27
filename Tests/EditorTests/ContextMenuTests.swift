import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineUI

// Right-click menus on dock tabs and scene objects (EditorContextMenus.swift).

@MainActor private func makeApp() -> EditorApp {
    let app = EditorApp(options: EditorOptions(deterministic: true))
    app.setupWithoutWindow(size: Vec2(1600, 1000), scale: 1)
    app.syncPanels()
    return app
}

@MainActor private func rightClick(_ app: EditorApp, at point: Vec2) {
    app.ui.pointerMoved(to: point)
    app.ui.pointerButton(.right, down: true)
    app.ui.pointerButton(.right, down: false)
}

@MainActor private func openMenu(_ app: EditorApp, named name: String) -> PopupMenu? {
    app.ui.overlays.last.flatMap { $0 as? PopupMenu }.flatMap { $0.name == name ? $0 : nil }
}

@MainActor private func pick(_ menu: PopupMenu, _ title: String) {
    guard let index = menu.items.firstIndex(of: title) else { return }
    menu.onSelect?(index)
    menu.context?.dismissOverlay(menu)
}

@MainActor @Suite struct ContextMenuTests {
    /// The center of panel `id`'s tab.
    private func tabPoint(_ app: EditorApp, _ id: String) throws -> Vec2 {
        app.ui.layoutIfNeeded()
        let group = try #require(app.dock.panel(id)?.owner)
        let index = try #require(group.tabs.firstIndex { $0.id == id })
        let y = group.frame.y + app.dock.tabBarHeight / 2
        let xs = stride(from: group.frame.x, to: group.frame.maxX, by: 2).filter { group.tab(at: Vec2($0, y)) == index }
        let x = try #require(xs.isEmpty ? nil : (xs.first! + xs.last!) / 2)
        return Vec2(x, y)
    }

    @Test func aTabsMenuClosesPopsOutAndResets() throws {
        let app = makeApp()
        rightClick(app, at: try tabPoint(app, EditorLayout.console))
        let menu = try #require(openMenu(app, named: "tabMenu"))
        #expect(menu.items.starts(with: ["Close", "Close Other Tabs", "Open in New Window"]))
        #expect(menu.items.last == "Reset Layout" && !menu.items.contains("Dock"))
        #expect(menu.itemCommandIDs.first == PanelCloseCommand.id.rawValue)
        // The tab right-clicked comes to the front.
        #expect(app.isFront(EditorLayout.console))
        pick(menu, "Close")
        #expect(!app.dock.isOpen(EditorLayout.console))

        // The Scene tab can't close, and floats instead of opening a window; a floating panel can dock.
        rightClick(app, at: try tabPoint(app, EditorLayout.viewport))
        let scene = try #require(openMenu(app, named: "tabMenu"))
        #expect(!scene.items.contains("Close") && scene.items.contains("Float"))
        pick(scene, "Float")
        #expect(app.isFloating(EditorLayout.viewport))
        rightClick(app, at: try tabPoint(app, EditorLayout.viewport))
        let floating = try #require(openMenu(app, named: "tabMenu"))
        pick(floating, "Dock")
        #expect(!app.isFloating(EditorLayout.viewport) && app.dock.isOpen(EditorLayout.viewport))

        rightClick(app, at: try tabPoint(app, EditorLayout.viewport))
        pick(try #require(openMenu(app, named: "tabMenu")), "Reset Layout")
        #expect(app.dock.isOpen(EditorLayout.console))
    }

    @Test func aHierarchyRowsMenuActsOnItsEntity() throws {
        let app = makeApp()
        let session = app.session
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube))?.entity)
        let sphere = try #require(session.run(EntityCreateCommand.self, .init(template: .sphere))?.entity)
        #expect(session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) } == sphere)
        app.syncPanels()
        app.ui.layoutIfNeeded()
        let tree = app.hierarchy.tree
        let row = try #require(tree.visibleNodes.firstIndex { $0.userData as? EntityID == cube })
        let rect = tree.rowRect(row)

        // Right-clicking the cube's row selects it and shows its menu.
        rightClick(app, at: Vec2(rect.x + rect.width / 2, rect.y + rect.height / 2))
        #expect(session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) } == cube)
        let menu = try #require(openMenu(app, named: "entityMenu"))
        #expect(menu.items.starts(with: ["Rename", "Duplicate", "Delete…", "Frame in Scene View", "Create Empty Child"]))
        #expect(!menu.items.contains("Unparent") && menu.disabledIndices.isEmpty)
        pick(menu, "Create Empty Child")
        let world = session.world
        let parent = try #require(world.entity(for: cube))
        let child = try #require(world.children(of: parent).first)
        #expect(world.worldMatrix(of: child).translation == world.worldMatrix(of: parent).translation)

        // The child (now selected) can be unparented; Rename edits its row in place.
        app.syncPanels()
        app.ui.layoutIfNeeded()
        let childMenu = app.entityMenuItems()
        #expect(childMenu.contains { $0.title == "Unparent" })
        childMenu.first { $0.title == "Rename" }?.action()
        #expect(tree.renamingNode != nil)
        childMenu.first { $0.title == "Unparent" }?.action()
        #expect(world.parent(of: child) == nil)

        // Below the rows: the Create items.
        let below = tree.rowRect(tree.rowCount - 1)
        rightClick(app, at: Vec2(below.x + 20, min(below.maxY + 30, tree.frame.maxY - 4)))
        let create = try #require(openMenu(app, named: "entityMenu"))
        #expect(create.items.first == "Create Empty" && create.items.contains("Create Torus"))
    }

    @Test func aRightClickInTheSceneViewSelectsWhatIsUnderIt() throws {
        let app = makeApp()
        let session = app.session
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube))?.entity)
        session.run(SelectionClearCommand.self)
        session.run(ViewFrameSelectionCommand.self, .init(entities: [cube]))
        app.syncPanels()
        app.ui.layoutIfNeeded()
        let rect = app.viewportWidget.frame
        app.viewport.rect = rect
        let center = Vec2(rect.width / 2, rect.height / 2)
        let context = app.toolContext(view: app.viewport.view(aspect: rect.width / rect.height))
        app.showViewportMenu(at: center, context: context)
        #expect(session.selection.primaryEntity(in: session.world).flatMap { session.world.id(of: $0) } == cube)
        #expect(openMenu(app, named: "entityMenu")?.items.first == "Rename")
        app.ui.dismissOverlay(try #require(app.ui.overlays.last))

        // Empty space: Create.
        app.showViewportMenu(at: Vec2(2, 2), context: context)
        #expect(openMenu(app, named: "entityMenu")?.items.first == "Create Empty")
    }

    @Test func theRightButtonClicksOrFlies() {
        let controller = ViewportController()
        controller.rect = UIRect(x: 0, y: 0, width: 400, height: 300)
        var clicks: [Vec2] = []
        controller.onContextClick = { point, _ in clicks.append(point) }
        let world = World()
        let selection = EditorSelection()
        func frame(_ build: (inout ViewportInput) -> Void) {
            var input = ViewportInput(mousePosition: Vec2(100, 80))
            build(&input)
            controller.update(input) { view in
                ViewportToolContext(world: world, selection: selection, undo: UndoStack(world: world), view: view, viewportRect: controller.rect,
                                    pixelScale: 1, toolMode: .move, isPlaying: false, meshBounds: { _ in nil })
            }
        }
        // Press and release in place: a click, no flying.
        frame { $0.pressed = [.right]; $0.down = [.right] }
        #expect(controller.gesture == nil && !controller.wantsMouseCapture)
        frame { $0.released = [.right] }
        #expect(clicks == [Vec2(100, 80)])

        // Press and move: flying, no click.
        frame { $0.pressed = [.right]; $0.down = [.right] }
        frame { $0.down = [.right]; $0.mouseDelta = Vec2(12, 0) }
        #expect(controller.gesture == .fly)
        frame { $0.released = [.right] }
        #expect(clicks.count == 1 && controller.gesture == nil)
    }
}
