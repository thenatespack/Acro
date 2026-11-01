import Engine
import Foundation

/// A rainy neon street at night: ~3.5k streaked raindrops (`stretchMode: .streak`: a drop's streak
/// is its speed × `stretch` seconds long, like a motion-blur exposure) that die on the wet road
/// (`collidesWithGround` + `killOnCollision`) and spawn a splash from a collision sub-emitter
/// where they land, under a magenta and a cyan point light with bloom.
///
/// Keys: **R** toggles the rain, **S** switches its streaks between `.streak` and the original
/// `.scaled` (size × (1 + stretch × speed): dots at this size). Deterministic under
/// `ENGINE_SCREENSHOT`.
final class RainScene: DemoScene {
    static let name = "rain"
    static let summary = "Rainy neon street: streaked rain (stretchMode .streak), ground splashes from collision sub-emitters, colored lights, bloom"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var rain = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let night = Vec3(0.004, 0.005, 0.014)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let materials: [(String, Material)] = [
            ("road", Material(baseColor: Vec4(0.05, 0.05, 0.06, 1), roughness: 0.25)),
            ("wall", Material(baseColor: Vec4(0.07, 0.07, 0.09, 1), roughness: 0.7)),
            ("magenta", Material(baseColor: Vec4(0.02, 0, 0.02, 1), emissiveColor: Vec3(1, 0.1, 0.7), emissiveStrength: 8)),
            ("cyan", Material(baseColor: Vec4(0, 0.02, 0.02, 1), emissiveColor: Vec3(0.1, 0.9, 1), emissiveStrength: 8)),
            ("amber", Material(baseColor: Vec4(0.02, 0.01, 0, 1), emissiveColor: Vec3(1, 0.55, 0.12), emissiveStrength: 5)),
        ]
        for (key, material) in materials { try sceneRenderer.registerMaterial(material, key: key) }

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 1.7, 9), at: Vec3(0, 2.4, 0)),
            Camera(fovY: .pi / 3, near: 0.1, far: 200, clearColor: Vec4(Self.night, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0.8, bloom: true, bloomIntensity: 0.12))
        _ = world.spawn(SceneEnvironment(skyColor: Self.night * 4, groundColor: Vec3(0.004, 0.004, 0.006), ambientIntensity: 0.5))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name), MeshRenderer(mesh: .cube, material: MaterialHandle(material)))
        }
        box("Road", "road", center: Vec3(0, -0.5, 0), size: Vec3(40, 1, 40))
        box("Left building", "wall", center: Vec3(-6.5, 5, -2), size: Vec3(4, 10, 24))
        box("Right building", "wall", center: Vec3(6.5, 5, -2), size: Vec3(4, 10, 24))
        box("End wall", "wall", center: Vec3(0, 5, -14), size: Vec3(20, 10, 1))
        // Neon signs on the facades.
        box("Sign A", "magenta", center: Vec3(-4.45, 3.4, -1), size: Vec3(0.1, 0.35, 5))
        box("Sign B", "cyan", center: Vec3(4.45, 2.6, -4), size: Vec3(0.1, 0.35, 6))
        box("Sign C", "amber", center: Vec3(-4.45, 1.5, -6), size: Vec3(0.1, 1.2, 0.3))
        box("Sign D", "cyan", center: Vec3(-4.45, 5.2, -7), size: Vec3(0.1, 2.2, 0.3))
        box("Sign E", "magenta", center: Vec3(4.45, 4.8, 0), size: Vec3(0.1, 0.3, 3))
        _ = world.spawn(Transform(position: Vec3(-3.2, 3.2, -1)), Name("Magenta light"),
                        PointLight(color: Vec3(1, 0.12, 0.7), intensity: 30, range: 14))
        _ = world.spawn(Transform(position: Vec3(3.2, 2.6, -4)), Name("Cyan light"),
                        PointLight(color: Vec3(0.1, 0.8, 1), intensity: 30, range: 14))

        // Splashes: a tiny crown of droplets thrown up from where a drop lands (the sub-emitter
        // spawns them at the collision point, inheriting a little of the drop's velocity).
        let splashes = world.spawn(Transform(), Name("Splashes"), ParticleEmitter(
            capacity: 16_384, rate: 0, lifetime: Vec2(0.15, 0.32), spread: 1.0, speed: Vec2(0.7, 1.8),
            gravity: Vec3(0, -9.81, 0), size: Vec2(0.008, 0.016),
            color: [ParticleColorKey(0, Vec4(0.75, 0.85, 1, 0.9)), ParticleColorKey(1, Vec4(0.5, 0.6, 1, 0))],
            intensity: 3, stretch: 0.04, stretchMode: .streak, seed: 31))
        // Rain: ~18 m/s drops from a sheet 12 m up that die on the road; stretch 0.07 s makes
        // each a ~1.3 m streak (speed × stretch).
        rain = world.spawn(Transform(position: Vec3(0, 12, -2)), Name("Rain"), ParticleEmitter(
            capacity: 16_384, rate: 3000, prewarm: 1.5, lifetime: Vec2(1.2, 1.4), shape: .box, shapeSize: Vec3(4.2, 0.05, 11),
            direction: Vec3(0.04, -1, 0.02), spread: 0.015, speed: Vec2(16, 20), size: Vec2(0.005, 0.008),
            color: [ParticleColorKey(0, Vec4(0.6, 0.7, 1, 0.35)), ParticleColorKey(1, Vec4(0.6, 0.7, 1, 0.35))],
            intensity: 2.5, brightnessVariation: 0.5, stretch: 0.07, stretchMode: .streak,
            collidesWithGround: true, groundHeight: 0, killOnCollision: true,
            subEmitters: [ParticleSubEmitter(.collision, emitter: world.ref(to: splashes), count: 3, inheritVelocity: 0.02)],
            seed: 30))
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.05, distance: 9, target: Vec3(0, 2.4, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.night) }

    var status: String {
        let stats = sceneRenderer.particles?.stats ?? ParticleSystem.Stats()
        let emitter = world.get(ParticleEmitter.self, for: rain)
        return "\(stats.aliveParticles) particles, rain \(emitter?.isEmitting == true ? "on" : "off") [R], stretch \(emitter?.stretchMode.rawValue ?? "") [S]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(engine: Engine, dt: Float, time: Float) {
        if engine.input.wasPressed(.r) { world.modify(ParticleEmitter.self, for: rain) { $0.isEmitting.toggle() } }
        if engine.input.wasPressed(.s) {
            world.modify(ParticleEmitter.self, for: rain) { $0.stretchMode = $0.stretchMode == .streak ? .scaled : .streak }
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
