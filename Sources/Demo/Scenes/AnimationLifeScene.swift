import Engine
import Foundation

/// The data-driven animation components, with no game code: `FieldAnimator` bobbing, breathing
/// and rocking objects and sweeping a tint, `LightFlicker` on a candle-like, a neon and a
/// broken lamp, `Spin`, and a `CameraPath` dolly with a look-at target and a little handheld
/// shake. Everything is scene data run by `World.addBuiltinAnimationSystems()` (the editor's
/// play mode and built games run the same), at a fixed 1/60 s per frame in screenshot mode.
final class AnimationLifeScene: DemoScene {
    static let name = "animation_life"
    static let summary = "FieldAnimator bobbing / breathing, LightFlicker styles, Spin and a CameraPath dolly, all from scene data"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private static let clearColor = Vec3(0.02, 0.022, 0.03)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.5, 0.5, 0.5, 1), checker: true, roughness: 0.6), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.75, 0.72, 0.68, 1), roughness: 0.75), key: "wall")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), metallic: 0.2, roughness: 0.3), key: "paint")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), emissive: 1), key: "bulb")

        world.addBuiltinAnimationSystems()

        // The dolly: a slow arc in front of the scene, always facing the centerpiece.
        let focusEntity = world.spawn(Transform(position: Vec3(0, 1.4, 0)), Name("Dolly Target"))
        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(-7, 3, 11), at: Vec3(0, 1.4, 0)),
            Camera(fovY: .pi / 3.2, near: 0.1, far: 100, clearColor: Vec4(Self.clearColor, 1)),
            CameraPath(points: [Vec3(-7, 3, 11), Vec3(-2.5, 2.2, 9), Vec3(3, 2.6, 9), Vec3(7.5, 3.4, 11)],
                       duration: 24, loop: .pingPong, easing: .sineInOut,
                       lookAtTarget: world.ref(to: focusEntity), handheld: 0.025, handheldRotation: 0.25, handheldSpeed: 1.2,
                       seed: 3))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.12, 0.15, 0.25), groundColor: Vec3(0.03, 0.03, 0.04),
                                         ambientIntensity: 0.25, fogColor: Self.clearColor, fogDensity: 0.012))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.4, 0.8, 0.5)))), Name("Moon"),
            DirectionalLight(color: Vec3(0.55, 0.65, 1), intensity: 0.35, shadowExtent: 18, shadowCenter: Vec3(0, 1, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)), Name("Floor"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        _ = world.spawn(
            Transform(position: Vec3(0, 3, -6), scale: Vec3(24, 7, 0.5)), Name("Back Wall"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("wall")))

        buildObjects()
        buildLamps()
        world.propagateTransforms()
    }

    private func buildObjects() {
        // A row of bobbing spheres, each phase-shifted; a breathing cube; a rocking slab; a Spin.
        let colors: [Vec3] = [Vec3(1, 0.35, 0.25), Vec3(1, 0.75, 0.2), Vec3(0.3, 0.85, 0.4), Vec3(0.25, 0.6, 1), Vec3(0.75, 0.4, 1)]
        for k in 0..<5 {
            let x = Float(k - 2) * 2.2
            _ = world.spawn(
                Transform(position: Vec3(x, 0.9, 1.5), scale: Vec3(repeating: 1.1)), Name("Bobber \(k)"),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("paint"), tint: colors[k]),
                FieldAnimator(tracks: [
                    .wave("Transform.position.y", .sine, amplitude: 0.45, frequency: 0.4, phase: Float(k) * 0.18),
                    .wave("MeshRenderer.tint.b", .sine, amplitude: 0.25, frequency: 0.2, phase: Float(k) * 0.18, additive: true),
                ]))
        }
        _ = world.spawn(
            Transform(position: Vec3(0, 1.6, -1.5), scale: Vec3(repeating: 1.6)), Name("Breather"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: Vec3(0.9, 0.9, 0.95)),
            FieldAnimator(tracks: [
                .fromTo("Transform.scale.x", from: 0, to: 0.35, duration: 3, easing: .sineInOut),
                .fromTo("Transform.scale.y", from: 0, to: -0.2, duration: 3, easing: .sineInOut),
                .fromTo("Transform.scale.z", from: 0, to: 0.35, duration: 3, easing: .sineInOut),
                .wave("Transform.rotation.y", .triangle, amplitude: 20, frequency: 0.1),
            ]), Spin(axis: Vec3(0, 1, 0), speed: 0.4))
        _ = world.spawn(
            Transform(position: Vec3(-6, 1.2, -2.5), scale: Vec3(1.6, 2.4, 0.3)), Name("Rocker"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: Vec3(0.3, 0.8, 0.9)),
            FieldAnimator(tracks: [.wave("Transform.rotation.z", .sine, amplitude: 14, frequency: 0.25)]))
        _ = world.spawn(
            Transform(position: Vec3(6, 1.2, -2.5), scale: Vec3(1.6, 2.4, 0.3)), Name("Noisy"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("paint"), tint: Vec3(0.9, 0.5, 0.3)),
            FieldAnimator(tracks: [.wave("Transform.position.x", .noise, amplitude: 0.6, frequency: 0.6),
                                   .wave("Transform.position.y", .noise, amplitude: 0.3, frequency: 0.9, phase: 4)]))
    }

    private func buildLamps() {
        let styles: [(FlickerStyle, Vec3, Float, Vec3)] = [
            (.smooth, Vec3(1, 0.62, 0.28), 14, Vec3(-5.5, 3.2, 3)),
            (.neonBuzz, Vec3(0.3, 0.9, 1), 16, Vec3(0, 3.6, 4)),
            (.strobe, Vec3(1, 0.3, 0.55), 14, Vec3(5.5, 3.2, 3)),
        ]
        for (i, (style, color, intensity, position)) in styles.enumerated() {
            let flicker = LightFlicker(style: style, minIntensity: style == .smooth ? 0.35 : 0.0, maxIntensity: 1,
                                       speed: style == .smooth ? 5 : (style == .neonBuzz ? 3 : 6),
                                       dropout: style == .strobe ? 0.4 : 0.2, seed: i)
            _ = world.spawn(Transform(position: position), Name("Lamp \(i)"),
                            PointLight(color: color, intensity: intensity, range: 14), flicker)
            _ = world.spawn(Transform(position: position, scale: Vec3(repeating: 0.25)), Name("Bulb \(i)"),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle("bulb"), tint: color, castsShadows: false))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.2, pitch: 0.2, distance: 14, target: Vec3(0, 1.4, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.clearColor) }
    var status: String { "\(world.entityCount) entities, t=\(String(format: "%.1f", world.time.elapsed))s" }

    /// The dolly drives the camera; orbit controls are ignored.
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        let m = world.get(Transform.self, for: cameraEntity) ?? Transform()
        return ViewCamera(eye: m.position, target: m.position + m.rotation * Vec3(0, 0, -1))
    }

    func update(input: Input, dt: Float, time: Float) {
        world.update(dt: Double(dt))
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
