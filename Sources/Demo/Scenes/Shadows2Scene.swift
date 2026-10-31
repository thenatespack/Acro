import Engine
import Foundation

/// Cascaded shadow maps and point / spot light shadows through `SceneRenderer`: a 600-unit
/// field of rocks, pillars and trees under a low evening sun (four cascades out to 220 units
/// at high quality), and near the camera a lantern (shadowed point light) circling a ring of
/// posts plus two sweeping shadowed spot lights on a plaza of crates. C tints the cascades.
/// Animated by the scene clock, so screenshots are deterministic.
final class Shadows2Scene: DemoScene {
    static let name = "shadows2"
    static let summary = "cascaded shadow maps over a large field, shadowed spot and point lights; C tints cascades"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private let lantern: Entity
    private var spots: [(entity: Entity, position: Vec3, target: Vec3, phase: Float)] = []
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let fogColor = Vec3(0.72, 0.66, 0.62)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.42, 0.45, 0.36, 1), checker: true, roughness: 0.9), key: "ground")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.6, 0.58, 0.55, 1), roughness: 0.8), key: "rock")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.85, 0.82, 0.76, 1), roughness: 0.6), key: "stone")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.3, 0.5, 0.25, 1), roughness: 0.85), key: "leaves")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.45, 0.32, 0.2, 1), roughness: 0.7), key: "wood")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), emissive: 1), key: "bulb")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(14, 5, 22), at: Vec3(0, 1.5, 0)),
            Camera(fovY: .pi / 3.2, near: 0.2, far: 600, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.55, 0.62, 0.8), groundColor: Vec3(0.15, 0.12, 0.1),
                                         ambientIntensity: 0.35, fogColor: Self.fogColor, fogDensity: 0.004))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.6, 0.32, -0.55)))), Name("Sun"),
            DirectionalLight(color: Vec3(1, 0.86, 0.7), intensity: 0.8, shadowMaxDistance: 220))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(600, 1, 600)), Name("Ground"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("ground"), castsShadows: false))

        lantern = world.spawn(
            Transform(position: Vec3(0, 1.4, 0), scale: Vec3(repeating: 0.18)), Name("Lantern"),
            PointLight(color: Vec3(1, 0.75, 0.45), intensity: 14, range: 11, castsShadows: true),
            MeshRenderer(mesh: .sphere, material: MaterialHandle("bulb"), tint: Vec3(1, 0.8, 0.5), castsShadows: false,
                         receivesShadows: false))
        buildField()
        buildPlaza()
        world.propagateTransforms()
    }

    /// Rocks, pillars and trees scattered out to 280 units (denser near the middle).
    private func buildField() {
        var rng = SplitMix64(state: 21)
        for k in 0..<900 {
            let radius = 30 + powf(rng.next(), 1.6) * 250
            let angle = rng.next() * 2 * .pi
            let p = Vec3(cosf(angle) * radius, 0, sinf(angle) * radius)
            switch k % 3 {
            case 0:
                let s = 1 + rng.next() * 3
                _ = world.spawn(
                    Transform(position: p + Vec3(0, s * 0.3, 0), rotation: Quat(angle: rng.next() * .pi, axis: normalize(Vec3(rng.next(), 1, rng.next()))),
                              scale: Vec3(s * 1.4, s, s * 1.1)),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("rock"), tint: Vec3(repeating: 0.8 + rng.next() * 0.3)))
            case 1:
                let h = 4 + rng.next() * 10
                _ = world.spawn(
                    Transform(position: p + Vec3(0, h / 2, 0), scale: Vec3(1, h, 1)),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
            default:
                let h = 3 + rng.next() * 4
                _ = world.spawn(
                    Transform(position: p + Vec3(0, h / 2, 0), scale: Vec3(0.5, h, 0.5)),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("wood")))
                _ = world.spawn(
                    Transform(position: p + Vec3(0, h + 1.2, 0), scale: Vec3(repeating: 3 + rng.next() * 1.5)),
                    MeshRenderer(mesh: .sphere, material: MaterialHandle("leaves"), tint: hsv(0.25 + rng.next() * 0.1, 0.5, 0.9)))
            }
        }
    }

    /// A ring of posts around the lantern, crates, and two spot lights on masts.
    private func buildPlaza() {
        for k in 0..<10 {
            let angle = Float(k) / 10 * 2 * .pi
            _ = world.spawn(
                Transform(position: Vec3(cosf(angle) * 4.5, 1.25, sinf(angle) * 4.5), scale: Vec3(0.4, 2.5, 0.4)),
                Name("Post \(k)"), MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
        }
        var rng = SplitMix64(state: 5)
        for k in 0..<14 {
            let p = Vec3(-12 + rng.next() * 9, 0, -4 + rng.next() * 12)
            let s = 0.8 + rng.next() * 0.8
            _ = world.spawn(
                Transform(position: p + Vec3(0, s / 2, 0), rotation: Quat(angle: rng.next() * .pi, axis: Vec3(0, 1, 0)),
                          scale: Vec3(repeating: s)),
                Name("Crate \(k)"), MeshRenderer(mesh: k % 4 == 0 ? .sphere : .cube, material: MaterialHandle("wood")))
        }
        for (k, (position, target)) in [(Vec3(-15, 8, 9), Vec3(-8, 0, 2)), (Vec3(-4, 8, -8), Vec3(-8, 0, 3))].enumerated() {
            let color = k == 0 ? Vec3(0.6, 0.8, 1) : Vec3(1, 0.55, 0.7)
            let entity = world.spawn(
                Transform.looking(from: position, at: target), Name("Spot \(k)"),
                SpotLight(color: color, intensity: 400, range: 24, innerConeAngle: 0.3, outerConeAngle: 0.42, castsShadows: true))
            spots.append((entity, position, target, Float(k) * 2.1))
            _ = world.spawn(
                Transform(position: position + Vec3(0, -position.y / 2 - 0.3, 0), scale: Vec3(0.25, position.y - 0.6, 0.25)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
            _ = world.spawn(
                Transform(position: position, scale: Vec3(repeating: 0.4)),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("bulb"), tint: color, castsShadows: false, receivesShadows: false))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.9, pitch: 0.3, distance: 30, target: Vec3(-3, 1.5, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var status: String {
        let s = sceneRenderer.stats.shadows, l = sceneRenderer.stats.list
        return "\(s.cascades) cascades, \(s.spotShadows) spot + \(s.pointShadows) point shadows, \(s.tiles) tiles in "
            + "\(s.atlasWidth)x\(s.atlasHeight), \(l.shadowCasters) caster draws\(sceneRenderer.showsShadowCascades ? ", tinted" : "")"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, far: 600)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.c) { sceneRenderer.showsShadowCascades.toggle() }
        let a = time * 0.5
        world.add(Transform(position: Vec3(cosf(a) * 2.2, 1.4 + sinf(a * 1.7) * 0.4, sinf(a) * 2.2), scale: Vec3(repeating: 0.18)),
                  to: lantern)
        for spot in spots {
            let b = time * 0.45 + spot.phase
            world.add(Transform.looking(from: spot.position, at: spot.target + Vec3(cosf(b), 0, sinf(b)) * 3), to: spot.entity)
        }
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
