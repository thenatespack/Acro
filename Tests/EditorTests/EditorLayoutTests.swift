import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// The editor's layout at small and large windows, backing scales, UI zooms and every theme, in
// busy states (long names, many entities, long console lines, a long undo title, every component,
// menus, the delete dialog, play mode, floating and squeezed panels): `UIContext.layoutAudit`
// must find no interactive widget outside the window or its parent, cut off, overlapping another,
// too small to hit, a button title cut off without a tooltip, or text too small to read. And the
// themes' text colors must reach WCAG AA contrast. See docs/EditorUIReview.md; the windowed twin
// is Evals/ui-audit.py.

/// The editor laid out without a window at `size` points, backing `scale`, with options.
@MainActor private func layoutApp(_ size: Vec2, scale: Float = 1, uiScale: Float? = nil, theme: String? = nil) -> EditorApp {
    var options = EditorOptions(deterministic: true)
    options.uiScale = uiScale
    options.theme = theme
    let app = EditorApp(options: options)
    app.setupWithoutWindow(size: size, scale: scale)
    return app
}

/// Drives `app`'s session as an MCP client does.
@MainActor private struct LayoutClient {
    let app: EditorApp
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init(_ app: EditorApp) {
        self.app = app
        mcp = EditorMCP(session: app.session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        connection.send(["jsonrpc": "2.0", "id": "init", "method": "initialize",
                         "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "layout-test"]]])
        mcp.pump()
        _ = connection.output.take()
    }

    @discardableResult
    func call(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": "tools/call", "params": ["name": .string(name), "arguments": arguments]])
        mcp.pump()
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        let result = reply["result"] ?? nil
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? reply)",
                sourceLocation: sourceLocation)
        app.syncPanels()
        return result["structuredContent"] ?? nil
    }
}

/// The audit's findings, one per line, for a readable failure.
@MainActor private func expectClean(_ app: EditorApp, _ context: String, sourceLocation: SourceLocation = #_sourceLocation) {
    app.syncPanels()
    let issues = app.ui.layoutAudit()
    let listing = issues.prefix(12).map { "  \($0)" }.joined(separator: "\n")
    #expect(issues.isEmpty, "\(context): \(issues.count) layout issue(s)\n\(listing)", sourceLocation: sourceLocation)
}

private let longName = String(repeating: "A Very Long Entity Name That Keeps Going ", count: 4)

/// Puts the editor through the busy states, checking the layout after each.
@MainActor private func checkBusyStates(_ app: EditorApp, _ context: String) {
    let client = LayoutClient(app)
    expectClean(app, "\(context) default")
    client.call("selection.clear")
    expectClean(app, "\(context) no selection")

    let entity = client.call("entity.create", ["template": "cube", "name": .string(longName)])["entity"] ?? nil
    client.call("component.setField", ["entity": entity, "path": "Transform.position", "value": [1, 2, 3],
                                       "label": .string("Set Transform.position on " + longName)])
    app.session.log.error("Couldn't open " + String(repeating: "/a/very/long/folder/name", count: 20) + "/scene.json")
    client.call("panel.focus", ["panel": "console"])
    expectClean(app, "\(context) long names, undo title and console line")

    let calls = (0..<200).map { i -> JSON in ["command": "entity.create", "arguments": ["template": "empty", "name": .string("Entity \(i)")]] }
    client.call("edit.batch", ["calls": .array(calls), "label": "Create 200"])
    for panel in ["activity", "stats", "assets"] {
        client.call("panel.focus", ["panel": .string(panel)])
        expectClean(app, "\(context) many entities, \(panel)")
    }

    let holder = client.call("entity.create", ["template": "empty", "name": "Holder"])["entity"] ?? nil
    let types = client.call("component.types")["components"]?.arrayValue ?? []
    for type in types where type["addable"] == true {
        client.call("component.add", ["entity": holder, "component": type["name"] ?? nil])
    }
    client.call("selection.set", ["entities": [holder], "primary": holder])
    expectClean(app, "\(context) every component")

    client.call("selection.set", ["entities": [entity], "primary": entity])
    client.call("ui.click", ["label": "Add Component", "role": "button"])
    expectClean(app, "\(context) Add Component menu")
    client.call("ui.key", ["keys": ["escape"]])
    client.call("ui.click", ["label": "Create", "role": "button"])
    expectClean(app, "\(context) Create menu")
    client.call("ui.key", ["keys": ["escape"]])
    app.confirmDeleteSelection()
    expectClean(app, "\(context) delete dialog")
    client.call("ui.key", ["keys": ["escape"]])

    client.call("play.start")
    expectClean(app, "\(context) playing")
    client.call("play.stop")

    // A floating inspector showing a tall component list used to stretch the dock past the window.
    client.call("selection.set", ["entities": [holder], "primary": holder])
    client.call("panel.dock", ["panel": "inspector", "floating": [120, 90, 300, 320]])
    expectClean(app, "\(context) floating inspector")
    client.call("layout.reset")
    client.call("panel.dock", ["panel": "hierarchy", "edge": "left", "fraction": 0.05])
    client.call("panel.dock", ["panel": "inspector", "edge": "right", "fraction": 0.05])
    expectClean(app, "\(context) narrow panels")
}

@MainActor @Suite struct EditorLayoutTests {
    static let sizes: [Vec2] = [Vec2(800, 600), Vec2(1280, 720), Vec2(2560, 1440), Vec2(2560, 600), Vec2(800, 1400)]

    @Test func defaultLayoutFitsEverySizeScaleAndZoom() {
        for size in Self.sizes {
            for scale: Float in [1, 2] {
                for zoom in [EditorApp.uiScaleRange.lowerBound, 1, EditorApp.uiScaleRange.upperBound] {
                    let app = layoutApp(size, scale: scale, uiScale: zoom)
                    expectClean(app, "\(Int(size.x))x\(Int(size.y)) @\(scale)x zoom \(zoom)")
                }
            }
        }
    }

    @Test func busyStatesFitSmallAndLargeWindows() {
        checkBusyStates(layoutApp(Vec2(800, 600)), "800x600")
        checkBusyStates(layoutApp(Vec2(800, 600), scale: 2, uiScale: EditorApp.uiScaleRange.upperBound), "800x600 @2x zoomed")
        checkBusyStates(layoutApp(Vec2(2560, 1440), uiScale: EditorApp.uiScaleRange.lowerBound), "2560x1440 smallest zoom")
        checkBusyStates(layoutApp(Vec2(2560, 600)), "2560x600")
        checkBusyStates(layoutApp(Vec2(800, 1400)), "800x1400")
    }

    @Test func everyThemeLaysOut() throws {
        for theme in EditorApp.themes.compactMap(UITheme.named) {
            let app = layoutApp(Vec2(1280, 720), theme: theme.name)
            #expect(app.ui.theme.name == theme.name)
            // The dividers between panels are the theme's (they were the dark theme's in every
            // theme): the splits take the theme's color when they draw, with no editor workaround.
            let split = try #require(app.dock.descendant(named: "dockSplit") as? SplitView)
            #expect(split.dividerColor == nil && split.dividerUsesThemeColor && app.dock.gapColor == nil)
            checkBusyStates(app, theme.name)
            expectClean(layoutApp(Vec2(800, 600), theme: theme.name), "\(theme.name) 800x600")
        }
    }

    @Test func auditCatchesBrokenLayouts() throws {
        // A toolbar that can't move anything into its More menu: its right end runs off a 700-point window.
        let app = layoutApp(Vec2(700, 600))
        app.toolbar.view.overflowOrder = []
        app.ui.layoutIfNeeded()
        let kinds = Set(app.ui.layoutAudit().map(\.kind))
        #expect(kinds.contains(.outsideWindow))

        let ui = UIContext()
        ui.setViewport(size: Vec2(300, 200), scale: 1)
        let tiny = Button("x")
        tiny.style.width = 8
        tiny.style.height = 8
        let a = Button("Overlapping A"), b = Button("Overlapping B")
        a.style.position = .absolute(Anchors(left: 10, top: 100))
        b.style.position = .absolute(Anchors(left: 30, top: 105))
        let squeezed = Button("A title much too long for its width")
        squeezed.style.width = 60
        let small = Label("Tiny text")
        small.fontSize = 7
        let panel = TabView(tabs: [DockPanel(id: "p", title: "Panel", content: HStack(spacing: 4, [Button("One"), Button("Two"), Button("Three")]))])
        panel.style.width = 90
        panel.style.height = 60
        ui.root.addChild(VStack(spacing: 4, alignment: .start, [tiny, squeezed, small, panel, a, b]))
        let issues = ui.layoutAudit()
        let found = Set(issues.map(\.kind))
        #expect(found.isSuperset(of: [.tooSmall, .overlap, .smallText, .outsideParent]), "\(issues)")
        // A cut-off title is fine with its tooltip (the full title), not without one.
        #expect(!found.contains(.truncatedWithoutTooltip))
        #expect(squeezed.titleIsTruncated && squeezed.tooltip(at: squeezed.frame.center) == squeezed.title)
    }

    @Test func zoomGivesWayInSmallWindows() {
        #expect(EditorApp.fittedUIScale(2, window: Vec2(2560, 1440)) == 2)
        #expect(EditorApp.fittedUIScale(2, window: Vec2(1280, 720)) == 1.44)
        #expect(EditorApp.fittedUIScale(2, window: Vec2(800, 600)) == 1)
        #expect(EditorApp.fittedUIScale(0.85, window: Vec2(800, 600)) == 0.85)
        let app = layoutApp(Vec2(1280, 720), uiScale: 2)
        #expect(app.preferredUIScale == 2 && app.ui.uiScale == 1.44)
        app.resizeWithoutWindow(size: Vec2(2560, 1440))
        #expect(app.ui.uiScale == 2)
        // Out-of-range settings are clamped.
        #expect(layoutApp(Vec2(1280, 720), uiScale: 0.3).preferredUIScale == EditorApp.uiScaleRange.lowerBound)
    }

    @Test func longUndoTitleIsTheLabelAndTooltipOfTheIconButton() throws {
        let app = layoutApp(Vec2(1280, 720))
        let client = LayoutClient(app)
        let entity = client.call("entity.create", ["template": "cube"])["entity"] ?? nil
        client.call("component.setField", ["entity": entity, "path": "Transform.position.x", "value": 2,
                                           "label": .string("Move " + longName)])
        app.syncPanels()
        let undo = try #require(app.ui.root.descendant(named: "undo") as? Button)
        // The toolbar's buttons are icon-only (#659): the whole title is the label and the tooltip.
        #expect(undo.title.hasPrefix("Undo AI: Move") && !undo.showsTitle && !undo.titleIsTruncated)
        #expect(undo.frame.width <= 40)
        #expect(undo.tooltip(at: undo.frame.center)?.contains(longName) == true)
        #expect(app.ui.accessibilityElement(path: "editorRoot/toolbar/undo")?.label == undo.title)
        // Everything after it in the toolbar is still in the window.
        expectClean(app, "long undo title")
    }

    // MARK: Re-review after icons and the #661 follow-ups

    /// The window can't go below `EditorApp.minimumWindowSize` (#23), and at that size the
    /// default layout has no findings and the toolbar stays one row.
    @Test func minimumWindowSizeIsHonoured() {
        var config = EngineConfig(width: 640, height: 400)
        #expect(config.openingWindowSize == (640, 400))
        config.minimumWindowSize = (Int(EditorApp.minimumWindowSize.x), Int(EditorApp.minimumWindowSize.y))
        #expect(config.openingWindowSize == (800, 500))
        config.width = 1440
        #expect(config.openingWindowSize == (1440, 500))
        for scale: Float in [1, 2] {
            let app = layoutApp(EditorApp.minimumWindowSize, scale: scale)
            expectClean(app, "minimum window @\(scale)x")
            let toolbar = app.toolbar.view
            #expect(toolbar.frame.height <= app.ui.theme.controlHeight + toolbar.padding.vertical + 0.5)
        }
    }

    /// Tab close buttons, tree disclosure triangles and checkboxes take clicks over at least
    /// 24x24 points (WCAG 2.2 target size, #24), whatever their glyph's size.
    @Test func smallControlsHaveTwentyFourPointHitTargets() throws {
        for theme in ["Dark", "High Contrast"] {
            let app = layoutApp(Vec2(1280, 720), theme: theme)
            let client = LayoutClient(app)
            let holder = client.call("entity.create", ["template": "cube", "name": "Holder"])["entity"] ?? nil
            client.call("selection.set", ["entities": [holder], "primary": holder])
            let elements = app.ui.accessibilityElements().filter(\.isOnScreen)
            let closes = elements.filter { $0.path.split(separator: "/").last?.hasPrefix("close:") == true }
            let toggles = elements.filter { $0.path.split(separator: "/").last?.hasPrefix("toggle:") == true }
            let checkboxes = elements.filter { $0.role == .checkbox }
            #expect(!closes.isEmpty && !toggles.isEmpty && !checkboxes.isEmpty)
            for element in closes + toggles + checkboxes {
                #expect(element.frame.width >= 24 && element.frame.height >= 24,
                        "\(theme): \(element.path) is \(element.frame.width)x\(element.frame.height)")
            }
            // A click at the edge of the larger area still hits: collapse "Props" by its toggle's corner.
            let toggle = try #require(toggles.first { $0.path.hasSuffix("toggle:Props") })
            app.ui.synthesizeClick(at: Vec2(toggle.frame.x + 1, toggle.frame.y + 1))
            app.syncPanels()
            #expect(app.ui.accessibilityElements().first { $0.path.hasSuffix("toggle:Props") }?.value == "collapsed")
        }
    }

    /// Floating windows stay wholly in the dock (#32): one placed for a bigger window, or
    /// taller than the dock, is pulled in and shrunk, and its stored frame is kept.
    @Test func floatingWindowsStayOnScreen() throws {
        let app = layoutApp(Vec2(800, 600))
        let client = LayoutClient(app)
        client.call("panel.dock", ["panel": "inspector", "floating": [600, 450, 320, 900]])
        let dock = app.dock
        let window = try #require(dock.children.first { $0.name == "dockFloating" })
        let inside = dock.contentRect
        #expect(window.frame.x >= inside.x && window.frame.y >= inside.y)
        #expect(window.frame.maxX <= inside.maxX + 0.5 && window.frame.maxY <= inside.maxY + 0.5, "\(window.frame) in \(inside)")
        expectClean(app, "floating inspector placed off screen")
        #expect(dock.layout.floating.first?.frame == UIRect(x: 600, y: 450, width: 320, height: 900))
    }

    /// The View menu switches the theme and the zoom of the running editor (#29): everything
    /// built in the old theme follows, and the choice is saved in the prefs.
    @Test func viewMenuSwitchesThemeAndZoom() throws {
        let app = layoutApp(Vec2(1280, 720))
        let client = LayoutClient(app)
        let opened = client.call("ui.click", ["label": "View", "role": "button"])["opened"]?.arrayValue ?? []
        let items = opened.filter { $0["role"] == "menuItem" }.compactMap { $0["label"]?.stringValue }
        #expect(items.first == "Reset Layout")
        #expect(items.contains("Light Theme") && items.contains("Zoom 125%"))
        #expect(!items.contains("Game Theme"))  // a game HUD preset, not offered for the editor
        client.call("ui.click", ["label": "Light Theme", "role": "menuItem"])
        let light = UITheme.light()
        #expect(app.ui.theme.name == "Light" && app.prefs.theme == "Light")
        #expect(app.toolbar.view.background == light.panelBackground && app.dock.background == light.fieldBackground)
        expectClean(app, "switched to Light")

        let result = client.call("view.appearance", ["uiScale": 1.25])
        #expect(result["theme"] == "Light" && result["uiScale"] == 1.25 && result["effectiveUIScale"] == 1.25)
        #expect(app.ui.uiScale == 1.25 && app.prefs.uiScale == 1.25)
        expectClean(app, "Light at 125%")
        // The menu checks what is chosen.
        client.call("ui.click", ["label": "View", "role": "button"])
        let menu = try #require(app.ui.overlays.compactMap { $0 as? PopupMenu }.last)
        #expect(menu.checkedIndices == [2, 1 + EditorApp.menuThemes.count + 2])
        client.call("ui.key", ["keys": ["escape"]])
        // The engine's Game preset is for game UI: refused, with the editor's themes named.
        #expect(throws: CommandError.self) { try app.session.commands.run(ViewAppearanceCommand.self, .init(theme: "game")) }
        do {
            _ = try app.session.commands.run(ViewAppearanceCommand.self, .init(theme: "Game"))
        } catch {
            #expect("\(error)".contains("Dark, Light, High Contrast"), "\(error)")
        }
        #expect(app.ui.theme.name == "Light" && app.prefs.theme == "Light")
    }

    /// Prefs or `EDITOR_THEME` saying Game (allowed before) start the editor in Dark, with one warning.
    @Test func gameThemeFallsBackToDark() {
        let app = layoutApp(Vec2(1280, 720), theme: "game")
        #expect(app.ui.theme.name == "Dark")
        let warnings = app.session.log.entries.filter { $0.level == .warning && $0.message.contains("Game") }
        #expect(warnings.count == 1, "\(warnings.map(\.message))")
        app.syncPanels()
        #expect(app.session.log.entries.filter { $0.level == .warning && $0.message.contains("Game") }.count == 1)
        #expect(throws: CommandError.self) { try EditorApp.editorTheme(named: "Game") }
        #expect((try? EditorApp.editorTheme(named: "high contrast"))?.name == "High Contrast")
    }

    /// One toolbar row at 800 points with a project open (#661 follow-up): what doesn't fit goes
    /// into the More menu, Build Game stays, the overflowed buttons keep their labels in
    /// ui.snapshot, and ui.click on one opens the menu and clicks its entry.
    @Test func toolbarOverflowsIntoAMoreMenu() throws {
        let app = layoutApp(Vec2(800, 600), uiScale: 1)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("EditorLayoutTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        try #require(app.session.run(ProjectNewCommand.self, .init(path: folder.path)) != nil)
        app.syncPanels()
        let toolbar = app.toolbar.view
        let rowHeight = app.ui.theme.controlHeight + toolbar.padding.vertical
        #expect(toolbar.frame.height <= rowHeight + 0.5)
        let build = try #require(toolbar.descendant(named: "buildGame") as? Button)
        #expect(!build.isHidden && build.frame.maxX <= 800)
        #expect(!toolbar.overflowed.isEmpty && !toolbar.moreButton.isHidden)
        expectClean(app, "800x600 with a project")
        let elements = app.ui.accessibilityElements()
        for button in toolbar.overflowed {
            let item = try #require(elements.first { $0.path == "editorRoot/toolbar/overflow:\(button.name)" })
            #expect(item.label == button.title && item.command == button.command && item.isOnScreen)
        }
        // ui.click on an overflowed button: put Snap in the menu, click it by its label.
        let snap = try #require(toolbar.descendant(named: "snapping") as? Button)
        toolbar.overflowOrder = [snap] + toolbar.overflowOrder.filter { $0 !== snap }
        app.syncPanels()
        #expect(toolbar.overflowed.contains { $0 === snap })
        let before = app.session.snapping
        let client = LayoutClient(app)
        client.call("ui.click", ["label": "Snap", "role": "button"])
        #expect(app.session.snapping != before)
        #expect(!app.ui.overlays.contains { $0 is PopupMenu })
        // Wide windows need no menu.
        app.resizeWithoutWindow(size: Vec2(1440, 900))
        #expect(toolbar.overflowed.isEmpty && toolbar.moreButton.isHidden)
    }

    /// Panel content taller than its panel scrolls with the panel (#33): prefab variant rows in
    /// a short inspector pushed Add Component below the window.
    @Test func panelContentScrollsWhenTallerThanThePanel() throws {
        let app = layoutApp(Vec2(1280, 720))
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("EditorLayoutTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        try #require(session.run(ProjectNewCommand.self, .init(path: folder.path)) != nil)
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube, name: "Crate")))
        try #require(session.run(PrefabCreateCommand.self, .init(entity: cube.entity)) != nil)
        let client = LayoutClient(app)
        let id = JSON.string(cube.entity.description)
        client.call("component.setField", ["entity": id, "path": "Transform.position", "value": [0, 2, 0]])
        try #require(session.run(PrefabCreateVariantCommand.self, .init(entity: cube.entity, name: "Crate Variant")) != nil)
        client.call("component.setField", ["entity": id, "path": "MeshRenderer.receivesShadows", "value": false])
        session.run(SelectionSetCommand.self, .init(entities: [cube.entity], primary: cube.entity))
        // A short inspector: the console takes most of its column.
        client.call("panel.dock", ["panel": "console", "edge": "bottom", "beside": "inspector", "fraction": 0.8])
        app.syncPanels()
        let group = try #require(app.inspector.view.parent as? TabView)
        let add = try #require(app.inspector.view.descendant(named: "addComponent"))
        #expect(group.contentOverflow > 0, "inspector \(group.contentArea), Add Component \(add.frame)")
        expectClean(app, "prefab variant in a short inspector")
        // Scrolling the panel brings Add Component into view.
        app.ui.synthesizeScroll(at: group.contentArea.center, by: Vec2(0, -1000))
        app.syncPanels()
        #expect(group.contentOffset == group.contentOverflow)
        #expect(add.frame.maxY <= group.contentArea.maxY + 0.5 && add.frame.y >= group.contentArea.y)
    }

    /// Selecting the entity that is already selected while an asset is in the inspector shows
    /// the entity again (the review's prefab-variant state kept showing the asset).
    @Test func reselectingTheSelectedEntityLeavesTheAssetInspector() throws {
        let app = layoutApp(Vec2(1280, 720))
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("EditorLayoutTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        try #require(session.run(ProjectNewCommand.self, .init(path: folder.path)) != nil)
        let material = try #require(session.run(AssetNewMaterialCommand.self, .init(name: "EditorLayoutTests Red")))
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube)))
        session.run(SelectionSetCommand.self, .init(entities: [cube.entity]))
        try #require(session.run(AssetSelectCommand.self, .init(asset: AssetReference(material.asset))) != nil)
        #expect(session.inspectedAsset != nil)
        app.syncPanels()
        #expect(app.assetBrowser.model.selection != nil)
        session.run(SelectionSetCommand.self, .init(entities: [cube.entity]))
        #expect(session.inspectedAsset == nil)
        // The asset browser drops its highlight with it.
        app.syncPanels()
        #expect(app.assetBrowser.model.selection == nil && app.assetBrowser.grid.selected == nil)
    }

    /// A prefab variant's thumbnail shows what it resolves to (its file holds only the base and
    /// overrides, so it previewed empty).
    @Test func prefabVariantThumbnailsShowTheirBase() throws {
        let app = layoutApp(Vec2(1280, 720))
        let session = app.session
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("EditorLayoutTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        try #require(session.run(ProjectNewCommand.self, .init(path: folder.path)) != nil)
        let cube = try #require(session.run(EntityCreateCommand.self, .init(template: .cube, name: "Crate")))
        let prefab = try #require(session.run(PrefabCreateCommand.self, .init(entity: cube.entity)))
        let variant = try #require(session.run(PrefabCreateVariantCommand.self, .init(asset: prefab.prefab, name: "Crate Variant")))
        let assets = try #require(session.assets)
        _ = assets.waitForAll(timeout: 30)
        #expect(assets.prefab(variant.prefab)?.variant != nil)
        let world = World()
        let root = world.spawn(Transform())
        #expect(AssetThumbnails.spawnPrefab(variant.prefab, under: root, in: world, assets: assets))
        var meshes = 0
        func visit(_ entity: Entity) {
            if world.has(MeshRenderer.self, for: entity) { meshes += 1 }
            for child in world.children(of: entity) { visit(child) }
        }
        visit(root)
        #expect(meshes == 1)
        // Its thumbnail is remade when the base changes too.
        #expect(AssetThumbnails.revision(of: variant.prefab, in: assets) != assets.revision(of: variant.prefab.asset))
    }

    /// The viewport's caption sits in its tab bar, where it can't cover scene labels (#30);
    /// it falls back to the badge only when the bar has no room.
    @Test func viewportCaptionIsInTheTabBar() throws {
        let app = layoutApp(Vec2(1280, 720))
        let panel = try #require(app.dock.panel(EditorLayout.viewport))
        #expect(panel.caption == "Perspective · Move")
        #expect(panel.owner?.captionIsShown == true && !app.viewportWidget.drawsCaption)
        let client = LayoutClient(app)
        client.call("panel.dock", ["panel": "hierarchy", "edge": "left", "fraction": 0.45])
        client.call("panel.dock", ["panel": "inspector", "edge": "right", "fraction": 0.5])
        app.syncPanels()
        if panel.owner?.captionIsShown == false { #expect(app.viewportWidget.drawsCaption) }
    }

    /// The document title hides rather than showing "U…" when the toolbar squeezes it.
    @Test func documentTitleHidesWhenSqueezed() throws {
        let app = layoutApp(Vec2(800, 600))
        let title = try #require(app.toolbar.view.descendant(named: "documentTitle") as? Label)
        #expect(title.minimumTruncatedWidth > 0)
        #expect(title.tooltip(at: title.frame.center) == (title.isTruncated ? title.text : nil))
        let wide = layoutApp(Vec2(1440, 900))
        let full = try #require(wide.toolbar.view.descendant(named: "documentTitle") as? Label)
        #expect(!full.isTruncated)
    }

    /// The inspector's name field shows a long name's start when not editing (#28).
    @Test func nameFieldShowsTheStartOfALongName() throws {
        let app = layoutApp(Vec2(800, 600))
        let client = LayoutClient(app)
        let entity = client.call("entity.create", ["template": "cube", "name": .string(longName)])["entity"] ?? nil
        client.call("selection.set", ["entities": [entity], "primary": entity])
        let field = try #require(app.inspector.view.descendant(named: "entityName") as? TextField)
        #expect(field.text == longName && !field.isFocused)
        #expect(field.characterIndex(atX: field.contentRect.x + 1) == 0)
        #expect(field.tooltip(at: field.frame.center) == longName)
    }

    @Test func themeTextMeetsWCAGContrast() {
        for theme in UITheme.presets {
            // Translucent surfaces (the game theme's) are judged over black, where they're drawn over a scene.
            func solid(_ c: UIColor) -> UIColor { c.a < 1 ? c.composited(over: .black) : c }
            let surfaces = [("panel", theme.panelBackground), ("field", theme.fieldBackground),
                            ("control", theme.controlBackground), ("popup", theme.popupBackground)].map { ($0.0, solid($0.1)) }
            let texts = [("text", theme.textColor), ("secondary", theme.secondaryTextColor), ("placeholder", theme.placeholderColor),
                         ("warning", theme.warningTextColor), ("error", theme.errorTextColor)]
            for (textName, text) in texts {
                // Placeholders only show in empty fields.
                for (surfaceName, surface) in surfaces where textName != "placeholder" || surfaceName == "field" {
                    let ratio = text.contrastRatio(with: surface)
                    #expect(ratio >= 4.5, "\(theme.name): \(textName) on \(surfaceName) is \(ratio):1")
                }
            }
            for (name, fill) in [("accent", theme.accent), ("accentHover", theme.accentHover), ("accentPressed", theme.accentPressed)] {
                let ratio = theme.accentText.contrastRatio(with: solid(fill))
                #expect(ratio >= 4.5, "\(theme.name): accentText on \(name) is \(ratio):1")
            }
            #expect(theme.tooltipText.contrastRatio(with: solid(theme.tooltipBackground)) >= 4.5, "\(theme.name) tooltip")
            let field = solid(theme.fieldBackground)
            for (i, axis) in theme.axisColors.enumerated() {
                #expect(axis.contrastRatio(with: field) >= 4.5, "\(theme.name): axis \(i) prefix is \(axis.contrastRatio(with: field)):1")
            }
            // Text in a focused selected row.
            let selected = theme.rowSelectedFocused.composited(over: solid(theme.panelBackground))
            #expect(theme.textColor.contrastRatio(with: selected) >= 4.5, "\(theme.name): text on a selected row")
            // Disabled text is exempt from WCAG, but under 3:1 it couldn't be read at all (#25).
            for (surfaceName, surface) in surfaces {
                let ratio = theme.disabledTextColor.contrastRatio(with: surface)
                #expect(ratio >= 3, "\(theme.name): disabled text on \(surfaceName) is \(ratio):1")
            }
            // And on a disabled button's half-faded fill.
            let disabledFill = theme.controlBackground.fading(0.5).composited(over: solid(theme.panelBackground))
            #expect(theme.disabledTextColor.contrastRatio(with: disabledFill) >= 3, "\(theme.name): disabled button")
            // Theme text sizes at the smallest editor zoom.
            #expect(theme.smallFontSize * EditorApp.uiScaleRange.lowerBound >= 9)
        }
    }
}
