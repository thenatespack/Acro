import Foundation

/// The timing of hover tooltips, free of widgets and clocks so it can be tested with injected
/// times. `UIContext` feeds it the tooltip target under the pointer every frame.
///
/// A new target waits `delay` seconds. Once a tooltip has been shown, moving to another target
/// (or to one within `switchWindow` of the last tooltip going away) shows it at once.
/// `dismiss` (a press, scroll or key) hides the tooltip at once; `UIContext` then keeps it
/// hidden until the pointer leaves that widget.
public struct TooltipController: Sendable {
    /// What the pointer is over: the widget that owns the tip and its text. A different text for
    /// the same widget (a tab's close button vs its title) is a different target.
    public struct Target: Equatable, Sendable {
        public var widget: ObjectIdentifier
        public var text: String

        public init(widget: ObjectIdentifier, text: String) {
            self.widget = widget
            self.text = text
        }
    }

    /// Seconds the pointer must rest on a target before its tooltip appears.
    public var delay: Double
    /// Seconds after a tooltip went away during which the next one appears without the delay.
    public var switchWindow: Double
    public private(set) var target: Target?
    public private(set) var isShown = false
    private var since: Double = 0
    private var lastShown = -Double.infinity

    public init(delay: Double = 0.5, switchWindow: Double = 0.4) {
        self.delay = delay
        self.switchWindow = switchWindow
    }

    /// Advances to `time` with the target now under the pointer (nil: none). Returns whether a
    /// tooltip for `target` is shown.
    @discardableResult
    public mutating func update(time: Double, target new: Target?) -> Bool {
        if new != target {
            let wasShown = isShown
            if wasShown { lastShown = time }
            target = new
            since = time
            isShown = new != nil && (wasShown || time - lastShown <= switchWindow)
        } else if target != nil, !isShown, time - since >= delay {
            isShown = true
        }
        if isShown { lastShown = time }
        return isShown
    }

    /// Hides the tooltip now. The next target switches without the delay if it comes soon enough.
    public mutating func dismiss(time: Double) {
        if isShown { lastShown = time }
        isShown = false
        target = nil
    }

    /// Forgets everything (the context is being dropped).
    public mutating func reset() {
        self = TooltipController(delay: delay, switchWindow: switchWindow)
    }
}

/// Size and placement of the tooltip box (window points).
public enum TooltipLayout {
    /// Gap from the pointer to the box's top-left corner when it sits below-right of it.
    public static let offset = Vec2(12, 18)
    /// Gap kept to the window's edges.
    public static let margin: Float = 4

    /// The text layout for `text`, wrapped so the box (padding included) is at most `theme.tooltipMaxWidth` wide.
    @MainActor
    public static func textLayout(_ text: String, theme: UITheme) -> TextLayout {
        TextLayout(text, font: theme.font, size: theme.tooltipFontSize,
                   maxWidth: max(20, theme.tooltipMaxWidth - 2 * theme.tooltipPadding.x))
    }

    /// The box around `layout`, with its width rounded up to whole pixels at `scale`.
    @MainActor
    public static func boxSize(for layout: TextLayout, theme: UITheme, scale: Float) -> Vec2 {
        Vec2((layout.width * scale).rounded(.up) / scale + 2 * theme.tooltipPadding.x,
             layout.height + 2 * theme.tooltipPadding.y)
    }

    /// Where a box of `size` goes for a pointer at `pointer`: below-right of it, flipped to the
    /// left / above when it would cross the right / bottom edge of `viewport`, then clamped inside it.
    public static func frame(size: Vec2, pointer: Vec2, viewport: UIRect) -> UIRect {
        var x = pointer.x + offset.x
        var y = pointer.y + offset.y
        if x + size.x > viewport.maxX - margin { x = pointer.x - 4 - size.x }
        if y + size.y > viewport.maxY - margin { y = pointer.y - 6 - size.y }
        x = min(x, viewport.maxX - margin - size.x)
        y = min(y, viewport.maxY - margin - size.y)
        x = max(x, viewport.x + margin)
        y = max(y, viewport.y + margin)
        return UIRect(x: x, y: y, width: size.x, height: size.y)
    }
}

/// Ellipsis truncation for single-line text.
public enum TextEllipsis {
    public static let mark = "\u{2026}"

    /// `text` cut to fit `width` points at `size` with a trailing "…", or nil when it already fits.
    public static func fit(_ text: String, font: Font, size: Float, width: Float) -> String? {
        let offsets = TextMetrics.caretOffsets(text, font: font, size: size)
        guard let total = offsets.last, total > width else { return nil }
        let room = width - (TextMetrics.caretOffsets(mark, font: font, size: size).last ?? 0)
        // The most Characters whose end still leaves room for the mark (offsets never decrease).
        let characters = offsets.count - 1
        var count = 0
        while count + 1 <= characters - 1 && offsets[count + 1] <= room { count += 1 }
        var prefix = String(text.prefix(count))
        while prefix.last == " " { prefix.removeLast() }
        return prefix + mark
    }
}
