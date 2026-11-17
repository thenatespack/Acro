import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild

// The light mesh builds are previewed in (MeshBuildPreviewEnvironment.swift): the studio map and
// the environments of the preview world and the Mesh Builder tab.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor private func environment(in world: World) -> SceneEnvironment? {
    var found: SceneEnvironment?
    world.query(SceneEnvironment.self) { _, e in if found == nil { found = e } }
    return found
}

@MainActor
@Suite struct MeshBuildPreviewEnvironmentTests {
    @Test func previewWorldsAreLitByTheStudio() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildPreviewEnvironmentTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        _ = try session.commands.run("project.new", json: JSONSerialization.data(withJSONObject: ["path": folder.appendingPathComponent("Game").path]))
        let build = MeshBuild(parts: [MeshBuildPart(name: "Ball", shape: .sphere, position: Vec3(0, 0.2, 0), size: Vec3(0.4, 0.4, 0.4), look: "gold")])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Ball", build: build))
        let assets = try #require(session.assets)
        let prefab = try #require(assets.prefab(AssetReference(id)))
        let meshes: (MeshHandle) -> MeshGeometry? = { handle in handle.assetReference.flatMap { assets.mesh($0) } }

        // Default: the studio map, lighting the model (image-based lighting) and behind it.
        let scene = try MeshBuildPreviewScene(build: build, prefab: prefab, views: [.front], tileSize: 100, labels: false, highlight: [],
                                              animation: nil, time: nil, meshes: meshes)
        let studio = try #require(environment(in: scene.world))
        #expect(studio.sky == .map && studio.imageBasedLighting)
        #expect(studio.environmentMap == TextureHandle(MeshBuildPreviewEnvironment.studioTextureKey))
        // The other choices: the procedural sky, and the old flat ambient.
        for (choice, sky) in [(MeshBuildPreviewEnvironment.outdoor, SkyMode.procedural), (.flat, .color)] {
            let other = try MeshBuildPreviewScene(build: build, prefab: prefab, views: [.front], tileSize: 100, labels: false, highlight: [],
                                                  animation: nil, time: nil, environment: choice, meshes: meshes)
            #expect(environment(in: other.world)?.sky == sky, "\(choice)")
        }
        // The Mesh Builder tab's world has the studio too.
        let workspace = MeshBuilderWorkspace(session: session)
        #expect(environment(in: workspace.world) == MeshBuildPreviewEnvironment.studio.sceneEnvironment)
        // The tool takes the choice by name.
        let arguments = try JSONDecoder().decode(MeshBuildPreviewCommand.Arguments.self, from: Data(#"{"path": "Ball.meshbuild", "environment": "outdoor"}"#.utf8))
        #expect(arguments.environment == .outdoor)
    }

    @Test func studioIsNeutralWithBrightSoftboxesAndADarkerFloor() {
        let image = MeshBuildPreviewEnvironment.studioImage
        #expect(image.width == 512 && image.height == 256)
        #expect(stride(from: 0, to: image.pixels.count, by: 4).allSatisfy { image.pixels[$0] == image.pixels[$0 + 1] && image.pixels[$0] == image.pixels[$0 + 2] },
                "gray: colors read true")
        let radiance = MeshBuildPreviewEnvironment.studioRadiance
        let floor = radiance(Vec3(0, -1, 0)), horizon = radiance(normalize(Vec3(0, -0.01, 1))), ceiling = radiance(normalize(Vec3(0.3, 0.6, 1)))
        #expect(floor < horizon && horizon < ceiling, "\(floor) \(horizon) \(ceiling)")
        // The key softbox (front right, above) is many times brighter than the walls.
        let key = radiance(normalize(Vec3(sinf(40 * .pi / 180), tanf(32 * .pi / 180), -cosf(40 * .pi / 180))))
        #expect(key > ceiling * 6)
        // Diffuse light comes mostly from above and stays in the range of the old ambient (not washing out).
        let sh = EnvironmentMath.projectIrradianceSH(width: 64, height: 32, radiance: { Vec3(repeating: radiance($0)) })
        let up = EnvironmentMath.irradiance(sh, normal: Vec3(0, 1, 0)).x
        let side = EnvironmentMath.irradiance(sh, normal: Vec3(1, 0, 0)).x
        let down = EnvironmentMath.irradiance(sh, normal: Vec3(0, -1, 0)).x
        #expect(up > side && side > down, "\(up) \(side) \(down)")
        #expect(up > 0.35 && up < 0.8 && down < 0.15, "\(up) \(down)")
    }
}
