import Foundation

/// Scrolling math along one axis, shared by `ScrollView`, `ListView` and `TreeView`.
public struct ScrollState: Sendable, Equatable {
    /// Distance scrolled from the top (or left), in points (0...maxOffset).
    public private(set) var offset: Float = 0
    public private(set) var contentLength: Float = 0
    public private(set) var viewportLength: Float = 0

    public init() {}

    public var maxOffset: Float { max(0, contentLength - viewportLength) }
    public var canScroll: Bool { maxOffset > 0 }

    /// Updates the lengths and re-clamps the offset.
    public mutating func setLengths(content: Float, viewport: Float) {
        contentLength = max(content, 0)
        viewportLength = max(viewport, 0)
        offset = min(max(offset, 0), maxOffset)
    }

    /// Sets the offset, clamped. Returns whether it changed.
    @discardableResult
    public mutating func scroll(to value: Float) -> Bool {
        let clamped = min(max(value.isFinite ? value : 0, 0), maxOffset)
        defer { offset = clamped }
        return clamped != offset
    }

    /// Scrolls the least amount that shows `start..<end` (content coordinates). Returns whether it moved.
    @discardableResult
    public mutating func reveal(_ start: Float, _ end: Float) -> Bool {
        if start < offset { return scroll(to: start) }
        if end > offset + viewportLength { return scroll(to: min(start, end - viewportLength)) }
        return false
    }

    /// The scrollbar thumb inside `track` (window points), or nil when nothing scrolls. `axis`
    /// is the direction the track runs in.
    public func thumb(in track: UIRect, axis: Axis = .vertical, minLength: Float = 20) -> UIRect? {
        guard canScroll, contentLength > 0 else { return nil }
        if axis == .horizontal {
            let length = min(track.width, max(minLength, track.width * viewportLength / contentLength))
            let x = track.x + (track.width - length) * (offset / maxOffset)
            return UIRect(x: x, y: track.y, width: length, height: track.height)
        }
        let length = min(track.height, max(minLength, track.height * viewportLength / contentLength))
        let y = track.y + (track.height - length) * (offset / maxOffset)
        return UIRect(x: track.x, y: y, width: track.width, height: length)
    }

    /// The offset that puts the thumb's top (its left edge on a horizontal track) at `thumbTop` (dragging it).
    public func offset(forThumbTop thumbTop: Float, in track: UIRect, axis: Axis = .vertical, minLength: Float = 20) -> Float {
        guard let thumb = thumb(in: track, axis: axis, minLength: minLength) else { return 0 }
        let vertical = axis == .vertical
        let travel = vertical ? track.height - thumb.height : track.width - thumb.width
        return travel > 0 ? (thumbTop - (vertical ? track.y : track.x)) / travel * maxOffset : 0
    }
}

/// Handles the scrollbar and wheel parts of a scrolling widget along one axis: the track along
/// the right edge (vertical) or the bottom edge (horizontal) of `viewport`, dragging the thumb,
/// clicking the track to page, and the wheel. `corner` shortens the track at its far end so a
/// vertical and a horizontal bar don't overlap.
@MainActor
struct ScrollbarInteraction {
    var axis: Axis
    var corner: Float = 0
    private var thumbGrab: Float?
    private var contentDrag: (pointerY: Float, offset: Float)?

    init(axis: Axis = .vertical) { self.axis = axis }

    var isDragging: Bool { thumbGrab != nil || contentDrag != nil }

    static func track(for viewport: UIRect, theme: UITheme, axis: Axis = .vertical, corner: Float = 0) -> UIRect {
        let w = theme.scrollbarWidth
        if axis == .horizontal {
            return UIRect(x: viewport.x + 2, y: viewport.maxY - w - 2, width: max(0, viewport.width - 4 - corner), height: w)
        }
        return UIRect(x: viewport.maxX - w - 2, y: viewport.y + 2, width: w, height: max(0, viewport.height - 4 - corner))
    }

    /// The area that grabs the scrollbar (a bit wider than the thumb).
    static func hitArea(for viewport: UIRect, theme: UITheme, axis: Axis = .vertical, corner: Float = 0) -> UIRect {
        let w = theme.scrollbarWidth + 6
        if axis == .horizontal {
            return UIRect(x: viewport.x, y: viewport.maxY - w, width: max(0, viewport.width - corner), height: w)
        }
        return UIRect(x: viewport.maxX - w, y: viewport.y, width: w, height: max(0, viewport.height - corner))
    }

    /// The component of `v` along the axis.
    private func along(_ v: Vec2) -> Float { axis == .vertical ? v.y : v.x }

    /// Returns true when the event was consumed; `changed` reports offset changes.
    mutating func handle(_ event: UIEvent, state: inout ScrollState, viewport: UIRect, theme: UITheme,
                         dragContent: Bool) -> (handled: Bool, changed: Bool) {
        switch event {
        case .scroll(let delta, _):
            guard state.canScroll, along(delta) != 0 else { return (false, false) }
            let changed = state.scroll(to: state.offset - along(delta))
            // At an edge, let an outer scroller have it.
            return (changed, changed)
        case .pointerDown(let e) where e.button == .left:
            guard state.canScroll else { return (false, false) }
            let track = Self.track(for: viewport, theme: theme, axis: axis, corner: corner)
            if Self.hitArea(for: viewport, theme: theme, axis: axis, corner: corner).contains(e.position),
               let thumb = state.thumb(in: track, axis: axis) {
                let p = along(e.position)
                let (start, end) = axis == .vertical ? (thumb.y, thumb.maxY) : (thumb.x, thumb.maxX)
                if p >= start && p < end {
                    thumbGrab = p - start
                    return (true, false)
                }
                // Page towards the click.
                let page = state.viewportLength * 0.9
                let changed = state.scroll(to: state.offset + (p < start ? -page : page))
                thumbGrab = nil
                return (true, changed)
            }
            if dragContent {
                contentDrag = (along(e.position), state.offset)
                return (true, false)
            }
            return (false, false)
        case .pointerDrag(let e):
            if let grab = thumbGrab {
                let track = Self.track(for: viewport, theme: theme, axis: axis, corner: corner)
                return (true, state.scroll(to: state.offset(forThumbTop: along(e.position) - grab, in: track, axis: axis)))
            }
            if let drag = contentDrag {
                return (true, state.scroll(to: drag.offset - (along(e.position) - drag.pointerY)))
            }
            return (false, false)
        case .pointerUp:
            let was = isDragging
            thumbGrab = nil
            contentDrag = nil
            return (was, false)
        default:
            return (false, false)
        }
    }

    func draw(_ list: UIDrawList, state: ScrollState, viewport: UIRect, theme: UITheme, hovered: Bool) {
        let track = Self.track(for: viewport, theme: theme, axis: axis, corner: corner)
        guard let thumb = state.thumb(in: track, axis: axis) else { return }
        let active = isDragging || hovered
        list.fillRect(thumb, color: active ? theme.scrollbarThumbActive : theme.scrollbarThumb,
                      radii: UICornerRadii(min(thumb.width, thumb.height) / 2))
    }
}

/// Shows a part of a larger `content` widget and scrolls it: mouse wheel / trackpad, dragging
/// a scrollbar thumb, clicking a track (pages), or dragging empty parts of the content.
/// Content is clipped to the padded frame, and focusing a widget inside with the keyboard
/// scrolls it into view. Give the scroll view a size (`style.height`, or `grow` in a column);
/// its measured size is the content's.
///
/// By default it scrolls vertically only: the content is laid out at the viewport's width and
/// its measured height. With `scrollsHorizontally` the content gets its measured width
/// (unconstrained, so text doesn't wrap) when that is wider than the viewport, and a second
/// scrollbar runs along the bottom. Horizontal wheel deltas (trackpads, tilt wheels) scroll
/// sideways, and so does the vertical wheel with Shift held. `scrollsVertically = false`
/// makes a horizontal-only strip.
public final class ScrollView: Widget {
    public let content: Widget
    /// The vertical scroll state.
    public private(set) var scroll = ScrollState()
    /// The horizontal scroll state (only used with `scrollsHorizontally`).
    public private(set) var horizontalScroll = ScrollState()
    public var scrollsHorizontally = false { didSet { if scrollsHorizontally != oldValue { setNeedsLayout() } } }
    /// Only consulted with `scrollsHorizontally` (a plain scroll view always scrolls vertically).
    public var scrollsVertically = true { didSet { if scrollsVertically != oldValue { setNeedsLayout() } } }
    private var interaction = ScrollbarInteraction()
    private var horizontalInteraction = ScrollbarInteraction(axis: .horizontal)
    private var contentDrag: (pointer: Vec2, offset: Vec2)?

    public init(_ content: Widget, name: String = "") {
        self.content = content
        super.init(name: name)
        clipsContent = true
        addChild(content)
    }

    public override var accessibilityRole: UIAccessibilityRole { .scrollView }

    /// Distance scrolled from the top, in points.
    public var offset: Float { scroll.offset }
    /// Distance scrolled from the left, in points.
    public var horizontalOffset: Float { horizontalScroll.offset }

    /// Scrolls to `offset`, clamped at the next layout pass (when the content length is known).
    public func scroll(to offset: Float) {
        pendingOffset = offset
        relayout()
    }

    /// Scrolls horizontally to `offset` (from the left), clamped at the next layout pass.
    public func scroll(toX offset: Float) {
        pendingHorizontalOffset = offset
        relayout()
    }

    private var pendingOffset: Float?
    private var pendingHorizontalOffset: Float?

    private func relayout() {
        context?.layoutDirty = true
        setNeedsDisplay()
    }

    public override func measureContent(width: Float?) -> Vec2 {
        content.measure(width: scrollsHorizontally ? nil : width)
    }

    public override func layoutChildren() {
        let viewport = contentRect
        guard scrollsHorizontally else {
            let height = content.measure(width: viewport.width).y
            scroll.setLengths(content: height, viewport: viewport.height)
            if let pending = pendingOffset {
                scroll.scroll(to: pending)
                pendingOffset = nil
            }
            content.layout(in: UIRect(x: viewport.x, y: viewport.y - snap(scroll.offset), width: viewport.width,
                                      height: max(height, viewport.height)))
            return
        }
        let width = max(content.measure(width: nil).x, viewport.width)
        let height = scrollsVertically ? max(content.measure(width: width).y, viewport.height) : viewport.height
        horizontalScroll.setLengths(content: width, viewport: viewport.width)
        scroll.setLengths(content: height, viewport: viewport.height)
        if let pending = pendingOffset {
            scroll.scroll(to: pending)
            pendingOffset = nil
        }
        if let pending = pendingHorizontalOffset {
            horizontalScroll.scroll(to: pending)
            pendingHorizontalOffset = nil
        }
        // With both bars showing, each stops short of the corner the other one runs into.
        let corner = scroll.canScroll && horizontalScroll.canScroll ? theme.scrollbarWidth + 2 : 0
        interaction.corner = corner
        horizontalInteraction.corner = corner
        content.layout(in: UIRect(x: viewport.x - snap(horizontalScroll.offset), y: viewport.y - snap(scroll.offset),
                                  width: width, height: height))
    }

    public override func scrollToReveal(_ rect: UIRect) -> Bool {
        let viewport = contentRect
        let top = rect.y - viewport.y + scroll.offset
        var moved = scroll.reveal(top, top + rect.height)
        if scrollsHorizontally {
            let left = rect.x - viewport.x + horizontalScroll.offset
            moved = horizontalScroll.reveal(left, left + rect.width) || moved
        }
        guard moved else { return false }
        relayout()
        return true
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        let viewport = contentRect
        guard scrollsHorizontally else {
            let result = interaction.handle(event, state: &scroll, viewport: viewport, theme: theme, dragContent: true)
            if result.changed { relayout() }
            return result.handled
        }
        var handled = false, changed = false
        func run(_ event: UIEvent) {
            let v = interaction.handle(event, state: &scroll, viewport: viewport, theme: theme, dragContent: false)
            let h = horizontalInteraction.handle(event, state: &horizontalScroll, viewport: viewport, theme: theme,
                                                 dragContent: false)
            handled = handled || v.handled || h.handled
            changed = changed || v.changed || h.changed
        }
        switch event {
        case .scroll(var delta, let position):
            // Shift turns a plain wheel sideways (macOS already does this for mice, sending x).
            if delta.x == 0, context?.modifiers.contains(.shift) == true, horizontalScroll.canScroll {
                delta = Vec2(delta.y, 0)
            }
            run(.scroll(delta: delta, position: position))
        case .pointerDown(let e) where e.button == .left:
            run(event)
            if !handled && (scroll.canScroll || horizontalScroll.canScroll) {
                contentDrag = (e.position, Vec2(horizontalScroll.offset, scroll.offset))
                handled = true
            }
        case .pointerDrag(let e):
            if let drag = contentDrag {
                let target = drag.offset - (e.position - drag.pointer)
                let x = horizontalScroll.scroll(to: target.x)
                let y = scroll.scroll(to: target.y)
                handled = true
                changed = x || y
            } else {
                run(event)
            }
        case .pointerUp:
            handled = contentDrag != nil
            contentDrag = nil
            run(event)
        default:
            break
        }
        if changed { relayout() }
        return handled
    }

    /// Whether `point` is over a scrollbar that can scroll.
    private func overScrollbar(_ point: Vec2) -> Bool {
        let viewport = contentRect
        if scroll.canScroll,
           ScrollbarInteraction.hitArea(for: viewport, theme: theme, corner: interaction.corner).contains(point) {
            return true
        }
        return scrollsHorizontally && horizontalScroll.canScroll
            && ScrollbarInteraction.hitArea(for: viewport, theme: theme, axis: .horizontal,
                                            corner: horizontalInteraction.corner).contains(point)
    }

    public override func hitTest(_ point: Vec2) -> Widget? {
        // The scrollbars sit above the content.
        if !isHidden, overScrollbar(point) { return self }
        guard !isHidden, contentRect.contains(point) || frame.contains(point) else { return nil }
        return super.hitTest(point)
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        let viewport = contentRect
        let pointer = context?.pointerPosition
        let hovered = pointer.map {
            ScrollbarInteraction.hitArea(for: viewport, theme: theme, corner: interaction.corner).contains($0)
        } ?? false
        interaction.draw(list, state: scroll, viewport: viewport, theme: theme, hovered: hovered)
        guard scrollsHorizontally else { return }
        let hoveredX = pointer.map {
            ScrollbarInteraction.hitArea(for: viewport, theme: theme, axis: .horizontal,
                                         corner: horizontalInteraction.corner).contains($0)
        } ?? false
        horizontalInteraction.draw(list, state: horizontalScroll, viewport: viewport, theme: theme, hovered: hoveredX)
    }
}
