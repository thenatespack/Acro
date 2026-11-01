import Engine
import Foundation

// Network play commands (EditorNetPlay.swift): start / stop a server with N clients in play mode,
// pick the world the Game View shows, set simulated link conditions per client, read every
// connection's numbers and toggle the viewport's stats overlay.
//
// ```
// net.start {clients: 2, latencyMs: 100, loss: 0.05}
// net.setConditions {client: 2, latencyMs: 250, jitterMs: 40, loss: 0.1, duplicate: 0.02}
// play.step {frames: 120}
// net.stats                                  // RTT, loss, kbit/s, snapshot sizes, buffers
// net.view {target: "client 2"}              // the Game View shows client 2's world
// view.screenshot {source: "game"}
// play.stop                                  // ends network play too
// ```

public enum EditorNetCommands {
    public static let all: [any EditorCommand.Type] = [
        NetStartCommand.self, NetStopCommand.self, NetViewCommand.self, NetSetConditionsCommand.self, NetStatsCommand.self,
        NetOverlayCommand.self,
    ]
}

/// Link conditions in tool units: milliseconds and fractions.
public struct NetLinkConditions: Codable, Equatable, Sendable {
    /// One-way latency (ms).
    public var latencyMs: Double
    /// Extra random delay, uniform in 0...jitterMs (packets reorder).
    public var jitterMs: Double
    /// Fraction of packets dropped (0-1).
    public var loss: Double
    /// Fraction of packets delivered twice (0-1).
    public var duplicate: Double

    public init(latencyMs: Double = 0, jitterMs: Double = 0, loss: Double = 0, duplicate: Double = 0) {
        self.latencyMs = latencyMs
        self.jitterMs = jitterMs
        self.loss = loss
        self.duplicate = duplicate
    }

    public init(_ conditions: LinkConditions) {
        self.init(latencyMs: conditions.latency * 1000, jitterMs: conditions.jitter * 1000, loss: conditions.loss,
                  duplicate: conditions.duplicate)
    }

    var linkConditions: LinkConditions {
        LinkConditions(latency: latencyMs / 1000, jitter: jitterMs / 1000, loss: loss, duplicate: duplicate)
    }

    static func validated(latencyMs: Double?, jitterMs: Double?, loss: Double?, duplicate: Double?,
                          base: LinkConditions = .perfect) throws -> LinkConditions {
        let latency = latencyMs ?? base.latency * 1000, jitter = jitterMs ?? base.jitter * 1000
        let loss = loss ?? base.loss, duplicate = duplicate ?? base.duplicate
        guard (0...5000).contains(latency), (0...5000).contains(jitter) else {
            throw CommandError.failed("`latencyMs` and `jitterMs` must be between 0 and 5000")
        }
        guard (0...1).contains(loss), (0...1).contains(duplicate) else {
            throw CommandError.failed("`loss` and `duplicate` are fractions between 0 and 1")
        }
        return NetLinkConditions(latencyMs: latency, jitterMs: jitter, loss: loss, duplicate: duplicate).linkConditions
    }
}

public struct NetPlayClientState: Codable, Equatable, Sendable {
    public var index: Int
    public var connected: Bool
    /// Entities replication created or matched in its world.
    public var entities: Int
    /// Server to client, and client to server.
    public var down: NetLinkConditions
    public var up: NetLinkConditions
}

/// Network play's state, which the net commands return.
public struct NetPlayStateResult: Codable, Equatable, Sendable {
    public var active: Bool
    /// What the Game View shows: "server" or "client N".
    public var view: String
    public var overlay: Bool
    /// Every entity with a Transform is replicated (the scene had no `Replicated` components).
    public var replicatesAll: Bool
    public var clients: [NetPlayClientState]

    static let inactive = NetPlayStateResult(active: false, view: "server", overlay: false, replicatesAll: false, clients: [])
}

/// `net.stats`' result.
public struct NetStatsResult: Codable, Equatable, Sendable {
    public struct Network: Codable, Equatable, Sendable {
        public var packetsSent: Int
        public var packetsDropped: Int
        public var packetsDelivered: Int
        public var bytesSent: Int
        init(_ stats: LoopbackNetwork.Stats) {
            packetsSent = stats.sent
            packetsDropped = stats.dropped
            packetsDelivered = stats.delivered
            bytesSent = stats.bytesSent
        }
    }
    /// Seconds since network play started.
    public var time: Double
    /// Each connected client as the server sees it.
    public var server: [NetStatsReport]
    /// Each client's own numbers.
    public var clients: [NetStatsReport]
    /// The simulated network's totals.
    public var network: Network
}

private let notNetPlaying = "network play isn't running (net.start first)"

extension EditorSession {
    var netPlayState: NetPlayStateResult { netPlay?.stateResult ?? .inactive }
}

public enum NetStartCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Clients (1-8, default 2).
        public var clients: Int?
        /// Every client's link, both ways (default perfect).
        public var latencyMs: Double?
        public var jitterMs: Double?
        public var loss: Double?
        public var duplicate: Double?
        /// "auto" (default), "all" or "marked"; see the doc.
        public var replicate: EditorNetPlay.Replication?
        public init(clients: Int? = nil, latencyMs: Double? = nil, jitterMs: Double? = nil, loss: Double? = nil, duplicate: Double? = nil,
                    replicate: EditorNetPlay.Replication? = nil) {
            self.clients = clients
            self.latencyMs = latencyMs
            self.jitterMs = jitterMs
            self.loss = loss
            self.duplicate = duplicate
            self.replicate = replicate
        }
    }

    public static let id: CommandID = "net.start"
    public static let title = "Play with Clients"
    public static let doc = """
        Plays the scene as a server with `clients` client worlds (1-8, default 2) in this process, on a simulated \
        network (`latencyMs` one way, `jitterMs`, `loss` and `duplicate` fractions; default perfect). Starts play mode \
        if needed; each client loaded the scene as play started, so entities are matched by id, and what the server \
        does reaches them as snapshots (30 Hz, interpolated 100 ms behind). Clients only display: systems, physics and \
        input run on the server. `replicate`: "marked" sends entities with a Replicated component; "all" gives every \
        entity with a Transform one (Transform, MeshRenderer, Name), also ones spawned later; "auto" (default) is \
        "marked" when the scene has Replicated components, else "all". Restarts network play when it runs. \
        Then: net.view, net.setConditions, net.stats; play.stop ends it.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NetPlayStateResult {
        let count = arguments.clients ?? 2
        guard (1...8).contains(count) else { throw CommandError.failed("`clients` must be between 1 and 8") }
        let conditions = try NetLinkConditions.validated(latencyMs: arguments.latencyMs, jitterMs: arguments.jitterMs,
                                                         loss: arguments.loss, duplicate: arguments.duplicate)
        session.startNetPlay(clients: count, conditions: conditions, replication: arguments.replicate ?? .auto)
        return session.netPlayState
    }
}

public enum NetStopCommand: EditorCommand {
    public static let id: CommandID = "net.stop"
    public static let title = "Stop Network Play"
    public static let doc = "Disconnects the clients and drops their worlds; play mode goes on with the server's world alone (play.stop ends both)."
    public static func isAvailable(in session: EditorSession) -> Bool { session.netPlay != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { notNetPlaying }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NetPlayStateResult {
        session.endNetPlay(reason: nil)
        return session.netPlayState
    }
}

public enum NetViewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// "server", or a client: "client 2" or "2".
        public var target: String
        public init(target: String) { self.target = target }
    }

    public static let id: CommandID = "net.view"
    public static let title = "Game View Source"
    public static let doc = """
        Which world the Game View (view.gameCamera) and view.screenshot {source: "game"} show during network play: \
        "server" (the scene's world) or a client ("client 2", or "2"), through that world's Camera entity. The scene \
        view (Game View off) always shows the server.
        """
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.netPlay != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { notNetPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NetPlayStateResult {
        guard let net = session.netPlay else { throw CommandError.failed(notNetPlaying) }
        let text = arguments.target.lowercased().trimmingCharacters(in: .whitespaces)
        if text == "server" {
            net.viewedClient = nil
        } else {
            let digits = text.hasPrefix("client") ? String(text.dropFirst(6)).trimmingCharacters(in: .whitespaces) : text
            guard let index = Int(digits), net.client(index) != nil else {
                throw CommandError.failed("No client '\(arguments.target)': use \"server\" or one of \(net.clients.map { "\"client \($0.index)\"" }.joined(separator: ", "))")
            }
            net.viewedClient = index
        }
        session.changed()
        return session.netPlayState
    }
}

public enum NetSetConditionsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The client (1...); omitted: every client.
        public var client: Int?
        /// "both" (default), "down" (server to client) or "up" (client to server).
        public var direction: String?
        /// Omitted fields keep their current value (of the first client given).
        public var latencyMs: Double?
        public var jitterMs: Double?
        public var loss: Double?
        public var duplicate: Double?
        public init(client: Int? = nil, direction: String? = nil, latencyMs: Double? = nil, jitterMs: Double? = nil,
                    loss: Double? = nil, duplicate: Double? = nil) {
            self.client = client
            self.direction = direction
            self.latencyMs = latencyMs
            self.jitterMs = jitterMs
            self.loss = loss
            self.duplicate = duplicate
        }
    }

    public static let id: CommandID = "net.setConditions"
    public static let title = "Set Network Conditions"
    public static let doc = """
        Simulated link between the server and `client` (omitted: every client), `direction` "both" (default), "down" \
        (server to client) or "up": `latencyMs` one way (0-5000), `jitterMs` (extra delay, uniform, so packets \
        reorder), `loss` and `duplicate` (fractions 0-1). Omitted fields keep their value. Applies to packets sent \
        from now on. Returns the network play state with every client's conditions.
        """
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.netPlay != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { notNetPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NetPlayStateResult {
        guard let net = session.netPlay else { throw CommandError.failed(notNetPlaying) }
        let direction = arguments.direction ?? "both"
        guard ["both", "up", "down"].contains(direction) else { throw CommandError.failed("`direction` is \"both\", \"up\" or \"down\"") }
        let first = arguments.client.flatMap { net.client($0) } ?? net.clients.first
        let base = direction == "up" ? first?.up : first?.down
        let conditions = try NetLinkConditions.validated(latencyMs: arguments.latencyMs, jitterMs: arguments.jitterMs,
                                                         loss: arguments.loss, duplicate: arguments.duplicate, base: base ?? .perfect)
        try net.setConditions(conditions, client: arguments.client, up: direction != "down", down: direction != "up")
        session.changed()
        return session.netPlayState
    }
}

public enum NetStatsCommand: EditorCommand {
    public static let id: CommandID = "net.stats"
    public static let title = "Network Stats"
    public static let doc = """
        Every connection's numbers during network play: for each client as the server sees it and as the client does, \
        RTT (ms), loss (%), bytes in / out per second (last second) and in total, packets, snapshots, the last \
        snapshot's size and deferred entities (server), the interpolation delay, what is buffered and starved frames \
        (client), its replicated entities and those waiting for their parent; plus the simulated network's totals.
        """
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.netPlay != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { notNetPlaying }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NetStatsResult {
        guard let net = session.netPlay else { throw CommandError.failed(notNetPlaying) }
        return net.statsResult
    }
}

public enum NetOverlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// true shows it, false hides it; omitted toggles.
        public var enabled: Bool?
        public init(enabled: Bool? = nil) { self.enabled = enabled }
    }

    public static let id: CommandID = "net.overlay"
    public static let title = "Network Stats Overlay"
    public static let doc = "Whether the viewport shows the network stats overlay during network play (RTT, loss, kbit/s, interpolation buffer per client). On by default."
    public static func isAvailable(in session: EditorSession) -> Bool { session.netPlay != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { notNetPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NetPlayStateResult {
        guard let net = session.netPlay else { throw CommandError.failed(notNetPlaying) }
        net.showsOverlay = arguments.enabled ?? !net.showsOverlay
        session.changed()
        return session.netPlayState
    }
}
