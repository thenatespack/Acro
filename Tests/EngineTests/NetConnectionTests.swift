import Foundation
import Testing
@testable import Engine

/// The connection layer under NetServer / NetClient (card 662): challenge handshake, client
/// ids, keep-alives, timeouts and disconnects, the reliable ordered message channel, RTT and
/// loss estimates; on `LoopbackNetwork` with loss, jitter and duplication, and UDP on localhost.
@MainActor @Suite struct NetConnectionTests {
    @MainActor final class Session {
        let network: LoopbackNetwork
        let server: NetServer
        var clients: [NetClient] = []
        var time = 0.0
        var serverEvents: [NetServerEvent] = []
        var clientEvents: [[NetClientEvent]] = []
        /// Clients not updated any more (simulating a crash or a frozen process).
        var frozen: Set<Int> = []
        var serverFrozen = false

        init(conditions: LinkConditions, seed: UInt64 = 1, clients count: Int = 1) {
            network = LoopbackNetwork(conditions: conditions, seed: seed)
            server = NetServer(world: World(), transport: network.makeEndpoint(), secret: 1234)
            for _ in 0..<count { addClient() }
        }

        @discardableResult
        func addClient() -> NetClient {
            let serverID = (server.transport as! LoopbackTransport).id
            let client = NetClient(world: World(), transport: network.makeEndpoint(), server: serverID, salt: UInt64(clients.count + 1) * 77)
            clients.append(client)
            clientEvents.append([])
            return client
        }

        func run(seconds: Double, body: (Double) -> Void = { _ in }) {
            let dt = 1.0 / 60.0
            for _ in 0..<Int((seconds / dt).rounded()) {
                body(time)
                network.now = time
                if !serverFrozen {
                    server.update(time: time)
                    serverEvents += server.pollEvents()
                }
                for (i, client) in clients.enumerated() where !frozen.contains(i) {
                    client.update(dt: dt)
                    clientEvents[i] += client.pollEvents()
                }
                time += dt
            }
        }
    }

    @Test func handshakeGivesClientIDsUnderLoss() {
        let session = Session(conditions: LinkConditions(latency: 0.04, jitter: 0.03, loss: 0.2, duplicate: 0.1), seed: 3, clients: 3)
        session.server.maxClients = 2
        session.run(seconds: 3)
        let states = session.clients.map(\.state)
        // Two get in (ids 1 and 2, in whichever order their handshakes completed); the third is
        // told the server is full.
        let ids = session.clients.compactMap(\.clientID).sorted()
        #expect(ids == [NetClientID(1), NetClientID(2)])
        #expect(states.filter { $0 == .disconnected(.serverFull) }.count == 1)
        #expect(session.server.clients == ids)
        #expect(session.serverEvents.filter { if case .connected = $0 { true } else { false } }.count == 2)
        for (i, client) in session.clients.enumerated() where client.clientID != nil {
            #expect(session.clientEvents[i] == [.connected(client.clientID!)])
        }
        #expect(session.network.stats.dropped > 0)
    }

    /// The server keeps no state and never answers with more bytes than it got until a client
    /// has echoed a valid challenge token.
    @Test func handshakeRejectsBadTokensAndDoesNotAmplify() {
        let network = LoopbackNetwork()
        let serverEnd = network.makeEndpoint()
        let server = NetServer(world: World(), transport: serverEnd, secret: 42)
        let attacker = network.makeEndpoint()
        var sent = 0
        func send(_ packet: [UInt8]) {
            sent += packet.count
            attacker.send(packet, to: serverEnd.id)
        }
        // Unpadded requests are ignored; padded ones get a challenge no bigger than the request.
        send(NetPacket.make(.connectRequest) { $0.u64(1) })
        send(NetPacket.padded(NetPacket.make(.connectRequest) { $0.u64(2) }))
        // Responses with a made-up token, and connected packets from a stranger.
        send(NetPacket.padded(NetPacket.make(.challengeResponse) { $0.u64(2); $0.u64(0xDEAD) }))
        send(NetPacket.make(.clientUpdate) { $0.bytes([UInt8](repeating: 0, count: 40)) })
        send([1, 2, 3])
        server.update(time: 0)
        var received = 0
        var challenge: (salt: UInt64, token: UInt64)?
        for datagram in attacker.receive() {
            received += datagram.bytes.count
            if let (kind, r) = NetPacket.parse(datagram.bytes), kind == .challenge {
                var reader = r
                challenge = (try! reader.u64(), try! reader.u64())
            }
        }
        #expect(received <= sent / 2)
        #expect(server.clients.isEmpty)
        #expect(server.rejectedPackets >= 3)
        #expect(challenge?.salt == 2)
        // The real token from another address doesn't work either (tokens are per address).
        let other = network.makeEndpoint()
        other.send(NetPacket.padded(NetPacket.make(.challengeResponse) { $0.u64(2); $0.u64(challenge!.token) }), to: serverEnd.id)
        server.update(time: 0.1)
        #expect(server.clients.isEmpty)
        // From the right address it does.
        attacker.send(NetPacket.padded(NetPacket.make(.challengeResponse) { $0.u64(2); $0.u64(challenge!.token) }), to: serverEnd.id)
        server.update(time: 0.2)
        #expect(server.clients == [NetClientID(1)])
        #expect(server.pollEvents() == [.connected(NetClientID(1))])
    }

    @Test func keepAlivesTimeoutsAndDisconnects() {
        let session = Session(conditions: LinkConditions(latency: 0.05, loss: 0.1), seed: 5, clients: 3)
        session.server.timeout = 1
        for client in session.clients { client.timeout = 1 }
        // Nothing to say for 4 s (no world content, no messages): keep-alives hold it open.
        session.run(seconds: 4)
        #expect(session.server.clients.count == 3)
        #expect(session.clients.allSatisfy { $0.clientID != nil })
        let (a, b, c) = (session.clients[0].clientID!, session.clients[1].clientID!, session.clients[2].clientID!)

        // A client says goodbye; another freezes and times out; the third is kicked.
        session.clients[0].disconnect()
        session.frozen.insert(1)
        session.run(seconds: 0.5)
        session.server.disconnect(c)
        session.run(seconds: 1.5)
        #expect(session.serverEvents.contains(.disconnected(a, .requested)))
        #expect(session.serverEvents.contains(.disconnected(b, .timedOut)))
        #expect(session.serverEvents.contains(.disconnected(c, .kicked)))
        #expect(session.server.clients.isEmpty)
        #expect(session.clients[0].state == .disconnected(.requested))
        #expect(session.clients[2].state == .disconnected(.kicked) || session.clients[2].state == .disconnected(.timedOut))

        // The server goes away: a client notices within its timeout.
        let d = session.addClient()
        d.timeout = 1
        session.run(seconds: 1)
        #expect(d.clientID == NetClientID(4)) // ids aren't reused
        session.serverFrozen = true
        session.run(seconds: 1.5)
        #expect(d.state == .disconnected(.timedOut))
        #expect(session.clientEvents[3].last == .disconnected(.timedOut))
    }

    @Test func connectTimesOutWithoutAServer() {
        let network = LoopbackNetwork()
        let client = NetClient(world: World(), transport: network.makeEndpoint(), server: PeerID(99))
        client.connectTimeout = 1
        for _ in 0..<70 { client.update(dt: 1.0 / 60.0) }
        #expect(client.state == .disconnected(.connectTimedOut))
        #expect(client.pollEvents() == [.disconnected(.connectTimedOut)])
    }

    /// Hundreds of messages each way over 20% loss, jitter and duplication: every one arrives
    /// exactly once and in order, piggybacked or in keep-alives.
    @Test func reliableMessagesArriveOnceInOrder() {
        let session = Session(conditions: LinkConditions(latency: 0.03, jitter: 0.04, loss: 0.2, duplicate: 0.1), seed: 11, clients: 2)
        session.run(seconds: 1)
        let ids = session.clients.map { $0.clientID! }
        func message(_ i: Int, _ tag: UInt8) -> [UInt8] { [tag, UInt8(i & 0xFF), UInt8(i >> 8)] + [UInt8](repeating: tag, count: i % 300) }
        var next = 0
        session.run(seconds: 8) { _ in
            guard next < 300 else { return }
            // A burst now and then, single messages in between.
            for _ in 0..<(next % 50 == 0 ? 20 : 1) where next < 300 {
                for (k, id) in ids.enumerated() { #expect(session.server.send(message: message(next, UInt8(k)), to: id)) }
                for (k, client) in session.clients.enumerated() { #expect(client.send(message: message(next, UInt8(10 + k)))) }
                next += 1
            }
        }
        for (k, client) in session.clients.enumerated() {
            let received = session.clientEvents[k].compactMap { if case .message(let m) = $0 { m } else { nil } }
            #expect(received == (0..<300).map { message($0, UInt8(k)) })
            #expect(client.connectionStats!.unackedMessages == 0)
            let fromClient = session.serverEvents.compactMap { if case .message(ids[k], let m) = $0 { m } else { nil } }
            #expect(fromClient == (0..<300).map { message($0, UInt8(10 + k)) })
        }
        #expect(!session.server.send(message: [UInt8](repeating: 0, count: 1001), to: ids[0]))
    }

    /// RTT from packet acks (ack hold time subtracted) and loss from acks that never came.
    @Test func rttAndLossEstimates() {
        let session = Session(conditions: LinkConditions(latency: 0.06, loss: 0.1), seed: 17)
        session.run(seconds: 10)
        let client = session.clients[0]
        let serverSide = session.server.connectionStats(of: client.clientID!)!
        let clientSide = client.connectionStats!
        for stats in [serverSide, clientSide] {
            #expect(abs(stats.rtt! - 0.12) < 0.02)
            #expect(abs(stats.loss - 0.1) < 0.07)
            #expect(stats.packetsSent > 50)
        }
        print("NetConnectionTests: 60 ms each way, 10% loss: server sees RTT \(serverSide.rtt!) loss \(serverSide.loss), client sees RTT \(clientSide.rtt!) loss \(clientSide.loss)")
    }

    #if canImport(Darwin) || canImport(Glibc)
    @Test func udpHandshakeAndMessages() throws {
        let serverSocket = try UDPTransport(port: 0)
        let clientSocket = try UDPTransport(port: 0)
        let server = NetServer(world: World(), transport: serverSocket)
        let client = NetClient(world: World(), transport: clientSocket, server: try clientSocket.peer(host: "127.0.0.1", port: serverSocket.port))
        var serverMessages: [[UInt8]] = []
        var clientMessages: [[UInt8]] = []
        var sent = false
        var time = 0.0
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, serverMessages.count < 20 || clientMessages.count < 20 {
            server.update(time: time)
            client.update(dt: 1.0 / 60.0)
            if let id = client.clientID, !sent {
                for i in 0..<20 {
                    client.send(message: [UInt8(i)])
                    server.send(message: [UInt8(100 + i)], to: id)
                }
                sent = true
            }
            for case .message(_, let m) in server.pollEvents() { serverMessages.append(m) }
            for case .message(let m) in client.pollEvents() { clientMessages.append(m) }
            time += 1.0 / 60.0
            usleep(2000)
        }
        #expect(client.clientID == NetClientID(1))
        #expect(serverMessages == (0..<20).map { [UInt8($0)] })
        #expect(clientMessages == (0..<20).map { [UInt8(100 + $0)] })
        #expect(client.connectionStats!.rtt != nil)
        client.disconnect()
        let end = Date().addingTimeInterval(2)
        var events: [NetServerEvent] = []
        while Date() < end, server.clients.count == 1 {
            server.update(time: time)
            events += server.pollEvents()
            usleep(2000)
        }
        #expect(events.contains(.disconnected(NetClientID(1), .requested)))
    }
    #endif
}
