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
    /// Hook for signed-distance-field text: the texture's alpha is a distance field (0.5 on
    /// the outline, larger inside) and `smoothing` the antialiasing width in distance units
    /// (about 0.7 / (spread in texels * on-screen scale)). The shader path exists (`MODE_SDF`
    /// in ui.frag) but is untested until a text renderer uses it.
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

/// A run of consecutive items drawn with one call.
struct UIBatch {
    /// nil for items that don't sample a texture; the renderer binds a white one.
    var texture: GPUTexture?
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

    public init() {}

    /// Clears the list for a new frame. The engine calls this before `Game.update`.
    func beginFrame(framebufferSize: (width: Int, height: Int), scale: Float) {
        precondition(clipStack.isEmpty, "UIDrawList: pushClip without a matching popClip")
        self.framebufferSize = framebufferSize
        self.scale = max(scale, 0.01)
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
        return c.isEmpty ? nil : UIRect(x: Float(c.x0) / scale, y: Float(c.y0) / scale,
                                         width: Float(c.x1 - c.x0) / scale, height: Float(c.y1 - c.y0) / scale)
    }

    /// Restricts drawing to `rect` (points) intersected with the current clip, until the matching `popClip`.
    public func pushClip(_ rect: UIRect) {
        let pixels = UIPixelRect(
            x0: Int((rect.x * scale).rounded()), y0: Int((rect.y * scale).rounded()),
            x1: Int((rect.maxX * scale).rounded()), y1: Int((rect.maxY * scale).rounded()))
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
        let p0 = a * scale, p1 = b * scale
        let thickness = max(width * scale, 0)
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
                position: center + u * local.x + v * local.y, uv: .zero, color: Vec4(color.r, color.g, color.b, color.a),
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
            UIVertex(position: $0.position * scale, uv: $0.uv, color: Vec4($0.color.r, $0.color.g, $0.color.b, $0.color.a),
                     local: .zero, halfSize: big, radii: .zero, params: Vec4(0, mode.shaderMode, smoothing, 0))
        }, texture: texture, sampler: sampler)
    }

    // MARK: Building

    /// Distance the quad extends past the shape, in pixels, so the antialiased edge isn't cut off.
    static let antialiasMargin: Float = 1

    private func addBox(_ rect: UIRect, fill: UIFill, radii: UICornerRadii, stroke: Float, mode: Float, smoothing: Float,
                        texture: GPUTexture?, sampler: GPUSampler?, uv: UIRect) {
        let box = UIRect(x: rect.x * scale, y: rect.y * scale, width: rect.width * scale, height: rect.height * scale)
        guard box.width > 0, box.height > 0 else { return }
        let r = radii.fitted(toWidth: box.width, height: box.height, scale: scale)
        let halfSize = Vec2(box.width, box.height) / 2
        let strokeWidth = stroke > 0 ? min(stroke * scale, min(halfSize.x, halfSize.y)) : 0
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
                color: Vec4(color.r, color.g, color.b, color.a), local: local, halfSize: halfSize, radii: radiiVector,
                params: Vec4(strokeWidth, mode, smoothing, 0)))
        }
        add(corners, texture: texture, sampler: sampler)
    }

    /// Appends a quad (four vertices, two triangles) and merges it into the last batch if possible.
    private func add(_ quad: [UIVertex], texture: GPUTexture?, sampler: GPUSampler?) {
        let clip = clip
        var minX = Float.infinity, minY = Float.infinity, maxX = -Float.infinity, maxY = -Float.infinity
        for vertex in quad {
            minX = min(minX, vertex.position.x)
            maxX = max(maxX, vertex.position.x)
            minY = min(minY, vertex.position.y)
            maxY = max(maxY, vertex.position.y)
        }
        if clip.isEmpty || maxX <= Float(clip.x0) || minX >= Float(clip.x1) || maxY <= Float(clip.y0) || minY >= Float(clip.y1) {
            stats.culled += 1
            return
        }

        let base = UInt32(vertices.count)
        let firstIndex = indices.count
        vertices.append(contentsOf: quad)
        indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])

        if var last = batches.last, last.clip == clip, Self.canMerge(last, texture: texture, sampler: sampler) {
            if last.texture == nil, let texture {
                // Everything so far ignores the texture, so the batch can take this item's.
                last.texture = texture
                last.sampler = sampler
            }
            last.indexCount += 6
            batches[batches.count - 1] = last
        } else {
            batches.append(UIBatch(texture: texture, sampler: sampler, clip: clip, firstIndex: firstIndex, indexCount: 6))
        }
        stats.items += 1
        stats.vertices = vertices.count
        stats.indices = indices.count
        stats.batches = batches.count
    }

    /// An item without a texture fits any batch; otherwise texture and sampler must match
    /// (or the batch must not have one yet).
    private static func canMerge(_ batch: UIBatch, texture: GPUTexture?, sampler: GPUSampler?) -> Bool {
        guard let texture else { return true }
        guard let current = batch.texture else { return true }
        return current === texture && batch.sampler === sampler
    }
}
