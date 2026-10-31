import Engine
import Foundation

/// The networking prototype (Sources/Engine/Net): a server world and a client world in one
/// process, joined by a simulated link (100 ms one way, 5% loss each way). Left: the server's
/// authoritative movers. Right: the client's replica, built only from delta snapshots (30 Hz)
/// and shown 100 ms behind the newest one with interpolated transforms; the faint shapes on the
/// right are where the server has them now, i.e. the total delay a remote player sees.
final class NetScene: DemoScene {
    static let name = "net"
    static let summary = "networking prototype: server world and an interpolated client replica over a lossy, laggy loopback link"

    private let display = World()
    private let serverWorld = World()
    private let clientWorld = World()
    private let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.1, loss: 0.05), seed: 624)
    private let server: NetServer
    private let client: NetClient
    private let sceneRenderer: SceneRenderer
    private let cameraEntity: Entity
    private var orbit: (eye: Vec3, target: Vec3)?
    private var mirrors: [String: Entity] = [:]
    private var simTime = 0.0
    private static let side: Float = 7.5
    private static let fogColor = Vec3(0.6, 0.66, 0.74)

    init(renderer: Renderer) throws {
        sceneRenderer = try SceneRenderer(device: renderer.device, quality: renderer.quality)
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.55, 0.53, 0.5, 1), checker: true, specular: 0.1), key: "floor")
        try sceneRenderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), specular: 0.6, shininess: 64), key: "glossy")
        try sceneRenderer.registerMaterial(
            Material(shading: .blinnPhong, baseColor: Vec4(1, 1, 1, 1), alphaMode: .blend), key: "ghost")

        cameraEntity = display.spawn(
            Transform.looking(from: Vec3(0, 16, 22), at: Vec3(0, 1, 0)),
            Camera(fovY: .pi / 3.5, near: 0.5, far: 200, clearColor: Vec4(Self.fogColor, 1)))
        _ = display.spawn(SceneEnvironment(fogColor: Self.fogColor, fogDensity: 0.004))
        _ = display.spawn(Transform(rotation: .lookRotation(forward: -Vec3(0.4, 0.8, 0.45))), DirectionalLight(intensity: 1.3, shadowExtent: 24))
        for (x, tint) in [(-Self.side, Vec3(1, 0.85, 0.8)), (Self.side, Vec3(0.8, 0.9, 1))] {
            _ = display.spawn(Transform(position: Vec3(x, -0.25, 0), scale: Vec3(13, 0.5, 13)),
                              MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), tint: tint, castsShadows: false))
        }

        // Server content: movers on circles at different speeds, some spinning cubes.
        var nextID: UInt64 = 0
        serverWorld.entityIDGenerator = {
            nextID += 1
            return EntityID(high: 624, low: nextID)
        }
        for i in 0..<14 {
            let ring = Float(i % 2) * 2.2 + 2.2
            _ = serverWorld.spawn(
                Transform(position: Vec3(ring, 0.6, 0), scale: Vec3(repeating: i % 3 == 0 ? 1.1 : 0.8)),
                MeshRenderer(mesh: i % 3 == 0 ? .cube : .sphere, material: MaterialHandle("glossy"), tint: hsv(Float(i) / 14, 0.65, 0.95)),
                NetSceneMover(radius: ring, speed: (i % 2 == 0 ? 1 : -1) * (0.6 + Float(i) * 0.08), phase: Float(i) * 0.9),
                Replicated(components: [Transform.componentName, MeshRenderer.componentName]))
        }
        serverWorld.addSystem("net-movers") { world in
            let t = Float(world.time.elapsed)
            world.queryMutating(Transform.self, NetSceneMover.self) { _, transform, mover in
                let a = mover.phase + mover.speed * t
                transform.position = Vec3(cosf(a) * mover.radius, 0.6 + 0.4 * sinf(t * 3 + mover.phase), sinf(a) * mover.radius)
                transform.rotation = Quat(angle: a * 2, axis: Vec3(0, 1, 0))
            }
        }

        let serverEnd = network.makeEndpoint()
        let clientEnd = network.makeEndpoint()
        server = NetServer(world: serverWorld, transport: serverEnd)
        client = NetClient(world: clientWorld, transport: clientEnd, server: serverEnd.id)
        display.propagateTransforms()
    }

    var initialView: OrbitView { OrbitView(yaw: 0, pitch: 0.75, distance: 26, target: Vec3(0, 0.5, 0)) }
    var lighting: Lighting { Lighting(fogColor: Self.fogColor) }
    var status: String {
        let bytes = server.clients.first.flatMap { server.lastSnapshotBytes[$0] } ?? 0
        return "tick \(server.tick), snapshot \(bytes) B, \(network.stats.dropped)/\(network.stats.sent) packets lost"
    }

    func update(input: Input, dt: Float, time: Float) {
        simTime += Double(dt)
        network.now = simTime
        serverWorld.update(dt: Double(dt))
        server.update(time: serverWorld.time.elapsed)
        client.update(dt: Double(dt))
        mirror()
    }

    /// Copies the server world (left), the client world (right) and the server's current
    /// positions as ghosts (right) into the displayed world.
    private func mirror() {
        var seen: Set<String> = []
        func show(_ key: String, _ transform: Transform, _ renderer: MeshRenderer, x: Float) {
            seen.insert(key)
            var t = transform
            t.position.x += x
            let entity = mirrors[key] ?? display.spawn()
            mirrors[key] = entity
            display.add(t, to: entity)
            display.add(renderer, to: entity)
        }
        for world in [serverWorld, clientWorld] {
            for entity in world.entities {
                guard let id = world.id(of: entity), let transform = world.get(Transform.self, for: entity),
                      var renderer = world.get(MeshRenderer.self, for: entity) else { continue }
                if world === serverWorld {
                    show("s\(id)", transform, renderer, x: -Self.side)
                    renderer.material = MaterialHandle("ghost")
                    renderer.opacity = 0.22
                    renderer.castsShadows = false
                    show("g\(id)", transform, renderer, x: Self.side)
                } else {
                    show("c\(id)", transform, renderer, x: Self.side)
                }
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
        let bytes = server.clients.first.flatMap { server.lastSnapshotBytes[$0] } ?? 0
        let lag = client.renderTime.map { String(format: "%.0f ms", (simTime - $0) * 1000) } ?? "-"
        let width = ui.size.x
        ui.fillRect(UIRect(x: 12, y: 12, width: 330, height: 66), color: panel, radii: UICornerRadii(8))
        ui.drawText("Server (authoritative)", at: Vec2(24, 20), size: 17, color: text)
        ui.drawText("tick \(server.tick) at 30 Hz, last delta \(bytes) bytes", at: Vec2(24, 46), size: 13, color: dim)
        ui.fillRect(UIRect(x: width - 342, y: 12, width: 330, height: 86), color: panel, radii: UICornerRadii(8))
        ui.drawText("Client (interpolated replica)", at: Vec2(width - 330, 20), size: 17, color: text)
        ui.drawText("100 ms latency, 5% loss, 100 ms buffer", at: Vec2(width - 330, 46), size: 13, color: dim)
        ui.drawText("\(client.stats.snapshots) snapshots, \(lag) behind (ghosts: now)", at: Vec2(width - 330, 68), size: 13, color: dim)
    }
}

/// Moves a `net` scene entity on a circle (server side only; not replicated).
struct NetSceneMover: Component, Codable, Sendable {
    var radius: Float
    var speed: Float
    var phase: Float
}
