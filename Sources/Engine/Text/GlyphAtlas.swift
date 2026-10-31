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
/// A page's texture is created once (when it first has glyphs). After that `uploadDirtyPages`
/// writes only the bounding rectangle of the glyphs added since the last upload
/// (`RenderDevice.updateTexture`), so new glyphs trickling in cost a few KiB instead of a whole
/// page. Several new glyphs in one frame share one update per page; warm the atlas up front
/// (`prewarm`) for large character sets so no update lands in a frame at all.
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
        /// Bounding box of the pixels written since the last upload (x/y inclusive-exclusive).
        var dirty: (x0: Int, y0: Int, x1: Int, y1: Int)?

        func markDirty(x: Int, y: Int, width: Int, height: Int) {
            guard let d = dirty else { dirty = (x, y, x + width, y + height); return }
            dirty = (min(d.x0, x), min(d.y0, y), max(d.x1, x + width), max(d.y1, y + height))
        }

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
        page.markDirty(x: x, y: y, width: w, height: h)
        let size = Float(pageSize)
        return GlyphInfo(
            page: index,
            uvMin: Vec2(Float(x) / size, Float(y) / size),
            uvMax: Vec2(Float(x + w) / size, Float(y + h) / size),
            offset: Vec2(Float(bitmap.xOffset), Float(bitmap.yOffset)) / Self.sdfSize,
            extent: Vec2(Float(w), Float(h)) / Self.sdfSize)
    }

    /// Creates the texture of every new page and writes the changed rectangle of every page that
    /// gained glyphs since the last call. Both block on Vulkan, so prefer calling this outside a
    /// hot path (e.g. after `prewarm`); `TextRenderer.render` calls it for you. Returns how many
    /// texels were uploaded (0 when nothing changed), mostly useful for tests and stats.
    @discardableResult
    public func uploadDirtyPages(device: RenderDevice) throws -> Int {
        var uploaded = 0
        for page in pages {
            guard let texture = page.texture else {
                page.texture = try device.makeTexture(
                    pixels: page.pixels, width: pageSize, height: pageSize, format: .rgba8Unorm, generateMipmaps: false)
                page.dirty = nil
                uploaded += pageSize * pageSize
                continue
            }
            guard let d = page.dirty else { continue }
            let width = d.x1 - d.x0, height = d.y1 - d.y0
            var rows = [UInt8]()
            rows.reserveCapacity(width * height * 4)
            for y in d.y0..<d.y1 {
                let start = (y * pageSize + d.x0) * 4
                rows.append(contentsOf: page.pixels[start..<start + width * 4])
            }
            try device.updateTexture(texture, region: TextureRegion(x: d.x0, y: d.y0, width: width, height: height), pixels: rows)
            page.dirty = nil
            uploaded += width * height
        }
        return uploaded
    }

    /// The texture of `page` as of the last `uploadDirtyPages`.
    public func texture(page: Int) -> GPUTexture? { pages[page].texture }

    /// The atlas bitmap of one page as `pageSize`² RGBA8 pixels (the CPU copy of its texture).
    public func pixels(page: Int) -> [UInt8] { pages[page].pixels }
}
