import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Import…: copying files and folders from outside the project into Assets/ and importing them.

@MainActor private func makeProject() throws -> (EditorSession, URL, URL) {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("AssetImportTests-\(UUID().uuidString)")
    let outside = root.appendingPathComponent("Downloads")
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    #expect(session.newProject(path: root.appendingPathComponent("Game").path))
    return (session, root, outside)
}

private let glTFResources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("EngineTests/Resources/glTF")

private let triangleOBJ = "o Tri\nv 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n"

@MainActor @Suite struct AssetImportTests {
    @Test func importCopiesIntoTheCurrentFolderImportsAndSelects() throws {
        let (session, root, outside) = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = outside.appendingPathComponent("tri.obj")
        try Data(triangleOBJ.utf8).write(to: source)
        let model = AssetBrowserModel(session: session)
        _ = model.newFolder()
        model.folder = "New Folder"

        let paths = model.importFiles([source])
        #expect(paths == ["New Folder/tri.obj"])
        let assets = try #require(session.assets)
        assets.waitForAll()
        let id = try #require(assets.id(forPath: "New Folder/tri.obj"))
        #expect(model.selection == .asset(id))
        #expect(assets.mesh(AssetReference(id)) != nil)
        #expect(FileManager.default.fileExists(atPath: source.path), "the original stays where it was")

        // Importing the same file again gets a fresh name and a different id.
        #expect(model.importFiles([source]) == ["New Folder/tri 2.obj"])
        assets.waitForAll()
        #expect(assets.id(forPath: "New Folder/tri 2.obj") != id)
    }

    @Test func gltfBringsItsExternalBufferAndSharesIdenticalCopies() throws {
        let (session, root, outside) = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        for name in ["BoxInterleaved.gltf", "BoxInterleaved.bin"] {
            try FileManager.default.copyItem(at: glTFResources.appendingPathComponent(name), to: outside.appendingPathComponent(name))
        }
        let assets = try #require(session.assets)
        #expect(session.importAssets([outside.appendingPathComponent("BoxInterleaved.gltf")], into: "Models") == ["Models/BoxInterleaved.gltf"])
        assets.waitForAll()
        #expect(FileManager.default.fileExists(atPath: session.project!.url(forAssetPath: "Models/BoxInterleaved.bin").path))
        let id = try #require(assets.id(forPath: "Models/BoxInterleaved.gltf"))
        #expect(assets.mesh(AssetReference(id))?.indices.count == 36)

        // A second copy of the same model reuses the identical .bin.
        #expect(session.importAssets([outside.appendingPathComponent("BoxInterleaved.gltf")], into: "Models") == ["Models/BoxInterleaved 2.gltf"])
        assets.waitForAll()
        let second = try #require(assets.id(forPath: "Models/BoxInterleaved 2.gltf"))
        #expect(assets.mesh(AssetReference(second))?.indices.count == 36)

        // A different .bin under the same name is refused, and nothing is copied.
        let other = outside.appendingPathComponent("other")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: glTFResources.appendingPathComponent("BoxInterleaved.gltf"), to: other.appendingPathComponent("BoxInterleaved.gltf"))
        try Data([1, 2, 3]).write(to: other.appendingPathComponent("BoxInterleaved.bin"))
        #expect(session.importAssets([other.appendingPathComponent("BoxInterleaved.gltf")], into: "Models").isEmpty)
        #expect(assets.id(forPath: "Models/BoxInterleaved 3.gltf") == nil)
        #expect(session.log.entries.last?.level == .error)
    }

    @Test func foldersAndSeveralFilesImportTogether() throws {
        let (session, root, outside) = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        let pack = outside.appendingPathComponent("Rocks")
        try FileManager.default.createDirectory(at: pack.appendingPathComponent("Big"), withIntermediateDirectories: true)
        try Data(triangleOBJ.utf8).write(to: pack.appendingPathComponent("Big/boulder.obj"))
        try Data(triangleOBJ.utf8).write(to: pack.appendingPathComponent("pebble.obj"))
        let loose = outside.appendingPathComponent("pebble.obj")
        try Data(triangleOBJ.utf8).write(to: loose)

        let model = AssetBrowserModel(session: session)
        let paths = model.importFiles([pack, loose])
        #expect(paths == ["Rocks", "pebble.obj"])
        #expect(model.selection == .folder("Rocks"))
        let assets = try #require(session.assets)
        assets.waitForAll()
        #expect(assets.id(forPath: "Rocks/Big/boulder.obj") != nil)
        #expect(assets.id(forPath: "Rocks/pebble.obj") != nil)
        #expect(assets.id(forPath: "pebble.obj") != nil)
    }

    @Test func badSourcesAreRefusedAndFilesInsideTheProjectAreNotCopied() throws {
        let (session, root, outside) = try makeProject()
        defer { try? FileManager.default.removeItem(at: root) }
        let assets = try #require(session.assets)
        #expect(throws: AssetFileError.missingSource(outside.appendingPathComponent("nope.png").standardizedFileURL.path)) {
            try assets.importFiles([outside.appendingPathComponent("nope.png")])
        }
        let inside = session.project!.url(forAssetPath: "tri.obj")
        try Data(triangleOBJ.utf8).write(to: inside)
        #expect(try assets.importFiles([inside], into: "Elsewhere") == ["tri.obj"])
        #expect(!assets.isFolder("Elsewhere"))
    }

    @Test func importShortcutIsShiftCommandI() {
        let shortcuts = EditorShortcuts(shortcutModifier: .command)
        #expect(shortcuts.action(for: KeyEvent(key: .i, modifiers: [.command, .shift])) == .importAsset)
        #expect(shortcuts.action(for: KeyEvent(key: .i, modifiers: .command)) == nil)
    }
}
