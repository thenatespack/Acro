import EditorCore
import Engine
import Foundation

/// The navigation tools: `navigation.bake`, `navigation.query`, `navigation.overlay`.
@MainActor
public enum EditorNavigationCommands {
    public static let all: [any EditorCommand.Type] = [
        NavigationBakeCommand.self,
        NavigationQueryCommand.self,
        NavigationOverlayCommand.self,
    ]

    /// The last path `navigation.query` found, which the overlay draws.
    static var lastQueryPath: [Vec3] = []

    static let overlayName = "navigation"
}

extension EditorSession {
    /// Bakes the current world's navigation (navmesh and grid), caching navmeshes in the
    /// project's `Library/Navigation` (which the cooker ships with exported games).
    @discardableResult
    func bakeWorldNavigation(useCache: Bool = true) -> NavMeshBakeReport? {
        let world = self.world
        if let assets { world.navigationCache = NavigationBakeCache.forAssets(assets) }
        guard world.count(of: Collider.self) > 0 else {
            world.clearNavigation()
            return nil
        }
        guard let report = world.bakeNavMesh(useCache: useCache) else { return nil }
        // The grid too: the fallback, and what `behavior.navigation` reports.
        world.navigation = world.makeNavigation()
        return report
    }
}

public enum NavigationBakeCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Bake again even when the cache has a bake of this level (default false).
        public var force: Bool?
        /// Show the navmesh in the Scene view afterwards (default: leave the overlay as it is).
        public var overlay: Bool?
        public init(force: Bool? = nil, overlay: Bool? = nil) {
            self.force = force
            self.overlay = overlay
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Whether anything was baked (false: the world has no colliders).
        public var baked: Bool
        /// Read from the Library cache instead of baked.
        public var cached: Bool
        public var polygons: Int
        /// Walkable area in square meters.
        public var area: Float
        /// Separately reachable areas (1: everything connects).
        public var islands: Int
        public var regions: Int
        public var offMeshLinks: Int
        public var voxelSize: Float
        /// Bake time in milliseconds (0 when cached).
        public var milliseconds: Double
        /// Unreachable areas, links whose ends aren't on the mesh, a too-big area.
        public var warnings: [String]
        public var boundsMin: Vec3?
        public var boundsMax: Vec3?
        /// The cache key (a file in Library/Navigation), when the project has a Library.
        public var cacheFile: String?
    }

    public static let id: CommandID = "navigation.bake"
    public static let title = "Bake Navigation"
    public static let doc = "Bakes the navmesh behavior trees and `world.findPath` walk on from the static colliders of the current world (the play world while playing): voxelized, eroded by the agent radius, cut into layer regions and convex polygons with detail heights, so floors above one another, ramps and bridges work; NavigationLink components add off-mesh links (jumps, drops, ladders). A NavigationArea component sets the box and the agent (radius, height, step, slope, voxelSize, maxPolygonSize). Reports the polygon count, bake time and warnings (areas the largest can't reach, links off the mesh). Bakes are cached in the project's Library/Navigation by what they were baked from (`force` bakes anyway) and cooked into exported games, which load them instead of baking. The grid fallback is baked too. Game code: `world.bakeNavMesh()`."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let report = session.bakeWorldNavigation(useCache: !(arguments.force ?? false))
        if let show = arguments.overlay { NavigationOverlayCommand.setOverlay(show, in: session) }
        guard let report else {
            return Result(baked: false, cached: false, polygons: 0, area: 0, islands: 0, regions: 0, offMeshLinks: 0, voxelSize: 0, milliseconds: 0,
                          warnings: ["Nothing to bake: the world has no static colliders"])
        }
        let mesh = report.navMesh
        var file: String?
        if let directory = session.world.navigationCache?.directory {
            let newest = NavigationBakeCache.files(in: directory).values.max { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return da < db
            }
            file = newest.map { "Library/\(NavigationBakeCache.libraryFolder)/\($0.lastPathComponent)" }
        }
        return Result(baked: true, cached: report.cached, polygons: mesh.polygonCount, area: mesh.area, islands: mesh.islandCount,
                      regions: report.regionCount, offMeshLinks: mesh.offMeshLinks.count, voxelSize: mesh.voxelSize,
                      milliseconds: (report.seconds * 1000).rounded(), warnings: report.warnings,
                      boundsMin: mesh.polygons.isEmpty ? nil : mesh.boundsMin, boundsMax: mesh.polygons.isEmpty ? nil : mesh.boundsMax,
                      cacheFile: file)
    }
}

public enum NavigationQueryCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Find a path between these world points ([x, y, z]); y picks the floor.
        public var from: Vec3?
        public var to: Vec3?
        /// Path to the reachable point nearest `to` when `to` can't be reached.
        public var partial: Bool?
        /// Where the walkable surface is under (or nearest) this point.
        public var point: Vec3?
        public init(from: Vec3? = nil, to: Vec3? = nil, partial: Bool? = nil, point: Vec3? = nil) {
            self.from = from
            self.to = to
            self.partial = partial
            self.point = point
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// "navmesh", "grid" or "none".
        public var surface: String
        /// Whether this call baked the navigation first (the world had none).
        public var baked: Bool
        public var found: Bool
        public var path: [Vec3]
        /// How each segment of `path` is crossed: walk, jump, drop or ladder.
        public var segments: [String]
        public var length: Float
        /// Whether `from` and `to` are on the walkable surface, and on areas that reach each other.
        public var fromOnMesh: Bool?
        public var toOnMesh: Bool?
        public var connected: Bool?
        /// For `point`: whether it is on the surface, and the nearest surface point (within 3 m).
        public var pointOnMesh: Bool?
        public var nearest: Vec3?
    }

    public static let id: CommandID = "navigation.query"
    public static let title = "Query Navigation"
    public static let doc = "Tests navigation in the current world (baking it first if it has none): with `from` and `to`, the path an agent would walk (on the navmesh when there is one, else the grid; `partial` returns the way to the nearest reachable point), how each segment is crossed (walk, jump, drop, ladder), its length, and whether the ends are on the mesh and connected; with `point`, whether the point is walkable and the nearest walkable point. The navigation overlay (`navigation.overlay`) draws the last path found."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if (arguments.from == nil) != (arguments.to == nil) { throw CommandError.failed("\(title): give both `from` and `to` for a path") }
        if arguments.from == nil, arguments.point == nil { throw CommandError.failed("\(title): give `from` and `to`, or `point`") }
        let world = session.world
        var baked = false
        if world.navigationSurface == nil {
            session.bakeWorldNavigation()
            baked = world.navigationSurface != nil
        }
        let surface = world.navigationSurface
        var result = Result(surface: surface is NavMesh ? "navmesh" : surface is NavigationGrid ? "grid" : "none", baked: baked, found: false,
                            path: [], segments: [], length: 0)
        if let from = arguments.from, let to = arguments.to {
            if let path = world.findNavigationPath(from: from, to: to, partial: arguments.partial ?? false) {
                result.found = true
                result.path = path.points
                result.segments = path.segments.map(\.rawValue)
                result.length = path.length
            }
            if let mesh = world.navMesh {
                result.fromOnMesh = mesh.locate(from) != nil
                result.toOnMesh = mesh.locate(to) != nil
                result.connected = mesh.areConnected(from, to)
            } else if let grid = world.navigation {
                result.fromOnMesh = grid.isWalkable(from)
                result.toOnMesh = grid.isWalkable(to)
                result.connected = grid.areConnected(from, to)
            }
            EditorNavigationCommands.lastQueryPath = result.path
        }
        if let point = arguments.point, let surface {
            if let mesh = surface as? NavMesh { result.pointOnMesh = mesh.locate(point) != nil }
            else if let grid = surface as? NavigationGrid { result.pointOnMesh = grid.isWalkable(point) }
            result.nearest = surface.nearestWalkablePoint(to: point, maxDistance: 3)
        }
        return result
    }
}

public enum NavigationOverlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Show (default) or hide the overlay.
        public var show: Bool?
        public init(show: Bool? = nil) { self.show = show }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var shown: Bool
        /// Polygons drawn (0 while the world has no navmesh: bake one with `navigation.bake`).
        public var polygons: Int
    }

    public static let id: CommandID = "navigation.overlay"
    public static let title = "Show Navigation"
    public static let doc = "Shows or hides the navmesh in the Scene view: polygons tinted by region (areas the largest can't reach in red), their outlines, off-mesh links as arcs, the paths behavior tree agents are walking and the last `navigation.query` path. It draws the current world's navmesh as last baked (`navigation.bake`). view.screenshot shows it with gizmos on."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let show = arguments.show ?? true
        setOverlay(show, in: session)
        return Result(shown: show, polygons: show ? session.world.navMesh?.polygonCount ?? 0 : 0)
    }

    static func setOverlay(_ show: Bool, in session: EditorSession) {
        guard show else {
            session.sceneOverlays[EditorNavigationCommands.overlayName] = nil
            return
        }
        session.sceneOverlays[EditorNavigationCommands.overlayName] = { draw, world in
            world.navMesh?.drawDebug(into: draw)
            world.query(BehaviorTreeState.self) { _, state in
                if state.path.count >= 2 { NavMesh.drawPath(state.path, into: draw, color: Vec4(0.3, 1, 0.4, 1)) }
            }
            let last = EditorNavigationCommands.lastQueryPath
            if last.count >= 2 { NavMesh.drawPath(last, into: draw) }
        }
    }
}
