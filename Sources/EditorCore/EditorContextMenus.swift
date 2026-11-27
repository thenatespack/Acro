import Engine
import Foundation

// Right-click menus on the editor's tabs and on scene objects:
// - a dock tab: Close, Close Other Tabs, Pop Out, Dock (a floating one), Reset Layout;
// - an entity in the Hierarchy or the Scene view (a right-click without dragging; dragging with
//   the right button still flies): Rename, Duplicate, Delete, Frame, Create Empty Child,
//   Unparent and the prefab actions; over empty space, the Create items.
// Each item reports the command it runs (`ui.snapshot`), and items whose command isn't
// available right now (while playing, say) are disabled.

/// One item of a context menu.
@MainActor
struct EditorMenuItem {
    var title: String
    /// The command it runs, or the tool that does the same for an agent.
    var command: CommandID
    var icon: VectorIcon?
    var isEnabled = true
    var action: () -> Void
}

extension EditorApp {
    /// Shows `items` as a popup menu at `point` (points of `context`).
    func presentContextMenu(_ items: [EditorMenuItem], at point: Vec2, in context: UIContext?, name: String) {
        guard let context, !items.isEmpty else { return }
        let menu = PopupMenu(items: items.map(\.title), name: name)
        menu.itemCommandIDs = items.map { $0.command.rawValue }
        menu.itemIcons = items.map(\.icon)
        menu.disabledIndices = Set(items.indices.filter { !items[$0].isEnabled })
        menu.anchorRect = UIRect(x: point.x, y: point.y, width: 1, height: 1)
        menu.onSelect = { index in items[index].action() }
        context.presentOverlay(menu)
    }

    private func item(_ title: String, _ command: CommandID, icon: String? = nil, action: @escaping () -> Void) -> EditorMenuItem {
        EditorMenuItem(title: title, command: command, icon: icon.flatMap { EditorIcons.named($0) },
                       isEnabled: session.commands.isAvailable(command), action: action)
    }

    // MARK: Tabs

    /// The menu of dock panel `id`'s tab.
    func tabMenuItems(_ id: String) -> [EditorMenuItem] {
        guard let panel = dock.panel(id) else { return [] }
        var items: [EditorMenuItem] = []
        if panel.isClosable {
            items.append(item("Close", PanelCloseCommand.id, icon: "x") { [unowned self] in
                session.run(PanelCloseCommand.self, .init(panel: id))
            })
        }
        let others = EditorLayout.groupPanels(in: dock.layout, containing: id).filter { $0 != id && dock.panel($0)?.isClosable == true }
        if !others.isEmpty {
            items.append(item("Close Other Tabs", PanelCloseCommand.id) { [unowned self] in
                for other in others { session.run(PanelCloseCommand.self, .init(panel: other)) }
            })
        }
        items.append(item(Self.mainWindowPanels.contains(id) ? "Float" : "Open in New Window", PanelPopOutCommand.id,
                          icon: "layers") { [unowned self] in
            session.run(PanelPopOutCommand.self, .init(panel: id))
        })
        if isFloating(id) {
            items.append(item("Dock", PanelDockCommand.id) { [unowned self] in dockAtHome(id) })
        }
        items.append(item("Reset Layout", LayoutResetCommand.id, icon: "layout-dashboard") { [unowned self] in
            session.run(LayoutResetCommand.self)
        })
        return items
    }

    /// Docks panel `id` where it belongs: a builder with the Scene view, another panel where
    /// the default layout has it.
    func dockAtHome(_ id: String) {
        if EditorBuilderRegistry.modules.contains(where: { $0.panelID == id }) {
            dock.dock(id, at: dock.isOpen(EditorLayout.viewport) && id != EditorLayout.viewport
                ? .tab(with: EditorLayout.viewport) : .edge(.bottom))
        } else {
            dock.dock(id, at: EditorLayout.defaultPosition(of: id, in: dock))
        }
        dock.focusPanel(id)
        syncPanels()
    }

    func showTabMenu(_ id: String, at point: Vec2) {
        presentContextMenu(tabMenuItems(id), at: point, in: dock.context, name: "tabMenu")
    }

    // MARK: Scene objects

    /// The menu for the selected entities (from a right-click on one of them).
    func entityMenuItems() -> [EditorMenuItem] {
        let world = session.world
        let selected = session.selection.topLevelEntities(in: world)
        guard let primary = session.selection.primaryEntity(in: world), let primaryID = world.id(of: primary) else { return [] }
        var items: [EditorMenuItem] = []
        if selected.count == 1 {
            items.append(item("Rename", EntityRenameCommand.id, icon: "pencil") { [unowned self] in rename(primaryID) })
        }
        items.append(item("Duplicate", EntityDuplicateCommand.id, icon: "copy") { [unowned self] in
            session.run(EntityDuplicateCommand.self, .init())
        })
        items.append(item("Delete…", EntityDeleteCommand.id, icon: "trash-2") { [unowned self] in confirmDeleteSelection() })
        items.append(item("Frame in Scene View", ViewFrameSelectionCommand.id, icon: "search") { [unowned self] in
            if dock.isOpen(EditorLayout.viewport) { dock.focusPanel(EditorLayout.viewport) }
            session.run(ViewFrameSelectionCommand.self, .init())
        })
        items.append(item("Create Empty Child", EntityCreateCommand.id, icon: "plus") { [unowned self] in
            session.run(EntityCreateCommand.self, .init(template: .empty, parent: primaryID))
        })
        let ids = selected.compactMap { world.id(of: $0) }
        if selected.contains(where: { world.parent(of: $0) != nil }) {
            items.append(item("Unparent", EntityReparentCommand.id, icon: "unlink") { [unowned self] in
                session.run(EntityReparentCommand.self, .init(entities: ids, parent: nil))
            })
        }
        for (title, command, action) in hierarchy.prefabMenuItems() {
            var prefab = item(title, command, action: action)
            prefab.icon = HierarchyPanel.prefabMenuIcon(command)
            items.append(prefab)
        }
        return items
    }

    /// The menu over empty space: the Create items, new entities at `position`.
    func createMenuItems(at position: Vec3) -> [EditorMenuItem] {
        EntityTemplate.allCases.map { template in
            var create = item("Create \(template.title)", EntityCreateCommand.id) { [unowned self] in
                session.run(EntityCreateCommand.self, .init(template: template, position: position))
            }
            create.icon = EditorIcons.template(template)
            return create
        }
    }

    /// Renames `id` in place in the Hierarchy (opening it if needed).
    func rename(_ id: EntityID) {
        if !dock.isOpen(EditorLayout.hierarchy) && !isPoppedOut(EditorLayout.hierarchy) {
            session.run(PanelOpenCommand.self, .init(panel: EditorLayout.hierarchy))
        }
        hierarchy.sync()
        guard let node = hierarchy.node(for: id) else { return }
        hierarchy.tree.beginRename(node)
    }

    /// A right-click in the Hierarchy: on a row (now selected) the entity menu, else Create.
    func showHierarchyMenu(onRow: Bool, at point: Vec2) {
        let items = onRow ? entityMenuItems() : createMenuItems(at: hierarchy.spawnPosition())
        presentContextMenu(items, at: point, in: hierarchy.tree.context, name: "entityMenu")
    }

    /// A right-click in the Scene view at `point` (viewport points): the entity under it is
    /// selected (unless it already is) and gets the entity menu; empty space gets Create.
    func showViewportMenu(at point: Vec2, context: ViewportToolContext) {
        let world = session.world
        let hit = BoundsClickSelectTool.pick(context.ray(at: point), context: context)
        let windowPoint = point + Vec2(viewport.rect.x, viewport.rect.y)
        if let hit, let id = world.id(of: hit) {
            if !session.selection.entities(in: world).contains(hit) {
                session.run(SelectionSetCommand.self, .init(entities: [id]))
            }
            presentContextMenu(entityMenuItems(), at: windowPoint, in: ui, name: "entityMenu")
        } else {
            presentContextMenu(createMenuItems(at: hierarchy.spawnPosition()), at: windowPoint, in: ui, name: "entityMenu")
        }
    }
}
