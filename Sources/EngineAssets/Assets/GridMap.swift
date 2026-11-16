import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// A grid map: the contents of a `.gridmap` file (JSON, every key optional). 3D levels built
// from modular pieces on a grid: dungeons, buildings, city blocks. `GridMapImporter` turns it
// into a prefab of the placed pieces (one node per piece, so equal meshes and materials draw as
// one instanced batch) with one merged triangle-mesh collider per chunk and floor.
//
// Cell (x, y, z) spans x*cellSize.x ... (x+1)*cellSize.x (z likewise) and stands on the floor
// y*cellSize.y. A piece is centered on the cells it covers (its footprint, from the anchor cell
// toward +x and +z; a quarter turn swaps width and depth) and stands on the floor.
//
// ```json
// {
//   "cellSize": [2, 3, 2], "chunkSize": 16, "layers": ["floor", "walls", "props"],
//   "pieces": [
//     {"name": "Floor", "asset": "Pieces/floor.meshbuild", "layer": "floor"},
//     {"name": "Crate", "asset": "Models/crate.glb", "layer": "props", "scale": [0.5, 0.5, 0.5]},
//     {"name": "Wall", "layer": "walls", "join": {"single": "Post", "end": "WallEnd", "straight": "WallStraight",
//                                                 "corner": "WallCorner", "tee": "WallTee", "cross": "WallCross"}}
//   ],
//   "cells": [{"at": [0, 0, 0], "piece": "Floor", "layer": "floor"},
//             {"at": [1, 0, 0], "piece": "Wall", "layer": "walls", "rotation": 90, "flipX": true}]
// }
// ```
//
// Auto-joining: a piece with `join` is painted like any piece, but each of its cells becomes the
// single, end, straight, corner, tee or cross piece that fits its neighbors (cells on the same
// floor and layer holding the same piece, one of its variants or a `joinsWith` piece), turned to
// face them. Variants are authored connecting toward +x (end), +x and -x (straight), +x and +z
// (corner), and +x, -x and +z (tee). An auto piece with a footprint bigger than one cell covers
// a square block (its footprint's larger side), looks for neighbors along each whole side of the
// block, and its variants are centered on the block.

/// A grid position: x and z across, y the floor.
public struct GridCoord: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public var x: Int
    public var y: Int
    public var z: Int

    public init(_ x: Int, _ y: Int, _ z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(from decoder: any Decoder) throws {
        var c = try decoder.unkeyedContainer()
        x = try c.decodeIfPresent(Int.self) ?? 0
        y = try c.decodeIfPresent(Int.self) ?? 0
        z = try c.decodeIfPresent(Int.self) ?? 0
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(x)
        try c.encode(y)
        try c.encode(z)
    }

    public static func < (a: GridCoord, b: GridCoord) -> Bool { (a.y, a.z, a.x) < (b.y, b.z, b.x) }

    public var description: String { "[\(x), \(y), \(z)]" }
}

/// How a placed piece collides.
public enum GridPieceCollider: String, Codable, CaseIterable, Sendable {
    /// The piece's triangles when the importer can read them (mesh builds, models), else a box.
    case auto
    /// The piece's triangles (nothing if they can't be read).
    case mesh
    /// A box of the piece's `size`.
    case box
    /// No collision.
    case none
}

/// The variants an auto-joining piece picks from (piece names; "" uses the auto piece's own asset).
public struct GridJoin: Codable, Equatable, Sendable {
    /// No neighbors.
    public var single: String
    /// One neighbor (authored connecting toward +x).
    public var end: String
    /// Two opposite neighbors (+x and -x).
    public var straight: String
    /// Two neighbors at a right angle (+x and +z).
    public var corner: String
    /// Three neighbors (+x, -x and +z).
    public var tee: String
    /// Four neighbors.
    public var cross: String
    /// Other pieces that count as neighbors (a door piece in a wall run, say).
    public var joinsWith: [String]

    public init(single: String = "", end: String = "", straight: String = "", corner: String = "", tee: String = "", cross: String = "",
                joinsWith: [String] = []) {
        self.single = single
        self.end = end
        self.straight = straight
        self.corner = corner
        self.tee = tee
        self.cross = cross
        self.joinsWith = joinsWith
    }

    private enum CodingKeys: String, CodingKey { case single, end, straight, corner, tee, cross, joinsWith }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(single: try c.decodeIfPresent(String.self, forKey: .single) ?? "",
                  end: try c.decodeIfPresent(String.self, forKey: .end) ?? "",
                  straight: try c.decodeIfPresent(String.self, forKey: .straight) ?? "",
                  corner: try c.decodeIfPresent(String.self, forKey: .corner) ?? "",
                  tee: try c.decodeIfPresent(String.self, forKey: .tee) ?? "",
                  cross: try c.decodeIfPresent(String.self, forKey: .cross) ?? "",
                  joinsWith: try c.decodeIfPresent([String].self, forKey: .joinsWith) ?? [])
    }

    /// Every variant name that is set.
    public var variants: [String] { [single, end, straight, corner, tee, cross].filter { !$0.isEmpty } }
}

/// One entry of the piece library.
public struct GridPiece: Codable, Equatable, Sendable {
    public var name: String
    /// What to draw: a `.meshbuild`, a model (`.gltf`, `.glb`, `.obj`) or a `.prefab` path under
    /// `Assets/`, or a mesh reference "asset:<id>#mesh/<name>" (with `material`). Empty for an
    /// auto-joining piece that only picks variants.
    public var asset: String
    /// A material for a mesh reference ("asset:<id>#material", or a `.material` path).
    public var material: String
    /// Cells covered, width (x) and depth (z), at no rotation.
    public var footprint: SIMD2<Int>
    /// The collision box in meters (zero: the footprint's cells, one floor high).
    public var size: Vec3
    /// The pivot: meters the model is moved by, in the cell's frame (it turns with the cell).
    public var offset: Vec3
    /// Degrees about y that turn the model before the cell's rotation (to fix how it was authored).
    public var rotation: Float
    public var scale: Vec3
    /// The layer it is painted on by default ("" : the map's first layer).
    public var layer: String
    public var collider: GridPieceCollider
    /// Makes this an auto-joining piece (see the notes at the top of this file).
    public var join: GridJoin?

    public init(name: String = "Piece", asset: String = "", material: String = "", footprint: SIMD2<Int> = SIMD2(1, 1),
                size: Vec3 = .zero, offset: Vec3 = .zero, rotation: Float = 0, scale: Vec3 = .one, layer: String = "",
                collider: GridPieceCollider = .auto, join: GridJoin? = nil) {
        self.name = name
        self.asset = asset
        self.material = material
        self.footprint = footprint
        self.size = size
        self.offset = offset
        self.rotation = rotation
        self.scale = scale
        self.layer = layer
        self.collider = collider
        self.join = join
    }

    private enum CodingKeys: String, CodingKey { case name, asset, material, footprint, size, offset, rotation, scale, layer, collider, join }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GridPiece()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  asset: try c.decodeIfPresent(String.self, forKey: .asset) ?? d.asset,
                  material: try c.decodeIfPresent(String.self, forKey: .material) ?? d.material,
                  footprint: try c.decodeIfPresent(SIMD2<Int>.self, forKey: .footprint) ?? d.footprint,
                  size: try c.decodeIfPresent(Vec3.self, forKey: .size) ?? d.size,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? d.offset,
                  rotation: try c.decodeIfPresent(Float.self, forKey: .rotation) ?? d.rotation,
                  scale: try c.decodeIfPresent(Vec3.self, forKey: .scale) ?? d.scale,
                  layer: try c.decodeIfPresent(String.self, forKey: .layer) ?? d.layer,
                  collider: try c.decodeIfPresent(GridPieceCollider.self, forKey: .collider) ?? d.collider,
                  join: try c.decodeIfPresent(GridJoin.self, forKey: .join))
    }

    /// The footprint clamped to 1...64 cells per side.
    public var cells: SIMD2<Int> { SIMD2(min(max(footprint.x, 1), 64), min(max(footprint.y, 1), 64)) }

    /// An auto-joining piece's block: it covers this many cells per side (its footprint's larger
    /// side, since a joined piece turns to face its neighbors).
    public var joinBlock: Int { max(cells.x, cells.y) }
}

/// One painted cell: a piece at a grid position on a layer.
public struct GridCell: Codable, Equatable, Sendable {
    /// The anchor cell (the piece covers its footprint from here toward +x and +z).
    public var at: GridCoord
    public var piece: String
    public var layer: String
    /// Degrees about y: 0, 90, 180 or 270.
    public var rotation: Int
    /// Mirrored across x (left-right) and z (front-back), in the cell's frame.
    public var flipX: Bool
    public var flipZ: Bool

    public init(at: GridCoord, piece: String, layer: String = "", rotation: Int = 0, flipX: Bool = false, flipZ: Bool = false) {
        self.at = at
        self.piece = piece
        self.layer = layer
        self.rotation = GridMap.quarterTurns(rotation) * 90
        self.flipX = flipX
        self.flipZ = flipZ
    }

    private enum CodingKeys: String, CodingKey { case at, piece, layer, rotation, flipX, flipZ }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(at: try c.decodeIfPresent(GridCoord.self, forKey: .at) ?? GridCoord(0, 0, 0),
                  piece: try c.decodeIfPresent(String.self, forKey: .piece) ?? "",
                  layer: try c.decodeIfPresent(String.self, forKey: .layer) ?? "",
                  rotation: try c.decodeIfPresent(Int.self, forKey: .rotation) ?? 0,
                  flipX: try c.decodeIfPresent(Bool.self, forKey: .flipX) ?? false,
                  flipZ: try c.decodeIfPresent(Bool.self, forKey: .flipZ) ?? false)
    }

    /// Only what differs from the defaults is written, so big maps stay small.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(at, forKey: .at)
        try c.encode(piece, forKey: .piece)
        if !layer.isEmpty { try c.encode(layer, forKey: .layer) }
        if rotation != 0 { try c.encode(rotation, forKey: .rotation) }
        if flipX { try c.encode(true, forKey: .flipX) }
        if flipZ { try c.encode(true, forKey: .flipZ) }
    }
}

/// A cell after auto-joining: the concrete piece to draw and how it is turned.
public struct GridPlacement: Equatable, Sendable {
    public var cell: GridCell
    /// Index into `GridMap.pieces` of the piece drawn.
    public var piece: Int
    /// Quarter turns about y (0...3).
    public var turns: Int
    /// Mirrored across x after flips are folded into the turn (flipZ = flipX + half a turn).
    public var mirrored: Bool
    /// The layer it ends up on.
    public var layer: String
    /// For an auto-joined cell, the cells per side of the auto piece's square block: the variant
    /// is centered on (and by default collides as) that block, whatever its own footprint.
    public var block: Int? = nil
}

/// The contents of a `.gridmap` file. See the notes at the top of this file.
public struct GridMap: Codable, Equatable, Sendable {
    public static let maxCells = 200_000
    public static let defaultLayers = ["floor", "walls", "props"]

    /// Meters per cell: x, floor height (y), z.
    public var cellSize: Vec3
    /// Cells per chunk side; each chunk (per floor) gets one merged collider.
    public var chunkSize: Int
    /// Give each chunk a collider made of its pieces.
    public var collider: Bool
    public var layers: [String]
    public var pieces: [GridPiece]
    public var cells: [GridCell]

    public static var fieldHints: [String: FieldHints] {
        ["cellSize": FieldHints(step: 0.1, tooltip: "Meters per cell: x, floor height, z"),
         "chunkSize": FieldHints(range: 1...256, step: 1, tooltip: "Cells per chunk side (one collider per chunk and floor)"),
         "collider": FieldHints(tooltip: "Merge the pieces' collision into one collider per chunk")]
    }

    public init(cellSize: Vec3 = Vec3(2, 3, 2), chunkSize: Int = 16, collider: Bool = true, layers: [String] = GridMap.defaultLayers,
                pieces: [GridPiece] = [], cells: [GridCell] = []) {
        self.cellSize = cellSize
        self.chunkSize = chunkSize
        self.collider = collider
        self.layers = layers
        self.pieces = pieces
        self.cells = cells
    }

    private enum CodingKeys: String, CodingKey { case cellSize, chunkSize, collider, layers, pieces, cells }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GridMap()
        self.init(cellSize: try c.decodeIfPresent(Vec3.self, forKey: .cellSize) ?? d.cellSize,
                  chunkSize: try c.decodeIfPresent(Int.self, forKey: .chunkSize) ?? d.chunkSize,
                  collider: try c.decodeIfPresent(Bool.self, forKey: .collider) ?? d.collider,
                  layers: try c.decodeIfPresent([String].self, forKey: .layers) ?? d.layers,
                  pieces: try c.decodeIfPresent([GridPiece].self, forKey: .pieces) ?? [],
                  cells: try c.decodeIfPresent([GridCell].self, forKey: .cells) ?? [])
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    // MARK: Access

    /// Cell size with every side at least 1 cm.
    public var cell: Vec3 { Vec3(max(cellSize.x, 0.01), max(cellSize.y, 0.01), max(cellSize.z, 0.01)) }
    public var chunk: Int { min(max(chunkSize, 1), 256) }
    /// The layers, never empty.
    public var layerNames: [String] { layers.isEmpty ? ["floor"] : layers }

    public func pieceIndex(named name: String) -> Int? { pieces.firstIndex { $0.name == name } }
    public func piece(named name: String) -> GridPiece? { pieceIndex(named: name).map { pieces[$0] } }

    /// The layer a piece goes on when none is given.
    public func defaultLayer(of piece: GridPiece?) -> String {
        if let piece, layerNames.contains(piece.layer) { return piece.layer }
        return layerNames[0]
    }

    /// The layer `cell` is on ("" means its piece's default layer).
    public func layer(of cell: GridCell) -> String {
        cell.layer.isEmpty ? defaultLayer(of: piece(named: cell.piece)) : cell.layer
    }

    /// 0...3 for any multiple of 90 degrees (others round to the nearest).
    public static func quarterTurns(_ degrees: Int) -> Int {
        let q = Int((Double(degrees) / 90).rounded())
        return ((q % 4) + 4) % 4
    }

    /// The cells a piece anchored at `at` covers with `turns` quarter turns.
    public func covered(by piece: GridPiece?, at: GridCoord, turns: Int) -> [GridCoord] {
        let size = piece.map { $0.join != nil ? SIMD2(repeating: $0.joinBlock) : $0.cells } ?? SIMD2(1, 1)
        let (w, d) = turns % 2 == 0 ? (size.x, size.y) : (size.y, size.x)
        guard w > 1 || d > 1 else { return [at] }
        var out: [GridCoord] = []
        for dz in 0..<d { for dx in 0..<w { out.append(GridCoord(at.x + dx, at.y, at.z + dz)) } }
        return out
    }

    public func covered(by cell: GridCell) -> [GridCoord] {
        covered(by: piece(named: cell.piece), at: cell.at, turns: Self.quarterTurns(cell.rotation))
    }

    /// The index of the cell covering `coord` on `layer` (nil: empty there).
    public func cellIndex(at coord: GridCoord, layer: String) -> Int? {
        cells.indices.last { i in layer == self.layer(of: cells[i]) && covered(by: cells[i]).contains(coord) }
    }

    /// The floors that have cells, lowest first.
    public var floors: [Int] { Array(Set(cells.map(\.at.y))).sorted() }

    /// The smallest and largest covered coordinates (nil: no cells).
    public var bounds: (min: GridCoord, max: GridCoord)? {
        var lo: GridCoord?, hi: GridCoord?
        for cell in cells {
            for c in covered(by: cell) {
                lo = GridCoord(min(lo?.x ?? c.x, c.x), min(lo?.y ?? c.y, c.y), min(lo?.z ?? c.z, c.z))
                hi = GridCoord(max(hi?.x ?? c.x, c.x), max(hi?.y ?? c.y, c.y), max(hi?.z ?? c.z, c.z))
            }
        }
        guard let lo, let hi else { return nil }
        return (lo, hi)
    }

    /// The corner of cell (x, y, z) nearest -x, -z, on its floor, in meters.
    public func origin(of coord: GridCoord) -> Vec3 {
        Vec3(Float(coord.x) * cell.x, Float(coord.y) * cell.y, Float(coord.z) * cell.z)
    }

    /// The cell containing a point (meters) on floor `floor`.
    public func coord(at point: Vec3, floor: Int) -> GridCoord {
        GridCoord(Int((point.x / cell.x).rounded(.down)), floor, Int((point.z / cell.z).rounded(.down)))
    }

    // MARK: Editing

    /// Paints `piece` at each of `coords` (on `layer`, default the piece's), replacing whatever on
    /// that layer the new piece overlaps. Returns how many cells were painted.
    @discardableResult
    public mutating func paint(_ piece: String, at coords: [GridCoord], rotation: Int = 0, flipX: Bool = false, flipZ: Bool = false,
                               layer: String? = nil) -> Int {
        paint(coords.map { ($0, piece, rotation) }, flipX: flipX, flipZ: flipZ, layer: layer)
    }

    /// Paints a random piece of `set` (and with `randomRotation` a random quarter turn) at each
    /// coordinate; the choice depends only on `seed` and the position, so it is repeatable.
    @discardableResult
    public mutating func paintRandom(_ set: [String], at coords: [GridCoord], seed: Int = 1, rotation: Int = 0, randomRotation: Bool = false,
                                     layer: String? = nil) -> Int {
        guard !set.isEmpty else { return 0 }
        return paint(coords.map { c in
            let h = Self.hash(c, seed: seed)
            return (c, set[Int(h % UInt64(set.count))], randomRotation ? Int((h >> 20) % 4) * 90 : rotation)
        }, flipX: false, flipZ: false, layer: layer)
    }

    private mutating func paint(_ items: [(GridCoord, String, Int)], flipX: Bool, flipZ: Bool, layer: String?) -> Int {
        var count = 0
        for (coord, name, rotation) in items {
            let p = piece(named: name)
            let target = layer.flatMap { $0.isEmpty ? nil : $0 } ?? defaultLayer(of: p)
            let cell = GridCell(at: coord, piece: name, layer: target, rotation: rotation, flipX: flipX, flipZ: flipZ)
            let area = Set(covered(by: cell))
            let lookup = GridMap(layers: layers, pieces: pieces)
            cells.removeAll { lookup.layer(of: $0) == target && !area.isDisjoint(with: lookup.covered(by: $0)) }
            cells.append(cell)
            count += 1
        }
        return count
    }

    /// Removes the cells covering any of `coords` (on `layer`, or every layer when nil).
    /// Returns how many were removed.
    @discardableResult
    public mutating func erase(at coords: [GridCoord], layer: String? = nil) -> Int {
        let area = Set(coords)
        let before = cells.count
        let lookup = GridMap(layers: layers, pieces: pieces)
        cells.removeAll { cell in
            (layer == nil || layer == lookup.layer(of: cell)) && !area.isDisjoint(with: lookup.covered(by: cell))
        }
        return before - cells.count
    }

    /// Renames a piece everywhere (cells, join variants and links).
    public mutating func renamePiece(_ old: String, to new: String) {
        guard old != new else { return }
        for i in pieces.indices {
            if pieces[i].name == old { pieces[i].name = new }
            guard var join = pieces[i].join else { continue }
            for key in [\GridJoin.single, \.end, \.straight, \.corner, \.tee, \.cross] where join[keyPath: key] == old { join[keyPath: key] = new }
            join.joinsWith = join.joinsWith.map { $0 == old ? new : $0 }
            pieces[i].join = join
        }
        for i in cells.indices where cells[i].piece == old { cells[i].piece = new }
    }

    // MARK: Brush shapes

    /// The cells on a straight line from `a` to `b` on `a`'s floor (Bresenham).
    public static func line(from a: GridCoord, to b: GridCoord) -> [GridCoord] {
        var x = a.x, z = a.z
        let dx = abs(b.x - a.x), dz = -abs(b.z - a.z)
        let sx = a.x < b.x ? 1 : -1, sz = a.z < b.z ? 1 : -1
        var err = dx + dz
        var out: [GridCoord] = []
        while true {
            out.append(GridCoord(x, a.y, z))
            if x == b.x && z == b.z { break }
            let e2 = 2 * err
            if e2 >= dz { err += dz; x += sx }
            if e2 <= dx { err += dx; z += sz }
        }
        return out
    }

    /// The cells of the rectangle with corners `a` and `b` on `a`'s floor (just its edge with `outline`).
    public static func rectangle(from a: GridCoord, to b: GridCoord, outline: Bool = false) -> [GridCoord] {
        let x0 = min(a.x, b.x), x1 = max(a.x, b.x), z0 = min(a.z, b.z), z1 = max(a.z, b.z)
        var out: [GridCoord] = []
        for z in z0...z1 {
            for x in x0...x1 where !outline || x == x0 || x == x1 || z == z0 || z == z1 { out.append(GridCoord(x, a.y, z)) }
        }
        return out
    }

    /// The cells of the box with corners `a` and `b` (every floor between them).
    public static func box(from a: GridCoord, to b: GridCoord) -> [GridCoord] {
        (min(a.y, b.y)...max(a.y, b.y)).flatMap { y in
            rectangle(from: GridCoord(a.x, y, a.z), to: GridCoord(b.x, y, b.z))
        }
    }

    public enum FillError: Error, CustomStringConvertible, Equatable {
        case notEnclosed
        case tooBig

        public var description: String {
            switch self {
            case .notEnclosed: "the area isn't enclosed (it reaches the edge of what is painted on this floor)"
            case .tooBig: "the area is larger than \(GridMap.maxCells) cells"
            }
        }
    }

    /// The flood-fill region from `start` on `layer`: the 4-connected cells of `start`'s floor
    /// holding the same piece there as `start` does. From an empty cell the fill also stops at
    /// cells painted on other layers (walls bound a floor fill) and must be enclosed by them.
    public func floodRegion(from start: GridCoord, layer: String) throws -> [GridCoord] {
        let target = cellIndex(at: start, layer: layer).map { cells[$0].piece }
        var content: [GridCoord: String] = [:]
        var blocked = Set<GridCoord>()
        var lo = start, hi = start
        for cell in cells where cell.at.y == start.y {
            let onLayer = self.layer(of: cell) == layer
            for c in covered(by: cell) {
                if onLayer { content[c] = cell.piece } else { blocked.insert(c) }
                lo = GridCoord(min(lo.x, c.x), c.y, min(lo.z, c.z))
                hi = GridCoord(max(hi.x, c.x), c.y, max(hi.z, c.z))
            }
        }
        var seen: Set<GridCoord> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let c = queue[head]
            head += 1
            for (dx, dz) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let n = GridCoord(c.x + dx, c.y, c.z + dz)
                guard !seen.contains(n), content[n] == target else { continue }
                if target == nil && blocked.contains(n) { continue }
                if n.x < lo.x || n.x > hi.x || n.z < lo.z || n.z > hi.z {
                    if target == nil { throw FillError.notEnclosed }
                    continue
                }
                seen.insert(n)
                queue.append(n)
                if queue.count > Self.maxCells { throw FillError.tooBig }
            }
        }
        return queue.sorted()
    }

    // MARK: Auto-joining

    /// Directions in quarter-turn order: a +90° turn about y takes each to the next.
    static let directions = [(1, 0), (0, -1), (-1, 0), (0, 1)]

    /// The variant and quarter turns for a neighbor mask (bit i: `directions[i]` has a neighbor).
    public static func joinShape(_ mask: Int) -> (variant: KeyPath<GridJoin, String>, turns: Int) {
        func rotated(_ m: Int, _ k: Int) -> Int {
            var out = 0
            for i in 0..<4 where m & (1 << i) != 0 { out |= 1 << ((i + k) % 4) }
            return out
        }
        let shapes: [(KeyPath<GridJoin, String>, Int)] = [(\.single, 0), (\.end, 0b0001), (\.straight, 0b0101), (\.corner, 0b1001),
                                                          (\.tee, 0b1101), (\.cross, 0b1111)]
        for (variant, canonical) in shapes {
            for k in 0..<4 where rotated(canonical, k) == mask & 0b1111 { return (variant, k) }
        }
        return (\.single, 0)
    }

    /// Every cell as the piece it draws: auto-joining pieces become their variants, flips are
    /// folded into turns. Cells whose piece is unknown or can't be drawn are left out and named in
    /// `warnings`.
    public func placements(warnings: inout [String]) -> [GridPlacement] {
        var occupant: [String: [GridCoord: String]] = [:]
        for cell in cells {
            let layer = layer(of: cell)
            for c in covered(by: cell) { occupant[layer, default: [:]][c] = cell.piece }
        }
        var out: [GridPlacement] = []
        var missing = Set<String>(), emptyVariants = Set<String>()
        for cell in cells {
            guard let index = pieceIndex(named: cell.piece) else {
                if missing.insert(cell.piece).inserted { warnings.append("no piece named '\(cell.piece)' in the library") }
                continue
            }
            let layer = layer(of: cell)
            let piece = pieces[index]
            guard let join = piece.join else {
                var turns = Self.quarterTurns(cell.rotation)
                if cell.flipZ { turns = (turns + 2) % 4 }
                out.append(GridPlacement(cell: cell, piece: index, turns: turns, mirrored: cell.flipX != cell.flipZ, layer: layer))
                continue
            }
            let friends = Set([piece.name] + join.variants + join.joinsWith)
            let n = piece.joinBlock
            var mask = 0
            for (i, side) in Self.blockSides(cell.at, size: n).enumerated()
            where side.contains(where: { occupant[layer]?[$0].map(friends.contains) == true }) {
                mask |= 1 << i
            }
            let (variant, turns) = Self.joinShape(mask)
            let name = join[keyPath: variant]
            let drawn = name.isEmpty ? index : pieceIndex(named: name)
            guard let drawn, !(pieces[drawn].asset.isEmpty) else {
                if emptyVariants.insert(piece.name + "/" + name).inserted {
                    warnings.append(name.isEmpty ? "auto piece '\(piece.name)' has no variant for this shape and no asset of its own"
                                                 : "auto piece '\(piece.name)': no drawable piece named '\(name)'")
                }
                continue
            }
            out.append(GridPlacement(cell: cell, piece: drawn, turns: turns, mirrored: false, layer: layer, block: n > 1 ? n : nil))
        }
        return out
    }

    /// The cells just outside each side of the `size` x `size` block anchored at `at`, in
    /// `directions` order (+x, -z, -x, +z): where an auto-joining piece looks for neighbors.
    static func blockSides(_ at: GridCoord, size: Int) -> [[GridCoord]] {
        let span = 0..<size
        return [span.map { GridCoord(at.x + size, at.y, at.z + $0) }, span.map { GridCoord(at.x + $0, at.y, at.z - 1) },
                span.map { GridCoord(at.x - 1, at.y, at.z + $0) }, span.map { GridCoord(at.x + $0, at.y, at.z + size) }]
    }

    /// `coords` snapped to whole footprints of `piece` turned by `rotation`, counted from the first
    /// coordinate, without repeats: a line or rectangle of a 2x2 piece puts pieces side by side
    /// instead of each one replacing the last. With `inside`, only footprints wholly within
    /// `coords` are kept (a fill stays inside its region). One-cell pieces come back unchanged.
    public func footprintSteps(_ coords: [GridCoord], piece name: String, rotation: Int, inside: Bool = false) -> [GridCoord] {
        guard let first = coords.first, let p = piece(named: name) else { return coords }
        let size = p.join != nil ? SIMD2(repeating: p.joinBlock) : p.cells
        let (w, d) = Self.quarterTurns(rotation) % 2 == 0 ? (size.x, size.y) : (size.y, size.x)
        guard w > 1 || d > 1 else { return coords }
        func floorDiv(_ a: Int, _ b: Int) -> Int { a >= 0 ? a / b : -((-a + b - 1) / b) }
        let all = inside ? Set(coords) : []
        var seen = Set<GridCoord>()
        var out: [GridCoord] = []
        for c in coords {
            let anchor = GridCoord(first.x + floorDiv(c.x - first.x, w) * w, c.y, first.z + floorDiv(c.z - first.z, d) * d)
            guard seen.insert(anchor).inserted else { continue }
            if inside, covered(by: p, at: anchor, turns: Self.quarterTurns(rotation)).contains(where: { !all.contains($0) }) { continue }
            out.append(anchor)
        }
        return out
    }

    /// The placement's transform in the map's space, before any mirroring of the model: the
    /// model is drawn with this transform after being mirrored across its x axis when
    /// `placement.mirrored` (see `GridMapImporter`).
    public func transform(of placement: GridPlacement) -> Transform {
        let piece = pieces[placement.piece]
        let center = footprintCenter(of: placement)
        let turn = Quat(angle: Float(placement.turns) * .pi / 2, axis: Vec3(0, 1, 0))
        let own = piece.rotation * .pi / 180
        // Mirroring x in the cell's frame reverses the model's own turn and the pivot's x.
        let offset = placement.mirrored ? Vec3(-piece.offset.x, piece.offset.y, piece.offset.z) : piece.offset
        let model = Quat(angle: placement.mirrored ? -own : own, axis: Vec3(0, 1, 0))
        return Transform(position: center + turn * offset, rotation: turn * model, scale: piece.scale)
    }

    /// The middle of the cells a placement covers, on its floor.
    public func footprintCenter(of placement: GridPlacement) -> Vec3 {
        let area = placement.block.map { n in
            [placement.cell.at, GridCoord(placement.cell.at.x + n - 1, placement.cell.at.y, placement.cell.at.z + n - 1)]
        } ?? covered(by: pieces[placement.piece], at: placement.cell.at, turns: placement.turns)
        let lo = area.first ?? placement.cell.at, hi = area.last ?? placement.cell.at
        let center = (origin(of: lo) + origin(of: hi) + Vec3(cell.x, 0, cell.z)) / 2
        return Vec3(center.x, origin(of: lo).y, center.z)
    }

    /// The piece's collision box at a placement: center and half extents in the map's space,
    /// and the turn.
    public func box(of placement: GridPlacement) -> (center: Vec3, halfExtent: Vec3, rotation: Quat) {
        let piece = pieces[placement.piece]
        let fp = placement.block.map { SIMD2(repeating: $0) } ?? piece.cells
        var size = piece.size
        if size.x <= 0 { size.x = Float(fp.x) * cell.x }
        if size.y <= 0 { size.y = cell.y }
        if size.z <= 0 { size.z = Float(fp.y) * cell.z }
        let turn = Quat(angle: Float(placement.turns) * .pi / 2, axis: Vec3(0, 1, 0))
        return (footprintCenter(of: placement) + Vec3(0, size.y / 2, 0), size / 2, turn)
    }

    /// The chunk (x, z) a placement's anchor falls in.
    public func chunk(of coord: GridCoord) -> SIMD2<Int> {
        let n = chunk
        func div(_ a: Int) -> Int { a >= 0 ? a / n : -((-a + n - 1) / n) }
        return SIMD2(div(coord.x), div(coord.z))
    }

    /// A stable 64-bit hash of a position and seed.
    static func hash(_ c: GridCoord, seed: Int) -> UInt64 {
        var h = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15
        for v in [c.x, c.y, c.z] {
            h ^= UInt64(bitPattern: Int64(v)) &+ 0x9E37_79B9_7F4A_7C15 &+ (h << 6) &+ (h >> 2)
            h = (h ^ (h >> 30)) &* 0xBF58_476D_1CE4_E5B9
            h = (h ^ (h >> 27)) &* 0x94D0_49BB_1331_11EB
            h ^= h >> 31
        }
        return h
    }

    // MARK: Starter library

    /// The mesh builds of the starter library, by file stem: a floor tile, wall variants for
    /// auto-joining (one cell thick, centered on the cell), a crate and a pillar, sized for `cellSize`.
    public static func starterBuilds(cellSize: Vec3 = Vec3(2, 3, 2)) -> [(name: String, build: MeshBuild)] {
        let c = Vec3(max(cellSize.x, 0.01), max(cellSize.y, 0.01), max(cellSize.z, 0.01))
        let t: Float = min(c.x, c.z) * 0.2, h = c.y
        let stone = Vec3(0.62, 0.6, 0.56), floor = Vec3(0.42, 0.4, 0.38)
        func post() -> MeshBuildPart { MeshBuildPart(name: "Post", position: Vec3(0, h / 2, 0), size: Vec3(t, h, t), color: stone) }
        func arm(_ name: String, _ dx: Float, _ dz: Float) -> MeshBuildPart {
            let lx = dx != 0 ? c.x / 2 : t, lz = dz != 0 ? c.z / 2 : t
            return MeshBuildPart(name: name, position: Vec3(dx * c.x / 4, h / 2, dz * c.z / 4), size: Vec3(lx, h, lz), color: stone)
        }
        let px = arm("East", 1, 0), nx = arm("West", -1, 0), pz = arm("South", 0, 1)
        return [
            ("Floor", MeshBuild(parts: [MeshBuildPart(name: "Tile", position: Vec3(0, -0.1, 0), size: Vec3(c.x, 0.2, c.z), color: floor,
                                                      roughness: 0.9)])),
            ("Wall Single", MeshBuild(parts: [post()])),
            ("Wall End", MeshBuild(parts: [post(), px])),
            ("Wall Straight", MeshBuild(parts: [MeshBuildPart(name: "Wall", position: Vec3(0, h / 2, 0), size: Vec3(c.x, h, t), color: stone)])),
            ("Wall Corner", MeshBuild(parts: [post(), px, pz])),
            ("Wall Tee", MeshBuild(parts: [post(), px, nx, pz])),
            ("Wall Cross", MeshBuild(parts: [post(), px, nx, pz, arm("North", 0, -1)])),
            ("Crate", MeshBuild(parts: [MeshBuildPart(name: "Crate", position: Vec3(0, c.x * 0.25, 0), size: Vec3(repeating: c.x * 0.5),
                                                      color: Vec3(0.55, 0.38, 0.2), roughness: 0.8)])),
            ("Pillar", MeshBuild(parts: [MeshBuildPart(name: "Pillar", shape: .cylinder, position: Vec3(0, h / 2, 0),
                                                       size: Vec3(c.x * 0.35, h, c.z * 0.35), color: stone)])),
        ]
    }

    /// The starter library's pieces for builds written to `folder` (as `starterBuilds` names them):
    /// the concrete pieces plus an auto-joining "Wall".
    public static func starterPieces(folder: String) -> [GridPiece] {
        func path(_ name: String) -> String { (folder.isEmpty ? "" : folder + "/") + name + ".meshbuild" }
        var pieces = [GridPiece(name: "Floor", asset: path("Floor"), size: Vec3(0, 0.2, 0), layer: "floor")]
        for v in ["Single", "End", "Straight", "Corner", "Tee", "Cross"] {
            pieces.append(GridPiece(name: "Wall " + v, asset: path("Wall " + v), layer: "walls"))
        }
        pieces.append(GridPiece(name: "Wall", layer: "walls", join: GridJoin(single: "Wall Single", end: "Wall End", straight: "Wall Straight",
                                                                             corner: "Wall Corner", tee: "Wall Tee", cross: "Wall Cross")))
        pieces.append(GridPiece(name: "Crate", asset: path("Crate"), layer: "props", collider: .box))
        pieces.append(GridPiece(name: "Pillar", asset: path("Pillar"), layer: "props"))
        return pieces
    }
}
