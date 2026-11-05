import Engine
import Foundation

// The Mesh Builder: the asset inspector's form for a `.meshbuild` file. Add shapes with one
// click, pick a part to edit its shape, size, placement, parent, color, texture and material in
// a property grid, and give it a ready-made motion (spin, bob, swing, pulse, shake). Every
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
        (.pyramid, "Pyramid"), (.group, "Group"),
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
            button.tooltip = shape == .group
                ? "An invisible pivot: attach parts to it and animate it (a hinge, a turret)"
                : "Add a \(label.lowercased()) on top of the selected part"
            shapes.addChild(button)
        }
        view.addChild(shapes)

        view.addChild(Label("Parts", role: .secondary))
        listedParts = orderedParts()
        partList.items = listedParts.map { name in
            let depth = self.depth(of: name)
            let shape = build.parts.first { $0.name == name }?.shape.rawValue ?? ""
            return String(repeating: "    ", count: depth) + name + "  ·  " + shape
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

        guard let selectedPart, let part = build.parts.first(where: { $0.name == selectedPart }) else {
            view.addChild(note(build.parts.isEmpty ? "Add a shape to start." : "Pick a part to edit it."))
            return
        }
        addPartGrid(part)
        addAnimationSection(for: part)
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

    private func note(_ text: String) -> Label {
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

    private func apply(_ edited: MeshBuild, label: String, select name: String? = nil) {
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
        var part = MeshBuildPart(name: edited.uniquePartName(label), shape: shape, position: Vec3(0, 0.5, 0))
        if shape == .plane { part.size = Vec3(2, 1, 2); part.position = .zero }
        if shape == .torus { part.size = Vec3(1, 0.25, 1) }
        if let selected = build.parts.first(where: { $0.name == selectedPart }) {
            part.parent = selected.parent
            part.position = selected.position + Vec3(0, selected.size.y / 2 + part.size.y / 2, 0)
        }
        edited.parts.append(part)
        apply(edited, label: "Add \(label)", select: part.name)
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
