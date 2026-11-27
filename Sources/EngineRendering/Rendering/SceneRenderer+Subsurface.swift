#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

/// `SceneRenderer`'s screen-space subsurface scattering (separable SSS, Jimenez et al. 2015) for
/// skin materials (`Material.subsurface`, MaterialSkin.swift; shaders skin.glsl and
/// subsurface_blur.frag).
///
/// How it fits the forward MSAA renderer without a second color target: the skin shader writes
/// the pixel's full lighting as usual and puts -(1 + its specular luminance) in alpha. The HDR
/// scene's MSAA resolve averages that like any color, so the pass that runs on the resolved image
/// (`PostProcessor.sceneEffect`, before volumetric fog, depth of field, bloom and tonemapping) can
/// tell marked pixels apart and split off the diffuse light (rgb minus the near-white specular),
/// blur it horizontally then vertically with the skin kernel and add the specular back. Distance
/// scaling and follow-surface need depth: the particles', volumetric fog's or depth of field's
/// prepass when the frame has one, else a prepass of just the skin batches (an unmarked pixel in
/// front of skin needs no depth: the mask already keeps it out).
///
/// `prepare` sets it up only when the main camera sees an opaque material that scatters, the mode
/// is `.screen` (`ENGINE_SSS`, and not WebGL 2 or low quality: those pre-integrate in the material
/// shader) and there is a post-processor (it turns the HDR path on, as volumetric fog does). One
/// kernel per frame: the first such material's strength, falloff and radius (a gap: several skin
/// profiles in one frame share the first one's). Frames without skin run nothing extra.
@MainActor
final class SubsurfaceState {
    struct Setup {
        var settings: MaterialSubsurface
        var projection: Mat4
        var viewProjection: Mat4
        var eye: Vec3
        var reversedZ: Bool
        var size: (width: Int, height: Int)
        var taps: Int
    }

    var setup: Setup?
    /// True while `draw(_:)` draws the main view of a frame the pass runs on: opaque skin marks its pixels.
    var encodes = false
    /// This frame's depth for the pass (shared or `ownDepth`).
    var depth: GPUTexture?
    var ownDepth: GPUTexture?
    var pipeline: RenderPipeline?
    var pipelineFailed = false
    var sampler: GPUSampler?
    var targets: [GPURenderTarget] = []
    var kernel: (strength: Vec3, falloff: Vec3, count: Int, taps: [Vec4])?
    /// mesh_skin(_probes).frag after mesh(_skinned).vert, by skinned x 2 + probes.
    var shaders: [Int: ShaderSource] = [:]
    /// `ENGINE_SSS`, read once.
    let environmentMode = SubsurfaceMode.environment(ProcessInfo.processInfo.environment["ENGINE_SSS"])

    /// How skin scatters on `device` at `quality`: `ENGINE_SSS` if set, else pre-integrated on
    /// WebGL 2 and at low quality, the screen pass elsewhere.
    func mode(for device: RenderDevice, quality: RenderQuality) -> SubsurfaceMode {
        if let environmentMode { return environmentMode }
        return device.backend == .webgl2 || quality == .low ? .preintegrated : .screen
    }
}

/// Must match the push constants of subsurface_blur.frag.
struct SubsurfaceBlurConstants {
    var linearize: SIMD4<Float>
    /// x: focal length in pixels, y: meters per profile millimeter, z: taps, w: 1 the second pass.
    var params: SIMD4<Float>
    /// xy: pixel step, z: follow-surface scale (1 / m).
    var direction: SIMD4<Float>
    var maxTexel: SIMD4<Int32>
}

extension SceneRenderer {
    /// The most taps subsurface_blur.frag's kernel block holds.
    static let subsurfaceMaxTaps = 25

    /// The skin shader variant (mesh_skin.frag, or mesh_skin_probes.frag while the frame has probes).
    func skinShader(skinned: Bool, probes: Bool) -> ShaderSource? {
        let key = (skinned ? 2 : 0) + (probes ? 1 : 0)
        if let shader = subsurface.shaders[key] { return shader }
        do {
            let shader = try ShaderSource.load(vertex: skinned ? "mesh_skinned" : "mesh", fragment: probes ? "mesh_skin_probes" : "mesh_skin",
                                               bundle: .engineResources)
            subsurface.shaders[key] = shader
            return shader
        } catch {
            print("SceneRenderer: skin shader unavailable: \(error)")
            return nil
        }
    }

    /// Called at the end of `prepare`: sets the pass up when the main view has opaque skin (see `SubsurfaceState`).
    func prepareSubsurface(engine: some SceneRenderHost, projection: Mat4, viewProjection: Mat4, eye: Vec3, reversedZ: Bool,
                           size: (width: Int, height: Int)) {
        subsurface.setup = nil
        subsurface.depth = nil
        guard size.width > 0, size.height > 0, !subsurface.pipelineFailed, let postProcessor = engine.postProcessor,
              subsurface.mode(for: device, quality: quality) == .screen,
              let batch = list.opaque.first(where: { materials[$0.material].material.scattersInScreenSpace }),
              let settings = materials[batch.material].material.subsurface else { return }
        // The pass needs the HDR scene image.
        if engine.postProcess == nil { engine.postProcess = .passthrough }
        subsurface.setup = .init(settings: settings, projection: projection, viewProjection: viewProjection, eye: eye,
                                 reversedZ: reversedZ, size: size, taps: quality == .ultra ? 17 : 11)
        // Before volumetric fog (and everything after it).
        let next = postProcessor.sceneEffect
        postProcessor.sceneEffect = { [weak self] scene in
            let scattered = self?.runSubsurface(scene: scene)
            return next?(scattered ?? scene) ?? scattered
        }
    }

    /// The depth the pass reads (called by `renderShadows` after the other prepasses).
    func renderSubsurfaceDepth(frame: Frame) {
        guard let setup = subsurface.setup else { return }
        if let shared = particleDepth?.texture ?? volumetric.depth ?? depthOfField.postProcessor?.sceneDepth?.texture,
           shared.width == setup.size.width, shared.height == setup.size.height {
            subsurface.depth = shared
            return
        }
        guard let texture = depthTexture(&subsurface.ownDepth, size: setup.size) else {
            subsurface.setup = nil
            return
        }
        renderDepthPrepass(into: texture, list: list, instances: uploaded, viewProjection: setup.viewProjection, eye: setup.eye,
                           reversedZ: setup.reversedZ, frame: frame, only: { $0.scattersInScreenSpace })
        subsurface.depth = texture
    }

    /// The kernel for `settings` (cached while it doesn't change), padded to `subsurfaceMaxTaps`.
    func subsurfaceKernel(_ settings: MaterialSubsurface, count: Int) -> [Vec4] {
        let strength = settings.channelStrength
        if let kernel = subsurface.kernel, kernel.strength == strength, kernel.falloff == settings.falloff, kernel.count == count {
            return kernel.taps
        }
        var taps = SubsurfaceKernel(strength: strength, falloff: settings.falloff, count: count).taps
        taps += [Vec4](repeating: .zero, count: max(Self.subsurfaceMaxTaps - taps.count, 0))
        subsurface.kernel = (strength, settings.falloff, count, taps)
        return taps
    }

    /// Scatters the marked pixels of `scene` in two passes and returns the result (nil: unchanged).
    func runSubsurface(scene: GPUTexture) -> GPUTexture? {
        guard let setup = subsurface.setup, let depth = subsurface.depth, setup.size.width == scene.width,
              setup.size.height == scene.height, depth.width == scene.width, depth.height == scene.height else { return nil }
        do {
            if subsurface.pipeline == nil {
                var descriptor = PipelineDescriptor(
                    shader: try ShaderSource.load(vertex: "post", fragment: "subsurface_blur", bundle: .engineResources), vertexLayout: .none)
                descriptor.target = .color(.rgba16Float)
                descriptor.cullMode = .none
                descriptor.depthTest = false
                descriptor.depthWrite = false
                subsurface.pipeline = try device.makePipeline(descriptor)
                subsurface.sampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
            }
            if subsurface.targets.count != 2 || subsurface.targets[0].texture.width != scene.width
                || subsurface.targets[0].texture.height != scene.height {
                subsurface.targets = try (0..<2).map { _ in
                    try device.makeRenderTarget(.color(width: scene.width, height: scene.height, format: .rgba16Float))
                }
            }
        } catch {
            print("SceneRenderer: subsurface scattering unavailable: \(error)")
            subsurface.pipelineFailed = true
            subsurface.setup = nil
            return nil
        }
        guard let pipeline = subsurface.pipeline, let sampler = subsurface.sampler else { return nil }
        let taps = subsurfaceKernel(setup.settings, count: setup.taps)
        let inverse = setup.projection.inverse
        let focal = 0.5 * Float(scene.height) * abs(setup.projection.c1.y)
        let radius = max(setup.settings.radius, 1e-5)
        var input = scene
        for (i, target) in subsurface.targets.enumerated() {
            let pass = device.beginPass(target: target, clearColor: .zero, clearDepth: 1, label: i == 0 ? "subsurface x" : "subsurface y")
            pass.setPipeline(pipeline)
            pass.setTexture(input, index: 1)
            pass.setTexture(depth, index: 2)
            pass.setSampler(sampler, index: 1)
            taps.withUnsafeBytes { pass.setUniformData($0, index: 2, stage: .fragment) }
            pass.setPushConstants(SubsurfaceBlurConstants(
                linearize: SIMD4(inverse.c2.z, inverse.c3.z, inverse.c2.w, inverse.c3.w),
                params: SIMD4(focal, radius * 0.5, Float(setup.taps), Float(i)),
                direction: SIMD4(i == 0 ? 1 : 0, i == 0 ? 0 : 1, 1 / (8 * radius), 0),
                maxTexel: SIMD4(Int32(scene.width - 1), Int32(scene.height - 1), 0, 0)))
            pass.draw(vertexCount: 3)
            device.endPass()
            input = target.texture
        }
        return input
    }
}
