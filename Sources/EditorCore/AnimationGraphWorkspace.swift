import Engine
import Foundation

// The Animation Graph Builder tab: the node editor (`AnimGraphCanvas`) above a live preview of
// the graph's model, with the `AnimationGraphView` form beside them. The preview plays the graph
// on an instance of its `preview` prefab in a world of its own (own renderer and orbit camera);
// parameters set in the form drive it by hand (they aren't saved), and the playing state is
// highlighted in the graph. Restart replays from the initial state, Pause freezes it.
//
// The file is the truth: every edit is one undo step, the graph reimports and the preview takes
// the new graph, keeping the parameter values and the state it was in (also after edits from MCP).

@MainActor
public final class AnimationGraphWorkspace {
    public let session: EditorSession
    public let view: VStack
    public private(set) var asset: AssetID?
    public private(set) var form: AnimationGraphView?
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 1, 0), yaw: -0.6, pitch: 0.25, distance: 5))
    public private(set) var isPaused = false
    /// The preview's animator (nil without a preview model).
    public private(set) var animator: Animator?
    /// The preview model's root.
    public private(set) var previewRoot: Entity?
    public let library = AnimationLibrary()
    /// The preview animator's clips, retargeted onto the model when the graph says so.
    let clipCache = AnimatorClipCache()
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "animGraphViewport", label: "Animation Graph Builder preview")
    private let title = Label("Animation Graph Builder", role: .heading, name: "animGraphTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "animGraphSidebar")
    private let canvasHolder = VStack(spacing: 0, name: "animGraphCanvasHolder")
    private let pauseToggle = Checkbox("Pause", kind: .toggleSwitch, name: "animGraphPause")
    private var shownRevision = -1
    private var shownPreview: String??
    /// Values set by hand in the form, kept across reloads.
    private var liveValues: [String: AnimationParameter] = [:]

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private let gizmos = DebugDraw()

    public init(session: EditorSession) {
        self.session = session
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-55, 35, 0))), Name("Light"), DirectionalLight(intensity: 1.6, castsShadows: false))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.5, fogDensity: 0))
        world.spawn(Transform(scale: Vec3(16, 1, 16)), Name("Ground"),
                    MeshRenderer(mesh: .plane, material: MaterialHandle("animGraphGround"), castsShadows: false))
        view = VStack(spacing: 0, name: "animGraphWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (an `.animgraph` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isAnimationGraphFile(id) else { return false }
        if asset != id {
            guard let form = AnimationGraphView(session: session, asset: id) else { return false }
            asset = id
            self.form = form
            form.liveValue = { [unowned self] name in animator?.parameters[name] }
            form.onSetLive = { [unowned self] name, value in setParameter(name, value) }
            form.onAssign = { [unowned self] in
                session.run(AnimGraphAssignCommand.self, .init(asset: AssetReference(id)))
            }
            shownRevision = -1
            shownPreview = nil
            liveValues = [:]
            sidebar.removeAllChildren()
            sidebar.addChild(form.view)
            canvasHolder.removeAllChildren()
            form.canvas.style.grow = 1
            form.canvas.style.shrink = 1
            canvasHolder.addChild(form.canvas)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Animation Graph Builder"
        return true
    }

    public func close() {
        asset = nil
        form = nil
        removePreview()
        showEmpty()
    }

    // MARK: Preview control

    /// Sets a parameter of the preview animator by hand (a trigger: `.trigger(true)`).
    public func setParameter(_ name: String, _ value: AnimationParameter) {
        if case .trigger = value {
            animator?.setTrigger(name)
        } else {
            liveValues[name] = value
            animator?.parameters[name] = value
        }
    }

    /// Replays the graph from its initial state with the parameters at their defaults.
    public func restart() {
        liveValues = [:]
        shownPreview = nil
        shownRevision = -1
    }

    public func setPaused(_ on: Bool) {
        isPaused = on
        pauseToggle.isOn = on
    }

    /// Advances the preview by `dt` (also what `update` does each frame).
    public func step(_ dt: Float) {
        guard var animator, let assets = session.assets else { return }
        library.assets = assets
        library.resolveAssetClips(animator.clipHandles)
        animator = animator.withLayerMasks(in: world)
        let clips = clipCache.clips(for: previewRoot ?? .invalid, animator, in: world, library: library)
        let pose = animator.update(dt: dt) { clips[$0] }
        for i in 0..<min(pose.count, animator.targets.count) where pose.animated[i] {
            world.modify(Transform.self, for: animator.targets[i]) { $0 = pose.transforms[i] }
        }
        self.animator = animator
        world.propagateTransforms()
    }

    private func removePreview() {
        if let previewRoot { world.despawn(previewRoot) }
        previewRoot = nil
        animator = nil
        clipCache.removeAll()
    }

    /// Respawns the model when it changed and gives the animator the current graph.
    private func reloadPreview(_ graph: AnimationGraph) {
        guard let assets = session.assets else { return }
        if shownPreview != .some(graph.preview) {
            removePreview()
            shownPreview = .some(graph.preview)
            if let key = graph.preview, let reference = AssetReference(key), let prefab = assets.prefab(reference),
               let root = world.instantiate(prefab).first {
                previewRoot = root
                world.propagateTransforms()
                animator = Animator(graph: graph, reference: nil, rigOf: root, in: world)
            }
        } else {
            animator?.apply(graph)
        }
        for (name, value) in liveValues { animator?.parameters[name] = value }
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "animGraphToolbar")
        title.style.shrink = 1
        title.icon = EditorIcons.asset(.animationGraph)
        bar.addChild(title)
        bar.addChild(Spacer())
        let restartButton = Button("Restart", name: "animGraphRestart") { [unowned self] in restart() }
        restartButton.tooltip = "Play the graph again from its initial state, parameters at their defaults"
        bar.addChild(restartButton)
        pauseToggle.onChange = { [unowned self] on in isPaused = on }
        pauseToggle.tooltip = "Freeze the preview"
        bar.addChild(pauseToggle)
        let closeButton = Button("Close", name: "animGraphClose") { [unowned self] in close() }
        closeButton.tooltip = "Stop editing this graph"
        bar.addChild(closeButton)

        canvasHolder.style.grow = 1
        canvasHolder.style.shrink = 1
        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let left = VStack(spacing: 0, name: "animGraphLeft", [canvasHolder, Separator(), viewportWidget])
        left.style.grow = 1
        left.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "animGraphSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "animGraphBody", [left, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Animation Graph Builder"
        sidebar.removeAllChildren()
        canvasHolder.removeAllChildren()
        let note = Label("Double-click an .animgraph file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Animation Graph (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Animation Graph", role: .primary, name: "animGraphNew") { [unowned self] in
            if let id = session.run(AnimGraphNewCommand.self, .init())?.asset {
                session.run(AnimGraphOpenCommand.self, .init(asset: AssetReference(id)))
            }
        }
        new.command = AnimGraphNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No animation graph open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when it belongs elsewhere), reloads the graph
    /// when the file changed and advances the preview. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        form?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { form?.reload() }
            shownRevision = revision
            if let graph = assets.animationGraph(of: asset) { reloadPreview(graph) }
        }
        viewport.tools = []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        if !isPaused { step(dt) }
        form?.canvas.activeState = animator?.currentState
        if let t = animator?.normalizedTime { form?.canvas.activeProgress = t - t.rounded(.down) }
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
                session.log.error("Animation Graph Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: Vec4(0.02, 0.025, 0.03, 1))
        gizmos.removeAll()
        viewportWidget.texture = target?.texture
        if target == nil {
            viewportWidget.placeholder = "The Animation Graph Builder needs the GPU to draw"
        } else if previewRoot == nil {
            viewportWidget.placeholder = "Pick a preview model in the sidebar"
        } else {
            viewportWidget.placeholder = nil
        }
        let state = animator?.currentState.map { "\($0)\(animator?.isInTransition == true ? " (blending)" : "")" } ?? "no state"
        viewportWidget.caption = (isPaused ? "Paused · " : "") + state + " · Right-drag orbits · wheel zooms"
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
                                          key: "animGraphGround")
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "animation graph view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Animation Graph Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

public enum AnimGraphOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "animGraph.open"
    public static let title = "Open in Animation Graph Builder"
    public static let doc = "Opens an .animgraph file in the editor's Animation Graph Builder tab (the node editor, a live preview on the graph's model with parameters you drive by hand, and the form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"animationGraph\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveAnimationGraph(arguments, title)
        session.openAnimationGraph = id
        session.onOpenAnimationGraph?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
