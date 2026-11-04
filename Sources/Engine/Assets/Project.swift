import Foundation

// A project is a folder:
//
// ```
// MyGame/
//   Project.json        marker and settings (checked in)
//   Assets/             the user's files, each with a sidecar: rock.obj + rock.obj.meta (checked in)
//   Library/            import cache, rebuilt on demand (ignored by the generated .gitignore)
//   .gitignore
// ```
//
// `Project.json`:
//
// ```json
// {
//   "engineVersion" : "0.1.0",
//   "format" : "SwiftGameEngine.Project",
//   "name" : "MyGame",
//   "version" : 1
// }
// ```
//
// `engineVersion` is the engine version that last opened the project (`EngineVersion`); the
// editor warns before opening a project made with another one.
//
// Optional sections: `game` (the game code, `GameModuleSettings`), `build` (Build Game,
// `GameBuildSettings`) and `runtime` (window and physics, `ProjectRuntimeSettings`).

/// Errors from projects, sidecars and imports.
public enum AssetError: Error, CustomStringConvertible, Equatable {
    case notAProject(String)
    case projectExists(String)
    case unsupportedProjectVersion(Int)
    case badSidecar(String)
    case noImporter(String)
    case unreadable(String)
    case noSuchAsset(String)

    public var description: String {
        switch self {
        case .notAProject(let path): "\(path) is not a project (no \(Project.fileName))"
        case .projectExists(let path): "\(path) already contains a project"
        case .unsupportedProjectVersion(let v): "Project file version \(v) is newer than this engine supports (\(ProjectSettings.currentVersion))"
        case .badSidecar(let message): "Bad sidecar: \(message)"
        case .noImporter(let path): "No importer for \(path)"
        case .unreadable(let message): "Couldn't read the file: \(message)"
        case .noSuchAsset(let what): "No asset \(what)"
        }
    }
}

/// The contents of `Project.json`. Unknown keys are ignored, missing ones get defaults.
public struct ProjectSettings: Equatable, Sendable, Codable {
    public static let format = "SwiftGameEngine.Project"
    public static let currentVersion = 1

    /// Display name (the folder's name when created).
    public var name: String
    /// The project's game code, which the editor loads and hot-reloads (`"game": {"target":
    /// "MyGame", "package": ".."}`; see `GameModuleSettings`). nil: none.
    public var game: GameModuleSettings?
    /// What Build Game and `--cook` use by default (`"build": {"scenes": ["Scenes/Main.scene"]}`;
    /// see `GameBuildSettings`). nil: none.
    public var build: GameBuildSettings?
    /// How the game runs: window, render quality, physics (`"runtime": {"window": {...},
    /// "physics": {...}}`; see `ProjectRuntimeSettings`). nil: the engine's defaults.
    public var runtime: ProjectRuntimeSettings?
    /// The engine version that made or last opened the project (`EngineVersion.current` for new
    /// ones); nil in projects from before it was recorded.
    public var engineVersion: String?

    public init(name: String, game: GameModuleSettings? = nil, build: GameBuildSettings? = nil, runtime: ProjectRuntimeSettings? = nil,
                engineVersion: String? = EngineVersion.current) {
        self.name = name
        self.engineVersion = engineVersion
        self.game = game
        self.build = build
        self.runtime = runtime
    }

    private enum CodingKeys: String, CodingKey { case format, version, engineVersion, name, game, build, runtime }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version <= Self.currentVersion else { throw AssetError.unsupportedProjectVersion(version) }
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        engineVersion = try c.decodeIfPresent(String.self, forKey: .engineVersion)
        game = try c.decodeIfPresent(GameModuleSettings.self, forKey: .game)
        build = try c.decodeIfPresent(GameBuildSettings.self, forKey: .build)
        runtime = try c.decodeIfPresent(ProjectRuntimeSettings.self, forKey: .runtime)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Self.format, forKey: .format)
        try c.encode(Self.currentVersion, forKey: .version)
        try c.encodeIfPresent(engineVersion, forKey: .engineVersion)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(game, forKey: .game)
        try c.encodeIfPresent(build, forKey: .build)
        if let runtime, !runtime.isEmpty { try c.encode(runtime, forKey: .runtime) }
    }
}

/// A project folder: `Project.json`, `Assets/` and `Library/` (see the layout above). Open its
/// assets with `AssetDatabase(project:)`.
public struct Project: Sendable {
    public static let fileName = "Project.json"
    public static let assetsFolder = "Assets"
    public static let libraryFolder = "Library"

    /// The project folder.
    public let root: URL
    public var settings: ProjectSettings

    public var assetsURL: URL { root.appendingPathComponent(Self.assetsFolder, isDirectory: true) }
    public var libraryURL: URL { root.appendingPathComponent(Self.libraryFolder, isDirectory: true) }
    public var settingsURL: URL { root.appendingPathComponent(Self.fileName) }
    public var name: String { settings.name.isEmpty ? root.lastPathComponent : settings.name }

    /// Makes a new project at `url` (created if needed; it may already hold files, but not a
    /// project): `Project.json`, an empty `Assets/`, `Library/` and a `.gitignore` for it.
    @discardableResult
    public static func create(at url: URL, name: String? = nil) throws -> Project {
        let root = url.standardizedFileURL
        let fm = FileManager.default
        if fm.fileExists(atPath: root.appendingPathComponent(fileName).path) { throw AssetError.projectExists(root.path) }
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let project = Project(root: root, settings: ProjectSettings(name: name ?? root.lastPathComponent))
        try fm.createDirectory(at: project.assetsURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: project.libraryURL, withIntermediateDirectories: true)
        let gitignore = root.appendingPathComponent(".gitignore")
        if !fm.fileExists(atPath: gitignore.path) {
            try Data("# Import cache, rebuilt from Assets/.\n/\(libraryFolder)/\n".utf8).write(to: gitignore)
        }
        try project.saveSettings()
        return project
    }

    /// Opens the project at `url`: the folder holding `Project.json`, or the file itself.
    /// Creates `Assets/` and `Library/` if they are missing (a fresh clone has no `Library/`).
    public static func open(at url: URL) throws -> Project {
        var root = url.standardizedFileURL
        if root.lastPathComponent == fileName {
            root.deleteLastPathComponent()
            #if os(Linux)
            // swift-corelibs-foundation leaves a trailing slash, and its URLs then don't equal
            // the folder's own (`open(at: folder)`).
            root = URL(fileURLWithPath: root.path, isDirectory: false)
            #endif
        }
        let file = root.appendingPathComponent(fileName)
        guard let data = FileManager.default.contents(atPath: file.path) else { throw AssetError.notAProject(root.path) }
        let settings = try AssetJSON.decoder().decode(ProjectSettings.self, from: data)
        let project = Project(root: root, settings: settings)
        try FileManager.default.createDirectory(at: project.assetsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: project.libraryURL, withIntermediateDirectories: true)
        return project
    }

    /// The project was made (or last opened) with another engine version (nil: this one, or not recorded).
    public var engineVersionMismatch: EngineVersionMismatch? { EngineVersionMismatch.check(settings.engineVersion) }

    /// Reads just the engine version recorded in the `Project.json` of the project at `url` (the
    /// folder or the file), without opening it; nil when there is none or the file can't be read.
    public static func engineVersionMismatch(at url: URL) -> EngineVersionMismatch? {
        let file = url.lastPathComponent == fileName ? url : url.appendingPathComponent(fileName)
        struct Header: Decodable { var engineVersion: String? }
        guard let data = FileManager.default.contents(atPath: file.path),
              let header = try? JSONDecoder().decode(Header.self, from: data) else { return nil }
        return EngineVersionMismatch.check(header.engineVersion)
    }

    /// Records this engine's version in `Project.json` (after opening a project from another
    /// version, or one from before versions were recorded). Does nothing when it is already there.
    public mutating func stampEngineVersion() throws {
        guard settings.engineVersion != EngineVersion.current else { return }
        settings.engineVersion = EngineVersion.current
        try saveSettings()
    }

    /// Whether `url` is a project folder (has `Project.json`).
    public static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.appendingPathComponent(fileName).path)
    }

    /// Writes `Project.json`.
    public func saveSettings() throws {
        try AssetJSON.encode(settings).write(to: settingsURL, options: .atomic)
    }

    /// The URL of `path` (relative to `Assets/`, "/" separators).
    public func url(forAssetPath path: String) -> URL {
        path.split(separator: "/").reduce(assetsURL) { $0.appendingPathComponent(String($1)) }
    }

    /// `url`'s path relative to `Assets/` with "/" separators, or nil if it isn't inside it.
    public func assetPath(for url: URL) -> String? {
        let base = assetsURL.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        let full = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        guard full.count > base.count, Array(full.prefix(base.count)) == base else { return nil }
        return full.dropFirst(base.count).joined(separator: "/")
    }
}
