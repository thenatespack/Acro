import Engine
import Foundation

// The launcher: the start screen the editor shows when it starts without a project or scene
// (and after Close Project). A sidebar with New Project, Open… and Continue Without a Project; the
// recent projects (RecentProjects.swift) as rows with a thumbnail, name, game-code badge, folder
// and when they were last opened, pinned ones first, filtered by a search field; an empty state
// when there are none; and the New Project and Open forms in place of the list.
//
// Keys: Up / Down move through the projects, Enter opens, Delete removes from the list,
// Cmd/Ctrl+N New Project, Cmd/Ctrl+O Open…, Cmd/Ctrl+F the search field, Esc leaves a form.
// Every control runs a command (EditorLauncherCommands.swift, project.open / project.new), so
// MCP clients and ParityTests see the launcher like the rest of the editor.

/// The recent projects as rows: thumbnail, name (with a Game badge), folder, last opened, and
/// pin / more buttons (Locate… and Remove for a missing folder).
@MainActor
final class RecentProjectsListView: RowListView {
    var entries: [RecentProject] = [] {
        didSet {
            if entries != oldValue {
                if let selected = selectedRow, selected >= entries.count { selectRow(entries.isEmpty ? nil : entries.count - 1) }
                setNeedsLayout()
            }
        }
    }
    /// The thumbnail of a project, if it has one (loaded by the app).
    var thumbnail: ((RecentProject) -> GPUTexture?)?
    var now: () -> Date = { Date() }
    var onOpen: ((RecentProject) -> Void)?
    var onRemove: ((RecentProject) -> Void)?
    var onTogglePin: ((RecentProject) -> Void)?
    var onLocate: ((RecentProject) -> Void)?
    /// Right click or the row's ⋯ button: show the row's menu at a point.
    var onMenu: ((RecentProject, UIRect) -> Void)?

    static let rowHeightPoints: Float = 68
    /// Thumbnails are 16:9.
    static let thumbnailSize = Vec2(96, 54)

    init() {
        super.init(name: "recentProjects")
        rowHeight = Self.rowHeightPoints
        preferredVisibleRows = 4
    }

    override var rowCount: Int { entries.count }
    override func rowAccessibilityLabel(_ row: Int) -> String? { entries[row].name }
    override func rowAccessibilityValue(_ row: Int) -> String? {
        let entry = entries[row]
        return entry.isMissing ? "missing: \(entry.path)" : entry.path
    }
    override func selectionChanged() { setNeedsDisplay() }
    override func rowActivated(_ row: Int) {
        let entry = entries[row]
        if entry.isMissing { onLocate?(entry) } else { onOpen?(entry) }
    }

    var selectedEntry: RecentProject? { selectedRow.flatMap { entries.indices.contains($0) ? entries[$0] : nil } }

    // MARK: Parts

    enum Part: String, CaseIterable { case menu, pin, remove, locate }

    /// The buttons drawn in a row, right to left: ⋯, the pin, and for a missing folder Remove and Locate….
    func partRects(_ row: Int) -> [(Part, UIRect)] {
        let rect = rowRect(row)
        let side: Float = 28
        let y = (rect.y + (rect.height - side) / 2).rounded()
        var x = rect.maxX - 8 - side
        var parts: [(Part, UIRect)] = [(.menu, UIRect(x: x, y: y, width: side, height: side))]
        x -= side + 4
        parts.append((.pin, UIRect(x: x, y: y, width: side, height: side)))
        if entries[row].isMissing {
            for (part, title) in [(Part.remove, "Remove"), (Part.locate, "Locate…")] {
                let width = textWidth(title, size: theme.fontSize) + 20
                x -= width + 6
                parts.append((part, UIRect(x: x, y: y, width: width, height: side)))
            }
        }
        return parts
    }

    private func label(_ part: Part, _ entry: RecentProject) -> String {
        switch part {
        case .menu: "More actions for \(entry.name)"
        case .pin: entry.pinned ? "Unpin \(entry.name)" : "Pin \(entry.name)"
        case .remove: "Remove \(entry.name) from the list"
        case .locate: "Locate \(entry.name)…"
        }
    }

    override var accessibilityItems: [UIAccessibilityItem] {
        var items = super.accessibilityItems
        for row in entries.indices {
            for (part, rect) in partRects(row) {
                items.append(UIAccessibilityItem(key: "\(part.rawValue):\(entries[row].name)", role: .button,
                                                 label: label(part, entries[row]), frame: rect, tooltip: label(part, entries[row])))
            }
        }
        return items
    }

    override func rowTooltip(_ row: Int, in rect: UIRect) -> String? {
        let entry = entries[row]
        if let context, let part = partRects(row).first(where: { $0.1.contains(context.pointerPosition) }) {
            return label(part.0, entry)
        }
        let opened = "Opened " + RecentProjectList.relativeTime(entry.lastOpened, now: now())
        return entry.isMissing ? "\(entry.name)\n\(entry.path)\nThe folder is missing: Locate… finds it, Remove takes it off the list"
            : "\(entry.name)\(entry.pinned ? " (pinned)" : "")\n\(entry.path)\n\(opened)"
    }

    override func rowPressed(_ row: Int, at position: Vec2, event: PointerEvent) -> Bool {
        guard let part = partRects(row).first(where: { $0.1.contains(position) }) else { return false }
        selectRow(row)
        let entry = entries[row]
        switch part.0 {
        case .menu: onMenu?(entry, part.1)
        case .pin: onTogglePin?(entry)
        case .remove: onRemove?(entry)
        case .locate: onLocate?(entry)
        }
        return true
    }

    override func handleEvent(_ event: UIEvent) -> Bool {
        if case .pointerDown(let e) = event, e.button == .right {
            if let row = row(at: e.position) {
                selectRow(row)
                onMenu?(entries[row], UIRect(x: e.position.x, y: e.position.y, width: 1, height: 1))
            }
            return true
        }
        return super.handleEvent(event)
    }

    override func handleRowKey(_ key: KeyEvent) -> Bool {
        guard let entry = selectedEntry else { return false }
        guard key.key == .delete || key.key == .backspace, key.modifiers.isEmpty || key.modifiers == .shortcut else { return false }
        onRemove?(entry)
        return true
    }

    // MARK: Drawing

    private func textWidth(_ text: String, size: Float) -> Float {
        (context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)).width
    }

    @discardableResult
    private func drawLine(_ text: String, size: Float, at origin: Vec2, width: Float, color: UIColor, list: UIDrawList) -> Float {
        guard width > 4 else { return 0 }
        let theme = theme
        var layout = context?.textLayout(text, size: size) ?? TextLayout(text, font: theme.font, size: size)
        if layout.width > width + 1 / scale, let short = TextEllipsis.fit(text, font: theme.font, size: size, width: width) {
            layout = context?.textLayout(short, size: size) ?? TextLayout(short, font: theme.font, size: size)
        }
        list.drawText(layout, font: theme.font, at: Vec2(snap(origin.x), snap(origin.y)), color: color)
        return layout.width
    }

    /// The colors of the Game badge: the accent, lifted until its text reads on the row.
    static func badgeColors(_ theme: UITheme) -> (text: UIColor, fill: UIColor) {
        let fill = theme.accent.withAlpha(0.16)
        let text = EditorIcons.readable(theme.accent, on: fill.composited(over: theme.fieldBackground), toward: theme.textColor, minimum: 4.5)
        return (text, fill)
    }

    override func drawRow(_ row: Int, in rect: UIRect, list: UIDrawList, theme: UITheme, selected: Bool) {
        let entry = entries[row]
        let missing = entry.isMissing
        let hovered = isHovered && context.flatMap { self.row(at: $0.pointerPosition) } == row
        // Thumbnail (16:9), or the project's kind as an icon.
        let thumb = UIRect(x: rect.x + 8, y: snap(rect.y + (rect.height - Self.thumbnailSize.y) / 2),
                           width: Self.thumbnailSize.x, height: Self.thumbnailSize.y)
        if !missing, let texture = thumbnail?(entry) {
            list.drawImage(texture, in: thumb, radii: UICornerRadii(theme.smallCornerRadius))
        } else {
            list.fillRect(thumb, color: theme.controlBackground, radii: UICornerRadii(theme.smallCornerRadius))
            let icon = EditorIcons.named(missing ? "triangle-alert" : entry.hasGame ? "gamepad-2" : "folder")
            let edge: Float = 24
            list.drawIcon(icon, in: UIRect(x: thumb.center.x - edge / 2, y: thumb.center.y - edge / 2, width: edge, height: edge),
                          color: missing ? theme.warningTextColor : theme.secondaryTextColor)
        }
        list.strokeRect(thumb, color: theme.controlBorder, width: theme.borderWidth, radii: UICornerRadii(theme.smallCornerRadius))

        // Buttons on the right.
        let parts = partRects(row)
        let textRight = (parts.map(\.1.x).min() ?? rect.maxX) - 10
        for (part, frame) in parts {
            let over = hovered && context.map { frame.contains($0.pointerPosition) } == true
            switch part {
            case .menu:
                if over { list.fillRect(frame, color: theme.controlHover, radii: UICornerRadii(theme.smallCornerRadius)) }
                list.drawIcon(EditorIcons.named("ellipsis"), in: frame.inset(by: EdgeInsets(6)),
                              color: hovered || selected ? theme.textColor : theme.secondaryTextColor)
            case .pin:
                if over { list.fillRect(frame, color: theme.controlHover, radii: UICornerRadii(theme.smallCornerRadius)) }
                // Pinned: in the accent; unpinned: only while the row is hovered or selected.
                if entry.pinned || hovered || selected {
                    let color = entry.pinned ? Self.badgeColors(theme).text : theme.secondaryTextColor
                    list.drawIcon(EditorIcons.named(entry.pinned ? "pin" : "pin"), in: frame.inset(by: EdgeInsets(6)), color: color)
                }
            case .remove, .locate:
                list.fillRect(frame, color: over ? theme.controlHover : theme.controlBackground, radii: UICornerRadii(theme.cornerRadius))
                list.strokeRect(frame, color: theme.controlBorder, width: theme.borderWidth, radii: UICornerRadii(theme.cornerRadius))
                let title = part == .locate ? "Locate…" : "Remove"
                let width = textWidth(title, size: theme.fontSize)
                drawLine(title, size: theme.fontSize, at: Vec2(frame.x + (frame.width - width) / 2, frame.y + (frame.height - theme.fontSize * 1.3) / 2),
                         width: frame.width - 8, color: theme.textColor, list: list)
            }
        }

        // Name (with the Game badge), folder, and when it was last opened.
        let x = thumb.maxX + 12
        let width = max(textRight - x, 0)
        // On the selection's accent the secondary color loses contrast: the text color instead.
        let nameColor = missing && !selected ? theme.disabledTextColor : theme.textColor
        let detailColor = selected ? theme.textColor : missing ? theme.disabledTextColor : theme.secondaryTextColor
        let top = rect.y + 8
        var nameWidth = width
        let badgeWidth = textWidth("Game", size: theme.smallFontSize) + 26
        if entry.hasGame && width > badgeWidth + 40 { nameWidth -= badgeWidth + 8 }
        let drawn = drawLine(entry.name, size: theme.fontSize + 1, at: Vec2(x, top), width: nameWidth, color: nameColor, list: list)
        if entry.hasGame && width > badgeWidth + 40 {
            let colors = Self.badgeColors(theme)
            let badge = UIRect(x: snap(x + drawn + 8), y: top + 1, width: badgeWidth, height: 17)
            list.fillRect(badge, color: colors.fill, radii: UICornerRadii(8.5))
            list.drawIcon(EditorIcons.named("gamepad-2"), in: UIRect(x: badge.x + 5, y: badge.y + 2, width: 13, height: 13),
                          color: missing ? theme.disabledTextColor : colors.text)
            drawLine("Game", size: theme.smallFontSize, at: Vec2(badge.x + 21, badge.y + 2), width: badgeWidth - 22,
                     color: missing ? theme.disabledTextColor : colors.text, list: list)
        }
        drawLine(Self.abbreviated(entry.path), size: theme.smallFontSize, at: Vec2(x, top + 20), width: width, color: detailColor, list: list)
        let status = missing ? "Folder not found" : "Opened " + RecentProjectList.relativeTime(entry.lastOpened, now: now())
        let statusColor = missing && !selected ? theme.warningTextColor : detailColor
        let icon = EditorIcons.named(missing ? "triangle-alert" : "clock")
        list.drawIcon(icon, in: UIRect(x: x, y: top + 37, width: 12, height: 12), color: statusColor)
        drawLine(status, size: theme.smallFontSize, at: Vec2(x + 16, top + 36), width: width - 16, color: statusColor, list: list)
    }

    /// A path with the home folder as "~".
    static func abbreviated(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path == home ? "~" : path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}

/// The launcher's widgets and what they do; the app shows it in place of the editor's panels.
@MainActor
final class LauncherView {
    enum Page: String { case recent, newProject, open }

    let view: HStack
    private unowned let app: EditorApp
    private(set) var page: Page = .recent

    // Sidebar
    let newButton = Button("New Project…", role: .primary, name: "launcherNew")
    let openButton = Button("Open…", name: "launcherOpen")
    let continueButton = Button("Continue Without Project", name: "launcherContinue")
    let reopenCheckbox = Checkbox("Reopen last project", name: "reopenLastProject")

    // Recent projects
    let search = TextField(placeholder: "Search projects", name: "projectSearch")
    let list = RecentProjectsListView()
    private let listHeader: HStack
    private let recentPage: VStack
    private let emptyState: VStack
    private let noMatches = Label("", role: .secondary, name: "noMatches")

    // New Project
    let nameField = TextField(placeholder: "Project name", name: "newProjectName")
    let locationField = TextField(placeholder: "Folder to create it in", name: "newProjectLocation")
    let locationBrowse = Button("Browse…", name: "newProjectBrowse")
    private(set) var templateButtons: [(ProjectTemplate, Button)] = []
    private let templateSummary = Label("", role: .secondary, name: "templateSummary")
    private let newPathPreview = Label("", role: .caption, name: "newProjectPath")
    let newError = Label("", role: .body, name: "newProjectError")
    let createButton = Button("Create", role: .primary, name: "createProject")
    private let newPage: VStack
    private(set) var template: ProjectTemplate = .starter

    // Open
    let openField = TextField(placeholder: "Project folder or Project.json", name: "openProjectPath")
    let openBrowse = Button("Browse…", name: "openProjectBrowse")
    let openStatus = Label("", role: .secondary, name: "openProjectStatus")
    let openConfirm = Button("Open", role: .primary, name: "openProject")
    let createHereButton = Button("Create Project Here", name: "createProjectHere")
    private let openPage: VStack
    /// Set while Open… is locating a missing recent project (its path in the list).
    private(set) var locating: String?

    init(app: EditorApp) {
        self.app = app
        let session = app.session
        let theme = app.ui?.theme ?? UITheme()
        let shortcut = KeyModifiers.shortcut == .command ? "⌘" : "Ctrl+"

        // Sidebar
        let title = Label("Acro", role: .heading, name: "launcherTitle")
        title.icon = EditorIcons.named("box")
        let subtitle = Label("Editor \(EngineVersion.current)", role: .secondary, name: "launcherSubtitle")
        newButton.icon = EditorIcons.named("folder-plus")
        openButton.icon = EditorIcons.named("folder-open")
        continueButton.icon = EditorIcons.named("file")
        newButton.tooltip = "Create a project from a template (\(shortcut)N)"
        openButton.tooltip = "Open a project folder (\(shortcut)O)"
        continueButton.tooltip = "Use the editor without a project (the starter scene, no assets)"
        reopenCheckbox.tooltip = "Skip this screen at launch and reopen the last project"
        for button in [newButton, openButton, continueButton] { button.style.alignSelf = .stretch }
        let sidebar = VStack(spacing: 8, padding: EdgeInsets(20), name: "launcherSidebar", [
            title, subtitle, Spacer(grow: 0, minLength: 12), newButton, openButton, Spacer(), reopenCheckbox, continueButton,
        ])
        sidebar.style.width = 236
        sidebar.style.shrink = 0
        sidebar.background = theme.panelBackground

        // Recent projects
        let heading = Label("Recent Projects", role: .heading, name: "recentTitle")
        heading.style.shrink = 1
        heading.style.minWidth = 0
        search.style.width = 240
        search.style.shrink = 1
        search.style.minWidth = 120
        search.tooltip = "Filter by name or folder (\(shortcut)F)"
        listHeader = HStack(spacing: 8, name: "recentHeader", [heading, Spacer(), search])
        list.style.grow = 1
        noMatches.isHidden = true
        let emptyIcon = IconView(EditorIcons.named("folder-plus"), size: 44, name: "emptyIcon")
        let emptyTitle = Label("Create your first project", role: .heading, name: "emptyTitle")
        let emptyText = Label("A project keeps your scenes, assets and game code together in one folder. "
                              + "Start from a template, or open a project you already have.", role: .secondary, name: "emptyText")
        emptyText.wraps = true
        emptyText.alignment = .center
        emptyText.style.maxWidth = 380
        let emptyNew = Button("New Project…", role: .primary, name: "emptyNew")
        let emptyOpen = Button("Open…", name: "emptyOpen")
        emptyNew.icon = EditorIcons.named("folder-plus")
        emptyOpen.icon = EditorIcons.named("folder-open")
        emptyState = VStack(spacing: 10, alignment: .center, name: "emptyState", [
            Spacer(), emptyIcon, emptyTitle, emptyText, HStack(spacing: 8, name: "emptyButtons", [emptyNew, emptyOpen]), Spacer(grow: 2),
        ])
        emptyState.style.grow = 1
        emptyState.isHidden = true
        recentPage = VStack(spacing: 10, name: "recentPage", [listHeader, list, noMatches, emptyState])
        recentPage.style.grow = 1

        // New Project
        func caption(_ text: String) -> Label { Label(text, role: .caption, name: "") }
        locationField.style.grow = 1
        locationField.style.shrink = 1
        locationField.style.minWidth = 120
        nameField.tooltip = "The project's name; also its folder's"
        locationField.tooltip = "The folder the project's folder goes in"
        locationBrowse.tooltip = "Pick the folder"
        let templateButtons = ProjectTemplate.allCases.map { template in
            let button = Button(template.title, name: "template-\(template.rawValue)")
            button.icon = EditorIcons.named(template.iconName)
            button.tooltip = template.summary
            return (template, button)
        }
        self.templateButtons = templateButtons
        let templates = HStack(spacing: 6, name: "templates", templateButtons.map(\.1))
        templateSummary.wraps = true
        newError.wraps = true
        newError.color = theme.errorTextColor
        newError.isHidden = true
        let cancelNew = Button("Cancel", name: "cancelNewProject")
        newPage = VStack(spacing: 8, name: "newProjectPage", [
            Label("New Project", role: .heading, name: "newProjectTitle"),
            caption("Name"), nameField,
            caption("Location"), HStack(spacing: 6, name: "locationRow", [locationField, locationBrowse]),
            caption("Template"), templates, templateSummary,
            newPathPreview, newError, Spacer(),
            HStack(spacing: 8, name: "newProjectButtons", [Spacer(), cancelNew, createButton]),
        ])
        newPage.style.grow = 1
        newPage.style.maxWidth = 620
        newPage.isHidden = true

        // Open
        openField.style.grow = 1
        openField.style.shrink = 1
        openField.style.minWidth = 120
        openField.tooltip = "A project folder (it holds Project.json), or the Project.json itself"
        openBrowse.tooltip = "Pick the folder"
        openStatus.wraps = true
        createHereButton.icon = EditorIcons.named("folder-plus")
        createHereButton.tooltip = "Make this folder a project (New Project with it filled in)"
        createHereButton.isHidden = true
        let cancelOpen = Button("Cancel", name: "cancelOpenProject")
        openPage = VStack(spacing: 8, name: "openProjectPage", [
            Label("Open Project", role: .heading, name: "openProjectTitle"),
            caption("Project folder"), HStack(spacing: 6, name: "openRow", [openField, openBrowse]),
            openStatus, HStack(spacing: 8, name: "createHereRow", [createHereButton, Spacer()]), Spacer(),
            HStack(spacing: 8, name: "openProjectButtons", [Spacer(), cancelOpen, openConfirm]),
        ])
        openPage.style.grow = 1
        openPage.style.maxWidth = 620
        openPage.isHidden = true

        // The pages stay at most 1100 points wide, centered in a big window (rows don't stretch across it).
        let pages = VStack(spacing: 10, name: "launcherPages", [recentPage, newPage, openPage])
        pages.style.grow = 10_000  // all the room, up to maxWidth; the spacers take the rest
        pages.style.shrink = 1
        pages.style.minWidth = 0
        pages.style.maxWidth = 1100
        let column = HStack(spacing: 0, alignment: .stretch, name: "launcherColumn", [Spacer(), pages, Spacer()])
        column.style.grow = 1
        let main = VStack(spacing: 10, padding: EdgeInsets(20), name: "launcherMain", [column])
        main.style.grow = 1
        main.style.shrink = 1
        main.style.minWidth = 0
        main.background = theme.fieldBackground
        let rule = Separator(.vertical)
        rule.style.alignSelf = .stretch
        view = HStack(spacing: 0, alignment: .stretch, name: "launcher", [sidebar, rule, main])
        view.style.grow = 1
        view.isHidden = true

        // Commands (introspection and parity).
        let tagged: [(Widget, CommandID)] = [
            (newButton, ProjectNewCommand.id), (emptyNew, ProjectNewCommand.id), (openButton, ProjectOpenCommand.id),
            (emptyOpen, ProjectOpenCommand.id), (continueButton, LauncherDismissCommand.id),
            (reopenCheckbox, LauncherSettingsCommand.id), (search, ProjectRecentListCommand.id),
            (nameField, ProjectNewCommand.id), (locationField, ProjectNewCommand.id), (locationBrowse, ProjectNewCommand.id),
            (createButton, ProjectNewCommand.id), (cancelNew, ProjectRecentListCommand.id),
            (openField, ProjectOpenCommand.id), (openBrowse, ProjectOpenCommand.id), (openConfirm, ProjectOpenCommand.id),
            (createHereButton, ProjectNewCommand.id), (cancelOpen, ProjectRecentListCommand.id),
        ] + templateButtons.map { ($0.1, ProjectNewCommand.id) }
        for (widget, id) in tagged { widget.command = id.rawValue }
        list.command = ProjectRecentListCommand.id.rawValue
        list.itemCommands = ["row": ProjectOpenCommand.id.rawValue, "menu": ProjectRecentListCommand.id.rawValue,
                             "pin": ProjectRecentPinCommand.id.rawValue, "remove": ProjectRecentRemoveCommand.id.rawValue,
                             "locate": ProjectRecentLocateCommand.id.rawValue]

        // Actions.
        newButton.action = { [unowned self] in showNewProject() }
        emptyNew.action = { [unowned self] in showNewProject() }
        openButton.action = { [unowned self] in showOpen() }
        emptyOpen.action = { [unowned self] in showOpen() }
        continueButton.action = { session.run(LauncherDismissCommand.self) }
        reopenCheckbox.onChange = { on in session.run(LauncherSettingsCommand.self, .init(reopenLastProject: on)) }
        search.onChange = { [unowned self] _ in sync() }
        search.onSubmit = { [unowned self] _ in
            if let first = list.entries.first { open(first) }
        }
        list.now = { session.recentProjects.now() }
        list.thumbnail = { [unowned app] entry in app.launcherThumbnail(entry) }
        list.onOpen = { [unowned self] entry in open(entry) }
        list.onRemove = { [unowned self] entry in remove(entry) }
        list.onTogglePin = { [unowned self] entry in
            session.run(ProjectRecentPinCommand.self, .init(path: entry.path, pinned: !entry.pinned))
            sync()
        }
        list.onLocate = { [unowned self] entry in locate(entry) }
        list.onMenu = { [unowned self] entry, rect in showMenu(for: entry, at: rect) }
        nameField.onChange = { [unowned self] _ in updateNewForm() }
        nameField.onSubmit = { [unowned self] _ in createProject() }
        locationField.onChange = { [unowned self] _ in updateNewForm() }
        locationField.onSubmit = { [unowned self] _ in createProject() }
        locationBrowse.action = { [unowned self] in
            if let url = FilePicker.chooseFolder(title: "Location", prompt: "Choose") {
                locationField.text = url.path
                updateNewForm()
            }
        }
        for (template, button) in templateButtons {
            button.action = { [unowned self] in
                self.template = template
                updateNewForm()
            }
        }
        createButton.action = { [unowned self] in createProject() }
        cancelNew.action = { [unowned self] in showRecent() }
        openField.onChange = { [unowned self] _ in updateOpenForm() }
        openField.onSubmit = { [unowned self] _ in confirmOpen() }
        openBrowse.action = { [unowned self] in
            if let url = FilePicker.chooseFolder(title: locating == nil ? "Open Project" : "Locate Project", prompt: "Open") {
                openField.text = url.path
                updateOpenForm()
            }
        }
        openConfirm.action = { [unowned self] in confirmOpen() }
        createHereButton.action = { [unowned self] in
            let url = EditorSession.url(forPath: openField.text)
            showNewProject(name: url.lastPathComponent, location: url.deletingLastPathComponent().path)
        }
        cancelOpen.action = { [unowned self] in showRecent() }
    }

    // MARK: Pages

    func showRecent() {
        page = .recent
        locating = nil
        sync()
        app.ui?.focus(list.entries.isEmpty ? nil : list)
        if list.selectedRow == nil, !list.entries.isEmpty { list.selectRow(0) }
    }

    func showNewProject(name: String? = nil, location: String? = nil) {
        page = .newProject
        let recent = app.session.recentProjects
        nameField.text = name ?? Self.unusedName("My Game", in: location ?? recent.newProjectLocation ?? RecentProjectList.defaultNewProjectLocation())
        locationField.text = location ?? recent.newProjectLocation ?? RecentProjectList.defaultNewProjectLocation()
        if template.unavailableReason != nil { template = .starter }
        newError.isHidden = true
        sync()
        app.ui?.focus(nameField)
        nameField.select(0..<nameField.text.count)
    }

    /// Open…: the folder picker (macOS, when no AI client drives the UI), else the Open form.
    func showOpen(locating entry: RecentProject? = nil) {
        if let url = FilePicker.chooseFolder(title: entry == nil ? "Open Project" : "Locate \(entry!.name)", prompt: "Open") {
            if let entry {
                if app.session.run(ProjectRecentLocateCommand.self, .init(path: entry.path, newPath: url.path)) != nil { sync() }
            } else {
                openProject(path: url.path)
            }
            return
        }
        page = .open
        locating = entry?.path
        openField.text = entry.map { URL(fileURLWithPath: $0.path).deletingLastPathComponent().path }
            ?? app.session.recentProjects.entries.first.map { URL(fileURLWithPath: $0.path).deletingLastPathComponent().path } ?? ""
        sync()
        app.ui?.focus(openField)
    }

    /// The page and the list, from the session.
    func sync() {
        let recent = app.session.recentProjects
        recentPage.isHidden = page != .recent
        newPage.isHidden = page != .newProject
        openPage.isHidden = page != .open
        if reopenCheckbox.isOn != recent.reopensLastProject { reopenCheckbox.isOn = recent.reopensLastProject }
        let entries = recent.filtered(search.text)
        list.entries = entries
        let none = recent.entries.isEmpty
        if emptyState.isHidden != !none { emptyState.isHidden = !none }
        if listHeader.isHidden != none { listHeader.isHidden = none }
        let hideList = none || entries.isEmpty
        if list.isHidden != hideList { list.isHidden = hideList }
        let noMatch = !none && entries.isEmpty
        noMatches.text = noMatch ? "No projects match \u{201C}\(search.text)\u{201D}" : ""
        if noMatches.isHidden != !noMatch { noMatches.isHidden = !noMatch }
        if page == .newProject { updateNewForm() }
        if page == .open { updateOpenForm() }
        let browse = FilePicker.isAvailable
        if locationBrowse.isHidden == browse { locationBrowse.isHidden = !browse }
        if openBrowse.isHidden == browse { openBrowse.isHidden = !browse }
    }

    /// "My Game", else "My Game 2"… whichever has no folder in `location` yet.
    static func unusedName(_ base: String, in location: String) -> String {
        let folder = EditorSession.url(forPath: location)
        var name = base, n = 2
        while FileManager.default.fileExists(atPath: folder.appendingPathComponent(name).path) && n < 1000 {
            name = "\(base) \(n)"
            n += 1
        }
        return name
    }

    private func updateNewForm() {
        let theme = app.ui?.theme ?? UITheme()
        for (template, button) in templateButtons {
            let role: Button.Role = template == self.template ? .primary : .normal
            if button.role != role { button.role = role }
            let enabled = template.unavailableReason == nil
            if button.isEnabled != enabled { button.isEnabled = enabled }
        }
        let summary = template.summary
        if templateSummary.text != summary { templateSummary.text = summary }
        let name = nameField.text.trimmingCharacters(in: .whitespaces)
        let location = locationField.text.trimmingCharacters(in: .whitespaces)
        let target = EditorSession.url(forPath: (location.isEmpty ? "." : location) + "/" + name)
        var problem: String?
        if name.isEmpty {
            problem = "Give the project a name."
        } else if name.contains("/") || name.contains("\\") {
            problem = "The name can't contain slashes (it names the folder)."
        } else if Project.exists(at: target) {
            problem = "There is already a project at \(RecentProjectsListView.abbreviated(target.path)): Open… opens it."
        }
        let preview = "Creates " + RecentProjectsListView.abbreviated(target.path)
        if newPathPreview.text != preview { newPathPreview.text = name.isEmpty ? "" : preview }
        newPathPreview.isHidden = name.isEmpty
        createButton.isEnabled = problem == nil
        createButton.tooltip = problem ?? "Create the project and open it"
        // The error line shows what Create refused, or a problem with what was typed (not "no name yet").
        if let problem, !name.isEmpty {
            newError.text = problem
            newError.color = theme.errorTextColor
            newError.isHidden = false
        } else if newError.text.hasPrefix("There is") || newError.text.hasPrefix("The name") {
            newError.isHidden = true
        }
    }

    private func updateOpenForm() {
        let theme = app.ui?.theme ?? UITheme()
        let text = openField.text.trimmingCharacters(in: .whitespaces)
        var url = EditorSession.url(forPath: text)
        if url.lastPathComponent == Project.fileName { url.deleteLastPathComponent() }
        var isFolder: ObjCBool = false
        let exists = !text.isEmpty && FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder)
        let status: String
        var ok = false, canCreate = false, error = false
        if text.isEmpty {
            status = locating != nil ? "Where is the project now? Its folder holds Project.json." : "Type or paste a project folder."
        } else if Project.exists(at: url) {
            let project = try? Project.open(at: url)
            ok = project != nil
            status = project.map { "\($0.name)" + ($0.settings.game != nil ? " · game code" : "") + " · \(RecentProjectsListView.abbreviated($0.root.path))" }
                ?? "Project.json there can't be read."
            error = project == nil
        } else if exists && isFolder.boolValue {
            status = "This folder isn't a project (it has no Project.json)."
            canCreate = locating == nil
            error = true
        } else {
            status = "No such folder."
            error = true
        }
        if openStatus.text != status { openStatus.text = status }
        openStatus.color = error ? theme.errorTextColor : nil
        openConfirm.title = locating != nil ? "Locate" : "Open"
        openConfirm.isEnabled = ok
        openConfirm.tooltip = ok ? (locating != nil ? "Point the recent project at this folder" : "Open the project") : status
        if createHereButton.isHidden == canCreate { createHereButton.isHidden = !canCreate }
    }

    // MARK: Actions

    /// Opens a recent project with its last scene (`project.open {openLastScene: true}`); a
    /// missing one offers Locate….
    func open(_ entry: RecentProject) {
        guard !entry.isMissing else {
            locate(entry)
            return
        }
        openProject(path: entry.path)
    }

    private func openProject(path: String) {
        // Asks first when the project is from another engine version.
        app.openProjectAsking(.init(path: path, openLastScene: true)) { [weak self] opened in
            if opened { self?.app.hideLauncher() } else { self?.sync() }
        }
    }

    private func confirmOpen() {
        guard openConfirm.isEnabled else { return }
        if let locating {
            if app.session.run(ProjectRecentLocateCommand.self, .init(path: locating, newPath: openField.text)) != nil { showRecent() }
        } else {
            openProject(path: openField.text)
        }
    }

    func createProject() {
        updateNewForm()
        guard createButton.isEnabled else { return }
        let session = app.session
        let arguments = ProjectNewCommand.Arguments(name: nameField.text.trimmingCharacters(in: .whitespaces),
                                                    location: locationField.text.trimmingCharacters(in: .whitespaces), template: template)
        if session.run(ProjectNewCommand.self, arguments) != nil {
            app.hideLauncher()
        } else {
            newError.text = session.log.entries.last { $0.level == .error }?.message ?? "Couldn't create the project."
            newError.color = (app.ui?.theme ?? UITheme()).errorTextColor
            newError.isHidden = false
        }
    }

    func remove(_ entry: RecentProject) {
        let row = list.selectedRow
        app.session.run(ProjectRecentRemoveCommand.self, .init(path: entry.path))
        sync()
        if let row, !list.entries.isEmpty { list.selectRow(min(row, list.entries.count - 1)) }
        if list.entries.isEmpty, app.ui?.focusedWidget === list { app.ui?.focus(nil) }
    }

    func locate(_ entry: RecentProject) {
        showOpen(locating: entry)
    }

    /// The row's menu: Open, Show in Finder (macOS), Copy Path, Pin / Unpin, Remove from List
    /// (Locate… first for a missing folder).
    func showMenu(for entry: RecentProject, at rect: UIRect) {
        guard let ui = app.ui else { return }
        let session = app.session
        var items: [(title: String, icon: String?, command: CommandID, enabled: Bool, action: () -> Void)] = []
        if entry.isMissing {
            items.append(("Locate…", "folder-search", ProjectRecentLocateCommand.id, true, { [unowned self] in locate(entry) }))
        } else {
            items.append(("Open", "folder-open", ProjectOpenCommand.id, true, { [unowned self] in open(entry) }))
        }
        #if os(macOS)
        items.append(("Show in Finder", "folder", ProjectRecentRevealCommand.id, !entry.isMissing, {
            session.run(ProjectRecentRevealCommand.self, .init(path: entry.path))
        }))
        #endif
        items.append(("Copy Path", "copy", ProjectRecentListCommand.id, true, { [unowned ui] in ui.clipboard.string = entry.path }))
        items.append((entry.pinned ? "Unpin" : "Pin", "pin", ProjectRecentPinCommand.id, true, { [unowned self] in
            session.run(ProjectRecentPinCommand.self, .init(path: entry.path, pinned: !entry.pinned))
            sync()
        }))
        items.append(("Remove from List", "x", ProjectRecentRemoveCommand.id, true, { [unowned self] in remove(entry) }))
        let menu = PopupMenu(items: items.map(\.title), name: "projectMenu")
        menu.itemCommandIDs = items.map { $0.command.rawValue }
        menu.itemIcons = items.map { $0.icon.map(EditorIcons.named) }
        menu.disabledIndices = Set(items.indices.filter { !items[$0].enabled })
        menu.anchorRect = rect
        menu.onSelect = { index in items[index].action() }
        ui.presentOverlay(menu)
    }

    /// Keys the launcher takes before the widgets: Cmd/Ctrl+N, +O, +F, and Esc on a form.
    /// Returns whether it used the key.
    func handleShortcut(_ event: KeyEvent) -> Bool {
        let mods = event.modifiers
        if mods == .shortcut {
            switch event.key {
            case .n: showNewProject()
            case .o: showOpen()
            case .f:
                page = .recent
                sync()
                app.ui?.focus(search)
            default: return false
            }
            return true
        }
        if event.key == .escape, mods.isEmpty, page != .recent {
            showRecent()
            return true
        }
        return false
    }
}
