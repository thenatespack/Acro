import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Network play in the editor (card 671, phase 6), without a window: net.start makes a server of
// the scene's world plus client worlds copied from the scene, matched by id; what the server
// does reaches the clients; per-client conditions, stats, the Game View's world, the overlay,
// the toolbar's Network menu; play.stop ends it all.

@MainActor @Suite struct EditorNetPlayTests {
    private func makeSession() -> EditorSession {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        let session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        return session
    }

    /// The starter scene plus a spinning parent with a child, and a mover the test drives.
    private func setUpScene(_ session: EditorSession) throws -> (spinner: EntityID, child: EntityID) {
        let world = session.world
        let spinner = world.spawn(Transform(position: Vec3(3, 1, 0)), MeshRenderer(mesh: .cube), Name("Spinner"),
                                  Spin(axis: Vec3(0, 1, 0), speed: 2))
        let child = world.spawn(Transform(position: Vec3(1, 0, 0)), MeshRenderer(mesh: .sphere), Name("Moon"))
        world.setParent(child, to: spinner)
        return (world.id(of: spinner)!, world.id(of: child)!)
    }

    private func worldPosition(_ id: EntityID, in world: World) -> Vec3? {
        world.entity(for: id).map { Transform(matrix: world.worldMatrix(of: $0)).position }
    }

    @Test func clientsMirrorTheServer() throws {
        let session = makeSession()
        let (spinner, child) = try setUpScene(session)
        let sceneCount = session.world.entityCount
        #expect(!session.commands.isAvailable(NetStatsCommand.self))

        let state = try session.commands.run(NetStartCommand.self, .init(clients: 2, latencyMs: 50, loss: 0.02))
        #expect(session.isPlaying)
        #expect(state.active && state.clients.count == 2 && state.replicatesAll && state.view == "server")
        let net = try #require(session.netPlay)
        // Every client loaded the scene: the same entities, matched by id, no duplicates.
        for client in net.clients { #expect(client.world.entityCount == sceneCount) }

        try session.commands.run(PlayStepCommand.self, .init(frames: 120))
        let server = session.world
        let spawned = server.spawn(Transform(position: Vec3(-2, 0.5, 0)), MeshRenderer(mesh: .cube), Name("Late"))
        let spawnedID = server.id(of: spawned)!
        try session.commands.run(PlayStepCommand.self, .init(frames: 60))

        for client in net.clients {
            #expect(client.net.clientID != nil)
            #expect(client.world.entityCount == sceneCount + 1)
            let world = client.world
            // The child follows its parent through the replicated hierarchy.
            #expect(world.entity(for: child).flatMap { world.parent(of: $0) }.flatMap { world.id(of: $0) } == spinner)
            #expect(world.entity(for: spawnedID).flatMap { world.get(Name.self, for: $0) }?.value == "Late")
            // Interpolated ~100 ms behind plus latency: the spinner turned, the moon moved with it.
            let moon = try #require(worldPosition(child, in: world))
            #expect(length(moon - Vec3(4, 1, 0)) > 0.1)
            #expect(abs(length(moon - Vec3(3, 1, 0)) - 1) < 0.01)
        }

        // Despawning on the server removes it everywhere.
        server.despawn(spawned)
        try session.commands.run(PlayStepCommand.self, .init(frames: 30))
        for client in net.clients { #expect(client.world.entity(for: spawnedID) == nil) }

        // play.stop ends network play and restores the scene.
        try session.commands.run(PlayStopCommand.self)
        #expect(session.netPlay == nil && !session.isPlaying)
        #expect(session.world.entityCount == sceneCount)
        #expect(!session.commands.isAvailable(NetViewCommand.self))
    }

    @Test func conditionsStatsViewAndOverlay() throws {
        let session = makeSession()
        _ = try setUpScene(session)
        try session.commands.run(NetStartCommand.self, .init(clients: 2))
        var state = try session.commands.run(NetSetConditionsCommand.self, .init(client: 2, latencyMs: 150, jitterMs: 20, loss: 0.1))
        #expect(state.clients[0].down == NetLinkConditions())
        #expect(state.clients[1].down == NetLinkConditions(latencyMs: 150, jitterMs: 20, loss: 0.1))
        #expect(state.clients[1].up == state.clients[1].down)
        // One direction only, keeping the other fields.
        state = try session.commands.run(NetSetConditionsCommand.self, .init(client: 2, direction: "up", duplicate: 0.05))
        #expect(state.clients[1].up == NetLinkConditions(latencyMs: 150, jitterMs: 20, loss: 0.1, duplicate: 0.05))
        #expect(state.clients[1].down.duplicate == 0)
        #expect(throws: (any Error).self) { try session.commands.run(NetSetConditionsCommand.self, .init(client: 3, latencyMs: 1)) }
        #expect(throws: (any Error).self) { try session.commands.run(NetSetConditionsCommand.self, .init(loss: 2)) }

        try session.commands.run(PlayStepCommand.self, .init(frames: 300))
        let stats = try session.commands.run(NetStatsCommand.self)
        #expect(stats.server.count == 2 && stats.clients.count == 2)
        let fast = stats.clients[0], slow = stats.clients[1]
        let fastRTT = try #require(fast.rttMs), slowRTT = try #require(slow.rttMs)
        #expect(fastRTT < 60)
        #expect(slowRTT > 300 && slowRTT < 420, "RTT \(slowRTT)")
        #expect(slow.lossPercent > 2)
        #expect(fast.bytesInPerSecond > 1000 && fast.snapshots > 100)
        #expect(stats.server[0].lastSnapshotBytes ?? 0 > 0)
        #expect(stats.network.packetsDropped > 0)
        // The JSON tool round trip.
        let json = try session.commands.run(NetStatsCommand.id, json: nil)
        #expect(String(decoding: json, as: UTF8.self).contains("\"rttMs\""))

        // The Game View's world.
        #expect(session.gameWorld === session.world)
        try session.commands.run(NetViewCommand.self, .init(target: "client 2"))
        #expect(session.gameWorld === session.netPlay!.client(2)!.world)
        let shot = try session.resolveView(ViewSpec(source: .game))
        #expect(shot.camera != nil)
        try session.commands.run(NetViewCommand.self, .init(target: "1"))
        #expect(session.gameWorld === session.netPlay!.client(1)!.world)
        #expect(throws: (any Error).self) { try session.commands.run(NetViewCommand.self, .init(target: "client 9")) }
        let lines = session.netPlay!.overlayLines()
        #expect(lines.first == "Game View: client 1")
        #expect(lines.contains { $0.hasPrefix("RTT ") })
        try session.commands.run(NetViewCommand.self, .init(target: "server"))
        #expect(session.netPlay!.overlayLines().count == 1 + 2 * 2)

        state = try session.commands.run(NetOverlayCommand.self, .init())
        #expect(!state.overlay)

        // net.stop: play goes on with the server alone.
        try session.commands.run(NetStopCommand.self)
        #expect(session.netPlay == nil && session.isPlaying)
        #expect(session.gameWorld === session.world)
    }

    /// A scene with its own `Replicated` components replicates only those ("auto" = "marked").
    @Test func markedSceneReplicatesOnlyMarked() throws {
        let session = makeSession()
        let world = session.world
        let marked = world.spawn(Transform(position: Vec3(0, 2, 0)), Name("Marked"), Spin(),
                                 Replicated(components: [Transform.componentName, Name.componentName]))
        let markedID = world.id(of: marked)!
        let state = try session.commands.run(NetStartCommand.self, .init(clients: 1))
        #expect(!state.replicatesAll)
        try session.commands.run(PlayStepCommand.self, .init(frames: 60))
        let client = session.netPlay!.clients[0]
        #expect(client.net.replicatedEntityCount == 1)
        #expect(client.world.entity(for: markedID) != nil)
        try session.commands.run(PlayStopCommand.self)
    }

    /// The toolbar's Network button opens a menu whose entries run net commands.
    @Test func networkMenu() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let ui = app.ui!
        func open() throws -> PopupMenu {
            let button = try #require(ui.accessibilityElements().first { $0.label == "Network" && $0.role == .button && $0.isOnScreen })
            #expect(button.command == NetStartCommand.id.rawValue)
            ui.synthesizeClick(at: button.clickPoint)
            app.syncPanels()
            return try #require(ui.overlays.last as? PopupMenu)
        }
        var menu = try open()
        #expect(menu.items == ["Play with 1 Client", "Play with 2 Clients", "Play with 3 Clients", "Play with 4 Clients"])
        menu.onSelect?(1)
        ui.dismissOverlay(menu)
        #expect(app.session.netPlay?.clients.count == 2)
        menu = try open()
        #expect(menu.items.contains("Game View: Client 2") && menu.items.contains("Stats Overlay"))
        let tools = Set(app.session.commands.all.map(\.id.rawValue))
        for id in menu.itemCommandIDs { #expect(id.map(tools.contains) == true) }
        menu.onSelect?(menu.items.firstIndex(of: "Game View: Client 2")!)
        ui.dismissOverlay(menu)
        #expect(app.session.netPlay?.viewedClient == 2)
        app.session.stop()
    }
}
