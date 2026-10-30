import Testing
@testable import Engine

// MARK: Helpers

/// A widget with a fixed intrinsic size that records events and handles what `handles` says.
@MainActor private final class Probe: Widget {
    var size: Vec2
    var events: [UIEvent] = []
    var handles: (UIEvent) -> Bool = { _ in false }
    var focusable = false
    var focusChanges: [Bool] = []

    init(_ size: Vec2 = Vec2(10, 10), name: String = "") {
        self.size = size
        super.init(name: name)
    }

    override var acceptsFocus: Bool { focusable }
    override func measureContent(width: Float?) -> Vec2 { size }
    override func handleEvent(_ event: UIEvent) -> Bool {
        events.append(event)
        return handles(event)
    }
    override func focusChanged(_ focused: Bool) { focusChanges.append(focused) }
}

/// Drives a `UIContext` through a real `Input`, one frame at a time, like the engine does.
@MainActor private final class Driver {
    let input = Input()
    let ui: UIContext
    let size: Vec2
    let scale: Float
    let clipboard = MemoryClipboard()

    init(size: Vec2 = Vec2(400, 300), scale: Float = 1) {
        ui = UIContext()
        ui.clipboard = clipboard
        self.size = size
        self.scale = scale
        ui.setViewport(size: size, scale: scale)
    }

    func frame(_ body: (Input) -> Void = { _ in }) {
        input.beginFrame()
        body(input)
        input.endEvents()
        ui.update(input: input, dt: 1.0 / 60, viewportSize: size, scale: scale)
    }

    func move(to p: Vec2) { frame { $0.mousePosition = p } }

    func press(at p: Vec2, button: MouseButton = .left) {
        frame { $0.mousePosition = p; $0.setButton(button, down: true) }
    }

    func release(at p: Vec2? = nil, button: MouseButton = .left) {
        frame { if let p { $0.mousePosition = p }; $0.setButton(button, down: false) }
    }

    func click(at p: Vec2) {
        press(at: p)
        release()
    }

    /// A key as the platforms deliver it: in `keyPresses` always, as a text-input key event when routed.
    func key(_ key: Key, _ modifiers: KeyModifiers = [], isRepeat: Bool = false) {
        frame {
            $0.recordKeyPress(key, modifiers: modifiers, isRepeat: isRepeat)
            $0.textKeyEvent(key, modifiers: modifiers, isRepeat: isRepeat)
        }
    }

    func type(_ text: String) { frame { $0.commitText(text) } }
}

@MainActor private func center(_ w: Widget) -> Vec2 { w.frame.center }

// MARK: Layout math

@Test func flexGrowSharesFreeSpaceByWeight() {
    let sizes = UILayout.distribute([.init(base: 10, grow: 1), .init(base: 10, grow: 3), .init(base: 20)], available: 120)
    #expect(sizes == [30, 70, 20])
}

@Test func flexGrowFreezesItemsAtTheirMaxAndRedistributes() {
    let sizes = UILayout.distribute([.init(base: 0, max: 10, grow: 1), .init(base: 0, grow: 1)], available: 100)
    #expect(sizes == [10, 90])
}

@Test func flexShrinkIsWeightedByBaseAndStopsAtMin() {
    // 60 over: weights 100 and 50 take 40 and 20.
    #expect(UILayout.distribute([.init(base: 100, shrink: 1), .init(base: 50, shrink: 1)], available: 90) == [60, 30])
    // The first can't go below 90, so the second takes the rest.
    let sizes = UILayout.distribute([.init(base: 100, min: 90, shrink: 1), .init(base: 50, shrink: 1)], available: 100)
    #expect(sizes == [90, 10])
    // shrink 0 never shrinks (overflows instead).
    #expect(UILayout.distribute([.init(base: 100), .init(base: 50)], available: 100) == [100, 50])
}

@Test func justifyOffsets() {
    #expect(UILayout.justify(.start, free: 30, count: 3) == (0, 0))
    #expect(UILayout.justify(.center, free: 30, count: 3) == (15, 0))
    #expect(UILayout.justify(.end, free: 30, count: 3) == (30, 0))
    #expect(UILayout.justify(.spaceBetween, free: 30, count: 3) == (0, 15))
    #expect(UILayout.justify(.center, free: -10, count: 3) == (0, 0))
}

@Test func snappingRoundsToThePixelGrid() {
    #expect(UILayout.snap(10.2, scale: 1) == 10)
    #expect(UILayout.snap(10.3, scale: 2) == 10.5)
    #expect(UILayout.snap(10.74, scale: 2) == 10.5)
    #expect(UILayout.snap(33.3333, scale: 3) == 33 + 1.0 / 3)
}

// MARK: Stack layout

@MainActor @Test func verticalStackAppliesPaddingSpacingAndGrow() {
    let d = Driver()
    let a = Probe(Vec2(50, 20)), b = Probe(Vec2(60, 30)), c = Probe(Vec2(10, 0))
    c.style.grow = 1
    let stack = VStack(spacing: 10, padding: EdgeInsets(5), [a, b, c])
    d.ui.root.addChild(stack)
    d.ui.layoutIfNeeded()
    #expect(stack.frame == UIRect(x: 0, y: 0, width: 400, height: 300))
    #expect(a.frame == UIRect(x: 5, y: 5, width: 390, height: 20))
    #expect(b.frame == UIRect(x: 5, y: 35, width: 390, height: 30))
    #expect(c.frame == UIRect(x: 5, y: 75, width: 390, height: 220))
    #expect(stack.measure() == Vec2(70, 20 + 30 + 0 + 20 + 10))
}

@MainActor @Test func crossAlignmentAndAlignSelf() {
    let d = Driver()
    let a = Probe(Vec2(50, 20)), b = Probe(Vec2(60, 20)), c = Probe(Vec2(70, 20))
    b.style.alignSelf = .end
    c.style.alignSelf = .stretch
    let stack = VStack(alignment: .center, [a, b, c])
    d.ui.root.addChild(stack)
    d.ui.layoutIfNeeded()
    #expect(a.frame == UIRect(x: 175, y: 0, width: 50, height: 20))
    #expect(b.frame == UIRect(x: 340, y: 20, width: 60, height: 20))
    #expect(c.frame == UIRect(x: 0, y: 40, width: 400, height: 20))
}

@MainActor @Test func horizontalStackJustifiesAndCentersAcross() {
    let d = Driver()
    let a = Probe(Vec2(40, 10)), b = Probe(Vec2(40, 30))
    let stack = HStack(spacing: 0, [a, b])
    stack.justify = .spaceBetween
    d.ui.root.addChild(stack)
    d.ui.layoutIfNeeded()
    #expect(a.frame == UIRect(x: 0, y: 145, width: 40, height: 10))
    #expect(b.frame == UIRect(x: 360, y: 135, width: 40, height: 30))
    stack.justify = .center
    d.ui.layoutIfNeeded()
    #expect(a.frame.x == 160 && b.frame.x == 200)
}

@MainActor @Test func fixedAndMinMaxSizesClampMeasurement() {
    let p = Probe(Vec2(50, 50))
    p.style.maxWidth = 30
    p.style.minHeight = 80
    #expect(p.measure() == Vec2(30, 80))
    p.style.width = 100
    #expect(p.measure() == Vec2(30, 80))  // max still wins over a fixed width
    p.style.maxWidth = .infinity
    p.padding = EdgeInsets(horizontal: 5, vertical: 0)
    #expect(p.measure() == Vec2(100, 80))
    p.style.width = nil
    #expect(p.measure() == Vec2(60, 80))
}

@MainActor @Test func edgesSnapToPixelsAndStayContiguous() {
    let d = Driver(size: Vec2(100, 50), scale: 2)
    let items = (0..<3).map { _ -> Probe in
        let p = Probe(Vec2(0, 10))
        p.style.grow = 1
        return p
    }
    d.ui.root.addChild(HStack(alignment: .stretch, items))
    d.ui.layoutIfNeeded()
    #expect(items.map(\.frame.x) == [0, 33.5, 66.5])
    #expect(items.map(\.frame.width) == [33.5, 33, 33.5])
    for i in 0..<2 { #expect(items[i].frame.maxX == items[i + 1].frame.x) }
    for item in items { #expect((item.frame.x * 2).rounded() == item.frame.x * 2) }
}

@MainActor @Test func layoutIsDeterministicAcrossRuns() {
    func run() -> [UIRect] {
        let d = Driver(size: Vec2(333, 211), scale: 1.5)
        let probes = (0..<7).map { i -> Probe in
            let p = Probe(Vec2(Float(i * 7 % 13) + 0.3, 11.7))
            p.style.grow = Float(i % 3)
            p.style.shrink = 1
            return p
        }
        d.ui.root.addChild(HStack(spacing: 3.3, padding: EdgeInsets(2.2), probes))
        d.ui.layoutIfNeeded()
        return probes.map(\.frame)
    }
    #expect(run() == run())
}

@MainActor @Test func absoluteChildrenFollowAnchors() {
    let d = Driver()
    let badge = Probe(Vec2(20, 10)), fill = Probe(), centered = Probe(Vec2(40, 40))
    badge.style.position = .absolute(Anchors(top: 4, right: 6))
    fill.style.position = .absolute(.fill(inset: 10))
    centered.style.position = .absolute(.centered)
    let flow = Probe(Vec2(30, 30))
    let stack = VStack([flow, badge, fill, centered])
    d.ui.root.addChild(stack)
    d.ui.layoutIfNeeded()
    #expect(badge.frame == UIRect(x: 374, y: 4, width: 20, height: 10))
    #expect(fill.frame == UIRect(x: 10, y: 10, width: 380, height: 280))
    #expect(centered.frame == UIRect(x: 180, y: 130, width: 40, height: 40))
    #expect(flow.frame.y == 0)  // absolute children take no space in the stack
    #expect(stack.measure().y == 30)
}

@MainActor @Test func hiddenChildrenTakeNoSpace() {
    let d = Driver()
    let a = Probe(Vec2(10, 20)), b = Probe(Vec2(10, 20)), c = Probe(Vec2(10, 20))
    let stack = VStack(spacing: 5, [a, b, c])
    d.ui.root.addChild(stack)
    b.isHidden = true
    d.ui.layoutIfNeeded()
    #expect(c.frame.y == 25)
}

@MainActor @Test func wrappingLabelsGetTallerWhenNarrower() {
    let label = Label("The quick brown fox jumps over the lazy dog again and again")
    label.wraps = true
    let wide = label.measure(width: 1000)
    let narrow = label.measure(width: 100)
    #expect(narrow.y > wide.y * 2)
    #expect(narrow.x <= 100)
    label.text = "x"
    #expect(label.measure(width: 100).y == wide.y)  // the cache was invalidated
}

// MARK: Scroll view

@MainActor @Test func scrollViewExtentsClampAndOffsetContent() {
    let d = Driver(size: Vec2(200, 100))
    let content = Probe(Vec2(150, 1000))
    let scroll = ScrollView(content)
    d.ui.root.addChild(scroll)
    d.ui.layoutIfNeeded()
    #expect(scroll.scroll.maxOffset == 900)
    #expect(content.frame == UIRect(x: 0, y: 0, width: 200, height: 1000))
    scroll.scroll(to: 5000)
    d.ui.layoutIfNeeded()
    #expect(scroll.offset == 900 && content.frame.y == -900)
    // Wheel: positive y scrolls up.
    d.move(to: Vec2(50, 50))
    d.frame { $0.addScroll(Vec2(0, 40)) }
    #expect(scroll.offset == 860 && content.frame.y == -860)
    #expect(d.ui.wantsPointer)
    // Short content doesn't scroll.
    content.size = Vec2(10, 50)
    content.setNeedsLayout()
    d.ui.layoutIfNeeded()
    #expect(scroll.scroll.maxOffset == 0 && scroll.offset == 0)
}

@MainActor @Test func scrollbarThumbDrags() {
    let d = Driver(size: Vec2(200, 100))
    let scroll = ScrollView(Probe(Vec2(150, 400)))
    d.ui.root.addChild(scroll)
    d.ui.layoutIfNeeded()
    let track = ScrollbarInteraction.track(for: scroll.contentRect, theme: d.ui.theme)
    let thumb = scroll.scroll.thumb(in: track)!
    #expect(thumb.height == track.height / 4)
    d.press(at: Vec2(thumb.center.x, thumb.y + 2))
    d.move(to: Vec2(thumb.center.x, track.maxY + 50))  // past the end: clamps
    #expect(scroll.offset == 300)
    d.release()
    #expect(d.ui.capturedWidget == nil)
}

@MainActor @Test func draggingContentScrolls() {
    let d = Driver(size: Vec2(200, 100))
    let scroll = ScrollView(Probe(Vec2(150, 400)))
    d.ui.root.addChild(scroll)
    d.press(at: Vec2(50, 80))
    d.move(to: Vec2(50, 30))
    #expect(scroll.offset == 50)
    d.release()
}

// MARK: Hit testing

@MainActor @Test func hitTestingFindsTheDeepestFrontmostVisibleWidget() {
    let d = Driver()
    let back = Probe(Vec2(100, 100), name: "back"), front = Probe(Vec2(100, 100), name: "front")
    let container = Widget(name: "container")
    container.addChildren([back, front])
    d.ui.root.addChild(container)
    d.ui.layoutIfNeeded()
    #expect(d.ui.hitTest(Vec2(10, 10)) === front)
    front.isHidden = true
    #expect(d.ui.hitTest(Vec2(10, 10)) === back)
    back.isHitTestable = false
    #expect(d.ui.hitTest(Vec2(10, 10)) === container)
    container.isHitTestable = false
    #expect(d.ui.hitTest(Vec2(10, 10)) == nil)  // the root lets clicks through
}

// MARK: Events

@MainActor @Test func buttonsActivateOnReleaseInside() {
    let d = Driver()
    var clicks = 0
    let button = Button("OK") { clicks += 1 }
    button.style.position = .absolute(Anchors(left: 10, top: 10))
    d.ui.root.addChild(button)
    d.ui.layoutIfNeeded()
    d.click(at: center(button))
    #expect(clicks == 1)
    d.press(at: center(button))
    #expect(button.isPressed)
    d.move(to: Vec2(390, 290))
    #expect(!button.isPressed && d.ui.capturedWidget === button)
    d.release()
    #expect(clicks == 1)  // released outside
    #expect(d.ui.focusedWidget === button)
    d.key(.space)
    d.key(.enter)
    #expect(clicks == 3)
}

@MainActor @Test func captureSendsDragsOutsideTheFrame() {
    let d = Driver()
    let slider = Slider(value: 0.5, in: 0...10)
    slider.style.position = .absolute(Anchors(left: 100, top: 0))
    slider.style.width = 100
    d.ui.root.addChild(slider)
    d.ui.layoutIfNeeded()
    d.press(at: center(slider))
    #expect(abs(slider.value - 5) < 0.01)
    d.move(to: Vec2(390, 280))
    #expect(slider.value == 10)
    d.move(to: Vec2(0, 280))
    #expect(slider.value == 0)
    d.release()
}

@MainActor @Test func eventsBubbleToAncestorsAndSkipDisabledOnes() {
    let d = Driver()
    let child = Probe(name: "child"), middle = Probe(Vec2(50, 50), name: "middle"), outer = Probe(Vec2(50, 50), name: "outer")
    child.focusable = true
    middle.addChild(child)
    outer.addChild(middle)
    outer.handles = { if case .key = $0 { true } else { false } }
    d.ui.root.addChild(outer)
    d.ui.focus(child)
    d.key(.f5)
    func keys(_ p: Probe) -> Int { p.events.filter { if case .key = $0 { true } else { false } }.count }
    #expect(keys(child) == 1 && keys(middle) == 1 && keys(outer) == 1)
    middle.isEnabled = false  // disables the child too: focus is dropped
    #expect(d.ui.focusedWidget == nil)
    d.ui.layoutIfNeeded()
    // A press on the disabled pair bubbles past them.
    outer.handles = { if case .pointerDown = $0 { true } else { false } }
    let before = middle.events.count
    d.press(at: Vec2(5, 5))
    #expect(middle.events.count == before && d.ui.capturedWidget === outer)
    d.release()
}

@MainActor @Test func pressesOutsideWidgetsBelongToTheGame() {
    let d = Driver()
    let probe = Probe(Vec2(100, 100))
    probe.handles = { _ in true }
    probe.style.position = .absolute(Anchors(left: 0, top: 0))
    d.ui.root.addChild(probe)
    d.move(to: Vec2(50, 50))
    #expect(d.ui.wantsPointer && d.ui.hoveredWidget === probe && probe.isHovered)
    d.move(to: Vec2(300, 200))
    #expect(!d.ui.wantsPointer && !probe.isHovered)
    // A camera drag that starts outside and crosses the widget stays the game's.
    d.press(at: Vec2(300, 200))
    #expect(!d.ui.wantsPointer)
    d.move(to: Vec2(50, 50))
    #expect(!d.ui.wantsPointer && d.ui.hoveredWidget == nil)
    d.release()
    d.move(to: Vec2(51, 50))
    #expect(d.ui.wantsPointer)
    #expect(!probe.events.contains { if case .pointerDown = $0 { true } else { false } })
}

@MainActor @Test func doubleClicksAreCounted() {
    let d = Driver()
    let probe = Probe(Vec2(100, 100))
    probe.handles = { _ in true }
    d.ui.root.addChild(probe)
    d.click(at: Vec2(10, 10))
    d.click(at: Vec2(11, 10))
    d.click(at: Vec2(11, 11))
    let counts = probe.events.compactMap { if case .pointerDown(let e) = $0 { e.clickCount } else { nil } }
    #expect(counts == [1, 2, 3])
    for _ in 0..<40 { d.frame() }  // wait past the interval
    d.click(at: Vec2(11, 11))
    #expect(probe.events.compactMap { if case .pointerDown(let e) = $0 { e.clickCount } else { nil } }.last == 1)
}

@MainActor @Test func keyboardIsLeftToTheGameWithoutFocus() {
    let d = Driver()
    let button = Button("A")
    d.ui.root.addChild(button)
    d.key(.tab)
    #expect(d.ui.focusedWidget == nil && !d.ui.wantsKeyboard)
    d.ui.focus(button)
    d.key(.w)
    #expect(d.ui.wantsKeyboard)
    // Esc unfocuses, and the frame still reports the keyboard as taken (the game mustn't quit).
    d.key(.escape)
    #expect(d.ui.focusedWidget == nil && d.ui.wantsKeyboard)
    d.frame()
    #expect(!d.ui.wantsKeyboard)
}

// MARK: Focus

@MainActor @Test func tabCyclesFocusableWidgetsInTreeOrder() {
    let d = Driver()
    let a = Button("a"), b = Checkbox("b"), hidden = Button("hidden"), disabled = Button("disabled"), c = TextField(), label = Label("x")
    hidden.isHidden = true
    disabled.isEnabled = false
    d.ui.root.addChild(VStack([a, HStack([b, hidden, label]), disabled, c]))
    #expect(d.ui.focusOrder.map(ObjectIdentifier.init) == [a, b, c].map(ObjectIdentifier.init))
    d.ui.focus(a)
    d.key(.tab)
    #expect(d.ui.focusedWidget === b && d.ui.focusVisible)
    d.key(.tab)
    #expect(d.ui.focusedWidget === c)
    d.key(.tab)  // the text field doesn't take Tab: it wraps around
    #expect(d.ui.focusedWidget === a)
    d.key(.tab, .shift)
    #expect(d.ui.focusedWidget === c)
}

@MainActor @Test func clickingFocusesTheNearestFocusableAncestor() {
    let d = Driver()
    let list = ListView(items: ["a", "b"])
    list.style.position = .absolute(Anchors(left: 0, top: 0))
    let field = TextField()
    field.style.position = .absolute(Anchors(left: 200, top: 0))
    d.ui.root.addChildren([list, field])
    d.ui.layoutIfNeeded()
    d.click(at: Vec2(10, 10))
    #expect(d.ui.focusedWidget === list && !d.ui.focusVisible)
    d.click(at: center(field))
    #expect(d.ui.focusedWidget === field)
    d.click(at: Vec2(300, 280))  // empty space: focus cleared, and the press is the game's
    #expect(d.ui.focusedWidget == nil)
}

@MainActor @Test func keyboardFocusScrollsTheWidgetIntoView() {
    let d = Driver(size: Vec2(200, 100))
    let buttons = (0..<10).map { Button("\($0)") }
    let scroll = ScrollView(VStack(spacing: 4, buttons))
    d.ui.root.addChild(scroll)
    d.ui.focus(buttons[0])
    for _ in 0..<7 { d.key(.tab) }
    #expect(d.ui.focusedWidget === buttons[7])
    #expect(buttons[7].frame.maxY <= 100 && buttons[7].frame.y >= 0 && scroll.offset > 0)
    d.key(.tab, .shift)
    d.ui.focus(buttons[0], visible: true)
    #expect(scroll.offset == 0)
}

// MARK: Text editing

@Test func editBufferInsertsDeletesAndReplacesSelections() {
    var b = TextEditBuffer("hello")
    #expect(b.caret == 5)
    b.insert(" world")
    #expect(b.text == "hello world")
    b.setCaret(5)
    b.setCaret(11, extend: true)
    #expect(b.selectedText == " world")
    b.insert("!")
    #expect(b.text == "hello!" && b.caret == 6 && !b.hasSelection)
    b.deleteBackward()
    #expect(b.text == "hello")
    b.moveToStart()
    b.deleteForward()
    #expect(b.text == "ello" && b.caret == 0)
    b.insert("line\none\r\ntwo\t")
    #expect(b.text == "line one twoello")  // newlines become spaces, tabs are dropped
    b.moveRight(extend: true)
    b.moveRight(extend: true)
    #expect(b.selectedText == "el")
    b.moveLeft()  // collapses to the selection start
    #expect(b.caret == 12 && !b.hasSelection)
}

@Test func editBufferJumpsAndDeletesByWord() {
    var b = TextEditBuffer("foo bar_baz, qux")
    b.moveLeft(by: .word)
    #expect(b.caret == 13)
    b.moveLeft(by: .word)
    #expect(b.caret == 4)
    b.moveRight(by: .word)
    #expect(b.caret == 11)
    b.moveRight(by: .word, extend: true)
    #expect(b.selectedText == ", qux")
    b.setCaret(11)
    b.deleteBackward(by: .word)
    #expect(b.text == "foo , qux" && b.caret == 4)
    b.deleteForward(by: .word)
    #expect(b.text == "foo ")
    b.deleteBackward(by: .line)
    #expect(b.text.isEmpty)
    var w = TextEditBuffer("one two three")
    w.selectWord(at: 5)
    #expect(w.selectedText == "two")
    w.selectWord(at: 3)
    #expect(w.selectedText == " ")
}

@Test func editBufferCountsGraphemeClusters() {
    var b = TextEditBuffer("a👍🏽e\u{301}z")  // emoji with skin tone, e + combining acute
    #expect(b.count == 4)
    b.moveLeft()
    b.deleteBackward()
    #expect(b.text == "a👍🏽z" && b.caret == 2)
    b.deleteBackward()
    #expect(b.text == "az" && b.caret == 1)
    // A combining mark typed after a letter joins it.
    b.setCaret(1)
    b.insert("\u{308}")
    #expect(b.text == "a\u{308}z" && b.count == 2 && b.caret == 1)
    // Character offsets agree with the UTF-16 helpers the platform text input uses.
    let s = "👍🏽e\u{301}x"
    let buffer = TextEditBuffer(s)
    #expect(TextOffsets.utf16Offset(ofCharacter: 2, in: buffer.text) == 6)
    #expect(TextOffsets.characterOffset(ofUTF16: 6, in: buffer.text, roundUp: false) == 2)
}

@Test func editBufferHonorsMaxLength() {
    var b = TextEditBuffer("abc", maxLength: 5)
    b.insert("defgh")
    #expect(b.text == "abcde")
    b.selectAll()
    b.insert("0123456789")
    #expect(b.text == "01234")
}

@MainActor @Test func caretOffsetsMatchTextLayout() {
    let font = UIDrawList.defaultFont
    let text = "AVa Wo"
    let offsets = TextMetrics.caretOffsets(text, font: font, size: 20)
    let layout = TextLayout(text, font: font, size: 20)
    #expect(offsets.count == 7)
    // Each glyph sits at the boundary before its character (the space has no glyph quad but a position).
    for (i, glyph) in layout.glyphs.enumerated() { #expect(abs(glyph.x - offsets[i]) < 1e-3) }
    #expect(abs(offsets[6] - layout.width) < 1e-3)
    #expect(TextMetrics.nearestBoundary(to: -5, in: offsets) == 0)
    #expect(TextMetrics.nearestBoundary(to: offsets[3] + 0.1, in: offsets) == 3)
    #expect(TextMetrics.nearestBoundary(to: 1000, in: offsets) == 6)
}

@MainActor @Test func textFieldEditsEndToEnd() {
    let d = Driver()
    var changes: [String] = []
    var submitted: String?
    let field = TextField(text: "hello") { changes.append($0) }
    field.onSubmit = { submitted = $0 }
    field.style.position = .absolute(Anchors(left: 10, top: 10))
    d.ui.root.addChild(field)
    d.ui.layoutIfNeeded()

    // Clicking focuses and starts text input at the caret.
    d.click(at: Vec2(field.contentRect.maxX - 2, field.frame.center.y))
    #expect(d.ui.focusedWidget === field && d.input.isTextInputActive)
    #expect(field.buffer.caret == 5)
    let caret = field.textInputCaretRect
    #expect(d.input.textInputRect == TextInputRect(x: caret.x, y: caret.y, width: caret.width, height: caret.height))
    #expect(caret.x > field.contentRect.x)

    d.type(" world")
    #expect(field.text == "hello world" && changes == ["hello world"])
    d.key(.left, [.shift])
    d.key(.left, [.shift, TextField.wordModifier])
    #expect(field.buffer.selectedText == "world")
    d.key(.c, .shortcut)
    #expect(d.clipboard.string == "world")
    d.key(.x, .shortcut)
    #expect(field.text == "hello " && d.clipboard.string == "world")
    d.key(.home)
    d.key(.v, .shortcut)
    #expect(field.text == "worldhello ")
    d.key(.a, .shortcut)
    d.key(.backspace)
    #expect(field.text.isEmpty)
    d.type("ok")
    d.key(.enter)
    #expect(submitted == "ok")
    // The text field doesn't take Esc: focus clears and text input stops.
    d.key(.escape)
    #expect(d.ui.focusedWidget == nil && !d.input.isTextInputActive)
    // Keys reach the game again.
    d.frame { $0.setKey(.w, down: true) }
    #expect(d.input.wasPressed(.w) && !d.ui.wantsKeyboard)
}

@MainActor @Test func textFieldMouseSelection() {
    let d = Driver()
    let field = TextField(text: "alpha beta gamma")
    field.preferredWidth = 300
    field.style.position = .absolute(Anchors(left: 0, top: 0))
    d.ui.root.addChild(field)
    d.ui.layoutIfNeeded()
    let offsets = TextMetrics.caretOffsets(field.text, font: d.ui.theme.font, size: d.ui.theme.fontSize)
    let x = { (i: Int) in field.contentRect.x + offsets[i] }
    // Drag from boundary 6 to 10 selects "beta".
    d.press(at: Vec2(x(6), 10))
    d.move(to: Vec2(x(10), 10))
    d.release()
    #expect(field.buffer.selectedText == "beta")
    // Shift-click extends.
    d.frame { $0.mousePosition = Vec2(x(16), 10); $0.setKey(.leftShift, down: true); $0.setButton(.left, down: true) }
    d.frame { $0.setButton(.left, down: false); $0.setKey(.leftShift, down: false) }
    #expect(field.buffer.selectedText == "beta gamma")
    for _ in 0..<40 { d.frame() }
    // Double click selects a word, triple everything.
    d.click(at: Vec2(x(2), 10))
    d.click(at: Vec2(x(2), 10))
    #expect(field.buffer.selectedText == "alpha")
    d.click(at: Vec2(x(2), 10))
    #expect(field.buffer.selectedText == "alpha beta gamma")
}

@MainActor @Test func textFieldShowsTheComposition() {
    let d = Driver()
    let field = TextField(text: "ab")
    d.ui.root.addChild(field)
    d.ui.focus(field)
    d.frame()
    #expect(d.input.isTextInputActive)
    d.frame { $0.setComposition("かな", selectedUTF16: 2..<2) }
    #expect(d.ui.composition?.text == "かな")
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (400, 300), scale: 1)
    d.ui.draw(into: list)  // draws the composed text and its underline without trapping
    d.frame { $0.commitText("かな") }
    #expect(field.text == "abかな" && d.ui.composition == nil)
}

// MARK: Controls

@MainActor @Test func sliderStepsAndKeys() {
    let slider = Slider(value: 0.37, in: 0...1, step: 0.25)
    #expect(slider.value == 0.25)
    #expect(slider.quantize(0.9) == 1 && slider.quantize(-3) == 0)
    let d = Driver()
    var reported: [Float] = []
    slider.onChange = { reported.append($0) }
    d.ui.root.addChild(slider)
    d.ui.focus(slider)
    d.key(.right)
    d.key(.right)
    #expect(slider.value == 0.75)
    d.key(.right)
    d.key(.right)  // clamped: no change reported
    #expect(slider.value == 1 && reported == [0.5, 0.75, 1])
    d.key(.home)
    #expect(slider.value == 0)
    let fine = Slider(value: 50, in: 0...100)
    #expect(fine.keyboardStep == 1)
    d.ui.root.addChild(fine)
    d.ui.focus(fine)
    d.key(.pageUp)
    #expect(fine.value == 60)
    d.key(.left, .shift)
    #expect(fine.value == 50)
}

@MainActor @Test func checkboxTogglesWithClickAndKeys() {
    let d = Driver()
    var states: [Bool] = []
    let box = Checkbox("x") { states.append($0) }
    box.style.position = .absolute(Anchors(left: 0, top: 0))
    d.ui.root.addChild(box)
    d.ui.layoutIfNeeded()
    d.click(at: center(box))
    d.key(.space)
    d.key(.space, isRepeat: true)  // repeats don't toggle
    #expect(states == [true, false] && !box.isOn)
}

@MainActor @Test func dropdownOpensSelectsAndCloses() {
    let d = Driver()
    var picked: [Int] = []
    let dropdown = Dropdown(options: ["one", "two", "three"]) { picked.append($0) }
    dropdown.style.position = .absolute(Anchors(left: 10, top: 10))
    var behind = 0
    let button = Button("behind") { behind += 1 }
    button.style.position = .absolute(Anchors(left: 10, top: 50))
    d.ui.root.addChildren([dropdown, button])
    d.ui.layoutIfNeeded()

    d.click(at: center(dropdown))
    #expect(dropdown.isOpen && d.ui.overlays.count == 1)
    let menu = dropdown.menu!
    #expect(menu.frame.y >= dropdown.frame.maxY && menu.frame.width >= dropdown.frame.width)
    // The menu overlaps the button; clicking an item picks it, not the button.
    let row2 = Vec2(menu.contentRect.center.x, menu.contentRect.y + menu.contentRect.height * 5 / 6)
    d.move(to: row2)
    #expect(menu.highlightedIndex == 2)
    d.click(at: row2)
    #expect(picked == [2] && dropdown.selectedIndex == 2 && !dropdown.isOpen && behind == 0)

    // Keyboard: Down opens, Up moves, Enter picks; Esc closes without picking.
    d.ui.focus(dropdown)
    d.key(.down)
    #expect(dropdown.isOpen)
    d.key(.up)
    d.key(.enter)
    #expect(picked == [2, 1] && !dropdown.isOpen)
    d.key(.space)
    d.key(.escape)
    #expect(!dropdown.isOpen && d.ui.focusedWidget === dropdown)

    // An outside press only closes the menu.
    dropdown.open()
    d.press(at: Vec2(390, 290))
    #expect(!dropdown.isOpen && d.ui.wantsPointer)  // the game doesn't see the closing press
    d.release()
    #expect(d.ui.focusedWidget === dropdown)
    dropdown.open()
    d.click(at: Vec2(10, 280))
    #expect(behind == 0)
}

@MainActor @Test func escClosesAnOverlayBeforeUnfocusing() {
    let d = Driver()
    let field = TextField()
    let dropdown = Dropdown(options: ["a"])
    d.ui.root.addChild(VStack([field, dropdown]))
    d.ui.focus(field)
    dropdown.open()
    d.frame()
    d.key(.escape)
    #expect(!dropdown.isOpen && d.ui.focusedWidget === field)
    d.key(.escape)
    #expect(d.ui.focusedWidget == nil)
}

@MainActor @Test func listNavigatesAndVirtualizes() {
    let d = Driver()
    let list = ListView(items: (0..<10_000).map { "row \($0)" })
    list.style.height = 104  // 100 points of rows inside 2 points of padding
    list.rowHeight = 20
    var selections: [Int?] = []
    list.onSelect = { selections.append($0) }
    d.ui.root.addChild(VStack([list]))
    d.ui.layoutIfNeeded()
    #expect(list.visibleRows == 0..<5)
    d.click(at: Vec2(50, 2 + 45))
    #expect(list.selectedRow == 2)
    d.key(.end)
    #expect(list.selectedRow == 9999 && list.visibleRows == 9995..<10_000)
    d.key(.up)
    d.key(.pageUp)
    #expect(list.selectedRow == 9994)
    d.key(.home)
    #expect(list.selectedRow == 0 && list.scroll.offset == 0)
    #expect(selections == [2, 9999, 9998, 9994, 0])
    // Drawing only touches visible rows.
    let drawList = UIDrawList()
    drawList.beginFrame(framebufferSize: (400, 300), scale: 1)
    d.ui.draw(into: drawList)
    #expect(drawList.stats.items < 200)
}

@MainActor @Test func treeExpandsCollapsesAndNavigates() {
    let leaf = TreeNode("leaf")
    let child = TreeNode("child", children: [leaf])
    let root = TreeNode("root", isExpanded: true, children: [child, TreeNode("sibling")])
    let tree = TreeView(roots: [root])
    #expect(tree.visibleNodes.map(\.title) == ["root", "child", "sibling"])
    let d = Driver()
    d.ui.root.addChild(tree)
    d.ui.focus(tree)
    tree.select(child)
    d.key(.right)  // expands
    #expect(tree.visibleNodes.map(\.title) == ["root", "child", "leaf", "sibling"])
    d.key(.right)  // steps into the first child
    #expect(tree.selectedNode === leaf)
    d.key(.left)  // leaf: to the parent
    #expect(tree.selectedNode === child)
    d.key(.left)  // collapses
    #expect(tree.visibleNodes.count == 3 && tree.selectedNode === child)
    d.key(.enter)  // toggles
    #expect(child.isExpanded)
    tree.select(nil)
    root.isExpanded = false
    tree.reloadData()
    tree.select(leaf)  // expands ancestors to reveal it
    #expect(root.isExpanded && tree.selectedNode === leaf)
}

@MainActor @Test func treeDisclosureClickToggles() {
    let d = Driver()
    let child = TreeNode("child", children: [TreeNode("leaf")])
    let tree = TreeView(roots: [TreeNode("root", isExpanded: true, children: [child])])
    tree.style.position = .absolute(Anchors(left: 0, top: 0))
    d.ui.root.addChild(tree)
    d.ui.layoutIfNeeded()
    let h = tree.effectiveRowHeight
    let content = tree.contentRect
    // The disclosure triangle of row 1 (depth 1).
    d.click(at: Vec2(content.x + 4 + d.ui.theme.treeIndent * 1.5, content.y + h * 1.5))
    #expect(child.isExpanded && tree.rowCount == 3)
}

@Test func colorConversions() {
    let c = UIColor(hex: 0x3fa7d6)
    #expect(c.hexString == "#3FA7D6")
    #expect(UIColor(hexString: "#3fa7d6") == c)
    #expect(UIColor(hexString: "fff") == UIColor(hex: 0xffffff))
    #expect(UIColor(hexString: "nope") == nil)
    let hsv = HSV(c)
    #expect(hsv.color().hexString == "#3FA7D6")
    #expect(HSV(UIColor(1, 0, 0)) == HSV(h: 0, s: 1, v: 1))
    #expect(HSV(h: 2.0 / 3, s: 1, v: 1).color().hexString == "#0000FF")
}

@MainActor @Test func colorPickerDragsAndParsesHex() {
    let d = Driver()
    var colors: [UIColor] = []
    let picker = ColorPicker(color: UIColor(1, 0, 0)) { colors.append($0) }
    picker.style.position = .absolute(Anchors(left: 0, top: 0))
    d.ui.root.addChild(picker)
    d.ui.layoutIfNeeded()
    // Bottom-left of the square: black.
    d.press(at: Vec2(picker.contentRect.x + 0.5, picker.contentRect.y + picker.squareSize - 0.01))
    d.release()
    #expect(colors.last.map { $0.hexString } == "#000000")
    #expect(picker.hexField.text == "#000000")
    picker.hexField.text = "#00ff00"
    d.ui.focus(picker.hexField)
    d.key(.enter)
    #expect(picker.color.hexString == "#00FF00")
}

// MARK: Text in the draw list

@MainActor @Test func drawTextEmitsSDFGlyphQuadsBatchedWithShapes() {
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (400, 300), scale: 2)
    list.fillRect(UIRect(x: 0, y: 0, width: 10, height: 10), color: .white)
    list.drawText("Hi there", at: Vec2(10.3, 20.2), size: 16, color: UIColor(1, 0.5, 0))
    list.fillRect(UIRect(x: 0, y: 0, width: 10, height: 10), color: .white)
    // 7 glyphs (the space has no quad) between two rects, all in one batch on the glyph page.
    #expect(list.stats.items == 9)
    #expect(list.batches.count == 1)
    if case .glyphPage(0)? = list.batches[0].source {} else { Issue.record("expected the glyph page") }
    let glyph = list.vertices[4]
    let smoothing = UIDrawList.sdfSmoothing(pixelSize: 32)
    #expect(glyph.params == Vec4(0, 3, smoothing, 0))
    #expect(glyph.color == Vec4(1, 0.5, 0, 1))  // sRGB, as given
    // The origin snaps to pixels (10.3 pt * 2 = 20.6 px -> 21).
    let layout = TextLayout("Hi there", font: UIDrawList.defaultFont, size: 16)
    let info = list.glyphAtlas.info(for: layout.glyphs[0].glyph, in: UIDrawList.defaultFont)!
    #expect(abs(glyph.position.x - (21 + info.offset.x * 32)) < 1e-3)
    // An image in between starts a new batch, and so does more text after it.
    list.drawImage(FakeWidgetTexture(), in: UIRect(x: 0, y: 0, width: 4, height: 4))
    list.drawText("x", at: .zero, size: 12, color: .white)
    #expect(list.batches.count == 3)
    #expect(list.glyphAtlas.pageCount == 1)
}

@MainActor private final class FakeWidgetTexture: GPUTexture {
    var width = 4, height = 4
    var format = TextureFormat.rgba8Unorm
    var mipLevelCount = 1
}

@MainActor @Test func paintingCullsWidgetsOutsideTheClip() {
    let d = Driver(size: Vec2(200, 100))
    let rows = (0..<200).map { i -> Label in Label("Row \(i)") }
    let scroll = ScrollView(VStack(rows))
    d.ui.root.addChild(scroll)
    let list = UIDrawList()
    list.beginFrame(framebufferSize: (200, 100), scale: 1)
    d.ui.draw(into: list)
    // Only the handful of rows inside the viewport produce glyphs.
    #expect(list.stats.items < 120)
    #expect(d.ui.stats.paintedItems == list.stats.items)
}
