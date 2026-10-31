import Foundation

// 2D UI draw list: the low-level layer the retained widget tree and game HUDs render through.
//
// Game code fills a `UIDrawList` each frame (`Engine.ui`) in logical points: the origin is
// the window's top-left corner, x grows right, y grows down, and one point is
// `UIDrawList.scale` framebuffer pixels (the window's backing scale factor). The engine
// draws the list in the window pass, at window resolution, on top of the scene and below
// the debug overlay. The list is cleared at the start of every frame.
//
// Colors are sRGB with straight (non-premultiplied) alpha, the values you'd write in CSS.
// The shader interpolates them in sRGB (so gradients look like CSS ones), converts to linear
// and blends in linear light; the sRGB window target encodes the result back. Textures
// sample as linear when created as `.rgba8Srgb` and as stored when `.rgba8Unorm`.

/// An sRGB color with straight alpha, components 0...1.
public struct UIColor: Sendable, Equatable {
    public var r, g, b, a: Float

    public init(_ r: Float, _ g: Float, _ b: Float, _ a: Float = 1) {
        (self.r, self.g, self.b, self.a) = (r, g, b, a)
    }

    /// `0xRRGGBB`, e.g. `UIColor(hex: 0x3478f6)`.
    public init(hex: UInt32, alpha: Float = 1) {
        self.init(Float((hex >> 16) & 0xff) / 255, Float((hex >> 8) & 0xff) / 255, Float(hex & 0xff) / 255, alpha)
    }

    public static let clear = UIColor(0, 0, 0, 0)
    public static let black = UIColor(0, 0, 0)
    public static let white = UIColor(1, 1, 1)

    public func withAlpha(_ alpha: Float) -> UIColor { UIColor(r, g, b, alpha) }

    /// Component-wise blend in sRGB space (`t` = 0 gives `self`, 1 gives `other`).
    public func mixed(with other: UIColor, _ t: Float) -> UIColor {
        UIColor(r + (other.r - r) * t, g + (other.g - g) * t, b + (other.b - b) * t, a + (other.a - a) * t)
    }
}

/// A rectangle in points (or in pixels, where a function says so). The origin is the top-left corner.
public struct UIRect: Sendable, Equatable {
    public var x, y, width, height: Float

    public init(x: Float, y: Float, width: Float, height: Float) {
        (self.x, self.y, self.width, self.height) = (x, y, width, height)
    }

    public var maxX: Float { x + width }
    public var maxY: Float { y + height }
    public var center: Vec2 { Vec2(x + width / 2, y + height / 2) }

    public func inset(by amount: Float) -> UIRect {
        UIRect(x: x + amount, y: y + amount, width: width - 2 * amount, height: height - 2 * amount)
    }

    /// The overlap, or nil when the rectangles don't share any area.
    public func intersection(_ other: UIRect) -> UIRect? {
        let x0 = max(x, other.x), y0 = max(y, other.y)
        let x1 = min(maxX, other.maxX), y1 = min(maxY, other.maxY)
        return x1 > x0 && y1 > y0 ? UIRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0) : nil
    }

    public static let unit = UIRect(x: 0, y: 0, width: 1, height: 1)
}

/// Corner radii in points, clockwise from the top-left.
public struct UICornerRadii: Sendable, Equatable {
    public var topLeft, topRight, bottomRight, bottomLeft: Float

    public init(topLeft: Float, topRight: Float, bottomRight: Float, bottomLeft: Float) {
        (self.topLeft, self.topRight, self.bottomRight, self.bottomLeft) = (topLeft, topRight, bottomRight, bottomLeft)
    }

    public init(_ radius: Float) {
        self.init(topLeft: radius, topRight: radius, bottomRight: radius, bottomLeft: radius)
    }

    public static let zero = UICornerRadii(0)

    var isZero: Bool { topLeft <= 0 && topRight <= 0 && bottomRight <= 0 && bottomLeft <= 0 }

    /// Scaled by `factor`, then shrunk uniformly (as CSS does) when two radii along a side
    /// would overlap on a `width` x `height` box, so shapes never self-intersect.
    func fitted(toWidth width: Float, height: Float, scale factor: Float = 1) -> UICornerRadii {
        var r = UICornerRadii(
            topLeft: max(topLeft, 0) * factor, topRight: max(topRight, 0) * factor,
            bottomRight: max(bottomRight, 0) * factor, bottomLeft: max(bottomLeft, 0) * factor)
        var shrink: Float = 1
        for (sum, side) in [(r.topLeft + r.topRight, width), (r.bottomLeft + r.bottomRight, width),
                            (r.topLeft + r.bottomLeft, height), (r.topRight + r.bottomRight, height)] where sum > side {
            shrink = min(shrink, side / sum)
        }
        if shrink < 1 {
            r = UICornerRadii(topLeft: r.topLeft * shrink, topRight: r.topRight * shrink,
                              bottomRight: r.bottomRight * shrink, bottomLeft: r.bottomLeft * shrink)
        }
        return r
    }
}

/// How a shape is filled.
public enum UIFill: Sendable, Equatable {
    case solid(UIColor)
    /// A linear gradient across the shape's bounding box from `start` to `end`. `angle` is the
    /// direction in radians: 0 runs left to right, `.pi / 2` (the default) top to bottom. As
    /// in CSS, the gradient line is as long as needed for the corners to get exactly the end colors.
    case linearGradient(start: UIColor, end: UIColor, angle: Float = .pi / 2)
}

extension UIFill {
    /// The color at `point`, for a gradient over `rect`. Extrapolates beyond the box (the
    /// shader clamps), which keeps the per-vertex interpolation exact inside it.
    func color(at point: Vec2, in rect: UIRect) -> UIColor {
        switch self {
        case .solid(let color):
            return color
        case .linearGradient(let start, let end, let angle):
            let direction = Vec2(cosf(angle), sinf(angle))
            let span = abs(rect.width * direction.x) + abs(rect.height * direction.y)
            let t = span > 0 ? ((point - rect.center) * direction).sum() / span + 0.5 : 0
            return start.mixed(with: end, t)
        }
    }
}

/// How the texture of a textured quad is used. The vertex color tints or colors it.
public enum UIQuadMode: Sendable, Equatable {
    /// color * texture (an image; the vertex color is the tint).
    case image
    /// The vertex color, with coverage taken from the texture's alpha channel (glyph atlases).
    case mask
    /// Signed-distance-field glyphs (what `drawText` emits): the texture's alpha is a distance
    /// field (0.5 on the outline, larger inside) and `smoothing` the width in distance units
    /// that the edge ramps over (see `UIDrawList.sdfSmoothing(pixelSize:)`).
    case sdf(smoothing: Float)

    var shaderMode: Float {
        switch self {
        case .image: 1
        case .mask: 2
        case .sdf: 3
        }
    }
}

/// Line end style.
public enum UILineCap: Sendable {
    case butt, round
}

/// One corner of a free-form textured quad (`UIDrawList.drawTexturedQuad`).
public struct UIQuadCorner: Sendable {
    /// Position in points.
    public var position: Vec2
    public var uv: Vec2
    public var color: UIColor

    public init(position: Vec2, uv: Vec2, color: UIColor = .white) {
        (self.position, self.uv, self.color) = (position, uv, color)
    }
}

/// What the last frame's list cost, for the debug overlay and tests.
public struct UIDrawStats: Sendable, Equatable {
    /// Primitives submitted (rects, strokes, images, lines, quads), after clip culling.
    public var items = 0
    /// Primitives dropped because they were entirely outside the clip rectangle.
    public var culled = 0
    public var vertices = 0
    public var indices = 0
    /// Draw calls: runs of items sharing a texture, sampler and clip rectangle.
    public var batches = 0
}

/// A clip rectangle in framebuffer pixels (`x0..<x1`, `y0..<y1`).
struct UIPixelRect: Equatable {
    var x0, y0, x1, y1: Int

    var isEmpty: Bool { x1 <= x0 || y1 <= y0 }

    func intersection(_ other: UIPixelRect) -> UIPixelRect {
        let r = UIPixelRect(x0: max(x0, other.x0), y0: max(y0, other.y0), x1: min(x1, other.x1), y1: min(y1, other.y1))
        return r.isEmpty ? UIPixelRect(x0: 0, y0: 0, x1: 0, y1: 0) : r
    }

    var scissor: ScissorRect { ScissorRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0) }
}

/// Vertex of the UI pipeline (`ui.vert`). Positions are in framebuffer pixels. Every shape is
/// a quad carrying what the fragment shader needs to evaluate the signed distance to a
/// rounded box analytically, so rounded rects, strokes, lines (rotated capsules) and images
/// with rounded corners are all one primitive.
struct UIVertex {
    var position: Vec2
    var uv: Vec2
    /// sRGB, straight alpha.
    var color: Vec4
    /// Position relative to the box center, pixels.
    var local: Vec2
    var halfSize: Vec2
    /// Corner radii in pixels: top-left, top-right, bottom-right, bottom-left.
    var radii: Vec4
    /// x: stroke width in pixels (0 fills), y: `UIQuadMode.shaderMode` (0 = solid), z: SDF smoothing.
    var params: Vec4

    static let layout = VertexLayout(
        stride: MemoryLayout<UIVertex>.stride,
        attributes: [
            VertexAttribute(location: 0, format: .float2, offset: MemoryLayout<UIVertex>.offset(of: \.position)!),
            VertexAttribute(location: 1, format: .float2, offset: MemoryLayout<UIVertex>.offset(of: \.uv)!),
            VertexAttribute(location: 2, format: .float4, offset: MemoryLayout<UIVertex>.offset(of: \.color)!),
            VertexAttribute(location: 3, format: .float2, offset: MemoryLayout<UIVertex>.offset(of: \.local)!),
            VertexAttribute(location: 4, format: .float2, offset: MemoryLayout<UIVertex>.offset(of: \.halfSize)!),
            VertexAttribute(location: 5, format: .float4, offset: MemoryLayout<UIVertex>.offset(of: \.radii)!),
            VertexAttribute(location: 6, format: .float4, offset: MemoryLayout<UIVertex>.offset(of: \.params)!),
        ])
}

/// What a batch samples: a texture, or a page of the list's glyph atlas (resolved when the
/// renderer draws, after uploading pages that gained glyphs this frame).
enum UITextureSource {
    case texture(GPUTexture)
    case glyphPage(Int)

    func isSame(as other: UITextureSource) -> Bool {
        switch (self, other) {
        case (.texture(let a), .texture(let b)): a === b
        case (.glyphPage(let a), .glyphPage(let b)): a == b
        default: false
        }
    }
}

/// A run of consecutive items drawn with one call.
struct UIBatch {
    /// nil for items that don't sample a texture; the renderer binds a white one.
    var source: UITextureSource?
    /// The texture, when the batch samples one directly (not a glyph page).
    var texture: GPUTexture? {
        if case .texture(let texture)? = source { texture } else { nil }
    }
    /// nil is the renderer's default (linear, clamp to edge).
    var sampler: GPUSampler?
    var clip: UIPixelRect
    var firstIndex: Int
    var indexCount: Int
}

/// An immediate-mode 2D draw list; see the notes at the top of this file.
///
/// Batching: items are drawn in submission order, and consecutive items merge into one draw
/// call when they share a clip rectangle and texture (and sampler). Items that don't sample a
/// texture (fills, strokes, lines) join the current batch whatever its texture, so a panel
/// full of rects with an icon in the middle is still a single draw. All vertices and indices
/// of a frame are uploaded once.
///
/// Clipping: `pushClip` / `popClip` keep a stack of rectangles; a nested clip is intersected
/// with the one below. They are scissor rectangles in whole framebuffer pixels (edges are
/// rounded to the nearest pixel, so clip edges are not antialiased) and always rectangular:
/// there is no rounded clipping. Items entirely outside the clip are dropped on the CPU.
///
/// Transforms and opacity: `pushTransform(scale:offset:)` maps the points of later items
/// through `p * scale + offset` (composed with the transforms below it), so a whole widget
/// tree can be zoomed (`UIContext.uiScale`), slid in a menu transition or drawn at a world
/// label's distance scale; text then rasterizes at the transformed pixel size, so it stays
/// sharp. `pushOpacity` multiplies the alpha of later items. With neither pushed the output is
/// exactly what the plain point coordinates give.
///
/// HiDPI: at a fractional pixel scale (a backing scale of 1.25 or 1.5, or any scale times a
/// zoom) stroke widths are rounded to whole pixels (at least one), so 1-point borders stay
/// crisp instead of spreading over two pixel rows. Integral scales draw strokes as given.
@MainActor
public final class UIDrawList {
    /// Framebuffer pixels per point (the window's backing scale factor).
    public private(set) var scale: Float = 1
    /// The target size in framebuffer pixels.
    public private(set) var framebufferSize: (width: Int, height: Int) = (0, 0)
    /// The target size in points: lay out in this.
    public var size: Vec2 { Vec2(Float(framebufferSize.width), Float(framebufferSize.height)) / scale }
    /// Counts of what was recorded since `beginFrame`.
    public private(set) var stats = UIDrawStats()

    private(set) var vertices: [UIVertex] = []
    private(set) var indices: [UInt32] = []
    private(set) var batches: [UIBatch] = []
    private var clipStack: [UIPixelRect] = []
    private var atlas: GlyphAtlas?
    /// Points to framebuffer pixels for the current transform: `p * pixelScale + pixelOffset`.
    private var pixelScale: Float = 1
    private var pixelOffset = Vec2.zero
    private var transformStack: [(scale: Float, offset: Vec2)] = []
    /// Multiplies the alpha of everything drawn (`pushOpacity`).
    public private(set) var opacity: Float = 1
    private var opacityStack: [Float] = []

    public init() {}

    /// The atlas `drawText` rasterizes glyphs into (created on first use). The renderer uploads
    /// pages that gained glyphs before drawing; `prewarm` it for large character sets.
    public var glyphAtlas: GlyphAtlas {
        if let atlas { return atlas }
        let created = GlyphAtlas()
        atlas = created
        return created
    }

    /// The atlas, if any text was ever drawn (for the renderer).
    var glyphAtlasIfCreated: GlyphAtlas? { atlas }

    /// The bundled UI font (Inter Regular), used by `drawText` when no font is given.
    public static let defaultFont: Font = {
        do { return try Font.bundledUI() } catch { fatalError("UIDrawList: \(error)") }
    }()

    /// Clears the list for a new frame. The engine calls this before `Game.update` for
    /// `engine.ui`; call it yourself for a list drawn elsewhere (e.g. into a `RenderTarget`
    /// with a `UIRenderer`), with the target's pixel size and pixels per point.
    public func beginFrame(framebufferSize: (width: Int, height: Int), scale: Float) {
        precondition(clipStack.isEmpty, "UIDrawList: pushClip without a matching popClip")
        precondition(transformStack.isEmpty, "UIDrawList: pushTransform without a matching popTransform")
        precondition(opacityStack.isEmpty, "UIDrawList: pushOpacity without a matching popOpacity")
        self.framebufferSize = framebufferSize
        self.scale = max(scale, 0.01)
        pixelScale = self.scale
        pixelOffset = .zero
        opacity = 1
        vertices.removeAll(keepingCapacity: true)
        indices.removeAll(keepingCapacity: true)
        batches.removeAll(keepingCapacity: true)
        stats = UIDrawStats()
    }

    // MARK: Clipping

    private var clip: UIPixelRect {
        clipStack.last ?? UIPixelRect(x0: 0, y0: 0, x1: framebufferSize.width, y1: framebufferSize.height)
    }

    /// The current clip rectangle in points (nil when nothing is visible), for skipping
    /// widgets that would be clipped away.
    public var clipBounds: UIRect? {
        let c = clip
        guard !c.isEmpty else { return nil }
        let x0 = (Float(c.x0) - pixelOffset.x) / pixelScale, y0 = (Float(c.y0) - pixelOffset.y) / pixelScale
        return UIRect(x: x0, y: y0, width: Float(c.x1 - c.x0) / pixelScale, height: Float(c.y1 - c.y0) / pixelScale)
    }

    /// Restricts drawing to `rect` (points) intersected with the current clip, until the matching `popClip`.
    public func pushClip(_ rect: UIRect) {
        let pixels = UIPixelRect(
            x0: Int(px(rect.x, 0).rounded()), y0: Int(px(rect.y, 1).rounded()),
            x1: Int(px(rect.maxX, 0).rounded()), y1: Int(px(rect.maxY, 1).rounded()))
        clipStack.append(clip.intersection(pixels))
    }

    public func popClip() {
        precondition(!clipStack.isEmpty, "UIDrawList: popClip without a matching pushClip")
        clipStack.removeLast()
    }

    /// Runs `body` with `rect` pushed as a clip.
    public func withClip(_ rect: UIRect, _ body: () -> Void) {
        pushClip(rect)
        body()
        popClip()
    }

    // MARK: Transforms and opacity

    /// Later items map their points through `p * scale + offset` (in the current transform's
    /// points), until the matching `popTransform`. `scale` must be positive.
    public func pushTransform(scale: Float = 1, offset: Vec2 = .zero) {
        transformStack.append((pixelScale, pixelOffset))
        pixelOffset = pixelOffset + offset * pixelScale
        pixelScale *= max(scale, 1e-4)
    }

    public func popTransform() {
        precondition(!transformStack.isEmpty, "UIDrawList: popTransform without a matching pushTransform")
        (pixelScale, pixelOffset) = transformStack.removeLast()
    }

    /// Runs `body` with a transform pushed.
    public func withTransform(scale: Float = 1, offset: Vec2 = .zero, _ body: () -> Void) {
        pushTransform(scale: scale, offset: offset)
        body()
        popTransform()
    }

    /// Framebuffer pixels per point under the current transform (`scale` with none pushed).
    public var effectiveScale: Float { pixelScale }

    /// Multiplies the alpha of later items by `alpha` (0...1; nested values multiply) until `popOpacity`.
    public func pushOpacity(_ alpha: Float) {
        opacityStack.append(opacity)
        opacity *= min(max(alpha, 0), 1)
    }

    public func popOpacity() {
        precondition(!opacityStack.isEmpty, "UIDrawList: popOpacity without a matching pushOpacity")
        opacity = opacityStack.removeLast()
    }

    public func withOpacity(_ alpha: Float, _ body: () -> Void) {
        pushOpacity(alpha)
        body()
        popOpacity()
    }

    /// A point coordinate in framebuffer pixels (`axis` 0 is x, 1 is y).
    @inline(__always) private func px(_ value: Float, _ axis: Int) -> Float {
        value * pixelScale + (axis == 0 ? pixelOffset.x : pixelOffset.y)
    }

    @inline(__always) private func px(_ point: Vec2) -> Vec2 { point * pixelScale + pixelOffset }

    /// A stroke width in pixels: whole pixels (at least one) when `scale` is fractional.
    public static func strokePixels(_ width: Float, scale: Float) -> Float {
        let pixels = width * scale
        guard scale != scale.rounded(), pixels > 0 else { return pixels }
        return max(pixels.rounded(), 1)
    }

    // MARK: Shapes

    /// Fills a rectangle, optionally with rounded corners.
    public func fillRect(_ rect: UIRect, color: UIColor, radii: UICornerRadii = .zero) {
        fillRect(rect, fill: .solid(color), radii: radii)
    }

    public func fillRect(_ rect: UIRect, fill: UIFill, radii: UICornerRadii = .zero) {
        addBox(rect, fill: fill, radii: radii, stroke: 0, mode: 0, smoothing: 0, texture: nil, sampler: nil, uv: .unit)
    }

    /// Strokes a `width`-point border on the inside of `rect`'s edge (like a CSS border), with
    /// rounded corners if `radii` isn't zero: the outer edge follows the same rounded rectangle `fillRect` would fill.
    public func strokeRect(_ rect: UIRect, color: UIColor, width: Float = 1, radii: UICornerRadii = .zero) {
        addBox(rect, fill: .solid(color), radii: radii, stroke: width, mode: 0, smoothing: 0, texture: nil, sampler: nil,
               uv: .unit)
    }

    /// Draws `texture` (any `.rgba8Srgb` / `.rgba8Unorm` texture) into `rect`, sampling the
    /// `uv` rectangle (0...1 covers the whole texture) multiplied by `tint`. Corners can be rounded.
    public func drawImage(_ texture: GPUTexture, in rect: UIRect, uv: UIRect = .unit, tint: UIColor = .white,
                          radii: UICornerRadii = .zero, sampler: GPUSampler? = nil) {
        addBox(rect, fill: .solid(tint), radii: radii, stroke: 0, mode: UIQuadMode.image.shaderMode, smoothing: 0,
               texture: texture, sampler: sampler, uv: uv)
    }

    /// A straight line `width` points thick, antialiased along its length and ends.
    public func drawLine(from a: Vec2, to b: Vec2, width: Float = 1, color: UIColor, cap: UILineCap = .butt) {
        let p0 = px(a), p1 = px(b)
        let thickness = max(width * pixelScale, 0)
        guard thickness > 0 else { return }
        let delta = p1 - p0
        let length = (delta * delta).sum().squareRoot()
        let u = length > 0 ? delta / length : Vec2(1, 0)
        let v = Vec2(-u.y, u.x)
        let half = thickness / 2
        let halfSize = Vec2(length / 2 + (cap == .round ? half : 0), half)
        let center = (p0 + p1) / 2
        let radius: Float = cap == .round ? half : 0
        let margin = Vec2(repeating: Self.antialiasMargin)
        var corners: [UIVertex] = []
        for (sx, sy) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
            let local = (halfSize + margin) * Vec2(sx, sy)
            corners.append(UIVertex(
                position: center + u * local.x + v * local.y, uv: .zero, color: Vec4(color.r, color.g, color.b, color.a * opacity),
                local: local, halfSize: halfSize, radii: Vec4(repeating: radius), params: .zero))
        }
        add(corners, texture: nil, sampler: nil)
    }

    // MARK: Textured quads

    /// An axis-aligned textured rectangle without edge antialiasing or rounding, for glyphs
    /// and other atlas sprites. `rect` is in points, `uv` in texture coordinates, `color`
    /// the text color (`.mask` / `.sdf`) or tint (`.image`). Consecutive calls with the same
    /// texture merge into one draw.
    public func drawTexturedRect(_ texture: GPUTexture, rect: UIRect, uv: UIRect, color: UIColor = .white,
                                 mode: UIQuadMode = .mask, sampler: GPUSampler? = nil) {
        drawTexturedQuad(texture, mode: mode, sampler: sampler, corners: [
            UIQuadCorner(position: Vec2(rect.x, rect.y), uv: Vec2(uv.x, uv.y), color: color),
            UIQuadCorner(position: Vec2(rect.maxX, rect.y), uv: Vec2(uv.maxX, uv.y), color: color),
            UIQuadCorner(position: Vec2(rect.maxX, rect.maxY), uv: Vec2(uv.maxX, uv.maxY), color: color),
            UIQuadCorner(position: Vec2(rect.x, rect.maxY), uv: Vec2(uv.x, uv.maxY), color: color),
        ])
    }

    /// A free-form textured quad from four corners in order around its edge (e.g. a rotated
    /// glyph, or per-corner colors). Positions are in points. No edge antialiasing.
    public func drawTexturedQuad(_ texture: GPUTexture, mode: UIQuadMode = .image, sampler: GPUSampler? = nil,
                                 corners: [UIQuadCorner]) {
        precondition(corners.count == 4, "A quad has four corners")
        var smoothing: Float = 0
        if case .sdf(let value) = mode { smoothing = value }
        let big = Vec2(repeating: 1e5)  // far inside: full coverage, so the SDF doesn't affect the quad
        add(corners.map {
            UIVertex(position: px($0.position), uv: $0.uv, color: Vec4($0.color.r, $0.color.g, $0.color.b, $0.color.a * opacity),
                     local: .zero, halfSize: big, radii: .zero, params: Vec4(0, mode.shaderMode, smoothing, 0))
        }, texture: texture, sampler: sampler)
    }

    // MARK: Text

    /// Draws `text` with its layout box's top-left at `origin` (points). `size` is the em size
    /// in points and `color` sRGB like every other UI color. Wraps and aligns within
    /// `maxWidth` when given (see `TextLayout`). Glyphs are SDF quads in the list's own
    /// `glyphAtlas`, so text sorts, clips and batches with the shapes around it.
    public func drawText(_ text: String, at origin: Vec2, size: Float, color: UIColor, font: Font? = nil,
                         maxWidth: Float? = nil, alignment: TextAlignment = .left, lineSpacing: Float = 1) {
        let font = font ?? Self.defaultFont
        let layout = TextLayout(text, font: font, size: size, maxWidth: maxWidth, alignment: alignment,
                                lineSpacing: lineSpacing)
        drawText(layout, font: font, at: origin, color: color)
    }

    /// Draws a laid-out text (sizes in points; lay out once and reuse it for static text).
    /// The origin is snapped to whole pixels and each line's baseline to a pixel row, so text
    /// looks the same wherever it is drawn. `glyphs` limits drawing to a range of `layout.glyphs`.
    public func drawText(_ layout: TextLayout, font: Font, at origin: Vec2, color: UIColor, glyphs: Range<Int>? = nil) {
        guard color.a * opacity > 0, !layout.glyphs.isEmpty else { return }
        let atlas = glyphAtlas
        let pixelSize = layout.size * pixelScale
        let smoothing = Self.sdfSmoothing(pixelSize: pixelSize)
        let originX = px(origin.x, 0).rounded()
        let rgba = Vec4(color.r, color.g, color.b, color.a * opacity)
        let params = Vec4(0, UIQuadMode.sdf(smoothing: smoothing).shaderMode, smoothing, 0)
        let big = Vec2(repeating: 1e5)
        for placed in layout.glyphs[glyphs ?? layout.glyphs.indices] {
            guard let info = atlas.info(for: placed.glyph, in: font) else { continue }
            let baseline = px(origin.y + placed.y, 1).rounded()
            let x0 = originX + placed.x * pixelScale + info.offset.x * pixelSize
            let y0 = baseline + info.offset.y * pixelSize
            let x1 = x0 + info.extent.x * pixelSize, y1 = y0 + info.extent.y * pixelSize
            func vertex(_ x: Float, _ y: Float, _ u: Float, _ v: Float) -> UIVertex {
                UIVertex(position: Vec2(x, y), uv: Vec2(u, v), color: rgba, local: .zero, halfSize: big, radii: .zero,
                         params: params)
            }
            appendQuad(vertex(x0, y0, info.uvMin.x, info.uvMin.y), vertex(x1, y0, info.uvMax.x, info.uvMin.y),
                       vertex(x1, y1, info.uvMax.x, info.uvMax.y), vertex(x0, y1, info.uvMin.x, info.uvMax.y),
                       source: .glyphPage(info.page), sampler: nil)
        }
    }

    /// The `.sdf` smoothing (the distance range the edge ramps over) that antialiases glyphs of
    /// the bundled atlas over one framebuffer pixel at an em size of `pixelSize` pixels: the
    /// atlas changes by `onEdgeValue / padding` per texel (of 255), at `sdfSize` texels per em.
    public static func sdfSmoothing(pixelSize: Float) -> Float {
        let perTexel = Float(GlyphAtlas.onEdgeValue) / Float(GlyphAtlas.padding) / 255
        return perTexel * GlyphAtlas.sdfSize / max(pixelSize, 1e-3)
    }

    // MARK: Building

    /// Distance the quad extends past the shape, in pixels, so the antialiased edge isn't cut off.
    static let antialiasMargin: Float = 1

    private func addBox(_ rect: UIRect, fill: UIFill, radii: UICornerRadii, stroke: Float, mode: Float, smoothing: Float,
                        texture: GPUTexture?, sampler: GPUSampler?, uv: UIRect) {
        let box = UIRect(x: px(rect.x, 0), y: px(rect.y, 1), width: rect.width * pixelScale, height: rect.height * pixelScale)
        guard box.width > 0, box.height > 0 else { return }
        let r = radii.fitted(toWidth: box.width, height: box.height, scale: pixelScale)
        let halfSize = Vec2(box.width, box.height) / 2
        let strokeWidth = stroke > 0 ? min(Self.strokePixels(stroke, scale: pixelScale), min(halfSize.x, halfSize.y)) : 0
        let radiiVector = Vec4(r.topLeft, r.topRight, r.bottomRight, r.bottomLeft)
        let margin = Self.antialiasMargin
        let center = box.center
        var corners: [UIVertex] = []
        for (sx, sy) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
            let local = (halfSize + Vec2(repeating: margin)) * Vec2(sx, sy)
            let position = center + local
            // Gradient and UV are affine in the position, so extrapolating to the margin keeps
            // the interior exact.
            let color = fill.color(at: position, in: box)
            let t = (position - Vec2(box.x, box.y)) / Vec2(box.width, box.height)
            corners.append(UIVertex(
                position: position, uv: Vec2(uv.x + uv.width * t.x, uv.y + uv.height * t.y),
                color: Vec4(color.r, color.g, color.b, color.a * opacity), local: local, halfSize: halfSize, radii: radiiVector,
                params: Vec4(strokeWidth, mode, smoothing, 0)))
        }
        add(corners, texture: texture, sampler: sampler)
    }

    /// Appends a quad (four vertices, two triangles) and merges it into the last batch if possible.
    private func add(_ quad: [UIVertex], texture: GPUTexture?, sampler: GPUSampler?) {
        appendQuad(quad[0], quad[1], quad[2], quad[3], source: texture.map { .texture($0) }, sampler: sampler)
    }

    private func appendQuad(_ v0: UIVertex, _ v1: UIVertex, _ v2: UIVertex, _ v3: UIVertex,
                            source: UITextureSource?, sampler: GPUSampler?) {
        let clip = clip
        let minX = min(min(v0.position.x, v1.position.x), min(v2.position.x, v3.position.x))
        let maxX = max(max(v0.position.x, v1.position.x), max(v2.position.x, v3.position.x))
        let minY = min(min(v0.position.y, v1.position.y), min(v2.position.y, v3.position.y))
        let maxY = max(max(v0.position.y, v1.position.y), max(v2.position.y, v3.position.y))
        if clip.isEmpty || maxX <= Float(clip.x0) || minX >= Float(clip.x1) || maxY <= Float(clip.y0) || minY >= Float(clip.y1) {
            stats.culled += 1
            return
        }

        let base = UInt32(vertices.count)
        let firstIndex = indices.count
        vertices.append(v0)
        vertices.append(v1)
        vertices.append(v2)
        vertices.append(v3)
        indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])

        if var last = batches.last, last.clip == clip, Self.canMerge(last, source: source, sampler: sampler) {
            if last.source == nil, let source {
                // Everything so far ignores the texture, so the batch can take this item's.
                last.source = source
                last.sampler = sampler
            }
            last.indexCount += 6
            batches[batches.count - 1] = last
        } else {
            batches.append(UIBatch(source: source, sampler: sampler, clip: clip, firstIndex: firstIndex, indexCount: 6))
        }
        stats.items += 1
        stats.vertices = vertices.count
        stats.indices = indices.count
        stats.batches = batches.count
    }

    /// An item without a texture fits any batch; otherwise texture and sampler must match
    /// (or the batch must not have one yet).
    private static func canMerge(_ batch: UIBatch, source: UITextureSource?, sampler: GPUSampler?) -> Bool {
        guard let source else { return true }
        guard let current = batch.source else { return true }
        return current.isSame(as: source) && batch.sampler === sampler
    }
}
