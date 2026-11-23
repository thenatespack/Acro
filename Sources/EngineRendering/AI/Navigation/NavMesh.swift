import Foundation
import EngineCore
import EnginePhysics

// A baked navigation mesh: convex walkable polygons (several floors, ramps and bridges stack
// fine), the portals between them, off-mesh links (jumps, drops, ladders) and per-polygon
// detail heights. Baked by NavMeshBake.swift; queried here:
//
// - `locate(_:)` finds the polygon under a point (the one whose surface is nearest in height,
//   so a point on a bridge finds the bridge, not the ground under it).
// - `findPath(from:to:)` / `navigationPath(from:to:)` run A* over the polygons (portal
//   midpoints, off-mesh links with their cost), then pull the string through the portals
//   (the funnel algorithm), one walking stretch at a time between links. Heights come from the
//   detail samples; a point is added where the path bends over a slope change (the foot of a
//   ramp), so straight segments between points stay on the surface.
// - `isClear(from:to:)` walks a straight line across polygons (no wall in between);
//   `move(from:to:)` slides a step along the surface, stopping and sliding at walls (crowd
//   agents stay on the mesh).
//
// Coordinates are world space. "Left" and "right" of a portal are seen walking through it.

/// What kind of off-mesh link a path segment uses (`.walk`: ordinary ground).
public enum NavigationLinkKind: String, Codable, CaseIterable, Sendable {
    case walk, jump, drop, ladder
}

/// A path from a navigation query: points from start to goal, and how each segment between
/// them is crossed (`segments[i]` is from `points[i]` to `points[i + 1]`).
public struct NavigationPath: Equatable, Sendable {
    public var points: [Vec3]
    public var segments: [NavigationLinkKind]

    public init(points: [Vec3], segments: [NavigationLinkKind]? = nil) {
        self.points = points
        self.segments = segments ?? Array(repeating: .walk, count: max(points.count - 1, 0))
    }

    /// Meters along the points.
    public var length: Float { NavigationGrid.length(of: points) }
}

/// What agents walk on: a baked `NavMesh` or the older `NavigationGrid`. Behavior trees and
/// `World.findPath` take whichever the world has (the navmesh first).
public protocol NavigationSurface: Sendable {
    /// The size of the bake's smallest feature (a grid cell, a navmesh voxel), in meters.
    var resolution: Float { get }
    /// A walkable path (see `NavMesh.findPath`); nil when there is none.
    func navigationPath(from start: Vec3, to goal: Vec3, partial: Bool) -> NavigationPath?
    /// The walkable point nearest `point` within `maxDistance` meters.
    func nearestWalkablePoint(to point: Vec3, maxDistance: Float) -> Vec3?
    /// Whether an agent at `a` can walk to `b` at all.
    func areConnected(_ a: Vec3, _ b: Vec3) -> Bool
    /// Whether the straight line from `a` to `b` is walkable.
    func isClear(from a: Vec3, to b: Vec3) -> Bool
}

extension NavigationGrid: NavigationSurface {
    public var resolution: Float { cellSize }
    public func navigationPath(from start: Vec3, to goal: Vec3, partial: Bool) -> NavigationPath? {
        findPath(from: start, to: goal, partial: partial).map { NavigationPath(points: $0) }
    }
}

/// A portal from one polygon into a neighbour, or the start of an off-mesh link.
public struct NavMeshLink: Codable, Equatable, Sendable {
    /// The polygon it leads to.
    public var polygon: Int32
    /// The portal's ends, seen walking from the owning polygon into `polygon` (equal for an
    /// off-mesh link: its start).
    public var left: Vec3
    public var right: Vec3
    /// The owning polygon's edge it lies on (-1 for an off-mesh link).
    public var edge: Int32
    /// The off-mesh link it uses (-1: walking across the edge).
    public var offMesh: Int32

    public init(polygon: Int32, left: Vec3, right: Vec3, edge: Int32, offMesh: Int32 = -1) {
        self.polygon = polygon
        self.left = left
        self.right = right
        self.edge = edge
        self.offMesh = offMesh
    }
}

/// One convex walkable polygon.
public struct NavMeshPolygon: Codable, Equatable, Sendable {
    /// Corners, in order around the polygon.
    public var vertices: [Vec3]
    /// Portals to the neighbours and the off-mesh links that start here.
    public var links: [NavMeshLink]
    /// The layer region it was cut from (a region never covers a spot twice).
    public var region: Int32
    /// Polygons with the same island reach each other (walking and links, either way).
    public var island: Int32
    /// Detail heights: a `detailColumns` × `detailRows` grid of surface heights, row by row
    /// along x, the first at (`detailX`, `detailZ`), `detailStep` meters apart.
    public var detailX: Float
    public var detailZ: Float
    public var detailStep: Float
    public var detailColumns: Int
    public var detailRows: Int
    public var detailHeights: [Float]

    public init(vertices: [Vec3], links: [NavMeshLink] = [], region: Int32 = 0, island: Int32 = 0,
                detailX: Float = 0, detailZ: Float = 0, detailStep: Float = 1, detailColumns: Int = 0, detailRows: Int = 0,
                detailHeights: [Float] = []) {
        self.vertices = vertices
        self.links = links
        self.region = region
        self.island = island
        self.detailX = detailX
        self.detailZ = detailZ
        self.detailStep = detailStep
        self.detailColumns = detailColumns
        self.detailRows = detailRows
        self.detailHeights = detailHeights
    }

    /// The middle of the corners.
    public var center: Vec3 { vertices.reduce(Vec3.zero, +) / Float(max(vertices.count, 1)) }

    /// Area on the XZ plane, in square meters.
    public var area: Float {
        var sum: Float = 0
        for i in vertices.indices {
            let a = vertices[i], b = vertices[(i + 1) % vertices.count]
            sum += a.x * b.z - b.x * a.z
        }
        return abs(sum) / 2
    }

    /// The surface height at `x`, `z` (from the detail samples, else the corners' plane).
    public func height(x: Float, z: Float) -> Float {
        guard detailColumns > 0, detailRows > 0, detailHeights.count == detailColumns * detailRows else {
            return vertices.isEmpty ? 0 : vertices.map(\.y).reduce(0, +) / Float(vertices.count)
        }
        let fx = min(max((x - detailX) / detailStep, 0), Float(detailColumns - 1))
        let fz = min(max((z - detailZ) / detailStep, 0), Float(detailRows - 1))
        let x0 = Int(fx), z0 = Int(fz)
        let x1 = min(x0 + 1, detailColumns - 1), z1 = min(z0 + 1, detailRows - 1)
        let tx = fx - Float(x0), tz = fz - Float(z0)
        let h00 = detailHeights[z0 * detailColumns + x0], h10 = detailHeights[z0 * detailColumns + x1]
        let h01 = detailHeights[z1 * detailColumns + x0], h11 = detailHeights[z1 * detailColumns + x1]
        return (h00 * (1 - tx) + h10 * tx) * (1 - tz) + (h01 * (1 - tx) + h11 * tx) * tz
    }

    /// Whether `point` is inside on the XZ plane (within `margin` meters of the edges).
    public func contains(x: Float, z: Float, margin: Float = 1e-4) -> Bool {
        guard vertices.count >= 3 else { return false }
        let sign = orientation
        for i in vertices.indices {
            let a = vertices[i], b = vertices[(i + 1) % vertices.count]
            let ex = b.x - a.x, ez = b.z - a.z
            let len = (ex * ex + ez * ez).squareRoot()
            guard len > 1e-7 else { continue }
            let side = (ex * (z - a.z) - ez * (x - a.x)) / len
            if side * sign < -margin { return false }
        }
        return true
    }

    /// +1 when the corners go counter-clockwise in (x, z), -1 when clockwise.
    var orientation: Float {
        var sum: Float = 0
        for i in vertices.indices {
            let a = vertices[i], b = vertices[(i + 1) % vertices.count]
            sum += a.x * b.z - b.x * a.z
        }
        return sum >= 0 ? 1 : -1
    }

    /// The point inside nearest (`x`, `z`) on the XZ plane.
    public func closestPoint(x: Float, z: Float) -> (x: Float, z: Float) {
        if contains(x: x, z: z) { return (x, z) }
        var best = (x: vertices.first?.x ?? x, z: vertices.first?.z ?? z)
        var bestD = Float.infinity
        for i in vertices.indices {
            let a = vertices[i], b = vertices[(i + 1) % vertices.count]
            let ex = b.x - a.x, ez = b.z - a.z
            let lenSq = ex * ex + ez * ez
            let t = lenSq > 1e-12 ? min(max(((x - a.x) * ex + (z - a.z) * ez) / lenSq, 0), 1) : 0
            let px = a.x + ex * t, pz = a.z + ez * t
            let d = (px - x) * (px - x) + (pz - z) * (pz - z)
            if d < bestD { bestD = d; best = (px, pz) }
        }
        return best
    }

    /// Bounds on the XZ plane (min x, min z, max x, max z).
    var flatBounds: (Float, Float, Float, Float) {
        var lo = (Float.infinity, Float.infinity), hi = (-Float.infinity, -Float.infinity)
        for v in vertices {
            lo = (min(lo.0, v.x), min(lo.1, v.z))
            hi = (max(hi.0, v.x), max(hi.1, v.z))
        }
        return (lo.0, lo.1, hi.0, hi.1)
    }
}

/// An off-mesh connection: a jump, drop or ladder between two spots the mesh doesn't join.
public struct NavMeshOffMeshLink: Codable, Equatable, Sendable {
    public var start: Vec3
    public var end: Vec3
    public var startPolygon: Int32
    public var endPolygon: Int32
    public var bidirectional: Bool
    public var kind: NavigationLinkKind
    /// Extra cost in meters on top of its length.
    public var cost: Float

    public init(start: Vec3, end: Vec3, startPolygon: Int32, endPolygon: Int32, bidirectional: Bool, kind: NavigationLinkKind, cost: Float) {
        self.start = start
        self.end = end
        self.startPolygon = startPolygon
        self.endPolygon = endPolygon
        self.bidirectional = bidirectional
        self.kind = kind
        self.cost = cost
    }
}

/// A place on the mesh: a polygon and a point on its surface.
public struct NavMeshLocation: Equatable, Sendable {
    public var polygon: Int
    public var point: Vec3

    public init(polygon: Int, point: Vec3) {
        self.polygon = polygon
        self.point = point
    }
}

/// A baked navigation mesh (see the notes at the top of NavMesh.swift).
public struct NavMesh: Codable, Equatable, Sendable, NavigationSurface {
    /// The format version of baked files; bakes from another version are rebaked.
    public static let formatVersion = 1

    public var settings: NavigationSettings
    /// The voxel size it was baked at.
    public var voxelSize: Float
    public var polygons: [NavMeshPolygon]
    public var offMeshLinks: [NavMeshOffMeshLink]
    /// How many islands (separately reachable areas) there are.
    public var islandCount: Int
    public var boundsMin: Vec3
    public var boundsMax: Vec3
    /// What the bake warned about (unreachable areas, links off the mesh).
    public var warnings: [String] = []

    /// Polygons by XZ bucket, for lookups (rebuilt on decode).
    private var buckets: [Int: [Int32]] = [:]
    private var bucketSize: Float = 4

    public init(settings: NavigationSettings, voxelSize: Float, polygons: [NavMeshPolygon], offMeshLinks: [NavMeshOffMeshLink] = []) {
        self.settings = settings
        self.voxelSize = voxelSize
        self.polygons = polygons
        self.offMeshLinks = offMeshLinks
        islandCount = 0
        boundsMin = .zero
        boundsMax = .zero
        finish()
    }

    private enum CodingKeys: String, CodingKey { case version, settings, voxelSize, polygons, offMeshLinks, warnings }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 0
        guard version == Self.formatVersion else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: c, debugDescription: "navmesh format \(version), expected \(Self.formatVersion)")
        }
        settings = try c.decode(NavigationSettings.self, forKey: .settings)
        voxelSize = try c.decode(Float.self, forKey: .voxelSize)
        polygons = try c.decode([NavMeshPolygon].self, forKey: .polygons)
        offMeshLinks = try c.decodeIfPresent([NavMeshOffMeshLink].self, forKey: .offMeshLinks) ?? []
        warnings = try c.decodeIfPresent([String].self, forKey: .warnings) ?? []
        islandCount = 0
        boundsMin = .zero
        boundsMax = .zero
        finish()
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Self.formatVersion, forKey: .version)
        try c.encode(settings, forKey: .settings)
        try c.encode(voxelSize, forKey: .voxelSize)
        try c.encode(polygons, forKey: .polygons)
        try c.encode(offMeshLinks, forKey: .offMeshLinks)
        if !warnings.isEmpty { try c.encode(warnings, forKey: .warnings) }
    }

    public static func == (a: NavMesh, b: NavMesh) -> Bool {
        a.settings == b.settings && a.voxelSize == b.voxelSize && a.polygons == b.polygons && a.offMeshLinks == b.offMeshLinks
    }

    /// Islands, bounds and the bucket index from the polygons.
    private mutating func finish() {
        // Islands: union-find over portals and links (either direction).
        var parent = Array(0..<polygons.count)
        func root(_ i: Int) -> Int {
            var i = i
            while parent[i] != i { parent[i] = parent[parent[i]]; i = parent[i] }
            return i
        }
        for (i, polygon) in polygons.enumerated() {
            for link in polygon.links where link.polygon >= 0 && Int(link.polygon) < polygons.count {
                let a = root(i), b = root(Int(link.polygon))
                if a != b { parent[max(a, b)] = min(a, b) }
            }
        }
        var ids: [Int: Int32] = [:]
        for i in polygons.indices {
            let r = root(i)
            let id = ids[r] ?? Int32(ids.count)
            ids[r] = id
            polygons[i].island = id
        }
        islandCount = ids.count
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for polygon in polygons {
            for v in polygon.vertices { lo = pointwiseMin(lo, v); hi = pointwiseMax(hi, v) }
        }
        if polygons.isEmpty { lo = .zero; hi = .zero }
        boundsMin = lo
        boundsMax = hi
        bucketSize = max(voxelSize * 16, 2)
        buckets = [:]
        for (i, polygon) in polygons.enumerated() {
            let (x0, z0, x1, z1) = polygon.flatBounds
            for bz in bucket(z0)...bucket(z1) {
                for bx in bucket(x0)...bucket(x1) { buckets[key(bx, bz), default: []].append(Int32(i)) }
            }
        }
    }

    private func bucket(_ v: Float) -> Int { Int((v / bucketSize).rounded(.down)) }
    private func key(_ x: Int, _ z: Int) -> Int { (x & 0xFFFFFF) | ((z & 0xFFFFFF) << 24) }

    /// The polygons whose XZ bounds come within `radius` of (`x`, `z`).
    func candidates(x: Float, z: Float, radius: Float) -> [Int] {
        var out: [Int] = []
        var seen = Set<Int32>()
        for bz in bucket(z - radius)...bucket(z + radius) {
            for bx in bucket(x - radius)...bucket(x + radius) {
                for i in buckets[key(bx, bz)] ?? [] where seen.insert(i).inserted { out.append(Int(i)) }
            }
        }
        return out.sorted()
    }

    public var polygonCount: Int { polygons.count }
    public var resolution: Float { voxelSize }
    /// Walkable area in square meters.
    public var area: Float { polygons.reduce(0) { $0 + $1.area } }

    // MARK: Locating

    /// The polygon under `point` whose surface is nearest it in height (within the agent's
    /// height above or `stepHeight` below plus `vertical`), or nil.
    public func locate(_ point: Vec3, vertical: Float = 0) -> NavMeshLocation? {
        var best: (i: Int, h: Float, d: Float)?
        let above = settings.agentHeight + vertical, below = max(settings.stepHeight, 0.25) + vertical
        for i in candidates(x: point.x, z: point.z, radius: 0) where polygons[i].contains(x: point.x, z: point.z, margin: 1e-3) {
            let h = polygons[i].height(x: point.x, z: point.z)
            let dy = point.y - h
            guard dy <= above, dy >= -below else { continue }
            let d = abs(dy)
            if best == nil || d < best!.d { best = (i, h, d) }
        }
        return best.map { NavMeshLocation(polygon: $0.i, point: Vec3(point.x, $0.h, point.z)) }
    }

    /// The point on the mesh nearest `point` within `maxDistance` meters across (and the
    /// agent's height plus `maxDistance` up or down).
    public func nearest(to point: Vec3, maxDistance: Float = 3) -> NavMeshLocation? {
        if let hit = locate(point) { return hit }
        var best: (location: NavMeshLocation, d: Float)?
        for i in candidates(x: point.x, z: point.z, radius: maxDistance) {
            let polygon = polygons[i]
            let c = polygon.closestPoint(x: point.x, z: point.z)
            let flat = ((c.x - point.x) * (c.x - point.x) + (c.z - point.z) * (c.z - point.z)).squareRoot()
            guard flat <= maxDistance + 1e-4 else { continue }
            let h = polygon.height(x: c.x, z: c.z)
            let dy = point.y - h
            guard dy <= settings.agentHeight + maxDistance, dy >= -(max(settings.stepHeight, 0.25) + maxDistance) else { continue }
            // Height counts less than distance across (agents' origins may sit above their feet).
            let d = flat + abs(dy) * 0.5
            if best == nil || d < best!.d { best = (NavMeshLocation(polygon: i, point: Vec3(c.x, h, c.z)), d) }
        }
        return best?.location
    }

    /// The surface height under `point` (nil off the mesh).
    public func height(at point: Vec3) -> Float? { locate(point)?.point.y }

    public func nearestWalkablePoint(to point: Vec3, maxDistance: Float = 3) -> Vec3? {
        nearest(to: point, maxDistance: maxDistance)?.point
    }

    public func areConnected(_ a: Vec3, _ b: Vec3) -> Bool {
        guard let la = locate(a), let lb = locate(b) else { return false }
        return polygons[la.polygon].island == polygons[lb.polygon].island
    }

    // MARK: Walking straight

    /// The edge where the segment from (`ax`, `az`) along (`dx`, `dz`) leaves polygon `i` and
    /// the fraction there (nil: it doesn't leave before 1).
    private func exit(_ i: Int, ax: Float, az: Float, dx: Float, dz: Float) -> (edge: Int, t: Float)? {
        let polygon = polygons[i]
        let o = polygon.orientation
        var best: (edge: Int, t: Float)?
        for e in polygon.vertices.indices {
            let a = polygon.vertices[e], b = polygon.vertices[(e + 1) % polygon.vertices.count]
            // Outward normal: right of the edge for counter-clockwise corners.
            let nx = (b.z - a.z) * o, nz = -(b.x - a.x) * o
            let denom = nx * dx + nz * dz
            guard denom > 1e-9 else { continue }
            let t = (nx * (a.x - ax) + nz * (a.z - az)) / denom
            if best == nil || t < best!.t { best = (e, t) }
        }
        guard let best, best.t < 1 else { return nil }
        return (best.edge, max(best.t, 0))
    }

    /// The walking portal on edge `edge` of polygon `i` that (`x`, `z`) lies on.
    private func portal(_ i: Int, edge: Int, x: Float, z: Float) -> NavMeshLink? {
        let tolerance = max(voxelSize * 0.05, 1e-3)
        for link in polygons[i].links where link.edge == Int32(edge) && link.offMesh < 0 {
            let ex = link.right.x - link.left.x, ez = link.right.z - link.left.z
            let lenSq = ex * ex + ez * ez
            let t = lenSq > 1e-12 ? ((x - link.left.x) * ex + (z - link.left.z) * ez) / lenSq : 0
            let l = lenSq.squareRoot()
            if t * l >= -tolerance, t * l <= l + tolerance { return link }
        }
        return nil
    }

    /// Walks the straight line from `start` (on polygon `from`) toward `end` across polygons:
    /// the polygon it ends on and the fraction walked before a wall (1: all the way).
    func walk(from: Int, start: Vec3, end: Vec3) -> (polygon: Int, t: Float, wallEdge: Int?) {
        var current = from
        let dx = end.x - start.x, dz = end.z - start.z
        var visited = 0
        while visited < polygons.count + 8 {
            visited += 1
            guard let (edge, t) = exit(current, ax: start.x, az: start.z, dx: dx, dz: dz) else { return (current, 1, nil) }
            let x = start.x + dx * t, z = start.z + dz * t
            guard let link = portal(current, edge: edge, x: x, z: z) else { return (current, t, edge) }
            current = Int(link.polygon)
        }
        return (current, 0, nil)
    }

    public func isClear(from a: Vec3, to b: Vec3) -> Bool {
        guard let start = locate(a) else { return false }
        let result = walk(from: start.polygon, start: a, end: b)
        guard result.t >= 1 else { return false }
        // The line ends on b's floor (not the one above or below it).
        if let goal = locate(b) { return polygons[goal.polygon].island == polygons[result.polygon].island
            && abs(polygons[result.polygon].height(x: b.x, z: b.z) - goal.point.y) <= settings.stepHeight + 0.05 }
        return false
    }

    /// Moves from `location` toward `target` along the surface: stops at walls and slides
    /// along them (two tries), and returns where it ends up, on the surface.
    public func move(from location: NavMeshLocation, to target: Vec3) -> NavMeshLocation {
        var current = location
        var goal = target
        for _ in 0..<3 {
            let result = walk(from: current.polygon, start: current.point, end: goal)
            let dx = goal.x - current.point.x, dz = goal.z - current.point.z
            if result.t >= 1 {
                let p = polygons[result.polygon]
                return NavMeshLocation(polygon: result.polygon, point: Vec3(goal.x, p.height(x: goal.x, z: goal.z), goal.z))
            }
            // Stop just short of the wall, then slide the rest along it.
            let back = max(voxelSize * 0.01, 1e-3) / max((dx * dx + dz * dz).squareRoot(), 1e-6)
            let t = max(result.t - back, 0)
            let x = current.point.x + dx * t, z = current.point.z + dz * t
            let polygon = polygons[result.polygon]
            let stop = polygon.closestPoint(x: x, z: z)
            current = NavMeshLocation(polygon: result.polygon, point: Vec3(stop.x, polygon.height(x: stop.x, z: stop.z), stop.z))
            guard let edge = result.wallEdge else { break }
            let a = polygon.vertices[edge], b = polygon.vertices[(edge + 1) % polygon.vertices.count]
            var ex = b.x - a.x, ez = b.z - a.z
            let len = (ex * ex + ez * ez).squareRoot()
            guard len > 1e-6 else { break }
            ex /= len; ez /= len
            let rest = (dx * (1 - t)) * ex + (dz * (1 - t)) * ez
            guard abs(rest) > 1e-5 else { break }
            goal = Vec3(current.point.x + ex * rest, goal.y, current.point.z + ez * rest)
        }
        return current
    }

    // MARK: Paths

    public func findPath(from start: Vec3, to goal: Vec3, partial: Bool = false, snapDistance: Float = 3) -> [Vec3]? {
        navigationPath(from: start, to: goal, partial: partial, snapDistance: snapDistance)?.points
    }

    public func navigationPath(from start: Vec3, to goal: Vec3, partial: Bool) -> NavigationPath? {
        navigationPath(from: start, to: goal, partial: partial, snapDistance: 3)
    }

    /// A walkable path from `start` to `goal` (both snapped onto the mesh within
    /// `snapDistance`), through the corners it has to go round and across off-mesh links. nil
    /// when either end is off the mesh or the goal can't be reached; with `partial`, the path
    /// to the reachable point nearest the goal instead.
    public func navigationPath(from start: Vec3, to goal: Vec3, partial: Bool, snapDistance: Float) -> NavigationPath? {
        guard let s = nearest(to: start, maxDistance: snapDistance) else { return nil }
        let island = polygons[s.polygon].island
        var g: NavMeshLocation
        if let on = locate(goal), polygons[on.polygon].island == island {
            g = on
        } else if !partial, locate(goal) != nil {
            return nil  // on the mesh, but on an island the start can't reach
        } else if let near = nearestOnIsland(goal, island: island, maxDistance: snapDistance) {
            g = near
        } else if partial, let near = nearestOnIsland(goal, island: island, maxDistance: .infinity) {
            g = near
        } else {
            return nil
        }
        guard let corridor = search(from: s, to: g, partial: partial) else { return nil }
        if corridor.reachedPartially, let last = corridor.polygons.last {
            let c = polygons[last].closestPoint(x: goal.x, z: goal.z)
            g = NavMeshLocation(polygon: last, point: Vec3(c.x, polygons[last].height(x: c.x, z: c.z), c.z))
        }
        return stringPull(corridor: corridor, start: s.point, goal: g.point)
    }

    private func nearestOnIsland(_ point: Vec3, island: Int32, maxDistance: Float) -> NavMeshLocation? {
        var best: (location: NavMeshLocation, d: Float)?
        let indices = maxDistance.isFinite ? candidates(x: point.x, z: point.z, radius: maxDistance) : Array(polygons.indices)
        for i in indices where polygons[i].island == island {
            let polygon = polygons[i]
            let c = polygon.closestPoint(x: point.x, z: point.z)
            let flat = ((c.x - point.x) * (c.x - point.x) + (c.z - point.z) * (c.z - point.z)).squareRoot()
            guard flat <= maxDistance + 1e-4 else { continue }
            let h = polygon.height(x: c.x, z: c.z)
            let d = flat + abs(point.y - h) * 0.5
            if best == nil || d < best!.d { best = (NavMeshLocation(polygon: i, point: Vec3(c.x, h, c.z)), d) }
        }
        return best?.location
    }

    struct Corridor {
        /// Polygons from start to goal.
        var polygons: [Int]
        /// The link taken out of each polygon but the last.
        var links: [NavMeshLink]
        var reachedPartially: Bool
    }

    /// A* over polygons: a node's position is where it was entered (a portal's middle, a link's
    /// end); cost is distance between those, plus links' extra cost.
    func search(from s: NavMeshLocation, to g: NavMeshLocation, partial: Bool) -> Corridor? {
        if s.polygon == g.polygon { return Corridor(polygons: [s.polygon], links: [], reachedPartially: false) }
        var cost: [Int: Float] = [s.polygon: 0]
        var position: [Int: Vec3] = [s.polygon: s.point]
        var came: [Int: (from: Int, link: NavMeshLink)] = [:]
        var closed = Set<Int>()
        var heap = NavigationHeap()
        heap.push(distance(s.point, g.point), s.polygon)
        var nearest = (polygon: s.polygon, d: distance(s.point, g.point))
        var found = false
        var expansions = 0
        while let (_, i) = heap.pop() {
            if i == g.polygon { found = true; break }
            if !closed.insert(i).inserted { continue }
            expansions += 1
            if expansions > 65_536 { break }
            let here = position[i]!
            let d = distance(here, g.point)
            if d < nearest.d { nearest = (i, d) }
            for link in polygons[i].links {
                let n = Int(link.polygon)
                guard n >= 0, n < polygons.count, !closed.contains(n) else { continue }
                let entry: Vec3
                var step: Float
                if link.offMesh >= 0 {
                    let off = offMeshLinks[Int(link.offMesh)]
                    let forward = off.startPolygon == Int32(i)
                    let from = forward ? off.start : off.end, to = forward ? off.end : off.start
                    entry = to
                    step = distance(here, from) + distance(from, to) + max(off.cost, 0)
                } else {
                    entry = (link.left + link.right) * 0.5
                    step = distance(here, entry)
                }
                if n == g.polygon { step += distance(entry, g.point) }
                let c = cost[i]! + step
                if c < cost[n] ?? .infinity {
                    cost[n] = c
                    position[n] = entry
                    came[n] = (i, link)
                    heap.push(c + (n == g.polygon ? 0 : distance(entry, g.point)), n)
                }
            }
        }
        var end = g.polygon
        var reachedPartially = false
        if !found {
            guard partial else { return nil }
            end = nearest.polygon
            reachedPartially = true
        }
        var chain = [end]
        var links: [NavMeshLink] = []
        var k = end
        while let step = came[k] {
            links.append(step.link)
            k = step.from
            chain.append(k)
        }
        return Corridor(polygons: chain.reversed(), links: links.reversed(), reachedPartially: reachedPartially)
    }

    private func distance(_ a: Vec3, _ b: Vec3) -> Float { EngineCore.length(a - b) }

    /// Pulls the string through the corridor's portals, one walking stretch at a time
    /// between off-mesh links, and adds the heights.
    func stringPull(corridor: Corridor, start: Vec3, goal: Vec3) -> NavigationPath {
        var points: [Vec3] = []
        var segments: [NavigationLinkKind] = []
        var stretchStart = start
        var portals: [(left: Vec3, right: Vec3)] = []
        var stretchPolygons: [Int] = [corridor.polygons[0]]
        func flush(to end: Vec3) {
            let pulled = Self.funnel(start: stretchStart, end: end, portals: portals)
            let draped = drape(pulled, over: stretchPolygons)
            for (i, p) in draped.enumerated() {
                if i == 0, let last = points.last, EngineCore.length(last - p) < 1e-4 { continue }
                if !points.isEmpty { segments.append(.walk) }
                points.append(p)
            }
        }
        for (i, link) in corridor.links.enumerated() {
            let next = corridor.polygons[i + 1]
            if link.offMesh >= 0 {
                let off = offMeshLinks[Int(link.offMesh)]
                let forward = off.startPolygon == Int32(corridor.polygons[i])
                let from = forward ? off.start : off.end, to = forward ? off.end : off.start
                flush(to: from)
                points.append(to)
                segments.append(off.kind == .walk ? .walk : off.kind)
                stretchStart = to
                portals = []
                stretchPolygons = [next]
            } else {
                portals.append((link.left, link.right))
                stretchPolygons.append(next)
            }
        }
        flush(to: goal)
        if points.count == 1 { points.append(goal); segments.append(.walk) }
        return NavigationPath(points: points, segments: segments)
    }

    /// The simple stupid funnel algorithm on the XZ plane: the shortest line from `start`
    /// through `portals` (left and right ends seen walking through) to `end`.
    static func funnel(start: Vec3, end: Vec3, portals: [(left: Vec3, right: Vec3)]) -> [Vec3] {
        let all = [(left: start, right: start)] + portals + [(left: end, right: end)]
        // Detour's triangle area sign: > 0 when c is left of a → b.
        func area(_ a: Vec3, _ b: Vec3, _ c: Vec3) -> Float {
            let ax = b.x - a.x, az = b.z - a.z, bx = c.x - a.x, bz = c.z - a.z
            return bx * az - ax * bz
        }
        func same(_ a: Vec3, _ b: Vec3) -> Bool { (a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z) < 1e-8 }
        var path = [start]
        var apex = start, left = all[0].left, right = all[0].right
        var apexIndex = 0, leftIndex = 0, rightIndex = 0
        var i = 1
        var guardCount = all.count * all.count + 16
        while i < all.count, guardCount > 0 {
            guardCount -= 1
            let l = all[i].left, r = all[i].right
            // The right side.
            if area(apex, right, r) <= 0 {
                if same(apex, right) || area(apex, left, r) > 0 {
                    right = r
                    rightIndex = i
                } else {
                    if !same(path.last!, left) { path.append(left) }
                    apex = left
                    apexIndex = leftIndex
                    left = apex; right = apex
                    leftIndex = apexIndex; rightIndex = apexIndex
                    i = apexIndex + 1
                    continue
                }
            }
            // The left side.
            if area(apex, left, l) >= 0 {
                if same(apex, left) || area(apex, right, l) < 0 {
                    left = l
                    leftIndex = i
                } else {
                    if !same(path.last!, right) { path.append(right) }
                    apex = right
                    apexIndex = rightIndex
                    left = apex; right = apex
                    leftIndex = apexIndex; rightIndex = apexIndex
                    i = apexIndex + 1
                    continue
                }
            }
            i += 1
        }
        if !same(path.last!, end) || path.count == 1 { path.append(end) }
        return path
    }

    /// Heights for the pulled points from the stretch's polygons, plus a point wherever a
    /// straight segment would leave the surface by more than a few centimeters (slope changes).
    func drape(_ points: [Vec3], over stretch: [Int]) -> [Vec3] {
        guard !points.isEmpty else { return points }
        func surface(_ x: Float, _ z: Float, near y: Float) -> Float? {
            var best: (h: Float, d: Float)?
            for i in stretch where polygons[i].contains(x: x, z: z, margin: max(voxelSize * 0.25, 1e-3)) {
                let h = polygons[i].height(x: x, z: z)
                let d = abs(h - y)
                if best == nil || d < best!.d { best = (h, d) }
            }
            return best?.h
        }
        var out: [Vec3] = []
        var lastY = points[0].y
        for (k, p) in points.enumerated() {
            let y = surface(p.x, p.z, near: lastY) ?? p.y
            let here = Vec3(p.x, y, p.z)
            if k > 0, let prev = out.last {
                // Sample the segment's surface, then keep the fewest samples that keep straight
                // lines within a few centimeters of it (Douglas-Peucker on height).
                let flat = ((here.x - prev.x) * (here.x - prev.x) + (here.z - prev.z) * (here.z - prev.z)).squareRoot()
                let steps = min(Int(flat / max(voxelSize, 0.05)), 512)
                if steps > 1 {
                    var samples = [prev]
                    for s in 1..<steps {
                        let t = Float(s) / Float(steps)
                        let x = prev.x + (here.x - prev.x) * t, z = prev.z + (here.z - prev.z) * t
                        if let h = surface(x, z, near: samples.last!.y) { samples.append(Vec3(x, h, z)) }
                    }
                    samples.append(here)
                    var keep = [Bool](repeating: false, count: samples.count)
                    func simplify(_ a: Int, _ b: Int) {
                        guard b > a + 1 else { return }
                        let pa = samples[a], pb = samples[b]
                        let total = ((pb.x - pa.x) * (pb.x - pa.x) + (pb.z - pa.z) * (pb.z - pa.z)).squareRoot()
                        var worst = (i: -1, d: Float(0.08))
                        for i in (a + 1)..<b {
                            let p = samples[i]
                            let along = ((p.x - pa.x) * (p.x - pa.x) + (p.z - pa.z) * (p.z - pa.z)).squareRoot()
                            let lineY = total > 1e-5 ? pa.y + (pb.y - pa.y) * along / total : pa.y
                            let d = abs(lineY - p.y)
                            if d > worst.d { worst = (i, d) }
                        }
                        guard worst.i >= 0 else { return }
                        keep[worst.i] = true
                        simplify(a, worst.i)
                        simplify(worst.i, b)
                    }
                    simplify(0, samples.count - 1)
                    for i in 1..<(samples.count - 1) where keep[i] { out.append(samples[i]) }
                }
            }
            out.append(here)
            lastY = y
        }
        return out
    }
}
