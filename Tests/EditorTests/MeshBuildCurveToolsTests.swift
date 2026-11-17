import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineUI

// Sweeps, lofts and deformers through the meshBuild tools and the Mesh Builder form.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct MeshBuildCurveToolsTests {
    @Test func toolsTakeCurvesAndDeformersAndWarn() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildCurveToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "meshBuild.new", [
            "name": "Props",
            "build": ["parts": [
                ["name": "Bottle", "shape": "loft", "sections": [["at": 0, "size": [0.3, 0.2], "roundness": 2], ["at": 0.3, "size": [0.3, 0.2]],
                                                                  ["at": 0.4, "size": [0.08, 0.08]], ["at": 0.5, "size": [0.08, 0.08]]]],
                ["name": "Handle", "shape": "sweep", "parent": "Bottle", "path": [[0.15, 0.08, 0], [0.26, 0.15, 0], [0.15, 0.25, 0]],
                 "radius": 0.015],
                ["name": "Rock", "shape": "sphere", "position": [0.3, 0.25, 0], "size": [0.5, 0.4, 0.5], "deform": ["noise": ["amount": 0.03]]],
                ["name": "Cable", "shape": "sweep", "path": [[0, 0, 0]], "position": [-0.5, 0, 0]],
            ]],
        ])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let warnings = created["warnings"] as? [String] ?? []
        #expect(warnings.contains { $0.contains("part 'Cable'") && $0.contains("at least 2") }, "\(warnings)")
        #expect(!warnings.contains { $0.contains("'Bottle'") || $0.contains("'Handle'") || $0.contains("'Rock'") }, "\(warnings)")
        let bounds = try #require(created["bounds"] as? [String: Any])
        #expect(bounds["base"] as? Double == 0, "the loft's base section is at y=0")

        // updateParts goes through the part's JSON: the new fields survive it.
        let edited = try call(session, "meshBuild.edit", [
            "asset": id.description,
            "updateParts": ["Rock": ["deform": [["twist": 30], ["bend": ["axis": "y", "degrees": 10]]]],
                            "Cable": ["path": [[0, 0.01, 0], [0.3, 0.01, 0.2]], "radius": 0.01]],
        ])
        #expect((edited["warnings"] as? [String]) == ["part 'Rock': deform 2: bend axis must be x or z (the way the top leans); it was ignored"],
                "\(edited["warnings"] ?? "")")
        let build = try #require(session.assets?.meshBuild(of: id))
        #expect(build.parts.first { $0.name == "Rock" }?.deform?.first == .twist(30))
        #expect(build.parts.first { $0.name == "Bottle" }?.sections?.count == 4)
        #expect(build.parts.allSatisfy { $0.geometry() != nil })

        let doc = MeshBuildNewCommand.doc
        #expect(doc.contains("sweep|loft") && doc.contains("radii") && doc.contains("roundness") && doc.contains("deform"))
        #expect(doc.contains(MeshBuildPart.curvesDoc))
    }

    @Test func builderFormEditsSweepsLoftsAndDeformers() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildCurveToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Props"))
        let view = try #require(MeshBuilderView(session: session, asset: id))
        #expect(MeshBuilderView.shapeButtons.contains { $0.0 == .sweep } && MeshBuilderView.shapeButtons.contains { $0.0 == .loft })

        // A sweep starts as a bent pipe standing on the box, with a row per path point.
        view.addPart(.sweep)
        view.refresh()
        let pipe = try #require(view.build.parts.last)
        #expect(pipe.shape == .sweep && pipe.path == MeshBuilderView.starterSweepPath && pipe.radius == MeshBuilderView.starterSweepRadius)
        #expect(pipe.shapeWarnings.isEmpty)
        let bottom = pipe.position.y + pipe.localBounds.center.y - pipe.localBounds.halfExtent.y
        #expect(abs(bottom - 1) < 1e-3, "it rests on the box's top")
        #expect(view.view.descendant(named: "meshBuildPath.0.0") is NumberField)
        #expect(view.view.descendant(named: "meshBuildSweepRadius") is NumberField)
        let add = try #require(view.view.descendant(named: "meshBuildPathAdd") as? Button)
        add.action?()
        view.refresh()
        #expect(view.build.parts.last?.path?.count == MeshBuilderView.starterSweepPath.count + 1)
        #expect(session.performUndo())
        view.reload()
        #expect(view.build.parts.last?.path == MeshBuilderView.starterSweepPath)

        // A deformer button adds one; its row and the subdivision level follow.
        let taper = try #require(view.view.descendant(named: "meshBuildDeform.taper") as? Button)
        taper.action?()
        view.refresh()
        #expect(view.build.parts.last?.deform == [.taper(0.6, 0.6)])
        #expect(view.view.descendant(named: "meshBuildDeform.0.taper.0") is NumberField)
        #expect(view.view.descendant(named: "meshBuildSubdivide") is NumberField)
        let remove = try #require(view.view.descendant(named: "meshBuildDeformRemove.0") as? Button)
        remove.action?()
        view.refresh()
        #expect(view.build.parts.last?.deform == nil)

        // A loft starts as a flask with a row per section.
        view.addPart(.loft)
        view.refresh()
        let flask = try #require(view.build.parts.last)
        #expect(flask.shape == .loft && flask.sections == MeshBuilderView.starterLoftSections && flask.shapeWarnings.isEmpty)
        #expect(view.view.descendant(named: "meshBuildSection.0.at") is NumberField)
        #expect(view.view.descendant(named: "meshBuildSection.0.roundness") is NumberField)
        #expect(view.view.descendant(named: "meshBuildPath.0.0") == nil)
        let addSection = try #require(view.view.descendant(named: "meshBuildSectionAdd") as? Button)
        addSection.action?()
        view.refresh()
        let sections = try #require(view.build.parts.last?.sections)
        #expect(sections.count == MeshBuilderView.starterLoftSections.count + 1)
        #expect(abs((sections.last?.at.split(.y).along ?? 0) - 0.58) < 1e-5, "continues the spacing")
        // Groups have nothing to deform.
        view.addPart(.group)
        view.refresh()
        #expect(view.view.descendant(named: "meshBuildDeform.taper") == nil)
    }
}
