#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EnginePhysics
import EngineScene

// Baking a navmesh, recast style, from a `PhysicsWorld`'s static bodies:
//
// 1. Voxelize: a column of `voxelSize` squares over the area; a ray down each column finds
//    every surface (the top of each body it crosses), so floors stacked above one another, a
//    bridge and the ground under it all become spans. A span is walkable when it isn't steeper
//    than `maxSlope`, nothing is within `agentHeight` straight above it, and no walkable
//    surface lies just over it (within a step). Steep faces don't hide what's just under them.
// 2. Connect: each span joins the span in each of the four neighbouring columns nearest in
//    height, when the step is at most `stepHeight`.
// 3. Erode by the agent radius: a chamfer distance from the border (spans missing a
//    neighbour: walls, drops, the area's edge); spans nearer than `agentRadius` go.
// 4. Regions: flood fills over the connections that never take two spans in one column, so
//    each region is a single layer.
// 5. Polygons: each region is cut into rectangles of spans greedily (rows along x, then whole
//    rows along z), each staying on one plane (within a few centimeters), at most
//    `maxPolygonSize` across. Portals join rectangles where their spans connect. Each polygon
//    keeps its spans' heights as detail samples.
// 6. Off-mesh links (`NavigationLink`): each end snaps to the nearest polygon within the link's
//    `radius`; a link whose ends both land joins them (both ways unless one-way).
//
// Results report the polygon count, bake time and warnings: islands the largest area can't
// reach, links whose ends aren't on the mesh.

/// An off-mesh link: from this entity's position to `end` (in the entity's space), for a jump,
/// a drop or a ladder the walkable mesh doesn't join. Navmesh bakes connect the two ends.
public struct NavigationLink: Component, Codable, Equatable, Sendable {
    public static let componentName = "NavigationLink"
    public static var fieldHints: [String: FieldHints] {
        ["end": FieldHints(step: 0.05, tooltip: "Where the link lands, in this entity's space (it starts at the entity)"),
         "bidirectional": FieldHints(tooltip: "Agents use it both ways (off: only from the start to the end)"),
         "kind": FieldHints(tooltip: "How agents cross it: jump (an arc), drop (a short fall), ladder (climb), walk"),
         "cost": FieldHints(range: 0...1000, step: 0.5, tooltip: "Extra cost in meters, so paths prefer walking"),
         "radius": FieldHints(range: 0.05...10, step: 0.05, tooltip: "How far from each end the walkable mesh may be")]
    }

    public var end: Vec3
    public var bidirectional: Bool
    public var kind: NavigationLinkKind
    public var cost: Float
    public var radius: Float

    public init(end: Vec3 = Vec3(0, 0, -2), bidirectional: Bool = true, kind: NavigationLinkKind = .jump, cost: Float = 1, radius: Float = 1) {
        self.end = end
        self.bidirectional = bidirectional
        self.kind = kind
        self.cost = cost
        self.radius = radius
    }

    private enum CodingKeys: String, CodingKey { case end, bidirectional, kind, cost, radius }

    public init(from decoder: any Decoder) throws {
        let d = NavigationLink()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        end = try c.decodeIfPresent(Vec3.self, forKey: .end) ?? d.end
        bidirectional = try c.decodeIfPresent(Bool.self, forKey: .bidirectional) ?? d.bidirectional
        kind = try c.decodeIfPresent(NavigationLinkKind.self, forKey: .kind) ?? d.kind
        cost = try c.decodeIfPresent(Float.self, forKey: .cost) ?? d.cost
        radius = try c.decodeIfPresent(Float.self, forKey: .radius) ?? d.radius
    }
}

/// An off-mesh link placed in the world, for `NavMesh.bake`.
public struct NavigationLinkPlacement: Equatable, Sendable {
    public var start: Vec3
    public var end: Vec3
    public var bidirectional: Bool
    public var kind: NavigationLinkKind
    public var cost: Float
    public var radius: Float
    /// What to call it in warnings.
    public var name: String

    public init(start: Vec3, end: Vec3, bidirectional: Bool = true, kind: NavigationLinkKind = .jump, cost: Float = 1, radius: Float = 1,
                name: String = "") {
        self.start = start
        self.end = end
        self.bidirectional = bidirectional
        self.kind = kind
        self.cost = cost
        self.radius = radius
        self.name = name
    }
}

/// What a navmesh bake produced.
public struct NavMeshBakeReport: Sendable {
    public var navMesh: NavMesh
    /// Seconds spent baking (0 when it came from the cache).
    public var seconds: Double
    /// Read from the bake cache instead of baked.
    public var cached: Bool
    public var warnings: [String]
    /// Walkable voxels after erosion.
    public var walkableSpans: Int
    public var regionCount: Int

    public var polygonCount: Int { navMesh.polygonCount }
}

extension NavMesh {
    /// The voxel size a bake with `settings` uses.
    public static func voxelSize(for settings: NavigationSettings) -> Float {
        if settings.voxelSize > 0 { return max(settings.voxelSize, 0.02) }
        return min(max(settings.agentRadius / 2, 0.1), max(settings.cellSize, 0.1))
    }

    /// Bakes the area `bounds` (x and z; y: how far up and down surfaces are searched) of
    /// `physics` (see the notes at the top of NavMeshBake.swift). `isObstacle(body)` says which
    /// bodies count (default: static ones).
    @MainActor
    public static func bake(physics: PhysicsWorld, bounds: AABB, settings: NavigationSettings = NavigationSettings(),
                            links: [NavigationLinkPlacement] = [], isObstacle: ((BodyID) -> Bool)? = nil) -> NavMeshBakeReport {
        let started = Date()
        let accepts = isObstacle ?? { physics.motion(of: $0) == .static }
        var warnings: [String] = []

        // 1. Voxelize.
        var cs = voxelSize(for: settings)
        let sizeX = max(bounds.max.x - bounds.min.x, cs), sizeZ = max(bounds.max.z - bounds.min.z, cs)
        let maxColumns = max(settings.maxCells, 16)
        if Float(sizeX / cs) * Float(sizeZ / cs) > Float(maxColumns) {
            cs = (sizeX * sizeZ / Float(maxColumns)).squareRoot()
            warnings.append("The area needs more than \(maxColumns) voxels; baked with \(String(format: "%.2f", cs)) m voxels instead (raise maxCells or shrink the NavigationArea)")
        }
        let width = max(Int((sizeX / cs).rounded(.up)), 1), depth = max(Int((sizeZ / cs).rounded(.up)), 1)
        let ox = bounds.min.x, oz = bounds.min.z
        let top = bounds.max.y + 0.5
        let span = top - bounds.min.y + 0.5
        let minNormalY = cos(min(max(settings.maxSlope, 0), 89.9) * .pi / 180)
        let step = max(settings.stepHeight, 0)
        let headroom = max(settings.agentHeight - 0.02, 0.05)

        var columnStart = [Int32](repeating: 0, count: width * depth + 1)
        var spanY: [Float] = []
        var spanColumn: [Int32] = []
        for z in 0..<depth {
            for x in 0..<width {
                let c = z * width + x
                columnStart[c] = Int32(spanY.count)
                let cx = ox + (Float(x) + 0.5) * cs, cz = oz + (Float(z) + 0.5) * cs
                let hits = physics.raycastAll(Ray(origin: Vec3(cx, top, cz), direction: Vec3(0, -1, 0)), maxDistance: span)
                var above: Float = .infinity
                var found: [Float] = []
                for hit in hits where accepts(hit.body) {
                    let y = hit.point.y
                    guard hit.distance > 1e-4 else { above = min(above, y); continue }  // the ray started inside it
                    // Too steep: not ground, and it doesn't hide a floor just under it (a ramp's lip).
                    guard hit.normal.y >= minNormalY else { continue }
                    defer { above = min(above, y) }
                    guard above - y > step else { continue }  // under a surface just over it
                    // Headroom: nothing else within the agent's height straight above.
                    let up = physics.raycastAll(Ray(origin: Vec3(cx, y + 0.02, cz), direction: Vec3(0, 1, 0)), maxDistance: headroom)
                    if up.contains(where: { $0.body != hit.body && accepts($0.body) }) { continue }
                    found.append(y)
                }
                // Bottom to top in each column.
                for y in found.reversed() {
                    spanY.append(y)
                    spanColumn.append(Int32(c))
                }
            }
        }
        columnStart[width * depth] = Int32(spanY.count)
        let spanCount = spanY.count

        // 2. Connect (directions: 0 -x, 1 +z, 2 +x, 3 -z).
        let dxs = [-1, 0, 1, 0], dzs = [0, 1, 0, -1]
        var alive = [Bool](repeating: true, count: spanCount)
        var con = [Int32](repeating: -1, count: spanCount * 4)
        func connect() {
            for s in 0..<spanCount {
                let c = Int(spanColumn[s]), x = c % width, z = c / width
                for d in 0..<4 {
                    con[s * 4 + d] = -1
                    guard alive[s] else { continue }
                    let nx = x + dxs[d], nz = z + dzs[d]
                    guard nx >= 0, nz >= 0, nx < width, nz < depth else { continue }
                    let n = nz * width + nx
                    var best: (Int, Float)?
                    for t in Int(columnStart[n])..<Int(columnStart[n + 1]) where alive[t] {
                        let dy = abs(spanY[t] - spanY[s])
                        if dy <= step + 1e-4, best == nil || dy < best!.1 { best = (t, dy) }
                    }
                    if let best { con[s * 4 + d] = Int32(best.0) }
                }
            }
        }
        connect()

        // 3. Erode (chamfer distance: 2 per straight step, 3 per diagonal).
        if settings.agentRadius > 0, spanCount > 0 {
            var dist = [Int32](repeating: Int32.max / 2, count: spanCount)
            for s in 0..<spanCount where (0..<4).contains(where: { con[s * 4 + $0] < 0 }) { dist[s] = 0 }
            func relax(_ s: Int, _ d: Int, _ diagonal: Int) {
                let a = con[s * 4 + d]
                guard a >= 0 else { return }
                dist[s] = min(dist[s], dist[Int(a)] + 2)
                let b = con[Int(a) * 4 + diagonal]
                if b >= 0 { dist[s] = min(dist[s], dist[Int(b)] + 3) }
            }
            for s in 0..<spanCount {
                relax(s, 0, 3)  // -x, then -z
                relax(s, 3, 2)  // -z, then +x
            }
            for s in stride(from: spanCount - 1, through: 0, by: -1) {
                relax(s, 2, 1)  // +x, then +z
                relax(s, 1, 0)  // +z, then -x
            }
            // A span's middle is (dist / 2) voxels plus half a voxel from the wall.
            for s in 0..<spanCount where Float(dist[s]) / 2 * cs + cs / 2 < settings.agentRadius - 1e-4 { alive[s] = false }
            connect()
        }
        let walkableSpans = alive.reduce(0) { $0 + ($1 ? 1 : 0) }

        // 4. Regions: single-layer flood fills.
        var region = [Int32](repeating: -1, count: spanCount)
        var columnMark = [Int32](repeating: -1, count: width * depth)
        var regionCount: Int32 = 0
        var queue: [Int] = []
        for s0 in 0..<spanCount where alive[s0] && region[s0] < 0 {
            let r = regionCount
            regionCount += 1
            region[s0] = r
            columnMark[Int(spanColumn[s0])] = r
            queue.removeAll(keepingCapacity: true)
            queue.append(s0)
            var head = 0
            while head < queue.count {
                let s = queue[head]
                head += 1
                for d in 0..<4 {
                    let t = Int(con[s * 4 + d])
                    guard t >= 0, region[t] < 0, columnMark[Int(spanColumn[t])] != r else { continue }
                    region[t] = r
                    columnMark[Int(spanColumn[t])] = r
                    queue.append(t)
                }
            }
        }

        // 5. Polygons: planar rectangles per region.
        var polygonOf = [Int32](repeating: -1, count: spanCount)
        let maxSide = max(Int((max(settings.maxPolygonSize, cs) / cs).rounded()), 1)
        let tolerance = max(0.03, cs * 0.1)
        // Slopes a polygon may follow (steeper height changes between voxels are steps).
        let maxRise = cs * tan(min(max(settings.maxSlope, 0), 89) * .pi / 180) + tolerance
        struct Rect { var x0: Int; var z0: Int; var x1: Int; var z1: Int; var spans: [Int]; var h0: Float; var sx: Float; var sz: Float; var region: Int32 }
        var rects: [Rect] = []
        // Spans in raster order (z, then x, then height).
        for s0 in 0..<spanCount where alive[s0] && polygonOf[s0] < 0 {
            let c0 = Int(spanColumn[s0])
            let x0 = c0 % width, z0 = c0 / width
            let r = region[s0]
            let h0 = spanY[s0]
            var sx: Float?, sz: Float?
            func fits(_ t: Int, _ x: Int, _ z: Int) -> Bool {
                guard t >= 0, alive[t], region[t] == r, polygonOf[t] < 0 else { return false }
                let predicted = h0 + (sx ?? 0) * Float(x - x0) + (sz ?? 0) * Float(z - z0)
                return abs(spanY[t] - predicted) <= tolerance
            }
            // Along x.
            var row = [s0]
            var x1 = x0
            while x1 - x0 + 1 < maxSide {
                let t = Int(con[row.last! * 4 + 2])
                if sx == nil, t >= 0, alive[t], region[t] == r, polygonOf[t] < 0 {
                    sx = abs(spanY[t] - h0) <= maxRise ? spanY[t] - h0 : 0
                }
                guard fits(t, x1 + 1, z0) else { break }
                row.append(t)
                x1 += 1
            }
            if x1 == x0 { sx = 0 }
            var spans = row
            var z1 = z0
            var previous = row
            // Whole rows along z.
            while z1 - z0 + 1 < maxSide {
                var next: [Int] = []
                var ok = true
                for (k, s) in previous.enumerated() {
                    let t = Int(con[s * 4 + 1])
                    if sz == nil, k == 0, t >= 0, alive[t], region[t] == r, polygonOf[t] < 0 {
                        sz = abs(spanY[t] - spanY[s]) <= maxRise ? spanY[t] - spanY[s] : 0
                    }
                    guard fits(t, x0 + k, z1 + 1) else { ok = false; break }
                    // Joined to the one before it in the new row too.
                    if k > 0, Int(con[next[k - 1] * 4 + 2]) != t { ok = false; break }
                    next.append(t)
                }
                guard ok else { break }
                spans += next
                previous = next
                z1 += 1
            }
            if z1 == z0 { sz = 0 }
            let id = Int32(rects.count)
            for s in spans { polygonOf[s] = id }
            rects.append(Rect(x0: x0, z0: z0, x1: x1, z1: z1, spans: spans, h0: h0, sx: sx ?? 0, sz: sz ?? 0, region: r))
        }

        // Corners, detail heights and portals.
        var polygons: [NavMeshPolygon] = []
        polygons.reserveCapacity(rects.count)
        for rect in rects {
            func plane(_ fx: Float, _ fz: Float) -> Float { rect.h0 + rect.sx * (fx - Float(rect.x0)) + rect.sz * (fz - Float(rect.z0)) }
            // Corners in voxel coordinates (voxel centers at integers).
            let lx = Float(rect.x0) - 0.5, hx = Float(rect.x1) + 0.5, lz = Float(rect.z0) - 0.5, hz = Float(rect.z1) + 0.5
            func world(_ fx: Float, _ fz: Float) -> Vec3 { Vec3(ox + (fx + 0.5) * cs, plane(fx, fz), oz + (fz + 0.5) * cs) }
            let vertices = [world(lx, lz), world(hx, lz), world(hx, hz), world(lx, hz)]  // counter-clockwise in (x, z)
            let columns = rect.x1 - rect.x0 + 1, rows = rect.z1 - rect.z0 + 1
            var detail = [Float](repeating: 0, count: columns * rows)
            for (k, s) in rect.spans.enumerated() { detail[k] = spanY[s] }
            polygons.append(NavMeshPolygon(vertices: vertices, region: rect.region,
                                           detailX: ox + (Float(rect.x0) + 0.5) * cs, detailZ: oz + (Float(rect.z0) + 0.5) * cs,
                                           detailStep: cs, detailColumns: columns, detailRows: rows, detailHeights: detail))
        }
        for (p, rect) in rects.enumerated() {
            let columns = rect.x1 - rect.x0 + 1
            // Each side: (edge index, direction out, the spans along it in edge order, how to place cell k's ends).
            func spanAt(_ x: Int, _ z: Int) -> Int { rect.spans[(z - rect.z0) * columns + (x - rect.x0)] }
            let sides: [(edge: Int, dir: Int, cells: [(x: Int, z: Int)])] = [
                (0, 3, (rect.x0...rect.x1).map { ($0, rect.z0) }),                  // -z side, along +x
                (1, 2, (rect.z0...rect.z1).map { (rect.x1, $0) }),                  // +x side, along +z
                (2, 1, (rect.x0...rect.x1).reversed().map { ($0, rect.z1) }),       // +z side, along -x
                (3, 0, (rect.z0...rect.z1).reversed().map { (rect.x0, $0) }),       // -x side, along -z
            ]
            let polygon = polygons[p]
            let center = polygon.center
            for side in sides {
                var runs: [(neighbour: Int32, first: Int, last: Int)] = []
                for (k, cell) in side.cells.enumerated() {
                    let t = Int(con[spanAt(cell.x, cell.z) * 4 + side.dir])
                    let n = t >= 0 ? polygonOf[t] : -1
                    if n >= 0, n != Int32(p), let last = runs.last, last.neighbour == n, last.last == k - 1 {
                        runs[runs.count - 1].last = k
                    } else if n >= 0, n != Int32(p) {
                        runs.append((n, k, k))
                    }
                }
                let a = polygon.vertices[side.edge], b = polygon.vertices[(side.edge + 1) % 4]
                let count = Float(side.cells.count)
                for run in runs {
                    let p0 = a + (b - a) * (Float(run.first) / count), p1 = a + (b - a) * (Float(run.last + 1) / count)
                    let mid = (p0 + p1) * 0.5
                    let out = Vec3(mid.x - center.x, 0, mid.z - center.z)
                    let side0 = out.x * (p0.z - mid.z) - out.z * (p0.x - mid.x)
                    let (left, right) = side0 > 0 ? (p0, p1) : (p1, p0)
                    polygons[p].links.append(NavMeshLink(polygon: run.neighbour, left: left, right: right, edge: Int32(side.edge)))
                }
            }
        }

        // 6. Off-mesh links.
        var offMesh: [NavMeshOffMeshLink] = []
        let provisional = NavMesh(settings: settings, voxelSize: cs, polygons: polygons)
        for (k, link) in links.enumerated() {
            let name = link.name.isEmpty ? "Link \(k + 1)" : link.name
            let a = provisional.nearest(to: link.start, maxDistance: link.radius)
            let b = provisional.nearest(to: link.end, maxDistance: link.radius)
            guard let a, let b else {
                let which = a == nil && b == nil ? "either end" : a == nil ? "its start" : "its end"
                warnings.append("\(name): no walkable surface within \(String(format: "%.2g", link.radius)) m of \(which); it isn't connected")
                continue
            }
            guard a.polygon != b.polygon else {
                warnings.append("\(name): both ends are on the same walkable area; it isn't needed")
                continue
            }
            let index = Int32(offMesh.count)
            offMesh.append(NavMeshOffMeshLink(start: a.point, end: b.point, startPolygon: Int32(a.polygon), endPolygon: Int32(b.polygon),
                                              bidirectional: link.bidirectional, kind: link.kind, cost: link.cost))
            polygons[a.polygon].links.append(NavMeshLink(polygon: Int32(b.polygon), left: a.point, right: a.point, edge: -1, offMesh: index))
            if link.bidirectional {
                polygons[b.polygon].links.append(NavMeshLink(polygon: Int32(a.polygon), left: b.point, right: b.point, edge: -1, offMesh: index))
            }
        }

        var used = settings
        used.voxelSize = cs
        var mesh = NavMesh(settings: used, voxelSize: cs, polygons: polygons, offMeshLinks: offMesh)
        warnings += mesh.islandWarnings()
        if mesh.polygons.isEmpty { warnings.append("Nothing walkable: no surface is flat, wide and open enough for the agent") }
        mesh.warnings = warnings
        return NavMeshBakeReport(navMesh: mesh, seconds: Date().timeIntervalSince(started), cached: false, warnings: warnings,
                                 walkableSpans: walkableSpans, regionCount: Int(regionCount))
    }

    /// Warnings about islands the largest one can't reach (the five biggest).
    func islandWarnings() -> [String] {
        guard islandCount > 1 else { return [] }
        var area = [Float](repeating: 0, count: islandCount)
        var sum = [Vec3](repeating: .zero, count: islandCount)
        for polygon in polygons {
            let a = polygon.area
            area[Int(polygon.island)] += a
            sum[Int(polygon.island)] += polygon.center * a
        }
        let order = area.indices.sorted { area[$0] != area[$1] ? area[$0] > area[$1] : $0 < $1 }
        var out = ["\(islandCount - 1) walkable area\(islandCount == 2 ? "" : "s") can't be reached from the largest one (\(String(format: "%.1f", area[order[0]])) m²)"]
        for i in order.dropFirst().prefix(5) {
            let c = area[i] > 0 ? sum[i] / area[i] : .zero
            out.append(String(format: "  unreachable: %.1f m² around (%.1f, %.1f, %.1f)", area[i], c.x, c.y, c.z))
        }
        return out
    }
}
