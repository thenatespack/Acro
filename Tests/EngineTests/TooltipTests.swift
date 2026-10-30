import Testing
@testable import Engine

// MARK: Helpers

@MainActor private final class Driver {
    let input = Input()
    let ui = UIContext()
    let size = Vec2(400, 300)

    init() {
        ui.clipboard = MemoryClipboard()
        ui.setViewport(size: size, scale: 1)
    }

    func frame(_ body: (Input) -> Void = { _ in }) {
        input.beginFrame()
        body(input)
        input.endEvents()
        ui.update(input: input, dt: 1.0 / 60, viewportSize: size, scale: 1)
    }

    func move(to p: Vec2) { frame { $0.mousePosition = p } }
    func press(at p: Vec2) { frame { $0.mousePosition = p; $0.setButton(.left, down: true) } }
    func release() { frame { $0.setButton(.left, down: false) } }
    func scroll() { frame { $0.addScroll(Vec2(0, -10)) } }
    func key(_ key: Key) {
        frame {
            $0.recordKeyPress(key, modifiers: [], isRepeat: false)
            $0.textKeyEvent(key, modifiers: [], isRepeat: false)
        }
    }

    /// Advances `seconds` of frames without input.
    func wait(_ seconds: Double) { for _ in 0..<Int((seconds * 60).rounded(.up)) { frame() } }

    /// Moves the pointer onto `point` (from elsewhere, so it counts as moving) and waits past the delay.
    func hover(_ point: Vec2, wait seconds: Double = 0.6) {
        move(to: point + Vec2(1, 1))
        move(to: point)
        wait(seconds)
    }
}

@MainActor private func place(_ w: Widget, _ d: Driver, at origin: Vec2, width: Float = 80) {
    w.style.width = width
    w.style.position = .absolute(Anchors(left: origin.x, top: origin.y))
    d.ui.root.addChild(w)
    d.ui.layoutIfNeeded()
}

private final class Owner {}

/// A reference wrapper so the controller's mutating calls can sit inside `#expect`.
private final class Timing {
    var controller: TooltipController
    init(delay: Double = 0.5, switchWindow: Double = 0.4) { controller = TooltipController(delay: delay, switchWindow: switchWindow) }
    @discardableResult
    func update(time: Double, target: TooltipController.Target?) -> Bool { controller.update(time: time, target: target) }
    func dismiss(time: Double) { controller.dismiss(time: time) }
    var isShown: Bool { controller.isShown }
}

// MARK: Timing (pure)

@Test func tooltipAppearsAfterTheDelayOnly() {
    let timing = Timing(delay: 0.5)
    let owner = Owner()
    let target = TooltipController.Target(widget: ObjectIdentifier(owner), text: "Hi")
    #expect(!timing.update(time: 10, target: target))
    #expect(!timing.update(time: 10.49, target: target))
    #expect(timing.update(time: 10.5, target: target))
    #expect(timing.update(time: 12, target: target))
    // Leaving hides it.
    #expect(!timing.update(time: 12.1, target: nil))
}

@Test func movingBetweenTargetsSwitchesImmediatelyOnlyAfterOneWasShown() {
    let timing = Timing(delay: 0.5, switchWindow: 0.4)
    let a = Owner(), b = Owner(), c = Owner()
    func target(_ o: Owner) -> TooltipController.Target { .init(widget: ObjectIdentifier(o), text: "tip") }
    // Never shown: the new target waits.
    _ = timing.update(time: 0, target: target(a))
    #expect(!timing.update(time: 0.2, target: target(b)))
    #expect(!timing.update(time: 0.6, target: target(b)))
    #expect(timing.update(time: 0.75, target: target(b)))
    // Shown: the next one is shown at once, also through a gap of a few frames.
    #expect(timing.update(time: 0.8, target: target(a)))
    #expect(!timing.update(time: 0.85, target: nil))
    #expect(timing.update(time: 1.0, target: target(c)))
    // A long gap restores the delay.
    _ = timing.update(time: 1.1, target: nil)
    #expect(!timing.update(time: 3, target: target(a)))
    #expect(timing.update(time: 3.5, target: target(a)))
    // Another text on the same widget (a tab's close button) switches at once too.
    #expect(timing.update(time: 3.6, target: .init(widget: ObjectIdentifier(a), text: "other")))
}

@Test func dismissHidesTheTooltipAndRestartsTheTimer() {
    let timing = Timing(delay: 0.5)
    let a = Owner(), b = Owner()
    func target(_ o: Owner) -> TooltipController.Target { .init(widget: ObjectIdentifier(o), text: "tip") }
    _ = timing.update(time: 0, target: target(a))
    #expect(timing.update(time: 0.6, target: target(a)))
    timing.dismiss(time: 0.7)
    #expect(!timing.isShown)
    #expect(!timing.update(time: 0.8, target: nil))
    #expect(timing.update(time: 0.9, target: target(b)))  // another widget soon after: no delay
    timing.dismiss(time: 1)
    #expect(!timing.update(time: 9, target: target(a)))  // long after: the delay applies
    #expect(timing.update(time: 9.6, target: target(a)))
}

// MARK: Positioning (pure)

@Test func tooltipSitsBelowRightOfThePointer() {
    let viewport = UIRect(x: 0, y: 0, width: 400, height: 300)
    let box = TooltipLayout.frame(size: Vec2(100, 30), pointer: Vec2(50, 60), viewport: viewport)
    #expect(box == UIRect(x: 50 + TooltipLayout.offset.x, y: 60 + TooltipLayout.offset.y, width: 100, height: 30))
}

@Test func tooltipFlipsAtTheRightAndBottomEdges() {
    let viewport = UIRect(x: 0, y: 0, width: 400, height: 300)
    let right = TooltipLayout.frame(size: Vec2(100, 30), pointer: Vec2(380, 60), viewport: viewport)
    #expect(right.maxX <= 380 && right.x >= 4)  // left of the pointer
    #expect(right.y == 60 + TooltipLayout.offset.y)
    let bottom = TooltipLayout.frame(size: Vec2(100, 30), pointer: Vec2(50, 290), viewport: viewport)
    #expect(bottom.maxY <= 290 && bottom.x == 50 + TooltipLayout.offset.x)  // above the pointer
    let corner = TooltipLayout.frame(size: Vec2(100, 30), pointer: Vec2(399, 299), viewport: viewport)
    #expect(corner.maxX <= 399 && corner.maxY <= 299)
}

@Test func tooltipIsClampedInsideTheWindow() {
    let viewport = UIRect(x: 0, y: 0, width: 200, height: 100)
    // Wider than fits on either side of the pointer: pinned to the margin.
    let wide = TooltipLayout.frame(size: Vec2(180, 30), pointer: Vec2(100, 10), viewport: viewport)
    #expect(wide.x >= TooltipLayout.margin && wide.maxX <= 200 - TooltipLayout.margin)
    // Pointer above / left of the window.
    let outside = TooltipLayout.frame(size: Vec2(50, 20), pointer: Vec2(-30, -30), viewport: viewport)
    #expect(outside.x >= TooltipLayout.margin && outside.y >= TooltipLayout.margin)
}

@MainActor @Test func tooltipTextWrapsToTheThemesMaxWidth() {
    var theme = UITheme()
    theme.tooltipMaxWidth = 160
    let short = TooltipLayout.textLayout("Save", theme: theme)
    let long = TooltipLayout.textLayout(String(repeating: "wrap this tooltip text ", count: 8), theme: theme)
    #expect(long.height > short.height * 1.5)
    #expect(TooltipLayout.boxSize(for: long, theme: theme, scale: 1).x <= 160)
    let size = TooltipLayout.boxSize(for: short, theme: theme, scale: 1)
    #expect(size.x == short.width.rounded(.up) + 2 * theme.tooltipPadding.x)
    #expect(size.y == short.height + 2 * theme.tooltipPadding.y)
}

// MARK: Context behavior

@MainActor @Test func hoveredWidgetShowsItsTooltipAfterTheThemeDelay() {
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "Go somewhere"
    place(button, d, at: Vec2(20, 20))
    d.move(to: Vec2(10, 10))
    d.move(to: Vec2(40, 30))
    d.wait(0.3)
    #expect(d.ui.tooltipText == nil)
    d.wait(0.3)
    #expect(d.ui.tooltipText == "Go somewhere")
    let box = d.ui.tooltipFrame!
    #expect(box.x >= 40 && box.y >= 30)
    // The box stays where it appeared while the pointer moves inside the widget.
    d.move(to: Vec2(60, 35))
    #expect(d.ui.tooltipFrame == box)
    // It is drawn (a box and text beyond the button's own items).
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (400, 300), scale: 1)
    d.ui.draw(into: list)
    let items = list.stats.items
    d.ui.tooltipsEnabled = false
    d.frame()
    let list2 = UIDrawList()
    list2.beginFrame(framebufferSize: (400, 300), scale: 1)
    d.ui.draw(into: list2)
    #expect(items > list2.stats.items && d.ui.tooltipText == nil)

    var theme = d.ui.theme
    theme.tooltipDelay = 0.1
    d.ui.theme = theme
    d.ui.tooltipsEnabled = true
    d.move(to: Vec2(500, 500))
    d.hover(Vec2(40, 30), wait: 0.2)
    #expect(d.ui.tooltipText == "Go somewhere")
}

@MainActor @Test func tooltipHidesOnPressScrollKeyAndLeaving() {
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "tip"
    place(button, d, at: Vec2(20, 20))
    let inside = Vec2(40, 30)

    d.hover(inside)
    #expect(d.ui.tooltipText == "tip")
    d.press(at: inside)
    #expect(d.ui.tooltipText == nil)
    d.release()
    d.wait(1)
    #expect(d.ui.tooltipText == nil)  // stays hidden while over the same widget

    d.hover(Vec2(300, 200))
    d.hover(inside)
    #expect(d.ui.tooltipText == "tip")
    d.scroll()
    #expect(d.ui.tooltipText == nil)

    d.hover(Vec2(300, 200))
    d.hover(inside)
    #expect(d.ui.tooltipText == "tip")
    d.key(.a)
    #expect(d.ui.tooltipText == nil)

    d.hover(Vec2(300, 200))
    d.hover(inside)
    #expect(d.ui.tooltipText == "tip")
    d.move(to: Vec2(300, 200))
    #expect(d.ui.tooltipText == nil)
}

@MainActor @Test func tooltipHidesWhenItsWidgetHidesOrDisables() {
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "tip"
    place(button, d, at: Vec2(20, 20))
    d.hover(Vec2(40, 30))
    #expect(d.ui.tooltipText == "tip")
    button.isEnabled = false
    d.frame()
    #expect(d.ui.tooltipText == nil)
    button.isEnabled = true
    d.hover(Vec2(300, 200))
    d.hover(Vec2(40, 30))
    #expect(d.ui.tooltipText == "tip")
    button.isHidden = true
    d.frame()
    #expect(d.ui.tooltipText == nil)
}

@MainActor @Test func movingToAnotherTooltipWidgetSwitchesWithoutADelay() {
    let d = Driver()
    let a = Button("A"), b = Button("B"), plain = Button("C")
    a.tooltip = "first"
    b.tooltip = "second"
    place(a, d, at: Vec2(20, 20), width: 60)
    place(b, d, at: Vec2(100, 20), width: 60)
    place(plain, d, at: Vec2(180, 20), width: 60)
    d.hover(Vec2(40, 30))
    #expect(d.ui.tooltipText == "first")
    d.move(to: Vec2(90, 30))  // the gap between them
    d.move(to: Vec2(120, 30))
    #expect(d.ui.tooltipText == "second")
    d.move(to: Vec2(200, 30))  // no tooltip here
    #expect(d.ui.tooltipText == nil)
    d.move(to: Vec2(120, 30))
    #expect(d.ui.tooltipText == "second")
    // After a long pause the delay applies again.
    d.move(to: Vec2(200, 30))
    d.wait(2)
    d.move(to: Vec2(120, 30))
    #expect(d.ui.tooltipText == nil)
    d.wait(0.6)
    #expect(d.ui.tooltipText == "second")
}

@MainActor @Test func noTooltipWhileThePointerIsCaptured() {
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "tip"
    let slider = Slider(value: 0.5)
    slider.tooltip = "slide"
    place(button, d, at: Vec2(20, 20))
    place(slider, d, at: Vec2(20, 100), width: 200)
    d.move(to: Vec2(41, 31))
    d.press(at: Vec2(40, 30))  // the button captures the pointer
    d.wait(1)
    #expect(d.ui.capturedWidget === button && d.ui.tooltipText == nil)
    d.release()
    d.move(to: Vec2(120, 110))
    d.press(at: Vec2(120, 112))
    d.move(to: Vec2(140, 112))
    d.wait(1)
    #expect(d.ui.capturedWidget === slider && d.ui.tooltipText == nil)
    d.release()
}

@MainActor @Test func aPointerThatNeverMovesHoversNothing() {
    // Screenshot runs ignore input: the pointer stays at the origin.
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "tip"
    place(button, d, at: Vec2(0, 0))
    d.wait(2)
    #expect(d.ui.hoveredWidget === button)
    #expect(d.ui.tooltipText == nil)
}

@MainActor @Test func deepestWidgetWithATooltipWins() {
    let d = Driver()
    let outer = HStack(spacing: 10, padding: EdgeInsets(10), name: "outer")
    let tipped = Button("A"), bare = Button("B")
    tipped.tooltip = "child tip"
    outer.tooltip = "container tip"
    outer.addChildren([tipped, bare])
    place(outer, d, at: Vec2(20, 20), width: 200)
    let tippedPoint = tipped.frame.center, barePoint = bare.frame.center
    d.hover(tippedPoint)
    #expect(d.ui.tooltipText == "child tip")
    d.move(to: barePoint)
    #expect(d.ui.tooltipText == "container tip")
    // Hidden or disabled widgets are skipped on the way up.
    outer.tooltip = nil
    d.move(to: tippedPoint)
    #expect(d.ui.tooltipText == "child tip")
    tipped.isEnabled = false
    d.wait(1)
    #expect(d.ui.tooltipText == nil)
}

@MainActor @Test func tooltipDrawsAboveOverlays() {
    let d = Driver()
    let button = Button("Go")
    button.tooltip = "tip"
    place(button, d, at: Vec2(20, 20))
    let menu = PopupMenu(items: ["One", "Two"], anchor: button)
    d.ui.presentOverlay(menu)
    d.ui.layoutIfNeeded()
    // The menu isn't over the pointer; the tooltip is still produced beside it.
    d.hover(Vec2(300, 250))
    #expect(d.ui.tooltipText == nil)
    d.ui.dismissOverlay(menu)
    d.hover(Vec2(40, 30))
    #expect(d.ui.tooltipText == "tip")
}

// MARK: Truncation

@MainActor @Test func ellipsisFitsTextToAWidth() {
    let font = UIDrawList.defaultFont
    let text = "Receives Shadows"
    let full = TextMetrics.caretOffsets(text, font: font, size: 13).last!
    #expect(TextEllipsis.fit(text, font: font, size: 13, width: full) == nil)
    #expect(TextEllipsis.fit(text, font: font, size: 13, width: full + 5) == nil)
    let cut = TextEllipsis.fit(text, font: font, size: 13, width: full - 20)!
    #expect(cut.hasSuffix("\u{2026}") && cut.count < text.count)
    #expect(text.hasPrefix(String(cut.dropLast())))
    #expect(TextMetrics.caretOffsets(cut, font: font, size: 13).last! <= full - 20)
    // One more character wouldn't have fit.
    let longer = String(text.prefix(cut.count)) + "\u{2026}"
    #expect(TextMetrics.caretOffsets(longer, font: font, size: 13).last! > full - 20)
    // Nothing fits: just the mark.
    #expect(TextEllipsis.fit(text, font: font, size: 13, width: 3) == "\u{2026}")
}

@MainActor @Test func truncatedLabelOffersItsFullTextAsTheTooltip() {
    let d = Driver()
    let label = Label("Receives Shadows")
    place(label, d, at: Vec2(20, 20), width: 200)
    #expect(label.tooltip(at: Vec2(30, 25)) == nil && !label.isTruncated)
    #expect(d.ui.hitTest(Vec2(30, 25)) == nil)  // a label that fits lets the pointer through
    label.style.width = 60
    d.ui.layoutIfNeeded()
    #expect(label.isTruncated)
    #expect(label.tooltip(at: Vec2(30, 25)) == "Receives Shadows")
    d.hover(Vec2(30, 25))
    #expect(d.ui.tooltipText == "Receives Shadows")
    // An explicit tooltip wins; wrapping labels never truncate.
    label.tooltip = "Whether the mesh receives shadows"
    #expect(label.tooltip(at: Vec2(30, 25)) == "Whether the mesh receives shadows")
    label.tooltip = nil
    label.wraps = true
    d.ui.layoutIfNeeded()
    #expect(!label.isTruncated)
}

@MainActor @Test func truncatedTreeRowsAndListRowsShowTheirFullText() {
    let d = Driver()
    let tree = TreeView(roots: [TreeNode("A rather long entity name that cannot fit"), TreeNode("Short")])
    place(tree, d, at: Vec2(10, 10), width: 120)
    tree.style.height = 100
    d.ui.layoutIfNeeded()
    let first = tree.rowRect(0).center, second = tree.rowRect(1).center
    #expect(tree.tooltip(at: first) == "A rather long entity name that cannot fit")
    #expect(tree.tooltip(at: second) == nil)
    let list = ListView(items: ["Short", "Another quite long list entry here"])
    place(list, d, at: Vec2(200, 10), width: 100)
    list.style.height = 100
    d.ui.layoutIfNeeded()
    #expect(list.tooltip(at: list.rowRect(0).center) == nil)
    #expect(list.tooltip(at: list.rowRect(1).center) == "Another quite long list entry here")
    list.tooltip = "whole list"
    #expect(list.tooltip(at: list.rowRect(0).center) == "whole list")
}

@MainActor @Test func tabsNameTheirCloseButtonAndShowCutOffTitles() {
    let d = Driver()
    let long = DockPanel(id: "long", title: "An extremely long panel title", content: Widget())
    let short = DockPanel(id: "short", title: "Short", content: Widget(), isClosable: false)
    let tabs = TabView(tabs: [long, short])
    place(tabs, d, at: Vec2(10, 10), width: 140)
    tabs.style.height = 100
    d.ui.layoutIfNeeded()
    tabs.maxTabWidth = 90
    d.ui.layoutIfNeeded()
    let close = tabs.closeButtonRect(0)!.center
    #expect(tabs.tooltip(at: close) == "Close An extremely long panel title")
    let rects = tabs.tabRects
    #expect(tabs.tooltip(at: Vec2(rects[0].x + 12, rects[0].center.y)) == "An extremely long panel title")
    #expect(tabs.tooltip(at: rects[1].center) == nil)
    short.tooltip = "Explicit"
    #expect(tabs.tooltip(at: rects[1].center) == "Explicit")
    #expect(tabs.tooltip(at: Vec2(10, 200)) == nil)
}

// MARK: PropertyGrid

private struct Hinted: Component, Equatable {
    static let componentName = "Test.Hinted"
    static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(displayName: "Speed (m/s)", tooltip: "How fast it goes"),
         "veryLongFieldName": FieldHints(displayName: "A display name that is long"), "plain": FieldHints()]
    }
    var speed: Float = 1
    var veryLongFieldName: Float = 1
    var plain: Float = 1
}

@MainActor @Test func propertyGridHintTooltipsUseTheContextTooltip() {
    let d = Driver()
    let world = World()
    let e = world.spawn(Hinted())
    let grid = PropertyGrid(world: world)
    grid.labelWidth = 70
    d.ui.root.addChild(grid)
    grid.style.position = .absolute(Anchors(left: 0, top: 0, right: 0))
    grid.entity = e
    d.ui.layoutIfNeeded()
    func label(_ path: String) -> Widget? {
        grid.descendant(named: "row.Test.Hinted.\(path)")?.children.first
    }
    let speed = label("speed")!.frame.center
    d.hover(speed)
    #expect(d.ui.tooltipText == "How fast it goes")
    // Truncated labels without a hint show the display name.
    let long = label("veryLongFieldName")!.frame.center
    d.move(to: long)
    #expect(d.ui.tooltipText == "A display name that is long")
    // A label that fits and has no hint has none.
    d.move(to: label("plain")!.frame.center)
    #expect(d.ui.tooltipText == nil)
    // The grid doesn't draw anything of its own any more: no tooltip, no extra items.
    d.move(to: Vec2(300, 190))
    d.wait(1)
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (400, 300), scale: 1)
    d.ui.draw(into: list)
    #expect(d.ui.tooltipText == nil)
}
