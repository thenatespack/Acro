/// Type-erased view of a component store, for operations that span every component type
/// (despawning, enumerating an entity's components).
@usableFromInline
protocol AnyComponentStore: AnyObject {
    var componentType: any Component.Type { get }
    var count: Int { get }
    func contains(_ entity: Entity) -> Bool
    func component(of entity: Entity) -> (any Component)?
    @discardableResult func remove(_ entity: Entity) -> Bool
}

/// One component type's sparse set. `values` and `entities` are dense and parallel
/// (iteration walks them front to back); `sparse` maps an entity's slot index to its dense
/// index, or -1. Removal swaps the last element into the hole, so dense order is not stable.
///
/// Values live in a buffer the store allocates itself rather than in an `Array`. Queries
/// hand the body copies and write them back, and the body may use the world meanwhile; with
/// an array in a class property, each of those reads and writes pays a dynamic exclusivity
/// check and a uniqueness check, which made `queryMutating` several times slower. The
/// buffer only moves when a component is appended, and `World` defers appends while a query
/// runs, so a query can hold the pointer for its whole loop. Owned by one `World` and used
/// only on its actor; not Sendable.
@usableFromInline
final class ComponentStore<C: Component>: AnyComponentStore {
    @usableFromInline var values: UnsafeMutablePointer<C>
    private var capacity: Int
    @usableFromInline private(set) var entities: [Entity] = []
    @usableFromInline private(set) var sparse: [Int32] = []

    @usableFromInline init() {
        capacity = 16
        values = .allocate(capacity: capacity)
    }

    deinit {
        values.deinitialize(count: entities.count)
        values.deallocate()
    }

    @usableFromInline var componentType: any Component.Type { C.self }

    @inlinable var count: Int { entities.count }

    /// The entity's dense index, or nil if it has no `C` (or the handle is stale: the slot's
    /// current occupant is checked by generation).
    @inlinable func denseIndex(of entity: Entity) -> Int? {
        let slot = Int(entity.index)
        guard slot < sparse.count else { return nil }
        let dense = Int(sparse[slot])
        guard dense >= 0, entities[dense] == entity else { return nil }
        return dense
    }

    @usableFromInline func contains(_ entity: Entity) -> Bool { denseIndex(of: entity) != nil }

    @usableFromInline func component(of entity: Entity) -> (any Component)? {
        denseIndex(of: entity).map { values[$0] }
    }

    /// Adds `component`, or replaces the entity's existing one. Adding may move `values`.
    @usableFromInline func insert(_ component: C, for entity: Entity) {
        if let dense = denseIndex(of: entity) {
            values[dense] = component
            return
        }
        let slot = Int(entity.index)
        if slot >= sparse.count {
            sparse.append(contentsOf: repeatElement(-1, count: slot + 1 - sparse.count))
        }
        let count = entities.count
        if count == capacity {
            let grown = UnsafeMutablePointer<C>.allocate(capacity: capacity * 2)
            grown.moveInitialize(from: values, count: count)
            values.deallocate()
            values = grown
            capacity *= 2
        }
        (values + count).initialize(to: component)
        sparse[slot] = Int32(count)
        entities.append(entity)
    }

    @usableFromInline @discardableResult func remove(_ entity: Entity) -> Bool {
        guard let dense = denseIndex(of: entity) else { return false }
        let last = entities.count - 1
        if dense != last {
            values[dense] = (values + last).move()
            entities[dense] = entities[last]
            sparse[Int(entities[dense].index)] = Int32(dense)
        } else {
            (values + last).deinitialize(count: 1)
        }
        entities.removeLast()
        sparse[Int(entity.index)] = -1
        return true
    }

    /// The store's arrays and buffer captured for a loop, so the loop doesn't touch the
    /// store's properties (and their exclusivity checks) per element. Valid until the next
    /// structural change to this store.
    @inlinable var view: View { View(values: values, entities: entities, sparse: sparse) }

    @usableFromInline struct View {
        @usableFromInline let values: UnsafeMutablePointer<C>
        @usableFromInline let entities: [Entity]
        @usableFromInline let sparse: [Int32]

        @inlinable init(values: UnsafeMutablePointer<C>, entities: [Entity], sparse: [Int32]) {
            self.values = values
            self.entities = entities
            self.sparse = sparse
        }

        @inlinable func denseIndex(of entity: Entity) -> Int? {
            let slot = Int(entity.index)
            guard slot < sparse.count else { return nil }
            let dense = Int(sparse[slot])
            guard dense >= 0, entities[dense] == entity else { return nil }
            return dense
        }
    }
}
