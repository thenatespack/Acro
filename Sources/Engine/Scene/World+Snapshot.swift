/// A copy of a world's entities, components, hierarchy and timing, taken by
/// `World.snapshot()` and put back by `World.restore(_:)`. In memory only (it holds the
/// components themselves, not their encoding); use `save` for files.
public struct WorldSnapshot {
    let generations: [UInt32]
    let alive: [Bool]
    let freeSlots: [UInt32]
    let entityCount: Int
    let stores: [any AnyComponentStore]
    let parents: [Entity?]
    let childLists: [[Entity]]
    let time: WorldTime
    let fixedAccumulator: Double

    /// Number of live entities in the snapshot.
    public var count: Int { entityCount }
}

extension World {
    /// Copies the world's data, e.g. before entering play mode in the editor. Cost is a copy
    /// of every component store (no encoding), so it is fast enough to take every frame for
    /// small worlds.
    public func snapshot() -> WorldSnapshot {
        precondition(!isIterating, "snapshot() can't run inside a query")
        return WorldSnapshot(
            generations: generations, alive: alive, freeSlots: freeSlots, entityCount: entityCount,
            stores: storeOrder.map { $0.clone() }, parents: parents, childLists: childLists,
            time: time, fixedAccumulator: fixedAccumulator)
    }

    /// Puts the world back to `snapshot`: the same entities with the same handles, the same
    /// components (stores of types added since are dropped), hierarchy, timing and fixed-step
    /// accumulator. Systems and settings (`fixedTimestep`, `maxFixedStepsPerFrame`) are code
    /// and configuration, not data, and are left as they are. A snapshot can be restored any
    /// number of times.
    ///
    /// Entity handles: a handle to an entity that was alive in the snapshot is valid again
    /// and refers to the restored entity, so the editor's selection survives play mode.
    /// Handles to entities spawned after the snapshot are stale, and stay stale when their
    /// slots are reused, because those slots' generations are bumped rather than rolled back.
    /// The one gap: a slot that was alive in the snapshot gets its old generation back, so a
    /// handle from play mode to a later occupant of that slot can become valid again once
    /// the restored entity is despawned and the slot reused. Drop play-mode handles on
    /// restore. Spawning after a restore hands out slots in the same order as after the
    /// snapshot was taken, so replays are deterministic.
    public func restore(_ snapshot: WorldSnapshot) {
        precondition(!isIterating, "restore(_:) can't run inside a query")
        let oldCount = generations.count
        let count = max(oldCount, snapshot.generations.count)
        var newGenerations = snapshot.generations
        var newAlive = snapshot.alive
        var extraSlots: [UInt32] = []
        for slot in 0..<count {
            let inSnapshot = slot < snapshot.generations.count
            if inSnapshot && snapshot.alive[slot] { continue }
            // Free in the snapshot (or created since): never go back to a generation a
            // play-mode handle may hold.
            var generation = inSnapshot ? snapshot.generations[slot] : 0
            if slot < oldCount {
                generation = max(generation, generations[slot] &+ (alive[slot] ? 1 : 0))
            }
            if inSnapshot {
                newGenerations[slot] = generation
            } else {
                newGenerations.append(generation)
                newAlive.append(false)
                extraSlots.append(UInt32(slot))
            }
        }
        generations = newGenerations
        alive = newAlive
        // Slots created after the snapshot are handed out after the snapshot's free slots, in
        // ascending order, as fresh slots would be.
        freeSlots = extraSlots.reversed() + snapshot.freeSlots
        entityCount = snapshot.entityCount

        storeOrder = snapshot.stores.map { $0.clone() }
        stores = Dictionary(uniqueKeysWithValues: storeOrder.map { (ObjectIdentifier($0.componentType), $0) })
        parents = snapshot.parents + Array(repeating: nil, count: count - snapshot.parents.count)
        childLists = snapshot.childLists + Array(repeating: [], count: count - snapshot.childLists.count)
        time = snapshot.time
        fixedAccumulator = snapshot.fixedAccumulator
    }
}
