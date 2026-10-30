import Testing
@testable import Engine

@MainActor @Test func batchRoutesResultsToTheirSetsAndIndices() {
    let a = OcclusionQuerySet(count: 3)
    let b = OcclusionQuerySet(count: 2)
    let batch = OcclusionQueryBatch()
    for (set, index) in [(a, 2), (b, 0), (a, 0)] {
        _ = batch.begin(set, index: index)
        _ = batch.end()
    }
    #expect(batch.count == 3)

    // Result slots are handed out in issue order: a[2], b[0], a[0].
    batch.resolve { $0 != 1 }
    #expect(a.results == [true, nil, true])
    #expect(b.results == [false, nil])
    #expect(batch.count == 0)
}

@MainActor @Test func laterResultsReplaceEarlierOnesAndResetClears() {
    let set = OcclusionQuerySet(count: 1)
    let batch = OcclusionQueryBatch()
    for visible in [true, false] {
        _ = batch.begin(set, index: 0)
        _ = batch.end()
        batch.resolve { _ in visible }
    }
    #expect(set.results == [false])
    set.reset()
    #expect(set.results == [nil])
}

@MainActor @Test func invalidateDropsResultsStillInFlight() {
    let set = OcclusionQuerySet(count: 2)
    let batch = OcclusionQueryBatch()
    for index in 0..<2 {
        _ = batch.begin(set, index: index)
        _ = batch.end()
    }
    set.invalidate(0)  // e.g. object 0 left the view while its query was in flight
    batch.resolve { _ in false }
    #expect(set.results == [nil, false])
}
