import Engine
import Foundation

/// Client-side prediction (Sources/Engine/Net, card 662): one server and two clients in one
/// process over a simulated link (100 ms one way, 20 ms jitter, 3% loss each way). Each client
/// moves its own capsule character immediately from its inputs (predicted with the same
/// `CharacterController` step the server runs), sends the inputs redundantly, and reconciles on
/// every snapshot; the other player is shown interpolated, 100 ms behind the newest snapshot.
/// Left: player 1's screen; right: player 2's. Faint capsules are where the server has both
/// characters now: the own character runs ahead of its ghost (the inputs are still on their
/// way), the other one trails it. Both players follow scripted routes (stairs, a landing, jumps);
/// WASD / F take over player 1. Deterministic: fixed steps, seeded link, scripted inputs, and
/// the scene starts four seconds into the session.
final class NetCharacterScene: DemoScene {
    static let name = "netcharacter"
    static let summary = "networking: two players with client-side prediction and reconciliation over a laggy, lossy loopback link"

    private static let dt: Float = 1.0 / 60
    private static let side: Float = 7
    private static let fogColor = Vec3(0.62, 0.68, 0.76)
    /// Boxes of the level (min, max), the same on the server and both clients.
    private static let level: [(Vec3, Vec3)] = {
        var boxes: [(Vec3, Vec3)] = [(Vec3(-6, -1, -6), Vec3(6, 0, 6))]
        for k in 0..<4 { boxes.append((Vec3(-1.5 + Float(k) * 0.5, 0, -1.5), Vec3(-1 + Float(k) * 0.5, 0.25 * Float(k + 1), 1.5))) }
        boxes.append((Vec3(0.5, 0, -1.5), Vec3(3.5, 1.25, 1.5)))   // landing
        boxes.append((Vec3(-5, 0, 3.6), Vec3(1, 1.4, 4.1)))        // wall
        boxes.append((Vec3(4, 0, -4.6), Vec3(5, 2, -3.6)))         // pillar
        return boxes
    }()
    /// Routes (waypoints in the level's xz) and jump periods (fixed steps), per player.
    private static let routes: [[Vec2]] = [
        [Vec2(-4.5, 0), Vec2(2.5, 0), Vec2(2.5, 2.8), Vec2(-4, 2.6)],
        [Vec2(4.5, -2.6), Vec2(-2.8, -2.6), Vec2(-2.8, 2.4), Vec2(4.5, 2.4)],
    ]
    private static let jumpPeriods = [113, 89]

    private let display = World()
    private let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.1, jitter: 0.02, loss: 0.03), seed: 662)
    private let server: NetServer
    private let serverPhysics = PhysicsWorld()
    private var characters: [NetClientID: Entity] = [:]
    private var clients: [NetClient] = []
    private var predictions: [NetCharacterPrediction?] = [nil, nil]
    private var clientPhysics: [PhysicsWorld] = []
    private var waypoint = [0, 0]
    private var step = 0
    private var time = 0.0
    private var accumulator: Float = 0
    private var userActive = false
    private var keysHeld = false
    private let actions = InputActions(bindings: CharacterScene.defaultBindings)
    private var pendingJump = false
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private var mirrors: [String: Entity] = [:]
    private var yaws: [String: Float] = [:]

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), specular: 0.2), key: "matte")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), specular: 0.6, shininess: 64), key: "glossy")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), alphaMode: .blend), key: "ghost")
        _ = try sceneRenderer.registerMesh(PhysicsScene.capsuleMesh(radius: 0.3, halfHeight: 0.6), key: "hero")

        cameraEntity = display.spawn(
            Transform.looking(from: Vec3(0, 16, 22), at: Vec3(0, 1, 0)),
            Camera(fovY: .pi / 3.5, near: 0.5, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = display.spawn(SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.004))
        _ = display.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.45))), DirectionalLight(intensity: 1.3, shadowExtent: 22))
        for (panel, tint) in [(-Self.side, Vec3(1, 0.88, 0.8)), (Self.side, Vec3(0.82, 0.9, 1))] {
            for (k, (lo, hi)) in Self.level.enumerated() {
                let center = (lo + hi) * 0.5 + Vec3(panel, 0, 0)
                _ = display.spawn(Transform(position: center, scale: hi - lo),
                                  MeshRenderer(mesh: .cube, material: MaterialHandle(k == 0 ? "floor" : "matte"),
                                               tint: k == 0 ? tint : hsv(0.08 + Float(k) * 0.04, 0.35, 0.9), castsShadows: k != 0))
            }
        }

        let serverEnd = network.makeEndpoint()
        server = NetServer(world: World(), transport: serverEnd, secret: 662)
        var nextID: UInt64 = 0
        server.world.entityIDGenerator = {
            nextID += 1
            return EntityID(high: 662, low: nextID)
        }
        Self.buildLevel(serverPhysics)
        for i in 0..<2 {
            let client = NetClient(world: World(), transport: network.makeEndpoint(), server: serverEnd.id, salt: UInt64(i + 1))
            clients.append(client)
            let physics = PhysicsWorld()
            Self.buildLevel(physics)
            clientPhysics.append(physics)
        }
        // Start four seconds in: connected, characters spawned, both players moving.
        for _ in 0..<240 { fixedStep() }
        mirror()
    }

    private static func buildLevel(_ physics: PhysicsWorld) {
        for (lo, hi) in level {
            physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: (lo + hi) * 0.5), shape: .box((hi - lo) * 0.5)))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.8, distance: 24, target: Vec3(0, 0.5, 0.5)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var wantsKeyboard: Bool { keysHeld }
    var status: String {
        let corrections = predictions.map { "\($0?.stats.corrections ?? 0)" }.joined(separator: "/")
        return "tick \(server.tick), corrections \(corrections), \(network.stats.dropped)/\(network.stats.sent) packets lost, WASD move [F] jump (player 1)"
    }

    /// The scripted input of `player`: walk to the next waypoint (from the predicted position),
    /// jump now and then.
    private func scriptedInput(_ player: Int) -> NetCharacterInput {
        guard let position = predictions[player]?.position else { return NetCharacterInput() }
        let route = Self.routes[player]
        func distance(_ v: Vec2) -> Float { (v * v).sum().squareRoot() }
        var target = route[waypoint[player]]
        if distance(Vec2(position.x, position.z) - target) < 0.4 {
            waypoint[player] = (waypoint[player] + 1) % route.count
            target = route[waypoint[player]]
        }
        let toward = target - Vec2(position.x, position.z)
        let speed: Float = player == 0 ? 4.5 : 3.8
        return NetCharacterInput(move: distance(toward) > 1e-3 ? toward / distance(toward) * speed : .zero,
                                 jump: step % Self.jumpPeriods[player] == Self.jumpPeriods[player] - 1)
    }

    /// One 60 Hz step of the whole session: clients predict and send, the server applies
    /// inputs and sends snapshots, the clients receive.
    private func fixedStep() {
        network.now = time
        for (i, client) in clients.enumerated() {
            for case .message(let bytes) in client.pollEvents() where bytes.count == 16 {
                let id = EntityID(high: bytes[0..<8].reversed().reduce(0) { $0 << 8 | UInt64($1) },
                                  low: bytes[8..<16].reversed().reduce(0) { $0 << 8 | UInt64($1) })
                predictions[i] = NetCharacterPrediction(client: client, physics: clientPhysics[i], entityID: id, dt: Self.dt)
            }
            guard let prediction = predictions[i] else { continue }
            var input = scriptedInput(i)
            if i == 0 && userActive {
                let move = actions.vector("move")
                input = NetCharacterInput(move: Vec2(move.x, -move.y) * 4.5, jump: pendingJump)
                pendingJump = false
            }
            prediction.step(input)
        }
        server.receive(time: time)
        for event in server.pollEvents() {
            guard case .connected(let id) = event else { continue }
            let entity = server.world.spawn(
                Transform(position: Vec3(id.value == 1 ? -4.5 : 4.5, 0.02, id.value == 1 ? 0 : -2.6)), CharacterController(),
                Replicated(components: [Transform.componentName, CharacterController.componentName], transform: .exact))
            characters[id] = entity
            let entityID = server.world.ensureID(of: entity)!
            var bytes: [UInt8] = []
            for v in [entityID.high, entityID.low] { withUnsafeBytes(of: v.littleEndian) { bytes.append(contentsOf: $0) } }
            server.send(message: bytes, to: id)
        }
        for (id, entity) in characters.sorted(by: { $0.key < $1.key }) {
            for command in server.takeInputs(from: id, max: 4) {
                guard let input = try? NetCharacterInput(decoding: command.bytes) else { continue }
                serverPhysics.applyCharacterInput(input, to: entity, in: server.world, dt: Self.dt)
            }
        }
        server.update(time: time)
        for client in clients { client.update(dt: Double(Self.dt)) }
        time += Double(Self.dt)
        step += 1
    }

    func update(input: Input, dt: Float, time: Float) {
        actions.update(input)
        let move = actions.vector("move")
        keysHeld = move != .zero || actions.isPressed("jump")
        if move != .zero || actions.wasPressed("jump") { userActive = true }
        if actions.wasPressed("jump") { pendingJump = true }
        accumulator = min(accumulator + dt, Self.dt * 8)
        while accumulator >= Self.dt * 0.999 {
            accumulator -= Self.dt
            fixedStep()
        }
        mirror()
    }

    /// Shows each client's world in its panel, and the server's characters as ghosts in both.
    private func mirror() {
        var seen: Set<String> = []
        func show(_ key: String, _ position: Vec3, _ controller: CharacterController?, panel: Float, tint: Vec3, ghost: Bool) {
            seen.insert(key)
            // Face the way it walks (kept when it stops).
            if let v = controller?.moveVelocity, v.x * v.x + v.z * v.z > 1e-4 { yaws[key] = atan2f(v.x, v.z) }
            let rotation = Quat(angle: yaws[key] ?? 0, axis: Vec3(0, 1, 0))
            let base = position + Vec3(panel, 0, 0)
            let body = mirrors[key] ?? display.spawn()
            mirrors[key] = body
            display.add(Transform(position: base + Vec3(0, 0.9, 0), rotation: rotation), to: body)
            display.add(MeshRenderer(mesh: MeshHandle("hero"), material: MaterialHandle(ghost ? "ghost" : "glossy"), tint: tint,
                                     opacity: ghost ? 0.25 : 1, castsShadows: !ghost), to: body)
            guard !ghost else { return }
            let noseKey = key + ".nose"
            seen.insert(noseKey)
            let nose = mirrors[noseKey] ?? display.spawn()
            mirrors[noseKey] = nose
            display.add(Transform(position: base + Vec3(0, 1.25, 0) + rotation * Vec3(0, 0, 0.27), rotation: rotation, scale: Vec3(0.2, 0.12, 0.2)), to: nose)
            display.add(MeshRenderer(mesh: .cube, material: MaterialHandle("matte"), tint: Vec3(0.05, 0.05, 0.05)), to: nose)
        }
        let colors = [Vec3(0.95, 0.55, 0.15), Vec3(0.25, 0.55, 0.95)]
        var owner: [EntityID: Int] = [:]
        for (i, prediction) in predictions.enumerated() { if let id = prediction?.entityID { owner[id] = i } }
        for (i, client) in clients.enumerated() {
            let panel = i == 0 ? -Self.side : Self.side
            for entity in client.world.entities {
                guard let id = client.world.id(of: entity), let transform = client.world.get(Transform.self, for: entity) else { continue }
                show("c\(i)\(id)", transform.position, client.world.get(CharacterController.self, for: entity), panel: panel,
                     tint: colors[owner[id] ?? 0], ghost: false)
            }
            for (clientID, entity) in characters {
                guard let transform = server.world.get(Transform.self, for: entity) else { continue }
                show("g\(i)\(clientID)", transform.position, nil, panel: panel, tint: colors[server.world.id(of: entity).flatMap { owner[$0] } ?? 0], ghost: true)
            }
        }
        for key in mirrors.keys.sorted() where !seen.contains(key) {
            display.despawn(mirrors[key]!)
            mirrors[key] = nil
        }
    }

    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera {
        orbit = (orbitEye, target)
        return ViewCamera(eye: orbitEye, target: target)
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        if let orbit { display.add(Transform.looking(from: orbit.eye, at: orbit.target), to: cameraEntity) }
        display.propagateTransforms()
        sceneRenderer.renderOffscreen(world: display, engine: engine, frame: frame)
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        sceneRenderer.draw(pass)
    }

    func drawUI(_ ui: UIDrawList) {
        let text = UIColor(hex: 0xf2f2f2), dim = UIColor(hex: 0xc8ccd4), panel = UIColor(hex: 0x000000, alpha: 0.45)
        let width = ui.size.x
        for (i, client) in clients.enumerated() {
            let x: Float = i == 0 ? 12 : width - 432
            let stats = client.connectionStats
            let rtt = stats?.rtt.map { String(format: "%.0f ms", $0 * 1000) } ?? "-"
            let loss = stats.map { String(format: "%.0f%%", $0.loss * 100) } ?? "-"
            let p = predictions[i]?.stats
            ui.fillRect(UIRect(x: x, y: 12, width: 420, height: 86), color: panel, radii: UICornerRadii(8))
            ui.drawText("Player \(i + 1)'s screen (\(i == 0 ? "orange" : "blue") is theirs)", at: Vec2(x + 12, 20), size: 17, color: text)
            ui.drawText("RTT \(rtt), loss \(loss), own character predicted", at: Vec2(x + 12, 46), size: 13, color: dim)
            ui.drawText("\(p?.reconciliations ?? 0) reconciliations, \(p?.corrections ?? 0) corrections; the other player is interpolated",
                        at: Vec2(x + 12, 68), size: 13, color: dim)
        }
    }
}
