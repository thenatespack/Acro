import Engine
import Foundation

// The Sound Builder: the editor tab for a `.sfx` file. The sound is drawn as a waveform; Play
// (or Auto-play, on by default) plays it through the editor's audio output. The sidebar has the
// presets (jump, coin, laser, explosion, hit, power-up, blip) with Randomize and Mutate, and a
// property grid with every synth parameter. Every change is written to the file as one undo
// step (`EditorSession.applySoundBuild`), which reimports it; Ctrl+Z takes it back.

/// The proxy component for the parameters grid: encodes and decodes as `SoundBuild`.
struct SoundBuildComponent: Component {
    static var componentName: String { "Sound" }
    static var fieldHints: [String: FieldHints] { SoundBuild.fieldHints }

    var build: SoundBuild

    init(build: SoundBuild) { self.build = build }
    init(from decoder: any Decoder) throws { build = try SoundBuild(from: decoder) }
    func encode(to encoder: any Encoder) throws { try build.encode(to: encoder) }
}

/// Draws a sound's loudness over time: mirrored bars around a center line, with the length in seconds.
@MainActor
public final class SFXWaveformView: Widget {
    /// Peak magnitudes (0...1) from start to end.
    public var peaks: [Float] = [] { didSet { setNeedsDisplay() } }
    public var duration: Float = 0 { didSet { setNeedsDisplay() } }

    public override init(name: String = "sfxWaveform") {
        super.init(name: name)
        isHitTestable = false
    }

    public override func measureContent(width: Float?) -> Vec2 { Vec2(240, 140) }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let rect = contentRect
        guard rect.width > 4, rect.height > 4 else { return }
        list.fillRect(rect, color: UIColor(0.07, 0.08, 0.1, 1), radii: UICornerRadii(4))
        let mid = rect.y + rect.height / 2
        list.drawLine(from: Vec2(rect.x, mid), to: Vec2(rect.x + rect.width, mid), width: 1, color: UIColor(1, 1, 1, 0.15))
        guard !peaks.isEmpty else { return }
        let columns = max(Int(rect.width / 3), 1)
        let half = rect.height / 2 - 6
        for c in 0..<columns {
            let lo = c * peaks.count / columns
            let hi = min(max((c + 1) * peaks.count / columns, lo + 1), peaks.count)
            let peak = peaks[lo..<hi].max() ?? 0
            let x = rect.x + (Float(c) + 0.5) * rect.width / Float(columns)
            let h = max(peak * half, 0.5)
            list.drawLine(from: Vec2(x, mid - h), to: Vec2(x, mid + h), width: max(rect.width / Float(columns) - 1, 1), color: theme.accent)
        }
        list.drawText(String(format: "%.2f s", duration), at: Vec2(rect.x + 8, rect.y + 6), size: 11,
                      color: theme.secondaryTextColor)
    }
}

/// Edits one `.sfx` file: presets, Randomize, Mutate and the parameters grid.
@MainActor
public final class SoundBuilderView {
    public let session: EditorSession
    public let asset: AssetID
    public let view: VStack
    public private(set) var build: SoundBuild
    public private(set) var grid: PropertyGrid?
    /// Called after the form wrote an edit to the file (the workspace plays the sound).
    public var onCommitted: (() -> Void)?
    private let world = World()
    private var entity: Entity?
    private var pending: (build: SoundBuild, label: String)?
    /// The preset Randomize varies, per sound.
    private static var presets: [AssetID: SFXPreset] = [:]

    public var preset: SFXPreset {
        get { Self.presets[asset] ?? .blip }
        set { Self.presets[asset] = newValue }
    }

    public init?(session: EditorSession, asset: AssetID) {
        guard session.isSoundBuildFile(asset), let build = session.assets?.soundBuild(of: asset) else { return nil }
        self.session = session
        self.asset = asset
        self.build = build
        view = VStack(spacing: 6, name: "soundBuilder")
        layout()
    }

    /// Call every frame: applies the pending edit and keeps the grid in step with its proxy.
    public func refresh() {
        if let pending {
            self.pending = nil
            commit(pending.build, label: pending.label)
        }
        grid?.refresh()
    }

    public var hasPendingEdit: Bool { pending != nil }

    /// Rereads the file (after an undo or an edit from elsewhere) and lays the form out again.
    public func reload() {
        guard pending == nil, let build = session.assets?.soundBuild(of: asset) else { return }
        self.build = build
        layout()
    }

    // MARK: Layout

    static func title(_ preset: SFXPreset) -> String {
        switch preset {
        case .powerUp: "Power-up"
        default: preset.rawValue.capitalized
        }
    }

    private func layout() {
        view.removeAllChildren()
        view.addChild(Label("Presets", role: .secondary))
        let presets = HStack(spacing: 4, name: "soundPresets")
        presets.wraps = true
        for preset in SFXPreset.allCases {
            let button = Button(Self.title(preset), role: preset == self.preset ? .primary : .normal, name: "soundPreset.\(preset.rawValue)") {
                [unowned self] in applyPreset(preset)
            }
            button.command = SoundBuildEditCommand.id.rawValue
            button.tooltip = "Replace the parameters with a typical \(Self.title(preset).lowercased()) sound"
            presets.addChild(button)
        }
        view.addChild(presets)
        let randomize = Button("Randomize", name: "soundRandomize") { [unowned self] in
            var edited = SoundBuild.preset(preset, seed: Int.random(in: 1...999_999))
            edited.volume = build.volume
            apply(edited, label: "Randomize Sound")
        }
        randomize.command = SoundBuildEditCommand.id.rawValue
        randomize.tooltip = "A new random variation of the chosen preset"
        let mutate = Button("Mutate", name: "soundMutate") { [unowned self] in
            apply(build.mutated(amount: 0.2, seed: Int.random(in: 1...999_999)), label: "Mutate Sound")
        }
        mutate.command = SoundBuildEditCommand.id.rawValue
        mutate.tooltip = "Nudge every parameter a little"
        view.addChild(HStack(spacing: 6, [randomize, mutate, Spacer()]))
        view.addChild(Separator())
        addGrid()
        let note = Label("Every change is saved to the file. Use the sound by setting an AudioEmitter's clip to it.", role: .caption,
                         name: "soundBuildNote")
        note.wraps = true
        view.addChild(note)
    }

    private func addGrid() {
        if let entity { world.despawn(entity) }
        let entity = world.spawn(SoundBuildComponent(build: build))
        self.entity = entity
        let grid = PropertyGrid(world: world, name: "soundBuildGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 120
        grid.entity = entity
        grid.command = SoundBuildEditCommand.id.rawValue
        grid.stringChoices = { _, path in path == "waveform" ? SFXWaveform.allCases.map(\.rawValue) : nil }
        grid.onFieldEdit = { [unowned self] edit in
            do { try world.setField(edit.path, of: SoundBuildComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Sound \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let edited = world.get(SoundBuildComponent.self, for: entity)?.build {
                pending = (edited, "Edit Sound")
            }
        }
        self.grid = grid
        view.addChild(grid)
    }

    // MARK: Edits

    func applyPreset(_ preset: SFXPreset) {
        self.preset = preset
        var edited = SoundBuild.preset(preset)
        edited.seed = build.seed
        apply(edited, label: "\(Self.title(preset)) Preset")
    }

    private func apply(_ edited: SoundBuild, label: String) { pending = (edited, label) }

    private func commit(_ edited: SoundBuild, label: String) {
        guard session.applySoundBuild(edited, to: asset, label: label) != nil else { return }
        build = session.assets?.soundBuild(of: asset) ?? edited
        layout()
        onCommitted?()
    }
}

/// The Sound Builder tab for one `.sfx` file.
@MainActor
public final class SoundBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The sound being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var builder: SoundBuilderView?
    public let waveform = SFXWaveformView()
    /// Whether an edit made in the form plays the sound.
    public var autoPlay = true

    private let title = Label("Sound Builder", role: .heading, name: "soundBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "soundBuilderSidebar")
    private let autoPlayToggle = Checkbox("Auto-play", kind: .toggleSwitch, name: "soundBuilderAutoPlay")
    private let playButton: Button
    private var shownRevision = -1

    public init(session: EditorSession) {
        self.session = session
        playButton = Button("Play", role: .primary, name: "soundBuilderPlay")
        view = VStack(spacing: 0, name: "soundBuilderWorkspace")
        layOutChrome()
        showEmpty()
    }

    /// Shows `id` (a `.sfx` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isSoundBuildFile(id), let builder = SoundBuilderView(session: session, asset: id) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            builder.onCommitted = { [unowned self] in if autoPlay { play() } }
            shownRevision = -1
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Sound Builder"
        title.icon = EditorIcons.asset(.audio)
        playButton.isEnabled = true
        updateWaveform()
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        showEmpty()
    }

    /// Plays the open sound through the editor's audio output; false if nothing is open or there is no audio device.
    @discardableResult
    public func play() -> Bool {
        guard let build = builder?.build else { return false }
        return SoundBuildPreview.play(build, in: session)
    }

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "soundBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        playButton.action = { [unowned self] in _ = play() }
        playButton.command = SoundBuildPlayCommand.id.rawValue
        playButton.tooltip = "Play the sound"
        bar.addChild(playButton)
        autoPlayToggle.isOn = autoPlay
        autoPlayToggle.onChange = { [unowned self] on in autoPlay = on }
        autoPlayToggle.tooltip = "Play the sound after each change"
        bar.addChild(autoPlayToggle)
        let close = Button("Close", name: "soundBuilderClose") { [unowned self] in close() }
        close.tooltip = "Stop editing this sound"
        bar.addChild(close)

        waveform.style.grow = 1
        waveform.style.shrink = 1
        waveform.padding = EdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let scroll = ScrollView(sidebar, name: "soundBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "soundBuilderBody", [waveform, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Sound Builder"
        title.icon = EditorIcons.asset(.audio)
        playButton.isEnabled = false
        waveform.peaks = []
        waveform.duration = 0
        sidebar.removeAllChildren()
        let note = Label("Double-click a .sfx file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Sound (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Sound", role: .primary, name: "soundBuilderNew") { [unowned self] in
            if let id = session.run(SoundBuildNewCommand.self, .init())?.asset { session.run(SoundBuildOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = SoundBuildNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
    }

    /// Applies the form's pending edit and follows changes to the file (undo, MCP, other panels). Call every frame.
    public func update() {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            shownRevision = revision
            updateWaveform()
        }
    }

    private func updateWaveform() {
        guard let build = builder?.build else { return }
        let samples = build.render()
        waveform.peaks = build.peaks(count: 512, of: samples)
        waveform.duration = Float(samples.count) / Float(max(build.sampleRate, 1))
    }
}
