// Networking (card 672): replicated states that remember which snapshot set each entity, so a
// backlog under a byte budget drains at the budget's rate.
//
// A snapshot is a delta against the newest state the client acknowledged. Under a budget each
// snapshot carries only some of the changes, so the snapshots in flight carry different entities;
// with only the newest acknowledged state as the baseline, everything the other acknowledged
// snapshots carried would be sent again (a backlog drained about one entity per round trip). So
// every state records, per entity, the tick of the snapshot that set its value (or removed it),
// and the baseline of the next snapshot is the newest acknowledged state with the entities of
// the other acknowledged snapshots merged in where they are newer (`NetSnapshot.mergedTicks`).
// Server and client build it the same way from the same states.
//
// The client shows a "display" state per snapshot: the newest value of each entity among the
// snapshots received so far (by tick), so an entity carried by a snapshot that wasn't
// acknowledged yet (and so isn't in the next baseline) doesn't disappear and come back.

struct NetVersionedState {
    var state: NetWorldState = [:]
    /// The tick of the snapshot that set each entity's value, or removed it (an id in here but
    /// not in `state`: a tombstone, kept while older snapshots can still be merged).
    var versions: [EntityID: UInt32] = [:]
    /// The entities this state's own snapshot set or removed.
    var carried: [EntityID] = []

    /// Merged ticks are at most this far behind the baseline; tombstones older than that are dropped.
    static let mergeWindow: UInt32 = 32

    /// Takes what `other` (the state after snapshot `tick`) carried where it is newer than what
    /// this state has. Returns whether anything changed.
    @discardableResult
    mutating func merge(carriedBy other: NetVersionedState, tick: UInt32) -> Bool {
        var changed = false
        for id in other.carried where tick > versions[id] ?? 0 {
            state[id] = other.state[id]
            versions[id] = tick
            changed = true
        }
        return changed
    }

    /// The state after `snapshot`, a delta against this one.
    func advanced(by snapshot: NetSnapshot) -> NetVersionedState {
        var next = NetVersionedState(state: snapshot.applied(to: state), versions: versions)
        next.carried = Array(snapshot.changed.keys) + snapshot.removed
        for id in next.carried { next.versions[id] = snapshot.tick }
        // A tombstone only matters against merged snapshots older than it; those are at most
        // `mergeWindow` behind any later baseline, so older tombstones go (the same on both sides).
        if let base = snapshot.baselineTick, base > Self.mergeWindow, next.versions.count > next.state.count {
            let horizon = base - Self.mergeWindow
            next.versions = next.versions.filter { $0.value >= horizon || next.state[$0.key] != nil }
        }
        return next
    }
}
