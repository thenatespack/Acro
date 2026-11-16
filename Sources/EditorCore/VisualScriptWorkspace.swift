import Engine
import Foundation

// The Visual Script tab: one `.vscript` graph on a canvas, tabbed with the Scene view, with a sidebar.
//
// - The canvas draws the event graph (or a function's nodes): drag nodes to move them, drag
//   from a pin to another to wire them, drop a wire on empty space (or right-click) to search
//   for a node to add there (filtered by the dragged pin's type), right-click a pin to cut its
//   wires, scroll to zoom. Delete removes the selection, Ctrl/Cmd+C / V / D copy, paste and
//   duplicate, F9 toggles a breakpoint, Space searches.
// - The sidebar: which body to edit (event graph or a function), the node search, the selected
//   node's settings and input values, the graph's variables and functions (with
//   collapse-to-function and comment boxes), its problems, and in play mode the variable values
//   of an entity running it.
// - While playing, nodes that ran in the last moments glow along their wires, output pins show
//   their values, and a breakpoint pauses play after the frame it ran in. Paused there, F10 / F11 /
//   Shift+F11 / F5 (or the sidebar's buttons) step over / into / out of the recorded flow, or continue.
//
// The file is the truth: every change is written as one undo step of the editor, the graph
// reimports and running games pick it up on their next frame. Edits from widget callbacks are
// applied in `update` so no widget is torn down while it handles an event.

@MainActor
public final class VisualScriptWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    public private(set) var asset: AssetID?
    public private(set) var graph = VisualScriptGraph()
    /// The function being edited (nil: the event graph).
    public private(set) var function: String?
    public private(set) var selection: Set<String> = []
    let canvas = VisualScriptCanvas()

    private let title = Label("Visual Script", role: .heading, name: "vscriptTitle")
    private let statusLabel = Label("", role: .caption, name: "vscriptStatus")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "vscriptSidebar")
    private let searchField = TextField(text: "", placeholder: "Search nodes to add (Space)", name: "vscriptSearch")
    private let searchHint = Label("", role: .caption, name: "vscriptSearchHint")
    private let results = VStack(spacing: 2, name: "vscriptResults")
    private let details = VStack(spacing: 6, name: "vscriptDetails")
    private let debugHost = VStack(spacing: 4, name: "vscriptDebug")
    private var shownRevision = -1
    private var sidebarDirty = true
    private var canvasDirty = true
    private var pending: (graph: VisualScriptGraph, label: String)?
    private var addPosition = Vec2(0, 0)
    private var addFrom: (pin: String, isOutput: Bool, type: VisualScriptType)?
    private var issues: [VisualScriptIssue] = []
    private var newVariable = ""
    private var newFunction = ""
    private var lastPlaying = false
    /// The trace step the debug section and canvas show (`session.visualScriptStep`), and of which trace.
    private var shownStep: (index: Int, hit: VisualScriptBreak)?
    private static var clipboard: (nodes: [VisualScriptNode], links: [VisualScriptLink])?

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "visualScriptWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.vscript` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isVisualScriptFile(id), let graph = session.assets?.visualScript(of: id) else { return false }
        if asset != id {
            asset = id
            function = nil
            selection = []
            canvas.pan = Vec2(40, 40)
            canvas.zoom = 1
        }
        self.graph = graph
        if let name = function, graph.function(name) == nil { function = nil }
        shownRevision = session.assets?.revision(of: id) ?? 0
        title.text = session.assets?.record(id)?.fileName ?? "Visual Script"
        sidebarDirty = true
        canvasDirty = true
        return true
    }

    public func close() {
        asset = nil
        pending = nil
        showEmpty()
    }

    /// Call every frame: applies the pending edit, follows file changes (undo, tools) and play mode.
    public func update() {
        guard let asset else { return }
        if let pending {
            self.pending = nil
            session.applyVisualScript(pending.graph, to: asset, label: pending.label)
        }
        let revision = session.assets?.revision(of: asset) ?? 0
        if revision != shownRevision {
            guard session.isVisualScriptFile(asset) else { close(); return }
            open(asset)
        }
        if canvasDirty { refreshCanvas() }
        if sidebarDirty { rebuildSidebar() }
        let playing = session.isPlaying
        if playing || lastPlaying != playing { refreshLive() }
        lastPlaying = playing
    }

    // MARK: Editing

    /// Nodes and links of the body being edited.
    var bodyNodes: [VisualScriptNode] { function.flatMap { graph.function($0)?.nodes } ?? graph.nodes }
    var bodyLinks: [VisualScriptLink] { function.flatMap { graph.function($0)?.links } ?? graph.links }
    var bodyFunction: VisualScriptFunction? { function.flatMap { graph.function($0) } }

    /// Applies `edit` (to the body being edited) as one undo step on the next update. Returns the added ids.
    @discardableResult
    func apply(_ edit: VisualScriptEdit, _ label: String) -> [String] {
        var edit = edit
        edit.function = function
        do {
            let result = try graph.applying(edit)
            commit(result.graph, label)
            return result.added
        } catch {
            session.log.error("\(label): \(error)")
            return []
        }
    }

    func commit(_ graph: VisualScriptGraph, _ label: String) {
        guard graph != self.graph else { return }
        self.graph = graph
        pending = (graph, label)
        sidebarDirty = true
        canvasDirty = true
    }

    /// Adds a node of `type` (with `config`) at the search position, wired to the pin a wire was dragged from.
    @discardableResult
    public func addNode(type: String, config: [String: JSONValue] = [:]) -> String? {
        let node = VisualScriptNode(id: "", type: type, x: addPosition.x, y: addPosition.y, config: config)
        var edit = VisualScriptEdit(addNodes: [node])
        var added = (try? graph.applying(VisualScriptEdit(function: function, addNodes: [node])).added) ?? []
        if let from = addFrom, let id = added.first, let definition = VisualScriptNodes.definition(type) {
            var placed = node
            placed.id = id
            let signature = definition.signature(for: placed, in: graph, function: bodyFunction)
            let candidates = from.isOutput ? signature.inputs : signature.outputs
            let match = candidates.first { from.isOutput ? from.type.converts(to: $0.type) : $0.type.converts(to: from.type) }
            if let match {
                edit.connect = [from.isOutput ? VisualScriptLink(from: from.pin, to: "\(id).\(match.name)")
                                              : VisualScriptLink(from: "\(id).\(match.name)", to: from.pin)]
            }
        }
        added = apply(edit, "Add Node")
        addFrom = nil
        selection = Set(added)
        addPosition += Vec2(30, 30)
        return added.first
    }

    func deleteSelection() {
        guard !selection.isEmpty else { return }
        apply(VisualScriptEdit(removeNodes: bodyNodes.filter { selection.contains($0.id) }.map(\.id)), "Delete Nodes")
        selection = []
    }

    func copySelection() {
        let nodes = bodyNodes.filter { selection.contains($0.id) }
        guard !nodes.isEmpty else { return }
        let links = bodyLinks.filter { selection.contains($0.source?.node ?? "") && selection.contains($0.target?.node ?? "") }
        Self.clipboard = (nodes, links)
    }

    func paste(offset: Vec2 = Vec2(40, 40)) {
        guard let clip = Self.clipboard else { return }
        var scratch = function.flatMap { graph.function($0) } ?? VisualScriptFunction(name: "", nodes: graph.nodes, links: graph.links)
        var renamed: [String: String] = [:]
        var nodes: [VisualScriptNode] = []
        for var node in clip.nodes {
            let id = scratch.uniqueNodeID(node.type)
            renamed[node.id] = id
            node.id = id
            node.x += offset.x
            node.y += offset.y
            scratch.nodes.append(node)
            nodes.append(node)
        }
        let links = clip.links.compactMap { link -> VisualScriptLink? in
            guard let a = link.source, let b = link.target, let na = renamed[a.node], let nb = renamed[b.node] else { return nil }
            return VisualScriptLink(from: "\(na).\(a.pin)", to: "\(nb).\(b.pin)")
        }
        apply(VisualScriptEdit(addNodes: nodes, connect: links), "Paste Nodes")
        selection = Set(nodes.map(\.id))
    }

    func toggleBreakpoint() {
        let nodes = bodyNodes.filter { selection.contains($0.id) }
        guard !nodes.isEmpty else { return }
        let on = !nodes.allSatisfy(\.breakpoint)
        apply(VisualScriptEdit(updateNodes: nodes.map { VisualScriptNodePatch(id: $0.id, breakpoint: on) }), on ? "Add Breakpoint" : "Remove Breakpoint")
    }

    /// Puts a reroute point on `link` at `position` (graph space): the wire then runs through it.
    @discardableResult
    func insertReroute(on link: VisualScriptLink, at position: Vec2) -> String? {
        let id = function.flatMap { graph.function($0)?.uniqueNodeID("reroute") } ?? graph.uniqueNodeID("reroute")
        let at = position - VisualScriptCanvas.rerouteSize / 2
        let added = apply(VisualScriptEdit(addNodes: [VisualScriptNode(id: id, type: VisualScriptReroute.type, x: at.x.rounded(), y: at.y.rounded())],
                                           disconnect: [link],
                                           connect: [VisualScriptLink(from: link.from, to: "\(id).in"), VisualScriptLink(from: "\(id).out", to: link.to)]),
                          "Add Reroute")
        return added.first
    }

    /// Moves the selected event graph nodes into a new function.
    public func collapseSelection(name: String? = nil) {
        guard function == nil else { session.log.error("Collapse to Function: only nodes of the event graph"); return }
        var n = 1
        while graph.function("function\(n)") != nil { n += 1 }
        let name = (name?.isEmpty == false ? name! : "function\(n)")
        do {
            commit(try graph.collapsingToFunction(selection, name: name), "Collapse to Function")
            selection = []
        } catch {
            session.log.error("Collapse to Function: \(error)")
        }
    }

    func handleKey(_ key: KeyEvent) -> Bool {
        let command = key.modifiers.contains(.command) || key.modifiers.contains(.control)
        switch key.key {
        case .delete, .backspace: deleteSelection()
        case .c where command: copySelection()
        case .v where command: paste()
        case .d where command: copySelection(); paste()
        case .f9: toggleBreakpoint()
        case .f10 where session.visualScriptStep != nil: session.stepVisualScript(.over)
        case .f11 where session.visualScriptStep != nil: session.stepVisualScript(key.modifiers.contains(.shift) ? .out : .into)
        case .f5 where session.visualScriptStep != nil: session.stepVisualScript(.continue)
        case .space:
            addFrom = nil
            addPosition = canvas.toGraph(Vec2(canvas.frame.x + canvas.frame.width / 2, canvas.frame.y + canvas.frame.height / 2))
            focusSearch()
        default: return false
        }
        return true
    }

    private func focusSearch() {
        searchHint.text = addFrom.map { "Wiring from \($0.pin) (\($0.type.rawValue)): pick a node" } ?? "Pick a node to add"
        refreshResults()
        view.context?.focus(searchField)
    }

    // MARK: Chrome

    private func layOutChrome() {
        title.style.shrink = 1
        title.icon = EditorIcons.asset(.text)
        statusLabel.style.grow = 1
        let attach = Button("Attach to Selection", name: "vscriptAttach") { [unowned self] in
            guard let asset, let id = session.selection.ids.first else {
                session.log.warning("Attach: select an entity first")
                return
            }
            session.attachVisualScript(asset, to: id)
        }
        attach.command = VScriptAttachCommand.id.rawValue
        attach.tooltip = "Put a VisualScript running this graph on the selected entity"
        let closeButton = Button("Close", name: "vscriptClose") { [unowned self] in close() }
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "vscriptToolbar",
                         [title, statusLabel, attach, closeButton])
        canvas.style.grow = 1
        canvas.style.shrink = 1
        canvas.onSelect = { [unowned self] ids in
            selection = ids
            sidebarDirty = true
        }
        canvas.onMove = { [unowned self] moves in
            apply(VisualScriptEdit(updateNodes: moves.sorted { $0.key < $1.key }.map { VisualScriptNodePatch(id: $0.key, x: $0.value.x.rounded(), y: $0.value.y.rounded()) }),
                  "Move Nodes")
        }
        canvas.onConnect = { [unowned self] from, to in apply(VisualScriptEdit(connect: [VisualScriptLink(from: from, to: to)]), "Connect") }
        canvas.onDisconnect = { [unowned self] pin, isInput in
            apply(VisualScriptEdit(disconnect: [isInput ? VisualScriptLink(from: "", to: pin) : VisualScriptLink(from: pin, to: "")]), "Disconnect")
        }
        canvas.onRequestAdd = { [unowned self] position, from in
            addPosition = position
            addFrom = from
            focusSearch()
        }
        canvas.onKey = { [unowned self] key in handleKey(key) }
        canvas.onInsertReroute = { [unowned self] link, position in insertReroute(on: link, at: position) }
        searchField.onChange = { [unowned self] _ in refreshResults() }
        searchField.onSubmit = { [unowned self] _ in
            if let first = catalog().first { addNode(type: first.type, config: first.config ?? [:]) }
        }
        let side = ScrollView(sidebar, name: "vscriptSidebarScroll")
        side.style.width = 320
        let body = HStack(spacing: 0, alignment: .stretch, name: "vscriptBody", [canvas, Separator(.vertical), side])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
        searchHint.wraps = true
        sidebar.addChildren([searchField, searchHint, results, Separator(), details, debugHost])
    }

    private func showEmpty() {
        title.text = "Visual Script"
        statusLabel.text = ""
        canvas.nodes = []
        canvas.links = []
        canvas.comments = []
        canvas.emptyText = "Open a .vscript file from the Assets panel (New Visual Script in its menu, or vscript.open)."
        results.removeAllChildren()
        details.removeAllChildren()
        debugHost.removeAllChildren()
    }

    // MARK: Canvas

    private func refreshCanvas() {
        canvasDirty = false
        canvas.emptyText = "Right-click (or Space) to add a node."
        issues = VisualScriptValidator.validate(graph)
        let errors = issues.filter { $0.severity == .error }.count, warnings = issues.filter { $0.severity == .warning }.count
        statusLabel.text = (function.map { "Function \($0) · " } ?? "Event graph · ") + "\(bodyNodes.count) nodes"
            + (errors + warnings == 0 ? "" : " · \(errors) errors, \(warnings) warnings")
        var byNode: [String: [VisualScriptIssue]] = [:]
        for issue in issues where issue.function == function { if let node = issue.node { byNode[node, default: []].append(issue) } }
        canvas.issues = byNode
        canvas.nodes = bodyNodes.map(canvasNode)
        canvas.links = bodyLinks
        canvas.comments = function == nil ? graph.comments : []
        canvas.selection = selection
        canvas.setNeedsDisplay()
    }

    private func canvasNode(_ node: VisualScriptNode) -> VisualScriptCanvasNode {
        let definition = VisualScriptNodes.definition(node.type)
        let signature = definition?.signature(for: node, in: graph, function: bodyFunction) ?? VisualScriptSignature()
        var literals: [String: String] = [:]
        for (name, value) in node.inputs { literals[name] = Self.text(of: value) }
        var title = definition?.title ?? node.type
        if let variable = node.configString("variable") { title += " " + variable }
        if let call = node.configString("function") { title = "Call " + call }
        if let component = node.configString("component") {
            title = (node.type == "component.set" ? "Set " : node.type == "component.get" ? "Get " : title + " ") + component
                + (node.configString("field").map { "." + $0 } ?? "")
        }
        for key in ["key", "action", "name"] { if let value = node.configString(key) { title += " " + value } }
        let reroute = node.type == VisualScriptReroute.type
        let size = reroute ? VisualScriptCanvas.rerouteSize
            : VisualScriptCanvas.size(title: title, inputs: signature.inputs, outputs: signature.outputs, literals: literals, collapsed: node.collapsed)
        return VisualScriptCanvasNode(id: node.id, title: title, kind: definition?.kind ?? .action, known: definition != nil,
                                      position: Vec2(node.x, node.y), size: size, inputs: signature.inputs, outputs: signature.outputs,
                                      literals: literals, breakpoint: node.breakpoint, collapsed: node.collapsed, comment: node.comment,
                                      doc: definition?.doc ?? "Unknown node type \(node.type)", isReroute: reroute)
    }

    static func text(of value: JSONValue) -> String {
        switch value {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return VisualScriptValue.float(d).asString
        case .bool(let b): return b ? "true" : "false"
        case .null: return ""
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }
    }

    /// Text typed into a value field as JSON: numbers, true / false, [1, 2, 3], {…}; anything else is text.
    static func json(from text: String) -> JSONValue? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let data = trimmed.data(using: .utf8), let value = try? JSONDecoder().decode(JSONValue.self, from: data) { return value }
        return .string(text)
    }

    /// Instances running this graph in play mode, the selected entity's first.
    private func liveInstances() -> [VisualScriptInstance] {
        guard let asset, let runtime = session.visualScriptRuntime, let assets = session.assets else { return [] }
        let selected = Set(session.selection.ids.compactMap { session.world.entity(for: $0) })
        return runtime.instances.values.filter { assets.visualScriptID(for: $0.key) == asset }
            .sorted { (selected.contains($0.entity) ? 0 : 1, $0.entity.index) < (selected.contains($1.entity) ? 0 : 1, $1.entity.index) }
    }

    private func refreshLive() {
        guard session.isPlaying, let runtime = session.visualScriptRuntime else {
            if !canvas.activity.isEmpty || !canvas.values.isEmpty || canvas.pausedAt != nil {
                canvas.activity = [:]
                canvas.values = [:]
                canvas.pausedAt = nil
                shownStep = nil
                debugHost.removeAllChildren()
            }
            return
        }
        if let index = session.visualScriptStep, let trace = runtime.trace, trace.steps.indices.contains(index) {
            showStep(index, of: trace)
            return
        }
        if shownStep != nil {
            shownStep = nil
            canvas.pausedAt = nil
            debugHost.removeAllChildren()
        }
        let instances = liveInstances()
        let now = session.world.time.elapsed
        var activity: [String: Double] = [:]
        if function == nil {
            for instance in instances {
                for (node, time) in runtime.activity[instance.key] ?? [:] { activity[node] = min(activity[node] ?? .infinity, now - time) }
            }
        }
        canvas.activity = activity
        var values: [String: String] = [:]
        if function == nil, let instance = instances.first {
            for node in bodyNodes {
                for (pin, value) in instance.outputs(of: node.id) { values["\(node.id).\(pin)"] = String(value.asString.prefix(24)) }
            }
        }
        canvas.values = values
        canvas.setNeedsDisplay()
        if session.playFrame % 15 == 0 || debugHost.children.isEmpty { rebuildDebug(instances) }
    }

    /// Whether a trace step is in this tab's graph.
    private func isMine(_ step: VisualScriptTraceStep) -> Bool {
        guard let asset, let assets = session.assets else { return false }
        return assets.visualScriptID(for: step.graph) == asset
    }

    /// Paused at a breakpoint: the current step's node outlined (its function opened), the values
    /// the flow had produced by then on the pins, and the step's details and controls in the sidebar.
    private func showStep(_ index: Int, of trace: VisualScriptTrace) {
        let step = trace.steps[index]
        let changed = shownStep?.index != index || shownStep?.hit != trace.hit
        if changed, isMine(step), step.function != function {
            function = step.function
            canvasDirty = true
            sidebarDirty = true
            refreshCanvas()
        }
        canvas.activity = [:]
        canvas.pausedAt = isMine(step) && step.function == function ? step.node : nil
        var values: [String: String] = [:]
        for earlier in trace.steps[...index] where earlier.graph == step.graph && earlier.entity == step.entity && earlier.function == function {
            for (pin, value) in earlier.outputs { values["\(earlier.node).\(pin)"] = String(value.asString.prefix(24)) }
        }
        canvas.values = isMine(step) ? values : [:]
        canvas.setNeedsDisplay()
        guard changed || debugHost.children.isEmpty else { return }
        shownStep = (index, trace.hit)
        debugHost.removeAllChildren()
        let place = (step.function.map { "function \($0), " } ?? "") + "node \(step.node)"
        let header = Label("Paused at \(place) (step \(index + 1) of \(trace.steps.count)\(trace.truncated ? "+" : ""))", role: .secondary, name: "vscriptStepAt")
        header.wraps = true
        debugHost.addChild(header)
        if !isMine(step) {
            let other = Label("In \(session.assets.flatMap { a in a.visualScriptID(for: step.graph).flatMap(a.path) } ?? step.graph)", role: .caption)
            other.wraps = true
            debugHost.addChild(other)
        }
        debugHost.addChild(Label("Entity: \(session.displayName(of: step.entity))", role: .caption))
        func button(_ title: String, _ action: VScriptStepAction, _ tip: String) -> Button {
            let b = Button(title, name: "vscriptStep.\(action.rawValue)") { [unowned self] in session.stepVisualScript(action) }
            b.command = VScriptStepCommand.id.rawValue
            b.tooltip = tip
            return b
        }
        let controls = HStack(spacing: 4, [button("Over", .over, "Step over (F10): the next node, skipping function calls"),
                                           button("Into", .into, "Step into (F11): the next node, entering function calls"),
                                           button("Out", .out, "Step out (Shift+F11): the next node in the caller"),
                                           button("Continue", .continue, "Resume play (F5)")])
        debugHost.addChild(controls)
        if let error = step.error {
            let label = Label("Error: \(error)", role: .caption)
            label.wraps = true
            debugHost.addChild(label)
        }
        for (title, values) in [("Inputs", step.inputs), ("Outputs", step.outputs), ("Variables", step.variables)] where !values.isEmpty {
            debugHost.addChild(Label(title, role: .secondary))
            for name in values.keys.sorted() {
                let line = Label("\(name) = \(values[name]!.asString)", role: .caption)
                line.wraps = true
                debugHost.addChild(line)
            }
        }
        let note = Label("Values as this node ran; the frame already finished, so the scene shows the end of it.", role: .caption)
        note.wraps = true
        debugHost.addChild(note)
    }

    private func rebuildDebug(_ instances: [VisualScriptInstance]) {
        debugHost.removeAllChildren()
        guard let instance = instances.first else {
            debugHost.addChild(Label("Playing: no entity runs this graph.", role: .caption))
            return
        }
        debugHost.addChild(Label("Live: \(session.displayName(of: instance.entity))\(instances.count > 1 ? " (+\(instances.count - 1) more)" : "")", role: .secondary))
        if instance.halted { debugHost.addChild(Label("Stopped on an error (see the console)", role: .caption)) }
        for name in instance.variables.keys.sorted() {
            debugHost.addChild(Label("\(name) = \(instance.variables[name]!.asString)", role: .caption))
        }
        if instance.pendingCount > 0 { debugHost.addChild(Label("\(instance.pendingCount) waiting (delays, tweens)", role: .caption)) }
        if let hit = session.visualScriptRuntime?.lastBreak { debugHost.addChild(Label("Last breakpoint: node \(hit.node)", role: .caption)) }
    }

    // MARK: Search

    private func catalog() -> [VisualScriptNodes.CatalogEntry] {
        let search = searchField.text.trimmingCharacters(in: .whitespaces)
        var entries = VisualScriptNodes.catalog(search: search, graph: graph, pinType: addFrom?.type == .any ? nil : addFrom?.type,
                                                includeComponentFields: !search.isEmpty, limit: 200)
        if function == nil { entries.removeAll { $0.type == "function.entry" || $0.type == "function.return" } } else { entries.removeAll { $0.kind == .event } }
        return entries
    }

    private func refreshResults() {
        results.removeAllChildren()
        guard asset != nil else { return }
        let entries = catalog()
        for entry in entries.prefix(30) {
            let button = Button(entry.title, name: "vscriptAdd.\(entry.type)") { [unowned self] in
                addNode(type: entry.type, config: entry.config ?? [:])
            }
            button.tooltip = "\(entry.type) (\(entry.category)): \(entry.doc)"
            results.addChild(button)
        }
        if entries.count > 30 { results.addChild(Label("\(entries.count - 30) more: refine the search", role: .caption)) }
    }

    // MARK: Sidebar

    private func rebuildSidebar() {
        sidebarDirty = false
        canvas.selection = selection
        details.removeAllChildren()
        refreshResults()
        guard asset != nil else { return }
        let bodies = ["Event Graph"] + graph.functions.map { "Function: \($0.name)" }
        let picker = Dropdown(options: bodies, selectedIndex: function.flatMap { name in graph.functions.firstIndex { $0.name == name }.map { $0 + 1 } } ?? 0,
                              name: "vscriptBody") { [unowned self] index in
            function = index == 0 ? nil : graph.functions[index - 1].name
            selection = []
            canvasDirty = true
            sidebarDirty = true
        }
        details.addChild(picker)
        let selected = bodyNodes.filter { selection.contains($0.id) }
        if selected.count == 1 { addNodeForm(selected[0]) } else if selected.count > 1 { addSelectionForm(selected) }
        addVariablesForm()
        addFunctionsForm()
        addProblems()
    }

    private func row(_ label: String, _ widget: Widget) -> HStack {
        let caption = Label(label, role: .secondary)
        caption.style.width = 90
        widget.style.grow = 1
        return HStack(spacing: 6, [caption, widget])
    }

    private func addNodeForm(_ node: VisualScriptNode) {
        let definition = VisualScriptNodes.definition(node.type)
        details.addChild(Label(definition?.title ?? node.type, role: .heading))
        let doc = Label("\(node.id) · \(node.type)" + (definition.map { "\n" + $0.doc } ?? "\nUnknown node type"), role: .caption)
        doc.wraps = true
        details.addChild(doc)
        for key in definition?.config ?? [] {
            let current = node.config[key.name].map(Self.text(of:)) ?? ""
            if let options = key.options, !options.isEmpty {
                let all = [""] + options
                let dropdown = Dropdown(options: all, selectedIndex: all.firstIndex(of: current) ?? 0, name: "vscriptConfig.\(key.name)") { [unowned self] i in
                    apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, config: [key.name: i == 0 ? .null : .string(all[i])])]), "Edit Node")
                }
                details.addChild(row(key.name, dropdown))
            } else {
                let field = TextField(text: current, placeholder: key.doc ?? key.type.rawValue, name: "vscriptConfig.\(key.name)")
                field.onSubmit = { [unowned self] text in
                    let value: JSONValue = key.type == .array ? .array(text.split(separator: ",").map { .string($0.trimmingCharacters(in: .whitespaces)) })
                        : (Self.json(from: text) ?? .null)
                    apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, config: [key.name: value])]), "Edit Node")
                }
                field.onEndEditing = field.onSubmit
                details.addChild(row(key.name, field))
            }
        }
        let signature = definition?.signature(for: node, in: graph, function: bodyFunction) ?? VisualScriptSignature()
        let wired = Set(bodyLinks.compactMap { $0.target?.node == node.id ? $0.target?.pin : nil })
        for pin in signature.inputs where pin.type != .exec && pin.type != .entity && !wired.contains(pin.name) {
            let field = TextField(text: node.inputs[pin.name].map(Self.text(of:)) ?? "",
                                  placeholder: pin.defaultValue?.asString ?? pin.type.rawValue, name: "vscriptInput.\(pin.name)")
            field.tooltip = "\(pin.type.rawValue) value used while nothing is wired in (numbers, true/false, [x, y, z], #RRGGBB, text)"
            field.onSubmit = { [unowned self] text in
                let value = pin.type == .string || pin.type == .asset ? (text.isEmpty ? JSONValue.null : .string(text)) : (Self.json(from: text) ?? .null)
                apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, inputs: [pin.name: value])]), "Edit Node")
            }
            field.onEndEditing = field.onSubmit
            details.addChild(row(pin.name, field))
        }
        let comment = TextField(text: node.comment ?? "", placeholder: "Note on the node", name: "vscriptNodeComment")
        comment.onSubmit = { [unowned self] text in apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, comment: text)]), "Edit Node") }
        comment.onEndEditing = comment.onSubmit
        details.addChild(row("note", comment))
        let breakpoint = Checkbox("Breakpoint (pause play after it runs)", isOn: node.breakpoint, name: "vscriptBreakpoint") { [unowned self] on in
            apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, breakpoint: on)]), on ? "Add Breakpoint" : "Remove Breakpoint")
        }
        let collapsed = Checkbox("Collapsed", isOn: node.collapsed, name: "vscriptCollapsed") { [unowned self] on in
            apply(VisualScriptEdit(updateNodes: [VisualScriptNodePatch(id: node.id, collapsed: on)]), "Collapse Node")
        }
        details.addChildren([breakpoint, collapsed])
        for issue in issues where issue.function == function && issue.node == node.id {
            let label = Label("\(issue.severity.rawValue): \(issue.pin.map { "\($0): " } ?? "")\(issue.message)", role: .caption)
            label.wraps = true
            details.addChild(label)
        }
        let delete = Button("Delete Node", name: "vscriptDeleteNode") { [unowned self] in deleteSelection() }
        details.addChild(HStack(spacing: 6, [delete, Spacer()]))
        details.addChild(Separator())
    }

    private func addSelectionForm(_ nodes: [VisualScriptNode]) {
        details.addChild(Label("\(nodes.count) nodes selected", role: .heading))
        let collapse = Button("Collapse to Function", name: "vscriptCollapse") { [unowned self] in collapseSelection() }
        collapse.tooltip = "Move these nodes into a new function and call it from here"
        let comment = Button("Comment Box", name: "vscriptCommentBox") { [unowned self] in
            let xs = nodes.map(\.x), ys = nodes.map(\.y)
            let box = VisualScriptComment(text: "Comment", x: (xs.min() ?? 0) - 30, y: (ys.min() ?? 0) - 50,
                                          width: (xs.max() ?? 0) - (xs.min() ?? 0) + 260, height: (ys.max() ?? 0) - (ys.min() ?? 0) + 200)
            apply(VisualScriptEdit(comments: [box]), "Add Comment")
        }
        let delete = Button("Delete", name: "vscriptDeleteNodes") { [unowned self] in deleteSelection() }
        details.addChild(HStack(spacing: 6, [collapse, comment, delete]))
        details.addChild(Separator())
    }

    private func addVariablesForm() {
        details.addChild(Label("Variables", role: .heading))
        for variable in graph.variables {
            let types = VisualScriptType.allCases.filter { $0 != .exec }.map(\.rawValue)
            let type = Dropdown(options: types, selectedIndex: types.firstIndex(of: variable.type.rawValue) ?? 0, name: "vscriptVarType.\(variable.name)") { [unowned self] i in
                var changed = variable
                changed.type = VisualScriptType(rawValue: types[i]) ?? .float
                changed.defaultValue = nil
                apply(VisualScriptEdit(variables: [changed]), "Edit Variable")
            }
            type.style.width = 80
            let value = TextField(text: variable.defaultValue.map(Self.text(of:)) ?? "", placeholder: "default", name: "vscriptVarDefault.\(variable.name)")
            value.style.grow = 1
            value.onSubmit = { [unowned self] text in
                var changed = variable
                changed.defaultValue = variable.type == .string || variable.type == .asset ? .string(text) : Self.json(from: text)
                apply(VisualScriptEdit(variables: [changed]), "Edit Variable")
            }
            value.onEndEditing = value.onSubmit
            let get = Button("Get", name: "vscriptVarGet.\(variable.name)") { [unowned self] in
                addNode(type: "var.get", config: ["variable": .string(variable.name)])
            }
            let set = Button("Set", name: "vscriptVarSet.\(variable.name)") { [unowned self] in
                addNode(type: "var.set", config: ["variable": .string(variable.name)])
            }
            let remove = Button("×", name: "vscriptVarRemove.\(variable.name)") { [unowned self] in
                apply(VisualScriptEdit(removeVariables: [variable.name]), "Remove Variable")
            }
            let name = Label(variable.name)
            name.style.width = 70
            details.addChild(HStack(spacing: 4, [name, type, value, get, set, remove]))
        }
        let field = TextField(text: newVariable, placeholder: "New variable name", name: "vscriptNewVariable")
        field.onChange = { [unowned self] text in newVariable = text }
        field.onSubmit = { [unowned self] text in addVariable(text) }
        let add = Button("Add", name: "vscriptAddVariable") { [unowned self] in addVariable(newVariable) }
        field.style.grow = 1
        details.addChild(HStack(spacing: 6, [field, add]))
    }

    private func addVariable(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, graph.variable(name) == nil else { return }
        newVariable = ""
        apply(VisualScriptEdit(variables: [VisualScriptVariable(name: name, type: .float, defaultValue: .int(0))]), "Add Variable")
    }

    private func addFunctionsForm() {
        details.addChild(Label("Functions", role: .heading))
        for function in graph.functions {
            let label = Label("\(function.name)(\(function.inputs.map(\.name).joined(separator: ", "))) → \(function.outputs.map(\.name).joined(separator: ", "))")
            label.style.grow = 1
            label.style.shrink = 1
            let edit = Button("Edit", name: "vscriptEditFunction.\(function.name)") { [unowned self] in
                self.function = function.name
                selection = []
                canvasDirty = true
                sidebarDirty = true
            }
            let call = Button("Call", name: "vscriptCallFunction.\(function.name)") { [unowned self] in
                let previous = self.function
                self.function = nil
                addNode(type: "function.call", config: ["function": .string(function.name)])
                self.function = previous
            }
            let remove = Button("×", name: "vscriptRemoveFunction.\(function.name)") { [unowned self] in
                if self.function == function.name { self.function = nil }
                apply(VisualScriptEdit(removeFunctions: [function.name]), "Remove Function")
            }
            details.addChild(HStack(spacing: 4, [label, edit, call, remove]))
        }
        let field = TextField(text: newFunction, placeholder: "New function name", name: "vscriptNewFunction")
        field.onChange = { [unowned self] text in newFunction = text }
        field.style.grow = 1
        let add = Button("Add", name: "vscriptAddFunction") { [unowned self] in
            let name = newFunction.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, graph.function(name) == nil else { return }
            newFunction = ""
            let function = VisualScriptFunction(name: name, nodes: [VisualScriptNode(id: "entry", type: "function.entry"),
                                                                    VisualScriptNode(id: "return", type: "function.return", x: 400)],
                                                 links: [VisualScriptLink(from: "entry.out", to: "return.in")])
            var edit = VisualScriptEdit(functions: [function])
            edit.function = nil
            if let result = try? graph.applying(edit) { commit(result.graph, "Add Function") }
        }
        details.addChild(HStack(spacing: 6, [field, add]))
        if let open = bodyFunction {
            addPinsForm(open, outputs: false)
            addPinsForm(open, outputs: true)
        } else {
            let note = Label("Edit a function to change its inputs and outputs.", role: .caption)
            note.wraps = true
            details.addChild(note)
        }
    }

    /// The inputs (or outputs) of the function being edited: rename, retype, reorder, remove, add.
    /// Wires on its entry, return and call nodes follow (`VisualScriptFunctionSignature`).
    private func addPinsForm(_ function: VisualScriptFunction, outputs: Bool) {
        let side = outputs ? "Outputs" : "Inputs"
        details.addChild(Label("\(function.name): \(side)", role: .secondary))
        let list = outputs ? function.outputs : function.inputs
        let tag = outputs ? "Output" : "Input"
        func commit(_ new: [VisualScriptParameter], renamed: [String: String] = [:], _ label: String) {
            var signature = VisualScriptFunctionSignature(function: function.name)
            if outputs {
                signature.outputs = new
                signature.renamedOutputs = renamed.isEmpty ? nil : renamed
            } else {
                signature.inputs = new
                signature.renamedInputs = renamed.isEmpty ? nil : renamed
            }
            apply(VisualScriptEdit(signatures: [signature]), label)
        }
        let types = VisualScriptType.allCases.filter { $0 != .exec }.map(\.rawValue)
        for (i, parameter) in list.enumerated() {
            let name = TextField(text: parameter.name, placeholder: "name", name: "vscriptFn\(tag)Name.\(parameter.name)")
            name.style.grow = 1
            name.style.width = 0
            name.command = VScriptEditCommand.id.rawValue
            name.onSubmit = { text in
                let new = text.trimmingCharacters(in: .whitespaces)
                guard !new.isEmpty, new != parameter.name else { return }
                var changed = list
                changed[i].name = new
                commit(changed, renamed: [parameter.name: new], "Rename Function \(tag)")
            }
            name.onEndEditing = name.onSubmit
            let type = Dropdown(options: types, selectedIndex: types.firstIndex(of: parameter.type.rawValue) ?? 0,
                                name: "vscriptFn\(tag)Type.\(parameter.name)") { i2 in
                var changed = list
                changed[i].type = VisualScriptType(rawValue: types[i2]) ?? .float
                commit(changed, "Change Function \(tag) Type")
            }
            type.style.width = 80
            type.command = VScriptEditCommand.id.rawValue
            let up = Button("↑", name: "vscriptFn\(tag)Up.\(parameter.name)") {
                guard i > 0 else { return }
                var changed = list
                changed.swapAt(i, i - 1)
                commit(changed, "Reorder Function \(tag)s")
            }
            up.isEnabled = i > 0
            up.tooltip = "Move up (the order of the call node's pins)"
            up.command = VScriptEditCommand.id.rawValue
            let remove = Button("×", name: "vscriptFn\(tag)Remove.\(parameter.name)") {
                var changed = list
                changed.remove(at: i)
                commit(changed, "Remove Function \(tag)")
            }
            remove.tooltip = "Remove (its wires go too)"
            remove.command = VScriptEditCommand.id.rawValue
            details.addChild(HStack(spacing: 4, alignment: .center, [name, type, up, remove]))
        }
        let field = TextField(text: "", placeholder: "New \(tag.lowercased()) name", name: "vscriptFnNew\(tag)")
        field.style.grow = 1
        field.command = VScriptEditCommand.id.rawValue
        let addPin = { (text: String) in
            let new = text.trimmingCharacters(in: .whitespaces)
            guard !new.isEmpty, !list.contains(where: { $0.name == new }) else { return }
            commit(list + [VisualScriptParameter(name: new, type: .float)], "Add Function \(tag)")
        }
        field.onSubmit = { text in addPin(text) }
        let add = Button("Add", name: "vscriptFnAdd\(tag)") { [weak field] in addPin(field?.text ?? "") }
        add.command = VScriptEditCommand.id.rawValue
        details.addChild(HStack(spacing: 6, [field, add]))
    }

    private func addProblems() {
        let shown = issues.filter { $0.severity != .info }
        details.addChild(Label(shown.isEmpty ? "No problems" : "Problems (\(shown.count))", role: .heading))
        for issue in shown.prefix(40) {
            let button = Button("\(issue.severity == .error ? "Error" : "Warning"): \(issue.description)", name: "vscriptIssue") { [unowned self] in
                function = issue.function
                if let node = issue.node { selection = [node] }
                canvasDirty = true
                sidebarDirty = true
            }
            details.addChild(button)
        }
    }
}
