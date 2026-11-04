import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Editor settings and project settings: the commands, the prefs, play mode, the AI sandbox and
// the Settings window.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("SettingsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @Suite struct SettingsTests {
    @Test func editorSettingsChangeValidateAndReset() throws {
        let session = makeSession()
        var notified = 0
        session.onEditorSettingsChange = { notified += 1 }
        let result = try session.commands.run(SettingsSetEditorCommand.self, .init(snapTranslate: 0.25, cameraFlySpeed: 12))
        #expect(result.snapTranslate == 0.25 && result.cameraFlySpeed == 12 && result.snapRotateDegrees == 15)
        #expect(session.editorSettings == result && notified == 1)
        #expect(throws: (any Error).self) { try session.commands.run(SettingsSetEditorCommand.self, .init(cameraFieldOfView: 500)) }
        #expect(throws: (any Error).self) { try session.commands.run(SettingsSetEditorCommand.self, .init(snapScale: .nan)) }
        #expect(session.editorSettings.cameraFieldOfView == EditorSettings.defaultFieldOfView)
        let reset = try session.commands.run(SettingsSetEditorCommand.self, .init(snapScale: 0.5, reset: true))
        #expect(reset == EditorSettings(snapScale: 0.5))
        // The gizmo gets the steps.
        let snapping = reset.gizmoSnapping(enabled: true)
        #expect(snapping.isEnabled && snapping.scaleStep == 0.5 && snapping.translateStep == 0.5)
    }

    @Test func editorSettingsPersistInThePrefsTolerantly() throws {
        var prefs = EditorPrefs()
        prefs.editor = EditorSettings(snapRotateDegrees: 45, cameraFlySpeed: 20)
        let url = temporaryDirectory().appendingPathComponent("prefs.json")
        let store = EditorPrefsStore(url: url)
        try store.save(prefs)
        #expect(try store.load()?.editor == prefs.editor)
        // Missing keys get defaults, out-of-range ones are clamped.
        let decoded = try JSONDecoder().decode(EditorSettings.self, from: Data(#"{"snapTranslate": -3, "cameraFieldOfView": 90}"#.utf8))
        #expect(decoded.snapTranslate == EditorSettings.snapTranslateRange.lowerBound)
        #expect(decoded.cameraFieldOfView == 90 && decoded.snapScale == 0.1)
    }

    @Test func projectSettingsAreWrittenToProjectJSON() throws {
        let session = makeSession()
        #expect(!session.commands.isAvailable(SettingsSetProjectCommand.self))
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path))
        let runtime = ProjectRuntimeSettings(window: .init(title: "My Game", width: 1600, height: 900, vsync: false, quality: .ultra),
                                             physics: .init(gravity: Vec3(0, -20, 0), fixedTimestep: 1.0 / 120))
        let result = try session.commands.run(SettingsSetProjectCommand.self, .init(
            name: " Renamed ", build: GameBuildSettings(scenes: ["Scenes/Main.scene"], output: "Out"), runtime: runtime))
        #expect(result.project.name == "Renamed")
        let reopened = try Project.open(at: root)
        #expect(reopened.settings.name == "Renamed" && reopened.settings.runtime == runtime)
        #expect(reopened.settings.build?.scenes == ["Scenes/Main.scene"] && reopened.settings.build?.output == "Out")
        #expect(session.project?.settings == reopened.settings)
        let snapshot = try session.commands.run(SettingsGetCommand.self)
        #expect(snapshot.project == reopened.settings && snapshot.projectPath == root.standardizedFileURL.path)

        // Bad values are refused and nothing changes; clear removes sections.
        #expect(throws: (any Error).self) {
            try session.commands.run(SettingsSetProjectCommand.self, .init(runtime: .init(physics: .init(fixedTimestep: 5))))
        }
        #expect(throws: (any Error).self) { try session.commands.run(SettingsSetProjectCommand.self, .init(clear: ["nope"])) }
        #expect(try Project.open(at: root).settings.runtime == runtime)
        try session.commands.run(SettingsSetProjectCommand.self, .init(clear: ["runtime", "build"]))
        let cleared = try Project.open(at: root).settings
        #expect(cleared.runtime == nil && cleared.build == nil)
        #expect(try String(contentsOf: root.appendingPathComponent("Project.json"), encoding: .utf8).contains("runtime") == false)
    }

    @Test func aiClientsCantChangeWhichCodeRunsOrWhereFilesGo() throws {
        let session = makeSession()
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path))
        let game = try Project.open(at: root).settings.game  // the new project's own package
        session.fileAccessRoots = [root]
        defer { session.fileAccessRoots = nil }
        #expect(throws: (any Error).self) {
            try session.commands.run(SettingsSetProjectCommand.self, .init(game: GameModuleSettings(target: "X", buildCommand: ["sh", "-c", "evil"])))
        }
        #expect(throws: (any Error).self) {
            try session.commands.run(SettingsSetProjectCommand.self, .init(build: GameBuildSettings(output: "/tmp/elsewhere")))
        }
        #expect(throws: (any Error).self) {
            try session.commands.run(SettingsSetProjectCommand.self, .init(build: GameBuildSettings(enginePackage: "/somewhere")))
        }
        #expect(try Project.open(at: root).settings.game == game)
        // Everything else is fine.
        try session.commands.run(SettingsSetProjectCommand.self, .init(build: GameBuildSettings(scenes: ["Scenes/A.scene"]),
                                                                       runtime: .init(physics: .init(gravity: Vec3(0, -1, 0)))))
        #expect(try Project.open(at: root).settings.runtime?.physics?.gravity == Vec3(0, -1, 0))
    }

    @Test func playModeUsesTheProjectsPhysicsSettings() throws {
        let session = makeSession()
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path, template: .starter))
        try session.commands.run(SettingsSetProjectCommand.self, .init(
            runtime: .init(physics: .init(gravity: Vec3(0, -3, 0), fixedTimestep: 1.0 / 30))))
        let floor = session.world.entities.first { session.world.get(MeshRenderer.self, for: $0) != nil }!
        session.world.add(Collider(.box(halfExtents: Vec3(1, 1, 1))), to: floor)
        let before = session.world.fixedTimestep
        try session.commands.run(PlayStartCommand.self, .init())
        #expect(session.world.fixedTimestep == 1.0 / 30)
        #expect(session.physics?.gravity == Vec3(0, -3, 0))
        try session.commands.run(PlayStopCommand.self, .init())
        #expect(session.world.fixedTimestep == before)
    }

    @Test func runtimeSettingsApplyToTheEngineConfig() throws {
        var config = EngineConfig(title: "Game", showDebugOverlay: false)
        let runtime = ProjectRuntimeSettings(window: .init(title: "Neon", width: 800, height: 600, vsync: false, quality: .low,
                                                           showDebugOverlay: true))
        runtime.apply(to: &config)
        #expect(config.title == "Neon" && config.width == 800 && config.height == 600)
        #expect(!config.vsync && config.quality == .low && config.showDebugOverlay)
        #expect(ProjectRuntimeSettings(window: .init(width: 10)).validationError() != nil)
        #expect(ProjectRuntimeSettings(window: .init()).isEmpty)
    }

    @Test func videoSettingsApplyToTheEngineConfig() throws {
        var config = EngineConfig()
        let window = ProjectRuntimeSettings.Window(renderResolution: "1080p", upscaler: "fsr3", upscalerSharpness: 0.1, msaa: 2,
                                                   backend: .vulkan, minWidth: 640, allowLargerThanScreen: true)
        ProjectRuntimeSettings(window: window).apply(to: &config)
        #expect(config.renderResolution == .fixed(width: 1920, height: 1080))
        #expect(config.upscaler == .fsr3(sharpness: 0.1))
        #expect(config.sampleCount == 2 && config.backend == .vulkan && config.allowsWindowLargerThanScreen)
        #expect(config.minimumWindowSize?.width == 640 && config.minimumWindowSize?.height == 64)

        var scaled = EngineConfig()
        ProjectRuntimeSettings(window: .init(renderResolution: "performance", upscaler: "taau")).apply(to: &scaled)
        #expect(scaled.renderResolution == .scaled(2) && scaled.upscaler == .taau())

        let data = try JSONEncoder().encode(ProjectRuntimeSettings(window: window))
        #expect(try JSONDecoder().decode(ProjectRuntimeSettings.self, from: data).window == window)

        #expect(ProjectRuntimeSettings(window: .init(renderResolution: "huge")).validationError() != nil)
        #expect(ProjectRuntimeSettings(window: .init(upscaler: "dlss")).validationError() != nil)
        #expect(ProjectRuntimeSettings(window: .init(msaa: 3)).validationError() != nil)
        #expect(ProjectRuntimeSettings(window: .init(renderResolution: "1x99999")).validationError() != nil)
        #expect(ProjectRuntimeSettings(window: window).validationError() == nil)
        #expect(SettingsDialog.resolutionChoices(current: "1234x567").last?.value == "1234x567")
        #expect(SettingsDialog.resolutionChoices(current: "1080p").filter { $0.value == "1080p" }.count == 1)
    }

    @Test func settingsWindowOpensFromTheShortcutAndAppliesFields() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let session = app.session
        let ui = app.ui!
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path))
        app.syncPanels()
        app.pressKey(KeyEvent(key: .comma, modifiers: .shortcut))
        let dialog = try #require(app.settingsDialog)
        #expect(ui.overlays.last === dialog && dialog.tab == .editor)
        // A change made elsewhere shows in the open window.
        try session.commands.run(SettingsSetEditorCommand.self, .init(cameraFlySpeed: 42))
        app.syncPanels()
        let fly = try #require(numberField(named: "settingsFlySpeed", in: dialog))
        #expect(fly.value == 42)
        #expect(app.viewport.flySpeed == 42)
        // The Project tab shows the project.
        dialog.select(.project)
        app.syncPanels()
        #expect(numberField(named: "settingsWindowWidth", in: dialog)?.value == 1280)
        // Esc closes it.
        app.pressKey(KeyEvent(key: .escape))
        #expect(app.settingsDialog == nil && !ui.overlays.contains { $0 === dialog })
    }

    @Test func gameTargetsAreTheModulesWithAnEntryPoint() {
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let targets = ProjectChoices.gameTargets(in: package)
        #expect(targets.contains("SampleGame") && targets.contains("Orbfall"))
        #expect(!targets.contains("Engine") && !targets.contains("EditorCore") && !targets.contains("Editor"))
    }

    @Test func settingsWindowPicksTheGameTargetAndBuildScenes() throws {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        app.setupWithoutWindow()
        let session = app.session
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path, template: .starter))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Assets/Scenes"), withIntermediateDirectories: true)
        try session.commands.run(SceneSaveAsCommand.self, .init(path: "Assets/Scenes/Second.scene"))
        try session.commands.run(AssetWaitForImportsCommand.self, .init())
        #expect(try session.commands.run(SettingsGetCommand.self).scenes == ["Scenes/Main.scene", "Scenes/Second.scene"])
        app.showSettings(tab: .project)
        app.syncPanels()
        let dialog = try #require(app.settingsDialog)

        // Scenes: the starter's Main.scene is listed; add the other one, make it the start scene, remove Main.
        #expect(session.project?.settings.build?.scenes == ["Scenes/Main.scene"])
        let add = try #require(widget(named: "settingsSceneAdd", in: dialog) as? Dropdown)
        #expect(add.options.last == "Scenes/Second.scene")
        add.onChange?(add.options.count - 1)
        #expect(session.project?.settings.build?.scenes == ["Scenes/Main.scene", "Scenes/Second.scene"])
        app.syncPanels()
        #expect((widget(named: "settingsSceneAddOpen", in: dialog) as? Button)?.isEnabled == false)  // already listed
        (widget(named: "settingsSceneMakeStart", in: dialog) as? Button)?.action?()
        #expect(session.project?.settings.build?.scenes == ["Scenes/Second.scene", "Scenes/Main.scene"])
        app.syncPanels()
        (widget(named: "settingsSceneRemove", in: dialog, last: true) as? Button)?.action?()
        #expect(try Project.open(at: root).settings.build?.scenes == ["Scenes/Second.scene"])

        // Target: the package's game modules once the package is set.
        let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        try session.commands.run(SettingsSetProjectCommand.self, .init(game: GameModuleSettings(package: package.path)))
        app.syncPanels()
        let target = try #require(widget(named: "settingsGameTarget", in: dialog) as? Dropdown)
        let index = try #require(target.options.firstIndex(of: "Orbfall"))
        target.select(index)
        target.onChange?(index)
        #expect(session.project?.settings.game?.target == "Orbfall")
        target.onChange?(0)
        #expect(session.project?.settings.game?.target == nil && session.project?.settings.game?.package == package.path)
    }

    @Test func codeEditorCommandLines() throws {
        let file = URL(fileURLWithPath: "/p/My Game/Sources/Game.swift")
        #expect(try ExternalLaunch.openCommand(file, with: .vscode, customCommand: nil, platform: .macOS)
                == ["/usr/bin/open", "-a", "Visual Studio Code", file.path])
        #expect(try ExternalLaunch.openCommand(file, with: .vscode, customCommand: nil, platform: .linux) == ["/usr/bin/env", "code", file.path])
        #expect(try ExternalLaunch.openCommand(file, with: .system, customCommand: nil, platform: .linux) == ["/usr/bin/env", "xdg-open", file.path])
        #expect(throws: (any Error).self) { try ExternalLaunch.openCommand(file, with: .xcode, customCommand: nil, platform: .linux) }
        #expect(try ExternalLaunch.openCommand(file, with: .custom, customCommand: #"nvim-qt --cwd "a b" {path}"#, platform: .macOS)
                == ["/usr/bin/env", "nvim-qt", "--cwd", "a b", file.path])
        #expect(try ExternalLaunch.openCommand(file, with: .custom, customCommand: "emacs", platform: .linux) == ["/usr/bin/env", "emacs", file.path])
        #expect(throws: (any Error).self) { try ExternalLaunch.openCommand(file, with: .custom, customCommand: "  ", platform: .macOS) }
        #expect(ExternalLaunch.revealCommand(file, platform: .macOS) == ["/usr/bin/open", "-R", file.path])
        #expect(ExternalLaunch.openTitle(.zed) == "Open in Zed")
    }

    @Test func revealAndOpenResolveProjectPathsAndStayInTheSandbox() throws {
        let session = makeSession()
        let root = temporaryDirectory().appendingPathComponent("Game")
        try session.commands.run(ProjectNewCommand.self, .init(path: root.path, template: .starter))
        try session.commands.run(SettingsSetEditorCommand.self, .init(codeEditor: .cursor))
        // An Assets-relative path, a project-relative one and the default (the project folder: no game code).
        let scene = try session.commands.run(FileOpenInCodeEditorCommand.self, .init(path: "Scenes/Main.scene"))
        #expect(scene.path.hasSuffix("Assets/Scenes/Main.scene") && !scene.launched)  // no window: not run
        #expect(scene.command.contains(scene.path) && scene.command.contains(ExternalLaunch.current == .macOS ? "Cursor" : "cursor"))
        #expect(try session.commands.run(FileRevealCommand.self, .init(path: "Project.json")).path.hasSuffix("Game/Project.json"))
        #expect(try session.commands.run(FileRevealCommand.self, .init()).path == root.standardizedFileURL.path)
        #expect(throws: (any Error).self) { try session.commands.run(FileRevealCommand.self, .init(path: "Nope.txt")) }
        // AI clients: only inside the project, and never the custom command.
        session.fileAccessRoots = [root]
        defer { session.fileAccessRoots = nil }
        #expect(throws: (any Error).self) { try session.commands.run(FileRevealCommand.self, .init(path: "/etc/hosts")) }
        #expect(throws: (any Error).self) {
            try session.commands.run(SettingsSetEditorCommand.self, .init(codeEditor: .custom, codeEditorCommand: "rm -rf {path}"))
        }
        #expect(session.editorSettings.codeEditorCommand == nil && session.editorSettings.codeEditor == .cursor)
        try session.commands.run(SettingsSetEditorCommand.self, .init(codeEditor: .zed))  // presets are fine
        #expect(session.editorSettings.codeEditor == .zed)
    }

    private func widget(named name: String, in root: Widget, last: Bool = false) -> Widget? {
        var found: [Widget] = []
        func visit(_ widget: Widget) {
            if widget.name == name { found.append(widget) }
            widget.children.forEach(visit)
        }
        visit(root)
        return last ? found.last : found.first
    }

    private func numberField(named name: String, in widget: Widget) -> NumberField? {
        if let field = widget as? NumberField, field.name == name { return field }
        for child in widget.children { if let found = numberField(named: name, in: child) { return found } }
        return nil
    }
}
