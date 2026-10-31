import Engine
import Foundation

// Commands for the game module (EditorGameModule.swift): load, reload, unload, info.

public enum EditorGameModuleCommands {
    public static let all: [any EditorCommand.Type] = [
        GameReloadCommand.self, GameLoadCommand.self, GameUnloadCommand.self, GameInfoCommand.self,
    ]
}

extension CommandID {
    public static let reloadGame: CommandID = "game.reload"
}

public enum GameReloadCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// false skips the build and relinks the objects already built (default true).
        public var build: Bool?
        public init(build: Bool? = nil) { self.build = build }
    }

    public typealias Result = GameReloadReport

    public static let id: CommandID = .reloadGame
    public static let title = "Reload Game Code"
    public static let doc = """
        Rebuilds the game module in the background (one direct `swiftc` call for the game target once a build plan is \
        cached, else `swift build --target <game>`, or its build command), then swaps it in with the scene kept: game \
        components (scene, play snapshot, undo history) are serialized, the old code's willUnload state saved, the new \
        types registered and the components restored (new fields get defaults, removed fields are dropped, components \
        whose type is gone stay as JSON), the new code's didLoad given the state; play mode goes on with the new \
        systems. Build errors go to the console and the old code keeps running. Returns what changed, how it was built \
        and the build, link, load and swap times. Keeps the undo history.
        """
    public static func isAvailable(in session: EditorSession) -> Bool {
        session.gameModule.isConfigured && !session.gameModule.isBusy && session.batch == nil
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        let game = session.gameModule
        if !game.isConfigured { return "no game module (start the editor with --game, or set \"game\" in Project.json)" }
        if game.isBusy { return "the game is already being rebuilt" }
        if session.batch != nil { return "a batch is open (edit.endBatch first)" }
        return nil
    }
    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<GameReloadReport> {
        try session.gameModule.reload(build: arguments.build ?? true)
    }
}

public enum GameLoadCommand: EditorDeferredCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A SwiftPM target to build and link ("SampleGame").
        public var target: String?
        /// Or a prebuilt module (.dylib / .so); relative paths from the project folder (or the working directory).
        public var library: String?
        /// The package folder holding `target`; default: the nearest Package.swift above the project folder.
        public var package: String?
        /// Build first (default true; false links what is already built).
        public var build: Bool?
        /// Reload when the target's sources change.
        public var watch: Bool?

        public init(target: String? = nil, library: String? = nil, package: String? = nil, build: Bool? = nil, watch: Bool? = nil) {
            self.target = target
            self.library = library
            self.package = package
            self.build = build
            self.watch = watch
        }
    }

    public typealias Result = GameReloadReport

    public static let id: CommandID = "game.load"
    public static let title = "Load Game Code"
    public static let doc = """
        Loads game code: a SwiftPM `target` (built, then its objects linked into a module) or a prebuilt `library`. Its \
        components become addable and its systems run in play mode; scene components of its types are restored. Replaces \
        the module loaded before, like game.reload.
        """
    public static func isAvailable(in session: EditorSession) -> Bool { !session.gameModule.isBusy && session.batch == nil }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.gameModule.isBusy ? "the game is being rebuilt" : session.batch != nil ? "a batch is open" : nil
    }
    public static func start(_ arguments: Arguments, in session: EditorSession) throws -> CommandFuture<GameReloadReport> {
        guard (arguments.target == nil) != (arguments.library == nil) else {
            throw CommandError.failed("Give either a target or a library")
        }
        let base = session.project?.root ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let settings = GameModuleSettings(target: arguments.target, package: arguments.package, library: arguments.library,
                                          watch: arguments.watch)
        // Loading runs the library's code and building runs the package's: AI clients only
        // inside the project folder (the sandbox).
        if let library = arguments.library {
            guard session.checkFileAccess(URL(fileURLWithPath: library, relativeTo: base).standardizedFileURL, title) else {
                throw CommandError.failed("The library is outside the project folder")
            }
        }
        let previous = (session.gameModule.settings, session.gameModule.baseURL)
        session.gameModule.configure(settings, base: base)
        if arguments.target != nil {
            let package = try session.gameModule.packageURL()
            guard session.checkFileAccess(package, title) else {
                session.gameModule.configure(previous.0, base: previous.1)
                throw CommandError.failed("The package is outside the project folder")
            }
        }
        return try session.gameModule.reload(build: arguments.build ?? true)
    }
}

public enum GameUnloadCommand: EditorCommand {
    public static let id: CommandID = "game.unload"
    public static let title = "Unload Game Code"
    public static let doc = "Unloads the game module: its systems stop, its components stay in the scene (and the undo history) as JSON (saved unchanged) until game code with those types is loaded again; its willUnload state is kept for the next load."
    public static func isAvailable(in session: EditorSession) -> Bool {
        session.gameModule.loaded != nil && !session.gameModule.isBusy && session.batch == nil
    }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.gameModule.loaded == nil ? "no game module is loaded" : session.gameModule.isBusy ? "the game is being rebuilt" : nil
    }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        try session.gameModule.unload()
        return NoResult()
    }
}

public enum GameInfoCommand: EditorCommand {
    public static let id: CommandID = "game.info"
    public static let title = "Game Code Info"
    public static let doc = "The game module: where it comes from, whether it is loaded, its components and systems, whether a rebuild is running, the last error and the last reload's report (timings, restored and dropped components), and components the scene holds as JSON because their type isn't loaded."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> GameInfoResult {
        session.gameModule.info
    }
}
