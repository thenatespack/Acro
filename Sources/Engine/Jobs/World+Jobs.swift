/// Parallel queries: the same iteration as `queryMutating`, split into batches on a
/// `JobSystem`. Each entity's components are visited by exactly one thread, so a body that
/// only changes its own components (and reads others nobody writes) gives the same result for
/// any thread count.
///
/// The body runs on several threads at once: it must not call the world's mutating API (`add`,
/// `remove`, `spawn`, `modify`, other queries' write-backs) or touch other main-actor state.
/// Read other entities' components through a value captured before the call (e.g. a
/// dictionary or array built beforehand), not through `world.get`, unless nothing writes that
/// component type during the call.
extension World {
    /// `queryMutating(A.self)` in parallel batches of `batchSize` entities.
    public func parallelQueryMutating<A: Component>(
        _: A.Type, batchSize: Int = 256, name: String = "parallelQuery", jobs: JobSystem = .shared,
        _ body: (Entity, inout A) -> Void
    ) {
        guard let a = existingStore(A.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        let entities = a.entities, values = a.values
        jobs.parallelFor(entities.indices, batchSize: batchSize, name: name) { range in
            for i in range { body(entities[i], &values[i]) }
        }
    }

    /// `queryMutating(A.self, B.self)` in parallel batches of `batchSize` entities (of the
    /// smaller store, as `queryMutating` walks it).
    public func parallelQueryMutating<A: Component, B: Component>(
        _: A.Type, _: B.Type, batchSize: Int = 256, name: String = "parallelQuery", jobs: JobSystem = .shared,
        _ body: (Entity, inout A, inout B) -> Void
    ) {
        guard let a = existingStore(A.self)?.view, let b = existingStore(B.self)?.view else { return }
        beginIteration()
        defer { endIteration() }
        let entities = a.entities.count <= b.entities.count ? a.entities : b.entities
        jobs.parallelFor(entities.indices, batchSize: batchSize, name: name) { range in
            for i in range {
                let entity = entities[i]
                guard let ia = a.denseIndex(of: entity), let ib = b.denseIndex(of: entity) else { continue }
                body(entity, &a.values[ia], &b.values[ib])
            }
        }
    }
}
