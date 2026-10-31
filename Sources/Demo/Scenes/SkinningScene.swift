import Engine
import Foundation

/// Skeletal animation and GPU skinning with the Khronos Fox (CC0 model, CC BY 4.0 rigging and
/// animation, see Models/LICENSE.md): a row of foxes playing Survey, Walk and Run from different
/// times, one switching between Walk and Run by exit-time transitions (crossfades), and a hero
/// fox circling in front, driven by a state machine: a 1D blend space Survey / Walk / Run on its
/// `speed` parameter, and a one-shot Survey on a trigger that returns when it ends. Footstep
/// events on the Walk and Run clips are counted. Everything moves through `Animator` +
/// `world.addAnimationSystem`, so it is deterministic under ENGINE_SCREENSHOT (fixed dt).
final class SkinningScene: DemoScene {
    static let name = "skinning"
    static let summary = "skeletal animation: glTF skins + GPU skinning, crossfades, a blend space and state machine (Fox)"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let library = AnimationLibrary()
    private let debug = DebugDraw()
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    /// The hero's model root (carries its `Animator`) and the entity moving it around the circle.
    private var hero = Entity.invalid
    private var heroMover = Entity.invalid
    private var heroAngle: Float = 0.6
    private var speedIndex = 3
    private var showBones = ProcessInfo.processInfo.environment["DEMO_SKELETON"] == "1"
    private var footsteps = 0
    private static let speeds: [Float] = [0, 0.5, 1, 1.6, 2, 2.5]
    private static let fogColor = Vec3(0.66, 0.74, 0.84)
    /// The Fox is in centimeters, about 80 tall and 155 long.
    private static let foxScale: Float = 0.02

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.42, 0.45, 0.38, 1), checker: true, roughness: 0.9), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.6, 0.58, 0.55, 1), roughness: 0.7), key: "stone")

        guard let url = Bundle.module.url(forResource: "Fox", withExtension: "glb", subdirectory: "Models") else {
            throw GraphicsError("Models/Fox.glb is missing from the Demo bundle")
        }
        let model = try GLTFReader.read(contentsOf: url)
        for warning in model.warnings { print("glTF: \(warning)") }
        let (textures, failures) = model.makeTextures(device: renderer.device) { data, _ in try ImageDecoder.decode(data) }
        for failure in failures { print("glTF: \(failure)") }
        let handles = try model.register(with: sceneRenderer, keyPrefix: "fox", textures: textures)

        // Survey, Walk, Run; the gaits get footstep events (both front paws per cycle).
        var clips = model.registerAnimations(in: library, keyPrefix: "fox")
        guard clips.count == 3 else { throw GraphicsError("Fox.glb should have 3 animations, has \(clips.count)") }
        for (index, handle) in clips.enumerated().dropFirst() {
            var clip = library.clip(handle)!
            clip.events = [AnimationEvent(time: 0, name: "step"), AnimationEvent(time: clip.duration / 2, name: "step")]
            clips[index] = library.register(clip, key: handle.key)
        }
        let (survey, walk, run) = (clips[0], clips[1], clips[2])

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(9, 7, 14), at: Vec3(0, 1, -1)),
            Camera(fovY: .pi / 3.5, near: 0.1, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.5, fogColor: Self.fogColor, fogDensity: 0.01))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.35))),
            DirectionalLight(intensity: 1.4, shadowExtent: 14))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(60, 1, 60)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))

        func spawnFox(_ name: String, at position: Vec3, facing angle: Float, tint: Vec3 = Vec3(1, 1, 1)) -> (root: Entity, rig: (targets: [Entity], restPose: [Transform])) {
            let root = world.spawn(
                Transform(position: position, rotation: Quat(angle: angle, axis: Vec3(0, 1, 0)), scale: Vec3(repeating: Self.foxScale)),
                Name(name))
            let instance = model.instantiate(in: world, under: root, handles: handles)
            for entity in instance.renderers { world.modify(MeshRenderer.self, for: entity) { $0.tint = tint } }
            return (root, model.animationTargets(of: instance))
        }

        // The parade: the same clips from different start times, on pedestals.
        let parade: [(AnimationClipHandle, Float, Vec3)] = [
            (survey, 0.1, Vec3(1, 1, 1)), (survey, 0.55, Vec3(1, 0.85, 0.7)), (walk, 0.3, Vec3(0.85, 0.9, 1)),
            (run, 0, Vec3(1, 1, 1)), (run, 0.6, Vec3(0.8, 0.8, 0.8)),
        ]
        for (i, (clip, time, tint)) in parade.enumerated() {
            let x = (Float(i) - 2.5) * Float(3.6)
            _ = world.spawn(Transform(position: Vec3(x, 0.15, -5), scale: Vec3(2.6, 0.3, 1.6)), MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
            let fox = spawnFox("Fox \(i)", at: Vec3(x, 0.3, -5), facing: .pi / 2, tint: tint)
            world.add(Animator(targets: fox.rig.targets, restPose: fox.rig.restPose, clip: clip, normalizedTime: time), to: fox.root)
        }
        // Walk ↔ Run every two cycles, crossfading over 0.4 s (exit-time transitions only).
        do {
            let x: Float = 2.5 * 3.6
            _ = world.spawn(Transform(position: Vec3(x, 0.15, -5), scale: Vec3(2.6, 0.3, 1.6)), MeshRenderer(mesh: .cube, material: MaterialHandle("stone")))
            let fox = spawnFox("Fox crossfade", at: Vec3(x, 0.3, -5), facing: .pi / 2, tint: Vec3(1, 0.75, 0.55))
            let machine = AnimationStateMachine(
                states: [AnimationState("Walk", .clip(walk)), AnimationState("Run", .clip(run))],
                transitions: [AnimationTransition(from: "Walk", to: "Run", exitTime: 2, duration: 0.4),
                              AnimationTransition(from: "Run", to: "Walk", exitTime: 3, duration: 0.4)])
            world.add(Animator(targets: fox.rig.targets, restPose: fox.rig.restPose, stateMachine: machine), to: fox.root)
        }

        // The hero: locomotion blend space by speed, a one-shot Survey on the "survey" trigger.
        heroMover = world.spawn(Transform(), Name("Hero mover"))
        let heroFox = spawnFox("Hero fox", at: .zero, facing: 0)
        world.setParent(heroFox.root, to: heroMover)
        hero = heroFox.root
        let machine = AnimationStateMachine(
            states: [
                AnimationState("Locomotion", .blend1D(parameter: "speed", entries: [
                    BlendSpaceEntry(clip: survey, position: 0), BlendSpaceEntry(clip: walk, position: 1),
                    BlendSpaceEntry(clip: run, position: 2.5),
                ])),
                AnimationState("Survey", .clip(survey), loops: false),
            ],
            transitions: [
                AnimationTransition(from: nil, to: "Survey", conditions: [.triggered("survey")], duration: 0.3),
                AnimationTransition(from: "Survey", to: "Locomotion", exitTime: 0.95, duration: 0.4),
            ],
            initialState: "Locomotion")
        world.add(Animator(targets: heroFox.rig.targets, restPose: heroFox.rig.restPose, stateMachine: machine,
                           parameters: ["speed": .float(Self.speeds[speedIndex])]), to: hero)

        world.addAnimationSystem(library) { [weak self] entity, event in
            if event.name == "step", entity == self?.hero { self?.footsteps += 1 }
        }
        // Moves the hero around its circle at a pace that matches its gait (0 while surveying).
        world.addSystem("hero", stage: .update, before: "animation") { [weak self] world in
            guard let self, let animator = world.get(Animator.self, for: self.hero) else { return }
            let moving = animator.currentState == "Locomotion" ? (animator.float("speed") ?? 0) : 0
            self.heroAngle += world.time.delta * moving * 0.45
            let radius: Float = 4
            world.add(Transform(position: Vec3(sinf(self.heroAngle) * radius, 0, 2 + cosf(self.heroAngle) * radius),
                                rotation: Quat(angle: self.heroAngle + .pi / 2, axis: Vec3(0, 1, 0))), to: self.heroMover)
        }
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.35, pitch: 0.36, distance: 14, target: Vec3(0, 0.8, -1.5)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var status: String {
        let animator = world.get(Animator.self, for: hero)
        let state = animator?.currentState ?? "-"
        let s = sceneRenderer.stats.list
        return "hero: \(state) speed \(Self.speeds[speedIndex]) [J/K], survey [T], \(footsteps) steps, "
            + "bones \(showBones ? "on" : "off") [B], \(s.opaque) drawn, \(s.drawCalls) draws"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.1)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.j) { speedIndex = max(speedIndex - 1, 0) }
        if input.wasPressed(.k) { speedIndex = min(speedIndex + 1, Self.speeds.count - 1) }
        if input.wasPressed(.b) { showBones.toggle() }
        world.modify(Animator.self, for: hero) {
            $0.setFloat("speed", Self.speeds[speedIndex])
            if input.wasPressed(.t) { $0.setTrigger("survey") }
        }
        world.update(dt: Double(dt))
        debug.removeAll()
        if showBones { world.drawSkeletons(into: debug) }
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
}
