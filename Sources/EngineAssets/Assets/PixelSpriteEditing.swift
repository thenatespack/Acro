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
    /// A rectangle selection to move, copy or paste (the editor's; no edit here).
    case select
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
        case .picker, .select:
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
            for e in tags[t].events.indices where tags[t].events[e].frame >= at { tags[t].events[e].frame += count }
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
        // A tag keeps the frames it still covers, and the events on them.
        let newIndex = Dictionary(uniqueKeysWithValues: keep.enumerated().map { ($0.element, $0.offset) })
        tags = tags.compactMap { tag in
            let kept = keep.enumerated().filter { $0.element >= tag.from && $0.element <= tag.to }.map(\.offset)
            guard let first = kept.first, let last = kept.last else { return nil }
            let events = tag.events.compactMap { e in newIndex[e.frame].map { FrameEvent(frame: $0, name: e.name) } }
            return Tag(tag.name, from: first, to: last, mode: tag.mode, events: events)
        }
    }

    /// Moves frame `from` to position `to` (tags and their events keep their frame numbers).
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

// MARK: - Selections and copy / paste

/// A rectangle of pixels (top-left origin). Encodes as `[x, y, width, height]`.
public struct PixelRect: Hashable, Sendable, Codable {
    public var x: Int, y: Int, width: Int, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        (self.x, self.y, self.width, self.height) = (x, y, width, height)
    }

    /// The rectangle with corners `a` and `b` (both included).
    public init(corners a: PixelPoint, _ b: PixelPoint) {
        self.init(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x) + 1, height: abs(b.y - a.y) + 1)
    }

    public var isEmpty: Bool { width <= 0 || height <= 0 }
    public var maxX: Int { x + width }
    public var maxY: Int { y + height }

    public func contains(_ p: PixelPoint) -> Bool { p.x >= x && p.y >= y && p.x < maxX && p.y < maxY }

    /// The part of the rectangle inside a `width` x `height` canvas (empty when none is).
    public func clamped(width w: Int, height h: Int) -> PixelRect {
        let x0 = max(x, 0), y0 = max(y, 0), x1 = min(maxX, w), y1 = min(maxY, h)
        return PixelRect(x: x0, y: y0, width: max(x1 - x0, 0), height: max(y1 - y0, 0))
    }

    public func offsetBy(_ dx: Int, _ dy: Int) -> PixelRect { PixelRect(x: x + dx, y: y + dy, width: width, height: height) }

    public init(from decoder: any Decoder) throws {
        var c = try decoder.unkeyedContainer()
        x = try c.decode(Int.self)
        y = try c.decode(Int.self)
        width = try c.decode(Int.self)
        height = try c.decode(Int.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(x)
        try c.encode(y)
        try c.encode(width)
        try c.encode(height)
    }
}

/// Pixels copied out of a cel: palette values (0 transparent), `width * height`, row by row.
/// Pasting leaves the cel's pixels under transparent ones as they are.
public struct PixelClip: Equatable, Sendable {
    public var width: Int
    public var height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.pixels = pixels.count == self.width * self.height ? pixels : [UInt8](repeating: 0, count: self.width * self.height)
    }

    public var isEmpty: Bool { width == 0 || height == 0 }

    /// The clip as row strings (`.` transparent).
    public var rows: [String] {
        (0..<height).map { y in String((0..<width).map { x in PixelSprite.character(for: pixels[y * width + x]) }) }
    }
}

extension PixelSprite {
    /// The pixels of one cel inside `rect` (cut to the canvas; nil for a missing frame or layer
    /// or a rectangle outside the canvas).
    public func copy(_ rect: PixelRect, frame: Int, layer: Int) -> PixelClip? {
        guard layers.indices.contains(layer), frames.indices.contains(frame) else { return nil }
        let r = rect.clamped(width: width, height: height)
        guard !r.isEmpty else { return nil }
        let cel = layers[layer].cels[frame]
        var pixels: [UInt8] = []
        pixels.reserveCapacity(r.width * r.height)
        for y in r.y..<r.maxY { pixels += cel[(y * width + r.x)..<(y * width + r.maxX)] }
        return PixelClip(width: r.width, height: r.height, pixels: pixels)
    }

    /// The visible pixels of `frame` (all visible layers, topmost wins) inside `rect`.
    public func copyMerged(_ rect: PixelRect, frame: Int) -> PixelClip? {
        guard frames.indices.contains(frame) else { return nil }
        let r = rect.clamped(width: width, height: height)
        guard !r.isEmpty else { return nil }
        var pixels: [UInt8] = []
        for y in r.y..<r.maxY { for x in r.x..<r.maxX { pixels.append(pick(frame: frame, x: x, y: y)) } }
        return PixelClip(width: r.width, height: r.height, pixels: pixels)
    }

    /// Writes `clip` into a cel with its top-left at (`x`, `y`). Transparent clip pixels leave the
    /// cel as it is, unless `opaque` (then they erase). Pixels off the canvas are cut.
    public mutating func paste(_ clip: PixelClip, x: Int, y: Int, frame: Int, layer: Int, opaque: Bool = false) {
        guard layers.indices.contains(layer), frames.indices.contains(frame) else { return }
        for cy in 0..<clip.height {
            for cx in 0..<clip.width {
                let v = clip.pixels[cy * clip.width + cx]
                guard v != 0 || opaque else { continue }
                setPixel(frame: frame, layer: layer, x: x + cx, y: y + cy, value: v)
            }
        }
    }

    /// Makes the pixels of one cel inside `rect` transparent.
    public mutating func clear(_ rect: PixelRect, frame: Int, layer: Int) {
        guard layers.indices.contains(layer), frames.indices.contains(frame) else { return }
        let r = rect.clamped(width: width, height: height)
        guard !r.isEmpty else { return }
        for y in r.y..<r.maxY { for x in r.x..<r.maxX { layers[layer].cels[frame][y * width + x] = 0 } }
    }

    /// Moves the pixels of one cel inside `rect` by (`dx`, `dy`): they are cut and pasted over
    /// what is there (transparent ones don't cover). With `copy`, the originals stay.
    public mutating func move(_ rect: PixelRect, dx: Int, dy: Int, frame: Int, layer: Int, copy: Bool = false) {
        guard let clip = self.copy(rect, frame: frame, layer: layer) else { return }
        let r = rect.clamped(width: width, height: height)
        if !copy { clear(r, frame: frame, layer: layer) }
        paste(clip, x: r.x + dx, y: r.y + dy, frame: frame, layer: layer)
    }
}
