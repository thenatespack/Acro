import Engine
import Foundation

/// Decals (`Decal`): projector boxes that paint a texture onto the opaque geometry inside them.
/// A night wall and road lit by neon: a magenta burst of graffiti that crosses from the wall
/// onto a crate in front of it (the box reaches both surfaces), a glowing cyan ring (emissive,
/// blooming), streaky grime under the roof line, dark glossy puddles on the road that mirror the
/// neon (low roughness) and a patch of oil, plus a glass pane and a glass cube that decals never
/// paint (they draw after the decals). **G** toggles every decal, to compare with the bare
/// surfaces; **B** shows the projector boxes. Textures are generated in code.
final class DecalsScene: DemoScene {
    static let name = "decals"
    static let summary = "decal projector boxes: graffiti across surfaces, emissive neon, grime, glossy puddles, not on glass"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var decals: [Entity] = []
    private var orbit: (eye: Vec3, target: Vec3)?
    private var shown = true
    private var boxes = false
    private static let night = Vec3(0.01, 0.012, 0.03)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let device = renderer.device
        let materials: [(String, Material)] = [
            ("road", Material(baseColor: Vec4(0.16, 0.16, 0.17, 1), roughness: 0.85)),
            ("wall", Material(baseColor: Vec4(0.34, 0.31, 0.3, 1), roughness: 0.9)),
            ("crate", Material(baseColor: Vec4(0.3, 0.2, 0.12, 1), roughness: 0.7)),
            ("glass", Material(baseColor: Vec4(0.5, 0.7, 0.9, 0.18), roughness: 0.05, alphaMode: .blend)),
            ("tube-pink", Material(baseColor: Vec4(0.05, 0.02, 0.04, 1), emissiveColor: Vec3(1, 0.1, 0.55), emissiveStrength: 5)),
            ("tube-cyan", Material(baseColor: Vec4(0.02, 0.04, 0.05, 1), emissiveColor: Vec3(0.1, 0.8, 1), emissiveStrength: 5)),
        ]
        for (key, material) in materials { try sceneRenderer.registerMaterial(material, key: key) }
        let burst = sceneRenderer.registerTexture(try Self.makeBurst(device: device), key: "decal-burst")
        let ring = sceneRenderer.registerTexture(try Self.makeRing(device: device), key: "decal-ring")
        let grime = sceneRenderer.registerTexture(try Self.makeGrime(device: device), key: "decal-grime")
        let puddle = sceneRenderer.registerTexture(try Self.makePuddle(device: device), key: "decal-puddle")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 3, 10), at: Vec3(0, 1.8, -3)),
            Camera(fovY: .pi / 3, near: 0.1, far: 200, clearColor: Vec4(Self.night, 1)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .aces, exposure: 0.8, bloom: true, bloomIntensity: 0.12))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.05, 0.06, 0.12), groundColor: Vec3(0.015, 0.015, 0.02), ambientIntensity: 0.6))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: normalize(Vec3(-0.35, -0.6, -0.7)))),
            DirectionalLight(color: Vec3(0.5, 0.6, 1), intensity: 0.4, shadowExtent: 16, shadowCenter: Vec3(0, 0, -2)))

        func box(_ name: String, _ material: String, center: Vec3, size: Vec3, mesh: MeshHandle = .cube) {
            _ = world.spawn(Transform(position: center, scale: size), Name(name), MeshRenderer(mesh: mesh, material: MaterialHandle(material)))
        }
        box("Road", "road", center: Vec3(0, -0.5, -2), size: Vec3(40, 1, 30))
        box("Wall", "wall", center: Vec3(0, 3.5, -4.5), size: Vec3(20, 7, 1))
        box("Crate", "crate", center: Vec3(3.2, 0.9, -2.6), size: Vec3(1.8, 1.8, 1.2))
        box("Neon tube", "tube-pink", center: Vec3(-5.5, 5.4, -3.9), size: Vec3(4, 0.12, 0.12))
        box("Neon tube", "tube-cyan", center: Vec3(5.5, 5.4, -3.9), size: Vec3(4, 0.12, 0.12))
        // Glass the decals must not paint: a pane over the left graffiti and a cube over a puddle.
        box("Glass pane", "glass", center: Vec3(-3.4, 1.6, -2.2), size: Vec3(2.6, 3.2, 0.06))
        box("Glass cube", "glass", center: Vec3(-1.4, 0.45, 1.2), size: Vec3(0.9, 0.9, 0.9))
        _ = world.spawn(Transform(position: Vec3(-5.5, 4.6, -2.6)), Name("Pink light"),
                        PointLight(color: Vec3(1, 0.12, 0.55), intensity: 40, range: 14))
        _ = world.spawn(Transform(position: Vec3(5.5, 4.6, -2.6)), Name("Cyan light"),
                        PointLight(color: Vec3(0.1, 0.75, 1), intensity: 40, range: 14))

        func decal(_ name: String, at position: Vec3, size: Vec3, rotation: Quat = .identity, _ decal: Decal) {
            decals.append(world.spawn(Transform(position: position, rotation: rotation, scale: size), Name(name), decal))
        }
        // Wall graffiti, projected along -Z. The first is deep enough to reach the crate in front
        // of the wall as well as the wall behind it.
        decal("Burst on wall and crate", at: Vec3(3.2, 2.0, -2.9), size: Vec3(4.2, 4.2, 3.4),
              Decal(texture: burst, tint: Vec3(1, 0.1, 0.55), opacity: 0.95, roughness: 0.6, sortOrder: 1))
        decal("Burst", at: Vec3(-3.4, 2.2, -3.6), size: Vec3(3.2, 3.2, 1.4),
              Decal(texture: burst, tint: Vec3(0.2, 0.9, 0.35), opacity: 0.9, roughness: 0.6, sortOrder: 0))
        decal("Neon ring", at: Vec3(0, 3.3, -3.6), size: Vec3(2.6, 2.6, 1.4),
              Decal(texture: ring, tint: Vec3(0.1, 0.8, 1), emissive: 4, roughness: 0.5, sortOrder: 2))
        decal("Grime", at: Vec3(0, 3.2, -3.6), size: Vec3(18, 6, 1.4),
              Decal(texture: grime, tint: Vec3(0.02, 0.02, 0.025), opacity: 0.85, roughness: 0.95, angleFade: 0.3, sortOrder: -1))
        // Road puddles: boxes turned to project straight down (forward -Z becomes -Y).
        let down = Quat(angle: -.pi / 2, axis: Vec3(1, 0, 0))
        decal("Puddle", at: Vec3(-1.2, 0, 1.0), size: Vec3(5, 3.6, 1),
              rotation: Quat(angle: 0.4, axis: Vec3(0, 1, 0)) * down,
              Decal(texture: puddle, tint: Vec3(0.012, 0.014, 0.02), opacity: 0.9, roughness: 0.04, sortOrder: 0))
        decal("Puddle", at: Vec3(3.4, 0, 2.4), size: Vec3(3.2, 2.4, 1),
              rotation: Quat(angle: -0.7, axis: Vec3(0, 1, 0)) * down,
              Decal(texture: puddle, tint: Vec3(0.012, 0.014, 0.02), opacity: 0.9, roughness: 0.04, sortOrder: 0))
        decal("Oil", at: Vec3(-6, 0, -0.5), size: Vec3(3, 2.2, 1), rotation: down,
              Decal(texture: puddle, tint: Vec3(0.2, 0.05, 0.3), opacity: 0.6, roughness: 0.15, sortOrder: 1))
        world.propagateTransforms()
    }

    // MARK: - Textures

    private static func hash(_ x: Int, _ y: Int, _ z: Int) -> Float {
        var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ z &* 2_147_483_647)
        h = (h ^ (h >> 13)) &* 1_274_126_177
        return Float((h ^ (h >> 16)) & 0xFFFF) / 65535
    }

    private static func noise(_ x: Float, _ y: Float, _ z: Int = 0) -> Float {
        let x0 = Int(x.rounded(.down)), y0 = Int(y.rounded(.down))
        let fx = x - Float(x0), fy = y - Float(y0)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        let a = hash(x0, y0, z) + (hash(x0 + 1, y0, z) - hash(x0, y0, z)) * sx
        let b = hash(x0, y0 + 1, z) + (hash(x0 + 1, y0 + 1, z) - hash(x0, y0 + 1, z)) * sx
        return a + (b - a) * sy
    }

    private static func fbm(_ x: Float, _ y: Float) -> Float {
        var sum: Float = 0, amplitude: Float = 0.5, frequency: Float = 1
        for octave in 0..<5 {
            sum += amplitude * noise(x * frequency, y * frequency, octave)
            amplitude *= 0.5
            frequency *= 2
        }
        return sum
    }

    /// A white image whose alpha is `alpha(u, v)` (u, v in -1...1, v down).
    private static func makeMask(device: RenderDevice, size: Int, _ alpha: (Float, Float) -> Float) throws -> GPUTexture {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let u = (Float(x) + 0.5) / Float(size) * 2 - 1, v = (Float(y) + 0.5) / Float(size) * 2 - 1
                pixels[(y * size + x) * 4 + 3] = UInt8((min(max(alpha(u, v), 0), 1) * 255).rounded())
            }
        }
        return try device.makeTexture(pixels: pixels, width: size, height: size, format: .rgba8Srgb, generateMipmaps: true)
    }

    private static func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// A spiky splat: a noisy disc with spikes (a spray-painted tag), and a hole in the middle.
    static func makeBurst(device: RenderDevice) throws -> GPUTexture {
        try makeMask(device: device, size: 256) { u, v in
            let r = (u * u + v * v).squareRoot(), angle = atan2f(v, u)
            let spikes = 0.55 + 0.35 * abs(sinf(angle * 4.5 + 0.6)) * abs(sinf(angle * 2 + 1)) + 0.12 * fbm(u * 3 + 5, v * 3)
            let body = 1 - smooth(spikes - 0.06, spikes, r)
            let hole = smooth(0.1, 0.16, r)
            let drips = smooth(0.35, 0.5, fbm(u * 6, v * 1.2)) * smooth(-0.1, 0.9, v) * (1 - smooth(0.9, 1, v)) * (abs(u) < 0.5 ? 1 : 0)
            return max(body * hole, drips * 0.8 * smooth(0.5, 0.7, abs(sinf(u * 14))))
        }
    }

    /// A thin ring with a break in it (a painted neon circle).
    static func makeRing(device: RenderDevice) throws -> GPUTexture {
        try makeMask(device: device, size: 256) { u, v in
            let r = (u * u + v * v).squareRoot(), angle = atan2f(v, u)
            let ring = 1 - smooth(0.04, 0.09, abs(r - 0.82))
            let gap = smooth(0.2, 0.35, abs(angle - 0.8))
            let inner = 1 - smooth(0.02, 0.06, abs(r - 0.55))
            return max(ring * gap, inner * smooth(0.2, 0.35, abs(angle + 1.6)))
        }
    }

    /// Vertical streaks that fade out downward from the top edge (rain-stained wall).
    static func makeGrime(device: RenderDevice) throws -> GPUTexture {
        try makeMask(device: device, size: 512) { u, v in
            let streak = fbm(u * 28, v * 1.4 + 3)
            let length = 0.55 + 0.45 * fbm(u * 9 + 17, 4)
            let top = 1 - smooth(-1, -1 + 2 * length, v)
            return smooth(0.3, 0.75, streak) * top * (1 - smooth(0.8, 1, abs(u)))
        }
    }

    /// An irregular blob with soft edges (a puddle).
    static func makePuddle(device: RenderDevice) throws -> GPUTexture {
        try makeMask(device: device, size: 256) { u, v in
            let r = (u * u + v * v).squareRoot(), angle = atan2f(v, u)
            let edge = 0.62 + 0.28 * fbm(cosf(angle) * 1.3 + 8, sinf(angle) * 1.3 + 8) + 0.1 * fbm(u * 2, v * 2)
            return 1 - smooth(edge - 0.1, edge, r)
        }
    }

    // MARK: - Scene

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.2, distance: 12, target: Vec3(0, 1.8, -3)) }
    var lighting: Lighting { Lighting(fogColor: Self.night) }

    var status: String { "decals \(shown ? "on" : "off") [G], boxes \(boxes ? "on" : "off") [B]" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(engine: Engine, dt: Float, time: Float) {
        let input = engine.input
        if input.wasPressed(.g) {
            shown.toggle()
            for entity in decals { world.modify(Decal.self, for: entity) { $0.isVisible = shown } }
        }
        if input.wasPressed(.b) { boxes.toggle() }
        if boxes {
            for entity in decals {
                if let matrix = world.get(GlobalTransform.self, for: entity)?.matrix {
                    engine.debugDraw.box(matrix * Mat4.scale(Vec3(repeating: 0.5)), color: Vec4(1, 0.72, 0.42, 1))
                }
            }
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
