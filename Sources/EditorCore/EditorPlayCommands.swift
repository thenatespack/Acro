import Engine
import Foundation

// Play-mode control and input injection, for the toolbar and for AI playtesters: pause, step a
// number of frames (deterministic), time scale, the game camera view, and keyboard, mouse,
// scroll and text played into the game's input (`EditorSession.gameInput`) over game time.
// While playing, the scene and entity commands read and write the live world; Stop restores
// the scene as it was.
//
// ```
// play.start {paused: true}
// input.inject {steps: [{key: "w", duration: 2}]}      // hold W for two seconds of game time
// play.step {frames: 120}                               // run them now, at 1/60 s per frame
// view.screenshot {source: "game"}
// play.stop                                             // the scene is back, byte for byte
// ```

/// Play mode's state, which the play and input commands return.
public struct PlayStateResult: Codable, Equatable, Sendable {
    public var playing: Bool
    public var paused: Bool
    public var timeScale: Double
    /// Game frames and seconds of game time run since Play.
    public var frame: Int
    public var time: Double
    /// Injected events still scheduled, and the seconds of game time until the last.
    public var inputPending: Int
    public var inputSeconds: Double
    /// Keys and mouse buttons down in the game's input.
    public var keys: [Key]
    public var buttons: [MouseButton]
    /// Whether the viewport shows the game camera while playing.
    public var gameCamera: Bool
    /// Whether the play session simulates physics (the scene has colliders).
    public var physics: Bool
}

extension EditorSession {
    public var playStateResult: PlayStateResult {
        PlayStateResult(playing: isPlaying, paused: isPaused, timeScale: timeScale, frame: playFrame, time: playTime,
                        inputPending: inputPlayer.pendingCount, inputSeconds: inputPlayer.remaining,
                        keys: Key.allCases.filter { gameInput.isDown($0) }, buttons: MouseButton.allCases.filter { gameInput.isDown($0) },
                        gameCamera: showsGameCamera, physics: physics != nil)
    }
}

private let notPlaying = "not playing (play.start first)"

public enum PlayPauseCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// true pauses, false resumes; omitted toggles.
        public var paused: Bool?
        public init(paused: Bool? = nil) { self.paused = paused }
    }

    public static let id: CommandID = .togglePause
    public static let title = "Pause"
    public static let doc = "Pauses play mode (`paused` true), resumes it (false) or toggles (omitted). Paused, the world doesn't update and scheduled input waits; edits still apply."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { notPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PlayStateResult {
        session.setPaused(arguments.paused ?? !session.isPaused)
        return session.playStateResult
    }
}

public enum PlayStepCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Frames to run (default 1, at most 10000).
        public var frames: Int?
        /// Seconds per frame (default the world's fixed step, 1/60).
        public var dt: Double?
        public init(frames: Int? = nil, dt: Double? = nil) {
            self.frames = frames
            self.dt = dt
        }
    }

    public static let id: CommandID = .step
    public static let title = "Step"
    public static let doc = "Pauses play mode and runs `frames` game frames now (default 1), each `dt` seconds (default 1/60), with the input scheduled for them. Deterministic: the same scene, input and steps give the same result."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { notPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PlayStateResult {
        let frames = arguments.frames ?? 1
        guard (0...10_000).contains(frames) else { throw CommandError.failed("`frames` must be between 0 and 10000") }
        if let dt = arguments.dt, !(dt > 0 && dt <= 1) { throw CommandError.failed("`dt` must be in (0, 1] seconds") }
        session.step(frames: frames, dt: arguments.dt)
        return session.playStateResult
    }
}

public enum PlaySetTimeScaleCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// 0 to 100; 1 is real time, 0.5 half speed.
        public var scale: Double
        public init(scale: Double) { self.scale = scale }
    }

    public static let id: CommandID = "play.setTimeScale"
    public static let title = "Set Time Scale"
    public static let doc = "Multiplies play mode's dt by `scale` (0 to 100; 1 is real time). Steps use their own dt."
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PlayStateResult {
        guard (0...100).contains(arguments.scale) else { throw CommandError.failed("`scale` must be between 0 and 100") }
        session.timeScale = arguments.scale
        return session.playStateResult
    }
}

public enum PlayStateCommand: EditorCommand {
    public static let id: CommandID = "play.state"
    public static let title = "Play State"
    public static let doc = "Returns whether the editor is playing and paused, the time scale, game frames and seconds run, scheduled input, keys and buttons down in the game, and whether physics runs."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> PlayStateResult {
        session.playStateResult
    }
}

public enum ViewGameCameraCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// true shows the game camera while playing, false the editor camera; omitted toggles.
        public var enabled: Bool?
        public init(enabled: Bool? = nil) { self.enabled = enabled }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var enabled: Bool
    }

    public static let id: CommandID = .toggleGameCamera
    public static let title = "Game View"
    public static let doc = "Whether the viewport shows the scene's Camera entity while playing (and forwards the keyboard and the mouse over it to the game) or the editor camera. On by default."
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        session.showsGameCamera = arguments.enabled ?? !session.showsGameCamera
        return Result(enabled: session.showsGameCamera)
    }
}

// MARK: Input

public enum InputInjectCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Run one after another; see the command's doc.
        public var steps: [InputStep]
        /// Drop what is scheduled (and release injected keys) first.
        public var replace: Bool?
        public init(steps: [InputStep], replace: Bool? = nil) {
            self.steps = steps
            self.replace = replace
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Seconds of game time until the scheduled input is done.
        public var seconds: Double
        public var state: PlayStateResult
    }

    public static let id: CommandID = "input.inject"
    public static let title = "Inject Input"
    public static let doc = """
        Plays input into the game (play mode) over game time, after what is already scheduled (`replace`: instead). \
        Each step does one thing: `key` (or `keys` together) / `button` tapped for one frame, held `duration` seconds, \
        or pressed (`down`: true) / released (false); `mouseTo` [x, y] in game-view points; `mouseBy`; `scroll`; \
        `text`. The next step starts `wait` seconds later (default the step's `duration`; 0 overlaps them). \
        Game systems read it from the session's gameInput, never the editor's UI. Paused, it waits: play.step runs it \
        frame by frame. Example: [{"key": "w", "duration": 2}, {"key": "space"}].
        """
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { notPlaying }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if arguments.replace == true {
            session.inputPlayer.clear()
            session.gameInput.releaseInjected()
        }
        do {
            let seconds = try session.inputPlayer.enqueue(arguments.steps)
            return Result(seconds: seconds, state: session.playStateResult)
        } catch {
            throw CommandError.failed("Inject Input: \(error)")
        }
    }
}

public enum InputClearCommand: EditorCommand {
    public static let id: CommandID = "input.clear"
    public static let title = "Clear Input"
    public static let doc = "Drops scheduled input and releases every injected key and button."
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> PlayStateResult {
        session.inputPlayer.clear()
        session.gameInput.releaseInjected()
        return session.playStateResult
    }
}

public enum InputStateCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        public var keys: [Key]
        public var buttons: [MouseButton]
        /// Cursor position in game-view points, and its last frame's movement.
        public var mouse: Vec2
        public var mouseDelta: Vec2
        /// Held by injected input (released by input.clear or a step with `down`: false).
        public var injectedKeys: [Key]
        public var pending: Int
    }

    public static let id: CommandID = "input.state"
    public static let title = "Input State"
    public static let doc = "Returns the game's input as of the last game frame: keys and buttons down, the cursor, keys held by injection and events still scheduled."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let input = session.gameInput
        return Result(keys: Key.allCases.filter { input.isDown($0) }, buttons: MouseButton.allCases.filter { input.isDown($0) },
                      mouse: input.mousePosition, mouseDelta: input.mouseDelta,
                      injectedKeys: input.injectedHeldKeys.sorted { $0.rawValue < $1.rawValue }, pending: session.inputPlayer.pendingCount)
    }
}
