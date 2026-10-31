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
    private var meshBoundsCache: [String: Bounds] = [:]
    /// Watches the open project's `Assets/` folder.
    private var assetWatcher: FileWatcher?

    let dock = DockSpace()
    private(set) var hierarchy: HierarchyPanel!
    private(set) var inspector: InspectorPanel!
    private(set) var console: ConsolePanel!
    private(set) var activity: ActivityPanel!
    private(set) var statusBar: StatusBar!
    /// The Assets panel (browser) and its thumbnails.
    public private(set) var assetBrowser: AssetBrowserPanel!
    private var thumbnails: AssetThumbnails?
    /// An asset being dragged from the browser, and where the pointer is.
    private var assetDrag: (entry: AssetBrowserEntry, position: Vec2)?
    private let stats = StatsPanel()
    let viewportWidget = ViewportWidget()
    private(set) var toolbar: Toolbar!

    private var shownAssetKeys: [AssetReference] = []
    private weak var shownAssets: AssetDatabase?
    private var prefs = EditorPrefs()
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
    /// The viewport shows the game camera this frame (playing, `showsGameCamera`, a Camera entity).
    private var gameViewActive = false
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
        sceneRenderer = try SceneRenderer(device: engine.device, quality: engine.quality)
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                           key: StarterScene.checkerMaterial.key)
        target = try RenderTarget(device: engine.device, width: 640, height: 360, label: "viewport")
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
        ui.setViewport(size: size, scale: scale)
        ui.layoutIfNeeded()
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
        syncPanels()
    }

    /// The part of setup that needs no GPU: the UI, the prefs, the project and the scene.
    private func finishSetup() {
        viewport.tools = [transformTool]

        var theme = UITheme.dark()
        if options.deterministic { theme.caretBlinkPeriod = 0 }
        ui = UIContext(theme: theme)
        session.log.echoesToStandardOutput = !options.deterministic

        if let url = options.prefsURL {
            do {
                prefs = try EditorPrefsStore(url: url).load() ?? EditorPrefs()
            } catch {
                session.log.warning("Ignoring unreadable editor prefs at \(url.path): \(error)")
            }
        }
        var ai = prefs.ai ?? AISettings()
        if options.mcp.readOnly { ai.readOnly = true }
        session.aiSettings = ai
        buildUI()

        session.onWillReplaceWorld = { [unowned self] in inspector.recorder.finishGesture() }
        session.onAISettingsChange = { [unowned self] in aiSettingsChanged() }
        session.onChange = { [unowned self] in toolbar.refresh() }
        session.onAssetsChange = { [unowned self] in assetsChanged() }
        // Game code before the scene, so the scene's game components load typed.
        if let game = options.game {
            session.gameModule.commandLineSettings = game
            session.gameModule.configure(game, base: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
            _ = try? session.commands.start(GameReloadCommand.self, .init(build: !(game.library != nil && game.buildCommand == nil)))
        }
        if let path = options.projectPath, session.run(ProjectOpenCommand.self, .init(path: path)) != nil {
            toolbar.projectPath.text = path
        } else if !options.deterministic, let path = prefs.lastProjectPath {
            toolbar.projectPath.text = path
        }
        if let path = options.scenePath {
            if session.run(SceneOpenCommand.self, .init(path: path)) == nil { session.run(SceneNewCommand.self) }
            toolbar.path.text = path
        } else {
            session.run(SceneNewCommand.self)
            toolbar.path.text = prefs.lastScenePath ?? "scene.json"
        }
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
        if let path = options.selectAssetPath { assetBrowser.model.reveal(path) }
        session.log.info("Editor ready. Right-drag flies the camera, Alt-drag or middle-drag orbits, the wheel zooms.")
        if options.mcp.http, session.aiSettings.httpEnabled, let mcp {
            do {
                try mcp.startHTTP(port: options.mcp.port)
            } catch {
                session.log.warning("MCP HTTP server unavailable: \(error)")
            }
        }
        toolbar.refresh()
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

        let viewportPanel = DockPanel(id: EditorLayout.viewport, title: "Scene", content: viewportWidget, isClosable: false,
                                      minSize: Vec2(200, 120))
        viewportPanel.passesPointerThrough = true
        dock.addPanel(viewportPanel)
        dock.addPanel(DockPanel(id: EditorLayout.hierarchy, title: "Hierarchy", content: hierarchy.view, minSize: Vec2(160, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.inspector, title: "Inspector", content: inspector.view, minSize: Vec2(220, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.console, title: "Console", content: console.view))
        dock.addPanel(DockPanel(id: EditorLayout.stats, title: "Stats", content: stats.view))
        dock.addPanel(DockPanel(id: EditorLayout.assets, title: "Assets", content: assetBrowser.view, minSize: Vec2(240, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.activity, title: "Activity", content: activity.view, minSize: Vec2(240, 100)))
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
        // Parity and introspection: what the dock's tabs and close buttons run.
        dock.itemCommands = ["tab": PanelFocusCommand.id.rawValue, "close": PanelCloseCommand.id.rawValue]
        viewportWidget.command = ViewPickCommand.id.rawValue
        dock.style.grow = 1
        dock.padding = EdgeInsets(top: 0, left: 4, bottom: 4, right: 4)
        dock.background = ui.theme.fieldBackground
        dock.onLayoutChange = { [unowned self] layout in
            prefs.layout = layout
            prefsDirty = true
        }

        toolbar = Toolbar(app: self)
        statusBar = StatusBar(app: self)
        let column = VStack(name: "editorRoot", [toolbar.view, dock, statusBar.view])
        column.isHitTestable = false
        ui.root.addChild(column)
    }

    /// Dropdown options: the renderer's code-registered keys, then the project's assets.
    private func makeAssetChoices() -> AssetChoices {
        AssetChoices(
            // Without a renderer (headless) the built-in meshes and the starter scene's material.
            meshes: { [unowned self] in
                sceneRenderer.map { $0.prep.meshes.keys.filter { AssetReference($0) == nil } }
                    ?? [MeshHandle.cube.key, MeshHandle.sphere.key, MeshHandle.plane.key]
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
        let keys = session.assets.map { $0.references(of: .mesh) + $0.references(of: .material) + $0.references(of: .texture) } ?? []
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
    }

    func openProject() {
        if let result = session.run(ProjectOpenCommand.self, .init(path: toolbar.projectPath.text)) {
            toolbar.projectPath.text = result.path
        }
    }

    func newProject() {
        if let result = session.run(ProjectNewCommand.self, .init(path: toolbar.projectPath.text)) {
            toolbar.projectPath.text = result.path
        }
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
        // Requests from MCP clients run here, between frames, before the UI reads the session.
        if let mcp {
            mcp.pump()
            if mcp.stdioClientDisconnected { engine.quit() }
        }

        // What the UI does with the keyboard, before and after it handles this frame's input.
        func textEditing() -> Bool { ui.focusedWidget?.wantsTextInput == true || input.isTextInputActive }
        let textBefore = textEditing(), focusedBefore = ui.focusedWidget != nil, overlayBefore = !ui.overlays.isEmpty
        ui.update(engine: engine, dt: dt)
        let focus = EditorShortcuts.Focus(textEditing: textBefore || textEditing(), overlayOpen: overlayBefore,
                                          widgetFocused: focusedBefore)
        for command in shortcuts.actions(for: input.keyPresses, focus: focus) { invoke(command) }

        updateViewport(engine: engine, dt: dt, keyboardFree: !focus.textEditing)
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
        resizeTarget(scale: engine.ui.scale)
        buildGizmos()
        viewportWidget.texture = target.texture
        viewportWidget.caption = playCaption()
        viewportWidget.isPlaying = session.isPlaying
        ui.draw(into: engine.ui)
        drawAssetDrag(into: engine.ui)

        input.cursor = cursorShape(for: ui.desiredCursor)
        let project = session.project.map { " — \($0.name)" } ?? ""
        let title = "\(session.document.title)\(project) — Editor" + (session.isPlaying ? " [Playing]" : "")
        if engine.title != title { engine.title = title }
        if prefsDirty && !MouseButton.allCases.contains(where: input.isDown) { savePrefs() }
    }

    /// Runs the command `id` as the UI does (a shortcut): commands that need an answer from the
    /// user ask first (delete confirms, import picks files, save takes the path field); the others
    /// run with default arguments. Unavailable commands do nothing.
    func invoke(_ id: CommandID) {
        switch id {
        case .save: save()
        case .delete: confirmDeleteSelection()
        case .importAsset: assetBrowser.beginImport()
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
        if session.run(SceneSaveCommand.self, .init(path: toolbar.path.text)) != nil { rememberScenePath() }
    }

    func saveAs() {
        if session.run(SceneSaveAsCommand.self, .init(path: toolbar.path.text)) != nil { rememberScenePath() }
    }

    func open() {
        if session.run(SceneOpenCommand.self, .init(path: toolbar.path.text)) != nil {
            hierarchy.sync(force: true)
            rememberScenePath()
        }
    }

    private func rememberScenePath() {
        guard let path = session.document.url?.path else { return }
        toolbar.path.text = path
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
    private func playCaption() -> String {
        guard session.isPlaying else { return "Perspective · \(session.tool.title)" }
        let state = session.isPaused ? "Paused · frame \(session.playFrame)" : "Playing"
            + (session.timeScale != 1 ? " · \(Toolbar.timeScaleTitle(session.timeScale))" : "")
        guard gameViewActive, let camera = RenderPrep.findCamera(in: session.world)?.entity else {
            return "Perspective · \(session.tool.title) · \(state)"
        }
        return "Game · \(session.displayName(of: camera)) · \(state)"
    }

    /// The scene's game camera view at the viewport's aspect, when the viewport should show it.
    private func gameView(aspect: Float) -> SceneView? {
        guard session.isPlaying, session.showsGameCamera,
              let camera = RenderPrep.findCamera(in: session.world)?.entity else { return nil }
        return SceneView(camera: camera, in: session.world, aspect: aspect)
    }

    /// Game view: the keyboard (unless the UI is typing) and the mouse over the viewport go to
    /// the game's input as events, positions relative to the viewport. Presses start only over
    /// the viewport; what is down stays down until released.
    private func forwardInputToGame(_ input: Input, keyboardFree: Bool) {
        let rect = viewportWidget.frame
        let hovered = viewportWidget.isEffectivelyVisible && rect.contains(input.mousePosition) && !ui.wantsPointer
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
            let local = input.mousePosition - Vec2(rect.x, rect.y)
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
        if gameView(aspect: sizer.aspectRatio) != nil {
            // The game has the viewport: no editor camera, picking or gizmos.
            forwardInputToGame(input, keyboardFree: keyboardFree)
            if captureRequested {
                input.isMouseCaptured = false
                captureRequested = false
            }
            return
        }
        releaseForwardedInput()
        var frameInput = ViewportInput(mousePosition: input.mousePosition)
        frameInput.mouseDelta = input.mouseDelta
        for button in MouseButton.allCases {
            if input.wasPressed(button) { frameInput.pressed.insert(button) }
            if input.wasReleased(button) { frameInput.released.insert(button) }
            if input.isDown(button) { frameInput.down.insert(button) }
        }
        frameInput.scroll = input.scrollDelta
        frameInput.modifiers = input.modifiers
        frameInput.dt = dt
        frameInput.pointerOverUI = ui.wantsPointer
        if keyboardFree {
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
        if let game = gameView(aspect: target.aspectRatio) {
            currentView = game
            gameViewActive = true
        } else {
            currentView = viewport.view(aspect: target.aspectRatio, clearColor: viewportClearColor())
            gameViewActive = false
        }
    }

    private func viewportClearColor() -> Vec4 { session.viewportClearColor }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(
            world: session.world, selection: session.selection, undo: session.undo, view: view, viewportRect: viewport.rect,
            pixelScale: ui.scale, toolMode: session.tool, isPlaying: session.isPlaying,
            meshBounds: { [unowned self] handle in meshBounds(handle) }, commands: session.commands)
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
        // The game view shows what the game camera sees, nothing of the editor's.
        fillGizmos(gizmos, context: context, grid: !gameViewActive, gizmos: !gameViewActive)
        toolDraw.removeAll()
        guard !gameViewActive else { return }
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

        world.query(Camera.self) { entity, camera in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let viewProjection = camera.projection(aspect: 16 / 9) * Camera.viewMatrix(world: matrix)
            let white = Vec4(0.92, 0.92, 0.95, 1)
            draw.frustum(viewProjection: viewProjection, color: white, farFraction: min(1.5 / camera.far, 1),
                         style: DebugDraw.Style(width: 1.5))
            draw.text(session.displayName(of: entity), at: matrix.translation + Vec3(0, 0.45, 0), color: white, size: labelSize)
        }
        world.query(DirectionalLight.self) { entity, light in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let start = matrix.translation, yellow = Vec4(1, 0.85, 0.3, 1)
            draw.arrow(from: start, to: start + light.travelDirection(world: matrix) * 1.5, color: yellow, headSize: 0.35,
                       style: DebugDraw.Style(width: 2))
            draw.text(session.displayName(of: entity), at: start + Vec3(0, 0.45, 0), color: yellow, size: labelSize)
        }

        for entity in session.selection.entities(in: world) where context.worldBounds(of: entity) == nil {
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            draw.axes(matrix, length: 0.6, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
    }

    public func renderOffscreen(engine: Engine, frame: Frame) {
        thumbnails?.render(frame: frame)
        renderCaptures(frame: frame)
        guard let view = currentView, sizer.width > 0 else { return }
        sceneRenderer.beginViews(world: session.world, frame: frame, shadowFocus: view)
        let world = session.world
        guard !gameViewActive else {
            sceneRenderer.renderView(view, into: target, frame: frame, debugDraw: gizmos)
            return
        }
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
            var request = job.request
            if request.view == nil && gameViewActive {
                // The viewport shows the game camera: so does its screenshot, without editor overlays.
                (request.grid, request.gizmos, request.outline) = (false, false, false)
            }
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
        let world = session.world
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
    override var accessibilityText: String? { "Scene viewport" }
    override var accessibilityValue: String? { caption }

    var texture: GPUTexture?
    var caption = "" { didSet { if caption != oldValue { setNeedsDisplay() } } }
    var isPlaying = false

    init() {
        super.init(name: "viewport")
        isHitTestable = false
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        if let texture {
            list.drawImage(texture, in: frame)
        } else {
            list.fillRect(frame, color: theme.fieldBackground)
        }
    }

    override func drawForeground(_ list: UIDrawList, theme: UITheme) {
        let layout = context?.textLayout(caption, size: theme.smallFontSize) ?? TextLayout(caption, font: theme.font, size: theme.smallFontSize)
        let badge = UIRect(x: frame.x + 8, y: frame.y + 8, width: snap(layout.width + 16), height: snap(layout.height + 8))
        list.fillRect(badge, color: UIColor(0, 0, 0, 0.45), radii: UICornerRadii(4))
        list.drawText(layout, font: theme.font, at: Vec2(snap(badge.x + 8), snap(badge.y + 4)), color: theme.textColor)
        if isPlaying {
            list.strokeRect(frame, color: UIColor(hex: 0x3fbf6f), width: 2)
        }
    }
}

/// The strip above the dock: file actions with a path field, undo / redo (titled with what
/// they would undo), play / stop, the transform-tool selector, the document title and layout reset.
@MainActor
final class Toolbar {
    let view: HStack
    let path = TextField(placeholder: "path/to/scene.json", name: "scenePath")
    let projectPath = TextField(placeholder: "path/to/project", name: "projectPath")
    private unowned let app: EditorApp
    private let undoButton: Button
    private let redoButton: Button
    private let playButton: Button
    private let pauseButton: Button
    private let stepButton: Button
    private let gameViewButton: Button
    /// Reload Game Code; shown when the editor has game code (`--game`, Project.json).
    private let reloadGameButton: Button
    /// Build Game; shown when a project is open.
    private let buildGameButton: Button
    private let timeScale: Dropdown
    /// The time scales the toolbar offers.
    static let timeScales: [Double] = [0.1, 0.25, 0.5, 1, 2, 4]
    private let toolButtons: [(EditorTool, Button)]
    private let resetButton: Button
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
        reloadGameButton = Button("Reload Game", name: "reloadGame") { _ = try? session.commands.start(GameReloadCommand.self, .init()) }
        buildGameButton = Button("Build Game", name: "buildGame") { _ = try? session.commands.start(GameBuildCommand.self, .init()) }
        timeScale = Dropdown(options: Self.timeScales.map(Self.timeScaleTitle), selectedIndex: Self.timeScales.firstIndex(of: 1) ?? 0,
                             name: "timeScale") { index in
            session.run(PlaySetTimeScaleCommand.self, .init(scale: Self.timeScales[index]))
        }
        timeScale.tooltip = "Play speed (time scale)"
        timeScale.style.width = 64
        gameViewButton.tooltip = "Show the scene's camera in the viewport while playing, and send it the keyboard and mouse"
        toolButtons = EditorTool.allCases.map { tool in
            (tool, Button(tool.title, name: tool.rawValue) { session.run(ToolSetCommand.self, .init(tool: tool)) })
        }
        path.style.width = 220
        // The path fields give way first when the window is narrow.
        path.style.shrink = 1
        path.style.minWidth = 72
        let shortcuts = app.shortcuts
        let newButton = Button("New", name: "new") { session.run(SceneNewCommand.self) }
        let openButton = Button("Open", name: "open") { [unowned app] in app.open() }
        let saveButton = Button("Save", name: "save") { [unowned app] in app.save() }
        let saveAsButton = Button("Save As", name: "saveAs") { [unowned app] in app.saveAs() }
        resetButton = Button("Reset Layout", name: "resetLayout") { [unowned app] in app.resetLayout() }
        let openProjectButton = Button("Open Project", name: "openProject") { [unowned app] in app.openProject() }
        let newProjectButton = Button("New Project", name: "newProject") { [unowned app] in app.newProject() }
        openProjectButton.tooltip = "Open the project folder at the project path and import its assets"
        newProjectButton.tooltip = "Create a project (Project.json, Assets/, Library/) at the project path"
        projectPath.tooltip = "Project folder, used by Open Project and New Project"
        projectPath.style.width = 160
        projectPath.style.shrink = 1
        projectPath.style.minWidth = 64
        newButton.tooltip = "Start a new scene"
        openButton.tooltip = "Open the scene file at the path"
        saveButton.tooltip = shortcuts.tooltip("Save the scene", for: .save)
        saveAsButton.tooltip = "Save the scene to the path"
        path.tooltip = "Scene file path, used by Open, Save and Save As"
        resetButton.tooltip = "Restore the default panel layout"
        for (tool, button) in toolButtons { button.tooltip = "\(tool.title) tool" }
        commandButtons = [(SceneNewCommand.id, newButton), (SceneOpenCommand.id, openButton), (SceneSaveCommand.id, saveButton),
                          (SceneSaveAsCommand.id, saveAsButton), (LayoutResetCommand.id, resetButton)]
        // What each control runs, for introspection (`ui.snapshot`) and the parity test.
        let tagged: [(Widget, CommandID)] = commandButtons.map { ($0.1, $0.0) } + [
            (undoButton, EditUndoCommand.id), (redoButton, EditRedoCommand.id), (playButton, PlayToggleCommand.id),
            (pauseButton, PlayPauseCommand.id), (stepButton, PlayStepCommand.id), (gameViewButton, ViewGameCameraCommand.id),
            (reloadGameButton, GameReloadCommand.id), (buildGameButton, GameBuildCommand.id),
            (timeScale, PlaySetTimeScaleCommand.id), (path, SceneOpenCommand.id), (projectPath, ProjectOpenCommand.id),
            (openProjectButton, ProjectOpenCommand.id), (newProjectButton, ProjectNewCommand.id),
        ] + toolButtons.map { ($0.1, ToolSetCommand.id) }
        for (widget, id) in tagged { widget.command = id.rawValue }
        view = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 5), name: "toolbar")
        view.background = (app.ui?.theme ?? UITheme()).panelBackground
        view.addChildren([
            newButton, openButton, saveButton, saveAsButton,
            path,
            Separator(.vertical),
            undoButton, redoButton,
            Separator(.vertical),
            playButton, pauseButton, stepButton, timeScale, gameViewButton, reloadGameButton,
            Separator(.vertical),
        ] + toolButtons.map(\.1) + [
            Separator(.vertical),
            projectPath, openProjectButton, newProjectButton, buildGameButton,
            Spacer(),
            titleLabel,
            resetButton,
        ])
        refresh()
    }

    func refresh() {
        let session = app.session
        let undo = session.undo
        let shortcuts = app.shortcuts
        set(undoButton, title: undo.undoTitle, enabled: session.commands.isAvailable(EditUndoCommand.self))
        set(redoButton, title: undo.redoTitle, enabled: session.commands.isAvailable(EditRedoCommand.self))
        for (id, button) in commandButtons { set(button, title: button.title, enabled: session.commands.isAvailable(id)) }
        set(playButton, title: session.isPlaying ? "Stop" : "Play", enabled: true)
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
        if let index = Self.timeScales.firstIndex(of: session.timeScale), timeScale.selectedIndex != index { timeScale.select(index) }
        let game = session.gameModule
        if reloadGameButton.isHidden == game.isConfigured { reloadGameButton.isHidden = !game.isConfigured }
        set(reloadGameButton, title: game.isBusy ? "Building…" : "Reload Game", enabled: session.commands.isAvailable(GameReloadCommand.self))
        let reloadTip = game.lastError.map { "Rebuild and reload the game code, keeping the scene. Last error: \($0)" }
            ?? "Rebuild and reload the game code (\(game.loaded?.module.name ?? "not loaded")), keeping the scene"
        if reloadGameButton.tooltip != reloadTip { reloadGameButton.tooltip = reloadTip }
        let export = session.gameExport
        if buildGameButton.isHidden == (session.project != nil) { buildGameButton.isHidden = session.project == nil }
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

    private func set(_ button: Button, title: String, enabled: Bool) {
        if button.title != title { button.title = title }
        if button.isEnabled != enabled { button.isEnabled = enabled }
    }
}
