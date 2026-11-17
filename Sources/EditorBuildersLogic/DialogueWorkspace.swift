import EditorCore
import Engine
import Foundation

// The Dialogue tab: one `.dialogue` file, tabbed with the Scene view.
//
// - The graph (DialogueGraphView) shows the nodes and links: click to select, drag to move,
//   drag from a node's dot onto another node to link them, drag empty space to pan.
// - Below it, a play-through preview: the game's default `DialogueBox` (or the dialogue's `.ui`
//   layout through a `DialogueLayoutPresenter`) driven by a `DialogueRunner`, with the variables
//   it tracks (editable) and the node it is at highlighted in the graph. It follows edits to the
//   file live.
// - The sidebar edits the selected node (type, speaker, text, key, links, options, condition,
//   changes, event), then the start node, speakers and variables, and lists the problems.
//
// The file is the truth: every change is one undo step (Ctrl+Z), the dialogue reimports
// (running games pick it up) and the tab is rebuilt. Edits made by widget callbacks are applied
// on the next `update` so no widget is torn down while it handles an event.

@MainActor
public final class DialogueWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    public private(set) var asset: AssetID?
    public private(set) var dialogue = DialogueAsset()
    public private(set) var selectedNode: String?
    public let graph = DialogueGraphView()
    /// The preview's player and its box.
    public private(set) var runner: DialogueRunner?
    public let previewBox = DialogueBox(name: "dialoguePreviewBox")
    /// The preview's `.ui` layout when the dialogue names one (`uiLayout`); nil shows `previewBox`.
    public private(set) var previewLayout: DialogueLayoutPresenter?
    /// Loads textures by path (speaker portraits, layout images); the editor sets it.
    public var images: ((String) -> GPUTexture?)? {
        didSet {
            previewBox.portraitTextures = images
            previewLayout?.view.images = images
        }
    }
    private var previewLayoutPath = ""
    private let previewHost = DialogueLayoutPreviewHost()

    private let title = Label("Dialogue", role: .heading, name: "dialogueTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "dialogueSidebar")
    private let variablesHost = VStack(spacing: 3, name: "dialoguePreviewVariables")
    private let previewStatus = Label("", role: .caption, name: "dialoguePreviewStatus")
    private var shownRevision = -1
    private var dirty = true
    private var variablesDirty = true
    private var pending: (dialogue: DialogueAsset, label: String, select: String??)?

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "dialogueWorkspace")
        previewBox.hidesWhenIdle = false
        previewBox.charactersPerSecond = 60
        previewBox.continueHint = "Click to continue"
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.dialogue` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isDialogueFile(id), let dialogue = session.assets?.dialogueContents(of: id) else { return false }
        let switched = asset != id
        asset = id
        self.dialogue = dialogue
        shownRevision = session.assets?.revision(of: id) ?? 0
        title.text = session.assets?.record(id)?.fileName ?? "Dialogue"
        if switched {
            selectedNode = dialogue.startNode
            graph.dialogue = dialogue
            graph.frameAll()
            resetPreview()
        }
        dirty = true
        return true
    }

    public func close() {
        asset = nil
        pending = nil
        runner = nil
        presentPreview(nil)
        showEmpty()
    }

    // MARK: Chrome

    private func layOutChrome() {
        title.style.shrink = 1
        title.icon = EditorIcons.asset(.model)
        var buttons: [Widget] = [title, Spacer()]
        for type in DialogueNodeType.allCases {
            let button = Button("+ \(type.rawValue.capitalized)", name: "dialogueAdd.\(type.rawValue)") { [unowned self] in addNode(type) }
            button.command = DialogueEditCommand.id.rawValue
            button.tooltip = "Add a \(type.rawValue) node, linked from the selected node when it has a free link"
            buttons.append(button)
        }
        let delete = Button("Delete", name: "dialogueDeleteNode") { [unowned self] in deleteSelected() }
        delete.command = DialogueEditCommand.id.rawValue
        delete.tooltip = "Delete the selected node (links to it are cleared)"
        let layout = Button("Arrange", name: "dialogueArrange") { [unowned self] in arrange() }
        layout.command = DialogueEditCommand.id.rawValue
        layout.tooltip = "Place every node again in columns by distance from the start"
        let keys = Button("Make Keys", name: "dialogueKeys") { [unowned self] in generateKeys() }
        keys.command = DialogueEditCommand.id.rawValue
        keys.tooltip = "Give every line and option without a localization key one (<file>.<node>)"
        let close = Button("Close", name: "dialogueClose") { [unowned self] in self.close() }
        buttons += [delete, layout, keys, close]
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "dialogueToolbar", buttons)

        graph.style.grow = 1
        graph.style.shrink = 1
        graph.onSelect = { [unowned self] id in
            selectedNode = id
            dirty = true
        }
        graph.onMove = { [unowned self] id, position in moveNode(id, to: position) }
        graph.onConnect = { [unowned self] from, to in connect(from, to) }

        let restart = Button("Play from Start", role: .primary, name: "dialoguePlay") { [unowned self] in playFrom(nil) }
        restart.command = DialoguePlayCommand.id.rawValue
        restart.tooltip = "Restart the preview at the start node (variables back to their defaults)"
        let fromSelected = Button("Play from Selected", name: "dialoguePlaySelected") { [unowned self] in playFrom(selectedNode) }
        fromSelected.tooltip = "Start the preview at the selected node, keeping the variables"
        let previewButtons = HStack(spacing: 6, [restart, fromSelected, previewStatus, Spacer()])
        previewHost.style.grow = 1
        previewHost.style.shrink = 1
        previewHost.addChild(previewBox)
        let variablesScroll = ScrollView(variablesHost, name: "dialoguePreviewVariablesScroll")
        variablesScroll.style.width = 240
        let previewRow = HStack(spacing: 10, alignment: .stretch, [previewHost, variablesScroll])
        previewRow.style.height = 230
        let preview = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "dialoguePreview",
                             [previewButtons, previewRow])

        let left = VStack(spacing: 0, alignment: .stretch, name: "dialogueMain", [graph, Separator(), preview])
        left.style.grow = 1
        left.style.shrink = 1
        let side = ScrollView(sidebar, name: "dialogueSidebarScroll")
        side.style.width = 330
        let body = HStack(spacing: 0, alignment: .stretch, name: "dialogueBody", [left, Separator(.vertical), side])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])

        previewBox.onAdvance = { [unowned self] in previewMoved() }
        previewBox.onChoose = { [unowned self] _ in previewMoved() }
    }

    private func showEmpty() {
        title.text = "Dialogue"
        sidebar.removeAllChildren()
        variablesHost.removeAllChildren()
        graph.dialogue = DialogueAsset()
        sidebar.addChild(note("Open a .dialogue file from the Assets panel (New Dialogue in its menu, or dialogue.open)."))
    }

    // MARK: Per frame

    /// Call every frame: applies the pending edit, follows the file (undo, MCP) and rebuilds what changed.
    public func update() {
        guard let asset, let assets = session.assets else { return }
        if let pending {
            self.pending = nil
            commit(pending.dialogue, label: pending.label, select: pending.select)
        }
        let revision = assets.revision(of: asset)
        if revision != shownRevision, let fresh = assets.dialogueContents(of: asset) {
            shownRevision = revision
            if fresh != dialogue { dialogue = fresh }
            dirty = true
        }
        if dirty {
            dirty = false
            rebuild()
        }
        if variablesDirty {
            variablesDirty = false
            rebuildVariables()
        }
    }

    public var hasPendingEdit: Bool { pending != nil }

    // MARK: Edits

    private func apply(_ edited: DialogueAsset, label: String, select: String?? = nil) {
        pending = (edited, label, select)
    }

    private func commit(_ edited: DialogueAsset, label: String, select: String??) {
        guard let asset, session.applyDialogue(edited, to: asset, label: label) != nil else { dirty = true; return }
        dialogue = session.assets?.dialogueContents(of: asset) ?? edited
        shownRevision = session.assets?.revision(of: asset) ?? shownRevision
        if let select { selectedNode = select }
        if let selectedNode, dialogue.node(selectedNode) == nil { self.selectedNode = nil }
        dirty = true
    }

    private func edit(_ label: String, select: String?? = nil, _ change: (inout DialogueAsset) throws -> Void) {
        var edited = dialogue
        do { try change(&edited) } catch {
            session.log.warning("Dialogue: \(error)")
            dirty = true
            return
        }
        edited.placeUnpositionedNodes()
        guard edited != dialogue else { return }
        apply(edited, label: label, select: select)
    }

    private func updateNode(_ id: String, label: String, _ change: @escaping (inout DialogueNode) -> Void) {
        edit(label) { d in
            guard let i = d.nodeIndex(id) else { return }
            change(&d.nodes[i])
        }
    }

    /// Adds a node of `type` right of the selected node, linked from it when it has a free link.
    public func addNode(_ type: DialogueNodeType) {
        var node = DialogueNode(type: type)
        switch type {
        case .line:
            node.text = "…"
            node.speaker = dialogue.speakers.first?.id ?? ""
        case .choice: node.choices = [DialogueChoice(text: "Option", next: "")]
        case .condition: node.condition = dialogue.variables.first.map { $0.type == .bool ? $0.name : "\($0.name) > 0" } ?? "true"
        case .set:
            if let v = dialogue.variables.first {
                node.changes = [DialogueChange(variable: v.name, op: v.type == .bool ? .toggle : .set,
                                               value: v.type == .bool ? nil : v.initialValue.json)]
            }
        case .event: node.event = "event"
        case .end: break
        }
        var id = ""
        edit("Add \(type.rawValue.capitalized) Node", select: .some(nil)) { d in
            node.id = d.uniqueNodeID(type.rawValue)
            id = node.id
            if let selected = selectedNode, let parent = d.node(selected), let p = parent.position {
                node.position = Vec2(p.x + DialogueAsset.layoutSpacing.x, p.y)
                while d.nodes.contains(where: { $0.position == node.position }) { node.position!.y += DialogueAsset.layoutSpacing.y }
            }
            d.nodes.append(node)
            if let selected = selectedNode, let i = d.nodeIndex(selected) {
                switch d.nodes[i].type {
                case .choice:
                    if let k = d.nodes[i].choices.firstIndex(where: { $0.next.isEmpty }) { d.nodes[i].choices[k].next = id }
                case .end: break
                default: if d.nodes[i].next.isEmpty { d.nodes[i].next = id }
                }
            }
            if d.nodes.count == 1 { d.start = id }
        }
        if let pending { self.pending = (pending.dialogue, pending.label, .some(id)) }
    }

    public func deleteSelected() {
        guard let id = selectedNode else { return }
        edit("Delete Node", select: .some(nil)) { d in d = try d.applying(DialogueEdit(removeNodes: [id])) }
    }

    func moveNode(_ id: String, to position: Vec2) {
        updateNode(id, label: "Move Node") { $0.position = position }
    }

    /// Links `from` to `to`: a choice gets a new option, a condition fills `next` then `else`, others set `next`.
    public func connect(_ from: String, _ to: String) {
        edit("Link Nodes") { d in
            guard let node = d.node(from) else { return }
            switch node.type {
            case .choice:
                if let k = node.choices.firstIndex(where: { $0.next.isEmpty }) {
                    try d.connect(DialogueConnection(from: from, to: to, choice: k))
                } else {
                    try d.connect(DialogueConnection(from: from, to: to, text: "Option"))
                }
            case .condition where !node.next.isEmpty && node.elseNext.isEmpty:
                try d.connect(DialogueConnection(from: from, to: to, branch: "else"))
            default:
                try d.connect(DialogueConnection(from: from, to: to))
            }
        }
    }

    func arrange() {
        edit("Arrange Nodes") { d in d = try d.applying(DialogueEdit(layout: true)) }
        graph.pan = Vec2(-40, -40)
    }

    func generateKeys() {
        guard let asset else { return }
        let stem = ((session.assets?.path(of: asset) ?? "dialogue") as NSString).lastPathComponent
        let prefix = (stem as NSString).deletingPathExtension
        edit("Make Localization Keys") { d in d.generateKeys(prefix: prefix) }
    }

    // MARK: Preview

    private func resetPreview() {
        let runner = DialogueRunner(dialogue)
        runner.onVariableChange { [unowned self] _, _ in variablesDirty = true }
        runner.onStateChange { [unowned self] _ in previewMoved() }
        self.runner = runner
        presentPreview(nil)
        showPreview(.idle)
        variablesDirty = true
        previewStatus.text = "Not started"
        graph.current = nil
    }

    /// Restarts the preview at `node` (nil: the start, with fresh variables).
    public func playFrom(_ node: String?) {
        if node == nil || runner == nil { resetPreview() }
        guard let runner else { return }
        runner.start(at: node)
        presentPreview(runner)
        previewMoved()
    }

    private func previewMoved() {
        guard let runner else { return }
        if runner.isActive { presentPreview(runner) } else { showPreview(runner.state == .idle ? .idle : .finished) }
        graph.current = runner.currentNode
        switch runner.state {
        case .idle: previewStatus.text = "Not started"
        case .line(let line): previewStatus.text = "At \(line.node)"
        case .choices(let choices): previewStatus.text = "At \(choices.node): pick an option"
        case .finished: previewStatus.text = "Finished"
        }
        if case .warning(let message)? = runner.history.last { previewStatus.text = (previewStatus.text) + " (\(message))" }
        variablesDirty = true
    }

    private func presentPreview(_ runner: DialogueRunner?) {
        if let previewLayout { previewLayout.present(runner) } else { previewBox.present(runner) }
    }

    private func showPreview(_ state: DialogueRunner.State) {
        if let previewLayout { previewLayout.show(state) } else { previewBox.show(state) }
    }

    /// Shows the preview in the dialogue's `.ui` layout, or the default box when it names none
    /// (or one that can't be loaded).
    private func syncPreviewLayout() {
        let path = dialogue.uiLayout
        guard path != previewLayoutPath else { return }
        previewLayoutPath = path
        previewLayout?.removeFromParent()
        previewLayout = nil
        if !path.isEmpty, let assets = session.assets,
           let presenter = DialogueLayoutPresenter(assets: assets, path: path, name: "dialoguePreviewLayout") {
            presenter.hidesWhenIdle = false
            // Placed by the host (scaled); absolute so its larger virtual frame doesn't count as
            // the tab's content running past the bottom.
            presenter.style.position = .absolute(UIAnchor.topLeft.anchors())
            presenter.charactersPerSecond = 60
            presenter.view.images = images
            presenter.onAdvance = { [unowned self] in previewMoved() }
            presenter.onChoose = { [unowned self] _ in previewMoved() }
            previewHost.addChild(presenter)
            previewLayout = presenter
        }
        previewHost.layoutPresenter = previewLayout
        previewBox.present(nil)
        previewBox.show(.idle)
        previewBox.isHidden = previewLayout != nil
        guard let runner else { return }
        if runner.isActive { presentPreview(runner) } else { showPreview(runner.state == .idle ? .idle : .finished) }
    }

    private func rebuildVariables() {
        variablesHost.removeAllChildren()
        variablesHost.addChild(Label("Variables", role: .secondary))
        guard let runner else { return }
        let names = runner.variables.keys.sorted()
        if names.isEmpty { variablesHost.addChild(note("None declared.")) }
        for name in names {
            let value = runner.variables[name] ?? .bool(false)
            let caption = Label(name, role: .caption)
            caption.style.width = 90
            let field = TextField(text: value.description, name: "dialoguePreviewVar.\(name)")
            field.style.grow = 1
            field.tooltip = "Set \(name) for the preview (\(value.type.rawValue))"
            let set: (String) -> Void = { [unowned self] text in
                let parsed: DialogueValue = Double(text).map(DialogueValue.number) ?? (text == "true" ? .bool(true) : text == "false" ? .bool(false) : .text(text))
                self.runner?.setVariable(name, parsed)
                variablesDirty = true
            }
            field.onSubmit = set
            field.onEndEditing = set
            variablesHost.addChild(HStack(spacing: 6, [caption, field]))
        }
    }

    // MARK: Layout

    private func rebuild() {
        graph.dialogue = dialogue
        graph.selected = selectedNode
        runner?.replace(dialogue)
        syncPreviewLayout()
        sidebar.removeAllChildren()
        let issues = session.assets?.dialogueIssues(dialogue) ?? dialogue.validate()
        if let id = selectedNode, let node = dialogue.node(id) {
            addNodeForm(node)
        } else {
            sidebar.addChild(note("Select a node in the graph to edit it, or add one with the toolbar."))
        }
        sidebar.addChild(Separator())
        addDialogueSection()
        sidebar.addChild(Separator())
        addSpeakersSection()
        sidebar.addChild(Separator())
        addVariablesSection()
        sidebar.addChild(Separator())
        sidebar.addChild(Label(issues.isEmpty ? "No problems" : "Problems (\(issues.count))", role: .secondary))
        for issue in issues.prefix(30) { sidebar.addChild(note(issue.description)) }
        if issues.count > 30 { sidebar.addChild(note("…and \(issues.count - 30) more (dialogue.get lists all)")) }
    }

    private func row(_ label: String, _ widget: Widget) {
        let caption = Label(label, role: .caption)
        caption.style.width = 70
        widget.style.grow = 1
        sidebar.addChild(HStack(spacing: 6, [caption, widget]))
    }

    private func field(_ label: String, _ text: String, placeholder: String = "", name: String, _ set: @escaping (String) -> Void) {
        let editor = TextField(text: text, placeholder: placeholder, name: "dialogueField.\(name)")
        let commitText: (String) -> Void = { value in if value != text { set(value) } }
        editor.onEndEditing = commitText
        editor.onSubmit = commitText
        row(label, editor)
    }

    /// A dropdown of node ids plus "(end)" for a link.
    private func linkPicker(_ current: String, name: String, _ set: @escaping (String) -> Void) -> Dropdown {
        var options = ["(end)"] + dialogue.nodes.map(\.id)
        var selected = current.isEmpty ? 0 : (dialogue.nodes.firstIndex { $0.id == current }.map { $0 + 1 } ?? -1)
        if selected < 0 { options.append("\(current) (missing)"); selected = options.count - 1 }
        let ids = dialogue.nodes.map(\.id)
        let dropdown = Dropdown(options: options, selectedIndex: selected, name: "dialogueLink.\(name)")
        dropdown.onChange = { k in
            guard k <= ids.count else { return }
            set(k == 0 ? "" : ids[k - 1])
        }
        return dropdown
    }

    private func speakerPicker(_ current: String, _ set: @escaping (String) -> Void) -> Dropdown {
        var options = ["(none)"] + dialogue.speakers.map { "\($0.displayName) (\($0.id))" }
        var selected = current.isEmpty ? 0 : (dialogue.speakers.firstIndex { $0.id == current }.map { $0 + 1 } ?? -1)
        if selected < 0 { options.append("\(current) (missing)"); selected = options.count - 1 }
        let ids = dialogue.speakers.map(\.id)
        let dropdown = Dropdown(options: options, selectedIndex: selected, name: "dialogueSpeakerPicker")
        dropdown.onChange = { k in
            guard k <= ids.count else { return }
            set(k == 0 ? "" : ids[k - 1])
        }
        return dropdown
    }

    private func addNodeForm(_ node: DialogueNode) {
        let id = node.id
        sidebar.addChild(Label("Node \(id)", role: .secondary))
        field("Id", id, name: "id") { [unowned self] text in
            let new = text.trimmingCharacters(in: .whitespaces)
            edit("Rename Node", select: .some(new)) { d in d = try d.applying(DialogueEdit(updateNodes: [id: .object(["id": .string(new)])])) }
        }
        let type = Dropdown(options: DialogueNodeType.allCases.map(\.rawValue),
                            selectedIndex: DialogueNodeType.allCases.firstIndex(of: node.type) ?? 0, name: "dialogueField.type")
        type.onChange = { [unowned self] k in updateNode(id, label: "Change Node Type") { $0.type = DialogueNodeType.allCases[k] } }
        row("Type", type)
        switch node.type {
        case .line, .choice:
            row("Speaker", speakerPicker(node.speaker) { [unowned self] s in updateNode(id, label: "Set Speaker") { $0.speaker = s } })
            field(node.type == .line ? "Text" : "Prompt", node.text, placeholder: node.type == .line ? "What is said ({variable} fills in)" : "(optional)",
                  name: "text") { [unowned self] t in updateNode(id, label: "Edit Text") { $0.text = t } }
            field("Key", node.key, placeholder: "localization key", name: "key") { [unowned self] t in
                updateNode(id, label: "Set Key") { $0.key = t.trimmingCharacters(in: .whitespaces) }
            }
        default: break
        }
        switch node.type {
        case .choice:
            sidebar.addChild(Label("Options", role: .caption))
            for (k, choice) in node.choices.enumerated() {
                let text = TextField(text: choice.text, placeholder: "Option text", name: "dialogueChoice.\(k).text")
                text.style.grow = 1
                let setText: (String) -> Void = { [unowned self] t in
                    if t != choice.text { updateNode(id, label: "Edit Option") { if $0.choices.indices.contains(k) { $0.choices[k].text = t } } }
                }
                text.onEndEditing = setText
                text.onSubmit = setText
                let remove = Button("×", name: "dialogueChoice.\(k).remove") { [unowned self] in
                    updateNode(id, label: "Remove Option") { if $0.choices.indices.contains(k) { $0.choices.remove(at: k) } }
                }
                remove.tooltip = "Remove this option"
                sidebar.addChild(HStack(spacing: 4, [Label("\(k + 1).", role: .caption), text, remove]))
                let next = linkPicker(choice.next, name: "choice\(k)") { [unowned self] target in
                    updateNode(id, label: "Link Option") { if $0.choices.indices.contains(k) { $0.choices[k].next = target } }
                }
                let condition = TextField(text: choice.condition, placeholder: "if… (always)", name: "dialogueChoice.\(k).condition")
                condition.style.grow = 1
                let setCondition: (String) -> Void = { [unowned self] t in
                    if t != choice.condition { updateNode(id, label: "Set Option Condition") { if $0.choices.indices.contains(k) { $0.choices[k].condition = t } } }
                }
                condition.onEndEditing = setCondition
                condition.onSubmit = setCondition
                let key = TextField(text: choice.key, placeholder: "key", name: "dialogueChoice.\(k).key")
                key.style.width = 80
                let setKey: (String) -> Void = { [unowned self] t in
                    if t != choice.key { updateNode(id, label: "Set Option Key") { if $0.choices.indices.contains(k) { $0.choices[k].key = t } } }
                }
                key.onEndEditing = setKey
                key.onSubmit = setKey
                sidebar.addChild(HStack(spacing: 4, [Label("→", role: .caption), next, condition, key]))
            }
            let add = Button("Add Option", name: "dialogueAddChoice") { [unowned self] in
                updateNode(id, label: "Add Option") { $0.choices.append(DialogueChoice(text: "Option")) }
            }
            sidebar.addChild(HStack(spacing: 6, [add, Spacer()]))
            row("Fallback", linkPicker(node.next, name: "next") { [unowned self] t in updateNode(id, label: "Link Node") { $0.next = t } })
        case .line:
            row("Next", linkPicker(node.next, name: "next") { [unowned self] t in updateNode(id, label: "Link Node") { $0.next = t } })
        case .condition:
            field("If", node.condition, placeholder: "gold >= 10 && !paid", name: "condition") { [unowned self] t in
                updateNode(id, label: "Set Condition") { $0.condition = t }
            }
            row("Then", linkPicker(node.next, name: "next") { [unowned self] t in updateNode(id, label: "Link Node") { $0.next = t } })
            row("Else", linkPicker(node.elseNext, name: "else") { [unowned self] t in updateNode(id, label: "Link Node") { $0.elseNext = t } })
        case .set:
            sidebar.addChild(Label("Changes", role: .caption))
            let names = dialogue.variables.map(\.name)
            for (k, change) in node.changes.enumerated() {
                var options = names
                var selected = names.firstIndex(of: change.variable) ?? -1
                if selected < 0 { options.append(change.variable.isEmpty ? "(none)" : change.variable); selected = options.count - 1 }
                let variable = Dropdown(options: options, selectedIndex: selected, name: "dialogueChange.\(k).variable")
                variable.onChange = { [unowned self] i in
                    guard i < names.count else { return }
                    updateNode(id, label: "Set Change Variable") { if $0.changes.indices.contains(k) { $0.changes[k].variable = names[i] } }
                }
                let ops = DialogueChange.Operation.allCases
                let op = Dropdown(options: ops.map(\.rawValue), selectedIndex: ops.firstIndex(of: change.op) ?? 0, name: "dialogueChange.\(k).op")
                op.onChange = { [unowned self] i in
                    updateNode(id, label: "Set Change Operation") { if $0.changes.indices.contains(k) { $0.changes[k].op = ops[i] } }
                }
                let shown = change.expression.isEmpty ? (change.value.flatMap(DialogueValue.init(json:))?.description ?? "") : "=" + change.expression
                let value = TextField(text: shown, placeholder: "value or =expression", name: "dialogueChange.\(k).value")
                value.style.grow = 1
                value.tooltip = "A value (10, true, text), or = and an expression (=gold * 2)"
                let type = dialogue.variable(change.variable)?.type
                let setValue: (String) -> Void = { [unowned self] t in
                    guard t != shown else { return }
                    updateNode(id, label: "Set Change Value") { node in
                        guard node.changes.indices.contains(k) else { return }
                        if t.hasPrefix("=") {
                            node.changes[k].expression = String(t.dropFirst()).trimmingCharacters(in: .whitespaces)
                            node.changes[k].value = nil
                        } else {
                            node.changes[k].expression = ""
                            let raw = DialogueValue.text(t)
                            node.changes[k].value = (type.flatMap { raw.converted(to: $0) } ?? raw).json
                        }
                    }
                }
                value.onEndEditing = setValue
                value.onSubmit = setValue
                let remove = Button("×", name: "dialogueChange.\(k).remove") { [unowned self] in
                    updateNode(id, label: "Remove Change") { if $0.changes.indices.contains(k) { $0.changes.remove(at: k) } }
                }
                sidebar.addChild(HStack(spacing: 4, [variable, op, value, remove]))
            }
            let add = Button("Add Change", name: "dialogueAddChange") { [unowned self] in
                updateNode(id, label: "Add Change") { $0.changes.append(DialogueChange(variable: names.first ?? "")) }
            }
            sidebar.addChild(HStack(spacing: 6, [add, Spacer()]))
            row("Next", linkPicker(node.next, name: "next") { [unowned self] t in updateNode(id, label: "Link Node") { $0.next = t } })
        case .event:
            field("Event", node.event, placeholder: "openGate", name: "event") { [unowned self] t in
                updateNode(id, label: "Set Event") { $0.event = t.trimmingCharacters(in: .whitespaces) }
            }
            let argsText = node.args.isEmpty ? "" : ((try? String(decoding: JSONEncoder.sorted.encode(node.args), as: UTF8.self)) ?? "")
            field("Args", argsText, placeholder: "{\"amount\": 10}", name: "args") { [unowned self] t in
                let trimmed = t.trimmingCharacters(in: .whitespaces)
                guard trimmed.isEmpty || (try? JSONDecoder().decode([String: JSONValue].self, from: Data(trimmed.utf8))) != nil else {
                    session.log.warning("Dialogue: event args must be a JSON object")
                    dirty = true
                    return
                }
                let args = trimmed.isEmpty ? [:] : ((try? JSONDecoder().decode([String: JSONValue].self, from: Data(trimmed.utf8))) ?? [:])
                updateNode(id, label: "Set Event Args") { $0.args = args }
            }
            row("Next", linkPicker(node.next, name: "next") { [unowned self] t in updateNode(id, label: "Link Node") { $0.next = t } })
        case .end:
            sidebar.addChild(note("Ends the conversation."))
        }
        field("Comment", node.comment, placeholder: "note for writers", name: "comment") { [unowned self] t in
            updateNode(id, label: "Set Comment") { $0.comment = t }
        }
        let start = Button(node.id == dialogue.startNode ? "Start Node ✓" : "Make Start Node", name: "dialogueMakeStart") { [unowned self] in
            edit("Set Start Node") { $0.start = id }
        }
        start.isEnabled = node.id != dialogue.startNode
        let play = Button("Play from Here", name: "dialoguePlayHere") { [unowned self] in playFrom(id) }
        sidebar.addChild(HStack(spacing: 6, [start, play, Spacer()]))
    }

    private func addDialogueSection() {
        sidebar.addChild(Label("Dialogue", role: .secondary))
        row("Start", linkPicker(dialogue.start, name: "start") { [unowned self] t in edit("Set Start Node") { $0.start = t } })
        row("Shown in", layoutPicker())
        let newLayout = Button("New Dialogue Layout", name: "dialogueNewLayout") { [unowned self] in makeLayout() }
        newLayout.tooltip = "Make a .ui file from the dialogue preset next to this file and show the dialogue in it"
        sidebar.addChild(HStack(spacing: 6, [newLayout, Spacer()]))
        sidebar.addChild(note("Game code: a DialoguePlayer component plays this file; world.dialogues?.start(entity), world.dialogue(for:)?.setVariable(_:_:), world.dialogues?.onEvent { … }."))
    }

    /// "Default box" or a project `.ui` file, for the dialogue's `uiLayout`.
    private func layoutPicker() -> Dropdown {
        let paths = (session.assets?.allRecords ?? []).filter { session.isUIBuildFile($0.id) }.map(\.path)
        var options = ["Default box"] + paths
        let current = dialogue.uiLayout
        var selected = current.isEmpty ? 0 : (session.assets?.assetID(forTableValue: current)
            .flatMap { id in paths.firstIndex { session.assets?.id(forPath: $0) == id } }.map { $0 + 1 } ?? -1)
        if selected < 0 { options.append("\(current) (missing)"); selected = options.count - 1 }
        let dropdown = Dropdown(options: options, selectedIndex: selected, name: "dialogueLayoutPicker")
        dropdown.tooltip = "What shows this dialogue: the game's default box or a .ui layout using the dialogue keys (a DialoguePlayer's uiLayout wins)"
        dropdown.onChange = { [unowned self] i in
            guard i <= paths.count else { return }
            let path = i == 0 ? "" : paths[i - 1]
            edit("Set Dialogue Layout") { $0.uiLayout = path }
        }
        return dropdown
    }

    /// Writes a `.ui` file from the "dialogue" preset beside this file and uses it.
    func makeLayout() {
        guard let asset, let path = session.assets?.path(of: asset) else { return }
        let folder = (path as NSString).deletingLastPathComponent
        let stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        guard let id = session.createUIBuildAsset(in: folder, name: stem + " Box", build: .dialogue),
              let layoutPath = session.assets?.path(of: id) else { return }
        edit("Set Dialogue Layout") { $0.uiLayout = layoutPath }
    }

    private func addSpeakersSection() {
        sidebar.addChild(Label("Speakers", role: .secondary))
        for (k, speaker) in dialogue.speakers.enumerated() {
            func text(_ value: String, _ placeholder: String, _ name: String, width: Float? = nil, _ set: @escaping (inout DialogueSpeaker, String) -> Void) -> TextField {
                let f = TextField(text: value, placeholder: placeholder, name: "dialogueSpeaker.\(k).\(name)")
                if let width { f.style.width = width } else { f.style.grow = 1 }
                let commitText: (String) -> Void = { [unowned self] t in
                    guard t != value else { return }
                    edit("Edit Speaker") { d in
                        guard d.speakers.indices.contains(k) else { return }
                        let old = d.speakers[k].id
                        set(&d.speakers[k], t.trimmingCharacters(in: .whitespaces))
                        let new = d.speakers[k].id
                        if old != new { for i in d.nodes.indices where d.nodes[i].speaker == old { d.nodes[i].speaker = new } }
                    }
                }
                f.onEndEditing = commitText
                f.onSubmit = commitText
                return f
            }
            let remove = Button("×", name: "dialogueSpeaker.\(k).remove") { [unowned self] in
                edit("Remove Speaker") { d in if d.speakers.indices.contains(k) { d.speakers.remove(at: k) } }
            }
            sidebar.addChild(HStack(spacing: 4, [text(speaker.id, "id", "id", width: 70) { $0.id = $1 },
                                                 text(speaker.name, "Name", "name") { $0.name = $1 },
                                                 text(speaker.color, "#RRGGBB", "color", width: 70) { $0.color = $1 }, remove]))
            sidebar.addChild(HStack(spacing: 4, [Label("portrait", role: .caption),
                                                 text(speaker.portrait, "Art/face.png", "portrait") { $0.portrait = $1 }]))
        }
        let add = Button("Add Speaker", name: "dialogueAddSpeaker") { [unowned self] in
            edit("Add Speaker") { d in
                var n = d.speakers.count + 1
                while d.speaker("speaker\(n)") != nil { n += 1 }
                d.speakers.append(DialogueSpeaker(id: "speaker\(n)", name: "Speaker \(n)"))
            }
        }
        sidebar.addChild(HStack(spacing: 6, [add, Spacer()]))
    }

    private func addVariablesSection() {
        sidebar.addChild(Label("Variables", role: .secondary))
        let types = DialogueVariableType.allCases
        for (k, variable) in dialogue.variables.enumerated() {
            let name = TextField(text: variable.name, placeholder: "name", name: "dialogueVariable.\(k).name")
            name.style.grow = 1
            let setName: (String) -> Void = { [unowned self] t in
                let t = t.trimmingCharacters(in: .whitespaces)
                guard t != variable.name else { return }
                edit("Rename Variable") { d in if d.variables.indices.contains(k) { d.variables[k].name = t } }
            }
            name.onEndEditing = setName
            name.onSubmit = setName
            let type = Dropdown(options: types.map(\.rawValue), selectedIndex: types.firstIndex(of: variable.type) ?? 0,
                                name: "dialogueVariable.\(k).type")
            type.onChange = { [unowned self] i in
                edit("Change Variable Type") { d in
                    guard d.variables.indices.contains(k) else { return }
                    d.variables[k].type = types[i]
                    d.variables[k].defaultValue = d.variables[k].defaultValue.flatMap(DialogueValue.init(json:))?.converted(to: types[i])?.json
                }
            }
            let shown = variable.defaultValue.flatMap(DialogueValue.init(json:))?.description ?? ""
            let value = TextField(text: shown, placeholder: DialogueValue.zero(variable.type).description, name: "dialogueVariable.\(k).default")
            value.style.width = 70
            let setValue: (String) -> Void = { [unowned self] t in
                guard t != shown else { return }
                edit("Set Variable Default") { d in
                    guard d.variables.indices.contains(k) else { return }
                    d.variables[k].defaultValue = t.isEmpty ? nil : (DialogueValue.text(t).converted(to: d.variables[k].type) ?? .text(t)).json
                }
            }
            value.onEndEditing = setValue
            value.onSubmit = setValue
            let remove = Button("×", name: "dialogueVariable.\(k).remove") { [unowned self] in
                edit("Remove Variable") { d in if d.variables.indices.contains(k) { d.variables.remove(at: k) } }
            }
            sidebar.addChild(HStack(spacing: 4, [name, type, value, remove]))
        }
        let add = Button("Add Variable", name: "dialogueAddVariable") { [unowned self] in
            edit("Add Variable") { d in
                var n = d.variables.count + 1
                while d.variable("var\(n)") != nil { n += 1 }
                d.variables.append(DialogueVariable(name: "var\(n)", type: .number))
            }
        }
        sidebar.addChild(HStack(spacing: 6, [add, Spacer()]))
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "dialogueNote")
        label.wraps = true
        return label
    }
}

private extension JSONEncoder {
    static var sorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}

/// Holds the preview: the default box, or a `.ui` layout drawn at least `virtualWidth` points
/// wide and scaled down to fit (layouts are made for a game screen, the preview is small).
/// Clicks are mapped into the scaled layout here: a button presses it, anything else continues.
@MainActor
final class DialogueLayoutPreviewHost: Widget {
    /// The layout shown scaled (nil: the box fills the host).
    weak var layoutPresenter: DialogueLayoutPresenter? { didSet { setNeedsLayout() } }
    /// The narrowest screen a layout is laid out on.
    var virtualWidth: Float = 720 { didSet { setNeedsLayout() } }
    /// The layout's scale in the last layout pass.
    private(set) var layoutScale: Float = 1

    init() {
        super.init(name: "dialoguePreviewHost")
        clipsContent = true
        isHitTestable = false
    }

    private var shownLayout: DialogueLayoutPresenter? {
        guard let layoutPresenter, layoutPresenter.parent === self, !layoutPresenter.isHidden else { return nil }
        return layoutPresenter
    }

    override var acceptsFocus: Bool { shownLayout?.acceptsFocus ?? false }
    override var showsFocusRing: Bool { false }

    /// The box's size: the scaled layout fits whatever room the host gets.
    override func measureContent(width: Float?) -> Vec2 {
        var size = Vec2.zero
        for child in children where !child.isHidden && child.style.position == .flow {
            size = pointwiseMax(size, child.measure(width: width))
        }
        return size
    }

    override func layoutChildren() {
        let content = contentRect
        for child in children where !child.isHidden {
            guard child === layoutPresenter else { child.layout(in: content); continue }
            // Not below a quarter: text drawn smaller is unreadable (and a host squeezed to
            // nothing mid-layout would otherwise ask for a huge virtual screen).
            let scale = min(1, max(0.25, content.width / virtualWidth))
            layoutScale = scale
            child.visualScale = scale
            child.layout(in: UIRect(x: content.x, y: content.y, width: content.width / scale, height: content.height / scale))
        }
    }

    /// `point` (window points) in the scaled layout's coordinates.
    func layoutPoint(_ point: Vec2) -> Vec2 {
        let origin = Vec2(contentRect.x, contentRect.y)
        return origin + (point - origin) / layoutScale
    }

    override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point) else { return nil }
        guard let layout = shownLayout else { return super.hitTest(point) }
        // Only where the layout draws something clickable, so the empty area stays inert.
        return layout.hitTest(layoutPoint(point)) != nil ? self : nil
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        guard let layout = shownLayout else { return false }
        switch event {
        case .pointerDown(let pointer) where pointer.button == .left:
            context?.focus(self)
            var widget = layout.hitTest(layoutPoint(pointer.position))
            while let current = widget, current !== layout {
                if current is Button, let id = layout.view.layoutID(of: current) {
                    layout.view.press(id)
                    return true
                }
                widget = current.parent
            }
            layout.continueOrComplete()
            return true
        case .pointerUp, .pointerDrag:
            return true
        case .key:
            return layout.handleEvent(event)
        default:
            return false
        }
    }
}
