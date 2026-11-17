import EditorCore
import Engine
import Foundation

/// The Animation Graph Builder's picture of a 2D blend space: each clip as a dot at its point
/// (sized by its weight at the live value), and the live value as a cross. Clicking or dragging
/// moves the live value, which drives the preview by hand.
@MainActor
public final class BlendSpace2DPlot: Widget {
    public struct Point: Equatable {
        public var label: String
        public var position: Vec2
    }

    public var points: [Point] = [] { didSet { if points != oldValue { setNeedsDisplay() } } }
    /// The live (x, y) parameter values.
    public var value = Vec2(0, 0) { didSet { if value != oldValue { setNeedsDisplay() } } }
    public var axisNames = ("x", "y") { didSet { setNeedsDisplay() } }
    /// The user picked a value (click or drag).
    public var onPick: ((Vec2) -> Void)?

    public override init(name: String = "animGraphBlend2D") {
        super.init(name: name)
        clipsContent = true
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(width ?? 220, 170) }

    /// The plotted range: the points' bounds (and the origin), padded.
    var range: (min: Vec2, max: Vec2) {
        var lo = Vec2(0, 0), hi = Vec2(0, 0)
        for p in points.map(\.position) + [value] {
            lo = Vec2(min(lo.x, p.x), min(lo.y, p.y))
            hi = Vec2(max(hi.x, p.x), max(hi.y, p.y))
        }
        let pad = Vec2(max((hi.x - lo.x) * 0.12, 0.25), max((hi.y - lo.y) * 0.12, 0.25))
        return (lo - pad, hi + pad)
    }

    private var plotRect: UIRect {
        let r = contentRect
        return UIRect(x: r.x + 6, y: r.y + 6, width: max(r.width - 12, 1), height: max(r.height - 22, 1))
    }

    /// Screen point of blend-space point `p` (y up).
    func screen(_ p: Vec2) -> Vec2 {
        let (lo, hi) = range, r = plotRect
        let u = (p.x - lo.x) / max(hi.x - lo.x, 1e-5), v = (p.y - lo.y) / max(hi.y - lo.y, 1e-5)
        return Vec2(r.x + u * r.width, r.y + (1 - v) * r.height)
    }

    /// Blend-space point under screen point `s`.
    func blendPoint(_ s: Vec2) -> Vec2 {
        let (lo, hi) = range, r = plotRect
        let u = (s.x - r.x) / r.width, v = 1 - (s.y - r.y) / r.height
        return Vec2(lo.x + u * (hi.x - lo.x), lo.y + v * (hi.y - lo.y))
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let r = plotRect
        list.fillRect(contentRect, color: UIColor(0.07, 0.08, 0.1, 1), radii: UICornerRadii(4))
        let origin = screen(Vec2(0, 0))
        list.drawLine(from: Vec2(r.x, origin.y), to: Vec2(r.x + r.width, origin.y), width: 1, color: UIColor(1, 1, 1, 0.12))
        list.drawLine(from: Vec2(origin.x, r.y), to: Vec2(origin.x, r.y + r.height), width: 1, color: UIColor(1, 1, 1, 0.12))
        let weights = AnimationMotion.blendWeights2D(points: points.map(\.position), value: value)
        for (point, weight) in zip(points, weights) {
            let s = screen(point.position)
            let radius = 3 + 5 * weight
            list.fillRect(UIRect(x: s.x - radius, y: s.y - radius, width: radius * 2, height: radius * 2),
                          color: weight > 0.001 ? UIColor(0.35, 0.8, 0.5, 1) : UIColor(0.6, 0.64, 0.72, 1), radii: UICornerRadii(radius))
            list.drawText(String(point.label.prefix(14)), at: Vec2(s.x + 7, s.y - 7), size: 10, color: theme.secondaryTextColor)
        }
        let v = screen(value)
        list.drawLine(from: v - Vec2(6, 0), to: v + Vec2(6, 0), width: 2, color: theme.accent)
        list.drawLine(from: v - Vec2(0, 6), to: v + Vec2(0, 6), width: 2, color: theme.accent)
        let caption = "\(axisNames.0) \(String(format: "%.2f", value.x)) · \(axisNames.1) \(String(format: "%.2f", value.y)) · drag to preview"
        list.drawText(caption, at: Vec2(r.x, r.y + r.height + 3), size: 10, color: theme.secondaryTextColor.withAlpha(0.8))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            pick(e.position)
            return true
        case .pointerDrag(let e):
            pick(e.position)
            return true
        case .pointerUp:
            return true
        default:
            return false
        }
    }

    private func pick(_ s: Vec2) {
        // Snaps to a clip's point when within a few points of it.
        var p = blendPoint(s)
        if let near = points.first(where: { length(screen($0.position) - s) < 8 }) { p = near.position }
        value = p
        onPick?(p)
    }
}

private func length(_ v: Vec2) -> Float { (v.x * v.x + v.y * v.y).squareRoot() }
