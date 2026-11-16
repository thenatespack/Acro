import Engine
import Foundation

// The Mesh Builder: the asset inspector's form for a `.meshbuild` file. Add shapes with one
// click, pick a part to edit its shape, size, placement, parent, color, texture and material in
// a property grid, its look (MeshBuilderView+Looks.swift), and give it a ready-made motion (spin, bob, swing, pulse, shake). Every
// change is written to the file at once as one undo step (`EditorSession.applyMeshBuild`), so
// the model reimports and placed copies update while you work; Ctrl+Z takes changes back.
// Keyframe tracks are kept and listed, and are written by `meshBuild.edit` or by hand.

/// The proxy component for one part: encodes and decodes as `MeshBuildPart`, so its fields are
/// the grid's rows.
struct MeshBuildPartComponent: Component {
    static var componentName: String { "Part" }
    static var fieldHints: [String: FieldHints] { MeshBuildPart.fieldHints }

    var part: MeshBuildPart

    init(part: MeshBuildPart) { self.part = part }
    init(from decoder: any Decoder) throws { part = try MeshBuildPart(from: decoder) }
    func encode(to encoder: any Encoder) throws { try part.encode(to: encoder) }
}

/// Edits one `.meshbuild` file. Rebuilt by the inspector whenever the file is reimported (its
/// selected part is remembered per asset).
@MainActor
public final class MeshBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var build: MeshBuild
    /// The part being edited.
    public private(set) var selectedPart: String?
    public private(set) var partGrid: PropertyGrid?
    let partList = ListView(items: [], name: "meshBuildParts")
    private let partWorld = World()
    private var partEntity: Entity?
    private var listedParts: [String] = []
    private var motionAxis = MeshBuildAxis.y
    /// The selected part of each mesh build, kept across rebuilds.
    private static var selections: [AssetID: String] = [:]

    /// The shapes offered as buttons, with their labels.
    static let shapeButtons: [(MeshBuildShape, String)] = [
        (.box, "Box"), (.sphere, "Sphere"), (.hemisphere, "Dome"), (.cylinder, "Cylinder"), (.cone, "Cone"),
        (.capsule, "Capsule"), (.torus, "Torus"), (.tube, "Tube"), (.plane, "Plane"), (.wedge, "Wedge"),
        (.pyramid, "Pyramid"), (.lathe, "Lathe"), (.extrude, "Extrude"), (.sweep, "Sweep"), (.loft, "Loft"), (.foliage, "Foliage"), (.sculpt, "Sculpt"), (.group, "Group"),
    ]

    /// The profile a new lathe starts with: a vase with a flared lip (radius, height in meters).
    static let starterLathe: [Vec2] = [
        Vec2(0, 0), Vec2(0.18, 0), Vec2(0.25, 0.12), Vec2(0.27, 0.25), Vec2(0.22, 0.42), Vec2(0.12, 0.58),
        Vec2(0.1, 0.68), Vec2(0.16, 0.78),
    ]
    /// The outline a new extrude starts with: an arrow pointing +X (x, y in meters).
    static let starterExtrude: [Vec2] = [
        Vec2(-0.5, -0.12), Vec2(0.1, -0.12), Vec2(0.1, -0.3), Vec2(0.5, 0), Vec2(0.1, 0.3), Vec2(0.1, 0.12),
        Vec2(-0.5, 0.12),
    ]

    /// Nil when `asset` isn't a readable `.meshbuild` file.
    /// Whether the form starts with its own "Mesh Builder" heading (off inside the workspace, which has one).
    public let showsTitle: Bool

    public init?(session: EditorSession, asset: AssetID, showsTitle: Bool = true) {
        guard session.isMeshBuildFile(asset), let build = session.assets?.meshBuild(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.build = build
        self.showsTitle = showsTitle
        view = VStack(spacing: 6, name: "meshBuilder")
        let remembered = Self.selections[asset]
        selectedPart = build.parts.contains { $0.name == remembered } ? remembered : build.parts.first?.name
        partList.style.height = 150
        partList.onSelect = { [unowned self] row in
            guard let row, listedParts.indices.contains(row), listedParts[row] != selectedPart else { return }
            select(listedParts[row])
        }
        layout()
    }

    /// An edit made by a widget callback, applied on the next `refresh` so no widget is torn
    /// down while it is handling an event.
    private var pending: (build: MeshBuild, label: String, select: String?)?

    /// Call every frame: applies the pending edit and keeps the grid in step with the proxy.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.build, label: pending.label, select: pending.select)
        }
        partGrid?.refresh()
    }

    /// Whether an edit is waiting for `refresh`.
    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let build = session.assets?.meshBuild(of: asset) else { return }
        self.build = build
        if !build.parts.contains(where: { $0.name == selectedPart }) { selectedPart = build.parts.first?.name }
        layout()
    }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        let title = Label("Mesh Builder", role: .heading)
        title.icon = EditorIcons.asset(.model)
        let place = Button("Place in Scene", role: .primary, name: "meshBuildPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this model in the scene (copies update when you change it here)"
        view.addChild(showsTitle ? HStack(spacing: 6, [title, Spacer(), place]) : HStack(spacing: 6, [place, Spacer()]))

        view.addChild(Label("Add a shape", role: .secondary))
        let shapes = HStack(spacing: 4, name: "meshBuildShapes")
        shapes.wraps = true
        for (shape, label) in Self.shapeButtons {
            let button = Button(label, name: "meshBuildAdd.\(shape.rawValue)") { [unowned self] in addPart(shape) }
            button.command = MeshBuildEditCommand.id.rawValue
            button.tooltip = switch shape {
            case .group: "An invisible pivot: attach parts to it and animate it (a hinge, a turret)"
            case .lathe: "Add a round solid spun from a profile (starts as a vase; edit its points below)"
            case .extrude: "Add a flat outline pushed out into a slab (starts as an arrow; edit its points below)"
            case .sweep: "Add a tube along a curved path: pipes, cables, handles, branches, horns (starts as a bent pipe)"
            case .loft: "Add a skin through stacked sections: bottles, hulls, fuselages, blades (starts as a flask)"
            case .foliage: "Add leaves: cut-out leaf cards filling a volume or growing on branches (starts as a broadleaf crown)"
            case .sculpt: "Add a sculpt: its child shapes melt together and cut into each other as one smooth surface (starts as a carved stone)"
            default: "Add a \(label.lowercased()) on top of the selected part"
            }
            shapes.addChild(button)
        }
        view.addChild(shapes)

        view.addChild(Label("Parts", role: .secondary))
        listedParts = orderedParts()
        let sculptOf = build.gatheringSculpts().sculptOf
        partList.items = listedParts.map { name in
            let depth = self.depth(of: name)
            let part = build.parts.first { $0.name == name }
            return String(repeating: "    ", count: depth) + name + "  ·  " + (part?.shape.rawValue ?? "") + (part.map(Self.copiesSummary) ?? "")
                + (part.map { sculptOf[$0.name] != nil ? Self.blendSummary($0) : "" } ?? "")
        }
        if let selectedPart, let row = listedParts.firstIndex(of: selectedPart) { partList.selectRow(row, reveal: true) }
        view.addChild(partList)
        let duplicate = Button("Duplicate", name: "meshBuildDuplicate") { [unowned self] in duplicateSelected() }
        let delete = Button("Delete", name: "meshBuildDelete") { [unowned self] in deleteSelected() }
        duplicate.isEnabled = selectedPart != nil
        delete.isEnabled = selectedPart != nil
        duplicate.tooltip = "Copy the selected part beside itself"
        delete.tooltip = "Remove the selected part (its children move up to its parent)"
        view.addChild(HStack(spacing: 6, [duplicate, delete, Spacer()]))
        addOcclusionToggle()  // MeshBuilderView+Looks.swift

        guard let selectedPart, let part = build.parts.first(where: { $0.name == selectedPart }) else {
            view.addChild(note(build.parts.isEmpty ? "Add a shape to start." : "Pick a part to edit it."))
            return
        }
        addPartGrid(part)
        addShapeSection(for: part)
        addCurveSection(for: part)  // sweep path / loft sections (MeshBuilderCurves.swift)
        addFoliageSection(for: part)  // foliage, ribbons, leaf looks (MeshBuilderView+Foliage.swift)
        addDeformSection(for: part)
        addSculptSection(for: part)
        addLookSection(for: part)  // MeshBuilderView+Looks.swift
        addSymmetrySection(for: part)
        addAnimationSection(for: part)
    }

    /// "  ·  ×4  ·  mirror x" for a part with copies, else "".
    static func copiesSummary(_ part: MeshBuildPart) -> String {
        var text = ""
        if let r = part.repetition, r.count > 1 { text += "  ·  ×\(r.count)" }
        if let m = part.mirror, !m.axes.isEmpty { text += "  ·  mirror " + m.axes.map(\.rawValue).joined() }
        return text
    }

    // MARK: Mirror and repeat

    /// Rows for the part's `mirror` (an axis toggle each) and `repeat` (count, then a line's
    /// offset or a ring's axis, angle and radius).
    private func addSymmetrySection(for part: MeshBuildPart) {
        let name = part.name
        view.addChild(Separator())
        view.addChild(Label("Mirror and Repeat", role: .secondary))
        if part.mirror != nil || part.repetition != nil {
            view.addChild(note("Copies show in the view and follow this part (with its children); clicking one picks this part."))
        }

        var mirrorRow: [Widget] = [rowLabel("Mirror")]
        for axis in MeshBuildAxis.allCases {
            let box = Checkbox(axis.rawValue.uppercased(), isOn: part.mirror?.axes.contains(axis) ?? false,
                               name: "meshBuildMirror.\(axis.rawValue)") { [unowned self] on in
                editPart(name, label: "Mirror Part") { p in
                    var axes = p.mirror?.axes ?? []
                    if on { axes.append(axis) } else { axes.removeAll { $0 == axis } }
                    p.mirror = axes.isEmpty ? nil : MeshBuildMirror(axes)
                }
            }
            box.command = MeshBuildEditCommand.id.rawValue
            box.tooltip = "Add a mirror image of this part and its children across the parent's \(axis.rawValue) = 0 plane"
            mirrorRow.append(box)
        }
        mirrorRow.append(Spacer())
        view.addChild(HStack(spacing: 6, mirrorRow))

        let repetition = part.repetition
        let count = NumberField(value: Double(repetition?.count ?? 1), isInteger: true, range: 1...Double(MeshBuildRepeat.maxCount),
                                step: 1, name: "meshBuildRepeatCount")
        count.tooltip = "Parts in all, this one included (1: no copies)"
        count.onEditEnded = { [unowned self] _, end in
            editPart(name, label: "Repeat Part") { p in
                let n = Int(end.rounded())
                if n <= 1 { p.repetition = nil; return }
                var r = p.repetition ?? MeshBuildRepeat(offset: Vec3(p.size.x + 0.1, 0, 0))
                r.count = n
                p.repetition = r
            }
        }
        count.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Repeat"), count]))
        guard let repetition else { return }

        let modes = ["Line", "Ring around parent", "Ring around itself"]
        let mode = repetition.radial == nil ? 0 : repetition.radial?.radius == nil ? 1 : 2
        let modeMenu = Dropdown(options: modes, selectedIndex: mode, name: "meshBuildRepeatMode") { [unowned self] index in
            editPart(name, label: "Repeat Part") { p in
                guard var r = p.repetition else { return }
                switch index {
                case 0: r.radial = nil
                case 1: r.radial = MeshBuildRepeat.Radial(axis: r.radial?.axis ?? .y, angle: r.radial?.angle ?? 360); r.offset = .zero
                default: r.radial = MeshBuildRepeat.Radial(axis: r.radial?.axis ?? .y, radius: r.radial?.radius ?? 0.5,
                                                           angle: r.radial?.angle ?? 360); r.offset = .zero
                }
                p.repetition = r
            }
        }
        modeMenu.tooltip = "A row of copies, a ring about the parent's origin, or a ring centered on this part"
        modeMenu.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Arrange"), modeMenu]))

        let offset = VectorField(count: 3, values: [repetition.offset.x, repetition.offset.y, repetition.offset.z].map(Double.init),
                                 step: 0.05, name: "meshBuildRepeatOffset")
        offset.tooltip = "Each copy's step from the one before, meters in the parent's space"
        offset.onEditEnded = { [unowned self] _, end in
            editPart(name, label: "Repeat Part") { p in p.repetition?.offset = Vec3(Float(end[0]), Float(end[1]), Float(end[2])) }
        }
        offset.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel(repetition.radial == nil ? "Offset" : "Rise"), offset]))
        guard let radial = repetition.radial else { return }

        let axis = Dropdown(options: ["X axis", "Y axis", "Z axis"], selectedIndex: radial.axis.index, name: "meshBuildRepeatAxis") {
            [unowned self] index in editPart(name, label: "Repeat Part") { p in p.repetition?.radial?.axis = MeshBuildAxis.allCases[index] }
        }
        axis.tooltip = "The parent's axis the ring turns about"
        let angle = NumberField(value: Double(radial.angle), range: -360...360, step: 1, name: "meshBuildRepeatAngle")
        angle.tooltip = "Degrees the ring spans: 360 spaces the copies evenly all round; less spreads them from 0 to this, both ends"
        angle.onEditEnded = { [unowned self] _, end in editPart(name, label: "Repeat Part") { p in p.repetition?.radial?.angle = Float(end) } }
        angle.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Ring"), axis, angle]))
        if let radius = radial.radius {
            let field = NumberField(value: Double(radius), range: 0...10_000, step: 0.05, name: "meshBuildRepeatRadius")
            field.tooltip = "How far each copy sits from this part's position, meters"
            field.onEditEnded = { [unowned self] _, end in editPart(name, label: "Repeat Part") { p in p.repetition?.radial?.radius = Float(end) } }
            field.style.grow = 1
            view.addChild(HStack(spacing: 6, [rowLabel("Radius"), field]))
        }
    }

    func rowLabel(_ text: String) -> Label {
        let label = Label(text)
        label.style.width = 104
        return label
    }

    /// Changes the part `name` as one edit (applied on the next `refresh`).
    func editPart(_ name: String, label: String, _ change: (inout MeshBuildPart) -> Void) {
        var edited = pending?.build ?? build
        guard let i = edited.parts.firstIndex(where: { $0.name == name }) else { return }
        change(&edited.parts[i])
        guard edited != build else { return }
        apply(edited, label: label, select: name)
    }

    private func addPartGrid(_ part: MeshBuildPart) {
        if let partEntity { partWorld.despawn(partEntity) }
        let entity = partWorld.spawn(MeshBuildPartComponent(part: part))
        partEntity = entity
        let grid = PropertyGrid(world: partWorld, name: "meshBuildPartGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        grid.command = MeshBuildEditCommand.id.rawValue
        grid.stringChoices = { [unowned self] _, path in choices(for: path, part: part.name) }
        grid.stringChoiceTitle = { [unowned session] _, path, value in
            if value.isEmpty { return path == "parent" ? "(root)" : "None" }
            if let reference = AssetReference(value), value.hasPrefix(AssetReference.scheme) {
                return session.assets?.displayName(of: reference) ?? value
            }
            return value
        }
        grid.onFieldEdit = { [unowned self] edit in
            do { try partWorld.setField(edit.path, of: MeshBuildPartComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Mesh build \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended { commitPart(from: entity, originalName: part.name) }
        }
        partGrid = grid
        view.addChild(grid)
    }

    /// The fields the grid hides because only some shapes use them: a bevel slider for boxes and
    /// cylinders, the profile's points for lathes and extrudes.
    private func addShapeSection(for part: MeshBuildPart) {
        if part.shape == .box || part.shape == .cylinder {
            let s = Vec3(abs(part.size.x), abs(part.size.y), abs(part.size.z))
            let limit = max(min(s.x, min(s.y, s.z)) / 2, 0.001)
            let value = min(max(part.bevel ?? 0, 0), limit)
            let caption = Label(String(format: "%.3f m", value), role: .caption, name: "meshBuildBevelValue")
            let slider = Slider(value: value, in: 0...limit, step: 0, name: "meshBuildBevel")
            slider.style.grow = 1
            slider.tooltip = part.shape == .box ? "Round the box's edges (meters)" : "Round the cylinder's rims (meters)"
            slider.accessibilityLabel = "Bevel"
            var dragging = false
            let commit: (Float) -> Void = { [unowned self] v in
                updatePart(part.name, label: "Bevel") { $0.bevel = v > 0 ? v : nil }
            }
            slider.onEditBegan = { dragging = true }
            slider.onChange = { v in
                caption.text = String(format: "%.3f m", v)
                if !dragging { commit(v) }  // keyboard changes come without began / ended
            }
            slider.onEditEnded = { [unowned slider] in
                dragging = false
                commit(slider.value)
            }
            let title = Label("Bevel", role: .body)
            title.style.width = 104
            view.addChild(HStack(spacing: 6, [title, slider, caption]))
        }
        // A sweep's profile, when it has one instead of a circle, is edited with the same rows.
        guard part.shape == .lathe || part.shape == .extrude || (part.shape == .sweep && part.profile != nil) else { return }
        let isLathe = part.shape == .lathe, isSweep = part.shape == .sweep
        let points = part.profile ?? []
        view.addChild(Separator())
        view.addChild(Label(isLathe ? "Profile: radius, height (m), bottom to top"
                            : isSweep ? "Section: x across, y up (m), around it" : "Outline: x, y (m), around the shape",
                            role: .secondary))
        let minimum = isLathe ? 2 : 3
        for (i, point) in points.enumerated() {
            let index = Label("\(i + 1)", role: .caption)
            index.style.width = 24
            var fields: [Widget] = [index]
            for axis in 0..<2 {
                let field = NumberField(value: Double(point[axis]), step: 0.01, name: "meshBuildProfile.\(i).\(axis)")
                field.prefix = isLathe ? (axis == 0 ? "r" : "h") : (axis == 0 ? "x" : "y")
                field.precision = 3
                field.style.grow = 1
                field.onEditEnded = { [unowned self] start, end in
                    guard start != end else { return }
                    updatePart(part.name, label: "Edit Profile") { p in
                        guard var profile = p.profile, profile.indices.contains(i) else { return }
                        profile[i][axis] = Float(end)
                        p.profile = profile
                    }
                }
                fields.append(field)
            }
            let remove = Button("Remove", name: "meshBuildProfileRemove.\(i)") { [unowned self] in
                updatePart(part.name, label: "Remove Profile Point") { p in
                    if var profile = p.profile, profile.indices.contains(i) { profile.remove(at: i); p.profile = profile }
                }
            }
            remove.command = MeshBuildEditCommand.id.rawValue
            remove.isEnabled = points.count > minimum
            remove.tooltip = "Remove this point (a \(part.shape.rawValue) keeps at least \(minimum))"
            fields.append(remove)
            view.addChild(HStack(spacing: 4, fields))
        }
        let add = Button("Add Point", name: "meshBuildProfileAdd") { [unowned self] in
            updatePart(part.name, label: "Add Profile Point") { p in
                var profile = p.profile ?? []
                let last = profile.last ?? .zero
                let step = profile.count >= 2 ? last - profile[profile.count - 2] : Vec2(0, 0.1)
                profile.append(last + step)
                p.profile = profile
            }
        }
        add.command = MeshBuildEditCommand.id.rawValue
        add.tooltip = isLathe ? "A new point above the last, continuing the profile" : "A new corner after the last, continuing the outline"
        view.addChild(HStack(spacing: 6, [add, Spacer()]))
        if isSweep { return }  // the sweep's own rows follow, with its notes and warnings
        view.addChild(note(isLathe
            ? "The profile spins around the part's Y axis; ends with a radius get flat caps, bends sharper than 40° stay hard. Size multiplies it."
            : "The outline is pushed out along Z, size.z meters deep. Concave is fine; edges must not cross. Size multiplies x and y."))
        let warnings = part.shapeWarnings
        if !warnings.isEmpty { view.addChild(note("⚠ " + warnings.joined(separator: " "))) }
    }

    /// Changes the part named `name` as one edit (applied on the next `refresh`).
    func updatePart(_ name: String, label: String, _ change: (inout MeshBuildPart) -> Void) {
        guard let index = build.parts.firstIndex(where: { $0.name == name }) else { return }
        var edited = build
        change(&edited.parts[index])
        guard edited != build else { return }
        apply(edited, label: label, select: name)
    }

    private func addAnimationSection(for part: MeshBuildPart) {
        view.addChild(Separator())
        view.addChild(Label("Animate \(part.name)", role: .secondary))
        let axis = Dropdown(options: ["X axis", "Y axis", "Z axis"], selectedIndex: motionAxis.index, name: "meshBuildMotionAxis") {
            [unowned self] index in motionAxis = MeshBuildAxis.allCases[index]
        }
        axis.tooltip = "The axis the next motion uses"
        let motions = HStack(spacing: 4, name: "meshBuildMotions")
        motions.wraps = true
        motions.addChild(axis)
        let kinds: [(MeshBuildMotion.Kind, String, String)] = [
            (.spin, "Spin", "Turn around the axis, one turn every 2 seconds"),
            (.bob, "Bob", "Float up and down along the axis"),
            (.swing, "Swing", "Rock 30° each way about the axis"),
            (.pulse, "Pulse", "Grow and shrink"),
            (.shake, "Shake", "Jitter along the axis"),
        ]
        for (kind, label, tooltip) in kinds {
            let button = Button(label, name: "meshBuildMotion.\(kind.rawValue)") { [unowned self] in
                addMotion(MeshBuildMotion(part: part.name, kind: kind, axis: motionAxis))
            }
            button.command = MeshBuildEditCommand.id.rawValue
            button.tooltip = tooltip
            motions.addChild(button)
        }
        view.addChild(motions)

        var any = false
        for (a, animation) in build.animations.enumerated() {
            for (m, motion) in animation.motions.enumerated() where motion.part == part.name {
                any = true
                let amount = motion.amount.map { String(format: " %g", $0) } ?? ""
                let period = motion.period.map { String(format: ", %gs", $0) } ?? ""
                addAnimationRow("\(animation.name): \(motion.kind.rawValue) \(motion.axis.rawValue)\(amount)\(period)") { [unowned self] build in
                    build.animations[a].motions.remove(at: m)
                }
            }
            for (t, track) in animation.tracks.enumerated() where track.part == part.name {
                any = true
                let end = track.keys.map(\.time).max() ?? 0
                addAnimationRow("\(animation.name): \(track.property.rawValue) keys ×\(track.keys.count), \(String(format: "%g", end))s") {
                    [unowned self] build in build.animations[a].tracks.remove(at: t)
                }
            }
        }
        view.addChild(note(any
            ? "Animations play in play mode and in games. Fine-tune amounts and keyframes with meshBuild.edit or in the file."
            : "No animation on this part yet. Pick an axis and a motion; press Play to see it."))
    }

    private func addAnimationRow(_ text: String, remove: @escaping (inout MeshBuild) -> Void) {
        let label = Label(text, role: .caption)
        label.style.grow = 1
        label.style.shrink = 1
        let button = Button("Remove", name: "meshBuildRemoveMotion") { [unowned self] in
            var edited = build
            remove(&edited)
            edited.animations.removeAll { $0.tracks.isEmpty && $0.motions.isEmpty }
            apply(edited, label: "Remove Animation")
        }
        button.command = MeshBuildEditCommand.id.rawValue
        view.addChild(HStack(spacing: 6, [label, button]))
    }

    func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "meshBuildNote")
        label.wraps = true
        return label
    }

    // MARK: Choices and order

    private func choices(for path: String, part: String) -> [String]? {
        switch path {
        case "shape": return MeshBuildShape.allCases.map(\.rawValue)
        case "parent":
            // Not itself or one of its descendants (that would make a loop).
            return [""] + build.parts.map(\.name).filter { $0 != part && !isAncestor(part, of: $0) }
        case "texture":
            return [""] + (session.assets?.references(of: .texture).map(\.description) ?? []) + current("texture", part)
        case "material":
            return [""] + (session.assets?.references(of: .material).map(\.description) ?? []) + current("material", part)
        default: return nil
        }
    }

    /// A path typed into the file is kept as a choice so the dropdown can show it.
    private func current(_ field: String, _ part: String) -> [String] {
        guard let p = build.parts.first(where: { $0.name == part }) else { return [] }
        let value = field == "texture" ? p.texture : p.material
        return value.isEmpty || value.hasPrefix(AssetReference.scheme) ? [] : [value]
    }

    private func isAncestor(_ ancestor: String, of name: String) -> Bool {
        var current = build.parts.first { $0.name == name }?.parent ?? ""
        var steps = 0
        while !current.isEmpty, steps <= build.parts.count {
            if current == ancestor { return true }
            current = build.parts.first { $0.name == current }?.parent ?? ""
            steps += 1
        }
        return false
    }

    private func depth(of name: String) -> Int {
        var depth = 0, current = build.parts.first { $0.name == name }?.parent ?? ""
        while !current.isEmpty, depth <= build.parts.count {
            depth += 1
            current = build.parts.first { $0.name == current }?.parent ?? ""
        }
        return depth
    }

    /// Part names depth first (children under their parent), each once.
    private func orderedParts() -> [String] {
        var result: [String] = [], seen: Set<String> = []
        let names = Set(build.parts.map(\.name))
        func visit(_ name: String) {
            guard seen.insert(name).inserted else { return }
            result.append(name)
            for child in build.parts where child.parent == name { visit(child.name) }
        }
        for part in build.parts where part.parent.isEmpty || !names.contains(part.parent) { visit(part.name) }
        for part in build.parts { visit(part.name) }  // loops
        return result
    }

    // MARK: Edits

    /// Selects a part (nil: none) without changing the file.
    public func selectPart(_ name: String?) {
        guard name != selectedPart else { return }
        select(name)
    }

    /// Changes every part with `change` as one edit (applied on the next `refresh`).
    public func updateParts(label: String, _ change: (inout MeshBuildPart) -> Void) {
        var edited = pending?.build ?? build
        for i in edited.parts.indices { change(&edited.parts[i]) }
        guard edited != build else { return }
        apply(edited, label: label, select: selectedPart)
    }

    private func select(_ name: String?) {
        selectedPart = name
        Self.selections[asset] = name
        layout()
    }

    func apply(_ edited: MeshBuild, label: String, select name: String? = nil) {
        pending = (edited, label, name)
    }

    private func commit(_ edited: MeshBuild, label: String, select name: String?) {
        guard session.applyMeshBuild(edited, to: asset, label: label) != nil else { return }
        build = session.assets?.meshBuild(of: asset) ?? edited
        if let name { Self.selections[asset] = name }
        select(Self.selections[asset].flatMap { n in build.parts.contains { $0.name == n } ? n : nil } ?? build.parts.first?.name)
    }

    /// A new part of `shape` stacked on the selected one (same parent), or at the origin's ground.
    func addPart(_ shape: MeshBuildShape) {
        var edited = build
        let label = Self.shapeButtons.first { $0.0 == shape }?.1 ?? shape.rawValue.capitalized
        var part = MeshBuildPart(name: edited.uniquePartName(label), shape: shape)
        if shape == .plane { part.size = Vec3(2, 1, 2) }
        if shape == .torus { part.size = Vec3(1, 0.25, 1) }
        if shape == .lathe { part.profile = Self.starterLathe }
        if shape == .extrude { part.profile = Self.starterExtrude; part.size = Vec3(1, 1, 0.15) }
        Self.applyCurveStarter(to: &part)  // sweep path, loft sections
        Self.applyFoliageStarter(to: &part)  // a crown
        if shape == .sculpt { return addSculpt(named: part.name) }
        // Rest on the ground, or on top of the selected part (profile shapes aren't centered, so go by bounds).
        let bounds = part.localBounds
        let bottom = shape == .plane ? 0 : bounds.center.y - bounds.halfExtent.y
        part.position = Vec3(0, -bottom, 0)
        if let selected = build.parts.first(where: { $0.name == selectedPart }) {
            let below = partBounds(of: selected)
            part.parent = selected.parent
            part.position = selected.position + Vec3(0, below.center.y + below.halfExtent.y - bottom, 0)
        }
        edited.parts.append(part)
        apply(edited, label: "Add \(label)", select: part.name)
    }

    /// A part's box in its own space; a sculpt's from its children.
    private func partBounds(of part: MeshBuildPart) -> Bounds {
        guard part.shape == .sculpt else { return part.localBounds }
        return build.gatheringSculpts().build.parts.first { $0.name == part.name }?.localBounds ?? part.localBounds
    }

    /// A new sculpt with a starter: a rounded block with a dome melted onto it and a hole cut
    /// through, stacked like `addPart`.
    private func addSculpt(named name: String) {
        var edited = build
        var sculpt = MeshBuildPart(name: name, shape: .sculpt, color: Vec3(0.62, 0.6, 0.56))
        sculpt.roughness = 0.85
        if let selected = build.parts.first(where: { $0.name == selectedPart }) {
            let below = partBounds(of: selected)
            sculpt.parent = selected.parent
            sculpt.position = selected.position + Vec3(0, below.center.y + below.halfExtent.y, 0)
        }
        edited.parts.append(sculpt)
        for var child in Self.starterSculpt {
            child.name = edited.uniquePartName(child.name)
            child.parent = name
            edited.parts.append(child)
        }
        apply(edited, label: "Add Sculpt", select: name)
    }

    /// The children a new sculpt starts with (its origin is their base).
    static var starterSculpt: [MeshBuildPart] {
        var dome = MeshBuildPart(name: "Dome", shape: .sphere, position: Vec3(0, 0.5, 0), size: Vec3(0.6, 0.5, 0.45))
        dome.smooth = 0.12
        var hole = MeshBuildPart(name: "Hole", shape: .cylinder, position: Vec3(0, 0.28, 0), rotation: Vec3(90, 0, 0),
                                 size: Vec3(0.22, 0.7, 0.22))
        hole.blend = .subtract
        hole.smooth = 0.02
        return [MeshBuildPart(name: "Block", position: Vec3(0, 0.25, 0), size: Vec3(0.8, 0.5, 0.5), bevel: 0.04), dome, hole]
    }

    /// "  ·  subtract, smooth 0.05" for a sculpt child that isn't a plain add, else "".
    static func blendSummary(_ part: MeshBuildPart) -> String {
        var notes: [String] = []
        if let blend = part.blend, blend != .add { notes.append(blend.rawValue) }
        if let smooth = part.smooth, smooth > 0 { notes.append(String(format: "smooth %g", smooth)) }
        return notes.isEmpty ? "" : "  ·  " + notes.joined(separator: ", ")
    }

    // MARK: Sculpt

    /// A sculpt's grid and noise rows, or a sculpt child's blend and smooth rows.
    private func addSculptSection(for part: MeshBuildPart) {
        let name = part.name
        if part.shape == .sculpt {
            view.addChild(Separator())
            view.addChild(Label("Sculpt", role: .secondary))
            let resolution = NumberField(value: Double(part.sculptResolution), isInteger: true,
                                         range: Double(MeshBuildPart.sculptResolutionRange.lowerBound)...Double(MeshBuildPart.sculptResolutionRange.upperBound),
                                         step: 8, name: "meshBuildSculptResolution")
            resolution.tooltip = "Grid cells along the sculpt's longest side: more is finer detail and a slower import"
            resolution.onEditEnded = { [unowned self] start, end in
                guard start != end else { return }
                updatePart(name, label: "Sculpt Resolution") { p in
                    let n = Int(end.rounded())
                    p.resolution = n == MeshBuildPart.defaultSculptResolution ? nil : n
                }
            }
            resolution.style.grow = 1
            view.addChild(HStack(spacing: 6, [rowLabel("Resolution"), resolution]))
            let noise = part.noise
            let fields: [(String, Double, ClosedRange<Double>, Double, (inout MeshBuildNoise, Double) -> Void, String)] = [
                ("amount", Double(noise?.amount ?? 0), 0...1, 0.005, { $0.amount = Float($1) }, "Bump height, meters (0: smooth)"),
                ("scale", Double(noise?.scale ?? MeshBuildNoise().scale), 0.005...100, 0.01, { $0.scale = Float($1) }, "Bump size, meters across"),
                ("seed", Double(noise?.seed ?? 0), 0...100_000, 1, { $0.seed = Int($1.rounded()) }, "Another seed, another pattern"),
            ]
            var row: [Widget] = [rowLabel("Noise")]
            for (key, value, range, step, set, tooltip) in fields {
                let field = NumberField(value: value, isInteger: key == "seed", range: range, step: step, name: "meshBuildSculptNoise.\(key)")
                field.prefix = String(key.prefix(1))
                field.tooltip = tooltip
                field.style.grow = 1
                field.onEditEnded = { [unowned self] start, end in
                    guard start != end else { return }
                    updatePart(name, label: "Sculpt Noise") { p in
                        var n = p.noise ?? MeshBuildNoise(amount: 0)
                        set(&n, end)
                        p.noise = n.amount == 0 ? nil : n
                    }
                }
                row.append(field)
            }
            view.addChild(HStack(spacing: 4, row))
            view.addChild(note("Its children melt into one surface, in list order: each adds, subtracts or intersects, smoothed by its Smooth. "
                               + "The sculpt's look covers the children that set none; a child with its own color or look keeps it. Size multiplies the mesh."))
            var warnings: [String] = []
            if let gathered = build.gatheringSculpts().build.parts.first(where: { $0.name == name }) { _ = gathered.geometry(warnings: &warnings) }
            if !warnings.isEmpty { view.addChild(note("⚠ " + warnings.joined(separator: " "))) }
            return
        }
        guard let sculpt = build.gatheringSculpts().sculptOf[name] else { return }
        view.addChild(Separator())
        view.addChild(Label("In sculpt \(sculpt)", role: .secondary))
        let blends = MeshBuildBlend.allCases
        let blend = Dropdown(options: ["Add", "Subtract", "Intersect"], selectedIndex: blends.firstIndex(of: part.blend ?? .add) ?? 0,
                             name: "meshBuildSculptBlend") { [unowned self] index in
            updatePart(name, label: "Sculpt Blend") { p in p.blend = blends[index] == .add ? nil : blends[index] }
        }
        blend.tooltip = "Join this shape on, cut it out, or keep only where it overlaps the shapes before it"
        blend.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Blend"), blend]))
        let smooth = NumberField(value: Double(part.smooth ?? 0), range: 0...10, step: 0.01, name: "meshBuildSculptSmooth")
        smooth.tooltip = "Meters over which this shape melts into the ones before it (0: a sharp seam)"
        smooth.precision = 3
        smooth.onEditEnded = { [unowned self] start, end in
            guard start != end else { return }
            updatePart(name, label: "Sculpt Smooth") { p in p.smooth = end > 0 ? Float(end) : nil }
        }
        smooth.style.grow = 1
        view.addChild(HStack(spacing: 6, [rowLabel("Smooth"), smooth]))
        view.addChild(note("Part of \(sculpt)'s surface (outlined in the view when selected); it isn't drawn on its own (its color and look, if set, paint the surface it makes) and can't be animated on its own."))
    }

    func duplicateSelected() {
        guard let source = build.parts.first(where: { $0.name == selectedPart }) else { return }
        var edited = build
        var copy = source
        copy.name = edited.uniquePartName(source.name)
        copy.position.x += source.size.x + 0.1
        edited.parts.append(copy)
        apply(edited, label: "Duplicate Part", select: copy.name)
    }

    func deleteSelected() {
        guard let name = selectedPart else { return }
        var edited = build
        edited.removeParts([name])
        edited.animations.removeAll { $0.tracks.isEmpty && $0.motions.isEmpty }
        Self.selections[asset] = edited.parts.first { $0.name == build.parts.first { $0.name == name }?.parent }?.name
        apply(edited, label: "Delete Part")
    }

    func addMotion(_ motion: MeshBuildMotion) {
        guard let edited = try? MeshBuildEditCommand.edited(build, with: .init(addMotions: [motion])) else { return }
        apply(edited, label: "Add \(motion.kind.rawValue.capitalized)")
    }

    private func commitPart(from entity: Entity, originalName: String) {
        guard var part = partWorld.get(MeshBuildPartComponent.self, for: entity)?.part,
              let index = build.parts.firstIndex(where: { $0.name == originalName }) else { return }
        var edited = build
        let newName = part.name.trimmingCharacters(in: .whitespaces)
        part.name = originalName
        edited.parts[index] = part
        var selectName = originalName
        if !newName.isEmpty, newName != originalName {
            if edited.parts.contains(where: { $0.name == newName }) {
                session.log.warning("Mesh build: a part is already named \(newName)")
            } else {
                edited.renamePart(originalName, to: newName)
                selectName = newName
            }
        }
        apply(edited, label: "Edit Part", select: selectName)
    }
}
