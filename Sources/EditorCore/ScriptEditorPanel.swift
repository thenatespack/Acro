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

        let dismissErrorButton = Button("Dismiss", name: "dismissScriptError")
        dismissErrorButton.style.width = 60

        errorBanner = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 4), [
            errorLabel, Spacer(), dismissErrorButton
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

        dismissErrorButton.action = { [weak self] in
            self?.errorBanner.isHidden = true
        }

        updateHeader()
    }

    public func openScript(at url: URL) {
        guard session.isProjectScript(url.standardizedFileURL) else {
            session.log.warning("Not opening \(url.path): only the project's own scripts can be edited here")
            return
        }
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
