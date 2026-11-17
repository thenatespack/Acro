import EditorCore
import Engine
import Foundation

// The GridMap Builder tab: a scene-view style workspace for one `.gridmap` file, tabbed with the
// Scene view. The map is shown in a viewport of its own (its own `World`, renderer and camera)
// with the `GridMapView` form beside it.
//
// - The edited floor shows its grid; floors below are faded and floors above hidden.
// - Left-click or drag paints with the form's brush (line and rectangle go from the press to the
//   release cell; Shift makes a rectangle hollow); the stroke is written when you let go (one undo step).
// - Orbit with right-drag (or middle-drag, or Alt + left-drag), pan with Shift, zoom with the wheel.
// - Keys while the pointer is over the tab: 1-6 pick the brush, R / Shift+R rotate, X and Z flip,
//   Page Up / Page Down (or ] / [) change the floor (`GridMapView.handleKey`).
//
// The file is the truth: every edit is written as one undo step of the editor (Ctrl+Z), the map
// reimports, and the workspace rebuilds its copy (also after edits from MCP or other panels).

/// Paints on the grid: finds the cell under the pointer on the edited floor and collects the stroke.
@MainActor
final class GridMapBrushViewportTool: ViewportTool {
    var map: () -> GridMap? = { nil }
    let brush: GridMapBrushSettings
    var onStroke: ([GridCoord], Bool) -> Void = { _, _ in }
    private(set) var hover: GridCoord?
    private(set) var stroke: [GridCoord] = []
    private var hollow = false

    init(brush: GridMapBrushSettings) { self.brush = brush }

    /// The cell where `ray` meets floor `floor` of `map` (nil if it points away).
    static func cell(_ ray: ViewportRay, map: GridMap, floor: Int) -> GridCoord? {
        let y = Float(floor) * map.cell.y
        guard abs(ray.direction.y) > 1e-5 else { return nil }
        let t = (y - ray.origin.y) / ray.direction.y
        guard t > 0 else { return nil }
        return map.coord(at: ray.point(at: t), floor: floor)
    }

    /// The cells the stroke covers right now (the preview).
    func preview(_ map: GridMap) -> [GridCoord] {
        guard let first = stroke.first else { return hover.map { [$0] } ?? [] }
        switch brush.tool {
        case .line: return GridMap.line(from: first, to: stroke.last ?? first)
        case .rect: return GridMap.rectangle(from: first, to: stroke.last ?? first, outline: hollow)
        default: return stroke
        }
    }

    func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        guard let map = map() else { return false }
        let hit = Self.cell(context.ray(at: event.position), map: map, floor: brush.floor)
        switch event.phase {
        case .moved:
            hover = hit
            return false
        case .pressed:
            guard event.button == .left, !event.modifiers.contains(.alt), let hit else { return false }
            hover = hit
            stroke = [hit]
            hollow = event.modifiers.contains(.shift)
            return true
        case .dragged:
            guard event.button == .left, !stroke.isEmpty else { return true }
            if let hit {
                hover = hit
                if brush.tool.strokes {
                    if let last = stroke.last, last != hit {
                        for c in GridMap.line(from: last, to: hit).dropFirst() where !stroke.contains(c) { stroke.append(c) }
                    }
                } else if brush.tool != .fill {
                    stroke = [stroke[0], hit]
                }
            }
            return true
        case .released:
            let cells = stroke
            stroke = []
            if event.button == .left, !cells.isEmpty { onStroke(cells, hollow) }
            return true
        }
    }

    func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {
        guard let map = map() else { return }
        let c = map.cell, y = Float(brush.floor) * c.y + 0.02
        // The floor's grid around what is painted (or around the origin).
        let bounds = map.bounds
        let x0 = min(bounds?.min.x ?? 0, hover?.x ?? 0) - 6, x1 = max(bounds?.max.x ?? 0, hover?.x ?? 0) + 7
        let z0 = min(bounds?.min.z ?? 0, hover?.z ?? 0) - 6, z1 = max(bounds?.max.z ?? 0, hover?.z ?? 0) + 7
        let gridColor = Vec4(1, 1, 1, 0.18), style = DebugDraw.Style(width: 1, depth: .tested)
        if (x1 - x0) * (z1 - z0) < 40_000 {
            for x in x0...x1 { debugDraw.line(Vec3(Float(x) * c.x, y, Float(z0) * c.z), Vec3(Float(x) * c.x, y, Float(z1) * c.z), color: gridColor, style: style) }
            for z in z0...z1 { debugDraw.line(Vec3(Float(x0) * c.x, y, Float(z) * c.z), Vec3(Float(x1) * c.x, y, Float(z) * c.z), color: gridColor, style: style) }
        }
        debugDraw.line(Vec3(0, y, 0), Vec3(c.x, y, 0), color: Vec4(1, 0.3, 0.3, 0.8), style: DebugDraw.Style(width: 2, depth: .tested))
        debugDraw.line(Vec3(0, y, 0), Vec3(0, y, c.z), color: Vec4(0.3, 0.5, 1, 0.8), style: DebugDraw.Style(width: 2, depth: .tested))
        let color = brush.tool == .erase ? Vec4(1, 0.35, 0.3, 1) : Vec4(1, 0.85, 0.3, 1)
        let piece = brush.tool == .erase ? nil : map.piece(named: brush.piece)
        for coord in preview(map).prefix(2000) {
            let area = brush.tool == .erase ? [coord] : map.covered(by: piece, at: coord, turns: GridMap.quarterTurns(brush.rotation))
            let lo = map.origin(of: area.first ?? coord), hi = map.origin(of: area.last ?? coord) + Vec3(c.x, 0, c.z)
            let height = max(c.y * 0.15, 0.05)
            debugDraw.box(Bounds(center: Vec3((lo.x + hi.x) / 2, lo.y + height / 2, (lo.z + hi.z) / 2),
                                 halfExtent: Vec3((hi.x - lo.x) / 2, height / 2, (hi.z - lo.z) / 2)),
                          color: color, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
        if let hover, piece != nil, brush.tool != .random {
            // An arrow shows which way +x of the piece faces after the rotation.
            let center = map.origin(of: hover) + Vec3(c.x / 2, 0.05, c.z / 2)
            let turn = Quat(angle: Float(GridMap.quarterTurns(brush.rotation)) * .pi / 2, axis: Vec3(0, 1, 0))
            debugDraw.arrow(from: center, to: center + turn * Vec3(c.x * 0.45, 0, 0), color: color)
        }
    }
}

@MainActor
public final class GridMapWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The map being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The form beside the viewport.
    public private(set) var builder: GridMapView?
    /// The map and its lighting, apart from the scene.
    public let world = World()
    public let selection = EditorSelection()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0, 0), yaw: -0.6, pitch: 0.75, distance: 40))
    public let brush = GridMapBrushSettings()
    /// Set by the host to render (nil without a GPU: the workspace still edits, it just draws nothing).
    public var device: RenderDevice?
    public var quality = RenderQuality.high
    /// The opacity of floors below the edited one.
    public var fadedOpacity: Float = 0.3

    package let viewportWidget = ViewportWidget(name: "gridMapBuilderViewport", label: "GridMap Builder viewport")
    private let undo: UndoStack
    private let title = Label("GridMap Builder", role: .heading, name: "gridMapBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "gridMapBuilderSidebar")
    private let brushTool: GridMapBrushViewportTool
    private(set) var root: Entity?
    private var shownRevision = -1
    private var needsFraming = false

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var outline: SelectionOutlineRenderer?
    private var toolRenderer: DebugDrawRenderer?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private var pixelScale: Float = 1
    private let gizmos = DebugDraw()
    private let toolDraw = DebugDraw()

    public init(session: EditorSession) {
        self.session = session
        undo = UndoStack(world: world)
        brushTool = GridMapBrushViewportTool(brush: brush)
        _ = world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.4, castsShadows: true))
        _ = world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        view = VStack(spacing: 0, name: "gridMapBuilderWorkspace")
        brushTool.map = { [unowned self] in builder?.map }
        brushTool.onStroke = { [unowned self] cells, hollow in builder?.applyStroke(cells, outline: hollow) }
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.gridmap` file) on `floor`; false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID, floor: Int? = nil) -> Bool {
        guard session.isGridMapFile(id) else { return false }
        if let floor { brush.floor = floor }
        guard let builder = GridMapView(session: session, asset: id, brush: brush, showsTitle: false) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            builder.onFloorChange = { [unowned self] in applyFloorFade() }
            shownRevision = -1
            needsFraming = true
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        } else {
            self.builder?.layout()
            applyFloorFade()
        }
        title.text = session.assets?.record(id)?.fileName ?? "GridMap Builder"
        title.icon = EditorIcons.asset(.model)
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        if let root { world.despawn(root) }
        root = nil
        showEmpty()
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "gridMapBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let frame = Button("Frame", name: "gridMapBuilderFrame") { [unowned self] in frameMap() }
        frame.tooltip = "Fit the whole map in the view"
        bar.addChild(frame)
        let closeButton = Button("Close", name: "gridMapBuilderClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this map"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "gridMapBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "gridMapBuilderBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "GridMap Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .gridmap file in the Assets panel to paint it here, or make one with the Assets panel's "
                         + "New GridMap (right-click); it comes with starter pieces.", role: .caption)
        note.wraps = true
        let new = Button("New GridMap", role: .primary, name: "gridMapBuilderNew") { [unowned self] in
            if let id = session.run(GridMapNewCommand.self, .init())?.asset { session.run(GridMapOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = GridMapNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No grid map open"
    }

    // MARK: Per frame

    /// The tab's keyboard shortcuts (`GridMapView.handleKey`), for key presses made while the
    /// pointer is over the tab (`point`, in UI points) and the keyboard is free. Returns whether
    /// any key was used.
    @discardableResult
    public func handleKeys(_ events: [KeyEvent], pointer point: Vec2) -> Bool {
        guard let builder, view.isEffectivelyVisible, view.frame.contains(point) else { return false }
        var used = false
        for event in events where builder.handleKey(event) { used = true }
        return used
    }

    /// Handles this frame's pointer (`input`: nil when the keyboard and mouse belong elsewhere)
    /// and keeps the copy in step with the file. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()  // applies the form's pending edit (writes the file)
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            rebuildMap()
        }
        viewport.tools = [brushTool]
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here (no fly mode in a map view).
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
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
        if needsFraming, root != nil {
            frameMap()
            needsFraming = false
        }
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("GridMap Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        let view = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: session.viewportClearColor)
        currentView = view
        gizmos.removeAll()
        toolDraw.removeAll()
        brushTool.draw(into: toolDraw, context: toolContext(view: view))
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The GridMap Builder needs the GPU to draw" : nil
        viewportWidget.caption = "Floor \(brush.floor) · \(brush.tool.title.lowercased()) · right-drag orbits · Shift pans · wheel zooms"
    }

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let outline, let toolRenderer, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        let debugView = DebugView(view: view.view, projection: view.projection, viewportSize: (target.width, target.height),
                                  reversedZ: view.reversedZ)
        outline.renderView(view, sceneRenderer: renderer, world: world, selection: [], primary: nil, into: target,
                           pixelScale: pixelScale, frame: frame, debugDraw: gizmos) { pass in
            toolRenderer.draw(self.toolDraw, in: pass, view: debugView)
        }
    }

    /// Whether this frame's pointer belongs to the workspace's viewport (a drag in it, or the pointer over it).
    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    // MARK: Map

    private func rebuildMap() {
        guard let asset, let assets = session.assets else { return }
        shownRevision = assets.revision(of: asset)
        if let root { world.despawn(root) }
        root = nil
        guard let prefab = assets.prefab(AssetReference(asset)), let newRoot = world.instantiate(prefab).first else { return }
        root = newRoot
        applyFloorFade()
        world.propagateTransforms()
    }

    /// Fades the floors below the edited one and hides the ones above.
    func applyFloorFade() {
        guard let root else { return }
        for floorNode in world.children(of: root) {
            guard let name = world.get(Name.self, for: floorNode)?.value, name.hasPrefix("Floor "),
                  let y = Int(name.dropFirst("Floor ".count)) else { continue }
            let opacity: Float = y < brush.floor ? fadedOpacity : 1
            let visible = y <= brush.floor
            var stack = [floorNode]
            while let entity = stack.popLast() {
                world.modify(MeshRenderer.self, for: entity) { renderer in
                    renderer.opacity = opacity
                    // Glow fades too: emission is added on top of the blended color, so a lamp
                    // on a faded floor would otherwise shine as brightly as on the edited one.
                    renderer.emissiveStrength = opacity
                    renderer.isVisible = visible
                }
                stack += world.children(of: entity)
            }
        }
    }

    /// Fits the camera to the map (or the edited floor around the origin when empty).
    public func frameMap() {
        guard let map = builder?.map else { return }
        let c = map.cell
        guard let b = map.bounds else {
            viewport.frame(Bounds(center: Vec3(0, Float(brush.floor) * c.y, 0), halfExtent: Vec3(c.x * 4, c.y, c.z * 4)))
            return
        }
        let lo = map.origin(of: b.min), hi = map.origin(of: b.max) + c
        viewport.frame(Bounds(center: (lo + hi) / 2, halfExtent: (hi - lo) / 2))
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: selection, undo: undo, view: view, viewportRect: viewport.rect,
                            pixelScale: pixelScale, toolMode: session.tool, isPlaying: false, meshBounds: { _ in nil }, commands: nil)
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "gridmap builder view")
            outline = try SelectionOutlineRenderer(device: device, maskLabel: "gridmap builder outline mask")
            toolRenderer = try DebugDrawRenderer(device: device)
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("GridMap Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}
