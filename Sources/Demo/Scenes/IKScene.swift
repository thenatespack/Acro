import Engine
import Foundation

/// Inverse kinematics and ragdolls on Character Builder humanoids (skeletons, skinned bodies and
/// the idle clip made in code from `CharacterRig`):
/// - left: a character standing across two steps of an uneven staircase; foot placement casts
///   rays against the physics floor, drops the pelvis and bends the leg on the lower step, and
///   turns the feet to the ground;
/// - middle: a character aiming: the spine, chest, neck and head turn toward a glowing target
///   circling it (aim IK) while the right arm reaches for it (two-bone IK with a pole);
/// - right: a ragdoll drop: a character pushed off a crate goes limp (capsule bodies, limited
///   joints), lands on the floor, then gets up (blends back to the animation) and climbs back.
///
/// Deterministic under ENGINE_SCREENSHOT (fixed dt): by the screenshot frame the ragdoll lies on
/// the floor.
final class IKScene: DemoScene {
    static let name = "ik"
    static let summary = "inverse kinematics (foot placement on stairs, aim and reach) and a ragdoll drop with get-up"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private let library = AnimationLibrary()
    private let rig = CharacterRig(template: .humanoid)
    private var idle = AnimationClipHandle("ik.idle")
    private var regions: [CharacterRegion] = []
    private var cameraEntity = Entity.invalid
    private var stander = Entity.invalid
    private var aimer = Entity.invalid
    private var faller = Entity.invalid
    private var target = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private var clock: Float = 0
    private var dropped = false
    private var standing = false
    private var debugMode = false

    private static let sky = Vec3(0.6, 0.7, 0.85)
    private static let crate = Vec3(3.2, 1.1, 0)
    /// Where the faller stands: near the crate's front-right corner, so the push carries its
    /// whole body (not just the top half) over the edge.
    private static let fallerStart = crate + Vec3(0.3, 0, 0.25)
    private static let cycle: Float = 8

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.36, 0.38, 0.36, 1), checker: true, roughness: 0.85), key: "ik.floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.6), key: "ik.matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 0.55, 0.15, 1), roughness: 0.3, emissiveColor: Vec3(1, 0.4, 0.08), emissiveStrength: 4), key: "ik.glow")
        for (region, geometry) in rig.bodyMeshes(segments: 12, smooth: true) {
            regions.append(region)
            _ = try sceneRenderer.registerMesh(geometry, key: "ik.body.\(region.rawValue)")
            let c = MeshBuildColor.linear(fromSRGB: CharacterTemplate.humanoid.defaultColor(region))
            try sceneRenderer.registerMaterial(Material(baseColor: Vec4(c.x, c.y, c.z, 1), roughness: region == .eyes ? 0.2 : 0.75),
                                               key: "ik.body.\(region.rawValue)")
        }
        // A white shirt each character tints its own color, so the three are told apart.
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.75), key: "ik.shirt")
        _ = try sceneRenderer.registerMesh(Self.floorMesh(halfSize: 20), key: "ik.floor")
        if let clip = CharacterClips.clip("idle", rig: rig) { idle = library.register(clip, key: "ik.idle") }
        build()
    }

    /// (Re)creates the world.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        world.addPhysics(physics)
        world.addAnimationSystem(library)
        clock = 0
        dropped = false
        standing = false
        sceneRenderer.resetMotion()

        cameraEntity = world.spawn(Transform.looking(from: Vec3(1, 2.5, 7), at: Vec3(0.2, 0.9, 0)),
                                   Camera(fovY: .pi / 3.5, near: 0.1, far: 120, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.004))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.45))),
                        DirectionalLight(intensity: 1.6, shadowExtent: 9, shadowCenter: Vec3(0, 0.8, 0)))
        _ = world.spawn(Transform(), Name("Floor"), MeshRenderer(mesh: MeshHandle("ik.floor"), material: MaterialHandle("ik.floor"), castsShadows: false),
                        Collider(.box(Vec3(20, 0.5, 20)), offset: Vec3(0, -0.5, 0), friction: 0.9))

        // Uneven stairs climbing toward -x.
        let heights: [Float] = [0.12, 0.31, 0.43, 0.67, 0.82]
        for (k, h) in heights.enumerated() {
            let x = -2.7 - Float(k) * 0.55
            box("Step", at: Vec3(x, h / 2, 0), size: Vec3(0.55, h, 2.2), tint: hsv(0.08 + Float(k) * 0.03, 0.4, 0.92))
        }
        // Its root on the edge between the first two steps (on the higher one); the left foot hangs over the lower.
        stander = spawnCharacter("Stander", at: Vec3(-2.975, 0.31, 0.1), yaw: 0, shirt: Vec3(0.85, 0.45, 0.1),
                                 ik: [AnimationIKNode.humanoidFeet()])

        // The aimer and its target.
        target = world.spawn(Transform(position: Vec3(0.6, 1.5, 1.2), scale: Vec3(repeating: 0.14)), Name("Target"),
                             MeshRenderer(mesh: .sphere, material: MaterialHandle("ik.glow")))
        aimer = spawnCharacter("Aimer", at: Vec3(0, 0, 0), yaw: 0.25, shirt: Vec3(0.15, 0.6, 0.25), ik: [
            AnimationIKNode(name: "Look", type: .aim, bones: ["spine", "chest", "neck", "head"], targetEntity: "Target", maxAngle: 35),
            AnimationIKNode(name: "Hand.R", type: .twoBoneIK, bones: ["upperArm.R", "lowerArm.R", "hand.R"], targetEntity: "Target",
                            pole: Vec3(-0.3, -0.4, -1)),
        ])

        // The crate the faller is pushed off, and some boxes to land among.
        box("Crate", at: Self.crate - Vec3(0, 0.55, 0), size: Vec3(1, 1.1, 1), tint: Vec3(0.55, 0.4, 0.25))
        box("Block", at: Vec3(3.6, 0.15, 1.3), size: Vec3(0.6, 0.3, 0.6), tint: Vec3(0.4, 0.5, 0.7))
        faller = spawnCharacter("Faller", at: Self.fallerStart, yaw: 0.0, shirt: Vec3(0.75, 0.12, 0.12), ik: nil)
        world.add(rig.ragdoll(CharacterRagdoll()), to: faller)
        world.propagateTransforms()
    }

    /// A humanoid: root, bones, skinned body meshes, an idle Animator with `ik`.
    @discardableResult
    private func spawnCharacter(_ name: String, at position: Vec3, yaw: Float, shirt: Vec3, ik: [AnimationIKNode]?) -> Entity {
        let root = world.spawn(Transform(position: position, rotation: Quat(angle: yaw, axis: Vec3(0, 1, 0))), Name(name))
        var bones: [Entity] = []
        for bone in rig.bones {
            let e = world.spawn(Transform(position: bone.offset), Name(bone.name))
            _ = world.setParent(e, to: bone.parent.map { bones[$0] } ?? root)
            bones.append(e)
        }
        for region in regions {
            let material = region == .body ? MaterialHandle("ik.shirt") : MaterialHandle("ik.body.\(region.rawValue)")
            let body = world.spawn(Transform(), Name("Body \(region.rawValue)"),
                                   MeshRenderer(mesh: MeshHandle("ik.body.\(region.rawValue)"), material: material,
                                                tint: region == .body ? shirt : Vec3(1, 1, 1)),
                                   Skin(joints: bones, inverseBindMatrices: rig.inverseBindMatrices))
            _ = world.setParent(body, to: root)
        }
        var animator = Animator(targets: bones, restPose: rig.restPose, clip: idle, normalizedTime: Float(bones.count % 3) * 0.3)
        animator.ik = ik
        world.add(animator, to: root)
        return root
    }

    @discardableResult
    private func box(_ name: String, at position: Vec3, size: Vec3, tint: Vec3) -> Entity {
        world.spawn(Transform(position: position, scale: size), Name(name),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("ik.matte"), tint: tint),
                    Collider(.box(Vec3(repeating: 0.5)), friction: 0.8))
    }

    var initialView: OrbitView { OrbitView(yaw: 0.12, pitch: 0.28, distance: 7.6, target: Vec3(0.1, 0.9, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky, shadowExtent: 9) }
    var status: String {
        let mode = world.get(Ragdoll.self, for: faller)?.mode.rawValue ?? ""
        return "ragdoll \(mode) [R] reset [G] physics debug"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.1)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.g) { debugMode.toggle() }
        clock += dt
        // The target circles the aimer at about head height.
        let a = clock * 0.9
        world.modify(Transform.self, for: target) {
            $0.position = Vec3(0.75 * sinf(a) + 0.15, 1.35 + 0.25 * sinf(a * 1.7), 0.75 + 0.45 * cosf(a))
        }
        // The faller: limp right away with a push off the crate, up again after a while, then back on the crate.
        let phase = clock.truncatingRemainder(dividingBy: Self.cycle)
        if !dropped, phase > 0.05 {
            dropped = true
            world.modify(Ragdoll.self, for: faller) {
                $0.goLimp()
                $0.applyImpulse(bone: "spine", impulse: Vec3(40, 20, 70))
            }
        } else if dropped, !standing, phase > 4.5 {
            standing = true
            world.modify(Ragdoll.self, for: faller) { $0.getUp() }
        } else if standing, phase < 0.05 {
            dropped = false
            standing = false
            world.modify(Transform.self, for: faller) { $0.position = Self.fallerStart }
        }
        world.update(dt: Double(dt))
        debug.removeAll()
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

    /// A flat square with UVs of 2 m per tile.
    private static func floorMesh(halfSize h: Float) -> MeshGeometry {
        var geometry = MeshGeometry(vertices: [], indices: [])
        for (x, z) in [(-h, -h), (h, -h), (-h, h), (h, h)] {
            geometry.vertices.append(MeshVertex(position: Vec3(x, 0, z), normal: Vec3(0, 1, 0), uv: Vec2(x, z) * 0.5))
        }
        geometry.indices = [0, 2, 1, 1, 2, 3]
        return geometry
    }
}
