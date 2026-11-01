import Engine
import Foundation

/// Per-user editor settings that persist between launches: the dock layout, the last scene and
/// the last project (pre-filled in the project path field), the launcher's recent projects and
/// whether to skip it, and the AI settings (read-only mode, confirmations, the HTTP server).
public struct EditorPrefs: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    public var version = EditorPrefs.currentVersion
    public var layout: DockLayout?
    public var lastScenePath: String?
    public var lastProjectPath: String?
    /// What AI clients may do (nil: the defaults); see `AISettings`.
    public var ai: AISettings?
    /// The UI theme's name ("Dark", "Light", "High Contrast"; nil or anything else: Dark).
    public var theme: String?
    /// UI zoom on top of the display's backing scale (nil: 1; clamped to `EditorApp.uiScaleRange`).
    public var uiScale: Float?
    /// The launcher's recent projects (RecentProjects.swift), newest first, pinned ones on top.
    public var recentProjects: [RecentProject]?
    /// Start in the last project instead of the launcher (nil: false).
    public var reopenLastProject: Bool?
    /// The folder New Project last created a project in (nil: ~/Games).
    public var newProjectLocation: String?

    public init(layout: DockLayout? = nil, lastScenePath: String? = nil, lastProjectPath: String? = nil, ai: AISettings? = nil) {
        self.layout = layout
        self.lastScenePath = lastScenePath
        self.lastProjectPath = lastProjectPath
        self.ai = ai
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
    public static let assets = "assets"
    public static let activity = "activity"
    public static let scripts = "scripts"
    public static let panelIDs = [viewport, hierarchy, inspector, console, stats, assets, activity, scripts]

    /// Hierarchy left, inspector right, the viewport in the middle above an Assets / Scripts /
    /// Console / Activity / Stats tab group.
    public static let defaultLayout = DockLayout(
        root: .split(axis: .horizontal, fractions: [0.19, 0.57, 0.24], children: [
            .tabs(panels: [hierarchy], active: hierarchy),
            .split(axis: .vertical, fractions: [0.64, 0.36], children: [
                .tabs(panels: [viewport], active: viewport),
                .tabs(panels: [assets, scripts, console, activity, stats], active: assets),
            ]),
            .tabs(panels: [inspector], active: inspector),
        ]))

    /// The selected panel of the tab group showing `id`, if it is docked.
    public static func activePanel(in layout: DockLayout, groupOf id: String) -> String? {
        func visit(_ node: DockLayout.Node) -> String?? {
            switch node {
            case .split(_, _, let children):
                for child in children { if let found = visit(child) { return found } }
                return nil
            case .tabs(let panels, let active):
                return panels.contains(id) ? .some(active) : nil
            }
        }
        if let found = layout.root.flatMap(visit) { return found }
        return layout.floating.first { $0.panels.contains(id) }?.active
    }

    /// The layout to start with: the stored one if it still shows the viewport, else the default.
    public static func initialLayout(stored: DockLayout?) -> DockLayout {
        guard let stored, stored.panelIDs.contains(viewport) else { return defaultLayout }
        return stored
    }
}
