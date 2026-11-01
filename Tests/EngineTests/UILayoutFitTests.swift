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
        // Fading multiplies alpha: a translucent fill stays translucent (withAlpha replaced it,
        // which made the Game theme's disabled buttons light gray).
        #expect(UIColor(1, 1, 1, 0.08).fading(0.5) == UIColor(1, 1, 1, 0.04))
        #expect(UIColor(hex: 0x2a3140).fading(0.5) == UIColor(hex: 0x2a3140).withAlpha(0.5))
    }

    // MARK: Re-review after icons (#660, #661)

    /// The components of one vector show the same decimals (#34): the fewest any of them fits.
    @Test func vectorComponentsShareTheirDecimals() {
        let vector = VectorField(count: 3, values: [1, 2, 12345.5])
        vector.style.width = 200
        _ = context(Vec2(300, 100), VStack(alignment: .start, [vector]))
        let shown = vector.fields.map(\.shownText)
        let decimals = shown.map { $0.split(separator: ".").dropFirst().first?.count ?? 0 }
        #expect(Set(decimals).count == 1, "\(shown)")
        #expect(decimals[0] < vector.fields[0].effectivePrecision, "\(shown)")
        #expect(vector.sharedDecimals == decimals[0])
        // A field shortened only to match the others still has its exact value as the tooltip.
        #expect(vector.fields[0].isTextShortened && vector.fields[0].tooltip(at: vector.fields[0].frame.center) == "1.000")
        // With room for everything, all keep the full precision.
        let wide = VectorField(count: 3, values: [1, 2, 3])
        wide.style.width = 300
        _ = context(Vec2(400, 100), VStack(alignment: .start, [wide]))
        #expect(wide.fields.map(\.shownText) == ["1.000", "2.000", "3.000"])
    }

    /// Small controls take clicks over the theme's `minimumHitSize` (24 pt), whatever their glyph.
    @Test func smallControlsHaveTwentyFourPointHitTargets() throws {
        let theme = UITheme()
        #expect(theme.minimumHitSize == 24 && theme.rowHeight >= theme.minimumHitSize)
        let box = Checkbox("")
        let parent = TreeNode("Parent", isExpanded: true)
        parent.addChild(TreeNode("Child"))
        let tree = TreeView(roots: [parent])
        tree.style.height = 120
        tree.style.width = 200
        let tabs = TabView(tabs: [DockPanel(id: "a", title: "Alpha", content: Label("A")), DockPanel(id: "b", title: "Beta", content: Label("B"))])
        tabs.style.width = 300
        tabs.style.height = 100
        let ui = context(Vec2(400, 400), VStack(alignment: .start, [box, tree, tabs]))
        #expect(box.frame.width >= 24 && box.frame.height >= 24)
        let close = try #require(tabs.closeButtonRect(0))
        #expect(close.width >= 24 && close.height >= 24 && tabs.tabRects[0].contains(close.center))
        let toggle = try #require(ui.accessibilityElements().first { $0.path.hasSuffix("toggle:Parent") })
        #expect(toggle.frame.width >= 24 && toggle.frame.height >= 24)
        // A click in the widened part (left of the old 16-point column) still toggles.
        ui.synthesizeClick(at: Vec2(toggle.frame.x + 1, toggle.frame.center.y))
        #expect(!parent.isExpanded)
        // The close button's widened area closes too.
        ui.synthesizeClick(at: Vec2(close.x + 1, close.y + 1))
        #expect(tabs.tabs.count == 1)
    }

    /// A text field not being edited shows the start of a long text, ending in "…", with the
    /// whole text as its tooltip (#28).
    @Test func idleTextFieldShowsTheStartOfLongText() {
        let long = String(repeating: "A long entity name ", count: 6)
        let field = TextField(text: "")
        field.preferredWidth = 120
        let ui = context(Vec2(300, 100), VStack(alignment: .start, [field]))
        field.text = long  // the caret goes to the end
        ui.layoutIfNeeded()
        #expect(field.characterIndex(atX: field.contentRect.x + 1) == 0)
        #expect(field.tooltip(at: field.frame.center) == long)
        // While editing, the caret's end shows.
        ui.focus(field)
        _ = field.textInputCaretRect
        #expect(field.characterIndex(atX: field.contentRect.x + 1) > 0)
        #expect(field.tooltip(at: field.frame.center) == nil)
    }

    /// Panel content taller than the panel (a toolbar wrapped onto several rows) scrolls (#33),
    /// clipped under the tab bar.
    @Test func overflowingPanelContentScrolls() {
        let rows = VStack(spacing: 4, (0..<8).map { Button("Button \($0)") })
        let tabs = TabView(tabs: [DockPanel(id: "p", title: "Panel", content: rows)])
        tabs.style.width = 200
        tabs.style.height = 120
        let ui = context(Vec2(300, 300), VStack(alignment: .start, [tabs]))
        #expect(tabs.contentOverflow > 0)
        let last = rows.children.last!
        #expect(last.frame.maxY > tabs.contentArea.maxY)
        ui.synthesizeScroll(at: tabs.contentArea.center, by: Vec2(0, -1000))
        ui.layoutIfNeeded()
        #expect(tabs.contentOffset == tabs.contentOverflow)
        #expect(abs(last.frame.maxY - tabs.contentArea.maxY) < 0.5)
        // Revealing a widget scrolls it into view (ui.click, focus).
        #expect(tabs.scrollToReveal(rows.children[0].frame))
        ui.layoutIfNeeded()
        #expect(rows.children[0].frame.y >= tabs.contentArea.y - 0.5)
        // Content that fits doesn't scroll.
        let fits = TabView(tabs: [DockPanel(id: "q", title: "Q", content: Label("Short"))])
        fits.style.width = 200
        fits.style.height = 120
        _ = context(Vec2(300, 300), VStack(alignment: .start, [fits]))
        #expect(fits.contentOverflow == 0 && fits.contentOffset == 0)
    }

    /// A dock's dividers take the theme's color when they draw, so a dock built before it joins
    /// a context (or before the theme changes) isn't stuck with the default theme's (#32).
    @Test func dockDividersFollowTheTheme() throws {
        let dock = DockSpace()
        dock.addPanel(DockPanel(id: "a", title: "A", content: Label("A")))
        dock.addPanel(DockPanel(id: "b", title: "B", content: Label("B")))
        dock.restoreLayout(DockLayout(root: .split(axis: .horizontal, fractions: [0.5, 0.5], children: [.tabs(panels: ["a"], active: nil), .tabs(panels: ["b"], active: nil)])))
        let split = try #require(dock.descendant(named: "dockSplit") as? SplitView)
        #expect(split.dividerColor == nil && split.dividerUsesThemeColor)
        dock.gapColor = .white
        #expect((dock.descendant(named: "dockSplit") as? SplitView)?.dividerColor == .white)
    }

    /// Floating windows are kept wholly inside the dock when they fit, and shrunk to it when not.
    @Test func floatingWindowsStayInsideTheDock() throws {
        let dock = DockSpace()
        dock.style.width = 400
        dock.style.height = 300
        dock.addPanel(DockPanel(id: "a", title: "A", content: Label("A")))
        dock.addPanel(DockPanel(id: "f", title: "F", content: Label("F")))
        dock.restoreLayout(DockLayout(root: .tabs(panels: ["a"], active: nil), floating: [.init(frame: UIRect(x: 350, y: 250, width: 200, height: 500), panels: ["f"])]))
        _ = context(Vec2(400, 300), VStack(alignment: .start, [dock]))
        let window = try #require(dock.children.first { $0.name == "dockFloating" })
        #expect(window.frame.x >= dock.frame.x && window.frame.y >= dock.frame.y)
        #expect(window.frame.maxX <= dock.frame.maxX + 0.5 && window.frame.maxY <= dock.frame.maxY + 0.5, "\(window.frame)")
    }

    /// A label squeezed below `minimumTruncatedWidth` is still truncated (tooltip, accessibility) but draws nothing.
    @Test func labelHidesWhenSqueezedTooFar() {
        let label = Label("Untitled Scene")
        label.minimumTruncatedWidth = 64
        label.style.width = 30
        let ui = context(Vec2(200, 100), VStack(alignment: .start, [label]))
        #expect(label.isTruncated && label.tooltip(at: label.frame.center) == "Untitled Scene")
        let list = UIDrawList()
        list.beginFrame(framebufferSize: (200, 100), scale: 1)
        let before = list.vertices.count
        label.draw(list, theme: ui.theme)
        #expect(list.vertices.count == before)
        label.style.width = 90
        ui.layoutIfNeeded()
        label.draw(list, theme: ui.theme)
        #expect(list.vertices.count > before)
    }

    /// A panel's caption shows at the right of its tab bar, when there is room (the viewport's
    /// "Perspective · Move", which covered scene labels as a badge, #30).
    @Test func panelCaptionInTheTabBar() {
        let panel = DockPanel(id: "v", title: "Scene", content: Label("image"))
        panel.caption = "Perspective · Move"
        let tabs = TabView(tabs: [panel])
        tabs.style.width = 400
        tabs.style.height = 100
        let ui = context(Vec2(500, 200), VStack(alignment: .start, [tabs]))
        #expect(tabs.captionIsShown)
        tabs.style.width = 130
        ui.layoutIfNeeded()
        #expect(!tabs.captionIsShown)
    }

    /// A menu can check several items (the View menu's theme and zoom).
    @Test func popupMenuChecksSeveralItems() {
        let menu = PopupMenu(items: ["Dark", "Light", "100%", "200%"])
        menu.checkedIndices = [1, 3]
        let ui = context(Vec2(300, 300), VStack([]))
        ui.presentOverlay(menu)
        ui.layoutIfNeeded()
        let selected = ui.accessibilityElements().filter { $0.role == .menuItem && $0.isSelected }.map(\.label)
        #expect(selected == ["Light", "200%"])
    }
}
