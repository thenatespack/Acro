import Foundation

extension UIColor {
    /// An sRGB color from linear RGB (values outside 0...1 clamp, as for an HDR light color).
    public init(linearRGB c: Vec3, alpha: Float = 1) {
        func encode(_ v: Float) -> Float {
            let v = min(max(v, 0), 1)
            return v <= 0.0031308 ? v * 12.92 : 1.055 * powf(v, 1 / 2.4) - 0.055
        }
        self.init(encode(c.x), encode(c.y), encode(c.z), alpha)
    }

    /// This sRGB color as linear RGB.
    public var linearRGB: Vec3 {
        func decode(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : powf((v + 0.055) / 1.055, 2.4) }
        return Vec3(decode(r), decode(g), decode(b))
    }
}

/// The popup a `ColorSwatch` opens: a `ColorPicker` on a panel, hanging below (or above) the swatch.
public final class ColorPopup: Widget {
    public let picker: ColorPicker
    public weak var anchor: Widget?
    /// Called when the popup closes for any reason (outside click, Esc, `ColorSwatch.close`).
    public var onDismiss: (() -> Void)?

    public init(color: UIColor, anchor: Widget?, name: String = "colorPopup") {
        picker = ColorPicker(color: color, name: "\(name).picker")
        self.anchor = anchor
        super.init(name: name)
        padding = EdgeInsets(8)
        addChild(picker)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(theme.popupCornerRadius)
        for i in 1...3 {
            let grow = Float(i) * 2
            list.fillRect(UIRect(x: frame.x - grow / 2, y: frame.y + grow, width: frame.width + grow, height: frame.height),
                          color: theme.shadow.withAlpha(theme.shadow.a / 3), radii: UICornerRadii(theme.popupCornerRadius - 1 + grow))
        }
        list.fillRect(frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }

    public override func overlayFrame(in viewport: UIRect) -> UIRect {
        let size = measure()
        let anchor = self.anchor?.frame ?? UIRect(x: viewport.center.x, y: viewport.center.y, width: 0, height: 0)
        var y = anchor.maxY + 2
        if y + size.y > viewport.maxY, anchor.y - 2 - size.y >= viewport.y { y = anchor.y - 2 - size.y }
        let x = min(max(anchor.x, viewport.x), max(viewport.x, viewport.maxX - size.x))
        return UIRect(x: x, y: y, width: size.x, height: size.y)
    }

    public override func overlayDismissed() { onDismiss?() }
}

/// A rectangle filled with a color (and its hex code); clicking it opens a `ColorPopup` with a
/// `ColorPicker`. Colors are sRGB; the property grid converts linear `vec3` / `vec4` fields.
///
/// Edit callbacks follow `NumberField`'s: one open popup is one gesture. `onEditBegan` fires on
/// the first change after opening, `onChange` for each, `onEditEnded(start, end)` when the popup
/// closes (not at all when nothing changed). `setColor` (no callbacks) is ignored while it is open.
public final class ColorSwatch: Widget {
    public private(set) var color: UIColor
    public var onEditBegan: ((_ start: UIColor) -> Void)?
    public var onChange: ((UIColor) -> Void)?
    public var onEditEnded: ((_ start: UIColor, _ end: UIColor) -> Void)?
    public private(set) var popup: ColorPopup?
    private var gestureStart: UIColor?
    private var cache = CachedTextLayout()

    public init(color: UIColor, name: String = "") {
        self.color = color
        super.init(name: name)
    }

    public override var acceptsFocus: Bool { true }
    public var isOpen: Bool { popup != nil }

    /// Sets the color without callbacks (ignored while the popup is open).
    public func setColor(_ new: UIColor) {
        guard popup == nil, new != color else { return }
        color = new
        setNeedsDisplay()
    }

    public func open() {
        guard let context, popup == nil, isEffectivelyEnabled else { return }
        let popup = ColorPopup(color: color, anchor: self, name: name.isEmpty ? "colorPopup" : "\(name).popup")
        popup.picker.onChange = { [weak self] picked in self?.picked(picked) }
        popup.onDismiss = { [weak self] in self?.popupClosed() }
        self.popup = popup
        context.presentOverlay(popup)
    }

    public func close() {
        if let popup { context?.dismissOverlay(popup) }
    }

    private func picked(_ new: UIColor) {
        if gestureStart == nil {
            gestureStart = color
            onEditBegan?(color)
        }
        color = new
        setNeedsDisplay()
        onChange?(new)
    }

    private func popupClosed() {
        popup = nil
        if let start = gestureStart {
            gestureStart = nil
            onEditEnded?(start, color)
        }
        setNeedsDisplay()
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(60, theme.controlHeight) }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) { if isOpen { close() } else { open() } }
            return true
        case .key(let e) where (e.key == .enter || e.key == .space) && !e.isRepeat && e.modifiers.isEmpty:
            if isOpen { close() } else { open() }
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: color.withAlpha(enabled ? 1 : 0.5), radii: radii)
        list.strokeRect(frame, color: isOpen ? theme.accent : isHovered ? theme.controlBorder.mixed(with: .white, 0.25)
                        : theme.controlBorder, width: isOpen ? theme.borderWidth + 0.5 : theme.borderWidth, radii: radii)
        // The hex code, dark or light for contrast.
        let luma = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
        let layout = cache.get(color.hexString, font: theme.font, size: theme.smallFontSize)
        drawLine(layout, font: theme.font, in: frame, alignment: .center,
                 color: (luma > 0.55 ? UIColor.black : UIColor.white).withAlpha(enabled ? 0.75 : 0.4), list: list)
    }
}
