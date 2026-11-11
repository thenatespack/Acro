import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Projects in the editor: New / Open Project, assets in the inspector's dropdowns.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("EditorProjectTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private let rocksOBJ = """
    o Rock
    v 0 0 0
    v 1 0 0
    v 0 1 0
    f 1 2 3
    o Pebble
    v 0 0 1
    v 1 0 1
    v 0 1 1
    f 4 5 6
    """

@MainActor private func dropdowns(in widget: Widget) -> [Dropdown] {
    (widget as? Dropdown).map { [$0] } ?? widget.children.flatMap { dropdowns(in: $0) }
}

@MainActor @Suite struct EditorProjectTests {
    @Test func scenesAreSavedOnlyInsideTheProjectOrTheStartFolder() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let start = folder.appendingPathComponent("Start")
        let outside = folder.appendingPathComponent("Elsewhere")
        try FileManager.default.createDirectory(at: start, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let session = makeSession()
        session.startFolder = start

        // Without a project: the start folder (relative paths are relative to it) and its subfolders.
        #expect(session.save(as: "loose.json"))
        #expect(FileManager.default.fileExists(atPath: start.appendingPathComponent("loose.json").path))
        #expect(session.save(as: start.appendingPathComponent("Levels/one.json").path))
        #expect(!session.save(as: outside.appendingPathComponent("away.json").path))
        #expect(!session.save(as: "../away.json"))
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("away.json").path))
        #expect(session.log.count(of: .error) == 2)

        // With a project: its folder (the project root or anywhere under it) and nowhere else.
        let project = folder.appendingPathComponent("Game")
        #expect(session.newProject(path: project.path))
        #expect(session.save(as: "main.json"))
        #expect(FileManager.default.fileExists(atPath: project.appendingPathComponent("main.json").path))
        #expect(session.save(as: project.appendingPathComponent("Assets/Scenes/level.json").path))
        #expect(session.save())
        #expect(!session.save(as: start.appendingPathComponent("loose.json").path))
        #expect(!session.save(as: outside.appendingPathComponent("away.json").path))
        #expect(session.document.url?.lastPathComponent == "level.json")

        // A scene opened from outside the project can't be saved back there; Save As into the project.
        #expect(session.open(path: start.appendingPathComponent("loose.json").path))
        session.create(.cube)
        #expect(!session.save())
        #expect(session.document.isDirty)
        #expect(session.save(as: "Assets/Scenes/loose.json"))
        #expect(!session.document.isDirty)
    }

    @Test func newProjectThenOpenProjectScansAssets() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appendingPathComponent("Game").path
        let session = makeSession()
        var notified = 0
        session.onAssetsChange = { notified += 1 }

        #expect(session.newProject(path: path))
        #expect(session.project?.name == "Game")
        #expect(session.assets?.records.isEmpty == true)
        #expect(notified == 1)
        #expect(!session.newProject(path: path))  // already a project
        #expect(session.log.count(of: .error) == 1)

        try Data(rocksOBJ.utf8).write(to: URL(fileURLWithPath: path).appendingPathComponent("Assets/rocks.obj"))
        #expect(session.openProject(path: path))
        #expect(notified == 2)
        let assets = try #require(session.assets)
        assets.waitForAll()  // projects import in the background
        let id = try #require(assets.id(forPath: "rocks.obj"))
        #expect(assets.references(of: .mesh) == [AssetReference(id, subAsset: "mesh/Rock"), AssetReference(id, subAsset: "mesh/Pebble")])
        #expect(session.log.entries.contains { $0.message.contains("Opened project Game") })

        #expect(!session.openProject(path: folder.appendingPathComponent("nothing").path))
    }

    @Test func fileChangesReachTheDatabase() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        #expect(session.newProject(path: folder.path))
        let assets = try #require(session.assets)
        let watcher = FileWatcher(directory: assets.project.assetsURL)
        try Data(rocksOBJ.utf8).write(to: assets.project.assetsURL.appendingPathComponent("rocks.obj"))
        session.assetsChanged(watcher.poll())
        #expect(assets.id(forPath: "rocks.obj") != nil)
    }

    @Test func assetChoicesListProjectAssetsAfterRegisteredKeys() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        #expect(session.newProject(path: folder.path))
        try Data(rocksOBJ.utf8).write(to: folder.appendingPathComponent("Assets/rocks.obj"))
        try Data("{}".utf8).write(to: folder.appendingPathComponent("Assets/plain.material"))
        #expect(session.openProject(path: folder.path))
        let assets = try #require(session.assets)
        assets.waitForAll()
        let rocks = try #require(assets.id(forPath: "rocks.obj"))
        let plain = try #require(assets.id(forPath: "plain.material"))
        let rock = AssetReference(rocks, subAsset: "mesh/Rock").description

        let choices = AssetChoices(meshes: { ["cube", "sphere", rock] }, materials: { ["default"] }, assets: { session.assets })
        #expect(choices.options(component: "MeshRenderer", path: "mesh")
            == ["cube", "sphere", rock, AssetReference(rocks, subAsset: "mesh/Pebble").description])
        #expect(choices.options(component: "MeshRenderer", path: "material") == ["default", AssetReference(plain, subAsset: "material").description])
        #expect(choices.title("cube") == "cube")
        #expect(choices.title(rock) == "rocks.obj › Rock")
        #expect(choices.title(AssetReference(plain, subAsset: "material").description) == "plain.material")

        // No project: only the registered keys.
        let none = AssetChoices(meshes: { ["cube"] }, materials: { ["default"] }, assets: { nil })
        #expect(none.options(component: "MeshRenderer", path: "mesh") == ["cube"])
    }

    /// The mesh dropdown shows asset titles; picking one stores the asset key (one undo step),
    /// and the scene saves the id.
    @Test func pickingAnAssetMeshStoresItsReference() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        #expect(session.newProject(path: folder.path))
        try Data(rocksOBJ.utf8).write(to: folder.appendingPathComponent("Assets/rocks.obj"))
        #expect(session.openProject(path: folder.path))
        session.assets?.waitForAll()
        let rocks = try #require(session.assets?.id(forPath: "rocks.obj"))

        let panel = InspectorPanel(session: session)
        panel.assetChoices = AssetChoices(meshes: { ["cube", "plane", "sphere"] }, materials: { ["default", "checker"] },
                                          assets: { session.assets })
        var sphere: Entity?
        session.world.query(Name.self) { entity, name in if name.value == "Blue Sphere" { sphere = entity } }
        let entity = try #require(sphere)
        session.selection.select(session.world.id(of: entity))
        panel.refresh()

        let mesh = try #require(dropdowns(in: panel.grid).first { $0.options.contains("plane") })
        #expect(mesh.options == ["cube", "plane", "sphere", "rocks.obj › Rock", "rocks.obj › Pebble"])
        #expect(mesh.selectedOption == "sphere")
        let depth = session.undo.undoDepth
        mesh.select(4)
        mesh.onChange?(4)
        let pebble = AssetReference(rocks, subAsset: "mesh/Pebble")
        #expect(session.world.get(MeshRenderer.self, for: entity)?.mesh == MeshHandle(pebble))
        #expect(session.undo.undoDepth == depth + 1)
        let saved = String(decoding: try session.world.save(), as: UTF8.self)
        #expect(saved.contains("\"mesh\" : \"\(pebble)\""))
        #expect(!saved.contains("rocks.obj"))

        _ = try session.undo.undo()
        panel.refresh()
        #expect(mesh.selectedOption == "sphere")
    }
}

// MARK: Engine version

@MainActor @Suite struct ProjectEngineVersionTests {
    @Test func openRefusesAnotherEngineVersionUnlessAllowedAndStampsIt() throws {
        let root = temporaryDirectory().appendingPathComponent("Versioned")
        var project = try Project.create(at: root)
        project.settings.engineVersion = "99.0.0"
        try project.saveSettings()

        let session = makeSession()
        #expect(ProjectOpenCommand.versionMismatch(root.path, in: session)?.saved == "99.0.0")
        #expect(throws: CommandError.self) { try session.commands.run(ProjectOpenCommand.self, .init(path: root.path)) }
        #expect(session.project == nil)
        #expect(try Project.open(at: root).settings.engineVersion == "99.0.0")  // untouched

        try session.commands.run(ProjectOpenCommand.self, .init(path: root.path, allowVersionMismatch: true))
        #expect(session.project?.root.standardizedFileURL.path == root.standardizedFileURL.path)
        #expect(try Project.open(at: root).settings.engineVersion == EngineVersion.current)
        #expect(ProjectOpenCommand.versionMismatch(root.path, in: session) == nil)
    }

    @Test func projectsWithoutAVersionOpenAndGetOne() throws {
        let root = temporaryDirectory().appendingPathComponent("Unversioned")
        let project = try Project.create(at: root)
        try Data(#"{"format": "SwiftGameEngine.Project", "name": "Old", "version": 1}"#.utf8).write(to: project.settingsURL)
        let session = makeSession()
        try session.commands.run(ProjectOpenCommand.self, .init(path: root.path))
        #expect(try Project.open(at: root).settings.engineVersion == EngineVersion.current)
    }
}
