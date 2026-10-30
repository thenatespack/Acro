import Engine
import Foundation

/// Spins an entity about `axis` at `speed` rad/s (absolute: angle = speed * time + phase).
struct Spin: Component, Codable, Sendable {
    var axis = Vec3(0, 1, 0)
    var speed: Float
    var phase: Float = 0
}

/// Bobs an entity up and down around `baseY`.
struct Bob: Component, Codable, Sendable {
    var baseY: Float
    var amplitude: Float
    var phase: Float
}

/// A scene built only from entities and drawn by the engine's `SceneRenderer`, not the
/// demo renderer: a checkered floor, a grid of mixed meshes and materials (some bobbing,
/// for object motion vectors), a rotating group three levels deep in the hierarchy, glass
/// panes and bubbles in the transparent pass, a camera entity driven by the orbit controls
/// and a directional light entity aimed by its rotation.
final class ECSScene: DemoScene {
    static let name = "ecs"
    static let summary = "entities drawn by the engine's SceneRenderer: hierarchy, instancing, shadows, transparency, motion vectors"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let fogColor = Vec3(0.62, 0.7, 0.82)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        let tiles = try renderer.device.makeTexture(
            pixels: Self.tilePixels(size: 64), width: 64, height: 64, format: .rgba8Srgb, generateMipmaps: true)
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), specular: 0.05), key: "matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), specular: 0.8, shininess: 96), key: "glossy")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), texture: tiles, uvScale: Vec2(2, 2)), key: "tiles")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 0.85, 0.5, 1), emissive: 1), key: "glow")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(1, 1, 1, 1), specular: 1, shininess: 128, doubleSided: true, isTransparent: true), key: "glass")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(20, 18, 24), at: Vec3(0, 2, 0)),
            Camera(fovY: .pi / 3.5, near: 0.5, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.006))
        // Aimed by its rotation; the shadow area follows the camera.
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.5, 0.75, 0.35))),
            DirectionalLight(intensity: 1.3, shadowExtent: 30))

        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(52, 1, 52)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))

        buildGrid()
        buildCarousel()
        buildGlass()

        world.addSystem("spin") { world in
            let t = Float(world.time.elapsed)
            world.queryMutating(Transform.self, Spin.self) { _, transform, spin in
                transform.rotation = Quat(angle: spin.speed * t + spin.phase, axis: spin.axis)
            }
        }
        world.addSystem("bob") { world in
            let t = Float(world.time.elapsed)
            world.queryMutating(Transform.self, Bob.self) { _, transform, bob in
                transform.position.y = bob.baseY + sinf(t * 2 + bob.phase) * bob.amplitude
            }
        }
        world.propagateTransforms()
    }

    /// 9x9 cubes and spheres around a clearing, cycling through three materials.
    private func buildGrid() {
        var rng = SplitMix64(state: 7)
        let materials = ["matte", "glossy", "tiles"].map(MaterialHandle.init)
        for gz in 0..<9 {
            for gx in 0..<9 {
                let p = Vec2(Float(gx) - 4, Float(gz) - 4) * 3.2
                if (p * p).sum() < 40 { continue }
                let i = gx + gz * 9
                let sphere = i % 3 == 1
                let size = 0.9 + rng.next() * 0.9
                let y = size / 2 + (sphere ? 0.2 : 0)
                let entity = world.spawn(
                    Transform(position: Vec3(p.x, y, p.y), rotation: Quat(angle: rng.next() * .pi, axis: Vec3(0, 1, 0)),
                              scale: Vec3(repeating: size)),
                    MeshRenderer(mesh: sphere ? .sphere : .cube, material: materials[(i / 2) % 3],
                                 tint: hsv(rng.next(), 0.55, 0.95)))
                if i % 4 == 0 {
                    world.add(Bob(baseY: y + 0.6, amplitude: 0.6, phase: rng.next() * 6), to: entity)
                }
            }
        }
    }

    /// A rotating pivot with a pillar and four arms; each arm spins and carries an orbiting moon.
    private func buildCarousel() {
        let pivot = world.spawn(Transform(), Spin(speed: 0.5))
        let pillar = world.spawn(
            Transform(position: Vec3(0, 2.5, 0), scale: Vec3(1.2, 5, 1.2)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("glossy"), tint: Vec3(0.85, 0.85, 0.9)))
        world.setParent(pillar, to: pivot)
        let lamp = world.spawn(
            Transform(position: Vec3(0, 5.6, 0), scale: Vec3(repeating: 1.1)),
            MeshRenderer(mesh: .sphere, material: MaterialHandle("glow"), castsShadows: false))
        world.setParent(lamp, to: pivot)
        for k in 0..<4 {
            let angle = Float(k) * .pi / 2
            let arm = world.spawn(Transform(position: Vec3(cosf(angle) * 4.5, 2.5, sinf(angle) * 4.5)), Spin(speed: 1.5, phase: angle))
            world.setParent(arm, to: pivot)
            let body = world.spawn(
                Transform(scale: Vec3(2.2, 0.5, 0.5)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: hsv(Float(k) / 4, 0.7, 0.9)))
            world.setParent(body, to: arm)
            let moonOrbit = world.spawn(Transform(position: Vec3(1.1, 0, 0)), Spin(axis: Vec3(1, 0, 0), speed: 3))
            world.setParent(moonOrbit, to: arm)
            let moon = world.spawn(
                Transform(position: Vec3(0, 0.9, 0), scale: Vec3(repeating: 0.55)),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("glossy"), tint: hsv(Float(k) / 4 + 0.5, 0.6, 1)))
            world.setParent(moon, to: moonOrbit)
        }
        // A translucent shell riding on the pivot (transparency inside the hierarchy).
        let shell = world.spawn(
            Transform(position: Vec3(0, 7.4, 0), scale: Vec3(repeating: 2.4)),
            MeshRenderer(mesh: .sphere, material: MaterialHandle("glass"), tint: Vec3(0.6, 0.85, 1), opacity: 0.35,
                         castsShadows: false))
        world.setParent(shell, to: pivot)
    }

    /// Colored glass panes on a ring and floating bubbles (transparent pass).
    private func buildGlass() {
        for k in 0..<6 {
            let angle = Float(k) / 6 * 2 * .pi + 0.3
            _ = world.spawn(
                Transform(position: Vec3(cosf(angle) * 18, 1.6, sinf(angle) * 18),
                          rotation: Quat(angle: -angle + .pi / 2, axis: Vec3(0, 1, 0)), scale: Vec3(3, 3.2, 0.12)),
                MeshRenderer(mesh: .cube, material: MaterialHandle("glass"), tint: hsv(Float(k) / 6, 0.7, 1), opacity: 0.45))
        }
        for k in 0..<5 {
            let x = Float(k - 2) * 3.4
            _ = world.spawn(
                Transform(position: Vec3(x, 3, 9), scale: Vec3(repeating: 1.6)),
                MeshRenderer(mesh: .sphere, material: MaterialHandle("matte"), tint: hsv(Float(k) / 5 + 0.1, 0.5, 1),
                             opacity: 0.5),
                Bob(baseY: 3, amplitude: 0.8, phase: Float(k)))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.6, pitch: 0.55, distance: 36, target: Vec3(0, 2, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(world.entityCount) entities, \(s.opaque) opaque + \(s.transparent) transparent drawn, \(s.culled) culled, "
            + "\(s.shadowCasters) casters, \(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func update(input: Input, dt: Float, time: Float) {
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

    /// Light stone tiles with dark grout (sRGB).
    private static func tilePixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let grout = x % 32 < 2 || y % 32 < 2
                let shade = ((x / 32 + y / 32) % 2 == 0) ? 230 : 190
                let i = (y * size + x) * 4
                pixels[i] = UInt8(grout ? 60 : shade)
                pixels[i + 1] = UInt8(grout ? 58 : shade - 10)
                pixels[i + 2] = UInt8(grout ? 64 : shade - 30)
            }
        }
        return pixels
    }
}
