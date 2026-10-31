import Engine
import Foundation

// Every editor action as a named command.
//
// ```swift
// try session.commands.run(EntityCreateCommand.self, .init(template: .cube))     // typed
// let json = try session.commands.run("entity.rename",
//                                     json: #"{"entity": "…", "name": "Crate"}"#.data(using: .utf8))  // generic
// session.commands.isAvailable("edit.undo")                                       // enabled state
// session.run(EntityDuplicateCommand.self)                                        // the UI: failures are logged
// ```
//
// ## Commands
//
// A command is a type conforming to `EditorCommand`: a stable `id` ("scene.save"), a title and a
// doc string, a Codable `Arguments` and `Result`, `isAvailable(in:)` (what enables a button or
// menu item) and `run`. Commands act on an `EditorSession` only, never on widgets, so they run
// headless: tests and the MCP server (EditorMCP.swift) call them exactly as the toolbar does. Undoable
// commands make their edits through the session's `UndoStack` as one step, so undo / redo take
// back what a command did. Asking the user (a confirmation dialog, a file picker) stays in the
// UI: it asks, then runs the command with the answer as arguments.
//
// ## The registry
//
// `CommandRegistry` (the session's `commands`) holds every command by id: `all` lists them
// (`CommandInfo`: id, title, doc, undoable, the argument and result type names), `run(_:json:)`
// decodes the arguments from JSON, runs the command and encodes the result as JSON, which is all a
// transport needs. A run checks `isAvailable` first (throwing `CommandError.unavailable`), and
// every failure is logged to the session's log once (by the command or by the registry) and
// thrown, so `try?` in the UI loses nothing.
//
// Hosts add what only they can do (reset the dock layout, frame the camera) through
// `EditorHost`; the commands that need it are unavailable without one.

/// A command's stable identifier, e.g. "entity.duplicate". Keyboard shortcuts are bound to these.
public struct CommandID: Hashable, Comparable, Sendable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }

    public init(from decoder: any Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }
    public static func < (a: CommandID, b: CommandID) -> Bool { a.rawValue < b.rawValue }
}

/// The arguments of a command that takes none (`{}` in JSON).
public struct NoArguments: Codable, Equatable, Sendable {
    public init() {}
}

/// The result of a command that returns nothing (`{}` in JSON).
public struct NoResult: Codable, Equatable, Sendable {
    public init() {}
}

/// A named editor action. See the notes at the top of this file.
@MainActor
public protocol EditorCommand {
    associatedtype Arguments: Codable = NoArguments
    associatedtype Result: Codable = NoResult

    /// Stable, namespaced id ("scene.save"): what shortcuts, menus and transports refer to.
    static var id: CommandID { get }
    /// Short title for menus and logs ("Save Scene").
    static var title: String { get }
    /// What it does and what its arguments mean, for documentation and tool listings.
    static var doc: String { get }
    /// Whether a run is recorded as one undo step.
    static var isUndoable: Bool { get }
    /// Whether it only reads (changes neither the document, the project nor the editor's state).
    /// Default false. Remote callers (MCP's `readOnlyHint`) may run read-only commands without asking.
    static var isReadOnly: Bool { get }
    /// Whether it can lose work that undo can't bring back: deletes or overwrites files, or
    /// replaces an unsaved scene. Default false (MCP's `destructiveHint`).
    static var isDestructive: Bool { get }
    /// Whether running it again with the same arguments changes nothing more. Default false
    /// (MCP's `idempotentHint`).
    static var isIdempotent: Bool { get }
    /// Whether it can run now (enables its button or menu item). `run` checks it first.
    static func isAvailable(in session: EditorSession) -> Bool
    /// Why it can't run now, when `isAvailable` is false ("nothing is selected"). The default
    /// names play mode when playing, else nil.
    static func unavailableReason(in session: EditorSession) -> String?
    /// Does it. Throws, after logging, when it can't (the arguments name something missing).
    static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result
}

extension EditorCommand {
    public static var isUndoable: Bool { false }
    public static var isReadOnly: Bool { false }
    public static var isDestructive: Bool { false }
    public static var isIdempotent: Bool { false }
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.isPlaying ? EditorError.playing.description : nil
    }
}

public enum CommandError: Error, Equatable, CustomStringConvertible {
    /// No command is registered with this id.
    case unknownCommand(CommandID)
    /// `isAvailable` is false right now (`reason` says why, when known).
    case unavailable(CommandID, reason: String?)
    /// The JSON arguments don't decode as the command's `Arguments`.
    case invalidArguments(CommandID, String)
    /// The command ran and failed; the message was logged.
    case failed(String)

    public var description: String {
        switch self {
        case .unknownCommand(let id): "No command '\(id)'"
        case .unavailable(let id, let reason): "'\(id)' isn't available now" + (reason.map { ": \($0)" } ?? "")
        case .invalidArguments(let id, let message): "Invalid arguments for '\(id)': \(message)"
        case .failed(let message): message
        }
    }
}

/// What the registry lists about a command.
public struct CommandInfo: Equatable, Sendable, Codable {
    public var id: CommandID
    public var title: String
    public var doc: String
    public var isUndoable: Bool
    public var isReadOnly: Bool
    public var isDestructive: Bool
    public var isIdempotent: Bool
    /// The Swift names of the `Arguments` and `Result` types.
    public var argumentsType: String
    public var resultType: String
}

/// What only the application hosting the session can do: things that live in widgets or the
/// viewport, not in the document. Commands that need it are unavailable without a host (tests).
@MainActor
public protocol EditorHost: AnyObject {
    /// Restores the default dock layout.
    func resetLayout()
    /// Frames the selected entities in the viewport camera.
    func frameSelection()
}

/// The session's commands, by id. See the notes at the top of this file.
@MainActor
public final class CommandRegistry {
    private struct Entry {
        var info: CommandInfo
        var argumentsType: any Codable.Type
        var resultType: any Codable.Type
        var isAvailable: @MainActor (EditorSession) -> Bool
        var unavailableReason: @MainActor (EditorSession) -> String?
        var runJSON: @MainActor (Data, EditorSession) throws -> Data
    }

    public unowned let session: EditorSession
    private var entries: [CommandID: Entry] = [:]
    /// The log's next sequence number when each running command started (innermost last).
    private var logMarks: [Int] = []
    /// Increases whenever a command is registered (for transports that list them).
    public private(set) var revision = 0

    public init(session: EditorSession) {
        self.session = session
    }

    /// Adds `command` (replacing one with the same id).
    public func register<C: EditorCommand>(_ command: C.Type) {
        let info = CommandInfo(id: C.id, title: C.title, doc: C.doc, isUndoable: C.isUndoable, isReadOnly: C.isReadOnly,
                               isDestructive: C.isDestructive, isIdempotent: C.isIdempotent,
                               argumentsType: String(describing: C.Arguments.self), resultType: String(describing: C.Result.self))
        revision += 1
        entries[C.id] = Entry(info: info, argumentsType: C.Arguments.self, resultType: C.Result.self,
                              isAvailable: { C.isAvailable(in: $0) }, unavailableReason: { C.unavailableReason(in: $0) },
                              runJSON: { [unowned self] data, _ in
            let arguments: C.Arguments
            do {
                arguments = try JSONDecoder().decode(C.Arguments.self, from: data.isEmpty ? Data("{}".utf8) : data)
            } catch {
                let failure = CommandError.invalidArguments(C.id, Self.describe(error))
                session.log.error(failure.description)
                throw failure
            }
            let result = try run(C.self, arguments)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return try encoder.encode(result)
        })
    }

    public func register(_ commands: [any EditorCommand.Type]) {
        for command in commands { register(command) }
    }

    /// Every command, sorted by id.
    public var all: [CommandInfo] { entries.values.map(\.info).sorted { $0.id < $1.id } }

    public func info(_ id: CommandID) -> CommandInfo? { entries[id]?.info }

    public func contains(_ id: CommandID) -> Bool { entries[id] != nil }

    /// Whether the command `id` exists and can run now.
    public func isAvailable(_ id: CommandID) -> Bool {
        entries[id]?.isAvailable(session) ?? false
    }

    public func isAvailable<C: EditorCommand>(_ command: C.Type) -> Bool { C.isAvailable(in: session) }

    /// Why the command `id` can't run now (see `EditorCommand.unavailableReason(in:)`).
    public func unavailableReason(_ id: CommandID) -> String? {
        entries[id]?.unavailableReason(session)
    }

    /// The command's `Arguments` and `Result` types (for deriving schemas).
    public func types(of id: CommandID) -> (arguments: any Codable.Type, result: any Codable.Type)? {
        entries[id].map { ($0.argumentsType, $0.resultType) }
    }

    /// Runs `command` with `arguments`: checks availability, runs it and logs a failure the
    /// command didn't log itself. Throws `CommandError`s or the command's error.
    @discardableResult
    public func run<C: EditorCommand>(_ command: C.Type, _ arguments: C.Arguments) throws -> C.Result {
        let mark = session.log.nextSequence
        guard C.isAvailable(in: session) else {
            let failure = CommandError.unavailable(C.id, reason: C.unavailableReason(in: session))
            session.log.warning("\(C.title): \(failure)")
            throw failure
        }
        logMarks.append(mark)
        defer { logMarks.removeLast() }
        do {
            return try C.run(arguments, in: session)
        } catch {
            if session.log.problem(since: mark) == nil { session.log.error("\(C.title) failed: \(Self.describe(error))") }
            throw error
        }
    }

    @discardableResult
    public func run<C: EditorCommand>(_ command: C.Type) throws -> C.Result where C.Arguments == NoArguments {
        try run(command, NoArguments())
    }

    /// Runs the command `id` with JSON-encoded arguments (empty data or nil: `{}`) and returns
    /// its JSON-encoded result.
    @discardableResult
    public func run(_ id: CommandID, json arguments: Data? = nil) throws -> Data {
        guard let entry = entries[id] else {
            let failure = CommandError.unknownCommand(id)
            session.log.error(failure.description)
            throw failure
        }
        return try entry.runJSON(arguments ?? Data(), session)
    }

    /// For commands built on session methods that log their failures and return false / nil:
    /// throws `CommandError.failed` with the newest warning or error logged since the running
    /// command started when `succeeded` is false.
    func check(_ succeeded: Bool, _ title: String) throws {
        guard !succeeded else { return }
        throw CommandError.failed(logMarks.last.flatMap { session.log.problem(since: $0) } ?? "\(title) failed")
    }

    /// `value`, or throws like `check(false, title)` when it is nil.
    func require<T>(_ value: T?, _ title: String) throws -> T {
        try check(value != nil, title)
        return value!
    }

    private static func describe(_ error: any Error) -> String {
        switch error {
        case DecodingError.keyNotFound(let key, _): "missing '\(key.stringValue)'"
        case DecodingError.typeMismatch(_, let context), DecodingError.valueNotFound(_, let context),
             DecodingError.dataCorrupted(let context):
            (context.codingPath.isEmpty ? "" : "'\(context.codingPath.map(\.stringValue).joined(separator: "."))': ")
                + context.debugDescription
        default: String(describing: error)
        }
    }
}

extension EditorLog {
    /// The newest warning or error logged at or after sequence `mark`.
    func problem(since mark: Int) -> String? {
        entries.last { $0.sequence >= mark && $0.level >= .warning }?.message
    }
}

extension EditorSession {
    /// Runs `command` for the UI: failures are logged (by the registry), so they only show as
    /// a nil result.
    @discardableResult
    public func run<C: EditorCommand>(_ command: C.Type, _ arguments: C.Arguments) -> C.Result? {
        try? commands.run(command, arguments)
    }

    @discardableResult
    public func run<C: EditorCommand>(_ command: C.Type) -> C.Result? where C.Arguments == NoArguments {
        try? commands.run(command)
    }

    /// Runs the command `id` with default (`{}`) arguments for the UI (shortcuts).
    public func run(_ id: CommandID) {
        _ = try? commands.run(id)
    }
}
