import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The project, asset and prefab commands as a remote caller uses them (JSON in, JSON out, as
// MCP tools do): an end-to-end run from importing a .glb to a saved scene that names its
// assets by id, plus prefab apply / revert / hot reload and closing the project.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private let glTFResources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("EngineTests/Resources/glTF")

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AssetToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// Runs a command by id with JSON arguments, as the MCP server does, and returns its JSON result.
@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct AssetToolsTests {
    @Test func importInstantiateEditPrefabSave() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        // Import a model and wait for it.
        let imported = try call(session, "asset.import", ["sources": [glTFResources.appendingPathComponent("TextureCoordinateTest.glb").path],
                                                          "folder": "Models"])
        #expect(imported["paths"] as? [String] == ["Models/TextureCoordinateTest.glb"])
        let waited = try call(session, "asset.waitForImports", ["timeout": 60])
        #expect(waited["finished"] as? Bool == true && (waited["errors"] as? [Any])?.isEmpty == true)

        // List and inspect it.
        let listing = try call(session, "asset.list", ["folder": "Models"])
        let models = listing["assets"] as? [[String: Any]] ?? []
        #expect(models.count == 1)
        let model = try #require(models.first)
        #expect(model["kind"] as? String == "model" && model["importer"] as? String == "gltf" && model["state"] as? String == "loaded")
        let modelID = try #require(model["id"] as? String)
        let objects = model["objects"] as? [[String: Any]] ?? []
        #expect(objects.contains { $0["kind"] as? String == "prefab" })
        #expect(objects.filter { $0["kind"] as? String == "material" }.count == 5)
        #expect(try call(session, "asset.list")["folders"] as? [String] == ["Models"])
        let found = try call(session, "asset.list", ["kind": "material", "search": "topleft"])["assets"] as? [[String: Any]]
        #expect(found?.map { $0["path"] as? String } == ["Models/TextureCoordinateTest.glb"])
        let details = try call(session, "asset.get", ["path": "Models/TextureCoordinateTest.glb"])
        #expect((details["settings"] as? [String: Any])?["smoothNormals"] as? Bool == false)
        #expect((details["defaultSettings"] as? [String: Any])?["smoothNormals"] as? Bool == false)
        #expect(try call(session, "asset.reimport", ["asset": "asset:\(modelID)"])["revision"] as? Int ?? 0 > details["revision"] as? Int ?? 0)
        let resource = try #require(EditorMCP(session: session).readResource("editor://asset/\(modelID)")?.first?.text)
        #expect(resource.contains("TextureCoordinateTest.glb"))

        // Place it: a linked prefab instance.
        let roots = try call(session, "asset.instantiate", ["asset": "asset:\(modelID)", "position": [0, 1, 0]])["entities"] as? [String]
        let root = try #require(roots?.first)
        let overrides = try call(session, "prefab.overrides", ["entity": root])
        #expect(overrides["prefab"] as? String == "asset:\(modelID)" && overrides["canApply"] as? Bool == false)
        #expect((overrides["overrides"] as? [Any])?.isEmpty == true)

        // Edit a material: extract the model's, then change one.
        let extracted = try call(session, "asset.extractMaterials", ["asset": modelID])["materials"] as? [String] ?? []
        #expect(extracted.count == 5)
        let topLeft = try #require(try call(session, "asset.list", ["search": "TopLeftMat.material"])["assets"] as? [[String: Any]]).first
        let materialID = try #require(topLeft?["id"] as? String)
        var material = try call(session, "material.get", ["asset": "asset:\(materialID)"])
        #expect(material["editable"] as? Bool == true)
        var values = try #require(material["material"] as? [String: Any])
        values["baseColor"] = [1, 0.5, 0, 1]
        try call(session, "material.set", ["asset": materialID, "material": values])
        material = try call(session, "material.get", ["asset": "asset:\(materialID)"])
        #expect((material["material"] as? [String: Any])?["baseColor"] as? [Double] == [1, 0.5, 0, 1])
        let gold = try call(session, "asset.newMaterial", ["name": "Gold", "material": ["baseColor": [1, 0.8, 0.2, 1], "metallic": 1]])
        let goldID = try #require(gold["asset"] as? String)
        #expect(session.assets?.material(AssetReference(AssetID(goldID)!))?.metallic == 1)

        // Make a prefab of the instance and place it again.
        let prefab = try call(session, "prefab.create", ["entity": root, "folder": "Prefabs", "name": "Board"])
        #expect(prefab["path"] as? String == "Prefabs/Board.prefab")
        let prefabReference = try #require(prefab["prefab"] as? String)
        #expect(try call(session, "asset.list", ["kind": "prefab", "folder": "Prefabs"])["assets"].map { ($0 as? [Any])?.count } == 1)
        let copies = try call(session, "asset.instantiate", ["asset": prefabReference, "position": [4, 0, 0]])["entities"] as? [String]
        let copy = try #require(copies?.first)
        #expect(try call(session, "prefab.overrides", ["entity": copy])["canApply"] as? Bool == true)

        // Save: the scene names assets by id, not by path.
        let scenePath = folder.appendingPathComponent("Game/Scenes/board.json").path
        try call(session, "scene.saveAs", ["path": scenePath])
        let scene = try String(contentsOfFile: scenePath, encoding: .utf8)
        #expect(scene.contains("asset:\(modelID)#mesh/"))
        #expect(scene.contains("asset:\(materialID)#material"))
        #expect(scene.contains(#""prefab" : "\#(prefabReference)""#))
        #expect(scene.contains("PrefabInstance"))
        #expect(!scene.contains("Models/") && !scene.contains(".glb"))

        // It opens again with its instances linked.
        let count = session.world.entityCount
        try call(session, "scene.open", ["path": scenePath])
        #expect(session.world.entityCount == count)
        #expect(session.world.independentPrefabInstances().count == 2)
    }

    @Test func prefabApplyRevertUndoAndHotReload() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.path])
        let parent = try #require(session.create(.cube, name: "Crate"))
        let lid = try #require(session.create(.cube, at: Vec3(0, 1, 0), name: "Lid", parent: parent))
        let prefab = try call(session, "prefab.create", ["entity": parent.description])
        let reference = try #require(AssetReference(prefab["prefab"] as? String ?? ""))
        let second = try #require(session.instantiate(.asset(reference.asset), at: Vec3(5, 0, 0)).first)
        func lidOf(_ root: EntityID) -> Entity? {
            let world = session.world
            return world.entity(for: root).flatMap { world.children(of: $0).first { world.get(Name.self, for: $0)?.value == "Lid" } }
        }

        // An override, shown and then applied: the other instance follows.
        try call(session, "component.setField", ["entity": lid.description, "path": "Transform.scale", "value": [2, 2, 2]])
        let overrides = try call(session, "prefab.overrides", ["entity": lid.description])["overrides"] as? [[String: Any]] ?? []
        #expect(overrides.map { $0["path"] as? String } == ["scale.0", "scale.1", "scale.2"])  // vectors element by element
        #expect(session.prefabInfo(of: lid)?.overriddenComponents.first?.fields == ["scale"])
        #expect(overrides.first?["entity"] as? String == lid.description)
        #expect(session.prefabInfo(of: lid)?.overriddenComponents.map(\.component) == ["Transform"])
        try call(session, "prefab.apply", ["entity": lid.description, "component": "Transform"])
        #expect(session.world.get(Transform.self, for: lidOf(second)!)?.scale == Vec3(2, 2, 2))
        #expect((try call(session, "prefab.overrides", ["entity": lid.description])["overrides"] as? [Any])?.isEmpty == true)
        // Undo writes the old file back; the instances follow again.
        try call(session, "edit.undo")
        #expect(session.world.get(Transform.self, for: lidOf(second)!)?.scale == Vec3(1, 1, 1))
        #expect(session.world.get(Transform.self, for: session.world.entity(for: lid)!)?.scale == Vec3(2, 2, 2))
        try call(session, "edit.redo")
        #expect(session.world.get(Transform.self, for: lidOf(second)!)?.scale == Vec3(2, 2, 2))

        // Revert one component, then a whole instance with an added child.
        try call(session, "component.setField", ["entity": lid.description, "path": "Transform.position", "value": [0, 3, 0]])
        try call(session, "prefab.revert", ["entity": lid.description, "component": "Transform"])
        #expect(session.world.get(Transform.self, for: session.world.entity(for: lid)!)?.position == Vec3(0, 1, 0))
        let extra = try #require(session.create(.sphere, name: "Extra", parent: second))
        try call(session, "component.remove", ["entity": lidOf(second).flatMap { session.world.id(of: $0) }!.description, "component": "MeshRenderer"])
        #expect(try call(session, "prefab.overrides", ["entity": second.description])["added"] as? [String] == [extra.description])
        try call(session, "prefab.revert", ["entity": second.description])
        #expect(session.world.entity(for: extra) == nil)
        #expect(session.world.get(MeshRenderer.self, for: lidOf(second)!) != nil)
        #expect(session.world.entity(for: second) != nil)
        try call(session, "edit.undo")
        #expect(session.world.entity(for: extra) != nil)

        // Apply All takes the added child into the prefab.
        try call(session, "prefab.apply", ["entity": second.description])
        #expect(session.world.entity(for: extra) != nil)
        let first = session.world.entity(for: parent)!
        #expect(session.world.children(of: first).contains { session.world.get(Name.self, for: $0)?.value == "Extra" })
        #expect(session.world.prefabAddedEntities(of: session.world.entity(for: second)!).isEmpty)

        // Hot reload: another tool rewrites the file.
        let assets = try #require(session.assets)
        let file = World()
        let fileRoot = try file.load(assets.fileData(of: reference.asset))[0]
        file.add(Name("Crate v2"), to: fileRoot)
        try assets.writePrefab(file.save([fileRoot]), to: reference.asset)
        #expect(session.world.get(Name.self, for: session.world.entity(for: second)!)?.value == "Crate v2")

        // A model's prefab can't be applied; play mode waits; unpacking unlinks.
        try call(session, "prefab.unpack", ["entity": second.description])
        #expect(session.world.get(PrefabInstance.self, for: session.world.entity(for: second)!) == nil)
        #expect(throws: (any Error).self) { try call(session, "prefab.overrides", ["entity": second.description]) }
    }

    @Test func prefabVariantsAndPerItemRevert() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.path])
        let crate = try #require(session.create(.cube, name: "Crate"))
        let lid = try #require(session.create(.cube, at: Vec3(0, 1, 0), name: "Lid", parent: crate))
        let base = try #require(AssetReference(try call(session, "prefab.create", ["entity": crate.description])["prefab"] as? String ?? ""))
        func lidOf(_ root: EntityID) -> EntityID? {
            let world = session.world
            return world.entity(for: root).flatMap { world.children(of: $0).first { world.get(Name.self, for: $0)?.value == "Lid" } }
                .flatMap { world.id(of: $0) }
        }
        func transform(_ id: EntityID?) -> Transform? { id.flatMap { session.world.entity(for: $0) }.flatMap { session.world.get(Transform.self, for: $0) } }

        // A variant of the prefab, and an instance of it.
        let created = try call(session, "prefab.createVariant", ["asset": base.description, "name": "Big"])
        #expect(created["path"] as? String == "Big.prefab")
        let variant = try #require(AssetReference(created["prefab"] as? String ?? ""))
        #expect(session.assets?.prefab(variant)?.variant?.base == base)
        let big = try #require(session.instantiate(.asset(variant.asset), at: Vec3(5, 0, 0)).first)
        let bigLid = try #require(lidOf(big))
        #expect(try call(session, "prefab.overrides", ["entity": big.description])["base"] as? String == base.description)
        #expect(session.prefabInfo(of: big)?.base == base)

        // An override applied to the variant: its instances get it, the base's don't.
        try call(session, "component.setField", ["entity": bigLid.description, "path": "Transform.scale", "value": [3, 3, 3]])
        try call(session, "prefab.apply", ["entity": bigLid.description, "component": "Transform"])
        #expect(session.assets?.prefab(variant)?.variant?.overrides.isEmpty == false)
        #expect(transform(lid)?.scale == Vec3(1, 1, 1))
        let big2 = try #require(session.instantiate(.asset(variant.asset), at: Vec3(9, 0, 0)).first)
        let big2Lid = try #require(lidOf(big2))
        #expect(transform(big2Lid)?.scale == Vec3(3, 3, 3))
        #expect((try call(session, "prefab.overrides", ["entity": big2Lid.description])["overrides"] as? [Any])?.isEmpty == true)

        // The base changes: the variant follows except where it overrides.
        try call(session, "component.setField", ["entity": lid.description, "path": "Transform.position", "value": [0, 2, 0]])
        try call(session, "prefab.apply", ["entity": lid.description, "component": "Transform"])
        #expect(transform(big2Lid)?.position == Vec3(0, 2, 0) && transform(big2Lid)?.scale == Vec3(3, 3, 3))
        #expect(transform(bigLid)?.position == Vec3(0, 2, 0))

        // Per-item revert: two fields overridden, one put back.
        try call(session, "component.setField", ["entity": big2Lid.description, "path": "Transform.position", "value": [0, 5, 0]])
        try call(session, "component.setField", ["entity": big2Lid.description, "path": "Transform.scale", "value": [4, 4, 4]])
        #expect(session.prefabInfo(of: big2Lid)?.items.map(\.field) == ["position", "scale"])
        try call(session, "prefab.revert", ["entity": big2Lid.description, "component": "Transform", "path": "position"])
        #expect(transform(big2Lid)?.position == Vec3(0, 2, 0) && transform(big2Lid)?.scale == Vec3(4, 4, 4))
        try call(session, "edit.undo")
        #expect(transform(big2Lid)?.position == Vec3(0, 5, 0))
        try call(session, "edit.redo")

        // An added child is an override that can be reverted alone; a removed one too.
        let extra = try #require(session.create(.sphere, name: "Extra", parent: big2))
        let overrides = try call(session, "prefab.overrides", ["entity": big2.description])["overrides"] as? [[String: Any]] ?? []
        #expect(overrides.contains { $0["kind"] as? String == "addedEntity" && $0["path"] as? String == extra.description })
        #expect(session.prefabInfo(of: big2)?.items.contains { $0.isAddedChild && $0.child == extra.description } == true)
        try call(session, "prefab.revert", ["entity": big2.description, "child": extra.description])
        #expect(session.world.entity(for: extra) == nil)
        #expect(transform(big2Lid)?.scale == Vec3(4, 4, 4))   // the other overrides stay
        try call(session, "edit.undo")
        #expect(session.world.entity(for: extra) != nil)
        let lidEntity = try #require(session.world.entity(for: big2Lid))
        session.world.despawn(lidEntity)
        let removed = (try call(session, "prefab.overrides", ["entity": big2.description])["overrides"] as? [[String: Any]] ?? [])
            .first { $0["kind"] as? String == "removedEntity" }
        let removedID = try #require(removed?["prefabEntity"] as? String)
        try call(session, "prefab.revert", ["entity": big2.description, "child": removedID])
        #expect(lidOf(big2) != nil)

        // A variant from an instance takes its overrides and added child; the instance becomes an instance of it.
        let bigger = try call(session, "prefab.createVariant", ["entity": big2.description, "name": "Bigger"])
        let biggerRef = try #require(AssetReference(bigger["prefab"] as? String ?? ""))
        #expect(session.assets?.prefab(biggerRef)?.variant?.base == variant)
        #expect(session.prefabInfo(of: big2)?.link.prefab == biggerRef && session.prefabInfo(of: big2)?.overrides.isEmpty == true)
        let again = try #require(session.instantiate(.asset(biggerRef.asset), at: Vec3(13, 0, 0)).first)
        let names = session.world.entity(for: again).map { session.world.children(of: $0).compactMap { session.world.get(Name.self, for: $0)?.value } } ?? []
        #expect(Set(names) == ["Lid", "Extra"])
        #expect(transform(lidOf(again))?.scale == Vec3(3, 3, 3))   // the restored lid is the variant's again
    }

    @Test func closeProject() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        #expect(!session.commands.isAvailable("project.close"))
        try call(session, "project.new", ["path": folder.path])
        #expect(session.commands.isAvailable("asset.list"))
        try call(session, "project.close")
        #expect(session.assets == nil)
        #expect(!session.commands.isAvailable("asset.list"))
        #expect(throws: (any Error).self) { try call(session, "asset.list") }
    }

    @Test func entityRefFieldsAreEntityPickers() throws {
        struct Leash: Component {
            static let componentName = "TestLeash"
            var target = EntityRef()
        }
        ComponentRegistry.register(Leash.self)
        let session = makeSession()
        let dog = try #require(session.create(.sphere, name: "Dog"))
        let post = try #require(session.create(.cube, name: "Post"))
        session.world.add(Leash(), to: session.world.entity(for: dog)!)
        try call(session, "component.setField", ["entity": dog.description, "path": "TestLeash.target", "value": post.description])
        #expect(session.world.get(Leash.self, for: session.world.entity(for: dog)!)?.target.id == post)
        // Duplicating the pair keeps the copy's leash on the copied post.
        session.selection.set([dog, post])
        let copies = try call(session, "entity.duplicate")["entities"] as? [String] ?? []
        #expect(copies.count == 2)
        let copyDog = session.world.entity(for: EntityID(copies[0])!)!
        #expect(session.world.get(Leash.self, for: copyDog)?.target.id == post)  // the post is outside the dog's subtree
        // The inspector offers the scene's entities, titled by name.
        let panel = InspectorPanel(session: session)
        session.selection.set([dog])
        panel.refresh()
        let options = try #require(panel.grid.stringChoices?("TestLeash", "target"))
        #expect(options.first == "" && options.contains(post.description))
        #expect(panel.grid.stringChoiceTitle?("TestLeash", "target", post.description) == "Post")
        #expect(panel.grid.stringChoiceTitle?("TestLeash", "target", "") == "None")
    }
}
