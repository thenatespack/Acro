import Engine
import Foundation

// What keeps AI clients in check (EditorMCP.swift applies it to every call):
//
// - **Labeled undo.** Steps recorded during an MCP call are labeled "AI: …" (`UndoStack.labelPrefix`),
//   so the history and the Undo button say who made them.
// - **Activity log.** Every call, its arguments and its outcome is an `ActivityEntry` in
//   `session.activity`, listed by the Activity panel and `activity.list`. `activity.revert`
//   (the panel's Revert buttons) undoes the AI steps on top of the undo history: all of them,
//   or down to one call.
// - **Confirmations.** Destructive tools (`isDestructive`) refuse to run without `confirm: true`;
//   with `AISettings.askBeforeDestructive` the editor also asks the user in a dialog.
// - **Sandbox.** During a call `session.fileAccessRoots` is the project folder (the editor's
//   start folder without a project): file paths outside it are refused, and relative paths
//   resolve inside it. Asset paths can't climb out of `Assets/`.
// - **Read-only mode** (`AISettings.readOnly`): only read-only tools are listed and run.
// - **HTTP** (`AISettings.httpEnabled`): the localhost server with its bearer token can be
//   turned off. Settings change only in the editor (the Activity panel, the prefs file), never
//   through MCP.

/// What AI clients may do. Persisted in the editor prefs.
public struct AISettings: Codable, Equatable, Sendable {
    /// Expose only read-only (perception and query) tools.
    public var readOnly: Bool
    /// Ask the user in the editor before a destructive call (deleting files, discarding
    /// unsaved changes), on top of the call's `confirm: true`.
    public var askBeforeDestructive: Bool
    /// Serve MCP over HTTP on localhost while the editor runs.
    public var httpEnabled: Bool

    public init(readOnly: Bool = false, askBeforeDestructive: Bool = false, httpEnabled: Bool = true) {
        self.readOnly = readOnly
        self.askBeforeDestructive = askBeforeDestructive
        self.httpEnabled = httpEnabled
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readOnly = try container.decodeIfPresent(Bool.self, forKey: .readOnly) ?? false
        askBeforeDestructive = try container.decodeIfPresent(Bool.self, forKey: .askBeforeDestructive) ?? false
        httpEnabled = try container.decodeIfPresent(Bool.self, forKey: .httpEnabled) ?? true
    }
}

/// One MCP call, as the Activity panel lists it.
public struct ActivityEntry: Codable, Equatable, Sendable {
    public enum Outcome: String, Codable, Sendable {
        /// Still running (waiting for a frame, imports or the user).
        case running
        case ok
        case error
        /// Not run: read-only mode, a missing `confirm`, the user said no, outside the sandbox.
        case refused
    }

    public var id: Int
    /// Console time (seconds since the editor started).
    public var time: Double
    public var tool: String
    /// The arguments as compact JSON.
    public var arguments: String
    public var outcome: Outcome
    /// The result or the error, shortened.
    public var summary: String
    /// The undo step the call recorded ("AI: Rename"), if any.
    public var undoLabel: String?
    /// The undo depth right after the call; its step is the one below it.
    public var undoDepth: Int?
    /// The client's name from `initialize`, if it gave one.
    public var client: String?
}

/// The calls AI clients made, newest last (at most `maxEntries`).
@MainActor
public final class EditorActivityLog {
    public private(set) var entries: [ActivityEntry] = []
    public var maxEntries = 500
    /// Increases on every change, for panels that poll.
    public private(set) var changeCount = 0
    /// When the last call started or finished.
    public private(set) var lastActivity: ContinuousClock.Instant?
    private var nextID = 1

    public init() {}

    /// Adds a call; returns its id.
    @discardableResult
    public func record(tool: String, arguments: String, outcome: ActivityEntry.Outcome, summary: String, time: Double,
                       client: String? = nil) -> Int {
        let id = nextID
        nextID += 1
        entries.append(ActivityEntry(id: id, time: time, tool: tool, arguments: arguments, outcome: outcome,
                                     summary: Self.shorten(summary), client: client))
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }
        touch()
        return id
    }

    /// Records how call `id` ended.
    public func finish(_ id: Int, outcome: ActivityEntry.Outcome, summary: String, undoLabel: String?, undoDepth: Int?) {
        guard let index = entries.lastIndex(where: { $0.id == id }) else { return }
        entries[index].outcome = outcome
        entries[index].summary = Self.shorten(summary)
        entries[index].undoLabel = undoLabel
        entries[index].undoDepth = undoDepth
        touch()
    }

    public func entry(_ id: Int) -> ActivityEntry? { entries.last { $0.id == id } }

    public func clear() {
        entries = []
        touch()
    }

    /// The tool of a call still running, if any.
    public var running: String? { entries.last { $0.outcome == .running }?.tool }

    /// Whether a call ran within `seconds`.
    public func wasActive(within seconds: Double) -> Bool {
        guard let lastActivity else { return false }
        return ContinuousClock.now - lastActivity < .milliseconds(Int(seconds * 1000))
    }

    private func touch() {
        changeCount += 1
        lastActivity = .now
    }

    static func shorten(_ text: String, limit: Int = 600) -> String {
        text.count <= limit ? text : String(text.prefix(limit)) + "…"
    }
}

// MARK: Session

extension EditorSession {
    /// The label prefix of undo steps made by AI clients.
    public static let aiUndoPrefix = "AI: "

    /// The file URL for a path an action was given: `~` expanded; relative paths against the
    /// working directory, or against the sandbox root while `fileAccessRoots` is set. Nil
    /// (logged as an error) when the path is outside the sandbox.
    public func fileURL(forPath path: String, _ action: String) -> URL? {
        let url = resolvedFileURL(forPath: path)
        return checkFileAccess(url, action) ? url : nil
    }

    /// `fileURL(forPath:_:)` without the sandbox check or the log entry.
    func resolvedFileURL(forPath path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        var url = Self.url(forPath: trimmed)
        if let root = fileAccessRoots?.first {
            let expanded = (trimmed as NSString).expandingTildeInPath
            if !expanded.hasPrefix("/") { url = root.appendingPathComponent(expanded).standardizedFileURL }
        }
        return url
    }

    /// Whether saving the scene to `path` would overwrite a file that isn't the scene's own.
    func savingOverOtherFile(at path: String) -> Bool {
        guard !path.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        let url = resolvedFileURL(forPath: path)
        if let own = document.url, Self.resolved(own) == Self.resolved(url) { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Whether `url` may be touched now (inside `fileAccessRoots`, symbolic links resolved);
    /// logs an error when not.
    public func checkFileAccess(_ url: URL, _ action: String) -> Bool {
        guard let roots = fileAccessRoots else { return true }
        if roots.contains(where: { Self.isInside(url, $0) }) { return true }
        let allowed = roots.map(\.path).joined(separator: ", ")
        log.error("\(action): \(url.path) is outside the project folder (AI clients may only touch files in \(allowed))")
        return false
    }

    /// Whether asset paths (relative to `Assets/`) stay inside it while sandboxed; logs an error when not.
    func checkAssetPaths(_ paths: [String], _ action: String) -> Bool {
        guard fileAccessRoots != nil else { return true }
        for path in paths {
            let parts = path.split(whereSeparator: { $0 == "/" || $0 == "\\" })
            if path.hasPrefix("/") || path.hasPrefix("~") || parts.contains("..") {
                log.error("\(action): '\(path)' leaves the project's Assets folder")
                return false
            }
        }
        return true
    }

    static func isInside(_ url: URL, _ root: URL) -> Bool {
        let path = resolved(url).path
        let base = resolved(root).path
        return path == base || path.hasPrefix(base.hasSuffix("/") ? base : base + "/")
    }

    /// `url` with symbolic links resolved, including in the folders of a file that doesn't
    /// exist yet (resolving stops at the first missing component otherwise).
    static func resolved(_ url: URL) -> URL {
        var existing = url.standardizedFileURL
        var missing: [String] = []
        while !FileManager.default.fileExists(atPath: existing.path), existing.pathComponents.count > 1 {
            missing.insert(existing.lastPathComponent, at: 0)
            existing.deleteLastPathComponent()
        }
        return missing.reduce(existing.resolvingSymlinksInPath()) { $0.appendingPathComponent($1) }
    }

    /// Undoes AI steps from the top of the undo history: every consecutive "AI: " step, or with
    /// `entry`, down to and including the step that activity entry recorded. Returns the labels
    /// undone. Throws (after logging) when a step of the user's is in the way or the entry's
    /// step is gone.
    @discardableResult
    public func revertAIChanges(through entry: Int? = nil) throws -> [String] {
        let history = undo.undoHistory
        let prefix = Self.aiUndoPrefix
        let count: Int
        if let entry {
            guard let record = activity.entry(entry) else { throw fail("Revert: no activity entry \(entry)") }
            guard let label = record.undoLabel, let depth = record.undoDepth else {
                throw fail("Revert: call \(entry) (\(record.tool)) made no undo step")
            }
            let steps = undo.undoDepth - (depth - 1)
            guard steps >= 1, steps <= history.count, history[steps - 1] == label else {
                throw fail("Revert: the step of call \(entry) (\(label)) is no longer in the undo history")
            }
            guard history.prefix(steps).allSatisfy({ $0.hasPrefix(prefix) }) else {
                throw fail("Revert: you made changes after call \(entry); undo those first")
            }
            count = steps
        } else {
            count = history.prefix { $0.hasPrefix(prefix) }.count
            guard count > 0 else { throw fail("Revert: the last undo step wasn't made by an AI client") }
        }
        var undone: [String] = []
        for label in history.prefix(count) {
            guard performUndo() else { throw CommandError.failed(log.entries.last?.message ?? "Undo failed") }
            undone.append(label)
        }
        log.info("Reverted \(undone.count) AI step\(undone.count == 1 ? "" : "s")")
        return undone
    }

    private func fail(_ message: String) -> CommandError {
        log.warning(message)
        return CommandError.failed(message)
    }
}

// MARK: Commands

/// The safety commands (see the notes at the top of this file).
@MainActor
public enum EditorSafetyCommands {
    public static let all: [any EditorCommand.Type] = [
        ActivityListCommand.self, ActivityRevertCommand.self, ActivityClearCommand.self, AISettingsCommand.self,
        LogClearCommand.self,
    ]
}

public enum ActivityListCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The newest `limit` entries (default 50).
        public var limit: Int?
        /// Only entries with an id above this (the `next` of an earlier read).
        public var since: Int?
        public init(limit: Int? = nil, since: Int? = nil) {
            self.limit = limit
            self.since = since
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entries: [ActivityEntry]
        /// Pass as `since` to read only newer entries.
        public var next: Int
        /// Undo steps on top of the history that AI clients made (what `activity.revert` undoes).
        public var revertableSteps: Int
    }

    public static let id: CommandID = "activity.list"
    public static let title = "Activity"
    public static let doc = "The AI activity log: every MCP call with its arguments, outcome, result summary and the undo step it recorded (\"AI: …\"), as the Activity panel lists it."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let entries = session.activity.entries.filter { $0.id > (arguments.since ?? 0) }
        return Result(entries: Array(entries.suffix(max(arguments.limit ?? 50, 0))),
                      next: session.activity.entries.last?.id ?? (arguments.since ?? 0),
                      revertableSteps: session.undo.undoHistory.prefix { $0.hasPrefix(EditorSession.aiUndoPrefix) }.count)
    }
}

public enum ActivityRevertCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Undo down to and including this activity entry's step; default: every AI step on top.
        public var entry: Int?
        public init(entry: Int? = nil) { self.entry = entry }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The undo labels taken back, newest first.
        public var undone: [String]
    }

    public static let id: CommandID = "activity.revert"
    public static let title = "Revert AI Changes"
    public static let doc = "Undoes the AI clients' steps on top of the undo history: all consecutive \"AI: …\" steps (the last AI batch), or down to the step of activity `entry`. Refused when a step of the user's is in the way. edit.redo brings them back."
    public static func isAvailable(in session: EditorSession) -> Bool {
        session.undo.canUndo && session.undo.undoLabel?.hasPrefix(EditorSession.aiUndoPrefix) == true
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.isPlaying ? EditorError.playing.description : "the last undo step wasn't made by an AI client"
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        Result(undone: try session.revertAIChanges(through: arguments.entry))
    }
}

public enum ActivityClearCommand: EditorCommand {
    public static let id: CommandID = "activity.clear"
    public static let title = "Clear Activity"
    public static let doc = "Empties the AI activity log (the undo history stays)."
    public static let isIdempotent = true
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.activity.clear()
        return NoResult()
    }
}

public enum AISettingsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var readOnly: Bool?
        public var askBeforeDestructive: Bool?
        public var httpEnabled: Bool?
        public init(readOnly: Bool? = nil, askBeforeDestructive: Bool? = nil, httpEnabled: Bool? = nil) {
            self.readOnly = readOnly
            self.askBeforeDestructive = askBeforeDestructive
            self.httpEnabled = httpEnabled
        }

        var isEmpty: Bool { readOnly == nil && askBeforeDestructive == nil && httpEnabled == nil }
    }

    public static let id: CommandID = "ai.settings"
    public static let title = "AI Settings"
    public static let doc = "What AI clients may do: `readOnly` (only perception and query tools), `askBeforeDestructive` (the editor asks the user before deleting files or discarding changes) and `httpEnabled` (the localhost HTTP server). Returns the settings. Over MCP it only reads them: they change in the editor (the Activity panel) or the prefs file."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> AISettings {
        var settings = session.aiSettings
        if let value = arguments.readOnly { settings.readOnly = value }
        if let value = arguments.askBeforeDestructive { settings.askBeforeDestructive = value }
        if let value = arguments.httpEnabled { settings.httpEnabled = value }
        session.aiSettings = settings
        return settings
    }
}

public enum LogClearCommand: EditorCommand {
    public static let id: CommandID = "log.clear"
    public static let title = "Clear Console"
    public static let doc = "Clears the console (log.read then starts from the next message)."
    public static let isIdempotent = true
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.log.clear()
        return NoResult()
    }
}
