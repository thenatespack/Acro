import Testing
@testable import EngineCore
@testable import EngineUI

// PopupMenu's submenus, separators and shortcut text (the editor's View menu).

@MainActor @Suite struct PopupSubmenuTests {
    private func setUp() -> (UIContext, PopupMenu, [String]) {
        let ui = UIContext()
        ui.setViewport(size: Vec2(800, 600), scale: 1)
        var picked: [String] = []
        _ = picked
        let menu = PopupMenu(items: ["Open", "Recent", "Close", "Quit"], name: "file")
        menu.anchorRect = UIRect(x: 20, y: 20, width: 60, height: 24)
        menu.separatorsBefore = [2]
        menu.itemShortcuts = ["⌘O", nil, nil, "⌘Q"]
        return (ui, menu, picked)
    }

    @Test func separatorsSpaceTheGroupsAndShortcutsWidenTheMenu() {
        let (ui, menu, _) = setUp()
        let plain = PopupMenu(items: menu.items)
        ui.presentOverlay(menu)
        ui.layoutIfNeeded()
        let first = try! #require(menu.item(at: Vec2(menu.frame.x + 10, menu.frame.y + 10)))
        #expect(first == 0)
        // The rule's gap: item 2 starts lower than two rows down.
        ui.presentOverlay(plain)
        ui.layoutIfNeeded()
        #expect(menu.frame.height > plain.frame.height)
        #expect(menu.measure().x > plain.measure().x)
    }

    @Test func aSubmenuOpensBesideItsItemAndPickingClosesTheChain() throws {
        let (ui, menu, _) = setUp()
        var chosen: String?
        menu.submenus[1] = {
            let recent = PopupMenu(items: ["a.scene", "b.scene"], name: "recent")
            recent.onSelect = { chosen = ["a.scene", "b.scene"][$0] }
            return recent
        }
        var parentChose = false
        menu.onSelect = { _ in parentChose = true }
        ui.presentOverlay(menu)
        ui.layoutIfNeeded()

        // Hovering "Recent" opens it beside the menu; hovering another item closes it.
        func center(_ menu: PopupMenu, _ i: Int) -> Vec2 {
            let row = menu.frame
            let y = stride(from: row.y, to: row.maxY, by: 1).first { menu.item(at: Vec2(row.center.x, $0)) == i }!
            return Vec2(row.center.x, y + 6)
        }
        ui.pointerMoved(to: center(menu, 1))
        let recent = try #require(menu.openSubmenu?.menu)
        ui.layoutIfNeeded()
        #expect(ui.overlays.count == 2 && recent.parentMenu === menu)
        #expect(recent.frame.x >= menu.frame.maxX)
        ui.pointerMoved(to: center(menu, 0))
        #expect(menu.openSubmenu == nil && ui.overlays.count == 1)

        // Clicking it opens it too; picking in it closes both and runs only its choice.
        ui.pointerMoved(to: center(menu, 1))
        ui.pointerButton(.left, down: true)
        ui.pointerButton(.left, down: false)
        let opened = try #require(menu.openSubmenu?.menu)
        ui.layoutIfNeeded()
        ui.pointerMoved(to: center(opened, 1))
        ui.pointerButton(.left, down: true)
        ui.pointerButton(.left, down: false)
        #expect(chosen == "b.scene" && !parentChose && ui.overlays.isEmpty)

        // The keys: Right opens it with its first item highlighted, Left closes it.
        ui.presentOverlay(menu)
        ui.layoutIfNeeded()
        menu.highlightedIndex = 1
        _ = menu.handleEvent(.key(KeyEvent(key: .right)))
        let keyed = try #require(menu.openSubmenu?.menu)
        #expect(keyed.highlightedIndex == 0)
        _ = keyed.handleEvent(.key(KeyEvent(key: .left)))
        #expect(menu.openSubmenu == nil && ui.overlays.count == 1)
        // Closing the menu closes its submenu with it.
        menu.openSubmenu(1)
        ui.dismissOverlay(menu)
        #expect(ui.overlays.isEmpty)
    }
}

// ConfirmDialog's third answer (the editor's recovery prompt: Ignore Changes).
@MainActor @Suite struct ConfirmDialogAlternativeTests {
    @Test func theAlternativeClosesTheDialogAndRunsOnlyItsAction() throws {
        let ui = UIContext()
        ui.setViewport(size: Vec2(800, 600), scale: 1)
        var answers: [String] = []
        let dialog = ConfirmDialog(title: "Recover unsaved work?", message: "…", confirmTitle: "Recover")
        dialog.onConfirm = { answers.append("recover") }
        dialog.onCancel = { answers.append("later") }
        let ignore = dialog.addAlternative("Ignore Changes", name: "recoveryIgnore") { answers.append("ignore") }
        dialog.present(in: ui)
        ui.layoutIfNeeded()
        // Left of Cancel and the confirm button.
        #expect(ignore.frame.maxX <= dialog.cancelButton.frame.x && dialog.cancelButton.frame.maxX <= dialog.confirmButton.frame.x)
        ignore.action?()
        #expect(answers == ["ignore"] && ui.overlays.isEmpty)
        // A second press does nothing.
        ignore.action?()
        #expect(answers == ["ignore"])
    }
}
