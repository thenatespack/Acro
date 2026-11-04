import Engine
import Foundation

/// The Settings window: a modal card over the editor with two tabs.
///
/// - **Editor**: the user's settings, kept in the prefs: theme and UI zoom (`view.appearance`),
///   gizmo snapping and the viewport camera (`tool.snapping`, `settings.setEditor`), reopening
///   the last project (`launcher.settings`) and what AI clients may do (`ai.settings`).
/// - **Project**: the open project's `Project.json` (`settings.setProject`): name, game window,
///   physics, Build Game's defaults and the game code.
///
/// Every field applies at once by running its command (numbers when the edit ends, text on
/// Enter or when the field loses focus), so there is no Save button; a value the command
/// refuses snaps back and the reason goes to the console. Open it with the View menu's
/// Settings… item or Cmd+, (Ctrl+, elsewhere); Esc or Done closes it.
@MainActor
public final class SettingsDialog: Widget {
    public enum Tab: String, CaseIterable, Sendable {
        case editor, project

        var title: String { self == .editor ? "Editor" : "Project" }
    }

    private unowned let app: EditorApp
    private var session: EditorSession { app.session }
    public private(set) var tab: Tab
    private let card: VStack
    private let body = VStack(spacing: 6, padding: EdgeInsets(top: 4, left: 2, bottom: 12, right: 12), name: "settingsBody")
    private let scroll: ScrollView
    private var tabButtons: [(Tab, Button)] = []
    private let resetButton = Button("Reset Editor Settings", name: "settingsReset")
    /// Pushes the current values into the fields (skipping ones being edited).
    private var refreshers: [() -> Void] = []
    /// The project the Project tab was built for (rebuilt when another one opens).
    private var builtProjectRoot: URL?
    private var isClosed = false

    /// Called after the dialog closed.
    public var onClose: (() -> Void)?

    /// Width of the label column, in points.
    static let labelWidth: Float = 190

    public init(app: EditorApp, tab: Tab = .editor) {
        self.app = app
        self.tab = tab
        scroll = ScrollView(body, name: "settingsScroll")
        scroll.style.grow = 1
        scroll.style.shrink = 1
        let heading = Label("Settings", role: .heading, name: "settingsTitle")
        let done = Button("Done", role: .primary, name: "settingsDone")
        done.command = SettingsGetCommand.id.rawValue
        let header = HStack(spacing: 8, name: "settingsHeader", [heading, Spacer(), done])
        let tabs = HStack(spacing: 4, name: "settingsTabs")
        resetButton.command = SettingsSetEditorCommand.id.rawValue
        resetButton.tooltip = "Snap steps and the viewport camera back to their defaults"
        card = VStack(spacing: 10, padding: EdgeInsets(18), name: "settingsCard", [header, tabs, Separator(), scroll])
        super.init(name: "settingsDialog")
        card.background = .clear  // drawn by `draw`, with its shadow
        addChild(card)
        for each in Tab.allCases {
            let button = Button(each.title, name: "settingsTab.\(each.rawValue)") { [unowned self] in select(each) }
            button.command = SettingsGetCommand.id.rawValue
            button.tooltip = each == .editor ? "Your editor settings, for every project" : "The open project's settings (Project.json)"
            tabs.addChild(button)
            tabButtons.append((each, button))
        }
        done.action = { [unowned self] in close() }
        resetButton.action = { [unowned self] in
            session.run(SettingsSetEditorCommand.self, .init(reset: true))
            refresh()
        }
        rebuild()
    }

    public override var accessibilityRole: UIAccessibilityRole { .dialog }
    public override var accessibilityText: String? { "Settings" }

    /// Shows the dialog over everything in `context`.
    public func present(in context: UIContext) {
        context.presentOverlay(self)
    }

    /// Closes the dialog (like Done or Esc).
    public func close() {
        guard !isClosed else { return }
        context?.dismissOverlay(self)
        finishClosing()
    }

    public override func overlayDismissed() { finishClosing() }

    private func finishClosing() {
        guard !isClosed else { return }
        isClosed = true
        onClose?()
    }

    /// Shows `tab`.
    public func select(_ tab: Tab) {
        guard tab != self.tab else { return }
        self.tab = tab
        rebuild()
    }

    /// Pushes the current settings into the fields; rebuilds the Project tab when the project changed.
    public func refresh() {
        if tab == .project, builtProjectRoot != session.project?.root {
            rebuild()
            return
        }
        for refresher in refreshers { refresher() }
        for (each, button) in tabButtons {
            let role: Button.Role = each == tab ? .primary : .normal
            if button.role != role { button.role = role }
        }
    }

    private func rebuild() {
        body.removeAllChildren()
        refreshers = []
        switch tab {
        case .editor: buildEditorTab()
        case .project: buildProjectTab()
        }
        scroll.scroll(to: 0)
        refresh()
    }

    // MARK: Editor tab

    private func buildEditorTab() {
        section("Appearance")
        let themes = EditorApp.themes
        dropdown("Theme", name: "settingsTheme", command: ViewAppearanceCommand.id, options: themes,
                 get: { [unowned self] in themes.firstIndex(of: context?.theme.name ?? "") ?? 0 },
                 set: { [unowned self] index in session.run(ViewAppearanceCommand.self, .init(theme: themes[index])) })
        let zooms = EditorApp.menuZooms
        dropdown("UI zoom", name: "settingsZoom", command: ViewAppearanceCommand.id, options: zooms.map { "\(Int(($0 * 100).rounded()))%" },
                 get: { [unowned self] in zooms.firstIndex(of: app.preferredUIScale) ?? zooms.firstIndex(of: 1) ?? 0 },
                 set: { [unowned self] index in session.run(ViewAppearanceCommand.self, .init(uiScale: zooms[index])) })

        section("Gizmo snapping")
        checkbox("Snap gizmo drags", name: "settingsSnapping", command: ToolSnappingCommand.id,
                 tooltip: "Hold \(KeyModifiers.shortcut == .command ? "⌘" : "Ctrl") during a drag to invert it",
                 get: { [unowned self] in session.snapping },
                 set: { [unowned self] on in session.run(ToolSnappingCommand.self, .init(enabled: on)) })
        editorNumber("Move step (units)", name: "settingsSnapTranslate", range: EditorSettings.snapTranslateRange, step: 0.05,
                     \.snapTranslate) { .init(snapTranslate: $0) }
        editorNumber("Rotate step (°)", name: "settingsSnapRotate", range: EditorSettings.snapRotateRange, step: 1,
                     \.snapRotateDegrees) { .init(snapRotateDegrees: $0) }
        editorNumber("Scale step", name: "settingsSnapScale", range: EditorSettings.snapScaleRange, step: 0.01,
                     \.snapScale) { .init(snapScale: $0) }

        section("Viewport camera")
        editorNumber("Fly speed (units/s)", name: "settingsFlySpeed", range: EditorSettings.cameraFlySpeedRange, step: 0.5,
                     tooltip: "Right mouse button + WASD; Shift flies 4x faster", \.cameraFlySpeed) { .init(cameraFlySpeed: $0) }
        editorNumber("Field of view (°)", name: "settingsFieldOfView", range: EditorSettings.cameraFieldOfViewRange, step: 1,
                     \.cameraFieldOfView) { .init(cameraFieldOfView: $0) }

        section("Code editor", note: "What Open in Code Editor uses (the Assets panel's menu, the Project tab).")
        let editors = CodeEditorChoice.allCases
        dropdown("Open files with", name: "settingsCodeEditor", command: SettingsSetEditorCommand.id, options: editors.map(\.title),
                 get: { [unowned self] in editors.firstIndex(of: session.editorSettings.codeEditor) ?? 0 },
                 set: { [unowned self] index in session.run(SettingsSetEditorCommand.self, .init(codeEditor: editors[index])) })
        text("Custom command", name: "settingsCodeEditorCommand", command: SettingsSetEditorCommand.id,
             placeholder: "nvim-qt {path}", tooltip: "With Custom Command: the command to run; {path} is the file or folder (else it goes last)",
             get: { [unowned self] in session.editorSettings.codeEditorCommand ?? "" },
             set: { [unowned self] value in session.run(SettingsSetEditorCommand.self, .init(codeEditorCommand: value)) })
        if let field = body.children.last?.children.last {
            refreshers.append { [unowned self, unowned field] in
                let enabled = session.editorSettings.codeEditor == .custom
                if field.isEnabled != enabled { field.isEnabled = enabled }
            }
        }

        section("Startup")
        checkbox("Reopen the last project at launch", name: "settingsReopen", command: LauncherSettingsCommand.id,
                 tooltip: "Skip the launcher when the editor starts without a project or scene",
                 get: { [unowned self] in session.recentProjects.reopensLastProject },
                 set: { [unowned self] on in session.run(LauncherSettingsCommand.self, .init(reopenLastProject: on)) })

        section("AI clients")
        checkbox("Read-only", name: "settingsAIReadOnly", command: AISettingsCommand.id,
                 tooltip: "Only perception and query tools", get: { [unowned self] in session.aiSettings.readOnly },
                 set: { [unowned self] on in session.run(AISettingsCommand.self, .init(readOnly: on)) })
        checkbox("Ask before destructive changes", name: "settingsAIAsk", command: AISettingsCommand.id,
                 tooltip: "Ask here before an AI client deletes files or discards changes",
                 get: { [unowned self] in session.aiSettings.askBeforeDestructive },
                 set: { [unowned self] on in session.run(AISettingsCommand.self, .init(askBeforeDestructive: on)) })
        checkbox("HTTP server", name: "settingsAIHTTP", command: AISettingsCommand.id,
                 tooltip: "Serve MCP on localhost while the editor runs", get: { [unowned self] in session.aiSettings.httpEnabled },
                 set: { [unowned self] on in session.run(AISettingsCommand.self, .init(httpEnabled: on)) })

        body.addChild(Spacer(grow: 0, minLength: 6))
        body.addChild(HStack(spacing: 8, name: "settingsEditorFooter", [resetButton, Spacer()]))
    }

    private func editorNumber(_ label: String, name: String, range: ClosedRange<Float>, step: Double, tooltip: String? = nil,
                              _ keyPath: KeyPath<EditorSettings, Float>,
                              arguments: @escaping (Float) -> SettingsSetEditorCommand.Arguments) {
        number(label, name: name, command: SettingsSetEditorCommand.id, range: Double(range.lowerBound)...Double(range.upperBound),
               step: step, tooltip: tooltip, get: { [unowned self] in Double(session.editorSettings[keyPath: keyPath]) },
               set: { [unowned self] value in session.run(SettingsSetEditorCommand.self, arguments(Float(value))) })
    }

    // MARK: Project tab

    private var project: ProjectSettings { session.project?.settings ?? ProjectSettings(name: "") }

    private func buildProjectTab() {
        builtProjectRoot = session.project?.root
        guard let root = session.project?.root else {
            let note = Label("Open or create a project to edit its settings.", role: .secondary, name: "settingsNoProject")
            note.wraps = true
            body.addChild(note)
            return
        }
        let setProject = SettingsSetProjectCommand.id

        section("General")
        text("Name", name: "settingsProjectName", command: setProject, placeholder: root.lastPathComponent,
             get: { [unowned self] in project.name }, set: { [unowned self] value in updateProject { $0.name = value } })
        let folder = Label(root.path, role: .secondary, name: "settingsProjectFolder")
        folder.style.shrink = 1
        folder.style.minWidth = 0
        row("Folder", folder)
        buttons([
            (ExternalLaunch.revealTitle, "settingsRevealProject", FileRevealCommand.id, { [unowned self] in
                session.run(FileRevealCommand.self, .init(path: root.path))
            }),
            (nil, "settingsOpenProject", FileOpenInCodeEditorCommand.id, { [unowned self] in
                session.run(FileOpenInCodeEditorCommand.self, .init(path: root.path))
            }),
        ])

        section("Game window", note: "Used by exported games (Build Game).")
        text("Title", name: "settingsWindowTitle", command: setProject, placeholder: "The game's name",
             get: { [unowned self] in project.runtime?.window?.title ?? "" },
             set: { [unowned self] value in updateWindow { $0.title = value.isEmpty ? nil : value } })
        let sizes = ProjectRuntimeSettings.windowSizeRange
        number("Width", name: "settingsWindowWidth", command: setProject, range: Double(sizes.lowerBound)...Double(sizes.upperBound),
               step: 16, isInteger: true, get: { [unowned self] in Double(project.runtime?.window?.width ?? 1280) },
               set: { [unowned self] value in updateWindow { $0.width = Int(value) } })
        number("Height", name: "settingsWindowHeight", command: setProject, range: Double(sizes.lowerBound)...Double(sizes.upperBound),
               step: 16, isInteger: true, get: { [unowned self] in Double(project.runtime?.window?.height ?? 720) },
               set: { [unowned self] value in updateWindow { $0.height = Int(value) } })
        let qualities: [RenderQuality?] = [nil] + RenderQuality.allCases
        dropdown("Render quality", name: "settingsQuality", command: setProject,
                 options: qualities.map { $0.map { $0.rawValue.capitalized } ?? "Default (High)" },
                 get: { [unowned self] in qualities.firstIndex(of: project.runtime?.window?.quality) ?? 0 },
                 set: { [unowned self] index in updateWindow { $0.quality = qualities[index] } })
        checkbox("VSync", name: "settingsVSync", command: setProject, tooltip: "Cap the frame rate at the display's refresh rate",
                 get: { [unowned self] in project.runtime?.window?.vsync ?? true },
                 set: { [unowned self] on in updateWindow { $0.vsync = on } })
        checkbox("Show the performance overlay", name: "settingsOverlay", command: setProject,
                 get: { [unowned self] in project.runtime?.window?.showDebugOverlay ?? false },
                 set: { [unowned self] on in updateWindow { $0.showDebugOverlay = on } })
        number("Minimum width", name: "settingsWindowMinWidth", command: setProject,
               range: Double(sizes.lowerBound)...Double(sizes.upperBound), step: 16, isInteger: true,
               tooltip: "The smallest width the player can resize the window to",
               get: { [unowned self] in Double(project.runtime?.window?.minWidth ?? sizes.lowerBound) },
               set: { [unowned self] value in updateWindow { $0.minWidth = Int(value) == sizes.lowerBound ? nil : Int(value) } })
        number("Minimum height", name: "settingsWindowMinHeight", command: setProject,
               range: Double(sizes.lowerBound)...Double(sizes.upperBound), step: 16, isInteger: true,
               tooltip: "The smallest height the player can resize the window to",
               get: { [unowned self] in Double(project.runtime?.window?.minHeight ?? sizes.lowerBound) },
               set: { [unowned self] value in updateWindow { $0.minHeight = Int(value) == sizes.lowerBound ? nil : Int(value) } })
        checkbox("Allow larger than the screen", name: "settingsWindowLarger", command: setProject,
                 tooltip: "Open at the full width x height even when the screen is smaller (macOS)",
                 get: { [unowned self] in project.runtime?.window?.allowLargerThanScreen ?? false },
                 set: { [unowned self] on in updateWindow { $0.allowLargerThanScreen = on ? true : nil } })

        section("Video", note: "Used by exported games (Build Game).")
        let resolutions = Self.resolutionChoices(current: project.runtime?.window?.renderResolution)
        dropdown("Render resolution", name: "settingsRenderResolution", command: setProject, options: resolutions.map(\.label),
                 tooltip: "The size the scene renders at; anything but Native is scaled into the window by the upscaler",
                 get: { [unowned self] in resolutions.firstIndex { $0.value == project.runtime?.window?.renderResolution } ?? 0 },
                 set: { [unowned self] index in updateWindow { $0.renderResolution = resolutions[index].value } })
        let upscalers = Self.upscalerChoices
        dropdown("Upscaler", name: "settingsUpscaler", command: setProject, options: upscalers.map(\.label),
                 tooltip: "How a lower render resolution is scaled up to the window. Temporal upscalers turn MSAA off",
                 get: { [unowned self] in upscalers.firstIndex { $0.value == project.runtime?.window?.upscaler } ?? 0 },
                 set: { [unowned self] index in updateWindow { $0.upscaler = upscalers[index].value } })
        number("Upscaler sharpness", name: "settingsUpscalerSharpness", command: setProject, range: 0...4, step: 0.1,
               tooltip: "Sharpening for FSR 1, TAAU and FSR 3, in stops: 0 is the sharpest, each +1 halves it",
               get: { [unowned self] in Double(project.runtime?.window?.upscalerSharpness ?? 0.4) },
               set: { [unowned self] value in updateWindow { $0.upscalerSharpness = Float(value) } })
        let samples: [Int?] = [nil] + ProjectRuntimeSettings.msaaCounts
        dropdown("Anti-aliasing (MSAA)", name: "settingsMSAA", command: setProject,
                 options: samples.map { $0.map { $0 == 1 ? "Off" : "\($0)x" } ?? "Default (from render quality)" },
                 get: { [unowned self] in samples.firstIndex(of: project.runtime?.window?.msaa) ?? 0 },
                 set: { [unowned self] index in updateWindow { $0.msaa = samples[index] } })
        let backends: [GraphicsBackend?] = [nil] + GraphicsBackend.allCases
        dropdown("Graphics API", name: "settingsBackend", command: setProject,
                 options: backends.map { $0.map { $0 == .metal ? "Metal" : "Vulkan" } ?? "Default (Metal on macOS, Vulkan elsewhere)" },
                 get: { [unowned self] in backends.firstIndex(of: project.runtime?.window?.backend) ?? 0 },
                 set: { [unowned self] index in updateWindow { $0.backend = backends[index] } })

        section("Physics", note: "Used in play mode and by exported games.")
        vector("Gravity (m/s²)", name: "settingsGravity", command: setProject, count: 3,
               get: { [unowned self] in
                   let g = project.runtime?.physics?.gravity ?? Vec3(0, -9.81, 0)
                   return [Double(g.x), Double(g.y), Double(g.z)]
               },
               set: { [unowned self] v in updatePhysics { $0.gravity = Vec3(Float(v[0]), Float(v[1]), Float(v[2])) } })
        vector("Gravity 2D (m/s²)", name: "settingsGravity2D", command: setProject, count: 2,
               get: { [unowned self] in
                   let g = project.runtime?.physics?.gravity2D ?? Vec2(0, -9.81)
                   return [Double(g.x), Double(g.y)]
               },
               set: { [unowned self] v in updatePhysics { $0.gravity2D = Vec2(Float(v[0]), Float(v[1])) } })
        let steps = ProjectRuntimeSettings.fixedTimestepRange
        number("Fixed updates per second", name: "settingsFixedRate", command: setProject,
               range: (1 / steps.upperBound).rounded()...(1 / steps.lowerBound).rounded(), step: 1, isInteger: true,
               tooltip: "How often physics and fixed-update systems run (the fixed timestep is 1 / this)",
               get: { [unowned self] in (1 / (project.runtime?.physics?.fixedTimestep ?? 1.0 / 60)).rounded() },
               set: { [unowned self] hz in updatePhysics { $0.fixedTimestep = 1 / max(hz, 1) } })

        section("Build", note: "What Build Game exports. The first scene is the one the game starts in.")
        buildScenes()
        text("App name", name: "settingsBuildName", command: setProject, placeholder: "The project's name",
             get: { [unowned self] in project.build?.name ?? "" },
             set: { [unowned self] value in updateBuild { $0.name = value.isEmpty ? nil : value } })
        text("Output folder", name: "settingsBuildOutput", command: setProject, placeholder: "Build",
             get: { [unowned self] in project.build?.output ?? "" },
             set: { [unowned self] value in updateBuild { $0.output = value.isEmpty ? nil : value } })
        let families: [TextureFamily?] = [nil] + TextureFamily.allCases
        dropdown("Texture format", name: "settingsTextureFamily", command: setProject,
                 options: families.map { $0.map { $0.rawValue.uppercased() } ?? "Default (ASTC on macOS, BC elsewhere)" },
                 get: { [unowned self] in families.firstIndex(of: project.build?.textureFamily) ?? 0 },
                 set: { [unowned self] index in updateBuild { $0.textureFamily = families[index] } })
        let modes = TextureCookMode.allCases
        dropdown("Textures", name: "settingsTextureMode", command: setProject,
                 options: modes.map { $0 == .compress ? "Compress all" : "As imported" },
                 get: { [unowned self] in modes.firstIndex(of: project.build?.textures ?? .compress) ?? 0 },
                 set: { [unowned self] index in updateBuild { $0.textures = modes[index] == .compress ? nil : modes[index] } })

        section("Game code", note: "The Swift target the editor loads and hot-reloads.")
        gameTarget()
        text("Package folder", name: "settingsGamePackage", command: setProject, placeholder: "Found by searching up from the project",
             get: { [unowned self] in project.game?.package ?? "" },
             set: { [unowned self] value in updateGame { $0.package = value.isEmpty ? nil : value } })
        buttons([
            (nil, "settingsOpenGameCode", FileOpenInCodeEditorCommand.id, { [unowned self] in
                session.run(FileOpenInCodeEditorCommand.self, .init())
            }),
        ], openSuffix: " (Package)")
        checkbox("Reload when its sources change", name: "settingsGameWatch", command: setProject,
                 get: { [unowned self] in project.game?.watch ?? false },
                 set: { [unowned self] on in updateGame { $0.watch = on ? true : nil } })
    }

    /// The Build section's scene list: a row per scene (start scene first) with Make Start and
    /// Remove, then a menu of the project's other scenes and Add Open Scene.
    private func buildScenes() {
        let setProject = SettingsSetProjectCommand.id.rawValue
        let list = VStack(spacing: 4, name: "settingsSceneList")
        var shown: [String]?
        let rebuildRows = { [unowned self, unowned list] in
            let scenes = project.build?.scenes ?? []
            guard scenes != shown else { return }
            shown = scenes
            list.removeAllChildren()
            if scenes.isEmpty {
                let none = Label("None yet: Build Game uses the open scene.", role: .caption, name: "settingsNoScenes")
                none.wraps = true
                list.addChild(none)
            }
            for (index, scene) in scenes.enumerated() {
                let title = Label(index == 0 ? "\(scene)  (start)" : scene, role: index == 0 ? .body : .secondary, name: "settingsScene")
                title.style.shrink = 1
                title.style.minWidth = 0
                var children: [Widget] = [title, Spacer()]
                if index > 0 {
                    let start = Button("Make Start", name: "settingsSceneMakeStart") { [unowned self] in
                        updateBuild { build in
                            var list = build.scenes ?? []
                            list.insert(list.remove(at: index), at: 0)
                            build.scenes = list
                        }
                    }
                    start.tooltip = "Start the game in \(scene)"
                    start.command = setProject
                    children.append(start)
                }
                let remove = Button("Remove", name: "settingsSceneRemove") { [unowned self] in
                    updateBuild { build in
                        var list = build.scenes ?? []
                        list.remove(at: index)
                        build.scenes = list.isEmpty ? nil : list
                    }
                }
                remove.tooltip = "Don't export \(scene)"
                remove.command = setProject
                children.append(remove)
                list.addChild(HStack(spacing: 6, name: "settingsSceneRow", children))
            }
        }
        rebuildRows()
        refreshers.append(rebuildRows)
        row("Scenes", list)

        let placeholder = "Add a scene…"
        let add = Dropdown(options: [placeholder], name: "settingsSceneAdd")
        add.command = setProject
        add.tooltip = "Add one of the project's scene files"
        var candidates: [String] = []
        add.onChange = { [unowned self, unowned add] index in
            guard index > 0, candidates.indices.contains(index - 1) else { return }
            let scene = candidates[index - 1]
            add.select(0)
            updateBuild { $0.scenes = ($0.scenes ?? []) + [scene] }
        }
        let addOpen = Button("Add Open Scene", name: "settingsSceneAddOpen")
        addOpen.command = setProject
        addOpen.action = { [unowned self] in
            guard let path = openSceneBuildPath() else { return }
            updateBuild { $0.scenes = ($0.scenes ?? []) + [path] }
        }
        refreshers.append { [unowned self, unowned add, unowned addOpen] in
            let included = Set(project.build?.scenes ?? [])
            let available = session.project.map(ProjectChoices.scenes(in:)) ?? []
            candidates = available.filter { !included.contains($0) }
            let options = [candidates.isEmpty ? "No other scenes in the project" : placeholder] + candidates
            if add.options != options { add.options = options }
            if add.selectedIndex != 0 { add.select(0) }
            add.isEnabled = !candidates.isEmpty
            let open = openSceneBuildPath()
            addOpen.isEnabled = open.map { !included.contains($0) } ?? false
            addOpen.tooltip = open.map { "Add \($0), the scene open in the editor" }
                ?? "Save the open scene inside the project first"
        }
        let controls = HStack(spacing: 6, name: "settingsSceneAddRow", [add, addOpen])
        add.style.grow = 1
        add.style.shrink = 1
        add.style.minWidth = 0
        row("", controls)
    }

    /// The open scene's path as Build Game takes it, when it is saved inside the project.
    private func openSceneBuildPath() -> String? {
        guard let url = session.document.url, let project = session.project else { return nil }
        return ProjectChoices.buildPath(for: url, in: project)
    }

    /// Game code's Target: the package's game module targets (`ProjectChoices.gameTargets`),
    /// None, and the current target even when it isn't found.
    private func gameTarget() {
        var choices: [String?] = []
        let menu = Dropdown(options: ["None"], name: "settingsGameTarget")
        menu.command = SettingsSetProjectCommand.id.rawValue
        menu.onChange = { [unowned self] index in
            guard choices.indices.contains(index) else { return }
            let target = choices[index]
            updateGame { $0.target = target }
        }
        refreshers.append { [unowned self, unowned menu] in
            let current = project.game?.target
            let found = session.project.map(ProjectChoices.gameTargets(for:)) ?? []
            choices = [nil] + found.map(Optional.some)
            if let current, !found.contains(current) { choices.append(current) }
            let options = choices.map { choice -> String in
                guard let choice else { return "None" }
                return found.contains(choice) ? choice : "\(choice) (not found in the package)"
            }
            if menu.options != options { menu.options = options }
            let index = choices.firstIndex(of: current) ?? 0
            if menu.selectedIndex != index { menu.select(index) }
            menu.tooltip = found.isEmpty
                ? "No game module targets found in \(session.project.flatMap(ProjectChoices.package(for:))?.path ?? "a package above the project")"
                : "The Swift target the editor loads and Build Game links (targets with a game module entry point)"
        }
        row("Target", menu)
    }

    /// Runs `settings.setProject` with the sections after `change`.
    private func updateProject(_ change: (inout ProjectSettings) -> Void) {
        guard session.project != nil else { return }
        var settings = project
        change(&settings)
        guard settings != project else { return }
        var clear: [String] = []
        if settings.game == nil { clear.append("game") }
        if settings.build == nil { clear.append("build") }
        if settings.runtime == nil { clear.append("runtime") }
        session.run(SettingsSetProjectCommand.self, .init(name: settings.name, game: settings.game, build: settings.build,
                                                          runtime: settings.runtime, clear: clear.isEmpty ? nil : clear))
        refresh()
    }

    private func updateWindow(_ change: (inout ProjectRuntimeSettings.Window) -> Void) {
        updateProject { settings in
            var runtime = settings.runtime ?? ProjectRuntimeSettings()
            var window = runtime.window ?? .init()
            change(&window)
            runtime.window = window.isEmpty ? nil : window
            settings.runtime = runtime.isEmpty ? nil : runtime
        }
    }

    /// The Render resolution menu: Default, Native, the scale modes, then the fixed presets up to
    /// 8K, plus `current` when it is a custom value (so it shows and survives).
    static func resolutionChoices(current: String?) -> [(label: String, value: String?)] {
        var choices: [(label: String, value: String?)] = [("Default (Native)", nil), ("Native", "native")]
        choices += RenderResolution.scaleModes.map { mode in
            let name = mode.name == "ultraperformance" ? "Ultra performance" : mode.name.capitalized
            return ("\(name) (window / \(mode.factor))", mode.name)
        }
        let presets = ["480p", "540p", "720p", "1080p", "1440p", "4k", "5k", "8k"]
        choices += RenderResolution.presets.filter { presets.contains($0.name) }.map { preset in
            let size = preset.resolution.size!
            return ("\(preset.name.uppercased().replacingOccurrences(of: "P", with: "p")) (\(size.width)x\(size.height))", preset.name)
        }
        if let current, !choices.contains(where: { $0.value == current }) { choices.append(("Custom (\(current))", current)) }
        return choices
    }

    /// The Upscaler menu.
    static let upscalerChoices: [(label: String, value: String?)] = [
        ("Default (Bilinear)", nil), ("Bilinear", "bilinear"), ("FSR 1", "fsr1"), ("MetalFX spatial (Metal)", "metalfx"),
        ("MetalFX temporal (Metal)", "metalfx-temporal"), ("TAAU", "taau"), ("FSR 3", "fsr3"),
    ]

    private func updatePhysics(_ change: (inout ProjectRuntimeSettings.Physics) -> Void) {
        updateProject { settings in
            var runtime = settings.runtime ?? ProjectRuntimeSettings()
            var physics = runtime.physics ?? .init()
            change(&physics)
            runtime.physics = physics.isEmpty ? nil : physics
            settings.runtime = runtime.isEmpty ? nil : runtime
        }
    }

    private func updateBuild(_ change: (inout GameBuildSettings) -> Void) {
        updateProject { settings in
            var build = settings.build ?? GameBuildSettings()
            change(&build)
            settings.build = build == GameBuildSettings() ? nil : build
        }
    }

    private func updateGame(_ change: (inout GameModuleSettings) -> Void) {
        updateProject { settings in
            var game = settings.game ?? GameModuleSettings()
            change(&game)
            settings.game = game == GameModuleSettings() ? nil : game
        }
    }

    // MARK: Fields

    private func section(_ title: String, note: String? = nil) {
        if !body.children.isEmpty { body.addChild(Spacer(grow: 0, minLength: 8)) }
        let heading = Label(title, role: .body, name: "settingsSection")
        heading.fontSize = 13
        body.addChild(heading)
        if let note {
            let caption = Label(note, role: .caption, name: "settingsSectionNote")
            caption.wraps = true
            body.addChild(caption)
        }
    }

    private func row(_ label: String, _ editor: Widget, tooltip: String? = nil) {
        let title = Label(label, role: .secondary, name: "settingsLabel")
        title.style.width = Self.labelWidth
        title.style.shrink = 1
        title.style.minWidth = 60
        title.tooltip = tooltip
        editor.style.grow = 1
        editor.style.shrink = 1
        editor.style.minWidth = 0
        if editor.tooltip == nil { editor.tooltip = tooltip }
        body.addChild(HStack(spacing: 8, name: "settingsRow", [title, editor]))
    }

    /// A row of buttons under the label column. A nil title is "Open in <code editor>" (+ `openSuffix`), kept current.
    private func buttons(_ specs: [(title: String?, name: String, command: CommandID, action: () -> Void)], openSuffix: String = "") {
        var widgets: [Widget] = []
        for spec in specs {
            let button = Button(spec.title ?? "", name: spec.name, action: spec.action)
            button.command = spec.command.rawValue
            if spec.title == nil {
                refreshers.append { [unowned self, unowned button] in
                    let title = ExternalLaunch.openTitle(session.editorSettings.codeEditor) + openSuffix
                    if button.title != title { button.title = title }
                }
            }
            widgets.append(button)
        }
        let row = HStack(spacing: 6, name: "settingsButtons", widgets + [Spacer()])
        self.row("", row)
    }

    private func number(_ label: String, name: String, command: CommandID, range: ClosedRange<Double>, step: Double,
                        isInteger: Bool = false, tooltip: String? = nil, get: @escaping () -> Double, set: @escaping (Double) -> Void) {
        let field = NumberField(value: get(), isInteger: isInteger, range: range, step: step, name: name)
        field.command = command.rawValue
        field.onEditEnded = { [unowned self] start, end in
            if end != start { set(end) }
            refresh()
        }
        refreshers.append { if !field.isInteracting, field.value != get() { field.setValue(get()) } }
        row(label, field, tooltip: tooltip)
    }

    private func vector(_ label: String, name: String, command: CommandID, count: Int, tooltip: String? = nil,
                        get: @escaping () -> [Double], set: @escaping ([Double]) -> Void) {
        let field = VectorField(count: count, values: get(), name: name)
        field.command = command.rawValue
        field.onEditEnded = { [unowned self] start, end in
            if end != start { set(end) }
            refresh()
        }
        refreshers.append { if !field.isInteracting, field.values != get() { field.setValues(get()) } }
        row(label, field, tooltip: tooltip)
    }

    private func text(_ label: String, name: String, command: CommandID, placeholder: String = "", tooltip: String? = nil,
                      get: @escaping () -> String, set: @escaping (String) -> Void) {
        let field = TextField(text: get(), placeholder: placeholder, name: name)
        field.command = command.rawValue
        let commit: (String) -> Void = { [unowned self] value in
            let value = value.trimmingCharacters(in: .whitespaces)
            if value != get() { set(value) }
            refresh()
        }
        field.onSubmit = commit
        field.onEndEditing = commit
        refreshers.append { if !field.isFocused, field.text != get() { field.text = get() } }
        row(label, field, tooltip: tooltip)
    }

    private func checkbox(_ label: String, name: String, command: CommandID, tooltip: String? = nil, get: @escaping () -> Bool,
                          set: @escaping (Bool) -> Void) {
        let box = Checkbox(label, isOn: get(), name: name)
        box.command = command.rawValue
        box.onChange = { [unowned self] on in
            set(on)
            refresh()
        }
        refreshers.append { if box.isOn != get() { box.isOn = get() } }
        row("", box, tooltip: tooltip)
    }

    private func dropdown(_ label: String, name: String, command: CommandID, options: [String], tooltip: String? = nil,
                          get: @escaping () -> Int, set: @escaping (Int) -> Void) {
        let menu = Dropdown(options: options, selectedIndex: get(), name: name)
        menu.command = command.rawValue
        menu.onChange = { [unowned self] index in
            set(index)
            refresh()
        }
        refreshers.append { if menu.selectedIndex != get() { menu.select(get()) } }
        row(label, menu, tooltip: tooltip)
    }

    // MARK: Widget

    public override func overlayFrame(in viewport: UIRect) -> UIRect { viewport }

    public override func layoutChildren() {
        let theme = theme
        card.padding = EdgeInsets(theme.dialogPadding)
        let width = min(640, max(frame.width - 32, 200))
        let height = min(620, max(frame.height - 32, 160))
        card.layout(in: UIRect(x: (frame.x + (frame.width - width) / 2).rounded(), y: (frame.y + (frame.height - height) / 2).rounded(),
                               width: width, height: height))
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown, .pointerUp, .pointerMove, .scroll:
            return true  // modal: nothing behind it reacts
        case .key(let e) where e.key == .escape:
            close()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        list.fillRect(frame, color: theme.modalDim)
        let radii = UICornerRadii(theme.dialogCornerRadius)
        list.fillRect(card.frame.inset(by: -6), color: theme.shadow.withAlpha(theme.shadow.a / 2), radii: UICornerRadii(theme.dialogCornerRadius + 6))
        list.fillRect(card.frame, color: theme.popupBackground, radii: radii)
        list.strokeRect(card.frame, color: theme.popupBorder, width: theme.borderWidth, radii: radii)
    }
}
