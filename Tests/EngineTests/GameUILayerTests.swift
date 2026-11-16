import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineAssets
@testable import EngineUI

// UI / HUD Builder: the runtime game UI layer (`UILayoutPlayer`, `world.gameUI`), ScenePlayback
// hosting it, and cooking the images a layout names.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("GameUILayerTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "GameUILayer")
}

private let hudJSON = """
{
  "size": [800, 600], "values": {"health": 50},
  "widgets": [
    {"id": "hp", "type": "bar", "anchor": "topLeft", "bind": "health", "max": 100, "width": 200},
    {"id": "hpText", "type": "label", "anchor": "topLeft", "offset": [0, 30], "text": "HP {health}"},
    {"id": "go", "type": "button", "anchor": "center", "text": "Go", "event": "start"},
    {"id": "icon", "type": "image", "anchor": "topRight", "image": "UI/heart.png", "width": 32, "height": 32}
  ]
}
"""

private func hud() throws -> UIBuild { try AssetJSON.decoder().decode(UIBuild.self, from: Data(hudJSON.utf8)) }

private func pngData() -> Data {
    Image(width: 4, height: 4, pixels: [UInt8](repeating: 200, count: 4 * 4 * 4)).pngData()
}

@MainActor
@Suite struct GameUILayerTests {
    @Test func componentDefaultsAndDecoding() throws {
        let player = try AssetJSON.decoder().decode(UILayoutPlayer.self, from: Data(#"{"layout": "UI/hud.ui"}"#.utf8))
        #expect(player == UILayoutPlayer(layout: "UI/hud.ui"))
        #expect(player.visible && player.order == 0 && !player.focus)
    }

    @Test func playersShowLayoutsSetValuesAndSendEvents() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let hudID = try database.createUIBuild(try hud(), at: "UI/hud.ui")
        let menuID = try database.createUIBuild(UIBuild(widgets: [UIBuildWidget(id: "resume", type: .button, text: "Resume")]), at: "UI/menu.ui")

        let world = World()
        let root = Widget(name: "root")
        let layer = world.addGameUI(assets: { database }, in: root)
        #expect(world.gameUI === layer)
        #expect(root.children.first === layer.container)

        let hudEntity = world.spawn(Transform(), UILayoutPlayer(layout: "UI/hud.ui"))
        let menuEntity = world.spawn(Transform(), UILayoutPlayer(layout: AssetReference(menuID).description, order: 5))
        world.update(dt: 1.0 / 60)
        #expect(layer.views.count == 2)
        let hudView = try #require(world.uiLayout(for: hudEntity))
        let menuView = try #require(layer.view(named: "UI/menu.ui"))
        #expect(layer.view(named: AssetReference(hudID).description) === hudView)
        #expect(layer.views.last === menuView, "higher order draws on top")

        // Layer values reach every layout, now and when they load later.
        layer.set("health", 80)
        #expect(hudView.value("health") == .int(80))
        #expect(menuView.value("health") == .int(80))
        #expect(layer.value("health") == .int(80))

        // Events come with the entity whose layout sent them.
        var heard: [(String, Entity?)] = []
        layer.on("start") { event, entity in heard.append((event.name, entity)) }
        var all: [String] = []
        let listener = layer.onEvent { event, _ in all.append(event.name) }
        #expect(hudView.press("go"))
        #expect(menuView.press("resume"))
        #expect(heard.count == 1 && heard[0].0 == "start" && heard[0].1 == hudEntity)
        #expect(all == ["start", "resume"])
        layer.removeListener(listener)
        hudView.press("go")
        #expect(heard.count == 2 && all.count == 2)

        // An input bound to a key writes the layer's value, which every layout sees.
        hudView.load(try hud().applying(UIBuildEdit(addWidgets: [UIBuildWidget(id: "vol", type: .slider, bind: "volume")])))
        menuView.load(UIBuild(widgets: [UIBuildWidget(id: "resume", type: .button, text: "Resume"),
                                        UIBuildWidget(id: "volText", type: .label, text: "{volume}")]))
        #expect(hudView.change("vol", to: .double(0.5)))
        #expect(layer.value("volume") == .double(0.5))
        #expect((menuView.widget("volText") as? Label)?.text == "0.5")
        #expect(all.count == 2, "the removed listener heard nothing")

        // The component drives visibility and order.
        world.modify(UILayoutPlayer.self, for: hudEntity) { $0.visible = false }
        world.update(dt: 1.0 / 60)
        #expect(hudView.isHidden && !hudView.isShown)
        world.modify(UILayoutPlayer.self, for: hudEntity) { $0.visible = true }
        world.modify(UILayoutPlayer.self, for: hudEntity) { $0.order = 10 }
        world.update(dt: 1.0 / 60)
        #expect(!hudView.isHidden && layer.views.last === hudView)

        // Pointing the component at another file swaps the layout; removing the entity drops it.
        world.modify(UILayoutPlayer.self, for: menuEntity) { $0.layout = "UI/hud.ui" }
        world.update(dt: 1.0 / 60)
        #expect(world.uiLayout(for: menuEntity) !== menuView && world.uiLayout(for: menuEntity)?.widget("go") != nil)
        world.despawn(menuEntity)
        world.update(dt: 1.0 / 60)
        #expect(layer.views.count == 1 && layer.views.first === hudView)

        // Layouts and widgets shown by code.
        let shown = try #require(layer.show("UI/menu.ui", order: -1))
        #expect(layer.views.first === shown)
        #expect(layer.show("UI/none.ui") == nil)
        let box = Widget(name: "GameUILayerTests.box")
        layer.add(box, order: 20)
        #expect(layer.container.children.last === box)
        layer.hide(shown)
        #expect(!layer.views.contains { $0 === shown })
        layer.remove(box)
        #expect(box.parent == nil)

        world.removeGameUI()
        #expect(world.gameUI == nil && root.children.isEmpty && hudView.parent == nil)
        world.update(dt: 1.0 / 60)
    }

    @Test func layoutsPlayTheirTransitionsOnTheLayer() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        var build = try hud()
        build.show = UIBuildTransition(kind: .fade, duration: 0.2)
        build.hide = UIBuildTransition(kind: .slide, duration: 0.2)
        _ = try database.createUIBuild(build, at: "UI/pause.ui")
        let context = UIContext.gameUI()
        let world = World()
        let layer = world.addGameUI(assets: { database }, in: context.root)
        let menu = try #require(layer.show("UI/pause.ui", order: 1))
        #expect(menu.isAnimating && menu.opacity == 0, "shows with its transition")
        menu.advance(by: 1)
        #expect(menu.opacity == 1)
        layer.hide(menu)
        #expect(layer.views.contains { $0 === menu }, "stays on the layer while its hide transition plays")
        menu.advance(by: 0.1)
        #expect(layer.views.contains { $0 === menu })
        menu.advance(by: 0.2)
        #expect(!layer.views.contains { $0 === menu } && menu.parent == nil)
        withExtendedLifetime(context) {}
    }

    @Test func scenePlaybackHostsTheLayer() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let id = try database.createUIBuild(try hud(), at: "UI/hud.ui")
        let scene = World()
        _ = scene.spawn(Transform(), Name("HUD"), UILayoutPlayer(layout: AssetReference(id).description))
        let data = try scene.save()

        let context = UIContext.gameUI()
        #expect(context.directionalNavigation)
        let playback = ScenePlayback(module: GameModule(), context: GameContext(input: Input()), assets: { database }, log: { _ in }) { _ in data }
        playback.uiRoot = context.root
        try playback.load("Main.scene")
        let layer = try #require(playback.gameUI)
        #expect(playback.world.gameUI === layer)
        playback.world.update(dt: 1.0 / 60)
        #expect(layer.views.count == 1)
        #expect(layer.container.parent === context.root)

        // Loading another scene starts a fresh layer.
        try playback.load("Main.scene")
        #expect(playback.gameUI !== layer && layer.container.parent == nil)
        playback.world.update(dt: 1.0 / 60)
        #expect(playback.gameUI?.views.count == 1)
    }

    @Test func cookingShipsALayoutsImages() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        try FileManager.default.createDirectory(at: project.url(forAssetPath: "UI"), withIntermediateDirectories: true)
        try pngData().write(to: project.url(forAssetPath: "UI/heart.png"))
        try pngData().write(to: project.url(forAssetPath: "UI/unused.png"))
        let database = AssetDatabase(project: project)
        database.scan()
        let heart = try #require(database.id(forPath: "UI/heart.png"))
        let unused = try #require(database.id(forPath: "UI/unused.png"))
        let layout = try database.createUIBuild(try hud(), at: "UI/hud.ui")

        let world = World()
        _ = world.spawn(Transform(), UILayoutPlayer(layout: AssetReference(layout).description))
        try FileManager.default.createDirectory(at: project.url(forAssetPath: "Scenes"), withIntermediateDirectories: true)
        try world.save().write(to: project.url(forAssetPath: "Scenes/Main.scene"))
        database.scan()

        let report = try AssetCooker.plan(database: database, options: CookOptions(scenes: ["Scenes/Main.scene"]))
            .run(to: project.root.appendingPathComponent("out"))
        let pack = try AssetPack(url: URL(fileURLWithPath: report.packPath))
        #expect(pack.contains(layout))
        #expect(pack.contains(heart), "the layout's image ships")
        #expect(!pack.contains(unused))
    }
}
