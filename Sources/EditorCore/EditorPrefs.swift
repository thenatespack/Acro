import Engine
import Foundation

/// Per-user editor settings that persist between launches: the dock layout, the last scene and
/// the last project (pre-filled in the project path field), the launcher's recent projects and
/// whether to skip it, the AI settings (read-only mode, confirmations, the HTTP server) and the
/// editor settings (snap steps, viewport camera).
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
    /// Snap steps and the viewport camera (nil: the defaults); see `EditorSettings`.
    public var editor: EditorSettings?

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
/// `~/Library/Application Support/Acro/Editor/prefs.json`, on Windows
/// `%APPDATA%\Acro\Editor\prefs.json`, elsewhere
/// `$XDG_CONFIG_HOME/acro/editor/prefs.json` (default `~/.config`). Prefs saved before the rename
/// (under `SwiftGameEngine` / `swift-game-engine`) are copied there the first time.
public struct EditorPrefsStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let path = environment["EDITOR_PREFS"], !path.isEmpty { return URL(fileURLWithPath: path) }
        let home = URL(fileURLWithPath: environment["HOME"] ?? NSHomeDirectory())
        #if os(macOS)
        let parent = home.appendingPathComponent("Library/Application Support")
        let (folder, legacyFolder) = ("Acro/Editor", "SwiftGameEngine/Editor")
        #elseif os(Windows)
        let parent = environment["APPDATA"].map { URL(fileURLWithPath: $0) } ?? home
        let (folder, legacyFolder) = ("Acro/Editor", "SwiftGameEngine/Editor")
        #else
        let parent = environment["XDG_CONFIG_HOME"].map { URL(fileURLWithPath: $0) } ?? home.appendingPathComponent(".config")
        let (folder, legacyFolder) = ("acro/editor", "swift-game-engine/editor")
        #endif
        let url = parent.appendingPathComponent(folder).appendingPathComponent("prefs.json")
        let legacy = parent.appendingPathComponent(legacyFolder).appendingPathComponent("prefs.json")
        let files = FileManager.default
        if !files.fileExists(atPath: url.path), files.fileExists(atPath: legacy.path) {
            try? files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? files.copyItem(at: legacy, to: url)
        }
        return url
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
    /// The Scene view (the editor camera, gizmos) and the Game view (the scene's Camera entity).
    public static let viewport = "viewport"
    public static let game = "game"
    public static let hierarchy = "hierarchy"
    public static let inspector = "inspector"
    public static let console = "console"
    public static let stats = "stats"
    public static let assets = "assets"
    public static let activity = "activity"
    public static let scripts = "scripts"
    public static let files = "files"
    /// The Mesh Builder tab (opened with a mesh build, tabbed with the Scene view; not in the default layout).
    public static let meshBuilder = "meshBuilder"
    /// The VFX Builder tab (opened with a .vfx file, like the Mesh Builder).
    public static let vfxBuilder = "vfxBuilder"
    /// The Sound Builder tab (opened with a sound build, tabbed with the Scene view; not in the default layout).
    public static let soundBuilder = "soundBuilder"
    /// The Post-FX tab (opened with a .postfx file, tabbed with the Scene view; not in the default layout).
    public static let postFXBuilder = "postFXBuilder"
    /// The Data Table tab (opened with a `.table` file, tabbed with the Scene view; not in the default layout).
    public static let dataTable = "dataTable"
    public static let terrainBuilder = "terrainBuilder"
    public static let panelIDs = [viewport, game, hierarchy, inspector, console, stats, assets, activity, scripts, files, meshBuilder, vfxBuilder,
                                  soundBuilder, postFXBuilder, dataTable, terrainBuilder]

    /// Hierarchy above Files on the left, inspector right, the Scene view (tabbed with the Game
    /// view and Scripts, so scripts open where the Scene view is) in the middle above an Assets / Console / Activity /
    /// Stats tab group.
    public static let defaultLayout = DockLayout(
        root: .split(axis: .horizontal, fractions: [0.19, 0.57, 0.24], children: [
            .split(axis: .vertical, fractions: [0.55, 0.45], children: [
                .tabs(panels: [hierarchy], active: hierarchy),
                .tabs(panels: [files], active: files),
            ]),
            .split(axis: .vertical, fractions: [0.64, 0.36], children: [
                .tabs(panels: [viewport, game, scripts], active: viewport),
                .tabs(panels: [assets, console, activity, stats], active: assets),
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

    /// Whether `a` and `b` are tabs of the same group.
    public static func shareGroup(in layout: DockLayout, _ a: String, _ b: String) -> Bool {
        func visit(_ node: DockLayout.Node) -> Bool {
            switch node {
            case .split(_, _, let children): return children.contains(where: visit)
            case .tabs(let panels, _): return panels.contains(a) && panels.contains(b)
            }
        }
        return layout.root.map(visit) ?? false || layout.floating.contains { $0.panels.contains(a) && $0.panels.contains(b) }
    }

    /// The layout to start with: the stored one if it still shows the viewport, else the default.
    public static func initialLayout(stored: DockLayout?) -> DockLayout {
        guard let stored, stored.panelIDs.contains(viewport) else { return defaultLayout }
        return stored
    }
}
