import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// UI / HUD Builder: the `.ui` model, validation, editing, the importer and `UIBuildView` (layout, bindings, events, hot reload).

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("UIBuildTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "UIBuild")
}

private func decode(_ json: String) throws -> UIBuild {
    try AssetJSON.decoder().decode(UIBuild.self, from: Data(json.utf8))
}

private let hud = """
{
  "theme": "dark", "colors": {"accent": "#33AAFF"}, "safeArea": 10, "size": [800, 600],
  "values": {"health": 50, "score": 7},
  "widgets": [
    {"id": "status", "type": "vstack", "anchor": "topLeft", "offset": [5, 5], "spacing": 4},
    {"id": "hp", "type": "bar", "parent": "status", "bind": "health", "max": 100, "width": 200, "kind": "health"},
    {"id": "hpText", "type": "label", "parent": "status", "text": "HP {health} / 100"},
    {"id": "score", "type": "label", "anchor": "topRight", "bind": "score"},
    {"id": "box", "type": "panel", "anchor": "bottomRight", "offset": [20, 30], "width": 100, "height": 50, "background": "panel"},
    {"id": "go", "type": "button", "parent": "box", "anchor": "center", "text": "Go", "event": "start"},
    {"id": "dead", "type": "label", "anchor": "center", "text": "You died", "visibleWhen": "!alive"}
  ]
}
"""

@MainActor private func laidOut(_ view: UIBuildView, size: Vec2) -> UIContext {
    let context = UIContext()
    context.root.addChild(view)
    context.setViewport(size: size, scale: 1)
    context.layoutIfNeeded()
    return context
}

@Suite struct UIBuildTests {
    // MARK: Model

    @Test func everyKeyIsOptionalAndDefaultsAreNotWritten() throws {
        let empty = try decode("{}")
        #expect(empty == UIBuild())
        #expect(empty.theme == "game" && empty.size == Vec2(1280, 720))
        let widget = try AssetJSON.decoder().decode(UIBuildWidget.self, from: Data("{}".utf8))
        #expect(widget == UIBuildWidget())

        let build = try decode(hud)
        let reread = try AssetJSON.decoder().decode(UIBuild.self, from: build.fileData())
        #expect(reread == build)
        let text = try #require(String(data: build.fileData(), encoding: .utf8))
        #expect(!text.contains("\"opacity\"") && !text.contains("\"segments\""), "defaults are left out")
        #expect(text.contains("\"visibleWhen\" : \"!alive\""))
    }

    @Test func textPlaceholdersAndValues() {
        #expect(UIBuild.placeholders(in: "HP {health} / {max} {health}") == ["health", "max"])
        let values: [String: JSONValue] = ["health": .double(72.5), "max": .int(100), "name": .string("Ana")]
        #expect(UIBuild.fill("HP {health}/{ max } {name}{missing}!", values: values) == "HP 72.5/100 Ana!")
        #expect(UIBuild.display(.double(3)) == "3" && UIBuild.display(.double(0.126)) == "0.13")
        #expect(UIBuild.truthy(.string("false")) == false && UIBuild.truthy(.int(2)) && !UIBuild.truthy(nil))
        #expect(UIBuild.isVisible("!alive", values: [:]) && !UIBuild.isVisible("alive", values: ["alive": .bool(false)]))
        #expect(UIBuild.number(.string(" 4 ")) == 4)
    }

    @Test func keysAndEvents() throws {
        let build = try decode(hud)
        #expect(build.valueKeys == ["alive", "health", "score"])
        #expect(build.events == ["start"])
        #expect(build.widget("go")?.eventName == "start")
        #expect(UIBuildWidget(id: "quit", type: .button).eventName == "quit")
    }

    @Test func validationReportsProblems() throws {
        var build = try decode(hud)
        #expect(build.validate().isEmpty, "\(build.validate())")
        build.theme = "neon"
        build.colors["glow"] = "red"
        build.widgets.append(UIBuildWidget(id: "hp", type: .label))
        build.widgets.append(UIBuildWidget(id: "orphan", type: .label, parent: "nowhere"))
        build.widgets.append(UIBuildWidget(id: "inLabel", type: .label, parent: "score"))
        build.widgets.append(UIBuildWidget(id: "pic", type: .image, color: "#12", image: "UI/missing.png"))
        build.widgets.append(UIBuildWidget(id: "", type: .spacer))
        let messages = build.validate(imageExists: { _ in false }).map(\.description)
        #expect(messages.contains { $0.contains("unknown theme 'neon'") })
        #expect(messages.contains { $0.contains("unknown theme color 'glow'") })
        #expect(messages.contains { $0.contains("'red' isn't a #RRGGBB[AA] color") })
        #expect(messages.contains { $0 == "hp: duplicate id (the first one wins)" })
        #expect(messages.contains { $0.hasPrefix("orphan: no parent 'nowhere'") })
        #expect(messages.contains { $0.hasPrefix("inLabel: parent 'score' is a label") })
        #expect(messages.contains { $0 == "pic: no image asset 'UI/missing.png'" })
        #expect(messages.contains { $0.hasPrefix("pic: color '#12'") })
        #expect(messages.contains { $0.contains("a widget needs an id") })

        // A parent cycle is reported and both widgets fall back to the screen.
        var cycle = UIBuild(widgets: [UIBuildWidget(id: "a", type: .panel, parent: "b"), UIBuildWidget(id: "b", type: .panel, parent: "a")])
        #expect(cycle.validate().contains { $0.message.contains("parent cycle") })
        #expect(cycle.effectiveParent(of: cycle.widgets[0]) == "")
        cycle.widgets.append(UIBuildWidget(id: "c", type: .label, parent: "a"))
        #expect(cycle.effectiveParent(of: cycle.widgets[2]) == "a")
    }

    // MARK: Editing

    @Test func editAppliesInOrder() throws {
        let build = try decode(hud)
        let edited = try build.applying(UIBuildEdit(
            removeWidgets: ["box"],
            addWidgets: [UIBuildWidget(type: .label, parent: "status", text: "Ammo {ammo}"), UIBuildWidget(id: "score", type: .label)],
            updateWidgets: ["status": .object(["id": .string("left"), "spacing": .int(10)]), "score": .object(["fontSize": .int(30), "anchor": .null])],
            moveWidgets: [UIBuildMove(id: "label", index: 0)],
            bindings: ["hp": "playerHealth"],
            values: ["ammo": .int(12), "score": .null],
            colors: ["accent": "", "danger": "#FF0000"], safeArea: -1, size: Vec2(0, 900)))
        #expect(edited.widget("box") == nil && edited.widget("go") == nil, "removing a panel removes what is in it")
        #expect(edited.widget("score2") != nil, "a taken id gets a number")
        #expect(edited.widget("left")?.spacing == 10)
        #expect(edited.children(of: "left").map(\.id) == ["label", "hp", "hpText"], "renaming carries children; the move put the label first")
        #expect(edited.widget("score")?.fontSize == 30 && edited.widget("score")?.anchor == .topLeft, "null resets a field")
        #expect(edited.widget("hp")?.bind == "playerHealth")
        #expect(edited.values == ["health": .int(50), "ammo": .int(12)])
        #expect(edited.colors == ["danger": "#FF0000"])
        #expect(edited.safeArea == nil && edited.size == Vec2(1, 900))
    }

    @Test func editErrors() throws {
        let build = try decode(hud)
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(removeWidgets: ["nobody"])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(addWidgets: [UIBuildWidget(type: .label, parent: "score")])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(updateWidgets: ["hp": .object(["colour": .string("#fff")])])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(updateWidgets: ["hp": .object(["id": .string("score")])])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(updateWidgets: ["hp": .object(["type": .string("dial")])])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(moveWidgets: [UIBuildMove(id: "status", parent: "status")])) }
        #expect(throws: UIBuildError.self) { try build.applying(UIBuildEdit(bindings: ["nobody": "x"])) }
    }

    @Test func movingReordersAndReparents() throws {
        var build = try decode(hud)
        try build.move("score", to: "status", index: 1)
        #expect(build.children(of: "status").map(\.id) == ["hp", "score", "hpText"])
        try build.move("score", to: "", index: 0)
        #expect(build.children(of: "").map(\.id).first == "score")
        try build.move("hp", to: nil, index: 5)
        #expect(build.children(of: "status").map(\.id) == ["hpText", "hp"], "an index past the end puts it last")
    }

    // MARK: Runtime

    @MainActor @Test func viewLaysOutBindsAndHides() throws {
        let view = UIBuildView(try decode(hud))
        let context = laidOut(view, size: Vec2(800, 600))
        _ = context
        #expect(view.frame == UIRect(x: 0, y: 0, width: 800, height: 600))

        let bar = try #require(view.widget("hp") as? ProgressBar)
        #expect(bar.value == 0.5, "the sample value fills the bar until code sets one")
        #expect(bar.kind == .health)
        let status = try #require(view.widget("status"))
        #expect(status.frame.x == 15 && status.frame.y == 15, "safe area 10 plus offset 5")
        #expect((view.widget("hpText") as? Label)?.text == "HP 50 / 100")
        #expect((view.widget("score") as? Label)?.text == "7", "a bound label shows the value")

        let box = try #require(view.widget("box"))
        #expect(box.frame == UIRect(x: 800 - 10 - 20 - 100, y: 600 - 10 - 30 - 50, width: 100, height: 50))
        let go = try #require(view.widget("go"))
        #expect(abs(go.frame.center.x - box.frame.center.x) <= 1 && abs(go.frame.center.y - box.frame.center.y) <= 1)
        let score = try #require(view.widget("score"))
        #expect(score.frame.maxX == 790)

        #expect(view.widget("dead")?.isHidden == false)
        view.set("alive", true)
        #expect(view.widget("dead")?.isHidden == true)

        view.set("health", 25)
        #expect(bar.value == 0.25)
        view.set("score", 1200)
        #expect((view.widget("score") as? Label)?.text == "1200")
        view.clear("score")
        #expect((view.widget("score") as? Label)?.text == "7")
        view.usesSampleValues = false
        #expect((view.widget("score") as? Label)?.text == "")
        #expect(view.layoutID(of: go) == "go" && view.layoutID(of: view) == nil)
    }

    @MainActor @Test func themeOverrideAndColors() throws {
        let view = UIBuildView(try decode(hud))
        let context = laidOut(view, size: Vec2(800, 600))
        #expect(context.theme.name == "Dark")
        let theme = try #require(view.widget("go")?.theme)
        #expect(theme.accent == UIColor(0.2, 2.0 / 3.0, 1, 1), "the layout's accent reaches its widgets")
        #expect(context.root.theme.accent != theme.accent, "the context's theme is untouched")
        #expect(view.widget("box")?.background == theme.panelBackground, "theme color names resolve")
        #expect(theme.uiBuildColor("#FF000080") == UIColor(1, 0, 0, 128.0 / 255))
        #expect(theme.uiBuildColor("nope") == nil)
        var bigger = UIBuild(theme: "game", fontSize: 36)
        #expect(bigger.makeTheme().fontSize == 36 && bigger.makeTheme().smallFontSize == 28)
        bigger.theme = "light"
        #expect(bigger.makeTheme().name == "Light")
    }

    @MainActor @Test func buttonsSendEvents() throws {
        let view = UIBuildView(try decode(hud))
        let context = laidOut(view, size: Vec2(800, 600))
        var heard: [String] = []
        var events: [UIBuildEvent] = []
        view.on("start") { heard.append("start") }
        view.onEvent = { events.append($0) }
        #expect(view.press("go"))
        #expect(!view.press("hp") && !view.press("nobody"))
        #expect(heard == ["start"] && events == [UIBuildEvent(name: "start", widget: "go")])

        // A real click through the context.
        let go = try #require(view.widget("go"))
        context.pointerMoved(to: go.frame.center)
        context.pointerButton(.left, down: true)
        context.pointerButton(.left, down: false)
        #expect(heard == ["start", "start"])

        // Clicks between widgets aren't taken by the view.
        #expect(context.hitTest(Vec2(400, 300)) == nil)
        view.removeHandlers(for: "start")
        view.press("go")
        #expect(heard.count == 2 && events.count == 3)
    }

    @MainActor @Test func importerWarnsAndViewFollowsHotReload() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var build = try decode(hud)
        build.widgets.append(UIBuildWidget(id: "icon", type: .image, image: "UI/heart.png"))
        let id = try database.createUIBuild(build, at: "UI/hud.ui")
        #expect(database.record(id)?.importer == "ui")
        #expect(database.record(id)?.importError == nil)
        #expect(database.uiBuild(of: id) == build)
        #expect(database.uiBuild(path: "Assets/UI/hud.ui") == build)
        #expect(database.uiBuildIssues(build).contains { $0.description == "icon: no image asset 'UI/heart.png'" })

        let view = try #require(UIBuildView(assets: database, path: "UI/hud.ui"))
        #expect(UIBuildView(assets: database, path: "UI/none.ui") == nil)
        _ = laidOut(view, size: Vec2(800, 600))
        view.set("health", 80)
        #expect(!view.reloadIfChanged())

        var changed = build
        changed.widgets[3].text = "Score {score}!"
        let warnings = try database.writeUIBuild(changed, to: id)
        #expect(warnings.contains { $0.contains("no image asset 'UI/heart.png'") }, "\(warnings)")
        #expect(view.reloadIfChanged())
        #expect((view.widget("score") as? Label)?.text == "Score 7!")
        #expect((view.widget("hp") as? ProgressBar)?.value == 0.8, "values set by code survive a reload")

        // Garbage doesn't import.
        try Data("{\"widgets\": [{\"type\": \"dial\"}]}".utf8).write(to: project.assetsURL.appendingPathComponent("bad.ui"))
        let report = database.refresh()
        #expect(report.errors.contains { $0.path == "bad.ui" })
    }

    @MainActor @Test func panelSizesToItsChildren() throws {
        let build = UIBuild(safeArea: 0, widgets: [
            UIBuildWidget(id: "p", type: .panel, anchor: .center, padding: 10),
            UIBuildWidget(id: "a", type: .spacer, parent: "p", offset: Vec2(5, 5), width: 40, height: 20),
            UIBuildWidget(id: "f", type: .panel, anchor: .fill, offset: Vec2(30, 40)),
        ])
        let view = UIBuildView(build)
        _ = laidOut(view, size: Vec2(400, 300))
        #expect(view.widget("p")?.frame == UIRect(x: 200 - 32.5, y: 150 - 22.5, width: 65, height: 45).snappedForTest)
        #expect(view.widget("f")?.frame == UIRect(x: 30, y: 40, width: 340, height: 220))
    }

    // MARK: Sliders, toggles and text fields

    @MainActor @Test func inputsBindAndSendEvents() throws {
        let build = try decode("""
        {"size": [800, 600], "values": {"volume": 0.25, "muted": false, "name": "Ana"},
         "widgets": [
           {"id": "settings", "type": "vstack", "anchor": "center", "width": 300},
           {"id": "vol", "type": "slider", "parent": "settings", "bind": "volume", "min": 0, "max": 1, "step": 0.25, "event": "volumeChanged"},
           {"id": "volText", "type": "label", "parent": "settings", "text": "Volume {volume}"},
           {"id": "mute", "type": "toggle", "parent": "settings", "text": "Mute", "bind": "muted", "toggleStyle": "switch"},
           {"id": "name", "type": "textField", "parent": "settings", "bind": "name", "placeholder": "Your name", "maxLength": 5, "event": "rename"},
           {"id": "loose", "type": "toggle", "parent": "settings", "text": "Loose", "on": true}
         ]}
        """)
        #expect(build.validate().isEmpty)
        #expect(build.events == ["loose", "mute", "rename", "volumeChanged"])
        let reread = try AssetJSON.decoder().decode(UIBuild.self, from: build.fileData())
        #expect(reread == build)
        var bad = build
        bad.widgets[1].max = 0
        #expect(bad.validate().contains { $0.description == "vol: max must be above min" })

        let view = UIBuildView(build)
        let context = laidOut(view, size: Vec2(800, 600))
        let slider = try #require(view.widget("vol") as? Slider)
        let toggle = try #require(view.widget("mute") as? Checkbox)
        let field = try #require(view.widget("name") as? TextField)
        #expect(slider.value == 0.25 && slider.range == 0...1 && !toggle.isOn && toggle.kind == .toggleSwitch)
        #expect(field.text == "Ana" && field.placeholder == "Your name" && field.maxLength == 5)
        #expect((view.widget("loose") as? Checkbox)?.isOn == true, "unbound toggles start at on")

        // Code sets the bound keys.
        view.set("volume", 0.75)
        view.set("muted", true)
        view.set("name", "Bo")
        #expect(slider.value == 0.75 && toggle.isOn && field.text == "Bo")

        // The player changes them: the key follows, text reading it updates, the event carries the value.
        var events: [UIBuildEvent] = []
        view.onEvent = { events.append($0) }
        #expect(view.change("vol", to: .double(0.4)))
        #expect(slider.value == 0.5, "snapped to the step")
        #expect(view.value("volume") == .double(0.5))
        #expect((view.widget("volText") as? Label)?.text == "Volume 0.5")
        #expect(events.last == UIBuildEvent(name: "volumeChanged", widget: "vol", value: .double(0.5), key: "volume"))
        #expect(view.change("mute", to: .bool(false)))
        #expect(events.last == UIBuildEvent(name: "mute", widget: "mute", value: .bool(false), key: "muted"))
        #expect(view.change("name", to: .string("Cy")))
        #expect(events.last == UIBuildEvent(name: "rename", widget: "name", value: .string("Cy"), key: "name"))
        #expect(!view.change("vol", to: .string("loud")) && !view.change("volText", to: .bool(true)) && !view.press("vol"))

        // A real click on the toggle.
        context.pointerMoved(to: toggle.frame.center)
        context.pointerButton(.left, down: true)
        context.pointerButton(.left, down: false)
        #expect(toggle.isOn && view.value("muted") == .bool(true))
        #expect(events.last?.name == "mute" && events.last?.value == .bool(true))

        // Typing updates the key at once; Enter sends the event.
        context.focus(field)
        let before = events.count
        context.textEntered("Zed")
        #expect(view.value("name") == .string("CyZed") && events.count == before)
        context.textEntered("Long")
        #expect(field.text == "CyZed", "maxLength")
        context.keyPressed(KeyEvent(key: .enter))
        #expect(events.last == UIBuildEvent(name: "rename", widget: "name", value: .string("CyZed"), key: "name"))
    }


    // MARK: Transitions and tweens

    @Test func transitionsRoundTripAndPose() throws {
        let build = try decode("""
        {"show": {"kind": "slide", "from": "left", "distance": 100}, "hide": {"kind": "fade", "duration": 0.5},
         "widgets": [{"id": "a", "type": "label", "show": {"kind": "scale"}, "tween": 0.3}]}
        """)
        #expect(build.show == UIBuildTransition(kind: .slide, from: .left, distance: 100))
        #expect(build.hide == UIBuildTransition(kind: .fade, duration: 0.5))
        #expect(build.widgets[0].show?.kind == .scale && build.widgets[0].hide == nil && build.widgets[0].tween == 0.3)
        #expect(try AssetJSON.decoder().decode(UIBuild.self, from: build.fileData()) == build)
        let text = try #require(String(data: build.fileData(), encoding: .utf8))
        #expect(!text.contains("\"scale\" : 0.85"), "defaults aren't written")

        let slide = try #require(build.show)
        #expect(slide.pose(shown: 0).offset == Vec2(-100, 0) && slide.pose(shown: 0).opacity == 0)
        #expect(slide.pose(shown: 1).offset == .zero && slide.pose(shown: 1).opacity == 1)
        let scale = UIBuildTransition(kind: .scale, scale: 0.5)
        #expect(scale.pose(shown: 0).scale == 0.5 && scale.pose(shown: 0.5).scale == 0.75)
        #expect(!UIBuildTransition(kind: .none).animates && !UIBuildTransition(duration: 0).animates)

        // Edits: kind none removes a layout transition.
        let edited = try build.applying(UIBuildEdit(show: UIBuildTransition(kind: .none), hide: UIBuildTransition(kind: .scale)))
        #expect(edited.show == nil && edited.hide?.kind == .scale)
        var bad = build
        bad.widgets[0].tween = -1
        bad.hide?.duration = -1
        #expect(bad.validate().map(\.description).contains("a: tween can't be negative"))
        #expect(bad.validate().map(\.description).contains("hide: duration and delay can't be negative"))
    }

    @MainActor @Test func viewPlaysShowAndHideTransitions() throws {
        var build = try decode(hud)
        build.show = UIBuildTransition(kind: .fade, duration: 0.2, easing: .linear)
        build.hide = UIBuildTransition(kind: .slide, duration: 0.2, easing: .linear, from: .bottom, distance: 50)
        let view = UIBuildView(build)

        // Outside a context, at once.
        var hidden = 0
        view.hide { hidden += 1 }
        #expect(view.isHidden && !view.isShown && hidden == 1 && !view.isAnimating)
        view.show()
        #expect(!view.isHidden && view.opacity == 1)

        let context = laidOut(view, size: Vec2(800, 600))
        defer { withExtendedLifetime(context) {} }
        view.hide { hidden += 1 }
        #expect(!view.isHidden && view.isAnimating && hidden == 1)
        #expect(view.hitTest(try #require(view.widget("go")).frame.center) == nil, "clicks pass through while hiding")
        view.advance(by: 0.1)
        #expect(abs(view.opacity - 0.5) < 0.01 && abs(view.visualOffset.y - 25) < 0.01)
        view.advance(by: 0.15)
        #expect(view.isHidden && hidden == 2 && view.opacity == 1 && view.visualOffset == .zero && !view.isAnimating)

        view.show()
        #expect(!view.isHidden && view.opacity == 0 && view.isAnimating)
        view.advance(by: 0.05)
        #expect(abs(view.opacity - 0.25) < 0.01)
        view.advance(by: 1)
        #expect(view.opacity == 1 && !view.isAnimating)
        #expect(view.hitTest(try #require(view.widget("go")).frame.center) != nil)

        // Showing again mid-hide cancels the hide (its completion never runs).
        view.hide { hidden += 1 }
        view.advance(by: 0.1)
        view.show()
        view.advance(by: 1)
        #expect(!view.isHidden && hidden == 2)
    }

    @MainActor @Test func widgetsTransitionAndValuesTween() throws {
        var build = try decode(hud)
        let dead = try #require(build.index(of: "dead"))
        build.widgets[dead].show = UIBuildTransition(kind: .scale, duration: 0.4, easing: .linear, scale: 0.5)
        build.widgets[dead].hide = UIBuildTransition(kind: .fade, duration: 0.4, easing: .linear)
        let hp = try #require(build.index(of: "hp"))
        build.widgets[hp].tween = 1
        let hpText = try #require(build.index(of: "hpText"))
        build.widgets[hpText].tween = 1
        let view = UIBuildView(build)
        let context = laidOut(view, size: Vec2(800, 600))
        defer { withExtendedLifetime(context) {} }
        let label = try #require(view.widget("dead"))
        let bar = try #require(view.widget("hp") as? ProgressBar)
        #expect(!label.isHidden, "alive is unset: !alive is true")

        view.set("alive", true)
        #expect(!label.isHidden && view.isAnimating, "hiding: still drawn while it fades")
        view.advance(by: 0.2)
        #expect(abs(label.opacity - 0.5) < 0.01)
        view.advance(by: 0.3)
        #expect(label.isHidden && label.opacity == 1)

        view.set("alive", false)
        #expect(!label.isHidden && label.visualScale == 0.5)
        view.advance(by: 0.2)
        #expect(abs(label.visualScale - 0.75) < 0.01)
        view.advance(by: 0.3)
        #expect(label.visualScale == 1 && label.visualOffset == .zero)

        // Numbers tween: the bar's fill and the label's {health} move to the new value.
        #expect(bar.value == 0.5)
        view.set("health", 100)
        #expect(bar.value == 0.5 && (view.widget("hpText") as? Label)?.text == "HP 50 / 100")
        #expect(view.value("health") == .int(100), "the value itself is set at once")
        view.advance(by: 0.5)
        #expect(bar.value > 0.5 && bar.value < 1)
        let midway = try #require((view.widget("hpText") as? Label)?.text)
        #expect(midway != "HP 50 / 100" && midway != "HP 100 / 100" && !midway.contains("."), "whole numbers stay whole: \(midway)")
        view.advance(by: 0.6)
        #expect(bar.value == 1 && (view.widget("hpText") as? Label)?.text == "HP 100 / 100" && !view.isAnimating)
    }


    // MARK: Gamepad navigation

    @MainActor @Test func navigationOrderAndOverrides() throws {
        let build = try decode("""
        {"size": [800, 600], "navigation": ["quit", "play", "options"], "focus": "play",
         "widgets": [
           {"id": "menu", "type": "vstack", "anchor": "center"},
           {"id": "play", "type": "button", "parent": "menu", "text": "Play"},
           {"id": "options", "type": "button", "parent": "menu", "text": "Options", "visibleWhen": "hasOptions"},
           {"id": "quit", "type": "button", "parent": "menu", "text": "Quit", "navLeft": "play"},
           {"id": "title", "type": "label", "anchor": "top", "text": "Game"}
         ]}
        """)
        #expect(build.validate().isEmpty)
        #expect(try AssetJSON.decoder().decode(UIBuild.self, from: build.fileData()) == build)
        var bad = build
        bad.navigation.append("title")
        bad.widgets[1].navUp = "nobody"
        let problems = bad.validate().map(\.description)
        #expect(problems.contains("navigation: 'title' is a label, which can't take focus"))
        #expect(problems.contains("play: navUp: no widget 'nobody'"))

        // Renames and removals follow.
        var renamed = build
        try renamed.update("quit", fields: ["id": .string("exit")])
        #expect(renamed.navigation == ["exit", "play", "options"])
        let removed = try build.applying(UIBuildEdit(removeWidgets: ["play"]))
        #expect(removed.navigation == ["quit", "options"] && removed.focus == "" && removed.widget("quit")?.navLeft == "")

        let view = UIBuildView(build)
        let context = laidOut(view, size: Vec2(800, 600))
        context.directionalNavigation = true
        let play = try #require(view.widget("play")), quit = try #require(view.widget("quit"))
        #expect(view.focusStartWidget())
        #expect(context.focusedWidget === play, "the layout's focus widget")
        // Order quit → play → (options hidden: skipped) → quit.
        #expect(context.moveFocus(.down) && context.focusedWidget === quit)
        #expect(context.moveFocus(.down) && context.focusedWidget === play)
        #expect(context.moveFocus(.up) && context.focusedWidget === quit)
        view.set("hasOptions", true)
        let options = try #require(view.widget("options"))
        #expect(context.moveFocus(.up) && context.focusedWidget === options, "shown again: back in the order")
        // A widget's own link wins over the order.
        context.focus(quit)
        #expect(context.moveFocus(.left) && context.focusedWidget === play)
    }


    // MARK: Scaling with the screen

    @Test func scaleModeFactors() throws {
        let design = Vec2(800, 600)
        #expect(UIBuildScaleMode.none.factor(screen: Vec2(1600, 900), design: design) == 1)
        #expect(UIBuildScaleMode.fit.factor(screen: Vec2(1600, 900), design: design) == 1.5)
        #expect(UIBuildScaleMode.fill.factor(screen: Vec2(1600, 900), design: design) == 2)
        #expect(UIBuildScaleMode.width.factor(screen: Vec2(1600, 900), design: design) == 2)
        #expect(UIBuildScaleMode.height.factor(screen: Vec2(1600, 900), design: design) == 1.5)
        #expect(UIBuildScaleMode.fit.factor(screen: .zero, design: design) == 1)

        let build = try decode(#"{"size": [800, 600], "scaleMode": "fit"}"#)
        #expect(build.scaleMode == .fit)
        let text = try #require(String(data: try decode("{}").fileData(), encoding: .utf8))
        #expect(!text.contains("scaleMode"), "none is the default and isn't written")
        #expect(try build.applying(UIBuildEdit(scaleMode: .height)).scaleMode == .height)
    }

    @MainActor @Test func viewScalesTheWholeLayout() throws {
        let build = try decode("""
        {"size": [800, 600], "safeArea": 10, "scaleMode": "fit",
         "widgets": [
           {"id": "box", "type": "panel", "anchor": "topLeft", "offset": [20, 30], "width": 100, "height": 50, "background": "panel"},
           {"id": "go", "type": "button", "parent": "box", "anchor": "fill", "text": "Go"},
           {"id": "title", "type": "label", "anchor": "top", "text": "Title", "fontSize": 20}
         ]}
        """)
        let view = UIBuildView(build)
        let context = laidOut(view, size: Vec2(800, 600))
        #expect(view.layoutScale == 1)
        let box = try #require(view.widget("box"))
        #expect(box.frame == UIRect(x: 30, y: 40, width: 100, height: 50))
        let small = try #require(view.widget("title")).measure(width: nil)

        context.setViewport(size: Vec2(1600, 1500), scale: 1)
        context.layoutIfNeeded()
        #expect(view.layoutScale == 2)
        let scaledBox = try #require(view.widget("box"))
        #expect(scaledBox.frame == UIRect(x: 60, y: 80, width: 200, height: 100), "offsets, sizes and the safe area scale")
        let big = try #require(view.widget("title")).measure(width: nil)
        #expect(big.y > small.y * 1.8, "text scales too")

        // Clicks land on the scaled widgets.
        var pressed = 0
        view.on("go") { pressed += 1 }
        let go = try #require(view.widget("go"))
        context.pointerMoved(to: go.frame.center)
        context.pointerButton(.left, down: true)
        context.pointerButton(.left, down: false)
        #expect(pressed == 1)

        // none keeps points.
        var fixed = build
        fixed.scaleMode = .none
        view.load(fixed)
        context.layoutIfNeeded()
        #expect(view.layoutScale == 1 && view.widget("box")?.frame.width == 100)
    }
}

extension UIRect {
    /// Rounded to whole points like layout at scale 1.
    fileprivate var snappedForTest: UIRect {
        let x0 = x.rounded(), y0 = y.rounded()
        return UIRect(x: x0, y: y0, width: (x + width).rounded() - x0, height: (y + height).rounded() - y0)
    }
}
