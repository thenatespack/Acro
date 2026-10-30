import Foundation

/// Severity of an `EditorLog` entry.
public enum LogLevel: Int, Comparable, CaseIterable, Sendable {
    case info, warning, error

    public static func < (a: LogLevel, b: LogLevel) -> Bool { a.rawValue < b.rawValue }

    public var tag: String {
        switch self {
        case .info: "info"
        case .warning: "warn"
        case .error: "error"
        }
    }
}

public struct LogEntry: Equatable, Sendable {
    public var level: LogLevel
    public var message: String
    /// Editor time (seconds since launch, from accumulated frame dt) when it was logged.
    public var time: Double
    /// Increases by one per entry over the log's lifetime (survives `clear()`).
    public var sequence: Int
}

/// The editor's message log, shown by the console panel: what the editor did (opened, saved,
/// entered play mode) and what failed (load / save / undo errors). The engine has no logging
/// API of its own (it prints), so this one is editor-only. Keeps the last `maxEntries`.
@MainActor
public final class EditorLog {
    public private(set) var entries: [LogEntry] = []
    /// Oldest entries are dropped beyond this.
    public var maxEntries = 1000
    /// Also print entries to stdout (on by default, so command-line runs show errors).
    public var echoesToStandardOutput = true
    /// Increases on every change (append or clear), for panels that poll.
    public private(set) var changeCount = 0
    /// The time stamped on new entries; the host advances it every frame.
    public var time: Double = 0
    private var nextSequence = 0

    public init() {}

    public func log(_ level: LogLevel, _ message: String) {
        entries.append(LogEntry(level: level, message: message, time: time, sequence: nextSequence))
        nextSequence += 1
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }
        changeCount += 1
        if echoesToStandardOutput { print("[\(level.tag)] \(message)") }
    }

    public func info(_ message: String) { log(.info, message) }
    public func warning(_ message: String) { log(.warning, message) }
    public func error(_ message: String) { log(.error, message) }

    public func clear() {
        entries.removeAll()
        changeCount += 1
    }

    /// Entries at `minimum` level or above, oldest first.
    public func entries(atLeast minimum: LogLevel) -> [LogEntry] {
        minimum == .info ? entries : entries.filter { $0.level >= minimum }
    }

    public func count(of level: LogLevel) -> Int { entries.reduce(0) { $0 + ($1.level == level ? 1 : 0) } }
}
