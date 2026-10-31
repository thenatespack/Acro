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
        for theme in UITheme.presets {
            let app = layoutApp(Vec2(1280, 720), theme: theme.name)
            #expect(app.ui.theme.name == theme.name)
            // The dividers between panels are the theme's (they were the dark theme's in every theme).
            let split = try #require(app.dock.descendant(named: "dockSplit") as? SplitView)
            #expect(split.dividerColor == theme.fieldBackground)
            checkBusyStates(app, theme.name)
            expectClean(layoutApp(Vec2(800, 600), theme: theme.name), "\(theme.name) 800x600")
        }
    }

    @Test func auditCatchesBrokenLayouts() throws {
        // The toolbar as it was (one row): its right end runs off an 800-point window.
        let app = layoutApp(Vec2(800, 600))
        app.toolbar.view.wraps = false
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

    @Test func longUndoTitleEndsInAnEllipsisWithTheWholeTitleAsTooltip() throws {
        let app = layoutApp(Vec2(1280, 720))
        let client = LayoutClient(app)
        let entity = client.call("entity.create", ["template": "cube"])["entity"] ?? nil
        client.call("component.setField", ["entity": entity, "path": "Transform.position.x", "value": 2,
                                           "label": .string("Move " + longName)])
        app.syncPanels()
        let undo = try #require(app.ui.root.descendant(named: "undo") as? Button)
        #expect(undo.title.hasPrefix("Undo AI: Move") && undo.titleIsTruncated)
        #expect(undo.frame.width <= 220)
        #expect(undo.tooltip(at: undo.frame.center)?.contains(longName) == true)
        // Everything after it in the toolbar is still in the window.
        expectClean(app, "long undo title")
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
            // Theme text sizes at the smallest editor zoom.
            #expect(theme.smallFontSize * EditorApp.uiScaleRange.lowerBound >= 9)
        }
    }
}
