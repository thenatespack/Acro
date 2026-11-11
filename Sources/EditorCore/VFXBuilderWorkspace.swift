import Engine
import Foundation

// The VFX Builder tab: a viewport for one `.vfx` file, tabbed with the Scene view, with the
// `VFXBuilderView` form beside it. The effect plays in a world of its own (its own renderer and
// orbit camera) over a ground plane on the effect's background color. It loops: after the
// effect's `duration` it is spawned again from the start (Loop off plays it once). Restart
// replays it now, Pause freezes it.
//
// The file is the truth: every edit is one undo step of the editor, the prefab reimports, and
// the preview restarts with the new settings (also after edits from MCP or other panels).

@MainActor
public final class VFXBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The effect being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var builder: VFXBuilderView?
    /// The preview's world: the effect, a light and the ground.
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 1, 0), yaw: -0.6, pitch: 0.3, distance: 7))
    public private(set) var isLooping = true
    public private(set) var isPaused = false
    /// Seconds since the effect last (re)started.
    public private(set) var runTime: Float = 0
    /// How many times the preview has (re)started the effect.
    public private(set) var restartCount = 0
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "vfxViewport", label: "VFX Builder viewport")
    private let title = Label("VFX Builder", role: .heading, name: "vfxTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "vfxSidebar")
    private let loopToggle = Checkbox("Loop", kind: .toggleSwitch, name: "vfxLoop")
    private let pauseToggle = Checkbox("Pause", kind: .toggleSwitch, name: "vfxPause")
    private var root: Entity?
    private var groundEntity: Entity?
    private var shownRevision = -1
    private var shownSettings: (Bool, Vec3)?

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private let gizmos = DebugDraw()
    private var duration: Float = 4
    private var background = Vec3(0.07, 0.08, 0.1)

    public init(session: EditorSession) {
        self.session = session
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-55, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 1.6, castsShadows: false))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.5, fogDensity: 0))
        view = VStack(spacing: 0, name: "vfxWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.vfx` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isVFXFile(id), let builder = VFXBuilderView(session: session, asset: id, showsTitle: false) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            shownRevision = -1
            shownSettings = nil
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "VFX Builder"
        title.icon = EditorIcons.asset(.model)
        return true
    }

    public func close() {
        asset = nil
        builder = nil
        if let root { world.despawn(root) }
        root = nil
        showEmpty()
    }

    // MARK: Controls

    /// Plays the effect again from the start.
    public func restart() {
        runTime = 0
        restartCount += 1
        if let root { world.despawn(root) }
        root = nil
        guard let asset, let prefab = session.assets?.prefab(AssetReference(asset)) else { return }
        // A new entity gets a fresh emitter state, so its particles start over (prewarm included).
        root = world.instantiate(prefab).first
        world.propagateTransforms()
    }

    public func setLooping(_ on: Bool) {
        isLooping = on
        loopToggle.isOn = on
    }

    public func setPaused(_ on: Bool) {
        isPaused = on
        pauseToggle.isOn = on
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "vfxToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let restartButton = Button("Restart", name: "vfxRestart") { [unowned self] in self.restart() }
        restartButton.tooltip = "Play the effect again from the start"
        bar.addChild(restartButton)
        loopToggle.isOn = true
        loopToggle.onChange = { [unowned self] on in isLooping = on }
        loopToggle.tooltip = "Replay the effect when its duration is over"
        bar.addChild(loopToggle)
        pauseToggle.onChange = { [unowned self] on in isPaused = on }
        pauseToggle.tooltip = "Freeze the preview"
        bar.addChild(pauseToggle)
        let closeButton = Button("Close", name: "vfxClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this effect"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "vfxSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "vfxBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "VFX Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .vfx file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New VFX (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New VFX", role: .primary, name: "vfxNew") { [unowned self] in
            if let id = session.run(VFXNewCommand.self, .init())?.asset { session.run(VFXOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = VFXNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No effect open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when it belongs elsewhere), reloads the effect
    /// when the file changed and advances the preview. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            shownRevision = revision
            if let build = assets.vfx(of: asset) {
                duration = max(build.duration, 0.1)
                background = build.background
                updateGround(build.ground)
            }
            restart()
        }
        viewport.tools = []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here (no fly mode in an effect view).
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        if !isPaused {
            runTime += dt
            if runTime >= duration, isLooping { restart() }
            world.update(dt: Double(dt))
        }
    }

    private func updateGround(_ visible: Bool) {
        if visible, groundEntity == nil {
            groundEntity = world.spawn(Transform(scale: Vec3(24, 1, 24)), Name("Ground"),
                                       MeshRenderer(mesh: .plane, material: MaterialHandle("vfxGround"), castsShadows: false))
            world.propagateTransforms()
        } else if !visible, let ground = groundEntity {
            world.despawn(ground)
            groundEntity = nil
        }
    }

    public func prepareFrame(pixelScale: Float) {
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("VFX Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        func linear(_ x: Float) -> Float { x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4) }
        let clear = Vec4(linear(background.x), linear(background.y), linear(background.z), 1)
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: clear)
        gizmos.removeAll()
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The VFX Builder needs the GPU to draw" : nil
        viewportWidget.caption = (isPaused ? "Paused" : String(format: "%.1f / %.1f s", min(runTime, duration), duration))
            + " · Right-drag orbits · wheel zooms"
    }

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        renderer.renderView(view, into: target, frame: frame, debugDraw: gizmos)
    }

    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    private func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: EditorSelection(), undo: UndoStack(world: world), view: view,
                            viewportRect: viewport.rect, pixelScale: 1, toolMode: session.tool, isPlaying: false,
                            meshBounds: { _ in nil }, commands: nil, snapping: false,
                            snapSteps: session.editorSettings.gizmoSnapping(enabled: false))
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.1, 0.11, 0.13, 1), specular: 0.05),
                                          key: "vfxGround")
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "vfx builder view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("VFX Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

public enum VFXOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VFXTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "vfx.open"
    public static let title = "Open in VFX Builder"
    public static let doc = "Opens a .vfx file in the editor's VFX Builder tab (a looping live preview over a ground plane, with the emitters form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"vfxBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveVFX(arguments, title)
        session.openVFX = id
        session.onOpenVFX?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
