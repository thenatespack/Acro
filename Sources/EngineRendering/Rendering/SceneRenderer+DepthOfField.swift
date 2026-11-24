#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

/// `SceneRenderer`'s side of depth of field (`PostProcessSettings.depthOfField`, dof.frag):
/// `prepare` notes whether this frame's post-processing wants it, then `renderShadows` hands
/// the post-processor the main camera's depth: the particles' or volumetric fog's prepass when
/// one was rendered this frame, otherwise its own. Without depth of field nothing extra is drawn.
/// `prepare` also points the post-processor at this renderer's assets, for LUT grading.
@MainActor
final class DepthOfFieldState {
    struct Setup {
        var projection: Mat4
        var viewProjection: Mat4
        var eye: Vec3
        var reversedZ: Bool
        var size: (width: Int, height: Int)
    }

    var setup: Setup?
    weak var postProcessor: PostProcessor?
}

extension SceneRenderer {
    /// Called by `prepare` once `engine.postProcess` is final (nil `projection`: no camera).
    func prepareDepthOfField(engine: some SceneRenderHost, projection: Mat4?, viewProjection: Mat4, eye: Vec3, reversedZ: Bool,
                             size: (width: Int, height: Int)) {
        depthOfField.setup = nil
        depthOfField.postProcessor = engine.postProcessor
        engine.postProcessor?.sceneDepth = nil
        engine.postProcessor?.assets = assets  // where LUTs are looked up
        guard let projection, engine.postProcess?.depthOfField == true, engine.postProcessor != nil,
              size.width > 0, size.height > 0 else { return }
        depthOfField.setup = .init(projection: projection, viewProjection: viewProjection, eye: eye, reversedZ: reversedZ, size: size)
    }

    /// Gives the post-processor this frame's camera depth (called by `renderShadows`).
    func renderDepthOfFieldDepth(frame: Frame) {
        guard let setup = depthOfField.setup, let postProcessor = depthOfField.postProcessor else { return }
        let texture: GPUTexture
        if let shared = particleDepth?.texture ?? volumetric.depth {
            texture = shared
        } else {
            guard let own = depthTexture(&particleDepthTexture, size: setup.size) else { return }
            renderDepthPrepass(into: own, list: list, instances: uploaded, viewProjection: setup.viewProjection, eye: setup.eye,
                               reversedZ: setup.reversedZ, frame: frame)
            texture = own
        }
        postProcessor.sceneDepth = PostProcessor.Depth(texture: texture, projection: setup.projection)
    }

    /// The depth of the world (as gathered by `beginViews`) seen from `view` at `size`, for
    /// `PostProcessor.renderPreview`'s depth of field: a prepass of the opaque meshes. Call
    /// between passes, like `renderView`.
    public func renderDepth(for view: SceneView, size: (width: Int, height: Int), frame: Frame) -> PostProcessor.Depth? {
        var texture = viewParticleDepthTextures[[size.width, size.height]]
        if texture == nil, viewParticleDepthTextures.count >= 4 { viewParticleDepthTextures.removeAll() }
        guard let texture = depthTexture(&texture, size: size) else { return nil }
        viewParticleDepthTextures[[size.width, size.height]] = texture
        viewList.build(items: prep.items, view: Frustum(viewProjection: view.viewProjection), cameraPosition: view.eye, shadows: nil)
        let instances = viewList.instances.isEmpty ? nil : frame.upload(viewList.instances)
        renderDepthPrepass(into: texture, list: viewList, instances: instances, viewProjection: view.viewProjection, eye: view.eye,
                           reversedZ: view.reversedZ, frame: frame)
        return PostProcessor.Depth(texture: texture, projection: view.projection)
    }
}
