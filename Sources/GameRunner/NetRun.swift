import Engine
import Foundation

#if canImport(Darwin) || canImport(Glibc)

// Networked runs (card 671, phase 6):
//
//   GameRunner SampleGame --server [--port 7777] [--host 0.0.0.0]
//       runs the game headless (no window, no GPU) as a UDP server: the module's systems (and
//       physics, when the world has colliders) at 60 Hz, snapshots at 30 Hz, a line of stats
//       per client every two seconds.
//   GameRunner SampleGame --connect 127.0.0.1:7777 [--headless]
//       a client: a window showing the replicated world, with the network stats in the debug
//       overlay (` toggles it); --headless prints them instead.
//
// Both sides build the same starting world: the scene file when one is given, else the
// module's `networkedWorld` (GameModule ABI 1.3). Entity ids are numbered in spawn / load order
// where the world has none, the same on both sides, so the client's entities are matched to
// the server's by id (Net phase 4) rather than spawned twice. Entities marked `Replicated` are
// sent; with none marked (`--replicate auto`, the default), every entity with a Transform is
// (Transform, MeshRenderer, Name), entities the server spawns later included. `--duration`
// stops either side after that many seconds (for scripts and tests).

struct NetRunOptions {
    enum Role { case server, client(host: String, port: UInt16) }
    enum Replication: String { case auto, all, marked }
    var role: Role
    var port: UInt16 = 7777
    var host = "0.0.0.0"
    var headless = false
    var duration: Double?
    var replication = Replication.auto
}

@MainActor
enum NetRun {
    static let replicatedComponents = [Transform.componentName, MeshRenderer.componentName, Name.componentName]

    /// The starting world: `sceneURL`, else the module's networked world. Ids where missing are
    /// numbered in order (the same on server and clients).
    static func makeWorld(module: GameModule, sceneURL: URL?) throws -> World {
        let world = World()
        var next: UInt64 = 0
        world.entityIDGenerator = {
            next += 1
            return EntityID(high: 0x6E65_7477_6F72_6B00, low: next) // "network"
        }
        world.assignsEntityIDs = true
        if let sceneURL {
            try world.load(Data(contentsOf: sceneURL))
        } else if let populate = module.populateNetworkedWorld {
            populate(world)
        } else {
            throw NetRunError("\(module.name) has no networked world (GameModule.networkedWorld): pass a scene file")
        }
        world.assignsEntityIDs = false
        return world
    }

    /// Whether every entity with a Transform is replicated, marking them if so.
    static func prepare(_ world: World, _ mode: NetRunOptions.Replication) -> Bool {
        let all = mode == .all || (mode == .auto && world.count(of: Replicated.self) == 0)
        if all { markReplicated(world) }
        return all
    }

    static func markReplicated(_ world: World) {
        var unmarked: [Entity] = []
        world.query(Transform.self) { entity, _ in if !world.has(Replicated.self, for: entity) { unmarked.append(entity) } }
        for entity in unmarked { world.add(Replicated(components: replicatedComponents), to: entity) }
    }

    static func log(_ line: String) {
        print(line)
        fflush(stdout)
    }

    // MARK: Server

    static func runServer(module: GameModule, sceneURL: URL?, options: NetRunOptions) throws {
        let world = try makeWorld(module: module, sceneURL: sceneURL)
        let replicatesAll = prepare(world, options.replication)
        if world.count(of: Collider.self) > 0 { world.addPhysics(PhysicsWorld()) }
        if world.count(of: Collider2D.self) > 0 { world.addPhysics2D(PhysicsWorld2D()) }
        for warning in module.addSystems(to: world, context: GameContext(input: Input())) { log(warning) }
        let transport = try UDPTransport(host: options.host, port: options.port)
        let server = NetServer(world: world, transport: transport)
        log("Serving \(module.name) headless on \(options.host):\(transport.port) (UDP), \(world.count(of: Replicated.self)) replicated entities"
            + (replicatesAll ? " (every entity with a Transform)" : ""))
        let dt = 1.0 / 60.0
        let start = Date()
        var tick = 0
        var nextReport = 2.0
        while true {
            let time = Double(tick) * dt
            if let duration = options.duration, time >= duration { break }
            let wait = time - Date().timeIntervalSince(start)
            if wait > 0 { usleep(UInt32(wait * 1_000_000)) }
            if replicatesAll { markReplicated(world) }
            world.update(dt: dt)
            server.update(time: time)
            for event in server.pollEvents() {
                switch event {
                case .connected(let id): log("\(id) connected")
                case .disconnected(let id, let reason): log("\(id) disconnected (\(reason))")
                case .message: break
                }
            }
            if time >= nextReport {
                nextReport += 2
                for client in server.clients {
                    guard let report = server.statsReport(for: client) else { continue }
                    log(String(format: "[%6.1f s] %@: RTT %@, loss %.1f%%, out %.1f kbit/s, in %.1f kbit/s, last snapshot %d B",
                               time, report.name, report.rttMs.map { String(format: "%.1f ms", $0) } ?? "-", report.lossPercent,
                               report.bytesOutPerSecond * 8 / 1000, report.bytesInPerSecond * 8 / 1000, report.lastSnapshotBytes ?? 0))
                }
            }
            tick += 1
        }
        for client in server.clients { server.disconnect(client) }
        log("Server stopped after \(tick) ticks, \(server.tick) snapshots")
    }

    // MARK: Client

    static func makeClient(world: World, host: String, port: UInt16) throws -> NetClient {
        let transport = try UDPTransport(host: "0.0.0.0", port: 0)
        let server = try transport.peer(host: host == "localhost" ? "127.0.0.1" : host, port: port)
        return NetClient(world: world, transport: transport, server: server)
    }

    /// A client without a window: prints its stats every two seconds.
    static func runHeadlessClient(module: GameModule, sceneURL: URL?, host: String, port: UInt16, options: NetRunOptions) throws {
        let world = try makeWorld(module: module, sceneURL: sceneURL)
        _ = prepare(world, options.replication)
        let client = try makeClient(world: world, host: host, port: port)
        log("Connecting to \(host):\(port) (headless)")
        let dt = 1.0 / 60.0
        let start = Date()
        var frame = 0
        var nextReport = 2.0
        var failure: String?
        loop: while true {
            let time = Double(frame) * dt
            if let duration = options.duration, time >= duration { break }
            let wait = time - Date().timeIntervalSince(start)
            if wait > 0 { usleep(UInt32(wait * 1_000_000)) }
            client.update(dt: dt)
            world.propagateTransforms()
            for event in client.pollEvents() {
                switch event {
                case .connected(let id): log("Connected as \(id)")
                case .disconnected(let reason):
                    failure = "\(reason)"
                    break loop
                case .message: break
                }
            }
            if time >= nextReport {
                nextReport += 2
                log(String(format: "[%6.1f s] ", time) + client.statsReport().overlayLines.joined(separator: " | "))
            }
            frame += 1
        }
        let report = client.statsReport()
        if let failure {
            log("Disconnected: \(failure)")
        } else {
            client.disconnect()
        }
        log("Client done: \(report.snapshots) snapshots, \(report.entities ?? 0) replicated entities, \(world.entityCount) in its world")
        if failure != nil || report.snapshots == 0 { exit(1) }
    }
}

/// A client with a window: the replicated world drawn by a SceneRenderer, the network stats in
/// the debug overlay.
@MainActor
final class NetClientGame: Game {
    let module: GameModule
    let sceneURL: URL?
    let host: String
    let port: UInt16
    let options: NetRunOptions
    private var world: World!
    private var client: NetClient!
    private var renderer: SceneRenderer!

    init(module: GameModule, sceneURL: URL?, host: String, port: UInt16, options: NetRunOptions) {
        self.module = module
        self.sceneURL = sceneURL
        self.host = host
        self.port = port
        self.options = options
    }

    func setup(engine: Engine) throws {
        renderer = try SceneRenderer(engine: engine)
        try renderer.registerMaterial(Material(shading: .blinnPhong, baseColor: Vec4(0.6, 0.6, 0.58, 1), checker: true, specular: 0.1),
                                      key: "checker")
        world = try NetRun.makeWorld(module: module, sceneURL: sceneURL)
        _ = NetRun.prepare(world, options.replication)
        client = try NetRun.makeClient(world: world, host: host, port: port)
        // No systems: the client only shows what the server sends (the world still propagates
        // transforms and prepares rendering).
        engine.world = world
        engine.showDebugOverlay = true
        engine.debugOverlayLines = { [client] in client!.statsReport().overlayLines }
        NetRun.log("Connecting to \(host):\(port)")
    }

    func update(engine: Engine, dt: Float) {
        client.update(dt: Double(dt))
        for event in client.pollEvents() {
            switch event {
            case .connected(let id): NetRun.log("Connected as \(id)")
            case .disconnected(let reason): engine.quit(reason: "disconnected from the server (\(reason))")
            case .message: break
            }
        }
        if let duration = options.duration, client.time >= duration {
            client.disconnect()
            engine.quit(reason: "--duration elapsed")
        }
    }

    func renderOffscreen(engine: Engine, frame: Frame) { renderer.renderOffscreen(world: world, engine: engine, frame: frame) }
    func render(engine: Engine, pass: RenderPass) { renderer.draw(pass) }
}

struct NetRunError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
#endif
