import Engine
import Foundation

// What the UI tools (EditorUICommands.swift) and the MCP server need from the app: bringing the
// panels up to date, key presses routed like real ones, synthetic pointer input for the 3D
// viewport, asking the user about an AI call, and the status bar that shows AI activity.

extension EditorApp {
    /// Brings the panels up to date with the session, as every frame does after input.
    public func syncPanels() {
        if isLauncherShown { launcher.sync() }
        hierarchy.sync()
        assetBrowser.sync()
        inspector.refresh()
        console.refresh()
        activity.refresh()
        statusBar.refresh()
        toolbar.refresh()
        ui.layoutIfNeeded()
        updateViewportCaption()
    }

    /// A key press as if typed: the focused widget or the topmost popup gets it first, then the
    /// editor's shortcuts, with the same rules as real keys (`update`).
    public func pressKey(_ event: KeyEvent) {
        let textBefore = ui.focusedWidget?.wantsTextInput == true
        let focusedBefore = ui.focusedWidget != nil, overlayBefore = !ui.overlays.isEmpty
        ui.synthesizeKey(event)
        let focus = EditorShortcuts.Focus(textEditing: textBefore || ui.focusedWidget?.wantsTextInput == true,
                                          overlayOpen: overlayBefore, widgetFocused: focusedBefore)
        let suppressed = FilePicker.isSuppressed
        FilePicker.isSuppressed = true
        defer { FilePicker.isSuppressed = suppressed }
        if isLauncherShown {
            if !overlayBefore { _ = launcher.handleShortcut(event) }
            launcher.sync()
            ui.layoutIfNeeded()
            return
        }
        for command in shortcuts.actions(for: [event], focus: focus) { invoke(command) }
        ui.layoutIfNeeded()
    }

    /// Whether `point` is on the 3D viewport, which lets the pointer through to the scene.
    public func isViewportPoint(_ point: Vec2) -> Bool {
        viewportWidget.isEffectivelyVisible && viewportWidget.frame.contains(point) && ui.hitTest(point) == nil
    }

    /// One frame of synthetic pointer input for the viewport.
    public struct ViewportFrame {
        public var position: Vec2
        public var pressed: Set<MouseButton> = []
        public var released: Set<MouseButton> = []
        public var down: Set<MouseButton> = []
        public var scroll: Vec2 = .zero

        public init(position: Vec2, pressed: Set<MouseButton> = [], released: Set<MouseButton> = [],
                    down: Set<MouseButton> = [], scroll: Vec2 = .zero) {
            self.position = position
            self.pressed = pressed
            self.released = released
            self.down = down
            self.scroll = scroll
        }
    }

    /// Feeds `frames` to the viewport (`ViewportController.update`, its tools and camera) as
    /// real input would arrive, one frame each. Refused while the viewport shows the game.
    public func viewportPointer(_ frames: [ViewportFrame], modifiers: KeyModifiers) throws {
        if session.isPlaying, session.showsGameCamera, RenderPrep.findCamera(in: session.gameWorld) != nil {
            throw CommandError.failed("The viewport shows the game while playing (Game View): use input.inject, or view.gameCamera {enabled: false}")
        }
        viewport.rect = viewportWidget.frame
        var last = frames.first?.position ?? .zero
        for frame in frames {
            var input = ViewportInput(mousePosition: frame.position)
            input.mouseDelta = frame.position - last
            input.pressed = frame.pressed
            input.released = frame.released
            input.down = frame.down
            input.scroll = frame.scroll
            input.modifiers = modifiers
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
            last = frame.position
        }
        session.tick(dt: 0)
    }

    /// Uses `mcp` as the app's MCP server (tests: the status bar without a transport).
    func attachMCPForTesting(_ mcp: EditorMCP) {
        self.mcp = mcp
    }

    /// Asks the user whether an AI client may run a destructive call; nil when there is no UI
    /// to ask in. The future is true for Allow.
    public func askToAllowAICall(title: String, message: String) -> CommandFuture<Bool>? {
        guard ui != nil else { return nil }
        let future = CommandFuture<Bool>()
        let dialog = ConfirmDialog(title: title, message: message, confirmTitle: "Allow", name: "aiConfirmDialog")
        dialog.onConfirm = { future.resolve(true) }
        dialog.onCancel = { future.resolve(false) }
        dialog.present(in: ui)
        return future
    }
}

/// The strip under the dock: whether an AI client is connected or acting (shown while the MCP
/// server runs).
@MainActor
final class StatusBar {
    let view: HStack
    let aiStatus = Label("", role: .caption, name: "aiStatus")
    private unowned let app: EditorApp

    init(app: EditorApp) {
        self.app = app
        let theme = app.ui?.theme ?? UITheme()
        aiStatus.tooltip = "AI clients (MCP): what they are doing; the Activity panel lists every call"
        view = HStack(spacing: 12, padding: EdgeInsets(horizontal: 10, vertical: 3), name: "statusBar", [buildStatus, Spacer(), aiStatus])
        view.background = theme.panelBackground
        refresh()
    }

    /// "Building game code…" / "Exporting the game…" while a build runs.
    let buildStatus: Label = {
        let label = Label("", role: .caption, name: "buildStatus")
        label.tooltip = "Game code or a game export is being built; progress is on the console"
        label.icon = EditorIcons.named("hammer")
        return label
    }()

    func refresh() {
        let status = Self.status(app: app)
        let building = Self.buildingStatus(app: app)
        let hidden = status == nil && building == nil
        if view.isHidden != hidden { view.isHidden = hidden }
        if buildStatus.isHidden != (building == nil) { buildStatus.isHidden = building == nil }
        if let building, buildStatus.text != building { buildStatus.text = building }
        if aiStatus.isHidden != (status == nil) { aiStatus.isHidden = status == nil }
        guard let status else { return }
        if aiStatus.text != status.text { aiStatus.text = status.text }
        // The icon says the state at a glance: waiting, connected, or an agent acting.
        let icon = EditorIcons.named(status.acting ? "bot" : status.connected ? "plug-zap" : "plug")
        if aiStatus.icon != icon { aiStatus.icon = icon }
        // The accent is a fill color; as small text it needs lifting toward the text color to read.
        let theme = app.ui.theme
        let color: UIColor? = status.acting ? theme.accent.mixed(with: theme.textColor, 0.4) : nil
        if aiStatus.color != color { aiStatus.color = color }
    }

    /// What is being built, or nil.
    static func buildingStatus(app: EditorApp) -> String? {
        let session = app.session
        if session.gameModule.isBusy { return "Building game code…" }
        if session.gameExport.isBusy { return "Exporting the game…" }
        return nil
    }

    /// The status text and whether an agent is acting right now; nil without an MCP server.
    static func status(app: EditorApp) -> (text: String, acting: Bool, connected: Bool)? {
        guard let mcp = app.mcp else { return nil }
        let session = app.session
        let running = session.activity.running
        let acting = running != nil || session.activity.wasActive(within: 1.5)
        var text: String
        if mcp.server.clientCount == 0 && running == nil {
            if let http = mcp.http {
                text = "AI: waiting for a client on \(http.url)"
            } else {
                text = mcp.stdio != nil ? "AI: waiting for the client" : "AI: off"
            }
        } else if acting {
            text = "AI acting: " + (running ?? session.activity.entries.last?.tool ?? "")
        } else {
            let names = mcp.server.clientNames
            text = "AI connected" + (names.isEmpty ? "" : " (\(names.joined(separator: ", ")))")
        }
        if session.aiSettings.readOnly { text += " · read-only" }
        return (text, acting, mcp.server.clientCount > 0 || running != nil)
    }
}
