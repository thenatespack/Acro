import Foundation

// Skybox and image-based lighting for `SceneRenderer` (see `SceneEnvironment.sky`).
//
// Layout: the device has 2D textures only, so everything is equirectangular (no cube maps). An
// environment is precomputed into one RGBA16F atlas (`EnvironmentAtlas`) with fragment passes,
// whenever its source changes (a new map, or the procedural sky's parameters or sun):
//
// 1. env_base: the source as a 512x256 image: an HDR map read at the matching mip level, or the
//    procedural sky without the sun's disk (the directional light already lights with it).
// 2. env_prefilter, five times: radiance prefiltered for roughness 0.2 ... 1, each level half the
//    size of the previous one and convolved from it with the GGX lobe that adds the missing
//    width (progressive, so a fixed set of 256 samples is noise-free).
// 3. env_downsample + env_sh: diffuse irradiance as nine SH coefficients (SH9), projected from a
//    64x32 solid-angle-weighted reduction of the base image.
// 4. env_pack: one pass copying every level and the SH row into the atlas, the one texture
//    mesh_surface.glsl reads (texture 6).
//
// Every precomputation step reads texels with loads and fixed weights (bilinear filtering of
// the equirectangular images is done in the shader, wrapping horizontally), except the map's
// trilinear read in step 1, and uses a fixed Hammersley sequence, so it is deterministic and
// identical on Metal and Vulkan. The split-sum BRDF table (texture 7) doesn't depend on the
// environment: it is computed once on the CPU (`EnvironmentMath.brdfLUT`), so the tests check
// the very values the shader samples.
//
// Intensity and rotation are applied at lookup, so animating them costs nothing. A procedural
// sky whose sun moves every frame is precomputed every frame (about a millisecond of GPU time).

/// Where `EnvironmentLighting` puts each prefiltered level and the SH coefficients in its atlas.
/// Must match environment.glsl.
public enum EnvironmentAtlas {
    public static let width = 512
    public static let height = 384
    /// Prefiltered radiance levels (equirectangular), sharpest first: atlas rectangle in texels.
    public static let levels: [(x: Int, y: Int, width: Int, height: Int)] = [
        (0, 0, 512, 256), (0, 256, 256, 128), (256, 256, 128, 64), (384, 256, 64, 32), (448, 256, 32, 16), (480, 256, 16, 8),
    ]
    /// The perceptual roughness each level is prefiltered for (level i: i / 5).
    public static func roughness(level: Int) -> Float { Float(level) / Float(levels.count - 1) }
    /// The first of the nine SH irradiance coefficients (one row).
    public static let sh = (x: 496, y: 256)
    /// Size of the reduction the SH coefficients are projected from.
    public static let shSource = (width: 64, height: 32)

    /// The GGX alpha that level `level` adds to the previous level's blur:
    /// sqrt(alpha_level² - alpha_previous²), with alpha = roughness².
    public static func incrementalAlpha(level: Int) -> Float {
        let a = roughness(level: level) * roughness(level: level)
        let p = level > 0 ? roughness(level: level - 1) * roughness(level: level - 1) : 0
        return (a * a - p * p).squareRoot()
    }
}

/// The math behind image-based lighting on the CPU: the equirectangular mapping, SH9 irradiance
/// and the split-sum BRDF. The shaders implement the same (environment.glsl, env_sh.frag,
/// mesh_surface.glsl), and `brdfLUT` is the table they sample.
public enum EnvironmentMath {
    /// Side of the BRDF table: NoV across, perceptual roughness down, both 0...1 at texel centers.
    public static let brdfLUTSize = 32
    /// Samples per texel of the BRDF table.
    public static let brdfSamples = 512

    /// Equirectangular coordinates of direction `d`: u = 0.5 looks down -Z and grows toward +X,
    /// v = 0 is straight up.
    public static func equirectUV(_ d: Vec3) -> Vec2 {
        Vec2(atan2f(d.x, -d.z) * (0.5 / .pi) + 0.5, acosf(min(max(d.y, -1), 1)) / .pi)
    }

    /// The direction at equirectangular coordinates `uv` (inverse of `equirectUV`).
    public static func equirectDirection(_ uv: Vec2) -> Vec3 {
        let phi = (uv.x - 0.5) * 2 * .pi, theta = uv.y * .pi
        return Vec3(sinf(theta) * sinf(phi), cosf(theta), -sinf(theta) * cosf(phi))
    }

    /// The real spherical harmonics of bands 0-2 at unit direction `d`.
    public static func shBasis(_ d: Vec3) -> [Float] {
        [0.282095,
         0.488603 * d.y, 0.488603 * d.z, 0.488603 * d.x,
         1.092548 * d.x * d.y, 1.092548 * d.y * d.z, 0.315392 * (3 * d.z * d.z - 1), 1.092548 * d.x * d.z,
         0.546274 * (d.x * d.x - d.y * d.y)]
    }

    /// The clamped-cosine convolution per band divided by pi (pi, 2pi/3, pi/4 over pi).
    static func bandScale(_ k: Int) -> Float { k == 0 ? 1 : (k < 4 ? 2.0 / 3.0 : 0.25) }

    /// Diffuse irradiance / pi of the environment `radiance` as SH9 coefficients, as env_sh.frag
    /// computes them: `radiance` sampled at the centers of a `width` x `height`
    /// equirectangular grid, each weighted by its texel's exact solid angle.
    public static func projectIrradianceSH(width: Int, height: Int, radiance: (Vec3) -> Vec3) -> [Vec3] {
        var sum = [Vec3](repeating: .zero, count: 9)
        let dphi = 2 * Float.pi / Float(width)
        for y in 0..<height {
            let dw = dphi * (cosf(Float(y) / Float(height) * .pi) - cosf(Float(y + 1) / Float(height) * .pi))
            for x in 0..<width {
                let d = equirectDirection((Vec2(Float(x), Float(y)) + 0.5) / Vec2(Float(width), Float(height)))
                let l = radiance(d) * dw
                for (k, basis) in shBasis(d).enumerated() { sum[k] += l * basis }
            }
        }
        return sum.enumerated().map { $1 * bandScale($0) }
    }

    /// Irradiance / pi at normal `n` from SH9 coefficients (`projectIrradianceSH`): what a
    /// white Lambert surface reflects.
    public static func irradiance(_ sh: [Vec3], normal n: Vec3) -> Vec3 {
        let sum = zip(sh, shBasis(n)).reduce(Vec3.zero) { $0 + $1.0 * $1.1 }
        return Vec3(max(sum.x, 0), max(sum.y, 0), max(sum.z, 0))
    }

    /// The i-th of n points of the Hammersley set: (i / n, radical inverse of i in base 2).
    public static func hammersley(_ i: Int, _ n: Int) -> Vec2 {
        var bits = UInt32(truncatingIfNeeded: i)
        bits = (bits << 16) | (bits >> 16)
        bits = ((bits & 0x5555_5555) << 1) | ((bits & 0xAAAA_AAAA) >> 1)
        bits = ((bits & 0x3333_3333) << 2) | ((bits & 0xCCCC_CCCC) >> 2)
        bits = ((bits & 0x0F0F_0F0F) << 4) | ((bits & 0xF0F0_F0F0) >> 4)
        bits = ((bits & 0x00FF_00FF) << 8) | ((bits & 0xFF00_FF00) >> 8)
        return Vec2(Float(i) / Float(n), Float(Double(bits) * 2.3283064365386963e-10))
    }

    /// A GGX-distributed half vector for `xi` around +Z (tangent space), alpha = roughness².
    static func importanceSampleGGX(_ xi: Vec2, alpha: Float) -> Vec3 {
        let a2 = alpha * alpha
        let phi = 2 * Float.pi * xi.x
        let cosTheta = ((1 - xi.y) / (1 + (a2 - 1) * xi.y)).squareRoot()
        let sinTheta = max(1 - cosTheta * cosTheta, 0).squareRoot()
        return Vec3(sinTheta * cosf(phi), sinTheta * sinf(phi), cosTheta)
    }

    /// Height-correlated Smith visibility G / (4 NoL NoV), as in mesh_surface.glsl.
    static func visibility(NoV: Float, NoL: Float, alpha: Float) -> Float {
        let a2 = alpha * alpha
        let v = NoL * (NoV * NoV * (1 - a2) + a2).squareRoot()
        let l = NoV * (NoL * NoL * (1 - a2) + a2).squareRoot()
        return 0.5 / max(v + l, 1e-5)
    }

    /// The split-sum environment BRDF (Karis 2013) for the engine's GGX: the scale A and bias B
    /// with which the specular reflection of a uniform white environment is F0 x A + B.
    public static func environmentBRDF(NoV: Float, roughness: Float, samples: Int = brdfSamples) -> Vec2 {
        let NoV = max(NoV, 1e-4)
        let alpha = max(roughness * roughness, 1e-4)
        let v = Vec3((1 - NoV * NoV).squareRoot(), 0, NoV)
        var a: Float = 0, b: Float = 0
        for i in 0..<samples {
            let h = importanceSampleGGX(hammersley(i, samples), alpha: alpha)
            let VoH = dot(v, h)
            let l = 2 * VoH * h - v
            guard l.z > 0, VoH > 0 else { continue }
            // Sample weight: BRDF x NoL / pdf, with pdf = D NoH / (4 VoH) and F factored out.
            let w = visibility(NoV: NoV, NoL: l.z, alpha: alpha) * 4 * VoH * l.z / h.z
            let fc = powf(1 - VoH, 5)
            a += (1 - fc) * w
            b += fc * w
        }
        return Vec2(a, b) / Float(samples)
    }

    /// The BRDF table: `brdfLUTSize`² entries, row = roughness, column = NoV, both
    /// index / (size - 1). Computed once.
    public static let brdfLUT: [Vec2] = {
        let n = brdfLUTSize
        return (0..<n * n).map { i in
            environmentBRDF(NoV: Float(i % n) / Float(n - 1), roughness: Float(i / n) / Float(n - 1))
        }
    }()
}

/// Uniform buffer 2 of sky.vert / sky.frag and env_base.frag (sky_common.glsl).
struct SkyUniforms: BitwiseCopyable, Equatable {
    var inverseViewProj = Mat4.identity
    /// x: 1 map, 0 procedural; y: intensity; z, w: cos, sin of the rotation.
    var params = Vec4.zero
    /// x: far-plane depth; y: map mip level (env_base); zw: target size (env_base).
    var extra = Vec4.zero
    var zenith = Vec4.zero
    var horizon = Vec4.zero
    var ground = Vec4.zero
    var sunDirection = Vec4.zero
    var sunColor = Vec4.zero
    /// x, y: cos of the disk's outer / inner edge, z: disk radiance scale, w: glow.
    var sun = Vec4.zero
}

/// Draws `SceneEnvironment`'s sky and precomputes its image-based lighting for `SceneRenderer`
/// (see the comment at the top of this file). Pipelines and targets are created on first use, so
/// scenes without a sky pay nothing.
@MainActor
final class EnvironmentLighting {
    let device: RenderDevice

    /// The frame's sky, from `prepare`; nil draws none (`SkyMode.color`, or the map isn't available).
    private(set) var sky: (uniforms: SkyUniforms, map: GPUTexture?)?
    /// `frame.environment` for the mesh shaders: x 1 while the sky lights the scene.
    private(set) var lighting = Vec4.zero
    /// What the atlas holds, and what this frame needs.
    private var computed: SourceKey?
    private var wanted: SourceKey?

    private struct SourceKey: Equatable {
        var map: ObjectIdentifier?
        var procedural: SkyUniforms?
    }

    private struct Pipelines {
        var base, prefilter, downsample, sh, pack: RenderPipeline
    }

    private struct Targets {
        var levels: [GPURenderTarget]
        var reduced: GPURenderTarget
        var sh: GPURenderTarget
        var atlas: GPURenderTarget
    }

    private var pipelines: Pipelines?
    private var targets: Targets?
    private var skyPipelines: [Bool: RenderPipeline] = [:]
    private var brdfTable: GPUTexture?
    private var failed = false
    private let pointSampler: GPUSampler
    private let linearSampler: GPUSampler
    private let mapSampler: GPUSampler
    /// Bound for unused inputs (Vulkan wants every declared binding valid).
    private let placeholder: GPUTexture

    /// Prefiltering samples per texel (env_prefilter.frag).
    static let prefilterSamples = 256

    /// The atlas `render` fills (nil until the first `prepare` with image-based lighting).
    var atlasTexture: GPUTexture? { targets?.atlas.texture }

    init(device: RenderDevice, placeholder: GPUTexture) throws {
        self.device = device
        self.placeholder = placeholder
        pointSampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
        linearSampler = try device.makeSampler(SamplerDescriptor(filter: .linear))
        mapSampler = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat))
    }

    /// Sets up the frame's sky from `environment`: `map` is its resolved `environmentMap`, the
    /// light the first directional light (toward it; color x intensity), which the procedural
    /// sun follows. Creates what the sky needs on first use.
    func prepare(_ environment: SceneEnvironment, map: GPUTexture?, toLight: Vec3, lightColor: Vec3) {
        sky = nil
        lighting = .zero
        wanted = nil
        guard !failed, environment.sky != .color, environment.sky == .procedural || map != nil else { return }
        var u = SkyUniforms()
        if environment.sky == .map {
            u.params = Vec4(1, environment.environmentIntensity, cosf(environment.environmentRotation), sinf(environment.environmentRotation))
        } else {
            let p = environment.proceduralSky
            u.params = Vec4(0, environment.environmentIntensity, 1, 0)
            u.zenith = Vec4(p.zenithColor, 0)
            u.horizon = Vec4(p.horizonColor, 0)
            u.ground = Vec4(p.groundColor, 0)
            u.sunDirection = Vec4(normalize(toLight), 0)
            u.sunColor = Vec4(lightColor, 0)
            u.sun = Vec4(cosf(p.sunSize * 1.15), cosf(p.sunSize * 0.85), p.sunIntensity, p.sunGlow)
        }
        sky = (u, environment.sky == .map ? map : nil)
        guard environment.imageBasedLighting else { return }
        do {
            try makeResources()
        } catch {
            print("SceneRenderer: image-based lighting unavailable: \(error)")
            failed = true
            return
        }
        var key = SourceKey(map: map.map(ObjectIdentifier.init))
        if environment.sky == .procedural {
            var source = u
            source.params = .zero  // intensity and rotation apply at lookup
            key = SourceKey(map: nil, procedural: source)
        }
        wanted = key
        lighting = Vec4(1, u.params.y, u.params.z, u.params.w)
    }

    private func makeResources() throws {
        if pipelines == nil {
            func pipeline(_ fragment: String) throws -> RenderPipeline {
                var descriptor = PipelineDescriptor(
                    shader: try ShaderSource.load(vertex: "post", fragment: fragment, bundle: .module), vertexLayout: .none)
                descriptor.target = .color(.rgba16Float)
                descriptor.cullMode = .none
                descriptor.depthTest = false
                descriptor.depthWrite = false
                return try device.makePipeline(descriptor)
            }
            pipelines = Pipelines(base: try pipeline("env_base"), prefilter: try pipeline("env_prefilter"),
                                  downsample: try pipeline("env_downsample"), sh: try pipeline("env_sh"), pack: try pipeline("env_pack"))
        }
        if targets == nil {
            func target(_ width: Int, _ height: Int) throws -> GPURenderTarget {
                try device.makeRenderTarget(.color(width: width, height: height, format: .rgba16Float))
            }
            targets = Targets(levels: try EnvironmentAtlas.levels.map { try target($0.width, $0.height) },
                              reduced: try target(EnvironmentAtlas.shSource.width, EnvironmentAtlas.shSource.height),
                              sh: try target(9, 1), atlas: try target(EnvironmentAtlas.width, EnvironmentAtlas.height))
        }
        if brdfTable == nil {
            let pixels = EnvironmentMath.brdfLUT.flatMap { [$0.x, $0.y, 0, 1] as [Float] }
            let size = EnvironmentMath.brdfLUTSize
            brdfTable = try device.makeTexture(image: FloatImage(width: size, height: size, pixels: pixels), generateMipmaps: false)
        }
    }

    /// Records the precomputation passes when the frame's environment differs from what the
    /// atlas holds. Call between `prepare` and the screen pass, outside any pass.
    func render() {
        guard let wanted, wanted != computed, let pipelines, let targets, let sky else { return }
        let levels = targets.levels
        var base = sky.uniforms
        let width = Float(levels[0].width), height = Float(levels[0].height)
        if let map = sky.map {
            let lod = min(max(log2f(Float(map.width) / width), 0), Float(map.mipLevelCount - 1))
            base.extra = Vec4(0, lod, width, height)
        } else {
            base.extra = Vec4(0, 0, width, height)
        }
        fullscreen(into: levels[0], pipeline: pipelines.base, source: sky.map ?? placeholder, sampler: mapSampler) { pass in
            pass.setUniformData(base, index: 2, stage: .fragment)
        }
        for level in 1..<levels.count {
            let source = levels[level - 1], target = levels[level]
            fullscreen(into: target, pipeline: pipelines.prefilter, source: source.texture, sampler: pointSampler) { pass in
                pass.setPushConstants(PrefilterConstants(
                    sourceSize: SIMD2(Int32(source.width), Int32(source.height)), size: SIMD2(Float(target.width), Float(target.height)),
                    alpha: EnvironmentAtlas.incrementalAlpha(level: level), samples: Int32(Self.prefilterSamples)))
            }
        }
        let factor = levels[0].width / targets.reduced.width
        fullscreen(into: targets.reduced, pipeline: pipelines.downsample, source: levels[0].texture, sampler: pointSampler) { pass in
            pass.setPushConstants(SIMD2(Int32(factor), Int32(levels[0].height)))
        }
        fullscreen(into: targets.sh, pipeline: pipelines.sh, source: targets.reduced.texture, sampler: pointSampler) { pass in
            pass.setPushConstants(SIMD2(Int32(targets.reduced.width), Int32(targets.reduced.height)))
        }
        // Every region in one pass (a pass's attachment starts undefined, so the atlas can't be
        // filled over several).
        let pass = device.beginPass(target: targets.atlas, clearColor: .zero, clearDepth: 1, label: "environment")
        pass.setPipeline(pipelines.pack)
        pass.setSampler(pointSampler, index: 1)
        var regions = zip(levels, EnvironmentAtlas.levels).map { ($0.texture, $1.x, $1.y, $1.width, $1.height) }
        regions.append((targets.sh.texture, EnvironmentAtlas.sh.x, EnvironmentAtlas.sh.y, 9, 1))
        for (texture, x, y, w, h) in regions {
            pass.setScissorRect(ScissorRect(x: x, y: y, width: w, height: h))
            pass.setTexture(texture, index: 1)
            pass.setPushConstants(SIMD2(Int32(x), Int32(y)))
            pass.draw(vertexCount: 3)
        }
        device.endPass()
        computed = wanted
    }

    /// One fullscreen triangle into `target` reading `source` as texture 1.
    private func fullscreen(into target: GPURenderTarget, pipeline: RenderPipeline, source: GPUTexture, sampler: GPUSampler,
                            _ setup: (RenderPass) -> Void) {
        let pass = device.beginPass(target: target, clearColor: .zero, clearDepth: 1, label: "environment")
        pass.setPipeline(pipeline)
        pass.setTexture(source, index: 1)
        pass.setSampler(sampler, index: 1)
        setup(pass)
        pass.draw(vertexCount: 3)
        device.endPass()
    }

    /// Binds the atlas (texture 6), the BRDF table (texture 7) and its sampler (7) for the mesh
    /// shaders, or placeholders when the sky doesn't light the scene.
    func bindLighting(in pass: RenderPass) {
        let active = lighting.x > 0
        pass.setTexture(active ? targets?.atlas.texture ?? placeholder : placeholder, index: 6)
        pass.setTexture(active ? brdfTable ?? placeholder : placeholder, index: 7)
        pass.setSampler(linearSampler, index: 7)
    }

    /// Draws the sky where nothing nearer was drawn, for a view with `view` and `projection`
    /// (jittered like the scene). Binds uniform buffer 2, texture 1 and sampler 1.
    func drawSky(in pass: RenderPass, view: Mat4, projection: Mat4, reversedZ: Bool) {
        guard let sky, let pipeline = skyPipeline(reversedZ: reversedZ) else { return }
        var rotation = view
        rotation.c3 = Vec4(0, 0, 0, 1)
        var u = sky.uniforms
        u.inverseViewProj = (projection * rotation).inverse
        u.extra = Vec4(reversedZ ? 0 : 1, 0, 0, 0)
        pass.setPipeline(pipeline)
        pass.setUniformData(u, index: 2)
        pass.setTexture(sky.map ?? placeholder, index: 1)
        pass.setSampler(mapSampler, index: 1)
        pass.draw(vertexCount: 3)
    }

    private func skyPipeline(reversedZ: Bool) -> RenderPipeline? {
        if let pipeline = skyPipelines[reversedZ] { return pipeline }
        do {
            var descriptor = PipelineDescriptor(shader: try ShaderSource.load(named: "sky", bundle: .module), vertexLayout: .none)
            descriptor.cullMode = .none
            descriptor.depthWrite = false
            descriptor.depthCompare = reversedZ ? .greaterEqual : .lessEqual
            descriptor.writesMotionVectors = true
            let pipeline = try device.makePipeline(descriptor)
            skyPipelines[reversedZ] = pipeline
            return pipeline
        } catch {
            print("SceneRenderer: sky pipeline creation failed: \(error)")
            sky = nil
            failed = true
            return nil
        }
    }
}

/// Must match the push constants of env_prefilter.frag (std430).
struct PrefilterConstants {
    var sourceSize: SIMD2<Int32>
    var size: SIMD2<Float>
    var alpha: Float
    var samples: Int32
}
