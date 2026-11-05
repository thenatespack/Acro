import Foundation
import Testing
@testable import Engine

// Projects, sidecars, the asset database, asset handles and the file watcher. Every test works
// in its own temporary folder.

private let triangleOBJ = """
    # one triangle
    o Tri
    v 0 0 0
    v 1 0 0
    v 0 1 0
    vt 0 0
    vt 1 0
    vt 0 1
    f 1/1 2/2 3/3
    """

private let twoObjectsOBJ = """
    o Rock
    v 0 0 0
    v 1 0 0
    v 1 1 0
    v 0 1 0
    vn 0 0 1
    f 1//1 2//1 3//1 4//1
    o Pebble
    v 0 0 1
    v 1 0 1
    v 0 1 1
    f -3 -2 -1
    """

/// A fresh temporary folder, removed by `cleanup`.
private func temporaryFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AssetDatabaseTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url)
}

/// A test importer that counts its runs: `.count` files hold a number, imported as a mesh with
/// that many triangles. `Settings.scale` multiplies positions.
private struct CountingImporter: AssetImporter {
    struct Settings: Codable, Equatable, Sendable {
        var scale: Float = 1
    }

    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        var count: Int { lock.withLock { value } }
        func increment() { lock.withLock { value += 1 } }
    }

    let counter: Counter
    var version = 1
    var name: String { "counting" }
    var fileExtensions: [String] { ["count"] }
    var defaultSettings: Settings { Settings() }

    func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        counter.increment()
        let text = String(decoding: try context.data(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Int(text) else { throw AssetError.unreadable("not a number") }
        var geometry = MeshGeometry(vertices: [], indices: [])
        for i in 0..<n {
            let base = UInt32(geometry.vertices.count), x = Float(i) * settings.scale
            for p in [Vec3(x, 0, 0), Vec3(x + settings.scale, 0, 0), Vec3(x, settings.scale, 0)] {
                geometry.vertices.append(MeshVertex(position: p, normal: Vec3(0, 0, 1)))
            }
            geometry.indices += [base, base + 1, base + 2]
        }
        try Data("artifact".utf8).write(to: context.artifactsDirectory.appendingPathComponent("note.txt"))
        var asset = ImportedAsset()
        asset.add("mesh/main", .mesh(geometry))
        asset.add("material", .material(MaterialAsset(baseColor: Vec4(1, 0, 0, 1))))
        return asset
    }
}

@MainActor
private func makeProject() throws -> (Project, URL) {
    let folder = try temporaryFolder()
    return (try Project.create(at: folder.appendingPathComponent("Game")), folder)
}

@MainActor
private func database(_ project: Project, counter: CountingImporter.Counter? = nil, version: Int = 1) -> AssetDatabase {
    var importers = AssetImporterRegistry.builtIn
    if let counter { importers.register(CountingImporter(counter: counter, version: version)) }
    return AssetDatabase(project: project, importers: importers)
}

@MainActor @Suite struct ProjectTests {
    @Test func createMakesTheLayoutAndOpenReadsIt() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("My Game")
        let project = try Project.create(at: url)
        let fm = FileManager.default
        #expect(fm.fileExists(atPath: url.appendingPathComponent("Project.json").path))
        #expect(fm.fileExists(atPath: url.appendingPathComponent("Assets").path))
        #expect(fm.fileExists(atPath: url.appendingPathComponent("Library").path))
        let gitignore = try String(contentsOf: url.appendingPathComponent(".gitignore"), encoding: .utf8)
        #expect(gitignore.contains("/Library/"))
        #expect(project.name == "My Game")

        let text = try String(contentsOf: project.settingsURL, encoding: .utf8)
        #expect(text == "{\n  \"engineVersion\" : \"\(EngineVersion.current)\",\n  \"format\" : \"Acro.Project\",\n  \"name\" : \"My Game\",\n  \"version\" : 1\n}\n")

        let opened = try Project.open(at: url)
        #expect(opened.settings == project.settings)
        #expect(try Project.open(at: url.appendingPathComponent("Project.json")).root == opened.root)
        #expect(Project.exists(at: url))

        #expect(throws: AssetError.projectExists(project.root.path)) { try Project.create(at: url) }
        #expect(throws: AssetError.self) { try Project.open(at: folder) }
    }

    @Test func openRecreatesAMissingLibrary() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.removeItem(at: project.libraryURL)
        _ = try Project.open(at: project.root)
        #expect(FileManager.default.fileExists(atPath: project.libraryURL.path))
    }

    @Test func newerProjectVersionIsRejected() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try write("{\"format\": \"SwiftGameEngine.Project\", \"version\": 99}", to: folder.appendingPathComponent("Project.json"))
        #expect(throws: AssetError.unsupportedProjectVersion(99)) { try Project.open(at: folder) }
    }
}

@MainActor @Suite struct AssetDatabaseTests {
    @Test func scanCreatesStableSidecars() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("Models/tri.obj"))
        try write("notes", to: project.assetsURL.appendingPathComponent("readme.txt"))
        try write("hidden", to: project.assetsURL.appendingPathComponent(".DS_Store"))

        let assets = database(project)
        let report = assets.refresh()
        #expect(report.createdSidecars == ["Models/tri.obj", "readme.txt"])
        #expect(report.added.count == 2)
        #expect(report.imported.count == 1)  // the .txt has no importer but still has an id
        #expect(!FileManager.default.fileExists(atPath: project.assetsURL.appendingPathComponent(".DS_Store.meta").path))

        let sidecarURL = project.assetsURL.appendingPathComponent("Models/tri.obj.meta")
        let sidecar = try AssetSidecar.read(from: sidecarURL)
        #expect(sidecar.importer == "obj")
        #expect(assets.id(forPath: "Models/tri.obj") == sidecar.id)
        let text = try String(contentsOf: sidecarURL, encoding: .utf8)
        #expect(text == """
            {
              "id" : "\(sidecar.id)",
              "importer" : "obj",
              "settings" : {
                "flipV" : true,
                "scale" : 1
              },
              "version" : 1
            }

            """)
        let txt = try AssetSidecar.read(from: project.assetsURL.appendingPathComponent("readme.txt.meta"))
        #expect(txt.importer == nil && txt.settings == nil)

        // A second scan neither rewrites sidecars nor reimports.
        let modified = try FileManager.default.attributesOfItem(atPath: sidecarURL.path)[.modificationDate] as? Date
        let again = database(project).refresh()
        #expect(again.createdSidecars.isEmpty && again.added.isEmpty && again.imported.isEmpty)
        #expect(again.upToDate == 1)
        #expect(try FileManager.default.attributesOfItem(atPath: sidecarURL.path)[.modificationDate] as? Date == modified)
    }

    @Test func renameAndMoveKeepTheID() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let fm = FileManager.default
        let original = project.assetsURL.appendingPathComponent("tri.obj")
        try write(triangleOBJ, to: original)
        let counter = CountingImporter.Counter()
        let assets = database(project, counter: counter)
        assets.refresh()
        let id = try #require(assets.id(forPath: "tri.obj"))

        // Move file and sidecar together into a subfolder, renamed.
        try fm.createDirectory(at: project.assetsURL.appendingPathComponent("Moved"), withIntermediateDirectories: true)
        let moved = project.assetsURL.appendingPathComponent("Moved/triangle.obj")
        try fm.moveItem(at: original, to: moved)
        try fm.moveItem(at: AssetSidecar.url(for: original), to: AssetSidecar.url(for: moved))
        let report = assets.refresh()
        #expect(report.moved.count == 1)
        #expect(report.moved.first?.id == id && report.moved.first?.from == "tri.obj" && report.moved.first?.to == "Moved/triangle.obj")
        #expect(report.added.isEmpty && report.removed.isEmpty && report.imported.isEmpty)
        #expect(assets.id(forPath: "Moved/triangle.obj") == id)
        #expect(assets.id(forPath: "tri.obj") == nil)
        #expect(assets.mesh(AssetReference(id)) != nil)

        // A fresh database (new session) sees the same id at the new path, without reimporting.
        let reopened = database(project)
        let second = reopened.refresh()
        #expect(second.moved.isEmpty && second.imported.isEmpty)
        #expect(reopened.id(forPath: "Moved/triangle.obj") == id)
    }

    @Test func fileMovedWithoutItsSidecarGetsItBack() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let original = project.assetsURL.appendingPathComponent("tri.obj")
        try write(triangleOBJ, to: original)
        let assets = database(project)
        assets.refresh()
        let id = try #require(assets.id(forPath: "tri.obj"))

        // Moved by a tool that doesn't know about sidecars: the orphan follows its content.
        let moved = project.assetsURL.appendingPathComponent("Elsewhere/tri.obj")
        try FileManager.default.createDirectory(at: moved.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: original, to: moved)
        let report = assets.refresh()
        #expect(report.orphanedSidecars.isEmpty && report.createdSidecars.isEmpty)
        #expect(assets.id(forPath: "Elsewhere/tri.obj") == id)
        #expect(FileManager.default.fileExists(atPath: AssetSidecar.url(for: moved).path))
        #expect(!FileManager.default.fileExists(atPath: AssetSidecar.url(for: original).path))
    }

    @Test func duplicatedSidecarGetsAFreshID() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let fm = FileManager.default
        let original = project.assetsURL.appendingPathComponent("b.obj")
        try write(triangleOBJ, to: original)
        let assets = database(project)
        assets.refresh()
        let id = try #require(assets.id(forPath: "b.obj"))

        // Copy file and sidecar; the copy sorts before the original, but the original keeps the id.
        let copy = project.assetsURL.appendingPathComponent("a copy.obj")
        try fm.copyItem(at: original, to: copy)
        try fm.copyItem(at: AssetSidecar.url(for: original), to: AssetSidecar.url(for: copy))
        let report = assets.refresh()
        #expect(report.reassigned.count == 1)
        #expect(report.reassigned.first?.path == "a copy.obj" && report.reassigned.first?.old == id)
        #expect(assets.id(forPath: "b.obj") == id)
        let copyID = try #require(assets.id(forPath: "a copy.obj"))
        #expect(copyID != id)
        #expect(try AssetSidecar.read(from: AssetSidecar.url(for: copy)).id == copyID)
        #expect(report.added == [copyID])
        #expect(report.imported == [copyID])

        // Without a Library (fresh clone), the first path in sorted order keeps the id.
        let other = try makeProject()
        defer { try? FileManager.default.removeItem(at: other.1) }
        for name in ["x.obj", "y.obj"] {
            try write(triangleOBJ, to: other.0.assetsURL.appendingPathComponent(name))
            try AssetSidecar(id: id, importer: "obj").write(to: AssetSidecar.url(for: other.0.assetsURL.appendingPathComponent(name)))
        }
        let fresh = database(other.0)
        #expect(fresh.refresh().reassigned.map(\.path) == ["y.obj"])
        #expect(fresh.id(forPath: "x.obj") == id)
    }

    @Test func orphanedSidecarsAreDeletedOrReported() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("gone.obj")
        try write(triangleOBJ, to: file)
        let assets = database(project)
        assets.refresh()
        let id = try #require(assets.id(forPath: "gone.obj"))
        #expect(FileManager.default.fileExists(atPath: assets.artifactsURL(id).path))

        // A stray sidecar with no file, reported only.
        let stray = project.assetsURL.appendingPathComponent("stray.png.meta")
        try AssetSidecar(id: .random()).write(to: stray)
        assets.orphanPolicy = .report
        #expect(assets.refresh().orphanedSidecars == ["stray.png.meta"])
        #expect(FileManager.default.fileExists(atPath: stray.path))

        // The file is deleted: its asset is removed with its cache, and both orphans deleted.
        try FileManager.default.removeItem(at: file)
        assets.orphanPolicy = .delete
        let report = assets.refresh()
        #expect(report.removed.map(\.id) == [id])
        #expect(report.orphanedSidecars.sorted() == ["gone.obj.meta", "stray.png.meta"])
        #expect(!FileManager.default.fileExists(atPath: stray.path))
        #expect(!FileManager.default.fileExists(atPath: AssetSidecar.url(for: file).path))
        #expect(!FileManager.default.fileExists(atPath: assets.artifactsURL(id).path))
        #expect(assets.record(id) == nil)
    }

    @Test func unreadableSidecarIsReportedAndLeftAlone() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("tri.obj")
        try write(triangleOBJ, to: file)
        let conflict = "<<<<<<< HEAD\n{}\n>>>>>>> branch\n"
        try write(conflict, to: AssetSidecar.url(for: file))
        let assets = database(project)
        let report = assets.refresh()
        #expect(report.errors.map(\.path) == ["tri.obj.meta"])
        #expect(assets.id(forPath: "tri.obj") == nil)
        #expect(try String(contentsOf: AssetSidecar.url(for: file), encoding: .utf8) == conflict)
    }

    @Test func reimportIsSkippedUnlessSourceSettingsOrVersionChange() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("tris.count")
        try write("2", to: file)
        let counter = CountingImporter.Counter()
        let assets = database(project, counter: counter)
        assets.refresh()
        #expect(counter.count == 1)
        let id = try #require(assets.id(forPath: "tris.count"))
        #expect(assets.mesh(AssetReference(id))?.indices.count == 6)
        let artifact = assets.artifactsURL(id).appendingPathComponent("files/note.txt")
        #expect(FileManager.default.fileExists(atPath: artifact.path))

        // Unchanged: nothing runs, in this session or a new one (which loads the Library cache).
        assets.refresh()
        #expect(counter.count == 1)
        let fresh = database(project, counter: counter)
        #expect(fresh.refresh().upToDate == 1)
        #expect(fresh.mesh(AssetReference(id))?.indices.count == 6)
        #expect(fresh.material(AssetReference(id))?.baseColor == Vec4(1, 0, 0, 1))
        #expect(counter.count == 1)

        // Touching the file without changing it rehashes but doesn't reimport.
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 10)], ofItemAtPath: file.path)
        fresh.refresh()
        #expect(counter.count == 1)

        // New content: reimport.
        let before = fresh.revision(of: id)
        try write("3", to: file)
        #expect(fresh.refresh().imported == [id])
        #expect(counter.count == 2)
        #expect(fresh.mesh(AssetReference(id))?.indices.count == 9)
        #expect(fresh.revision(of: id) > before)

        // New settings (written through the database or by hand): reimport.
        try fresh.setSettings(CountingImporter.Settings(scale: 2), for: id)
        #expect(counter.count == 3)
        #expect(fresh.settings(of: id, as: CountingImporter.Settings.self)?.scale == 2)
        #expect(fresh.mesh(AssetReference(id))?.vertices[1].position.x == 2)
        fresh.refresh()
        #expect(counter.count == 3)

        // A new importer version: reimport.
        let upgraded = database(project, counter: counter, version: 2)
        #expect(upgraded.refresh().imported == [id])
        #expect(counter.count == 4)

        // A deleted Library: reimport.
        try FileManager.default.removeItem(at: project.libraryURL)
        let rebuilt = database(project, counter: counter, version: 2)
        rebuilt.refresh()
        #expect(counter.count == 5)
    }

    @Test func failedImportIsReportedAndKeepsThePreviousResult() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("tris.count")
        try write("1", to: file)
        let counter = CountingImporter.Counter()
        let assets = database(project, counter: counter)
        assets.refresh()
        let id = try #require(assets.id(forPath: "tris.count"))
        try write("not a number", to: file)
        let report = assets.refresh()
        #expect(report.errors.map(\.path) == ["tris.count"])
        #expect(assets.record(id)?.importError != nil)
        #expect(assets.mesh(AssetReference(id))?.indices.count == 3)
        // A new session still has the last good import.
        let next = database(project, counter: counter)
        next.refresh()
        #expect(next.mesh(AssetReference(id))?.indices.count == 3)
        #expect(counter.count == 2)
    }

    @Test func settingsMissingFromTheSidecarGetDefaults() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("big.obj")
        try write(triangleOBJ, to: file)
        let id = AssetID.random()
        // Hand-written: only some keys.
        try write("{\"id\": \"\(id)\", \"settings\": {\"scale\": 10}}", to: AssetSidecar.url(for: file))
        let assets = database(project)
        assets.refresh()
        #expect(assets.id(forPath: "big.obj") == id)
        #expect(assets.settings(of: id, as: OBJImporter.Settings.self) == OBJImporter.Settings(scale: 10, flipV: true))
        #expect(assets.mesh(AssetReference(id))?.vertices.map(\.position).contains(Vec3(10, 0, 0)) == true)
    }

    @Test func objImportsSubAssetsWithStableIDsAndAPrefab() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        try write(twoObjectsOBJ, to: project.assetsURL.appendingPathComponent("rocks.obj"))
        let assets = database(project)
        assets.refresh()
        let id = try #require(assets.id(forPath: "rocks.obj"))
        #expect(assets.record(id)?.objects.map(\.id) == ["mesh/Rock", "mesh/Pebble", "prefab/rocks"])

        let rock = try #require(assets.mesh(AssetReference(id, subAsset: "mesh/Rock")))
        #expect(rock.indices.count == 6)  // a quad as a fan
        #expect(rock.vertices.allSatisfy { $0.normal == Vec3(0, 0, 1) })
        let pebble = try #require(assets.mesh(AssetReference(id, subAsset: "mesh/Pebble")))
        #expect(pebble.indices.count == 3 && pebble.vertices[0].position == Vec3(0, 0, 1))
        // No sub-asset: the first mesh. Wrong kind: nil.
        #expect(assets.mesh(AssetReference(id))?.indices.count == 6)
        #expect(assets.material(AssetReference(id, subAsset: "mesh/Rock")) == nil)
        #expect(assets.displayName(of: AssetReference(id, subAsset: "mesh/Pebble")) == "rocks.obj › Pebble")
        #expect(assets.references(of: .mesh).map(\.subAsset) == ["mesh/Rock", "mesh/Pebble"])

        // The prefab spawns a hierarchy whose renderers reference the meshes by id.
        let prefab = try #require(assets.prefab(AssetReference(id)))
        let world = World()
        let roots = world.instantiate(prefab)
        #expect(roots.count == 1)
        let children = world.children(of: roots[0])
        #expect(children.map { world.get(Name.self, for: $0)?.value } == ["Rock", "Pebble"])
        #expect(world.get(MeshRenderer.self, for: children[0])?.mesh == MeshHandle(AssetReference(id, subAsset: "mesh/Rock")))

        // Reordering the objects in the source keeps their ids.
        try write(twoObjectsOBJ.replacingOccurrences(of: "o Rock", with: "o Rock2").replacingOccurrences(of: "o Pebble", with: "o Rock"),
                  to: project.assetsURL.appendingPathComponent("rocks.obj"))
        assets.refresh()
        #expect(assets.mesh(AssetReference(id, subAsset: "mesh/Rock"))?.indices.count == 3)
    }

    @Test func subAssetNamerFollowsTheConvention() {
        var namer = SubAssetNamer()
        #expect(namer.id(kind: "mesh", name: "Rock", index: 0) == "mesh/Rock")
        #expect(namer.id(kind: "mesh", name: nil, index: 1) == "mesh/1")
        #expect(namer.id(kind: "mesh", name: "Rock", index: 2) == "mesh/Rock~2")
        #expect(namer.id(kind: "material", name: "Rock", index: 0) == "material/Rock")
        #expect(namer.id(kind: "mesh", name: "  ", index: 4) == "mesh/4")
    }

    @Test func materialFilesReferenceTextures() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let texture = AssetReference(.random(), subAsset: "texture")
        try write("{\"baseColor\": [0.5, 0.25, 1, 1], \"texture\": \"\(texture)\", \"filter\": \"nearest\"}",
                  to: project.assetsURL.appendingPathComponent("red.material"))
        let assets = database(project)
        assets.refresh()
        let id = try #require(assets.id(forPath: "red.material"))
        let material = try #require(assets.material(AssetReference(id)))
        #expect(material.baseColor == Vec4(0.5, 0.25, 1, 1))
        #expect(material.texture == texture)
        #expect(material.filter == .nearest && material.specular == 0.35)
    }

    @Test func importContextResolvesRelativePaths() {
        let a = AssetID.random(), b = AssetID.random()
        let context = ImportContext(assetID: .random(), sourceURL: URL(fileURLWithPath: "/x"), assetPath: "Models/car/car.gltf",
                                    artifactsDirectory: URL(fileURLWithPath: "/y"),
                                    assetsByPath: ["Models/car/tex/paint.png": a, "Models/shared.png": b])
        #expect(context.asset(atRelativePath: "tex/paint.png") == a)
        #expect(context.asset(atRelativePath: "./tex/paint.png") == a)
        #expect(context.asset(atRelativePath: "../shared.png") == b)
        #expect(context.asset(atRelativePath: "missing.png") == nil)
    }
}

@MainActor @Suite struct AssetHandleTests {
    @Test func idsAndReferencesRoundTripAsText() throws {
        let id = AssetID(high: 0x5f1c_0e9a_8b7d_4c3e, low: 0x2f1a_0b9c_8d7e_6f50)
        #expect(id.description == "5f1c0e9a8b7d4c3e2f1a0b9c8d7e6f50")
        #expect(AssetID("5F1C0E9A-8B7D-4C3E-2F1A-0B9C8D7E6F50") == id)
        #expect(AssetID("xyz") == nil)
        let reference = AssetReference(id, subAsset: "mesh/Rock#1")
        #expect(reference.description == "asset:5f1c0e9a8b7d4c3e2f1a0b9c8d7e6f50#mesh/Rock#1")
        #expect(AssetReference(reference.description) == reference)
        #expect(AssetReference("asset:\(id)") == AssetReference(id))
        #expect(AssetReference("cube") == nil)
        #expect(AssetReference("asset:nope") == nil)
    }

    @Test func handlesEncodeKeysAndAssetReferencesAsStrings() throws {
        let id = AssetID.random()
        let renderer = MeshRenderer(mesh: MeshHandle(AssetReference(id, subAsset: "mesh/Rock")),
                                    material: MaterialHandle(AssetReference(id)))
        let json = String(decoding: try JSONEncoder().encode(renderer), as: UTF8.self)
        #expect(json.contains("\"mesh\":\"asset:\(id)#mesh\\/Rock\""))
        #expect(json.contains("\"material\":\"asset:\(id)\""))
        let decoded = try JSONDecoder().decode(MeshRenderer.self, from: Data(json.utf8))
        #expect(decoded == renderer)
        #expect(decoded.mesh.assetReference == AssetReference(id, subAsset: "mesh/Rock"))

        // Old-style keys stay exactly as they were.
        let plain = try JSONDecoder().decode(MeshHandle.self, from: Data("\"cube\"".utf8))
        #expect(plain == .cube && plain.assetReference == nil)
        #expect(String(decoding: try JSONEncoder().encode(MaterialHandle.default), as: UTF8.self) == "\"default\"")
    }

    /// A scene saved before asset references existed loads unchanged and saves back identically;
    /// a scene with references saves ids, not paths.
    @Test func oldScenesStillLoadAndAssetScenesStoreIDs() throws {
        let old = """
            {
              "entities" : [
                {
                  "components" : {
                    "MeshRenderer" : {
                      "castsShadows" : true,
                      "isVisible" : true,
                      "material" : "checker",
                      "mesh" : "cube",
                      "opacity" : 1,
                      "receivesShadows" : true,
                      "tint" : [1, 1, 1]
                    },
                    "Transform" : {
                      "position" : [0, 1, 0],
                      "rotation" : [0, 0, 0, 1],
                      "scale" : [1, 1, 1]
                    }
                  },
                  "id" : 0
                }
              ],
              "format" : "Acro.Scene",
              "version" : 1
            }
            """
        ComponentRegistry.register(MeshRenderer.self)   // not built in: scene loading resolves it by name
        let world = World()
        let roots = try world.load(Data(old.utf8))
        let renderer = try #require(world.get(MeshRenderer.self, for: roots[0]))
        #expect(renderer.mesh == .cube && renderer.material == MaterialHandle("checker"))

        let id = AssetID.random()
        world.modify(MeshRenderer.self, for: roots[0]) { $0.mesh = MeshHandle(AssetReference(id, subAsset: "mesh/Rock")) }
        let saved = String(decoding: try world.save(), as: UTF8.self)
        #expect(saved.contains("\"mesh\" : \"asset:\(id)#mesh/Rock\""))
        let again = World()
        let loaded = try again.load(Data(saved.utf8))
        #expect(again.get(MeshRenderer.self, for: loaded[0])?.mesh.assetReference == AssetReference(id, subAsset: "mesh/Rock"))
    }
}

@Suite struct FileWatcherTests {
    @Test func pollingReportsCreateModifyRenameDelete() throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let fm = FileManager.default
        try write("a", to: folder.appendingPathComponent("a.txt"))
        try write("b", to: folder.appendingPathComponent("sub/b.txt"))
        let watcher = FileWatcher(directory: folder)
        #expect(watcher.poll().isEmpty)

        try write("c", to: folder.appendingPathComponent("sub/c.txt"))
        try write("hidden", to: folder.appendingPathComponent(".hidden"))
        #expect(watcher.poll() == [FileChange(.created, "sub/c.txt")])

        try write("a, longer", to: folder.appendingPathComponent("a.txt"))
        #expect(watcher.poll() == [FileChange(.modified, "a.txt")])

        try fm.moveItem(at: folder.appendingPathComponent("sub/b.txt"), to: folder.appendingPathComponent("renamed.txt"))
        #expect(watcher.poll() == [FileChange(.renamed(from: "sub/b.txt"), "renamed.txt")])

        try fm.removeItem(at: folder.appendingPathComponent("sub/c.txt"))
        #expect(watcher.poll() == [FileChange(.deleted, "sub/c.txt")])
        #expect(watcher.poll().isEmpty)
    }

    @MainActor @Test func startedWatcherDeliversOnTheMainActor() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let watcher = FileWatcher(directory: folder)
        final class Box: @unchecked Sendable { var changes: [FileChange] = [] }
        let box = Box()
        watcher.start(interval: 0.05) { box.changes += $0 }
        defer { watcher.stop() }
        try write("x", to: folder.appendingPathComponent("x.txt"))
        for _ in 0..<100 where box.changes.isEmpty { try await Task.sleep(for: .milliseconds(20)) }
        #expect(box.changes == [FileChange(.created, "x.txt")])
    }

    @MainActor @Test func changesFeedTheDatabase() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = database(project)
        assets.refresh()
        let watcher = FileWatcher(directory: project.assetsURL)
        try write(triangleOBJ, to: project.assetsURL.appendingPathComponent("new.obj"))
        let changes = watcher.poll()
        #expect(changes == [FileChange(.created, "new.obj")])
        let report = assets.reimport(changed: changes)
        #expect(report.imported.count == 1)
        #expect(assets.id(forPath: "new.obj") != nil)
        // The sidecar the scan wrote shows up as the next change.
        #expect(watcher.poll() == [FileChange(.created, "new.obj.meta")])
    }
}

#if os(macOS)
import QuartzCore

/// Asset handles through a real `SceneRenderer` (Metal, no window).
@MainActor @Suite struct SceneRendererAssetTests {
    @Test func assetHandlesUploadOnFirstUseAndFollowReimports() throws {
        let (project, folder) = try makeProject()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = project.assetsURL.appendingPathComponent("tris.count")
        try write("1", to: file)
        let counter = CountingImporter.Counter()
        let assets = database(project, counter: counter)
        assets.refresh()
        let id = try #require(assets.id(forPath: "tris.count"))

        let device = try MetalRenderDevice(layer: CAMetalLayer(), sampleCount: 1)
        let renderer = try SceneRenderer(device: device, quality: .low)
        renderer.blocksOnAssetLoading = true  // the first frame waits for the import (see AssetLoadingTests for async)
        let world = World()
        let mesh = MeshHandle(AssetReference(id, subAsset: "mesh/main"))
        let material = MaterialHandle(AssetReference(id))
        let entity = world.spawn(Transform(), MeshRenderer(mesh: mesh, material: material))
        world.propagateTransforms()

        // Without a database the keys are just missing.
        renderer.gather(world)
        #expect(renderer.prep.items.isEmpty)

        renderer.assets = assets
        renderer.gather(world)
        #expect(renderer.prep.items.count == 1)
        #expect(renderer.mesh(mesh)?.indexCount == 3)
        #expect(renderer.material(material)?.baseColor == Vec4(1, 0, 0, 1))
        // Built-ins keep working next to assets.
        world.spawn(Transform(), MeshRenderer(mesh: .cube))
        world.propagateTransforms()
        renderer.gather(world)
        #expect(renderer.prep.items.count == 2)

        // Reimport: the next frame re-uploads under the same key.
        try write("4", to: file)
        assets.refresh()
        renderer.gather(world)
        #expect(renderer.geometry(mesh)?.indices.count == 12)

        // Unknown sub-assets stay missing without retrying every frame.
        world.modify(MeshRenderer.self, for: entity) { $0.mesh = MeshHandle(AssetReference(id, subAsset: "mesh/nope")) }
        renderer.gather(world)
        #expect(renderer.prep.items.count == 1)
        #expect(renderer.failedAssetKeys.contains(AssetReference(id, subAsset: "mesh/nope").description))
    }
}
#endif
