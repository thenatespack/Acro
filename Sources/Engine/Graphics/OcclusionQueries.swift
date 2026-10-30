/// Most occlusion queries that can be issued in one frame.
public let maxOcclusionQueriesPerFrame = 8192

/// A group of hardware occlusion queries, e.g. one per object or cluster.
///
/// Wrap a draw (typically a cheap bounding-box proxy drawn with `colorWrites: false` and
/// `depthWrite: false`) in `pass.beginOcclusionQuery(set, index:)` / `pass.endOcclusionQuery()`.
/// The result says whether any sample of that draw passed the depth test.
///
/// Results come back asynchronously: when a frame slot is reused (2–3 frames later,
/// depending on the backend), its results are copied into `results`. The latency is fixed
/// per backend, so screenshots stay deterministic.
@MainActor
public final class OcclusionQuerySet {
    public let count: Int
    /// Visibility from the latest returned query for each index; nil until one returns.
    public private(set) var results: [Bool?]
    /// Bumped by `invalidate`; results of queries issued under an older generation are dropped.
    fileprivate var generations: [UInt32]

    public init(count: Int) {
        precondition(count > 0, "An occlusion query set needs at least one query")
        self.count = count
        results = Array(repeating: nil, count: count)
        generations = Array(repeating: 0, count: count)
    }

    /// Clears `results[index]` and ignores queries for it that are still in flight. Use it
    /// when an object stops being queried (e.g. it left the view frustum), so an old
    /// "hidden" can't arrive after it comes back.
    public func invalidate(_ index: Int) {
        results[index] = nil
        generations[index] &+= 1
    }

    /// Invalidates every index (e.g. after a camera cut, when the old results are meaningless).
    public func reset() {
        for i in results.indices { invalidate(i) }
    }

    fileprivate func store(_ visible: Bool, at index: Int, generation: UInt32) {
        guard generations[index] == generation else { return }
        results[index] = visible
    }
}

/// Queries issued in one frame slot. Backends keep one per frame in flight: `begin` hands
/// out the slot's next result index, and `resolve` reads them back once the GPU is done.
@MainActor
final class OcclusionQueryBatch {
    private var entries: [(set: OcclusionQuerySet, index: Int, generation: UInt32)] = []
    /// Result index of the query currently open, if any.
    private(set) var open: Int?

    var count: Int { entries.count }

    func begin(_ set: OcclusionQuerySet, index: Int) -> Int {
        precondition(open == nil, "beginOcclusionQuery while another query is open")
        precondition(set.results.indices.contains(index), "Occlusion query index \(index) out of range 0..<\(set.count)")
        precondition(entries.count < maxOcclusionQueriesPerFrame,
                     "More than \(maxOcclusionQueriesPerFrame) occlusion queries in one frame")
        entries.append((set, index, set.generations[index]))
        open = entries.count - 1
        return entries.count - 1
    }

    /// Call when a pass ends: queries can't span passes.
    func checkClosed() {
        precondition(open == nil, "Occlusion query left open at the end of a pass")
    }

    func end() -> Int {
        guard let open else { preconditionFailure("endOcclusionQuery without beginOcclusionQuery") }
        self.open = nil
        return open
    }

    /// Stores each query's result (`visible(resultIndex)`) in its set, then empties the batch.
    func resolve(_ visible: (Int) -> Bool) {
        guard !entries.isEmpty else { return }
        for (i, entry) in entries.enumerated() {
            entry.set.store(visible(i), at: entry.index, generation: entry.generation)
        }
        entries.removeAll(keepingCapacity: true)
    }
}
