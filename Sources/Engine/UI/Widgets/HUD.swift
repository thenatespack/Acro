import Foundation

// HUD building blocks: a layer that pins widgets to the window's corners, edges and center
// inside a safe area, progress / health bars, and icon + text counters. They are ordinary
// widgets, styled by the theme (`UITheme.game()` is made for them).

/// Nine places a HUD element can sit.
public enum UIAnchor: Sendable, CaseIterable {
    case topLeft, top, topRight
    case left, center, right
    case bottomLeft, bottom, bottomRight

    /// Absolute-layout anchors that pin a widget here, `offset` points in from the edges it
    /// touches (x from the left / right edge, y from the top / bottom one; centered axes ignore it).
    public func anchors(offset: Vec2 = .zero) -> Anchors {
        switch self {
        case .topLeft: Anchors(left: offset.x, top: offset.y)
        case .top: Anchors(top: offset.y)
        case .topRight: Anchors(top: offset.y, right: offset.x)
        case .left: Anchors(left: offset.x)
        case .center: Anchors()
        case .right: Anchors(right: offset.x)
        case .bottomLeft: Anchors(left: offset.x, bottom: offset.y)
        case .bottom: Anchors(bottom: offset.y)
        case .bottomRight: Anchors(right: offset.x, bottom: offset.y)
        }
    }
}

/// A full-window layer for HUD elements: `add(_:at:offset:)` pins a widget to one of the nine
/// `UIAnchor`s, inside `safeArea` (default: the theme's `hudSafeArea`). It isn't hit-testable
/// itself, so clicks between the elements reach the game.
@MainActor
public final class HUDLayer: Widget {
    /// Insets from the layer's edges that elements keep clear of; nil uses `theme.hudSafeArea`.
    public var safeArea: EdgeInsets? { didSet { if safeArea != oldValue { setNeedsLayout() } } }

    public override init(name: String = "hud") {
        super.init(name: name)
        isHitTestable = false
    }

    /// The rectangle elements are placed in (the frame minus the safe area).
    public var safeRect: UIRect { frame.inset(by: safeArea ?? theme.hudSafeArea) }

    /// Adds `widget` pinned at `anchor`, `offset` points in from the safe area's edges.
    public func add(_ widget: Widget, at anchor: UIAnchor, offset: Vec2 = .zero) {
        widget.style.position = .absolute(anchor.anchors(offset: offset))
        addChild(widget)
    }

    public override func layoutChildren() {
        let content = safeRect
        for child in children where !child.isHidden {
            if case .absolute(let anchors) = child.style.position {
                child.layout(in: Self.anchoredFrame(for: child, anchors: anchors, in: content, snap: snap))
            } else {
                child.layout(in: content)
            }
        }
    }
}

/// A horizontal bar showing `value` (0...1): progress, health, stamina, loading. Colors come
/// from the theme by `kind` (or `fillColor`); the bar is fully rounded unless a style override
/// gives a corner radius. Options: centered `text` over it, `segments` tick marks, and a
/// damage `trail` that shows recently lost value and catches up after `trailDelay`.
@MainActor
public final class ProgressBar: Widget {
    public enum Kind: Sendable {
        /// The theme's accent.
        case progress
        /// Green, then the warning color at or below 50%, then the danger color at or below 25%.
        case health
    }

    public var value: Float {
        didSet {
            value = min(max(value.isFinite ? value : 0, 0), 1)
            if value != oldValue { valueChanged(from: oldValue) }
        }
    }
    public var kind: Kind { didSet { setNeedsDisplay() } }
    /// Overrides the kind's color.
    public var fillColor: UIColor? { didSet { setNeedsDisplay() } }
    public var text: String? { didSet { if text != oldValue { setNeedsLayout() } } }
    /// Tick marks dividing the bar into this many parts (0 or 1: none).
    public var segments = 0 { didSet { setNeedsDisplay() } }
    /// Show lost value as a lighter trail that drains after `trailDelay` seconds at `trailSpeed` per second.
    public var showsTrail = false
    public var trailDelay: Double = 0.35
    public var trailSpeed: Float = 0.8
    /// Where the trail is (≥ `value` while draining).
    public private(set) var trailValue: Float
    private var trailHoldUntil: Double = 0
    private var lastPaintTime: Double?
    private var cache = CachedTextLayout()

    public init(value: Float = 0, kind: Kind = .progress, name: String = "") {
        let v = min(max(value.isFinite ? value : 0, 0), 1)
        self.value = v
        self.kind = kind
        trailValue = v
        super.init(name: name)
        isHitTestable = false
    }

    private func valueChanged(from old: Float) {
        if value > trailValue || !showsTrail {
            trailValue = value
        } else if value < old {
            trailHoldUntil = (context?.time ?? 0) + trailDelay
        }
        setNeedsDisplay()
    }

    /// The fill color for the current value.
    public func currentFillColor(_ theme: UITheme) -> UIColor {
        if let fillColor { return fillColor }
        if let accent = theme.style(for: self).accent { return accent }
        switch kind {
        case .progress: return theme.accent
        case .health: return value <= 0.25 ? theme.dangerColor : value <= 0.5 ? theme.warningColor : theme.healthColor
        }
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        var height = theme.style(for: self).height ?? theme.progressBarHeight
        if let text, !text.isEmpty { height = max(height, theme.lineHeight(theme.smallFontSize) + 2) }
        return Vec2(160, height)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let style = theme.style(for: self)
        let radius = style.cornerRadius ?? frame.height / 2
        let radii = UICornerRadii(radius)
        list.fillRect(frame, color: style.background ?? theme.barBackground, radii: radii)
        // Drain the trail with the context clock.
        if let now = context?.time {
            if let last = lastPaintTime, showsTrail, trailValue > value, now >= trailHoldUntil {
                trailValue = max(value, trailValue - trailSpeed * Float(now - last))
            }
            lastPaintTime = now
            if trailValue > value { setNeedsDisplay() }
        }
        let inner = frame.inset(by: 1)
        let fill = currentFillColor(theme)
        if showsTrail, trailValue > value {
            list.fillRect(UIRect(x: inner.x, y: inner.y, width: inner.width * trailValue, height: inner.height),
                          color: fill.mixed(with: .white, 0.55).withAlpha(0.8), radii: UICornerRadii(max(radius - 1, 0)))
        }
        if value > 0 {
            let filled = UIRect(x: inner.x, y: inner.y, width: snap(inner.width * value), height: inner.height)
            list.fillRect(filled, fill: .linearGradient(start: fill.mixed(with: .white, 0.18), end: fill),
                          radii: UICornerRadii(max(radius - 1, 0)))
        }
        if segments > 1 {
            for i in 1..<segments {
                let x = snap(inner.x + inner.width * Float(i) / Float(segments))
                list.fillRect(UIRect(x: x, y: inner.y, width: 1 / scale, height: inner.height), color: theme.barBackground)
            }
        }
        if let borderColor = style.borderColor {
            list.strokeRect(frame, color: borderColor, width: style.borderWidth ?? theme.borderWidth, radii: radii)
        }
        if let text, !text.isEmpty {
            let layout = cache.get(text, font: theme.font, size: theme.smallFontSize)
            drawLine(layout, font: theme.font, in: frame.offsetBy(Vec2(0, 1)), alignment: .center, color: theme.hudTextShadow,
                     list: list)
            drawLine(layout, font: theme.font, in: frame, alignment: .center, color: style.textColor ?? theme.hudTextColor,
                     list: list)
        }
    }
}

/// An icon for `IconLabel`: a texture region, or anything drawn into a square.
public enum UIIcon {
    /// `uv` of `texture`, tinted.
    case image(GPUTexture, uv: UIRect = .unit, tint: UIColor = .white)
    /// Draws into the icon square with the label's color.
    case custom((UIDrawList, UIRect, UIColor) -> Void)
}

/// An icon next to a line of text with a soft drop shadow, for HUD counters ("♥ 75", "▮ 24 / 120")
/// and objective lines. Without an icon it is a shadowed label for text over the game.
@MainActor
public final class IconLabel: Widget {
    public var icon: UIIcon? { didSet { setNeedsLayout() } }
    public var text: String { didSet { if text != oldValue { setNeedsLayout() } } }
    /// Points; nil uses the theme's font size (or its style override).
    public var fontSize: Float? { didSet { setNeedsLayout() } }
    /// Nil uses the theme's `hudTextColor`.
    public var color: UIColor? { didSet { setNeedsDisplay() } }
    /// Icon edge length in points; nil makes it the line height.
    public var iconSize: Float? { didSet { setNeedsLayout() } }
    public var shadow = true { didSet { setNeedsDisplay() } }
    private var cache = CachedTextLayout()

    public init(_ text: String, icon: UIIcon? = nil, fontSize: Float? = nil, name: String = "") {
        self.text = text
        self.icon = icon
        self.fontSize = fontSize
        super.init(name: name)
        isHitTestable = false
    }

    private func size(_ theme: UITheme) -> Float { fontSize ?? theme.style(for: self).fontSize ?? theme.fontSize }

    private func iconEdge(_ theme: UITheme) -> Float {
        icon == nil ? 0 : iconSize ?? (theme.lineHeight(size(theme)) * scale).rounded() / scale
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let theme = theme
        let layout = cache.get(text, font: theme.font, size: size(theme))
        let edge = iconEdge(theme)
        let textWidth = (layout.width * scale).rounded(.up) / scale
        let gap = icon != nil && !text.isEmpty ? theme.spacing : 0
        return Vec2(edge + gap + textWidth, max(edge, layout.height))
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let content = contentRect
        let color = color ?? theme.style(for: self).textColor ?? theme.hudTextColor
        var x = content.x
        if let icon {
            let edge = iconEdge(theme)
            let box = UIRect(x: x, y: snap(content.y + (content.height - edge) / 2), width: edge, height: edge)
            switch icon {
            case .image(let texture, let uv, let tint):
                list.drawImage(texture, in: box, uv: uv, tint: tint)
            case .custom(let draw):
                if shadow { draw(list, box.offsetBy(Vec2(0, 1)), theme.hudTextShadow) }
                draw(list, box, color)
            }
            x = box.maxX + theme.spacing
        }
        let layout = cache.get(text, font: theme.font, size: size(theme))
        let rect = UIRect(x: x, y: content.y, width: content.maxX - x, height: content.height)
        if shadow {
            drawLine(layout, font: theme.font, in: rect.offsetBy(Vec2(0, 1)), color: theme.hudTextShadow, list: list)
        }
        drawLine(layout, font: theme.font, in: rect, color: color, list: list)
    }
}
