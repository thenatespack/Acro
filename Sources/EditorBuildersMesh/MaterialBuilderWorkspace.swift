import EditorCore
import Engine
import Foundation

// The Material Builder tab: a workspace for one `.material` file's node graph, tabbed with the
// Scene view. The top left previews the material on a sphere, cube, plane or the scene's
// selection (all its meshes, at their scale and arrangement), with a light and background picker (orbit with right-drag, Shift pans, the
// wheel zooms; Animate runs the graph's time). Below it, the graph canvas shows the nodes and
// their links: click a node to edit it, drag it to move it, drag from a node's output port
// (the dot right of its title) to an input row to link them, and drag a linked input's port
// away to move the link or, dropped on nothing, delete it. The sidebar holds presets, the
// material's alpha settings, the PBR outputs, Add Node and the selected node's inputs and
// settings. Every change is written to the file as one undo step and reimported, which compiles
// the graph into its shader variant; the preview and placed copies update.

/// Draws a material graph: a box per node with its inputs, the outputs box, and a wire per link.
@MainActor
public final class MaterialGraphCanvas: Widget {
    public var graph = MaterialGraph() { didSet { setNeedsDisplay() } }
    public var selected: String? { didSet { setNeedsDisplay() } }
    /// Clicked a node (nil: the background).
    public var onSelect: ((String?) -> Void)?
    /// Dragged a node to a new grid position.
    public var onMove: ((String, Vec2) -> Void)?
    /// Dragged a link: `source` (a link such as "noise" or "tex.rgb") to `target` ("node.input"
    /// or "output.<name>"; nil: dropped on nothing), taken off the input `detached` (nil: a new
    /// link from an output port). One edit.
    public var onLink: ((_ source: String, _ target: String?, _ detached: String?) -> Void)?

    static let columnWidth: Float = 150, rowHeight: Float = 64, boxWidth: Float = 128
    static let headerHeight: Float = 18, lineHeight: Float = 13
    private var pan = Vec2(16, 12)
    private var drag: (id: String?, start: Vec2, origin: Vec2, moved: Bool)?
    private var dragOffset = Vec2.zero
    /// A link being dragged: its source, the pointer, and the input it was taken off.
    private(set) var linkDrag: (source: String, position: Vec2, detached: String?)?
    /// How close (points) the pointer must be to a port to grab it.
    static let portRadius: Float = 8

    public override init(name: String = "materialGraphCanvas") {
        super.init(name: name)
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(320, 220) }

    /// Each node's grid position: its own, or a column by depth from the outputs.
    func layout() -> [String: Vec2] {
        var depth: [String: Int] = [:]
        func visit(_ id: String, _ d: Int, _ seen: Set<String>) {
            guard let node = graph.node(id), !seen.contains(id) else { return }
            if d <= depth[id] ?? -1 { return }
            depth[id] = d
            for link in node.links { visit(link, d + 1, seen.union([id])) }
        }
        for value in graph.output.values {
            if case .string(let s) = value, let link = MaterialGraphLink(s) { visit(link.node, 0, []) }
        }
        let maxDepth = (depth.values.max() ?? 0) + 1
        var rows: [Int: Int] = [:]
        var result: [String: Vec2] = [:]
        for node in graph.nodes {
            if let position = node.position {
                result[node.id] = position
                continue
            }
            let column = maxDepth - (depth[node.id] ?? maxDepth)
            let row = rows[column, default: 0]
            rows[column] = row + 1
            result[node.id] = Vec2(Float(column), Float(row))
        }
        return result
    }

    private var outputColumn: Float { (layout().values.map(\.x).max() ?? -1) + 1 }

    private func rect(at grid: Vec2, rows: Int) -> UIRect {
        let origin = Vec2(contentRect.x, contentRect.y) + pan + Vec2(grid.x * Self.columnWidth, grid.y * Self.rowHeight)
        return UIRect(x: origin.x, y: origin.y, width: Self.boxWidth, height: Self.headerHeight + Float(max(rows, 1)) * Self.lineHeight + 4)
    }

    private func inputs(of node: MaterialGraphNode) -> [String] {
        MaterialGraphNodeType.catalog[node.type]?.inputs.map(\.name) ?? node.fields.keys.sorted()
    }

    func nodeRects() -> [(id: String, rect: UIRect)] {
        let positions = layout()
        return graph.nodes.map { node in
            var grid = positions[node.id] ?? .zero
            if let drag, drag.id == node.id { grid += dragOffset }
            return (node.id, rect(at: grid, rows: inputs(of: node).count))
        }
    }

    var outputsRect: UIRect { rect(at: Vec2(outputColumn, 0), rows: MaterialGraph.outputs.count) }

    static func outputPort(_ r: UIRect) -> Vec2 { Vec2(r.x + r.width, r.y + headerHeight / 2) }
    static func inputPort(_ r: UIRect, _ row: Int) -> Vec2 { Vec2(r.x, r.y + headerHeight + (Float(row) + 0.5) * lineHeight) }

    /// Every input row: its target ("node.input" / "output.name"), box and row.
    private func inputRows() -> [(target: String, rect: UIRect, row: Int)] {
        var rows: [(String, UIRect, Int)] = []
        let rects = Dictionary(nodeRects().map { ($0.id, $0.rect) }, uniquingKeysWith: { a, _ in a })
        for node in graph.nodes {
            guard let r = rects[node.id] else { continue }
            for (row, name) in inputs(of: node).enumerated() { rows.append((node.id + "." + name, r, row)) }
        }
        let outputs = outputsRect
        for (row, output) in MaterialGraph.outputs.enumerated() { rows.append(("output." + output.name, outputs, row)) }
        return rows
    }

    /// The link string an input holds ("node.input" / "output.name"), if it is linked.
    func link(at target: String) -> String? {
        guard let dot = target.lastIndex(of: ".") else { return nil }
        let owner = String(target[..<dot]), key = String(target[target.index(after: dot)...])
        let value = owner == "output" && graph.node("output") == nil ? graph.output[key] : graph.node(owner)?[key]
        if case .string(let s)? = value, MaterialGraphLink(s) != nil { return s }
        return nil
    }

    /// The input row under `point` (anywhere on the row, or its port just left of the box).
    func dropTarget(at point: Vec2) -> String? {
        inputRows().last { row in
            let y = row.rect.y + Self.headerHeight + Float(row.row) * Self.lineHeight
            return point.x >= row.rect.x - Self.portRadius && point.x <= row.rect.x + row.rect.width && point.y >= y && point.y < y + Self.lineHeight
        }?.target
    }

    /// Whether linking `source` into `target` would make a cycle (the target's node feeds the source).
    func makesCycle(source: String, target: String) -> Bool {
        guard let from = MaterialGraphLink(source)?.node, let dot = target.lastIndex(of: ".") else { return false }
        let owner = String(target[..<dot])
        guard owner != "output" || graph.node("output") != nil else { return false }
        var stack = [from], seen = Set<String>()
        while let id = stack.popLast() {
            if id == owner { return true }
            guard seen.insert(id).inserted, let node = graph.node(id) else { continue }
            stack += node.links
        }
        return false
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let area = contentRect
        list.fillRect(area, color: UIColor(0.07, 0.08, 0.1, 1), radii: UICornerRadii(4))
        list.pushClip(area)
        do {
            let rects = Dictionary(nodeRects().map { ($0.id, $0.rect) }, uniquingKeysWith: { a, _ in a })
            let outputs = outputsRect
            func inputPoint(_ r: UIRect, _ row: Int) -> Vec2 { Self.inputPort(r, row) }
            let detached = linkDrag?.detached
            func wire(from source: String, to point: Vec2, target: String? = nil) {
                guard let s = rects[source], target == nil || target != detached else { return }
                let start = Self.outputPort(s)
                let mid = (start.x + point.x) / 2
                let color = theme.accent.withAlpha(0.8)
                list.drawLine(from: start, to: Vec2(mid, start.y), width: 1.5, color: color)
                list.drawLine(from: Vec2(mid, start.y), to: Vec2(mid, point.y), width: 1.5, color: color)
                list.drawLine(from: Vec2(mid, point.y), to: point, width: 1.5, color: color)
            }
            for node in graph.nodes {
                guard let r = rects[node.id] else { continue }
                for (row, name) in inputs(of: node).enumerated() {
                    if case .string(let s)? = node[name], let link = MaterialGraphLink(s) {
                        wire(from: link.node, to: inputPoint(r, row), target: node.id + "." + name)
                    }
                }
            }
            for (row, output) in MaterialGraph.outputs.enumerated() {
                if case .string(let s)? = graph.output[output.name], let link = MaterialGraphLink(s) {
                    wire(from: link.node, to: inputPoint(outputs, row), target: "output." + output.name)
                }
            }
            func box(_ r: UIRect, title: String, rows: [String], highlighted: Bool, linked: [Bool]) {
                list.fillRect(r, color: theme.controlBackground, radii: UICornerRadii(4))
                list.fillRect(UIRect(x: r.x, y: r.y, width: r.width, height: Self.headerHeight),
                              color: highlighted ? theme.accent : theme.controlHover, radii: UICornerRadii(4))
                list.strokeRect(r, color: highlighted ? theme.accent : theme.controlBorder, width: 1, radii: UICornerRadii(4))
                list.drawText(title, at: Vec2(r.x + 6, r.y + 3), size: 11, color: theme.textColor)
                for (i, row) in rows.enumerated() {
                    let y = r.y + Self.headerHeight + Float(i) * Self.lineHeight + 1
                    list.drawText(row, at: Vec2(r.x + 8, y), size: 10, color: linked[i] ? theme.textColor : theme.secondaryTextColor)
                }
            }
            for node in graph.nodes {
                guard let r = rects[node.id] else { continue }
                let names = inputs(of: node)
                box(r, title: "\(node.id) · \(node.type)", rows: names, highlighted: node.id == selected,
                    linked: names.map { if case .string? = node[$0] { true } else { false } })
            }
            box(outputs, title: "Output", rows: MaterialGraph.outputs.map(\.name), highlighted: false,
                linked: MaterialGraph.outputs.map { if case .string? = graph.output[$0.name] { true } else { false } })
            // Ports: each node's output, and every input row (filled when linked).
            func dot(_ c: Vec2, _ r: Float, _ color: UIColor) {
                list.fillRect(UIRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2), color: color, radii: UICornerRadii(r))
            }
            for node in graph.nodes {
                guard let r = rects[node.id] else { continue }
                dot(Self.outputPort(r), 3.5, theme.accent)
            }
            for row in inputRows() {
                let linked = link(at: row.target) != nil && row.target != detached
                dot(Self.inputPort(row.rect, row.row), 3, linked ? theme.accent : theme.controlBorder)
            }
            // The link being dragged, to the pointer (highlighting the input it would drop on).
            if let linkDrag, let source = MaterialGraphLink(linkDrag.source)?.node {
                if let target = dropTarget(at: linkDrag.position), let row = inputRows().first(where: { $0.target == target }) {
                    let y = row.rect.y + Self.headerHeight + Float(row.row) * Self.lineHeight
                    let ok = !makesCycle(source: linkDrag.source, target: target)
                    list.strokeRect(UIRect(x: row.rect.x, y: y, width: row.rect.width, height: Self.lineHeight),
                                    color: ok ? theme.accent : UIColor(0.9, 0.3, 0.3, 1), width: 1, radii: UICornerRadii(2))
                }
                wire(from: source, to: linkDrag.position)
            }
        }
        list.popClip()
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e):
            func near(_ p: Vec2) -> Bool { let d = p - e.position; return (d * d).sum() <= Self.portRadius * Self.portRadius }
            // An output port starts a new link; a linked input's port picks its link up.
            if let port = nodeRects().last(where: { near(Self.outputPort($0.rect)) }) {
                linkDrag = (port.id, e.position, nil)
                setNeedsDisplay()
                return true
            }
            if let row = inputRows().last(where: { near(Self.inputPort($0.rect, $0.row)) }), let source = link(at: row.target) {
                linkDrag = (source, e.position, row.target)
                setNeedsDisplay()
                return true
            }
            let hit = nodeRects().last { r in
                e.position.x >= r.rect.x && e.position.x <= r.rect.x + r.rect.width && e.position.y >= r.rect.y && e.position.y <= r.rect.y + r.rect.height
            }
            let origin = hit.flatMap { layout()[$0.id] } ?? .zero
            drag = (hit?.id, e.position, origin, false)
            dragOffset = .zero
            onSelect?(hit?.id)
            return true
        case .pointerDrag(let e):
            if linkDrag != nil {
                linkDrag?.position = e.position
                setNeedsDisplay()
                return true
            }
            guard var d = drag else { return false }
            let delta = e.position - d.start
            if abs(delta.x) + abs(delta.y) > 3 { d.moved = true }
            drag = d
            if d.id != nil {
                dragOffset = Vec2((delta.x / Self.columnWidth).rounded(), (delta.y / Self.rowHeight * 2).rounded() / 2)
            } else {
                pan += delta
                drag?.start = e.position
            }
            setNeedsDisplay()
            return true
        case .pointerUp(let e):
            if let link = linkDrag {
                linkDrag = nil
                setNeedsDisplay()
                let target = dropTarget(at: e.position)
                if let target, target == link.detached || makesCycle(source: link.source, target: target) { return true }
                if target == nil && link.detached == nil { return true }  // a new link dropped on nothing
                onLink?(link.source, target, link.detached)
                return true
            }
            if let d = drag, let id = d.id, d.moved, dragOffset != .zero {
                onMove?(id, Vec2(max(d.origin.x + dragOffset.x, 0), max(d.origin.y + dragOffset.y, 0)))
            }
            drag = nil
            dragOffset = .zero
            setNeedsDisplay()
            return true
        case .scroll(let delta, _):
            pan += delta
            setNeedsDisplay()
            return true
        default:
            return false
        }
    }
}

@MainActor
public final class MaterialBuilderWorkspace {
    public typealias PreviewShape = MaterialPreviewShape
    public typealias PreviewLight = MaterialPreviewLight
    public typealias PreviewBackground = MaterialPreviewBackground

    public let session: EditorSession
    public let view: VStack
    /// The material being edited (nil: nothing open) and its file contents.
    public private(set) var asset: AssetID?
    public private(set) var material = MaterialAsset()
    public private(set) var selectedNode: String?
    public private(set) var shape = PreviewShape.sphere
    public private(set) var light = PreviewLight.studio
    public private(set) var background = PreviewBackground.gray
    /// Whether the graph's time runs in the preview.
    public var animates = true
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: .zero, yaw: -0.6, pitch: 0.35, distance: 3.2))
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "materialViewport", label: "Material preview")
    let canvas = MaterialGraphCanvas()
    private let title = Label("Material Builder", role: .heading, name: "materialTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "materialSidebar")
    private let shapePicker = Dropdown(options: PreviewShape.allCases.map { $0.rawValue.capitalized }, name: "materialPreviewShape")
    private let lightPicker = Dropdown(options: PreviewLight.allCases.map { $0.rawValue.capitalized }, name: "materialPreviewLight")
    private let backgroundPicker = Dropdown(options: PreviewBackground.allCases.map { $0.rawValue.capitalized }, name: "materialPreviewBackground")
    private let animateToggle = Checkbox("Animate", isOn: true, kind: .toggleSwitch, name: "materialAnimate")
    private var preview: Entity
    private var lightEntity: Entity
    /// The Selected shape: one child of `preview` per mesh of the scene's selection, and what
    /// they were built from (rebuilt, and the camera refit, when it changes).
    private(set) var selectionParts: [Entity] = []
    private var shownSelection: [SelectionPart]?
    private var meshBoundsCache: [String: Bounds] = [:]
    private var shownRevision = -1
    private var pendingEdit: (MaterialAsset, String)?
    private let undoStack: UndoStack

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?

    public init(session: EditorSession) {
        self.session = session
        undoStack = UndoStack(world: world)
        view = VStack(spacing: 0, name: "materialWorkspace")
        lightEntity = world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-40, 35, 0))), Name("Light"),
                                  DirectionalLight(intensity: 2.5, castsShadows: false))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        preview = world.spawn(Transform(), Name("Preview"), MeshRenderer(mesh: .sphere))
        layOutChrome()
        showEmpty()
    }

    var materialKey: String? { asset.map { AssetReference($0, subAsset: "material").description } }

    // MARK: Opening

    /// Shows `id` (a `.material` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isMaterialFile(id), let material = session.assets?.materialFile(of: id) else { return false }
        if asset != id {
            asset = id
            shownRevision = -1
            selectedNode = nil
            self.material = material
            canvas.selected = nil
            buildForm()
        }
        title.text = session.assets?.record(id)?.fileName ?? "Material Builder"
        title.icon = EditorIcons.named("palette")
        return true
    }

    public func close() {
        asset = nil
        showEmpty()
    }

    public func select(_ node: String?) {
        selectedNode = node.flatMap { material.graph?.node($0) != nil ? $0 : nil }
        canvas.selected = selectedNode
        buildForm()
    }

    public func setPreview(shape: PreviewShape? = nil, light: PreviewLight? = nil, background: PreviewBackground? = nil) {
        if let shape {
            self.shape = shape
            shapePicker.select(PreviewShape.allCases.firstIndex(of: shape) ?? 0)
        }
        if let light {
            self.light = light
            lightPicker.select(PreviewLight.allCases.firstIndex(of: light) ?? 0)
        }
        if let background {
            self.background = background
            backgroundPicker.select(PreviewBackground.allCases.firstIndex(of: background) ?? 0)
        }
        applyPreviewSettings()
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "materialToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        shapePicker.tooltip = "What the preview shows the material on (Selected: every mesh of the scene's selection, at its scale and arrangement)"
        shapePicker.onChange = { [unowned self] i in setPreview(shape: PreviewShape.allCases[i]) }
        lightPicker.tooltip = "Preview lighting"
        lightPicker.onChange = { [unowned self] i in setPreview(light: PreviewLight.allCases[i]) }
        backgroundPicker.tooltip = "Preview background"
        backgroundPicker.onChange = { [unowned self] i in setPreview(background: PreviewBackground.allCases[i]) }
        animateToggle.tooltip = "Run the graph's time (scrolling UVs, time nodes) in the preview"
        animateToggle.onChange = { [unowned self] on in animates = on }
        let closeButton = Button("Close", name: "materialClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this material"
        bar.addChildren([shapePicker, lightPicker, backgroundPicker, animateToggle, closeButton])

        canvas.onSelect = { [unowned self] id in select(id) }
        canvas.onLink = { [unowned self] source, target, detached in
            edit(target == nil ? "Disconnect" : "Connect") { material in
                guard var graph = material.graph else { return }
                if let detached { try? MaterialGraphEditCommand.setInput(detached, to: .null, in: &graph) }
                if let target { try? MaterialGraphEditCommand.setInput(target, to: .string(source), in: &graph) }
                material.graph = graph
            }
        }
        canvas.onMove = { [unowned self] id, position in
            edit("Move Node") { material in
                guard let i = material.graph?.index(of: id) else { return }
                material.graph?.nodes[i].position = position
            }
        }
        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        canvas.style.grow = 1
        canvas.style.shrink = 1
        let left = VStack(spacing: 0, alignment: .stretch, name: "materialLeft", [viewportWidget, Separator(), canvas])
        left.style.grow = 1
        left.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "materialSidebarScroll")
        scroll.style.width = 360
        let body = HStack(spacing: 0, alignment: .stretch, name: "materialBody", [left, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Material Builder"
        title.icon = EditorIcons.named("palette")
        sidebar.removeAllChildren()
        canvas.graph = MaterialGraph()
        let note = Label("Double-click a .material file in the Assets panel (or use Open in Material Builder in its inspector) to edit "
                         + "its node graph here, or make one:", role: .caption)
        note.wraps = true
        let new = Button("New Material Graph", role: .primary, name: "materialNew") { [unowned self] in
            if let id = session.run(MaterialGraphNewCommand.self, .init(preset: "basic"))?.asset {
                session.run(MaterialGraphOpenCommand.self, .init(asset: AssetReference(id)))
            }
        }
        new.command = MaterialGraphNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No material open"
    }

    // MARK: Form

    /// Records `change` to the material as one undo step (applied before the next layout).
    func edit(_ label: String, _ change: (inout MaterialAsset) -> Void) {
        var edited = pendingEdit?.0 ?? material
        change(&edited)
        pendingEdit = (edited, label)
    }

    static func text(_ value: JSONValue?) -> String {
        switch value {
        case .string(let s)?: s
        case .int(let i)?: String(i)
        case .double(let d)?: String(format: "%g", d)
        case .bool(let b)?: b ? "1" : "0"
        case .array(let items)?: items.map { text($0) }.joined(separator: ", ")
        default: ""
        }
    }

    /// Parses an input field: numbers ("0.5", "1, 0, 0") are a constant, anything else a link, empty resets.
    static func value(_ text: String) -> JSONValue? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(whereSeparator: { $0 == "," || $0 == " " }).map(String.init)
        let numbers = parts.compactMap(Double.init)
        if numbers.count == parts.count, (1...4).contains(numbers.count) {
            return numbers.count == 1 ? .double(numbers[0]) : .array(numbers.map { .double($0) })
        }
        return .string(text.trimmingCharacters(in: .whitespaces))
    }

    private func sectionLabel(_ text: String) -> Label { Label(text, role: .secondary) }

    /// A row editing one input (or output): a text field for a constant or link, and a link picker.
    private func inputRow(_ name: String, value: JSONValue?, placeholder: String, tooltip: String, excluding: String?,
                          set: @escaping (JSONValue?) -> Void) -> HStack {
        let label = Label(name, role: .body)
        label.style.width = 86
        label.tooltip = tooltip
        let field = TextField(text: Self.text(value), placeholder: placeholder, name: "materialInput.\(excluding ?? "output").\(name)")
        field.preferredWidth = 120
        field.style.grow = 1
        field.style.shrink = 1
        field.tooltip = "A number, 2-4 numbers (\"1, 0.5, 0\"), or a link: a node id, optionally with a swizzle (\"tex.rgb\", \"n.x\")"
        let commit: (String) -> Void = { text in
            let new = Self.value(text)
            if new != value { set(new) }
        }
        field.onSubmit = commit
        field.onEndEditing = commit
        let nodes = (material.graph?.nodes.map(\.id) ?? []).filter { $0 != excluding }
        let options = ["Link…"] + nodes + ["uv", "position", "normal", "viewDir", "vertexColor", "time"]
        let picker = Dropdown(options: options, name: "materialLink.\(excluding ?? "output").\(name)")
        picker.style.width = 74
        picker.tooltip = "Link this input to a node's output or a built-in"
        picker.onChange = { i in if i > 0 { set(.string(options[i])) } }
        return HStack(spacing: 4, [label, field, picker])
    }

    private func buildForm() {
        sidebar.removeAllChildren()
        guard let asset else { return showEmpty() }
        canvas.graph = material.graph ?? MaterialGraph()
        canvas.selected = selectedNode

        guard let graph = material.graph else {
            let note = Label("This material uses fixed PBR settings (edit them in the inspector). Convert it to a node graph to build "
                             + "its look from textures, noise and math, or start from a preset.", role: .caption)
            note.wraps = true
            let convert = Button("Convert to Graph", role: .primary, name: "materialConvert") { [unowned self] in
                edit("Convert to Material Graph") { $0.graph = graphFromFixedFields($0) }
            }
            convert.command = MaterialGraphSetCommand.id.rawValue
            sidebar.addChildren([note, HStack(spacing: 6, [convert, Spacer()]), sectionLabel("Presets"), presetButtons()])
            return
        }

        sidebar.addChildren([sectionLabel("Presets"), presetButtons()])

        // Material settings.
        let modes = ["opaque", "mask", "blend"]
        let mode = Dropdown(options: modes.map(\.capitalized), selectedIndex: modes.firstIndex(of: material.alphaMode.rawValue.lowercased()) ?? 0,
                            name: "materialAlphaMode")
        mode.tooltip = "Opaque ignores opacity; Mask discards below the cutoff; Blend draws see-through"
        mode.onChange = { [unowned self] i in edit("Alpha Mode") { $0.alphaMode = AlphaMode(rawValue: modes[i].uppercased()) ?? .opaque } }
        let sides = Checkbox("Double-sided", isOn: material.doubleSided, name: "materialDoubleSided")
        sides.onChange = { [unowned self] on in edit("Double-sided") { $0.doubleSided = on } }
        sidebar.addChildren([sectionLabel("Material"), HStack(spacing: 6, [Label("Alpha"), mode, sides, Spacer()])])
        if material.alphaMode == .mask {
            let cutoff = NumberField(value: Double(material.alphaCutoff), range: 0...1, step: 0.01, name: "materialAlphaCutoff")
            cutoff.onEditEnded = { [unowned self] _, end in edit("Alpha Cutoff") { $0.alphaCutoff = Float(end) } }
            sidebar.addChild(HStack(spacing: 6, [Label("Cutoff"), cutoff, Spacer()]))
        }

        // Outputs.
        sidebar.addChild(sectionLabel("Outputs"))
        for output in MaterialGraph.outputs {
            let placeholder = output.defaultValue.map { String(format: "%g", $0) }.joined(separator: ", ")
            sidebar.addChild(inputRow(output.name, value: graph.output[output.name], placeholder: placeholder,
                                      tooltip: output.name == "normal" ? "Tangent-space normal (0, 0, 1 is flat)" : "",
                                      excluding: nil) { [unowned self] value in
                edit("Set \(output.name)") { $0.graph?.output[output.name] = value }
            })
        }

        // Add node.
        let types = MaterialGraphNodeType.all
        let add = Dropdown(options: ["Add Node…"] + types.map { "\($0.category): \($0.name)" }, name: "materialAddNode")
        add.tooltip = "Add a node; link it from an input or output below"
        add.onChange = { [unowned self] i in
            guard i > 0 else { return }
            let type = types[i - 1].name
            var newID = type
            edit("Add \(type) Node") { material in
                var graph = material.graph ?? MaterialGraph()
                newID = graph.uniqueID(type)
                graph.nodes.append(MaterialGraphNode(id: newID, type: type, position: MaterialGraphEditCommand.autoPosition(for: graph)))
                material.graph = graph
            }
            selectedNode = newID
        }
        add.command = MaterialGraphEditCommand.id.rawValue
        sidebar.addChildren([sectionLabel("Nodes"), add])

        // The selected node.
        if let id = selectedNode, let node = graph.node(id) {
            let type = MaterialGraphNodeType.catalog[node.type]
            let heading = Label("\(id) · \(node.type)", role: .heading)
            heading.tooltip = type?.summary
            let remove = Button("Delete", name: "materialDeleteNode") { [unowned self] in
                edit("Delete Node") { material in
                    guard var graph = material.graph else { return }
                    MaterialGraphEditCommand.removeNode(id, from: &graph)
                    material.graph = graph
                }
                selectedNode = nil
            }
            remove.tooltip = "Remove this node; inputs linked to it go back to their defaults"
            let duplicate = Button("Duplicate", name: "materialDuplicateNode") { [unowned self] in
                var newID = id
                edit("Duplicate Node") { material in
                    guard var graph = material.graph, var copy = graph.node(id) else { return }
                    newID = graph.uniqueID(id)
                    copy.id = newID
                    copy.position = copy.position.map { $0 + Vec2(0, 1) }
                    graph.nodes.append(copy)
                    material.graph = graph
                }
                selectedNode = newID
            }
            sidebar.addChild(HStack(spacing: 6, [heading, Spacer(), duplicate, remove]))
            if let summary = type?.summary {
                let note = Label(summary, role: .caption)
                note.wraps = true
                sidebar.addChild(note)
            }
            for input in type?.inputs ?? [] {
                let placeholder = input.defaultLink ?? input.defaultValue.map { String(format: "%g", $0) }.joined(separator: ", ")
                sidebar.addChild(inputRow(input.name, value: node[input.name], placeholder: placeholder, tooltip: input.tooltip,
                                          excluding: id) { [unowned self] value in
                    edit("Set \(id).\(input.name)") { material in
                        guard let i = material.graph?.index(of: id) else { return }
                        material.graph?.nodes[i][input.name] = value
                    }
                })
            }
            for setting in type?.settings ?? [] {
                sidebar.addChild(settingRow(setting, node: node))
            }
        } else {
            let note = Label("Click a node in the graph to edit it.", role: .caption)
            sidebar.addChild(note)
        }

        // Problems.
        let warnings = session.assets?.materialGraphWarnings(material) ?? []
        if !warnings.isEmpty {
            sidebar.addChild(sectionLabel("Problems"))
            for warning in warnings {
                let label = Label(warning, role: .caption)
                label.wraps = true
                label.color = UIColor(hex: 0xe8b04a)
                sidebar.addChild(label)
            }
        }
    }

    private func presetButtons() -> HStack {
        let presets = HStack(spacing: 4, name: "materialPresets")
        presets.wraps = true
        for name in MaterialGraph.presetNames {
            let button = Button(name.capitalized, name: "materialPreset.\(name)") { [unowned self] in
                guard let preset = try? materialForGraphPreset(name) else { return }
                edit("Material Preset \(name.capitalized)") { material in
                    material.graph = preset.graph
                    material.alphaMode = preset.alphaMode
                }
                selectedNode = nil
            }
            button.command = MaterialGraphSetCommand.id.rawValue
            button.tooltip = "Replace the graph with the \(name) preset"
            presets.addChild(button)
        }
        return presets
    }

    private func settingRow(_ setting: MaterialGraphNodeType.Setting, node: MaterialGraphNode) -> HStack {
        let id = node.id
        let label = Label(setting.name)
        label.style.width = 86
        label.tooltip = setting.tooltip
        let current = node[setting.name] ?? setting.defaultValue
        func set(_ value: JSONValue?) {
            edit("Set \(id).\(setting.name)") { material in
                guard let i = material.graph?.index(of: id) else { return }
                material.graph?.nodes[i][setting.name] = value
            }
        }
        switch setting.kind {
        case .choice(let options):
            let picker = Dropdown(options: options, selectedIndex: options.firstIndex(of: Self.text(current)) ?? 0,
                                  name: "materialSetting.\(id).\(setting.name)")
            picker.onChange = { i in set(.string(options[i])) }
            return HStack(spacing: 4, [label, picker, Spacer()])
        case .integer(let range):
            let field = NumberField(value: Double(Self.text(current)) ?? Double(range.lowerBound), isInteger: true,
                                    range: Double(range.lowerBound)...Double(range.upperBound), step: 1,
                                    name: "materialSetting.\(id).\(setting.name)")
            field.onEditEnded = { _, end in set(.int(Int64(end))) }
            return HStack(spacing: 4, [label, field, Spacer()])
        case .flag:
            let box = Checkbox("", isOn: current == .bool(true), name: "materialSetting.\(id).\(setting.name)")
            box.onChange = { on in set(.bool(on)) }
            return HStack(spacing: 4, [label, box, Spacer()])
        case .texture:
            let textures = (session.assets?.references(of: .texture) ?? []).compactMap { reference -> String? in
                guard reference.subAsset == nil || reference.subAsset == "texture" else { return nil }
                return session.assets?.path(of: reference.asset)
            }
            let paths = Array(Set(textures)).sorted()
            let field = TextField(text: Self.text(current), placeholder: "Textures/rock.png", name: "materialSetting.\(id).\(setting.name)")
            field.style.grow = 1
            field.style.shrink = 1
            field.tooltip = setting.tooltip
            let commit: (String) -> Void = { text in
                let value: JSONValue? = text.isEmpty ? nil : .string(text)
                if value != node[setting.name] { set(value) }
            }
            field.onSubmit = commit
            field.onEndEditing = commit
            let picker = Dropdown(options: ["Pick…"] + paths, name: "materialTexturePick.\(id)")
            picker.style.width = 74
            picker.tooltip = "Pick an image or .proctex in the project"
            picker.onChange = { i in if i > 0 { set(.string(paths[i - 1])) } }
            return HStack(spacing: 4, [label, field, picker])
        }
    }

    // MARK: Per frame

    /// Applies the form's pending edit, follows the file, and handles the viewport pointer. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        if let (edited, label) = pendingEdit {
            pendingEdit = nil
            if session.applyMaterialFile(edited, to: asset, label: label) != nil {
                material = assets.materialFile(of: asset) ?? edited
                if let selectedNode, material.graph?.node(selectedNode) == nil { self.selectedNode = nil }
                buildForm()
            }
        }
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            shownRevision = revision
            if let fresh = assets.materialFile(of: asset), fresh != material {
                material = fresh
                buildForm()
            }
        }
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        if animates { world.update(dt: Double(dt)) }
        applyPreviewSettings()
        world.propagateTransforms()
    }

    /// The preview entity's mesh and material, the light and the background.
    private func applyPreviewSettings() {
        var mesh = MeshHandle.sphere
        var scale = Vec3(1.6, 1.6, 1.6)
        var rotation = Quat.identity
        let material = materialKey.map { MaterialHandle($0) } ?? .default
        let parts = shape == .selected ? selectedParts() : []
        switch shape {
        case .sphere: break
        case .cube: scale = Vec3(1.2, 1.2, 1.2)
        case .plane:
            scale = Vec3(2, 1, 2)
            rotation = Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))
        case .selected: break
        }
        if parts.isEmpty {
            if shownSelection != nil { showSelection(nil) }
            world.add(Transform(rotation: rotation, scale: scale), to: preview)
            world.add(MeshRenderer(mesh: mesh, material: material), to: preview)
        } else {
            if shownSelection != parts { showSelection(parts) }
            world.remove(MeshRenderer.self, from: preview)
            for part in selectionParts where world.get(MeshRenderer.self, for: part)?.material != material {
                if var renderer = world.get(MeshRenderer.self, for: part) {
                    renderer.material = material
                    world.add(renderer, to: part)
                }
            }
        }
        let (intensity, angles, ambient): (Float, Vec3, Float) = switch light {
        case .studio: (2.5, Vec3(-40, 35, 0), 0.6)
        case .sun: (4, Vec3(-70, 20, 0), 0.35)
        case .rim: (3.5, Vec3(-20, 160, 0), 0.25)
        case .dim: (0.6, Vec3(-40, 35, 0), 0.15)
        }
        world.add(Transform(rotation: Quat(eulerDegrees: angles)), to: lightEntity)
        world.add(DirectionalLight(intensity: intensity, castsShadows: false), to: lightEntity)
        world.query(SceneEnvironment.self) { entity, environment in
            if environment.ambientIntensity != ambient {
                var changed = environment
                changed.ambientIntensity = ambient
                world.add(changed, to: entity)
            }
        }
    }

    /// A mesh of the scene's selection, where it is in the scene.
    struct SelectionPart: Equatable {
        var mesh: MeshHandle
        var matrix: Mat4
    }

    /// Every mesh at or below the scene's selected entities, with its world matrix (each once).
    func selectedParts() -> [SelectionPart] {
        let sceneWorld = session.world
        var parts: [SelectionPart] = []
        var seen = Set<Entity>()
        var queue = session.selection.entities(in: sceneWorld)
        while !queue.isEmpty {
            let entity = queue.removeFirst()
            guard seen.insert(entity).inserted else { continue }
            if let renderer = sceneWorld.get(MeshRenderer.self, for: entity), renderer.isVisible {
                let matrix = sceneWorld.get(GlobalTransform.self, for: entity)?.matrix
                    ?? sceneWorld.get(Transform.self, for: entity)?.matrix ?? .identity
                parts.append(SelectionPart(mesh: renderer.mesh, matrix: matrix))
            }
            queue.append(contentsOf: sceneWorld.children(of: entity))
        }
        return parts
    }

    /// Rebuilds the Selected shape's meshes (nil: none), centered on the origin at their scene
    /// scale and arrangement, and fits the camera to them (back to the default without them).
    private func showSelection(_ parts: [SelectionPart]?) {
        for part in selectionParts { world.despawn(part) }
        selectionParts = []
        shownSelection = parts
        guard let parts else {
            viewport.camera.pivot = .zero
            viewport.camera.distance = 3.2
            return
        }
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for part in parts {
            let bounds = (meshBounds(part.mesh) ?? Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5))).transformed(by: part.matrix)
            lo = lo.replacing(with: bounds.center - bounds.halfExtent, where: bounds.center - bounds.halfExtent .< lo)
            hi = hi.replacing(with: bounds.center + bounds.halfExtent, where: bounds.center + bounds.halfExtent .> hi)
        }
        let center = (lo + hi) / 2
        let half = (hi - lo) / 2
        let radius = max((half * half).sum().squareRoot(), 0.01)
        world.add(Transform(position: -center), to: preview)
        for part in parts {
            let entity = world.spawn(Name("Selected Part"), MeshRenderer(mesh: part.mesh))
            world.add(Transform(matrix: part.matrix), to: entity)
            world.setParent(entity, to: preview)
            selectionParts.append(entity)
        }
        // Fit the box, seen from any side around Y and from a little above, into the view.
        let t = tanf(viewport.camera.fovY / 2)
        let aspect = viewport.rect.width > 0 && viewport.rect.height > 0 ? viewport.rect.width / viewport.rect.height : 16 / 9
        let across = max(half.x, half.z, 0.01), up = max(half.y, across * 0.4)
        viewport.camera.pivot = .zero
        viewport.camera.distance = max(up / t, across / (t * aspect)) * 1.15 + across * 0.5
        viewport.camera.far = max(1000, viewport.camera.distance + radius * 4)
    }

    private func meshBounds(_ handle: MeshHandle) -> Bounds? {
        if let cached = meshBoundsCache[handle.key] { return cached }
        let bounds = if let reference = handle.assetReference { session.assets?.mesh(reference)?.bounds } else { MeshGeometry.builtin(handle)?.bounds }
        if let bounds { meshBoundsCache[handle.key] = bounds }
        return bounds
    }

    var clearColor: Vec4 {
        switch background {
        case .gray: Vec4(0.3, 0.31, 0.33, 1)
        case .dark: Vec4(0.03, 0.035, 0.04, 1)
        case .light: Vec4(0.8, 0.8, 0.8, 1)
        case .sky: Vec4(0.35, 0.45, 0.6, 1)
        }
    }

    /// Sizes the render target to the panel; call after layout.
    public func prepareFrame(pixelScale: Float) {
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Material Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: clearColor)
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Material Builder needs the GPU to draw" : nil
        viewportWidget.caption = "Right-drag orbits · Shift pans · wheel zooms"
    }

    /// Renders the preview; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let view = currentView, sizer.width > 0 else { return }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        renderer.renderView(view, into: target, frame: frame)
    }

    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: EditorSelection(), undo: undoStack, view: view, viewportRect: viewport.rect,
                            pixelScale: 1, toolMode: session.tool, isPlaying: false,
                            meshBounds: { _ in nil }, commands: nil, snapping: false,
                            snapSteps: session.editorSettings.gizmoSnapping(enabled: false))
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "material view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Material Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

public enum MaterialGraphOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MaterialGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Preview on: sphere, cube, plane or selected (the selected entity's mesh).
        public var shape: String?
        /// Preview light: studio, sun, rim or dim.
        public var light: String?
        /// Preview background: gray, dark, light or sky.
        public var background: String?
        /// A node to select in the form.
        public var node: String?
        public init(asset: AssetReference? = nil, path: String? = nil, shape: String? = nil, light: String? = nil,
                    background: String? = nil, node: String? = nil) {
            self.asset = asset
            self.path = path
            self.shape = shape
            self.light = light
            self.background = background
            self.node = node
        }
    }

    public static let id: CommandID = "materialGraph.open"
    public static let title = "Open in Material Builder"
    public static let doc = "Opens a .material file in the editor's Material Builder tab (live preview, node graph canvas, outputs and node form) and brings the tab to the front. Optional preview `shape` (sphere, cube, plane, selected), `light` (studio, sun, rim, dim), `background` (gray, dark, light, sky) and a `node` to select. view.screenshot {source: \"panel\", panel: \"materialBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveMaterialFile(arguments, title)
        func parse<T: RawRepresentable & CaseIterable>(_ value: String?, _ type: T.Type, _ name: String) throws -> T? where T.RawValue == String {
            guard let value else { return nil }
            guard let parsed = T(rawValue: value.lowercased()) else {
                throw CommandError.failed("\(title): \(name) must be \(T.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            return parsed
        }
        let preview = MaterialPreviewRequest(shape: try parse(arguments.shape, MaterialBuilderWorkspace.PreviewShape.self, "shape"),
                                             light: try parse(arguments.light, MaterialBuilderWorkspace.PreviewLight.self, "light"),
                                             background: try parse(arguments.background, MaterialBuilderWorkspace.PreviewBackground.self, "background"),
                                             node: arguments.node)
        session.openMaterialGraph = id
        session.materialPreviewRequest = preview
        session.onOpenMaterialGraph?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

extension MaterialBuilderWorkspace {
    /// Applies (and clears) the session's pending `materialGraph.open` preview request.
    public func applyRequest(from session: EditorSession) {
        guard let request = session.materialPreviewRequest else { return }
        session.materialPreviewRequest = nil
        setPreview(shape: request.shape, light: request.light, background: request.background)
        if let node = request.node { select(node) }
    }
}
