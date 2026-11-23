import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineRendering

/// Camera rigs: the four modes, collision, damping, blends and input.
@MainActor @Suite struct CameraRigTests {
    /// A world with physics, a camera, a capsule character at the origin facing +Z (with its own
    /// collider, which the rig must ignore) and a rig following it.
    @MainActor struct Scene {
        let world = World()
        let physics = PhysicsWorld()
        let input = Input()
        var camera = Entity.invalid
        var player = Entity.invalid
        var rig = Entity.invalid

        init(rig settings: CameraRig = CameraRig()) {
            world.addPhysics(physics)
            _ = world.spawn(Transform(position: Vec3(0, -0.5, 0)), Name("Floor"), Collider(.box(halfExtents: Vec3(100, 0.5, 100))))
            camera = world.spawn(Transform(position: Vec3(0, 5, 20)), Camera(), Name("Camera"))
            let controller = CharacterController()
            player = world.spawn(Transform(), Name("Player"), controller,
                                 Collider(controller.colliderShape, offset: controller.colliderOffset), RigidBody(.kinematic))
            var settings = settings
            settings.target = world.ref(to: player)
            rig = world.spawn(Transform(), Name("Rig"), settings)
            world.addCameraRigs(input: input)
        }

        func step(_ frames: Int = 1, dt: Double = 1.0 / 60) {
            for _ in 0..<frames {
                input.beginFrame()
                input.endEvents()
                world.update(dt: dt)
            }
        }

        var cameraPosition: Vec3 { world.get(Transform.self, for: camera)!.position }
        var cameraForward: Vec3 { world.get(Transform.self, for: camera)!.rotation * Vec3(0, 0, -1) }

        /// A static wall box.
        @discardableResult
        func wall(center: Vec3, size: Vec3) -> Entity {
            world.spawn(Transform(position: center), Name("Wall"), Collider(.box(halfExtents: size / 2)))
        }
    }

    @Test func emptyJSONDecodesToDefaultsAndRoundTrips() throws {
        let rig = try JSONDecoder().decode(CameraRig.self, from: Data("{}".utf8))
        #expect(rig.mode == .thirdPerson && rig.enabled && rig.priority == 0 && rig.collision)
        #expect(rig.resolvedDistance == 4 && rig.resolvedPitch == 15)
        var changed = CameraRig(mode: .sideScroller, priority: 3, distance: 9, lookAhead: 3)
        changed.fieldOfView = 50
        let back = try JSONDecoder().decode(CameraRig.self, from: JSONEncoder().encode(changed))
        #expect(back == changed)
        // Mode defaults for the optional settings.
        #expect(CameraRig(mode: .topDown).resolvedPitch == 60)
        #expect(CameraRig(mode: .firstPerson).resolvedPositionDamping == .zero)
    }

    @Test func thirdPersonSitsBehindAndAboveTheTarget() {
        let scene = Scene(rig: CameraRig(shoulderOffset: .zero))
        scene.step(2)
        let p = scene.cameraPosition
        // Behind (-Z, the target faces +Z), above the 1.6 m pivot, 4 m away from it.
        #expect(p.z < -3)
        #expect(p.y > 1.6)
        #expect(abs(length(p - Vec3(0, 1.6, 0)) - 4) < 0.05)
        #expect(scene.cameraForward.z > 0.9)
        #expect(scene.world.get(Camera.self, for: scene.camera)!.isActive)
        #expect(scene.world.liveCameraRig == scene.rig)
    }

    @Test func collisionKeepsTheCameraInFrontOfAWall() {
        let scene = Scene(rig: CameraRig(shoulderOffset: .zero, pitch: 0))
        // A wall 2 m behind the character (its front face at z = -2).
        scene.wall(center: Vec3(0, 2, -2.5), size: Vec3(6, 4, 1))
        scene.step(3)
        let p = scene.cameraPosition
        #expect(p.z > -2, "camera at \(p) went through the wall")
        #expect(p.z < -1.2)
        let rig = scene.world.get(CameraRig.self, for: scene.rig)!
        #expect(rig.probeHit)
        // The character's own capsule didn't count as a wall.
        #expect(p.z < -1)
    }

    @Test func pullsInFastAndEasesOutSlowly() {
        let scene = Scene(rig: CameraRig(shoulderOffset: .zero, pitch: 0, pullInTime: 0.04, easeOutTime: 0.5))
        scene.step(10)
        #expect(scene.cameraPosition.z < -3.9)
        // A wall appears behind the character: the camera comes in within a frame.
        let wall = scene.wall(center: Vec3(0, 2, -2.5), size: Vec3(6, 4, 1))
        scene.step(2)
        #expect(scene.cameraPosition.z > -2)
        // It goes away: the camera eases back out, not at once.
        scene.world.despawn(wall)
        scene.step(6)
        let partway = scene.cameraPosition.z
        #expect(partway < -2 && partway > -3.9, "after 0.1 s: \(partway)")
        scene.step(180)
        #expect(scene.cameraPosition.z < -3.95)
    }

    @Test func ignoresTheTargetsChildCollidersAndRagdollBones() {
        let scene = Scene(rig: CameraRig(shoulderOffset: .zero, pitch: 0))
        // A big collider on a child of the character (a ragdoll bone, a held shield) spanning the probe.
        let child = scene.world.spawn(Transform(position: Vec3(0, 1.6, -2)), Name("Bone"), Collider(.box(halfExtents: Vec3(1, 1, 0.5))))
        scene.world.setParent(child, to: scene.player)
        scene.step(3)
        #expect(scene.cameraPosition.z < -3.9)
        #expect(!(scene.world.get(CameraRig.self, for: scene.rig)!.probeHit))
    }

    @Test func dampingIsFramerateIndependent() {
        func run(fps: Double) -> Vec3 {
            let scene = Scene(rig: CameraRig(shoulderOffset: .zero, collision: false))
            scene.step(1, dt: 1 / fps)
            let frames = Int(fps)
            for k in 0..<frames {
                // The target slides +X at 3 m/s.
                scene.world.modify(Transform.self, for: scene.player) { $0.position.x = 3 * Float(k + 1) / Float(fps) }
                scene.step(1, dt: 1 / fps)
            }
            return scene.cameraPosition
        }
        let slow = run(fps: 30), fast = run(fps: 144)
        #expect(length(slow - fast) < 0.08, "30 fps \(slow) vs 144 fps \(fast)")
        // Damped: the camera trails the target a little.
        #expect(fast.x < 3 && fast.x > 2.5)
    }

    @Test func autoRecenterSwingsBehindTheMovingTarget() {
        let scene = Scene(rig: CameraRig(recenterDelay: 0.2, recenterTime: 0.2, collision: false))
        scene.step(2)
        // The character turns to face +X and walks.
        scene.world.modify(Transform.self, for: scene.player) { $0.rotation = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)) }
        for k in 0..<120 {
            scene.world.modify(Transform.self, for: scene.player) { $0.position.x = Float(k) * 0.05 }
            scene.step()
        }
        // Behind it now means looking along +X.
        #expect(scene.cameraForward.x > 0.9, "forward \(scene.cameraForward)")
    }

    @Test func rightStickOrbitsAndInvertFlipsIt() {
        func yawAfterStick(invert: Bool) -> Float {
            let scene = Scene(rig: CameraRig(autoRecenter: false, collision: false, rotationDamping: .zero, invertX: invert))
            scene.step()
            for _ in 0..<30 {
                scene.input.beginFrame()
                scene.input.updateGamepads([GamepadSnapshot(id: 0, rightStick: Vec2(1, 0))])
                scene.input.endEvents()
                scene.world.update(dt: 1.0 / 60)
            }
            let f = scene.cameraForward
            return atan2f(-f.x, -f.z) * 180 / .pi
        }
        // Behind a +Z-facing target the heading is 180; full right stick turns right (heading decreases) at 150 deg/s.
        let normal = CameraRigSystem.wrapDegrees(yawAfterStick(invert: false) - 180)
        let inverted = CameraRigSystem.wrapDegrees(yawAfterStick(invert: true) - 180)
        #expect(abs(normal + 75) < 3, "\(normal)")
        #expect(abs(inverted - 75) < 3, "\(inverted)")
    }

    @Test func mouseOrbitsWhileTheRightButtonIsHeldAndScrollZooms() {
        let scene = Scene(rig: CameraRig(shoulderOffset: .zero, autoRecenter: false, collision: false, rotationDamping: .zero))
        scene.step()
        let before = scene.cameraPosition
        scene.input.beginFrame()
        scene.input.inject(.mouseMove(to: Vec2(100, 100)))
        scene.input.endEvents()
        scene.world.update(dt: 1.0 / 60)
        scene.input.beginFrame()
        scene.input.inject(.button(.right, down: true))
        scene.input.inject(.mouseMove(to: Vec2(200, 100)))
        scene.input.endEvents()
        scene.world.update(dt: 1.0 / 60)
        // 100 points at 0.2 deg/point: 20 degrees around.
        let after = scene.cameraPosition
        let turned = acosf(min(dot(normalize(before - Vec3(0, 1.6, 0)), normalize(after - Vec3(0, 1.6, 0))), 1)) * 180 / .pi
        #expect(abs(turned - 20) < 1.5, "\(turned)")
        scene.input.beginFrame()
        scene.input.inject(.button(.right, down: false))
        scene.input.inject(.scroll(Vec2(0, 25)))
        scene.input.endEvents()
        scene.world.update(dt: 1.0 / 60)
        // 25 points x 4 m/s x 0.01 = 1 m closer.
        #expect(abs(length(scene.cameraPosition - Vec3(0, 1.6, 0)) - 3) < 0.05)
    }

    @Test func firstPersonLooksFromTheEyesAndBobsWhileWalking() {
        let scene = Scene(rig: CameraRig(mode: .firstPerson))
        scene.step()
        #expect(length(scene.cameraPosition - Vec3(0, 1.6, 0)) < 0.01, "\(scene.cameraPosition)")
        #expect(scene.cameraForward.z > 0.99)
        var heights: [Float] = []
        for k in 0..<90 {
            scene.world.modify(Transform.self, for: scene.player) { $0.position.z = Float(k) * 0.07 }
            scene.step()
            heights.append(scene.cameraPosition.y)
        }
        #expect((heights.max()! - heights.min()!) > 0.03)
        #expect(abs(scene.cameraPosition.z - 89 * 0.07) < 0.05)
    }

    @Test func topDownLooksDownFromAbove() {
        let scene = Scene(rig: CameraRig(mode: .topDown))
        scene.step()
        let p = scene.cameraPosition
        #expect(p.y > 12, "\(p) \(scene.world.get(Transform.self, for: scene.player)!.position)")
        #expect(abs(scene.cameraForward.y + sinf(60 * .pi / 180)) < 0.01)
        // Heading 0: looking along -Z, so the camera is on the +Z side.
        #expect(p.z > 5)
    }

    @Test func sideScrollerKeepsADeadZoneAndLooksAhead() {
        let scene = Scene(rig: CameraRig(mode: .sideScroller, deadZone: Vec2(1, 1), lookAhead: 2, lookAheadTime: 0.05,
                                         collision: false, positionDamping: .zero))
        scene.step()
        let start = scene.cameraPosition
        #expect(start.z > 9)
        #expect(abs(scene.cameraForward.z + cosf(5 * .pi / 180)) < 0.01)
        // Inside the dead zone the camera holds still.
        scene.world.modify(Transform.self, for: scene.player) { $0.position.y = 0.6 }
        scene.step()
        #expect(abs(scene.cameraPosition.y - start.y) < 1e-3)
        // Running right past it: the camera follows and leads by the look-ahead.
        for k in 0..<60 {
            scene.world.modify(Transform.self, for: scene.player) { $0.position.x = Float(k + 1) * 0.1 }
            scene.step()
        }
        let x = scene.cameraPosition.x
        // focus = 6 - 1 (dead zone), plus about 2 ahead.
        #expect(x > 6.5 && x < 7.1, "\(x)")
    }

    @Test func switchingRigsBlendsOverTheBlendTime() {
        let scene = Scene(rig: CameraRig(collision: false))
        let top = scene.world.spawn(Transform(), Name("Top"),
                                    CameraRig(mode: .topDown, target: scene.world.ref(to: scene.player), priority: -1, blendTime: 1, blendCurve: .linear))
        scene.step(2)
        let from = scene.cameraPosition
        let goal = CameraRigSystem.probe(of: top, in: scene.world)!.pose.position
        #expect(length(from - goal) > 5)
        #expect(scene.world.activateCameraRig(top))
        #expect(scene.world.get(CameraRig.self, for: top)!.priority == 1)
        scene.step(30)
        let mid = scene.cameraPosition
        let weight = scene.world.get(CameraRig.self, for: top)!.blendWeight
        #expect(abs(weight - 0.5) < 0.03, "\(weight)")
        #expect(length(mid - (from + (goal - from) * weight)) < 0.1, "\(from) \(goal) \(mid) \(weight)")
        #expect(scene.world.cameraRigs!.isBlending)
        scene.step(31)
        #expect(length(scene.cameraPosition - goal) < 0.02)
        #expect(!scene.world.cameraRigs!.isBlending)
        #expect(scene.world.get(CameraRig.self, for: top)!.isLive)
        #expect(!(scene.world.get(CameraRig.self, for: scene.rig)!.isLive))
        // An explicit blend time of 0 cuts.
        scene.world.activateCameraRig(scene.rig, blendTime: 0)
        scene.step()
        #expect(length(scene.cameraPosition - CameraRigSystem.probe(of: scene.rig, in: scene.world)!.pose.position) < 1e-3)
    }

    @Test func fixedRigBlendsToAPlacedCamera() {
        let scene = Scene(rig: CameraRig(collision: false))
        let shot = scene.world.spawn(Transform.looking(from: Vec3(10, 3, 0), at: .zero), Name("Shot"),
                                     CameraRig(mode: .fixed, priority: -5, blendTime: 0.5, blendCurve: .linear))
        scene.step(2)
        scene.world.activateCameraRig(shot)
        scene.step(31)
        #expect(length(scene.cameraPosition - Vec3(10, 3, 0)) < 1e-3)
    }

    @Test func previewSettlesWithoutTheSystem() {
        let world = World()
        let target = world.spawn(Transform(position: Vec3(2, 0, 0)))
        let rig = world.spawn(Transform(), CameraRig(target: world.ref(to: target), shoulderOffset: .zero))
        let probe = CameraRigSystem.preview(rig, in: world, physics: nil)!
        #expect(abs(length(probe.pose.position - Vec3(2, 1.6, 0)) - 4) < 1e-3)
        #expect(probe.start == Vec3(2, 1.6, 0))
        #expect(probe.hit == nil)
    }
}
