import Testing
@testable import Engine

nonisolated(unsafe) private let font = try! Font.bundledUI()

@Test func utf8DecodesToOneGlyphPerScalar() {
    // "é" is two bytes, "€" three, "😀" four; invalid bytes become U+FFFD.
    let bytes: [UInt8] = [0x61, 0xC3, 0xA9, 0xE2, 0x82, 0xAC, 0xF0, 0x9F, 0x98, 0x80, 0xFF]
    let scalars = Array(String(decoding: bytes, as: UTF8.self).unicodeScalars)
    #expect(scalars.map(\.value) == [0x61, 0xE9, 0x20AC, 0x1F600, 0xFFFD])
    let layout = TextLayout(String(decoding: bytes, as: UTF8.self), font: font, size: 20)
    #expect(layout.glyphs.count == 5)
    #expect(layout.glyphs[1].glyph == font.glyph(for: "é"))
    #expect(font.hasGlyph(for: "é") && font.hasGlyph(for: "ß") && font.hasGlyph(for: "ñ"))
}

@Test func invalidFontDataThrows() {
    #expect(throws: FontError.self) { try Font(data: [1, 2, 3, 4]) }
    #expect(throws: FontError.self) { try Font(data: []) }
}

@Test func measureScalesWithSizeAndMatchesAdvances() {
    let small = TextLayout("Hello", font: font, size: 10)
    let large = TextLayout("Hello", font: font, size: 20)
    #expect(abs(large.width - small.width * 2) < 0.01)
    #expect(abs(large.height - font.lineHeight * 20) < 0.01)
    #expect(small.lines.count == 1)
    var expected: Float = 0
    let glyphs = "Hello".unicodeScalars.map { font.glyph(for: $0) }
    for (i, g) in glyphs.enumerated() {
        expected += font.advance(of: g)
        if i + 1 < glyphs.count { expected += font.kerning(g, glyphs[i + 1]) }
    }
    #expect(abs(small.width - expected * 10) < 0.01)
}

@Test func kerningPairsTightenAdvance() {
    let a = font.glyph(for: "A"), v = font.glyph(for: "V")
    #expect(font.kerning(a, v) < 0)
    let pair = TextLayout("AV", font: font, size: 100)
    #expect(pair.glyphs[1].x < font.advance(of: a) * 100)
}

@Test func newlinesStartLines() {
    let layout = TextLayout("a\nb\r\n\nc", font: font, size: 16)
    #expect(layout.lines.count == 4)
    #expect(abs(layout.height - 4 * layout.lineHeight) < 0.01)
    #expect(layout.glyphs.map(\.line) == [0, 1, 3])
    #expect(abs(layout.glyphs[2].y - (font.ascent * 16 + 3 * layout.lineHeight)) < 0.01)
    #expect(TextLayout("", font: font, size: 16).lines.count == 1)
}

@Test func wrappingKeepsLinesWithinMaxWidth() {
    let text = "The quick brown fox jumps over the lazy dog and keeps running"
    let layout = TextLayout(text, font: font, size: 20, maxWidth: 200)
    #expect(layout.lines.count > 2)
    #expect(layout.lines.allSatisfy { $0.width <= 200.001 })
    // Nothing is lost except the spaces at breaks.
    let visible = text.unicodeScalars.filter { $0 != " " }.count
    let placed = layout.glyphs.filter { $0.glyph != font.glyph(for: " ") }.count
    #expect(visible == placed)
}

@Test func longWordsBreakBetweenGlyphs() {
    let layout = TextLayout("Pneumonoultramicroscopic", font: font, size: 20, maxWidth: 80)
    #expect(layout.lines.count > 1)
    #expect(layout.lines.allSatisfy { $0.width <= 80.001 && !$0.glyphs.isEmpty })
    #expect(layout.glyphs.count == 24)
    // A box narrower than one glyph still makes progress.
    #expect(TextLayout("WWW", font: font, size: 20, maxWidth: 1).lines.count == 3)
}

@Test func alignmentOffsetsLinesWithinTheBox() {
    let left = TextLayout("ab", font: font, size: 20, maxWidth: 200, alignment: .left)
    let center = TextLayout("ab", font: font, size: 20, maxWidth: 200, alignment: .center)
    let right = TextLayout("ab", font: font, size: 20, maxWidth: 200, alignment: .right)
    let w = left.width
    #expect(left.lines[0].x == 0)
    #expect(abs(center.lines[0].x - (200 - w) / 2) < 0.01)
    #expect(abs(right.lines[0].x - (200 - w)) < 0.01)
    #expect(abs(right.glyphs[0].x - (200 - w)) < 0.01)
    // Without a box, alignment is relative to the widest line.
    let multi = TextLayout("a\nabc", font: font, size: 20, alignment: .right)
    #expect(abs(multi.lines[1].x) < 0.01 && multi.lines[0].x > 0)
}

@Test func packerPlacesWithoutOverlapAndRejectsMisfits() {
    var packer = ShelfPacker(width: 64, height: 64)
    var placed: [(x: Int, y: Int, w: Int, h: Int)] = []
    let sizes = [(20, 10), (30, 12), (14, 8), (20, 20), (40, 6), (64, 10), (10, 30), (25, 25)]
    for (w, h) in sizes {
        if let origin = packer.pack(width: w, height: h) {
            #expect(origin.x >= 0 && origin.y >= 0 && origin.x + w <= 64 && origin.y + h <= 64)
            placed.append((origin.x, origin.y, w, h))
        }
    }
    #expect(placed.count >= 6)
    for i in placed.indices {
        for j in placed.indices where j > i {
            let a = placed[i], b = placed[j]
            let overlap = a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
            #expect(!overlap)
        }
    }
    #expect(packer.pack(width: 65, height: 1) == nil)
    #expect(packer.pack(width: 0, height: 5) == nil)
}

@Test func packerReusesShelvesAndFillsUp() {
    var packer = ShelfPacker(width: 30, height: 20)
    #expect(packer.pack(width: 10, height: 10)! == (0, 0))
    // Fits on the first shelf (same row), shorter rect too.
    #expect(packer.pack(width: 10, height: 8)! == (10, 0))
    // Taller than the shelf: new shelf below.
    #expect(packer.pack(width: 10, height: 10)! == (20, 0))
    #expect(packer.pack(width: 10, height: 10)! == (0, 10))
    #expect(packer.pack(width: 25, height: 11) == nil)
}

@MainActor @Test func atlasRasterizesOnceAndCachesGlyphs() {
    let atlas = GlyphAtlas(pageSize: 256)
    let g = font.glyph(for: "g")
    let first = atlas.info(for: g, in: font)!
    let second = atlas.info(for: g, in: font)!
    #expect(first.uvMin == second.uvMin && first.page == second.page)
    #expect(atlas.glyphCount == 1)
    #expect(atlas.info(for: font.glyph(for: " "), in: font) == nil)  // no outline
    #expect(atlas.glyphCount == 1)
    // The stored distance is high inside the glyph and low outside.
    let pixels = atlas.pixels(page: 0)
    #expect(pixels[(Int(first.uvMin.y * 256) + 1) * 256 * 4 + Int(first.uvMin.x * 256) * 4] == 0)
    #expect(pixels.contains { $0 > 170 })
}

@MainActor @Test func atlasAddsPagesWhenFullAndKeepsEarlierGlyphsStable() {
    let atlas = GlyphAtlas(pageSize: 128)
    let first = atlas.info(for: font.glyph(for: "A"), in: font)!
    atlas.prewarm("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", font: font)
    #expect(atlas.pageCount > 1)
    #expect(atlas.glyphCount == 62)
    let again = atlas.info(for: font.glyph(for: "A"), in: font)!
    #expect(again.page == first.page && again.uvMin == first.uvMin && again.uvMax == first.uvMax)
    // Every glyph's rectangle lies inside its page.
    for scalar in "AZaz09".unicodeScalars {
        let info = atlas.info(for: font.glyph(for: scalar), in: font)!
        #expect(info.page < atlas.pageCount)
        #expect(info.uvMin.x >= 0 && info.uvMin.y >= 0 && info.uvMax.x <= 1 && info.uvMax.y <= 1)
    }
}

@MainActor @Test func quadsAreGroupedByPage() {
    let atlas = GlyphAtlas(pageSize: 128)
    let layout = TextLayout("Hello, world! Quick brown fox", font: font, size: 24)
    var quads = TextQuads()
    atlas.appendQuads(layout, font: font, origin: Vec2(10, 20), color: Vec4(1, 0, 0, 1), to: &quads)
    let letters = layout.glyphs.filter { atlas.info(for: $0.glyph, in: font) != nil }.count
    #expect(quads.vertices.reduce(0) { $0 + $1.count } == letters * 6)
    #expect(quads.vertices.count == atlas.pageCount)
    #expect(quads.vertices.flatMap { $0 }.allSatisfy { $0.color == Vec4(1, 0, 0, 1) })
}
