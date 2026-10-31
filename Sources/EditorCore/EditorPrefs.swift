import Engine
import Foundation

/// Per-user editor settings that persist between launches: the dock layout, the last scene and
/// the last project (pre-filled in the project path field, not opened automatically).
public struct EditorPrefs: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public var version = EditorPrefs.currentVersion
    public var layout: DockLayout?
    public var lastScenePath: String?
    public var lastProjectPath: String?

    public init(layout: DockLayout? = nil, lastScenePath: String? = nil, lastProjectPath: String? = nil) {
        self.layout = layout
        self.lastScenePath = lastScenePath
        self.lastProjectPath = lastProjectPath
    }
}

/// Reads and writes `EditorPrefs` as a small JSON file.
///
/// Location (`defaultURL`): `EDITOR_PREFS=<file>` if set; else on macOS
/// `~/Library/Application Support/SwiftGameEngine/Editor/prefs.json`, on Windows
/// `%APPDATA%\SwiftGameEngine\Editor\prefs.json`, elsewhere
/// `$XDG_CONFIG_HOME/swift-game-engine/editor/prefs.json` (default `~/.config`).
public struct EditorPrefsStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let path = environment["EDITOR_PREFS"], !path.isEmpty { return URL(fileURLWithPath: path) }
        let home = URL(fileURLWithPath: environment["HOME"] ?? NSHomeDirectory())
        #if os(macOS)
        let base = home.appendingPathComponent("Library/Application Support/SwiftGameEngine/Editor")
        #elseif os(Windows)
        let base = (environment["APPDATA"].map { URL(fileURLWithPath: $0) } ?? home).appendingPathComponent("SwiftGameEngine/Editor")
        #else
        let config = environment["XDG_CONFIG_HOME"].map { URL(fileURLWithPath: $0) } ?? home.appendingPathComponent(".config")
        let base = config.appendingPathComponent("swift-game-engine/editor")
        #endif
        return base.appendingPathComponent("prefs.json")
    }

    /// The stored prefs, nil if there is no file. Throws for a file that can't be decoded.
    public func load() throws -> EditorPrefs? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(EditorPrefs.self, from: Data(contentsOf: url))
    }

    public func save(_ prefs: EditorPrefs) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(prefs).write(to: url, options: .atomic)
    }
}

/// The editor's panels and their default arrangement.
public enum EditorLayout {
    public static let viewport = "viewport"
    public static let hierarchy = "hierarchy"
    public static let inspector = "inspector"
    public static let console = "console"
    public static let stats = "stats"
    public static let panelIDs = [viewport, hierarchy, inspector, console, stats]

    /// Hierarchy left, inspector right, the viewport in the middle above a Console / Stats tab group.
    public static let defaultLayout = DockLayout(
        root: .split(axis: .horizontal, fractions: [0.19, 0.57, 0.24], children: [
            .tabs(panels: [hierarchy], active: hierarchy),
            .split(axis: .vertical, fractions: [0.72, 0.28], children: [
                .tabs(panels: [viewport], active: viewport),
                .tabs(panels: [console, stats], active: console),
            ]),
            .tabs(panels: [inspector], active: inspector),
        ]))

    /// The layout to start with: the stored one if it still shows the viewport, else the default.
    public static func initialLayout(stored: DockLayout?) -> DockLayout {
        guard let stored, stored.panelIDs.contains(viewport) else { return defaultLayout }
        return stored
    }
}
