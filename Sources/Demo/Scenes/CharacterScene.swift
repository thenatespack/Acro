import Engine
import Foundation

/// Moves a kinematic body back and forth along `axis` (its `Transform` is set every fixed step
/// from the simulated time, so the physics sync turns that into velocity and characters on it
/// are carried).
struct Mover: Component, Codable, Sendable {
    var origin: Vec3
    var axis: Vec3
    var amplitude: Float
    var speed: Float
}

/// The kinematic character controller (`CharacterController`): a third-person capsule moved
/// with the `move` action (WASD or the left stick, relative to the camera), **F** / A jumps,
/// Shift runs. It climbs a staircase (steps of 0.25 under its 0.35 step height), refuses a
/// 60 degree ramp (and slides down it) but walks up a 25 degree one, rides a sweeping platform,
/// pushes crates, lights up a glass trigger zone, and a table and a chair (compound colliders
/// made from child entities) fall and settle. The camera follows with some smoothing.
///
/// **G** shows the physics debug view, **R** resets. **F5** quick saves the character and the
/// crates (positions, in `saves/quick.save.json` in the user data folder, see `SaveGames`) and
/// **F9** quick loads them; the title shows the result for a few seconds. The character is a kinematic body on its
/// own layer that only collides with the trigger zone's layer (the controller does its own
/// sweeps), and is drawn interpolated between fixed steps. Under ENGINE_SCREENSHOT the engine
/// feeds the game no input, so until the first real input the character follows a scripted
/// path toward the stairs (deterministic with the fixed timestep).
final class CharacterScene: DemoScene {
    static let name = "character"
    static let summary = "character controller: capsule slide / steps / slopes / moving platform / pushing, compound colliders, interpolation"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private let actions = InputActions(bindings: CharacterScene.defaultBindings)
    private var cameraEntity = Entity.invalid
    private var hero = Entity.invalid
    private var facing = Entity.invalid
    private var zone = Entity.invalid
    private var inZone = false
    private var orbit: (eye: Vec3, target: Vec3)?
    private var cameraOffset = Vec3.zero
    private var focus = CharacterScene.start
    private var yaw: Float = 0
    private var frame = 0
    private var userActive = false
    private var keysHeld = false
    private var debugMode = false
    private var crates: [Entity] = []
    private var now: Float = 0
    private var message: (text: String, until: Float)?
    private let saves = SaveGames(app: "AcroDemo")
    /// Screenshot runs never touch the real user's saves (`ENGINE_USER_DATA_DIR` opts back in).
    private let savesEnabled = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] == nil || UserData.isOverridden

    /// What a quick save keeps: the character's spot and heading, and where each crate is and
    /// how it is turned (`crateRotations` is missing in saves from before it was added).
    private struct QuickSave: Codable {
        var hero: Vec3
        var yaw: Float
        var crates: [Vec3]
        var crateRotations: [Quat]?
    }
    /// Frames until the post-load check prints where things ended up (see `quickLoad`).
    private var verifyLoad: (frames: Int, state: QuickSave)?
    private static let sky = Vec3(0.62, 0.72, 0.86)
    private static let start = Vec3(-5.5, 0, 0)
    private static let layerCharacter: UInt32 = 2
    private static let layerTrigger: UInt32 = 4
    /// Frames of the scripted walk when no input arrives.
    private static let autoFrames = 150
    private static let walkSpeed: Float = 4.5

    static var defaultBindings: InputBindings {
        var map = InputBindings()
        map.vectors.append(.init("move", [
            .composite(up: .key(.w), down: .key(.s), left: .key(.a), right: .key(.d)),
            .stick(stick: .left),
        ]))
        map.buttons.append(.init("jump", [.key(.f), .gamepadButton(.south)]))
        map.buttons.append(.init("run", [.key(.leftShift), .gamepadButton(.leftShoulder)]))
        return map
    }

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.36, 0.38, 0.36, 1), checker: true, roughness: 0.85), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.55), key: "matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), metallic: 0.9, roughness: 0.3), key: "metal")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.25), key: "gloss")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.1, alphaMode: .blend, doubleSided: true), key: "glass")
        _ = try sceneRenderer.registerMesh(Self.floorMesh(halfSize: 30), key: "floor")
        _ = try sceneRenderer.registerMesh(PhysicsScene.capsuleMesh(radius: 0.3, halfHeight: 0.6), key: "hero")
        build()
    }

    /// (Re)creates the world and its physics.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        physics.interpolatesPoses = true
        world.addPhysics(physics)
        inZone = false
        crates = []
        frame = 0
        userActive = false
        yaw = 0
        focus = Self.start
        sceneRenderer.resetMotion()

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(-14, 6, 6), at: Vec3(-5, 1, 0)),
            Camera(fovY: .pi / 3.5, near: 0.2, far: 200, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.004))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.3))),
            DirectionalLight(intensity: 1.5, shadowExtent: 22, shadowCenter: Vec3(2, 1, 2)))
        _ = world.spawn(
            Transform(), Name("Floor"), MeshRenderer(mesh: MeshHandle("floor"), material: MaterialHandle("floor"), castsShadows: false),
            Collider(.box(Vec3(30, 0.5, 30)), offset: Vec3(0, -0.5, 0), friction: 0.8))

        buildStairs()
        buildRamps()
        buildCrates()
        buildPlatform()
        buildZone()
        buildFurniture()
        buildHero()
        world.propagateTransforms()
    }

    /// Six steps of 0.25 (the controller steps up to 0.35) onto a landing.
    private func buildStairs() {
        for k in 0..<6 {
            let top = 0.25 * Float(k + 1)
            box("Step", at: Vec3(-2.75 + Float(k) * 0.5, top / 2, 0), size: Vec3(0.5, top, 4), tint: hsv(0.08 + Float(k) * 0.02, 0.45, 0.95))
        }
        box("Landing", at: Vec3(2.25, 0.75, 0), size: Vec3(5, 1.5, 5), tint: hsv(0.1, 0.4, 0.9))
        // A wall along the landing's far side, to slide along.
        box("Wall", at: Vec3(2.25, 2.1, -2.7), size: Vec3(5, 1.2, 0.4), tint: Vec3(0.55, 0.6, 0.7), material: "metal")
    }

    /// A 60 degree slab (too steep: blocks and slides) and a 25 degree one (walked up).
    private func buildRamps() {
        for (name, degrees, z, tint) in [("Steep ramp", Float(60), Float(-6), Vec3(0.9, 0.3, 0.2)), ("Gentle ramp", 25, -10.5, Vec3(0.3, 0.75, 0.4))] {
            let rotation = Quat(angle: degrees * .pi / 180, axis: Vec3(0, 0, 1))
            let half = Vec3(2.6, 0.2, 1.5)
            // Its lower end flush with the floor at x = -3.
            box(name, at: Vec3(-3, 0, z) - rotation * Vec3(-half.x, half.y, 0), rotation: rotation, size: half * 2, tint: tint)
        }
    }

    /// Light crates to push: three on the floor and one on top.
    private func buildCrates() {
        let spots = [Vec3(-5.2, 0.4, -3), Vec3(-4.3, 0.4, -3), Vec3(-3.4, 0.4, -3.1), Vec3(-4.75, 1.2, -3)]
        for (k, p) in spots.enumerated() {
            crates.append(box("Crate", at: p, size: Vec3(repeating: 0.8), tint: hsv(0.58 + Float(k) * 0.05, 0.6, 0.9),
                              motion: .dynamic, friction: 0.4, density: 90))
        }
    }

    /// A kinematic slab sweeping along x, low enough to step onto.
    private func buildPlatform() {
        let origin = Vec3(2, 0.15, 8)
        let platform = box("Platform", at: origin, size: Vec3(3, 0.3, 3), tint: Vec3(0.3, 0.55, 0.95), material: "metal", motion: .kinematic)
        world.add(Mover(origin: origin, axis: Vec3(1, 0, 0), amplitude: 4, speed: 0.8), to: platform)
        world.addSystem("mover", stage: .fixedUpdate, before: "physics") { world in
            let t = Float(world.time.fixedElapsed)
            world.queryMutating(Transform.self, Mover.self) { _, transform, mover in
                transform.position = mover.origin + mover.axis * (sinf(t * mover.speed) * mover.amplitude)
            }
        }
    }

    /// A glass zone on the floor that glows while the character stands in it.
    private func buildZone() {
        zone = world.spawn(
            Transform(position: Vec3(2.5, 0.6, 4.4)), Name("Trigger zone"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("glass"), tint: Vec3(0.4, 0.7, 1), opacity: 0.3, castsShadows: false),
            Collider(.box(Vec3(0.5, 0.5, 0.5)), isTrigger: true, layer: Self.layerTrigger))
        world.modify(Transform.self, for: zone) { $0.scale = Vec3(3, 1.2, 3) }
    }

    /// A table and a chair, each one body with its parts as child colliders (a compound), dropped
    /// to settle on their legs.
    private func buildFurniture() {
        let wood = hsv(0.07, 0.6, 0.8), cloth = hsv(0.6, 0.5, 0.8)
        let table = world.spawn(
            Transform(position: Vec3(-3.6, 1.7, 3.4), rotation: Quat(angle: 0.3, axis: normalize(Vec3(0.3, 0, 1)))), Name("Table"),
            RigidBody())
        part("Table top", of: table, at: Vec3(0, 0.39, 0), size: Vec3(1.6, 0.12, 1), tint: wood)
        for (x, z) in [(-0.7, -0.4), (0.7, -0.4), (-0.7, 0.4), (0.7, 0.4)] as [(Float, Float)] {
            part("Table leg", of: table, at: Vec3(x, -0.075, z), size: Vec3(0.1, 0.75, 0.1), tint: wood)
        }
        let chair = world.spawn(
            Transform(position: Vec3(-1.6, 1.5, 4.6), rotation: Quat(angle: 0.9, axis: Vec3(0, 1, 0)) * Quat(angle: 0.35, axis: Vec3(1, 0, 0))),
            Name("Chair"), RigidBody())
        part("Seat", of: chair, at: .zero, size: Vec3(0.7, 0.08, 0.7), tint: cloth)
        part("Back", of: chair, at: Vec3(0, 0.44, -0.31), size: Vec3(0.7, 0.8, 0.08), tint: cloth)
        for (x, z) in [(-0.29, -0.29), (0.29, -0.29), (-0.29, 0.29), (0.29, 0.29)] as [(Float, Float)] {
            part("Chair leg", of: chair, at: Vec3(x, -0.29, z), size: Vec3(0.08, 0.5, 0.08), tint: wood)
        }
    }

    /// A child with a box mesh and a collider that joins its parent's body.
    private func part(_ name: String, of parent: Entity, at position: Vec3, size: Vec3, tint: Vec3) {
        let child = world.spawn(
            Transform(position: position, scale: size), Name(name),
            MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: tint),
            Collider(.box(Vec3(repeating: 0.5)), friction: 0.5, density: 250))
        _ = world.setParent(child, to: parent)
    }

    /// The capsule: an entity at the feet (the controller's position) with a kinematic body, and
    /// a visual child that turns toward where it walks.
    private func buildHero() {
        let controller = CharacterController(radius: 0.3, height: 1.8, stepHeight: 0.35, jumpSpeed: 6, pushForce: 450)
        hero = world.spawn(
            Transform(position: Self.start), Name("Character"), controller,
            Collider(controller.colliderShape, offset: controller.colliderOffset, layer: Self.layerCharacter, mask: Self.layerTrigger),
            RigidBody(.kinematic, interpolation: .on))
        facing = world.spawn(Transform(position: Vec3(0, 0.9, 0)), Name("Facing"))
        _ = world.setParent(facing, to: hero)
        let body = world.spawn(
            Transform(), Name("Body"), MeshRenderer(mesh: MeshHandle("hero"), material: MaterialHandle("gloss"), tint: Vec3(0.95, 0.55, 0.15)))
        _ = world.setParent(body, to: facing)
        let nose = world.spawn(
            Transform(position: Vec3(0, 0.35, 0.27), scale: Vec3(0.2, 0.12, 0.2)), Name("Nose"),
            MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: Vec3(0.05, 0.05, 0.05)))
        _ = world.setParent(nose, to: facing)
    }

    /// A static (or dynamic, kinematic) box with a unit cube mesh and a matching collider.
    @discardableResult
    private func box(_ name: String, at position: Vec3, rotation: Quat = .identity, size: Vec3, tint: Vec3, material: String = "matte",
                     motion: MotionType = .static, friction: Float = 0.6, density: Float = 1000) -> Entity {
        let entity = world.spawn(
            Transform(position: position, rotation: rotation, scale: size), Name(name),
            MeshRenderer(mesh: .cube, material: MaterialHandle(material), tint: tint),
            Collider(.box(Vec3(repeating: 0.5)), friction: friction, density: density))
        if motion != .static { world.add(RigidBody(motion, interpolation: .on), to: entity) }
        return entity
    }

    var initialView: OrbitView { OrbitView(yaw: -1.15, pitch: 0.45, distance: 14, target: Vec3(0, 1, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var wantsKeyboard: Bool { keysHeld }
    var status: String {
        let c = world.get(CharacterController.self, for: hero)
        let state = c.map { $0.isGrounded ? "grounded" : ($0.isSliding ? "sliding" : "airborne") } ?? ""
        let base = "\(state), zone \(inZone ? "occupied" : "empty"), WASD move [F] jump [Shift] run [G] debug [R] reset [F5/F9] quick save/load"
        return message.map { "\($0.text), \(base)" } ?? base
    }

    /// F5: writes the character and crate positions to the "quick" slot.
    private func quickSave() {
        guard savesEnabled else { return show("Saving is off in screenshot runs") }
        // The simulation's poses, not the interpolated transforms drawn between steps.
        let crates = self.crates.map(exactPose)
        let state = QuickSave(hero: exactPose(of: hero).position, yaw: yaw, crates: crates.map(\.position),
                              crateRotations: crates.map(\.rotation))
        do {
            try saves.save(slot: "quick", state: state, sceneName: Self.name, playtime: Double(now))
            show("Quick saved", detail: Self.describe(state))
        } catch {
            show("Quick save failed: \(error)")
        }
    }

    /// F9: puts the character and crates back where the "quick" slot has them.
    private func quickLoad() {
        guard savesEnabled else { return show("Loading is off in screenshot runs") }
        do {
            let state = try saves.load(slot: "quick").state(QuickSave.self)
            guard state.crates.count == crates.count else { return show("Quick save doesn't match this scene") }
            let before = QuickSave(hero: exactPose(of: hero).position, yaw: yaw, crates: crates.map { exactPose(of: $0).position })
            // Teleport by editing the transforms (the physics sync moves the bodies), and stop
            // everything so nothing carries momentum from before the load.
            world.modify(Transform.self, for: hero) { $0.position = state.hero }
            world.modify(CharacterController.self, for: hero) { $0.verticalVelocity = 0; $0.moveVelocity = .zero }
            for (k, (crate, position)) in zip(crates, state.crates).enumerated() {
                world.modify(Transform.self, for: crate) {
                    $0.position = position
                    if let rotation = state.crateRotations?[k] { $0.rotation = rotation }
                }
                world.modify(RigidBody.self, for: crate) { $0.linearVelocity = .zero; $0.angularVelocity = .zero }
            }
            yaw = state.yaw
            focus = state.hero
            userActive = true
            verifyLoad = (2, state)
            show("Quick loaded", detail: "\(Self.describe(state)), was \(Self.describe(before))")
        } catch SaveError.notFound {
            show("No quick save yet (F5)")
        } catch {
            show("Quick load failed: \(error)")
        }
    }

    /// Shows `text` in the title for a few seconds; prints it with `detail` (for scripted runs).
    private func show(_ text: String, detail: String = "") {
        message = (text, now + 3)
        print("Character: \(text)\(detail.isEmpty ? "" : " " + detail)")
    }

    /// The body's simulated pose (the transform when it has none).
    private func exactPose(of entity: Entity) -> Pose {
        if let id = physics.body(for: entity), let pose = physics.pose(of: id) { return pose }
        let t = world.get(Transform.self, for: entity) ?? Transform()
        return Pose(position: t.position, rotation: t.rotation)
    }

    private static func describe(_ state: QuickSave) -> String {
        func f(_ v: Vec3) -> String { String(format: "(%.3f, %.3f, %.3f)", v.x, v.y, v.z) }
        return "hero \(f(state.hero)) crates \(state.crates.map(f).joined(separator: " "))"
    }

    /// A few fixed steps after a quick load: where the character and crates are now, and how
    /// far from the save (printed, so a scripted F5 / F9 run can check the load worked).
    private func checkLoad() {
        guard let (frames, state) = verifyLoad else { return }
        guard frames == 0 else { return verifyLoad = (frames - 1, state) }
        verifyLoad = nil
        let now = QuickSave(hero: exactPose(of: hero).position, yaw: yaw, crates: crates.map { exactPose(of: $0).position })
        let error = zip([now.hero] + now.crates, [state.hero] + state.crates).map { length($0 - $1) }.max() ?? 0
        print("Character: after load \(Self.describe(now)), largest distance from the save \(String(format: "%.4f", error)) m")
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        cameraOffset = orbitEye - target
        return ViewCamera(eye: focus + Vec3(0, 1.2, 0) + cameraOffset, target: focus + Vec3(0, 1.2, 0), near: 0.2)
    }

    func update(input: Input, dt: Float, time: Float) {
        actions.update(input)
        now = time
        if let message, now >= message.until { self.message = nil }
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.f5) { quickSave() }
        if input.wasPressed(.f9) { quickLoad() }
        if input.wasPressed(.g) { debugMode.toggle() }
        let move = actions.vector("move")
        let jump = actions.wasPressed("jump")
        keysHeld = move != .zero || actions.isPressed("jump")
        if move != .zero || jump { userActive = true }
        if cameraOffset == .zero {
            let v = initialView
            cameraOffset = Vec3(cosf(v.pitch) * sinf(v.yaw), sinf(v.pitch), cosf(v.pitch) * cosf(v.yaw)) * v.distance
        }

        // Camera-relative movement, or the scripted walk until the first real input.
        var velocity = Vec3.zero
        if userActive {
            let forward = normalize(Vec3(-cameraOffset.x, 0, -cameraOffset.z))
            let right = Vec3(-forward.z, 0, forward.x)
            velocity = (right * move.x + forward * move.y) * (actions.isPressed("run") ? 7 : Self.walkSpeed)
        } else if frame < Self.autoFrames {
            velocity = Vec3(Self.walkSpeed, 0, 0)
        }
        frame += 1
        world.modify(CharacterController.self, for: hero) {
            $0.moveVelocity = velocity
            $0.jump = $0.jump || jump
        }
        world.update(dt: Double(dt))
        checkLoad()

        // Turn toward the way it walks (the visual child only: the entity itself must not be
        // edited while it is drawn interpolated).
        if dot(velocity, velocity) > 1e-4 {
            let target = atan2f(velocity.x, velocity.z)
            var delta = target - yaw
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            yaw += delta * (1 - expf(-14 * dt))
        }
        world.modify(Transform.self, for: facing) { $0.rotation = Quat(angle: yaw, axis: Vec3(0, 1, 0)) }

        // Camera focus follows the (interpolated) position with a little lag.
        if let t = world.get(Transform.self, for: hero) {
            focus += (t.position - focus) * (1 - expf(-8 * dt))
        }

        for event in physics.events where event.entityA == zone && event.entityB == hero {
            if event.kind == .triggerEntered { inZone = true }
            if event.kind == .triggerExited { inZone = false }
        }
        world.modify(MeshRenderer.self, for: zone) {
            $0.tint = inZone ? Vec3(1, 0.35, 0.15) : Vec3(0.4, 0.7, 1)
            $0.opacity = inZone ? 0.5 : 0.3
        }

        debug.removeAll()
        if debugMode { physics.drawDebug(into: debug, options: [.colliders, .contacts]) }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            let eye = focus + Vec3(0, 1.2, 0) + (orbit.eye - orbit.target)
            world.add(Transform.looking(from: eye, at: focus + Vec3(0, 1.2, 0)), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }

    /// A flat square with UVs of 4 m per tile.
    private static func floorMesh(halfSize h: Float) -> MeshGeometry {
        var geometry = MeshGeometry(vertices: [], indices: [])
        for (x, z) in [(-h, -h), (h, -h), (-h, h), (h, h)] {
            geometry.vertices.append(MeshVertex(position: Vec3(x, 0, z), normal: Vec3(0, 1, 0), uv: Vec2(x, z) * 0.25))
        }
        // Counter-clockwise seen from above (+y).
        geometry.indices = [0, 2, 1, 1, 2, 3]
        return geometry
    }
}
