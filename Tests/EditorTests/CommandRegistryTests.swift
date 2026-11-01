import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The command registry: listing, running typed and by id with JSON arguments (no window),
// availability, failures, and undo / redo of what commands did.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    // The tests save scenes in temporary folders: as if the editor had started there.
    session.startFolder = FileManager.default.temporaryDirectory
    session.newDocument()
    return session
}

@MainActor private func id(_ name: String, _ session: EditorSession) -> EntityID {
    var found: Entity?
    session.world.query(Name.self) { entity, n in if n.value == name { found = entity } }
    return session.world.id(of: found!)!
}

@MainActor private func entity(_ id: EntityID, _ session: EditorSession) -> Entity { session.world.entity(for: id)! }

/// Runs `command` by id with `json` arguments and returns the decoded JSON result.
@MainActor @discardableResult
private func run(_ session: EditorSession, _ command: CommandID, _ json: String = "{}") throws -> [String: Any] {
    let data = try session.commands.run(command, json: Data(json.utf8))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CommandRegistryTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor private final class FakeHost: EditorHost {
    var resets = 0, frames = 0
    func resetLayout() { resets += 1 }
    func frameSelection() { frames += 1 }
}

@MainActor @Suite struct CommandRegistryTests {
    @Test func listsEveryCommandWithUniqueIDsAndDocs() {
        let session = makeSession()
        let all = session.commands.all
        #expect(all.count == BuiltinCommands.all.count)
        #expect(Set(all.map(\.id)).count == all.count)
        #expect(all.map(\.id) == all.map(\.id).sorted())
        for info in all {
            #expect(info.id.rawValue.contains("."))
            #expect(!info.title.isEmpty && !info.doc.isEmpty)
        }
        // Every shortcut is bound to a registered command.
        for command in EditorShortcuts.boundCommands { #expect(session.commands.contains(command)) }
        #expect(session.commands.info("entity.create")?.isUndoable == true)
        #expect(session.commands.info("asset.delete")?.isUndoable == false)
        #expect(session.commands.info("entity.rename")?.argumentsType == "Arguments")
    }

    @Test func createByIDWithJSONUndoAndRedo() throws {
        let session = makeSession()
        let before = session.world.entityCount
        let result = try run(session, "entity.create", #"{"template": "cube", "position": [1, 2, 3]}"#)
        let created = try #require((result["entity"] as? String).flatMap(EntityID.init))
        #expect(session.world.entityCount == before + 1)
        #expect(session.world.get(Transform.self, for: entity(created, session))?.position == Vec3(1, 2, 3))
        #expect(session.world.get(Name.self, for: entity(created, session))?.value == "Cube")
        #expect(session.selection.ids == [created])
        #expect(session.undo.undoLabel == "Create Cube")

        try run(session, "edit.undo")
        #expect(session.world.entity(for: created) == nil && session.world.entityCount == before)
        #expect(!session.commands.isAvailable("edit.undo"))
        try run(session, "edit.redo")
        #expect(session.world.entity(for: created) != nil)
        #expect(!session.commands.isAvailable("edit.redo"))
    }

    @Test func renameAndReparentByID() throws {
        let session = makeSession()
        let cube = id("Red Cube", session), spinner = id("Spinner", session)
        try run(session, "entity.rename", #"{"entity": "\#(cube)", "name": "Crate"}"#)
        #expect(session.world.get(Name.self, for: entity(cube, session))?.value == "Crate")
        let worldBefore = session.world.worldMatrix(of: entity(cube, session))
        try run(session, "entity.reparent", #"{"entities": ["\#(cube)"], "parent": "\#(spinner)"}"#)
        #expect(session.world.parent(of: entity(cube, session)) == entity(spinner, session))
        #expect(session.world.children(of: entity(spinner, session)).last == entity(cube, session))
        let worldAfter = session.world.worldMatrix(of: entity(cube, session))
        #expect(length(worldAfter.translation - worldBefore.translation) < 1e-4)
        try run(session, "entity.reparent", #"{"entities": ["\#(cube)"], "parent": null, "index": 0}"#)
        #expect(session.world.roots.first == entity(cube, session))

        session.performUndo()
        session.performUndo()
        #expect(session.world.parent(of: entity(cube, session)) == entity(id("Props", session), session))
        session.performUndo()
        #expect(session.world.get(Name.self, for: entity(cube, session))?.value == "Red Cube")
    }

    @Test func setFieldConvertsJSONByFieldKind() throws {
        let session = makeSession()
        let sphere = id("Blue Sphere", session), camera = id("Main Camera", session)
        try run(session, "component.setField", #"{"entity": "\#(sphere)", "component": "Transform", "path": "position", "value": [4, 5, 6]}"#)
        #expect(session.world.get(Transform.self, for: entity(sphere, session))?.position == Vec3(4, 5, 6))
        try run(session, "component.setField", #"{"entity": "\#(sphere)", "component": "Transform", "path": "rotation", "value": [0, 0, 0, 1]}"#)
        try run(session, "component.setField", #"{"entity": "\#(camera)", "component": "Camera", "path": "fovY", "value": 1}"#)
        #expect(session.world.get(Camera.self, for: entity(camera, session))?.fovY == 1)
        try run(session, "component.setField", #"{"entity": "\#(camera)", "component": "Camera", "path": "isActive", "value": false}"#)
        #expect(session.world.get(Camera.self, for: entity(camera, session))?.isActive == false)
        #expect(session.undo.undoLabel == "Edit isActive")

        // Transient: applied, not recorded.
        let depth = session.undo.undoDepth
        try run(session, "component.setField", #"{"entity": "\#(sphere)", "component": "Transform", "path": "scale", "value": [2, 2, 2], "transient": true}"#)
        #expect(session.world.get(Transform.self, for: entity(sphere, session))?.scale == Vec3(2, 2, 2))
        #expect(session.undo.undoDepth == depth)

        session.performUndo()
        session.performUndo()
        session.performUndo()
        session.performUndo()
        #expect(session.world.get(Transform.self, for: entity(sphere, session))?.position == Vec3(0, 0.75, 2))
        #expect(session.world.get(Camera.self, for: entity(camera, session))?.isActive == true)
    }

    @Test func transformSetIsOneStepAndUndoesToPrevious() throws {
        let session = makeSession()
        let cube = id("Red Cube", session), pillar = id("Green Pillar", session)
        let start = session.world.get(Transform.self, for: entity(cube, session))!
        let moved = Transform(position: Vec3(9, 0, 0))
        try session.commands.run(TransformSetCommand.self, .init(changes: [
            .init(entity: cube, transform: moved), .init(entity: pillar, transform: moved),
        ], label: "Move"))
        #expect(session.world.get(Transform.self, for: entity(cube, session)) == moved)
        #expect(session.undo.undoDepth == 1 && session.undo.undoLabel == "Move")
        session.performUndo()
        #expect(session.world.get(Transform.self, for: entity(cube, session)) == start)

        // A gesture that already moved the entity passes where it started.
        session.world.add(moved, to: entity(cube, session))
        try run(session, "transform.set", #"{"changes": [{"entity": "\#(cube)", "transform": {"position": [9, 0, 0], "rotation": [0, 0, 0, 1], "scale": [1, 1, 1]}, "previous": {"position": [-2.5, 0.5, 0.5], "rotation": [0, 0, 0, 1], "scale": [1, 1, 1]}}]}"#)
        session.performUndo()
        #expect(session.world.get(Transform.self, for: entity(cube, session)) == start)
    }

    @Test func selectionCommandsDriveDuplicateAndDelete() throws {
        let session = makeSession()
        let cube = id("Red Cube", session)
        #expect(!session.commands.isAvailable("entity.duplicate") && !session.commands.isAvailable("entity.delete"))
        #expect(throws: CommandError.unavailable("entity.duplicate", reason: "nothing is selected (run selection.set first)")) { try run(session, "entity.duplicate") }

        try run(session, "selection.set", #"{"entities": ["\#(cube)"]}"#)
        #expect(session.selection.ids == [cube])
        let copies = try run(session, "entity.duplicate")["entities"] as? [String]
        #expect(copies?.count == 1)
        #expect(session.selection.ids.map(\.description) == copies)
        #expect(try run(session, "entity.delete")["count"] as? Int == 1)
        #expect(session.selection.isEmpty)
        session.performUndo()  // the copy is back
        #expect(copies.flatMap { $0.first }.flatMap(EntityID.init).flatMap { session.world.entity(for: $0) } != nil)
        try run(session, "selection.clear")
        #expect(session.selection.isEmpty)
    }

    @Test func componentsAddAndRemoveByID() throws {
        let session = makeSession()
        let cube = id("Red Cube", session)
        try run(session, "component.add", #"{"entity": "\#(cube)", "component": "Spin"}"#)
        #expect(session.world.get(Spin.self, for: entity(cube, session)) != nil)
        try run(session, "component.remove", #"{"entity": "\#(cube)", "component": "MeshRenderer"}"#)
        #expect(session.world.get(MeshRenderer.self, for: entity(cube, session)) == nil)
        try run(session, "edit.undo")
        try run(session, "edit.undo")
        #expect(session.world.get(MeshRenderer.self, for: entity(cube, session)) != nil)
        #expect(session.world.get(Spin.self, for: entity(cube, session)) == nil)
    }

    @Test func failuresThrowAndAreLoggedOnce() throws {
        let session = makeSession()
        let errors = session.log.count(of: .error)
        #expect(throws: CommandError.unknownCommand("nope.nothing")) { try run(session, "nope.nothing") }
        #expect(session.log.count(of: .error) == errors + 1)

        #expect(throws: CommandError.self) { try run(session, "entity.rename", #"{"name": "x"}"#) }
        #expect(session.log.entries.last?.message.contains("missing 'entity'") == true)

        let missing = EntityID(high: 1, low: 2)
        #expect(throws: CommandError.self) { try run(session, "entity.rename", #"{"entity": "\#(missing)", "name": "x"}"#) }
        #expect(session.log.count(of: .error) == errors + 3)
        #expect(throws: (any Error).self) {
            try run(session, "component.setField", #"{"entity": "\#(id("Red Cube", session))", "component": "Transform", "path": "nope", "value": 1}"#)
        }
        #expect(session.log.count(of: .error) == errors + 4)
        #expect(session.undo.undoDepth == 0)
    }

    @Test func playModeAvailability() throws {
        let session = makeSession()
        #expect(session.commands.isAvailable("scene.save") && session.commands.isAvailable("play.start"))
        #expect(!session.commands.isAvailable("play.stop"))
        try run(session, "play.toggle")
        #expect(session.isPlaying)
        #expect(!session.commands.isAvailable("scene.save") && !session.commands.isAvailable("scene.new"))
        #expect(throws: CommandError.self) { try run(session, "scene.save", #"{"path": "/tmp/never.json"}"#) }
        #expect(session.log.entries.last?.level == .warning)
        try run(session, "play.stop")
        #expect(!session.isPlaying)
    }

    @Test func toolAndHostCommands() throws {
        let session = makeSession()
        try run(session, "tool.set", #"{"tool": "rotate"}"#)
        #expect(session.tool == .rotate)
        #expect(!session.commands.isAvailable("layout.reset"))
        let host = FakeHost()
        session.host = host
        try run(session, "layout.reset")
        #expect(host.resets == 1)
        #expect(!session.commands.isAvailable("view.frameSelection"))
        session.selection.select(id("Floor", session))
        try run(session, "view.frameSelection")
        #expect(host.frames == 1)
    }

    @Test func sceneSaveNewAndOpenByID() throws {
        let session = makeSession()
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appendingPathComponent("a.json").path
        try run(session, "entity.rename", #"{"entity": "\#(id("Floor", session))", "name": "Ground"}"#)
        #expect(try run(session, "scene.save", #"{"path": "\#(path)"}"#)["path"] as? String == path)
        #expect(!session.document.isDirty)
        try run(session, "scene.new")
        #expect(session.document.url == nil)
        try run(session, "scene.open", #"{"path": "\#(path)"}"#)
        _ = id("Ground", session)
    }

    @Test func assetCommandsWithAProject() throws {
        let session = makeSession()
        #expect(!session.commands.isAvailable("asset.newFolder"))
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let assets = folder.appendingPathComponent("Assets")
        try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
        try Data("o Tri\nv 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n".utf8).write(to: assets.appendingPathComponent("tri.obj"))
        try run(session, "project.new", #"{"path": "\#(folder.path)"}"#)
        session.assets?.waitForAll()

        #expect(try run(session, "asset.newFolder", #"{"name": "Models"}"#)["path"] as? String == "Models")
        #expect(try run(session, "asset.move", #"{"path": "tri.obj", "folder": "Models"}"#)["path"] as? String == "Models/tri.obj")
        #expect(try run(session, "asset.rename", #"{"path": "Models/tri.obj", "name": "rock"}"#)["path"] as? String == "Models/rock.obj")
        let material = try run(session, "asset.newMaterial", #"{"folder": "Models"}"#)
        #expect(material["path"] as? String == "Models/New Material.material")
        session.assets?.waitForAll()

        let model = try #require(session.assets?.id(forPath: "Models/rock.obj"))
        let roots = try run(session, "asset.instantiate", #"{"asset": "\#(AssetReference(model))", "position": [0, 1, 0]}"#)["entities"] as? [String]
        let root = try #require(roots?.first.flatMap(EntityID.init))
        #expect(session.undo.undoLabel?.hasPrefix("Instantiate") == true)
        // Assign the material to the instance's renderer (the root or its child).
        var target = root
        if session.world.get(MeshRenderer.self, for: entity(root, session)) == nil {
            target = try #require(session.world.children(of: entity(root, session)).first.flatMap { session.world.id(of: $0) })
        }
        let materialID = try #require((material["asset"] as? String).flatMap(AssetID.init).map { AssetReference($0) })
        try run(session, "asset.assign", #"{"entity": "\#(target)", "asset": "\#(materialID)"}"#)
        #expect(session.world.get(MeshRenderer.self, for: entity(target, session))?.material.key.hasPrefix("asset:") == true)
        #expect(session.undo.undoLabel == "Assign Material")
        session.performUndo()
        session.performUndo()
        #expect(session.world.entity(for: root) == nil)

        try run(session, "asset.delete", #"{"path": "Models/New Material.material"}"#)
        #expect(session.assets?.id(forPath: "Models/New Material.material") == nil)
    }

    @Test func hierarchyButtonsFollowAvailability() throws {
        let session = makeSession()
        let hierarchy = HierarchyPanel(session: session)
        let duplicate = try #require(hierarchy.view.descendant(named: "duplicate") as? Button)
        #expect(!duplicate.isEnabled)
        session.selection.select(id("Floor", session))
        hierarchy.sync()
        #expect(duplicate.isEnabled)
    }
}
