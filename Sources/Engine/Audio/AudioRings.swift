import CAudio

// Lock-free plumbing between the game thread and the audio thread. Everything here is plain
// memory allocated once by the game thread; the audio thread only reads and writes it, so it
// never allocates, frees or waits.

/// A fixed array of 64-bit words shared between threads, read and written with acquire/release atomics.
struct AtomicWords: @unchecked Sendable {
    let base: UnsafeMutablePointer<UInt64>
    let count: Int

    init(count: Int) {
        self.count = count
        base = .allocate(capacity: count)
        base.initialize(repeating: 0, count: count)
    }

    func free() { base.deallocate() }

    @inline(__always) func load(_ i: Int) -> UInt64 { caudio_atomic_load(base + i) }
    @inline(__always) func store(_ i: Int, _ value: UInt64) { caudio_atomic_store(base + i, value) }
    @inline(__always) func exchange(_ i: Int, _ value: UInt64) -> UInt64 { caudio_atomic_exchange(base + i, value) }
    @inline(__always) func max(_ i: Int, _ value: UInt64) { caudio_atomic_max(base + i, value) }

    /// A non-negative float stored as its bit pattern (whose integer order matches the float order, so `max` works).
    @inline(__always) func maxFloat(_ i: Int, _ value: Float) { max(i, UInt64(Swift.max(value, 0).bitPattern)) }
    @inline(__always) func exchangeFloat(_ i: Int, _ value: Float) -> Float {
        Float(bitPattern: UInt32(truncatingIfNeeded: exchange(i, UInt64(value.bitPattern))))
    }
}

/// A single-producer single-consumer queue of `AudioCommand`s (game thread → audio thread).
/// `push` is called only by the producer and `pop` only by the consumer; neither blocks.
final class CommandQueue: @unchecked Sendable {
    let capacity: Int
    private let storage: UnsafeMutablePointer<AudioCommand>
    /// [0] = total pushed, [8] = total popped (on separate cache lines).
    private let counters = AtomicWords(count: 16)

    init(capacity: Int) {
        self.capacity = capacity
        storage = .allocate(capacity: capacity)
    }

    deinit {
        storage.deallocate()
        counters.free()
    }

    /// Producer side. False when the queue is full (the caller keeps the command and retries).
    func push(_ command: AudioCommand) -> Bool {
        let write = counters.load(0)
        let read = counters.load(8)
        guard write - read < UInt64(capacity) else { return false }
        (storage + Int(write % UInt64(capacity))).initialize(to: command)
        counters.store(0, write + 1)
        return true
    }

    /// Consumer side.
    @inline(__always) func pop() -> AudioCommand? {
        let read = counters.load(8)
        guard read != counters.load(0) else { return nil }
        let command = (storage + Int(read % UInt64(capacity))).move()
        counters.store(8, read + 1)
        return command
    }
}

/// A single-producer single-consumer ring of interleaved float frames feeding a streamed voice:
/// the game thread decodes into it (`AudioStream.fill`), the audio thread reads from it.
/// A value type of raw pointers so the audio thread holds it without reference counting; the
/// owning `AudioStream` frees it after the voice has finished.
struct StreamRing: @unchecked Sendable {
    let samples: UnsafeMutablePointer<Float>
    let capacity: Int  // frames
    let channels: Int
    /// [0] = frames written, [8] = frames read, [16] = 1 once the writer has reached the end.
    let counters: AtomicWords

    init(capacityFrames: Int, channels: Int) {
        capacity = capacityFrames
        self.channels = channels
        samples = .allocate(capacity: capacityFrames * channels)
        samples.initialize(repeating: 0, count: capacityFrames * channels)
        counters = AtomicWords(count: 24)
    }

    func free() {
        samples.deallocate()
        counters.free()
    }

    var written: UInt64 { counters.load(0) }
    var read: UInt64 { counters.load(8) }
    var isFinished: Bool { counters.load(16) != 0 }
    func markFinished() { counters.store(16, 1) }
    func publishWritten(_ value: UInt64) { counters.store(0, value) }
    func publishRead(_ value: UInt64) { counters.store(8, value) }
}
