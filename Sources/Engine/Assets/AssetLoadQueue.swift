import Foundation

/// A small pool of worker threads that run `AssetImportJob`s. Results wait in a mailbox until
/// the main actor takes them (`AssetDatabase.pump`), so nothing depends on the main run loop
/// spinning (tests and screenshot runs can wait synchronously).
final class AssetLoadQueue: @unchecked Sendable {
    private let operations = OperationQueue()
    private let condition = NSCondition()
    private var finished: [AssetImportResult] = []

    init(workers: Int? = nil) {
        operations.name = "AssetLoadQueue"
        operations.qualityOfService = .utility
        operations.maxConcurrentOperationCount = workers ?? max(1, min(4, ProcessInfo.processInfo.activeProcessorCount - 1))
    }

    /// Queues `job`; `run()` happens on a worker thread.
    func submit(_ job: AssetImportJob) {
        operations.addOperation { [self] in
            let result = job.run()
            condition.lock()
            finished.append(result)
            condition.broadcast()
            condition.unlock()
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

/// How far the database's background loading has got: jobs submitted since it was last idle.
public struct AssetLoadProgress: Equatable, Sendable {
    /// Jobs applied (or discarded as out of date) so far in this batch.
    public var completed = 0
    /// Jobs submitted in this batch (it restarts from 0 when the database goes idle).
    public var total = 0

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
