#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineRendering
import EngineScene
import EngineText
import EngineUI

// A `.ui` layout as the dialogue box, and a widget that shows whichever one a conversation asks for.
//
// `DialogueLayoutPresenter` drives a `UIBuildView` through the keys in `DialogueLayoutKeys`
// (speaker, text, portrait, choice1…9 and their flags) and answers its `continue` / `choice1`…
// buttons. `UIBuild.dialogue` (preset "dialogue" in the UI tab) is a layout to start from.
//
// `DialogueView` is the presenter to hand the dialogue system: it shows the default
// `DialogueBox`, or the layout the `DialoguePlayer` (or the dialogue file) names in `uiLayout`.
//
// ```swift
// let dialogue = DialogueView(assets: { assets })
// dialogue.useImages(renderer: sceneRenderer, assets: assets)   // portraits, layout images
// ui.root.addChild(dialogue)                                    // fills the screen; clicks
// world.dialogues?.presenter = dialogue                         // between panels reach the game
//
// // or one layout for every conversation:
// let presenter = DialogueLayoutPresenter(assets: assets, path: "UI/dialogue.ui")!
// ui.root.addChild(presenter)
// world.dialogues?.presenter = presenter
// ```

/// A `DialoguePresenter` that shows the conversation in a `.ui` layout (see DialogueLayout.swift
/// for the keys and events it uses).
@MainActor
public final class DialogueLayoutPresenter: Widget, DialoguePresenter {
    /// The layout shown (set more values on it, follow hot reload, look widgets up).
    public let view: UIBuildView
    /// The conversation shown (nil: none, or a state shown with `show`).
    public private(set) weak var runner: DialogueRunner?
    /// What is shown.
    public private(set) var state: DialogueRunner.State?
    /// Letters typed per second (0 shows each line at once).
    public var charactersPerSecond: Float = 45
    /// Hide the layout when nothing is shown (default true; previews keep it).
    public var hidesWhenIdle = true { didSet { show(state) } }
    /// Called after the player continues past a line or picks an option (after the runner moved on).
    public var onAdvance: (() -> Void)?
    public var onChoose: ((Int) -> Void)?

    private var fullText = ""
    private var typedCount = 0
    private var typingStart: Double?
    private var typing = false

    public init(_ view: UIBuildView, name: String = "dialogueLayout") {
        self.view = view
        super.init(name: name)
        isHitTestable = false
        addChild(view)
        view.on(DialogueLayoutKeys.continueEvent) { [unowned self] in continueOrComplete() }
        for n in 1...DialogueLayoutKeys.maxChoices {
            view.on(DialogueLayoutKeys.choice(n)) { [unowned self] in choose(n - 1) }
        }
        show(nil)
    }

    /// Shows `build` (default: the starter dialogue layout).
    public convenience init(_ build: UIBuild = .dialogue, name: String = "dialogueLayout") {
        self.init(UIBuildView(build), name: name)
    }

    /// Shows the `.ui` file at `path` (under `Assets/`, or "asset:<id>"), following hot reload.
    /// Nil when there is no such layout.
    public convenience init?(assets: AssetDatabase, path: String, name: String = "dialogueLayout") {
        guard let id = assets.assetID(forTableValue: path) else { return nil }
        let view = UIBuildView()
        guard view.follow(assets, asset: id) else { return nil }
        self.init(view, name: name)
    }

    /// Loads layout images and portraits through `renderer` (project textures by path or "asset:<id>").
    public func useImages(renderer: SceneRenderer, assets: AssetDatabase) { view.useImages(renderer: renderer, assets: assets) }

    public override var acceptsFocus: Bool { !isHidden && state.map(Self.isShowing) == true }
    public override var showsFocusRing: Bool { false }

    private static func isShowing(_ state: DialogueRunner.State) -> Bool {
        switch state {
        case .line, .choices: true
        case .idle, .finished: false
        }
    }

    // MARK: DialoguePresenter

    public func present(_ runner: DialogueRunner?) {
        self.runner = runner
        guard let runner, runner.isActive else {
            show(nil)
            return
        }
        show(runner.state)
    }

    /// Shows a state without a runner (previews, tests). Continuing and choosing then call
    /// `onAdvance` / `onChoose` only.
    public func show(_ state: DialogueRunner.State?) {
        let changed = state != self.state
        self.state = state
        var text = ""
        if case .line(let line)? = state { text = line.text }
        if changed || text != fullText {
            fullText = text
            typing = charactersPerSecond > 0 && !text.isEmpty
            typedCount = typing ? 0 : text.count
            typingStart = nil
        }
        view.set(DialogueLayoutKeys.values(for: state, text: shownText))
        isHidden = hidesWhenIdle && !(state.map(Self.isShowing) ?? false)
        setNeedsLayout()
    }

    private var shownText: String? {
        guard case .line? = state else { return nil }
        return typing ? String(fullText.prefix(typedCount)) : fullText
    }

    // MARK: Input

    /// Whether the whole line is shown.
    public var isTextComplete: Bool { !typing }

    /// Shows the whole line now.
    public func completeText() {
        guard typing else { return }
        typing = false
        typedCount = fullText.count
        view.set(DialogueLayoutKeys.text, fullText)
    }

    /// The `continue` button, a click on the layout, Enter or Space: finish typing the line, else continue.
    public func continueOrComplete() {
        guard case .line? = state else { return }
        if typing {
            completeText()
            return
        }
        runner?.advance()
        onAdvance?()
    }

    /// Picks the shown option at `index` (the `choice<index + 1>` button).
    public func choose(_ index: Int) {
        guard case .choices(let choices)? = state, choices.options.indices.contains(index) else { return }
        runner?.choose(index)
        onChoose?(index)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let pointer) where pointer.button == .left:
            // A click that landed on a panel of the layout (its buttons handle their own).
            guard case .line? = state else { return false }
            context?.focus(self)
            continueOrComplete()
            return true
        case .key(let key):
            switch key.key {
            case .enter, .space:
                guard case .line? = state else { return false }
                continueOrComplete()
                return true
            case .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9:
                let digits: [Key] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9]
                guard let i = digits.firstIndex(of: key.key), case .choices(let choices)? = state, choices.options.indices.contains(i)
                else { return false }
                choose(i)
                return true
            default:
                return false
            }
        default:
            return false
        }
    }

    // MARK: Widget

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        guard typing, let now = context?.time else { return }
        if typingStart == nil { typingStart = now }
        let count = min(fullText.count, Int(Float(now - typingStart!) * charactersPerSecond))
        if count >= fullText.count { typing = false }
        if count != typedCount || !typing {
            typedCount = count
            view.set(DialogueLayoutKeys.text, typing ? String(fullText.prefix(count)) : fullText)
            layout(in: frame)
        }
        if typing { setNeedsDisplay() }
    }
}

/// The presenter to give the dialogue system: the default `DialogueBox` at the bottom, or the
/// `.ui` layout a conversation names (`DialoguePlayer.uiLayout`, else the dialogue's `uiLayout`)
/// through a `DialogueLayoutPresenter`. It fills its frame and lets clicks outside the box reach
/// what is behind it (the game).
@MainActor
public final class DialogueView: Widget, DialoguePresenter {
    /// The default box (style it, or change `charactersPerSecond`).
    public let box: DialogueBox
    /// Where layouts load from.
    public var assets: () -> AssetDatabase?
    /// Loads textures by path (portraits and layout images); `useImages(renderer:assets:)` sets one.
    public var images: ((String) -> GPUTexture?)? {
        didSet {
            box.portraitTextures = images
            for presenter in layouts.values { presenter.view.images = images }
        }
    }
    /// The layout presenter now shown (nil: the box, or nothing).
    public private(set) var activeLayout: DialogueLayoutPresenter?
    /// The layout path the last conversation asked for ("" for the box).
    public private(set) var requestedLayout = ""
    /// Called with every layout presenter this view makes (to set `charactersPerSecond`, etc.).
    public var configureLayout: ((DialogueLayoutPresenter) -> Void)?
    /// Called after the player continues or picks an option, in the box or a layout.
    public var onInput: (() -> Void)?

    private var layouts: [String: DialogueLayoutPresenter] = [:]

    public init(assets: @escaping () -> AssetDatabase? = { nil }, box: DialogueBox = DialogueBox(name: "dialogueViewBox"),
                name: String = "dialogueView") {
        self.assets = assets
        self.box = box
        super.init(name: name)
        isHitTestable = false
        box.style.position = .absolute(UIAnchor.bottom.anchors(offset: Vec2(0, 16)))
        if box.style.width == nil { box.style.width = 560 }
        box.onAdvance = { [unowned self] in onInput?() }
        box.onChoose = { [unowned self] _ in onInput?() }
        addChild(box)
    }

    /// Loads portraits and layout images through `renderer` (project textures by path or "asset:<id>").
    public func useImages(renderer: SceneRenderer, assets: AssetDatabase) {
        images = DialoguePortraitView.textureLoader(renderer: renderer, assets: assets)
    }

    // MARK: DialoguePresenter

    public func present(_ runner: DialogueRunner?) { present(runner, layout: requestedLayout) }

    public func present(_ runner: DialogueRunner?, layout: String) {
        let path = layout.trimmingCharacters(in: .whitespaces)
        if runner != nil { requestedLayout = path }
        let presenter = path.isEmpty || runner == nil ? nil : layoutPresenter(for: path)
        if activeLayout !== presenter {
            activeLayout?.present(nil)
            activeLayout = presenter
        }
        if let presenter {
            box.present(nil)
            presenter.present(runner)
        } else {
            activeLayout?.present(nil)
            activeLayout = nil
            box.present(runner)
        }
        setNeedsLayout()
    }

    /// The presenter for the layout at `path`, made on first use; nil when there is no such layout
    /// (the box is used then).
    public func layoutPresenter(for path: String) -> DialogueLayoutPresenter? {
        if let made = layouts[path] { return made }
        guard let assets = assets(), let presenter = DialogueLayoutPresenter(assets: assets, path: path, name: "dialogueViewLayout") else {
            return nil
        }
        presenter.view.images = images
        presenter.onAdvance = { [unowned self] in onInput?() }
        presenter.onChoose = { [unowned self] _ in onInput?() }
        configureLayout?(presenter)
        layouts[path] = presenter
        insertChild(presenter, at: 0)
        return presenter
    }

    /// Forgets the layouts made so far (e.g. after the project changed).
    public func clearLayouts() {
        for presenter in layouts.values { presenter.removeFromParent() }
        layouts = [:]
        activeLayout = nil
    }
}
