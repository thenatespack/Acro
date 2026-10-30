/// Entities, their components, the transform hierarchy and the systems that update them.
///
/// ```swift
/// struct Velocity: Component { var value: Vec3 }
///
/// let world = World()
/// let ship = world.spawn(Transform(position: Vec3(0, 1, 0)), Velocity(value: Vec3(1, 0, 0)))
/// let turret = world.spawn(Transform(position: Vec3(0, 0.5, 0)))
/// world.setParent(turret, to: ship)                    // turret follows the ship
///
/// world.addSystem("move", stage: .fixedUpdate) { world in
///     let dt = world.time.delta                        // the fixed step here
///     world.queryMutating(Transform.self, Velocity.self) { _, transform, velocity in
///         transform.position += velocity.value * dt
///     }
/// }
/// world.addSystem("cull", stage: .update) { world in
///     world.query(Transform.self) { entity, transform in
///         if transform.position.y < -100 { world.despawn(entity) }  // applied after the query
///     }
/// }
///
/// engine.world = world                                 // the engine calls world.update(dt:) every frame
/// // Rendering: world.query(GlobalTransform.self) { _, global in … global.matrix … }
/// ```
///
/// ## Storage: sparse sets
///
/// Each component type has its own sparse set (`ComponentStore`): a dense array of values,
/// a parallel dense array of entities, and a sparse array from entity slot to dense index.
/// The alternative, archetypes (one table per distinct component combination), iterates
/// multi-component queries slightly faster because matching rows are contiguous in every
/// column. We chose sparse sets because:
/// - Adding or removing a component is O(1) and touches only that type's store. With
///   archetypes it moves every component of the entity to another table, which makes tag
///   components, editor toggles and per-frame state markers expensive.
/// - Iteration is still dense: a query walks the smallest store's arrays front to back and
///   probes the others by slot index (one array load and a compare each). Single-component
///   queries, the common case for renderers and physics, are a plain array walk.
/// - It is far simpler (no archetype graph, table moves or query caches), so it is easy to
///   keep correct and to change later. The public API (handles, `add`/`remove`/`get`,
///   closure queries, deferred structural changes) doesn't expose the layout, so archetypes
///   or grouped storage can replace it if profiling asks for it.
/// - Enumerating one entity's components, which the editor inspector and serialization
///   need, is a probe of each registered store (`components(of:)`), in registration order.
///
/// ## Structural changes during queries
///
/// While any query is running, structural changes (`despawn`, removing a component, adding
/// a component the entity doesn't have yet) are queued and applied in order when the
/// outermost query returns. Until then the entity keeps its components and stays alive, so
/// every query sees a stable set of entities. Non-structural changes apply immediately:
/// `spawn` (the new entity has no components until the queue is applied), replacing a
/// component the entity already has, `modify`, and hierarchy changes. Outside queries
/// everything applies immediately.
///
/// `queryMutating` passes components as `inout` copies and writes them back after the body
/// returns, so the body may freely read and write other entities (including through
/// nested queries). Writes to the current entity's queried components made through other
/// paths (`add`, `modify`) during the body are overwritten by the write-back; change them
/// through the `inout` parameters.
///
/// Stale handles are safe everywhere: lookups return nil and mutations are ignored.
///
/// The world is main-actor isolated, like the rest of the engine's game-facing API.
@MainActor
public final class World {
    // Entity slots. A slot's generation is bumped when its entity is despawned.
    @usableFromInline var generations: [UInt32] = []
    @usableFromInline var alive: [Bool] = []
    var freeSlots: [UInt32] = []
    /// Number of live entities.
    public internal(set) var entityCount = 0

    // Component stores, keyed by component type, and in registration order.
    @usableFromInline var stores: [ObjectIdentifier: any AnyComponentStore] = [:]
    var storeOrder: [any AnyComponentStore] = []

    // Queries running (nesting depth) and the structural changes deferred until they end.
    @usableFromInline var iterationDepth = 0
    private var deferred: [() -> Void] = []

    // Hierarchy, indexed by slot (see World+Hierarchy.swift).
    var parents: [Entity?] = []
    var childLists: [[Entity]] = []

    // Systems and timing (see World+Systems.swift).
    var systems: [[SystemEntry]] = Array(repeating: [], count: SystemStage.allCases.count)
    var fixedAccumulator: Double = 0
    /// Timing for the frame and stage being run.
    public internal(set) var time = WorldTime()
    /// Length of one `.fixedUpdate` step in seconds (default 1/60).
    public var fixedTimestep: Double = 1.0 / 60.0 {
        didSet { precondition(fixedTimestep > 0, "fixedTimestep must be positive") }
    }
    /// At most this many fixed steps run per `update(dt:)`. Time beyond that is dropped
    /// (whole steps only, so `time.alpha` stays continuous), so a slow frame can't snowball
    /// into ever more steps (the "spiral of death").
    public var maxFixedStepsPerFrame = 8

    public init() {}

    // MARK: Entities

    /// Creates an entity with no components.
    public func spawn() -> Entity {
        let entity: Entity
        if let slot = freeSlots.popLast() {
            alive[Int(slot)] = true
            entity = Entity(index: slot, generation: generations[Int(slot)])
        } else {
            precondition(generations.count < Int(UInt32.max), "Too many entities")
            entity = Entity(index: UInt32(generations.count), generation: 0)
            generations.append(0)
            alive.append(true)
            parents.append(nil)
            childLists.append([])
        }
        entityCount += 1
        return entity
    }

    /// Creates an entity with the given components (applied after the outermost running
    /// query, if any; the handle is valid immediately).
    public func spawn<each C: Component>(_ components: repeat each C) -> Entity {
        let entity = spawn()
        repeat add(each components, to: entity)
        return entity
    }

    /// Whether `entity` refers to a live entity (false for stale handles).
    @inlinable public func isAlive(_ entity: Entity) -> Bool {
        let slot = Int(entity.index)
        return slot < generations.count && alive[slot] && generations[slot] == entity.generation
    }

    /// Despawns `entity` and, recursively, all of its children (reparent children first to
    /// keep them). Deferred while a query is running. Ignored for stale handles.
    public func despawn(_ entity: Entity) {
        guard isAlive(entity) else { return }
        if iterationDepth > 0 {
            deferred.append { self.despawn(entity) }
            return
        }
        // Detach the subtree's root, then free every entity in it.
        if let parent = parents[Int(entity.index)] {
            childLists[Int(parent.index)].removeAll { $0 == entity }
        }
        var pending = [entity]
        while let next = pending.popLast() {
            let slot = Int(next.index)
            pending += childLists[slot]
            for store in storeOrder { store.remove(next) }
            parents[slot] = nil
            childLists[slot] = []
            alive[slot] = false
            generations[slot] &+= 1
            freeSlots.append(next.index)
            entityCount -= 1
        }
    }

    /// Every live entity, in slot order.
    public var entities: [Entity] {
        alive.indices.compactMap { alive[$0] ? Entity(index: UInt32($0), generation: generations[$0]) : nil }
    }

    // MARK: Components

    /// Adds `component` to `entity`, replacing one of the same type. Adding a new type is
    /// deferred while a query is running; replacing is immediate. Ignored for stale handles.
    /// Accepts an `any Component` too (the existential is opened), e.g. when deserializing.
    public func add<C: Component>(_ component: C, to entity: Entity) {
        guard isAlive(entity) else { return }
        let store = store(C.self)
        if let dense = store.denseIndex(of: entity) {
            store.values[dense] = component
        } else if iterationDepth > 0 {
            deferred.append { self.add(component, to: entity) }
        } else {
            store.insert(component, for: entity)
        }
    }

    /// Removes `entity`'s `C`, if it has one. Deferred while a query is running. Accepts an
    /// `any Component.Type` too.
    public func remove<C: Component>(_ type: C.Type, from entity: Entity) {
        guard let store = existingStore(C.self), store.denseIndex(of: entity) != nil else { return }
        if iterationDepth > 0 {
            deferred.append { self.remove(type, from: entity) }
        } else {
            store.remove(entity)
        }
    }

    /// `entity`'s `C`, or nil if it has none or the handle is stale.
    @inlinable public func get<C: Component>(_ type: C.Type, for entity: Entity) -> C? {
        guard let store = existingStore(C.self), let dense = store.denseIndex(of: entity) else { return nil }
        return store.values[dense]
    }

    @inlinable public func has<C: Component>(_ type: C.Type, for entity: Entity) -> Bool {
        existingStore(C.self)?.denseIndex(of: entity) != nil
    }

    /// Edits `entity`'s `C` in place and returns the body's result, or returns nil if it
    /// has none. Immediate, also during queries.
    @inlinable @discardableResult
    public func modify<C: Component, R>(_ type: C.Type, for entity: Entity, _ body: (inout C) throws -> R) rethrows -> R? {
        guard let store = existingStore(C.self), let dense = store.denseIndex(of: entity) else { return nil }
        // Edit a copy: the body may use the world, even read this component, which must not
        // overlap an inout access into the store's buffer.
        var value = store.values[dense]
        let result = try body(&value)
        if let dense = store.denseIndex(of: entity) { store.values[dense] = value }
        return result
    }

    /// Number of entities with a `C`.
    public func count<C: Component>(of type: C.Type) -> Int {
        existingStore(C.self)?.count ?? 0
    }

    /// All of `entity`'s components, in the order their types were first added to the world.
    /// For the editor inspector and serialization.
    public func components(of entity: Entity) -> [any Component] {
        guard isAlive(entity) else { return [] }
        return storeOrder.compactMap { $0.component(of: entity) }
    }

    /// The types of `entity`'s components, in the same order as `components(of:)`.
    public func componentTypes(of entity: Entity) -> [any Component.Type] {
        guard isAlive(entity) else { return [] }
        return storeOrder.filter { $0.contains(entity) }.map(\.componentType)
    }

    /// Every component type that has been added to this world, in registration order.
    public var registeredComponentTypes: [any Component.Type] {
        storeOrder.map(\.componentType)
    }

    @inlinable func existingStore<C: Component>(_: C.Type) -> ComponentStore<C>? {
        guard let store = stores[ObjectIdentifier(C.self)] else { return nil }
        // Stores are keyed by their component type, so the cast can't fail (checked in debug).
        return unsafeDowncast(store, to: ComponentStore<C>.self)
    }

    func store<C: Component>(_: C.Type) -> ComponentStore<C> {
        if let store = existingStore(C.self) { return store }
        let store = ComponentStore<C>()
        stores[ObjectIdentifier(C.self)] = store
        storeOrder.append(store)
        ComponentRegistry.registerImplicitly(C.self)
        return store
    }

    // MARK: Queries

    @usableFromInline func beginIteration() {
        iterationDepth += 1
    }

    @usableFromInline func endIteration() {
        iterationDepth -= 1
        guard iterationDepth == 0, !deferred.isEmpty else { return }
        let commands = deferred
        deferred = []
        for command in commands { command() }
    }

    /// Whether a query is running (structural changes are being deferred).
    public var isIterating: Bool { iterationDepth > 0 }

    /// Calls `body` with every entity that has an `A`, densely, in storage order.
    @inlinable public func query<A: Component>(
        _: A.Type, _ body: (Entity, A) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for (i, entity) in a.entities.enumerated() {
            try body(entity, a.values[i])
        }
    }

    /// Calls `body` with every entity that has an `A` and a `B`. Walks the smallest store
    /// and probes the others.
    @inlinable public func query<A: Component, B: Component>(
        _: A.Type, _: B.Type, _ body: (Entity, A, B) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in a.entities.count <= b.entities.count ? a.entities : b.entities {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity) else { continue }
            try body(entity, a.values[ia], b.values[ib])
        }
    }

    @inlinable public func query<A: Component, B: Component, C: Component>(
        _: A.Type, _: B.Type, _: C.Type, _ body: (Entity, A, B, C) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view, let c = existingStore(C.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in Self.smallest(a.entities, b.entities, c.entities) {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity), let ic = c.denseIndex(of: entity) else { continue }
            try body(entity, a.values[ia], b.values[ib], c.values[ic])
        }
    }

    @inlinable public func query<A: Component, B: Component, C: Component, D: Component>(
        _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ body: (Entity, A, B, C, D) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view, let c = existingStore(C.self)?.view, let d = existingStore(D.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in Self.smallest(a.entities, b.entities, c.entities, d.entities) {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity), let ic = c.denseIndex(of: entity), let id = d.denseIndex(of: entity) else { continue }
            try body(entity, a.values[ia], b.values[ib], c.values[ic], d.values[id])
        }
    }

    /// Like `query`, but the components are `inout`; changes are written back after `body`
    /// returns (see "Structural changes during queries" above).
    @inlinable public func queryMutating<A: Component>(
        _: A.Type, _ body: (Entity, inout A) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for (i, entity) in a.entities.enumerated() {
            var va = a.values[i]
            try body(entity, &va)
            a.values[i] = va
        }
    }

    @inlinable public func queryMutating<A: Component, B: Component>(
        _: A.Type, _: B.Type, _ body: (Entity, inout A, inout B) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in a.entities.count <= b.entities.count ? a.entities : b.entities {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity) else { continue }
            var va = a.values[ia]
            var vb = b.values[ib]
            try body(entity, &va, &vb)
            a.values[ia] = va
            b.values[ib] = vb
        }
    }

    @inlinable public func queryMutating<A: Component, B: Component, C: Component>(
        _: A.Type, _: B.Type, _: C.Type, _ body: (Entity, inout A, inout B, inout C) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view, let c = existingStore(C.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in Self.smallest(a.entities, b.entities, c.entities) {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity), let ic = c.denseIndex(of: entity) else { continue }
            var va = a.values[ia]
            var vb = b.values[ib]
            var vc = c.values[ic]
            try body(entity, &va, &vb, &vc)
            a.values[ia] = va
            b.values[ib] = vb
            c.values[ic] = vc
        }
    }

    @inlinable public func queryMutating<A: Component, B: Component, C: Component, D: Component>(
        _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ body: (Entity, inout A, inout B, inout C, inout D) throws -> Void
    ) rethrows {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view, let c = existingStore(C.self)?.view, let d = existingStore(D.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        for entity in Self.smallest(a.entities, b.entities, c.entities, d.entities) {
            guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity), let ic = c.denseIndex(of: entity), let id = d.denseIndex(of: entity) else { continue }
            var va = a.values[ia]
            var vb = b.values[ib]
            var vc = c.values[ic]
            var vd = d.values[id]
            try body(entity, &va, &vb, &vc, &vd)
            a.values[ia] = va
            b.values[ib] = vb
            c.values[ic] = vc
            d.values[id] = vd
        }
    }

    @inlinable static func smallest(_ lists: [Entity]...) -> [Entity] {
        lists.min { $0.count < $1.count }!
    }
}
