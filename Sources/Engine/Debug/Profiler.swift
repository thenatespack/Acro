import Foundation

/// One finished scope.
public struct ProfilerEvent: Sendable, Equatable {
    public var name: String
    /// Identifies the thread it ran on (0 is the main thread).
    public var thread: UInt64
    /// How many scopes of the same thread were open around it.
    public var depth: Int
    /// Seconds since the profiler started.
    public var start: Double
    public var duration: Double
}

/// The scopes recorded during one engine frame.
public struct ProfilerFrame: Sendable {
    public var index: Int
    /// Seconds since the profiler started, at the frame's beginning and end.
    public var start: Double
    public var end: Double
    /// In the order they finished (inner scopes before the scope around them).
    public var events: [ProfilerEvent]
    /// GPU time per pass of the most recent frame the GPU had finished when this one ended (it
    /// lags the CPU by a frame or two), empty when the backend can't time passes.
    public var gpuPasses: [GPUPassTime] = []
    /// Names given with `Profiler.nameCurrentThread` (job workers) of the threads in `events`.
    public var threadNames: [UInt64: String] = [:]

    public var duration: Double { end - start }
}

/// A CPU profiler: scoped markers on any thread, recorded per frame into a ring, shown as a
/// timeline in the debug overlay and exported as Chrome trace JSON.
///
/// ```swift
/// Profiler.scope("pathfinding") { solve() }          // or
/// Profiler.begin("pathfinding"); solve(); Profiler.end()
/// ```
///
/// Disabled (the default), a marker is one flag test. Turn it on with `ENGINE_PROFILER=1` (also
/// shows the timeline), the profiler key (F3, `EngineConfig.profilerKey`) or
/// `Profiler.isEnabled`. `ENGINE_PROFILE_TRACE=<file.json>` records the whole run and writes it
/// at exit; the key F4 saves the ring's frames to a file next to the crash reports.
/// The engine marks its loop (`events`, `update`, `world` with each stage and system,
/// `renderOffscreen`, `acquire` / `present`, `render`, `postprocess`, `ui`, `overlay`).
///
/// Markers nest per thread; `begin` / `end` must balance on the thread that called them. The
/// engine starts a frame with `beginFrame` / `endFrame`; scopes outside any frame (before the
/// first one, or on worker threads between frames) land in the frame that is current when they end.
/// Enable and disable from the main thread between frames; flipping it mid-scope drops the
/// unmatched `end` safely.
public enum Profiler {
    /// Whether markers record. Read without a lock by every marker, so change it from one thread.
    nonisolated(unsafe) public static var isEnabled = false {
        didSet { if isEnabled && !oldValue { ProfilerCore.shared.restartClock() } }
    }

    /// Runs `body` as a scope named `name`.
    @inline(__always)
    public static func scope<T>(_ name: String, _ body: () throws -> T) rethrows -> T {
        guard isEnabled else { return try body() }
        ProfilerCore.shared.begin(name)
        defer { ProfilerCore.shared.end() }
        return try body()
    }

    /// Opens a scope; close it with `end()` on the same thread.
    @inline(__always)
    public static func begin(_ name: String) {
        if isEnabled { ProfilerCore.shared.begin(name) }
    }

    @inline(__always)
    public static func end() {
        if isEnabled { ProfilerCore.shared.end() }
    }

    /// Names the calling thread in the timeline and in traces (e.g. "job worker 3"). Works
    /// whether or not the profiler is enabled; the job system names its workers.
    public static func nameCurrentThread(_ name: String) {
        ProfilerCore.shared.nameCurrentThread(name)
    }

    /// Starts frame `index`, finishing the previous one. The engine calls this.
    public static func beginFrame(index: Int) {
        if isEnabled { ProfilerCore.shared.beginFrame(index: index) }
    }

    /// Finishes the current frame, attaching `gpuPasses`. The engine calls this.
    public static func endFrame(gpuPasses: [GPUPassTime] = []) {
        if isEnabled { ProfilerCore.shared.endFrame(gpuPasses: gpuPasses) }
    }

    /// The most recent finished frames, oldest first (at most `frameCapacity`).
    public static var frames: [ProfilerFrame] { ProfilerCore.shared.frames }

    /// How many finished frames the ring keeps (default 240).
    public static var frameCapacity: Int {
        get { ProfilerCore.shared.frameCapacity }
        set { ProfilerCore.shared.frameCapacity = newValue }
    }

    /// Forgets the ring's frames.
    public static func clear() { ProfilerCore.shared.clear() }

    /// Chrome trace JSON (loads in chrome://tracing and Perfetto) for `frames`, by default the ring.
    public static func chromeTrace(frames: [ProfilerFrame]? = nil) -> String {
        ProfilerCore.chromeTrace(frames: frames ?? self.frames)
    }

    /// Writes `chromeTrace(frames:)` to `url`.
    public static func exportChromeTrace(to url: URL, frames: [ProfilerFrame]? = nil) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try chromeTrace(frames: frames).write(to: url, atomically: true, encoding: .utf8)
    }

    /// Keeps every frame from now on (up to `maxFrames`) in addition to the ring, for `finishTraceCapture`.
    public static func startTraceCapture(maxFrames: Int = 100_000) {
        isEnabled = true
        ProfilerCore.shared.startCapture(maxFrames: maxFrames)
    }

    /// Writes the captured frames (and the current partial frame's finished scopes) to `url` and stops capturing.
    public static func finishTraceCapture(to url: URL) throws {
        let captured = ProfilerCore.shared.finishCapture()
        try exportChromeTrace(to: url, frames: captured)
    }
}

/// The profiler's state. `Profiler` forwards to the shared instance; tests make their own.
final class ProfilerCore: @unchecked Sendable {
    static let shared = ProfilerCore()

    private let lock = NSLock()
    private var epoch = DispatchTime.now().uptimeNanoseconds
    private var openScopes: [UInt64: [(name: String, start: Double)]] = [:]
    private var threadNumbers: [ObjectIdentifier: UInt64] = [:]
    private var nextThreadNumber: UInt64 = 1
    private var threadNames: [UInt64: String] = [:]
    private var pending: [ProfilerEvent] = []
    private var currentIndex = 0
    private var currentStart = 0.0
    private var ring: [ProfilerFrame] = []
    private var ringStart = 0
    private var capacity = 240
    private var capture: [ProfilerFrame]?
    private var captureLimit = 0

    var frameCapacity: Int {
        get { lock.withLock { capacity } }
        set {
            lock.withLock {
                let ordered = orderedRing()
                capacity = max(newValue, 1)
                ring = Array(ordered.suffix(capacity))
                ringStart = 0
            }
        }
    }

    var frames: [ProfilerFrame] { lock.withLock { orderedRing() } }

    /// Caller holds the lock.
    private func orderedRing() -> [ProfilerFrame] {
        ring.count < capacity || ringStart == 0 ? ring : Array(ring[ringStart...] + ring[..<ringStart])
    }

    private func now() -> Double { Double(DispatchTime.now().uptimeNanoseconds - epoch) * 1e-9 }

    /// Time restarts from zero whenever recording is switched on, so traces start near 0.
    func restartClock() {
        lock.withLock {
            epoch = DispatchTime.now().uptimeNanoseconds
            openScopes.removeAll()
            pending.removeAll()
            ring.removeAll()
            ringStart = 0
            currentStart = 0
        }
    }

    /// Caller holds the lock. The main thread is 0 so traces list it first.
    private func threadID() -> UInt64 {
        if Thread.isMainThread { return 0 }
        let key = ObjectIdentifier(Thread.current)
        if let number = threadNumbers[key] { return number }
        let number = nextThreadNumber
        nextThreadNumber += 1
        threadNumbers[key] = number
        return number
    }

    func nameCurrentThread(_ name: String) {
        lock.withLock { threadNames[threadID()] = name }
    }

    func begin(_ name: String) {
        let time = now()
        lock.withLock { openScopes[threadID(), default: []].append((name, time)) }
    }

    func end() {
        let time = now()
        lock.withLock {
            let thread = threadID()
            guard let scope = openScopes[thread]?.popLast() else { return }
            let depth = openScopes[thread]?.count ?? 0
            pending.append(ProfilerEvent(name: scope.name, thread: thread, depth: depth, start: scope.start,
                                         duration: max(time - scope.start, 0)))
        }
    }

    func beginFrame(index: Int) {
        let time = now()
        lock.withLock {
            finishFrame(at: time, gpuPasses: [])
            currentIndex = index
            currentStart = time
        }
    }

    func endFrame(gpuPasses: [GPUPassTime]) {
        let time = now()
        lock.withLock {
            finishFrame(at: time, gpuPasses: gpuPasses)
            currentStart = time
        }
    }

    /// Caller holds the lock. Files the pending events as a frame (if any were recorded).
    private func finishFrame(at time: Double, gpuPasses: [GPUPassTime]) {
        guard !pending.isEmpty || !gpuPasses.isEmpty else { return }
        var frame = ProfilerFrame(index: currentIndex, start: currentStart, end: time, events: pending, gpuPasses: gpuPasses)
        if !threadNames.isEmpty {
            for event in pending where event.thread != 0 && frame.threadNames[event.thread] == nil {
                if let name = threadNames[event.thread] { frame.threadNames[event.thread] = name }
            }
        }
        pending = []
        if ring.count < capacity {
            ring.append(frame)
        } else {
            ring[ringStart] = frame
            ringStart = (ringStart + 1) % capacity
        }
        if capture != nil, capture!.count < captureLimit { capture!.append(frame) }
    }

    func clear() {
        lock.withLock {
            ring.removeAll()
            ringStart = 0
            pending.removeAll()
        }
    }

    func startCapture(maxFrames: Int) {
        lock.withLock {
            capture = []
            captureLimit = maxFrames
        }
    }

    func finishCapture() -> [ProfilerFrame] {
        lock.withLock {
            finishFrame(at: now(), gpuPasses: [])
            defer { capture = nil }
            return capture ?? []
        }
    }

    // MARK: Chrome trace

    /// Trace Event Format JSON: one complete ("X") event per scope, a `frames` track with one
    /// event per frame, and a `GPU` track laying each frame's pass times end to end from the
    /// frame's start (the passes ran later and overlap in reality; only their lengths are exact).
    /// Times are microseconds.
    static func chromeTrace(frames: [ProfilerFrame]) -> String {
        let frameTrack = 1_000_000, gpuTrack = 1_000_001
        var tracks: Set<UInt64> = []
        var names: [UInt64: String] = [:]
        var events: [String] = []
        func micro(_ seconds: Double) -> String { String(format: "%.3f", seconds * 1e6) }
        for frame in frames {
            names.merge(frame.threadNames) { old, _ in old }
            events.append("{\"name\":\"Frame \(frame.index)\",\"cat\":\"frame\",\"ph\":\"X\",\"ts\":\(micro(frame.start)),"
                + "\"dur\":\(micro(frame.duration)),\"pid\":1,\"tid\":\(frameTrack)}")
            for event in frame.events {
                tracks.insert(event.thread)
                events.append("{\"name\":\(quoted(event.name)),\"cat\":\"cpu\",\"ph\":\"X\",\"ts\":\(micro(event.start)),"
                    + "\"dur\":\(micro(event.duration)),\"pid\":1,\"tid\":\(event.thread)}")
            }
            var offset = frame.start
            for pass in frame.gpuPasses {
                events.append("{\"name\":\(quoted(pass.name)),\"cat\":\"gpu\",\"ph\":\"X\",\"ts\":\(micro(offset)),"
                    + "\"dur\":\(micro(pass.seconds)),\"pid\":1,\"tid\":\(gpuTrack)}")
                offset += pass.seconds
            }
        }
        func thread(_ id: Int, _ name: String) -> String {
            "{\"name\":\"thread_name\",\"ph\":\"M\",\"pid\":1,\"tid\":\(id),\"args\":{\"name\":\(quoted(name))}}"
        }
        var metadata = ["{\"name\":\"process_name\",\"ph\":\"M\",\"pid\":1,\"args\":{\"name\":\"Engine\"}}",
                        thread(frameTrack, "frames"), thread(gpuTrack, "GPU")]
        for id in tracks.sorted() {
            metadata.append(thread(Int(id), id == 0 ? "main" : names[id] ?? "thread \(id)"))
            // Perfetto / chrome://tracing order tracks by this: main, then workers in order.
            metadata.append("{\"name\":\"thread_sort_index\",\"ph\":\"M\",\"pid\":1,\"tid\":\(id),\"args\":{\"sort_index\":\(id)}}")
        }
        return "{\"displayTimeUnit\":\"ms\",\"traceEvents\":[\n" + (metadata + events).joined(separator: ",\n") + "\n]}\n"
    }

    private static func quoted(_ string: String) -> String {
        var result = "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default:
                if scalar.value < 0x20 { result += String(format: "\\u%04x", scalar.value) } else { result.unicodeScalars.append(scalar) }
            }
        }
        return result + "\""
    }
}
