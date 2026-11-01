import Foundation

extension Widget {
    /// The context's theme, or the default one while detached.
    public var theme: UITheme { context?.theme ?? UITheme() }

    /// A cached single-line layout at the theme font (see `UIContext.textLayout`).
    func cachedLayout(_ text: String, size: Float) -> TextLayout {
        context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)
    }

    /// Draws one line of laid-out text vertically centered in `rect`, aligned horizontally.
    func drawLine(_ layout: TextLayout, font: Font, in rect: UIRect, alignment: TextAlignment = .left,
                  color: UIColor, list: UIDrawList) {
        let x: Float
        switch alignment {
        case .left: x = rect.x
        case .center: x = rect.x + (rect.width - layout.width) / 2
        case .right: x = rect.maxX - layout.width
        }
        list.drawText(layout, font: font, at: Vec2(x, rect.y + (rect.height - layout.height) / 2), color: color)
    }
}

extension Widget {
    /// Whether a line `layout` is wider than `width` (beyond a pixel of rounding slack).
    func overflows(_ layout: TextLayout, width: Float) -> Bool {
        layout.width > width + 1 / scale
    }

    /// Like `drawLine`, but text wider than `rect` ends in "…" instead of running past it.
    /// Returns whether it was truncated.
    @discardableResult
    func drawEllipsized(_ text: String, layout: TextLayout, size: Float, in rect: UIRect, alignment: TextAlignment = .left,
                        color: UIColor, list: UIDrawList) -> Bool {
        guard overflows(layout, width: rect.width) else {
            drawLine(layout, font: theme.font, in: rect, alignment: alignment, color: color, list: list)
            return false
        }
        let short = context?.ellipsizedText(text, size: size, width: rect.width)
            ?? TextEllipsis.fit(text, font: theme.font, size: size, width: rect.width) ?? text
        drawLine(cachedLayout(short, size: size), font: theme.font, in: rect, alignment: .left, color: color, list: list)
        return true
    }

    /// `text` when a single line of it at `size` overflows `width` (so it can be its own tooltip), else nil.
    func truncatedText(_ text: String, size: Float, width: Float) -> String? {
        overflows(cachedLayout(text, size: size), width: width) ? text : nil
    }
}

/// Caches a `TextLayout` until its inputs change, so static text isn't re-laid out every frame.
struct CachedTextLayout {
    private var key: (text: String, size: Float, maxWidth: Float?, alignment: TextAlignment, font: ObjectIdentifier)?
    private var layout: TextLayout?

    mutating func get(_ text: String, font: Font, size: Float, maxWidth: Float? = nil, alignment: TextAlignment = .left)
        -> TextLayout {
        if let key, let layout, key.text == text, key.size == size, key.maxWidth == maxWidth, key.alignment == alignment,
           key.font == ObjectIdentifier(font) {
            return layout
        }
        let made = TextLayout(text, font: font, size: size, maxWidth: maxWidth, alignment: alignment)
        key = (text, size, maxWidth, alignment, ObjectIdentifier(font))
        layout = made
        return made
    }
}

/// Character-boundary positions for single-line text.
public enum TextMetrics {
    /// The x offset (pixels at `size`) of every Character boundary in `text` laid out on one
    /// line: `count + 1` values, starting at 0. Matches `TextLayout`'s glyph placement (advance
    /// plus pair kerning per scalar), so a caret drawn at `offsets[i]` sits between the glyphs of
    /// Characters `i - 1` and `i`. Control characters take no space; tabs count as spaces.
    public static func caretOffsets(_ text: String, font: Font, size: Float) -> [Float] {
        // A Character starts where its first glyph is placed, i.e. after the kerning with the
        // glyph before it (as in TextLayout); the last boundary is the end of the last advance.
        var offsets: [Float] = []
        offsets.reserveCapacity(text.count + 1)
        var pen: Float = 0
        var previous: Font.Glyph?
        let space = font.glyph(for: " ")
        for character in text {
            var start: Float?
            for scalar in character.unicodeScalars {
                let glyph: Font.Glyph
                if scalar == " " || scalar == "\t" {
                    glyph = space
                } else if scalar.value >= 0x20, scalar.value != 0x7F {
                    glyph = font.glyph(for: scalar)
                } else {
                    continue
                }
                if let previous { pen += font.kerning(previous, glyph) * size }
                if start == nil { start = pen }
                pen += font.advance(of: glyph) * size
                previous = glyph
            }
            offsets.append(start ?? pen)
        }
        offsets.append(pen)
        return offsets
    }

    /// The boundary index whose offset is closest to `x`.
    public static func nearestBoundary(to x: Float, in offsets: [Float]) -> Int {
        guard offsets.count > 1 else { return 0 }
        // Offsets are non-decreasing: find the first boundary at or past x, then compare with the one before.
        var low = 0, high = offsets.count - 1
        while low < high {
            let mid = (low + high) / 2
            if offsets[mid] < x { low = mid + 1 } else { high = mid }
        }
        if low > 0, x - offsets[low - 1] <= offsets[low] - x { return low - 1 }
        return low
    }
}

/// Text roles: they pick the size and color from the theme.
public enum LabelRole: Sendable {
    case body, secondary, heading, caption
}

/// Static text. Single line by default; `wraps` breaks lines at the width the layout gives it.
public final class Label: Widget {
    public var text: String { didSet { if text != oldValue { setNeedsLayout() } } }
    public var role: LabelRole { didSet { setNeedsLayout() } }
    /// Overrides the role's color.
    public var color: UIColor? { didSet { setNeedsDisplay() } }
    /// Overrides the role's size (points).
    public var fontSize: Float? { didSet { setNeedsLayout() } }
    public var wraps = false { didSet { setNeedsLayout() } }
    public var alignment: TextAlignment = .left { didSet { setNeedsDisplay() } }
    /// An icon before the text, about 1.25 times the text size, in `iconColor` or the text's color.
    public var icon: VectorIcon? { didSet { if icon != oldValue { setNeedsLayout() } } }
    public var iconColor: UIColor? { didSet { setNeedsDisplay() } }
    /// A single-line label cut off to narrower than this (points) draws nothing rather than a
    /// few letters and "…"; its tooltip and accessibility text still have the whole text.
    public var minimumTruncatedWidth: Float = 0 { didSet { setNeedsDisplay() } }
    private var cache = CachedTextLayout()

    public init(_ text: String, role: LabelRole = .body, name: String = "") {
        self.text = text
        self.role = role
        super.init(name: name)
        isHitTestable = false
    }

    public override var accessibilityRole: UIAccessibilityRole { .label }
    public override var accessibilityText: String? { text }

    /// The text size it draws at (points): `fontSize`, the style's, else its role's.
    var effectiveFontSize: Float { size }

    private var size: Float {
        if let fontSize { return fontSize }
        let theme = theme
        if let size = theme.style(for: self).fontSize { return size }
        switch role {
        case .body, .secondary: return theme.fontSize
        case .heading: return theme.headingFontSize
        case .caption: return theme.smallFontSize
        }
    }

    private func textColor(_ theme: UITheme) -> UIColor {
        if !isEffectivelyEnabled { return theme.disabledTextColor }
        if let color { return color }
        if let color = theme.style(for: self).textColor { return color }
        switch role {
        case .body, .heading: return theme.textColor
        case .secondary, .caption: return theme.secondaryTextColor
        }
    }

    /// The icon's edge (0 without one) and the gap after it.
    private var iconSpace: (edge: Float, gap: Float) {
        icon == nil ? (0, 0) : ((size * 1.25).rounded(), (size * 0.4).rounded())
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let (edge, gap) = iconSpace
        let layout = cache.get(text, font: theme.font, size: size, maxWidth: wraps ? width.map { $0 - edge - gap } : nil)
        // Round the width up to whole pixels so laying out at the snapped width doesn't re-wrap.
        return Vec2((layout.width * scale).rounded(.up) / scale + edge + gap, max(layout.height, edge))
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        var content = contentRect
        if minimumTruncatedWidth > 0, content.width < minimumTruncatedWidth, isTruncated { return }
        if let icon {
            let (edge, gap) = iconSpace
            let y = wraps ? content.y + (theme.lineHeight(size) - edge) / 2 : content.center.y - edge / 2
            list.drawIcon(icon, in: UIRect(x: content.x, y: y, width: edge, height: edge),
                          color: isEffectivelyEnabled ? iconColor ?? textColor(theme) : theme.disabledTextColor)
            content.x += edge + gap
            content.width = max(0, content.width - edge - gap)
        }
        if wraps {
            let layout = cache.get(text, font: theme.font, size: size, maxWidth: content.width + 0.5 / scale,
                                   alignment: alignment)
            list.drawText(layout, font: theme.font, at: Vec2(content.x, content.y + (content.height - layout.height) / 2),
                          color: textColor(theme))
        } else {
            let layout = cache.get(text, font: theme.font, size: size)
            drawEllipsized(text, layout: layout, size: size, in: content, alignment: alignment, color: textColor(theme),
                           list: list)
        }
    }

    /// Whether a single-line label is cut off at its current width.
    public var isTruncated: Bool {
        let (edge, gap) = iconSpace
        return !wraps && truncatedText(text, size: size, width: max(0, contentRect.width - edge - gap)) != nil
    }

    /// An explicit `tooltip`, else the full text while it is truncated.
    public override func tooltip(at point: Vec2) -> String? {
        tooltip ?? (isTruncated ? text : nil)
    }

    /// Labels let the pointer through unless they have something to show on hover.
    public override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point), tooltip != nil || isTruncated else { return nil }
        return self
    }
}

/// A thin horizontal or vertical line (`axis` is its direction).
public final class Separator: Widget {
    public var axis: Axis

    public init(_ axis: Axis = .horizontal) {
        self.axis = axis
        super.init(name: "separator")
        isHitTestable = false
    }

    public override var accessibilityRole: UIAccessibilityRole { .separator }

    public override func measureContent(width: Float?) -> Vec2 {
        axis == .horizontal ? Vec2(0, 1) : Vec2(1, 0)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.panelBorder)
    }
}

/// A push button. Click (press and release inside), Enter or Space runs `action`.
public final class Button: Widget {
    public enum Role: Sendable {
        case normal
        /// Accent-colored, for the main action.
        case primary
    }

    public var title: String { didSet { if title != oldValue { setNeedsLayout() } } }
    public var role: Role { didSet { setNeedsDisplay() } }
    public var action: (() -> Void)?
    /// An icon before the title (`theme.iconSize`, in the title's color: dimmed when disabled,
    /// `accentText` on a primary button).
    public var icon: VectorIcon? { didSet { if icon != oldValue { setNeedsLayout() } } }
    /// False shows only the icon (a square button). The title stays the button's accessibility
    /// label and becomes its tooltip unless it has one.
    public var showsTitle = true { didSet { if showsTitle != oldValue { setNeedsLayout() } } }
    private var cache = CachedTextLayout()

    public init(_ title: String, role: Role = .normal, name: String = "", action: (() -> Void)? = nil) {
        self.title = title
        self.role = role
        self.action = action
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { .button }
    public override var accessibilityText: String? { title }

    /// Runs the action as if clicked.
    public func activate() {
        action?()
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        let style = theme.style(for: self)
        let height = style.height ?? theme.controlHeight
        if icon != nil && !showsTitle {
            // Square (wider when the control is too short for the icon and a margin).
            return Vec2(max(height, theme.iconSize + 10), height)
        }
        let layout = cache.get(title, font: theme.font, size: style.fontSize ?? theme.fontSize)
        return Vec2((layout.width * scale).rounded(.up) / scale + 2 * (style.paddingX ?? theme.controlPaddingX) + iconSpace(theme),
                    height)
    }

    /// Room the icon takes before the title (icon and gap), 0 without one.
    private func iconSpace(_ theme: UITheme) -> Float {
        icon == nil ? 0 : theme.iconSize + theme.spacing
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) { activate() }
            return true
        case .key(let e) where (e.key == .enter || e.key == .space) && !e.isRepeat && e.modifiers.isEmpty:
            activate()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let style = theme.style(for: self)
        let fill: UIColor
        let border: UIColor
        switch role {
        case .normal:
            let background = style.background ?? theme.controlBackground
            fill = !enabled ? background.fading(0.5)
                : isPressed ? style.pressedBackground ?? theme.controlPressed
                : isHovered ? style.hoverBackground ?? theme.controlHover : background
            border = style.borderColor ?? theme.controlBorder
        case .primary:
            let accent = style.accent ?? theme.accent
            fill = !enabled ? accent.fading(0.35)
                : isPressed ? style.pressedBackground ?? theme.accentPressed
                : isHovered ? style.hoverBackground ?? theme.accentHover : accent
            border = fill
        }
        let radii = UICornerRadii(style.cornerRadius ?? theme.cornerRadius)
        list.fillRect(frame, color: fill, radii: radii)
        if role == .normal { list.strokeRect(frame, color: border, width: style.borderWidth ?? theme.borderWidth, radii: radii) }
        let color = !enabled ? theme.disabledTextColor
            : role == .primary ? theme.accentText : style.textColor ?? theme.textColor
        let size = style.fontSize ?? theme.fontSize
        if let icon {
            let edge = theme.iconSize
            if !showsTitle {
                list.drawIcon(icon, in: UIRect(x: frame.center.x - edge / 2, y: frame.center.y - edge / 2, width: edge, height: edge),
                              color: color)
                return
            }
            // Icon and title centered together; the title gives way first.
            let layout = cache.get(title, font: theme.font, size: size)
            let rect = titleRect
            let textWidth = min((layout.width * scale).rounded(.up) / scale, max(0, rect.width - iconSpace(theme)))
            let x = snap(max(rect.x, rect.center.x - (edge + theme.spacing + textWidth) / 2))
            list.drawIcon(icon, in: UIRect(x: x, y: frame.center.y - edge / 2, width: edge, height: edge), color: color)
            let textRect = UIRect(x: x + edge + theme.spacing, y: frame.y, width: max(0, rect.maxX - x - edge - theme.spacing),
                                  height: frame.height)
            if overflows(layout, width: textRect.width) {
                drawEllipsized(title, layout: layout, size: size, in: textRect, color: color, list: list)
            } else {
                drawLine(layout, font: theme.font, in: textRect, alignment: .left, color: color, list: list)
            }
            return
        }
        let layout = cache.get(title, font: theme.font, size: size)
        if overflows(layout, width: titleRect.width) {
            drawEllipsized(title, layout: layout, size: size, in: titleRect, color: color, list: list)
        } else {
            drawLine(layout, font: theme.font, in: frame, alignment: .center, color: color, list: list)
        }
    }

    /// Where the title goes: the frame less the horizontal padding. A longer title ends in "…".
    private var titleRect: UIRect {
        let paddingX = theme.style(for: self).paddingX ?? theme.controlPaddingX
        let inset = min(paddingX, max(0, frame.width / 2 - 2))
        return UIRect(x: frame.x + inset, y: frame.y, width: max(0, frame.width - 2 * inset), height: frame.height)
    }

    /// Whether the title is cut off (ellipsized) at the current width (never for an icon-only button).
    public var titleIsTruncated: Bool {
        guard showsTitle || icon == nil else { return false }
        let theme = theme
        let width = titleRect.width - iconSpace(theme)
        return truncatedText(title, size: theme.style(for: self).fontSize ?? theme.fontSize, width: max(0, width)) != nil
    }

    /// An explicit `tooltip`, else the full title while it is truncated or only the icon shows.
    public override func tooltip(at point: Vec2) -> String? {
        tooltip ?? (titleIsTruncated || (icon != nil && !showsTitle) ? title : nil)
    }
}

/// A labeled on/off control, drawn as a checkbox or a switch. Click, Enter or Space toggles it.
public final class Checkbox: Widget {
    public enum Kind: Sendable {
        case checkbox
        case toggleSwitch
    }

    public var title: String { didSet { if title != oldValue { setNeedsLayout() } } }
    public var isOn: Bool { didSet { if isOn != oldValue { setNeedsDisplay() } } }
    public var kind: Kind { didSet { setNeedsLayout() } }
    /// Called when the user toggles it (not when `isOn` is set in code).
    public var onChange: ((Bool) -> Void)?
    private var cache = CachedTextLayout()

    public init(_ title: String, isOn: Bool = false, kind: Kind = .checkbox, name: String = "",
                onChange: ((Bool) -> Void)? = nil) {
        self.title = title
        self.isOn = isOn
        self.kind = kind
        self.onChange = onChange
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { kind == .checkbox ? .checkbox : .toggle }
    public override var accessibilityText: String? { title }
    public override var accessibilityValue: String? { isOn ? "on" : "off" }

    public func toggle() {
        isOn.toggle()
        onChange?(isOn)
    }

    private func indicatorSize(_ theme: UITheme) -> Vec2 {
        kind == .checkbox ? Vec2(repeating: theme.checkboxSize) : theme.switchSize
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        let indicator = indicatorSize(theme)
        let layout = cache.get(title, font: theme.font, size: theme.fontSize)
        let textWidth = title.isEmpty ? 0 : theme.spacing + (layout.width * scale).rounded(.up) / scale
        // An untitled checkbox still takes clicks over `minimumHitSize` (the box stays at the left).
        return Vec2(max(indicator.x + textWidth, theme.minimumHitSize), max(indicator.y, theme.controlHeight, theme.minimumHitSize))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) { toggle() }
            return true
        case .key(let e) where (e.key == .enter || e.key == .space) && !e.isRepeat && e.modifiers.isEmpty:
            toggle()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let size = indicatorSize(theme)
        let box = UIRect(x: frame.x, y: snap(frame.y + (frame.height - size.y) / 2), width: size.x, height: size.y)
        let style = theme.style(for: self)
        let accent = isPressed ? theme.accentPressed : isHovered ? theme.accentHover : style.accent ?? theme.accent
        let off = isPressed ? theme.controlPressed : isHovered ? theme.controlHover : theme.controlBackground
        let alpha: Float = enabled ? 1 : 0.45
        switch kind {
        case .checkbox:
            let radii = UICornerRadii(theme.smallCornerRadius)
            if isOn {
                list.fillRect(box, color: accent.fading(alpha), radii: radii)
                // A check mark from two round-capped strokes.
                let s = size.x
                let a = Vec2(box.x + s * 0.24, box.y + s * 0.52)
                let b = Vec2(box.x + s * 0.43, box.y + s * 0.70)
                let c = Vec2(box.x + s * 0.76, box.y + s * 0.31)
                let color = theme.accentText.fading(alpha)
                list.drawLine(from: a, to: b, width: theme.checkmarkWidth, color: color, cap: .round)
                list.drawLine(from: b, to: c, width: theme.checkmarkWidth, color: color, cap: .round)
            } else {
                list.fillRect(box, color: off.fading(alpha), radii: radii)
                list.strokeRect(box, color: (style.borderColor ?? theme.controlBorder).fading(alpha),
                                width: style.borderWidth ?? theme.borderWidth, radii: radii)
            }
        case .toggleSwitch:
            let radii = UICornerRadii(size.y / 2)
            list.fillRect(box, color: (isOn ? accent : theme.trackBackground).fading(alpha), radii: radii)
            let knob = size.y - 4
            let knobX = isOn ? box.maxX - 2 - knob : box.x + 2
            list.fillRect(UIRect(x: knobX, y: box.y + 2, width: knob, height: knob), color: theme.thumb.fading(alpha),
                          radii: UICornerRadii(knob / 2))
        }
        if !title.isEmpty {
            let layout = cache.get(title, font: theme.font, size: theme.fontSize)
            let textRect = UIRect(x: box.maxX + theme.spacing, y: frame.y, width: frame.maxX - box.maxX - theme.spacing,
                                  height: frame.height)
            drawLine(layout, font: theme.font, in: textRect,
                     color: enabled ? style.textColor ?? theme.textColor : theme.disabledTextColor, list: list)
        }
    }
}

/// A horizontal slider over `range`. With `step` > 0 values snap to `range.lowerBound + k * step`.
/// Drag or click the track; arrows (or +/- a step, 1% without one), Page Up/Down (10 steps),
/// Home/End adjust it when focused. With directional navigation on (`UIContext.navigatesDirectionally`)
/// only Left / Right adjust it, so Up / Down move focus through a menu.
public final class Slider: Widget {
    public private(set) var value: Float
    public var range: ClosedRange<Float> { didSet { setValue(value) } }
    public var step: Float { didSet { setValue(value) } }
    /// Called when the user changes the value (not when it is set in code).
    public var onChange: ((Float) -> Void)?
    /// A pointer drag starts (before its first `onChange`) / ends. Keyboard changes call only `onChange`.
    public var onEditBegan: (() -> Void)?
    public var onEditEnded: (() -> Void)?
    private var dragging = false

    public init(value: Float, in range: ClosedRange<Float> = 0...1, step: Float = 0, name: String = "",
                onChange: ((Float) -> Void)? = nil) {
        self.range = range
        self.step = step
        self.value = range.lowerBound
        self.onChange = onChange
        super.init(name: name)
        setValue(value)
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { .slider }
    public override var accessibilityValue: String? { String(value) }

    /// Clamps to the range and snaps to the step.
    public func quantize(_ v: Float) -> Float {
        var v = min(max(v.isFinite ? v : range.lowerBound, range.lowerBound), range.upperBound)
        if step > 0 {
            v = range.lowerBound + ((v - range.lowerBound) / step).rounded() * step
            v = min(max(v, range.lowerBound), range.upperBound)
        }
        return v
    }

    /// Sets the value (clamped and snapped) without calling `onChange`.
    public func setValue(_ v: Float) {
        let q = quantize(v)
        if q != value {
            value = q
            setNeedsDisplay()
        }
    }

    private func userSet(_ v: Float) {
        let old = value
        setValue(v)
        if value != old { onChange?(value) }
    }

    /// The amount one arrow press moves the value.
    public var keyboardStep: Float { step > 0 ? step : (range.upperBound - range.lowerBound) / 100 }

    private func track(_ theme: UITheme) -> UIRect {
        let inset = theme.sliderThumbSize / 2
        return UIRect(x: frame.x + inset, y: frame.y + frame.height / 2, width: max(0, frame.width - 2 * inset), height: 0)
    }

    private var fraction: Float {
        let span = range.upperBound - range.lowerBound
        return span > 0 ? (value - range.lowerBound) / span : 0
    }

    private func value(atX x: Float) -> Float {
        let t = track(theme)
        let f = t.width > 0 ? min(max((x - t.x) / t.width, 0), 1) : 0
        return range.lowerBound + f * (range.upperBound - range.lowerBound)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(120, theme.controlHeight)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            dragging = true
            onEditBegan?()
            userSet(value(atX: e.position.x))
            return true
        case .pointerDrag(let e):
            userSet(value(atX: e.position.x))
            return true
        case .pointerUp:
            dragging = false
            setNeedsDisplay()
            onEditEnded?()
            return true
        case .key(let e):
            let big = e.modifiers.contains(.shift) ? 10 : 1 as Float
            if (e.key == .up || e.key == .down) && context?.navigatesDirectionally == true { return false }
            switch e.key {
            case .left, .down: userSet(value - keyboardStep * big)
            case .right, .up: userSet(value + keyboardStep * big)
            case .pageDown: userSet(value - keyboardStep * 10)
            case .pageUp: userSet(value + keyboardStep * 10)
            case .home: userSet(range.lowerBound)
            case .end: userSet(range.upperBound)
            default: return false
            }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let t = track(theme)
        let h = theme.sliderTrackHeight
        let trackRect = UIRect(x: t.x, y: snap(t.y - h / 2), width: t.width, height: h)
        list.fillRect(trackRect, color: theme.trackBackground, radii: UICornerRadii(h / 2))
        let filled = UIRect(x: trackRect.x, y: trackRect.y, width: t.width * fraction, height: h)
        let accent = theme.style(for: self).accent ?? theme.accent
        list.fillRect(filled, color: enabled ? accent : theme.trackBackground.mixed(with: .white, 0.15),
                      radii: UICornerRadii(h / 2))
        let s = theme.sliderThumbSize
        let thumb = UIRect(x: t.x + t.width * fraction - s / 2, y: snap(t.y - s / 2), width: s, height: s)
        let active = dragging || isHovered
        list.fillRect(thumb.offsetBy(Vec2(0, 1)), color: theme.shadow, radii: UICornerRadii(s / 2))
        list.fillRect(thumb, color: enabled ? (active ? .white : theme.thumb) : theme.thumb.fading(0.5),
                      radii: UICornerRadii(s / 2))
    }
}
