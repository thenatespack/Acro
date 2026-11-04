import Engine
import Foundation

// The Files panel's commands: the project's scenes and scripts as one folder tree, opening one
// (a scene in the Scene view, a script in the Scripts editor beside it) and making a scene.
// The Files panel is where the editor's UI creates and switches scenes.

@MainActor
public enum EditorFilesCommands {
    public static let all: [any EditorCommand.Type] = [FilesListCommand.self, FilesOpenCommand.self, FilesNewSceneCommand.self]
}

/// A scene or script the Files panel shows.
public struct ProjectFile: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case scene, script }
    /// Shown path, "/"-separated: from the project folder ("Assets/Scenes/Main.scene",
    /// "Sources/SampleGame/Player.swift"), or from the script folder's parent when it is elsewhere.
    public var path: String
    /// The file on disk.
    public var absolutePath: String
    public var kind: Kind

    public init(path: String, absolutePath: String, kind: Kind) {
        self.path = path
        self.absolutePath = absolutePath
        self.kind = kind
    }
}

extension EditorSession {
    /// The folder `ProjectFile.path` is relative to: the project's, else the start folder.
    var filesBase: URL { (project?.root ?? startFolder).standardizedFileURL }

    /// The project's scenes (`.scene` under `Assets/`) and scripts (`projectScripts()`), sorted by path.
    public func projectFiles() -> [ProjectFile] {
        let base = filesBase
        func shown(_ url: URL, root: URL?) -> String {
            if Self.isInside(url, base) {
                return String(Self.resolved(url).path.dropFirst(Self.resolved(base).path.count + 1))
            }
            // A game package outside the project: name it from its script folder.
            if let root, Self.isInside(url, root) {
                let rest = String(Self.resolved(url).path.dropFirst(Self.resolved(root).path.count + 1))
                return root.lastPathComponent + "/" + rest
            }
            return url.lastPathComponent
        }
        var files: [ProjectFile] = []
        let sceneRoot = project?.assetsURL ?? startFolder.appendingPathComponent(Project.assetsFolder, isDirectory: true)
        if let found = FileManager.default.enumerator(at: sceneRoot, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for case let url as URL in found where url.pathExtension.lowercased() == "scene" {
                let url = url.standardizedFileURL
                files.append(ProjectFile(path: shown(url, root: sceneRoot), absolutePath: url.path, kind: .scene))
            }
        }
        let roots = scriptRoots
        for url in projectScripts() {
            let root = roots.first { Self.isInside(url, $0) }
            files.append(ProjectFile(path: shown(url, root: root), absolutePath: url.path, kind: .script))
        }
        var seen = Set<String>()
        return files.filter { seen.insert($0.absolutePath).inserted }.sorted { $0.path < $1.path }
    }
}

public struct FilesListResult: Codable, Equatable, Sendable {
    public var files: [ProjectFile]
    public init(files: [ProjectFile]) { self.files = files }
}

public enum FilesListCommand: EditorCommand {
    public static let id: CommandID = "files.list"
    public static let title = "List Files"
    public static let doc = "Lists what the Files panel shows: the project's scenes (.scene under Assets/) and its own scripts (script.list), with paths from the project folder."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> FilesListResult {
        FilesListResult(files: session.projectFiles())
    }
}

public enum FilesOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A path from files.list (relative to the project folder, or absolute).
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "files.open"
    public static let title = "Open File"
    public static let doc = "Opens a file from the Files panel: a scene replaces the open scene and shows the Scene view (as scene.open), a script opens in the Scripts editor tabbed with the Scene view (as script.open). Not for scenes while playing."
    public static let isDestructive = true
    public static let confirmsOnlyWhen: String? = "when `path` is a scene (it replaces the open scene); opening a script needs no confirm"
    public static func needsConfirmation(_ arguments: Arguments, in session: EditorSession) -> Bool {
        !arguments.path.lowercased().hasSuffix(".swift")
    }
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let file = (arguments.path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: file, relativeTo: session.filesBase).standardizedFileURL
        switch url.pathExtension.lowercased() {
        case "swift":
            let result = try ScriptOpenCommand.run(.init(path: url.path), in: session)
            return PathResult(path: result.path)
        case "scene":
            guard !session.isPlaying else { throw CommandError.failed("\(title): stop playing before opening a scene") }
            let result = try SceneOpenCommand.run(.init(path: url.path), in: session)
            session.uiApp?.sceneOpenedFromFiles()
            return result
        default:
            throw CommandError.failed("\(title): \(arguments.path) is neither a scene (.scene) nor a script (.swift)")
        }
    }
}

public enum FilesNewSceneCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The scene's file name ("Level 2" or "Level 2.scene").
        public var name: String
        /// "starter" (default: a camera, a sun, a floor and a few primitives) or "empty".
        public var template: String?
        public init(name: String, template: String? = nil) {
            self.name = name
            self.template = template
        }
    }

    public static let id: CommandID = "files.newScene"
    public static let title = "New Scene"
    public static let doc = "Creates a scene file in the project's Assets/Scenes/ (Assets/ without a project), saves it and opens it in the Scene view, as the Files panel's New Scene does. Refuses a name that exists. The open scene is replaced (unsaved changes are lost). Not while playing."
    public static let isDestructive = true
    public static func isAvailable(in session: EditorSession) -> Bool { !session.isPlaying }

    /// Where `files.newScene` puts scenes.
    @MainActor public static func scenesFolder(in session: EditorSession) -> URL {
        let assets = session.project?.assetsURL ?? session.startFolder.appendingPathComponent(Project.assetsFolder, isDirectory: true)
        return assets.appendingPathComponent("Scenes", isDirectory: true)
    }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        var name = arguments.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasSuffix(".scene") { name = String(name.dropLast(".scene".count)) }
        guard !name.isEmpty, !name.contains("/"), !name.contains("\\"), !name.hasPrefix(".") else {
            throw CommandError.failed("\(title): the name must be a plain file name")
        }
        let url = scenesFolder(in: session).appendingPathComponent(name + ".scene")
        guard session.checkFileAccess(url, title) else {
            throw CommandError.failed("\(title): \(url.path) is outside the project folder")
        }
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw CommandError.failed("\(title): \(url.lastPathComponent) already exists")
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = try SceneNewCommand.run(.init(template: arguments.template), in: session)
        _ = try SceneSaveCommand.run(.init(path: url.path), in: session)
        session.uiApp?.sceneOpenedFromFiles()
        return PathResult(path: url.path)
    }
}
