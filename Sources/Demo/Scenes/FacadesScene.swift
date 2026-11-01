import Engine
import Foundation

/// A night street of tall buildings. Four towers get a generated `ProceduralTexture.windowGrid` as
/// an emissive texture (lit windows picked at random, per-window color variation), one material
/// each so the grid matches the tower's size. The front block has no texture at all: its ~300
/// window quads are one entity with a `MeshArray` (random tint variation, some quads "off" and
/// dark), drawn in one instanced call.
final class FacadesScene: DemoScene {
    static let name = "facades"
    static let summary = "Window-grid emissive textures (ProceduralTexture) on towers; a MeshArray of window quads on one entity"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let skyColor = Vec3(0.02, 0.03, 0.07)

    init(renderer: Renderer) throws {
        let device = renderer.device
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)

        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.1, 0.1, 0.11, 1), roughness: 0.95), key: "ground")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.16, 0.16, 0.18, 1), roughness: 0.9), key: "wall")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.1, 0.1, 0.12, 1), roughness: 0.8), key: "roof")
        // Window quads: unlit warm albedo, so the instance tint (random variation, off windows) is the light.
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1.0, 0.8, 0.45, 1), emissive: 1), key: "window")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(18, 14, 52), at: Vec3(0, 14, 0)),
            Camera(fovY: .pi / 3.2, near: 0.1, far: 300, clearColor: Vec4(Self.skyColor, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.25, fogColor: Self.skyColor, fogDensity: 0.006))
        _ = world.spawn(Name("Post-processing"), PostProcess(tonemapper: .neutral, bloom: true, bloomIntensity: 0.08))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.4, 0.6, 0.5)))),
            DirectionalLight(color: Vec3(0.55, 0.65, 1), intensity: 0.5, shadowExtent: 60, shadowCenter: Vec3(0, 5, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(160, 1, 160)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("ground"), castsShadows: false))

        // Towers with emissive window-grid textures: (x, z, floors, columns, seed).
        let towers: [(Float, Float, Int, Int, Int)] = [(-26, -4, 20, 6, 11), (27, -8, 14, 6, 23), (-12, -26, 26, 8, 5), (16, -30, 18, 8, 42)]
        for (i, tower) in towers.enumerated() {
            let (x, z, floors, columns, seed) = tower
            let width = Float(columns) * 2, height = Float(floors) * 1.6
            let image = ProceduralTexture.windowGrid(width: 512, height: 512, columns: columns, rows: floors, margin: 0.22,
                                                     litFraction: 0.42, seed: seed, variation: 0.35)
            let key = "tower \(i)"
            try sceneRenderer.registerMaterial(Material(
                baseColor: Vec4(0.16, 0.16, 0.18, 1), roughness: 0.9, emissiveColor: Vec3(1, 1, 1),
                emissiveTexture: try device.makeTexture(image: image, srgb: true, generateMipmaps: true),
                emissiveStrength: 1.6), key: key)
            _ = world.spawn(Transform(position: Vec3(x, height / 2, z), scale: Vec3(width, height, width)),
                            Name("Tower \(i)"), MeshRenderer(mesh: .cube, material: MaterialHandle(key)))
            _ = world.spawn(Transform(position: Vec3(x, height + 0.25, z), scale: Vec3(width + 0.6, 0.5, width + 0.6)),
                            Name("Roof \(i)"), MeshRenderer(mesh: .cube, material: MaterialHandle("roof")))
        }

        // The front block: a plain wall with a grid of window quads in front of it, one entity.
        let columns = 20, rows = 14, step: Float = 1.5
        let blockWidth = Float(columns) * step + 1.5, blockHeight = Float(rows) * step + 1.5
        _ = world.spawn(Transform(position: Vec3(0, blockHeight / 2, 0), scale: Vec3(blockWidth, blockHeight, 6)),
                        Name("Block"), MeshRenderer(mesh: .cube, material: MaterialHandle("wall")))
        _ = world.spawn(Transform(position: Vec3(0, blockHeight + 0.25, 0), scale: Vec3(blockWidth + 0.6, 0.5, 6.6)),
                        Name("Block roof"), MeshRenderer(mesh: .cube, material: MaterialHandle("roof")))
        // The plane faces +Y; stand it up toward +Z. Its local Z then runs down the wall.
        _ = world.spawn(
            Transform(position: Vec3(0, blockHeight / 2, 3.03), rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)),
                      scale: Vec3(1.0, 1, 0.8)),
            Name("Windows"),
            MeshRenderer(mesh: .plane, material: MaterialHandle("window"), castsShadows: false),
            MeshArray(countX: columns, countY: 1, countZ: rows, spacing: Vec3(step, 1, step), centered: true, seed: 7,
                      tintVariation: 0.5, offFraction: 0.4, offMode: .tinted, offTint: Vec3(0.04, 0.05, 0.08)))
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.3, pitch: 0.2, distance: 50, target: Vec3(0, 14, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.skyColor) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(s.items) items, \(s.opaque) opaque drawn, \(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, far: 300)
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
}
