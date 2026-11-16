import Foundation
import EngineAssets
import EngineBackends
import EngineCore
import EngineGraphics
import EngineRendering
import EngineScene
import EngineText
import EngineUI

// Shows a `.ui` layout (UI / HUD Builder) with the engine's widgets, fills its text and bars
// from values game code sets, and reports button presses.
//
// ```swift
// let hud = UIBuildView(assets: assets, path: "UI/hud.ui")!    // follows hot reload
// hud.useImages(renderer: sceneRenderer, assets: assets)
// ui.root.addChild(hud)                                         // fills the window
// hud.set("health", 64)                                         // bars, "{health}" text
// hud.set("score", 1200)
// hud.on("pause") { openPauseMenu() }                           // a button's event
// ```
//
// The view fills its frame like a HUD layer and lets clicks between widgets reach the game.
// Its widgets use the layout's theme (base preset + colors), whatever the context's theme is.

/// A button press (or a slider, toggle or text field change) in a `UIBuildView`.
public struct UIBuildEvent: Equatable, Sendable {
    /// The event name (the widget's `event`, or its id).
    public var name: String
    /// The id of the widget that sent it.
    public var widget: String
    /// The widget's new value (a slider's number, a toggle's bool, a text field's text); nil for a button.
    public var value: JSONValue?
    /// The value key the widget is bound to (`bind`), which now holds `value`; nil when unbound.
    public var key: String?

    public init(name: String, widget: String, value: JSONValue? = nil, key: String? = nil) {
        self.name = name
        self.widget = widget
        self.value = value
        self.key = key
    }
}

/// A widget that shows a `UIBuild` (a `.ui` file). See the notes at the top of UIBuildView.swift.
@MainActor
public final class UIBuildView: Widget {
    /// The layout shown.
    public private(set) var build: UIBuild
    /// Values game code set (they win over the file's sample `values`).
    public private(set) var values: [String: JSONValue] = [:]
    /// Called for every button press (after the handlers registered with `on`).
    public var onEvent: ((UIBuildEvent) -> Void)?
    /// Loads a project image by the path a widget names (path under `Assets/` or "asset:<id>").
    /// `useImages(renderer:assets:)` sets one that uses a `SceneRenderer`.
    public var images: ((String) -> GPUTexture?)? { didSet { setNeedsLayout() } }
    /// Draw a box with the file name for images that can't be loaded (the editor's preview).
    public var showsPlaceholders = false { didSet { setNeedsDisplay() } }
    /// Use the file's sample `values` for keys code hasn't set (default true).
    public var usesSampleValues = true { didSet { applyValues() } }
    /// The factor the layout is scaled by for the view's size (its `scaleMode` from its design
    /// `size`; 1 with `none`). Widgets are laid out at the scaled sizes, so clicks and focus match.
    public private(set) var layoutScale: Float = 1

    private var handlers: [String: [() -> Void]] = [:]
    private let screen = UIBuildPanel(name: "uiBuildScreen")
    private var entries: [(spec: UIBuildWidget, widget: Widget)] = []
    private var byID: [String: Widget] = [:]
    private var idsByWidget: [ObjectIdentifier: String] = [:]
    private weak var followedAssets: AssetDatabase?
    private var followedAsset: AssetID?
    private var followedRevision = -1

    public init(_ build: UIBuild = UIBuild(), name: String = "uiBuild") {
        self.build = build
        super.init(name: name)
        isHitTestable = false
        screen.isHitTestable = false
        addChild(screen)
        rebuild()
    }

    /// A view of the `.ui` file at `path` (relative to `Assets/`) that reloads when the file is
    /// reimported (hot reload while playing). Nil if there is no such layout.
    public convenience init?(assets: AssetDatabase, path: String, name: String = "uiBuild") {
        guard let id = assets.id(forPath: path.hasPrefix("Assets/") ? String(path.dropFirst(7)) : path),
              let loaded = assets.uiBuildForGame(id) else { return nil }
        self.init(loaded.build, name: name)
        followedAssets = assets
        followedAsset = id
        followedRevision = loaded.revision
    }

    // MARK: Loading

    /// Shows `build` instead (values set by code stay).
    public func load(_ build: UIBuild) {
        self.build = build
        rebuild()
    }

    /// Follows the `.ui` asset `id`: reloads it whenever it is reimported. Returns false if it isn't one.
    @discardableResult
    public func follow(_ assets: AssetDatabase, asset id: AssetID) -> Bool {
        guard let loaded = assets.uiBuildForGame(id) else { return false }
        followedAssets = assets
        followedAsset = id
        followedRevision = loaded.revision
        load(loaded.build)
        return true
    }

    /// Reloads the followed file if it was reimported since; returns whether it did. Called
    /// while painting, so a game needn't call it.
    @discardableResult
    public func reloadIfChanged() -> Bool {
        guard let assets = followedAssets, let id = followedAsset, assets.pack == nil else { return false }
        let revision = assets.revision(of: id)
        guard revision != followedRevision else { return false }
        followedRevision = revision
        guard let loaded = assets.uiBuildForGame(id) else { return false }
        followedRevision = loaded.revision
        load(loaded.build)
        return true
    }

    /// Loads images through `renderer` (project textures by path or "asset:<id>").
    public func useImages(renderer: SceneRenderer, assets: AssetDatabase) {
        images = Self.imageLoader(renderer: renderer, assets: assets)
    }

    /// An `images` loader that draws project textures (by path or "asset:<id>") through `renderer`.
    public static func imageLoader(renderer: SceneRenderer, assets: AssetDatabase) -> (String) -> GPUTexture? {
        { [weak renderer, weak assets] path in
            guard let renderer, let assets, let id = assets.assetID(forTableValue: path) else { return nil }
            return renderer.texture(TextureHandle(AssetReference(id).description))
        }
    }

    // MARK: Values

    /// Sets a value widgets read (bars, `{key}` text, `bind`, `visibleWhen`).
    public func set(_ key: String, _ value: JSONValue) {
        guard values[key] != value else { return }
        values[key] = value
        applyValues()
    }

    public func set(_ key: String, _ value: Double) { set(key, .double(value)) }
    public func set(_ key: String, _ value: Float) { set(key, .double(Double(value))) }
    public func set(_ key: String, _ value: Int) { set(key, .int(Int64(value))) }
    public func set(_ key: String, _ value: String) { set(key, .string(value)) }
    public func set(_ key: String, _ value: Bool) { set(key, .bool(value)) }

    /// Sets several values at once.
    public func set(_ newValues: [String: JSONValue]) {
        for (key, value) in newValues { values[key] = value }
        applyValues()
    }

    /// Forgets a value set by code (the file's sample value shows again).
    public func clear(_ key: String) {
        guard values.removeValue(forKey: key) != nil else { return }
        applyValues()
    }

    /// The value widgets see for `key`: code's, else the file's sample.
    public func value(_ key: String) -> JSONValue? { effectiveValues[key] }

    /// Code's values over the file's samples.
    public var effectiveValues: [String: JSONValue] {
        usesSampleValues ? build.values.merging(values) { _, set in set } : values
    }

    // MARK: Events

    /// Runs `handler` whenever a button sends `event`.
    public func on(_ event: String, _ handler: @escaping () -> Void) {
        handlers[event, default: []].append(handler)
    }

    /// Removes the handlers for `event`.
    public func removeHandlers(for event: String) { handlers[event] = nil }

    /// Presses the button `id` as if clicked (tests, scripted tutorials). Returns false if there is no such button.
    @discardableResult
    public func press(_ id: String) -> Bool {
        guard let spec = build.widget(id), spec.type == .button, let button = byID[id] as? Button, button.isEffectivelyEnabled,
              button.isEffectivelyVisible else { return false }
        send(spec)
        return true
    }

    /// Changes the input `id` (slider: a number, toggle: a bool, text field: a string) as if the
    /// player did (tests, scripted tutorials): writes its bound key and sends its event. Returns
    /// false if there is no such input or the value is of the wrong kind.
    @discardableResult
    public func change(_ id: String, to value: JSONValue) -> Bool {
        guard let spec = build.widget(id), spec.type.isInput, let widget = byID[id], widget.isEffectivelyEnabled,
              widget.isEffectivelyVisible else { return false }
        switch (widget, value) {
        case (let slider as Slider, _):
            guard let number = UIBuild.number(value) else { return false }
            slider.setValue(Float(number))
            inputChanged(id, to: .double(Double(slider.value)), sends: true)
        case (let toggle as Checkbox, .bool(let on)):
            toggle.isOn = on
            inputChanged(id, to: .bool(on), sends: true)
        case (let field as TextField, .string(let text)):
            field.text = text
            inputChanged(id, to: .string(field.text), sends: true)
        default:
            return false
        }
        return true
    }

    /// The player changed input `id`: its bound key takes the value (text and bars reading it
    /// follow), then it sends its event when `sends`.
    private func inputChanged(_ id: String, to value: JSONValue, sends: Bool) {
        guard let spec = build.widget(id) else { return }
        if !spec.bind.isEmpty, values[spec.bind] != value {
            values[spec.bind] = value
            applyValues()
        }
        if sends { send(spec, value: value) }
    }

    private func send(_ spec: UIBuildWidget, value: JSONValue? = nil) {
        let event = UIBuildEvent(name: spec.eventName, widget: spec.id, value: value, key: value == nil || spec.bind.isEmpty ? nil : spec.bind)
        for handler in handlers[event.name] ?? [] { handler() }
        onEvent?(event)
        layerHandler?(event)
    }

    /// The game UI layer's hook (`GameUILayer`), called after `onEvent`.
    var layerHandler: ((UIBuildEvent) -> Void)?

    // MARK: Showing and focus

    /// Whether the view is shown (`show`) rather than hidden (`hide`), even while a transition plays.
    public private(set) var isShown = true

    /// Shows the view, playing the layout's `show` transition when it was hidden (or hiding)
    /// and `animated`. Outside a `UIContext` it shows at once.
    public func show(animated: Bool = true) {
        if isShown, !isHidden { return }
        let wasHidden = isHidden, wasHiding = viewFade?.showing == false
        isShown = true
        isHidden = false
        viewFade = nil
        lastTime = nil
        if animated, wasHidden || wasHiding, let t = build.show, t.animates, context != nil {
            viewFade = Fade(transition: t, showing: true)
            applyPose(self, base: 1, t, shown: 0)
            setNeedsDisplay()
        } else {
            applyPose(self, base: 1, nil, shown: 1)
        }
    }

    /// Hides the view after the layout's `hide` transition (when `animated`; at once outside a
    /// `UIContext`), then calls `completion`. While it hides, clicks pass through it.
    public func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        let wasShown = isShown
        isShown = false
        if animated, wasShown, !isHidden, let t = build.hide, t.animates, context != nil {
            viewFade = Fade(transition: t, showing: false, completion: completion)
            lastTime = nil
            setNeedsDisplay()
            return
        }
        viewFade = nil
        isHidden = true
        applyPose(self, base: 1, nil, shown: 1)
        completion?()
    }

    // MARK: Animation

    /// A show or hide transition in progress.
    private struct Fade {
        var transition: UIBuildTransition
        var showing: Bool
        var elapsed: Double = 0
        var completion: (() -> Void)?

        /// 0 hidden … 1 shown, eased.
        var shown: Float {
            let t = transition
            let raw = t.duration > 0 ? Float((elapsed - Double(t.delay)) / Double(t.duration)) : (elapsed >= Double(t.delay) ? 1 : 0)
            let eased = t.easing(raw)
            return showing ? eased : 1 - eased
        }
        var isDone: Bool { elapsed >= Double(transition.delay + transition.duration) }
    }

    /// A number moving to a new value (`tween`).
    private struct Tween {
        var from: Double
        var to: Double
        var elapsed: Double = 0
        var duration: Double
        var integral: Bool

        var current: Double { from + (to - from) * Double(Easing.quadOut(Float(min(elapsed / duration, 1)))) }
        var value: JSONValue { integral ? .int(Int64(current.rounded())) : .double(current) }
    }

    private var viewFade: Fade?
    private var widgetFades: [String: Fade] = [:]
    /// Whether each widget should show (its `hidden` / `visibleWhen`), while `isHidden` lags during a hide transition.
    private var widgetVisible: [String: Bool] = [:]
    private var tweens: [String: Tween] = [:]
    private var lastValues: [String: JSONValue] = [:]
    private var lastTime: Double?

    /// Whether a show / hide transition or value tween is playing.
    public var isAnimating: Bool { viewFade != nil || !widgetFades.isEmpty || !tweens.isEmpty }

    /// Moves transitions and tweens on by `dt` seconds. Drawing in a `UIContext` calls it with
    /// the context's time, so a game needn't.
    public func advance(by dt: Double) {
        guard dt > 0, isAnimating else { return }
        if var fade = viewFade {
            fade.elapsed += dt
            if fade.isDone {
                viewFade = nil
                if !fade.showing { isHidden = true }
                applyPose(self, base: 1, nil, shown: 1)
                fade.completion?()
            } else {
                viewFade = fade
                applyPose(self, base: 1, fade.transition, shown: fade.shown)
            }
        }
        for (id, var fade) in widgetFades {
            guard let widget = byID[id], let spec = entries.first(where: { $0.widget === widget })?.spec else {
                widgetFades[id] = nil
                continue
            }
            fade.elapsed += dt
            if fade.isDone {
                widgetFades[id] = nil
                widget.isHidden = !fade.showing
                applyPose(widget, base: spec.opacity, nil, shown: 1)
            } else {
                widgetFades[id] = fade
                applyPose(widget, base: spec.opacity, fade.transition, shown: fade.shown)
            }
        }
        if !tweens.isEmpty {
            for (key, var tween) in tweens {
                tween.elapsed += dt
                tweens[key] = tween.elapsed >= tween.duration ? nil : tween
            }
            applyValues()
        }
    }

    /// Sets a widget's (or the view's) opacity, offset and scale for a transition at `shown`
    /// (nil transition: at rest). Scales about the widget's center; slides scale with the layout.
    private func applyPose(_ widget: Widget, base: Float, _ transition: UIBuildTransition?, shown: Float) {
        let base = min(max(base, 0), 1)
        guard let transition else {
            widget.opacity = base
            widget.visualScale = 1
            widget.visualOffset = .zero
            return
        }
        let pose = transition.pose(shown: shown)
        widget.opacity = base * pose.opacity
        widget.visualScale = max(pose.scale, 0.001)
        widget.visualOffset = pose.offset * layoutScale + Vec2(widget.frame.width, widget.frame.height) * ((1 - pose.scale) / 2)
    }

    /// Shows or hides a layout widget, with its transition once the view is in a context.
    private func setVisible(_ spec: UIBuildWidget, _ widget: Widget, _ visible: Bool) {
        let old = widgetVisible[spec.id]
        widgetVisible[spec.id] = visible
        guard let old, old != visible else {
            if old == nil { widget.isHidden = !visible }
            return
        }
        if let t = visible ? spec.show : spec.hide, t.animates, context != nil {
            widgetFades[spec.id] = Fade(transition: t, showing: visible)
            widget.isHidden = false
            applyPose(widget, base: spec.opacity, t, shown: visible ? 0 : 1)
            setNeedsDisplay()
        } else {
            widgetFades[spec.id] = nil
            widget.isHidden = !visible
            applyPose(widget, base: spec.opacity, nil, shown: 1)
        }
    }

    /// Starts tweens for numbers that changed and that a widget with a `tween` shows.
    private func startTweens(_ values: [String: JSONValue]) {
        var durations: [String: Double] = [:]
        for (spec, _) in entries where spec.tween > 0 {
            for key in spec.valueKeys { durations[key] = max(durations[key] ?? 0, Double(spec.tween)) }
        }
        for (key, duration) in durations {
            guard let newValue = values[key], let new = UIBuild.number(newValue) else {
                tweens[key] = nil
                continue
            }
            guard let oldValue = lastValues[key], let old = UIBuild.number(oldValue), old != new else { continue }
            if tweens[key]?.to == new { continue }
            guard context != nil else {
                tweens[key] = nil
                continue
            }
            let from = tweens[key]?.current ?? old
            tweens[key] = Tween(from: from, to: new, duration: duration,
                                integral: Self.isIntegral(newValue) && Self.isIntegral(oldValue))
            setNeedsDisplay()
        }
    }

    private static func isIntegral(_ value: JSONValue) -> Bool {
        switch value {
        case .int: true
        case .double(let d): d == d.rounded()
        default: false
        }
    }

    /// `values` with tweening numbers at their current point.
    private func tweenedValues(_ values: [String: JSONValue]) -> [String: JSONValue] {
        var shown = values
        for (key, tween) in tweens { shown[key] = tween.value }
        return shown
    }

    public override func hitTest(_ point: Vec2) -> Widget? {
        isShown ? super.hitTest(point) : nil
    }

    /// Focus the start widget the next time the view is drawn in a context.
    var wantsFocus = false

    /// Gives keyboard / gamepad focus to the layout's first focusable widget (a menu's first
    /// button). Returns false when there is none or the view isn't in a `UIContext` yet (it then
    /// focuses when it is next drawn).
    @discardableResult
    public func focusStartWidget() -> Bool {
        wantsFocus = true
        guard let context, isEffectivelyVisible, let start = startWidget() else { return false }
        wantsFocus = false
        context.focus(start, visible: true)
        return true
    }

    /// The widget focus starts at: the first focusable widget in file order.
    func startWidget() -> Widget? {
        for (_, widget) in entries where widget.acceptsFocus && widget.isEffectivelyVisible && widget.isEffectivelyEnabled {
            return widget
        }
        return nil
    }

    // MARK: Lookup

    /// The engine widget showing the layout's widget `id` (a `Label`, `IconLabel`, `Button`,
    /// `ProgressBar`, `Stack`, panel or image), for tweaks the file can't express.
    public func widget(_ id: String) -> Widget? { byID[id] }

    /// The layout id of `widget` or its nearest ancestor that has one (nil: none, or the screen).
    public func layoutID(of widget: Widget) -> String? {
        var current: Widget? = widget
        while let w = current, w !== self {
            if let id = idsByWidget[ObjectIdentifier(w)] { return id }
            current = w.parent
        }
        return nil
    }

    // MARK: Building

    private func rebuild() {
        let theme = build.makeTheme().uiBuildScaled(by: layoutScale)
        let s = layoutScale
        widgetFades = [:]
        widgetVisible = [:]
        tweens = [:]
        screen.removeAllChildren()
        entries = []
        byID = [:]
        idsByWidget = [:]
        var styles = theme.styles
        var made: [String: Widget] = [:]
        for original in build.widgets where !original.id.isEmpty && made[original.id] == nil {
            let spec = s == 1 ? original : original.scaled(by: s)
            let widget = makeWidget(spec, theme: theme, styles: &styles)
            made[spec.id] = widget
            entries.append((spec, widget))
            byID[spec.id] = widget
            idsByWidget[ObjectIdentifier(widget)] = spec.id
        }
        var finalTheme = theme
        finalTheme.styles = styles
        themeOverride = finalTheme
        screen.padding = EdgeInsets((build.safeArea ?? 0) * s)
        if build.safeArea == nil { screen.padding = finalTheme.hudSafeArea }
        // Hang each widget from its (effective) parent, in file order.
        for (spec, widget) in entries {
            let parentID = build.effectiveParent(of: spec)
            let parent = parentID.isEmpty ? screen : (made[parentID] ?? screen)
            if let panel = parent as? UIBuildPanel { panel.place(widget, anchor: spec.anchor, offset: spec.offset) }
            parent.addChild(widget)
        }
        applyValues()
        setNeedsLayout()
    }

    private func makeWidget(_ spec: UIBuildWidget, theme: UITheme, styles: inout [String: UIWidgetStyle]) -> Widget {
        let styleClass = "uiBuild." + spec.id
        let textColor = theme.uiBuildColor(spec.color)
        let fontSize: Float? = spec.fontSize > 0 ? spec.fontSize : nil
        let widget: Widget
        switch spec.type {
        case .panel:
            let panel = UIBuildPanel(name: spec.id)
            panel.isHitTestable = !spec.background.isEmpty
            widget = panel
        case .vstack, .hstack:
            let axis: Axis = spec.type == .vstack ? .vertical : .horizontal
            let alignment: CrossAlignment = switch spec.align {
            case .auto: axis == .vertical ? .stretch : .center
            case .start: .start
            case .center: .center
            case .end: .end
            case .stretch: .stretch
            }
            let stack = Stack(axis, spacing: spec.spacing, alignment: alignment, name: spec.id)
            stack.justify = switch spec.justify {
            case .start: .start
            case .center: .center
            case .end: .end
            case .spaceBetween: .spaceBetween
            }
            stack.isHitTestable = !spec.background.isEmpty
            widget = stack
        case .label:
            if spec.shadow {
                let label = IconLabel(spec.text, fontSize: fontSize, name: spec.id)
                label.color = textColor
                widget = label
            } else {
                let label = Label(spec.text, name: spec.id)
                label.color = textColor
                label.fontSize = fontSize
                label.wraps = spec.wrap
                label.alignment = switch spec.textAlign {
                case .left: .left
                case .center: .center
                case .right: .right
                }
                label.isHitTestable = false
                widget = label
            }
        case .image:
            let image = UIBuildImage(spec.image, fit: spec.fit, owner: self, name: spec.id)
            image.tint = textColor ?? .white
            widget = image
        case .button:
            let button = Button(spec.text, role: spec.primary ? .primary : .normal, name: spec.id)
            button.action = { [unowned self] in
                if let current = build.widget(spec.id) { send(current) }
            }
            var style = UIWidgetStyle()
            style.background = theme.uiBuildColor(spec.background)
            style.borderColor = theme.uiBuildColor(spec.borderColor)
            style.textColor = textColor
            style.fontSize = fontSize
            if spec.cornerRadius > 0 { style.cornerRadius = spec.cornerRadius }
            if spec.primary, let background = style.background { style.accent = background }
            if let height = spec.height { style.height = height }
            styles[styleClass] = style
            button.styleClass = styleClass
            widget = button
        case .bar:
            let bar = ProgressBar(value: 0, kind: spec.kind == .health ? .health : .progress, name: spec.id)
            bar.fillColor = textColor
            bar.segments = spec.segments
            bar.showsTrail = spec.trail
            var style = UIWidgetStyle()
            style.background = theme.uiBuildColor(spec.background)
            style.borderColor = theme.uiBuildColor(spec.borderColor)
            if spec.cornerRadius > 0 { style.cornerRadius = spec.cornerRadius }
            if let height = spec.height { style.height = height }
            styles[styleClass] = style
            bar.styleClass = styleClass
            widget = bar
        case .spacer:
            widget = Spacer(grow: spec.grow > 0 ? spec.grow : 1)
            widget.name = spec.id
        case .slider:
            let upper = spec.max > spec.min ? spec.max : spec.min + 1
            let slider = Slider(value: spec.value, in: spec.min...upper, step: max(spec.step, 0), name: spec.id)
            slider.onChange = { [unowned self] value in inputChanged(spec.id, to: .double(Double(value)), sends: true) }
            if spec.width == nil { slider.style.minWidth = 160 * layoutScale }
            widget = slider
        case .toggle:
            let toggle = Checkbox(spec.text, isOn: spec.on, kind: spec.toggleStyle == .switch ? .toggleSwitch : .checkbox, name: spec.id)
            toggle.onChange = { [unowned self] on in inputChanged(spec.id, to: .bool(on), sends: true) }
            if textColor != nil || fontSize != nil {
                var style = UIWidgetStyle()
                style.textColor = textColor
                style.fontSize = fontSize
                styles[styleClass] = style
                toggle.styleClass = styleClass
            }
            widget = toggle
        case .textField:
            let field = TextField(text: spec.text, placeholder: spec.placeholder, name: spec.id)
            field.maxLength = spec.maxLength > 0 ? spec.maxLength : nil
            field.preferredWidth = 160 * layoutScale
            // The bound key follows every edit; Enter sends the event.
            field.onChange = { [unowned self] text in inputChanged(spec.id, to: .string(text), sends: false) }
            field.onSubmit = { [unowned self] text in inputChanged(spec.id, to: .string(text), sends: true) }
            if textColor != nil || fontSize != nil || spec.height != nil {
                var style = UIWidgetStyle()
                style.textColor = textColor
                style.fontSize = fontSize
                if let height = spec.height { style.height = height }
                styles[styleClass] = style
                field.styleClass = styleClass
            }
            widget = field
        }
        if spec.type != .button && spec.type != .bar {
            widget.background = theme.uiBuildColor(spec.background)
            widget.borderColor = theme.uiBuildColor(spec.borderColor)
            widget.cornerRadius = spec.cornerRadius
        }
        if spec.type.isContainer { widget.padding = EdgeInsets(spec.padding) }
        widget.style.width = spec.width
        widget.style.height = spec.height
        if spec.type != .spacer { widget.style.grow = spec.grow }
        widget.opacity = min(max(spec.opacity, 0), 1)
        return widget
    }

    /// Fills text, bars, images and visibility from the current values.
    private func applyValues() {
        let raw = effectiveValues
        startTweens(raw)
        let tweened = tweens.isEmpty ? raw : tweenedValues(raw)
        lastValues = raw
        for (spec, widget) in entries {
            setVisible(spec, widget, !spec.hidden && UIBuild.isVisible(spec.visibleWhen, values: raw))
            let values = spec.tween > 0 ? tweened : raw
            switch spec.type {
            case .label:
                let text = Self.text(of: spec, values: values)
                if let label = widget as? Label { label.text = text } else if let label = widget as? IconLabel { label.text = text }
            case .button:
                (widget as? Button)?.title = Self.text(of: spec, values: values)
            case .bar:
                guard let bar = widget as? ProgressBar else { continue }
                let raw = spec.bind.isEmpty ? Double(spec.value) : UIBuild.number(values[spec.bind]) ?? 0
                bar.value = spec.max > 0 ? Float(raw / Double(spec.max)) : 0
                bar.text = spec.text.isEmpty ? nil : UIBuild.fill(spec.text, values: values)
            case .image:
                guard let image = widget as? UIBuildImage else { continue }
                if !spec.bind.isEmpty, case .string(let path)? = values[spec.bind] { image.path = path } else { image.path = spec.image }
            case .slider:
                if !spec.bind.isEmpty, let number = UIBuild.number(values[spec.bind]) { (widget as? Slider)?.setValue(Float(number)) }
            case .toggle:
                guard let toggle = widget as? Checkbox else { continue }
                toggle.title = UIBuild.fill(spec.text, values: values)
                if !spec.bind.isEmpty, values[spec.bind] != nil { toggle.isOn = UIBuild.truthy(values[spec.bind]) }
            case .textField:
                guard let field = widget as? TextField, !spec.bind.isEmpty, let value = values[spec.bind] else { continue }
                let text = UIBuild.display(value)
                if field.text != text { field.text = text }
            default: break
            }
        }
    }

    /// A label's or button's text: its `{key}` placeholders filled, else the bound value, else the text as written.
    static func text(of spec: UIBuildWidget, values: [String: JSONValue]) -> String {
        if !UIBuild.placeholders(in: spec.text).isEmpty { return UIBuild.fill(spec.text, values: values) }
        if !spec.bind.isEmpty { return values[spec.bind].map(UIBuild.display) ?? spec.text }
        return spec.text
    }

    // MARK: Widget

    public override func measureContent(width: Float?) -> Vec2 { build.size }

    public override func layoutChildren() {
        let factor = build.scaleMode.factor(screen: Vec2(frame.width, frame.height), design: build.size)
        let wanted = factor.isFinite && factor > 0 ? min(max(factor, 0.05), 20) : 1
        if abs(wanted - layoutScale) > 0.0005 {
            // Keep focus on the same layout widget across the rebuild (a menu while the window resizes).
            let focused = context?.focusedWidget.flatMap { $0.isDescendant(of: self) ? layoutID(of: $0) : nil }
            layoutScale = wanted
            rebuild()
            if let focused, let widget = byID[focused], widget.acceptsFocus { context?.focus(widget, visible: true) }
        }
        super.layoutChildren()
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        if let context {
            if let last = lastTime { advance(by: context.time - last) }
            lastTime = isAnimating ? context.time : nil
            if isAnimating { setNeedsDisplay() }
        }
        if reloadIfChanged() { layout(in: frame) }
        if wantsFocus { focusStartWidget() }
        super.draw(list, theme: theme)
    }
}

/// A box that places its children by anchor and offset (the screen and `panel` widgets).
@MainActor
final class UIBuildPanel: Widget {
    private var placements: [ObjectIdentifier: (anchor: UIBuildAnchor, offset: Vec2)] = [:]

    func place(_ child: Widget, anchor: UIBuildAnchor, offset: Vec2) {
        placements[ObjectIdentifier(child)] = (anchor, offset)
        setNeedsLayout()
    }

    private func placement(of child: Widget) -> (anchor: UIBuildAnchor, offset: Vec2) {
        placements[ObjectIdentifier(child)] ?? (.topLeft, .zero)
    }

    override func measureContent(width: Float?) -> Vec2 {
        var size = Vec2.zero
        for child in children where !child.isHidden {
            let (anchor, offset) = placement(of: child)
            let measured = anchor == .fill ? Vec2.zero : child.measure(width: child.style.width)
            let ox = anchor == .fill ? 2 * offset.x : abs(offset.x)
            let oy = anchor == .fill ? 2 * offset.y : abs(offset.y)
            size = Vec2(max(size.x, measured.x + ox), max(size.y, measured.y + oy))
        }
        return size
    }

    override func layoutChildren() {
        let content = contentRect
        for child in children where !child.isHidden {
            child.layout(in: Self.frame(for: child, placement: placement(of: child), in: content))
        }
    }

    static func frame(for child: Widget, placement: (anchor: UIBuildAnchor, offset: Vec2), in content: UIRect) -> UIRect {
        let (anchor, offset) = placement
        if anchor == .fill {
            return UIRect(x: content.x + offset.x, y: content.y + offset.y, width: max(0, content.width - 2 * offset.x),
                          height: max(0, content.height - 2 * offset.y))
        }
        let size = child.measure(width: child.style.width)
        let x: Float, y: Float
        switch anchor {
        case .topLeft, .left, .bottomLeft: x = content.x + offset.x
        case .topRight, .right, .bottomRight: x = content.maxX - offset.x - size.x
        default: x = content.x + (content.width - size.x) / 2 + offset.x
        }
        switch anchor {
        case .topLeft, .top, .topRight: y = content.y + offset.y
        case .bottomLeft, .bottom, .bottomRight: y = content.maxY - offset.y - size.y
        default: y = content.y + (content.height - size.y) / 2 + offset.y
        }
        return UIRect(x: x, y: y, width: size.x, height: size.y)
    }
}

/// A project image in a `UIBuildView`, loaded through the view's `images`.
@MainActor
final class UIBuildImage: Widget {
    var path: String { didSet { if path != oldValue { setNeedsLayout() } } }
    var fit: UIBuildImageFit
    var tint = UIColor.white
    private unowned let owner: UIBuildView

    init(_ path: String, fit: UIBuildImageFit, owner: UIBuildView, name: String) {
        self.path = path
        self.fit = fit
        self.owner = owner
        super.init(name: name)
        isHitTestable = false
    }

    private var texture: GPUTexture? { path.isEmpty ? nil : owner.images?(path) }

    override func measureContent(width: Float?) -> Vec2 {
        let s = owner.layoutScale
        guard let texture else { return Vec2(64, 64) * s }
        let size = Vec2(Float(texture.width), Float(texture.height)) * s
        // Scale down to the proposed width, keeping the aspect.
        if let width, width > 0, size.x > width { return Vec2(width, size.y * width / size.x) }
        return size
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let box = contentRect
        guard let texture else {
            if owner.showsPlaceholders {
                list.fillRect(box, color: theme.controlBackground)
                list.strokeRect(box, color: theme.controlBorder)
                let name = (path as NSString).lastPathComponent
                list.drawText(name.isEmpty ? "image" : name, at: Vec2(box.x + 4, box.y + 4), size: theme.smallFontSize,
                              color: theme.secondaryTextColor)
            }
            return
        }
        let w = Float(max(texture.width, 1)), h = Float(max(texture.height, 1))
        switch fit {
        case .stretch:
            list.drawImage(texture, in: box, tint: tint)
        case .fit:
            let s = min(box.width / w, box.height / h)
            let rect = UIRect(x: box.x + (box.width - w * s) / 2, y: box.y + (box.height - h * s) / 2, width: w * s, height: h * s)
            list.drawImage(texture, in: rect, tint: tint)
        case .fill:
            let s = max(box.width / w, box.height / h)
            let uw = box.width / (w * s), uh = box.height / (h * s)
            list.drawImage(texture, in: box, uv: UIRect(x: (1 - uw) / 2, y: (1 - uh) / 2, width: uw, height: uh), tint: tint)
        }
    }
}

extension UIBuildWidget {
    /// This widget with its sizes in points (offset, width, height, padding, spacing, corner
    /// radius, font size) multiplied by `factor`, for a layout scaled to the screen.
    func scaled(by factor: Float) -> UIBuildWidget {
        var w = self
        w.offset = offset * factor
        w.width = width.map { $0 * factor }
        w.height = height.map { $0 * factor }
        w.padding = padding * factor
        w.spacing = spacing * factor
        w.cornerRadius = cornerRadius * factor
        w.fontSize = fontSize * factor
        return w
    }
}

extension UITheme {
    /// This theme with its sizes (text, controls, spacing, corners, safe area) multiplied by
    /// `factor`, for a `.ui` layout scaled to the screen. Colors and timings stay.
    func uiBuildScaled(by factor: Float) -> UITheme {
        guard factor != 1 else { return self }
        var t = self
        for path: WritableKeyPath<UITheme, Float> in [
            \.fontSize, \.smallFontSize, \.headingFontSize, \.spacing, \.panelPadding, \.controlHeight, \.controlPaddingX,
            \.cornerRadius, \.smallCornerRadius, \.rowCornerRadius, \.popupCornerRadius, \.dialogCornerRadius, \.iconSize,
            \.rowHeight, \.treeIndent, \.minimumHitSize, \.checkboxSize, \.sliderTrackHeight, \.sliderThumbSize,
            \.scrollbarWidth, \.dialogPadding, \.dialogSpacing, \.buttonSpacing, \.dialogMaxWidth, \.progressBarHeight,
            \.tooltipFontSize, \.tooltipMaxWidth,
        ] {
            t[keyPath: path] *= factor
        }
        t.hudSafeArea = EdgeInsets(top: hudSafeArea.top * factor, left: hudSafeArea.left * factor,
                                   bottom: hudSafeArea.bottom * factor, right: hudSafeArea.right * factor)
        t.tooltipPadding = tooltipPadding * factor
        for (name, var style) in styles {
            style.fontSize = style.fontSize.map { $0 * factor }
            style.height = style.height.map { $0 * factor }
            style.paddingX = style.paddingX.map { $0 * factor }
            style.cornerRadius = style.cornerRadius.map { $0 * factor }
            t.styles[name] = style
        }
        return t
    }
}

@MainActor
extension UIBuild {
    /// The layout's theme: the base preset with its colors and font size applied.
    public func makeTheme() -> UITheme {
        var t: UITheme = switch theme {
        case "dark": .dark()
        case "light": .light()
        case "highContrast": .highContrast()
        default: .game()
        }
        if fontSize > 0 {
            let ratio = fontSize / t.fontSize
            t.fontSize = fontSize
            t.smallFontSize = (t.smallFontSize * ratio).rounded()
            t.headingFontSize = (t.headingFontSize * ratio).rounded()
        }
        for (name, text) in colors {
            guard let c = UIBuild.hexColor(text) else { continue }
            let color = UIColor(c.x, c.y, c.z, c.w)
            switch name {
            case "text": t.textColor = color
            case "secondaryText": t.secondaryTextColor = color
            case "accent":
                t.accent = color
                t.accentHover = color.mixed(with: .white, 0.15)
                t.accentPressed = color.mixed(with: .black, 0.15)
                t.focusRing = color.mixed(with: .white, 0.3)
            case "accentText": t.accentText = color
            case "panel": t.panelBackground = color
            case "panelBorder": t.panelBorder = color
            case "control": t.controlBackground = color
            case "controlHover": t.controlHover = color
            case "barBackground": t.barBackground = color
            case "health": t.healthColor = color
            case "warning": t.warningColor = color
            case "danger": t.dangerColor = color
            case "hudText": t.hudTextColor = color
            case "hudShadow": t.hudTextShadow = color
            default: break
            }
        }
        return t
    }
}

@MainActor
extension UITheme {
    /// A `.ui` color: "#RRGGBB[AA]" or a theme color name; nil for "" or anything unknown.
    public func uiBuildColor(_ text: String) -> UIColor? {
        if text.isEmpty { return nil }
        if let c = UIBuild.hexColor(text) { return UIColor(c.x, c.y, c.z, c.w) }
        switch text {
        case "text": return textColor
        case "secondaryText": return secondaryTextColor
        case "accent": return accent
        case "accentText": return accentText
        case "panel": return panelBackground
        case "panelBorder": return panelBorder
        case "control": return controlBackground
        case "controlHover": return controlHover
        case "barBackground": return barBackground
        case "health": return healthColor
        case "warning": return warningColor
        case "danger": return dangerColor
        case "hudText": return hudTextColor
        case "hudShadow": return hudTextShadow
        default: return nil
        }
    }
}
