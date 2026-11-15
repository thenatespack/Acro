import Engine
import Foundation

/// The script editor panel: write, edit, save and reload a game script. It sits with the Scene
/// view; the Files panel (`FilesPanel`) picks which script it shows.
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

    private let titleLabel: Label
    private let dirtyLabel: Label
    private let statusLabel: Label
    private let saveButton: Button
    private let reloadButton: Button
    private let errorBanner: HStack
    private let errorLabel: Label
    private let goToErrorButton: Button
    /// The errors the banner shows, for Go to Error.
    public private(set) var shownDiagnostics: [GameBuildDiagnostic] = []

    private var lastKnownReport: GameReloadReport?
    private var lastKnownError: String?

    public init(session: EditorSession) {
        self.session = session

        editor = CodeEditorWidget(name: "scriptCodeEditor")
        scroll = ScrollView(editor, name: "scriptEditorScroll")
        scroll.scrollsHorizontally = true
        scroll.style.grow = 1
        scroll.style.shrink = 1

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

        errorLabel = Label("", role: .caption, name: "scriptErrorLabel")
        errorLabel.color = UIColor(hex: 0xff7b72)
        errorLabel.wraps = true

        goToErrorButton = Button("Go to Error", name: "scriptGoToErrorButton")
        goToErrorButton.tooltip = "Open the first error's file at its line"
        goToErrorButton.isHidden = true

        let dismissErrorButton = Button("Dismiss", name: "dismissScriptError")
        dismissErrorButton.style.width = 60

        errorBanner = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            errorLabel, Spacer(), goToErrorButton, dismissErrorButton
        ])
        errorBanner.background = UIColor(hex: 0x3d1418)
        errorBanner.isHidden = true

        // The open script's name and actions above the code
        let editorToolbar = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            titleLabel, dirtyLabel, Spacer(), statusLabel, saveButton, reloadButton
        ])
        let pane = VStack(spacing: 2, padding: EdgeInsets(0), name: "scriptEditorPanel", [
            editorToolbar, errorBanner, scroll
        ])
        pane.style.grow = 1
        view = pane

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

        goToErrorButton.action = { [weak self] in
            self?.goToFirstError()
        }

        dismissErrorButton.action = { [weak self] in
            self?.hideError()
        }

        updateHeader()
    }

    public func openScript(at url: URL) {
        guard session.isProjectScript(url.standardizedFileURL) else {
            let message = "Can't open \(url.lastPathComponent): only .swift files in the project's script folders can be edited here"
            session.log.warning(message)
            showError(message)
            return
        }
        if isDirty {
            save()
        }
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            let message = "Couldn't read \(url.lastPathComponent): \(error.localizedDescription)"
            session.log.warning(message)
            showError(message)
            return
        }

        currentScriptURL = url
        editor.text = content
        isDirty = false
        updateHeader()
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
            let message = "Couldn't save \(url.lastPathComponent): \(error.localizedDescription)"
            session.log.error(message)
            statusLabel.text = "Save failed"
            statusLabel.color = UIColor(hex: 0xff7b72)
            showError(message)
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
                    self.hideError()
                case .failure(let error):
                    let diagnostics = self.session.gameModule.lastDiagnostics
                    self.statusLabel.text = diagnostics.isEmpty ? "Build error" : "\(diagnostics.count) error\(diagnostics.count == 1 ? "" : "s")"
                    self.statusLabel.color = UIColor(hex: 0xff7b72)
                    self.showError("\(error)", diagnostics: diagnostics)
                }
            }
        } catch {
            statusLabel.text = "Can't rebuild"
            statusLabel.color = UIColor(hex: 0xff7b72)
            showError("\(error)")
        }
    }

    /// Shows `message` in the error banner; with `diagnostics`, Go to Error jumps to the first.
    public func showError(_ message: String, diagnostics: [GameBuildDiagnostic] = []) {
        errorLabel.text = message
        shownDiagnostics = diagnostics
        goToErrorButton.isHidden = diagnostics.isEmpty
        errorBanner.isHidden = false
    }

    private func hideError() {
        errorBanner.isHidden = true
        shownDiagnostics = []
        goToErrorButton.isHidden = true
    }

    /// Opens the first shown error's file (preferring one in the open script) at its line.
    public func goToFirstError() {
        let current = currentScriptURL?.standardizedFileURL.path
        guard let diagnostic = shownDiagnostics.first(where: { URL(fileURLWithPath: $0.file).standardizedFileURL.path == current })
                ?? shownDiagnostics.first else { return }
        let url = URL(fileURLWithPath: diagnostic.file).standardizedFileURL
        guard session.isProjectScript(url) else {
            session.log.warning("\(diagnostic.summary) (\(url.path) isn't a project script, so it can't be opened here)")
            return
        }
        let diagnostics = shownDiagnostics
        if currentScriptURL?.standardizedFileURL != url { openScript(at: url) }
        guard currentScriptURL?.standardizedFileURL == url else { return }
        editor.goTo(line: diagnostic.line, column: diagnostic.column)
        showError(errorLabel.text, diagnostics: diagnostics)
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
        // Check if game module reload error status changed
        if let err = session.gameModule.lastError, err != lastKnownError {
            lastKnownError = err
            showError(err, diagnostics: session.gameModule.lastDiagnostics)
        } else if session.gameModule.lastError == nil && lastKnownError != nil {
            lastKnownError = nil
            hideError()
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
