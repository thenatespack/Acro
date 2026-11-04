import Engine
import Foundation

@MainActor
public enum EditorScriptCommands {
    public static let all: [any EditorCommand.Type] = [
        ScriptOpenCommand.self,
        ScriptSaveCommand.self,
        ScriptNewCommand.self,
        ScriptListCommand.self,
    ]
}

// MARK: - Project script scope

extension EditorSession {
    /// Folders that hold the project's own game scripts (the ones a user creates, such as
    /// `CameraController.swift`). Script tools only list, open and save `.swift` files inside
    /// these, never engine or editor sources that happen to sit next to the project.
    public var scriptRoots: [URL] {
        var roots: [URL] = []
        if let target = gameModule.settings?.target, let packageURL = try? gameModule.packageURL() {
            roots.append(packageURL.appendingPathComponent("Sources/\(target)", isDirectory: true))
        }
        if let project {
            roots.append(project.root.appendingPathComponent("Sources/\(project.name)", isDirectory: true))
            roots.append(project.root.appendingPathComponent("Scripts", isDirectory: true))
            roots.append(project.assetsURL)
        } else {
            roots.append(startFolder.appendingPathComponent("Scripts", isDirectory: true))
        }
        var seen = Set<String>()
        return roots.map(\.standardizedFileURL).filter { seen.insert($0.path).inserted }
    }

    /// Where new scripts go: the first script root.
    public var scriptDestination: URL { scriptRoots[0] }

    /// Whether `url` is a project script: a `.swift` file inside one of `scriptRoots`.
    public func isProjectScript(_ url: URL) -> Bool {
        url.pathExtension == "swift" && scriptRoots.contains { Self.isInside(url, $0) }
    }

    /// Every project script, sorted by path.
    public func projectScripts() -> [URL] {
        var found: [URL] = []
        var seen = Set<String>()
        for root in scriptRoots {
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey],
                                                                 options: [.skipsHiddenFiles]) else { continue }
            for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
                let url = fileURL.standardizedFileURL
                if seen.insert(url.path).inserted { found.append(url) }
            }
        }
        return found.sorted { $0.path < $1.path }
    }

    func checkProjectScript(_ url: URL, _ action: String) throws {
        guard isProjectScript(url) else {
            let allowed = scriptRoots.map(\.path).joined(separator: ", ")
            log.error("\(action): \(url.path) is not a project script (scripts live in \(allowed))")
            throw CommandError.failed("\(url.path) is not a project script; only .swift files in the project's script folders can be opened or saved")
        }
    }
}

public struct ScriptOpenResult: Codable, Equatable, Sendable {
    public var path: String
    public var content: String
    public var lineCount: Int

    public init(path: String, content: String, lineCount: Int) {
        self.path = path
        self.content = content
        self.lineCount = lineCount
    }
}

public enum ScriptOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String
        public init(path: String) { self.path = path }
    }

    public static let id: CommandID = "script.open"
    public static let title = "Open Script"
    public static let doc = "Opens a project Swift game script by file path, reading its content and showing it in the editor. Only files listed by script.list can be opened."

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptOpenResult {
        let base = session.project?.root ?? session.startFolder
        let url = URL(fileURLWithPath: arguments.path, relativeTo: base).standardizedFileURL
        try session.checkProjectScript(url, title)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CommandError.failed("No script at \(arguments.path)")
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw CommandError.failed("Could not read script at \(arguments.path)")
        }

        session.onOpenScript?(url.path)
        let lines = content.components(separatedBy: "\n").count
        return ScriptOpenResult(path: url.path, content: content, lineCount: lines)
    }
}

public struct ScriptSaveResult: Codable, Equatable, Sendable {
    public var path: String
    public var saved: Bool
    public var reloaded: Bool

    public init(path: String, saved: Bool, reloaded: Bool) {
        self.path = path
        self.saved = saved
        self.reloaded = reloaded
    }
}

public enum ScriptSaveCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String
        public var content: String
        public var reload: Bool?

        public init(path: String, content: String, reload: Bool? = true) {
            self.path = path
            self.content = content
            self.reload = reload
        }
    }

    public static let id: CommandID = "script.save"
    public static let title = "Save Script"
    public static let doc = "Saves code to a project Swift game script and optionally triggers hot reloading. Only project script folders can be written."

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptSaveResult {
        let base = session.project?.root ?? session.startFolder
        let url = URL(fileURLWithPath: arguments.path, relativeTo: base).standardizedFileURL
        try session.checkProjectScript(url, title)

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try arguments.content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw CommandError.failed("Could not write script: \(error)")
        }

        var reloaded = false
        if arguments.reload ?? true, session.gameModule.isConfigured, !session.gameModule.isBusy {
            _ = try? session.commands.start(GameReloadCommand.self, .init(build: true))
            reloaded = true
        }

        session.onOpenScript?(url.path)
        return ScriptSaveResult(path: url.path, saved: true, reloaded: reloaded)
    }
}

public struct ScriptNewResult: Codable, Equatable, Sendable {
    public var path: String
    public var created: Bool

    public init(path: String, created: Bool) {
        self.path = path
        self.created = created
    }
}

public enum ScriptNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var name: String
        public var template: String?

        public init(name: String, template: String? = nil) {
            self.name = name
            self.template = template
        }
    }

    public static let id: CommandID = "script.new"
    public static let title = "New Script"
    public static let doc = "Creates a new Swift game script file with standard component boilerplate."

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptNewResult {
        var rawName = arguments.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawName.isEmpty else { throw CommandError.failed("Script name cannot be empty") }
        if !rawName.hasSuffix(".swift") { rawName += ".swift" }

        let componentName = String(rawName.dropLast(".swift".count))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "_")

        guard !rawName.contains("/"), !rawName.contains("\\"), rawName != ".swift" else {
            throw CommandError.failed("Script name must be a plain file name")
        }

        let destinationDir = session.scriptDestination
        let fileURL = destinationDir.appendingPathComponent(rawName)
        try session.checkProjectScript(fileURL, title)
        guard session.checkFileAccess(fileURL, title) else {
            throw CommandError.failed("Script destination is outside the project folder")
        }

        let code = arguments.template ?? """
        import Engine
        import Foundation

        /// Custom game component.
        public struct \(componentName): Component, Equatable, Sendable {
            public static let componentName = "\(componentName)"
            public static var fieldHints: [String: FieldHints] {
                ["speed": FieldHints(range: 0...20, step: 0.1, tooltip: "Movement speed")]
            }

            public var speed: Float = 2.0

            public init(speed: Float = 2.0) {
                self.speed = speed
            }
        }

        """

        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            try code.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw CommandError.failed("Could not create script file: \(error)")
        }

        session.onOpenScript?(fileURL.path)
        return ScriptNewResult(path: fileURL.path, created: true)
    }
}

public struct ScriptListResult: Codable, Equatable, Sendable {
    public var scripts: [String]

    public init(scripts: [String]) {
        self.scripts = scripts
    }
}

public enum ScriptListCommand: EditorCommand {
    public static let id: CommandID = "script.list"
    public static let title = "List Scripts"
    public static let doc = "Lists the project's own Swift game scripts (game target, project Scripts/ and Assets/ folders); engine and editor sources are never included."
    public static let isReadOnly = true
    public static let isIdempotent = true

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> ScriptListResult {
        ScriptListResult(scripts: session.projectScripts().map(\.path))
    }
}
