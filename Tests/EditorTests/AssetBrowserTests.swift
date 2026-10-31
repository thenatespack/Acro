import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The asset browser: listing, file operations that keep ids, import settings, material editing
// with undo, Extract Materials, and dropping assets into the scene.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AssetBrowserTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private let triangleOBJ = """
    o Tri
    v 0 0 0
    v 1 0 0
    v 0 1 0
    f 1 2 3
    """

private let glTFResources = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("EngineTests/Resources/glTF")

/// A project with Models/tri.obj, Models/TextureCoordinateTest.glb and Red.material, opened
/// and fully imported.
@MainActor private func makeProject(_ folder: URL) throws -> EditorSession {
    let session = makeSession()
    let assets = folder.appendingPathComponent("Assets")
    try FileManager.default.createDirectory(at: assets.appendingPathComponent("Models"), withIntermediateDirectories: true)
    try Data(triangleOBJ.utf8).write(to: assets.appendingPathComponent("Models/tri.obj"))
    try FileManager.default.copyItem(at: glTFResources.appendingPathComponent("TextureCoordinateTest.glb"),
                                     to: assets.appendingPathComponent("Models/TextureCoordinateTest.glb"))
    try Data(#"{ "baseColor" : [0.8, 0.1, 0.1, 1] }"#.utf8).write(to: assets.appendingPathComponent("Red.material"))
    #expect(session.newProject(path: folder.path))
    session.assets?.waitForAll()
    return session
}

@MainActor @Suite struct AssetBrowserTests {
    @Test func listsFoldersFilesAndExpandedModels() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let model = AssetBrowserModel(session: session)
        #expect(model.folders == ["Models"])
        #expect(model.entries.map(\.title) == ["Models", "Red.material"])
        #expect(model.entries.map(\.kind) == [.folder, .material])

        model.activate(model.entries[0])
        #expect(model.folder == "Models")
        #expect(model.breadcrumb.map(\.title) == ["Assets", "Models"])
        #expect(model.entries.map(\.title) == ["TextureCoordinateTest.glb", "tri.obj"])
        let glb = model.entries[0]
        #expect(glb.kind == .model && glb.isExpandable && glb.thumbnailKind == .prefab)

        model.activate(glb)  // expands
        let objects = model.entries.filter(\.isSubAsset)
        #expect(objects.contains { $0.kind == .material && $0.title == "TopLeftMat" })
        #expect(objects.contains { $0.kind == .mesh })
        #expect(objects.contains { $0.kind == .texture })
        #expect(objects.contains { $0.kind == .prefab })

        model.search = "topleft"
        #expect(Set(model.entries.map(\.title)) == ["TopLeftMat", "TopLeftMesh"])
        model.search = ""

        // Selecting shows it in the inspector; selecting an entity takes it back.
        model.select(.asset(try #require(session.assets?.id(forPath: "Red.material"))))
        #expect(session.inspectedAsset != nil)
        session.selection.select(session.world.roots.first.flatMap { session.world.id(of: $0) })
        #expect(session.inspectedAsset == nil)
    }

    @Test func renameMoveAndDeleteKeepIDs() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let id = try #require(assets.id(forPath: "Models/tri.obj"))
        let model = AssetBrowserModel(session: session)

        model.folder = "Models"
        model.select(.asset(id))
        #expect(model.renameSelection(to: "triangle"))
        #expect(assets.path(of: id) == "Models/triangle.obj")  // extension kept, id kept
        #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Assets/Models/triangle.obj.meta").path))

        let newFolder = try #require(model.newFolder())
        #expect(newFolder == "Models/New Folder")
        #expect(model.newFolder() == "Models/New Folder 2")
        #expect(model.move(.asset(id), into: newFolder))
        #expect(assets.path(of: id) == "Models/New Folder/triangle.obj")

        // A folder rename moves what is inside, with the ids.
        model.select(.folder(newFolder))
        #expect(model.renameSelection(to: "Shapes"))
        #expect(assets.path(of: id) == "Models/Shapes/triangle.obj")
        #expect(assets.mesh(AssetReference(id, subAsset: "mesh/Tri")) != nil)

        // Taken names are refused.
        #expect(session.renameAsset(at: "Models/Shapes", to: "New Folder 2") == nil)
        #expect(session.log.count(of: .error) == 1)

        model.select(.asset(id))
        #expect(model.deleteSelection())
        #expect(assets.record(id) == nil)
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent("Assets/Models/Shapes/triangle.obj.meta").path))
    }

    @Test func newMaterialWritesAFile() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let model = AssetBrowserModel(session: session)
        let id = try #require(model.newMaterial())
        #expect(session.assets?.path(of: id) == "New Material.material")
        #expect(session.assets?.material(AssetReference(id)) == MaterialAsset())
        #expect(session.isMaterialFile(id))
        #expect(model.selection == .asset(id))
        #expect(model.newMaterial().flatMap { session.assets?.path(of: $0) } == "New Material 2.material")
    }

    @Test func importSettingsApplyAndRevert() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let id = try #require(assets.id(forPath: "Models/tri.obj"))
        let editor = try #require(AssetSettingsEditor(session: session, asset: id))
        #expect(editor.componentName == "Import Settings")
        let fields = try #require(editor.world.fields(of: editor.componentName, for: editor.entity))
        #expect(fields.first { $0.name == "scale" }?.kind == .float)  // typed form: 1 is still a float
        #expect(!editor.isModified)

        try editor.setField("scale", to: .float(2.5))
        #expect(editor.isModified)
        editor.revert()
        #expect(!editor.isModified)
        #expect(assets.settings(of: id, as: OBJImporter.Settings.self)?.scale == 1)

        try editor.setField("scale", to: .float(2.5))
        let revision = assets.revision(of: id)
        #expect(editor.apply())
        #expect(!editor.isModified)
        #expect(assets.settings(of: id, as: OBJImporter.Settings.self)?.scale == 2.5)
        #expect(assets.revision(of: id) > revision)
        #expect(assets.mesh(AssetReference(id, subAsset: "mesh/Tri"))?.bounds.halfExtent.x == 1.25)

        // A .material has no settings form.
        #expect(AssetSettingsEditor(session: session, asset: try #require(assets.id(forPath: "Red.material"))) == nil)
    }

    @Test func materialEditUndoRedoAndSave() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let id = try #require(assets.id(forPath: "Red.material"))
        let editor = try #require(MaterialAssetEditor(session: session, reference: AssetReference(id, subAsset: "material")))
        #expect(editor.isEditable)
        let names = try #require(editor.world.fields(of: "Material", for: editor.entity)).map(\.name)
        #expect(names.contains("baseColor") && names.contains("texture") && names.contains("specular"))

        // A drag: several changes, one step.
        func edit(_ phase: PropertyEditPhase, _ value: Double) {
            editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "specular",
                                       oldValue: .float(0.35), newValue: .float(value), phase: phase))
        }
        let depth = session.undo.undoDepth
        edit(.began, 0.35)
        edit(.changed, 0.5)
        #expect(assets.material(AssetReference(id))?.specular == 0.5)  // written live
        #expect(session.undo.undoDepth == depth)
        edit(.changed, 0.7)
        edit(.ended, 0.7)
        #expect(session.undo.undoDepth == depth + 1)
        let file = folder.appendingPathComponent("Assets/Red.material")
        let saved = try AssetJSON.decoder().decode(MaterialAsset.self, from: Data(contentsOf: file))
        #expect(saved.specular == 0.7)
        #expect(saved.baseColor == Vec4(0.8, 0.1, 0.1, 1))

        session.performUndo()
        #expect(try AssetJSON.decoder().decode(MaterialAsset.self, from: Data(contentsOf: file)).specular == 0.35)
        #expect(assets.material(AssetReference(id))?.specular == 0.35)
        editor.refresh()
        #expect(editor.material?.specular == 0.35)
        session.performRedo()
        #expect(assets.material(AssetReference(id))?.specular == 0.7)

        // Texture: "" in the dropdown means none.
        let texture = try #require(assets.references(of: .texture).first)
        #expect(MaterialAssetComponent.choices(path: "texture", assets: assets) == [""] + assets.references(of: .texture).map(\.description))
        editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "texture", oldValue: .null,
                                   newValue: .string(texture.description), phase: .began))
        editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "texture", oldValue: .null,
                                   newValue: .string(texture.description), phase: .ended))
        #expect(assets.material(AssetReference(id))?.texture == texture)
        editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "texture",
                                   oldValue: .string(texture.description), newValue: .null, phase: .began))
        editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "texture",
                                   oldValue: .string(texture.description), newValue: .null, phase: .ended))
        #expect(assets.material(AssetReference(id))?.texture == nil)

        // Imported materials are read-only.
        let glb = try #require(assets.id(forPath: "Models/TextureCoordinateTest.glb"))
        let imported = try #require(MaterialAssetEditor(session: session, reference: AssetReference(glb, subAsset: "material/TopLeftMat")))
        #expect(!imported.isEditable)
    }

    @Test func extractMaterialsRemapsTheModel() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let glb = try #require(assets.id(forPath: "Models/TextureCoordinateTest.glb"))
        let original = AssetReference(glb, subAsset: "material/TopLeftMat")
        let originalMaterial = try #require(assets.material(original))

        // An instance from before the extraction.
        let roots = session.instantiate(.asset(glb), at: Vec3(1, 0, 0))
        #expect(roots.count == 1)
        func renderers() -> [MeshRenderer] {
            var result: [MeshRenderer] = []
            session.world.query(MeshRenderer.self) { _, r in result.append(r) }
            return result
        }
        #expect(renderers().contains { $0.material.key == original.description })

        let created = session.extractMaterials(of: glb)
        #expect(created.count == 5)
        let topLeft = try #require(assets.id(forPath: "Models/TextureCoordinateTest Materials/TopLeftMat.material"))
        #expect(created.contains(topLeft))
        #expect(assets.material(AssetReference(topLeft)) == originalMaterial)
        let settings = try #require(assets.settings(of: glb, as: GLTFImporter.Settings.self))
        #expect(settings.materialRemap["material/TopLeftMat"] == AssetReference(topLeft, subAsset: "material"))

        // The prefab now uses the extracted files; so does the existing instance (one undo step).
        let prefab = try #require(assets.prefab(AssetReference(glb)))
        func materials(_ node: PrefabNode) -> [AssetReference] { (node.material.map { [$0] } ?? []) + node.children.flatMap(materials) }
        let used = prefab.roots.flatMap(materials)
        #expect(used.contains(AssetReference(topLeft, subAsset: "material")))
        #expect(!used.contains(original))
        #expect(renderers().contains { $0.material.key == AssetReference(topLeft, subAsset: "material").description })
        #expect(session.undo.undoLabel == "Extract Materials")
        // The originals still import (old references keep working).
        #expect(assets.material(original) != nil)

        // Again: nothing left to extract.
        #expect(session.extractMaterials(of: glb).isEmpty)
    }

    @Test func dropToInstantiateIsOneUndoStep() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let glb = try #require(assets.id(forPath: "Models/TextureCoordinateTest.glb"))
        let count = session.world.entityCount
        let depth = session.undo.undoDepth

        #expect(session.drop(.asset(glb), on: .viewport(position: Vec3(2, 0, -3), entity: nil)))
        #expect(session.undo.undoDepth == depth + 1)
        #expect(session.world.entityCount > count + 1)
        let root = try #require(session.selection.primaryEntity(in: session.world))
        #expect(session.world.get(Transform.self, for: root)?.position == Vec3(2, 0, -3))
        #expect(session.world.parent(of: root) == nil)
        let saved = String(decoding: try session.world.save(), as: UTF8.self)
        #expect(saved.contains("asset:\(glb.description)#mesh/"))
        #expect(!saved.contains("TextureCoordinateTest.glb"))

        session.performUndo()
        #expect(session.world.entityCount == count)

        // Onto a hierarchy row: a child of it.
        let parentID = try #require(session.world.roots.first.flatMap { session.world.id(of: $0) })
        #expect(session.drop(.asset(glb), on: .hierarchy(parent: parentID, position: .zero)))
        let child = try #require(session.selection.primaryEntity(in: session.world))
        #expect(session.world.parent(of: child).flatMap { session.world.id(of: $0) } == parentID)

        // A mesh object becomes one entity.
        let tri = try #require(assets.id(forPath: "Models/tri.obj"))
        #expect(session.drop(.object(AssetReference(tri, subAsset: "mesh/Tri")), on: .viewport(position: .zero, entity: nil)))
        let mesh = try #require(session.selection.primaryEntity(in: session.world))
        #expect(session.world.get(MeshRenderer.self, for: mesh)?.mesh == MeshHandle(AssetReference(tri, subAsset: "mesh/Tri")))
    }

    @Test func dropMaterialOntoFieldOrObject() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try makeProject(folder)
        let assets = try #require(session.assets)
        let red = try #require(assets.id(forPath: "Red.material"))
        var sphere: Entity?
        session.world.query(Name.self) { entity, name in if name.value == "Blue Sphere" { sphere = entity } }
        let entity = try #require(sphere)
        let id = try #require(session.world.id(of: entity))
        let depth = session.undo.undoDepth

        #expect(session.drop(.asset(red), on: .field(entity: id, kind: .material)))
        #expect(session.world.get(MeshRenderer.self, for: entity)?.material == MaterialHandle(AssetReference(red, subAsset: "material")))
        #expect(session.undo.undoDepth == depth + 1)
        #expect(session.undo.undoLabel == "Assign Material")

        // The wrong kind is refused.
        #expect(!session.drop(.asset(red), on: .field(entity: id, kind: .mesh)))
        #expect(session.undo.undoDepth == depth + 1)

        session.performUndo()
        #expect(session.world.get(MeshRenderer.self, for: entity)?.material == .default)

        // Onto the object in the viewport.
        #expect(session.drop(.asset(red), on: .viewport(position: .zero, entity: id)))
        #expect(session.world.get(MeshRenderer.self, for: entity)?.material == MaterialHandle(AssetReference(red, subAsset: "material")))
        // A material dropped on empty space does nothing.
        #expect(!session.drop(.asset(red), on: .viewport(position: .zero, entity: nil)))
    }

    @Test func dropdownTruncatesLongTitles() {
        let dropdown = Dropdown(options: ["Models/A Very Long Folder Name/model.glb › SomeMaterialName"], name: "d")
        let ui = UIContext()
        ui.setViewport(size: Vec2(800, 600), scale: 1)
        let row = HStack(alignment: .start, [dropdown])
        ui.root.addChild(row)
        dropdown.style.width = 120
        ui.layoutIfNeeded()
        #expect(dropdown.tooltip(at: dropdown.frame.center) == "Models/A Very Long Folder Name/model.glb › SomeMaterialName")
        dropdown.options = ["cube"]
        ui.layoutIfNeeded()
        #expect(dropdown.tooltip(at: dropdown.frame.center) == nil)
    }
}
