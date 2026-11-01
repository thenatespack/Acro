import Engine
import Foundation

/// The asset browser's grid (or list) of entries: a thumbnail (or icon) and a name per cell,
/// drawn only where visible. Put it in a `ScrollView`. Click selects, double click activates
/// (opens a folder, expands a model), the triangle on a model expands it, right click asks for
/// a context menu, and dragging a cell reports `onDrag` (began, moved, dropped) with the window
/// position, so the host can drop it anywhere in the editor.
@MainActor
final class AssetGridView: Widget {
    enum DragPhase { case began, moved, dropped, cancelled }

    var entries: [AssetBrowserEntry] = [] { didSet { if entries != oldValue { setNeedsLayout() } } }
    var selected: AssetItem? { didSet { if selected != oldValue { setNeedsDisplay() } } }
    var listMode = false { didSet { if listMode != oldValue { setNeedsLayout() } } }
    /// Grid cell size in points (thumbnail plus a title line).
    var cellSize = Vec2(88, 104)
    var listRowHeight: Float = 24
    var dragThreshold: Float = 5
    /// The thumbnail for an entry, if one is ready (asked while drawing visible cells).
    var thumbnail: ((AssetBrowserEntry) -> GPUTexture?)?
    var onSelect: ((AssetBrowserEntry?) -> Void)?
    var onActivate: ((AssetBrowserEntry) -> Void)?
    var onToggleExpanded: ((AssetBrowserEntry) -> Void)?
    var onContextMenu: ((AssetBrowserEntry?, Vec2) -> Void)?
    var onDrag: ((AssetBrowserEntry, Vec2, DragPhase) -> Void)?

    private var press: (index: Int, position: Vec2)?
    private(set) var dragging: AssetBrowserEntry?

    init() {
        super.init(name: "assetGrid")
    }

    override var acceptsFocus: Bool { true }
    override var accessibilityRole: UIAccessibilityRole { .list }

    /// A "cell:<title>" item per entry, and "expand:<title>" for a model's triangle.
    override var accessibilityItems: [UIAccessibilityItem] {
        var items: [UIAccessibilityItem] = []
        for (index, entry) in entries.enumerated() {
            items.append(UIAccessibilityItem(key: "cell:\(entry.title)", role: .listItem, label: entry.title, value: entry.path,
                                             frame: cellRect(index), isSelected: entry.item == selected))
            if let expander = expanderRect(index) {
                items.append(UIAccessibilityItem(key: "expand:\(entry.title)", role: .button, label: "Expand \(entry.title)",
                                                 frame: expander))
            }
        }
        return items
    }

    private var columns: Int {
        listMode ? 1 : max(1, Int((contentRect.width / cellSize.x).rounded(.down)))
    }

    private func columns(forWidth width: Float) -> Int {
        listMode ? 1 : max(1, Int((width / cellSize.x).rounded(.down)))
    }

    override func measureContent(width: Float?) -> Vec2 {
        let w = width ?? cellSize.x * 4
        let rows = (entries.count + columns(forWidth: w) - 1) / columns(forWidth: w)
        return Vec2(listMode ? 160 : cellSize.x, Float(max(rows, 1)) * (listMode ? listRowHeight : cellSize.y))
    }

    /// The frame of entry `index` in window points.
    func cellRect(_ index: Int) -> UIRect {
        let content = contentRect
        if listMode {
            return UIRect(x: content.x, y: content.y + Float(index) * listRowHeight, width: content.width, height: listRowHeight)
        }
        let n = columns
        let width = content.width / Float(n)
        return UIRect(x: content.x + Float(index % n) * width, y: content.y + Float(index / n) * cellSize.y, width: width,
                      height: cellSize.y)
    }

    /// The entry under a window point.
    func index(at point: Vec2) -> Int? {
        let content = contentRect
        guard content.contains(point) else { return nil }
        let row = Int(((point.y - content.y) / (listMode ? listRowHeight : cellSize.y)).rounded(.down))
        let column = listMode ? 0 : Int(((point.x - content.x) / (content.width / Float(columns))).rounded(.down))
        let index = row * columns + column
        return entries.indices.contains(index) ? index : nil
    }

    private func thumbnailRect(_ cell: UIRect) -> UIRect {
        if listMode {
            return UIRect(x: cell.x + 4 + (entries.isEmpty ? 0 : 0), y: cell.y + 3, width: cell.height - 6, height: cell.height - 6)
        }
        let side = min(cell.width - 16, cell.height - 30)
        return UIRect(x: snap(cell.x + (cell.width - side) / 2), y: cell.y + 6, width: side, height: side)
    }

    /// The expand triangle of an expandable entry.
    private func expanderRect(_ index: Int) -> UIRect? {
        guard entries[index].isExpandable else { return nil }
        let cell = cellRect(index)
        if listMode { return UIRect(x: cell.maxX - 22, y: cell.y, width: 22, height: cell.height) }
        let thumb = thumbnailRect(cell)
        return UIRect(x: thumb.maxX - 18, y: thumb.y + (thumb.height - 22) / 2, width: 22, height: 22)
    }

    // MARK: Events

    override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .right:
            let index = index(at: e.position)
            if let index {
                selected = entries[index].item
                onSelect?(entries[index])
            }
            onContextMenu?(index.map { entries[$0] }, e.position)
            return true
        case .pointerDown(let e) where e.button == .left:
            guard let index = index(at: e.position) else {
                selected = nil
                onSelect?(nil)
                return true
            }
            let entry = entries[index]
            if let expander = expanderRect(index), expander.contains(e.position) {
                onToggleExpanded?(entry)
                return true
            }
            selected = entry.item
            onSelect?(entry)
            if e.clickCount == 2 {
                onActivate?(entry)
            } else {
                press = (index, e.position)
            }
            return true
        case .pointerDrag(let e):
            if let dragging {
                onDrag?(dragging, e.position, .moved)
            } else if let press, entries.indices.contains(press.index), length(Vec3(e.position - press.position, 0)) > dragThreshold {
                dragging = entries[press.index]
                onDrag?(entries[press.index], e.position, .began)
                setNeedsDisplay()
            }
            return true
        case .pointerUp(let e):
            if let dragging { onDrag?(dragging, e.position, .dropped) }
            dragging = nil
            press = nil
            return true
        case .key(let e) where e.key == .escape && dragging != nil:
            if let dragging { onDrag?(dragging, context?.pointerPosition ?? .zero, .cancelled) }
            dragging = nil
            press = nil
            return true
        case .key(let e):
            guard let current = entries.firstIndex(where: { $0.item == selected }) ?? (entries.isEmpty ? nil : -1) else { return false }
            let step: Int
            switch e.key {
            case .left: step = -1
            case .right: step = 1
            case .up: step = -columns
            case .down: step = columns
            case .enter:
                if current >= 0 { onActivate?(entries[current]) }
                return true
            default: return false
            }
            let next = min(max(current + step, 0), entries.count - 1)
            selected = entries[next].item
            onSelect?(entries[next])
            _ = parent?.scrollToReveal(cellRect(next))
            return true
        default:
            return false
        }
    }

    override func tooltip(at point: Vec2) -> String? {
        guard dragging == nil, let index = index(at: point) else { return tooltip }
        let entry = entries[index]
        return "\(entry.title)\n\(entry.kind.rawValue.capitalized) · \(entry.isSubAsset ? "in " : "")Assets/\(entry.path)"
    }

    // MARK: Drawing

    override func draw(_ list: UIDrawList, theme: UITheme) {
        guard !entries.isEmpty else {
            let layout = context?.textLayout("Empty", size: theme.fontSize) ?? TextLayout("Empty", font: theme.font, size: theme.fontSize)
            list.drawText(layout, font: theme.font, at: Vec2(snap(contentRect.x + 8), snap(contentRect.y + 8)),
                          color: theme.secondaryTextColor)
            return
        }
        let clip = list.clipBounds ?? frame
        let hovered = isHovered && dragging == nil ? context.flatMap { index(at: $0.pointerPosition) } : nil
        for index in entries.indices {
            let cell = cellRect(index)
            if cell.maxY < clip.y { continue }
            if cell.y > clip.maxY { break }
            drawCell(index, in: cell, hovered: hovered == index, list: list, theme: theme)
        }
    }

    private func drawCell(_ index: Int, in cell: UIRect, hovered: Bool, list: UIDrawList, theme: UITheme) {
        let entry = entries[index]
        let isSelected = entry.item == selected
        let box = cell.inset(by: EdgeInsets(2))
        if entry.isSubAsset { list.fillRect(box, color: UIColor(hex: 0xffffff, alpha: 0.03), radii: UICornerRadii(4)) }
        if isSelected {
            list.fillRect(box, color: isFocused ? theme.rowSelectedFocused : theme.rowSelected, radii: UICornerRadii(4))
        } else if hovered {
            list.fillRect(box, color: theme.rowHover, radii: UICornerRadii(4))
        }
        var thumb = thumbnailRect(cell)
        if listMode, entry.isSubAsset { thumb.x += 16 }
        if let texture = thumbnail?(entry) {
            // Fit, keeping the aspect ratio.
            let aspect = Float(texture.width) / Float(max(texture.height, 1))
            var rect = thumb
            if aspect > 1 {
                rect.height = thumb.width / aspect
                rect.y += (thumb.height - rect.height) / 2
            } else {
                rect.width = thumb.height * aspect
                rect.x += (thumb.width - rect.width) / 2
            }
            list.drawImage(texture, in: snappedRect(rect), radii: UICornerRadii(listMode ? 2 : 4))
            // The asset's kind as a badge in the thumbnail's corner (a texture, a material and a
            // mesh can look alike).
            if !listMode {
                let badge = UIRect(x: thumb.x + 2, y: thumb.maxY - 20, width: 18, height: 18)
                list.fillRect(badge, color: UIColor(0, 0, 0, 0.6), radii: UICornerRadii(9))
                list.drawIcon(EditorIcons.asset(EditorIcons.assetKind(entry.kind, path: entry.path)), in: badge.inset(by: 3),
                              color: UIColor(hex: 0xf4f6fa))
            }
        } else {
            Self.drawIcon(entry, in: thumb, list: list, theme: theme, selected: isSelected)
        }
        if let expander = expanderRect(index) {
            let c = expander.center
            if !listMode { list.fillRect(expander, color: UIColor(0, 0, 0, 0.45), radii: UICornerRadii(11)) }
            let s: Float = 3.5
            let color = theme.textColor
            if entry.isExpanded {
                list.drawLine(from: c + Vec2(s / 2, -s), to: c + Vec2(-s / 2, 0), width: 1.5, color: color, cap: .round)
                list.drawLine(from: c + Vec2(-s / 2, 0), to: c + Vec2(s / 2, s), width: 1.5, color: color, cap: .round)
            } else {
                list.drawLine(from: c + Vec2(-s / 2, -s), to: c + Vec2(s / 2, 0), width: 1.5, color: color, cap: .round)
                list.drawLine(from: c + Vec2(s / 2, 0), to: c + Vec2(-s / 2, s), width: 1.5, color: color, cap: .round)
            }
        }
        let size = listMode ? theme.fontSize : theme.smallFontSize
        let textRect: UIRect
        let alignment: TextAlignment
        if listMode {
            let right = expanderRect(index).map { $0.width } ?? 0
            textRect = UIRect(x: thumb.maxX + 8, y: cell.y, width: max(0, cell.maxX - right - thumb.maxX - 12), height: cell.height)
            alignment = .left
        } else {
            textRect = UIRect(x: cell.x + 4, y: thumb.maxY + 3, width: cell.width - 8, height: cell.maxY - thumb.maxY - 6)
            alignment = .center
        }
        drawEllipsizedLine(entry.title, size: size, in: textRect, alignment: alignment,
                           color: entry.isSubAsset && !isSelected ? theme.secondaryTextColor : theme.textColor, list: list, theme: theme)
    }

    private func drawEllipsizedLine(_ text: String, size: Float, in rect: UIRect, alignment: TextAlignment, color: UIColor,
                                    list: UIDrawList, theme: UITheme) {
        guard rect.width > 0 else { return }
        var layout = context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)
        if layout.width > rect.width + 1 / scale, let short = TextEllipsis.fit(text, font: theme.font, size: size, width: rect.width) {
            layout = context?.textLayout(short, size: size) ?? TextLayout(short, font: theme.font, size: size)
        }
        let x: Float = alignment == .center ? rect.x + (rect.width - layout.width) / 2 : rect.x
        list.drawText(layout, font: theme.font, at: Vec2(snap(x), snap(rect.y + (rect.height - layout.height) / 2)), color: color)
    }

    /// The icon of an entry without a thumbnail: its kind's (`EditorIcons.asset`), in the
    /// middle of the thumbnail square.
    static func drawIcon(_ entry: AssetBrowserEntry, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool = false) {
        let kind = EditorIcons.assetKind(entry.kind, path: entry.path)
        let side = min(rect.width, rect.height)
        let edge = side < 32 ? side : (side * 0.6).rounded()
        // On a selected cell the text color keeps its contrast (as tree rows do).
        list.drawIcon(EditorIcons.asset(kind), in: UIRect(x: rect.center.x - edge / 2, y: rect.center.y - edge / 2, width: edge, height: edge),
                      color: selected ? theme.textColor : EditorIcons.assetColor(kind, theme: theme))
    }
}

/// The dockable Assets panel: the project's folders on the left (a tree), the selected folder's
/// files on the right as a grid of thumbnails (or a list), with a breadcrumb, a search field
/// and Import… / New Folder / New Material / Rename / Delete (with confirmation). Import copies
/// files or folders from anywhere on disk into the current folder (a native dialog on macOS, a
/// path field elsewhere). Models expand to show
/// their meshes, materials, textures and prefab. Selecting an item shows it in the inspector;
/// cells can be dragged onto the viewport, the hierarchy or an inspector field
/// (`onDrag`, handled by the host), or onto a folder in the tree to move them.
@MainActor
public final class AssetBrowserPanel {
    public let model: AssetBrowserModel
    public let view: Widget
    let folderTree = TreeView(roots: [], name: "assetFolders")
    let grid = AssetGridView()
    let search = TextField(placeholder: "Search", name: "assetSearch")
    let breadcrumb = Label("Assets", role: .secondary, name: "assetBreadcrumb")
    /// Inline rename field, shown on demand.
    let renameField = TextField(placeholder: "Name", name: "assetRename")
    private let renameBar: HStack
    /// Path entry for Import… where there's no native file dialog.
    let importField = TextField(placeholder: "Path to a file or folder", name: "assetImportPath")
    private let importBar: HStack
    private let viewToggle: Button
    private let noProject = Label("Open or create a project to see its assets", role: .secondary, name: "noProject")
    private let content: Widget
    private var shownVersion = -1
    private var shownFolders: [String]?
    private var folderNodes: [String: TreeNode] = [:]
    private var applyingTree = false

    /// The host's drop handling for a drag that ends outside the browser; also gets moves.
    var onDrag: ((AssetBrowserEntry, Vec2, AssetGridView.DragPhase) -> Void)?

    public init(session: EditorSession) {
        model = AssetBrowserModel(session: session)
        let importButton = Button("Import…", name: "importAsset")
        let newFolder = Button("New Folder", name: "newFolder")
        let newMaterial = Button("New Material", name: "newMaterial")
        let rename = Button("Rename", name: "renameAsset")
        let delete = Button("Delete", name: "deleteAsset")
        viewToggle = Button("List", name: "assetViewMode")
        importButton.tooltip = EditorShortcuts().tooltip(
            "Copy files or folders from your computer into the current folder and import them", for: .importAsset)
        newFolder.tooltip = "Create a folder in the current folder"
        newMaterial.tooltip = "Create a .material file in the current folder"
        rename.tooltip = "Rename the selected file or folder (its id is kept)"
        delete.tooltip = "Delete the selected file or folder"
        viewToggle.tooltip = "Switch between thumbnails and a list"
        // What each control runs (introspection, parity). The view mode and the search only
        // change what the panel shows: asset.list reads the same.
        let tagged: [(Widget, CommandID)] = [
            (importButton, AssetImportCommand.id), (newFolder, AssetNewFolderCommand.id), (newMaterial, AssetNewMaterialCommand.id),
            (rename, AssetRenameCommand.id), (delete, AssetDeleteCommand.id), (viewToggle, AssetListCommand.id),
            (search, AssetListCommand.id),
        ]
        for (widget, id) in tagged { widget.command = id.rawValue }
        folderTree.itemCommands = ["row": AssetListCommand.id.rawValue, "toggle": AssetListCommand.id.rawValue]
        grid.itemCommands = ["cell": AssetSelectCommand.id.rawValue, "expand": AssetGetCommand.id.rawValue]
        search.style.width = 140
        search.style.minWidth = 70
        search.style.shrink = 1
        search.tooltip = "Filter the whole project by name"
        breadcrumb.style.grow = 1
        breadcrumb.style.shrink = 1
        breadcrumb.style.width = 0
        breadcrumb.style.minWidth = 60
        // Icon-only buttons (titles stay their labels; tooltips say what they do), so the bar
        // keeps to one row in a narrow panel more often.
        for (button, icon) in [(importButton, "file-down"), (newFolder, "folder-plus"), (newMaterial, "palette"), (rename, "pencil"),
                               (delete, "trash-2"), (viewToggle, "list")] {
            button.icon = EditorIcons.named(icon)
            button.showsTitle = false
        }
        let toolbar = HStack(spacing: 4, name: "assetToolbar", [breadcrumb, search, importButton, newFolder, newMaterial, rename, delete, viewToggle])
        toolbar.wraps = true  // rows of buttons in a narrow panel, instead of buttons past its edge

        let renameOK = Button("Rename", role: .primary, name: "renameOK")
        let renameCancel = Button("Cancel", name: "renameCancel")
        renameField.style.grow = 1
        renameField.style.width = 0
        renameBar = HStack(spacing: 6, name: "renameBar", [Label("Rename to", role: .secondary), renameField, renameCancel, renameOK])
        renameBar.command = AssetRenameCommand.id.rawValue
        renameBar.isHidden = true
        let importOK = Button("Import", role: .primary, name: "importOK")
        let importCancel = Button("Cancel", name: "importCancel")
        importField.style.grow = 1
        importField.style.width = 0
        importBar = HStack(spacing: 6, name: "importBar", [Label("Import", role: .secondary), importField, importCancel, importOK])
        importBar.command = AssetImportCommand.id.rawValue
        importBar.isHidden = true

        let gridScroll = ScrollView(grid, name: "assetGridScroll")
        gridScroll.style.grow = 1
        gridScroll.style.shrink = 1
        let right = VStack(spacing: 6, padding: EdgeInsets(top: 0, left: 6, bottom: 0, right: 0), name: "assetContents",
                           [toolbar, importBar, renameBar, gridScroll])
        folderTree.background = .clear
        folderTree.allowsDragAndDrop = false
        let split = SplitView(.horizontal, panes: [folderTree, right], fractions: [0.22, 0.78], minSizes: [100, 200], name: "assetSplit")
        split.style.grow = 1
        content = split
        noProject.isHidden = true
        let root = VStack(spacing: 6, padding: EdgeInsets(6), name: "assetsPanel", [split, noProject])
        view = root

        importButton.action = { [unowned self] in beginImport() }
        importOK.action = { [unowned self] in commitImport() }
        importCancel.action = { [unowned self] in importBar.isHidden = true }
        importField.onSubmit = { [unowned self] _ in commitImport() }
        newFolder.action = { [unowned self] in model.newFolder(); sync() }
        newMaterial.action = { [unowned self] in model.newMaterial(); sync() }
        rename.action = { [unowned self] in beginRename() }
        delete.action = { [unowned self] in askDelete() }
        viewToggle.action = { [unowned self] in
            grid.listMode.toggle()
            viewToggle.title = grid.listMode ? "Grid" : "List"
            viewToggle.icon = EditorIcons.named(grid.listMode ? "layout-grid" : "list")
        }
        renameOK.action = { [unowned self] in commitRename() }
        renameCancel.action = { [unowned self] in renameBar.isHidden = true }
        renameField.onSubmit = { [unowned self] _ in commitRename() }
        search.onChange = { [unowned self] text in model.search = text }

        folderTree.onSelect = { [unowned self] node in
            guard !applyingTree, let path = node?.userData as? String else { return }
            model.folder = path
            model.select(.folder(path))
        }
        grid.onSelect = { [unowned self] entry in model.select(entry?.item) }
        grid.onActivate = { [unowned self] entry in model.activate(entry); sync() }
        grid.onToggleExpanded = { [unowned self] entry in
            if let id = entry.item.assetID { model.toggleExpanded(id) }
        }
        grid.onContextMenu = { [unowned self] entry, position in showContextMenu(for: entry, at: position) }
        grid.onDrag = { [unowned self] entry, position, phase in
            if phase == .dropped, dropOnFolderTree(entry, at: position) { return }
            onDrag?(entry, position, phase)
        }
        sync()
    }

    /// Pulls the model into the widgets; call every frame.
    public func sync() {
        let hasProject = model.session.assets != nil
        if content.isHidden == hasProject { content.isHidden = !hasProject }
        if noProject.isHidden != hasProject { noProject.isHidden = hasProject }
        let entries = model.entries
        let folders = model.folders
        let pending = model.session.assets?.pendingLoadCount ?? 0
        let crumbBase = model.search.isEmpty ? model.breadcrumb.map(\.title).joined(separator: " › ") : "Search results"
        let crumb = crumbBase + (pending > 0 ? " · importing \(pending)…" : "")
        if breadcrumb.text != crumb { breadcrumb.text = crumb }
        if folders != shownFolders { rebuildTree(folders) }
        guard model.version != shownVersion else { return }
        shownVersion = model.version
        grid.entries = entries
        grid.selected = model.selection
        if search.text != model.search, !search.isFocused { search.text = model.search }
        applyingTree = true
        if let node = folderNodes[model.folder] {
            var parent = node.parent
            while let p = parent { p.isExpanded = true; parent = p.parent }
            folderTree.reloadData()
            if folderTree.selectedNode !== node { folderTree.select(node) }
        }
        applyingTree = false
    }

    private func rebuildTree(_ folders: [String]) {
        shownFolders = folders
        let expandedPaths = Set(folderNodes.filter { $0.value.isExpanded }.map(\.key))
        let root = TreeNode("Assets", isExpanded: true, userData: "")
        root.icon = EditorIcons.named("folder")
        folderNodes = ["": root]
        for path in folders {
            let parent = folderNodes[EditorSession.parentFolder(of: path)] ?? root
            let node = TreeNode(String(path.split(separator: "/").last ?? ""), isExpanded: expandedPaths.contains(path), userData: path)
            node.icon = EditorIcons.named("folder")
            parent.addChild(node)
            folderNodes[path] = node
        }
        applyingTree = true
        folderTree.roots = [root]
        applyingTree = false
        shownVersion = -1
    }

    /// A cell dropped on a folder of the tree moves there.
    private func dropOnFolderTree(_ entry: AssetBrowserEntry, at position: Vec2) -> Bool {
        guard folderTree.isEffectivelyVisible, folderTree.frame.contains(position) else { return false }
        if let row = folderTree.row(at: position), let path = folderTree.visibleNodes[row].userData as? String {
            if model.move(entry.item, into: path) { sync() }
        }
        return true
    }

    /// Import…: the native file dialog where there is one, else the path field.
    func beginImport() {
        guard model.session.assets != nil else { return }
        renameBar.isHidden = true
        if FilePicker.isAvailable {
            guard let urls = FilePicker.chooseFiles(title: "Import into Assets/\(model.folder)", prompt: "Import") else { return }
            if !model.importFiles(urls).isEmpty { sync() }
        } else {
            importBar.isHidden = false
            view.context?.focus(importField)
        }
    }

    private func commitImport() {
        let text = importField.text.trimmingCharacters(in: .whitespaces)
        guard !importBar.isHidden, !text.isEmpty else { return }
        let url = URL(fileURLWithPath: (text as NSString).expandingTildeInPath)
        if !model.importFiles([url]).isEmpty {
            importBar.isHidden = true
            importField.text = ""
            sync()
        }
    }

    func beginRename() {
        guard let path = model.selectedPath else { return }
        importBar.isHidden = true
        renameBar.isHidden = false
        let name = String(path.split(separator: "/").last ?? "")
        renameField.text = name
        view.context?.focus(renameField)
    }

    private func commitRename() {
        guard !renameBar.isHidden else { return }
        renameBar.isHidden = true
        if model.renameSelection(to: renameField.text) { sync() }
    }

    /// Asks in a modal dialog, then deletes the selected file or folder.
    func askDelete() {
        guard let path = model.selectedPath, let context = view.context else { return }
        renameBar.isHidden = true
        importBar.isHidden = true
        let isFolder = model.session.assets?.isFolder(path) ?? false
        let name = String(path.split(separator: "/").last ?? "")
        let dialog = ConfirmDialog(
            title: "Delete \(isFolder ? "folder" : "file") \u{201C}\(name)\u{201D}?",
            message: (isFolder ? "Assets/\(path) and everything in it will be deleted." : "Assets/\(path) will be deleted.")
                + " This can't be undone, and scenes that use \(isFolder ? "these assets" : "it") will show them as missing.",
            confirmTitle: "Delete", name: "deleteAssetDialog")
        dialog.command = AssetDeleteCommand.id.rawValue
        dialog.onConfirm = { [unowned self] in
            model.deleteSelection()
            sync()
        }
        dialog.present(in: context)
    }

    private func showContextMenu(for entry: AssetBrowserEntry?, at position: Vec2) {
        guard let context = view.context else { return }
        // (title, the command it runs or the tool that gives an agent the same, action)
        var items: [(String, CommandID, () -> Void)] = [
            ("Import…", AssetImportCommand.id, { [unowned self] in beginImport() }),
            ("New Folder", AssetNewFolderCommand.id, { [unowned self] in model.newFolder(); sync() }),
            ("New Material", AssetNewMaterialCommand.id, { [unowned self] in model.newMaterial(); sync() }),
        ]
        if let entry {
            if case .folder = entry.item {
                items.append(("Open", AssetListCommand.id, { [unowned self] in model.activate(entry); sync() }))
            }
            if !entry.isSubAsset {
                items.append(("Rename", AssetRenameCommand.id, { [unowned self] in beginRename() }))
                items.append(("Delete", AssetDeleteCommand.id, { [unowned self] in askDelete() }))
            }
            if case .asset(let id) = entry.item, model.session.assets?.record(id)?.importer == GLTFImporter().name {
                items.append(("Extract Materials", AssetExtractMaterialsCommand.id, { [unowned self] in
                    model.session.run(AssetExtractMaterialsCommand.self, .init(asset: id))
                    model.invalidate()
                }))
            }
            #if os(macOS)
            if let url = model.session.project?.url(forAssetPath: entry.path) {
                // An agent has the path from asset.get; revealing it in Finder is for the user.
                items.append(("Show in Finder", AssetGetCommand.id, {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-R", url.path]
                    try? process.run()
                }))
            }
            #endif
        }
        let menu = PopupMenu(items: items.map(\.0))
        menu.itemCommandIDs = items.map { $0.1.rawValue }
        menu.anchorRect = UIRect(x: position.x, y: position.y, width: 1, height: 1)
        menu.onSelect = { index in items[index].2() }
        context.presentOverlay(menu)
    }
}

extension AssetBrowserModel {
    /// Selects `item` and shows it in the inspector (again, if an entity was selected since).
    public func select(_ item: AssetItem?) {
        selection = item
        if let item { session.inspectedAsset = item }
    }
}
