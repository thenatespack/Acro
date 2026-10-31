import Foundation

/// Logs a fault, writes a crash report (see `CrashReporter`) and traps. Use it for states the
/// engine can't continue from, instead of `fatalError` (which leaves nothing behind but a stack
/// trace). The same in debug and release.
public func engineFatal(
    _ message: @autoclosure () -> String, category: EngineLog.Category = .engine,
    file: StaticString = #fileID, line: UInt = #line
) -> Never {
    let text = message()
    EngineLog.fault("\(text) (\(file):\(line))", category: category)
    CrashReporter.writeReport(reason: "engineFatal: \(text) (\(file):\(line))")
    fatalError(text, file: file, line: line)
}

/// Debug builds: like `engineFatal` when `condition` is false. Release builds: nothing, and
/// `condition` isn't evaluated (so it may be expensive, but must not have side effects).
/// For invariants that are bugs in the engine or game, not bad input.
@inline(__always)
public func engineAssert(
    _ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "",
    category: EngineLog.Category = .engine, file: StaticString = #fileID, line: UInt = #line
) {
    #if DEBUG
    if !condition() {
        engineFatal("Assertion failed" + (message().isEmpty ? "" : ": \(message())"), category: category, file: file, line: line)
    }
    #endif
}

/// Checks `condition` in every build. When it is false, debug builds behave like `engineFatal`;
/// release builds log an error (with file and line) and return false, so the caller can recover.
/// For conditions that depend on input but should never happen.
@discardableResult
public func engineVerify(
    _ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = "",
    category: EngineLog.Category = .engine, file: StaticString = #fileID, line: UInt = #line
) -> Bool {
    if condition() { return true }
    let suffix = message().isEmpty ? "" : ": \(message())"
    #if DEBUG
    engineFatal("Verification failed\(suffix)", category: category, file: file, line: line)
    #else
    EngineLog.error("Verification failed\(suffix) (\(file):\(line))", category: category)
    return false
    #endif
}
