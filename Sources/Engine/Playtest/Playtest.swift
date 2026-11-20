import EngineCore
import EngineMCP
import Foundation

// Agent playtesting: a playtest is a script of what a player does and what should then be true,
// stored as JSON so it can be committed and run in CI. The same steps are what an agent sends
// one by one over MCP (the editor's `playtest.*` and `input.action` tools, or GameRunner's
// headless MCP server), and what a recording of such a session holds, so a recording replays
// with its assertions checked again.
//
// ```json
// {
//   "format": "Acro.Playtest", "version": 1,
//   "name": "Player walks right and jumps",
//   "scene": "Scenes/Main.scene",
//   "steps": [
//     {"frames": 1},
//     {"assert": {"entity": "Player", "exists": true}},
//     {"action": "right", "duration": 1},
//     {"action": "jump"},
//     {"frames": 75},
//     {"assert": {"label": "walked right", "entity": "Player", "field": "position.x", "min": 1.5}},
//     {"assert": {"entity": "Player", "variable": "jumps", "equals": 1}}
//   ]
// }
// ```
//
// Steps run in order. `frames` runs game frames at a fixed dt (deterministic: the same scene and
// steps give the same world); every other step happens between frames. Input steps start at the
// next frame: `action` presses an input action by name (resolved through the playtest's
// `actions` and the scene's visual scripts' actions), `gamepad` drives a virtual gamepad's
// buttons and axes, and `input` schedules raw keyboard / mouse steps exactly like
// `input.inject` (after input already scheduled that way). `assert` checks the world and
// records a pass or a failure; a playtest passes when no assertion failed and no step errored.
// Runners: `PlaytestDriver` (any host), `PlaytestHeadlessHost` (no window, GameRunner
// `--playtest`) and the editor's play mode (`playtest.run`).

/// A playtest script or recording; see the notes at the top of this file.
public struct Playtest: Codable, Equatable, Sendable {
    /// The `format` value of playtest files.
    public static let formatName = "Acro.Playtest"
    /// The file name suffix playtests are saved with.
    public static let fileSuffix = ".playtest.json"

    /// "Acro.Playtest".
    public var format: String
    public var version: Int
    public var name: String?
    /// The scene it plays: a path under the project's `Assets/` ("Scenes/Main.scene"), relative
    /// to the file's folder, or absolute. Runners that are given a scene ignore it.
    public var scene: String?
    /// Seconds per frame for `frames` steps without their own `dt` (default the world's fixed
    /// step, 1/60).
    public var dt: Double?
    /// Input actions beyond the scene's visual scripts': name → sources, as visual script
    /// graphs list them ("key.space", "mouse.left", "pad.south", "axis.leftStickX",
    /// "axis.leftTrigger+", "axis.leftStickX-").
    public var actions: [String: [String]]?
    public var steps: [PlaytestStep]

    public init(name: String? = nil, scene: String? = nil, dt: Double? = nil, actions: [String: [String]]? = nil,
                steps: [PlaytestStep] = []) {
        format = Self.formatName
        version = 1
        self.name = name
        self.scene = scene
        self.dt = dt
        self.actions = actions
        self.steps = steps
    }

    private enum CodingKeys: String, CodingKey { case format, version, name, scene, dt, actions, steps }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        format = try c.decodeIfPresent(String.self, forKey: .format) ?? Self.formatName
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        name = try c.decodeIfPresent(String.self, forKey: .name)
        scene = try c.decodeIfPresent(String.self, forKey: .scene)
        dt = try c.decodeIfPresent(Double.self, forKey: .dt)
        actions = try c.decodeIfPresent([String: [String]].self, forKey: .actions)
        steps = try c.decodeIfPresent([PlaytestStep].self, forKey: .steps) ?? []
    }

    /// Reads a playtest file. Throws when it isn't one (another `format`, a newer `version`).
    public init(contentsOf url: URL) throws {
        try self.init(json: Data(contentsOf: url))
    }

    public init(json data: Data) throws {
        self = try JSONDecoder().decode(Playtest.self, from: data)
        guard format == Self.formatName else { throw PlaytestError("Not a playtest (format \"\(format)\", expected \"\(Self.formatName)\")") }
        guard version <= 1 else { throw PlaytestError("Playtest version \(version) is newer than this engine reads (1)") }
    }

    /// Pretty-printed JSON with sorted keys, one step per line where it fits, for diffs.
    public func json() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }

    /// Frames the `frames` steps run in total.
    public var frameCount: Int { steps.reduce(0) { $0 + max($1.frames ?? 0, 0) } }
    /// The number of assertions.
    public var assertionCount: Int { steps.filter { $0.assert != nil }.count }
}

/// One step of a playtest. Set one kind of step: `frames`, `action`, `gamepad`, `input`,
/// `clearInput`, `assert` or `note`.
public struct PlaytestStep: Codable, Equatable, Sendable {
    /// Runs this many game frames (each `dt` seconds, default the playtest's).
    public var frames: Int?
    public var dt: Double?
    /// Presses the input action with this name: tapped (down one frame), held `duration`
    /// seconds, pressed (`down` true) or released (false). With `value` (-1…1) an analog source
    /// (a gamepad axis) is set to it instead; a key or button takes it as pressed when |value| ≥ 0.5.
    public var action: String?
    /// For `action` and `gamepad`: true presses and keeps it down, false releases it; nil taps
    /// or holds for `duration`.
    public var down: Bool?
    /// Seconds it is held (default: a tap, one frame).
    public var duration: Double?
    public var value: Double?
    /// The virtual gamepad: a `button` tapped / held / pressed, or an `axis` set to `value`.
    public var gamepad: PlaytestGamepadInput?
    /// Raw keyboard and mouse input, scheduled like `input.inject` (after input already
    /// scheduled that way; `replace` drops that first).
    public var input: [InputStep]?
    public var replace: Bool?
    /// Drops every scheduled input and releases everything held (`input.clear`).
    public var clearInput: Bool?
    /// Checks the world now.
    public var assert: PlaytestAssertion?
    /// A comment, kept in the file and skipped when run.
    public var note: String?

    public init(frames: Int? = nil, dt: Double? = nil, action: String? = nil, down: Bool? = nil, duration: Double? = nil,
                value: Double? = nil, gamepad: PlaytestGamepadInput? = nil, input: [InputStep]? = nil, replace: Bool? = nil,
                clearInput: Bool? = nil, assert: PlaytestAssertion? = nil, note: String? = nil) {
        self.frames = frames
        self.dt = dt
        self.action = action
        self.down = down
        self.duration = duration
        self.value = value
        self.gamepad = gamepad
        self.input = input
        self.replace = replace
        self.clearInput = clearInput
        self.assert = assert
        self.note = note
    }

    public static func frames(_ count: Int, dt: Double? = nil) -> PlaytestStep { PlaytestStep(frames: count, dt: dt) }
    public static func action(_ name: String, down: Bool? = nil, duration: Double? = nil, value: Double? = nil) -> PlaytestStep {
        PlaytestStep(action: name, down: down, duration: duration, value: value)
    }
    public static func assert(_ assertion: PlaytestAssertion) -> PlaytestStep { PlaytestStep(assert: assertion) }
}

/// Input for the virtual gamepad a playtest drives (`Input.gamepads`, as "Playtest Pad").
public struct PlaytestGamepadInput: Codable, Equatable, Sendable {
    /// A button ("south", "east", "dpadUp", "start"…), tapped, held for the step's `duration` or
    /// pressed / released (`down`).
    public var button: GamepadButton?
    /// An axis ("leftStickX", "leftStickY", "rightStickX", "rightStickY", "leftTrigger",
    /// "rightTrigger") set to `value` (sticks -1…1, triggers 0…1), before the game's deadzone;
    /// for the step's `duration`, else until set again.
    public var axis: GamepadAxis?
    public var value: Double?

    public init(button: GamepadButton? = nil, axis: GamepadAxis? = nil, value: Double? = nil) {
        self.button = button
        self.axis = axis
        self.value = value
    }
}

/// What to count for a `count` assertion: entities with this exact `name` and / or this `component`.
public struct PlaytestCountQuery: Codable, Equatable, Sendable {
    public var name: String?
    public var component: String?

    public init(name: String? = nil, component: String? = nil) {
        self.name = name
        self.component = component
    }
}

/// A check of the world. Pick the value — an entity (`exists`), a `component` and its `field`, a
/// visual script `variable`, the entity's world transform (`field` "position", "rotation",
/// "scale", or one coordinate: "position.x"), or a `count` of entities — then compare it:
/// `exists`, `equals`, `min` / `max`, or `near` (within `tolerance`). Without a comparison it
/// checks that the value exists.
public struct PlaytestAssertion: Codable, Equatable, Sendable {
    /// What the result calls it (default: a description of the check).
    public var label: String?
    /// The entity: its name (exact; else any case), a path of names ("Level/Door"), or its id.
    public var entity: String?
    /// A component of the entity (its registered name: "Transform", "RigidBody", "Bobber").
    public var component: String?
    /// A dotted path into the component's fields as `entity.get` shows them ("position.x",
    /// "position.1", "linearVelocity"); without `component`, the world transform's
    /// "position", "rotation" or "scale" (with ".x"…).
    public var field: String?
    /// A visual script variable of the entity.
    public var variable: String?
    /// Counts entities instead (compare with `equals`, `min`, `max`).
    public var count: PlaytestCountQuery?
    /// Whether the entity (or its component, or the variable) exists.
    public var exists: Bool?
    /// The value equals this (numbers compare within `tolerance`, default 1e-4).
    public var equals: JSON?
    /// A number at least / at most this.
    public var min: Double?
    public var max: Double?
    /// A number or vector within `tolerance` (default 0.01) of this, by distance.
    public var near: [Double]?
    public var tolerance: Double?

    public init(label: String? = nil, entity: String? = nil, component: String? = nil, field: String? = nil, variable: String? = nil,
                count: PlaytestCountQuery? = nil, exists: Bool? = nil, equals: JSON? = nil, min: Double? = nil, max: Double? = nil,
                near: [Double]? = nil, tolerance: Double? = nil) {
        self.label = label
        self.entity = entity
        self.component = component
        self.field = field
        self.variable = variable
        self.count = count
        self.exists = exists
        self.equals = equals
        self.min = min
        self.max = max
        self.near = near
        self.tolerance = tolerance
    }
}

/// One assertion's outcome.
public struct PlaytestCheck: Codable, Equatable, Sendable {
    public var label: String
    public var passed: Bool
    /// Why it failed, or what it saw.
    public var message: String
    /// The value checked, when there was one.
    public var actual: JSON?
    /// The game frame and time it was checked at.
    public var frame: Int
    public var time: Double
    /// The index of the step in the playtest (replays and recordings).
    public var step: Int?

    public init(label: String, passed: Bool, message: String, actual: JSON? = nil, frame: Int, time: Double, step: Int? = nil) {
        self.label = label
        self.passed = passed
        self.message = message
        self.actual = actual
        self.frame = frame
        self.time = time
        self.step = step
    }
}

/// A playtest session's outcome: every assertion's result, in order.
public struct PlaytestResult: Codable, Equatable, Sendable {
    public var name: String?
    /// No assertion failed and no step errored.
    public var passed: Bool
    public var passedCount: Int
    public var failedCount: Int
    public var checks: [PlaytestCheck]
    /// Steps that couldn't run (an unknown action, bad input).
    public var errors: [String]
    /// Game frames and seconds run.
    public var frames: Int
    public var time: Double
    /// Whether the session is recording, and the steps recorded so far.
    public var recording: Bool
    public var recordedSteps: Int

    public init(name: String?, checks: [PlaytestCheck], errors: [String], frames: Int, time: Double, recording: Bool = false,
                recordedSteps: Int = 0) {
        self.name = name
        self.checks = checks
        self.errors = errors
        passedCount = checks.filter(\.passed).count
        failedCount = checks.count - passedCount
        passed = failedCount == 0 && errors.isEmpty
        self.frames = frames
        self.time = time
        self.recording = recording
        self.recordedSteps = recordedSteps
    }

    /// A few lines for a terminal: each check, then a summary.
    public var report: String {
        var lines = checks.map { "\($0.passed ? "PASS" : "FAIL") [frame \($0.frame)] \($0.label)\($0.passed ? "" : ": \($0.message)")" }
        lines += errors.map { "ERROR \($0)" }
        lines.append("\(passed ? "Passed" : "Failed"): \(passedCount) of \(checks.count) assertions passed"
                     + (errors.isEmpty ? "" : ", \(errors.count) errors") + " in \(frames) frames (\(String(format: "%.2f", time)) s)")
        return lines.joined(separator: "\n")
    }
}

public struct PlaytestError: Error, CustomStringConvertible, Sendable {
    public var description: String
    public init(_ description: String) { self.description = description }
}
