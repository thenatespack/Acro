import Engine
import Foundation

/// Hitboxes, damage and interaction (Engine/Gameplay) on Character Builder humanoids:
/// - left: a fighter swings a sword at a training dummy. The sword is an animation hitbox track
///   (`Animator.hitboxes`: the attack state's swing window on the right hand); the dummy has a
///   `Health`, hurtboxes on its bones (`CharacterRig.hurtboxes`) and a `Ragdoll`. Each hit flashes
///   it, stops time for a moment, shakes the camera and makes it flinch (partial ragdoll); the
///   third hit kills it and it goes limp. Its health shows above it; it stands up again later.
/// - right: a gate (`Door`) opened by a lever (`Lever` with the gate as target), and a chest
///   (`Container` with a lid). Two visitors (`Interactor`s) use them: the focused one is
///   highlighted and a prompt shows the use action's key ("[E] Pull", "[E] Open").
///
/// Deterministic under ENGINE_SCREENSHOT (fixed dt): the scene is pre-rolled so that by the
/// screenshot frame the dummy lies on the floor, the gate is open and a prompt shows over the chest.
final class CombatScene: DemoScene {
    static let name = "combat"
    static let summary = "hitboxes and damage (a sword swing kills a dummy that ragdolls), hit stop and shake, a lever-opened gate and a chest with prompts"

    private var world = World()
    private var physics = PhysicsWorld()
    private var gameplay: GameplaySystems!
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private let library = AnimationLibrary()
    private let rig = CharacterRig(template: .humanoid)
    private var regions: [CharacterRegion] = []
    private var clips: [String: AnimationClipHandle] = [:]
    private var cameraEntity = Entity.invalid
    private var fighter = Entity.invalid
    private var dummy = Entity.invalid
    private var healthLabel = Entity.invalid
    private var leverUser = Entity.invalid
    private var chestUser = Entity.invalid
    private var lever = Entity.invalid
    private var chest = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private var clock: Float = 0
    private var nextSwing: Float = 0
    private var pulled = false
    private var looted = false
    private var showHitboxes = true

    private static let sky = Vec3(0.55, 0.62, 0.78)
    private static let cycle: Float = 12
    /// Seconds simulated before the first frame shows (so the screenshot catches the dummy down).
    private static let preroll: Float = 3.6

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.34, 0.33, 0.3, 1), checker: true, roughness: 0.9), key: "combat.floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.65), key: "combat.matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.85, 0.88, 0.92, 1), metallic: 1, roughness: 0.25), key: "combat.steel")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 0.75, 0.3, 1), roughness: 0.4, emissiveColor: Vec3(1, 0.6, 0.2), emissiveStrength: 2),
                                           key: "combat.gold")
        for (region, geometry) in rig.bodyMeshes(segments: 12, smooth: true) {
            regions.append(region)
            _ = try sceneRenderer.registerMesh(geometry, key: "combat.body.\(region.rawValue)")
            let c = MeshBuildColor.linear(fromSRGB: CharacterTemplate.humanoid.defaultColor(region))
            try sceneRenderer.registerMaterial(Material(baseColor: Vec4(c.x, c.y, c.z, 1), roughness: region == .eyes ? 0.2 : 0.75),
                                               key: "combat.body.\(region.rawValue)")
        }
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.75), key: "combat.shirt")
        for name in ["idle", "attack"] {
            if let clip = CharacterClips.clip(name, rig: rig) { clips[name] = library.register(clip, key: "combat.\(name)") }
        }
        build()
    }

    /// (Re)creates the world and plays it forward to `preroll`.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        world.addPhysics(physics)
        world.addAnimationSystem(library)
        gameplay = world.addGameplay(input: nil, physics: { [unowned self] in physics })
        gameplay.feel.maxOffset = 0.06
        clock = 0
        nextSwing = 0.2
        pulled = false
        looted = false
        sceneRenderer.resetMotion()

        cameraEntity = world.spawn(Transform.looking(from: Vec3(0.6, 2.6, 7.5), at: Vec3(0.6, 0.9, 0)),
                                   Camera(fovY: .pi / 3.4, near: 0.1, far: 120, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.27, 0.24), fogColor: Self.sky, fogDensity: 0.004))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.35, 0.85, 0.5))),
                        DirectionalLight(intensity: 1.7, shadowExtent: 9, shadowCenter: Vec3(0.5, 0.8, 0)))
        _ = world.spawn(Transform(), Name("Floor"), MeshRenderer(mesh: .plane, material: MaterialHandle("combat.floor"), castsShadows: false),
                        Collider(.box(Vec3(20, 0.5, 20)), offset: Vec3(0, -0.5, 0), friction: 0.9))
        world.modify(Transform.self, for: world.firstEntity(named: "Floor")!) { $0.scale = Vec3(40, 1, 40) }

        // The fighter, facing +Z with a sword in its right hand; the dummy in front of it.
        fighter = spawnCharacter("Fighter", at: Vec3(-1.6, 0, -0.55), yaw: 0, shirt: Vec3(0.2, 0.35, 0.75))
        world.add(Health(max: 100, team: "heroes"), to: fighter)
        let hand = CombatSystem.descendant(named: "hand.R", of: fighter, in: world)!
        let blade = world.spawn(Transform(position: Vec3(0, -0.42, 0), scale: Vec3(0.05, 0.7, 0.025)), Name("Sword"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("combat.steel")))
        _ = world.setParent(blade, to: hand)
        world.modify(Animator.self, for: fighter) {
            $0.hitboxes = [HitboxTrack(name: "Sword", state: "attack", bone: "hand.R",
                                       shape: .capsule(from: Vec3(0, -0.08, 0), to: Vec3(0, -0.78, 0), radius: 0.07),
                                       start: 0.3, end: 0.6, damage: HitDamage(amount: 30, type: "slash", knockback: 10))]
        }

        dummy = spawnCharacter("Dummy", at: Vec3(-1.6, 0, 0.55), yaw: .pi, shirt: Vec3(0.8, 0.65, 0.35))
        world.add(Health(max: 60, team: "dummies", invulnerableTime: 0.2), to: dummy)
        for box in rig.hurtboxes() {
            if let bone = CombatSystem.descendant(named: box.bone, of: dummy, in: world) { world.add(box.hurtbox, to: bone) }
        }
        world.add(rig.ragdoll(CharacterRagdoll(strength: 10)), to: dummy)
        healthLabel = world.spawn(Transform(position: Vec3(-1.6, 2.2, 0.55)), Name("Health"),
                                  TextMesh("HP 60 / 60", size: 0.24, color: Vec3(1, 1, 1), emissiveColor: Vec3(1, 0.4, 0.3), emissiveStrength: 1.2,
                                           outlineWidth: 0.12, outlineColor: Vec3(0.05, 0.05, 0.08), billboard: true))

        // The gate: posts, a lintel and a door panel on its hinge (the Door entity).
        let gateX: Float = 1.2
        box("Post L", at: Vec3(gateX - 0.08, 1.1, -1.2), size: Vec3(0.16, 2.2, 0.16), tint: Vec3(0.45, 0.32, 0.22))
        box("Post R", at: Vec3(gateX + 1.48, 1.1, -1.2), size: Vec3(0.16, 2.2, 0.16), tint: Vec3(0.45, 0.32, 0.22))
        box("Lintel", at: Vec3(gateX + 0.7, 2.25, -1.2), size: Vec3(1.72, 0.14, 0.18), tint: Vec3(0.45, 0.32, 0.22))
        let gate = world.spawn(Transform(position: Vec3(gateX, 0, -1.2)), Name("Gate"), Door(motion: SwingMotion(angle: -100, axis: Vec3(0, 1, 0), speed: 1.2)),
                               Interactable(focusOffset: Vec3(0.7, 1.1, 0)))
        let panel = world.spawn(Transform(position: Vec3(0.7, 1.05, 0), scale: Vec3(1.36, 2.04, 0.08)), Name("Panel"),
                                MeshRenderer(mesh: .cube, material: MaterialHandle("combat.matte"), tint: Vec3(0.6, 0.42, 0.26)))
        _ = world.setParent(panel, to: gate)

        // The lever that opens it.
        box("Lever Base", at: Vec3(3.3, 0.15, -0.6), size: Vec3(0.4, 0.3, 0.3), tint: Vec3(0.3, 0.3, 0.33))
        lever = world.spawn(Transform(position: Vec3(3.3, 0.3, -0.6), rotation: Quat(angle: 0.6, axis: Vec3(1, 0, 0))), Name("Lever"),
                            Lever(target: "Gate"), Interactable(focusOffset: Vec3(0, 0.4, 0)))
        let handle = world.spawn(Transform(position: Vec3(0, 0.3, 0), scale: Vec3(0.06, 0.6, 0.06)), Name("Handle"),
                                 MeshRenderer(mesh: .cylinder, material: MaterialHandle("combat.steel")))
        let knob = world.spawn(Transform(position: Vec3(0, 0.62, 0), scale: Vec3(repeating: 0.12)), Name("Knob"),
                               MeshRenderer(mesh: .sphere, material: MaterialHandle("combat.matte"), tint: Vec3(0.8, 0.1, 0.1)))
        _ = world.setParent(handle, to: lever)
        _ = world.setParent(knob, to: lever)

        // The chest: a body and a lid hinged at its back edge.
        chest = world.spawn(Transform(position: Vec3(2.4, 0, 1.3), rotation: Quat(angle: -0.4, axis: Vec3(0, 1, 0))), Name("Chest"),
                            Container(items: ["gold": 25, "potion": 1]), Interactable(focusOffset: Vec3(0, 0.45, 0)))
        let body = world.spawn(Transform(position: Vec3(0, 0.25, 0), scale: Vec3(0.9, 0.5, 0.55)), Name("Body"),
                               MeshRenderer(mesh: .cube, material: MaterialHandle("combat.matte"), tint: Vec3(0.55, 0.35, 0.18)))
        let lid = world.spawn(Transform(position: Vec3(0, 0.5, -0.275)), Name("Lid"))
        let lidMesh = world.spawn(Transform(position: Vec3(0, 0.07, 0.275), scale: Vec3(0.94, 0.14, 0.58)), Name("Lid Board"),
                                  MeshRenderer(mesh: .cube, material: MaterialHandle("combat.matte"), tint: Vec3(0.5, 0.3, 0.15)))
        let trim = world.spawn(Transform(position: Vec3(0, 0.08, 0.57), scale: Vec3(0.2, 0.12, 0.04)), Name("Lock"),
                               MeshRenderer(mesh: .cube, material: MaterialHandle("combat.gold")))
        for part in [body, lid] { _ = world.setParent(part, to: chest) }
        for part in [lidMesh, trim] { _ = world.setParent(part, to: lid) }

        // Two visitors: one by the lever, one in front of the chest.
        leverUser = visitor("Visitor", at: Vec3(3.3, 0, 0.35), facing: Vec3(3.3, 0, -0.6), tint: Vec3(0.3, 0.7, 0.4))
        chestUser = visitor("Looter", at: Vec3(2.95, 0, 2.4), facing: Vec3(2.4, 0, 1.3), tint: Vec3(0.75, 0.3, 0.6))
        world.propagateTransforms()
        let step: Float = 1.0 / 60
        for _ in 0..<Int(Self.preroll / step) { advance(step) }
    }

    /// A humanoid: root, bones, skinned body meshes, an Animator with idle and attack states.
    private func spawnCharacter(_ name: String, at position: Vec3, yaw: Float, shirt: Vec3) -> Entity {
        let root = world.spawn(Transform(position: position, rotation: Quat(angle: yaw, axis: Vec3(0, 1, 0))), Name(name))
        var bones: [Entity] = []
        for bone in rig.bones {
            let e = world.spawn(Transform(position: bone.offset), Name(bone.name))
            _ = world.setParent(e, to: bone.parent.map { bones[$0] } ?? root)
            bones.append(e)
        }
        for region in regions {
            let material = region == .body ? MaterialHandle("combat.shirt") : MaterialHandle("combat.body.\(region.rawValue)")
            let body = world.spawn(Transform(), Name("Body \(region.rawValue)"),
                                   MeshRenderer(mesh: MeshHandle("combat.body.\(region.rawValue)"), material: material,
                                                tint: region == .body ? shirt : Vec3(1, 1, 1)),
                                   Skin(joints: bones, inverseBindMatrices: rig.inverseBindMatrices))
            _ = world.setParent(body, to: root)
        }
        var states = [AnimationState("idle", .clip(clips["idle"] ?? AnimationClipHandle("combat.idle")))]
        if let attack = clips["attack"] { states.append(AnimationState("attack", .clip(attack), loops: false)) }
        let machine = AnimationStateMachine(states: states, transitions: [
            AnimationTransition(from: nil, to: "attack", conditions: [.triggered("attack")], duration: 0.08, canTransitionToSelf: true),
            AnimationTransition(from: "attack", to: "idle", exitTime: 1, duration: 0.2),
        ], initialState: "idle")
        world.add(Animator(targets: bones, restPose: rig.restPose, stateMachine: machine, parameters: ["attack": .trigger(false)]), to: root)
        return root
    }

    /// An interactor: a capsule with a nose, looking at `target`.
    private func visitor(_ name: String, at position: Vec3, facing target: Vec3, tint: Vec3) -> Entity {
        let d = target - position
        let yaw = atan2f(-d.x, -d.z)
        let e = world.spawn(Transform(position: position, rotation: Quat(angle: yaw, axis: Vec3(0, 1, 0))), Name(name),
                            Interactor(range: 2.4, maxAngle: 50, eyeHeight: 1.4))
        let body = world.spawn(Transform(position: Vec3(0, 0.8, 0), scale: Vec3(0.5, 0.8, 0.5)), Name("Body"),
                               MeshRenderer(mesh: .capsule, material: MaterialHandle("combat.matte"), tint: tint))
        let nose = world.spawn(Transform(position: Vec3(0, 1.4, -0.27), scale: Vec3(0.12, 0.1, 0.12)), Name("Nose"),
                               MeshRenderer(mesh: .cube, material: MaterialHandle("combat.matte"), tint: tint * 0.6))
        _ = world.setParent(body, to: e)
        _ = world.setParent(nose, to: e)
        return e
    }

    @discardableResult
    private func box(_ name: String, at position: Vec3, size: Vec3, tint: Vec3) -> Entity {
        world.spawn(Transform(position: position, scale: size), Name(name),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("combat.matte"), tint: tint),
                    Collider(.box(Vec3(repeating: 0.5)), friction: 0.8))
    }

    /// The scripted timeline: swings every 1.2 s, the lever at 0.8 s, the chest at 7 s, the dummy up again at 10 s.
    private func advance(_ dt: Float) {
        clock += dt
        let alive = world.get(Health.self, for: dummy).map { !$0.dead } ?? false
        if clock >= nextSwing, alive {
            nextSwing += 1.2
            world.modify(Animator.self, for: fighter) { $0.setTrigger("attack") }
        }
        if !pulled, clock > 0.8 {
            pulled = true
            gameplay.interaction.interact(leverUser, with: lever, in: world)
        }
        if !looted, clock > 7 {
            looted = true
            gameplay.interaction.interact(chestUser, with: chest, in: world)
        }
        if clock > 10, !alive {
            // Stand the dummy up and heal it.
            world.modify(Ragdoll.self, for: dummy) { $0.getUp() }
            world.modify(Health.self, for: dummy) { $0.current = $0.max; $0.dead = false }
            nextSwing = clock + 1.5
        }
        if clock > Self.cycle {
            clock = 0
            nextSwing = 0.2
            pulled = false
            looted = false
            world.modify(Container.self, for: chest) { $0.open = false; $0.items = ["gold": 25, "potion": 1] }
            world.modify(Interactable.self, for: chest) { $0.enabled = true }
            gameplay.interaction.interact(leverUser, with: lever, in: world)  // closes the gate again
            pulled = false
        }
        world.update(dt: Double(dt))
        if let health = world.get(Health.self, for: dummy) {
            world.modify(TextMesh.self, for: healthLabel) {
                $0.text = health.dead ? "Down!" : String(format: "HP %.0f / %.0f", health.current, health.max)
            }
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.05, pitch: 0.3, distance: 7.2, target: Vec3(0.6, 0.8, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky, shadowExtent: 9) }
    var status: String {
        let health = world.get(Health.self, for: dummy)
        return String(format: "dummy %.0f HP, %d hits [R] reset [H] hitboxes", health?.current ?? 0, world.combat.lastSequence)
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.1)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.h) { showHitboxes.toggle() }
        advance(dt)
        debug.removeAll()
        if showHitboxes { CombatSystem.drawDebug(world, into: debug) }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            // The shake moves the camera entity; follow the orbit and keep the shake's offset.
            let offset = gameplay.feel.currentOffset
            world.add(Transform.looking(from: orbit.eye + offset, at: orbit.target + offset), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
