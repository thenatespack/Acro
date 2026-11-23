import Foundation
import EngineCore
import EnginePhysics
import EngineScene

// Navigation: a walkable grid baked from the scene's static colliders, and A* paths on it.
//
// - `NavigationGrid` covers an XZ area with square cells. Each cell has the height of the
//   ground under it (the topmost static surface a ray straight down hits) and is walkable when
//   that ground isn't steeper than `maxSlope`, nothing static stands in the agent's way above
//   it (a box `agentRadius` wider than the cell, from `stepHeight` to `agentHeight` over the
//   ground), and no drop or wall (a height jump bigger than `stepHeight` plus the slope
//   allows) is closer than `agentRadius`. Neighbouring walkable cells connect (8 ways, no
//   corner cutting) when their heights differ by at most `stepHeight`.
// - `findPath(from:to:)` runs A* (octile distance) between the cells under the two points,
//   then pulls the string: waypoints are dropped while the straight line between the ones
//   kept crosses only connected walkable cells. Points off the grid or on blocked cells snap
//   to the nearest walkable cell (a goal on walkable ground the start can't reach has no
//   path). `partial: true` returns a path to the reachable cell nearest the goal instead.
// - Baking reads a `PhysicsWorld` (`NavigationGrid.bake`). `World.bakeNavigation()` builds
//   a temporary one from the world's `Collider`s (static ones: no `RigidBody`, or a static
//   one; never a `CharacterController` or a `BehaviorTreeRunner` entity) over the
//   `NavigationArea` entity's box, or around the static colliders near the agents when there
//   is none, and keeps the grid for `World.findPath`. The behavior tree system bakes one the
//   first time a tree walks somewhere in a world with colliders, and its move / patrol / chase
//   / flee leaves follow paths on it (straight-line steering when there is no grid or no path).
//
// One walkable layer per cell: a bridge or a table hides the ground under it, and floors
// stacked above one another aren't supported. Moving obstacles aren't baked; rebake with
// `bakeNavigation()` after the static level changes.

/// What a navigation bake assumes about the agents and how fine its grid is.
public struct NavigationSettings: Codable, Equatable, Sendable {
    /// Cell edge in meters.
    public var cellSize: Float
    /// Agents keep this far from walls and drops.
    public var agentRadius: Float
    /// Space an agent needs above the ground.
    public var agentHeight: Float
    /// Highest step between neighbouring cells an agent walks up or down.
    public var stepHeight: Float
    /// Steepest walkable ground, in degrees.
    public var maxSlope: Float
    /// At most this many cells; a bigger area gets bigger cells.
    public var maxCells: Int

    public init(cellSize: Float = 0.5, agentRadius: Float = 0.4, agentHeight: Float = 1.8, stepHeight: Float = 0.4,
                maxSlope: Float = 45, maxCells: Int = 250_000) {
        self.cellSize = cellSize
        self.agentRadius = agentRadius
        self.agentHeight = agentHeight
        self.stepHeight = stepHeight
        self.maxSlope = maxSlope
        self.maxCells = maxCells
    }

    private enum CodingKeys: String, CodingKey { case cellSize, agentRadius, agentHeight, stepHeight, maxSlope, maxCells }

    public init(from decoder: any Decoder) throws {
        let d = NavigationSettings()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cellSize = try c.decodeIfPresent(Float.self, forKey: .cellSize) ?? d.cellSize
        agentRadius = try c.decodeIfPresent(Float.self, forKey: .agentRadius) ?? d.agentRadius
        agentHeight = try c.decodeIfPresent(Float.self, forKey: .agentHeight) ?? d.agentHeight
        stepHeight = try c.decodeIfPresent(Float.self, forKey: .stepHeight) ?? d.stepHeight
        maxSlope = try c.decodeIfPresent(Float.self, forKey: .maxSlope) ?? d.maxSlope
        maxCells = try c.decodeIfPresent(Int.self, forKey: .maxCells) ?? d.maxCells
    }
}

/// Marks the box a navigation bake covers (centered on the entity, `size` in meters) and the
/// agent it bakes for. Without one, bakes cover the static colliders around the agents.
public struct NavigationArea: Component, Codable, Equatable, Sendable {
    public static let componentName = "NavigationArea"
    public static var fieldHints: [String: FieldHints] {
        ["size": FieldHints(tooltip: "Width, height and depth of the baked box, centered on the entity (0 on an axis: the static colliders' extent)"),
         "cellSize": FieldHints(range: 0.1...4, step: 0.05, tooltip: "Grid cell edge in meters (smaller: finer paths, slower bake)"),
         "agentRadius": FieldHints(range: 0...4, step: 0.05, tooltip: "Agents keep this far from walls and drops"),
         "agentHeight": FieldHints(range: 0.2...6, step: 0.05, tooltip: "Space an agent needs above the ground"),
         "stepHeight": FieldHints(range: 0...2, step: 0.05, tooltip: "Highest step an agent walks up or down"),
         "maxSlope": FieldHints(range: 0...89, step: 1, tooltip: "Steepest walkable ground in degrees")]
    }

    public var size: Vec3
    public var cellSize: Float
    public var agentRadius: Float
    public var agentHeight: Float
    public var stepHeight: Float
    public var maxSlope: Float

    public init(size: Vec3 = Vec3(40, 20, 40), settings: NavigationSettings = NavigationSettings()) {
        self.size = size
        cellSize = settings.cellSize
        agentRadius = settings.agentRadius
        agentHeight = settings.agentHeight
        stepHeight = settings.stepHeight
        maxSlope = settings.maxSlope
    }

    public var settings: NavigationSettings {
        NavigationSettings(cellSize: cellSize, agentRadius: agentRadius, agentHeight: agentHeight, stepHeight: stepHeight, maxSlope: maxSlope)
    }

    private enum CodingKeys: String, CodingKey { case size, cellSize, agentRadius, agentHeight, stepHeight, maxSlope }

    public init(from decoder: any Decoder) throws {
        let d = NavigationSettings()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        size = try c.decodeIfPresent(Vec3.self, forKey: .size) ?? Vec3(40, 20, 40)
        cellSize = try c.decodeIfPresent(Float.self, forKey: .cellSize) ?? d.cellSize
        agentRadius = try c.decodeIfPresent(Float.self, forKey: .agentRadius) ?? d.agentRadius
        agentHeight = try c.decodeIfPresent(Float.self, forKey: .agentHeight) ?? d.agentHeight
        stepHeight = try c.decodeIfPresent(Float.self, forKey: .stepHeight) ?? d.stepHeight
        maxSlope = try c.decodeIfPresent(Float.self, forKey: .maxSlope) ?? d.maxSlope
    }
}

/// A baked walkable grid on the XZ plane (see the notes at the top of Navigation.swift).
public struct NavigationGrid: Equatable, Sendable {
    /// The corner of cell (0, 0) with the smallest x and z (y unused).
    public let origin: Vec3
    public let cellSize: Float
    /// Cells along x and z.
    public let width: Int, depth: Int
    /// Ground height per cell, row by row along x (`.nan`: no ground).
    public let heights: [Float]
    public let walkable: [Bool]
    public let settings: NavigationSettings
    /// Connected area per cell (-1: blocked); cells with the same id reach each other.
    public let regions: [Int32]
    public let regionCount: Int

    public init(origin: Vec3, cellSize: Float, width: Int, depth: Int, heights: [Float], walkable: [Bool],
                settings: NavigationSettings = NavigationSettings()) {
        precondition(heights.count == width * depth && walkable.count == width * depth, "NavigationGrid: one height and flag per cell")
        self.origin = origin
        self.cellSize = cellSize
        self.width = width
        self.depth = depth
        self.heights = heights
        self.walkable = walkable
        self.settings = settings
        var regions = [Int32](repeating: -1, count: width * depth)
        var count: Int32 = 0
        var stack: [Int] = []
        for start in 0..<(width * depth) where walkable[start] && regions[start] < 0 {
            regions[start] = count
            stack.append(start)
            while let i = stack.popLast() {
                Self.forEachNeighbour(i, width: width, depth: depth, walkable: walkable, heights: heights, step: settings.stepHeight) { n, _ in
                    if regions[n] < 0 {
                        regions[n] = count
                        stack.append(n)
                    }
                }
            }
            count += 1
        }
        self.regions = regions
        regionCount = Int(count)
    }

    public var cellCount: Int { width * depth }
    public var walkableCount: Int { walkable.reduce(0) { $0 + ($1 ? 1 : 0) } }

    /// The grid's extent (y: the lowest and highest ground).
    public var bounds: AABB {
        let ys = heights.filter { !$0.isNaN }
        return AABB(min: Vec3(origin.x, ys.min() ?? 0, origin.z),
                    max: Vec3(origin.x + Float(width) * cellSize, ys.max() ?? 0, origin.z + Float(depth) * cellSize))
    }

    // MARK: Cells

    /// The cell under `point` (nil off the grid).
    public func cell(at point: Vec3) -> (x: Int, z: Int)? {
        let x = Int(((point.x - origin.x) / cellSize).rounded(.down))
        let z = Int(((point.z - origin.z) / cellSize).rounded(.down))
        guard x >= 0, z >= 0, x < width, z < depth else { return nil }
        return (x, z)
    }

    /// The middle of a cell, on its ground (y 0 without ground).
    public func center(x: Int, z: Int) -> Vec3 {
        let h = heights[z * width + x]
        return Vec3(origin.x + (Float(x) + 0.5) * cellSize, h.isNaN ? 0 : h, origin.z + (Float(z) + 0.5) * cellSize)
    }

    func center(_ i: Int) -> Vec3 { center(x: i % width, z: i / width) }

    public func isWalkable(x: Int, z: Int) -> Bool {
        x >= 0 && z >= 0 && x < width && z < depth && walkable[z * width + x]
    }

    /// Whether the cell under `point` is walkable.
    public func isWalkable(_ point: Vec3) -> Bool { cell(at: point).map { walkable[$0.z * width + $0.x] } ?? false }

    /// The ground height under `point` (nil off the grid or without ground).
    public func height(at point: Vec3) -> Float? {
        guard let c = cell(at: point) else { return nil }
        let h = heights[c.z * width + c.x]
        return h.isNaN ? nil : h
    }

    /// Calls `body` with each connected neighbour of cell `i` and the step length (1 or √2).
    static func forEachNeighbour(_ i: Int, width: Int, depth: Int, walkable: [Bool], heights: [Float], step: Float,
                                 _ body: (Int, Float) -> Void) {
        let x = i % width, z = i / width
        let h = heights[i]
        func open(_ nx: Int, _ nz: Int) -> Bool {
            guard nx >= 0, nz >= 0, nx < width, nz < depth else { return false }
            let n = nz * width + nx
            return walkable[n] && abs(heights[n] - h) <= step
        }
        let east = open(x + 1, z), west = open(x - 1, z), north = open(x, z + 1), south = open(x, z - 1)
        if east { body(i + 1, 1) }
        if west { body(i - 1, 1) }
        if north { body(i + width, 1) }
        if south { body(i - width, 1) }
        let diagonal: Float = Float(2).squareRoot()
        if east, north, open(x + 1, z + 1) { body(i + width + 1, diagonal) }
        if west, north, open(x - 1, z + 1) { body(i + width - 1, diagonal) }
        if east, south, open(x + 1, z - 1) { body(i - width + 1, diagonal) }
        if west, south, open(x - 1, z - 1) { body(i - width - 1, diagonal) }
    }

    /// The walkable cell nearest `point` within `maxDistance` meters (nil: none), by index.
    func nearestWalkableCell(to point: Vec3, maxDistance: Float, region: Int32? = nil) -> Int? {
        let fx = (point.x - origin.x) / cellSize - 0.5, fz = (point.z - origin.z) / cellSize - 0.5
        let cx = Int(fx.rounded()), cz = Int(fz.rounded())
        let maxRing = Int((maxDistance / cellSize).rounded(.up)) + 1
        var best: (i: Int, d: Float)?
        for ring in 0...maxRing {
            // Cells on the square ring at Chebyshev distance `ring` around (cx, cz).
            for dz in -ring...ring {
                let edge = abs(dz) == ring
                var dx = -ring
                while dx <= ring {
                    let x = cx + dx, z = cz + dz
                    if x >= 0, z >= 0, x < width, z < depth {
                        let i = z * width + x
                        if walkable[i], region.map({ regions[i] == $0 }) ?? true {
                            let d = ((Float(x) - fx) * (Float(x) - fx) + (Float(z) - fz) * (Float(z) - fz)).squareRoot() * cellSize
                            if d <= maxDistance + cellSize, best == nil || d < best!.d { best = (i, d) }
                        }
                    }
                    dx += edge ? 1 : 2 * ring
                    if ring == 0 { break }
                }
            }
            // A cell on a later ring is at least (ring) cells away: stop once that can't win.
            if let best, best.d < Float(ring) * cellSize { return best.i }
        }
        return best?.i
    }

    /// The walkable point nearest `point` (its cell's middle, or `point` itself when its cell
    /// is walkable) within `maxDistance` meters.
    public func nearestWalkablePoint(to point: Vec3, maxDistance: Float = 3) -> Vec3? {
        if let c = cell(at: point), walkable[c.z * width + c.x] { return Vec3(point.x, heights[c.z * width + c.x], point.z) }
        return nearestWalkableCell(to: point, maxDistance: maxDistance).map(center)
    }

    /// Whether `a` and `b` are on the same connected walkable area.
    public func areConnected(_ a: Vec3, _ b: Vec3) -> Bool {
        guard let ca = cell(at: a), let cb = cell(at: b) else { return false }
        let ra = regions[ca.z * width + ca.x], rb = regions[cb.z * width + cb.x]
        return ra >= 0 && ra == rb
    }

    // MARK: Paths

    /// Whether an agent can walk the straight line from `a` to `b`: every cell it crosses is
    /// walkable and connected to the one before (both ends must be on the grid).
    public func isClear(from a: Vec3, to b: Vec3) -> Bool {
        guard var c = cell(at: a), let end = cell(at: b), walkable[c.z * width + c.x] else { return false }
        let fx = (a.x - origin.x) / cellSize, fz = (a.z - origin.z) / cellSize
        let dx = (b.x - a.x) / cellSize, dz = (b.z - a.z) / cellSize
        let stepX = dx > 0 ? 1 : -1, stepZ = dz > 0 ? 1 : -1
        let tDeltaX = dx != 0 ? abs(1 / dx) : .infinity, tDeltaZ = dz != 0 ? abs(1 / dz) : .infinity
        var tMaxX = dx != 0 ? (dx > 0 ? (Float(c.x + 1) - fx) : (fx - Float(c.x))) * tDeltaX : .infinity
        var tMaxZ = dz != 0 ? (dz > 0 ? (Float(c.z + 1) - fz) : (fz - Float(c.z))) * tDeltaZ : .infinity
        let step = settings.stepHeight
        func passable(from i: Int, to x: Int, _ z: Int) -> Bool {
            guard x >= 0, z >= 0, x < width, z < depth else { return false }
            let n = z * width + x
            return walkable[n] && abs(heights[n] - heights[i]) <= step
        }
        var guardCount = width + depth + 4
        // Walk the cells the segment crosses until the next crossing is past its end.
        while min(tMaxX, tMaxZ) < 1 - 1e-5, guardCount > 0 {
            guardCount -= 1
            let i = c.z * width + c.x
            if abs(tMaxX - tMaxZ) < 1e-5 {
                // Through a corner: both side cells must be open too.
                guard passable(from: i, to: c.x + stepX, c.z), passable(from: i, to: c.x, c.z + stepZ),
                      passable(from: i, to: c.x + stepX, c.z + stepZ) else { return false }
                c = (c.x + stepX, c.z + stepZ)
                tMaxX += tDeltaX
                tMaxZ += tDeltaZ
            } else if tMaxX < tMaxZ {
                guard passable(from: i, to: c.x + stepX, c.z) else { return false }
                c.x += stepX
                tMaxX += tDeltaX
            } else {
                guard passable(from: i, to: c.x, c.z + stepZ) else { return false }
                c.z += stepZ
                tMaxZ += tDeltaZ
            }
        }
        if (c.x, c.z) == (end.x, end.z) { return true }
        // An end exactly on a cell edge or corner: the step into its cell must be open too.
        let ex = end.x - c.x, ez = end.z - c.z
        guard abs(ex) <= 1, abs(ez) <= 1 else { return false }
        let i = c.z * width + c.x
        if ex != 0, ez != 0, !(passable(from: i, to: c.x + ex, c.z) && passable(from: i, to: c.x, c.z + ez)) { return false }
        return passable(from: i, to: end.x, end.z)
    }

    /// A walkable path from `start` to `goal`: points on the ground, `start` (snapped onto the
    /// grid) first and `goal` (or the nearest walkable point) last, with the corners in between.
    /// nil when either end is far from walkable ground or the goal can't be reached (with
    /// `partial`, the path ends at the reachable cell nearest the goal instead).
    public func findPath(from start: Vec3, to goal: Vec3, partial: Bool = false, snapDistance: Float = 3) -> [Vec3]? {
        guard let s = nearestWalkableCell(to: start, maxDistance: snapDistance) else { return nil }
        let region = regions[s]
        let startPoint = isWalkable(start) && cell(at: start).map({ $0.z * width + $0.x }) == s ? start : center(s)
        var goalPoint = goal
        var g: Int
        if let c = cell(at: goal), walkable[c.z * width + c.x], regions[c.z * width + c.x] == region {
            g = c.z * width + c.x
        } else if !partial, let c = cell(at: goal), walkable[c.z * width + c.x] {
            return nil  // walkable but not connected to the start
        } else if let near = nearestWalkableCell(to: goal, maxDistance: snapDistance, region: region) {
            g = near
            goalPoint = center(near)
        } else if partial, let near = nearestWalkableCell(to: goal, maxDistance: Float(width + depth) * cellSize, region: region) {
            g = near
            goalPoint = center(near)
        } else {
            return nil
        }
        if g == s { return [Vec3(startPoint.x, heights[s], startPoint.z), Vec3(goalPoint.x, heights[g], goalPoint.z)] }
        guard let cells = aStar(from: s, to: g) else { return nil }
        var points = cells.map(center)
        points[0] = Vec3(startPoint.x, heights[s], startPoint.z)
        points[points.count - 1] = Vec3(goalPoint.x, heights[g], goalPoint.z)
        return smooth(points)
    }

    /// Cell indices from `s` to `g` (same region), nil if none.
    func aStar(from s: Int, to g: Int) -> [Int]? {
        let count = width * depth
        var cost = [Float](repeating: .infinity, count: count)
        var came = [Int32](repeating: -1, count: count)
        var closed = [Bool](repeating: false, count: count)
        let gx = Float(g % width), gz = Float(g / width)
        func h(_ i: Int) -> Float {
            let dx = abs(Float(i % width) - gx), dz = abs(Float(i / width) - gz)
            return max(dx, dz) + (Float(2).squareRoot() - 1) * min(dx, dz)
        }
        var heap = NavigationHeap()
        cost[s] = 0
        heap.push(h(s), s)
        while let (_, i) = heap.pop() {
            if i == g {
                var path = [g]
                var k = g
                while came[k] >= 0 { k = Int(came[k]); path.append(k) }
                return path.reversed()
            }
            if closed[i] { continue }
            closed[i] = true
            Self.forEachNeighbour(i, width: width, depth: depth, walkable: walkable, heights: heights, step: settings.stepHeight) { n, length in
                guard !closed[n] else { return }
                let c = cost[i] + length
                if c < cost[n] {
                    cost[n] = c
                    came[n] = Int32(i)
                    heap.push(c + h(n), n)
                }
            }
        }
        return nil
    }

    /// Drops the points a straight walk can skip.
    func smooth(_ points: [Vec3]) -> [Vec3] {
        guard points.count > 2 else { return points }
        var result = [points[0]]
        var anchor = 0
        while anchor < points.count - 1 {
            var next = anchor + 1
            var j = points.count - 1
            while j > anchor + 1 {
                if isClear(from: points[anchor], to: points[j]) { next = j; break }
                j -= 1
            }
            result.append(points[next])
            anchor = next
        }
        return result
    }

    /// The length of a path along its points (XZ plus height).
    public static func length(of path: [Vec3]) -> Float {
        zip(path, path.dropFirst()).reduce(0) { $0 + EngineCore.length($1.1 - $1.0) }
    }
}

/// A binary min-heap of (priority, cell) for A*.
struct NavigationHeap {
    private var items: [(Float, Int)] = []

    mutating func push(_ priority: Float, _ value: Int) {
        items.append((priority, value))
        var i = items.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard items[i].0 < items[parent].0 else { break }
            items.swapAt(i, parent)
            i = parent
        }
    }

    mutating func pop() -> (Float, Int)? {
        guard let top = items.first else { return nil }
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var i = 0
            while true {
                let l = 2 * i + 1, r = l + 1
                var m = i
                if l < items.count, items[l].0 < items[m].0 { m = l }
                if r < items.count, items[r].0 < items[m].0 { m = r }
                if m == i { break }
                items.swapAt(i, m)
                i = m
            }
        }
        return top
    }
}

// MARK: Baking

extension NavigationGrid {
    /// Bakes the area `bounds` (x and z; y: how far up and down the ground is searched) from
    /// `physics`. `isObstacle(body)` says which bodies count (default: static ones).
    @MainActor
    public static func bake(physics: PhysicsWorld, bounds: AABB, settings: NavigationSettings = NavigationSettings(),
                            isObstacle: ((BodyID) -> Bool)? = nil) -> NavigationGrid {
        let accepts = isObstacle ?? { physics.motion(of: $0) == .static }
        var cell = max(settings.cellSize, 0.05)
        let sizeX = max(bounds.max.x - bounds.min.x, cell), sizeZ = max(bounds.max.z - bounds.min.z, cell)
        let maxCells = max(settings.maxCells, 16)
        if Float(sizeX / cell) * Float(sizeZ / cell) > Float(maxCells) { cell = (sizeX * sizeZ / Float(maxCells)).squareRoot() }
        let width = max(Int((sizeX / cell).rounded(.up)), 1), depth = max(Int((sizeZ / cell).rounded(.up)), 1)
        let origin = Vec3(bounds.min.x, bounds.min.y, bounds.min.z)
        let top = bounds.max.y + 0.5
        let span = top - bounds.min.y + 0.5
        let minNormalY = cos(min(max(settings.maxSlope, 0), 89.9) * .pi / 180)
        let clearance = max(settings.agentHeight - settings.stepHeight, 0.05)
        let half = Vec3(cell / 2 + settings.agentRadius, clearance / 2, cell / 2 + settings.agentRadius)
        var heights = [Float](repeating: .nan, count: width * depth)
        var ground = [Bool](repeating: false, count: width * depth)
        var blocked = [Bool](repeating: false, count: width * depth)
        for z in 0..<depth {
            for x in 0..<width {
                let i = z * width + x
                let cx = origin.x + (Float(x) + 0.5) * cell, cz = origin.z + (Float(z) + 0.5) * cell
                let hits = physics.raycastAll(Ray(origin: Vec3(cx, top, cz), direction: Vec3(0, -1, 0)), maxDistance: span)
                guard let hit = hits.first(where: { accepts($0.body) }) else { continue }
                heights[i] = hit.point.y
                guard hit.normal.y >= minNormalY else { continue }
                ground[i] = true
                let center = Vec3(cx, hit.point.y + settings.stepHeight + clearance / 2, cz)
                if physics.overlapBox(center: center, halfExtents: half).contains(where: { $0 != hit.body && accepts($0) }) {
                    blocked[i] = true
                }
            }
        }
        // Keep agentRadius away from drops, walls of the ground itself and missing ground.
        let reach = Int((settings.agentRadius / cell).rounded(.up))
        let slope = tan(min(max(settings.maxSlope, 0), 89) * .pi / 180)
        var walkable = [Bool](repeating: false, count: width * depth)
        for z in 0..<depth {
            for x in 0..<width {
                let i = z * width + x
                guard ground[i], !blocked[i] else { continue }
                var ok = true
                if reach > 0 {
                    search: for dz in -reach...reach {
                        for dx in -reach...reach where dx != 0 || dz != 0 {
                            let d = (Float(dx * dx + dz * dz)).squareRoot() * cell
                            guard d - cell * 0.5 <= settings.agentRadius else { continue }
                            let nx = x + dx, nz = z + dz
                            guard nx >= 0, nz >= 0, nx < width, nz < depth else { continue }  // the area's edge isn't a wall
                            let n = nz * width + nx
                            if !ground[n] || abs(heights[n] - heights[i]) > settings.stepHeight + d * slope { ok = false; break search }
                        }
                    }
                }
                walkable[i] = ok
            }
        }
        var used = settings
        used.cellSize = cell
        return NavigationGrid(origin: origin, cellSize: cell, width: width, depth: depth, heights: heights, walkable: walkable, settings: used)
    }
}

// MARK: World

/// The grid each world keeps for `World.findPath` (worlds are main-actor objects, so a table
/// keyed by identity, checked against a weak reference, stands in for a stored property).
@MainActor
enum NavigationStore {
    final class Entry {
        weak var world: World?
        var grid: NavigationGrid
        /// Baked by the behavior tree system (rebaked the next time the system is added).
        var automatic: Bool

        init(world: World, grid: NavigationGrid, automatic: Bool) {
            self.world = world
            self.grid = grid
            self.automatic = automatic
        }
    }

    static var entries: [ObjectIdentifier: Entry] = [:]

    static func entry(_ world: World) -> Entry? {
        guard let entry = entries[ObjectIdentifier(world)] else { return nil }
        guard entry.world === world else { entries[ObjectIdentifier(world)] = nil; return nil }
        return entry
    }

    static func set(_ grid: NavigationGrid?, for world: World, automatic: Bool) {
        entries = entries.filter { $0.value.world != nil }
        if let grid { entries[ObjectIdentifier(world)] = Entry(world: world, grid: grid, automatic: automatic) }
        else { entries[ObjectIdentifier(world)] = nil }
    }
}

extension World {
    /// The navigation grid `findPath` uses (nil until one is baked or set).
    public var navigation: NavigationGrid? {
        get { NavigationStore.entry(self)?.grid }
        set { NavigationStore.set(newValue, for: self, automatic: false) }
    }

    /// Whether the behavior tree system baked `navigation` itself (it rebakes when added again).
    var navigationIsAutomatic: Bool { NavigationStore.entry(self)?.automatic ?? false }

    /// Whether `entity` is something a bake treats as a moving agent rather than level geometry.
    func isNavigationAgent(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if has(CharacterController.self, for: e) || has(BehaviorTreeRunner.self, for: e) { return true }
            if let body = get(RigidBody.self, for: e), body.motion != .static { return true }
            current = parent(of: e)
        }
        return false
    }

    /// The area a bake covers: the `NavigationArea` entity's box, else the static colliders'
    /// extent (limited to 40 m around the agents when there are any). nil without colliders.
    func navigationBounds(physics: PhysicsWorld, accepts: (BodyID) -> Bool) -> (bounds: AABB, settings: NavigationSettings)? {
        var statics: AABB?
        for body in physics.bodyIDs where accepts(body) {
            guard let b = physics.bounds(of: body) else { continue }
            statics = statics.map { $0.union(b) } ?? b
        }
        var areaEntity: Entity?
        query(NavigationArea.self) { e, _ in if areaEntity == nil { areaEntity = e } }
        if let e = areaEntity, let area = get(NavigationArea.self, for: e) {
            let center = worldMatrix(of: e).c3
            let c = Vec3(center.x, center.y, center.z)
            var lo = c - area.size / 2, hi = c + area.size / 2
            for axis in 0..<3 where area.size[axis] <= 0 {
                lo[axis] = statics?.min[axis] ?? c[axis]
                hi[axis] = statics?.max[axis] ?? c[axis]
            }
            return (AABB(min: lo, max: hi), area.settings)
        }
        guard var bounds = statics else { return nil }
        var agents: AABB?
        var runners: [Entity] = []
        query(BehaviorTreeRunner.self) { e, _ in runners.append(e) }
        for e in runners {
            let p4 = worldMatrix(of: e).c3
            let p = Vec3(p4.x, p4.y, p4.z)
            let box = AABB(min: p, max: p)
            agents = agents.map { $0.union(box) } ?? box
        }
        if let agents {
            let near = agents.expanded(by: 40)
            let lo = pointwiseMax(bounds.min, near.min), hi = pointwiseMin(bounds.max, near.max)
            if lo.x < hi.x, lo.z < hi.z { bounds = AABB(min: Vec3(lo.x, bounds.min.y, lo.z), max: Vec3(hi.x, bounds.max.y, hi.z)) }
        }
        return (bounds, NavigationSettings())
    }

    /// Bakes a navigation grid from this world's static colliders (see the notes at the top of
    /// Navigation.swift) and keeps it as `navigation`. `physics` defaults to a temporary
    /// physics world built from the `Collider` components; `settings` and `bounds` default to
    /// the `NavigationArea` entity's, else defaults around the static colliders near the
    /// agents. nil (and `navigation` unchanged) when there is nothing to bake.
    @discardableResult
    public func bakeNavigation(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil) -> NavigationGrid? {
        guard let grid = makeNavigation(physics: physics, settings: settings, bounds: bounds) else { return nil }
        navigation = grid
        return grid
    }

    /// A baked grid without keeping it (what `bakeNavigation` bakes).
    public func makeNavigation(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil) -> NavigationGrid? {
        let world: PhysicsWorld
        if let physics { world = physics } else {
            guard count(of: Collider.self) > 0 else { return nil }
            PhysicsWorld.registerComponents()
            propagateTransforms()
            world = PhysicsWorld()
            world.syncFromWorld(self, dt: 0)
        }
        let accepts: (BodyID) -> Bool = { body in
            guard world.motion(of: body) == .static else { return false }
            if let e = world.entity(of: body), self.isAlive(e), self.isNavigationAgent(e) { return false }
            return true
        }
        guard let found = navigationBounds(physics: world, accepts: accepts) ?? bounds.map({ ($0, NavigationSettings()) }) else { return nil }
        let area = bounds ?? found.bounds
        return NavigationGrid.bake(physics: world, bounds: area, settings: settings ?? found.settings, isObstacle: accepts)
    }

    /// A walkable path between two world points on `navigation` (see `NavigationGrid.findPath`);
    /// nil without a grid or a path.
    public func findPath(from start: Vec3, to goal: Vec3, partial: Bool = false) -> [Vec3]? {
        navigation?.findPath(from: start, to: goal, partial: partial)
    }
}
