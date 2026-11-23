/// When a system runs within `World.update(dt:)`. Stages run in declaration order; systems
/// within a stage run in registration order (adjustable with `before:` / `after:`).
import EngineCore

public enum SystemStage: Int, CaseIterable, Sendable {
    /// Zero or more times per frame, once per elapsed `fixedTimestep` (physics, gameplay
    /// that must not depend on frame rate). `time.delta` is the fixed step.
    case fixedUpdate
    /// Once per frame with the frame's dt (input handling, animation, AI).
    case update
    /// Once per frame after `.update` (cameras following targets, constraints). Transform
    /// propagation runs right after this stage.
    case lateUpdate
    /// Once per frame after transform propagation: gather what the renderer needs from
    /// final world matrices, interpolating fixed-step state with `time.alpha`.
    case renderPrep
}

/// Timing for the stage being run.
public struct WorldTime: Sendable {
    /// Seconds this stage advances: the fixed step in `.fixedUpdate`, the frame's dt otherwise.
    public package(set) var delta: Float = 0
    /// Sum of all frame dts passed to `update(dt:)`.
    public package(set) var elapsed: Double = 0
    /// Simulated time: fixed steps run so far times their length.
    public package(set) var fixedElapsed: Double = 0
    /// How far the frame is between the last fixed step and the next one, in [0, 1). Render
    /// fixed-step state as `previous + (current - previous) * alpha`.
    public package(set) var alpha: Float = 0
    /// Fixed steps run this frame (so far, while in `.fixedUpdate`).
    public package(set) var fixedStepsThisFrame = 0
    /// Total fixed steps run.
    public package(set) var fixedStepCount = 0
    /// The frame's dt before `World.timeScale` and hit stop (real time: camera shake, UI).
    public package(set) var unscaledDelta: Float = 0
    /// Frames (`update(dt:)` calls) completed before this one.
    public package(set) var frame = 0
    /// Whole fixed steps dropped by `maxFixedStepsPerFrame`, in total.
    public package(set) var droppedFixedSteps = 0
}

struct SystemEntry {
    var name: String
    var run: @MainActor (World) -> Void
}

extension World {
    /// Registers `run` in `stage`, after the stage's existing systems or next to the system
    /// named `before` / `after` (in the same stage; at most one of the two). Names must be
    /// unique within the world.
    public func addSystem(
        _ name: String, stage: SystemStage = .update, before: String? = nil, after: String? = nil,
        _ run: @escaping @MainActor (World) -> Void
    ) {
        precondition(before == nil || after == nil, "Pass before: or after:, not both")
        precondition(systemStage(named: name) == nil, "A system named '\(name)' already exists")
        var list = systems[stage.rawValue]
        var index = list.count
        if let anchor = before ?? after {
            guard let i = list.firstIndex(where: { $0.name == anchor }) else {
                preconditionFailure("No system named '\(anchor)' in \(stage)")
            }
            index = before != nil ? i : i + 1
        }
        list.insert(SystemEntry(name: name, run: run), at: index)
        systems[stage.rawValue] = list
    }

    /// Removes the system named `name`; returns whether there was one.
    @discardableResult
    public func removeSystem(named name: String) -> Bool {
        guard let stage = systemStage(named: name) else { return false }
        systems[stage.rawValue].removeAll { $0.name == name }
        return true
    }

    /// The names of `stage`'s systems, in run order.
    public func systemNames(in stage: SystemStage) -> [String] {
        systems[stage.rawValue].map(\.name)
    }

    private func systemStage(named name: String) -> SystemStage? {
        SystemStage.allCases.first { stage in systems[stage.rawValue].contains { $0.name == name } }
    }

    /// Runs one frame: as many `.fixedUpdate` steps as `dt` (plus leftover time from earlier
    /// frames) covers, up to `maxFixedStepsPerFrame`; then `.update`, `.lateUpdate`,
    /// `propagateTransforms()` and `.renderPrep`. `Engine` calls this after `Game.update` when
    /// `engine.world` is set. With a fixed dt (as in screenshot mode) the step sequence is
    /// deterministic. `dt` is scaled by `timeScale` and any hit stop (`time.unscaledDelta` keeps it).
    public func update(dt realDt: Double) {
        precondition(!isIterating, "World.update can't run inside a query")
        var scale = timeScale
        if hitStopRemaining > 0 {
            scale *= hitStopScale
            hitStopRemaining = max(hitStopRemaining - max(realDt, 0), 0)
        }
        let dt = realDt * scale
        time.unscaledDelta = Float(realDt)
        time.elapsed += dt
        time.fixedStepsThisFrame = 0
        fixedAccumulator += max(dt, 0)
        // Tolerate rounding so e.g. a 1/120 s step runs exactly twice per 1/60 s frame.
        let tolerance = fixedTimestep * 1e-6
        while fixedAccumulator + tolerance >= fixedTimestep {
            if time.fixedStepsThisFrame == maxFixedStepsPerFrame {
                let dropped = (fixedAccumulator / fixedTimestep).rounded(.down)
                time.droppedFixedSteps += Int(dropped)
                fixedAccumulator -= dropped * fixedTimestep
                break
            }
            fixedAccumulator = max(fixedAccumulator - fixedTimestep, 0)
            time.delta = Float(fixedTimestep)
            time.fixedElapsed += fixedTimestep
            time.fixedStepsThisFrame += 1
            time.fixedStepCount += 1
            run(.fixedUpdate)
        }
        time.alpha = min(Float(fixedAccumulator / fixedTimestep), 1)
        time.delta = Float(dt)
        run(.update)
        run(.lateUpdate)
        Profiler.scope("propagateTransforms") { propagateTransforms() }
        run(.renderPrep)
        time.frame += 1
    }

    /// Freezes game time for `seconds` of real time (hit stop: the frame of impact lingers):
    /// dt is multiplied by `scale` (0: frozen) on top of `timeScale` until then. A longer stop
    /// already running wins; the slower scale wins.
    public func hitStop(_ seconds: Double, scale: Double = 0) {
        guard seconds > 0, seconds.isFinite else { return }
        hitStopScale = hitStopRemaining > 0 ? min(hitStopScale, max(scale, 0)) : max(scale, 0)
        hitStopRemaining = max(hitStopRemaining, seconds)
    }

    /// Ends any hit stop and sets `timeScale` back to 1.
    public func resetTimeScale() {
        hitStopRemaining = 0
        timeScale = 1
    }

    /// Runs `stage`'s systems once with the current `time`. `update(dt:)` does this for
    /// every stage; call it directly for custom loops and tests.
    public func run(_ stage: SystemStage) {
        // Iterate a snapshot: systems may add or remove systems.
        let profiling = Profiler.isEnabled
        if profiling { Profiler.begin("stage \(stage)") }
        for system in systems[stage.rawValue] {
            if profiling { Profiler.begin(system.name) }
            system.run(self)
            if profiling { Profiler.end() }
        }
        if profiling { Profiler.end() }
    }
}
