import Engine
import Foundation

/// The grid map builder tools: `gridMap.new`, `.get`, `.set`, `.edit`, `.open`, `.paint`, `.fill`, `.erase`.
@MainActor
public enum EditorGridMapCommands {
    public static let all: [any EditorCommand.Type] = [
        GridMapNewCommand.self,
        GridMapGetCommand.self,
        GridMapSetCommand.self,
        GridMapEditCommand.self,
        GridMapOpenCommand.self,
        GridMapPaintCommand.self,
        GridMapFillCommand.self,
        GridMapEraseCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A grid map is a level built from modular pieces on a grid: `cellSize` [x, floor height, z] meters, `chunkSize` (cells per \
        chunk side; one merged collider per chunk and floor), `collider`, `layers` (default floor, walls, props; one piece per cell \
        per layer), `pieces` (the library; each: name, asset (a .meshbuild, .gltf/.glb/.obj model or .prefab path under Assets/, or \
        "asset:<id>#mesh/<name>" with `material`), footprint [w, d] cells, size [x,y,z] collision box meters (0: footprint by one \
        floor), offset [x,y,z] pivot meters, rotation degrees (fixes how the model faces), scale, layer (default layer), collider \
        (auto, mesh, box, none), join (auto-joining: single, end, straight, corner, tee, cross piece names, plus joinsWith)) and \
        `cells` (each: at [x, y, z] (y is the floor), piece, layer, rotation 0/90/180/270, flipX, flipZ). Cell (x,y,z) spans \
        x*cellSize.x...(x+1)*cellSize.x and z likewise, standing on y*cellSize.y; a piece is centered on its footprint, which runs \
        from the anchor toward +x and +z. An auto-joining piece becomes the variant that fits its neighbors on the same floor and \
        layer, turned to face them (variants are authored connecting toward +x (end), +x/-x (straight), +x/+z (corner), \
        +x/-x/+z (tee)). Every key is optional.
        """
}

extension EditorSession {
    /// Writes a grid map to "`name`.gridmap" (or "… 2") in `folder`. With `starterFolder` the
    /// starter piece mesh builds are written there first (`GridMap.starterBuilds`). Returns its id.
    @discardableResult
    public func createGridMapAsset(in folder: String, name: String = "New GridMap", map: GridMap, writeStarterPieces: Bool = false) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New GridMap") else {
            log.error("New GridMap: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".gridmap"))
        var map = map
        do {
            if writeStarterPieces {
                let stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
                let pieceFolder = assets.uniquePath(Self.join(folder, stem + " Pieces"))
                let directory = assets.project.url(forAssetPath: pieceFolder)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                for (piece, build) in GridMap.starterBuilds(cellSize: map.cellSize) {
                    try build.fileData().write(to: directory.appendingPathComponent(piece + ".meshbuild"), options: .atomic)
                }
                let starter = GridMap.starterPieces(folder: pieceFolder)
                map.pieces = starter + map.pieces.filter { piece in !starter.contains { $0.name == piece.name } }
            }
            let id = try assets.createGridMap(map, at: path)
            log.info("Created grid map \(path)")
            return id
        } catch {
            log.error("New GridMap failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.gridmap` file.
    public func isGridMapFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == GridMapImporter().name
    }

    /// Replaces the contents of the grid map `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applyGridMap(_ map: GridMap, to id: AssetID, label: String = "Edit GridMap") -> [String]? {
        guard let assets, let old = assets.gridMap(of: id) else {
            log.error("\(label): \(id) isn't a readable .gridmap file")
            return nil
        }
        guard old != map else { return [] }
        let command = GridMapFileEditCommand(asset: id, old: old, new: map, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes grid map edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct GridMapFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: GridMap
    public let new: GridMap
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: GridMap, new: GridMap, in database: AssetDatabase, label: String = "Edit GridMap") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ map: GridMap) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeGridMap(map, to: asset)
    }
}

/// Arguments naming a `.gridmap` file.
public protocol GridMapTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The grid map named by `target` and its contents.
    func resolveGridMap(_ target: some GridMapTarget, _ title: String) throws -> (AssetID, GridMap) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isGridMapFile(id), let map = assets?.gridMap(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .gridmap file")
        }
        return (id, map)
    }
}

/// What the editing tools return (the cells stay in the file; gridMap.get lists them).
public struct GridMapResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    public var cellSize: Vec3
    public var layers: [String]
    /// The library's piece names.
    public var pieces: [String]
    public var cells: Int
    /// Floors that have cells.
    public var floors: [Int]
    /// The smallest and largest covered cells ([x, y, z]); nil when empty.
    public var min: GridCoord?
    public var max: GridCoord?
    /// Cells painted or erased by this call.
    public var changed: Int?
    /// Import problems and unresolved references.
    public var warnings: [String]
    /// Entities placed in the scene (gridMap.new with `place`).
    public var entities: [EntityID]?
}

extension GridMapResult {
    @MainActor init(_ id: AssetID, _ map: GridMap, changed: Int? = nil, warnings: [String], entities: [EntityID]? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        let bounds = map.bounds
        var all = warnings
        for w in record?.importError.map({ ["import failed: \($0)"] }) ?? [] where !all.contains(w) { all.append(w) }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, cellSize: map.cellSize, layers: map.layerNames,
                  pieces: map.pieces.map(\.name), cells: map.cells.count, floors: map.floors, min: bounds?.min, max: bounds?.max,
                  changed: changed, warnings: all, entities: entities)
    }
}

/// Problems with a grid map, found without importing.
@MainActor
enum GridMapCheck {
    static func problems(_ map: GridMap, in session: EditorSession) -> [String] {
        var problems: [String] = []
        let names = map.pieces.map(\.name)
        let known = Set(names)
        if known.count != names.count { problems.append("some pieces share a name; cells use the first") }
        for piece in map.pieces {
            if piece.asset.isEmpty {
                if piece.join == nil { problems.append("piece '\(piece.name)' has no asset") }
            } else if MeshBuildCheck.resolve(piece.asset.components(separatedBy: "#")[0], session: session) == nil {
                problems.append("piece '\(piece.name)': no asset '\(piece.asset)'")
            }
            if !piece.layer.isEmpty && !map.layerNames.contains(piece.layer) {
                problems.append("piece '\(piece.name)': no layer named '\(piece.layer)'")
            }
            if let join = piece.join {
                for name in join.variants + join.joinsWith where !known.contains(name) {
                    problems.append("auto piece '\(piece.name)': no piece named '\(name)'")
                }
            }
        }
        var unknown = Set<String>(), badLayers = Set<String>()
        for cell in map.cells {
            if !known.contains(cell.piece) { unknown.insert(cell.piece) }
            if !cell.layer.isEmpty && !map.layerNames.contains(cell.layer) { badLayers.insert(cell.layer) }
        }
        for name in unknown.sorted() { problems.append("cells use a piece that isn't in the library: '\(name)'") }
        for name in badLayers.sorted() { problems.append("cells use a layer that isn't in the list: '\(name)'") }
        return problems
    }

    /// `problems` plus the import's warnings, without repeats.
    static func all(_ map: GridMap, imported: [String], in session: EditorSession) -> [String] {
        var out = problems(map, in: session)
        for w in imported where !out.contains(w) { out.append(w) }
        return out
    }
}

private func requireCells(_ cells: [GridCoord], _ title: String) throws {
    guard !cells.isEmpty else { throw CommandError.failed("\(title): cells is empty; give [x, y, z] cells (y is the floor)") }
    guard cells.count <= 100_000 else { throw CommandError.failed("\(title): at most 100000 cells per call") }
}

private func requirePiece(_ name: String, in map: GridMap, _ title: String) throws {
    guard map.piece(named: name) != nil else {
        throw CommandError.failed("\(title): no piece named '\(name)' (pieces: \(map.pieces.map(\.name).joined(separator: ", ")))")
    }
}

private func requireLayer(_ layer: String?, in map: GridMap, _ title: String) throws {
    if let layer, !layer.isEmpty, !map.layerNames.contains(layer) {
        throw CommandError.failed("\(title): no layer named '\(layer)' (layers: \(map.layerNames.joined(separator: ", ")))")
    }
}

public enum GridMapNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New GridMap" (the file gets ".gridmap").
        public var name: String?
        /// Meters per cell: x, floor height, z (default [2, 3, 2]).
        public var cellSize: Vec3?
        public var chunkSize: Int?
        public var layers: [String]?
        /// Pieces for the library (a piece left named "Piece" takes its asset's file name).
        public var library: [GridPiece]?
        /// Shortcut: asset paths that each become a piece named after the file.
        public var assets: [String]?
        /// Also write the starter pieces (floor, auto-joining walls, crate, pillar) as mesh builds in
        /// "<name> Pieces/" (default: true when no library or assets are given).
        public var starter: Bool?
        /// Also place it in the scene (default false).
        public var place: Bool?
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, cellSize: Vec3? = nil, chunkSize: Int? = nil, layers: [String]? = nil,
                    library: [GridPiece]? = nil, assets: [String]? = nil, starter: Bool? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.cellSize = cellSize
            self.chunkSize = chunkSize
            self.layers = layers
            self.library = library
            self.assets = assets
            self.starter = starter
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "gridMap.new"
    public static let title = "New GridMap"
    public static let doc = "Writes a .gridmap file in `folder` (default: the Assets root) with a piece library: `library` pieces, `assets` paths (each a piece named after its file), and unless a library is given the starter pieces (Floor, auto-joining Wall with its Wall Single/End/Straight/Corner/Tee/Cross variants, Crate, Pillar) written as mesh builds next to it. Optionally places it in the scene. Then paint with gridMap.paint, gridMap.fill and gridMap.erase. " + EditorGridMapCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        var map = GridMap()
        if let size = arguments.cellSize {
            guard size.x > 0, size.y > 0, size.z > 0, size.x <= 1000, size.y <= 1000, size.z <= 1000 else {
                throw CommandError.failed("\(title): cellSize must be 0...1000 meters on each axis")
            }
            map.cellSize = size
        }
        if let v = arguments.chunkSize { map.chunkSize = Swift.min(Swift.max(v, 1), 256) }
        if let layers = arguments.layers, !layers.isEmpty { map.layers = layers }
        var pieces = arguments.library ?? []
        for path in arguments.assets ?? [] { pieces.append(GridPiece(asset: path)) }
        for i in pieces.indices where pieces[i].name == GridPiece().name && !pieces[i].asset.isEmpty && !pieces[i].asset.hasPrefix("asset:") {
            pieces[i].name = ((pieces[i].asset as NSString).lastPathComponent as NSString).deletingPathExtension
        }
        var unique: [GridPiece] = []
        for var piece in pieces {
            piece.name = GridMapEditCommand.uniqueName(piece.name, among: unique.map(\.name))
            unique.append(piece)
        }
        map.pieces = unique
        let starter = arguments.starter ?? (arguments.library == nil && arguments.assets == nil)
        let id = try session.commands.require(session.createGridMapAsset(in: arguments.folder ?? "", name: arguments.name ?? "New GridMap",
                                                                         map: map, writeStarterPieces: starter), title)
        let written = session.assets?.gridMap(of: id) ?? map
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return GridMapResult(id, written, warnings: GridMapCheck.problems(written, in: session), entities: entities, in: session)
    }
}

public enum GridMapGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Only list cells on this floor.
        public var floor: Int?
        /// At most this many cells are listed (default 500; 0 lists none).
        public var cellLimit: Int?
        /// Also draw this floor as text rows (one per z, -z first; each cell the first letter of its top-layer piece, "." empty).
        public var mapFloor: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, floor: Int? = nil, cellLimit: Int? = nil, mapFloor: Int? = nil) {
            self.asset = asset
            self.path = path
            self.floor = floor
            self.cellLimit = cellLimit
            self.mapFloor = mapFloor
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var summary: GridMapResult
        public var cellSize: Vec3
        public var chunkSize: Int
        public var collider: Bool
        public var layers: [String]
        public var pieces: [GridPiece]
        public var cells: [GridCell]
        /// True when more cells match than were listed.
        public var truncated: Bool
        /// The rows of `mapFloor`, and the x and z of its first cell.
        public var map: [String]?
        public var mapOrigin: GridCoord?
    }

    public static let id: CommandID = "gridMap.get"
    public static let title = "Get GridMap"
    public static let doc = "Reads a .gridmap file: settings, the piece library (every field, defaults included), the cells (optionally one `floor`, up to `cellLimit`), a summary (floors, bounds, problems), and with `mapFloor` a text picture of one floor."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, map) = try session.resolveGridMap(arguments, title)
        let matching = map.cells.filter { arguments.floor == nil || $0.at.y == arguments.floor }
        let limit = Swift.max(arguments.cellLimit ?? 500, 0)
        var rows: [String]?
        var origin: GridCoord?
        if let floor = arguments.mapFloor, let bounds = map.bounds {
            var top: [GridCoord: String] = [:]
            let order = map.layerNames
            var rank: [GridCoord: Int] = [:]
            for cell in map.cells where cell.at.y == floor {
                let r = order.firstIndex(of: map.layer(of: cell)) ?? 0
                for c in map.covered(by: cell) where (rank[c] ?? -1) <= r {
                    rank[c] = r
                    top[c] = String(cell.piece.first ?? "?")
                }
            }
            let x0 = bounds.min.x, x1 = Swift.min(bounds.max.x, x0 + 127), z0 = bounds.min.z, z1 = Swift.min(bounds.max.z, z0 + 127)
            rows = (z0...z1).map { z in (x0...x1).map { x in top[GridCoord(x, floor, z)] ?? "." }.joined() }
            origin = GridCoord(x0, floor, z0)
        }
        return Result(summary: GridMapResult(id, map, warnings: GridMapCheck.problems(map, in: session), in: session), cellSize: map.cellSize,
                      chunkSize: map.chunk, collider: map.collider, layers: map.layerNames, pieces: map.pieces,
                      cells: Array(matching.prefix(limit)), truncated: matching.count > limit, map: rows, mapOrigin: origin)
    }
}

public enum GridMapSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var map: GridMap
        public init(asset: AssetReference? = nil, path: String? = nil, map: GridMap) {
            self.asset = asset
            self.path = path
            self.map = map
        }
    }

    public static let id: CommandID = "gridMap.set"
    public static let title = "Set GridMap"
    public static let doc = "Replaces a .gridmap file's whole contents (library and cells) and reimports it; placed copies update. Undoable. For library or settings changes gridMap.edit is shorter; paint with gridMap.paint / gridMap.fill / gridMap.erase."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        let (id, _) = try session.resolveGridMap(arguments, title)
        guard arguments.map.cells.count <= GridMap.maxCells else { throw CommandError.failed("\(title): at most \(GridMap.maxCells) cells") }
        let warnings = try session.commands.require(session.applyGridMap(arguments.map, to: id, label: title), title)
        return GridMapResult(id, arguments.map, warnings: GridMapCheck.all(arguments.map, imported: warnings, in: session), in: session)
    }
}

public enum GridMapEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        public var cellSize: Vec3?
        public var chunkSize: Int?
        public var collider: Bool?
        /// The new layer list (cells on a removed layer move to the first layer).
        public var layers: [String]?
        /// Pieces to remove by name (their cells go too).
        public var removePieces: [String]?
        /// Pieces to add (a taken name gets " 2"…).
        public var addPieces: [GridPiece]?
        /// Piece name → fields to change; a "name" key renames it (cells and join links follow).
        public var updatePieces: [String: JSONValue]?
        /// Remove every cell (or with `clearFloor` just that floor's) before anything else.
        public var clear: Bool?
        public var clearFloor: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, cellSize: Vec3? = nil, chunkSize: Int? = nil, collider: Bool? = nil,
                    layers: [String]? = nil, removePieces: [String]? = nil, addPieces: [GridPiece]? = nil,
                    updatePieces: [String: JSONValue]? = nil, clear: Bool? = nil, clearFloor: Int? = nil) {
            self.asset = asset
            self.path = path
            self.cellSize = cellSize
            self.chunkSize = chunkSize
            self.collider = collider
            self.layers = layers
            self.removePieces = removePieces
            self.addPieces = addPieces
            self.updatePieces = updatePieces
            self.clear = clear
            self.clearFloor = clearFloor
        }
    }

    public static let id: CommandID = "gridMap.edit"
    public static let title = "Edit GridMap"
    public static let doc = "Changes a .gridmap file's settings and piece library in one undoable step, in this order: clear / clearFloor, cellSize, chunkSize, collider, layers, removePieces (their cells go too), addPieces, updatePieces (name → fields; \"name\" renames and cells follow). Placed copies update. Cells are painted with gridMap.paint, gridMap.fill and gridMap.erase."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        let (id, original) = try session.resolveGridMap(arguments, title)
        let map = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyGridMap(map, to: id, label: title), title)
        return GridMapResult(id, map, warnings: GridMapCheck.all(map, imported: warnings, in: session), in: session)
    }

    /// `map` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ map: GridMap, with arguments: Arguments) throws -> GridMap {
        var m = map
        if let floor = arguments.clearFloor { m.cells.removeAll { $0.at.y == floor } }
        if arguments.clear == true { m.cells = [] }
        if let size = arguments.cellSize {
            guard size.x > 0, size.y > 0, size.z > 0, size.x <= 1000, size.y <= 1000, size.z <= 1000 else {
                throw CommandError.failed("cellSize must be 0...1000 meters on each axis")
            }
            m.cellSize = size
        }
        if let v = arguments.chunkSize { m.chunkSize = Swift.min(Swift.max(v, 1), 256) }
        if let v = arguments.collider { m.collider = v }
        if let layers = arguments.layers {
            let cleaned = layers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            guard !cleaned.isEmpty, Set(cleaned).count == cleaned.count else { throw CommandError.failed("layers must be distinct, non-empty names") }
            let old = m
            m.layers = cleaned
            for i in m.cells.indices {
                let layer = old.layer(of: m.cells[i])
                m.cells[i].layer = cleaned.contains(layer) ? layer : cleaned[0]
            }
            for i in m.pieces.indices where !m.pieces[i].layer.isEmpty && !cleaned.contains(m.pieces[i].layer) { m.pieces[i].layer = "" }
        }
        if let names = arguments.removePieces, !names.isEmpty {
            let missing = names.filter { m.piece(named: $0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("No piece named \(missing.joined(separator: ", "))") }
            m.pieces.removeAll { names.contains($0.name) }
            m.cells.removeAll { names.contains($0.piece) }
        }
        for var piece in arguments.addPieces ?? [] {
            if piece.name == GridPiece().name, !piece.asset.isEmpty, !piece.asset.hasPrefix("asset:") {
                piece.name = ((piece.asset as NSString).lastPathComponent as NSString).deletingPathExtension
            }
            piece.name = uniqueName(piece.name, among: m.pieces.map(\.name))
            m.pieces.append(piece)
        }
        for (name, changes) in (arguments.updatePieces ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = m.pieceIndex(named: name) else { throw CommandError.failed("No piece named \(name)") }
            let updated = try TerrainEditCommand.merged(m.pieces[index], changes, "updatePieces[\(name)]")
            if updated.name != name {
                guard m.piece(named: updated.name) == nil, !updated.name.isEmpty else {
                    throw CommandError.failed("A piece is already named \(updated.name)")
                }
                m.renamePiece(name, to: updated.name)
            }
            m.pieces[index] = updated
        }
        return m
    }

    static func uniqueName(_ base: String, among names: [String]) -> String { TerrainEditCommand.uniqueName(base, among: names) }
}

public enum GridMapOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The floor to edit (default: the lowest painted floor).
        public var floor: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, floor: Int? = nil) {
            self.asset = asset
            self.path = path
            self.floor = floor
        }
    }

    public static let id: CommandID = "gridMap.open"
    public static let title = "Open in GridMap Builder"
    public static let doc = "Opens a .gridmap file in the editor's GridMap Builder tab (a viewport showing the map with the edited floor's grid, the floors below faded and the ones above hidden, brushes you click or drag, and the piece library form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"gridMapBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, map) = try session.resolveGridMap(arguments, title)
        session.openGridMap = id
        session.openGridMapFloor = arguments.floor ?? map.floors.first ?? 0
        session.onOpenGridMap?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

/// How gridMap.paint reads its `cells`.
public enum GridMapBrush: String, Codable, CaseIterable, Sendable {
    /// Every listed cell.
    case cells
    /// A line between the first two cells (on the first one's floor).
    case line
    /// The filled rectangle with the first two cells as corners.
    case rect
    /// Just the edge of that rectangle.
    case outline
    /// Flood fill from the first cell: the connected cells holding the same piece (or, from an empty
    /// cell, the empty area enclosed by other cells on that floor).
    case fill
}

extension GridMap {
    /// The cells a brush covers, from the cells given.
    public func brushCells(_ brush: GridMapBrush, _ cells: [GridCoord], layer: String) throws -> [GridCoord] {
        switch brush {
        case .cells: return cells
        case .line: return GridMap.line(from: cells[0], to: cells.count > 1 ? cells[1] : cells[0])
        case .rect: return GridMap.rectangle(from: cells[0], to: cells.count > 1 ? cells[1] : cells[0])
        case .outline: return GridMap.rectangle(from: cells[0], to: cells.count > 1 ? cells[1] : cells[0], outline: true)
        case .fill: return try floodRegion(from: cells[0], layer: layer)
        }
    }
}

public enum GridMapPaintCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The piece to paint (a name in the library).
        public var piece: String?
        /// Or paint a random piece of this set at each cell.
        public var pieces: [String]?
        /// [x, y, z] cells (y is the floor); how they are read depends on `brush`.
        public var cells: [GridCoord]
        /// cells (default), line, rect, outline or fill.
        public var brush: GridMapBrush?
        /// Degrees about y: 0, 90, 180 or 270 (default 0).
        public var rotation: Int?
        public var flipX: Bool?
        public var flipZ: Bool?
        /// The layer (default: the piece's).
        public var layer: String?
        /// For `pieces`: the random seed (default 1) and whether each cell gets a random quarter turn.
        public var seed: Int?
        public var randomRotation: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, piece: String? = nil, pieces: [String]? = nil, cells: [GridCoord],
                    brush: GridMapBrush? = nil, rotation: Int? = nil, flipX: Bool? = nil, flipZ: Bool? = nil, layer: String? = nil,
                    seed: Int? = nil, randomRotation: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.piece = piece
            self.pieces = pieces
            self.cells = cells
            self.brush = brush
            self.rotation = rotation
            self.flipX = flipX
            self.flipZ = flipZ
            self.layer = layer
            self.seed = seed
            self.randomRotation = randomRotation
        }
    }

    public static let id: CommandID = "gridMap.paint"
    public static let title = "Paint GridMap"
    public static let doc = "Paints a piece (or a random one of `pieces`) onto a .gridmap file's cells in one undoable step and reimports it. `cells` are [x, y, z] (y is the floor); `brush` reads them as: cells (each one), line or rect / outline (between the first two), fill (flood fill from the first). `rotation` 0/90/180/270, `flipX` / `flipZ` mirror, `layer` (default: the piece's) — a piece replaces what it overlaps on its layer only. Auto-joining pieces (like the starter Wall) pick their straight/corner/tee/end shape from neighbors by themselves."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        try requireCells(arguments.cells, title)
        let (id, original) = try session.resolveGridMap(arguments, title)
        let (map, count) = try painted(original, with: arguments)
        let warnings = try session.commands.require(session.applyGridMap(map, to: id, label: title), title)
        return GridMapResult(id, map, changed: count, warnings: GridMapCheck.all(map, imported: warnings, in: session), in: session)
    }

    /// `map` with the paint applied and how many cells were painted (pure, for tests and the UI).
    public static func painted(_ map: GridMap, with arguments: Arguments) throws -> (GridMap, Int) {
        var m = map
        let set = arguments.pieces ?? []
        guard let first = arguments.piece ?? set.first else { throw CommandError.failed("\(title): give `piece` or `pieces`") }
        for name in [first] + set { try requirePiece(name, in: m, title) }
        try requireLayer(arguments.layer, in: m, title)
        let layer = arguments.layer.flatMap { $0.isEmpty ? nil : $0 } ?? m.defaultLayer(of: m.piece(named: first))
        let coords: [GridCoord]
        do { coords = try m.brushCells(arguments.brush ?? .cells, arguments.cells, layer: layer) } catch {
            throw CommandError.failed("\(title): \(error)")
        }
        guard m.cells.count + coords.count <= GridMap.maxCells else { throw CommandError.failed("\(title): a map holds at most \(GridMap.maxCells) cells") }
        let count: Int
        if arguments.piece == nil {
            count = m.paintRandom(set, at: coords, seed: arguments.seed ?? 1, rotation: arguments.rotation ?? 0,
                                  randomRotation: arguments.randomRotation ?? false, layer: arguments.layer)
        } else {
            count = m.paint(first, at: coords, rotation: arguments.rotation ?? 0, flipX: arguments.flipX ?? false, flipZ: arguments.flipZ ?? false,
                            layer: arguments.layer)
        }
        return (m, count)
    }
}

public enum GridMapFillCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        public var piece: String
        /// Two opposite corners [[x, y, z], [x, y, z]]; every floor between them is filled.
        public var box: [GridCoord]
        /// Only the box's edge on each floor (a ring of walls).
        public var hollow: Bool?
        public var rotation: Int?
        public var layer: String?
        public init(asset: AssetReference? = nil, path: String? = nil, piece: String, box: [GridCoord], hollow: Bool? = nil, rotation: Int? = nil,
                    layer: String? = nil) {
            self.asset = asset
            self.path = path
            self.piece = piece
            self.box = box
            self.hollow = hollow
            self.rotation = rotation
            self.layer = layer
        }
    }

    public static let id: CommandID = "gridMap.fill"
    public static let title = "Fill GridMap"
    public static let doc = "Fills a box of cells (`box`: two opposite [x, y, z] corners, every floor between them) with a piece in one undoable step; `hollow` paints only each floor's edge (a ring of walls; auto-joining walls form corners by themselves). `rotation` 0/90/180/270, `layer` (default: the piece's)."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        let (id, original) = try session.resolveGridMap(arguments, title)
        let (map, count) = try filled(original, with: arguments)
        let warnings = try session.commands.require(session.applyGridMap(map, to: id, label: title), title)
        return GridMapResult(id, map, changed: count, warnings: GridMapCheck.all(map, imported: warnings, in: session), in: session)
    }

    public static func filled(_ map: GridMap, with arguments: Arguments) throws -> (GridMap, Int) {
        guard arguments.box.count == 2 else { throw CommandError.failed("\(title): box is two corners [[x, y, z], [x, y, z]]") }
        var m = map
        try requirePiece(arguments.piece, in: m, title)
        try requireLayer(arguments.layer, in: m, title)
        let a = arguments.box[0], b = arguments.box[1]
        let volume = (abs(a.x - b.x) + 1) * (abs(a.y - b.y) + 1) * (abs(a.z - b.z) + 1)
        guard volume <= 100_000, m.cells.count + volume <= GridMap.maxCells else { throw CommandError.failed("\(title): the box is too big") }
        let coords = (Swift.min(a.y, b.y)...Swift.max(a.y, b.y)).flatMap { y in
            GridMap.rectangle(from: GridCoord(a.x, y, a.z), to: GridCoord(b.x, y, b.z), outline: arguments.hollow ?? false)
        }
        let count = m.paint(arguments.piece, at: coords, rotation: arguments.rotation ?? 0, layer: arguments.layer)
        return (m, count)
    }
}

public enum GridMapEraseCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GridMapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// [x, y, z] cells to clear.
        public var cells: [GridCoord]?
        /// Or two opposite corners of a box to clear.
        public var box: [GridCoord]?
        /// Only this layer (default: every layer).
        public var layer: String?
        public init(asset: AssetReference? = nil, path: String? = nil, cells: [GridCoord]? = nil, box: [GridCoord]? = nil, layer: String? = nil) {
            self.asset = asset
            self.path = path
            self.cells = cells
            self.box = box
            self.layer = layer
        }
    }

    public static let id: CommandID = "gridMap.erase"
    public static let title = "Erase GridMap"
    public static let doc = "Clears cells of a .gridmap file in one undoable step: `cells` ([x, y, z] list) and/or `box` (two opposite corners), on `layer` or every layer. A multi-cell piece goes when any cell it covers is erased."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> GridMapResult {
        let (id, original) = try session.resolveGridMap(arguments, title)
        var map = original
        try requireLayer(arguments.layer, in: map, title)
        var coords = arguments.cells ?? []
        if let box = arguments.box {
            guard box.count == 2 else { throw CommandError.failed("\(title): box is two corners [[x, y, z], [x, y, z]]") }
            coords += GridMap.box(from: box[0], to: box[1])
        }
        try requireCells(coords, title)
        let count = map.erase(at: coords, layer: arguments.layer.flatMap { $0.isEmpty ? nil : $0 })
        let warnings = try session.commands.require(session.applyGridMap(map, to: id, label: title), title)
        return GridMapResult(id, map, changed: count, warnings: GridMapCheck.all(map, imported: warnings, in: session), in: session)
    }
}
