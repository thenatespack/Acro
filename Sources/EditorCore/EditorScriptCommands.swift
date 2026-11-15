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
            let reason = url.pathExtension == "swift" ? "it's outside the project's script folders" : "scripts are .swift files"
            throw CommandError.failed("\(url.lastPathComponent) is not a project script (\(reason)). Script folders: \(allowed)")
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
            throw CommandError.failed("No script at \(arguments.path) (script.list shows the project's scripts)")
        }
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CommandError.failed("Couldn't read \(arguments.path): \(error.localizedDescription)")
        }

        session.onOpenScript?(url.path)
        let lines = content.components(separatedBy: "\n").count
        return ScriptOpenResult(path: url.path, content: content, lineCount: lines)
    }
}

public struct ScriptSaveResult: Codable, Equatable, Sendable {
    public var path: String
    public var saved: Bool
    /// Whether a rebuild and reload started (it finishes in the background: `game.info` has its
    /// errors, with file and line, if the build fails).
    public var reloaded: Bool
    /// Why a requested reload didn't start (no game module, a build already running…).
    public var reloadNote: String?

    public init(path: String, saved: Bool, reloaded: Bool, reloadNote: String? = nil) {
        self.path = path
        self.saved = saved
        self.reloaded = reloaded
        self.reloadNote = reloadNote
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
    public static let doc = "Saves code to a project Swift game script and starts a rebuild and hot reload (reload: false skips it). The build runs in the background; if it fails, game.info's diagnostics list each error's file, line and message. Only project script folders can be written."

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
            throw CommandError.failed("Couldn't write \(url.lastPathComponent): \(error.localizedDescription)")
        }

        var reloaded = false
        var note: String?
        if arguments.reload ?? true {
            if let reason = GameReloadCommand.unavailableReason(in: session) {
                note = "Saved but not reloaded: \(reason)"
            } else {
                do {
                    _ = try session.commands.start(GameReloadCommand.self, .init(build: true))
                    reloaded = true
                } catch {
                    note = "Saved but the reload didn't start: \(error)"
                    session.log.warning(note!)
                }
            }
        }

        session.onOpenScript?(url.path)
        return ScriptSaveResult(path: url.path, saved: true, reloaded: reloaded, reloadNote: note)
    }
}

public struct ScriptNewResult: Codable, Equatable, Sendable {
    public var path: String
    public var created: Bool
    /// The Swift type the file declares.
    public var typeName: String
    /// The file `game.script(<type>.self)` was added to (the module's entry point), or nil when
    /// it wasn't registered: see `note`.
    public var registeredIn: String?
    /// What's left to do by hand, if anything.
    public var note: String?

    public init(path: String, created: Bool, typeName: String = "", registeredIn: String? = nil, note: String? = nil) {
        self.path = path
        self.created = created
        self.typeName = typeName
        self.registeredIn = registeredIn
        self.note = note
    }
}

public enum ScriptNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The script's name: "Spinner", "camera controller" or "Spinner.swift". The type is
        /// its UpperCamelCase form.
        public var name: String
        /// The file's code instead of the Script template (not registered automatically).
        public var template: String?

        public init(name: String, template: String? = nil) {
            self.name = name
            self.template = template
        }
    }

    public static let id: CommandID = "script.new"
    public static let title = "New Script"
    public static let doc = """
        Creates a Swift game script: a component with an update(_ context:) that runs every frame for each entity that \
        has it (the Script protocol). Registers it in the game module's entry point (game.script(Name.self)) so it shows \
        in Add Component after the next reload. Refuses to overwrite an existing file.
        """

    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func unavailableReason(in session: EditorSession) -> String? { nil }

    /// "camera controller" / "camera-controller" → "CameraController"; nil when that isn't a
    /// Swift type name.
    static func typeName(for name: String) -> String? {
        let words = name.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" })
        let joined = words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
        guard joined.wholeMatch(of: /[A-Za-z][A-Za-z0-9]*/) != nil else { return nil }
        return joined
    }

    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ScriptNewResult {
        var rawName = arguments.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawName.isEmpty else { throw CommandError.failed("Give the script a name, such as \"Spinner\"") }
        guard !rawName.contains("/"), !rawName.contains("\\") else {
            throw CommandError.failed("\"\(rawName)\" must be a plain file name; new scripts go in \(session.scriptDestination.path)")
        }
        if rawName.hasSuffix(".swift") { rawName.removeLast(".swift".count) }
        guard let typeName = typeName(for: rawName) else {
            throw CommandError.failed("\"\(rawName)\" can't be a Swift type name: use letters and digits, starting with a letter (e.g. \"Spinner\" or \"camera controller\")")
        }

        let destinationDir = session.scriptDestination
        let fileURL = destinationDir.appendingPathComponent(rawName + ".swift")
        try session.checkProjectScript(fileURL, title)
        guard session.checkFileAccess(fileURL, title) else {
            throw CommandError.failed("Script destination is outside the project folder")
        }
        guard !FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CommandError.failed("\(fileURL.lastPathComponent) already exists: open it with script.open, or pick another name")
        }
        if let clash = session.projectScripts().first(where: { declares(typeName, in: $0) }) {
            throw CommandError.failed("\(clash.lastPathComponent) already declares a type named \(typeName): pick another name")
        }

        let code = arguments.template ?? template(typeName)
        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            try code.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw CommandError.failed("Couldn't create \(fileURL.lastPathComponent): \(error.localizedDescription)")
        }

        var registeredIn: String?
        var note: String?
        if arguments.template != nil {
            note = "Custom template: register the type in the module's entry point yourself (game.script or game.component)"
        } else {
            do {
                registeredIn = try register(typeName, in: session)?.path
                if registeredIn == nil {
                    note = "No game module entry point (a GameModule.register { game in … } call) in the project's scripts: add game.script(\(typeName).self) to it so the editor offers \(typeName)"
                }
            } catch {
                note = "Couldn't register \(typeName) (\(error.localizedDescription)): add game.script(\(typeName).self) to the module's entry point"
            }
        }
        if let note { session.log.warning("New script \(typeName): \(note)") }

        session.onOpenScript?(fileURL.path)
        return ScriptNewResult(path: fileURL.path, created: true, typeName: typeName, registeredIn: registeredIn, note: note)
    }

    static func template(_ typeName: String) -> String {
        """
        import Engine

        /// \(typeName): describe what it does. Add it to an entity in the inspector; while the
        /// game plays, `update` runs every frame for each entity that has it.
        public struct \(typeName): Script, Equatable, Sendable {
            public static let componentName = "\(typeName)"
            public static var fieldHints: [String: FieldHints] {
                ["speed": FieldHints(range: 0...10, step: 0.1, tooltip: "Turns per second")]
            }

            // Fields show in the inspector and are saved with the scene.
            public var speed: Float = 0.5

            public init() {}

            public mutating func update(_ context: ScriptContext) {
                // Example: spin around the up axis. context also has dt, time, input, log,
                // get(_:) / modify(_:) for the entity's other components and the world.
                let turn = Quat(angle: speed * 2 * .pi * context.dt, axis: Vec3(0, 1, 0))
                context.transform.rotation = turn * context.transform.rotation
            }
        }

        """
    }

    /// Whether the Swift file at `url` declares a type named `name`.
    static func declares(_ name: String, in url: URL) -> Bool {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return source.contains(try! Regex("\\b(struct|class|enum|actor)\\s+\(name)\\b"))
    }

    /// Adds `<game>.script(<typeName>.self)` as the first line of the module's registration
    /// closure (`GameModule.register(module) { game in`). Returns the file it changed, nil when
    /// no project script has one.
    static func register(_ typeName: String, in session: EditorSession) throws -> URL? {
        let pattern = /GameModule\.register\([^)]*\)\s*\{\s*(?:\[[^\]]*\]\s*)?(\w+)\s+in[ \t]*\n/
        for url in session.projectScripts() {
            guard let source = try? String(contentsOf: url, encoding: .utf8), let match = source.firstMatch(of: pattern) else { continue }
            if source.contains("script(\(typeName).self") || source.contains("component(\(typeName).self") { return url }
            let lineStart = source[..<match.range.lowerBound].lastIndex(of: "\n").map { source.index(after: $0) } ?? source.startIndex
            let indent = source[lineStart...].prefix { $0 == " " || $0 == "\t" }
            let line = "\(indent)    \(match.1).script(\(typeName).self)\n"
            var updated = source
            updated.insert(contentsOf: line, at: match.range.upperBound)
            try updated.write(to: url, atomically: true, encoding: .utf8)
            session.log.info("Registered \(typeName) in \(url.lastPathComponent)")
            return url
        }
        return nil
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
