import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineUI
@testable import EngineAudio

// Builder tabs' side panels show in the Inspector while the builder is in front, so the
// builder's view gets the whole tab (EditorBuilderSidebars.swift); Open in Pop-Out floats a
// builder with its file, keeping its panel in the window.

@MainActor private func makeApp() -> EditorApp {
    let app = EditorApp(options: EditorOptions(deterministic: true))
    app.setupWithoutWindow(size: Vec2(1600, 1000), scale: 1)
    app.syncPanels()
    return app
}

@MainActor @Suite struct BuilderSidebarTests {
    @Test func everyBuilderTabHasASidePanel() {
        let app = makeApp()
        let missing = zip(EditorBuilderRegistry.modules, app.builderTabs).filter { $0.1.sidebar == nil }.map(\.0.title)
        // Builders whose whole tab is their editor have no side panel to move.
        #expect(missing.allSatisfy { ["Scripts"].contains($0) }, "no side panel found: \(missing)")
    }

    @Test func theFrontBuildersPanelMovesIntoTheInspectorAndBack() throws {
        let app = makeApp()
        let index = try #require(EditorBuilderRegistry.modules.firstIndex { $0.panelID == EditorLayout.meshBuilder })
        let sidebar = try #require(app.builderTabs[index].sidebar)
        let tabView = app.builderTabs[index].view
        let home = try #require(sidebar.parent)
        let width = sidebar.style.width

        app.showBuilderPanel(EditorLayout.meshBuilder)
        app.syncPanels()
        #expect(app.inspector.builderPanel === sidebar)
        #expect(sidebar.isDescendant(of: app.inspector.view))
        #expect(!sidebar.isDescendant(of: tabView))
        #expect(sidebar.style.width == nil)
        let title = try #require(app.inspector.view.descendant(named: "inspectorBuilderTitle") as? Label)
        #expect(title.text == "Mesh Builder")
        #expect(app.inspector.view.descendant(named: "addComponent")?.isHidden == true)
        // The tab's separator goes with it, so the view fills the tab.
        #expect(home.children.compactMap { $0 as? Separator }.allSatisfy { $0.isHidden })

        // Back to the Scene: the panel returns to its tab, the Inspector to the selection.
        app.dock.focusPanel(EditorLayout.viewport)
        app.syncPanels()
        #expect(app.inspector.builderPanel == nil)
        #expect(sidebar.parent === home && home.children.last === sidebar)
        #expect(sidebar.style.width == width)
        #expect(home.children.compactMap { $0 as? Separator }.allSatisfy { !$0.isHidden })
        #expect(app.inspector.view.descendant(named: "inspectorBuilderHost")?.isHidden == true)

        // Without an Inspector the panel stays in its tab.
        app.dock.closePanel(EditorLayout.inspector)
        app.showBuilderPanel(EditorLayout.meshBuilder)
        app.syncPanels()
        #expect(app.inspector.builderPanel == nil && sidebar.parent === home)
    }

    @Test func switchingBuildersSwapsThePanelAndTheLayoutStaysClean() throws {
        let app = makeApp()
        let modules = EditorBuilderRegistry.modules
        let mesh = try #require(modules.firstIndex { $0.panelID == EditorLayout.meshBuilder })
        let terrain = try #require(modules.firstIndex { $0.panelID == EditorLayout.terrainBuilder })
        app.showBuilderPanel(EditorLayout.meshBuilder)
        app.syncPanels()
        app.showBuilderPanel(EditorLayout.terrainBuilder)
        app.syncPanels()
        #expect(app.inspector.builderPanel === app.builderTabs[terrain].sidebar)
        #expect(app.builderTabs[mesh].sidebar?.isDescendant(of: app.builderTabs[mesh].view) == true)

        // Pressing in the Inspector (its group becomes the dock's active one) keeps the panel there.
        app.dock.focusPanel(EditorLayout.inspector)
        app.syncPanels()
        #expect(app.inspector.builderPanel === app.builderTabs[terrain].sidebar)

        app.ui.layoutIfNeeded()
        let issues = app.ui.layoutAudit()
        #expect(issues.isEmpty, "\(issues.prefix(8).map { "\($0)" }.joined(separator: "\n"))")
    }

    @Test func everyBuildersPanelFitsTheInspector() {
        let app = makeApp()
        var report: [String] = []
        for (module, tab) in zip(EditorBuilderRegistry.modules, app.builderTabs) where tab.sidebar != nil {
            app.showBuilderPanel(module.panelID)
            app.syncPanels()
            guard app.inspector.builderPanel === tab.sidebar else {
                report.append("\(module.title): not shown in the Inspector")
                continue
            }
            app.ui.layoutIfNeeded()
            let issues = app.ui.layoutAudit()
            report += issues.prefix(4).map { "\(module.title): \($0)" }
        }
        #expect(report.isEmpty, "\(report.count) issue(s):\n\(report.joined(separator: "\n"))")
    }

    @Test func openInPopOutFloatsTheBuilderWithItsOwnPanel() throws {
        let app = makeApp()
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("BuilderSidebarTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(session.newProject(path: folder.path))
        session.assets?.waitForAll()
        let modules = EditorBuilderRegistry.modules
        let dialogue = try #require(modules.firstIndex { $0.panelID == EditorLayout.dialogueBuilder })
        let mesh = try #require(modules.firstIndex { $0.panelID == EditorLayout.meshBuilder })
        let tree = try #require(modules[dialogue].asset?.create(session, ""))
        let second = try #require(modules[dialogue].asset?.create(session, ""))
        app.syncPanels()
        #expect(EditorBuilderRegistry.module(forFile: tree, in: session)?.panelID == EditorLayout.dialogueBuilder)

        let result = try #require(session.run(AssetOpenPopOutCommand.self, .init(asset: AssetReference(tree))))
        #expect(result.panel == EditorLayout.dialogueBuilder)
        #expect(app.isFloating(EditorLayout.dialogueBuilder))
        let window = try #require(app.dock.layout.floating.first { $0.panels.contains(EditorLayout.dialogueBuilder) })
        #expect(window.frame.width >= 560 && window.frame.height >= 400)
        // The pop-out keeps its own side panel; the Inspector keeps the selection.
        let dialogueSidebar = try #require(app.builderTabs[dialogue].sidebar)
        #expect(dialogueSidebar.isDescendant(of: app.builderTabs[dialogue].view))
        #expect(app.inspector.builderPanel == nil)

        // Working in the Scene or a docked builder leaves it floating; the docked one uses the Inspector.
        app.showBuilderPanel(EditorLayout.meshBuilder)
        app.syncPanels()
        #expect(app.isFloating(EditorLayout.dialogueBuilder) && app.dock.isOpen(EditorLayout.dialogueBuilder))
        #expect(app.inspector.builderPanel === app.builderTabs[mesh].sidebar)
        app.dock.focusPanel(EditorLayout.viewport)
        app.syncPanels()
        #expect(app.isFloating(EditorLayout.dialogueBuilder))

        // Opening another dialogue shows it in the same window instead of docking it again.
        modules[dialogue].asset?.open(session, second)
        app.syncPanels()
        #expect(app.isFloating(EditorLayout.dialogueBuilder))
        #expect(app.dock.layout.floating.filter { $0.panels.contains(EditorLayout.dialogueBuilder) }.count == 1)

        // panel.popOut floats an open builder; a second pop-out cascades.
        session.run(PanelPopOutCommand.self, .init(panel: EditorLayout.meshBuilder))
        #expect(app.isFloating(EditorLayout.meshBuilder) && app.inspector.builderPanel == nil)
        let frames = app.dock.layout.floating.map(\.frame)
        #expect(Set(frames.map(\.x)).count == frames.count)
        app.ui.layoutIfNeeded()
        let issues = app.ui.layoutAudit()
        #expect(issues.isEmpty, "\(issues.prefix(8).map { "\($0)" }.joined(separator: "\n"))")
    }

    @Test func popOutIsOfferedForBuilderFilesOnly() throws {
        let app = makeApp()
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("BuilderSidebarTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(session.newProject(path: folder.path))
        session.assets?.waitForAll()
        let timeline = try #require(EditorBuilderRegistry.modules.first { $0.panelID == EditorLayout.timeline }?.asset?.create(session, ""))
        // A plain audio file: no builder opens it.
        try WAVWriter.encode([Float](repeating: 0, count: 480), channelCount: 1, sampleRate: 48000)
            .write(to: folder.appendingPathComponent("Assets/click.wav"))
        _ = session.assets?.refresh()
        let material = try #require(session.assets?.id(forPath: "click.wav"))
        let inspector = AssetInspectorView(session: session)
        inspector.show(.asset(timeline))
        #expect(inspector.view.descendant(named: "assetOpenPopOut") != nil)
        inspector.show(.asset(material))
        #expect(inspector.view.descendant(named: "assetOpenPopOut") == nil)
        #expect(throws: (any Error).self) { try session.commands.run(AssetOpenPopOutCommand.id, json: Data("{\"asset\":\"\(AssetReference(material))\"}".utf8)) }
    }
}

// Pop-outs in OS windows of their own (EditorPopOutWindows.swift), with headless windows
// standing in for the engine's.
@MainActor @Suite struct PopOutWindowTests {
    private func makeWindowedApp() -> (EditorApp, () -> [EngineWindow]) {
        let app = makeApp()
        var opened: [EngineWindow] = []
        app.windowOpener = { title, size in
            let window = EngineWindow(headlessSize: size, scale: 2, title: title)
            opened.append(window)
            return window
        }
        return (app, { opened })
    }

    @Test func aPoppedOutBuilderGetsAWindowOfItsOwn() throws {
        let (app, windows) = makeWindowedApp()
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PopOutWindowTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(session.newProject(path: folder.path))
        session.assets?.waitForAll()
        let modules = EditorBuilderRegistry.modules
        let dialogue = try #require(modules.firstIndex { $0.panelID == EditorLayout.dialogueBuilder })
        let tree = try #require(modules[dialogue].asset?.create(session, ""))
        let second = try #require(modules[dialogue].asset?.create(session, ""))
        app.syncPanels()

        let result = try #require(session.run(AssetOpenPopOutCommand.self, .init(asset: AssetReference(tree))))
        #expect(result.panel == EditorLayout.dialogueBuilder)
        let window = try #require(windows().first)
        #expect(windows().count == 1 && window.title == "Dialogue")
        #expect(window.size.x >= 560 && window.size.y >= 400)
        // Out of the dock, into the window's own UI, with its side panel.
        #expect(app.isPoppedOut(EditorLayout.dialogueBuilder))
        #expect(!app.dock.isOpen(EditorLayout.dialogueBuilder) && !app.isFloating(EditorLayout.dialogueBuilder))
        let popOut = try #require(app.popOuts.first)
        let content = app.builderTabs[dialogue].view
        #expect(content.isDescendant(of: popOut.ui.root) && !content.isDescendant(of: app.dock))
        #expect(app.builderTabs[dialogue].sidebar?.isDescendant(of: content) == true)
        #expect(app.inspector.builderPanel == nil)

        // A frame lays it out at the window's size and paints it into the window.
        app.updateWithoutWindow(dt: 1.0 / 60)
        #expect(abs(content.frame.width - window.size.x / popOut.ui.uiScale) < 1)
        #expect(!window.ui.batches.isEmpty)
        let center = Vec2(content.frame.x + content.frame.width / 2, content.frame.y + content.frame.height / 2)
        #expect(popOut.ui.hitTest(center)?.isDescendant(of: content) == true)
        popOut.ui.layoutIfNeeded()
        let issues = popOut.ui.layoutAudit()
        #expect(issues.isEmpty, "\(issues.prefix(8).map { "\($0)" }.joined(separator: "\n"))")

        // Opening another dialogue, or showing the panel, keeps it in its window; Reset Layout too.
        modules[dialogue].asset?.open(session, second)
        session.run(PanelOpenCommand.self, .init(panel: EditorLayout.dialogueBuilder))
        app.resetLayout()
        app.updateWithoutWindow(dt: 1.0 / 60)
        #expect(windows().count == 1 && app.isPoppedOut(EditorLayout.dialogueBuilder))
        #expect(!app.dock.isOpen(EditorLayout.dialogueBuilder) && content.isDescendant(of: popOut.ui.root))
        let listed = try #require(session.run(PanelListCommand.self, .init())?.panels.first { $0.id == EditorLayout.dialogueBuilder })
        #expect(listed.open && listed.window == true)

        // Its close button docks it back where the Scene view is.
        window.requestClose()
        app.updateWithoutWindow(dt: 1.0 / 60)
        #expect(window.isClosed && app.popOuts.isEmpty)
        #expect(app.dock.isOpen(EditorLayout.dialogueBuilder) && content.isDescendant(of: app.dock))
        #expect(EditorLayout.shareGroup(in: app.dock.layout, EditorLayout.dialogueBuilder, EditorLayout.viewport))
    }

    @Test func otherPanelsPopOutAndTheSceneViewFloats() throws {
        let (app, windows) = makeWindowedApp()
        let session = app.session
        session.run(PanelPopOutCommand.self, .init(panel: EditorLayout.console))
        #expect(app.isPoppedOut(EditorLayout.console) && windows().count == 1)
        app.updateWithoutWindow(dt: 1.0 / 60)
        #expect(!(windows().first?.ui.batches.isEmpty ?? true))

        // panel.close closes the window and the panel; panel.open docks it again.
        session.run(PanelCloseCommand.self, .init(panel: EditorLayout.console))
        #expect(windows().first?.isClosed == true && !app.isPoppedOut(EditorLayout.console) && !app.dock.isOpen(EditorLayout.console))
        session.run(PanelOpenCommand.self, .init(panel: EditorLayout.console))
        #expect(app.dock.isOpen(EditorLayout.console))

        // panel.dock takes a popped-out panel back into the dock.
        session.run(PanelPopOutCommand.self, .init(panel: EditorLayout.hierarchy))
        #expect(app.isPoppedOut(EditorLayout.hierarchy))
        session.run(PanelDockCommand.self, .init(panel: EditorLayout.hierarchy, edge: .left))
        #expect(!app.isPoppedOut(EditorLayout.hierarchy) && app.dock.isOpen(EditorLayout.hierarchy))

        // The Scene view draws from the main window's input: it floats over the editor.
        session.run(PanelPopOutCommand.self, .init(panel: EditorLayout.viewport))
        #expect(!app.isPoppedOut(EditorLayout.viewport) && app.isFloating(EditorLayout.viewport))
        #expect(windows().count == 2)
    }

    @Test func withoutWindowsPopOutsFloat() {
        let app = makeApp()
        app.windowOpener = { _, _ in nil }
        app.session.run(PanelPopOutCommand.self, .init(panel: EditorLayout.console))
        #expect(!app.isPoppedOut(EditorLayout.console) && app.isFloating(EditorLayout.console))
    }
}
