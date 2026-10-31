import Engine
import Foundation

/// GPU particles (`ParticleEmitter`, simulated in compute, drawn with indirect draws): a fire
/// in a brazier under a column of sorted, alpha-blended smoke, sparks fountaining off a pillar
/// and bouncing on the floor, and a spiral galaxy of 128k additive particles orbiting above,
/// at night with bloom.
///
/// Keys: **F** toggles the fire and smoke, **K** the sparks, **G** the galaxy; **B** fires a
/// burst of sparks. The title shows the live particle count (read back from the GPU) and the
/// GPU time of the `particles` compute pass. Deterministic under `ENGINE_SCREENSHOT`.
final class ParticlesScene: DemoScene {
    static let name = "particles"
    static let summary = "GPU particles: fire and sorted smoke, bouncing sparks, a 128k-particle galaxy, bloom, compute + indirect draws"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var fire = Entity.invalid, smoke = Entity.invalid, sparks = Entity.invalid, galaxy = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    /// From the engine, for the title.
    private var computeTime: Double?
    private static let night = Vec3(0.012, 0.014, 0.03)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let materials: [(String, Material)] = [
            ("floor", Material(baseColor: Vec4(0.32, 0.3, 0.28, 1), checker: true, roughness: 0.8)),
            ("iron", Material(baseColor: Vec4(0.25, 0.24, 0.23, 1), metallic: 1, roughness: 0.55)),
            ("stone", Material(baseColor: Vec4(0.45, 0.43, 0.4, 1), roughness: 0.9)),
            ("embers", Material(baseColor: Vec4(0.05, 0.02, 0.01, 1), emissiveColor: Vec3(1, 0.35, 0.08), emissiveStrength: 6)),
        ]
        for (key, material) in materials { try sceneRenderer.registerMaterial(material, key: key) }

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 5, 16), at: Vec3(0, 3, -2)),
            Camera(fovY: .pi / 3, near: 0.1, far: 300, clearColor: Vec4(Self.night, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0.5, bloom: true, bloomIntensity: 0.07))
        _ = world.spawn(SceneEnvironment(skyColor: Self.night * 3, groundColor: Vec3(0.02, 0.02, 0.02), ambientIntensity: 0.6))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: normalize(Vec3(-0.4, -0.7, -0.5)))),
            DirectionalLight(color: Vec3(0.55, 0.62, 1), intensity: 0.35, shadowExtent: 14, shadowCenter: Vec3(0, 0, 0)))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name), MeshRenderer(mesh: .cube, material: MaterialHandle(material)))
        }
        box("Floor", "floor", center: Vec3(0, -0.5, 0), size: Vec3(40, 1, 40))
        box("Brazier", "iron", center: Vec3(-4, 0.4, 2), size: Vec3(1.4, 0.8, 1.4))
        box("Embers", "embers", center: Vec3(-4, 0.82, 2), size: Vec3(1.1, 0.06, 1.1))
        box("Pillar", "stone", center: Vec3(4, 1.25, 2), size: Vec3(0.6, 2.5, 0.6))
        _ = world.spawn(Transform(position: Vec3(-4, 1.6, 2)), Name("Fire light"),
                        PointLight(color: Vec3(1, 0.55, 0.2), intensity: 9, range: 12))
        _ = world.spawn(Transform(position: Vec3(4, 2.9, 2)), Name("Spark light"),
                        PointLight(color: Vec3(1, 0.7, 0.35), intensity: 2, range: 6))

        // Fire: hot at birth, cooling to red and fading, rising with buoyancy and swirling.
        fire = world.spawn(Transform(position: Vec3(-4, 0.95, 2)), Name("Fire"), ParticleEmitter(
            capacity: 2048, rate: 700, prewarm: 2, lifetime: Vec2(0.5, 1.1), shape: .sphere, shapeSize: Vec3(0.4, 0.4, 0.4),
            spread: 0.35, speed: Vec2(0.6, 1.4), gravity: Vec3(0, 2.2, 0), drag: 0.8, turbulence: 4, turbulenceFrequency: 1.6,
            size: Vec2(0.22, 0.38), spin: 2,
            sizeOverLife: [ParticleCurveKey(0, 0.7), ParticleCurveKey(0.25, 1), ParticleCurveKey(1, 0.25)],
            color: [ParticleColorKey(0, Vec4(1, 0.85, 0.45, 0.9)), ParticleColorKey(0.3, Vec4(1, 0.42, 0.1, 0.8)),
                    ParticleColorKey(0.7, Vec4(0.7, 0.12, 0.02, 0.45)), ParticleColorKey(1, Vec4(0.2, 0.03, 0, 0))],
            intensity: 3.5, brightnessVariation: 0.4, seed: 11))
        // Smoke: slow, growing gray puffs above the flames, sorted back to front.
        smoke = world.spawn(Transform(position: Vec3(-4, 2.2, 2)), Name("Smoke"), ParticleEmitter(
            capacity: 1024, rate: 45, prewarm: 6, lifetime: Vec2(3.5, 5.5), shape: .sphere, shapeSize: Vec3(0.3, 0.3, 0.3),
            spread: 0.3, speed: Vec2(0.5, 0.9), gravity: Vec3(0.25, 0.5, 0), drag: 0.4, turbulence: 0.8, turbulenceFrequency: 0.5,
            size: Vec2(0.45, 0.7), spin: 0.4,
            sizeOverLife: [ParticleCurveKey(0, 0.5), ParticleCurveKey(1, 2.6)],
            color: [ParticleColorKey(0, Vec4(0.16, 0.15, 0.14, 0)), ParticleColorKey(0.15, Vec4(0.15, 0.14, 0.14, 0.55)),
                    ParticleColorKey(0.6, Vec4(0.12, 0.12, 0.13, 0.35)), ParticleColorKey(1, Vec4(0.1, 0.1, 0.11, 0))],
            brightnessVariation: 0.3, blend: .alpha, seed: 12))
        // Sparks: a fountain off the pillar, streaked along their velocity, bouncing on the floor;
        // a bigger burst every 1.5 s.
        sparks = world.spawn(Transform(position: Vec3(4, 2.55, 2)), Name("Sparks"), ParticleEmitter(
            capacity: 4096, rate: 250, bursts: [ParticleBurst(time: 0.5, count: 160, interval: 1.5, cycles: 0)], prewarm: 2,
            lifetime: Vec2(1.6, 2.6), spread: 0.75, speed: Vec2(3, 7.5), gravity: Vec3(0, -9.81, 0), drag: 0.15,
            size: Vec2(0.025, 0.045),
            color: [ParticleColorKey(0, Vec4(1, 0.95, 0.7, 1)), ParticleColorKey(0.4, Vec4(1, 0.6, 0.15, 1)),
                    ParticleColorKey(1, Vec4(0.8, 0.15, 0.02, 0))],
            intensity: 9, stretch: 0.05, collidesWithGround: true, groundHeight: 0, bounce: 0.45, friction: 0.3, seed: 13))
        // Galaxy: a tilted disc with three spiral arms, orbiting its center (128k slots).
        galaxy = world.spawn(
            Transform(position: Vec3(0, 7, -9), rotation: Quat(angle: 0.45, axis: normalize(Vec3(1, 0, 0.25)))), Name("Galaxy"),
            ParticleEmitter(
                capacity: 131_072, rate: 15_000, prewarm: 9, lifetime: Vec2(6, 9), shape: .disc, shapeSize: Vec3(6.5, 0.35, 0),
                spread: .pi, speed: Vec2(0, 0.08), attraction: 2.2, orbit: 1, spiralArms: 3, spiralTwist: 0.5, armWidth: 0.5,
                size: Vec2(0.012, 0.035),
                color: [ParticleColorKey(0, Vec4(0.55, 0.65, 1, 0)), ParticleColorKey(0.1, Vec4(0.7, 0.8, 1, 0.9)),
                        ParticleColorKey(0.6, Vec4(1, 0.55, 0.85, 0.8)), ParticleColorKey(1, Vec4(1, 0.45, 0.25, 0))],
                intensity: 1.2, brightnessVariation: 0.8, seed: 14))
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.18, distance: 17, target: Vec3(0, 3, -2)) }
    var lighting: Lighting { Lighting(fogColor: Self.night) }

    var status: String {
        let stats = sceneRenderer.particles?.stats ?? ParticleSystem.Stats()
        var text = "\(stats.aliveParticles) particles of \(stats.capacity), compute "
        text += computeTime.map { String(format: "%.2f ms", $0 * 1000) } ?? "-"
        func flag(_ entity: Entity) -> String { world.get(ParticleEmitter.self, for: entity)?.isEmitting == true ? "on" : "off" }
        return text + ", fire \(flag(fire)) [F], sparks \(flag(sparks)) [K], galaxy \(flag(galaxy)) [G], burst [B]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(engine: Engine, dt: Float, time: Float) {
        let input = engine.input
        func toggle(_ entities: Entity...) {
            for entity in entities { world.modify(ParticleEmitter.self, for: entity) { $0.isEmitting.toggle() } }
        }
        if input.wasPressed(.f) { toggle(fire, smoke) }
        if input.wasPressed(.k) { toggle(sparks) }
        if input.wasPressed(.g) { toggle(galaxy) }
        if input.wasPressed(.b) { sceneRenderer.particles?.burst(400, from: sparks) }
        computeTime = engine.stats.gpuPassTimes.first { $0.name == "particles" }?.seconds
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
