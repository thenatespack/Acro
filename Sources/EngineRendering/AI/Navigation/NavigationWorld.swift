import Foundation
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// A world's navigation: the grid and navmesh `World.findPath` and behavior trees use, how they
// are baked from the world's colliders, and the bake cache (`NavigationBakeCache`: baked
// navmeshes in the project's `Library/Navigation`, cooked into exported games' packs).

/// What each world keeps for `World.findPath` (worlds are main-actor objects, so a table keyed
/// by identity, checked against a weak reference, stands in for stored properties).
@MainActor
enum NavigationStore {
    final class Entry {
        weak var world: World?
        var grid: NavigationGrid?
        var navMesh: NavMesh?
        /// Baked by the behavior tree system (rebaked the next time the system is added).
        var automatic = false
        var cache: NavigationBakeCache?
        var lastBake: NavMeshBakeReport?

        init(world: World) { self.world = world }
    }

    static var entries: [ObjectIdentifier: Entry] = [:]

    static func entry(_ world: World) -> Entry? {
        guard let entry = entries[ObjectIdentifier(world)] else { return nil }
        guard entry.world === world else { entries[ObjectIdentifier(world)] = nil; return nil }
        return entry
    }

    static func entry(creating world: World) -> Entry {
        if let entry = entry(world) { return entry }
        entries = entries.filter { $0.value.world != nil }
        let entry = Entry(world: world)
        entries[ObjectIdentifier(world)] = entry
        return entry
    }

    /// Forgets the world's grid and navmesh (keeps its cache).
    static func clear(_ world: World) {
        guard let entry = entry(world) else { return }
        entry.grid = nil
        entry.navMesh = nil
        entry.automatic = false
        entry.lastBake = nil
    }
}

extension World {
    /// The navigation grid (nil until one is baked or set). `findPath` uses it when the world
    /// has no `navMesh`.
    public var navigation: NavigationGrid? {
        get { NavigationStore.entry(self)?.grid }
        set {
            let entry = NavigationStore.entry(creating: self)
            entry.grid = newValue
            entry.automatic = false
        }
    }

    /// The navigation mesh `findPath` and behavior trees use (nil until one is baked or set).
    public var navMesh: NavMesh? {
        get { NavigationStore.entry(self)?.navMesh }
        set {
            let entry = NavigationStore.entry(creating: self)
            entry.navMesh = newValue
            entry.automatic = false
        }
    }

    /// What paths are found on: the navmesh when there is one, else the grid.
    public var navigationSurface: (any NavigationSurface)? {
        guard let entry = NavigationStore.entry(self) else { return nil }
        if let mesh = entry.navMesh { return mesh }
        return entry.grid
    }

    /// Where navmesh bakes are cached (nil: not cached). The behavior tree system sets it from
    /// its asset database (the project's Library, or an exported game's pack).
    public var navigationCache: NavigationBakeCache? {
        get { NavigationStore.entry(self)?.cache }
        set { NavigationStore.entry(creating: self).cache = newValue }
    }

    /// The report of the last navmesh bake (`bakeNavMesh`, `bakeNavigation`).
    public var lastNavMeshBake: NavMeshBakeReport? { NavigationStore.entry(self)?.lastBake }

    /// Whether the behavior tree system baked the navigation itself (it rebakes when added again).
    var navigationIsAutomatic: Bool { NavigationStore.entry(self)?.automatic ?? false }

    /// Forgets the grid and the navmesh.
    public func clearNavigation() { NavigationStore.clear(self) }

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

    /// The physics world, body filter, area and settings a bake uses.
    private func bakeInputs(physics: PhysicsWorld?, settings: NavigationSettings?, bounds: AABB?)
        -> (physics: PhysicsWorld, accepts: (BodyID) -> Bool, bounds: AABB, settings: NavigationSettings)? {
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
        return (world, accepts, bounds ?? found.bounds, settings ?? found.settings)
    }

    /// Bakes the navigation grid and (unless the settings turn it off) the navmesh from this
    /// world's static colliders and keeps them (`navigation`, `navMesh`). `physics` defaults
    /// to a temporary physics world built from the `Collider` components; `settings` and
    /// `bounds` default to the `NavigationArea` entity's, else defaults around the static
    /// colliders near the agents. Returns the grid; nil (and nothing changed) when there is
    /// nothing to bake.
    @discardableResult
    public func bakeNavigation(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil) -> NavigationGrid? {
        guard let inputs = bakeInputs(physics: physics, settings: settings, bounds: bounds) else { return nil }
        let grid = NavigationGrid.bake(physics: inputs.physics, bounds: inputs.bounds, settings: inputs.settings, isObstacle: inputs.accepts)
        let report = inputs.settings.navMesh ? makeNavMesh(inputs: inputs, cacheable: physics == nil) : nil
        let entry = NavigationStore.entry(creating: self)
        entry.grid = grid
        entry.navMesh = report?.navMesh
        entry.lastBake = report
        entry.automatic = false
        return grid
    }

    /// A baked grid without keeping it (what `bakeNavigation` bakes).
    public func makeNavigation(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil) -> NavigationGrid? {
        guard let inputs = bakeInputs(physics: physics, settings: settings, bounds: bounds) else { return nil }
        return NavigationGrid.bake(physics: inputs.physics, bounds: inputs.bounds, settings: inputs.settings, isObstacle: inputs.accepts)
    }

    /// Bakes just the navmesh (always, whatever `settings.navMesh` says) and keeps it as
    /// `navMesh`; the report has its polygon count, bake time and warnings. Reads it from
    /// `navigationCache` when the level hasn't changed since it was cached (`useCache`).
    @discardableResult
    public func bakeNavMesh(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil,
                            useCache: Bool = true) -> NavMeshBakeReport? {
        guard let report = makeNavMesh(physics: physics, settings: settings, bounds: bounds, useCache: useCache) else { return nil }
        let entry = NavigationStore.entry(creating: self)
        entry.navMesh = report.navMesh
        entry.lastBake = report
        entry.automatic = false
        return report
    }

    /// A baked navmesh without keeping it (what `bakeNavMesh` bakes).
    public func makeNavMesh(physics: PhysicsWorld? = nil, settings: NavigationSettings? = nil, bounds: AABB? = nil,
                            useCache: Bool = true) -> NavMeshBakeReport? {
        guard let inputs = bakeInputs(physics: physics, settings: settings, bounds: bounds) else { return nil }
        return makeNavMesh(inputs: inputs, cacheable: physics == nil && useCache)
    }

    private func makeNavMesh(inputs: (physics: PhysicsWorld, accepts: (BodyID) -> Bool, bounds: AABB, settings: NavigationSettings),
                             cacheable: Bool) -> NavMeshBakeReport {
        let links = navigationLinks()
        let key = cacheable && navigationCache != nil ? navigationBakeKey(bounds: inputs.bounds, settings: inputs.settings, links: links) : nil
        if let key, let cache = navigationCache, let mesh = cache.load(key: key) {
            return NavMeshBakeReport(navMesh: mesh, seconds: 0, cached: true, warnings: mesh.warnings, walkableSpans: 0,
                                     regionCount: Set(mesh.polygons.map(\.region)).count)
        }
        let report = NavMesh.bake(physics: inputs.physics, bounds: inputs.bounds, settings: inputs.settings, links: links,
                                  isObstacle: inputs.accepts)
        if let key, let cache = navigationCache { cache.store(report.navMesh, key: key) }
        return report
    }

    /// The world's `NavigationLink`s, in world space.
    public func navigationLinks() -> [NavigationLinkPlacement] {
        var out: [NavigationLinkPlacement] = []
        query(NavigationLink.self) { entity, link in
            let m = self.worldMatrix(of: entity)
            let start = Vec3(m.c3.x, m.c3.y, m.c3.z)
            let e = m * Vec4(link.end, 1)
            out.append(NavigationLinkPlacement(start: start, end: Vec3(e.x, e.y, e.z), bidirectional: link.bidirectional, kind: link.kind,
                                               cost: link.cost, radius: link.radius, name: self.get(Name.self, for: entity)?.value ?? ""))
        }
        return out
    }

    /// A key for the navmesh the world's static colliders, `bounds`, `settings` and `links`
    /// bake to: equal keys bake equal navmeshes.
    func navigationBakeKey(bounds: AABB, settings: NavigationSettings, links: [NavigationLinkPlacement]) -> String {
        propagateTransforms()
        var lines: [String] = []
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        query(Collider.self) { entity, collider in
            guard !collider.isTrigger, !self.isNavigationAgent(entity) else { return }
            let m = self.worldMatrix(of: entity)
            let shape = (try? encoder.encode(collider)).map { String(decoding: $0, as: UTF8.self) } ?? ""
            let matrix = [m.c0, m.c1, m.c2, m.c3].flatMap { [$0.x, $0.y, $0.z, $0.w] }.map { String($0.bitPattern, radix: 16) }
            lines.append(shape + "@" + matrix.joined(separator: ","))
        }
        lines.sort()
        let settingsJSON = (try? encoder.encode(settings)).map { String(decoding: $0, as: UTF8.self) } ?? ""
        var head = "navmesh \(NavMesh.formatVersion) \(NavigationBakeCache.bakeVersion)\n\(settingsJSON)\n"
        head += [bounds.min, bounds.max].map { "\($0.x.bitPattern),\($0.y.bitPattern),\($0.z.bitPattern)" }.joined(separator: " ") + "\n"
        for link in links {
            head += "link \(link.start) \(link.end) \(link.bidirectional) \(link.kind.rawValue) \(link.cost) \(link.radius)\n"
        }
        return ContentHash.hex(Data((head + lines.joined(separator: "\n")).utf8))
    }

    /// A walkable path between two world points: on `navMesh` when there is one, else on the
    /// grid (see `NavMesh.findPath`, `NavigationGrid.findPath`); nil without either or a path.
    public func findPath(from start: Vec3, to goal: Vec3, partial: Bool = false) -> [Vec3]? {
        findNavigationPath(from: start, to: goal, partial: partial)?.points
    }

    /// `findPath` with how each segment is crossed (walking, or an off-mesh link's jump, drop or ladder).
    public func findNavigationPath(from start: Vec3, to goal: Vec3, partial: Bool = false) -> NavigationPath? {
        navigationSurface?.navigationPath(from: start, to: goal, partial: partial)
    }
}

/// Baked navmeshes by the key of what they were baked from: files in a folder (the project's
/// `Library/Navigation`), and read-only entries of an asset pack (exported games, which the
/// cooker gives every navmesh in `Library/Navigation`).
public final class NavigationBakeCache: @unchecked Sendable {
    /// Bumped when baking changes, so older cached bakes are baked again.
    public static let bakeVersion = 1
    /// The file extension of cached navmeshes.
    public static let fileExtension = "navmesh"
    /// The folder under the project's Library.
    public static let libraryFolder = "Navigation"
    /// At most this many files stay in a folder (the oldest go).
    public var maxFiles = 64

    public let directory: URL?
    private let packed: (String) -> Data?

    /// A cache in `directory` (created when something is stored).
    public init(directory: URL) {
        self.directory = directory
        packed = { _ in nil }
    }

    /// The navmeshes cooked into `pack` (read-only).
    public init(pack: AssetPack) {
        directory = nil
        packed = { key in
            guard let blob = pack.manifest.navigation?[key] else { return nil }
            return try? pack.bytes(of: blob)
        }
    }

    /// The cache for `assets`: its pack's navmeshes, or its project's `Library/Navigation`.
    @MainActor
    public static func forAssets(_ assets: AssetDatabase) -> NavigationBakeCache {
        if let pack = assets.pack { return NavigationBakeCache(pack: pack) }
        return NavigationBakeCache(directory: assets.project.libraryURL.appendingPathComponent(libraryFolder, isDirectory: true))
    }

    func url(_ key: String) -> URL? { directory?.appendingPathComponent(key + "." + Self.fileExtension) }

    /// The navmesh cached under `key`, if any.
    public func load(key: String) -> NavMesh? {
        let data: Data?
        if let url = url(key) { data = try? Data(contentsOf: url) } else { data = packed(key) }
        guard let data else { return nil }
        return try? JSONDecoder().decode(NavMesh.self, from: data)
    }

    /// Caches `mesh` under `key` (no-op for a pack).
    public func store(_ mesh: NavMesh, key: String) {
        guard let directory, let url = url(key) else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(mesh).write(to: url, options: .atomic)
            prune()
        } catch {
            EngineLog.warning("Navigation: couldn't cache the navmesh in \(directory.path): \(error)")
        }
    }

    /// Every cached navmesh file in a folder, by key.
    public static func files(in directory: URL) -> [String: URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var out: [String: URL] = [:]
        for url in urls where url.pathExtension == fileExtension { out[url.deletingPathExtension().lastPathComponent] = url }
        return out
    }

    private func prune() {
        guard let directory else { return }
        let files = Self.files(in: directory).values
        guard files.count > maxFiles else { return }
        let dated = files.map { url in
            (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
        for (url, _) in dated.sorted(by: { $0.1 < $1.1 }).prefix(files.count - maxFiles) { try? FileManager.default.removeItem(at: url) }
    }
}
