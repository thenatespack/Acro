import EditorCore
import Engine
import Foundation

// The Tilemap Builder sidebar: the tile palette, the selected tile's data (collision, one-way,
// tags, properties, animation), layers (add, remove, reorder, hide in the canvas, settings),
// terrain sets, object points and the map's settings. Every change is one undo step through the
// workspace (`TilemapWorkspace.apply`), written on the next `update`.

/// The map's scalar settings as the grid's rows.
struct TilemapSettingsProxy: Component, Codable, Equatable {
    static let componentName = "Tilemap"
    static var fieldHints: [String: FieldHints] {
        ["columns": FieldHints(range: 1...Double(Tilemap.maxSide), step: 1), "rows": FieldHints(range: 1...Double(Tilemap.maxSide), step: 1),
         "tileWidth": FieldHints(range: 1...1024, step: 1), "tileHeight": FieldHints(range: 1...1024, step: 1),
         "pixelsPerUnit": FieldHints(range: 0...4096, step: 1, tooltip: "0: one tile is one world unit wide"),
         "chunkSize": FieldHints(range: 1...256, step: 1, tooltip: "Cells per chunk mesh / culling unit"),
         "background": FieldHints(color: true, tooltip: "Shown behind the map here (alpha 0: none)"),
         "filter": FieldHints(tooltip: "nearest keeps pixel art crisp")]
    }
    var columns = 40, rows = 22, tileWidth = 16, tileHeight = 16
    var pixelsPerUnit: Float = 0
    var chunkSize = 16
    var filter = "nearest"
    var background = Vec4(0, 0, 0, 0)

    init(_ m: Tilemap) {
        columns = m.cols
        rows = m.rowCount
        tileWidth = m.tileW
        tileHeight = m.tileH
        pixelsPerUnit = m.pixelsPerUnit
        chunkSize = m.chunk
        filter = m.tileset.filter
        background = m.background ?? Vec4(0, 0, 0, 0)
    }
}

/// A layer's settings (its cells stay out of the grid).
struct TilemapLayerProxy: Component, Codable, Equatable {
    static let componentName = "Tilemap Layer"
    static var fieldHints: [String: FieldHints] { TilemapLayer.fieldHints }
    var name: String
    var order: Float
    var parallax: Vec2
    var opacity: Float
    var visible: Bool
    var collision: Bool

    init(_ m: Tilemap, _ i: Int) {
        let l = m.layers[i]
        name = l.name
        order = m.order(ofLayer: i)
        parallax = l.parallax
        opacity = l.opacity
        visible = l.visible
        collision = l.collision
    }
}

/// One tile's data with the lists as text.
struct TilemapTileProxy: Component, Codable, Equatable {
    static let componentName = "Tilemap Tile"
    static var fieldHints: [String: FieldHints] {
        ["collision": FieldHints(tooltip: "The tile's collision shape (follows flips and turns)"),
         "oneWay": FieldHints(tooltip: "Bodies pass through from below and land on top (the side the tile's top faces once turned or flipped)"),
         "tags": FieldHints(tooltip: "Comma separated (hazard, ladder…); game code asks Tilemap.hasTag"),
         "points": FieldHints(tooltip: "polygon collision: x y pairs 0-1 (y up), comma separated: 0 0, 1 0, 1 1"),
         "animationFrames": FieldHints(tooltip: "Tile indices to play, comma separated (blank: not animated)"),
         "animationFps": FieldHints(range: 0...60, step: 0.5), "animationMode": FieldHints(tooltip: "loop or pingPong"),
         "properties": FieldHints(tooltip: "Custom properties as a JSON object: {\"damage\": 1}")]
    }
    var name = ""
    var collision = "none"
    var oneWay = false
    var tags = ""
    var points = ""
    var animationFrames = ""
    var animationFps: Float = 8
    var animationMode = "loop"
    var properties = "{}"

    init(_ t: TilemapTile) {
        name = t.name
        collision = t.collision.rawValue
        oneWay = t.oneWay
        tags = t.tags.joined(separator: ", ")
        points = t.points.map { String(format: "%g %g", $0.x, $0.y) }.joined(separator: ", ")
        animationFrames = t.animation?.frames.map(String.init).joined(separator: ", ") ?? ""
        animationFps = t.animation?.fps ?? 8
        animationMode = t.animation?.mode ?? "loop"
        if !t.properties.isEmpty, let data = try? JSONEncoder().encode(t.properties) { properties = String(decoding: data, as: UTF8.self) }
    }

    /// The tile entry these fields describe (nil with a reason if a field doesn't parse).
    func tile(index: Int) -> Result<TilemapTile, CommandError> {
        let numbers = { (text: String) in text.split(whereSeparator: { $0 == "," || $0 == " " }).compactMap { Float($0) } }
        let p = numbers(points)
        guard p.count % 2 == 0 else { return .failure(.failed("points need x y pairs")) }
        var props: [String: JSONValue] = [:]
        let trimmed = properties.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            guard let parsed = try? JSONDecoder().decode([String: JSONValue].self, from: Data(trimmed.utf8)) else {
                return .failure(.failed("properties must be a JSON object"))
            }
            props = parsed
        }
        let frames = numbers(animationFrames).map { Int($0) }
        return .success(TilemapTile(
            index: index, name: name, collision: TileCollision(rawValue: collision) ?? .none,
            points: stride(from: 0, to: p.count, by: 2).map { Vec2(p[$0], p[$0 + 1]) }, oneWay: oneWay,
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }, properties: props,
            animation: frames.isEmpty ? nil : TilemapAnimation(frames: frames, fps: animationFps, mode: animationMode)))
    }
}

/// A terrain set with its mask table as text.
struct TilemapTerrainProxy: Component, Codable, Equatable {
    static let componentName = "Tilemap Terrain"
    static var fieldHints: [String: FieldHints] {
        ["mode": FieldHints(tooltip: "edges: 4 sides (16 tiles); blob: sides and corners (47 tiles)"),
         "first": FieldHints(range: -1...65535, step: 1, tooltip: "edges: tile of mask 0; the 16 tiles follow in mask order (-1: none)"),
         "tiles": FieldHints(tooltip: "mask:tile pairs, comma separated (overrides first): 15:10, 0:3"),
         "fill": FieldHints(range: -1...65535, step: 1, tooltip: "Tile for masks without one (-1: closest match)"),
         "edgesConnect": FieldHints(tooltip: "The map's edge counts as this terrain")]
    }
    var name: String
    var mode: String
    var first: Int
    var tiles: String
    var fill: Int
    var edgesConnect: Bool

    init(_ t: TilemapTerrainSet) {
        name = t.name
        mode = t.mode.rawValue
        first = t.first
        tiles = t.tiles.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }.map { "\($0.key):\($0.value)" }.joined(separator: ", ")
        fill = t.fill ?? -1
        edgesConnect = t.edgesConnect
    }

    var terrain: TilemapTerrainSet {
        var table: [String: Int] = [:]
        for pair in tiles.split(separator: ",") {
            let parts = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let m = Int(parts[0]), let t = Int(parts[1]) { table[String(m)] = t }
        }
        return TilemapTerrainSet(name: name, mode: TilemapTerrainMode(rawValue: mode) ?? .edges, first: first, tiles: table,
                                 fill: fill >= 0 ? fill : nil, edgesConnect: edgesConnect)
    }
}

struct TilemapObjectProxy: Component, Codable, Equatable {
    static let componentName = "Tilemap Object"
    static var fieldHints: [String: FieldHints] { TilemapObject.fieldHints }
    var object: TilemapObject
    init(_ object: TilemapObject) { self.object = object }
    init(from decoder: any Decoder) throws { object = try TilemapObject(from: decoder) }
    func encode(to encoder: any Encoder) throws { try object.encode(to: encoder) }
}

/// Builds the sidebar for the workspace's open tilemap.
@MainActor
public final class TilemapBuilderView {
    unowned let workspace: TilemapWorkspace
    public let view = VStack(spacing: 6, name: "tilemapBuilder")
    let layerList = ListView(items: [], name: "tilemapLayers")
    let terrainList = ListView(items: [], name: "tilemapTerrains")
    let objectList = ListView(items: [], name: "tilemapObjects")
    private let formWorld = World()
    private var formEntities: [Entity] = []
    private var grids: [PropertyGrid] = []

    init(workspace: TilemapWorkspace) {
        self.workspace = workspace
        layerList.style.height = 96
        terrainList.style.height = 64
        objectList.style.height = 80
        layerList.onSelect = { [unowned self] row in
            guard let row, row != self.workspace.selectedLayer else { return }
            self.workspace.selectedLayer = row
            self.workspace.setNeedsSidebar()
        }
        terrainList.onSelect = { [unowned self] row in
            guard let row, row != self.workspace.selectedTerrain else { return }
            self.workspace.selectedTerrain = row
            if self.workspace.tool != .erase { self.workspace.tool = .terrain }
            self.workspace.setNeedsSidebar()
        }
        objectList.onSelect = { [unowned self] row in
            guard let row, row != self.workspace.selectedObject else { return }
            self.workspace.selectedObject = row
            self.workspace.setNeedsSidebar()
        }
    }

    private var session: EditorSession { workspace.session }

    /// Keeps the grids in step with their proxies; call every frame.
    func refresh() { for grid in grids { grid.refresh() } }

    // MARK: Layout

    func layout() {
        view.removeAllChildren()
        grids = []
        for entity in formEntities { formWorld.despawn(entity) }
        formEntities = []
        guard let map = workspace.map, let asset = workspace.asset else { return }

        let place = Button("Place in Scene", role: .primary, name: "tilemapPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this map in the scene: layer meshes, Collider2D shapes and object points (copies update when you paint here)"
        view.addChild(HStack(spacing: 6, [place, Spacer()]))

        addPalette(map)
        view.addChild(Separator())
        addLayers(map)
        view.addChild(Separator())
        addTerrains(map)
        view.addChild(Separator())
        addObjects(map)
        view.addChild(Separator())
        addSettings(map)
    }

    private func section(_ text: String) { view.addChild(Label(text, role: .secondary)) }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "tilemapNote")
        label.wraps = true
        return label
    }

    private func makeGrid(_ entity: Entity, name: String) -> PropertyGrid {
        let grid = PropertyGrid(world: formWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 110
        grid.entity = entity
        grid.command = TilemapEditCommand.id.rawValue
        grids.append(grid)
        return grid
    }

    /// A grid over a proxy component: edits update the proxy, finished edits call `commit`.
    private func grid<P: Component & Codable>(_ proxy: P, name: String, choices: [String: [String]] = [:], commit: @escaping (P) -> Void) -> PropertyGrid {
        let entity = formWorld.spawn(proxy)
        formEntities.append(entity)
        let grid = makeGrid(entity, name: name)
        if !choices.isEmpty { grid.stringChoices = { _, path in choices[path] } }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: P.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Tilemap \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let value = formWorld.get(P.self, for: entity) { commit(value) }
        }
        return grid
    }

    // MARK: Palette and tile data

    private func addPalette(_ map: Tilemap) {
        section("Tiles")
        view.addChild(workspace.palette)
        let tile = workspace.brushTile
        let random = workspace.randomTiles.count > 1 ? " · random set: \(workspace.randomTiles.map(String.init).joined(separator: ", "))" : ""
        view.addChild(note("Brush: tile \(tile)\(random). Click a tile to paint with it; Shift-click builds the Random set; right-click the map picks."))
        guard let layout = workspace.layout, layout.contains(tile) else {
            view.addChild(note(workspace.layout == nil ? "The tile set didn't import; check the map's tile set source below." : "Pick a tile to edit its data."))
            return
        }
        let entry = map.tileset.tile(tile) ?? TilemapTile(index: tile)
        view.addChild(Label("Tile \(tile)", role: .caption))
        view.addChild(grid(TilemapTileProxy(entry), name: "tilemapTileGrid",
                           choices: ["collision": TileCollision.allCases.map(\.rawValue), "animationMode": ["loop", "pingPong"]]) { [unowned self] proxy in
            switch proxy.tile(index: tile) {
            case .success(let edited):
                guard var m = workspace.current else { return }
                m.tileset.setTile(edited)
                workspace.apply(m, label: "Edit Tile")
            case .failure(let error):
                session.log.error("Tile \(tile): \(error)")
                workspace.setNeedsSidebar()
            }
        })
    }

    // MARK: Layers

    private func addLayers(_ map: Tilemap) {
        section("Layers")
        let painted = map.paintedCounts
        layerList.items = map.layers.enumerated().map { i, l in
            (workspace.hiddenLayers.contains(l.name) ? "◌ " : "") + l.name + "  ·  \(painted[i]) cells" + (l.collision ? "  ·  collides" : "")
        }
        if map.layers.indices.contains(workspace.selectedLayer) { layerList.selectRow(workspace.selectedLayer, reveal: true) }
        view.addChild(layerList)
        let add = Button("Add", name: "tilemapAddLayer") { [unowned self] in addLayer() }
        let remove = Button("Remove", name: "tilemapRemoveLayer") { [unowned self] in removeLayer() }
        let up = Button("Forward", name: "tilemapLayerUp") { [unowned self] in moveLayer(by: 1) }
        let down = Button("Back", name: "tilemapLayerDown") { [unowned self] in moveLayer(by: -1) }
        let hide = Button(workspace.hiddenLayers.contains(map.layers.indices.contains(workspace.selectedLayer) ? map.layers[workspace.selectedLayer].name : "")
                          ? "Show" : "Hide", name: "tilemapHideLayer") { [unowned self] in toggleHidden() }
        let dim = Button("Dim Others", role: workspace.dimsOtherLayers ? .primary : .normal, name: "tilemapDimLayers") { [unowned self] in
            workspace.dimsOtherLayers.toggle()
            workspace.setNeedsSidebar()
        }
        for b in [add, remove, up, down] { b.command = TilemapEditCommand.id.rawValue }
        remove.isEnabled = map.layers.count > 1
        up.tooltip = "Draw the layer in front of the next one"
        hide.tooltip = "Hide the layer in this view only (the file keeps it)"
        let row = HStack(spacing: 4, [add, remove, up, down, hide, dim])
        row.wraps = true
        view.addChild(row)
        guard map.layers.indices.contains(workspace.selectedLayer) else { return }
        let index = workspace.selectedLayer
        view.addChild(grid(TilemapLayerProxy(map, index), name: "tilemapLayerGrid") { [unowned self] proxy in commitLayer(proxy, at: index) })
    }

    private func commitLayer(_ proxy: TilemapLayerProxy, at index: Int) {
        guard var m = workspace.current, m.layers.indices.contains(index) else { return }
        var layer = m.layers[index]
        let name = proxy.name.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty, !m.layers.enumerated().contains(where: { $0.offset != index && $0.element.name == name }) { layer.name = name }
        layer.order = proxy.order == Float(index) && layer.order == nil ? nil : proxy.order
        layer.parallax = proxy.parallax
        layer.opacity = min(max(proxy.opacity, 0), 1)
        layer.visible = proxy.visible
        layer.collision = proxy.collision
        m.layers[index] = layer
        workspace.apply(m, label: "Edit Layer")
    }

    func addLayer() {
        guard var m = workspace.current else { return }
        m.layers.append(TilemapLayer(name: EditorBuilderSupport.uniqueName("Layer", among: m.layers.map(\.name)), collision: false))
        m.normalize()
        workspace.selectedLayer = m.layers.count - 1
        workspace.apply(m, label: "Add Layer")
    }

    func removeLayer() {
        guard var m = workspace.current, m.layers.count > 1, m.layers.indices.contains(workspace.selectedLayer) else { return }
        m.layers.remove(at: workspace.selectedLayer)
        workspace.selectedLayer = max(workspace.selectedLayer - 1, 0)
        workspace.apply(m, label: "Remove Layer")
    }

    /// Moves the selected layer forward (+1) or back (-1) in the list (its draw order follows unless it has an explicit `order`).
    func moveLayer(by step: Int) {
        guard var m = workspace.current else { return }
        let i = workspace.selectedLayer, j = i + step
        guard m.layers.indices.contains(i), m.layers.indices.contains(j) else { return }
        m.layers.swapAt(i, j)
        workspace.selectedLayer = j
        workspace.apply(m, label: "Reorder Layers")
    }

    private func toggleHidden() {
        guard let m = workspace.map, m.layers.indices.contains(workspace.selectedLayer) else { return }
        let name = m.layers[workspace.selectedLayer].name
        if workspace.hiddenLayers.contains(name) { workspace.hiddenLayers.remove(name) } else { workspace.hiddenLayers.insert(name) }
        workspace.setNeedsSidebar()
    }

    // MARK: Terrains

    private func addTerrains(_ map: Tilemap) {
        section("Terrains (auto-tiling)")
        terrainList.items = map.terrains.map { "\($0.name)  ·  \($0.mode.rawValue)  ·  \($0.table.count) tiles" }
        if map.terrains.indices.contains(workspace.selectedTerrain) { terrainList.selectRow(workspace.selectedTerrain, reveal: true) }
        view.addChild(terrainList)
        let add = Button("Add", name: "tilemapAddTerrain") { [unowned self] in
            guard var m = workspace.current else { return }
            m.terrains.append(TilemapTerrainSet(name: EditorBuilderSupport.uniqueName("Terrain", among: m.terrains.map(\.name)), first: workspace.brushTile))
            workspace.selectedTerrain = m.terrains.count - 1
            workspace.apply(m, label: "Add Terrain")
        }
        add.tooltip = "A 16-tile edge set starting at the brush tile (tiles in mask order: N 1, E 2, S 4, W 8)"
        let remove = Button("Remove", name: "tilemapRemoveTerrain") { [unowned self] in
            guard var m = workspace.current, m.terrains.indices.contains(workspace.selectedTerrain) else { return }
            m.terrains.remove(at: workspace.selectedTerrain)
            workspace.apply(m, label: "Remove Terrain")
        }
        remove.isEnabled = !map.terrains.isEmpty
        let retile = Button("Re-tile Layer", name: "tilemapRetile") { [unowned self] in
            guard var m = workspace.current, m.terrains.indices.contains(workspace.selectedTerrain),
                  m.layers.indices.contains(workspace.selectedLayer) else { return }
            m.autotile(layer: workspace.selectedLayer, terrain: workspace.selectedTerrain)
            workspace.apply(m, label: "Re-tile Terrain")
        }
        retile.tooltip = "Pick every terrain tile of the selected layer again from its neighbors"
        for b in [add, remove, retile] { b.command = TilemapEditCommand.id.rawValue }
        view.addChild(HStack(spacing: 4, [add, remove, retile, Spacer()]))
        guard map.terrains.indices.contains(workspace.selectedTerrain) else {
            view.addChild(note("A terrain set picks edge and corner tiles as you paint with the Terrain tool."))
            return
        }
        let index = workspace.selectedTerrain
        view.addChild(grid(TilemapTerrainProxy(map.terrains[index]), name: "tilemapTerrainGrid",
                           choices: ["mode": TilemapTerrainMode.allCases.map(\.rawValue)]) { [unowned self] proxy in
            guard var m = workspace.current, m.terrains.indices.contains(index) else { return }
            var terrain = proxy.terrain
            if terrain.name.trimmingCharacters(in: .whitespaces).isEmpty { terrain.name = m.terrains[index].name }
            m.terrains[index] = terrain
            workspace.apply(m, label: "Edit Terrain")
        })
    }

    // MARK: Objects

    private func addObjects(_ map: Tilemap) {
        section("Objects")
        objectList.items = map.objects.map { "\($0.name)\($0.type.isEmpty ? "" : "  ·  " + $0.type)  ·  \(String(format: "%.1f, %.1f", $0.position.x, $0.position.y))" }
        if let o = workspace.selectedObject, map.objects.indices.contains(o) { objectList.selectRow(o, reveal: true) }
        view.addChild(objectList)
        let remove = Button("Remove", name: "tilemapRemoveObject") { [unowned self] in
            guard var m = workspace.current, let o = workspace.selectedObject, m.objects.indices.contains(o) else { return }
            m.objects.remove(at: o)
            workspace.selectedObject = nil
            workspace.apply(m, label: "Remove Object")
        }
        remove.command = TilemapEditCommand.id.rawValue
        remove.isEnabled = workspace.selectedObject != nil
        let tool = Button("Object Tool", name: "tilemapObjectTool") { [unowned self] in workspace.tool = .object }
        view.addChild(HStack(spacing: 4, [tool, remove, Spacer()]))
        guard let index = workspace.selectedObject, map.objects.indices.contains(index) else {
            view.addChild(note("Object points (spawns, triggers, pickups) become named nodes of the placed prefab; game code finds them with Tilemap.object(named:)."))
            return
        }
        view.addChild(grid(TilemapObjectProxy(map.objects[index]), name: "tilemapObjectGrid") { [unowned self] proxy in
            guard var m = workspace.current, m.objects.indices.contains(index) else { return }
            var object = proxy.object
            object.properties = m.objects[index].properties
            m.objects[index] = object
            workspace.apply(m, label: "Edit Object")
        })
    }

    // MARK: Settings

    private func addSettings(_ map: Tilemap) {
        section("Map")
        view.addChild(grid(TilemapSettingsProxy(map), name: "tilemapSettingsGrid", choices: ["filter": ["nearest", "linear"]]) { [unowned self] s in
            guard let m = workspace.current else { return }
            let arguments = TilemapEditCommand.Arguments(size: [s.columns, s.rows], tileSize: [s.tileWidth, s.tileHeight], pixelsPerUnit: s.pixelsPerUnit,
                                                         chunkSize: s.chunkSize, filter: s.filter)
            do {
                var edited = try TilemapEditCommand.edited(m, with: arguments)
                edited.background = s.background.w > 0 ? s.background : nil
                workspace.apply(edited, label: "Edit Tilemap")
            } catch {
                session.log.error("Tilemap: \(error)")
                workspace.setNeedsSidebar()
            }
        })
        let source: String
        switch map.tileset.source {
        case .image(let path, _, _): source = path.isEmpty ? "no image" : path
        case .images(let paths): source = "\(paths.count) images"
        case .sprite(let path): source = path.isEmpty ? "no sprite" : "\(path) (tile i = frame i)"
        case .unsupported(let kind, _): source = "\(kind) (not supported)"
        }
        let images = imagePaths()
        if !images.isEmpty {
            var current = 0
            switch map.tileset.source {
            case .image(let path, _, _), .sprite(let path): current = images.firstIndex(of: path).map { $0 + 1 } ?? 0
            default: break
            }
            let picker = Dropdown(options: ["Tile set image or sprite…"] + images, selectedIndex: current, name: "tilemapTilesetImage") { [unowned self] i in
                guard i > 0, var m = workspace.current else { return }
                let path = images[i - 1]
                m.tileset.source = TilesetSource(path: path)
                // A sprite's frames are the tiles: take its frame size.
                if case .sprite = m.tileset.source, let assets = session.assets, let id = assets.id(forPath: path),
                   let sprite = assets.pixelSprite(of: id), sprite.width > 0, sprite.height > 0 {
                    m.tileWidth = sprite.width
                    m.tileHeight = sprite.height
                }
                workspace.apply(m, label: "Change Tile Set")
            }
            picker.tooltip = "Slice another image into \(map.tileW) x \(map.tileH) tiles, or use a Pixel Sprite's frames as tiles (its tags animate them)"
            view.addChild(picker)
        }
        var text = "Tile set: \(source), \(workspace.layout?.count ?? 0) tiles of \(map.tileW) x \(map.tileH) px. One tile is \(String(format: "%g", map.cellSize.x)) world units wide."
        if !workspace.tagAnimations.isEmpty {
            text += " Sprite tags animate tile\(workspace.tagAnimations.count == 1 ? "" : "s") \(workspace.tagAnimations.keys.sorted().map(String.init).joined(separator: ", "))."
        }
        view.addChild(note(text))
    }

    private func imagePaths() -> [String] {
        let extensions = ["png", "jpg", "jpeg", "tga", "bmp", "sprite"]
        return (session.assets?.allRecords ?? []).map(\.path).filter { path in extensions.contains { path.lowercased().hasSuffix("." + $0) } }
    }
}
