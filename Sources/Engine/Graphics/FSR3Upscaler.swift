import Foundation

// AMD FidelityFX Super Resolution 3.1 upscaler (FSR 3.1.4 from FidelityFX SDK 1.1.4, MIT). The
// SDK's GPU code is vendored unchanged in Shaders/FidelityFX (with its license); the engine's
// resource accessors are Shaders/fsr3_callbacks.glsl and the passes Shaders/fsr3_*.comp. This
// file is the host side, the part of the SDK's ffx_fsr3upscaler.cpp the engine needs: resources,
// constants and the dispatch sequence. It only uses the compute API, so both backends record the
// same dispatches; they hand it their scene images and show `encode`'s result.
//
// Per frame, in one compute pass (`upscale`), each dispatch seeing the previous ones' writes:
//  1. clear the reconstructed previous depth (to the farthest depth)
//  2. prepare inputs: dilated depth and motion, previous depth by reprojection (atomic min/max),
//     farthest depth, luma
//  3. luma pyramid (SPD level 0: farthest depth at half resolution)
//  4. shading-change pyramid (SPD levels 0-2 of the luma change against the previous frame)
//  5. shading change (half resolution)
//  6. prepare reactivity: disocclusion, shading change, reactive mask, accumulation, new locks
//  7. luma instability
//  8. accumulate into the next history (output resolution)
//  9. RCAS into the output
// Deviations from the SDK (none changes the result of the passes that remain):
// - No FSR auto exposure: the luma pyramid stops at SPD level 0 and the shading-change pyramid at
//   level 2, the levels later passes read. SPD then never reaches its last-workgroup step, so
//   there is no global atomic counter and no cross-workgroup read.
// - The reconstructed depth is a storage buffer (order-independent atomic min/max).
// - Out-of-bounds loads return 0 and stores are dropped, as on D3D (see fsr3_callbacks.glsl).
// - Always the sharpening permutation (accumulate, then RCAS); 32-bit math (no FP16); no
//   Lanczos LUT; reversed-Z selects a second prepare-inputs pipeline.
// - The constant buffers are one push-constant block (`FSR3PushConstants`): MoltenVK binds
//   uniform buffers through argument buffers, and Apple's compiler then rounds some of FSR's
//   arithmetic differently than with the directly bound buffers of native Metal.

/// What FSR 3 reads each frame (render size unless noted).
struct FSR3Inputs {
    /// Jittered scene color, gamma-encoded (the scene image's UNORM view).
    var color: GPUTexture
    /// Scene depth, standard or reversed (`temporal.reversedDepth`).
    var depth: GPUTexture
    /// Motion vectors, previous UV − current UV (see `TemporalUpscaling.swift`).
    var motion: GPUTexture
    /// Optional reactive mask (red, 0...1): how much each pixel should ignore its history.
    var reactive: GPUTexture?
    var temporal: TemporalInputs
    /// RCAS sharpness in stops (0 is the sharpest).
    var sharpness: Float
    /// Multiplier that takes `color` to the values FSR should see; 1 for display-referred input.
    var exposure: Float = 1
}

/// The SDK's `Fsr3UpscalerConstants` plus `exposure`; the shaders get the fields they read as
/// `FSR3PushConstants`.
struct FSR3Constants: Equatable {
    var renderSize: SIMD2<Int32> = .zero
    var previousFrameRenderSize: SIMD2<Int32> = .zero
    var upscaleSize: SIMD2<Int32> = .zero
    var previousFrameUpscaleSize: SIMD2<Int32> = .zero
    var maxRenderSize: SIMD2<Int32> = .zero
    var maxUpscaleSize: SIMD2<Int32> = .zero
    /// Device depth d → view depth `[1] / (d − [0])`; view x and y = ndc · `[2]`, `[3]` · depth.
    var deviceToViewDepth: SIMD4<Float> = .zero
    var jitter: Vec2 = .zero
    var previousFrameJitter: Vec2 = .zero
    /// Converts the motion texture to UV offsets (ours already are).
    var motionVectorScale = Vec2(1, 1)
    /// Render size / output size.
    var downscaleFactor: Vec2 = .zero
    var motionVectorJitterCancellation: Vec2 = .zero
    var tanHalfFOV: Float = 0
    /// Jitter phases (see `TemporalJitter.phaseCount`), moved one step per frame toward a new count.
    var jitterSequenceLength: Float = 0
    /// Only read by FSR's own auto exposure, which isn't used.
    var deltaTime: Float = 0
    var deltaPreExposure: Float = 1
    var viewSpaceToMetersFactor: Float = 1
    /// Frames accumulated since the last reset (0 on a reset).
    var frameIndex: Float = 0
    var velocityFactor: Float = 1
    var reactivenessScale: Float = 1
    var shadingChangeScale: Float = 1
    var accumulationAddedPerFrame: Float = 1.0 / 3.0
    var minDisocclusionAccumulation: Float = -1.0 / 3.0
    var exposure: Float = 1

    /// `deviceToViewDepth` and `tanHalfFOV` from a perspective projection (column-major, clip
    /// depth in [0, 1], standard or reversed, finite or infinite far plane), as the SDK computes
    /// them from near, far and the field of view: clip z = P[2][2] z + P[3][2], clip w = −z, so
    /// for a view distance D = −z, device depth d = −P[2][2] + P[3][2] / D.
    mutating func setProjection(_ projection: Mat4) {
        deviceToViewDepth = SIMD4(-projection.c2.z, projection.c3.z, 1 / projection.c0.x, 1 / projection.c1.y)
        tanHalfFOV = 1 / projection.c0.x
    }

    /// The constants of the next frame: `previous` advanced to `render` → `output` with `inputs`
    /// (`reset` restarts the accumulation). Mirrors `fsr3upscalerDispatch` in the SDK.
    static func next(after previous: FSR3Constants?, render: (width: Int, height: Int), output: (width: Int, height: Int),
                     inputs: TemporalInputs, exposure: Float, reset: Bool) -> FSR3Constants {
        var constants = previous ?? FSR3Constants()
        let renderSize = SIMD2(Int32(render.width), Int32(render.height))
        let upscaleSize = SIMD2(Int32(output.width), Int32(output.height))
        // The SDK starts from zeroed constants; a first frame has no history, but previous sizes of
        // 0 would make the shaders divide by zero (NaN under fast math), so start from this frame.
        constants.previousFrameJitter = previous?.jitter ?? inputs.jitter
        constants.previousFrameRenderSize = previous?.renderSize ?? renderSize
        constants.previousFrameUpscaleSize = previous?.upscaleSize ?? upscaleSize
        constants.jitter = inputs.jitter
        constants.renderSize = renderSize
        constants.maxRenderSize = renderSize
        constants.upscaleSize = upscaleSize
        constants.maxUpscaleSize = upscaleSize
        constants.setProjection(inputs.projection ?? FSR3Constants.fallbackProjection(aspect: Float(render.width) / Float(render.height),
                                                                                      reversed: inputs.reversedDepth))
        constants.downscaleFactor = Vec2(Float(render.width) / Float(output.width), Float(render.height) / Float(output.height))
        constants.exposure = exposure
        let phases = Float(jitterPhaseCount(renderWidth: render.width, outputWidth: output.width))
        if reset || constants.jitterSequenceLength == 0 {
            constants.jitterSequenceLength = phases
        } else if phases > constants.jitterSequenceLength {
            constants.jitterSequenceLength += 1
        } else if phases < constants.jitterSequenceLength {
            constants.jitterSequenceLength -= 1
        }
        constants.frameIndex = reset ? 0 : constants.frameIndex + 1
        return constants
    }

    /// `ffxFsr3UpscalerGetJitterPhaseCount`: 8 × (output / render width)², truncated.
    static func jitterPhaseCount(renderWidth: Int, outputWidth: Int) -> Int {
        Int(8 * powf(Float(outputWidth) / Float(renderWidth), 2))
    }

    /// Used when the game didn't jitter a projection through `Engine.jittered(_:)`: 60° vertical,
    /// near 0.1, far 1000 (FSR only uses it for depth thresholds in meters).
    static func fallbackProjection(aspect: Float, reversed: Bool) -> Mat4 {
        reversed ? Mat4.perspective(fovY: .pi / 3, aspect: aspect, near: 1000, far: 0.1)
            : Mat4.perspective(fovY: .pi / 3, aspect: aspect, near: 0.1, far: 1000)
    }
}

/// `cbSPD` (24 bytes): SPD's tile grid and how many levels to compute.
struct FSR3SpdConstants: Equatable {
    var mips: UInt32
    var numWorkGroups: UInt32
    var workGroupOffset: SIMD2<UInt32>
    var renderSize: SIMD2<UInt32>

    /// `ffxSpdSetup` for the whole render target, computing at most `maxMips` levels.
    init(render: (width: Int, height: Int), maxMips: Int) {
        let groups = Self.workgroups(render: render)
        numWorkGroups = UInt32(groups.x * groups.y)
        workGroupOffset = .zero
        renderSize = SIMD2(UInt32(render.width), UInt32(render.height))
        let levels = Int(min(floor(log2(Float(max(render.width, render.height)))), 12))
        mips = UInt32(min(levels, maxMips))
    }

    /// `(mips, numWorkGroups)` for `FSR3PushConstants.passConfig`.
    var passConfig: SIMD2<UInt32> { SIMD2(mips, numWorkGroups) }

    /// One 64x64 tile per workgroup.
    static func workgroups(render: (width: Int, height: Int)) -> ComputeSize {
        ComputeSize((render.width + 63) / 64, (render.height + 63) / 64)
    }
}

/// `cbRCAS` (16 bytes): `FsrRcasCon` for a sharpness in stops.
struct FSR3RcasConstants: Equatable {
    var config: SIMD4<UInt32>

    init(sharpness stops: Float) {
        let linear = exp2(-stops)
        let half = UInt32(Half.bits(linear))
        config = SIMD4(linear.bitPattern, half | half << 16, 0, 0)
    }
}

/// The push constants of the FSR passes (128 bytes; `cbFSR3Upscaler` in fsr3_callbacks.glsl): the
/// fields of `FSR3Constants` the shaders read, plus the pass's SPD or RCAS constants.
struct FSR3PushConstants {
    var renderSize: SIMD2<Int32>
    var previousFrameRenderSize: SIMD2<Int32>
    var upscaleSize: SIMD2<Int32>
    var previousFrameUpscaleSize: SIMD2<Int32>
    var deviceToViewDepth: SIMD4<Float>
    var jitter: Vec2
    var previousFrameJitter: Vec2
    var downscaleFactor: Vec2
    var tanHalfFOV: Float
    var jitterSequenceLength: Float
    var deltaPreExposure: Float
    var viewSpaceToMetersFactor: Float
    var frameIndex: Float
    var velocityFactor: Float
    var reactivenessScale: Float
    var shadingChangeScale: Float
    var accumulationAddedPerFrame: Float
    var minDisocclusionAccumulation: Float
    var exposure: Float
    /// SPD: (mips, numWorkGroups); RCAS: `config.xy`.
    var passConfig: SIMD2<UInt32>

    init(_ c: FSR3Constants, passConfig: SIMD2<UInt32> = .zero) {
        renderSize = c.renderSize
        previousFrameRenderSize = c.previousFrameRenderSize
        upscaleSize = c.upscaleSize
        previousFrameUpscaleSize = c.previousFrameUpscaleSize
        deviceToViewDepth = c.deviceToViewDepth
        jitter = c.jitter
        previousFrameJitter = c.previousFrameJitter
        downscaleFactor = c.downscaleFactor
        tanHalfFOV = c.tanHalfFOV
        jitterSequenceLength = c.jitterSequenceLength
        deltaPreExposure = c.deltaPreExposure
        viewSpaceToMetersFactor = c.viewSpaceToMetersFactor
        frameIndex = c.frameIndex
        velocityFactor = c.velocityFactor
        reactivenessScale = c.reactivenessScale
        shadingChangeScale = c.shadingChangeScale
        accumulationAddedPerFrame = c.accumulationAddedPerFrame
        minDisocclusionAccumulation = c.minDisocclusionAccumulation
        exposure = c.exposure
        self.passConfig = passConfig
    }
}

/// Push constants of fsr3_clear (32 bytes).
private struct FSR3ClearConstants {
    var value: SIMD4<Float>
    var size: SIMD2<UInt32>
    var mode: UInt32
    var word: UInt32
}

/// FSR 3.1 for one backend device: pipelines, resources sized for the current render and output
/// sizes (recreated when they change), and the state carried between frames.
@MainActor final class FSR3Upscaler {
    private let clear: ComputePipeline
    private let prepareInputs: ComputePipeline
    private let prepareInputsReversed: ComputePipeline
    private let lumaPyramid: ComputePipeline
    private let shadingChangePyramid: ComputePipeline
    private let shadingChange: ComputePipeline
    private let prepareReactivity: ComputePipeline
    private let lumaInstability: ComputePipeline
    private let accumulate: ComputePipeline
    private let rcas: ComputePipeline
    private let linearClamp: GPUSampler
    private var resources: Resources?
    /// Last frame's constants (nil until a frame with the current resources).
    private var constants: FSR3Constants?
    /// Which of each ping-pong pair is written this frame (the SDK's odd/even frame).
    private var parity = 0

    /// Storage textures and buffers. Ping-pong pairs alternate between read (last frame's) and write.
    private struct Resources {
        var renderSize: (width: Int, height: Int)
        var outputSize: (width: Int, height: Int)
        // Render size.
        var dilatedMotion, dilatedDepth, farthestDepth, dilatedReactive, lumaInstability: GPUTexture
        var luma, accumulation, lumaHistory: [GPUTexture]
        var reconstructedDepth: GPUBuffer
        /// Zero, for frames without a reactive mask.
        var noReactive: GPUTexture
        // Half render size and below.
        var farthestDepthMip1, shadingChange: GPUTexture
        var spdMips: [GPUTexture]
        // Output size.
        var history: [GPUTexture]
        var newLocks, output: GPUTexture
    }

    init(device: RenderDevice) throws {
        func load(_ name: String) throws -> ComputePipeline {
            try device.makeComputePipeline(shader: ShaderSource.load(compute: name, bundle: .module))
        }
        clear = try load("fsr3_clear")
        prepareInputs = try load("fsr3_prepare_inputs")
        prepareInputsReversed = try load("fsr3_prepare_inputs_reversed")
        lumaPyramid = try load("fsr3_luma_pyramid")
        shadingChangePyramid = try load("fsr3_shading_change_pyramid")
        shadingChange = try load("fsr3_shading_change")
        prepareReactivity = try load("fsr3_prepare_reactivity")
        lumaInstability = try load("fsr3_luma_instability")
        accumulate = try load("fsr3_accumulate")
        rcas = try load("fsr3_rcas")
        linearClamp = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .clampToEdge))
    }

    /// Records the passes (one compute pass timed as `label`) upscaling `inputs` to `output` and
    /// returns the result: an `.rgba16Float` storage texture of that size, gamma-encoded like the
    /// input, for the window pass to copy. Call between passes, after the scene pass.
    func encode(_ inputs: FSR3Inputs, output: (width: Int, height: Int), device: RenderDevice,
                label: String = "upscale") throws -> GPUTexture {
        let render = (width: inputs.color.width, height: inputs.color.height)
        var reset = inputs.temporal.resetHistory
        let fresh = resources.map { $0.renderSize != render || $0.outputSize != output } ?? true
        if fresh {
            resources = try makeResources(device: device, render: render, output: output)
            constants = nil
            reset = true
        }
        guard let r = resources else { preconditionFailure("FSR 3 resources missing") }
        let frame = FSR3Constants.next(after: constants, render: render, output: output, inputs: inputs.temporal,
                                       exposure: inputs.exposure, reset: reset)
        constants = frame
        let write = parity, read = 1 - parity
        parity = read

        let pass = device.beginComputePass(label: label)
        defer { device.endPass() }
        pass.setSampler(linearClamp, index: 1)

        func fill(_ texture: GPUTexture, _ value: SIMD4<Float> = .zero) {
            pass.setPipeline(clear)
            pass.setStorageTexture(texture, index: 0)
            pass.setStorageBuffer(r.reconstructedDepth, index: 0)
            pass.setPushConstants(FSR3ClearConstants(
                value: value, size: SIMD2(UInt32(texture.width), UInt32(texture.height)), mode: 0, word: 0))
            pass.dispatch(threads: ComputeSize(texture.width, texture.height), of: clear)
        }
        if fresh {
            // The SDK's first-execution clears, plus what its D3D/Vulkan resources start as (new
            // locks are only cleared after being read; SPD levels past the written area are sampled).
            for texture in r.accumulation + r.luma + r.spdMips + [r.newLocks, r.noReactive] { fill(texture) }
        } else if reset {
            fill(r.accumulation[read])
            for texture in r.spdMips { fill(texture) }
        }

        // 1. The farthest depth's bits: atomic min (standard depth) or max (reversed) keeps the nearest.
        pass.setPipeline(clear)
        pass.setStorageTexture(r.noReactive, index: 0)
        pass.setStorageBuffer(r.reconstructedDepth, index: 0)
        pass.setPushConstants(FSR3ClearConstants(
            value: .zero, size: SIMD2(UInt32(render.width), UInt32(render.height)), mode: 1,
            word: inputs.temporal.reversedDepth ? 0 : Float(1).bitPattern))
        pass.dispatch(threads: ComputeSize(render.width, render.height), of: clear)

        let push = FSR3PushConstants(frame)
        pass.setPushConstants(push)
        let renderGroups = ComputeSize(render.width, render.height).groups(of: ComputeSize(8, 8))

        // 2. Prepare inputs.
        pass.setPipeline(inputs.temporal.reversedDepth ? prepareInputsReversed : prepareInputs)
        pass.setTexture(inputs.motion, index: 1)
        pass.setTexture(inputs.depth, index: 2)
        pass.setTexture(inputs.color, index: 3)
        pass.setStorageTexture(r.dilatedMotion, index: 0)
        pass.setStorageTexture(r.dilatedDepth, index: 1)
        pass.setStorageTexture(r.farthestDepth, index: 2)
        pass.setStorageTexture(r.luma[write], index: 3)
        pass.setStorageBuffer(r.reconstructedDepth, index: 0)
        pass.dispatch(groups: renderGroups)

        // 3. Luma pyramid: SPD level 0 only (the farthest depth at half resolution).
        let spdGroups = FSR3SpdConstants.workgroups(render: render)
        pass.setPipeline(lumaPyramid)
        pass.setPushConstants(FSR3PushConstants(frame, passConfig: FSR3SpdConstants(render: render, maxMips: 1).passConfig))
        pass.setTexture(r.luma[write], index: 1)
        pass.setTexture(r.farthestDepth, index: 2)
        pass.setStorageTexture(r.farthestDepthMip1, index: 0)
        pass.dispatch(groups: spdGroups)

        // 4. Shading-change pyramid: SPD levels 0-2.
        pass.setPipeline(shadingChangePyramid)
        pass.setPushConstants(FSR3PushConstants(frame, passConfig: FSR3SpdConstants(render: render, maxMips: 3).passConfig))
        pass.setTexture(r.luma[write], index: 1)
        pass.setTexture(r.luma[read], index: 2)
        pass.setTexture(r.dilatedMotion, index: 3)
        for (level, texture) in r.spdMips.enumerated() { pass.setStorageTexture(texture, index: level) }
        pass.dispatch(groups: spdGroups)

        // 5. Shading change at half resolution.
        pass.setPipeline(shadingChange)
        for (level, texture) in r.spdMips.enumerated() { pass.setTexture(texture, index: 1 + level) }
        pass.setStorageTexture(r.shadingChange, index: 0)
        pass.dispatch(threads: ComputeSize(render.width / 2, render.height / 2), of: shadingChange)

        // 6. Prepare reactivity.
        pass.setPipeline(prepareReactivity)
        pass.setTexture(r.dilatedMotion, index: 1)
        pass.setTexture(r.dilatedDepth, index: 2)
        pass.setTexture(inputs.reactive ?? r.noReactive, index: 3)
        pass.setTexture(r.accumulation[read], index: 4)
        pass.setTexture(r.shadingChange, index: 5)
        pass.setTexture(r.luma[write], index: 6)
        pass.setStorageTexture(r.dilatedReactive, index: 0)
        pass.setStorageTexture(r.newLocks, index: 1)
        pass.setStorageTexture(r.accumulation[write], index: 2)
        pass.setStorageBuffer(r.reconstructedDepth, index: 0)
        pass.dispatch(groups: renderGroups)

        // 7. Luma instability.
        pass.setPipeline(lumaInstability)
        pass.setTexture(r.dilatedReactive, index: 1)
        pass.setTexture(r.dilatedMotion, index: 2)
        pass.setTexture(r.lumaHistory[read], index: 3)
        pass.setTexture(r.farthestDepthMip1, index: 4)
        pass.setTexture(r.luma[write], index: 5)
        pass.setStorageTexture(r.lumaHistory[write], index: 0)
        pass.setStorageTexture(r.lumaInstability, index: 1)
        pass.dispatch(groups: renderGroups)

        // 8. Accumulate.
        pass.setPipeline(accumulate)
        pass.setTexture(r.dilatedReactive, index: 1)
        pass.setTexture(r.dilatedMotion, index: 2)
        pass.setTexture(r.history[read], index: 3)
        pass.setTexture(r.farthestDepthMip1, index: 4)
        pass.setTexture(r.lumaInstability, index: 5)
        pass.setTexture(inputs.color, index: 6)
        pass.setStorageTexture(r.history[write], index: 0)
        pass.setStorageTexture(r.newLocks, index: 1)
        pass.dispatch(threads: ComputeSize(output.width, output.height), of: accumulate)

        // 9. RCAS: 64 threads per 16x16 tile.
        pass.setPipeline(rcas)
        let rcasConfig = FSR3RcasConstants(sharpness: inputs.sharpness).config
        pass.setPushConstants(FSR3PushConstants(frame, passConfig: SIMD2(rcasConfig.x, rcasConfig.y)))
        pass.setTexture(r.history[write], index: 1)
        pass.setStorageTexture(r.output, index: 0)
        pass.dispatch(groups: ComputeSize(output.width, output.height).groups(of: ComputeSize(16, 16)))
        return r.output
    }

    private func makeResources(device: RenderDevice, render: (width: Int, height: Int),
                               output: (width: Int, height: Int)) throws -> Resources {
        func texture(_ size: (width: Int, height: Int), _ format: TextureFormat) throws -> GPUTexture {
            try device.makeTexture(TextureDescriptor(width: max(size.width, 1), height: max(size.height, 1), format: format, storage: true))
        }
        let half = (width: render.width / 2, height: render.height / 2)
        return Resources(
            renderSize: render, outputSize: output,
            dilatedMotion: try texture(render, .rg16Float),
            dilatedDepth: try texture(render, .r32Float),
            farthestDepth: try texture(render, .r16Float),
            dilatedReactive: try texture(render, .rgba8Unorm),
            lumaInstability: try texture(render, .r16Float),
            luma: try (0..<2).map { _ in try texture(render, .r16Float) },
            accumulation: try (0..<2).map { _ in try texture(render, .r8Unorm) },
            lumaHistory: try (0..<2).map { _ in try texture(render, .rgba16Float) },
            reconstructedDepth: try device.makeBuffer(length: render.width * render.height * 4, usage: .storage),
            noReactive: try texture((1, 1), .r8Unorm),
            farthestDepthMip1: try texture(half, .r16Float),
            shadingChange: try texture(half, .r8Unorm),
            spdMips: try (0..<3).map { level in try texture((render.width >> (level + 1), render.height >> (level + 1)), .rg16Float) },
            history: try (0..<2).map { _ in try texture(output, .rgba16Float) },
            newLocks: try texture(output, .r8Unorm),
            output: try texture(output, .rgba16Float))
    }
}
