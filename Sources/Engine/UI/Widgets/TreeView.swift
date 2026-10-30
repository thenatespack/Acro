import Foundation

/// A node of a `TreeView`. Classes so the editor can keep references (e.g. to entities via `userData`).
@MainActor
public final class TreeNode {
    public var title: String
    public private(set) var children: [TreeNode] = []
    public private(set) weak var parent: TreeNode?
    public var isExpanded: Bool
    /// Anything the owner wants to attach (an entity, an asset…).
    public var userData: Any?

    public init(_ title: String, isExpanded: Bool = false, children: [TreeNode] = [], userData: Any? = nil) {
        self.title = title
        self.isExpanded = isExpanded
        self.userData = userData
        for child in children { addChild(child) }
    }

    public func addChild(_ child: TreeNode) {
        child.parent?.children.removeAll { $0 === child }
        children.append(child)
        child.parent = self
    }

    /// Inserts `child` at `index` (clamped), moving it out of its current parent first. The
    /// index counts the children after `child` has been taken out of this node.
    public func insertChild(_ child: TreeNode, at index: Int) {
        child.parent?.children.removeAll { $0 === child }
        children.insert(child, at: min(max(index, 0), children.count))
        child.parent = self
    }

    /// Detaches the node from its parent (a root stays in `TreeView.roots` until removed there).
    public func removeFromParent() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    public func removeAllChildren() {
        for child in children { child.parent = nil }
        children.removeAll()
    }

    public var hasChildren: Bool { !children.isEmpty }
    public var depth: Int { parent.map { $0.depth + 1 } ?? 0 }

    /// Whether `ancestor` is this node's parent, grandparent, … (a node is not its own descendant).
    public func isDescendant(of ancestor: TreeNode) -> Bool {
        var node = parent
        while let current = node {
            if current === ancestor { return true }
            node = current.parent
        }
        return false
    }
}

/// Where a drag would drop, relative to the row under the pointer.
public enum TreeDropPosition: Sendable {
    /// Between this node and the one above it (a sibling, before it).
    case before
    /// Below this node: its next sibling, or its first child when it is expanded.
    case after
    /// Onto the node: its last child.
    case into
}

/// A resolved drop: `nodes` would become children of `parent` (nil: roots) at `index`.
public struct TreeDropTarget {
    public var parent: TreeNode?
    /// Insertion index among `parent`'s children once the moved nodes have been taken out of
    /// them (what `TreeView.onMove` receives).
    public var index: Int
    public var position: TreeDropPosition
    /// The visible row the pointer is over (nil below the last row).
    public var row: Int?
}

/// An expandable tree of `TreeNode` rows (the editor's hierarchy panel). Click the disclosure
/// triangle (or double-click, Enter, Space) to expand/collapse. Keys: Up/Down move, Right
/// expands or steps into the first child, Left collapses or steps to the parent.
/// Call `reloadData()` after changing nodes from outside.
///
/// Opt-in editing features (all off by default, so a plain tree behaves as before):
/// - `allowsMultipleSelection`: cmd/ctrl-click toggles a row, shift-click selects the range
///   from the anchor (the last row clicked without shift; cmd/ctrl+shift adds the range),
///   shift+Up/Down/Home/End/Page extend it, cmd/ctrl+A selects every visible row. A plain
///   click or arrow key goes back to one row. `selectedNode` is the primary (last clicked)
///   row, `selectedNodes` all of them in tree order. Selection survives collapsing.
/// - `allowsRename`: F2, Enter or a double click on a row edits its title in place (Enter or
///   focus loss commits, Esc cancels, an empty title cancels). Double click and Enter then no
///   longer expand/activate: use Space, the arrows or the disclosure triangle.
/// - `allowsDragAndDrop`: drag a row (or the whole selection, when the row is part of it) to
///   reparent / reorder. The top quarter of a row drops before it, the bottom quarter after it
///   (as its first child when it is expanded), the middle onto it; below the last row drops at
///   the end of the roots. A drag can't go into itself or its own descendants. Hovering a
///   collapsed node while dragging expands it after `autoExpandDelay`; the pointer near the
///   top or bottom edge scrolls. Esc cancels the drag.
///
/// The drop and rename callbacks can veto, so the owner's model stays the source of truth:
/// `onMove` / `onRename` run first, and the tree changes its nodes only when they say yes.
public final class TreeView: RowListView {
    public var roots: [TreeNode] { didSet { reloadData() } }
    /// Called when the selected (primary) node changes.
    public var onSelect: ((TreeNode?) -> Void)?
    /// Called on double click / Enter on a leaf.
    public var onActivate: ((TreeNode) -> Void)?

    /// Cmd/ctrl-click, shift-click and shift+arrows select several rows.
    public var allowsMultipleSelection = false
    /// F2 / Enter / double click rename the selected row in place.
    public var allowsRename = false
    /// Rows can be dragged to reparent or reorder them.
    public var allowsDragAndDrop = false

    /// Called when the set of selected nodes changes (also for a single selection).
    public var onSelectionChange: (([TreeNode]) -> Void)?
    /// A rename was committed with a new, non-empty title: return false to veto (the title is
    /// left alone); true, or no handler, applies it.
    public var onRename: ((_ node: TreeNode, _ newTitle: String) -> Bool)?
    /// Asks whether `nodes` (the dragged nodes, ancestors only, in tree order) may become
    /// children of `parent` (nil: roots) at `index` (see `TreeDropTarget.index`). Used for the
    /// drop indicator and again on drop; no handler allows everything that isn't a cycle.
    public var canMove: ((_ nodes: [TreeNode], _ parent: TreeNode?, _ index: Int) -> Bool)?
    /// A drop happened. Return true to let the tree move its nodes (the usual case: update your
    /// model here, e.g. `world.setParent`, and say yes); false to veto, or to rebuild the nodes
    /// yourself (`roots` / `reloadData()`).
    public var onMove: ((_ nodes: [TreeNode], _ parent: TreeNode?, _ index: Int) -> Bool)?

    /// Seconds a dragged node must hover over a collapsed node to expand it.
    public var autoExpandDelay: Double = 0.6
    /// Distance from the viewport's top / bottom edge in which a drag scrolls, in points.
    public var autoScrollZone: Float = 28
    /// Points per second a drag scrolls at the very edge (it ramps up from 0 at the zone's start).
    public var autoScrollSpeed: Float = 600
    /// Distance the pointer must move before a press becomes a drag, in points.
    public var dragThreshold: Float = 4

    private var rows: [(node: TreeNode, depth: Int)] = []
    private var selection = Set<ObjectIdentifier>()
    private weak var anchor: TreeNode?
    private var internalSelection = false

    private struct Press {
        var row: Int
        var position: Vec2
        /// The press was on a row that is part of a multi-selection: it collapses to this row on
        /// release unless a drag starts.
        var collapseOnRelease: Bool
    }
    private struct Drag {
        var nodes: [TreeNode]
        var ids: Set<ObjectIdentifier>
        var target: TreeDropTarget?
        var lastTick: Double
        var hoverNode: TreeNode?
        var hoverSince: Double = 0
    }
    private var press: Press?
    private var drag: Drag?

    public private(set) var renamingNode: TreeNode?
    private var renameField: TextField?

    public init(roots: [TreeNode], name: String = "") {
        self.roots = roots
        super.init(name: name)
        rebuildRows()
    }

    public override var rowCount: Int { rows.count }

    /// Rows currently visible (expanded ancestors), in order.
    public var visibleNodes: [TreeNode] { rows.map(\.node) }

    /// The primary selected node: the one last clicked or moved to.
    public var selectedNode: TreeNode? { selectedRow.map { rows[$0].node } }

    /// Every selected node in tree order (including ones hidden inside collapsed parents).
    public var selectedNodes: [TreeNode] {
        guard !selection.isEmpty else { return [] }
        var result: [TreeNode] = []
        func visit(_ node: TreeNode) {
            if selection.contains(ObjectIdentifier(node)) { result.append(node) }
            for child in node.children { visit(child) }
        }
        for root in roots { visit(root) }
        return result
    }

    /// Whether a drag is in progress.
    public var isDragging: Bool { drag != nil }
    /// Where the drag in progress would drop (nil: nowhere valid).
    public var dropTarget: TreeDropTarget? { drag?.target }

    /// Re-reads the nodes (keeps the selected node selected if it's still visible, and drops
    /// selected nodes that are no longer in the tree).
    public func reloadData() {
        let selected = selectedNode
        rebuildRows()
        if !selection.isEmpty { pruneSelection() }
        if let renaming = renamingNode, rowIndex(of: renaming) == nil { endRename(refocus: false) }
        internalSelection = true
        selectRow(selected.flatMap(rowIndex(of:)), reveal: false)
        internalSelection = false
        setNeedsLayout()
    }

    /// Selects only `node` (expanding its ancestors) and scrolls to it; nil clears the selection.
    public func select(_ node: TreeNode?) {
        guard let node else { setSelection([], primary: nil); return }
        var ancestor = node.parent
        var changed = false
        while let a = ancestor {
            if !a.isExpanded { a.isExpanded = true; changed = true }
            ancestor = a.parent
        }
        if changed { reloadData() }
        setSelection([node], primary: node)
    }

    /// Selects exactly `nodes` (expanding ancestors of the primary one) with `primary` as the
    /// active row. The anchor for shift-click ranges becomes the primary.
    public func setSelection(_ nodes: [TreeNode], primary: TreeNode?, reveal: Bool = true) {
        if let primary {
            var ancestor = primary.parent
            var changed = false
            while let a = ancestor {
                if !a.isExpanded { a.isExpanded = true; changed = true }
                ancestor = a.parent
            }
            if changed { reloadData() }
        }
        applySelection(nodes, primary: primary, anchor: primary, reveal: reveal)
    }

    public func setExpanded(_ node: TreeNode, _ expanded: Bool) {
        guard node.hasChildren, node.isExpanded != expanded else { return }
        node.isExpanded = expanded
        reloadData()
    }

    public func toggle(_ node: TreeNode) { setExpanded(node, !node.isExpanded) }

    private func rebuildRows() {
        rows.removeAll(keepingCapacity: true)
        func visit(_ node: TreeNode, _ depth: Int) {
            rows.append((node, depth))
            if node.isExpanded { for child in node.children { visit(child, depth + 1) } }
        }
        for root in roots { visit(root, 0) }
    }

    private func rowIndex(of node: TreeNode) -> Int? {
        rows.firstIndex { $0.node === node }
    }

    // MARK: Selection

    private func pruneSelection() {
        var present = Set<ObjectIdentifier>()
        func visit(_ node: TreeNode) {
            if selection.contains(ObjectIdentifier(node)) { present.insert(ObjectIdentifier(node)) }
            for child in node.children { visit(child) }
        }
        for root in roots { visit(root) }
        if present != selection {
            selection = present
            onSelectionChange?(selectedNodes)
        }
    }

    private func applySelection(_ nodes: [TreeNode], primary: TreeNode?, anchor newAnchor: TreeNode?, reveal: Bool = true) {
        let old = selection
        selection = Set(nodes.map(ObjectIdentifier.init))
        if let primary { selection.insert(ObjectIdentifier(primary)) }
        if let newAnchor { anchor = newAnchor } else if primary == nil { anchor = nil }
        internalSelection = true
        selectRow(primary.flatMap(rowIndex(of:)), reveal: reveal)
        internalSelection = false
        setNeedsDisplay()
        if selection != old { onSelectionChange?(selectedNodes) }
    }

    public override func selectionChanged() {
        if !internalSelection {
            // Moved by the keyboard or `selectRow`: back to a single selection.
            let old = selection
            selection = selectedNode.map { [ObjectIdentifier($0)] } ?? []
            anchor = selectedNode
            if selection != old { onSelectionChange?(selectedNodes) }
        }
        onSelect?(selectedNode)
    }

    public override func isRowSelected(_ row: Int) -> Bool {
        row == selectedRow || (!selection.isEmpty && selection.contains(ObjectIdentifier(rows[row].node)))
    }

    /// Selects the rows between the anchor and `row` (inclusive); `adding` keeps the current selection.
    private func selectRange(to row: Int, adding: Bool) {
        let anchorNode = anchor.flatMap { rowIndex(of: $0) != nil ? $0 : nil } ?? selectedNode ?? rows[row].node
        let anchorRow = rowIndex(of: anchorNode) ?? row
        let range = min(anchorRow, row)...max(anchorRow, row)
        let nodes = (adding ? selectedNodes : []) + rows[range].map(\.node)
        applySelection(nodes, primary: rows[row].node, anchor: anchorNode)
    }

    private func toggleSelection(of row: Int) {
        let node = rows[row].node
        var nodes = selectedNodes
        if let index = nodes.firstIndex(where: { $0 === node }) {
            nodes.remove(at: index)
            // The primary row went away: the last remaining row (in tree order) takes over.
            let primary = node === selectedNode ? nodes.last(where: { rowIndex(of: $0) != nil }) : selectedNode
            applySelection(nodes, primary: primary, anchor: primary)
        } else {
            nodes.append(node)
            applySelection(nodes, primary: node, anchor: node)
        }
    }

    private func selectAllVisible() {
        guard !rows.isEmpty else { return }
        applySelection(rows.map(\.node), primary: selectedNode ?? rows[0].node, anchor: anchor)
    }

    // MARK: Pointer

    private func disclosureRect(row: Int, in rect: UIRect) -> UIRect {
        let indent = theme.treeIndent
        return UIRect(x: rect.x + 4 + Float(rows[row].depth) * indent, y: rect.y, width: indent, height: rect.height)
    }

    public override func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool {
        let viewport = contentRect
        let h = effectiveRowHeight
        let rect = UIRect(x: viewport.x, y: viewport.y + Float(row) * h - scroll.offset, width: viewport.width, height: h)
        if rows[row].node.hasChildren, disclosureRect(row: row, in: rect).contains(position) {
            selectRow(row)
            toggle(rows[row].node)
            return true
        }
        guard allowsMultipleSelection || allowsDragAndDrop || allowsRename else { return false }

        let node = rows[row].node
        let additive = allowsMultipleSelection && (event.modifiers.contains(.command) || event.modifiers.contains(.control))
        let ranged = allowsMultipleSelection && event.modifiers.contains(.shift)
        press = nil
        if event.clickCount >= 2 && !additive && !ranged {
            applySelection([node], primary: node, anchor: node)
            if allowsRename { beginRename(node) } else { rowActivated(row) }
            return true
        }
        var collapseOnRelease = false
        if ranged {
            selectRange(to: row, adding: additive)
        } else if additive {
            toggleSelection(of: row)
        } else if allowsDragAndDrop, selection.count > 1, selection.contains(ObjectIdentifier(node)) {
            // Keep the group so it can be dragged; a click without a drag narrows it on release.
            applySelection(selectedNodes, primary: node, anchor: node)
            collapseOnRelease = true
        } else {
            applySelection([node], primary: node, anchor: node)
        }
        if allowsDragAndDrop && !additive && !ranged {
            press = Press(row: row, position: position, collapseOnRelease: collapseOnRelease)
        }
        return true
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDrag(let e) where press != nil:
            dragMoved(to: e.position)
            return true
        case .pointerUp(let e) where press != nil:
            finishPress(at: e.position)
            return true
        case .key(let e) where e.key == .escape:
            if drag != nil { cancelDrag(); return true }
            if renamingNode != nil { cancelRename(); return true }
        default:
            break
        }
        return super.handleEvent(event)
    }

    // MARK: Drag and drop

    private func dragMoved(to position: Vec2) {
        guard let press else { return }
        if drag == nil {
            let delta = position - press.position
            guard (delta * delta).sum() >= dragThreshold * dragThreshold else { return }
            beginDrag()
        }
        tickDrag()
    }

    private func beginDrag() {
        let selected = selectedNodes
        // Only the topmost selected nodes move: their descendants come along.
        let top = selected.filter { node in !selected.contains { node.isDescendant(of: $0) } }
        guard !top.isEmpty else { return }
        press?.collapseOnRelease = false
        drag = Drag(nodes: top, ids: Set(top.map(ObjectIdentifier.init)), target: nil, lastTick: context?.time ?? 0)
        setNeedsDisplay()
    }

    /// Advances the drag in progress (auto-scroll, hover expansion, the drop target) to the
    /// pointer's current position. Runs on every pointer move and every painted frame, so a
    /// pointer held still at the edge keeps scrolling.
    private func tickDrag() {
        guard var state = drag, let context else { return }
        let now = context.time
        let dt = Float(max(0, now - state.lastTick))
        state.lastTick = now
        let pointer = context.pointerPosition
        let viewport = contentRect

        let zone = autoScrollZone
        if dt > 0, zone > 0, scroll.canScroll {
            var velocity: Float = 0
            if pointer.y < viewport.y + zone {
                velocity = -min(1, (viewport.y + zone - pointer.y) / zone)
            } else if pointer.y > viewport.maxY - zone {
                velocity = min(1, (pointer.y - (viewport.maxY - zone)) / zone)
            }
            if velocity != 0 { scroll(to: scroll.offset + velocity * autoScrollSpeed * dt) }
        }

        var target = dropTarget(at: pointer, dragging: state.nodes)
        if let t = target, t.position == .into, let row = t.row, rows[row].node.hasChildren, !rows[row].node.isExpanded {
            let node = rows[row].node
            if state.hoverNode !== node {
                state.hoverNode = node
                state.hoverSince = now
            } else if now - state.hoverSince >= autoExpandDelay {
                state.hoverNode = nil
                drag = state
                setExpanded(node, true)
                target = dropTarget(at: pointer, dragging: state.nodes)
            }
        } else {
            state.hoverNode = nil
        }
        state.target = target
        drag = state
        setNeedsDisplay()
    }

    private func finishPress(at position: Vec2) {
        guard let press else { return }
        self.press = nil
        if let state = drag {
            tickDrag()
            let target = drag?.target ?? state.target
            drag = nil
            setNeedsDisplay()
            if let target { drop(state.nodes, on: target) }
        } else if press.collapseOnRelease, rows.indices.contains(press.row) {
            let node = rows[press.row].node
            applySelection([node], primary: node, anchor: node)
        }
    }

    private func cancelDrag() {
        drag = nil
        press = nil
        setNeedsDisplay()
    }

    private func drop(_ nodes: [TreeNode], on target: TreeDropTarget) {
        if let onMove, !onMove(nodes, target.parent, target.index) { return }
        var newRoots = roots
        for node in nodes {
            if node.parent != nil { node.removeFromParent() } else { newRoots.removeAll { $0 === node } }
        }
        if let parent = target.parent {
            for (i, node) in nodes.enumerated() { parent.insertChild(node, at: target.index + i) }
            parent.isExpanded = true
        } else {
            newRoots.insert(contentsOf: nodes, at: min(target.index, newRoots.count))
        }
        let selected = selectedNodes
        let primary = selectedNode
        roots = newRoots  // reloads
        applySelection(selected, primary: primary, anchor: anchor, reveal: false)
    }

    /// What dropping `nodes` at a window point would do, or nil when it is nowhere valid (outside
    /// the rows, into a node's own subtree, vetoed by `canMove`, or a move that changes nothing).
    public func dropTarget(at point: Vec2, dragging nodes: [TreeNode]) -> TreeDropTarget? {
        let viewport = contentRect
        guard point.x >= viewport.x, point.x < viewport.maxX, point.y >= viewport.y, point.y < viewport.maxY else { return nil }
        let h = effectiveRowHeight
        let y = point.y - viewport.y + scroll.offset
        var target: TreeDropTarget
        if y >= Float(rows.count) * h {
            target = TreeDropTarget(parent: nil, index: roots.count, position: .after, row: nil)
        } else {
            let row = Int((y / h).rounded(.down))
            let node = rows[row].node
            let fraction = (y - Float(row) * h) / h
            let siblings = node.parent?.children ?? roots
            let at = siblings.firstIndex { $0 === node } ?? 0
            if fraction < 0.25 {
                target = TreeDropTarget(parent: node.parent, index: at, position: .before, row: row)
            } else if fraction >= 0.75 {
                if node.isExpanded && node.hasChildren {
                    target = TreeDropTarget(parent: node, index: 0, position: .after, row: row)
                } else {
                    target = TreeDropTarget(parent: node.parent, index: at + 1, position: .after, row: row)
                }
            } else {
                target = TreeDropTarget(parent: node, index: node.children.count, position: .into, row: row)
            }
        }
        // Nothing may go into itself or below itself.
        for node in nodes {
            if let parent = target.parent, parent === node || parent.isDescendant(of: node) { return nil }
        }
        // The index counts the siblings that stay: the moved ones leave first.
        let siblings = target.parent?.children ?? roots
        let before = nodes.filter { node in
            node.parent === target.parent && (siblings.firstIndex { $0 === node }).map { $0 < target.index } == true
        }.count
        target.index -= before
        // Dropping the nodes back where they are is not a move.
        let remaining = siblings.filter { sibling in !nodes.contains { $0 === sibling } }
        var result = remaining
        result.insert(contentsOf: nodes, at: min(target.index, result.count))
        if result.count == siblings.count, zip(result, siblings).allSatisfy({ $0 === $1 }) { return nil }
        if let canMove, !canMove(nodes, target.parent, target.index) { return nil }
        return target
    }

    // MARK: Rename

    /// Edits `node`'s title in place. Enter or leaving the field commits, Esc cancels.
    public func beginRename(_ node: TreeNode) {
        guard context != nil, let row = rowIndex(of: node) else { return }
        if renamingNode != nil { cancelRename() }
        revealRow(row)
        let field: TextField
        if let existing = renameField {
            field = existing
        } else {
            field = TextField(name: "rename")
            field.onSubmit = { [weak self] text in self?.commitRename(text) }
            field.onEndEditing = { [weak self] text in
                if self?.renamingNode != nil { self?.commitRename(text) }
            }
            renameField = field
            addChild(field)
        }
        renamingNode = node
        field.text = node.title
        field.isHidden = false
        layoutRenameField()
        field.select(0..<node.title.count)
        context?.focus(field)
        setNeedsDisplay()
    }

    private func commitRename(_ text: String) {
        guard let node = renamingNode else { return }
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        endRename(refocus: true)
        guard !title.isEmpty, title != node.title else { return }
        if onRename?(node, title) ?? true { node.title = title }
        setNeedsDisplay()
    }

    public func cancelRename() {
        endRename(refocus: true)
    }

    private func endRename(refocus: Bool) {
        guard renamingNode != nil else { return }
        let hadFocus = renameField?.isFocused ?? false
        renamingNode = nil
        renameField?.isHidden = true
        // Enter and Esc hand the keyboard back to the tree; a click elsewhere keeps its focus.
        if refocus && hadFocus { context?.focus(self) }
        setNeedsDisplay()
    }

    private func layoutRenameField() {
        guard let node = renamingNode, let field = renameField, let row = rowIndex(of: node) else { return }
        let viewport = contentRect
        let h = effectiveRowHeight
        let rect = UIRect(x: viewport.x, y: viewport.y + Float(row) * h - scroll.offset, width: viewport.width, height: h)
        // The field's own padding puts its text where the row's title is drawn.
        let x = disclosureRect(row: row, in: rect).maxX + 2 - field.padding.left
        field.layout(in: UIRect(x: x, y: rect.y + 1, width: max(60, viewport.maxX - x - 2), height: h - 2))
    }

    public override func layoutChildren() {
        super.layoutChildren()
        layoutRenameField()
    }

    // MARK: Keys

    public override func handleRowKey(_ key: KeyEvent) -> Bool {
        if allowsMultipleSelection, key.key == .a, key.modifiers.contains(.shortcut) {
            selectAllVisible()
            return true
        }
        if allowsRename, let node = selectedNode, !key.isRepeat,
           key.key == .f2 || (key.key == .enter && key.modifiers.isEmpty) {
            beginRename(node)
            return true
        }
        if allowsMultipleSelection, key.modifiers.contains(.shift), let current = selectedRow {
            let page = max(1, Int(contentRect.height / effectiveRowHeight) - 1)
            let target: Int?
            switch key.key {
            case .up: target = current - 1
            case .down: target = current + 1
            case .pageUp: target = current - page
            case .pageDown: target = current + page
            case .home: target = 0
            case .end: target = rows.count - 1
            default: target = nil
            }
            if let target {
                let row = min(max(target, 0), rows.count - 1)
                selectRange(to: row, adding: false)
                revealRow(row)
                return true
            }
        }
        guard let row = selectedRow else { return false }
        let node = rows[row].node
        switch key.key {
        case .right:
            if node.hasChildren && !node.isExpanded { toggle(node) } else if node.hasChildren { selectRow(row + 1) }
            return true
        case .left:
            if node.hasChildren && node.isExpanded {
                toggle(node)
            } else if let parent = node.parent, let index = rows.firstIndex(where: { $0.node === parent }) {
                selectRow(index)
            }
            return true
        case .space:
            if node.hasChildren { toggle(node) }
            return true
        default:
            return false
        }
    }

    public override func rowActivated(_ row: Int) {
        let node = rows[row].node
        if node.hasChildren { toggle(node) } else { onActivate?(node) }
    }

    // MARK: Drawing

    public override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let (node, _) = rows[row]
        let disclosure = disclosureRect(row: row, in: rect)
        let color = isEffectivelyEnabled ? theme.textColor : theme.disabledTextColor
        if node.hasChildren {
            // A small triangle from two lines: pointing right when collapsed, down when expanded.
            let c = disclosure.center
            let s: Float = 3.5
            let arrow = theme.secondaryTextColor
            if node.isExpanded {
                list.drawLine(from: c + Vec2(-s, -s / 2), to: c + Vec2(0, s / 2), width: 1.5, color: arrow, cap: .round)
                list.drawLine(from: c + Vec2(0, s / 2), to: c + Vec2(s, -s / 2), width: 1.5, color: arrow, cap: .round)
            } else {
                list.drawLine(from: c + Vec2(-s / 2, -s), to: c + Vec2(s / 2, 0), width: 1.5, color: arrow, cap: .round)
                list.drawLine(from: c + Vec2(s / 2, 0), to: c + Vec2(-s / 2, s), width: 1.5, color: arrow, cap: .round)
            }
        }
        if node === renamingNode { return }
        let dragged = drag?.ids.contains(ObjectIdentifier(node)) ?? false
        let layout = cachedLayout(node.title, size: theme.fontSize)
        drawEllipsized(node.title, layout: layout, size: theme.fontSize, in: textRect(row: row, in: rect),
                       color: dragged ? color.withAlpha(0.45) : color, list: list)
    }

    private func textRect(row: Int, in rect: UIRect) -> UIRect {
        let disclosure = disclosureRect(row: row, in: rect)
        return UIRect(x: disclosure.maxX + 2, y: rect.y, width: rect.maxX - disclosure.maxX - 2, height: rect.height)
    }

    /// The node's full title while its row cuts it off (not while it is being renamed).
    public override func rowTooltip(_ row: Int, in rect: UIRect) -> String? {
        let node = rows[row].node
        guard node !== renamingNode else { return nil }
        return truncatedText(node.title, size: theme.fontSize, width: textRect(row: row, in: rect).width)
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        if drag != nil { tickDrag() }
        super.drawForeground(list, theme: theme)
        guard let state = drag else { return }
        list.withClip(contentRect) {
            if let target = state.target { drawDropIndicator(target, list: list, theme: theme) }
            drawDragGhost(state, list: list, theme: theme)
        }
    }

    private func drawDropIndicator(_ target: TreeDropTarget, list: UIDrawList, theme: UITheme) {
        let viewport = contentRect
        let h = effectiveRowHeight
        let accent = theme.accent
        func rowTop(_ row: Int) -> Float { snap(viewport.y + Float(row) * h - scroll.offset) }
        if target.position == .into, let row = target.row {
            let rect = UIRect(x: viewport.x, y: rowTop(row), width: viewport.width, height: h)
            list.fillRect(rect, color: accent.withAlpha(0.22), radii: UICornerRadii(3))
            list.strokeRect(rect, color: accent, width: 1.5, radii: UICornerRadii(3))
            return
        }
        let y: Float, depth: Int
        switch (target.position, target.row) {
        case (.before, let row?):
            y = rowTop(row)
            depth = rows[row].depth
        case (.after, let row?):
            y = rowTop(row) + h
            depth = rows[row].depth + (target.parent === rows[row].node ? 1 : 0)
        default:
            y = snap(viewport.y + Float(rows.count) * h - scroll.offset)
            depth = 0
        }
        let x = viewport.x + 4 + Float(depth) * theme.treeIndent
        list.fillRect(UIRect(x: x, y: y - 1, width: max(0, viewport.maxX - x - 2), height: 2), color: accent)
        list.fillRect(UIRect(x: x - 3, y: y - 3, width: 6, height: 6), color: accent, radii: UICornerRadii(3))
    }

    private func drawDragGhost(_ state: Drag, list: UIDrawList, theme: UITheme) {
        guard let context, let first = state.nodes.first else { return }
        let text = state.nodes.count > 1 ? "\(first.title) +\(state.nodes.count - 1)" : first.title
        let layout = cachedLayout(text, size: theme.fontSize)
        let size = Vec2((layout.width * scale).rounded(.up) / scale + 16, theme.rowHeight)
        let origin = context.pointerPosition + Vec2(12, 10)
        let rect = UIRect(x: origin.x, y: origin.y, width: size.x, height: size.y)
        list.fillRect(rect, color: theme.popupBackground.withAlpha(0.92), radii: UICornerRadii(4))
        list.strokeRect(rect, color: theme.accent.withAlpha(0.8), width: 1, radii: UICornerRadii(4))
        drawLine(layout, font: theme.font, in: UIRect(x: rect.x + 8, y: rect.y, width: rect.width - 16, height: rect.height),
                 color: theme.textColor, list: list)
    }

    /// Like the base, but the rename field is painted after the rows (which are drawn above
    /// children) so it covers its row.
    override func paint(_ list: UIDrawList, theme: UITheme) {
        guard renamingNode != nil, let field = renameField else {
            super.paint(list, theme: theme)
            return
        }
        guard !isHidden, let clip = list.clipBounds else { return }
        let slack: Float = 4
        let bounds = UIRect(x: frame.x - slack, y: frame.y - slack, width: frame.width + 2 * slack,
                            height: frame.height + 2 * slack)
        guard bounds.intersects(clip) else { return }
        draw(list, theme: theme)
        drawForeground(list, theme: theme)
        layoutRenameField()
        list.withClip(contentRect) { field.paint(list, theme: theme) }
    }
}
