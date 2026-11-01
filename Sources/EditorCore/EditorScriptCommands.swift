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
    public static let doc = "Opens a Swift game script by file path, reading its content and showing it in the editor."

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptOpenResult {
        let base = session.project?.root ?? session.startFolder
        let url = URL(fileURLWithPath: arguments.path, relativeTo: base).standardizedFileURL
        guard session.checkFileAccess(url, title) else {
            throw CommandError.failed("Script is outside the project folder")
        }
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
    public static let doc = "Saves code to a Swift game script and optionally triggers hot reloading."

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptSaveResult {
        let base = session.project?.root ?? session.startFolder
        let url = URL(fileURLWithPath: arguments.path, relativeTo: base).standardizedFileURL
        guard session.checkFileAccess(url, title) else {
            throw CommandError.failed("Script is outside the project folder")
        }

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

        let destinationDir: URL
        if let target = session.gameModule.settings?.target, let packageURL = try? session.gameModule.packageURL() {
            destinationDir = packageURL.appendingPathComponent("Sources/\(target)", isDirectory: true)
        } else if let project = session.project {
            destinationDir = project.root.appendingPathComponent("Sources/\(project.name)", isDirectory: true)
        } else {
            destinationDir = session.startFolder.appendingPathComponent("Scripts", isDirectory: true)
        }

        let fileURL = destinationDir.appendingPathComponent(rawName)
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
    public static let doc = "Lists all Swift game script files in the game module target and project folders."
    public static let isReadOnly = true
    public static let isIdempotent = true

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> ScriptListResult {
        var found: [String] = []
        var seen = Set<String>()

        func scanDirectory(_ dir: URL) {
            guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey],
                                                                 options: [.skipsHiddenFiles]) else { return }
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "swift" {
                    let path = fileURL.standardizedFileURL.path
                    if !seen.contains(path) {
                        seen.insert(path)
                        found.append(path)
                    }
                }
            }
        }

        if let settings = session.gameModule.settings, let target = settings.target,
           let packageURL = try? session.gameModule.packageURL() {
            scanDirectory(packageURL.appendingPathComponent("Sources/\(target)", isDirectory: true))
        }

        if let project = session.project {
            scanDirectory(project.root.appendingPathComponent("Sources", isDirectory: true))
            scanDirectory(project.root.appendingPathComponent("Scripts", isDirectory: true))
        }

        scanDirectory(session.startFolder.appendingPathComponent("Sources", isDirectory: true))
        scanDirectory(session.startFolder.appendingPathComponent("Scripts", isDirectory: true))

        found.sort()
        return ScriptListResult(scripts: found)
    }
}
