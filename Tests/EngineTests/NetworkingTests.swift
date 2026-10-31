import Foundation
import Testing
@testable import Engine

/// Snapshot replication (Sources/Engine/Net, cards 624 and 662) over the loopback and UDP
/// transports: deltas, interpolation under latency and loss, the compact encodings (quantized
/// Transform, binary Codable, zlib), priorities and the bandwidth budget.
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
        let server = NetServer(world: serverWorld, transport: serverEnd, secret: 99)
        let client = NetClient(world: World(), transport: clientEnd, server: serverEnd.id, salt: 5)
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

    /// What a quantized Transform looks like after the trip.
    func quantized(_ t: Transform?) -> Transform? {
        t.flatMap { try? NetComponentCoder.decodeTransform(NetComponentCoder.encodeTransform($0)) }
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
        // Then still for a while: the client must end up with exactly the server's state (as
        // quantized: Transforms are sent to 1/1024 m and ~0.1 degree).
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
            #expect(transform == quantized(world.get(Transform.self, for: entity)))
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
    /// motion interpolates exactly, up to the 1 mm quantization), it never runs out of
    /// snapshots, and it moves smoothly.
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
            // Snapshot times are multiples of dt, positions speed * time: exact up to quantization.
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
        var time = run(server, client, network: network, seconds: 0.3)
        let peer = server.clients[0]
        // The first snapshot was full; by now the client has acked and deltas are empty.
        let full = NetSnapshot(tick: 1, serverTime: 0, state: server.captureState(), baseline: nil, baselineTick: nil).encoded()
        let compressed = NetCompression.deflate(full)
        let empty = server.lastSnapshotBytes[peer]!
        #expect(empty < 24)
        // The prototype (raw Transforms, JSON, 16-byte ids everywhere) needed 18342 bytes.
        #expect(full.count < 200 * 56)
        #expect(compressed.count < full.count / 2)

        // 10 of 200 move: ~10 quantized Transforms plus baseline indices.
        time = run(server, client, network: network, from: time, seconds: 1.0 / 60.0) { _ in
            for e in entities.prefix(10) { server.world.modify(Transform.self, for: e) { $0.position.z += 1 } }
        }
        let delta = server.lastSnapshotBytes[peer]!
        #expect(delta < 10 * (1 + 1 + 1 + 1 + 3) + 32) // a gap, a count, the Transform header and a 3-byte delta
        _ = run(server, client, network: network, from: time, seconds: 0.2)
        #expect(clientState(client).count == 200)
        print("NetworkingTests: 200 entities: full snapshot \(full.count) bytes (zlib \(compressed.count)), 10 moved: \(delta) bytes, none: \(empty) bytes")
    }

    @Test func snapshotRoundTripAndMalformedInput() throws {
        let a = EntityID(high: 1, low: 2), b = EntityID(high: 3, low: 4), c = EntityID(high: 5, low: 6)
        let base: NetWorldState = [a: ["Transform": [1, 2, 3], "X": [9]], b: ["Transform": [4]]]
        let state: NetWorldState = [a: ["Transform": [1, 2, 3, 4]], c: ["Y": []]]
        let delta = NetSnapshot(tick: 9, serverTime: 1.5, state: state, baseline: base, baselineTick: 8)
        #expect(delta.removed == [b])
        let bytes = delta.encoded(baseline: base)
        let decoded = try NetSnapshot(decoding: bytes, baseline: base)
        #expect(decoded == delta)
        #expect(decoded.applied(to: base) == state)
        #expect(try NetSnapshot.header(of: bytes) == (9, 8))
        // A delta can't be read without its baseline.
        #expect(throws: NetError.self) { try NetSnapshot(decoding: bytes) }
        // Every truncation fails cleanly rather than crashing.
        for n in 0..<bytes.count { #expect(throws: NetError.self) { try NetSnapshot(decoding: Array(bytes.prefix(n)), baseline: base) } }
        // So do references past the baseline (a smaller baseline than the encoder's).
        #expect(throws: NetError.self) { try NetSnapshot(decoding: bytes, baseline: [b: [:]]) }
        // Compression round trip, and a corrupt stream throws.
        let packed = NetCompression.deflate(bytes)
        #expect(try NetCompression.inflate(packed) == bytes)
        var corrupt = packed
        corrupt[corrupt.count / 2] ^= 0xFF
        #expect(throws: NetError.self) { try NetCompression.inflate(corrupt) }
        #expect(throws: NetError.self) { try NetCompression.inflate([0xFF, 0xFF, 0xFF, 0x7F]) } // a 256 MB claim
    }

    /// Large snapshots go out in fragments; one lost fragment loses that snapshot only.
    @Test func fragmentedSnapshots() {
        let network = LoopbackNetwork(conditions: LinkConditions(loss: 0.02), seed: 11)
        let (server, client, entities) = makeSession(network: network, count: 300)
        _ = run(server, client, network: network, seconds: 1.5) { t in
            for e in entities {
                server.world.modify(Transform.self, for: e) {
                    $0.position = Vec3(-30, 20, 30) * Float(t)
                    $0.rotation = Quat(angle: Float(t), axis: Vec3(0, 1, 0))
                }
            }
        }
        #expect(server.lastSnapshotBytes[server.clients[0]]! > NetLimits.maxDatagramSize * 3)
        _ = run(server, client, network: network, from: 1.5, seconds: 0.5)
        let state = clientState(client)
        #expect(state.count == 300)
        let expected = quantized(server.world.get(Transform.self, for: entities[0]))!
        #expect(state.values.allSatisfy { $0.0?.position.y == expected.position.y && $0.0?.rotation == expected.rotation })
        #expect(client.stats.snapshots < server.tick) // some were lost with a fragment
    }

    // MARK: Encodings

    @Test func quantizedTransformPrecision() throws {
        var generator = SplitMix64(seed: 662)
        func unit() -> Float { Float(generator.nextUnit()) * 2 - 1 }
        var maxPosition: Float = 0
        var maxAngle: Float = 0
        var sizes: [Int] = []
        for _ in 0..<2000 {
            let axis = normalize(Vec3(unit(), unit(), unit()) + Vec3(0, 0.01, 0))
            let t = Transform(position: Vec3(unit(), unit(), unit()) * 500, rotation: Quat(angle: unit() * .pi, axis: axis))
            let bytes = NetComponentCoder.encodeTransform(t)
            sizes.append(bytes.count)
            let back = try NetComponentCoder.decodeTransform(bytes)
            maxPosition = max(maxPosition, length(back.position - t.position))
            let d = abs((back.rotation.vector * t.rotation.vector).sum())
            maxAngle = max(maxAngle, 2 * acosf(min(1, d)) * 180 / .pi)
            #expect(back.scale == .one)
            // Quantizing is idempotent: what the client has re-encodes to the same bytes.
            #expect(NetComponentCoder.encodeTransform(back) == bytes)
        }
        // Half a step on each axis, and about a tenth of a degree.
        #expect(maxPosition <= NetComponentCoder.positionStep * 0.5 * 1.74)
        #expect(maxAngle < 0.2)
        #expect(sizes.max()! <= 1 + 3 * 3 + 4)
        // Exact: bit for bit, 41 bytes. Scaled: one float for uniform scale, three otherwise.
        let odd = Transform(position: Vec3(0.1, -2e6, 3), rotation: Quat(angle: 0.3, axis: Vec3(0, 1, 0)), scale: Vec3(1, 2, 3))
        #expect(try NetComponentCoder.decodeTransform(NetComponentCoder.encodeTransform(odd, .exact)) == odd)
        #expect(NetComponentCoder.encodeTransform(odd, .exact).count == 41)
        #expect(try NetComponentCoder.decodeTransform(NetComponentCoder.encodeTransform(odd)) == odd) // out of range: sent exact
        #expect(NetComponentCoder.encodeTransform(Transform(scale: Vec3(repeating: 2))).count == 1 + 3 + 4)
        #expect(NetComponentCoder.encodeTransform(Transform()).count == 4)
        for n in 0..<41 {
            #expect(throws: NetError.self) { try NetComponentCoder.decodeTransform(Array(NetComponentCoder.encodeTransform(odd, .exact).prefix(n))) }
        }
        print("NetworkingTests: quantized Transform: \(sizes.min()!)-\(sizes.max()!) bytes within 500 m, error \(maxPosition * 1000) mm, \(maxAngle) degrees")
    }

    struct NetworkingTestsRecord: Codable, Equatable {
        enum Kind: String, Codable { case a, b }
        var name: String
        var count: Int
        var big: UInt64
        var negative: Int32
        var ratio: Double
        var weight: Float
        var flag: Bool
        var optional: Int?
        var missing: String?
        var position: Vec3
        var rotation: Quat
        var list: [Int16]
        var nested: [[String]]
        var table: [String: Float]
        var kind: Kind
        var id: EntityID
    }

    @Test func binaryCoderRoundTrip() throws {
        let record = NetworkingTestsRecord(
            name: "crate ✓", count: -123456, big: .max, negative: .min, ratio: .pi, weight: -0.0, flag: true, optional: 7, missing: nil,
            position: Vec3(1, 2, 3), rotation: Quat(angle: 1, axis: Vec3(0, 1, 0)), list: [1, -2, 300], nested: [[], ["x", "y"]],
            table: ["b": 2, "a": .infinity], kind: .b, id: EntityID(high: 1, low: 2))
        let bytes = try NetBinaryEncoder().encode(record)
        #expect(try NetBinaryDecoder().decode(NetworkingTestsRecord.self, from: bytes) == record)
        // Deterministic (dictionary keys sorted), and much smaller than JSON.
        #expect(try NetBinaryEncoder().encode(record) == bytes)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        let json = try encoder.encode(record).count
        #expect(bytes.count < json * 9 / 10)
        #expect(try NetComponentCoder.encode(CharacterController()).count < 100)
        // Components: the controller (what prediction reconciles from) survives exactly.
        var controller = CharacterController(radius: 0.4)
        controller.verticalVelocity = 1.2345678
        controller.groundNormal = normalize(Vec3(0.1, 1, 0))
        let controllerBytes = try NetComponentCoder.encode(controller)
        #expect(try NetComponentCoder.decode(controllerBytes, as: CharacterController.componentName) as? CharacterController == controller)
        let health = try NetComponentCoder.encode(NetworkingTestsHealth(hp: 100, label: "unit 7"))
        let healthJSON = try encoder.encode(NetworkingTestsHealth(hp: 100, label: "unit 7")).count
        // Malformed input throws, never traps.
        for n in 0..<bytes.count { #expect(throws: (any Error).self) { try NetBinaryDecoder().decode(NetworkingTestsRecord.self, from: Array(bytes.prefix(n))) } }
        #expect(throws: (any Error).self) { try NetBinaryDecoder().decode(Int8.self, from: NetBinaryEncoder().encode(300)) }
        #expect(throws: (any Error).self) { try NetBinaryDecoder().decode([Int].self, from: [8, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F]) }
        let deep = [UInt8](repeating: 8, count: 200) + [0]
        #expect(throws: (any Error).self) { try NetBinaryDecoder().decode([Int].self, from: deep) }
        print("NetworkingTests: binary record \(bytes.count) B (JSON \(json) B), CharacterController \(controllerBytes.count) B, health \(health.count) B (JSON \(healthJSON) B)")
    }

    // MARK: Bandwidth

    /// 300 replicated entities (Transform with rotation + a small component) at 30 Hz: the
    /// bytes per second the server sends one client, packet headers included.
    func measureBandwidth(moving: Int, limit: Int?, compression: NetSnapshotCompression = .fullSnapshots,
                          seconds: Double = 4) -> (kbits: Double, joinBytes: Int, entitiesPerSnapshot: Double, maxStaleness: Double) {
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.05), seed: 9)
        let (server, client, entities) = makeSession(network: network, count: 300)
        server.bandwidthLimit = limit
        server.compression = compression
        for (i, e) in entities.enumerated() {
            server.world.modify(Transform.self, for: e) {
                $0.position = Vec3(Float(i % 20) * 2 - 20, 0.5, Float(i / 20) * 2 - 15)
                $0.rotation = Quat(angle: Float(i), axis: Vec3(0, 1, 0))
            }
        }
        func move(_ t: Double) {
            for (i, e) in entities.prefix(moving).enumerated() {
                server.world.modify(Transform.self, for: e) {
                    $0.position.y = 0.5 + Float(sin(t * 2 + Double(i)))
                    $0.rotation = Quat(angle: Float(t) + Float(i), axis: Vec3(0, 1, 0))
                }
            }
        }
        var time = run(server, client, network: network, seconds: 1.5, body: move)
        let serverID = PeerID(1) // makeSession makes the server endpoint first
        let joinBytes = network.statsBySender[serverID]!.bytesSent
        let before = network.statsBySender[serverID]!.bytesSent
        var entitiesSent = 0
        var snapshots = 0
        var lastTick = server.tick
        // How old the client's newest copy of each entity is: the server time of the last
        // snapshot that carried a change to it.
        var maxStaleness = 0.0
        time = run(server, client, network: network, from: time, seconds: seconds) { t in
            move(t)
            if server.tick != lastTick, let deferred = server.lastSnapshotDeferred[server.clients[0]] {
                lastTick = server.tick
                snapshots += 1
                entitiesSent += moving - deferred
            }
        }
        if moving > 0 {
            // Every moving entity is changed every snapshot; one waits at most
            // (moving / entities per snapshot) snapshots.
            maxStaleness = Double(moving) / max(1, Double(entitiesSent) / Double(snapshots)) * server.sendInterval
        }
        let bytes = network.statsBySender[serverID]!.bytesSent - before
        _ = time
        return (Double(bytes) * 8 / seconds / 1000, joinBytes, Double(entitiesSent) / Double(max(snapshots, 1)), maxStaleness)
    }

    @Test func bandwidth300Entities() {
        let idle = measureBandwidth(moving: 0, limit: nil)
        let some = measureBandwidth(moving: 30, limit: nil)
        let all = measureBandwidth(moving: 300, limit: nil)
        let allZlib = measureBandwidth(moving: 300, limit: nil, compression: .all)
        // 256 kbit/s = 32000 B/s; leave room for packet headers.
        let budgeted = measureBandwidth(moving: 300, limit: 30_000, compression: .all)
        print("NetworkingTests: 300 entities at 30 Hz: idle \(idle.kbits) kbit/s (join \(idle.joinBytes) B in 1.5 s), "
              + "30 moving \(some.kbits) kbit/s, 300 moving \(all.kbits) kbit/s, with zlib \(allZlib.kbits) kbit/s, "
              + "budget 30000 B/s: \(budgeted.kbits) kbit/s, \(budgeted.entitiesPerSnapshot) entities per snapshot, "
              + "each updated at least every \(budgeted.maxStaleness) s")
        #expect(idle.kbits < 16)
        #expect(some.kbits < 128)
        #expect(all.kbits > 256) // everything moving doesn't fit without a budget
        #expect(budgeted.kbits < 256)
        #expect(budgeted.entitiesPerSnapshot > 50)
        #expect(budgeted.maxStaleness < 0.25)
    }

    /// With a budget, entities with a higher `Replicated.priority` are sent proportionally more
    /// often, and everything still converges once movement stops.
    @Test func priorityAndBudgetConverge() {
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.03, loss: 0.05), seed: 21)
        let (server, client, entities) = makeSession(network: network, count: 100)
        for e in entities.prefix(10) { server.world.modify(Replicated.self, for: e) { $0.priority = 4 } }
        server.bandwidthLimit = 6000
        var sentCount: [EntityID: Int] = [:]
        var previous: [EntityID: Transform] = [:]
        var time = run(server, client, network: network, seconds: 4) { t in
            for e in entities { server.world.modify(Transform.self, for: e) { $0.position.y = Float(t) } }
            // Count how often the client's newest copy changed, per entity.
            for entity in client.world.entities {
                guard let id = client.world.id(of: entity), let transform = client.world.get(Transform.self, for: entity) else { continue }
                if previous[id] != transform { sentCount[id, default: 0] += 1 }
                previous[id] = transform
            }
        }
        #expect(server.lastSnapshotDeferred[server.clients[0]]! > 0)
        let ids = entities.map { server.world.id(of: $0)! }
        let high = ids.prefix(10).map { sentCount[$0, default: 0] }.reduce(0, +) / 10
        let low = ids.dropFirst(10).map { sentCount[$0, default: 0] }.reduce(0, +) / 90
        #expect(high > low * 2)
        time = run(server, client, network: network, from: time, seconds: 3)
        let state = clientState(client)
        #expect(state.count == 100)
        for e in entities {
            #expect(state[server.world.id(of: e)!]?.0 == quantized(server.world.get(Transform.self, for: e)))
        }
        print("NetworkingTests: priority 4 vs 1 under a 6000 B/s budget: \(high) vs \(low) updates seen in 4 s")
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
        #expect(client.clientID == NetClientID(1))
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
