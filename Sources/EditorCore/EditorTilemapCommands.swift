import Engine
import EngineMCP
import Foundation

/// The tilemap builder tools: `tilemap.new`, `.get`, `.set`, `.edit`, `.open`, `.paint`, `.fill`, `.erase`.
@MainActor
public enum EditorTilemapCommands {
    public static let all: [any EditorCommand.Type] = [
        TilemapNewCommand.self,
        TilemapGetCommand.self,
        TilemapSetCommand.self,
        TilemapEditCommand.self,
        TilemapOpenCommand.self,
        TilemapPaintCommand.self,
        TilemapFillCommand.self,
        TilemapEraseCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A tilemap is a grid of `size` [columns, rows] cells of `tileSize` [w, h] pixels; `pixelsPerUnit` (0: the tile width, so \
        a tile is 1 world unit) sets the world size. Cells are addressed [x, y] with x right and y DOWN from the top-left cell. \
        `tileset`: `source` ({"kind": "image", "image": "Tiles/sheet.png", "margin", "spacing"} slices a sprite sheet into tiles \
        in reading order, tile 0 first; {"kind": "images", "images": [...]} packs one image per tile), `filter` (nearest/linear), \
        `tiles` (per-tile entries: index, name, collision none/full/top/bottom/slopeUp/slopeDown/polygon (+points 0-1, y up), \
        oneWay, tags, properties, animation {frames, fps, mode loop/pingPong}). `layers` (name, cells (rows of cell values, top \
        row first), order, parallax [x,y], opacity, visible, collision) draw in list order, first at the back. A cell value is -1 \
        (empty) or a tile index + 65536 (flip x) + 131072 (flip y) + 262144 * quarter turns clockwise. `terrains` are auto-tiling \
        sets (name, mode edges (mask N1 E2 S4 W8) or blob (8 neighbors), first (edges: tile first+mask), tiles {"mask": tile}, \
        fill, edgesConnect). `objects` (name, type, position [x,y] world units from the bottom-left, size, trigger, properties) \
        are points for game code. Every key is optional; paint with tilemap.paint / fill / erase rather than writing cells.
        """
}

extension TilesetSource: JSONSchemaProviding {
    public static var jsonSchema: JSON {
        [
            "description": "Where the tile pictures come from: an image path (a sprite sheet sliced by tileSize), or an object with a kind.",
            "oneOf": [
                ["type": "string"],
                [
                    "type": "object",
                    "properties": [
                        "kind": ["type": "string", "enum": ["image", "images"]],
                        "image": ["type": "string", "description": "kind image: the sheet, a path under Assets/"],
                        "margin": ["type": "integer"], "spacing": ["type": "integer"],
                        "images": ["type": "array", "items": ["type": "string"], "description": "kind images: one image per tile"],
                    ],
                ],
            ],
        ]
    }
}

extension EditorSession {
    /// Writes a tilemap to "`name`.tilemap" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createTilemapAsset(in folder: String, name: String = "New Tilemap", map: Tilemap) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Tilemap") else {
            log.error("New Tilemap: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".tilemap"))
        do {
            let id = try assets.createTilemap(map, at: path)
            log.info("Created tilemap \(path)")
            return id
        } catch {
            log.error("New Tilemap failed: \(error)")
            return nil
        }
    }

    /// Writes the starter tile set image (`TilemapStarter`) as "`name`.png" in `folder`. Returns its path.
    func createStarterTileset(in folder: String, name: String) -> String? {
        guard let assets, checkAssetPaths([folder, name], "New Tilemap") else { return nil }
        let path = assets.uniquePath(Self.join(folder, name + ".png"))
        let url = assets.project.url(forAssetPath: path)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try TilemapStarter.image().pngData().write(to: url, options: .atomic)
            assets.refresh()
            return path
        } catch {
            log.error("New Tilemap: writing the starter tile set failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.tilemap` file.
    public func isTilemapFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == TilemapImporter().name
    }

    /// Replaces the contents of the tilemap `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyTilemap(_ map: Tilemap, to id: AssetID, label: String = "Edit Tilemap") -> [String]? {
        guard let assets, var old = assets.tilemapContents(of: id) else {
            log.error("\(label): \(id) isn't a readable .tilemap file")
            return nil
        }
        old.normalize()
        var new = map
        new.normalize()
        guard old != new else { return [] }
        let command = TilemapFileEditCommand(asset: id, old: old, new: new, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// The tilemap named by `target` and its contents (normalized).
    func resolveTilemap(_ target: some TilemapTarget, _ title: String) throws -> (AssetID, Tilemap) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isTilemapFile(id), var map = assets?.tilemapContents(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .tilemap file")
        }
        map.normalize()
        return (id, map)
    }
}

/// Makes tilemap edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct TilemapFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: Tilemap
    public let new: Tilemap
    /// The last write's import warnings.
    let warnings = TerrainFileEditCommand.Box<[String]>([])
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: Tilemap, new: Tilemap, in database: AssetDatabase, label: String = "Edit Tilemap") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ map: Tilemap) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeTilemap(map, to: asset)
    }
}

/// Arguments naming a `.tilemap` file.
public protocol TilemapTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

/// What the tilemap tools return (the cells stay in the file; tilemap.get reads them).
public struct TilemapResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The prefab to place with asset.instantiate ("asset:<id>" works too).
    public var prefab: AssetReference
    /// [columns, rows].
    public var size: [Int]
    /// [width, height] in pixels.
    public var tileSize: [Int]
    /// One cell in world units.
    public var cellSize: Vec2
    /// Tiles in the tile set (as imported).
    public var tileCount: Int
    public var layers: [String]
    /// Painted cells per layer (same order as `layers`).
    public var painted: [Int]
    public var terrains: [String]
    public var objects: [String]
    /// Merged Collider2D shapes the collision makes.
    public var colliders: Int
    /// Cells the call changed (paint, fill, erase).
    public var changed: Int?
    /// Import problems and unresolved references.
    public var warnings: [String]
    /// Entities placed in the scene (tilemap.new with `place`).
    public var entities: [EntityID]?
}

extension TilemapResult {
    @MainActor init(_ id: AssetID, _ map: Tilemap, warnings: [String], changed: Int? = nil, entities: [EntityID]? = nil,
                    in session: EditorSession) {
        let record = session.assets?.record(id)
        let prefab = record?.objects.first { $0.kind == .prefab }.map { AssetReference(id, subAsset: $0.id) } ?? AssetReference(id)
        var m = map
        m.normalize()
        let tileCount = session.assets?.tileset(of: id)?.layout.count ?? 0
        var all = warnings + TilemapCheck.problems(m, tileCount: tileCount, in: session) + (record?.importError.map { ["import failed: \($0)"] } ?? [])
        var seen = Set<String>()
        all = all.filter { seen.insert($0).inserted }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", prefab: prefab, size: [m.cols, m.rowCount], tileSize: [m.tileW, m.tileH],
                  cellSize: m.cellSize, tileCount: tileCount, layers: m.layers.map(\.name), painted: m.paintedCounts,
                  terrains: m.terrains.map(\.name), objects: m.objects.map(\.name), colliders: m.collisionShapes().count,
                  changed: changed, warnings: all, entities: entities)
    }
}

/// Problems with a tilemap's references, found without importing.
@MainActor
enum TilemapCheck {
    static func problems(_ map: Tilemap, tileCount: Int?, in session: EditorSession) -> [String] {
        var problems: [String] = []
        for path in map.tileset.source.paths where session.assets?.id(forPath: TilemapImporter.normalized(path)) == nil {
            problems.append("tile set: no image asset '\(path)'")
        }
        if case .unsupported(let kind, _) = map.tileset.source { problems.append("tile set: the source kind '\(kind)' isn't supported") }
        return problems + map.validate(tileCount: map.tileset.source.paths.isEmpty || problems.isEmpty ? tileCount : nil)
    }
}

/// Picks the layer a tool works on: by name, else the first layer.
private func layerIndex(_ name: String?, in map: Tilemap, _ title: String) throws -> Int {
    guard !map.layers.isEmpty else { throw CommandError.failed("\(title): the tilemap has no layers; add one with tilemap.edit {addLayers}") }
    guard let name, !name.isEmpty else { return 0 }
    guard let index = map.layerIndex(named: name) else {
        throw CommandError.failed("\(title): no layer named '\(name)' (layers: \(map.layers.map(\.name).joined(separator: ", ")))")
    }
    return index
}

/// [[x, y], …] cell pairs.
private func cellPairs(_ cells: [[Int]]?, _ title: String) throws -> [(x: Int, y: Int)] {
    guard let cells, !cells.isEmpty else { return [] }
    guard cells.count <= 100_000 else { throw CommandError.failed("\(title): at most 100000 cells per call") }
    return try cells.map {
        guard $0.count == 2 else { throw CommandError.failed("\(title): each cell is [x, y] (x right, y down from the top-left)") }
        return ($0[0], $0[1])
    }
}

/// A [x0, y0, x1, y1] rectangle (corners inclusive).
private func rectCells(_ rect: [Int]?, in map: Tilemap, _ title: String) throws -> [(x: Int, y: Int)]? {
    guard let rect else { return nil }
    guard rect.count == 4 else { throw CommandError.failed("\(title): rect is [x0, y0, x1, y1] (corners inclusive)") }
    return map.rectCells(rect[0], rect[1], rect[2], rect[3])
}

/// What to put in cells: one tile, a random pick from several, or a terrain.
struct TilemapBrushArguments {
    var tile: Int?
    var tiles: [Int]?
    var terrain: String?
    var flipX: Bool?
    var flipY: Bool?
    var rotation: Int?
    var seed: Int?

    /// Applies the brush to `cells` of layer `layer`; returns how many cells changed.
    func apply(to map: inout Tilemap, layer: Int, cells: [(x: Int, y: Int)], _ title: String) throws -> Int {
        let given = [tile != nil, !(tiles ?? []).isEmpty, terrain != nil].filter { $0 }.count
        guard given == 1 else { throw CommandError.failed("\(title): give exactly one of tile, tiles (random from a set) or terrain") }
        if let name = terrain {
            guard let t = map.terrainIndex(named: name) else {
                throw CommandError.failed("\(title): no terrain named '\(name)' (terrains: \(map.terrains.map(\.name).joined(separator: ", ")))")
            }
            return map.paintTerrain(layer: layer, terrain: t, cells: cells)
        }
        if let tiles, !tiles.isEmpty {
            guard tiles.allSatisfy({ $0 >= 0 && $0 <= 0xFFFF }) else { throw CommandError.failed("\(title): tile indices are 0...65535") }
            return map.paintRandom(layer: layer, cells: cells, tiles: tiles, seed: seed ?? 1, flipX: flipX ?? false, flipY: flipY ?? false,
                                   rotation: rotation ?? 0)
        }
        guard let tile, tile >= -1, tile <= 0xFFFF else { throw CommandError.failed("\(title): tile is a tile set index 0...65535 (-1 erases)") }
        return map.paint(layer: layer, cells: cells, TileCell(tile: tile, flipX: flipX ?? false, flipY: flipY ?? false, rotation: rotation ?? 0))
    }
}

public enum TilemapNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Tilemap" (the file gets ".tilemap").
        public var name: String?
        /// [width, height] in pixels (default [16, 16]).
        public var tileSize: [Int]?
        /// [columns, rows] (default [40, 22]).
        public var size: [Int]?
        /// An image path (a sprite sheet sliced by tileSize) or a tileset object. Default: a starter tile set (dirt with
        /// grass edges as the "Dirt" terrain, stone, brick, platform, ramps, spikes, water, torch, coin, ladder) written next to the map.
        public var tileset: JSONValue?
        /// Layer names, back to front (default ["Background", "Ground", "Foreground"]; only "Ground" collides).
        public var layers: [String]?
        /// Pixels per world unit (default 0: one tile is one unit wide).
        public var pixelsPerUnit: Float?
        /// Also place it in the scene (default false).
        public var place: Bool?
        public var position: Vec3?
        public init(folder: String? = nil, name: String? = nil, tileSize: [Int]? = nil, size: [Int]? = nil, tileset: JSONValue? = nil,
                    layers: [String]? = nil, pixelsPerUnit: Float? = nil, place: Bool? = nil, position: Vec3? = nil) {
            self.folder = folder
            self.name = name
            self.tileSize = tileSize
            self.size = size
            self.tileset = tileset
            self.layers = layers
            self.pixelsPerUnit = pixelsPerUnit
            self.place = place
            self.position = position
        }
    }

    public static let id: CommandID = "tilemap.new"
    public static let title = "New Tilemap"
    public static let doc = "Writes a .tilemap file in `folder` (default: the Assets root) with empty layers, imported as a prefab of layer chunk meshes, merged Collider2D shapes and object points, optionally placed in the scene. Without `tileset` a 16 px starter tile set image is written next to it (tiles 0-15 the \"Dirt\" terrain by edge mask, 16 stone, 17 brick, 18 one-way platform, 19/20 ramps, 21 spikes, 22-25 animated water, 26-27 torch, 28 coin, 29 grass tuft, 30 back wall, 31 ladder). Then paint with tilemap.paint / tilemap.fill. " + EditorTilemapCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        let tile = arguments.tileSize ?? [16, 16]
        let size = arguments.size ?? [40, 22]
        guard tile.count == 2, tile.allSatisfy({ $0 >= 1 && $0 <= 1024 }) else { throw CommandError.failed("\(title): tileSize is [width, height], 1...1024 pixels") }
        guard size.count == 2, size.allSatisfy({ $0 >= 1 && $0 <= Tilemap.maxSide }) else {
            throw CommandError.failed("\(title): size is [columns, rows], 1...\(Tilemap.maxSide)")
        }
        let folder = arguments.folder ?? "", name = arguments.name ?? "New Tilemap"
        var map = Tilemap(tileWidth: tile[0], tileHeight: tile[1], columns: size[0], rows: size[1], pixelsPerUnit: max(arguments.pixelsPerUnit ?? 0, 0))
        switch arguments.tileset {
        case .string(let path)?:
            map.tileset = TilemapTileset(source: .image(path: path))
        case .object?:
            do { map.tileset = try JSONDecoder().decode(TilemapTileset.self, from: JSONEncoder().encode(arguments.tileset)) } catch {
                throw CommandError.failed("\(title): tileset: \(error)")
            }
        case nil, .null?:
            guard tile == [TilemapStarter.tileSize, TilemapStarter.tileSize] else {
                throw CommandError.failed("\(title): the starter tile set is 16 x 16 pixels; give a tileset for tileSize \(tile)")
            }
            let path = try session.commands.require(session.createStarterTileset(in: folder, name: name + " tiles"), title)
            map.tileset = TilemapStarter.tileset(imagePath: path)
            map.terrains = [TilemapStarter.terrain]
        default:
            throw CommandError.failed("\(title): tileset is an image path or a tileset object")
        }
        let names = arguments.layers ?? ["Background", "Ground", "Foreground"]
        map.layers = names.map { TilemapLayer(name: $0, collision: arguments.layers == nil ? $0 == "Ground" : true) }
        map.normalize()
        let id = try session.commands.require(session.createTilemapAsset(in: folder, name: name, map: map), title)
        var entities: [EntityID]?
        if arguments.place == true {
            entities = session.instantiate(.asset(id), at: arguments.position ?? .zero)
            try session.commands.check(!(entities ?? []).isEmpty, title)
        }
        return TilemapResult(id, map, warnings: [], entities: entities, in: session)
    }
}

/// A layer's settings without its cells (tilemap.get).
public struct TilemapLayerInfo: Codable, Equatable, Sendable {
    public var name: String
    public var order: Float
    public var parallax: Vec2
    public var opacity: Float
    public var visible: Bool
    public var collision: Bool
    public var painted: Int
}

public enum TilemapGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Also return cells of this layer (default: none).
        public var layer: String?
        /// The region of `layer` to return, [x0, y0, x1, y1] (default: the whole map, at most 128 x 128 cells).
        public var rect: [Int]?
        public init(asset: AssetReference? = nil, path: String? = nil, layer: String? = nil, rect: [Int]? = nil) {
            self.asset = asset
            self.path = path
            self.layer = layer
            self.rect = rect
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var summary: TilemapResult
        public var pixelsPerUnit: Float
        public var chunkSize: Int
        public var tileset: TilemapTileset
        public var layers: [TilemapLayerInfo]
        public var terrains: [TilemapTerrainSet]
        public var objects: [TilemapObject]
        public var background: Vec4?
        /// The requested region's cell values, rows top first (-1 empty; see the format notes).
        public var cells: [[Int]]?
        /// The region's top-left cell [x, y].
        public var origin: [Int]?
    }

    public static let id: CommandID = "tilemap.get"
    public static let title = "Get Tilemap"
    public static let doc = "Reads a .tilemap file: size, tile set (source and per-tile entries), layer settings, terrains, objects and a summary (painted cells per layer, merged colliders, problems). With `layer` it also returns that layer's cells (or the `rect` [x0, y0, x1, y1] of them) as rows of cell values, top row first."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, map) = try session.resolveTilemap(arguments, title)
        var cells: [[Int]]?
        var origin: [Int]?
        if let name = arguments.layer {
            let l = try layerIndex(name, in: map, title)
            let r = arguments.rect ?? [0, 0, map.cols - 1, map.rowCount - 1]
            guard r.count == 4 else { throw CommandError.failed("\(title): rect is [x0, y0, x1, y1]") }
            let x0 = max(min(r[0], r[2]), 0), x1 = min(max(r[0], r[2]), map.cols - 1)
            let y0 = max(min(r[1], r[3]), 0), y1 = min(max(r[1], r[3]), map.rowCount - 1)
            guard x0 <= x1, y0 <= y1 else { throw CommandError.failed("\(title): rect is outside the map") }
            guard (x1 - x0 + 1) <= 128, (y1 - y0 + 1) <= 128 else { throw CommandError.failed("\(title): at most 128 x 128 cells per call; give a rect") }
            cells = (y0...y1).map { y in (x0...x1).map { x in map.cell(layer: l, x: x, y: y).encoded } }
            origin = [x0, y0]
        }
        let painted = map.paintedCounts
        let layers = map.layers.enumerated().map { i, l in
            TilemapLayerInfo(name: l.name, order: map.order(ofLayer: i), parallax: l.parallax, opacity: l.opacity, visible: l.visible,
                             collision: l.collision, painted: painted[i])
        }
        return Result(summary: TilemapResult(id, map, warnings: [], in: session), pixelsPerUnit: map.pixelsPerUnit, chunkSize: map.chunk,
                      tileset: map.tileset, layers: layers, terrains: map.terrains, objects: map.objects, background: map.background,
                      cells: cells, origin: origin)
    }
}

public enum TilemapSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var tilemap: Tilemap
        public init(asset: AssetReference? = nil, path: String? = nil, tilemap: Tilemap) {
            self.asset = asset
            self.path = path
            self.tilemap = tilemap
        }
    }

    public static let id: CommandID = "tilemap.set"
    public static let title = "Set Tilemap"
    public static let doc = "Replaces a .tilemap file's whole contents and reimports it; placed copies update. Undoable. For settings, layers, tiles, terrains or objects tilemap.edit is shorter; paint cells with tilemap.paint / fill / erase. " + EditorTilemapCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        let (id, _) = try session.resolveTilemap(arguments, title)
        var map = arguments.tilemap
        map.normalize()
        let warnings = try session.commands.require(session.applyTilemap(map, to: id, label: title), title)
        return TilemapResult(id, map, warnings: warnings, in: session)
    }
}

public enum TilemapEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// New [columns, rows]; cells keep their place from the top-left (or the bottom-left with `anchorBottom`).
        public var size: [Int]?
        public var anchorBottom: Bool?
        /// New [width, height] in pixels (the tile set is sliced again).
        public var tileSize: [Int]?
        public var pixelsPerUnit: Float?
        public var chunkSize: Int?
        /// sRGB [r, g, b, a] behind the map in the editor.
        public var background: Vec4?
        /// A new tile set source (an image path, or {"kind": "images", "images": [...]}).
        public var tilesetSource: TilesetSource?
        /// "nearest" or "linear".
        public var filter: String?
        /// Per-tile entries to write (each replaces the entry with its index; an entry with only an index clears it).
        public var setTiles: [TilemapTile]?
        /// Tile indices whose entries to remove.
        public var removeTiles: [Int]?
        /// Layer names to remove.
        public var removeLayers: [String]?
        /// Layers to add (a taken name gets " 2"…), in front of the others unless they say `order`.
        public var addLayers: [TilemapLayer]?
        /// Layer name → fields to change; "name" renames.
        public var updateLayers: [String: JSONValue]?
        /// The layers' new back-to-front order by name (every layer, once).
        public var layerOrder: [String]?
        public var removeTerrains: [String]?
        public var addTerrains: [TilemapTerrainSet]?
        public var updateTerrains: [String: JSONValue]?
        /// Object names to remove (every object with the name).
        public var removeObjects: [String]?
        public var addObjects: [TilemapObject]?
        /// Object name → fields to change (the first object with the name).
        public var updateObjects: [String: JSONValue]?
        public init(asset: AssetReference? = nil, path: String? = nil, size: [Int]? = nil, anchorBottom: Bool? = nil, tileSize: [Int]? = nil,
                    pixelsPerUnit: Float? = nil, chunkSize: Int? = nil, background: Vec4? = nil, tilesetSource: TilesetSource? = nil,
                    filter: String? = nil, setTiles: [TilemapTile]? = nil, removeTiles: [Int]? = nil, removeLayers: [String]? = nil,
                    addLayers: [TilemapLayer]? = nil, updateLayers: [String: JSONValue]? = nil, layerOrder: [String]? = nil,
                    removeTerrains: [String]? = nil, addTerrains: [TilemapTerrainSet]? = nil, updateTerrains: [String: JSONValue]? = nil,
                    removeObjects: [String]? = nil, addObjects: [TilemapObject]? = nil, updateObjects: [String: JSONValue]? = nil) {
            self.asset = asset
            self.path = path
            self.size = size
            self.anchorBottom = anchorBottom
            self.tileSize = tileSize
            self.pixelsPerUnit = pixelsPerUnit
            self.chunkSize = chunkSize
            self.background = background
            self.tilesetSource = tilesetSource
            self.filter = filter
            self.setTiles = setTiles
            self.removeTiles = removeTiles
            self.removeLayers = removeLayers
            self.addLayers = addLayers
            self.updateLayers = updateLayers
            self.layerOrder = layerOrder
            self.removeTerrains = removeTerrains
            self.addTerrains = addTerrains
            self.updateTerrains = updateTerrains
            self.removeObjects = removeObjects
            self.addObjects = addObjects
            self.updateObjects = updateObjects
        }
    }

    public static let id: CommandID = "tilemap.edit"
    public static let title = "Edit Tilemap"
    public static let doc = "Changes a .tilemap file in one undoable step, in this order: size (anchorBottom keeps the bottom rows), tileSize, pixelsPerUnit, chunkSize, background, tilesetSource, filter, setTiles / removeTiles (per-tile collision, oneWay, tags, properties, animation), removeLayers, addLayers, updateLayers (name → fields; \"name\" renames), layerOrder, removeTerrains, addTerrains, updateTerrains, removeObjects, addObjects, updateObjects. Placed copies update. Cells are painted with tilemap.paint / fill / erase."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        let (id, original) = try session.resolveTilemap(arguments, title)
        let map = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyTilemap(map, to: id, label: title), title)
        return TilemapResult(id, map, warnings: warnings, in: session)
    }

    /// `map` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ map: Tilemap, with arguments: Arguments) throws -> Tilemap {
        var m = map
        m.normalize()
        if let size = arguments.size {
            guard size.count == 2, size.allSatisfy({ $0 >= 1 && $0 <= Tilemap.maxSide }) else {
                throw CommandError.failed("size is [columns, rows], 1...\(Tilemap.maxSide)")
            }
            m.resize(columns: size[0], rows: size[1], anchorBottom: arguments.anchorBottom ?? false)
        }
        if let tile = arguments.tileSize {
            guard tile.count == 2, tile.allSatisfy({ $0 >= 1 && $0 <= 1024 }) else { throw CommandError.failed("tileSize is [width, height], 1...1024") }
            m.tileWidth = tile[0]
            m.tileHeight = tile[1]
        }
        if let v = arguments.pixelsPerUnit { m.pixelsPerUnit = max(v, 0) }
        if let v = arguments.chunkSize { m.chunkSize = min(max(v, 1), 256) }
        if let v = arguments.background { m.background = v }
        if let v = arguments.tilesetSource { m.tileset.source = v }
        if let v = arguments.filter {
            guard v == "nearest" || v == "linear" else { throw CommandError.failed("filter is nearest or linear") }
            m.tileset.filter = v
        }
        for tile in arguments.setTiles ?? [] {
            guard tile.index >= 0 else { throw CommandError.failed("setTiles: tile indices start at 0") }
            m.tileset.setTile(tile)
        }
        if let remove = arguments.removeTiles { m.tileset.tiles.removeAll { remove.contains($0.index) } }

        if let names = arguments.removeLayers {
            let missing = names.filter { m.layerIndex(named: $0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("No layer named \(missing.joined(separator: ", "))") }
            m.layers.removeAll { names.contains($0.name) }
        }
        for var layer in arguments.addLayers ?? [] {
            layer.name = TerrainEditCommand.uniqueName(layer.name, among: m.layers.map(\.name))
            m.layers.append(layer)
        }
        m.normalize()
        for (name, changes) in (arguments.updateLayers ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = m.layerIndex(named: name) else { throw CommandError.failed("No layer named \(name)") }
            var updated: TilemapLayer = try TerrainEditCommand.merged(m.layers[index], changes, "updateLayers[\(name)]")
            if case .object(let fields) = changes, fields["cells"] == nil, fields["data"] == nil { updated.data = m.layers[index].data }
            if updated.name != name, m.layerIndex(named: updated.name) != nil { throw CommandError.failed("A layer is already named \(updated.name)") }
            m.layers[index] = updated
        }
        m.normalize()
        if let order = arguments.layerOrder {
            guard Set(order) == Set(m.layers.map(\.name)), order.count == m.layers.count else {
                throw CommandError.failed("layerOrder names every layer once (layers: \(m.layers.map(\.name).joined(separator: ", ")))")
            }
            m.layers = order.compactMap { name in m.layers.first { $0.name == name } }
        }

        if let names = arguments.removeTerrains {
            let missing = names.filter { m.terrainIndex(named: $0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("No terrain named \(missing.joined(separator: ", "))") }
            m.terrains.removeAll { names.contains($0.name) }
        }
        for var terrain in arguments.addTerrains ?? [] {
            terrain.name = TerrainEditCommand.uniqueName(terrain.name, among: m.terrains.map(\.name))
            m.terrains.append(terrain)
        }
        for (name, changes) in (arguments.updateTerrains ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = m.terrainIndex(named: name) else { throw CommandError.failed("No terrain named \(name)") }
            m.terrains[index] = try TerrainEditCommand.merged(m.terrains[index], changes, "updateTerrains[\(name)]")
        }

        if let names = arguments.removeObjects {
            let missing = names.filter { m.object(named: $0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("No object named \(missing.joined(separator: ", "))") }
            m.objects.removeAll { names.contains($0.name) }
        }
        m.objects += arguments.addObjects ?? []
        for (name, changes) in (arguments.updateObjects ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = m.objects.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No object named \(name)") }
            m.objects[index] = try TerrainEditCommand.merged(m.objects[index], changes, "updateObjects[\(name)]")
        }
        return m
    }
}

public enum TilemapOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "tilemap.open"
    public static let title = "Open in Tilemap Builder"
    public static let doc = "Opens a .tilemap file in the editor's Tilemap Builder tab (the map drawn with its tile set, a tile palette, brushes and the layer, tile, terrain and object forms) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"tilemapBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveTilemap(arguments, title)
        session.openTilemap = id
        session.onOpenTilemap?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum TilemapPaintCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Layer name (default: the first layer).
        public var layer: String?
        /// [[x, y], …] cells (x right, y down from the top-left).
        public var cells: [[Int]]
        /// The tile set index to paint (-1 erases).
        public var tile: Int?
        /// Random brush: each cell gets one of these (stable per `seed`).
        public var tiles: [Int]?
        /// Auto-tile brush: a terrain set's name; edges and corners are picked from the neighbors.
        public var terrain: String?
        public var flipX: Bool?
        public var flipY: Bool?
        /// Quarter turns clockwise (0-3).
        public var rotation: Int?
        public var seed: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, layer: String? = nil, cells: [[Int]], tile: Int? = nil, tiles: [Int]? = nil,
                    terrain: String? = nil, flipX: Bool? = nil, flipY: Bool? = nil, rotation: Int? = nil, seed: Int? = nil) {
            self.asset = asset
            self.path = path
            self.layer = layer
            self.cells = cells
            self.tile = tile
            self.tiles = tiles
            self.terrain = terrain
            self.flipX = flipX
            self.flipY = flipY
            self.rotation = rotation
            self.seed = seed
        }
    }

    public static let id: CommandID = "tilemap.paint"
    public static let title = "Paint Tilemap"
    public static let doc = "Paints cells of a layer in one undoable step with exactly one brush: `tile` (one tile, with flipX / flipY / rotation), `tiles` (random from a set) or `terrain` (auto-tiling: the cells become that terrain and every terrain cell around them picks the tile matching its neighbors). Cells are [x, y] with y down from the top-left; cells outside the map are skipped. Returns the summary with `changed`."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        var (id, map) = try session.resolveTilemap(arguments, title)
        let layer = try layerIndex(arguments.layer, in: map, title)
        let cells = try cellPairs(arguments.cells, title)
        guard !cells.isEmpty else { throw CommandError.failed("\(title): cells is empty; give [[x, y], …]") }
        let brush = TilemapBrushArguments(tile: arguments.tile, tiles: arguments.tiles, terrain: arguments.terrain, flipX: arguments.flipX,
                                          flipY: arguments.flipY, rotation: arguments.rotation, seed: arguments.seed)
        let changed = try brush.apply(to: &map, layer: layer, cells: cells, title)
        let warnings = try session.commands.require(session.applyTilemap(map, to: id, label: title), title)
        return TilemapResult(id, map, warnings: warnings, changed: changed, in: session)
    }
}

public enum TilemapFillCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        public var layer: String?
        /// [x0, y0, x1, y1] (corners inclusive) to fill.
        public var rect: [Int]?
        /// [x, y]: flood fill from this cell instead (the connected cells holding the same tile).
        public var at: [Int]?
        public var tile: Int?
        public var tiles: [Int]?
        public var terrain: String?
        public var flipX: Bool?
        public var flipY: Bool?
        public var rotation: Int?
        public var seed: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, layer: String? = nil, rect: [Int]? = nil, at: [Int]? = nil, tile: Int? = nil,
                    tiles: [Int]? = nil, terrain: String? = nil, flipX: Bool? = nil, flipY: Bool? = nil, rotation: Int? = nil, seed: Int? = nil) {
            self.asset = asset
            self.path = path
            self.layer = layer
            self.rect = rect
            self.at = at
            self.tile = tile
            self.tiles = tiles
            self.terrain = terrain
            self.flipX = flipX
            self.flipY = flipY
            self.rotation = rotation
            self.seed = seed
        }
    }

    public static let id: CommandID = "tilemap.fill"
    public static let title = "Fill Tilemap"
    public static let doc = "Fills a `rect` [x0, y0, x1, y1] of a layer, or flood-fills from `at` [x, y] (the 4-connected cells holding the same tile), with one brush: `tile`, `tiles` (random) or `terrain` (auto-tiled). One undoable step."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        var (id, map) = try session.resolveTilemap(arguments, title)
        let layer = try layerIndex(arguments.layer, in: map, title)
        var cells: [(x: Int, y: Int)]
        if let rect = try rectCells(arguments.rect, in: map, title) {
            guard arguments.at == nil else { throw CommandError.failed("\(title): give rect or at, not both") }
            cells = rect
        } else if let at = arguments.at {
            guard at.count == 2, map.contains(x: at[0], y: at[1]) else { throw CommandError.failed("\(title): at is [x, y] inside the map") }
            cells = map.floodRegion(layer: layer, x: at[0], y: at[1])
        } else {
            throw CommandError.failed("\(title): give rect [x0, y0, x1, y1] or at [x, y]")
        }
        let brush = TilemapBrushArguments(tile: arguments.tile, tiles: arguments.tiles, terrain: arguments.terrain, flipX: arguments.flipX,
                                          flipY: arguments.flipY, rotation: arguments.rotation, seed: arguments.seed)
        let changed = try brush.apply(to: &map, layer: layer, cells: cells, title)
        let warnings = try session.commands.require(session.applyTilemap(map, to: id, label: title), title)
        return TilemapResult(id, map, warnings: warnings, changed: changed, in: session)
    }
}

public enum TilemapEraseCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TilemapTarget {
        public var asset: AssetReference?
        public var path: String?
        public var layer: String?
        /// [[x, y], …] cells to clear.
        public var cells: [[Int]]?
        /// [x0, y0, x1, y1] to clear.
        public var rect: [Int]?
        /// Clear the whole layer.
        public var all: Bool?
        /// The terrain the cells belong to: its neighbors are re-tiled so new edges appear.
        public var terrain: String?
        public init(asset: AssetReference? = nil, path: String? = nil, layer: String? = nil, cells: [[Int]]? = nil, rect: [Int]? = nil,
                    all: Bool? = nil, terrain: String? = nil) {
            self.asset = asset
            self.path = path
            self.layer = layer
            self.cells = cells
            self.rect = rect
            self.all = all
            self.terrain = terrain
        }
    }

    public static let id: CommandID = "tilemap.erase"
    public static let title = "Erase Tilemap"
    public static let doc = "Clears `cells` [[x, y], …], a `rect` [x0, y0, x1, y1] or `all` of a layer in one undoable step. With `terrain`, the terrain cells around them are re-tiled so the new edges get border tiles."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TilemapResult {
        var (id, map) = try session.resolveTilemap(arguments, title)
        let layer = try layerIndex(arguments.layer, in: map, title)
        var cells = try cellPairs(arguments.cells, title)
        cells += try rectCells(arguments.rect, in: map, title) ?? []
        if arguments.all == true { cells = map.rectCells(0, 0, map.cols - 1, map.rowCount - 1) }
        guard !cells.isEmpty else { throw CommandError.failed("\(title): give cells, rect or all") }
        let changed: Int
        if let name = arguments.terrain {
            guard let t = map.terrainIndex(named: name) else { throw CommandError.failed("\(title): no terrain named '\(name)'") }
            changed = map.paintTerrain(layer: layer, terrain: t, cells: cells, erase: true)
        } else {
            changed = map.paint(layer: layer, cells: cells, .empty)
        }
        let warnings = try session.commands.require(session.applyTilemap(map, to: id, label: title), title)
        return TilemapResult(id, map, warnings: warnings, changed: changed, in: session)
    }
}
