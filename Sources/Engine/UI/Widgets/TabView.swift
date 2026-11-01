import Foundation

/// A titled piece of UI shown as a tab: in a `TabView`, or in a `DockSpace`, which moves it
/// between tab groups, splits and floating windows. `id` is what layouts are saved with, so
/// keep it stable across runs ("hierarchy", "inspector").
@MainActor
public final class DockPanel {
    public let id: String
    public var title: String { didSet { if title != oldValue { owner?.setNeedsLayout() } } }
    public let content: Widget
    /// Shows a close button on the tab (and allows a middle click to close it).
    public var isClosable: Bool { didSet { owner?.setNeedsDisplay() } }
    /// The smallest size the panel's area gets in a dock split (points, tab bar excluded).
    public var minSize: Vec2
    /// Clicks on parts of the content that no widget takes go to the game instead of the UI
    /// (a scene viewport the game draws and orbits in).
    public var passesPointerThrough = false
    /// Whether the tab view fills the content area with the panel background before the content
    /// draws. Turn it off for a viewport whose pixels come from behind the UI.
    public var drawsBackground = true
    /// Shown when hovering the tab's title; the full title appears instead when the tab cuts it off.
    public var tooltip: String?
    /// An icon before the tab's title.
    public var icon: VectorIcon? { didSet { if icon != oldValue { owner?.setNeedsLayout() } } }
    /// A short status shown at the right end of the tab bar while this panel is selected
    /// ("Perspective · Move"), in small secondary text, when the bar has room for it; never over
    /// the content.
    public var caption: String? { didSet { if caption != oldValue { owner?.setNeedsDisplay() } } }
    /// Called after the user closes the panel (close button, middle click, `DockSpace.closePanel`).
    public var onClose: (() -> Void)?
    /// The tab view currently showing it.
    public internal(set) weak var owner: TabView?

    public init(id: String, title: String, content: Widget, isClosable: Bool = true, minSize: Vec2 = Vec2(120, 80)) {
        self.id = id
        self.title = title
        self.content = content
        self.isClosable = isClosable
        self.minSize = minSize
    }
}

/// Tabs across the top of a panel: one `DockPanel`'s content shows at a time, below a bar of
/// titles.
///
/// - Click a tab to show it; drag it along the bar to reorder (in a `DockSpace`, dragging it off
///   the bar docks it elsewhere instead, see there). Close buttons appear on the selected and
///   the hovered tab of closable panels; a middle click closes too.
/// - When the titles don't fit, tabs shrink down to `minTabWidth` (titles are clipped), then the
///   bar scrolls: the wheel over it scrolls sideways, and the selected tab is kept in view.
/// - Keyboard, while the tab view or anything inside it has focus: Ctrl-Tab / Ctrl-Shift-Tab and
///   Ctrl-Page Down / Ctrl-Page Up select the next / previous tab (wrapping); Left / Right do the
///   same when the tab bar itself is focused (click a tab, or Tab to it). Esc cancels a tab drag.
public final class TabView: Widget {
    public private(set) var tabs: [DockPanel] = []
    /// The tab shown, nil when there are none.
    public private(set) var selectedIndex: Int?
    public var tabBarHeight: Float = 28 { didSet { if tabBarHeight != oldValue { setNeedsLayout() } } }
    public var minTabWidth: Float = 64 { didSet { setNeedsLayout() } }
    public var maxTabWidth: Float = 220 { didSet { setNeedsLayout() } }
    /// Called when the user selects another tab.
    public var onSelect: ((Int) -> Void)?
    /// Called after the user reordered the tabs by dragging.
    public var onReorder: (([DockPanel]) -> Void)?
    /// Called after a tab was closed by the user (outside a dock space; there the dock reports it).
    public var onClose: ((DockPanel) -> Void)?
    /// How far the tab strip is scrolled when the tabs overflow the bar (points).
    public private(set) var barOffset: Float = 0
    /// How much taller the selected panel's content is than the content area (0 when it fits): a
    /// wrapped toolbar in a short panel. The content then scrolls with the wheel by `contentOffset`.
    public private(set) var contentOverflow: Float = 0
    /// How far the overflowing content is scrolled up (0...`contentOverflow`).
    public private(set) var contentOffset: Float = 0

    /// Set by the dock space that owns this tab group.
    weak var dock: DockSpace?

    private enum DragPhase { case pressed, reordering, docking }
    private var drag: (panel: DockPanel, start: Vec2, grab: Float, phase: DragPhase)?
    private var pressedClose: DockPanel?
    /// Laid-out tab widths (before scrolling), from the last layout.
    private var tabWidths: [Float] = []
    private var revealSelection = true

    public init(tabs: [DockPanel] = [], selectedIndex: Int = 0, name: String = "") {
        super.init(name: name)
        // A panel's content never paints over its neighbors when it is wider than the panel.
        clipsContent = true
        for tab in tabs { addTab(tab, select: false) }
        if !self.tabs.isEmpty { self.selectedIndex = min(max(selectedIndex, 0), self.tabs.count - 1) }
        updateVisibility()
    }

    public override var acceptsFocus: Bool { !tabs.isEmpty }
    public override var showsFocusRing: Bool { false }

    public override var accessibilityRole: UIAccessibilityRole { .tabGroup }
    public override var accessibilityValue: String? { selectedTab?.title }

    /// A "tab:<id>" item per tab, and "close:<id>" for its close button.
    public override var accessibilityItems: [UIAccessibilityItem] {
        let rects = tabRects
        var items: [UIAccessibilityItem] = []
        for (index, tab) in tabs.enumerated() where index < rects.count {
            items.append(UIAccessibilityItem(key: "tab:\(tab.id)", role: .tab, label: tab.title, frame: rects[index],
                                             isSelected: index == selectedIndex, tooltip: tab.tooltip))
            if let close = closeButtonRect(index) {
                items.append(UIAccessibilityItem(key: "close:\(tab.id)", role: .button, label: "Close \(tab.title)", frame: close))
            }
        }
        return items
    }

    public var selectedTab: DockPanel? { selectedIndex.map { tabs[$0] } }

    public func index(of id: String) -> Int? { tabs.firstIndex { $0.id == id } }

    // MARK: Tabs

    /// Shows tab `index` (no `onSelect`).
    public func select(_ index: Int) {
        guard tabs.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        revealSelection = true
        updateVisibility()
        setNeedsLayout()
    }

    private func userSelect(_ index: Int) {
        guard index != selectedIndex else { return }
        select(index)
        onSelect?(index)
    }

    /// Adds `panel` at `index` (the end by default), optionally selecting it.
    public func addTab(_ panel: DockPanel, at index: Int? = nil, select shouldSelect: Bool = true) {
        if let owner = panel.owner, let i = owner.tabs.firstIndex(where: { $0 === panel }) { owner.removeTab(at: i) }
        let index = min(max(index ?? tabs.count, 0), tabs.count)
        tabs.insert(panel, at: index)
        panel.owner = self
        if let selected = selectedIndex, index <= selected { selectedIndex = selected + 1 }
        if selectedIndex == nil { selectedIndex = index }
        addChild(panel.content)
        if shouldSelect { select(index) }
        updateVisibility()
        setNeedsLayout()
    }

    /// Removes the tab at `index` and returns it. The tab after it (or else before it) is selected.
    @discardableResult
    public func removeTab(at index: Int) -> DockPanel? {
        guard tabs.indices.contains(index) else { return nil }
        let panel = tabs.remove(at: index)
        if drag?.panel === panel { drag = nil }
        panel.owner = nil
        panel.content.removeFromParent()
        if let selected = selectedIndex {
            if tabs.isEmpty {
                selectedIndex = nil
            } else if index < selected || (index == selected && selected == tabs.count) {
                selectedIndex = selected - 1
            }
        }
        revealSelection = true
        updateVisibility()
        setNeedsLayout()
        return panel
    }

    /// Moves a tab within the bar (the selection follows the moved tabs).
    public func moveTab(from source: Int, to destination: Int) {
        guard tabs.indices.contains(source) else { return }
        let destination = min(max(destination, 0), tabs.count - 1)
        guard destination != source else { return }
        let selected = selectedTab
        tabs.insert(tabs.remove(at: source), at: destination)
        selectedIndex = selected.flatMap { s in tabs.firstIndex { $0 === s } }
        setNeedsLayout()
    }

    /// Closes the tab at `index` as the user would: in a dock space through the dock (which may
    /// collapse the group), otherwise removes it and calls `onClose` and the panel's `onClose`.
    public func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        if let dock {
            dock.closePanel(tabs[index].id)
            return
        }
        guard let panel = removeTab(at: index) else { return }
        onClose?(panel)
        panel.onClose?()
    }

    /// Selects the next (or previous) tab, wrapping.
    public func selectNext(_ forward: Bool = true) {
        guard let selected = selectedIndex, tabs.count > 1 else { return }
        userSelect((selected + (forward ? 1 : tabs.count - 1)) % tabs.count)
    }

    private func updateVisibility() {
        for (i, tab) in tabs.enumerated() { tab.content.isHidden = i != selectedIndex }
    }

    // MARK: Geometry

    /// The strip of tabs along the top.
    public var barRect: UIRect { UIRect(x: frame.x, y: frame.y, width: frame.width, height: min(tabBarHeight, frame.height)) }
    /// Where the selected panel's content goes.
    public var contentArea: UIRect {
        let bar = min(tabBarHeight, frame.height)
        return UIRect(x: frame.x, y: frame.y + bar, width: frame.width, height: frame.height - bar)
    }

    /// Each tab's rectangle in window points (scrolled; parts may lie outside the bar), from the last layout.
    public var tabRects: [UIRect] {
        let bar = barRect
        var x = bar.x - barOffset
        var rects: [UIRect] = []
        for width in tabWidths.prefix(tabs.count) {
            rects.append(UIRect(x: snap(x), y: bar.y, width: snap(x + width) - snap(x), height: bar.height))
            x += width
        }
        return rects
    }

    /// The tab under `point` (inside the bar).
    public func tab(at point: Vec2) -> Int? {
        guard barRect.contains(point) else { return nil }
        return tabRects.firstIndex { $0.contains(point) }
    }

    /// The close button of tab `index`: where it takes clicks, at least the theme's
    /// `minimumHitSize` (as far as the tab's height allows) around its 16-point glyph.
    public func closeButtonRect(_ index: Int) -> UIRect? {
        guard let glyph = closeGlyphRect(index) else { return nil }
        let r = tabRects[index]
        let s = max(glyph.width, min(theme.minimumHitSize, r.height))
        return UIRect(x: snap(glyph.center.x - s / 2), y: snap(r.y + (r.height - s) / 2), width: s, height: s)
    }

    /// The 16-point square the close cross is drawn in.
    private func closeGlyphRect(_ index: Int) -> UIRect? {
        guard tabs.indices.contains(index), tabs[index].isClosable, index < tabWidths.count else { return nil }
        let r = tabRects[index]
        let s: Float = 16
        return UIRect(x: r.maxX - s - 6, y: snap(r.y + (r.height - s) / 2), width: s, height: s)
    }

    /// Where a tab dropped at `x` would be inserted (0...tabs.count), comparing with tab centers.
    /// `excluding` leaves one tab out (the one being dragged within this bar).
    public func insertionIndex(at x: Float, excluding: DockPanel? = nil) -> Int {
        var index = 0
        for (i, rect) in tabRects.enumerated() where tabs[i] !== excluding && rect.center.x < x { index += 1 }
        return index
    }

    private func naturalWidth(_ panel: DockPanel, theme: UITheme) -> Float {
        let text = (cachedLayout(panel.title, size: theme.fontSize).width * scale).rounded(.up) / scale
        return min(max(text + 2 * theme.controlPaddingX + (panel.isClosable ? 20 : 0) + iconSpace(panel, theme: theme), minTabWidth),
                   maxTabWidth)
    }

    /// A tab icon's edge (a little under the theme's, to sit in the bar).
    private func iconEdge(_ theme: UITheme) -> Float { theme.iconSize - 2 }

    /// Room an icon takes before the title (icon and gap), 0 without one.
    private func iconSpace(_ panel: DockPanel, theme: UITheme) -> Float {
        panel.icon == nil ? 0 : iconEdge(theme) + 6
    }

    // MARK: Layout

    public override func measureContent(width: Float?) -> Vec2 {
        var size = Vec2.zero
        for tab in tabs { size = pointwiseMax(size, tab.content.measure(width: width)) }
        return Vec2(size.x, size.y + tabBarHeight)
    }

    public override func layoutChildren() {
        let theme = theme
        let bar = barRect
        let natural = tabs.map { naturalWidth($0, theme: theme) }
        // Shrink towards the minimum width first, then scroll.
        tabWidths = UILayout.distribute(natural.map { UILayout.FlexItem(base: $0, min: min(minTabWidth, $0), shrink: 1) },
                                        available: bar.width)
        let strip = tabWidths.reduce(0, +)
        var offset = min(max(barOffset, 0), max(0, strip - bar.width))
        if revealSelection, let selected = selectedIndex {
            let start = tabWidths.prefix(selected).reduce(0, +), end = start + tabWidths[selected]
            if start < offset { offset = start } else if end > offset + bar.width { offset = end - bar.width }
            revealSelection = false
        }
        barOffset = offset
        let area = contentArea
        contentOverflow = 0
        for tab in tabs where !tab.content.isHidden { layoutContent(tab.content, in: area) }
        if contentOverflow == 0 { contentOffset = 0 }
    }

    /// Lays `content` out in `area`; when what it holds runs past the bottom (a toolbar wrapped
    /// onto more rows than a short panel has room for, anywhere in it), lays it out that much
    /// taller, scrolled by `contentOffset`, so every part can be scrolled to.
    private func layoutContent(_ content: Widget, in area: UIRect) {
        content.layout(in: area)
        let overflow = Self.bottom(of: content) - area.maxY
        guard overflow > 0.5 else { return }
        contentOverflow = overflow
        contentOffset = min(max(contentOffset, 0), overflow)
        content.layout(in: UIRect(x: area.x, y: area.y - contentOffset, width: area.width, height: area.height + overflow))
    }

    /// The lowest edge of `widget` and what it lays out in the flow: not the content of scroll
    /// views and other tab views (they keep it inside themselves), nor hidden or absolutely
    /// placed widgets.
    private static func bottom(of widget: Widget) -> Float {
        var bottom = widget.frame.maxY
        guard !(widget is ScrollView), !(widget is TabView) else { return bottom }
        for child in widget.children where !child.isHidden && child.style.position == .flow {
            bottom = max(bottom, self.bottom(of: child))
        }
        return bottom
    }

    /// Scrolls overflowing content so `rect` (window points) shows, as far as it can.
    public override func scrollToReveal(_ rect: UIRect) -> Bool {
        guard contentOverflow > 0 else { return false }
        let area = contentArea
        var offset = contentOffset
        if rect.maxY > area.maxY {
            offset += min(rect.maxY - area.maxY, rect.y - area.y)
        } else if rect.y < area.y {
            offset -= area.y - rect.y
        }
        offset = min(max(offset, 0), contentOverflow)
        guard offset != contentOffset else { return false }
        contentOffset = offset
        setNeedsLayout()
        return true
    }

    /// Children are clipped to the content area, so scrolled content never covers the tab bar.
    override var childClipRect: UIRect { contentArea }

    // MARK: Events

    public override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point) else { return nil }
        if barRect.contains(point) { return self }
        if let content = selectedTab?.content, let hit = content.hitTest(point) { return hit }
        return selectedTab?.passesPointerThrough == true ? nil : self
    }

    /// "Close <title>" over a close button, else the panel's `tooltip` or its full title while the tab cuts it off.
    public override func tooltip(at point: Vec2) -> String? {
        if let tooltip { return tooltip }
        guard drag == nil, let i = tab(at: point) else { return nil }
        let panel = tabs[i]
        if let close = closeButtonRect(i), close.contains(point) { return "Close \(panel.title)" }
        return panel.tooltip ?? truncatedText(panel.title, size: theme.fontSize, width: titleRect(i, in: tabRects[i], showClose: closeButtonRect(i) != nil).width)
    }

    public override func cursor(at point: Vec2) -> UICursor? {
        drag?.phase == .docking || drag?.phase == .reordering ? .move : nil
    }

    /// The pointer left the bar far enough to dock the tab elsewhere.
    private func leftBar(_ p: Vec2) -> Bool {
        let bar = barRect
        return p.y < bar.y - bar.height || p.y > bar.maxY + bar.height || p.x < bar.x - 24 || p.x > bar.maxX + 24
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e):
            guard let index = tab(at: e.position) else { return false }
            if e.button == .middle {
                if tabs[index].isClosable { pressedClose = tabs[index] }
                return true
            }
            guard e.button == .left else { return false }
            if let close = closeButtonRect(index), close.contains(e.position) {
                pressedClose = tabs[index]
                setNeedsDisplay()
                return true
            }
            userSelect(index)
            drag = (tabs[index], e.position, e.position.x - tabRects[index].x, .pressed)
            return true
        case .pointerDrag(let e):
            guard var current = drag else { return pressedClose != nil }
            if current.phase == .pressed {
                let d = e.position - current.start
                guard (d * d).sum() >= 16 else { return true }
                current.phase = .reordering
            }
            if current.phase == .reordering, let dock, leftBar(e.position) {
                current.phase = .docking
                drag = current
                dock.beginTabDrag(current.panel, from: self)
            }
            drag = current
            switch current.phase {
            case .reordering:
                guard let from = tabs.firstIndex(where: { $0 === current.panel }) else { return true }
                let draggedCenter = e.position.x - current.grab + (from < tabWidths.count ? tabWidths[from] / 2 : 0)
                let to = insertionIndex(at: draggedCenter, excluding: current.panel)
                if to != from {
                    moveTab(from: from, to: to)
                    onReorder?(tabs)
                }
                setNeedsDisplay()
            case .docking:
                dock?.updateTabDrag(at: e.position)
            case .pressed:
                break
            }
            return true
        case .pointerUp(let e):
            if let panel = pressedClose {
                pressedClose = nil
                setNeedsDisplay()
                if let index = tabs.firstIndex(where: { $0 === panel }),
                   e.button == .middle ? tab(at: e.position) == index : closeButtonRect(index)?.contains(e.position) == true {
                    closeTab(at: index)
                }
                return true
            }
            guard let current = drag else { return false }
            drag = nil
            setNeedsDisplay()
            if current.phase == .docking { dock?.endTabDrag(at: e.position, commit: true) }
            return true
        case .scroll(let delta, let position):
            if contentOverflow > 0, contentArea.contains(position), delta.y != 0 {
                let old = contentOffset
                contentOffset = min(max(contentOffset - delta.y, 0), contentOverflow)
                if contentOffset != old { setNeedsLayout() }
                return contentOffset != old
            }
            guard barRect.contains(position) else { return false }
            let strip = tabWidths.reduce(0, +)
            let old = barOffset
            barOffset = min(max(barOffset - (delta.x != 0 ? delta.x : delta.y), 0), max(0, strip - barRect.width))
            if barOffset != old { setNeedsLayout() }
            return barOffset != old
        case .key(let e):
            if e.key == .escape, let current = drag {
                drag = nil
                if current.phase == .docking { dock?.endTabDrag(at: context?.pointerPosition ?? .zero, commit: false) }
                setNeedsDisplay()
                return true
            }
            let control = e.modifiers.contains(.control)
            switch e.key {
            case .tab where control && !e.modifiers.contains(.command):
                selectNext(!e.modifiers.contains(.shift))
            case .pageDown where control:
                selectNext(true)
            case .pageUp where control:
                selectNext(false)
            case .right where isFocused && e.modifiers.isEmpty:
                selectNext(true)
            case .left where isFocused && e.modifiers.isEmpty:
                selectNext(false)
            default:
                return false
            }
            return true
        default:
            return false
        }
    }

    public override func focusChanged(_ focused: Bool) {
        setNeedsDisplay()
    }

    // MARK: Painting

    /// The selected tab is highlighted with the accent when this group has the user's attention
    /// (focus inside, or the dock's active group).
    private var isActiveGroup: Bool {
        if let dock, dock.activeGroup === self { return true }
        guard let focused = context?.focusedWidget else { return false }
        return focused.isDescendant(of: self)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let bar = barRect
        if selectedTab?.drawsBackground != false { list.fillRect(contentArea, color: background ?? theme.panelBackground) }
        list.fillRect(bar, color: theme.fieldBackground)
        list.fillRect(UIRect(x: bar.x, y: bar.maxY - 1, width: bar.width, height: 1), color: theme.panelBorder)
        let rects = tabRects
        let hovered = context.flatMap { $0.hoveredWidget === self ? tab(at: $0.pointerPosition) : nil }
        let dragged = drag?.phase == .reordering ? drag?.panel : nil
        list.withClip(bar) {
            for (i, rect) in rects.enumerated() where tabs[i] !== dragged && rect.intersects(bar) {
                drawTab(i, in: rect, list: list, theme: theme, hovered: hovered == i)
            }
            if let dragged, let i = tabs.firstIndex(where: { $0 === dragged }), let pointer = context?.pointerPosition,
               let grab = drag?.grab {
                let x = min(max(pointer.x - grab, bar.x), bar.maxX - rects[i].width)
                drawTab(i, in: UIRect(x: snap(x), y: bar.y, width: rects[i].width, height: bar.height), list: list,
                        theme: theme, hovered: true)
            }
            // Fades where more tabs are scrolled out of view.
            let strip = tabWidths.reduce(0, +)
            if let caption = selectedTab?.caption, !caption.isEmpty, dragged == nil {
                drawCaption(caption, after: bar.x - barOffset + strip, in: bar, theme: theme, list: list)
            }
            let fade: Float = 16
            if barOffset > 0 {
                list.fillRect(UIRect(x: bar.x, y: bar.y, width: fade, height: bar.height - 1),
                              fill: .linearGradient(start: theme.fieldBackground, end: theme.fieldBackground.withAlpha(0), angle: 0))
            }
            if strip - barOffset > bar.width + 0.5 {
                list.fillRect(UIRect(x: bar.maxX - fade, y: bar.y, width: fade, height: bar.height - 1),
                              fill: .linearGradient(start: theme.fieldBackground.withAlpha(0), end: theme.fieldBackground, angle: 0))
            }
        }
    }

    /// The selected panel's caption, right-aligned in the bar's free space past the tabs (`x`),
    /// ellipsized when tight, left out when there is almost no room.
    private func drawCaption(_ caption: String, after x: Float, in bar: UIRect, theme: UITheme, list: UIDrawList) {
        let size = theme.smallFontSize
        let room = UIRect(x: x + theme.controlPaddingX, y: bar.y, width: bar.maxX - theme.controlPaddingX - x - theme.controlPaddingX,
                          height: bar.height - 1)
        guard room.width >= 48 else { return }
        let layout = cachedLayout(caption, size: size)
        let alignment: TextAlignment = overflows(layout, width: room.width) ? .left : .right
        drawEllipsized(caption, layout: layout, size: size, in: room, alignment: alignment, color: theme.secondaryTextColor, list: list)
    }

    /// The selected panel's caption when the bar shows it, for introspection and tests.
    public var captionIsShown: Bool {
        guard let caption = selectedTab?.caption, !caption.isEmpty else { return false }
        let strip = tabWidths.reduce(0, +)
        return barRect.maxX - 2 * theme.controlPaddingX - (barRect.x - barOffset + strip) >= 48
    }

    /// A scroll indicator along the right edge while the content overflows.
    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        guard contentOverflow > 0 else { return }
        let area = contentArea
        guard area.height > 0 else { return }
        let length = max(20, area.height * area.height / (area.height + contentOverflow))
        let y = area.y + (area.height - length) * contentOffset / contentOverflow
        let width = theme.scrollbarWidth
        list.fillRect(UIRect(x: area.maxX - width - 2, y: snap(y), width: width, height: snap(length)), color: theme.scrollbarThumb,
                      radii: UICornerRadii(width / 2))
    }

    /// Where tab `i`'s title goes inside `rect`, leaving room for the close button when it shows.
    private func titleRect(_ i: Int, in rect: UIRect, showClose: Bool) -> UIRect {
        let theme = theme
        let textRight = showClose ? (closeGlyphRect(i)?.x ?? rect.maxX) - 2 : rect.maxX - theme.controlPaddingX
        let x = rect.x + theme.controlPaddingX + iconSpace(tabs[i], theme: theme)
        return UIRect(x: x, y: rect.y, width: max(0, textRight - x), height: rect.height)
    }

    private func drawTab(_ i: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, hovered: Bool) {
        let panel = tabs[i]
        let selected = i == selectedIndex
        if selected {
            list.fillRect(rect, color: theme.panelBackground)
            let line = isActiveGroup ? theme.accent : theme.controlBorder
            list.fillRect(UIRect(x: rect.x, y: rect.y, width: rect.width, height: 2), color: line)
        } else {
            if hovered { list.fillRect(rect.inset(by: EdgeInsets(top: 0, left: 0, bottom: 1, right: 0)), color: theme.rowHover) }
            let next = i + 1
            if next != selectedIndex {
                list.fillRect(UIRect(x: rect.maxX - 1, y: rect.y + 7, width: 1, height: max(0, rect.height - 14)),
                              color: theme.panelBorder)
            }
        }
        if selected && isFocused && context?.focusVisible == true {
            list.strokeRect(rect.inset(by: EdgeInsets(top: 3, left: 2, bottom: 2, right: 2)), color: theme.focusRing,
                            width: theme.focusRingWidth, radii: UICornerRadii(theme.rowCornerRadius))
        }
        let close = closeButtonRect(i)
        let showClose = close != nil && (selected || hovered || pressedClose === panel)
        let textRect = titleRect(i, in: rect, showClose: showClose)
        let layout = cachedLayout(panel.title, size: theme.fontSize)
        let color = selected ? theme.textColor : theme.secondaryTextColor
        if let icon = panel.icon {
            let edge = iconEdge(theme)
            let iconRect = UIRect(x: rect.x + theme.controlPaddingX, y: rect.center.y + 1 - edge / 2, width: edge, height: edge)
            if iconRect.maxX <= textRect.maxX + 1 {
                list.drawIcon(icon, in: iconRect, color: isEffectivelyEnabled ? (selected ? theme.accent.mixed(with: theme.textColor, 0.35) : color)
                                                                              : theme.disabledTextColor)
            }
        }
        drawEllipsized(panel.title, layout: layout, size: theme.fontSize, in: textRect,
                       color: isEffectivelyEnabled ? color : theme.disabledTextColor, list: list)
        if showClose, let close, let glyph = closeGlyphRect(i) {
            let pointer = context?.pointerPosition ?? Vec2(-1e6, -1e6)
            if close.contains(pointer) && (pressedClose === panel || pressedClose == nil) {
                // The highlight a little larger than the glyph; clicks count in all of `close`.
                list.fillRect(glyph.inset(by: EdgeInsets(-2)), color: pressedClose === panel ? theme.controlPressed : theme.controlHover,
                              radii: UICornerRadii(theme.rowCornerRadius))
            }
            let c = glyph.center, s: Float = 3.5
            let xColor = selected ? theme.secondaryTextColor : theme.placeholderColor
            list.drawLine(from: c + Vec2(-s, -s), to: c + Vec2(s, s), width: theme.iconStrokeWidth, color: xColor, cap: .round)
            list.drawLine(from: c + Vec2(-s, s), to: c + Vec2(s, -s), width: theme.iconStrokeWidth, color: xColor, cap: .round)
        }
    }
}
