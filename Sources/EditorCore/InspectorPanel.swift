import Engine
import Foundation

/// The inspector panel for the primary selected entity: a header with its name (editable,
/// `entity.rename`) and id, a reflection-driven `PropertyGrid` whose edits are recorded one undo
/// step per gesture (`InspectorEditRecorder`, `component.setField`), a remove button per component
/// (`component.remove`) and "Add Component" (`component.add` with the catalog's default value).
/// With several entities selected it shows the primary one only.
/// Dropdown options for asset-key fields in the inspector: `MeshRenderer.mesh` lists the
/// registered meshes and `MeshRenderer.material` the registered materials (with a project open,
/// its assets too, as `asset:` keys shown by `title`).
@MainActor
public struct AssetChoices {
    public var meshes: () -> [String]
    public var materials: () -> [String]
    /// What the dropdown shows for a key (the key itself by default).
    public var title: (String) -> String

    public init(meshes: @escaping () -> [String], materials: @escaping () -> [String],
                title: @escaping (String) -> String = { $0 }) {
        self.meshes = meshes
        self.materials = materials
        self.title = title
    }

    /// The registered keys, followed by every mesh / material of `assets` (titled by path and
    /// object name, e.g. "Models/rock.obj › Rock").
    public init(meshes: @escaping () -> [String], materials: @escaping () -> [String], assets: @escaping () -> AssetDatabase?) {
        self.init(
            meshes: { meshes() + Self.assetKeys(assets(), .mesh, excluding: meshes()) },
            materials: { materials() + Self.assetKeys(assets(), .material, excluding: materials()) },
            title: { key in
                guard let reference = AssetReference(key), let assets = assets() else { return key }
                return assets.displayName(of: reference)
            })
    }

    private static func assetKeys(_ assets: AssetDatabase?, _ kind: AssetKind, excluding registered: [String]) -> [String] {
        guard let assets else { return [] }
        let skip = Set(registered)
        return assets.references(of: kind).map(\.description).filter { !skip.contains($0) }
    }

    /// The options for a field, or nil when it isn't an asset key (it stays a text field).
    public func options(component: String, path: String) -> [String]? {
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
        didSet {
            grid.stringChoiceTitle = assetChoices.map { choices in { _, _, value in choices.title(value) } }
            grid.stringChoices = assetChoices.map { choices in { choices.options(component: $0, path: $1) } }
        }
    }

    private let nameField = TextField(placeholder: "Name", name: "entityName")
    private let idLabel = Label("", role: .caption, name: "entityID")
    private let subtitle = Label("", role: .caption, name: "selectionCount")
    private let emptyLabel = Label("Nothing selected", role: .secondary, name: "empty")
    private let addButton: Button
    private let separator = Separator()
    private let scroll: ScrollView
    private var shownEntity: Entity?
    private var shownID: EntityID?

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
        grid.componentFilter = { $0 != Name.componentName }
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

        nameField.style.grow = 1
        nameField.style.width = 0
        nameField.onSubmit = { [unowned self] text in commitName(text) }
        nameField.onEndEditing = { [unowned self] text in commitName(text) }
        addButton.action = { [unowned self] in showAddMenu() }

        let header = HStack(spacing: 6, [nameField])
        assetView.view.style.grow = 1
        assetView.view.style.shrink = 1
        view.addChildren([header, idLabel, subtitle, separator, scroll, addButton, emptyLabel, assetView.view])
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
            for widget in [nameField, idLabel, subtitle, scroll, addButton, emptyLabel] as [Widget] where !widget.isHidden {
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
            grid.entity = entity
        }
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
        menu.onSelect = { [unowned self] index in session.run(ComponentAddCommand.self, .init(entity: id, component: names[index])) }
        context.presentOverlay(menu)
    }
}
