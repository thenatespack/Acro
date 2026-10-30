import Foundation

// Retained UI: a tree of `Widget`s owned by a `UIContext`. The context turns `Input` into
// events, lays the tree out when something changed, and paints it into a `UIDrawList`.
//
// Coordinates are window points (top-left origin, y down), the same space as
// `Input.mousePosition` and `UIDrawList`. Every widget's `frame` is absolute (not relative to
// its parent), so hit testing and painting need no transforms; a scroll view lays its content
// out shifted by the scroll offset. Layout snaps every edge to the pixel grid.

extension UIRect {
    public static let zero = UIRect(x: 0, y: 0, width: 0, height: 0)

    /// Whether `point` lies inside (the left/top edges are inside, the right/bottom ones are not).
    public func contains(_ point: Vec2) -> Bool {
        point.x >= x && point.x < maxX && point.y >= y && point.y < maxY
    }

    public func intersects(_ other: UIRect) -> Bool {
        x < other.maxX && other.x < maxX && y < other.maxY && other.y < maxY
    }

    public func inset(by insets: EdgeInsets) -> UIRect {
        UIRect(x: x + insets.left, y: y + insets.top, width: max(0, width - insets.horizontal),
               height: max(0, height - insets.vertical))
    }

    public func offsetBy(_ delta: Vec2) -> UIRect {
        UIRect(x: x + delta.x, y: y + delta.y, width: width, height: height)
    }
}

/// Space around content, in points.
public struct EdgeInsets: Sendable, Equatable {
    public var top, left, bottom, right: Float

    public init(top: Float = 0, left: Float = 0, bottom: Float = 0, right: Float = 0) {
        (self.top, self.left, self.bottom, self.right) = (top, left, bottom, right)
    }

    public init(_ all: Float) { self.init(top: all, left: all, bottom: all, right: all) }

    public init(horizontal: Float, vertical: Float) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    public static let zero = EdgeInsets(0)
    public var horizontal: Float { left + right }
    public var vertical: Float { top + bottom }
}

public enum Axis: Sendable {
    case horizontal, vertical
}

/// Pointer shapes a widget can ask for (`Widget.cursor(at:)`, `UIContext.desiredCursor`).
public enum UICursor: Sendable, Equatable {
    case arrow
    /// Over something clickable (links, tabs).
    case pointingHand
    /// Left-right arrows (a vertical divider, a window's left/right edge).
    case resizeLeftRight
    /// Up-down arrows (a horizontal divider, a window's top/bottom edge).
    case resizeUpDown
    /// Diagonal arrows for a top-left / bottom-right corner.
    case resizeDiagonal
    /// Diagonal arrows for a top-right / bottom-left corner.
    case resizeAntiDiagonal
    /// Moving something (dragging a floating panel).
    case move
}

/// Where children sit across a stack (and `alignSelf`).
public enum CrossAlignment: Sendable {
    case start, center, end
    /// Fill the stack's cross size (unless the child has a fixed size there).
    case stretch
}

/// How a stack places children along its axis when they don't fill it.
public enum MainAlignment: Sendable {
    case start, center, end
    /// Equal gaps between children (on top of `spacing`), none at the ends.
    case spaceBetween
}

/// Offsets from the parent's content edges for an absolutely positioned widget. On each axis:
/// both edges stretch it between them, one edge pins it there at its measured size, and
/// neither centers it.
public struct Anchors: Sendable, Equatable {
    public var left, top, right, bottom: Float?

    public init(left: Float? = nil, top: Float? = nil, right: Float? = nil, bottom: Float? = nil) {
        (self.left, self.top, self.right, self.bottom) = (left, top, right, bottom)
    }

    /// Stretched over the whole content rect, `inset` from each edge.
    public static func fill(inset: Float = 0) -> Anchors { Anchors(left: inset, top: inset, right: inset, bottom: inset) }
    public static let centered = Anchors()
}

public enum Positioning: Sendable, Equatable {
    /// Laid out by the parent (in sequence in a `Stack`, filling the content rect elsewhere).
    case flow
    /// Placed by anchors inside the parent's content rect, ignored by stack layout (overlays, badges, HUD corners).
    case absolute(Anchors)
}

/// Per-widget layout input. Sizes are points; nil width/height means "measure the content".
public struct LayoutStyle: Sendable, Equatable {
    public var width: Float?
    public var height: Float?
    public var minWidth: Float = 0
    public var maxWidth: Float = .infinity
    public var minHeight: Float = 0
    public var maxHeight: Float = .infinity
    /// Share of a stack's free space this widget takes along the stack's axis (0: none).
    public var grow: Float = 0
    /// How much this widget gives up when a stack overflows, weighted by its size (0: never; the default).
    public var shrink: Float = 0
    /// Overrides the parent stack's cross alignment.
    public var alignSelf: CrossAlignment?
    public var position: Positioning = .flow

    public init(width: Float? = nil, height: Float? = nil, minWidth: Float = 0, maxWidth: Float = .infinity,
                minHeight: Float = 0, maxHeight: Float = .infinity, grow: Float = 0, shrink: Float = 0,
                alignSelf: CrossAlignment? = nil, position: Positioning = .flow) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.grow = grow
        self.shrink = shrink
        self.alignSelf = alignSelf
        self.position = position
    }
}

/// A pointer event; `position` is in window points.
public struct PointerEvent: Sendable, Equatable {
    public var position: Vec2
    public var button: MouseButton
    public var modifiers: KeyModifiers
    /// 1 for a single click, 2 for a double click, … (pointer down/up only).
    public var clickCount: Int

    public init(position: Vec2, button: MouseButton = .left, modifiers: KeyModifiers = [], clickCount: Int = 1) {
        self.position = position
        self.button = button
        self.modifiers = modifiers
        self.clickCount = clickCount
    }
}

/// What widgets receive in `handleEvent`. Pointer down and scroll go to the widget under the
/// pointer, keys and text to the focused widget; each bubbles to the parent until a widget
/// returns true. The widget that handles a pointer down captures the pointer: it gets the
/// following `pointerDrag`s and the `pointerUp`, wherever the pointer goes.
public enum UIEvent: Sendable, Equatable {
    case pointerDown(PointerEvent)
    case pointerUp(PointerEvent)
    /// The pointer moved with no capture (hover); sent to the widget under it.
    case pointerMove(PointerEvent)
    /// The pointer moved while this widget has the capture.
    case pointerDrag(PointerEvent)
    /// Wheel / trackpad scroll in points (see `Input.scrollDelta`).
    case scroll(delta: Vec2, position: Vec2)
    /// A key press or repeat while the widget (or a descendant) has focus.
    case key(KeyEvent)
    /// Committed text for a widget that wants text input (`wantsTextInput`).
    case text(String)
}

/// The base of every retained UI element: a node in the tree with a frame, layout style,
/// visibility, enabled state, hit testing, event handling and painting.
///
/// Subclasses override:
/// - `measureContent(width:)` for their intrinsic size (padding excluded) and `layoutChildren()`
///   to place children (the default stacks flow children on top of each other, filling the content rect);
/// - `handleEvent(_:)` to react to input (return true when handled);
/// - `draw(_:theme:)` (below the children) and `drawForeground(_:theme:)` (above them).
///
/// Property changes that affect size call `setNeedsLayout()`; the next `UIContext` frame lays
/// out again. Painting happens every frame (the draw list is immediate), `setNeedsDisplay()`
/// only records that something visible changed (`UIContext.paintDirty`).
@MainActor
open class Widget {
    /// For debugging and lookup (`descendant(named:)`).
    public var name: String
    public private(set) weak var parent: Widget?
    public private(set) var children: [Widget] = []
    /// The context this widget is attached to (through its root or an overlay), if any.
    public internal(set) weak var context: UIContext?

    /// Absolute position and size in window points, set by layout (overlays and the root are
    /// placed by the context).
    public internal(set) var frame: UIRect = .zero

    public var style = LayoutStyle() { didSet { if style != oldValue { setNeedsLayout() } } }
    /// Space between the frame and the children / content.
    public var padding = EdgeInsets.zero { didSet { if padding != oldValue { setNeedsLayout() } } }
    /// Hidden widgets take no space, don't paint and aren't hit.
    public var isHidden = false {
        didSet {
            guard isHidden != oldValue else { return }
            setNeedsLayout()
            if isHidden { context?.widgetBecameUnavailable(self) }
        }
    }
    /// Disabled widgets (and their descendants) paint dimmed, can't be focused and don't receive
    /// events (events bubble past them to enabled ancestors).
    public var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            setNeedsDisplay()
            if !isEnabled { context?.widgetBecameUnavailable(self) }
        }
    }
    /// Whether the pointer can hit this widget itself (its children are tested either way).
    /// Turn it off for layout-only containers spanning areas the game should get clicks in.
    public var isHitTestable = true
    /// Clip children (and content) to the padded frame.
    public var clipsContent = false

    /// Text shown in a small box after the pointer rests on this widget (or a descendant without
    /// a tip of its own). See `tooltip(at:)` and `UIContext`.
    public var tooltip: String?

    /// Optional decoration painted by the default `draw`: a background, a border and a corner radius.
    public var background: UIColor? { didSet { setNeedsDisplay() } }
    public var borderColor: UIColor? { didSet { setNeedsDisplay() } }
    public var borderWidth: Float = 1 { didSet { setNeedsDisplay() } }
    public var cornerRadius: Float = 0 { didSet { setNeedsDisplay() } }

    /// Last `measure` result, keyed by the proposed width. Cleared by `setNeedsLayout`.
    private var measureCache: (width: Float?, size: Vec2)?

    public init(name: String = "") {
        self.name = name
    }

    // MARK: Behavior overridden by subclasses

    /// Whether this widget takes keyboard focus (on click and with Tab).
    open var acceptsFocus: Bool { false }
    /// A focused widget that answers true gets `.text` events and `Input.startTextInput` (with
    /// `textInputCaretRect`), and all keys arrive through the text input stream.
    open var wantsTextInput: Bool { false }
    /// The caret rectangle for the IME candidate window, in window points.
    open var textInputCaretRect: UIRect { frame }
    /// Draw the context's focus ring when focused by keyboard. Text fields draw their own focus state.
    open var showsFocusRing: Bool { true }

    /// Intrinsic size of the content, excluding padding. `width` is the proposed content width
    /// when the parent knows it (wrapping text uses it), nil otherwise.
    open func measureContent(width: Float?) -> Vec2 {
        var size = Vec2.zero
        for child in children where !child.isHidden && child.style.position == .flow {
            size = pointwiseMax(size, child.measure(width: width))
        }
        return size
    }

    /// Places the children inside `frame` (already set). The default fills the content rect
    /// with every flow child (they overlap) and places absolute children by their anchors.
    open func layoutChildren() {
        let content = contentRect
        for child in children where !child.isHidden {
            if case .absolute(let anchors) = child.style.position {
                child.layout(in: Self.anchoredFrame(for: child, anchors: anchors, in: content, snap: snap))
            } else {
                child.layout(in: content)
            }
        }
    }

    /// Return true when the event was handled (stops bubbling; a handled pointer down captures the pointer).
    open func handleEvent(_ event: UIEvent) -> Bool { false }

    /// Called when this widget gains or loses keyboard focus.
    open func focusChanged(_ focused: Bool) {}

    /// Paints the widget below its children. The default draws `background` and the border.
    open func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(cornerRadius)
        if let background, background.a > 0 { list.fillRect(frame, color: background, radii: radii) }
        if let borderColor, borderColor.a > 0, borderWidth > 0 {
            list.strokeRect(frame, color: borderColor, width: borderWidth, radii: radii)
        }
    }

    /// Paints above the children (scroll bars, overlaid decorations).
    open func drawForeground(_ list: UIDrawList, theme: UITheme) {}

    /// The deepest visible widget at `point`, or nil. Children are tested front to back (last child first).
    open func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point) else { return nil }
        for child in children.reversed() {
            if let hit = child.hitTest(point) { return hit }
        }
        return isHitTestable ? self : nil
    }

    /// Scrolls so that `rect` (window points, usually a descendant's frame) becomes visible, if
    /// this widget scrolls. Returns whether it did. Called up the ancestor chain when a widget
    /// receives keyboard focus.
    open func scrollToReveal(_ rect: UIRect) -> Bool { false }

    /// For a widget presented with `UIContext.presentOverlay`: where it goes in the viewport.
    /// The default centers its measured size, or applies `style.position` anchors.
    open func overlayFrame(in viewport: UIRect) -> UIRect {
        let anchors: Anchors
        if case .absolute(let a) = style.position { anchors = a } else { anchors = .centered }
        return Self.anchoredFrame(for: self, anchors: anchors, in: viewport, snap: snap)
    }

    /// Called after the context removed this overlay (outside click, Esc, or `dismissOverlay`).
    open func overlayDismissed() {}

    /// The pointer shape this widget wants at `point` while hovered or capturing the pointer
    /// (dividers ask for resize arrows), or nil to defer to its ancestors. See `UIContext.desiredCursor`.
    open func cursor(at point: Vec2) -> UICursor? { nil }

    /// The tooltip for the pointer at `point` (window points), or nil for none. The context asks
    /// the hovered widget and then each ancestor, and shows the first answer. Widgets with
    /// per-part tips (rows, a tab's close button) override it; the default is `tooltip`.
    open func tooltip(at point: Vec2) -> String? { tooltip }

    /// Called on the widget under the pointer and then each ancestor before a pointer down is
    /// dispatched, whether or not anyone handles it. Containers use it to react to any click
    /// inside them (a floating panel comes to the front).
    open func pointerWillPress(_ event: PointerEvent) {}

    // MARK: Derived state

    /// The padded frame: where children and content go.
    public var contentRect: UIRect { frame.inset(by: padding) }

    public var isFocused: Bool { context?.focusedWidget === self }
    /// The pointer is over this widget or one of its descendants (or this widget has the capture).
    public var isHovered: Bool { context?.isHovered(self) ?? false }
    /// This widget has the pointer captured and the pointer is over it (a button being clicked).
    public var isPressed: Bool {
        guard let context, context.capturedWidget === self else { return false }
        return frame.contains(context.pointerPosition)
    }
    /// Enabled, and every ancestor is too.
    public var isEffectivelyEnabled: Bool { isEnabled && (parent?.isEffectivelyEnabled ?? true) }
    /// Not hidden, and no ancestor is.
    public var isEffectivelyVisible: Bool { !isHidden && (parent?.isEffectivelyVisible ?? true) }

    public func isDescendant(of ancestor: Widget) -> Bool {
        var node: Widget? = self
        while let current = node {
            if current === ancestor { return true }
            node = current.parent
        }
        return false
    }

    /// The first descendant (depth first, self included) with `name`.
    public func descendant(named name: String) -> Widget? {
        if self.name == name { return self }
        for child in children {
            if let found = child.descendant(named: name) { return found }
        }
        return nil
    }

    // MARK: Tree

    public func addChild(_ child: Widget) {
        insertChild(child, at: children.count)
    }

    public func addChildren(_ widgets: [Widget]) {
        for widget in widgets { addChild(widget) }
    }

    public func insertChild(_ child: Widget, at index: Int) {
        precondition(child !== self && !isDescendant(of: child), "A widget can't contain itself")
        child.removeFromParent()
        children.insert(child, at: min(max(index, 0), children.count))
        child.parent = self
        child.attach(to: context)
        setNeedsLayout()
    }

    public func removeFromParent() {
        guard let parent else { return }
        context?.widgetBecameUnavailable(self)
        parent.children.removeAll { $0 === self }
        self.parent = nil
        attach(to: nil)
        parent.setNeedsLayout()
    }

    public func removeAllChildren() {
        for child in children { child.removeFromParent() }
    }

    /// Moves `child` to the end of `children`: painted last and hit first.
    public func bringChildToFront(_ child: Widget) {
        guard let index = children.firstIndex(where: { $0 === child }), index != children.count - 1 else { return }
        children.append(children.remove(at: index))
        setNeedsDisplay()
    }

    func attach(to context: UIContext?) {
        guard self.context !== context else { return }
        self.context = context
        for child in children { child.attach(to: context) }
    }

    // MARK: Invalidation

    /// Size or arrangement changed: drops cached measurements up the tree and asks the context
    /// for a layout pass before the next paint.
    public func setNeedsLayout() {
        var node: Widget? = self
        while let current = node {
            current.measureCache = nil
            node = current.parent
        }
        context?.layoutDirty = true
        context?.paintDirty = true
    }

    /// Only the appearance changed.
    public func setNeedsDisplay() {
        context?.paintDirty = true
    }

    // MARK: Layout

    /// The widget's preferred size including padding, honoring a fixed `style.width/height`
    /// and the min/max limits. Cached until `setNeedsLayout`.
    public func measure(width: Float? = nil) -> Vec2 {
        if let cache = measureCache, cache.width == width { return cache.size }
        let proposed = style.width ?? width
        let inner = measureContent(width: proposed.map { max(0, $0 - padding.horizontal) })
        var size = inner + Vec2(padding.horizontal, padding.vertical)
        if let w = style.width { size.x = w }
        if let h = style.height { size.y = h }
        size.x = min(max(size.x, style.minWidth), style.maxWidth)
        size.y = min(max(size.y, style.minHeight), style.maxHeight)
        measureCache = (width, size)
        return size
    }

    /// Sets the frame (snapped to the pixel grid) and lays out the children.
    public func layout(in rect: UIRect) {
        frame = snappedRect(rect)
        layoutChildren()
    }

    /// Framebuffer pixels per point of the context (1 when detached).
    public var scale: Float { context?.scale ?? 1 }

    /// Rounds a coordinate in points to the nearest framebuffer pixel.
    public func snap(_ value: Float) -> Float { UILayout.snap(value, scale: scale) }

    /// A rectangle whose four edges are snapped (so adjacent widgets never overlap or gap).
    public func snappedRect(_ rect: UIRect) -> UIRect {
        let x0 = snap(rect.x), y0 = snap(rect.y), x1 = snap(rect.maxX), y1 = snap(rect.maxY)
        return UIRect(x: x0, y: y0, width: max(0, x1 - x0), height: max(0, y1 - y0))
    }

    /// Where an absolutely positioned `child` goes inside `content` (see `Anchors`).
    static func anchoredFrame(for child: Widget, anchors: Anchors, in content: UIRect, snap: (Float) -> Float) -> UIRect {
        func axis(_ start: Float?, _ end: Float?, origin: Float, length: Float, measured: () -> Float) -> (Float, Float) {
            switch (start, end) {
            case let (s?, e?): return (origin + s, max(0, length - s - e))
            case let (s?, nil): return (origin + s, measured())
            case let (nil, e?): let m = measured(); return (origin + length - e - m, m)
            case (nil, nil): let m = measured(); return (origin + (length - m) / 2, m)
            }
        }
        let (x, width) = axis(anchors.left, anchors.right, origin: content.x, length: content.width) {
            child.measure(width: nil).x
        }
        let (y, height) = axis(anchors.top, anchors.bottom, origin: content.y, length: content.height) {
            child.measure(width: width).y
        }
        let clampedW = min(max(width, child.style.minWidth), child.style.maxWidth)
        let clampedH = min(max(height, child.style.minHeight), child.style.maxHeight)
        return UIRect(x: x, y: y, width: clampedW, height: clampedH)
    }

    // MARK: Painting

    /// Paints this widget and its subtree, skipping it when it lies outside the current clip.
    func paint(_ list: UIDrawList, theme: UITheme) {
        guard !isHidden, let clip = list.clipBounds else { return }
        // A little slack for strokes and shadows that extend past the frame.
        let slack: Float = 4
        let bounds = UIRect(x: frame.x - slack, y: frame.y - slack, width: frame.width + 2 * slack,
                            height: frame.height + 2 * slack)
        guard bounds.intersects(clip) else { return }
        draw(list, theme: theme)
        if clipsContent { list.pushClip(contentRect) }
        for child in children { child.paint(list, theme: theme) }
        if clipsContent { list.popClip() }
        drawForeground(list, theme: theme)
    }
}

/// An empty widget that takes free space in a stack (`grow` 1 by default).
public final class Spacer: Widget {
    public init(grow: Float = 1, minLength: Float = 0) {
        super.init(name: "spacer")
        style.grow = grow
        style.minWidth = minLength
        style.minHeight = minLength
        isHitTestable = false
    }
}
