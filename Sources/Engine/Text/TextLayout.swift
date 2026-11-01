public enum TextAlignment: String, Codable, Sendable, CaseIterable {
    case left, center, right
}

/// One glyph placed by `TextLayout`.
public struct PositionedGlyph: Sendable {
    public var glyph: Font.Glyph
    /// The glyph origin: x is the pen position, y the baseline, in pixels from the layout's top-left.
    public var x: Float
    public var y: Float
    /// Index into `TextLayout.lines`.
    public var line: Int
}

/// Text broken into lines and positioned, without touching the GPU. Scalars are looked up one
/// glyph each and advanced by the font's advance plus pair kerning. Complex shaping
/// (ligatures, right-to-left and bidirectional text, combining marks) is not supported; see `Font`.
///
/// - `\n` (and `\r\n`) start a new line; a tab is a space; other control characters are skipped.
/// - With `maxWidth`, lines break at spaces so that they fit; a word wider than the box is
///   broken between glyphs (at least one glyph per line). Spaces at a break are dropped, as
///   are trailing spaces. Without `maxWidth` only explicit newlines break lines.
/// - `alignment` places each line within the box: `maxWidth`, or the widest line without one.
///
/// Coordinates are pixels with y down, relative to the top-left of the box. Every line is
/// `lineHeight` tall (the font's ascent - descent + line gap, times `lineSpacing`). Even empty
/// text has one line.
public struct TextLayout {
    public struct Line: Sendable {
        /// Range in `glyphs`.
        public var glyphs: Range<Int>
        /// Width of the line's advances.
        public var width: Float
        /// Left edge of the line within the box (set by the alignment).
        public var x: Float
    }

    public private(set) var glyphs: [PositionedGlyph] = []
    public private(set) var lines: [Line] = []
    /// Width of the widest line. Alignment is relative to `maxWidth` when one was given, but
    /// this stays the measured width of the text.
    public private(set) var width: Float = 0
    /// `lines.count * lineHeight`.
    public private(set) var height: Float = 0
    /// The em size in pixels.
    public let size: Float
    public let lineHeight: Float

    public var bounds: Vec2 { Vec2(width, height) }

    public init(_ text: String, font: Font, size: Float, maxWidth: Float? = nil,
                alignment: TextAlignment = .left, lineSpacing: Float = 1) {
        self.size = size
        lineHeight = font.lineHeight * size * lineSpacing

        func advanceWidth(_ run: [Font.Glyph]) -> Float {
            var total: Float = 0
            for (i, glyph) in run.enumerated() {
                total += font.advance(of: glyph)
                if i + 1 < run.count { total += font.kerning(glyph, run[i + 1]) }
            }
            return total * size
        }

        var broken: [[Font.Glyph]] = []
        let space = font.glyph(for: " ")
        for paragraph in text.unicodeScalars.split(separator: "\n", omittingEmptySubsequences: false) {
            // Words, each with the spaces before it.
            var words: [(spaces: Int, glyphs: [Font.Glyph])] = []
            var word: [Font.Glyph] = []
            var wordSpaces = 0, pending = 0
            for scalar in paragraph {
                if scalar == " " || scalar == "\t" {
                    if !word.isEmpty { words.append((wordSpaces, word)); word = [] }
                    pending += 1
                } else if scalar.value >= 0x20, scalar.value != 0x7F {
                    if word.isEmpty { wordSpaces = pending; pending = 0 }
                    word.append(font.glyph(for: scalar))
                }
            }
            if !word.isEmpty { words.append((wordSpaces, word)) }

            var line: [Font.Glyph] = []
            var firstLine = true
            func commit() {
                broken.append(line)
                line = []
                firstLine = false
            }
            // Starts `run` on an empty line, breaking it between glyphs if it is wider than the box.
            func place(_ run: [Font.Glyph]) {
                guard let maxWidth, advanceWidth(run) > maxWidth else { line = run; return }
                for glyph in run {
                    if !line.isEmpty, advanceWidth(line + [glyph]) > maxWidth { commit() }
                    line.append(glyph)
                }
            }
            for (spaces, word) in words {
                let gap = [Font.Glyph](repeating: space, count: spaces)
                if line.isEmpty {
                    place((firstLine ? gap : []) + word)  // keep indentation, drop spaces at a break
                } else if let maxWidth, advanceWidth(line + gap + word) > maxWidth {
                    commit()
                    place(word)
                } else {
                    line += gap + word
                }
            }
            commit()
        }

        let boxWidth = maxWidth ?? broken.map(advanceWidth).max() ?? 0
        let ascent = font.ascent * size
        for (index, run) in broken.enumerated() {
            let lineWidth = advanceWidth(run)
            let x: Float
            switch alignment {
            case .left: x = 0
            case .center: x = (boxWidth - lineWidth) / 2
            case .right: x = boxWidth - lineWidth
            }
            let baseline = ascent + Float(index) * lineHeight
            let start = glyphs.count
            var pen = x
            for (i, glyph) in run.enumerated() {
                glyphs.append(PositionedGlyph(glyph: glyph, x: pen, y: baseline, line: index))
                pen += font.advance(of: glyph) * size
                if i + 1 < run.count { pen += font.kerning(glyph, run[i + 1]) * size }
            }
            lines.append(Line(glyphs: start..<glyphs.count, width: lineWidth, x: x))
            width = max(width, lineWidth)
        }
        height = Float(lines.count) * lineHeight
    }
}
