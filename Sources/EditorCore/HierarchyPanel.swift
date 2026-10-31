import Engine

/// The hierarchy panel: a `TreeView` mirroring the world's entity tree (roots in `world.roots`
/// order, children in sibling order, titled by `Name` or "Entity <id>"), bound to the
/// `EditorSelection` in both directions (`selection.set`). Rename in place (F2 / double click)
/// runs `entity.rename`; drag and drop runs `entity.reparent`, which keeps world transforms; the
/// buttons run `entity.create`, `entity.duplicate` and `entity.delete`, enabled by their availability.
/// With a project open and an entity selected, the Create menu also has the prefab actions for
/// the primary selection: Create Prefab (`prefab.create`), and for an entity of a prefab instance
/// Select Prefab Asset (`asset.select`), Apply All, Revert All and Unpack (`prefab.apply`,
/// `prefab.revert`, `prefab.unpack`).
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
    /// What the Delete button does; the editor asks for confirmation first. Defaults to deleting.
    public var onDelete: (() -> Void)?

    private var nodes: [EntityID: TreeNode] = [:]
    private var shownStructure: [Row] = []
    /// Set while the panel pushes the model's selection into the tree (or rebuilds it), so the
    /// tree's callbacks don't echo it back.
    private var applyingSelection = false
    private var createButton: Button!
    private var duplicateButton: Button!
    private var deleteButton: Button!

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
        duplicateButton = Button("Duplicate", name: "duplicate") { [unowned session] in session.run(EntityDuplicateCommand.self, .init()) }
        deleteButton = Button("Delete", name: "delete")
        let shortcuts = EditorShortcuts()
        createButton.tooltip = "Create a new entity at the viewport camera's pivot, or a prefab from the selection"
        duplicateButton.tooltip = shortcuts.tooltip("Duplicate the selection", for: .duplicate)
        deleteButton.tooltip = shortcuts.tooltip("Delete the selection", for: .delete)
        createButton.command = EntityCreateCommand.id.rawValue
        duplicateButton.command = EntityDuplicateCommand.id.rawValue
        deleteButton.command = EntityDeleteCommand.id.rawValue
        // Rows select (rename: F2 or a double click, entity.rename; drag: entity.reparent);
        // the triangles only show or hide children.
        tree.itemCommands = ["row": SelectionSetCommand.id.rawValue, "toggle": SceneHierarchyCommand.id.rawValue]
        tree.command = EntityRenameCommand.id.rawValue  // its rename field
        let buttons = HStack(spacing: 6, [createButton, duplicateButton, deleteButton])
        deleteButton.action = { [unowned self] in
            if let onDelete { onDelete() } else { session.run(EntityDeleteCommand.self, .init()) }
        }
        view.addChildren([buttons, tree])

        tree.onSelectionChange = { [unowned self] _ in pushSelectionFromTree() }
        tree.onSelect = { [unowned self] _ in pushSelectionFromTree() }
        tree.onRename = { [unowned session] node, title in
            guard let id = node.userData as? EntityID else { return false }
            session.run(EntityRenameCommand.self, .init(entity: id, name: title))
            return true
        }
        tree.onMove = { [unowned session] nodes, parent, index in
            let ids = nodes.compactMap { $0.userData as? EntityID }
            guard ids.count == nodes.count else { return false }
            return session.run(EntityReparentCommand.self, .init(entities: ids, parent: parent?.userData as? EntityID, index: index)) != nil
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
        for (button, command) in [(duplicateButton!, EntityDuplicateCommand.id), (deleteButton!, EntityDeleteCommand.id)] {
            let enabled = session.commands.isAvailable(command)
            if button.isEnabled != enabled { button.isEnabled = enabled }
        }

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
        session.run(SelectionSetCommand.self, .init(entities: ids, primary: tree.selectedNode?.userData as? EntityID))
    }

    /// The prefab actions for the primary selection (none without a project or a selection).
    private func prefabMenuItems() -> [(String, CommandID, () -> Void)] {
        guard session.commands.isAvailable(PrefabCreateCommand.id), let entity = session.selection.primaryEntity(in: session.world),
              let id = session.world.id(of: entity) else { return [] }
        var items: [(String, CommandID, () -> Void)] = [
            ("Create Prefab", PrefabCreateCommand.id, { [unowned session] in session.run(PrefabCreateCommand.self, .init(entity: id)) }),
        ]
        if let link = session.world.prefabLink(of: entity) {
            items.append(("Select Prefab Asset", AssetSelectCommand.id, { [unowned session] in
                session.run(AssetSelectCommand.self, .init(asset: link.prefab))
            }))
            if session.isPrefabFile(link.prefab.asset) {
                items.append(("Apply All to Prefab", PrefabApplyCommand.id, { [unowned session] in
                    session.run(PrefabApplyCommand.self, .init(entity: id))
                }))
            }
            items.append(("Revert All", PrefabRevertCommand.id, { [unowned session] in session.run(PrefabRevertCommand.self, .init(entity: id)) }))
            items.append(("Unpack Prefab", PrefabUnpackCommand.id, { [unowned session] in
                session.run(PrefabUnpackCommand.self, .init(entity: id))
            }))
        }
        return items
    }

    private func showCreateMenu() {
        guard let context = view.context else { return }
        var items: [(String, CommandID, () -> Void)] = EntityTemplate.allCases.map { template in
            (template.title, EntityCreateCommand.id, { [unowned self] in
                session.run(EntityCreateCommand.self, .init(template: template, position: spawnPosition()))
            })
        }
        items += prefabMenuItems()
        let menu = PopupMenu(items: items.map(\.0), anchor: createButton)
        menu.itemCommandIDs = items.map { $0.1.rawValue }
        menu.onSelect = { index in items[index].2() }
        context.presentOverlay(menu)
    }
}
