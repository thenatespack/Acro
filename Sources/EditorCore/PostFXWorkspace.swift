import Engine
import Foundation

// The Post-FX tab: a workspace for one `.postfx` file, tabbed with the Scene view. A small
// sample scene (a lit set with a glowing lamp) is drawn in a viewport of its own and run through
// the profile's post pass, so every slider change is visible at once; the form beside it edits
// the profile and each change is written to the file as one undo step (Ctrl+Z).
//
// - Presets replace the whole look; the sliders and colors below are the file's keys.
// - Split compares the plain scene (left) with the look (right) at a movable line.
// - Orbit with right-drag (or middle-drag), pan with Shift, zoom with the wheel.
//
// The preview post-processes the editor view's 8-bit image, so highlights above 1 are already
// clipped: bloom and the tonemapper look weaker here than in the game's HDR path; grading,
// vignette, chromatic aberration and grain match.

/// The proxy the form's property grid edits: encodes as the profile itself.
struct PostFXFormComponent: Component {
    static var componentName: String { "Post-FX" }
    static var fieldHints: [String: FieldHints] { PostProcessSettings.fieldHints }

    var settings: PostProcessSettings

    init(settings: PostProcessSettings) { self.settings = settings }
    init(from decoder: any Decoder) throws { settings = try PostProcessSettings(from: decoder) }
    func encode(to encoder: any Encoder) throws { try settings.encode(to: encoder) }
}

@MainActor
public final class PostFXWorkspace {
    public let session: EditorSession
    public let view: VStack
    /// The profile being edited (nil: nothing open).
    public private(set) var asset: AssetID?
    public private(set) var profile = PostProcessSettings()
    /// The sample scene, apart from the project's scene.
    public let world = World()
    public let viewport = ViewportController(camera: EditorCamera(pivot: Vec3(0, 0.8, 0), yaw: -0.7, pitch: 0.3, distance: 7))
    /// Whether the before/after split is shown, and where (0...1 of the width).
    public private(set) var splitEnabled = false
    public private(set) var splitPosition: Float = 0.5
    public var device: RenderDevice?
    public var quality = RenderQuality.high

    let viewportWidget = ViewportWidget(name: "postFXViewport", label: "Post-FX viewport")
    private let title = Label("Post-FX", role: .heading, name: "postFXTitle")
    private let sidebar = VStack(spacing: 6, padding: EdgeInsets(top: 8, left: 10, bottom: 8, right: 10), name: "postFXSidebar")
    private let splitToggle = Checkbox("Split", kind: .toggleSwitch, name: "postFXSplit")
    private let splitSlider = Slider(value: 0.5, in: 0.05...0.95, step: 0.01, name: "postFXSplitPosition")
    private let formWorld = World()
    private var formEntity: Entity?
    private var grid: PropertyGrid?
    private var shownRevision = -1
    private var pendingEdit: (PostProcessSettings, String)?
    private let undoStack: UndoStack

    private var renderer: SceneRenderer?
    private var processor: PostProcessor?
    private var target: RenderTarget?
    private var output: GPURenderTarget?
    private var outputSize = (width: 0, height: 0)
    private var sizer = ViewportTargetSizer()
    private var currentView: SceneView?
    private var lastDT: Float = 1.0 / 60

    public init(session: EditorSession) {
        self.session = session
        undoStack = UndoStack(world: world)
        view = VStack(spacing: 0, name: "postFXWorkspace")
        world.spawn(Transform(rotation: Quat(eulerDegrees: Vec3(-45, 40, 0))), Name("Light"),
                    DirectionalLight(intensity: 3, castsShadows: true))
        world.spawn(Name("Environment"), SceneEnvironment(ambientIntensity: 0.5, fogDensity: 0))
        buildSampleScene()
        layOutChrome()
        showEmpty()
    }

    // MARK: Opening

    /// Shows `id` (a `.postfx` file); false if it isn't one.
    @discardableResult
    public func open(_ id: AssetID) -> Bool {
        guard session.isPostFXFile(id), let profile = session.assets?.postFX(of: id) else { return false }
        if asset != id {
            asset = id
            shownRevision = -1
            self.profile = profile
            buildForm()
        }
        title.text = session.assets?.record(id)?.fileName ?? "Post-FX"
        title.icon = EditorIcons.named("sparkles")
        return true
    }

    public func close() {
        asset = nil
        grid = nil
        showEmpty()
    }

    public func setSplit(enabled: Bool, position: Float? = nil) {
        splitEnabled = enabled
        splitToggle.isOn = enabled
        if let position {
            splitPosition = min(max(position, 0.05), 0.95)
            splitSlider.setValue(splitPosition)
        }
    }

    // MARK: Chrome

    private func layOutChrome() {
        let bar = HStack(spacing: 6, padding: EdgeInsets(top: 6, left: 10, bottom: 6, right: 10), name: "postFXToolbar")
        title.style.shrink = 1
        bar.addChild(title)
        bar.addChild(Spacer())
        splitToggle.onChange = { [unowned self] on in splitEnabled = on }
        splitToggle.tooltip = "Before / after: the plain scene on the left of the line, the look on the right"
        splitSlider.style.width = 120
        splitSlider.onChange = { [unowned self] value in splitPosition = value }
        bar.addChildren([splitToggle, splitSlider])
        let closeButton = Button("Close", name: "postFXClose") { [unowned self] in self.close() }
        closeButton.tooltip = "Stop editing this profile"
        bar.addChild(closeButton)

        viewportWidget.style.grow = 1
        viewportWidget.style.shrink = 1
        let scroll = ScrollView(sidebar, name: "postFXSidebarScroll")
        scroll.style.width = 340
        let body = HStack(spacing: 0, alignment: .stretch, name: "postFXBody", [viewportWidget, Separator(.vertical), scroll])
        body.style.grow = 1
        body.style.shrink = 1
        view.addChildren([bar, Separator(), body])
    }

    private func showEmpty() {
        title.text = "Post-FX"
        title.icon = EditorIcons.named("sparkles")
        sidebar.removeAllChildren()
        let note = Label("Double-click a .postfx file in the Assets panel to edit it here, or make one with the Assets panel's "
                         + "New Post-FX (right-click).", role: .caption)
        note.wraps = true
        let new = Button("New Post-FX", role: .primary, name: "postFXNew") { [unowned self] in
            if let id = session.run(PostFXNewCommand.self, .init(preset: "cinematic"))?.asset {
                session.run(PostFXOpenCommand.self, .init(asset: AssetReference(id)))
            }
        }
        new.command = PostFXNewCommand.id.rawValue
        sidebar.addChildren([note, HStack(spacing: 6, [new, Spacer()])])
        viewportWidget.placeholder = "No post-fx profile open"
    }

    private func buildForm() {
        sidebar.removeAllChildren()
        let presets = HStack(spacing: 4, name: "postFXPresets")
        presets.wraps = true
        for preset in PostFXPreset.allCases {
            let button = Button(preset.rawValue.capitalized, name: "postFXPreset.\(preset.rawValue)") { [unowned self] in
                pendingEdit = (preset.settings, "Post-FX Preset \(preset.rawValue.capitalized)")
            }
            button.command = PostFXEditCommand.id.rawValue
            button.tooltip = "Replace this look with the \(preset.rawValue) preset"
            presets.addChild(button)
        }
        let assign = Button("Assign to Camera", name: "postFXAssign") { [unowned self] in
            if let asset { session.run(PostFXAssignCommand.self, .init(asset: AssetReference(asset))) }
        }
        assign.command = PostFXAssignCommand.id.rawValue
        assign.tooltip = "Use this look on the scene's active camera"
        sidebar.addChildren([Label("Presets", role: .secondary), presets, HStack(spacing: 6, [assign, Spacer()])])

        if let formEntity { formWorld.despawn(formEntity) }
        let entity = formWorld.spawn(PostFXFormComponent(settings: profile))
        formEntity = entity
        let grid = PropertyGrid(world: formWorld, name: "postFXGrid")
        grid.appliesEditsToWorld = false
        grid.labelWidth = 120
        grid.entity = entity
        grid.command = PostFXEditCommand.id.rawValue
        grid.onFieldEdit = { [unowned self] edit in
            do { try formWorld.setField(edit.path, of: PostFXFormComponent.componentName, for: entity, to: edit.newValue) } catch {
                session.log.error("Post-FX \(edit.path): \(error)")
                return
            }
            if edit.phase == .ended, let settings = formWorld.get(PostFXFormComponent.self, for: entity)?.settings {
                pendingEdit = (settings, "Edit Post-FX")
            } else if let settings = formWorld.get(PostFXFormComponent.self, for: entity)?.settings {
                profile = settings  // live preview while dragging
            }
        }
        self.grid = grid
        sidebar.addChild(grid)
        let note = Label("Depth of field and LUT grading are not available yet. The preview clips highlights to 8-bit, so bloom looks weaker here than in the game.", role: .caption)
        note.wraps = true
        sidebar.addChild(note)
    }

    // MARK: Per frame

    /// Applies the form's pending edit, follows the file, and handles the viewport pointer. Call before layout.
    public func update(input: ViewportInput?, dt: Float) {
        lastDT = dt
        guard let asset, let assets = session.assets else { return }
        guard assets.record(asset) != nil else { return close() }
        if let (edited, label) = pendingEdit {
            pendingEdit = nil
            if session.applyPostFX(edited, to: asset, label: label) != nil { profile = assets.postFX(of: asset) ?? edited }
        }
        grid?.refresh()
        let revision = assets.revision(of: asset)
        if revision != shownRevision {
            shownRevision = revision
            if let fresh = assets.postFX(of: asset), fresh != profile || formEntity == nil {
                profile = fresh
                buildForm()
            }
        }
        viewport.rect = viewportWidget.isEffectivelyVisible ? viewportWidget.frame : .zero
        if var input, viewportWidget.isEffectivelyVisible {
            for set in [\ViewportInput.pressed, \ViewportInput.released, \ViewportInput.down] where input[keyPath: set].contains(.right) {
                input[keyPath: set].remove(.right)
                input[keyPath: set].insert(.middle)
            }
            input.move = .zero
            viewport.update(input) { [unowned self] view in toolContext(view: view) }
        }
        world.propagateTransforms()
    }

    /// Sizes the render targets to the panel; call after layout.
    public func prepareFrame(pixelScale: Float) {
        guard asset != nil, viewportWidget.isEffectivelyVisible else {
            currentView = nil
            return
        }
        setUpRenderingIfNeeded()
        let rect = viewportWidget.frame
        if let target, let size = sizer.update(rect: rect, scale: pixelScale) {
            do {
                try target.resize(width: size.width, height: size.height)
                output = try device?.makeRenderTarget(.color(width: target.width, height: target.height, format: .rgba8Srgb))
            } catch {
                session.log.error("Post-FX: resizing the view failed: \(error)")
            }
        }
        let aspect = rect.height > 0 ? rect.width / rect.height : 1
        currentView = viewport.view(aspect: target?.aspectRatio ?? aspect, clearColor: Vec4(0.35, 0.45, 0.6, 1))
        viewportWidget.texture = output?.texture
        viewportWidget.placeholder = target == nil ? "The Post-FX tab needs the GPU to draw" : nil
        viewportWidget.caption = splitEnabled ? "Left: plain scene · right: this look" : "Right-drag orbits · Shift pans · wheel zooms"
    }

    /// Renders the sample scene and runs the look over it; call in `renderOffscreen`.
    public func render(frame: Frame) {
        guard let renderer, let target, let processor, let output, let view = currentView, sizer.width > 0 else { return }
        renderer.beginViews(world: world, frame: frame, shadowFocus: view)
        renderer.renderView(view, into: target, frame: frame)
        processor.splitPreview = splitEnabled ? splitPosition : 0
        processor.renderPreview(scene: target.texture, settings: profile, into: output, dt: lastDT)
    }

    public func hasPointer(_ input: ViewportInput) -> Bool {
        viewportWidget.isEffectivelyVisible && viewport.hasPointer(input)
    }

    // MARK: Helpers

    private func buildSampleScene() {
        let floor = world.spawn(Transform(position: Vec3(0, -0.05, 0), scale: Vec3(14, 0.1, 14)), Name("Floor"),
                                MeshRenderer(mesh: .cube))
        _ = floor
        func shape(_ mesh: MeshHandle, _ position: Vec3, _ scale: Vec3, _ name: String) {
            world.spawn(Transform(position: position, scale: scale), Name(name), MeshRenderer(mesh: mesh))
        }
        shape(.sphere, Vec3(-2, 0.8, 0), Vec3(1.6, 1.6, 1.6), "Ball")
        shape(.cube, Vec3(0.2, 0.6, -1), Vec3(1.2, 1.2, 1.2), "Crate")
        shape(.cube, Vec3(2.4, 1.2, 0.5), Vec3(0.8, 2.4, 0.8), "Pillar")
        shape(.sphere, Vec3(0.4, 0.25, 1.6), Vec3(0.5, 0.5, 0.5), "Pebble")
    }

    func toolContext(view: SceneView) -> ViewportToolContext {
        ViewportToolContext(world: world, selection: EditorSelection(), undo: undoStack, view: view, viewportRect: viewport.rect,
                            pixelScale: 1, toolMode: session.tool, isPlaying: false,
                            meshBounds: { _ in nil }, commands: nil, snapping: false,
                            snapSteps: session.editorSettings.gizmoSnapping(enabled: false))
    }

    private func setUpRenderingIfNeeded() {
        guard renderer == nil, let device else { return }
        do {
            let renderer = try SceneRenderer(device: device, quality: quality)
            renderer.assets = session.assets
            self.renderer = renderer
            processor = try PostProcessor(device: device)
            target = try RenderTarget(device: device, width: 640, height: 360, label: "post-fx view")
            output = try device.makeRenderTarget(.color(width: 640, height: 360, format: .rgba8Srgb))
            sizer = ViewportTargetSizer()
        } catch {
            session.log.error("Post-FX: the view can't render: \(error)")
            self.device = nil
        }
    }
}

public enum PostFXOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PostFXTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "postfx.open"
    public static let title = "Open in Post-FX Builder"
    public static let doc = "Opens a .postfx file in the editor's Post-FX tab (a sample scene run through the profile, with presets, sliders and a before/after split) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"postFXBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolvePostFX(arguments, title)
        session.openPostFX = id
        session.onOpenPostFX?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
