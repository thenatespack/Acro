import EngineAssets
import EngineCore
import EngineMCP
import EngineScene
import Foundation

// Runs playtest steps against a host that plays a scene: the editor's play mode
// (EditorSession), `PlaytestHeadlessHost` (no window) or anything else that can run game frames
// with an `Input`. The driver turns actions and gamepad steps into input events on its own
// timeline (they start at the next frame, independent of `InputPlayer`'s queue), checks
// assertions against the world, collects the results and, while recording, appends every step
// it is given — with the frames the host ran in between — to a `Playtest` that replays the
// session. Hosts call `applyFrameInput(to:)` once per game frame, after `InputPlayer.apply` and
// before the world updates.

/// What a playtest drives: closures over the host's play session.
@MainActor
public struct PlaytestTarget {
    /// The world being played.
    public var world: () -> World
    /// The input game code reads.
    public var input: () -> Input
    /// The scheduler `input` steps go to (`input.inject`'s).
    public var inputPlayer: () -> InputPlayer
    /// Game frames and seconds run so far.
    public var frame: () -> Int
    public var time: () -> Double
    /// The fixed step frames run at by default.
    public var fixedStep: () -> Double
    /// Runs this many frames at `dt` (nil: the fixed step), applying scheduled input and the
    /// driver's (`applyFrameInput`).
    public var runFrames: (Int, Double?) -> Void

    public init(world: @escaping () -> World, input: @escaping () -> Input, inputPlayer: @escaping () -> InputPlayer,
                frame: @escaping () -> Int, time: @escaping () -> Double, fixedStep: @escaping () -> Double,
                runFrames: @escaping (Int, Double?) -> Void) {
        self.world = world
        self.input = input
        self.inputPlayer = inputPlayer
        self.frame = frame
        self.time = time
        self.fixedStep = fixedStep
        self.runFrames = runFrames
    }
}

/// An input action as a playtest sees it: its name and sources, and where it is defined.
public struct PlaytestActionInfo: Codable, Equatable, Sendable {
    public var name: String
    /// Source codes ("key.space", "pad.south", "axis.leftStickX+").
    public var sources: [String]
    /// "playtest" (the playtest's `actions`) or "script" (a visual script graph in the scene).
    public var origin: String
}

/// Runs, checks and records playtest steps; see the notes at the top of this file.
@MainActor
public final class PlaytestDriver {
    public let target: PlaytestTarget
    public var name: String?
    /// Actions beyond the scene's visual scripts' (the playtest's `actions`).
    public var actions: [String: [String]]
    /// Whether steps given to `perform` are appended to `recording`.
    public private(set) var isRecording: Bool
    /// The session so far as a playtest (while recording).
    public private(set) var recording: Playtest
    public private(set) var checks: [PlaytestCheck] = []
    public private(set) var errors: [String] = []
    /// The most frames one `frames` step or replay may run.
    public static let maxFrames = 100_000

    /// The frame the recording has accounted for.
    private var recordedFrame: Int
    /// Input events of actions and the virtual gamepad, by game time.
    private var timeline: [(time: Double, event: TimedEvent)] = []
    private var pad = PadState()

    private enum TimedEvent {
        case input(InputEvent)
        case padButton(GamepadButton, down: Bool)
        case padAxis(GamepadAxis, Float)
    }

    private struct PadState {
        var used = false
        var buttons = Set<GamepadButton>()
        var axes: [GamepadAxis: Float] = [:]

        func snapshot() -> GamepadSnapshot {
            GamepadSnapshot(id: PlaytestDriver.padID, name: "Playtest Pad", buttons: buttons,
                            leftStick: Vec2(axes[.leftStickX] ?? 0, axes[.leftStickY] ?? 0),
                            rightStick: Vec2(axes[.rightStickX] ?? 0, axes[.rightStickY] ?? 0),
                            leftTrigger: axes[.leftTrigger] ?? 0, rightTrigger: axes[.rightTrigger] ?? 0)
        }
    }

    /// The virtual gamepad's id in `Input.gamepads`.
    nonisolated public static let padID = 0x504C_4159

    /// `record`: start recording from the target's current frame (start at frame 0 for a
    /// recording that replays exactly). `scene` is stored in the recording.
    public init(target: PlaytestTarget, name: String? = nil, scene: String? = nil, actions: [String: [String]] = [:],
                record: Bool = false) {
        self.target = target
        self.name = name
        self.actions = actions
        isRecording = record
        recording = Playtest(name: name, scene: scene, actions: actions.isEmpty ? nil : actions)
        recordedFrame = target.frame()
    }

    // MARK: Results

    public var result: PlaytestResult {
        PlaytestResult(name: name, checks: checks, errors: errors, frames: target.frame(), time: target.time(),
                       recording: isRecording, recordedSteps: recording.steps.count)
    }

    /// Stops recording; the recording so far is kept (`recording`).
    public func stopRecording() {
        syncFrames()
        isRecording = false
    }

    /// The recording with the frames run since its last step accounted for.
    public func finishedRecording() -> Playtest {
        syncFrames()
        return recording
    }

    // MARK: Steps

    /// Runs one step (and records it while recording). Returns the check an `assert` step made.
    /// Throws for a step that can't run; the error is also kept in `errors`.
    @discardableResult
    public func perform(_ step: PlaytestStep, index: Int? = nil) throws -> PlaytestCheck? {
        do {
            return try run(step, index: index)
        } catch {
            errors.append((index.map { "step \($0): " } ?? "") + "\(error)")
            throw error
        }
    }

    private func run(_ step: PlaytestStep, index: Int?) throws -> PlaytestCheck? {
        let kinds = [step.frames != nil, step.action != nil, step.gamepad != nil, step.input != nil, step.clearInput == true,
                     step.assert != nil].filter { $0 }.count
        guard kinds <= 1 else {
            throw PlaytestError("a step does one thing: frames, action, gamepad, input, clearInput or assert")
        }
        syncFrames()
        if let frames = step.frames {
            guard (0...Self.maxFrames).contains(frames) else { throw PlaytestError("`frames` must be between 0 and \(Self.maxFrames)") }
            if let dt = step.dt, !(dt > 0 && dt <= 1) { throw PlaytestError("`dt` must be in (0, 1] seconds") }
            target.runFrames(frames, step.dt ?? recording.dt)
            noteFrames(dt: step.dt)
            return nil
        }
        if let name = step.action {
            try press(action: name, down: step.down, duration: step.duration, value: step.value)
        } else if let gamepad = step.gamepad {
            try press(gamepad: gamepad, down: step.down, duration: step.duration)
        } else if let steps = step.input {
            if step.replace == true { clearScheduledInput(keepTimeline: true) }
            do {
                try target.inputPlayer().enqueue(steps)
            } catch {
                throw PlaytestError("input: \(error)")
            }
        } else if step.clearInput == true {
            clearScheduledInput(keepTimeline: false)
        } else if let assertion = step.assert {
            let check = self.check(assertion, step: index)
            record(step)
            return check
        } else if step.note == nil {
            throw PlaytestError("the step does nothing (set frames, action, gamepad, input, clearInput, assert or note)")
        }
        record(step)
        return nil
    }

    /// Runs `playtest`'s steps in order (not recorded) and returns the result. Errors are kept
    /// in the result; the run goes on with the next step.
    public func run(_ playtest: Playtest) -> PlaytestResult {
        if name == nil { name = playtest.name }
        for (name, sources) in playtest.actions ?? [:] { actions[name] = sources }
        let wasRecording = isRecording
        isRecording = false
        recording.dt = playtest.dt
        defer { isRecording = wasRecording }
        guard playtest.frameCount <= Self.maxFrames else {
            errors.append("the playtest runs \(playtest.frameCount) frames; at most \(Self.maxFrames)")
            return result
        }
        for (index, step) in playtest.steps.enumerated() {
            _ = try? perform(step, index: index)
        }
        return result
    }

    /// Records the frames the host ran since the last recorded step (play mode running in
    /// real time, or stepped by other means) as a `frames` step at `dt`.
    public func noteFrames(dt: Double? = nil) {
        let now = target.frame()
        defer { recordedFrame = now }
        guard isRecording, now > recordedFrame else { return }
        let fixed = recording.dt ?? target.fixedStep()
        let stepDT = dt.flatMap { abs($0 - fixed) < 1e-12 ? nil : $0 }
        if stepDT == nil, let last = recording.steps.indices.last, recording.steps[last].frames != nil, recording.steps[last].dt == nil {
            recording.steps[last].frames! += now - recordedFrame
        } else {
            recording.steps.append(.frames(now - recordedFrame, dt: stepDT))
        }
    }

    /// `noteFrames()` before a step that isn't frames.
    public func syncFrames() { noteFrames() }

    /// Appends a step to the recording (while recording) without running it: for steps the host
    /// ran itself (`input.inject`).
    public func record(_ step: PlaytestStep) {
        guard isRecording else { return }
        syncFrames()
        recording.steps.append(step)
    }

    // MARK: Actions and the virtual gamepad

    /// Every action a step can name: the playtest's, then the scene's visual scripts'.
    public var knownActions: [PlaytestActionInfo] {
        var result = actions.keys.sorted().map { PlaytestActionInfo(name: $0, sources: actions[$0]!, origin: "playtest") }
        var seen = Set(actions.keys)
        if let runtime = VisualScriptRuntime.runtime(for: target.world()) {
            for instance in runtime.instances.values.sorted(by: { $0.entity.index < $1.entity.index }) {
                for (name, sources) in instance.program.graph.actions.sorted(by: { $0.key < $1.key }) where !seen.contains(name) {
                    seen.insert(name)
                    result.append(PlaytestActionInfo(name: name, sources: sources, origin: "script"))
                }
            }
        }
        return result
    }

    /// The sources of the action `name`.
    public func sources(ofAction name: String) throws -> [InputSource] {
        guard let info = knownActions.first(where: { $0.name == name }) else {
            let names = knownActions.map(\.name)
            throw PlaytestError("no input action '\(name)'" + (names.isEmpty
                ? " (the scene's visual scripts define none yet: step a frame first, or give the playtest `actions`)"
                : "; known: \(names.joined(separator: ", "))"))
        }
        let sources = info.sources.compactMap(Self.source(code:))
        guard !sources.isEmpty else { throw PlaytestError("input action '\(name)' has no usable sources (\(info.sources))") }
        return sources
    }

    static func source(code: String) -> InputSource? {
        guard let data = try? JSONEncoder().encode(code) else { return nil }
        return try? JSONDecoder().decode(InputSource.self, from: data)
    }

    static func code(of source: InputSource) -> String {
        (try? JSONEncoder().encode(source)).flatMap { try? JSONDecoder().decode(String.self, from: $0) } ?? "\(source)"
    }

    /// Presses the action `name` from the next frame (see `PlaytestStep.action`). Returns the source it used.
    @discardableResult
    public func press(action name: String, down: Bool? = nil, duration: Double? = nil, value: Double? = nil) throws -> String {
        try checkTimes(duration: duration, value: value)
        let sources = try sources(ofAction: name)
        if let value {
            if let axisSource = sources.first(where: { if case .gamepadAxis = $0 { true } else { false } }),
               case .gamepadAxis(let axis, let side) = axisSource {
                let magnitude = Float(value)
                let set: Float = switch side {
                case .full: magnitude
                case .positive: abs(magnitude)
                case .negative: -abs(magnitude)
                }
                schedule(press: .padAxis(axis, set), release: .padAxis(axis, 0), down: down, duration: duration)
                return Self.code(of: axisSource)
            }
            guard abs(value) >= 0.5 else {
                // A key or button below the press threshold: released.
                if let source = sources.first, let pair = Self.events(for: source) { schedule(at: target.time(), pair.1) }
                return sources.first.map(Self.code(of:)) ?? name
            }
        }
        let preferred = sources.first { if case .key = $0 { true } else { false } }
            ?? sources.first { if case .mouseButton = $0 { true } else { false } }
            ?? sources.first { if case .gamepadButton = $0 { true } else { false } }
            ?? sources[0]
        guard let pair = Self.events(for: preferred) else { throw PlaytestError("can't press \(preferred)") }
        schedule(press: pair.0, release: pair.1, down: down, duration: duration)
        return Self.code(of: preferred)
    }

    /// Drives the virtual gamepad from the next frame (see `PlaytestGamepadInput`).
    public func press(gamepad: PlaytestGamepadInput, down: Bool? = nil, duration: Double? = nil) throws {
        try checkTimes(duration: duration, value: gamepad.value)
        switch (gamepad.button, gamepad.axis) {
        case (let button?, nil):
            schedule(press: .padButton(button, down: true), release: .padButton(button, down: false), down: down, duration: duration)
        case (nil, let axis?):
            guard let value = gamepad.value else { throw PlaytestError("gamepad: an `axis` needs a `value`") }
            let range: ClosedRange<Double> = axis == .leftTrigger || axis == .rightTrigger ? 0...1 : -1...1
            guard range.contains(value) else { throw PlaytestError("gamepad: \(axis.rawValue) takes \(range.lowerBound)…\(range.upperBound)") }
            if let duration, down == nil {
                schedule(at: target.time(), .padAxis(axis, Float(value)))
                schedule(at: target.time() + duration, .padAxis(axis, 0))
            } else {
                schedule(at: target.time(), .padAxis(axis, down == false ? 0 : Float(value)))
            }
        default:
            throw PlaytestError("gamepad: give a `button` or an `axis` with a `value`")
        }
    }

    private func checkTimes(duration: Double?, value: Double?) throws {
        if let duration, !(duration >= 0 && duration.isFinite) { throw PlaytestError("`duration` must be finite and not negative") }
        if let value, !(-1...1).contains(value) { throw PlaytestError("`value` must be between -1 and 1") }
    }

    private static func events(for source: InputSource) -> (TimedEvent, TimedEvent)? {
        switch source {
        case .key(let key): (.input(.key(key, down: true)), .input(.key(key, down: false)))
        case .mouseButton(let button): (.input(.button(button, down: true)), .input(.button(button, down: false)))
        case .gamepadButton(let button): (.padButton(button, down: true), .padButton(button, down: false))
        case .gamepadAxis(let axis, let side):
            (.padAxis(axis, side == .negative ? -1 : 1), .padAxis(axis, 0))
        }
    }

    private func schedule(press: TimedEvent, release: TimedEvent, down: Bool?, duration: Double?) {
        let now = target.time()
        switch down {
        case true?: schedule(at: now, press)
        case false?: schedule(at: now, release)
        case nil:
            schedule(at: now, press)
            schedule(at: now + (duration ?? 0), release)
        }
    }

    private func schedule(at time: Double, _ event: TimedEvent) {
        // After every event at the same time or earlier: same-time events keep their order.
        let index = timeline.firstIndex { $0.time > time + 1e-9 } ?? timeline.endIndex
        timeline.insert((time, event), at: index)
    }

    /// Drops scheduled input (this driver's and `InputPlayer`'s) and releases what injected
    /// input and the virtual gamepad hold. `keepTimeline`: only `InputPlayer`'s queue (what
    /// `input.inject`'s `replace` drops).
    public func clearScheduledInput(keepTimeline: Bool = false) {
        target.inputPlayer().clear()
        target.input().releaseInjected()
        guard !keepTimeline else { return }
        timeline.removeAll()
        if pad.used {
            pad.buttons.removeAll()
            pad.axes.removeAll()
        }
    }

    /// Forgets scheduled input without touching the target (play mode stopped).
    public func discardScheduledInput() {
        timeline.removeAll()
        pad = PadState()
    }

    /// Whether actions or the virtual gamepad still have input scheduled.
    public var pendingInput: Int { timeline.count }

    /// Applies the input due this frame: call once per game frame, after `InputPlayer.apply`
    /// and before the world updates. A release of something pressed in this same call waits for
    /// the next frame, so a tap is down for exactly one frame.
    public func applyFrameInput(to input: Input) {
        let now = target.time()
        var pressedNow = Set<String>()
        var applied = 0
        loop: for item in timeline {
            guard item.time <= now + 1e-9 else { break }
            switch item.event {
            case .input(.key(let key, down: false)) where pressedNow.contains("k" + key.rawValue): break loop
            case .input(.button(let button, down: false)) where pressedNow.contains("b" + button.rawValue): break loop
            case .padButton(let button, down: false) where pressedNow.contains("p" + button.rawValue): break loop
            case .input(let event):
                switch event {
                case .key(let key, down: true): pressedNow.insert("k" + key.rawValue)
                case .button(let button, down: true): pressedNow.insert("b" + button.rawValue)
                default: break
                }
                input.inject(event)
            case .padButton(let button, let down):
                pad.used = true
                if down {
                    pad.buttons.insert(button)
                    pressedNow.insert("p" + button.rawValue)
                } else {
                    pad.buttons.remove(button)
                }
            case .padAxis(let axis, let value):
                pad.used = true
                pad.axes[axis] = value
            }
            applied += 1
        }
        timeline.removeFirst(applied)
        if pad.used { input.updateGamepads([pad.snapshot()]) }
    }

    // MARK: Assertions

    /// Checks `assertion` against the world now and keeps the result (recorded while recording).
    @discardableResult
    public func check(_ assertion: PlaytestAssertion, step: Int? = nil) -> PlaytestCheck {
        let (passed, message, actual) = Self.evaluate(assertion, in: target.world())
        let check = PlaytestCheck(label: assertion.label ?? Self.describe(assertion), passed: passed, message: message,
                                  actual: actual, frame: target.frame(), time: target.time(), step: step)
        checks.append(check)
        return check
    }

    /// A short description of what `assertion` checks.
    public static func describe(_ a: PlaytestAssertion) -> String {
        var subject: String
        if let count = a.count {
            subject = "count of " + ([count.name.map { "'\($0)'" }, count.component].compactMap { $0 }.joined(separator: " with ")
                                     .nonEmpty ?? "entities")
        } else {
            subject = a.entity.map { "'\($0)'" } ?? "?"
            if let variable = a.variable { subject += " variable \(variable)" }
            if let component = a.component { subject += " \(component)" }
            if let field = a.field { subject += (a.component == nil ? " world " : ".") + field }
        }
        var tests: [String] = []
        if let exists = a.exists { tests.append(exists ? "exists" : "doesn't exist") }
        if let equals = a.equals { tests.append("== \(equals.text)") }
        if let min = a.min { tests.append(">= \(Self.number(min))") }
        if let max = a.max { tests.append("<= \(Self.number(max))") }
        if let near = a.near { tests.append("near [\(near.map(Self.number).joined(separator: ", "))] ± \(Self.number(a.tolerance ?? 0.01))") }
        return subject + " " + (tests.isEmpty ? "exists" : tests.joined(separator: ", "))
    }

    private static func number(_ value: Double) -> String {
        value == value.rounded() && abs(value) < 1e15 ? String(Int64(value)) : String(value)
    }

    /// Evaluates `assertion`: whether it holds, a message, and the value it looked at.
    public static func evaluate(_ a: PlaytestAssertion, in world: World) -> (Bool, String, JSON?) {
        if let count = a.count {
            let entities = world.entities.filter { entity in
                if let name = count.name, world.get(Name.self, for: entity)?.value != name { return false }
                if let component = count.component, world.component(named: component, of: entity) == nil { return false }
                return true
            }
            return compare(.int(Int64(entities.count)), a, what: "count")
        }
        guard let reference = a.entity else { return (false, "give `entity` or `count`", nil) }
        let entity = findEntity(reference, in: world)
        let wantsValue = a.component != nil || a.field != nil || a.variable != nil
        guard let entity else {
            if a.exists == false && !wantsValue { return (true, "no entity '\(reference)'", nil) }
            return (false, "no entity '\(reference)'", nil)
        }
        guard wantsValue else {
            if a.exists == false { return (false, "'\(reference)' exists", nil) }
            return (true, "'\(reference)' exists", nil)
        }
        let value: JSON?
        let what: String
        if let variable = a.variable {
            what = "variable \(variable)"
            value = VisualScriptRuntime.runtime(for: world)?.variable(variable, of: entity).flatMap { try? JSON(encoding: $0.json) }
        } else if let component = a.component {
            guard let found = world.component(named: component, of: entity) else {
                return a.exists == false ? (true, "no \(component)", nil) : (false, "'\(reference)' has no \(component)", nil)
            }
            let json = (try? JSON(encoding: found)) ?? .null
            what = a.field.map { "\(component).\($0)" } ?? component
            value = a.field.map { lookup($0, in: json) } ?? json
        } else {
            let transform = Transform(matrix: world.worldMatrix(of: entity))
            let json: JSON = ["position": vector([transform.position.x, transform.position.y, transform.position.z]),
                              "rotation": vector([transform.rotation.x, transform.rotation.y, transform.rotation.z, transform.rotation.w]),
                              "scale": vector([transform.scale.x, transform.scale.y, transform.scale.z])]
            what = "world \(a.field!)"
            value = lookup(a.field!, in: json)
        }
        guard let value else {
            return a.exists == false ? (true, "no \(what)", nil) : (false, "'\(reference)' has no \(what)", nil)
        }
        return compare(value, a, what: what)
    }

    private static func vector(_ values: [Float]) -> JSON { .array(values.map { .double(Double($0)) }) }

    /// The value at a dotted path: object keys, array indices, and x / y / z / w for indices 0…3.
    static func lookup(_ path: String, in json: JSON) -> JSON? {
        var current = json
        for key in path.split(separator: ".").map(String.init) {
            switch current {
            case .object(let members):
                guard let next = members[key] else { return nil }
                current = next
            case .array(let items):
                let index = Int(key) ?? ["x": 0, "y": 1, "z": 2, "w": 3, "r": 0, "g": 1, "b": 2, "a": 3][key]
                guard let index, items.indices.contains(index) else { return nil }
                current = items[index]
            default:
                return nil
            }
        }
        return current
    }

    private static func compare(_ value: JSON, _ a: PlaytestAssertion, what: String) -> (Bool, String, JSON?) {
        var failures: [String] = []
        if a.exists == false { failures.append("\(what) exists") }
        if let expected = a.equals, !equal(value, expected, tolerance: a.tolerance ?? 1e-4) {
            failures.append("\(what) is \(value.text), expected \(expected.text)")
        }
        if a.min != nil || a.max != nil {
            if let number = value.doubleValue {
                if let min = a.min, number < min { failures.append("\(what) is \(number), below \(Self.number(min))") }
                if let max = a.max, number > max { failures.append("\(what) is \(number), above \(Self.number(max))") }
            } else {
                failures.append("\(what) is \(value.text), not a number")
            }
        }
        if let near = a.near {
            let tolerance = a.tolerance ?? 0.01
            let numbers = value.doubleValue.map { [$0] } ?? value.arrayValue?.compactMap(\.doubleValue) ?? []
            if numbers.count != near.count {
                failures.append("\(what) is \(value.text), not \(near.count == 1 ? "a number" : "\(near.count) numbers")")
            } else {
                let distance = zip(numbers, near).reduce(0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }.squareRoot()
                if distance > tolerance {
                    failures.append("\(what) is \(value.text), \(String(format: "%.4g", distance)) from [\(near.map(Self.number).joined(separator: ", "))] (tolerance \(Self.number(tolerance)))")
                }
            }
        }
        return failures.isEmpty ? (true, "\(what) is \(value.text)", value) : (false, failures.joined(separator: "; "), value)
    }

    private static func equal(_ a: JSON, _ b: JSON, tolerance: Double) -> Bool {
        if let x = a.doubleValue, let y = b.doubleValue { return abs(x - y) <= tolerance }
        switch (a, b) {
        case (.array(let xs), .array(let ys)):
            return xs.count == ys.count && zip(xs, ys).allSatisfy { equal($0, $1, tolerance: tolerance) }
        case (.object(let xs), .object(let ys)):
            return xs.keys.sorted() == ys.keys.sorted() && xs.allSatisfy { key, value in equal(value, ys[key]!, tolerance: tolerance) }
        default:
            return a == b
        }
    }

    /// The entity `reference` names: an id (32 hex digits or "<index>v<generation>"), a path
    /// of names ("Level/Door"), or a name (exact first, then any case), in hierarchy order.
    public static func findEntity(_ reference: String, in world: World) -> Entity? {
        if let id = EntityID(reference), let entity = world.entity(for: id) { return entity }
        let parts = reference.split(separator: "v")
        if parts.count == 2, let index = UInt32(parts[0]), let generation = UInt32(parts[1]) {
            let entity = Entity(index: index, generation: generation)
            if world.isAlive(entity) { return entity }
        }
        func name(_ entity: Entity) -> String? { world.get(Name.self, for: entity)?.value }
        if reference.contains("/") {
            var candidates = world.roots
            var found: Entity?
            for part in reference.split(separator: "/").map(String.init) {
                guard let next = candidates.first(where: { name($0) == part }) else { return nil }
                found = next
                candidates = world.children(of: next)
            }
            return found
        }
        var ordered: [Entity] = []
        func visit(_ entity: Entity) {
            ordered.append(entity)
            for child in world.children(of: entity) { visit(child) }
        }
        for root in world.roots { visit(root) }
        return ordered.first { name($0) == reference } ?? ordered.first { name($0)?.lowercased() == reference.lowercased() }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
