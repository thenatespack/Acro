import Engine
import Foundation

/// Where the orbit camera starts when a scene is opened.
struct OrbitView {
    var yaw: Float = 0.7
    var pitch: Float = 0.6
    var distance: Float = 40
    var target = Vec3(0, 2, 0)
}

/// One test scene. The host (`DemoGame`) owns the camera, the shadow pass and the
/// screen pass, and calls into the scene for content.
@MainActor
protocol DemoScene: AnyObject {
    /// Name used on the command line (`--scene <name>`).
    static var name: String { get }
    /// What the scene exercises.
    static var summary: String { get }

    init(renderer: Renderer) throws

    var initialView: OrbitView { get }
    var lighting: Lighting { get }
    /// Builds the camera from the orbit controls. Scenes may override it entirely.
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera
    /// Extra text for the window title (current mode, counters, …).
    var status: String { get }

    /// `time` is the animation clock (stops while paused).
    func update(input: Input, dt: Float, time: Float)
    /// The same with engine access (e.g. `engine.audio`). Defaults to `update(input:dt:time:)`.
    func update(engine: Engine, dt: Float, time: Float)
    /// Called before the host switches to another scene (stop sounds, etc.).
    func willClose()
    /// Extra offscreen passes, recorded before the shadow pass.
    func renderOffscreen(frame: Frame)
    /// The same with engine access (jitter, aspect, clear color). Defaults to `renderOffscreen(frame:)`.
    func renderOffscreen(engine: Engine, frame: Frame)
    /// Geometry for the shadow map. The shadow pipeline and uniforms are already bound.
    func drawShadowCasters(_ pass: RenderPass)
    /// The screen pass. Uniforms and the shadow map are already bound; set a pipeline.
    func draw(_ pass: RenderPass) throws
    /// Fills the engine's 2D UI draw list (drawn in the window pass, over the scene).
    func drawUI(_ ui: UIDrawList)
    /// A retained widget tree. The host updates it before its own input handling and skips
    /// camera controls and shortcuts while it wants the pointer or keyboard.
    var uiContext: UIContext? { get }
    /// The scene uses the keyboard itself right now (e.g. Esc cancels a drag), so the host
    /// leaves its shortcuts and camera keys alone, like when widgets want the keyboard.
    var wantsKeyboard: Bool { get }
}

extension DemoScene {
    var initialView: OrbitView { OrbitView() }
    var lighting: Lighting { Lighting() }
    var status: String { "" }
    func camera(orbitEye: Vec3, target: Vec3) -> ViewCamera { ViewCamera(eye: orbitEye, target: target) }
    func update(input: Input, dt: Float, time: Float) {}
    func update(engine: Engine, dt: Float, time: Float) { update(input: engine.input, dt: dt, time: time) }
    func willClose() {}
    func renderOffscreen(frame: Frame) {}
    func renderOffscreen(engine: Engine, frame: Frame) { renderOffscreen(frame: frame) }
    func drawUI(_ ui: UIDrawList) {}
    var uiContext: UIContext? { nil }
    var wantsKeyboard: Bool { false }
}

/// Every scene, in number-key order (scenes past 10 are reached with `[` / `]`).
@MainActor let allScenes: [any DemoScene.Type] = [
    ShadowsScene.self,
    InstancingScene.self,
    TransparencyScene.self,
    DepthPrecisionScene.self,
    CullingScene.self,
    ResourceChurnScene.self,
    OcclusionScene.self,
    TexturesScene.self,
    TextScene.self,
    UIScene.self,
    ECSScene.self,
    WidgetsScene.self,
    DockingScene.self,
    InspectorScene.self,
    ViewportsScene.self,
    GizmosScene.self,
    ImagesScene.self,
    GLTFScene.self,
    PBRScene.self,
    InputScene.self,
    LightsScene.self,
    AudioScene.self,
    Shadows2Scene.self,
    PostScene.self,
    SpritesScene.self,
    SkyScene.self,
    PhysicsScene.self,
    ParticlesScene.self,
]
