import Engine
import Foundation

// The Mesh Builder tab: a scene-view style workspace for one `.meshbuild` file, tabbed with the
// Scene view. The model is shown alone in a viewport of its own (its own `World`, renderer,
// camera, selection and undo stack for gizmo drags), with the `MeshBuilderView` form beside it.
//
// - Click a part to select it (the form follows, and picking a part in the form selects it in
//   the view); the toolbar's Move / Rotate / Scale gizmos (W / E / R) edit it, and the drag is
//   written to the file when it ends (scale grows the part's size).
// - Orbit with right-drag (or middle-drag, or Alt + left-drag), pan with Shift, zoom with the wheel.
// - Animate plays the model's autoplay animations live; turning it off puts the parts back.
//
// The file is the truth: every edit is written as one undo step of the editor (Ctrl+Z), the model
// reimports, and the workspace rebuilds its copy (also after edits from MCP or other panels).

@MainActor
public final class MeshBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The mesh build being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The parts form beside the viewport.
    public private(set) var builder: MeshBuilderView?
    /// The model and its lighting, apart from the scene.
    public let world = World()
    public let selection = EditorSelection()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0.5, 0), yaw: -0.6, pitch: 0.45, distance: 6))
    /// Whether the animations are playing in the view.
    public private(set) var isPreviewingAnimation = false
    /// Set by the host to render (nil without a GPU: the workspace still edits, it just draws nothing).
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "meshBuilderViewport", label: "Mesh Builder viewport")
    private let undo: UndoStack
    private let title = Label("Mesh Builder", role: .heading, name: "meshBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "meshBuilderSidebar")
    private var toolButtons: [EditorTool: Button] = [:]
    private let animateToggle = Checkbox("Animate", kind: .toggleSwitch, name: "meshBuilderAnimate")
    private var root: Entity?
    private var partEntities: [String: Entity] = [:]
    private var shownRevision = -1
    /// The part last agreed on by the form and the view's selection.
    private var syncedPart: String?
    private var needsFraming = false

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var outline: SelectionOutlineRenderer?
    private var toolRenderer: DebugDrawRenderer?
    public private(set) var transformTool: TransformTool?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private var pixelScale: Float = 1
    private let gizmos = DebugDraw()
    private let toolDraw = DebugDraw()
    private var wasDragging = false

    public init(session: EditorSession) {
        self.session = session
        undo = UndoStack(world: world)
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-55, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.2, castsShadows: true))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        world.addBuiltinAnimationSystems()
        view = VStack(spacing: 0, name: "meshBuilderWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.meshbuild` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isMeshBuildFile(id), let builder = MeshBuilderView(session: session, asset: id, showsTitle: false) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            selection.clear()
            syncedPart = nil
            shownRevision = -1
            needsFraming = true
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Mesh Builder"
        title.icon = EditorIcons.asset(.model)
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        if let root { world.despawn(root) }
        root = nil
        partEntities = [:]
        selection.clear()
        showEmpty()
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "meshBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        for tool in EditorTool.allCases {
            let button = Button(tool.title, name: "meshBuilderTool.\(tool.rawValue)") { [unowned self] in session.tool = tool }
            button.tooltip = "\(tool.title) the selected part with the gizmo"
            toolButtons[tool] = button
            bar.addChild(button)
        }
        let frame = Button("Frame", name: "meshBuilderFrame") { [unowned self] in frameModel() }
        frame.tooltip = "Fit the whole model in the view"
        bar.addChild(frame)
        animateToggle.onChange = { [unowned self] on in setPreviewingAnimation(on) }
        animateToggle.tooltip = "Play the model's animations here"
        bar.addChild(animateToggle)
        let close = Button("Close", name: "meshBuilderClose") { [unowned self] in close() }
        close.tooltip = "Stop editing this mesh build"
        bar.addChild(close)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "meshBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "meshBuilderBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Mesh Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .meshbuild file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Mesh Build (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Mesh Build", role: .primary, name: "meshBuilderNew") { [unowned self] in
            if let id = session.run(MeshBuildNewCommand.self, .init())?.asset { session.run(MeshBuildOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = MeshBuildNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No mesh build open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when the keyboard and mouse belong elsewhere),
    /// keeps the copy in step with the file and the form with the selection. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()  // applies the form's pending edit (writes the file)
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            rebuildModel()
        }
        updateToolButtons()

        let gizmoTool = isPreviewingAnimation ? nil : transformTool
        viewport.tools = gizmoTool.map { [$0] } ?? []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here (no fly mode in a model view).
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        let dragging = transformTool?.isDragging ?? false
        if wasDragging && !dragging { commitGizmoEdit() }
        wasDragging = dragging

        syncSelection()
        if isPreviewingAnimation {
            world.update(dt: Double(dt))
        } else {
            world.propagateTransforms()
        }
    }

    /// Sizes the render target to the panel and builds the overlays; call after layout.
    public func prepareFrame(pixelScale: Float) {
        self.pixelScale = pixelScale
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        if needsFraming, !partEntities.isEmpty {
            frameModel()
            needsFraming = false
        }
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Mesh Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        let view = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: session.viewportClearColor)
        currentView = view
        gizmos.removeAll()
        gizmos.grid = DebugGrid(height: 0.002, spacing: 0.5, majorEvery: 2, fadeDistance: 40,
                                minorColor: Vec4(0.2, 0.21, 0.25, 0.5), majorColor: Vec4(0.3, 0.32, 0.38, 0.85))
        toolDraw.removeAll()
        let context = toolContext(view: view)
        for entity in selection.entities(in: world) where world.get(MeshRenderer.self, for: entity) == nil {
            // Groups have no mesh to outline: show their axes.
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            gizmos.axes(matrix, length: 0.4, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
        if !isPreviewingAnimation { transformTool?.draw(into: toolDraw, context: context) }
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Mesh Builder needs the GPU to draw" : nil
        viewportWidget.caption = isPreviewingAnimation ? "Animating" : "Right-drag orbits · Shift pans · wheel zooms"
    }

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let outline, let toolRenderer, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        let debugView = DebugView(view: view.view, projection: view.projection, viewportSize: (target.width, target.height),
                                  reversedZ: view.reversedZ)
        outline.renderView(view, sceneRenderer: renderer, world: world, selection: selection.entities(in: world),
                           primary: selection.primaryEntity(in: world), into: target, pixelScale: pixelScale, frame: frame,
                           debugDraw: gizmos) { [unowned self] pass in
            toolRenderer.draw(toolDraw, in: pass, view: debugView)
        }
    }

    /// Whether this frame's pointer belongs to the workspace's viewport (a drag in it, or the pointer over it).
    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    // MARK: Model

    private func rebuildModel() {
        guard let asset, let assets = session.assets else { return }
        shownRevision = assets.revision(of: asset)
        if let root { world.despawn(root) }
        root = nil
        partEntities = [:]
        guard let prefab = assets.prefab(AssetReference(asset)), let newRoot = world.instantiate(prefab).first else { return }
        root = newRoot
        var stack = world.children(of: newRoot)
        while let entity = stack.popLast() {
            if let name = world.get(Name.self, for: entity)?.value, partEntities[name] == nil { partEntities[name] = entity }
            stack += world.children(of: entity)
        }
        world.propagateTransforms()
        selection.set(syncedPart.flatMap { partEntities[$0] }.flatMap { world.ensureID(of: $0) }.map { [$0] } ?? [])
    }

    private func part(of entity: Entity) -> String? { partEntities.first { $0.value == entity }?.key }

    /// The form and the view's selection follow each other: a part picked in the form is
    /// selected in the view, an entity clicked in the view picks its part in the form.
    private func syncSelection() {
        guard let builder else { return }
        if builder.selectedPart != syncedPart {
            syncedPart = builder.selectedPart
            selection.set(syncedPart.flatMap { partEntities[$0] }.flatMap { world.ensureID(of: $0) }.map { [$0] } ?? [])
            return
        }
        let picked = selection.primaryEntity(in: world).flatMap(part(of:))
        if picked != syncedPart, picked != nil || selection.ids.isEmpty {
            syncedPart = picked
            builder.selectPart(picked)
        }
    }

    /// Writes a finished gizmo drag to the parts it moved: position and rotation, and a scale
    /// multiplied into the part's size.
    private func commitGizmoEdit() {
        guard let builder else { return }
        var changes: [String: Transform] = [:]
        for entity in selection.entities(in: world) {
            if let name = part(of: entity), let transform = world.get(Transform.self, for: entity) { changes[name] = transform }
        }
        guard !changes.isEmpty else { return }
        builder.updateParts(label: "\(session.tool.title) Part") { part in
            guard let t = changes[part.name] else { return }
            part.position = t.position
            part.rotation = t.rotation.eulerDegrees
            if t.scale != Vec3(1, 1, 1) { part.size *= Vec3(abs(t.scale.x), abs(t.scale.y), abs(t.scale.z)) }
        }
    }

    public func setPreviewingAnimation(_ on: Bool) {
        guard on != isPreviewingAnimation else { return }
        isPreviewingAnimation = on
        animateToggle.isOn = on
        if !on { rebuildModel() }  // back to the rest pose
    }

    /// Fits the camera to the model.
    public func frameModel() {
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        for entity in partEntities.values {
            guard let renderer = world.get(MeshRenderer.self, for: entity), let bounds = meshBounds(renderer.mesh) else { continue }
            let matrix = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let b = bounds.transformed(by: matrix)
            lo = pointwiseMin(lo, b.center - b.halfExtent)
            hi = pointwiseMax(hi, b.center + b.halfExtent)
        }
        guard lo.x <= hi.x else { return }
        viewport.frame(Bounds(center: (lo + hi) / 2, halfExtent: pointwiseMax((hi - lo) / 2, Vec3(repeating: 0.1))))
    }

    // MARK: Helpers

    private func updateToolButtons() {
        for (tool, button) in toolButtons {
            let role: Button.Role = tool == session.tool ? .primary : .normal
            if button.role != role { button.role = role }
        }
    }

    private func meshBounds(_ handle: MeshHandle) -> Bounds? {
        if let reference = handle.assetReference { return session.assets?.mesh(reference)?.bounds }
        return MeshGeometry.builtin(handle)?.bounds
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: selection, undo: undo, view: view, viewportRect: viewport.rect,
                            pixelScale: pixelScale, toolMode: session.tool, isPlaying: false,
                            meshBounds: { [unowned self] in meshBounds($0) }, commands: nil, snapping: session.snapping,
                            snapSteps: session.editorSettings.gizmoSnapping(enabled: session.snapping))
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else {
            if transformTool == nil, device == nil {
                let tool = TransformTool(meshes: session.cpuPickMeshes)
                tool.billboardSource = nil
                transformTool = tool
            }
            return
        }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "mesh builder view")
            outline = try SelectionOutlineRenderer(device: device, maskLabel: "mesh builder outline mask")
            toolRenderer = try DebugDrawRenderer(device: device)
            let tool = TransformTool(meshes: renderer)
            tool.billboardSource = nil
            transformTool = tool
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Mesh Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

public enum MeshBuildOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, MeshBuildTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "meshBuild.open"
    public static let title = "Open in Mesh Builder"
    public static let doc = "Opens a .meshbuild file in the editor's Mesh Builder tab (a viewport showing just the model, with gizmos to place parts, live animation preview and the parts form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"meshBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveMeshBuild(arguments, title)
        session.openMeshBuild = id
        session.onOpenMeshBuild?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
