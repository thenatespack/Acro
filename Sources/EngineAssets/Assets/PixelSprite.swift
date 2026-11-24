#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// An 8-bit sRGB color with alpha. Encodes as a hex string: "#rrggbb", or "#rrggbbaa" when not opaque.
public struct PixelColor: Hashable, Sendable, Codable, CustomStringConvertible {
    public var r: UInt8, g: UInt8, b: UInt8, a: UInt8

    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        (self.r, self.g, self.b, self.a) = (r, g, b, a)
    }

    /// `0xRRGGBB`.
    public init(hex: UInt32, alpha: UInt8 = 255) {
        self.init(UInt8((hex >> 16) & 0xff), UInt8((hex >> 8) & 0xff), UInt8(hex & 0xff), alpha)
    }

    /// Parses "#rgb", "#rrggbb" or "#rrggbbaa" (the "#" is optional); nil for anything else.
    public init?(hex text: String) {
        var s = text.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6 || s.count == 8, let value = UInt64(s, radix: 16) else { return nil }
        if s.count == 6 {
            self.init(hex: UInt32(value))
        } else {
            self.init(UInt8((value >> 24) & 0xff), UInt8((value >> 16) & 0xff), UInt8((value >> 8) & 0xff), UInt8(value & 0xff))
        }
    }

    public var description: String {
        a == 255 ? String(format: "#%02x%02x%02x", r, g, b) : String(format: "#%02x%02x%02x%02x", r, g, b, a)
    }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let color = PixelColor(hex: text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "'\(text)' isn't a #rrggbb color"))
        }
        self = color
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(description)
    }
}

/// Pixel art with layers, frames and tags: the contents of a `.sprite` file (JSON, every key
/// optional; `PixelSpriteImporter`).
///
/// Pixels are palette indices. In the file every cel (one layer in one frame) is a list of row
/// strings, one character per pixel: `.` is transparent and `0`-`9`, `a`-`z`, `A`-`Z` are palette
/// entries 0-61 (`PixelSprite.alphabet`). An empty list is an empty cel.
///
/// ```json
/// {"width": 4, "height": 2, "palette": ["#000000", "#ff004d"],
///  "layers": [{"name": "Body", "cels": [[".11.", "1001"], ["1..1", ".00."]]}],
///  "frames": [{"duration": 100}, {"duration": 150}],
///  "tags": [{"name": "idle", "from": 0, "to": 1, "mode": "loop"}]}
/// ```
///
/// Layers are listed bottom first and composited with their opacity; hidden layers are left out
/// of the image. Frame durations are milliseconds. Tags name a range of frames (inclusive) and
/// become one `SpriteClip` each (`SpriteSheet.clips`).
public struct PixelSprite: Codable, Equatable, Sendable {
    public static let maxSize = 256
    /// Characters for palette entries 0, 1, 2, … in cel rows.
    public static let alphabet: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    public static var maxColors: Int { alphabet.count }
    public static let transparentCharacter: Character = "."

    public enum TagMode: String, Codable, CaseIterable, Sendable {
        case loop, once, pingPong
    }

    /// A named event on a frame of a tag: the clip fires it (`SpriteAnimator.events`) each time it
    /// reaches that frame. `frame` is the sprite's frame index (inside the tag's range).
    public struct FrameEvent: Codable, Equatable, Hashable, Sendable {
        public var frame: Int
        public var name: String

        public init(frame: Int, name: String) {
            self.frame = frame
            self.name = name
        }
    }

    /// A named range of frames, played as one animation clip.
    public struct Tag: Codable, Equatable, Sendable {
        public var name: String
        /// First and last frame (inclusive).
        public var from: Int
        public var to: Int
        public var mode: TagMode
        /// Events fired when the clip reaches a frame (footsteps, hit frames, sounds).
        public var events: [FrameEvent]

        public init(_ name: String, from: Int, to: Int, mode: TagMode = .loop, events: [FrameEvent] = []) {
            self.name = name
            self.from = from
            self.to = to
            self.mode = mode
            self.events = events
        }

        private enum CodingKeys: String, CodingKey { case name, from, to, mode, events }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decodeIfPresent(String.self, forKey: .name) ?? "clip"
            from = try c.decodeIfPresent(Int.self, forKey: .from) ?? 0
            to = try c.decodeIfPresent(Int.self, forKey: .to) ?? from
            mode = try c.decodeIfPresent(TagMode.self, forKey: .mode) ?? .loop
            events = try c.decodeIfPresent([FrameEvent].self, forKey: .events) ?? []
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(name, forKey: .name)
            try c.encode(from, forKey: .from)
            try c.encode(to, forKey: .to)
            try c.encode(mode, forKey: .mode)
            if !events.isEmpty { try c.encode(events, forKey: .events) }
        }
    }

    public struct Frame: Codable, Equatable, Sendable {
        /// Milliseconds the frame shows for.
        public var duration: Int

        public init(duration: Int = 100) { self.duration = duration }

        private enum CodingKeys: String, CodingKey { case duration }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 100
        }
    }

    /// How a layer's colors combine with the layers below it (where those have pixels; over
    /// transparent pixels every mode draws like `normal`).
    public enum BlendMode: String, Codable, CaseIterable, Sendable {
        /// The layer covers what is below.
        case normal
        /// Darkens: below x layer (shadows, tints).
        case multiply
        /// Brightens: below + layer, capped at white (glows, light).
        case add
        /// Brightens softly: 1 - (1 - below)(1 - layer).
        case screen
        /// Multiply on dark parts below, screen on light ones (contrast, shading).
        case overlay

        /// The blended channel for layer value `s` over `d` (0...1).
        public func blend(_ s: Float, over d: Float) -> Float {
            switch self {
            case .normal: s
            case .multiply: s * d
            case .add: min(s + d, 1)
            case .screen: s + d - s * d
            case .overlay: d < 0.5 ? 2 * s * d : 1 - 2 * (1 - s) * (1 - d)
            }
        }
    }

    public struct Layer: Equatable, Sendable {
        public var name: String
        public var visible: Bool
        /// 0...1.
        public var opacity: Float
        public var blend: BlendMode
        /// One cel per frame: `width * height` values, 0 transparent, `n` palette entry `n - 1`.
        public var cels: [[UInt8]]

        public init(name: String, visible: Bool = true, opacity: Float = 1, blend: BlendMode = .normal, cels: [[UInt8]] = []) {
            self.name = name
            self.visible = visible
            self.opacity = opacity
            self.blend = blend
            self.cels = cels
        }
    }

    public var width: Int
    public var height: Int
    public var palette: [PixelColor]
    /// Bottom first.
    public var layers: [Layer]
    public var frames: [Frame]
    public var tags: [Tag]
    /// Where the sprite's position is within a frame: (0, 0) bottom-left, (0.5, 0) bottom middle.
    public var pivot: Vec2
    /// Pixels per world unit for sprites drawn from it.
    public var pixelsPerUnit: Float

    /// A blank sprite of one layer and one frame.
    public init(width: Int = 16, height: Int = 16, palette: [PixelColor] = PixelPalette.pico8.colors, frameCount: Int = 1,
                tags: [Tag] = [], pivot: Vec2 = Vec2(0.5, 0), pixelsPerUnit: Float = 16) {
        self.width = min(max(width, 1), Self.maxSize)
        self.height = min(max(height, 1), Self.maxSize)
        self.palette = palette
        self.frames = Array(repeating: Frame(), count: max(frameCount, 1))
        self.layers = []
        self.tags = tags
        self.pivot = pivot
        self.pixelsPerUnit = pixelsPerUnit
        layers = [Layer(name: "Layer 1")]
        normalize()
    }

    public var pixelCount: Int { width * height }

    /// Makes the data consistent: sizes clamped, at least one layer and frame, every layer
    /// with one full-size cel per frame (padded with transparent pixels or cut).
    public mutating func normalize() {
        width = min(max(width, 1), Self.maxSize)
        height = min(max(height, 1), Self.maxSize)
        if frames.isEmpty { frames = [Frame()] }
        if layers.isEmpty { layers = [Layer(name: "Layer 1")] }
        let n = pixelCount
        for l in layers.indices {
            if layers[l].cels.count > frames.count { layers[l].cels.removeLast(layers[l].cels.count - frames.count) }
            while layers[l].cels.count < frames.count { layers[l].cels.append([]) }
            for f in layers[l].cels.indices where layers[l].cels[f].count != n {
                var cel = layers[l].cels[f]
                if cel.count > n { cel.removeLast(cel.count - n) } else { cel += [UInt8](repeating: 0, count: n - cel.count) }
                layers[l].cels[f] = cel
            }
        }
    }

    // MARK: Coding

    private enum CodingKeys: String, CodingKey { case width, height, palette, layers, frames, tags, pivot, pixelsPerUnit }

    private struct LayerFile: Codable {
        var name: String?
        var visible: Bool?
        var opacity: Float?
        /// Omitted for `normal`.
        var blend: BlendMode?
        var cels: [[String]]?
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        width = min(max(try c.decodeIfPresent(Int.self, forKey: .width) ?? 16, 1), Self.maxSize)
        height = min(max(try c.decodeIfPresent(Int.self, forKey: .height) ?? 16, 1), Self.maxSize)
        palette = try c.decodeIfPresent([PixelColor].self, forKey: .palette) ?? PixelPalette.pico8.colors
        frames = try c.decodeIfPresent([Frame].self, forKey: .frames) ?? []
        tags = try c.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        pivot = try c.decodeIfPresent(Vec2.self, forKey: .pivot) ?? Vec2(0.5, 0)
        pixelsPerUnit = try c.decodeIfPresent(Float.self, forKey: .pixelsPerUnit) ?? 16
        let files = try c.decodeIfPresent([LayerFile].self, forKey: .layers) ?? []
        let (w, h) = (width, height)
        layers = files.enumerated().map { i, file in
            Layer(name: file.name ?? "Layer \(i + 1)", visible: file.visible ?? true, opacity: file.opacity ?? 1,
                  blend: file.blend ?? .normal, cels: (file.cels ?? []).map { Self.decodeRows($0, width: w, height: h) })
        }
        // A file with cels but no frame list gets a frame per cel.
        let celCount = layers.map(\.cels.count).max() ?? 0
        if frames.count < celCount && !c.contains(.frames) {
            frames = Array(repeating: Frame(), count: celCount)
        }
        normalize()
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encode(palette, forKey: .palette)
        try c.encode(frames, forKey: .frames)
        try c.encode(tags, forKey: .tags)
        try c.encode(pivot, forKey: .pivot)
        try c.encode(pixelsPerUnit, forKey: .pixelsPerUnit)
        try c.encode(layers.map { layer in
            LayerFile(name: layer.name, visible: layer.visible, opacity: layer.opacity,
                      blend: layer.blend == .normal ? nil : layer.blend, cels: layer.cels.map { rows(of: $0) })
        }, forKey: .layers)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// A cel's row strings; an empty cel is `[]`.
    public func rows(of cel: [UInt8]) -> [String] {
        guard cel.contains(where: { $0 != 0 }) else { return [] }
        return (0..<height).map { y in
            String((0..<width).map { x in Self.character(for: cel[y * width + x]) })
        }
    }

    /// The character for a pixel value (0 transparent, `n` palette entry `n - 1`); "?" past the alphabet.
    public static func character(for value: UInt8) -> Character {
        if value == 0 { return transparentCharacter }
        let i = Int(value) - 1
        return i < alphabet.count ? alphabet[i] : "?"
    }

    private static let valueByCharacter: [Character: UInt8] = {
        var map: [Character: UInt8] = [transparentCharacter: 0]
        for (i, ch) in alphabet.enumerated() { map[ch] = UInt8(i + 1) }
        return map
    }()

    /// The pixel value for a row character (nil for characters outside the alphabet and ".").
    public static func value(for character: Character) -> UInt8? { valueByCharacter[character] }

    static func decodeRows(_ rows: [String], width: Int, height: Int) -> [UInt8] {
        var cel = [UInt8](repeating: 0, count: width * height)
        for (y, row) in rows.prefix(height).enumerated() {
            for (x, ch) in row.prefix(width).enumerated() { cel[y * width + x] = value(for: ch) ?? 0 }
        }
        return cel
    }

    // MARK: Reading

    public func layerIndex(named name: String) -> Int? { layers.firstIndex { $0.name == name } }

    /// The palette color of a pixel value (nil for transparent or an entry the palette doesn't have).
    public func color(of value: UInt8) -> PixelColor? {
        value == 0 || Int(value) > palette.count ? nil : palette[Int(value) - 1]
    }

    /// The value of the topmost visible, non-transparent pixel at (x, y) in `frame` (0 for none).
    public func pick(frame: Int, x: Int, y: Int) -> UInt8 {
        guard frames.indices.contains(frame), x >= 0, y >= 0, x < width, y < height else { return 0 }
        for layer in layers.reversed() where layer.visible && layer.opacity > 0 {
            let v = layer.cels[frame][y * width + x]
            if v != 0 { return v }
        }
        return 0
    }

    /// `frame` as row strings of the topmost visible pixels (opacity and blend modes ignored).
    public func compositeRows(frame: Int) -> [String] {
        (0..<height).map { y in String((0..<width).map { x in Self.character(for: pick(frame: frame, x: x, y: y)) }) }
    }

    /// `frame` composited: visible layers bottom to top, each with its opacity and blend mode
    /// (straight alpha; a blend mode mixes with what is below in proportion to its coverage).
    /// `onlyLayer` draws that layer alone (ignoring its visibility).
    public func image(frame: Int, onlyLayer: Int? = nil) -> Image {
        var pixels = [Float](repeating: 0, count: pixelCount * 4)
        if frames.indices.contains(frame) {
            for (l, layer) in layers.enumerated() {
                if let onlyLayer { guard l == onlyLayer else { continue } } else { guard layer.visible else { continue } }
                let opacity = min(max(layer.opacity, 0), 1)
                guard opacity > 0 else { continue }
                let cel = layer.cels[frame]
                for i in 0..<pixelCount {
                    guard let c = color(of: cel[i]) else { continue }
                    let sa = Float(c.a) / 255 * opacity
                    guard sa > 0 else { continue }
                    let o = i * 4
                    let da = pixels[o + 3]
                    let outA = sa + da * (1 - sa)
                    for (k, s) in [c.r, c.g, c.b].enumerated() {
                        let dc = pixels[o + k]
                        // W3C compositing: where there is something below, the source color is
                        // the blend of the two.
                        let sc = (1 - da) * (Float(s) / 255) + da * layer.blend.blend(Float(s) / 255, over: dc)
                        pixels[o + k] = (sc * sa + dc * da * (1 - sa)) / outA
                    }
                    pixels[o + 3] = outA
                }
            }
        }
        return Image(width: width, height: height, pixels: pixels.map { UInt8((min(max($0, 0), 1) * 255).rounded()) })
    }

    // MARK: Checking

    /// Problems worth reporting: out-of-range values, pixels naming missing palette entries, bad tags.
    public func problems() -> [String] {
        var out: [String] = []
        if palette.isEmpty { out.append("the palette is empty: nothing can be drawn") }
        if palette.count > Self.maxColors { out.append("the palette has \(palette.count) colors; only the first \(Self.maxColors) can be used in cel rows") }
        var names = Set<String>()
        for layer in layers {
            if !names.insert(layer.name).inserted { out.append("two layers are named '\(layer.name)'") }
            if layer.opacity < 0 || layer.opacity > 1 { out.append("layer '\(layer.name)' opacity \(layer.opacity) is outside 0...1") }
            let highest = layer.cels.lazy.compactMap { $0.max() }.max() ?? 0
            if Int(highest) > palette.count {
                out.append("layer '\(layer.name)' uses palette entry \(highest - 1) but the palette has \(palette.count) colors (drawn transparent)")
            }
        }
        for (i, frame) in frames.enumerated() where frame.duration <= 0 {
            out.append("frame \(i) has duration \(frame.duration) ms; it needs to be positive")
        }
        var tagNames = Set<String>()
        for tag in tags {
            if tag.name.isEmpty { out.append("a tag has no name") }
            if !tagNames.insert(tag.name).inserted { out.append("two tags are named '\(tag.name)'") }
            if tag.from < 0 || tag.to >= frames.count || tag.from > tag.to {
                out.append("tag '\(tag.name)' covers frames \(tag.from)...\(tag.to) but the sprite has frames 0...\(frames.count - 1)")
            }
            for event in tag.events {
                if event.name.isEmpty { out.append("tag '\(tag.name)' has an event without a name") }
                if event.frame < tag.from || event.frame > tag.to {
                    out.append("tag '\(tag.name)' event '\(event.name)' is on frame \(event.frame), outside the tag's frames \(tag.from)...\(tag.to) (it never fires)")
                }
            }
        }
        return out
    }
}

/// Ready-made palettes.
public enum PixelPalette: String, Codable, CaseIterable, Sendable {
    /// The PICO-8 fantasy console's 16 colors.
    case pico8
    /// DawnBringer's 16-color palette.
    case db16
    /// DawnBringer's 32-color palette.
    case db32
    /// Four greens of the original Game Boy.
    case gameboy
    /// Black, white and grays (8).
    case grayscale

    public var colors: [PixelColor] {
        let hex: [UInt32]
        switch self {
        case .pico8:
            hex = [0x000000, 0x1D2B53, 0x7E2553, 0x008751, 0xAB5236, 0x5F574F, 0xC2C3C7, 0xFFF1E8,
                   0xFF004D, 0xFFA300, 0xFFEC27, 0x00E436, 0x29ADFF, 0x83769C, 0xFF77A8, 0xFFCCAA]
        case .db16:
            hex = [0x140C1C, 0x442434, 0x30346D, 0x4E4A4E, 0x854C30, 0x346524, 0xD04648, 0x757161,
                   0x597DCE, 0xD27D2C, 0x8595A1, 0x6DAA2C, 0xD2AA99, 0x6DC2CA, 0xDAD45E, 0xDEEED6]
        case .db32:
            hex = [0x000000, 0x222034, 0x45283C, 0x663931, 0x8F563B, 0xDF7126, 0xD9A066, 0xEEC39A,
                   0xFBF236, 0x99E550, 0x6ABE30, 0x37946E, 0x4B692F, 0x524B24, 0x323C39, 0x3F3F74,
                   0x306082, 0x5B6EE1, 0x639BFF, 0x5FCDE4, 0xCBDBFC, 0xFFFFFF, 0x9BADB7, 0x847E87,
                   0x696A6A, 0x595652, 0x76428A, 0xAC3232, 0xD95763, 0xD77BBA, 0x8F974A, 0x8A6F30]
        case .gameboy:
            hex = [0x0F380F, 0x306230, 0x8BAC0F, 0x9BBC0F]
        case .grayscale:
            hex = [0x000000, 0x242424, 0x494949, 0x6D6D6D, 0x929292, 0xB6B6B6, 0xDBDBDB, 0xFFFFFF]
        }
        return hex.map { PixelColor(hex: $0) }
    }
}
