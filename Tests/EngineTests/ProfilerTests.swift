import Foundation
import Testing
@testable import Engine

private func spin(_ seconds: Double) {
    let end = DispatchTime.now().uptimeNanoseconds + UInt64(seconds * 1e9)
    while DispatchTime.now().uptimeNanoseconds < end {}
}

@Test func scopesNestAndRecordDepthAndOrder() throws {
    let profiler = ProfilerCore()
    profiler.beginFrame(index: 7)
    profiler.begin("outer")
    profiler.begin("inner")
    spin(0.002)
    profiler.end()
    profiler.begin("second")
    profiler.end()
    profiler.end()
    profiler.endFrame(gpuPasses: [GPUPassTime(name: "scene", seconds: 0.001)])
    let frame = try #require(profiler.frames.first)
    #expect(frame.index == 7)
    #expect(frame.events.map(\.name) == ["inner", "second", "outer"])
    #expect(frame.events.map(\.depth) == [1, 1, 0])
    let outer = frame.events[2], inner = frame.events[0]
    #expect(inner.start >= outer.start && inner.start + inner.duration <= outer.start + outer.duration + 1e-9)
    #expect(inner.duration >= 0.002)
    #expect(frame.gpuPasses.map(\.name) == ["scene"])
    #expect(frame.end >= frame.start)
}

@Test func unmatchedEndIsIgnored() {
    let profiler = ProfilerCore()
    profiler.end()
    profiler.beginFrame(index: 0)
    profiler.begin("a")
    profiler.end()
    profiler.end()
    profiler.endFrame(gpuPasses: [])
    #expect(profiler.frames.first?.events.count == 1)
}

@Test func ringKeepsTheMostRecentFrames() {
    let profiler = ProfilerCore()
    profiler.frameCapacity = 3
    for i in 0..<5 {
        profiler.beginFrame(index: i)
        profiler.begin("work")
        profiler.end()
        profiler.endFrame(gpuPasses: [])
    }
    #expect(profiler.frames.map(\.index) == [2, 3, 4])
    profiler.clear()
    #expect(profiler.frames.isEmpty)
}

@Test func eachThreadHasItsOwnStack() throws {
    let profiler = ProfilerCore()
    profiler.beginFrame(index: 0)
    profiler.begin("main")
    let done = DispatchSemaphore(value: 0)
    Thread.detachNewThread {
        profiler.begin("worker")
        profiler.begin("worker inner")
        profiler.end()
        profiler.end()
        done.signal()
    }
    done.wait()
    profiler.end()
    profiler.endFrame(gpuPasses: [])
    let events = try #require(profiler.frames.first).events
    let byName = Dictionary(uniqueKeysWithValues: events.map { ($0.name, $0) })
    // Swift Testing may run this on a non-main thread, so compare against the worker instead of 0.
    #expect(byName["main"]?.depth == 0)
    #expect(byName["worker"]?.depth == 0)
    #expect(byName["worker inner"]?.depth == 1)
    #expect(byName["worker"]?.thread == byName["worker inner"]?.thread)
    #expect(byName["worker"]?.thread != byName["main"]?.thread)
}

@Test func chromeTraceIsValidJSONWithEscapedNames() throws {
    let profiler = ProfilerCore()
    profiler.beginFrame(index: 1)
    profiler.begin("quote\" back\\slash\nnewline")
    profiler.end()
    profiler.endFrame(gpuPasses: [GPUPassTime(name: "scene", seconds: 0.002), GPUPassTime(name: "bloom", seconds: 0.001)])
    let json = ProfilerCore.chromeTrace(frames: profiler.frames)
    let object = try #require(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
    let events = try #require(object["traceEvents"] as? [[String: Any]])
    let complete = events.filter { $0["ph"] as? String == "X" }
    #expect(complete.contains { $0["name"] as? String == "quote\" back\\slash\nnewline" && $0["cat"] as? String == "cpu" })
    let gpu = complete.filter { $0["cat"] as? String == "gpu" }
    #expect(gpu.count == 2)
    #expect(complete.contains { $0["cat"] as? String == "frame" && $0["name"] as? String == "Frame 1" })
    #expect(complete.allSatisfy { ($0["ts"] as? Double) != nil && ($0["dur"] as? Double) != nil })
    #expect(events.contains { $0["ph"] as? String == "M" && $0["name"] as? String == "thread_name" })
    // GPU passes are laid out back to back.
    let first = gpu[0], second = gpu[1]
    let end = (first["ts"] as? Double ?? 0) + (first["dur"] as? Double ?? 0)
    #expect(abs(end - (second["ts"] as? Double ?? -1)) < 1e-3)
}

@Test func emptyTraceIsStillValid() throws {
    let json = ProfilerCore.chromeTrace(frames: [])
    #expect(try JSONSerialization.jsonObject(with: Data(json.utf8)) is [String: Any])
}

@Test func captureKeepsEveryFrameBeyondTheRing() {
    let profiler = ProfilerCore()
    profiler.frameCapacity = 2
    profiler.startCapture(maxFrames: 100)
    for i in 0..<6 {
        profiler.beginFrame(index: i)
        profiler.begin("work")
        profiler.end()
        profiler.endFrame(gpuPasses: [])
    }
    #expect(profiler.frames.count == 2)
    #expect(profiler.finishCapture().map(\.index) == [0, 1, 2, 3, 4, 5])
}

/// Disabled markers are a flag test; this is the only test that touches the global profiler.
@Test func disabledProfilerRecordsNothingAndIsCheap() {
    Profiler.isEnabled = false
    Profiler.clear()
    nonisolated(unsafe) var sum = 0
    let elapsed = ContinuousClock().measure {
        for i in 0..<1_000_000 {
            Profiler.scope("hot") { sum &+= i }
            Profiler.begin("hot")
            Profiler.end()
        }
    }
    #expect(sum > 0)
    #expect(Profiler.frames.isEmpty)
    #expect(elapsed < .seconds(1), "1M disabled scopes took \(elapsed)")
    Profiler.beginFrame(index: 0)
    Profiler.endFrame()
    #expect(Profiler.frames.isEmpty)
}
