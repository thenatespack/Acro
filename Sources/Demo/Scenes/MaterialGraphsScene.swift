import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// Material graphs and a splat terrain: a sphere per Material Builder preset (basic, lava, water,
/// hologram, stone, pulse), on a small generated terrain whose grass, rock and dirt layers are
/// blended per pixel (mesh_terrain.frag) and whose painted "Lava" layer is the lava graph,
/// drawn as a blended overlay (TerrainGraphLayers.swift). Everything is imported at start by an
/// `AssetDatabase` in a temporary project, as the editor would; the compiled graph shaders are
/// spliced at run time for every backend (MSL, SPIR-V and WGSL).
final class MaterialGraphsScene: DemoScene {
    static let name = "graphs"
    static let summary = "material graphs: every preset, a splat terrain with a graph layer (runtime-spliced shaders)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let database: AssetDatabase
    private let root: URL
    private var cameraEntity = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?

    init(renderer: Renderer) throws {
        let device = renderer.device
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)
        root = FileManager.default.temporaryDirectory.appendingPathComponent("MaterialGraphsScene-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: root, name: "Material Graphs")
        database = AssetDatabase(project: project)
        sceneRenderer.assets = database
        sceneRenderer.blocksOnAssetLoading = true

        // A material per preset.
        var presets: [AssetID] = []
        for name in MaterialGraph.presetNames {
            var material = MaterialAsset()
            material.graph = MaterialGraph.preset(name)
            presets.append(try database.createMaterial(material, at: "Materials/\(name).material"))
        }

        // The terrain: gentle hills, rock on the far side, lava painted in a ring around the middle.
        var terrain = Terrain.generated(size: Vec2(32, 32), resolution: 33, seed: 7, hilliness: 0.35, heightRange: 6)
        terrain.collider = false
        terrain.chunkCells = 16
        terrain.layers.append(TerrainLayer(name: "Lava", color: Vec3(0.9, 0.3, 0.05), tileSize: 6, material: "Materials/lava.material"))
        terrain.normalizeData()
        let n = terrain.res
        for z in 0..<n {
            for x in 0..<n {
                let u = Float(x) / Float(n - 1) * 2 - 1, v = Float(z) / Float(n - 1) * 2 - 1
                let ring = max(0, 1 - abs(sqrt(u * u + v * v) - 0.55) * 6)
                let rock = max(0, min(1, -v * 1.5 - 0.3)) * (1 - ring)
                let i = z * n + x
                terrain.splatData[0][i] = UInt8((1 - ring - rock) * 255)
                terrain.splatData[1][i] = UInt8(rock * 255)
                terrain.splatData[2][i] = 0
                terrain.splatData[3][i] = UInt8(ring * 255)
            }
        }
        let terrainID = try database.createTerrain(terrain, at: "Maps/Ground.terrain")
        database.waitForAll()
        guard let ground = database.prefab(AssetReference(terrainID)) else {
            throw AssetError.unreadable("the terrain didn't import: \(database.record(terrainID)?.importError ?? "no record")")
        }
        for id in presets where database.record(id)?.importError != nil {
            print("graphs: \(database.path(of: id) ?? "?"): \(database.record(id)!.importError!)")
        }

        cameraEntity = world.spawn(Transform.looking(from: Vec3(0, 8, -16), at: .zero),
                                   Camera(fovY: .pi / 3, near: 0.1, far: 200, clearColor: Vec4(0.55, 0.65, 0.8, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Vec3(0.55, 0.65, 0.85), ambientIntensity: 0.5))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.4, 0.8, -0.45)))),
                        DirectionalLight(color: Vec3(1, 0.96, 0.9), intensity: 2.4, shadowExtent: 30))
        world.instantiate(ground)
        for (k, id) in presets.enumerated() {
            let x = (Float(k) - Float(presets.count - 1) / 2) * 3
            let groundHeight = terrain.heightAt(x: x, z: 0)
            _ = world.spawn(Transform(position: Vec3(x, groundHeight + 1.4, 0), scale: Vec3(repeating: 2.2)),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle(AssetReference(id).description)))
        }
        world.propagateTransforms()
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    var initialView: OrbitView { OrbitView(yaw: .pi, pitch: 0.45, distance: 17, target: Vec3(0, 1.5, 0)) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(MaterialGraph.presetNames.joined(separator: ", ")); \(s.items) items, \(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, far: 200)
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
