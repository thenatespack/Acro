import EngineCore
import EngineGraphics
import EngineText

/// A field whose value is chosen in a dialog rather than a dropdown (an asset among many: a
/// mesh, a material): it shows the value's `title`, with a small `preview` image before it, and
/// a "…" mark; a click, Space or Enter calls `onPick`, which opens the dialog.
@MainActor
public final class PickerField: Widget {
    public var title: String { didSet { if title != oldValue { setNeedsDisplay() } } }
    public var preview: GPUTexture? { didSet { if preview !== oldValue { setNeedsDisplay() } } }
    /// Draws the preview box even without an image (an empty swatch), so titles line up.
    public var showsPreview = true { didSet { if showsPreview != oldValue { setNeedsDisplay() } } }
    public var onPick: (() -> Void)?
    private var cache = CachedTextLayout()

    public init(title: String, name: String = "", onPick: (() -> Void)? = nil) {
        self.title = title
        self.onPick = onPick
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { .button }
    public override var accessibilityText: String? { title }
    public override var accessibilityValue: String? { title }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(80, theme.controlHeight)
    }

    private var previewRect: UIRect {
        let edge = max(frame.height - 6, 0)
        return UIRect(x: frame.x + 3, y: frame.y + 3, width: edge, height: edge)
    }

    private var textRect: UIRect {
        let left = showsPreview ? previewRect.maxX + 6 : frame.x + theme.controlPaddingX
        return UIRect(x: left, y: frame.y, width: max(0, frame.maxX - theme.controlPaddingX - 14 - left), height: frame.height)
    }

    public override func tooltip(at point: Vec2) -> String? {
        tooltip ?? truncatedText(title, size: theme.fontSize, width: textRect.width)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position), isEffectivelyEnabled { onPick?() }
            return true
        case .pointerDrag:
            return true
        case .key(let e) where e.key == .space || e.key == .enter:
            if isEffectivelyEnabled { onPick?() }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let fill = !enabled ? theme.controlBackground.fading(0.5)
            : isPressed ? theme.controlPressed : isHovered ? theme.controlHover : theme.controlBackground
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: fill, radii: radii)
        list.strokeRect(frame, color: isFocused ? theme.accent : theme.controlBorder, width: theme.borderWidth, radii: radii)
        if showsPreview {
            let box = previewRect
            let boxRadii = UICornerRadii(max(theme.cornerRadius - 2, 1))
            list.fillRect(box, color: theme.fieldBackground, radii: boxRadii)
            if let preview { list.drawImage(preview, in: box) }
        }
        let layout = cache.get(title, font: theme.font, size: theme.fontSize)
        drawEllipsized(title, layout: layout, size: theme.fontSize, in: textRect, color: enabled ? theme.textColor : theme.disabledTextColor,
                       list: list)
        // "…": more choices in a dialog.
        let y = frame.center.y
        for i in 0..<3 {
            let x = frame.maxX - theme.controlPaddingX - 8 + Float(i) * 4
            list.fillRect(UIRect(x: x - 1, y: y - 1, width: 2, height: 2), color: theme.secondaryTextColor, radii: UICornerRadii(1))
        }
    }
}
