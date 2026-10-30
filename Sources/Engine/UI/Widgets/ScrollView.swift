import Foundation

/// Vertical scrolling math shared by `ScrollView`, `ListView` and `TreeView`.
public struct ScrollState: Sendable, Equatable {
    /// Distance scrolled from the top, in points (0...maxOffset).
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

    /// The scrollbar thumb inside `track` (window points), or nil when nothing scrolls.
    public func thumb(in track: UIRect, minLength: Float = 20) -> UIRect? {
        guard canScroll, contentLength > 0 else { return nil }
        let length = min(track.height, max(minLength, track.height * viewportLength / contentLength))
        let y = track.y + (track.height - length) * (offset / maxOffset)
        return UIRect(x: track.x, y: y, width: track.width, height: length)
    }

    /// The offset that puts the thumb's top at `thumbTop` (dragging it).
    public func offset(forThumbTop thumbTop: Float, in track: UIRect, minLength: Float = 20) -> Float {
        guard let thumb = thumb(in: track, minLength: minLength) else { return 0 }
        let travel = track.height - thumb.height
        return travel > 0 ? (thumbTop - track.y) / travel * maxOffset : 0
    }
}

/// Handles the scrollbar and wheel parts of a vertically scrolling widget: the track along the
/// right edge of `viewport`, dragging the thumb, clicking the track to page, and the wheel.
@MainActor
struct ScrollbarInteraction {
    private var thumbGrab: Float?
    private var contentDrag: (pointerY: Float, offset: Float)?

    var isDragging: Bool { thumbGrab != nil || contentDrag != nil }

    static func track(for viewport: UIRect, theme: UITheme) -> UIRect {
        let w = theme.scrollbarWidth
        return UIRect(x: viewport.maxX - w - 2, y: viewport.y + 2, width: w, height: max(0, viewport.height - 4))
    }

    /// The area that grabs the scrollbar (a bit wider than the thumb).
    static func hitArea(for viewport: UIRect, theme: UITheme) -> UIRect {
        let w = theme.scrollbarWidth + 6
        return UIRect(x: viewport.maxX - w, y: viewport.y, width: w, height: viewport.height)
    }

    /// Returns true when the event was consumed; `changed` reports offset changes.
    mutating func handle(_ event: UIEvent, state: inout ScrollState, viewport: UIRect, theme: UITheme,
                         dragContent: Bool) -> (handled: Bool, changed: Bool) {
        switch event {
        case .scroll(let delta, _):
            guard state.canScroll, delta.y != 0 else { return (false, false) }
            let changed = state.scroll(to: state.offset - delta.y)
            // At an edge, let an outer scroller have it.
            return (changed, changed)
        case .pointerDown(let e) where e.button == .left:
            guard state.canScroll else { return (false, false) }
            let track = Self.track(for: viewport, theme: theme)
            if Self.hitArea(for: viewport, theme: theme).contains(e.position), let thumb = state.thumb(in: track) {
                if e.position.y >= thumb.y && e.position.y < thumb.maxY {
                    thumbGrab = e.position.y - thumb.y
                    return (true, false)
                }
                // Page towards the click.
                let page = state.viewportLength * 0.9
                let changed = state.scroll(to: state.offset + (e.position.y < thumb.y ? -page : page))
                thumbGrab = nil
                return (true, changed)
            }
            if dragContent {
                contentDrag = (e.position.y, state.offset)
                return (true, false)
            }
            return (false, false)
        case .pointerDrag(let e):
            if let grab = thumbGrab {
                let track = Self.track(for: viewport, theme: theme)
                return (true, state.scroll(to: state.offset(forThumbTop: e.position.y - grab, in: track)))
            }
            if let drag = contentDrag {
                return (true, state.scroll(to: drag.offset - (e.position.y - drag.pointerY)))
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
        let track = Self.track(for: viewport, theme: theme)
        guard let thumb = state.thumb(in: track) else { return }
        let active = isDragging || hovered
        list.fillRect(thumb, color: active ? theme.scrollbarThumbActive : theme.scrollbarThumb,
                      radii: UICornerRadii(thumb.width / 2))
    }
}

/// Shows a part of a taller `content` widget and scrolls it vertically: mouse wheel /
/// trackpad, dragging the scrollbar thumb, clicking the track (pages), or dragging empty parts
/// of the content. Content is laid out at the viewport's width and its measured height, and
/// clipped to the padded frame. Focusing a widget inside with the keyboard scrolls it into view.
/// Give the scroll view a size (`style.height`, or `grow` in a column); its measured height is the content's.
public final class ScrollView: Widget {
    public let content: Widget
    public private(set) var scroll = ScrollState()
    private var interaction = ScrollbarInteraction()

    public init(_ content: Widget, name: String = "") {
        self.content = content
        super.init(name: name)
        clipsContent = true
        addChild(content)
    }

    /// Distance scrolled from the top, in points.
    public var offset: Float { scroll.offset }

    /// Scrolls to `offset`, clamped at the next layout pass (when the content length is known).
    public func scroll(to offset: Float) {
        pendingOffset = offset
        relayout()
    }

    private var pendingOffset: Float?

    private func relayout() {
        context?.layoutDirty = true
        setNeedsDisplay()
    }

    public override func measureContent(width: Float?) -> Vec2 {
        content.measure(width: width)
    }

    public override func layoutChildren() {
        let viewport = contentRect
        let height = content.measure(width: viewport.width).y
        scroll.setLengths(content: height, viewport: viewport.height)
        if let pending = pendingOffset {
            scroll.scroll(to: pending)
            pendingOffset = nil
        }
        content.layout(in: UIRect(x: viewport.x, y: viewport.y - snap(scroll.offset), width: viewport.width,
                                  height: max(height, viewport.height)))
    }

    public override func scrollToReveal(_ rect: UIRect) -> Bool {
        let viewport = contentRect
        let top = rect.y - viewport.y + scroll.offset
        guard scroll.reveal(top, top + rect.height) else { return false }
        relayout()
        return true
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        let result = interaction.handle(event, state: &scroll, viewport: contentRect, theme: theme, dragContent: true)
        if result.changed { relayout() }
        return result.handled
    }

    public override func hitTest(_ point: Vec2) -> Widget? {
        // The scrollbar sits above the content.
        if !isHidden, scroll.canScroll, ScrollbarInteraction.hitArea(for: contentRect, theme: theme).contains(point) {
            return self
        }
        guard !isHidden, contentRect.contains(point) || frame.contains(point) else { return nil }
        return super.hitTest(point)
    }

    public override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        let viewport = contentRect
        let hovered = context.map { ScrollbarInteraction.hitArea(for: viewport, theme: theme).contains($0.pointerPosition) } ?? false
        interaction.draw(list, state: scroll, viewport: viewport, theme: theme, hovered: hovered)
    }
}
