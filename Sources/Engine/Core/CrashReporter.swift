import Foundation

/// Writes a crash report when the engine hits `engineFatal` or the process gets a fatal signal
/// (SIGSEGV, SIGABRT, SIGILL, SIGBUS, SIGFPE, SIGTRAP: what Swift traps and `precondition`
/// failures raise). The report is a text file with the reason, a backtrace, engine / backend /
/// GPU information and the last log lines, written to `directory` (`ENGINE_CRASH_DIR`, default
/// `<temporary directory>/EngineCrashReports`); its path is printed to standard error.
/// `Engine.run` installs the handlers; `ENGINE_CRASH_REPORTS=0` turns that off.
///
/// Async-signal safety: a signal handler may only call a few C functions, and this one calls
/// Foundation (allocation, locks, file APIs) because a useful report needs it. That can deadlock
/// or crash again if the signal interrupted malloc or a lock, so it is best effort, with
/// mitigations: the log ring is read with a try-lock (skipped if held), handlers are reset to
/// the default before the report starts so a second fault terminates normally, and a 5 second
/// `alarm` kills a handler that hangs (POSIX). The handler runs on the crashing thread's own
/// stack, so a stack overflow can't be reported. Only `engineFatal` (not a signal) is fully
/// safe, since it runs in normal context.
public enum CrashReporter {
    /// Signals that get a report (POSIX; Windows has no SIGBUS).
    static var signals: [Int32] {
        #if os(Windows)
        [SIGSEGV, SIGABRT, SIGILL, SIGFPE]
        #else
        [SIGSEGV, SIGABRT, SIGILL, SIGBUS, SIGFPE, SIGTRAP]
        #endif
    }

    /// Where reports are written.
    public static var directory: URL {
        if let path = ProcessInfo.processInfo.environment["ENGINE_CRASH_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("EngineCrashReports", isDirectory: true)
    }

    /// How many log lines a report includes.
    public static let logLineCount = 200

    private static let lock = NSLock()
    nonisolated(unsafe) private static var info: [(key: String, value: String)] = []
    nonisolated(unsafe) private static var installed = false
    nonisolated(unsafe) private static var reported = false
    nonisolated(unsafe) private static var lastReport: URL?
    /// The frame being run (set by `Engine` each frame; a plain word, so a signal handler can read it).
    nonisolated(unsafe) public static var frame = 0

    /// Installs the signal handlers (once). Does nothing with `ENGINE_CRASH_REPORTS=0`.
    public static func install() {
        let enabled = ProcessInfo.processInfo.environment["ENGINE_CRASH_REPORTS"] != "0"
        let shouldInstall: Bool = lock.withLock {
            defer { installed = true }
            return enabled && !installed
        }
        guard shouldInstall else { return }
        for signalNumber in signals { signal(signalNumber, crashSignalHandler) }
    }

    /// Adds a line to the "Engine" section of reports (replaces an earlier line with the same key).
    public static func setInfo(_ key: String, _ value: String) {
        lock.withLock {
            if let i = info.firstIndex(where: { $0.key == key }) { info[i].value = value } else { info.append((key, value)) }
        }
    }

    /// The path of the report written by this process, if any.
    public static var lastReportURL: URL? { lock.withLock { lastReport } }

    /// Writes a report for `reason` and prints its path. Only the first call per process writes
    /// (a fatal error usually ends in a signal, which must not write a second report). Returns
    /// nil if a report was already written or the file couldn't be created.
    @discardableResult
    public static func writeReport(reason: String, directory: URL? = nil, backtrace: [String]? = nil) -> URL? {
        // A signal handler can't wait for this lock: if the crash happened inside `setInfo`, skip it.
        let acquired = lock.try()
        if !acquired && !Thread.isMainThread { return nil }
        defer { if acquired { lock.unlock() } }
        if reported { return nil }
        reported = true

        let directory = directory ?? Self.directory
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let now = Date()
        let process = ProcessInfo.processInfo
        let url = directory.appendingPathComponent("crash-\(formatter.string(from: now))-\(process.processIdentifier).txt")

        var text = "Engine crash report\n"
        text += "Reason: \(reason)\n"
        text += "Date: \(ISO8601DateFormatter().string(from: now))\n"
        text += "Process: \(process.processName) (pid \(process.processIdentifier))\n"
        text += "OS: \(process.operatingSystemVersionString)\n"
        #if DEBUG
        text += "Build: debug\n"
        #else
        text += "Build: release\n"
        #endif
        text += "Thread: \(Thread.isMainThread ? "main" : "other")\n"
        text += "Frame: \(frame)\n"
        text += "\nEngine\n"
        for (key, value) in info { text += "  \(key): \(value)\n" }
        text += "\nBacktrace\n"
        for line in backtrace ?? Thread.callStackSymbols { text += "  \(line)\n" }
        text += "\nLast log lines\n"
        if let entries = LogCore.shared.recentWithoutWaiting(logLineCount) {
            for entry in entries { text += "  \(entry.formatted)\n" }
        } else {
            text += "  (log busy; skipped)\n"
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try text.write(to: url, atomically: false, encoding: .utf8)
        } catch {
            FileHandle.standardError.write(Data("Crash report could not be written to \(url.path): \(error)\n".utf8))
            return nil
        }
        lastReport = url
        FileHandle.standardError.write(Data("Crash report written to \(url.path)\n".utf8))
        return url
    }

    /// Re-arms `writeReport` (tests only).
    static func resetForTesting() { lock.withLock { reported = false; lastReport = nil } }
}

/// `signal` handlers are C functions: no captures, so this forwards to `CrashReporter`.
private func crashSignalHandler(_ signalNumber: Int32) {
    signal(signalNumber, SIG_DFL)
    #if !os(Windows)
    alarm(5)
    #endif
    let name: String
    switch signalNumber {
    case SIGSEGV: name = "SIGSEGV (invalid memory access)"
    case SIGABRT: name = "SIGABRT (abort)"
    case SIGILL: name = "SIGILL (illegal instruction / Swift trap)"
    case SIGFPE: name = "SIGFPE (arithmetic error)"
    #if !os(Windows)
    case SIGBUS: name = "SIGBUS (bus error)"
    case SIGTRAP: name = "SIGTRAP (Swift trap)"
    #endif
    default: name = "signal \(signalNumber)"
    }
    CrashReporter.writeReport(reason: name)
    raise(signalNumber)
}
