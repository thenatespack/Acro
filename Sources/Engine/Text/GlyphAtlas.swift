import Foundation

/// Where a glyph lives in the atlas and how its quad sits relative to the glyph origin.
public struct GlyphInfo: Sendable {
    /// Index of the atlas page holding the bitmap.
    public var page: Int
    /// Texture coordinates of the bitmap (including its distance-field padding).
    public var uvMin: Vec2
    public var uvMax: Vec2
    /// The quad in em: top-left relative to the glyph origin on the baseline (y down), and its size.
    /// Multiply by the font size in pixels.
    public var offset: Vec2
    public var extent: Vec2
}

/// Signed-distance-field glyph bitmaps, rasterized on demand into RGBA8 pages and uploaded as
/// textures.
///
/// Every glyph is rendered once at `sdfSize` pixels per em with `padding` pixels of distance
/// field around it, and scaled to any size at draw time (the text shader reconstructs a crisp
/// edge from the distance). The distance is stored in all four channels: 128 on the outline,
/// rising to 255 inside and falling to 0 outside, 128 / `padding` per pixel.
///
/// Bitmaps are packed into square pages of `pageSize` with a `ShelfPacker` (one transparent
/// pixel between neighbors, so bilinear filtering never mixes glyphs). A full page is kept and
/// another one added, so UVs stay valid and existing glyphs never move; draw one batch per page.
///
/// The `RenderDevice` has no texture sub-region update, so a page that gained glyphs is
/// re-created from its CPU copy (`uploadDirtyPages`, one `pageSize`² x 4 byte upload per dirty
/// page). That is cheap when text is stable and fine for new glyphs trickling in, but warm the
/// atlas up front (`prewarm`) for large character sets.
@MainActor
public final class GlyphAtlas {
    /// Pixels per em of the stored bitmaps.
    public static let sdfSize: Float = 48
    /// Distance-field margin around each glyph, in atlas pixels.
    public static let padding = 6
    /// Stored value on the glyph outline.
    public static let onEdgeValue: UInt8 = 128

    final class Page {
        var packer: ShelfPacker
        var pixels: [UInt8]
        var texture: GPUTexture?
        var dirty = false

        init(size: Int) {
            packer = ShelfPacker(width: size, height: size)
            pixels = [UInt8](repeating: 0, count: size * size * 4)
        }
    }

    private struct Key: Hashable {
        var font: ObjectIdentifier
        var glyph: Font.Glyph
    }

    public let pageSize: Int
    private(set) var pages: [Page] = []
    private var glyphs: [Key: GlyphInfo?] = [:]
    /// Keeps cached fonts alive so their `ObjectIdentifier`s stay unique.
    private var fonts: [ObjectIdentifier: Font] = [:]

    public var pageCount: Int { pages.count }
    /// Number of distinct glyphs with a bitmap in the atlas.
    public var glyphCount: Int { glyphs.values.reduce(0) { $0 + ($1 == nil ? 0 : 1) } }

    public init(pageSize: Int = 512) {
        precondition(pageSize >= 64, "Atlas pages must be at least 64 pixels")
        self.pageSize = pageSize
    }

    /// The atlas entry for `glyph`, rasterizing it first if needed. nil for glyphs without an
    /// outline (space) and for glyphs too large for a page.
    public func info(for glyph: Font.Glyph, in font: Font) -> GlyphInfo? {
        let key = Key(font: ObjectIdentifier(font), glyph: glyph)
        if let cached = glyphs[key] { return cached }
        fonts[key.font] = font
        let info = rasterize(glyph, in: font)
        glyphs[key] = info
        return info
    }

    /// Rasterizes every glyph `text` uses, so drawing it later adds nothing to the atlas.
    public func prewarm(_ text: String, font: Font) {
        for scalar in text.unicodeScalars { _ = info(for: font.glyph(for: scalar), in: font) }
    }

    private func rasterize(_ glyph: Font.Glyph, in font: Font) -> GlyphInfo? {
        guard let bitmap = font.sdf(of: glyph, emPixels: Self.sdfSize, padding: Self.padding, onEdge: Self.onEdgeValue)
        else { return nil }
        let w = bitmap.width, h = bitmap.height
        var placement: (page: Int, x: Int, y: Int)?
        for (index, page) in pages.enumerated() {
            if let origin = page.packer.pack(width: w + 1, height: h + 1) {
                placement = (index, origin.x, origin.y)
                break
            }
        }
        if placement == nil {
            let page = Page(size: pageSize)
            guard let origin = page.packer.pack(width: w + 1, height: h + 1) else { return nil }
            pages.append(page)
            placement = (pages.count - 1, origin.x, origin.y)
        }
        let (index, x, y) = placement!
        let page = pages[index]
        for row in 0..<h {
            for column in 0..<w {
                let value = bitmap.pixels[row * w + column]
                let i = ((y + row) * pageSize + x + column) * 4
                page.pixels[i] = value
                page.pixels[i + 1] = value
                page.pixels[i + 2] = value
                page.pixels[i + 3] = value
            }
        }
        page.dirty = true
        let size = Float(pageSize)
        return GlyphInfo(
            page: index,
            uvMin: Vec2(Float(x) / size, Float(y) / size),
            uvMax: Vec2(Float(x + w) / size, Float(y + h) / size),
            offset: Vec2(Float(bitmap.xOffset), Float(bitmap.yOffset)) / Self.sdfSize,
            extent: Vec2(Float(w), Float(h)) / Self.sdfSize)
    }

    /// Creates or re-creates the texture of every page that changed since the last call.
    /// `device.makeTexture` blocks on Vulkan, so prefer calling this outside a hot path
    /// (e.g. after `prewarm`); `TextRenderer.render` calls it for you.
    public func uploadDirtyPages(device: RenderDevice) throws {
        for page in pages where page.dirty || page.texture == nil {
            page.texture = try device.makeTexture(
                pixels: page.pixels, width: pageSize, height: pageSize, format: .rgba8Unorm, generateMipmaps: false)
            page.dirty = false
        }
    }

    /// The texture of `page` as of the last `uploadDirtyPages`.
    public func texture(page: Int) -> GPUTexture? { pages[page].texture }

    /// The atlas bitmap of one page as `pageSize`² RGBA8 pixels (the CPU copy of its texture).
    public func pixels(page: Int) -> [UInt8] { pages[page].pixels }
}
