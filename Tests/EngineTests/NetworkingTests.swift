import Foundation
import Testing
@testable import Engine

/// The networking prototype (Sources/Engine/Net, card 624): snapshot replication over the
/// loopback and UDP transports, deltas, interpolation under latency and loss.
@MainActor @Suite struct NetworkingTests {
    struct NetworkingTestsHealth: Component, Equatable {
        static let componentName = "NetworkingTestsHealth"
        var hp: Int
        var label: String
    }

    init() {
        ComponentRegistry.register(NetworkingTestsHealth.self)
    }

    /// A server world with `count` replicated entities (Transform and Health), and a client
    /// connected to it over `network`.
    func makeSession(network: LoopbackNetwork, count: Int) -> (server: NetServer, client: NetClient, entities: [Entity]) {
        let serverWorld = World()
        var generator = SplitMix64(seed: 42)
        serverWorld.entityIDGenerator = { EntityID.random(using: &generator) }
        var entities: [Entity] = []
        for i in 0..<count {
            entities.append(serverWorld.spawn(Transform(position: Vec3(Float(i), 0, 0)),
                                              NetworkingTestsHealth(hp: 100, label: "unit \(i)"),
                                              Replicated(components: [Transform.componentName, NetworkingTestsHealth.componentName])))
        }
        let serverEnd = network.makeEndpoint()
        let clientEnd = network.makeEndpoint()
        let server = NetServer(world: serverWorld, transport: serverEnd)
        let client = NetClient(world: World(), transport: clientEnd, server: serverEnd.id)
        return (server, client, entities)
    }

    /// Runs both sides at 60 Hz for `seconds`, calling `body` with the time before each step.
    func run(_ server: NetServer, _ client: NetClient, network: LoopbackNetwork, from start: Double = 0, seconds: Double,
             body: (Double) -> Void = { _ in }) -> Double {
        let dt = 1.0 / 60.0
        var time = start
        for _ in 0..<Int((seconds / dt).rounded()) {
            body(time)
            network.now = time
            server.update(time: time)
            client.update(dt: dt)
            time += dt
        }
        return time
    }

    func clientState(_ client: NetClient) -> [EntityID: (Transform?, NetworkingTestsHealth?)] {
        var result: [EntityID: (Transform?, NetworkingTestsHealth?)] = [:]
        for entity in client.world.entities {
            guard let id = client.world.id(of: entity) else { continue }
            result[id] = (client.world.get(Transform.self, for: entity), client.world.get(NetworkingTestsHealth.self, for: entity))
        }
        return result
    }

    @Test func loopbackReplicationConverges() {
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.03, jitter: 0.02, loss: 0.1, duplicate: 0.05), seed: 7)
        let (server, client, entities) = makeSession(network: network, count: 20)
        let world = server.world
        // Moving, damaging, despawning and spawning while the link drops and reorders packets.
        var spawned: Entity?
        var time = run(server, client, network: network, seconds: 2) { t in
            for (i, e) in entities.enumerated() where world.isAlive(e) {
                world.modify(Transform.self, for: e) { $0.position.y = Float(sin(t + Double(i))) }
            }
            if t > 0.5, world.isAlive(entities[3]) { world.despawn(entities[3]) }
            if t > 0.8, spawned == nil {
                spawned = world.spawn(Transform(position: Vec3(0, 5, 0), rotation: Quat(angle: 1, axis: Vec3(0, 1, 0))),
                                      NetworkingTestsHealth(hp: 7, label: "late"), Replicated(components: [Transform.componentName, NetworkingTestsHealth.componentName]))
            }
            if t > 1.0 { world.modify(NetworkingTestsHealth.self, for: entities[5]) { $0.hp = 42 } }
            if t > 1.2 { world.remove(NetworkingTestsHealth.self, from: entities[6]) }
        }
        // Then still for a while: the client must end up with exactly the server's state.
        time = run(server, client, network: network, from: time, seconds: 1)

        let replicated = clientState(client)
        var expected = 0
        world.query(Replicated.self) { entity, _ in
            expected += 1
            let id = world.id(of: entity)!
            guard let (transform, health) = replicated[id] else {
                Issue.record("entity \(id) missing on the client")
                return
            }
            #expect(transform == world.get(Transform.self, for: entity))
            #expect(health == world.get(NetworkingTestsHealth.self, for: entity))
        }
        #expect(expected == 20)
        #expect(replicated.count == expected)
        #expect(replicated[world.id(of: entities[5])!]?.1?.hp == 42)
        #expect(replicated[world.id(of: entities[6])!]?.1 == nil)
        #expect(network.stats.dropped > 0)
        #expect(client.stats.malformed == 0)
        // Deltas were used (acks got through) and the server tracked the client.
        #expect(server.ackedTick(of: server.clients[0]) != nil)
    }

    /// One entity moving at constant speed, 100 ms one-way latency, 5% loss each way: the
    /// client's interpolated position is the server's position at the render time (linear
    /// motion interpolates exactly), it never runs out of snapshots, and it moves smoothly.
    @Test func interpolationUnderLatencyAndLoss() {
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.1, loss: 0.05), seed: 3)
        let (server, client, entities) = makeSession(network: network, count: 1)
        let speed: Float = 4
        let dt = 1.0 / 60.0
        var positions: [(render: Double, x: Float)] = []
        var maxLag = 0.0
        _ = run(server, client, network: network, seconds: 6) { t in
            server.world.modify(Transform.self, for: entities[0]) { $0.position.x = speed * Float(t) }
            if let render = client.renderTime, let entity = client.world.entities.first,
               let x = client.world.get(Transform.self, for: entity)?.position.x {
                positions.append((render, x))
                maxLag = max(maxLag, t - render)
            }
        }
        #expect(network.stats.dropped > 10)
        #expect(client.stats.snapshots > 150)
        // Settled after the first second: the clock holds ~latency + delay (+ up to a snapshot interval) behind.
        let settled = positions.filter { $0.render > 1 }
        #expect(settled.count > 250)
        #expect(client.stats.starvedFrames == 0)
        var maxError: Float = 0
        var maxStepError: Float = 0
        for (i, p) in settled.enumerated() {
            // Snapshot times are multiples of dt, positions speed * time: exact up to float rounding.
            maxError = max(maxError, abs(p.x - speed * Float(p.render)))
            if i > 0 { maxStepError = max(maxStepError, abs((p.x - settled[i - 1].x) - speed * Float(dt))) }
        }
        #expect(maxError < 1e-3)
        // Per-frame movement within 25% of the true speed: no stalls, no catch-up jumps.
        #expect(maxStepError < speed * Float(dt) * 0.25)
        #expect(maxLag < 0.1 + 0.1 + 1.0 / 30.0 + 0.05)
    }

    @Test func snapshotDeltaSize() throws {
        let network = LoopbackNetwork()
        let (server, client, entities) = makeSession(network: network, count: 200)
        var time = run(server, client, network: network, seconds: 0.2)
        let peer = server.clients[0]
        // The first snapshot was full; by now the client has acked and deltas are empty.
        let full = NetSnapshot(tick: 1, serverTime: 0, state: server.captureState(), baseline: nil, baselineTick: nil).encoded().count
        let empty = server.lastSnapshotBytes[peer]!
        #expect(empty < 40)
        #expect(full > 200 * 60)

        // 10 of 200 move: ~10 Transforms of 40 bytes plus ids.
        time = run(server, client, network: network, from: time, seconds: 1.0 / 60.0) { _ in
            for e in entities.prefix(10) { server.world.modify(Transform.self, for: e) { $0.position.z += 1 } }
        }
        let delta = server.lastSnapshotBytes[peer]!
        #expect(delta < full / 15)
        #expect(delta < 10 * (16 + 2 + 2 + 40) + 64)
        _ = run(server, client, network: network, from: time, seconds: 0.2)
        #expect(clientState(client).count == 200)
        print("NetworkingTests: 200 entities: full snapshot \(full) bytes, 10 moved: \(delta) bytes, none: \(empty) bytes")
    }

    @Test func snapshotRoundTripAndMalformedInput() throws {
        let a = EntityID(high: 1, low: 2), b = EntityID(high: 3, low: 4), c = EntityID(high: 5, low: 6)
        let base: NetWorldState = [a: ["Transform": [1, 2, 3], "X": [9]], b: ["Transform": [4]]]
        let state: NetWorldState = [a: ["Transform": [1, 2, 3, 4]], c: ["Y": []]]
        let delta = NetSnapshot(tick: 9, serverTime: 1.5, state: state, baseline: base, baselineTick: 8)
        #expect(delta.removed == [b])
        let decoded = try NetSnapshot(decoding: delta.encoded())
        #expect(decoded == delta)
        #expect(decoded.applied(to: base) == state)
        // Every truncation fails cleanly rather than crashing.
        let bytes = delta.encoded()
        for n in 0..<bytes.count { #expect(throws: NetError.self) { try NetSnapshot(decoding: Array(bytes.prefix(n))) } }
    }

    /// Large snapshots go out in fragments; one lost fragment loses that snapshot only.
    @Test func fragmentedSnapshots() {
        let network = LoopbackNetwork(conditions: LinkConditions(loss: 0.02), seed: 11)
        let (server, client, entities) = makeSession(network: network, count: 300)
        _ = run(server, client, network: network, seconds: 1.5) { t in
            for e in entities { server.world.modify(Transform.self, for: e) { $0.position.y = Float(t) } }
        }
        #expect(server.lastSnapshotBytes[server.clients[0]]! > NetLimits.maxDatagramSize * 3)
        _ = run(server, client, network: network, from: 1.5, seconds: 0.5)
        let state = clientState(client)
        #expect(state.count == 300)
        let y = server.world.get(Transform.self, for: entities[0])!.position.y
        #expect(state.values.allSatisfy { $0.0?.position.y == y })
        #expect(client.stats.snapshots < server.tick) // some were lost with a fragment
    }

    #if canImport(Darwin) || canImport(Glibc)
    @Test func udpLocalhostReplication() throws {
        let serverSocket = try UDPTransport(port: 0)
        let clientSocket = try UDPTransport(port: 0)
        let serverPeer = try clientSocket.peer(host: "127.0.0.1", port: serverSocket.port)
        let world = World()
        let entity = world.spawn(Transform(position: Vec3(1, 2, 3)), Replicated())
        let server = NetServer(world: world, transport: serverSocket)
        let client = NetClient(world: World(), transport: clientSocket, server: serverPeer)
        client.interpolationDelay = 0
        let deadline = Date().addingTimeInterval(5)
        var time = 0.0
        while Date() < deadline {
            world.modify(Transform.self, for: entity) { $0.position.x = 7 }
            server.update(time: time)
            client.update(dt: 1.0 / 60.0)
            if client.world.entities.first.flatMap({ client.world.get(Transform.self, for: $0) })?.position == Vec3(7, 2, 3) { break }
            time += 1.0 / 60.0
            usleep(2000)
        }
        #expect(client.world.entities.count == 1)
        #expect(client.world.entities.first.flatMap { client.world.get(Transform.self, for: $0) }?.position == Vec3(7, 2, 3))
        #expect(client.world.id(of: client.world.entities[0]) == world.id(of: entity))
    }
    #endif

    /// Not a check: prints a hash of a single-threaded physics run and of a few libm results,
    /// to compare across machines and architectures (docs/Networking.md, "Determinism").
    /// `swift test --filter NetworkingTests/physicsDeterminismFingerprint` on each machine.
    @Test func physicsDeterminismFingerprint() {
        let physics = PhysicsWorld()
        physics.jobs = JobSystem(threadCount: 1)
        defer { physics.jobs.shutdown() }
        physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: Vec3(0, -0.5, 0)), shape: .box(Vec3(30, 0.5, 30))))
        var ids: [BodyID] = []
        for i in 0..<60 {
            let p = Vec3(Float(i % 4) * 0.9 - 1.3, 0.6 + Float(i / 16) * 1.1, Float((i / 4) % 4) * 0.9 - 1.3 + Float(i % 5) * 0.01)
            let shape: ColliderShape = i % 3 == 0 ? .box(Vec3(0.4, 0.3, 0.4)) : i % 3 == 1 ? .sphere(radius: 0.4) : .capsule(radius: 0.25, halfHeight: 0.25)
            ids.append(physics.addBody(BodyDescriptor(pose: Pose(position: p, rotation: Quat(angle: Float(i) * 0.3, axis: normalize(Vec3(1, 2, 3)))),
                                                      shape: shape, angularVelocity: Vec3(Float(i % 5) * 0.2, 0, Float(i % 3) * 0.1))))
        }
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ v: Float) { hash = (hash ^ UInt64(v.bitPattern)) &* 0x100_0000_01b3 }
        for _ in 0..<300 { physics.step(1.0 / 60.0) }
        for id in ids {
            let pose = physics.pose(of: id)!
            for v in [pose.position.x, pose.position.y, pose.position.z, pose.rotation.vector.x, pose.rotation.vector.y,
                      pose.rotation.vector.z, pose.rotation.vector.w] { mix(v) }
        }
        var libm: UInt64 = 0
        for i in 1...2000 {
            let x = Float(i) * 0.0137
            for v in [sinf(x), cosf(x), tanf(x), atan2f(x, 1.3), expf(x * 0.01), logf(x), powf(x, 1.7), acosf(min(1, x * 0.03))] {
                libm = (libm ^ UInt64(v.bitPattern)) &* 0x100_0000_01b3
            }
        }
        #if arch(arm64)
        let arch = "arm64"
        #elseif arch(x86_64)
        let arch = "x86_64"
        #else
        let arch = "other"
        #endif
        print("DETERMINISM arch=\(arch) physics=\(String(hash, radix: 16)) libm=\(String(libm, radix: 16)) sample=\(physics.pose(of: ids[17])!.position)")
        #expect(physics.pose(of: ids[0]) != nil)
    }
}
