import Engine
import EngineMCP
import Foundation

// Agent playtesting in the editor (see Sources/Engine/Playtest/Playtest.swift): input by action
// name and a virtual gamepad, assertions collected into a result, and sessions recorded into
// playtest files that replay with their assertions checked again.
//
// ```
// playtest.start {name: "walk right"}                  // Play, paused at frame 0, recording
// play.step {frames: 1}                                 // visual scripts start: their actions are known
// input.action {action: "right", duration: 1}           // hold the action's key for a second
// play.step {frames: 90}
// playtest.assert {entity: "Player", field: "position.x", min: 1.9}
// playtest.save {path: "Playtests/WalkRight"}           // Playtests/WalkRight.playtest.json
// playtest.stop                                         // the result; the scene is restored
// playtest.run {path: "Playtests/WalkRight.playtest.json"}   // replay: the same checks again
// ```
//
// While a session records, `input.inject`, `input.clear` and `play.step` are recorded too, and
// frames that ran in real time (unpaused) are recorded as `frames` steps at the fixed dt, so for
// an exact replay step paused. `GameRunner <module> --playtest <file>` runs the same files
// headless (CI).

extension EditorSession {
    /// A playtest driver for this session's play mode.
    func makePlaytestDriver(name: String?, record: Bool, actions: [String: [String]] = [:]) -> PlaytestDriver {
        let target = PlaytestTarget(world: { [unowned self] in world }, input: { [unowned self] in gameInput },
                                    inputPlayer: { [unowned self] in inputPlayer }, frame: { [unowned self] in playFrame },
                                    time: { [unowned self] in playTime }, fixedStep: { [unowned self] in world.fixedTimestep },
                                    runFrames: { [unowned self] frames, dt in step(frames: frames, dt: dt) })
        let scene = document.url.map { project?.assetPath(for: $0) ?? $0.path }
        return PlaytestDriver(target: target, name: name, scene: scene, actions: actions, record: record)
    }

    /// The playtest session, made (not recording) when there is none.
    func ensurePlaytest() -> PlaytestDriver {
        if let playtest { return playtest }
        let driver = makePlaytestDriver(name: nil, record: false)
        playtest = driver
        return driver
    }

    /// A playtest file path: relative paths are in the project folder when one is open.
    func playtestURL(_ path: String, _ action: String) throws -> URL {
        var path = path.trimmingCharacters(in: .whitespaces)
        if let project, fileAccessRoots == nil, !(path as NSString).expandingTildeInPath.hasPrefix("/") {
            path = project.root.appendingPathComponent(path).path
        }
        guard let url = fileURL(forPath: path, action) else { throw CommandError.failed("\(action): \(path) is outside the project folder") }
        return url
    }

    /// The result of the playtest session (an empty one when there is none).
    var playtestResult: PlaytestResult {
        playtest?.result ?? PlaytestResult(name: nil, checks: [], errors: [], frames: playFrame, time: playTime)
    }
}

/// The result of the playtest input commands.
public struct PlaytestInputResult: Codable, Equatable, Sendable {
    /// Action and gamepad input still scheduled.
    public var actionInputPending: Int
    public var state: PlayStateResult
}

public enum InputActionCommand: EditorCommand {
    public typealias Arguments = PlaytestActionArguments
    public typealias Result = PlaytestInputResult

    public static let id: CommandID = "input.action"
    public static let title = "Input Action"
    public static let doc = """
        Presses an input action by name (play mode), from the next game frame: tapped (down one frame), held `duration` \
        seconds, pressed (`down`: true) or released (false). `value` (-1…1) sets an analog source instead (a gamepad \
        axis such as "axis.leftStickX+"); a key or button counts as pressed at |value| ≥ 0.5. Actions come from the \
        scene's visual scripts (known once they started: step a frame first) and playtest.start's `actions`; \
        input.actions lists them. Paused, it waits: play.step runs it. Recorded while a playtest records.
        """
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start or playtest.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let driver = session.ensurePlaytest()
        do {
            try driver.perform(arguments.step)
        } catch {
            throw CommandError.failed("Input Action: \(error)")
        }
        return Result(actionInputPending: driver.pendingInput, state: session.playStateResult)
    }
}

public enum InputGamepadCommand: EditorCommand {
    public typealias Arguments = PlaytestGamepadArguments
    public typealias Result = PlaytestInputResult

    public static let id: CommandID = "input.gamepad"
    public static let title = "Gamepad Input"
    public static let doc = """
        Drives a virtual gamepad in the game's input (play mode), from the next game frame: a `button` ("south", \
        "east", "dpadUp", "start"…) tapped, held `duration` seconds or pressed / released (`down`), or an `axis` \
        ("leftStickX", "leftStickY", "rightStickX", "rightStickY" -1…1, "leftTrigger", "rightTrigger" 0…1) set to \
        `value` for `duration` seconds or until set again. Game code sees it in `Input.gamepads` like a real pad. \
        Recorded while a playtest records.
        """
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start or playtest.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let driver = session.ensurePlaytest()
        do {
            try driver.perform(arguments.step)
        } catch {
            throw CommandError.failed("Gamepad Input: \(error)")
        }
        return Result(actionInputPending: driver.pendingInput, state: session.playStateResult)
    }
}

public enum InputActionsCommand: EditorCommand {
    public typealias Result = PlaytestActionList

    public static let id: CommandID = "input.actions"
    public static let title = "Input Actions"
    public static let doc = "Lists the input actions input.action can press, with their sources (\"key.space\", \"pad.south\", \"axis.leftStickX+\") and origin: \"playtest\" (playtest.start's `actions`) or \"script\" (a visual script running in the scene, so known once play ran a frame)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let driver = session.playtest ?? session.makePlaytestDriver(name: nil, record: false)
        return PlaytestActionList(actions: driver.knownActions)
    }
}

// MARK: Sessions

public enum PlaytestStartCommand: EditorCommand {
    public typealias Arguments = PlaytestStartArguments
    public typealias Result = PlayStateResult

    public static let id: CommandID = "playtest.start"
    public static let title = "Start Playtest"
    public static let doc = """
        Starts a playtest session: Play from the scene as saved in the editor (stopping play first if it runs), \
        paused at frame 0, recording (unless `record` is false) every input.action, input.gamepad, input.inject, \
        input.clear, play.step and playtest.assert for playtest.save. `actions` adds input actions (name → sources \
        such as "key.space", "pad.south", "axis.leftStickX") to the scene's visual scripts' ones. Assertions collect \
        in playtest.result.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if session.isPlaying { session.stop() }
        session.play(paused: true)
        guard session.isPlaying else { throw CommandError.failed("Start Playtest: play mode didn't start") }
        session.playtest = session.makePlaytestDriver(name: arguments.name, record: arguments.record ?? true,
                                                      actions: arguments.actions ?? [:])
        session.log.info("Playtest\(arguments.name.map { " '\($0)'" } ?? "") started\(arguments.record == false ? "" : ", recording")")
        return session.playStateResult
    }
}

public enum PlaytestAssertCommand: EditorCommand {
    public typealias Arguments = PlaytestAssertion
    public typealias Result = PlaytestCheck

    public static let id: CommandID = "playtest.assert"
    public static let title = "Assert"
    public static let doc = """
        Checks the world now and records pass / fail in the playtest session (made if there is none). The value: \
        `entity` (a name, a path "Level/Door" or an id) alone checks it exists; with `component` and `field` a \
        component field ("position.x", "linearVelocity"); with `variable` a visual script variable; with only `field` \
        its world transform ("position", "position.y", "rotation", "scale"); or `count` {name?, component?} of \
        entities. Compared with `exists`, `equals` (numbers within `tolerance`, default 1e-4), `min` / `max`, or \
        `near` [x, y, z] within `tolerance` (default 0.01). Returns the check: passed, message, the actual value. A \
        failing assertion is a result, not a tool error.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let driver = session.ensurePlaytest()
        let check = try driver.perform(.assert(arguments)) ?? driver.check(arguments)
        if !check.passed { session.log.warning("Playtest assertion failed: \(check.label): \(check.message)") }
        return check
    }
}

public enum PlaytestResultCommand: EditorCommand {
    public typealias Result = PlaytestResult

    public static let id: CommandID = "playtest.result"
    public static let title = "Playtest Result"
    public static let doc = "Returns the playtest session's result: every assertion so far (label, passed, message, actual value, frame), `passed` (none failed and no step errored), step errors, frames run and how many steps are recorded. Still readable after playtest.stop."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        session.playtestResult
    }
}

public enum PlaytestSaveCommand: EditorCommand {
    public typealias Arguments = PlaytestSaveArguments
    public typealias Result = PlaytestSaveResult

    public static let id: CommandID = "playtest.save"
    public static let title = "Save Playtest"
    public static let doc = """
        Writes what the playtest session recorded since playtest.start (input, frames and assertions, with the scene) \
        as a playtest JSON file: `path` relative to the project folder (".playtest.json" added when missing). Replay \
        it with playtest.run, or headless with `GameRunner <module> --playtest <file>` (exit code 1 when an assertion \
        fails). Overwrites an existing file. Works during play and after playtest.stop.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let driver = session.playtest else { throw CommandError.failed("Save Playtest: no playtest session (playtest.start first)") }
        let recording = driver.finishedRecording()
        guard !recording.steps.isEmpty else {
            throw CommandError.failed("Save Playtest: nothing recorded (playtest.start records; start one with `record` true)")
        }
        var path = arguments.path
        if !path.hasSuffix(".json") { path += Playtest.fileSuffix }
        let url = try session.playtestURL(path, "Save Playtest")
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try recording.json().write(to: url, options: .atomic)
        } catch {
            throw CommandError.failed("Save Playtest: \(error)")
        }
        session.log.info("Saved playtest \(url.lastPathComponent): \(recording.steps.count) steps, \(recording.assertionCount) assertions")
        return Result(path: url.path, playtest: recording)
    }
}

public enum PlaytestStopCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Keep play mode running (default: stop it, restoring the scene).
        public var keepPlaying: Bool?
        public init(keepPlaying: Bool? = nil) { self.keepPlaying = keepPlaying }
    }
    public typealias Result = PlaytestResult

    public static let id: CommandID = "playtest.stop"
    public static let title = "Stop Playtest"
    public static let doc = "Ends the playtest session's recording and stops play mode (the scene is restored; `keepPlaying` keeps it running). Returns the session's result; playtest.save still saves the recording."
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        session.playtest?.stopRecording()
        let result = session.playtestResult
        if arguments.keepPlaying != true && session.isPlaying { session.stop() }
        if session.playtest != nil {
            session.log.info("Playtest \(result.passed ? "passed" : "failed"): \(result.passedCount) of \(result.checks.count) assertions")
        }
        return result
    }
}

public enum PlaytestRunCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A playtest file (relative to the project folder).
        public var path: String?
        /// Or the playtest itself.
        public var playtest: Playtest?
        /// Keep play mode running at the end (default: stop, restoring the scene).
        public var keepPlaying: Bool?
        public init(path: String? = nil, playtest: Playtest? = nil, keepPlaying: Bool? = nil) {
            self.path = path
            self.playtest = playtest
            self.keepPlaying = keepPlaying
        }
    }
    public typealias Result = PlaytestResult

    public static let id: CommandID = "playtest.run"
    public static let title = "Run Playtest"
    public static let doc = """
        Replays a playtest (`path` to a .playtest.json file, or the `playtest` itself) in play mode: opens its \
        `scene` when another one is open (refused while that one has unsaved changes), plays from the start paused, \
        runs every step at the fixed dt and checks its assertions, then stops (`keepPlaying` keeps the end state). \
        Returns the result; `passed` is false when an assertion failed or a step couldn't run.
        """
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let playtest: Playtest
        var file: URL?
        if let given = arguments.playtest {
            playtest = given
        } else if let path = arguments.path {
            let url = try session.playtestURL(path, "Run Playtest")
            file = url
            do {
                playtest = try Playtest(contentsOf: url)
            } catch {
                throw CommandError.failed("Run Playtest: \(url.lastPathComponent): \(error)")
            }
        } else {
            throw CommandError.failed("Run Playtest: give `path` or `playtest`")
        }
        if let scene = playtest.scene { try openScene(scene, near: file, in: session) }
        if session.isPlaying { session.stop() }
        session.play(paused: true)
        guard session.isPlaying else { throw CommandError.failed("Run Playtest: play mode didn't start") }
        let driver = session.makePlaytestDriver(name: playtest.name, record: false)
        session.playtest = driver
        let result = driver.run(playtest)
        if arguments.keepPlaying != true { session.stop() }
        session.log.info("Playtest \(playtest.name.map { "'\($0)' " } ?? "")\(result.passed ? "passed" : "failed"): \(result.passedCount) of \(result.checks.count) assertions"
                         + (result.errors.isEmpty ? "" : ", \(result.errors.count) errors"))
        return result
    }

    /// Opens the playtest's scene unless it is the open one.
    private static func openScene(_ scene: String, near file: URL?, in session: EditorSession) throws {
        var candidates = [session.resolvedFileURL(forPath: session.sceneOpenPath(scene))]
        if let file { candidates.append(PlaytestHeadlessHost.resolve(scene, from: file)) }
        let fm = FileManager.default
        guard let url = candidates.first(where: { fm.fileExists(atPath: $0.path) }) else {
            throw CommandError.failed("Run Playtest: its scene \(scene) wasn't found")
        }
        if let open = session.document.url, EditorSession.resolved(open) == EditorSession.resolved(url) { return }
        if session.isPlaying { session.stop() }
        guard !session.document.isDirty else {
            throw CommandError.failed("Run Playtest: it plays \(scene), but the open scene has unsaved changes (save it or open \(scene) first)")
        }
        guard session.open(path: url.path) else { throw CommandError.failed("Run Playtest: \(scene) didn't open") }
    }
}
