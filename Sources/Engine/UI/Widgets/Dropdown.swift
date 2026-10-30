import Foundation

/// A list of choices shown as an overlay (above every other widget), anchored below a widget
/// (above it when there is no room). Hover or Up/Down highlight, click or Enter picks, a press
/// outside or Esc closes it. Used by `Dropdown`; usable alone as a context menu
/// (`UIContext.presentOverlay`).
public final class PopupMenu: Widget {
    public var items: [String] { didSet { setNeedsLayout() } }
    public var highlightedIndex: Int? { didSet { setNeedsDisplay() } }
    /// The item that gets a check mark.
    public var checkedIndex: Int?
    /// The widget the menu hangs from (its frame is re-read on every layout, so it follows scrolling).
    public weak var anchor: Widget?
    /// The rectangle to hang from when there is no anchor widget (window points).
    public var anchorRect: UIRect?
    public var onSelect: ((Int) -> Void)?
    /// Called when the menu closes for any reason.
    public var onDismiss: (() -> Void)?

    public init(items: [String], anchor: Widget? = nil, name: String = "menu") {
        self.items = items
        self.anchor = anchor
        super.init(name: name)
        padding = EdgeInsets(4)
    }

    private var rowHeight: Float { theme.rowHeight + 2 }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        var widest: Float = 0
        for item in items { widest = max(widest, cachedLayout(item, size: theme.fontSize).width) }
        return Vec2((widest * scale).rounded(.up) / scale + 2 * theme.controlPaddingX + 16, rowHeight * Float(items.count))
    }

    public override func overlayFrame(in viewport: UIRect) -> UIRect {
        let size = measure()
        let anchor = self.anchor?.frame ?? anchorRect ?? UIRect(x: viewport.center.x, y: viewport.center.y, width: 0, height: 0)
        let width = max(size.x, anchor.width)
        var y = anchor.maxY + 2
        if y + size.y > viewport.maxY, anchor.y - 2 - size.y >= viewport.y { y = anchor.y - 2 - size.y }
        let x = min(max(anchor.x, viewport.x), max(viewport.x, viewport.maxX - width))
        return UIRect(x: x, y: y, width: width, height: size.y)
    }

    public override func overlayDismissed() { onDismiss?() }

    /// The item under a window point.
    public func item(at point: Vec2) -> Int? {
        let content = contentRect
        guard content.contains(point) else { return nil }
        let index = Int(((point.y - content.y) / rowHeight).rounded(.down))
        return index >= 0 && index < items.count ? index : nil
    }

    /// Picks `index`: closes the menu and calls `onSelect`.
    public func choose(_ index: Int) {
        guard items.indices.contains(index) else { return }
        let select = onSelect
        context?.dismissOverlay(self)
        select?(index)
    }

    /// Moves the highlight by `step` (wrapping).
    public func moveHighlight(by step: Int) {
        guard !items.isEmpty else { return }
        let current = highlightedIndex ?? (step > 0 ? -1 : items.count)
        highlightedIndex = ((current + step) % items.count + items.count) % items.count
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerMove(let e), .pointerDrag(let e):
            if let index = item(at: e.position) { highlightedIndex = index }
            return true
        case .pointerDown:
            return true
        case .pointerUp(let e):
            if let index = item(at: e.position) { choose(index) }
            return true
        case .scroll:
            return true
        case .key(let e):
            switch e.key {
            case .up: moveHighlight(by: -1)
            case .down: moveHighlight(by: 1)
            case .home: highlightedIndex = items.isEmpty ? nil : 0
            case .end: highlightedIndex = items.isEmpty ? nil : items.count - 1
            case .enter, .space: if let index = highlightedIndex { choose(index) }
            case .escape: context?.dismissOverlay(self)
            default: return false
            }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.cornerRadius + 1)
        // A soft drop shadow from a few stacked translucent rects.
        for i in 1...3 {
            let grow = Float(i) * 2
            list.fillRect(UIRect(x: frame.x - grow / 2, y: frame.y + grow, width: frame.width + grow, height: frame.height),
                          color: theme.shadow.withAlpha(theme.shadow.a / 3), radii: UICornerRadii(theme.cornerRadius + grow))
        }
        list.fillRect(frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(frame, color: theme.popupBorder, width: 1, radii: radii)
        let content = contentRect
        for (i, item) in items.enumerated() {
            let row = UIRect(x: content.x, y: content.y + Float(i) * rowHeight, width: content.width, height: rowHeight)
            let highlighted = i == highlightedIndex
            if highlighted { list.fillRect(row, color: theme.accent, radii: UICornerRadii(theme.cornerRadius - 1)) }
            if i == checkedIndex {
                let c = Vec2(row.x + 9, row.center.y)
                let color = highlighted ? theme.accentText : theme.textColor
                list.drawLine(from: c + Vec2(-3.5, 0), to: c + Vec2(-1, 2.5), width: 1.5, color: color, cap: .round)
                list.drawLine(from: c + Vec2(-1, 2.5), to: c + Vec2(4, -3), width: 1.5, color: color, cap: .round)
            }
            let layout = cachedLayout(item, size: theme.fontSize)
            let textRect = UIRect(x: row.x + 18, y: row.y, width: row.width - 18, height: row.height)
            drawLine(layout, font: theme.font, in: textRect, color: highlighted ? theme.accentText : theme.textColor, list: list)
        }
    }
}

/// A button showing the selected option; it opens a `PopupMenu` of all options. Click, Space,
/// Enter or Down opens it; while open Up/Down move, Enter/Space pick, Esc closes.
public final class Dropdown: Widget {
    public var options: [String] { didSet { setNeedsLayout() } }
    public private(set) var selectedIndex: Int
    /// Called when the user picks an option.
    public var onChange: ((Int) -> Void)?
    public private(set) var menu: PopupMenu?
    private var cache = CachedTextLayout()

    public init(options: [String], selectedIndex: Int = 0, name: String = "", onChange: ((Int) -> Void)? = nil) {
        self.options = options
        self.selectedIndex = min(max(selectedIndex, 0), max(options.count - 1, 0))
        self.onChange = onChange
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }
    public var isOpen: Bool { menu != nil }

    public var selectedOption: String? { options.indices.contains(selectedIndex) ? options[selectedIndex] : nil }

    /// Selects an option in code (no `onChange`).
    public func select(_ index: Int) {
        guard options.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        setNeedsDisplay()
    }

    public func open() {
        guard let context, menu == nil, !options.isEmpty else { return }
        let menu = PopupMenu(items: options, anchor: self)
        menu.highlightedIndex = selectedIndex
        menu.checkedIndex = selectedIndex
        menu.onSelect = { [weak self] index in
            guard let self else { return }
            let changed = index != self.selectedIndex
            self.select(index)
            if changed { self.onChange?(index) }
        }
        menu.onDismiss = { [weak self] in self?.menu = nil; self?.setNeedsDisplay() }
        self.menu = menu
        context.presentOverlay(menu)
    }

    public func close() {
        if let menu { context?.dismissOverlay(menu) }
    }

    public override func focusChanged(_ focused: Bool) {
        if !focused { close() }
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        var widest: Float = 0
        for option in options { widest = max(widest, cachedLayout(option, size: theme.fontSize).width) }
        return Vec2((widest * scale).rounded(.up) / scale + 2 * theme.controlPaddingX + 18, theme.controlHeight)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            if isOpen { close() } else { open() }
            return true
        case .pointerUp, .pointerDrag:
            return true
        case .key(let e):
            if let menu {
                if e.key == .tab { close(); return false }
                return menu.handleEvent(event)
            }
            switch e.key {
            case .space, .enter, .down: open()
            case .up: open()
            default: return false
            }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let fill = !enabled ? theme.controlBackground.withAlpha(0.5)
            : (isPressed || isOpen) ? theme.controlPressed : isHovered ? theme.controlHover : theme.controlBackground
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: fill, radii: radii)
        list.strokeRect(frame, color: isOpen ? theme.accent : theme.controlBorder, width: 1, radii: radii)
        let color = enabled ? theme.textColor : theme.disabledTextColor
        if let option = selectedOption {
            let layout = cache.get(option, font: theme.font, size: theme.fontSize)
            let textRect = UIRect(x: frame.x + theme.controlPaddingX, y: frame.y, width: frame.width - 2 * theme.controlPaddingX - 14,
                                  height: frame.height)
            drawLine(layout, font: theme.font, in: textRect, color: color, list: list)
        }
        // Chevron.
        let c = Vec2(frame.maxX - theme.controlPaddingX - 4, frame.center.y)
        let s: Float = 3.5
        let dy: Float = isOpen ? -1 : 1
        list.drawLine(from: c + Vec2(-s, -s / 2 * dy), to: c + Vec2(0, s / 2 * dy), width: 1.5, color: theme.secondaryTextColor,
                      cap: .round)
        list.drawLine(from: c + Vec2(0, s / 2 * dy), to: c + Vec2(s, -s / 2 * dy), width: 1.5, color: theme.secondaryTextColor,
                      cap: .round)
    }
}
