import Testing
@testable import Engine

// MARK: Helpers

@MainActor private final class Driver {
    let input = Input()
    let ui = UIContext()
    let size = Vec2(500, 600)

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
    func release(at p: Vec2? = nil) { frame { if let p { $0.mousePosition = p }; $0.setButton(.left, down: false) } }
    func click(at p: Vec2) { press(at: p); release() }
    func hold(_ key: Key) { frame { $0.setKey(key, down: true) } }
    func unhold(_ key: Key) { frame { $0.setKey(key, down: false) } }
    func key(_ key: Key, _ modifiers: KeyModifiers = []) {
        frame {
            $0.recordKeyPress(key, modifiers: modifiers, isRepeat: false)
            $0.textKeyEvent(key, modifiers: modifiers, isRepeat: false)
        }
    }
    func type(_ text: String) { frame { $0.commitText(text) } }

    /// Advances `n` frames without input (time passes; drags tick).
    func idle(_ n: Int) { for _ in 0..<n { frame() } }

    func drawFrame() {
        let list = UIDrawList()
        list.beginFrame(framebufferSize: (500, 600), scale: 1)
        ui.draw(into: list)
    }
}

@MainActor private func place(_ w: Widget, in d: Driver, width: Float = 100, at origin: Vec2 = Vec2(10, 10)) {
    w.style.width = width
    w.style.position = .absolute(Anchors(left: origin.x, top: origin.y))
    d.ui.root.addChild(w)
    d.ui.layoutIfNeeded()
}

// MARK: NumberField

@MainActor @Test func scrubRateScalesWithStepAndRange() {
    #expect(NumberField.scrubRate(step: 0, range: 0...100, isInteger: false) == 0.5)
    #expect(NumberField.scrubRate(step: 0.1, range: nil, isInteger: false) == 0.05)
    // A step that is small next to the range is raised to a 400th of the range.
    #expect(NumberField.scrubRate(step: 0.01, range: 0...100, isInteger: false) == 0.25)
    #expect(NumberField.scrubRate(step: 0, range: nil, isInteger: true) == 0.5)
    #expect(NumberField.scrubRate(step: 0, range: nil, isInteger: false, modifiers: .shift) == 0.05 * 0.1)
    #expect(NumberField.scrubRate(step: 0, range: nil, isInteger: false, modifiers: .alt) == 0.5)
}

@MainActor @Test func numberFieldScrubsAndReportsOneGesture() {
    let d = Driver()
    let field = NumberField(value: 10, range: 0...100)
    var log: [String] = []
    field.onEditBegan = { log.append("began \($0)") }
    field.onChange = { log.append("changed \($0)") }
    field.onEditEnded = { log.append("ended \($0) \($1)") }
    place(field, in: d)
    let c = field.frame.center
    d.press(at: c)
    d.move(to: c + Vec2(2, 0))  // under the threshold: still a press
    #expect(log.isEmpty && field.isInteracting)
    d.move(to: c + Vec2(40, 0))  // 40 pt * 0.5
    #expect(field.value == 30 && field.isScrubbing)
    d.move(to: c + Vec2(1000, 0))  // clamped
    #expect(field.value == 100)
    d.move(to: c + Vec2(900, 0))  // reversing leaves the clamp at once
    #expect(field.value == 50)
    d.release()
    #expect(log.first == "began 10.0" && log.last == "ended 10.0 50.0")
    #expect(log.filter { $0.hasPrefix("began") }.count == 1 && !field.isTyping)
}

@MainActor @Test func scrubModifiersAndIntegerRounding() {
    let d = Driver()
    let field = NumberField(value: 0, isInteger: true)
    place(field, in: d)
    let c = field.frame.center
    d.press(at: c)
    d.move(to: c + Vec2(10, 0))
    #expect(field.value == 5)
    d.hold(.leftAlt)  // coarse: x10
    d.move(to: c + Vec2(11, 0))
    #expect(field.value == 10)  // 5 + 1 * 5
    d.unhold(.leftAlt)
    d.hold(.leftShift)  // fine: a tenth of 0.5
    d.move(to: c + Vec2(20, 0))
    #expect(field.value == 10)  // 9 pt * 0.05 = 0.45 rounds away
    d.release()
}

@MainActor @Test func escapeDuringScrubRestoresTheValue() {
    let d = Driver()
    let field = NumberField(value: 4, range: 0...100)
    var ended: (Double, Double)?
    field.onEditEnded = { ended = ($0, $1) }
    place(field, in: d)
    let c = field.frame.center
    d.press(at: c)
    d.move(to: c + Vec2(30, 0))
    #expect(field.value != 4)
    d.key(.escape)
    #expect(field.value == 4 && ended?.0 == 4 && ended?.1 == 4)
    d.move(to: c + Vec2(60, 0))
    d.release()
    #expect(field.value == 4)
}

@MainActor @Test func clickTypesAnExactValueAndEnterCommits() {
    let d = Driver()
    let field = NumberField(value: 1.5, range: -10...10, name: "n")
    var log: [String] = []
    field.onEditBegan = { log.append("began \($0)") }
    field.onChange = { log.append("changed \($0)") }
    field.onEditEnded = { log.append("ended \($0) \($1)") }
    place(field, in: d)
    d.click(at: field.frame.center)
    #expect(field.isTyping && d.ui.focusedWidget is TextField)
    #expect((d.ui.focusedWidget as? TextField)?.text == "1.5")
    d.type("25")  // replaces the selection; out of range
    d.key(.enter)
    #expect(field.value == 10 && !field.isTyping && d.ui.focusedWidget === field)
    #expect(log == ["began 1.5", "changed 10.0", "ended 1.5 10.0"])
    // Escape cancels.
    d.key(.enter)
    #expect(field.isTyping)
    d.type("3")
    d.key(.escape)
    #expect(field.value == 10 && !field.isTyping && d.ui.focusedWidget === field && log.count == 3)
}

@MainActor @Test func invalidTypedInputRevertsAndFocusLossCommits() {
    let d = Driver()
    let field = NumberField(value: 7, isInteger: true)
    var changes = 0
    field.onChange = { _ in changes += 1 }
    let other = Button("x")
    place(field, in: d)
    place(other, in: d, at: Vec2(10, 100))
    d.click(at: field.frame.center)
    d.type("abc")
    d.key(.enter)
    #expect(field.value == 7 && changes == 0)
    d.click(at: field.frame.center)
    d.type("12.6")
    d.click(at: other.frame.center)  // leaving commits (rounded for integers)
    #expect(field.value == 13 && changes == 1 && !field.isTyping)
}

@MainActor @Test func arrowKeysNudgeAndModifiersScale() {
    let d = Driver()
    let field = NumberField(value: 1, range: 0...3, step: 0.5)
    var ends: [(Double, Double)] = []
    field.onEditEnded = { ends.append(($0, $1)) }
    place(field, in: d)
    d.ui.focus(field)
    d.key(.up)
    #expect(field.value == 1.5 && ends.count == 1)
    d.key(.up, .alt)  // x10, clamped
    #expect(field.value == 3)
    d.key(.down, .shift)  // x0.1
    #expect(field.value == 2.95)
    d.key(.down)
    #expect(field.value == 2.45)
}

@MainActor @Test func setValueWaitsWhileEditing() {
    let d = Driver()
    let field = NumberField(value: 1)
    place(field, in: d)
    field.setValue(2)
    #expect(field.value == 2)
    d.press(at: field.frame.center)
    field.setValue(9)
    #expect(field.value == 2)
    d.release()  // typing now
    field.setValue(9)
    #expect(field.value == 2)
    d.key(.escape)
    field.setValue(9)
    #expect(field.value == 9)
}

@MainActor @Test func numberFieldFormatting() {
    let f = NumberField(value: 0, range: nil, step: 0.0001)
    #expect(f.effectivePrecision == 4)
    #expect(f.displayString(for: -0.00001) == "0.0000")
    #expect(NumberField(isInteger: true).displayString(for: 41.6) == "42")
}

// MARK: VectorField

@MainActor @Test func vectorFieldGroupsComponentGestures() {
    let d = Driver()
    let v = VectorField(count: 3, values: [1, 2, 3], range: 0...100, name: "v")
    var log: [String] = []
    v.onEditBegan = { log.append("began \($0)") }
    v.onChange = { log.append("changed \($0)") }
    v.onEditEnded = { log.append("ended \($0) \($1)") }
    place(v, in: d, width: 300)
    #expect(v.fields.count == 3 && v.fields[0].prefix == "X" && v.fields[2].prefix == "Z")
    #expect(v.fields[0].prefixColor != v.fields[1].prefixColor)
    #expect(abs(v.fields[0].frame.width - v.fields[1].frame.width) <= 1)
    let c = v.fields[1].frame.center
    d.press(at: c)
    d.move(to: c + Vec2(20, 0))
    d.release()
    #expect(log.first == "began [1.0, 2.0, 3.0]")
    #expect(log.last == "ended [1.0, 2.0, 3.0] [1.0, 12.0, 3.0]")
    #expect(log.filter { $0.hasPrefix("began") }.count == 1)
    v.vec3 = Vec3(5, 6, 7)
    #expect(v.values == [5, 6, 7])
    #expect(VectorField(count: 2).fields.count == 2 && VectorField(count: 9).fields.count == 4)
}

// MARK: PropertyGrid

private enum Mode: String, Codable, CaseIterable { case fast, slow }
private struct Inner: Codable, Equatable { var a = 1; var b: Float = 2 }

private struct Everything: Component, Equatable {
    static let componentName = "Test.Everything"
    static var fieldHints: [String: FieldHints] {
        ["amount": FieldHints(range: 0...10, step: 0.5), "tint": FieldHints(color: true), "rgba": FieldHints(color: true), "locked": FieldHints(readOnly: true),
         "secret": FieldHints(hidden: true), "speed": FieldHints(displayName: "Speed (m/s)", tooltip: "How fast")]
    }
    var flag = true
    var count = 3
    var amount: Float = 2
    var name = "abc"
    var uv = Vec2(1, 2)
    var pos = Vec3(1, 2, 3)
    var tint = Vec3(0.5, 0.25, 0.1)
    var rgba = Vec4(1, 0, 0, 0.5)
    var rot = Quat(eulerDegrees: Vec3(0, 90, 0))
    var mode = Mode.slow
    var inner = Inner()
    var list = [1.0, 2.0, 3.0]
    var other = Entity.invalid
    var locked = 5
    var secret = 1
    var speed: Float = 1
    var maybe: Float?
}

private struct Marker: Component, Equatable {
    static let componentName = "Test.Marker"
    var label = "m"
}

@MainActor private func gridSetup() -> (Driver, World, Entity, PropertyGrid) {
    let d = Driver()
    let world = World()
    let e = world.spawn(Transform(position: Vec3(1, 2, 3)), Everything())
    let grid = PropertyGrid(world: world)
    d.ui.root.addChild(grid)
    grid.style.position = .absolute(Anchors(left: 0, top: 0, right: 0))
    grid.entity = e
    d.ui.layoutIfNeeded()
    return (d, world, e, grid)
}

@MainActor @Test func gridBuildsAnEditorForEveryKind() {
    let (_, _, _, grid) = gridSetup()
    #expect(grid.componentNames == ["Transform", "Test.Everything"])
    func find<T: Widget>(_ path: String, _ type: T.Type) -> T? { grid.descendant(named: "Test.Everything.\(path)") as? T }
    func label(_ path: String) -> FieldLabel? {
        grid.descendant(named: "row.Test.Everything.\(path)")?.children.compactMap { $0 as? FieldLabel }.first
    }
    #expect(find("flag", Checkbox.self)?.isOn == true)
    #expect(find("count", NumberField.self)?.isInteger == true)
    let amount = find("amount", NumberField.self)
    #expect(amount?.range == 0...10 && amount?.step == 0.5)
    #expect(find("name", TextEditor.self)?.field.text == "abc")
    #expect(find("uv", VectorField.self)?.fields.count == 2)
    #expect(find("pos", VectorField.self)?.values == [1, 2, 3])
    #expect(find("tint", ColorSwatch.self) != nil && find("rgba", ColorSwatch.self) != nil)
    #expect(find("rot", VectorField.self)?.values.map { Int($0.rounded()) } == [0, 90, 0])
    #expect(find("mode", Dropdown.self)?.selectedOption == "slow")
    #expect(find("inner.a", NumberField.self) != nil)
    #expect(grid.descendant(named: "group.Test.Everything.inner") != nil)
    #expect(find("list.1", NumberField.self)?.isEnabled == false)  // array elements are read-only
    #expect(find("other", Label.self)?.text == "None")
    #expect(find("maybe", Label.self)?.text == "—")
    // Hints: read-only disables, hidden skips, display names replace titles.
    #expect(find("locked", NumberField.self)?.isEnabled == false)
    #expect(grid.descendant(named: "Test.Everything.secret") == nil)
    #expect(label("speed")?.text == "Speed (m/s)" && label("speed")?.tooltip == "How fast")
    #expect(label("flag")?.text == "Flag")
}

@MainActor @Test func gridRoutesEditsWithOldAndNewValues() {
    let (d, world, e, grid) = gridSetup()
    var edits: [PropertyEdit] = []
    grid.onFieldEdit = { edits.append($0) }
    // A checkbox is a whole edit: began, changed, ended.
    (grid.descendant(named: "Test.Everything.flag") as? Checkbox)?.toggle()
    #expect(edits.map(\.phase) == [.began, .changed, .ended])
    #expect(edits.allSatisfy { $0.oldValue == .bool(true) && $0.path == "flag" && $0.componentName == "Test.Everything" && $0.entity == e })
    #expect(edits.last?.newValue == .bool(false))
    #expect(world.get(Everything.self, for: e)?.flag == false)

    // A scrub is one began, many changed, one ended; the world follows live.
    edits = []
    let field = grid.descendant(named: "Test.Everything.pos.y") as! NumberField
    let c = field.frame.center
    d.press(at: c)
    d.move(to: c + Vec2(10, 0))
    #expect(world.get(Everything.self, for: e)!.pos.y > 2)
    d.move(to: c + Vec2(20, 0))
    d.release()
    #expect(edits.first?.phase == .began && edits.last?.phase == .ended)
    #expect(edits.filter { $0.phase == .began }.count == 1 && edits.filter { $0.phase == .changed }.count >= 2)
    #expect(edits.allSatisfy { $0.oldValue == .vec3(Vec3(1, 2, 3)) && $0.path == "pos" })
    guard case .vec3(let final)? = edits.last?.newValue else { Issue.record("no vec3"); return }
    #expect(final.x == 1 && final.y > 2.5 && world.get(Everything.self, for: e)?.pos == final)

    // The owner can take over applying.
    grid.appliesEditsToWorld = false
    edits = []
    (grid.descendant(named: "Test.Everything.mode") as? Dropdown)?.onChange?(0)
    #expect(edits.last?.newValue == .enumCase("fast") && edits.last?.oldValue == .enumCase("slow"))
    #expect(world.get(Everything.self, for: e)?.mode == .slow)
    grid.refresh()
    #expect((grid.descendant(named: "Test.Everything.mode") as? Dropdown)?.selectedOption == "slow")  // snaps back
}

@MainActor @Test func gridRefreshesValuesWithoutRebuilding() {
    let (_, world, e, grid) = gridSetup()
    let field = grid.descendant(named: "Test.Everything.count") as! NumberField
    let vector = grid.descendant(named: "Test.Everything.pos") as! VectorField
    world.modify(Everything.self, for: e) { $0.count = 9; $0.pos = Vec3(4, 5, 6); $0.name = "xyz"; $0.mode = .fast }
    grid.refresh()
    #expect(field.value == 9 && vector.values == [4, 5, 6])
    #expect(grid.descendant(named: "Test.Everything.count") === field && grid.descendant(named: "Test.Everything.pos") === vector)
    #expect((grid.descendant(named: "Test.Everything.name") as? TextEditor)?.field.text == "xyz")
    #expect((grid.descendant(named: "Test.Everything.mode") as? Dropdown)?.selectedOption == "fast")
    // A shape change (an optional gaining a value) rebuilds the section.
    world.modify(Everything.self, for: e) { $0.maybe = 2 }
    grid.refresh()
    #expect(grid.descendant(named: "Test.Everything.maybe") is NumberField)
    // A component added to the entity rebuilds the section list.
    world.add(Marker(), to: e)
    grid.refresh()
    #expect(grid.componentNames.last == "Test.Marker")
}

@MainActor @Test func gridKeepsFocusAndTypedTextAcrossRefreshes() {
    let (d, world, e, grid) = gridSetup()
    let field = grid.descendant(named: "Test.Everything.count") as! NumberField
    d.click(at: field.frame.center)
    d.type("41")
    let typing = d.ui.focusedWidget
    world.modify(Everything.self, for: e) { $0.count = 8 }
    grid.refresh()
    #expect(d.ui.focusedWidget === typing && field.isTyping && field.value == 3)
    d.key(.enter)
    #expect(world.get(Everything.self, for: e)?.count == 41)
    // A text property keeps half-typed text too.
    let editor = grid.descendant(named: "Test.Everything.name") as! TextEditor
    d.click(at: editor.frame.center)
    d.type("Z")
    world.modify(Everything.self, for: e) { $0.name = "changed" }
    grid.refresh()
    #expect(editor.field.text.hasSuffix("Z") && editor.field.isFocused)
}

@MainActor @Test func gridCollapseStatePersists() {
    let (_, _, e, grid) = gridSetup()
    grid.setCollapsed(true, component: "Test.Everything", path: "inner")
    #expect(grid.descendant(named: "row.Test.Everything.inner.a")?.isHidden == true)
    grid.setCollapsed(true, component: "Transform")
    #expect(grid.descendant(named: "body.Transform")?.isHidden == true)
    grid.entity = nil
    grid.entity = e
    #expect(grid.isCollapsed(component: "Transform") && grid.descendant(named: "body.Transform")?.isHidden == true)
    #expect(grid.descendant(named: "row.Test.Everything.inner.a")?.isHidden == true)
    grid.setCollapsed(false, component: "Test.Everything", path: "inner")
    #expect(grid.descendant(named: "row.Test.Everything.inner.a")?.isHidden == false)
}

@MainActor @Test func gridRemoveButtonAndEntityNames() {
    let (d, world, e, grid) = gridSetup()
    var removed: String?
    grid.onRemoveComponent = { _, name in removed = name }
    let header = grid.descendant(named: "header.Test.Everything") as! GridHeader
    d.click(at: Vec2(header.frame.maxX - 8, header.frame.center.y))
    #expect(removed == "Test.Everything")
    let target = world.spawn()
    grid.entityName = { $0 == target ? "Target" : nil }
    world.modify(Everything.self, for: e) { $0.other = target }
    grid.refresh()
    #expect((grid.descendant(named: "Test.Everything.other") as? Label)?.text == "Target")
}

@MainActor @Test func sliderAppearsForRangedFieldsWhenAsked() {
    let d = Driver()
    let world = World()
    let e = world.spawn(Everything())
    let grid = PropertyGrid(world: world)
    grid.usesSlidersForRanges = true
    d.ui.root.addChild(grid)
    grid.entity = e
    d.ui.layoutIfNeeded()
    let slider = grid.descendant(named: "Test.Everything.amount.slider") as? Slider
    #expect(slider != nil)
    var phases: [PropertyEditPhase] = []
    grid.onFieldEdit = { phases.append($0.phase) }
    slider?.onEditBegan?()
    slider?.onChange?(5)
    slider?.onEditEnded?()
    #expect(phases == [.began, .changed, .ended])
}

// MARK: TreeView

@MainActor private func sampleTree() -> (TreeView, [String: TreeNode]) {
    var n: [String: TreeNode] = [:]
    func node(_ t: String, expanded: Bool = true, _ kids: [TreeNode] = []) -> TreeNode {
        let x = TreeNode(t, isExpanded: expanded, children: kids)
        n[t] = x
        return x
    }
    let a = node("a", [node("a1"), node("a2")])
    let c = node("c", expanded: false, [node("c1")])
    let root = node("root", [a, node("b"), c, node("d")])
    let tree = TreeView(roots: [root])
    tree.allowsMultipleSelection = true
    tree.allowsRename = true
    tree.allowsDragAndDrop = true
    return (tree, n)
}

@MainActor private func rowCenter(_ tree: TreeView, _ row: Int, fraction: Float = 0.5) -> Vec2 {
    let c = tree.contentRect
    return Vec2(c.x + 60, c.y + (Float(row) + fraction) * tree.effectiveRowHeight - tree.scroll.offset)
}

@MainActor private func placeTree(_ tree: TreeView, _ d: Driver) {
    tree.style.position = .absolute(Anchors(left: 0, top: 0))
    tree.style.width = 300
    tree.style.height = 400
    d.ui.root.addChild(tree)
    d.ui.layoutIfNeeded()
}

@MainActor @Test func treeMultiSelectRules() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    var selections: [[String]] = []
    tree.onSelectionChange = { selections.append($0.map(\.title)) }
    // rows: root a a1 a2 b c d
    d.click(at: rowCenter(tree, 1))
    #expect(tree.selectedNodes.map(\.title) == ["a"])
    d.hold(.leftSuper)
    d.click(at: rowCenter(tree, 4))  // toggle on
    d.click(at: rowCenter(tree, 6))
    #expect(tree.selectedNodes.map(\.title) == ["a", "b", "d"] && tree.selectedNode === n["d"])
    d.click(at: rowCenter(tree, 4))  // toggle off
    #expect(tree.selectedNodes.map(\.title) == ["a", "d"])
    d.unhold(.leftSuper)
    d.click(at: rowCenter(tree, 2))
    d.hold(.leftShift)
    d.click(at: rowCenter(tree, 5))  // range from the anchor (a1) to c
    #expect(tree.selectedNodes.map(\.title) == ["a1", "a2", "b", "c"] && tree.selectedNode === n["c"])
    d.unhold(.leftShift)
    d.click(at: rowCenter(tree, 6))  // plain click: one row again
    #expect(tree.selectedNodes.map(\.title) == ["d"])
    #expect(selections.last == ["d"])
    // Keyboard: shift+up extends from the anchor, plain up collapses; cmd+A selects all.
    d.key(.up, .shift)
    d.key(.up, .shift)
    #expect(tree.selectedNodes.map(\.title) == ["b", "c", "d"])
    d.key(.up)
    #expect(tree.selectedNodes.count == 1)
    d.key(.a, .shortcut)
    #expect(tree.selectedNodes.count == 7)
}

@MainActor @Test func treeSingleSelectionIsUnchangedByDefault() {
    let (tree, _) = sampleTree()
    tree.allowsMultipleSelection = false
    tree.allowsRename = false
    tree.allowsDragAndDrop = false
    let d = Driver()
    placeTree(tree, d)
    d.click(at: rowCenter(tree, 1))
    d.hold(.leftShift)
    d.click(at: rowCenter(tree, 4))
    #expect(tree.selectedNodes.map(\.title) == ["b"])
    d.unhold(.leftShift)
    d.key(.enter)  // no rename: expands / activates as before
    #expect(tree.renamingNode == nil)
}

@MainActor @Test func treeRenameCommitsCancelsAndVetoes() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    var asked: [String] = []
    tree.onRename = { node, title in asked.append("\(node.title)->\(title)"); return title != "bad" }
    d.click(at: rowCenter(tree, 4))
    d.key(.f2)
    #expect(tree.renamingNode === n["b"] && d.ui.focusedWidget is TextField)
    d.drawFrame()  // paints the field over its row
    d.type("beta")
    d.key(.enter)
    #expect(n["b"]?.title == "beta" && tree.renamingNode == nil && d.ui.focusedWidget === tree)
    // Esc cancels.
    d.key(.enter)
    #expect(tree.renamingNode === n["b"])
    d.type("zzz")
    d.key(.escape)
    #expect(n["b"]?.title == "beta" && tree.renamingNode == nil && d.ui.focusedWidget === tree)
    // A veto keeps the old title.
    d.key(.f2)
    d.type("bad")
    d.key(.enter)
    #expect(n["b"]?.title == "beta" && asked == ["b->beta", "beta->bad"])
    // Double click on a label renames; an empty title cancels.
    d.click(at: rowCenter(tree, 6))
    d.click(at: rowCenter(tree, 6))
    #expect(tree.renamingNode === n["d"])
    d.key(.a, .shortcut)
    d.key(.backspace)
    d.key(.enter)
    #expect(n["d"]?.title == "d" && asked.count == 2)
}

@MainActor private func dragRow(_ d: Driver, _ tree: TreeView, from row: Int, to point: Vec2, release: Bool = true) {
    let start = rowCenter(tree, row)
    d.press(at: start)
    d.move(to: start + Vec2(0, 8))
    d.move(to: point)
    if release { d.release() }
}

@MainActor @Test func treeDropTargetsBeforeAfterInto() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    let b = [n["b"]!]
    // rows: root a a1 a2 b c d (row 6 = d)
    var t = tree.dropTarget(at: rowCenter(tree, 6, fraction: 0.1), dragging: b)
    #expect(t?.parent === n["root"] && t?.index == 2 && t?.position == .before)  // before d once b has left: [a, c, d]
    t = tree.dropTarget(at: rowCenter(tree, 6, fraction: 0.9), dragging: b)
    #expect(t?.parent === n["root"] && t?.index == 3 && t?.position == .after)
    t = tree.dropTarget(at: rowCenter(tree, 5), dragging: b)  // onto c
    #expect(t?.parent === n["c"] && t?.index == 1 && t?.position == .into)
    // After an expanded node: its first child.
    t = tree.dropTarget(at: rowCenter(tree, 1, fraction: 0.9), dragging: b)
    #expect(t?.parent === n["a"] && t?.index == 0 && t?.position == .after)
    // Below the rows: the end of the roots.
    t = tree.dropTarget(at: Vec2(tree.contentRect.x + 20, tree.contentRect.maxY - 5), dragging: b)
    #expect(t?.parent == nil && t?.index == 1)
    // Dropping where it already is changes nothing.
    #expect(tree.dropTarget(at: rowCenter(tree, 4, fraction: 0.1), dragging: b) == nil)
}

@MainActor @Test func treeForbidsDroppingIntoOwnSubtree() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    let a = [n["a"]!]
    #expect(tree.dropTarget(at: rowCenter(tree, 1), dragging: a) == nil)  // onto itself
    #expect(tree.dropTarget(at: rowCenter(tree, 2), dragging: a) == nil)  // onto a child
    #expect(tree.dropTarget(at: rowCenter(tree, 3, fraction: 0.1), dragging: a) == nil)  // between its children
    #expect(tree.dropTarget(at: rowCenter(tree, 5), dragging: a)?.parent === n["c"])
}

@MainActor @Test func treeDragMovesNodesAndCallsOnMove() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    var calls: [String] = []
    tree.onMove = { nodes, parent, index in calls.append("\(nodes.map(\.title)) -> \(parent?.title ?? "roots") @\(index)"); return true }
    dragRow(d, tree, from: 4, to: rowCenter(tree, 1))  // b onto a
    #expect(calls == ["[\"b\"] -> a @2"])
    #expect(n["b"]?.parent === n["a"] && n["a"]?.children.map(\.title) == ["a1", "a2", "b"])
    #expect(tree.selectedNode === n["b"] && !tree.isDragging)
    // A veto leaves the tree alone.
    tree.onMove = { _, _, _ in false }
    let before = tree.visibleNodes.map(\.title)
    let row = before.firstIndex(of: "d")!
    dragRow(d, tree, from: row, to: rowCenter(tree, 1))
    #expect(tree.visibleNodes.map(\.title) == before)
    // canMove hides the target.
    tree.canMove = { _, parent, _ in parent !== n["a"] }
    #expect(tree.dropTarget(at: rowCenter(tree, 1), dragging: [n["d"]!]) == nil)
}

@MainActor @Test func treeDragMovesTheWholeSelectionAndEscapeCancels() {
    let (tree, n) = sampleTree()
    let d = Driver()
    placeTree(tree, d)
    d.click(at: rowCenter(tree, 4))
    d.hold(.leftSuper)
    d.click(at: rowCenter(tree, 6))
    d.unhold(.leftSuper)
    // Drag one of the selected rows (b) onto c: both move.
    dragRow(d, tree, from: 4, to: rowCenter(tree, 5), release: false)
    #expect(tree.isDragging && tree.dropTarget?.parent === n["c"])
    d.key(.escape)
    #expect(!tree.isDragging)
    d.release()
    #expect(n["b"]?.parent === n["root"])
    d.idle(40)  // not a double click
    dragRow(d, tree, from: 4, to: rowCenter(tree, 5))
    #expect(n["c"]?.children.map(\.title) == ["c1", "b", "d"] && n["c"]?.isExpanded == true)
}

@MainActor @Test func treeAutoExpandsAndAutoScrollsWhileDragging() {
    var kids: [TreeNode] = []
    for i in 0..<40 { kids.append(TreeNode("n\(i)")) }
    let folder = TreeNode("folder", children: [TreeNode("inner")])
    let root = TreeNode("root", isExpanded: true, children: [folder] + kids)
    let tree = TreeView(roots: [root])
    tree.allowsDragAndDrop = true
    tree.autoExpandDelay = 0.2
    let d = Driver()
    placeTree(tree, d)
    d.press(at: rowCenter(tree, 2))
    d.move(to: rowCenter(tree, 2) + Vec2(0, 6))
    d.move(to: rowCenter(tree, 1))
    #expect(tree.isDragging && !folder.isExpanded)
    d.idle(20)
    d.drawFrame()
    #expect(folder.isExpanded)
    // Near the bottom edge the list scrolls.
    let bottom = Vec2(tree.contentRect.x + 40, tree.contentRect.maxY - 4)
    d.move(to: bottom)
    let offset = tree.scroll.offset
    d.idle(30)
    d.drawFrame()
    #expect(tree.scroll.offset > offset)
    d.release()
}
