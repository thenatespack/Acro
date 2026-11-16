import Engine
import Foundation

// The Path Builder form: the sidebar for a `.path` file. Pick a kind (road, rail, river, fence,
// cable, wall) to start from its profiles and pieces, edit the curve settings and terrain
// following, the control points (the workspace's viewport has a handle per point to drag with
// the Move gizmo), and the cross-section profiles and repeated pieces in property grids. Every
// change is written to the file at once as one undo step (`EditorSession.applyPathBuild`), so the
// path reimports and placed copies update; Ctrl+Z takes changes back.

/// The curve settings as the grid's rows.
struct PathSettings: Codable, Equatable {
    var closed = false
    var smooth = true
    var spacing: Float = 0.5
    var bank: Float = 0
    var autoBank: Float = 0

    init(_ b: PathBuild) {
        closed = b.closed
        smooth = b.smooth
        spacing = b.spacing
        bank = b.bank
        autoBank = b.autoBank
    }

    private enum CodingKeys: String, CodingKey { case closed, smooth, spacing, bank, autoBank }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathSettings(PathBuild())
        closed = try c.decodeIfPresent(Bool.self, forKey: .closed) ?? d.closed
        smooth = try c.decodeIfPresent(Bool.self, forKey: .smooth) ?? d.smooth
        spacing = try c.decodeIfPresent(Float.self, forKey: .spacing) ?? d.spacing
        bank = try c.decodeIfPresent(Float.self, forKey: .bank) ?? d.bank
        autoBank = try c.decodeIfPresent(Float.self, forKey: .autoBank) ?? d.autoBank
    }
}

struct PathSettingsComponent: Component {
    static var componentName: String { "Path Curve" }
    static var fieldHints: [String: FieldHints] { PathBuild.fieldHints }
    var settings: PathSettings
    init(_ settings: PathSettings) { self.settings = settings }
    init(from decoder: any Decoder) throws { settings = try PathSettings(from: decoder) }
    func encode(to encoder: any Encoder) throws { try settings.encode(to: encoder) }
}

struct PathTerrainComponent: Component {
    static var componentName: String { "Path Terrain" }
    static var fieldHints: [String: FieldHints] { PathTerrain.fieldHints }
    var terrain: PathTerrain
    init(_ terrain: PathTerrain) { self.terrain = terrain }
    init(from decoder: any Decoder) throws { terrain = try PathTerrain(from: decoder) }
    func encode(to encoder: any Encoder) throws { try terrain.encode(to: encoder) }
}

struct PathJunctionComponent: Component {
    static var componentName: String { "Path Junction" }
    static var fieldHints: [String: FieldHints] { PathJunction.fieldHints }
    var junction: PathJunction
    init(_ junction: PathJunction) { self.junction = junction }
    init(from decoder: any Decoder) throws { junction = try PathJunction(from: decoder) }
    func encode(to encoder: any Encoder) throws { try junction.encode(to: encoder) }
}

/// The Shape Terrain form (width 0: the widest profile).
struct PathShapingComponent: Component {
    static var componentName: String { "Path Terrain Shaping" }
    static var fieldHints: [String: FieldHints] {
        ["mode": FieldHints(tooltip: "flatten: cut and fill; carve: only lower (cuttings, river beds); raise: only raise (embankments)"),
         "width": FieldHints(range: 0...1000, step: 0.1, tooltip: "Meters across the flat part (0: the widest profile)"),
         "shoulder": FieldHints(range: 0...1000, step: 0.1, tooltip: "Meters over which it blends back into the terrain at each side"),
         "depth": FieldHints(range: -100...100, step: 0.05, tooltip: "Meters below the path's ground level (a river bed, a sunken lane)"),
         "smoothing": FieldHints(range: 0...1000, step: 0.5, tooltip: "Meters along the path the ground level is averaged over")]
    }
    var mode: PathTerrainShapeMode
    var width: Float
    var shoulder: Float
    var depth: Float
    var smoothing: Float

    init(_ s: PathTerrainShaping) {
        mode = s.mode
        width = s.width ?? 0
        shoulder = s.shoulder
        depth = s.depth
        smoothing = s.smoothing
    }

    var shaping: PathTerrainShaping {
        PathTerrainShaping(mode: mode, width: width > 0 ? width : nil, shoulder: shoulder, depth: depth, smoothing: smoothing)
    }
}

struct PathPointComponent: Component {
    static var componentName: String { "Path Point" }
    static var fieldHints: [String: FieldHints] { PathPoint.fieldHints }
    var point: PathPoint
    init(_ point: PathPoint) { self.point = point }
    init(from decoder: any Decoder) throws { point = try PathPoint(from: decoder) }
    func encode(to encoder: any Encoder) throws { try point.encode(to: encoder) }
}

struct PathProfileComponent: Component {
    static var componentName: String { "Path Profile" }
    static var fieldHints: [String: FieldHints] { PathProfile.fieldHints }
    var profile: PathProfile
    init(_ profile: PathProfile) { self.profile = profile }
    init(from decoder: any Decoder) throws { profile = try PathProfile(from: decoder) }
    func encode(to encoder: any Encoder) throws { try profile.encode(to: encoder) }
}

struct PathPieceComponent: Component {
    static var componentName: String { "Path Piece" }
    static var fieldHints: [String: FieldHints] { PathPiece.fieldHints }
    var piece: PathPiece
    init(_ piece: PathPiece) { self.piece = piece }
    init(from decoder: any Decoder) throws { piece = try PathPiece(from: decoder) }
    func encode(to encoder: any Encoder) throws { try piece.encode(to: encoder) }
}

/// Edits one `.path` file. Rebuilt by the workspace whenever the file is reimported.
@MainActor
public final class PathBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var build: PathBuild
    /// The control point being edited (the workspace selects its handle).
    public private(set) var selectedPoint: Int?
    public private(set) var selectedProfile: Int?
    public private(set) var selectedPiece: Int?
    public let showsTitle: Bool

    let pointList = ListView(items: [], name: "pathPoints")
    let profileList = ListView(items: [], name: "pathProfiles")
    let pieceList = ListView(items: [], name: "pathPieces")
    private let formWorld = World()
    private var formEntities: [Entity] = []
    private var grids: [PropertyGrid] = []
    private static var selections: [AssetID: (point: Int?, profile: Int?, piece: Int?)] = [:]

    public init?(session: EditorSession, asset: AssetID, showsTitle: Bool = true) {
        guard session.isPathBuildFile(asset), let build = session.assets?.pathBuild(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.build = build
        self.showsTitle = showsTitle
        view = VStack(spacing: 6, name: "pathBuilder")
        let remembered = Self.selections[asset]
        selectedPoint = remembered?.point.flatMap { build.points.indices.contains($0) ? $0 : nil }
        selectedProfile = remembered?.profile.flatMap { build.profiles.indices.contains($0) ? $0 : nil } ?? (build.profiles.isEmpty ? nil : 0)
        selectedPiece = remembered?.piece.flatMap { build.pieces.indices.contains($0) ? $0 : nil } ?? (build.pieces.isEmpty ? nil : 0)
        for list in [pointList, profileList, pieceList] { list.style.height = 96 }
        pointList.onSelect = { [unowned self] row in
            guard let row, row != selectedPoint, self.build.points.indices.contains(row) else { return }
            selectPoint(row)
        }
        profileList.onSelect = { [unowned self] row in
            guard let row, row != selectedProfile, self.build.profiles.indices.contains(row) else { return }
            selectedProfile = row
            remember()
            layout()
        }
        pieceList.onSelect = { [unowned self] row in
            guard let row, row != selectedPiece, self.build.pieces.indices.contains(row) else { return }
            selectedPiece = row
            remember()
            layout()
        }
        layout()
    }

    /// An edit made by a widget callback, applied on the next `refresh` so no widget is torn
    /// down while it is handling an event.
    private var pending: (build: PathBuild, label: String)?
    /// The Shape Terrain form's settings, and what the last shaping did.
    public var shaping = PathTerrainShaping()
    private(set) var lastShape: String?

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.build, label: pending.label)
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let b = session.assets?.pathBuild(of: asset) else { return }
        build = b
        clampSelection()
        layout()
    }

    private func clampSelection() {
        if let p = selectedPoint, !build.points.indices.contains(p) { selectedPoint = build.points.isEmpty ? nil : build.points.count - 1 }
        if let p = selectedProfile, !build.profiles.indices.contains(p) { selectedProfile = build.profiles.isEmpty ? nil : 0 }
        if selectedProfile == nil, !build.profiles.isEmpty { selectedProfile = 0 }
        if let p = selectedPiece, !build.pieces.indices.contains(p) { selectedPiece = build.pieces.isEmpty ? nil : 0 }
        if selectedPiece == nil, !build.pieces.isEmpty { selectedPiece = 0 }
    }

    private func remember() { Self.selections[asset] = (selectedPoint, selectedProfile, selectedPiece) }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        grids = []
        for entity in formEntities { formWorld.despawn(entity) }
        formEntities = []

        let title = Label("Path Builder", role: .heading)
        title.icon = EditorIcons.asset(.model)
        let place = Button("Place in Scene", role: .primary, name: "pathPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this path in the scene (copies update when you change it here)"
        view.addChild(showsTitle ? HStack(spacing: 6, [title, Spacer(), place]) : HStack(spacing: 6, [place, Spacer()]))

        addKindSection()
        view.addChild(Separator())
        addCurveSection()
        view.addChild(Separator())
        addPointSection()
        view.addChild(Separator())
        addProfileSection()
        view.addChild(Separator())
        addPieceSection()
        view.addChild(Separator())
        addJunctionSection()
        view.addChild(Separator())
        addTerrainSection()
        addSummary()
    }

    private func addKindSection() {
        view.addChild(Label("Kind", role: .secondary))
        let kinds = HStack(spacing: 4, name: "pathKinds")
        kinds.wraps = true
        for kind in PathKind.allCases {
            let button = Button(kind.rawValue.capitalized, role: kind == build.kind ? .primary : .normal, name: "pathKind.\(kind.rawValue)") {
                [unowned self] in applyKind(kind)
            }
            button.command = PathEditCommand.id.rawValue
            button.tooltip = kind == .custom ? "One plain strip to shape yourself" : "Use the \(kind.rawValue) profiles and pieces (the points stay)"
            kinds.addChild(button)
        }
        view.addChild(kinds)
    }

    private func addCurveSection() {
        view.addChild(Label("Curve", role: .secondary))
        let entity = formWorld.spawn(PathSettingsComponent(PathSettings(build)))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "pathCurveGrid")
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathSettingsComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Path \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let s = formWorld.get(PathSettingsComponent.self, for: entity)?.settings else { return }
            var edited = pending?.build ?? build
            edited.closed = s.closed
            edited.smooth = s.smooth
            edited.spacing = min(max(s.spacing, 0.05), 50)
            edited.bank = s.bank
            edited.autoBank = s.autoBank
            apply(edited, label: "Edit Path")
        }
        view.addChild(grid)
    }

    private func addPointSection() {
        view.addChild(Label("Points", role: .secondary))
        pointList.items = build.points.enumerated().map { i, p in
            var text = "\(i)  ·  " + [p.position.x, p.position.y, p.position.z].map { String(format: "%.1f", $0) }.joined(separator: ", ")
            if p.bank != 0 { text += String(format: "  ·  bank %g°", p.bank) }
            if p.width != 1 { text += String(format: "  ·  width ×%g", p.width) }
            return text
        }
        if let selectedPoint { pointList.selectRow(selectedPoint, reveal: true) }
        view.addChild(pointList)
        let add = Button("Add", name: "pathAddPoint") { [unowned self] in addPoint() }
        let insert = Button("Insert", name: "pathInsertPoint") { [unowned self] in insertPoint() }
        let remove = Button("Delete", name: "pathDeletePoint") { [unowned self] in deletePoint() }
        for button in [add, insert, remove] { button.command = PathEditCommand.id.rawValue }
        add.tooltip = "A new point past the end, continuing the curve"
        insert.tooltip = "A new point halfway between the selected point and the next"
        remove.tooltip = "Remove the selected point (a path keeps at least 2)"
        insert.isEnabled = selectedPoint != nil && build.points.count >= 2
        remove.isEnabled = selectedPoint != nil && build.points.count > 2
        view.addChild(HStack(spacing: 6, [add, insert, remove, Spacer()]))
        guard let index = selectedPoint, build.points.indices.contains(index) else {
            view.addChild(note("Click a handle in the view (or a row above) to edit a point; drag it with the Move gizmo."))
            return
        }
        let entity = formWorld.spawn(PathPointComponent(build.points[index]))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "pathPointGrid")
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathPointComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Path point \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let point = formWorld.get(PathPointComponent.self, for: entity)?.point else { return }
            var edited = pending?.build ?? build
            guard edited.points.indices.contains(index) else { return }
            edited.points[index] = point
            apply(edited, label: "Edit Point")
        }
        view.addChild(grid)
    }

    private func addProfileSection() {
        view.addChild(Label("Profiles", role: .secondary))
        profileList.items = build.profiles.map { "\($0.name)  ·  \($0.shape.rawValue) \(String(format: "%g", $0.width)) m" }
        if let selectedProfile { profileList.selectRow(selectedProfile, reveal: true) }
        view.addChild(profileList)
        let add = Button("Add Profile", name: "pathAddProfile") { [unowned self] in addProfile() }
        let remove = Button("Remove", name: "pathRemoveProfile") { [unowned self] in removeProfile() }
        add.command = PathEditCommand.id.rawValue
        remove.command = PathEditCommand.id.rawValue
        remove.isEnabled = selectedProfile != nil
        add.tooltip = "A cross-section swept along the path into a mesh (a strip, a block, a tube or your own outline)"
        view.addChild(HStack(spacing: 6, [add, remove, Spacer()]))
        guard let index = selectedProfile, build.profiles.indices.contains(index) else {
            view.addChild(note("Add a profile to give the path a surface."))
            return
        }
        let entity = formWorld.spawn(PathProfileComponent(build.profiles[index]))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "pathProfileGrid")
        grid.stringChoices = { [unowned self] _, path in
            switch path {
            case "texture": return [""] + texturePaths() + current(build.profiles[index].texture, in: texturePaths())
            case "material": return [""] + assetPaths(extensions: ["material"]) + current(build.profiles[index].material, in: assetPaths(extensions: ["material"]))
            default: return nil
            }
        }
        grid.stringChoiceTitle = { _, _, value in value.isEmpty ? "None" : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathProfileComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Path profile \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let profile = formWorld.get(PathProfileComponent.self, for: entity)?.profile else { return }
            commitNamed(profile, at: index, in: \.profiles, label: "Edit Profile")
        }
        view.addChild(grid)
    }

    private func addPieceSection() {
        view.addChild(Label("Pieces", role: .secondary))
        pieceList.items = build.pieces.map { "\($0.name)  ·  \($0.asset.isEmpty ? $0.shape.rawValue : $0.asset)  ·  every \(String(format: "%g", $0.spacing)) m" }
        if let selectedPiece { pieceList.selectRow(selectedPiece, reveal: true) }
        view.addChild(pieceList)
        let add = Button("Add Piece", name: "pathAddPiece") { [unowned self] in addPiece() }
        let remove = Button("Remove", name: "pathRemovePiece") { [unowned self] in removePiece() }
        add.command = PathEditCommand.id.rawValue
        remove.command = PathEditCommand.id.rawValue
        remove.isEnabled = selectedPiece != nil
        add.tooltip = "Something repeated along the path: posts, sleepers, lamps (a shape, a .meshbuild or a mesh)"
        view.addChild(HStack(spacing: 6, [add, remove, Spacer()]))
        guard let index = selectedPiece, build.pieces.indices.contains(index) else {
            view.addChild(note("Pieces repeat along the path every few meters."))
            return
        }
        let entity = formWorld.spawn(PathPieceComponent(build.pieces[index]))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "pathPieceGrid")
        grid.stringChoices = { [unowned self] _, path in
            switch path {
            case "asset": return [""] + assetPaths(extensions: ["meshbuild"]) + current(build.pieces[index].asset, in: assetPaths(extensions: ["meshbuild"]))
            case "shape": return MeshBuildShape.allCases.filter { $0 != .group }.map(\.rawValue)
            case "material": return [""] + assetPaths(extensions: ["material"]) + current(build.pieces[index].material, in: assetPaths(extensions: ["material"]))
            default: return nil
            }
        }
        grid.stringChoiceTitle = { _, path, value in value.isEmpty ? (path == "asset" ? "None (the shape below)" : "None") : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathPieceComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Path piece \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let piece = formWorld.get(PathPieceComponent.self, for: entity)?.piece else { return }
            commitNamed(piece, at: index, in: \.pieces, label: "Edit Piece")
        }
        view.addChild(grid)
    }

    private func addJunctionSection() {
        view.addChild(Label("Junctions", role: .secondary))
        let others = otherPathPaths()
        for (index, junction) in build.junctions.enumerated() {
            let entity = formWorld.spawn(PathJunctionComponent(junction))
            formEntities.append(entity)
            let grid = makeGrid(entity, name: "pathJunctionGrid.\(index)")
            grid.stringChoices = { [unowned self] _, path in
                path == "path" ? others + current(build.junctions.indices.contains(index) ? build.junctions[index].path : "", in: others) : nil
            }
            grid.onFieldEdit = { [unowned self] edit in
                do { try formWorld.setField(edit.path, of: PathJunctionComponent.componentName, for: entity, to: edit.newValue) } catch {
                    session.log.error("Path junction \(edit.path): \(error)")
                    return
                }
                guard edit.phase == .ended, let value = formWorld.get(PathJunctionComponent.self, for: entity)?.junction else { return }
                var edited = pending?.build ?? build
                guard edited.junctions.indices.contains(index) else { return }
                edited.junctions[index] = value
                apply(edited, label: "Edit Junction")
            }
            view.addChild(grid)
            let remove = Button("Remove Junction", name: "pathRemoveJunction.\(index)") { [unowned self] in removeJunction(index) }
            remove.command = PathEditCommand.id.rawValue
            view.addChild(HStack(spacing: 6, [remove, Spacer()]))
        }
        let add = Button("Add Junction", name: "pathAddJunction") { [unowned self] in addJunction() }
        add.command = PathEditCommand.id.rawValue
        add.isEnabled = !others.isEmpty
        add.tooltip = others.isEmpty ? "Make another .path for this one to meet" : "Join another path: a T where this one ends at it, an X where it crosses it"
        view.addChild(HStack(spacing: 6, [add, Spacer()]))
        view.addChild(note(build.junctions.isEmpty
            ? "Where this road ends at or crosses another path it can join it: it stops at the other road's edges and rounded corners pave the gap."
            : "This path stops at the other roads' edges; its widest flat or box profile paves the corners. The other road stays whole."))
    }

    /// The project's other `.path` files.
    private func otherPathPaths() -> [String] {
        let mine = session.assets?.path(of: asset)
        return assetPaths(extensions: ["path"]).filter { $0 != mine }
    }

    /// Joins the first other path not joined yet (one undo step).
    public func addJunction(_ path: String? = nil) {
        let joined = Set(build.junctions.map(\.path))
        guard let other = path ?? otherPathPaths().first(where: { !joined.contains($0) }) ?? otherPathPaths().first else { return }
        var edited = pending?.build ?? build
        edited.junctions.append(PathJunction(path: other))
        apply(edited, label: "Add Junction")
    }

    public func removeJunction(_ index: Int) {
        var edited = pending?.build ?? build
        guard edited.junctions.indices.contains(index) else { return }
        edited.junctions.remove(at: index)
        apply(edited, label: "Remove Junction")
    }

    private func addTerrainSection() {
        view.addChild(Label("Terrain following", role: .secondary))
        let entity = formWorld.spawn(PathTerrainComponent(build.terrain))
        formEntities.append(entity)
        let grid = makeGrid(entity, name: "pathTerrainGrid")
        grid.stringChoices = { [unowned self] _, path in
            path == "asset" ? [""] + assetPaths(extensions: ["terrain"]) + current(build.terrain.asset, in: assetPaths(extensions: ["terrain"])) : nil
        }
        grid.stringChoiceTitle = { _, _, value in value.isEmpty ? "Off" : value }
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathTerrainComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Path terrain \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let terrain = formWorld.get(PathTerrainComponent.self, for: entity)?.terrain else { return }
            var edited = pending?.build ?? build
            edited.terrain = terrain
            apply(edited, label: terrain.isOn == build.terrain.isOn ? "Edit Terrain Following" : (terrain.isOn ? "Follow Terrain" : "Stop Following Terrain"))
        }
        view.addChild(grid)
        view.addChild(note(build.terrain.isOn
            ? "Every sample and piece sits on the terrain (point heights are ignored). Place the path where the terrain is, or set the offset."
            : "Pick a .terrain to make the path hug its ground."))
        guard build.terrain.isOn else { return }

        view.addChild(Separator())
        view.addChild(Label("Shape the terrain", role: .secondary))
        let shapingEntity = formWorld.spawn(PathShapingComponent(shaping))
        formEntities.append(shapingEntity)
        let shapingGrid = makeGrid(shapingEntity, name: "pathShapingGrid")
        shapingGrid.command = PathFlattenTerrainCommand.id.rawValue
        shapingGrid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PathShapingComponent.componentName, for: shapingEntity, to: edit.newValue) } catch {
                session.log.error("Path terrain shaping \(edit.path): \(error)")
                return
            }
            if let value = formWorld.get(PathShapingComponent.self, for: shapingEntity) { shaping = value.shaping }
        }
        view.addChild(shapingGrid)
        let shape = Button("Shape Terrain", name: "pathShapeTerrain") { [unowned self] in shapeTerrain() }
        shape.tooltip = "Writes the terrain's heights under the path (one undo step); the path then follows the new ground"
        view.addChild(HStack(spacing: 6, [shape, Spacer()]))
        if let lastShape { view.addChild(note(lastShape)) }
    }

    /// Shapes the followed terrain under the path with the form's settings (one undo step).
    public func shapeTerrain() {
        refresh()  // a pending form edit goes in first
        do {
            let (terrain, report) = try session.shapeTerrain(under: asset, shaping)
            let name = session.assets?.path(of: terrain) ?? terrain.description
            lastShape = report.changedSamples == 0
                ? "\(name) already fits the path."
                : String(format: "Moved %d height samples of %@ (up to %.2f m).", report.changedSamples, name, report.largestChange)
                    + (report.clampedSamples > 0 ? " \(report.clampedSamples) hit the terrain's height range." : "")
        } catch {
            lastShape = "\(error)"
            session.log.error("Shape Terrain: \(error)")
        }
        reload()
    }

    private func addSummary() {
        let ground = session.followedTerrain(of: build)
        let samples = build.samples(on: ground?.terrain)
        let pieces = build.pieces.map { build.instances(of: $0, samples: samples, on: ground?.terrain).count }.reduce(0, +)
        view.addChild(Separator())
        view.addChild(note(String(format: "%.1f m long, %d samples, %d pieces.", samples.last?.distance ?? 0, samples.count, pieces)))
        for problem in PathBuildCheck.problems(build, in: session) {
            let label = note("Problem: " + problem)
            view.addChild(label)
        }
    }

    private func makeGrid(_ entity: Entity, name: String) -> PropertyGrid {
        let grid = PropertyGrid(world: formWorld, name: name)
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        grid.command = PathEditCommand.id.rawValue
        grids.append(grid)
        return grid
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "pathNote")
        label.wraps = true
        return label
    }

    // MARK: Choices

    private func assetPaths(extensions: [String]) -> [String] {
        (session.assets?.allRecords ?? []).map(\.path).filter { path in extensions.contains { path.lowercased().hasSuffix("." + $0) } }
    }

    private func texturePaths() -> [String] { assetPaths(extensions: ["png", "jpg", "jpeg", "tga", "proctex"]) }

    /// A value typed into the file is kept as a choice so the dropdown can show it.
    private func current(_ value: String, in choices: [String]) -> [String] {
        value.isEmpty || choices.contains(value) ? [] : [value]
    }

    // MARK: Edits

    /// Selects a control point (nil: none) without changing the file.
    public func selectPoint(_ index: Int?) {
        guard index != selectedPoint else { return }
        selectedPoint = index.flatMap { build.points.indices.contains($0) ? $0 : nil }
        remember()
        layout()
    }

    /// Moves control points (index → new position) as one edit, applied on the next `refresh`.
    public func movePoints(_ moves: [Int: Vec3], label: String = "Move Point") {
        var edited = pending?.build ?? build
        for (i, p) in moves where edited.points.indices.contains(i) { edited.points[i].position = p }
        guard edited != build else { return }
        apply(edited, label: label)
    }

    private func apply(_ edited: PathBuild, label: String) {
        pending = (edited, label)
    }

    private func commit(_ edited: PathBuild, label: String) {
        guard session.applyPathBuild(edited, to: asset, label: label) != nil else { return }
        build = session.assets?.pathBuild(of: asset) ?? edited
        clampSelection()
        layout()
    }

    private func commitNamed<T: PathNamedItem>(_ item: T, at index: Int, in list: WritableKeyPath<PathBuild, [T]>, label: String) {
        var edited = pending?.build ?? build
        guard edited[keyPath: list].indices.contains(index) else { return }
        var item = item
        let old = edited[keyPath: list][index].name
        item.name = item.name.trimmingCharacters(in: .whitespaces)
        if item.name.isEmpty || edited[keyPath: list].enumerated().contains(where: { $0.offset != index && $0.element.name == item.name }) {
            item.name = old
        }
        edited[keyPath: list][index] = item
        apply(edited, label: label)
    }

    func applyKind(_ kind: PathKind) {
        guard let edited = try? PathEditCommand.edited(build, with: .init(kind: kind)) else { return }
        selectedProfile = edited.profiles.isEmpty ? nil : 0
        selectedPiece = edited.pieces.isEmpty ? nil : 0
        remember()
        apply(edited, label: "Make \(kind.rawValue.capitalized)")
    }

    /// A new point past the end, continuing in the direction of the last span.
    func addPoint() {
        var edited = build
        let p = edited.points
        var next = Vec3(10, 0, 0)
        if let last = p.last {
            let direction = p.count >= 2 ? last.position - p[p.count - 2].position : Vec3(10, 0, 0)
            let l = length(direction)
            next = last.position + (l > 1e-4 ? direction / l * min(max(l, 2), 20) : Vec3(10, 0, 0))
        }
        edited.points.append(PathPoint(next, bank: p.last?.bank ?? 0, width: p.last?.width ?? 1))
        selectedPoint = edited.points.count - 1
        remember()
        apply(edited, label: "Add Point")
    }

    /// A new point at `position` (a click on the ground): before the first point when the first is
    /// selected (an open path grows from that end), else after the last. One undo step.
    public func addPoint(at position: Vec3) {
        var edited = build
        let atStart = selectedPoint == 0 && edited.points.count > 1 && !edited.wraps
        let neighbor = atStart ? edited.points.first : edited.points.last
        let point = PathPoint(position, bank: neighbor?.bank ?? 0, width: neighbor?.width ?? 1)
        if atStart { edited.points.insert(point, at: 0) } else { edited.points.append(point) }
        selectedPoint = atStart ? 0 : edited.points.count - 1
        remember()
        apply(edited, label: "Add Point")
    }

    /// A new point on the curve at parameter `u` (a click on the curve). One undo step.
    public func insertPoint(atU u: Float) {
        var edited = build
        guard let index = edited.insertPoint(atU: u) else { return }
        selectedPoint = index
        remember()
        apply(edited, label: "Insert Point")
    }

    /// A new point on the curve halfway between the selected point and the next (or the previous, at the end).
    func insertPoint() {
        guard let i = selectedPoint, build.points.count >= 2, build.points.indices.contains(i) else { return }
        var edited = build
        let atEnd = i == build.points.count - 1 && !(build.closed && build.points.count > 2)
        let a = atEnd ? i - 1 : i
        let b = (a + 1) % build.points.count
        let position = build.curvePosition(at: Float(a) + 0.5)
        let pa = build.points[a], pb = build.points[b]
        edited.points.insert(PathPoint(position, bank: (pa.bank + pb.bank) / 2, width: (pa.width + pb.width) / 2), at: a + 1)
        selectedPoint = a + 1
        remember()
        apply(edited, label: "Insert Point")
    }

    func deletePoint() {
        guard let i = selectedPoint, build.points.count > 2, build.points.indices.contains(i) else { return }
        var edited = build
        edited.points.remove(at: i)
        selectedPoint = min(i, edited.points.count - 1)
        remember()
        apply(edited, label: "Delete Point")
    }

    func addProfile() {
        var edited = build
        let name = TerrainEditCommand.uniqueName("Profile", among: edited.profiles.map(\.name))
        edited.profiles.append(PathProfile(name: name))
        selectedProfile = edited.profiles.count - 1
        remember()
        apply(edited, label: "Add Profile")
    }

    func removeProfile() {
        guard let i = selectedProfile, build.profiles.indices.contains(i) else { return }
        var edited = build
        edited.profiles.remove(at: i)
        selectedProfile = edited.profiles.isEmpty ? nil : 0
        remember()
        apply(edited, label: "Remove Profile")
    }

    func addPiece() {
        var edited = build
        let name = TerrainEditCommand.uniqueName("Piece", among: edited.pieces.map(\.name))
        edited.pieces.append(PathPiece(name: name, offset: Vec3(0, 0.5, 0)))
        selectedPiece = edited.pieces.count - 1
        remember()
        apply(edited, label: "Add Piece")
    }

    func removePiece() {
        guard let i = selectedPiece, build.pieces.indices.contains(i) else { return }
        var edited = build
        edited.pieces.remove(at: i)
        selectedPiece = edited.pieces.isEmpty ? nil : 0
        remember()
        apply(edited, label: "Remove Piece")
    }
}
