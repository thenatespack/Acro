import Engine
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif

/// Fur and hair from `.groom` files (Groom Builder): three grooms imported by an `AssetDatabase`
/// in a temporary project and grown at run time by `GroomRenderer`s:
/// - a shaggy quadruped (Character Builder skeleton and walk clip): shell fur on its skinned body
///   and legs, following the animation, with a spring per bone trailing the motion;
/// - a humanoid with styled hair cards on a scalp riding its head bone: a side part, hair lying on
///   the scalp and falling past the ears to the shoulders, a flat inner layer, tapered clumps, a few
///   flyaways, a soft hairline, cut away from the face by a `cut` stroke and kept out of the head,
///   neck and shoulders by colliders (`FUR_HAIR=<preset>` grows a hairstyle preset instead);
/// - three mossy rocks in the wind: shell moss (bare underneath, a `cut` stroke), drawn as one
///   instanced batch for every shell of every rock.
///
/// Environment: `FUR_VIEW=hair|hairfront|hairside|hairback|creature|moss` shows a close-up, `FUR_HAIR=bob` (any hairstyle
/// preset) changes the hair, `FUR_TIMING=1` prints how long the hair's guides and cards take to build, `FUR_OFF=1` hides every
/// groom (the before picture for GPU timing), `FUR_SUN=back` backlights,
/// `FUR_WIND=0` stills the air, `FUR_SHAKE=1` turns the humanoid sharply side to side every few
/// seconds (holding still between, so its hair swings and settles), `FUR_SIM=0` bends the hair
/// with the old springs instead of simulating it, `FUR_SYNC=1` builds the fur meshes on the
/// render thread, `FUR_PX_PER_SHELL=<n>` sets the shell fur's pixels per shell. With `FUR_TIMING=1` the scene doesn't wait for assets and prints the first
/// frames' render prep time and the hair simulation's cost. The title lists draws and items.
final class FurScene: DemoScene {
    static let name = "fur"
    static let summary = "Groom Builder fur and hair: shell fur on an animated creature, hair cards, moss in wind"

    private let world = World()
    private let sceneRenderer: SceneRenderer
    private let library = AnimationLibrary()
    private let database: AssetDatabase
    private let root: URL
    private var cameraEntity = Entity.invalid
    private var orbit: (eye: Vec3, target: Vec3)?
    private static let sky = Vec3(0.62, 0.7, 0.82)
    /// `FUR_SHAKE=1`: the humanoid's root, where it stands and its yaw, and the clock.
    private var shake: (root: Entity, position: Vec3, yaw: Float)?
    private var shakeTime: Float = 0
    private let timing = ProcessInfo.processInfo.environment["FUR_TIMING"] == "1"
    private var frameIndex = 0
    private var simulationTotal: Double = 0
    private var slowestPrep: (ms: Double, frame: Int) = (0, 0)

    init(renderer: Renderer) throws {
        let env = ProcessInfo.processInfo.environment
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.simulatesHair = env["FUR_SIM"] != "0"
        sceneRenderer.buildsFurInBackground = env["FUR_SYNC"] != "1"
        if env["FUR_TIMING"] == "1" { sceneRenderer.blocksOnAssetLoading = false }
        if let pixels = env["FUR_PX_PER_SHELL"].flatMap(Float.init) { sceneRenderer.furPixelsPerShell = pixels }
        SkeletalAnimation.registerComponents()

        // The grooms, imported like a project's.
        root = FileManager.default.temporaryDirectory.appendingPathComponent("FurScene-\(UUID().uuidString)", isDirectory: true)
        let project = try Project.create(at: root, name: "Fur")
        database = AssetDatabase(project: project)
        var shaggy = GroomBuild.preset("shaggyFur")!
        shaggy.rootColor = Vec3(0.2, 0.13, 0.09)
        shaggy.tipColor = Vec3(0.78, 0.6, 0.42)
        shaggy.length = 0.06
        var hair = env["FUR_HAIR"].flatMap(GroomBuild.preset) ?? Self.demoHair()
        // The scalp's edge is the hairline; out of the head, neck and shoulders (the scalp's space).
        hair.colliders = Self.hairColliders
        var moss = GroomBuild.preset("moss")!
        moss.length = 0.03
        // Moss on the top and the sides, bare stone underneath.
        moss.cut = [GroomCut(center: Vec3(0, -0.45, 0.1), radius: 0.6, length: 0)]
        let shaggyID = try database.createGroom(shaggy, at: "Grooms/Shaggy.groom")
        let hairID = try database.createGroom(hair, at: "Grooms/Hair.groom")
        let mossID = try database.createGroom(moss, at: "Grooms/Moss.groom")
        database.refreshAsync()
        database.waitForAll()
        sceneRenderer.assets = database
        let off = env["FUR_OFF"] == "1"

        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.3, 0.34, 0.26, 1), roughness: 0.95), key: "fur.ground")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.42, 0.4, 0.37, 1), roughness: 0.9), key: "fur.rock")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.25, 0.15, 0.08, 1), roughness: 0.8), key: "fur.scalp")
        _ = try sceneRenderer.registerMesh(Self.rockMesh(), key: "fur.rock")
        _ = try sceneRenderer.registerMesh(Self.scalpMesh(), key: "fur.scalp")
        if env["FUR_TIMING"] == "1" {
            let start = Date()
            let fur = MaterialFur(groom: hair)
            let guides = GroomGeometry.guides(Self.scalpMesh(), fur: fur).guides
            let grown = Date()
            let triangles = hair.cardLevels.reduce(0) { $0 + (GroomGeometry.cards(guides: guides, fur: fur, fraction: $1, skinned: false)?.indices.count ?? 0) / 3 }
            let leaders = guides.indices.filter { guides[$0].clump == $0 || guides[$0].clump < 0 && guides[$0].layer != .inner }.count
            print(String(format: "Fur: hair guides %.1f ms (%d guides, %d simulated), cards %.1f ms (%d triangles over %d levels)",
                         grown.timeIntervalSince(start) * 1000, guides.count, leaders, Date().timeIntervalSince(grown) * 1000, triangles,
                         hair.cardLevels.count))
        }

        cameraEntity = world.spawn(Transform.looking(from: Vec3(0, 1.4, 4.2), at: Vec3(0, 0.6, 0)),
                                   Camera(fovY: .pi / 3.6, near: 0.05, far: 100, clearColor: Vec4(Self.sky, 1)))
        var environment = SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.24), ambientIntensity: 0.55,
                                           fogColor: Self.sky, fogDensity: 0.01)
        environment.wind = env["FUR_WIND"] == "0" ? .calm : Wind(direction: Vec3(1, 0, 0.3), strength: 1, gustiness: 0.6)
        world.spawn(environment)
        // `FUR_SUN=back`: the sun low behind the fur (seen from the close-ups), for the backlit rim.
        let toSun = env["FUR_SUN"] == "back" ? Vec3(-0.45, 0.35, -0.8) : Vec3(0.5, 0.85, 0.55)
        world.spawn(Transform(rotation: .lookRotation(forward: -normalize(toSun))),
                    DirectionalLight(color: Vec3(1, 0.96, 0.9), intensity: 2.4, shadowExtent: 5, shadowCenter: Vec3(0, 0.5, 0)))
        world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(30, 1, 30)), Name("Ground"),
                    MeshRenderer(mesh: .cube, material: MaterialHandle("fur.ground"), castsShadows: false))

        // The creature: a quadruped, shaggy on its body and legs, walking in place.
        let quadruped = CharacterRig(template: .quadruped, proportions: CharacterProportions(height: 1.1, width: 1.15))
        let walk = CharacterClips.clip("walk", rig: quadruped).map { library.register($0, key: "fur.walk") }
        spawnCharacter(quadruped, prefix: "fur.quadruped", at: Vec3(-1.25, 0, 0), yaw: 0.9, clip: walk,
                       grooms: off ? [:] : [.body: GroomRenderer.material(ofGroom: shaggyID), .legs: GroomRenderer.material(ofGroom: shaggyID)])

        // The humanoid with card hair on a scalp riding its head.
        let humanoid = CharacterRig(template: .humanoid)
        let idle = CharacterClips.clip("idle", rig: humanoid).map { library.register($0, key: "fur.idle") }
        let bones = spawnCharacter(humanoid, prefix: "fur.humanoid", at: Vec3(0.35, 0, -0.2), yaw: -0.25, clip: idle, grooms: [:])
        if env["FUR_SHAKE"] == "1", let first = bones.first, let root = world.parent(of: first) {
            shake = (root, Vec3(0.35, 0, -0.2), -0.25)
        }
        if let head = humanoid.index(of: "head") {
            let scalp = world.spawn(Transform(position: Vec3(0, 0.12, 0.01)), Name("Scalp"),
                                    MeshRenderer(mesh: MeshHandle("fur.scalp"), material: MaterialHandle("fur.scalp")))
            if !off { world.add(GroomRenderer(groom: GroomRenderer.material(ofGroom: hairID)), to: scalp) }
            world.setParent(scalp, to: bones[head])
        }

        // Mossy rocks: one mesh and groom, so each shell set is one instanced draw.
        for (k, place) in [(Vec3(1.45, 0.05, 0.25), Float(0.55)), (Vec3(1.95, 0.0, -0.6), 0.35), (Vec3(0.95, 0.0, 0.85), 0.25)].enumerated() {
            let rock = world.spawn(Transform(position: place.0, rotation: Quat(angle: Float(k) * 1.9, axis: Vec3(0, 1, 0)),
                                             scale: Vec3(place.1, place.1 * 0.75, place.1)),
                                   Name("Rock \(k + 1)"), MeshRenderer(mesh: MeshHandle("fur.rock"), material: MaterialHandle("fur.rock")))
            if !off { world.add(GroomRenderer(groom: GroomRenderer.material(ofGroom: mossID)), to: rock) }
        }
        world.addAnimationSystem(library)
        world.propagateTransforms()
    }

    deinit { try? FileManager.default.removeItem(at: root) }

    /// A character from `rig`: root, bones, skinned body meshes (with fur on `grooms`' regions) and an Animator playing `clip`.
    @discardableResult
    private func spawnCharacter(_ rig: CharacterRig, prefix: String, at position: Vec3, yaw: Float, clip: AnimationClipHandle?,
                                grooms: [CharacterRegion: MaterialHandle]) -> [Entity] {
        let root = world.spawn(Transform(position: position, rotation: Quat(angle: yaw, axis: Vec3(0, 1, 0))), Name(prefix))
        var bones: [Entity] = []
        for bone in rig.bones {
            let e = world.spawn(Transform(position: bone.offset), Name(bone.name))
            world.setParent(e, to: bone.parent.map { bones[$0] } ?? root)
            bones.append(e)
        }
        for (region, geometry) in rig.bodyMeshes(segments: 16, smooth: true) {
            let key = "\(prefix).\(region.rawValue)"
            _ = try? sceneRenderer.registerMesh(geometry, key: key)
            let c = MeshBuildColor.linear(fromSRGB: rig.template.defaultColor(region))
            _ = try? sceneRenderer.registerMaterial(Material(baseColor: Vec4(c.x, c.y, c.z, 1), roughness: region == .eyes ? 0.2 : 0.75), key: key)
            let body = world.spawn(Transform(), Name("Body \(region.rawValue)"),
                                   MeshRenderer(mesh: MeshHandle(key), material: MaterialHandle(key)),
                                   Skin(joints: bones, inverseBindMatrices: rig.inverseBindMatrices))
            if let groom = grooms[region] { world.add(GroomRenderer(groom: groom), to: body) }
            world.setParent(body, to: root)
        }
        if let clip { world.add(Animator(targets: bones, restPose: rig.restPose, clip: clip), to: root) }
        return bones
    }

    var initialView: OrbitView {
        // `FUR_VIEW=hair|creature|moss`: close-ups.
        switch ProcessInfo.processInfo.environment["FUR_VIEW"] {
        case "hair": OrbitView(yaw: 0.35, pitch: 0.45, distance: 0.75, target: Vec3(0.35, 1.5, -0.2))
        // The humanoid faces yaw -0.25.
        case "hairfront": OrbitView(yaw: -0.25, pitch: 0.08, distance: 0.7, target: Vec3(0.35, 1.5, -0.2))
        case "hairside": OrbitView(yaw: -0.25 + .pi / 2, pitch: 0.08, distance: 0.7, target: Vec3(0.35, 1.5, -0.2))
        case "hairback": OrbitView(yaw: -0.25 + .pi, pitch: 0.25, distance: 0.7, target: Vec3(0.35, 1.5, -0.2))
        case "creature": OrbitView(yaw: 0.3, pitch: 0.2, distance: 1.6, target: Vec3(-1.25, 0.6, 0))
        case "moss": OrbitView(yaw: 0.2, pitch: 0.35, distance: 1.3, target: Vec3(1.45, 0.2, 0.25))
        default: OrbitView(yaw: 0.0, pitch: 0.22, distance: 4.4, target: Vec3(0.25, 0.55, 0))
        }
    }
    var lighting: Lighting { Lighting(fogColor: Self.sky, shadowExtent: 5) }
    var status: String {
        let s = sceneRenderer.stats.list
        return "\(s.items) items, \(s.drawCalls) draws"
    }

    /// The demo app keeps the orbit at least 2 m out; the hair close-ups scale it in (their
    /// `OrbitView` distance is the one they get).
    private let zoom: Float = {
        switch ProcessInfo.processInfo.environment["FUR_VIEW"] {
        case "hair": 0.75 / 2
        case "hairfront", "hairside", "hairback": 0.7 / 2
        default: 1
        }
    }()

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        let orbitEye = target + (orbitEye - target) * zoom
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.05)
    }

    func update(input: Input, dt: Float, time: Float) {
        if let shake {
            shakeTime += dt
            let (turn, step) = Self.shakePose(shakeTime)
            world.add(Transform(position: shake.position + Vec3(step, 0, 0), rotation: Quat(angle: shake.yaw + turn, axis: Vec3(0, 1, 0))),
                      to: shake.root)
        }
        world.update(dt: Double(dt))
    }

    /// `FUR_SHAKE`: still for a second, then every 3 s a sharp turn of 1.1 rad (and a 10 cm step)
    /// in 0.3 s, held for 1.2 s, and back the same way.
    static func shakePose(_ t: Float) -> (turn: Float, step: Float) {
        guard t > 1 else { return (0, 0) }
        let u = (t - 1).truncatingRemainder(dividingBy: 3)
        func ease(_ x: Float) -> Float {
            let c = min(max(x, 0), 1)
            return c * c * (3 - 2 * c)
        }
        let k = u < 1.5 ? ease(u / 0.3) : 1 - ease((u - 1.5) / 0.3)
        return (1.1 * k, 0.1 * k)
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit {
            world.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity)
            world.propagateTransforms()
        }
        sceneRenderer.renderOffscreen(world: world, engine: engine, frame: frame)
        if timing {
            frameIndex += 1
            simulationTotal += sceneRenderer.hairSimulationSeconds
            if sceneRenderer.stats.prepareTime * 1000 > slowestPrep.ms { slowestPrep = (sceneRenderer.stats.prepareTime * 1000, frameIndex) }
            if frameIndex == 200 { print(String(format: "Fur: slowest render prep %.2f ms (frame %d)", slowestPrep.ms, slowestPrep.frame)) }
            if frameIndex <= 6 || sceneRenderer.furBuildSeconds > 0 && frameIndex % 100 == 0 {
                print(String(format: "Fur: frame %d render prep %.2f ms (hair simulation %.3f ms, last fur build %.1f ms%@)", frameIndex,
                             sceneRenderer.stats.prepareTime * 1000, sceneRenderer.hairSimulationSeconds * 1000,
                             sceneRenderer.furBuildSeconds * 1000, frameIndex % 100 == 0
                                 ? String(format: ", simulation mean %.3f ms", simulationTotal / Double(frameIndex) * 1000) : ""))
            }
        }
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }

    /// A lumpy rock: a sphere pushed in and out by smooth noise, flatter underneath.
    static func rockMesh() -> MeshGeometry {
        var geometry = MeshGeometry.sphere(radius: 0.5, segments: 48, rings: 24)
        func bump(_ p: Vec3) -> Float {
            0.09 * sinf(p.x * 7.1 + 1.3) * sinf(p.y * 6.3 + 0.4) * sinf(p.z * 5.7 + 2.1) + 0.05 * sinf(p.x * 13 + p.z * 11 + p.y * 3)
        }
        for i in geometry.vertices.indices {
            let p = geometry.vertices[i].position
            let n = normalize(p)
            var q = n * (0.5 + bump(n))
            if q.y < -0.15 { q.y = -0.15 + (q.y + 0.15) * 0.3 }
            geometry.vertices[i].position = q
        }
        // Smooth normals from the moved positions.
        var normals = [Vec3](repeating: .zero, count: geometry.vertices.count)
        for t in stride(from: 0, to: geometry.indices.count, by: 3) {
            let a = Int(geometry.indices[t]), b = Int(geometry.indices[t + 1]), c = Int(geometry.indices[t + 2])
            let pa = geometry.vertices[a].position, pb = geometry.vertices[b].position, pc = geometry.vertices[c].position
            let n = cross(pb - pa, pc - pa)
            normals[a] += n; normals[b] += n; normals[c] += n
        }
        // The sphere's seam has duplicate vertices: share normals between vertices at the same spot.
        var byPosition: [SIMD3<Int32>: Vec3] = [:]
        func cell(_ p: Vec3) -> SIMD3<Int32> { SIMD3(Int32((p.x * 1e4).rounded()), Int32((p.y * 1e4).rounded()), Int32((p.z * 1e4).rounded())) }
        for (i, v) in geometry.vertices.enumerated() { byPosition[cell(v.position), default: .zero] += normals[i] }
        for i in geometry.vertices.indices {
            let n = byPosition[cell(geometry.vertices[i].position)] ?? Vec3(0, 1, 0)
            geometry.vertices[i].normal = length(n) > 0 ? normalize(n) : Vec3(0, 1, 0)
            geometry.vertices[i].tangent = .zero
        }
        return geometry
    }

    /// The demo's hairdo: shoulder-length hair with a side part, lying on the scalp before it
    /// falls, longer at the back than around the face, a flat inner layer, tapered clumps and a
    /// few flyaways.
    static func demoHair() -> GroomBuild {
        var hair = GroomBuild.preset("straightHair")!
        hair.length = 0.26
        hair.density = 2.5
        hair.part = GroomPart(style: .side, offset: 0.4)
        hair.lengthProfile = GroomLengthProfile(front: 0.7, back: 1.1, top: 1, sides: 0.9)
        hair.wave = 0.15
        return hair
    }

    /// The humanoid's head, neck and shoulders in the scalp's space (the scalp sits 0.12 above the head bone).
    static let hairColliders = [
        GroomCollider(center: Vec3(0, -0.005, 0.005), radii: Vec3(0.108, 0.13, 0.12)),
        GroomCollider(center: Vec3(0, -0.12, -0.01), radius: 0.055, end: Vec3(0, -0.3, -0.01)),
        GroomCollider(center: Vec3(-0.2, -0.33, 0), radius: 0.08, end: Vec3(0.2, -0.33, 0)),
    ]

    /// The humanoid's scalp: an ellipsoid cap around its head (radii 0.116, 0.136, 0.126, in the
    /// head bone's space around the head's center), its rings bent so its edge is a smooth
    /// hairline: above the forehead, past the temples at the sides, low at the nape.
    static func scalpMesh() -> MeshGeometry {
        let radii = Vec3(0.12, 0.14, 0.13)
        let rings = 20, segments = 36
        var vertices: [MeshVertex] = []
        var indices: [UInt32] = []
        for r in 0...rings {
            for s in 0...segments {
                let phi = Float(s) / Float(segments) * 2 * .pi
                // The hairline: high over the forehead (+Z), past the temples at the sides, low at the nape.
                let limit = 0.95 + 1.0 * (1 - cosf(phi)) / 2
                let theta = Float(r) / Float(rings) * limit  // polar angle from the top, radians
                let d = Vec3(sinf(theta) * sinf(phi), cosf(theta), sinf(theta) * cosf(phi))
                vertices.append(MeshVertex(position: d * radii, normal: normalize(d / radii), uv: Vec2(Float(s) / Float(segments), Float(r) / Float(rings))))
            }
        }
        for r in 0..<rings {
            for s in 0..<segments {
                let a = UInt32(r * (segments + 1) + s), b = a + 1, c = a + UInt32(segments + 1), d = c + 1
                indices += [a, c, b, b, c, d]
            }
        }
        return MeshGeometry(vertices: vertices, indices: indices)
    }
}
