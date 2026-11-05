import Engine
import Foundation

/// The terrain builder tools: `terrain.new`, `.get`, `.set`, `.edit`, `.open`, `.sculpt`, `.paint`, `.scatter`.
@MainActor
public enum EditorTerrainCommands {
    public static let all: [any EditorCommand.Type] = [
        TerrainNewCommand.self,
        TerrainGetCommand.self,
        TerrainSetCommand.self,
        TerrainEditCommand.self,
        TerrainOpenCommand.self,
        TerrainSculptCommand.self,
        TerrainPaintCommand.self,
        TerrainScatterCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A terrain is a heightmap centered on its origin: `size` [x,z] meters, `resolution` height samples per side (3-1025), \
        `heightRange` (meters at full height; heights span 0 to heightRange), `chunkCells` (cells per chunk mesh), `lods` \
        (extra detail meshes per chunk), `collider` (a triangle-mesh collider per chunk), `colliderLod`, `albedoSize`, `seed`, \
        `layers` (each: name, color [r,g,b] 0-1 sRGB, texture (path under Assets/: an image or .proctex), tileSize meters per \
        repeat), `scatter` rules (each: name, asset (a .meshbuild path, or "asset:<id>#mesh/<name>"), material, density \
        (candidate spots per 100 m²), minSlope/maxSlope degrees, minHeight/maxHeight meters, minScale/maxScale, layer (only \
        where this layer is painted), alignToNormal, seed, maxCount), and the data `heights` (base64 UInt16) and `splat` \
        (base64 UInt8 weights per layer). Positions in tools are terrain-space [x,z] meters from the center (x and z each run \
        -size/2 to size/2). Every key is optional; use terrain.sculpt / terrain.paint to change the data rather than writing it.
        """
}

extension EditorSession {
    /// Writes a terrain to "`name`.terrain" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createTerrainAsset(in folder: String, name: String = "New Terrain", terrain: Terrain) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Terrain") else {
            log.error("New Terrain: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".terrain"))
        do {
            let id = try assets.createTerrain(terrain, at: path)
            log.info("Created terrain \(path)")
            return id
        } catch {
            log.error("New Terrain failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.terrain` file.
    public func isTerrainFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == TerrainImporter().name
    }

    /// Replaces the contents of the terrain `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applyTerrain(_ terrain: Terrain, to id: AssetID, label: String = "Edit Terrain") -> [String]? {
        guard let assets, let old = assets.terrain(of: id) else {
            log.error("\(label): \(id) isn't a readable .terrain file")
            return nil
        }
        guard old != terrain else { return [] }
        let command = TerrainFileEditCommand(asset: id, old: old, new: terrain, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes terrain edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct TerrainFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: Terrain
    public let new: Terrain
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: Terrain, new: Terrain, in database: AssetDatabase, label: String = "Edit Terrain") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ terrain: Terrain) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeTerrain(terrain, to: asset)
    }
}

/// Arguments naming a `.terrain` file.
public protocol TerrainTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The terrain named by `target` and its contents.
    func resolveTerrain(_ target: some TerrainTarget, _ title: String) throws -> (AssetID, Terrain) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isTerrainFile(id), let terrain = assets?.terrain(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .terrain file")
        }
        return (id, terrain)
    }
}

/// What the editing tools return (the height and weight data stay in the file).
public struct TerrainResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    public var size: Vec2
    public var resolution: Int
    public var heightRange: Float
    public var chunks: Int
    public var layers: [String]
    public var scatter: [String]
    /// Props each scatter rule places (same order as `scatter`).
    public var scatterCounts: [Int]
    /// Lowest and highest ground in meters.
    public var minHeight: Float
    public var maxHeight: Float
    /// Import problems and unresolved references.
    public var warnings: [String]
    /// Entities placed in the scene (terrain.new with `place`).
    public var entities: [EntityID]?
}

extension TerrainResult {
    @MainActor init(_ id: AssetID, _ terrain: Terrain, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        var t = terrain
        t.normalizeData()
        let heights = t.heightData.map { Float($0) / 65535 * t.heightRange }
        let counts = t.chunkCounts
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, size: t.size, resolution: t.res,
                  heightRange: t.heightRange, chunks: counts.x * counts.z, layers: t.layers.map(\.name), scatter: t.scatter.map(\.name),
                  scatterCounts: t.scatter.map { t.instances(of: $0).count }, minHeight: heights.min() ?? 0, maxHeight: heights.max() ?? 0,
                  warnings: warnings + (record?.importError.map { ["import failed: \($0)"] } ?? []), entities: entities)
    }
}

/// Problems with a terrain's references, found without importing.
@MainActor
enum TerrainCheck {
    static func problems(_ terrain: Terrain, in session: EditorSession) -> [String] {
        var problems: [String] = []
        let names = terrain.layers.map(\.name)
        if Set(names).count != names.count { problems.append("some layers share a name; scatter rules use the first") }
        for layer in terrain.layers where !layer.texture.isEmpty && MeshBuildCheck.resolve(layer.texture, session: session) == nil {
            problems.append("layer '\(layer.name)': no texture asset '\(layer.texture)'")
        }
        for rule in terrain.scatter {
            if rule.asset.isEmpty {
                problems.append("scatter '\(rule.name)' has no asset")
            } else if MeshBuildCheck.resolve(rule.asset.components(separatedBy: "#")[0], session: session) == nil {
                problems.append("scatter '\(rule.name)': no asset '\(rule.asset)'")
            }
            if !rule.layer.isEmpty && !names.contains(rule.layer) { problems.append("scatter '\(rule.name)': no layer named '\(rule.layer)'") }
        }
        return problems
    }
}

/// Terrain-space brush points: [x, z] meters from the terrain's center.
private func requirePoints(_ points: [Vec2], _ title: String) throws {
    guard !points.isEmpty else { throw CommandError.failed("\(title): points is empty; give [x, z] positions in meters from the terrain's center") }
    guard points.count <= 10_000 else { throw CommandError.failed("\(title): at most 10000 points per call") }
}

public enum TerrainNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Terrain" (the file gets ".terrain").
        public var name: String?
        /// Width and depth in meters (default [128, 128]).
        public var size: Vec2?
        /// Height samples per side (default 129; 3...1025).
        public var resolution: Int?
        /// Seeds the starting hills (and scatter) (default 1).
        public var seed: Int?
        /// 0 flat ... 1 rugged (default 0.5).
        public var hilliness: Float?
        /// Meters at full height (default 64).
        public var heightRange: Float?
        /// Also place it in the scene (default false).
        public var place: Bool?
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, size: Vec2? = nil, resolution: Int? = nil, seed: Int? = nil,
                    hilliness: Float? = nil, heightRange: Float? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.size = size
            self.resolution = resolution
            self.seed = seed
            self.hilliness = hilliness
            self.heightRange = heightRange
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "terrain.new"
    public static let title = "New Terrain"
    public static let doc = "Writes a .terrain file in `folder` (default: the Assets root): rolling hills generated from `seed` with grass, rock and dirt layers (grass everywhere), imported as chunk meshes with colliders and a baked albedo, optionally placed in the scene. Then shape it with terrain.sculpt, texture it with terrain.paint, and add props with terrain.scatter. " + EditorTerrainCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        let size = arguments.size ?? Vec2(128, 128)
        guard size.x > 0, size.y > 0, size.x <= 8192, size.y <= 8192 else { throw CommandError.failed("\(title): size must be 0...8192 meters") }
        let resolution = arguments.resolution ?? 129
        guard resolution >= Terrain.minResolution, resolution <= Terrain.maxResolution else {
            throw CommandError.failed("\(title): resolution must be \(Terrain.minResolution)...\(Terrain.maxResolution)")
        }
        let terrain = Terrain.generated(size: size, resolution: resolution, seed: arguments.seed ?? 1,
                                        hilliness: arguments.hilliness ?? 0.5, heightRange: arguments.heightRange ?? 64)
        let id = try session.commands.require(session.createTerrainAsset(in: arguments.folder ?? "", name: arguments.name ?? "New Terrain",
                                                                         terrain: terrain), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), entities: entities, in: session)
    }
}

public enum TerrainGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Also return a grid of heights (meters) this many samples per side, row by row from -z, to see the shape (default none; max 64).
        public var sampleHeights: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, sampleHeights: Int? = nil) {
            self.asset = asset
            self.path = path
            self.sampleHeights = sampleHeights
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var summary: TerrainResult
        public var size: Vec2
        public var resolution: Int
        public var heightRange: Float
        public var chunkCells: Int
        public var lods: Int
        public var collider: Bool
        public var colliderLod: Int
        public var albedoSize: Int
        public var seed: Int
        public var layers: [TerrainLayer]
        public var scatter: [TerrainScatter]
        public var heights: [[Float]]?
    }

    public static let id: CommandID = "terrain.get"
    public static let title = "Get Terrain"
    public static let doc = "Reads a .terrain file: settings, layers and scatter rules (every field, defaults included), a summary (chunks, height range, props per rule, problems), and with `sampleHeights` a coarse grid of heights. The raw height and weight data stay in the file."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, t) = try session.resolveTerrain(arguments, title)
        var grid: [[Float]]?
        if let n = arguments.sampleHeights, n > 0 {
            let n = min(max(n, 2), 64)
            grid = (0..<n).map { j in
                (0..<n).map { i in
                    t.heightAt(x: (Float(i) / Float(n - 1) - 0.5) * t.size.x, z: (Float(j) / Float(n - 1) - 0.5) * t.size.y)
                }
            }
        }
        return Result(summary: TerrainResult(id, t, warnings: TerrainCheck.problems(t, in: session), in: session), size: t.size,
                      resolution: t.res, heightRange: t.heightRange, chunkCells: t.chunkCells, lods: t.lods, collider: t.collider,
                      colliderLod: t.colliderLod, albedoSize: t.albedoSize, seed: t.seed, layers: t.layers, scatter: t.scatter, heights: grid)
    }
}

public enum TerrainSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values (a missing `heights` is flat ground).
        public var terrain: Terrain
        public init(asset: AssetReference? = nil, path: String? = nil, terrain: Terrain) {
            self.asset = asset
            self.path = path
            self.terrain = terrain
        }
    }

    public static let id: CommandID = "terrain.set"
    public static let title = "Set Terrain"
    public static let doc = "Replaces a .terrain file's whole contents (heights included) and reimports it; placed copies update. Undoable. For settings, layers or scatter changes terrain.edit is shorter; sculpt and paint with terrain.sculpt / terrain.paint."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        let (id, _) = try session.resolveTerrain(arguments, title)
        var terrain = arguments.terrain
        terrain.resolution = terrain.res
        terrain.normalizeData()
        _ = try session.commands.require(session.applyTerrain(terrain, to: id, label: title), title)
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), in: session)
    }
}

public enum TerrainEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        /// New size in meters (the heights keep their grid, so the ground stretches).
        public var size: Vec2?
        /// New resolution: the heights and paint are resampled.
        public var resolution: Int?
        /// New height range: heights keep their value in meters (clamped to the range).
        public var heightRange: Float?
        public var chunkCells: Int?
        public var lods: Int?
        public var collider: Bool?
        public var colliderLod: Int?
        public var albedoSize: Int?
        public var seed: Int?
        /// Layers to remove by name (their paint goes to the first remaining layer).
        public var removeLayers: [String]?
        /// Layers to add (a taken name gets " 2"…); they start unpainted.
        public var addLayers: [TerrainLayer]?
        /// Layer name → fields to change; a "name" key renames it (scatter rules follow).
        public var updateLayers: [String: JSONValue]?
        /// Scatter rules to remove by name.
        public var removeScatter: [String]?
        public var addScatter: [TerrainScatter]?
        /// Rule name → fields to change.
        public var updateScatter: [String: JSONValue]?
        public init(asset: AssetReference? = nil, path: String? = nil, size: Vec2? = nil, resolution: Int? = nil, heightRange: Float? = nil,
                    chunkCells: Int? = nil, lods: Int? = nil, collider: Bool? = nil, colliderLod: Int? = nil, albedoSize: Int? = nil,
                    seed: Int? = nil, removeLayers: [String]? = nil, addLayers: [TerrainLayer]? = nil,
                    updateLayers: [String: JSONValue]? = nil, removeScatter: [String]? = nil, addScatter: [TerrainScatter]? = nil,
                    updateScatter: [String: JSONValue]? = nil) {
            self.asset = asset
            self.path = path
            self.size = size
            self.resolution = resolution
            self.heightRange = heightRange
            self.chunkCells = chunkCells
            self.lods = lods
            self.collider = collider
            self.colliderLod = colliderLod
            self.albedoSize = albedoSize
            self.seed = seed
            self.removeLayers = removeLayers
            self.addLayers = addLayers
            self.updateLayers = updateLayers
            self.removeScatter = removeScatter
            self.addScatter = addScatter
            self.updateScatter = updateScatter
        }
    }

    public static let id: CommandID = "terrain.edit"
    public static let title = "Edit Terrain"
    public static let doc = "Changes a .terrain file's settings, layers or scatter rules in one undoable step, in this order: size, resolution (resamples), heightRange, the scalar settings, removeLayers, addLayers, updateLayers (name → fields; \"name\" renames), removeScatter, addScatter, updateScatter. Placed copies update. Heights and paint are changed with terrain.sculpt and terrain.paint."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        let (id, original) = try session.resolveTerrain(arguments, title)
        let terrain = try edited(original, with: arguments)
        _ = try session.commands.require(session.applyTerrain(terrain, to: id, label: title), title)
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), in: session)
    }

    /// `terrain` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ terrain: Terrain, with arguments: Arguments) throws -> Terrain {
        var t = terrain
        t.resolution = t.res
        t.normalizeData()
        if let size = arguments.size {
            guard size.x > 0, size.y > 0, size.x <= 8192, size.y <= 8192 else { throw CommandError.failed("size must be 0...8192 meters") }
            t.size = size
        }
        if let resolution = arguments.resolution, resolution != t.res {
            guard resolution >= Terrain.minResolution, resolution <= Terrain.maxResolution else {
                throw CommandError.failed("resolution must be \(Terrain.minResolution)...\(Terrain.maxResolution)")
            }
            t.resample(to: resolution)
        }
        if let range = arguments.heightRange {
            guard range > 0, range <= 2000 else { throw CommandError.failed("heightRange must be 0...2000") }
            let old = t.heightRange
            t.heightData = t.heightData.map { UInt16(min(max(Float($0) / 65535 * old / range, 0), 1) * 65535) }
            t.heightRange = range
        }
        if let v = arguments.chunkCells { t.chunkCells = min(max(v, 2), 256) }
        if let v = arguments.lods { t.lods = min(max(v, 1), 4) }
        if let v = arguments.collider { t.collider = v }
        if let v = arguments.colliderLod { t.colliderLod = min(max(v, 0), 3) }
        if let v = arguments.albedoSize { t.albedoSize = min(max(v, 0), 2048) }
        if let v = arguments.seed { t.seed = v }

        if let names = arguments.removeLayers, !names.isEmpty {
            let missing = names.filter { name in !t.layers.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No layer named \(missing.joined(separator: ", "))") }
            t.removeLayers(Set(names))
        }
        for var layer in arguments.addLayers ?? [] {
            layer.name = uniqueName(layer.name, among: t.layers.map(\.name))
            t.layers.append(layer)
        }
        t.normalizeData()
        for (name, changes) in (arguments.updateLayers ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = t.layers.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No layer named \(name)") }
            let updated = try merged(t.layers[index], changes, "updateLayers[\(name)]")
            if updated.name != name {
                guard !t.layers.contains(where: { $0.name == updated.name }) else { throw CommandError.failed("A layer is already named \(updated.name)") }
                for i in t.scatter.indices where t.scatter[i].layer == name { t.scatter[i].layer = updated.name }
            }
            t.layers[index] = updated
        }

        if let names = arguments.removeScatter {
            let missing = names.filter { name in !t.scatter.contains { $0.name == name } }
            guard missing.isEmpty else { throw CommandError.failed("No scatter rule named \(missing.joined(separator: ", "))") }
            t.scatter.removeAll { names.contains($0.name) }
        }
        for var rule in arguments.addScatter ?? [] {
            rule.name = uniqueName(rule.name, among: t.scatter.map(\.name))
            t.scatter.append(rule)
        }
        for (name, changes) in (arguments.updateScatter ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = t.scatter.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No scatter rule named \(name)") }
            t.scatter[index] = try merged(t.scatter[index], changes, "updateScatter[\(name)]")
        }
        return t
    }

    static func uniqueName(_ base: String, among names: [String]) -> String {
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// `value` with the fields of `changes` replaced.
    static func merged<T: Codable>(_ value: T, _ changes: JSONValue, _ label: String) throws -> T {
        guard case .object(let fields) = changes else { throw CommandError.failed("\(label) must be an object of fields") }
        guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) else { return value }
        for (key, v) in fields { current[key] = v }
        do { return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
            throw CommandError.failed("\(label): \(error)")
        }
    }
}

extension Terrain {
    /// Resamples heights and paint to `resolution` samples per side (bilinear heights, nearest paint).
    public mutating func resample(to resolution: Int) {
        normalizeData()
        let source = self
        self.resolution = min(max(resolution, Self.minResolution), Self.maxResolution)
        let n = res
        heightData = [UInt16](repeating: 0, count: n * n)
        splatData = layers.map { _ in [UInt8](repeating: 0, count: n * n) }
        for z in 0..<n {
            for x in 0..<n {
                let p = position(x: x, z: z)
                heightData[z * n + x] = UInt16(min(max(source.heightAt(x: p.x, z: p.y) / max(heightRange, 0.001), 0), 1) * 65535)
                for l in layers.indices { splatData[l][z * n + x] = UInt8(source.weightAt(layer: l, x: p.x, z: p.y) * 255 + 0.5) }
            }
        }
    }

    /// Removes layers by name; their paint goes to the first remaining layer.
    public mutating func removeLayers(_ names: Set<String>) {
        normalizeData()
        let keep = layers.indices.filter { !names.contains(layers[$0].name) }
        guard !keep.isEmpty else {
            layers = []
            splatData = []
            return
        }
        var data = keep.map { splatData[$0] }
        for i in layers.indices where names.contains(layers[i].name) {
            for k in data[0].indices { data[0][k] = UInt8(min(Int(data[0][k]) + Int(splatData[i][k]), 255)) }
        }
        layers = keep.map { layers[$0] }
        splatData = data
    }
}

public enum TerrainOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "terrain.open"
    public static let title = "Open in Terrain Builder"
    public static let doc = "Opens a .terrain file in the editor's Terrain Builder tab (a viewport showing just the terrain, brush tools you drag over it, and the layers and scatter forms) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"terrainBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveTerrain(arguments, title)
        session.openTerrain = id
        session.onOpenTerrain?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum TerrainSculptCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        /// raise, lower, smooth, flatten or noise.
        public var brush: TerrainBrush
        /// [x, z] meters from the terrain's center, applied in order (drag a stroke as several points).
        public var points: [Vec2]
        /// Meters (default 8).
        public var radius: Float?
        /// raise/lower/noise: meters per point at the center; smooth/flatten: 0...1 blend (default 0.5).
        public var strength: Float?
        /// 0 hard edge ... 1 smooth dome (default 0.7).
        public var falloff: Float?
        /// flatten: the target height in meters (default: the height at the first point).
        public var height: Float?
        public init(asset: AssetReference? = nil, path: String? = nil, brush: TerrainBrush, points: [Vec2], radius: Float? = nil,
                    strength: Float? = nil, falloff: Float? = nil, height: Float? = nil) {
            self.asset = asset
            self.path = path
            self.brush = brush
            self.points = points
            self.radius = radius
            self.strength = strength
            self.falloff = falloff
            self.height = height
        }
    }

    public static let id: CommandID = "terrain.sculpt"
    public static let title = "Sculpt Terrain"
    public static let doc = "Applies a brush (raise, lower, smooth, flatten, noise) at `points` ([x,z] meters from the terrain's center) to a .terrain file's heights, in one undoable step, and reimports it (chunks, colliders and scatter follow). `radius` meters, `strength` (raise/lower/noise: meters per point; smooth/flatten: 0-1), `falloff` 0-1, `height` for flatten."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        try requirePoints(arguments.points, title)
        let (id, original) = try session.resolveTerrain(arguments, title)
        var terrain = original
        terrain.resolution = terrain.res
        terrain.sculpt(arguments.brush, at: arguments.points, radius: arguments.radius ?? 8, strength: arguments.strength ?? 0.5,
                       falloff: arguments.falloff ?? 0.7, height: arguments.height)
        _ = try session.commands.require(session.applyTerrain(terrain, to: id, label: title), title)
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), in: session)
    }
}

public enum TerrainPaintCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TerrainTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The layer's name.
        public var layer: String
        public var points: [Vec2]
        public var radius: Float?
        /// 0...1: how much of the missing weight each point adds at its center (default 0.8).
        public var strength: Float?
        public var falloff: Float?
        /// Remove the layer's paint instead (the other layers take over).
        public var erase: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, layer: String, points: [Vec2], radius: Float? = nil,
                    strength: Float? = nil, falloff: Float? = nil, erase: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.layer = layer
            self.points = points
            self.radius = radius
            self.strength = strength
            self.falloff = falloff
            self.erase = erase
        }
    }

    public static let id: CommandID = "terrain.paint"
    public static let title = "Paint Terrain"
    public static let doc = "Paints a texture layer (by name) at `points` ([x,z] meters from the terrain's center) onto a .terrain file's splat map in one undoable step; other layers give way so weights sum to 1. `radius` meters, `strength` 0-1, `falloff` 0-1, `erase` removes the layer's paint. Add layers with terrain.edit addLayers (an image or .proctex texture, or a flat color)."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        try requirePoints(arguments.points, title)
        let (id, original) = try session.resolveTerrain(arguments, title)
        var terrain = original
        terrain.resolution = terrain.res
        guard let index = terrain.layerIndex(named: arguments.layer) else {
            throw CommandError.failed("\(title): no layer named '\(arguments.layer)' (layers: \(terrain.layers.map(\.name).joined(separator: ", ")))")
        }
        terrain.paint(layer: index, at: arguments.points, radius: arguments.radius ?? 8, strength: arguments.strength ?? 0.8,
                      falloff: arguments.falloff ?? 0.7, erase: arguments.erase ?? false)
        _ = try session.commands.require(session.applyTerrain(terrain, to: id, label: title), title)
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), in: session)
    }
}

public enum TerrainScatterCommand: EditorCommand {
    /// The placement rules of a scatter (all optional).
    public struct Rules: Codable, Equatable, Sendable {
        public var minSlope: Float?
        public var maxSlope: Float?
        public var minHeight: Float?
        public var maxHeight: Float?
        public var minScale: Float?
        public var maxScale: Float?
        /// Only where this layer is painted.
        public var layer: String?
        public var alignToNormal: Bool?
        public var seed: Int?
        public var maxCount: Int?
        public init(minSlope: Float? = nil, maxSlope: Float? = nil, minHeight: Float? = nil, maxHeight: Float? = nil, minScale: Float? = nil,
                    maxScale: Float? = nil, layer: String? = nil, alignToNormal: Bool? = nil, seed: Int? = nil, maxCount: Int? = nil) {
            self.minSlope = minSlope
            self.maxSlope = maxSlope
            self.minHeight = minHeight
            self.maxHeight = maxHeight
            self.minScale = minScale
            self.maxScale = maxScale
            self.layer = layer
            self.alignToNormal = alignToNormal
            self.seed = seed
            self.maxCount = maxCount
        }
    }

    public struct Arguments: Codable, Equatable, Sendable {
        /// The .terrain file.
        public var terrain: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        /// The prop to scatter: a .meshbuild path under Assets/, or "asset:<id>#mesh/<name>".
        public var asset: String?
        /// A material for a mesh reference.
        public var material: String?
        /// Candidate spots per 100 m² (default 5).
        public var density: Float?
        public var rules: Rules?
        /// The rule's name; a rule with that name is replaced (default: the prop's file name).
        public var name: String?
        /// Remove the rules with these names (or every rule when "*" is listed) before adding.
        public var remove: [String]?
        public init(terrain: AssetReference? = nil, path: String? = nil, asset: String? = nil, material: String? = nil, density: Float? = nil,
                    rules: Rules? = nil, name: String? = nil, remove: [String]? = nil) {
            self.terrain = terrain
            self.path = path
            self.asset = asset
            self.material = material
            self.density = density
            self.rules = rules
            self.name = name
            self.remove = remove
        }
    }

    struct Target: TerrainTarget {
        var asset: AssetReference?
        var path: String?
    }

    public static let id: CommandID = "terrain.scatter"
    public static let title = "Scatter on Terrain"
    public static let doc = "Adds (or replaces, by `name`) a scatter rule on a .terrain file: `terrain` (or `path`) names the terrain; `asset` is the prop to scatter (a .meshbuild path such as \"Models/pine.meshbuild\", or \"asset:<id>#mesh/<name>\" with `material`); `density` is candidate spots per 100 m²; `rules` limit where props stand (minSlope/maxSlope degrees, minHeight/maxHeight meters, layer, minScale/maxScale, alignToNormal, seed, maxCount). `remove` deletes rules by name first. Props are drawn instanced. Returns how many props each rule places."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TerrainResult {
        let (id, original) = try session.resolveTerrain(Target(asset: arguments.terrain, path: arguments.path), title)
        let terrain = try scattered(original, with: arguments)
        _ = try session.commands.require(session.applyTerrain(terrain, to: id, label: title), title)
        return TerrainResult(id, terrain, warnings: TerrainCheck.problems(terrain, in: session), in: session)
    }

    /// `terrain` with the scatter change applied (pure, for tests and the UI).
    public static func scattered(_ terrain: Terrain, with arguments: Arguments) throws -> Terrain {
        var t = terrain
        if let names = arguments.remove {
            if names.contains("*") { t.scatter = [] } else { t.scatter.removeAll { names.contains($0.name) } }
        }
        guard let prop = arguments.asset else {
            if arguments.remove == nil { throw CommandError.failed("\(title): give `asset` (what to scatter) or `remove`") }
            return t
        }
        let stem = ((prop as NSString).lastPathComponent as NSString).deletingPathExtension
        let name = arguments.name ?? (stem.isEmpty || prop.hasPrefix("asset:") ? "Scatter" : stem)
        var rule = t.scatter.first { $0.name == name } ?? TerrainScatter(name: name)
        rule.asset = prop
        if let v = arguments.material { rule.material = v }
        if let v = arguments.density { rule.density = max(v, 0) }
        if let r = arguments.rules {
            if let v = r.minSlope { rule.minSlope = v }
            if let v = r.maxSlope { rule.maxSlope = v }
            if let v = r.minHeight { rule.minHeight = v }
            if let v = r.maxHeight { rule.maxHeight = v }
            if let v = r.minScale { rule.minScale = max(v, 0.001) }
            if let v = r.maxScale { rule.maxScale = max(v, 0.001) }
            if let v = r.layer { rule.layer = v }
            if let v = r.alignToNormal { rule.alignToNormal = v }
            if let v = r.seed { rule.seed = v }
            if let v = r.maxCount { rule.maxCount = min(max(v, 0), Terrain.maxScatterInstances) }
        }
        if !rule.layer.isEmpty && t.layerIndex(named: rule.layer) == nil {
            throw CommandError.failed("\(title): no layer named '\(rule.layer)' (layers: \(t.layers.map(\.name).joined(separator: ", ")))")
        }
        if let i = t.scatter.firstIndex(where: { $0.name == name }) { t.scatter[i] = rule } else { t.scatter.append(rule) }
        return t
    }
}
