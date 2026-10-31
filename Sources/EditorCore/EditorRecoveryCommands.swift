import Engine
import Foundation

// Commands for recovering work a crashed (or closed-with-unsaved-changes) session left behind
// (EditorRecovery.swift): list, open, discard.

public enum EditorRecoveryCommands {
    public static let all: [any EditorCommand.Type] = [
        SceneListRecoveryCommand.self, SceneRecoverCommand.self, SceneDiscardRecoveryCommand.self,
    ]
}

/// `scene.listRecovery`'s result.
public struct RecoveryListResult: Codable, Equatable, Sendable {
    /// Whether this editor keeps recovery files (not in deterministic or prefs-less runs).
    public var enabled: Bool
    /// Where they are.
    public var folder: String?
    /// Sessions that can be recovered, newest first.
    public var sessions: [RecoveryInfo]
}

public enum SceneListRecoveryCommand: EditorCommand {
    public static let id: CommandID = "scene.listRecovery"
    public static let title = "List Recoverable Work"
    public static let doc = """
        Work that earlier editor sessions left behind because they crashed (game code included) or were closed with \
        unsaved changes: per session the scene, why it ended, whether it had unsaved changes and a play state. \
        Open one with scene.recover, delete with scene.discardRecovery.
        """
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> RecoveryListResult {
        guard let recovery = session.recovery else { return RecoveryListResult(enabled: false, folder: nil, sessions: []) }
        recovery.refresh()
        return RecoveryListResult(enabled: true, folder: recovery.folder.path, sessions: recovery.found)
    }
}

public enum SceneRecoverCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The session (`id` from scene.listRecovery); default the newest.
        public var id: String?
        /// Open the play world as it was at the crash instead of the edit-time scene.
        public var playState: Bool?
        public init(id: String? = nil, playState: Bool? = nil) {
            self.id = id
            self.playState = playState
        }
    }

    public static let id: CommandID = "scene.recover"
    public static let title = "Recover Unsaved Work"
    public static let doc = """
        Opens the work a crashed or closed session left behind (scene.listRecovery) as the document: unsaved, saving \
        to the scene's original file; `playState` opens the play world at the crash instead, as a new scene. Replaces \
        the open scene and clears the undo history. Not while playing.
        """
    public static let isDestructive = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying && session.recovery?.found.isEmpty == false }
    public static func unavailableReason(in session: EditorSession) -> String? {
        if session.isPlaying { return "playing (stop first)" }
        guard let recovery = session.recovery else { return "recovery is off (no prefs folder)" }
        return recovery.found.isEmpty ? "nothing to recover" : nil
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> RecoveryInfo {
        guard let recovery = session.recovery else { throw CommandError.failed("Recovery is off") }
        return try recovery.recover(id: arguments.id, playState: arguments.playState ?? false)
    }
}

public enum SceneDiscardRecoveryCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The session to delete; default all of them.
        public var id: String?
        public init(id: String? = nil) { self.id = id }
    }

    public static let id: CommandID = "scene.discardRecovery"
    public static let title = "Discard Recoverable Work"
    public static let doc = "Deletes the work a crashed or closed session left behind (`id`, default every session in scene.listRecovery)."
    public static let isDestructive = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.recovery?.found.isEmpty == false }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.recovery?.found.isEmpty == false ? nil : "nothing to recover"
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> RecoveryListResult {
        guard let recovery = session.recovery else { throw CommandError.failed("Recovery is off") }
        recovery.discard(id: arguments.id)
        return RecoveryListResult(enabled: true, folder: recovery.folder.path, sessions: recovery.found)
    }
}
