import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineUI

// Sculpt parts through the meshBuild tools, the spatial checks and the Mesh Builder form.

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
@Suite struct MeshBuildSculptToolsTests {
    /// A snowman-like sculpt whose children overlap, hide inside each other and include a cut.
    static let snowman: [[String: Any]] = [
        ["name": "Snowman", "shape": "sculpt", "position": [0, 0.4, 0]],
        ["name": "Low", "shape": "sphere", "parent": "Snowman", "size": [0.8, 0.8, 0.8]],
        ["name": "High", "shape": "sphere", "parent": "Snowman", "position": [0, 0.55, 0], "size": [0.55, 0.55, 0.55], "smooth": 0.1],
        // Wholly inside Low: as a part of its own it would be "hidden".
        ["name": "Core", "shape": "box", "parent": "Snowman", "size": [0.2, 0.2, 0.2]],
        ["name": "Left Eye", "shape": "sphere", "parent": "Snowman", "position": [-0.08, 0.62, -0.26], "size": [0.06, 0.06, 0.06],
         "blend": "subtract", "mirror": "x"],
    ]

    @Test func toolsMeshSculptsAndCheckThemAsOnePart() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "meshBuild.new", ["name": "Snowman", "build": ["parts": Self.snowman]])
        #expect((created["warnings"] as? [String]) == [], "no floating, hidden or buried children: \(created["warnings"] ?? "")")
        let bounds = try #require(created["bounds"] as? [String: Any])
        #expect(bounds["base"] as? Double == 0)
        let size = try #require(bounds["size"] as? [Double])
        #expect(abs(size[0] - 0.8) < 0.02 && abs(size[1] - 1.225) < 0.03, "\(size)")

        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let got = try call(session, "meshBuild.get", ["asset": id.description])
        let partBoxes = try #require((got["bounds"] as? [String: Any])?["parts"] as? [[String: Any]])
        #expect(partBoxes.compactMap { $0["part"] as? String } == ["Snowman"], "only the sculpt has a box")

        // A track on a child warns; one on the sculpt is fine.
        let animated = try call(session, "meshBuild.edit", ["asset": id.description,
                                                            "addMotions": [["part": "High", "kind": "bob"], ["part": "Snowman", "kind": "spin"]]])
        let warnings = animated["warnings"] as? [String] ?? []
        #expect(warnings.count == 1 && warnings[0].contains("'High', a child of sculpt 'Snowman'"), "\(warnings)")

        // A blend outside a sculpt warns.
        let stray = try call(session, "meshBuild.edit", ["asset": id.description, "removeAnimations": ["Idle"],
                                                         "addParts": [["name": "Hat", "shape": "cylinder", "position": [0, 1.3, 0],
                                                                       "size": [0.3, 0.2, 0.3], "smooth": 0.05]]])
        #expect((stray["warnings"] as? [String] ?? []).contains { $0.contains("'Hat'") && $0.contains("isn't in a sculpt") })

        let doc = MeshBuildNewCommand.doc
        #expect(doc.contains("|sculpt") && doc.contains(MeshBuildPart.sculptDoc) && doc.contains(EditorMeshBuildCommands.symmetryDoc))
    }

    @Test func checksSeeTheSculptNotItsChildren() throws {
        let build = try JSONDecoder().decode(MeshBuild.self, from: JSONSerialization.data(withJSONObject: ["parts": Self.snowman]))
        #expect(MeshBuildCheck.parts(of: build).map(\.name) == ["Snowman"])
        let (bounds, warnings) = MeshBuildCheck.spatial(build, includeParts: true)
        #expect(warnings.isEmpty, "\(warnings)")
        #expect(bounds?.parts?.map(\.part) == ["Snowman"])
        // The eyes are cut on both sides.
        let sculpting = build.expanded().gatheringSculpts(sources: build.expansion().sources)
        #expect(sculpting.build.parts[0].sculptChildren.map(\.part.name) == ["Low", "High", "Core", "Left Eye", "Right Eye"])
    }

    @Test func builderFormAddsASculptAndEditsBlends() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildSculptToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createMeshBuildAsset(in: "", name: "Props"))
        let view = try #require(MeshBuilderView(session: session, asset: id))
        #expect(MeshBuilderView.shapeButtons.contains { $0.0 == .sculpt })

        view.addPart(.sculpt)
        view.refresh()
        let sculpt = try #require(view.build.parts.first { $0.shape == .sculpt })
        #expect(view.selectedPart == sculpt.name && abs(sculpt.position.y - 1) < 1e-5, "stacked on the starter box")
        #expect(view.build.parts.filter { $0.parent == sculpt.name }.map(\.name) == ["Block", "Dome", "Hole"])
        #expect(MeshBuildCheck.problems(view.build, in: session).isEmpty)
        #expect(MeshBuildCheck.spatial(view.build).warnings.isEmpty, "\(MeshBuildCheck.spatial(view.build).warnings)")
        // The sculpt's rows: resolution and noise.
        let resolution = try #require(view.view.descendant(named: "meshBuildSculptResolution") as? NumberField)
        resolution.onEditEnded?(64, 96)
        view.refresh()
        #expect(view.build.parts.first { $0.shape == .sculpt }?.resolution == 96)
        #expect(view.view.descendant(named: "meshBuildSculptNoise.amount") is NumberField)
        #expect(view.view.descendant(named: "meshBuildSculptBlend") == nil)

        // A child's rows: blend and smooth.
        view.selectPart("Dome")
        let blend = try #require(view.view.descendant(named: "meshBuildSculptBlend") as? Dropdown)
        #expect(blend.selectedIndex == 0)
        blend.onChange?(2)
        view.refresh()
        #expect(view.build.parts.first { $0.name == "Dome" }?.blend == .intersect)
        let smooth = try #require(view.view.descendant(named: "meshBuildSculptSmooth") as? NumberField)
        smooth.onEditEnded?(0.12, 0)
        view.refresh()
        #expect(view.build.parts.first { $0.name == "Dome" }?.smooth == nil, "0 is the default, left out")
        #expect(session.performUndo())
        view.reload()
        #expect(view.build.parts.first { $0.name == "Dome" }?.smooth == 0.12)
    }
}
