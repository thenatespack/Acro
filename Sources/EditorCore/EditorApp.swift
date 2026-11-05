import Engine
import Foundation

/// How the editor starts.
public struct EditorOptions: Sendable {
    /// A scene file to open; nil starts with the starter scene.
    public var scenePath: String?
    /// A project folder to open (`--project`); nil starts without a project.
    public var projectPath: String?
    /// Deterministic start for `ENGINE_SCREENSHOT` runs: default layout (prefs neither read nor
    /// written), sequential entity ids, the starter scene with an entity selected, a fixed
    /// camera and no caret blinking, so screenshots match across runs and backends.
    public var deterministic: Bool
    /// Where the dock layout is persisted; nil doesn't persist it.
    public var prefsURL: URL?
    /// An asset to select in the browser (and show in the inspector) at startup, by path
    /// relative to `Assets/`: a folder opens it, a file selects it in its folder, and
    /// "file#sub-asset" expands the file and selects that object (`EDITOR_SELECT_ASSET`).
    public var selectAssetPath: String?
    /// The MCP server's transports (see EditorMCP.swift).
    public var mcp = MCPOptions()
    /// Game code to load (`--game`), over the project's `"game"` setting (EditorGameModule.swift).
    public var game: GameModuleSettings?
    /// UI zoom over the prefs' `uiScale` (`EDITOR_UI_SCALE`), clamped to `EditorApp.uiScaleRange`.
    public var uiScale: Float?
    /// A `UITheme` preset name over the prefs' `theme` (`EDITOR_THEME`: Dark, Light, High Contrast, Game).
    public var theme: String?
    /// Whether the editor starts on the launcher (the start screen with the recent projects).
    public var launcher: LauncherMode = .never
    /// Keep unsaved work for crash recovery when there is a prefs folder (EditorRecovery.swift;
    /// also off with `EDITOR_RECOVERY=0`). Tests with a prefs file turn it off.
    public var recovery = true

    /// When the launcher shows at startup.
    public enum LauncherMode: Sendable, Equatable {
        /// Never (tests, `--headless`, a scene or project on the command line).
        case never
        /// Unless the prefs say to reopen the last project and it still exists (a plain launch).
        case auto
        /// Always (`--launcher`).
        case always
    }

    /// Which MCP transports to start.
    public struct MCPOptions: Sendable {
        /// Serve a client on standard input / output (`--mcp`): the client launched the editor.
        public var stdio = false
        /// Serve Streamable HTTP on 127.0.0.1, so clients can attach to the running editor.
        public var http = false
        /// The HTTP port (the next free one if it is taken).
        public var port: UInt16 = 7333
        /// Expose only read-only tools (`--mcp-read-only`; also an AI setting in the Activity panel).
        public var readOnly = false

        public init(stdio: Bool = false, http: Bool = false, port: UInt16 = 7333, readOnly: Bool = false) {
            self.stdio = stdio
            self.http = http
            self.port = port
            self.readOnly = readOnly
        }
    }

    public init(scenePath: String? = nil, projectPath: String? = nil, deterministic: Bool = false, prefsURL: URL? = nil) {
        self.scenePath = scenePath
        self.projectPath = projectPath
        self.deterministic = deterministic
        self.prefsURL = prefsURL
    }

    /// From the environment: deterministic with `ENGINE_SCREENSHOT`, prefs at `EditorPrefsStore.defaultURL`,
    /// the MCP HTTP transport on unless deterministic or `EDITOR_MCP_HTTP=0` (port `EDITOR_MCP_PORT`).
    public static func fromEnvironment(scenePath: String?, projectPath: String? = nil) -> EditorOptions {
        let environment = ProcessInfo.processInfo.environment
        let deterministic = environment["ENGINE_SCREENSHOT"] != nil
        var options = EditorOptions(scenePath: scenePath, projectPath: projectPath, deterministic: deterministic,
                                    prefsURL: deterministic ? nil : EditorPrefsStore.defaultURL())
        options.selectAssetPath = environment["EDITOR_SELECT_ASSET"]
        options.uiScale = environment["EDITOR_UI_SCALE"].flatMap { Float($0) }
        options.theme = environment["EDITOR_THEME"]
        options.mcp.http = !deterministic && environment["EDITOR_MCP_HTTP"] != "0"
        if let port = environment["EDITOR_MCP_PORT"].flatMap({ UInt16($0) }) { options.mcp.port = port }
        return options
    }
}

/// The editor application: hosts an `EditorSession` in the engine, builds the panels in a
/// `DockSpace` under a toolbar, renders the viewport through `SceneRenderer.beginViews` /
/// `renderView` into a `RenderTarget` sized to its panel, routes shortcuts to commands and applies
/// the UI's cursor. Every button, menu item, shortcut and drop runs a command from
/// `session.commands`; the app is the session's `EditorHost` (layout reset, framing the camera,
/// the viewport's view for picking, frame stats and screenshots).
/// Run it with `Engine(config:).run(EditorApp(options:))`.
@MainActor
public final class EditorApp: Game, EditorHost {
    public let session: EditorSession
    public let options: EditorOptions
    public let viewport = ViewportController()
    public let shortcuts = EditorShortcuts()
    public private(set) var ui: UIContext!

    private var sceneRenderer: SceneRenderer!
    private var target: RenderTarget!
    private var sizer = ViewportTargetSizer()
    private let gizmos = DebugDraw()
    /// The viewport tools' overlays (the transform gizmo), drawn above the selection outline.
    private let toolDraw = DebugDraw()
    private var toolDrawRenderer: DebugDrawRenderer!
    private var outline: SelectionOutlineRenderer!
    /// Selection and gizmos in the viewport (set up with the renderer, which it picks against).
    public private(set) var transformTool: TransformTool!
    private var currentView: SceneView?
    /// The Game view's own render target and size, and what it shows this frame: the scene's
    /// Camera entity (the game world's while playing), nil without one.
    private var gameTarget: RenderTarget!
    private var gameSizer = ViewportTargetSizer()
    private var gameCurrentView: SceneView?
    /// The Game view draws nothing of the editor's.
    private let gameDraw = DebugDraw()
    private var meshBoundsCache: [String: Bounds] = [:]
    /// Watches the open project's `Assets/` folder.
    private var assetWatcher: FileWatcher?

    let dock = DockSpace()
    private(set) var hierarchy: HierarchyPanel!
    private(set) var inspector: InspectorPanel!
    private(set) var console: ConsolePanel!
    private(set) var activity: ActivityPanel!
    public private(set) var scriptEditor: ScriptEditorPanel!
    public private(set) var files: FilesPanel!
    /// The Mesh Builder tab (MeshBuilderWorkspace.swift).
    public private(set) var meshWorkspace: MeshBuilderWorkspace!
    /// The Post-FX tab (PostFXWorkspace.swift).
    public private(set) var postFXWorkspace: PostFXWorkspace!
    private(set) var statusBar: StatusBar!
    /// The Assets panel (browser) and its thumbnails.
    public private(set) var assetBrowser: AssetBrowserPanel!
    private var thumbnails: AssetThumbnails?
    /// An asset being dragged from the browser, and where the pointer is.
    private var assetDrag: (entry: AssetBrowserEntry, position: Vec2)?
    private let stats = StatsPanel()
    let viewportWidget = ViewportWidget()
    /// The Game panel's content: what the scene's camera sees.
    let gameWidget = ViewportWidget(name: "gameViewport", label: "Game view")
    private(set) var toolbar: Toolbar!
    /// The start screen with the recent projects (LauncherPanel.swift), shown in place of the
    /// toolbar and the dock.
    private(set) var launcher: LauncherView!
    /// Whether the launcher is shown (`launcher.show`, `launcher.dismiss`; opening a project hides it).
    public private(set) var isLauncherShown = false
    /// Close Project from the UI: the project's thumbnail renders this frame, the project closes next frame.
    private var launcherPending = false
    /// The launcher page to show once a pending launcher appears (`requestCloseProject(then:)`).
    private var launcherPage: ((LauncherView) -> Void)?
    /// When to render the open project's launcher thumbnail (engine time), if it has none yet.
    private var thumbnailDue: Double?
    /// The launcher's thumbnails by project folder (nil: none or unreadable), until it is shown again.
    private var launcherThumbnails: [String: GPUTexture?] = [:]

    private var shownAssetKeys: [AssetReference] = []
    private weak var shownAssets: AssetDatabase?
    private(set) var prefs = EditorPrefs()
    /// The UI zoom asked for (prefs, `EDITOR_UI_SCALE`); `ui.uiScale` is lower in a small window.
    public private(set) var preferredUIScale: Float = 1
    private var prefsDirty = false
    private var captureRequested = false
    /// The MCP server, when a transport is on (`EditorOptions.mcp`).
    public internal(set) var mcp: EditorMCP?

    private weak var engine: Engine?
    /// Screenshots asked for (`capture`) and not rendered yet.
    private var captureJobs: [CaptureJob] = []
    /// Draws the selection outline into screenshots (its own mask, apart from the viewport's).
    private var captureOutline: SelectionOutlineRenderer?
    /// Screenshot targets rendered this frame, kept until the next one.
    private var captureTargets: [RenderTarget] = []
    private var lastStats: EditorStatsSnapshot?
    /// The game has the keyboard and the mouse this frame: playing, `showsGameCamera`, the Game
    /// view in front and a Camera entity.
    private var gameViewActive = false
    /// Last frame's play state, `showsGameCamera` and which of the Scene and Game tabs were in
    /// front (`syncViewTabs`).
    private var tabsState: (playing: Bool, gameCamera: Bool, sceneFront: Bool, gameFront: Bool) = (false, true, true, false)
    /// Real keys and buttons forwarded to the game as down (game view).
    private var forwardedKeys = Set<Key>()
    private var forwardedButtons = Set<MouseButton>()
    private var forwardedPointer: Vec2?
    /// Engine messages (Vulkan validation) on their way to the console.
    private let engineMessages = EngineMessageInbox()

    public init(options: EditorOptions) {
        self.options = options
        let document = EditorDocument()
        if options.deterministic {
            var generator = SequentialIDs()
            document.world.entityIDGenerator = { generator.next() }
        }
        session = EditorSession(document: document)
        session.host = self
        if options.mcp.stdio || options.mcp.http {
            let mcp = EditorMCP(session: session)
            mcp.fallbackConfigURL = options.prefsURL?.deletingLastPathComponent().appendingPathComponent("mcp.json")
            // Before the engine starts printing: stdout belongs to the protocol from here on.
            if options.mcp.stdio { mcp.startStdio() }
            self.mcp = mcp
        }
    }

    // MARK: Setup

    public func setup(engine: Engine) throws {
        self.engine = engine
        engineMessages.install()
        // The macOS app menu: Settings… (Cmd+,) above Quit, as Mac apps have it.
        engine.setAppMenuItems([AppMenuItem(title: "Settings…", keyEquivalent: ",") { [weak self] in self?.showSettings() }])
        session.audioProvider = { [unowned engine] in engine.audio }
        sceneRenderer = try SceneRenderer(device: engine.device, quality: engine.quality)
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                           key: StarterScene.checkerMaterial.key)
        target = try RenderTarget(device: engine.device, width: 640, height: 360, label: "viewport")
        gameTarget = try RenderTarget(device: engine.device, width: 640, height: 360, label: "game view")
        outline = try SelectionOutlineRenderer(device: engine.device)
        toolDrawRenderer = try DebugDrawRenderer(device: engine.device)
        transformTool = TransformTool(meshes: sceneRenderer)
        do {
            thumbnails = try AssetThumbnails(device: engine.device, quality: engine.quality)
        } catch {
            print("Editor: asset thumbnails unavailable: \(error)")
        }
        engine.clearColor = Vec4(0.02, 0.022, 0.03, 1)
        finishSetup()
    }

    /// Builds the panels and opens the scene without a window or GPU (`--headless`, tests), so
    /// the UI can be inspected and driven (`ui.snapshot`, `ui.click`…) as if it were on screen
    /// at `size` points. Run frames with `updateWithoutWindow(dt:)`.
    public func setupWithoutWindow(size: Vec2 = Vec2(1440, 900), scale: Float = 1) {
        FilePicker.isSuppressed = true  // no modal dialogs without a window
        transformTool = TransformTool(meshes: session.cpuPickMeshes)
        finishSetup()
        resizeWithoutWindow(size: size, scale: scale)
    }

    /// Lays the UI out for a window of `size` points at backing `scale` (and the UI's `uiScale`),
    /// as a resized window would; no window or GPU (`setupWithoutWindow`).
    public func resizeWithoutWindow(size: Vec2, scale: Float = 1) {
        fitUIScale(window: size)
        let zoom = ui.uiScale
        ui.setViewport(size: size / zoom, scale: scale * zoom)
        ui.layoutIfNeeded()
        syncPanels()
    }

    /// The UI zooms the editor allows (`EditorPrefs.uiScale`, `EDITOR_UI_SCALE`): below 0.85 the
    /// small text (11 pt) drops under 9 pt; above 2 a 1280-point window has too little room.
    public static let uiScaleRange: ClosedRange<Float> = 0.85...2

    /// The smallest UI, in points, a zoom above 100% may leave: a window with less room zooms less.
    public static let minimumZoomedUISize = Vec2(800, 500)

    /// The smallest editor window (points; `EngineConfig.minimumWindowSize`): the default layout's
    /// panels at their minimum sizes plus a one-row toolbar fit, with the zoom at 100%.
    public static let minimumWindowSize = Vec2(800, 500)

    /// `preferred` lowered (not below 1, or below `preferred` when that is under 1) so a window
    /// of `window` points keeps at least `minimumZoomedUISize` points of UI.
    public static func fittedUIScale(_ preferred: Float, window: Vec2) -> Float {
        guard preferred > 1, window.x > 0, window.y > 0 else { return preferred }
        let fit = min(window.x / minimumZoomedUISize.x, window.y / minimumZoomedUISize.y)
        return max(1, min(preferred, (fit * 100).rounded(.down) / 100))
    }

    private func fitUIScale(window: Vec2) {
        let zoom = Self.fittedUIScale(preferredUIScale, window: window)
        if ui.uiScale != zoom { ui.uiScale = zoom }
    }

    /// The theme and UI zoom from the options, else the prefs, else Dark at 100%. A theme the
    /// editor doesn't use (Game, an unknown name) falls back to Dark with one warning.
    private func appearance() -> (theme: UITheme, uiScale: Float) {
        let name = options.theme ?? prefs.theme
        var theme = UITheme.dark()
        if let name {
            do {
                theme = try Self.editorTheme(named: name)
            } catch {
                session.log.warning("\(error); using Dark")
            }
        }
        if options.deterministic { theme.caretBlinkPeriod = 0 }
        let zoom = options.uiScale ?? prefs.uiScale ?? 1
        return (theme, min(max(zoom.isFinite ? zoom : 1, Self.uiScaleRange.lowerBound), Self.uiScaleRange.upperBound))
    }

    /// The editor's themes (the View menu's, `view.appearance`, the prefs, `EDITOR_THEME`). The
    /// engine's Game preset isn't one: it is made for game menus and HUDs (44-point controls,
    /// 18-point text), too coarse for a dense tool UI.
    public static let themes = ["Dark", "Light", "High Contrast"]
    /// The themes the toolbar's View menu offers (all of `themes`).
    public static let menuThemes = themes

    /// The editor theme called `name` (case-insensitive); throws for Game and unknown names.
    public static func editorTheme(named name: String) throws -> UITheme {
        guard let theme = UITheme.named(name), themes.contains(theme.name) else {
            let why = UITheme.named(name) == nil ? "Unknown theme" : "The \(UITheme.named(name)!.name) theme is for game UI, not the editor:"
            throw CommandError.failed("\(why) '\(name)' (the editor's themes: \(themes.joined(separator: ", ")))")
        }
        return theme
    }
    /// The zooms the View menu offers.
    public static let menuZooms: [Float] = [0.85, 1, 1.25, 1.5, 2]

    /// The current theme and zoom, after applying `theme` and / or `uiScale` (`view.appearance`).
    public func appearance(theme name: String?, uiScale: Float?) throws -> EditorAppearance? {
        guard ui != nil else { return nil }
        if let name {
            var theme = try Self.editorTheme(named: name)
            if options.deterministic { theme.caretBlinkPeriod = 0 }
            if theme.name != ui.theme.name { apply(theme) }
            prefs.theme = theme.name
            prefsDirty = true
        }
        if let uiScale {
            guard uiScale.isFinite else { throw CommandError.failed("uiScale must be a number in 0.85...2") }
            let zoom = min(max(uiScale, Self.uiScaleRange.lowerBound), Self.uiScaleRange.upperBound)
            if zoom != preferredUIScale {
                // The window's size in points and its backing scale, before the change.
                let window = Vec2(ui.viewport.width, ui.viewport.height) * ui.uiScale
                let backing = ui.scale / ui.uiScale
                preferredUIScale = zoom
                if window.x > 0 { resizeWithoutWindow(size: window, scale: backing) }
            }
            prefs.uiScale = zoom
            prefsDirty = true
        }
        return EditorAppearance(theme: ui.theme.name, uiScale: preferredUIScale, effectiveUIScale: ui.uiScale,
                                themes: Self.themes)
    }

    /// Restyles the running editor: the context's theme, plus what was colored when it was built.
    private func apply(_ theme: UITheme) {
        ui.theme = theme
        dock.background = theme.fieldBackground
        toolbar.view.background = theme.panelBackground
        statusBar.view.background = theme.panelBackground
        console.recolor()
        scriptEditor?.recolor()
        hierarchy.sync(force: true)
        syncPanels()
    }

    /// One frame without a window: what `update` does apart from rendering and real input.
    public func updateWithoutWindow(dt: Float) {
        session.log.time += Double(dt)
        if let mcp {
            mcp.pump()
        }
        session.assets?.pump()
        session.tick(dt: Double(dt))
        session.recovery?.update()
        syncPanels()
    }

    /// The part of setup that needs no GPU: the UI, the prefs, the project and the scene.
    private func finishSetup() {
        viewport.tools = [transformTool]

        session.log.echoesToStandardOutput = !options.deterministic
        if let url = options.prefsURL {
            do {
                prefs = try EditorPrefsStore(url: url).load() ?? EditorPrefs()
            } catch {
                session.log.warning("Ignoring unreadable editor prefs at \(url.path): \(error)")
            }
            if !options.deterministic, options.recovery, ProcessInfo.processInfo.environment["EDITOR_RECOVERY"] != "0" {
                session.recovery = EditorRecovery(session: session, folder: url.deletingLastPathComponent().appendingPathComponent("Recovery", isDirectory: true))
            }
        }
        let appearance = appearance()
        ui = UIContext(theme: appearance.theme)
        preferredUIScale = appearance.uiScale
        ui.uiScale = appearance.uiScale
        var ai = prefs.ai ?? AISettings()
        if options.mcp.readOnly { ai.readOnly = true }
        session.aiSettings = ai
        session.editorSettings = prefs.editor ?? EditorSettings()
        applyEditorSettings()
        buildUI()

        session.onWillReplaceWorld = { [unowned self] in inspector.recorder.finishGesture() }
        session.onAISettingsChange = { [unowned self] in aiSettingsChanged() }
        session.onEditorSettingsChange = { [unowned self] in editorSettingsChanged() }
        session.onChange = { [unowned self] in toolbar.refresh() }
        session.onAssetsChange = { [unowned self] in assetsChanged() }
        session.onSceneSaved = { [unowned self] in captureProjectThumbnail() }
        loadRecentProjects()
        // A plain launch starts on the launcher, or in the last project when the prefs say so.
        var startOnLauncher = options.launcher == .always
        var reopen: String?
        if options.launcher == .auto, options.projectPath == nil, options.scenePath == nil {
            let recent = session.recentProjects
            if recent.reopensLastProject, let last = recent.entries.filter({ !$0.isMissing }).max(by: { $0.lastOpened < $1.lastOpened }) {
                reopen = last.path
            } else {
                startOnLauncher = true
            }
        }
        // Game code before the scene, so the scene's game components load typed.
        if let game = options.game {
            session.gameModule.commandLineSettings = game
            session.gameModule.configure(game, base: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
            _ = try? session.commands.start(GameReloadCommand.self, .init(build: !(game.library != nil && game.buildCommand == nil)))
        }
        if let path = options.projectPath { openProjectAsking(.init(path: path)) }
        if let path = options.scenePath {
            if session.run(SceneOpenCommand.self, .init(path: path)) == nil { session.run(SceneNewCommand.self) }
            scenePath = toolbarScenePath(session.document.url?.path ?? path)
        } else {
            session.run(SceneNewCommand.self)
            scenePath = toolbarScenePath(prefs.lastScenePath ?? "scene.json")
        }
        if let reopen {
            // From another engine version: start on the launcher, which the answer closes.
            if openProjectAsking(.init(path: reopen, openLastScene: true), then: { [unowned self] opened in
                if opened { hideLauncher() }
            }) != nil {
                if let url = session.document.url { scenePath = toolbarScenePath(url.path) }
            } else {
                startOnLauncher = true
            }
        }
        if startOnLauncher { setLauncherShown(true) }
        hierarchy.sync(force: true)
        if options.deterministic {
            let world = session.world
            let sphere = world.roots.flatMap { [$0] + world.children(of: $0) }.first { session.displayName(of: $0) == "Blue Sphere" }
            session.selection.select(sphere.flatMap { world.id(of: $0) })
        }
        session.onRevealAsset = { [unowned self] path in
            assetBrowser.model.search = ""
            assetBrowser.model.reveal(path)
        }
        session.onOpenMeshBuild = { [unowned self] id in
            guard meshWorkspace.open(id) else { return }
            // The Mesh Builder opens where the Scene view is: tabbed with the viewport.
            if !EditorLayout.shareGroup(in: dock.layout, EditorLayout.meshBuilder, EditorLayout.viewport) {
                dock.dock(EditorLayout.meshBuilder, at: dock.isOpen(EditorLayout.viewport) ? .tab(with: EditorLayout.viewport)
                                                                                             : .edge(.bottom))
            }
            dock.focusPanel(EditorLayout.meshBuilder)
        }
        session.onOpenPostFX = { [unowned self] id in
            guard postFXWorkspace.open(id) else { return }
            if !EditorLayout.shareGroup(in: dock.layout, EditorLayout.postFXBuilder, EditorLayout.viewport) {
                dock.dock(EditorLayout.postFXBuilder, at: dock.isOpen(EditorLayout.viewport) ? .tab(with: EditorLayout.viewport)
                                                                                               : .edge(.bottom))
            }
            dock.focusPanel(EditorLayout.postFXBuilder)
        }
        session.onOpenScript = { [unowned self] path in
            let url = URL(fileURLWithPath: path)
            scriptEditor.openScript(at: url)
            // Scripts open where the Scene view is: tabbed with the viewport.
            if !EditorLayout.shareGroup(in: dock.layout, EditorLayout.scripts, EditorLayout.viewport) {
                dock.dock(EditorLayout.scripts, at: dock.isOpen(EditorLayout.viewport) ? .tab(with: EditorLayout.viewport)
                                                                                         : .edge(.bottom))
            }
            dock.focusPanel(EditorLayout.scripts)
        }
        if let path = options.selectAssetPath { assetBrowser.model.reveal(path) }
        session.log.info("Editor ready. Right-drag flies the camera, Alt-drag or middle-drag orbits, the wheel zooms.")
        offerRecovery()
        if options.mcp.http, session.aiSettings.httpEnabled, let mcp {
            do {
                try mcp.startHTTP(port: options.mcp.port)
            } catch {
                session.log.warning("MCP HTTP server unavailable: \(error)")
            }
        }
        toolbar.refresh()
    }

    /// The open Settings window, if any.
    public private(set) var settingsDialog: SettingsDialog?

    /// Opens the Settings window (the View menu, Cmd/Ctrl+,) on `tab`, or switches the open one to it.
    public func showSettings(tab: SettingsDialog.Tab? = nil) {
        if let open = settingsDialog {
            if let tab { open.select(tab) }
            return
        }
        let dialog = SettingsDialog(app: self, tab: tab ?? .editor)
        dialog.onClose = { [unowned self, unowned dialog] in
            if settingsDialog === dialog { settingsDialog = nil }
        }
        settingsDialog = dialog
        dialog.present(in: ui)
    }

    /// The open Export Game window, if any.
    public private(set) var exportDialog: ExportDialog?

    /// Opens the Export Game window (the toolbar's Build Game button): platform, architecture
    /// and configuration, then Export runs `game.build`.
    public func showExportDialog() {
        guard exportDialog == nil, session.project != nil else { return }
        let dialog = ExportDialog(session: session)
        dialog.onClose = { [unowned self, unowned dialog] in
            if exportDialog === dialog { exportDialog = nil }
        }
        exportDialog = dialog
        dialog.present(in: ui)
    }

    /// The editor settings changed (`settings.setEditor`): persist them and apply them.
    private func editorSettingsChanged() {
        let settings = session.editorSettings
        prefs.editor = settings == EditorSettings() ? nil : settings
        prefsDirty = true
        applyEditorSettings()
    }

    /// The viewport camera's fly speed and field of view from the editor settings (the gizmo's
    /// snap steps come with each tool context).
    private func applyEditorSettings() {
        let settings = session.editorSettings
        viewport.flySpeed = settings.cameraFlySpeed
        viewport.camera.fovY = settings.cameraFieldOfView * .pi / 180
    }

    /// The AI settings changed (the Activity panel): persist them, start or stop the HTTP server.
    private func aiSettingsChanged() {
        prefs.ai = session.aiSettings
        prefsDirty = true
        guard !options.deterministic else { return }
        if session.aiSettings.httpEnabled {
            let server = mcp ?? {
                let created = EditorMCP(session: session)
                created.fallbackConfigURL = options.prefsURL?.deletingLastPathComponent().appendingPathComponent("mcp.json")
                mcp = created
                return created
            }()
            if server.http == nil {
                do {
                    try server.startHTTP(port: options.mcp.port)
                } catch {
                    session.log.warning("MCP HTTP server unavailable: \(error)")
                }
            }
        } else if let http = mcp?.http {
            mcp?.stopHTTP()
            session.log.info("MCP HTTP server on \(http.url) stopped")
        }
    }

    private func buildUI() {
        hierarchy = HierarchyPanel(session: session)
        hierarchy.onDelete = { [unowned self] in confirmDeleteSelection() }
        hierarchy.spawnPosition = { [unowned self] in
            var p = viewport.camera.pivot
            p.y = max(p.y, 0.5)
            return p
        }
        inspector = InspectorPanel(session: session)
        inspector.assetChoices = makeAssetChoices()
        console = ConsolePanel(log: session.log)
        console.showsTime = !options.deterministic
        console.onClear = { [unowned self] in session.run(LogClearCommand.self) }
        activity = ActivityPanel(session: session)
        assetBrowser = AssetBrowserPanel(session: session)
        assetBrowser.grid.thumbnail = { [unowned self] entry in
            guard let reference = entry.thumbnail, let kind = entry.thumbnailKind else { return nil }
            return thumbnails?.thumbnail(reference, kind: kind)
        }
        assetBrowser.onDrag = { [unowned self] entry, position, phase in assetDragged(entry, at: position, phase: phase) }
        scriptEditor = ScriptEditorPanel(session: session)
        files = FilesPanel(session: session)
        meshWorkspace = MeshBuilderWorkspace(session: session)
        meshWorkspace.device = engine?.device
        if let quality = engine?.quality { meshWorkspace.quality = quality }
        postFXWorkspace = PostFXWorkspace(session: session)
        postFXWorkspace.device = engine?.device
        if let quality = engine?.quality { postFXWorkspace.quality = quality }
        files.onOpen = { [unowned self] file in openFile(file) }
        files.onNewScene = { [unowned self] name in newScene(named: name) }

        let viewportPanel = DockPanel(id: EditorLayout.viewport, title: "Scene", content: viewportWidget, isClosable: false,
                                      minSize: Vec2(200, 120))
        viewportPanel.passesPointerThrough = true
        dock.addPanel(viewportPanel)
        let gamePanel = DockPanel(id: EditorLayout.game, title: "Game", content: gameWidget, isClosable: false,
                                  minSize: Vec2(200, 120))
        gamePanel.passesPointerThrough = true
        dock.addPanel(gamePanel)
        dock.addPanel(DockPanel(id: EditorLayout.hierarchy, title: "Hierarchy", content: hierarchy.view, minSize: Vec2(160, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.inspector, title: "Inspector", content: inspector.view, minSize: Vec2(240, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.console, title: "Console", content: console.view))
        dock.addPanel(DockPanel(id: EditorLayout.stats, title: "Stats", content: stats.view))
        dock.addPanel(DockPanel(id: EditorLayout.assets, title: "Assets", content: assetBrowser.view, minSize: Vec2(240, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.scripts, title: "Scripts", content: scriptEditor.view, minSize: Vec2(240, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.files, title: "Files", content: files.view, minSize: Vec2(160, 100)))
        let meshPanel = DockPanel(id: EditorLayout.meshBuilder, title: "Mesh Builder", content: meshWorkspace.view, minSize: Vec2(320, 200))
        meshPanel.passesPointerThrough = true
        dock.addPanel(meshPanel)
        let postFXPanel = DockPanel(id: EditorLayout.postFXBuilder, title: "Post-FX", content: postFXWorkspace.view, minSize: Vec2(320, 200))
        postFXPanel.passesPointerThrough = true
        dock.addPanel(postFXPanel)
        dock.addPanel(DockPanel(id: EditorLayout.activity, title: "Activity", content: activity.view, minSize: Vec2(240, 100)))
        for (id, icon) in EditorIcons.panelIconNames { dock.panel(id)?.icon = EditorIcons.named(icon) }
        dock.restoreLayout(EditorLayout.initialLayout(stored: prefs.layout))
        // Layouts saved before the Assets panel existed get it next to the console.
        if !dock.isOpen(EditorLayout.assets) {
            dock.dock(EditorLayout.assets, at: dock.isOpen(EditorLayout.console) ? .tab(with: EditorLayout.console, index: 0)
                                                                                   : .edge(.bottom))
        }
        // And the Activity panel after the console (without selecting it).
        if !dock.isOpen(EditorLayout.activity) {
            let selected = EditorLayout.activePanel(in: dock.layout, groupOf: EditorLayout.console)
            dock.dock(EditorLayout.activity, at: dock.isOpen(EditorLayout.console) ? .tab(with: EditorLayout.console)
                                                                                     : .edge(.bottom))
            if let selected { dock.focusPanel(selected) }
        }
        // And the Scripts panel tabbed with the Scene view if not open, keeping the Scene selected.
        if !dock.isOpen(EditorLayout.scripts) {
            let selected = EditorLayout.activePanel(in: dock.layout, groupOf: EditorLayout.viewport)
            dock.dock(EditorLayout.scripts, at: dock.isOpen(EditorLayout.viewport) ? .tab(with: EditorLayout.viewport)
                                                                                     : .edge(.bottom))
            if let selected { dock.focusPanel(selected) }
        }
        // And the Game view tabbed after the Scene view, keeping the Scene selected.
        if !dock.isOpen(EditorLayout.game) {
            let selected = EditorLayout.activePanel(in: dock.layout, groupOf: EditorLayout.viewport)
            dock.dock(EditorLayout.game, at: dock.isOpen(EditorLayout.viewport) ? .tab(with: EditorLayout.viewport, index: 1)
                                                                                  : .edge(.bottom))
            if let selected { dock.focusPanel(selected) }
        }
        tabsState = (session.isPlaying, session.showsGameCamera, isFront(EditorLayout.viewport), isFront(EditorLayout.game))
        // Parity and introspection: what the dock's tabs and close buttons run.
        dock.itemCommands = ["tab": PanelFocusCommand.id.rawValue, "close": PanelCloseCommand.id.rawValue]
        viewportWidget.command = ViewPickCommand.id.rawValue
        viewportWidget.selectionState = { [unowned self] entity in
            let world = session.world
            if session.selection.primaryEntity(in: world) == entity { return .primary }
            return session.selection.entities(in: world).contains(entity) ? .selected : .none
        }
        dock.style.grow = 1
        dock.padding = EdgeInsets(top: 0, left: 4, bottom: 4, right: 4)
        dock.background = ui.theme.fieldBackground
        dock.onLayoutChange = { [unowned self] layout in
            prefs.layout = layout
            prefsDirty = true
        }

        toolbar = Toolbar(app: self)
        statusBar = StatusBar(app: self)
        launcher = LauncherView(app: self)
        let column = VStack(name: "editorRoot", [toolbar.view, dock, launcher.view, statusBar.view])
        column.isHitTestable = false
        ui.root.addChild(column)
    }

    /// Dropdown options: the renderer's code-registered keys, then the project's assets.
    private func makeAssetChoices() -> AssetChoices {
        AssetChoices(
            // Without a renderer (headless) the built-in meshes and the starter scene's material.
            meshes: { [unowned self] in
                sceneRenderer.map { $0.prep.meshes.keys.filter { AssetReference($0) == nil } }
                    ?? MeshGeometry.builtinHandles.map(\.key)
            },
            materials: { [unowned self] in
                sceneRenderer.map { $0.prep.materials.keys.filter { AssetReference($0) == nil } } ?? [StarterScene.checkerMaterial.key]
            },
            assets: { [unowned self] in session.assets })
    }

    /// A project was opened or its assets changed: resolve handles through it, refresh the
    /// inspector's dropdowns and watch its `Assets/` folder.
    private func assetsChanged() {
        sceneRenderer?.assets = session.assets
        thumbnails?.assets = session.assets
        meshBoundsCache.removeAll()
        // Rebuilding the dropdowns resets the inspector's grid, so only when the choices changed
        // (not for every reimport, such as a material edited live).
        let keys = session.assets.map { $0.references(of: .mesh) + $0.references(of: .material) + $0.references(of: .texture) + $0.audioReferences() } ?? []
        if keys != shownAssetKeys || session.assets !== shownAssets {
            shownAssetKeys = keys
            shownAssets = session.assets
            inspector.assetChoices = makeAssetChoices()
        }
        assetBrowser.model.invalidate()
        guard let project = session.project else {
            // The project was closed.
            assetWatcher?.stop()
            assetWatcher = nil
            return
        }
        if assetWatcher?.directory != project.assetsURL {
            assetWatcher?.stop()
            let watcher = FileWatcher(directory: project.assetsURL)
            watcher.start(interval: 1) { [weak self] changes in self?.session.assetsChanged(changes) }
            assetWatcher = watcher
        }
        if prefs.lastProjectPath != project.root.path {
            prefs.lastProjectPath = project.root.path
            prefsDirty = true
        }
        if isLauncherShown { setLauncherShown(false) }
        if let url = session.document.url { scenePath = toolbarScenePath(url.path) }
        // A project without a thumbnail gets one once its scene has had time to load.
        if canRender, !FileManager.default.fileExists(atPath: RecentProjectList.thumbnailURL(projectRoot: project.root).path) {
            thumbnailDue = (engine?.time ?? 0) + 2
        }
    }

    // MARK: Launcher

    /// The recent projects and the launcher settings from the prefs (a prefs file from before
    /// the launcher starts the list with its last project); changes are saved back.
    private func loadRecentProjects() {
        let recent = session.recentProjects
        var stored = prefs.recentProjects ?? []
        if prefs.recentProjects == nil, let last = prefs.lastProjectPath, let project = try? Project.open(at: URL(fileURLWithPath: last)) {
            stored = [RecentProject(path: project.root.path, name: project.name, lastOpened: Date(), hasGame: project.settings.game != nil)]
        }
        recent.load(stored)
        recent.reopensLastProject = prefs.reopenLastProject ?? false
        recent.newProjectLocation = prefs.newProjectLocation
        recent.onChange = { [unowned self, unowned recent] in
            prefs.recentProjects = recent.entries
            prefs.reopenLastProject = recent.reopensLastProject ? true : nil
            prefs.newProjectLocation = recent.newProjectLocation
            prefsDirty = true
        }
    }

    /// Closes the project (if one is open), starts a new scene and shows the launcher
    /// (`launcher.show`). False (logged) while playing.
    @discardableResult
    public func showLauncher() -> Bool {
        guard !session.isPlaying else {
            session.log.warning("Close Project: stop playing first")
            return false
        }
        if session.project != nil { session.closeProject() }
        session.newDocument()
        hierarchy.sync(force: true)
        setLauncherShown(true)
        return true
    }

    /// Shows the launcher (Close Project), then the page `requestCloseProject(then:)` asked for.
    private func showPendingLauncher() {
        let page = launcherPage
        launcherPage = nil
        if session.run(LauncherShowCommand.self) != nil, let page { page(launcher) }
    }

    /// Leaves the launcher for the editor (`launcher.dismiss`, or a project was opened).
    public func hideLauncher() {
        setLauncherShown(false)
    }

    private func setLauncherShown(_ shown: Bool) {
        isLauncherShown = shown
        if toolbar.view.isHidden != shown { toolbar.view.isHidden = shown }
        if dock.isHidden != shown { dock.isHidden = shown }
        if launcher.view.isHidden == shown { launcher.view.isHidden = !shown }
        if shown {
            launcherThumbnails.removeAll()
            for overlay in ui.overlays.reversed() where overlay is PopupMenu { ui.dismissOverlay(overlay) }
            launcher.showRecent()
        } else if let focused = ui.focusedWidget, focused.isDescendant(of: launcher.view) {
            ui.focus(nil)
        }
        ui.layoutIfNeeded()
        toolbar?.refresh()
    }

    /// Close Project from the toolbar: asks first when the scene has unsaved changes, renders the
    /// project's thumbnail, then shows the launcher.
    /// `then` runs on the launcher once it shows (Open Project / New Project go to its forms).
    func requestCloseProject(then page: ((LauncherView) -> Void)? = nil) {
        guard ui.overlays.isEmpty, session.commands.isAvailable(LauncherShowCommand.self) else { return }
        let proceed = { [unowned self] in
            launcherPage = page
            if canRender, session.project != nil {
                captureProjectThumbnail()
                launcherPending = true
            } else {
                showPendingLauncher()
            }
        }
        guard session.document.isDirty else {
            proceed()
            return
        }
        let name = session.project.map { "\u{201C}\($0.name)\u{201D}" } ?? "the scene"
        let dialog = ConfirmDialog(
            title: "Close \(name) with unsaved changes?",
            message: "Your changes to \(session.document.displayName) are lost when the project closes. Cancel, then save (\(shortcuts.shortcutText(for: .save))) to keep them.",
            confirmTitle: "Discard and Close", name: "closeProjectDialog")
        dialog.command = LauncherShowCommand.id.rawValue
        dialog.onConfirm = proceed
        dialog.present(in: ui)
    }

    /// Renders the open project's scene through its camera (else the editor camera's view; 16:9, no gizmos) into the
    /// project's `Library/Editor/Thumbnail.png`, for the launcher. Needs a window.
    func captureProjectThumbnail() {
        guard canRender, let project = session.project else { return }
        thumbnailDue = nil
        // The scene's camera (what the game shows), else the editor camera.
        let world = session.world
        let view: SceneView = RenderPrep.findCamera(in: world).flatMap { SceneView(camera: $0.entity, in: world, aspect: 16.0 / 9) }
            ?? viewport.view(aspect: 16.0 / 9, clearColor: viewportClearColor())
        let request = ScreenshotRequest(source: .camera, view: view, width: 384, height: 216, grid: false, gizmos: false, outline: false)
        let url = RecentProjectList.thumbnailURL(projectRoot: project.root)
        capture(request)?.onFinish { [weak self] result in
            guard case .success(let image) = result else { return }
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try image.pngData().write(to: url, options: .atomic)
                self?.launcherThumbnails[project.root.path] = nil
            } catch {
                self?.session.log.warning("Couldn't save the project thumbnail: \(error)")
            }
        }
    }

    /// A recent project's thumbnail as a texture (loaded once per launcher showing), nil without one or a GPU.
    func launcherThumbnail(_ entry: RecentProject) -> GPUTexture? {
        if let cached = launcherThumbnails[entry.path] { return cached }
        var texture: GPUTexture?
        if let device = engine?.device, let data = try? Data(contentsOf: entry.thumbnailURL), let image = try? ImageDecoder.decode(data) {
            texture = try? device.makeTexture(image: image, srgb: true, generateMipmaps: false)
        }
        launcherThumbnails[entry.path] = texture
        return texture
    }

    /// Open Project from the toolbar: the folder picker (macOS), else the launcher's Open form.
    func openProject() {
        guard FilePicker.isAvailable else {
            requestCloseProject { $0.showOpen() }
            return
        }
        // Cancelled: nothing changes.
        guard let url = FilePicker.chooseFolder(title: "Open Project", prompt: "Open") else { return }
        openProjectAsking(.init(path: url.path, openLastScene: nil))
    }

    /// Runs project.open, first asking when the project was made with another engine version:
    /// a warning with Open Anyway (which opens it and stamps it with this version) and Cancel.
    /// `done` gets whether the project opened (not called on Cancel). Returns the result when
    /// it ran at once; nil when it failed or waits for the answer.
    @discardableResult
    func openProjectAsking(_ arguments: ProjectOpenCommand.Arguments, then done: ((Bool) -> Void)? = nil) -> PathResult? {
        guard arguments.allowVersionMismatch != true, let mismatch = ProjectOpenCommand.versionMismatch(arguments.path, in: session) else {
            let result = session.run(ProjectOpenCommand.self, arguments)
            done?(result != nil)
            return result
        }
        let path = ProjectOpenCommand.resolvedPath(arguments.path, in: session)
        let name = (try? Project.open(at: session.resolvedFileURL(forPath: path)).name) ?? (path as NSString).lastPathComponent
        session.log.warning("\(name) was \(mismatch)")
        let risk = mismatch.isNewer
            ? "It may use features this engine doesn't know, and saving it here can lose them."
            : "Its files may be upgraded and then not open in engine \(mismatch.saved) again."
        let dialog = ConfirmDialog(
            title: "Open \u{201C}\(name)\u{201D} made with engine \(mismatch.saved)?",
            message: "This editor is engine \(mismatch.current). \(risk) Opening it anyway records \(mismatch.current) in its Project.json.",
            confirmTitle: "Open Anyway", name: "engineVersionDialog")
        dialog.command = ProjectOpenCommand.id.rawValue
        dialog.onConfirm = { [unowned self] in
            var allowed = arguments
            allowed.allowVersionMismatch = true
            let opened = session.run(ProjectOpenCommand.self, allowed) != nil
            if opened, let url = session.document.url { scenePath = toolbarScenePath(url.path) }
            hierarchy.sync(force: true)
            done?(opened)
        }
        dialog.present(in: ui)
        return nil
    }

    /// New Project from the toolbar: the launcher's New Project form (name, location, template).
    func newProject() {
        requestCloseProject { $0.showNewProject() }
    }

    /// The open scene's path (Save uses it for a scene without a file): from the project folder
    /// when the scene is in it ("Assets/Main.scene"), else the whole path. The Files panel
    /// creates and switches scenes, so it is no longer a field.
    var scenePath = ""

    /// A scene path as `scenePath` keeps it: from the project folder when the scene is in it
    /// ("Assets/Main.scene"), else the whole path.
    func toolbarScenePath(_ path: String) -> String {
        guard let root = session.project?.root else { return path }
        let url = EditorSession.url(forPath: path)
        guard EditorSession.isInside(url, root) else { return path }
        let base = EditorSession.resolved(root).path
        let full = EditorSession.resolved(url).path
        return full == base ? "" : String(full.dropFirst(base.count + (base.hasSuffix("/") ? 0 : 1)))
    }

    /// `scenePath` for a command: a relative path is from the project folder while a
    /// project is open (`~` and absolute paths are taken as they are).
    func scenePathFromToolbar() -> String {
        let text = scenePath.trimmingCharacters(in: .whitespaces)
        guard let root = session.project?.root, !text.isEmpty, !text.hasPrefix("/"), !text.hasPrefix("~") else { return text }
        return root.appendingPathComponent(text).standardizedFileURL.path
    }

    /// The host calls it when the main loop ended (`quitReason`: why, from `Engine.quitReason`):
    /// saves the prefs and leaves unsaved work for recovery (EditorRecovery.swift). Says loudly
    /// on standard error why the editor is quitting and what was in flight.
    public func shutdown(quitReason: String?) {
        var notes: [String] = []
        if session.gameModule.isBusy { notes.append("a game rebuild was still running (abandoned)") }
        if session.isPlaying { notes.append("play mode was on") }
        if session.document.isDirty { notes.append("the scene had unsaved changes") }
        let line = "Editor: quitting (\(quitReason ?? "the main loop ended"))" + (notes.isEmpty ? "" : ": " + notes.joined(separator: "; "))
        FileHandle.standardError.write(Data((line + "\n").utf8))
        savePrefs()
        session.recovery?.finish(quitReason: quitReason)
    }

    /// Recovery files of sessions that are gone: say so in the console and ask.
    private func offerRecovery() {
        guard let recovery = session.recovery, let newest = recovery.found.first else { return }
        let more = recovery.found.count > 1 ? " (and \(recovery.found.count - 1) older)" : ""
        session.log.warning("Recovery: \(newest.sceneName) was left by \(EditorRecovery.describe(newest))\(more). "
            + "scene.recover opens it, scene.discardRecovery deletes it.")
        guard !options.deterministic else { return }
        let changes = newest.unsaved ? "unsaved changes to \(newest.sceneName)" : "\(newest.sceneName) as it was"
        let play = newest.hasPlayState ? " A play state is included (scene.recover with playState)." : ""
        let dialog = ConfirmDialog(
            title: "Recover unsaved work?",
            message: "The last editor session left work behind (\(newest.reason)). It kept \(changes) (\(newest.entities) entities).\(play) "
                + "Not Now keeps it for later (scene.recover).",
            confirmTitle: "Recover", name: "recoveryDialog")
        dialog.cancelButton.title = "Not Now"
        dialog.command = SceneRecoverCommand.id.rawValue
        dialog.onConfirm = { [unowned self] in
            if session.run(SceneRecoverCommand.self, .init(id: newest.id)) != nil {
                hierarchy.sync(force: true)
                if let path = newest.scenePath { scenePath = toolbarScenePath(path) }
            }
        }
        dialog.present(in: ui)
    }

    /// Writes the prefs file (layout, last scene) if prefs are persisted. The host calls it on exit too.
    public func savePrefs() {
        guard let url = options.prefsURL else { return }
        prefs.layout = dock.layout
        if let path = session.document.url?.path { prefs.lastScenePath = path }
        do {
            try EditorPrefsStore(url: url).save(prefs)
            prefsDirty = false
        } catch {
            session.log.warning("Couldn't save editor prefs to \(url.path): \(error)")
        }
    }

    /// `layout.reset`.
    public func resetLayout() {
        dock.restoreLayout(EditorLayout.defaultLayout)
        prefs.layout = dock.layout
        prefsDirty = true
    }

    // MARK: Frame

    public func update(engine: Engine, dt: Float) {
        let input = engine.input
        session.log.time = engine.time
        engineMessages.drain(into: session.log)
        // Close Project from the toolbar: its thumbnail rendered last frame, now it closes.
        if launcherPending {
            launcherPending = false
            showPendingLauncher()
        }
        if let due = thumbnailDue, engine.time >= due, session.assets?.isLoading != true, !isLauncherShown {
            captureProjectThumbnail()
        }
        // Requests from MCP clients run here, between frames, before the UI reads the session.
        if let mcp {
            mcp.pump()
            if mcp.stdioClientDisconnected { engine.quit(reason: "the MCP stdio client disconnected") }
        }

        // What the UI does with the keyboard, before and after it handles this frame's input.
        func textEditing() -> Bool { ui.focusedWidget?.wantsTextInput == true || input.isTextInputActive }
        let textBefore = textEditing(), focusedBefore = ui.focusedWidget != nil, overlayBefore = !ui.overlays.isEmpty
        fitUIScale(window: engine.ui.size)
        ui.update(engine: engine, dt: dt)
        let focus = EditorShortcuts.Focus(textEditing: textBefore || textEditing(), overlayOpen: overlayBefore,
                                          widgetFocused: focusedBefore)
        if isLauncherShown {
            // The launcher has its own keys; the editor's (save, play, delete…) don't apply to it.
            if !overlayBefore { for event in input.keyPresses { _ = launcher.handleShortcut(event) } }
        } else {
            for command in shortcuts.actions(for: input.keyPresses, focus: focus) { invoke(command) }
            updateViewport(engine: engine, dt: dt, keyboardFree: !focus.textEditing)
            meshWorkspace.update(input: workspaceInput(engine.input, dt: dt), dt: dt)
            postFXWorkspace.update(input: workspaceInput(engine.input, dt: dt), dt: dt)
        }
        session.tick(dt: Double(dt))

        syncPanels()
        thumbnails?.prepare()
        updateCaptures()
        var snapshot = EditorStatsSnapshot()
        snapshot.frame = engine.stats
        snapshot.entityCount = session.world.entityCount
        snapshot.viewportSize = (target.width, target.height)
        snapshot.viewportDrawn = sceneRenderer.stats.list.opaque + sceneRenderer.stats.list.transparent
        snapshot.viewportCulled = sceneRenderer.stats.list.culled
        snapshot.undoDepth = session.undo.undoDepth
        snapshot.redoDepth = session.undo.redoDepth
        snapshot.isPlaying = session.isPlaying
        snapshot.uiPaintTime = ui.stats.paintTime
        snapshot.backend = engine.device.backend.rawValue
        snapshot.deviceName = engine.device.deviceName
        lastStats = snapshot
        stats.refresh(snapshot, time: engine.time)
        toolbar.refresh()

        // Size the target to the panel before painting, so the image drawn this frame is the one rendered.
        ui.layoutIfNeeded()
        resizeTarget(scale: ui.scale)
        meshWorkspace.prepareFrame(pixelScale: ui.scale)
        postFXWorkspace.prepareFrame(pixelScale: ui.scale)
        buildGizmos()
        viewportWidget.texture = target.texture
        viewportWidget.billboards = transformTool.billboards
        gameWidget.texture = gameCurrentView != nil ? gameTarget.texture : nil
        gameWidget.overlayLines = session.netPlay.map { $0.showsOverlay ? $0.overlayLines() : [] } ?? []
        updateViewportCaption()
        viewportWidget.isPlaying = session.isPlaying
        gameWidget.isPlaying = session.isPlaying
        ui.draw(into: engine.ui)
        engine.ui.withTransform(scale: ui.uiScale) { drawAssetDrag(into: engine.ui) }

        input.cursor = cursorShape(for: ui.desiredCursor)
        let project = session.project.map { " — \($0.name)" } ?? ""
        let title = isLauncherShown ? "Projects — Editor \(EngineVersion.current)"
            : "\(session.document.title)\(project) — Editor \(EngineVersion.current)" + (session.isPlaying ? " [Playing]" : "")
        if engine.title != title { engine.title = title }
        if prefsDirty && !MouseButton.allCases.contains(where: input.isDown) { savePrefs() }
        session.recovery?.update()
    }

    /// Runs the command `id` as the UI does (a shortcut): commands that need an answer from the
    /// user ask first (delete confirms, import picks files, save takes the path field); the others
    /// run with default arguments. Unavailable commands do nothing.
    func invoke(_ id: CommandID) {
        switch id {
        case .save: save()
        case .delete: confirmDeleteSelection()
        case .importAsset: assetBrowser.beginImport()
        case .settings: showSettings()
        case .clearSelection:
            // Esc first cancels a gizmo drag, then clears the selection.
            if transformTool?.cancelDrag(world: session.world) != true { session.run(SelectionClearCommand.self) }
        default:
            guard session.commands.isAvailable(id) else { return }
            session.run(id)
        }
    }

    /// Asks in a modal dialog, then deletes the selected entities (`entity.delete`, one undo step).
    func confirmDeleteSelection() {
        let doomed = session.selection.topLevelEntities(in: session.world)
        guard !doomed.isEmpty, ui.overlays.isEmpty else { return }
        let title = doomed.count == 1
            ? "Delete \u{201C}\(session.displayName(of: doomed[0]))\u{201D}?" : "Delete \(doomed.count) entities?"
        let hasChildren = doomed.contains { !session.world.children(of: $0).isEmpty }
        let message = (hasChildren ? (doomed.count == 1 ? "Its children are deleted with it. " : "Their children are deleted with them. ") : "")
            + "You can undo this with \(shortcuts.shortcutText(for: .undo))."
        let dialog = ConfirmDialog(title: title, message: message, confirmTitle: "Delete", name: "deleteEntitiesDialog")
        dialog.command = EntityDeleteCommand.id.rawValue
        dialog.onConfirm = { [unowned self] in session.run(EntityDeleteCommand.self, .init()) }
        dialog.present(in: ui)
    }

    func save() {
        if session.run(SceneSaveCommand.self, .init(path: scenePathFromToolbar())) != nil { rememberScenePath() }
    }

    /// A click in the Files panel: a script opens in the Scripts editor; a scene asks first when
    /// the open one has unsaved changes, then opens in the Scene view.
    func openFile(_ file: ProjectFile) {
        let isOpenScene = session.document.url?.standardizedFileURL.path == file.absolutePath
        if file.kind == .script || !isOpenScene {
            let name = (file.path as NSString).lastPathComponent
            let run = { [unowned self] in _ = session.run(FilesOpenCommand.self, .init(path: file.absolutePath)) }
            if file.kind == .script { run() } else { replaceScene(title: "Open \(name)", confirm: "Discard and Open", command: FilesOpenCommand.id, run) }
        } else {
            sceneOpenedFromFiles()
        }
    }

    /// New Scene in the Files panel: asks first when the open scene has unsaved changes.
    func newScene(named name: String) {
        replaceScene(title: "Create \(name)", confirm: "Discard and Create", command: FilesNewSceneCommand.id) { [unowned self] in
            _ = session.run(FilesNewSceneCommand.self, .init(name: name))
        }
    }

    /// Runs `proceed`, which replaces the open scene, after asking when it has unsaved changes.
    private func replaceScene(title: String, confirm: String, command: CommandID, _ proceed: @escaping () -> Void) {
        guard session.document.isDirty else { return proceed() }
        guard ui.overlays.isEmpty else { return }
        let dialog = ConfirmDialog(
            title: "\(title) with unsaved changes?",
            message: "Your changes to \(session.document.displayName) are lost. Cancel, then save (\(shortcuts.shortcutText(for: .save))) to keep them.",
            confirmTitle: confirm, name: "replaceSceneDialog")
        dialog.command = command.rawValue
        dialog.onConfirm = proceed
        dialog.present(in: ui)
    }

    /// After files.open or files.newScene opened a scene: the hierarchy, the scene path and the Scene view in front.
    func sceneOpenedFromFiles() {
        hierarchy.sync(force: true)
        rememberScenePath()
        if dock.isOpen(EditorLayout.viewport) { dock.focusPanel(EditorLayout.viewport) }
    }

    private func rememberScenePath() {
        guard let path = session.document.url?.path else { return }
        scenePath = toolbarScenePath(path)
        if prefs.lastScenePath != path {
            prefs.lastScenePath = path
            prefsDirty = true
        }
    }

    /// Frames the selected entities (their bounds, or their positions) in the viewport
    /// (`view.frameSelection`).
    public func frameSelection() {
        frame(session.selection.entities(in: session.world))
    }

    /// Frames `entities` (their bounds, or their positions) in the viewport.
    public func frame(_ entities: [Entity]) {
        let context = toolContext(view: currentView ?? viewport.view(aspect: sizer.aspectRatio))
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for entity in entities where session.world.isAlive(entity) {
            let box = context.worldBounds(of: entity)
                ?? Bounds(center: session.world.worldMatrix(of: entity).translation, halfExtent: Vec3(repeating: 0.5))
            lo = pointwiseMin(lo, box.center - box.halfExtent)
            hi = pointwiseMax(hi, box.center + box.halfExtent)
        }
        guard lo.x <= hi.x else { return }
        viewport.frame(Bounds(center: (lo + hi) / 2, halfExtent: (hi - lo) / 2))
    }

    // MARK: Viewport

    /// The viewport's caption: the camera and tool, and the play state.
    /// The viewport's caption goes in its panel's tab bar (it covered scene labels as a badge
    /// over the image); the badge only shows when the bar has no room for it.
    func updateViewportCaption() {
        let scene = "Perspective · \(session.tool.title)" + (playState().map { " · \($0)" } ?? "")
        setCaption(scene, of: viewportWidget, panel: EditorLayout.viewport)
        setCaption(gameCaption(), of: gameWidget, panel: EditorLayout.game)
        gameWidget.placeholder = RenderPrep.findCamera(in: session.gameWorld) == nil
            ? "No Camera entity in the scene: add one to see the game here" : nil
    }

    private func setCaption(_ caption: String, of widget: ViewportWidget, panel id: String) {
        widget.caption = caption
        guard let panel = dock.panel(id) else { return }
        panel.caption = caption
        let inBar = panel.owner?.captionIsShown ?? false
        if widget.drawsCaption == inBar { widget.drawsCaption = !inBar }
    }

    /// "Playing", "Paused · frame 12"…; nil in edit mode.
    private func playState() -> String? {
        guard session.isPlaying else { return nil }
        return session.isPaused ? "Paused · frame \(session.playFrame)" : "Playing"
            + (session.timeScale != 1 ? " · \(Toolbar.timeScaleTitle(session.timeScale))" : "")
    }

    /// The Game view's caption: the world it shows (network play), the camera and the play state.
    private func gameCaption() -> String {
        let world = session.gameWorld
        guard let camera = RenderPrep.findCamera(in: world)?.entity else { return "No camera" }
        let source = session.netPlay.map { $0.viewedClient.map { "Client \($0) · " } ?? "Server · " } ?? ""
        let name = world === session.world ? session.displayName(of: camera) : world.get(Name.self, for: camera)?.value ?? "Camera"
        return "\(source)\(name)" + (playState().map { " · \($0)" } ?? "")
    }

    /// The scene's Camera entity's view (the game world's while playing) at `aspect`, nil without one.
    private func gameView(aspect: Float) -> SceneView? {
        let world = session.gameWorld
        guard let camera = RenderPrep.findCamera(in: world)?.entity else { return nil }
        return SceneView(camera: camera, in: world, aspect: aspect)
    }

    /// Whether panel `id` is open and the selected tab of its group.
    func isFront(_ id: String) -> Bool {
        dock.isOpen(id) && EditorLayout.activePanel(in: dock.layout, groupOf: id) == id
    }

    /// Keeps the Scene and Game tabs and `showsGameCamera` in step: Play brings the Game tab to
    /// the front (when `showsGameCamera`), Stop the Scene tab back (when they share a group);
    /// while playing, `view.gameCamera` picks the tab and picking a tab sets it.
    func syncViewTabs() {
        guard dock.isOpen(EditorLayout.game), dock.isOpen(EditorLayout.viewport) else { return }
        let playing = session.isPlaying, last = tabsState
        if playing != last.playing {
            if playing, session.showsGameCamera {
                dock.focusPanel(EditorLayout.game)
            } else if !playing, isFront(EditorLayout.game), EditorLayout.shareGroup(in: dock.layout, EditorLayout.game, EditorLayout.viewport) {
                dock.focusPanel(EditorLayout.viewport)
            }
        } else if playing, session.showsGameCamera != last.gameCamera {
            dock.focusPanel(session.showsGameCamera ? EditorLayout.game : EditorLayout.viewport)
        } else if playing {
            let sceneFront = isFront(EditorLayout.viewport), gameFront = isFront(EditorLayout.game)
            if sceneFront != last.sceneFront || gameFront != last.gameFront {
                if gameFront && !sceneFront { session.showsGameCamera = true }
                if sceneFront && !gameFront { session.showsGameCamera = false }
            }
        }
        tabsState = (playing, session.showsGameCamera, isFront(EditorLayout.viewport), isFront(EditorLayout.game))
    }

    /// Game view: the keyboard (unless the UI is typing) and the mouse over the viewport go to
    /// the game's input as events, positions relative to the viewport. Presses start only over
    /// the viewport; what is down stays down until released.
    private func forwardInputToGame(_ input: Input, keyboardFree: Bool) {
        let rect = gameWidget.frame
        let mouse = uiPoint(input.mousePosition)
        let hovered = gameWidget.isEffectivelyVisible && rect.contains(mouse) && !ui.wantsPointer
        var events: [InputEvent] = []
        for key in Key.allCases {
            let down = keyboardFree && input.isDown(key)
            guard down != forwardedKeys.contains(key) else { continue }
            if down { forwardedKeys.insert(key) } else { forwardedKeys.remove(key) }
            events.append(.key(key, down: down))
        }
        for button in MouseButton.allCases {
            let down = input.isDown(button) && (forwardedButtons.contains(button) || (hovered && input.wasPressed(button)))
            guard down != forwardedButtons.contains(button) else { continue }
            if down { forwardedButtons.insert(button) } else { forwardedButtons.remove(button) }
            events.append(.button(button, down: down))
        }
        if hovered || !forwardedButtons.isEmpty {
            let local = mouse - Vec2(rect.x, rect.y)
            if local != forwardedPointer {
                forwardedPointer = local
                events.append(.mouseMove(to: local))
            }
            if hovered && input.scrollDelta != .zero { events.append(.scroll(input.scrollDelta)) }
        }
        session.forwardToGame(events)
    }

    /// Lets go of what game view forwarded (it was turned off, or play stopped).
    private func releaseForwardedInput() {
        guard !forwardedKeys.isEmpty || !forwardedButtons.isEmpty || forwardedPointer != nil else { return }
        session.forwardToGame(forwardedKeys.map { .key($0, down: false) } + forwardedButtons.map { .button($0, down: false) })
        forwardedKeys.removeAll()
        forwardedButtons.removeAll()
        forwardedPointer = nil
    }

    private func updateViewport(engine: Engine, dt: Float, keyboardFree: Bool) {
        let input = engine.input
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        // Scene and Game side by side while playing: a click picks which one gets the keyboard.
        if session.isPlaying, viewportWidget.isEffectivelyVisible, gameWidget.isEffectivelyVisible,
           MouseButton.allCases.contains(where: input.wasPressed), !ui.wantsPointer {
            let mouse = uiPoint(input.mousePosition)
            if gameWidget.frame.contains(mouse) { session.showsGameCamera = true }
            if viewportWidget.frame.contains(mouse) { session.showsGameCamera = false }
        }
        gameViewActive = session.isPlaying && session.showsGameCamera && gameWidget.isEffectivelyVisible
            && RenderPrep.findCamera(in: session.gameWorld) != nil
        if gameViewActive {
            forwardInputToGame(input, keyboardFree: keyboardFree)
        } else {
            releaseForwardedInput()
        }
        guard viewportWidget.isEffectivelyVisible else {
            if captureRequested {
                input.isMouseCaptured = false
                captureRequested = false
            }
            return
        }
        var frameInput = ViewportInput(mousePosition: uiPoint(input.mousePosition))
        frameInput.mouseDelta = input.mouseDelta / ui.uiScale
        for button in MouseButton.allCases {
            if input.wasPressed(button) { frameInput.pressed.insert(button) }
            if input.wasReleased(button) { frameInput.released.insert(button) }
            if input.isDown(button) { frameInput.down.insert(button) }
        }
        frameInput.scroll = input.scrollDelta
        frameInput.modifiers = input.modifiers
        frameInput.dt = dt
        frameInput.pointerOverUI = ui.wantsPointer
        if keyboardFree && !gameViewActive {
            frameInput.move = Vec3(input.axis(negative: .a, positive: .d), input.axis(negative: .q, positive: .e),
                                   input.axis(negative: .s, positive: .w))
        }
        viewport.update(frameInput) { [unowned self] view in toolContext(view: view) }

        let wantsCapture = viewport.wantsMouseCapture
        if wantsCapture != captureRequested {
            input.isMouseCaptured = wantsCapture
            captureRequested = wantsCapture
        }
    }

    /// This frame's pointer for the Mesh Builder's viewport.
    private func workspaceInput(_ input: Input, dt: Float) -> ViewportInput {
        var frameInput = ViewportInput(mousePosition: uiPoint(input.mousePosition))
        frameInput.mouseDelta = input.mouseDelta / ui.uiScale
        for button in MouseButton.allCases {
            if input.wasPressed(button) { frameInput.pressed.insert(button) }
            if input.wasReleased(button) { frameInput.released.insert(button) }
            if input.isDown(button) { frameInput.down.insert(button) }
        }
        frameInput.scroll = input.scrollDelta
        frameInput.modifiers = input.modifiers
        frameInput.dt = dt
        frameInput.pointerOverUI = ui.wantsPointer
        return frameInput
    }

    /// A window point (the mouse) in the UI's points, which `uiScale` zooms.
    private func uiPoint(_ windowPoint: Vec2) -> Vec2 { windowPoint / ui.uiScale }

    /// Sizes the viewport's render target to its panel at `scale` framebuffer pixels per UI point.
    private func resizeTarget(scale: Float) {
        let rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        viewport.rect = rect
        if let size = sizer.update(rect: rect, scale: scale) {
            do {
                try target.resize(width: size.width, height: size.height)
            } catch {
                session.log.error("Resizing the viewport to \(size.width)x\(size.height) failed: \(error)")
            }
        }
        currentView = viewport.view(aspect: target.aspectRatio, clearColor: viewportClearColor())
        let gameRect = gameWidget.isEffectivelyVisible ? gameWidget.frame : .zero
        if let size = gameSizer.update(rect: gameRect, scale: scale) {
            do {
                try gameTarget.resize(width: size.width, height: size.height)
            } catch {
                session.log.error("Resizing the Game view to \(size.width)x\(size.height) failed: \(error)")
            }
        }
        gameCurrentView = gameWidget.isEffectivelyVisible ? gameView(aspect: gameTarget.aspectRatio) : nil
    }

    private func viewportClearColor() -> Vec4 { session.viewportClearColor }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(
            world: session.world, selection: session.selection, undo: session.undo, view: view, viewportRect: viewport.rect,
            pixelScale: ui.scale, toolMode: session.tool, isPlaying: session.isPlaying,
            meshBounds: { [unowned self] handle in meshBounds(handle) }, commands: session.commands, snapping: session.snapping,
            snapSteps: session.editorSettings.gizmoSnapping(enabled: session.snapping))
    }

    private func meshBounds(_ handle: MeshHandle) -> Bounds? {
        if let cached = meshBoundsCache[handle.key] { return cached }
        let bounds = sceneRenderer?.mesh(handle)?.bounds ?? builtinMeshBounds(handle)
        if let bounds { meshBoundsCache[handle.key] = bounds }
        return bounds
    }

    /// The viewport's debug shapes: grid, cameras, lights and axes for selected entities without a
    /// mesh (meshes get the selection outline), plus the tools' overlays in `toolDraw`.
    private func buildGizmos() {
        guard let view = currentView else { return }
        let context = toolContext(view: view)
        fillGizmos(gizmos, context: context, grid: true, gizmos: true)
        toolDraw.removeAll()
        transformTool.updateBillboards(view: ViewportProjection(view, size: context.viewportSize, pixelScale: context.pixelScale),
                                       world: session.world)
        for tool in viewport.tools { tool.draw(into: toolDraw, context: context) }
    }

    /// Puts the grid and / or the camera, light and axes gizmos into `draw` (cleared first).
    private func fillGizmos(_ draw: DebugDraw, context: ViewportToolContext, grid: Bool, gizmos: Bool) {
        let world = session.world
        draw.removeAll()
        if grid {
            draw.grid = DebugGrid(height: 0.005, spacing: 1, majorEvery: 10, fadeDistance: 80,
                                  minorColor: Vec4(0.2, 0.21, 0.25, 0.5), majorColor: Vec4(0.28, 0.3, 0.36, 0.85))
        } else {
            draw.grid = nil
        }
        guard gizmos else { return }
        let labelSize = 12 * ui.scale
        // Names read over the bright sky and dark ground alike.
        let labelShadow = Vec4(0, 0, 0, 0.85)
        // Names go just above the billboard (a constant distance on screen), else 0.45 units up.
        let projection = ViewportProjection(context.view, size: context.viewportSize, pixelScale: context.pixelScale)
        func labelPosition(_ position: Vec3) -> Vec3 {
            let up = projection.worldUnitsPerPoint(at: position).map { $0 * (transformTool.billboards.size / 2 + 12) } ?? 0.45
            return position + Vec3(0, up, 0)
        }

        world.query(Camera.self) { entity, camera in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let viewProjection = camera.projection(aspect: 16 / 9) * Camera.viewMatrix(world: matrix)
            let white = Vec4(0.92, 0.92, 0.95, 1)
            draw.frustum(viewProjection: viewProjection, color: white, farFraction: min(1.5 / camera.far, 1),
                         style: DebugDraw.Style(width: 1.5))
            draw.text(session.displayName(of: entity), at: labelPosition(matrix.translation), color: white, size: labelSize,
                      shadow: labelShadow)
        }
        world.query(DirectionalLight.self) { entity, light in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let start = matrix.translation, yellow = Vec4(1, 0.85, 0.3, 1)
            draw.arrow(from: start, to: start + light.travelDirection(world: matrix) * 1.5, color: yellow, headSize: 0.35,
                       style: DebugDraw.Style(width: 2))
            draw.text(session.displayName(of: entity), at: labelPosition(start), color: yellow, size: labelSize, shadow: labelShadow)
        }

        // A selected decal's projector box, with an arrow along its projection axis.
        for entity in session.selection.entities(in: world) where world.has(Decal.self, for: entity) {
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let orange = Vec4(1, 0.72, 0.42, 1)
            draw.box(matrix * Mat4.scale(Vec3(repeating: 0.5)), color: orange, style: DebugDraw.Style(width: 1.5, depth: .onTop))
            let forward = -Vec3(matrix.c2.x, matrix.c2.y, matrix.c2.z)
            draw.arrow(from: matrix.translation, to: matrix.translation + forward * 0.5, color: orange, headSize: 0.12,
                       style: DebugDraw.Style(width: 2, depth: .onTop))
        }

        for entity in session.selection.entities(in: world) where context.worldBounds(of: entity) == nil {
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            draw.axes(matrix, length: 0.6, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
    }

    public func renderOffscreen(engine: Engine, frame: Frame) {
        thumbnails?.render(frame: frame)
        renderCaptures(frame: frame)
        guard !isLauncherShown else { return }
        meshWorkspace.render(frame: frame)
        postFXWorkspace.render(frame: frame)
        if let game = gameCurrentView, gameSizer.width > 0, gameWidget.isEffectivelyVisible {
            sceneRenderer.beginViews(world: session.gameWorld, frame: frame, shadowFocus: game)
            sceneRenderer.renderView(game, into: gameTarget, frame: frame, debugDraw: gameDraw)
        }
        guard let view = currentView, sizer.width > 0, viewportWidget.isEffectivelyVisible else { return }
        sceneRenderer.beginViews(world: session.world, frame: frame, shadowFocus: view)
        let world = session.world
        let debugView = DebugView(view: view.view, projection: view.projection,
                                  viewportSize: (target.width, target.height), reversedZ: view.reversedZ)
        outline.renderView(view, sceneRenderer: sceneRenderer, world: world, selection: session.selection.entities(in: world),
                           primary: session.selection.primaryEntity(in: world), into: target, pixelScale: ui.scale,
                           frame: frame, debugDraw: gizmos) { [unowned self] pass in
            toolDrawRenderer.draw(toolDraw, in: pass, view: debugView)
        }
    }

    public func render(engine: Engine, pass: RenderPass) {}
}

// MARK: - Dragging assets from the browser

extension EditorApp {
    /// A browser cell is being dragged: remember it for the badge; on drop, find what is under
    /// the pointer (viewport, hierarchy row, inspector field) and hand it to the session.
    fileprivate func assetDragged(_ entry: AssetBrowserEntry, at position: Vec2, phase: AssetGridView.DragPhase) {
        switch phase {
        case .began, .moved:
            assetDrag = (entry, position)
        case .cancelled:
            assetDrag = nil
        case .dropped:
            assetDrag = nil
            guard let target = dropTarget(at: position) else { return }
            if session.drop(entry.item, on: target) { hierarchy.sync(force: true) }
        }
    }

    /// What a drop at `position` (window points) lands on.
    func dropTarget(at position: Vec2) -> AssetDropTarget? {
        let world = session.world
        if viewportWidget.isEffectivelyVisible, viewportWidget.frame.contains(position), let view = currentView {
            let rect = viewportWidget.frame
            let local = position - Vec2(rect.x, rect.y)
            let projection = ViewportProjection(view, size: Vec2(rect.width, rect.height), pixelScale: ui.scale)
            let hit = transformTool.picker.pick(at: local, in: projection, world: world)
            let ray = projection.ray(through: local)
            var point = ray.origin + ray.direction * 6
            if let hit {
                point = hit.point
            } else if ray.direction.y < -1e-4 {
                let t = -ray.origin.y / ray.direction.y
                if t > 0 && t < 200 { point = ray.origin + ray.direction * t }
            }
            return .viewport(position: point, entity: hit.flatMap { world.id(of: $0.entity) })
        }
        let tree = hierarchy.tree
        if tree.isEffectivelyVisible, tree.frame.contains(position) {
            let parent = tree.row(at: position).flatMap { tree.visibleNodes[$0].userData as? EntityID }
            return .hierarchy(parent: parent, position: hierarchy.spawnPosition())
        }
        if inspector.view.isEffectivelyVisible, inspector.view.frame.contains(position), session.inspectedAsset == nil,
           let entity = session.selection.primaryEntity(in: world), let id = world.id(of: entity) {
            var widget = ui.hitTest(position)
            while let current = widget {
                if current.name == "row.\(MeshRenderer.componentName).mesh" { return .field(entity: id, kind: .mesh) }
                if current.name == "row.\(MeshRenderer.componentName).material" { return .field(entity: id, kind: .material) }
                if current.name == "row.\(AudioEmitter.componentName).clip" { return .audioField(entity: id) }
                widget = current.parent
            }
        }
        return nil
    }

    /// The dragged asset's name next to the pointer, green where it can be dropped.
    fileprivate func drawAssetDrag(into list: UIDrawList) {
        guard let (entry, position) = assetDrag else { return }
        let theme = ui.theme
        let accepted = dropTarget(at: position) != nil
        let layout = ui.textLayout(entry.title, size: theme.fontSize)
        let badge = UIRect(x: position.x + 14, y: position.y + 10, width: layout.width + 16, height: layout.height + 8)
        list.fillRect(badge, color: theme.popupBackground.withAlpha(0.92), radii: UICornerRadii(4))
        list.strokeRect(badge, color: accepted ? UIColor(hex: 0x3fbf6f) : theme.popupBorder, width: 1, radii: UICornerRadii(4))
        list.drawText(layout, font: theme.font, at: Vec2(badge.x + 8, badge.y + 4), color: theme.textColor)
    }
}

// MARK: - Host: picking, stats and screenshots

/// A screenshot asked for through `capture`, until its frame is read back.
private struct CaptureJob {
    var request: ScreenshotRequest
    let future: CommandFuture<Image>
    /// Frames waited (thumbnails that aren't made yet).
    var frames = 0
    /// A mesh, material or prefab thumbnail that is ready: read it back this frame.
    var thumbnailTarget: RenderTarget?
}

extension EditorApp {
    public var viewportView: (view: SceneView, width: Int, height: Int)? {
        guard let currentView, sizer.width > 0 else { return nil }
        return (currentView, target.width, target.height)
    }

    public var pickMeshes: (any PickMeshSource)? { sceneRenderer }
    public var canRender: Bool { engine != nil }

    public var frameStats: EditorStatsSnapshot? { lastStats }

    /// Queues `request`. Camera views render in this frame's `renderOffscreen`, the window and
    /// panels are read back at the end of this frame, thumbnails once they are made.
    public func capture(_ request: ScreenshotRequest) -> CommandFuture<Image>? {
        guard let engine else { return nil }
        let future = CommandFuture<Image>()
        switch request.source {
        case .window:
            engine.captureFrame { image in
                if let image { future.resolve(image) } else { future.fail(CommandError.failed("This backend can't read the window back")) }
            }
        case .panel:
            guard let id = request.panel, let panel = dock.panel(id), dock.isOpen(id) else {
                future.fail(CommandError.failed("The \(request.panel ?? "") panel is closed (layout.reset brings it back)"))
                return future
            }
            // A background tab: bring it to the front so this frame draws it.
            if !panel.content.isEffectivelyVisible { dock.focusPanel(id) }
            engine.captureFrame { [weak self] image in
                guard let self, let image else {
                    future.fail(CommandError.failed("This backend can't read the window back"))
                    return
                }
                let rect = panel.content.frame
                guard let cropped = image.cropped(x: Int((rect.x * ui.scale).rounded()), y: Int((rect.y * ui.scale).rounded()),
                                                  width: Int((rect.width * ui.scale).rounded()),
                                                  height: Int((rect.height * ui.scale).rounded())) else {
                    future.fail(CommandError.failed("The \(id) panel isn't on screen"))
                    return
                }
                future.resolve(cropped)
            }
        case .viewport, .game, .camera, .thumbnail:
            captureJobs.append(CaptureJob(request: request, future: future))
        }
        return future
    }

    /// Finds thumbnails that are ready (or makes texture ones); gives up on what takes too long.
    func updateCaptures() {
        captureTargets.removeAll()
        guard !captureJobs.isEmpty else { return }
        for index in captureJobs.indices.reversed() {
            var job = captureJobs[index]
            guard job.request.source == .thumbnail else { continue }
            job.frames += 1
            defer { if index < captureJobs.count { captureJobs[index] = job } }
            guard let reference = job.request.asset, let assets = session.assets, let thumbnails else {
                job.future.fail(CommandError.failed("Thumbnails need an open project"))
                captureJobs.remove(at: index)
                continue
            }
            if job.frames > 600 {
                job.future.fail(CommandError.failed("The thumbnail of \(reference) wasn't ready after 10 seconds"))
                captureJobs.remove(at: index)
                continue
            }
            guard let kind = Self.thumbnailKind(of: reference, in: assets) else {
                job.future.fail(CommandError.failed("\(reference) has no thumbnail (it holds no mesh, material, texture or prefab)"))
                captureJobs.remove(at: index)
                continue
            }
            let object = kind.reference
            if kind.kind == .texture {
                guard assets.request(object.asset) == .loaded else { continue }
                guard let texture = assets.texture(object) else {
                    job.future.fail(CommandError.failed("\(object) didn't load"))
                    captureJobs.remove(at: index)
                    continue
                }
                job.future.resolve(AssetThumbnails.downsample(texture.image, to: thumbnails.size))
                captureJobs.remove(at: index)
                continue
            }
            _ = thumbnails.thumbnail(object, kind: kind.kind)
            job.thumbnailTarget = thumbnails.currentTarget(for: object)
        }
    }

    /// The object whose thumbnail stands for `reference` (as in the asset browser) and its kind.
    private static func thumbnailKind(of reference: AssetReference, in assets: AssetDatabase)
        -> (reference: AssetReference, kind: AssetKind)? {
        guard let record = assets.record(reference.asset) else { return nil }
        if let sub = reference.subAsset {
            return record.objects.first { $0.id == sub }.map { (reference, $0.kind) }
        }
        let object = record.objects.count == 1 ? record.objects.first : record.objects.last { $0.kind == .prefab }
        return object.map { (AssetReference(record.id, subAsset: $0.id), $0.kind) }
    }

    /// Renders this frame's camera-view screenshots into targets of their own and reads them
    /// (and ready thumbnails) back; called before the viewport renders, which then starts its
    /// views again, so its picture and stats are as without screenshots.
    func renderCaptures(frame: Frame) {
        guard !captureJobs.isEmpty else { return }
        var remaining: [CaptureJob] = []
        for job in captureJobs {
            if job.request.source == .thumbnail {
                guard let target = job.thumbnailTarget else {
                    remaining.append(job)
                    continue
                }
                frame.readBack(target) { image in job.future.resolve(image) }
                continue
            }
            let request = job.request
            guard let view = request.view ?? currentView else {
                job.future.fail(CommandError.failed("The viewport isn't visible"))
                continue
            }
            let width = request.view == nil ? target.width : request.width
            let height = request.view == nil ? target.height : request.height
            do {
                let shot = try RenderTarget(device: sceneRenderer.device, width: width, height: height, label: "screenshot")
                renderCapture(view, into: shot, request: request, frame: frame)
                captureTargets.append(shot)
                frame.readBack(shot) { image in job.future.resolve(image) }
            } catch {
                job.future.fail(error)
            }
        }
        captureJobs = remaining
    }

    private func renderCapture(_ view: SceneView, into shot: RenderTarget, request: ScreenshotRequest, frame: Frame) {
        // The Game View's world (a network play client's) for the game and the viewport showing it.
        let world = request.source == .game ? session.gameWorld : session.world
        sceneRenderer.beginViews(world: world, frame: frame, shadowFocus: view)
        // The viewport's own view gets the tools' overlays too (they are sized for it).
        let isViewport = request.view == nil
        let draw = DebugDraw()
        let context = toolContext(view: view)
        if request.grid || request.gizmos { fillGizmos(draw, context: context, grid: request.grid, gizmos: request.gizmos) }
        let debugView = DebugView(view: view.view, projection: view.projection, viewportSize: (shot.width, shot.height),
                                  reversedZ: view.reversedZ)
        let overlay: (RenderPass) -> Void = { [unowned self] pass in
            if request.gizmos && isViewport { toolDrawRenderer.draw(toolDraw, in: pass, view: debugView) }
        }
        if request.outline, let outliner = captureOutline ?? (try? SelectionOutlineRenderer(device: sceneRenderer.device,
                                                                                          maskLabel: "screenshot outline mask")) {
            captureOutline = outliner
            outliner.renderView(view, sceneRenderer: sceneRenderer, world: world, selection: session.selection.entities(in: world),
                                primary: session.selection.primaryEntity(in: world), into: shot, pixelScale: ui.scale,
                                frame: frame, debugDraw: draw, overlay: overlay)
        } else {
            sceneRenderer.renderView(view, into: shot, frame: frame, debugDraw: draw, overlay: overlay)
        }
    }
}

extension Image {
    /// The pixels in a rectangle (clipped to the image), or nil if none are.
    func cropped(x: Int, y: Int, width: Int, height: Int) -> Image? {
        let x0 = max(x, 0), y0 = max(y, 0), x1 = min(x + width, self.width), y1 = min(y + height, self.height)
        guard x1 > x0, y1 > y0 else { return nil }
        var pixels: [UInt8] = []
        pixels.reserveCapacity((x1 - x0) * (y1 - y0) * 4)
        for row in y0..<y1 {
            let start = (row * self.width + x0) * 4
            pixels += self.pixels[start..<(start + (x1 - x0) * 4)]
        }
        return Image(width: x1 - x0, height: y1 - y0, pixels: pixels)
    }
}

extension Mat4 {
    /// The translation column.
    var translation: Vec3 { Vec3(c3.x, c3.y, c3.z) }
}

/// Deterministic entity ids for screenshot runs (a SplitMix64 sequence).
struct SequentialIDs {
    private var state: UInt64 = 0x5EED_ED17_0000_0001

    mutating func next() -> EntityID {
        EntityID(high: step(), low: step())
    }

    private mutating func step() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// The viewport panel's content: the render target's image, a caption and, in play mode, a
/// colored frame. Not hit-testable, and its panel passes the pointer through, so clicks and
/// drags in it reach the viewport controller instead of the UI.
final class ViewportWidget: Widget {
    override var accessibilityRole: UIAccessibilityRole { .viewport }
    override var accessibilityText: String? { label }
    override var accessibilityValue: String? { caption }

    var texture: GPUTexture?
    /// Said over the background when there is no image (the Game view without a camera).
    var placeholder: String? { didSet { if placeholder != oldValue { setNeedsDisplay() } } }
    private let label: String
    var caption = "" { didSet { if caption != oldValue { setNeedsDisplay() } } }
    /// Whether the caption is drawn as a badge over the image (when the tab bar can't show it).
    var drawsCaption = true { didSet { if drawsCaption != oldValue { setNeedsDisplay() } } }
    var isPlaying = false
    /// The icons of cameras, lights and other entities without a mesh, over the image.
    var billboards: ViewportBillboards?
    /// How an entity is selected, for its billboard.
    var selectionState: (Entity) -> ViewportBillboards.SelectionState = { _ in .none }
    /// The network stats overlay's lines (EditorNetPlay.swift), top right; empty: none.
    var overlayLines: [String] = [] { didSet { if overlayLines != oldValue { setNeedsDisplay() } } }

    init(name: String = "viewport", label: String = "Scene viewport") {
        self.label = label
        super.init(name: name)
        isHitTestable = false
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        if let texture {
            list.drawImage(texture, in: frame)
        } else {
            list.fillRect(frame, color: theme.fieldBackground)
            if let placeholder {
                let layout = context?.textLayout(placeholder, size: theme.fontSize) ?? TextLayout(placeholder, font: theme.font, size: theme.fontSize)
                let origin = Vec2(snap(frame.x + (frame.width - layout.width) / 2), snap(frame.y + (frame.height - layout.height) / 2))
                list.withClip(frame) { list.drawText(layout, font: theme.font, at: origin, color: theme.secondaryTextColor) }
            }
        }
        if let billboards, !billboards.placed.isEmpty {
            list.withClip(frame) { billboards.draw(into: list, origin: Vec2(frame.x, frame.y), selection: selectionState) }
        }
    }

    override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        if drawsCaption && !caption.isEmpty {
            let layout = context?.textLayout(caption, size: theme.smallFontSize) ?? TextLayout(caption, font: theme.font, size: theme.smallFontSize)
            let badge = UIRect(x: frame.x + 8, y: frame.y + 8, width: snap(layout.width + 16), height: snap(layout.height + 8))
            // Dark in every theme (it sits on the scene), with light text.
            list.fillRect(badge, color: UIColor(0, 0, 0, 0.6), radii: UICornerRadii(4))
            list.drawText(layout, font: theme.font, at: Vec2(snap(badge.x + 8), snap(badge.y + 4)), color: UIColor(hex: 0xf2f4f8))
        }
        if !overlayLines.isEmpty {
            list.withClip(frame) { EditorNetPlay.drawOverlay(overlayLines, in: frame, list: list, theme: theme, context: context) }
        }
        if isPlaying {
            list.strokeRect(frame, color: UIColor(hex: 0x3fbf6f), width: 2)
        }
    }
}

/// The strip above the dock: Save (the Files panel creates and switches scenes), undo / redo (titled with what
/// they would undo), play / stop, the transform-tool selector and snapping, the project, the
/// document title and layout reset.
///
/// Every button is icon-only: its title stays its accessibility label (`ui.snapshot`, `ui.click
/// {label}`) and its tooltip says what it does, with the shortcut. That keeps the toolbar one row
/// down to about 800 points (the path fields and the title give way first); narrower, the least
/// used buttons go into a More (») menu at its end (`ToolbarRow`), so it never takes two rows.
@MainActor
final class Toolbar {
    let view: ToolbarRow
    /// The open project's name (its folder in the tooltip); Open / New Project pick the folder.
    let projectLabel = Label("No project", role: .secondary, name: "projectName")
    private unowned let app: EditorApp
    private let undoButton: Button
    private let redoButton: Button
    private let playButton: Button
    private let pauseButton: Button
    private let stepButton: Button
    private let gameViewButton: Button
    /// Opens the Network menu (EditorNetPlay.swift): play with clients, the Game View's world, conditions, the overlay.
    private let netButton: Button
    /// Reload Game Code; shown when the editor has game code (`--game`, Project.json).
    private let reloadGameButton: Button
    /// Build Game; shown when a project is open.
    private let buildGameButton: Button
    /// Open in Code Editor (`file.openInCodeEditor`): the project's code in the editor picked in Settings.
    private let codeEditorButton: Button
    private let timeScale: Dropdown
    /// The time scales the toolbar offers.
    static let timeScales: [Double] = [0.1, 0.25, 0.5, 1, 2, 4]
    private let toolButtons: [(EditorTool, Button)]
    private let snapButton: Button
    /// Opens the View menu: Reset Layout, the themes and the UI zooms.
    private var viewButton: Button!
    /// Buttons enabled by their command's availability.
    private var commandButtons: [(CommandID, Button)] = []
    private let titleLabel = Label("", role: .secondary, name: "documentTitle")

    init(app: EditorApp) {
        self.app = app
        let session = app.session
        undoButton = Button("Undo", name: "undo") { session.run(EditUndoCommand.self) }
        redoButton = Button("Redo", name: "redo") { session.run(EditRedoCommand.self) }
        playButton = Button("Play", name: "play") { session.run(PlayToggleCommand.self) }
        pauseButton = Button("Pause", name: "pause") { session.run(PlayPauseCommand.self, .init()) }
        stepButton = Button("Step", name: "step") { session.run(PlayStepCommand.self, .init()) }
        gameViewButton = Button("Game", name: "gameView") { session.run(ViewGameCameraCommand.self, .init()) }
        netButton = Button("Network", name: "network")
        reloadGameButton = Button("Reload Game", name: "reloadGame") { _ = try? session.commands.start(GameReloadCommand.self, .init()) }
        buildGameButton = Button("Build Game", name: "buildGame") { [unowned app] in app.showExportDialog() }
        timeScale = Dropdown(options: Self.timeScales.map(Self.timeScaleTitle), selectedIndex: Self.timeScales.firstIndex(of: 1) ?? 0,
                             name: "timeScale") { index in
            session.run(PlaySetTimeScaleCommand.self, .init(scale: Self.timeScales[index]))
        }
        timeScale.tooltip = "Play speed (time scale)"
        gameViewButton.tooltip = "Play in the Game view: Play brings the Game tab to the front and sends the game the keyboard and mouse"
        netButton.tooltip = "Play with network clients in this editor, pick the world the Game View shows, simulate latency and loss"
        toolButtons = EditorTool.allCases.map { tool in
            (tool, Button(tool.title, name: tool.rawValue) { session.run(ToolSetCommand.self, .init(tool: tool)) })
        }
        snapButton = Button("Snap", name: "snapping") { session.run(ToolSnappingCommand.self, .init()) }
        let shortcuts = app.shortcuts
        let saveButton = Button("Save", name: "save") { [unowned app] in app.save() }
        codeEditorButton = Button(ExternalLaunch.openTitle(session.editorSettings.codeEditor), name: "openInCodeEditor") {
            session.run(FileOpenInCodeEditorCommand.self, .init())
        }
        let closeProjectButton = Button("Close Project", name: "closeProject") { [unowned app] in app.requestCloseProject() }
        closeProjectButton.tooltip = "Close the project and go back to the launcher (the recent projects)"
        codeEditorButton.tooltip = "Open the project's code in the code editor picked in Settings"
        // The name gives way (ending in "…") when the window is narrow.
        projectLabel.style.shrink = 1
        projectLabel.style.minWidth = 0
        saveButton.tooltip = shortcuts.tooltip("Save the scene", for: .save)
        let viewButton = Button("View", name: "view")
        viewButton.tooltip = "Open any panel (Files, Scripts, Console…), settings, reset the panel layout, pick the theme and the UI zoom"
        for (tool, button) in toolButtons { button.tooltip = "\(tool.title) tool" }
        snapButton.tooltip = "Snap gizmo drags to 0.5 units, 15° and 0.1 scale steps (hold \(KeyModifiers.shortcut == .command ? "⌘" : "Ctrl") to invert)"
        // Icon-only buttons: the titles stay their accessibility labels and default tooltips.
        let icons: [(Button, String)] = [
            (saveButton, "save"),
            (undoButton, "undo-2"), (redoButton, "redo-2"), (playButton, "play"), (pauseButton, "pause"),
            (stepButton, "step-forward"), (gameViewButton, "gamepad-2"), (netButton, "network"), (reloadGameButton, "refresh-cw"),
            (buildGameButton, "hammer"), (snapButton, "magnet"), (codeEditorButton, "file-code"),
            (closeProjectButton, "folder-x"), (viewButton, "appearance"),
        ] + toolButtons.map { ($0.1, EditorIcons.tool($0.0).name) }
        for (button, icon) in icons {
            button.icon = EditorIcons.named(icon)
            button.showsTitle = false
        }
        // View reads as a menu: its title shows beside the icon.
        viewButton.showsTitle = true
        commandButtons = [(SceneSaveCommand.id, saveButton), (LauncherShowCommand.id, closeProjectButton)]
        // What each control runs, for introspection (`ui.snapshot`) and the parity test.
        let tagged: [(Widget, CommandID)] = commandButtons.map { ($0.1, $0.0) } + [
            (undoButton, EditUndoCommand.id), (redoButton, EditRedoCommand.id), (playButton, PlayToggleCommand.id),
            (pauseButton, PlayPauseCommand.id), (stepButton, PlayStepCommand.id), (gameViewButton, ViewGameCameraCommand.id),
            (netButton, NetStartCommand.id),
            (reloadGameButton, GameReloadCommand.id), (buildGameButton, GameBuildCommand.id),
            (timeScale, PlaySetTimeScaleCommand.id),
            (codeEditorButton, FileOpenInCodeEditorCommand.id),
            (snapButton, ToolSnappingCommand.id), (viewButton, ViewAppearanceCommand.id),
        ] + toolButtons.map { ($0.1, ToolSetCommand.id) }
        for (widget, id) in tagged { widget.command = id.rawValue }
        // Undo / redo titles name the step ("Undo AI: Set Transform.position on Crate…"); the
        // buttons show the icon and the tooltip the whole title.
        view = ToolbarRow(spacing: 4, padding: EdgeInsets(horizontal: 8, vertical: 5), name: "toolbar")
        // One row: what doesn't fit the window goes into the More (») menu at the end, least used
        // first; the scene and project actions people reach for (Play, the tools, Build / Reload
        // Game, View) go last.
        view.overflowOrder = [closeProjectButton, codeEditorButton, snapButton,
                              stepButton, redoButton, netButton, gameViewButton, pauseButton, undoButton, saveButton]
            + toolButtons.map(\.1).reversed() + [reloadGameButton, buildGameButton, playButton]
        view.background = (app.ui?.theme ?? UITheme()).panelBackground
        // Vertical rules between the groups (a bare Separator measures 0 points tall in a row).
        func separator() -> Separator {
            let rule = Separator(.vertical)
            rule.style.height = 18
            return rule
        }
        // The document title gives way (ending in "…", whole in its tooltip) before the row wraps.
        titleLabel.style.shrink = 1
        titleLabel.style.minWidth = 0
        // Squeezed to a few letters ("U…") it says nothing: then it hides (the window title and
        // the label's tooltip still name the document).
        titleLabel.minimumTruncatedWidth = 64
        // Project on the left, Play in the middle, the tools after it, the document and View on the right.
        view.addChildren([
            projectLabel, closeProjectButton, codeEditorButton, buildGameButton,
            separator(),
            saveButton, undoButton, redoButton,
            Spacer(),
            playButton, pauseButton, stepButton, timeScale, gameViewButton, netButton, reloadGameButton,
            Spacer(),
        ] + toolButtons.map(\.1) + [
            snapButton,
            Spacer(),
            titleLabel,
            viewButton,
        ])
        self.viewButton = viewButton
        viewButton.action = { [unowned self] in showViewMenu() }
        netButton.action = { [unowned self, unowned app] in EditorNetMenu.show(anchor: netButton, session: app.session) }
        refresh()
    }

    /// The panels the View menu lists, in its order (`EditorLayout.panelIDs`, the Scene view first).
    var menuPanels: [(id: String, title: String)] {
        EditorLayout.panelIDs.compactMap { id in app.dock.panel(id).map { (id, $0.title) } }
    }

    /// The View menu: every panel (open ones checked; picking one opens a closed panel where the
    /// default layout has it, or brings an open one to the front), then Settings…, Reset Layout,
    /// the themes (`EditorApp.menuThemes`) and the zooms, the current ones checked.
    func showViewMenu() {
        guard let context = view.context else { return }
        let panels = menuPanels
        let themes = EditorApp.menuThemes, zooms = EditorApp.menuZooms
        let settingsTitle = "Settings… (\(app.shortcuts.shortcutText(for: .settings)))"
        let options = [settingsTitle, "Reset Layout"] + themes.map { "\($0) Theme" } + zooms.map { "Zoom \(Int(($0 * 100).rounded()))%" }
        let menu = PopupMenu(items: panels.map(\.title) + options, anchor: viewButton, name: "viewMenu")
        menu.itemCommandIDs = panels.map { _ in PanelOpenCommand.id.rawValue }
            + [SettingsGetCommand.id.rawValue, LayoutResetCommand.id.rawValue]
            + options.dropFirst(2).map { _ in ViewAppearanceCommand.id.rawValue }
        menu.itemIcons = panels.map { EditorIcons.panelIconNames[$0.id].map(EditorIcons.named) }
            + [EditorIcons.named("sliders-horizontal"), EditorIcons.named("layout-dashboard")]
        let first = panels.count
        var checked = Set(panels.indices.filter { app.dock.isOpen(panels[$0].id) })
        if let theme = themes.firstIndex(of: context.theme.name) { checked.insert(first + 2 + theme) }
        if let zoom = zooms.firstIndex(of: app.preferredUIScale) { checked.insert(first + 2 + themes.count + zoom) }
        menu.checkedIndices = checked
        let session = app.session
        menu.onSelect = { [unowned app] index in
            if index < first {
                session.run(PanelOpenCommand.self, .init(panel: panels[index].id))
                return
            }
            let index = index - first
            switch index {
            case 0: app.showSettings()
            case 1: app.resetLayout()
            case 2...(themes.count + 1): session.run(ViewAppearanceCommand.self, .init(theme: themes[index - 2]))
            default: session.run(ViewAppearanceCommand.self, .init(uiScale: zooms[index - 2 - themes.count]))
            }
        }
        context.presentOverlay(menu)
    }

    func refresh() {
        let session = app.session
        let undo = session.undo
        let shortcuts = app.shortcuts
        set(undoButton, title: undo.undoTitle, enabled: session.commands.isAvailable(EditUndoCommand.self))
        set(redoButton, title: undo.redoTitle, enabled: session.commands.isAvailable(EditRedoCommand.self))
        for (id, button) in commandButtons { set(button, title: button.title, enabled: session.commands.isAvailable(id)) }
        set(playButton, title: session.isPlaying ? "Stop" : "Play", enabled: true)
        setIcon(playButton, session.isPlaying ? "square" : "play")
        setIcon(pauseButton, session.isPaused ? "play" : "pause")
        setIcon(reloadGameButton, session.gameModule.isBusy ? "loader" : "refresh-cw")
        setIcon(buildGameButton, session.gameExport.isBusy ? "loader" : "hammer")
        let snapRole: Button.Role = session.snapping ? .primary : .normal
        if snapButton.role != snapRole { snapButton.role = snapRole }
        undoButton.tooltip = shortcuts.tooltip(undo.undoTitle, for: .undo)
        redoButton.tooltip = shortcuts.tooltip(undo.redoTitle, for: .redo)
        playButton.tooltip = shortcuts.tooltip(session.isPlaying ? "Stop and restore the scene" : "Play the scene", for: .togglePlay)
        playButton.role = session.isPlaying ? .primary : .normal
        set(pauseButton, title: session.isPaused ? "Resume" : "Pause", enabled: session.isPlaying)
        set(stepButton, title: stepButton.title, enabled: session.isPlaying)
        pauseButton.tooltip = shortcuts.tooltip(session.isPaused ? "Resume the game" : "Pause the game", for: .togglePause)
        stepButton.tooltip = shortcuts.tooltip("Pause and run one frame", for: .step)
        let gameRole: Button.Role = session.showsGameCamera ? .primary : .normal
        if gameViewButton.role != gameRole { gameViewButton.role = gameRole }
        let netRole: Button.Role = session.netPlay != nil ? .primary : .normal
        if netButton.role != netRole { netButton.role = netRole }
        if let index = Self.timeScales.firstIndex(of: session.timeScale), timeScale.selectedIndex != index { timeScale.select(index) }
        let game = session.gameModule
        view.setAvailable(reloadGameButton, game.isConfigured)
        set(reloadGameButton, title: game.isBusy ? "Building…" : "Reload Game", enabled: session.commands.isAvailable(GameReloadCommand.self))
        let reloadTip = game.lastError.map { "Rebuild and reload the game code, keeping the scene. Last error: \($0)" }
            ?? "Rebuild and reload the game code (\(game.loaded?.module.name ?? "not loaded")), keeping the scene"
        if reloadGameButton.tooltip != reloadTip { reloadGameButton.tooltip = reloadTip }
        let codeTitle = ExternalLaunch.openTitle(session.editorSettings.codeEditor)
        if codeEditorButton.title != codeTitle { codeEditorButton.title = codeTitle }
        let export = session.gameExport
        view.setAvailable(buildGameButton, session.project != nil)
        let projectName = session.project?.name ?? "No project"
        if projectLabel.text != projectName { projectLabel.text = projectName }
        let projectTip = session.project.map { "Project folder: \($0.root.path)" } ?? "No project open: Open Project or New Project"
        if projectLabel.tooltip != projectTip { projectLabel.tooltip = projectTip }
        set(buildGameButton, title: export.isBusy ? "Building…" : "Build Game", enabled: session.commands.isAvailable(GameBuildCommand.self))
        let buildTip = export.lastError.map { "Export the game (cook the assets, build a standalone app). Last error: \($0)" }
            ?? export.lastResult.map { "Export the game again (last: \($0.outputPath))" }
            ?? "Export the game: cook the scenes' assets into a pack and build a standalone app into Build/"
        if buildGameButton.tooltip != buildTip { buildGameButton.tooltip = buildTip }
        for (tool, button) in toolButtons {
            let role: Button.Role = tool == session.tool ? .primary : .normal
            if button.role != role { button.role = role }
        }
        let title = session.document.title + (session.isPlaying ? " (playing)" : "")
        if titleLabel.text != title { titleLabel.text = title }
    }

    /// "0.5×", "1×", "2×".
    static func timeScaleTitle(_ scale: Double) -> String {
        (scale == scale.rounded() ? String(Int(scale)) : String(scale)) + "×"
    }

    private func setIcon(_ button: Button, _ name: String) {
        if button.icon?.name != name { button.icon = EditorIcons.named(name) }
    }

    private func set(_ button: Button, title: String, enabled: Bool) {
        if button.title != title { button.title = title }
        if button.isEnabled != enabled { button.isEnabled = enabled }
    }
}
