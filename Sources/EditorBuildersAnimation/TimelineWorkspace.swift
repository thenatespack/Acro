import EditorCore
import Engine
import Foundation

// The Timeline tab: a preview of the open scene posed by one `.timeline` file, tabbed with the
// Scene view, with transport (Play / Pause, Stop, Loop), a track strip to scrub, select and drag
// keys, and the `TimelineBuilderView` form beside it.
//
// The preview plays in a copy of the scene (refreshed when the scene changes and the preview
// isn't playing) through the engine's own `TimelinePlayer` system, so what you see is what the
// game does: camera moves and cuts, transforms, animation clips, sounds (while playing),
// effects, the screen fade and conversations (in a dialogue box over the preview: click it to
// continue). Seen through the timeline's camera (Camera View) or a free orbit camera. The file is
// the truth: every edit is one undo step and the preview follows it.

/// Draws a timeline's tracks as rows of key markers under a time ruler with the playhead.
/// Click or drag in the ruler or a row to scrub, click a key to select it, drag it to move it
/// (one edit on release), double-click a row to add a key there.
@MainActor
public final class TimelineStripView: Widget {
    public var tracks: [TimelineTrack] = [] { didSet { if tracks != oldValue { setNeedsLayout() } } }
    public var duration: Float = 10 { didSet { setNeedsDisplay() } }
    public var playhead: Float = 0 { didSet { if playhead != oldValue { setNeedsDisplay() } } }
    public var selectedTrack: String? { didSet { setNeedsDisplay() } }
    public var selectedKey: Int? { didSet { setNeedsDisplay() } }
    public var onScrub: ((Float) -> Void)?
    public var onSelect: ((String, Int?) -> Void)?
    public var onMoveKey: ((String, Int, Float) -> Void)?
    public var onAddKey: ((String, Float) -> Void)?

    static let headerWidth: Float = 120
    static let rulerHeight: Float = 20
    static let rowHeight: Float = 22
    private enum Drag { case scrub, key(track: String, index: Int, time: Float, moved: Bool) }
    private var drag: Drag?

    public override init(name: String = "timelineStrip") {
        super.init(name: name)
    }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(320, Self.rulerHeight + Float(max(tracks.count, 1)) * Self.rowHeight + 4)
    }

    var lane: UIRect {
        let r = contentRect
        return UIRect(x: r.x + Self.headerWidth, y: r.y, width: max(r.width - Self.headerWidth - 8, 1), height: r.height)
    }

    func x(of time: Float) -> Float { lane.x + time / max(duration, 0.0001) * lane.width }
    func time(at x: Float) -> Float { min(max((x - lane.x) / lane.width * duration, 0), duration) }
    func row(at y: Float) -> Int? {
        let i = Int(((y - contentRect.y - Self.rulerHeight) / Self.rowHeight).rounded(.down))
        return y >= contentRect.y + Self.rulerHeight && tracks.indices.contains(i) ? i : nil
    }
    func rowY(_ i: Int) -> Float { contentRect.y + Self.rulerHeight + Float(i) * Self.rowHeight }

    /// The key under `point` (within 6 points), if any.
    func key(at point: Vec2) -> (track: Int, key: Int)? {
        guard let r = row(at: point.y) else { return nil }
        var best: (Int, Float)?
        for (k, key) in tracks[r].keys.enumerated() {
            let d = abs(x(of: key.time) - point.x)
            if d <= 6, d < (best?.1 ?? .infinity) { best = (k, d) }
        }
        return best.map { (r, $0.0) }
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            let p = e.position
            if p.x < lane.x - 4 {
                if let r = row(at: p.y) { onSelect?(tracks[r].id, nil) }
                return true
            }
            if let hit = key(at: p) {
                let track = tracks[hit.track]
                onSelect?(track.id, hit.key)
                drag = .key(track: track.id, index: hit.key, time: track.keys[hit.key].time, moved: false)
                return true
            }
            if e.clickCount >= 2, let r = row(at: p.y) {
                onAddKey?(tracks[r].id, time(at: p.x))
                return true
            }
            drag = .scrub
            onScrub?(time(at: p.x))
            return true
        case .pointerDrag(let e):
            switch drag {
            case .scrub: onScrub?(time(at: e.position.x))
            case .key(let track, let index, _, _):
                // Snap to 0.05 s.
                let t = (time(at: e.position.x) * 20).rounded() / 20
                drag = .key(track: track, index: index, time: t, moved: true)
                setNeedsDisplay()
            case nil: return false
            }
            return true
        case .pointerUp:
            if case .key(let track, let index, let t, true) = drag { onMoveKey?(track, index, t) }
            drag = nil
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        super.draw(list, theme: theme)
        let r = contentRect
        guard r.width > Self.headerWidth + 10, r.height > Self.rulerHeight else { return }
        list.fillRect(r, color: UIColor(0.07, 0.08, 0.1, 1), radii: UICornerRadii(4))
        let lane = self.lane
        list.withClip(r) {
            // Ruler: a tick per second (or per 5 / 10 s on long timelines).
            let step: Float = duration > 120 ? 10 : (duration > 30 ? 5 : 1)
            var t: Float = 0
            while t <= duration + 0.0001 {
                let x = self.x(of: t)
                list.drawLine(from: Vec2(x, r.y + 12), to: Vec2(x, r.y + r.height), width: 1, color: UIColor(1, 1, 1, 0.06))
                list.drawText(String(format: "%g", t), at: Vec2(x + 2, r.y + 2), size: 10, color: theme.secondaryTextColor)
                t += step
            }
            for (i, track) in tracks.enumerated() {
                let y = rowY(i)
                let selected = track.id == selectedTrack
                if selected {
                    list.fillRect(UIRect(x: r.x, y: y, width: r.width, height: Self.rowHeight), color: UIColor(1, 1, 1, 0.06))
                }
                list.drawLine(from: Vec2(r.x, y), to: Vec2(r.x + r.width, y), width: 1, color: UIColor(1, 1, 1, 0.08))
                let label = track.displayName + (track.muted ? " (muted)" : "")
                list.drawText(label, at: Vec2(r.x + 6, y + 5), size: 11,
                              color: track.trackKind == nil || track.muted ? theme.secondaryTextColor : theme.textColor)
                let color = Self.color(track.trackKind)
                // Continuous tracks: a bar between keys.
                if track.trackKind?.isContinuous == true, let first = track.keys.first, let last = track.keys.last {
                    list.fillRect(UIRect(x: x(of: first.time), y: y + Self.rowHeight / 2 - 1, width: max(x(of: last.time) - x(of: first.time), 1), height: 2),
                                  color: color.withAlpha(0.35))
                }
                for (k, key) in track.keys.enumerated() {
                    var time = key.time
                    if case .key(let id, let index, let t, true) = drag, id == track.id, index == k { time = t }
                    let cx = x(of: time), cy = y + Self.rowHeight / 2
                    let isSelected = selected && selectedKey == k
                    let s: Float = isSelected ? 6 : 4.5
                    list.fillRect(UIRect(x: cx - s, y: cy - s, width: s * 2, height: s * 2), color: isSelected ? theme.accent : color,
                                  radii: UICornerRadii(key.cut == true ? 0 : s))
                    let summary = key.summary(kind: track.trackKind)
                    if !summary.isEmpty, track.trackKind?.isContinuous == false {
                        list.drawText(summary, at: Vec2(cx + 8, y + 5), size: 10, color: theme.secondaryTextColor)
                    }
                }
            }
            let px = x(of: playhead)
            list.drawLine(from: Vec2(px, r.y), to: Vec2(px, r.y + r.height), width: 2, color: UIColor(1, 0.35, 0.3, 1))
        }
        _ = lane
    }

    static func color(_ kind: TimelineTrackKind?) -> UIColor {
        switch kind {
        case .camera: UIColor(0.35, 0.65, 1, 1)
        case .transform: UIColor(0.45, 0.85, 0.55, 1)
        case .animation: UIColor(0.95, 0.75, 0.35, 1)
        case .audio: UIColor(0.8, 0.55, 1, 1)
        case .particles: UIColor(1, 0.5, 0.3, 1)
        case .fade: UIColor(0.75, 0.75, 0.8, 1)
        case .event: UIColor(1, 0.9, 0.4, 1)
        case .dialogue: UIColor(0.4, 0.85, 0.85, 1)
        case nil: UIColor(0.5, 0.5, 0.5, 1)
        }
    }
}

/// The screen fade over the preview image (the preview isn't post-processed).
@MainActor
final class TimelineFadeOverlay: Widget {
    var fade: ScreenFade? { didSet { if fade != oldValue { setNeedsDisplay() } } }

    override init(name: String = "timelineFade") {
        super.init(name: name)
        isHitTestable = false
    }

    override func draw(_ list: UIDrawList, theme: UITheme) {
        guard let fade, fade.amount > 0 else { return }
        list.fillRect(frame, color: UIColor(fade.color.x, fade.color.y, fade.color.z, min(max(fade.amount, 0), 1)))
    }
}

@MainActor
public final class TimelineWorkspace {
    public let session: EditorSession
    public let view: VStack
    public private(set) var asset: AssetID?
    public private(set) var builder: TimelineBuilderView?
    /// The copy of the scene the timeline poses.
    public private(set) var world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 1, 0), yaw: -0.6, pitch: 0.35, distance: 14))
    public let strip = TimelineStripView()
    public private(set) var playhead: Float = 0
    public private(set) var isPlaying = false
    public private(set) var isLooping = true
    /// Look through the timeline's camera (else the free orbit camera).
    public private(set) var usesTimelineCamera = true
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    package let viewportWidget = ViewportWidget(name: "timelineViewport", label: "Timeline viewport")
    private let fadeOverlay = TimelineFadeOverlay()
    /// Shows the preview's conversations (dialogue tracks).
    let dialogueBox = DialogueBox(name: "timelineDialogueBox")
    /// The preview's sound, installed only while it plays.
    private var audio: SpatialAudioHandle?
    private let title = Label("Timeline", role: .heading, name: "timelineTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "timelineSidebar")
    private let playButton = Button("Play", name: "timelinePlay")
    private let loopToggle = Checkbox("Loop", kind: .toggleSwitch, name: "timelineLoop")
    private let cameraToggle = Checkbox("Camera View", kind: .toggleSwitch, name: "timelineCameraView")
    private var director: Entity?
    private var timeline = Timeline()
    private var shownRevision = -1
    private var syncedChange = -1
    private var syncedWorld: ObjectIdentifier?

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?

    public init(session: EditorSession) {
        self.session = session
        view = VStack(spacing: 0, name: "timelineWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.timeline` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isTimelineFile(id), let builder = TimelineBuilderView(session: session, asset: id) else { return false }
        if asset != id {
            asset = id
            self.builder = builder
            builder.viewCamera = { [unowned self] in viewport.camera }
            builder.onSelectionChange = { [unowned self] in syncStrip() }
            shownRevision = -1
            syncedChange = -1
            playhead = 0
            setPlaying(false)
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Timeline"
        title.icon = EditorIcons.named("clapperboard")
        return true
    }

    public func close() {
        asset = nil
        builder = nil
        director = nil
        silence()
        world.dialogues?.presenter = nil
        world = World()
        showEmpty()
    }

    // MARK: Transport

    public func setPlaying(_ on: Bool) {
        isPlaying = on
        playButton.title = on ? "Pause" : "Play"
        guard let director, world.isAlive(director) else { return }
        world.modify(TimelinePlayer.self, for: director) { p in
            if on {
                if playhead >= timeline.duration - 0.0001 { playhead = 0 }
                p.play(from: playhead)
            } else {
                p.seek(to: playhead)
            }
        }
    }

    /// Moves the playhead to `time` (pausing playback) and poses the preview there.
    public func scrub(to time: Float) {
        playhead = min(max(time, 0), timeline.duration)
        isPlaying = false
        playButton.title = "Play"
        builder?.playhead = playhead
        if let director, world.isAlive(director) { world.modify(TimelinePlayer.self, for: director) { $0.seek(to: playhead) } }
        strip.playhead = playhead
    }

    public func setLooping(_ on: Bool) {
        isLooping = on
        loopToggle.isOn = on
        if let director, world.isAlive(director) { world.modify(TimelinePlayer.self, for: director) { $0.loop = on } }
    }

    public func setUsesTimelineCamera(_ on: Bool) {
        usesTimelineCamera = on
        cameraToggle.isOn = on
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "timelineToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        playButton.action = { [unowned self] in setPlaying(!isPlaying) }
        playButton.tooltip = "Play or pause the preview from the playhead"
        bar.addChild(playButton)
        let stop = Button("Stop", name: "timelineStop") { [unowned self] in scrub(to: 0) }
        stop.tooltip = "Stop and go back to the start"
        bar.addChild(stop)
        loopToggle.isOn = true
        loopToggle.onChange = { [unowned self] on in setLooping(on) }
        loopToggle.tooltip = "Play the preview in a loop"
        bar.addChild(loopToggle)
        cameraToggle.isOn = true
        cameraToggle.onChange = { [unowned self] on in usesTimelineCamera = on }
        cameraToggle.tooltip = "Look through the timeline's camera (off: a free camera; right-drag orbits, the wheel zooms)"
        bar.addChild(cameraToggle)
        let reload = Button("Reload Scene", name: "timelineReloadScene") { [unowned self] in rebuildPreview() }
        reload.tooltip = "Copy the open scene into the preview again"
        bar.addChild(reload)
        let closeButton = Button("Close", name: "timelineClose") { [unowned self] in close() }
        bar.addChild(closeButton)

        strip.onScrub = { [unowned self] t in scrub(to: t) }
        strip.onSelect = { [unowned self] track, key in builder?.select(track: track, key: key) }
        strip.onMoveKey = { [unowned self] track, key, t in builder?.moveKey(track, key, to: t) }
        strip.onAddKey = { [unowned self] track, t in builder?.addKey(to: track, at: (t * 20).rounded() / 20) }
        strip.padding = EdgeInsets(top: 4, left: 6, bottom: 6, right: 6)

        let stage = Widget(name: "timelineStage")
        dialogueBox.style.position = .absolute(UIAnchor.bottom.anchors(offset: Vec2(0, 12)))
        dialogueBox.style.width = 480
        dialogueBox.continueHint = "Click to continue"
        stage.addChildren([viewportWidget, fadeOverlay, dialogueBox])
        stage.style.grow = 1
        stage.style.shrink = 1
        let stripScroll = ScrollView(strip, name: "timelineStripScroll")
        stripScroll.style.height = 150
        let left = VStack(spacing: 0, alignment: .stretch, name: "timelineLeft", [stage, Separator(), stripScroll])
        left.style.grow = 1
        left.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "timelineSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "timelineBody", [left, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Timeline"
        title.icon = EditorIcons.named("clapperboard")
        sidebar.removeAllChildren()
        strip.tracks = []
        fadeOverlay.fade = nil
        let note = Label("Double-click a .timeline file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Timeline (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Timeline", role: .primary, name: "timelineNew") { [unowned self] in
            if let id = session.run(TimelineNewCommand.self, .init())?.asset { session.run(TimelineOpenCommand.self, .init(asset: AssetReference(id))) }
        }
        new.command = TimelineNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No timeline open"
    }

    // MARK: Preview

    /// Copies the open scene into the preview world and puts a paused player at the playhead.
    public func rebuildPreview() {
        guard let asset else { return }
        let copy = World()
        do { _ = try copy.load(try session.world.save()) } catch {
            session.log.error("Timeline: copying the scene into the preview failed: \(error)")
        }
        copy.propagateTransforms()
        // The game's systems the timeline drives: animation clips, conversations (sound is added while playing).
        if copy.count(of: SpriteAnimator.self) > 0 { copy.addSpriteAnimationSystem(name: "timelinePreview.spriteAnimation") }
        copy.addSceneAnimationSystem(assets: { [weak session] in session?.assets }, name: "timelinePreview.animation")
        silence()
        world.dialogues?.presenter = nil
        // Only the timeline's conversations: the scene's autoStart ones would cover the preview.
        var talkers: [Entity] = []
        copy.query(DialoguePlayer.self) { e, d in if d.autoStart { talkers.append(e) } }
        for e in talkers { copy.modify(DialoguePlayer.self, for: e) { $0.autoStart = false } }
        copy.addDialogueSystem(assets: { [weak session] in session?.assets }).presenter = dialogueBox
        copy.addTimelinePlayers(assets: { [weak session] in session?.assets })
        director = copy.spawn(Name("Timeline Preview"),
                              TimelinePlayer(timeline: AssetReference(asset).description, playOnStart: false, loop: isLooping))
        world = copy
        syncedChange = session.undo.changeCount
        syncedWorld = ObjectIdentifier(session.world)
        let resume = isPlaying
        world.modify(TimelinePlayer.self, for: director!) { [playhead] p in
            if resume { p.play(from: playhead) } else { p.seek(to: playhead) }
        }
        world.update(dt: 0)
    }

    private func syncStrip() {
        strip.tracks = timeline.tracks
        strip.duration = timeline.duration
        strip.playhead = playhead
        strip.selectedTrack = builder?.selectedTrack
        strip.selectedKey = builder?.selectedKey
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when it belongs elsewhere), follows the file
    /// and the scene, and advances the preview. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()
        // The dialogue box fits a narrow preview (it would spill over the sidebar).
        let boxWidth = viewportWidget.frame.width > 0 ? min(480, max(160, viewportWidget.frame.width - 24)) : 480
        if dialogueBox.style.width != boxWidth { dialogueBox.style.width = boxWidth }
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            shownRevision = revision
            timeline = (assets.timeline(of: asset) ?? Timeline()).normalized()
            playhead = min(playhead, timeline.duration)
        }
        // The scene changed (an edit, undo, another scene): copy it again, unless the preview plays.
        if (session.undo.changeCount != syncedChange || syncedWorld != ObjectIdentifier(session.world) || director == nil),
           !isPlaying || director == nil {
            rebuildPreview()
        }
        viewport.tools = []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible, !usesTimelineCamera {
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        // Sound only while playing: a paused preview is silent (the scene's own emitters too).
        if isPlaying, audio == nil, let device = session.audioProvider?() {
            audio = world.addSpatialAudio(device, assets: { [weak session] in session?.assets })
        } else if !isPlaying {
            silence()
        }
        world.update(dt: isPlaying ? Double(dt) : 0)
        if let director, let player = world.get(TimelinePlayer.self, for: director) {
            if isPlaying {
                playhead = player.time
                if player.state == .finished { setPlaying(false) }
            }
            fadeOverlay.fade = world.get(ScreenFade.self, for: director)
        }
        builder?.playhead = playhead
        syncStrip()
    }

    /// Stops the preview's sound.
    private func silence() {
        audio?.remove()
        audio = nil
    }

    /// The camera the timeline drives in the preview (its camera track's target, else the active camera).
    func timelineCamera() -> Entity? {
        if let track = timeline.tracks.first(where: { $0.trackKind == .camera && !$0.muted }), !track.target.isEmpty,
           let entity = TimelineEvaluator.find(track.target, in: world), world.has(Camera.self, for: entity) {
            return entity
        }
        return RenderPrep.findCamera(in: world)?.entity
    }

    public func prepareFrame(pixelScale: Float) {
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Timeline: resizing the view failed: \(error)")
            }
        }
        let aspect = target?.aspectRatio ?? (rect.height > 0 ? rect.width / rect.height : 1)
        world.propagateTransforms()
        if usesTimelineCamera, let camera = timelineCamera(), let view = SceneView(camera: camera, in: world, aspect: aspect) {
            currentView = view
        } else {
            currentView = viewport.view(aspect: aspect, clearColor: Vec4(0.05, 0.055, 0.07, 1))
        }
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Timeline preview needs the GPU to draw" : nil
        let mode = usesTimelineCamera ? (timelineCamera() == nil ? "No camera in the scene" : "Camera view") : "Free camera · right-drag orbits"
        viewportWidget.caption = String(format: "%.2f / %.2f s", playhead, timeline.duration) + " · " + mode
    }

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        renderer.renderView(view, into: target, frame: frame)
    }

    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    private func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: EditorSelection(), undo: UndoStack(world: world), view: view,
                            viewportRect: viewport.rect, pixelScale: 1, toolMode: session.tool, isPlaying: false,
                            meshBounds: { _ in nil }, commands: nil, snapping: false,
                            snapSteps: session.editorSettings.gizmoSnapping(enabled: false))
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "timeline view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Timeline: the view can't render: \(error)")
            self.device = nil
        }
    }
}
