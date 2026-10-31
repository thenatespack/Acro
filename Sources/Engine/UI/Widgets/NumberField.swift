import Foundation

/// A number shown in a box that is edited by dragging or typing, the inspector's basic control.
///
/// - **Scrub:** press and drag horizontally. Moving 3 points starts the drag (a click that
///   barely moves doesn't); then each point moves the value by `scrubRate`, which scales with
///   the field: half a `step` per point when `step` is set, a 200th of the `range` per point
///   (a 400th of it at least, with a step), 0.05 / 0.5 for an unbounded float / int. **Shift** drags
///   at a tenth of that (fine), **Alt / Option** at ten times (coarse); the modifiers apply to
///   each move, so they can change mid-drag. Esc during a drag restores the start value.
///   Floats are rounded to the display `precision`, integers to whole numbers, and the value is
///   clamped to `range`.
/// - **Type:** a click (press and release without a drag), Enter or F2 swaps the field for a text
///   field holding the exact value, selected. Enter commits and keeps the keyboard focus on the
///   field; Esc cancels; leaving the field (a click elsewhere, Tab) commits. Text that isn't a
///   finite number reverts to the old value; a number is clamped to `range` (and rounded to a
///   whole number in `isInteger` mode).
/// - **Nudge:** with the field focused, Up / Down add / subtract `step` (1 for integers, 0.1 for
///   unbounded floats, a 100th of the range otherwise); Shift = a tenth, Alt = ten times.
///
/// ## Edit callbacks (designed for undo)
///
/// One user gesture is `onEditBegan(start)`, then `onChange(value)` for every new value, then
/// `onEditEnded(start, end)`. A scrub spans the whole drag, so an editor can record one undo step
/// `(start, end)` when it ends (and skip it when `start == end`); a typed value or an arrow
/// nudge is a complete gesture delivered at once (began, changed, ended). A cancelled scrub ends
/// with `start == end` after an `onChange(start)` that restored the value. Nothing is called
/// for `setValue`, so a model can be pushed into the field freely, and `setValue` is ignored
/// while the user is editing the field (so a per-frame refresh can't fight a drag or typing).
///
/// TODO(cursor): ask the platform for a horizontal-resize cursor while the pointer is over the
/// field / scrubbing, once `Input` / `Window` has a cursor API (the other agent's work). The two
/// places are `isHovered` and `isScrubbing` in `draw`.
public final class NumberField: Widget {
    public private(set) var value: Double
    /// Whole numbers only: scrubbing and typing round.
    public var isInteger: Bool { didSet { if isInteger != oldValue { refreshText() } } }
    /// Bounds for scrubbing, nudging and typing (a value set with `setValue` may be outside).
    public var range: ClosedRange<Double>?
    /// The increment of the arrow keys and the basis of the scrub rate; 0 picks one from the range / type.
    public var step: Double = 0
    /// Decimals shown for floats; nil shows as many as `step` needs, at least 3.
    public var precision: Int? { didSet { if precision != oldValue { refreshText() } } }
    /// A short label drawn at the left inside the box (an axis letter), in `prefixColor`.
    public var prefix: String? { didSet { setNeedsDisplay() } }
    public var prefixColor: UIColor? { didSet { setNeedsDisplay() } }
    /// Colors the prefix with the theme's `axisColors[prefixAxis]` when `prefixColor` is nil.
    public var prefixAxis: Int? { didSet { setNeedsDisplay() } }
    /// Minimum width when measured (points).
    public var preferredWidth: Float = 64 { didSet { setNeedsLayout() } }

    /// A gesture starts; `start` is the value before it. Not called for a drag that never moved.
    public var onEditBegan: ((_ start: Double) -> Void)?
    /// The value changed through the user (continuously while scrubbing).
    public var onChange: ((Double) -> Void)?
    /// The gesture is over; `start` and `end` are the values before and after.
    public var onEditEnded: ((_ start: Double, _ end: Double) -> Void)?

    public private(set) var isScrubbing = false
    public private(set) var isTyping = false
    /// The user is dragging, typing or about to (pressed but not yet moved): `setValue` waits.
    public var isInteracting: Bool { isScrubbing || isTyping || press != nil }

    /// Scrub speed multipliers for Shift and Alt / Option.
    public static let fineScale = 0.1
    public static let coarseScale = 10.0
    /// Points the pointer must move before a press becomes a scrub.
    public static let scrubThreshold: Float = 3

    private var press: (position: Vec2, lastX: Float)?
    private var scrubValue = 0.0
    private var startValue = 0.0
    private var textField: TextField?
    private var text = ""
    private var layoutCache = CachedTextLayout()
    private var prefixCache = CachedTextLayout()

    public init(value: Double = 0, isInteger: Bool = false, range: ClosedRange<Double>? = nil, step: Double = 0,
                name: String = "") {
        self.value = value
        self.isInteger = isInteger
        self.range = range
        self.step = step
        super.init(name: name)
        refreshText()
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { .numberField }
    /// In a `VectorField`: its label and the axis ("Position X"); else the axis prefix, if any.
    public override var accessibilityText: String? {
        guard let prefix else { return nil }
        return (parent as? VectorField)?.effectiveAccessibilityLabel.map { "\($0) \(prefix)" } ?? prefix
    }
    public override var accessibilityValue: String? { text }

    // MARK: Value

    /// Decimals actually shown (0 for integers).
    public var effectivePrecision: Int {
        if isInteger { return 0 }
        if let precision { return min(max(precision, 0), 8) }
        guard step > 0, step < 1 else { return 3 }
        return min(max(3, Int((-log10(step)).rounded(.up))), 8)
    }

    /// Arrow-key increment.
    public var effectiveStep: Double {
        if step > 0 { return step }
        if let range, range.upperBound > range.lowerBound, !isInteger { return (range.upperBound - range.lowerBound) / 100 }
        return isInteger ? 1 : 0.1
    }

    /// Sets the value without callbacks and without clamping. Ignored while the user is editing.
    public func setValue(_ newValue: Double) {
        guard !isInteracting, newValue != value else { return }
        value = newValue
        refreshText()
    }

    /// Clamps to `range`, rounds integers to whole numbers and (with `roundToPrecision`) floats to the display decimals.
    public func quantize(_ v: Double, roundToPrecision: Bool = false) -> Double {
        var v = v.isFinite ? v : value
        if let range { v = min(max(v, range.lowerBound), range.upperBound) }
        if isInteger {
            v = v.rounded()
        } else if roundToPrecision {
            let scale = pow(10, Double(effectivePrecision))
            v = (v * scale).rounded() / scale
        }
        if let range { v = min(max(v, range.lowerBound), range.upperBound) }
        return v == 0 ? 0 : v  // no negative zero
    }

    /// Value change per point of horizontal drag for a field with these settings (see the type's docs).
    public static func scrubRate(step: Double, range: ClosedRange<Double>?, isInteger: Bool, modifiers: KeyModifiers = []) -> Double {
        let span = range.map { $0.upperBound - $0.lowerBound } ?? .infinity
        var base: Double
        if step > 0 {
            base = step / 2
            if span.isFinite, span > 0 { base = max(base, span / 400) }
        } else if span.isFinite, span > 0 {
            base = span / 200
        } else {
            base = isInteger ? 0.5 : 0.05
        }
        if isInteger { base = max(base, 0.25) }
        if modifiers.contains(.shift) { base *= fineScale }
        if modifiers.contains(.alt) { base *= coarseScale }
        return base
    }

    /// `v` as shown while idle: integers plain, floats with `effectivePrecision` decimals.
    public func displayString(for v: Double) -> String {
        if isInteger { return v.isFinite ? String(Int(max(min(v, 9e18), -9e18).rounded())) : "0" }
        var s = String(format: "%.\(effectivePrecision)f", v)
        if s.hasPrefix("-"), !s.contains(where: { $0 != "-" && $0 != "0" && $0 != "." }) { s.removeFirst() }
        return s
    }

    /// `v` as put in the text field: every digit that matters (up to 6 decimals), no trailing zeros.
    private func editString(for v: Double) -> String {
        if isInteger { return displayString(for: v) }
        var s = String(format: "%.6f", v)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s == "-0" ? "0" : s
    }

    private func refreshText() {
        let new = displayString(for: value)
        if new != text {
            text = new
            setNeedsDisplay()
        }
    }

    // MARK: Gestures

    private func apply(_ new: Double) {
        guard new != value else { return }
        value = new
        refreshText()
        onChange?(new)
    }

    /// A whole gesture at once (typing, nudging).
    private func commit(_ new: Double) {
        guard new != value else { return }
        let old = value
        onEditBegan?(old)
        apply(new)
        onEditEnded?(old, value)
    }

    private func scrubMoved(to x: Float, modifiers: KeyModifiers) {
        guard var press else { return }
        let dx = Double(x - press.lastX)
        press.lastX = x
        self.press = press
        scrubValue += dx * Self.scrubRate(step: step, range: range, isInteger: isInteger, modifiers: modifiers)
        if let range { scrubValue = min(max(scrubValue, range.lowerBound), range.upperBound) }
        apply(quantize(scrubValue, roundToPrecision: true))
    }

    private func finishScrub() {
        guard isScrubbing else { return }
        isScrubbing = false
        onEditEnded?(startValue, value)
        setNeedsDisplay()
    }

    private func cancelScrub() {
        guard isScrubbing else { return }
        press = nil
        apply(startValue)
        finishScrub()
    }

    // MARK: Typing

    /// Replaces the box with a text field holding the exact value, selected.
    public func beginTyping() {
        guard isEffectivelyEnabled, let context, !isTyping else { return }
        let field: TextField
        if let existing = textField {
            field = existing
        } else {
            field = TextField(name: name.isEmpty ? "" : "\(name).text")
            field.onSubmit = { [weak self] text in self?.endTyping(commit: text, refocus: true) }
            field.onEndEditing = { [weak self] text in
                if self?.isTyping == true { self?.endTyping(commit: text, refocus: false) }
            }
            textField = field
            addChild(field)
        }
        isTyping = true
        field.text = editString(for: value)
        field.isHidden = false
        field.layout(in: frame)
        context.focus(field)
        field.select(0..<field.buffer.count)
        setNeedsDisplay()
    }

    /// Leaves typing: with `commit` text, applies it when it parses; nil cancels.
    private func endTyping(commit text: String?, refocus: Bool) {
        guard isTyping else { return }
        let hadFocus = textField?.isFocused ?? false
        isTyping = false
        textField?.isHidden = true
        if refocus && hadFocus { context?.focus(self) }
        setNeedsDisplay()
        guard let text, let parsed = Double(text.trimmingCharacters(in: .whitespaces)), parsed.isFinite else { return }
        commit(quantize(parsed))
    }

    public override func layoutChildren() {
        if isTyping { textField?.layout(in: frame) }
    }

    // MARK: Events

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            guard !isTyping else { return true }
            press = (e.position, e.position.x)
            scrubValue = value
            startValue = value
            return true
        case .pointerDrag(let e):
            guard let press else { return true }
            if !isScrubbing {
                guard abs(e.position.x - press.position.x) >= Self.scrubThreshold else { return true }
                isScrubbing = true
                onEditBegan?(startValue)
            }
            scrubMoved(to: e.position.x, modifiers: e.modifiers)
            return true
        case .pointerUp(let e):
            let wasPress = press != nil
            press = nil
            if isScrubbing {
                finishScrub()
            } else if wasPress, frame.contains(e.position) {
                beginTyping()
            }
            return true
        case .key(let e):
            return handleKey(e)
        default:
            return false
        }
    }

    private func handleKey(_ e: KeyEvent) -> Bool {
        if isTyping {
            guard e.key == .escape else { return false }
            endTyping(commit: nil, refocus: true)
            return true
        }
        if isScrubbing {
            if e.key == .escape { cancelScrub(); return true }
            return false
        }
        switch e.key {
        case .enter, .f2:
            guard !e.isRepeat, e.modifiers.isEmpty else { return false }
            beginTyping()
        case .up, .down:
            var delta = effectiveStep
            if e.modifiers.contains(.shift) { delta *= isInteger ? 1 : Self.fineScale }
            if e.modifiers.contains(.alt) { delta *= Self.coarseScale }
            commit(quantize(value + (e.key == .up ? delta : -delta), roundToPrecision: true))
        default:
            return false
        }
        return true
    }

    // MARK: Drawing

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(preferredWidth, theme.controlHeight)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let active = isScrubbing || isFocused
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: enabled ? theme.fieldBackground : theme.fieldBackground.fading(0.5), radii: radii)
        list.strokeRect(frame, color: active ? theme.accent : (isHovered && enabled) ? theme.controlBorder.mixed(with: .white, 0.15)
                        : theme.controlBorder, width: active ? theme.borderWidth + 0.5 : theme.borderWidth, radii: radii)
        guard !isTyping else { return }
        var content = frame.inset(by: EdgeInsets(horizontal: 6, vertical: 0))
        let size = theme.fontSize
        if let prefix, !prefix.isEmpty {
            let axisColor = prefixAxis.flatMap { theme.axisColors.isEmpty ? nil : theme.axisColors[$0 % theme.axisColors.count] }
            let color = (prefixColor ?? axisColor ?? theme.secondaryTextColor).withAlpha(enabled ? 1 : 0.5)
            let bar = UIRect(x: frame.x + 1, y: frame.y + 3, width: 2, height: max(0, frame.height - 6))
            list.fillRect(bar, color: color, radii: UICornerRadii(1))
            let layout = prefixCache.get(prefix, font: theme.font, size: theme.smallFontSize)
            drawLine(layout, font: theme.font, in: UIRect(x: frame.x + 7, y: frame.y, width: layout.width, height: frame.height),
                     color: color, list: list)
            let used = 7 + layout.width + 2 - 6
            content = UIRect(x: content.x + used, y: content.y, width: max(0, content.width - used), height: content.height)
        }
        let shown = fittedText(width: content.width, size: size)
        let layout = layoutCache.get(shown, font: theme.font, size: size)
        let color = !enabled ? theme.disabledTextColor : isScrubbing ? .white : theme.textColor
        list.withClip(UIRect(x: frame.x + 1, y: frame.y, width: frame.width - 2, height: frame.height)) {
            if overflows(layout, width: content.width) {
                drawEllipsized(shown, layout: layout, size: size, in: content, color: color, list: list)
            } else {
                drawLine(layout, font: theme.font, in: content, alignment: .center, color: color, list: list)
            }
        }
    }

    /// Where the number goes: inside the box, right of the prefix.
    private var textRect: UIRect {
        var content = frame.inset(by: EdgeInsets(horizontal: 6, vertical: 0))
        if let prefix, !prefix.isEmpty {
            let used = 7 + cachedLayout(prefix, size: theme.smallFontSize).width + 2 - 6
            content = UIRect(x: content.x + used, y: content.y, width: max(0, content.width - used), height: content.height)
        }
        return content
    }

    /// The text to draw in `width`: the value at its precision, else rounded to fewer decimals
    /// until it fits ("1.000" → "1.00" → "1.0" → "1"); what still doesn't fit is ellipsized.
    /// At most `decimalsLimit` (a `VectorField`'s shared precision) decimals, then fewer until it fits.
    private func fittedText(width: Float, size: Float) -> String {
        guard !isInteger else { return text }
        let limit = decimalsLimit?() ?? Int.max
        var decimals = effectivePrecision
        if limit >= decimals {
            guard overflows(cachedLayout(text, size: size), width: width) else { return text }
        } else {
            decimals = max(limit, 0) + 1
        }
        while decimals > 0 {
            decimals -= 1
            let s = Self.format(value, decimals: decimals)
            if !overflows(cachedLayout(s, size: size), width: width) { return s }
        }
        return text
    }

    /// `v` with `decimals` decimals, without a sign on zero ("-0.0" → "0.0").
    private static func format(_ v: Double, decimals: Int) -> String {
        var s = String(format: "%.\(decimals)f", v)
        if s.hasPrefix("-"), !s.contains(where: { $0 != "-" && $0 != "0" && $0 != "." }) { s.removeFirst() }
        return s
    }

    /// Caps the decimals shown while idle (the value may still drop more to fit). `VectorField`
    /// sets it so every component of a vector shows the same number of decimals.
    public var decimalsLimit: (() -> Int?)? { didSet { setNeedsDisplay() } }

    /// The most decimals (up to `effectivePrecision`) the value fits with in the box now; 0 for integers.
    public var decimalsThatFit: Int {
        guard !isInteger else { return 0 }
        let size = theme.fontSize, width = textRect.width
        var decimals = effectivePrecision
        while decimals > 0, overflows(cachedLayout(Self.format(value, decimals: decimals), size: size), width: width) {
            decimals -= 1
        }
        return decimals
    }

    /// What the box shows while idle at its current width (`text` with fewer decimals when
    /// narrow or when its `VectorField` shows fewer); `text` while typing.
    public var shownText: String {
        isTyping ? text : fittedText(width: textRect.width, size: theme.fontSize)
    }

    /// Whether the value is shown shorter than `text` (fewer decimals or ellipsized).
    public var isTextShortened: Bool {
        !isTyping && (overflows(cachedLayout(text, size: theme.fontSize), width: textRect.width)
            || fittedText(width: textRect.width, size: theme.fontSize) != text)
    }

    /// An explicit `tooltip`, else the full value while the box shows it shortened.
    public override func tooltip(at point: Vec2) -> String? {
        tooltip ?? (isTextShortened ? text : nil)
    }
}
