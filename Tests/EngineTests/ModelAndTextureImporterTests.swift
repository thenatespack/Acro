import Foundation
import Testing
@testable import Engine

// TextureImporter and GLTFImporter through a real project and AssetDatabase.

private func temporaryProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ModelImporterTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Test")
}

private func copyResource(_ name: String, to project: Project, as path: String? = nil) throws {
    let source = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Resources/glTF"))
    let destination = project.assetsURL.appendingPathComponent(path ?? name)
    try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: source, to: destination)
}

private func checkerPNG() -> Data {
    var pixels: [UInt8] = []
    for y in 0..<4 { for x in 0..<4 { pixels += (x + y) % 2 == 0 ? [255, 0, 0, 255] : [0, 0, 255, 255] } }
    return Image(width: 4, height: 4, pixels: pixels).pngData()
}

/// A one-triangle .gltf whose material's base color texture is the external image `imageURI`.
private func triangleGLTF(imageURI: String) -> String {
    let positions: [Float] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
    let base64 = positions.withUnsafeBytes { Data($0) }.base64EncodedString()
    return """
        {
          "asset": {"version": "2.0"},
          "buffers": [{"byteLength": 36, "uri": "data:application/octet-stream;base64,\(base64)"}],
          "bufferViews": [{"buffer": 0, "byteLength": 36}],
          "accessors": [{"bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3", "min": [0, 0, 0], "max": [1, 1, 0]}],
          "images": [{"uri": "\(imageURI)"}],
          "textures": [{"source": 0}],
          "materials": [{"name": "Painted", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}}}],
          "meshes": [{"name": "Tri", "primitives": [{"attributes": {"POSITION": 0}, "material": 0}]}],
          "nodes": [{"name": "Root", "mesh": 0}],
          "scenes": [{"nodes": [0]}],
          "scene": 0
        }
        """
}

@MainActor
@Suite struct ModelAndTextureImporterTests {
    @Test func pngImportsAsATextureWithItsSettings() throws {
        let project = try temporaryProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try checkerPNG().write(to: project.assetsURL.appendingPathComponent("checker.png"))
        let database = AssetDatabase(project: project)
        let report = database.refresh()
        #expect(report.errors.isEmpty)

        let id = try #require(database.id(forPath: "checker.png"))
        var texture = try #require(database.texture(AssetReference(id)))
        #expect(texture.image.width == 4 && texture.image.height == 4)
        #expect(Array(texture.image.pixels.prefix(8)) == [255, 0, 0, 255, 0, 0, 255, 255])
        #expect(texture.isSRGB && texture.generatesMipmaps)

        try database.setSettings(TextureImporter.Settings(sRGB: false, mipmaps: false), for: id)
        texture = try #require(database.texture(AssetReference(id)))
        #expect(!texture.isSRGB && !texture.generatesMipmaps)
    }

    @Test func glbImportsMeshesTexturesMaterialsAndAPrefab() throws {
        let project = try temporaryProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try copyResource("TextureCoordinateTest.glb", to: project)
        let database = AssetDatabase(project: project)
        let report = database.refresh()
        #expect(report.errors.isEmpty)

        let id = try #require(database.id(forPath: "TextureCoordinateTest.glb"))
        let asset = try #require(database.asset(id))
        let kinds = Dictionary(grouping: asset.objects, by: \.kind).mapValues(\.count)
        #expect(kinds[.mesh, default: 0] > 0)
        #expect(kinds[.material, default: 0] > 0)
        #expect(kinds[.texture, default: 0] > 0)
        #expect(kinds[.prefab] == 1)

        // Embedded textures are decoded, sRGB for base color; materials reference them.
        let textured = asset.objects.compactMap { object -> MaterialAsset? in
            if case .material(let material) = object.value, material.texture != nil { return material }
            return nil
        }
        #expect(!textured.isEmpty)
        for material in textured {
            let texture = try #require(database.texture(material.texture!))
            #expect(texture.isSRGB)
            #expect(texture.image.width > 0)
        }

        // The prefab (the main object) spawns one MeshRenderer per primitive, all resolvable.
        let prefab = try #require(database.prefab(AssetReference(id)))
        let world = World()
        let roots = world.instantiate(prefab)
        #expect(roots.count == 1)
        let model = try GLTFReader.read(contentsOf: try #require(
            Bundle.module.url(forResource: "TextureCoordinateTest.glb", withExtension: nil, subdirectory: "Resources/glTF")))
        var renderers: [MeshRenderer] = []
        world.query(MeshRenderer.self) { _, renderer in renderers.append(renderer) }
        #expect(renderers.count == model.meshes.reduce(0) { $0 + $1.primitives.count })
        for renderer in renderers {
            let mesh = try #require(renderer.mesh.assetReference)
            let material = try #require(renderer.material.assetReference)
            #expect(database.mesh(mesh) != nil)
            #expect(database.material(material) != nil)
        }
    }

    @Test func gltfWithAnExternalBufferImports() throws {
        let project = try temporaryProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try copyResource("BoxInterleaved.gltf", to: project, as: "Models/BoxInterleaved.gltf")
        try copyResource("BoxInterleaved.bin", to: project, as: "Models/BoxInterleaved.bin")
        let database = AssetDatabase(project: project)
        let report = database.refresh()
        #expect(report.errors.isEmpty)

        let id = try #require(database.id(forPath: "Models/BoxInterleaved.gltf"))
        let mesh = try #require(database.mesh(AssetReference(id)))
        #expect(mesh.indices.count == 36)
        // The .bin is an asset too (it gets an id), but nothing imports it.
        #expect(database.id(forPath: "Models/BoxInterleaved.bin") != nil)
    }

    @Test func externalImagesThatAreProjectAssetsAreReferencedNotCopied() throws {
        let project = try temporaryProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let folder = project.assetsURL.appendingPathComponent("Props")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try checkerPNG().write(to: folder.appendingPathComponent("paint job.png"))
        try Data(triangleGLTF(imageURI: "paint%20job.png").utf8).write(to: folder.appendingPathComponent("tri.gltf"))
        let database = AssetDatabase(project: project)
        let report = database.refresh()
        #expect(report.errors.isEmpty)

        let model = try #require(database.id(forPath: "Props/tri.gltf"))
        let image = try #require(database.id(forPath: "Props/paint job.png"))
        let asset = try #require(database.asset(model))
        #expect(!asset.objects.contains { $0.kind == .texture })
        let material = try #require(database.material(AssetReference(model)))
        #expect(material.texture == AssetReference(image, subAsset: "texture"))
        #expect(database.texture(material.texture!) != nil)

        let prefab = try #require(database.prefab(AssetReference(model)))
        #expect(prefab.roots.first?.material == AssetReference(model, subAsset: "material/Painted"))
    }
}
