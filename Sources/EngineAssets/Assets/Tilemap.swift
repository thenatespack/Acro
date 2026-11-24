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

// A 2D tile map: the contents of a `.tilemap` file (JSON, every key optional). `TilemapImporter`
// turns it into the tile set texture, one mesh per layer chunk, a `Collider2D` per merged
// collision shape and a node per object point, all in a prefab; sprite games draw it through a
// `SpriteBatch` with `TilemapSpriteDrawer` (EngineRendering) and read it with `assets.tilemap(path:)`.
//
// Cells are addressed (x, y) with x to the right and y down from the top-left cell, like the
// image a map is painted as. In the world the map lies in the XY plane with its bottom-left
// corner at the origin and y up: a tile is `tileSize / pixelsPerUnit` units big.
//
// ```json
// {
//   "tileSize": [16, 16], "size": [40, 22], "pixelsPerUnit": 16,
//   "tileset": {"source": {"kind": "image", "image": "Tiles/tiles.png"},
//               "tiles": [{"index": 16, "collision": "full"},
//                         {"index": 18, "collision": "top", "oneWay": true},
//                         {"index": 22, "animation": {"frames": [22, 23, 24, 25], "fps": 6}}]},
//   "layers": [{"name": "Ground", "cells": [[-1, 16, 16], [16, 65552, -1]]}],
//   "terrains": [{"name": "Dirt", "mode": "edges", "first": 0}],
//   "objects": [{"name": "Player", "type": "spawn", "position": [2, 3]}]
// }
// ```
//
// A cell value is -1 (empty) or a tile index (0 is the tile set's first tile) plus transform
// bits: +65536 flips it horizontally, +131072 vertically, and +262144 × n turns it n quarter
// turns clockwise (the flips apply first). See `TileCell`.

// MARK: - Cells

/// One placed tile: a tile set index (or empty) and how it is mirrored and turned.
public struct TileCell: Equatable, Hashable, Sendable {
    /// Tile set index, -1 for an empty cell.
    public var tile: Int
    public var flipX: Bool
    public var flipY: Bool
    /// Quarter turns clockwise (0...3), applied after the flips.
    public var rotation: Int

    public static let empty = TileCell(tile: -1)
    static let flipXBit = 1 << 16, flipYBit = 1 << 17, rotationShift = 18

    public init(tile: Int, flipX: Bool = false, flipY: Bool = false, rotation: Int = 0) {
        self.tile = tile
        self.flipX = flipX
        self.flipY = flipY
        self.rotation = ((rotation % 4) + 4) % 4
    }

    /// Decodes a cell value of the file (see the notes at the top of this file).
    public init(encoded value: Int) {
        guard value >= 0 else { self = .empty; return }
        self.init(tile: value & 0xFFFF, flipX: value & Self.flipXBit != 0, flipY: value & Self.flipYBit != 0,
                  rotation: (value >> Self.rotationShift) & 3)
    }

    public var isEmpty: Bool { tile < 0 }

    /// The value written to the file.
    public var encoded: Int {
        guard tile >= 0 else { return -1 }
        return (tile & 0xFFFF) | (flipX ? Self.flipXBit : 0) | (flipY ? Self.flipYBit : 0) | ((rotation & 3) << Self.rotationShift)
    }

    /// Where the point `p` of the tile's own image (0...1, y up) ends up in the cell.
    public func place(_ p: Vec2) -> Vec2 {
        var q = Vec2(flipX ? 1 - p.x : p.x, flipY ? 1 - p.y : p.y)
        for _ in 0..<rotation { q = Vec2(q.y, 1 - q.x) }
        return q
    }

    /// Whether the transform turns the tile on its side (width and height swap).
    public var isSideways: Bool { rotation % 2 == 1 }
}

// MARK: - Tile set

/// What a tile collides as. Shapes are in the tile's own space (0...1, y up) and follow the
/// cell's flips and turns.
public enum TileCollision: String, Codable, CaseIterable, Sendable {
    case none
    /// The whole cell.
    case full
    /// The top quarter (a thin platform; usually with `oneWay`).
    case top
    /// The bottom half.
    case bottom
    /// A ramp rising to the right.
    case slopeUp
    /// A ramp falling to the right.
    case slopeDown
    /// The convex hull of the tile's `points`.
    case polygon

    /// The shape's outline (counter-clockwise) for the non-rectangular kinds, the rectangle for the others.
    public func outline(points: [Vec2]) -> [Vec2] {
        switch self {
        case .none: []
        case .full: [Vec2(0, 0), Vec2(1, 0), Vec2(1, 1), Vec2(0, 1)]
        case .top: [Vec2(0, 0.75), Vec2(1, 0.75), Vec2(1, 1), Vec2(0, 1)]
        case .bottom: [Vec2(0, 0), Vec2(1, 0), Vec2(1, 0.5), Vec2(0, 0.5)]
        case .slopeUp: [Vec2(0, 0), Vec2(1, 0), Vec2(1, 1)]
        case .slopeDown: [Vec2(0, 0), Vec2(1, 0), Vec2(0, 1)]
        case .polygon: points
        }
    }

    /// Whether the shape is an axis-aligned rectangle (merged with its neighbors).
    public var isRectangle: Bool { self == .full || self == .top || self == .bottom }
}

/// A flipbook tile (water, torches): tile set indices played at `fps`, like a `SpriteClip`.
public struct TilemapAnimation: Codable, Equatable, Sendable {
    public var frames: [Int]
    public var fps: Float
    /// "loop", "pingPong" or "once" (holds the last frame), as `SpriteLoopMode`.
    public var mode: String

    public init(frames: [Int] = [], fps: Float = 8, mode: String = "loop") {
        self.frames = frames
        self.fps = fps
        self.mode = mode
    }

    private enum CodingKeys: String, CodingKey { case frames, fps, mode }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(frames: try c.decodeIfPresent([Int].self, forKey: .frames) ?? [],
                  fps: try c.decodeIfPresent(Float.self, forKey: .fps) ?? 8,
                  mode: try c.decodeIfPresent(String.self, forKey: .mode) ?? "loop")
    }

    /// The frame shown at `time` seconds (the same stepping as `SpriteClip`).
    public func frame(at time: Float) -> Int? {
        step(at: time).map { frames[$0] }
    }

    /// The index into `frames` shown at `time` seconds (nil without frames).
    public func step(at time: Float) -> Int? {
        guard !frames.isEmpty else { return nil }
        let n = frames.count
        guard n > 1, fps > 0 else { return 0 }
        let tick = Int((max(time, 0) * fps).rounded(.down))
        if mode == "once" { return min(tick, n - 1) }
        if mode == "pingPong" {
            let cycle = 2 * n - 2
            let p = tick % cycle
            return p < n ? p : cycle - p
        }
        return tick % n
    }
}

/// What one tile of the tile set means: its collision, tags, custom properties and animation.
/// Tiles without an entry are plain, non-colliding pictures.
public struct TilemapTile: Codable, Equatable, Sendable {
    /// Tile set index.
    public var index: Int
    public var name: String
    public var collision: TileCollision
    /// The `polygon` collision's points (0...1, y up; at most 8 hull points).
    public var points: [Vec2]
    /// Bodies pass through from below and land on top.
    public var oneWay: Bool
    public var tags: [String]
    public var properties: [String: JSONValue]
    public var animation: TilemapAnimation?

    public init(index: Int, name: String = "", collision: TileCollision = .none, points: [Vec2] = [], oneWay: Bool = false,
                tags: [String] = [], properties: [String: JSONValue] = [:], animation: TilemapAnimation? = nil) {
        self.index = index
        self.name = name
        self.collision = collision
        self.points = points
        self.oneWay = oneWay
        self.tags = tags
        self.properties = properties
        self.animation = animation
    }

    private enum CodingKeys: String, CodingKey { case index, name, collision, points, oneWay, tags, properties, animation }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(index: try c.decodeIfPresent(Int.self, forKey: .index) ?? 0,
                  name: try c.decodeIfPresent(String.self, forKey: .name) ?? "",
                  collision: try c.decodeIfPresent(TileCollision.self, forKey: .collision) ?? .none,
                  points: try c.decodeIfPresent([Vec2].self, forKey: .points) ?? [],
                  oneWay: try c.decodeIfPresent(Bool.self, forKey: .oneWay) ?? false,
                  tags: try c.decodeIfPresent([String].self, forKey: .tags) ?? [],
                  properties: try c.decodeIfPresent([String: JSONValue].self, forKey: .properties) ?? [:],
                  animation: try c.decodeIfPresent(TilemapAnimation.self, forKey: .animation))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(index, forKey: .index)
        if !name.isEmpty { try c.encode(name, forKey: .name) }
        if collision != .none { try c.encode(collision, forKey: .collision) }
        if !points.isEmpty { try c.encode(points, forKey: .points) }
        if oneWay { try c.encode(oneWay, forKey: .oneWay) }
        if !tags.isEmpty { try c.encode(tags, forKey: .tags) }
        if !properties.isEmpty { try c.encode(properties, forKey: .properties) }
        try c.encodeIfPresent(animation, forKey: .animation)
    }

    /// Whether the entry says nothing beyond its index (and can be dropped).
    public var isPlain: Bool { self == TilemapTile(index: index) }
}

/// Where a tile set's pictures come from. Encoded as an object with a `kind`:
/// `{"kind": "image", "image": "Tiles/tiles.png", "margin": 0, "spacing": 0}` slices one image
/// (a sprite sheet) into `tileSize` cells in reading order; `{"kind": "images", "images": [...]}`
/// packs separate images (one tile each, in order) into an atlas; `{"kind": "sprite", "sprite":
/// "Tiles/tiles.sprite"}` uses a Pixel Sprite's frames (tile i is frame i) and plays its tags as
/// tile animations (`Tilemap.spriteTagAnimations(_:)`). A plain string is an image path, or a
/// sprite when it ends in `.sprite`.
///
/// A kind this build doesn't know is kept as `unsupported` and imports with a warning.
public enum TilesetSource: Equatable, Sendable, Codable {
    case image(path: String, margin: Int = 0, spacing: Int = 0)
    case images([String])
    /// A Pixel Sprite Builder `.sprite`: frame i is tile i.
    case sprite(path: String)
    case unsupported(kind: String, value: JSONValue)

    private enum CodingKeys: String, CodingKey { case kind, image, margin, spacing, images, sprite }

    /// The source for one asset path: a `.sprite` file, else an image sliced into tiles.
    public init(path: String) {
        self = path.lowercased().hasSuffix(".sprite") ? .sprite(path: path) : .image(path: path)
    }

    public init(from decoder: any Decoder) throws {
        if let path = try? decoder.singleValueContainer().decode(String.self) {
            self = TilesetSource(path: path)
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decodeIfPresent(String.self, forKey: .kind)
            ?? (c.contains(.images) ? "images" : c.contains(.sprite) ? "sprite" : "image")
        switch kind {
        case "sprite":
            self = .sprite(path: try c.decodeIfPresent(String.self, forKey: .sprite) ?? "")
        case "image":
            self = .image(path: try c.decodeIfPresent(String.self, forKey: .image) ?? "",
                          margin: max(try c.decodeIfPresent(Int.self, forKey: .margin) ?? 0, 0),
                          spacing: max(try c.decodeIfPresent(Int.self, forKey: .spacing) ?? 0, 0))
        case "images":
            self = .images(try c.decodeIfPresent([String].self, forKey: .images) ?? [])
        default:
            self = .unsupported(kind: kind, value: try JSONValue(from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .image(let path, let margin, let spacing):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode("image", forKey: .kind)
            try c.encode(path, forKey: .image)
            if margin != 0 { try c.encode(margin, forKey: .margin) }
            if spacing != 0 { try c.encode(spacing, forKey: .spacing) }
        case .images(let paths):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode("images", forKey: .kind)
            try c.encode(paths, forKey: .images)
        case .sprite(let path):
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode("sprite", forKey: .kind)
            try c.encode(path, forKey: .sprite)
        case .unsupported(_, let value):
            try value.encode(to: encoder)
        }
    }

    /// The `kind` name.
    public var kind: String {
        switch self {
        case .image: "image"
        case .images: "images"
        case .sprite: "sprite"
        case .unsupported(let kind, _): kind
        }
    }

    /// The asset paths the source reads.
    public var paths: [String] {
        switch self {
        case .image(let path, _, _): path.isEmpty ? [] : [path]
        case .images(let paths): paths
        case .sprite(let path): path.isEmpty ? [] : [path]
        case .unsupported: []
        }
    }
}

/// The tiles a map is painted with: where the pictures come from and what each tile means.
public struct TilemapTileset: Codable, Equatable, Sendable {
    public var source: TilesetSource
    /// "nearest" (crisp pixel art, the default) or "linear".
    public var filter: String
    /// Per-tile data, by tile index (tiles without an entry are plain).
    public var tiles: [TilemapTile]

    public init(source: TilesetSource = .image(path: ""), filter: String = "nearest", tiles: [TilemapTile] = []) {
        self.source = source
        self.filter = filter
        self.tiles = tiles
    }

    private enum CodingKeys: String, CodingKey { case source, filter, tiles }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(source: try c.decodeIfPresent(TilesetSource.self, forKey: .source) ?? .image(path: ""),
                  filter: try c.decodeIfPresent(String.self, forKey: .filter) ?? "nearest",
                  tiles: try c.decodeIfPresent([TilemapTile].self, forKey: .tiles) ?? [])
    }

    /// The entry for tile `index` (nil for a plain tile).
    public func tile(_ index: Int) -> TilemapTile? { tiles.first { $0.index == index } }

    /// Replaces (or adds) the entry for `tile.index`; a plain entry is removed. Keeps the list sorted by index.
    public mutating func setTile(_ tile: TilemapTile) {
        tiles.removeAll { $0.index == tile.index }
        if !tile.isPlain { tiles.append(tile) }
        tiles.sort { $0.index < $1.index }
    }
}

// MARK: - Layers, terrains, objects

/// One layer of cells. Layers draw in list order (the first is at the back) unless `order` says otherwise.
public struct TilemapLayer: Codable, Equatable, Sendable {
    public var name: String
    /// Encoded cells (see `TileCell`), row by row from the top: `columns * rows` values.
    public var data: [Int]
    /// Draw order (larger is in front); nil: the layer's position in the list.
    public var order: Float?
    /// How far the layer moves with the camera: 1 moves with the world, 0.5 half as fast (far
    /// background), 0 stays put. Applied by `TilemapSpriteDrawer`; placed prefabs are static.
    public var parallax: Vec2
    public var opacity: Float
    public var visible: Bool
    /// Tiles of this layer make collision shapes.
    public var collision: Bool

    public static var fieldHints: [String: FieldHints] {
        ["data": FieldHints(hidden: true), "opacity": FieldHints(range: 0...1, step: 0.05),
         "parallax": FieldHints(range: 0...2, step: 0.05, tooltip: "1 moves with the world, 0 stays with the camera"),
         "collision": FieldHints(tooltip: "Tiles with a collision shape on this layer collide"),
         "order": FieldHints(tooltip: "Draw order: larger is in front (blank: the list order)")]
    }

    public init(name: String = "Layer", data: [Int] = [], order: Float? = nil, parallax: Vec2 = Vec2(1, 1), opacity: Float = 1,
                visible: Bool = true, collision: Bool = true) {
        self.name = name
        self.data = data
        self.order = order
        self.parallax = parallax
        self.opacity = opacity
        self.visible = visible
        self.collision = collision
    }

    /// `cells` holds the rows (top first); a flat `data` array is read too.
    private enum CodingKeys: String, CodingKey { case name, cells, data, order, parallax, opacity, visible, collision }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var data: [Int] = []
        if let rows = try c.decodeIfPresent([[Int]].self, forKey: .cells) { data = rows.flatMap { $0 } }
        else if let flat = try c.decodeIfPresent([Int].self, forKey: .data) { data = flat }
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "Layer", data: data,
                  order: try c.decodeIfPresent(Float.self, forKey: .order),
                  parallax: try c.decodeIfPresent(Vec2.self, forKey: .parallax) ?? Vec2(1, 1),
                  opacity: try c.decodeIfPresent(Float.self, forKey: .opacity) ?? 1,
                  visible: try c.decodeIfPresent(Bool.self, forKey: .visible) ?? true,
                  collision: try c.decodeIfPresent(Bool.self, forKey: .collision) ?? true)
    }

    /// Writes `data` as rows of `columns` (call through `Tilemap`, which knows the width).
    func encode(to encoder: any Encoder, columns: Int) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        let width = max(columns, 1)
        try c.encode(stride(from: 0, to: data.count, by: width).map { Array(data[$0..<min($0 + width, data.count)]) }, forKey: .cells)
        try c.encodeIfPresent(order, forKey: .order)
        if parallax != Vec2(1, 1) { try c.encode(parallax, forKey: .parallax) }
        if opacity != 1 { try c.encode(opacity, forKey: .opacity) }
        if !visible { try c.encode(visible, forKey: .visible) }
        try c.encode(collision, forKey: .collision)
    }

    public func encode(to encoder: any Encoder) throws { try encode(to: encoder, columns: data.count) }
}

/// How a terrain set reads a cell's neighbors.
public enum TilemapTerrainMode: String, Codable, CaseIterable, Sendable {
    /// The four sides: mask bits N 1, E 2, S 4, W 8 (16 tiles).
    case edges
    /// Sides and corners: N 1, NE 2, E 4, SE 8, S 16, SW 32, W 64, NW 128; a corner counts only
    /// when both sides next to it are set (47 distinct tiles).
    case blob
}

/// An auto-tiling rule: painting with it marks cells as this terrain and picks each cell's tile
/// from which neighbors are the same terrain, so edges and corners come out right.
public struct TilemapTerrainSet: Codable, Equatable, Sendable {
    public var name: String
    public var mode: TilemapTerrainMode
    /// `edges` shorthand: the 16 tiles are `first + mask` (a row of 16 in mask order); -1: none.
    public var first: Int
    /// Mask (as a decimal string) → tile index; overrides `first`.
    public var tiles: [String: Int]
    /// The tile for a mask with no tile (default: the all-neighbors tile).
    public var fill: Int?
    /// Cells outside the map count as this terrain (ground reaching the edge has no border there).
    public var edgesConnect: Bool

    public init(name: String = "Terrain", mode: TilemapTerrainMode = .edges, first: Int = -1, tiles: [String: Int] = [:],
                fill: Int? = nil, edgesConnect: Bool = true) {
        self.name = name
        self.mode = mode
        self.first = first
        self.tiles = tiles
        self.fill = fill
        self.edgesConnect = edgesConnect
    }

    private enum CodingKeys: String, CodingKey { case name, mode, first, tiles, fill, edgesConnect }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "Terrain",
                  mode: try c.decodeIfPresent(TilemapTerrainMode.self, forKey: .mode) ?? .edges,
                  first: try c.decodeIfPresent(Int.self, forKey: .first) ?? -1,
                  tiles: try c.decodeIfPresent([String: Int].self, forKey: .tiles) ?? [:],
                  fill: try c.decodeIfPresent(Int.self, forKey: .fill),
                  edgesConnect: try c.decodeIfPresent(Bool.self, forKey: .edgesConnect) ?? true)
    }

    /// Mask → tile, `first` expanded and `tiles` applied.
    public var table: [Int: Int] {
        var table: [Int: Int] = [:]
        if first >= 0 && mode == .edges { for mask in 0..<16 { table[mask] = first + mask } }
        for (key, tile) in tiles { if let mask = Int(key) { table[mask] = tile } }
        return table
    }

    /// Every tile that belongs to the terrain.
    public var members: Set<Int> {
        var set = Set(table.values)
        if let fill { set.insert(fill) }
        return set
    }

    /// The all-neighbors mask.
    public var fullMask: Int { mode == .edges ? 15 : 255 }

    /// Clears corner bits whose two sides aren't both set (`blob` only).
    public static func reduced(_ mask: Int, mode: TilemapTerrainMode) -> Int {
        guard mode == .blob else { return mask & 15 }
        var m = mask & 0b0101_0101  // sides
        let corners = [(2, 1, 4), (8, 4, 16), (32, 16, 64), (128, 64, 1)]
        for (corner, a, b) in corners where mask & corner != 0 && mask & a != 0 && mask & b != 0 { m |= corner }
        return m
    }

    /// The tile for neighbor `mask`: the exact entry, else (blob) the sides-only entry, else
    /// the entry sharing the most neighbors, else `fill`.
    public func tile(for mask: Int) -> Int? {
        let table = self.table
        let mask = Self.reduced(mask, mode: mode)
        if let tile = table[mask] { return tile }
        if mode == .blob, let tile = table[mask & 0b0101_0101] { return tile }
        if let fill { return fill }
        var best: (score: Int, mask: Int, tile: Int)?
        for (m, tile) in table {
            let score = (m & mask).nonzeroBitCount * 2 - (m ^ mask).nonzeroBitCount
            if best == nil || score > best!.score || (score == best!.score && m < best!.mask) { best = (score, m, tile) }
        }
        return best?.tile ?? table[fullMask]
    }
}

/// A named point or area for game code: spawns, triggers, pickups. `position` is in world units
/// from the map's bottom-left corner (y up); `size` 0 is a point.
public struct TilemapObject: Codable, Equatable, Sendable {
    public var name: String
    public var type: String
    public var position: Vec2
    public var size: Vec2
    /// With a size: the prefab node gets a trigger `Collider2D` box.
    public var trigger: Bool
    public var properties: [String: JSONValue]

    public static var fieldHints: [String: FieldHints] {
        ["position": FieldHints(step: 0.25, tooltip: "World units from the map's bottom-left corner"),
         "size": FieldHints(step: 0.25, tooltip: "0 for a point"),
         "trigger": FieldHints(tooltip: "With a size: a trigger Collider2D box in the placed prefab"),
         "properties": FieldHints(hidden: true)]
    }

    public init(name: String = "Object", type: String = "", position: Vec2 = .zero, size: Vec2 = .zero, trigger: Bool = false,
                properties: [String: JSONValue] = [:]) {
        self.name = name
        self.type = type
        self.position = position
        self.size = size
        self.trigger = trigger
        self.properties = properties
    }

    private enum CodingKeys: String, CodingKey { case name, type, position, size, trigger, properties }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "Object",
                  type: try c.decodeIfPresent(String.self, forKey: .type) ?? "",
                  position: try c.decodeIfPresent(Vec2.self, forKey: .position) ?? .zero,
                  size: try c.decodeIfPresent(Vec2.self, forKey: .size) ?? .zero,
                  trigger: try c.decodeIfPresent(Bool.self, forKey: .trigger) ?? false,
                  properties: try c.decodeIfPresent([String: JSONValue].self, forKey: .properties) ?? [:])
    }
}

// MARK: - The map

/// The contents of a `.tilemap` file. See the notes at the top of this file.
public struct Tilemap: Codable, Equatable, Sendable {
    public static let maxSide = 1024

    /// Tile width and height in pixels.
    public var tileWidth: Int
    public var tileHeight: Int
    /// Cells across and down.
    public var columns: Int
    public var rows: Int
    /// Pixels per world unit (0: the tile width, so a tile is one unit wide).
    public var pixelsPerUnit: Float
    /// Cells per chunk side (each layer's chunk is one mesh / one culling unit).
    public var chunkSize: Int
    public var tileset: TilemapTileset
    public var layers: [TilemapLayer]
    public var terrains: [TilemapTerrainSet]
    public var objects: [TilemapObject]
    /// sRGB color shown behind the map in the editor (and by games that read it); nil: none.
    public var background: Vec4?

    public init(tileWidth: Int = 16, tileHeight: Int = 16, columns: Int = 32, rows: Int = 18, pixelsPerUnit: Float = 0,
                chunkSize: Int = 16, tileset: TilemapTileset = TilemapTileset(), layers: [TilemapLayer] = [],
                terrains: [TilemapTerrainSet] = [], objects: [TilemapObject] = [], background: Vec4? = nil) {
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.columns = columns
        self.rows = rows
        self.pixelsPerUnit = pixelsPerUnit
        self.chunkSize = chunkSize
        self.tileset = tileset
        self.layers = layers
        self.terrains = terrains
        self.objects = objects
        self.background = background
    }

    private enum CodingKeys: String, CodingKey {
        case tileSize, size, pixelsPerUnit, chunkSize, tileset, layers, terrains, objects, background
    }

    private struct LayerList: Encodable {
        var layers: [TilemapLayer]
        var columns: Int
        func encode(to encoder: any Encoder) throws {
            var c = encoder.unkeyedContainer()
            for layer in layers { try c.encode(LayerBox(layer: layer, columns: columns)) }
        }
    }

    private struct LayerBox: Encodable {
        var layer: TilemapLayer
        var columns: Int
        func encode(to encoder: any Encoder) throws { try layer.encode(to: encoder, columns: columns) }
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tile = try c.decodeIfPresent([Int].self, forKey: .tileSize) ?? [16, 16]
        let size = try c.decodeIfPresent([Int].self, forKey: .size) ?? [32, 18]
        self.init(tileWidth: tile.first ?? 16, tileHeight: tile.count > 1 ? tile[1] : tile.first ?? 16,
                  columns: size.first ?? 32, rows: size.count > 1 ? size[1] : size.first ?? 18,
                  pixelsPerUnit: try c.decodeIfPresent(Float.self, forKey: .pixelsPerUnit) ?? 0,
                  chunkSize: try c.decodeIfPresent(Int.self, forKey: .chunkSize) ?? 16,
                  tileset: try c.decodeIfPresent(TilemapTileset.self, forKey: .tileset) ?? TilemapTileset(),
                  layers: try c.decodeIfPresent([TilemapLayer].self, forKey: .layers) ?? [],
                  terrains: try c.decodeIfPresent([TilemapTerrainSet].self, forKey: .terrains) ?? [],
                  objects: try c.decodeIfPresent([TilemapObject].self, forKey: .objects) ?? [],
                  background: try c.decodeIfPresent(Vec4.self, forKey: .background))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode([tileWidth, tileHeight], forKey: .tileSize)
        try c.encode([columns, rows], forKey: .size)
        try c.encode(pixelsPerUnit, forKey: .pixelsPerUnit)
        try c.encode(chunkSize, forKey: .chunkSize)
        try c.encode(tileset, forKey: .tileset)
        try c.encode(LayerList(layers: layers, columns: cols), forKey: .layers)
        try c.encode(terrains, forKey: .terrains)
        try c.encode(objects, forKey: .objects)
        try c.encodeIfPresent(background, forKey: .background)
    }

    public func fileData() throws -> Data {
        var copy = self
        copy.normalize()
        return try AssetJSON.encode(copy)
    }

    // MARK: Sizes

    /// The size clamped to 1...`maxSide`.
    public var cols: Int { min(max(columns, 1), Self.maxSide) }
    public var rowCount: Int { min(max(rows, 1), Self.maxSide) }
    public var tileW: Int { min(max(tileWidth, 1), 1024) }
    public var tileH: Int { min(max(tileHeight, 1), 1024) }
    /// Pixels per world unit in effect.
    public var unitsPerPixel: Float { 1 / (pixelsPerUnit > 0 ? pixelsPerUnit : Float(tileW)) }
    /// One cell's size in world units.
    public var cellSize: Vec2 { Vec2(Float(tileW), Float(tileH)) * unitsPerPixel }
    /// The whole map's size in world units.
    public var worldSize: Vec2 { Vec2(Float(cols), Float(rowCount)) * cellSize }
    public var chunk: Int { min(max(chunkSize, 1), 256) }
    /// Chunks across and down.
    public var chunkCounts: (x: Int, y: Int) { ((cols + chunk - 1) / chunk, (rowCount + chunk - 1) / chunk) }

    /// Makes every layer's data `cols * rowCount` long (padding with empty cells) and the sizes valid.
    public mutating func normalize() {
        columns = cols
        rows = rowCount
        tileWidth = tileW
        tileHeight = tileH
        let n = cols * rowCount
        for i in layers.indices where layers[i].data.count != n {
            layers[i].data = Array(layers[i].data.prefix(n)) + [Int](repeating: -1, count: max(n - layers[i].data.count, 0))
        }
    }

    /// Changes the size, keeping cells by their (x, y) from the top-left (or, with `anchorBottom`, from the bottom-left).
    public mutating func resize(columns newColumns: Int, rows newRows: Int, anchorBottom: Bool = false) {
        normalize()
        let oldC = cols, oldR = rowCount
        columns = min(max(newColumns, 1), Self.maxSide)
        rows = min(max(newRows, 1), Self.maxSide)
        let c = cols, r = rowCount
        let shift = anchorBottom ? r - oldR : 0
        for i in layers.indices {
            var data = [Int](repeating: -1, count: c * r)
            for y in 0..<r {
                let sy = y - shift
                guard sy >= 0, sy < oldR else { continue }
                for x in 0..<min(c, oldC) { data[y * c + x] = layers[i].data[sy * oldC + x] }
            }
            layers[i].data = data
        }
    }

    // MARK: Access

    public func contains(x: Int, y: Int) -> Bool { x >= 0 && y >= 0 && x < cols && y < rowCount }

    public func layerIndex(named name: String) -> Int? { layers.firstIndex { $0.name == name } }

    /// The cell at (x, y) of layer `layer` (empty outside the map).
    public func cell(layer: Int, x: Int, y: Int) -> TileCell {
        guard layers.indices.contains(layer), contains(x: x, y: y) else { return .empty }
        let i = y * cols + x
        return i < layers[layer].data.count ? TileCell(encoded: layers[layer].data[i]) : .empty
    }

    /// Sets a cell (ignored outside the map).
    public mutating func setCell(layer: Int, x: Int, y: Int, _ cell: TileCell) {
        guard layers.indices.contains(layer), contains(x: x, y: y) else { return }
        if layers[layer].data.count != cols * rowCount { normalize() }
        layers[layer].data[y * cols + x] = cell.encoded
    }

    /// The draw order of layer `index`.
    public func order(ofLayer index: Int) -> Float { layers[index].order ?? Float(index) }

    /// The world rectangle (min corner, size) of cell (x, y), from the map's bottom-left corner.
    public func cellRect(x: Int, y: Int) -> (min: Vec2, size: Vec2) {
        let s = cellSize
        return (Vec2(Float(x) * s.x, Float(rowCount - 1 - y) * s.y), s)
    }

    /// The world position of the center of cell (x, y).
    public func cellCenter(x: Int, y: Int) -> Vec2 {
        let r = cellRect(x: x, y: y)
        return r.min + r.size / 2
    }

    /// The cell under a world position (relative to the map's bottom-left corner), or nil outside the map.
    public func cell(atWorld p: Vec2) -> (x: Int, y: Int)? {
        let s = cellSize
        let x = Int((p.x / s.x).rounded(.down)), yUp = Int((p.y / s.y).rounded(.down))
        let y = rowCount - 1 - yUp
        return contains(x: x, y: y) ? (x, y) : nil
    }

    /// The tile data for a tile index (nil for a plain tile).
    public func tileInfo(_ index: Int) -> TilemapTile? { tileset.tile(index) }

    /// The tile at a world position on layer `layer` (empty when outside or unpainted).
    public func cell(layer: String, atWorld p: Vec2) -> TileCell {
        guard let l = layerIndex(named: layer), let c = cell(atWorld: p) else { return .empty }
        return cell(layer: l, x: c.x, y: c.y)
    }

    /// Whether the tile at a world position (any layer, or `layer`) has `tag`.
    public func hasTag(_ tag: String, atWorld p: Vec2, layer: String? = nil) -> Bool {
        guard let c = cell(atWorld: p) else { return false }
        for (i, l) in layers.enumerated() where layer == nil || l.name == layer {
            let t = cell(layer: i, x: c.x, y: c.y)
            if !t.isEmpty, tileInfo(t.tile)?.tags.contains(tag) == true { return true }
        }
        return false
    }

    /// The objects of a type, in file order.
    public func objects(ofType type: String) -> [TilemapObject] { objects.filter { $0.type == type } }

    /// The first object named `name`.
    public func object(named name: String) -> TilemapObject? { objects.first { $0.name == name } }

    /// How many cells of each layer are painted.
    public var paintedCounts: [Int] { layers.map { $0.data.reduce(0) { $1 >= 0 ? $0 + 1 : $0 } } }

    /// Every tile index used by any layer.
    public var usedTiles: Set<Int> {
        var set = Set<Int>()
        for layer in layers { for v in layer.data where v >= 0 { set.insert(v & 0xFFFF) } }
        return set
    }
}

// MARK: - Editing

extension Tilemap {
    /// Paints `cell` into `cells` of layer `layer` (cells outside the map are skipped). Returns how many changed.
    @discardableResult
    public mutating func paint(layer: Int, cells: [(x: Int, y: Int)], _ cell: TileCell) -> Int {
        normalize()
        var changed = 0
        for c in cells where contains(x: c.x, y: c.y) {
            if self.cell(layer: layer, x: c.x, y: c.y) != cell { changed += 1 }
            setCell(layer: layer, x: c.x, y: c.y, cell)
        }
        return changed
    }

    /// The cells of a rectangle (corners inclusive, in any order), clipped to the map.
    public func rectCells(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int) -> [(x: Int, y: Int)] {
        let lx = max(min(x0, x1), 0), hx = min(max(x0, x1), cols - 1)
        let ly = max(min(y0, y1), 0), hy = min(max(y0, y1), rowCount - 1)
        guard lx <= hx, ly <= hy else { return [] }
        var cells: [(x: Int, y: Int)] = []
        for y in ly...hy { for x in lx...hx { cells.append((x, y)) } }
        return cells
    }

    /// The connected cells (4-way) around (x, y) holding the same tile (transform included) as it.
    public func floodRegion(layer: Int, x: Int, y: Int) -> [(x: Int, y: Int)] {
        guard contains(x: x, y: y), layers.indices.contains(layer) else { return [] }
        let target = cell(layer: layer, x: x, y: y)
        var seen = [Bool](repeating: false, count: cols * rowCount)
        var stack = [(x, y)]
        var region: [(x: Int, y: Int)] = []
        seen[y * cols + x] = true
        while let (cx, cy) = stack.popLast() {
            region.append((cx, cy))
            for (nx, ny) in [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)] where contains(x: nx, y: ny) {
                let i = ny * cols + nx
                if !seen[i] && cell(layer: layer, x: nx, y: ny) == target {
                    seen[i] = true
                    stack.append((nx, ny))
                }
            }
        }
        return region
    }

    /// Fills the region `floodRegion` finds with `cell`. Returns how many changed.
    @discardableResult
    public mutating func floodFill(layer: Int, x: Int, y: Int, _ cell: TileCell) -> Int {
        paint(layer: layer, cells: floodRegion(layer: layer, x: x, y: y), cell)
    }

    /// Paints each cell with a tile picked from `tiles` (stable for a `seed` and cell). Returns how many changed.
    @discardableResult
    public mutating func paintRandom(layer: Int, cells: [(x: Int, y: Int)], tiles: [Int], seed: Int = 1,
                                     flipX: Bool = false, flipY: Bool = false, rotation: Int = 0) -> Int {
        guard !tiles.isEmpty else { return 0 }
        normalize()
        var changed = 0
        for c in cells where contains(x: c.x, y: c.y) {
            var h = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15
            h ^= UInt64(c.x) &* 0xBF58_476D_1CE4_E5B9
            h ^= UInt64(c.y) &* 0x94D0_49BB_1331_11EB
            h ^= h >> 31
            h = h &* 0xD6E8_FEB8_6659_FD93
            h ^= h >> 32
            let new = TileCell(tile: tiles[Int(h % UInt64(tiles.count))], flipX: flipX, flipY: flipY, rotation: rotation)
            if cell(layer: layer, x: c.x, y: c.y) != new { changed += 1 }
            setCell(layer: layer, x: c.x, y: c.y, new)
        }
        return changed
    }

    public func terrainIndex(named name: String) -> Int? { terrains.firstIndex { $0.name == name } }

    /// The neighbor mask of cell (x, y) for terrain set `terrain` on layer `layer`.
    public func terrainMask(layer: Int, x: Int, y: Int, terrain: TilemapTerrainSet, members: Set<Int>? = nil) -> Int {
        let members = members ?? terrain.members
        func same(_ dx: Int, _ dy: Int) -> Bool {
            let nx = x + dx, ny = y + dy
            guard contains(x: nx, y: ny) else { return terrain.edgesConnect }
            let c = cell(layer: layer, x: nx, y: ny)
            return !c.isEmpty && members.contains(c.tile)
        }
        if terrain.mode == .edges {
            return (same(0, -1) ? 1 : 0) | (same(1, 0) ? 2 : 0) | (same(0, 1) ? 4 : 0) | (same(-1, 0) ? 8 : 0)
        }
        let bits = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]
        var mask = 0
        for (i, d) in bits.enumerated() where same(d.0, d.1) { mask |= 1 << i }
        return TilemapTerrainSet.reduced(mask, mode: .blob)
    }

    /// Paints (or with `erase`, clears) terrain `terrain` into `cells` of layer `layer`, then
    /// re-picks the tile of every terrain cell in and around them from its neighbors.
    @discardableResult
    public mutating func paintTerrain(layer: Int, terrain index: Int, cells: [(x: Int, y: Int)], erase: Bool = false) -> Int {
        guard terrains.indices.contains(index), layers.indices.contains(layer) else { return 0 }
        normalize()
        let terrain = terrains[index]
        let members = terrain.members
        guard let placeholder = terrain.tile(for: terrain.fullMask) ?? members.first else { return 0 }
        let before = layers[layer].data
        for c in cells where contains(x: c.x, y: c.y) {
            setCell(layer: layer, x: c.x, y: c.y, erase ? .empty : TileCell(tile: placeholder))
        }
        var touched = Set<Int>()
        for c in cells {
            for dy in -1...1 { for dx in -1...1 where contains(x: c.x + dx, y: c.y + dy) { touched.insert((c.y + dy) * cols + c.x + dx) } }
        }
        retile(layer: layer, terrain: terrain, members: members, cells: touched)
        return zip(before, layers[layer].data).reduce(0) { $1.0 != $1.1 ? $0 + 1 : $0 }
    }

    /// Re-picks the tile of every cell of terrain `terrain` on layer `layer` (all cells, or `region`).
    public mutating func autotile(layer: Int, terrain index: Int) {
        guard terrains.indices.contains(index), layers.indices.contains(layer) else { return }
        normalize()
        retile(layer: layer, terrain: terrains[index], members: terrains[index].members, cells: Set(0..<(cols * rowCount)))
    }

    private mutating func retile(layer: Int, terrain: TilemapTerrainSet, members: Set<Int>, cells: Set<Int>) {
        // Masks are read from the state before any cell changes, so the order doesn't matter.
        var updates: [(Int, Int)] = []
        for i in cells.sorted() {
            let x = i % cols, y = i / cols
            let c = cell(layer: layer, x: x, y: y)
            guard !c.isEmpty, members.contains(c.tile) else { continue }
            if let tile = terrain.tile(for: terrainMask(layer: layer, x: x, y: y, terrain: terrain, members: members)) {
                updates.append((i, tile))
            }
        }
        for (i, tile) in updates { layers[layer].data[i] = TileCell(tile: tile).encoded }
    }
}

// MARK: - Tile set layout

/// Where each tile sits in the tile set texture.
public struct TilesetLayout: Equatable, Sendable {
    public var imageWidth: Int
    public var imageHeight: Int
    public var tileWidth: Int
    public var tileHeight: Int
    public var margin: Int
    public var spacing: Int
    public var columns: Int
    /// Number of tiles.
    public var count: Int

    public init(imageWidth: Int, imageHeight: Int, tileWidth: Int, tileHeight: Int, margin: Int = 0, spacing: Int = 0, count: Int? = nil) {
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.tileWidth = max(tileWidth, 1)
        self.tileHeight = max(tileHeight, 1)
        self.margin = margin
        self.spacing = spacing
        columns = max((imageWidth - 2 * margin + spacing) / (self.tileWidth + spacing), 0)
        let rows = max((imageHeight - 2 * margin + spacing) / (self.tileHeight + spacing), 0)
        self.count = min(count ?? columns * rows, columns * rows)
    }

    public var rows: Int { columns > 0 ? (count + columns - 1) / columns : 0 }

    public func contains(_ tile: Int) -> Bool { tile >= 0 && tile < count }

    /// The pixel rectangle of `tile` (top-left origin).
    public func rect(_ tile: Int) -> (x: Int, y: Int, width: Int, height: Int) {
        let c = columns > 0 ? tile % columns : 0, r = columns > 0 ? tile / columns : 0
        return (margin + c * (tileWidth + spacing), margin + r * (tileHeight + spacing), tileWidth, tileHeight)
    }

    /// Texture coordinates of the top-left and bottom-right corners (v down), pulled in by `inset` pixels.
    public func uv(_ tile: Int, inset: Float = 0) -> (min: Vec2, max: Vec2) {
        let r = rect(tile)
        let w = Float(max(imageWidth, 1)), h = Float(max(imageHeight, 1))
        return (Vec2((Float(r.x) + inset) / w, (Float(r.y) + inset) / h),
                Vec2((Float(r.x + r.width) - inset) / w, (Float(r.y + r.height) - inset) / h))
    }
}

extension Tilemap {
    /// The layout of the tile set texture of `width` x `height` pixels this map's source produces.
    /// `tileCount` caps the number of tiles (a sprite's frame count: its grid's last row may be part empty).
    public func tilesetLayout(imageWidth width: Int, imageHeight height: Int, tileCount: Int? = nil) -> TilesetLayout {
        switch tileset.source {
        case .sprite:
            // Frames in tileSize cells, each padded by one pixel repeating its edge (see `spriteTileset`).
            return TilesetLayout(imageWidth: width, imageHeight: height, tileWidth: tileW, tileHeight: tileH, margin: 1, spacing: 2,
                                 count: tileCount)
        case .image(_, let margin, let spacing):
            return TilesetLayout(imageWidth: width, imageHeight: height, tileWidth: tileW, tileHeight: tileH, margin: margin, spacing: spacing)
        case .images(let paths):
            return TilesetLayout(imageWidth: width, imageHeight: height, tileWidth: tileW, tileHeight: tileH, count: tileCount ?? paths.count)
        case .unsupported:
            return TilesetLayout(imageWidth: width, imageHeight: height, tileWidth: tileW, tileHeight: tileH, count: 0)
        }
    }

    /// The tile set texture and its layout. `load` returns the image at an asset path (nil if it can't).
    /// Problems (missing images, tiles of another size, an unsupported source) go to `warnings`.
    /// `loadSprite` reads a `.sprite` source.
    public func buildTileset(load: (String) -> Image?, loadSprite: (String) -> PixelSprite? = { _ in nil },
                             warnings: inout [String]) -> (image: Image, layout: TilesetLayout) {
        let tw = tileW, th = tileH
        func placeholder() -> (Image, TilesetLayout) {
            let image = Image(width: tw, height: th, pixels: [UInt8](repeating: 255, count: tw * th * 4))
            return (image, TilesetLayout(imageWidth: tw, imageHeight: th, tileWidth: tw, tileHeight: th, count: 0))
        }
        switch tileset.source {
        case .image(let path, _, _):
            guard !path.isEmpty else {
                warnings.append("the tile set has no image")
                return placeholder()
            }
            guard let image = load(path) else {
                warnings.append("tile set: can't read the image '\(path)'")
                return placeholder()
            }
            let layout = tilesetLayout(imageWidth: image.width, imageHeight: image.height)
            if layout.count == 0 { warnings.append("tile set: '\(path)' (\(image.width) x \(image.height)) is smaller than one \(tw) x \(th) tile") }
            return (image, layout)
        case .images(let paths):
            guard !paths.isEmpty else {
                warnings.append("the tile set has no images")
                return placeholder()
            }
            let columns = Int(Float(paths.count).squareRoot().rounded(.up))
            let rows = (paths.count + columns - 1) / columns
            let width = columns * tw, height = rows * th
            var pixels = [UInt8](repeating: 0, count: width * height * 4)
            for (i, path) in paths.enumerated() {
                guard let image = load(path) else {
                    warnings.append("tile set: can't read the image '\(path)' (tile \(i))")
                    continue
                }
                if image.width != tw || image.height != th {
                    warnings.append("tile set: '\(path)' is \(image.width) x \(image.height), not \(tw) x \(th); cropped or padded")
                }
                let ox = (i % columns) * tw, oy = (i / columns) * th
                for y in 0..<min(th, image.height) {
                    for x in 0..<min(tw, image.width) {
                        let s = (y * image.width + x) * 4, d = ((oy + y) * width + ox + x) * 4
                        for k in 0..<4 { pixels[d + k] = image.pixels[s + k] }
                    }
                }
            }
            return (Image(width: width, height: height, pixels: pixels),
                    TilesetLayout(imageWidth: width, imageHeight: height, tileWidth: tw, tileHeight: th, count: paths.count))
        case .sprite(let path):
            guard !path.isEmpty else {
                warnings.append("the tile set has no sprite")
                return placeholder()
            }
            guard let sprite = loadSprite(path), !sprite.frames.isEmpty else {
                warnings.append("tile set: can't read the sprite '\(path)'")
                return placeholder()
            }
            if sprite.width != tw || sprite.height != th {
                warnings.append("tile set: '\(path)' frames are \(sprite.width) x \(sprite.height), not \(tw) x \(th); cropped or padded")
            }
            return spriteTileset(sprite)
        case .unsupported(let kind, _):
            warnings.append("tile set: the source kind '\(kind)' isn't supported by this engine version")
            return placeholder()
        }
    }

    /// A sprite's frames as a tile set texture: frame i in grid cell i (`PixelSprite.sheetColumns`
    /// per row), each cropped or padded to the map's tile size from its top-left and surrounded by
    /// one pixel repeating its edge, so filtering never bleeds into a neighbor.
    public func spriteTileset(_ sprite: PixelSprite) -> (image: Image, layout: TilesetLayout) {
        let tw = tileW, th = tileH
        let count = sprite.frames.count
        let columns = PixelSprite.sheetColumns(frameCount: count)
        let rows = max((count + columns - 1) / columns, 1)
        let cellW = tw + 2, cellH = th + 2
        let width = columns * cellW, height = rows * cellH
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for f in 0..<count {
            let frame = sprite.image(frame: f)
            let left = (f % columns) * cellW + 1, top = (f / columns) * cellH + 1
            for dy in -1...th {
                let sy = min(max(dy, 0), th - 1)
                guard sy < frame.height else { continue }
                for dx in -1...tw {
                    let sx = min(max(dx, 0), tw - 1)
                    guard sx < frame.width else { continue }
                    let s = (sy * frame.width + sx) * 4, d = ((top + dy) * width + left + dx) * 4
                    for k in 0..<4 { pixels[d + k] = frame.pixels[s + k] }
                }
            }
        }
        return (Image(width: width, height: height, pixels: pixels), tilesetLayout(imageWidth: width, imageHeight: height, tileCount: count))
    }

    /// Tile animations from a sprite's tags: each tag plays on the tile of its first frame, at the
    /// tag's per-frame timing (as `PixelSprite.clips()` steps it). One-frame tags and untagged
    /// sprites give none.
    public static func spriteTagAnimations(_ sprite: PixelSprite) -> [Int: TilemapAnimation] {
        guard !sprite.tags.isEmpty, !sprite.frames.isEmpty else { return [:] }
        var out: [Int: TilemapAnimation] = [:]
        for clip in sprite.clips() where Set(clip.frames).count > 1 {
            guard let first = clip.frames.first, out[first] == nil else { continue }
            out[first] = TilemapAnimation(frames: clip.frames, fps: clip.fps, mode: clip.mode.rawValue)
        }
        return out
    }

    /// The map with `animations` given to tiles that have no animation of their own (the file's
    /// entries win). How a `.sprite` tile set's tag animations reach game code and the importer.
    public func addingAnimations(_ animations: [Int: TilemapAnimation]) -> Tilemap {
        var map = self
        for (index, animation) in animations.sorted(by: { $0.key < $1.key }) where map.tileset.tile(index)?.animation == nil {
            var tile = map.tileset.tile(index) ?? TilemapTile(index: index)
            tile.animation = animation
            map.tileset.setTile(tile)
        }
        return map
    }

    /// Problems found without reading images: unknown tiles, bad layers and terrains, duplicate names.
    public func validate(tileCount: Int?) -> [String] {
        var problems: [String] = []
        let names = layers.map(\.name)
        if Set(names).count != names.count { problems.append("some layers share a name; tools use the first") }
        if let tileCount {
            let missing = usedTiles.filter { $0 >= tileCount }.sorted()
            if !missing.isEmpty {
                problems.append("cells use tile\(missing.count == 1 ? "" : "s") \(missing.prefix(8).map(String.init).joined(separator: ", ")) but the tile set has \(tileCount)")
            }
            for tile in tileset.tiles {
                if tile.index >= tileCount || tile.index < 0 { problems.append("tile entry \(tile.index) is outside the tile set (\(tileCount) tiles)") }
                for f in tile.animation?.frames ?? [] where f < 0 || f >= tileCount {
                    problems.append("tile \(tile.index): animation frame \(f) is outside the tile set")
                    break
                }
            }
        }
        for tile in tileset.tiles where tile.collision == .polygon && tile.points.count < 3 {
            problems.append("tile \(tile.index): a polygon collision needs at least 3 points")
        }
        for terrain in terrains where terrain.table.isEmpty && terrain.fill == nil {
            problems.append("terrain '\(terrain.name)' has no tiles (set first or tiles)")
        }
        for layer in layers where layer.data.count != cols * rowCount && !layer.data.isEmpty {
            problems.append("layer '\(layer.name)' has \(layer.data.count) cells, the map \(cols * rowCount); padded or cut")
        }
        return problems
    }
}
