import Engine
import Foundation

/// One ECS world rendered twice per frame into render targets, shown side by side through the
/// UI draw list like an editor: an "editor" fly camera with debug drawing (ground grid, axes,
/// boxes around the selected entities, the game camera's frustum, the sun's direction, labels)
/// and the game camera's own view. Both share one shadow map. Compare window screenshots
/// (`ENGINE_SCREENSHOT_SOURCE=window`) when rendering offscreen: the views are UI.
///
/// Keys / mouse: right-drag in the editor view flies its camera (the mouse is captured: WASD
/// moves, Q / E go down / up, Esc or releasing the button lets go); drag the divider between the
/// views to resize them (the targets follow).
final class ViewportsScene: DemoScene {
    static let name = "viewports"
    static let summary = "render targets: one world drawn from an editor and a game camera, debug draw, mouse capture"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let editorTarget: RenderTarget
    private let gameTarget: RenderTarget
    private let gizmos = DebugDraw()
    private let gameCamera: Entity
    private var selected: [Entity] = []
    private var lamp = Entity.invalid
    private var time: Float = 0

    // Editor fly camera.
    private var editorPosition = Vec3(21, 15, 23)
    private var editorYaw: Float = 0
    private var editorPitch: Float = 0
    private var flying = false

    // Layout (window points), computed every frame from the window size and the split.
    private var split: Float = 0.58
    private var draggingSplit = false
    private var layout = Layout()
    private var viewStats: (editor: RenderListStats, game: RenderListStats)?

    private static let fogColor = Vec3(0.62, 0.7, 0.82)
    private static let panel = UIColor(hex: 0x1d2330)
    private static let border = UIColor(hex: 0x39425a)
    private static let text = UIColor(hex: 0xd8dde8)
    private static let dim = UIColor(hex: 0x8a93a6)

    private struct Layout {
        var editor = UIRect(x: 0, y: 0, width: 1, height: 1)
        var game = UIRect(x: 0, y: 0, width: 1, height: 1)
        var divider = UIRect(x: 0, y: 0, width: 1, height: 1)
    }

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        editorTarget = try RenderTarget(device: renderer.device, width: 640, height: 480, label: "editor")
        // Single-sampled (on an MSAA device the pipelines then use their 1x variants), so the
        // scene exercises both kinds of target.
        gameTarget = try RenderTarget(device: renderer.device, width: 480, height: 480, multisampled: false, label: "game")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), specular: 0.4, shininess: 48), key: "paint")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 0.85, 0.5, 1), emissive: 1), key: "glow")

        _ = world.spawn(SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.006))
        // A fixed shadow square covering the whole set, so both views get shadows from one map.
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.5, 0.75, 0.35))),
            DirectionalLight(intensity: 1.3, shadowExtent: 20, shadowCenter: Vec3(0, 0, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(36, 1, 36)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        gameCamera = world.spawn(
            Transform.looking(from: Vec3(14, 7, 10), at: Vec3(0, 1.5, 0)),
            Camera(fovY: .pi / 3.2, near: 0.3, far: 120, clearColor: Vec4(Self.fogColor, 1)))

        var rng = SplitMix64(state: 11)
        for gz in 0..<5 {
            for gx in 0..<5 {
                let p = Vec2(Float(gx) - 2, Float(gz) - 2) * 4.5
                if (p * p).sum() < 20 { continue }
                let sphere = (gx + gz) % 3 == 0
                let size = 1 + rng.next() * 1.2
                let entity = world.spawn(
                    Transform(position: Vec3(p.x, size / 2, p.y), rotation: Quat(angle: rng.next() * .pi, axis: Vec3(0, 1, 0)),
                              scale: Vec3(repeating: size)),
                    MeshRenderer(mesh: sphere ? .sphere : .cube, material: MaterialHandle("paint"), tint: hsv(rng.next(), 0.55, 0.95)))
                if gx == 4 && gz == 1 || gx == 0 && gz == 3 { selected.append(entity) }
            }
        }
        buildCarousel()

        world.addSystem("spin") { world in
            let t = Float(world.time.elapsed)
            world.queryMutating(Transform.self, Spin.self) { _, transform, spin in
                transform.rotation = Quat(angle: spin.speed * t + spin.phase, axis: spin.axis)
            }
        }
        world.propagateTransforms()

        let forward = normalize(Vec3(0, 1, 0) - editorPosition)
        editorYaw = atan2f(-forward.x, -forward.z)
        editorPitch = asinf(forward.y)
    }

    /// A spinning pivot with a pillar, a lamp and four arms; one arm is selected.
    private func buildCarousel() {
        let pivot = world.spawn(Transform(), Spin(speed: 0.5))
        let pillar = world.spawn(
            Transform(position: Vec3(0, 2, 0), scale: Vec3(1, 4, 1)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: Vec3(0.85, 0.85, 0.9)))
        world.setParent(pillar, to: pivot)
        lamp = world.spawn(
            Transform(position: Vec3(0, 4.6, 0), scale: Vec3(repeating: 0.9)),
            MeshRenderer(mesh: .sphere, material: MaterialHandle("glow"), castsShadows: false))
        world.setParent(lamp, to: pivot)
        for k in 0..<4 {
            let angle = Float(k) * .pi / 2
            let arm = world.spawn(
                Transform(position: Vec3(cosf(angle) * 3.5, 2.2, sinf(angle) * 3.5), rotation: Quat(angle: -angle, axis: Vec3(0, 1, 0)),
                          scale: Vec3(2, 0.45, 0.45)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: hsv(Float(k) / 4, 0.7, 0.9)))
            world.setParent(arm, to: pivot)
            if k == 0 { selected.append(arm) }
        }
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.008, 0.009, 0.014)) }
    var status: String {
        var status = "targets \(editorTarget.width)x\(editorTarget.height) + \(gameTarget.width)x\(gameTarget.height)"
        if let (editor, game) = viewStats {
            status += ", editor \(editor.opaque + editor.transparent) drawn / \(editor.culled) culled"
            status += ", game \(game.opaque + game.transparent) / \(game.culled)"
        }
        return status + (flying ? " [flying]" : "")
    }

    func update(input: Input, dt: Float, time t: Float) {
        time = t
        updateLayout(input: input)
        flyEditorCamera(input: input, dt: dt)

        // The game camera circles the set slowly.
        let angle = 0.9 + t * 0.15
        world.add(Transform.looking(from: Vec3(sinf(angle) * 15, 6.5, cosf(angle) * 15), at: Vec3(0, 1.5, 0)), to: gameCamera)
        world.update(dt: Double(dt))
    }

    /// The divider drag (resize cursor) and cursor shapes over the views.
    private func updateLayout(input: Input) {
        let mouse = input.mousePosition
        let overDivider = layout.divider.inset(by: -3).contains(mouse)
        if input.wasPressed(.left as MouseButton) && overDivider { draggingSplit = true }
        if !input.isDown(.left as MouseButton) { draggingSplit = false }
        if draggingSplit {
            let inner = layout.game.maxX - layout.editor.x - layout.divider.width
            split = min(max((mouse.x - layout.editor.x - layout.divider.width / 2) / max(inner, 1), 0.2), 0.8)
        }
        if draggingSplit || overDivider {
            input.cursor = .resizeHorizontal
        } else if layout.editor.contains(mouse) {
            input.cursor = .crosshair
        }
    }

    /// Right-drag in the editor view: captured mouse looks around, WASD / Q / E move.
    private func flyEditorCamera(input: Input, dt: Float) {
        if input.wasPressed(.right as MouseButton) && layout.editor.contains(input.mousePosition) {
            input.isMouseCaptured = true
        }
        if !input.isDown(.right as MouseButton) { input.isMouseCaptured = false }
        flying = input.isMouseCaptured
        guard flying else { return }
        editorYaw -= input.mouseDelta.x * 0.004
        editorPitch = min(max(editorPitch - input.mouseDelta.y * 0.004, -1.5), 1.5)
        let forward = editorForward
        let right = normalize(cross(forward, Vec3(0, 1, 0)))
        var move = forward * input.axis(negative: .s, positive: .w)
        move += right * input.axis(negative: .a, positive: .d)
        move.y += input.axis(negative: .q, positive: .e)
        editorPosition += move * (12 * dt)
    }

    private var editorForward: Vec3 {
        Vec3(-sinf(editorYaw) * cosf(editorPitch), sinf(editorPitch), -cosf(editorYaw) * cosf(editorPitch))
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        layout = Self.layout(size: engine.ui.size, split: split)
        do {
            try editorTarget.resize(toPoints: Vec2(layout.editor.width, layout.editor.height), scale: engine.ui.scale)
            try gameTarget.resize(toPoints: Vec2(layout.game.width, layout.game.height), scale: engine.ui.scale)
        } catch {
            print("viewports: resizing the targets failed: \(error)")
        }

        guard let game = SceneView(camera: gameCamera, in: world, aspect: gameTarget.aspectRatio) else { return }
        let editor = SceneView(
            view: Mat4.lookAt(eye: editorPosition, target: editorPosition + editorForward),
            projection: Mat4.perspective(fovY: .pi / 3.6, aspect: editorTarget.aspectRatio, near: 0.1, far: 300),
            clearColor: Vec4(0.045, 0.05, 0.065, 1))

        sceneRenderer.beginViews(world: world, frame: frame, shadowFocus: game)
        drawGizmos(game: game)
        sceneRenderer.renderView(editor, into: editorTarget, frame: frame, debugDraw: gizmos)
        let editorStats = sceneRenderer.stats.list
        sceneRenderer.renderView(game, into: gameTarget, frame: frame)
        viewStats = (editorStats, sceneRenderer.stats.list)
    }

    /// The editor view's debug shapes for this frame.
    private func drawGizmos(game: SceneView) {
        gizmos.removeAll()
        // Mid-gray lines show on the light floor and the dark background. Slightly above the floor, against z-fighting.
        gizmos.grid = DebugGrid(height: 0.01, spacing: 1, majorEvery: 5, fadeDistance: 70,
                                minorColor: Vec4(0.16, 0.17, 0.2, 0.45), majorColor: Vec4(0.22, 0.24, 0.29, 0.8))
        gizmos.axes(.identity, length: 2.5, style: DebugDraw.Style(width: 3, depth: .onTop))

        let yellow = Vec4(1, 0.8, 0.1, 1), orange = Vec4(1, 0.45, 0.1, 1)
        for (i, entity) in selected.enumerated() {
            guard let matrix = world.get(GlobalTransform.self, for: entity)?.matrix,
                  let renderer = world.get(MeshRenderer.self, for: entity),
                  let bounds = sceneRenderer.mesh(renderer.mesh)?.bounds else { continue }
            let box = bounds.transformed(by: matrix)
            gizmos.box(box, color: yellow, style: DebugDraw.Style(width: 1.5, depth: .onTop))
            gizmos.box(matrix * Mat4.translation(bounds.center) * Mat4.scale(bounds.halfExtent), color: orange,
                       style: DebugDraw.Style(width: 2.5))
            gizmos.text("selected \(i + 1)", at: box.center + Vec3(0, box.halfExtent.y + 0.6, 0), color: yellow, size: 26)
        }

        // The game camera: its frustum (pulled in), its body and a label.
        let white = Vec4(0.95, 0.95, 0.95, 1)
        gizmos.frustum(viewProjection: game.viewProjection, color: white, farFraction: 0.04, style: DebugDraw.Style(width: 2))
        gizmos.box(game.view.inverse * Mat4.translation(Vec3(0, 0, 0.5)) * Mat4.scale(Vec3(0.35, 0.25, 0.5)), color: white,
                   style: DebugDraw.Style(width: 2))
        gizmos.text("game camera", at: game.eye - Vec3(0, 1.1, 0), color: white, size: 26)

        // The sun's direction, a world-width ring on the ground and a wire sphere around the lamp.
        let sun = -normalize(Vec3(0.5, 0.75, 0.35))
        gizmos.arrow(from: Vec3(-9, 9, -6), to: Vec3(-9, 9, -6) + sun * 4, color: Vec4(1, 0.9, 0.3, 1), headSize: 0.8,
                     style: DebugDraw.Style(width: 3))
        gizmos.text("sun", at: Vec3(-9, 9.9, -6), color: Vec4(1, 0.9, 0.3, 1), size: 26)
        gizmos.circle(center: Vec3(0, 0.02, 0), normal: Vec3(0, 1, 0), radius: 9, color: Vec4(0.2, 0.9, 1, 0.8), segments: 64,
                      style: DebugDraw.Style(width: 0.08, worldWidth: true))
        if let lampMatrix = world.get(GlobalTransform.self, for: lamp)?.matrix {
            gizmos.sphere(center: Vec3(lampMatrix.c3.x, lampMatrix.c3.y, lampMatrix.c3.z), radius: 0.9,
                          color: Vec4(1, 0.85, 0.5, 1), style: DebugDraw.Style(width: 1.5))
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ ui: UIDrawList) {
        let l = layout
        for (rect, title, target) in [(l.editor, "Editor", editorTarget), (l.game, "Game camera", gameTarget)] {
            let frame = UIRect(x: rect.x - 1, y: rect.y - 29, width: rect.width + 2, height: rect.height + 30)
            ui.fillRect(frame, color: Self.panel, radii: UICornerRadii(6))
            ui.strokeRect(frame, color: Self.border, width: 1, radii: UICornerRadii(6))
            ui.drawText(title, at: Vec2(rect.x + 8, rect.y - 22), size: 14, color: Self.text)
            ui.drawText("\(target.width)x\(target.height) px", at: Vec2(rect.maxX - 168, rect.y - 21), size: 13, color: Self.dim,
                        maxWidth: 160, alignment: .right)
            ui.drawImage(target.texture, in: rect)
        }
        let grip = l.divider
        ui.fillRect(UIRect(x: grip.center.x - 1.5, y: grip.center.y - 18, width: 3, height: 36),
                    color: draggingSplit ? Self.text : Self.border, radii: UICornerRadii(1.5))
        ui.drawText("Right-drag in the editor view to fly (WASD, Q/E; Esc lets go) · drag the divider to resize the views",
                    at: Vec2(l.editor.x, l.editor.maxY + 8), size: 13, color: Self.dim)
    }

    /// Two image rects side by side under a title bar, with a divider between them, in whole points.
    private static func layout(size: Vec2, split: Float) -> Layout {
        let margin: Float = 16, header: Float = 30, gap: Float = 12, footer: Float = 30
        let top = margin + header
        let height = max(size.y - top - margin - footer, 16).rounded(.down)
        let inner = max(size.x - 2 * margin - gap, 32)
        let left = (inner * split).rounded()
        return Layout(
            editor: UIRect(x: margin, y: top, width: left, height: height),
            game: UIRect(x: margin + left + gap, y: top, width: (inner - left).rounded(.down), height: height),
            divider: UIRect(x: margin + left, y: top, width: gap, height: height))
    }
}
