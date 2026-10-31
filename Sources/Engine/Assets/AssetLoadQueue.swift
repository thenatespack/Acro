import Foundation

/// Runs `AssetImportJob`s as `.background` jobs on a `JobSystem` (the engine's shared one by
/// default), at most `maxRunning` at a time so frame work always finds free workers. Jobs wait
/// in submission order, `.high` priority ones ahead of the rest. Results wait in a mailbox until
/// the main actor takes them (`AssetDatabase.pump`), so nothing depends on the main run loop
/// spinning (tests and screenshot runs can wait synchronously).
///
/// Imports never run on a thread waiting in `JobSystem.wait` or `parallelFor` (background jobs
/// are left to workers), so a frame's parallel loops aren't held up by one. With no workers
/// (`ENGINE_JOB_THREADS` 0 or 1) a job runs on the submitting thread before `submit` returns.
final class AssetLoadQueue: @unchecked Sendable {
    private struct Entry {
        let job: AssetImportJob
        let priority: AssetLoadPriority
    }

    let jobs: JobSystem
    let maxRunning: Int
    private let condition = NSCondition()
    /// Not started yet, in the order they'll start.
    private var waiting: [Entry] = []
    private var running: Set<AssetID> = []
    private var finished: [AssetImportResult] = []

    init(jobs: JobSystem = .shared, maxRunning: Int? = nil) {
        self.jobs = jobs
        self.maxRunning = max(1, maxRunning ?? min(4, jobs.workerCount - 1))
    }

    /// Queues `job` (`.high` ahead of everything waiting at `.normal`); `run()` happens on a
    /// job worker.
    func submit(_ job: AssetImportJob, priority: AssetLoadPriority = .normal) {
        condition.lock()
        let entry = Entry(job: job, priority: priority)
        if priority == .high, let index = waiting.firstIndex(where: { $0.priority == .normal }) {
            waiting.insert(entry, at: index)
        } else {
            waiting.append(entry)
        }
        let start = takeStartable()
        condition.unlock()
        for entry in start { schedule(entry) }
    }

    /// Moves `id`'s waiting job ahead of the `.normal` ones. Returns whether one was waiting.
    @discardableResult
    func prioritize(_ id: AssetID) -> Bool {
        condition.withLock {
            guard let index = waiting.firstIndex(where: { $0.job.context.assetID == id }) else { return false }
            let entry = waiting.remove(at: index)
            let front = waiting.firstIndex { $0.priority == .normal } ?? waiting.count
            waiting.insert(Entry(job: entry.job, priority: .high), at: front)
            return true
        }
    }

    /// Drops `id`'s job if it hasn't started. Returns false if there is none waiting (it may be
    /// running: its result still arrives).
    func cancel(_ id: AssetID) -> Bool {
        condition.withLock {
            guard let index = waiting.firstIndex(where: { $0.job.context.assetID == id }) else { return false }
            waiting.remove(at: index)
            return true
        }
    }

    /// Jobs on a worker now, and jobs waiting to start.
    var runningCount: Int { condition.withLock { running.count } }
    var waitingCount: Int { condition.withLock { waiting.count } }

    /// Entries to start now (up to `maxRunning`), marked running. Caller holds the lock.
    private func takeStartable() -> [Entry] {
        var start: [Entry] = []
        while running.count < maxRunning, !waiting.isEmpty {
            let entry = waiting.removeFirst()
            running.insert(entry.job.context.assetID)
            start.append(entry)
        }
        return start
    }

    private func schedule(_ entry: Entry) {
        jobs.schedule("import \(entry.job.context.assetPath)", priority: .background) { [self] in
            let result = entry.job.run()
            condition.lock()
            running.remove(entry.job.context.assetID)
            finished.append(result)
            let next = takeStartable()
            condition.broadcast()
            condition.unlock()
            for entry in next { schedule(entry) }
        }
    }

    /// Results that finished since the last call (oldest first), without blocking.
    func takeFinished() -> [AssetImportResult] {
        condition.lock()
        defer { condition.unlock() }
        let results = finished
        finished.removeAll()
        return results
    }

    /// Blocks until a result is waiting or `timeout` seconds pass.
    func waitForFinished(timeout: TimeInterval) {
        condition.lock()
        if finished.isEmpty { _ = condition.wait(until: Date(timeIntervalSinceNow: timeout)) }
        condition.unlock()
    }
}

/// Where a background load waits (`AssetDatabase.request(_:priority:)`).
public enum AssetLoadPriority: Sendable {
    /// In request order.
    case normal
    /// Ahead of every `.normal` load that hasn't started (e.g. what the camera sees first).
    case high
}

/// How far the database's background loading has got: jobs submitted since it was last idle.
public struct AssetLoadProgress: Equatable, Sendable {
    /// Jobs applied, discarded as out of date or cancelled so far in this batch.
    public var completed = 0
    /// Jobs submitted in this batch (it restarts from 0 when the database goes idle).
    public var total = 0
    /// Of `completed`, the loads cancelled (`AssetDatabase.cancelLoading`).
    public var cancelled = 0

    public var pending: Int { total - completed }
    public var isIdle: Bool { pending == 0 }
    /// 0...1; 1 when idle.
    public var fraction: Double { total == 0 ? 1 : Double(completed) / Double(total) }
}

/// Where an asset is in loading (`AssetDatabase.loadState(of:)`).
public enum AssetLoadState: Sendable {
    /// Imported or read from the cache; `AssetDatabase.asset(_:)` returns it without blocking.
    case loaded
    /// A background import or cache read is queued or running.
    case loading
    /// Not requested yet (`AssetDatabase.request(_:)` starts it).
    case unloaded
    /// Its import failed, or no importer handles it.
    case failed
    /// No such asset (never existed, or deleted).
    case missing
}
