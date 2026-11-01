import Foundation
import Testing
@testable import Engine

/// A backlog under a byte budget (card 672): new entities that don't fit one snapshot drain at
/// about the budget's rate, not one per acknowledgement round; entities carried by snapshots in
/// flight stay on the client (no spawn / despawn flicker); idle deltas cost what they did; scene
/// entities the server lacks are removed although the budget always defers something.
@MainActor @Suite struct NetBacklogTests {
    struct NetBacklogTestsTag: Component, Equatable {
        static let componentName = "NetBacklogTestsTag"
        var label: String
    }

    static let components = [Transform.componentName, NetBacklogTestsTag.componentName]
    /// The link of the #671 repro: 50 ms + 40 ms jitter, 15% loss, 5% duplication each way.
    static let lossy = LinkConditions(latency: 0.05, jitter: 0.04, loss: 0.15, duplicate: 0.05)

    init() {
        ComponentRegistry.register(NetBacklogTestsTag.self)
    }

    /// Ids from a counter: entities spawned later sort later.
    func makeSession(network: LoopbackNetwork, serverWorld: World = World(), clientWorld: World = World(), firstID: UInt64 = 1)
        -> (server: NetServer, client: NetClient) {
        var next = firstID
        serverWorld.entityIDGenerator = {
            defer { next += 1 }
            return EntityID(high: 672, low: next)
        }
        let serverEnd = network.makeEndpoint()
        let clientEnd = network.makeEndpoint()
        let server = NetServer(world: serverWorld, transport: serverEnd, secret: 3)
        let client = NetClient(world: clientWorld, transport: clientEnd, server: serverEnd.id, salt: 8)
        return (server, client)
    }

    @discardableResult
    func run(_ server: NetServer, _ client: NetClient, network: LoopbackNetwork, from start: Double = 0, seconds: Double,
             body: (Double) -> Bool = { _ in true }) -> Double {
        let dt = 1.0 / 60.0
        var time = start
        for _ in 0..<Int((seconds / dt).rounded()) {
            guard body(time) else { break }
            network.now = time
            server.update(time: time)
            client.update(dt: dt)
            time += dt
        }
        return time
    }

    func spawn(_ world: World, _ label: String, at position: Vec3) -> Entity {
        let entity = world.spawn(Transform(position: position), NetBacklogTestsTag(label: label), Replicated(components: Self.components))
        world.ensureID(of: entity)
        return entity
    }

    func labels(_ world: World) -> Set<String> {
        var result: Set<String> = []
        world.query(NetBacklogTestsTag.self) { _, tag in result.insert(tag.label) }
        return result
    }

    /// Spawns `count` new entities at once on a connected, idle session limited to `limit` B/s and
    /// returns how long until the client has all of them, the bytes one new entity costs in a
    /// snapshot, and how often an entity the client had shown went away again.
    func drain(count: Int, limit: Int, seed: UInt64) -> (seconds: Double, entityBytes: Int, flickers: Int, deferredSeen: Bool, bytesPerSecond: Double) {
        let network = LoopbackNetwork(conditions: Self.lossy, seed: seed)
        let (server, client) = makeSession(network: network)
        let world = server.world
        _ = spawn(world, "anchor", at: .zero)
        var time = run(server, client, network: network, seconds: 1)
        // What one new entity costs: a snapshot with one against the idle one.
        let peer = server.clients[0]
        let idle = server.lastSnapshotBytes[peer]!
        _ = spawn(world, "probe", at: Vec3(0, 2, 0))
        time = run(server, client, network: network, from: time, seconds: 1.0 / 60.0) { _ in true }
        time = run(server, client, network: network, from: time, seconds: 1.0 / 60.0) { _ in true }
        let entityBytes = server.lastSnapshotBytes[peer]! - idle
        time = run(server, client, network: network, from: time, seconds: 1)

        server.bandwidthLimit = limit
        var expected = labels(world)
        for i in 0..<count { _ = spawn(world, "e\(i)", at: Vec3(Float(i % 6), 0, Float(i / 6))) }
        expected.formUnion((0..<count).map { "e\($0)" })
        let start = time
        let serverPeer = (server.transport as! LoopbackTransport).id
        let bytesBefore = network.statsBySender[serverPeer]!.bytesSent
        var done: Double?
        var seen: Set<String> = []
        var flickers = 0
        var deferredSeen = false
        time = run(server, client, network: network, from: time, seconds: 20) { t in
            let now = labels(client.world)
            flickers += seen.subtracting(now).count
            seen.formUnion(now)
            if (server.lastSnapshotDeferred[peer] ?? 0) > 0 { deferredSeen = true }
            if now == expected, done == nil { done = t - start }
            return done == nil
        }
        #expect(client.stats.missingBaseline == 0)
        #expect(client.stats.malformed == 0)
        let rate = Double(network.statsBySender[serverPeer]!.bytesSent - bytesBefore) / (time - start)
        return (done ?? .infinity, entityBytes, flickers, deferredSeen, rate)
    }

    /// The #671 repro: 36 new entities at 600 B/s with 15% loss each way. 600 B/s is 20 B per
    /// snapshot, less than one entity, so each snapshot carries one (the budget's minimum): 36
    /// snapshots, 1.2 s, if nothing were lost. Each attempt arrives with p = 0.85; a lost one is
    /// sent again once a later ack shows it missing (about a round trip, ~0.2 s here). Bound:
    /// 36 / 30 / 0.85 + 5 round trips ≈ 2.4 s (30 seeds: 1.47-2.0 s). Before card 672: 6.5 s.
    @Test func backlogDrainsAtBudgetRate() {
        for seed: UInt64 in [672, 673, 674] {
            let result = drain(count: 36, limit: 600, seed: seed)
            print("NetBacklogTests: 36 entities at 600 B/s, 15% loss (seed \(seed)): all there after \(result.seconds) s, "
                  + "\(result.entityBytes) B per entity, \(result.flickers) flickers, \(Int(result.bytesPerSecond)) B/s sent")
            #expect(result.deferredSeen)
            #expect(result.flickers == 0)
            #expect(result.seconds < 36.0 / 30 / 0.85 + 5 * 0.2)
        }
        // A larger budget drains proportionally faster: 120 entities at 6000 B/s is 200 B per
        // snapshot, (200 - ~20 B of headers) / entity bytes per snapshot.
        let big = drain(count: 120, limit: 6000, seed: 675)
        let perSnapshot = max(1, (6000 / 30 - 20) / big.entityBytes)
        let bound = 120.0 / Double(perSnapshot) / 30 / 0.85 + 5 * 0.2
        print("NetBacklogTests: 120 entities at 6000 B/s, 15% loss: all there after \(big.seconds) s "
              + "(\(perSnapshot) per snapshot by the budget, bound \(bound) s), \(big.flickers) flickers, \(Int(big.bytesPerSecond)) B/s sent")
        #expect(big.flickers == 0)
        #expect(big.seconds < bound)
    }

    /// With nothing backlogged, snapshots are what they were: idle deltas of 200 entities stay at
    /// the empty delta's size (17 bytes, 19 before card 672) under loss and a budget that isn't
    /// reached, and they never merge acknowledged snapshots.
    @Test func idleDeltasStaySmall() {
        let network = LoopbackNetwork(conditions: LinkConditions(latency: 0.05, jitter: 0.02, loss: 0.1), seed: 676)
        let (server, client) = makeSession(network: network)
        for i in 0..<200 { _ = spawn(server.world, "e\(i)", at: Vec3(Float(i), 0, 0)) }
        server.bandwidthLimit = 100_000
        var time = run(server, client, network: network, seconds: 1.5)
        let peer = server.clients[0]
        var largest = 0
        var lastTick = server.tick
        time = run(server, client, network: network, from: time, seconds: 3) { _ in
            if server.tick != lastTick {
                lastTick = server.tick
                largest = max(largest, server.lastSnapshotBytes[peer] ?? 0)
            }
            return true
        }
        print("NetBacklogTests: 200 idle entities, 10% loss: largest delta \(largest) B")
        #expect(largest <= 17)
        #expect(labels(client.world).count == 200)
    }

    /// A scene on both sides with 40 entities that always move and a budget that never fits all
    /// of them (every snapshot defers some): the entity the server removed before the client
    /// joined still goes, once every server entity is on the client (values lag, the set doesn't).
    /// Before card 672 it stayed: cleanup waited for a snapshot with nothing deferred.
    @Test func cleanupUnderABudgetThatAlwaysDefers() throws {
        let (serverWorld, clientWorld, gone) = try sharedScene(count: 40)
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 677)
        let (server, client) = makeSession(network: network, serverWorld: serverWorld, clientWorld: clientWorld, firstID: 1000)
        server.bandwidthLimit = 1500
        let movers = serverWorld.entities.filter { serverWorld.has(Replicated.self, for: $0) }
        let loaded = Set(clientWorld.entities)
        let goneHandle = try #require(clientWorld.entity(for: gone))
        var removedAt: Double?
        var alwaysDeferred = true
        let peer = { server.clients.first }
        run(server, client, network: network, seconds: 4) { t in
            for (i, e) in movers.enumerated() { serverWorld.modify(Transform.self, for: e) { $0.position.y = Float(sin(t * 3 + Double(i))) } }
            if t > 0.3, let p = peer(), server.lastSnapshotDeferred[p] == 0 { alwaysDeferred = false }
            if removedAt == nil, clientWorld.entity(for: gone) == nil { removedAt = t }
            return true
        }
        print("NetBacklogTests: 40 movers at 1500 B/s, every snapshot deferring: the unmatched entity went after \(removedAt ?? .infinity) s")
        #expect(alwaysDeferred)
        #expect(removedAt.map { $0 < 40.0 / 30 / 0.85 + 1 } == true)
        // Nothing else went: the 40 matched entities and the camera are the ones loaded.
        #expect(Set(clientWorld.entities) == loaded.subtracting([goneHandle]))
    }

    /// Under a budget with a backlog of 100 new entities, the removed scene entity goes as soon as
    /// no entity still missing sorts next to it (the snapshot lists where the missing ones sort),
    /// long before the backlog has drained.
    @Test func cleanupWhileABacklogDrains() throws {
        let (serverWorld, clientWorld, gone) = try sharedScene(count: 20)
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 678)
        let (server, client) = makeSession(network: network, serverWorld: serverWorld, clientWorld: clientWorld, firstID: 1000)
        server.bandwidthLimit = 600
        for i in 0..<100 { _ = spawn(serverWorld, "new\(i)", at: Vec3(Float(i), 0, 3)) }
        let expected = labels(serverWorld)
        var removedAt: Double?
        var drainedAt: Double?
        run(server, client, network: network, seconds: 8) { t in
            if removedAt == nil, clientWorld.entity(for: gone) == nil { removedAt = t }
            if drainedAt == nil, labels(clientWorld) == expected { drainedAt = t }
            return drainedAt == nil
        }
        print("NetBacklogTests: 20 scene entities + 100 new at 600 B/s: the unmatched one went after \(removedAt ?? .infinity) s, "
              + "the backlog drained after \(drainedAt ?? .infinity) s")
        #expect(removedAt != nil)
        #expect(drainedAt != nil)
        if let removedAt, let drainedAt { #expect(removedAt < drainedAt - 1) }
        #expect(clientWorld.count(of: Camera.self) == 1)
    }

    /// The version 3 sections: merged ticks, removals of ids outside the baseline, gaps; every
    /// truncation is rejected.
    @Test func wireFormatSections() throws {
        let a = EntityID(high: 1, low: 2), b = EntityID(high: 3, low: 4), c = EntityID(high: 5, low: 6), d = EntityID(high: 7, low: 8)
        let base: NetWorldState = [a: ["Transform": [1]], b: ["Transform": [2]]]
        var delta = NetSnapshot(tick: 40, serverTime: 2, state: [a: ["Transform": [3]]], baseline: base, baselineTick: 37)
        delta.mergedTicks = [33, 36]
        delta.removed.append(d) // not in the baseline: by id
        delta.complete = false
        delta.pendingGaps = [0, 2]
        let bytes = delta.encoded(baseline: base)
        let decoded = try NetSnapshot(decoding: bytes, baseline: base)
        #expect(decoded == delta)
        #expect(try NetSnapshot.references(of: bytes) == (40, 37, [33, 36]))
        for n in 0..<bytes.count { #expect(throws: NetError.self) { try NetSnapshot(decoding: Array(bytes.prefix(n)), baseline: base) } }
        // Too many gaps: incomplete without them.
        delta.pendingGaps = Array(0...NetSnapshot.maxPendingGaps)
        let unknown = try NetSnapshot(decoding: delta.encoded(baseline: base), baseline: base)
        #expect(!unknown.complete && unknown.pendingGaps == nil)
        // A full snapshot is unchanged by the sections it doesn't use.
        let full = NetSnapshot(tick: 1, serverTime: 0, state: [c: [:]], baseline: nil, baselineTick: nil)
        #expect(try NetSnapshot(decoding: full.encoded()) == full)
    }

    /// A scene saved and loaded into a server and a client world: `count` replicated entities
    /// (ids 1...), one more in the middle of them that the server then removes, and a camera.
    func sharedScene(count: Int) throws -> (server: World, client: World, gone: EntityID) {
        let scene = World()
        var next: UInt64 = 1
        scene.entityIDGenerator = {
            defer { next += 1 }
            return EntityID(high: 672, low: next)
        }
        var goneID: EntityID?
        for i in 0...count {
            let entity = spawn(scene, i == count / 2 ? "gone" : "s\(i)", at: Vec3(Float(i), 0, 0))
            if i == count / 2 { goneID = scene.id(of: entity) }
        }
        let camera = scene.spawn(Transform(position: Vec3(0, 5, 10)), Camera())
        scene.ensureID(of: camera)
        let data = try scene.save()
        let serverWorld = World(), clientWorld = World()
        try serverWorld.load(data)
        try clientWorld.load(data)
        let gone = try #require(goneID)
        serverWorld.despawn(try #require(serverWorld.entity(for: gone)))
        return (serverWorld, clientWorld, gone)
    }
}
