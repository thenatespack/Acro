import Engine
import Foundation

/// The Files panel: the project's scenes and scripts as a folder tree (`files.list`). Clicking a
/// scene opens it in the Scene view, clicking a script opens it in the Scripts editor tabbed
/// with it (`files.open`). New Scene (`files.newScene`) and New Script (`script.new`) make files:
/// this panel is where scenes are created and switched.
@MainActor
public final class FilesPanel {
    public unowned let session: EditorSession
    public let view: VStack
    public let tree: TreeView
    /// What the tree shows.
    public private(set) var files: [ProjectFile] = []
    /// Opens a file the user clicked (the app asks before replacing a scene with unsaved changes);
    /// nil runs `files.open` directly.
    public var onOpen: ((ProjectFile) -> Void)?
    /// Makes a scene named in the name bar (the app asks first when the open one has unsaved
    /// changes); nil runs `files.newScene` directly.
    public var onNewScene: ((String) -> Void)?

    /// What the name bar makes.
    public enum NewKind: Sendable { case scene, script }
    /// What the name bar is open for; nil when it is hidden.
    public private(set) var naming: NewKind?
    private let nameBar: HStack
    private let nameField: TextField
    private let createButton: Button
    /// Folders the user collapsed, by shown path (new folders start expanded).
    private var collapsed = Set<String>()
    private var nodes: [String: TreeNode] = [:]
    private var lastScan: Date = .distantPast
    private var shownSelection: String?
    /// Set while the tree's selection follows the open file, so it doesn't open it again.
    private var isSyncingSelection = false

    public init(session: EditorSession) {
        self.session = session
        tree = TreeView(roots: [], name: "filesTree")
        tree.background = .clear
        tree.style.grow = 1
        tree.style.shrink = 1
        // Rows open their file; the triangles only show or hide a folder.
        tree.itemCommands = ["row": FilesOpenCommand.id.rawValue, "toggle": FilesListCommand.id.rawValue]

        let newSceneButton = Button("New Scene", name: "newScene")
        newSceneButton.icon = EditorIcons.named("clapperboard")
        newSceneButton.tooltip = "Create a scene in Assets/Scenes and open it"
        newSceneButton.command = FilesNewSceneCommand.id.rawValue
        let newScriptButton = Button("New Script", name: "newScript")
        newScriptButton.icon = EditorIcons.named("file-plus")
        newScriptButton.tooltip = "Create a new script in the game's sources and open it"
        newScriptButton.command = ScriptNewCommand.id.rawValue
        let refreshButton = Button("Refresh", name: "refreshFiles")
        refreshButton.icon = EditorIcons.named("refresh-cw")
        refreshButton.tooltip = "Look for new or removed scenes and scripts"
        refreshButton.command = FilesListCommand.id.rawValue
        for button in [newSceneButton, newScriptButton, refreshButton] { button.showsTitle = false }

        nameField = TextField(placeholder: "", name: "newFileName")
        nameField.style.grow = 1
        nameField.style.shrink = 1
        nameField.style.minWidth = 60
        createButton = Button("Create", role: .primary, name: "confirmNewFile")
        let cancelButton = Button("Cancel", name: "cancelNewFile")
        cancelButton.command = FilesListCommand.id.rawValue
        nameBar = HStack(spacing: 4, [nameField, createButton, cancelButton])
        nameBar.isHidden = true

        let header = HStack(spacing: 4, [Spacer(), newSceneButton, newScriptButton, refreshButton])
        view = VStack(spacing: 6, padding: EdgeInsets(6), name: "filesPanel", [header, nameBar, tree])

        newSceneButton.action = { [unowned self] in startNaming(.scene) }
        newScriptButton.action = { [unowned self] in startNaming(.script) }
        refreshButton.action = { [unowned self] in refresh(force: true) }
        cancelButton.action = { [unowned self] in stopNaming() }
        createButton.action = { [unowned self] in create() }
        nameField.onSubmit = { [unowned self] _ in create() }
        tree.onSelect = { [unowned self] node in
            guard !isSyncingSelection, let file = node?.userData as? ProjectFile else { return }
            open(file)
        }
        refresh(force: true)
    }

    /// Rescans the files every couple of seconds (or now, with `force`) and rebuilds the tree
    /// when they changed; selects the open scene or script.
    public func sync() {
        refresh(force: false)
        selectOpenFile()
    }

    public func refresh(force: Bool) {
        guard force || Date().timeIntervalSince(lastScan) > 2 else { return }
        lastScan = Date()
        let found = session.projectFiles()
        guard force || found != files else { return }
        files = found
        rebuild()
        shownSelection = nil
        selectOpenFile()
    }

    /// Opens `file` as a click on its row does.
    public func open(_ file: ProjectFile) {
        if let onOpen { onOpen(file) } else { session.run(FilesOpenCommand.self, .init(path: file.absolutePath)) }
    }

    /// The row showing `path` (a `ProjectFile.path`, or a folder's).
    public func node(for path: String) -> TreeNode? { nodes[path] }

    /// Shows the name bar for a new scene or script.
    public func startNaming(_ kind: NewKind) {
        naming = kind
        nameField.placeholder = kind == .scene ? "Level 2" : "CameraController"
        let command = kind == .scene ? FilesNewSceneCommand.id : ScriptNewCommand.id
        nameField.command = command.rawValue
        createButton.command = command.rawValue
        createButton.title = kind == .scene ? "Create Scene" : "Create Script"
        nameField.text = ""
        nameBar.isHidden = false
        nameField.context?.focus(nameField)
    }

    private func stopNaming() {
        naming = nil
        nameBar.isHidden = true
    }

    /// Makes the file the name bar names.
    public func create(named text: String? = nil) {
        let name = (text ?? nameField.text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let kind = naming, !name.isEmpty else { return }
        stopNaming()
        switch kind {
        case .scene:
            if let onNewScene { onNewScene(name) } else { session.run(FilesNewSceneCommand.self, .init(name: name)) }
        case .script:
            session.run(ScriptNewCommand.self, .init(name: name))
        }
        refresh(force: true)
    }

    private func rebuild() {
        // Keep what the user collapsed.
        for (path, node) in nodes where node.userData == nil {
            if node.isExpanded { collapsed.remove(path) } else { collapsed.insert(path) }
        }
        nodes = [:]
        var roots: [TreeNode] = []
        func folder(_ path: String) -> TreeNode? {
            guard !path.isEmpty else { return nil }
            if let node = nodes[path] { return node }
            let parentPath = (path as NSString).deletingLastPathComponent
            let node = TreeNode((path as NSString).lastPathComponent, isExpanded: !collapsed.contains(path))
            node.icon = EditorIcons.named("folder")
            nodes[path] = node
            if let parent = folder(parentPath) { parent.addChild(node) } else { roots.append(node) }
            return node
        }
        for file in files {
            let node = TreeNode((file.path as NSString).lastPathComponent, userData: file)
            node.icon = EditorIcons.named(file.kind == .scene ? "clapperboard" : "file-code")
            nodes[file.path] = node
            if let parent = folder((file.path as NSString).deletingLastPathComponent) { parent.addChild(node) } else { roots.append(node) }
        }
        tree.roots = roots
    }

    /// Selects the row of the script being edited when the Scripts editor is in front, else the open scene.
    private func selectOpenFile() {
        let app = session.uiApp
        let scriptsInFront = app.map { EditorLayout.activePanel(in: $0.dock.layout, groupOf: EditorLayout.scripts) == EditorLayout.scripts } ?? false
        let openPath = (scriptsInFront ? app?.scriptEditor.currentScriptURL?.standardizedFileURL.path : nil)
            ?? session.document.url?.standardizedFileURL.path
        guard openPath != shownSelection else { return }
        shownSelection = openPath
        let node = files.first { $0.absolutePath == openPath }.flatMap { nodes[$0.path] }
        guard tree.selectedNode !== node else { return }
        isSyncingSelection = true
        tree.select(node)
        isSyncingSelection = false
    }
}
