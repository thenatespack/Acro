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

// Combat and interaction tools: animGraph.hitboxes, character.combat, combat.inspect,
// combat.simulateHit, combat.overlay, interaction.list and interaction.use.

@MainActor
@Suite(.serialized) struct CombatToolsTests {
    private func makeSession() -> EditorSession {
        EditorComponentCatalog.registerBuiltins()
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        return session
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CombatToolsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
        let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    @Test func componentsAreAddableWithIcons() {
        EditorComponentCatalog.registerBuiltins()
        for type in GameplayComponents.types {
            #expect(EditorComponentCatalog.makeDefault(named: type.componentName) != nil, "\(type.componentName)")
            #expect(EditorIcons.componentIconNames[type.componentName] != nil, "\(type.componentName)")
        }
    }

    @Test func animGraphHitboxesAddChangeRemoveAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "animGraph.new", ["name": "Fighter"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let path = try #require(created["path"] as? String)

        let added = try call(session, "animGraph.hitboxes", ["path": path, "add": [
            ["name": "Blade", "state": "Idle", "bone": "hand.R", "start": 0.2, "end": 0.5,
             "shape": ["kind": "capsule", "radius": 0.08, "to": [0, -0.7, 0]], "damage": ["amount": 30, "type": "slash"]]]])
        #expect((added["warnings"] as? [String])?.contains { $0.contains("hitbox") } == false, "\(added["warnings"] ?? "")")
        var graph = try #require(session.assets?.animationGraph(of: id))
        #expect(graph.hitboxes.count == 1 && graph.hitboxes[0].damage.amount == 30 && graph.hitboxes[0].shape.to == Vec3(0, -0.7, 0))
        // Change one key; the rest stays.
        try call(session, "animGraph.hitboxes", ["path": path, "add": [["name": "Blade", "damage": ["amount": 45]]]])
        graph = try #require(session.assets?.animationGraph(of: id))
        #expect(graph.hitboxes[0].damage.amount == 45 && graph.hitboxes[0].damage.type == "slash" && graph.hitboxes[0].start == 0.2)
        // A second, unnamed one gets a unique name; a bad state is a warning.
        let more = try call(session, "animGraph.hitboxes", ["path": path, "add": [["state": "Nope", "bone": "foot.L"]]])
        #expect((more["warnings"] as? [String])?.contains { $0.contains("Nope") } == true)
        #expect((more["hitboxes"] as? [[String: Any]])?.count == 2)
        try call(session, "animGraph.hitboxes", ["path": path, "remove": ["Hit"]])
        #expect(session.assets?.animationGraph(of: id)?.hitboxes.map(\.name) == ["Blade"])
        #expect(throws: (any Error).self) { try call(session, "animGraph.hitboxes", ["path": path, "remove": ["Missing"]]) }
        _ = try session.undo.undo()
        #expect(session.assets?.animationGraph(of: id)?.hitboxes.count == 2)
    }

    @Test func characterCombatPutsHealthHurtboxesAndHitboxesOnThePrefab() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "character.new", ["name": "Brute", "place": true])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        let read = try call(session, "character.combat", ["path": "Brute.character"])
        #expect(read["combat"] == nil && (read["hurtboxes"] as? [Any])?.isEmpty == true)
        let edited = try call(session, "character.combat", ["path": "Brute.character", "health": 250, "team": "enemies",
                                                             "regions": ["head": 3], "resistances": ["fire": 0.5]])
        #expect((edited["warnings"] as? [String])?.isEmpty == true, "\(edited["warnings"] ?? "")")
        let hurtboxes = try #require(edited["hurtboxes"] as? [[String: Any]])
        #expect(hurtboxes.count == 11)
        #expect(hurtboxes.first { $0["bone"] as? String == "head" }?["multiplier"] as? Double == 3)
        #expect((edited["hitboxes"] as? [[String: Any]])?.first?["bone"] as? String == "hand.R")
        #expect(session.assets?.character(of: id)?.combat?.health == 250)

        // The placed copy has them.
        _ = session.prefabs.sync(session.world, database: try #require(session.assets))
        var health: [Health] = []
        session.world.query(Health.self) { _, h in health.append(h) }
        #expect(health.count == 1 && health.first?.max == 250 && health.first?.team == "enemies" && health.first?.resistance(to: "fire") == 0.5)
        #expect(session.world.count(of: Hurtbox.self) == 11)
        var tracks: [HitboxTrack] = []
        session.world.query(Animator.self) { _, a in tracks += a.hitboxes ?? [] }
        #expect(tracks.map(\.name) == ["Attack"])

        // Inspect lists them; the overlay draws them.
        let inspect = try call(session, "combat.inspect")
        #expect((inspect["hurtboxes"] as? [Any])?.count == 11)
        #expect((inspect["hitboxes"] as? [[String: Any]])?.first?["active"] as? Bool == false)
        let overlay = try call(session, "combat.overlay", ["show": true])
        #expect(overlay["hurtboxes"] as? Int == 11 && session.sceneOverlays["combat"] != nil)
        let draw = DebugDraw()
        session.sceneOverlays["combat"]?(draw, session.world)
        #expect(!(draw.segments[.onTop] ?? []).isEmpty)
        try call(session, "combat.overlay", ["show": false])
        #expect(session.sceneOverlays["combat"] == nil)

        // Remove takes it all off again.
        try call(session, "character.combat", ["path": "Brute.character", "remove": true])
        #expect(session.assets?.character(of: id)?.combat == nil)
    }

    @Test func simulateHitAndInteractWhilePlaying() throws {
        let session = makeSession()
        let world = session.world
        let dummy = world.spawn(Transform(position: Vec3(0, 0, -2)), Name("CombatToolsTests.Dummy"), Health(max: 50))
        let head = world.spawn(Transform(position: Vec3(0, 1.6, 0)), Name("head"), Hurtbox(shape: .sphere(radius: 0.2), region: "head", multiplier: 2))
        _ = world.setParent(head, to: dummy)
        let player = world.spawn(Transform(), Name("CombatToolsTests.Player"), Interactor())
        let door = world.spawn(Transform(position: Vec3(0, 0, -1.2)), Name("CombatToolsTests.Door"), Interactable(), Door())
        #expect(throws: (any Error).self) { try call(session, "combat.simulateHit", ["victim": world.id(of: dummy)!.description]) }
        session.play(paused: true)
        #expect(session.step(frames: 1))

        let hit = try call(session, "combat.simulateHit", ["victim": try #require(session.world.id(of: dummy)).description, "bone": "head",
                                                           "damage": 10, "attacker": try #require(session.world.id(of: player)).description])
        let info = try #require(hit["hit"] as? [String: Any])
        #expect(info["damage"] as? Double == 20 && info["region"] as? String == "head")
        #expect((hit["health"] as? [String: Any])?["current"] as? Double == 30)
        let inspect = try call(session, "combat.inspect")
        #expect((inspect["recentHits"] as? [Any])?.count == 1)

        let list = try call(session, "interaction.list")
        let interactor = try #require((list["interactors"] as? [[String: Any]])?.first)
        #expect(interactor["prompt"] as? String == "[E] Open")
        #expect(interactor["focus"] as? String == session.world.id(of: door)?.description)
        #expect((list["glyphs"] as? [String: String])?["use"] == "E")
        let used = try call(session, "interaction.use")
        #expect(used["result"] as? String == "opened")
        #expect(session.world.get(Door.self, for: door)?.open == true)
        let doorID = try #require(session.world.id(of: door)), dummyID = try #require(session.world.id(of: dummy))
        session.stop()
        let restoredDoor = try #require(session.world.entity(for: doorID)), restoredDummy = try #require(session.world.entity(for: dummyID))
        #expect(session.world.get(Door.self, for: restoredDoor)?.open == false)
        #expect(session.world.get(Health.self, for: restoredDummy)?.current == 50)
    }
}
