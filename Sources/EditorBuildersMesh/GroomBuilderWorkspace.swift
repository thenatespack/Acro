import EditorCore
import Engine
import Foundation

// The Groom Builder tab: a viewport for one `.groom` file, tabbed with the Scene view, with the
// `GroomBuilderView` form beside it. The fur grows live on the groom's preview (its `previewMesh`:
// a sphere by default, or a `.meshbuild`'s parts) in a world of its own, in a light breeze, over a
// ground plane. Left-drag orbits; with a brush picked (Mask, Restore, Length, Comb) left-drag
// paints on the preview mesh instead, and each stroke is written to the file as `cut` or `comb`
// strokes in one undo step (what an agent writes with groom.edit).
//
// The file is the truth: every edit is one undo step of the editor, the groom reimports, and the
// fur regrows (also after edits from MCP or other panels).

/// A brush of the Groom Builder tab.
public enum GroomBrush: String, CaseIterable, Sendable {
    /// Orbit the camera (no painting).
    case none
    /// Paint fur away (cut strokes to length 0).
    case mask
    /// Paint fur back (cut strokes to length 1).
    case restore
    /// Paint the length (cut strokes to the brush's length).
    case length
    /// Comb strands along the drag (comb strokes).
    case comb

    var title: String {
        switch self {
        case .none: "Orbit"
        case .mask: "Mask"
        case .restore: "Restore"
        case .length: "Length"
        case .comb: "Comb"
        }
    }
}

@MainActor
public final class GroomBuilderWorkspace {
    public let session: EditorSession
    public let view: VStack
    /// The groom being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var builder: GroomBuilderView?
    /// The preview's world: the groom's preview prefab, a light, the ground and the wind.
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0.5, 0), yaw: -0.5, pitch: 0.35, distance: 2.6))
    public var device: RenderDevice?
    public var quality = RenderQuality.high
    /// The brush left-drag paints with, its radius (meters in the mesh's space), strength and target length.
    public var brush = GroomBrush.none
    public var brushRadius: Float = 0.12
    public var brushStrength: Float = 1
    public var brushLength: Float = 0.5
    /// Strokes of the drag in progress (committed on release).
    public private(set) var pendingCuts: [GroomCut] = []
    public private(set) var pendingCombs: [GroomComb] = []

    package let viewportWidget = ViewportWidget(name: "groomViewport", label: "Groom Builder viewport")
    private let title = Label("Groom Builder", role: .heading, name: "groomTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "groomSidebar")
    private var root: Entity?
    private var shownRevision = -1
    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private let gizmos = DebugDraw()
    private lazy var brushTool = GroomBrushTool(workspace: self)
    private var clock: Float = 0
    /// Where the brush is over the mesh (world space), for its circle.
    var hover: (point: Vec3, normal: Vec3)?

    public init(session: EditorSession) {
        self.session = session
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 35, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.2, castsShadows: true, shadowExtent: 3))
        var environment = SceneEnvironment(ambientIntensity: 0.55, fogDensity: 0)
        environment.wind = Wind(strength: 0.4, gustiness: 0.5)
        world.spawn(Name("Environment"), environment)
        world.spawn(Transform(scale: Vec3(8, 1, 8)), Name("Ground"),
                    MeshRenderer(mesh: .plane, material: MaterialHandle("groomGround"), castsShadows: false))
        view = VStack(spacing: 0, name: "groomWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.groom` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isGroomFile(id), let builder = GroomBuilderView(session: session, asset: id, workspace: self) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            shownRevision = -1
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Groom Builder"
        title.icon = EditorIcons.asset(.material)
        return true
    }

    public func close() {
        asset = nil
        builder = nil
        if let root { world.despawn(root) }
        root = nil
        showEmpty()
    }

    /// Places the groom's preview again (after a reimport).
    public func reloadPreview() {
        if let root { world.despawn(root) }
        root = nil
        guard let asset, let prefab = session.assets?.prefab(AssetReference(asset)) else { return }
        root = world.instantiate(prefab).first
        world.propagateTransforms()
    }

    /// The entities of the preview that wear the fur.
    var furredEntities: [Entity] {
        guard let root else { return [] }
        var out: [Entity] = []
        var stack = [root]
        while let e = stack.popLast() {
            if world.get(GroomRenderer.self, for: e) != nil { out.append(e) }
            stack += world.children(of: e)
        }
        return out
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "groomToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let closeButton = Button("Close", name: "groomClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this groom"
        bar.addChild(closeButton)
        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "groomSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "groomBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Groom Builder"
        title.icon = EditorIcons.asset(.material)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .groom file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Groom (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Groom", role: .primary, name: "groomNew") { [unowned self] in
            if let id = session.run(GroomNewCommand.self, .init())?.asset { session.run(GroomOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = GroomNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No groom open"
    }

    // MARK: Strokes

    /// Adds a brush dab at `point` (the mesh's space) moving along `direction`, for the drag in progress.
    func dab(at point: Vec3, direction: Vec3?) {
        switch brush {
        case .none: return
        case .mask: pendingCuts.append(GroomCut(center: point, radius: brushRadius, length: 0, strength: brushStrength))
        case .restore: pendingCuts.append(GroomCut(center: point, radius: brushRadius, length: 1, strength: brushStrength))
        case .length: pendingCuts.append(GroomCut(center: point, radius: brushRadius, length: brushLength, strength: brushStrength))
        case .comb:
            guard let direction, length(direction) > 1e-5 else { return }
            pendingCombs.append(GroomComb(center: point, radius: brushRadius, direction: normalize(direction), strength: brushStrength))
        }
    }

    /// Writes the drag's strokes to the file as one undo step (`groom.edit`).
    func commitStroke() {
        defer { pendingCuts = []; pendingCombs = [] }
        guard let asset, !pendingCuts.isEmpty || !pendingCombs.isEmpty else { return }
        // Thin a long drag out: about one dab per half radius.
        func thin<T>(_ list: [T], center: (T) -> Vec3) -> [T] {
            var out: [T] = []
            for item in list where out.last.map({ length(center($0) - center(item)) >= brushRadius * 0.5 }) ?? true { out.append(item) }
            return out
        }
        session.run(GroomEditCommand.self, .init(asset: AssetReference(asset), addComb: pendingCombs.isEmpty ? nil : thin(pendingCombs) { $0.center },
                                                 addCut: pendingCuts.isEmpty ? nil : thin(pendingCuts) { $0.center }))
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when it belongs elsewhere), reloads the preview
    /// when the file changed and advances the wind. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            shownRevision = revision
            reloadPreview()
        }
        viewport.tools = [brushTool]
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            // Right-drag orbits here too (no fly mode in a groom view); left-drag orbits without a brush.
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            if brush == .none {
                for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.left) {
                    input[keyPath: set].remove(.left)
                    input[keyPath: set].insert(.middle)
                }
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        clock += dt
        world.update(dt: Double(dt))
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
                session.log.error("Groom Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: Vec4(0.07, 0.075, 0.09, 1))
        gizmos.removeAll()
        if brush != .none, let hover {
            gizmos.circle(center: hover.point, normal: hover.normal, radius: brushRadius * hoverScale,
                          color: brush == .mask ? Vec4(1, 0.35, 0.3, 1) : Vec4(0.4, 0.85, 1, 1))
        }
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Groom Builder needs the GPU to draw" : nil
        let tris = renderer?.stats.list.drawCalls ?? 0
        viewportWidget.caption = (brush == .none ? "Left- or right-drag orbits · wheel zooms" : "\(brush.title) brush: left-drag paints · right-drag orbits")
            + " · \(tris) draws"
    }

    /// The world size of one mesh-space meter on the furred entity under the brush.
    var hoverScale: Float = 1

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.windClock = clock
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

    /// The geometry `handle` names (an asset's, or a built-in shape).
    func geometry(_ handle: MeshHandle) -> MeshGeometry? {
        handle.assetReference.flatMap { session.assets?.mesh($0) } ?? MeshGeometry.builtin(handle)
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            try renderer.registerMaterial(Material(baseColor: Vec4(0.16, 0.17, 0.19, 1), roughness: 0.9), key: "groomGround")
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "groom builder view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Groom Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}

/// Paints the workspace's brush on the furred preview meshes.
@MainActor
final class GroomBrushTool: ViewportTool {
    unowned let workspace: GroomBuilderWorkspace
    private var last: Vec3?

    init(workspace: GroomBuilderWorkspace) { self.workspace = workspace }

    /// The nearest hit of `ray` on a furred preview mesh: the point in the mesh's space, and in world space with its normal.
    func hit(_ ray: ViewportRay) -> (local: Vec3, world: Vec3, normal: Vec3, scale: Float)? {
        var best: (t: Float, local: Vec3, world: Vec3, normal: Vec3, scale: Float)?
        let world = workspace.world
        for entity in workspace.furredEntities {
            guard let renderer = world.get(MeshRenderer.self, for: entity), let geometry = workspace.geometry(renderer.mesh) else { continue }
            let model = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
            let inverse = model.inverse
            let o4 = inverse * Vec4(ray.origin, 1), d4 = inverse * Vec4(ray.direction, 0)
            let o = Vec3(o4.x, o4.y, o4.z), d = Vec3(d4.x, d4.y, d4.z)
            var t = 0
            while t + 2 < geometry.indices.count {
                let a = geometry.vertices[Int(geometry.indices[t])].position, b = geometry.vertices[Int(geometry.indices[t + 1])].position
                let c = geometry.vertices[Int(geometry.indices[t + 2])].position
                t += 3
                // Möller-Trumbore (in the mesh's space; the ray parameter is the same in world space).
                let e1 = b - a, e2 = c - a, p = cross(d, e2)
                let det = dot(e1, p)
                guard abs(det) > 1e-12 else { continue }
                let s = o - a, u = dot(s, p) / det
                guard u >= 0, u <= 1 else { continue }
                let q = cross(s, e1), v = dot(d, q) / det
                guard v >= 0, u + v <= 1 else { continue }
                let distance = dot(e2, q) / det
                guard distance > 0, distance < (best?.t ?? .infinity) else { continue }
                let local = o + d * distance
                let w4 = model * Vec4(local, 1)
                let n = normalize(cross(e1, e2))
                let wn4 = model * Vec4(n, 0)
                let scale = length(Vec3(model.c0.x, model.c0.y, model.c0.z))
                best = (distance, local, Vec3(w4.x, w4.y, w4.z), normalize(Vec3(wn4.x, wn4.y, wn4.z)), scale)
            }
        }
        return best.map { ($0.local, $0.world, $0.normal, $0.scale) }
    }

    func handlePointer(_ event: ViewportPointerEvent, context: ViewportToolContext) -> Bool {
        let found = hit(context.ray(at: event.position))
        workspace.hover = found.map { ($0.world, $0.normal) }
        if let found { workspace.hoverScale = found.scale }
        guard workspace.brush != .none, event.button == .left else { return false }
        switch event.phase {
        case .pressed:
            guard let found else { return false }
            last = found.local
            workspace.dab(at: found.local, direction: nil)
            return true
        case .dragged:
            if let found {
                workspace.dab(at: found.local, direction: last.map { found.local - $0 })
                last = found.local
            }
            return true
        case .released:
            last = nil
            workspace.commitStroke()
            return true
        case .moved:
            return false
        }
    }

    func draw(into debugDraw: DebugDraw, context: ViewportToolContext) {}
}

public enum GroomOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, GroomTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "groom.open"
    public static let title = "Open in Groom Builder"
    public static let doc = "Opens a .groom file in the editor's Groom Builder tab (the fur growing live on its previewMesh in a light breeze, the settings form, and Mask / Restore / Length / Comb brushes that paint cut and comb strokes into the file) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"groomBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveGroom(arguments, title)
        session.openGroom = id
        session.onOpenGroom?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
