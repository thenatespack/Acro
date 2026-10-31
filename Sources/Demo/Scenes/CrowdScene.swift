import Engine
import Foundation

/// A CPU stress test for the job system (`JobSystem`, `ENGINE_JOB_THREADS`): 144 skinned foxes
/// in a 12 x 12 crowd (each with its own `Animator`, clip and start time: animator updates and
/// skin palettes run in parallel), 640 rigid bodies dropped into a pen of four walled bays
/// (pair search, narrowphase and the four piles' solver islands in parallel), and 2500
/// shadow-casting posts around them (camera and shadow-caster culling in parallel). The title
/// shows the CPU time of the world update and of render prep, averaged over the last 30
/// frames, and the job thread count.
/// Results are the same for any thread count, so screenshots match `ENGINE_JOB_THREADS=1`.
final class CrowdScene: DemoScene {
    static let name = "crowd"
    static let summary = "job system stress: 144 animated skinned foxes, 640 rigid bodies in four bays (four solver islands), 2500 culled shadow casters"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let library = AnimationLibrary()
    private let model: ImportedModel
    private let handles: ModelHandles
    private let clips: [AnimationClipHandle]
    private var cameraEntity = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private var timings = (update: [Double](), prep: [Double]())
    private static let sky = Vec3(0.62, 0.7, 0.8)
    private static let foxScale: Float = 0.02

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.4, 0.42, 0.38, 1), checker: true, roughness: 0.9), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.6), key: "matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.25), key: "gloss")

        guard let url = Bundle.module.url(forResource: "Fox", withExtension: "glb", subdirectory: "Models") else {
            throw GraphicsError("Models/Fox.glb is missing from the Demo bundle")
        }
        model = try GLTFReader.read(contentsOf: url)
        let (textures, failures) = model.makeTextures(device: renderer.device) { data, _ in try ImageDecoder.decode(data) }
        for failure in failures { print("glTF: \(failure)") }
        handles = try model.register(with: sceneRenderer, keyPrefix: "fox", textures: textures)
        clips = model.registerAnimations(in: library, keyPrefix: "fox")
        guard clips.count == 3 else { throw GraphicsError("Fox.glb should have 3 animations, has \(clips.count)") }
        build()
    }

    /// (Re)creates the world.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        world.addPhysics(physics)
        world.addAnimationSystem(library)
        sceneRenderer.resetMotion()
        var rng = SplitMix64(state: 620)

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(26, 22, 30), at: Vec3(0, 0, 0)),
            Camera(fovY: .pi / 3.5, near: 0.3, far: 300, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.006))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.35))),
            DirectionalLight(intensity: 1.5, shadowExtent: 40))
        _ = world.spawn(
            Transform(position: Vec3(0, -0.5, 0), scale: Vec3(160, 1, 160)),
            MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false),
            Collider(.box(Vec3(repeating: 0.5)), friction: 0.7))

        // The crowd: 12 x 12 foxes playing Survey / Walk / Run from different times.
        for row in 0..<12 {
            for column in 0..<12 {
                let k = row * 12 + column
                let root = world.spawn(
                    Transform(position: Vec3(Float(column) * 2.2 - 30, 0, Float(row) * 2 - 12),
                              rotation: Quat(angle: .pi / 2 + (rng.next() - 0.5) * 0.6, axis: Vec3(0, 1, 0)),
                              scale: Vec3(repeating: Self.foxScale)))
                let instance = model.instantiate(in: world, under: root, handles: handles)
                let tint = hsv(0.05 + rng.next() * 0.08, 0.3 * rng.next(), 0.8 + 0.2 * rng.next())
                for entity in instance.renderers { world.modify(MeshRenderer.self, for: entity) { $0.tint = tint } }
                let rig = model.animationTargets(of: instance)
                world.add(Animator(targets: rig.targets, restPose: rig.restPose, clip: clips[k % 3], speed: 0.8 + rng.next() * 0.4,
                                   normalizedTime: rng.next()), to: root)
            }
        }

        // The pen: a 13 x 13 m floor walled in and split into four 5.25 m bays by double walls
        // (a body on a divider can't touch both sides), so the bodies settle into four piles:
        // four solver islands. 160 bodies in a lattice above each bay.
        let wall: Float = 1.75
        var walls = [(Vec3(8, wall, -6.5), Vec3(6.75, wall, 0.25)), (Vec3(8, wall, 6.5), Vec3(6.75, wall, 0.25)),
                     (Vec3(1.5, wall, 0), Vec3(0.25, wall, 6.25)), (Vec3(14.5, wall, 0), Vec3(0.25, wall, 6.25))]
        for d: Float in [-0.75, 0.75] {
            walls.append((Vec3(8 + d, wall, 0), Vec3(0.25, wall, 6.25)))
            walls.append((Vec3(8, wall, d), Vec3(6.25, wall, 0.25)))
        }
        for (center, half) in walls {
            _ = world.spawn(
                Transform(position: center, scale: half * 2),
                MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: Vec3(0.55, 0.55, 0.6)),
                Collider(.box(Vec3(repeating: 0.5)), friction: 0.6))
        }
        for layer in 0..<10 {
            for z in 0..<8 {
                for x in 0..<8 {
                    let k = (layer * 8 + z) * 8 + x
                    // Four per row in each bay (bays span 1.75...7 and 9...14.25 in x, ±1...±6.25 in z).
                    let bx: Float = x < 4 ? 2.5 : 9.75, bz: Float = z < 4 ? -5.5 : 1.75
                    let p = Vec3(bx + Float(x % 4) * 1.2 + rng.next() * 0.15, 1 + Float(layer) * 1.2,
                                 bz + Float(z % 4) * 1.2 + rng.next() * 0.15)
                    let rotation = Quat(angle: rng.next() * 3, axis: normalize(Vec3(rng.next() - 0.5, 1, rng.next() - 0.5)))
                    let sphere = k % 3 == 0
                    let size: Vec3 = sphere ? Vec3(repeating: 0.7) : Vec3(0.75, 0.45 + 0.3 * rng.next(), 0.6)
                    _ = world.spawn(
                        Transform(position: p, rotation: rotation, scale: size),
                        MeshRenderer(mesh: sphere ? .sphere : .cube, material: MaterialHandle(sphere ? "gloss" : "matte"),
                                     tint: hsv(Float(layer) / 10, 0.6, 0.95)),
                        Collider(sphere ? .sphere(radius: 0.5) : .box(Vec3(repeating: 0.5)), friction: 0.5),
                        RigidBody(.dynamic))
                }
            }
        }

        // A 50 x 50 field of posts around everything (many outside the view and the shadow cascades).
        for z in 0..<50 {
            for x in 0..<50 {
                let p = Vec3(Float(x) * 3 - 75, 0, Float(z) * 3 - 75)
                guard abs(p.x - 8) > 7 || abs(p.z) > 7, !(p.x > -33 && p.x < -3 && p.z > -15 && p.z < 13) else { continue }
                let height = 0.6 + rng.next() * 2.4
                _ = world.spawn(
                    Transform(position: Vec3(p.x, height / 2, p.z), scale: Vec3(0.4, height, 0.4)),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: hsv(0.1 + rng.next() * 0.1, 0.25, 0.75)))
            }
        }
        world.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0.75, pitch: 0.55, distance: 46, target: Vec3(-6, 0, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String {
        func average(_ values: [Double]) -> String {
            String(format: "%.2f ms", values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) * 1000)
        }
        let threads = JobSystem.shared.threadCount
        return "\(threads) job thread\(threads == 1 ? "" : "s"): world \(average(timings.update)), render prep \(average(timings.prep)); "
            + "\(physics.awakeBodyCount) awake, \(physics.contactCount) contacts, \(sceneRenderer.stats.list.opaque) drawn [R reset]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.3)
    }

    private func record(_ seconds: Double, into values: inout [Double]) {
        values.append(seconds)
        if values.count > 30 { values.removeFirst(values.count - 30) }
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        let start = DispatchTime.now().uptimeNanoseconds
        world.update(dt: Double(dt))
        record(Double(DispatchTime.now().uptimeNanoseconds - start) * 1e-9, into: &timings.update)
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
        record(sceneRenderer.stats.prepareTime, into: &timings.prep)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }
}
