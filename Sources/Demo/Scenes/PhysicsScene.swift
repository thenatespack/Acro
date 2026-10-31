import Engine
import Foundation

/// Spins a kinematic body about Y (its `Transform` is set every fixed step; the physics sync
/// turns that into velocity, so it pushes what it touches).
struct Spinner: Component, Codable, Sendable {
    var speed: Float
}

/// Rigid body physics (`PhysicsWorld` driven by `Collider` / `RigidBody` / `Joint` components):
/// a bowl-shaped triangle-mesh floor, two box towers and a pyramid, spheres and capsules
/// rolling down a ramp, convex-hull gems, a hinge chain swinging down from a gantry, a
/// kinematic paddle, a trigger zone that lights up while something is inside it, and a laser
/// sweeping across the scene (a raycast; all hits along it marked, the first one with its
/// normal).
///
/// Keys: **G** cycles the physics debug view (off, colliders + contacts + joints, plus
/// bounding boxes), **F** drops a handful of shapes, **B** shoots a ball from the camera,
/// **R** resets. Fixed timestep, so screenshots are deterministic.
final class PhysicsScene: DemoScene {
    static let name = "physics"
    static let summary = "rigid bodies: stacks, a pyramid, rolling spheres and capsules on a triangle mesh, hinge chain, trigger, raycasts"

    private var world = World()
    private var physics = PhysicsWorld()
    private let sceneRenderer: SceneRenderer
    private let debug = DebugDraw()
    private var cameraEntity = Entity.invalid
    private var zone = Entity.invalid
    private var inZone: [Entity] = []
    private var orbit: (eye: Vec3, target: Vec3)?
    private var debugMode = 0
    private var rng = SplitMix64(state: 11)
    private var spawned = 0
    private static let sky = Vec3(0.6, 0.7, 0.84)
    private static let terrain = PhysicsScene.terrainMesh()
    private static let gem: ColliderShape = .convexHull(points: (0..<6).map { k -> Vec3 in
        let a = Float(k) / 6 * 2 * .pi
        return Vec3(cosf(a) * 0.5, 0, sinf(a) * 0.5)
    } + [Vec3(0, 0.45, 0), Vec3(0, -0.6, 0)])

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        sceneRenderer.debugDraw = debug
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.36, 0.38, 0.36, 1), checker: true, roughness: 0.85), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.55), key: "matte")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), metallic: 0.9, roughness: 0.3), key: "metal")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.2), key: "gloss")
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(1, 1, 1, 1), roughness: 0.1, alphaMode: .blend, doubleSided: true), key: "glass")
        _ = try sceneRenderer.registerMesh(Self.terrain, key: "terrain")
        _ = try sceneRenderer.registerMesh(Self.capsuleMesh(radius: 0.5, halfHeight: 0.5), key: "capsule")
        _ = try sceneRenderer.registerMesh(Self.hullMesh(Self.gem.hullFaces), key: "gem")
        build()
    }

    /// (Re)creates the world and its physics.
    private func build() {
        world = World()
        physics = PhysicsWorld()
        world.addPhysics(physics)
        inZone = []
        spawned = 0
        rng = SplitMix64(state: 11)
        sceneRenderer.resetMotion()

        cameraEntity = world.spawn(
            Transform.looking(from: Vec3(18, 14, 22), at: Vec3(0, 1.5, 0)),
            Camera(fovY: .pi / 3.5, near: 0.3, far: 200, clearColor: Vec4(Self.sky, 1)))
        _ = world.spawn(SceneEnvironment(skyColor: Self.sky, groundColor: Vec3(0.3, 0.28, 0.25), fogColor: Self.sky, fogDensity: 0.004))
        _ = world.spawn(
            Transform(rotation: .lookRotation(forward: -Vec3(0.45, 0.8, 0.3))),
            DirectionalLight(intensity: 1.5, shadowExtent: 20, shadowCenter: Vec3(0, 1, 0)))

        // The floor: a triangle mesh, flat in the middle and rising into a bowl at the edges.
        let geometry = Self.terrain
        _ = world.spawn(
            Transform(), Name("Floor"),
            MeshRenderer(mesh: MeshHandle("terrain"), material: MaterialHandle("floor"), castsShadows: false),
            Collider(.triangleMesh(vertices: geometry.vertices.map(\.position), indices: geometry.indices), friction: 0.7))

        buildStacks()
        buildRamp()
        buildChain()
        buildZone()

        // Convex hull gems tumbling onto the floor, and a kinematic paddle sweeping the bowl.
        for k in 0..<3 {
            box("Gem", mesh: "gem", material: "gloss", at: Vec3(3.2 + Float(k) * 1.4, 0.9 + Float(k) * 0.5, -1.2),
                rotation: Quat(angle: 0.5 + Float(k), axis: normalize(Vec3(1, 0.3, Float(k)))), size: .one,
                tint: hsv(0.55 + Float(k) * 0.08, 0.6, 0.95), shape: Self.gem)
        }
        let paddle = box("Paddle", mesh: "cube", material: "metal", at: Vec3(7.5, 0.35, -5), size: Vec3(4, 0.5, 0.3),
                         tint: Vec3(0.85, 0.85, 0.9), motion: .kinematic)
        world.add(Spinner(speed: 0.8), to: paddle)
        world.addSystem("spinner", stage: .fixedUpdate, before: "physics") { world in
            let dt = world.time.delta
            world.queryMutating(Transform.self, Spinner.self) { _, transform, spinner in
                transform.rotation = (Quat(angle: spinner.speed * dt, axis: Vec3(0, 1, 0)) * transform.rotation).normalized
            }
        }
        world.propagateTransforms()
    }

    /// Two box towers and a pyramid on the flat middle of the floor.
    private func buildStacks() {
        for k in 0..<7 {
            box("Tower box", mesh: "cube", material: "matte", at: Vec3(-5, 0.45 + Float(k) * 0.9, -4),
                rotation: Quat(angle: Float(k % 2) * 0.3, axis: Vec3(0, 1, 0)), size: Vec3(repeating: 0.9),
                tint: hsv(0.02 + Float(k) * 0.03, 0.65, 0.95))
        }
        for k in 0..<5 {
            box("Column box", mesh: "cube", material: "matte", at: Vec3(-2.6, 0.35 + Float(k) * 0.7, -6),
                size: Vec3(1.2, 0.7, 0.7), tint: hsv(0.6 + Float(k) * 0.03, 0.5, 0.9))
        }
        let size: Float = 0.8
        for row in 0..<6 {
            for k in 0..<(6 - row) {
                let x = 1.5 + (Float(k) - Float(5 - row) / 2) * (size + 0.02)
                box("Pyramid box", mesh: "cube", material: "matte", at: Vec3(x, size / 2 + Float(row) * size, -5),
                    size: Vec3(repeating: size), tint: hsv(0.12 + Float(row) * 0.02, 0.6, 0.95))
            }
        }
    }

    /// A ramp on a pillar with spheres and capsules rolling down it toward the middle.
    private func buildRamp() {
        let angle: Float = 0.42
        let rotation = Quat(angle: angle, axis: Vec3(0, 0, 1))
        let center = Vec3(6.6, 1.5, 2.4)
        let half = Vec3(4.2, 0.15, 1.9)
        box("Ramp", mesh: "cube", material: "matte", at: center, rotation: rotation, size: half * 2, tint: Vec3(0.55, 0.6, 0.66),
            motion: .static, friction: 0.8)
        box("Pillar", mesh: "cube", material: "matte", at: Vec3(10.9, 1.8, 2.4), size: Vec3(0.6, 3.6, 3.8),
            tint: Vec3(0.5, 0.52, 0.55), motion: .static)
        let down = rotation * Vec3(-1, 0, 0), up = rotation * Vec3(0, 1, 0)
        func onRamp(_ s: Float, _ z: Float, lift: Float) -> Vec3 { center + rotation * Vec3(s, half.y, 0) + up * lift + Vec3(0, 0, z) }
        for (k, z) in [Float(-1.1), 0, 1.1].enumerated() {
            box("Ball", mesh: "sphere", material: "gloss", at: onRamp(3.2 - Float(k) * 0.6, z, lift: 0.4), size: Vec3(repeating: 0.8),
                tint: hsv(0.95 - Float(k) * 0.1, 0.7, 0.95), shape: .sphere(radius: 0.5), velocity: down * 3, friction: 0.6)
        }
        for (k, s) in [Float(1.4), 0.2].enumerated() {
            // Lying across the ramp (axis along z), so they roll.
            box("Capsule", mesh: "capsule", material: "gloss", at: onRamp(s, 0, lift: 0.3),
                rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), size: Vec3(repeating: 0.6),
                tint: hsv(0.3 + Float(k) * 0.1, 0.6, 0.9), shape: .capsule(radius: 0.5, halfHeight: 0.5), velocity: down * 2)
        }
    }

    /// A gantry with a chain of hinged links, released horizontally so it swings down.
    private func buildChain() {
        let anchor = Vec3(-9, 7.5, 2)
        for z: Float in [0.6, 3.4] {
            box("Post", mesh: "cube", material: "metal", at: Vec3(-9.8, 3.9, z), size: Vec3(0.3, 7.8, 0.3), tint: Vec3(0.6, 0.6, 0.65),
                motion: .static)
        }
        box("Beam", mesh: "cube", material: "metal", at: Vec3(-9.4, 7.85, 2), size: Vec3(1.2, 0.3, 3.4), tint: Vec3(0.6, 0.6, 0.65),
            motion: .static)
        var previous: Entity?
        let length: Float = 0.8
        for k in 0..<7 {
            let x = anchor.x + length * (Float(k) + 0.5)
            let link = box("Link", mesh: "cube", material: "metal", at: Vec3(x, anchor.y, anchor.z), size: Vec3(length - 0.06, 0.18, 0.3),
                           tint: hsv(0.08, 0.5, 0.85), density: 2000)
            // Hinged about z at its left end, to the previous link (or the world).
            world.add(Joint(.hinge, connectedTo: previous, anchor: Vec3(-length / 2, 0, 0), axis: Vec3(0, 0, 1)), to: link)
            previous = link
        }
        // A weight at the end.
        let weight = box("Weight", mesh: "sphere", material: "metal", at: anchor + Vec3(length * 7 + 0.35, 0, 0),
                         size: Vec3(repeating: 0.7), tint: Vec3(0.9, 0.75, 0.4), shape: .sphere(radius: 0.5), density: 3000)
        world.add(Joint(.ball, connectedTo: previous, anchor: Vec3(-0.35, 0, 0)), to: weight)
    }

    /// A glass trigger zone, and a ball dropped into it.
    private func buildZone() {
        let center = Vec3(1.2, 0.8, 2.6)
        zone = box("Trigger zone", mesh: "cube", material: "glass", at: center, size: Vec3(2.6, 1.6, 3.2), tint: Vec3(0.4, 0.7, 1),
                   motion: .static, trigger: true)
        world.modify(MeshRenderer.self, for: zone) {
            $0.opacity = 0.3
            $0.castsShadows = false
        }
        box("Dropped ball", mesh: "sphere", material: "gloss", at: center + Vec3(0.3, 4, -0.4), size: Vec3(repeating: 0.7),
            tint: Vec3(0.95, 0.95, 0.95), shape: .sphere(radius: 0.5))
    }

    /// An entity with a mesh and a collider (a box of the mesh's unit size by default),
    /// dynamic unless `motion` says otherwise.
    @discardableResult
    private func box(_ name: String, mesh: String, material: String, at position: Vec3, rotation: Quat = .identity, size: Vec3,
                     tint: Vec3, shape: ColliderShape = .box(Vec3(repeating: 0.5)), motion: MotionType = .dynamic,
                     velocity: Vec3 = .zero, friction: Float = 0.5, density: Float = 1000, trigger: Bool = false) -> Entity {
        let entity = world.spawn(
            Transform(position: position, rotation: rotation, scale: size), Name(name),
            MeshRenderer(mesh: MeshHandle(mesh), material: MaterialHandle(material), tint: tint),
            Collider(shape, friction: friction, density: density, isTrigger: trigger))
        if motion != .static { world.add(RigidBody(motion, linearVelocity: velocity), to: entity) }
        return entity
    }

    var initialView: OrbitView { OrbitView(yaw: 0.62, pitch: 0.42, distance: 27, target: Vec3(0, 1.8, -0.5)) }
    var lighting: Lighting { Lighting(fogColor: Self.sky) }
    var status: String {
        let modes = ["off", "colliders", "colliders + bounds"]
        return "\(physics.bodyCount) bodies, \(physics.awakeBodyCount) awake, \(physics.touchingContactCount) contacts, "
            + "zone \(inZone.isEmpty ? "empty" : "\(inZone.count) inside"), debug \(modes[debugMode]) [G], drop [F], shoot [B], reset [R]"
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target, near: 0.3)
    }

    func update(input: Input, dt: Float, time: Float) {
        if input.wasPressed(.r) { build() }
        if input.wasPressed(.g) { debugMode = (debugMode + 1) % 3 }
        if input.wasPressed(.f) { drop() }
        if input.wasPressed(.b), let orbit { shoot(from: orbit.eye, toward: orbit.target) }
        world.update(dt: Double(dt))

        // Trigger events: the zone glows while anything is inside.
        for event in physics.events where event.entityA == zone {
            guard let other = event.entityB else { continue }
            if event.kind == .triggerEntered { inZone.append(other) }
            if event.kind == .triggerExited { inZone.removeAll { $0 == other } }
        }
        world.modify(MeshRenderer.self, for: zone) {
            $0.tint = inZone.isEmpty ? Vec3(0.4, 0.7, 1) : Vec3(1, 0.35, 0.15)
            $0.opacity = inZone.isEmpty ? 0.3 : 0.5
        }

        debug.removeAll()
        drawLaser(time: time)
        switch debugMode {
        case 1: physics.drawDebug(into: debug, options: [.colliders, .contacts, .joints])
        case 2: physics.drawDebug(into: debug, options: [.colliders, .contacts, .joints, .bounds])
        default: break
        }
    }

    /// A laser sweeping across the towers: every hit along the ray is marked (raycastAll), the
    /// first stops the beam and shows its normal.
    private func drawLaser(time: Float) {
        let origin = Vec3(11.5, 1.1, -3)
        let angle = sinf(time * 0.7 - 0.7) * 0.1
        let direction = Quat(angle: angle, axis: Vec3(0, 1, 0)) * normalize(Vec3(1.5, 1.2, -5) - origin)
        let ray = Ray(origin: origin, direction: direction)
        let red = Vec4(1, 0.15, 0.1, 1)
        debug.sphere(center: origin, radius: 0.15, color: red, segments: 12)
        guard let hit = physics.raycast(ray, maxDistance: 40) else {
            debug.line(origin, ray.point(at: 40), color: red, style: DebugDraw.Style(width: 3))
            return
        }
        debug.line(origin, hit.point, color: red, style: DebugDraw.Style(width: 3))
        debug.arrow(from: hit.point, to: hit.point + hit.normal * 1.2, color: Vec4(1, 0.9, 0.2, 1), style: DebugDraw.Style(width: 2.5))
        debug.disc(center: hit.point + hit.normal * 0.01, normal: hit.normal, radius: 0.18, color: red)
        for other in physics.raycastAll(ray, maxDistance: 40).dropFirst() {
            debug.circle(center: other.point, normal: other.normal, radius: 0.15, color: Vec4(1, 0.5, 0.4, 0.8),
                         segments: 12, style: DebugDraw.Style(width: 1.5, depth: .onTop))
        }
    }

    /// Six random shapes dropped over the middle.
    private func drop() {
        for _ in 0..<6 {
            let p = Vec3(rng.next() * 6 - 3, 6 + rng.next() * 3, rng.next() * 4 - 1)
            let rotation = Quat(angle: rng.next() * 6, axis: normalize(Vec3(rng.next() - 0.5, rng.next() - 0.5, rng.next() - 0.5) + Vec3(0, 0.01, 0)))
            let tint = hsv(rng.next(), 0.6, 0.95)
            switch spawned % 4 {
            case 0: box("Dropped box", mesh: "cube", material: "matte", at: p, rotation: rotation, size: Vec3(repeating: 0.7), tint: tint)
            case 1: box("Dropped ball", mesh: "sphere", material: "gloss", at: p, size: Vec3(repeating: 0.7), tint: tint, shape: .sphere(radius: 0.5))
            case 2: box("Dropped capsule", mesh: "capsule", material: "gloss", at: p, rotation: rotation, size: Vec3(repeating: 0.5), tint: tint,
                        shape: .capsule(radius: 0.5, halfHeight: 0.5))
            default: box("Dropped gem", mesh: "gem", material: "gloss", at: p, rotation: rotation, size: .one, tint: tint, shape: Self.gem)
            }
            spawned += 1
        }
    }

    private func shoot(from eye: Vec3, toward target: Vec3) {
        let direction = normalize(target - eye)
        box("Shot", mesh: "sphere", material: "metal", at: eye + direction * 2, size: Vec3(repeating: 0.6), tint: Vec3(0.9, 0.9, 0.95),
            shape: .sphere(radius: 0.5), velocity: direction * 30, density: 4000)
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

    // MARK: - Meshes

    /// Height of the floor: flat in the middle, rising quadratically toward the edges.
    private static func height(_ x: Float, _ z: Float) -> Float {
        let dx = max(abs(x) - 11, 0), dz = max(abs(z) - 8, 0)
        return 0.07 * dx * dx + 0.09 * dz * dz
    }

    /// A 36 x 28 m grid of 1 m cells following `height`, with smooth normals.
    private static func terrainMesh() -> MeshGeometry {
        let nx = 36, nz = 28
        var geometry = MeshGeometry(vertices: [], indices: [])
        for j in 0...nz {
            for i in 0...nx {
                let x = Float(i) - Float(nx) / 2, z = Float(j) - Float(nz) / 2
                let e: Float = 0.01
                let normal = normalize(Vec3(height(x - e, z) - height(x + e, z), 2 * e, height(x, z - e) - height(x, z + e)))
                geometry.vertices.append(MeshVertex(position: Vec3(x, height(x, z), z), normal: normal, uv: Vec2(x, z) * 0.25))
            }
        }
        let stride = UInt32(nx + 1)
        for j in 0..<UInt32(nz) {
            for i in 0..<UInt32(nx) {
                let a = j * stride + i, b = a + 1, c = a + stride, d = c + 1
                // Counter-clockwise seen from above (+y): a, c, b and b, c, d (z grows toward c).
                geometry.indices += [a, c, b, b, c, d]
            }
        }
        return geometry
    }

    /// A capsule along Y: hemispheres of `radius` at ±`halfHeight` joined by a cylinder.
    static func capsuleMesh(radius: Float, halfHeight: Float, segments: Int = 24, rings: Int = 12) -> MeshGeometry {
        var geometry = MeshGeometry(vertices: [], indices: [])
        // Rings from the top pole down; the equator twice (top and bottom of the cylinder).
        var latitudes: [(theta: Float, offset: Float)] = []
        for r in 0...(rings / 2) { latitudes.append((Float(r) / Float(rings) * .pi, halfHeight)) }
        for r in (rings / 2)...rings { latitudes.append((Float(r) / Float(rings) * .pi, -halfHeight)) }
        for (ring, latitude) in latitudes.enumerated() {
            for segment in 0...segments {
                let phi = Float(segment) / Float(segments) * 2 * .pi
                let n = Vec3(sinf(latitude.theta) * sinf(phi), cosf(latitude.theta), sinf(latitude.theta) * cosf(phi))
                geometry.vertices.append(MeshVertex(position: n * radius + Vec3(0, latitude.offset, 0), normal: n,
                                                    uv: Vec2(Float(segment) / Float(segments), Float(ring) / Float(latitudes.count - 1))))
            }
        }
        let stride = UInt32(segments + 1)
        let last = UInt32(latitudes.count - 1)
        for ring in 0..<last {
            for segment in 0..<UInt32(segments) {
                let a = ring * stride + segment, b = a + 1, c = a + stride, d = c + 1
                if ring != 0 { geometry.indices += [a, c, b] }
                if ring != last - 1 { geometry.indices += [b, c, d] }
            }
        }
        return geometry
    }

    /// Flat-shaded triangles fanned from each convex face.
    private static func hullMesh(_ faces: [[Vec3]]) -> MeshGeometry {
        var geometry = MeshGeometry(vertices: [], indices: [])
        for face in faces where face.count >= 3 {
            let normal = normalize(cross(face[1] - face[0], face[2] - face[0]))
            let base = UInt32(geometry.vertices.count)
            for p in face { geometry.vertices.append(MeshVertex(position: p, normal: normal, uv: Vec2(p.x, p.z))) }
            for k in 1..<UInt32(face.count - 1) { geometry.indices += [base, base + k, base + k + 1] }
        }
        return geometry
    }
}
