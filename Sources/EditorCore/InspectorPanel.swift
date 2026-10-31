import Engine
import Foundation

/// The inspector panel for the primary selected entity: a header with its name (editable,
/// `entity.rename`) and id, a reflection-driven `PropertyGrid` whose edits are recorded one undo
/// step per gesture (`InspectorEditRecorder`, `component.setField`), a remove button per component
/// (`component.remove`) and "Add Component" (`component.add` with the catalog's default value).
/// `EntityRef` fields are dropdowns of the scene's entities (None first). For an entity of a
/// prefab instance, a prefab section names the prefab (Select shows it in the asset browser)
/// and lists the overridden components with their fields, each with Revert and Apply
/// (`prefab.revert` / `prefab.apply`); on the instance's root also Apply All, Revert All and
/// Unpack. With several entities selected it shows the primary one only.
/// Dropdown options for asset-key fields in the inspector: `MeshRenderer.mesh` lists the
/// registered meshes, `MeshRenderer.material` the registered materials and every `TextureHandle`
/// field (`SceneEnvironment.environmentMap`, found by reflection) "None" and the textures (with
/// a project open, its assets too, as `asset:` keys shown by `title`).
@MainActor
public struct AssetChoices {
    public var meshes: () -> [String]
    public var materials: () -> [String]
    public var textures: () -> [String]
    /// What the dropdown shows for a key (the key itself by default; "" is "None").
    public var title: (String) -> String

    public init(meshes: @escaping () -> [String], materials: @escaping () -> [String], textures: @escaping () -> [String] = { [] },
                title: @escaping (String) -> String = { $0 }) {
        self.meshes = meshes
        self.materials = materials
        self.textures = textures
        self.title = title
    }

    /// The registered keys, followed by every mesh / material / texture of `assets` (titled by
    /// path and object name, e.g. "Models/rock.obj › Rock").
    public init(meshes: @escaping () -> [String], materials: @escaping () -> [String], textures: @escaping () -> [String] = { [] },
                assets: @escaping () -> AssetDatabase?) {
        self.init(
            meshes: { meshes() + Self.assetKeys(assets(), .mesh, excluding: meshes()) },
            materials: { materials() + Self.assetKeys(assets(), .material, excluding: materials()) },
            textures: { textures() + Self.assetKeys(assets(), .texture, excluding: textures()) },
            title: { key in
                guard let reference = AssetReference(key), let assets = assets() else { return key }
                return assets.displayName(of: reference)
            })
    }

    /// Paths of `component`'s `TextureHandle` fields (optional or not), from the catalog's
    /// default value by reflection; cached per component.
    static func textureFields(of component: String) -> Set<String> {
        if let cached = textureFieldCache[component] { return cached }
        var paths = Set<String>()
        func scan(_ value: Any, prefix: String) {
            for child in Mirror(reflecting: value).children {
                guard let label = child.label else { continue }
                let type = Swift.type(of: child.value)
                if type == TextureHandle.self || type == TextureHandle?.self {
                    paths.insert(prefix + label)
                } else if Mirror(reflecting: child.value).displayStyle == .struct {
                    scan(child.value, prefix: prefix + label + ".")
                }
            }
        }
        if let value = EditorComponentCatalog.makeDefault(named: component) { scan(value, prefix: "") }
        textureFieldCache[component] = paths
        return paths
    }

    private static var textureFieldCache: [String: Set<String>] = [:]

    /// Forgets what was learned about component types (game code was reloaded).
    static func resetCaches() { textureFieldCache = [:] }

    /// Whether `path` of `component` is a `TextureHandle` (its dropdown starts with "None").
    public static func isTextureField(component: String, path: String) -> Bool {
        textureFields(of: component).contains(path)
    }

    private static func assetKeys(_ assets: AssetDatabase?, _ kind: AssetKind, excluding registered: [String]) -> [String] {
        guard let assets else { return [] }
        let skip = Set(registered)
        return assets.references(of: kind).map(\.description).filter { !skip.contains($0) }
    }

    /// The options for a field, or nil when it isn't an asset key (it stays a text field).
    public func options(component: String, path: String) -> [String]? {
        if Self.isTextureField(component: component, path: path) { return [""] + textures() }
        guard component == MeshRenderer.componentName else { return nil }
        switch path {
        case "mesh": return meshes()
        case "material": return materials()
        default: return nil
        }
    }
}

@MainActor
public final class InspectorPanel {
    public let session: EditorSession
    public let grid: PropertyGrid
    public let recorder: InspectorEditRecorder
    public let view: VStack
    /// Shown instead of the entity while `session.inspectedAsset` is set.
    public let assetView: AssetInspectorView
    /// Turns asset-key fields into dropdowns of the registered keys (see `AssetChoices`).
    public var assetChoices: AssetChoices? {
        didSet { installChoices() }
    }
    /// The prefab section (see the type's notes), above the components.
    public let prefabView = VStack(spacing: 4, name: "prefabSection")

    private let nameField = TextField(placeholder: "Name", name: "entityName")
    private let idLabel = Label("", role: .caption, name: "entityID")
    private let subtitle = Label("", role: .caption, name: "selectionCount")
    private let emptyLabel = Label("Nothing selected", role: .secondary, name: "empty")
    private let addButton: Button
    private let separator = Separator()
    private let scroll: ScrollView
    private var shownEntity: Entity?
    private var shownID: EntityID?
    /// The shown entity has `EntityRef` fields, whose options follow the scene's entities.
    private var showsEntityRefs = false
    private var shownEntityCount = -1
    private var prefabKey: [Int] = []
    private var shownPrefab: PrefabEntityInfo?

    public init(session: EditorSession) {
        self.session = session
        grid = PropertyGrid(world: session.world)
        recorder = InspectorEditRecorder(session: session)
        assetView = AssetInspectorView(session: session)
        view = VStack(spacing: 6, padding: EdgeInsets(8), name: "inspectorPanel")
        addButton = Button("Add Component", name: "addComponent")
        addButton.tooltip = "Add a component to the selected entity"
        scroll = ScrollView(grid, name: "inspectorScroll")

        grid.appliesEditsToWorld = false
        grid.componentFilter = { $0 != Name.componentName && $0 != PrefabInstance.componentName }
        grid.labelWidth = 104
        grid.padding = EdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        grid.entityName = { [unowned session] entity in session.displayName(of: entity) }
        grid.onFieldEdit = { [unowned self] edit in recorder.handle(edit) }
        grid.onRemoveComponent = { [unowned self] entity, name in
            guard let id = session.world.id(of: entity) else { return }
            session.run(ComponentRemoveCommand.self, .init(entity: id, component: name))
        }
        scroll.style.grow = 1
        scroll.style.shrink = 1
        nameField.command = EntityRenameCommand.id.rawValue
        addButton.command = ComponentAddCommand.id.rawValue
        grid.command = ComponentSetFieldCommand.id.rawValue
        grid.itemCommands = ["remove": ComponentRemoveCommand.id.rawValue]

        nameField.style.grow = 1
        nameField.style.width = 0
        nameField.onSubmit = { [unowned self] text in commitName(text) }
        nameField.onEndEditing = { [unowned self] text in commitName(text) }
        addButton.action = { [unowned self] in showAddMenu() }

        let header = HStack(spacing: 6, [nameField])
        assetView.view.style.grow = 1
        assetView.view.style.shrink = 1
        prefabView.isHidden = true
        view.addChildren([header, idLabel, subtitle, prefabView, separator, scroll, addButton, emptyLabel, assetView.view])
        installChoices()
        refresh()
    }

    /// Re-reads the selection and the entity; call every frame after the UI processed input.
    public func refresh() {
        let world = session.world
        let asset = session.inspectedAsset
        if assetView.view.isHidden != (asset == nil) { assetView.view.isHidden = asset == nil }
        if separator.isHidden != (asset != nil) { separator.isHidden = asset != nil }
        assetView.show(asset)
        let entity = asset == nil ? session.selection.primaryEntity(in: world) : nil
        if asset != nil {
            for widget in [nameField, idLabel, subtitle, scroll, addButton, emptyLabel, prefabView] as [Widget] where !widget.isHidden {
                widget.isHidden = true
            }
            if shownEntity != nil {
                recorder.finishGesture()
                shownEntity = nil
                shownID = nil
                grid.entity = nil
            }
            return
        }
        if entity != shownEntity || entity.flatMap({ world.id(of: $0) }) != shownID {
            // A gesture can't continue on another entity (or after its entity went away).
            recorder.finishGesture()
            shownEntity = entity
            shownID = entity.flatMap { world.id(of: $0) }
            showsEntityRefs = entity.map { e in world.components(of: e).contains { Self.hasEntityRefs($0.fields()) } } ?? false
            grid.entity = entity
        }
        // New or deleted entities change the options of `EntityRef` dropdowns.
        if showsEntityRefs, world.entityCount != shownEntityCount, recorder.openGesture == nil {
            shownEntityCount = world.entityCount
            installChoices()
        }
        refreshPrefab()
        let hasEntity = entity != nil
        for widget in [nameField, idLabel, subtitle, scroll, addButton] as [Widget] where widget.isHidden == hasEntity {
            widget.isHidden = !hasEntity
        }
        emptyLabel.isHidden = hasEntity
        guard let entity else { return }
        if !nameField.isFocused {
            let name = world.get(Name.self, for: entity)?.value ?? ""
            if nameField.text != name { nameField.text = name }
        }
        let id = shownID.map { "ID \($0.description)" } ?? ""
        if idLabel.text != id {
            idLabel.text = id
            idLabel.tooltip = shownID.map { "Entity ID \($0.description)" }
        }
        let count = session.selection.entities(in: world).count
        let caption = count > 1 ? "\(count) entities selected; showing the primary one" : ""
        if subtitle.text != caption { subtitle.text = caption }
        subtitle.isHidden = caption.isEmpty
        grid.refresh()
    }

    // MARK: Entity references and asset keys

    private static func hasEntityRefs(_ fields: [FieldDescriptor]) -> Bool {
        fields.contains { $0.isEntityReference || hasEntityRefs($0.children) }
    }

    /// Whether `path` of the shown entity's `component` is an `EntityRef`.
    private func isEntityRef(_ component: String, _ path: String) -> Bool {
        guard showsEntityRefs, let entity = shownEntity else { return false }
        return session.world.component(named: component, of: entity)?.field(at: path)?.isEntityReference == true
    }

    /// Dropdowns for `EntityRef` fields (None, then every entity in hierarchy order, by name) and
    /// asset keys (`assetChoices`).
    private func installChoices() {
        let choices = assetChoices
        grid.stringChoiceTitle = { [unowned self] component, path, value in
            if value.isEmpty { return "None" }
            if isEntityRef(component, path), let id = EntityID(value) {
                return session.world.entity(for: id).map { session.displayName(of: $0) } ?? "Missing (\(value.prefix(8)))"
            }
            return choices?.title(value) ?? value
        }
        grid.stringChoices = { [unowned self] component, path in
            if isEntityRef(component, path) {
                let world = session.world
                return [""] + world.roots.flatMap { world.subtreeOrder($0) }.compactMap { world.ensureID(of: $0)?.description }
            }
            return choices?.options(component: component, path: path)
        }
    }

    // MARK: Prefab section

    /// Rebuilds the prefab section when the entity, the undo history or the assets changed.
    private func refreshPrefab() {
        let id = shownID
        let key = [id?.hashValue ?? 0, session.undo.changeCount, session.assets?.revision ?? -1, session.isPlaying ? 1 : 0,
                   session.world.entityCount]
        guard key != prefabKey else { return }
        prefabKey = key
        let info = session.isPlaying ? nil : id.flatMap { session.prefabInfo(of: $0) }
        guard info != shownPrefab || prefabView.children.isEmpty != (info == nil) else { return }
        shownPrefab = info
        prefabView.removeAllChildren()
        prefabView.isHidden = info == nil
        guard let info, let id, let assets = session.assets else { return }

        let title = Label("Prefab: " + assets.displayName(of: info.link.prefab), role: .caption, name: "prefabName")
        title.style.grow = 1
        title.style.shrink = 1
        title.style.width = 0
        title.tooltip = info.link.local == nil ? "Added to this instance of the prefab" : "Part of an instance of this prefab"
        let select = Button("Select", name: "prefabSelect") { [unowned session] in
            session.run(AssetSelectCommand.self, .init(asset: info.link.prefab))
        }
        select.tooltip = "Select the prefab asset in the Assets panel"
        select.command = AssetSelectCommand.id.rawValue
        prefabView.addChild(HStack(spacing: 6, [title, select]))

        if info.isRoot {
            let rootID = info.root
            var parts = ["\(info.overrides.count) override\(info.overrides.count == 1 ? "" : "s")"]
            if info.addedEntities > 0 { parts.append("\(info.addedEntities) added") }
            let summary = Label(parts.joined(separator: ", "), role: .caption, name: "prefabSummary")
            summary.style.grow = 1
            let apply = Button("Apply All", name: "prefabApplyAll") { [unowned session] in
                session.run(PrefabApplyCommand.self, .init(entity: rootID))
            }
            apply.isEnabled = info.canApply && (!info.overrides.isEmpty || info.addedEntities > 0)
            apply.tooltip = info.canApply ? "Write this instance's changes into the prefab" : "A model's prefab can't be changed"
            let revert = Button("Revert All", name: "prefabRevertAll") { [unowned session] in
                session.run(PrefabRevertCommand.self, .init(entity: rootID))
            }
            revert.isEnabled = !info.overrides.isEmpty || info.addedEntities > 0
            revert.tooltip = "Remove every override and added entity"
            let unpack = Button("Unpack", name: "prefabUnpack") { [unowned session] in
                session.run(PrefabUnpackCommand.self, .init(entity: rootID))
            }
            unpack.tooltip = "Unlink this instance from the prefab"
            apply.command = PrefabApplyCommand.id.rawValue
            revert.command = PrefabRevertCommand.id.rawValue
            unpack.command = PrefabUnpackCommand.id.rawValue
            prefabView.addChild(HStack(spacing: 6, [summary, apply, revert, unpack]))
        }
        for (component, fields) in info.overriddenComponents {
            let label = Label("\(component): \(fields.joined(separator: ", "))", role: .secondary, name: "override.\(component)")
            label.style.grow = 1
            label.style.shrink = 1
            label.style.width = 0
            label.tooltip = "Overridden: \(component) " + fields.joined(separator: ", ")
            let revert = Button("Revert", name: "revert.\(component)") { [unowned session] in
                session.run(PrefabRevertCommand.self, .init(entity: id, component: component))
            }
            revert.tooltip = "Put \(component) back to the prefab's"
            let apply = Button("Apply", name: "apply.\(component)") { [unowned session] in
                session.run(PrefabApplyCommand.self, .init(entity: id, component: component))
            }
            apply.isEnabled = info.canApply
            apply.tooltip = info.canApply ? "Write \(component) into the prefab" : "A model's prefab can't be changed"
            apply.command = PrefabApplyCommand.id.rawValue
            revert.command = PrefabRevertCommand.id.rawValue
            prefabView.addChild(HStack(spacing: 6, [label, revert, apply]))
        }
    }

    private func commitName(_ text: String) {
        guard let id = shownID, session.world.entity(for: id) != nil else { return }
        let name = text.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        session.run(EntityRenameCommand.self, .init(entity: id, name: name))
    }

    private func showAddMenu() {
        guard let context = view.context, let entity = shownEntity, let id = shownID else { return }
        let names = EditorComponentCatalog.addableNames(for: entity, in: session.world)
        guard !names.isEmpty else {
            session.log.info("Every addable component is already on this entity")
            return
        }
        let menu = PopupMenu(items: names, anchor: addButton)
        menu.command = ComponentAddCommand.id.rawValue
        menu.onSelect = { [unowned self] index in session.run(ComponentAddCommand.self, .init(entity: id, component: names[index])) }
        context.presentOverlay(menu)
    }
}
