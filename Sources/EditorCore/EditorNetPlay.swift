import Engine
import Foundation

// Network play in the editor (card 671, phase 6): one process, the scene's world as the server
// plus N client worlds, joined by a `LoopbackNetwork` (like the `net` demo scene).
//
// `net.start {clients: 2}` enters play mode (if it isn't already) and makes each client world a
// copy of the scene as play started, i.e. every client loaded the same scene: its entities are
// matched to the server's by `EntityID` (NetHierarchy / phase 4), and what the server spawns,
// moves, reparents or removes reaches them as snapshots. Clients only display: game systems,
// physics and input run on the server (the session's world), as they would on a dedicated
// server whose clients send nothing but their connection traffic.
//
// Replication: entities with a `Replicated` component as the scene sets them up; a scene
// without any (`replicate: "auto"`, the default) gets one on every entity with a Transform,
// sending Transform, MeshRenderer and Name, on the server and on the client copies (so
// entities the server removes before a client connects go away there too), and entities the
// server spawns later get one each frame.
//
// The Game View shows the server or one client (`net.view`), the scene view (Game View off)
// always the server. Per-client link conditions (`net.setConditions`: latency, jitter, loss,
// duplication, each direction) and every connection's numbers (`net.stats`) are tools; the
// viewport draws them as an overlay (`net.overlay`).
//
// Stopping play (or `net.stop`, or reloading game code) ends network play and drops the client
// worlds.

/// One client of an editor network play session.
@MainActor
public final class EditorNetClient {
    /// 1, 2, ... in the order they were made (also their `NetClientID` while connected).
    public let index: Int
    public let world: World
    public let net: NetClient
    let transport: LoopbackTransport
    /// Server to client, and client to server.
    public internal(set) var down: LinkConditions
    public internal(set) var up: LinkConditions

    init(index: Int, world: World, net: NetClient, transport: LoopbackTransport, conditions: LinkConditions) {
        self.index = index
        self.world = world
        self.net = net
        self.transport = transport
        down = conditions
        up = conditions
    }
}

/// The server, its clients and the simulated network of an editor network play session.
@MainActor
public final class EditorNetPlay {
    /// What gets a `Replicated` component.
    public enum Replication: String, Codable, Sendable {
        /// The scene's own `Replicated` components, or "all" when it has none.
        case auto
        /// Every entity with a Transform (Transform, MeshRenderer and Name).
        case all
        /// Only entities with a `Replicated` component.
        case marked
    }

    public let network: LoopbackNetwork
    public let server: NetServer
    public private(set) var clients: [EditorNetClient] = []
    /// Whether every entity with a Transform is replicated (see `Replication`).
    public let replicatesAll: Bool
    /// The client the Game View shows (1...), nil for the server.
    public var viewedClient: Int? {
        didSet { if let viewedClient, client(viewedClient) == nil { self.viewedClient = nil } }
    }
    /// Whether the viewport draws the stats overlay.
    public var showsOverlay = true
    /// Seconds of network time (play time since `net.start`).
    public private(set) var time: Double = 0

    static let replicatedComponents = [Transform.componentName, MeshRenderer.componentName, Name.componentName]
    private let serverEndpoint: LoopbackTransport
    private let scene: WorldSnapshot
    private unowned let session: EditorSession

    /// A server on `session.world` and `clients` client worlds copied from `scene` (the scene
    /// as play started).
    init(session: EditorSession, scene: WorldSnapshot, clients count: Int, conditions: LinkConditions, replication: Replication) {
        self.session = session
        self.scene = scene
        network = LoopbackNetwork(conditions: conditions, seed: 671)
        serverEndpoint = network.makeEndpoint()
        server = NetServer(world: session.world, transport: serverEndpoint, secret: 671)
        server.maxClients = 64
        let world = session.world
        replicatesAll = replication == .all || (replication == .auto && world.count(of: Replicated.self) == 0)
        if replicatesAll { Self.markReplicated(world) }
        for _ in 0..<count { addClient(conditions: conditions) }
    }

    /// Adds a client: a copy of the scene, connecting now.
    @discardableResult
    func addClient(conditions: LinkConditions) -> EditorNetClient {
        let index = (clients.last?.index ?? 0) + 1
        let world = World()
        world.restore(scene)
        if replicatesAll { Self.markReplicated(world) }
        world.propagateTransforms()
        let endpoint = network.makeEndpoint()
        let net = NetClient(world: world, transport: endpoint, server: serverEndpoint.id, salt: UInt64(index) &* 0x9E37_79B9)
        let client = EditorNetClient(index: index, world: world, net: net, transport: endpoint, conditions: conditions)
        clients.append(client)
        return client
    }

    public func client(_ index: Int) -> EditorNetClient? { clients.first { $0.index == index } }

    /// The world the Game View shows.
    public var viewedWorld: World? { viewedClient.flatMap { client($0)?.world } }

    /// Sets the link conditions between `client` (nil: every client) and the server, in
    /// `direction` "down" (server to client), "up" or both.
    func setConditions(_ conditions: LinkConditions, client index: Int?, up: Bool, down: Bool) throws {
        let targets = try index.map { i in [try client(i).orThrow("No client \(i) (net.stats lists them)")] } ?? clients
        for client in targets {
            if down {
                client.down = conditions
                network.linkOverrides[LoopbackNetwork.Link(from: serverEndpoint.id, to: client.transport.id)] = conditions
            }
            if up {
                client.up = conditions
                network.linkOverrides[LoopbackNetwork.Link(from: client.transport.id, to: serverEndpoint.id)] = conditions
            }
        }
    }

    /// One game frame, after the server's world updated: the network's clock, the server's
    /// snapshots and every client's receive / apply / send.
    func advance(dt: Double) {
        time += dt
        network.now = time
        if replicatesAll { Self.markReplicated(session.world) }
        server.update(time: time)
        _ = server.pollEvents()
        for client in clients {
            client.net.update(dt: dt)
            _ = client.net.pollEvents()
            client.world.propagateTransforms()
        }
    }

    /// Gives every entity with a Transform and no `Replicated` one.
    static func markReplicated(_ world: World) {
        var unmarked: [(Entity, [String])] = []
        world.query(Transform.self) { entity, _ in
            guard !world.has(Replicated.self, for: entity) else { return }
            unmarked.append((entity, replicatedComponents))
        }
        for (entity, components) in unmarked { world.add(Replicated(components: components), to: entity) }
    }

    // MARK: Reports

    /// The server's view of each client, then each client's own, in client order and named by
    /// the editor's client numbers (the server numbers them in the order they connected).
    public var statsResult: NetStatsResult {
        NetStatsResult(time: time, server: clients.compactMap(serverReport), clients: clients.map(report),
                       network: .init(network.stats))
    }

    func report(_ client: EditorNetClient) -> NetStatsReport {
        var report = client.net.statsReport()
        report.name = "client \(client.index)"
        return report
    }

    func serverReport(_ client: EditorNetClient) -> NetStatsReport? {
        guard let id = client.net.clientID, var report = server.statsReport(for: id) else { return nil }
        report.name = "server → client \(client.index)"
        return report
    }

    public var stateResult: NetPlayStateResult {
        NetPlayStateResult(active: true, view: viewedClient.map { "client \($0)" } ?? "server", overlay: showsOverlay,
                           replicatesAll: replicatesAll,
                           clients: clients.map { client in
                               NetPlayClientState(index: client.index, connected: client.net.clientID != nil,
                                                  entities: client.net.replicatedEntityCount,
                                                  down: NetLinkConditions(client.down), up: NetLinkConditions(client.up))
                           })
    }

    // MARK: Overlay

    /// The stats lines the viewport overlay shows: the viewed client's (or each client's, as
    /// the server sees it, when the Game View shows the server).
    func overlayLines() -> [String] {
        var lines: [String] = []
        if let index = viewedClient, let client = client(index) {
            lines.append("Game View: client \(index)")
            lines += report(client).overlayLines.dropFirst()
        } else {
            lines.append("Game View: server, \(clients.count) client\(clients.count == 1 ? "" : "s")")
            for client in clients {
                lines += Self.compact(report(client), server: serverReport(client))
            }
        }
        return lines
    }

    /// One client in two lines, for the server's overview.
    static func compact(_ report: NetStatsReport, server: NetStatsReport?) -> [String] {
        let rtt = report.rttMs.map { String(format: "%.0f ms", $0) } ?? "-"
        let down = String(format: "%.1f", report.bytesInPerSecond * 8 / 1000), up = String(format: "%.1f", report.bytesOutPerSecond * 8 / 1000)
        return [
            "\(report.name.capitalized): RTT \(rtt), loss \(String(format: "%.1f", report.lossPercent))%" + (report.connected ? "" : " (disconnected)"),
            "  in \(down) / out \(up) kbit/s, buffer \(String(format: "%.0f", report.bufferedMs ?? 0)) ms, "
                + "starved \(report.starvedFrames ?? 0)" + (server.map { ", last \($0.lastSnapshotBytes ?? 0) B" } ?? ""),
        ]
    }

    /// Draws `lines` in a dark panel at the top right of `frame` (over the scene, in every theme).
    static func drawOverlay(_ lines: [String], in frame: UIRect, list: UIDrawList, theme: UITheme, context: UIContext?) {
        guard !lines.isEmpty else { return }
        let size = theme.smallFontSize
        let layouts = lines.map { context?.textLayout($0, size: size) ?? TextLayout($0, font: theme.font, size: size) }
        let width = (layouts.map(\.width).max() ?? 0) + 16
        let lineHeight = (layouts.first?.height ?? size) + 2
        let height = lineHeight * Float(layouts.count) + 10
        let panel = UIRect(x: (frame.x + frame.width - width - 8).rounded(), y: (frame.y + 8).rounded(), width: width.rounded(), height: height.rounded())
        list.fillRect(panel, color: UIColor(0, 0, 0, 0.62), radii: UICornerRadii(4))
        for (i, layout) in layouts.enumerated() {
            let color = i == 0 ? UIColor(hex: 0x8fd6a8) : UIColor(hex: 0xf2f4f8)
            list.drawText(layout, font: theme.font, at: Vec2(panel.x + 8, (panel.y + 5 + Float(i) * lineHeight).rounded()), color: color)
        }
    }
}

extension EditorSession {
    /// The world the Game View shows: a network play client's when one is picked (`net.view`),
    /// else the scene's.
    public var gameWorld: World { netPlay?.viewedWorld ?? world }

    /// Starts network play: play mode (if not playing) plus `clients` client worlds.
    @discardableResult
    func startNetPlay(clients: Int, conditions: LinkConditions, replication: EditorNetPlay.Replication) -> EditorNetPlay {
        if netPlay != nil { endNetPlay(reason: nil) }
        if !isPlaying { play() }
        let scene = playSnapshot ?? world.snapshot()
        let net = EditorNetPlay(session: self, scene: scene, clients: clients, conditions: conditions, replication: replication)
        netPlay = net
        log.info("Network play: server and \(clients) client\(clients == 1 ? "" : "s")"
                 + (conditions == .perfect ? "" : String(format: " (%.0f ms, %.0f%% loss)", conditions.latency * 1000, conditions.loss * 100)))
        changed()
        return net
    }

    /// Ends network play (play mode goes on); `reason` is logged.
    func endNetPlay(reason: String?) {
        guard let net = netPlay else { return }
        for client in net.clients { client.net.disconnect() }
        netPlay = nil
        log.info("Network play ended" + (reason.map { " (\($0))" } ?? ""))
        changed()
    }
}

extension Optional {
    fileprivate func orThrow(_ message: String) throws -> Wrapped {
        guard let self else { throw CommandError.failed(message) }
        return self
    }
}

/// The toolbar's Network menu: play with 1-4 clients, then (while network play runs) stop it,
/// the Game View's world, link presets for every client and the stats overlay.
@MainActor
enum EditorNetMenu {
    /// Link presets: name and conditions (both ways).
    static let presets: [(String, LinkConditions)] = [
        ("Perfect Link", .perfect),
        ("LAN (2 ms)", LinkConditions(latency: 0.002)),
        ("Internet (60 ms, 1% Loss)", LinkConditions(latency: 0.06, jitter: 0.01, loss: 0.01)),
        ("Poor (150 ms, 40 ms Jitter, 5% Loss)", LinkConditions(latency: 0.15, jitter: 0.04, loss: 0.05, duplicate: 0.01)),
    ]

    static func show(anchor: Button, session: EditorSession) {
        guard let context = anchor.context else { return }
        var items: [String] = []
        var commands: [String?] = []
        var actions: [() -> Void] = []
        var checked = Set<Int>()
        func add(_ title: String, _ command: CommandID, checked isChecked: Bool = false, _ action: @escaping () -> Void) {
            if isChecked { checked.insert(items.count) }
            items.append(title)
            commands.append(command.rawValue)
            actions.append(action)
        }
        let net = session.netPlay
        for count in 1...4 {
            add("Play with \(count) Client\(count == 1 ? "" : "s")", NetStartCommand.id, checked: net?.clients.count == count) {
                session.run(NetStartCommand.self, .init(clients: count))
            }
        }
        if let net {
            add("Stop Network Play", NetStopCommand.id) { session.run(NetStopCommand.self) }
            add("Game View: Server", NetViewCommand.id, checked: net.viewedClient == nil) {
                session.run(NetViewCommand.self, .init(target: "server"))
            }
            for client in net.clients {
                add("Game View: Client \(client.index)", NetViewCommand.id, checked: net.viewedClient == client.index) {
                    session.run(NetViewCommand.self, .init(target: "client \(client.index)"))
                }
            }
            for (title, conditions) in presets {
                let all = net.clients.allSatisfy { $0.up == conditions && $0.down == conditions }
                let link = NetLinkConditions(conditions)
                add(title, NetSetConditionsCommand.id, checked: all) {
                    session.run(NetSetConditionsCommand.self, .init(latencyMs: link.latencyMs, jitterMs: link.jitterMs, loss: link.loss,
                                                                    duplicate: link.duplicate))
                }
            }
            add("Stats Overlay", NetOverlayCommand.id, checked: net.showsOverlay) { session.run(NetOverlayCommand.self, .init()) }
        }
        let menu = PopupMenu(items: items, anchor: anchor, name: "networkMenu")
        menu.itemCommandIDs = commands
        menu.checkedIndices = checked
        menu.onSelect = { index in if actions.indices.contains(index) { actions[index]() } }
        context.presentOverlay(menu)
    }
}
