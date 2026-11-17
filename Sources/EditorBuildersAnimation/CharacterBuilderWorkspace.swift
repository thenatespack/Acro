import EditorCore
import Engine
import Foundation

// The Character Builder tab: one `.character` file shown alone in a viewport of its own (its own
// `World`, renderer and camera) playing a clip on its `Animator`, with the `CharacterBuilderView`
// form beside it. Orbit with right-drag (or middle-drag), pan with Shift, zoom with the wheel.
//
// The file is the truth: every edit is written as one undo step of the editor (Ctrl+Z), the
// character reimports and the workspace rebuilds its copy (also after edits from MCP or other panels).

@MainActor
public final class CharacterBuilderWorkspace {
    public let session: EditorSession
    /// The panel's content.
    public let view: VStack
    /// The character being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    /// The form beside the viewport.
    public private(set) var builder: CharacterBuilderView?
    /// The character, a ground plane and lighting, apart from the scene.
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0.9, 0), yaw: 0.5, pitch: 0.2, distance: 4))
    /// Set by the host to render (nil without a GPU: the workspace still edits, it just draws nothing).
    public var device: RenderDevice?
    public var quality = RenderQuality.high
    /// The clip the preview plays.
    public private(set) var clip: String?
    public private(set) var isPaused = false
    public private(set) var showsSkeleton = false

    package let viewportWidget = ViewportWidget(name: "characterBuilderViewport", label: "Character Builder viewport")
    private let title = Label("Character Builder", role: .heading, name: "characterBuilderTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "characterBuilderSidebar")
    private let pauseToggle = Checkbox("Pause", kind: .toggleSwitch, name: "characterPause")
    private let skeletonToggle = Checkbox("Bones", kind: .toggleSwitch, name: "characterBones")
    /// The character's root entity in `world`.
    public private(set) var root: Entity?
    private var shownRevision = -1
    private var needsFraming = false

    private var renderer: SceneRenderer?
    private var target: RenderTarget?
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private let gizmos = DebugDraw()

    public init(session: EditorSession) {
        self.session = session
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-50, 30, 0))), Name("Light"),
                    DirectionalLight(intensity: 2.2, castsShadows: true))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.6, fogDensity: 0))
        world.spawn(Transform(scale: Vec3(8, 1, 8)), Name("Ground"), MeshRenderer(mesh: .plane, material: MaterialHandle("characterGround")))
        // The play-mode system (SceneAnimation.swift), so the tab previews exactly what plays in games.
        world.addSceneAnimationSystem(assets: { [weak session] in session?.assets }, name: "characterBuilder.animation")
        view = VStack(spacing: 0, name: "characterBuilderWorkspace")
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.character` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isCharacterFile(id) else { return false }
        if asset != id {
            guard let builder = CharacterBuilderView(session: session, asset: id) else { return false }
            asset = id
            self.builder = builder
            builder.onPlayClip = { [unowned self] name in play(name) }
            builder.playingClip = { [unowned self] in clip }
            clip = nil
            shownRevision = -1
            needsFraming = true
            sidebar.removeAllChildren()
            sidebar.addChild(builder.view)
        }
        if let requested = session.characterPreviewClip {
            session.characterPreviewClip = nil
            play(requested)
        }
        title.text = session.assets?.record(id)?.fileName ?? "Character Builder"
        title.icon = EditorIcons.asset(.model)
        return true
    }

    /// Closes the file (the panel shows how to open one).
    public func close() {
        asset = nil
        builder = nil
        if let root { world.despawn(root) }
        root = nil
        showEmpty()
    }

    // MARK: Playback

    /// Plays `name` (a clip of the character) from its start.
    public func play(_ name: String) {
        clip = name
        if let root {
            world.modify(Animator.self, for: root) { $0.play(name, fade: 0) }
        }
        builder?.layout()
    }

    public func setPaused(_ on: Bool) {
        isPaused = on
        pauseToggle.isOn = on
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "characterBuilderToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        let restart = Button("Restart", name: "characterRestart") { [unowned self] in if let clip { play(clip) } }
        restart.tooltip = "Play the clip again from the start"
        bar.addChild(restart)
        pauseToggle.onChange = { [unowned self] on in isPaused = on }
        pauseToggle.tooltip = "Freeze the preview"
        bar.addChild(pauseToggle)
        skeletonToggle.onChange = { [unowned self] on in showsSkeleton = on }
        skeletonToggle.tooltip = "Draw the bones over the character"
        bar.addChild(skeletonToggle)
        let frame = Button("Frame", name: "characterBuilderFrame") { [unowned self] in frameCharacter() }
        frame.tooltip = "Fit the character in the view"
        bar.addChild(frame)
        let closeButton = Button("Close", name: "characterBuilderClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this character"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "characterBuilderSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "characterBuilderBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Character Builder"
        title.icon = EditorIcons.asset(.model)
        sidebar.removeAllChildren()
        let note = Label("Double-click a .character file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Character (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Character", role: .primary, name: "characterBuilderNew") { [unowned self] in
            if let id = session.run(CharacterNewCommand.self, .init())?.asset {
                session.run(CharacterOpenCommand.self, .init(asset: AssetReference(id)))
            }
        }
        new.command = CharacterNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No character open"
    }

    // MARK: Per frame

    /// Handles this frame's pointer (`input`: nil when the keyboard and mouse belong elsewhere),
    /// keeps the copy in step with the file and advances the animation. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        builder?.refresh()  // applies the form's pending edit (writes the file)
        if assets.revision(of: asset) != shownRevision {
            if shownRevision >= 0 { builder?.reload() }
            rebuild()
        }
        viewport.tools = []
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        world.update(dt: isPaused ? 0 : Double(dt))
    }

    /// Sizes the render target to the panel; call after layout.
    public func prepareFrame(pixelScale: Float) {
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        if needsFraming, root != nil {
            frameCharacter()
            needsFraming = false
        }
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do { try target.resize(width: size.width, height: size.height) } catch {
                session.log.error("Character Builder: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: session.viewportClearColor)
        gizmos.removeAll()
        if showsSkeleton { world.drawSkeletons(into: gizmos) }
        viewportWidget.texture = target?.texture
        viewportWidget.placeholder = target == nil ? "The Character Builder needs the GPU to draw" : nil
        let playing = root.flatMap { world.get(Animator.self, for: $0)?.currentState } ?? "rest pose"
        viewportWidget.caption = (isPaused ? "Paused · " : "") + "\(playing) · right-drag orbits · Shift pans · wheel zooms"
    }

    /// Renders the view; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let view = currentView, sizer.width > 0 else { return }
        if renderer.assets !== session.assets { renderer.assets = session.assets }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        renderer.renderView(view, into: target, frame: frame, debugDraw: gizmos)
    }

    /// Whether this frame's pointer belongs to the workspace's viewport.
    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    // MARK: Character

    private func rebuild() {
        guard let asset, let assets = session.assets else { return }
        shownRevision = assets.revision(of: asset)
        if let root { world.despawn(root) }
        root = nil
        guard let prefab = assets.prefab(AssetReference(asset)), let newRoot = world.instantiate(prefab).first else { return }
        root = newRoot
        if let clip, let animator = world.get(Animator.self, for: newRoot), animator.stateMachine.index(of: clip) != nil {
            world.modify(Animator.self, for: newRoot) { $0.play(clip, fade: 0) }
        } else {
            clip = world.get(Animator.self, for: newRoot)?.stateMachine.initialState
        }
        world.propagateTransforms()
    }

    /// Fits the camera to the character.
    public func frameCharacter() {
        guard let rig = builder?.character.rig else { return }
        var bounds = rig.bounds
        bounds.halfExtent = Vec3(repeating: max(bounds.halfExtent.x, bounds.halfExtent.y, bounds.halfExtent.z) * 1.2)
        viewport.frame(bounds)
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
            try renderer.registerMaterial(Material(shading: .pbr, baseColor: Vec4(0.32, 0.34, 0.37, 1), roughness: 0.9), key: "characterGround")
            self.renderer = renderer
            target = try RenderTarget(device: device, width: 640, height: 360, label: "character builder view")
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Character Builder: the view can't render: \(error)")
            self.device = nil
        }
    }
}
