import Engine
import Foundation

/// Physics v2: the character controller's new moves, continuous collision and physics materials.
/// Capsule characters (scripted, deterministic with the fixed timestep), left to right:
/// - stairs and a 25 degree ramp a character walks up, and a 55 degree slab it slides off;
/// - a moving platform carrying a character;
/// - a 2 m wall with a ledge: one character hangs from it (hand points drawn as small spheres,
///   where an arm IK would put the hands) and shimmies, one grabs it and mantles up;
/// - a climbable wall (the built-in "climbingWall" material) a character climbs and tops out of;
/// - a low roof a crouched character walks under (it stands up once out);
/// - in the back, balls dropped on rubber, wood and ice pads (rubber bounces), and crates pushed
///   along wood and ice strips (ice keeps sliding);
/// - on the right, two bullets at 300 m/s through a 4 cm wall: continuous collision off (red
///   trail, passes through) and on (green, stops at the wall).
/// **R** resets, **G** shows the physics debug view.
final class Physics2Scene: DemoScene {
    static let name = "physics2"
    static let summary = "physics v2: ledges, mantling, climbing, crouching, platforms, stairs and slopes, CCD bullets, physics materials"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private var cameraEntity = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private var clock: Float = 0
    private var debugMode = false

    /// A scripted character: its entity, visual, hand markers and what it does over time.
    private struct Actor {
        var entity: Entity
        var body: Entity
        var hands: [Entity]
        var script: (Float, inout CharacterController) -> Void
    }
    private var actors: [Actor] = []
    private var bullets: [(entity: Entity, continuous: Bool)] = []
    private var shot: Float = -1
    private var hits: [Vec3] = []

    private static let sky = Vec3(0.62, 0.72, 0.86)
    private static let muzzle = Vec3(13, 1.2, -1)
    private static let thinWallX: Float = 17
    private static let characterLayer: UInt32 = 2

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.36, 0.38, 0.36, 1), checker: true, roughness: 0.85), key: "p2.floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.6), key: "p2.matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), metallic: 0.9, roughness: 0.3), key: "p2.metal")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.25), key: "p2.gloss")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.75, 0.9, 1, 1), roughness: 0.05), key: "p2.ice")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 0.9, 0.5, 1), roughness: 0.3, emissiveColor: Vec3(1, 0.7, 0.2),
                                                    emissiveStrength: 3), key: "p2.glow")
        _ = try sceneRenderer.registerMesh(Self.floorMesh(halfSize: 40), key: "p2.floor")
        _ = try sceneRenderer.registerMesh(PhysicsScene.capsuleMesh(radius: 0.3, halfHeight: 0.6), key: "p2.stand")
        _ = try sceneRenderer.registerMesh(PhysicsScene.capsuleMesh(radius: 0.3, halfHeight: 0.2), key: "p2.crouch")
        build()
    }

    /// (Re)creates the world.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        physics.interpolatesPoses = true
        world.addPhysics(physics)
        actors = []
        bullets = []
        hits = []
        shot = -1
        clock = 0
        sceneRenderer.resetMotion()

        cameraEntity = world.spawn(Transform.looking(from: Vec3(4, 9, 17), at: Vec3(4, 1, -1)),
                                   Camera(fovY: .pi / 3.2, near: 0.2, far: 300, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.003))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.35, 0.8, 0.45))),
                        DirectionalLight(intensity: 1.5, shadowExtent: 24, shadowCenter: Vec3(4, 1, -2)))
        _ = world.spawn(Transform(), Name("Floor"),
                        MeshRenderer(mesh: MeshHandle("p2.floor"), material: MaterialHandle("p2.floor"), castsShadows: false),
                        Collider(.box(Vec3(40, 0.5, 40)), offset: Vec3(0, -0.5, 0), friction: 0.8), PhysicsSurface(material: "concrete"))

        buildStairsAndSlopes()
        buildPlatform()
        buildLedge()
        buildClimbingWall()
        buildRoof()
        buildMaterials()
        buildBullets()
        world.propagateTransforms()
    }

    // MARK: Areas

    /// Five 0.25 m steps onto a landing, a 25 degree ramp beside them and a 55 degree slab.
    private func buildStairsAndSlopes() {
        for k in 0..<5 {
            let top = 0.25 * Float(k + 1)
            box("Step", at: Vec3(-9 + Float(k) * 0.5, top / 2, 0.5), size: Vec3(0.5, top, 2), tint: hsv(0.08 + Float(k) * 0.02, 0.45, 0.95),
                surface: "wood")
        }
        box("Landing", at: Vec3(-6, 0.625, 0.5), size: Vec3(1.5, 1.25, 2), tint: hsv(0.1, 0.4, 0.9), surface: "wood")
        let gentle = Quat(angle: 25 * .pi / 180, axis: Vec3(0, 0, 1))
        box("Gentle ramp", at: Vec3(-7.3, 0, -2.2) - gentle * Vec3(-1.8, 0.15, 0), rotation: gentle, size: Vec3(3.6, 0.3, 1.6),
            tint: Vec3(0.3, 0.75, 0.4), surface: "grass")
        let steep = Quat(angle: 55 * .pi / 180, axis: Vec3(0, 0, 1))
        box("Steep slab", at: Vec3(-11, 0, -2.2) - steep * Vec3(-1.4, 0.15, 0), rotation: steep, size: Vec3(2.8, 0.3, 1.6),
            tint: Vec3(0.9, 0.3, 0.2), surface: "stone")
        // Up the stairs, then on along the landing.
        addActor("Stair walker", at: Vec3(-10.2, 0, 0.5), tint: Vec3(0.95, 0.55, 0.15)) { t, c in
            c.moveVelocity = t < 3.2 ? Vec3(1.8, 0, 0) : .zero
        }
        addActor("Ramp walker", at: Vec3(-8.2, 0, -2.2), tint: Vec3(0.2, 0.7, 0.35)) { t, c in
            c.moveVelocity = t < 2.2 ? Vec3(1.4, 0, 0) : .zero
        }
        // Dropped onto the steep slab: it slides off.
        addActor("Slider", at: Vec3(-9.9, 2.6, -2.2), tint: Vec3(0.85, 0.25, 0.2)) { _, c in c.moveVelocity = .zero }
    }

    /// A kinematic platform sweeping along z with a character riding it.
    private func buildPlatform() {
        let origin = Vec3(-3.2, 0.15, -0.5)
        let platform = box("Platform", at: origin, size: Vec3(2, 0.3, 2), tint: Vec3(0.3, 0.55, 0.95), material: "p2.metal", motion: .kinematic,
                           surface: "metal")
        world.add(Mover(origin: origin, axis: Vec3(0, 0, 1), amplitude: 2.2, speed: 1.2), to: platform)
        world.addSystem("mover", stage: .fixedUpdate, before: "physics") { world in
            let t = Float(world.time.fixedElapsed)
            world.queryMutating(Transform.self, Mover.self) { _, transform, mover in
                transform.position = mover.origin + mover.axis * (sinf(t * mover.speed) * mover.amplitude)
            }
        }
        addActor("Rider", at: origin + Vec3(0, 0.17, 0), tint: Vec3(0.55, 0.35, 0.9)) { _, c in c.moveVelocity = .zero }
    }

    /// A 2 m wall: a character hanging from it (it shimmies along) and one that grabs it and mantles up.
    private func buildLedge() {
        box("Ledge wall", at: Vec3(1.5, 1, -0.5), size: Vec3(2, 2, 4), tint: Vec3(0.62, 0.6, 0.56), surface: "stone")
        addActor("Hanger", at: Vec3(0.12, 0.3, -1.6), tint: Vec3(0.95, 0.8, 0.2)) { t, c in
            c.grabLedges = true
            if t < 0.05 { c.grabLedge = true }
            c.moveVelocity = c.mode == .hanging ? Vec3(0, 0, t < 3 ? 0.8 : -0.8) : .zero
        }
        // Grabs the ledge at once, then pulls up onto the top and walks on.
        addActor("Mantler", at: Vec3(0.12, 0.3, 0.8), tint: Vec3(0.2, 0.75, 0.85)) { t, c in
            if t < 0.05 { c.grabLedge = true }
            c.mantle = c.mode == .hanging && t > 0.5
            c.moveVelocity = c.mode == .walking && c.isGrounded && t > 1.2 && t < 2 ? Vec3(1, 0, 0) : .zero
        }
    }

    /// A climbable wall (its material is "climbingWall") with a character climbing it.
    private func buildClimbingWall() {
        box("Climbing wall", at: Vec3(5, 1.5, -0.5), size: Vec3(1, 3, 3), tint: Vec3(0.35, 0.65, 0.3), surface: "climbingWall")
        // Holds, for show.
        for k in 0..<9 {
            let y = 0.4 + Float(k / 3) * 0.9, z = -1.5 + Float(k % 3) * 0.9 + Float(k / 3 % 2) * 0.3
            _ = world.spawn(Transform(position: Vec3(4.48, y, z), scale: Vec3(repeating: 0.12)), Name("Hold"),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle("p2.matte"), tint: hsv(Float(k) * 0.11, 0.7, 0.9)))
        }
        addActor("Climber", at: Vec3(3.6, 0, -0.5), tint: Vec3(0.9, 0.4, 0.6)) { t, c in
            c.moveVelocity = t < 4 ? Vec3(1.5, 0, 0) : .zero
        }
    }

    /// A roof 1.3 m up that a crouched character walks under (standing up once it's out).
    private func buildRoof() {
        box("Roof", at: Vec3(8.5, 1.45, -0.5), size: Vec3(2.4, 0.3, 2.4), tint: Vec3(0.7, 0.5, 0.35), surface: "wood")
        for (x, z) in [(7.4, -1.6), (9.6, -1.6), (7.4, 0.6), (9.6, 0.6)] as [(Float, Float)] {
            box("Post", at: Vec3(x, 0.65, z), size: Vec3(0.15, 1.3, 0.15), tint: Vec3(0.5, 0.35, 0.25), surface: "wood")
        }
        addActor("Croucher", at: Vec3(7.3, 0, -0.5), tint: Vec3(0.3, 0.45, 0.95)) { t, c in
            c.crouch = t < 2.5
            c.moveVelocity = Vec3(1.2, 0, 0) * (t < 5 ? 1 : 0)
        }
    }

    /// Balls dropped on rubber, wood and ice pads; crates sliding on wood and ice strips.
    private func buildMaterials() {
        for (k, (material, tint)) in [("rubber", Vec3(0.2, 0.2, 0.22)), ("wood", Vec3(0.7, 0.5, 0.3)), ("ice", Vec3(0.75, 0.9, 1))].enumerated() {
            let x = -6 + Float(k) * 2
            box("Pad \(material)", at: Vec3(x, 0.05, -6), size: Vec3(1.6, 0.1, 1.6), tint: tint, material: material == "ice" ? "p2.ice" : "p2.matte",
                surface: material)
            _ = world.spawn(Transform(position: Vec3(x, 2.6, -6), scale: Vec3(repeating: 0.5)), Name("Ball on \(material)"),
                            MeshRenderer(mesh: .sphere, material: MaterialHandle("p2.gloss"), tint: hsv(0.02 + Float(k) * 0.3, 0.75, 0.95)),
                            Collider(.sphere(radius: 0.5), restitution: 0.3), RigidBody(interpolation: .on), PhysicsSurface(material: "rubber"))
        }
        for (k, material) in ["wood", "ice"].enumerated() {
            let z = -9 - Float(k) * 1.6
            box("Strip \(material)", at: Vec3(1, 0.025, z), size: Vec3(12, 0.05, 1.2), tint: material == "ice" ? Vec3(0.75, 0.9, 1) : Vec3(0.7, 0.5, 0.3),
                material: material == "ice" ? "p2.ice" : "p2.matte", surface: material)
            let crate = box("Crate on \(material)", at: Vec3(-4.4, 0.36, z), size: Vec3(repeating: 0.6), tint: hsv(0.58 + Float(k) * 0.1, 0.6, 0.9),
                            motion: .dynamic, surface: "wood")
            world.modify(RigidBody.self, for: crate) { $0.linearVelocity = Vec3(5, 0, 0) }
        }
    }

    /// A thin wall and two bullets fired at it, with continuous collision off and on.
    private func buildBullets() {
        box("Thin wall", at: Vec3(Self.thinWallX, 1.5, -1), size: Vec3(0.04, 3, 3), tint: Vec3(0.85, 0.85, 0.9), surface: "glass")
        box("Launcher", at: Self.muzzle - Vec3(0.4, 0.6, 0), size: Vec3(0.8, 0.3, 1.6), tint: Vec3(0.25, 0.25, 0.3), material: "p2.metal", surface: "metal")
        for (k, continuous) in [false, true].enumerated() {
            let e = world.spawn(Transform(position: bulletStart(k), scale: Vec3(repeating: 0.08)), Name(continuous ? "Bullet (CCD)" : "Bullet"),
                                MeshRenderer(mesh: .sphere, material: MaterialHandle("p2.glow")),
                                Collider(.sphere(radius: 0.5), density: 11000),
                                RigidBody(linearDamping: 0, gravityScale: 0, allowSleep: false, continuous: continuous))
            bullets.append((e, continuous))
        }
    }

    private func bulletStart(_ k: Int) -> Vec3 { Self.muzzle + Vec3(0, 0, k == 0 ? -0.45 : 0.45) }

    private func fire() {
        hits = []
        for (k, bullet) in bullets.enumerated() {
            world.modify(Transform.self, for: bullet.entity) { $0.position = bulletStart(k) }
            world.modify(RigidBody.self, for: bullet.entity) {
                $0.linearVelocity = Vec3(300, 0, 0)
                $0.angularVelocity = .zero
            }
        }
    }

    // MARK: Helpers

    /// A scripted capsule character at `feet`.
    private func addActor(_ name: String, at feet: Vec3, tint: Vec3, script: @escaping (Float, inout CharacterController) -> Void) {
        let controller = CharacterController(radius: 0.3, height: 1.8, stepHeight: 0.35)
        let entity = world.spawn(Transform(position: feet), Name(name), controller,
                                 Collider(controller.colliderShape, offset: controller.colliderOffset, layer: Self.characterLayer, mask: 0),
                                 RigidBody(.kinematic, interpolation: .on))
        let body = world.spawn(Transform(position: Vec3(0, 0.9, 0)), Name("Body"),
                               MeshRenderer(mesh: MeshHandle("p2.stand"), material: MaterialHandle("p2.gloss"), tint: tint))
        _ = world.setParent(body, to: entity)
        let hands = (0..<2).map { _ in
            world.spawn(Transform(scale: Vec3(repeating: 0.12)), Name("Hand"),
                        MeshRenderer(mesh: .sphere, material: MaterialHandle("p2.matte"), tint: tint * 0.8, isVisible: false))
        }
        actors.append(Actor(entity: entity, body: body, hands: hands, script: script))
    }

    /// A static (or kinematic, dynamic) box with a unit cube mesh, a matching collider and a physics material.
    @discardableResult
    private func box(_ name: String, at position: Vec3, rotation: Quat = .identity, size: Vec3, tint: Vec3, material: String = "p2.matte",
                     motion: MotionType = .static, surface: String) -> Entity {
        let entity = world.spawn(Transform(position: position, rotation: rotation, scale: size), Name(name),
                                 MeshRenderer(mesh: .cube, material: MaterialHandle(material), tint: tint),
                                 Collider(.box(Vec3(repeating: 0.5))), PhysicsSurface(material: surface))
        if motion != .static { world.add(RigidBody(motion, interpolation: .on), to: entity) }
        return entity
    }

    // MARK: DemoScene

    var initialView: OrbitView { OrbitView(yaw: -0.35, pitch: 0.4, distance: 20, target: Vec3(3, 1, -2.5)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky, shadowExtent: 24) }
    var status: String {
        let modes = actors.compactMap { world.get(CharacterController.self, for: $0.entity)?.mode.rawValue }
        return "\(Set(modes).sorted().joined(separator: ", ")) [R] reset [G] physics debug"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.2)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.g) { debugMode.toggle() }
        clock += dt
        // Scripts set the characters' inputs, every 6 s from the start.
        let t = clock.truncatingRemainder(dividingBy: 6)
        for actor in actors {
            world.modify(CharacterController.self, for: actor.entity) { actor.script(t, &$0) }
        }
        // Fire every 2 s.
        if clock - shot >= 2 || shot < 0 {
            shot = clock
            fire()
        }
        world.update(dt: Double(dt))
        // Crouched bodies, hand markers.
        for actor in actors {
            guard let c = world.get(CharacterController.self, for: actor.entity) else { continue }
            world.modify(MeshRenderer.self, for: actor.body) { $0.mesh = MeshHandle(c.isCrouching ? "p2.crouch" : "p2.stand") }
            world.modify(Transform.self, for: actor.body) { $0.position = Vec3(0, c.currentHeight / 2, 0) }
            let hands = c.handTargets
            for (k, hand) in actor.hands.enumerated() {
                world.modify(MeshRenderer.self, for: hand) { $0.isVisible = hands != nil }
                if let hands { world.modify(Transform.self, for: hand) { $0.position = k == 0 ? hands.left : hands.right } }
            }
        }
        debug.removeAll()
        // Bullet trails from the muzzle.
        for (k, bullet) in bullets.enumerated() {
            guard let p = world.get(Transform.self, for: bullet.entity)?.position else { continue }
            let end = Vec3(min(p.x, Self.muzzle.x + 60), p.y, p.z)
            debug.line(bulletStart(k), end, color: bullet.continuous ? Vec4(0.2, 1, 0.3, 1) : Vec4(1, 0.25, 0.2, 1))
            if bullet.continuous && p.x < Self.thinWallX && p.x > Self.thinWallX - 0.5 {
                debug.sphere(center: Vec3(Self.thinWallX - 0.03, p.y, p.z), radius: 0.12, color: Vec4(0.2, 1, 0.3, 1))
            }
        }
        if debugMode { physics.drawDebug(into: debug, options: [.colliders]) }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
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
        geometry.indices = [0, 2, 1, 1, 2, 3]
        return geometry
    }
}
