import Engine
import Foundation

/// Moves a light (and its marker) around a circle: angle = speed * time + phase, bobbing.
struct LightOrbit: Component, Codable, Sendable {
    var center: Vec3
    var radius: Float
    var speed: Float
    var phase: Float
    var bob: Float
}

/// Swings a spot light's aim around a circle on the floor.
struct SpotSweep: Component, Codable, Sendable {
    var position: Vec3
    var target: Vec3
    var radius: Float
    var speed: Float
    var phase: Float
}

/// Many point and spot lights through `SceneRenderer`'s clustered forward shading: a dim
/// night floor with pillars, spheres and blocks, lit by a few hundred colored point lights
/// circling at different heights (each with a small unlit marker) and four sweeping spot
/// lights, plus a faint moon for shadows. Animated by the scene clock, so screenshots
/// (fixed 1/60 s steps) are deterministic.
final class LightsScene: DemoScene {
    static let name = "lights"
    static let summary = "clustered forward: 320 moving point lights + 4 spot lights on PBR and Blinn-Phong props"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let clearColor = Vec3(0.012, 0.014, 0.022)
    static let pointLightCount = 320

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMesh(.sphere(radius: 0.5, segments: 48, rings: 24), key: "sphere-hi")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.5, 0.5, 0.5, 1), checker: true, roughness: 0.55), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.8, 0.78, 0.74, 1), roughness: 0.7), key: "stone")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.95, 0.93, 0.88, 1), metallic: 1, roughness: 0.25), key: "metal")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.9, 0.9, 0.9, 1), roughness: 0.15), key: "gloss")
        try sceneRenderer.registerMaterial(
            Material(shading: .blinnPhong, baseColor: Vec4(0.85, 0.85, 0.85, 1), specular: 0.6, shininess: 48), key: "phong")
        // Light markers: unlit, so they show their tint (the light's color) at full brightness.
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), emissive: 1), key: "bulb")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.7, 0.85, 1, 1), roughness: 0.1, alphaMode: .blend), key: "glass")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(18, 14, 22), at: Vec3(0, 1, 0)),
            Camera(fovY: .pi / 3.5, near: 0.1, far: 200, clearColor: Vec4(Self.clearColor, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.3, 0.38, 0.6), groundColor: Vec3(0.06, 0.05, 0.05),
                                         ambientIntensity: 0.06, fogColor: Self.clearColor, fogDensity: 0.01))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.4, 0.8, 0.3)))), Name("Moon"),
            DirectionalLight(color: Vec3(0.6, 0.7, 1), intensity: 0.12, shadowExtent: 22, shadowCenter: Vec3(0, 1, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(48, 1, 48)), Name("Floor"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))

        buildProps()
        buildPointLights()
        buildSpotLights()
        world.propagateTransforms()
    }

    /// A ring of pillars, a grid of spheres and blocks in four materials, and a glass pane.
    private func buildProps() {
        var rng = SplitMix64(state: 11)
        for k in 0..<10 {
            let angle = Float(k) / 10 * 2 * .pi
            _ = world.spawn(
                Transform(position: Vec3(cosf(angle) * 13, 2.5, sinf(angle) * 13), scale: Vec3(1.2, 5, 1.2)),
                Name("Pillar \(k)"), MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
        }
        let materials = ["stone", "metal", "gloss", "phong"].map(MaterialHandle.init)
        for gz in 0..<5 {
            for gx in 0..<5 {
                let p = Vec2(Float(gx) - 2, Float(gz) - 2) * 4.2
                let i = gx + gz * 5
                let sphere = i % 2 == 0
                let size = 1.1 + rng.next() * 0.8
                _ = world.spawn(
                    Transform(position: Vec3(p.x, size / 2, p.y), rotation: Quat(angle: rng.next() * .pi, axis: Vec3(0, 1, 0)),
                              scale: sphere ? Vec3(repeating: size) : Vec3(size, size * 0.6, size)),
                    MeshRenderer(mesh: sphere ? MeshHandle("sphere-hi") : .cube, material: materials[(i / 2) % 4]))
            }
        }
        _ = world.spawn(
            Transform(position: Vec3(0, 1.6, 10.5), scale: Vec3(6, 3.2, 0.12)), Name("Glass"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("glass"), opacity: 0.4, castsShadows: false))
    }

    /// Point lights on circles around the scene, low over the floor, in all hues.
    private func buildPointLights() {
        var rng = SplitMix64(state: 3)
        for k in 0..<Self.pointLightCount {
            let center = Vec3((rng.next() - 0.5) * 34, 0.35 + rng.next() * 1.6, (rng.next() - 0.5) * 34)
            let color = hsv(rng.next(), 0.75, 1)
            _ = world.spawn(
                Transform(position: center, scale: Vec3(repeating: 0.12)), Name("Point light \(k)"),
                PointLight(color: color, intensity: 0.7 + rng.next() * 0.8, range: 2.5 + rng.next() * 1.5),
                LightOrbit(center: center, radius: 0.8 + rng.next() * 2.5, speed: (rng.next() - 0.5) * 1.6,
                           phase: rng.next() * 2 * .pi, bob: rng.next() * 0.3),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("bulb"), tint: color, castsShadows: false,
                             receivesShadows: false))
        }
    }

    /// Four warm spot lights high above the corners, sweeping over the floor.
    private func buildSpotLights() {
        for k in 0..<4 {
            let angle = Float(k) / 4 * 2 * .pi + .pi / 4
            let position = Vec3(cosf(angle) * 15, 9, sinf(angle) * 15)
            let target = Vec3(cosf(angle) * 4, 0, sinf(angle) * 4)
            _ = world.spawn(
                Transform.looking(from: position, at: target), Name("Spot light \(k)"),
                SpotLight(color: hsv(Float(k) * 0.07 + 0.05, 0.35, 1), intensity: 160, range: 26,
                          innerConeAngle: 0.18, outerConeAngle: 0.28),
                SpotSweep(position: position, target: target, radius: 4, speed: 0.4 + Float(k) * 0.1, phase: Float(k) * 1.7))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.65, pitch: 0.55, distance: 30, target: Vec3(0, 1, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.clearColor) }
    var status: String {
        let s = sceneRenderer.stats.list, l = sceneRenderer.stats.lights
        return "\(l.lights) lights visible, \(l.references) cluster refs (max \(l.maxClusterLights)/cluster, \(l.droppedReferences) dropped), "
            + "\(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
        world.queryMutating(Transform.self, LightOrbit.self) { _, transform, orbit in
            let a = orbit.speed * time + orbit.phase
            transform.position = orbit.center + Vec3(cosf(a) * orbit.radius, sinf(a * 2.3) * orbit.bob, sinf(a) * orbit.radius)
        }
        world.queryMutating(Transform.self, SpotSweep.self) { _, transform, sweep in
            let a = sweep.speed * time + sweep.phase
            let aim = sweep.target + Vec3(cosf(a), 0, sinf(a)) * sweep.radius
            transform = .looking(from: sweep.position, at: aim)
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
