// Networking prototype (card 624): unreliable datagram transports. See docs/Networking.md.
//
// Everything above the transport (snapshots, acks, fragments) is built for unreliable,
// unordered datagrams, the lowest common denominator of UDP, QUIC datagrams, WebRTC data
// channels and Steam's relay sockets, so any of those can sit under it later.

/// A remote endpoint as a transport knows it: an index into the transport's own table of
/// addresses (a loopback endpoint, a UDP address). Only meaningful to the transport that
/// produced it.
public struct PeerID: Hashable, Sendable, CustomStringConvertible {
    public let value: UInt64
    public init(_ value: UInt64) { self.value = value }
    public var description: String { "peer\(value)" }
}

/// One received datagram.
public struct NetDatagram: Sendable {
    public var from: PeerID
    public var bytes: [UInt8]
    public init(from: PeerID, bytes: [UInt8]) {
        self.from = from
        self.bytes = bytes
    }
}

/// Sends and receives unreliable datagrams: they may be lost, duplicated or reordered, and
/// each is at most `NetLimits.maxDatagramSize` bytes. Polled (no callbacks): `receive` drains
/// what arrived since the last call, so the game loop decides when network work happens.
public protocol NetTransport: AnyObject {
    func send(_ bytes: [UInt8], to peer: PeerID)
    func receive() -> [NetDatagram]
}

public enum NetLimits {
    /// The largest datagram the replication layer sends: below the usual 1280-byte IPv6
    /// minimum MTU minus IP / UDP headers, so datagrams are never fragmented by IP.
    public static let maxDatagramSize = 1200
}

// MARK: Loopback

/// Simulated link conditions for a `LoopbackNetwork`: one-way latency, jitter (uniform in
/// `0...jitter`, so packets can arrive out of order), random loss and duplication.
public struct LinkConditions: Sendable, Equatable {
    public var latency: Double
    public var jitter: Double
    public var loss: Double
    public var duplicate: Double

    public init(latency: Double = 0, jitter: Double = 0, loss: Double = 0, duplicate: Double = 0) {
        self.latency = latency
        self.jitter = jitter
        self.loss = loss
        self.duplicate = duplicate
    }

    public static let perfect = LinkConditions()
}

/// An in-process network for tests and demos: endpoints made by `makeEndpoint` exchange
/// datagrams through it, delayed and dropped according to `conditions` with a seeded random
/// generator (deterministic runs). Time is `now`, advanced by the caller (simulation time,
/// not the wall clock), so tests run instantly and reproducibly.
public final class LoopbackNetwork {
    public var now: Double = 0
    public var conditions: LinkConditions
    /// Per-direction overrides, keyed by (from, to).
    public var linkOverrides: [Link: LinkConditions] = [:]

    public struct Link: Hashable, Sendable {
        public var from: PeerID
        public var to: PeerID
        public init(from: PeerID, to: PeerID) { self.from = from; self.to = to }
    }

    public struct Stats: Sendable, Equatable {
        public var sent = 0
        public var dropped = 0
        public var delivered = 0
        public var bytesSent = 0
    }
    public private(set) var stats = Stats()

    private struct InFlight {
        var deliverAt: Double
        var order: UInt64
        var from: PeerID
        var to: PeerID
        var bytes: [UInt8]
    }
    private var inFlight: [InFlight] = []
    private var nextPeer: UInt64 = 1
    private var nextOrder: UInt64 = 0
    private var rng: SplitMix64

    public init(conditions: LinkConditions = .perfect, seed: UInt64 = 1) {
        self.conditions = conditions
        rng = SplitMix64(seed: seed)
    }

    public func makeEndpoint() -> LoopbackTransport {
        defer { nextPeer += 1 }
        return LoopbackTransport(network: self, id: PeerID(nextPeer))
    }

    fileprivate func send(_ bytes: [UInt8], from: PeerID, to: PeerID) {
        precondition(bytes.count <= NetLimits.maxDatagramSize, "datagram of \(bytes.count) bytes")
        stats.sent += 1
        stats.bytesSent += bytes.count
        let link = linkOverrides[Link(from: from, to: to)] ?? conditions
        if link.loss > 0, rng.nextUnit() < link.loss {
            stats.dropped += 1
            return
        }
        let copies = link.duplicate > 0 && rng.nextUnit() < link.duplicate ? 2 : 1
        for _ in 0..<copies {
            let delay = link.latency + (link.jitter > 0 ? rng.nextUnit() * link.jitter : 0)
            inFlight.append(InFlight(deliverAt: now + delay, order: nextOrder, from: from, to: to, bytes: bytes))
            nextOrder += 1
        }
    }

    fileprivate func receive(for peer: PeerID) -> [NetDatagram] {
        var due: [InFlight] = []
        inFlight.removeAll { packet in
            guard packet.to == peer, packet.deliverAt <= now else { return false }
            due.append(packet)
            return true
        }
        due.sort { ($0.deliverAt, $0.order) < ($1.deliverAt, $1.order) }
        stats.delivered += due.count
        return due.map { NetDatagram(from: $0.from, bytes: $0.bytes) }
    }
}

/// One endpoint of a `LoopbackNetwork`. Its `id` is the `PeerID` other endpoints send to.
public final class LoopbackTransport: NetTransport {
    public let network: LoopbackNetwork
    public let id: PeerID

    fileprivate init(network: LoopbackNetwork, id: PeerID) {
        self.network = network
        self.id = id
    }

    public func send(_ bytes: [UInt8], to peer: PeerID) {
        network.send(bytes, from: id, to: peer)
    }

    public func receive() -> [NetDatagram] {
        network.receive(for: id)
    }
}

/// A small deterministic generator (SplitMix64) for simulated loss and jitter.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    /// Uniform in [0, 1).
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }
}
