/// `for i in range { body(i) }`, for hot loops.
///
/// In a debug build a `for`-`in` over a range runs through the unspecialized generic iterator
/// (`IndexingIterator`, `ClosedRange`'s), with runtime metadata lookups on every step: about 15
/// times slower than a counted loop. That overhead dominated the Mesh Builder's debug-build time
/// (and so the editor tests). This helper is a plain counted loop; release builds compile it
/// and a `for`-`in` alike. Use it where a loop runs per texel, grid point or vertex.
@inline(__always) package func forEachIndex(_ range: Range<Int>, _ body: (Int) -> Void) {
    var i = range.lowerBound
    let end = range.upperBound
    while i < end {
        body(i)
        i += 1
    }
}

/// `for i in range { body(i) }` over a closed range (see the half-open one).
@inline(__always) package func forEachIndex(_ range: ClosedRange<Int>, _ body: (Int) -> Void) {
    var i = range.lowerBound
    let end = range.upperBound
    while true {
        body(i)
        if i == end { return }
        i += 1
    }
}
