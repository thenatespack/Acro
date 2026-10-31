import Foundation

/// The engine's log: levels, categories, a few sinks and a filter, safe to call from any thread.
///
/// ```swift
/// EngineLog.warning("no mesh '\(key)'", category: .rendering)   // stderr + ring (+ file)
/// EngineLog.debug("\(expensiveDump())", category: .audio)       // not evaluated unless audio logs debug
/// ```
///
/// Messages are autoclosures, so a filtered-out call costs one lock and a comparison.
/// Environment:
/// - `ENGINE_LOG=<level>[,<category>=<level>…]` sets the minimum level (default `info`) and
///   per-category overrides, e.g. `warning,audio=debug,vulkan=trace`. Levels: trace, debug,
///   info, warning, error, fault.
/// - `ENGINE_LOG_FILE=<path>` also appends every message that passes the filter to a file.
///
/// Sinks: standard error (replaced by the handler when one is installed), an in-memory ring
/// of the last `ringCapacity` entries (`recent`; crash reports include it) and the optional
/// file. Backends post their messages (Vulkan validation, with `ENGINE_VULKAN_VALIDATION=1`)
/// here; the editor installs a handler that moves them into its console, where `log.read` and
/// `diagnostics.get` see them. Posting is thread-safe (validation messages arrive on driver
/// threads); the handler runs on the posting thread.
public enum EngineLog {
    public enum Level: Int, Sendable, Comparable, CaseIterable {
        case trace, debug, info, warning, error, fault

        public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }

        public var name: String {
            switch self {
            case .trace: "trace"
            case .debug: "debug"
            case .info: "info"
            case .warning: "warning"
            case .error: "error"
            case .fault: "fault"
            }
        }

        /// Parses a level name (case-insensitive; `warn` works too).
        public init?(name: String) {
            switch name.lowercased() {
            case "trace": self = .trace
            case "debug": self = .debug
            case "info": self = .info
            case "warning", "warn": self = .warning
            case "error": self = .error
            case "fault": self = .fault
            default: return nil
            }
        }
    }

    /// A subsystem tag, filterable on its own (`ENGINE_LOG=audio=debug`). Names are lowercase.
    public struct Category: Hashable, Sendable, ExpressibleByStringLiteral {
        public var name: String
        public init(_ name: String) { self.name = name.lowercased() }
        public init(stringLiteral value: String) { self.init(value) }

        public static let engine: Category = "engine"
        public static let rendering: Category = "rendering"
        public static let vulkan: Category = "vulkan"
        public static let audio: Category = "audio"
        public static let assets: Category = "assets"
        public static let animation: Category = "animation"
        public static let particles: Category = "particles"
        public static let input: Category = "input"
        public static let editor: Category = "editor"
    }

    /// One logged message, as kept in the ring.
    public struct Entry: Sendable, Equatable {
        /// Increases by one per entry that passed the filter.
        public var sequence: Int
        /// Seconds since the log was first used.
        public var time: Double
        public var level: Level
        public var category: Category
        public var message: String

        /// `[   1.234] [warning] [audio] message`
        public var formatted: String {
            let seconds = String(format: "%8.3f", time)
            return "[\(seconds)] [\(level.name)] [\(category.name)] \(message)"
        }
    }

    public typealias Handler = @Sendable (Level, String) -> Void

    // MARK: Logging

    /// Logs `message` if `level` passes the filter for `category`; the message is only built then.
    public static func log(_ level: Level, category: Category = .engine, _ message: @autoclosure () -> String) {
        LogCore.shared.log(level, category, message)
    }

    public static func trace(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.trace, category, message)
    }
    public static func debug(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.debug, category, message)
    }
    public static func info(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.info, category, message)
    }
    public static func warning(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.warning, category, message)
    }
    public static func error(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.error, category, message)
    }
    /// Something the engine can't continue from; `engineFatal` logs this before crashing.
    public static func fault(_ message: @autoclosure () -> String, category: Category = .engine) {
        LogCore.shared.log(.fault, category, message)
    }

    /// Reports `message` in category `engine` (what backends call).
    public static func post(_ level: Level, _ message: String) {
        LogCore.shared.log(level, .engine, { message })
    }

    // MARK: Filter

    /// Messages below this level are dropped unless their category overrides it.
    public static var minimumLevel: Level {
        get { LogCore.shared.minimumLevel }
        set { LogCore.shared.minimumLevel = newValue }
    }

    /// Sets (or with nil, clears) the minimum level of one category.
    public static func setLevel(_ level: Level?, for category: Category) {
        LogCore.shared.setLevel(level, for: category)
    }

    /// Whether a message at `level` in `category` would be logged. Guard expensive prep work with it.
    public static func isEnabled(_ level: Level, category: Category = .engine) -> Bool {
        LogCore.shared.isEnabled(level, category)
    }

    /// Applies an `ENGINE_LOG`-style specification (`warning,audio=debug`); returns the parts it didn't understand.
    @discardableResult
    public static func configure(_ specification: String) -> [String] {
        LogCore.shared.configure(specification)
    }

    // MARK: Sinks

    /// Replaces the handler (nil: print to standard error again).
    public static func setHandler(_ handler: Handler?) {
        LogCore.shared.setHandler(handler)
    }

    /// Whether messages go to standard error when no handler is installed (default true).
    public static var writesToStandardError: Bool {
        get { LogCore.shared.writesToStandardError }
        set { LogCore.shared.writesToStandardError = newValue }
    }

    /// Appends messages to the file at `url` (created if missing); nil stops. Returns false if it can't be opened.
    @discardableResult
    public static func setFile(_ url: URL?) -> Bool {
        LogCore.shared.setFile(url)
    }

    /// The last `count` entries that passed the filter, oldest first (at most `ringCapacity`).
    public static func recent(_ count: Int = .max) -> [Entry] {
        LogCore.shared.recent(count)
    }

    /// How many entries the ring keeps (default 512).
    public static var ringCapacity: Int {
        get { LogCore.shared.ringCapacity }
        set { LogCore.shared.ringCapacity = newValue }
    }
}

/// The log's state. `EngineLog` forwards to the shared instance; tests make their own.
final class LogCore: @unchecked Sendable {
    static let shared = LogCore(environment: ProcessInfo.processInfo.environment)

    private let lock = NSLock()
    private let epoch = DispatchTime.now().uptimeNanoseconds
    private var level: EngineLog.Level = .info
    private var categoryLevels: [EngineLog.Category: EngineLog.Level] = [:]
    private var handler: EngineLog.Handler?
    private var standardError = true
    private var file: FileHandle?
    private var ring: [EngineLog.Entry] = []
    private var ringStart = 0
    private var capacity = 512
    private var sequence = 0

    init(environment: [String: String] = [:]) {
        if let spec = environment["ENGINE_LOG"] {
            let ignored = configure(spec)
            if !ignored.isEmpty { Self.writeStandardError("[engine] ENGINE_LOG: ignoring \(ignored.joined(separator: ", "))\n") }
        }
        if let path = environment["ENGINE_LOG_FILE"], !path.isEmpty, !setFile(URL(fileURLWithPath: path)) {
            Self.writeStandardError("[engine] ENGINE_LOG_FILE: can't open \(path)\n")
        }
    }

    var minimumLevel: EngineLog.Level {
        get { lock.withLock { level } }
        set { lock.withLock { level = newValue } }
    }

    var writesToStandardError: Bool {
        get { lock.withLock { standardError } }
        set { lock.withLock { standardError = newValue } }
    }

    var ringCapacity: Int {
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

    func setLevel(_ newLevel: EngineLog.Level?, for category: EngineLog.Category) {
        lock.withLock { categoryLevels[category] = newLevel }
    }

    func isEnabled(_ messageLevel: EngineLog.Level, _ category: EngineLog.Category) -> Bool {
        lock.withLock { passes(messageLevel, category) }
    }

    /// Caller holds the lock.
    private func passes(_ messageLevel: EngineLog.Level, _ category: EngineLog.Category) -> Bool {
        messageLevel >= (categoryLevels.isEmpty ? level : categoryLevels[category] ?? level)
    }

    func configure(_ specification: String) -> [String] {
        var ignored: [String] = []
        for part in specification.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) where !part.isEmpty {
            let pieces = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            if pieces.count == 1, let parsed = EngineLog.Level(name: pieces[0]) {
                minimumLevel = parsed
            } else if pieces.count == 2, let parsed = EngineLog.Level(name: pieces[1]), !pieces[0].isEmpty {
                setLevel(parsed, for: EngineLog.Category(pieces[0]))
            } else {
                ignored.append(part)
            }
        }
        return ignored
    }

    func setHandler(_ newHandler: EngineLog.Handler?) {
        lock.withLock { handler = newHandler }
    }

    func setFile(_ url: URL?) -> Bool {
        guard let url else {
            lock.withLock {
                try? file?.close()
                file = nil
            }
            return true
        }
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else { return false }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return false }
        _ = try? handle.seekToEnd()
        lock.withLock {
            try? file?.close()
            file = handle
        }
        return true
    }

    func log(_ messageLevel: EngineLog.Level, _ category: EngineLog.Category, _ message: () -> String) {
        guard lock.withLock({ passes(messageLevel, category) }) else { return }
        let text = message()
        let handlerToCall: EngineLog.Handler? = lock.withLock {
            let entry = EngineLog.Entry(
                sequence: sequence, time: Double(DispatchTime.now().uptimeNanoseconds - epoch) * 1e-9,
                level: messageLevel, category: category, message: text)
            sequence += 1
            if ring.count < capacity {
                ring.append(entry)
            } else {
                ring[ringStart] = entry
                ringStart = (ringStart + 1) % capacity
            }
            let line = entry.formatted + "\n"
            if let file, let data = line.data(using: .utf8) { try? file.write(contentsOf: data) }
            if handler == nil, standardError { Self.writeStandardError(line) }
            return handler
        }
        handlerToCall?(messageLevel, text)
    }

    func recent(_ count: Int) -> [EngineLog.Entry] {
        lock.withLock { Array(orderedRing().suffix(max(count, 0))) }
    }

    /// The ring's entries, oldest first, without blocking: nil if another thread holds the lock
    /// (a crash report must not wait on a lock the crashed thread may own).
    func recentWithoutWaiting(_ count: Int) -> [EngineLog.Entry]? {
        guard lock.try() else { return nil }
        defer { lock.unlock() }
        return Array(orderedRing().suffix(max(count, 0)))
    }

    /// Caller holds the lock.
    private func orderedRing() -> [EngineLog.Entry] {
        ring.count < capacity || ringStart == 0 ? ring : Array(ring[ringStart...] + ring[..<ringStart])
    }

    private static func writeStandardError(_ string: String) {
        if let data = string.data(using: .utf8) { FileHandle.standardError.write(data) }
    }
}
