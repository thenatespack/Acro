import Engine
import Foundation

/// HDR post-processing (`PostProcess` component, see `PostProcessSettings`): a dark room with a
/// window onto a sunlit courtyard and a bright sky (both far above 1), ceiling light strips,
/// neon bars, a hot lamp bulb and a few glossy objects. The range from the shadowed corners to
/// the sky is about 2^10, so the tonemappers, bloom and exposure all visibly matter.
///
/// Keys: **T** cycles the tonemapper, **B** toggles bloom, **Z** / **X** lower / raise the
/// exposure by half a stop, **N** toggles auto exposure. Starts with ACES, bloom and auto
/// exposure on. Static, so screenshots are deterministic (auto exposure converges on the first
/// frame, then holds).
final class PostScene: DemoScene {
    static let name = "post"
    static let summary = "HDR post-processing: tonemappers, bloom, manual and auto exposure in a dark room with a sunlit window"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private let settingsEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    /// Linear sky radiance seen through the window (the camera's clear color).
    private static let sky = Vec3(1.6, 2.3, 3.6)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let materials: [(String, Material)] = [
            ("ground", Material(baseColor: Vec4(0.5, 0.48, 0.44, 1), checker: true, roughness: 0.9)),
            ("wall", Material(baseColor: Vec4(0.42, 0.4, 0.38, 1), roughness: 0.85)),
            ("floor", Material(baseColor: Vec4(0.3, 0.22, 0.16, 1), roughness: 0.45)),
            ("metal", Material(baseColor: Vec4(0.95, 0.93, 0.88, 1), metallic: 1, roughness: 0.15)),
            ("gold", Material(baseColor: Vec4(1, 0.78, 0.34, 1), metallic: 1, roughness: 0.35)),
            ("gloss", Material(baseColor: Vec4(0.08, 0.1, 0.5, 1), roughness: 0.1)),
            ("pedestal", Material(baseColor: Vec4(0.6, 0.6, 0.62, 1), roughness: 0.6)),
            ("strip", Material(baseColor: Vec4(0.05, 0.05, 0.05, 1), emissiveColor: Vec3(1, 0.93, 0.82), emissiveStrength: 14)),
            ("neon red", Material(baseColor: Vec4(0.05, 0.05, 0.05, 1), emissiveColor: Vec3(1, 0.08, 0.12), emissiveStrength: 10)),
            ("neon green", Material(baseColor: Vec4(0.05, 0.05, 0.05, 1), emissiveColor: Vec3(0.1, 1, 0.3), emissiveStrength: 10)),
            ("neon blue", Material(baseColor: Vec4(0.05, 0.05, 0.05, 1), emissiveColor: Vec3(0.15, 0.35, 1), emissiveStrength: 12)),
            ("bulb", Material(baseColor: Vec4(0.1, 0.1, 0.1, 1), emissiveColor: Vec3(1, 0.62, 0.3), emissiveStrength: 60)),
        ]
        for (key, material) in materials { try sceneRenderer.registerMaterial(material, key: key) }

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 2.4, 6), at: Vec3(0, 2.2, -1)),
            Camera(fovY: .pi / 3, near: 0.1, far: 300, clearColor: Vec4(Self.sky, 1)))
        settingsEntity = world.spawn(
            Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0, autoExposure: true, bloom: true, bloomIntensity: 0.05))
        // Interior: almost no ambient light; the sun through the window and the emissives do the work.
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.2, 0.18, 0.15), ambientIntensity: 0.02))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: normalize(Vec3(0.25, -0.45, 1)))),
            DirectionalLight(color: Vec3(1, 0.95, 0.85), intensity: 7, shadowExtent: 16, shadowCenter: Vec3(0, 2, -2)))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3, shadows: Bool = true) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name),
                            MeshRenderer(mesh: .cube, material: MaterialHandle(material), castsShadows: shadows))
        }
        // The courtyard outside, and the room: 16 x 6 x 12 with a 6 x 3 window in the far wall.
        box("Courtyard", "ground", center: Vec3(0, -0.5, -20), size: Vec3(80, 1, 60), shadows: false)
        box("Floor", "floor", center: Vec3(0, -0.24, 0), size: Vec3(16.5, 0.5, 12.5), shadows: false)
        box("Ceiling", "wall", center: Vec3(0, 6.25, 0), size: Vec3(16.5, 0.5, 12.5))
        box("Wall left", "wall", center: Vec3(-8, 3, 0), size: Vec3(0.5, 6, 12.5))
        box("Wall right", "wall", center: Vec3(8, 3, 0), size: Vec3(0.5, 6, 12.5))
        box("Wall back", "wall", center: Vec3(0, 3, 6.25), size: Vec3(16.5, 6, 0.5))
        box("Window wall left", "wall", center: Vec3(-5.5, 3, -6), size: Vec3(5, 6, 0.5))
        box("Window wall right", "wall", center: Vec3(5.5, 3, -6), size: Vec3(5, 6, 0.5))
        box("Window sill", "wall", center: Vec3(0, 0.75, -6), size: Vec3(6, 1.5, 0.5))
        box("Window lintel", "wall", center: Vec3(0, 5.25, -6), size: Vec3(6, 1.5, 0.5))

        // Emissives: two ceiling strips (with point lights under them), neon bars, a lamp bulb.
        for x: Float in [-4, 4] {
            box("Light strip", "strip", center: Vec3(x, 5.95, 0.5), size: Vec3(0.3, 0.08, 6), shadows: false)
            _ = world.spawn(Transform(position: Vec3(x, 5.4, 0.5)), Name("Strip light"),
                            PointLight(color: Vec3(1, 0.93, 0.82), intensity: 5, range: 10))
        }
        for (i, color) in ["neon red", "neon green", "neon blue"].enumerated() {
            box("Neon", color, center: Vec3(7.7, 2 + Float(i) * 0.6, -3.6 + Float(i) * 0.4), size: Vec3(0.08, 0.1, 2.4), shadows: false)
        }
        _ = world.spawn(Transform(position: Vec3(7.2, 2.6, -3.2)), Name("Neon light"),
                        PointLight(color: Vec3(0.6, 0.5, 0.7), intensity: 1.5, range: 5))
        box("Lamp post", "pedestal", center: Vec3(-4.5, 0.6, -3.5), size: Vec3(0.12, 1.2, 0.12))
        _ = world.spawn(Transform(position: Vec3(-4.5, 1.35, -3.5), scale: Vec3(repeating: 0.35)), Name("Bulb"),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("bulb"), castsShadows: false))
        _ = world.spawn(Transform(position: Vec3(-4.5, 1.35, -3.5)), Name("Bulb light"),
                        PointLight(color: Vec3(1, 0.62, 0.3), intensity: 4, range: 8))

        // Objects: chrome, gold and glossy blue spheres on pedestals.
        for (i, material) in ["metal", "gold", "gloss"].enumerated() {
            let x = Float(i - 1) * 2.4
            box("Pedestal", "pedestal", center: Vec3(x, 0.4, -1), size: Vec3(1, 0.8, 1))
            _ = world.spawn(Transform(position: Vec3(x, 1.45, -1), scale: Vec3(repeating: 1.3)), Name("Sphere \(material)"),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle(material)))
        }
        world.propagateTransforms()
    }

    private var settings: PostProcessSettings {
        get { world.get(PostProcess.self, for: settingsEntity) ?? PostProcessSettings() }
        set { world.add(newValue, to: settingsEntity) }
    }

    var initialView: OrbitView { OrbitView(yaw: -0.3, pitch: 0.05, distance: 6.8, target: Vec3(0, 2.3, -1)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String {
        let s = settings
        return "tonemapper \(s.tonemapper.rawValue) [T], bloom \(s.bloom ? "on" : "off") [B], exposure "
            + String(format: "%+.1f EV", s.exposure) + " [Z/X], auto exposure \(s.autoExposure ? "on" : "off") [N]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
        var s = settings
        if input.wasPressed(.t) {
            let all = PostProcessSettings.Tonemapper.allCases
            s.tonemapper = all[(all.firstIndex(of: s.tonemapper)! + 1) % all.count]
        }
        if input.wasPressed(.b) { s.bloom.toggle() }
        if input.wasPressed(.z) { s.exposure -= 0.5 }
        if input.wasPressed(.x) { s.exposure += 0.5 }
        if input.wasPressed(.n) { s.autoExposure.toggle() }
        if s != settings { settings = s }
        world.update(dt: Double(dt))
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
