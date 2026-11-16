import Foundation
import EngineAssets
import EngineBackends
import EngineCore
import EngineGraphics
import EngineRendering
import EngineScene
import EngineUI

// The runtime game UI layer: `.ui` layouts (UI / HUD Builder) shown over the game with no game
// code. Each `UILayoutPlayer` component gets a `UIBuildView`; game code shows more with
// `show(_:)`, hangs widgets of its own on the layer with `add(_:order:)` (a dialogue box), sets
// values every layout reads and listens for their events:
//
// ```swift
// let ui = world.gameUI!
// ui.set("health", 64)                       // shared by every layout on the layer
// ui.on("pause") { event, entity in ... }    // any layout's button / slider / toggle / field
// let menu = ui.show("UI/pause.ui", order: 10, focus: true)
// ui.hide(menu!)                             // plays the layout's hide transition, then removes it
// world.uiLayout(for: hud)?.set("score", 5)  // the layout of one entity's UILayoutPlayer
// ```
//
// Hosts: `ScenePlayback` (GameRunner and exported games) adds the layer when its `uiRoot` is
// set; the editor shows it over the Game view while playing. A host without a UI still gets a
// layer (with no parent widget), so game code that sets values runs the same everywhere.

/// A listener added with `GameUILayer.onEvent` (remove it with `removeListener`).
public struct GameUIListener: Hashable, Sendable {
    let id: Int
}

/// The game's `.ui` layouts over the scene. See the notes at the top of GameUILayer.swift.
@MainActor
public final class GameUILayer {
    public static let systemName = "gameUI.layouts"

    /// The widget the layouts are shown in: it fills its parent and lets clicks between widgets
    /// through. `World.addGameUI(assets:in:)` adds it to the host's widget.
    public let container: Widget
    /// Where layout files load from.
    public var assets: () -> AssetDatabase?
    /// Loads a layout image by path ("UI/heart.png" or "asset:<id>"); see `UIBuildView.imageLoader`.
    public var images: ((String) -> GPUTexture?)? {
        didSet { for view in views { view.images = images } }
    }
    /// Values every layout on the layer reads (set with `set(_:_:)`; a layout's own `set` wins for that layout).
    public private(set) var values: [String: JSONValue] = [:]

    private weak var world: World?
    private var players: [Entity: Player] = [:]
    /// Layouts and widgets game code put on the layer, with their order.
    private var extras: [(widget: Widget, order: Int, source: String)] = []
    private var listeners: [Int: (UIBuildEvent, Entity?) -> Void] = [:]
    private var handlers: [String: [(UIBuildEvent, Entity?) -> Void]] = [:]
    private var nextListener = 0
    private var orderDirty = false

    private struct Player {
        var view: UIBuildView
        var source: String
        var asset: AssetID?
        var order: Int
        var visible: Bool
        var focus: Bool
    }

    private static var byWorld: [ObjectIdentifier: Weak] = [:]
    private struct Weak { weak var layer: GameUILayer? }

    /// A layer of its own (not tied to a world): call `update` yourself, or use `World.addGameUI`.
    public init(world: World? = nil, assets: @escaping () -> AssetDatabase? = { nil }) {
        self.world = world
        self.assets = assets
        container = Widget(name: "gameUILayer")
        container.isHitTestable = false
        container.style.position = .absolute(.fill())
    }

    static func layer(for world: World) -> GameUILayer? {
        guard let layer = byWorld[ObjectIdentifier(world)]?.layer, layer.world === world else { return nil }
        return layer
    }

    static func set(_ layer: GameUILayer?, for world: World) {
        byWorld = byWorld.filter { $0.value.layer != nil }
        byWorld[ObjectIdentifier(world)] = layer.map { Weak(layer: $0) }
    }

    // MARK: Views

    /// Every layout on the layer: the components' and those shown by code, in drawing order.
    public var views: [UIBuildView] { container.children.compactMap { $0 as? UIBuildView } }

    /// The layout of `entity`'s `UILayoutPlayer` (loaded now if needed); nil when it has none
    /// or its file can't be read.
    public func view(for entity: Entity) -> UIBuildView? {
        sync(entity)
        return players[entity]?.view
    }

    /// The first layout on the layer showing `layout` (a path under `Assets/`, as the component
    /// or `show` named it, or "asset:<id>").
    public func view(named layout: String) -> UIBuildView? {
        let wanted = assets()?.assetID(forTableValue: layout)
        for (_, player) in players.sorted(by: { $0.key.index < $1.key.index }) {
            if player.source == layout || (wanted != nil && player.asset == wanted) { return player.view }
        }
        for extra in extras where extra.source == layout || (wanted != nil && assets()?.assetID(forTableValue: extra.source) == wanted) {
            if let view = extra.widget as? UIBuildView { return view }
        }
        return nil
    }

    /// Shows the `.ui` file `layout` (path under `Assets/` or "asset:<id>") on the layer, above
    /// layouts of lower `order`, playing its show transition. `focus` gives it keyboard /
    /// gamepad focus (a menu). Nil if there is no such layout.
    @discardableResult
    public func show(_ layout: String, order: Int = 0, focus: Bool = false) -> UIBuildView? {
        guard let assets = assets(), let id = assets.assetID(forTableValue: layout), let loaded = assets.uiBuildForGame(id) else { return nil }
        let view = makeView(loaded.build, entity: nil)
        view.follow(assets, asset: id)
        add(view, order: order, source: layout)
        view.show(animated: true)
        if focus { focusSoon(view) }
        return view
    }

    /// Shows a layout made in code.
    @discardableResult
    public func show(_ build: UIBuild, order: Int = 0, focus: Bool = false) -> UIBuildView {
        let view = makeView(build, entity: nil)
        add(view, order: order, source: "")
        view.show(animated: true)
        if focus { focusSoon(view) }
        return view
    }

    /// Hangs any widget on the layer (a `DialogueBox`, a game's own panel), above widgets of
    /// lower `order`. It is laid out like a child of a full-screen widget (use `style.position`).
    public func add(_ widget: Widget, order: Int = 0) {
        add(widget, order: order, source: "")
    }

    private func add(_ widget: Widget, order: Int, source: String) {
        remove(widget)
        extras.append((widget, order, source))
        container.addChild(widget)
        orderDirty = true
        sortIfNeeded()
    }

    /// Takes a layout or widget off the layer at once.
    public func remove(_ widget: Widget) {
        guard let index = extras.firstIndex(where: { $0.widget === widget }) else { return }
        extras.remove(at: index)
        widget.removeFromParent()
    }

    /// Hides a layout shown with `show` (its hide transition plays first) and takes it off the
    /// layer; a component's layout is hidden instead (set `UILayoutPlayer.visible` to show it again).
    public func hide(_ view: UIBuildView, animated: Bool = true) {
        if players.values.contains(where: { $0.view === view }) {
            view.hide(animated: animated)
            return
        }
        guard extras.contains(where: { $0.widget === view }) else { return }
        view.hide(animated: animated) { [weak self, weak view] in
            guard let self, let view else { return }
            remove(view)
        }
    }

    /// Takes every layout and widget off the layer.
    public func removeAll() {
        for player in players.values { player.view.removeFromParent() }
        players = [:]
        for extra in extras { extra.widget.removeFromParent() }
        extras = []
    }

    // MARK: Values

    /// Sets a value every layout reads (bars, `{key}` text, `bind`, `visibleWhen`).
    public func set(_ key: String, _ value: JSONValue) {
        guard values[key] != value else { return }
        values[key] = value
        for view in views { view.set(key, value) }
    }

    public func set(_ key: String, _ value: Double) { set(key, .double(value)) }
    public func set(_ key: String, _ value: Float) { set(key, .double(Double(value))) }
    public func set(_ key: String, _ value: Int) { set(key, .int(Int64(value))) }
    public func set(_ key: String, _ value: String) { set(key, .string(value)) }
    public func set(_ key: String, _ value: Bool) { set(key, .bool(value)) }

    /// The value set with `set` (not a layout's own or sample values).
    public func value(_ key: String) -> JSONValue? { values[key] }

    // MARK: Events

    /// Runs `handler` whenever a widget of any layout on the layer sends `event` (a button press,
    /// a slider / toggle / text field change), with the entity whose layout it is (nil: shown by code).
    public func on(_ event: String, _ handler: @escaping (UIBuildEvent, Entity?) -> Void) {
        handlers[event, default: []].append(handler)
    }

    /// Calls `handler` for every event of every layout on the layer.
    @discardableResult
    public func onEvent(_ handler: @escaping (UIBuildEvent, Entity?) -> Void) -> GameUIListener {
        nextListener += 1
        listeners[nextListener] = handler
        return GameUIListener(id: nextListener)
    }

    public func removeListener(_ listener: GameUIListener) { listeners[listener.id] = nil }

    /// Removes the handlers added with `on` for `event`.
    public func removeHandlers(for event: String) { handlers[event] = nil }

    private func dispatch(_ event: UIBuildEvent, entity: Entity?) {
        // An input bound to a key writes the layer's value, so every layout sees it (a volume slider's
        // menu and the HUD showing it) and `value(_:)` reads it.
        if let key = event.key, let value = event.value {
            values[key] = value
            for view in views where view.value(key) != value { view.set(key, value) }
        }
        for handler in handlers[event.name] ?? [] { handler(event, entity) }
        for listener in listeners.values { listener(event, entity) }
    }

    // MARK: Per frame

    /// The system's per-frame work: loads layouts for new `UILayoutPlayer`s, follows file and
    /// component changes, shows / hides them and drops those of removed entities.
    public func update() {
        guard let world else { return }
        var seen = Set<Entity>()
        world.query(UILayoutPlayer.self) { entity, _ in seen.insert(entity) }
        for entity in seen.sorted(by: { $0.index < $1.index }) { sync(entity) }
        for (entity, player) in players where !seen.contains(entity) {
            player.view.removeFromParent()
            players[entity] = nil
        }
        sortIfNeeded()
    }

    /// Loads or updates `entity`'s layout to match its component.
    private func sync(_ entity: Entity) {
        guard let world, let component = world.get(UILayoutPlayer.self, for: entity) else { return }
        let assets = assets()
        let id = assets?.assetID(forTableValue: component.layout)
        if var player = players[entity], player.source == component.layout, player.asset == id {
            if player.order != component.order {
                player.order = component.order
                orderDirty = true
            }
            if player.visible != component.visible {
                player.visible = component.visible
                if component.visible {
                    player.view.show(animated: true)
                    if component.focus { focusSoon(player.view) }
                } else {
                    player.view.hide(animated: true)
                }
            }
            player.focus = component.focus
            players[entity] = player
            return
        }
        players[entity]?.view.removeFromParent()
        players[entity] = nil
        guard let assets, let id, let loaded = assets.uiBuildForGame(id) else { return }
        let view = makeView(loaded.build, entity: entity)
        view.follow(assets, asset: id)
        players[entity] = Player(view: view, source: component.layout, asset: id, order: component.order, visible: component.visible,
                                 focus: component.focus)
        container.addChild(view)
        orderDirty = true
        if component.visible {
            view.show(animated: true)
            if component.focus { focusSoon(view) }
        } else {
            view.hide(animated: false)
        }
    }

    private func makeView(_ build: UIBuild, entity: Entity?) -> UIBuildView {
        let view = UIBuildView(build, name: "gameUI." + (entity.map { "\($0.index)" } ?? "shown"))
        view.images = images
        view.set(values)
        view.layerHandler = { [weak self] event in self?.dispatch(event, entity: entity) }
        return view
    }

    /// Puts the container's children in drawing order (by order, then when they were added).
    private func sortIfNeeded() {
        guard orderDirty else { return }
        orderDirty = false
        var ordered: [(widget: Widget, order: Int, rank: Int)] = []
        for (rank, child) in container.children.enumerated() {
            let order = players.values.first(where: { $0.view === child })?.order ?? extras.first(where: { $0.widget === child })?.order ?? 0
            ordered.append((child, order, rank))
        }
        let sorted = ordered.sorted { ($0.order, $0.rank) < ($1.order, $1.rank) }
        guard sorted.map({ ObjectIdentifier($0.widget) }) != container.children.map({ ObjectIdentifier($0) }) else { return }
        container.removeAllChildren()
        for entry in sorted { container.addChild(entry.widget) }
    }

    /// Focuses the view's start widget once it is in a context (now, or when next laid out).
    private func focusSoon(_ view: UIBuildView) {
        view.wantsFocus = true
        view.focusStartWidget()
    }
}

extension World {
    /// Adds the game UI layer (see `GameUILayer`): a system that shows a `UIBuildView` for every
    /// `UILayoutPlayer`, inside `host` (a widget filling the game's screen: a host's
    /// `UIContext.root`, the editor's Game view) or with no parent when nil. Layouts load from
    /// `assets`. Returns the layer (also `world.gameUI`); calling it again replaces it.
    @MainActor @discardableResult
    public func addGameUI(assets: @escaping () -> AssetDatabase?, in host: Widget?) -> GameUILayer {
        ComponentRegistry.register(UILayoutPlayer.self)
        removeGameUI()
        let layer = GameUILayer(world: self, assets: assets)
        GameUILayer.set(layer, for: self)
        host?.addChild(layer.container)
        addSystem(GameUILayer.systemName, stage: .update) { _ in layer.update() }
        return layer
    }

    /// Removes the game UI layer and everything on it.
    @MainActor public func removeGameUI() {
        if let old = GameUILayer.layer(for: self) {
            old.removeAll()
            old.container.removeFromParent()
        }
        GameUILayer.set(nil, for: self)
        removeSystem(named: GameUILayer.systemName)
    }

    /// The game UI layer, when one was added.
    @MainActor public var gameUI: GameUILayer? { GameUILayer.layer(for: self) }

    /// The layout of `entity`'s `UILayoutPlayer`.
    @MainActor public func uiLayout(for entity: Entity) -> UIBuildView? { gameUI?.view(for: entity) }
}

extension UIContext {
    /// A context for a game's UI over its scene (the game UI layer, a dialogue box): the game
    /// theme, with the arrow keys and a gamepad's D-pad moving focus between widgets.
    public static func gameUI(theme: UITheme = .game()) -> UIContext {
        let context = UIContext(theme: theme)
        context.directionalNavigation = true
        context.gamepadNavigation = UINavigationInput()
        return context
    }
}
