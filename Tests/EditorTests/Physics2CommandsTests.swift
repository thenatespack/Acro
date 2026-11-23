import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EnginePhysics

private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// The physics v2 tools on a copy of SampleGame: physics materials, the material under a point,
/// and character state and actions while playing its Physics2 scene.
@MainActor @Suite struct Physics2CommandsTests {
    func session() throws -> (EditorSession, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Physics2CommandsTests-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: packageRoot.appendingPathComponent("Projects/SampleGame"), to: folder)
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        #expect(session.openProject(path: folder.path))
        #expect(session.open(path: "Scenes/Physics2.scene"))
        return (session, folder)
    }

    @Test func physicsMaterialFilesAreMadeEditedAndListed() throws {
        let (session, folder) = try session()
        defer { try? FileManager.default.removeItem(at: folder) }
        let made = try PhysicsMaterialNewCommand.run(.init(folder: "Physics", name: "Slick", preset: "ice"), in: session)
        #expect(made.path == "Physics/Slick.physmat" && made.friction == 0.03 && made.warnings.isEmpty)
        let edited = try PhysicsMaterialEditCommand.run(.init(path: "Physics/Slick.physmat", changes: .object([
            "bounce": .double(0.4), "impact": .object(["sound": .string("Sounds/Missing.sfx")]), "pairs": .object(["lava": .object([:])]),
        ])), in: session)
        #expect(edited.material.bounce == 0.4 && edited.material.friction == 0.03)
        #expect(edited.warnings.contains { $0.contains("impact.sound: no asset 'Sounds/Missing.sfx'") })
        #expect(edited.warnings.contains { $0.contains("pairs.lava") })
        let got = try PhysicsMaterialGetCommand.run(.init(path: "Physics/Slick.physmat"), in: session)
        #expect(got.material == edited.material)
        // Undo puts the old file back.
        #expect(session.performUndo())
        #expect(try PhysicsMaterialGetCommand.run(.init(path: "Physics/Slick.physmat"), in: session).material.bounce == 0.05)
        let list = try PhysicsMaterialListCommand.run(.init(), in: session).materials
        #expect(list.contains { $0.name == "Physics/Slick.physmat" && !$0.builtIn })
        #expect(list.contains { $0.name == "climbingWall" && $0.climbable == true })
        #expect(throws: (any Error).self) { try PhysicsMaterialNewCommand.run(.init(preset: "lava"), in: session) }
    }

    @Test func materialUnderAPointWhileEditing() throws {
        let (session, folder) = try session()
        defer { try? FileManager.default.removeItem(at: folder) }
        let floor = try PhysicsMaterialAtCommand.run(.init(point: Vec3(-3, 0.5, 3)), in: session)
        #expect(floor.hit && floor.material == "concrete" && floor.friction == 0.8)
        let ice = try PhysicsMaterialAtCommand.run(.init(point: Vec3(6, 0.5, -8.5)), in: session)
        #expect(ice.material == "ice" && ice.friction == 0.03)
        #expect(try !PhysicsMaterialAtCommand.run(.init(point: Vec3(0, 50, 0), distance: 1), in: session).hit)
    }

    @Test func characterStateAndActionsWhilePlaying() throws {
        let (session, folder) = try session()
        defer { try? FileManager.default.removeItem(at: folder) }
        var found: Entity?
        session.world.query(Name.self) { e, name in if name.value == "Player" { found = e } }
        let player = try #require(found)
        let id = try #require(session.world.id(of: player))
        #expect(throws: (any Error).self) { try session.commands.run(CharacterActionCommand.self, .init(entity: id, action: .jump)) }
        session.play(paused: true)
        #expect(session.isPlaying)
        _ = session.step(frames: 10)
        var state = try CharacterStateCommand.run(.init(entity: id), in: session)
        #expect(state.grounded && state.mode == "walking" && state.ground == "concrete" && !state.crouching, "\(state)")
        // The Player's script sets `crouch` every frame from its input action, so jump instead.
        state = try CharacterActionCommand.run(.init(entity: id, action: .jump), in: session)
        _ = session.step(frames: 3)
        state = try CharacterStateCommand.run(.init(entity: id), in: session)
        #expect(!state.grounded && state.verticalVelocity > 3 && state.canStand, "\(state)")
        session.stop()
    }
}
