import Engine
import Foundation

/// Height fog, volumetric light shafts and per-entity emissive overrides: a dusk street between
/// two rows of buildings with gaps, a low sun at the far end casting shafts through the gaps
/// into ground-hugging fog (`SceneEnvironment.fogHeightFalloff`, `volumetricFog`), and neon
/// signs that share one emissive material but differ in `MeshRenderer.emissiveTint` and
/// `emissiveStrength`, with point lights beside them that scatter in the fog too. Static, so
/// screenshots are deterministic.
final class FogScene: DemoScene {
    static let name = "fog"
    static let summary = "height fog, raymarched light shafts through the sun's shadow cascades, per-entity emissive tint/strength"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let sky = Vec3(0.55, 0.42, 0.4)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.32, 0.31, 0.33, 1), checker: true, roughness: 0.8), key: "street")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.2, 0.2, 0.23, 1), roughness: 0.85), key: "building")
        // One white-hot emissive material for every sign: the entities color and scale it.
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.03, 0.03, 0.03, 1), emissiveColor: Vec3(1, 1, 1), emissiveStrength: 1), key: "neon")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 2.2, 22), at: Vec3(0, 3, 0)),
            Camera(fovY: .pi / 3, near: 0.1, far: 300, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: -0.3, bloom: true, bloomIntensity: 0.06))
        _ = world.spawn(
            Name("Environment"),
            SceneEnvironment(skyColor: Vec3(0.45, 0.4, 0.5), groundColor: Vec3(0.12, 0.1, 0.1), ambientIntensity: 0.25,
                             fogColor: Self.sky * 0.5, fogDensity: 0.07, fogHeightFalloff: 0.16, fogBaseHeight: 0,
                             volumetricFog: VolumetricFog(enabled: true, intensity: 0.8, anisotropy: 0.55, maxDistance: 80, steps: 48)))
        // The low sun at the far end of the street, its light travelling toward the camera.
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: normalize(Vec3(0.18, -0.2, 1)))), Name("Sun"),
            DirectionalLight(color: Vec3(1, 0.7, 0.45), intensity: 4, shadowExtent: 40, shadowCenter: Vec3(0, 4, 0)))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3, shadows: Bool = true) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name),
                            MeshRenderer(mesh: .cube, material: MaterialHandle(material), castsShadows: shadows))
        }
        box("Street", "street", center: Vec3(0, -0.5, -5), size: Vec3(60, 1, 90), shadows: false)
        // Two rows of buildings with gaps; a wall across the far end with a gap for the sun.
        for side: Float in [-1, 1] {
            for k in 0..<5 {
                let z = -22 + Float(k) * 9
                let height = 9 + Float((k * 7 + Int(side) * 3 + 10) % 5) * 2.5
                box("Building", "building", center: Vec3(side * 8.5, height / 2, z), size: Vec3(7, height, 6.5))
            }
        }
        box("Far wall left", "building", center: Vec3(-14, 7, -30), size: Vec3(20, 14, 3))
        box("Far wall right", "building", center: Vec3(14, 7, -30), size: Vec3(20, 14, 3))

        // Neon signs on the building fronts: same mesh and material, different color and strength.
        let signs: [(Vec3, Vec3, Float, Vec3)] = [
            (Vec3(1, 0.1, 0.5), Vec3(-4.9, 5.5, 4), 8, Vec3(0.12, 2.2, 0.2)),
            (Vec3(0.1, 0.7, 1), Vec3(4.9, 4.5, -5), 10, Vec3(0.12, 0.25, 3.2)),
            (Vec3(0.3, 1, 0.3), Vec3(-4.9, 3.2, -14), 6, Vec3(0.12, 0.25, 3.5)),
            (Vec3(1, 0.5, 0.05), Vec3(4.9, 6.5, 13), 9, Vec3(0.12, 2, 0.2)),
        ]
        for (color, position, strength, size) in signs {
            _ = world.spawn(
                Transform(position: position, scale: size), Name("Neon sign"),
                MeshRenderer(mesh: .cube, material: MaterialHandle("neon"), castsShadows: false,
                             emissiveTint: color, emissiveStrength: strength))
            _ = world.spawn(Transform(position: position + Vec3(position.x > 0 ? -1.2 : 1.2, 0, 0)), Name("Sign light"),
                            PointLight(color: color, intensity: 14, range: 9))
        }
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.05, distance: 20, target: Vec3(0, 3, 2)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String { "height fog + volumetric sun shafts + emissive overrides" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) { world.update(dt: Double(dt)) }

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
