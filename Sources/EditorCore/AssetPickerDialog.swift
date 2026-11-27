import Engine
import Foundation

// The asset picker: a modal over the editor to choose a mesh or a material for a field (the
// Inspector's Mesh and Material fields, the Material section's picker). A search field over the
// choices, each with its preview, name and where it comes from ("Built-in", the file's path);
// the current one is selected. Type to filter, Up / Down to move, Enter, a double-click or Select
// to pick, Esc, Cancel or a click outside to close.

/// One choice in the picker.
struct AssetPickerOption: Equatable {
    /// What the field is set to (a registered key, an `asset:` reference, "" for none).
    var value: String
    var title: String
    var caption: String

    static func == (a: Self, b: Self) -> Bool { a.value == b.value }
}

@MainActor
public final class AssetPickerDialog: Widget {
    public let field: TextField
    public let list: AssetPickerList
    public let selectButton: Button
    public let cancelButton: Button
    private let card: VStack
    private let options: [AssetPickerOption]
    private(set) var shown: [AssetPickerOption] = []
    /// Called with the value picked (the dialog has closed by then).
    var onPick: ((String) -> Void)?
    private var closed = false

    init(title: String, options: [AssetPickerOption], current: String, preview: @escaping (String) -> GPUTexture?, command: CommandID) {
        self.options = options
        field = TextField(text: "", placeholder: "Search", name: "assetPickerField")
        list = AssetPickerList(name: "assetPickerList")
        list.preview = preview
        selectButton = Button("Select", role: .primary, name: "assetPickerSelect")
        cancelButton = Button("Cancel", name: "assetPickerCancel")
        let heading = Label(title, role: .heading, name: "assetPickerTitle")
        let buttons = HStack(spacing: 8, name: "assetPickerButtons", [Spacer(), cancelButton, selectButton])
        card = VStack(spacing: 8, padding: EdgeInsets(14), name: "assetPickerCard", [heading, field, list, buttons])
        super.init(name: "assetPickerDialog")
        card.background = .clear  // drawn by `draw`
        addChild(card)
        for widget in [field, list, selectButton] as [Widget] { widget.command = command.rawValue }
        list.itemCommands = ["row": command.rawValue]
        cancelButton.command = command.rawValue
        list.preferredVisibleRows = 8
        field.onChange = { [unowned self] text in filter(text) }
        field.onSubmit = { [unowned self] _ in pickSelected() }
        field.onKey = { [unowned self] key in
            switch key.key {
            case .up: moveSelection(by: -1)
            case .down: moveSelection(by: 1)
            case .pageUp: moveSelection(by: -list.preferredVisibleRows)
            case .pageDown: moveSelection(by: list.preferredVisibleRows)
            default: return false
            }
            return true
        }
        list.onPick = { [unowned self] row in pick(row) }
        selectButton.action = { [unowned self] in pickSelected() }
        cancelButton.action = { [unowned self] in close() }
        filter("")
        if let row = shown.firstIndex(where: { $0.value == current }) { list.selectRow(row) }
    }

    public override var accessibilityRole: UIAccessibilityRole { .dialog }
    public override var accessibilityText: String? { (card.children.first as? Label)?.text }

    /// Shows it over everything in `context` with the search field focused.
    public func present(in context: UIContext) {
        context.presentOverlay(self)
        context.focus(field)
    }

    /// Shows the choices whose name or source contains `text` (all of them for no text).
    public func filter(_ text: String) {
        let query = text.trimmingCharacters(in: .whitespaces).lowercased()
        let selected = list.selectedRow.flatMap { shown.indices.contains($0) ? shown[$0].value : nil }
        shown = query.isEmpty ? options : options.filter {
            $0.title.lowercased().contains(query) || $0.caption.lowercased().contains(query) || $0.value.lowercased().contains(query)
        }
        list.items = shown
        list.selectRow(shown.firstIndex { $0.value == selected } ?? (shown.isEmpty ? nil : 0))
        selectButton.isEnabled = !shown.isEmpty
    }

    private func moveSelection(by delta: Int) {
        guard !shown.isEmpty else { return }
        list.selectRow(min(max((list.selectedRow ?? -1) + delta, 0), shown.count - 1))
    }

    /// Picks the selected choice (Enter, Select).
    public func pickSelected() {
        guard let row = list.selectedRow ?? (shown.isEmpty ? nil : 0) else { return }
        pick(row)
    }

    private func pick(_ row: Int) {
        guard shown.indices.contains(row) else { return }
        let value = shown[row].value
        close()
        onPick?(value)
    }

    public func close() {
        guard !closed else { return }
        closed = true
        context?.dismissOverlay(self)
    }

    public override func overlayDismissed() { closed = true }

    public override func overlayFrame(in viewport: UIRect) -> UIRect { viewport }

    public override func layoutChildren() {
        let theme = theme
        let width = min(theme.dialogMaxWidth + 80, max(frame.width - 32, 160))
        let height = card.measure(width: width).y
        card.layout(in: UIRect(x: (frame.x + (frame.width - width) / 2).rounded(), y: (frame.y + max((frame.height - height) / 2.4, 16)).rounded(),
                               width: width, height: min(height, frame.height - 32)))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e):
            // A click outside the card closes it; inside, nothing behind it reacts.
            if !card.frame.contains(e.position) { close() }
            return true
        case .pointerUp, .pointerMove, .pointerDrag, .scroll:
            return true
        case .key(let e) where e.key == .escape:
            close()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim)
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2), radii: UICornerRadii(theme.dialogCornerRadius + 6))
        list.fillRect(card.frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }
}

/// The picker's choices: a preview, the name and, under it, where it comes from. A click
/// selects, a double-click picks.
@MainActor
public final class AssetPickerList: RowListView {
    var items: [AssetPickerOption] = [] { didSet { setNeedsLayout() } }
    var preview: ((String) -> GPUTexture?)?
    var onPick: ((Int) -> Void)?

    override init(name: String) {
        super.init(name: name)
        rowHeight = 40
    }

    public override var rowCount: Int { items.count }
    public override func rowAccessibilityLabel(_ row: Int) -> String? { items[row].title }
    public override func rowAccessibilityValue(_ row: Int) -> String? { items[row].caption }
    public override func rowActivated(_ row: Int) { onPick?(row) }

    public override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let item = items[row]
        let edge = rect.height - 8
        let box = UIRect(x: rect.x + 6, y: rect.y + 4, width: edge, height: edge)
        list.fillRect(box, color: theme.fieldBackground.mixed(with: theme.controlBackground, 0.5), radii: UICornerRadii(3))
        if let texture = preview?(item.value) { list.drawImage(texture, in: box) }
        let x = box.maxX + 8, width = rect.maxX - x - 8
        guard width > 4 else { return }
        func line(_ text: String, size: Float, y: Float, color: UIColor) {
            var layout = context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)
            if layout.width > width + 1 / scale, let short = TextEllipsis.fit(text, font: theme.font, size: size, width: width) {
                layout = context?.textLayout(short, size: size) ?? TextLayout(short, font: theme.font, size: size)
            }
            list.drawText(layout, font: theme.font, at: Vec2(snap(x), snap(y)), color: color)
        }
        line(item.title, size: theme.fontSize, y: rect.y + 4, color: theme.textColor)
        line(item.caption, size: theme.smallFontSize, y: rect.y + rect.height / 2 + 1, color: theme.secondaryTextColor)
    }
}

extension AssetChoices {
    /// The kind of asset a field picks in the dialog (`AssetPickerDialog`) rather than a
    /// dropdown: `MeshRenderer.mesh` (meshes), `MeshRenderer.material` and `Decal.material`.
    public func pickerKind(component: String, path: String) -> AssetKind? {
        switch (component, path) {
        case (MeshRenderer.componentName, "mesh"): .mesh
        case (MeshRenderer.componentName, "material"), (Decal.componentName, "material"): .material
        default: nil
        }
    }
}

extension EditorSession {
    /// The picker's choices for `keys`: titled by `title`, "" as None, registered keys as
    /// built-in, assets by their file.
    @MainActor
    func assetPickerOptions(_ keys: [String], title: (String) -> String) -> [AssetPickerOption] {
        keys.map { key in
            if key.isEmpty { return AssetPickerOption(value: "", title: "None", caption: "No asset") }
            guard let reference = AssetReference(key), let record = assets?.record(reference.asset) else {
                return AssetPickerOption(value: key, title: title(key), caption: "Built-in")
            }
            return AssetPickerOption(value: key, title: title(key), caption: record.path)
        }
    }

    /// Opens the picker in `context` for `kind` among `keys`, on `current`; `done` gets the value picked.
    @MainActor
    func showAssetPicker(_ kind: AssetKind, keys: [String], current: String, title: @escaping (String) -> String,
                         preview: @escaping (String) -> GPUTexture?, in context: UIContext?, done: @escaping (String) -> Void) {
        guard let context else { return }
        let noun = kind == .mesh ? "Mesh" : kind == .material ? "Material" : "Asset"
        var options = assetPickerOptions(keys, title: title)
        if !options.contains(where: { $0.value == current }) {
            options.insert(contentsOf: assetPickerOptions([current], title: title), at: 0)
        }
        let dialog = AssetPickerDialog(title: "Select \(noun)", options: options, current: current, preview: preview,
                                       command: ComponentSetFieldCommand.id)
        dialog.onPick = done
        dialog.present(in: context)
    }
}
