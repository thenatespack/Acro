import Engine
import Foundation

// The Material section under an object's components in the Inspector: the material of its
// MeshRenderer, viewed and edited without leaving the object.
//
//   ▾ Material                 [■ Brick                    … ]   ← header: fold, the material (opens the picker)
//     ┌──────┐ Brick
//     │ ◯◯◯◯ │ Materials/Brick.material
//     └──────┘ [Open in Material Builder] [Select]
//     Base Color   ■ ...                                         ← the material's settings
//
// The material field opens the asset picker (AssetPickerDialog.swift), which sets `MeshRenderer.material` (`component.setField`); the settings edit the
// material file itself (`material.set`, one undo step per gesture), so every object using it
// changes. A material imported with a model, or a built-in one, is shown read-only with Make
// Editable Copy / New Material, which writes a .material file (`asset.newMaterial`) and points
// the renderer at it, as one undo step.

/// Draws a texture (a material's thumbnail) in its frame, or an empty swatch without one.
final class TextureView: Widget {
    var texture: GPUTexture? { didSet { if texture !== oldValue { setNeedsDisplay() } } }
    let size: Float

    init(size: Float, name: String) {
        self.size = size
        super.init(name: name)
        isHitTestable = false
    }

    override func measureContent(width: Float?) -> Vec2 { Vec2(size, size) }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        let radii = UICornerRadii(min(theme.smallCornerRadius, size / 4))
        list.fillRect(frame, color: theme.fieldBackground, radii: radii)
        if let texture { list.drawImage(texture, in: frame) }
        list.strokeRect(frame, color: theme.controlBorder, width: theme.borderWidth, radii: radii)
    }
}

/// The section's header row: clicking it (outside the picker) folds the section.
final class MaterialSectionHeader: Stack {
    var onToggle: (() -> Void)?
    var isCollapsed = false { didSet { if isCollapsed != oldValue { setNeedsDisplay() } } }

    init(_ children: [Widget]) {
        super.init(.horizontal, spacing: 6, alignment: .center, padding: EdgeInsets(top: 3, left: 22, bottom: 3, right: 4),
                   name: "materialHeader", children: children)
    }

    override var accessibilityRole: UIAccessibilityRole { .header }
    override var accessibilityText: String? { "Material" }
    override var accessibilityValue: String? { isCollapsed ? "collapsed" : "expanded" }

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            return true
        case .pointerUp(let e):
            if frame.contains(e.position) { onToggle?() }
            return true
        default:
            return false
        }
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: isHovered ? theme.controlHover : theme.controlBackground, radii: UICornerRadii(theme.smallCornerRadius))
        let c = Vec2(frame.x + 12, frame.center.y)
        let s: Float = 3.5
        let arrow = theme.secondaryTextColor
        if isCollapsed {
            list.drawLine(from: c + Vec2(-s / 2, -s), to: c + Vec2(s / 2, 0), width: theme.iconStrokeWidth, color: arrow, cap: .round)
            list.drawLine(from: c + Vec2(s / 2, 0), to: c + Vec2(-s / 2, s), width: theme.iconStrokeWidth, color: arrow, cap: .round)
        } else {
            list.drawLine(from: c + Vec2(-s, -s / 2), to: c + Vec2(0, s / 2), width: theme.iconStrokeWidth, color: arrow, cap: .round)
            list.drawLine(from: c + Vec2(0, s / 2), to: c + Vec2(s, -s / 2), width: theme.iconStrokeWidth, color: arrow, cap: .round)
        }
    }
}

@MainActor
public final class InspectorMaterialSection {
    public let session: EditorSession
    public let view = VStack(spacing: 6, name: "materialSection")
    /// A material asset's thumbnail (nil without a GPU, or while it renders).
    var preview: ((AssetReference) -> GPUTexture?)?
    /// The picker's options (material keys) and their titles (`AssetChoices`).
    var choices: AssetChoices?
    /// Whether the section is open; kept across selections.
    public private(set) var isExpanded = true
    /// The editor of the material shown (nil for a built-in material).
    public private(set) var editor: MaterialAssetEditor?
    /// The material's name (and preview) in the header; a click opens the asset picker.
    public private(set) var picker: PickerField?
    private var form: PropertyGrid?
    private var largePreview: TextureView?
    /// What the section was built for: the entity, its material key, the assets' revision and the fold.
    private var shownKey: (id: EntityID, material: String, assets: Int, expanded: Bool)?
    private var options: [String] = []

    init(session: EditorSession) {
        self.session = session
        view.isHidden = true
    }

    /// The material key `entity` renders with (nil without a MeshRenderer).
    private func materialKey(of entity: Entity) -> String? {
        session.world.get(MeshRenderer.self, for: entity)?.material.key
    }

    /// Shows the material of `entity`'s MeshRenderer (hidden without one). Call every frame.
    func refresh(entity: Entity?, id: EntityID?) {
        guard let entity, let id, let key = materialKey(of: entity) else {
            if !view.isHidden { clear() }
            return
        }
        let wanted = (id, key, session.assets?.revision ?? -1, isExpanded)
        if shownKey.map({ $0.id != wanted.0 || $0.material != wanted.1 || $0.expanded != wanted.3 }) ?? true {
            build(id: id, key: key)
        } else if shownKey?.assets != wanted.2 {
            // New, renamed or deleted materials change the picker (the form stays: edits bump the revision too).
            updatePicker(key: key)
        }
        shownKey = wanted
        editor?.refresh()
        form?.refresh()
        let reference = AssetReference(key)
        let texture = reference.flatMap { preview?($0) }
        picker?.preview = texture
        largePreview?.texture = texture
    }

    private func pickerOptions(key: String) -> [String] {
        var options = choices?.options(component: MeshRenderer.componentName, path: "material") ?? [key]
        if !options.contains(key) { options.insert(key, at: 0) }
        return options
    }

    /// Material names can change (a rename): the header follows.
    private func updatePicker(key: String) {
        options = pickerOptions(key: key)
        let title = key.isEmpty ? "None" : choices?.title(key) ?? key
        picker?.title = title
    }

    private func clear() {
        view.removeAllChildren()
        view.isHidden = true
        editor = nil
        form = nil
        picker = nil
        largePreview = nil
        shownKey = nil
    }

    func toggle() {
        isExpanded.toggle()
    }

    private func build(id: EntityID, key: String) {
        view.removeAllChildren()
        view.isHidden = false
        let assets = session.assets
        let reference = AssetReference(key)
        options = pickerOptions(key: key)
        let title = { [choices] (value: String) in choices?.title(value) ?? value }

        // Header: fold, "Material", the material's preview and name, which opens the picker.
        let label = Label("Material", name: "materialSectionTitle")
        let picker = PickerField(title: title(key), name: "materialPicker") { [unowned self] in
            pickMaterial(current: key, for: id)
        }
        picker.tooltip = "The material this object's MeshRenderer draws with: click to choose another"
        picker.command = ComponentSetFieldCommand.id.rawValue
        picker.style.grow = 1
        picker.style.shrink = 1
        picker.style.width = 0
        self.picker = picker
        let header = MaterialSectionHeader([label, picker])
        header.isCollapsed = !isExpanded
        header.onToggle = { [unowned self] in toggle() }
        // Folding shows or hides the material's settings, which material.get reads.
        header.command = MaterialGetCommand.id.rawValue
        header.tooltip = isExpanded ? "Hide the material's settings" : "Show the material's settings"
        view.addChild(header)
        editor = nil
        form = nil
        largePreview = nil
        guard isExpanded else { return }

        // Preview, name, where it comes from, and what can be done with it.
        let editor = reference.flatMap { MaterialAssetEditor(session: session, reference: $0) }
        self.editor = editor
        let large = TextureView(size: 72, name: "materialPreview")
        largePreview = large
        let name = Label(title(key), role: .heading, name: "materialName")
        let caption: String
        if let reference, let assets, assets.record(reference.asset) != nil {
            let path = assets.record(reference.asset)?.path ?? ""
            caption = editor?.isEditable == true ? path : "Imported with \(path) (read-only)"
        } else {
            caption = "Built-in material (read-only)"
        }
        let where_ = Label(caption, role: .caption, name: "materialSource")
        // The info column stretches them to its width; longer text is cut with an ellipsis.
        for label in [name, where_] { label.style.shrink = 1 }
        name.tooltip = title(key)
        where_.tooltip = caption
        var buttons: [Widget] = []
        if let editor, editor.isEditable, let reference {
            if let module = EditorBuilderRegistry.module(forFile: reference.asset, in: session), let asset = module.asset {
                let open = Button("Open in \(module.title)", name: "materialOpenBuilder") { [unowned session] in
                    asset.open(session, reference.asset)
                }
                open.command = asset.openCommand?.rawValue
                buttons.append(open)
            }
        } else {
            let copy = Button(editor == nil ? "New Material" : "Make Editable Copy", name: "materialMakeCopy") { [unowned self] in
                makeEditableCopy(of: key, for: id)
            }
            copy.tooltip = editor == nil ? "Make a .material file and use it on this object"
                : "Copy this material into a .material file you can edit, and use it on this object"
            copy.command = AssetNewMaterialCommand.id.rawValue
            copy.isEnabled = session.commands.isAvailable(AssetNewMaterialCommand.id)
            buttons.append(copy)
        }
        if let reference, assets?.record(reference.asset) != nil {
            let select = Button("Select", name: "materialSelect") { [unowned session] in
                session.run(AssetSelectCommand.self, .init(asset: reference))
            }
            select.tooltip = "Show the material in the Assets panel"
            select.command = AssetSelectCommand.id.rawValue
            buttons.append(select)
        }
        let actions = HStack(spacing: 6, buttons)
        actions.wraps = true
        let info = VStack(spacing: 4, [name, where_, actions])
        info.style.grow = 1
        info.style.shrink = 1
        info.style.width = 0
        view.addChild(HStack(spacing: 10, alignment: .start, padding: EdgeInsets(top: 2, left: 4, bottom: 0, right: 4),
                             name: "materialSummary", [large, info]))
        if let editor {
            let form = editor.makeForm(name: "materialForm", labelWidth: 120)
            form.padding = EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.form = form
            view.addChild(form)
        }
    }

    /// Opens the asset picker on the materials; the one picked goes on the object.
    func pickMaterial(current: String, for id: EntityID) {
        let choices = choices
        session.showAssetPicker(.material, keys: options, current: current, title: { choices?.title($0) ?? $0 },
                                preview: { [unowned self] value in AssetReference(value).flatMap { preview?($0) } },
                                in: view.context) { [unowned self] value in
            if value != current { assign(value, to: id) }
        }
    }

    /// Points the shown object's MeshRenderer at material `key` (one undo step).
    private func assign(_ key: String, to id: EntityID) {
        session.run(ComponentSetFieldCommand.self, .init(entity: id, component: MeshRenderer.componentName, path: "material",
                                                         value: .string(key)))
    }

    /// Writes a .material file from `key`'s material (or the defaults for a built-in one) next
    /// to the model or in Materials/, and points the object at it: one undo step.
    private func makeEditableCopy(of key: String, for id: EntityID) {
        let assets = session.assets
        let reference = AssetReference(key)
        let source = reference.flatMap { assets?.materialFile(of: $0.asset) ?? assets?.material($0) }
        let base = reference.flatMap { assets?.displayName(of: $0) } ?? "Material"
        session.run(EditBeginBatchCommand.self, .init(label: "Make Editable Material"))
        defer { session.run(EditEndBatchCommand.self, .init()) }
        guard let created = session.run(AssetNewMaterialCommand.self, .init(name: base, material: source ?? MaterialAsset())) else { return }
        // As the picker lists it (a .material file's material sub-asset).
        let copy = session.assets?.references(of: .material).first { $0.asset == created.asset } ?? AssetReference(created.asset)
        assign(copy.description, to: id)
    }
}
