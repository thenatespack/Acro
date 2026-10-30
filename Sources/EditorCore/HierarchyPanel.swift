import Engine

/// The hierarchy panel: a `TreeView` mirroring the world's entity tree (roots in `world.roots`
/// order, children in sibling order, titled by `Name` or "Entity <id>"), bound to the
/// `EditorSelection` in both directions. Rename in place (F2 / double click) records a
/// `RenameCommand`; drag and drop records `ReparentCommand`s that keep world transforms; the
/// buttons create, duplicate and delete through the session.
///
/// Sync: `sync()` (every frame) compares the world's structure (ids, parents, order, names)
/// with what the tree shows and rebuilds the nodes only when it differs, e.g. after undo, redo,
/// load or play mode. Nodes are kept per `EntityID`, so expansion state survives rebuilds and
/// even delete + undo. It waits while a row is being dragged or renamed.
@MainActor
public final class HierarchyPanel {
    public let session: EditorSession
    public let tree: TreeView
    public let view: VStack
    /// Where Create puts new entities (the host points it at the viewport camera's pivot).
    public var spawnPosition: () -> Vec3 = { .zero }

    private var nodes: [EntityID: TreeNode] = [:]
    private var shownStructure: [Row] = []
    /// Set while the panel pushes the model's selection into the tree (or rebuilds it), so the
    /// tree's callbacks don't echo it back.
    private var applyingSelection = false
    private var createButton: Button!

    struct Row: Equatable {
        var id: EntityID
        var depth: Int
        var title: String
    }

    public init(session: EditorSession) {
        self.session = session
        tree = TreeView(roots: [], name: "hierarchyTree")
        view = VStack(spacing: 6, padding: EdgeInsets(6), name: "hierarchyPanel")
        tree.allowsMultipleSelection = true
        tree.allowsRename = true
        tree.allowsDragAndDrop = true
        tree.background = .clear
        tree.style.grow = 1
        tree.style.shrink = 1

        createButton = Button("Create", name: "create") { [unowned self] in showCreateMenu() }
        let buttons = HStack(spacing: 6, [
            createButton,
            Button("Duplicate", name: "duplicate") { [unowned self] in session.duplicateSelection() },
            Button("Delete", name: "delete") { [unowned self] in session.deleteSelection() },
        ])
        view.addChildren([buttons, tree])

        tree.onSelectionChange = { [unowned self] _ in pushSelectionFromTree() }
        tree.onSelect = { [unowned self] _ in pushSelectionFromTree() }
        tree.onRename = { [unowned self] node, title in
            guard let id = node.userData as? EntityID else { return false }
            session.rename(id, to: title)
            return true
        }
        tree.onMove = { [unowned self] nodes, parent, index in
            let ids = nodes.compactMap { $0.userData as? EntityID }
            guard ids.count == nodes.count else { return false }
            return session.move(ids, to: parent?.userData as? EntityID, at: index)
        }
        session.selection.observe { [unowned self] _ in applySelectionToTree() }
        sync(force: true)
    }

    /// The node showing `id`, if it is in the tree.
    public func node(for id: EntityID) -> TreeNode? {
        guard let node = nodes[id], isInTree(node) else { return nil }
        return node
    }

    /// Rebuilds the tree if the world's hierarchy or names changed (or always, with `force`).
    public func sync(force: Bool = false) {
        guard force || (!tree.isDragging && tree.renamingNode == nil) else { return }
        let structure = Self.structure(of: session.world, name: session.displayName(of:))
        guard force || structure != shownStructure else { return }
        shownStructure = structure
        rebuild(structure)
    }

    /// The world's tree as depth-first rows.
    static func structure(of world: World, name: (Entity) -> String) -> [Row] {
        var rows: [Row] = []
        func visit(_ entity: Entity, _ depth: Int) {
            guard let id = world.ensureID(of: entity) else { return }
            rows.append(Row(id: id, depth: depth, title: name(entity)))
            for child in world.children(of: entity) { visit(child, depth + 1) }
        }
        for root in world.roots { visit(root, 0) }
        return rows
    }

    private func rebuild(_ rows: [Row]) {
        applyingSelection = true
        defer { applyingSelection = false }
        var roots: [TreeNode] = []
        var stack: [TreeNode] = []
        for node in nodes.values { node.removeAllChildren() }
        for row in rows {
            let node = nodes[row.id] ?? TreeNode(row.title, isExpanded: true, userData: row.id)
            nodes[row.id] = node
            node.title = row.title
            stack.removeLast(stack.count - row.depth)
            if let parent = stack.last { parent.addChild(node) } else { roots.append(node) }
            stack.append(node)
        }
        // Forget nodes of long-gone entities, but keep recently deleted ones (undo brings them back).
        if nodes.count > 4 * rows.count + 64 {
            let live = Set(rows.map(\.id))
            nodes = nodes.filter { live.contains($0.key) }
        }
        tree.roots = roots
        applySelectionToTree(reveal: false)
    }

    private func isInTree(_ node: TreeNode) -> Bool {
        var top = node
        while let parent = top.parent { top = parent }
        return tree.roots.contains { $0 === top }
    }

    private func applySelectionToTree(reveal: Bool = true) {
        let wasApplying = applyingSelection
        applyingSelection = true
        defer { applyingSelection = wasApplying }
        let selection = session.selection
        let selected = selection.ids.compactMap { node(for: $0) }
        let primary = selection.primary.flatMap { node(for: $0) } ?? selected.last
        tree.setSelection(selected, primary: primary, reveal: reveal)
    }

    private func pushSelectionFromTree() {
        guard !applyingSelection else { return }
        let ids = tree.selectedNodes.compactMap { $0.userData as? EntityID }
        session.selection.set(ids, primary: tree.selectedNode?.userData as? EntityID)
    }

    private func showCreateMenu() {
        guard let context = view.context else { return }
        let templates = EntityTemplate.allCases
        let menu = PopupMenu(items: templates.map(\.title), anchor: createButton)
        menu.onSelect = { [unowned self] index in
            session.create(templates[index], at: spawnPosition())
        }
        context.presentOverlay(menu)
    }
}
