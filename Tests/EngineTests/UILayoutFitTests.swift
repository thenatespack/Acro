import Testing
@testable import Engine

// What keeps widgets readable when space runs out: wrapping stacks, ellipsized button titles,
// number fields that drop decimals, panels that clip their content, and the layout audit.

@MainActor private func context(_ size: Vec2, _ root: Widget) -> UIContext {
    let ui = UIContext()
    ui.setViewport(size: size, scale: 1)
    ui.root.addChild(root)
    ui.layoutIfNeeded()
    return ui
}

@MainActor @Suite struct UILayoutFitTests {
    @Test func wrappingStackMovesWhatDoesntFitToANewRow() {
        let buttons = (0..<6).map { Button("Button \($0)") }
        let row = HStack(spacing: 6, padding: EdgeInsets(4), [buttons[0], buttons[1], Separator(.vertical), buttons[2], buttons[3], buttons[4], buttons[5]])
        row.wraps = true
        let column = VStack([row, Label("Below")])
        let ui = context(Vec2(260, 300), column)
        let width = buttons[0].frame.width
        #expect(buttons.allSatisfy { $0.frame.maxX <= 260 - 4 + 0.5 })
        // Rows, `spacing` apart; the stack is as tall as its rows, so what follows sits below.
        let rows = Set(buttons.map(\.frame.y)).sorted()
        #expect(rows.count >= 2 && rows[1] - rows[0] == buttons[0].frame.height + 6)
        #expect(row.frame.maxY == buttons.map(\.frame.maxY).max()! + 4)
        #expect(column.children[1].frame.y >= row.frame.maxY)
        // Unwrapped, the same row runs past the window.
        row.wraps = false
        ui.layoutIfNeeded()
        #expect(buttons[5].frame.maxX > 260)
        #expect(buttons[0].frame.width == width)
        #expect(ui.layoutAudit().contains { $0.kind == .outsideWindow })
    }

    @Test func wrappingStackWithRoomIsASingleRow() {
        let a = Button("A"), b = Button("B")
        let row = HStack(spacing: 6, [a, Spacer(), b])
        row.wraps = true
        _ = context(Vec2(400, 100), VStack([row]))
        #expect(a.frame.y == b.frame.y && b.frame.maxX == 400)
    }

    @Test func narrowButtonEllipsizesItsTitleAndShowsItAsTooltip() {
        let button = Button("Undo AI: Set Transform.position on Crate")
        button.style.maxWidth = 120
        let ui = context(Vec2(400, 100), VStack(alignment: .start, [button]))
        #expect(button.frame.width == 120 && button.titleIsTruncated)
        #expect(button.tooltip(at: button.frame.center) == button.title)
        button.tooltip = "Explicit"
        #expect(button.tooltip(at: button.frame.center) == "Explicit")
        let short = Button("OK")
        ui.root.children[0].addChild(short)
        ui.layoutIfNeeded()
        #expect(!short.titleIsTruncated && short.tooltip(at: short.frame.center) == nil)
    }

    @Test func numberFieldDropsDecimalsBeforeClipping() {
        let field = NumberField(value: 12.345)
        field.style.width = 36
        _ = context(Vec2(200, 100), VStack(alignment: .start, [field]))
        #expect(field.accessibilityValue == "12.345")
        #expect(field.isTextShortened && field.tooltip(at: field.frame.center) == "12.345")
        let wide = NumberField(value: 12.345)
        wide.style.width = 120
        _ = context(Vec2(200, 100), VStack(alignment: .start, [wide]))
        #expect(!wide.isTextShortened && wide.tooltip(at: wide.frame.center) == nil)
    }

    @Test func menuTallerThanTheWindowIsCutToFitAndScrolls() throws {
        let anchor = Button("Add")
        let ui = context(Vec2(300, 200), VStack(alignment: .start, padding: EdgeInsets(top: 40), [anchor]))
        let menu = PopupMenu(items: (0..<20).map { "Item \($0)" }, anchor: anchor)
        ui.presentOverlay(menu)
        ui.layoutIfNeeded()
        #expect(menu.frame.y >= anchor.frame.maxY && menu.frame.maxY <= 200)
        #expect(!ui.layoutAudit().contains { $0.kind == .outsideWindow })
        let items = ui.accessibilityElements().filter { $0.role == .menuItem }
        #expect(items.first?.isOnScreen == true && items.last?.isOnScreen == false)
        // The wheel scrolls; the item under the pointer follows.
        let point = Vec2(menu.frame.center.x, menu.contentRect.y + 2)
        #expect(menu.item(at: point) == 0)
        ui.synthesizeScroll(at: point, by: Vec2(0, -1))
        #expect(menu.scrollOffset > 0 && menu.item(at: point)! > 0)
        // Keys keep the highlight in view.
        menu.highlightedIndex = 19
        #expect(menu.scrollOffset == menu.measure().y - menu.padding.vertical - menu.contentRect.height)
        #expect(menu.item(at: Vec2(point.x, menu.contentRect.maxY - 2)) == 19)
    }

    @Test func contrastRatiosFollowWCAG() {
        #expect(abs(UIColor.white.contrastRatio(with: .black) - 21) < 0.01)
        #expect(UIColor.white.contrastRatio(with: .white) == 1)
        #expect(abs(UIColor(hex: 0x767676).contrastRatio(with: .white) - 4.54) < 0.01)
        #expect(UIColor(1, 1, 1, 0.5).composited(over: .black) == UIColor(0.5, 0.5, 0.5, 1))
    }
}
