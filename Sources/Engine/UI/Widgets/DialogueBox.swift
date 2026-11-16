import Foundation
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene
import EngineText
import EngineUI

// The default dialogue UI: a panel with the speaker's portrait and name, the line typed out
// letter by letter, and the options as buttons. It is a `DialoguePresenter`, so it is swapped
// for any other presenter (a `.ui` layout, a game's own UI) by setting `DialogueDirector.presenter`.
//
// ```swift
// let box = DialogueBox()
// hud.add(box, at: .bottom)                 // or ui.root.addChild(box) with your own layout
// world.dialogues?.presenter = box
// ```
//
// Input: click, Enter or Space shows the whole line, then continues; options are clicked or
// picked with the number keys 1-9.

/// The default `DialoguePresenter`: portrait, speaker name, typed-out text and option buttons.
@MainActor
public final class DialogueBox: Widget, DialoguePresenter {
    /// The conversation shown (nil: the box is hidden).
    public private(set) weak var runner: DialogueRunner?
    /// Letters typed per second (0 shows each line at once).
    public var charactersPerSecond: Float = 45
    /// The image for a speaker's portrait, when code wants to choose it; nil (or a nil result)
    /// loads the speaker's `portrait` texture through `portraitTextures`, else draws the initial
    /// in the speaker's color.
    public var portraitImage: ((DialogueSpeaker) -> UIIcon?)?
    /// Loads a portrait texture by the path a speaker names (under `Assets/` or "asset:<id>");
    /// asked again while it draws until it answers, so textures still loading show up.
    /// `usePortraits(renderer:assets:)` sets one that uses a `SceneRenderer`.
    public var portraitTextures: ((String) -> GPUTexture?)? {
        get { portrait.textures }
        set { portrait.textures = newValue }
    }
    /// Hide the box when nothing is shown (default true; the editor preview keeps it).
    public var hidesWhenIdle = true
    /// The text shown below a line ("" for none).
    public var continueHint = "Click or press Enter to continue"

    public let portrait = DialoguePortraitView()
    public let nameLabel = Label("", role: .secondary, name: "dialogueSpeaker")
    public let textView = DialogueTextView()
    public let optionsStack = VStack(spacing: 4, alignment: .stretch, name: "dialogueOptions")
    public let hintLabel = Label("", role: .caption, name: "dialogueHint")
    /// The option buttons now shown.
    public private(set) var optionButtons: [Button] = []

    public override init(name: String = "dialogueBox") {
        super.init(name: name)
        padding = EdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        cornerRadius = 10
        style.minWidth = 320
        textView.style.grow = 0
        let column = VStack(spacing: 6, alignment: .stretch, name: "dialogueColumn", [nameLabel, textView, optionsStack, hintLabel])
        column.style.grow = 1
        column.style.shrink = 1
        let row = HStack(spacing: 12, alignment: .start, name: "dialogueRow", [portrait, column])
        addChild(row)
        isHidden = true
    }

    public override var acceptsFocus: Bool { true }
    public override var showsFocusRing: Bool { false }

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
        optionsStack.removeAllChildren()
        optionButtons = []
        switch state {
        case .line(let line)?:
            isHidden = false
            setSpeaker(line.speaker, id: line.speakerID)
            textView.setText(line.text, animated: charactersPerSecond > 0, charactersPerSecond: charactersPerSecond)
            textView.isHidden = false
            hintLabel.text = continueHint
            hintLabel.isHidden = continueHint.isEmpty
        case .choices(let choices)?:
            isHidden = false
            setSpeaker(choices.speaker, id: choices.speakerID)
            textView.setText(choices.prompt, animated: false, charactersPerSecond: 0)
            textView.isHidden = choices.prompt.isEmpty
            hintLabel.isHidden = true
            for option in choices.options {
                let label = option.index < 9 ? "\(option.index + 1). \(option.text)" : option.text
                let button = Button(label, name: "dialogueOption.\(option.index)") { [unowned self] in choose(option.index) }
                optionButtons.append(button)
                optionsStack.addChild(button)
            }
        case .idle?, .finished?, nil:
            setSpeaker(nil, id: "")
            textView.setText("", animated: false, charactersPerSecond: 0)
            hintLabel.isHidden = true
            isHidden = hidesWhenIdle
        }
        setNeedsLayout()
    }

    /// Called after the player continues past a line or picks an option (after the runner moved on).
    public var onAdvance: (() -> Void)?
    public var onChoose: ((Int) -> Void)?

    private func setSpeaker(_ speaker: DialogueSpeaker?, id: String) {
        let name = speaker?.displayName ?? id
        nameLabel.text = name
        nameLabel.isHidden = name.isEmpty
        nameLabel.color = speaker?.parsedColor.map { UIColor($0.x, $0.y, $0.z, $0.w) }
        portrait.speaker = speaker ?? (id.isEmpty ? nil : DialogueSpeaker(id: id))
        portrait.image = speaker.flatMap { portraitImage?($0) }
        portrait.isHidden = portrait.speaker == nil
    }

    /// Loads speakers' `portrait` textures through `renderer` (project textures by path or "asset:<id>").
    public func usePortraits(renderer: SceneRenderer, assets: AssetDatabase) {
        portraitTextures = DialoguePortraitView.textureLoader(renderer: renderer, assets: assets)
    }

    // MARK: Input

    /// Click / Enter / Space: finish typing the line, else continue.
    public func continueOrComplete() {
        if !textView.isComplete {
            textView.complete()
            return
        }
        guard optionButtons.isEmpty else { return }
        runner?.advance()
        onAdvance?()
    }

    /// Picks the shown option at `index`.
    public func choose(_ index: Int) {
        guard optionButtons.indices.contains(index) else { return }
        runner?.choose(index)
        onChoose?(index)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let pointer) where pointer.button == .left:
            context?.focus(self)
            continueOrComplete()
            return true
        case .key(let key):
            switch key.key {
            case .enter, .space:
                continueOrComplete()
                return true
            case .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9:
                let digits: [Key] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9]
                if let i = digits.firstIndex(of: key.key), optionButtons.indices.contains(i) { choose(i); return true }
                return false
            default:
                return false
            }
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let style = theme.style(for: self)
        list.fillRect(frame, color: background ?? style.background ?? theme.panelBackground.withAlpha(0.94), radii: UICornerRadii(cornerRadius))
        list.strokeRect(frame, color: borderColor ?? style.borderColor ?? theme.textColor.withAlpha(0.18), width: borderWidth,
                        radii: UICornerRadii(cornerRadius))
    }
}

/// The text of a line, typed out over time.
@MainActor
public final class DialogueTextView: Widget {
    public private(set) var text = ""
    public var fontSize: Float? { didSet { setNeedsLayout() } }
    private var startTime: Double?
    private var charactersPerSecond: Float = 0
    private var completed = true
    private var cachedLayout: (text: String, width: Float, size: Float, layout: TextLayout)?

    public override init(name: String = "dialogueText") {
        super.init(name: name)
        isHitTestable = false
    }

    public override var accessibilityRole: UIAccessibilityRole { .label }
    public override var accessibilityText: String? { text }

    /// Shows `text`, typed out at `charactersPerSecond` when `animated`.
    public func setText(_ text: String, animated: Bool, charactersPerSecond: Float) {
        self.text = text
        self.charactersPerSecond = charactersPerSecond
        completed = !animated || charactersPerSecond <= 0 || text.isEmpty
        startTime = nil
        setNeedsLayout()
    }

    /// Whether the whole line is shown.
    public var isComplete: Bool {
        if completed { return true }
        guard let start = startTime, let now = context?.time else { return false }
        return revealed(at: now, start: start) >= glyphCount
    }

    /// Shows the whole line now.
    public func complete() {
        completed = true
        setNeedsDisplay()
    }

    private var glyphCount: Int { cachedLayout?.layout.glyphs.count ?? text.count }

    private func revealed(at now: Double, start: Double) -> Int { Int(Float(now - start) * charactersPerSecond) }

    private func layout(width: Float, theme: UITheme) -> TextLayout {
        let size = fontSize ?? theme.fontSize * 1.15
        if let cached = cachedLayout, cached.text == text, cached.width == width, cached.size == size { return cached.layout }
        let layout = TextLayout(text, font: theme.font, size: size, maxWidth: max(width, 40))
        cachedLayout = (text, width, size, layout)
        return layout
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let layout = layout(width: width ?? 480, theme: theme)
        return Vec2(min(layout.width, width ?? layout.width), layout.height)
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let rect = contentRect
        let layout = layout(width: rect.width, theme: theme)
        var count = layout.glyphs.count
        if !completed, let now = context?.time {
            if startTime == nil { startTime = now }
            count = min(count, revealed(at: now, start: startTime!))
            if count >= layout.glyphs.count { completed = true } else { setNeedsDisplay() }
        }
        guard count > 0 else { return }
        list.drawText(layout, font: theme.font, at: Vec2(rect.x, rect.y), color: theme.style(for: self).textColor ?? theme.textColor,
                      glyphs: 0..<count)
    }
}

/// A speaker's portrait: an image when given, else the speaker's `portrait` texture (through
/// `textures`), else the speaker's initial in a colored circle.
@MainActor
public final class DialoguePortraitView: Widget {
    public var speaker: DialogueSpeaker? { didSet { setNeedsDisplay() } }
    public var image: UIIcon? { didSet { setNeedsDisplay() } }
    public var size: Float = 64 { didSet { setNeedsLayout() } }
    /// Loads the speaker's `portrait` by path (nil: portraits come only from `image`).
    public var textures: ((String) -> GPUTexture?)? { didSet { setNeedsDisplay() } }

    public override init(name: String = "dialoguePortrait") {
        super.init(name: name)
        isHitTestable = false
    }

    /// A loader for `textures` that reads project textures through `renderer`.
    public static func textureLoader(renderer: SceneRenderer, assets: AssetDatabase) -> (String) -> GPUTexture? {
        { [weak renderer, weak assets] path in
            guard let renderer, let assets, let id = assets.assetID(forTableValue: path) else { return nil }
            return renderer.texture(TextureHandle(AssetReference(id).description))
        }
    }

    /// What is drawn: `image`, else the loaded `portrait` texture, else nil (the initial).
    public var shownImage: UIIcon? {
        if let image { return image }
        guard let path = speaker?.portrait, !path.isEmpty, let texture = textures?(path) else { return nil }
        return .image(texture)
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(size, size) }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let rect = UIRect(x: frame.x, y: frame.y, width: size, height: size)
        let tint = speaker?.parsedColor.map { UIColor($0.x, $0.y, $0.z, 1) } ?? theme.accent
        switch shownImage {
        case .image(let texture, var uv, let color)?:
            // A non-square texture is cropped to its middle square rather than squashed.
            if uv == .unit, texture.width != texture.height, texture.width > 0, texture.height > 0 {
                let w = Float(texture.width), h = Float(texture.height)
                uv = w > h ? UIRect(x: (1 - h / w) / 2, y: 0, width: h / w, height: 1) : UIRect(x: 0, y: (1 - w / h) / 2, width: 1, height: w / h)
            }
            list.drawImage(texture, in: rect, uv: uv, tint: color)
        case .custom(let draw)?:
            draw(list, rect, tint)
        case nil:
            list.fillRect(rect, color: tint.withAlpha(0.85), radii: UICornerRadii(size / 2))
            let initial = String((speaker?.displayName ?? "?").prefix(1)).uppercased()
            let layout = TextLayout(initial, font: theme.font, size: size * 0.45)
            list.drawText(layout, font: theme.font, at: Vec2(rect.x + (size - layout.width) / 2, rect.y + (size - layout.height) / 2),
                          color: .white)
        }
    }
}
