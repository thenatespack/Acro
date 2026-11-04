import Engine
import Foundation

// Opening project files outside the editor: Show in Finder / Explorer / Folder (`file.reveal`)
// and Open in Code Editor (`file.openInCodeEditor`), with the code editor picked in the
// Settings window (`EditorSettings.codeEditor`). The Assets panel's context menu and the
// Settings window's Project tab offer both.
//
// Paths are the project's: absolute, relative to the project folder, or relative to `Assets/`
// (as the Assets panel and asset.list show them); without a project, relative to the editor's
// start folder. AI calls stay inside the project folder like every other file action. Apps are
// only launched by an editor with a window (`canRender`), so tests and headless runs just get
// the command line back.

/// The code editors Open in Code Editor knows.
public enum CodeEditorChoice: String, Codable, Sendable, CaseIterable {
    /// What the system opens the file with (`open`, `xdg-open`, `start`).
    case system
    case vscode, cursor, xcode, zed, sublime
    /// `EditorSettings.codeEditorCommand`.
    case custom

    public var title: String {
        switch self {
        case .system: "System Default"
        case .vscode: "VS Code"
        case .cursor: "Cursor"
        case .xcode: "Xcode"
        case .zed: "Zed"
        case .sublime: "Sublime Text"
        case .custom: "Custom Command"
        }
    }

    /// The macOS app name (`open -a`), for the ones that are apps.
    var macApp: String? {
        switch self {
        case .vscode: "Visual Studio Code"
        case .cursor: "Cursor"
        case .xcode: "Xcode"
        case .zed: "Zed"
        case .sublime: "Sublime Text"
        case .system, .custom: nil
        }
    }

    /// The command-line launcher elsewhere.
    var cli: String? {
        switch self {
        case .vscode: "code"
        case .cursor: "cursor"
        case .zed: "zed"
        case .sublime: "subl"
        case .system, .xcode, .custom: nil
        }
    }
}

/// The result of `file.reveal` and `file.openInCodeEditor`.
public struct ExternalOpenResult: Codable, Equatable, Sendable {
    /// The file or folder.
    public var path: String
    /// What was (or, without a window, would be) run.
    public var command: [String]
    /// Whether it was run (only by an editor with a window).
    public var launched: Bool
}

/// Command lines for revealing and opening files, per platform.
public enum ExternalLaunch {
    public enum Platform: Sendable { case macOS, windows, linux }

    #if os(macOS)
    public static let current = Platform.macOS
    #elseif os(Windows)
    public static let current = Platform.windows
    #else
    public static let current = Platform.linux
    #endif

    /// "Show in Finder" (macOS), "Show in Explorer" (Windows), "Show in Folder".
    public static var revealTitle: String {
        switch current {
        case .macOS: "Show in Finder"
        case .windows: "Show in Explorer"
        case .linux: "Show in Folder"
        }
    }

    /// "Open in VS Code", "Open in Default App", "Open in Custom Editor".
    public static func openTitle(_ choice: CodeEditorChoice) -> String {
        switch choice {
        case .system: "Open in Default App"
        case .custom: "Open in Custom Editor"
        default: "Open in \(choice.title)"
        }
    }

    /// Shows `url` selected in the file manager (a folder on Linux, where it can't select).
    public static func revealCommand(_ url: URL, platform: Platform = current) -> [String] {
        switch platform {
        case .macOS: return ["/usr/bin/open", "-R", url.path]
        case .windows: return ["explorer.exe", "/select,\(url.path)"]
        case .linux:
            var isFolder: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder)
            return ["/usr/bin/env", "xdg-open", (exists && isFolder.boolValue) ? url.path : url.deletingLastPathComponent().path]
        }
    }

    /// Opens `url` with `choice`; throws when that editor doesn't exist on `platform` or the
    /// custom command is empty.
    public static func openCommand(_ url: URL, with choice: CodeEditorChoice, customCommand: String?,
                                   platform: Platform = current) throws -> [String] {
        let path = url.path
        switch choice {
        case .system:
            switch platform {
            case .macOS: return ["/usr/bin/open", path]
            case .windows: return ["cmd.exe", "/c", "start", "", path]
            case .linux: return ["/usr/bin/env", "xdg-open", path]
            }
        case .custom:
            let words = split(customCommand ?? "")
            guard !words.isEmpty else {
                throw CommandError.failed("No custom code editor command: set one in Settings › Editor › Code editor")
            }
            let filled = words.contains { $0.contains("{path}") } ? words.map { $0.replacingOccurrences(of: "{path}", with: path) }
                : words + [path]
            return platform == .windows ? ["cmd.exe", "/c"] + filled : ["/usr/bin/env"] + filled
        default:
            if platform == .macOS, let app = choice.macApp { return ["/usr/bin/open", "-a", app, path] }
            guard let cli = choice.cli else {
                throw CommandError.failed("\(choice.title) isn't available on this platform: pick another code editor in Settings")
            }
            return platform == .windows ? ["cmd.exe", "/c", cli, path] : ["/usr/bin/env", cli, path]
        }
    }

    /// Splits a command into words; single or double quotes group words.
    static func split(_ command: String) -> [String] {
        var words: [String] = [], word = "", quote: Character?, inWord = false
        for character in command {
            if let open = quote {
                if character == open { quote = nil } else { word.append(character) }
            } else if character == "\"" || character == "'" {
                quote = character
                inWord = true
            } else if character == " " || character == "\t" {
                if inWord { words.append(word) }
                word = ""
                inWord = false
            } else {
                word.append(character)
                inWord = true
            }
        }
        if inWord { words.append(word) }
        return words
    }

    /// Runs `command` without waiting; when it exits with an error, `failed` gets a message.
    @MainActor
    static func launch(_ command: [String], failed: @escaping @MainActor (String) -> Void) {
        guard let executable = command.first else { return }
        let process = Process()
        if executable.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = Array(command.dropFirst())
        } else {
            // cmd.exe / explorer.exe: found on the PATH.
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = command
            #if os(Windows)
            process.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\\(executable)")
            process.arguments = Array(command.dropFirst())
            #endif
        }
        let errors = Pipe()
        process.standardError = errors
        process.standardOutput = FileHandle.nullDevice
        process.terminationHandler = { finished in
            guard finished.terminationStatus != 0 else { return }
            let output = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let message = output.isEmpty ? "exit status \(finished.terminationStatus)" : output
            Task { @MainActor in failed(message) }
        }
        do {
            try process.run()
        } catch {
            failed("\(error)")
        }
    }
}

extension EditorSession {
    /// The file or folder a `file.*` command names: absolute, relative to the project folder or
    /// to `Assets/`; nil and logged when it is missing or outside the sandbox.
    func externalFileURL(_ path: String?, default fallback: URL, _ action: String) -> URL? {
        let url: URL
        if let path, !path.trimmingCharacters(in: .whitespaces).isEmpty {
            let base = project?.root ?? startFolder
            let trimmed = (path.trimmingCharacters(in: .whitespaces) as NSString).expandingTildeInPath
            var candidates = [trimmed.hasPrefix("/") ? URL(fileURLWithPath: trimmed) : base.appendingPathComponent(trimmed)]
            if let project, !trimmed.hasPrefix("/") { candidates.append(project.url(forAssetPath: trimmed)) }
            url = (candidates.first { FileManager.default.fileExists(atPath: $0.path) } ?? candidates[0]).standardizedFileURL
        } else {
            url = fallback.standardizedFileURL
        }
        guard checkFileAccess(url, action) else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else {
            log.error("\(action): \(url.path) doesn't exist")
            return nil
        }
        return url
    }

    /// Runs `command` when this editor has a window; returns whether it did.
    func launchExternal(_ command: [String], _ action: String) -> Bool {
        guard uiApp?.canRender == true else { return false }
        ExternalLaunch.launch(command) { [weak self] message in self?.log.error("\(action) failed: \(message)") }
        return true
    }

    /// Where Open in Code Editor goes without a path: the game's package (the code), else the
    /// project folder, else the start folder.
    var defaultCodeFolder: URL {
        if let project {
            if project.settings.game != nil, let package = ProjectChoices.package(for: project) { return package }
            return project.root
        }
        return startFolder
    }
}

public enum FileRevealCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A file or folder: absolute, relative to the project folder, or relative to Assets/. Default: the project folder.
        public var path: String?
        public init(path: String? = nil) { self.path = path }
    }

    public static let id: CommandID = "file.reveal"
    public static let title = "Show in Folder"
    public static let doc = """
        Shows a file or folder in the system's file manager (Finder, Explorer; on Linux its folder opens): `path` \
        absolute, relative to the project folder or to Assets/ (default: the project folder). Only inside the \
        project for AI clients. Returns the path and the command; it runs only in an editor with a window.
        """
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ExternalOpenResult {
        guard let url = session.externalFileURL(arguments.path, default: session.project?.root ?? session.startFolder, title) else {
            throw CommandError.failed("\(title): can't show \(arguments.path ?? "the project folder")")
        }
        let command = ExternalLaunch.revealCommand(url)
        return ExternalOpenResult(path: url.path, command: command, launched: session.launchExternal(command, title))
    }
}

public enum FileOpenInCodeEditorCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// A file or folder: absolute, relative to the project folder, or relative to Assets/. Default: the game code's package folder, else the project folder.
        public var path: String?
        public init(path: String? = nil) { self.path = path }
    }

    public static let id: CommandID = "file.openInCodeEditor"
    public static let title = "Open in Code Editor"
    public static let doc = """
        Opens a file or folder in the code editor picked in the Settings window (settings.setEditor `codeEditor`: \
        the system default, VS Code, Cursor, Xcode, Zed, Sublime Text or a custom command). `path` is absolute, \
        relative to the project folder or to Assets/; default: the game code's package folder, else the project \
        folder. Only inside the project for AI clients. Returns the path and the command; it runs only in an editor with a window.
        """
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ExternalOpenResult {
        guard let url = session.externalFileURL(arguments.path, default: session.defaultCodeFolder, title) else {
            throw CommandError.failed("\(title): can't open \(arguments.path ?? "the game code")")
        }
        let settings = session.editorSettings
        let command = try ExternalLaunch.openCommand(url, with: settings.codeEditor, customCommand: settings.codeEditorCommand)
        return ExternalOpenResult(path: url.path, command: command, launched: session.launchExternal(command, title))
    }
}
