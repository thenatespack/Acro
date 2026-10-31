import Foundation

// Game menu building blocks: a stack of screens with transitions, a centered menu screen and a
// gamepad-friendly option selector. Buttons, sliders and toggles are the regular controls; the
// "game" theme (`UITheme.game()`) sizes them for a TV. Modal questions use `ConfirmDialog`.

/// A stack of menu screens (pause → options → controls …): only the top one is shown and
/// navigable. `push` slides the new screen in and focuses its first focusable widget (or the
/// one given); `pop` slides back and restores the focus the screen below had. Esc / B (an
/// unhandled `.escape` key from a focused widget inside) pops, and at the root screen calls
/// `onBackAtRoot` (e.g. to resume the game). Each screen is a navigation scope, so the D-pad
/// never leaves it. It isn't hit-testable itself: put it over a dimmed backdrop if clicks
/// behind it should go nowhere.
@MainActor
public final class MenuStack: Widget {
    public enum Transition: Sendable {
        case none
        /// Slides `slideDistance` points sideways while cross-fading (forward to the left on push).
        case slide
        case fade
    }

    public private(set) var screens: [Widget] = []
    public var transition: Transition = .slide
    public var slideDistance: Float = 48
    /// Esc / B at the root screen. Nil leaves the key unhandled (the context then clears focus).
    public var onBackAtRoot: (() -> Void)?
    /// Called after the top screen changed (push, pop), with the new top.
    public var onChange: ((Widget) -> Void)?

    /// For each covered screen, the widget that had focus in it.
    private var savedFocus: [ObjectIdentifier: WeakWidget] = [:]
    private var animation: (incoming: Widget, outgoing: Widget?, forward: Bool, removesOutgoing: Bool, start: Double?)?

    public init(root: Widget? = nil, name: String = "menuStack") {
        super.init(name: name)
        isHitTestable = false
        if let root { push(root, animated: false) }
    }

    public var top: Widget? { screens.last }
    /// A transition is running.
    public var isAnimating: Bool { animation != nil }

    /// Shows `screen` above the current top and focuses `focus` (default: its first focusable widget).
    public func push(_ screen: Widget, focus: Widget? = nil, animated: Bool = true) {
        finishAnimation()
        let previous = top
        if let previous, let focused = context?.focusedWidget, focused.isDescendant(of: previous) {
            savedFocus[ObjectIdentifier(previous)] = WeakWidget(focused)
        }
        screen.isNavigationScope = true
        screen.isHidden = false
        screens.append(screen)
        addChild(screen)
        if let focus { savedFocus[ObjectIdentifier(screen)] = WeakWidget(focus) }
        begin(incoming: screen, outgoing: previous, forward: true, removesOutgoing: false, animated: animated)
        focusTop()
        onChange?(screen)
    }

    /// Removes the top screen (not the root) and returns it.
    @discardableResult
    public func pop(animated: Bool = true) -> Widget? {
        finishAnimation()
        guard screens.count > 1, let leaving = screens.popLast(), let below = top else { return nil }
        savedFocus[ObjectIdentifier(leaving)] = nil
        below.isHidden = false
        begin(incoming: below, outgoing: leaving, forward: false, removesOutgoing: true, animated: animated)
        focusTop()
        onChange?(below)
        return leaving
    }

    /// Pops everything above the root screen.
    public func popToRoot(animated: Bool = true) {
        while screens.count > 2 {
            let leaving = screens.removeLast()
            savedFocus[ObjectIdentifier(leaving)] = nil
            leaving.removeFromParent()
        }
        pop(animated: animated)
    }

    /// Focuses the top screen's saved focus, or its first focusable widget, with the focus ring.
    public func focusTop() {
        guard let context, let top else { return }
        context.layoutIfNeeded()
        let saved = savedFocus[ObjectIdentifier(top)]?.widget
        if let saved, saved.isDescendant(of: top), context.isFocusable(saved) {
            context.focus(saved, visible: true)
        } else if let first = context.focusableWidgets(in: top).first {
            context.focus(first, visible: true)
        }
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard case .key(let e) = event, e.key == .escape, !e.isRepeat else { return false }
        if screens.count > 1 {
            pop()
            return true
        }
        guard let onBackAtRoot else { return false }
        onBackAtRoot()
        return true
    }

    /// Only the top screen takes the pointer (a screen sliding out doesn't).
    public override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, frame.contains(point) else { return nil }
        return top?.hitTest(point)
    }

    // MARK: Transitions

    private func begin(incoming: Widget, outgoing: Widget?, forward: Bool, removesOutgoing: Bool, animated: Bool) {
        let duration = context?.theme.menuTransitionDuration ?? UITheme().menuTransitionDuration
        guard animated, transition != .none, duration > 0, let outgoing else {
            if let outgoing { retire(outgoing, remove: removesOutgoing) }
            return
        }
        // The start time is taken at the first paint, so a push before the first frame still animates.
        animation = (incoming, outgoing, forward, removesOutgoing, nil)
        apply(progress: 0)
    }

    private func finishAnimation() {
        guard let current = animation else { return }
        animation = nil
        reset(current.incoming)
        if let outgoing = current.outgoing { retire(outgoing, remove: current.removesOutgoing) }
    }

    private func retire(_ screen: Widget, remove: Bool) {
        reset(screen)
        if remove { screen.removeFromParent() } else { screen.isHidden = true }
    }

    private func reset(_ screen: Widget) {
        screen.visualOffset = .zero
        screen.opacity = 1
    }

    private func apply(progress t: Float) {
        guard let current = animation else { return }
        let eased = 1 - (1 - t) * (1 - t) * (1 - t)  // cubic ease-out
        let direction: Float = current.forward ? 1 : -1
        let slide = transition == .slide ? slideDistance : 0
        current.incoming.visualOffset = Vec2(snap((1 - eased) * slide * direction), 0)
        current.incoming.opacity = eased
        current.outgoing?.visualOffset = Vec2(snap(-eased * slide * direction), 0)
        current.outgoing?.opacity = 1 - eased
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        guard var current = animation, let context else { return }
        let start = current.start ?? context.time
        if current.start == nil {
            current.start = start
            animation = current
        }
        let duration = max(theme.menuTransitionDuration, 1e-3)
        let t = Float(min(max((context.time - start) / duration, 0), 1))
        if t >= 1 {
            finishAnimation()
        } else {
            apply(progress: t)
        }
        setNeedsDisplay()
    }
}

/// A menu screen: a centered card with a heading and a column of items (buttons, toggles,
/// selectors, slider rows), sized by the theme (`panelPadding`, `spacing`, `dialogCornerRadius`).
/// The card takes `width` points (clamped to the screen) and its measured height.
@MainActor
public final class MenuScreen: Widget {
    public let titleLabel: Label
    public let items: VStack
    public var width: Float { didSet { if width != oldValue { setNeedsLayout() } } }
    private let card: VStack

    public init(title: String, width: Float = 460, name: String = "", items: [Widget] = []) {
        self.width = width
        titleLabel = Label(title, role: .heading, name: "menuTitle")
        titleLabel.alignment = .center
        self.items = VStack(spacing: 8, name: "menuItems", items)
        card = VStack(spacing: 14, padding: EdgeInsets(18), name: "menuCard", [titleLabel, self.items])
        super.init(name: name.isEmpty ? title : name)
        isHitTestable = false
        addChild(card)
    }

    public func addItem(_ widget: Widget) { items.addChild(widget) }

    /// The card's frame (for decorations around it).
    public var cardFrame: UIRect { card.frame }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(self.width, card.measure(width: self.width).y)
    }

    public override func layoutChildren() {
        let theme = theme
        items.spacing = theme.spacing
        card.spacing = theme.spacing * 2
        card.padding = EdgeInsets(theme.panelPadding)
        let content = contentRect
        let w = min(width, content.width)
        let h = card.measure(width: w).y
        card.layout(in: UIRect(x: content.x + (content.width - w) / 2, y: content.y + (content.height - h) / 2,
                               width: w, height: h))
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let radii = UICornerRadii(theme.dialogCornerRadius)
        if theme.shadow.a > 0 {
            list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2),
                          radii: UICornerRadii(theme.dialogCornerRadius + 6))
        }
        list.fillRect(card.frame, color: theme.panelBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.panelBorder, width: theme.borderWidth, radii: radii)
    }
}

/// A "Title      < Medium >" control for picking one of a few options with a gamepad: Left /
/// Right (or the D-pad) step through `options`, Enter / Space / A step forward, clicking the
/// left or right half of the value steps back or forward. With `wraps` the ends wrap around;
/// otherwise the arrow at an end is dimmed.
@MainActor
public final class OptionSelector: Widget {
    public var title: String { didSet { if title != oldValue { setNeedsLayout() } } }
    public var options: [String] {
        didSet {
            selectedIndex = min(max(selectedIndex, 0), max(options.count - 1, 0))
            setNeedsLayout()
        }
    }
    public private(set) var selectedIndex: Int
    public var wraps = true { didSet { setNeedsDisplay() } }
    /// Called when the user changes the selection (not when it is set in code).
    public var onChange: ((Int) -> Void)?
    private var titleCache = CachedTextLayout()

    public init(_ title: String, options: [String], selectedIndex: Int = 0, name: String = "",
                onChange: ((Int) -> Void)? = nil) {
        self.title = title
        self.options = options
        self.selectedIndex = min(max(selectedIndex, 0), max(options.count - 1, 0))
        self.onChange = onChange
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }

    public var selectedOption: String? { options.indices.contains(selectedIndex) ? options[selectedIndex] : nil }

    /// Selects `index` without calling `onChange`.
    public func select(_ index: Int) {
        let clamped = min(max(index, 0), max(options.count - 1, 0))
        if clamped != selectedIndex {
            selectedIndex = clamped
            setNeedsDisplay()
        }
    }

    /// Steps the selection by `delta` as the user would (wrapping with `wraps`), calling `onChange`.
    public func step(_ delta: Int) {
        guard !options.isEmpty else { return }
        var next = selectedIndex + delta
        if wraps {
            next = ((next % options.count) + options.count) % options.count
        } else {
            next = min(max(next, 0), options.count - 1)
        }
        guard next != selectedIndex else { return }
        selectedIndex = next
        setNeedsDisplay()
        onChange?(next)
    }

    private func metrics(_ theme: UITheme) -> (style: UIWidgetStyle, size: Float, padding: Float, arrow: Float) {
        let style = theme.style(for: self)
        let size = style.fontSize ?? theme.fontSize
        return (style, size, style.paddingX ?? theme.controlPaddingX, size * 0.9)
    }

    /// Width of the value part: the widest option plus the two arrows.
    private func valueWidth(_ theme: UITheme) -> Float {
        let m = metrics(theme)
        let widest = options.map { cachedLayout($0, size: m.size).width }.max() ?? 0
        return (widest * scale).rounded(.up) / scale + 2 * (m.arrow + theme.spacing)
    }

    private func valueRect(_ theme: UITheme) -> UIRect {
        let m = metrics(theme)
        let w = valueWidth(theme)
        let x = title.isEmpty ? frame.x + (frame.width - w) / 2 : frame.maxX - m.padding - w
        return UIRect(x: snap(x), y: frame.y, width: w, height: frame.height)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        let m = metrics(theme)
        let titleWidth = title.isEmpty ? 0
            : (titleCache.get(title, font: theme.font, size: m.size).width * scale).rounded(.up) / scale + 3 * theme.spacing
        return Vec2(titleWidth + valueWidth(theme) + 2 * m.padding, m.style.height ?? theme.controlHeight)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            guard frame.contains(e.position) else { return true }
            step(e.position.x < valueRect(theme).center.x ? -1 : 1)
            return true
        case .key(let e) where e.modifiers.isEmpty:
            switch e.key {
            case .left: step(-1)
            case .right: step(1)
            case .enter, .space where !e.isRepeat: step(1)
            default: return false
            }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let m = metrics(theme)
        let style = m.style
        let background = style.background ?? theme.controlBackground
        let fill = !enabled ? background.withAlpha(0.5)
            : isPressed ? style.pressedBackground ?? theme.controlPressed
            : isHovered || isFocused ? style.hoverBackground ?? theme.controlHover : background
        let radii = UICornerRadii(style.cornerRadius ?? theme.cornerRadius)
        list.fillRect(frame, color: fill, radii: radii)
        list.strokeRect(frame, color: style.borderColor ?? theme.controlBorder, width: style.borderWidth ?? theme.borderWidth,
                        radii: radii)
        let textColor = enabled ? style.textColor ?? theme.textColor : theme.disabledTextColor
        if !title.isEmpty {
            let layout = titleCache.get(title, font: theme.font, size: m.size)
            let rect = UIRect(x: frame.x + m.padding, y: frame.y, width: frame.width - 2 * m.padding, height: frame.height)
            drawLine(layout, font: theme.font, in: rect, color: textColor, list: list)
        }
        let value = valueRect(theme)
        if let option = selectedOption {
            let layout = cachedLayout(option, size: m.size)
            let accent = enabled ? style.accent ?? (isFocused ? theme.accent : textColor) : theme.disabledTextColor
            drawLine(layout, font: theme.font, in: value, alignment: .center, color: isFocused ? accent : textColor, list: list)
        }
        // Chevrons at both ends of the value.
        let s = m.arrow * 0.3
        let cy = value.center.y
        let atStart = !wraps && selectedIndex <= 0, atEnd = !wraps && selectedIndex >= options.count - 1
        let left = Vec2(value.x + m.arrow / 2, cy), right = Vec2(value.maxX - m.arrow / 2, cy)
        let dim = theme.disabledTextColor
        let leftColor = atStart || !enabled ? dim : textColor, rightColor = atEnd || !enabled ? dim : textColor
        let w = theme.iconStrokeWidth
        list.drawLine(from: left + Vec2(s / 2, -s), to: left + Vec2(-s / 2, 0), width: w, color: leftColor, cap: .round)
        list.drawLine(from: left + Vec2(-s / 2, 0), to: left + Vec2(s / 2, s), width: w, color: leftColor, cap: .round)
        list.drawLine(from: right + Vec2(-s / 2, -s), to: right + Vec2(s / 2, 0), width: w, color: rightColor, cap: .round)
        list.drawLine(from: right + Vec2(s / 2, 0), to: right + Vec2(-s / 2, s), width: w, color: rightColor, cap: .round)
    }
}
