// Networking (card 662): the connection layer under `NetServer` / `NetClient`.
//
// Handshake (no server state and no reply bigger than the request until the client proved it
// receives at its address):
//   client: connectRequest(salt), padded to `connectRequestSize`
//   server: challenge(salt, token)       token = keyed hash of (peer, salt, time bucket)
//   client: challengeResponse(salt, token), padded
//   server: accepted(client id) | denied(reason)    -- the client now has a slot
// After that every packet either way is "connected": a header with its own 16-bit sequence
// number, an ack of the newest sequence received plus a 32-bit field of the ones before it and
// how long the ack was held (for RTT), the reliable channel's cumulative ack, and any reliable
// messages due for (re)sending, followed by the packet kind's body (snapshot fragment, client
// update with inputs, keep-alive, disconnect). Acks therefore ride on snapshots and inputs;
// keep-alives only go out when nothing else did for `keepAliveInterval`.
//
// Reliable messages are numbered (16 bits, wrapping) and resent until the cumulative ack
// covers them, every 1.25 RTT; the receiver buffers out-of-order ones and delivers in order.
// Loss is the fraction of the last 128 packets whose sequence fell out of the peer's ack field
// without being acked.

/// A client's id on its server (1, 2, ... in connection order; never reused by one server).
public struct NetClientID: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let value: UInt32
    public init(_ value: UInt32) { self.value = value }
    public static func < (a: Self, b: Self) -> Bool { a.value < b.value }
    public var description: String { "client\(value)" }
}

public enum NetDisconnectReason: UInt8, Sendable, Equatable {
    /// The other side said goodbye (`disconnect()`).
    case requested = 1
    /// Nothing arrived for `timeout` seconds.
    case timedOut = 2
    /// The server has `maxClients` clients.
    case serverFull = 3
    /// The server disconnected this client (`NetServer.disconnect(_:)`).
    case kicked = 4
    /// No answer to the connection request within `connectTimeout`.
    case connectTimedOut = 5
}

/// Round trip, loss and traffic of one connection.
public struct NetConnectionStats: Equatable, Sendable {
    /// Smoothed round-trip time (seconds); nil until the first ack.
    public var rtt: Double?
    /// Fraction of recent packets (the last 128 whose fate is known) the peer didn't receive.
    public var loss: Double
    public var packetsSent = 0
    public var packetsReceived = 0
    public var bytesSent = 0
    public var bytesReceived = 0
    /// Reliable messages sent but not acknowledged yet.
    public var unackedMessages = 0
}

enum NetPacket {
    static let magic: [UInt8] = [0x53, 0x4E] // "SN"
    static let version: UInt8 = 3
    static let headerSize = 4
    /// Requests are padded to this size so the server's answers (challenge, denied) are never
    /// bigger than what an unverified address sent (no reflection amplification).
    static let connectRequestSize = 64

    enum Kind: UInt8 {
        // Unconnected.
        case connectRequest = 1
        case challenge = 2
        case challengeResponse = 3
        case denied = 4
        // Connected (a connection header follows the packet header).
        case accepted = 5
        case keepAlive = 6
        case disconnect = 7
        case snapshotFragment = 8
        case clientUpdate = 9
    }

    static func make(_ kind: Kind, _ body: (inout ByteWriter) -> Void = { _ in }) -> [UInt8] {
        var w = ByteWriter()
        w.bytes(magic)
        w.u8(version)
        w.u8(kind.rawValue)
        body(&w)
        return w.data
    }

    static func padded(_ packet: [UInt8]) -> [UInt8] {
        packet + [UInt8](repeating: 0, count: max(0, connectRequestSize - packet.count))
    }

    /// The kind and a reader positioned after the header, or nil for foreign / old packets.
    static func parse(_ bytes: [UInt8]) -> (Kind, ByteReader)? {
        guard bytes.count >= headerSize, bytes[0] == magic[0], bytes[1] == magic[1], bytes[2] == version,
              let kind = Kind(rawValue: bytes[3]) else { return nil }
        var reader = ByteReader(bytes)
        reader.offset = headerSize
        return (kind, reader)
    }

    /// Snapshot fragment header after the connection header: tick u32, index u8, count u8.
    static let fragmentHeaderSize = 6
    /// Room left for a connection header with a few reliable messages.
    static let connectionHeaderReserve = 96
    static let maxFragmentPayload = NetLimits.maxDatagramSize - headerSize - connectionHeaderReserve - fragmentHeaderSize

    /// The keyed hash the challenge token is (not cryptographic: it only proves the client
    /// receives at its address; see docs/Networking.md, "Security").
    static func challengeToken(secret: UInt64, peer: PeerID, salt: UInt64, bucket: UInt64) -> UInt64 {
        func mix(_ x: UInt64) -> UInt64 {
            var z = x &+ 0x9E37_79B9_7F4A_7C15
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
        return mix(mix(mix(secret ^ peer.value) ^ salt) ^ bucket)
    }
}

/// `a` comes after `b` in 16-bit wrapping sequence order.
@inline(__always) func sequenceGreater(_ a: UInt16, _ b: UInt16) -> Bool {
    a != b && (a &- b) < 0x8000
}

/// Per-peer state of a connection: packet sequence numbers and acks, RTT and loss, and the
/// reliable ordered message channel. Times are the owner's clock (seconds).
final class NetConnection {
    /// Messages over this size are refused by `send(message:)` (they must fit one datagram
    /// with the headers).
    static let maxMessageSize = 1000
    /// Reliable messages buffered either way; more means the peer is gone or misbehaving.
    static let maxPendingMessages = 1024

    private(set) var stats = NetConnectionStats(loss: 0)
    var lastReceiveTime: Double
    var lastSendTime: Double

    // Packet acks.
    private var localSequence: UInt16 = 0
    private struct Sent {
        var sequence: UInt16
        var time: Double
        var resolved: Bool
    }
    private var sent = [Sent](repeating: Sent(sequence: 0, time: 0, resolved: true), count: 1024)
    private var lossCursor: UInt16 = 0
    private var outcomes: [Bool] = [] // true: lost
    private var outcomeIndex = 0
    private var remoteNewest: UInt16?
    private var remoteBits: UInt32 = 0
    private var remoteNewestTime: Double = 0

    // Reliable messages.
    private var nextMessageID: UInt16 = 0
    private var outgoing: [(id: UInt16, bytes: [UInt8], lastSent: Double?)] = []
    private var nextExpected: UInt16 = 0
    private var incoming: [UInt16: [UInt8]] = [:]
    /// Messages received in order, drained by the owner.
    var delivered: [[UInt8]] = []

    init(now: Double) {
        lastReceiveTime = now
        lastSendTime = now
    }

    /// Queues a reliable message; false if it is too big or the queue is full.
    @discardableResult
    func send(message: [UInt8]) -> Bool {
        guard message.count <= Self.maxMessageSize, outgoing.count < Self.maxPendingMessages else { return false }
        outgoing.append((nextMessageID, message, nil))
        nextMessageID &+= 1
        stats.unackedMessages = outgoing.count
        return true
    }

    /// Some message is due: never sent, or sent longer than 1.25 RTT ago.
    func hasMessagesDue(now: Double) -> Bool {
        let delay = resendDelay()
        return outgoing.prefix(64).contains { $0.lastSent.map { now - $0 >= delay } ?? true }
    }

    private func resendDelay() -> Double { max(0.03, (stats.rtt ?? 0.1) * 1.25 + 0.01) }

    /// The largest connection header `writeHeader` writes without messages.
    static let bareHeaderSize = 14

    /// Writes a connection header and the reliable messages that are due and fit in `budget`
    /// bytes (header included).
    func writeHeader(_ w: inout ByteWriter, now: Double, budget: Int = NetPacket.connectionHeaderReserve) {
        let sequence = localSequence
        localSequence &+= 1
        let slot = Int(sequence & 1023)
        if !sent[slot].resolved { record(lost: true) } // 1024 packets without an answer
        sent[slot] = Sent(sequence: sequence, time: now, resolved: false)
        w.u16(sequence)
        if let remoteNewest {
            w.u8(1)
            w.u16(remoteNewest)
            w.u32(remoteBits)
            w.u16(UInt16(min(65535, max(0, (now - remoteNewestTime) * 1000).rounded())))
        } else {
            w.u8(0)
        }
        w.u16(nextExpected)
        let delay = resendDelay()
        var chosen: [Int] = []
        var size = Self.bareHeaderSize
        for (i, message) in outgoing.prefix(64).enumerated() {
            if let last = message.lastSent, now - last < delay { continue }
            let cost = 2 + 2 + message.bytes.count
            if size + cost > budget { continue }
            chosen.append(i)
            size += cost
        }
        w.varint(chosen.count)
        for i in chosen {
            w.u16(outgoing[i].id)
            w.varint(outgoing[i].bytes.count)
            w.bytes(outgoing[i].bytes)
            outgoing[i].lastSent = now
        }
    }

    /// Counts a packet about to be sent (after `writeHeader`).
    func didSend(bytes: Int, now: Double) {
        stats.packetsSent += 1
        stats.bytesSent += bytes
        lastSendTime = now
    }

    /// Reads a connection header: processes the acks and delivers the messages.
    func readHeader(_ r: inout ByteReader, now: Double, packetSize: Int) throws {
        let sequence = try r.u16()
        let hasAck = try r.u8()
        guard hasAck <= 1 else { throw NetError.malformed("ack flag") }
        var ack: (UInt16, UInt32, UInt16)?
        if hasAck == 1 { ack = (try r.u16(), try r.u32(), try r.u16()) }
        let remoteExpected = try r.u16()
        var messages: [(UInt16, [UInt8])] = []
        for _ in 0..<(try r.varint(max: 64)) {
            let id = try r.u16()
            messages.append((id, try r.bytes(r.varint(max: Self.maxMessageSize))))
        }
        // Parsed completely: apply.
        stats.packetsReceived += 1
        stats.bytesReceived += packetSize
        lastReceiveTime = now
        received(sequence, now: now)
        if let (newest, bits, delayMs) = ack { acked(newest, bits: bits, delay: Double(delayMs) / 1000, now: now) }
        outgoing.removeAll { sequenceGreater(remoteExpected, $0.id) }
        stats.unackedMessages = outgoing.count
        for (id, bytes) in messages {
            let ahead = id &- nextExpected
            guard ahead < UInt16(Self.maxPendingMessages) else { continue } // already delivered (or absurd)
            incoming[id] = bytes
        }
        while let bytes = incoming.removeValue(forKey: nextExpected) {
            delivered.append(bytes)
            nextExpected &+= 1
        }
    }

    private func received(_ sequence: UInt16, now: Double) {
        guard let newest = remoteNewest else {
            remoteNewest = sequence
            remoteNewestTime = now
            return
        }
        if sequenceGreater(sequence, newest) {
            let shift = sequence &- newest
            remoteBits = shift >= 32 ? (shift == 32 ? 1 << 31 : 0) : (remoteBits << shift) | (1 << (shift - 1))
            remoteNewest = sequence
            remoteNewestTime = now
        } else {
            let behind = newest &- sequence
            if behind >= 1 && behind <= 32 { remoteBits |= 1 << (behind - 1) }
        }
    }

    private func acked(_ newest: UInt16, bits: UInt32, delay: Double, now: Double) {
        func resolve(_ sequence: UInt16, sample: Bool) {
            let slot = Int(sequence & 1023)
            guard sent[slot].sequence == sequence, !sent[slot].resolved else { return }
            sent[slot].resolved = true
            record(lost: false)
            if sample {
                let rtt = max(0, now - sent[slot].time - delay)
                stats.rtt = stats.rtt.map { $0 + (rtt - $0) * 0.1 } ?? rtt
            }
        }
        resolve(newest, sample: true)
        for i in 0..<32 where bits & (1 << UInt32(i)) != 0 { resolve(newest &- UInt16(i + 1), sample: false) }
        // Whatever fell out of the ack field unacked was lost.
        let horizon = newest &- 32
        var checked = 0
        while sequenceGreater(horizon, lossCursor), checked < 1024 {
            let slot = Int(lossCursor & 1023)
            if sent[slot].sequence == lossCursor, !sent[slot].resolved {
                sent[slot].resolved = true
                record(lost: true)
            }
            lossCursor &+= 1
            checked += 1
        }
    }

    private func record(lost: Bool) {
        if outcomes.count < 128 {
            outcomes.append(lost)
        } else {
            outcomes[outcomeIndex] = lost
            outcomeIndex = (outcomeIndex + 1) % 128
        }
        stats.loss = Double(outcomes.filter { $0 }.count) / Double(outcomes.count)
    }
}
