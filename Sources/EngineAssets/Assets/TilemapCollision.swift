import Foundation
import EngineCore
import EnginePhysics
import EngineScene

// Collision built from a tilemap's tiles: each colliding layer's tiles become as few
// `Collider2D` shapes as possible. Solid (`full`) tiles are merged into rectangles (greedy: the
// widest run, then as many rows down as fit); other rectangular shapes (`top`, `bottom`, one-way
// platforms) merge along their row; ramps and polygons stay one convex shape per tile.

/// One merged collision shape, in the map's world space (bottom-left corner at the origin).
public struct TilemapColliderShape: Equatable, Sendable {
    public var name: String
    /// Where the shape's origin sits (the box center; the cell center for polygons).
    public var position: Vec2
    public var shape: ColliderShape2D
    public var isOneWay: Bool
    /// The layer it came from.
    public var layer: String
    /// Cells it covers.
    public var cellCount: Int

    /// The `Collider2D` for it (static unless the entity gets a `RigidBody2D`).
    public var collider: Collider2D { Collider2D(shape, isOneWay: isOneWay) }
}

extension Tilemap {
    /// A rectangle within a cell in quarter-cell steps (0...4), y up.
    private struct QuarterRect: Hashable {
        var x0, y0, x1, y1: Int
        var oneWay: Bool
        var spansWidth: Bool { x0 == 0 && x1 == 4 }
        var isFull: Bool { x0 == 0 && y0 == 0 && x1 == 4 && y1 == 4 && !oneWay }
    }

    /// Every collision shape of the map's colliding layers (see the notes at the top of this file).
    public func collisionShapes() -> [TilemapColliderShape] {
        var map = self
        map.normalize()
        var shapes: [TilemapColliderShape] = []
        let size = cellSize
        let w = cols, h = rowCount
        var info: [Int: TilemapTile] = [:]
        for tile in tileset.tiles where tile.collision != .none { info[tile.index] = tile }
        guard !info.isEmpty else { return [] }

        for (li, layer) in map.layers.enumerated() where layer.collision {
            var rects = [QuarterRect?](repeating: nil, count: w * h)
            var polygons: [(x: Int, y: Int, points: [Vec2])] = []
            for y in 0..<h {
                for x in 0..<w {
                    let cell = map.cell(layer: li, x: x, y: y)
                    guard !cell.isEmpty, let tile = info[cell.tile] else { continue }
                    let placed = tile.collision.outline(points: tile.points).map { cell.place($0) }
                    guard placed.count >= 3 else { continue }
                    if tile.collision.isRectangle {
                        let xs = placed.map(\.x), ys = placed.map(\.y)
                        func q(_ v: Float) -> Int { Int((v * 4).rounded()) }
                        rects[y * w + x] = QuarterRect(x0: q(xs.min()!), y0: q(ys.min()!), x1: q(xs.max()!), y1: q(ys.max()!), oneWay: tile.oneWay)
                    } else {
                        polygons.append((x, y, placed))
                    }
                }
            }

            func box(_ x0: Int, _ yTop: Int, _ x1: Int, _ yBottom: Int, _ r: QuarterRect, cells: Int, name: String) {
                // Cells x0...x1 (left to right), yTop...yBottom (rows, top to bottom); r gives the part of each cell.
                let left = Float(x0) * size.x + Float(r.x0) / 4 * size.x
                let right = Float(x1) * size.x + Float(r.x1) / 4 * size.x
                let bottom = Float(h - 1 - yBottom) * size.y + Float(r.y0) / 4 * size.y
                let top = Float(h - 1 - yTop) * size.y + Float(r.y1) / 4 * size.y
                guard right > left, top > bottom else { return }
                shapes.append(TilemapColliderShape(
                    name: name, position: Vec2((left + right) / 2, (bottom + top) / 2),
                    shape: .box(halfExtents: Vec2((right - left) / 2, (top - bottom) / 2)), isOneWay: r.oneWay, layer: layer.name,
                    cellCount: cells))
            }

            // Solid tiles: greedy rectangles.
            var used = [Bool](repeating: false, count: w * h)
            func solid(_ x: Int, _ y: Int) -> Bool { !used[y * w + x] && rects[y * w + x]?.isFull == true }
            for y in 0..<h {
                var x = 0
                while x < w {
                    guard solid(x, y) else { x += 1; continue }
                    var x1 = x
                    while x1 + 1 < w && solid(x1 + 1, y) { x1 += 1 }
                    var y1 = y
                    while y1 + 1 < h && (x...x1).allSatisfy({ solid($0, y1 + 1) }) { y1 += 1 }
                    for yy in y...y1 { for xx in x...x1 { used[yy * w + xx] = true } }
                    box(x, y, x1, y1, QuarterRect(x0: 0, y0: 0, x1: 4, y1: 4, oneWay: false), cells: (x1 - x + 1) * (y1 - y + 1),
                        name: "\(layer.name) solid \(x)_\(y)")
                    x = x1 + 1
                }
            }

            // Other rectangles: runs along the row when they span the cell's width.
            for y in 0..<h {
                var x = 0
                while x < w {
                    guard !used[y * w + x], let r = rects[y * w + x] else { x += 1; continue }
                    var x1 = x
                    if r.spansWidth {
                        while x1 + 1 < w && !used[y * w + x1 + 1] && rects[y * w + x1 + 1] == r { x1 += 1 }
                    }
                    for xx in x...x1 { used[y * w + xx] = true }
                    box(x, y, x1, y, r, cells: x1 - x + 1, name: "\(layer.name) \(r.oneWay ? "platform" : "edge") \(x)_\(y)")
                    x = x1 + 1
                }
            }

            // Ramps and polygons: one convex shape per cell, around the cell's center.
            for p in polygons {
                let center = Vec2((Float(p.x) + 0.5) * size.x, (Float(h - 1 - p.y) + 0.5) * size.y)
                let points = p.points.map { Vec2(($0.x - 0.5) * size.x, ($0.y - 0.5) * size.y) }
                let oneWay = info[map.cell(layer: li, x: p.x, y: p.y).tile]?.oneWay ?? false
                shapes.append(TilemapColliderShape(name: "\(layer.name) shape \(p.x)_\(p.y)", position: center,
                                                   shape: .polygon(points: points), isOneWay: oneWay, layer: layer.name, cellCount: 1))
            }
        }
        return shapes
    }
}

extension World {
    /// Spawns one static `Collider2D` entity per collision shape of `map`, with the map's
    /// bottom-left corner at `origin`. 2D physics reads each collider entity's own `Transform`
    /// (parents are ignored), so use this when the map isn't placed at the world origin.
    @MainActor @discardableResult
    public func spawnTilemapColliders(_ map: Tilemap, at origin: Vec2 = .zero) -> [Entity] {
        map.collisionShapes().map { shape in
            spawn(Transform(position: Vec3(origin.x + shape.position.x, origin.y + shape.position.y, 0)), Name(shape.name), shape.collider)
        }
    }
}
