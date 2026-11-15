import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineText

/// What `SceneRenderer` reads from and writes to the engine each frame. `Engine` conforms; the
/// renderer takes this protocol rather than `Engine` so it doesn't depend on the engine itself.
@MainActor
public protocol SceneRenderHost: AnyObject {
    var device: RenderDevice { get }
    var quality: RenderQuality { get }
    var debugDraw: DebugDraw { get }
    var renderSize: (width: Int, height: Int) { get }
    var aspectRatio: Float { get }
    var clearColor: Vec4 { get set }
    var clearDepth: Float { get set }
    var postProcess: PostProcessSettings? { get set }
    var postProcessor: PostProcessor? { get }
    /// `projection` with this frame's sub-pixel jitter when a temporal upscaler is active.
    func jittered(_ projection: Mat4) -> Mat4
}
