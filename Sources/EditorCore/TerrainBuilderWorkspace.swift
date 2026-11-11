import Engine
import Foundation

// The Terrain Builder tab: a scene-view style workspace for one `.terrain` file, tabbed with the
// Scene view. The terrain is shown alone in a viewport of its own (its own `World`, renderer and
// camera) with the `TerrainBuilderView` form beside it.
//
// - Left-drag sculpts or paints with the form's brush; a ring shows the brush on the ground and
//   the stroke is written to the file when you let go (one undo step).
// - Orbit with right-drag (or middle-drag, or Alt + left-drag), pan with Shift, zoom with the wheel.
//
// The file is the truth: every edit is written as one undo step of the editor (Ctrl+Z), the
// terrain reimports, and the workspace rebuilds its copy (also after edits from MCP or other panels).

/// Drags the brush over the terrain: finds where the pointer's ray meets the ground and collects
/// the stroke's points.
@MainActor
final class TerrainBrushViewportTool: ViewportTool {
    var terrain: () -> Terrain? = { nil }
    var brush: TerrainBrushSettings
    var onStroke: ([Vec2]) -> Void = { _ in }
    private(set) var hover: Vec3?
    private(set) var stroke: [Vec2] = []

    init(brush: TerrainBrushSettings) { self.brush = brush }

    /// Where `ray` meets the ground of `terrain` (nil if it misses), by marching then bisecting.
    static func intersect(_ ray: ViewportRay, with terrain: Terrain) -> Vec3? {
        let half = Vec3(terrain.size.x / 2, terrain.heightRange, terrain.size.y / 2)
        guard let enter = ray.intersect(Bounds(center: Vec3(0, terrain.heightRange / 2, 0), halfExtent: half)) else { return nil }
        let step = max(min(terrain.size.x, terrain.size.y) / Float(max(terrain.res - 1, 1)) * 0.5, 0.05)
        func above(_ t: Float) -> Bool {
            let p = ray.point(at: t)
            return p.y > terrain.heightAt(x: p.x, z: p.z)
        }
        var t = enter
        let limit = enter + length(half) * 2 + 1
        var previous = t
        while t < limit {
            let p = ray.point(at: t)
            let inside = abs(p.x) <= half.x + 0.001 && abs(p.z) <= half.z + 0.001
            if inside && !above(t) {
                var lo = previous, hi = t
                for _ in 0..<24 {
                    let mid = (lo + hi) / 2
                    if above(mid) { lo = mid } else { hi = mid }
                }
                let hit = ray.point(at: hi)
                return Vec3(min(max(hit.x, -half.x), half.x), hit.y, min(max(hit.z, -half.z), half.z))
            }
            previous = t
            t += step
        }
        return nil
    }

    func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        guard let terrain = terrain() else { return false }
        let hit = Self.intersect(context.ray(at: event.position), with: terrain)
        switch event.phase {
        case .moved:
            hover = hit
            return false
        case .pressed:
            guard event.button == .left, !event.modifiers.contains(.alt), let hit else { return false }
            hover = hit
            stroke = [Vec2(hit.x, hit.z)]
            return true
        case .dragged:
            guard event.button == .left else { return true }
            if let hit {
                hover = hit
                let p = Vec2(hit.x, hit.z)
                if let last = stroke.last, hypotf(p.x - last.x, p.y - last.y) >= max(brush.radius * 0.2, 0.25) { stroke.append(p) }
            }
            return true
        case .released:
            let points = stroke
            stroke = []
            if event.button == .left, !points.isEmpty { onStroke(points) }
            return true
        }
    }

    func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {
        guard let terrain = terrain() else { return }
        func ring(_ center: Vec2, color: Vec4) {
            let points = (0...48).map { i -> Vec3 in
                let a = Float(i) / 48 * 2 * .pi
                let x = center.x + cosf(a) * brush.radius, z = center.y + sinf(a) * brush.radius
                return Vec3(x, terrain.heightAt(x: x, z: z) + 0.08, z)
            }
            debugDraw.polyline(points, closed: false, color: color, style: DebugDraw.Style(width: 2, depth: .onTop))
        }
        if let hover { ring(Vec2(hover.x, hover.z), color: Vec4(1, 0.85, 0.3, 1)) }
        if stroke.count > 1 {
            debugDraw.polyline(stroke.map { Vec3($0.x, terrain.heightAt(x: $0.x, z: $0.y) + 0.12, $0.y) }, color: Vec4(1, 1, 1, 0.8),
                               style: DebugDraw.Style(width: 2, depth: .onTop))
        }
    }
}

@MainActor
public final class TerrainBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The terrain being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The form beside the viewport.
    public private(set) var builder: TerrainBuilderView?
    /// The terrain and its lighting, apart from the scene.
    public let world = World()
    public let selection = EditorSelection()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 8, 0), yaw: -0.6, pitch: 0.6, distance: 120))
    public let brush = TerrainBrushSettings()
    /// Set by the host to render (nil without a GPU: the workspace still edits, it just draws nothing).
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "terrainBuilderViewport", label: "Terrain Builder viewport")
    private let undo: UndoStack
    private let title = Label("Terrain Builder", role: .heading, name: "terrainBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "terrainBuilderSidebar")
    private let brushTool: TerrainBrushViewportTool
    private var root: Entity?
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
        brushTool = TerrainBrushViewportTool(brush: brush)
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-45, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.4, castsShadows: true))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        view = VStack(spacing: 0, name: "terrainBuilderWorkspace")
        brushTool.terrain = { [unowned self] in builder?.terrain }
        brushTool.onStroke = { [unowned self] points in builder?.applyStroke(points) }
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.terrain` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isTerrainFile(id), let builder = TerrainBuilderView(session: session, asset: id, brush: brush, showsTitle: false) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            shownRevision = -1
            needsFraming = true
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Terrain Builder"
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
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "terrainBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let frame = Button("Frame", name: "terrainBuilderFrame") { [unowned self] in frameTerrain() }
        frame.tooltip = "Fit the whole terrain in the view"
        bar.addChild(frame)
        let closeButton = Button("Close", name: "terrainBuilderClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this terrain"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "terrainBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "terrainBuilderBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Terrain Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .terrain file in the Assets panel to sculpt it here, or make one with the Assets panel's "
                         + "New Terrain (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Terrain", role: .primary, name: "terrainBuilderNew") { [unowned self] in
            if let id = session.run(TerrainNewCommand.self, .init())?.asset { session.run(TerrainOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = TerrainNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No terrain open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when the keyboard and mouse belong elsewhere)
    /// and keeps the copy in step with the file. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()  // applies the form's pending edit (writes the file)
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            rebuildTerrain()
        }
        viewport.tools = [brushTool]
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here (no fly mode in a terrain view).
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
            frameTerrain()
            needsFraming = false
        }
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Terrain Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        let view = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: session.viewportClearColor)
        currentView = view
        gizmos.removeAll()
        toolDraw.removeAll()
        brushTool.draw(into: toolDraw, context: toolContext(view: view))
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Terrain Builder needs the GPU to draw" : nil
        viewportWidget.caption = "Drag to \(brush.tool.title.lowercased()) · right-drag orbits · Shift pans · wheel zooms"
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

    // MARK: Terrain

    private func rebuildTerrain() {
        guard let asset, let assets = session.assets else { return }
        shownRevision = assets.revision(of: asset)
        if let root { world.despawn(root) }
        root = nil
        guard let prefab = assets.prefab(AssetReference(asset)), let newRoot = world.instantiate(prefab).first else { return }
        root = newRoot
        world.propagateTransforms()
    }

    /// Fits the camera to the terrain.
    public func frameTerrain() {
        guard let t = builder?.terrain else { return }
        viewport.frame(Bounds(center: Vec3(0, t.heightRange * 0.2, 0), halfExtent: Vec3(t.size.x / 2, t.heightRange * 0.2, t.size.y / 2)))
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
            target = try RenderTarget(device: device, width: 640, height: 360, label: "terrain builder view")
            outline = try SelectionOutlineRenderer(device: device, maskLabel: "terrain builder outline mask")
            toolRenderer = try DebugDrawRenderer(device: device)
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Terrain Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

