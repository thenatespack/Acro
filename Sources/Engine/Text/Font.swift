import CStbTrueType
import Foundation

/// A TrueType / OpenType (glyf outlines) font, parsed with stb_truetype. All metrics are in
/// em units (multiply by the font size in pixels). Kerning comes from GPOS pair adjustments
/// (the `kern` feature) or, failing that, the legacy `kern` table.
///
/// Text is mapped one Unicode scalar to one glyph through the `cmap` table. Complex shaping
/// (ligatures, contextual forms, right-to-left and bidirectional text, combining marks and
/// other mark positioning) is out of scope: a scalar the font lacks renders as `.notdef`.
public final class Font {
    /// An index into the font's glyph table.
    public typealias Glyph = Int32

    private let data: UnsafeMutableRawPointer
    private let info: UnsafeMutablePointer<stbtt_fontinfo>
    /// Font units to em: multiply a font-unit value by this.
    private let perEm: Float
    /// Pair kerning from GPOS, which stb_truetype can't read for most modern fonts (see `GPOSKerning`).
    private let gposKerning: GPOSKerning?

    /// Distance from the baseline to the top of the line (positive).
    public let ascent: Float
    /// Distance from the baseline to the bottom of the line (negative).
    public let descent: Float
    /// Extra spacing between lines.
    public let lineGap: Float
    /// Baseline-to-baseline distance: `ascent - descent + lineGap`.
    public var lineHeight: Float { ascent - descent + lineGap }

    /// Parses font number `index` of `bytes` (the first of a TrueType Collection `.ttc` by
    /// default; the bytes are copied).
    public init(data bytes: [UInt8], index: Int = 0) throws {
        let copy = UnsafeMutableRawPointer.allocate(byteCount: max(bytes.count, 1), alignment: 16)
        bytes.withUnsafeBytes { raw in
            if let base = raw.baseAddress { copy.copyMemory(from: base, byteCount: raw.count) }
        }
        data = copy
        info = .allocate(capacity: 1)
        let pointer = data.assumingMemoryBound(to: UInt8.self)
        let offset = bytes.isEmpty ? -1 : stbtt_GetFontOffsetForIndex(pointer, Int32(index))
        guard offset >= 0, stbtt_InitFont(info, pointer, offset) != 0 else {
            data.deallocate()
            info.deallocate()
            throw FontError("Not a valid TrueType/OpenType font (\(bytes.count) bytes)")
        }
        perEm = stbtt_ScaleForMappingEmToPixels(info, 1)
        gposKerning = GPOSKerning(font: bytes)
        var a: Int32 = 0, d: Int32 = 0, g: Int32 = 0
        stbtt_GetFontVMetrics(info, &a, &d, &g)
        ascent = Float(a) * perEm
        descent = Float(d) * perEm
        lineGap = Float(g) * perEm
    }

    public convenience init(contentsOf url: URL, index: Int = 0) throws {
        try self.init(data: [UInt8](try Data(contentsOf: url)), index: index)
    }

    deinit {
        data.deallocate()
        info.deallocate()
    }

    /// Inter Regular (SIL Open Font License; see `Fonts/Inter-LICENSE.txt`), bundled with the engine.
    public static func bundledUI() throws -> Font {
        guard let url = Bundle.module.url(forResource: "Inter-Regular", withExtension: "ttf", subdirectory: "Fonts") else {
            throw FontError("Bundled font Inter-Regular.ttf not found")
        }
        return try Font(contentsOf: url)
    }

    /// The glyph for `scalar`; 0 (`.notdef`) when the font has none.
    public func glyph(for scalar: Unicode.Scalar) -> Glyph {
        stbtt_FindGlyphIndex(info, Int32(scalar.value))
    }

    /// Whether the font maps `scalar` to a real glyph.
    public func hasGlyph(for scalar: Unicode.Scalar) -> Bool { glyph(for: scalar) != 0 }

    /// Horizontal advance in em.
    public func advance(of glyph: Glyph) -> Float {
        var advance: Int32 = 0, bearing: Int32 = 0
        stbtt_GetGlyphHMetrics(info, glyph, &advance, &bearing)
        return Float(advance) * perEm
    }

    /// Extra advance in em between `left` and `right` (usually negative or zero).
    public func kerning(_ left: Glyph, _ right: Glyph) -> Float {
        if let gposKerning { return Float(gposKerning.adjustment(Int(left), Int(right))) * perEm }
        return Float(stbtt_GetGlyphKernAdvance(info, left, right)) * perEm
    }

    /// A signed-distance-field bitmap of `glyph` for an em of `emPixels`: distance to the
    /// outline in the bytes (`onEdge` on the outline, rising inside, `onEdge / padding` per
    /// pixel). `xOffset` / `yOffset` place the bitmap's top-left relative to the glyph origin
    /// on the baseline (y down). nil for glyphs without an outline (space).
    func sdf(of glyph: Glyph, emPixels: Float, padding: Int, onEdge: UInt8)
        -> (pixels: [UInt8], width: Int, height: Int, xOffset: Int, yOffset: Int)? {
        var width: Int32 = 0, height: Int32 = 0, xOffset: Int32 = 0, yOffset: Int32 = 0
        let scale = stbtt_ScaleForMappingEmToPixels(info, emPixels)
        guard let bitmap = stbtt_GetGlyphSDF(
            info, scale, glyph, Int32(padding), onEdge, Float(onEdge) / Float(padding),
            &width, &height, &xOffset, &yOffset) else { return nil }
        defer { stbtt_FreeSDF(bitmap, nil) }
        guard width > 0, height > 0 else { return nil }
        let pixels = Array(UnsafeBufferPointer(start: bitmap, count: Int(width * height)))
        return (pixels, Int(width), Int(height), Int(xOffset), Int(yOffset))
    }
}

public struct FontError: Error, CustomStringConvertible {
    public var description: String
    public init(_ description: String) { self.description = description }
}
