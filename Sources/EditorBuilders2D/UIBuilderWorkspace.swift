import EditorCore
import Engine
import Foundation

// The UI Builder tab: one `.ui` file (a game menu or HUD), tabbed with the Scene view.
//
// - Left: buttons that add a widget (into the selected container, or next to the selected
//   widget), the widget tree (drag rows to reparent or reorder), and Duplicate / Delete / Up / Down.
// - Middle: the live preview, drawn by the same `UIBuildView` games use, fitted into the panel
//   at the chosen screen size (presets for common sizes and aspect ratios). Click a widget to
//   select it; drag one that sits in a panel or on the screen to change its offset from its
//   anchor. With Interact on, clicks press the preview's buttons and the event is shown.
// - Right: the selected widget's properties (placement, size, look, text, bar / image / button
//   fields, bindings), then the layout's theme, colors, sample values and problems.
//
// The file is the truth: every change is one undo step of the editor (Ctrl+Z), the layout
// reimports (running games show it) and the tab rebuilds. Edits made by widget callbacks are
// applied on the next `update`, so no widget is torn down while it handles an event.

@MainActor
public final class UIBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The layout being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var build = UIBuild()
    /// The selected widget's id.
    public private(set) var selected: String?
    /// The preview's screen size in points.
    public private(set) var previewSize = Vec2(1280, 720)
    /// Values shown in the preview over the file's samples (from `uiLayout.open`; not saved).
    public private(set) var previewValues: [String: JSONValue] = [:]
    /// The last event a preview button sent (Interact mode).
    public private(set) var lastEvent: UIBuildEvent?
    /// Loads image thumbnails for the preview (the app sets it).
    public var images: ((AssetReference) -> GPUTexture?)?
    /// The preview.
    public let canvas: UIBuildPreviewCanvas

    /// Screen sizes offered for the preview ("Design" is the layout's own size).
    public static let previewPresets: [(name: String, size: Vec2?)] = [
        ("Design size", nil),
        ("1920 × 1080 (16:9)", Vec2(1920, 1080)),
        ("1280 × 720 (16:9)", Vec2(1280, 720)),
        ("2560 × 1080 (21:9)", Vec2(2560, 1080)),
        ("1280 × 800 (16:10)", Vec2(1280, 800)),
        ("1024 × 768 (4:3)", Vec2(1024, 768)),
        ("844 × 390 (phone landscape)", Vec2(844, 390)),
        ("390 × 844 (phone portrait)", Vec2(390, 844)),
    ]

    private let title = Label("UI Builder", role: .heading, name: "uiBuilderTitle")
    private let sizePicker = Dropdown(options: UIBuilderWorkspace.previewPresets.map(\.name), name: "uiBuilderPreviewSize")
    private let interact = Checkbox("Interact", name: "uiBuilderInteract")
    private let status = Label("", role: .caption, name: "uiBuilderStatus")
    private let tree = TreeView(roots: [], name: "uiBuilderTree")
    private let leftBar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "uiBuilderLeft")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "uiBuilderSidebar")
    private let editButtons = HStack(spacing: 4, name: "uiBuilderEditButtons")
    private var presetIndex = 0
    private var shownRevision = -1
    private var dirty = true
    private var pending: (change: (inout UIBuild) throws -> Void, label: String, select: String?)?
    private var pendingSelection: String??
    /// The layout as shown while a widget is dragged in the preview (not yet written).
    private var draft: UIBuild?

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "uiBuilderWorkspace")
        canvas = UIBuildPreviewCanvas(name: "uiBuilderPreview")
        canvas.workspace = self
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.ui` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isUIBuildFile(id), let build = session.assets?.uiBuild(of: id) else { return false }
        if asset != id {
            asset = id
            selected = build.widgets.first?.id
            previewValues = [:]
            lastEvent = nil
            presetIndex = 0
            sizePicker.select(0)
        }
        self.build = build
        draft = nil
        shownRevision = session.assets?.revision(of: id) ?? 0
        title.text = session.assets?.record(id)?.fileName ?? "UI Builder"
        takePreviewRequest()
        dirty = true
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        pending = nil
        draft = nil
        showEmpty()
    }

    private func takePreviewRequest() {
        guard let request = session.uiPreviewRequest else { return }
        session.uiPreviewRequest = nil
        if let size = request.size {
            presetIndex = Self.previewPresets.firstIndex { $0.size == size } ?? 0
            sizePicker.select(presetIndex)
            customSize = presetIndex == 0 && size != build.size ? size : nil
        }
        if let values = request.values { previewValues = values }
        if let select = request.select { selected = select }
    }

    private var customSize: Vec2?

    // MARK: Chrome

    private func layOutChrome() {
        title.style.shrink = 1
        title.icon = EditorIcons.named("layout-dashboard")
        sizePicker.tooltip = "The screen size the preview shows the layout at"
        sizePicker.onChange = { [unowned self] index in
            presetIndex = index
            customSize = nil
            dirty = true
        }
        interact.tooltip = "Click the preview's buttons to see their events instead of selecting widgets"
        interact.onChange = { [unowned self] _ in dirty = true }
        status.style.shrink = 1
        let closeButton = Button("Close", name: "uiBuilderClose") { [unowned self] in self.close() }
        let playButton = Button("Play", name: "uiBuilderPlayTransitions") { [unowned self] in playTransitions() }
        playButton.tooltip = "Play the layout's hide transition, then its show transition, in the preview"
        let bar = HStack(spacing: 8, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "uiBuilderToolbar",
                         [title, Spacer(), status, playButton, interact, sizePicker, closeButton])

        tree.allowsDragAndDrop = true
        tree.style.height = 260
        tree.onSelect = { [unowned self] node in
            guard let id = node?.userData as? String, id != selected else { return }
            pendingSelection = .some(id)
        }
        tree.canMove = { [unowned self] _, parent, _ in
            guard let parentID = parent?.userData as? String else { return true }
            return build.widget(parentID)?.type.isContainer == true
        }
        tree.onMove = { [unowned self] nodes, parent, index in
            guard let id = nodes.first?.userData as? String else { return false }
            let parentID = parent?.userData as? String ?? ""
            apply("Move Widget", select: id) { try $0.move(id, to: parentID, index: index) }
            return false
        }

        let left = ScrollView(leftBar, name: "uiBuilderLeftScroll")
        left.style.width = 250
        canvas.style.grow = 1
        canvas.style.shrink = 1
        let side = ScrollView(sidebar, name: "uiBuilderSidebarScroll")
        side.style.width = 320
        let body = HStack(spacing: 0, alignment: .stretch, name: "uiBuilderBody",
                          [left, Separator(.vertical), canvas, Separator(.vertical), side])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "UI Builder"
        leftBar.removeAllChildren()
        sidebar.removeAllChildren()
        status.text = ""
        canvas.preview.load(UIBuild(widgets: []))
        let note = note("Open a .ui file from the Assets panel (New UI Layout in its menu, or uiLayout.open).")
        leftBar.addChild(note)
    }

    // MARK: Per frame

    /// Call every frame: applies the pending edit, follows the file (undo, MCP, other panels) and rebuilds what changed.
    public func update() {
        guard let asset, let assets = session.assets else { return }
        if session.uiPreviewRequest != nil, session.openUIBuild == asset {
            takePreviewRequest()
            dirty = true
        }
        if let pendingSelection {
            self.pendingSelection = nil
            selected = pendingSelection
            dirty = true
        }
        if let pending {
            self.pending = nil
            commit(pending.change, label: pending.label, select: pending.select)
        }
        let revision = assets.revision(of: asset)
        if revision != shownRevision, let fresh = assets.uiBuild(of: asset) {
            shownRevision = revision
            if fresh != build { build = fresh }
            dirty = true
        }
        if dirty {
            dirty = false
            rebuild()
        }
    }

    /// Whether an edit is waiting for `update`.
    public var hasPendingEdit: Bool { pending != nil }

    // MARK: Edits

    /// Queues a change to the layout, written as one undo step on the next `update`.
    func apply(_ label: String, select: String? = nil, _ change: @escaping (inout UIBuild) throws -> Void) {
        pending = (change, label, select)
    }

    private func commit(_ change: (inout UIBuild) throws -> Void, label: String, select: String?) {
        guard let asset else { return }
        var edited = build
        do { try change(&edited) } catch {
            session.log.warning("UI Builder: \(error)")
            dirty = true
            return
        }
        guard session.applyUIBuild(edited, to: asset, label: label) != nil else { dirty = true; return }
        build = session.assets?.uiBuild(of: asset) ?? edited
        shownRevision = session.assets?.revision(of: asset) ?? shownRevision
        if let select { selected = select }
        if let selected, build.widget(selected) == nil { self.selected = nil }
        draft = nil
        dirty = true
    }

    /// Selects widget `id` (nil: none).
    public func select(_ id: String?) {
        guard id != selected else { return }
        pendingSelection = .some(id)
    }

    /// Adds a widget of `type`: into the selected container, else beside the selected widget, else on the screen.
    public func addWidget(_ type: UIBuildWidgetType) {
        var parent = ""
        if let selected, let current = build.widget(selected) {
            parent = current.type.isContainer ? current.id : current.parent
        }
        var widget = Self.newWidget(type)
        widget.id = build.uniqueID(type.rawValue)
        widget.parent = parent
        let id = widget.id
        apply("Add \(Self.title(of: type))", select: id) { try $0 = $0.applying(UIBuildEdit(addWidgets: [widget])) }
    }

    /// A widget type's name for buttons and headings ("Text Field").
    static func title(of type: UIBuildWidgetType) -> String {
        type == .textField ? "Text Field" : type.rawValue.capitalized
    }

    /// A new widget of `type` with settings that show something.
    static func newWidget(_ type: UIBuildWidgetType) -> UIBuildWidget {
        switch type {
        case .panel: UIBuildWidget(type: .panel, width: 240, height: 140, padding: 12, background: "panel", cornerRadius: 10)
        case .vstack: UIBuildWidget(type: .vstack, padding: 8, spacing: 8)
        case .hstack: UIBuildWidget(type: .hstack, padding: 8, spacing: 8)
        case .label: UIBuildWidget(type: .label, text: "Label", shadow: true)
        case .image: UIBuildWidget(type: .image, width: 64, height: 64)
        case .button: UIBuildWidget(type: .button, text: "Button")
        case .bar: UIBuildWidget(type: .bar, width: 200, value: 0.6)
        case .spacer: UIBuildWidget(type: .spacer, grow: 1)
        case .slider: UIBuildWidget(type: .slider, width: 200, value: 0.5)
        case .toggle: UIBuildWidget(type: .toggle, text: "Toggle")
        case .textField: UIBuildWidget(type: .textField, width: 200, placeholder: "Type here")
        }
    }

    public func deleteSelected() {
        guard let id = selected, build.widget(id) != nil else { return }
        apply("Delete Widget") { try $0 = $0.applying(UIBuildEdit(removeWidgets: [id])) }
    }

    /// Copies the selected widget (and what is inside it) beside itself.
    public func duplicateSelected() {
        guard let id = selected, build.widget(id) != nil else { return }
        let copyID = build.uniqueID(id)
        apply("Duplicate Widget", select: copyID) { build in
            var renamed: [String: String] = [:]
            var copies: [UIBuildWidget] = []
            let subtree = build.subtree(of: id)
            for w in build.widgets where subtree.contains(w.id) {
                var copy = w
                copy.id = w.id == id ? copyID : build.uniqueID(w.id + "Copy")
                // Keep generated ids distinct from each other too.
                while copies.contains(where: { $0.id == copy.id }) { copy.id += "x" }
                renamed[w.id] = copy.id
                copies.append(copy)
            }
            for i in copies.indices where copies[i].id != copyID { copies[i].parent = renamed[copies[i].parent] ?? copies[i].parent }
            if var first = copies.first, first.id == copyID {
                if build.widget(first.parent)?.type == .panel || first.parent.isEmpty { first.offset += Vec2(16, 16) }
                copies[0] = first
            }
            build.widgets.append(contentsOf: copies)
        }
    }

    /// Moves the selected widget `delta` places among its siblings.
    public func moveSelected(by delta: Int) {
        guard let id = selected, let widget = build.widget(id) else { return }
        let siblings = build.children(of: widget.parent).map(\.id)
        guard let index = siblings.firstIndex(of: id) else { return }
        let target = min(max(index + delta, 0), siblings.count - 1)
        guard target != index else { return }
        apply("Reorder Widget") { try $0.move(id, to: nil, index: target) }
    }

    /// Changes one field of widget `id` (JSON name; null resets it).
    public func setField(_ id: String, _ key: String, _ value: JSONValue, label: String? = nil) {
        let select = key == "id" ? value.stringValue : nil
        apply(label ?? "Set \(key)", select: select) { try $0.update(id, fields: [key: value]) }
    }

    /// Changes the layout itself (theme, colors, values…).
    func editLayout(_ label: String, _ edit: UIBuildEdit) {
        apply(label) { try $0 = $0.applying(edit) }
    }

    // MARK: Preview (called by the canvas)

    /// The layout the preview shows.
    var shownBuild: UIBuild { draft ?? build }

    /// The preview's screen size for the current preset.
    var effectivePreviewSize: Vec2 {
        customSize ?? Self.previewPresets[presetIndex].size ?? build.size
    }

    var isInteractive: Bool { interact.isOn }

    /// Whether widget `id` can be dragged in the preview (it sits on the screen or in a panel and isn't filling it).
    func isDraggable(_ id: String) -> Bool {
        guard let w = build.widget(id), w.anchor != .fill else { return false }
        let parent = build.effectiveParent(of: w)
        return parent.isEmpty || build.widget(parent)?.type == .panel
    }

    /// Shows widget `id` at `offset` while dragging (not written yet).
    func dragPreview(_ id: String, offset: Vec2) {
        guard var shown = draft ?? Optional(build), let i = shown.index(of: id) else { return }
        shown.widgets[i].offset = offset
        draft = shown
        canvas.preview.load(shown)
    }

    /// Writes the dragged offset as one undo step.
    func endDrag(_ id: String) {
        guard let draft, let w = draft.widget(id), w.offset != build.widget(id)?.offset else {
            self.draft = nil
            canvas.preview.load(build)
            return
        }
        let offset = w.offset
        apply("Move Widget", select: id) { try $0.update(id, fields: ["offset": .array([.double(Double(offset.x)), .double(Double(offset.y))])]) }
    }

    /// Plays the layout's hide transition, then its show transition, in the preview.
    public func playTransitions() {
        let preview = canvas.preview
        preview.hide { [weak preview] in preview?.show() }
        canvas.setNeedsDisplay()
    }

    func previewEvent(_ event: UIBuildEvent) {
        lastEvent = event
        let value = event.value.map { " = " + UIBuild.display($0) } ?? ""
        status.text = "Event: \(event.name)\(value)  (from \(event.widget))"
    }

    // MARK: Layout

    private func rebuild() {
        guard asset != nil else { return }
        previewSize = effectivePreviewSize
        let preview = canvas.preview
        preview.load(shownBuild)
        preview.set(previewValues)
        preview.images = { [weak self] path in
            guard let self, let id = self.session.assets?.assetID(forTableValue: path) else { return nil }
            return self.images?(AssetReference(id))
        }
        if lastEvent == nil {
            status.text = "\(Int(previewSize.x)) × \(Int(previewSize.y))"
        }
        let issues = session.assets?.uiBuildIssues(build) ?? build.validate()
        layOutLeft()
        layOutSidebar(issues)
    }

    private func layOutLeft() {
        leftBar.removeAllChildren()
        leftBar.addChild(Label("Add", role: .secondary))
        let adds = HStack(spacing: 4, name: "uiBuilderAdd")
        adds.wraps = true
        for type in UIBuildWidgetType.allCases {
            let button = Button(Self.title(of: type), name: "uiBuilderAdd.\(type.rawValue)") { [unowned self] in addWidget(type) }
            button.command = UIEditCommand.id.rawValue
            button.tooltip = "Add a \(type.rawValue) into the selected container (or beside the selected widget)"
            adds.addChild(button)
        }
        leftBar.addChild(adds)
        leftBar.addChild(Separator())
        leftBar.addChild(Label("Widgets", role: .secondary))
        var nodes: [String: TreeNode] = [:]
        var roots: [TreeNode] = []
        for w in build.widgets where nodes[w.id] == nil {
            let node = TreeNode("\(w.id)  ·  \(w.type.rawValue)", isExpanded: true, userData: w.id)
            node.icon = Self.icon(for: w.type)
            nodes[w.id] = node
        }
        for w in build.widgets {
            guard let node = nodes[w.id], node.parent == nil, !roots.contains(where: { $0 === node }) else { continue }
            let parent = build.effectiveParent(of: w)
            if let parentNode = nodes[parent], parentNode !== node { parentNode.addChild(node) } else { roots.append(node) }
        }
        tree.roots = roots
        if let selected, let node = nodes[selected] { tree.select(node) } else { tree.select(nil) }
        leftBar.addChild(tree)
        if build.widgets.isEmpty { leftBar.addChild(note("No widgets yet: add one above.")) }

        editButtons.removeAllChildren()
        let has = selected.flatMap { build.widget($0) } != nil
        let up = Button("Up", name: "uiBuilderUp") { [unowned self] in moveSelected(by: -1) }
        let down = Button("Down", name: "uiBuilderDown") { [unowned self] in moveSelected(by: 1) }
        let duplicate = Button("Duplicate", name: "uiBuilderDuplicate") { [unowned self] in duplicateSelected() }
        let delete = Button("Delete", name: "uiBuilderDelete") { [unowned self] in deleteSelected() }
        up.tooltip = "Move before the previous sibling"
        down.tooltip = "Move after the next sibling"
        delete.tooltip = "Remove the widget and everything inside it"
        for button in [up, down, duplicate, delete] {
            button.isEnabled = has
            button.command = UIEditCommand.id.rawValue
            editButtons.addChild(button)
        }
        editButtons.wraps = true
        leftBar.addChild(editButtons)
        leftBar.addChild(note("Drag rows to put a widget in another container or reorder it. Drag widgets in the preview to move them from their anchor."))
    }

    static func icon(for type: UIBuildWidgetType) -> VectorIcon {
        switch type {
        case .panel: EditorIcons.named("square")
        case .vstack, .hstack: EditorIcons.named("list")
        case .label: EditorIcons.named("type")
        case .image: EditorIcons.named("image")
        case .button: EditorIcons.named("mouse-pointer-ban")
        case .bar: EditorIcons.named("gauge")
        case .spacer: EditorIcons.named("square-dashed")
        case .slider: EditorIcons.named("sliders-horizontal")
        case .toggle: EditorIcons.named("circle-dot")
        case .textField: EditorIcons.named("keyboard")
        }
    }

    // MARK: Sidebar

    private func layOutSidebar(_ issues: [UIBuildIssue]) {
        sidebar.removeAllChildren()
        if let selected, let widget = build.widget(selected) {
            addWidgetForm(widget)
            sidebar.addChild(Separator())
        } else {
            sidebar.addChild(note("Select a widget in the tree or the preview to edit it."))
        }
        addLayoutForm()
        sidebar.addChild(Separator())
        addValuesForm()
        sidebar.addChild(Separator())
        sidebar.addChild(Label(issues.isEmpty ? "No problems" : "Problems (\(issues.count))", role: .secondary))
        for issue in issues.prefix(30) { sidebar.addChild(note(issue.description)) }
    }

    private func row(_ caption: String, _ editor: Widget) {
        let label = Label(caption, role: .caption)
        label.style.width = 86
        editor.style.grow = 1
        sidebar.addChild(HStack(spacing: 6, [label, editor]))
    }

    private func textRow(_ caption: String, _ text: String, placeholder: String = "", name: String, tooltip: String? = nil,
                         _ set: @escaping (String) -> Void) {
        let field = TextField(text: text, placeholder: placeholder, name: "uiBuilderField.\(name)")
        let commitText: (String) -> Void = { value in if value != text { set(value) } }
        field.onEndEditing = commitText
        field.onSubmit = commitText
        field.tooltip = tooltip
        row(caption, field)
    }

    /// The swatch's color of a `.ui` color ("" shows clear).
    static func swatchColor(_ text: String, theme: UITheme) -> UIColor { theme.uiBuildColor(text) ?? UIColor(0.35, 0.35, 0.38, 1) }

    /// A color: a swatch that opens a color picker (writes "#RRGGBB[AA]") and a menu of the
    /// layout theme's color names, "(none)" and "custom" (the hex in the swatch). One pick is one undo step.
    private func colorRow(_ caption: String, _ text: String, name: String, noneTitle: String = "(none)",
                          _ set: @escaping (String) -> Void) {
        let theme = build.makeTheme()
        let swatch = ColorSwatch(color: Self.swatchColor(text, theme: theme), name: "uiBuilderField.\(name)")
        swatch.onEditEnded = { _, end in set(DataTableValues.hex(Vec4(end.r, end.g, end.b, end.a))) }
        let isHex = UIBuild.hexColor(text) != nil
        let options = [""] + ["custom"] + UIBuild.themeColorNames + (isHex || text.isEmpty || UIBuild.themeColorNames.contains(text) ? [] : [text])
        let selected = text.isEmpty ? 0 : isHex ? 1 : options.firstIndex(of: text) ?? 0
        let menu = Dropdown(options: options.map { $0.isEmpty ? noneTitle : $0 == "custom" && isHex ? text : $0 }, selectedIndex: selected,
                            name: "uiBuilderField.\(name).name")
        menu.tooltip = "A theme color (it follows the layout's theme), a custom color, or none"
        menu.onChange = { index in
            let choice = options[index]
            if choice == "custom" {
                let c = theme.uiBuildColor(text) ?? .white
                set(DataTableValues.hex(Vec4(c.r, c.g, c.b, c.a)))
            } else if choice != text {
                set(choice)
            }
        }
        swatch.showsHexCode = false
        swatch.tooltip = text.isEmpty ? "Pick a color" : "\(text): pick a color"
        swatch.style.width = 32
        swatch.style.grow = 0
        menu.style.grow = 1
        let editor = HStack(spacing: 4, [swatch, menu])
        row(caption, editor)
    }

    private func numberRow(_ caption: String, _ value: Float, name: String, isInteger: Bool = false, range: ClosedRange<Double>? = nil,
                           step: Double = 1, _ set: @escaping (Double) -> Void) {
        let field = NumberField(value: Double(value), isInteger: isInteger, range: range, step: step, name: "uiBuilderField.\(name)")
        field.onEditEnded = { start, end in if start != end { set(end) } }
        row(caption, field)
    }

    private func choiceRow<T: RawRepresentable & CaseIterable & Equatable>(_ caption: String, _ value: T, name: String,
                                                                         _ set: @escaping (T) -> Void) where T.RawValue == String {
        let cases = Array(T.allCases)
        let dropdown = Dropdown(options: cases.map(\.rawValue), selectedIndex: cases.firstIndex(of: value) ?? 0, name: "uiBuilderField.\(name)")
        dropdown.onChange = { index in set(cases[index]) }
        row(caption, dropdown)
    }

    private func toggleRow(_ caption: String, _ isOn: Bool, name: String, _ set: @escaping (Bool) -> Void) {
        let box = Checkbox("", isOn: isOn, name: "uiBuilderField.\(name)")
        box.onChange = set
        row(caption, box)
    }

    /// A transition picker: its kind, then (when it has one) its time and a slide's side.
    private func transitionRows(_ caption: String, _ transition: UIBuildTransition?, name: String, tooltip: String,
                                _ set: @escaping (UIBuildTransition?) -> Void) {
        let kinds = UIBuildTransitionKind.allCases
        let picker = Dropdown(options: kinds.map(\.rawValue), selectedIndex: kinds.firstIndex(of: transition?.kind ?? .none) ?? 0,
                              name: "uiBuilderField.\(name)")
        picker.tooltip = tooltip
        picker.onChange = { index in
            guard kinds[index] != .none else { return set(nil) }
            var t = transition ?? UIBuildTransition()
            t.kind = kinds[index]
            set(t)
        }
        row(caption, picker)
        guard let transition else { return }
        numberRow("\(caption) time", transition.duration, name: "\(name).duration", range: 0...30, step: 0.05) { seconds in
            var t = transition
            t.duration = Float(seconds)
            set(t)
        }
        if transition.kind == .slide {
            choiceRow("\(caption) from", transition.from, name: "\(name).from") { edge in
                var t = transition
                t.from = edge
                set(t)
            }
        }
    }

    private func addWidgetForm(_ w: UIBuildWidget) {
        let id = w.id
        func field(_ key: String, _ value: JSONValue) { setField(id, key, value) }
        sidebar.addChild(Label("\(Self.title(of: w.type)) \(w.id)", role: .secondary))
        textRow("Id", w.id, name: "id", tooltip: "Unique; game code finds the widget and its events by it") { text in
            let new = text.trimmingCharacters(in: .whitespaces)
            if !new.isEmpty { field("id", .string(new)) }
        }
        choiceRow("Type", w.type, name: "type") { field("type", .string($0.rawValue)) }
        let containers = build.widgets.filter { $0.type.isContainer && !build.subtree(of: id).contains($0.id) }.map(\.id)
        let parents = [""] + containers
        let parentPicker = Dropdown(options: parents.map { $0.isEmpty ? "(screen)" : $0 }, selectedIndex: parents.firstIndex(of: w.parent) ?? 0,
                                    name: "uiBuilderField.parent")
        parentPicker.onChange = { [unowned self] index in
            apply("Set Parent", select: id) { try $0.move(id, to: parents[index], index: nil) }
        }
        row("Parent", parentPicker)

        let parentType = build.widget(build.effectiveParent(of: w))?.type
        if parentType == nil || parentType == .panel {
            choiceRow("Anchor", w.anchor, name: "anchor") { field("anchor", .string($0.rawValue)) }
            numberRow("Offset X", w.offset.x, name: "offsetX") { x in field("offset", .array([.double(x), .double(Double(w.offset.y))])) }
            numberRow("Offset Y", w.offset.y, name: "offsetY") { y in field("offset", .array([.double(Double(w.offset.x)), .double(y)])) }
        } else {
            numberRow("Grow", w.grow, name: "grow", range: 0...100, step: 0.1) { field("grow", .double($0)) }
        }
        textRow("Width", w.width.map { UIBuild.display(.double(Double($0))) } ?? "", placeholder: "auto", name: "width") { text in
            field("width", Double(text.trimmingCharacters(in: .whitespaces)).map { .double($0) } ?? .null)
        }
        textRow("Height", w.height.map { UIBuild.display(.double(Double($0))) } ?? "", placeholder: "auto", name: "height") { text in
            field("height", Double(text.trimmingCharacters(in: .whitespaces)).map { .double($0) } ?? .null)
        }

        switch w.type {
        case .panel, .vstack, .hstack:
            numberRow("Padding", w.padding, name: "padding", range: 0...1000) { field("padding", .double($0)) }
            if w.type != .panel {
                numberRow("Spacing", w.spacing, name: "spacing", range: 0...1000) { field("spacing", .double($0)) }
                choiceRow("Align", w.align, name: "align") { field("align", .string($0.rawValue)) }
                choiceRow("Justify", w.justify, name: "justify") { field("justify", .string($0.rawValue)) }
            }
        case .label:
            textRow("Text", w.text, placeholder: "Score: {score}", name: "text", tooltip: "{key} shows a value") { field("text", .string($0)) }
            numberRow("Font size", w.fontSize, name: "fontSize", range: 0...400) { field("fontSize", .double($0)) }
            choiceRow("Align text", w.textAlign, name: "textAlign") { field("textAlign", .string($0.rawValue)) }
            toggleRow("Wrap", w.wrap, name: "wrap") { field("wrap", .bool($0)) }
            toggleRow("Shadow", w.shadow, name: "shadow") { field("shadow", .bool($0)) }
        case .button:
            textRow("Text", w.text, name: "text", tooltip: "{key} shows a value") { field("text", .string($0)) }
            textRow("Event", w.event, placeholder: w.id, name: "event", tooltip: "What game code listens for with on(\"…\")") {
                field("event", .string($0.trimmingCharacters(in: .whitespaces)))
            }
            toggleRow("Primary", w.primary, name: "primary") { field("primary", .bool($0)) }
            numberRow("Font size", w.fontSize, name: "fontSize", range: 0...400) { field("fontSize", .double($0)) }
        case .bar:
            choiceRow("Kind", w.kind, name: "kind") { field("kind", .string($0.rawValue)) }
            numberRow("Value", w.value, name: "value", range: 0...1_000_000, step: 0.01) { field("value", .double($0)) }
            numberRow("Max", w.max, name: "max", range: 0.0001...1_000_000, step: 0.1) { field("max", .double($0)) }
            numberRow("Segments", Float(w.segments), name: "segments", isInteger: true, range: 0...100) { field("segments", .int(Int64($0))) }
            toggleRow("Damage trail", w.trail, name: "trail") { field("trail", .bool($0)) }
            textRow("Text", w.text, placeholder: "{health} / 100", name: "text") { field("text", .string($0)) }
        case .image:
            let images = imagePaths()
            if images.isEmpty {
                textRow("Image", w.image, placeholder: "UI/heart.png", name: "image") { field("image", .string($0)) }
            } else {
                let options = [""] + images + (images.contains(w.image) || w.image.isEmpty ? [] : [w.image])
                let picker = Dropdown(options: options.map { $0.isEmpty ? "(none)" : $0 }, selectedIndex: options.firstIndex(of: w.image) ?? 0,
                                      name: "uiBuilderField.image")
                picker.onChange = { index in field("image", .string(options[index])) }
                row("Image", picker)
            }
            choiceRow("Fit", w.fit, name: "fit") { field("fit", .string($0.rawValue)) }
        case .slider:
            numberRow("Value", w.value, name: "value", step: 0.01) { field("value", .double($0)) }
            numberRow("Min", w.min, name: "min", step: 0.1) { field("min", .double($0)) }
            numberRow("Max", w.max, name: "max", step: 0.1) { field("max", .double($0)) }
            numberRow("Step", w.step, name: "step", range: 0...1_000_000, step: 0.01) { field("step", .double($0)) }
        case .toggle:
            textRow("Text", w.text, name: "text", tooltip: "{key} shows a value") { field("text", .string($0)) }
            toggleRow("On", w.on, name: "on") { field("on", .bool($0)) }
            choiceRow("Style", w.toggleStyle, name: "toggleStyle") { field("toggleStyle", .string($0.rawValue)) }
            numberRow("Font size", w.fontSize, name: "fontSize", range: 0...400) { field("fontSize", .double($0)) }
        case .textField:
            textRow("Text", w.text, name: "text", tooltip: "The starting text") { field("text", .string($0)) }
            textRow("Placeholder", w.placeholder, name: "placeholder", tooltip: "The hint shown while it is empty") { field("placeholder", .string($0)) }
            numberRow("Max length", Float(w.maxLength), name: "maxLength", isInteger: true, range: 0...10_000) { field("maxLength", .int(Int64($0))) }
            numberRow("Font size", w.fontSize, name: "fontSize", range: 0...400) { field("fontSize", .double($0)) }
        case .spacer:
            break
        }
        if w.type.isInput {
            let when = w.type == .textField ? "on Enter" : "when the player changes it"
            textRow("Event", w.event, placeholder: w.id, name: "event", tooltip: "Sent \(when), with the new value; game code listens with on(\"…\")") {
                field("event", .string($0.trimmingCharacters(in: .whitespaces)))
            }
        }

        if w.type != .spacer {
            let colorCaption = w.type == .bar ? "Fill" : w.type == .image ? "Tint" : "Color"
            if w.type != .panel && w.type != .vstack && w.type != .hstack {
                colorRow(colorCaption, w.color, name: "color", noneTitle: "(default)") { field("color", .string($0)) }
            }
            colorRow(w.type == .bar ? "Track" : "Background", w.background, name: "background",
                     noneTitle: w.type == .bar || w.type == .button || w.type.isInput ? "(default)" : "(none)") { field("background", .string($0)) }
            colorRow("Border", w.borderColor, name: "borderColor") { field("borderColor", .string($0)) }
            numberRow("Corners", w.cornerRadius, name: "cornerRadius", range: 0...500) { field("cornerRadius", .double($0)) }
            numberRow("Opacity", w.opacity, name: "opacity", range: 0...1, step: 0.01) { field("opacity", .double($0)) }
        }
        toggleRow("Hidden", w.hidden, name: "hidden") { field("hidden", .bool($0)) }

        sidebar.addChild(Label("Animation", role: .secondary))
        func transitionValue(_ t: UIBuildTransition?) -> JSONValue { t.flatMap { try? AssetJSON.value($0) } ?? .null }
        transitionRows("Show", w.show, name: "show", tooltip: "How it appears when it becomes visible (visibleWhen, hidden)") { [unowned self] t in
            // A first show transition also becomes the hide one, the usual pairing.
            var fields: [String: JSONValue] = ["show": transitionValue(t)]
            if w.show == nil, w.hide == nil { fields["hide"] = transitionValue(t) }
            apply("Set Show Transition", select: id) { try $0.update(id, fields: fields) }
        }
        transitionRows("Hide", w.hide, name: "hide", tooltip: "How it goes away") { t in field("hide", transitionValue(t)) }
        if w.type == .bar || w.type == .label || w.type == .button {
            numberRow("Tween", w.tween, name: "tween", range: 0...30, step: 0.05) { field("tween", .double($0)) }
        }

        if w.type.isFocusable {
            sidebar.addChild(Label("Navigation", role: .secondary))
            let targets = [""] + build.widgets.filter { $0.type.isFocusable && $0.id != id }.map(\.id)
            for (caption, key, current) in [("Up", "navUp", w.navUp), ("Down", "navDown", w.navDown), ("Left", "navLeft", w.navLeft),
                                            ("Right", "navRight", w.navRight)] {
                let options = targets + (targets.contains(current) ? [] : [current])
                let picker = Dropdown(options: options.map { $0.isEmpty ? "(auto)" : $0 }, selectedIndex: options.firstIndex(of: current) ?? 0,
                                      name: "uiBuilderField.\(key)")
                picker.tooltip = "Where \(caption) on the arrow keys / D-pad moves focus from this widget (auto: the navigation order, else the nearest widget that way)"
                picker.onChange = { index in field(key, .string(options[index])) }
                row(caption, picker)
            }
        }

        sidebar.addChild(Label("Bindings", role: .secondary))
        if w.type == .bar || w.type == .label || w.type == .button || w.type == .image || w.type.isInput {
            let what = switch w.type {
            case .bar: "fill (value / max)"
            case .image: "image path"
            case .slider: "value (the player's changes write it back)"
            case .toggle: "state (the player's changes write it back)"
            case .textField: "text (the player's typing writes it back)"
            default: "whole text (unless it has {…})"
            }
            textRow("Bind", w.bind, placeholder: "value key", name: "bind", tooltip: "The value key that sets the \(what)") {
                field("bind", .string($0.trimmingCharacters(in: .whitespaces)))
            }
        }
        textRow("Visible when", w.visibleWhen, placeholder: "always", name: "visibleWhen", tooltip: "A value key: shown while it is truthy (\"!key\": falsy)") {
            field("visibleWhen", .string($0.trimmingCharacters(in: .whitespaces)))
        }
    }

    private func addLayoutForm() {
        sidebar.addChild(Label("Layout", role: .secondary))
        let themes = UIBuild.themeNames
        let themePicker = Dropdown(options: themes, selectedIndex: themes.firstIndex(of: build.theme) ?? 0, name: "uiBuilderField.theme")
        themePicker.onChange = { [unowned self] index in editLayout("Set Theme", UIBuildEdit(theme: themes[index])) }
        row("Theme", themePicker)
        numberRow("Font size", build.fontSize, name: "layoutFontSize", range: 0...200) { [unowned self] size in
            editLayout("Set Font Size", UIBuildEdit(fontSize: Float(size)))
        }
        textRow("Safe area", build.safeArea.map { UIBuild.display(.double(Double($0))) } ?? "", placeholder: "theme", name: "safeArea") { [unowned self] text in
            editLayout("Set Safe Area", UIBuildEdit(safeArea: Float(text.trimmingCharacters(in: .whitespaces)) ?? -1))
        }
        numberRow("Design W", build.size.x, name: "designWidth", range: 1...16384) { [unowned self] w in
            editLayout("Set Design Size", UIBuildEdit(size: Vec2(Float(w), build.size.y)))
        }
        numberRow("Design H", build.size.y, name: "designHeight", range: 1...16384) { [unowned self] h in
            editLayout("Set Design Size", UIBuildEdit(size: Vec2(build.size.x, Float(h))))
        }
        let modes = UIBuildScaleMode.allCases
        let scalePicker = Dropdown(options: modes.map(\.rawValue), selectedIndex: modes.firstIndex(of: build.scaleMode) ?? 0,
                                   name: "uiBuilderField.scaleMode")
        scalePicker.tooltip = "How the whole layout scales with the screen from the design size: none keeps points; fit shows all of it; fill covers the screen; width / height follow one side"
        scalePicker.onChange = { [unowned self] index in editLayout("Set Scale Mode", UIBuildEdit(scaleMode: modes[index])) }
        row("Scale", scalePicker)
        let none = UIBuildTransition(kind: .none)
        transitionRows("Show", build.show, name: "layoutShow", tooltip: "How the whole layout appears when the game shows it") { [unowned self] t in
            editLayout("Set Show Transition", UIBuildEdit(show: t ?? none, hide: build.show == nil && build.hide == nil ? t : nil))
        }
        let focusable = build.widgets.filter(\.type.isFocusable).map(\.id)
        let focusOptions = [""] + focusable + (focusable.contains(build.focus) || build.focus.isEmpty ? [] : [build.focus])
        let focusPicker = Dropdown(options: focusOptions.map { $0.isEmpty ? "(first)" : $0 }, selectedIndex: focusOptions.firstIndex(of: build.focus) ?? 0,
                                   name: "uiBuilderField.focus")
        focusPicker.tooltip = "The widget keyboard / gamepad focus starts at when the layout takes focus"
        focusPicker.onChange = { [unowned self] index in editLayout("Set First Focus", UIBuildEdit(focus: focusOptions[index])) }
        row("Focus first", focusPicker)
        textRow("Nav order", build.navigation.joined(separator: ", "), placeholder: "nearest widget", name: "navigation",
                tooltip: "Widget ids, comma separated: Down / Right step through them and Up / Left step back (wrapping)") { [unowned self] text in
            editLayout("Set Navigation Order", UIBuildEdit(navigation: text.split(separator: ",").map(String.init)))
        }
        transitionRows("Hide", build.hide, name: "layoutHide", tooltip: "How the whole layout goes away when the game hides it") { [unowned self] t in
            editLayout("Set Hide Transition", UIBuildEdit(hide: t ?? none))
        }
        sidebar.addChild(Label("Theme colors", role: .secondary))
        let theme = build.makeTheme()
        for name in UIBuild.themeColorNames {
            // The swatch shows the color in use (the override, else the base theme's); Reset drops the override.
            let swatch = ColorSwatch(color: theme.uiBuildColor(name) ?? .clear, name: "uiBuilderField.color.\(name)")
            swatch.tooltip = build.colors[name].map { "\(name): \($0) (changed from the \(build.theme) theme)" } ?? "\(name): the \(build.theme) theme's"
            swatch.onEditEnded = { [unowned self] _, end in
                editLayout("Set \(name) Color", UIBuildEdit(colors: [name: DataTableValues.hex(Vec4(end.r, end.g, end.b, end.a))]))
            }
            swatch.style.grow = 1
            var parts: [Widget] = [swatch]
            if build.colors[name] != nil {
                let reset = Button("Reset", name: "uiBuilderField.color.\(name).reset") { [unowned self] in
                    editLayout("Reset \(name) Color", UIBuildEdit(colors: [name: ""]))
                }
                reset.tooltip = "Use the \(build.theme) theme's \(name) again"
                parts.append(reset)
            }
            row(name, HStack(spacing: 4, parts))
        }
    }

    private func addValuesForm() {
        sidebar.addChild(Label("Sample values", role: .secondary))
        let keys = Array(Set(build.valueKeys).union(build.values.keys)).sorted()
        if keys.isEmpty { sidebar.addChild(note("Bind a widget or write {key} in a text to add a value.")) }
        for key in keys {
            textRow(key, build.values[key].map(UIBuild.display) ?? "", placeholder: "(unset)", name: "value.\(key)") { [unowned self] text in
                editLayout("Set Sample Value", UIBuildEdit(values: [key: Self.parseValue(text)]))
            }
        }
        if !previewValues.isEmpty {
            sidebar.addChild(note("The preview also shows values from uiLayout.open: " + previewValues.keys.sorted().joined(separator: ", ")))
        }
        let events = build.events
        sidebar.addChild(note(events.isEmpty ? "No button events." : "Events game code can handle: " + events.joined(separator: ", ")))
    }

    /// Text typed for a value: "" removes it, true/false and numbers are typed, anything else is text.
    static func parseValue(_ text: String) -> JSONValue {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .null }
        if trimmed == "true" { return .bool(true) }
        if trimmed == "false" { return .bool(false) }
        if let n = Int64(trimmed) { return .int(n) }
        if let d = Double(trimmed) { return .double(d) }
        return .string(text)
    }

    private func imagePaths() -> [String] {
        guard let assets = session.assets else { return [] }
        let extensions: Set<String> = ["png", "jpg", "jpeg", "tga", "bmp", "proctex", "ktx", "ktx2", "dds", "hdr", "exr"]
        return assets.allRecords.map(\.path).filter { extensions.contains(($0 as NSString).pathExtension.lowercased()) }
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "uiBuilderNote")
        label.wraps = true
        return label
    }
}

extension JSONValue {
    fileprivate var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
}

/// The UI Builder's preview: the layout drawn by a `UIBuildView` in a context of its own at the
/// chosen screen size, scaled to fit the panel. Click to select, drag to move, or (Interact)
/// press its buttons.
@MainActor
public final class UIBuildPreviewCanvas: Widget {
    weak var workspace: UIBuilderWorkspace?
    /// The context the preview's widgets live in (its own coordinates: the screen's points).
    public let previewContext = UIContext()
    /// The view games use, showing the layout.
    public let preview = UIBuildView(name: "uiBuilderPreviewView")
    /// Where the screen is drawn in the panel, and its scale.
    public private(set) var screenRect = UIRect.zero
    public private(set) var previewScale: Float = 1
    private var drag: (id: String, start: Vec2, offset: Vec2, anchor: UIBuildAnchor)?
    private var forwarding = false
    /// The editor's time at the last draw: the preview's context has no clock, so transitions and tweens step from it.
    private var lastTime: Double?

    public override init(name: String = "") {
        super.init(name: name)
        clipsContent = true
        preview.showsPlaceholders = true
        previewContext.root.addChild(preview)
        preview.onEvent = { [weak self] event in self?.workspace?.previewEvent(event) }
    }

    /// Lays the preview out at `size` and works out where it goes in `frame`.
    func placeScreen() {
        let size = workspace?.effectivePreviewSize ?? preview.build.size
        let room = frame.inset(by: 16)
        let s = max(min(room.width / max(size.x, 1), room.height / max(size.y, 1), 2), 0.05)
        previewScale = s
        screenRect = UIRect(x: (frame.x + (frame.width - size.x * s) / 2).rounded(), y: (frame.y + (frame.height - size.y * s) / 2).rounded(),
                            width: size.x * s, height: size.y * s)
        previewContext.setViewport(size: size, scale: scale * s)
        previewContext.layoutIfNeeded()
    }

    /// A point in the panel → the preview screen's points.
    public func screenPoint(_ point: Vec2) -> Vec2 {
        Vec2((point.x - screenRect.x) / previewScale, (point.y - screenRect.y) / previewScale)
    }

    /// The layout widget under a point in the preview's own coordinates (the deepest one).
    public func pick(_ point: Vec2) -> String? {
        func visit(_ widget: Widget) -> String? {
            guard !widget.isHidden, widget.frame.contains(point) || widget === preview else { return nil }
            for child in widget.children.reversed() {
                if let hit = visit(child) { return hit }
            }
            return preview.layoutID(of: widget)
        }
        return visit(preview)
    }

    public override func layoutChildren() {
        super.layoutChildren()
        placeScreen()
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.fieldBackground)
        if let now = context?.time {
            if let lastTime { preview.advance(by: now - lastTime) }
            lastTime = preview.isAnimating ? now : nil
        }
        placeScreen()
        list.withClip(screenRect) {
            list.fillRect(screenRect, fill: .linearGradient(start: UIColor(hex: 0x3c4a5e), end: UIColor(hex: 0x151a22)))
            list.withTransform(scale: previewScale, offset: Vec2(screenRect.x, screenRect.y)) {
                previewContext.draw(into: list)
                if let workspace, let id = workspace.selected, !workspace.isInteractive, let widget = preview.widget(id), widget.isEffectivelyVisible {
                    list.strokeRect(widget.frame, color: theme.accent, width: 2 / previewScale)
                }
            }
        }
        list.strokeRect(screenRect, color: theme.panelBorder)
        if previewContext.paintDirty || preview.isAnimating || preview.build.widgets.contains(where: { $0.trail }) { setNeedsDisplay() }
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard let workspace, workspace.asset != nil else { return false }
        switch event {
        case .pointerDown(let e) where e.button == .left:
            let p = screenPoint(e.position)
            if workspace.isInteractive {
                forwarding = true
                previewContext.pointerMoved(to: p)
                previewContext.pointerButton(.left, down: true)
                setNeedsDisplay()
                return true
            }
            let id = pick(p)
            workspace.select(id)
            if let id, workspace.isDraggable(id), let w = workspace.build.widget(id) {
                drag = (id, e.position, w.offset, w.anchor)
            }
            return true
        case .pointerDrag(let e):
            if forwarding {
                previewContext.pointerMoved(to: screenPoint(e.position))
                return true
            }
            guard let drag else { return true }
            // Panel points → the layout's design points (a scaled layout moves less per point).
            let delta = (e.position - drag.start) / (previewScale * max(preview.layoutScale, 0.05))
            var offset = drag.offset
            switch drag.anchor {
            case .topRight, .right, .bottomRight: offset.x -= delta.x
            default: offset.x += delta.x
            }
            switch drag.anchor {
            case .bottomLeft, .bottom, .bottomRight: offset.y -= delta.y
            default: offset.y += delta.y
            }
            workspace.dragPreview(drag.id, offset: Vec2(offset.x.rounded(), offset.y.rounded()))
            setNeedsDisplay()
            return true
        case .pointerUp(let e):
            if forwarding {
                forwarding = false
                previewContext.pointerMoved(to: screenPoint(e.position))
                previewContext.pointerButton(.left, down: false)
                setNeedsDisplay()
                return true
            }
            if let drag {
                self.drag = nil
                workspace.endDrag(drag.id)
            }
            return true
        case .pointerMove(let e):
            if workspace.isInteractive {
                previewContext.pointerMoved(to: screenPoint(e.position))
                setNeedsDisplay()
            }
            return false
        default:
            return false
        }
    }
}
