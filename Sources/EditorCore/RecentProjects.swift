import Engine
import Foundation

// The projects the editor has opened, for the launcher (LauncherPanel.swift): newest first with
// pinned ones on top, deduplicated by resolved path, capped, persisted in the editor prefs.
// Every way of opening a project (the launcher, the toolbar, `project.open` / `project.new`,
// `--project`) moves it to the top (`EditorSession.setProject`). The list remembers each
// project's name and whether it has game code as they were when last opened, and the scene last
// opened in it; whether its folder still exists is checked when the list is shown.
//
// New projects come from a `ProjectTemplate`: empty, the starter scene, or a copy of
// Projects/SampleGame with its game code (`ProjectTemplate.sampleGameURL`).

/// One project in the recent list (`EditorPrefs.recentProjects`).
public struct RecentProject: Codable, Equatable, Sendable {
    /// The project folder (standardized, symbolic links resolved).
    public var path: String
    /// The project's name (Project.json's, else the folder's) when it was last opened.
    public var name: String
    public var lastOpened: Date
    /// Pinned projects stay at the top of the list (and are never dropped by the cap).
    public var pinned: Bool
    /// Project.json has a `"game"` setting (game code the editor loads).
    public var hasGame: Bool
    /// The scene file last opened or saved in the project (reopened from the launcher).
    public var lastScene: String?

    public init(path: String, name: String, lastOpened: Date, pinned: Bool = false, hasGame: Bool = false, lastScene: String? = nil) {
        self.path = path
        self.name = name
        self.lastOpened = lastOpened
        self.pinned = pinned
        self.hasGame = hasGame
        self.lastScene = lastScene
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decode(String.self, forKey: .path)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? URL(fileURLWithPath: path).lastPathComponent
        lastOpened = try c.decodeIfPresent(Date.self, forKey: .lastOpened) ?? Date(timeIntervalSince1970: 0)
        pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        hasGame = try c.decodeIfPresent(Bool.self, forKey: .hasGame) ?? false
        lastScene = try c.decodeIfPresent(String.self, forKey: .lastScene)
    }

    public var url: URL { URL(fileURLWithPath: path, isDirectory: true) }
    /// The folder or its Project.json is gone (moved, deleted, an unmounted drive).
    public var isMissing: Bool { !Project.exists(at: url) }
    /// Where the editor keeps the project's launcher thumbnail (in its `Library/`, which isn't
    /// checked in).
    public var thumbnailURL: URL { RecentProjectList.thumbnailURL(projectRoot: url) }
}

/// The recent projects (see the notes at the top of the file). The app loads it from the prefs
/// and saves it on `onChange`; commands and the launcher edit it.
@MainActor
public final class RecentProjectList {
    /// How many projects the list keeps by default (pinned ones beyond it stay).
    public static let defaultCapacity = 20
    public var capacity = RecentProjectList.defaultCapacity {
        didSet { if trim() { changed() } }
    }
    /// Newest first, pinned ones on top.
    public private(set) var entries: [RecentProject] = []
    /// Launch straight into the last project instead of showing the launcher (`EditorPrefs.reopenLastProject`).
    public var reopensLastProject = false {
        didSet { if reopensLastProject != oldValue { changed() } }
    }
    /// The folder New Project offers (the last one used), nil: `defaultNewProjectLocation`.
    public var newProjectLocation: String? {
        didSet { if newProjectLocation != oldValue { changed() } }
    }
    /// Called after any change (the app saves the prefs).
    public var onChange: (() -> Void)?
    /// The clock (tests set it).
    public var now: () -> Date = { Date() }

    public init(entries: [RecentProject] = []) {
        load(entries)
    }

    /// Replaces the entries (from the prefs) without calling `onChange`: deduplicated (the newest
    /// of each folder wins, pinned if any was), sorted and capped.
    public func load(_ stored: [RecentProject]) {
        var byKey: [String: RecentProject] = [:]
        var order: [String] = []
        for var entry in stored {
            let key = Self.key(entry.path)
            entry.path = key
            if var existing = byKey[key] {
                let pinned = existing.pinned || entry.pinned
                if entry.lastOpened > existing.lastOpened { existing = entry }
                existing.pinned = pinned
                byKey[key] = existing
            } else {
                byKey[key] = entry
                order.append(key)
            }
        }
        entries = order.compactMap { byKey[$0] }
        sort()
        _ = trim()
    }

    /// The canonical form of a project path: `~` expanded, standardized, symbolic links resolved.
    public static func key(_ path: String) -> String {
        EditorSession.resolved(EditorSession.url(forPath: path)).standardizedFileURL.path
    }

    /// The entry for `path` (any spelling of the folder, or its Project.json), else the only
    /// entry named `path` (ignoring case).
    public func entry(_ path: String) -> RecentProject? {
        index(of: path).map { entries[$0] }
    }

    func index(of path: String) -> Int? {
        var key = Self.key(path)
        if key.hasSuffix("/" + Project.fileName) { key = String(key.dropLast(Project.fileName.count + 1)) }
        if let index = entries.firstIndex(where: { $0.path == key }) { return index }
        let named = entries.indices.filter { entries[$0].name.caseInsensitiveCompare(path) == .orderedSame }
        return named.count == 1 ? named[0] : nil
    }

    /// `project` was opened: it goes to the top (below the pinned ones) with its current name and game setting.
    public func noteOpened(_ project: Project) {
        let key = Self.key(project.root.path)
        var entry = entries.first { $0.path == key } ?? RecentProject(path: key, name: project.name, lastOpened: now())
        entries.removeAll { $0.path == key }
        entry.name = project.name
        entry.hasGame = project.settings.game != nil
        entry.lastOpened = now()
        entries.insert(entry, at: 0)
        sort()
        _ = trim()
        changed()
    }

    /// The scene at `url` was opened or saved in `project`: the launcher reopens it next time.
    public func noteScene(_ url: URL, in project: Project) {
        guard let index = index(of: project.root.path), EditorSession.isInside(url, project.root) else { return }
        let path = url.standardizedFileURL.path
        guard entries[index].lastScene != path else { return }
        entries[index].lastScene = path
        changed()
    }

    /// Takes `path` off the list. Returns false when it isn't on it.
    @discardableResult
    public func remove(_ path: String) -> Bool {
        guard let index = index(of: path) else { return false }
        entries.remove(at: index)
        changed()
        return true
    }

    /// Pins or unpins `path`. Returns false when it isn't on the list.
    @discardableResult
    public func setPinned(_ pinned: Bool, _ path: String) -> Bool {
        guard let index = index(of: path) else { return false }
        guard entries[index].pinned != pinned else { return true }
        entries[index].pinned = pinned
        sort()
        changed()
        return true
    }

    /// Points the entry for `path` (a missing folder) at `project`, which was moved there. An
    /// entry the new folder already had merges into it.
    @discardableResult
    public func relocate(_ path: String, to project: Project) -> Bool {
        guard let index = index(of: path) else { return false }
        var entry = entries[index]
        let key = Self.key(project.root.path)
        entries.remove(at: index)
        if let other = entries.firstIndex(where: { $0.path == key }) {
            entry.pinned = entry.pinned || entries[other].pinned
            entry.lastOpened = max(entry.lastOpened, entries[other].lastOpened)
            entries.remove(at: other)
        }
        // A last scene inside the old folder moves with it.
        if let scene = entry.lastScene, scene.hasPrefix(entry.path + "/") {
            entry.lastScene = key + scene.dropFirst(entry.path.count)
        }
        entry.path = key
        entry.name = project.name
        entry.hasGame = project.settings.game != nil
        entries.append(entry)
        sort()
        changed()
        return true
    }

    /// The entries whose name or path contains `query` (ignoring case; all for an empty one), in list order.
    public func filtered(_ query: String) -> [RecentProject] {
        let words = query.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else { return entries }
        return entries.filter { entry in
            let text = (entry.name + " " + entry.path).lowercased()
            return words.allSatisfy { text.contains($0) }
        }
    }

    /// Pinned first, then most recently opened.
    private func sort() {
        entries.sort { a, b in a.pinned != b.pinned ? a.pinned : a.lastOpened > b.lastOpened }
    }

    /// Drops the oldest unpinned entries past `capacity`. Returns whether any went.
    private func trim() -> Bool {
        let limit = max(capacity, 0)
        let before = entries.count
        // Pinned ones always stay; unpinned ones fill what's left of the capacity.
        let pinned = entries.filter(\.pinned)
        let rest = entries.filter { !$0.pinned }.prefix(max(limit - pinned.count, 0))
        entries = pinned + rest
        return entries.count != before
    }

    private func changed() { onChange?() }

    // MARK: Helpers

    /// Where a project's launcher thumbnail lives: `Library/Editor/Thumbnail.png`.
    public nonisolated static func thumbnailURL(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(Project.libraryFolder, isDirectory: true)
            .appendingPathComponent("Editor", isDirectory: true).appendingPathComponent("Thumbnail.png")
    }

    /// "just now", "5 minutes ago", "yesterday", "3 days ago", else the date ("12 Mar 2026").
    public static func relativeTime(_ date: Date, now: Date) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago" }
        let hours = minutes / 60
        if hours < 24 { return hours == 1 ? "1 hour ago" : "\(hours) hours ago" }
        let days = hours / 24
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 30 { return days < 14 ? "last week" : "\(days / 7) weeks ago" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    /// Where New Project suggests creating projects when none was used yet: `~/Games`.
    public static func defaultNewProjectLocation(home: String = NSHomeDirectory()) -> String {
        URL(fileURLWithPath: home).appendingPathComponent("Games").path
    }
}

// MARK: Templates

/// What a new project starts with (`project.new {template}`, the launcher's New Project).
/// Every template also gets a Swift package for its game code (`ProjectScaffold`).
public enum ProjectTemplate: String, CaseIterable, Codable, Sendable {
    /// Project.json, Assets/ and Library/; the editor opens an empty scene.
    case empty
    /// The starter scene saved as `Assets/Scenes/Main.scene` (Build Game's scene) and opened.
    case starter
    /// A copy of Projects/SampleGame: its assets, its scene and its game code (the SampleGame
    /// target's sources, copied into the project's own package).
    case game

    public var title: String {
        switch self {
        case .empty: "Empty"
        case .starter: "Starter Scene"
        case .game: "Game Module"
        }
    }

    /// One line for the New Project form.
    public var summary: String {
        switch self {
        case .empty: "An empty project and an empty scene."
        case .starter: "A camera, a sun, a floor and a few shapes in Scenes/Main.scene."
        case .game: "A copy of the SampleGame project with its game code (Swift) as the project's own package."
        }
    }

    public var iconName: String {
        switch self {
        case .empty: "file"
        case .starter: "box"
        case .game: "gamepad-2"
        }
    }

    /// The scene a project made from this template opens with (relative to `Assets/`).
    public static let mainScene = "Scenes/Main.scene"

    /// Projects/SampleGame: found above the working directory or the editor executable
    /// (`EDITOR_SAMPLE_PROJECT` overrides it). Nil when it can't be found (an installed editor).
    public static func sampleGameURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        if let path = environment["EDITOR_SAMPLE_PROJECT"], !path.isEmpty {
            let url = URL(fileURLWithPath: path).standardizedFileURL
            return Project.exists(at: url) ? url : nil
        }
        let starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                      URL(fileURLWithPath: CommandLine.arguments.first ?? "").deletingLastPathComponent()]
        for start in starts {
            var folder = start.standardizedFileURL
            for _ in 0..<8 {
                let candidate = folder.appendingPathComponent("Projects/SampleGame", isDirectory: true)
                if Project.exists(at: candidate) { return candidate }
                guard folder.pathComponents.count > 1 else { break }
                folder.deleteLastPathComponent()
            }
        }
        return nil
    }

    /// Why this template can't be used now, or nil.
    public var unavailableReason: String? {
        self == .game && Self.sampleGameURL() == nil
            ? "the Game Module template copies Projects/SampleGame, which isn't above the working directory or the editor (set EDITOR_SAMPLE_PROJECT)"
            : nil
    }

    /// Makes the project at `url` (a new folder, or an existing one without a project) named
    /// `name` (default: the folder's), with its own Swift package for game code
    /// (`ProjectScaffold`). Returns it, the scene to open, if any, and what the scaffold made.
    @MainActor public func create(at url: URL, name: String? = nil, engine: URL? = ProjectScaffold.findEngine())
        throws -> (project: Project, scene: URL?, scaffold: ProjectScaffold.Result) {
        let root = url.standardizedFileURL
        switch self {
        case .empty:
            var project = try Project.create(at: root, name: name)
            let scaffold = try ProjectScaffold.write(into: &project, engine: engine)
            return (project, nil, scaffold)
        case .starter:
            var project = try Project.create(at: root, name: name)
            let scene = project.url(forAssetPath: Self.mainScene)
            try FileManager.default.createDirectory(at: scene.deletingLastPathComponent(), withIntermediateDirectories: true)
            let world = World()
            world.assignsEntityIDs = true
            StarterScene.build(in: world)
            try world.save().write(to: scene, options: .atomic)
            project.settings.build = GameBuildSettings(scenes: [Self.mainScene])
            try project.saveSettings()
            let scaffold = try ProjectScaffold.write(into: &project, engine: engine)
            return (project, scene, scaffold)
        case .game:
            guard let sample = Self.sampleGameURL() else { throw CommandError.failed(unavailableReason ?? "no sample project") }
            if Project.exists(at: root) { throw AssetError.projectExists(root.path) }
            let sampleProject = try Project.open(at: sample)
            try Self.copyContents(of: sample, to: root, skipping: [Project.libraryFolder, "Build", ".DS_Store"])
            var project = try Project.open(at: root)
            project.settings.name = name ?? root.lastPathComponent
            project.settings.game = nil
            try project.saveSettings()
            // The sample's game code (the engine package's SampleGame target) becomes the project's own target.
            var sampleSources: URL?
            if let game = sampleProject.settings.game, let target = game.target {
                let package = game.package.map { sample.appendingPathComponent($0).standardizedFileURL } ?? GameModuleBuilder.findPackage(from: sample)
                sampleSources = package?.appendingPathComponent("Sources/\(target)", isDirectory: true)
            }
            let scaffold = try ProjectScaffold.write(into: &project, engine: engine, sources: sampleSources)
            if scaffold.target == nil, var game = sampleProject.settings.game {
                // No package of its own: keep building the sample's target in the engine's package.
                if let package = game.package {
                    let absolute = sample.appendingPathComponent(package).standardizedFileURL
                    game.package = Self.relativePath(from: root, to: absolute)
                }
                project.settings.game = game
                try project.saveSettings()
            }
            let scene = project.url(forAssetPath: Self.mainScene)
            return (project, FileManager.default.fileExists(atPath: scene.path) ? scene : nil, scaffold)
        }
    }

    /// Copies what `source` holds into `destination` (created), leaving out `skipping` names at
    /// the top and files that already exist there.
    static func copyContents(of source: URL, to destination: URL, skipping: Set<String>) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        for name in try fm.contentsOfDirectory(atPath: source.path) where !skipping.contains(name) {
            let target = destination.appendingPathComponent(name)
            guard !fm.fileExists(atPath: target.path) else { continue }
            try fm.copyItem(at: source.appendingPathComponent(name), to: target)
        }
    }

    /// `target` relative to the folder `base` ("../../engine"), or its absolute path when they
    /// share nothing but the root.
    @MainActor static func relativePath(from base: URL, to target: URL) -> String {
        let a = EditorSession.resolved(base).standardizedFileURL.pathComponents
        let b = EditorSession.resolved(target).standardizedFileURL.pathComponents
        var common = 0
        while common < min(a.count, b.count) && a[common] == b[common] { common += 1 }
        guard common > 1 else { return target.standardizedFileURL.path }
        let ups = Array(repeating: "..", count: a.count - common)
        let parts = ups + b[common...]
        return parts.isEmpty ? "." : parts.joined(separator: "/")
    }
}
