import Foundation

/// A change to a file under a watched folder. Paths are relative to the folder, with "/".
public struct FileChange: Equatable, Hashable, Sendable, CustomStringConvertible {
    public enum Kind: Equatable, Hashable, Sendable {
        case created
        case modified
        case deleted
        /// Moved or renamed from `from` (also relative to the watched folder).
        case renamed(from: String)
    }

    public var kind: Kind
    public var path: String

    public init(_ kind: Kind, _ path: String) {
        self.kind = kind
        self.path = path
    }

    public var description: String {
        switch kind {
        case .created: "created \(path)"
        case .modified: "modified \(path)"
        case .deleted: "deleted \(path)"
        case .renamed(let from): "renamed \(from) -> \(path)"
        }
    }
}

/// Reports files created, modified, deleted and renamed under a folder (recursively, skipping
/// hidden files), by polling: each poll lists the folder and compares size, modification time
/// and file number (inode) with the previous listing. Works the same on macOS, Linux and
/// Windows. A rename is a file that disappeared while one with the same file number appeared
/// (where the platform has no file numbers, the same size and mtime). A file written several
/// times between polls is reported once.
///
/// Either call `poll()` yourself (for example once a second from `Game.update`), or `start`
/// it to poll on a background queue and deliver batches to the main actor:
///
/// ```swift
/// let watcher = FileWatcher(directory: project.assetsURL)
/// watcher.start(interval: 0.5) { changes in assets.reimport(changed: changes) }
/// ```
///
/// Polling costs one directory listing per interval; a few thousand files take a few
/// milliseconds, off the main thread when started. When a poll is slow the interval stretches
/// to 20 times its cost (up to 10 s), so a huge tree never keeps a core busy.
public final class FileWatcher: @unchecked Sendable {
    public let directory: URL

    private struct Entry: Equatable {
        var size: Int64
        var modified: Double
        var fileNumber: UInt64
    }

    // State below is only touched on `queue`.
    private let queue = DispatchQueue(label: "FileWatcher", qos: .utility)
    private var snapshot: [String: Entry]
    private var timer: DispatchSourceTimer?
    private var collected: [FileChange] = []

    /// Takes the initial listing: changes are reported relative to it.
    public init(directory: URL) {
        self.directory = directory
        snapshot = Self.list(directory)
    }

    deinit { timer?.cancel() }

    /// Lists the folder and returns what changed since the previous listing, sorted by path.
    public func poll() -> [FileChange] {
        queue.sync { pollOnQueue() }
    }

    /// Polls every `interval` seconds on a background queue and calls `handler` on the main
    /// actor with each non-empty batch. Replaces an earlier `start`.
    public func start(interval: Double = 0.5, handler: @escaping @MainActor @Sendable ([FileChange]) -> Void) {
        startTimer(interval: interval) { changes in
            DispatchQueue.main.async { MainActor.assumeIsolated { handler(changes) } }
        }
    }

    /// Polls like `start`, but keeps the changes until `takeChanges()` collects them, so a
    /// frame loop can pick them up without relying on the main dispatch queue.
    public func startCollecting(interval: Double = 0.5) {
        startTimer(interval: interval) { [weak self] changes in self?.collected.append(contentsOf: changes) }
    }

    /// The changes found since the last call (`startCollecting`), oldest first.
    public func takeChanges() -> [FileChange] {
        queue.sync {
            defer { collected.removeAll() }
            return collected
        }
    }

    /// `deliver` runs on the watcher's queue.
    private func startTimer(interval: Double, deliver: @escaping @Sendable ([FileChange]) -> Void) {
        queue.sync {
            timer?.cancel()
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(Int(interval * 100)))
            var current = interval
            timer.setEventHandler { [weak self, weak timer] in
                guard let self, let timer else { return }
                let started = DispatchTime.now().uptimeNanoseconds
                let changes = pollOnQueue()
                // Back off when polling is expensive (a big tree): at least 20 polls' worth of idle time.
                let cost = Double(DispatchTime.now().uptimeNanoseconds - started) / 1e9
                let wanted = min(max(interval, cost * 20), 10)
                if abs(wanted - current) > current * 0.25 {
                    current = wanted
                    timer.schedule(deadline: .now() + wanted, repeating: wanted, leeway: .milliseconds(Int(wanted * 100)))
                }
                if !changes.isEmpty { deliver(changes) }
            }
            timer.resume()
            self.timer = timer
        }
    }

    public func stop() {
        queue.sync {
            timer?.cancel()
            timer = nil
        }
    }

    private func pollOnQueue() -> [FileChange] {
        let current = Self.list(directory)
        let changes = Self.diff(old: snapshot, new: current)
        snapshot = current
        return changes
    }

    private static func diff(old: [String: Entry], new: [String: Entry]) -> [FileChange] {
        var changes: [FileChange] = []
        var deleted = old.keys.filter { new[$0] == nil }
        var created = new.keys.filter { old[$0] == nil }.sorted()
        for (path, entry) in new {
            if let previous = old[path], previous != entry { changes.append(FileChange(.modified, path)) }
        }
        // Pair deletions with creations of the same file: renames.
        for path in created {
            let entry = new[path]!
            let match = deleted.firstIndex { gone in
                let was = old[gone]!
                return entry.fileNumber != 0 && was.fileNumber != 0
                    ? was.fileNumber == entry.fileNumber
                    : was.size == entry.size && was.modified == entry.modified
            }
            if let match {
                changes.append(FileChange(.renamed(from: deleted[match]), path))
                deleted.remove(at: match)
            } else {
                changes.append(FileChange(.created, path))
            }
        }
        created.removeAll()
        changes += deleted.map { FileChange(.deleted, $0) }
        return changes.sorted { $0.path < $1.path }
    }

    private static func list(_ directory: URL) -> [String: Entry] {
        var entries: [String: Entry] = [:]
        let root = directory.standardizedFileURL.resolvingSymlinksInPath()
        let base = root.pathComponents
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey],
                                             options: [.skipsHiddenFiles]) else { return [:] }
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true,
                  let attributes = try? fm.attributesOfItem(atPath: url.path) else { continue }
            let components = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            guard components.count > base.count else { continue }
            let path = components.dropFirst(base.count).joined(separator: "/")
            entries[path] = Entry(
                size: (attributes[.size] as? NSNumber)?.int64Value ?? 0,
                modified: (attributes[.modificationDate] as? Date)?.timeIntervalSinceReferenceDate ?? 0,
                fileNumber: (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0)
        }
        return entries
    }
}
