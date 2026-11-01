import Engine
import Foundation

/// One script file shown in the script editor.
public struct ScriptFile: Equatable, Sendable {
    public var name: String
    public var path: String
    public var url: URL

    public init(name: String, path: String, url: URL) {
        self.name = name
        self.path = path
        self.url = url
    }
}

/// The script editor panel: browse, write, edit, save, and reload game scripts directly in the editor.
@MainActor
public final class ScriptEditorPanel {
    public unowned let session: EditorSession
    public let view: Widget

    public let editor: CodeEditorWidget
    public let scroll: ScrollView
    public private(set) var currentScriptURL: URL?
    public private(set) var isDirty: Bool = false {
        didSet {
            if isDirty != oldValue {
                updateHeader()
            }
        }
    }

    public private(set) var files: [ScriptFile] = []

    private let fileList: ListView
    private let titleLabel: Label
    private let dirtyLabel: Label
    private let statusLabel: Label
    private let saveButton: Button
    private let reloadButton: Button
    private let newScriptBar: HStack
    private let newScriptField: TextField
    private let errorBanner: HStack
    private let errorLabel: Label

    private var lastScannedDate: Date = .distantPast
    private var lastKnownReport: GameReloadReport?
    private var lastKnownError: String?

    public init(session: EditorSession) {
        self.session = session

        editor = CodeEditorWidget(name: "scriptCodeEditor")
        scroll = ScrollView(editor, name: "scriptEditorScroll")
        scroll.scrollsHorizontally = true
        scroll.style.grow = 1
        scroll.style.shrink = 1

        fileList = ListView(items: [], name: "scriptFileList")
        fileList.style.grow = 1

        titleLabel = Label("No script open", role: .heading, name: "scriptTitleLabel")
        dirtyLabel = Label("", role: .body, name: "scriptDirtyLabel")
        dirtyLabel.color = UIColor(hex: 0xffa657)

        statusLabel = Label("Ready", role: .caption, name: "scriptStatusLabel")
        statusLabel.color = UIColor(hex: 0x8b949e)

        saveButton = Button("Save", name: "scriptSaveButton")
        saveButton.icon = EditorIcons.named("save")
        saveButton.tooltip = "Save script (Cmd+S)"
        saveButton.command = "script.save"

        reloadButton = Button("Reload Game", name: "scriptReloadButton")
        reloadButton.icon = EditorIcons.named("rotate-cw")
        reloadButton.tooltip = "Rebuild and hot reload game code"
        reloadButton.command = "game.reload"

        let newButton = Button("+", name: "scriptNewButton")
        newButton.tooltip = "Create a new script"
        newButton.style.width = 26

        newScriptField = TextField(placeholder: "MyComponent.swift", name: "newScriptName")
        newScriptField.style.grow = 1

        let createButton = Button("Create", name: "confirmCreateScript")
        createButton.role = .primary

        let cancelButton = Button("Cancel", name: "cancelCreateScript")

        newScriptBar = HStack(spacing: 4, padding: EdgeInsets(4), [
            newScriptField, createButton, cancelButton
        ])
        newScriptBar.isHidden = true

        errorLabel = Label("", role: .caption, name: "scriptErrorLabel")
        errorLabel.color = UIColor(hex: 0xff7b72)
        errorLabel.wraps = true

        let dismissErrorButton = Button("Dismiss", name: "dismissScriptError")
        dismissErrorButton.style.width = 60

        errorBanner = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            errorLabel, Spacer(), dismissErrorButton
        ])
        errorBanner.background = UIColor(hex: 0x3d1418)
        errorBanner.isHidden = true

        // Sidebar
        let sidebarTitle = Label("Scripts", role: .heading, name: "scriptsSidebarHeading")
        let sidebarHeader = HStack(spacing: 4, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            sidebarTitle, Spacer(), newButton
        ])
        let sidebar = VStack(spacing: 4, padding: EdgeInsets(top: 4, left: 4, bottom: 4, right: 0), [
            sidebarHeader, newScriptBar, fileList
        ])
        sidebar.style.width = 160
        sidebar.style.minWidth = 120

        // Right pane
        let editorToolbar = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            titleLabel, dirtyLabel, Spacer(), statusLabel, saveButton, reloadButton
        ])
        let rightPane = VStack(spacing: 2, padding: EdgeInsets(0), [
            editorToolbar, errorBanner, scroll
        ])
        rightPane.style.grow = 1

        let split = SplitView(.horizontal, panes: [sidebar, rightPane], fractions: [0.22, 0.78], minSizes: [120, 200])
        view = split

        // Wiring callbacks
        editor.onChange = { [weak self] _ in
            self?.isDirty = true
        }

        editor.onSave = { [weak self] in
            self?.save()
        }

        saveButton.action = { [weak self] in
            self?.save()
        }

        reloadButton.action = { [weak self] in
            self?.reloadGame()
        }

        newButton.action = { [weak self] in
            guard let self else { return }
            self.newScriptBar.isHidden = false
            self.newScriptField.text = ""
        }

        cancelButton.action = { [weak self] in
            self?.newScriptBar.isHidden = true
        }

        createButton.action = { [weak self] in
            self?.confirmNewScript()
        }

        newScriptField.onSubmit = { [weak self] _ in
            self?.confirmNewScript()
        }

        dismissErrorButton.action = { [weak self] in
            self?.errorBanner.isHidden = true
        }

        fileList.onSelect = { [weak self] index in
            guard let self, let index, self.files.indices.contains(index) else { return }
            let file = self.files[index]
            if file.url != self.currentScriptURL {
                self.openScript(at: file.url)
            }
        }

        refreshFiles()
        if let first = files.first {
            openScript(at: first.url)
        }
    }

    public func refreshFiles() {
        var found: [ScriptFile] = []
        var seen = Set<String>()

        func addFile(_ url: URL, base: URL) {
            let standard = url.standardizedFileURL
            guard standard.pathExtension == "swift" else { return }
            guard !seen.contains(standard.path) else { return }
            seen.insert(standard.path)

            let rel: String
            if standard.path.hasPrefix(base.standardizedFileURL.path) {
                rel = String(standard.path.dropFirst(base.standardizedFileURL.path.count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            } else {
                rel = standard.lastPathComponent
            }
            found.append(ScriptFile(name: standard.lastPathComponent, path: rel, url: standard))
        }

        func scanDirectory(_ dir: URL) {
            guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey],
                                                                 options: [.skipsHiddenFiles]) else { return }
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "swift" {
                    addFile(fileURL, base: dir)
                }
            }
        }

        // 1. Game module target sources
        if let settings = session.gameModule.settings, let target = settings.target,
           let packageURL = try? session.gameModule.packageURL() {
            let targetDir = packageURL.appendingPathComponent("Sources/\(target)", isDirectory: true)
            scanDirectory(targetDir)
        }

        // 2. Project sources and scripts
        if let project = session.project {
            scanDirectory(project.root.appendingPathComponent("Sources", isDirectory: true))
            scanDirectory(project.root.appendingPathComponent("Scripts", isDirectory: true))
        }

        // 3. Fallback to startFolder Sources / Scripts
        scanDirectory(session.startFolder.appendingPathComponent("Sources", isDirectory: true))
        scanDirectory(session.startFolder.appendingPathComponent("Scripts", isDirectory: true))

        found.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        files = found
        fileList.items = files.map(\.name)

        if let current = currentScriptURL, let idx = files.firstIndex(where: { $0.url == current }) {
            fileList.selectRow(idx, reveal: false)
        }
    }

    public func openScript(at url: URL) {
        if isDirty {
            save()
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            session.log.warning("Could not read script at \(url.path)")
            return
        }

        currentScriptURL = url
        editor.text = content
        isDirty = false
        updateHeader()

        if let idx = files.firstIndex(where: { $0.url == url }) {
            fileList.selectRow(idx, reveal: true)
        }
    }

    public func save() {
        guard let url = currentScriptURL else { return }
        do {
            try editor.text.write(to: url, atomically: true, encoding: .utf8)
            isDirty = false
            statusLabel.text = "Saved"
            statusLabel.color = UIColor(hex: 0x7ee787)
            session.log.info("Saved script \(url.lastPathComponent)")
        } catch {
            session.log.error("Failed to save script \(url.lastPathComponent): \(error)")
            statusLabel.text = "Save failed"
            statusLabel.color = UIColor(hex: 0xff7b72)
        }
    }

    public func reloadGame() {
        if isDirty {
            save()
        }
        statusLabel.text = "Rebuilding..."
        statusLabel.color = UIColor(hex: 0xffa657)

        do {
            let future = try session.commands.start(GameReloadCommand.self, .init(build: true))
            future.onFinish { [weak self] outcome in
                guard let self else { return }
                switch outcome {
                case .success(let report):
                    self.statusLabel.text = "Reloaded (\(String(format: "%.2f", report.totalSeconds))s)"
                    self.statusLabel.color = UIColor(hex: 0x7ee787)
                    self.errorBanner.isHidden = true
                case .failure(let error):
                    self.statusLabel.text = "Build error"
                    self.statusLabel.color = UIColor(hex: 0xff7b72)
                    self.errorLabel.text = "\(error)"
                    self.errorBanner.isHidden = false
                }
            }
        } catch {
            statusLabel.text = "Rebuild failed"
            statusLabel.color = UIColor(hex: 0xff7b72)
            errorLabel.text = "\(error)"
            errorBanner.isHidden = false
        }
    }

    private func confirmNewScript() {
        var rawName = newScriptField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawName.isEmpty else { return }
        if !rawName.hasSuffix(".swift") {
            rawName += ".swift"
        }

        let componentName = String(rawName.dropLast(".swift".count))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "_")

        let destinationDir: URL
        if let target = session.gameModule.settings?.target, let packageURL = try? session.gameModule.packageURL() {
            destinationDir = packageURL.appendingPathComponent("Sources/\(target)", isDirectory: true)
        } else if let project = session.project {
            destinationDir = project.root.appendingPathComponent("Sources/\(project.name)", isDirectory: true)
        } else {
            destinationDir = session.startFolder.appendingPathComponent("Scripts", isDirectory: true)
        }

        let fileURL = destinationDir.appendingPathComponent(rawName)
        let template = """
        import Engine
        import Foundation

        /// Custom game component.
        public struct \(componentName): Component, Equatable, Sendable {
            public static let componentName = "\(componentName)"
            public static var fieldHints: [String: FieldHints] {
                ["speed": FieldHints(range: 0...20, step: 0.1, tooltip: "Movement speed")]
            }

            public var speed: Float = 2.0

            public init(speed: Float = 2.0) {
                self.speed = speed
            }
        }

        """

        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            try template.write(to: fileURL, atomically: true, encoding: .utf8)
            newScriptBar.isHidden = true
            session.log.info("Created script \(rawName)")
            refreshFiles()
            openScript(at: fileURL)
        } catch {
            session.log.error("Failed to create script: \(error)")
        }
    }

    private func updateHeader() {
        if let url = currentScriptURL {
            titleLabel.text = url.lastPathComponent
            dirtyLabel.text = isDirty ? "●" : ""
        } else {
            titleLabel.text = "No script open"
            dirtyLabel.text = ""
        }
    }

    public func sync() {
        // Check for newly added or removed script files periodically
        if Date().timeIntervalSince(lastScannedDate) > 3.0 {
            lastScannedDate = Date()
            refreshFiles()
        }

        // Check if game module reload error status changed
        if let err = session.gameModule.lastError, err != lastKnownError {
            lastKnownError = err
            errorLabel.text = err
            errorBanner.isHidden = false
        } else if session.gameModule.lastError == nil && lastKnownError != nil {
            lastKnownError = nil
            errorBanner.isHidden = true
        }

        if let rep = session.gameModule.lastReport, rep != lastKnownReport {
            lastKnownReport = rep
            statusLabel.text = "Reloaded (\(String(format: "%.2f", rep.totalSeconds))s)"
            statusLabel.color = UIColor(hex: 0x7ee787)
        }
    }

    public func recolor() {
        view.setNeedsDisplay()
        editor.setNeedsDisplay()
    }
}
