import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The launcher (card #673): the recent projects list (persistence, dedupe, cap, pin order,
// missing folders, every way of opening a project moving it to the top), the project templates,
// Close Project returning to the launcher, the launcher's keys and forms, and its MCP commands
// (with the sandbox). Everything lives in temporary folders; the prefs file is a temporary one
// and crash recovery is off, so nothing touches the real prefs or home folder.

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("LauncherTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// A headless editor showing the launcher (or as `launcher` says), with prefs in `prefs` if given.
@MainActor private func launcherApp(prefs: URL? = nil, launcher: EditorOptions.LauncherMode = .always,
                                    size: Vec2 = Vec2(1280, 720)) -> EditorApp {
    var options = EditorOptions(deterministic: prefs == nil, prefsURL: prefs)
    options.recovery = false
    options.launcher = launcher
    let app = EditorApp(options: options)
    app.session.log.echoesToStandardOutput = false
    // Projects made from the Game Module template say "game": loading SampleGame's module here
    // would register its components for the whole test process; act as if --game said otherwise.
    app.session.gameModule.commandLineSettings = GameModuleSettings()
    app.setupWithoutWindow(size: size)
    app.session.log.echoesToStandardOutput = false
    return app
}

/// A clock the tests move forward.
@MainActor private final class TestClock {
    var date = Date(timeIntervalSince1970: 1_800_000_000)
    func tick(_ seconds: Double = 60) -> Date {
        date += seconds
        return date
    }
}

/// Drives a session as an MCP client does, sandboxed to `workspace` while no project is open.
@MainActor private struct LauncherClient {
    let mcp: EditorMCP
    let connection: MCPMemoryConnection
    let app: EditorApp

    init(_ app: EditorApp, workspace: URL) {
        self.app = app
        mcp = EditorMCP(session: app.session)
        mcp.workspaceRoot = workspace
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        connection.send(["jsonrpc": "2.0", "id": "init", "method": "initialize",
                         "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "launcher-test"]]])
        mcp.pump()
        _ = connection.output.take()
    }

    /// The call's result (`isError`, `structuredContent`, `content`).
    func call(_ name: String, _ arguments: JSON = [:]) -> JSON {
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": "tools/call", "params": ["name": .string(name), "arguments": arguments]])
        mcp.pump()
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        app.syncPanels()
        return reply["result"] ?? nil
    }

    func text(_ result: JSON) -> String { result["content"]?.arrayValue?.first?["text"]?.stringValue ?? "" }
}

@MainActor @Suite struct LauncherTests {
    // MARK: The list

    @Test func recentListDedupesCapsAndPutsPinnedFirst() throws {
        let folder = temporaryDirectory()
        let clock = TestClock()
        let list = RecentProjectList()
        list.now = { clock.tick() }
        var changes = 0
        list.onChange = { changes += 1 }
        let projects = try (1...5).map { try Project.create(at: folder.appendingPathComponent("P\($0)")) }
        for project in projects { list.noteOpened(project) }
        #expect(list.entries.map(\.name) == ["P5", "P4", "P3", "P2", "P1"])
        #expect(changes == 5)

        // The same folder spelled differently (trailing slash, "..", a symbolic link) is one entry.
        let link = folder.appendingPathComponent("Link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: projects[0].root)
        for spelling in [projects[0].root.path + "/", folder.path + "/P2/../P1", link.path] {
            list.noteOpened(try Project.open(at: URL(fileURLWithPath: spelling)))
        }
        #expect(list.entries.count == 5)
        #expect(list.entries.first?.name == "P1")
        #expect(list.entry(link.path)?.name == "P1")
        #expect(list.entry(projects[0].settingsURL.path)?.name == "P1")
        #expect(list.entry("p3")?.name == "P3")  // by name, ignoring case

        // Pinned first; pinning keeps the pinned ones' own order by last opened.
        list.setPinned(true, projects[2].root.path)
        list.setPinned(true, projects[4].root.path)
        #expect(list.entries.map(\.name) == ["P5", "P3", "P1", "P4", "P2"])
        list.setPinned(false, "P5")
        #expect(list.entries.map(\.name) == ["P3", "P1", "P5", "P4", "P2"])

        // The cap drops the oldest unpinned ones, never pinned ones.
        list.capacity = 3
        #expect(list.entries.map(\.name) == ["P3", "P1", "P5"])
        list.setPinned(true, "P5")
        list.setPinned(true, "P1")
        list.capacity = 2
        #expect(Set(list.entries.map(\.name)) == ["P1", "P3", "P5"], "pinned ones beyond the cap stay")
        let allPinned = list.entries.allSatisfy(\.pinned)
        #expect(allPinned)
        #expect(RecentProjectList.defaultCapacity == 20)

        // Stored duplicates (another spelling) load as one, the newest and pinned if either was.
        let stored = [RecentProject(path: projects[1].root.path, name: "Old", lastOpened: clock.date - 1000, pinned: true),
                      RecentProject(path: projects[1].root.path + "/", name: "New", lastOpened: clock.date)]
        let loaded = RecentProjectList(entries: stored)
        #expect(loaded.entries.count == 1)
        #expect(loaded.entries.first?.name == "New" && loaded.entries.first?.pinned == true)

        // Filtering by name or folder, every word.
        #expect(list.filtered("p1").map(\.name) == ["P1"])
        #expect(list.filtered("LauncherTests p5").map(\.name) == ["P5"])
        #expect(list.filtered("nothing").isEmpty)
        #expect(list.filtered("").count == list.entries.count)
    }

    @Test func relativeTimes() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(RecentProjectList.relativeTime(now - 10, now: now) == "just now")
        #expect(RecentProjectList.relativeTime(now - 60, now: now) == "1 minute ago")
        #expect(RecentProjectList.relativeTime(now - 7200, now: now) == "2 hours ago")
        #expect(RecentProjectList.relativeTime(now - 86_400 * 1.5, now: now) == "yesterday")
        #expect(RecentProjectList.relativeTime(now - 86_400 * 3, now: now) == "3 days ago")
        #expect(RecentProjectList.relativeTime(now - 86_400 * 10, now: now) == "last week")
        #expect(RecentProjectList.relativeTime(now - 86_400 * 400, now: now).contains("20"))
    }

    @Test func recentProjectsPersistInThePrefs() throws {
        let folder = temporaryDirectory()
        let prefsURL = folder.appendingPathComponent("prefs/prefs.json")
        let app = launcherApp(prefs: prefsURL)
        let session = app.session
        try session.commands.run(ProjectNewCommand.self, .init(name: "First", location: folder.path, template: .empty))
        try session.commands.run(ProjectNewCommand.self, .init(name: "Second", location: folder.path, template: .starter))
        try session.commands.run(ProjectRecentPinCommand.self, .init(path: "First"))
        try session.commands.run(LauncherSettingsCommand.self, .init(reopenLastProject: true))
        app.savePrefs()

        let prefs = try #require(try EditorPrefsStore(url: prefsURL).load())
        #expect(prefs.recentProjects?.map(\.name) == ["First", "Second"])
        #expect(prefs.recentProjects?.first?.pinned == true)
        #expect(prefs.reopenLastProject == true)
        #expect(prefs.newProjectLocation == folder.path)
        #expect(prefs.recentProjects?.last?.lastScene?.hasSuffix("Second/Assets/Scenes/Main.scene") == true)

        // A new editor reads them back, and with "reopen last project" starts in Second (opened last).
        let again = launcherApp(prefs: prefsURL, launcher: .auto)
        #expect(again.session.recentProjects.entries.map(\.name) == ["First", "Second"])
        #expect(!again.isLauncherShown)
        #expect(again.session.project?.name == "Second")
        #expect(again.session.document.url?.lastPathComponent == "Main.scene")
        // Without it, the launcher.
        try again.session.commands.run(LauncherSettingsCommand.self, .init(reopenLastProject: false))
        again.savePrefs()
        let third = launcherApp(prefs: prefsURL, launcher: .auto)
        #expect(third.isLauncherShown && third.session.project == nil)
        // An old prefs file (before the launcher) starts the list with its last project.
        var old = EditorPrefs()
        old.lastProjectPath = folder.appendingPathComponent("First").path
        try EditorPrefsStore(url: prefsURL).save(old)
        #expect(launcherApp(prefs: prefsURL).session.recentProjects.entries.map(\.name) == ["First"])
    }

    @Test func missingFoldersCanBeLocatedOrRemoved() throws {
        let folder = temporaryDirectory()
        let app = launcherApp()
        let session = app.session
        try session.commands.run(ProjectNewCommand.self, .init(name: "Wanderer", location: folder.path, template: .starter))
        try session.commands.run(ProjectRecentPinCommand.self, .init(path: "Wanderer"))
        try session.commands.run(LauncherShowCommand.self)
        let moved = folder.appendingPathComponent("Elsewhere/Wanderer")
        try FileManager.default.createDirectory(at: moved.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: folder.appendingPathComponent("Wanderer"), to: moved)

        let listed = try session.commands.run(ProjectRecentListCommand.self, .init())
        #expect(listed.projects.first?.missing == true)
        #expect(listed.projects.first?.lastOpenedText == "just now")
        // Opening it fails (and the launcher stays); its row offers Locate… and Remove.
        #expect(throws: (any Error).self) { try session.commands.run(ProjectOpenCommand.self, .init(path: "Wanderer", openLastScene: true)) }
        app.syncPanels()
        let items = app.ui.accessibilityElements().filter { $0.isOnScreen }
        #expect(items.contains { $0.label == "Locate Wanderer…" && $0.command == ProjectRecentLocateCommand.id.rawValue })
        #expect(items.contains { $0.label == "Remove Wanderer from the list" && $0.command == ProjectRecentRemoveCommand.id.rawValue })
        #expect(items.contains { $0.label == "Wanderer" && $0.value?.hasPrefix("missing") == true })

        // Locate: it keeps its pin and its last scene moves with it.
        let located = try session.commands.run(ProjectRecentLocateCommand.self, .init(path: "Wanderer", newPath: moved.path))
        #expect(!located.missing && located.pinned && located.path == RecentProjectList.key(moved.path))
        #expect(located.lastScene == RecentProjectList.key(moved.path) + "/Assets/Scenes/Main.scene")
        try session.commands.run(ProjectOpenCommand.self, .init(path: "Wanderer", openLastScene: true))
        #expect(session.project?.root.path == moved.standardizedFileURL.path)
        #expect(session.document.url?.lastPathComponent == "Main.scene")
        // Locating at a folder that isn't a project fails.
        #expect(throws: (any Error).self) {
            try session.commands.run(ProjectRecentLocateCommand.self, .init(path: "Wanderer", newPath: folder.path))
        }
        // Remove takes it off the list, the folder stays.
        try session.commands.run(ProjectRecentRemoveCommand.self, .init(path: "Wanderer"))
        #expect(session.recentProjects.entries.isEmpty)
        #expect(Project.exists(at: moved))
        #expect(throws: (any Error).self) { try session.commands.run(ProjectRecentRemoveCommand.self, .init(path: "Wanderer")) }
    }

    @Test func openingAProjectAnyWayPutsItOnTop() throws {
        let folder = temporaryDirectory()
        let a = try Project.create(at: folder.appendingPathComponent("Alpha"))
        let b = try Project.create(at: folder.appendingPathComponent("Beta"))
        // The command line (--project).
        var options = EditorOptions(projectPath: a.root.path, deterministic: true)
        options.launcher = .auto
        options.recovery = false
        let app = EditorApp(options: options)
        app.session.log.echoesToStandardOutput = false
        app.setupWithoutWindow()
        let session = app.session
        #expect(!app.isLauncherShown, "--project skips the launcher")
        #expect(session.recentProjects.entries.map(\.name) == ["Alpha"])
        // MCP / the toolbar (project.open).
        try session.commands.run(ProjectOpenCommand.self, .init(path: b.root.path))
        #expect(session.recentProjects.entries.map(\.name) == ["Beta", "Alpha"])
        // The toolbar's Open Project button.
        app.toolbar.projectPath.text = a.root.path
        app.openProject()
        #expect(session.recentProjects.entries.map(\.name) == ["Alpha", "Beta"])
        // project.new.
        try session.commands.run(ProjectNewCommand.self, .init(path: folder.appendingPathComponent("Gamma").path))
        #expect(session.recentProjects.entries.map(\.name) == ["Gamma", "Alpha", "Beta"])
        // A scene saved in a project becomes its last scene; saving outside the project is refused.
        try session.commands.run(SceneSaveAsCommand.self, .init(path: folder.appendingPathComponent("Gamma/Assets/Level.scene").path))
        #expect(session.recentProjects.entry("Gamma")?.lastScene?.hasSuffix("Gamma/Assets/Level.scene") == true)
        #expect(throws: (any Error).self) {
            try session.commands.run(SceneSaveAsCommand.self, .init(path: folder.appendingPathComponent("Outside.scene").path))
        }
        #expect(session.recentProjects.entry("Gamma")?.lastScene?.hasSuffix("Level.scene") == true)
    }

    // MARK: Templates

    @Test func newProjectFromEachTemplateOpensIt() throws {
        let folder = temporaryDirectory()
        let app = launcherApp()
        let session = app.session
        #expect(app.isLauncherShown)

        try session.commands.run(ProjectNewCommand.self, .init(name: "Blank", location: folder.path, template: .empty))
        #expect(!app.isLauncherShown && session.project?.name == "Blank")
        #expect(session.document.url == nil && session.world.entityCount == 0)

        try session.commands.run(LauncherShowCommand.self)
        try session.commands.run(ProjectNewCommand.self, .init(name: "Starter", location: folder.path, template: .starter))
        #expect(session.project?.name == "Starter")
        #expect(session.document.url?.path.hasSuffix("Starter/Assets/Scenes/Main.scene") == true)
        #expect(session.world.entityCount > 5)
        #expect(session.project?.settings.build?.scenes == [ProjectTemplate.mainScene])

        try session.commands.run(LauncherShowCommand.self)
        let gameFolder = folder.appendingPathComponent("Shooter Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: gameFolder.path, name: "Shooter", template: .game))
        let project = try #require(session.project)
        #expect(project.name == "Shooter" && project.root.lastPathComponent == "Shooter Game")
        let game = try #require(project.settings.game)
        #expect(game.target == "SampleGame")
        // The package path, relative to the new project, still names the engine's package.
        let package = URL(fileURLWithPath: try #require(game.package), relativeTo: project.root).standardizedFileURL
        #expect(FileManager.default.fileExists(atPath: package.appendingPathComponent("Package.swift").path))
        #expect(FileManager.default.fileExists(atPath: package.appendingPathComponent("Sources/SampleGame").path))
        #expect(FileManager.default.fileExists(atPath: project.url(forAssetPath: "Models/BoomBox.glb").path))
        #expect(!FileManager.default.fileExists(atPath: project.libraryURL.appendingPathComponent("index.json").path),
                "the sample's Library isn't copied")
        #expect(session.document.url?.lastPathComponent == "Main.scene")
        #expect(session.recentProjects.entries.first?.hasGame == true)
        #expect(session.recentProjects.entries.map(\.name) == ["Shooter", "Starter", "Blank"])

        // A folder that already holds a project is refused.
        #expect(throws: (any Error).self) {
            try session.commands.run(ProjectNewCommand.self, .init(name: "Starter", location: folder.path, template: .starter))
        }
        // A name with a slash, or no name and no path.
        #expect(throws: (any Error).self) { try session.commands.run(ProjectNewCommand.self, .init(name: "a/b", location: folder.path)) }
        #expect(throws: (any Error).self) { try session.commands.run(ProjectNewCommand.self, .init()) }
        // New Project remembers the location for next time.
        #expect(session.recentProjects.newProjectLocation == folder.path)
    }

    // MARK: Showing and leaving

    @Test func closeProjectReturnsToTheLauncher() throws {
        let folder = temporaryDirectory()
        let app = launcherApp(launcher: .never)
        let session = app.session
        #expect(!app.isLauncherShown)
        try session.commands.run(ProjectNewCommand.self, .init(name: "Closer", location: folder.path, template: .starter))
        try session.commands.run(EntityCreateCommand.self, .init(template: .cube))
        #expect(session.document.isDirty)

        // The toolbar's Close Project asks first when there are unsaved changes.
        let close = try #require(app.ui.accessibilityElements().first { $0.label == "Close Project" && $0.role == .button })
        #expect(close.command == LauncherShowCommand.id.rawValue)
        app.ui.synthesizeClick(at: close.clickPoint)
        app.syncPanels()
        let dialog = try #require(app.ui.overlays.last as? ConfirmDialog)
        #expect(dialog.name == "closeProjectDialog" && dialog.command == LauncherShowCommand.id.rawValue)
        dialog.resolve(confirmed: false)
        #expect(session.project != nil && !app.isLauncherShown)
        app.ui.synthesizeClick(at: close.clickPoint)
        try #require(app.ui.overlays.last as? ConfirmDialog).resolve(confirmed: true)
        app.syncPanels()
        #expect(app.isLauncherShown && session.project == nil)
        #expect(!session.document.isDirty && session.world.entityCount > 5, "a new starter scene")
        #expect(app.toolbar.view.isHidden && app.dock.isHidden)
        let shown = app.ui.accessibilityElements().filter(\.isOnScreen)
        #expect(shown.contains { $0.label == "Closer" && $0.role == .listItem })
        #expect(!shown.contains { $0.path.hasPrefix("editorRoot/toolbar") })

        // Not while playing.
        try session.commands.run(LauncherDismissCommand.self)
        #expect(!app.isLauncherShown && session.project == nil)
        try session.commands.run(PlayStartCommand.self, .init())
        #expect(!session.commands.isAvailable(LauncherShowCommand.self))
        try session.commands.run(PlayStopCommand.self)
        // Without a project, Close Project still goes back to the launcher.
        try session.commands.run(LauncherShowCommand.self)
        #expect(app.isLauncherShown)
        #expect(!session.commands.isAvailable(LauncherShowCommand.self) == false)
        // A plain session (no UI) can't show it.
        let plain = EditorSession()
        plain.log.echoesToStandardOutput = false
        #expect(!plain.commands.isAvailable(LauncherShowCommand.self))
    }

    @Test func keyboardNavigation() throws {
        let folder = temporaryDirectory()
        let app = launcherApp()
        let session = app.session
        let clock = TestClock()
        session.recentProjects.now = { clock.tick() }
        for name in ["One", "Two", "Three"] {
            try session.commands.run(ProjectNewCommand.self, .init(name: name, location: folder.path, template: .empty))
        }
        try session.commands.run(LauncherShowCommand.self)
        let launcher = app.launcher!
        #expect(launcher.list.entries.map(\.name) == ["Three", "Two", "One"])
        #expect(app.ui.focusedWidget === launcher.list && launcher.list.selectedRow == 0)

        app.pressKey(KeyEvent(key: .down))
        app.pressKey(KeyEvent(key: .down))
        #expect(launcher.list.selectedEntry?.name == "One")
        app.pressKey(KeyEvent(key: .up))
        #expect(launcher.list.selectedEntry?.name == "Two")
        // Delete removes the selected project from the list; the next one is selected.
        app.pressKey(KeyEvent(key: .delete))
        #expect(launcher.list.entries.map(\.name) == ["Three", "One"])
        #expect(launcher.list.selectedEntry?.name == "One")
        // Enter opens it (with its scene) and leaves the launcher.
        app.pressKey(KeyEvent(key: .enter))
        #expect(!app.isLauncherShown && session.project?.name == "One")

        try session.commands.run(LauncherShowCommand.self)
        // Cmd/Ctrl+N: New Project with the name field focused; Esc goes back.
        app.pressKey(KeyEvent(key: .n, modifiers: .shortcut))
        #expect(launcher.page == .newProject && app.ui.focusedWidget === launcher.nameField)
        app.pressKey(KeyEvent(key: .escape))
        #expect(launcher.page == .recent)
        // Cmd/Ctrl+O: the Open form (the native dialog never opens headless).
        app.pressKey(KeyEvent(key: .o, modifiers: .shortcut))
        #expect(launcher.page == .open && app.ui.focusedWidget === launcher.openField)
        app.pressKey(KeyEvent(key: .escape))
        // Cmd/Ctrl+F: the search field; typing filters, Enter opens the first match.
        app.pressKey(KeyEvent(key: .f, modifiers: .shortcut))
        #expect(app.ui.focusedWidget === launcher.search)
        launcher.search.text = "thr"
        launcher.sync()
        #expect(launcher.list.entries.map(\.name) == ["Three"])
        launcher.search.onSubmit?("thr")
        #expect(!app.isLauncherShown && session.project?.name == "Three")
        // The editor's shortcuts don't run on the launcher (Cmd+S would save the hidden scene).
        try session.commands.run(LauncherShowCommand.self)
        let undo = session.undo.undoDepth
        app.pressKey(KeyEvent(key: .d, modifiers: .shortcut))
        #expect(session.undo.undoDepth == undo)
    }

    @Test func newProjectAndOpenForms() throws {
        let folder = temporaryDirectory()
        let app = launcherApp()
        let session = app.session
        let launcher = app.launcher!
        // The empty state.
        let empty = app.ui.accessibilityElements().filter(\.isOnScreen)
        #expect(empty.contains { $0.label == "Create your first project" })
        #expect(empty.contains { $0.path.hasSuffix("emptyNew") && $0.command == ProjectNewCommand.id.rawValue })

        launcher.showNewProject(location: folder.path)
        #expect(launcher.nameField.text == "My Game")
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("My Game"), withIntermediateDirectories: true)
        launcher.showNewProject(location: folder.path)
        #expect(launcher.nameField.text == "My Game 2", "a name whose folder doesn't exist yet")
        launcher.nameField.text = "bad/name"
        launcher.sync()
        #expect(!launcher.createButton.isEnabled && !launcher.newError.isHidden)
        launcher.nameField.text = "Formed"
        launcher.sync()
        #expect(launcher.createButton.isEnabled)
        // The template buttons pick the template; Create makes and opens it.
        let gameButton = try #require(launcher.templateButtons.first { $0.0 == .empty }?.1)
        gameButton.activate()
        launcher.createButton.activate()
        #expect(!app.isLauncherShown && session.project?.name == "Formed")
        #expect(session.project?.root.path == folder.appendingPathComponent("Formed").standardizedFileURL.path)

        // Open: a folder that isn't a project offers Create Project Here; a project enables Open.
        try session.commands.run(LauncherShowCommand.self)
        launcher.showOpen()
        launcher.openField.text = folder.appendingPathComponent("My Game").path
        launcher.sync()
        #expect(!launcher.openConfirm.isEnabled && !launcher.createHereButton.isHidden)
        #expect(launcher.openStatus.text.contains("isn't a project"))
        launcher.createHereButton.activate()
        #expect(launcher.page == .newProject && launcher.nameField.text == "My Game")
        #expect(launcher.locationField.text == folder.path)
        launcher.showOpen()
        launcher.openField.text = folder.appendingPathComponent("Formed/Project.json").path
        launcher.sync()
        #expect(launcher.openConfirm.isEnabled && launcher.createHereButton.isHidden)
        launcher.openConfirm.activate()
        #expect(!app.isLauncherShown && session.project?.name == "Formed")
        // Continue Without Project.
        try session.commands.run(LauncherShowCommand.self)
        launcher.continueButton.activate()
        #expect(!app.isLauncherShown && session.project == nil)
    }

    @Test func rowMenuAndPinButton() throws {
        let folder = temporaryDirectory()
        let app = launcherApp()
        let session = app.session
        try session.commands.run(ProjectNewCommand.self, .init(name: "Menu Test", location: folder.path, template: .empty))
        try session.commands.run(LauncherShowCommand.self)
        func element(_ label: String) throws -> UIAccessibilityElement {
            try #require(app.ui.accessibilityElements().first { $0.label == label && $0.isOnScreen }, "\(label)")
        }
        app.ui.synthesizeClick(at: try element("Pin Menu Test").clickPoint)
        app.syncPanels()
        #expect(session.recentProjects.entries.first?.pinned == true)
        #expect(try element("Unpin Menu Test").command == ProjectRecentPinCommand.id.rawValue)
        app.ui.synthesizeClick(at: try element("More actions for Menu Test").clickPoint)
        let menu = try #require(app.ui.overlays.last as? PopupMenu)
        #expect(menu.items.contains("Open") && menu.items.contains("Unpin") && menu.items.contains("Remove from List"))
        #expect(menu.items.contains("Copy Path"))
        let memory = MemoryClipboard()
        app.ui.clipboard = memory
        menu.onSelect?(try #require(menu.items.firstIndex(of: "Copy Path")))
        #expect(memory.string == session.recentProjects.entries.first?.path)
        app.ui.dismissOverlay(menu)
        // Right click opens the same menu.
        app.ui.synthesizeClick(at: try element("Menu Test").clickPoint, button: .right)
        let again = try #require(app.ui.overlays.last as? PopupMenu)
        again.onSelect?(try #require(again.items.firstIndex(of: "Remove from List")))
        app.syncPanels()
        #expect(session.recentProjects.entries.isEmpty)
        #expect(app.ui.accessibilityElements().contains { $0.label == "Create your first project" && $0.isOnScreen })
    }

    // MARK: MCP

    @Test func mcpCommandsAndTheSandbox() throws {
        let workspace = temporaryDirectory()
        let outside = temporaryDirectory()
        let app = launcherApp()
        let client = LauncherClient(app, workspace: workspace)

        var result = client.call("project.recent.list")
        #expect(result["isError"] == false && result["structuredContent"]?["launcherShown"] == true)
        #expect(result["structuredContent"]?["projects"]?.arrayValue?.isEmpty == true)

        // New projects inside the sandbox; outside it (or climbing out) is refused like any other path.
        result = client.call("project.new", ["name": "Inside", "location": .string(workspace.path), "template": "starter"])
        #expect(result["isError"] == false, "\(client.text(result))")
        #expect(app.session.project?.name == "Inside" && !app.isLauncherShown)
        // The sandbox is now the project: launcher.show closes it (the scene is unchanged, no confirm needed).
        result = client.call("launcher.show")
        #expect(result["isError"] == false, "\(client.text(result))")
        #expect(app.isLauncherShown)
        result = client.call("project.new", ["name": "Escapee", "location": .string(outside.path), "template": "empty"])
        #expect(result["isError"] == true)
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("Escapee").path))
        result = client.call("project.new", ["path": "../Climber"])
        #expect(result["isError"] == true)

        // A dirty scene: launcher.show and template / last-scene opens need confirm: true.
        try app.session.commands.run(LauncherDismissCommand.self)
        try app.session.commands.run(EntityCreateCommand.self, .init(template: .cube))
        result = client.call("launcher.show")
        #expect(result["isError"] == true && client.text(result).contains("confirm"))
        result = client.call("project.new", ["name": "Second", "location": .string(workspace.path), "template": "empty"])
        #expect(result["isError"] == true && client.text(result).contains("confirm"))
        result = client.call("launcher.show", ["confirm": true])
        #expect(result["isError"] == false && app.isLauncherShown)

        // Pin, list, open by name, remove.
        #expect(client.call("project.recent.pin", ["path": "Inside"])["structuredContent"]?["pinned"] == true)
        let listed = client.call("project.recent.list", ["query": "insi"])["structuredContent"]?["projects"]?.arrayValue ?? []
        #expect(listed.count == 1 && listed.first?["name"] == "Inside" && listed.first?["missing"] == false)
        #expect(listed.first?["lastScene"]?.stringValue?.hasSuffix("Main.scene") == true)
        result = client.call("project.open", ["path": "Inside", "openLastScene": true])
        #expect(result["isError"] == false, "\(client.text(result))")
        #expect(app.session.document.url?.lastPathComponent == "Main.scene" && !app.isLauncherShown)
        #expect(client.call("launcher.settings", ["reopenLastProject": true])["structuredContent"]?["reopenLastProject"] == true)
        #expect(client.call("project.recent.reveal", ["path": "Inside"])["isError"] == false)
        #expect(client.call("project.recent.remove", ["path": "Inside"])["isError"] == false)
        #expect(client.call("project.recent.remove", ["path": "Inside"])["isError"] == true)
        // launcher.dismiss only while it is shown.
        #expect(client.call("launcher.dismiss")["isError"] == true)

        // The tools are listed with their hints.
        let tools = Dictionary(uniqueKeysWithValues: client.mcp.tools.map { ($0.name, $0) })
        for name in ["launcher.show", "launcher.dismiss", "launcher.settings", "project.recent.list", "project.recent.remove",
                     "project.recent.pin", "project.recent.locate", "project.recent.reveal", "project.new", "project.open", "project.close"] {
            #expect(tools[name] != nil, "\(name)")
        }
        #expect(tools["project.recent.list"]?.annotations?.readOnlyHint == true)
        #expect(tools["launcher.show"]?.annotations?.destructiveHint == true)
    }
}

/// A clipboard that isn't the system's.
private final class MemoryClipboard: UIClipboard {
    var string: String?
}
