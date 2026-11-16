import Foundation
import EngineAssets
import EngineCore
import EngineScene
import EngineUI

// Visual script nodes for UI layouts (`.ui` shown by a `UIBuildView`): show and hide layouts,
// set the values their bars and texts read, press buttons, and an event for button presses.
//
// Graphs name views. A view gets a name when a graph shows it (`ui.show`, which needs a layer
// from the host: the editor's Game view) or when game code hands one over:
//
// ```swift
// let hud = UIBuildView(assets: assets, path: "UI/hud.ui")!
// ui.root.addChild(hud)
// world.scriptUI(hud, name: "hud")      // graphs: ui.setValue {view: "hud", key: "health"}
// ```

/// The UI layouts the visual scripts of one runtime can reach, by name. Kept in the host's
/// `services` (`VisualScriptUI.service`).
@MainActor
public final class VisualScriptUI {
    /// The `VisualScriptHost.services` key of the registry.
    public static let service = "engine.ui"
    /// The `VisualScriptHost.services` key of the widget `ui.show` adds layouts to.
    public static let layerService = "engine.ui.layer"

    private struct Entry {
        weak var view: UIBuildView?
        /// Shown by `ui.show` (removed again with `ui.hide` or when play stops).
        var owned: Bool
        /// Takes an owned view off where `ui.show` put it (default: its parent).
        var detach: (() -> Void)?
    }
    private var entries: [String: Entry] = [:]
    var pressed: [(view: String, event: UIBuildEvent)] = []

    init() {}

    /// The registry of `runtime` (made on first use).
    static func of(_ runtime: VisualScriptRuntime) -> VisualScriptUI {
        if let existing = runtime.host.services[service] as? VisualScriptUI { return existing }
        let registry = VisualScriptUI()
        runtime.host.services[service] = registry
        runtime.onDetach { [weak registry] in registry?.removeOwned() }
        return registry
    }

    /// Names `view` for graphs and forwards its button presses to them (its `onEvent` handler
    /// keeps working: it is called first).
    func add(_ view: UIBuildView, name: String, owned: Bool = false, detach: (() -> Void)? = nil) {
        if let old = entries[name], old.view !== view, old.owned { Self.detach(old) }
        entries[name] = Entry(view: view, owned: owned, detach: detach)
        let previous = view.onEvent
        view.onEvent = { [weak self] event in
            previous?(event)
            self?.pressed.append((name, event))
        }
    }

    func view(_ name: String) -> UIBuildView? { entries[name]?.view }

    /// Every live view, by name (sorted).
    var views: [(name: String, view: UIBuildView)] {
        entries.keys.sorted().compactMap { name in entries[name]?.view.map { (name, $0) } }
    }

    func remove(_ name: String) {
        guard let entry = entries.removeValue(forKey: name) else { return }
        if entry.owned { Self.detach(entry) }
    }

    func removeOwned() {
        for (name, entry) in entries where entry.owned {
            Self.detach(entry)
            entries[name] = nil
        }
    }

    private static func detach(_ entry: Entry) {
        if let detach = entry.detach { detach() } else { entry.view?.removeFromParent() }
    }

    /// The names graphs can use.
    public var names: [String] { views.map(\.name) }
}

extension VisualScriptRuntime {
    /// Lets graphs reach `view` as `name` (`ui.setValue`, `ui.getValue`, `ui.press`) and hear its
    /// button presses (`event.uiButton`).
    public func addUI(_ view: UIBuildView, name: String) {
        VisualScriptUI.of(self).add(view, name: name)
    }

    /// The layouts graphs can reach.
    public var scriptUI: VisualScriptUI { VisualScriptUI.of(self) }
}

extension World {
    /// Lets this world's visual scripts reach `view` as `name`. Returns false when no visual
    /// scripts run here.
    @MainActor @discardableResult
    public func scriptUI(_ view: UIBuildView, name: String) -> Bool {
        guard let runtime = VisualScriptRuntime.runtime(for: self) else { return false }
        runtime.addUI(view, name: name)
        return true
    }
}

@MainActor
enum VisualScriptUINodes {
    static func register() {
        VisualScriptNodes.addProvider("engine.ui") {
            for definition in definitions() { VisualScriptNodes.register(definition) }
        }
    }

    static func views(_ c: VisualScriptNodeContext) throws -> [UIBuildView] {
        let registry = VisualScriptUI.of(c.runtime)
        let name = try c.string("view").trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return registry.views.map(\.view) }
        guard let view = registry.view(name) else { throw VisualScriptError("no UI layout named '\(name)' (show it with ui.show, or world.scriptUI in Swift)") }
        return [view]
    }

    static func definitions() -> [VisualScriptNodeDefinition] {
        typealias S = VisualScriptEngineSupport
        let view = VisualScriptPin("view", .string, doc: "The layout's name (empty: every layout shown)")
        return [
            S.action("ui.show", "Show UI Layout", "UI",
                     "Shows the .ui layout `layout` over the game as `name` (default: the file's name), following edits to the file. Needs a game UI layer: the game's (`world.gameUI`: the editor's Game view, GameRunner and exported games), or game code adding layouts with world.scriptUI.",
                     [VisualScriptPin("layout", .asset, required: true, doc: "A .ui file: asset:<id> or a path under Assets/"),
                      VisualScriptPin("name", .string)], [VisualScriptPin("view", .string)]) { c in
                guard let assets = c.host.assets() else { throw VisualScriptError("no asset database to load the layout from") }
                let value = try c.string("layout")
                guard let id = assets.assetID(forScriptValue: value) else { throw VisualScriptError("no layout '\(value)'") }
                var name = try c.string("name").trimmingCharacters(in: .whitespaces)
                if name.isEmpty { name = ((assets.path(of: id) ?? value) as NSString).lastPathComponent.split(separator: ".").first.map(String.init) ?? "layout" }
                let registry = VisualScriptUI.of(c.runtime)
                if registry.view(name) == nil {
                    let gameUI = c.world.gameUI
                    let layer = c.host.services[VisualScriptUI.layerService] as? Widget
                    guard gameUI != nil || layer != nil else {
                        throw VisualScriptError("nowhere to show UI: this host has no game UI layer (game code can add layouts with world.scriptUI)")
                    }
                    let shown = UIBuildView(name: "vscriptUI.\(name)")
                    guard shown.follow(assets, asset: id) else { throw VisualScriptError("'\(value)' isn't a .ui layout") }
                    shown.style.position = .absolute(.fill())
                    if let gameUI {
                        gameUI.add(shown)
                        registry.add(shown, name: name, owned: true) { [weak gameUI, weak shown] in
                            if let shown { gameUI?.remove(shown) }
                        }
                    } else {
                        layer?.addChild(shown)
                        registry.add(shown, name: name, owned: true)
                    }
                }
                c.set("view", .string(name))
                return .next
            },
            S.action("ui.hide", "Hide UI Layout", "UI", "Removes the layout `view` that a graph showed (layouts game code added just stop being reachable).",
                     [VisualScriptPin("view", .string, required: true)]) { c in
                VisualScriptUI.of(c.runtime).remove(try c.string("view"))
                return .next
            },
            S.action("ui.setValue", "Set UI Value", "UI",
                     "Sets the value `key` of layout `view`: bars, `{key}` text, bindings and visibleWhen read it. Numbers, bools and text.",
                     [view, VisualScriptPin("key", .string, required: true), VisualScriptPin("value", .any)]) { c in
                let key = try c.string("key")
                let value = try c.input("value")
                let json: JSONValue = switch value {
                case .bool(let b): .bool(b)
                case .int(let i): .int(Int64(i))
                case .float(let f): .double(f)
                case .none: .null
                default: .string(value.asString)
                }
                for target in try views(c) { json == .null ? target.clear(key) : target.set(key, json) }
                return .next
            },
            S.pure("ui.getValue", "Get UI Value", "UI", "The value `key` of layout `view` (set by code, else the file's sample).",
                   [VisualScriptPin("view", .string, required: true), VisualScriptPin("key", .string, required: true)],
                   [VisualScriptPin("value", .any), VisualScriptPin("found", .bool)]) { c in
                let found = try views(c).first?.value(try c.string("key"))
                c.set("value", found.map(VisualScriptValue.fromJSON) ?? .none)
                c.set("found", .bool(found != nil))
            },
            S.action("ui.press", "Press UI Button", "UI", "Presses the button `button` (its id) of layout `view` as if clicked; `pressed` is false when it isn't there or is disabled.",
                     [VisualScriptPin("view", .string, required: true), VisualScriptPin("button", .string, required: true)],
                     [VisualScriptPin("pressed", .bool)]) { c in
                let button = try c.string("button")
                c.set("pressed", .bool(try views(c).first?.press(button) ?? false))
                return .next
            },
            VisualScriptNodeDefinition(
                id: "event.uiButton", title: "On UI Button", category: "Events",
                doc: "Runs when a button of a layout graphs can reach is pressed (config view and event; empty: any). `event` is the button's event name, `button` its id.",
                kind: .event, config: [VisualScriptConfigKey("view", doc: "The layout's name (empty: any)"),
                                       VisualScriptConfigKey("event", doc: "The button's event name (empty: any)")],
                event: "uiButton", outputs: [VisualScriptPin("event", .string), VisualScriptPin("button", .string), VisualScriptPin("view", .string)],
                run: nil),
        ]
    }

    static func addEventSource(to runtime: VisualScriptRuntime) {
        runtime.addEventSource("engine.ui") { runtime in
            guard let registry = runtime.host.services[VisualScriptUI.service] as? VisualScriptUI, !registry.pressed.isEmpty else { return }
            let pressed = registry.pressed
            registry.pressed.removeAll()
            for (view, event) in pressed {
                for instance in runtime.instances.values.sorted(by: { $0.entity.index < $1.entity.index }) where instance.program.handles("uiButton") {
                    runtime.raise("uiButton", on: instance, outputs: ["event": .string(event.name), "button": .string(event.widget), "view": .string(view)]) { node in
                        VisualScriptEngineSupport.nameMatches(node.source, view, key: "view") && VisualScriptEngineSupport.nameMatches(node.source, event.name, key: "event")
                    }
                }
            }
        }
    }
}
