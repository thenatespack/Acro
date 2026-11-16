import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets

// Plants through the tools: the plant examples stay light and quiet, results report triangles,
// and the Mesh Builder offers foliage.

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
@Suite(.serialized) struct MeshBuildFoliageToolsTests {
    @Test func plantExamplesAreLightAndQuiet() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MeshBuildFoliageToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        // Triangle targets: a whole tree well under 15k (the old noise-blob tree was about 100k).
        let targets: [String: Int] = ["Gnarled Tree": 12_000, "Shrub": 6_000, "Potted Fern": 10_000, "Small Pine": 14_000]
        for (name, limit) in targets {
            let example = try #require(MeshBuildExamples.all.first { $0.name == name }, "\(name)")
            #expect(example.build.parts.contains { $0.shape == MeshBuildShape.foliage || $0.isRibbon }, "\(name) uses plants")
            let listed = try call(session, "meshBuild.examples", ["name": name])
            let build = try #require((listed["examples"] as? [[String: Any]])?.first?["build"])
            let created = try call(session, "meshBuild.new", ["name": name, "build": build])
            #expect((created["warnings"] as? [String]) == [], "\(name): \(created["warnings"] ?? "")")
            let triangles = try #require(created["triangles"] as? Int, "\(name) reports its triangles")
            #expect(triangles > 1000 && triangles < limit, "\(name): \(triangles) triangles (limit \(limit))")
            #expect((created["bounds"] as? [String: Any])?["base"] as? Double == 0, "\(name) stands on y=0")
        }
    }

    @Test func toolDocsAndEditorOfferFoliage() {
        let doc = MeshBuildNewCommand.doc
        for text in ["foliage", "cardSize", "ribbon", "open", "pineNeedles", "triangles", "\"on\""] {
            #expect(doc.contains(text), "the format doc mentions \(text)")
        }
        #expect(MeshBuilderView.shapeButtons.contains { $0.0 == .foliage })
        var part = MeshBuildPart(name: "Foliage", shape: .foliage)
        MeshBuilderView.applyFoliageStarter(to: &part)
        #expect(part.resolvedLeafLook == .broadleaf && part.geometry() != nil)
    }
}
