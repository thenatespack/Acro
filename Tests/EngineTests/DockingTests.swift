import Foundation
import Testing
@testable import Engine

// Split views, tab views, the dock space and two-axis scrolling.

/// A widget with a fixed intrinsic size.
@MainActor private final class Box: Widget {
    var size: Vec2
    init(_ size: Vec2 = Vec2(10, 10), name: String = "") {
        self.size = size
        super.init(name: name)
    }
    override func measureContent(width: Float?) -> Vec2 { size }
}

/// Drives a `UIContext` through a real `Input`, one frame at a time.
@MainActor private final class Driver {
    let input = Input()
    let ui = UIContext()
    var size: Vec2

    init(size: Vec2 = Vec2(800, 600)) {
        self.size = size
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
    func press(at p: Vec2, button: MouseButton = .left) { frame { $0.mousePosition = p; $0.setButton(button, down: true) } }
    func release(at p: Vec2? = nil, button: MouseButton = .left) {
        frame { if let p { $0.mousePosition = p }; $0.setButton(button, down: false) }
    }
    func click(at p: Vec2, button: MouseButton = .left) {
        press(at: p, button: button)
        release(button: button)
    }
    /// Press, move in a few steps, release.
    func drag(from a: Vec2, to b: Vec2, steps: Int = 4) {
        press(at: a)
        for i in 1...steps { move(to: a + (b - a) * (Float(i) / Float(steps))) }
        release()
    }
    func key(_ key: Key, _ modifiers: KeyModifiers = []) {
        frame {
            $0.recordKeyPress(key, modifiers: modifiers, isRepeat: false)
            $0.textKeyEvent(key, modifiers: modifiers, isRepeat: false)
        }
    }
}

// MARK: Split math

@Test func splitSizesFollowFractionsAndHoldMinimums() {
    #expect(SplitLayout.sizes(fractions: [0.25, 0.75], minSizes: [0, 0], available: 400) == [100, 300])
    // The first pane would get 40 but needs 100; the others share the rest 1:2.
    let held = SplitLayout.sizes(fractions: [0.1, 0.3, 0.6], minSizes: [100, 0, 0], available: 400)
    #expect(zip(held, [Float(100), 100, 200]).allSatisfy { abs($0 - $1) < 1e-3 })
    // Minimums that don't fit are scaled down together.
    #expect(SplitLayout.sizes(fractions: [0.5, 0.5], minSizes: [300, 100], available: 200) == [150, 50])
    // Garbage fractions become equal shares.
    #expect(SplitLayout.normalized([.nan, -1], count: 2) == [0.5, 0.5])
    #expect(SplitLayout.normalized([1, 3], count: 3) == [0.25, 0.75, 0])
}

@Test func splitDraggingMovesOnlyNeighborsWithinMinimums() {
    let sizes: [Float] = [100, 200, 100]
    #expect(SplitLayout.dragging(sizes, divider: 0, by: 50, minSizes: [0, 0, 0]) == [150, 150, 100])
    #expect(SplitLayout.dragging(sizes, divider: 0, by: 500, minSizes: [0, 80, 0]) == [220, 80, 100])
    #expect(SplitLayout.dragging(sizes, divider: 1, by: -500, minSizes: [0, 30, 0]) == [100, 30, 270])
}

@MainActor @Test func splitViewDragsResetsAndKeepsProportionsOnResize() {
    let d = Driver(size: Vec2(404, 100))
    let a = Box(), b = Box()
    let split = SplitView(.horizontal, panes: [a, b], fractions: [1, 3], minSizes: [50, 50])
    var reported: [[Float]] = []
    split.onResize = { reported.append($0) }
    d.ui.root.addChild(split)
    d.ui.layoutIfNeeded()
    #expect(a.frame == UIRect(x: 0, y: 0, width: 100, height: 100))
    #expect(b.frame == UIRect(x: 104, y: 0, width: 300, height: 100))
    #expect(split.dividerRect(0) == UIRect(x: 100, y: 0, width: 4, height: 100))

    // Hovering the divider (or its slop) asks for a resize cursor; panes don't.
    d.move(to: Vec2(98, 50))
    #expect(d.ui.desiredCursor == .resizeLeftRight && d.ui.wantsPointer)
    d.move(to: Vec2(50, 50))
    #expect(d.ui.desiredCursor == .arrow)

    // Drag the divider; the right pane stops at its minimum.
    d.press(at: Vec2(102, 50))
    d.move(to: Vec2(202, 50))
    #expect(a.frame.width == 200 && b.frame.width == 200)
    d.move(to: Vec2(900, 50))
    #expect(b.frame.width == 50 && a.frame.width == 350)
    #expect(d.ui.desiredCursor == .resizeLeftRight)
    d.release()
    #expect(reported.last == [0.875, 0.125])

    // Window resize keeps the proportions.
    d.size = Vec2(804, 100)
    d.frame()
    #expect(a.frame.width == 700 && b.frame.width == 100)

    // Double-click resets.
    let divider = split.dividerRect(0).center
    d.click(at: divider)
    d.click(at: divider)
    #expect(split.fractions == [0.25, 0.75])
    #expect(a.frame.width == 200)
}

@MainActor @Test func verticalSplitSnapsEdgesContiguously() {
    let d = Driver(size: Vec2(100, 333))
    d.ui.setViewport(size: d.size, scale: 2)
    let panes = (0..<3).map { _ in Box() }
    let split = SplitView(.vertical, panes: panes)
    d.ui.root.addChild(split)
    d.ui.layoutIfNeeded()
    for p in panes { #expect((p.frame.y * 2).rounded() == p.frame.y * 2 && (p.frame.height * 2).rounded() == p.frame.height * 2) }
    #expect(panes[1].frame.y - panes[0].frame.maxY == 4 && panes[2].frame.y - panes[1].frame.maxY == 4)
    #expect(panes[2].frame.maxY == 333)
}

// MARK: Tabs

@MainActor private func panel(_ id: String, closable: Bool = true) -> DockPanel {
    DockPanel(id: id, title: id.capitalized, content: Box(name: id), isClosable: closable, minSize: Vec2(40, 40))
}

@MainActor @Test func tabViewSwitchesClosesAndCyclesWithKeys() {
    let d = Driver()
    let tabs = TabView(tabs: [panel("one"), panel("two"), panel("three", closable: false)])
    var selections: [Int] = []
    var closed: [String] = []
    tabs.onSelect = { selections.append($0) }
    tabs.onClose = { closed.append($0.id) }
    d.ui.root.addChild(tabs)
    d.ui.layoutIfNeeded()
    #expect(tabs.selectedIndex == 0)
    #expect(tabs.tabs[1].content.isHidden && !tabs.tabs[0].content.isHidden)
    #expect(tabs.tabs[0].content.frame == tabs.contentArea && tabs.contentArea.y == 28)

    d.click(at: tabs.tabRects[1].center)
    #expect(tabs.selectedIndex == 1 && selections == [1] && tabs.isFocused)
    #expect(tabs.tabs[0].content.isHidden && !tabs.tabs[1].content.isHidden)

    // Ctrl-Tab / Ctrl-Shift-Tab wrap; arrows work while the bar is focused.
    d.key(.tab, .control)
    #expect(tabs.selectedIndex == 2)
    d.key(.tab, .control)
    #expect(tabs.selectedIndex == 0)
    d.key(.tab, [.control, .shift])
    #expect(tabs.selectedIndex == 2)
    d.key(.left)
    #expect(tabs.selectedIndex == 1)
    #expect(tabs.closeButtonRect(2) == nil)

    // Close button of the selected tab; the next tab is selected.
    let close = tabs.closeButtonRect(1)!
    d.click(at: close.center)
    #expect(closed == ["two"] && tabs.tabs.map(\.id) == ["one", "three"] && tabs.selectedIndex == 1)
    // Middle click closes a closable tab.
    d.click(at: tabs.tabRects[0].center, button: .middle)
    #expect(closed == ["two", "one"] && tabs.tabs.map(\.id) == ["three"] && tabs.selectedIndex == 0)
}

@MainActor @Test func tabsReorderByDraggingAlongTheBar() {
    let d = Driver()
    let tabs = TabView(tabs: [panel("a"), panel("b"), panel("c")])
    var orders: [[String]] = []
    tabs.onReorder = { orders.append($0.map(\.id)) }
    d.ui.root.addChild(tabs)
    d.ui.layoutIfNeeded()
    let rects = tabs.tabRects
    d.drag(from: rects[0].center, to: Vec2(rects[2].maxX - 5, rects[2].center.y), steps: 8)
    #expect(tabs.tabs.map(\.id) == ["b", "c", "a"])
    #expect(tabs.selectedTab?.id == "a" && tabs.selectedIndex == 2)
    #expect(orders.last == ["b", "c", "a"])
}

@MainActor @Test func overflowingTabsShrinkThenScroll() {
    let d = Driver(size: Vec2(300, 200))
    let tabs = TabView(tabs: (0..<3).map { panel("panel\($0)") })
    d.ui.root.addChild(tabs)
    d.ui.layoutIfNeeded()
    // Three fit at their natural widths.
    #expect(tabs.tabRects.last!.maxX <= 300 && tabs.barOffset == 0)
    for i in 3..<10 { tabs.addTab(panel("panel\(i)"), select: false) }
    d.ui.layoutIfNeeded()
    // Ten don't: they shrink to the minimum width, and the strip scrolls.
    #expect(tabs.tabRects.allSatisfy { $0.width == tabs.minTabWidth })
    #expect(tabs.tabRects.last!.maxX > 300)
    d.move(to: Vec2(100, 10))
    d.frame { $0.addScroll(Vec2(0, -100)) }
    #expect(tabs.barOffset == 100 && d.ui.wantsPointer)
    // Selecting a tab scrolls it into view.
    tabs.select(9)
    d.ui.layoutIfNeeded()
    #expect(tabs.barOffset == 10 * tabs.minTabWidth - 300 && tabs.tabRects[9].maxX == 300)
}

// MARK: Dock tree

@MainActor private func makeDock(_ ids: [String]) -> DockSpace {
    let dock = DockSpace()
    for id in ids { dock.addPanel(panel(id)) }
    return dock
}

@MainActor @Test func dockingAtEdgesSplitsAndCenterAddsTabs() {
    let dock = makeDock(["a", "b", "c", "d", "e"])
    dock.dock("a", at: .edge(.left))
    #expect(dock.layout.root == .tabs(panels: ["a"], active: "a"))
    dock.dock("b", at: .tab(with: "a"))
    #expect(dock.layout.root == .tabs(panels: ["a", "b"], active: "b"))
    dock.dock("c", at: .split(beside: "a", edge: .right, fraction: 0.4))
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.6, 0.4], children: [
        .tabs(panels: ["a", "b"], active: "b"), .tabs(panels: ["c"], active: "c"),
    ]))
    // Same axis as the parent split: a sibling, not a nested split.
    dock.dock("d", at: .split(beside: "c", edge: .left))
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.6, 0.2, 0.2], children: [
        .tabs(panels: ["a", "b"], active: "b"), .tabs(panels: ["d"], active: "d"), .tabs(panels: ["c"], active: "c"),
    ]))
    // Another axis nests; an edge of the whole space wraps the root.
    dock.dock("e", at: .edge(.bottom, fraction: 0.25))
    guard case .split(.vertical, let fractions, let children)? = dock.layout.root else { Issue.record("no root split"); return }
    #expect(fractions == [0.75, 0.25] && children.last == .tabs(panels: ["e"], active: "e"))
    #expect(dock.openPanelIDs == ["a", "b", "d", "c", "e"])
}

@MainActor @Test func movingTabsBetweenGroupsAndClosingCollapses() {
    let dock = makeDock(["a", "b", "c"])
    dock.restoreLayout(DockLayout(root: .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a", "b"], active: "a"), .tabs(panels: ["c"], active: "c"),
    ])))
    var changes = 0
    var closed: [String] = []
    dock.onLayoutChange = { _ in changes += 1 }
    dock.panel("c")!.onClose = { closed.append("c") }

    // Move "b" into c's group at the front.
    dock.dock("b", at: .tab(with: "c", index: 0))
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a"], active: "a"), .tabs(panels: ["b", "c"], active: "b"),
    ]))
    // Moving the last tab out of a group removes the group and collapses the split.
    dock.dock("a", at: .tab(with: "c"))
    #expect(dock.layout.root == .tabs(panels: ["b", "c", "a"], active: "a"))
    // Closing works the same way.
    dock.dock("a", at: .split(beside: "b", edge: .top))
    dock.closePanel("c")
    dock.closePanel("b")
    #expect(dock.layout.root == .tabs(panels: ["a"], active: "a"))
    #expect(closed == ["c"] && changes == 2)
    #expect(!dock.isOpen("b") && dock.panel("b") != nil)
    dock.closePanel("a")
    #expect(dock.layout.root == nil && dock.openPanelIDs.isEmpty)
    // Reopening into an empty dock fills it.
    dock.dock("b", at: .tab(with: "nowhere"))
    #expect(dock.layout.root == .tabs(panels: ["b"], active: "b"))
}

@MainActor @Test func nestedSplitsOfTheSameAxisMergeWhenCollapsing() {
    let dock = makeDock(["a", "b", "c"])
    dock.restoreLayout(DockLayout(root: .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a"], active: "a"),
        .split(axis: .vertical, fractions: [0.5, 0.5], children: [
            .split(axis: .horizontal, fractions: [0.5, 0.5], children: [.tabs(panels: ["b"], active: nil), .tabs(panels: ["c"], active: nil)]),
            .tabs(panels: ["gone"], active: "gone"),
        ]),
    ])))
    // "gone" isn't registered: its group disappears, the vertical split collapses, and the
    // inner horizontal split merges into the root.
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.5, 0.25, 0.25], children: [
        .tabs(panels: ["a"], active: "a"), .tabs(panels: ["b"], active: "b"), .tabs(panels: ["c"], active: "c"),
    ]))
}

@MainActor @Test func layoutRoundTripsThroughJSONAndDropsUnknownPanels() throws {
    let dock = makeDock(["hierarchy", "scene", "console", "assets", "inspector", "color"])
    let layout = DockLayout(
        root: .split(axis: .horizontal, fractions: [0.25, 0.5, 0.25], children: [
            .tabs(panels: ["hierarchy"], active: "hierarchy"),
            .split(axis: .vertical, fractions: [0.75, 0.25], children: [
                .tabs(panels: ["scene"], active: "scene"),
                .tabs(panels: ["console", "assets"], active: "assets"),
            ]),
            .tabs(panels: ["inspector"], active: "inspector"),
        ]),
        floating: [DockLayout.Floating(frame: UIRect(x: 300, y: 80, width: 240, height: 200), panels: ["color"], active: "color")])
    dock.restoreLayout(layout)
    #expect(dock.layout == layout)

    let json = try layout.jsonData()
    let text = String(decoding: json, as: UTF8.self)
    #expect(text.contains("\"split\" : \"horizontal\"") && text.contains("\"frame\" : ["))
    #expect(try DockLayout.decode(json: json) == layout)

    // A layout saved by another version: unknown panels, a repeat, a bad active ID, a bad fraction count.
    let foreign = """
        {"version": 1,
         "root": {"split": "vertical", "fractions": [1], "children": [
             {"tabs": ["timeline", "console", "console"], "active": "timeline"},
             {"tabs": ["scene", "profiler"], "active": "profiler"},
             {"tabs": ["sequencer"]}]},
         "floating": [{"frame": [10, 10, 200, 100], "tabs": ["minimap"]},
                      {"frame": [20, 20, 200, 100], "tabs": ["color"], "active": "color"}]}
        """
    dock.restoreLayout(try DockLayout.decode(json: Data(foreign.utf8)))
    #expect(dock.layout.root == .split(axis: .vertical, fractions: [1, 0], children: [
        .tabs(panels: ["console"], active: "console"), .tabs(panels: ["scene"], active: "scene"),
    ]))
    #expect(dock.layout.floating == [DockLayout.Floating(frame: UIRect(x: 20, y: 20, width: 200, height: 100), panels: ["color"],
                                                         active: "color")])
    #expect(!dock.isOpen("hierarchy"))
    #expect(throws: DecodingError.self) { try DockLayout.decode(json: Data(#"{"root": {"split": "diagonal", "children": []}}"#.utf8)) }
}

// MARK: Dragging end to end

/// A dock filling an 800x600 viewport: "a" | "b" side by side.
@MainActor private func twoGroupDock(_ d: Driver) -> DockSpace {
    let dock = makeDock(["a", "b", "c"])
    dock.restoreLayout(DockLayout(root: .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a", "c"], active: "a"), .tabs(panels: ["b"], active: "b"),
    ])))
    d.ui.root.addChild(dock)
    d.ui.layoutIfNeeded()
    return dock
}

@MainActor private func group(_ dock: DockSpace, showing id: String) -> TabView {
    dock.panel(id)!.owner!
}

@MainActor @Test func draggingATabOntoAGroupEdgeSplitsIt() {
    let d = Driver()
    let dock = twoGroupDock(d)
    let source = group(dock, showing: "a"), target = group(dock, showing: "b")
    #expect(source.frame == UIRect(x: 0, y: 0, width: 398, height: 600) && target.frame.x == 402)

    d.press(at: source.tabRects[0].center)
    d.move(to: source.tabRects[0].center + Vec2(0, 60))
    d.move(to: Vec2(target.frame.center.x, target.contentArea.maxY - 30))  // the bottom quarter of b
    #expect(dock.isDraggingTab && d.ui.wantsPointer && d.ui.desiredCursor == .move)
    let preview = dock.dropPreview!
    #expect(preview == UIRect(x: 402, y: 300, width: 398, height: 300))
    d.release()
    #expect(!dock.isDraggingTab && dock.dropPreview == nil)
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["c"], active: "c"),
        .split(axis: .vertical, fractions: [0.5, 0.5], children: [.tabs(panels: ["b"], active: "b"), .tabs(panels: ["a"], active: "a")]),
    ]))
    #expect(dock.panel("a")!.content.frame.y > 300)
}

@MainActor @Test func draggingATabIntoAnotherBarInsertsItAtTheMarker() {
    let d = Driver()
    let dock = twoGroupDock(d)
    let source = group(dock, showing: "c"), target = group(dock, showing: "b")
    let tab = source.tabRects[1].center
    d.press(at: tab)
    d.move(to: tab + Vec2(0, 80))
    d.move(to: Vec2(target.tabRects[0].x + 4, target.barRect.center.y))  // before b's first tab
    if case .tab? = dock.dropTarget(at: d.ui.pointerPosition) {} else { Issue.record("expected a tab target") }
    #expect(dock.dropPreview == target.frame)
    d.release()
    #expect(dock.layout.root == .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a"], active: "a"), .tabs(panels: ["c", "b"], active: "c"),
    ]))
}

@MainActor @Test func draggingTheLastTabOutFloatsItAndEscCancels() {
    let d = Driver()
    let dock = twoGroupDock(d)
    var b = group(dock, showing: "b")
    // Esc cancels a drag in progress.
    d.press(at: b.tabRects[0].center)
    d.move(to: b.tabRects[0].center + Vec2(0, 100))
    d.move(to: Vec2(600, 300))
    d.key(.escape)
    #expect(!dock.isDraggingTab)
    d.release(at: Vec2(600, 300))
    #expect(dock.layout.floating.isEmpty)

    // Dropping onto the dragged group's own middle does nothing (no preview either).
    d.press(at: b.tabRects[0].center)
    d.move(to: b.tabRects[0].center + Vec2(0, 100))
    d.move(to: b.frame.center)
    #expect(dock.dropPreview == nil)
    // Outside the dock space it becomes a floating window; the emptied group collapses.
    dock.padding = EdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
    d.ui.layoutIfNeeded()
    d.move(to: Vec2(300, 550))
    #expect(dock.dropPreview != nil)
    d.release()
    #expect(dock.layout.root == .tabs(panels: ["a", "c"], active: "a"))
    #expect(dock.layout.floating.map(\.panels) == [["b"]])
    let window = dock.children.last!
    // Sized like the group it left (capped), moved up so all of it is inside the dock space.
    #expect(dock.layout.floating[0].frame == UIRect(x: 260, y: 180, width: 398, height: 320))
    #expect(window.frame == UIRect(x: 260, y: 180, width: 398, height: 320))

    // Floating windows move by their bar's empty part and sit above docked content.
    b = group(dock, showing: "b")
    let barSpot = Vec2(b.barRect.maxX - 10, b.barRect.center.y)
    let before = dock.layout.floating[0].frame
    d.drag(from: barSpot, to: barSpot + Vec2(-100, -100))
    #expect(dock.layout.floating[0].frame == before.offsetBy(Vec2(-100, -100)))
    // It can't be dragged so far up that its bar leaves the dock space.
    d.drag(from: barSpot + Vec2(-100, -100), to: barSpot + Vec2(-100, -400))
    #expect(dock.layout.floating[0].frame.y == 0)
    #expect(d.ui.hitTest(window.frame.center)?.isDescendant(of: window) == true)
}

@MainActor @Test func floatingWindowsResizeAndComeToTheFrontWhenClicked() {
    let d = Driver()
    let dock = makeDock(["a", "b", "c"])
    dock.restoreLayout(DockLayout(root: .tabs(panels: ["a"], active: "a"), floating: [
        DockLayout.Floating(frame: UIRect(x: 100, y: 100, width: 200, height: 150), panels: ["b"]),
        DockLayout.Floating(frame: UIRect(x: 150, y: 120, width: 200, height: 150), panels: ["c"]),
    ]))
    d.ui.root.addChild(dock)
    d.ui.layoutIfNeeded()
    // The bottom-right corner resizes with a diagonal cursor; it stops at the minimum size.
    d.move(to: Vec2(349, 269))
    #expect(d.ui.desiredCursor == .resizeDiagonal)
    d.drag(from: Vec2(349, 269), to: Vec2(399, 299))
    #expect(dock.layout.floating[1].frame == UIRect(x: 150, y: 120, width: 250, height: 180))
    d.drag(from: Vec2(399, 120), to: Vec2(100, 120))
    #expect(dock.layout.floating[1].frame.width == dock.minFloatingSize.x)
    // Clicking the window behind brings it to the front (and into the saved order).
    d.click(at: Vec2(110, 200))
    #expect(dock.layout.floating.map(\.panels) == [["c"], ["b"]])
    #expect(dock.children.last === group(dock, showing: "b").parent)
}

@MainActor @Test func draggingToTheDockEdgeDocksAlongTheWholeEdge() {
    let d = Driver()
    let dock = twoGroupDock(d)
    let b = group(dock, showing: "b")
    d.press(at: b.tabRects[0].center)
    d.move(to: b.tabRects[0].center + Vec2(0, 100))
    d.move(to: Vec2(400, 590))
    #expect(dock.dropPreview == UIRect(x: 0, y: 450, width: 800, height: 150))
    d.release()
    #expect(dock.layout.root == .split(axis: .vertical, fractions: [0.75, 0.25], children: [
        .tabs(panels: ["a", "c"], active: "a"), .tabs(panels: ["b"], active: "b"),
    ]))
}

@MainActor @Test func viewportPanelsPassClicksToTheGame() {
    let d = Driver()
    let dock = makeDock(["a"])
    let viewport = DockPanel(id: "scene", title: "Scene", content: Widget(), isClosable: false)
    viewport.content.isHitTestable = false
    viewport.passesPointerThrough = true
    dock.addPanel(viewport)
    dock.restoreLayout(DockLayout(root: .split(axis: .horizontal, fractions: [0.5, 0.5], children: [
        .tabs(panels: ["a"], active: "a"), .tabs(panels: ["scene"], active: "scene"),
    ])))
    d.ui.root.addChild(dock)
    d.ui.layoutIfNeeded()
    d.move(to: Vec2(600, 300))
    #expect(!d.ui.wantsPointer)
    d.move(to: Vec2(200, 300))
    #expect(d.ui.wantsPointer)
    d.move(to: Vec2(600, 10))  // the viewport's tab bar is UI
    #expect(d.ui.wantsPointer)
}

// MARK: Two-axis scrolling

@MainActor @Test func horizontalScrollingExtentsWheelAndBars() {
    let d = Driver(size: Vec2(200, 100))
    let content = Box(Vec2(500, 300))
    let scroll = ScrollView(content)
    scroll.scrollsHorizontally = true
    d.ui.root.addChild(scroll)
    d.ui.layoutIfNeeded()
    #expect(scroll.horizontalScroll.maxOffset == 300 && scroll.scroll.maxOffset == 200)
    #expect(content.frame == UIRect(x: 0, y: 0, width: 500, height: 300))

    d.move(to: Vec2(50, 50))
    // Trackpad x: positive scrolls left (towards the start).
    d.frame { $0.addScroll(Vec2(-40, 0)) }
    #expect(scroll.horizontalOffset == 40 && scroll.offset == 0 && content.frame.x == -40)
    // A vertical wheel stays vertical, with Shift it goes sideways.
    d.frame { $0.addScroll(Vec2(0, -30)) }
    #expect(scroll.offset == 30 && scroll.horizontalOffset == 40)
    d.frame { $0.setKey(.leftShift, down: true); $0.addScroll(Vec2(0, -30)) }
    #expect(scroll.horizontalOffset == 70 && scroll.offset == 30)
    d.frame { $0.setKey(.leftShift, down: false) }

    // The bottom bar's thumb drags; both bars stop short of the corner.
    let corner = d.ui.theme.scrollbarWidth + 2
    let track = ScrollbarInteraction.track(for: scroll.contentRect, theme: d.ui.theme, axis: .horizontal, corner: corner)
    #expect(track.width == 200 - 4 - corner)
    let thumb = scroll.horizontalScroll.thumb(in: track, axis: .horizontal)!
    d.press(at: thumb.center)
    d.move(to: Vec2(thumb.center.x + 500, thumb.center.y))
    #expect(scroll.horizontalOffset == 300 && scroll.offset == 30)
    d.release()
    // Dragging the content moves both ways.
    d.drag(from: Vec2(100, 50), to: Vec2(150, 70))
    #expect(scroll.horizontalOffset == 250 && scroll.offset == 10)
    // Narrow content doesn't scroll sideways and fills the viewport width.
    content.size = Vec2(120, 300)
    content.setNeedsLayout()
    d.ui.layoutIfNeeded()
    #expect(scroll.horizontalScroll.maxOffset == 0 && content.frame.width == 200)
}

@MainActor @Test func verticalOnlyScrollViewsIgnoreHorizontalDeltas() {
    let d = Driver(size: Vec2(200, 100))
    let content = Box(Vec2(500, 300))
    let scroll = ScrollView(content)
    d.ui.root.addChild(scroll)
    d.ui.layoutIfNeeded()
    #expect(content.frame.width == 200)
    d.move(to: Vec2(50, 50))
    d.frame { $0.addScroll(Vec2(-40, 0)) }
    #expect(scroll.offset == 0 && content.frame.x == 0)
}
