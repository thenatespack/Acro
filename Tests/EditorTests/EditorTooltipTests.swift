import Testing
@testable import EditorCore
@testable import Engine

// MARK: Helpers

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// A panel's view laid out filling a 600x500 window.
@MainActor private func host(_ view: Widget) -> UIContext {
    let ui = UIContext()
    ui.setViewport(size: Vec2(600, 500), scale: 1)
    view.style.position = .absolute(.fill())
    ui.root.addChild(view)
    ui.layoutIfNeeded()
    return ui
}

@MainActor private func tooltip(_ root: Widget, _ name: String) -> String? {
    root.descendant(named: name)?.tooltip
}

// MARK: Shortcut text

@Test func shortcutTextFollowsThePlatformModifier() {
    let mac = EditorShortcuts(shortcutModifier: .command), other = EditorShortcuts(shortcutModifier: .control)
    #expect(mac.shortcutText(for: .undo) == "⌘Z" && other.shortcutText(for: .undo) == "Ctrl+Z")
    #expect(mac.shortcutText(for: .redo) == "⇧⌘Z" && other.shortcutText(for: .redo) == "Ctrl+Shift+Z")
    #expect(mac.shortcutText(for: .save) == "⌘S" && other.shortcutText(for: .save) == "Ctrl+S")
    #expect(mac.shortcutText(for: .togglePlay) == "⌘P" && other.shortcutText(for: .togglePlay) == "Ctrl+P")
    #expect(mac.shortcutText(for: .delete) == "Delete" && mac.shortcutText(for: .focusSelection) == "F")
    #expect(mac.tooltip("Undo Rename", for: .undo) == "Undo Rename (⌘Z)")
    #expect(other.tooltip("Undo Rename", for: .undo) == "Undo Rename (Ctrl+Z)")
}

@Test func shownBindingsAreTheRealBindings() {
    let all: [CommandID] = [.undo, .redo, .save, .duplicate, .delete, .focusSelection, .clearSelection, .togglePlay, .importAsset,
                            .togglePause, .step]
    #expect(EditorShortcuts.boundCommands == all)
    for shortcuts in [EditorShortcuts(shortcutModifier: .command), EditorShortcuts(shortcutModifier: .control)] {
        for action in all { #expect(shortcuts.action(for: shortcuts.binding(for: action)!) == action) }
    }
}

// MARK: Toolbar

@MainActor @Suite struct EditorTooltipTests {
    @Test func toolbarButtonsShowTheirShortcuts() {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        let toolbar = Toolbar(app: app)
        let shortcuts = app.shortcuts
        #expect(tooltip(toolbar.view, "save") == "Save the scene (\(shortcuts.shortcutText(for: .save)))")
        #expect(tooltip(toolbar.view, "play") == "Play the scene (\(shortcuts.shortcutText(for: .togglePlay)))")
        #expect(tooltip(toolbar.view, "undo") == "Undo (\(shortcuts.shortcutText(for: .undo)))")
        #expect(tooltip(toolbar.view, "redo") == "Redo (\(shortcuts.shortcutText(for: .redo)))")
        #expect(tooltip(toolbar.view, "scenePath") != nil && tooltip(toolbar.view, "resetLayout") != nil)
        #expect(tooltip(toolbar.view, "move") == "Move tool" && tooltip(toolbar.view, "rotate") == "Rotate tool")
        #expect(tooltip(toolbar.view, "scale") == "Scale tool")
        #expect(tooltip(toolbar.view, "new") != nil && tooltip(toolbar.view, "open") != nil && tooltip(toolbar.view, "saveAs") != nil)
    }

    @Test func undoAndPlayTooltipsTrackTheSession() {
        let app = EditorApp(options: EditorOptions(deterministic: true))
        let toolbar = Toolbar(app: app)
        let session = app.session
        session.newDocument()
        let id = session.world.id(of: session.world.roots[0])!
        session.rename(id, to: "Renamed")
        toolbar.refresh()
        let undoKeys = app.shortcuts.shortcutText(for: .undo)
        #expect(tooltip(toolbar.view, "undo") == "Undo Rename (\(undoKeys))")
        session.performUndo()
        toolbar.refresh()
        #expect(tooltip(toolbar.view, "redo") == "Redo Rename (\(app.shortcuts.shortcutText(for: .redo)))")
        session.togglePlay()
        toolbar.refresh()
        #expect(tooltip(toolbar.view, "play") == "Stop and restore the scene (\(app.shortcuts.shortcutText(for: .togglePlay)))")
    }

    @Test func hierarchyAndConsoleButtonsHaveTooltips() {
        let session = makeSession()
        let hierarchy = HierarchyPanel(session: session)
        let shortcuts = EditorShortcuts()
        #expect(tooltip(hierarchy.view, "create") != nil)
        #expect(tooltip(hierarchy.view, "duplicate") == "Duplicate the selection (\(shortcuts.shortcutText(for: .duplicate)))")
        #expect(tooltip(hierarchy.view, "delete") == "Delete the selection (\(shortcuts.shortcutText(for: .delete)))")
        let console = ConsolePanel(log: session.log)
        #expect(tooltip(console.view, "consoleClear") == "Clear the console")
        #expect(tooltip(console.view, "consoleFilter") != nil)
    }

    @Test func inspectorShowsTheFullIDAndRemoveButtonTooltips() {
        let session = makeSession()
        let inspector = InspectorPanel(session: session)
        let ui = host(inspector.view)
        let entity = session.world.roots[0]
        let id = session.world.id(of: entity)!
        session.selection.select(id)
        inspector.refresh()
        ui.layoutIfNeeded()
        #expect(tooltip(inspector.view, "entityID") == "Entity ID \(id.description)")
        #expect(tooltip(inspector.view, "addComponent") != nil)
        let header = inspector.view.descendant(named: "header.Transform")!
        let remove = Vec2(header.frame.maxX - 13, header.frame.center.y)
        #expect(header.tooltip(at: remove) == "Remove Transform")
        // Elsewhere on the header there is nothing to say while the title fits.
        #expect(header.tooltip(at: Vec2(header.frame.x + 60, header.frame.center.y)) == nil)
    }

    @Test func dockTabCloseButtonsNameTheirPanel() {
        let session = makeSession()
        let panel = DockPanel(id: "console", title: "Console", content: ConsolePanel(log: session.log).view)
        let tabs = TabView(tabs: [panel, DockPanel(id: "stats", title: "Stats", content: StatsPanel().view)])
        let ui = host(tabs)
        ui.layoutIfNeeded()
        #expect(tabs.tooltip(at: tabs.closeButtonRect(0)!.center) == "Close Console")
    }
}
