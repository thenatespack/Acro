import Engine
import Foundation

/// GPU particles (`ParticleEmitter`, simulated in compute, drawn with indirect draws): a fire
/// in a brazier under a column of lit, soft, flipbook-textured smoke (sorted back to front),
/// lit ground mist that fades softly into the floor (16k sorted particles), sparks fountaining
/// off a pillar that bounce off the floor, a stone ball (a sphere collider) and the scene's
/// depth buffer and flash where they hit (a collision sub-emitter), fireworks whose rockets
/// burst on death (a death sub-emitter), and a 128k-particle spiral galaxy orbiting above, at
/// night with bloom.
///
/// Keys: **F** toggles the fire and smoke, **K** the sparks, **G** the galaxy, **M** the mist,
/// **W** the fireworks; **B** fires a burst of sparks. The title shows the live particle count
/// (read back from the GPU) and the GPU time of the `particles` compute pass. Deterministic
/// under `ENGINE_SCREENSHOT`.
final class ParticlesScene: DemoScene {
    static let name = "particles"
    static let summary = "GPU particles: lit soft flipbook smoke, sorted mist, colliding sparks, fireworks sub-emitters, a 128k galaxy"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var fire = Entity.invalid, smoke = Entity.invalid, sparks = Entity.invalid, galaxy = Entity.invalid
    private var mist = Entity.invalid, rockets = Entity.invalid
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
        let smokeAtlas = sceneRenderer.registerTexture(try Self.makeSmokeAtlas(device: renderer.device), key: "smoke-atlas")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 5, 16), at: Vec3(0, 3, -2)),
            Camera(fovY: .pi / 3, near: 0.1, far: 300, clearColor: Vec4(Self.night, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0.5, bloom: true, bloomIntensity: 0.07))
        _ = world.spawn(SceneEnvironment(skyColor: Self.night * 3, groundColor: Vec3(0.02, 0.02, 0.02), ambientIntensity: 0.6))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: normalize(Vec3(-0.4, -0.7, -0.5)))),
            DirectionalLight(color: Vec3(0.55, 0.62, 1), intensity: 0.35, shadowExtent: 14, shadowCenter: Vec3(0, 0, 0)))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3, mesh: MeshHandle = .cube) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name), MeshRenderer(mesh: mesh, material: MaterialHandle(material)))
        }
        box("Floor", "floor", center: Vec3(0, -0.5, 0), size: Vec3(40, 1, 40))
        box("Brazier", "iron", center: Vec3(-4, 0.4, 2), size: Vec3(1.4, 0.8, 1.4))
        box("Embers", "embers", center: Vec3(-4, 0.82, 2), size: Vec3(1.1, 0.06, 1.1))
        box("Pillar", "stone", center: Vec3(4, 1.25, 2), size: Vec3(0.6, 2.5, 0.6))
        // The stone ball the sparks bounce off (a sphere collider of the same radius); the
        // block behind the pillar stops them through the depth buffer.
        let ball = (center: Vec3(5.6, 0.7, 2.6), radius: Float(0.7))
        box("Ball", "stone", center: ball.center, size: Vec3(repeating: ball.radius * 2), mesh: .sphere)
        box("Block", "stone", center: Vec3(4.3, 0.75, -0.6), size: Vec3(2.4, 1.5, 0.8))
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
            intensity: 3.5, brightnessVariation: 0.4, softness: 0.25, seed: 11))
        // Smoke: slow, growing puffs above the flames from a 4x4 flipbook (blended frames),
        // lit by the fire and the moon (with its shadow), soft where they meet the brazier.
        smoke = world.spawn(Transform(position: Vec3(-4, 2.2, 2)), Name("Smoke"), ParticleEmitter(
            capacity: 1024, rate: 45, prewarm: 6, lifetime: Vec2(3.5, 5.5), shape: .sphere, shapeSize: Vec3(0.3, 0.3, 0.3),
            spread: 0.3, speed: Vec2(0.5, 0.9), gravity: Vec3(0.25, 0.5, 0), drag: 0.4, turbulence: 0.8, turbulenceFrequency: 0.5,
            size: Vec2(0.55, 0.85), spin: 0.4,
            sizeOverLife: [ParticleCurveKey(0, 0.5), ParticleCurveKey(1, 2.6)],
            color: [ParticleColorKey(0, Vec4(0.5, 0.48, 0.46, 0)), ParticleColorKey(0.15, Vec4(0.48, 0.46, 0.45, 0.75)),
                    ParticleColorKey(0.6, Vec4(0.42, 0.42, 0.44, 0.5)), ParticleColorKey(1, Vec4(0.4, 0.4, 0.42, 0))],
            brightnessVariation: 0.3, blend: .alpha,
            texture: smokeAtlas, atlasColumns: 4, atlasRows: 4, frameBlending: true, softness: 0.6, lit: true, receivesShadows: true,
            seed: 12))
        // Mist: 16k big, faint, lit puffs drifting over the floor, sorted back to front and
        // faded softly where they cut into it.
        mist = world.spawn(Transform(position: Vec3(0, 0.25, -1)), Name("Mist"), ParticleEmitter(
            capacity: 4096, rate: 450, prewarm: 9, lifetime: Vec2(7, 9), shape: .box, shapeSize: Vec3(10, 0.2, 6),
            spread: .pi, speed: Vec2(0.02, 0.12), gravity: Vec3(0.04, 0, 0), turbulence: 0.05, turbulenceFrequency: 0.3,
            size: Vec2(0.45, 0.75), spin: 0.1,
            sizeOverLife: [ParticleCurveKey(0, 0.6), ParticleCurveKey(1, 1.4)],
            color: [ParticleColorKey(0, Vec4(0.55, 0.6, 0.75, 0)), ParticleColorKey(0.3, Vec4(0.55, 0.6, 0.75, 0.09)),
                    ParticleColorKey(0.7, Vec4(0.55, 0.6, 0.75, 0.09)), ParticleColorKey(1, Vec4(0.55, 0.6, 0.75, 0))],
            blend: .alpha, texture: smokeAtlas, atlasColumns: 4, atlasRows: 4, randomStartFrame: true, softness: 0.8, lit: true,
            seed: 15))
        // Sparks: a fountain off the pillar, streaked along their velocity, bouncing off the
        // floor, the ball and (through the depth buffer) the block; each hit flashes.
        let flashes = world.spawn(Transform(), Name("Spark flashes"), ParticleEmitter(
            capacity: 4096, rate: 0, lifetime: Vec2(0.12, 0.3), shape: .sphere, shapeSize: Vec3(0.03, 0.03, 0.03), spread: .pi,
            speed: Vec2(0.6, 1.6), gravity: Vec3(0, -4, 0), size: Vec2(0.012, 0.025),
            color: [ParticleColorKey(0, Vec4(1, 0.9, 0.6, 1)), ParticleColorKey(1, Vec4(1, 0.35, 0.05, 0))],
            intensity: 14, stretch: 0.04, seed: 16))
        sparks = world.spawn(Transform(position: Vec3(4, 2.55, 2)), Name("Sparks"), ParticleEmitter(
            capacity: 4096, rate: 250, bursts: [ParticleBurst(time: 0.5, count: 160, interval: 1.5, cycles: 0)], prewarm: 2,
            lifetime: Vec2(1.6, 2.6), spread: 0.75, speed: Vec2(3, 7.5), gravity: Vec3(0, -9.81, 0), drag: 0.15,
            size: Vec2(0.025, 0.045),
            color: [ParticleColorKey(0, Vec4(1, 0.95, 0.7, 1)), ParticleColorKey(0.4, Vec4(1, 0.6, 0.15, 1)),
                    ParticleColorKey(1, Vec4(0.8, 0.15, 0.02, 0))],
            intensity: 9, stretch: 0.05, collidesWithGround: true, groundHeight: 0, bounce: 0.45, friction: 0.3,
            collidesWithDepth: true, depthThickness: 0.6, colliders: [.sphere(center: ball.center, radius: ball.radius)],
            subEmitters: [ParticleSubEmitter(.collision, emitter: world.ref(to: flashes), count: 2, inheritVelocity: 0.15)],
            seed: 13))
        // Fireworks: rockets rise, slow and burst on death into a shell of sparks that fall.
        let shells = world.spawn(Transform(), Name("Firework shells"), ParticleEmitter(
            capacity: 16_384, rate: 0, lifetime: Vec2(1.3, 2.1), shape: .sphere, shapeSize: Vec3(0.05, 0.05, 0.05), spread: .pi,
            speed: Vec2(3.2, 3.6), gravity: Vec3(0, -2.5, 0), drag: 1.1, size: Vec2(0.03, 0.05),
            color: [ParticleColorKey(0, Vec4(1, 1, 1, 1)), ParticleColorKey(0.25, Vec4(0.45, 0.85, 1, 1)),
                    ParticleColorKey(0.75, Vec4(0.9, 0.35, 1, 0.8)), ParticleColorKey(1, Vec4(0.6, 0.1, 0.8, 0))],
            intensity: 8, brightnessVariation: 0.5, stretch: 0.06, seed: 17))
        rockets = world.spawn(Transform(position: Vec3(8.5, 0, -6)), Name("Fireworks"), ParticleEmitter(
            capacity: 256, rate: 1.4, prewarm: 3, lifetime: Vec2(1.1, 1.4), spread: 0.18, speed: Vec2(9, 10.5),
            gravity: Vec3(0, -4, 0), size: Vec2(0.04, 0.05),
            color: [ParticleColorKey(0, Vec4(1, 0.8, 0.5, 1)), ParticleColorKey(1, Vec4(1, 0.6, 0.3, 0.6))],
            intensity: 6, stretch: 0.08,
            subEmitters: [ParticleSubEmitter(.death, emitter: world.ref(to: shells), count: 220, inheritVelocity: 0.4)], seed: 18))
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

    /// A 4x4 flipbook of a smoke puff (64x64 cells, row by row): billowing value noise in a soft
    /// disc that grows and thins out over the 16 frames. White, with the density in alpha.
    static func makeSmokeAtlas(device: RenderDevice) throws -> GPUTexture {
        let cell = 64, grid = 4, size = cell * grid
        func hash(_ x: Int, _ y: Int, _ z: Int) -> Float {
            var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ z &* 2_147_483_647)
            h = (h ^ (h >> 13)) &* 1_274_126_177
            return Float((h ^ (h >> 16)) & 0xFFFF) / 65535
        }
        func noise(_ x: Float, _ y: Float, _ z: Int) -> Float {
            let x0 = Int(x.rounded(.down)), y0 = Int(y.rounded(.down))
            let fx = x - Float(x0), fy = y - Float(y0)
            let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
            let a = hash(x0, y0, z) + (hash(x0 + 1, y0, z) - hash(x0, y0, z)) * sx
            let b = hash(x0, y0 + 1, z) + (hash(x0 + 1, y0 + 1, z) - hash(x0, y0 + 1, z)) * sx
            return a + (b - a) * sy
        }
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        for frame in 0..<grid * grid {
            let t = Float(frame) / Float(grid * grid - 1)
            let radius: Float = 0.62 + 0.3 * t, density: Float = 1 - 0.55 * t
            for y in 0..<cell {
                for x in 0..<cell {
                    let u = (Float(x) + 0.5) / Float(cell) * 2 - 1, v = (Float(y) + 0.5) / Float(cell) * 2 - 1
                    let r = (u * u + v * v).squareRoot() / radius
                    var fbm: Float = 0, amplitude: Float = 0.5, frequency: Float = 3
                    for octave in 0..<4 {
                        // The billows drift outward and swirl a little from frame to frame.
                        fbm += amplitude * noise(u * frequency + t * 1.5, v * frequency - t, octave)
                        amplitude *= 0.5
                        frequency *= 2
                    }
                    let disc = max(0, 1 - r * r)
                    let alpha = min(1, max(0, disc * disc * (0.35 + 1.3 * fbm) * density))
                    // Lighter on top, darker below: a hint of volume before the scene's lighting.
                    let shade = 0.78 + 0.22 * (1 - (v * 0.5 + 0.5)) + 0.1 * (fbm - 0.5)
                    let i = (((frame / grid) * cell + y) * size + (frame % grid) * cell + x) * 4
                    let c = UInt8(min(255, max(0, shade * 255)).rounded())
                    pixels[i] = c
                    pixels[i + 1] = c
                    pixels[i + 2] = c
                    pixels[i + 3] = UInt8((alpha * 255).rounded())
                }
            }
        }
        return try device.makeTexture(pixels: pixels, width: size, height: size, format: .rgba8Unorm, generateMipmaps: true)
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.18, distance: 17, target: Vec3(0, 3, -2)) }
    var lighting: Lighting { Lighting(fogColor: Self.night) }

    var status: String {
        let stats = sceneRenderer.particles?.stats ?? ParticleSystem.Stats()
        var text = "\(stats.aliveParticles) particles of \(stats.capacity), compute "
        text += computeTime.map { String(format: "%.2f ms", $0 * 1000) } ?? "-"
        func flag(_ entity: Entity) -> String { world.get(ParticleEmitter.self, for: entity)?.isEmitting == true ? "on" : "off" }
        return text + ", fire \(flag(fire)) [F], sparks \(flag(sparks)) [K], galaxy \(flag(galaxy)) [G], mist \(flag(mist)) [M], "
            + "fireworks \(flag(rockets)) [W], burst [B]"
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
        if input.wasPressed(.m) { toggle(mist) }
        if input.wasPressed(.w) { toggle(rockets) }
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
