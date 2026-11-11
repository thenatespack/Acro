import Engine
import Foundation

// Editor settings and project settings, and the commands that read and change them. The
// Settings window (SettingsDialog.swift) runs these too.
//
// - Editor settings (`EditorSettings`) are the user's: gizmo snap steps and the viewport camera.
//   They live in `session.editorSettings` and the app keeps them in the prefs file
//   (`EditorPrefs.editor`), so they follow the user from project to project. The theme and
//   UI zoom are editor settings too, changed with `view.appearance`; the AI settings change
//   only in the editor's UI (EditorSafety.swift).
// - Project settings (`ProjectSettings`) are the project's, in its `Project.json`: the name,
//   the game code (`game`), Build Game's defaults (`build`) and how the game runs (`runtime`:
//   window, render quality, physics; applied in play mode and in exported games).
//
// For AI clients `settings.setProject` refuses to change what decides which code runs or
// where files are written outside the project: `game`, `build.enginePackage` and `build.output`.

/// The user's editor settings (`settings.setEditor`, the Settings window), kept in the prefs.
/// Missing keys get the defaults.
public struct EditorSettings: Codable, Equatable, Sendable {
    /// Move snapping step, in units (default 0.5).
    public var snapTranslate: Float
    /// Rotate snapping step, in degrees (default 15).
    public var snapRotateDegrees: Float
    /// Scale snapping step (default 0.1).
    public var snapScale: Float
    /// Fly speed of the viewport camera (right mouse + WASD), in units per second; Shift
    /// flies 4x faster (default 6).
    public var cameraFlySpeed: Float
    /// Vertical field of view of the viewport camera, in degrees (default about 53).
    public var cameraFieldOfView: Float
    /// What Open in Code Editor (`file.openInCodeEditor`) opens files and folders with (default: the system's default app).
    public var codeEditor: CodeEditorChoice
    /// With `codeEditor` custom: the command, `{path}` standing for the file or folder ("nvim-qt {path}";
    /// without `{path}` it goes last). Quotes group words.
    public var codeEditorCommand: String?

    public static let defaultFieldOfView: Float = 180 / 3.4
    public static let snapTranslateRange: ClosedRange<Float> = 0.001...1000
    public static let snapRotateRange: ClosedRange<Float> = 0.1...180
    public static let snapScaleRange: ClosedRange<Float> = 0.001...10
    public static let cameraFlySpeedRange: ClosedRange<Float> = 0.1...1000
    public static let cameraFieldOfViewRange: ClosedRange<Float> = 10...120

    public init(snapTranslate: Float = 0.5, snapRotateDegrees: Float = 15, snapScale: Float = 0.1, cameraFlySpeed: Float = 6,
                cameraFieldOfView: Float = EditorSettings.defaultFieldOfView, codeEditor: CodeEditorChoice = .system,
                codeEditorCommand: String? = nil) {
        self.codeEditor = codeEditor
        self.codeEditorCommand = codeEditorCommand
        self.snapTranslate = snapTranslate
        self.snapRotateDegrees = snapRotateDegrees
        self.snapScale = snapScale
        self.cameraFlySpeed = cameraFlySpeed
        self.cameraFieldOfView = cameraFieldOfView
    }

    private enum CodingKeys: String, CodingKey {
        case snapTranslate, snapRotateDegrees, snapScale, cameraFlySpeed, cameraFieldOfView, codeEditor, codeEditorCommand
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = EditorSettings()
        // Out-of-range values (a hand-edited prefs file) fall back to the clamped value.
        snapTranslate = Self.clamp(try c.decodeIfPresent(Float.self, forKey: .snapTranslate), Self.snapTranslateRange, d.snapTranslate)
        snapRotateDegrees = Self.clamp(try c.decodeIfPresent(Float.self, forKey: .snapRotateDegrees), Self.snapRotateRange, d.snapRotateDegrees)
        snapScale = Self.clamp(try c.decodeIfPresent(Float.self, forKey: .snapScale), Self.snapScaleRange, d.snapScale)
        cameraFlySpeed = Self.clamp(try c.decodeIfPresent(Float.self, forKey: .cameraFlySpeed), Self.cameraFlySpeedRange, d.cameraFlySpeed)
        cameraFieldOfView = Self.clamp(try c.decodeIfPresent(Float.self, forKey: .cameraFieldOfView), Self.cameraFieldOfViewRange,
                                       d.cameraFieldOfView)
        // An editor this version doesn't know falls back to the default.
        codeEditor = (try? c.decodeIfPresent(CodeEditorChoice.self, forKey: .codeEditor)) ?? .system
        codeEditorCommand = try c.decodeIfPresent(String.self, forKey: .codeEditorCommand)
    }

    private static func clamp(_ value: Float?, _ range: ClosedRange<Float>, _ fallback: Float) -> Float {
        guard let value, value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }

    /// The gizmo's snapping with these steps (`isEnabled`: the toolbar's toggle).
    public func gizmoSnapping(enabled: Bool) -> GizmoSnapping {
        GizmoSnapping(isEnabled: enabled, translateStep: snapTranslate, rotateDegrees: snapRotateDegrees, scaleStep: snapScale)
    }
}

/// Both kinds of settings (`settings.get`).
public struct SettingsSnapshot: Codable, Equatable, Sendable {
    /// The user's editor settings.
    public var editor: EditorSettings
    /// The theme and UI zoom (nil without the editor window).
    public var appearance: EditorAppearance?
    /// The open project's `Project.json` (nil without a project).
    public var project: ProjectSettings?
    /// The project folder (nil without a project).
    public var projectPath: String?
    /// The game module targets of the project's package, the choices for `game.target`
    /// (nil without a project or package).
    public var gameTargets: [String]?
    /// The project's scene files, relative to `Assets/`: the choices for `build.scenes`.
    public var scenes: [String]?
}

/// Finds what the Settings window offers: game module targets and scene files.
@MainActor
public enum ProjectChoices {
    /// The package the project's game code builds in: `game.package` (relative to the project
    /// folder), else the nearest `Package.swift` at or above the project folder.
    public static func package(for project: Project) -> URL? {
        if let path = project.settings.game?.package {
            let url = URL(fileURLWithPath: path, relativeTo: project.root).standardizedFileURL
            return FileManager.default.fileExists(atPath: url.appendingPathComponent("Package.swift").path) ? url : nil
        }
        return GameModuleBuilder.findPackage(from: project.root)
    }

    private static var targetCache: [String: (date: Date, targets: [String])] = [:]

    /// The folders under `package`'s `Sources/` that are game modules: a Swift file in them
    /// declares the entry point (`@_cdecl("acro_module_v1")` at the start of a
    /// line; the pre-Acro `swift_game_engine_module_v1` counts too). Sorted; cached until `Sources/` changes.
    public static func gameTargets(in package: URL) -> [String] {
        let fm = FileManager.default
        let sources = package.appendingPathComponent("Sources", isDirectory: true)
        let date = (try? fm.attributesOfItem(atPath: sources.path))?[.modificationDate] as? Date ?? .distantPast
        if let cached = targetCache[package.path], cached.date == date { return cached.targets }
        let markers = [GameModuleABI.entryPoint, GameModuleABI.legacyEntryPoint].map { "@_cdecl(\"\($0)\")" }
        var targets: [String] = []
        for name in (try? fm.contentsOfDirectory(atPath: sources.path)) ?? [] {
            let folder = sources.appendingPathComponent(name, isDirectory: true)
            guard let files = fm.enumerator(at: folder, includingPropertiesForKeys: nil) else { continue }
            for case let file as URL in files where file.pathExtension == "swift" {
                guard let text = try? String(contentsOf: file, encoding: .utf8),
                      markers.contains(where: text.contains) else { continue }
                if text.split(separator: "\n").contains(where: { line in markers.contains { line.hasPrefix($0) } }) {
                    targets.append(name)
                    break
                }
            }
        }
        targets.sort()
        targetCache[package.path] = (date, targets)
        return targets
    }

    /// The game module targets for `project` (empty without a package).
    public static func gameTargets(for project: Project) -> [String] {
        package(for: project).map(gameTargets(in:)) ?? []
    }

    /// The project's scene files (`.scene` under `Assets/`, read from disk so a scene saved a
    /// moment ago is there before the next scan), relative to `Assets/`, sorted.
    public static func scenes(in project: Project) -> [String] {
        guard let files = FileManager.default.enumerator(at: project.assetsURL, includingPropertiesForKeys: nil,
                                                         options: [.skipsHiddenFiles]) else { return [] }
        var scenes: [String] = []
        for case let url as URL in files where url.pathExtension.lowercased() == "scene" {
            if let path = project.assetPath(for: url) { scenes.append(path) }
        }
        return scenes.sorted()
    }

    /// `url` as Build Game takes it: relative to `Assets/` when inside, else to the project
    /// folder; nil outside the project.
    public static func buildPath(for url: URL, in project: Project) -> String? {
        if let path = project.assetPath(for: url) { return path }
        let root = project.root.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let full = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        guard full.count > root.count, Array(full.prefix(root.count)) == root else { return nil }
        return full.dropFirst(root.count).joined(separator: "/")
    }
}

/// The project settings after `settings.setProject`.
public struct ProjectSettingsResult: Codable, Equatable, Sendable {
    public var project: ProjectSettings
    /// The file written.
    public var path: String
}

extension EditorSession {
    /// Both kinds of settings as `settings.get` reports them.
    public func settingsSnapshot() -> SettingsSnapshot {
        SettingsSnapshot(editor: editorSettings, appearance: try? host?.appearance(theme: nil, uiScale: nil),
                         project: project?.settings, projectPath: project?.root.path,
                         gameTargets: project.map(ProjectChoices.gameTargets(for:)), scenes: project.map(ProjectChoices.scenes(in:)))
    }

    /// Replaces the open project's settings and writes `Project.json`. A changed `game` is
    /// loaded (without building).
    public func saveProjectSettings(_ settings: ProjectSettings) throws {
        guard let assets else { throw CommandError.failed("No project is open") }
        if let problem = settings.runtime?.validationError() { throw CommandError.failed(problem) }
        let gameChanged = settings.game != assets.project.settings.game
        try assets.saveProjectSettings(settings)
        log.info("Saved \(assets.project.settingsURL.path)")
        if gameChanged { gameModule.projectOpened(assets.project) }
        onProjectSettingsChange?()
        changed()
    }
}

public enum SettingsGetCommand: EditorCommand {
    public static let id: CommandID = "settings.get"
    public static let title = "Get Settings"
    public static let doc = """
        The editor settings (`editor`: snap steps, viewport camera; `appearance`: theme and UI zoom, with the editor \
        window) and the open project's settings (`project`, its Project.json: name, `game`, `build`, `runtime`). Change \
        them with settings.setEditor, view.appearance and settings.setProject. With a project, `gameTargets` lists the \
        package's game module targets (the choices for game.target) and `scenes` its scene files (for build.scenes).
        """
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> SettingsSnapshot {
        session.settingsSnapshot()
    }
}

public enum SettingsSetEditorCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Move snapping step in units (0.001-1000).
        public var snapTranslate: Float?
        /// Rotate snapping step in degrees (0.1-180).
        public var snapRotateDegrees: Float?
        /// Scale snapping step (0.001-10).
        public var snapScale: Float?
        /// Viewport camera fly speed in units per second (0.1-1000).
        public var cameraFlySpeed: Float?
        /// Viewport camera vertical field of view in degrees (10-120).
        public var cameraFieldOfView: Float?
        /// The code editor for Open in Code Editor: system, vscode, cursor, xcode, zed, sublime or custom.
        public var codeEditor: CodeEditorChoice?
        /// The command for `codeEditor: custom` ("nvim-qt {path}"); "" clears it. Not for AI clients.
        public var codeEditorCommand: String?
        /// Go back to the defaults first (then apply the other fields).
        public var reset: Bool?

        public init(snapTranslate: Float? = nil, snapRotateDegrees: Float? = nil, snapScale: Float? = nil, cameraFlySpeed: Float? = nil,
                    cameraFieldOfView: Float? = nil, codeEditor: CodeEditorChoice? = nil, codeEditorCommand: String? = nil,
                    reset: Bool? = nil) {
            self.codeEditor = codeEditor
            self.codeEditorCommand = codeEditorCommand
            self.snapTranslate = snapTranslate
            self.snapRotateDegrees = snapRotateDegrees
            self.snapScale = snapScale
            self.cameraFlySpeed = cameraFlySpeed
            self.cameraFieldOfView = cameraFieldOfView
            self.reset = reset
        }
    }

    public static let id: CommandID = "settings.setEditor"
    public static let title = "Editor Settings"
    public static let doc = """
        Changes the user's editor settings (the Settings window's Editor tab) and saves them in the prefs: gizmo \
        snap steps (`snapTranslate`, `snapRotateDegrees`, `snapScale`; tool.snapping turns snapping on) and the \
        viewport camera (`cameraFlySpeed`, `cameraFieldOfView`) and the code editor file.openInCodeEditor uses \
        (`codeEditor`; `codeEditorCommand` for custom, which AI clients can't change). Only the fields given change; `reset: true` goes back \
        to the defaults first. A value outside its range is refused. Returns all of them.
        """
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EditorSettings {
        var settings = arguments.reset == true ? EditorSettings() : session.editorSettings
        func set(_ value: Float?, _ range: ClosedRange<Float>, _ name: String, _ keyPath: WritableKeyPath<EditorSettings, Float>) throws {
            guard let value else { return }
            guard value.isFinite, range.contains(value) else {
                throw CommandError.failed("\(name) must be in \(range.lowerBound)...\(range.upperBound) (got \(value))")
            }
            settings[keyPath: keyPath] = value
        }
        try set(arguments.snapTranslate, EditorSettings.snapTranslateRange, "snapTranslate", \.snapTranslate)
        try set(arguments.snapRotateDegrees, EditorSettings.snapRotateRange, "snapRotateDegrees", \.snapRotateDegrees)
        try set(arguments.snapScale, EditorSettings.snapScaleRange, "snapScale", \.snapScale)
        try set(arguments.cameraFlySpeed, EditorSettings.cameraFlySpeedRange, "cameraFlySpeed", \.cameraFlySpeed)
        try set(arguments.cameraFieldOfView, EditorSettings.cameraFieldOfViewRange, "cameraFieldOfView", \.cameraFieldOfView)
        if let choice = arguments.codeEditor { settings.codeEditor = choice }
        if let command = arguments.codeEditorCommand {
            let trimmed = command.trimmingCharacters(in: .whitespaces)
            settings.codeEditorCommand = trimmed.isEmpty ? nil : trimmed
        }
        // A custom command runs a program of its author's choosing: only the user sets it.
        if session.fileAccessRoots != nil, settings.codeEditorCommand != session.editorSettings.codeEditorCommand {
            throw CommandError.failed("AI clients can't change codeEditorCommand; change it in the editor's Settings window")
        }
        session.editorSettings = settings
        return settings
    }
}

public enum SettingsSetProjectCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The project's display name.
        public var name: String?
        /// Replaces the `game` section (the game code: target, package, library, buildCommand, watch). Not for AI clients.
        public var game: GameModuleSettings?
        /// Replaces the `build` section (Build Game's scenes, include, name, output, textureFamily, textures, enginePackage).
        public var build: GameBuildSettings?
        /// Replaces the `runtime` section: `window` (title, width, height, vsync, quality, showDebugOverlay, renderResolution, upscaler, upscalerSharpness, msaa, backend, minWidth, minHeight, allowLargerThanScreen) and `physics` (gravity, gravity2D, fixedTimestep).
        public var runtime: ProjectRuntimeSettings?
        /// Sections to remove: "game", "build", "runtime".
        public var clear: [String]?

        public init(name: String? = nil, game: GameModuleSettings? = nil, build: GameBuildSettings? = nil,
                    runtime: ProjectRuntimeSettings? = nil, clear: [String]? = nil) {
            self.name = name
            self.game = game
            self.build = build
            self.runtime = runtime
            self.clear = clear
        }
    }

    public static let id: CommandID = "settings.setProject"
    public static let title = "Project Settings"
    public static let doc = """
        Changes the open project's settings (the Settings window's Project tab) and writes Project.json. `name` sets \
        the display name; `game`, `build` and `runtime` each replace their whole section (read it with settings.get, \
        change it, send it back); `clear` removes sections. `runtime.window` (title, width, height, vsync, quality \
        low|medium|high|ultra, showDebugOverlay, renderResolution native|720p|1080p|4k|<w>x<h>|quality|balanced|\
        performance|ultraperformance|<factor>x, upscaler bilinear|fsr1|metalfx|metalfx-temporal|taau|fsr3, \
        upscalerSharpness 0-4 stops, msaa 1|2|4|8, backend metal|vulkan, minWidth, minHeight, allowLargerThanScreen) \
        applies to exported games; `runtime.physics` (gravity [x,y,z], \
        gravity2D [x,y], fixedTimestep in seconds) applies in play mode and exported games. AI clients can't change \
        `game`, `build.enginePackage` or `build.output` (they decide what code runs and where files go): change those \
        in the editor. Not while playing.
        """
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.project != nil && !session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? {
        session.isPlaying ? EditorError.playing.description : session.project == nil ? "no project is open" : nil
    }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ProjectSettingsResult {
        guard let project = session.project else { throw CommandError.failed("No project is open") }
        var settings = project.settings
        let sections = ["game", "build", "runtime"]
        for section in arguments.clear ?? [] {
            guard sections.contains(section) else {
                throw CommandError.failed("Unknown section '\(section)' in clear: use \(sections.joined(separator: ", "))")
            }
        }
        let clear = Set(arguments.clear ?? [])
        if let name = arguments.name { settings.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
        if clear.contains("game") { settings.game = nil }
        if clear.contains("build") { settings.build = nil }
        if clear.contains("runtime") { settings.runtime = nil }
        if let game = arguments.game { settings.game = game }
        if let build = arguments.build { settings.build = build }
        if let runtime = arguments.runtime { settings.runtime = runtime.isEmpty ? nil : runtime }
        // AI calls run sandboxed (`fileAccessRoots`): no changing which code runs or where files go.
        if session.fileAccessRoots != nil {
            let old = project.settings
            var refused: [String] = []
            if settings.game != old.game { refused.append("game") }
            if settings.build?.enginePackage != old.build?.enginePackage { refused.append("build.enginePackage") }
            if settings.build?.output != old.build?.output { refused.append("build.output") }
            if !refused.isEmpty {
                throw CommandError.failed("AI clients can't change \(refused.joined(separator: ", ")); change it in the editor's Settings window")
            }
        }
        try session.saveProjectSettings(settings)
        return ProjectSettingsResult(project: settings, path: project.settingsURL.path)
    }
}

@MainActor
public enum EditorSettingsCommands {
    public static let all: [any EditorCommand.Type] = [SettingsGetCommand.self, SettingsSetEditorCommand.self, SettingsSetProjectCommand.self,
                                                       FileRevealCommand.self, FileOpenInCodeEditorCommand.self]
}
