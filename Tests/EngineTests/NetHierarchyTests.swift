import Foundation
import Testing
@testable import Engine

/// Replication of hierarchy and references (card 671, phase 4): parent links by `EntityID`
/// with any spawn order, reparenting and despawned parents; `Entity` and `EntityRef` fields
/// mapped to the client's entities once their targets arrive; scene entities both sides loaded
/// matched by id. Under loss, jitter (reordering) and duplication.
@MainActor @Suite struct NetHierarchyTests {
    struct NetHierarchyTestsTag: Component, Equatable {
        static let componentName = "NetHierarchyTestsTag"
        var label: String
    }

    struct NetHierarchyTestsFollow: Component, Equatable {
        static let componentName = "NetHierarchyTestsFollow"
        var target: Entity = .invalid
        var ref = EntityRef()
        var optional: Entity?
        var list: [Entity] = []
    }

    static let all = [Transform.componentName, NetHierarchyTestsTag.componentName, NetHierarchyTestsFollow.componentName]

    init() {
        ComponentRegistry.register(NetHierarchyTestsTag.self, NetHierarchyTestsFollow.self)
    }

    /// A server over `network` and one client, ids from a counter that counts *down*, so later
    /// entities sort first: a child spawned after its parent is listed before it in snapshots.
    func makeSession(network: LoopbackNetwork, serverWorld: World = World(), clientWorld: World = World())
        -> (server: NetServer, client: NetClient) {
        var next: UInt64 = 1_000
        serverWorld.entityIDGenerator = {
            next -= 1
            return EntityID(high: 671, low: next)
        }
        let serverEnd = network.makeEndpoint()
        let clientEnd = network.makeEndpoint()
        let server = NetServer(world: serverWorld, transport: serverEnd, secret: 4)
        let client = NetClient(world: clientWorld, transport: clientEnd, server: serverEnd.id, salt: 6)
        return (server, client)
    }

    @discardableResult
    func run(_ server: NetServer, _ client: NetClient, network: LoopbackNetwork, from start: Double = 0, seconds: Double,
             body: (Double) -> Void = { _ in }) -> Double {
        let dt = 1.0 / 60.0
        var time = start
        for _ in 0..<Int((seconds / dt).rounded()) {
            body(time)
            network.now = time
            server.world.update(dt: dt)
            server.update(time: time)
            client.update(dt: dt)
            time += dt
        }
        return time
    }

    func spawn(_ world: World, _ label: String, at position: Vec3 = .zero, parent: Entity? = nil) -> Entity {
        let entity = world.spawn(Transform(position: position), NetHierarchyTestsTag(label: label), Replicated(components: Self.all))
        if let parent { world.setParent(entity, to: parent) }
        world.ensureID(of: entity)
        return entity
    }

    /// Every replicated server entity's parent id, by id (nil: a root).
    func hierarchy(_ world: World, replicatedOnly: Bool = true) -> [EntityID: EntityID?] {
        var result: [EntityID: EntityID?] = [:]
        for entity in world.entities where !replicatedOnly || world.has(Replicated.self, for: entity) {
            guard let id = world.id(of: entity) else { continue }
            result[id] = .some(world.parent(of: entity).flatMap { world.id(of: $0) })
        }
        return result
    }

    func clientHierarchy(_ client: NetClient) -> [EntityID: EntityID?] {
        let world = client.world
        var result: [EntityID: EntityID?] = [:]
        for entity in world.entities {
            guard let id = world.id(of: entity) else { continue }
            result[id] = .some(world.parent(of: entity).flatMap { world.id(of: $0) })
        }
        return result
    }

    /// World positions of every entity with a tag, by label.
    func worldPositions(_ world: World) -> [String: Vec3] {
        var result: [String: Vec3] = [:]
        world.query(NetHierarchyTestsTag.self) { entity, tag in result[tag.label] = Transform(matrix: world.worldMatrix(of: entity)).position }
        return result
    }

    static let lossy = LinkConditions(latency: 0.05, jitter: 0.04, loss: 0.15, duplicate: 0.05)

    @Test func childrenBeforeParentsKeepTheirHierarchy() {
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 11)
        let (server, client) = makeSession(network: network)
        let world = server.world
        // Spawned parent first, so (ids counting down) every child sorts before its parent.
        let root = spawn(world, "root", at: Vec3(10, 0, 0))
        let arm = spawn(world, "arm", at: Vec3(0, 2, 0), parent: root)
        let hand = spawn(world, "hand", at: Vec3(1, 0, 0), parent: arm)
        _ = spawn(world, "leg", at: Vec3(0, -1, 0), parent: root)
        #expect(world.id(of: hand)! < world.id(of: arm)! && world.id(of: arm)! < world.id(of: root)!)
        world.modify(Transform.self, for: root) { $0.rotation = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0)) }

        // Moving the root moves the subtree on the client, through the hierarchy.
        let time = run(server, client, network: network, seconds: 2) { t in
            world.modify(Transform.self, for: root) { $0.position.x = 10 + Float(t) }
        }
        run(server, client, network: network, from: time, seconds: 1)

        #expect(clientHierarchy(client) == hierarchy(world))
        #expect(client.unresolvedParents.isEmpty)
        let expected = worldPositions(world), actual = worldPositions(client.world)
        #expect(expected.count == 4 && actual.count == 4)
        for (label, position) in expected {
            #expect(length(actual[label]! - position) < 0.01, "\(label): \(actual[label]!) vs \(position)")
        }
        // The hand: the root turned 90 degrees, arm 2 up, hand 1 along the arm's x (now -z).
        let rootX = world.get(Transform.self, for: root)!.position.x
        #expect(length(actual["hand"]! - Vec3(rootX, 2, -1)) < 0.01)
        #expect(network.stats.dropped > 0)
    }

    @Test func reparentingAndDespawnedParents() {
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 12)
        let (server, client) = makeSession(network: network)
        let world = server.world
        let a = spawn(world, "a", at: Vec3(1, 0, 0))
        let b = spawn(world, "b", at: Vec3(0, 1, 0), parent: a)
        let c = spawn(world, "c", at: Vec3(0, 0, 1), parent: b)
        let d = spawn(world, "d", at: Vec3(2, 0, 0))
        let e = spawn(world, "e", at: Vec3(0, 3, 0), parent: d)
        let f = spawn(world, "f", at: Vec3(0, 0, 3), parent: d)
        var time = run(server, client, network: network, seconds: 1)
        #expect(clientHierarchy(client) == hierarchy(world))

        // In one tick: a and b swap places (b becomes the root, a its child), c moves to d,
        // e becomes a root, then d is despawned (taking f with it).
        world.setParent(b, to: nil)
        world.setParent(a, to: b)
        world.setParent(c, to: d)
        world.setParent(c, to: a)
        world.setParent(e, to: nil)
        world.despawn(d)
        #expect(!world.isAlive(f))
        time = run(server, client, network: network, from: time, seconds: 1.5)
        #expect(clientHierarchy(client) == hierarchy(world))
        #expect(Set(worldPositions(client.world).keys) == ["a", "b", "c", "e"])

        // A parent despawned while its child stays: the server detaches the child first.
        world.setParent(c, to: nil)
        world.despawn(a)
        time = run(server, client, network: network, from: time, seconds: 1.5)
        #expect(clientHierarchy(client) == hierarchy(world))
        let expected = worldPositions(world), actual = worldPositions(client.world)
        #expect(Set(actual.keys) == ["b", "c", "e"])
        for (label, position) in expected { #expect(length(actual[label]! - position) < 0.01, "\(label)") }
        #expect(client.stats.malformed == 0)
    }

    /// A replicated child of an entity that isn't replicated (yet): a root on the client until
    /// the parent arrives, then attached. And under a tight budget, new parents travel with
    /// their new children, so the client never sees one without the other.
    @Test func unresolvedParentsAndBudgets() {
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 13)
        let (server, client) = makeSession(network: network)
        let world = server.world
        let holder = world.spawn(Transform(position: Vec3(5, 0, 0)), NetHierarchyTestsTag(label: "holder"))
        let item = spawn(world, "item", at: Vec3(0, 1, 0), parent: holder)
        var time = run(server, client, network: network, seconds: 1)
        let itemID = world.id(of: item)!
        #expect(client.unresolvedParents == [itemID])
        #expect(client.world.entity(for: itemID).flatMap { client.world.parent(of: $0) } == nil)
        #expect(worldPositions(client.world)["item"].map { length($0 - Vec3(0, 1, 0)) < 0.01 } == true)

        world.add(Replicated(components: Self.all), to: holder)
        time = run(server, client, network: network, from: time, seconds: 1)
        #expect(client.unresolvedParents.isEmpty)
        #expect(clientHierarchy(client) == hierarchy(world))
        #expect(length(worldPositions(client.world)["item"]! - Vec3(5, 1, 0)) < 0.01)

        // Budget: about one entity per snapshot. 12 new subtrees of three at once.
        server.bandwidthLimit = 600
        var roots: [Entity] = []
        for i in 0..<12 {
            let root = spawn(world, "r\(i)", at: Vec3(Float(i), 0, 0))
            let mid = spawn(world, "m\(i)", at: Vec3(0, 1, 0), parent: root)
            _ = spawn(world, "l\(i)", at: Vec3(0, 1, 0), parent: mid)
            roots.append(root)
        }
        var orphanFrames = 0
        var deferredSeen = false
        time = run(server, client, network: network, from: time, seconds: 6) { _ in
            if !client.unresolvedParents.isEmpty { orphanFrames += 1 }
            if (server.lastSnapshotDeferred.values.first ?? 0) > 0 { deferredSeen = true }
        }
        #expect(deferredSeen)
        #expect(orphanFrames == 0)
        #expect(clientHierarchy(client) == hierarchy(world))
        #expect(worldPositions(client.world).count == worldPositions(world).count)
    }

    @Test func entityFieldsMapToClientEntities() {
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 14)
        let (server, client) = makeSession(network: network)
        let world = server.world
        let a = spawn(world, "a")
        // b exists on the server but isn't replicated yet; c is replicated.
        let b = world.spawn(Transform(), NetHierarchyTestsTag(label: "b"))
        let c = spawn(world, "c")
        let follower = spawn(world, "follower")
        world.add(NetHierarchyTestsFollow(target: b, ref: world.ref(to: b), optional: c, list: [a, b, c, .invalid]), to: follower)

        var time = run(server, client, network: network, seconds: 1)
        let cw = client.world
        func follow() -> NetHierarchyTestsFollow? {
            cw.entity(for: world.id(of: follower)!).flatMap { cw.get(NetHierarchyTestsFollow.self, for: $0) }
        }
        func clientEntity(_ e: Entity) -> Entity? { cw.entity(for: world.id(of: e)!) }
        var value = try! #require(follow())
        // Unresolved: b hasn't arrived.
        #expect(value.target == .invalid && !cw.isAlive(value.target))
        #expect(value.ref.id == world.id(of: b) && cw.resolve(value.ref) == nil)
        #expect(value.optional == clientEntity(c) && value.optional != nil)
        #expect(value.list == [clientEntity(a)!, .invalid, clientEntity(c)!, .invalid])

        // b arrives: the handles resolve, with no change to the component on the server.
        world.add(Replicated(components: Self.all), to: b)
        time = run(server, client, network: network, from: time, seconds: 1)
        value = try! #require(follow())
        let clientB = try! #require(clientEntity(b))
        #expect(value.target == clientB)
        #expect(cw.resolve(value.ref) == clientB)
        #expect(value.list == [clientEntity(a)!, clientB, clientEntity(c)!, .invalid])
        #expect(cw.get(NetHierarchyTestsTag.self, for: value.target)?.label == "b")

        // The target is despawned: the handle goes stale on the client too; retargeting works.
        world.despawn(b)
        time = run(server, client, network: network, from: time, seconds: 1)
        value = try! #require(follow())
        #expect(!cw.isAlive(value.target) && cw.resolve(value.ref) == nil)
        world.modify(NetHierarchyTestsFollow.self, for: follower) { $0.target = a; $0.ref = world.ref(to: a) }
        run(server, client, network: network, from: time, seconds: 1)
        value = try! #require(follow())
        #expect(value.target == clientEntity(a) && cw.resolve(value.ref) == clientEntity(a))
        #expect(client.stats.malformed == 0)
    }

    /// Both sides load the same scene file: its replicated entities are matched by id (no
    /// duplicates, the client's own handles and non-replicated components kept), one the server
    /// removed before the client joined goes away, entities spawned at run time arrive.
    @Test func sceneEntitiesMatchedByID() throws {
        let scene = World()
        let camera = scene.spawn(Transform(position: Vec3(0, 5, 10)), Camera(), Name("Camera"))
        let platform = scene.spawn(Transform(position: Vec3(0, 1, 0)), NetHierarchyTestsTag(label: "platform"),
                                   MeshRenderer(mesh: .cube), Replicated(components: Self.all))
        let rider = scene.spawn(Transform(position: Vec3(0, 1, 0)), NetHierarchyTestsTag(label: "rider"), Replicated(components: Self.all))
        scene.setParent(rider, to: platform)
        _ = scene.spawn(Transform(position: Vec3(4, 0, 0)), NetHierarchyTestsTag(label: "crate"), Replicated(components: Self.all))
        _ = camera
        for entity in scene.entities { scene.ensureID(of: entity) }
        let data = try scene.save()

        let serverWorld = World(), clientWorld = World()
        try serverWorld.load(data)
        try clientWorld.load(data)
        let clientEntities = Set(clientWorld.entities)
        #expect(clientEntities.count == 4)
        let network = LoopbackNetwork(conditions: Self.lossy, seed: 15)
        let (server, client) = makeSession(network: network, serverWorld: serverWorld, clientWorld: clientWorld)
        // The crate is gone before the client connects; a new entity appears under the platform.
        serverWorld.query(NetHierarchyTestsTag.self) { entity, tag in if tag.label == "crate" { serverWorld.despawn(entity) } }
        let serverPlatform = try #require(serverWorld.entity(for: scene.ensureID(of: platform)!))
        var time = run(server, client, network: network, seconds: 0.5)
        let late = spawn(serverWorld, "late", at: Vec3(2, 0, 0), parent: serverPlatform)
        time = run(server, client, network: network, from: time, seconds: 1) { t in
            serverWorld.modify(Transform.self, for: serverPlatform) { $0.position.y = 1 + Float(t) }
        }
        run(server, client, network: network, from: time, seconds: 1)

        #expect(Set(worldPositions(clientWorld).keys) == ["platform", "rider", "late"])
        // The same entities as loaded (crate aside), plus one.
        let now = Set(clientWorld.entities)
        #expect(now.subtracting(clientEntities).count == 1)
        #expect(clientEntities.subtracting(now).count == 1)
        #expect(clientWorld.entity(for: serverWorld.id(of: late)!) != nil)
        // Non-replicated data stays: the camera, and the platform's mesh (not in `components`).
        #expect(clientWorld.count(of: Camera.self) == 1)
        let clientPlatform = try #require(clientWorld.entity(for: scene.ensureID(of: platform)!))
        #expect(clientWorld.get(MeshRenderer.self, for: clientPlatform) != nil)
        #expect(clientHierarchy(client).filter { $0.value != nil }.count == 2)
        #expect(clientHierarchy(client).filter { $0.value != nil } == hierarchy(serverWorld).filter { $0.value != nil })
        let expected = worldPositions(serverWorld), actual = worldPositions(clientWorld)
        for (label, position) in expected { #expect(length(actual[label]! - position) < 0.01, "\(label)") }
    }

    /// A client that keeps `despawnsUnmatchedEntities` off keeps its scene copies.
    @Test func unmatchedEntitiesCanBeKept() throws {
        let scene = World()
        _ = scene.spawn(Transform(), NetHierarchyTestsTag(label: "local"), Replicated(components: Self.all))
        let data = try scene.save()
        let clientWorld = World()
        try clientWorld.load(data)
        let network = LoopbackNetwork(seed: 16)
        let (server, client) = makeSession(network: network, clientWorld: clientWorld)
        client.despawnsUnmatchedEntities = false
        _ = spawn(server.world, "remote")
        run(server, client, network: network, seconds: 0.5)
        #expect(Set(worldPositions(clientWorld).keys) == ["local", "remote"])
    }
}
