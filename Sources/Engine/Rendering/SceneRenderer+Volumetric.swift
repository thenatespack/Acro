import Foundation

/// `SceneRenderer`'s volumetric fog (`SceneEnvironment.volumetricFog`, volumetric_fog.frag).
///
/// `prepare` decides whether it runs this frame: it needs fog, a post-processing pipeline (it
/// turns the HDR path on) and the main camera. `renderShadows` then renders the camera's depth
/// prepass (shared with the particles' when they made one), and `PostProcessor` calls
/// `runVolumetricFog` on the HDR scene image before bloom, exposure and tonemapping, which
/// marches the fog into a copy of it. Without the setting nothing extra is created or drawn.
@MainActor
final class VolumetricFogState {
    struct Setup {
        var uniforms: SceneRenderer.FrameUniforms
        var lights: LightClusters.GPUData?
        var settings: VolumetricFog
        var reversedZ: Bool
        var size: (width: Int, height: Int)
    }

    var setup: Setup?
    /// The prepass depth of this frame, once `renderShadows` has rendered it.
    var depth: GPUTexture?
    var pipeline: RenderPipeline?
    var pipelineFailed = false
    var sampler: GPUSampler?
    var target: GPURenderTarget?
}

/// Must match the push constants of volumetric_fog.frag.
struct VolumetricFogConstants {
    var inverseViewProj: Mat4
    /// x: intensity, y: anisotropy, z: max distance, w: steps.
    var params: Vec4
    /// x: reversed-Z, y: scatter point / spot lights.
    var flags: Vec4
}

extension SceneRenderer {
    /// Called at the end of `prepare` with the final frame uniforms: schedules the fog pass on
    /// `engine`'s post-processor, or clears it.
    func prepareVolumetricFog(environment: SceneEnvironment, engine: Engine, size: (width: Int, height: Int)) {
        volumetric.setup = nil
        volumetric.depth = nil
        engine.postProcessor?.sceneEffect = nil
        guard environment.volumetricFog.enabled, environment.fogDensity > 0, size.width > 0, size.height > 0,
              let postProcessor = engine.postProcessor, let uniforms, !volumetric.pipelineFailed else { return }
        var settings = environment.volumetricFog
        settings.steps = min(max(settings.steps, 8), 128)
        settings.anisotropy = min(max(settings.anisotropy, -0.95), 0.95)
        settings.maxDistance = max(settings.maxDistance, 1)
        // The pass needs the HDR scene image.
        if engine.postProcess == nil { engine.postProcess = .passthrough }
        volumetric.setup = .init(uniforms: uniforms, lights: settings.localLights && !clusters.isEmpty ? lightData : nil,
                                 settings: settings, reversedZ: reversedZ, size: size)
        postProcessor.sceneEffect = { [weak self] scene in self?.runVolumetricFog(scene: scene) }
    }

    /// Renders the camera's depth for the fog pass (the particles' prepass if they made one).
    func renderVolumetricDepth(frame: Frame) {
        guard let setup = volumetric.setup else { return }
        if let particleDepth {
            volumetric.depth = particleDepth.texture
            return
        }
        guard let texture = depthTexture(&particleDepthTexture, size: setup.size) else {
            volumetric.setup = nil
            return
        }
        renderDepthPrepass(into: texture, list: list, instances: uploaded, viewProjection: setup.uniforms.viewProj,
                           reversedZ: setup.reversedZ, frame: frame)
        volumetric.depth = texture
    }

    /// Draws the fog over `scene` into a target of its size and returns it (nil leaves the scene as is).
    func runVolumetricFog(scene: GPUTexture) -> GPUTexture? {
        guard let setup = volumetric.setup, let depth = volumetric.depth, setup.size.width == scene.width,
              setup.size.height == scene.height else { return nil }
        do {
            if volumetric.pipeline == nil {
                var descriptor = PipelineDescriptor(
                    shader: try ShaderSource.load(vertex: "post", fragment: "volumetric_fog", bundle: .module), vertexLayout: .none)
                descriptor.target = .color(.rgba16Float)
                descriptor.cullMode = .none
                descriptor.depthTest = false
                descriptor.depthWrite = false
                volumetric.pipeline = try device.makePipeline(descriptor)
                volumetric.sampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
            }
            if volumetric.target.map({ $0.texture.width != scene.width || $0.texture.height != scene.height }) ?? true {
                volumetric.target = try device.makeRenderTarget(.color(width: scene.width, height: scene.height, format: .rgba16Float))
            }
        } catch {
            print("SceneRenderer: volumetric fog unavailable: \(error)")
            volumetric.pipelineFailed = true
            volumetric.setup = nil
            return nil
        }
        guard let pipeline = volumetric.pipeline, let sampler = volumetric.sampler, let target = volumetric.target else { return nil }
        let pass = device.beginPass(target: target, clearColor: .zero, clearDepth: 1, label: "volumetric fog")
        pass.setPipeline(pipeline)
        pass.setUniforms(setup.uniforms)
        bindLights(setup.lights, in: pass)
        pass.setTexture(scene, index: 1)
        pass.setTexture(depth, index: 2)
        pass.setTexture(shadowMap, index: 3, stage: .fragment)
        pass.setSampler(sampler, index: 1)
        pass.setPushConstants(VolumetricFogConstants(
            inverseViewProj: setup.uniforms.viewProj.inverse,
            params: Vec4(setup.settings.intensity, setup.settings.anisotropy, setup.settings.maxDistance, Float(setup.settings.steps)),
            flags: Vec4(setup.reversedZ ? 1 : 0, setup.settings.localLights ? 1 : 0, 0, 0)))
        pass.draw(vertexCount: 3)
        device.endPass()
        return target.texture
    }
}
