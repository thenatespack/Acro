// Networking (card 671, phase 4): entity references inside replicated components, and the
// parent link.
//
// An `Entity` handle is a slot in one world, meaningless in another. While the server encodes a
// replicated component, every `Entity` in it is written as its target's `EntityID` (given one if
// it has none; a stale handle is written as none); while a client decodes it, the id becomes the
// client's entity with that id (client entities carry the server's ids), or `Entity.invalid`
// while the target hasn't arrived. The client remembers what each id resolved to and decodes
// the component again once that changes (the target spawned, or was replaced), so a reference
// that arrives before its target resolves as soon as the target does.
//
// `EntityRef` needs none of this: it names its target by id already and resolves through
// `World.resolve` whenever it is read.

extension CodingUserInfoKey {
    /// A `NetEntityMapping` while replicated components are encoded or decoded.
    static let netEntities = CodingUserInfoKey(rawValue: "Engine.NetEntities")!
}

/// Maps `Entity` handles to `EntityID`s (server, encoding) and ids back to handles (client,
/// decoding) for one world. Coders are not main-actor isolated, but replication encodes and
/// decodes on the main actor only.
final class NetEntityMapping: @unchecked Sendable {
    let world: World
    /// Decoding: every id the value referred to and the entity it resolved to (nil: none yet).
    private(set) var referenced: [EntityID: Entity?] = [:]

    init(world: World) {
        self.world = world
    }

    /// The id to send for `entity`; nil for a stale handle.
    func id(of entity: Entity) -> EntityID? {
        MainActor.assumeIsolated { world.ensureID(of: entity) }
    }

    /// The handle for `id` in this world, `Entity.invalid` while there is none.
    func entity(for id: EntityID) -> Entity {
        let entity = MainActor.assumeIsolated { world.entity(for: id) }
        referenced[id] = .some(entity)
        return entity ?? .invalid
    }
}

/// The pseudo-component that carries an entity's parent in a `NetWorldState`: the parent's
/// `EntityID` (16 bytes), absent for a root.
public enum NetHierarchy {
    public static let parentKey = "$parent"

    static func encode(_ id: EntityID) -> [UInt8] {
        var w = ByteWriter()
        w.entityID(id)
        return w.data
    }

    static func decode(_ bytes: [UInt8]) -> EntityID? {
        var r = ByteReader(bytes)
        guard let id = try? r.entityID(), r.isAtEnd else { return nil }
        return id
    }
}
