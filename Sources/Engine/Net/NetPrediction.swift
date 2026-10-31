import Foundation

// Networking (card 662): input commands for a `CharacterController` and client-side
// prediction with reconciliation.
//
// The client turns each fixed step's input into a `NetCharacterInput`, sends it
// (`NetClient.sendInput`, resent until acknowledged) and moves its own character right away with
// `PhysicsWorld.predictCharacter`. The server applies each client's inputs in order, one fixed
// step each (`NetServer.takeInputs` + `applyCharacterInput`), and every snapshot says which
// input it had applied last. When a snapshot arrives the client rewinds its character to the
// server's state (exact Transform and the CharacterController's state), drops the inputs the
// server has applied and replays the rest. With the same collision world on both sides the
// replay lands exactly where the prediction was (no correction); anything the client can't
// know (server-only obstacles, knock-backs, other players blocking) shows up as a correction,
// blended out over `smoothing` seconds for display.

/// One fixed step of a character's input: the wanted horizontal velocity in world space (m/s,
/// x and z) and jump. Quantized on the wire (1 mm/s, at most 32 m/s per axis); `quantized` gives
/// the value both sides simulate with.
public struct NetCharacterInput: Equatable, Sendable {
    public var move: Vec2
    public var jump: Bool

    public init(move: Vec2 = .zero, jump: Bool = false) {
        self.move = move
        self.jump = jump
    }

    /// Flags (bit 0: jump), x and z in mm/s as Int16: 5 bytes.
    public func encoded() -> [UInt8] {
        var w = ByteWriter()
        w.u8(jump ? 1 : 0)
        for v in [move.x, move.y] {
            let mm = (v.isFinite ? v * 1000 : 0).rounded()
            w.u16(UInt16(bitPattern: Int16(min(max(mm, -32767), 32767))))
        }
        return w.data
    }

    public init(decoding bytes: [UInt8]) throws {
        var r = ByteReader(bytes)
        let flags = try r.u8()
        guard flags <= 1 else { throw NetError.malformed("input flags") }
        let x = Float(Int16(bitPattern: try r.u16())) / 1000
        let z = Float(Int16(bitPattern: try r.u16())) / 1000
        guard r.isAtEnd else { throw NetError.malformed("trailing bytes") }
        self.init(move: Vec2(x, z), jump: flags == 1)
    }

    /// What the other side decodes.
    public var quantized: NetCharacterInput { (try? NetCharacterInput(decoding: encoded())) ?? NetCharacterInput() }

    /// Sets the controller's input fields for the next step.
    public func apply(to controller: inout CharacterController) {
        controller.moveVelocity = Vec3(move.x, 0, move.y)
        controller.jump = jump
    }
}

extension PhysicsWorld {
    /// Server side: one input command for `entity`'s `CharacterController`, one step of `dt`
    /// (the entity's `Transform.position` is the feet; its kinematic body, if any, follows).
    /// Characters stepped this way shouldn't also be moved by the "character" system (remove it
    /// or don't add `CharacterController` entities to a world with `addPhysics`).
    public func applyCharacterInput(_ input: NetCharacterInput, to entity: Entity, in world: World, dt: Float) {
        guard var controller = world.get(CharacterController.self, for: entity), var transform = world.get(Transform.self, for: entity) else { return }
        input.quantized.apply(to: &controller)
        transform.position = moveCharacter(&controller, from: transform.position, dt: dt, body: body(for: entity))
        world.add(transform, to: entity)
        world.add(controller, to: entity)
    }
}

/// Predicts the client's own character: replicated with `Replicated(components: [Transform,
/// CharacterController], transform: .exact)` and moved by the server with
/// `applyCharacterInput`. `physics` is the client's copy of the collision world (the same static
/// level, built in the same order). Call `step` once per fixed step with the local input.
@MainActor
public final class NetCharacterPrediction {
    public let client: NetClient
    public let physics: PhysicsWorld
    public let entityID: EntityID
    public let dt: Float
    /// Time constant (seconds) over which a correction's jump is blended out of the display.
    public var smoothing: Float = 0.1

    public struct Stats: Equatable, Sendable {
        /// Snapshots reconciled with.
        public var reconciliations = 0
        /// Reconciliations that moved the prediction by more than 0.1 mm.
        public var corrections = 0
        /// Inputs re-simulated during reconciliations.
        public var replayedSteps = 0
        /// How far the latest prediction moved on the last / worst reconciliation (metres).
        public var lastError: Float = 0
        public var maxError: Float = 0
    }
    public private(set) var stats = Stats()
    /// The predicted feet position and controller state (nil until the first snapshot with the
    /// character arrives).
    public private(set) var position: Vec3?
    public private(set) var controller: CharacterController?
    /// What is left of recent corrections, decaying to zero: the character is drawn at
    /// `position + displayOffset`.
    public private(set) var displayOffset: Vec3 = .zero

    private var history: [(sequence: UInt32, input: NetCharacterInput)] = []
    private var reconciledTick: UInt32?

    public init(client: NetClient, physics: PhysicsWorld, entityID: EntityID, dt: Float) {
        self.client = client
        self.physics = physics
        self.entityID = entityID
        self.dt = dt
        client.predictedEntities.insert(entityID)
    }

    /// One fixed step: reconciles with the newest snapshot, sends `input` and predicts its
    /// result. Returns the input's sequence number.
    @discardableResult
    public func step(_ input: NetCharacterInput) -> UInt32 {
        let input = input.quantized
        reconcile()
        let sequence = client.sendInput(input.encoded())
        history.append((sequence, input))
        if var c = controller, let p = position {
            input.apply(to: &c)
            position = physics.predictCharacter(&c, from: p, dt: dt)
            controller = c
        }
        displayOffset *= expf(-dt / max(smoothing, 1e-3))
        if lengthSquared(displayOffset) < 1e-10 { displayOffset = .zero }
        write()
        return sequence
    }

    /// Rewinds to the newest snapshot's state of the character and replays the inputs the
    /// server hadn't applied yet.
    public func reconcile() {
        guard let newest = client.newestState(of: entityID), newest.tick != reconciledTick,
              let transformBytes = newest.components[Transform.componentName],
              let controllerBytes = newest.components[CharacterController.componentName],
              let transform = try? NetComponentCoder.decodeTransform(transformBytes),
              var c = try? CharacterController.netDecoded(controllerBytes) else { return }
        reconciledTick = newest.tick
        history.removeAll { $0.sequence <= newest.inputAck }
        var p = transform.position
        for entry in history {
            entry.input.apply(to: &c)
            p = physics.predictCharacter(&c, from: p, dt: dt)
        }
        stats.reconciliations += 1
        stats.replayedSteps += history.count
        if let before = position {
            let error = length(p - before)
            stats.lastError = error
            stats.maxError = max(stats.maxError, error)
            if error > 1e-4 {
                stats.corrections += 1
                displayOffset += before - p
            }
        }
        position = p
        controller = c
    }

    private func write() {
        guard let position, let controller, let entity = client.world.entity(for: entityID) else { return }
        var transform = client.world.get(Transform.self, for: entity) ?? Transform()
        transform.position = position + displayOffset
        client.world.add(transform, to: entity)
        client.world.add(controller, to: entity)
    }
}
