import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineUI

// The Inspector's Material section (InspectorMaterialSection.swift): the material of the
// selected object's MeshRenderer, picked, previewed and edited from the object.

@MainActor private func makeApp(_ folder: URL) throws -> EditorApp {
    let app = EditorApp(options: EditorOptions(deterministic: true))
    app.setupWithoutWindow(size: Vec2(1600, 1000), scale: 1)
    let assets = folder.appendingPathComponent("Assets")
    try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
    try Data(#"{ "baseColor" : [0.8, 0.1, 0.1, 1] }"#.utf8).write(to: assets.appendingPathComponent("Red.material"))
    #expect(app.session.newProject(path: folder.path))
    app.session.assets?.waitForAll()
    app.syncPanels()
    return app
}

/// Every widget under `root`, depth first.
@MainActor private func allWidgets(_ root: Widget) -> [Widget] {
    root.children.flatMap { [$0] + allWidgets($0) }
}

@MainActor @Suite struct InspectorMaterialTests {
    private func folder() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("InspectorMaterialTests-\(UUID().uuidString)")
    }

    @Test func anObjectsMaterialIsPickedAndEditedFromTheInspector() throws {
        let folder = folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = try makeApp(folder)
        let session = app.session
        let assets = try #require(session.assets)
        let cubeID = try #require(session.run(EntityCreateCommand.self, .init(template: .cube))?.entity)
        let cube = try #require(session.world.entity(for: cubeID))
        app.syncPanels()
        let section = app.inspector.materialSection
        #expect(!section.view.isHidden && section.isExpanded)

        // A built-in material: shown read-only, with New Material.
        #expect(section.editor == nil)
        #expect(section.view.descendant(named: "materialMakeCopy") != nil)
        #expect((section.view.descendant(named: "materialSource") as? Label)?.text.contains("Built-in") == true)

        // The material field opens the picker; picking a project material sets the renderer's (one undo step).
        let red = try #require(assets.references(of: .material).first { assets.record($0.asset)?.path == "Red.material" })
        let picker = try #require(section.picker)
        picker.onPick?()
        let dialog = try #require(app.ui.overlays.last as? AssetPickerDialog)
        #expect(dialog.shown.first?.caption == "Built-in" && dialog.shown.contains { $0.value == red.description })
        let depth = session.undo.undoDepth
        dialog.filter("red")
        #expect(dialog.shown.map(\.value) == [red.description])
        dialog.pickSelected()
        #expect(app.ui.overlays.isEmpty)
        #expect(session.world.get(MeshRenderer.self, for: cube)?.material.key == red.description)
        #expect(session.undo.undoDepth == depth + 1)
        app.syncPanels()
        let editor = try #require(section.editor)
        #expect(editor.isEditable && editor.reference == red)
        #expect(section.view.descendant(named: "materialForm") != nil)
        #expect(section.view.descendant(named: "materialOpenBuilder") != nil)
        #expect(section.picker?.title == "Red.material")

        // Its settings edit the material file itself, one undo step per gesture.
        func edit(_ phase: PropertyEditPhase, _ value: Double) {
            editor.handle(PropertyEdit(entity: editor.entity, componentName: "Material", path: "specular",
                                       oldValue: .float(0.35), newValue: .float(value), phase: phase))
        }
        let before = session.undo.undoDepth
        edit(.began, 0.35)
        edit(.changed, 0.6)
        app.syncPanels()  // a live edit bumps the revision: the form stays
        #expect(section.editor === editor)
        edit(.ended, 0.8)
        #expect(assets.material(red)?.specular == 0.8 && session.undo.undoDepth == before + 1)
        session.performUndo()
        app.syncPanels()
        #expect(assets.material(red)?.specular == 0.35 && editor.material?.specular == 0.35)

        // Folded: just the header.
        section.toggle()
        app.syncPanels()
        #expect(section.editor == nil && section.view.descendant(named: "materialForm") == nil && section.picker != nil)
        section.toggle()
        app.syncPanels()
        #expect(section.editor != nil)

        // The name and where it comes from get the column's width (they used to be squeezed to "…").
        app.ui.layoutIfNeeded()
        for name in ["materialName", "materialSource"] {
            let label = try #require(section.view.descendant(named: name))
            #expect(label.frame.width > 100 && label.frame.height < 30, "\(name): \(label.frame)")
        }
        let issues = app.ui.layoutAudit()
        #expect(issues.isEmpty, "\(issues.prefix(8).map { "\($0)" }.joined(separator: "\n"))")

        // An object without a MeshRenderer has no Material section.
        session.run(EntityCreateCommand.self, .init(template: .empty))
        app.syncPanels()
        #expect(section.view.isHidden)
    }

    @Test func makeEditableCopyWritesAMaterialAndUsesIt() throws {
        let folder = folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = try makeApp(folder)
        let session = app.session
        let cubeID = try #require(session.run(EntityCreateCommand.self, .init(template: .cube))?.entity)
        let cube = try #require(session.world.entity(for: cubeID))
        app.syncPanels()
        let builtIn = session.world.get(MeshRenderer.self, for: cube)?.material.key
        let materials = session.assets?.references(of: .material).count ?? 0
        let depth = session.undo.undoDepth
        let button = try #require(app.inspector.materialSection.view.descendant(named: "materialMakeCopy") as? Button)
        button.action?()
        app.syncPanels()
        #expect((session.assets?.references(of: .material).count ?? 0) == materials + 1)
        let key = try #require(session.world.get(MeshRenderer.self, for: cube)?.material.key)
        #expect(key != builtIn && app.inspector.materialSection.editor?.isEditable == true)
        #expect(session.undo.undoDepth == depth + 1)
        session.performUndo()
        #expect(session.world.get(MeshRenderer.self, for: cube)?.material.key == builtIn)
    }

    @Test func meshAndMaterialFieldsShowTheNameAndPickInADialog() throws {
        let folder = folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = try makeApp(folder)
        let session = app.session
        let cubeID = try #require(session.run(EntityCreateCommand.self, .init(template: .cube))?.entity)
        let cube = try #require(session.world.entity(for: cubeID))
        app.syncPanels()
        app.ui.layoutIfNeeded()
        let grid = app.inspector.grid
        let fields = allWidgets(grid).compactMap { $0 as? PickerField }
        #expect(fields.count == 2, "\(fields.map(\.title))")
        let mesh = try #require(fields.first { $0.title == "cube" })
        #expect(fields.contains { $0.title == session.world.get(MeshRenderer.self, for: cube)?.material.key })

        // The mesh picker lists the meshes, the current one selected; Esc or Cancel changes nothing.
        mesh.onPick?()
        var dialog = try #require(app.ui.overlays.last as? AssetPickerDialog)
        #expect(dialog.list.selectedRow.map { dialog.shown[$0].value } == "cube")
        #expect(dialog.shown.contains { $0.value == "sphere" } && !dialog.shown.contains { $0.value == "checker" })
        dialog.cancelButton.action?()
        #expect(app.ui.overlays.isEmpty && session.world.get(MeshRenderer.self, for: cube)?.mesh.key == "cube")

        // Type, move with the keys, Enter: the field shows the new name.
        mesh.onPick?()
        dialog = try #require(app.ui.overlays.last as? AssetPickerDialog)
        dialog.filter("sph")
        #expect(dialog.shown.map(\.value) == ["sphere"])
        dialog.pickSelected()
        #expect(session.world.get(MeshRenderer.self, for: cube)?.mesh.key == "sphere")
        app.syncPanels()
        #expect(allWidgets(grid).compactMap { $0 as? PickerField }.contains { $0.title == "sphere" })
    }
}
