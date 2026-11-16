import Engine
import Foundation

// The Path Builder tab: a scene-view style workspace for one `.path` file, tabbed with the Scene
// view. The path is shown in a viewport of its own (its own `World`, renderer, camera, selection
// and undo stack for gizmo drags), over the terrain it follows, with the `PathBuilderView` form
// beside it.
//
// - Every control point has a handle (a small sphere): click one to select it (the form follows,
//   and picking a point in the form selects its handle), drag it with the Move gizmo, and the new
//   position is written to the file when the drag ends (one undo step). With terrain following,
//   handles sit on the ground and only their x / z matter.
// - The curve is drawn as a line over the geometry, and the control polygon as a faint line.
// - Orbit with right-drag (or middle-drag, or Alt + left-drag), pan with Shift, zoom with the wheel.
//
// The file is the truth: every edit is written as one undo step of the editor (Ctrl+Z), the path
// reimports, and the workspace rebuilds its copy (also after edits from MCP, other panels, or the
// followed terrain changing).

@MainActor
public final class PathBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The path being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The form beside the viewport.
    public private(set) var builder: PathBuilderView?
    /// The path, its terrain, the handles and the lighting, apart from the scene.
    public let world = World()
    public let selection = EditorSelection()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0, 0), yaw: -0.6, pitch: 0.7, distance: 60))
    /// Set by the host to render (nil without a GPU: the workspace still edits, it just draws nothing).
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "pathBuilderViewport", label: "Path Builder viewport")
    private let undo: UndoStack
    private let title = Label("Path Builder", role: .heading, name: "pathBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "pathBuilderSidebar")
    private var root: Entity?
    private var terrainRoot: Entity?
    /// The handle entity of each control point, in order.
    public private(set) var handles: [Entity] = []
    private var shownRevision = -1
    private var shownTerrainRevision = -1
    private var shownTerrain: AssetID?
    private var syncedPoint: Int?
    private var needsFraming = false
    private var curve: [Vec3] = []

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
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.3, castsShadows: true))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        view = VStack(spacing: 0, name: "pathBuilderWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.path` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isPathBuildFile(id), let builder = PathBuilderView(session: session, asset: id, showsTitle: false) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            selection.clear()
            syncedPoint = nil
            shownRevision = -1
            needsFraming = true
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Path Builder"
        title.icon = EditorIcons.asset(.model)
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        clearCopies()
        selection.clear()
        showEmpty()
    }

    private func clearCopies() {
        for entity in [root, terrainRoot].compactMap({ $0 }) + handles { world.despawn(entity) }
        root = nil
        terrainRoot = nil
        handles = []
        curve = []
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "pathBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let frame = Button("Frame", name: "pathBuilderFrame") { [unowned self] in framePath() }
        frame.tooltip = "Fit the whole path in the view"
        bar.addChild(frame)
        let closeButton = Button("Close", name: "pathBuilderClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this path"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "pathBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "pathBuilderBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Path Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .path file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Path (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Path", role: .primary, name: "pathBuilderNew") { [unowned self] in
            if let id = session.run(PathNewCommand.self, .init())?.asset { session.run(PathOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = PathNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No path open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when the keyboard and mouse belong elsewhere),
    /// keeps the copy in step with the file and the form with the selection. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()  // applies the form's pending edit (writes the file)
        let revision = assets.revision(of: asset)
        let followed = builder.flatMap { session.followedTerrain(of: $0.build)?.id }
        let terrainRevision = followed.map { assets.revision(of: $0) } ?? -1
        if revision != shownRevision || followed != shownTerrain || terrainRevision != shownTerrainRevision {
            if shownRevision >= 0, revision != shownRevision { builder?.reload() }
            rebuild()
        }

        viewport.tools = transformTool.map { [$0] } ?? []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here (no fly mode in a builder view).
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
        world.propagateTransforms()
    }

    /// Sizes the render target to the panel and builds the overlays; call after layout.
    public func prepareFrame(pixelScale: Float) {
        self.pixelScale = pixelScale
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        if needsFraming, !handles.isEmpty {
            framePath()
            needsFraming = false
        }
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Path Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        let view = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: session.viewportClearColor)
        currentView = view
        gizmos.removeAll()
        if terrainRoot == nil {
            gizmos.grid = DebugGrid(height: 0.002, spacing: 1, majorEvery: 5, fadeDistance: 120,
                                    minorColor: Vec4(0.2, 0.21, 0.25, 0.5), majorColor: Vec4(0.3, 0.32, 0.38, 0.85))
        }
        toolDraw.removeAll()
        if curve.count > 1 {
            gizmos.polyline(curve.map { $0 + Vec3(0, 0.05, 0) }, color: Vec4(1, 0.8, 0.25, 1), style: DebugDraw.Style(width: 2, depth: .onTop))
        }
        let handlePositions = handles.compactMap { world.get(Transform.self, for: $0)?.position }
        if handlePositions.count > 1 {
            let closed = (builder?.build.closed ?? false) && handlePositions.count > 2
            gizmos.polyline(handlePositions, closed: closed, color: Vec4(0.6, 0.75, 1, 0.45), style: DebugDraw.Style(width: 1, depth: .onTop))
        }
        transformTool?.draw(into: toolDraw, context: toolContext(view: view))
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Path Builder needs the GPU to draw" : nil
        viewportWidget.caption = "Click a point · drag the gizmo · right-drag orbits · Shift pans · wheel zooms"
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

    // MARK: Copies

    /// Respawns the path, the terrain it follows and the handles from the files.
    private func rebuild() {
        guard let asset, let assets = session.assets, let builder else { return }
        shownRevision = assets.revision(of: asset)
        clearCopies()
        let build = builder.build
        let ground = session.followedTerrain(of: build)
        shownTerrain = ground?.id
        shownTerrainRevision = ground.map { assets.revision(of: $0.id) } ?? -1
        if let ground, let prefab = assets.prefab(AssetReference(ground.id)), let t = world.instantiate(prefab).first {
            world.modify(Transform.self, for: t) { $0.position = build.terrain.offset }
            terrainRoot = t
        }
        if let prefab = assets.prefab(AssetReference(asset)), let newRoot = world.instantiate(prefab).first { root = newRoot }

        let samples = build.samples(on: ground?.terrain)
        curve = samples.map(\.position)
        let length = samples.last?.distance ?? 20
        let radius = min(max(length * 0.012, 0.25), 2)
        for (i, point) in build.points.enumerated() {
            var position = point.position
            if let ground { position.y = build.groundHeight(ground.terrain, x: position.x, z: position.z) }
            let handle = world.spawn(Transform(position: position, scale: Vec3(repeating: radius * 2)), Name("Point \(i)"),
                                     MeshRenderer(mesh: .sphere, tint: i == 0 ? Vec3(0.4, 1, 0.5) : Vec3(1, 0.85, 0.3), castsShadows: false))
            handles.append(handle)
        }
        world.propagateTransforms()
        selection.set(syncedPoint.flatMap { handles.indices.contains($0) ? handles[$0] : nil }.flatMap { world.ensureID(of: $0) }.map { [$0] } ?? [])
    }

    private func point(of entity: Entity) -> Int? { handles.firstIndex(of: entity) }

    /// The form and the view's selection follow each other: a point picked in the form selects
    /// its handle, a handle clicked in the view picks its point in the form. Clicking the path's
    /// geometry selects nothing.
    private func syncSelection() {
        guard let builder else { return }
        if builder.selectedPoint != syncedPoint {
            syncedPoint = builder.selectedPoint
            selection.set(syncedPoint.flatMap { handles.indices.contains($0) ? handles[$0] : nil }.flatMap { world.ensureID(of: $0) }.map { [$0] } ?? [])
            return
        }
        let primary = selection.primaryEntity(in: world)
        if let primary, point(of: primary) == nil {
            selection.set(syncedPoint.flatMap { handles.indices.contains($0) ? handles[$0] : nil }.flatMap { world.ensureID(of: $0) }.map { [$0] } ?? [])
            return
        }
        let picked = primary.flatMap(point(of:))
        if picked != syncedPoint, picked != nil || selection.ids.isEmpty {
            syncedPoint = picked
            builder.selectPoint(picked)
        }
    }

    /// Writes a finished gizmo drag to the points it moved (with terrain following only x and z
    /// change; the file's heights stay).
    private func commitGizmoEdit() {
        guard let builder else { return }
        let build = builder.build
        var moves: [Int: Vec3] = [:]
        for entity in selection.entities(in: world) {
            guard let i = point(of: entity), build.points.indices.contains(i), let t = world.get(Transform.self, for: entity) else { continue }
            var position = t.position
            if build.terrain.isOn { position.y = build.points[i].position.y }
            moves[i] = position
        }
        guard !moves.isEmpty else { return }
        builder.movePoints(moves, label: moves.count == 1 ? "Move Point" : "Move Points")
    }

    /// Fits the camera to the path.
    public func framePath() {
        let positions = curve + handles.compactMap { world.get(Transform.self, for: $0)?.position }
        guard let first = positions.first else { return }
        var lo = first, hi = first
        for p in positions {
            lo = pointwiseMin(lo, p)
            hi = pointwiseMax(hi, p)
        }
        viewport.frame(Bounds(center: (lo + hi) / 2, halfExtent: pointwiseMax((hi - lo) / 2, Vec3(repeating: 2))))
    }

    // MARK: Helpers

    private func meshBounds(_ handle: MeshHandle) -> Bounds? {
        if let reference = handle.assetReference { return session.assets?.mesh(reference)?.bounds }
        return MeshGeometry.builtin(handle)?.bounds
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        // Points only move: the gizmo is always Move here.
        ViewportToolContext(world: world, selection: selection, undo: undo, view: view, viewportRect: viewport.rect,
                            pixelScale: pixelScale, toolMode: .move, isPlaying: false,
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
            target = try RenderTarget(device: device, width: 640, height: 360, label: "path builder view")
            outline = try SelectionOutlineRenderer(device: device, maskLabel: "path builder outline mask")
            toolRenderer = try DebugDrawRenderer(device: device)
            let tool = TransformTool(meshes: renderer)
            tool.billboardSource = nil
            transformTool = tool
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Path Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}
