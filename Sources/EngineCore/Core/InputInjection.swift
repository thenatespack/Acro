// Synthetic input: tests and AI playtesters drive a game through the same `Input` the window
// fills, so game code can't tell the difference.
//
// ```swift
// engine.inputPlayer.enqueue([
//     InputStep(key: .w, duration: 2),           // hold W for two seconds
//     InputStep(key: .space),                    // then tap Space (down, up the next frame)
//     InputStep(mouseTo: Vec2(400, 300)), InputStep(button: .left),
// ])
// ```
//
// `Input.inject(_:)` applies one `InputEvent` right away, as if the platform reported it this
// frame. A key or button pressed that way stays down until an injected release, even though the
// window reports it up every frame (GLFW polls key state), and an injected cursor position stays
// until `releaseInjected()`. `InputPlayer` runs scripts of `InputStep`s over game time: each
// frame, `apply(to:)` injects the events that are due, then `advance(by:)` moves its clock by
// the frame's (scaled) dt. Steps run one after another; a step's `wait` (default its
// `duration`) is how long until the next one starts, so `wait: 0` overlaps them (hold W and D).
// A release due in the frame its press happened waits for the next frame, so a tap is seen
// down for exactly one frame. With a fixed dt (stepping) the frames each event lands in are
// deterministic.

/// One synthetic input event (`Input.inject`).
public enum InputEvent: Equatable, Sendable {
    case key(Key, down: Bool)
    case button(MouseButton, down: Bool)
    /// The cursor moves to a position in window points (top-left origin); the move counts in
    /// `mouseDelta` (as raw motion while the mouse is captured).
    case mouseMove(to: Vec2)
    /// The mouse moves by a delta in points (y down), for fly cameras with the mouse captured.
    case mouseMotion(by: Vec2)
    case scroll(Vec2)
    /// Typed text. Like real typing it reaches `textEvents` only while text input is active.
    case text(String)
}

extension Input {
    /// Applies `event` now, as if the window reported it this frame (see the notes above).
    public func inject(_ event: InputEvent) {
        switch event {
        case .key(let key, let down):
            if down {
                injectedKeys.insert(key)
                setKey(key, down: true)
                recordKeyPress(key, modifiers: modifiers, isRepeat: false)
                textKeyEvent(key, modifiers: modifiers, isRepeat: false)
            } else {
                injectedKeys.remove(key)
                setKey(key, down: false)
            }
        case .button(let button, let down):
            if down {
                injectedButtons.insert(button)
            } else {
                injectedButtons.remove(button)
            }
            setButton(button, down: down)
        case .mouseMove(let position):
            let from = injectedPointer ?? mousePosition
            injectedPointer = position
            mousePosition = position
            addMouseMotion(position - from)
        case .mouseMotion(let delta):
            addMouseMotion(delta)
            if !isMouseCaptured {
                injectedPointer = (injectedPointer ?? mousePosition) + delta
                mousePosition = injectedPointer!
            }
        case .scroll(let delta):
            addScroll(delta)
        case .text(let text):
            commitText(text)
        }
    }

    /// Releases every key and button injected events hold and gives the cursor back to the
    /// platform.
    public func releaseInjected() {
        for key in injectedKeys.sorted(by: { $0.rawValue < $1.rawValue }) { inject(.key(key, down: false)) }
        for button in injectedButtons.sorted(by: { $0.rawValue < $1.rawValue }) { inject(.button(button, down: false)) }
        injectedPointer = nil
    }

    /// The keys and buttons injected events hold down now.
    public var injectedHeldKeys: Set<Key> { injectedKeys }
    public var injectedHeldButtons: Set<MouseButton> { injectedButtons }

    /// Releases everything, injected or not (play mode starting or stopping).
    public func reset() {
        releaseInjected()
        releaseAll()
        stopTextInput()
    }
}

/// One step of an input script (`InputPlayer.enqueue`, the `input.inject` tool). Set one kind
/// of action; `wait` says how long until the next step starts.
public struct InputStep: Codable, Equatable, Sendable {
    /// A key ("w", "space", "leftShift", "num1", "up"…), or several pressed together (`keys`).
    public var key: Key?
    public var keys: [Key]?
    /// A mouse button ("left", "right", "middle").
    public var button: MouseButton?
    /// For keys and buttons: true presses and keeps it down, false releases it; nil taps it
    /// (down for one frame), or holds it for `duration`.
    public var down: Bool?
    /// Seconds a key or button is held before it is released.
    public var duration: Double?
    /// Moves the cursor to this position in window points ([x, y], top-left origin; in the
    /// editor, relative to the game view).
    public var mouseTo: Vec2?
    /// Moves the mouse by this delta in points ([dx, dy], y down).
    public var mouseBy: Vec2?
    /// Scrolls by [dx, dy] points (positive y scrolls up).
    public var scroll: Vec2?
    /// Types text (reaches the game only while it has text input active).
    public var text: String?
    /// Seconds from this step's start to the next step's (default: `duration`, else 0, the
    /// same frame).
    public var wait: Double?

    public init(key: Key? = nil, keys: [Key]? = nil, button: MouseButton? = nil, down: Bool? = nil, duration: Double? = nil,
                mouseTo: Vec2? = nil, mouseBy: Vec2? = nil, scroll: Vec2? = nil, text: String? = nil, wait: Double? = nil) {
        self.key = key
        self.keys = keys
        self.button = button
        self.down = down
        self.duration = duration
        self.mouseTo = mouseTo
        self.mouseBy = mouseBy
        self.scroll = scroll
        self.text = text
        self.wait = wait
    }

    /// A pause of `seconds` between steps.
    public static func wait(_ seconds: Double) -> InputStep { InputStep(wait: seconds) }
}

/// Plays `InputStep` scripts into an `Input` over game time; see the notes at the top of this file.
@MainActor
public final class InputPlayer {
    private struct Scheduled {
        var time: Double
        var event: InputEvent
    }

    /// Events not applied yet, by time (ties in the order they were scheduled).
    private var queue: [Scheduled] = []
    /// Seconds of game time this player has advanced.
    public private(set) var time: Double = 0
    /// When the last enqueued step's wait ends: the next enqueued script starts there (or now).
    private var scriptEnd: Double = 0

    public init() {}

    /// Events still to inject.
    public var pendingCount: Int { queue.count }
    public var isIdle: Bool { queue.isEmpty }
    /// Seconds of game time until the last scheduled event (0 when idle).
    public var remaining: Double { max((queue.last?.time ?? time) - time, 0) }

    /// Schedules `steps` after what is already queued (or from now). Returns the seconds of
    /// game time until they are done. Throws for a step without an action or with a bad time.
    @discardableResult
    public func enqueue(_ steps: [InputStep]) throws -> Double {
        var t = max(scriptEnd, time)
        var added: [Scheduled] = []
        for (index, step) in steps.enumerated() {
            for value in [step.duration, step.wait].compactMap({ $0 }) where !(value >= 0 && value.isFinite) {
                throw InputScriptError("step \(index): times must be finite and not negative")
            }
            let keys = (step.key.map { [$0] } ?? []) + (step.keys ?? [])
            var events: [(InputEvent, InputEvent?)] = keys.map { (.key($0, down: true), .key($0, down: false)) }
            if let button = step.button { events.append((.button(button, down: true), .button(button, down: false))) }
            var scheduledAny = false
            for (press, release) in events {
                switch step.down {
                case true?: added.append(Scheduled(time: t, event: press))
                case false?: added.append(Scheduled(time: t, event: release!))
                case nil:
                    added.append(Scheduled(time: t, event: press))
                    added.append(Scheduled(time: t + (step.duration ?? 0), event: release!))
                }
                scheduledAny = true
            }
            if let position = step.mouseTo { added.append(Scheduled(time: t, event: .mouseMove(to: position))); scheduledAny = true }
            if let delta = step.mouseBy { added.append(Scheduled(time: t, event: .mouseMotion(by: delta))); scheduledAny = true }
            if let delta = step.scroll { added.append(Scheduled(time: t, event: .scroll(delta))); scheduledAny = true }
            if let text = step.text { added.append(Scheduled(time: t, event: .text(text))); scheduledAny = true }
            if !scheduledAny && step.wait == nil && step.duration == nil {
                throw InputScriptError("step \(index) does nothing (set key, keys, button, mouseTo, mouseBy, scroll, text or wait)")
            }
            t += step.wait ?? step.duration ?? 0
        }
        scriptEnd = t
        // A stable merge by time keeps same-time events in scheduling order.
        queue = (queue + added).enumerated().sorted { a, b in
            a.element.time != b.element.time ? a.element.time < b.element.time : a.offset < b.offset
        }.map(\.element)
        return max(t, queue.last?.time ?? t) - time
    }

    /// Drops everything scheduled (what is held stays held: `Input.releaseInjected()` lets go).
    public func clear() {
        queue.removeAll()
        scriptEnd = time
    }

    /// Injects the events due by now into `input`. A release of something pressed in this same
    /// call, and everything after it, waits for the next frame.
    public func apply(to input: Input) {
        var pressedNow = Set<String>()
        var count = 0
        for item in queue {
            guard item.time <= time + 1e-9 else { break }
            switch item.event {
            case .key(let key, down: false) where pressedNow.contains("k" + key.rawValue):
                queue.removeFirst(count)
                return
            case .button(let button, down: false) where pressedNow.contains("b" + button.rawValue):
                queue.removeFirst(count)
                return
            case .key(let key, down: true): pressedNow.insert("k" + key.rawValue)
            case .button(let button, down: true): pressedNow.insert("b" + button.rawValue)
            default: break
            }
            input.inject(item.event)
            count += 1
        }
        queue.removeFirst(count)
    }

    /// Moves the clock by a frame's game time (after the frame ran).
    public func advance(by dt: Double) {
        time += max(dt, 0)
    }
}

public struct InputScriptError: Error, CustomStringConvertible, Sendable {
    public var description: String
    public init(_ description: String) { self.description = description }
}
