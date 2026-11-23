import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineNet
@testable import EngineMeshBuild

/// Physics v2: character controller moves (crouch, ledges, mantling, climbing, platforms),
/// continuous collision and physics materials.
@MainActor @Suite struct Physics2Tests {
    let dt: Float = 1.0 / 60

    /// A static box from `min` to `max`.
    @discardableResult
    func box(_ physics: PhysicsWorld, _ lo: Vec3, _ hi: Vec3, motion: MotionType = .static) -> BodyID {
        physics.addBody(BodyDescriptor(motion: motion, pose: Pose(position: (lo + hi) * 0.5), shape: .box((hi - lo) * 0.5),
                                       material: ColliderMaterial(friction: 0.5)))
    }

    /// A world with a floor whose top is at y = 0.
    func floorWorld() -> PhysicsWorld {
        let physics = PhysicsWorld()
        box(physics, Vec3(-50, -1, -50), Vec3(50, 0, 50))
        return physics
    }

    /// Steps the character `steps` times with `velocity`, calling `input` before each step.
    func run(_ physics: PhysicsWorld, _ c: inout CharacterController, _ p: inout Vec3, _ velocity: Vec3 = .zero, steps: Int,
             input: ((inout CharacterController) -> Void)? = nil) {
        for _ in 0..<steps {
            c.moveVelocity = velocity
            input?(&c)
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
        }
    }

    // MARK: Crouch

    @Test func crouchShrinksAndStandsOnlyWithRoom() {
        let physics = floorWorld()
        // A low ceiling (1.3 m) over x > 2.
        box(physics, Vec3(2, 1.3, -2), Vec3(6, 1.6, 2))
        var c = CharacterController()
        var p = Vec3(0, 0.05, 0)
        run(physics, &c, &p, steps: 20)
        #expect(c.isGrounded && !c.isCrouching)
        // Standing, the ceiling stops it.
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 60)
        #expect(p.x < 2 - c.radius + 0.05)
        // Crouched, it walks under at crouch speed.
        let before = p.x
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 120) { $0.crouch = true }
        #expect(c.isCrouching && c.currentHeight == c.crouchHeight)
        #expect(p.x > 3 && p.x - before < 2 * 0.5 * 2 + 0.1)
        // Releasing crouch under the ceiling keeps it crouched.
        run(physics, &c, &p, steps: 10) { $0.crouch = false }
        #expect(c.isCrouching)
        #expect(!physics.canStand(c, at: p))
        // Out in the open it stands up.
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 200) { $0.crouch = false }
        #expect(p.x > 6.3 && !c.isCrouching)
    }

    // MARK: Ledges

    /// A 2 m wall (a cliff top at y = 2) facing -x at x = 1.
    func cliffWorld() -> PhysicsWorld {
        let physics = floorWorld()
        box(physics, Vec3(1, 0, -5), Vec3(4, 2, 5))
        return physics
    }

    @Test func grabsALedgeWhileFallingAndHangs() {
        let physics = cliffWorld()
        var c = CharacterController()
        c.grabLedges = true
        // Jump toward the wall from close by.
        var p = Vec3(0.3, 0.02, 0)
        run(physics, &c, &p, steps: 10)
        var caught = false
        for step in 0..<90 {
            c.moveVelocity = Vec3(1.5, 0, 0)
            c.jump = step == 0
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
            if c.mode == .hanging { caught = true; break }
        }
        #expect(caught)
        #expect(abs(c.ledgePoint.y - 2) < 0.02 && abs(c.ledgePoint.x - 1) < 0.02)
        #expect(abs(c.ledgeNormal.x + 1) < 1e-3)
        // It hangs still: hands at the edge, feet height * 1.1 below.
        let hang = p
        run(physics, &c, &p, steps: 30)
        #expect(c.mode == .hanging && length(p - hang) < 1e-4)
        #expect(abs(p.y - (2 - c.height * 1.1)) < 0.01)
        let hands = try! #require(c.handTargets)
        #expect(abs(hands.left.y - 2) < 0.01 && abs(hands.left.z - hands.right.z) > 0.2)
        // Shimmy sideways along the ledge.
        run(physics, &c, &p, Vec3(0, 0, 2), steps: 30)
        #expect(c.mode == .hanging && p.z > 0.4)
        // Drop lets go and falls to the floor.
        run(physics, &c, &p, steps: 1) { $0.drop = true }
        run(physics, &c, &p, steps: 60)
        #expect(c.mode == .walking && c.isGrounded && p.y < 0.05)
    }

    @Test func doesNotGrabWithoutTheSettingButGrabsOnRequest() {
        let physics = cliffWorld()
        var c = CharacterController()
        var p = Vec3(0.3, 0.02, 0)
        run(physics, &c, &p, steps: 10)
        run(physics, &c, &p, Vec3(1.5, 0, 0), steps: 60) { $0.jump = true }
        #expect(c.mode == .walking)
        // A grab request while jumping: within reach of the top.
        var grabbed = false
        for step in 0..<60 {
            c.moveVelocity = Vec3(1, 0, 0)
            c.jump = step == 0
            c.grabLedge = step > 15
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
            if c.mode == .hanging { grabbed = true; break }
        }
        #expect(grabbed)
        #expect(!c.grabLedge)
    }

    @Test func mantlesFromHangingOntoTheTop() {
        let physics = cliffWorld()
        var c = CharacterController()
        c.grabLedges = true
        var p = Vec3(0.3, 0.02, 0)
        run(physics, &c, &p, steps: 10)
        for step in 0..<90 where c.mode != .hanging {
            c.moveVelocity = Vec3(1.5, 0, 0)
            c.jump = step == 0
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
        }
        #expect(c.mode == .hanging)
        run(physics, &c, &p, steps: 1) { $0.mantle = true }
        #expect(c.mode == .mantling)
        run(physics, &c, &p, steps: Int(c.mantleTime / dt) + 5)
        #expect(c.mode == .walking && c.isGrounded)
        #expect(p.x > 1 + c.radius && abs(p.y - 2) < 0.05)
        // And walks on.
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 30)
        #expect(p.x > 2 && c.isGrounded)
    }

    @Test func mantlesALowWallFromTheGround() {
        let physics = floorWorld()
        box(physics, Vec3(1, 0, -3), Vec3(2, 1.1, 3))
        var c = CharacterController()
        var p = Vec3(0, 0.02, 0)
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 40)
        #expect(p.x < 1 - c.radius + 0.05)
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 1) { $0.mantle = true }
        #expect(c.mode == .mantling)
        run(physics, &c, &p, steps: 40)
        #expect(c.mode == .walking && abs(p.y - 1.1) < 0.05 && p.x > 1)
    }

    @Test func mantleEndsCrouchedUnderALowCeiling() {
        let physics = cliffWorld()
        // A roof 1.4 m above the top.
        box(physics, Vec3(1, 3.4, -5), Vec3(4, 3.7, 5))
        var c = CharacterController()
        c.grabLedges = true
        var p = Vec3(0.3, 0.02, 0)
        run(physics, &c, &p, steps: 10)
        for step in 0..<90 where c.mode != .hanging {
            c.moveVelocity = Vec3(1.5, 0, 0)
            c.jump = step == 0
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
        }
        #expect(c.mode == .hanging)
        run(physics, &c, &p, steps: 1) { $0.mantle = true }
        run(physics, &c, &p, steps: 40)
        #expect(c.mode == .walking && c.isCrouching && abs(p.y - 2) < 0.05)
    }

    // MARK: Climbing

    @Test func climbsAClimbableWallAndMantlesOverTheTop() {
        let physics = floorWorld()
        physics.materials.register("Physics2TestsVines", PhysicsMaterial(climbable: true))
        let wall = box(physics, Vec3(1, 0, -3), Vec3(4, 3, 3))
        // Without ECS the surface is set on the body directly.
        physics.bodies[Int(wall.index)].surface = PhysicsSurface(material: "Physics2TestsVines")
        var c = CharacterController()
        var p = Vec3(0, 0.02, 0)
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 30)
        #expect(c.mode == .climbing)
        #expect(abs(c.ledgeNormal.x + 1) < 1e-3)
        let start = p.y
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 30)
        #expect(c.mode == .climbing && p.y > start + 0.8)
        // Sideways along the wall.
        let z = p.z
        run(physics, &c, &p, Vec3(0, 0, 1), steps: 20)
        #expect(p.z > z + 0.25 && c.mode == .climbing)
        // Over the top.
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 60)
        #expect(c.mode == .walking && p.y > 2.9 && p.x > 1)
    }

    @Test func climbsDownToTheGroundAndJumpsOff() {
        let physics = floorWorld()
        physics.materials.register("Physics2TestsVines", PhysicsMaterial(climbable: true))
        let wall = box(physics, Vec3(1, 0, -3), Vec3(1.4, 6, 3))
        physics.bodies[Int(wall.index)].surface = PhysicsSurface(material: "Physics2TestsVines")
        var c = CharacterController()
        var p = Vec3(0, 0.02, 0)
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 60)
        #expect(c.mode == .climbing && p.y > 0.5)
        run(physics, &c, &p, Vec3(-2, 0, 0), steps: 60)
        #expect(c.mode == .walking && c.isGrounded)
        run(physics, &c, &p, Vec3(2, 0, 0), steps: 40)
        #expect(c.mode == .climbing)
        run(physics, &c, &p, steps: 1) { $0.jump = true }
        #expect(c.mode == .walking && c.launchVelocity.x < -1)
        // A wall that isn't climbable stops it instead.
        let plain = floorWorld()
        box(plain, Vec3(1, 0, -3), Vec3(1.4, 6, 3))
        var d = CharacterController()
        var q = Vec3(0, 0.02, 0)
        run(plain, &d, &q, Vec3(2, 0, 0), steps: 60)
        #expect(d.mode == .walking && q.y < 0.05)
    }

    // MARK: Platforms

    @Test func ridesARisingPlatformAndJumpsWithItsSpeed() {
        let physics = floorWorld()
        let platform = box(physics, Vec3(-1, 0.5, -1), Vec3(1, 0.7, 1), motion: .kinematic)
        var c = CharacterController()
        var p = Vec3(0, 0.75, 0)
        var y: Float = 0.6
        for _ in 0..<60 {
            y += 1 * dt
            physics.moveKinematic(platform, to: Pose(position: Vec3(0, y, 0)), dt: dt)
            p = physics.moveCharacter(&c, from: p, dt: dt)
            physics.step(dt)
        }
        #expect(c.isGrounded && abs(p.y - (y + 0.1 + c.skinWidth)) < 0.05)
        c.jump = true
        physics.moveKinematic(platform, to: Pose(position: Vec3(0, y + dt, 0)), dt: dt)
        p = physics.moveCharacter(&c, from: p, dt: dt)
        #expect(abs(c.verticalVelocity - (c.jumpSpeed + 1)) < 0.1)
    }

    // MARK: Continuous collision

    @Test func continuousBodiesStopAtThinWalls() {
        func shoot(continuous: Bool, speed: Float, shape: ColliderShape, spin: Vec3 = .zero) -> Float {
            let physics = PhysicsWorld()
            physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(5, 1, 0)), shape: .box(Vec3(0.02, 2, 2))))
            let b = physics.addBody(BodyDescriptor(motion: .dynamic, pose: Pose(position: Vec3(0, 1, 0)), shape: shape,
                                                   linearVelocity: Vec3(speed, 0, 0), angularVelocity: spin, gravityScale: 0,
                                                   continuous: continuous))
            for _ in 0..<60 { physics.step(1.0 / 60) }
            return physics.pose(of: b)!.position.x
        }
        let bullet = ColliderShape.sphere(radius: 0.03)
        #expect(shoot(continuous: false, speed: 400, shape: bullet) > 10)
        #expect(shoot(continuous: true, speed: 400, shape: bullet) < 5)
        #expect(shoot(continuous: true, speed: 1500, shape: bullet) < 5)
        let shard = ColliderShape.box(Vec3(0.02, 0.02, 0.05))
        #expect(shoot(continuous: true, speed: 200, shape: shard, spin: Vec3(3, 7, 1)) < 5)
        #expect(shoot(continuous: true, speed: 600, shape: .capsule(radius: 0.02, halfHeight: 0.05)) < 5)
    }

    @Test func continuousRigidBodyComponentAndBounce() throws {
        let world = World()
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        world.spawn(Transform(position: Vec3(5, 1, 0)), Collider(.box(Vec3(0.02, 2, 2)), restitution: 1))
        let bullet = world.spawn(Transform(position: Vec3(0, 1, 0)), Collider(.sphere(radius: 0.03), restitution: 1),
                                 RigidBody(linearVelocity: Vec3(500, 0, 0), linearDamping: 0, gravityScale: 0, continuous: true))
        for _ in 0..<5 { world.update(dt: 1.0 / 60) }
        let x = try #require(world.get(Transform.self, for: bullet)).position.x
        #expect(x < 5)
        // It bounced back.
        #expect(try #require(world.get(RigidBody.self, for: bullet)).linearVelocity.x < -100)
        #expect(physics.isContinuous(try #require(physics.body(for: bullet))))
        // Old scenes without the key load with it off.
        let data = try JSONEncoder().encode(RigidBody())
        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["continuous"] = nil
        let decoded = try JSONDecoder().decode(RigidBody.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(!decoded.continuous)
    }

    @Test func impactEventsReportSpeedAndSlidesAreFound() {
        let physics = floorWorld()
        let crate = physics.addBody(BodyDescriptor(motion: .dynamic, pose: Pose(position: Vec3(0, 2, 0)), shape: .box(Vec3(0.25, 0.25, 0.25))))
        var speeds: [Float] = []
        physics.onEvent = { if $0.kind == .collisionBegan { speeds.append($0.speed) } }
        for _ in 0..<60 { physics.step(dt) }
        let expected = (2 * 9.81 * 1.75 as Float).squareRoot()
        #expect(speeds.count >= 1 && abs(speeds[0] - expected) < 1)
        physics.setLinearVelocity(crate, Vec3(4, 0, 0))
        physics.step(dt)
        let slides = physics.slidingContacts(minSpeed: 0.5)
        #expect(slides.count == 1 && slides[0].speed > 2)
    }

    // MARK: Materials

    @Test func surfacesSetFrictionBounceAndDensity() throws {
        let world = World()
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        let ground = world.spawn(Transform(), Collider(.box(Vec3(20, 0.5, 20)), offset: Vec3(0, -0.5, 0), friction: 0.9),
                                 PhysicsSurface(material: "ice"))
        let crate = world.spawn(Transform(position: Vec3(0, 0.26, 0)), Collider(.box(Vec3(0.25, 0.25, 0.25)), friction: 0.9),
                                RigidBody(linearVelocity: Vec3(3, 0, 0)))
        // A child collider picks up its parent's surface.
        let parent = world.spawn(Transform(position: Vec3(0, 0, 8)), PhysicsSurface(material: "rubber"))
        let child = world.spawn(Transform(), Collider(.sphere(radius: 0.2)))
        world.setParent(child, to: parent)
        for _ in 0..<60 { world.update(dt: 1.0 / 60) }
        // On ice it keeps sliding (ice friction 0.03 against 0.9: about 0.16).
        #expect(try #require(world.get(Transform.self, for: crate)).position.x > 1.5)
        let g = try #require(physics.body(for: ground)), k = try #require(physics.body(for: child))
        #expect(physics.bodies[Int(g.index)].material.friction == 0.03)
        #expect(physics.bodies[Int(k.index)].material.restitution == 0.8)
        #expect(physics.surfaceMaterialName(of: g, at: .zero) == "ice")
        let probe = try #require(physics.materialUnder(Vec3(3, 0.5, 3)))
        #expect(probe.name == "ice" && probe.material.friction == 0.03)
        // A registered material wins; an unknown name keeps the collider's numbers.
        physics.materials.register("Physics2TestsSticky", PhysicsMaterial(friction: 2))
        world.add(PhysicsSurface(material: "Physics2TestsSticky"), to: ground)
        world.update(dt: 1.0 / 60)
        #expect(physics.bodies[Int(g.index)].material.friction == 2)
        world.add(PhysicsSurface(material: "Physics2TestsNoSuch"), to: ground)
        world.update(dt: 1.0 / 60)
        #expect(physics.bodies[Int(g.index)].material.friction == 0.9)
    }

    @Test func surfaceGridsNameMaterialsByArea() throws {
        var grid = PhysicsSurfaceGrid(materials: ["grass", "stone"], origin: Vec2(-2, -2), cellSize: Vec2(1, 1), columns: 4, rows: 4,
                                      cells: [UInt8](repeating: 0, count: 16))
        grid.cells[2 * 4 + 3] = 1
        grid.cells[0] = 255
        let surface = PhysicsSurface(material: "dirt", regions: grid)
        #expect(surface.material(atLocal: Vec3(1.5, 0, 0.5)) == "stone")
        #expect(surface.material(atLocal: Vec3(0, 0, 0)) == "grass")
        #expect(surface.material(atLocal: Vec3(-1.5, 0, -1.5)) == "dirt")
        #expect(surface.material(atLocal: Vec3(9, 0, 9)) == "dirt")
        // Saved compactly and read back.
        let data = try JSONEncoder().encode(surface)
        #expect(String(decoding: data, as: UTF8.self).contains("\"cells\":\""))
        #expect(try JSONDecoder().decode(PhysicsSurface.self, from: data) == surface)
        for n in 0..<7 {
            let bytes = (0..<n).map { UInt8($0 * 37 % 256) }
            #expect(PhysicsSurfaceGrid.decodeBase64(PhysicsSurfaceGrid.encodeBase64(bytes)) == bytes)
        }
        #expect(PhysicsSurfaceGrid.encodeBase64([1, 2, 3, 4]) == "AQIDBA==")
    }

    @Test func pairEffectsWinOverEachMaterialsOwn() {
        let library = PhysicsMaterialLibrary()
        library.register("Physics2TestsMetal", PhysicsMaterial(impact: PhysicsMaterialEffect(sound: "clang"),
                                                               pairs: ["Physics2TestsWood": PhysicsMaterialEffects(impact: PhysicsMaterialEffect(sound: "thunk"))]))
        library.register("Physics2TestsWood", PhysicsMaterial(footstep: PhysicsMaterialEffect(sound: "creak"), impact: PhysicsMaterialEffect(sound: "knock")))
        #expect(library.effect(.impact, "Physics2TestsWood", "Physics2TestsMetal")?.sound == "thunk")
        #expect(library.effect(.impact, "Physics2TestsMetal", "Physics2TestsWood")?.sound == "thunk")
        #expect(library.effect(.impact, "default", "Physics2TestsMetal")?.sound == "clang")
        #expect(library.effect(.footstep, "default", "Physics2TestsWood")?.sound == "creak")
        #expect(library.effect(.scrape, "default", "Physics2TestsWood") == nil)
        #expect(PhysicsMaterial(friction: -1, bounce: 2, density: 0, impact: PhysicsMaterialEffect()).problems().count == 4)
        #expect(PhysicsMaterial.builtIn(named: "ICE")?.friction == 0.03)
    }

    // MARK: Saving and networking

    @Test func controllerStateSavesAndOldScenesLoad() throws {
        var c = CharacterController(radius: 0.4)
        c.mode = .hanging
        c.isCrouching = true
        c.ledgePoint = Vec3(1, 2, 3)
        c.crouchHeight = 0.9
        let data = try JSONEncoder().encode(c)
        var decoded = try JSONDecoder().decode(CharacterController.self, from: data)
        decoded.groundBody = c.groundBody
        #expect(decoded == c)
        let old = try JSONDecoder().decode(CharacterController.self, from: Data(#"{"radius": 0.5, "height": 2}"#.utf8))
        #expect(old.radius == 0.5 && old.height == 2 && old.mode == .walking && old.crouchHeight == 1)
        // The network coding keeps the default controller small and round-trips version 2 state.
        #expect(try NetComponentCoder.encode(CharacterController()).count < 100)
        let bytes = try NetComponentCoder.encode(c)
        #expect(try NetComponentCoder.decode(bytes, as: CharacterController.componentName) as? CharacterController == c)
    }

    @Test func characterComponentCrouchUpdatesItsCapsuleCollider() throws {
        let world = World()
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        world.spawn(Transform(), Collider(.box(Vec3(20, 0.5, 20)), offset: Vec3(0, -0.5, 0)))
        var controller = CharacterController()
        let player = world.spawn(Transform(position: Vec3(0, 0.05, 0)), controller,
                                 Collider(controller.colliderShape, offset: controller.colliderOffset), RigidBody(.kinematic))
        for _ in 0..<10 { world.update(dt: 1.0 / 60) }
        controller = try #require(world.get(CharacterController.self, for: player))
        controller.crouch = true
        world.add(controller, to: player)
        world.update(dt: 1.0 / 60)
        let collider = try #require(world.get(Collider.self, for: player))
        #expect(collider.offset.y == 0.5)
        guard case .capsule(_, let half) = collider.shape else { Issue.record("not a capsule"); return }
        #expect(abs(half - 0.2) < 1e-5)
    }

    // MARK: Playtest

    /// Projects/SampleGame/Playtests/Physics2.playtest.json, headless (what `GameRunner none --playtest` runs).
    @Test func physics2PlaytestPassesHeadless() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let file = root.appendingPathComponent("Projects/SampleGame/Playtests/Physics2.playtest.json")
        let playtest = try Playtest(contentsOf: file)
        let scene = PlaytestHeadlessHost.resolve(try #require(playtest.scene), from: file)
        let host = try PlaytestHeadlessHost(module: GameModule(), sceneURL: scene, log: { _ in })
        let result = host.run(playtest)
        #expect(result.passed, "\(result.report)")
        #expect(result.checks.count == playtest.assertionCount)
    }

    // MARK: Builders

    @Test func meshBuildLooksAndTerrainLayersNameMaterials() throws {
        var part = MeshBuildPart(name: "Lid")
        part.look = "rustyMetal"
        #expect(part.resolvedPhysicsMaterial == "metal")
        part.physicsMaterial = "Physics/Tin.physmat"
        #expect(part.resolvedPhysicsMaterial == "Physics/Tin.physmat")
        let json = String(decoding: try JSONEncoder().encode(part), as: UTF8.self)
        #expect(json.contains("Physics\\/Tin.physmat") || json.contains("Physics/Tin.physmat"))
        #expect(try JSONDecoder().decode(MeshBuildPart.self, from: Data(json.utf8)).physicsMaterial == "Physics/Tin.physmat")
        // Every look maps to a built-in.
        for look in MeshBuildLook.allCases { #expect(PhysicsMaterial.builtIn(named: look.physicsMaterial) != nil, "\(look)") }

        var terrain = Terrain(size: Vec2(16, 16), resolution: 17, chunkCells: 8,
                              layers: [TerrainLayer(name: "Grass"), TerrainLayer(name: "Rock")])
        #expect(terrain.chunkPhysicsSurface(0, 0) == nil)
        terrain.layers[0].physicsMaterial = "grass"
        terrain.layers[1].physicsMaterial = "stone"
        terrain.normalizeData()
        terrain.paint(layer: 1, at: [Vec2(-6, -6)], radius: 2, strength: 1, falloff: 0)
        let surface = try #require(terrain.chunkPhysicsSurface(0, 0))
        #expect(surface.material == "grass")
        #expect(surface.material(atLocal: Vec3(-6, 0, -6)) == "stone")
        #expect(surface.material(atLocal: Vec3(-1, 0, -1)) == "grass")
        let layerJSON = String(decoding: try JSONEncoder().encode(terrain.layers[1]), as: UTF8.self)
        #expect(layerJSON.contains("stone"))
        #expect(!String(decoding: try JSONEncoder().encode(TerrainLayer()), as: UTF8.self).contains("physicsMaterial"))
    }
}
