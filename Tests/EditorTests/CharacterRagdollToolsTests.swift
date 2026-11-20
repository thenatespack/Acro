import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersAnimation
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineRendering

// The Character Builder's ragdoll and IK (character.ragdoll, character.ik, the tab's Test Ragdoll)
// and IK nodes in animation graphs (animGraph.edit addIK / updateIK / removeIK).

@MainActor
@Suite(.serialized) struct CharacterRagdollToolsTests {
    private func makeSession() -> EditorSession {
        EditorComponentCatalog.registerBuiltins()
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        return session
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CharacterRagdollToolsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
        let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    @Test func ragdollToolSizesBodiesEditsLimitsAndUndoes() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "character.new", ["name": "Hero", "place": true])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        // Reading changes nothing: the automatic bodies, no ragdoll yet.
        let read = try call(session, "character.ragdoll", ["path": "Hero.character"])
        #expect(read["enabled"] as? Bool == false)
        let bodies = try #require(read["bodies"] as? [[String: Any]])
        #expect(bodies.count == 11)
        let total = bodies.reduce(0.0) { $0 + ($1["mass"] as? Double ?? 0) }
        #expect(abs(total - 70) < 0.5, "\(total)")
        let knee = try #require(bodies.first { $0["bone"] as? String == "lowerLeg.L" })
        #expect(knee["joint"] as? String == "hinge" && knee["parent"] as? String == "upperLeg.L")
        #expect(session.assets?.character(of: id)?.ragdoll == nil)

        // Enable with a heavier body and a stiffer knee.
        let edited = try call(session, "character.ragdoll", ["path": "Hero.character", "enabled": true, "mass": 90,
                                                             "bones": [["bone": "lowerLeg.L", "maxAngle": 100, "radius": 0.08]]])
        #expect(edited["enabled"] as? Bool == true && edited["mass"] as? Double == 90)
        #expect((edited["warnings"] as? [String])?.isEmpty == true, "\(edited["warnings"] ?? "")")
        let changed = try #require((edited["bodies"] as? [[String: Any]])?.first { $0["bone"] as? String == "lowerLeg.L" })
        #expect(changed["maxAngle"] as? Double == 100 && changed["edited"] as? Bool == true)
        let file = try #require(session.assets?.character(of: id))
        #expect(file.ragdoll?.mass == 90 && file.ragdoll?.bones == [CharacterRagdollBone(bone: "lowerLeg.L", radius: 0.08, maxAngle: 100)])
        // The placed copy has the Ragdoll.
        _ = session.prefabs.sync(session.world, database: try #require(session.assets))
        var ragdolls: [Ragdoll] = []
        session.world.query(Ragdoll.self) { _, r in ragdolls.append(r) }
        #expect(ragdolls.count == 1 && ragdolls.first?.mass == 90)
        #expect(ragdolls.first?.bones.first { $0.bone == "lowerLeg.L" }?.maxAngle == 100)

        // Merging keeps the earlier change; resetting drops it; a bone without a body is an error.
        try call(session, "character.ragdoll", ["path": "Hero.character", "bones": [["bone": "lowerLeg.L", "minAngle": -2]]])
        #expect(session.assets?.character(of: id)?.ragdoll?.override("lowerLeg.L") == CharacterRagdollBone(bone: "lowerLeg.L", radius: 0.08, minAngle: -2, maxAngle: 100))
        try call(session, "character.ragdoll", ["path": "Hero.character", "resetBones": ["lowerLeg.L"]])
        #expect(session.assets?.character(of: id)?.ragdoll?.bones.isEmpty == true)
        #expect(throws: (any Error).self) { try call(session, "character.ragdoll", ["path": "Hero.character", "bones": [["bone": "hand.L"]]]) }

        // Undo walks back; remove deletes the section.
        #expect(session.performUndo())
        #expect(session.assets?.character(of: id)?.ragdoll?.bones.count == 1)
        try call(session, "character.ragdoll", ["path": "Hero.character", "remove": true])
        #expect(session.assets?.character(of: id)?.ragdoll == nil)
        // Without the window there is no tab to test in.
        let test = try call(session, "character.ragdoll", ["path": "Hero.character", "test": true])
        #expect((test["warnings"] as? [String])?.contains { $0.contains("isn't open") } == true)
    }

    @Test func ikToolPutsNodesOnTheAnimator() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "character.new", ["name": "Hero", "place": true])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let result = try call(session, "character.ik", ["path": "Hero.character", "footPlacement": true, "lookAt": true, "lookTarget": "Player"])
        let nodes = try #require(result["nodes"] as? [[String: Any]])
        #expect(nodes.map { $0["name"] as? String } == ["Feet", "Look"])
        #expect(nodes[1]["targetEntity"] as? String == "Player")
        #expect(session.assets?.character(of: id)?.ik == CharacterIK(footPlacement: true, lookAt: true, lookTarget: "Player"))
        _ = session.prefabs.sync(session.world, database: try #require(session.assets))
        var ik: [AnimationIKNode]?
        session.world.query(Animator.self) { _, a in ik = a.ik }
        #expect(ik?.map(\.name) == ["Feet", "Look"])
        // Hands for a quadruped: a warning, no nodes.
        try call(session, "character.edit", ["path": "Hero.character", "template": "quadruped"])
        let quad = try call(session, "character.ik", ["path": "Hero.character", "handIK": true])
        #expect((quad["warnings"] as? [String])?.contains { $0.contains("no arms") } == true)
        #expect((quad["nodes"] as? [[String: Any]])?.contains { ($0["name"] as? String)?.hasPrefix("Hand") == true } == false)
        try call(session, "character.ik", ["path": "Hero.character", "remove": true])
        #expect(session.assets?.character(of: id)?.ik == nil)
    }

    @Test func builderTestRagdollDropsAndStandsThePreview() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let id = try #require(session.createCharacterAsset(in: "", name: "C", character: CharacterBuild()))
        let workspace = CharacterBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.update(input: nil, dt: 1.0 / 60)
        let root = try #require(workspace.root)
        #expect(!workspace.world.has(Ragdoll.self, for: root), "no ragdoll in the file")
        let view = try #require(workspace.builder)
        view.layout()
        #expect(workspace.testRagdoll(true))
        for _ in 0..<40 { workspace.update(input: nil, dt: 1.0 / 60) }
        #expect(workspace.isRagdollTesting)
        #expect(workspace.physics.ragdollBodies(of: root).count == 11)
        let head = workspace.world.get(Animator.self, for: root).flatMap { a in a.targets.first { workspace.world.get(Name.self, for: $0)?.value == "head" } }
        let y = Transform(matrix: workspace.world.worldMatrix(of: try #require(head))).position.y
        #expect(y < 1.2, "falling: head at \(y)")
        // Through the tool too: stand it up.
        let result = try call(session, "character.ragdoll", ["asset": "asset:\(id)", "test": false])
        #expect(result["tested"] as? Bool == false)
        #expect(!workspace.isRagdollTesting)

        // The form: enabling the ragdoll writes the file.
        var edited = view.character
        edited.ragdoll = CharacterRagdoll()
        view.apply(edited, label: "Edit Ragdoll")
        view.refresh()
        #expect(session.assets?.character(of: id)?.ragdoll?.enabled == true)
        workspace.update(input: nil, dt: 1.0 / 60)
        let rebuilt = try #require(workspace.root)
        #expect(workspace.world.get(Ragdoll.self, for: rebuilt)?.mode == .animated)
    }

    @Test func animGraphEditAddsUpdatesAndRemovesIK() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "animGraph.new", ["name": "Hero"])
        let path = try #require(created["path"] as? String)
        let added = try call(session, "animGraph.edit", ["path": path,
                                                          "parameters": [["name": "look", "type": "float", "default": 1]],
                                                          "addIK": [["name": "Look", "type": "aim", "bones": ["chest", "head"], "weightParameter": "look"],
                                                                    ["name": "Look", "type": "twoBoneIK", "bones": ["a", "b", "c"]]]])
        #expect((added["ik"] as? [String]) == ["Look (aim)", "Look 2 (twoBoneIK)"])
        let updated = try call(session, "animGraph.edit", ["path": path, "updateIK": ["Look 2": ["name": "Hand", "pole": [0, 0, -1]]]])
        #expect((updated["ik"] as? [String]) == ["Look (aim)", "Hand (twoBoneIK)"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.assets?.animationGraph(of: id)?.ik.last?.pole == Vec3(0, 0, -1))
        let removed = try call(session, "animGraph.edit", ["path": path, "removeIK": ["Look"]])
        #expect((removed["ik"] as? [String]) == ["Hand (twoBoneIK)"])
        #expect(throws: (any Error).self) { try call(session, "animGraph.edit", ["path": path, "removeIK": ["Nope"]]) }
    }
}
