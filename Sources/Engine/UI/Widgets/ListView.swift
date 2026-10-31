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

    open override var accessibilityRole: UIAccessibilityRole { .list }
    /// A row's label for `accessibilityItems`; nil leaves the row out (the default).
    open func rowAccessibilityLabel(_ row: Int) -> String? { nil }
    /// A row's value for `accessibilityItems` ("expanded").
    open func rowAccessibilityValue(_ row: Int) -> String? { nil }
    open var rowAccessibilityRole: UIAccessibilityRole { .listItem }

    /// One "row:<label>" item per row (scrolled-out rows too, with their would-be frames).
    open override var accessibilityItems: [UIAccessibilityItem] {
        (0..<rowCount).compactMap { row in
            guard let label = rowAccessibilityLabel(row) else { return nil }
            return UIAccessibilityItem(key: "row:\(label)", role: rowAccessibilityRole, label: label,
                                       value: rowAccessibilityValue(row), frame: rowRect(row), isSelected: isRowSelected(row),
                                       tooltip: rowTooltip(row, in: rowRect(row)))
        }
    }

    /// Draws row `row` into `rect` (the selection and hover backgrounds are already drawn).
    open func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {}

    /// Double click or Enter on a row.
    open func rowActivated(_ row: Int) {}

    /// The selection changed (by the user or `selectRow`).
    open func selectionChanged() {}

    /// A press on a row; return true to stop the default (select, and activate on double click).
    open func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool { false }

    /// The tooltip for `row` (laid out in `rect`) when the pointer rests on it; by default none.
    /// Lists and trees return a row's full text while it is cut off.
    open func rowTooltip(_ row: Int, in rect: UIRect) -> String? { nil }

    /// Keys beyond the shared navigation (tree expand/collapse).
    open func handleRowKey(_ key: KeyEvent) -> Bool { false }

    /// Whether `row` gets the selection background (the selected row by default; a tree with
    /// several selected rows says yes to all of them).
    open func isRowSelected(_ row: Int) -> Bool { row == selectedRow }

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

    /// Where `row` is drawn (window points), whether or not it is visible.
    public func rowRect(_ row: Int) -> UIRect {
        let viewport = contentRect
        return UIRect(x: viewport.x, y: snap(viewport.y + Float(row) * effectiveRowHeight - scroll.offset), width: viewport.width,
                      height: effectiveRowHeight)
    }

    public override func tooltip(at point: Vec2) -> String? {
        if let tooltip { return tooltip }
        guard let row = row(at: point) else { return nil }
        return rowTooltip(row, in: rowRect(row))
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
        list.strokeRect(frame, color: isFocused ? theme.accent.withAlpha(0.8) : theme.controlBorder, width: theme.borderWidth, radii: radii)
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        updateScrollLengths()
        let viewport = contentRect
        let h = effectiveRowHeight
        let hoveredRow = isHovered ? context.flatMap { row(at: $0.pointerPosition) } : nil
        list.withClip(viewport) {
            for row in visibleRows {
                let rect = rowRect(row)
                let selected = isRowSelected(row)
                if selected {
                    list.fillRect(rect, color: isFocused ? theme.rowSelectedFocused : theme.rowSelected, radii: UICornerRadii(theme.rowCornerRadius))
                } else if row == hoveredRow {
                    list.fillRect(rect, color: theme.rowHover, radii: UICornerRadii(theme.rowCornerRadius))
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
    public override func rowAccessibilityLabel(_ row: Int) -> String? { items[row] }

    public override func selectionChanged() { onSelect?(selectedRow) }
    public override func rowActivated(_ row: Int) { onActivate?(row) }

    public override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let layout = cachedLayout(items[row], size: theme.fontSize)
        drawEllipsized(items[row], layout: layout, size: theme.fontSize, in: textRect(in: rect),
                       color: isEffectivelyEnabled ? theme.textColor : theme.disabledTextColor, list: list)
    }

    private func textRect(in rect: UIRect) -> UIRect {
        UIRect(x: rect.x + 8, y: rect.y, width: rect.width - 16, height: rect.height)
    }

    public override func rowTooltip(_ row: Int, in rect: UIRect) -> String? {
        truncatedText(items[row], size: theme.fontSize, width: textRect(in: rect).width)
    }
}
