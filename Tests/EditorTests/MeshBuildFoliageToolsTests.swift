import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild

// Plants through the tools: the plant examples use plants (their triangle counts and detail levels
// are checked where every example is imported, in MeshBuildSpatialTests), and the Mesh Builder
// offers foliage.

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
    /// Triangle limits for the plant examples: a whole tree well under 15k (the old noise-blob
    /// tree was about 100k). MeshBuildSpatialTests.examplesImportWithoutWarnings imports every
    /// example once and checks these, with their detail levels, on the same import.
    static let plantTriangleLimits: [String: Int] = ["Gnarled Tree": 12_000, "Shrub": 6_000, "Potted Fern": 10_000, "Small Pine": 14_000]

    @Test func plantExamplesUsePlants() throws {
        for name in Self.plantTriangleLimits.keys {
            let example = try #require(MeshBuildExamples.all.first { $0.name == name }, "\(name)")
            #expect(example.build.parts.contains { $0.shape == MeshBuildShape.foliage || $0.isRibbon }, "\(name) uses plants")
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
