import Foundation
import Testing
@testable import Engine

// Background import, hot reload, dependencies and HDR textures. Each test works in its own
// temporary project.

private let triangleOBJ = "o Tri\nv 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n"
private let quadOBJ = "o Quad\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nf 1 2 3 4\n"

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AssetLoadingTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Loading")
}

private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

/// Rewrites `url` and moves its mtime forward so a same-size edit is still noticed.
private func overwrite(_ data: Data, at url: URL, secondsLater: Double = 5) throws {
    try data.write(to: url)
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: secondsLater)], ofItemAtPath: url.path)
}

private func pngData(_ color: [UInt8]) -> Data {
    Image(width: 2, height: 2, pixels: Array([[UInt8]](repeating: color, count: 4).joined())).pngData()
}

private func hdrFile(_ pixels: [[UInt8]], width: Int, height: Int) -> Data {
    var data = Data("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y \(height) +X \(width)\n".utf8)
    for pixel in pixels { data.append(contentsOf: pixel) }
    return data
}

/// Spins the main run loop (and pumps `database`) until `condition` holds or `seconds` pass.
@MainActor
private func spin(_ database: AssetDatabase, seconds: Double = 10, until condition: () -> Bool) -> Bool {
    let deadline = Date(timeIntervalSinceNow: seconds)
    while Date() < deadline {
        database.pump()
        if condition() { return true }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
    }
    return false
}

@MainActor
@Suite struct AssetLoadingTests {
    @Test func backgroundImportReturnsAtOnceAndAppliesOnPump() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("tri.obj"))
        let database = AssetDatabase(project: project)
        var reports: [AssetScanReport] = []
        database.onChange = { reports.append($0) }

        let scan = database.refreshAsync()
        #expect(scan.imported.isEmpty && scan.added.count == 1)
        let id = try #require(database.id(forPath: "tri.obj"))
        #expect(database.isLoading && database.pendingLoadCount == 1)
        #expect(database.loadState(of: id) == .loading)
        #expect(database.loadProgress.total == 1 && database.loadProgress.fraction < 1)

        #expect(database.waitForAll())
        #expect(!database.isLoading && database.loadProgress.isIdle)
        #expect(database.loadState(of: id) == .loaded)
        #expect(database.revision(of: id) > 0)
        #expect(reports.contains { $0.imported == [id] })
        #expect(database.mesh(AssetReference(id, subAsset: "mesh/Tri"))?.indices.count == 3)
        #expect(database.waitForAll())  // idle: returns at once
    }

    @Test func requestLoadsFromTheCacheInTheBackground() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("tri.obj"))
        let first = AssetDatabase(project: project)
        first.refresh()
        let id = try #require(first.id(forPath: "tri.obj"))

        let second = AssetDatabase(project: project)
        second.refreshAsync()
        #expect(second.waitForAll())
        let third = AssetDatabase(project: project)
        third.scan()
        #expect(third.loadState(of: id) == .unloaded)
        #expect(third.request(id) == .loading)
        #expect(third.request(id) == .loading)  // no second job
        #expect(third.loadProgress.total == 1)
        third.waitForAll()
        #expect(third.loadState(of: id) == .loaded)
        #expect(third.mesh(AssetReference(id, subAsset: "mesh/Tri")) != nil)
    }

    @Test func modifyingASourceReimportsAndBumpsTheRevision() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.assetsURL.appendingPathComponent("shape.obj")
        try write(triangleOBJ, to: url)
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()
        let id = try #require(database.id(forPath: "shape.obj"))
        let before = database.revision(of: id)
        #expect(database.mesh(AssetReference(id, subAsset: "mesh/Tri")) != nil)

        try write(quadOBJ, to: url)
        database.refreshAsync()
        database.waitForAll()
        #expect(database.revision(of: id) > before)
        #expect(database.mesh(AssetReference(id, subAsset: "mesh/Quad"))?.indices.count == 6)
    }

    @Test func changingAFileTwiceWhileItImportsEndsWithTheLastVersion() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.assetsURL.appendingPathComponent("shape.obj")
        try write(triangleOBJ, to: url)
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        try write(quadOBJ, to: url)
        database.refreshAsync()  // the first job may still be running: the second waits for it
        #expect(database.waitForAll())
        let id = try #require(database.id(forPath: "shape.obj"))
        #expect(database.mesh(AssetReference(id, subAsset: "mesh/Quad")) != nil)
    }

    @Test func aBinDependencyReimportsTheModel() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        func bin(x: Float) -> Data { [Float(0), 0, 0, x, 0, 0, 0, 1, 0].withUnsafeBytes { Data($0) } }
        let gltf = """
            {"asset": {"version": "2.0"},
             "buffers": [{"byteLength": 36, "uri": "tri.bin"}],
             "bufferViews": [{"buffer": 0, "byteLength": 36}],
             "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3", "min": [0, 0, 0], "max": [1, 1, 0]}],
             "meshes": [{"name": "Tri", "primitives": [{"attributes": {"POSITION": 0}}]}],
             "nodes": [{"name": "Root", "mesh": 0}], "scenes": [{"nodes": [0]}], "scene": 0}
            """
        try write(gltf, to: project.assetsURL.appendingPathComponent("Models/tri.gltf"))
        try bin(x: 1).write(to: project.assetsURL.appendingPathComponent("Models/tri.bin"))
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()
        let id = try #require(database.id(forPath: "Models/tri.gltf"))
        #expect(database.record(id)?.importError == nil)
        let mesh = AssetReference(id, subAsset: "mesh/Tri")
        #expect(database.mesh(mesh)?.vertices.map(\.position.x).max() == 1)
        let before = database.revision(of: id)

        // Nothing changed: nothing is reimported.
        database.refreshAsync()
        #expect(!database.isLoading)

        try overwrite(bin(x: 3), at: project.assetsURL.appendingPathComponent("Models/tri.bin"))
        database.refreshAsync()
        #expect(database.isLoading)
        database.waitForAll()
        #expect(database.revision(of: id) > before)
        #expect(database.mesh(mesh)?.vertices.map(\.position.x).max() == 3)

        // The dependency survives a restart: the index remembers it.
        try overwrite(bin(x: 5), at: project.assetsURL.appendingPathComponent("Models/tri.bin"), secondsLater: 10)
        let reopened = AssetDatabase(project: project)
        reopened.refreshAsync()
        reopened.waitForAll()
        #expect(reopened.mesh(mesh)?.vertices.map(\.position.x).max() == 5)
    }

    @Test func deletingAnAssetReleasesIt() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.assetsURL.appendingPathComponent("tri.obj")
        try write(triangleOBJ, to: url)
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()
        let id = try #require(database.id(forPath: "tri.obj"))
        let before = database.revision(of: id)

        try FileManager.default.removeItem(at: url)
        try FileManager.default.removeItem(at: url.appendingPathExtension("meta"))
        let report = database.refreshAsync()
        #expect(report.removed.map(\.id) == [id])
        #expect(database.loadState(of: id) == .missing)
        #expect(database.asset(id) == nil)
        #expect(database.revision(of: id) > before)
        #expect(!FileManager.default.fileExists(atPath: database.artifactsURL(id).path))
    }

    @Test func hdrTexturesImportCacheAndRoundTrip() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        // RGBE (128, 64, 32, e = 130) is (2, 1, 0.5).
        try hdrFile([[128, 64, 32, 130], [0, 0, 0, 0]], width: 2, height: 1)
            .write(to: project.assetsURL.appendingPathComponent("sky.hdr"))
        try pngData([10, 20, 30, 255]).write(to: project.assetsURL.appendingPathComponent("tile.png"))
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()
        let id = try #require(database.id(forPath: "sky.hdr"))
        #expect(database.record(id)?.importer == "texture")
        let texture = try #require(database.texture(AssetReference(id, subAsset: "texture")))
        let float = try #require(texture.floatImage)
        #expect(texture.isHDR && texture.format == .rgba16Float && texture.width == 2)
        #expect(abs(float.pixels[0] - 2) < 0.02 && abs(float.pixels[2] - 0.5) < 0.02)
        let tileID = try #require(database.id(forPath: "tile.png"))
        let tile = try #require(database.texture(AssetReference(tileID, subAsset: "texture")))
        #expect(!tile.isHDR && tile.format == .rgba8Srgb)

        // Back from the Library cache, bit for bit.
        let cached = AssetDatabase(project: project)
        cached.scan()
        let again = try #require(cached.texture(AssetReference(id, subAsset: "texture")))
        #expect(again.floatImage?.pixels == float.pixels)
        #expect(again.floatImage?.width == 2 && again.floatImage?.height == 1)

        // The compatibility initializer still builds an 8-bit texture.
        let plain = TextureAsset(image: Image(width: 1, height: 1, pixels: [1, 2, 3, 4]))
        #expect(plain.image.pixels == [1, 2, 3, 4] && plain.isSRGB && !plain.isHDR)
    }

    @Test func hotReloadPicksUpEditsInTheBackground() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.assetsURL.appendingPathComponent("shape.obj")
        try write(triangleOBJ, to: url)
        let database = AssetDatabase(project: project)
        database.logsHotReloads = false
        database.refreshAsync()
        database.waitForAll()
        let id = try #require(database.id(forPath: "shape.obj"))
        let before = database.revision(of: id)

        database.startWatching(interval: 0.1)
        defer { database.stopWatching() }
        #expect(database.isWatching)
        try write(quadOBJ, to: url)
        #expect(spin(database) { database.revision(of: id) > before && !database.isLoading })
        #expect(database.mesh(AssetReference(id, subAsset: "mesh/Quad")) != nil)
    }
}

#if os(macOS)
import QuartzCore

@MainActor
@Suite struct SceneRendererLoadingTests {
    private func makeRenderer() throws -> SceneRenderer {
        try SceneRenderer(device: MetalRenderDevice(layer: CAMetalLayer(), sampleCount: 1), quality: .low)
    }

    @Test func materialsDrawAPlaceholderWhileLoadingAndMeshesAreSkipped() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("tri.obj"))
        try write(#"{"baseColor": [1, 0, 0, 1]}"#, to: project.assetsURL.appendingPathComponent("red.material"))
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()  // imported and cached ...
        let reopened = AssetDatabase(project: project)  // ... but not loaded in this database
        reopened.scan()
        let tri = try #require(reopened.id(forPath: "tri.obj")), red = try #require(reopened.id(forPath: "red.material"))

        let renderer = try makeRenderer()
        renderer.blocksOnAssetLoading = false
        renderer.assets = reopened
        let world = World()
        let mesh = MeshHandle(AssetReference(tri, subAsset: "mesh/Tri")), material = MaterialHandle(AssetReference(red))
        _ = world.spawn(Transform(), MeshRenderer(mesh: mesh, material: material))
        _ = world.spawn(Transform(), MeshRenderer(mesh: .cube, material: material))
        world.propagateTransforms()

        renderer.gather(world)
        #expect(renderer.prep.items.count == 1)  // the cube draws with the placeholder, the loading mesh is skipped
        #expect(renderer.material(material)?.baseColor == Vec4(0.5, 0.5, 0.5, 1))
        #expect(reopened.isLoading)

        #expect(spin(reopened) { !reopened.isLoading })
        renderer.gather(world)
        #expect(renderer.prep.items.count == 2)
        #expect(renderer.material(material)?.baseColor == Vec4(1, 0, 0, 1))
    }

    @Test func uploadBudgetSpreadsMeshesOverFrames() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        for i in 0..<3 { try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("tri\(i).obj")) }
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()

        let renderer = try makeRenderer()
        renderer.blocksOnAssetLoading = false
        renderer.assetUploadBudget = 1  // every upload exhausts a frame; one still goes through
        renderer.assets = database
        let world = World()
        for i in 0..<3 {
            let id = try #require(database.id(forPath: "tri\(i).obj"))
            _ = world.spawn(Transform(), MeshRenderer(mesh: MeshHandle(AssetReference(id, subAsset: "mesh/Tri")), material: .default))
        }
        world.propagateTransforms()
        var counts: [Int] = []
        for _ in 0..<5 {
            renderer.gather(world)
            counts.append(renderer.prep.items.count)
        }
        #expect(counts == [1, 2, 3, 3, 3])
    }

    @Test func textureReimportUpdatesMaterialsAndDeletionReleasesMeshes() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let pngURL = project.assetsURL.appendingPathComponent("tile.png")
        let objURL = project.assetsURL.appendingPathComponent("tri.obj")
        try pngData([255, 0, 0, 255]).write(to: pngURL)
        try write(triangleOBJ, to: objURL)
        let database = AssetDatabase(project: project)
        database.refreshAsync()
        database.waitForAll()
        let tile = try #require(database.id(forPath: "tile.png")), tri = try #require(database.id(forPath: "tri.obj"))
        let materialJSON = #"{"texture": "\#(AssetReference(tile, subAsset: "texture").description)"}"#
        try write(materialJSON, to: project.assetsURL.appendingPathComponent("painted.material"))
        database.refreshAsync()
        database.waitForAll()
        let painted = try #require(database.id(forPath: "painted.material"))

        let renderer = try makeRenderer()
        renderer.blocksOnAssetLoading = false
        renderer.assets = database
        let world = World()
        let mesh = MeshHandle(AssetReference(tri, subAsset: "mesh/Tri")), material = MaterialHandle(AssetReference(painted))
        _ = world.spawn(Transform(), MeshRenderer(mesh: mesh, material: material))
        world.propagateTransforms()
        // Loading doesn't block: gather until the texture is in (a slow runner can need more frames).
        #expect(spin(database) { renderer.gather(world); return renderer.material(material)?.texture != nil })
        let first = try #require(renderer.material(material)?.texture)
        #expect(first.width == 2)

        // A new PNG of another size: the material gets the new GPU texture.
        try overwrite(Image(width: 4, height: 4, pixels: [UInt8](repeating: 200, count: 64)).pngData(), at: pngURL)
        database.refreshAsync()
        database.waitForAll()
        #expect(spin(database) { renderer.gather(world); return renderer.material(material)?.texture?.width == 4 })
        let second = try #require(renderer.material(material)?.texture)
        #expect(second !== first && second.width == 4)

        // Deleting the mesh's file: nothing is drawn, the GPU data is released and the key unregistered.
        try FileManager.default.removeItem(at: objURL)
        try FileManager.default.removeItem(at: objURL.appendingPathExtension("meta"))
        database.refreshAsync()
        renderer.gather(world)
        #expect(renderer.prep.items.isEmpty)
        #expect(!renderer.prep.meshes.contains(mesh.key))
        #expect(renderer.geometry(mesh) == nil)
    }
}
#endif
