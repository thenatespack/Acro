// Networking (cards 624, 662): server-authoritative snapshot replication with client
// interpolation, over the connection layer in NetConnection.swift. See docs/Networking.md.
//
// Server: accepts clients through the challenge handshake; every `sendInterval` it captures the
// components named by each entity's `Replicated` into a `NetWorldState` and sends each client a
// delta against the newest state that client acknowledged (a full snapshot until it has
// acknowledged one). With a `bandwidthLimit`, a snapshot carries the changed entities with the
// highest accumulated priority that fit; the rest wait (their priority grows), so what each
// client has is tracked per client. Full snapshots (or all, see `compression`) are zlib
// compressed when that is smaller. Snapshots larger than a datagram are split into fragments;
// losing one fragment loses the snapshot, which only means the next delta is against an older
// baseline. Clients' input commands are queued per client for the game to apply on its fixed
// tick (`takeInputs`); each snapshot tells the client the newest input applied.
//
// Client: reassembles and decodes snapshots, rebuilds each full state from its baseline,
// acknowledges the newest tick, and shows the world `interpolationDelay` seconds behind the
// newest snapshot: entities, components and spawns / despawns as of the snapshot before that
// time, Transforms interpolated between the snapshots around it. Entities are matched by
// `EntityID`: the client world's entities get the server's ids. Entities in
// `predictedEntities` are left to client-side prediction (see NetPrediction.swift).

/// Marks an entity for replication and names the components sent (by `componentName`).
/// Only root entities are meaningful for now: Transforms replicate as local transforms and
/// the hierarchy isn't sent.
public struct Replicated: Component, Equatable, Sendable {
    public static let componentName = "Replicated"
    public var components: [String]
    /// How often it is sent relative to others when a snapshot can't carry every change (see
    /// `NetServer.bandwidthLimit`): it gains this much priority per snapshot it waits.
    public var priority: Float
    /// Quantized (about 14 bytes) or exact (41 bytes; for entities a client predicts).
    public var transform: NetTransformEncoding

    public init(components: [String] = [Transform.componentName], priority: Float = 1, transform: NetTransformEncoding = .quantized) {
        self.components = components
        self.priority = priority
        self.transform = transform
    }

    private enum CodingKeys: String, CodingKey { case components, priority, transform }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        components = try c.decode([String].self, forKey: .components)
        priority = try c.decodeIfPresent(Float.self, forKey: .priority) ?? 1
        transform = try c.decodeIfPresent(NetTransformEncoding.self, forKey: .transform) ?? .quantized
    }
}

/// One input command from a client: its sequence number (1, 2, ... per client) and the game's
/// bytes (for characters, `NetCharacterInput.encoded()`).
public struct NetInputCommand: Equatable, Sendable {
    public var sequence: UInt32
    public var bytes: [UInt8]
    public init(sequence: UInt32, bytes: [UInt8]) {
        self.sequence = sequence
        self.bytes = bytes
    }
}

/// Which snapshots are zlib compressed (each only when that makes it smaller).
public enum NetSnapshotCompression: Sendable {
    case none
    /// Snapshots without a baseline (joins, clients that fell behind the history).
    case fullSnapshots
    case all
}

enum NetLimitsInternal {
    /// Input commands in one client packet, and their size.
    static let maxInputsPerPacket = 64
    static let maxInputSize = 256
    /// Inputs a server queues per client before dropping new ones.
    static let maxQueuedInputs = 256
}

// MARK: Server

public enum NetServerEvent: Equatable, Sendable {
    case connected(NetClientID)
    case disconnected(NetClientID, NetDisconnectReason)
    /// A reliable message, in the order the client sent them.
    case message(NetClientID, [UInt8])
}

@MainActor
public final class NetServer {
    public let world: World
    public let transport: any NetTransport
    /// Seconds between snapshots (default 30 Hz).
    public var sendInterval: Double = 1.0 / 30.0
    /// States kept per client as possible baselines; a client whose newest ack is older gets a
    /// full snapshot.
    public var historyLength = 64
    /// Clients beyond this are denied.
    public var maxClients = 16
    /// A client that sent nothing for this long (seconds) is disconnected.
    public var timeout: Double = 5
    /// Longest silence towards a client before a keep-alive goes out.
    public var keepAliveInterval: Double = 0.1
    /// Snapshot payload bytes per second per client (after compression, before packet
    /// headers); nil for no limit. Snapshots then carry the changed entities with the highest
    /// accumulated `Replicated.priority` that fit (at least one), the rest wait.
    public var bandwidthLimit: Int?
    public var compression: NetSnapshotCompression = .fullSnapshots

    public private(set) var tick: UInt32 = 0
    /// Connected clients, in connection order.
    public var clients: [NetClientID] { clientStates.keys.sorted() }
    /// Size of the last snapshot sent to each client before compression and fragmentation.
    public private(set) var lastSnapshotBytes: [NetClientID: Int] = [:]
    /// The same after compression: the payload that was fragmented.
    public private(set) var lastSnapshotWireBytes: [NetClientID: Int] = [:]
    /// Entities with changes the last snapshot to each client had no room for.
    public private(set) var lastSnapshotDeferred: [NetClientID: Int] = [:]
    /// Components that failed to encode (logged once per name).
    public private(set) var encodeFailures: Set<String> = []
    /// Packets dropped because they didn't parse, or were handshakes with a wrong token.
    public private(set) var rejectedPackets = 0

    public func ackedTick(of client: NetClientID) -> UInt32? { clientStates[client]?.ackedTick }
    public func peer(of client: NetClientID) -> PeerID? { clientStates[client]?.peer }
    public func connectionStats(of client: NetClientID) -> NetConnectionStats? { clientStates[client]?.connection.stats }
    /// The newest input command of `client` that `takeInputs` handed out (0: none yet).
    public func lastProcessedInput(of client: NetClientID) -> UInt32? { clientStates[client]?.lastProcessedInput }

    private final class ClientState {
        let id: NetClientID
        let peer: PeerID
        let connection: NetConnection
        /// The client sent a connected packet (it has its `accepted`).
        var confirmed = false
        var lastAcceptedSent = -Double.infinity
        var ackedTick: UInt32?
        /// What the client has after each snapshot sent to it.
        var sent: [UInt32: NetWorldState] = [:]
        var priority: [EntityID: Float] = [:]
        /// Wire / raw size of recent snapshots (for the budget).
        var compressionRatio: Double = 1
        var pendingInputs: [UInt32: [UInt8]] = [:]
        var lastProcessedInput: UInt32 = 0

        init(id: NetClientID, peer: PeerID, now: Double) {
            self.id = id
            self.peer = peer
            connection = NetConnection(now: now)
        }
    }
    private var clientStates: [NetClientID: ClientState] = [:]
    private var clientsByPeer: [PeerID: NetClientID] = [:]
    private var nextClientID: UInt32 = 1
    private var events: [NetServerEvent] = []
    private var nextSendTime: Double?
    private var now: Double = 0
    private let secret: UInt64

    /// `secret` keys the handshake's challenge tokens (random by default).
    public init(world: World, transport: any NetTransport, secret: UInt64? = nil) {
        self.world = world
        self.transport = transport
        var generator = SystemRandomNumberGenerator()
        self.secret = secret ?? generator.next()
    }

    /// Handles incoming packets, times out silent clients, sends a snapshot when one is due and
    /// keep-alives. Call every frame (or fixed step) with the server's simulation time.
    public func update(time: Double) {
        receive(time: time)
        for client in clients {
            guard let state = clientStates[client], time - state.connection.lastReceiveTime > timeout else { continue }
            remove(client, reason: .timedOut)
        }
        if time >= (nextSendTime ?? time) {
            sendSnapshot(time: time)
            // Keep the cadence; skip ahead after a stall instead of bursting.
            let next = (nextSendTime ?? time) + sendInterval
            nextSendTime = next > time ? next : time + sendInterval
        }
        for client in clients {
            guard let state = clientStates[client] else { continue }
            if !state.confirmed, time - state.lastAcceptedSent >= 0.1 {
                state.lastAcceptedSent = time
                sendConnected(.accepted, to: state) { $0.u32(state.id.value) }
            } else if time - state.connection.lastSendTime >= keepAliveInterval || state.connection.hasMessagesDue(now: time) {
                sendConnected(.keepAlive, to: state, budget: NetLimits.maxDatagramSize - NetPacket.headerSize)
            }
        }
    }

    /// Events since the last call: connections, disconnections, messages.
    public func pollEvents() -> [NetServerEvent] {
        defer { events = [] }
        return events
    }

    /// Queues a reliable, ordered message to `client` (at most 1000 bytes); false if it can't.
    @discardableResult
    public func send(message: [UInt8], to client: NetClientID) -> Bool {
        clientStates[client]?.connection.send(message: message) ?? false
    }

    /// Disconnects `client` (it is told so, if the packets get through).
    public func disconnect(_ client: NetClientID) {
        guard let state = clientStates[client] else { return }
        for _ in 0..<3 { sendConnected(.disconnect, to: state) { $0.u8(NetDisconnectReason.kicked.rawValue) } }
        remove(client, reason: .kicked)
    }

    /// The next input commands of `client` in order (at most `max`), marking them processed: the
    /// game applies each for one fixed step. Commands that never arrived are skipped.
    public func takeInputs(from client: NetClientID, max: Int = 1) -> [NetInputCommand] {
        guard let state = clientStates[client], max > 0 else { return [] }
        let sequences = state.pendingInputs.keys.sorted().prefix(max)
        var commands: [NetInputCommand] = []
        for sequence in sequences {
            commands.append(NetInputCommand(sequence: sequence, bytes: state.pendingInputs.removeValue(forKey: sequence)!))
            state.lastProcessedInput = sequence
        }
        return commands
    }

    /// Input commands of `client` received but not taken yet.
    public func queuedInputCount(of client: NetClientID) -> Int { clientStates[client]?.pendingInputs.count ?? 0 }

    public func receive() { receive(time: now) }

    public func receive(time: Double) {
        now = max(now, time)
        for datagram in transport.receive() {
            guard let (kind, parsed) = NetPacket.parse(datagram.bytes) else {
                rejectedPackets += 1
                continue
            }
            var reader = parsed
            do {
                try handle(kind, &reader, from: datagram.from, size: datagram.bytes.count)
            } catch {
                rejectedPackets += 1
            }
        }
    }

    private func handle(_ kind: NetPacket.Kind, _ r: inout ByteReader, from peer: PeerID, size: Int) throws {
        let bucket = UInt64(max(0, now) / 10)
        switch kind {
        case .connectRequest:
            guard size >= NetPacket.connectRequestSize else { throw NetError.malformed("short request") }
            let salt = try r.u64()
            if let id = clientsByPeer[peer] {
                clientStates[id]?.lastAcceptedSent = -.infinity
                return
            }
            if clientStates.count >= maxClients {
                transport.send(NetPacket.make(.denied) { $0.u64(salt); $0.u8(NetDisconnectReason.serverFull.rawValue) }, to: peer)
                return
            }
            let token = NetPacket.challengeToken(secret: secret, peer: peer, salt: salt, bucket: bucket)
            transport.send(NetPacket.make(.challenge) { $0.u64(salt); $0.u64(token) }, to: peer)
        case .challengeResponse:
            guard size >= NetPacket.connectRequestSize else { throw NetError.malformed("short response") }
            let salt = try r.u64()
            let token = try r.u64()
            guard token == NetPacket.challengeToken(secret: secret, peer: peer, salt: salt, bucket: bucket)
                    || (bucket > 0 && token == NetPacket.challengeToken(secret: secret, peer: peer, salt: salt, bucket: bucket - 1)) else {
                throw NetError.malformed("challenge token")
            }
            if let id = clientsByPeer[peer] {
                clientStates[id]?.lastAcceptedSent = -.infinity
                return
            }
            if clientStates.count >= maxClients {
                transport.send(NetPacket.make(.denied) { $0.u64(salt); $0.u8(NetDisconnectReason.serverFull.rawValue) }, to: peer)
                return
            }
            let id = NetClientID(nextClientID)
            nextClientID += 1
            let state = ClientState(id: id, peer: peer, now: now)
            clientStates[id] = state
            clientsByPeer[peer] = id
            events.append(.connected(id))
            state.lastAcceptedSent = now
            sendConnected(.accepted, to: state) { $0.u32(id.value) }
        case .challenge, .denied, .accepted, .snapshotFragment:
            throw NetError.malformed("server-bound kind")
        case .keepAlive, .disconnect, .clientUpdate:
            guard let id = clientsByPeer[peer], let state = clientStates[id] else { return } // not connected: no answer
            try state.connection.readHeader(&r, now: now, packetSize: size)
            state.confirmed = true
            for message in state.connection.delivered { events.append(.message(id, message)) }
            state.connection.delivered = []
            switch kind {
            case .disconnect:
                remove(id, reason: .requested)
            case .clientUpdate:
                try readClientUpdate(&r, state)
            default:
                break
            }
        }
    }

    private func readClientUpdate(_ r: inout ByteReader, _ state: ClientState) throws {
        let ack = try r.u32()
        let newest = try r.u32()
        let count = try r.varint(max: NetLimitsInternal.maxInputsPerPacket)
        guard UInt32(count) <= newest else { throw NetError.malformed("input count") }
        var inputs: [(UInt32, [UInt8])] = []
        for i in 0..<count {
            inputs.append((newest - UInt32(count - 1 - i), try r.bytes(r.varint(max: NetLimitsInternal.maxInputSize))))
        }
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        // Acks can arrive out of order: keep the newest that is still a baseline.
        if ack > 0, ack <= tick, ack > (state.ackedTick ?? 0), state.sent[ack] != nil { state.ackedTick = ack }
        for (sequence, bytes) in inputs where sequence > state.lastProcessedInput && state.pendingInputs[sequence] == nil {
            guard state.pendingInputs.count < NetLimitsInternal.maxQueuedInputs else { break }
            state.pendingInputs[sequence] = bytes
        }
    }

    private func remove(_ client: NetClientID, reason: NetDisconnectReason) {
        guard let state = clientStates.removeValue(forKey: client) else { return }
        clientsByPeer[state.peer] = nil
        lastSnapshotBytes[client] = nil
        lastSnapshotWireBytes[client] = nil
        lastSnapshotDeferred[client] = nil
        events.append(.disconnected(client, reason))
    }

    /// Sends a connected packet: packet header, connection header (acks, due messages), body.
    private func sendConnected(_ kind: NetPacket.Kind, to state: ClientState, budget: Int = NetPacket.connectionHeaderReserve,
                               _ body: (inout ByteWriter) -> Void = { _ in }) {
        let packet = NetPacket.make(kind) { w in
            state.connection.writeHeader(&w, now: now, budget: budget)
            body(&w)
        }
        state.connection.didSend(bytes: packet.count, now: now)
        transport.send(packet, to: state.peer)
    }

    // MARK: Snapshots

    /// The replicated state now: every entity with `Replicated`, by id (given one if needed).
    public func captureState() -> NetWorldState { capture().state }

    private func capture() -> (state: NetWorldState, priorities: [EntityID: Float]) {
        var state: NetWorldState = [:]
        var priorities: [EntityID: Float] = [:]
        var replicatedEntities: [(Entity, Replicated)] = []
        world.query(Replicated.self) { replicatedEntities.append(($0, $1)) }
        for (entity, replicated) in replicatedEntities {
            guard let id = world.ensureID(of: entity) else { continue }
            var components: [String: [UInt8]] = [:]
            for name in replicated.components {
                guard let component = world.component(named: name, of: entity) else { continue }
                do {
                    components[name] = try NetComponentCoder.encode(component, transform: replicated.transform)
                } catch {
                    if encodeFailures.insert(name).inserted { EngineLog.warning("can't encode \(name): \(error)", category: "net") }
                }
            }
            state[id] = components
            priorities[id] = replicated.priority
        }
        return (state, priorities)
    }

    /// Captures the state and sends every client its delta.
    public func sendSnapshot(time: Double) {
        now = max(now, time)
        tick += 1
        let (state, priorities) = capture()
        for client in clients {
            guard let c = clientStates[client] else { continue }
            let baseline = c.ackedTick.flatMap { c.sent[$0] }
            var snapshot = NetSnapshot(tick: tick, serverTime: time, state: state, baseline: baseline, baselineTick: c.ackedTick)
            var deferred = 0
            if let limit = bandwidthLimit {
                let budget = Int(Double(limit) * sendInterval / max(0.2, c.compressionRatio))
                (snapshot, deferred) = prioritized(snapshot, baseline: baseline, priorities: priorities, client: c, budget: budget)
                c.sent[tick] = snapshot.applied(to: baseline)
            } else {
                c.sent[tick] = state
            }
            if tick > UInt32(historyLength) { c.sent[tick - UInt32(historyLength)] = nil }
            let raw = snapshot.encoded(baseline: baseline)
            var flags: UInt8 = 0
            var body = raw
            let compress = compression == .all || (compression == .fullSnapshots && snapshot.baselineTick == nil)
            if compress, raw.count > 64 {
                let packed = NetCompression.deflate(raw)
                if packed.count < raw.count {
                    flags |= 1
                    body = packed
                }
            }
            c.compressionRatio += (Double(body.count) / Double(max(raw.count, 1)) - c.compressionRatio) * 0.2
            var w = ByteWriter()
            w.u8(flags)
            w.u32(c.lastProcessedInput)
            w.bytes(body)
            lastSnapshotBytes[client] = raw.count
            lastSnapshotWireBytes[client] = body.count
            lastSnapshotDeferred[client] = deferred
            sendFragments(w.data, tick: tick, to: c)
        }
    }

    /// The part of `snapshot` that fits `budget` bytes: removals, then changed entities by
    /// accumulated priority (ties by id), skipping ones that don't fit; at least one.
    private func prioritized(_ snapshot: NetSnapshot, baseline: NetWorldState?, priorities: [EntityID: Float],
                             client: ClientState, budget: Int) -> (NetSnapshot, deferred: Int) {
        for id in client.priority.keys where snapshot.changed[id] == nil { client.priority[id] = nil }
        var candidates: [(id: EntityID, priority: Float, cost: Int)] = []
        for (id, diff) in snapshot.changed {
            let priority = client.priority[id, default: 0] + (priorities[id] ?? 1)
            client.priority[id] = priority
            candidates.append((id, priority, NetSnapshot.entrySize(diff, base: baseline?[id])))
        }
        candidates.sort { $0.priority != $1.priority ? $0.priority > $1.priority : $0.id < $1.id }
        let names = Set(snapshot.changed.values.flatMap(\.keys)).reduce(0) { $0 + $1.utf8.count + 1 }
        var size = 20 + names + snapshot.removed.count * 2
        var chosen: [EntityID: [String: [UInt8]?]] = [:]
        for candidate in candidates where chosen.isEmpty || size + candidate.cost <= budget {
            chosen[candidate.id] = snapshot.changed[candidate.id]
            client.priority[candidate.id] = nil
            size += candidate.cost
        }
        var limited = snapshot
        limited.changed = chosen
        return (limited, candidates.count - chosen.count)
    }

    private func sendFragments(_ payload: [UInt8], tick: UInt32, to client: ClientState) {
        let size = NetPacket.maxFragmentPayload
        let count = max(1, (payload.count + size - 1) / size)
        guard count <= 255 else {
            EngineLog.warning("snapshot of \(payload.count) bytes is over 255 fragments; not sent", category: "net")
            return
        }
        for index in 0..<count {
            let chunk = payload[(index * size)..<min(payload.count, (index + 1) * size)]
            sendConnected(.snapshotFragment, to: client) { w in
                w.u32(tick)
                w.u8(UInt8(index))
                w.u8(UInt8(count))
                w.bytes(Array(chunk))
            }
        }
    }
}

// MARK: Client

public enum NetClientEvent: Equatable, Sendable {
    case connected(NetClientID)
    case disconnected(NetDisconnectReason)
    /// A reliable message, in the order the server sent them.
    case message([UInt8])
}

public enum NetClientState: Equatable, Sendable {
    case connecting
    case connected(NetClientID)
    case disconnected(NetDisconnectReason)
}

/// One entity in the newest snapshot (what prediction reconciles to).
public struct NetReceivedEntity: Sendable {
    public var tick: UInt32
    public var serverTime: Double
    /// The newest of this client's input commands the server had applied.
    public var inputAck: UInt32
    public var components: [String: [UInt8]]
}

@MainActor
public final class NetClient {
    public let world: World
    public let transport: any NetTransport
    public let server: PeerID
    /// How far behind the newest snapshot the world is shown. Two to three snapshot intervals
    /// ride out a lost snapshot or two without stalling.
    public var interpolationDelay: Double = 0.1
    /// Received states kept for interpolation and as delta baselines.
    public var historyLength = 64
    /// Give up connecting after this long (seconds).
    public var connectTimeout: Double = 5
    /// Disconnect when nothing arrived from the server for this long.
    public var timeout: Double = 5
    /// Longest silence towards the server before a keep-alive goes out.
    public var keepAliveInterval: Double = 0.1
    /// Unacknowledged input commands resent in every packet (newest first): covers this many
    /// fixed steps of consecutive loss.
    public var inputsPerPacket = 16
    /// Entities the game predicts itself: spawned with the server's components, then their
    /// `predictedComponents` are left alone (see `NetCharacterPrediction`).
    public var predictedEntities: Set<EntityID> = []
    public var predictedComponents: Set<String> = [Transform.componentName, CharacterController.componentName]

    public struct Stats: Equatable, Sendable {
        /// Snapshots decoded and stored.
        public var snapshots = 0
        /// Snapshots that arrived complete but whose baseline the client no longer had.
        public var missingBaseline = 0
        /// Packets that didn't parse.
        public var malformed = 0
        /// Frames where the render time had caught up with the newest snapshot (nothing to
        /// interpolate towards: the world holds still).
        public var starvedFrames = 0
        /// Snapshot payload bytes received (after compression).
        public var snapshotBytes = 0
    }
    public private(set) var stats = Stats()
    public private(set) var state: NetClientState = .connecting
    public var clientID: NetClientID? {
        if case .connected(let id) = state { return id }
        return nil
    }
    /// The client's own clock: the sum of `update` dts.
    public private(set) var time: Double = 0
    /// The server time the world currently shows; nil until the first snapshot.
    public private(set) var renderTime: Double?
    /// The newest snapshot's tick and server time.
    public private(set) var latestTick: UInt32?
    public var latestServerTime: Double? { states.last?.time }
    public var connectionStats: NetConnectionStats? { connection?.stats }
    /// The newest input command the server had applied, as of the newest snapshot.
    public var latestInputAck: UInt32? { states.last?.inputAck }

    private struct ReceivedState {
        var tick: UInt32
        var time: Double
        var inputAck: UInt32
        var state: NetWorldState
    }
    /// Sorted by tick.
    private var states: [ReceivedState] = []
    private var fragments: [UInt32: [Int: [UInt8]]] = [:]
    private var applied: [EntityID: [String: [UInt8]]] = [:]
    private let salt: UInt64
    private var token: UInt64?
    private var lastHandshake: Double = 0
    private var connection: NetConnection?
    private var events: [NetClientEvent] = []
    private var ackDue = false
    private var inputs: [(sequence: UInt32, bytes: [UInt8])] = []
    private var nextInput: UInt32 = 1
    private var inputsDue = false

    /// Starts connecting to `server` (the handshake runs in `update`).
    public init(world: World, transport: any NetTransport, server: PeerID, salt: UInt64? = nil) {
        self.world = world
        self.transport = transport
        self.server = server
        var generator = SystemRandomNumberGenerator()
        self.salt = salt ?? generator.next()
        sendHandshake()
    }

    /// Events since the last call: connected, disconnected, messages.
    public func pollEvents() -> [NetClientEvent] {
        defer { events = [] }
        return events
    }

    /// Queues a reliable, ordered message to the server (at most 1000 bytes); false if it can't
    /// (not connected, too big).
    @discardableResult
    public func send(message: [UInt8]) -> Bool { connection?.send(message: message) ?? false }

    /// Says goodbye to the server and stops.
    public func disconnect() {
        if let connection {
            for _ in 0..<3 { sendConnected(.disconnect, connection) { $0.u8(NetDisconnectReason.requested.rawValue) } }
        }
        close(.requested)
    }

    /// Queues an input command (sent with the next packets until the server acknowledges it)
    /// and returns its sequence number.
    @discardableResult
    public func sendInput(_ bytes: [UInt8]) -> UInt32 {
        precondition(bytes.count <= NetLimitsInternal.maxInputSize, "input command of \(bytes.count) bytes")
        let sequence = nextInput
        nextInput += 1
        inputs.append((sequence, bytes))
        if inputs.count > NetLimitsInternal.maxQueuedInputs { inputs.removeFirst(inputs.count - NetLimitsInternal.maxQueuedInputs) }
        inputsDue = true
        return sequence
    }

    /// The newest snapshot's state of entity `id`.
    public func newestState(of id: EntityID) -> NetReceivedEntity? {
        guard let last = states.last, let components = last.state[id] else { return nil }
        return NetReceivedEntity(tick: last.tick, serverTime: last.time, inputAck: last.inputAck, components: components)
    }

    /// Advances the clock, runs the handshake, receives snapshots, applies the interpolated
    /// state to `world` and sends acks, inputs and messages. Call once per frame.
    public func update(dt: Double) {
        time += dt
        if case .disconnected = state { return }
        if connection == nil {
            if time >= connectTimeout {
                close(.connectTimedOut)
                return
            }
            if time - lastHandshake >= 0.1 { sendHandshake() }
        }
        receive()
        if let connection, time - connection.lastReceiveTime > timeout {
            close(.timedOut)
            return
        }
        advanceClock(dt: dt)
        apply()
        flush()
    }

    /// Sends what is due now: a client update when there are inputs, a snapshot ack or
    /// messages, a keep-alive after `keepAliveInterval` of silence.
    public func flush() {
        guard let connection, clientID != nil else { return }
        if inputsDue || ackDue || connection.hasMessagesDue(now: time) {
            let pending = inputs.suffix(min(inputsPerPacket, NetLimitsInternal.maxInputsPerPacket))
            let inputBytes = pending.reduce(0) { $0 + $1.bytes.count + 2 }
            sendConnected(.clientUpdate, connection, budget: NetLimits.maxDatagramSize - NetPacket.headerSize - 16 - inputBytes) { w in
                w.u32(self.latestTick ?? 0)
                w.u32(pending.last?.sequence ?? 0)
                w.varint(pending.count)
                for input in pending {
                    w.varint(input.bytes.count)
                    w.bytes(input.bytes)
                }
            }
            inputsDue = false
            ackDue = false
        } else if time - connection.lastSendTime >= keepAliveInterval {
            sendConnected(.keepAlive, connection)
        }
    }

    private func sendHandshake() {
        lastHandshake = time
        if let token {
            transport.send(NetPacket.padded(NetPacket.make(.challengeResponse) { $0.u64(self.salt); $0.u64(token) }), to: server)
        } else {
            transport.send(NetPacket.padded(NetPacket.make(.connectRequest) { $0.u64(self.salt) }), to: server)
        }
    }

    private func sendConnected(_ kind: NetPacket.Kind, _ connection: NetConnection, budget: Int = NetPacket.connectionHeaderReserve,
                               _ body: (inout ByteWriter) -> Void = { _ in }) {
        let packet = NetPacket.make(kind) { w in
            connection.writeHeader(&w, now: time, budget: budget)
            body(&w)
        }
        connection.didSend(bytes: packet.count, now: time)
        transport.send(packet, to: server)
    }

    private func close(_ reason: NetDisconnectReason) {
        if case .disconnected = state { return }
        state = .disconnected(reason)
        events.append(.disconnected(reason))
    }

    public func receive() {
        var newest: UInt32?
        for datagram in transport.receive() where datagram.from == server {
            guard let (kind, parsed) = NetPacket.parse(datagram.bytes) else {
                stats.malformed += 1
                continue
            }
            var reader = parsed
            do {
                if let tick = try handle(kind, &reader, size: datagram.bytes.count) { newest = max(newest ?? 0, tick) }
            } catch {
                stats.malformed += 1
            }
            if case .disconnected = state { return }
        }
        if let newest {
            latestTick = max(latestTick ?? 0, newest)
            ackDue = true
        }
        // Forget incomplete snapshots too old to matter.
        if let latestTick, latestTick > UInt32(historyLength) {
            let cutoff = latestTick - UInt32(historyLength)
            fragments = fragments.filter { $0.key > cutoff }
        }
    }

    /// Handles one packet; returns the tick of a snapshot it completed.
    private func handle(_ kind: NetPacket.Kind, _ r: inout ByteReader, size: Int) throws -> UInt32? {
        switch kind {
        case .challenge:
            guard connection == nil, try r.u64() == salt else { return nil }
            if token == nil {
                token = try r.u64()
                sendHandshake()
            }
            return nil
        case .denied:
            guard connection == nil, try r.u64() == salt, let reason = NetDisconnectReason(rawValue: try r.u8()) else { return nil }
            close(reason)
            return nil
        case .accepted, .keepAlive, .disconnect, .snapshotFragment:
            if connection == nil {
                guard kind == .accepted, token != nil else { return nil }
                connection = NetConnection(now: time)
            }
            let connection = connection!
            try connection.readHeader(&r, now: time, packetSize: size)
            for message in connection.delivered { events.append(.message(message)) }
            connection.delivered = []
            switch kind {
            case .accepted:
                let id = NetClientID(try r.u32())
                if clientID == nil {
                    state = .connected(id)
                    events.append(.connected(id))
                    ackDue = true // confirms the connection
                }
            case .disconnect:
                close(NetDisconnectReason(rawValue: try r.u8()) ?? .kicked)
            case .snapshotFragment:
                guard clientID != nil else { return nil }
                return try receiveFragment(&r)
            default:
                break
            }
            return nil
        case .connectRequest, .challengeResponse, .clientUpdate:
            throw NetError.malformed("client-bound kind")
        }
    }

    private func receiveFragment(_ r: inout ByteReader) throws -> UInt32? {
        let tick = try r.u32()
        let index = try r.u8()
        let count = try r.u8()
        guard index < count else { throw NetError.malformed("fragment index") }
        let chunk = r.rest()
        if let latestTick, tick <= latestTick, states.contains(where: { $0.tick == tick }) { return nil } // duplicate
        fragments[tick, default: [:]][Int(index)] = chunk
        guard let parts = fragments[tick], parts.count == Int(count) else { return nil }
        fragments[tick] = nil
        var payload = ByteReader((0..<Int(count)).flatMap { parts[$0] ?? [] })
        let flags = try payload.u8()
        let inputAck = try payload.u32()
        var body = payload.rest()
        if flags & 1 != 0 { body = try NetCompression.inflate(body) }
        stats.snapshotBytes += payload.data.count
        let header = try NetSnapshot.header(of: body)
        var baseline: NetWorldState?
        if let baseTick = header.baselineTick {
            guard let base = states.first(where: { $0.tick == baseTick }) else {
                stats.missingBaseline += 1
                return nil
            }
            baseline = base.state
        }
        let snapshot = try NetSnapshot(decoding: body, baseline: baseline)
        insert(ReceivedState(tick: snapshot.tick, time: snapshot.serverTime, inputAck: inputAck, state: snapshot.applied(to: baseline)))
        stats.snapshots += 1
        if let newest = states.last?.inputAck { inputs.removeAll { $0.sequence <= newest } }
        return snapshot.tick
    }

    private func insert(_ received: ReceivedState) {
        let index = states.firstIndex { $0.tick > received.tick } ?? states.count
        states.insert(received, at: index)
        if states.count > historyLength { states.removeFirst(states.count - historyLength) }
    }

    private func advanceClock(dt: Double) {
        guard let latest = states.last?.time else { return }
        let target = latest - interpolationDelay
        guard let current = renderTime, abs(target - current) < 0.25 else {
            renderTime = target
            return
        }
        // Run at real speed, steering gently towards the target so the delay holds without
        // visible speed changes (the target jumps by a snapshot interval at a time).
        var next = current + dt
        next += (target - next) * min(1, dt * 2)
        if next >= latest {
            next = latest
            stats.starvedFrames += 1
        }
        renderTime = max(current, next)
    }

    private func apply() {
        guard let time = renderTime, let firstState = states.first else { return }
        // a: the newest state at or before the render time; b: the next one.
        let bIndex = states.firstIndex { $0.time > time }
        let a = bIndex.map { $0 > 0 ? states[$0 - 1] : firstState } ?? states.last!
        let b = bIndex.map { states[$0] }
        let t: Float = b.map { b in b.time > a.time ? Float((time - a.time) / (b.time - a.time)) : 0 } ?? 0

        // Sorted: spawn order (and so storage and draw order) the same in every run.
        for id in a.state.keys.sorted() {
            let components = a.state[id]!
            let entity: Entity
            var spawned = false
            if let existing = world.entity(for: id) {
                entity = existing
            } else {
                entity = world.spawn()
                world.setEntityID(id, for: entity)
                spawned = true
            }
            let predicted = predictedEntities.contains(id)
            var previous = applied[id] ?? [:]
            for (name, bytes) in components where name != Transform.componentName && previous[name] != bytes {
                if predicted && !spawned && predictedComponents.contains(name) { continue }
                do {
                    let component = try NetComponentCoder.decode(bytes, as: name)
                    world.add(component, to: entity)
                    previous[name] = bytes
                } catch {
                    EngineLog.warning("can't decode \(name): \(error)", category: "net")
                }
            }
            for name in previous.keys where components[name] == nil {
                if let type = ComponentRegistry.type(named: name) { world.remove(type, from: entity) }
                previous[name] = nil
            }
            applied[id] = previous
            if predicted && !spawned && predictedComponents.contains(Transform.componentName) { continue }
            if let bytes = components[Transform.componentName], let from = try? NetComponentCoder.decodeTransform(bytes) {
                var transform = from
                // (Unchanged: exactly the snapshot's value; slerp would renormalize it.)
                if let next = b?.state[id]?[Transform.componentName], next != bytes, let to = try? NetComponentCoder.decodeTransform(next) {
                    transform = Transform.interpolated(from, to, t)
                }
                world.add(transform, to: entity)
            }
        }
        for id in applied.keys.sorted() where a.state[id] == nil {
            if let entity = world.entity(for: id) { world.despawn(entity) }
            applied[id] = nil
        }
    }
}

extension Transform {
    /// Position and scale lerped, rotation slerped.
    public static func interpolated(_ a: Transform, _ b: Transform, _ t: Float) -> Transform {
        Transform(position: a.position + (b.position - a.position) * t,
                  rotation: Quat.slerp(a.rotation, b.rotation, t),
                  scale: a.scale + (b.scale - a.scale) * t)
    }
}
