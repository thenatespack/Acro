// Networking prototype (card 624): server-authoritative snapshot replication with client
// interpolation. See docs/Networking.md for the design and what is left out.
//
// Server: every `sendInterval` it captures the components named by each entity's
// `Replicated` into a `NetWorldState`, keeps the last `historyLength` states, and sends each
// client a delta against the newest state that client acknowledged (a full snapshot until it
// has acknowledged one). Snapshots larger than a datagram are split into fragments; losing
// one fragment loses the snapshot, which only means the next delta is against an older
// baseline.
//
// Client: reassembles and decodes snapshots, rebuilds each full state from its baseline,
// acknowledges the newest tick, and shows the world `interpolationDelay` seconds behind the
// newest snapshot: entities, components and spawns / despawns as of the snapshot before that
// time, Transforms interpolated between the snapshots around it. Entities are matched by
// `EntityID`: the client world's entities get the server's ids.

/// Marks an entity for replication and names the components sent (by `componentName`).
/// Only root entities are meaningful for now: Transforms replicate as local transforms and
/// the hierarchy isn't sent.
public struct Replicated: Component, Equatable, Sendable {
    public static let componentName = "Replicated"
    public var components: [String]

    public init(components: [String] = [Transform.componentName]) {
        self.components = components
    }
}

enum NetPacket {
    static let magic: [UInt8] = [0x53, 0x4E] // "SN"
    static let version: UInt8 = 1
    static let headerSize = 4

    enum Kind: UInt8 {
        case hello = 1
        case snapshotFragment = 2
        case ack = 3
    }

    static func make(_ kind: Kind, _ body: (inout ByteWriter) -> Void = { _ in }) -> [UInt8] {
        var w = ByteWriter()
        w.bytes(magic)
        w.u8(version)
        w.u8(kind.rawValue)
        body(&w)
        return w.data
    }

    /// The kind and a reader positioned after the header, or nil for foreign / old packets.
    static func parse(_ bytes: [UInt8]) -> (Kind, ByteReader)? {
        guard bytes.count >= headerSize, bytes[0] == magic[0], bytes[1] == magic[1], bytes[2] == version,
              let kind = Kind(rawValue: bytes[3]) else { return nil }
        var reader = ByteReader(bytes)
        reader.offset = headerSize
        return (kind, reader)
    }

    /// Fragment header after the packet header: tick u32, index u8, count u8.
    static let fragmentHeaderSize = 6
    static let maxFragmentPayload = NetLimits.maxDatagramSize - headerSize - fragmentHeaderSize
}

// MARK: Server

@MainActor
public final class NetServer {
    public let world: World
    public let transport: any NetTransport
    /// Seconds between snapshots (default 30 Hz).
    public var sendInterval: Double = 1.0 / 30.0
    /// States kept as possible baselines; a client whose newest ack is older gets a full snapshot.
    public var historyLength = 64

    public private(set) var tick: UInt32 = 0
    public var clients: [PeerID] { clientStates.keys.sorted { $0.value < $1.value } }
    /// Encoded snapshot size (before fragmentation) of the last snapshot sent to each client.
    public private(set) var lastSnapshotBytes: [PeerID: Int] = [:]
    /// The ack each client last sent.
    public func ackedTick(of client: PeerID) -> UInt32? { clientStates[client]?.ackedTick }
    /// Components that failed to encode (logged once per name).
    public private(set) var encodeFailures: Set<String> = []

    private struct ClientState { var ackedTick: UInt32? }
    private var clientStates: [PeerID: ClientState] = [:]
    private var history: [UInt32: NetWorldState] = [:]
    private var nextSendTime: Double?

    public init(world: World, transport: any NetTransport) {
        self.world = world
        self.transport = transport
    }

    /// Handles incoming packets and sends a snapshot when one is due. Call every frame (or
    /// fixed step) with the server's simulation time.
    public func update(time: Double) {
        receive()
        if time >= (nextSendTime ?? time) {
            sendSnapshot(time: time)
            // Keep the cadence; skip ahead after a stall instead of bursting.
            let next = (nextSendTime ?? time) + sendInterval
            nextSendTime = next > time ? next : time + sendInterval
        }
    }

    public func receive() {
        for datagram in transport.receive() {
            guard var (kind, reader) = NetPacket.parse(datagram.bytes) else { continue }
            switch kind {
            case .hello:
                if clientStates[datagram.from] == nil { clientStates[datagram.from] = ClientState() }
            case .ack:
                guard let tick = try? reader.u32(), let client = clientStates[datagram.from] else { continue }
                // Acks can arrive out of order: keep the newest (ticks start at 1).
                if tick <= self.tick, tick > (client.ackedTick ?? 0) { clientStates[datagram.from]?.ackedTick = tick }
            case .snapshotFragment:
                continue
            }
        }
    }

    /// The replicated state now: every entity with `Replicated`, by id (given one if needed).
    public func captureState() -> NetWorldState {
        var state: NetWorldState = [:]
        var replicatedEntities: [(Entity, Replicated)] = []
        world.query(Replicated.self) { replicatedEntities.append(($0, $1)) }
        for (entity, replicated) in replicatedEntities {
            guard let id = world.ensureID(of: entity) else { continue }
            var components: [String: [UInt8]] = [:]
            for name in replicated.components {
                guard let component = world.component(named: name, of: entity) else { continue }
                do {
                    components[name] = try NetComponentCoder.encode(component)
                } catch {
                    if encodeFailures.insert(name).inserted { EngineLog.warning("can't encode \(name): \(error)", category: "net") }
                }
            }
            state[id] = components
        }
        return state
    }

    /// Captures the state and sends every client its delta.
    public func sendSnapshot(time: Double) {
        tick += 1
        let state = captureState()
        history[tick] = state
        if tick > UInt32(historyLength) { history[tick - UInt32(historyLength)] = nil }
        for peer in clients {
            let acked = clientStates[peer]?.ackedTick
            let baseline = acked.flatMap { history[$0] }
            let snapshot = NetSnapshot(tick: tick, serverTime: time, state: state, baseline: baseline, baselineTick: acked)
            let payload = snapshot.encoded()
            lastSnapshotBytes[peer] = payload.count
            send(payload, tick: tick, to: peer)
        }
    }

    private func send(_ payload: [UInt8], tick: UInt32, to peer: PeerID) {
        let size = NetPacket.maxFragmentPayload
        let count = max(1, (payload.count + size - 1) / size)
        guard count <= 255 else {
            EngineLog.warning("snapshot of \(payload.count) bytes is over 255 fragments; not sent", category: "net")
            return
        }
        for index in 0..<count {
            let chunk = payload[(index * size)..<min(payload.count, (index + 1) * size)]
            transport.send(NetPacket.make(.snapshotFragment) { w in
                w.u32(tick)
                w.u8(UInt8(index))
                w.u8(UInt8(count))
                w.bytes(Array(chunk))
            }, to: peer)
        }
    }
}

// MARK: Client

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
    }
    public private(set) var stats = Stats()
    /// The server time the world currently shows; nil until the first snapshot.
    public private(set) var renderTime: Double?
    /// The newest snapshot's tick and server time.
    public private(set) var latestTick: UInt32?
    public var latestServerTime: Double? { states.last?.time }

    private struct ReceivedState {
        var tick: UInt32
        var time: Double
        var state: NetWorldState
    }
    /// Sorted by tick.
    private var states: [ReceivedState] = []
    private var fragments: [UInt32: [Int: [UInt8]]] = [:]
    private var applied: [EntityID: [String: [UInt8]]] = [:]
    private var helloTimer: Double = 0

    public init(world: World, transport: any NetTransport, server: PeerID) {
        self.world = world
        self.transport = transport
        self.server = server
        transport.send(NetPacket.make(.hello), to: server)
    }

    /// Receives snapshots, advances the render clock by `dt` and applies the interpolated
    /// state to `world`. Call once per frame.
    public func update(dt: Double) {
        if states.isEmpty {
            helloTimer += dt
            if helloTimer >= 0.25 {
                helloTimer = 0
                transport.send(NetPacket.make(.hello), to: server)
            }
        }
        receive()
        advanceClock(dt: dt)
        apply()
    }

    public func receive() {
        var newest: UInt32?
        for datagram in transport.receive() where datagram.from == server {
            guard var (kind, reader) = NetPacket.parse(datagram.bytes), kind == .snapshotFragment else {
                stats.malformed += 1
                continue
            }
            guard let tick = try? reader.u32(), let index = try? reader.u8(), let count = try? reader.u8(),
                  index < count, let chunk = try? reader.bytes(datagram.bytes.count - reader.offset) else {
                stats.malformed += 1
                continue
            }
            if let latestTick, tick <= latestTick, states.contains(where: { $0.tick == tick }) { continue } // duplicate
            fragments[tick, default: [:]][Int(index)] = chunk
            guard let parts = fragments[tick], parts.count == Int(count) else { continue }
            fragments[tick] = nil
            let payload = (0..<Int(count)).flatMap { parts[$0] ?? [] }
            guard let snapshot = try? NetSnapshot(decoding: payload) else {
                stats.malformed += 1
                continue
            }
            var baseline: NetWorldState?
            if let baseTick = snapshot.baselineTick {
                guard let base = states.first(where: { $0.tick == baseTick }) else {
                    stats.missingBaseline += 1
                    continue
                }
                baseline = base.state
            }
            insert(ReceivedState(tick: snapshot.tick, time: snapshot.serverTime, state: snapshot.applied(to: baseline)))
            stats.snapshots += 1
            newest = max(newest ?? 0, snapshot.tick)
        }
        if let newest {
            latestTick = max(latestTick ?? 0, newest)
            transport.send(NetPacket.make(.ack) { $0.u32(latestTick!) }, to: server)
        }
        // Forget incomplete snapshots too old to matter.
        if let latestTick, latestTick > UInt32(historyLength) {
            let cutoff = latestTick - UInt32(historyLength)
            fragments = fragments.filter { $0.key > cutoff }
        }
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
            if let existing = world.entity(for: id) {
                entity = existing
            } else {
                entity = world.spawn()
                world.setEntityID(id, for: entity)
            }
            var previous = applied[id] ?? [:]
            for (name, bytes) in components where name != Transform.componentName && previous[name] != bytes {
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
            if let bytes = components[Transform.componentName], let from = try? NetComponentCoder.decodeTransform(bytes) {
                var transform = from
                if let next = b?.state[id]?[Transform.componentName], let to = try? NetComponentCoder.decodeTransform(next) {
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
