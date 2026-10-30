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
    func camera(orbitEye: Vec3, target: Vec3) -> Camera
    /// Extra text for the window title (current mode, counters, …).
    var status: String { get }

    /// `time` is the animation clock (stops while paused).
    func update(input: Input, dt: Float, time: Float)
    /// Extra offscreen passes, recorded before the shadow pass.
    func renderOffscreen(frame: Frame)
    /// Geometry for the shadow map. The shadow pipeline and uniforms are already bound.
    func drawShadowCasters(_ pass: RenderPass)
    /// The screen pass. Uniforms and the shadow map are already bound; set a pipeline.
    func draw(_ pass: RenderPass) throws
    /// Fills the engine's 2D UI draw list (drawn in the window pass, over the scene).
    func drawUI(_ ui: UIDrawList)
}

extension DemoScene {
    var initialView: OrbitView { OrbitView() }
    var lighting: Lighting { Lighting() }
    var status: String { "" }
    func camera(orbitEye: Vec3, target: Vec3) -> Camera { Camera(eye: orbitEye, target: target) }
    func update(input: Input, dt: Float, time: Float) {}
    func renderOffscreen(frame: Frame) {}
    func drawUI(_ ui: UIDrawList) {}
}

/// Every scene, in number-key order.
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
]
