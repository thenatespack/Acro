import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineUI

// Bevels and the profile shapes (lathe, extrude) through the meshBuild tools and the Mesh Builder form.

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
@Suite struct MeshBuildShapeToolsTests {
    @Test func toolsTakeProfilesAndBevelsAndWarn() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildShapeToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "meshBuild.new", [
            "name": "Shelf",
            "build": ["parts": [
                ["name": "Vase", "shape": "lathe", "profile": [[0, 0], [0.2, 0], [0.25, 0.3], [0.1, 0.6], [0.14, 0.7]]],
                ["name": "Sign", "shape": "extrude", "profile": [[0, 0], [1, 0]], "size": [1, 1, 0.1]],
            ]],
        ])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let warnings = created["warnings"] as? [String] ?? []
        #expect(warnings.count == 1 && warnings[0].contains("part 'Sign'") && warnings[0].contains("at least 3"), "\(warnings)")

        let edited = try call(session, "meshBuild.edit", [
            "asset": id.description,
            "updateParts": ["Sign": ["profile": [[0, 0], [0.6, 0], [0.6, 0.2], [0.2, 0.2], [0.2, 1], [0, 1]]],
                            "Vase": ["bevel": 0.1]],
            "addParts": [["name": "Crate", "shape": "box", "bevel": 0.05, "position": [1.5, 0.5, 0]]],
        ])
        #expect((edited["warnings"] as? [String]) == ["part 'Vase': bevel only rounds box and cylinder parts; this lathe ignores it"])
        let build = try #require(session.assets?.meshBuild(of: id))
        #expect(build.parts.first { $0.name == "Sign" }?.profile?.count == 6)
        #expect(build.parts.first { $0.name == "Crate" }?.bevel == 0.05)
        #expect(build.parts.allSatisfy { $0.geometry() != nil })

        let doc = MeshBuildNewCommand.doc
        #expect(doc.contains("lathe|extrude") && doc.contains("bevel") && doc.contains("profile"))
    }

    @Test func builderFormAddsProfileShapesAndEditsThem() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildShapeToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Props"))
        let view = try #require(MeshBuilderView(session: session, asset: id))

        // The box gets a bevel slider and no profile list.
        #expect(view.view.descendant(named: "meshBuildBevel") is Slider)
        #expect(view.view.descendant(named: "meshBuildProfileAdd") == nil)

        view.addPart(.lathe)
        view.refresh()
        let vase = try #require(view.build.parts.last)
        #expect(vase.shape == .lathe && vase.profile == MeshBuilderView.starterLathe)
        #expect(abs(vase.position.y - 1) < 1e-5, "its base (profile height 0) rests on the box's top")
        #expect(view.view.descendant(named: "meshBuildProfile.0.0") is NumberField)
        #expect(view.view.descendant(named: "meshBuildBevel") == nil)

        view.addPart(.extrude)
        view.refresh()
        let arrow = try #require(view.build.parts.last)
        #expect(arrow.shape == .extrude && arrow.profile == MeshBuilderView.starterExtrude && arrow.size.z == 0.15)
        let top = vase.position.y + vase.localBounds.center.y + vase.localBounds.halfExtent.y
        #expect(abs(arrow.position.y + arrow.localBounds.center.y - arrow.localBounds.halfExtent.y - top) < 1e-4, "stacked by bounds")

        // Add Point continues the outline.
        let add = try #require(view.view.descendant(named: "meshBuildProfileAdd") as? Button)
        add.action?()
        view.refresh()
        #expect(view.build.parts.last?.profile?.count == MeshBuilderView.starterExtrude.count + 1)
        #expect(session.performUndo())
        view.reload()
        #expect(view.build.parts.last?.profile == MeshBuilderView.starterExtrude)
        #expect(MeshBuilderView.shapeButtons.contains { $0.0 == .lathe } && MeshBuilderView.shapeButtons.contains { $0.0 == .extrude })
    }
}
