import Foundation

/// Split-pane math, kept free of widgets so it can be tested directly. Panes share the length
/// left after the dividers in proportion to their fractions; panes that would get less than
/// their minimum are held at it and the rest is shared among the others.
public enum SplitLayout {
    /// Fractions that are finite, non-negative and sum to 1 (equal shares when that isn't
    /// possible); padded or truncated to `count`.
    public static func normalized(_ fractions: [Float], count: Int) -> [Float] {
        guard count > 0 else { return [] }
        var f = (0..<count).map { $0 < fractions.count && fractions[$0].isFinite ? max(fractions[$0], 0) : 0 }
        let total = f.reduce(0, +)
        if total <= 0 { return Array(repeating: 1 / Float(count), count: count) }
        f = f.map { $0 / total }
        return f
    }

    /// The pane lengths for `available` points (dividers already removed). When the minimums
    /// don't fit, every pane gets its minimum scaled down by the same factor.
    public static func sizes(fractions: [Float], minSizes: [Float], available: Float) -> [Float] {
        let n = fractions.count
        guard n > 0 else { return [] }
        let available = max(available, 0)
        let mins = (0..<n).map { $0 < minSizes.count ? max(minSizes[$0], 0) : 0 }
        let totalMin = mins.reduce(0, +)
        if totalMin >= available {
            return totalMin > 0 ? mins.map { $0 * available / totalMin } : Array(repeating: available / Float(n), count: n)
        }
        let fractions = normalized(fractions, count: n)
        var sizes = Array(repeating: Float(0), count: n)
        var frozen = Array(repeating: false, count: n)
        // Freeze the panes below their minimum and share the rest again (at most n rounds).
        for _ in 0..<n {
            let free = available - (0..<n).reduce(Float(0)) { frozen[$1] ? $0 + mins[$1] : $0 }
            let weight = (0..<n).reduce(Float(0)) { frozen[$1] ? $0 : $0 + fractions[$1] }
            var clamped = false
            for i in 0..<n where !frozen[i] {
                let share = weight > 0 ? free * fractions[i] / weight : free / Float(frozen.filter { !$0 }.count)
                if share < mins[i] {
                    frozen[i] = true
                    clamped = true
                }
                sizes[i] = share
            }
            if !clamped { break }
        }
        for i in 0..<n where frozen[i] { sizes[i] = mins[i] }
        return sizes
    }

    /// Lengths after dragging divider `index` (between panes `index` and `index + 1`) by
    /// `delta` points. Only the two neighbors change, and neither goes below its minimum.
    public static func dragging(_ sizes: [Float], divider index: Int, by delta: Float, minSizes: [Float]) -> [Float] {
        guard index >= 0, index + 1 < sizes.count else { return sizes }
        func minimum(_ i: Int) -> Float { i < minSizes.count ? max(minSizes[i], 0) : 0 }
        var result = sizes
        let pair = sizes[index] + sizes[index + 1]
        let low = min(minimum(index), pair), high = max(low, pair - minimum(index + 1))
        result[index] = min(max(sizes[index] + delta, low), high)
        result[index + 1] = pair - result[index]
        return result
    }
}

/// Two or more panes side by side (`axis` `.horizontal`) or stacked (`.vertical`), separated
/// by draggable dividers. Each pane keeps a fraction of the length (so proportions survive
/// window resizes) and never gets less than its minimum. Drag a divider to move it (only its
/// two neighbors change), double-click it to go back to `defaultFractions`. While the pointer
/// is over a divider or dragging it, `UIContext.desiredCursor` is a resize arrow.
public final class SplitView: Widget {
    public let axis: Axis
    public private(set) var panes: [Widget]
    /// Each pane's share of the length after the dividers (sums to 1).
    public private(set) var fractions: [Float]
    /// What a double-click on a divider (or `resetFractions`) goes back to.
    public var defaultFractions: [Float]
    /// Minimum lengths along the axis, per pane (points).
    public var minSizes: [Float] { didSet { if minSizes != oldValue { setNeedsLayout() } } }
    /// Space between panes (points), painted as the divider.
    public var dividerThickness: Float = 4 { didSet { if dividerThickness != oldValue { setNeedsLayout() } } }
    /// Extra grab area on each side of a divider (points), over the panes.
    public var dividerHitSlop: Float = 3
    /// The divider's color; nil leaves the gap clear (the split view's `background` shows). Accent while hovered or dragged.
    public var dividerColor: UIColor? { didSet { setNeedsDisplay() } }
    /// Without a `dividerColor`, paints the divider in the current theme's field background
    /// (follows theme changes; a `DockSpace`'s gaps).
    public var dividerUsesThemeColor = false { didSet { setNeedsDisplay() } }
    /// Called with the new fractions when the user drags a divider or double-clicks one.
    public var onResize: (([Float]) -> Void)?

    private var drag: (divider: Int, start: Float, sizes: [Float])?

    public init(_ axis: Axis, panes: [Widget], fractions: [Float]? = nil, minSizes: [Float]? = nil, name: String = "") {
        self.axis = axis
        self.panes = panes
        let initial = SplitLayout.normalized(fractions ?? [], count: panes.count)
        self.fractions = initial
        defaultFractions = initial
        self.minSizes = minSizes ?? Array(repeating: 0, count: panes.count)
        super.init(name: name)
        isHitTestable = false
        addChildren(panes)
    }

    public override var accessibilityRole: UIAccessibilityRole { .splitView }

    /// Sets the fractions (normalized) without calling `onResize`.
    public func setFractions(_ values: [Float]) {
        let normalized = SplitLayout.normalized(values, count: panes.count)
        guard normalized != fractions else { return }
        fractions = normalized
        setNeedsLayout()
    }

    /// Goes back to `defaultFractions`.
    public func resetFractions() {
        setFractions(defaultFractions)
    }

    /// Adds a pane at `index` taking `fraction` of the length (the others shrink proportionally).
    public func insertPane(_ pane: Widget, at index: Int, fraction: Float, minSize: Float = 0) {
        let index = min(max(index, 0), panes.count)
        let f = panes.isEmpty ? 1 : min(max(fraction, 0), 1)
        var values = fractions.map { $0 * (1 - f) }
        values.insert(f, at: index)
        panes.insert(pane, at: index)
        minSizes.insert(minSize, at: min(index, minSizes.count))
        defaultFractions = SplitLayout.normalized(values, count: panes.count)
        fractions = defaultFractions
        insertChild(pane, at: index)
    }

    /// Removes a pane; its share goes to the others proportionally.
    public func removePane(at index: Int) {
        guard panes.indices.contains(index) else { return }
        let pane = panes.remove(at: index)
        fractions.remove(at: index)
        if index < minSizes.count { minSizes.remove(at: index) }
        fractions = SplitLayout.normalized(fractions, count: panes.count)
        defaultFractions = fractions
        pane.removeFromParent()
        setNeedsLayout()
    }

    private var vertical: Bool { axis == .vertical }
    private func along(_ v: Vec2) -> Float { vertical ? v.y : v.x }

    /// Pane lengths along the axis for the current frame.
    public var paneSizes: [Float] {
        let length = vertical ? contentRect.height : contentRect.width
        let available = length - dividerThickness * Float(max(panes.count - 1, 0))
        return SplitLayout.sizes(fractions: fractions, minSizes: minSizes, available: available)
    }

    /// The divider between panes `index` and `index + 1` (window points), from the last layout.
    public func dividerRect(_ index: Int) -> UIRect {
        guard index >= 0, index + 1 < panes.count else { return .zero }
        let a = panes[index].frame, b = panes[index + 1].frame
        return vertical ? UIRect(x: contentRect.x, y: a.maxY, width: contentRect.width, height: b.y - a.maxY)
            : UIRect(x: a.maxX, y: contentRect.y, width: b.x - a.maxX, height: contentRect.height)
    }

    /// The divider whose grab area contains `point`.
    public func divider(at point: Vec2) -> Int? {
        for i in 0..<max(panes.count - 1, 0) {
            let r = dividerRect(i)
            let grab = vertical ? UIRect(x: r.x, y: r.y - dividerHitSlop, width: r.width, height: r.height + 2 * dividerHitSlop)
                : UIRect(x: r.x - dividerHitSlop, y: r.y, width: r.width + 2 * dividerHitSlop, height: r.height)
            if grab.contains(point) { return i }
        }
        return nil
    }

    /// Moves divider `index` so the pane before it ends at `position` (window points along the axis),
    /// as a drag would. Calls `onResize`.
    public func moveDivider(_ index: Int, to position: Float) {
        guard index >= 0, index + 1 < panes.count else { return }
        let sizes = paneSizes
        let start = along(Vec2(panes[index].frame.x, panes[index].frame.y))
        apply(SplitLayout.dragging(sizes, divider: index, by: position - (start + sizes[index]), minSizes: minSizes))
    }

    private func apply(_ sizes: [Float]) {
        let total = sizes.reduce(0, +)
        guard total > 0 else { return }
        let values = sizes.map { $0 / total }
        guard values != fractions else { return }
        fractions = values
        setNeedsLayout()
        onResize?(fractions)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let dividers = dividerThickness * Float(max(panes.count - 1, 0))
        let mins = minSizes.prefix(panes.count).reduce(0, +)
        return vertical ? Vec2(0, mins + dividers) : Vec2(mins + dividers, 0)
    }

    public override func layoutChildren() {
        let content = contentRect
        let sizes = paneSizes
        // Edges are placed cumulatively and snapped, so neighbors share them exactly.
        var cursor = vertical ? content.y : content.x
        for (i, pane) in panes.enumerated() {
            let start = cursor, end = cursor + sizes[i]
            pane.layout(in: vertical ? UIRect(x: content.x, y: snap(start), width: content.width, height: snap(end) - snap(start))
                : UIRect(x: snap(start), y: content.y, width: snap(end) - snap(start), height: content.height))
            cursor = end + dividerThickness
        }
    }

    public override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point) else { return nil }
        // Dividers (with their slop) win over the panes they overlap.
        if divider(at: point) != nil { return self }
        return super.hitTest(point)
    }

    public override func cursor(at point: Vec2) -> UICursor? {
        guard drag != nil || divider(at: point) != nil else { return nil }
        return vertical ? .resizeUpDown : .resizeLeftRight
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            guard let index = divider(at: e.position) else { return false }
            if e.clickCount >= 2 {
                let old = fractions
                resetFractions()
                if fractions != old { onResize?(fractions) }
                return true
            }
            drag = (index, along(e.position), paneSizes)
            setNeedsDisplay()
            return true
        case .pointerDrag(let e):
            guard let drag else { return false }
            apply(SplitLayout.dragging(drag.sizes, divider: drag.divider, by: along(e.position) - drag.start, minSizes: minSizes))
            return true
        case .pointerUp:
            guard drag != nil else { return false }
            drag = nil
            setNeedsDisplay()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        guard panes.count > 1 else { return }
        let hovered = context.flatMap { $0.hoveredWidget === self ? divider(at: $0.pointerPosition) : nil }
        for i in 0..<(panes.count - 1) {
            let active = drag?.divider == i || (drag == nil && hovered == i)
            let color = active ? theme.accent : (dividerColor ?? (dividerUsesThemeColor ? theme.fieldBackground : .clear))
            if color.a > 0 { list.fillRect(dividerRect(i), color: color) }
        }
    }
}
