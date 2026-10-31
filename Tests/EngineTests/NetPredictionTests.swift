import Foundation
import Testing
@testable import Engine

/// Input commands and client-side prediction of a CharacterController (card 662): the server
/// applies each client's inputs per fixed tick, the client predicts and reconciles.
@MainActor @Suite struct NetPredictionTests {
    static let dt: Float = 1.0 / 60

    /// The level both sides build: a floor, stairs, a ramp and a wall.
    static func buildLevel(_ physics: PhysicsWorld) {
        func box(_ lo: Vec3, _ hi: Vec3, rotation: Quat = .identity) {
            physics.addBody(BodyDescriptor(motion: .static, pose: Pose(position: (lo + hi) * 0.5, rotation: rotation), shape: .box((hi - lo) * 0.5)))
        }
        box(Vec3(-30, -1, -30), Vec3(30, 0, 30))
        for k in 0..<5 { box(Vec3(2 + Float(k) * 0.5, 0, -2), Vec3(2.5 + Float(k) * 0.5, 0.25 * Float(k + 1), 2)) }
        box(Vec3(4.5, 0, -2), Vec3(8, 1.25, 2))
        box(Vec3(-6, 0, 4), Vec3(6, 2, 4.5))
        box(Vec3(-4, -1, -8), Vec3(0, 0.2, -6), rotation: Quat(angle: 0.3, axis: Vec3(0, 0, 1)))
    }

    /// A server with a physics level and one character per client, and the clients with their
    /// own copy of the level predicting their character.
    @MainActor final class Game {
        let network: LoopbackNetwork
        let server: NetServer
        let serverPhysics = PhysicsWorld()
        var characters: [NetClientID: Entity] = [:]
        var clients: [NetClient] = []
        var predictions: [NetCharacterPrediction?] = []
        var clientPhysics: [PhysicsWorld] = []
        var time = 0.0
        var step = 0
        /// Inputs the server applied, per client, in order.
        var applied: [NetClientID: [UInt32]] = [:]

        init(conditions: LinkConditions, clients count: Int, seed: UInt64 = 1) {
            network = LoopbackNetwork(conditions: conditions, seed: seed)
            let serverEnd = network.makeEndpoint()
            server = NetServer(world: World(), transport: serverEnd, secret: 7)
            var next: UInt64 = 0
            server.world.entityIDGenerator = {
                next += 1
                return EntityID(high: 662, low: next)
            }
            NetPredictionTests.buildLevel(serverPhysics)
            for i in 0..<count {
                clients.append(NetClient(world: World(), transport: network.makeEndpoint(), server: serverEnd.id, salt: UInt64(i + 1)))
                predictions.append(nil)
                let physics = PhysicsWorld()
                NetPredictionTests.buildLevel(physics)
                clientPhysics.append(physics)
            }
        }

        /// Server side: a character for every new client, told to the client in a reliable
        /// message (its entity id).
        func serverEvents() {
            for event in server.pollEvents() {
                guard case .connected(let id) = event else { continue }
                let entity = server.world.spawn(
                    Transform(position: Vec3(Float(id.value) * 2 - 4, 0.02, 0)), CharacterController(),
                    Replicated(components: [Transform.componentName, CharacterController.componentName], transform: .exact))
                characters[id] = entity
                let entityID = server.world.ensureID(of: entity)!
                var w = ByteWriter()
                w.entityID(entityID)
                server.send(message: w.data, to: id)
            }
        }

        /// One 60 Hz frame: every client predicts with `input(client index, step)`, the server
        /// applies what arrived (up to 4 inputs per client per tick) and sends snapshots.
        func frame(input: (Int, Int) -> NetCharacterInput, serverTick: ((Game) -> Void)? = nil) {
            network.now = time
            for (i, client) in clients.enumerated() {
                for case .message(let bytes) in client.pollEvents() {
                    var r = ByteReader(bytes)
                    let id = try! r.entityID()
                    predictions[i] = NetCharacterPrediction(client: client, physics: clientPhysics[i], entityID: id, dt: NetPredictionTests.dt)
                }
                predictions[i]?.step(input(i, step))
            }
            server.receive(time: time)
            serverEvents()
            for (id, entity) in characters.sorted(by: { $0.key < $1.key }) {
                for command in server.takeInputs(from: id, max: 4) {
                    serverPhysics.applyCharacterInput(try! NetCharacterInput(decoding: command.bytes), to: entity, in: server.world, dt: NetPredictionTests.dt)
                    applied[id, default: []].append(command.sequence)
                }
            }
            serverTick?(self)
            server.update(time: time)
            for client in clients { client.update(dt: Double(NetPredictionTests.dt)) }
            time += Double(NetPredictionTests.dt)
            step += 1
        }

        func serverPosition(of client: NetClient) -> Vec3 { server.world.get(Transform.self, for: characters[client.clientID!]!)!.position }
    }

    /// A walk over the stairs and along the wall with jumps, different per player.
    static func scripted(_ player: Int, _ step: Int) -> NetCharacterInput {
        let t = Float(step) * dt
        if step > 600 { return NetCharacterInput() }
        let angle = t * (player == 0 ? 0.9 : -0.7) + Float(player)
        return NetCharacterInput(move: Vec2(cosf(angle), sinf(angle)) * 4.5 + Vec2(1.5, 0), jump: step % 97 == 40 + player * 13)
    }

    /// Same collision world on both sides: the replayed prediction lands exactly where it was
    /// (zero corrections) through 100 ms each way, jitter and 5% loss, and once inputs stop the
    /// client shows exactly the server's position.
    @Test func predictionMatchesTheServerExactly() {
        let game = Game(conditions: LinkConditions(latency: 0.1, jitter: 0.02, loss: 0.05, duplicate: 0.02), clients: 2, seed: 4)
        var lead: [Float] = [0, 0]
        for _ in 0..<720 {
            game.frame(input: Self.scripted)
            // How far ahead of the server's current position the prediction is (the latency it hides).
            for (i, client) in game.clients.enumerated() {
                if let p = game.predictions[i]?.position, client.clientID != nil, game.characters[client.clientID!] != nil {
                    lead[i] = max(lead[i], length(p - game.serverPosition(of: client)))
                }
            }
        }
        for (i, client) in game.clients.enumerated() {
            let prediction = game.predictions[i]!
            #expect(prediction.stats.reconciliations > 300)
            #expect(prediction.stats.corrections == 0)
            #expect(prediction.stats.maxError == 0)
            #expect(prediction.stats.replayedSteps > prediction.stats.reconciliations * 8)
            // Everything sent was applied, in order, without gaps (redundant inputs cover the loss).
            let applied = game.applied[client.clientID!]!
            #expect(applied == Array(1...UInt32(applied.count)))
            #expect(applied.count > 650)
            // Inputs stopped at step 600: both sides are at rest at the same spot.
            #expect(prediction.position == game.serverPosition(of: client))
            let entity = client.world.entity(for: prediction.entityID)!
            #expect(client.world.get(Transform.self, for: entity)!.position == game.serverPosition(of: client))
            #expect(lead[i] > 0.4) // ~200+ ms of walking at 4.5-6 m/s
            print("NetPredictionTests: player \(i): \(prediction.stats.reconciliations) reconciliations, \(prediction.stats.replayedSteps) replayed steps, "
                  + "max error \(prediction.stats.maxError) m, prediction up to \(lead[i]) m ahead of the server")
        }
        // Each client sees the other's character too, interpolated.
        let other = game.clients[0].world.entity(for: game.predictions[1]!.entityID)
        #expect(other.flatMap { game.clients[0].world.get(Transform.self, for: $0) }?.position == game.serverPosition(of: game.clients[1]))
    }

    /// The server moves the character in a way the client can't predict (a knock-back): the
    /// client corrects within a round trip, the display blends the jump out, and it converges.
    @Test func correctionsConverge() {
        let game = Game(conditions: LinkConditions(latency: 0.08, jitter: 0.01, loss: 0.03), clients: 1, seed: 8)
        var knocked = false
        var errorAfter: [Float] = []
        for frame in 0..<480 {
            game.frame(input: { _, step in NetCharacterInput(move: step < 400 ? Vec2(0, 3) : .zero) }) { game in
                if frame == 150, let entity = game.characters.values.first {
                    game.server.world.modify(Transform.self, for: entity) { $0.position.x += 1.5 }
                    knocked = true
                }
            }
            if knocked, let p = game.predictions[0] { errorAfter.append(length(p.displayOffset)) }
        }
        let prediction = game.predictions[0]!
        #expect(prediction.stats.corrections >= 1)
        #expect(prediction.stats.maxError > 1.4 && prediction.stats.maxError < 1.6)
        // The visible offset decays (time constant 0.1 s) and is gone well before the end.
        #expect(errorAfter.contains { $0 > 1 })
        #expect(errorAfter.last == 0)
        #expect(prediction.position == game.serverPosition(of: game.clients[0]))
    }

    /// 30% loss on the client-to-server direction: 16 redundant inputs per packet still get
    /// every input to the server, in order.
    @Test func redundantInputsSurviveHeavyLoss() {
        let game = Game(conditions: LinkConditions(latency: 0.05, loss: 0.3), clients: 1, seed: 12)
        for _ in 0..<600 { game.frame(input: { _, step in NetCharacterInput(move: Vec2(Float(step % 7), 1)) }) }
        let applied = game.applied.values.first!
        #expect(applied == Array(1...UInt32(applied.count)))
        #expect(applied.count > 500)
        #expect(game.predictions[0]!.stats.corrections == 0)
    }

    /// `predictCharacter` is `moveCharacter` without side effects: same positions and state,
    /// no pushes, no kinematic move.
    @Test func predictCharacterMatchesMoveCharacter() {
        let a = PhysicsWorld(), b = PhysicsWorld()
        for physics in [a, b] {
            Self.buildLevel(physics)
            physics.addBody(BodyDescriptor(pose: Pose(position: Vec3(0, 0.5, 2)), shape: .box(Vec3(0.4, 0.4, 0.4))))
        }
        var ca = CharacterController(), cb = CharacterController()
        var pa = Vec3(0, 0.02, 0), pb = pa
        for step in 0..<300 {
            let input = Self.scripted(0, step)
            input.apply(to: &ca)
            input.apply(to: &cb)
            pa = a.moveCharacter(&ca, from: pa, dt: Self.dt)
            pb = b.predictCharacter(&cb, from: pb, dt: Self.dt)
            #expect(pa == pb)
            #expect(ca == cb)
        }
        // Input quantization: 1 mm/s.
        let input = NetCharacterInput(move: Vec2(1.23456, -40), jump: true)
        #expect(input.quantized == NetCharacterInput(move: Vec2(1.235, -32.767), jump: true))
        #expect(input.encoded().count == 5)
        #expect(throws: NetError.self) { try NetCharacterInput(decoding: [2, 0, 0, 0, 0]) }
    }
}
