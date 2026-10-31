import Foundation

/// Layout math shared by the containers, kept free of widgets so it can be tested directly.
public enum UILayout {
    /// Rounds `value` (points) to the nearest framebuffer pixel at `scale` pixels per point.
    /// Ties round away from zero, so the result depends only on the value.
    public static func snap(_ value: Float, scale: Float) -> Float {
        guard scale > 0, value.isFinite else { return value }
        return (value * scale).rounded() / scale
    }

    /// One item along a stack's main axis.
    public struct FlexItem: Sendable, Equatable {
        public var base: Float
        public var min: Float
        public var max: Float
        public var grow: Float
        public var shrink: Float

        public init(base: Float, min: Float = 0, max: Float = .infinity, grow: Float = 0, shrink: Float = 0) {
            (self.base, self.min, self.max, self.grow, self.shrink) = (base, min, max, grow, shrink)
        }
    }

    /// Main-axis sizes for `items` sharing `available` points (spacing already removed),
    /// following CSS flexbox: free space goes to growing items in proportion to `grow`; an
    /// overflow is taken from shrinking items in proportion to `shrink * base`. Items that hit
    /// their min/max are frozen there and the rest is redistributed among the others.
    public static func distribute(_ items: [FlexItem], available: Float) -> [Float] {
        var sizes = items.map { Swift.min(Swift.max($0.base, $0.min), $0.max) }
        let initialFree = available - sizes.reduce(0, +)
        guard initialFree != 0 else { return sizes }
        let growing = initialFree > 0
        var frozen = items.map { growing ? $0.grow <= 0 : $0.shrink <= 0 }
        for _ in 0...items.count {
            let unfrozen = items.indices.filter { !frozen[$0] }
            if unfrozen.isEmpty { break }
            var used: Float = 0
            for i in items.indices { used += frozen[i] ? sizes[i] : Swift.min(Swift.max(items[i].base, items[i].min), items[i].max) }
            let free = available - used
            let weights = unfrozen.map { growing ? items[$0].grow : items[$0].shrink * Swift.max(items[$0].base, 0) }
            let total = weights.reduce(0, +)
            var clamped: [Int] = []
            for (k, i) in unfrozen.enumerated() {
                let start = Swift.min(Swift.max(items[i].base, items[i].min), items[i].max)
                let target = total > 0 ? start + free * weights[k] / total : start
                let limited = Swift.min(Swift.max(target, items[i].min), items[i].max)
                sizes[i] = limited
                if limited != target { clamped.append(i) }
            }
            if clamped.isEmpty { break }
            for i in clamped { frozen[i] = true }
        }
        return sizes
    }

    /// Offsets of the first item and the extra gap between items for a main-axis alignment.
    public static func justify(_ alignment: MainAlignment, free: Float, count: Int) -> (start: Float, gap: Float) {
        let free = Swift.max(free, 0)
        switch alignment {
        case .start: return (0, 0)
        case .center: return (free / 2, 0)
        case .end: return (free, 0)
        case .spaceBetween: return count > 1 ? (0, free / Float(count - 1)) : (0, 0)
        }
    }
}

/// Lays children out in a row or column: `spacing` between them, `padding` around, flex
/// grow/shrink along the axis (`LayoutStyle.grow/shrink`, min/max), `alignment` across it and
/// `justify` along it. Absolutely positioned children are placed by their anchors instead.
/// With `background` / `borderColor` set it doubles as a panel. A horizontal stack with `wraps`
/// moves children that don't fit onto further rows (toolbars in narrow windows).
open class Stack: Widget {
    public var axis: Axis { didSet { if axis != oldValue { setNeedsLayout() } } }
    public var spacing: Float { didSet { if spacing != oldValue { setNeedsLayout() } } }
    /// Horizontal stacks only: children that don't fit at their natural width start a new row
    /// (`spacing` apart), each row laid out as a stack of its own (grow / shrink / justify per
    /// row). Separators that would start or end a row are left out of it. The stack's measured
    /// height counts every row, so a parent that knows the width gives it room.
    public var wraps = false { didSet { if wraps != oldValue { setNeedsLayout() } } }
    public var alignment: CrossAlignment { didSet { if alignment != oldValue { setNeedsLayout() } } }
    public var justify: MainAlignment = .start { didSet { if justify != oldValue { setNeedsLayout() } } }

    public init(_ axis: Axis, spacing: Float = 0, alignment: CrossAlignment = .stretch, padding: EdgeInsets = .zero,
                name: String = "", children: [Widget] = []) {
        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
        super.init(name: name)
        self.padding = padding
        addChildren(children)
    }

    private var flowChildren: [Widget] {
        children.filter { !$0.isHidden && $0.style.position == .flow }
    }

    open override func measureContent(width: Float?) -> Vec2 {
        let items = flowChildren
        let gaps = spacing * Float(max(items.count - 1, 0))
        switch axis {
        case .vertical:
            var size = Vec2(0, gaps)
            for child in items {
                let s = child.measure(width: width)
                size.x = max(size.x, s.x)
                size.y += s.y
            }
            return size
        case .horizontal:
            if wraps, let width {
                let rows = wrappedRows(items, width: width)
                var size = Vec2(0, spacing * Float(max(rows.count - 1, 0)))
                for row in rows {
                    let widths = row.map { $0.measure(width: nil).x }
                    size.x = max(size.x, min(width, widths.reduce(0, +) + spacing * Float(max(row.count - 1, 0))))
                    size.y += row.map { $0.measure(width: nil).y }.max() ?? 0
                }
                return size
            }
            var size = Vec2(gaps, 0)
            for child in items {
                let s = child.measure(width: nil)
                size.x += s.x
                size.y = max(size.y, s.y)
            }
            return size
        }
    }

    /// `items` split into rows that fit `width` at their natural widths (at least one item per
    /// row), without separators at the start or end of a row.
    func wrappedRows(_ items: [Widget], width: Float) -> [[Widget]] {
        var rows: [[Widget]] = [[]]
        var used: Float = 0
        for child in items {
            let w = max(child.measure(width: nil).x, child.style.minWidth)
            if !rows[rows.count - 1].isEmpty, used + spacing + w > width + 0.5 {
                rows.append([])
                used = 0
            }
            if rows[rows.count - 1].isEmpty && child is Separator { continue }
            used += (rows[rows.count - 1].isEmpty ? 0 : spacing) + w
            rows[rows.count - 1].append(child)
        }
        for i in rows.indices {
            while let last = rows[i].last, last is Separator { rows[i].removeLast() }
        }
        return rows.filter { !$0.isEmpty }
    }

    open override func layoutChildren() {
        let content = contentRect
        let flow = flowChildren
        if wraps && axis == .horizontal {
            let rows = wrappedRows(flow, width: content.width)
            if rows.count > 1 {
                let placed = Set(rows.joined().map(ObjectIdentifier.init))
                for child in flow where !placed.contains(ObjectIdentifier(child)) {
                    child.layout(in: UIRect(x: content.x, y: content.y, width: 0, height: 0))
                }
                var y = content.y
                for row in rows {
                    let height = row.map { $0.measure(width: nil).y }.max() ?? 0
                    layoutRow(row, in: UIRect(x: content.x, y: y, width: content.width, height: height))
                    y += height + spacing
                }
                layoutAbsoluteChildren(in: content)
                return
            }
        }
        layoutRow(flow, in: content)
        layoutAbsoluteChildren(in: content)
    }

    /// Lays `items` out along the axis in `content` (one row of a wrapping stack, or all of them).
    private func layoutRow(_ items: [Widget], in content: UIRect) {
        let vertical = axis == .vertical
        let mainLength = vertical ? content.height : content.width
        let crossLength = vertical ? content.width : content.height

        func align(_ child: Widget) -> CrossAlignment { child.style.alignSelf ?? alignment }
        func stretches(_ child: Widget) -> Bool {
            align(child) == .stretch && (vertical ? child.style.width : child.style.height) == nil
        }
        func clampCross(_ child: Widget, _ value: Float) -> Float {
            vertical ? min(max(value, child.style.minWidth), child.style.maxWidth)
                : min(max(value, child.style.minHeight), child.style.maxHeight)
        }

        // Vertical stacks know each child's width before measuring its height (wrapping text).
        var crossSizes: [Float] = []
        var flex: [UILayout.FlexItem] = []
        for child in items {
            let cross: Float
            if vertical {
                cross = stretches(child) ? clampCross(child, crossLength) : child.measure(width: crossLength).x
            } else {
                cross = 0  // measured once the width is known
            }
            crossSizes.append(cross)
            let base = vertical ? child.measure(width: cross).y : child.measure(width: nil).x
            let s = child.style
            flex.append(UILayout.FlexItem(
                base: base, min: vertical ? s.minHeight : s.minWidth, max: vertical ? s.maxHeight : s.maxWidth,
                grow: s.grow, shrink: s.shrink))
        }
        let gaps = spacing * Float(max(items.count - 1, 0))
        let sizes = UILayout.distribute(flex, available: mainLength - gaps)
        let used = sizes.reduce(0, +) + gaps
        let (start, extraGap) = UILayout.justify(justify, free: mainLength - used, count: items.count)

        var cursor = (vertical ? content.y : content.x) + start
        for (i, child) in items.enumerated() {
            let main = sizes[i]
            var cross = crossSizes[i]
            if !vertical {
                cross = stretches(child) ? clampCross(child, crossLength) : child.measure(width: main).y
            }
            let crossOrigin = vertical ? content.x : content.y
            let crossOffset: Float
            switch align(child) {
            case .start, .stretch: crossOffset = 0
            case .center: crossOffset = (crossLength - cross) / 2
            case .end: crossOffset = crossLength - cross
            }
            let rect = vertical
                ? UIRect(x: crossOrigin + crossOffset, y: cursor, width: cross, height: main)
                : UIRect(x: cursor, y: crossOrigin + crossOffset, width: main, height: cross)
            child.layout(in: rect)
            cursor += main + spacing + extraGap
        }
    }

    private func layoutAbsoluteChildren(in content: UIRect) {
        for child in children where !child.isHidden {
            if case .absolute(let anchors) = child.style.position {
                child.layout(in: Self.anchoredFrame(for: child, anchors: anchors, in: content, snap: snap))
            }
        }
    }
}

/// A vertical `Stack`.
public final class VStack: Stack {
    public init(spacing: Float = 0, alignment: CrossAlignment = .stretch, padding: EdgeInsets = .zero, name: String = "",
                _ children: [Widget] = []) {
        super.init(.vertical, spacing: spacing, alignment: alignment, padding: padding, name: name, children: children)
    }
}

/// A horizontal `Stack`.
public final class HStack: Stack {
    public init(spacing: Float = 0, alignment: CrossAlignment = .center, padding: EdgeInsets = .zero, name: String = "",
                _ children: [Widget] = []) {
        super.init(.horizontal, spacing: spacing, alignment: alignment, padding: padding, name: name, children: children)
    }
}
