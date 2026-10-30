import Engine
import Foundation

/// How the editor starts.
public struct EditorOptions: Sendable {
    /// A scene file to open; nil starts with the starter scene.
    public var scenePath: String?
    /// Deterministic start for `ENGINE_SCREENSHOT` runs: default layout (prefs neither read nor
    /// written), sequential entity ids, the starter scene with an entity selected, a fixed
    /// camera and no caret blinking, so screenshots match across runs and backends.
    public var deterministic: Bool
    /// Where the dock layout is persisted; nil doesn't persist it.
    public var prefsURL: URL?

    public init(scenePath: String? = nil, deterministic: Bool = false, prefsURL: URL? = nil) {
        self.scenePath = scenePath
        self.deterministic = deterministic
        self.prefsURL = prefsURL
    }

    /// From the environment: deterministic with `ENGINE_SCREENSHOT`, prefs at `EditorPrefsStore.defaultURL`.
    public static func fromEnvironment(scenePath: String?) -> EditorOptions {
        let deterministic = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] != nil
        return EditorOptions(scenePath: scenePath, deterministic: deterministic,
                             prefsURL: deterministic ? nil : EditorPrefsStore.defaultURL())
    }
}

/// The editor application: hosts an `EditorSession` in the engine, builds the panels in a
/// `DockSpace` under a toolbar, renders the viewport through `SceneRenderer.beginViews` /
/// `renderView` into a `RenderTarget` sized to its panel, routes shortcuts and applies the UI's
/// cursor. Run it with `Engine(config:).run(EditorApp(options:))`.
@MainActor
public final class EditorApp: Game {
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

    private let dock = DockSpace()
    private var hierarchy: HierarchyPanel!
    private var inspector: InspectorPanel!
    private var console: ConsolePanel!
    private let stats = StatsPanel()
    private let viewportWidget = ViewportWidget()
    private var toolbar: Toolbar!

    private var prefs = EditorPrefs()
    private var prefsDirty = false
    private var captureRequested = false

    public init(options: EditorOptions) {
        self.options = options
        let document = EditorDocument()
        if options.deterministic {
            var generator = SequentialIDs()
            document.world.entityIDGenerator = { generator.next() }
        }
        session = EditorSession(document: document)
    }

    // MARK: Setup

    public func setup(engine: Engine) throws {
        sceneRenderer = try SceneRenderer(device: engine.device, quality: engine.quality)
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                           key: StarterScene.checkerMaterial.key)
        target = try RenderTarget(device: engine.device, width: 640, height: 360, label: "viewport")
        outline = try SelectionOutlineRenderer(device: engine.device)
        toolDrawRenderer = try DebugDrawRenderer(device: engine.device)
        transformTool = TransformTool(meshes: sceneRenderer)
        viewport.tools = [transformTool]
        engine.clearColor = Vec4(0.02, 0.022, 0.03, 1)

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
        buildUI()

        session.onWillReplaceWorld = { [unowned self] in inspector.recorder.finishGesture() }
        session.onChange = { [unowned self] in toolbar.refresh() }
        if let path = options.scenePath {
            if !session.open(path: path) { session.newDocument() }
            toolbar.path.text = path
        } else {
            session.newDocument()
            toolbar.path.text = prefs.lastScenePath ?? "scene.json"
        }
        hierarchy.sync(force: true)
        if options.deterministic {
            let world = session.world
            let sphere = world.roots.flatMap { [$0] + world.children(of: $0) }.first { session.displayName(of: $0) == "Blue Sphere" }
            session.selection.select(sphere.flatMap { world.id(of: $0) })
        }
        session.log.info("Editor ready. Right-drag flies the camera, Alt-drag or middle-drag orbits, the wheel zooms.")
        toolbar.refresh()
    }

    private func buildUI() {
        hierarchy = HierarchyPanel(session: session)
        hierarchy.spawnPosition = { [unowned self] in
            var p = viewport.camera.pivot
            p.y = max(p.y, 0.5)
            return p
        }
        inspector = InspectorPanel(session: session)
        inspector.assetChoices = AssetChoices(
            meshes: { [unowned self] in sceneRenderer.prep.meshes.keys },
            materials: { [unowned self] in sceneRenderer.prep.materials.keys })
        console = ConsolePanel(log: session.log)
        console.showsTime = !options.deterministic

        let viewportPanel = DockPanel(id: EditorLayout.viewport, title: "Scene", content: viewportWidget, isClosable: false,
                                      minSize: Vec2(200, 120))
        viewportPanel.passesPointerThrough = true
        dock.addPanel(viewportPanel)
        dock.addPanel(DockPanel(id: EditorLayout.hierarchy, title: "Hierarchy", content: hierarchy.view, minSize: Vec2(160, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.inspector, title: "Inspector", content: inspector.view, minSize: Vec2(220, 120)))
        dock.addPanel(DockPanel(id: EditorLayout.console, title: "Console", content: console.view))
        dock.addPanel(DockPanel(id: EditorLayout.stats, title: "Stats", content: stats.view))
        dock.restoreLayout(EditorLayout.initialLayout(stored: prefs.layout))
        dock.style.grow = 1
        dock.padding = EdgeInsets(top: 0, left: 4, bottom: 4, right: 4)
        dock.background = ui.theme.fieldBackground
        dock.onLayoutChange = { [unowned self] layout in
            prefs.layout = layout
            prefsDirty = true
        }

        toolbar = Toolbar(app: self)
        let column = VStack(name: "editorRoot", [toolbar.view, dock])
        column.isHitTestable = false
        ui.root.addChild(column)
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

    func resetLayout() {
        dock.restoreLayout(EditorLayout.defaultLayout)
        prefs.layout = dock.layout
        prefsDirty = true
    }

    // MARK: Frame

    public func update(engine: Engine, dt: Float) {
        let input = engine.input
        session.log.time = engine.time

        // What the UI does with the keyboard, before and after it handles this frame's input.
        func textEditing() -> Bool { ui.focusedWidget?.wantsTextInput == true || input.isTextInputActive }
        let textBefore = textEditing(), focusedBefore = ui.focusedWidget != nil, overlayBefore = !ui.overlays.isEmpty
        ui.update(engine: engine, dt: dt)
        let focus = EditorShortcuts.Focus(textEditing: textBefore || textEditing(), overlayOpen: overlayBefore,
                                          widgetFocused: focusedBefore)
        for action in shortcuts.actions(for: input.keyPresses, focus: focus) { perform(action) }

        updateViewport(engine: engine, dt: dt, keyboardFree: !focus.textEditing)
        session.tick(dt: Double(dt))

        hierarchy.sync()
        inspector.refresh()
        console.refresh()
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
        stats.refresh(snapshot, time: engine.time)
        toolbar.refresh()

        // Size the target to the panel before painting, so the image drawn this frame is the one rendered.
        ui.layoutIfNeeded()
        resizeTarget(scale: engine.ui.scale)
        buildGizmos()
        viewportWidget.texture = target.texture
        viewportWidget.caption = "Perspective · \(session.tool.title)" + (session.isPlaying ? " · Playing" : "")
        viewportWidget.isPlaying = session.isPlaying
        ui.draw(into: engine.ui)

        input.cursor = cursorShape(for: ui.desiredCursor)
        let title = "\(session.document.title) — Editor" + (session.isPlaying ? " [Playing]" : "")
        if engine.title != title { engine.title = title }
        if prefsDirty && !MouseButton.allCases.contains(where: input.isDown) { savePrefs() }
    }

    func perform(_ action: EditorAction) {
        switch action {
        case .undo: session.performUndo()
        case .redo: session.performRedo()
        case .save: save()
        case .duplicate: session.duplicateSelection()
        case .delete: session.deleteSelection()
        case .focusSelection: frameSelection()
        case .clearSelection:
            // Esc first cancels a gizmo drag, then clears the selection.
            if transformTool?.cancelDrag(world: session.world) != true { session.selection.clear() }
        case .togglePlay: session.togglePlay()
        }
    }

    func save() {
        if session.save(fallbackPath: toolbar.path.text) { rememberScenePath() }
    }

    func saveAs() {
        if session.save(as: toolbar.path.text) { rememberScenePath() }
    }

    func open() {
        if session.open(path: toolbar.path.text) {
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

    /// Frames the selected entities (their bounds, or their positions) in the viewport.
    func frameSelection() {
        let context = toolContext(view: currentView ?? viewport.view(aspect: sizer.aspectRatio))
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for entity in session.selection.entities(in: session.world) {
            let box = context.worldBounds(of: entity)
                ?? Bounds(center: session.world.worldMatrix(of: entity).translation, halfExtent: Vec3(repeating: 0.5))
            lo = pointwiseMin(lo, box.center - box.halfExtent)
            hi = pointwiseMax(hi, box.center + box.halfExtent)
        }
        guard lo.x <= hi.x else { return }
        viewport.frame(Bounds(center: (lo + hi) / 2, halfExtent: (hi - lo) / 2))
    }

    // MARK: Viewport

    private func updateViewport(engine: Engine, dt: Float, keyboardFree: Bool) {
        let input = engine.input
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
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
        currentView = viewport.view(aspect: target.aspectRatio, clearColor: viewportClearColor())
    }

    private func viewportClearColor() -> Vec4 {
        let environment = RenderPrep.findEnvironment(in: session.world)
        return environment.fogDensity > 0 ? Vec4(environment.fogColor, 1) : Vec4(0.08, 0.09, 0.11, 1)
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(
            world: session.world, selection: session.selection, undo: session.undo, view: view, viewportRect: viewport.rect,
            pixelScale: ui.scale, toolMode: session.tool, isPlaying: session.isPlaying,
            meshBounds: { [unowned self] handle in meshBounds(handle) })
    }

    private func meshBounds(_ handle: MeshHandle) -> Bounds? {
        if let cached = meshBoundsCache[handle.key] { return cached }
        let bounds = sceneRenderer.mesh(handle)?.bounds ?? builtinMeshBounds(handle)
        if let bounds { meshBoundsCache[handle.key] = bounds }
        return bounds
    }

    /// The viewport's debug shapes: grid, cameras, lights and axes for selected entities without a
    /// mesh (meshes get the selection outline), plus the tools' overlays in `toolDraw`.
    private func buildGizmos() {
        guard let view = currentView else { return }
        let world = session.world
        let context = toolContext(view: view)
        gizmos.removeAll()
        gizmos.grid = DebugGrid(height: 0.005, spacing: 1, majorEvery: 10, fadeDistance: 80,
                                minorColor: Vec4(0.2, 0.21, 0.25, 0.5), majorColor: Vec4(0.28, 0.3, 0.36, 0.85))
        let labelSize = 12 * ui.scale

        world.query(Camera.self) { entity, camera in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let viewProjection = camera.projection(aspect: 16 / 9) * Camera.viewMatrix(world: matrix)
            let white = Vec4(0.92, 0.92, 0.95, 1)
            gizmos.frustum(viewProjection: viewProjection, color: white, farFraction: min(1.5 / camera.far, 1),
                           style: DebugDraw.Style(width: 1.5))
            gizmos.text(session.displayName(of: entity), at: matrix.translation + Vec3(0, 0.45, 0), color: white, size: labelSize)
        }
        world.query(DirectionalLight.self) { entity, light in
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let start = matrix.translation, yellow = Vec4(1, 0.85, 0.3, 1)
            gizmos.arrow(from: start, to: start + light.travelDirection(world: matrix) * 1.5, color: yellow, headSize: 0.35,
                         style: DebugDraw.Style(width: 2))
            gizmos.text(session.displayName(of: entity), at: start + Vec3(0, 0.45, 0), color: yellow, size: labelSize)
        }

        for entity in session.selection.entities(in: world) where context.worldBounds(of: entity) == nil {
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            gizmos.axes(matrix, length: 0.6, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
        toolDraw.removeAll()
        for tool in viewport.tools { tool.draw(into: toolDraw, context: context) }
    }

    public func renderOffscreen(engine: Engine, frame: Frame) {
        guard let view = currentView, sizer.width > 0 else { return }
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
    private unowned let app: EditorApp
    private let undoButton: Button
    private let redoButton: Button
    private let playButton: Button
    private let toolButtons: [(EditorTool, Button)]
    private let titleLabel = Label("", role: .secondary, name: "documentTitle")

    init(app: EditorApp) {
        self.app = app
        let session = app.session
        undoButton = Button("Undo", name: "undo") { session.performUndo() }
        redoButton = Button("Redo", name: "redo") { session.performRedo() }
        playButton = Button("Play", name: "play") { session.togglePlay() }
        toolButtons = EditorTool.allCases.map { tool in (tool, Button(tool.title, name: tool.rawValue) { session.tool = tool }) }
        path.style.width = 220
        view = HStack(spacing: 6, padding: EdgeInsets(horizontal: 8, vertical: 5), name: "toolbar")
        view.background = app.ui.theme.panelBackground
        view.addChildren([
            Button("New", name: "new") { session.newDocument() },
            Button("Open", name: "open") { [unowned app] in app.open() },
            Button("Save", name: "save") { [unowned app] in app.save() },
            Button("Save As", name: "saveAs") { [unowned app] in app.saveAs() },
            path,
            Separator(.vertical),
            undoButton, redoButton,
            Separator(.vertical),
            playButton,
            Separator(.vertical),
        ] + toolButtons.map(\.1) + [
            Spacer(),
            titleLabel,
            Button("Reset Layout", name: "resetLayout") { [unowned app] in app.resetLayout() },
        ])
        refresh()
    }

    func refresh() {
        let session = app.session
        let undo = session.undo
        set(undoButton, title: undo.undoTitle, enabled: undo.canUndo)
        set(redoButton, title: undo.redoTitle, enabled: undo.canRedo)
        set(playButton, title: session.isPlaying ? "Stop" : "Play", enabled: true)
        playButton.role = session.isPlaying ? .primary : .normal
        for (tool, button) in toolButtons {
            let role: Button.Role = tool == session.tool ? .primary : .normal
            if button.role != role { button.role = role }
        }
        let title = session.document.title + (session.isPlaying ? " (playing)" : "")
        if titleLabel.text != title { titleLabel.text = title }
    }

    private func set(_ button: Button, title: String, enabled: Bool) {
        if button.title != title { button.title = title }
        if button.isEnabled != enabled { button.isEnabled = enabled }
    }
}
