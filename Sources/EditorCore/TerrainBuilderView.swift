import Engine
import Foundation

// The Terrain Builder form: the sidebar for a `.terrain` file. Pick a brush (raise, lower, smooth,
// flatten, noise, paint, erase paint) and its radius, strength and falloff, then drag over the
// terrain in the workspace's viewport; edit the terrain's settings, texture layers and scatter
// rules in property grids. Every change is written to the file at once as one undo step
// (`EditorSession.applyTerrain`), so the terrain reimports and placed copies update; Ctrl+Z takes
// changes back. A stroke is one step.

/// What the brush does.
public enum TerrainBrushTool: String, CaseIterable, Sendable {
    case raise, lower, smooth, flatten, noise, paint, erase

    public var title: String {
        switch self {
        case .paint: "Paint"
        case .erase: "Erase paint"
        default: rawValue.capitalized
        }
    }

    public var sculptBrush: TerrainBrush? { TerrainBrush(rawValue: rawValue) }
}

/// The brush the workspace's viewport uses; shared between the form (sets it) and the view tool.
@MainActor
public final class TerrainBrushSettings {
    public var tool = TerrainBrushTool.raise
    public var radius: Float = 8
    /// 0...1; raise, lower and noise move up to `2 * strength` meters per dab.
    public var strength: Float = 0.5
    public var falloff: Float = 0.7
    public init() {}
}

/// The terrain's scalar settings as the grid's rows (the data and lists stay out of it).
struct TerrainSettings: Codable, Equatable {
    var size = Vec2(128, 128)
    var resolution = 129
    var heightRange: Float = 64
    var chunkCells = 32
    var lods = 1
    var collider = true
    var colliderLod = 0
    var albedoSize = 0
    var seed = 1

    init(_ t: Terrain) {
        size = t.size
        resolution = t.res
        heightRange = t.heightRange
        chunkCells = t.chunkCells
        lods = t.lods
        collider = t.collider
        colliderLod = t.colliderLod
        albedoSize = t.albedoSize
        seed = t.seed
    }

    private enum CodingKeys: String, CodingKey { case size, resolution, heightRange, chunkCells, lods, collider, colliderLod, albedoSize, seed }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TerrainSettings(Terrain())
        size = try c.decodeIfPresent(Vec2.self, forKey: .size) ?? d.size
        resolution = try c.decodeIfPresent(Int.self, forKey: .resolution) ?? d.resolution
        heightRange = try c.decodeIfPresent(Float.self, forKey: .heightRange) ?? d.heightRange
        chunkCells = try c.decodeIfPresent(Int.self, forKey: .chunkCells) ?? d.chunkCells
        lods = try c.decodeIfPresent(Int.self, forKey: .lods) ?? d.lods
        collider = try c.decodeIfPresent(Bool.self, forKey: .collider) ?? d.collider
        colliderLod = try c.decodeIfPresent(Int.self, forKey: .colliderLod) ?? d.colliderLod
        albedoSize = try c.decodeIfPresent(Int.self, forKey: .albedoSize) ?? d.albedoSize
        seed = try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed
    }
}

struct TerrainSettingsComponent: Component {
    static var componentName: String { "Terrain" }
    static var fieldHints: [String: FieldHints] { Terrain.fieldHints }
    var settings: TerrainSettings
    init(_ settings: TerrainSettings) { self.settings = settings }
    init(from decoder: any Decoder) throws { settings = try TerrainSettings(from: decoder) }
    func encode(to encoder: any Encoder) throws { try settings.encode(to: encoder) }
}

struct TerrainLayerComponent: Component {
    static var componentName: String { "Layer" }
    static var fieldHints: [String: FieldHints] { TerrainLayer.fieldHints }
    var layer: TerrainLayer
    init(_ layer: TerrainLayer) { self.layer = layer }
    init(from decoder: any Decoder) throws { layer = try TerrainLayer(from: decoder) }
    func encode(to encoder: any Encoder) throws { try layer.encode(to: encoder) }
}

struct TerrainScatterComponent: Component {
    static var componentName: String { "Scatter" }
    static var fieldHints: [String: FieldHints] { TerrainScatter.fieldHints }
    var rule: TerrainScatter
    init(_ rule: TerrainScatter) { self.rule = rule }
    init(from decoder: any Decoder) throws { rule = try TerrainScatter(from: decoder) }
    func encode(to encoder: any Encoder) throws { try rule.encode(to: encoder) }
}

/// Edits one `.terrain` file. Rebuilt by the workspace whenever the file is reimported.
@MainActor
public final class TerrainBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var terrain: Terrain
    public let brush: TerrainBrushSettings
    /// The layer being edited, and the one the paint brush uses.
    public private(set) var selectedLayer: Int?
    public private(set) var selectedScatter: Int?
    public let showsTitle: Bool

    let layerList = ListView(items: [], name: "terrainLayers")
    let scatterList = ListView(items: [], name: "terrainScatter")
    private let formWorld = World()
    private var formEntities: [Entity] = []
    private var grids: [PropertyGrid] = []
    private static var selections: [AssetID: (layer: Int?, scatter: Int?)] = [:]

    public init?(session: EditorSession, asset: AssetID, brush: TerrainBrushSettings, showsTitle: Bool = true) {
        guard session.isTerrainFile(asset), var terrain = session.assets?.terrain(of: asset) else { return nil }
        terrain.resolution = terrain.res
        terrain.normalizeData()
        self.session = session
        self.asset = asset
        self.terrain = terrain
        self.brush = brush
        self.showsTitle = showsTitle
        view = VStack(spacing: 6, name: "terrainBuilder")
        let remembered = Self.selections[asset]
        selectedLayer = remembered?.layer.flatMap { terrain.layers.indices.contains($0) ? $0 : nil } ?? (terrain.layers.isEmpty ? nil : 0)
        selectedScatter = remembered?.scatter.flatMap { terrain.scatter.indices.contains($0) ? $0 : nil }
        layerList.style.height = 90
        scatterList.style.height = 90
        layerList.onSelect = { [unowned self] row in
            guard let row, row != selectedLayer, self.terrain.layers.indices.contains(row) else { return }
            selectedLayer = row
            remember()
            layout()
        }
        scatterList.onSelect = { [unowned self] row in
            guard let row, row != selectedScatter, self.terrain.scatter.indices.contains(row) else { return }
            selectedScatter = row
            remember()
            layout()
        }
        layout()
    }

    /// An edit made by a widget callback, applied on the next `refresh` so no widget is torn
    /// down while it is handling an event.
    private var pending: (terrain: Terrain, label: String)?

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.terrain, label: pending.label)
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, var t = session.assets?.terrain(of: asset) else { return }
        t.resolution = t.res
        t.normalizeData()
        terrain = t
        clampSelection()
        layout()
    }

    private func clampSelection() {
        if let l = selectedLayer, !terrain.layers.indices.contains(l) { selectedLayer = terrain.layers.isEmpty ? nil : 0 }
        if let s = selectedScatter, !terrain.scatter.indices.contains(s) { selectedScatter = nil }
    }

    private func remember() { Self.selections[asset] = (selectedLayer, selectedScatter) }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        grids = []
        for entity in formEntities { formWorld.despawn(entity) }
        formEntities = []

        let title = Label("Terrain Builder", role: .heading)
        title.icon = EditorIcons.asset(.model)
        let place = Button("Place in Scene", role: .primary, name: "terrainPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this terrain in the scene (copies update when you change it here)"
        view.addChild(showsTitle ? HStack(spacing: 6, [title, Spacer(), place]) : HStack(spacing: 6, [place, Spacer()]))

        addBrushSection()
        view.addChild(Separator())
        addSettingsSection()
        view.addChild(Separator())
        addLayerSection()
        view.addChild(Separator())
        addScatterSection()
    }

    private func slider(_ label: String, value: Float, range: ClosedRange<Float>, step: Float, name: String, tooltip: String,
                        set: @escaping (Float) -> Void) -> Widget {
        let caption = Label(label, role: .caption)
        caption.style.width = 64
        let slider = Slider(value: value, in: range, step: step, name: name)
        slider.style.grow = 1
        slider.tooltip = tooltip
        let readout = Label(String(format: "%g", value), role: .caption)
        readout.style.width = 36
        slider.onChange = { v in
            set(v)
            readout.text = String(format: "%g", v)
        }
        return HStack(spacing: 6, [caption, slider, readout])
    }

    private func addBrushSection() {
        view.addChild(Label("Brush", role: .secondary))
        let tools = HStack(spacing: 4, name: "terrainBrushes")
        tools.wraps = true
        for tool in TerrainBrushTool.allCases {
            let button = Button(tool.title, role: tool == brush.tool ? .primary : .normal, name: "terrainBrush.\(tool.rawValue)") { [unowned self] in
                brush.tool = tool
                layout()
            }
            button.tooltip = tool == .paint || tool == .erase ? "Drag over the terrain to paint the selected layer"
                : "Drag over the terrain to \(tool.rawValue)"
            tools.addChild(button)
        }
        view.addChild(tools)
        view.addChild(slider("Radius", value: brush.radius, range: 1...64, step: 0.5, name: "terrainRadius", tooltip: "Brush size in meters") {
            [unowned self] in brush.radius = $0
        })
        view.addChild(slider("Strength", value: brush.strength, range: 0.05...1, step: 0.05, name: "terrainStrength",
                             tooltip: "How hard each dab pushes (raise and lower move up to twice this in meters)") {
            [unowned self] in brush.strength = $0
        })
        view.addChild(slider("Falloff", value: brush.falloff, range: 0...1, step: 0.05, name: "terrainFalloff",
                             tooltip: "0 is a hard edge, 1 a soft dome") { [unowned self] in brush.falloff = $0 })
        let note = Label(brush.tool == .paint || brush.tool == .erase
                         ? "Painting layer \(selectedLayer.flatMap { terrain.layers.indices.contains($0) ? terrain.layers[$0].name : nil } ?? "(none: add a layer)")."
                         : "Left-drag on the terrain. Right-drag orbits, Shift pans, the wheel zooms.", role: .caption, name: "terrainBrushNote")
        note.wraps = true
        view.addChild(note)
    }

    private func addSettingsSection() {
        view.addChild(Label("Terrain", role: .secondary))
        let entity = formWorld.spawn(TerrainSettingsComponent(TerrainSettings(terrain)))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "terrainSettingsGrid", command: TerrainEditCommand.id.rawValue)
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: TerrainSettingsComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Terrain \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let s = formWorld.get(TerrainSettingsComponent.self, for: entity)?.settings { commitSettings(s) }
        }
        view.addChild(grid)
        view.addChild(note("Resolution resamples the heights and paint; changing the height range keeps heights in meters."))
    }

    private func addLayerSection() {
        view.addChild(Label("Layers", role: .secondary))
        layerList.items = terrain.layers.map { $0.name + ($0.texture.isEmpty ? "" : "  ·  " + $0.texture) }
        if let selectedLayer { layerList.selectRow(selectedLayer, reveal: true) }
        view.addChild(layerList)
        let add = Button("Add Layer", name: "terrainAddLayer") { [unowned self] in addLayer() }
        let remove = Button("Remove", name: "terrainRemoveLayer") { [unowned self] in removeLayer() }
        add.command = TerrainEditCommand.id.rawValue
        remove.command = TerrainEditCommand.id.rawValue
        remove.isEnabled = selectedLayer != nil && terrain.layers.count > 1
        add.tooltip = "A new unpainted layer (give it a color or a texture)"
        remove.tooltip = "Remove the selected layer; its paint goes to the first layer"
        view.addChild(HStack(spacing: 6, [add, remove, Spacer()]))
        guard let index = selectedLayer, terrain.layers.indices.contains(index) else {
            view.addChild(note("Add a layer to paint with."))
            return
        }
        let entity = formWorld.spawn(TerrainLayerComponent(terrain.layers[index]))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "terrainLayerGrid", command: TerrainEditCommand.id.rawValue)
        grid.stringChoices = { [unowned self] _, path in path == "texture" ? [""] + texturePaths() : nil }
        grid.stringChoiceTitle = { _, _, value in value.isEmpty ? "None (flat color)" : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: TerrainLayerComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Terrain layer \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let layer = formWorld.get(TerrainLayerComponent.self, for: entity)?.layer { commitLayer(layer, at: index) }
        }
        view.addChild(grid)
    }

    private func addScatterSection() {
        view.addChild(Label("Scatter", role: .secondary))
        scatterList.items = terrain.scatter.map { "\($0.name)  ·  \($0.asset.isEmpty ? "no asset" : $0.asset)" }
        if let selectedScatter { scatterList.selectRow(selectedScatter, reveal: true) }
        view.addChild(scatterList)
        let add = Button("Add Rule", name: "terrainAddScatter") { [unowned self] in addScatter() }
        let remove = Button("Remove", name: "terrainRemoveScatter") { [unowned self] in removeScatter() }
        add.command = TerrainScatterCommand.id.rawValue
        remove.command = TerrainEditCommand.id.rawValue
        remove.isEnabled = selectedScatter != nil
        add.tooltip = "Scatter props (trees, rocks) by density, slope and height rules; drawn instanced"
        view.addChild(HStack(spacing: 6, [add, remove, Spacer()]))
        guard let index = selectedScatter, terrain.scatter.indices.contains(index) else {
            view.addChild(note("Pick or add a rule. Props are placed by the rules on a stable seed."))
            return
        }
        let entity = formWorld.spawn(TerrainScatterComponent(terrain.scatter[index]))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "terrainScatterGrid", command: TerrainEditCommand.id.rawValue)
        grid.stringChoices = { [unowned self] _, path in
            switch path {
            case "asset": return [""] + assetPaths(extension: "meshbuild") + current(terrain.scatter[index].asset, in: assetPaths(extension: "meshbuild"))
            case "layer": return [""] + terrain.layers.map(\.name)
            default: return nil
            }
        }
        grid.stringChoiceTitle = { _, _, value in value.isEmpty ? "None" : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: TerrainScatterComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Terrain scatter \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let rule = formWorld.get(TerrainScatterComponent.self, for: entity)?.rule { commitScatter(rule, at: index) }
        }
        view.addChild(grid)
        let count = terrain.instances(of: terrain.scatter[index]).count
        view.addChild(note("Places \(count) props right now."))
    }

    private func makeGrid(_ entity: Entity, name: String, command: String) -> PropertyGrid {
        let grid = PropertyGrid(world: formWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        grid.command = command
        grids.append(grid)
        return grid
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "terrainNote")
        label.wraps = true
        return label
    }

    // MARK: Choices

    private func assetPaths(extension ext: String) -> [String] {
        (session.assets?.allRecords ?? []).map(\.path).filter { $0.lowercased().hasSuffix("." + ext) }
    }

    private func texturePaths() -> [String] {
        let all = (session.assets?.allRecords ?? []).map(\.path)
        let extensions = ["png", "jpg", "jpeg", "tga", "proctex"]
        let found = all.filter { path in extensions.contains { path.lowercased().hasSuffix("." + $0) } }
        guard let index = selectedLayer, terrain.layers.indices.contains(index) else { return found }
        return found + current(terrain.layers[index].texture, in: found)
    }

    /// A value typed into the file is kept as a choice so the dropdown can show it.
    private func current(_ value: String, in choices: [String]) -> [String] {
        value.isEmpty || choices.contains(value) ? [] : [value]
    }

    // MARK: Edits

    /// Applies a finished brush stroke (terrain-space [x, z] points) as one edit.
    public func applyStroke(_ points: [Vec2]) {
        guard !points.isEmpty else { return }
        var edited = pending?.terrain ?? terrain
        switch brush.tool {
        case .paint, .erase:
            guard let layer = selectedLayer, edited.layers.indices.contains(layer) else {
                session.log.warning("Terrain Builder: add and select a layer to paint with")
                return
            }
            edited.paint(layer: layer, at: points, radius: brush.radius, strength: min(brush.strength * 1.6, 1), falloff: brush.falloff,
                         erase: brush.tool == .erase)
        default:
            guard let sculpt = brush.tool.sculptBrush else { return }
            let strength = [.raise, .lower, .noise].contains(brush.tool) ? brush.strength * 2 : brush.strength
            edited.sculpt(sculpt, at: points, radius: brush.radius, strength: strength, falloff: brush.falloff)
        }
        apply(edited, label: brush.tool.title + " Terrain")
    }

    private func apply(_ edited: Terrain, label: String) {
        pending = (edited, label)
    }

    private func commit(_ edited: Terrain, label: String) {
        guard session.applyTerrain(edited, to: asset, label: label) != nil else { return }
        terrain = session.assets?.terrain(of: asset) ?? edited
        terrain.resolution = terrain.res
        terrain.normalizeData()
        clampSelection()
        layout()
    }

    private func commitSettings(_ s: TerrainSettings) {
        let arguments = TerrainEditCommand.Arguments(size: s.size, resolution: s.resolution, heightRange: s.heightRange, chunkCells: s.chunkCells,
                                                     lods: s.lods, collider: s.collider, colliderLod: s.colliderLod, albedoSize: s.albedoSize,
                                                     seed: s.seed)
        do { apply(try TerrainEditCommand.edited(pending?.terrain ?? terrain, with: arguments), label: "Edit Terrain") } catch {
            session.log.error("Terrain: \(error)")
            layout()
        }
    }

    private func commitLayer(_ layer: TerrainLayer, at index: Int) {
        var edited = pending?.terrain ?? terrain
        guard edited.layers.indices.contains(index) else { return }
        let old = edited.layers[index].name
        var layer = layer
        layer.name = layer.name.trimmingCharacters(in: .whitespaces)
        if layer.name.isEmpty || edited.layers.enumerated().contains(where: { $0.offset != index && $0.element.name == layer.name }) {
            layer.name = old
        }
        if layer.name != old { for i in edited.scatter.indices where edited.scatter[i].layer == old { edited.scatter[i].layer = layer.name } }
        edited.layers[index] = layer
        apply(edited, label: "Edit Layer")
    }

    private func commitScatter(_ rule: TerrainScatter, at index: Int) {
        var edited = pending?.terrain ?? terrain
        guard edited.scatter.indices.contains(index) else { return }
        edited.scatter[index] = rule
        apply(edited, label: "Edit Scatter")
    }

    func addLayer() {
        var edited = terrain
        let name = TerrainEditCommand.uniqueName("Layer", among: edited.layers.map(\.name))
        edited.layers.append(TerrainLayer(name: name))
        selectedLayer = edited.layers.count - 1
        remember()
        apply(edited, label: "Add Layer")
    }

    func removeLayer() {
        guard let index = selectedLayer, terrain.layers.count > 1, terrain.layers.indices.contains(index) else { return }
        guard let edited = try? TerrainEditCommand.edited(terrain, with: .init(removeLayers: [terrain.layers[index].name])) else { return }
        selectedLayer = 0
        remember()
        apply(edited, label: "Remove Layer")
    }

    func addScatter() {
        var edited = terrain
        var rule = TerrainScatter(name: TerrainEditCommand.uniqueName("Scatter", among: edited.scatter.map(\.name)))
        rule.asset = assetPaths(extension: "meshbuild").first ?? ""
        edited.scatter.append(rule)
        selectedScatter = edited.scatter.count - 1
        remember()
        apply(edited, label: "Add Scatter")
    }

    func removeScatter() {
        guard let index = selectedScatter, terrain.scatter.indices.contains(index) else { return }
        var edited = terrain
        edited.scatter.remove(at: index)
        selectedScatter = nil
        remember()
        apply(edited, label: "Remove Scatter")
    }
}
