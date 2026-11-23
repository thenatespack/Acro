import Engine
import Foundation

/// Camera rigs: one character pacing a walled yard and four `CameraRig`s on it, cycling every
/// 6 s with a 1.2 s blend: third-person orbit (the end wall behind the character pulls the camera
/// in, auto-recenter swings it behind after each turn), first person (head bob, the body hidden),
/// top-down and side-scrolling (dead zone and look-ahead in the walking direction, the back wall
/// as the backdrop). The scene's camera is moved by the "cameraRigs" system only.
/// `CAMERARIGS_MODE=orbit|first|top|side` holds one rig (for screenshots). **C** switches to the
/// next rig now, **G** draws every rig's probe and the colliders, **R** resets.
final class CameraRigsScene: DemoScene {
    static let name = "camerarigs"
    static let summary = "camera rigs: third-person orbit with collision, first person, top-down and side-scroller, blended by priority"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private var player = Entity.invalid
    private var body = Entity.invalid
    private var visor = Entity.invalid
    private var rigs: [(name: String, entity: Entity)] = []
    private var clock: Float = 0
    private var current = 0
    private var held: Int?
    private var debugMode = false
    private var heading: Float = .pi / 2

    private static let sky = Vec3(0.6, 0.7, 0.84)
    private static let speed: Float = 2
    private static let turnX: Float = 9
    private static let cycle: Float = 6

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.42, 0.44, 0.4, 1), checker: true, roughness: 0.85), key: "rigs.floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.7), key: "rigs.matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.3), key: "rigs.gloss")
        _ = try sceneRenderer.registerMesh(PhysicsScene.capsuleMesh(radius: 0.3, halfHeight: 0.6), key: "rigs.body")
        held = ProcessInfo.processInfo.environment["CAMERARIGS_MODE"].flatMap { ["orbit": 0, "first": 1, "top": 2, "side": 3][$0] }
        build()
    }

    private func build() {
        world = World()
        physics = PhysicsWorld()
        physics.interpolatesPoses = true
        world.addPhysics(physics)
        clock = 0
        heading = .pi / 2
        sceneRenderer.resetMotion()

        _ = world.spawn(Transform.looking(from: Vec3(0, 6, 16), at: Vec3(0, 1, 0)), Name("Main Camera"),
                        Camera(fovY: 60 * .pi / 180, near: 0.1, far: 300, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.004))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.45))),
                        DirectionalLight(intensity: 1.5, shadowExtent: 18, shadowCenter: Vec3(0, 1, 0)))
        box("Floor", at: Vec3(0, -0.5, 0), size: Vec3(40, 1, 24), tint: Vec3(1, 1, 1), material: "rigs.floor")
        buildLevel()

        // The character: a kinematic capsule pacing along x, turning round at the ends.
        let controller = CharacterController(radius: 0.3, height: 1.8)
        player = world.spawn(Transform(position: Vec3(-Self.turnX, 0, 0), rotation: Quat(angle: heading, axis: Vec3(0, 1, 0))), Name("Player"),
                             controller, Collider(controller.colliderShape, offset: controller.colliderOffset), RigidBody(.kinematic, interpolation: .on))
        body = world.spawn(Transform(position: Vec3(0, 0.9, 0)), Name("Body"),
                           MeshRenderer(mesh: MeshHandle("rigs.body"), material: MaterialHandle("rigs.gloss"), tint: Vec3(0.95, 0.55, 0.15)))
        _ = world.setParent(body, to: player)
        // A visor shows which way it faces.
        visor = world.spawn(Transform(position: Vec3(0, 1.55, 0.24), scale: Vec3(0.4, 0.12, 0.14)), Name("Visor"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("rigs.gloss"), tint: Vec3(0.15, 0.2, 0.3)))
        _ = world.setParent(visor, to: player)

        let target = world.ref(to: player)
        let blend: Float = 1.2
        rigs = [
            ("orbit", world.spawn(Transform(), Name("Orbit Rig"),
                                  CameraRig(mode: .thirdPerson, target: target, blendTime: blend, distance: 4.5, recenterDelay: 0.8, recenterTime: 0.6))),
            ("first", world.spawn(Transform(), Name("First Person Rig"),
                                  CameraRig(mode: .firstPerson, target: target, targetOffset: Vec3(0, 1.62, 0), blendTime: blend,
                                            pitch: 8, recenterDelay: 0, recenterTime: 0.25, headBob: 0.05))),
            ("top", world.spawn(Transform(), Name("Top-down Rig"),
                                CameraRig(mode: .topDown, target: target, blendTime: blend, distance: 16, yaw: 0, pitch: 62))),
            ("side", world.spawn(Transform(), Name("Side Rig"),
                                 CameraRig(mode: .sideScroller, target: target, targetOffset: Vec3(0, 1.2, 0), blendTime: blend, distance: 11,
                                           pitch: 8, deadZone: Vec2(1.2, 1), lookAhead: 2.5, lookAheadTime: 0.8, collision: false))),
        ]
        current = held ?? 0
        world.activateCameraRig(rigs[current].entity)
        world.addCameraRigs()
        world.propagateTransforms()
    }

    /// A walled yard: a long back wall, end walls the orbit camera backs into, pillars and crates.
    private func buildLevel() {
        box("Back wall", at: Vec3(0, 1.5, -3), size: Vec3(26, 3, 0.5), tint: Vec3(0.72, 0.68, 0.6))
        box("West wall", at: Vec3(-12, 1.5, 0), size: Vec3(0.5, 3, 6.5), tint: Vec3(0.62, 0.6, 0.56))
        box("East wall", at: Vec3(12, 1.5, 0), size: Vec3(0.5, 3, 6.5), tint: Vec3(0.62, 0.6, 0.56))
        for (k, x) in [-6, -1, 4].enumerated() {
            box("Pillar", at: Vec3(Float(x), 1.25, -2.2), size: Vec3(0.8, 2.5, 0.8), tint: hsv(0.55 + Float(k) * 0.05, 0.35, 0.85))
        }
        for (k, p) in [(Float(-3.5), Float(2.4)), (2, 2.6), (7, 2.2)].enumerated() {
            box("Crate", at: Vec3(p.0, 0.4, p.1), size: Vec3(repeating: 0.8), tint: hsv(0.08 + Float(k) * 0.03, 0.5, 0.8))
        }
        // A lane down the middle.
        box("Lane", at: Vec3(0, 0.01, 0), size: Vec3(22, 0.02, 1.2), tint: Vec3(0.55, 0.5, 0.42), collider: false)
    }

    @discardableResult
    private func box(_ name: String, at position: Vec3, size: Vec3, tint: Vec3, material: String = "rigs.matte", collider: Bool = true) -> Entity {
        let entity = world.spawn(Transform(position: position, scale: size), Name(name),
                                 MeshRenderer(mesh: .cube, material: MaterialHandle(material), tint: tint))
        if collider { world.add(Collider(.box(halfExtents: Vec3(repeating: 0.5))), to: entity) }
        return entity
    }

    private func hsv(_ h: Float, _ s: Float, _ v: Float) -> Vec3 {
        let i = Int(h * 6) % 6, f = h * 6 - floorf(h * 6)
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        switch i {
        case 0: return Vec3(v, t, p)
        case 1: return Vec3(q, v, p)
        case 2: return Vec3(p, v, t)
        case 3: return Vec3(p, q, v)
        case 4: return Vec3(t, p, v)
        default: return Vec3(v, p, q)
        }
    }

    // MARK: DemoScene

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.35, distance: 16, target: Vec3(0, 1, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky, shadowExtent: 18) }
    var status: String {
        let live = world.liveCameraRig.flatMap { e in rigs.first { $0.entity == e }?.name } ?? "-"
        let blending = world.cameraRigs?.isBlending == true ? " (blending)" : ""
        return "rig: \(live)\(blending) [C] next rig [G] probes [R] reset"
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.g) { debugMode.toggle() }
        if world.cameraRigs?.input == nil { world.cameraRigs?.input = input }
        clock += dt
        // Every 6 s (or on C) the next rig goes live and the camera blends to it.
        let due = held == nil && Int(clock / Self.cycle) != Int((clock - dt) / Self.cycle)
        if input.wasPressed(.c) || due {
            current = (current + 1) % rigs.count
            world.activateCameraRig(rigs[current].entity)
        }
        // Pace along x, turning round at the ends (the body turns smoothly toward its direction).
        if let feet = world.get(Transform.self, for: player)?.position {
            world.modify(CharacterController.self, for: player) { c in
                var direction = c.moveVelocity.x == 0 ? Float(1) : (c.moveVelocity.x > 0 ? 1 : -1)
                if feet.x > Self.turnX { direction = -1 }
                if feet.x < -Self.turnX { direction = 1 }
                c.moveVelocity = Vec3(direction * Self.speed, 0, 0)
            }
            let wanted: Float = (world.get(CharacterController.self, for: player)?.moveVelocity.x ?? 1) > 0 ? .pi / 2 : -.pi / 2
            heading += (wanted - heading) * (1 - expf(-dt / 0.15))
            world.modify(Transform.self, for: player) { $0.rotation = Quat(angle: heading, axis: Vec3(0, 1, 0)) }
        }
        // First person: hide the body and visor the camera is in.
        let firstPerson = world.liveCameraRig == rigs[1].entity && world.cameraRigs?.isBlending != true
        for part in [body, visor] { world.modify(MeshRenderer.self, for: part) { $0.isVisible = !firstPerson } }
        world.update(dt: Double(dt))

        debug.removeAll()
        if debugMode {
            physics.drawDebug(into: debug, options: [.colliders])
            for rig in rigs {
                guard let probe = CameraRigSystem.probe(of: rig.entity, in: world) else { continue }
                let color = probe.hit == nil ? Vec4(0.35, 0.85, 0.95, 1) : Vec4(1, 0.35, 0.3, 1)
                debug.line(probe.start, probe.end, color: color)
                debug.sphere(center: probe.pose.position, radius: max(probe.radius, 0.05), color: color)
            }
        }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
