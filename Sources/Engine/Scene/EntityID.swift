// Persistent entity ids and display names.
//
// An `Entity` handle is a slot plus a generation: cheap and fast, but meaningless outside
// the running world. Despawning and recreating an entity (undo), loading a file or
// restoring a snapshot into other slots all give different handles. Anything that has to
// refer to an entity across those (the editor's selection, undo records, links between
// files) uses its `EntityID` instead.
//
// ## Design: a world-level table, not a component
//
// The id lives in a side table indexed by entity slot, next to the hierarchy tables, with a
// dictionary from id to entity for O(1) lookup. The alternative was an `EntityID` component:
// it would be saved, snapshotted and removed with the entity for free, and queryable. But
// - it would need a second structure for the reverse lookup that every add/remove/despawn
//   path keeps in sync, or `entity(for:)` is a linear scan;
// - it shows up in `components(of:)`, the inspector and "remove component", where editing
//   it would break the uniqueness guarantee (like an editable parent link would);
// - an entity could lose it by a stray `remove`.
// A side table makes uniqueness an invariant of the world: `setEntityID` is the only way to
// change an id, and it refuses duplicates. Scene files store it as `"uid"` on the entity's
// record, and snapshots copy the table.
//
// ids are random 128-bit values (like a UUID, but without the version bits), so they stay
// unique across files, sessions and machines without coordination, and a file written
// today can be merged into any world. Sequential ids would be deterministic but would
// collide as soon as two files were combined. For deterministic output in tests, replace
// `World.entityIDGenerator`.
//
// Ordering: ids have no meaning in their order (`Comparable` exists for sorting and stable
// containers). The order of entities is the hierarchy's: roots in `World.roots` order, then
// children in sibling order, which is also the order scene files list them in.

/// A stable, unique identity for an entity: 128 random bits. See `World.id(of:)`.
public struct EntityID: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let high: UInt64
    public let low: UInt64

    public init(high: UInt64, low: UInt64) {
        self.high = high
        self.low = low
    }

    /// A new random id.
    public static func random() -> EntityID {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    public static func random<G: RandomNumberGenerator>(using generator: inout G) -> EntityID {
        EntityID(high: generator.next(), low: generator.next())
    }

    /// Parses the 32 hex digits `description` produces.
    public init?(_ string: String) {
        guard string.utf8.count == 32,
              let high = UInt64(string.prefix(16), radix: 16),
              let low = UInt64(string.suffix(16), radix: 16) else { return nil }
        self.init(high: high, low: low)
    }

    /// 32 lowercase hex digits.
    public var description: String {
        let h = String(high, radix: 16), l = String(low, radix: 16)
        return String(repeating: "0", count: 16 - h.count) + h + String(repeating: "0", count: 16 - l.count) + l
    }

    public static func < (a: EntityID, b: EntityID) -> Bool {
        (a.high, a.low) < (b.high, b.low)
    }

    public init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let id = EntityID(string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad entity id '\(string)'"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// A display name for the hierarchy panel and tools. Optional: entities without one show
/// as unnamed.
public struct Name: Component, Equatable, Sendable, ExpressibleByStringLiteral {
    public static let componentName = "Name"
    public var value: String

    public init(_ value: String) { self.value = value }
    public init(stringLiteral value: String) { self.value = value }
}

extension World {
    /// `entity`'s persistent id, or nil if it has none (`assignsEntityIDs` is off and
    /// nothing asked for one) or the handle is stale.
    public func id(of entity: Entity) -> EntityID? {
        isAlive(entity) ? entityIDs[Int(entity.index)] : nil
    }

    /// The live entity with `id`, or nil. O(1).
    public func entity(for id: EntityID) -> Entity? {
        idLookup[id]
    }

    /// `entity`'s id, giving it a new one first if it has none. Nil for a stale handle.
    @discardableResult
    public func ensureID(of entity: Entity) -> EntityID? {
        guard isAlive(entity) else { return nil }
        if let id = entityIDs[Int(entity.index)] { return id }
        var id = entityIDGenerator()
        while idLookup[id] != nil { id = entityIDGenerator() }
        entityIDs[Int(entity.index)] = id
        idLookup[id] = entity
        return id
    }

    /// Gives `entity` the id `id`, replacing its current one. Returns false, changing
    /// nothing, if the handle is stale or another entity has `id`.
    @discardableResult
    public func setEntityID(_ id: EntityID, for entity: Entity) -> Bool {
        guard isAlive(entity) else { return false }
        if let owner = idLookup[id] { return owner == entity }
        if let old = entityIDs[Int(entity.index)] { idLookup[old] = nil }
        entityIDs[Int(entity.index)] = id
        idLookup[id] = entity
        return true
    }

    /// Gives every entity in `entity`'s subtree an id (see `ensureID`).
    func ensureIDs(inSubtreeOf entity: Entity) {
        var stack = [entity]
        while let next = stack.popLast() {
            ensureID(of: next)
            stack += childLists[Int(next.index)]
        }
    }
}

// MARK: Roots

extension World {
    /// The entities without a parent, in order: spawn order unless `setParent(_:to:at:)`
    /// moved one. Scene files list roots in this order.
    public var roots: [Entity] {
        rootList.compactMap { $0 }
    }

    func appendRoot(_ entity: Entity) {
        rootPos[Int(entity.index)] = rootList.count
        rootList.append(entity)
    }

    /// Inserts `entity` so it is the `index`th root (clamped).
    func insertRoot(_ entity: Entity, at index: Int) {
        var live = 0
        var position = rootList.count
        for (i, root) in rootList.enumerated() where root != nil {
            if live == index { position = i; break }
            live += 1
        }
        rootList.insert(entity, at: position)
        // Entries from the insertion on moved.
        for i in position..<rootList.count { if let root = rootList[i] { rootPos[Int(root.index)] = i } }
    }

    func removeRoot(_ entity: Entity) {
        let pos = rootPos[Int(entity.index)]
        guard pos >= 0 else { return }
        rootList[pos] = nil
        rootPos[Int(entity.index)] = -1
        rootHoles += 1
        // Compact once holes dominate, so the list stays proportional to the live roots.
        if rootHoles > 32 && rootHoles * 2 > rootList.count {
            rootList = rootList.filter { $0 != nil }
            rootHoles = 0
            for (i, root) in rootList.enumerated() { rootPos[Int(root!.index)] = i }
        }
    }

    /// `entity`'s position among its siblings (among the roots if it has no parent), or nil
    /// for a stale handle.
    public func siblingIndex(of entity: Entity) -> Int? {
        guard isAlive(entity) else { return nil }
        if let parent = parents[Int(entity.index)] {
            return childLists[Int(parent.index)].firstIndex(of: entity)
        }
        let pos = rootPos[Int(entity.index)]
        guard pos >= 0 else { return nil }
        return rootList[..<pos].reduce(0) { $0 + ($1 == nil ? 0 : 1) }
    }
}
