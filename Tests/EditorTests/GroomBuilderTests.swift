import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuilders2D
@testable import EditorBuildersAnimation
@testable import EditorBuildersLogic
@testable import EditorBuildersMesh
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// The Groom Builder as an agent uses it (groom.* tools) and as a user does (the tab's form and brushes).

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("GroomBuilderTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct GroomBuilderTests {
    @Test func newGetEditSetAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "groom.new", ["preset": "shaggyFur", "folder": "Grooms"])
        #expect(created["path"] as? String == "Grooms/ShaggyFur.groom")
        #expect(created["style"] as? String == "shell")
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        #expect((created["material"] as? String)?.hasSuffix("#material/fur") == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isGroomFile(id))

        let edited = try call(session, "groom.edit", [
            "path": "Grooms/ShaggyFur.groom",
            "changes": ["length": 0.1, "tipColor": [1, 0.9, 0.8], "lod": ["shells": [16, 8], "distances": [4, 9]]],
            "addComb": [["center": [0, 0.5, 0], "radius": 0.2, "direction": [0, 0, -1]]],
            "addCut": [["center": [0, -0.5, 0], "radius": 0.2, "length": 0]],
        ])
        #expect(edited["levels"] as? [Double] == [16, 8])
        var build = try #require(session.assets?.groom(of: id))
        #expect(build.length == 0.1 && build.tipColor == Vec3(1, 0.9, 0.8) && build.comb.count == 1 && build.cut.count == 1)
        #expect(build.clumping == GroomBuild.preset("shaggyFur")!.clumping, "untouched fields keep their values")

        let got = try call(session, "groom.get", ["asset": "asset:\(id)"])
        #expect((got["groom"] as? [String: Any])?["length"] as? Double == 0.1)

        try call(session, "edit.undo")
        build = try #require(session.assets?.groom(of: id))
        #expect(build.length == GroomBuild.preset("shaggyFur")!.length && build.comb.isEmpty)

        let set = try call(session, "groom.set", ["path": "Grooms/ShaggyFur.groom", "groom": ["style": "cards", "length": 2.5]])
        #expect(set["style"] as? String == "cards")
        #expect((set["warnings"] as? [String])?.contains { $0.contains("length") } == true)
        #expect(throws: (any Error).self) { try call(session, "groom.new", ["preset": "nope"]) }
        #expect(throws: (any Error).self) { try call(session, "groom.edit", ["path": "Grooms/ShaggyFur.groom", "changes": 3]) }
    }

    @Test func presetsAndExamplesAreClean() throws {
        let session = makeSession()
        let presets = try call(session, "groom.presets")["presets"] as? [[String: Any]] ?? []
        #expect(presets.map { $0["name"] as? String } == GroomBuild.presetNames)
        #expect(presets.allSatisfy { ($0["about"] as? String)?.contains("budget") == true })
        let examples = GroomExamplesCommand.examples
        #expect(examples.count == 3)
        for example in examples { #expect(GroomCheck.problems(example.groom).isEmpty, "\(example.name)") }
        let one = try call(session, "groom.examples", ["name": "moss patch"])
        #expect((one["examples"] as? [[String: Any]])?.count == 1)
    }

    @Test func applyToEntitiesCharactersAndMeshBuilds() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        try call(session, "groom.new", ["preset": "shortFur", "name": "Fur"])

        // An entity: a sphere gets a GroomRenderer (undoable); a cube is warned about.
        let ball = try #require((try call(session, "entity.create", ["template": "sphere", "name": "Ball"])["entity"] as? String).flatMap(EntityID.init))
        let applied = try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["entity": ball.description]])
        #expect(applied["applied"] as? [String] == ["Ball"])
        #expect((applied["furTriangles"] as? Int ?? 0) > 0)
        let entity = try #require(session.world.entity(for: ball))
        #expect(session.world.get(GroomRenderer.self, for: entity)?.groom.key.hasSuffix("#material/fur") == true)
        try call(session, "edit.undo")
        #expect(session.world.get(GroomRenderer.self, for: entity) == nil)
        let box = try #require((try call(session, "entity.create", ["template": "cube", "name": "Box"])["entity"] as? String).flatMap(EntityID.init))
        let boxed = try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["entity": box.description]])
        #expect((boxed["warnings"] as? [String])?.contains { $0.contains("12 triangles") } == true)
        let removed = try call(session, "groom.apply", ["groom": "", "remove": true, "target": ["entity": box.description]])
        #expect(removed["applied"] as? [String] == ["Box"])
        #expect(session.world.get(GroomRenderer.self, for: try #require(session.world.entity(for: box))) == nil)

        // A character region and a mesh build part.
        let character = try assets.createCharacter(CharacterBuild(template: .quadruped), at: "Fox.character")
        let onFox = try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["character": "Fox.character", "part": "body"]])
        #expect(onFox["applied"] as? [String] == ["region body"])
        #expect(assets.character(of: character)?.grooms["body"] == "Fur.groom")
        #expect((onFox["furTriangles"] as? Int ?? 0) > 0, "checked on the imported body mesh")
        #expect(throws: (any Error).self) {
            try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["character": "Fox.character", "part": "tentacle"]])
        }
        let model = try assets.createMeshBuild(MeshBuild(parts: [MeshBuildPart(name: "Rock", shape: .sphere)]), at: "Rock.meshbuild")
        try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["meshBuild": "Rock.meshbuild", "part": "Rock"]])
        #expect(assets.meshBuild(of: model)?.parts[0].groom == "Fur.groom")
        try call(session, "edit.undo")
        #expect(assets.meshBuild(of: model)?.parts[0].groom == nil)
        #expect(throws: (any Error).self) {
            try call(session, "groom.apply", ["groom": "Fur.groom", "target": ["entity": ball.description, "meshBuild": "Rock.meshbuild"]])
        }
    }

    @Test func tabFormAndBrushesWriteTheFile() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "groom.new", ["preset": "moss"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        let workspace = GroomBuilderWorkspace(session: session)
        var opened: AssetID?
        session.onOpenGroom = { opened = $0; workspace.open($0) }
        try call(session, "groom.open", ["asset": "asset:\(id)"])
        #expect(opened == id && workspace.asset == id)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.furredEntities.count == 1, "the preview sphere wears the fur")

        // A mask stroke: two dabs, one undo step with cut strokes to length 0.
        workspace.brush = .mask
        workspace.dab(at: Vec3(0, 0.5, 0), direction: nil)
        workspace.dab(at: Vec3(0.2, 0.45, 0), direction: nil)
        workspace.commitStroke()
        var build = try #require(session.assets?.groom(of: id))
        #expect(build.cut.count == 2 && build.cut.allSatisfy { $0.length == 0 })
        // A comb stroke needs a direction.
        workspace.brush = .comb
        workspace.dab(at: Vec3(0, 0.5, 0), direction: nil)
        workspace.dab(at: Vec3(0, 0.4, 0.1), direction: Vec3(0, -0.1, 0.1))
        workspace.commitStroke()
        build = try #require(session.assets?.groom(of: id))
        #expect(build.comb.count == 1)
        try call(session, "edit.undo")
        #expect(session.assets?.groom(of: id)?.comb.isEmpty == true)

        // The brush finds the preview mesh under a ray.
        let tool = GroomBrushTool(workspace: workspace)
        let hit = tool.hit(ViewportRay(origin: Vec3(0, 3, 0), direction: Vec3(0, -1, 0)))
        #expect(hit.map { abs($0.local.y - 0.5) < 0.02 } == true, "the top of the sphere")

        // The form's edits.
        let view = try #require(workspace.builder)
        var edited = view.build
        edited.length = 0.05
        view.apply(edited, label: "Edit Groom")
        view.refresh()
        #expect(session.assets?.groom(of: id)?.length == 0.05)
        workspace.close()
        #expect(workspace.asset == nil)
    }
}
