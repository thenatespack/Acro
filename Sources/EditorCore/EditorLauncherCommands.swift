import Engine
import Foundation

// The launcher's commands (LauncherPanel.swift): the recent projects list and showing or
// leaving the start screen. Opening and creating projects are `project.open` (with
// `openLastScene`, as the launcher opens them) and `project.new` (with `name`, `location` and a
// `template`). The list lives in the session (`recentProjects`), so these run headless too;
// showing the launcher needs the editor's UI.
//
// ```text
// project.recent.list {query: "space"}     → projects: name, path, lastOpened, pinned, game, missing…
// project.open {path: "Space Game", openLastScene: true}
// launcher.show {confirm: true}             → the project closes, the start screen shows
// project.recent.pin {path: "~/Games/Space Game"}
// ```

@MainActor
public enum EditorLauncherCommands {
    public static let all: [any EditorCommand.Type] = [
        LauncherShowCommand.self, LauncherDismissCommand.self, LauncherSettingsCommand.self,
        ProjectRecentListCommand.self, ProjectRecentRemoveCommand.self, ProjectRecentPinCommand.self,
        ProjectRecentLocateCommand.self, ProjectRecentRevealCommand.self,
    ]
}

private let noLauncherUIReason = "the launcher needs the editor's UI (a window, or Editor --headless)"

/// One recent project as the tools report it.
public struct RecentProjectInfo: Codable, Equatable, Sendable {
    public var name: String
    /// The project folder.
    public var path: String
    /// When it was last opened (ISO 8601).
    public var lastOpened: String
    /// The same, as the launcher shows it ("2 hours ago").
    public var lastOpenedText: String
    public var pinned: Bool
    /// Project.json has game code (`"game"`).
    public var game: Bool
    /// The folder (or its Project.json) is gone: project.recent.locate or project.recent.remove it.
    public var missing: Bool
    /// The launcher's thumbnail of it (a PNG in its Library/), if one was made.
    public var thumbnail: String?
    /// The scene last opened in it (project.open with openLastScene opens it).
    public var lastScene: String?

    @MainActor init(_ entry: RecentProject, now: Date) {
        name = entry.name
        path = entry.path
        lastOpened = ISO8601DateFormatter().string(from: entry.lastOpened)
        lastOpenedText = RecentProjectList.relativeTime(entry.lastOpened, now: now)
        pinned = entry.pinned
        game = entry.hasGame
        missing = entry.isMissing
        let thumbnail = entry.thumbnailURL.path
        self.thumbnail = !missing && FileManager.default.fileExists(atPath: thumbnail) ? thumbnail : nil
        lastScene = entry.lastScene
    }
}

/// The entry `path` names, or a failure that says what the list has.
@MainActor private func recentEntry(_ path: String, in session: EditorSession, _ title: String) throws -> RecentProject {
    guard let entry = session.recentProjects.entry(path) else {
        let message = "\(title): '\(path)' isn't in the recent projects (project.recent.list lists them)"
        session.log.error(message)
        throw CommandError.failed(message)
    }
    return entry
}

public enum LauncherShowCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        /// The project that was closed, if one was open.
        public var closedProject: String?
        public var launcherShown: Bool
    }

    public static let id: CommandID = "launcher.show"
    public static let title = "Close Project"
    public static let doc = "Closes the open project (if any) and shows the launcher: the start screen with the recent projects, New Project and Open. The scene is replaced with a new starter scene, so unsaved changes are lost. Not while playing."
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when the open scene has unsaved changes"
    public static func needsConfirmation(_ arguments: NoArguments, in session: EditorSession) -> Bool { session.document.isDirty }
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil && !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.uiApp == nil ? noLauncherUIReason : EditorError.playing.description
    }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        guard let app = session.uiApp else { throw CommandError.failed(noLauncherUIReason) }
        let closed = session.project?.name
        try session.commands.check(app.showLauncher(), title)
        return Result(closedProject: closed, launcherShown: app.isLauncherShown)
    }
}

public enum LauncherDismissCommand: EditorCommand {
    public static let id: CommandID = "launcher.dismiss"
    public static let title = "Continue Without a Project"
    public static let doc = "Leaves the launcher for the editor without opening a project (the starter scene; no assets)."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp?.isLauncherShown == true }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.uiApp == nil ? noLauncherUIReason : "the launcher isn't shown (launcher.show shows it)"
    }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> NoResult {
        session.uiApp?.hideLauncher()
        return NoResult()
    }
}

public enum LauncherSettingsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Skip the launcher at startup and reopen the last project (when the editor starts
        /// without --project, a scene or --launcher).
        public var reopenLastProject: Bool?
        public init(reopenLastProject: Bool? = nil) { self.reopenLastProject = reopenLastProject }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var reopenLastProject: Bool
        public var launcherShown: Bool
    }

    public static let id: CommandID = "launcher.settings"
    public static let title = "Launcher Settings"
    public static let doc = "Whether the editor skips the launcher at startup and reopens the last project (`reopenLastProject`, saved in the prefs). Returns the settings and whether the launcher is shown."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if let value = arguments.reopenLastProject { session.recentProjects.reopensLastProject = value }
        return Result(reopenLastProject: session.recentProjects.reopensLastProject, launcherShown: session.uiApp?.isLauncherShown ?? false)
    }
}

public enum ProjectRecentListCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only projects whose name or path contains every word of this (ignoring case).
        public var query: String?
        public init(query: String? = nil) { self.query = query }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Pinned first, then the most recently opened.
        public var projects: [RecentProjectInfo]
        /// The open project's folder, if one is open.
        public var openProject: String?
        public var launcherShown: Bool
        public var reopenLastProject: Bool
    }

    public static let id: CommandID = "project.recent.list"
    public static let title = "Recent Projects"
    public static let doc = "The recent projects as the launcher lists them (pinned first, then by last opened; at most 20 besides the pinned): name, folder, when last opened, pinned, whether it has game code, whether its folder is missing, its thumbnail and last scene. project.open {path, openLastScene: true} opens one as the launcher does."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let list = session.recentProjects
        let now = list.now()
        return Result(projects: list.filtered(arguments.query ?? "").map { RecentProjectInfo($0, now: now) },
                      openProject: session.project?.root.path, launcherShown: session.uiApp?.isLauncherShown ?? false,
                      reopenLastProject: list.reopensLastProject)
    }
}

public enum ProjectRecentRemoveCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project's folder (any spelling) or its name, as project.recent.list gives it.
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "project.recent.remove"
    public static let title = "Remove from List"
    public static let doc = "Takes a project off the recent projects list (the folder isn't touched)."
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let entry = try recentEntry(arguments.path, in: session, title)
        session.recentProjects.remove(entry.path)
        return PathResult(path: entry.path)
    }
}

public enum ProjectRecentPinCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project's folder (any spelling) or its name.
        public var path: String
        /// Pin (default) or unpin.
        public var pinned: Bool?
        public init(path: String, pinned: Bool? = nil) {
            self.path = path
            self.pinned = pinned
        }
    }

    public static let id: CommandID = "project.recent.pin"
    public static let title = "Pin Project"
    public static let doc = "Pins a recent project to the top of the list (`pinned: false` unpins it). Pinned projects are never dropped from the list."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> RecentProjectInfo {
        let entry = try recentEntry(arguments.path, in: session, title)
        session.recentProjects.setPinned(arguments.pinned ?? true, entry.path)
        let list = session.recentProjects
        return RecentProjectInfo(list.entry(entry.path) ?? entry, now: list.now())
    }
}

public enum ProjectRecentLocateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The (missing) project's folder as listed, or its name.
        public var path: String
        /// Where the project is now: its folder or its Project.json.
        public var newPath: String
        public init(path: String, newPath: String) {
            self.path = path
            self.newPath = newPath
        }
    }

    public static let id: CommandID = "project.recent.locate"
    public static let title = "Locate Project"
    public static let doc = "Points a recent project whose folder moved (missing in project.recent.list) at its new folder, keeping its place, pin and last scene. `newPath` must hold a Project.json."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> RecentProjectInfo {
        let entry = try recentEntry(arguments.path, in: session, title)
        guard let url = session.fileURL(forPath: arguments.newPath, title) else {
            throw CommandError.failed(session.log.entries.last?.message ?? "\(title): \(arguments.newPath) is outside the project folder")
        }
        let project: Project
        do {
            project = try Project.open(at: url)
        } catch {
            let message = "\(title): \(error)"
            session.log.error(message)
            throw CommandError.failed(message)
        }
        session.recentProjects.relocate(entry.path, to: project)
        session.log.info("\(entry.name) is now at \(project.root.path)")
        let list = session.recentProjects
        return RecentProjectInfo(list.entry(project.root.path) ?? entry, now: list.now())
    }
}

public enum ProjectRecentRevealCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project's folder (any spelling) or its name.
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "project.recent.reveal"
    public static let title = "Show in Finder"
    public static let doc = "Shows a recent project's folder in the Finder (macOS; elsewhere it only returns the folder's path, which the launcher's Copy Path puts on the clipboard)."
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let entry = try recentEntry(arguments.path, in: session, title)
        guard !entry.isMissing else {
            let message = "\(title): \(entry.path) is missing (project.recent.locate points it at its new folder)"
            session.log.error(message)
            throw CommandError.failed(message)
        }
        #if os(macOS)
        // Only with a window (never from tests or headless runs).
        if session.uiApp?.canRender == true {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-R", entry.path]
            try? process.run()
        }
        #endif
        return PathResult(path: entry.path)
    }
}
