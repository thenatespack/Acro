import Engine
import Foundation

/// The engine's editor viewport tools on an ECS world rendered into render targets: picking
/// (`ScenePicker`), the selection outline (`SelectionOutlineRenderer`: primary and secondary
/// colors, dimmed where an entity is hidden) and transform gizmos (`TransformGizmo`) with undo.
/// The big view is interactive; the three small ones show the translate, rotate and scale
/// gizmos (local space, pivot on the primary entity) with a hovered handle each. Nothing
/// animates, so screenshots are deterministic. Compare window screenshots
/// (`ENGINE_SCREENSHOT_SOURCE=window`) when rendering offscreen: the views are UI.
///
/// Keys / mouse in the big view: click selects (shift-click adds or removes), drag a handle to
/// edit, W / E / R translate / rotate / scale, X toggles world / local space, C toggles the
/// pivot (selection center / primary), hold Cmd (Ctrl elsewhere) to snap, Esc cancels a drag,
/// Cmd/Ctrl+Z undoes and Shift+Cmd/Ctrl+Z redoes, right-drag orbits, the wheel zooms.
final class GizmosScene: DemoScene {
    static let name = "gizmos"
    static let summary = "editor tools: picking, selection outline, translate / rotate / scale gizmos with snapping and undo"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let picker: ScenePicker
    private let undo: UndoStack
    private let debugRenderer: DebugDrawRenderer
    private var selection = EditorSelection()
    private var views: [Viewport] = []

    // The big view's orbit camera.
    private var yaw: Float = 0.62
    private var pitch: Float = 0.5
    private var distance: Float = 13
    private let target = Vec3(0.6, 0.8, 0)
    private var orbiting = false

    private var layout: [UIRect] = []

    private static let fogColor = Vec3(0.62, 0.7, 0.82)
    private static let panel = UIColor(hex: 0x1d2330)
    private static let border = UIColor(hex: 0x39425a)
    private static let text = UIColor(hex: 0xd8dde8)
    private static let dim = UIColor(hex: 0x8a93a6)

    /// One view: its target, outline, gizmo and debug lists.
    @MainActor private final class Viewport {
        let title: String
        let target: RenderTarget
        let outline: SelectionOutlineRenderer
        let gizmo = TransformGizmo()
        let grid = DebugDraw()
        let handles = DebugDraw()
        var projection: ViewportProjection?

        init(title: String, device: RenderDevice, multisampled: Bool) throws {
            self.title = title
            target = try RenderTarget(device: device, width: 320, height: 240, multisampled: multisampled, label: "gizmos \(title)")
            outline = try SelectionOutlineRenderer(device: device, maskLabel: "outline \(title)")
            // Mid-gray lines show on the light floor and the dark background. Slightly above the floor, against z-fighting.
            grid.grid = DebugGrid(height: 0.01, spacing: 1, majorEvery: 5, fadeDistance: 40,
                                  minorColor: Vec4(0.16, 0.17, 0.2, 0.45), majorColor: Vec4(0.22, 0.24, 0.29, 0.8))
        }
    }

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        picker = ScenePicker(meshes: sceneRenderer)
        undo = UndoStack(world: world)
        debugRenderer = try DebugDrawRenderer(device: renderer.device)
        world.assignsEntityIDs = true
        // Ids from a counter, so runs are reproducible.
        var nextID: UInt64 = 0
        world.entityIDGenerator = {
            nextID += 1
            return EntityID(high: 0x6a1d, low: nextID)
        }
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), specular: 0.4, shininess: 48), key: "paint")

        views = [
            try Viewport(title: "Editor", device: renderer.device, multisampled: true),
            try Viewport(title: "Translate", device: renderer.device, multisampled: true),
            try Viewport(title: "Rotate", device: renderer.device, multisampled: false),
            try Viewport(title: "Scale", device: renderer.device, multisampled: true),
        ]
        for (view, mode) in zip(views[1...], GizmoMode.allCases) {
            view.gizmo.mode = mode
            view.gizmo.space = .local
            view.gizmo.pivot = .primary
            view.gizmo.style.size = 80
        }
        buildWorld()
    }

    private func buildWorld() {
        _ = world.spawn(Name("Environment"), SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.004))
        _ = world.spawn(Name("Sun"), Transform(rotation: .lookRotation(forward: -Vec3(0.5, 0.75, 0.35))),
                        DirectionalLight(intensity: 1.3, shadowExtent: 12, shadowCenter: Vec3(0, 0, 0)))
        let floor = world.spawn(Name("Floor"), Transform(position: Vec3(0, -0.5, 0), scale: Vec3(24, 1, 24)),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        world.add(Unpickable(), to: floor)

        func object(_ name: String, _ mesh: MeshHandle, _ transform: Transform, tint: Vec3) -> Entity {
            world.spawn(Name(name), transform, MeshRenderer(mesh: mesh, material: MaterialHandle("paint"), tint: tint))
        }
        let crate = object("Crate", .cube, Transform(position: Vec3(1.2, 0.75, -0.6), rotation: Quat(angle: 0.35, axis: Vec3(0, 1, 0)),
                                                       scale: Vec3(repeating: 1.5)), tint: hsv(0.08, 0.7, 0.95))
        let ball = object("Ball", .sphere, Transform(position: Vec3(3.3, 0.6, 1.6), scale: Vec3(repeating: 1.2)), tint: hsv(0.55, 0.6, 0.9))
        // A wall in front of the ball, so part of its outline is hidden (drawn dimmed).
        _ = object("Wall", .cube, Transform(position: Vec3(3.9, 0.7, 3.2), rotation: Quat(angle: 0.5, axis: Vec3(0, 1, 0)),
                                            scale: Vec3(1.8, 1.4, 0.2)), tint: Vec3(0.75, 0.75, 0.8))
        // A turntable with a pedestal and a statue on it: the statue is selected (a parented entity).
        let turntable = world.spawn(Name("Turntable"), Transform(position: Vec3(-2.6, 0, 0.8), rotation: Quat(angle: 0.6, axis: Vec3(0, 1, 0))))
        let pedestal = object("Pedestal", .cube, Transform(position: Vec3(0, 0.4, 0), scale: Vec3(1.6, 0.8, 1.6)), tint: Vec3(0.55, 0.55, 0.6))
        let statue = object("Statue", .cube, Transform(position: Vec3(0, 1.45, 0), rotation: Quat(angle: 0.7, axis: Vec3(1, 0, 1)),
                                                        scale: Vec3(0.8, 1.3, 0.8)), tint: hsv(0.33, 0.6, 0.85))
        world.setParent(pedestal, to: turntable)
        world.setParent(statue, to: turntable)
        for (i, p) in [Vec3(-1, 0.4, -3.2), Vec3(-4.5, 0.5, -2.5), Vec3(5.5, 0.5, -1.5), Vec3(-0.5, 0.35, 3.6)].enumerated() {
            _ = object("Prop \(i + 1)", i % 2 == 0 ? .cube : .sphere,
                       Transform(position: p, rotation: Quat(angle: Float(i) * 0.7, axis: Vec3(0, 1, 0)), scale: Vec3(repeating: p.y * 2)),
                       tint: hsv(0.12 + Float(i) * 0.21, 0.35, 0.85))
        }
        world.propagateTransforms()
        for entity in [ball, statue, crate] { selection.add(world.ensureID(of: entity)!) }
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.008, 0.009, 0.014)) }
    var wantsKeyboard: Bool { views.first?.gizmo.isDragging ?? false }
    var status: String {
        let gizmo = views[0].gizmo
        var status = "\(gizmo.mode.rawValue), \(gizmo.space.rawValue) space, pivot \(gizmo.pivot.rawValue)"
        status += ", \(selection.ids.count) selected"
        if gizmo.isDragging { status += " [dragging]" }
        return status
    }

    // MARK: - Input

    func update(input: Input, dt: Float, time: Float) {
        let main = views[0]
        handleKeys(input: input, gizmo: main.gizmo)
        if let rect = layout.first, let view = main.projection {
            handlePointer(input: input, rect: rect, view: view, gizmo: main.gizmo)
            orbit(input: input, rect: rect)
        }
        world.update(dt: Double(dt))
    }

    private func handleKeys(input: Input, gizmo: TransformGizmo) {
        if gizmo.isDragging {
            if input.wasPressed(.escape) { gizmo.cancel(world: world) }
            return
        }
        if input.wasPressed(.w) { gizmo.mode = .translate }
        if input.wasPressed(.e) { gizmo.mode = .rotate }
        if input.wasPressed(.r) { gizmo.mode = .scale }
        if input.wasPressed(.x) { gizmo.space = gizmo.space == .world ? .local : .world }
        if input.wasPressed(.c) { gizmo.pivot = gizmo.pivot == .center ? .primary : .center }
        for press in input.keyPresses where press.key == .z && press.modifiers.contains(.shortcut) {
            do {
                if press.modifiers.contains(.shift) { try undo.redo() } else { try undo.undo() }
            } catch {
                print("gizmos: undo failed: \(error)")
            }
        }
    }

    private func handlePointer(input: Input, rect: UIRect, view: ViewportProjection, gizmo: TransformGizmo) {
        let point = input.mousePosition - Vec2(rect.x, rect.y)
        let inside = rect.contains(input.mousePosition)
        let phase: ViewportPointer.Phase
        if input.wasPressed(.left as MouseButton) {
            guard inside else { return }
            phase = .pressed
        } else if input.wasReleased(.left as MouseButton) {
            phase = .released
        } else {
            phase = input.isDown(.left as MouseButton) ? .dragged : .moved
        }
        guard inside || gizmo.isDragging else { return }
        let pointer = ViewportPointer(position: point, phase: phase, modifiers: input.modifiers)
        let edit = gizmo.handle(pointer, view: view, world: world, selection: selection)
        if phase == .pressed && edit == nil {
            // Missed the gizmo: pick.
            let hit = picker.pick(at: point, in: view, world: world)
            selection.click(hit?.entity, modifiers: input.modifiers, in: world)
        }
        if let edit, edit.phase == .ended {
            do {
                try edit.record(in: undo)
            } catch {
                print("gizmos: recording the edit failed: \(error)")
            }
        }
        if gizmo.hovered != nil || gizmo.isDragging { input.cursor = .pointingHand }
    }

    private func orbit(input: Input, rect: UIRect) {
        if input.wasPressed(.right as MouseButton) && rect.contains(input.mousePosition) { orbiting = true }
        if !input.isDown(.right as MouseButton) { orbiting = false }
        if orbiting {
            yaw -= input.mouseDelta.x * 0.008
            pitch = min(max(pitch + input.mouseDelta.y * 0.008, 0.05), 1.5)
        }
        if rect.contains(input.mousePosition) {
            distance = min(max(distance * (1 - input.scrollDelta.y * 0.01), 3), 60)
        }
    }

    // MARK: - Rendering

    func renderOffscreen(engine: Engine, frame: Frame) {
        layout = Self.layout(size: engine.ui.size)
        let scale = engine.ui.scale
        for (view, rect) in zip(views, layout) {
            do {
                try view.target.resize(toPoints: Vec2(rect.width, rect.height), scale: scale)
            } catch {
                print("gizmos: resizing a target failed: \(error)")
            }
        }
        let sceneViews = views.indices.map { sceneView($0) }
        for (i, view) in views.enumerated() {
            view.projection = ViewportProjection(sceneViews[i], size: Vec2(layout[i].width, layout[i].height), pixelScale: scale)
        }
        showcaseHover()

        sceneRenderer.beginViews(world: world, frame: frame, shadowFocus: sceneViews[0])
        let selected = selection.entities(in: world), primary = selection.primaryEntity(in: world)
        for (view, sceneView) in zip(views, sceneViews) {
            guard let projection = view.projection else { continue }
            view.handles.removeAll()
            view.gizmo.draw(into: view.handles, view: projection, world: world, selection: selected, primary: primary)
            let debugView = DebugView(view: sceneView.view, projection: sceneView.projection,
                                      viewportSize: (view.target.width, view.target.height), reversedZ: sceneView.reversedZ)
            view.outline.renderView(sceneView, sceneRenderer: sceneRenderer, world: world, selection: selected, primary: primary,
                                    into: view.target, pixelScale: scale, frame: frame, debugDraw: view.grid) { pass in
                self.debugRenderer.draw(view.handles, in: pass, view: debugView)
            }
        }
    }

    /// The big view orbits `target` with reversed-Z; the small ones look at the primary entity.
    private func sceneView(_ index: Int) -> SceneView {
        let size = layout.indices.contains(index) ? layout[index] : UIRect(x: 0, y: 0, width: 4, height: 3)
        let aspect = max(size.width, 1) / max(size.height, 1)
        if index == 0 {
            let eye = target + Vec3(cosf(pitch) * sinf(yaw), sinf(pitch), cosf(pitch) * cosf(yaw)) * distance
            return SceneView(view: Mat4.lookAt(eye: eye, target: target),
                             projection: Mat4.perspective(fovY: .pi / 3.6, aspect: aspect, near: 200, far: 0.05),
                             reversedZ: true, clearColor: Vec4(0.045, 0.05, 0.065, 1))
        }
        let focus = selection.primaryEntity(in: world).map { Vec3(world.worldMatrix(of: $0).c3.x, 0.75, world.worldMatrix(of: $0).c3.z) }
            ?? .zero
        return SceneView(view: Mat4.lookAt(eye: focus + Vec3(-3.2, 3.4, 5.2), target: focus),
                         projection: Mat4.perspective(fovY: .pi / 3.4, aspect: aspect, near: 0.05, far: 100),
                         clearColor: Vec4(0.045, 0.05, 0.065, 1))
    }

    /// Hovers one handle in each small view (the screenshot shows the highlight).
    private func showcaseHover() {
        let handles: [GizmoHandle] = [.axis(1), .ring(0), .uniform]
        let selected = selection.entities(in: world), primary = selection.primaryEntity(in: world)
        for (view, handle) in zip(views[1...], handles) {
            guard let projection = view.projection,
                  let frame = view.gizmo.frame(view: projection, world: world, selection: selected, primary: primary) else { continue }
            let point: Vec3
            switch handle {
            case .axis(let i): point = frame.origin + frame.axes[i] * (0.6 * frame.length)
            case .ring(let i): point = frame.origin + normalize(frame.toViewer - frame.axes[i] * dot(frame.toViewer, frame.axes[i])) * frame.length
            default: point = frame.origin
            }
            guard let screen = projection.project(point) else { continue }
            view.gizmo.handle(ViewportPointer(position: screen, phase: .moved), view: projection, world: world, selection: selected,
                              primary: primary)
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ ui: UIDrawList) {
        for (i, (view, rect)) in zip(views, layout).enumerated() {
            let frame = UIRect(x: rect.x - 1, y: rect.y - 25, width: rect.width + 2, height: rect.height + 26)
            ui.fillRect(frame, color: Self.panel, radii: UICornerRadii(6))
            ui.strokeRect(frame, color: Self.border, width: 1, radii: UICornerRadii(6))
            var title = view.title
            if i == 0 {
                let g = view.gizmo
                title += " · \(g.mode.rawValue) · \(g.space.rawValue) · pivot \(g.pivot.rawValue)"
            }
            ui.drawText(title, at: Vec2(rect.x + 8, rect.y - 19), size: 13, color: Self.text)
            ui.drawImage(view.target.texture, in: rect)
        }
        guard let main = layout.first else { return }
        let help = "Click selects, shift-click adds · drag handles · W/E/R move/rotate/scale · X space · C pivot · "
            + "hold Cmd/Ctrl to snap · Esc cancels · Cmd/Ctrl+Z undo (+Shift redo) · right-drag orbits"
        ui.drawText(help, at: Vec2(main.x, main.maxY + 8), size: 12, color: Self.dim)
        let history = undo.canUndo ? undo.undoTitle : "nothing to undo"
        ui.drawText("\(selection.ids.count) selected · \(history)", at: Vec2(main.x, main.maxY + 26), size: 12, color: Self.dim)
    }

    /// The big view on the left and three small ones stacked on the right, in whole points.
    private static func layout(size: Vec2) -> [UIRect] {
        let margin: Float = 16, header: Float = 26, gap: Float = 12, footer: Float = 46
        let top = margin + header
        let height = max(size.y - top - margin - footer, 48).rounded(.down)
        let inner = max(size.x - 2 * margin - gap, 64)
        let mainWidth = (inner * 0.66).rounded()
        let sideWidth = (inner - mainWidth).rounded(.down)
        let sideHeight = ((height - 2 * (gap + header)) / 3).rounded(.down)
        var rects = [UIRect(x: margin, y: top, width: mainWidth, height: height)]
        for k in 0..<3 {
            rects.append(UIRect(x: margin + mainWidth + gap, y: top + Float(k) * (sideHeight + gap + header), width: sideWidth,
                                height: max(sideHeight, 16)))
        }
        return rects
    }
}
