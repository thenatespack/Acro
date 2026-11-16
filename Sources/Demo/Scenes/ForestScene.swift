import Engine
import Foundation

/// A small forest of one mesh build tree (the editor's Gnarled Tree example), placed 200 times
/// with random turns and sizes: every copy is a prefab of parts that draw instanced (one draw per
/// part mesh, material and detail level for the whole forest), with detail levels and an
/// impostor generated at import (MeshBuildLOD.swift) and swaying in the scene's wind.
///
/// The model is imported by an `AssetDatabase` in a temporary project and every mesh and material
/// is registered up front, so the first frame draws everything (deterministic screenshots).
/// Environment: `FOREST_LOD=0` imports it without detail levels (the before picture),
/// `FOREST_WIND=0` stills the air, `FOREST_TREES=n` places n trees, `FOREST_SINGLE=d` shows one
/// tree from d meters (detail level screenshots), `FOREST_PARTS=1` prints each part's triangles per level.
final class ForestScene: DemoScene {
    static let name = "forest"
    static let summary = "200 mesh build trees: instanced parts, detail levels with impostors, wind"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private let single: Float?
    private let levelTriangles: [Int]
    private static let skyColor = Vec3(0.62, 0.72, 0.85)

    init(renderer: Renderer) throws {
        let env = ProcessInfo.processInfo.environment
        let device = renderer.device
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)
        single = env["FOREST_SINGLE"].flatMap(Float.init)

        // Import the tree.
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ForestScene-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let project = try Project.create(at: root, name: "Forest")
        let database = AssetDatabase(project: project)
        var build = try AssetJSON.decoder().decode(MeshBuild.self, from: Data(Self.treeJSON.utf8))
        if env["FOREST_LOD"] == "0" { build.lod = false }
        let id = try database.createMeshBuild(build, at: "Models/Gnarled Tree.meshbuild")
        database.refreshAsync()
        database.waitForAll()
        guard let prefab = database.prefab(AssetReference(id)), let record = database.record(id) else {
            throw AssetError.unreadable("the forest's tree didn't import")
        }
        var textures: [String: GPUTexture] = [:]
        for object in record.objects {
            let reference = AssetReference(id, subAsset: object.id)
            switch object.kind {
            case .mesh:
                if let mesh = database.mesh(reference) { try sceneRenderer.registerMesh(mesh, key: reference.description) }
            case .material:
                guard let asset = database.material(reference) else { continue }
                let material = try asset.material { texture in
                    if let made = textures[texture.description] { return made }
                    guard let data = database.texture(texture), case .rgba8(let image) = data.pixels else { return nil }
                    let made = try device.makeTexture(image: image, srgb: data.isSRGB, generateMipmaps: data.generatesMipmaps)
                    textures[texture.description] = made
                    return made
                }
                try sceneRenderer.registerMaterial(material, key: reference.description)
            default: break
            }
        }
        levelTriangles = Self.levelTriangles(prefab, database: database)

        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.23, 0.3, 0.14, 1), roughness: 0.95), key: "grass")
        cameraEntity = world.spawn(Transform.looking(from: Vec3(0, 6, -20), at: Vec3(0, 3, 30)),
                                   Camera(fovY: .pi / 3, near: 0.1, far: 600, clearColor: Vec4(Self.skyColor, 1)))
        var environment = SceneEnvironment(skyColor: Vec3(0.55, 0.65, 0.85), ambientIntensity: 0.45, fogColor: Self.skyColor,
                                           fogDensity: 0.004)
        if env["FOREST_WIND"] == "0" { environment.wind = .calm } else { environment.wind = Wind(strength: 1, gustiness: 0.6) }
        _ = world.spawn(environment)
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(0.45, 0.8, -0.35)))),
                        DirectionalLight(color: Vec3(1, 0.96, 0.88), intensity: 2.6, shadowExtent: 60, shadowCenter: Vec3(0, 0, 30)))
        _ = world.spawn(Transform(position: Vec3(0, -0.5, 60), scale: Vec3(400, 1, 400)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("grass"), castsShadows: false))

        // The trees: a jittered grid in front of the camera (or one tree).
        if single != nil {
            world.instantiate(prefab)
        } else {
            let count = env["FOREST_TREES"].flatMap(Int.init) ?? 200
            var seed: UInt64 = 0x5EED
            func random() -> Float {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Float(seed >> 40) / Float(1 << 24)
            }
            for k in 0..<count {
                let x = (Float(k % 20) - 9.5) * 9 + (random() - 0.5) * 5
                let z = Float(k / 20) * 11 + (random() - 0.5) * 6
                let tree = world.instantiate(prefab).first!
                let scale = 0.8 + random() * 0.45
                world.add(Transform(position: Vec3(x, 0, z), rotation: Quat(angle: random() * 2 * .pi, axis: Vec3(0, 1, 0)),
                                    scale: Vec3(repeating: scale)), to: tree)
            }
        }
        world.propagateTransforms()
        print("forest: \(single == nil ? "\(env["FOREST_TREES"] ?? "200") trees" : "one tree"), triangles per level "
              + "\(levelTriangles) (full, 1, 2, impostor), detail levels \(build.lod == false ? "off" : "on")")
    }

    /// Triangles drawn per detail level by one tree (full detail first).
    private static func levelTriangles(_ prefab: PrefabAsset, database: AssetDatabase) -> [Int] {
        var nodes: [PrefabNode] = []
        var stack = prefab.roots
        while let node = stack.popLast() {
            nodes.append(node)
            stack += node.children
        }
        let levels = nodes.reduce(0) { max($0, $1.lod?.levelCount ?? 0) }
        var totals = [Int](repeating: 0, count: levels + 1)
        for node in nodes {
            guard let mesh = node.mesh else { continue }
            for level in 0...levels {
                let key = node.lod?.mesh(level: level, base: MeshHandle(mesh)).key ?? MeshHandle(mesh).key
                totals[level] += AssetReference(key).flatMap { database.mesh($0) }.map { $0.indices.count / 3 } ?? 0
            }
            if ProcessInfo.processInfo.environment["FOREST_PARTS"] == "1" {
                print("  \(node.name): " + (0...levels).map { level in
                    let key = node.lod?.mesh(level: level, base: MeshHandle(mesh)).key ?? MeshHandle(mesh).key
                    return "\(AssetReference(key).flatMap { database.mesh($0) }.map { $0.indices.count / 3 } ?? 0)"
                }.joined(separator: " / "))
            }
        }
        return totals
    }

    var initialView: OrbitView {
        if let single { return OrbitView(yaw: 0.5, pitch: 0.12, distance: single, target: Vec3(0, 2.8, 0)) }
        return OrbitView(yaw: .pi, pitch: 0.12, distance: 24, target: Vec3(0, 4, 4))
    }
    var lighting: Lighting { Lighting(fogColor: Self.skyColor) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(s.items) items, \(s.drawCalls) draws, tree triangles per level \(levelTriangles)"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, far: 600)
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

    /// The editor's Gnarled Tree example (MeshBuildExamples.swift), as the file says it.
    static let treeJSON = #"""
        {"parts": [
          {"name":"Mound","shape":"hemisphere","position":[0,0.06,0],"size":[1.8,0.12,1.8],"segments":24,"look":"dirt"},
          {"name":"Trunk","shape":"sweep","parent":"Mound","position":[0,-0.06,0],"look":"bark","radius":0.26,"segments":16,"path":[[0,0.08,0],[0.1,0.8,0.05],[-0.13,1.6,0.14],[0.07,2.3,0],[0.12,3,-0.05]],"radii":[1.4,1,0.85,0.75,0.6],"deform":[{"noise":{"amount":0.035,"scale":0.45,"seed":4}}]},
          {"name":"Root","shape":"sweep","parent":"Trunk","look":"bark","radius":0.1,"segments":10,"path":[[0.1,0.62,0],[0.38,0.3,0.02],[0.62,0.17,0.06],[0.86,0.11,0.1]],"radii":[1.6,1.1,0.6,0.15],"repeat":{"count":5,"radial":{"axis":"y"}}},
          {"name":"Branch East","shape":"sweep","parent":"Trunk","look":"bark","radius":0.15,"segments":12,"path":[[0,2.35,0.05],[0.6,2.9,0.1],[1.2,3.2,0],[1.75,3.75,-0.1]],"radii":[1,0.72,0.48,0.15]},
          {"name":"Branch West","shape":"sweep","parent":"Trunk","look":"bark","radius":0.14,"segments":12,"path":[[-0.05,2.05,0.1],[-0.6,2.6,0.4],[-1.1,3,0.5],[-1.55,3.65,0.7]],"radii":[1,0.72,0.48,0.15]},
          {"name":"Branch Front","shape":"sweep","parent":"Trunk","look":"bark","radius":0.12,"segments":10,"path":[[0.05,2.65,0],[0.1,3.3,-0.5],[0,3.8,-0.95],[0.15,4.25,-1.2]],"radii":[1,0.7,0.45,0.15]},
          {"name":"Branch Back","shape":"sweep","parent":"Trunk","look":"bark","radius":0.11,"segments":10,"path":[[0.05,2.5,0.05],[0.25,3.1,0.6],[0.2,3.6,1.0],[0.4,4.0,1.35]],"radii":[1,0.7,0.45,0.15]},
          {"name":"Leader","shape":"sweep","parent":"Trunk","look":"bark","radius":0.14,"segments":10,"path":[[0.12,2.9,-0.05],[0.2,3.6,0.1],[0.1,4.3,0.2],[0.25,4.9,0.15]],"radii":[1,0.7,0.45,0.12]},
          {"name":"Twig East","shape":"sweep","parent":"Branch East","look":"bark","radius":0.05,"segments":8,"path":[[1.2,3.2,0],[1.5,3.35,0.5],[1.85,3.5,0.85]],"radii":[1,0.6,0.15]},
          {"name":"Twig West","shape":"sweep","parent":"Branch West","look":"bark","radius":0.05,"segments":8,"path":[[-1.1,3,0.5],[-1.6,3.1,0.2],[-2.05,3.3,0.05]],"radii":[1,0.6,0.15]},
          {"name":"Twig Front","shape":"sweep","parent":"Branch Front","look":"bark","radius":0.045,"segments":8,"path":[[0,3.8,-0.95],[-0.5,4.0,-1.1],[-0.9,4.3,-1.0]],"radii":[1,0.6,0.15]},
          {"name":"Twig Top","shape":"sweep","parent":"Leader","look":"bark","radius":0.045,"segments":8,"path":[[0.1,4.3,0.2],[0.55,4.6,0.35],[0.9,4.75,0.55]],"radii":[1,0.6,0.15]},
          {"name":"Leaves","shape":"foliage","parent":"Trunk","look":"oakLeaves","on":["Branch East","Branch West","Branch Front","Branch Back","Leader","Twig East","Twig West","Twig Front","Twig Top"],"along":[0.4,1],"cardSize":0.6,"density":1.3},
          {"name":"Crown","shape":"foliage","parent":"Trunk","look":"oakLeaves","position":[0.05,4.0,0.05],"size":[3.6,2.4,3.0],"cardSize":0.65,"density":0.9,"seed":2}
        ]}
        """#
}
