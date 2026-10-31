import Foundation
import Testing
@testable import Engine

private func quietLog(_ environment: [String: String] = [:]) -> LogCore {
    let log = LogCore(environment: environment)
    log.writesToStandardError = false
    return log
}

private final class Received: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    func add(_ value: String) { lock.withLock { storage.append(value) } }
    var values: [String] { lock.withLock { storage } }
}

@Test func defaultLevelIsInfo() {
    let log = quietLog()
    log.log(.debug, .engine) { "hidden" }
    log.log(.info, .engine) { "shown" }
    log.log(.fault, .engine) { "worse" }
    #expect(log.recent(10).map(\.message) == ["shown", "worse"])
}

@Test func environmentSetsLevelAndCategoryOverrides() {
    let log = quietLog(["ENGINE_LOG": "warning, audio=trace ,rendering=error"])
    log.log(.info, .engine) { "no" }
    log.log(.warning, .engine) { "yes" }
    log.log(.trace, .audio) { "audio trace" }
    log.log(.warning, .rendering) { "rendering warning" }
    log.log(.error, .rendering) { "rendering error" }
    #expect(log.recent(10).map(\.message) == ["yes", "audio trace", "rendering error"])
    #expect(log.isEnabled(.debug, .audio) && !log.isEnabled(.debug, .input))
}

@Test func configureReportsWhatItCannotParse() {
    let log = quietLog()
    #expect(log.configure("loud,audio=debug,=info,x=y") == ["loud", "=info", "x=y"])
    #expect(log.isEnabled(.debug, "audio"))
}

@Test func filteredMessagesAreNotBuilt() {
    let log = quietLog(["ENGINE_LOG": "error"])
    nonisolated(unsafe) var built = 0
    log.log(.debug, .engine) { built += 1; return "expensive" }
    log.log(.warning, .engine) { built += 1; return "expensive" }
    #expect(built == 0)
    log.log(.error, .engine) { built += 1; return "expensive" }
    #expect(built == 1)
}

@Test func ringKeepsTheLastEntriesInOrder() {
    let log = quietLog()
    log.ringCapacity = 4
    for i in 0..<10 { log.log(.info, .engine) { "m\(i)" } }
    #expect(log.recent(100).map(\.message) == ["m6", "m7", "m8", "m9"])
    #expect(log.recent(2).map(\.message) == ["m8", "m9"])
    #expect(log.recent(100).map(\.sequence) == [6, 7, 8, 9])
    log.ringCapacity = 2
    #expect(log.recent(100).map(\.message) == ["m8", "m9"])
    log.ringCapacity = 8
    log.log(.info, .engine) { "m10" }
    #expect(log.recent(100).map(\.message) == ["m8", "m9", "m10"])
}

@Test func handlerReplacesStandardErrorAndSeesLevels() {
    let log = quietLog()
    let received = Received()
    log.setHandler { level, message in received.add("\(level.name):\(message)") }
    log.log(.warning, .audio) { "w" }
    log.log(.trace, .audio) { "t" }
    #expect(received.values == ["warning:w"])
    #expect(log.recent(10).count == 1)
}

@Test func fileSinkAppendsFormattedLines() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("engine-log-\(UUID().uuidString).txt")
    defer { try? FileManager.default.removeItem(at: url) }
    let log = quietLog(["ENGINE_LOG_FILE": url.path])
    log.log(.info, .assets) { "first" }
    log.log(.debug, .assets) { "dropped" }
    log.log(.error, "Custom") { "second" }
    #expect(log.setFile(nil))
    log.log(.info, .assets) { "after close" }
    let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
    #expect(lines.count == 2)
    #expect(lines[0].hasSuffix("[info] [assets] first"))
    #expect(lines[1].hasSuffix("[error] [custom] second"))
}

@Test func unopenableFileIsReported() {
    let log = quietLog()
    #expect(!log.setFile(URL(fileURLWithPath: "/nonexistent-dir/log.txt")))
}

@Test func loggingFromManyThreadsLosesNothing() {
    let log = quietLog()
    log.ringCapacity = 10_000
    DispatchQueue.concurrentPerform(iterations: 8) { thread in
        for i in 0..<250 { log.log(.info, .engine) { "t\(thread)-\(i)" } }
    }
    let entries = log.recent(10_000)
    #expect(entries.count == 2000)
    #expect(Set(entries.map(\.sequence)).count == 2000)
}

@Test func levelNamesRoundTrip() {
    for level in EngineLog.Level.allCases { #expect(EngineLog.Level(name: level.name.uppercased()) == level) }
    #expect(EngineLog.Level(name: "warn") == .warning)
    #expect(EngineLog.Level(name: "loud") == nil)
    #expect(EngineLog.Level.trace < .debug && EngineLog.Level.error < .fault)
}

@Test func filteredCallsAreCheap() {
    let log = quietLog(["ENGINE_LOG": "error"])
    let elapsed = ContinuousClock().measure {
        for i in 0..<200_000 { log.log(.debug, .engine) { "never built \(i)" } }
    }
    // Generous: unoptimized this still takes a few ms.
    #expect(elapsed < .seconds(1))
}

@Test func assertionsThatHoldDoNothing() {
    engineAssert(1 + 1 == 2, "math")
    #expect(engineVerify(true, "fine"))
}

@Test func crashReportHasReasonBacktraceInfoAndLog() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("crash-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    CrashReporter.resetForTesting()
    defer { CrashReporter.resetForTesting() }
    CrashReporter.setInfo("Backend", "testing")
    LogCore.shared.writesToStandardError = false
    defer { LogCore.shared.writesToStandardError = true }
    EngineLog.error("something went wrong before the crash", category: .engine)
    let url = try #require(CrashReporter.writeReport(reason: "unit test", directory: directory))
    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(text.contains("Reason: unit test"))
    #expect(text.contains("Backend: testing"))
    #expect(text.contains("Backtrace"))
    #expect(text.contains("something went wrong before the crash"))
    // Only the first report of a process is written.
    #expect(CrashReporter.writeReport(reason: "second", directory: directory) == nil)
}
