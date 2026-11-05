import Engine
import Foundation

// The VFX Builder form for a `.vfx` file: preset buttons, the emitter list (add, duplicate,
// delete) and a property grid for the selected emitter's fields and for the effect's own
// settings (loop length, preview background and ground). Every change is written to the file as
// one undo step (`EditorSession.applyVFX`), so the prefab reimports and placed copies update.

/// The proxy component for one emitter: encodes and decodes as `VFXEmitter`.
struct VFXEmitterComponent: Component {
    static var componentName: String { "Emitter" }
    static var fieldHints: [String: FieldHints] { VFXEmitter.fieldHints }

    var emitter: VFXEmitter

    init(emitter: VFXEmitter) { self.emitter = emitter }
    init(from decoder: any Decoder) throws { emitter = try VFXEmitter(from: decoder) }
    func encode(to encoder: any Encoder) throws { try emitter.encode(to: encoder) }
}

/// The proxy component for the effect's own settings.
struct VFXSettingsComponent: Component {
    static var componentName: String { "Effect" }
    static var fieldHints: [String: FieldHints] {
        ["duration": FieldHints(range: 0.1...120, step: 0.1, tooltip: "Seconds one run lasts: the preview restarts after this when looping"),
         "background": FieldHints(color: true, tooltip: "Preview background color (not saved into placed copies)"),
         "ground": FieldHints(tooltip: "Show a ground plane in the preview")]
    }

    var duration: Float
    var background: Vec3
    var ground: Bool

    init(_ build: VFXBuild) {
        duration = build.duration
        background = build.background
        ground = build.ground
    }
}

@MainActor
public final class VFXBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var build: VFXBuild
    /// The emitter being edited.
    public private(set) var selectedEmitter: String?
    public private(set) var emitterGrid: PropertyGrid?
    let emitterList = ListView(items: [], name: "vfxEmitters")
    private let gridWorld = World()
    private var emitterEntity: Entity?
    private var settingsEntity: Entity?
    private var listed: [String] = []
    private var presetIndex = 0
    private static var selections: [AssetID: String] = [:]

    public let showsTitle: Bool

    public init?(session: EditorSession, asset: AssetID, showsTitle: Bool = true) {
        guard session.isVFXFile(asset), let build = session.assets?.vfx(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.build = build
        self.showsTitle = showsTitle
        view = VStack(spacing: 6, name: "vfxBuilder")
        let remembered = Self.selections[asset]
        selectedEmitter = build.emitters.contains { $0.name == remembered } ? remembered : build.emitters.first?.name
        emitterList.style.height = 120
        emitterList.onSelect = { [unowned self] row in
            guard let row, listed.indices.contains(row), listed[row] != selectedEmitter else { return }
            select(listed[row])
        }
        layout()
    }

    private var pending: (build: VFXBuild, label: String, select: String?)?

    /// Call every frame: applies the pending edit and keeps the grids in step with their proxies.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.build, label: pending.label, select: pending.select)
        }
        emitterGrid?.refresh()
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let build = session.assets?.vfx(of: asset) else { return }
        self.build = build
        if !build.emitters.contains(where: { $0.name == selectedEmitter }) { selectedEmitter = build.emitters.first?.name }
        layout()
    }

    // MARK: Layout

    private func layout() {
        view.removeAllChildren()
        let title = Label("VFX Builder", role: .heading)
        title.icon = EditorIcons.asset(.model)
        let place = Button("Place in Scene", role: .primary, name: "vfxPlace") { [unowned self] in
            session.run(AssetInstantiateCommand.self, .init(asset: AssetReference(asset)))
        }
        place.command = AssetInstantiateCommand.id.rawValue
        place.tooltip = "Put a copy of this effect in the scene (copies update when you change it here)"
        view.addChild(showsTitle ? HStack(spacing: 6, [title, Spacer(), place]) : HStack(spacing: 6, [place, Spacer()]))

        view.addChild(Label("Preset", role: .secondary))
        let presets = Dropdown(options: VFXBuild.presetNames.map(Self.presetTitle), selectedIndex: presetIndex, name: "vfxPreset") {
            [unowned self] index in presetIndex = index
        }
        presets.tooltip = "A ready-made effect"
        let replace = Button("Replace", name: "vfxPresetReplace") { [unowned self] in applyPreset(add: false) }
        replace.command = VFXEditCommand.id.rawValue
        replace.tooltip = "Replace all emitters with the preset's"
        let add = Button("Add", name: "vfxPresetAdd") { [unowned self] in applyPreset(add: true) }
        add.command = VFXEditCommand.id.rawValue
        add.tooltip = "Add the preset's emitters to this effect"
        view.addChild(HStack(spacing: 4, [presets, replace, add]))

        view.addChild(Label("Emitters", role: .secondary))
        listed = build.emitters.map(\.name)
        emitterList.items = build.emitters.map { e in
            let timing = e.delay > 0 ? String(format: "  ·  +%gs", e.delay) : ""
            return e.name + "  ·  " + e.blend.rawValue + timing
        }
        if let selectedEmitter, let row = listed.firstIndex(of: selectedEmitter) { emitterList.selectRow(row, reveal: true) }
        view.addChild(emitterList)
        let new = Button("Add Emitter", name: "vfxAddEmitter") { [unowned self] in addEmitter() }
        new.command = VFXEditCommand.id.rawValue
        let duplicate = Button("Duplicate", name: "vfxDuplicate") { [unowned self] in duplicateSelected() }
        let delete = Button("Delete", name: "vfxDelete") { [unowned self] in deleteSelected() }
        duplicate.isEnabled = selectedEmitter != nil
        delete.isEnabled = selectedEmitter != nil
        new.tooltip = "Add a soft additive emitter"
        duplicate.tooltip = "Copy the selected emitter"
        delete.tooltip = "Remove the selected emitter"
        view.addChild(HStack(spacing: 6, [new, duplicate, delete, Spacer()]))

        if let selectedEmitter, let emitter = build.emitters.first(where: { $0.name == selectedEmitter }) {
            addEmitterGrid(emitter)
        } else {
            view.addChild(note(build.emitters.isEmpty ? "Add an emitter or pick a preset to start." : "Pick an emitter to edit it."))
        }
        addSettingsGrid()
    }

    private func addEmitterGrid(_ emitter: VFXEmitter) {
        if let emitterEntity { gridWorld.despawn(emitterEntity) }
        let entity = gridWorld.spawn(VFXEmitterComponent(emitter: emitter))
        emitterEntity = entity
        let grid = PropertyGrid(world: gridWorld, name: "vfxEmitterGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        grid.command = VFXEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: VFXEmitterComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("VFX \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended { commitEmitter(from: entity, originalName: emitter.name) }
        }
        emitterGrid = grid
        view.addChild(Label("Emitter: \(emitter.name)", role: .secondary))
        view.addChild(grid)
    }

    private func addSettingsGrid() {
        view.addChild(Separator())
        view.addChild(Label("Effect", role: .secondary))
        if let settingsEntity { gridWorld.despawn(settingsEntity) }
        let entity = gridWorld.spawn(VFXSettingsComponent(build))
        settingsEntity = entity
        let grid = PropertyGrid(world: gridWorld, name: "vfxSettingsGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        grid.command = VFXEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try gridWorld.setField(edit.path, of: VFXSettingsComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("VFX \(edit.path): \(error)")
                return
            }
            guard edit.phase == .ended, let s = gridWorld.get(VFXSettingsComponent.self, for: entity) else { return }
            var edited = build
            edited.duration = max(s.duration, 0.1)
            edited.background = s.background
            edited.ground = s.ground
            apply(edited, label: "Edit Effect", select: selectedEmitter)
        }
        view.addChild(grid)
        view.addChild(note("Emitters with a delay start that many seconds after the effect begins. The preview loops after the "
                           + "duration. Spawn a placed copy's particles by placing or instantiating the effect."))
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "vfxNote")
        label.wraps = true
        return label
    }

    static func presetTitle(_ name: String) -> String {
        name.prefix(1).uppercased() + name.dropFirst().map { $0.isUppercase ? " " + String($0) : String($0) }.joined()
    }

    // MARK: Edits

    public func selectEmitter(_ name: String?) {
        guard name != selectedEmitter else { return }
        select(name)
    }

    private func select(_ name: String?) {
        selectedEmitter = name
        Self.selections[asset] = name
        layout()
    }

    private func apply(_ edited: VFXBuild, label: String, select name: String? = nil) {
        pending = (edited, label, name)
    }

    private func commit(_ edited: VFXBuild, label: String, select name: String?) {
        guard session.applyVFX(edited, to: asset, label: label) != nil else { return }
        build = session.assets?.vfx(of: asset) ?? edited
        if let name { Self.selections[asset] = name }
        select(Self.selections[asset].flatMap { n in build.emitters.contains { $0.name == n } ? n : nil } ?? build.emitters.first?.name)
    }

    func applyPreset(add: Bool) {
        guard VFXBuild.presetNames.indices.contains(presetIndex), let preset = VFXBuild.preset(VFXBuild.presetNames[presetIndex]) else { return }
        var edited = build
        let title = Self.presetTitle(VFXBuild.presetNames[presetIndex])
        if add {
            for var e in preset.emitters {
                e.name = edited.uniqueEmitterName(e.name)
                edited.emitters.append(e)
            }
        } else {
            edited.emitters = preset.emitters
            edited.duration = preset.duration
        }
        apply(edited, label: "\(add ? "Add" : "Apply") \(title) Preset", select: edited.emitters.first?.name)
    }

    func addEmitter() {
        var edited = build
        var e = VFXEmitter()
        e.name = edited.uniqueEmitterName("Emitter")
        e.rate = 60
        e.shape = .sphere
        e.shapeSize = Vec3(0.2, 0.2, 0.2)
        e.size = Vec2(0.1, 0.15)
        e.gravity = Vec3(0, 1, 0)
        e.color = [ParticleColorKey(0, Vec4(1, 0.7, 0.3, 0.8)), ParticleColorKey(1, Vec4(1, 0.2, 0.05, 0))]
        e.intensity = 2
        edited.emitters.append(e)
        apply(edited, label: "Add Emitter", select: e.name)
    }

    func duplicateSelected() {
        guard let source = build.emitters.first(where: { $0.name == selectedEmitter }) else { return }
        var edited = build
        var copy = source
        copy.name = edited.uniqueEmitterName(source.name)
        copy.seed &+= 1
        edited.emitters.append(copy)
        apply(edited, label: "Duplicate Emitter", select: copy.name)
    }

    func deleteSelected() {
        guard let name = selectedEmitter else { return }
        var edited = build
        edited.emitters.removeAll { $0.name == name }
        Self.selections[asset] = edited.emitters.first?.name
        apply(edited, label: "Delete Emitter")
    }

    private func commitEmitter(from entity: Entity, originalName: String) {
        guard var emitter = gridWorld.get(VFXEmitterComponent.self, for: entity)?.emitter,
              let index = build.emitters.firstIndex(where: { $0.name == originalName }) else { return }
        var edited = build
        let newName = emitter.name.trimmingCharacters(in: .whitespaces)
        emitter.name = originalName
        var selectName = originalName
        if !newName.isEmpty, newName != originalName {
            if edited.emitters.contains(where: { $0.name == newName }) {
                session.log.warning("VFX: an emitter is already named \(newName)")
            } else {
                emitter.name = newName
                selectName = newName
            }
        }
        edited.emitters[index] = emitter
        apply(edited, label: "Edit Emitter", select: selectName)
    }
}
