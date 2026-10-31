import Engine
import Foundation

/// A glTF model imported with `GLTFReader` and drawn by `SceneRenderer`: by default the
/// Khronos OrientationTest model (every arrow must point into its matching target; a mirrored
/// or inside-out import breaks that), or any `.gltf` / `.glb` named by `DEMO_GLTF=<path>`.
/// Images are decoded with `ImageDecoder` and every texture of the PBR materials is used
/// (block-compressed by role with `DEMO_TEXTURE_COMPRESSION=auto|bc7|astc|bc5|astcRG`).
/// The model is scaled to fit and stood on the floor; the window title shows what was imported.
final class GLTFScene: DemoScene {
    static let name = "gltf"
    static let summary = "glTF 2.0 import: node hierarchy, multi-primitive meshes, materials (OrientationTest, or DEMO_GLTF=<file>)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private let summaryText: String
    private let viewDistance: Float
    private static let fogColor = Vec3(0.62, 0.7, 0.82)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")

        let url: URL
        if let path = ProcessInfo.processInfo.environment["DEMO_GLTF"] {
            url = URL(fileURLWithPath: path)
        } else {
            guard let bundled = Bundle.module.url(forResource: "OrientationTest", withExtension: "glb", subdirectory: "Models") else {
                throw GraphicsError("Models/OrientationTest.glb is missing from the Demo bundle")
            }
            url = bundled
        }
        let model = try GLTFReader.read(contentsOf: url)
        for warning in model.warnings { print("glTF: \(warning)") }
        let (textures, failures) = model.makeTextures(device: renderer.device, compression: .demoSetting) { data, _ in
            try ImageDecoder.decode(data)
        }
        for failure in failures { print("glTF: \(failure)") }
        let handles = try model.register(with: sceneRenderer, keyPrefix: url.lastPathComponent, textures: textures)

        // Fit the model into an 8-unit box standing on the floor at the origin.
        let bounds = model.sceneBounds ?? Bounds(center: .zero, halfExtent: Vec3(repeating: 0.5))
        let scale = 4 / max(bounds.halfExtent.max(), 1e-3)
        let root = world.spawn(
            Transform(position: Vec3(-bounds.center.x, bounds.halfExtent.y - bounds.center.y, -bounds.center.z) * scale,
                      scale: Vec3(repeating: scale)),
            Name(url.deletingPathExtension().lastPathComponent))
        let instance = model.instantiate(in: world, under: root, handles: handles)
        viewDistance = 4 + bounds.halfExtent.y * scale * 4

        summaryText = "\(url.lastPathComponent): \(model.nodes.count) nodes, \(model.meshes.count) meshes, "
            + "\(instance.renderers.count) primitives drawn, \(model.materials.count) materials, \(model.triangleCount) triangles"
            + (model.textures.isEmpty ? "" : ", \(model.textures.count) textures")
            + (failures.isEmpty ? "" : ", \(failures.count) images failed to decode")
            + (model.warnings.isEmpty ? "" : ", \(model.warnings.count) warnings")

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(12, 10, 14), at: Vec3(0, 4, 0)),
            Camera(fovY: .pi / 3.5, near: 0.1, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.45, fogColor: Self.fogColor, fogDensity: 0.004))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.3))),
            DirectionalLight(intensity: 1.2, shadowExtent: 12, shadowCenter: Vec3(0, 3, 0)))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(40, 1, 40)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.6, pitch: 0.4, distance: viewDistance, target: Vec3(0, 4, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var status: String { summaryText }

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
}
