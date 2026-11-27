import EditorCore
import Engine
import Foundation

// The Groom Builder form for a `.groom` file: presets, the brushes (Orbit, Mask, Restore, Length,
// Comb with radius, strength and length), the comb direction, sliders for every setting, the
// mask and the detail levels. Every change is written to the file as one undo step
// (`EditorSession.applyGroom`), so the groom reimports and the fur using it regrows.

/// The proxy component for the groom's settings: encodes and decodes as `GroomBuild`.
struct GroomSettingsComponent: Component {
    static var componentName: String { "Groom" }
    static var fieldHints: [String: FieldHints] { GroomBuild.fieldHints }

    var groom: GroomBuild

    init(groom: GroomBuild) { self.groom = groom }
    init(from decoder: any Decoder) throws { groom = try GroomBuild(from: decoder) }
    func encode(to encoder: any Encoder) throws { try groom.encode(to: encoder) }
}

/// The proxy component for the mask.
struct GroomMaskComponent: Component {
    static var componentName: String { "Mask" }
    static var fieldHints: [String: FieldHints] {
        ["texture": FieldHints(tooltip: "An image whose red channel scales the length (black: bald)"),
         "vertexPaint": FieldHints(tooltip: "A vertex paint channel (r, g, b or a) that scales the length (blank: off)"),
         "parts": FieldHints(tooltip: "Part or entity names the fur grows on (empty: every part)"),
         "invert": FieldHints(tooltip: "Swap grown and bald")]
    }

    var mask: GroomMask

    init(mask: GroomMask) { self.mask = mask }
    init(from decoder: any Decoder) throws { mask = try GroomMask(from: decoder) }
    func encode(to encoder: any Encoder) throws { try mask.encode(to: encoder) }
}

/// The proxy component for the hairstyle (card hair): part, length by region, hemline, fringe,
/// ponytail tie and colliders.
struct GroomStyleComponent: Component {
    static var componentName: String { "Hairstyle" }
    static var fieldHints: [String: FieldHints] {
        ["part": FieldHints(tooltip: "Where the hair parts: strands comb away from the line (center, side or a curve of points)"),
         "part.style": FieldHints(tooltip: "none, center, side (at offset) or curve (points in the mesh's space)"),
         "part.offset": FieldHints(range: -1...1, step: 0.05, tooltip: "Across the head (-1 left, 1 right of the hair's bounds); side with 0 sits at 0.4"),
         "part.crown": FieldHints(range: -1...1, step: 0.05, tooltip: "Where the part ends toward the back (-1 back, 1 front)"),
         "part.strength": FieldHints(range: 0...1, step: 0.05, tooltip: "How much the part wins over the comb direction"),
         "part.width": FieldHints(range: 0...0.05, step: 0.001, tooltip: "Meters of bare scalp along the line"),
         "lengthProfile": FieldHints(tooltip: "Length multipliers at the front, back, top and sides of the head"),
         "hemline": FieldHints(tooltip: "A blunt cut: tips end at a height (-1 the bottom of the hair area, 1 its top)"),
         "hemline.softness": FieldHints(range: 0...1, step: 0.01, tooltip: "Raggedness of the cut edge"),
         "fringe": FieldHints(tooltip: "Bangs: front hair combed down over the forehead"),
         "fringe.amount": FieldHints(range: 0...1, step: 0.05, tooltip: "How much of the front hairline is fringe (0: none)"),
         "fringe.length": FieldHints(range: 0...0.5, step: 0.005, tooltip: "The fringe's length in meters"),
         "fringe.sweep": FieldHints(range: -1...1, step: 0.05, tooltip: "Sweeps the fringe toward -X or +X"),
         "tie": FieldHints(tooltip: "A ponytail: strands run along the scalp to the tie point (hair bounds) and hang from it"),
         "tie.tail": FieldHints(range: 0...2, step: 0.01, tooltip: "The tail's length in meters"),
         "tie.radius": FieldHints(range: 0...0.2, step: 0.001, tooltip: "How thick the gathered tail is (meters)"),
         "colliders": FieldHints(tooltip: "Spheres (radius), ellipsoids (radii) or capsules (end) in the mesh's space the cards stay out of")]
    }

    var part: GroomPart
    var lengthProfile: GroomLengthProfile
    var hemline: GroomHemline
    var fringe: GroomFringe
    var tie: GroomTie
    var colliders: [GroomCollider]

    init(_ build: GroomBuild) {
        part = build.part
        lengthProfile = build.lengthProfile
        hemline = build.hemline
        fringe = build.fringe
        tie = build.tie
        colliders = build.colliders
    }

    func applied(to build: GroomBuild) -> GroomBuild {
        var edited = build
        edited.part = part
        edited.lengthProfile = lengthProfile
        edited.hemline = hemline
        edited.fringe = fringe
        edited.tie = tie
        edited.colliders = colliders
        return edited
    }
}

/// The proxy component for the detail levels.
struct GroomLODComponent: Component {
    static var componentName: String { "Detail Levels" }
    static var fieldHints: [String: FieldHints] {
        ["shells": FieldHints(tooltip: "Shells at each level (shell style; empty: shells, half, a quarter)"),
         "cards": FieldHints(tooltip: "The fraction of cards at each level (cards style)"),
         "distances": FieldHints(tooltip: "Meters where levels 1, 2… start; past the last only the undercoat draws")]
    }

    var lod: GroomLOD

    init(lod: GroomLOD) { self.lod = lod }
    init(from decoder: any Decoder) throws { lod = try GroomLOD(from: decoder) }
    func encode(to encoder: any Encoder) throws { try lod.encode(to: encoder) }
}

/// The proxy component for the brush (not saved).
struct GroomBrushComponent: Component {
    static var componentName: String { "Brush" }
    static var fieldHints: [String: FieldHints] {
        ["radius": FieldHints(range: 0.005...2, step: 0.005, tooltip: "Meters in the mesh's space"),
         "strength": FieldHints(range: 0...1, step: 0.05, tooltip: "How much one dab changes"),
         "length": FieldHints(range: 0...2, step: 0.05, tooltip: "The Length brush's target (1: full length)")]
    }

    var radius: Float
    var strength: Float
    var length: Float
}

@MainActor
public final class GroomBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var build: GroomBuild
    unowned let workspace: GroomBuilderWorkspace
    private let gridWorld = World()
    private var grids: [PropertyGrid] = []
    private var gridEntities: [Entity] = []
    private var presetIndex = 0
    private var pending: (build: GroomBuild, label: String)?

    static let combChoices: [(String, GroomDirection)] = [
        ("Straight out", .normal), ("Follow surface (down)", .followSurface), ("Back (-Z)", .vector(Vec3(0, 0, -1))),
        ("Forward (+Z)", .vector(Vec3(0, 0, 1))), ("Down (-Y)", .vector(Vec3(0, -1, 0))), ("Up (+Y)", .vector(Vec3(0, 1, 0))),
        ("Left (+X)", .vector(Vec3(1, 0, 0))), ("Right (-X)", .vector(Vec3(-1, 0, 0))),
    ]

    public init?(session: EditorSession, asset: AssetID, workspace: GroomBuilderWorkspace) {
        guard session.isGroomFile(asset), let build = session.assets?.groom(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.build = build
        self.workspace = workspace
        view = VStack(spacing: 6, name: "groomBuilder")
        layout()
    }

    /// Call every frame: applies the pending edit and keeps the grids in step.
    public func refresh() {
        if let pending {
            self.pending = nil
            if session.applyGroom(pending.build, to: asset, label: pending.label) != nil {
                build = session.assets?.groom(of: asset) ?? pending.build
                layout()
            }
        }
        for grid in grids { grid.refresh() }
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let build = session.assets?.groom(of: asset) else { return }
        self.build = build
        layout()
    }

    func apply(_ edited: GroomBuild, label: String) { pending = (edited, label) }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        grids = []
        for entity in gridEntities { gridWorld.despawn(entity) }
        gridEntities = []
        let place = Button("Place Preview", role: .primary, name: "groomPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put the preview (the groom on its preview mesh) in the scene"
        let applyButton = Button("Apply to Selection", name: "groomApplySelection") { [unowned self] in
            guard let entity = session.selection.ids.first, let path = session.assets?.path(of: asset) else {
                session.log.warning("Groom: select an entity with a mesh first")
                return
            }
            session.run(GroomApplyCommand.self, .init(groom: path, target: .init(entity: entity)))
        }
        applyButton.command = GroomApplyCommand.id.rawValue
        applyButton.tooltip = "Grow this fur on the selected entity (or the parts of a selected model)"
        view.addChild(HStack(spacing: 6, [place, applyButton, Spacer()]))

        view.addChild(Label("Preset", role: .secondary))
        let presets = Dropdown(options: GroomBuild.presetNames.map(VFXBuilderView.presetTitle), selectedIndex: presetIndex,
                               name: "groomPreset") { [unowned self] index in presetIndex = index }
        presets.tooltip = "A ready-made groom"
        let replace = Button("Replace", name: "groomPresetReplace") { [unowned self] in
            guard GroomBuild.presetNames.indices.contains(presetIndex), var preset = GroomBuild.preset(GroomBuild.presetNames[presetIndex]) else { return }
            preset.comb = build.comb
            preset.cut = build.cut
            preset.mask = build.mask
            preset.previewMesh = build.previewMesh
            apply(preset, label: "Apply \(VFXBuilderView.presetTitle(GroomBuild.presetNames[presetIndex])) Preset")
        }
        replace.command = GroomEditCommand.id.rawValue
        replace.tooltip = "Take the preset's settings (keeps the strokes, mask and preview mesh)"
        view.addChild(HStack(spacing: 4, [presets, replace]))

        // Brushes.
        view.addChild(Label("Brush", role: .secondary))
        let brushes = Dropdown(options: GroomBrush.allCases.map(\.title), selectedIndex: GroomBrush.allCases.firstIndex(of: workspace.brush) ?? 0,
                               name: "groomBrush") { [unowned self] index in workspace.brush = GroomBrush.allCases[index] }
        brushes.tooltip = "Left-drag on the preview paints: Mask removes fur, Restore brings it back, Length sets it, Comb turns it along the drag"
        let clear = Button("Clear Strokes", name: "groomClearStrokes") { [unowned self] in
            var edited = build
            edited.comb = []
            edited.cut = []
            apply(edited, label: "Clear Groom Strokes")
        }
        clear.command = GroomEditCommand.id.rawValue
        clear.isEnabled = !build.comb.isEmpty || !build.cut.isEmpty
        clear.tooltip = "Remove every comb and cut stroke"
        view.addChild(HStack(spacing: 4, [brushes, clear]))
        let brushEntity = gridWorld.spawn(GroomBrushComponent(radius: workspace.brushRadius, strength: workspace.brushStrength,
                                                              length: workspace.brushLength))
        addGrid(brushEntity, GroomBrushComponent.componentName) { [unowned self] in
            guard let b = gridWorld.get(GroomBrushComponent.self, for: brushEntity) else { return }
            workspace.brushRadius = max(b.radius, 0.001)
            workspace.brushStrength = min(max(b.strength, 0), 1)
            workspace.brushLength = min(max(b.length, 0), 2)
        }
        view.addChild(note("\(build.comb.count) comb and \(build.cut.count) cut stroke\(build.cut.count == 1 ? "" : "s") in the file."))

        // Direction.
        view.addChild(Label("Comb direction", role: .secondary))
        let current = Self.combChoices.firstIndex { $0.1 == build.combDirection }
        var options = Self.combChoices.map(\.0)
        if current == nil { options.append("Custom") }
        let comb = Dropdown(options: options, selectedIndex: current ?? options.count - 1, name: "groomCombDirection") { [unowned self] index in
            guard Self.combChoices.indices.contains(index) else { return }
            var edited = build
            edited.combDirection = Self.combChoices[index].1
            apply(edited, label: "Edit Comb Direction")
        }
        comb.command = GroomEditCommand.id.rawValue
        comb.tooltip = "Where strands lean before gravity and wind (Comb Strength sets how far)"
        view.addChild(comb)

        // Settings.
        view.addChild(Separator())
        view.addChild(Label("Fur", role: .secondary))
        let settings = gridWorld.spawn(GroomSettingsComponent(groom: build))
        addGrid(settings, GroomSettingsComponent.componentName) { [unowned self] in
            guard let s = gridWorld.get(GroomSettingsComponent.self, for: settings)?.groom else { return }
            var edited = s
            edited.comb = build.comb
            edited.cut = build.cut
            edited.mask = build.mask
            edited.lod = build.lod
            edited.combDirection = build.combDirection
            edited = GroomStyleComponent(build).applied(to: edited)
            apply(edited, label: "Edit Groom")
        }
        if build.drawnStyle == .cards {
            view.addChild(Label("Hairstyle", role: .secondary))
            let style = gridWorld.spawn(GroomStyleComponent(build))
            addGrid(style, GroomStyleComponent.componentName) { [unowned self] in
                guard let s = gridWorld.get(GroomStyleComponent.self, for: style) else { return }
                apply(s.applied(to: build), label: "Edit Hairstyle")
            }
            view.addChild(note("Parts, hemlines and ties are in the hair's bounds (-1...1 over the furry area; the face toward +Z). "
                               + "Scalp Hug, Volume, Inner Layer, Flyaways, Clump Size, Wave and Sweep Back are in the Fur settings above."))
        }
        view.addChild(Label("Mask", role: .secondary))
        let mask = gridWorld.spawn(GroomMaskComponent(mask: build.mask))
        addGrid(mask, GroomMaskComponent.componentName) { [unowned self] in
            guard let m = gridWorld.get(GroomMaskComponent.self, for: mask)?.mask else { return }
            var edited = build
            edited.mask = m
            apply(edited, label: "Edit Groom Mask")
        }
        view.addChild(Label("Detail levels", role: .secondary))
        let lod = gridWorld.spawn(GroomLODComponent(lod: build.lod))
        addGrid(lod, GroomLODComponent.componentName) { [unowned self] in
            guard let l = gridWorld.get(GroomLODComponent.self, for: lod)?.lod else { return }
            var edited = build
            edited.lod = l
            apply(edited, label: "Edit Groom Detail Levels")
        }
        let problems = GroomCheck.problems(build)
        view.addChild(note(problems.isEmpty ? "No problems." : problems.joined(separator: "\n")))
        view.addChild(note("Shells draw instanced; past the last detail distance only a fur-colored undercoat is drawn. "
                           + "Put the groom on a mesh with Apply to Selection, a Character Builder region or attachment, a Mesh Builder part or a terrain scatter rule."))
    }

    private func addGrid(_ entity: Entity, _ component: String, commit: @escaping () -> Void) {
        let grid = PropertyGrid(world: gridWorld, name: "groom\(component.filter { $0.isLetter })Grid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 112
        grid.entity = entity
        grid.command = GroomEditCommand.id.rawValue
        grid.stringChoices = { _, path in
            switch path {
            case "style": GroomStyle.allCases.map(\.rawValue)
            case "rootPlacement": GroomRootPlacement.allCases.map(\.rawValue)
            case "part.style": GroomPartStyle.allCases.map(\.rawValue)
            default: nil
            }
        }
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: component, for: entity, to: edit.newValue) } catch {
                session.log.error("Groom \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended { commit() }
        }
        grids.append(grid)
        gridEntities.append(entity)
        view.addChild(grid)
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "groomNote")
        label.wraps = true
        return label
    }
}
