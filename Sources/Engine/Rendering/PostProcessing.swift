import Foundation

/// How the HDR scene is turned into the displayed image: exposure (manual and automatic),
/// bloom and a tonemapping curve. Set `Engine.postProcess` to use it; `SceneRenderer` does that
/// every frame from the world's `PostProcess` component (this type, under that name), so adding
/// one to an entity opts the scene in and the editor's inspector shows its fields.
///
/// With post-processing the scene pass renders linear light into an RGBA16F image; then
/// `PostProcessor` runs bloom and auto-exposure passes and a final pass that applies exposure,
/// bloom and the tonemapper and writes the sRGB image that the upscalers and the window see.
public struct PostProcessSettings: Component, Codable, Equatable, Sendable {
    public static let componentName = "PostProcess"

    /// Maps scene radiance (after exposure) to display values in 0...1.
    public enum Tonemapper: String, Codable, CaseIterable, Sendable {
        /// Clamps to 0...1: what the scene looked like without post-processing (for debugging).
        case none
        /// `x / (1 + x)` per channel: soft, desaturates highlights little, never reaches 1.
        case reinhard
        /// Khronos PBR Neutral: nearly linear (colors match the material's base color) up to
        /// about 0.76, then compresses highlights toward white without hue shifts.
        case neutral
        /// ACES filmic (Stephen Hill's RRT+ODT fit): contrasty, saturated, film-like toe and shoulder.
        case aces
    }

    public var tonemapper: Tonemapper
    /// Exposure compensation in EV (stops): the scene is scaled by 2^exposure before
    /// tonemapping (on top of auto exposure when that is on).
    public var exposure: Float
    /// Adapt the exposure to the scene's average luminance (log-average over a coarse grid,
    /// mapped to middle gray), smoothly over time. The first frame converges at once, so
    /// screenshots are deterministic.
    public var autoExposure: Bool
    /// The range auto exposure stays in, in EV.
    public var autoExposureMin: Float
    public var autoExposureMax: Float
    /// How fast auto exposure adapts, per second (the remaining difference shrinks by
    /// e^(-speed · dt) each frame).
    public var adaptationSpeed: Float
    /// Bloom: a wide, energy-conserving blur of the HDR scene mixed in by `bloomIntensity`
    /// (no threshold: everything blooms in proportion to its brightness, so only very bright
    /// pixels, such as emissive materials and the sun's specular highlights, visibly glow).
    /// Off on the low quality preset (`RenderQuality.bloom`).
    public var bloom: Bool
    /// Fraction of the bloom image in the result (0...1).
    public var bloomIntensity: Float
    /// Color grading, applied after tonemapping: contrast around middle gray, then lift (raises
    /// the shadows), gamma (per-channel midtone exponent, 1 = unchanged, higher brightens) and
    /// gain (per-channel multiplier), then saturation (1 = unchanged, 0 = gray).
    public var lift: Vec3
    public var gamma: Vec3
    public var gain: Vec3
    public var saturation: Float
    public var contrast: Float
    /// Darkens the corners (0 = off, 1 = black); `vignetteSoftness` is how far in the fade reaches.
    public var vignette: Float
    public var vignetteSoftness: Float
    /// Splits red and blue radially toward the edges (0 = off; about 0.2 is subtle).
    public var chromaticAberration: Float
    /// Animated noise strength (0 = off).
    public var filmGrain: Float

    public init(tonemapper: Tonemapper = .neutral, exposure: Float = 0, autoExposure: Bool = false,
                autoExposureMin: Float = -6, autoExposureMax: Float = 6, adaptationSpeed: Float = 1.5,
                bloom: Bool = false, bloomIntensity: Float = 0.04,
                lift: Vec3 = Vec3(0, 0, 0), gamma: Vec3 = Vec3(1, 1, 1), gain: Vec3 = Vec3(1, 1, 1),
                saturation: Float = 1, contrast: Float = 1, vignette: Float = 0, vignetteSoftness: Float = 0.5,
                chromaticAberration: Float = 0, filmGrain: Float = 0) {
        self.lift = lift
        self.gamma = gamma
        self.gain = gain
        self.saturation = saturation
        self.contrast = contrast
        self.vignette = vignette
        self.vignetteSoftness = vignetteSoftness
        self.chromaticAberration = chromaticAberration
        self.filmGrain = filmGrain
        self.tonemapper = tonemapper
        self.exposure = exposure
        self.autoExposure = autoExposure
        self.autoExposureMin = autoExposureMin
        self.autoExposureMax = autoExposureMax
        self.adaptationSpeed = adaptationSpeed
        self.bloom = bloom
        self.bloomIntensity = bloomIntensity
    }

    /// No tonemapping, exposure or bloom: the HDR path reproduces the scene as it would look
    /// rendered straight into the sRGB target (colors above 1 clip).
    public static let passthrough = PostProcessSettings(tonemapper: .none)

    private enum CodingKeys: String, CodingKey {
        case tonemapper, exposure, autoExposure, autoExposureMin, autoExposureMax, adaptationSpeed, bloom, bloomIntensity
        case lift, gamma, gain, saturation, contrast, vignette, vignetteSoftness, chromaticAberration, filmGrain
    }

    /// Missing keys take their defaults, so scene files stay loadable when fields are added.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PostProcessSettings()
        tonemapper = try c.decodeIfPresent(Tonemapper.self, forKey: .tonemapper) ?? d.tonemapper
        exposure = try c.decodeIfPresent(Float.self, forKey: .exposure) ?? d.exposure
        autoExposure = try c.decodeIfPresent(Bool.self, forKey: .autoExposure) ?? d.autoExposure
        autoExposureMin = try c.decodeIfPresent(Float.self, forKey: .autoExposureMin) ?? d.autoExposureMin
        autoExposureMax = try c.decodeIfPresent(Float.self, forKey: .autoExposureMax) ?? d.autoExposureMax
        adaptationSpeed = try c.decodeIfPresent(Float.self, forKey: .adaptationSpeed) ?? d.adaptationSpeed
        bloom = try c.decodeIfPresent(Bool.self, forKey: .bloom) ?? d.bloom
        bloomIntensity = try c.decodeIfPresent(Float.self, forKey: .bloomIntensity) ?? d.bloomIntensity
        lift = try c.decodeIfPresent(Vec3.self, forKey: .lift) ?? d.lift
        gamma = try c.decodeIfPresent(Vec3.self, forKey: .gamma) ?? d.gamma
        gain = try c.decodeIfPresent(Vec3.self, forKey: .gain) ?? d.gain
        saturation = try c.decodeIfPresent(Float.self, forKey: .saturation) ?? d.saturation
        contrast = try c.decodeIfPresent(Float.self, forKey: .contrast) ?? d.contrast
        vignette = try c.decodeIfPresent(Float.self, forKey: .vignette) ?? d.vignette
        vignetteSoftness = try c.decodeIfPresent(Float.self, forKey: .vignetteSoftness) ?? d.vignetteSoftness
        chromaticAberration = try c.decodeIfPresent(Float.self, forKey: .chromaticAberration) ?? d.chromaticAberration
        filmGrain = try c.decodeIfPresent(Float.self, forKey: .filmGrain) ?? d.filmGrain
    }

    public static var fieldHints: [String: FieldHints] {
        [
            "exposure": FieldHints(range: -10...10, step: 0.1, tooltip: "Exposure compensation in EV (stops)"),
            "autoExposureMin": FieldHints(range: -16...16, step: 0.1, displayName: "Auto exposure min (EV)"),
            "autoExposureMax": FieldHints(range: -16...16, step: 0.1, displayName: "Auto exposure max (EV)"),
            "adaptationSpeed": FieldHints(range: 0.01...20, step: 0.1, tooltip: "Per second"),
            "bloomIntensity": FieldHints(range: 0...1, step: 0.005),
            "lift": FieldHints(color: true), "gamma": FieldHints(color: true), "gain": FieldHints(color: true),
            "saturation": FieldHints(range: 0...2, step: 0.01),
            "contrast": FieldHints(range: 0.5...1.5, step: 0.01),
            "vignette": FieldHints(range: 0...1, step: 0.01),
            "vignetteSoftness": FieldHints(range: 0.01...1, step: 0.01),
            "chromaticAberration": FieldHints(range: 0...1, step: 0.01),
            "filmGrain": FieldHints(range: 0...1, step: 0.01),
        ]
    }

    /// The `PostProcess` component of the lowest-numbered entity that has one, or nil.
    @MainActor public static func find(in world: World) -> PostProcessSettings? {
        var best: (entity: Entity, settings: PostProcessSettings)?
        world.query(PostProcessSettings.self) { entity, settings in
            if best == nil || entity.index < best!.entity.index { best = (entity, settings) }
        }
        return best?.settings
    }
}

/// The component name scene files use for `PostProcessSettings`.
public typealias PostProcess = PostProcessSettings

/// The CPU side of post-processing: the curves and formulas the shaders implement (tested on
/// their own), and the bloom chain's layout.
public enum PostProcessMath {
    /// The scale an exposure of `ev` stops applies: 2^ev.
    public static func exposureScale(ev: Float) -> Float { exp2f(ev) }
    /// The exposure in stops that scales by `scale`.
    public static func ev(scale: Float) -> Float { log2f(scale) }

    /// Luminance auto exposure maps the scene's log-average to (middle gray).
    public static let autoExposureKey: Float = 0.18

    /// Rec. 709 luminance of linear RGB.
    public static func luminance(_ c: Vec3) -> Float { c.x * 0.2126 + c.y * 0.7152 + c.z * 0.0722 }

    /// The exposure (EV) that maps a scene whose log2 luminance averages `averageLog2Luminance`
    /// to `autoExposureKey`, clamped to `minEV...maxEV` (exposure_adapt.frag).
    public static func autoExposureEV(averageLog2Luminance: Float, minEV: Float, maxEV: Float) -> Float {
        min(max(log2f(autoExposureKey) - averageLog2Luminance, minEV), maxEV)
    }

    /// The fraction of the remaining difference auto exposure closes in a frame of `dt`
    /// seconds: 1 - e^(-speed · dt). Frame-rate independent: two steps of dt equal one of 2 dt.
    public static func adaptationRate(dt: Float, speed: Float) -> Float {
        1 - expf(-max(dt, 0) * max(speed, 0))
    }

    /// One adaptation step from `current` toward `target` (EV) at `rate`.
    public static func adapt(current: Float, target: Float, rate: Float) -> Float {
        rate >= 1 ? target : current + (target - current) * rate
    }

    /// `color` tonemapped by `tonemapper` (after exposure), clamped to 0...1, as tonemap.frag does.
    public static func tonemap(_ color: Vec3, _ tonemapper: PostProcessSettings.Tonemapper) -> Vec3 {
        let c = Vec3(max(color.x, 0), max(color.y, 0), max(color.z, 0))
        let mapped: Vec3 = switch tonemapper {
        case .none: c
        case .reinhard: Vec3(c.x / (1 + c.x), c.y / (1 + c.y), c.z / (1 + c.z))
        case .neutral: neutral(c)
        case .aces: aces(c)
        }
        return Vec3(min(max(mapped.x, 0), 1), min(max(mapped.y, 0), 1), min(max(mapped.z, 0), 1))
    }

    /// Khronos PBR Neutral.
    static func neutral(_ input: Vec3) -> Vec3 {
        let startCompression: Float = 0.8 - 0.04, desaturation: Float = 0.15
        var color = input
        let x = min(color.x, color.y, color.z)
        let offset = x < 0.08 ? x - 6.25 * x * x : 0.04
        color = color - Vec3(repeating: offset)
        let peak = max(color.x, color.y, color.z)
        guard peak >= startCompression else { return color }
        let d = 1 - startCompression
        let newPeak = 1 - d * d / (peak + d - startCompression)
        color = color * (newPeak / peak)
        let g = 1 - 1 / (desaturation * (peak - newPeak) + 1)
        return color + (Vec3(repeating: newPeak) - color) * g
    }

    /// ACES filmic, Stephen Hill's fit.
    static func aces(_ c: Vec3) -> Vec3 {
        func fit(_ v: Float) -> Float { (v * (v + 0.0245786) - 0.000090537) / (v * (0.983729 * v + 0.4329510) + 0.238081) }
        let v = Vec3(fit(0.59719 * c.x + 0.35458 * c.y + 0.04823 * c.z),
                     fit(0.07600 * c.x + 0.90834 * c.y + 0.01566 * c.z),
                     fit(0.02840 * c.x + 0.13383 * c.y + 0.83777 * c.z))
        return Vec3(1.60475 * v.x - 0.53108 * v.y - 0.07367 * v.z,
                    -0.10208 * v.x + 1.10813 * v.y - 0.00605 * v.z,
                    -0.00327 * v.x - 0.07276 * v.y + 1.07602 * v.z)
    }

    /// Sizes of the bloom downsample chain for a `width` x `height` scene: each level half the
    /// previous (rounded up), until the next would be smaller than `minSize` on an axis or
    /// `maxLevels` exist (at least one level). The coarsest level of a 1440p scene is about
    /// 1/100 of the screen, so the blur's reach is similar at every resolution.
    public static func bloomMipSizes(width: Int, height: Int, maxLevels: Int = 8, minSize: Int = 8) -> [(width: Int, height: Int)] {
        var sizes: [(width: Int, height: Int)] = []
        var w = max(width, 1), h = max(height, 1)
        while sizes.count < maxLevels {
            w = (w + 1) / 2
            h = (h + 1) / 2
            if !sizes.isEmpty && min(w, h) < minSize { break }
            sizes.append((w, h))
        }
        return sizes
    }

    /// The linear value an sRGB attachment stores exactly as an 8-bit code: `c`'s channels moved
    /// to the nearest code (alpha, stored linearly, to the nearest 1/255). Clearing to such a
    /// value gives the same bytes on every GPU path; a value near the midpoint between two
    /// codes may round either way (Apple GPUs round clear colors slightly differently depending
    /// on the pass's attachments), which made Metal and Vulkan screenshots differ by 1.
    public static func snappedToSRGB8(_ c: Vec4) -> Vec4 {
        func encode(_ x: Double) -> Double { x <= 0.0031308 ? x * 12.92 : 1.055 * pow(x, 1 / 2.4) - 0.055 }
        func decode(_ x: Double) -> Double { x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4) }
        func snap(_ x: Float) -> Float {
            let code = (encode(min(max(Double(x), 0), 1)) * 255).rounded()
            return Float(decode(code / 255))
        }
        return Vec4(snap(c.x), snap(c.y), snap(c.z), (min(max(c.w, 0), 1) * 255).rounded() / 255)
    }
}

/// Runs post-processing for the engine (see `PostProcessSettings`): after the scene pass has
/// rendered into the HDR image, `render` records the bloom chain and auto exposure into
/// offscreen RGBA16F targets, then `drawOutput` applies everything in the scene output pass.
///
/// Passes (GPU timings): `bloom` (one per downsample level, then one per upsample), `exposure`
/// (a 16x16 log-luminance grid, then the 1x1 adapted value) and `tonemap`.
///
/// Every shader reads texels with exact loads and fixed weights (no filtering hardware), so the
/// result is byte-identical on Metal and Vulkan.
@MainActor
public final class PostProcessor {
    public let device: RenderDevice
    private let bloomDown: RenderPipeline
    private let bloomUp: RenderPipeline
    private let exposureReduce: RenderPipeline
    private let exposureAdapt: RenderPipeline
    private let tonemap: RenderPipeline
    private let pointSampler: GPUSampler
    /// Bound in place of inputs a pass doesn't use (Vulkan wants every declared binding valid).
    private let black: GPUTexture
    private var bloomChain: (width: Int, height: Int, down: [GPURenderTarget], up: [GPURenderTarget])?
    private var exposureTargets: (grid: GPURenderTarget, history: [GPURenderTarget])?
    /// The history target written last, and whether it holds a valid exposure.
    private var exposureCurrent = 0
    private var exposureValid = false
    /// Before/after preview: the left of this fraction of the width (0...1) shows the plain
    /// scene without exposure or effects, separated by a white line. 0 turns it off.
    public var splitPreview: Float = 0
    private var grainTime: Float = 0

    /// Size of the auto-exposure log-luminance grid.
    static let exposureGrid = (width: 16, height: 16)

    public init(device: RenderDevice) throws {
        self.device = device
        func pipeline(_ fragment: String, _ format: TextureFormat) throws -> RenderPipeline {
            var descriptor = PipelineDescriptor(
                shader: try ShaderSource.load(vertex: "post", fragment: fragment, bundle: .module), vertexLayout: .none)
            descriptor.target = .color(format)
            descriptor.cullMode = .none
            descriptor.depthTest = false
            descriptor.depthWrite = false
            return try device.makePipeline(descriptor)
        }
        bloomDown = try pipeline("bloom_down", .rgba16Float)
        bloomUp = try pipeline("bloom_up", .rgba16Float)
        exposureReduce = try pipeline("exposure_reduce", .rgba16Float)
        exposureAdapt = try pipeline("exposure_adapt", .rgba16Float)
        tonemap = try pipeline("tonemap", .rgba8Srgb)
        pointSampler = try device.makeSampler(SamplerDescriptor(filter: .nearest))
        black = try device.makeTexture(pixels: [UInt8](repeating: 0, count: 8), width: 1, height: 1, format: .rgba16Float)
    }

    /// Runs on the HDR scene image before bloom, exposure and tonemapping: returns the image to use
    /// instead (volumetric fog), or nil to keep the scene. `SceneRenderer` sets it each frame.
    public var sceneEffect: ((GPUTexture) -> GPUTexture?)?

    /// Makes the next auto-exposure frame converge at once instead of adapting (camera cuts).
    public func resetExposure() {
        exposureValid = false
    }

    /// What `render` produced for `drawOutput`.
    public struct Inputs {
        /// The scene after `sceneEffect`, if it changed it.
        var scene: GPUTexture?
        var bloom: GPUTexture?
        var exposure: GPUTexture?
    }

    /// Records the bloom and auto-exposure passes that read `scene` (the HDR scene image).
    /// Call after the screen pass has ended, before the output pass. `dt` drives adaptation.
    public func render(scene original: GPUTexture, settings: PostProcessSettings, dt: Float) -> Inputs {
        var inputs = Inputs()
        var scene = original
        if let output = sceneEffect?(scene) {
            scene = output
            inputs.scene = output
        }
        if settings.bloom && settings.bloomIntensity > 0 {
            inputs.bloom = renderBloom(scene: scene)
        } else {
            bloomChain = nil  // free the memory while bloom is off
        }
        if settings.autoExposure {
            inputs.exposure = renderExposure(scene: scene, settings: settings, dt: dt)
        } else {
            exposureValid = false
        }
        return inputs
    }

    /// Post-processes `scene` (any texture, e.g. an editor view; its values are already clamped to
    /// 0...1, so highlights can't bloom as in the HDR path) into `target`, a color-only
    /// `.rgba8Srgb` target. Call between passes, not inside one.
    public func renderPreview(scene: GPUTexture, settings: PostProcessSettings, into target: GPURenderTarget, dt: Float) {
        let inputs = render(scene: scene, settings: settings, dt: dt)
        let pass = device.beginPass(target: target, clearColor: .zero, clearDepth: 1, label: "post fx preview")
        drawOutput(into: pass, scene: scene, settings: settings, inputs: inputs)
        device.endPass()
    }

    /// Draws the final image (exposure, bloom, tonemapper) into `pass`, the scene output pass.
    public func drawOutput(into pass: RenderPass, scene original: GPUTexture, settings: PostProcessSettings, inputs: Inputs) {
        let scene = inputs.scene ?? original
        pass.setPipeline(tonemap)
        pass.setTexture(scene, index: 1)
        pass.setTexture(inputs.bloom ?? black, index: 2)
        pass.setTexture(inputs.exposure ?? black, index: 3)
        pass.setSampler(pointSampler, index: 1)
        let bloom = inputs.bloom
        grainTime += 1.0 / 60
        let graded = settings.lift != Vec3(0, 0, 0) || settings.gamma != Vec3(1, 1, 1) || settings.gain != Vec3(1, 1, 1)
            || settings.saturation != 1 || settings.contrast != 1
        let gammaInverse = Vec3(1 / max(settings.gamma.x, 0.01), 1 / max(settings.gamma.y, 0.01), 1 / max(settings.gamma.z, 0.01))
        pass.setPushConstants(TonemapConstants(
            exposure: PostProcessMath.exposureScale(ev: settings.exposure),
            bloomIntensity: bloom == nil ? 0 : min(max(settings.bloomIntensity, 0), 1),
            tonemapper: Int32(PostProcessSettings.Tonemapper.allCases.firstIndex(of: settings.tonemapper)!),
            autoExposure: inputs.exposure == nil ? 0 : 1,
            bloomMax: SIMD2(Int32((bloom?.width ?? 1) - 1), Int32((bloom?.height ?? 1) - 1)),
            lift: SIMD4(settings.lift.x, settings.lift.y, settings.lift.z, graded ? 1 : 0),
            gamma: SIMD4(gammaInverse.x, gammaInverse.y, gammaInverse.z, 0),
            gain: SIMD4(settings.gain.x, settings.gain.y, settings.gain.z, 0),
            look: SIMD4(max(settings.saturation, 0), max(settings.contrast, 0), min(max(settings.vignette, 0), 1),
                        min(max(settings.vignetteSoftness, 0.01), 1)),
            fx: SIMD4(max(settings.chromaticAberration, 0), max(settings.filmGrain, 0), grainTime,
                      min(max(splitPreview, 0), 1))))
        pass.draw(vertexCount: 3)
    }

    /// Downsamples `scene` into the chain, then upsamples back to the first level, which it returns.
    private func renderBloom(scene: GPUTexture) -> GPUTexture? {
        let sizes = PostProcessMath.bloomMipSizes(width: scene.width, height: scene.height)
        if bloomChain.map({ $0.width != scene.width || $0.height != scene.height }) ?? true {
            bloomChain = nil
            do {
                let down = try sizes.map { try device.makeRenderTarget(.color(width: $0.width, height: $0.height, format: .rgba16Float)) }
                let up = try sizes.dropLast().map {
                    try device.makeRenderTarget(.color(width: $0.width, height: $0.height, format: .rgba16Float))
                }
                bloomChain = (scene.width, scene.height, down, up)
            } catch {
                print("PostProcessor: bloom unavailable: \(error)")
                return nil
            }
        }
        guard let chain = bloomChain else { return nil }
        var source = scene
        for (level, target) in chain.down.enumerated() {
            fullscreen(into: target, label: "bloom", pipeline: bloomDown, textures: [source]) { pass in
                pass.setPushConstants(BloomDownConstants(
                    sourceMax: SIMD2(Int32(source.width - 1), Int32(source.height - 1)),
                    karis: level == 0 ? 1 : 0, maxValue: 65000))
            }
            source = target.texture
        }
        var coarse = chain.down[chain.down.count - 1].texture
        for level in chain.up.indices.reversed() {
            let target = chain.up[level]
            fullscreen(into: target, label: "bloom", pipeline: bloomUp, textures: [coarse, chain.down[level].texture]) { pass in
                pass.setPushConstants(SIMD2(Int32(coarse.width - 1), Int32(coarse.height - 1)))
            }
            coarse = target.texture
        }
        return coarse
    }

    /// Reduces `scene`'s log luminance to a grid, then adapts last frame's exposure toward it.
    private func renderExposure(scene: GPUTexture, settings: PostProcessSettings, dt: Float) -> GPUTexture? {
        if exposureTargets == nil {
            do {
                let grid = try device.makeRenderTarget(
                    .color(width: Self.exposureGrid.width, height: Self.exposureGrid.height, format: .rgba16Float))
                let history = try (0..<2).map { _ in try device.makeRenderTarget(.color(width: 1, height: 1, format: .rgba16Float)) }
                exposureTargets = (grid, history)
            } catch {
                print("PostProcessor: auto exposure unavailable: \(error)")
                return nil
            }
        }
        guard let targets = exposureTargets else { return nil }
        let gridSize = SIMD2(Int32(Self.exposureGrid.width), Int32(Self.exposureGrid.height))
        fullscreen(into: targets.grid, label: "exposure", pipeline: exposureReduce, textures: [scene]) { pass in
            pass.setPushConstants(ExposureReduceConstants(sceneSize: SIMD2(Int32(scene.width), Int32(scene.height)), gridSize: gridSize))
        }
        let next = 1 - exposureCurrent
        let rate = exposureValid ? PostProcessMath.adaptationRate(dt: dt, speed: settings.adaptationSpeed) : 1
        let previous = targets.history[exposureCurrent].texture
        fullscreen(into: targets.history[next], label: "exposure", pipeline: exposureAdapt,
                   textures: [targets.grid.texture, previous]) { pass in
            pass.setPushConstants(ExposureAdaptConstants(
                gridSize: gridSize, rate: rate, key: log2f(PostProcessMath.autoExposureKey),
                minEV: min(settings.autoExposureMin, settings.autoExposureMax), maxEV: settings.autoExposureMax))
        }
        exposureCurrent = next
        exposureValid = true
        return targets.history[next].texture
    }

    /// One fullscreen triangle into a color-only target, with `textures` bound from index 1.
    private func fullscreen(into target: GPURenderTarget, label: String, pipeline: RenderPipeline, textures: [GPUTexture],
                            _ setup: (RenderPass) -> Void) {
        let pass = device.beginPass(target: target, clearColor: .zero, clearDepth: 1, label: label)
        pass.setPipeline(pipeline)
        for (i, texture) in textures.enumerated() { pass.setTexture(texture, index: i + 1) }
        pass.setSampler(pointSampler, index: 1)
        setup(pass)
        pass.draw(vertexCount: 3)
        device.endPass()
    }
}

/// Must match the push constants of the post shaders (std430 layout).
struct BloomDownConstants {
    var sourceMax: SIMD2<Int32>
    var karis: Float
    var maxValue: Float
}

struct ExposureReduceConstants {
    var sceneSize: SIMD2<Int32>
    var gridSize: SIMD2<Int32>
}

struct ExposureAdaptConstants {
    var gridSize: SIMD2<Int32>
    var rate: Float
    var key: Float
    var minEV: Float
    var maxEV: Float
}

struct TonemapConstants {
    var exposure: Float
    var bloomIntensity: Float
    var tonemapper: Int32
    var autoExposure: Float
    var bloomMax: SIMD2<Int32>
    var lift: SIMD4<Float>
    var gamma: SIMD4<Float>
    var gain: SIMD4<Float>
    var look: SIMD4<Float>
    var fx: SIMD4<Float>
}
