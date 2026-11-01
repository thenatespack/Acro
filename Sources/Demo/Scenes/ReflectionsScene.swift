import Engine
import Foundation

/// Drifts a colored light (and its marker) back and forth along the street.
struct StreetLight: Component, Codable, Sendable {
    var base: Vec3
    var travel: Float
    var speed: Float
    var phase: Float
}

/// A wet neon street: a glossy road with a rippled normal map under a `PlanarReflection`,
/// lined with emissive neon signs and tubes, lamp posts with colored point lights, a few
/// props, and dry (rough) sidewalks that don't reflect. Everything is lit only by the signs'
/// lights and a faint moon, so what you see on the road is mostly reflection.
final class ReflectionsScene: DemoScene {
    static let name = "reflections"
    static let summary = "planar reflections: a wet neon street, roughness blur, normal-map ripples, half-res mirrored pass"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let clearColor = Vec3(0.02, 0.012, 0.04)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let ripples = try Self.rippleNormalMap(device: renderer.device)
        // The wet road: very smooth, with a rippled normal map; the gutter strip is rougher (blurred reflection).
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.05, 0.05, 0.06, 1), uvScale: Vec2(8, 8), roughness: 0.06, normalTexture: ripples, normalScale: 0.5),
            key: "wet")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(0.05, 0.05, 0.06, 1), uvScale: Vec2(8, 8), roughness: 0.3, normalTexture: ripples, normalScale: 0.5),
            key: "damp")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.18, 0.17, 0.2, 1), roughness: 0.85), key: "concrete")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.07, 0.07, 0.09, 1), roughness: 0.6), key: "building")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.6, 0.62, 0.66, 1), metallic: 1, roughness: 0.25), key: "metal")
        for (key, color) in [("magenta", Vec3(1, 0.1, 0.6)), ("cyan", Vec3(0.1, 0.8, 1)), ("amber", Vec3(1, 0.55, 0.1)),
                             ("green", Vec3(0.2, 1, 0.3))] {
            try sceneRenderer.registerMaterial(
                Material(baseColor: Vec4(0.02, 0.02, 0.02, 1), roughness: 0.4, emissiveColor: color, emissiveStrength: 6), key: "neon-" + key)
        }

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(0, 1.4, 16), at: Vec3(0, 2.2, -10)),
            Camera(fovY: .pi / 3, near: 0.1, far: 200, clearColor: Vec4(Self.clearColor, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.1, 0.06, 0.2), groundColor: Vec3(0.02, 0.015, 0.03), ambientIntensity: 0.15,
                                         fogColor: Self.clearColor, fogDensity: 0.012))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.3, 0.9, 0.4)))), Name("Moon"),
                        DirectionalLight(color: Vec3(0.5, 0.55, 1), intensity: 0.12, castsShadows: false))
        // The mirror: the road's plane (y = 0).
        _ = world.spawn(Transform(position: .zero), Name("Road reflection"), PlanarReflection())
        _ = world.spawn(Transform(position: Vec3(0, 0, -8), scale: Vec3(14, 1, 70)), Name("Road"),
                        MeshRenderer(mesh: .plane, material: MaterialHandle("wet"), castsShadows: false, receivesShadows: false))
        _ = world.spawn(Transform(position: Vec3(4.6, 0.001, -8), scale: Vec3(2.6, 1, 70)), Name("Gutter"),
                        MeshRenderer(mesh: .plane, material: MaterialHandle("damp"), castsShadows: false, receivesShadows: false))

        buildStreet()
        world.propagateTransforms()
    }

    private func buildStreet() {
        var rng = SplitMix64(state: 5)
        let neon = ["magenta", "cyan", "amber", "green"]
        for side: Float in [-1, 1] {
            // Sidewalk, then buildings with neon signs facing the street.
            _ = world.spawn(Transform(position: Vec3(side * 10.5, 0.1, -8), scale: Vec3(6, 0.2, 70)), Name("Sidewalk"),
                            MeshRenderer(mesh: .cube, material: MaterialHandle("concrete"), castsShadows: false))
            for k in 0..<8 {
                let z = 12 - Float(k) * 8.5
                let height = 9 + rng.next() * 12
                _ = world.spawn(Transform(position: Vec3(side * 15.5, height / 2, z), scale: Vec3(8, height, 7.5)), Name("Building"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("building"), castsShadows: false))
                let color = neon[(k + (side > 0 ? 2 : 0)) % 4]
                let signY = 3 + rng.next() * 4
                _ = world.spawn(Transform(position: Vec3(side * 11.4, signY, z), scale: Vec3(0.2, 1.1 + rng.next(), 3.2)), Name("Sign"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("neon-" + color), castsShadows: false))
                _ = world.spawn(Transform(position: Vec3(side * 9.5, signY - 0.5, z), scale: Vec3(repeating: 0.1)), Name("Sign light"),
                                PointLight(color: Self.color(color), intensity: 9, range: 11))
                // A vertical neon tube at the corner, and a lamp post by the curb.
                _ = world.spawn(Transform(position: Vec3(side * 11.3, 5.5, z + 4), scale: Vec3(0.15, 9, 0.15)), Name("Tube"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("neon-" + neon[(k + 1) % 4]), castsShadows: false))
                _ = world.spawn(Transform(position: Vec3(side * 7.6, 2.6, z - 2), scale: Vec3(0.18, 5.2, 0.18)), Name("Lamp post"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("metal"), castsShadows: false))
            }
        }
        // Moving colored lights over the road (cars passing).
        for k in 0..<4 {
            let name = neon[k]
            let base = Vec3(k % 2 == 0 ? -3 : 3, 0.7, -2 - Float(k) * 6)
            _ = world.spawn(Transform(position: base, scale: Vec3(0.5, 0.25, 0.5)), Name("Car light \(k)"),
                            PointLight(color: Self.color(name), intensity: 10, range: 9),
                            StreetLight(base: base, travel: 5, speed: 0.5 + Float(k) * 0.13, phase: Float(k) * 1.7),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle("neon-" + name), castsShadows: false))
        }
        // Props standing on the wet road: a glossy-metal sphere, a neon ring of cubes, a crate.
        _ = world.spawn(Transform(position: Vec3(-2.2, 0.8, 4), scale: Vec3(repeating: 1.6)), Name("Sphere"),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("metal"), castsShadows: false))
        _ = world.spawn(Transform(position: Vec3(2.5, 0.5, 1), rotation: Quat(angle: 0.5, axis: Vec3(0, 1, 0))), Name("Crate"),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("concrete"), castsShadows: false))
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi
            _ = world.spawn(Transform(position: Vec3(0.5 + cosf(a) * 1.2, 0.2, -5 + sinf(a) * 1.2), scale: Vec3(repeating: 0.4)),
                            Name("Neon cube"), MeshRenderer(mesh: .cube, material: MaterialHandle("neon-" + neon[k % 4]), castsShadows: false))
        }
    }

    private static func color(_ name: String) -> Vec3 {
        switch name {
        case "magenta": Vec3(1, 0.1, 0.6)
        case "cyan": Vec3(0.1, 0.8, 1)
        case "amber": Vec3(1, 0.55, 0.1)
        default: Vec3(0.2, 1, 0.3)
        }
    }

    /// A tiling tangent-space normal map of overlapping ripples (sums of sines with whole
    /// periods, so it repeats seamlessly).
    private static func rippleNormalMap(device: RenderDevice) throws -> GPUTexture {
        let size = 128
        var height = [Float](repeating: 0, count: size * size)
        for y in 0..<size {
            for x in 0..<size {
                let u = Float(x) / Float(size) * 2 * .pi, v = Float(y) / Float(size) * 2 * .pi
                height[y * size + x] = sinf(u * 3 + sinf(v * 2) * 1.5) * 0.5 + sinf(v * 4 - u * 2 + 1) * 0.35 + sinf((u + v) * 6) * 0.15
            }
        }
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let dx = height[y * size + (x + 1) % size] - height[y * size + (x + size - 1) % size]
                let dy = height[((y + 1) % size) * size + x] - height[((y + size - 1) % size) * size + x]
                let n = normalize(Vec3(-dx * 1.5, -dy * 1.5, 1))
                let i = (y * size + x) * 4
                pixels[i] = UInt8(((n.x * 0.5 + 0.5) * 255).rounded())
                pixels[i + 1] = UInt8(((n.y * 0.5 + 0.5) * 255).rounded())
                pixels[i + 2] = UInt8(((n.z * 0.5 + 0.5) * 255).rounded())
            }
        }
        return try device.makeTexture(pixels: pixels, width: size, height: size, format: .rgba8Unorm, generateMipmaps: true)
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.07, distance: 18, target: Vec3(0, 2, -4)) }
    var lighting: Lighting { Lighting(fogColor: Self.clearColor) }
    var status: String { "\(sceneRenderer.stats.list.drawCalls) draws" }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
        world.queryMutating(Transform.self, StreetLight.self) { _, transform, light in
            transform.position = light.base + Vec3(0, 0, sinf(time * light.speed + light.phase) * light.travel)
        }
        world.update(dt: Double(dt))
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: Vec3(orbit.eye.x, max(orbit.eye.y, 0.5), orbit.eye.z), at: orbit.target), to: cameraEntity)
        }
        world.propagateTransforms()
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
