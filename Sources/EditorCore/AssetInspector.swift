import Engine
import Foundation

// The inspector for assets picked in the asset browser: a file's import settings (with Apply /
// Revert) and, for materials, their fields (editable and undoable for `.material` files,
// read-only for materials imported from a model, which offer Extract Materials instead).
//
// Both forms reuse `PropertyGrid`, which shows an entity's components by reflection: each
// editor keeps a private `World` with one entity holding a proxy component whose Codable form
// is the settings or the material. New fields of the settings or of `MaterialAsset` show up
// without changes here, with an editor chosen from their Codable type.

/// The proxy component for a typed importer's settings: encodes and decodes as the settings.
struct ImportSettingsComponent<S: Codable>: Component {
    static var componentName: String { "Import Settings" }
    static var fieldHints: [String: FieldHints] {
        ["materialRemap": FieldHints(readOnly: true, tooltip: "Set by Extract Materials")]
    }

    var settings: S

    init(settings: S) { self.settings = settings }
    init(from decoder: any Decoder) throws { settings = try S(from: decoder) }
    func encode(to encoder: any Encoder) throws { try settings.encode(to: encoder) }
}

/// The proxy component for settings of an importer without a registered form: the raw JSON.
struct JSONSettingsComponent: Component {
    static var componentName: String { "Import Settings" }
    var value: JSONValue

    init(value: JSONValue) { self.value = value }
    init(from decoder: any Decoder) throws { value = try JSONValue(from: decoder) }
    func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
}

/// Typed forms for import settings in the inspector, by importer name. A registered type gives
/// each field its real kind (a `Float` stays a float field even when its value is whole);
/// importers without one get a form built from the settings' JSON.
@MainActor
public enum ImportSettingsForms {
    private static var makers: [String: (Data) throws -> any Component] = [:]

    /// Uses `S` (the importer's `Settings`) for assets imported by `importer`.
    public static func register<S: Codable>(_ type: S.Type, importer: String) {
        makers[importer] = { data in try JSONDecoder().decode(ImportSettingsComponent<S>.self, from: data) }
    }

    /// The built-in importers' settings: texture, OBJ and glTF.
    public static func registerBuiltins() {
        register(TextureImporter.Settings.self, importer: TextureImporter().name)
        register(OBJImporter.Settings.self, importer: OBJImporter().name)
        register(GLTFImporter.Settings.self, importer: GLTFImporter().name)
        register(ProceduralTextureImporter.Settings.self, importer: ProceduralTextureImporter().name)
    }

    /// The proxy component holding `settings` for `importer`.
    static func component(importer: String, settings: JSONValue) throws -> any Component {
        let data = try JSONEncoder().encode(settings)
        if let make = makers[importer] { return try make(data) }
        return JSONSettingsComponent(value: settings)
    }
}

/// `value` as untyped JSON.
func jsonValue<T: Encodable>(_ value: T) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))
}

/// Edits one asset's import settings: a form (`world` / `entity` for a `PropertyGrid`) holding
/// pending values, `apply()` writes them with `AssetDatabase.setSettings` (sidecar + reimport),
/// `revert()` goes back to the stored ones.
@MainActor
public final class AssetSettingsEditor {
    public let session: EditorSession
    public let asset: AssetID
    public let importer: String
    /// Holds the form's proxy component.
    public let world = World()
    public let entity: Entity
    /// The settings as stored (effective values), in the form's encoding.
    public private(set) var stored: JSONValue = .null

    /// Nil when the asset has no importer or its importer has no settings.
    public init?(session: EditorSession, asset: AssetID) {
        guard let assets = session.assets, let importer = assets.record(asset)?.importer,
              let settings = assets.settings(of: asset), case .object(let keys) = settings, !keys.isEmpty else { return nil }
        self.session = session
        self.asset = asset
        self.importer = importer
        entity = world.spawn()
        load(settings)
    }

    /// The component name the grid shows.
    public var componentName: String { world.components(of: entity).first.map { type(of: $0).componentName } ?? "" }

    /// The form's current values.
    public var pending: JSONValue {
        (world.components(of: entity).first).flatMap { try? jsonValue($0) } ?? stored
    }

    /// Whether the form differs from the stored settings.
    public var isModified: Bool { pending != stored }

    /// Sets a field of the form (not yet applied).
    public func setField(_ path: String, to value: FieldValue) throws {
        try world.setField(path, of: componentName, for: entity, to: value)
    }

    /// Writes the pending settings to the sidecar and reimports (`asset.applySettings`). Returns
    /// whether it worked.
    @discardableResult
    public func apply() -> Bool {
        guard session.run(AssetApplySettingsCommand.self, .init(asset: asset, settings: pending)) != nil else { return false }
        revert()
        return true
    }

    /// Drops pending changes: the form shows the stored settings again.
    public func revert() {
        guard let settings = session.assets?.settings(of: asset) else { return }
        load(settings)
    }

    private func load(_ settings: JSONValue) {
        do {
            let component = try ImportSettingsForms.component(importer: importer, settings: settings)
            world.add(component, to: entity)  // replaces the previous one (same importer, same type)
            stored = try jsonValue(component)
        } catch {
            session.log.error("Can't show the import settings: \(error)")
        }
    }
}

/// The proxy component for a material: encodes and decodes as `MaterialAsset`, so its fields
/// (including ones added later) are the grid's rows.
struct MaterialAssetComponent: Component {
    static var componentName: String { "Material" }
    /// Color pickers for every color-like field (by name), from the default material's encoding.
    static let colorHints: [String: FieldHints] = {
        guard case .object(let keys)? = try? jsonValue(MaterialAsset()) else { return [:] }
        var hints: [String: FieldHints] = [:]
        for (key, value) in keys where key.lowercased().contains("color") {
            if case .array(let items) = value, items.count == 3 || items.count == 4 { hints[key] = FieldHints(color: true) }
        }
        return hints
    }()
    static var fieldHints: [String: FieldHints] { colorHints }

    var material: MaterialAsset

    init(material: MaterialAsset) { self.material = material }
    init(from decoder: any Decoder) throws { material = try MaterialAsset(from: decoder) }
    func encode(to encoder: any Encoder) throws { try material.encode(to: encoder) }

    /// Options for string fields: textures (any field whose name contains "texture") list
    /// "" (none) and the project's textures; sampler settings list their values.
    @MainActor static func choices(path: String, assets: AssetDatabase?) -> [String]? {
        if path.lowercased().contains("texture") {
            return [""] + (assets?.references(of: .texture).map(\.description) ?? [])
        }
        switch path {
        case "filter": return ["linear", "nearest"]
        case "mipFilter": return ["none", "nearest", "linear"]
        case "addressMode": return ["repeat", "clampToEdge", "mirrorRepeat"]
        default: return nil
        }
    }
}

/// Edits a material asset through a form. For a `.material` file, every gesture is one undo
/// step (`material.set`, a `MaterialEditCommand`) that saves the file; changes during a drag are
/// written live without being recorded (`material.set`, transient). Materials imported from a
/// model are shown read-only.
@MainActor
public final class MaterialAssetEditor {
    public let session: EditorSession
    public let reference: AssetReference
    /// Whether edits are allowed (the material is a `.material` file).
    public let isEditable: Bool
    public let world = World()
    public let entity: Entity
    private var shownRevision = -1
    private var gestureStart: MaterialAsset?

    /// Nil when `reference` isn't a material.
    public init?(session: EditorSession, reference: AssetReference) {
        guard let assets = session.assets, let material = assets.material(reference) else { return nil }
        self.session = session
        self.reference = reference
        isEditable = session.isMaterialFile(reference.asset)
        entity = world.spawn(MaterialAssetComponent(material: material))
        shownRevision = assets.revision(of: reference.asset)
    }

    /// The material as the form shows it.
    public var material: MaterialAsset? { world.get(MaterialAssetComponent.self, for: entity)?.material }

    /// Re-reads the material when the database imported it again (an undo, an external edit).
    /// Call every frame; a gesture in progress is left alone.
    public func refresh() {
        guard gestureStart == nil, let assets = session.assets else { return }
        let revision = assets.revision(of: reference.asset)
        guard revision != shownRevision, let material = assets.material(reference) else { return }
        shownRevision = revision
        world.add(MaterialAssetComponent(material: material), to: entity)
    }

    /// Handles an edit from the grid: `.began` remembers the material, `.changed` writes the
    /// file live (unrecorded), `.ended` records one `MaterialEditCommand` for the whole gesture.
    public func handle(_ edit: PropertyEdit) {
        guard isEditable, let current = material else { return }
        switch edit.phase {
        case .began:
            gestureStart = current
        case .changed, .ended:
            let start = gestureStart ?? current
            do {
                try world.setField(edit.path, of: MaterialAssetComponent.componentName, for: entity, to: edit.newValue)
            } catch {
                session.log.error("Edit material \(edit.path) failed: \(error)")
            }
            guard let updated = material else { return }
            if edit.phase == .changed {
                if updated != current {
                    session.run(MaterialSetCommand.self, .init(asset: reference.asset, material: updated, transient: true))
                }
            } else {
                gestureStart = nil
                session.run(MaterialSetCommand.self, .init(asset: reference.asset, material: updated, previous: start,
                                                           label: "Edit Material \(edit.path)"))
            }
            shownRevision = session.assets?.revision(of: reference.asset) ?? shownRevision
        }
    }
}

/// The inspector's view of an `AssetItem`: name, path, importer and id, the import settings
/// form with Apply / Revert, the material form, and Extract Materials for models.
@MainActor
public final class AssetInspectorView {
    public let session: EditorSession
    public let view: VStack
    public private(set) var item: AssetItem?
    public private(set) var settingsEditor: AssetSettingsEditor?
    public private(set) var materialEditor: MaterialAssetEditor?
    public private(set) var settingsGrid: PropertyGrid?
    public private(set) var materialGrid: PropertyGrid?
    /// The `.proctex` parameter form (procedural texture files).
    public private(set) var proceduralEditor: ProceduralTextureEditor?
    public private(set) var proceduralGrid: PropertyGrid?

    private let title = Label("", role: .heading, name: "assetTitle")
    private let subtitle = Label("", role: .caption, name: "assetPath")
    private let idLabel = Label("", role: .caption, name: "assetID")
    private let content = VStack(spacing: 8, name: "assetContent")
    private let applyButton = Button("Apply", role: .primary, name: "applySettings")
    private let revertButton = Button("Revert", name: "revertSettings")
    private let proceduralApply = Button("Apply", role: .primary, name: "applyProceduralTexture")
    private let proceduralRevert = Button("Revert", name: "revertProceduralTexture")
    private var shownRevision = -1

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 6, name: "assetInspector")
        applyButton.tooltip = "Write the settings to the sidecar and reimport"
        revertButton.tooltip = "Discard the changes to the settings"
        applyButton.command = AssetApplySettingsCommand.id.rawValue
        revertButton.command = AssetApplySettingsCommand.id.rawValue
        applyButton.action = { [unowned self] in settingsEditor?.apply(); updateButtons() }
        revertButton.action = { [unowned self] in settingsEditor?.revert(); settingsGrid?.refresh(); updateButtons() }
        proceduralApply.tooltip = "Write the parameters to the .proctex file and reimport the texture"
        proceduralRevert.tooltip = "Discard the changes to the parameters"
        proceduralApply.command = AssetSetProceduralTextureCommand.id.rawValue
        proceduralRevert.command = AssetSetProceduralTextureCommand.id.rawValue
        proceduralApply.action = { [unowned self] in proceduralEditor?.apply(); proceduralGrid?.refresh(); updateButtons() }
        proceduralRevert.action = { [unowned self] in proceduralEditor?.revert(); proceduralGrid?.refresh(); updateButtons() }
        let scroll = ScrollView(content, name: "assetScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        content.padding = EdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        view.addChildren([title, subtitle, idLabel, Separator(), scroll])
    }

    /// Shows `item` (rebuilding the forms when it or its import changed); call every frame.
    public func show(_ item: AssetItem?) {
        let revision = item?.assetID.map { session.assets?.revision(of: $0) ?? 0 } ?? 0
        if item != self.item || (revision != shownRevision && materialEditor == nil && settingsEditor?.isModified != true
            && proceduralEditor?.isModified != true) {
            self.item = item
            shownRevision = revision
            rebuild()
        }
        materialEditor?.refresh()
        settingsGrid?.refresh()
        materialGrid?.refresh()
        proceduralGrid?.refresh()
        updateButtons()
    }

    private func updateButtons() {
        let modified = settingsEditor?.isModified ?? false
        if applyButton.isEnabled != modified { applyButton.isEnabled = modified }
        if revertButton.isEnabled != modified { revertButton.isEnabled = modified }
        let proceduralModified = proceduralEditor?.isModified ?? false
        if proceduralApply.isEnabled != proceduralModified { proceduralApply.isEnabled = proceduralModified }
        if proceduralRevert.isEnabled != proceduralModified { proceduralRevert.isEnabled = proceduralModified }
    }

    private func rebuild() {
        content.removeAllChildren()
        settingsEditor = nil
        materialEditor = nil
        settingsGrid = nil
        materialGrid = nil
        proceduralEditor = nil
        proceduralGrid = nil
        guard let item, let assets = session.assets else { return }
        switch item {
        case .folder(let path):
            title.text = path.isEmpty ? "Assets" : String(path.split(separator: "/").last ?? "")
            title.icon = EditorIcons.asset(.folder)
            subtitle.text = "Folder · Assets/\(path)"
            idLabel.text = ""
            return
        case .asset(let id):
            guard let record = assets.record(id) else { return missing() }
            title.text = record.fileName
            title.icon = EditorIcons.asset(EditorIcons.assetKind(forFile: record.path))
            subtitle.text = "Assets/\(record.path)" + (record.importer.map { " · \($0) importer" } ?? " · no importer")
            idLabel.text = "ID \(id.description)"
            if let error = record.importError { content.addChild(note("Import failed: \(error)")) }
            if let editor = AssetSettingsEditor(session: session, asset: id) {
                settingsEditor = editor
                let grid = makeGrid(world: editor.world, entity: editor.entity)
                grid.onFieldEdit = { [unowned self, unowned editor] edit in
                    guard edit.phase != .began else { return }
                    do { try editor.setField(edit.path, to: edit.newValue) } catch {
                        session.log.error("Import setting \(edit.path): \(error)")
                    }
                    updateButtons()
                }
                grid.command = AssetApplySettingsCommand.id.rawValue
                settingsGrid = grid
                content.addChildren([grid, HStack(spacing: 6, [Spacer(), revertButton, applyButton])])
            }
            if let editor = ProceduralTextureEditor(session: session, asset: id) {
                proceduralEditor = editor
                let grid = makeGrid(world: editor.world, entity: editor.entity)
                grid.stringChoices = { _, path in path == "generator" ? ProceduralTexture.Generator.allCases.map(\.rawValue) : nil }
                grid.onFieldEdit = { [unowned self, unowned editor] edit in
                    guard edit.phase != .began else { return }
                    do { try editor.setField(edit.path, to: edit.newValue) } catch {
                        session.log.error("Procedural texture \(edit.path): \(error)")
                    }
                    updateButtons()
                }
                grid.command = AssetSetProceduralTextureCommand.id.rawValue
                proceduralGrid = grid
                content.addChildren([grid, HStack(spacing: 6, [Spacer(), proceduralRevert, proceduralApply])])
            }
            if session.isMeshBuildFile(id) {
                let open = Button("Open in Mesh Builder", role: .primary, name: "openMeshBuilder") { [unowned self] in
                    session.run(MeshBuildOpenCommand.self, .init(asset: AssetReference(id)))
                }
                open.command = MeshBuildOpenCommand.id.rawValue
                open.tooltip = "Edit this model in the Mesh Builder tab (or double-click it in the Assets panel)"
                let parts = session.assets?.meshBuild(of: id)?.parts.count ?? 0
                content.addChildren([HStack(spacing: 6, [open, Spacer()]),
                                     note("A model built from \(parts) shape\(parts == 1 ? "" : "s"). The Mesh Builder shows it in a view of its own, with gizmos, the parts list and live animation.")])
            }
            if session.isTableFile(id) {
                let open = Button("Open in Data Table", role: .primary, name: "openDataTable") { [unowned self] in
                    session.run(TableOpenCommand.self, .init(asset: AssetReference(id)))
                }
                open.command = TableOpenCommand.id.rawValue
                open.tooltip = "Edit this table in the Data Table tab (or double-click it in the Assets panel)"
                let table = session.assets?.dataTableContents(of: id)
                content.addChildren([HStack(spacing: 6, [open, Spacer()]),
                                     note("A data table of \(table?.rows.count ?? 0) rows and \(table?.columns.count ?? 0) columns. Game code reads it with assets.dataTable(path:)?.row(id)?.number(column).")])
            }
            if session.isMaterialFile(id) {
                addMaterialForm(AssetReference(id, subAsset: "material"))
            }
            if record.importer == GLTFImporter().name, record.objects.contains(where: { $0.kind == .material }) {
                let extract = Button("Extract Materials", name: "extractMaterials") { [unowned self] in
                    session.run(AssetExtractMaterialsCommand.self, .init(asset: id))
                    shownRevision = -1
                }
                extract.command = AssetExtractMaterialsCommand.id.rawValue
                extract.tooltip = "Write the model's materials to .material files you can edit, and use them for this model"
                content.addChild(extract)
            }
            content.addChild(objectList(record))
        case .object(let reference):
            guard let record = assets.record(reference.asset),
                  let object = record.objects.first(where: { $0.id == reference.subAsset }) else { return missing() }
            title.text = object.name
            title.icon = EditorIcons.asset(EditorIcons.AssetIconKind(object.kind))
            subtitle.text = "\(object.kind.rawValue.capitalized) in Assets/\(record.path)"
            idLabel.text = reference.description
            if object.kind == .material { addMaterialForm(reference) }
            if object.kind == .texture, let texture = assets.texture(reference) {
                content.addChild(note("\(texture.width) × \(texture.height), \(texture.isSRGB ? "sRGB" : "linear")"
                    + (texture.generatesMipmaps ? ", mipmaps" : "")
                    + (texture.format.isCompressed ? ", \(texture.format), \(texture.gpuByteCount / 1024) KiB" : "")))
            }
            if object.kind == .mesh, let mesh = assets.mesh(reference) {
                content.addChild(note("\(mesh.vertices.count) vertices, \(mesh.indices.count / 3) triangles"))
            }
        }
    }

    private func addMaterialForm(_ reference: AssetReference) {
        guard let editor = MaterialAssetEditor(session: session, reference: reference) else { return }
        materialEditor = editor
        let grid = makeGrid(world: editor.world, entity: editor.entity)
        grid.stringChoices = { [unowned session] _, path in MaterialAssetComponent.choices(path: path, assets: session.assets) }
        grid.stringChoiceTitle = { [unowned session] _, _, value in
            if value.isEmpty { return "None" }
            guard let reference = AssetReference(value) else { return value }
            return session.assets?.displayName(of: reference) ?? value
        }
        grid.onFieldEdit = { [unowned editor] edit in editor.handle(edit) }
        grid.command = MaterialSetCommand.id.rawValue
        materialGrid = grid
        if !editor.isEditable {
            grid.isEnabled = false
            content.addChild(note("Imported with its model, so it is read-only. Extract Materials on the model makes editable copies."))
        }
        content.addChild(grid)
    }

    private func makeGrid(world: World, entity: Entity) -> PropertyGrid {
        let grid = PropertyGrid(world: world, name: "assetGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 104
        grid.entity = entity
        return grid
    }

    private func objectList(_ record: AssetRecord) -> Widget {
        guard !record.objects.isEmpty else { return Spacer(grow: 0) }
        let list = VStack(spacing: 2, name: "assetObjects")
        list.addChild(Label("Contents", role: .secondary))
        for object in record.objects {
            let label = Label("\(object.kind.rawValue) · \(object.name)", role: .caption)
            label.icon = EditorIcons.asset(EditorIcons.AssetIconKind(object.kind))
            list.addChild(label)
        }
        return list
    }

    private func note(_ text: String) -> Label {
        let label = Label(text, role: .caption, name: "assetNote")
        label.wraps = true
        return label
    }

    private func missing() {
        title.text = "Missing asset"
        title.icon = EditorIcons.named("circle-x")
        subtitle.text = ""
        idLabel.text = ""
    }
}
