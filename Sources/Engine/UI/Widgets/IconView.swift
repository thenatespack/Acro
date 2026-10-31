/// A `VectorIcon` on its own: a square of `size` points (nil: `theme.iconSize`) in `color` (nil:
/// the secondary text color). Not interactive; `accessibilityLabel` or `tooltip` describes it.
@MainActor
public final class IconView: Widget {
    public var icon: VectorIcon? { didSet { if icon != oldValue { setNeedsDisplay() } } }
    public var color: UIColor? { didSet { if color != oldValue { setNeedsDisplay() } } }
    public var size: Float? { didSet { if size != oldValue { setNeedsLayout() } } }

    public init(_ icon: VectorIcon?, size: Float? = nil, color: UIColor? = nil, name: String = "icon") {
        self.icon = icon
        self.size = size
        self.color = color
        super.init(name: name)
        isHitTestable = false
    }

    public override var accessibilityRole: UIAccessibilityRole { .image }
    public override var accessibilityText: String? { accessibilityLabel ?? tooltip ?? icon?.name }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(repeating: size ?? theme.iconSize)
    }

    public override func hitTest(_ point: Vec2) -> Widget? {
        guard !isHidden, tooltip != nil, frame.contains(point) else { return nil }
        return self
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        guard let icon else { return }
        let content = contentRect
        let edge = min(size ?? theme.iconSize, content.width, content.height)
        list.drawIcon(icon, in: UIRect(x: content.center.x - edge / 2, y: content.center.y - edge / 2, width: edge, height: edge),
                      color: isEffectivelyEnabled ? color ?? theme.secondaryTextColor : theme.disabledTextColor)
    }
}
