import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EnginePhysics
@testable import EngineRendering

/// The camera rig tools, the Game view's camera in play mode, the catalog entry, icon and gizmo.
@MainActor @Suite struct CameraRigToolsTests {
    @MainActor struct Scene {
        let session: EditorSession
        let camera: Entity
        let player: Entity
        let orbit: Entity
        let top: Entity
        var world: World { session.world }
        func id(_ e: Entity) -> EntityID { world.id(of: e)! }
    }

    /// A floor, a camera, a character with a wall behind it, an orbit rig (live) and a top-down rig.
    func scene() -> Scene {
        EditorComponentCatalog.registerBuiltins()
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        let world = session.world
        _ = world.spawn(Transform(position: Vec3(0, -0.5, 0)), Name("Floor"), Collider(.box(halfExtents: Vec3(50, 0.5, 50))))
        let camera = world.spawn(Transform(position: Vec3(0, 3, 10)), Name("Main Camera"), Camera())
        let controller = CharacterController()
        let player = world.spawn(Transform(), Name("Player"), controller, Collider(controller.colliderShape, offset: controller.colliderOffset),
                                 RigidBody(.kinematic))
        _ = world.spawn(Transform(position: Vec3(0, 2, -2.5)), Name("Wall"), Collider(.box(halfExtents: Vec3(3, 2, 0.5))))
        let orbit = world.spawn(Transform(), Name("Orbit Rig"),
                                CameraRig(target: world.ref(to: player), priority: 1, shoulderOffset: .zero, pitch: 0))
        let top = world.spawn(Transform(), Name("Top Rig"),
                              CameraRig(mode: .topDown, target: world.ref(to: player), blendTime: 0.5, blendCurve: .linear))
        world.propagateTransforms()
        return Scene(session: session, camera: camera, player: player, orbit: orbit, top: top)
    }

    @Test func stateAndActivateWhileEditing() throws {
        let s = scene()
        var state = try s.session.commands.run(CameraRigStateCommand.self, .init())
        #expect(!state.playing && state.rigs.count == 2)
        #expect(state.live == s.id(s.orbit) && state.camera == s.id(s.camera))
        let top = try #require(state.rigs.first { $0.entity == s.id(s.top) })
        #expect(top.mode == "topDown" && !top.live && (top.cameraPosition?.y ?? 0) > 10)
        state = try s.session.commands.run(CameraRigActivateCommand.self, .init(entity: s.id(s.top)))
        #expect(state.live == s.id(s.top))
        #expect(s.world.get(CameraRig.self, for: s.top)?.priority == 2)
        // One undo step.
        #expect(s.session.performUndo())
        #expect(s.world.get(CameraRig.self, for: s.top)?.priority == 0)
        #expect(throws: (any Error).self) { try s.session.commands.run(CameraRigActivateCommand.self, .init(entity: s.id(s.player))) }
    }

    @Test func setTargetPointsTheRigAndUndoes() throws {
        let s = scene()
        let other = s.world.spawn(Transform(position: Vec3(8, 0, 0)), Name("Other"))
        let state = try s.session.commands.run(CameraRigSetTargetCommand.self, .init(entity: s.id(s.orbit), target: s.id(other)))
        #expect(state.rigs.first { $0.entity == s.id(s.orbit) }?.target == s.id(other))
        #expect(s.session.performUndo())
        #expect(s.world.resolve(s.world.get(CameraRig.self, for: s.orbit)!.target) == s.player)
    }

    @Test func playingMovesTheGameCameraAndBlendsBetweenRigs() throws {
        let s = scene()
        s.session.play(paused: true)
        defer { s.session.stop() }
        _ = s.session.step(frames: 5)
        let world = s.session.gameWorld
        let cameraZ = world.get(Transform.self, for: s.camera)!.position.z
        // The orbit rig put the game camera behind the player, in front of the wall (its face at z = -2).
        #expect(cameraZ > -2 && cameraZ < -1, "\(cameraZ)")
        var state = try s.session.commands.run(CameraRigStateCommand.self, .init())
        #expect(state.playing && state.live == s.id(s.orbit))
        #expect(state.rigs.first { $0.entity == s.id(s.orbit) }?.collisionHit == true)
        state = try s.session.commands.run(CameraRigActivateCommand.self, .init(entity: s.id(s.top)))
        _ = s.session.step(frames: 15)
        state = try s.session.commands.run(CameraRigStateCommand.self, .init())
        let top = try #require(state.rigs.first { $0.entity == s.id(s.top) })
        #expect(state.blending && top.live && abs(top.blendWeight - 0.5) < 0.05, "\(state)")
        _ = s.session.step(frames: 20)
        state = try s.session.commands.run(CameraRigStateCommand.self, .init())
        #expect(!state.blending)
        let goal = try #require(state.rigs.first { $0.entity == s.id(s.top) }?.cameraPosition)
        #expect(length(world.get(Transform.self, for: s.camera)!.position - goal) < 1e-3)
    }

    @Test func catalogIconAndGizmo() throws {
        let s = scene()
        #expect(EditorComponentCatalog.makeDefault(named: CameraRig.componentName) is CameraRig)
        #expect(EditorIcons.componentIconNames[CameraRig.componentName] == "camera-rig")
        #expect(EditorIcons.entityKind(s.top, in: s.world).kind == .camera)
        _ = EditorIcons.named("camera-rig")
        s.session.selection.set([s.id(s.orbit)])
        let draw = DebugDraw()
        CameraRigGizmos.draw(into: draw, session: s.session, labelPosition: { $0 }, labelSize: 12, labelShadow: Vec4(0, 0, 0, 1))
        #expect((draw.segments[.onTop]?.count ?? 0) > 20)
        // The selected rig's probe found the wall: its label and a red hit marker.
        #expect(draw.labels.contains { $0.text.contains("Orbit Rig") })
        #expect(draw.segments[.onTop]!.contains { $0.color.x > 0.9 && $0.color.y < 0.5 })
    }
}
