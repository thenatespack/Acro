import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// Drawing and structure edits on a `PixelSprite`, shared by the Pixel Sprite Builder tab and the
// sprite.* tools. All of them are pure value edits; the editor writes the result as one undo step.

/// A pixel position.
public struct PixelPoint: Hashable, Sendable, Codable {
    public var x: Int, y: Int
    public init(_ x: Int, _ y: Int) { (self.x, self.y) = (x, y) }

    /// Encodes as `[x, y]`.
    public init(from decoder: any Decoder) throws {
        var c = try decoder.unkeyedContainer()
        x = try c.decode(Int.self)
        y = try c.decode(Int.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(x)
        try c.encode(y)
    }
}

/// Which axes drawing is mirrored across (the canvas center).
public struct PixelMirror: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let horizontal = PixelMirror(rawValue: 1)
    public static let vertical = PixelMirror(rawValue: 2)
}

/// The drawing tools.
public enum PixelTool: String, Codable, CaseIterable, Sendable {
    /// Sets each point (a freehand stroke joins consecutive points with lines).
    case pencil
    /// A line through consecutive points.
    case line
    /// A rectangle between the first and last point (outline, or filled with `filled`).
    case rect
    /// Flood-fills the area of one color around each point (4-connected, this layer only).
    case fill
    /// The pencil with transparent.
    case eraser
    /// Picks the color under the point (no edit).
    case picker
}

extension PixelSprite {
    // MARK: Pixels

    /// Sets one pixel of a cel (ignored outside the canvas or for a missing frame / layer).
    public mutating func setPixel(frame: Int, layer: Int, x: Int, y: Int, value: UInt8) {
        guard layers.indices.contains(layer), frames.indices.contains(frame), x >= 0, y >= 0, x < width, y < height else { return }
        layers[layer].cels[frame][y * width + x] = value
    }

    public func pixel(frame: Int, layer: Int, x: Int, y: Int) -> UInt8 {
        guard layers.indices.contains(layer), frames.indices.contains(frame), x >= 0, y >= 0, x < width, y < height else { return 0 }
        return layers[layer].cels[frame][y * width + x]
    }

    /// `point` and its mirror images.
    public func mirrored(_ point: PixelPoint, _ mirror: PixelMirror) -> [PixelPoint] {
        var out = [point]
        if mirror.contains(.horizontal) { out.append(PixelPoint(width - 1 - point.x, point.y)) }
        if mirror.contains(.vertical) { out += out.map { PixelPoint($0.x, height - 1 - $0.y) } }
        return out
    }

    /// Sets every point (and its mirror images) to `value`.
    public mutating func plot(_ points: [PixelPoint], value: UInt8, frame: Int, layer: Int, mirror: PixelMirror = []) {
        for p in points { for m in mirrored(p, mirror) { setPixel(frame: frame, layer: layer, x: m.x, y: m.y, value: value) } }
    }

    /// The pixels of a line from `a` to `b` (Bresenham), both ends included.
    public static func linePoints(_ a: PixelPoint, _ b: PixelPoint) -> [PixelPoint] {
        var points: [PixelPoint] = []
        var x = a.x, y = a.y
        let dx = abs(b.x - a.x), dy = -abs(b.y - a.y)
        let sx = a.x < b.x ? 1 : -1, sy = a.y < b.y ? 1 : -1
        var err = dx + dy
        while true {
            points.append(PixelPoint(x, y))
            if x == b.x && y == b.y { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
        return points
    }

    /// The pixels of the rectangle with corners `a` and `b`: its outline, or all of it when `filled`.
    public static func rectPoints(_ a: PixelPoint, _ b: PixelPoint, filled: Bool) -> [PixelPoint] {
        let x0 = min(a.x, b.x), x1 = max(a.x, b.x), y0 = min(a.y, b.y), y1 = max(a.y, b.y)
        var points: [PixelPoint] = []
        for y in y0...y1 {
            for x in x0...x1 where filled || x == x0 || x == x1 || y == y0 || y == y1 { points.append(PixelPoint(x, y)) }
        }
        return points
    }

    /// Flood-fills the 4-connected area of the color at `start` in one cel with `value` (and the
    /// areas at its mirror images).
    public mutating func fill(at start: PixelPoint, value: UInt8, frame: Int, layer: Int, mirror: PixelMirror = []) {
        guard layers.indices.contains(layer), frames.indices.contains(frame) else { return }
        for seed in mirrored(start, mirror) {
            guard seed.x >= 0, seed.y >= 0, seed.x < width, seed.y < height else { continue }
            var cel = layers[layer].cels[frame]
            let target = cel[seed.y * width + seed.x]
            guard target != value else { continue }
            var stack = [seed.y * width + seed.x]
            while let i = stack.popLast() {
                guard cel[i] == target else { continue }
                cel[i] = value
                let x = i % width, y = i / width
                if x > 0 { stack.append(i - 1) }
                if x < width - 1 { stack.append(i + 1) }
                if y > 0 { stack.append(i - width) }
                if y < height - 1 { stack.append(i + width) }
            }
            layers[layer].cels[frame] = cel
        }
    }

    /// Applies a drawing tool through `points` with `value` (the eraser always draws transparent;
    /// the picker changes nothing).
    public mutating func draw(_ tool: PixelTool, points: [PixelPoint], value: UInt8, frame: Int, layer: Int,
                              filled: Bool = false, mirror: PixelMirror = []) {
        guard let first = points.first else { return }
        switch tool {
        case .pencil, .eraser:
            let v: UInt8 = tool == .eraser ? 0 : value
            var stroke = [first]
            for (a, b) in zip(points, points.dropFirst()) { stroke += Self.linePoints(a, b).dropFirst() }
            plot(stroke, value: v, frame: frame, layer: layer, mirror: mirror)
        case .line:
            var stroke = [first]
            for (a, b) in zip(points, points.dropFirst()) { stroke += Self.linePoints(a, b).dropFirst() }
            plot(stroke, value: value, frame: frame, layer: layer, mirror: mirror)
        case .rect:
            plot(Self.rectPoints(first, points.last!, filled: filled), value: value, frame: frame, layer: layer, mirror: mirror)
        case .fill:
            for p in points { fill(at: p, value: value, frame: frame, layer: layer, mirror: mirror) }
        case .picker:
            break
        }
    }

    /// Writes row strings into a cel with their top-left at (`x`, `y`). `.` leaves the pixel as it
    /// is, unless `clear` (then it erases). Returns the characters that aren't palette characters.
    @discardableResult
    public mutating func stamp(rows: [String], x: Int = 0, y: Int = 0, frame: Int, layer: Int, clear: Bool = false) -> Set<Character> {
        var unknown = Set<Character>()
        for (dy, row) in rows.enumerated() {
            for (dx, ch) in row.enumerated() {
                if ch == Self.transparentCharacter || ch == " " {
                    if clear { setPixel(frame: frame, layer: layer, x: x + dx, y: y + dy, value: 0) }
                    continue
                }
                guard let v = Self.value(for: ch) else { unknown.insert(ch); continue }
                setPixel(frame: frame, layer: layer, x: x + dx, y: y + dy, value: v)
            }
        }
        return unknown
    }

    /// Makes one cel transparent.
    public mutating func clearCel(frame: Int, layer: Int) {
        guard layers.indices.contains(layer), frames.indices.contains(frame) else { return }
        layers[layer].cels[frame] = [UInt8](repeating: 0, count: pixelCount)
    }

    // MARK: Frames

    /// Inserts `count` frames at `index` (default: the end), blank or copies of frame `copyOf`.
    /// Tags after the insertion point move along.
    public mutating func insertFrames(_ count: Int, at index: Int? = nil, copyOf: Int? = nil, duration: Int? = nil) {
        guard count > 0 else { return }
        let at = min(max(index ?? frames.count, 0), frames.count)
        let source = copyOf.flatMap { frames.indices.contains($0) ? $0 : nil }
        let frame = Frame(duration: duration ?? source.map { frames[$0].duration } ?? frames.last?.duration ?? 100)
        frames.insert(contentsOf: Array(repeating: frame, count: count), at: at)
        for l in layers.indices {
            let cel = source.map { layers[l].cels[$0] } ?? [UInt8](repeating: 0, count: pixelCount)
            layers[l].cels.insert(contentsOf: Array(repeating: cel, count: count), at: at)
        }
        // Frames inserted inside a tag join it; tags after the insertion point move along.
        for t in tags.indices {
            if tags[t].from >= at { tags[t].from += count }
            if tags[t].to >= at { tags[t].to += count }
        }
    }

    /// Removes the frames at `indices` (one frame always stays). Tags shrink or go away.
    public mutating func removeFrames(_ indices: [Int]) {
        let doomed = Set(indices.filter { frames.indices.contains($0) })
        guard !doomed.isEmpty else { return }
        let keep = frames.indices.filter { !doomed.contains($0) }
        guard !keep.isEmpty else {
            frames = [frames[0]]
            for l in layers.indices { layers[l].cels = [[UInt8](repeating: 0, count: pixelCount)] }
            tags = tags.map { Tag($0.name, from: 0, to: 0, mode: $0.mode) }
            return
        }
        frames = keep.map { frames[$0] }
        for l in layers.indices { layers[l].cels = keep.map { layers[l].cels[$0] } }
        // A tag keeps the frames it still covers.
        tags = tags.compactMap { tag in
            let kept = keep.enumerated().filter { $0.element >= tag.from && $0.element <= tag.to }.map(\.offset)
            guard let first = kept.first, let last = kept.last else { return nil }
            return Tag(tag.name, from: first, to: last, mode: tag.mode)
        }
    }

    /// Moves frame `from` to position `to` (tags keep their frame numbers).
    public mutating func moveFrame(_ from: Int, to: Int) {
        guard frames.indices.contains(from), frames.indices.contains(to), from != to else { return }
        frames.insert(frames.remove(at: from), at: to)
        for l in layers.indices { layers[l].cels.insert(layers[l].cels.remove(at: from), at: to) }
    }

    // MARK: Layers

    /// A layer name not used yet ("Layer 2", …).
    public func unusedLayerName(_ base: String = "Layer") -> String {
        var n = layers.count + 1
        while layerIndex(named: "\(base) \(n)") != nil { n += 1 }
        return "\(base) \(n)"
    }

    /// Adds an empty layer at `index` (default: on top). Returns its index.
    @discardableResult
    public mutating func insertLayer(name: String? = nil, at index: Int? = nil, opacity: Float = 1) -> Int {
        let at = min(max(index ?? layers.count, 0), layers.count)
        let layer = Layer(name: name ?? unusedLayerName(), opacity: opacity,
                          cels: Array(repeating: [UInt8](repeating: 0, count: pixelCount), count: frames.count))
        layers.insert(layer, at: at)
        return at
    }

    /// Removes a layer (one always stays).
    public mutating func removeLayer(_ index: Int) {
        guard layers.indices.contains(index) else { return }
        layers.remove(at: index)
        if layers.isEmpty { normalize() }
    }

    public mutating func moveLayer(_ from: Int, to: Int) {
        guard layers.indices.contains(from), layers.indices.contains(to), from != to else { return }
        layers.insert(layers.remove(at: from), at: to)
    }

    // MARK: Palette

    /// The pixel value of `color` (palette index + 1), adding it to the palette if missing.
    /// nil when the palette is full.
    public mutating func value(for color: PixelColor) -> UInt8? {
        if let i = palette.firstIndex(of: color) { return i < Self.maxColors ? UInt8(i + 1) : nil }
        guard palette.count < Self.maxColors else { return nil }
        palette.append(color)
        return UInt8(palette.count)
    }

    /// Removes palette entry `index`: its pixels become transparent, later entries move down one.
    public mutating func removeColor(_ index: Int) {
        guard palette.indices.contains(index) else { return }
        palette.remove(at: index)
        let removed = UInt8(index + 1)
        for l in layers.indices {
            for f in layers[l].cels.indices {
                layers[l].cels[f] = layers[l].cels[f].map { v in v == removed ? 0 : (v > removed ? v - 1 : v) }
            }
        }
    }

    // MARK: Canvas

    /// The sprite with a canvas of `newWidth` x `newHeight`, pixels kept at their place from the
    /// top-left (cut or padded with transparent).
    public func resized(width newWidth: Int, height newHeight: Int) -> PixelSprite {
        var out = self
        out.width = min(max(newWidth, 1), Self.maxSize)
        out.height = min(max(newHeight, 1), Self.maxSize)
        for l in layers.indices {
            out.layers[l].cels = layers[l].cels.map { cel in
                var new = [UInt8](repeating: 0, count: out.width * out.height)
                for y in 0..<min(height, out.height) {
                    for x in 0..<min(width, out.width) { new[y * out.width + x] = cel[y * width + x] }
                }
                return new
            }
        }
        return out
    }

    /// Frame `frame` flipped across one axis (every layer).
    public mutating func flip(frame: Int, horizontal: Bool) {
        guard frames.indices.contains(frame) else { return }
        for l in layers.indices {
            let cel = layers[l].cels[frame]
            var out = cel
            for y in 0..<height {
                for x in 0..<width {
                    let (sx, sy) = horizontal ? (width - 1 - x, y) : (x, height - 1 - y)
                    out[y * width + x] = cel[sy * width + sx]
                }
            }
            layers[l].cels[frame] = out
        }
    }
}
