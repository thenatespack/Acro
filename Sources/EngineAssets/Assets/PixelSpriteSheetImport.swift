import Foundation
import EngineCore

// Turning an RGBA sprite sheet (a PNG of frames in a grid) into a `PixelSprite`: slice it into
// frames, then map every pixel to a palette, either a given one (nearest color) or one built from
// the sheet's own colors (median cut when it has more than fit).

/// How a sheet image is cut into frames: cells of `frameWidth` x `frameHeight` read left to right,
/// top to bottom, after `margin` pixels around the sheet and `spacing` pixels between cells.
public struct PixelSheetSlicing: Codable, Equatable, Sendable {
    public var frameWidth: Int
    public var frameHeight: Int
    public var margin: Int
    public var spacing: Int
    /// At most this many frames (default: every cell).
    public var frameCount: Int?
    /// Drop fully transparent cells at the end of the sheet (a partly filled last row).
    public var dropEmptyTrailingFrames: Bool

    public init(frameWidth: Int, frameHeight: Int, margin: Int = 0, spacing: Int = 0, frameCount: Int? = nil,
                dropEmptyTrailingFrames: Bool = true) {
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.margin = margin
        self.spacing = spacing
        self.frameCount = frameCount
        self.dropEmptyTrailingFrames = dropEmptyTrailingFrames
    }

    /// Columns and rows of whole cells that fit in a `width` x `height` image.
    public func grid(width: Int, height: Int) -> (columns: Int, rows: Int) {
        func count(_ size: Int, _ cell: Int) -> Int {
            let room = size - 2 * margin + spacing
            return cell > 0 && room > 0 ? room / (cell + spacing) : 0
        }
        return (count(width, frameWidth), count(height, frameHeight))
    }
}

public enum PixelSheetImportError: Error, CustomStringConvertible, Equatable {
    case badFrameSize(Int, Int)
    case noWholeFrame(imageWidth: Int, imageHeight: Int)
    case emptyPalette

    public var description: String {
        switch self {
        case .badFrameSize(let w, let h): "frame size \(w) x \(h) must be 1-\(PixelSprite.maxSize) pixels on each side"
        case .noWholeFrame(let w, let h): "no whole frame fits in the \(w) x \(h) image with that frame size, margin and spacing"
        case .emptyPalette: "the palette is empty"
        }
    }
}

extension PixelSprite {
    /// What `init(sheet:…)` did, for reporting.
    public struct SheetImportReport: Equatable, Sendable {
        public var columns: Int
        public var rows: Int
        /// Distinct opaque-enough colors in the sliced frames.
        public var colorsFound: Int
        /// Whether colors were merged or mapped to a nearest palette entry.
        public var quantized: Bool
        public var warnings: [String]
    }

    /// A sprite from an RGBA sheet: one frame per cell (`slicing`), one layer, each pixel mapped to
    /// `palette` by nearest color, or with no palette to the sheet's own colors (reduced to
    /// `maxColors` by median cut when there are more). Pixels with alpha below `alphaThreshold`
    /// become transparent; other alpha values are kept in the palette colors.
    public init(sheet image: Image, slicing: PixelSheetSlicing, palette: [PixelColor]? = nil, maxColors: Int = PixelSprite.maxColors,
                alphaThreshold: UInt8 = 128, duration: Int = 100) throws {
        self = try Self.importingSheet(image, slicing: slicing, palette: palette, maxColors: maxColors,
                                       alphaThreshold: alphaThreshold, duration: duration).sprite
    }

    /// `init(sheet:…)` with a report of what it did.
    public static func importingSheet(_ image: Image, slicing: PixelSheetSlicing, palette given: [PixelColor]? = nil,
                                      maxColors: Int = PixelSprite.maxColors, alphaThreshold: UInt8 = 128,
                                      duration: Int = 100) throws -> (sprite: PixelSprite, report: SheetImportReport) {
        var r = SheetImportReport(columns: 0, rows: 0, colorsFound: 0, quantized: false, warnings: [])
        let (fw, fh) = (slicing.frameWidth, slicing.frameHeight)
        guard (1...Self.maxSize).contains(fw), (1...Self.maxSize).contains(fh) else { throw PixelSheetImportError.badFrameSize(fw, fh) }
        let (columns, rows) = slicing.grid(width: image.width, height: image.height)
        guard columns > 0, rows > 0 else { throw PixelSheetImportError.noWholeFrame(imageWidth: image.width, imageHeight: image.height) }
        (r.columns, r.rows) = (columns, rows)
        var cellCount = columns * rows
        if let limit = slicing.frameCount {
            if limit > cellCount { r.warnings.append("the sheet has \(cellCount) frames, fewer than the \(limit) asked for") }
            cellCount = min(max(limit, 1), cellCount)
        }

        // Read each cell's pixels as colors (nil: transparent).
        var cells: [[PixelColor?]] = []
        for i in 0..<cellCount {
            let ox = slicing.margin + (i % columns) * (fw + slicing.spacing)
            let oy = slicing.margin + (i / columns) * (fh + slicing.spacing)
            var cell = [PixelColor?](repeating: nil, count: fw * fh)
            for y in 0..<fh {
                for x in 0..<fw {
                    let o = ((oy + y) * image.width + ox + x) * 4
                    let a = image.pixels[o + 3]
                    guard a >= alphaThreshold, a > 0 else { continue }
                    cell[y * fw + x] = PixelColor(image.pixels[o], image.pixels[o + 1], image.pixels[o + 2], a)
                }
            }
            cells.append(cell)
        }
        if slicing.dropEmptyTrailingFrames {
            let before = cells.count
            while cells.count > 1, cells.last!.allSatisfy({ $0 == nil }) { cells.removeLast() }
            if cells.count < before { r.warnings.append("dropped \(before - cells.count) empty frame(s) at the end of the sheet") }
        }

        var counts: [PixelColor: Int] = [:]
        for cell in cells { for case let c? in cell { counts[c, default: 0] += 1 } }
        r.colorsFound = counts.count
        let limit = min(max(maxColors, 1), Self.maxColors)
        let palette: [PixelColor]
        if let given {
            guard !given.isEmpty else { throw PixelSheetImportError.emptyPalette }
            if given.count > Self.maxColors { r.warnings.append("only the first \(Self.maxColors) palette colors are used") }
            palette = Array(given.prefix(Self.maxColors))
            r.quantized = counts.keys.contains { !palette.contains($0) }
        } else if counts.count <= limit {
            // Most used first, so the common colors get the short characters.
            palette = counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.description < $1.key.description }.map(\.key)
        } else {
            palette = Self.medianCut(counts, to: limit)
            r.quantized = true
            r.warnings.append("the sheet has \(counts.count) colors; reduced to \(palette.count)")
        }

        var lookup: [PixelColor: UInt8] = [:]
        for (i, c) in palette.enumerated() where lookup[c] == nil { lookup[c] = UInt8(i + 1) }
        func value(_ c: PixelColor) -> UInt8 {
            if let v = lookup[c] { return v }
            let v = Self.nearest(c, in: palette)
            lookup[c] = v
            return v
        }
        let layerCels = cells.map { cell in cell.map { $0.map(value) ?? 0 } }
        var sprite = PixelSprite(width: fw, height: fh, palette: palette.isEmpty ? [PixelColor(0, 0, 0)] : palette, frameCount: cells.count)
        sprite.layers = [Layer(name: "Layer 1", cels: layerCels)]
        sprite.frames = Array(repeating: Frame(duration: max(duration, 1)), count: cells.count)
        sprite.normalize()
        return (sprite, r)
    }

    /// The pixel value of the palette entry closest to `color` (RGBA distance, green weighted).
    static func nearest(_ color: PixelColor, in palette: [PixelColor]) -> UInt8 {
        var best = 0, bestDistance = Int.max
        for (i, p) in palette.enumerated() {
            let dr = Int(color.r) - Int(p.r), dg = Int(color.g) - Int(p.g), db = Int(color.b) - Int(p.b), da = Int(color.a) - Int(p.a)
            let d = 3 * dr * dr + 4 * dg * dg + 2 * db * db + 3 * da * da
            if d < bestDistance { (best, bestDistance) = (i, d) }
        }
        return UInt8(best + 1)
    }

    /// Reduces weighted colors to at most `count` by median cut (mean-split variant): the box with
    /// the most pixels times channel range is split along its widest channel at the weighted mean
    /// until there are `count` boxes; each box becomes its weighted average color.
    static func medianCut(_ counts: [PixelColor: Int], to count: Int) -> [PixelColor] {
        typealias Entry = (color: PixelColor, weight: Int)
        func channel(_ c: PixelColor, _ k: Int) -> Int { k == 0 ? Int(c.r) : k == 1 ? Int(c.g) : k == 2 ? Int(c.b) : Int(c.a) }
        func widest(_ box: [Entry]) -> (channel: Int, range: Int) {
            var best = (0, -1)
            for k in 0..<4 {
                let values = box.map { channel($0.color, k) }
                let range = (values.max() ?? 0) - (values.min() ?? 0)
                if range > best.1 { best = (k, range) }
            }
            return best
        }
        var boxes: [[Entry]] = [counts.map { ($0.key, $0.value) }.sorted { $0.color.description < $1.color.description }]
        while boxes.count < count {
            // Split the box with the most pixels among those that can still be split, weighted by range.
            var pick: Int?
            var score = 0
            for (i, box) in boxes.enumerated() where box.count > 1 {
                let w = box.reduce(0) { $0 + $1.weight }
                let s = w * (widest(box).range + 1)
                if s > score { (pick, score) = (i, s) }
            }
            guard let i = pick else { break }
            let k = widest(boxes[i]).channel
            let sorted = boxes[i].sorted { channel($0.color, k) != channel($1.color, k) ? channel($0.color, k) < channel($1.color, k) : $0.color.description < $1.color.description }
            let total = sorted.reduce(0) { $0 + $1.weight }
            // Split at the weighted mean (keeps tight clusters whole, unlike the median).
            let mean = Double(sorted.reduce(0) { $0 + channel($1.color, k) * $1.weight }) / Double(max(total, 1))
            let firstAbove = sorted.firstIndex { Double(channel($0.color, k)) > mean } ?? sorted.count
            let cut = min(max(firstAbove, 1), sorted.count - 1)
            boxes[i] = Array(sorted[..<cut])
            boxes.append(Array(sorted[cut...]))
        }
        var seen = Set<PixelColor>()
        return boxes
            .map { box -> (PixelColor, Int) in
                let w = box.reduce(0) { $0 + $1.weight }
                func avg(_ k: Int) -> UInt8 { UInt8((box.reduce(0) { $0 + channel($1.color, k) * $1.weight } + w / 2) / max(w, 1)) }
                return (PixelColor(avg(0), avg(1), avg(2), avg(3)), w)
            }
            .sorted { $0.1 > $1.1 }
            .compactMap { seen.insert($0.0).inserted ? $0.0 : nil }
    }
}
