import Foundation

/// A job scheduled on a `JobSystem`: wait for it with `JobSystem.wait(_:)`, or name it as a
/// dependency of later jobs.
public final class JobHandle: @unchecked Sendable {
    public let name: String
    // All guarded by the system's lock.
    fileprivate var body: (@Sendable () -> Void)?
    fileprivate var pendingDependencies = 0
    fileprivate var dependents: [JobHandle] = []
    fileprivate var finished = false
    fileprivate let group: JobGroup?
    fileprivate let system: JobSystem

    fileprivate init(name: String, body: @escaping @Sendable () -> Void, group: JobGroup?, system: JobSystem) {
        self.name = name
        self.body = body
        self.group = group
        self.system = system
    }

    /// Whether the job has run.
    public var isComplete: Bool { system.withLock { finished } }
}

/// Jobs waited for together: pass it to `JobSystem.schedule(_:after:in:_:)`, then
/// `JobSystem.wait(_:)` for all of them.
public final class JobGroup: @unchecked Sendable {
    /// Jobs scheduled in the group that haven't finished (guarded by the system's lock).
    fileprivate var unfinished = 0

    public init() {}
}

/// A fixed pool of worker threads running jobs: one-off jobs with dependencies and groups, and
/// `parallelFor` loops split into batches.
///
/// ```swift
/// let jobs = JobSystem.shared
/// jobs.parallelFor(0..<items.count, batchSize: 256, name: "cull") { range in
///     for i in range { visible[i] = frustum.intersects(items[i].bounds) }   // disjoint writes only
/// }
/// let a = jobs.schedule("load a") { … }
/// let b = jobs.schedule("load b") { … }
/// let c = jobs.schedule("combine", after: [a, b]) { … }
/// jobs.wait(c)
/// ```
///
/// - **Threads:** `ENGINE_JOB_THREADS=<n>` sets the total number of threads that run jobs,
///   counting the calling (main) thread, so `n - 1` workers; the default is one per core
///   (`activeProcessorCount`), at most 16. `0` or `1` runs everything inline on the calling
///   thread, in submission order; a job with dependencies then runs when it is scheduled (its
///   dependencies, scheduled earlier, have already run).
/// - **Waiting helps:** `wait` and `parallelFor` never just block: the waiting thread runs
///   queued jobs (any, not only the awaited ones) until what it waits for is done, so waiting
///   from a job on a worker can't deadlock the pool, and the main thread does its share of a loop.
/// - **Determinism:** jobs run in any order on any thread. Callers keep results identical
///   to a single-threaded run by giving each job its own output (e.g. an index range of an
///   array) and merging them in a fixed order afterwards; the engine's uses do this, so their
///   results don't depend on `ENGINE_JOB_THREADS`.
/// - **Profiler:** workers are named "job worker N" in the CPU profiler (their own lanes in
///   the overlay timeline and the Chrome trace), and every job and each worker's share of a
///   loop records a scope under the job's or loop's name.
/// - **Main thread:** any thread may schedule, wait and loop, including the main thread
///   (`@MainActor` code). A `parallelFor` body runs on several threads at once, so it must only
///   read shared state and write its own slots; it must not mutate a `World`, `PhysicsWorld` or
///   other main-actor objects (reading a world nobody writes meanwhile is fine).
public final class JobSystem: @unchecked Sendable {
    /// The engine's job system, sized by `ENGINE_JOB_THREADS` on first use.
    public static let shared = JobSystem(threadCount: threadCount(environment: ProcessInfo.processInfo.environment))

    /// Worker threads (0: everything runs inline on the calling thread).
    public let workerCount: Int
    /// Threads that run jobs, counting the one that waits: `workerCount + 1`.
    public var threadCount: Int { workerCount + 1 }
    /// Whether jobs run inline on the calling thread.
    public var isInline: Bool { workerCount == 0 }

    private enum Work {
        case job(JobHandle)
        case loop(LoopContext)
    }

    private let condition = NSCondition()
    private var queue: [Work] = []
    private var queueHead = 0
    private var stopping = false
    private var runningWorkers = 0

    /// The thread count `ENGINE_JOB_THREADS` asks for, or one per core (at most 16).
    static func threadCount(environment: [String: String]) -> Int {
        if let value = environment["ENGINE_JOB_THREADS"], let n = Int(value.trimmingCharacters(in: .whitespaces)), n >= 0 {
            return min(n, 64)
        }
        return min(ProcessInfo.processInfo.activeProcessorCount, 16)
    }

    /// A pool running jobs on `threadCount` threads in all: the caller plus `threadCount - 1`
    /// workers (0 or 1: inline).
    public init(threadCount: Int) {
        workerCount = max(threadCount - 1, 0)
        // Start workers one at a time so they register with the profiler in order (stable lane order).
        let started = DispatchSemaphore(value: 0)
        for index in 0..<workerCount {
            // Workers keep the pool alive until `shutdown()`.
            let thread = Thread { [self] in
                Profiler.nameCurrentThread("job worker \(index + 1)")
                started.signal()
                workerLoop()
            }
            thread.name = "Engine job worker \(index + 1)"
            thread.qualityOfService = .userInteractive
            thread.stackSize = 1 << 20
            runningWorkers += 1
            thread.start()
            started.wait()
        }
    }

    /// Stops the workers once the queue is empty; later jobs run inline. A pool's workers keep
    /// it alive until then (the shared one lives for the whole process; tests shut theirs down).
    public func shutdown() {
        condition.lock()
        stopping = true
        condition.broadcast()
        while runningWorkers > 0 { condition.wait() }
        condition.unlock()
    }

    fileprivate func withLock<T>(_ body: () -> T) -> T {
        condition.lock()
        defer { condition.unlock() }
        return body()
    }

    // MARK: - Jobs

    /// Schedules `body` to run once every job in `dependencies` has finished (at once if they
    /// have), counted in `group` if given. Inline, it runs before this returns.
    @discardableResult
    public func schedule(_ name: String, after dependencies: [JobHandle] = [], in group: JobGroup? = nil,
                         _ body: @escaping @Sendable () -> Void) -> JobHandle {
        let job = JobHandle(name: name, body: body, group: group, system: self)
        condition.lock()
        group?.unfinished += 1
        for dependency in dependencies where !dependency.finished {
            precondition(dependency.system === self, "JobSystem: a dependency belongs to another job system")
            dependency.dependents.append(job)
            job.pendingDependencies += 1
        }
        let ready = job.pendingDependencies == 0
        let inline = isInline || stopping
        if ready && !inline { push(.job(job)) }
        condition.unlock()
        if ready && inline { run(job) }
        // Inline, a job with pending dependencies can only wait for jobs that run later by
        // being scheduled after it, which a single thread can't do; they all ran already.
        return job
    }

    /// Returns once `job` has finished, running other jobs meanwhile.
    public func wait(_ job: JobHandle) {
        waitHelping { job.finished }
    }

    /// Returns once every job scheduled in `group` has finished, running jobs meanwhile.
    public func wait(_ group: JobGroup) {
        waitHelping { group.unfinished == 0 }
    }

    /// Caller holds the lock.
    private func push(_ work: Work) {
        queue.append(work)
        condition.signal()
    }

    /// Caller holds the lock.
    private func pop() -> Work? {
        guard queueHead < queue.count else { return nil }
        let work = queue[queueHead]
        queueHead += 1
        if queueHead == queue.count {
            queue.removeAll(keepingCapacity: true)
            queueHead = 0
        } else if queueHead >= 1024, queueHead * 2 >= queue.count {
            queue.removeFirst(queueHead)
            queueHead = 0
        }
        return work
    }

    private func perform(_ work: Work) {
        switch work {
        case .job(let job): run(job)
        case .loop(let loop): loop.drain(self)
        }
    }

    private func run(_ job: JobHandle) {
        let body = withLock { () -> (@Sendable () -> Void)? in
            defer { job.body = nil }
            return job.body
        }
        if let body { Profiler.scope(job.name, body) }
        condition.lock()
        job.finished = true
        job.group?.unfinished -= 1
        let dependents = job.dependents
        job.dependents = []
        var inlineReady: [JobHandle] = []
        for dependent in dependents {
            dependent.pendingDependencies -= 1
            guard dependent.pendingDependencies == 0 else { continue }
            if isInline || stopping { inlineReady.append(dependent) } else { push(.job(dependent)) }
        }
        condition.broadcast()
        condition.unlock()
        for dependent in inlineReady { run(dependent) }
    }

    /// Runs queued work until `done` (read under the lock) holds.
    private func waitHelping(until done: () -> Bool) {
        condition.lock()
        while !done() {
            if let work = pop() {
                condition.unlock()
                perform(work)
                condition.lock()
            } else {
                condition.wait()
            }
        }
        condition.unlock()
    }

    private func workerLoop() {
        condition.lock()
        while true {
            if let work = pop() {
                condition.unlock()
                perform(work)
                condition.lock()
            } else if stopping {
                break
            } else {
                condition.wait()
            }
        }
        runningWorkers -= 1
        condition.broadcast()
        condition.unlock()
    }

    // MARK: - Loops

    /// One `parallelFor`: batches are claimed in order by the caller and by helper entries in
    /// the queue (one per worker that could help).
    private final class LoopContext: @unchecked Sendable {
        let name: String
        let lower: Int, upper: Int, batchSize: Int, batches: Int
        private let lock = NSLock()
        private var next = 0
        /// Batches finished (guarded by `lock`; read by the waiter under the system lock too).
        private var done = 0
        /// Cleared before `parallelFor` returns; only read after claiming a batch, which can't
        /// happen once every batch is done.
        private var body: ((Range<Int>) -> Void)?

        init(name: String, range: Range<Int>, batchSize: Int, body: @escaping (Range<Int>) -> Void) {
            self.name = name
            lower = range.lowerBound
            upper = range.upperBound
            self.batchSize = batchSize
            batches = (range.count + batchSize - 1) / batchSize
            self.body = body
        }

        var isFinished: Bool { lock.withLock { done == batches } }

        private func claim() -> Range<Int>? {
            lock.withLock {
                guard next < batches else { return nil }
                let start = lower + next * batchSize
                next += 1
                return start..<min(start + batchSize, upper)
            }
        }

        /// Calls the body; its reference is released before this returns, so once every batch
        /// is counted as done nothing holds the (not really escaping) closure any more.
        @inline(never)
        private func call(_ range: Range<Int>) {
            let body = lock.withLock { self.body }
            body?(range)
        }

        /// Runs batches until none are left (under a profiler scope named after the loop, if
        /// `recordsScope` and it got any); the thread finishing the last one wakes the waiter.
        func drain(_ system: JobSystem, recordsScope: Bool = true) {
            var scoped = false
            var finishedLast = false
            while let range = claim() {
                if recordsScope && !scoped {
                    Profiler.begin(name)
                    scoped = true
                }
                call(range)
                lock.withLock {
                    done += 1
                    finishedLast = done == batches
                }
            }
            if scoped { Profiler.end() }
            if finishedLast {
                system.condition.lock()
                system.condition.broadcast()
                system.condition.unlock()
            }
        }

        func releaseBody() { lock.withLock { body = nil } }
    }

    /// Calls `body` with consecutive sub-ranges of `range` of `batchSize` elements (the last may
    /// be shorter), on the calling thread and the workers at once, and returns when all are done.
    /// Inline, or with a single batch, the batches run in order on the calling thread.
    ///
    /// The body must only read shared data and write disjoint data per index (see the type's
    /// notes); merge per-batch results in index order to stay deterministic. Pick a batch size
    /// that makes a batch worth tens of microseconds: each costs a lock round trip.
    public func parallelFor(_ range: Range<Int>, batchSize: Int = 1, name: String = "parallelFor",
                            _ body: (Range<Int>) -> Void) {
        let batch = max(batchSize, 1)
        let batches = (range.count + batch - 1) / batch
        guard batches > 0 else { return }
        if batches == 1 || isInline {
            Profiler.scope(name) {
                var start = range.lowerBound
                while start < range.upperBound {
                    body(start..<min(start + batch, range.upperBound))
                    start += batch
                }
            }
            return
        }
        Profiler.begin(name)
        defer { Profiler.end() }
        withoutActuallyEscaping(body) { escaping in
            let loop = LoopContext(name: name, range: range, batchSize: batch, body: escaping)
            condition.lock()
            let helping = !stopping
            if helping { for _ in 0..<min(workerCount, batches - 1) { push(.loop(loop)) } }
            condition.unlock()
            // The caller's share is recorded inside the scope it already has.
            loop.drain(self, recordsScope: false)
            waitHelping { loop.isFinished }
            // Helper entries still queued find nothing to claim and drop their reference later;
            // the body must not outlive this call.
            loop.releaseBody()
        }
    }

    /// `transform(i)` for every `i` in `0..<count`, computed by `parallelFor` and returned in
    /// index order.
    public func parallelMap<T>(_ count: Int, batchSize: Int = 1, name: String = "parallelMap",
                               _ transform: (Int) -> T) -> [T] {
        guard count > 0 else { return [] }
        return [T](unsafeUninitializedCapacity: count) { buffer, initialized in
            let base = buffer.baseAddress!
            parallelFor(0..<count, batchSize: batchSize, name: name) { range in
                for i in range { (base + i).initialize(to: transform(i)) }
            }
            initialized = count
        }
    }
}
