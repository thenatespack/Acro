import Engine
import Foundation

// The Pixel Sprite Builder's widgets: the drawing canvas, the palette strip and the animation
// preview. They draw a `PixelSpriteBuilderView`'s working copy and report strokes back to it;
// the builder writes every finished stroke or form change to the file as one undo step.

extension PixelColor {
    var uiColor: UIColor { UIColor(Float(r) / 255, Float(g) / 255, Float(b) / 255, Float(a) / 255) }

    init(_ color: UIColor) {
        func byte(_ v: Float) -> UInt8 { UInt8((min(max(v, 0), 1) * 255).rounded()) }
        self.init(byte(color.r), byte(color.g), byte(color.b), byte(color.a))
    }
}

/// Draws an RGBA image as rectangles, one per run of equal pixels in a row (transparent skipped).
@MainActor
func drawPixelImage(_ image: Image, origin: Vec2, scale: Float, alpha: Float = 1, tint: UIColor? = nil, into list: UIDrawList) {
    for y in 0..<image.height {
        var x = 0
        while x < image.width {
            let o = (y * image.width + x) * 4
            let a = image.pixels[o + 3]
            guard a > 0 else { x += 1; continue }
            var end = x + 1
            while end < image.width {
                let p = (y * image.width + end) * 4
                guard image.pixels[p] == image.pixels[o], image.pixels[p + 1] == image.pixels[o + 1],
                      image.pixels[p + 2] == image.pixels[o + 2], image.pixels[p + 3] == a else { break }
                end += 1
            }
            var color = UIColor(Float(image.pixels[o]) / 255, Float(image.pixels[o + 1]) / 255, Float(image.pixels[o + 2]) / 255,
                                Float(a) / 255 * alpha)
            if let tint { color = color.mixed(with: tint.withAlpha(color.a), 0.5) }
            list.fillRect(UIRect(x: origin.x + Float(x) * scale, y: origin.y + Float(y) * scale,
                                 width: Float(end - x) * scale, height: scale), color: color)
            x = end
        }
    }
}

/// A checkerboard behind transparent pixels.
@MainActor
func drawCheckerboard(_ rect: UIRect, cell: Float, into list: UIDrawList) {
    list.fillRect(rect, color: UIColor(0.42, 0.42, 0.45, 1))
    let cell = max(cell, 4)
    let columns = Int((rect.width / cell).rounded(.up)), rows = Int((rect.height / cell).rounded(.up))
    for r in 0..<rows {
        for c in stride(from: r % 2, to: columns, by: 2) {
            let x = rect.x + Float(c) * cell, y = rect.y + Float(r) * cell
            list.fillRect(UIRect(x: x, y: y, width: min(cell, rect.maxX - x), height: min(cell, rect.maxY - y)),
                          color: UIColor(0.55, 0.55, 0.58, 1))
        }
    }
}

/// The drawing canvas: the current frame (all visible layers) zoomed to fit, with onion skin,
/// a pixel grid when zoomed in, mirror guides and the stroke being drawn.
///
/// Left-drag draws with the builder's tool (Alt+click or the picker picks a color), right-drag
/// erases; the stroke is handed to the builder on release. The wheel zooms, middle-drag pans.
@MainActor
public final class PixelCanvasView: Widget {
    public weak var builder: PixelSpriteBuilderView?
    /// Zoom on top of the fit-to-view scale (1 = fit).
    public var zoom: Float = 1 { didSet { setNeedsDisplay() } }
    public var pan = Vec2.zero { didSet { setNeedsDisplay() } }
    public private(set) var hover: PixelPoint?
    private var stroke: [PixelPoint] = []
    private var strokeTool: PixelTool?
    private var panStart: (pointer: Vec2, pan: Vec2)?
    private var preview: PixelSprite?
    private var imageCache: (key: Int, frame: Int, image: Image, previous: Image?, next: Image?)?
    private var cacheKey = 0

    public override init(name: String = "pixelCanvas") {
        super.init(name: name)
        clipsContent = true
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(320, 320) }

    /// Forgets cached frame images (call after the sprite or the shown frame changes).
    public func invalidate() {
        cacheKey &+= 1
        setNeedsDisplay()
    }

    /// Screen points per sprite pixel.
    public var pixelScale: Float {
        guard let sprite = builder?.sprite else { return 1 }
        let rect = contentRect
        let fit = max(min((rect.width - 24) / Float(sprite.width), (rect.height - 24) / Float(sprite.height)), 1)
        return max((fit * zoom).rounded(.down), 1)
    }

    /// The top-left corner of the canvas on screen.
    public var origin: Vec2 {
        guard let sprite = builder?.sprite else { return Vec2(contentRect.x, contentRect.y) }
        let rect = contentRect, s = pixelScale
        return Vec2((rect.x + (rect.width - Float(sprite.width) * s) / 2 + pan.x).rounded(),
                    (rect.y + (rect.height - Float(sprite.height) * s) / 2 + pan.y).rounded())
    }

    /// The sprite pixel under a window point (may be outside the canvas).
    public func pixel(at point: Vec2) -> PixelPoint {
        let o = origin, s = pixelScale
        return PixelPoint(Int(((point.x - o.x) / s).rounded(.down)), Int(((point.y - o.y) / s).rounded(.down)))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard let builder else { return false }
        switch event {
        case .pointerDown(let e):
            if e.button == .middle {
                panStart = (e.position, pan)
                return true
            }
            let p = pixel(at: e.position)
            let tool: PixelTool = e.button == .right ? .eraser : (e.modifiers.contains(.alt) ? .picker : builder.tool)
            if tool == .picker {
                builder.pickColor(at: p)
                return true
            }
            strokeTool = tool
            stroke = [p]
            updatePreview()
            return true
        case .pointerDrag(let e):
            if let panStart {
                pan = panStart.pan + (e.position - panStart.pointer)
                return true
            }
            let p = pixel(at: e.position)
            hover = p
            guard let tool = strokeTool else { return true }
            switch tool {
            case .pencil, .eraser:
                if stroke.last != p { stroke.append(p) }
            case .line, .rect:
                stroke = [stroke[0], p]
            case .fill, .picker:
                break
            }
            updatePreview()
            return true
        case .pointerUp:
            if panStart != nil {
                panStart = nil
                return true
            }
            if let tool = strokeTool, !stroke.isEmpty { builder.applyStroke(tool, points: stroke) }
            strokeTool = nil
            stroke = []
            preview = nil
            invalidate()
            return true
        case .pointerMove(let e):
            let p = pixel(at: e.position)
            if p != hover {
                hover = p
                setNeedsDisplay()
            }
            return false
        case .scroll(let delta, _):
            zoom = min(max(zoom * powf(1.1, delta.y / 4), 0.25), 16)
            return true
        default:
            return false
        }
    }

    private func updatePreview() {
        guard let builder, let tool = strokeTool else { return }
        var copy = builder.sprite
        copy.draw(tool, points: stroke, value: builder.color, frame: builder.frame, layer: builder.layer,
                  filled: builder.filled, mirror: builder.mirror)
        preview = copy
        invalidate()
    }

    public override func cursor(at point: Vec2) -> UICursor? { builder == nil ? nil : .pointingHand }

    public override func tooltip(at point: Vec2) -> String? {
        guard let builder, let hover, hover.x >= 0, hover.y >= 0, hover.x < builder.sprite.width, hover.y < builder.sprite.height else { return nil }
        return "\(hover.x), \(hover.y)"
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let rect = contentRect
        list.fillRect(rect, color: UIColor(0.11, 0.12, 0.14, 1))
        guard let builder else { return }
        let sprite = preview ?? builder.sprite
        let frame = builder.frame
        let s = pixelScale, o = origin
        let canvas = UIRect(x: o.x, y: o.y, width: Float(sprite.width) * s, height: Float(sprite.height) * s)
        drawCheckerboard(canvas, cell: max(s, 8), into: list)

        if imageCache == nil || imageCache!.key != cacheKey || imageCache!.frame != frame {
            let previous = builder.onionSkin && frame > 0 ? sprite.image(frame: frame - 1) : nil
            let next = builder.onionSkin && frame + 1 < sprite.frames.count ? sprite.image(frame: frame + 1) : nil
            imageCache = (cacheKey, frame, sprite.image(frame: frame), previous, next)
        }
        if let cache = imageCache {
            if let previous = cache.previous { drawPixelImage(previous, origin: o, scale: s, alpha: 0.3, tint: UIColor(1, 0.3, 0.3), into: list) }
            if let next = cache.next { drawPixelImage(next, origin: o, scale: s, alpha: 0.2, tint: UIColor(0.3, 0.6, 1), into: list) }
            drawPixelImage(cache.image, origin: o, scale: s, into: list)
        }

        if s >= 8 {
            let line = UIColor(0, 0, 0, 0.18)
            for x in 0...sprite.width {
                let px = o.x + Float(x) * s
                list.drawLine(from: Vec2(px, canvas.y), to: Vec2(px, canvas.maxY), width: 1, color: line)
            }
            for y in 0...sprite.height {
                let py = o.y + Float(y) * s
                list.drawLine(from: Vec2(canvas.x, py), to: Vec2(canvas.maxX, py), width: 1, color: line)
            }
        }
        if builder.mirror.contains(.horizontal) {
            let x = canvas.x + canvas.width / 2
            list.drawLine(from: Vec2(x, canvas.y), to: Vec2(x, canvas.maxY), width: 1, color: theme.accent.withAlpha(0.7))
        }
        if builder.mirror.contains(.vertical) {
            let y = canvas.y + canvas.height / 2
            list.drawLine(from: Vec2(canvas.x, y), to: Vec2(canvas.maxX, y), width: 1, color: theme.accent.withAlpha(0.7))
        }
        list.strokeRect(canvas, color: UIColor(0, 0, 0, 0.6), width: 1)
        if let hover, hover.x >= 0, hover.y >= 0, hover.x < sprite.width, hover.y < sprite.height {
            list.strokeRect(UIRect(x: o.x + Float(hover.x) * s, y: o.y + Float(hover.y) * s, width: s, height: s),
                            color: UIColor(1, 1, 1, 0.85), width: 1)
        }
        let info = "\(sprite.width) x \(sprite.height)  frame \(frame + 1)/\(sprite.frames.count)  \(sprite.layers[builder.layer].name)"
            + (hover.map { h in h.x >= 0 && h.y >= 0 && h.x < sprite.width && h.y < sprite.height ? "  (\(h.x), \(h.y))" : "" } ?? "")
        list.drawText(info, at: Vec2(rect.x + 8, rect.maxY - 18), size: 11, color: theme.secondaryTextColor)
    }
}

/// The palette as a grid of swatches: the transparent cell first, then each color. Click to pick.
@MainActor
public final class PixelPaletteView: Widget {
    public var colors: [PixelColor] = [] { didSet { setNeedsLayout() } }
    /// The selected pixel value (0 transparent, `n` palette entry `n - 1`).
    public var selected: UInt8 = 1 { didSet { setNeedsDisplay() } }
    public var onSelect: ((UInt8) -> Void)?
    let cell: Float = 20

    public override init(name: String = "pixelPalette") { super.init(name: name) }

    private func columns(for width: Float) -> Int { max(Int(width / cell), 1) }

    public override func measureContent(width: Float?) -> Vec2 {
        let w = width ?? cell * 8
        let rows = (colors.count + 1 + columns(for: w) - 1) / columns(for: w)
        return Vec2(w, Float(max(rows, 1)) * cell)
    }

    private func cellRect(_ i: Int) -> UIRect {
        let rect = contentRect, n = columns(for: rect.width)
        return UIRect(x: rect.x + Float(i % n) * cell, y: rect.y + Float(i / n) * cell, width: cell - 2, height: cell - 2)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        guard case .pointerDown(let e) = event else { return false }
        for i in 0...colors.count where cellRect(i).contains(e.position) {
            selected = UInt8(i)
            onSelect?(UInt8(i))
            return true
        }
        return false
    }

    public override func tooltip(at point: Vec2) -> String? {
        for i in 0...colors.count where cellRect(i).contains(point) {
            return i == 0 ? "Transparent (\".\")" : "\(colors[i - 1]) (\"\(PixelSprite.character(for: UInt8(i)))\", index \(i - 1))"
        }
        return nil
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        for i in 0...colors.count {
            let r = cellRect(i)
            if i == 0 {
                drawCheckerboard(r, cell: r.width / 2, into: list)
                list.drawLine(from: Vec2(r.x + 2, r.maxY - 2), to: Vec2(r.maxX - 2, r.y + 2), width: 1.5, color: UIColor(0.9, 0.2, 0.2, 1))
            } else {
                list.fillRect(r, color: colors[i - 1].uiColor)
            }
            if UInt8(i) == selected {
                list.strokeRect(r.inset(by: -1), color: UIColor.white, width: 2)
            }
        }
    }
}

/// Plays one tag (or every frame) of the builder's sprite at its frame timing.
@MainActor
public final class PixelSpritePreviewView: Widget {
    public weak var builder: PixelSpriteBuilderView?
    /// The clip shown (a tag name; nil: the first clip).
    public var clipName: String?
    public var isPlaying = true
    private var time: Float = 0
    private var images: (key: Int, frames: [Image])?
    private var key = 0

    public override init(name: String = "pixelSpritePreview") {
        super.init(name: name)
        isHitTestable = false
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(width ?? 160, 120) }

    public func invalidate() { key &+= 1 }

    public func advance(dt: Float) {
        guard isPlaying else { return }
        time += dt
        setNeedsDisplay()
    }

    /// The atlas frame shown now.
    public var currentFrame: Int? {
        guard let sprite = builder?.sprite else { return nil }
        let clips = sprite.clips()
        guard let clip = clips.first(where: { $0.name == clipName }) ?? clips.first, !clip.frames.isEmpty else { return nil }
        let tick = clip.fps > 0 ? Int(time * clip.fps) : 0
        let n = clip.frames.count
        let step: Int
        switch clip.mode {
        case .loop: step = tick % n
        case .once: step = min(tick, n - 1)
        case .pingPong:
            let cycle = max(2 * n - 2, 1)
            let p = tick % cycle
            step = n == 1 ? 0 : (p < n ? p : cycle - p)
        }
        return clip.frames[step]
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let rect = contentRect
        list.fillRect(rect, color: UIColor(0.11, 0.12, 0.14, 1), radii: UICornerRadii(4))
        guard let sprite = builder?.sprite, let frame = currentFrame else { return }
        if images?.key != key || images?.frames.count != sprite.frames.count {
            images = (key, sprite.frames.indices.map { sprite.image(frame: $0) })
        }
        guard let frames = images?.frames, frames.indices.contains(frame) else { return }
        let image = frames[frame]
        let s = max(min((rect.width - 8) / Float(sprite.width), (rect.height - 8) / Float(sprite.height)).rounded(.down), 1)
        let o = Vec2((rect.x + (rect.width - Float(sprite.width) * s) / 2).rounded(), (rect.y + (rect.height - Float(sprite.height) * s) / 2).rounded())
        drawPixelImage(image, origin: o, scale: s, into: list)
        list.drawText("frame \(frame)", at: Vec2(rect.x + 6, rect.y + 4), size: 10, color: theme.secondaryTextColor)
    }
}
