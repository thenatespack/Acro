import Foundation

/// Hue / saturation / value, all 0...1, over sRGB components.
public struct HSV: Sendable, Equatable {
    public var h, s, v: Float

    public init(h: Float, s: Float, v: Float) {
        (self.h, self.s, self.v) = (h, s, v)
    }

    public init(_ color: UIColor) {
        let maxC = max(color.r, color.g, color.b), minC = min(color.r, color.g, color.b)
        let delta = maxC - minC
        var hue: Float = 0
        if delta > 0 {
            if maxC == color.r {
                hue = (color.g - color.b) / delta
            } else if maxC == color.g {
                hue = (color.b - color.r) / delta + 2
            } else {
                hue = (color.r - color.g) / delta + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        self.init(h: hue, s: maxC > 0 ? delta / maxC : 0, v: maxC)
    }

    public func color(alpha: Float = 1) -> UIColor {
        let h6 = (h - h.rounded(.down)) * 6
        let sector = Int(h6.rounded(.down)) % 6
        let f = h6 - h6.rounded(.down)
        let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch sector {
        case 0: return UIColor(v, t, p, alpha)
        case 1: return UIColor(q, v, p, alpha)
        case 2: return UIColor(p, v, t, alpha)
        case 3: return UIColor(p, q, v, alpha)
        case 4: return UIColor(t, p, v, alpha)
        default: return UIColor(v, p, q, alpha)
        }
    }
}

extension UIColor {
    /// `#RRGGBB` (alpha is not included).
    public var hexString: String {
        func byte(_ c: Float) -> Int { Int((min(max(c, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }

    /// Parses `#RRGGBB`, `RRGGBB`, `#RGB` or `RGB` (case-insensitive, surrounding spaces ignored).
    public init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

/// Picks an sRGB color: a saturation/value square, a hue bar, a swatch and a hex field. Drag in
/// the square or bar; arrow keys move saturation (left/right) and value (up/down) when focused;
/// type `#RRGGBB` in the field and press Enter (or leave it) to set it.
public final class ColorPicker: Widget {
    public private(set) var hsv: HSV
    public var color: UIColor { hsv.color() }
    /// Called while the user changes the color.
    public var onChange: ((UIColor) -> Void)?
    /// Side of the saturation/value square.
    public var squareSize: Float = 132 { didSet { setNeedsLayout() } }
    public let hexField: TextField
    private enum Drag { case square, hue }
    private var drag: Drag?
    private let hueBarWidth: Float = 16

    public init(color: UIColor, name: String = "", onChange: ((UIColor) -> Void)? = nil) {
        hsv = HSV(color)
        self.onChange = onChange
        hexField = TextField(text: color.hexString, name: "\(name).hex")
        hexField.preferredWidth = 84
        super.init(name: name)
        addChild(hexField)
        hexField.onSubmit = { [weak self] text in self?.applyHex(text) }
        hexField.onEndEditing = { [weak self] text in self?.applyHex(text) }
    }

    public override var acceptsFocus: Bool { true }

    /// Sets the color in code (no `onChange`).
    public func setColor(_ color: UIColor) {
        let new = HSV(color)
        // Keep the hue when the new color has none (grays).
        hsv = HSV(h: new.s > 0 && new.v > 0 ? new.h : hsv.h, s: new.v > 0 ? new.s : hsv.s, v: new.v)
        syncField()
        setNeedsDisplay()
    }

    private func userSet(_ new: HSV) {
        let clamped = HSV(h: min(max(new.h, 0), 1), s: min(max(new.s, 0), 1), v: min(max(new.v, 0), 1))
        guard clamped != hsv else { return }
        hsv = clamped
        syncField()
        setNeedsDisplay()
        onChange?(color)
    }

    private func syncField() {
        if !hexField.isFocused { hexField.text = color.hexString }
    }

    private func applyHex(_ text: String) {
        if let parsed = UIColor(hexString: text) {
            let old = color
            setColor(parsed)
            if old != color { onChange?(color) }
        }
        hexField.text = color.hexString
    }

    private var squareRect: UIRect {
        let c = contentRect
        return UIRect(x: c.x, y: c.y, width: squareSize, height: squareSize)
    }

    private var hueRect: UIRect {
        let sq = squareRect
        return UIRect(x: sq.maxX + 8, y: sq.y, width: hueBarWidth, height: squareSize)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let field = hexField.measure()
        return Vec2(squareSize + 8 + hueBarWidth, squareSize + 8 + field.y)
    }

    public override func layoutChildren() {
        let sq = squareRect
        let field = hexField.measure()
        let swatch = field.y
        hexField.layout(in: UIRect(x: sq.x + swatch + 8, y: sq.maxY + 8, width: hueRect.maxX - sq.x - swatch - 8, height: field.y))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            if squareRect.contains(e.position) {
                drag = .square
            } else if hueRect.contains(e.position) {
                drag = .hue
            } else {
                return false
            }
            dragTo(e.position)
            return true
        case .pointerDrag(let e):
            if drag != nil { dragTo(e.position) }
            return drag != nil
        case .pointerUp:
            let was = drag != nil
            drag = nil
            return was
        case .key(let e):
            let step: Float = e.modifiers.contains(.shift) ? 0.1 : 0.01
            switch e.key {
            case .left: userSet(HSV(h: hsv.h, s: hsv.s - step, v: hsv.v))
            case .right: userSet(HSV(h: hsv.h, s: hsv.s + step, v: hsv.v))
            case .up: userSet(HSV(h: hsv.h, s: hsv.s, v: hsv.v + step))
            case .down: userSet(HSV(h: hsv.h, s: hsv.s, v: hsv.v - step))
            case .pageUp: userSet(HSV(h: (hsv.h - step + 1).truncatingRemainder(dividingBy: 1), s: hsv.s, v: hsv.v))
            case .pageDown: userSet(HSV(h: (hsv.h + step).truncatingRemainder(dividingBy: 1), s: hsv.s, v: hsv.v))
            default: return false
            }
            return true
        default:
            return false
        }
    }

    private func dragTo(_ p: Vec2) {
        switch drag {
        case .square:
            let sq = squareRect
            userSet(HSV(h: hsv.h, s: (p.x - sq.x) / sq.width, v: 1 - (p.y - sq.y) / sq.height))
        case .hue:
            let bar = hueRect
            userSet(HSV(h: min(max((p.y - bar.y) / bar.height, 0), 0.9999), s: hsv.s, v: hsv.v))
        case nil:
            break
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let sq = squareRect
        let radii = UICornerRadii(theme.smallCornerRadius)
        // Saturation left to right (white to the pure hue), then value top to bottom (a black overlay).
        let pure = HSV(h: hsv.h, s: 1, v: 1).color()
        list.fillRect(sq, fill: .linearGradient(start: .white, end: pure, angle: 0), radii: radii)
        list.fillRect(sq, fill: .linearGradient(start: .black.withAlpha(0), end: .black, angle: .pi / 2), radii: radii)
        list.strokeRect(sq, color: theme.controlBorder, width: theme.borderWidth, radii: radii)

        // Hue bar: six gradient segments.
        let bar = hueRect
        let segment = bar.height / 6
        for i in 0..<6 {
            let top = HSV(h: Float(i) / 6, s: 1, v: 1).color(), bottom = HSV(h: Float(i + 1) / 6, s: 1, v: 1).color()
            let corners = UICornerRadii(topLeft: i == 0 ? 4 : 0, topRight: i == 0 ? 4 : 0,
                                        bottomRight: i == 5 ? 4 : 0, bottomLeft: i == 5 ? 4 : 0)
            list.fillRect(UIRect(x: bar.x, y: bar.y + Float(i) * segment, width: bar.width, height: segment),
                          fill: .linearGradient(start: top, end: bottom), radii: corners)
        }
        list.strokeRect(bar, color: theme.controlBorder, width: theme.borderWidth, radii: radii)

        // Markers.
        let marker = Vec2(sq.x + hsv.s * sq.width, sq.y + (1 - hsv.v) * sq.height)
        let ring = UIRect(x: marker.x - 6, y: marker.y - 6, width: 12, height: 12)
        list.strokeRect(ring, color: .black.withAlpha(0.5), width: 3, radii: UICornerRadii(6))
        list.strokeRect(ring.inset(by: 0.5), color: .white, width: 1.5, radii: UICornerRadii(5.5))
        let hueY = bar.y + hsv.h * bar.height
        let handle = UIRect(x: bar.x - 2, y: hueY - 3, width: bar.width + 4, height: 6)
        list.fillRect(handle, color: theme.thumb, radii: UICornerRadii(3))
        list.strokeRect(handle, color: .black.withAlpha(0.45), width: 1, radii: UICornerRadii(3))

        // Swatch next to the hex field.
        let field = hexField.frame
        let swatch = UIRect(x: sq.x, y: field.y, width: field.height, height: field.height)
        list.fillRect(swatch, color: color, radii: UICornerRadii(theme.cornerRadius))
        list.strokeRect(swatch, color: theme.controlBorder, width: theme.borderWidth, radii: UICornerRadii(theme.cornerRadius))
    }
}
