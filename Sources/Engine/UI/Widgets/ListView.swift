import Foundation

/// Base of `ListView` and `TreeView`: fixed-height rows with a single selection, scrolled
/// internally and virtualized (only rows inside the viewport are drawn, so a list of 100k
/// rows costs the same as one of 20). Click selects, double-click activates; when focused,
/// Up/Down, Page Up/Down and Home/End move the selection and Enter activates.
open class RowListView: Widget {
    /// Row height in points; nil uses the theme's.
    public var rowHeight: Float? { didSet { setNeedsLayout() } }
    /// Rows shown when measured without a fixed height.
    public var preferredVisibleRows = 8 { didSet { setNeedsLayout() } }
    public private(set) var selectedRow: Int?
    public private(set) var scroll = ScrollState()
    private var interaction = ScrollbarInteraction()

    public override init(name: String = "") {
        super.init(name: name)
        clipsContent = true
        padding = EdgeInsets(2)
    }

    /// Number of rows; subclasses provide it.
    open var rowCount: Int { 0 }

    /// Draws row `row` into `rect` (the selection and hover backgrounds are already drawn).
    open func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {}

    /// Double click or Enter on a row.
    open func rowActivated(_ row: Int) {}

    /// The selection changed (by the user or `selectRow`).
    open func selectionChanged() {}

    /// A press on a row; return true to stop the default (select, and activate on double click).
    open func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool { false }

    /// Keys beyond the shared navigation (tree expand/collapse).
    open func handleRowKey(_ key: KeyEvent) -> Bool { false }

    public override var acceptsFocus: Bool { true }

    public var effectiveRowHeight: Float { rowHeight ?? theme.rowHeight }

    /// Selects `row` (nil clears; clamped) and scrolls it into view.
    public func selectRow(_ row: Int?, reveal: Bool = true) {
        let clamped = row.map { min(max($0, 0), rowCount - 1) }.flatMap { $0 >= 0 ? $0 : nil }
        if reveal, let clamped { revealRow(clamped) }
        guard clamped != selectedRow else { return }
        selectedRow = clamped
        setNeedsDisplay()
        selectionChanged()
    }

    /// Scrolls so `row` is fully visible.
    public func revealRow(_ row: Int) {
        updateScrollLengths()
        let h = effectiveRowHeight
        if scroll.reveal(Float(row) * h, Float(row + 1) * h) { setNeedsDisplay() }
    }

    public func scroll(to offset: Float) {
        updateScrollLengths()
        if scroll.scroll(to: offset) { setNeedsDisplay() }
    }

    /// The row under a window point, if any.
    public func row(at point: Vec2) -> Int? {
        let viewport = contentRect
        guard viewport.contains(point) else { return nil }
        let row = Int(((point.y - viewport.y + scroll.offset) / effectiveRowHeight).rounded(.down))
        return row >= 0 && row < rowCount ? row : nil
    }

    /// Rows intersecting the viewport.
    public var visibleRows: Range<Int> {
        let h = effectiveRowHeight
        let viewport = contentRect
        guard h > 0, rowCount > 0 else { return 0..<0 }
        let first = max(0, Int((scroll.offset / h).rounded(.down)))
        let last = min(rowCount, Int(((scroll.offset + viewport.height) / h).rounded(.up)))
        return first..<max(first, last)
    }

    func updateScrollLengths() {
        scroll.setLengths(content: Float(rowCount) * effectiveRowHeight, viewport: contentRect.height)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(180, effectiveRowHeight * Float(preferredVisibleRows))
    }

    public override func layoutChildren() {
        updateScrollLengths()
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        updateScrollLengths()
        let result = interaction.handle(event, state: &scroll, viewport: contentRect, theme: theme, dragContent: false)
        if result.changed { setNeedsDisplay() }
        if result.handled { return true }
        switch event {
        case .pointerDown(let e) where e.button == .left:
            if let row = row(at: e.position) {
                if !rowPressed(row, at: e.position, event: e) {
                    selectRow(row)
                    if e.clickCount == 2 { rowActivated(row) }
                }
            }
            return true
        case .pointerDrag, .pointerUp:
            return true
        case .key(let e):
            if handleRowKey(e) { return true }
            let page = max(1, Int(contentRect.height / effectiveRowHeight) - 1)
            let current = selectedRow
            switch e.key {
            case .up: selectRow(current.map { $0 - 1 } ?? rowCount - 1)
            case .down: selectRow(current.map { $0 + 1 } ?? 0)
            case .pageUp: selectRow((current ?? 0) - page)
            case .pageDown: selectRow((current ?? 0) + page)
            case .home: selectRow(0)
            case .end: selectRow(rowCount - 1)
            case .enter, .space:
                guard let current else { return false }
                rowActivated(current)
            default: return false
            }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: theme.fieldBackground, radii: radii)
        list.strokeRect(frame, color: isFocused ? theme.accent.withAlpha(0.8) : theme.controlBorder, width: 1, radii: radii)
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        updateScrollLengths()
        let viewport = contentRect
        let h = effectiveRowHeight
        let hoveredRow = isHovered ? context.flatMap { row(at: $0.pointerPosition) } : nil
        list.withClip(viewport) {
            for row in visibleRows {
                let rect = UIRect(x: viewport.x, y: snap(viewport.y + Float(row) * h - scroll.offset), width: viewport.width,
                                  height: h)
                let selected = row == selectedRow
                if selected {
                    list.fillRect(rect, color: isFocused ? theme.rowSelectedFocused : theme.rowSelected, radii: UICornerRadii(3))
                } else if row == hoveredRow {
                    list.fillRect(rect, color: theme.rowHover, radii: UICornerRadii(3))
                }
                drawRow(row, in: rect, list: list, theme: theme, selected: selected)
            }
            let hoverBar = context.map { ScrollbarInteraction.hitArea(for: viewport, theme: theme).contains($0.pointerPosition) } ?? false
            interaction.draw(list, state: scroll, viewport: viewport, theme: theme, hovered: hoverBar)
        }
    }
}

/// A scrolling list of text rows with one selection.
public final class ListView: RowListView {
    public var items: [String] {
        didSet {
            if let selected = selectedRow, selected >= items.count { selectRow(items.isEmpty ? nil : items.count - 1) }
            setNeedsLayout()
        }
    }
    /// Called when the selection changes.
    public var onSelect: ((Int?) -> Void)?
    /// Called on double click / Enter.
    public var onActivate: ((Int) -> Void)?

    public init(items: [String], name: String = "") {
        self.items = items
        super.init(name: name)
    }

    public override var rowCount: Int { items.count }

    public override func selectionChanged() { onSelect?(selectedRow) }
    public override func rowActivated(_ row: Int) { onActivate?(row) }

    public override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let layout = cachedLayout(items[row], size: theme.fontSize)
        let textRect = UIRect(x: rect.x + 8, y: rect.y, width: rect.width - 16, height: rect.height)
        drawLine(layout, font: theme.font, in: textRect, color: isEffectivelyEnabled ? theme.textColor : theme.disabledTextColor,
                 list: list)
    }
}

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

    public func removeAllChildren() {
        for child in children { child.parent = nil }
        children.removeAll()
    }

    public var hasChildren: Bool { !children.isEmpty }
    public var depth: Int { parent.map { $0.depth + 1 } ?? 0 }
}

/// An expandable tree of `TreeNode` rows (the editor's hierarchy panel). Click the disclosure
/// triangle (or double-click, Enter, Space) to expand/collapse. Keys: Up/Down move, Right
/// expands or steps into the first child, Left collapses or steps to the parent.
/// Call `reloadData()` after changing nodes from outside.
public final class TreeView: RowListView {
    public var roots: [TreeNode] { didSet { reloadData() } }
    /// Called when the selected node changes.
    public var onSelect: ((TreeNode?) -> Void)?
    /// Called on double click / Enter on a leaf.
    public var onActivate: ((TreeNode) -> Void)?
    private var rows: [(node: TreeNode, depth: Int)] = []

    public init(roots: [TreeNode], name: String = "") {
        self.roots = roots
        super.init(name: name)
        rebuildRows()
    }

    public override var rowCount: Int { rows.count }

    /// Rows currently visible (expanded ancestors), in order.
    public var visibleNodes: [TreeNode] { rows.map(\.node) }

    public var selectedNode: TreeNode? { selectedRow.map { rows[$0].node } }

    /// Re-reads the nodes (keeps the selected node selected if it's still visible).
    public func reloadData() {
        let selected = selectedNode
        rebuildRows()
        selectRow(selected.flatMap { node in rows.firstIndex { $0.node === node } }, reveal: false)
        setNeedsLayout()
    }

    public func select(_ node: TreeNode?) {
        guard let node else { selectRow(nil); return }
        var ancestor = node.parent
        var changed = false
        while let a = ancestor {
            if !a.isExpanded { a.isExpanded = true; changed = true }
            ancestor = a.parent
        }
        if changed { reloadData() }
        selectRow(rows.firstIndex { $0.node === node })
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

    public override func selectionChanged() { onSelect?(selectedNode) }

    public override func rowActivated(_ row: Int) {
        let node = rows[row].node
        if node.hasChildren { toggle(node) } else { onActivate?(node) }
    }

    private func disclosureRect(row: Int, in rect: UIRect) -> UIRect {
        let indent = theme.treeIndent
        return UIRect(x: rect.x + 4 + Float(rows[row].depth) * indent, y: rect.y, width: indent, height: rect.height)
    }

    public override func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool {
        let viewport = contentRect
        let h = effectiveRowHeight
        let rect = UIRect(x: viewport.x, y: viewport.y + Float(row) * h - scroll.offset, width: viewport.width, height: h)
        guard rows[row].node.hasChildren, disclosureRect(row: row, in: rect).contains(position) else { return false }
        selectRow(row)
        toggle(rows[row].node)
        return true
    }

    public override func handleRowKey(_ key: KeyEvent) -> Bool {
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
        let layout = cachedLayout(node.title, size: theme.fontSize)
        let textRect = UIRect(x: disclosure.maxX + 2, y: rect.y, width: rect.maxX - disclosure.maxX - 2, height: rect.height)
        drawLine(layout, font: theme.font, in: textRect, color: color, list: list)
    }
}
