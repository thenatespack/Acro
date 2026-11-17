import EditorCore
import Engine
import Foundation

// The GridMap Builder form: the sidebar for a `.gridmap` file. Pick a brush (paint, line,
// rectangle, fill, erase, random), a piece from the library, the rotation, flips, layer and the
// floor being edited, then click or drag on the grid in the workspace's viewport. The library's
// pieces and the map's settings are edited in property grids. Every change is written to the
// file at once as one undo step (`EditorSession.applyGridMap`), so the map reimports and placed
// copies update; Ctrl+Z takes changes back. A brush stroke is one step.

/// What the brush does.
public enum GridMapBrushTool: String, CaseIterable, Sendable {
    case paint, line, rect, fill, erase, random

    public var title: String {
        switch self {
        case .paint: "Paint"
        case .line: "Line"
        case .rect: "Rectangle"
        case .fill: "Fill"
        case .erase: "Erase"
        case .random: "Random"
        }
    }

    /// Whether a drag collects every cell passed over (the others use the press and release cells).
    public var strokes: Bool { self == .paint || self == .erase || self == .random }

    /// Its number key in the tab (1 for Paint ... 6 for Random).
    public var shortcut: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }
}

/// The brush the workspace's viewport uses; shared between the form (sets it) and the view tool.
@MainActor
public final class GridMapBrushSettings {
    public var tool = GridMapBrushTool.paint
    /// The piece painted (a library name).
    public var piece = ""
    /// The pieces the random brush picks from (empty: just `piece`).
    public var randomSet: [String] = []
    /// The floor being edited.
    public var floor = 0
    /// Degrees: 0, 90, 180, 270.
    public var rotation = 0
    public var flipX = false
    public var flipZ = false
    /// The layer painted and erased ("": the piece's own layer; erase then clears every layer).
    public var layer = ""
    /// A changing seed so each random stroke differs.
    public var seed = 1
    public init() {}
}

/// The map's settings as the grid's rows.
struct GridMapSettingsForm: Codable, Equatable {
    var cellSize = Vec3(2, 3, 2)
    var chunkSize = 16
    var collider = true
    /// Comma-separated layer names.
    var layers = "floor, walls, props"

    init(_ m: GridMap) {
        cellSize = m.cellSize
        chunkSize = m.chunk
        collider = m.collider
        layers = m.layerNames.joined(separator: ", ")
    }
}

struct GridMapSettingsComponent: Component {
    static var componentName: String { "GridMapSettings" }
    static var fieldHints: [String: FieldHints] {
        GridMap.fieldHints.merging(["layers": FieldHints(tooltip: "Layer names, comma-separated (one piece per cell per layer)")]) { $1 }
    }
    var settings: GridMapSettingsForm
    init(_ settings: GridMapSettingsForm) { self.settings = settings }
    init(from decoder: any Decoder) throws { settings = try GridMapSettingsForm(from: decoder) }
    func encode(to encoder: any Encoder) throws { try settings.encode(to: encoder) }
}

/// A piece as the grid's rows (the footprint and join fields flattened).
struct GridPieceForm: Codable, Equatable {
    var name = "Piece"
    var asset = ""
    var material = ""
    var width = 1
    var depth = 1
    var size = Vec3.zero
    var offset = Vec3.zero
    var rotation: Float = 0
    var scale = Vec3.one
    var layer = ""
    var collider = "auto"
    var autoJoin = false
    var single = ""
    var end = ""
    var straight = ""
    var corner = ""
    var tee = ""
    var cross = ""
    /// Comma-separated piece names.
    var joinsWith = ""

    init(_ p: GridPiece) {
        name = p.name
        asset = p.asset
        material = p.material
        width = p.cells.x
        depth = p.cells.y
        size = p.size
        offset = p.offset
        rotation = p.rotation
        scale = p.scale
        layer = p.layer
        collider = p.collider.rawValue
        autoJoin = p.join != nil
        if let j = p.join {
            single = j.single
            end = j.end
            straight = j.straight
            corner = j.corner
            tee = j.tee
            cross = j.cross
            joinsWith = j.joinsWith.joined(separator: ", ")
        }
    }

    var piece: GridPiece {
        GridPiece(name: name.trimmingCharacters(in: .whitespaces), asset: asset, material: material,
                  footprint: SIMD2(min(max(width, 1), 64), min(max(depth, 1), 64)), size: size, offset: offset, rotation: rotation,
                  scale: scale, layer: layer, collider: GridPieceCollider(rawValue: collider) ?? .auto,
                  join: autoJoin ? GridJoin(single: single, end: end, straight: straight, corner: corner, tee: tee, cross: cross,
                                            joinsWith: joinsWith.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                                                .filter { !$0.isEmpty }) : nil)
    }

    static var fieldHints: [String: FieldHints] {
        ["asset": FieldHints(tooltip: "A .meshbuild, model (.gltf, .glb, .obj) or .prefab under Assets/, or asset:<id>#mesh/<name>"),
         "material": FieldHints(tooltip: "For a mesh reference: its material"),
         "width": FieldHints(range: 1...64, step: 1, tooltip: "Cells covered along x"),
         "depth": FieldHints(range: 1...64, step: 1, tooltip: "Cells covered along z"),
         "size": FieldHints(step: 0.05, tooltip: "Collision box in meters (0: the footprint, one floor high)"),
         "offset": FieldHints(step: 0.05, displayName: "Pivot", tooltip: "Meters the model is moved by in its cell"),
         "rotation": FieldHints(step: 90, tooltip: "Degrees that turn the model before the cell's rotation"),
         "scale": FieldHints(step: 0.05),
         "layer": FieldHints(tooltip: "The layer it is painted on by default"),
         "collider": FieldHints(tooltip: "auto: its triangles (or a box), mesh, box or none"),
         "autoJoin": FieldHints(displayName: "Auto-join", tooltip: "Pick the variant below that fits the neighbors"),
         "single": FieldHints(tooltip: "No neighbors"), "end": FieldHints(tooltip: "One neighbor (authored toward +x)"),
         "straight": FieldHints(tooltip: "Neighbors at +x and -x"), "corner": FieldHints(tooltip: "Neighbors at +x and +z"),
         "tee": FieldHints(tooltip: "Neighbors at +x, -x and +z"), "cross": FieldHints(tooltip: "Neighbors on all four sides"),
         "joinsWith": FieldHints(tooltip: "Other pieces that count as neighbors, comma-separated")]
    }
}

struct GridPieceComponent: Component {
    static var componentName: String { "GridMapPiece" }
    static var fieldHints: [String: FieldHints] { GridPieceForm.fieldHints }
    var form: GridPieceForm
    init(_ form: GridPieceForm) { self.form = form }
    init(from decoder: any Decoder) throws { form = try GridPieceForm(from: decoder) }
    func encode(to encoder: any Encoder) throws { try form.encode(to: encoder) }
}

/// Edits one `.gridmap` file. Rebuilt by the workspace whenever the file is reimported.
@MainActor
public final class GridMapView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var map: GridMap
    public let brush: GridMapBrushSettings
    public let showsTitle: Bool
    /// Called when the floor changes (the workspace fades the floors below).
    public var onFloorChange: (() -> Void)?

    let pieceList = ListView(items: [], name: "gridMapPieces")
    private let formWorld = World()
    private var formEntities: [Entity] = []
    private var grids: [PropertyGrid] = []

    public init?(session: EditorSession, asset: AssetID, brush: GridMapBrushSettings, showsTitle: Bool = true) {
        guard session.isGridMapFile(asset), let map = session.assets?.gridMap(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.map = map
        self.brush = brush
        self.showsTitle = showsTitle
        view = VStack(spacing: 6, name: "gridMapBuilder")
        pieceList.style.height = 140
        pieceList.onSelect = { [unowned self] row in
            guard let row, self.map.pieces.indices.contains(row), self.map.pieces[row].name != brush.piece else { return }
            brush.piece = self.map.pieces[row].name
            layout()
        }
        clampSelection()
        layout()
    }

    /// An edit made by a widget callback, applied on the next `refresh` so no widget is torn
    /// down while it is handling an event.
    private var pending: (map: GridMap, label: String)?

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.map, label: pending.label)
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let m = session.assets?.gridMap(of: asset) else { return }
        map = m
        clampSelection()
        layout()
    }

    private func clampSelection() {
        if map.piece(named: brush.piece) == nil { brush.piece = map.pieces.first { !$0.asset.isEmpty || $0.join != nil }?.name ?? "" }
        brush.randomSet = brush.randomSet.filter { map.piece(named: $0) != nil }
        if !brush.layer.isEmpty && !map.layerNames.contains(brush.layer) { brush.layer = "" }
    }

    /// Sets the floor being edited.
    public func setFloor(_ floor: Int) {
        guard floor != brush.floor else { return }
        brush.floor = min(max(floor, -64), 256)
        layout()
        onFloorChange?()
    }

    // MARK: Keys

    /// The tab's keys, while the pointer is over it (see `GridMapWorkspace.handleKeys`):
    ///
    /// | Keys | Does |
    /// |---|---|
    /// | 1 to 6 | Paint, Line, Rectangle, Fill, Erase, Random brush |
    /// | R / Shift+R | Rotate a quarter turn clockwise / back |
    /// | X / Z | Flip X / Flip Z |
    /// | Page Up / Page Down, or ] / [ | Floor up / down |
    ///
    /// Returns whether the key did something. Repeats only rotate and change floors.
    @discardableResult
    public func handleKey(_ event: KeyEvent) -> Bool {
        let mods = event.modifiers.subtracting(.shift)
        guard mods.isEmpty else { return false }
        let shift = event.modifiers.contains(.shift)
        let numbers: [Key] = [.num1, .num2, .num3, .num4, .num5, .num6]
        if let i = numbers.firstIndex(of: event.key), !shift, !event.isRepeat, GridMapBrushTool.allCases.indices.contains(i) {
            brush.tool = GridMapBrushTool.allCases[i]
        } else {
            switch event.key {
            case .r: brush.rotation = (brush.rotation + (shift ? 270 : 90)) % 360
            case .x where !shift && !event.isRepeat: brush.flipX.toggle()
            case .z where !shift && !event.isRepeat: brush.flipZ.toggle()
            case .pageUp, .rightBracket:
                setFloor(brush.floor + 1)
                return true
            case .pageDown, .leftBracket:
                setFloor(brush.floor - 1)
                return true
            default: return false
            }
        }
        layout()
        return true
    }

    // MARK: Layout

    func layout() {
        view.removeAllChildren()
        grids = []
        for entity in formEntities { formWorld.despawn(entity) }
        formEntities = []

        let title = Label("GridMap Builder", role: .heading)
        title.icon = EditorIcons.asset(.model)
        let place = Button("Place in Scene", role: .primary, name: "gridMapPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this map in the scene (copies update when you change it here)"
        view.addChild(showsTitle ? HStack(spacing: 6, [title, Spacer(), place]) : HStack(spacing: 6, [place, Spacer()]))

        addBrushSection()
        view.addChild(Separator())
        addFloorSection()
        view.addChild(Separator())
        addPieceSection()
        view.addChild(Separator())
        addSettingsSection()
    }

    private func toggle(_ title: String, on: Bool, name: String, tooltip: String, action: @escaping () -> Void) -> Button {
        let button = Button(title, role: on ? .primary : .normal, name: name, action: action)
        button.tooltip = tooltip
        return button
    }

    private func addBrushSection() {
        view.addChild(Label("Brush", role: .secondary))
        let tools = HStack(spacing: 4, name: "gridMapBrushes")
        tools.wraps = true
        for tool in GridMapBrushTool.allCases {
            let tip: String = switch tool {
            case .paint: "Click or drag to paint the piece"
            case .line: "Drag from one cell to another for a line"
            case .rect: "Drag a rectangle (Shift: just its edge)"
            case .fill: "Click to flood-fill the area (an empty area must be enclosed)"
            case .erase: "Click or drag to clear cells (on the chosen layer, or every layer on Auto)"
            case .random: "Paint a random piece of the random set, each turned at random"
            }
            tools.addChild(toggle(tool.title, on: tool == brush.tool, name: "gridMapBrush.\(tool.rawValue)", tooltip: "\(tip) (\(tool.shortcut))") { [unowned self] in
                brush.tool = tool
                layout()
            })
        }
        view.addChild(tools)

        let rotate = Button("Rotate \(brush.rotation)°", name: "gridMapRotate") { [unowned self] in
            brush.rotation = (brush.rotation + 90) % 360
            layout()
        }
        rotate.tooltip = "Turn the piece a quarter turn (R; Shift+R turns back)"
        let flipX = toggle("Flip X", on: brush.flipX, name: "gridMapFlipX", tooltip: "Mirror the piece left to right (X)") { [unowned self] in
            brush.flipX.toggle()
            layout()
        }
        let flipZ = toggle("Flip Z", on: brush.flipZ, name: "gridMapFlipZ", tooltip: "Mirror the piece front to back (Z)") { [unowned self] in
            brush.flipZ.toggle()
            layout()
        }
        view.addChild(HStack(spacing: 4, [rotate, flipX, flipZ, Spacer()]))

        let layers = HStack(spacing: 4, name: "gridMapLayers")
        layers.wraps = true
        let layerCaption = Label("Layer", role: .caption)
        layerCaption.style.width = 40
        layers.addChild(layerCaption)
        for layer in [""] + map.layerNames {
            layers.addChild(toggle(layer.isEmpty ? "Auto" : layer, on: brush.layer == layer, name: "gridMapLayer.\(layer.isEmpty ? "auto" : layer)",
                                   tooltip: layer.isEmpty ? "Each piece goes on its own layer" : "Paint and erase on \(layer)") { [unowned self] in
                brush.layer = layer
                layout()
            })
        }
        view.addChild(layers)
        let note = Label(brushNote(), role: .caption, name: "gridMapBrushNote")
        note.wraps = true
        view.addChild(note)
    }

    private func brushNote() -> String {
        if map.pieces.isEmpty { return "Add a piece to the library to paint with." }
        switch brush.tool {
        case .erase: return "Click or drag to erase. Right-drag orbits, Shift pans, the wheel zooms."
        case .random:
            let set = brush.randomSet.isEmpty ? [brush.piece] : brush.randomSet
            return "Random from: \(set.joined(separator: ", ")). Add pieces to the set below."
        default: return "Painting \(brush.piece.isEmpty ? "(no piece)" : brush.piece) on floor \(brush.floor). Right-drag orbits, Shift pans, the wheel zooms."
        }
    }

    private func addFloorSection() {
        view.addChild(Label("Floor", role: .secondary))
        let floors = map.floors
        let lo = min((floors.first ?? 0) - 2, brush.floor, 0), hi = max((floors.last ?? 0) + 3, brush.floor, 4)
        let caption = Label("Height", role: .caption)
        caption.style.width = 48
        let slider = Slider(value: Float(brush.floor), in: Float(lo)...Float(hi), step: 1, name: "gridMapFloor")
        slider.style.grow = 1
        slider.tooltip = "The floor you paint on; floors below are faded, floors above hidden (Page Up / Page Down, or ] / [)"
        let readout = Label("\(brush.floor)", role: .caption, name: "gridMapFloorValue")
        readout.style.width = 28
        slider.onChange = { [unowned self] v in
            readout.text = "\(Int(v.rounded()))"
            let floor = Int(v.rounded())
            if floor != brush.floor {
                brush.floor = floor
                onFloorChange?()
            }
        }
        let down = Button("Down", name: "gridMapFloorDown") { [unowned self] in setFloor(brush.floor - 1) }
        let up = Button("Up", name: "gridMapFloorUp") { [unowned self] in setFloor(brush.floor + 1) }
        view.addChild(HStack(spacing: 6, [caption, slider, readout]))
        view.addChild(HStack(spacing: 4, [down, up, Spacer()]))
        let count = map.cells.filter { $0.at.y == brush.floor }.count
        view.addChild(note("\(map.cells.count) cells on \(floors.count) floor\(floors.count == 1 ? "" : "s"); \(count) on this one."))
    }

    private func addPieceSection() {
        view.addChild(Label("Pieces", role: .secondary))
        pieceList.items = map.pieces.map { p in
            let kind = p.join != nil ? "auto-join" : (p.asset.isEmpty ? "no asset" : (p.asset as NSString).lastPathComponent)
            return "\(p.name)  ·  \(kind)" + (brush.randomSet.contains(p.name) ? "  ·  random" : "")
        }
        let selected = map.pieceIndex(named: brush.piece)
        if let selected { pieceList.selectRow(selected, reveal: true) }
        view.addChild(pieceList)
        let add = Button("Add Piece", name: "gridMapAddPiece") { [unowned self] in addPiece() }
        let remove = Button("Remove", name: "gridMapRemovePiece") { [unowned self] in removePiece() }
        add.command = GridMapEditCommand.id.rawValue
        remove.command = GridMapEditCommand.id.rawValue
        remove.isEnabled = selected != nil
        add.tooltip = "A new piece (pick its mesh build, model or prefab)"
        remove.tooltip = "Remove the selected piece and its cells"
        let inSet = brush.randomSet.contains(brush.piece)
        let random = Button(inSet ? "Leave Random Set" : "Add to Random Set", name: "gridMapRandomSet") { [unowned self] in
            if let i = brush.randomSet.firstIndex(of: brush.piece) { brush.randomSet.remove(at: i) } else if !brush.piece.isEmpty {
                brush.randomSet.append(brush.piece)
            }
            layout()
        }
        random.isEnabled = selected != nil
        random.tooltip = "The Random brush picks from this set"
        view.addChild(HStack(spacing: 6, [add, remove, Spacer()]))
        view.addChild(HStack(spacing: 6, [random, Spacer()]))
        guard let index = selected else {
            view.addChild(note("Pick or add a piece."))
            return
        }
        let entity = formWorld.spawn(GridPieceComponent(GridPieceForm(map.pieces[index])))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "gridMapPieceGrid", command: GridMapEditCommand.id.rawValue)
        grid.stringChoices = { [unowned self] _, path in
            switch path {
            case "asset": return [""] + piecePaths() + current(map.pieces[index].asset, in: piecePaths())
            case "layer": return [""] + map.layerNames
            case "collider": return GridPieceCollider.allCases.map(\.rawValue)
            case "single", "end", "straight", "corner", "tee", "cross":
                return [""] + map.pieces.filter { $0.join == nil }.map(\.name)
            default: return nil
            }
        }
        grid.stringChoiceTitle = { _, path, value in value.isEmpty ? (path == "layer" ? "Map's first layer" : "None") : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: GridPieceComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("GridMap piece \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let form = formWorld.get(GridPieceComponent.self, for: entity)?.form { commitPiece(form.piece, at: index) }
        }
        view.addChild(grid)
    }

    private func addSettingsSection() {
        view.addChild(Label("Map", role: .secondary))
        let entity = formWorld.spawn(GridMapSettingsComponent(GridMapSettingsForm(map)))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "gridMapSettingsGrid", command: GridMapEditCommand.id.rawValue)
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: GridMapSettingsComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("GridMap \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let s = formWorld.get(GridMapSettingsComponent.self, for: entity)?.settings { commitSettings(s) }
        }
        view.addChild(grid)
        let problems = GridMapCheck.problems(map, in: session) + (session.assets?.record(asset)?.importError.map { ["import failed: \($0)"] } ?? [])
        for problem in problems.prefix(6) { view.addChild(note("Problem: " + problem)) }
    }

    private func makeGrid(_ entity: Entity, name: String, command: String) -> PropertyGrid {
        let grid = PropertyGrid(world: formWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 96
        grid.entity = entity
        grid.command = command
        grids.append(grid)
        return grid
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "gridMapNote")
        label.wraps = true
        return label
    }

    // MARK: Choices

    private func piecePaths() -> [String] {
        let extensions = ["meshbuild", "gltf", "glb", "obj", "prefab"]
        return (session.assets?.allRecords ?? []).map(\.path).filter { path in extensions.contains { path.lowercased().hasSuffix("." + $0) } }
    }

    private func current(_ value: String, in choices: [String]) -> [String] {
        value.isEmpty || choices.contains(value) ? [] : [value]
    }

    // MARK: Edits

    /// Applies a finished brush stroke: the cells it touched (for line and rectangle, the press and
    /// release cells), on the current floor, as one edit.
    public func applyStroke(_ cells: [GridCoord], outline: Bool = false) {
        guard let first = cells.first else { return }
        var edited = pending?.map ?? map
        let layer = brush.layer.isEmpty ? nil : brush.layer
        switch brush.tool {
        case .erase:
            guard edited.erase(at: cells, layer: layer) > 0 else { return }
            apply(edited, label: "Erase GridMap")
            return
        case .random:
            let set = brush.randomSet.isEmpty ? [brush.piece] : brush.randomSet
            guard set.allSatisfy({ edited.piece(named: $0) != nil }) else { return warnNoPiece() }
            brush.seed &+= 1
            edited.paintRandom(set, at: cells, seed: brush.seed, randomRotation: true, layer: layer)
        default:
            guard edited.piece(named: brush.piece) != nil else { return warnNoPiece() }
            let area: [GridCoord]
            switch brush.tool {
            case .line: area = GridMap.line(from: first, to: cells.last ?? first)
            case .rect: area = GridMap.rectangle(from: first, to: cells.last ?? first, outline: outline)
            case .fill:
                do { area = try edited.floodRegion(from: first, layer: layer ?? edited.defaultLayer(of: edited.piece(named: brush.piece))) } catch {
                    session.log.warning("GridMap Builder: \(error)")
                    return
                }
            default: area = cells
            }
            guard edited.cells.count + area.count <= GridMap.maxCells else {
                session.log.warning("GridMap Builder: a map holds at most \(GridMap.maxCells) cells")
                return
            }
            // A multi-cell piece is laid side by side along a stroke or across an area, not once per cell.
            let steps = edited.footprintSteps(area, piece: brush.piece, rotation: brush.rotation,
                                              inside: brush.tool == .fill || (brush.tool == .rect && !outline))
            edited.paint(brush.piece, at: steps, rotation: brush.rotation, flipX: brush.flipX, flipZ: brush.flipZ, layer: layer)
        }
        apply(edited, label: brush.tool.title + " GridMap")
    }

    private func warnNoPiece() {
        session.log.warning("GridMap Builder: pick a piece from the library first")
    }

    private func apply(_ edited: GridMap, label: String) {
        pending = (edited, label)
    }

    private func commit(_ edited: GridMap, label: String) {
        guard session.applyGridMap(edited, to: asset, label: label) != nil else { return }
        map = session.assets?.gridMap(of: asset) ?? edited
        clampSelection()
        layout()
    }

    private func commitSettings(_ s: GridMapSettingsForm) {
        let layers = s.layers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let arguments = GridMapEditCommand.Arguments(cellSize: s.cellSize, chunkSize: s.chunkSize, collider: s.collider,
                                                     layers: layers == map.layerNames ? nil : layers)
        do { apply(try GridMapEditCommand.edited(pending?.map ?? map, with: arguments), label: "Edit GridMap") } catch {
            session.log.error("GridMap: \(error)")
            layout()
        }
    }

    private func commitPiece(_ piece: GridPiece, at index: Int) {
        var edited = pending?.map ?? map
        guard edited.pieces.indices.contains(index) else { return }
        let old = edited.pieces[index].name
        var piece = piece
        if piece.name.isEmpty || edited.pieces.enumerated().contains(where: { $0.offset != index && $0.element.name == piece.name }) {
            piece.name = old
        }
        if piece.name != old {
            edited.renamePiece(old, to: piece.name)
            if brush.piece == old { brush.piece = piece.name }
            brush.randomSet = brush.randomSet.map { $0 == old ? piece.name : $0 }
        }
        edited.pieces[index] = piece
        apply(edited, label: "Edit Piece")
    }

    func addPiece() {
        var edited = map
        let name = GridMapEditCommand.uniqueName("Piece", among: edited.pieces.map(\.name))
        edited.pieces.append(GridPiece(name: name, asset: piecePaths().first { $0.hasSuffix(".meshbuild") } ?? piecePaths().first ?? ""))
        brush.piece = name
        apply(edited, label: "Add Piece")
    }

    func removePiece() {
        guard map.piece(named: brush.piece) != nil,
              let edited = try? GridMapEditCommand.edited(map, with: .init(removePieces: [brush.piece])) else { return }
        brush.piece = ""
        apply(edited, label: "Remove Piece")
    }
}
