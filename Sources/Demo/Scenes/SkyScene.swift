import Engine
import Foundation

/// Skybox and image-based lighting (`SceneEnvironment.sky`): rows of chrome, gold and red
/// plastic spheres from smooth to rough (left to right) on a small stage, reflecting either an
/// HDR studio environment (an equirectangular image generated in code: softboxes over a dark
/// room; `DEMO_HDR=<file.hdr>` loads a Radiance file instead) or the procedural sky, whose sun
/// follows the directional light.
///
/// Keys: **M** switches between the HDR map and the procedural sky, hold **R** to turn the
/// environment (and the light with it), **I** toggles image-based lighting (off: hemisphere
/// ambient). `DEMO_SKY=procedural` starts with the procedural sky. Static, so screenshots are
/// deterministic.
final class SkyScene: DemoScene {
    static let name = "sky"
    static let summary = "Skybox + image-based lighting: HDR map or procedural sky, SH9 irradiance, prefiltered reflections (DEMO_HDR=<file>)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private let environmentEntity: Entity
    private let lightEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    /// Turn of the environment and the light about +Y, radians.
    private var yaw: Float = 0
    /// Direction toward the light before `yaw`: the studio's key softbox, or a low sun in the left of the view.
    private let keyDirection: Vec3
    private static let sunDirection = normalize(Vec3(-0.6, 0.3, -0.75))

    init(renderer: Renderer) throws {
        let device = renderer.device
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)
        try sceneRenderer.registerMesh(.sphere(radius: 0.5, segments: 64, rings: 32), key: "sphere-hi")

        if let path = ProcessInfo.processInfo.environment["DEMO_HDR"] {
            let image = try ImageDecoder.decodeFloat(Data(contentsOf: URL(fileURLWithPath: path)))
            sceneRenderer.registerTexture(try device.makeTexture(image: image), key: "environment")
        } else {
            sceneRenderer.registerTexture(try device.makeTexture(image: Self.studio(width: 1024, height: 512)), key: "environment")
        }
        keyDirection = EnvironmentMath.equirectDirection(Self.keySoftbox)

        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.32, 0.32, 0.34, 1), checker: true, roughness: 0.65), key: "stage")
        let rows: [(String, Vec4, Float)] = [
            ("chrome", Vec4(0.97, 0.96, 0.94, 1), 1), ("gold", Vec4(1, 0.78, 0.34, 1), 1), ("plastic", Vec4(0.75, 0.08, 0.06, 1), 0),
        ]
        let columns = 6
        for (row, (name, color, metallic)) in rows.enumerated() {
            for column in 0..<columns {
                let roughness = Float(column) / Float(columns - 1)
                let key = "\(name) \(column)"
                try sceneRenderer.registerMaterial(Material(baseColor: color, metallic: metallic, roughness: roughness), key: key)
                _ = world.spawn(
                    Transform(position: Vec3((Float(column) - 2.5) * 1.2, 0.75 + Float(2 - row) * 1.2, 0), scale: Vec3(repeating: 1.05)),
                    Name("\(name) roughness \(roughness)"), MeshRenderer(mesh: MeshHandle("sphere-hi"), material: MaterialHandle(key)))
            }
        }
        _ = world.spawn(Transform(position: Vec3(0, -0.25, 0), scale: Vec3(9, 0.5, 4)), Name("Stage"),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("stage"), castsShadows: false))

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 2.5, 9), at: Vec3(0, 1.8, 0)),
            Camera(fovY: .pi / 3, near: 0.1, far: 200))
        let procedural = ProcessInfo.processInfo.environment["DEMO_SKY"] == "procedural"
        environmentEntity = world.spawn(Name("Environment"), SceneEnvironment(
            sky: procedural ? .procedural : .map, environmentMap: TextureHandle("environment")))
        lightEntity = world.spawn(Name("Sun"), DirectionalLight(intensity: 0, shadowExtent: 7, shadowCenter: Vec3(0, 1.5, 0)))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, bloom: true, bloomIntensity: 0.04))
        applyEnvironment()
        world.propagateTransforms()
    }

    private var environment: SceneEnvironment {
        get { world.get(SceneEnvironment.self, for: environmentEntity) ?? SceneEnvironment() }
        set { world.add(newValue, to: environmentEntity) }
    }

    /// Turns the environment and the light by `yaw`: the map's key softbox (a dimmer key light
    /// with shadows) or the procedural sun (a bright one) stays where the light comes from.
    private func applyEnvironment() {
        var e = environment
        e.environmentRotation = yaw
        environment = e
        let procedural = e.sky == .procedural
        let toLight = Quat(angle: yaw, axis: Vec3(0, 1, 0)) * (procedural ? Self.sunDirection : keyDirection)
        world.modify(DirectionalLight.self, for: lightEntity) { light in
            light.direction = -toLight
            light.intensity = procedural ? 3 : 1.2
            light.color = procedural ? Vec3(1, 0.93, 0.82) : Vec3(1, 0.96, 0.9)
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.12, distance: 9.5, target: Vec3(0, 1.9, 0)) }
    var status: String {
        let e = environment
        return "sky \(e.sky == .map ? "HDR map" : "procedural") [M], image-based lighting \(e.imageBasedLighting ? "on" : "off") [I], "
            + String(format: "rotation %.0f° [hold R]", yaw * 180 / .pi)
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
        var changed = false
        if input.wasPressed(.m) {
            var e = environment
            e.sky = e.sky == .map ? .procedural : .map
            environment = e
            changed = true
        }
        if input.wasPressed(.i) {
            var e = environment
            e.imageBasedLighting.toggle()
            environment = e
        }
        if input.isDown(.r) {
            yaw = (yaw + dt * 0.6).truncatingRemainder(dividingBy: 2 * .pi)
            changed = true
        }
        if changed { applyEnvironment() }
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

    // MARK: - The studio environment

    /// Equirectangular coordinates of the key softbox's center (front left, 35° up).
    private static let keySoftbox = Vec2(0.4, 0.3)

    /// An HDR photo-studio environment: a dim room (darker floor, a faint warm band at eye
    /// level) lit by a big warm key softbox, a cool fill on the other side, a long strip overhead
    /// and a narrow rim light behind. Linear radiance, edges softened over a few texels.
    static func studio(width: Int, height: Int) -> FloatImage {
        struct Softbox {
            var center: Vec2  // equirectangular uv
            var size: Vec2    // in uv
            var radiance: Vec3
        }
        let boxes = [
            Softbox(center: keySoftbox, size: Vec2(0.07, 0.12), radiance: Vec3(16, 14.5, 12.5)),
            Softbox(center: Vec2(0.78, 0.38), size: Vec2(0.12, 0.08), radiance: Vec3(2.4, 2.9, 3.6)),
            Softbox(center: Vec2(0.5, 0.06), size: Vec2(0.5, 0.02), radiance: Vec3(3, 3, 3)),
            Softbox(center: Vec2(0.02, 0.42), size: Vec2(0.012, 0.2), radiance: Vec3(9, 8.5, 8)),
        ]
        let soft = 1.5 / Float(height)
        func edge(_ distance: Float) -> Float { min(max(0.5 - distance / soft, 0), 1) }
        var pixels = [Float](repeating: 1, count: width * height * 4)
        for y in 0..<height {
            let v = (Float(y) + 0.5) / Float(height)
            // Walls fade from a gray-blue ceiling to a warm band at the horizon, then a dark floor.
            let up = max(0.5 - v, 0) * 2
            var base = Vec3(0.09, 0.1, 0.12) * (1 - up) + Vec3(0.05, 0.055, 0.07) * up
            base += Vec3(0.12, 0.08, 0.05) * expf(-powf((v - 0.5) / 0.035, 2))
            if v > 0.5 { base = base * 0.3 + Vec3(0.035, 0.03, 0.028) * min((v - 0.5) * 20, 1) }
            for x in 0..<width {
                let u = (Float(x) + 0.5) / Float(width)
                var color = base
                for box in boxes {
                    var du = abs(u - box.center.x)
                    du = min(du, 1 - du)  // wraps around
                    let dv = abs(v - box.center.y)
                    let inside = edge(du - box.size.x / 2) * edge(dv - box.size.y / 2)
                    color = color + (box.radiance - color) * inside
                }
                let i = (y * width + x) * 4
                pixels[i] = color.x
                pixels[i + 1] = color.y
                pixels[i + 2] = color.z
            }
        }
        return FloatImage(width: width, height: height, pixels: pixels)
    }
}
