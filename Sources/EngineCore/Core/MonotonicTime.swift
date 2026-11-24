/// Nanoseconds on a monotonic clock, for timing and epochs. Replaces
/// `monotonicNanoseconds()`, which isn't available where Dispatch isn't
/// (single-threaded WebAssembly). Only differences between two readings are meaningful.
@inline(__always)
public func monotonicNanoseconds() -> UInt64 {
    let d = monotonicReference.duration(to: .now).components
    return UInt64(d.seconds) &* 1_000_000_000 &+ UInt64(d.attoseconds / 1_000_000_000) &+ 1
}

private let monotonicReference = ContinuousClock.now
