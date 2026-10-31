#if canImport(Metal) && canImport(AppKit)
import Foundation
import Metal
import MetalFX
import QuartzCore

// MSL buffer indices; see `RenderPass` for the full binding table.
let metalInstanceBufferIndex = 1
let metalUniformBufferIndex = 15
let metalPushConstantIndex = 16
private let maxFramesInFlight = 3
/// Passes per frame whose GPU time is measured; later ones go untimed.
private let maxTimedPasses = 16
private let screenDepthFormat = MTLPixelFormat.depth32Float
/// The scene pass's second color attachment while a temporal upscaler is active.
private let motionVectorFormat = MTLPixelFormat.rg16Float

final class MetalBuffer: GPUBuffer {
    let buffer: MTLBuffer
    var length: Int { buffer.length }
    init(_ buffer: MTLBuffer) { self.buffer = buffer }
}

final class MetalTexture: GPUTexture {
    let texture: MTLTexture
    let format: TextureFormat
    var width: Int { texture.width }
    var height: Int { texture.height }
    var mipLevelCount: Int { texture.mipmapLevelCount }

    init(_ texture: MTLTexture, format: TextureFormat) {
        self.texture = texture
        self.format = format
    }
}

final class MetalSampler: GPUSampler {
    let state: MTLSamplerState
    let descriptor: SamplerDescriptor
    init(state: MTLSamplerState, descriptor: SamplerDescriptor) {
        self.state = state
        self.descriptor = descriptor
    }
}

final class MetalPipeline: RenderPipeline {
    let state: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let cullMode: MTLCullMode
    let depthBias: DepthBias?
    /// `.screen` pipelines: `state` plus a motion-vector attachment, for scene passes that have
    /// one (temporal upscaling). Built on first use there.
    private let motionDescriptor: MTLRenderPipelineDescriptor?
    private var motionState: MTLRenderPipelineState?
    /// `.screen` pipelines on a multisampled device: `state` at 1x, for single-sample render
    /// targets. Built on first use there.
    private let singleSampleDescriptor: MTLRenderPipelineDescriptor?
    private var singleSampleState: MTLRenderPipelineState?

    init(state: MTLRenderPipelineState, depthState: MTLDepthStencilState, cullMode: MTLCullMode, depthBias: DepthBias?,
         motionDescriptor: MTLRenderPipelineDescriptor? = nil, singleSampleDescriptor: MTLRenderPipelineDescriptor? = nil) {
        self.state = state
        self.depthState = depthState
        self.cullMode = cullMode
        self.depthBias = depthBias
        self.motionDescriptor = motionDescriptor
        self.singleSampleDescriptor = singleSampleDescriptor
    }

    /// The variant for a pass with (`motionVectors`) or without a motion-vector attachment, and
    /// for a single-sample render target on a multisampled device (`singleSample`).
    func state(motionVectors: Bool, singleSample: Bool = false) -> MTLRenderPipelineState {
        if motionVectors { return variant(&motionState, motionDescriptor, "motion-vector") }
        if singleSample { return variant(&singleSampleState, singleSampleDescriptor, "single-sample") }
        return state
    }

    private func variant(_ cached: inout MTLRenderPipelineState?, _ descriptor: MTLRenderPipelineDescriptor?,
                         _ name: String) -> MTLRenderPipelineState {
        if let cached { return cached }
        guard let descriptor, let device = descriptor.vertexFunction?.device else {
            preconditionFailure("This pipeline has no \(name) variant (depth-only pipelines can't draw in color passes)")
        }
        do {
            let made = try device.makeRenderPipelineState(descriptor: descriptor)
            cached = made
            return made
        } catch {
            preconditionFailure("Failed to create the \(name) variant of a pipeline: \(error)")
        }
    }
}

/// See `GPURenderTarget`. The depth (and MSAA color) attachments are memoryless where supported.
final class MetalRenderTarget: GPURenderTarget {
    let resolved: MetalTexture
    let msaa: MTLTexture?
    let depth: MTLTexture
    var width: Int { resolved.width }
    var height: Int { resolved.height }
    var sampleCount: Int { msaa?.sampleCount ?? 1 }
    var texture: GPUTexture { resolved }

    init(resolved: MetalTexture, msaa: MTLTexture?, depth: MTLTexture) {
        self.resolved = resolved
        self.msaa = msaa
        self.depth = depth
    }
}

final class MetalRenderDevice: RenderDevice {
    let backend = GraphicsBackend.metal
    let device: MTLDevice
    let sampleCount: Int
    let maxTextureSize: Int
    var captureNextFrame = false
    var captureWindow = false
    var vsync: Bool {
        get { layer.displaySyncEnabled }
        set { layer.displaySyncEnabled = newValue }
    }
    var upscaler = Upscaler.bilinear
    var temporalInputs = TemporalInputs()
    var deviceName: String { device.name }
    /// The sum of the pass times when the GPU can time passes. The command buffer's span is the
    /// fallback, but it includes waits for the drawable, so it can read far higher than the GPU's actual work.
    var gpuFrameTime: Double? {
        guard !passTimestamps.isEmpty else { return lastGPUTime.get() }
        let passes = lastPassTimes.get()
        return passes.isEmpty ? nil : passes.reduce(0) { $0 + $1.seconds }
    }
    var gpuPassTimes: [GPUPassTime] { lastPassTimes.get() }

    private let queue: MTLCommandQueue
    private let layer: CAMetalLayer
    private let comparisonSampler: MTLSamplerState
    private let linearSampler: MTLSamplerState
    private let samplerCache = SamplerCache<MetalSampler>()
    private var blitPipeline: MetalPipeline!
    /// FSR 1 upscale pass, rendering into `UpscaleTargets.output`.
    private var easuPipeline: MTLRenderPipelineState!
    /// FSR 1 sharpen pass (also the plain copy after MetalFX), rendering into the window.
    private var rcasPipeline: MetalPipeline!
    /// TAAU pass, rendering the next history into `UpscaleTargets.outputs`.
    private var taauPipeline: MTLRenderPipelineState!
    private var upscaleTargets: UpscaleTargets?
    private let frameSemaphore = DispatchSemaphore(value: maxFramesInFlight)
    private let lastGPUTime = LockedValue<Double?>(nil)
    private let lastPassTimes = LockedValue<[GPUPassTime]>([])
    /// Per frame slot: timestamps at the start and end of each pass's vertex and fragment stages.
    /// Empty when the GPU can't sample counters at stage boundaries.
    private var passTimestamps: [MTLCounterSampleBuffer] = []
    /// An empty kernel, dispatched around MetalFX to time it (see `time(_:commandBuffer:_:)`).
    private var markerPipeline: MTLComputePipelineState?
    /// The passes timed so far in the current frame.
    private var timedPasses: [TimedPass] = []
    /// CPU (nanoseconds) and GPU timestamps sampled together at startup, to convert GPU ticks to seconds.
    private var timestampOrigin: (cpu: MTLTimestamp, gpu: MTLTimestamp) = (0, 0)
    // One transient ring per frame in flight; the semaphore guarantees the GPU is done
    // with ring N when frame N + maxFramesInFlight begins.
    private var transientRings: [TransientRing<MetalBuffer>] = []
    /// Per frame slot: the screen pass's visibility-result buffer (8 bytes per query) and
    /// which query sets its entries belong to. Same reuse guarantee as `transientRings`.
    private var occlusionResults: [MTLBuffer] = []
    private var occlusionBatches: [OcclusionQueryBatch] = []
    private var frameNumber = 0
    private var screenTargets: (color: MTLTexture?, depth: MTLTexture)?
    /// Scene targets at the render size when it differs from the window (see `RenderResolution`).
    private var sceneTargets: SceneTargets?

    private struct SceneTargets {
        var color: MTLTexture?  // multisampled, memoryless
        /// Memoryless, except with a temporal upscaler, which reads it.
        var depth: MTLTexture
        /// Single-sample result: sampled by the window pass and read back for screenshots.
        var resolved: MTLTexture
        /// `resolved` read without sRGB decoding: upscalers work on gamma-encoded values.
        var resolvedUnorm: MTLTexture
        /// Motion vectors, the scene pass's second color attachment (temporal upscalers only).
        var motion: MTLTexture?
    }

    /// First-stage upscaler output at the letterboxed window size (gamma-encoded), plus the
    /// MetalFX scaler that writes it when that upscaler is active. TAAU alternates between two
    /// outputs, reading the one it wrote last frame as its history.
    private struct UpscaleTargets {
        var stage: UpscalerStage
        var input: (width: Int, height: Int)
        var outputs: [MTLTexture]
        var metalFX: MTLFXSpatialScaler?
        var metalFXTemporal: MTLFXTemporalScaler?
        /// Temporal upscalers: the output written last, and whether any frame has written one.
        var current = 0
        var hasHistory = false
    }

    /// A pass timed with 4 timestamps: the start and end of its vertex and fragment stages, or
    /// (`span`) the start and end of the whole range in the first two.
    private struct TimedPass {
        var name: String
        var span = false
    }

    private struct FrameState {
        /// Commands not yet committed. Replaced by a new buffer when the drawable is acquired.
        var commandBuffer: MTLCommandBuffer
        /// Set by `acquireWindowTarget()`, nil until then and when no drawable was available.
        var drawable: CAMetalDrawable?
        /// What the window is drawn into: the drawable's texture, or `fallbackWindowTarget`.
        var windowTarget: MTLTexture?
        var ring: TransientRing<MetalBuffer>
        var slot: Int
        var capture: Bool
        var offscreen: Bool
        var windowSize: (width: Int, height: Int)
        /// GPU time of the frame's command buffers, summed as they complete (fallback timing).
        let gpuSpan = LockedValue(0.0)
    }

    private var frame: FrameState?
    /// Window-sized target for frames that couldn't get a drawable (rendered, then dropped).
    private var fallbackWindowTarget: MTLTexture?
    private var currentPass: MetalRenderPass?

    init(layer: CAMetalLayer, sampleCount requestedSamples: Int) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw GraphicsError("No Metal device available") }
        guard let queue = device.makeCommandQueue() else { throw GraphicsError("Failed to create Metal command queue") }
        self.device = device
        self.queue = queue
        self.layer = layer
        sampleCount = [8, 4, 2, 1].first { $0 <= requestedSamples && device.supportsTextureSampleCount($0) } ?? 1
        maxTextureSize = Self.maxTextureSize(device)
        layer.device = device
        layer.pixelFormat = .bgra8Unorm_srgb
        layer.framebufferOnly = true

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.compareFunction = .lessEqual
        samplerDescriptor.sAddressMode = .clampToBorderColor
        samplerDescriptor.tAddressMode = .clampToBorderColor
        samplerDescriptor.borderColor = .opaqueWhite
        guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw GraphicsError("Failed to create comparison sampler")
        }
        comparisonSampler = sampler

        let linearDescriptor = MTLSamplerDescriptor()
        linearDescriptor.minFilter = .linear
        linearDescriptor.magFilter = .linear
        linearDescriptor.sAddressMode = .clampToEdge
        linearDescriptor.tAddressMode = .clampToEdge
        guard let linear = device.makeSamplerState(descriptor: linearDescriptor) else {
            throw GraphicsError("Failed to create linear sampler")
        }
        linearSampler = linear

        transientRings = (0..<maxFramesInFlight).map { _ in
            TransientRing { size in
                guard let buffer = device.makeBuffer(length: size, options: .storageModeShared) else {
                    throw GraphicsError("Failed to allocate \(size) bytes of transient memory")
                }
                return (MetalBuffer(buffer), buffer.contents())
            }
        }

        if device.supportsCounterSampling(.atStageBoundary),
           let timestamps = device.counterSets?.first(where: { $0.name == MTLCommonCounterSet.timestamp.rawValue }) {
            let descriptor = MTLCounterSampleBufferDescriptor()
            descriptor.counterSet = timestamps
            descriptor.storageMode = .shared
            descriptor.sampleCount = maxTimedPasses * 4
            passTimestamps = (0..<maxFramesInFlight).compactMap { _ in try? device.makeCounterSampleBuffer(descriptor: descriptor) }
            if passTimestamps.count != maxFramesInFlight { passTimestamps = [] }
            timestampOrigin = device.sampleTimestamps()
            let library = try? device.makeLibrary(source: "kernel void marker(metal::texture2d<float> t [[texture(0)]]) {}", options: nil)
            markerPipeline = library?.makeFunction(name: "marker").flatMap { try? device.makeComputePipelineState(function: $0) }
        }

        for _ in 0..<maxFramesInFlight {
            let length = maxOcclusionQueriesPerFrame * MemoryLayout<UInt64>.size
            guard let buffer = device.makeBuffer(length: length, options: .storageModeShared) else {
                throw GraphicsError("Failed to allocate the occlusion query buffer")
            }
            memset(buffer.contents(), 0, length)
            occlusionResults.append(buffer)
            occlusionBatches.append(OcclusionQueryBatch())
        }

        var blit = PipelineDescriptor(shader: try ShaderSource.load(named: "blit", bundle: .module), vertexLayout: .none)
        blit.cullMode = .none
        blit.depthTest = false
        blit.depthWrite = false
        blitPipeline = try makePipeline(blit) as? MetalPipeline

        var rcas = PipelineDescriptor(shader: try ShaderSource.load(named: "fsr_rcas", bundle: .module), vertexLayout: .none)
        rcas.cullMode = .none
        rcas.depthTest = false
        rcas.depthWrite = false
        rcasPipeline = try makePipeline(rcas) as? MetalPipeline
        easuPipeline = try makeUpscalePipeline("fsr_easu", format: .bgra8Unorm)
        taauPipeline = try makeUpscalePipeline("taau", format: .rgba16Float)
    }

    /// Renders into a single-sample color texture of `format` with no depth.
    private func makeUpscalePipeline(_ name: String, format: MTLPixelFormat) throws -> MTLRenderPipelineState {
        let functions = try makeFunctions(ShaderSource.load(named: name, bundle: .module), fragment: true)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = functions.vertex
        descriptor.fragmentFunction = functions.fragment
        descriptor.colorAttachments[0].pixelFormat = format
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func supports(_ upscaler: Upscaler) -> Bool {
        switch upscaler {
        case .bilinear, .fsr1, .taau: true
        case .metalFXSpatial: MTLFXSpatialScalerDescriptor.supportsDevice(device)
        case .metalFXTemporal: MTLFXTemporalScalerDescriptor.supportsDevice(device)
        }
    }

    /// Whether this frame's scene pass feeds a temporal upscaler (needs 1x MSAA; `Engine` ensures it).
    private func temporal(offscreen: Bool) -> Bool {
        offscreen && upscaler.isTemporal && sampleCount == 1
    }

    /// Metal has no query for this; values from the Metal feature set tables (exceeding it
    /// asserts in validation rather than failing gracefully).
    private static func maxTextureSize(_ device: MTLDevice) -> Int {
        if #available(macOS 26.0, *), device.supportsFamily(.apple10) { return 32768 }
        return device.supportsFamily(.apple3) || device.supportsFamily(.mac2) ? 16384 : 8192
    }

    // MARK: - Resources

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard let base = bytes.baseAddress, bytes.count > 0,
              let buffer = device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        else { throw GraphicsError("Failed to create Metal buffer of \(bytes.count) bytes") }
        return MetalBuffer(buffer)
    }

    /// Blits from this frame's transient memory into the buffer, in the frame's command buffer.
    /// Buffers use default hazard tracking, so the blit waits for earlier command buffers (and
    /// encoders) that read the buffer, and later ones wait for the blit.
    func updateBuffer(_ buffer: GPUBuffer, offset: Int, bytes: UnsafeRawBufferPointer) throws {
        guard let frame else { preconditionFailure("updateBuffer outside a frame") }
        precondition(currentPass == nil, "updateBuffer called inside a pass; call it between passes")
        let target = buffer as! MetalBuffer
        try validateBufferUpdate(bufferLength: target.length, offset: offset, byteCount: bytes.count)
        guard bytes.count > 0 else { return }
        let source = uploadTransient(bytes)
        guard let blit = frame.commandBuffer.makeBlitCommandEncoder() else {
            preconditionFailure("Failed to create Metal blit encoder")
        }
        blit.copy(from: (source.buffer as! MetalBuffer).buffer, sourceOffset: source.offset,
                  to: target.buffer, destinationOffset: offset, size: bytes.count)
        blit.endEncoding()
    }

    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        guard descriptor.format == .depth32Float else {
            throw GraphicsError("Render targets must be .depth32Float; use makeTexture(pixels:...) for color textures")
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float, width: descriptor.width, height: descriptor.height, mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw GraphicsError("Failed to create \(descriptor.width)x\(descriptor.height) texture")
        }
        return MetalTexture(texture, format: descriptor.format)
    }

    func makeRenderTarget(_ descriptor: RenderTargetDescriptor) throws -> GPURenderTarget {
        try descriptor.validate(maxSize: maxTextureSize)
        let (width, height) = (descriptor.width, descriptor.height)
        let samples = descriptor.multisampled ? sampleCount : 1
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: layer.pixelFormat, width: width, height: height, mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private
        guard let resolved = device.makeTexture(descriptor: textureDescriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        return MetalRenderTarget(
            resolved: MetalTexture(resolved, format: .rgba8Srgb),
            msaa: samples > 1 ? try makeAttachment(layer.pixelFormat, width, height, samples: samples) : nil,
            depth: try makeAttachment(screenDepthFormat, width, height, samples: samples))
    }

    func makeTexture(levels: [TextureMipLevel], format: TextureFormat) throws -> GPUTexture {
        try format.validateLevels(levels, maxSize: maxTextureSize)
        let (width, height) = (levels[0].width, levels[0].height)
        let pixelFormat: MTLPixelFormat = switch format {
        case .rgba8Srgb: .rgba8Unorm_srgb
        case .rgba16Float: .rgba16Float
        default: .rgba8Unorm
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        textureDescriptor.mipmapLevelCount = levels.count
        textureDescriptor.usage = .shaderRead
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) texture")
        }
        for (level, mip) in levels.enumerated() {
            mip.pixels.withUnsafeBytes {
                texture.replace(
                    region: MTLRegionMake2D(0, 0, mip.width, mip.height), mipmapLevel: level, withBytes: $0.baseAddress!,
                    bytesPerRow: mip.width * format.bytesPerPixel)
            }
        }
        return MetalTexture(texture, format: format)
    }

    func updateTexture(_ texture: GPUTexture, region: TextureRegion, mipLevel: Int, bytes: UnsafeRawBufferPointer) throws {
        let target = texture as! MetalTexture
        try target.format.validateUpdate(
            region, mipLevel: mipLevel, byteCount: bytes.count,
            width: target.width, height: target.height, mipLevelCount: target.mipLevelCount)
        // Blit from a staging buffer on the device queue rather than `replace(region:)` from the
        // CPU: command buffers run in commit order with hazard tracking, so frames already
        // submitted still sample the old texels and later frames see the new ones (as on Vulkan).
        guard let staging = device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared),
              let commandBuffer = queue.makeCommandBuffer(),
              let blit = commandBuffer.makeBlitCommandEncoder() else {
            throw GraphicsError("Failed to encode a texture update")
        }
        blit.copy(from: staging, sourceOffset: 0, sourceBytesPerRow: region.width * target.format.bytesPerPixel,
                  sourceBytesPerImage: bytes.count, sourceSize: MTLSize(width: region.width, height: region.height, depth: 1),
                  to: target.texture, destinationSlice: 0, destinationLevel: mipLevel,
                  destinationOrigin: MTLOrigin(x: region.x, y: region.y, z: 0))
        blit.endEncoding()
        commandBuffer.commit()
    }

    func makeSampler(_ descriptor: SamplerDescriptor) throws -> GPUSampler {
        try samplerCache.sampler(for: descriptor) { descriptor in
            let sampler = MTLSamplerDescriptor()
            sampler.minFilter = descriptor.minFilter.metal
            sampler.magFilter = descriptor.magFilter.metal
            sampler.mipFilter = switch descriptor.mipFilter {
            case .none: .notMipmapped
            case .nearest: .nearest
            case .linear: .linear
            }
            let mode: MTLSamplerAddressMode = switch descriptor.addressMode {
            case .repeat: .repeat
            case .clampToEdge: .clampToEdge
            case .mirrorRepeat: .mirrorRepeat
            }
            sampler.sAddressMode = mode
            sampler.tAddressMode = mode
            guard let state = device.makeSamplerState(descriptor: sampler) else {
                throw GraphicsError("Failed to create sampler")
            }
            return MetalSampler(state: state, descriptor: descriptor)
        }
    }

    /// Compiles `vertex_main` and (if `fragment`) `fragment_main`, from one MSL source or from
    /// one per stage (see `ShaderSource.metalFragmentSource`). `color0Fragment` is the variant
    /// that writes only `[[color(0)]]` (`ShaderSource.metalFragmentColor0Source`), if any.
    private func makeFunctions(_ shader: ShaderSource, fragment: Bool)
        throws -> (vertex: MTLFunction, fragment: MTLFunction?, color0Fragment: MTLFunction?) {
        guard let source = shader.metalSource else {
            throw GraphicsError("Shader has no Metal source")
        }
        let library = try device.makeLibrary(source: source, options: nil)
        guard let vertexFunction = library.makeFunction(name: "vertex_main") else {
            throw GraphicsError("Metal shader must define vertex_main")
        }
        guard fragment else { return (vertexFunction, nil, nil) }
        let fragmentLibrary = try shader.metalFragmentSource.map { try device.makeLibrary(source: $0, options: nil) } ?? library
        guard let fragmentFunction = fragmentLibrary.makeFunction(name: "fragment_main") else {
            throw GraphicsError("Metal shader must define fragment_main")
        }
        let color0Function = try shader.metalFragmentColor0Source.map {
            guard let function = try device.makeLibrary(source: $0, options: nil).makeFunction(name: "fragment_main") else {
                throw GraphicsError("Metal shader must define fragment_main")
            }
            return function
        }
        return (vertexFunction, fragmentFunction, color0Function)
    }

    func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        let functions = try makeFunctions(descriptor.shader, fragment: descriptor.target == .screen || descriptor.depthOnlyFragment)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = functions.vertex
        pipelineDescriptor.vertexDescriptor = Self.vertexDescriptor(descriptor)

        switch descriptor.target {
        case .screen:
            // Passes without a motion attachment get the color-0-only variant (see
            // ShaderSource.metalFragmentColor0Source); the motion variant below gets the full one.
            pipelineDescriptor.fragmentFunction = functions.color0Fragment ?? functions.fragment
            pipelineDescriptor.depthAttachmentPixelFormat = screenDepthFormat
            pipelineDescriptor.rasterSampleCount = sampleCount
            let color = pipelineDescriptor.colorAttachments[0]!
            color.pixelFormat = layer.pixelFormat
            color.writeMask = descriptor.colorWrites ? .all : []
            if descriptor.alphaBlending {
                color.isBlendingEnabled = true
                color.sourceRGBBlendFactor = .sourceAlpha
                color.destinationRGBBlendFactor = .oneMinusSourceAlpha
                color.sourceAlphaBlendFactor = .one
                color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
        case .depthOnly:
            pipelineDescriptor.fragmentFunction = functions.fragment
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            pipelineDescriptor.rasterSampleCount = 1
        }
        var motionDescriptor: MTLRenderPipelineDescriptor?
        if descriptor.target == .screen, let copy = pipelineDescriptor.copy() as? MTLRenderPipelineDescriptor {
            copy.fragmentFunction = functions.fragment
            let motion = copy.colorAttachments[1]!
            motion.pixelFormat = motionVectorFormat
            motion.writeMask = descriptor.writesMotionVectors && descriptor.colorWrites ? [.red, .green] : []
            motionDescriptor = copy
        }
        var singleSampleDescriptor: MTLRenderPipelineDescriptor?
        if descriptor.target == .screen, sampleCount > 1, let copy = pipelineDescriptor.copy() as? MTLRenderPipelineDescriptor {
            copy.rasterSampleCount = 1
            singleSampleDescriptor = copy
        }
        let state = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = descriptor.depthTest ? descriptor.depthCompare.metal : .always
        depthDescriptor.isDepthWriteEnabled = descriptor.depthWrite
        guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            throw GraphicsError("Failed to create depth-stencil state")
        }

        let cull: MTLCullMode = switch descriptor.cullMode {
        case .none: .none
        case .front: .front
        case .back: .back
        }
        return MetalPipeline(
            state: state, depthState: depthState, cullMode: cull, depthBias: descriptor.depthBias,
            motionDescriptor: motionDescriptor, singleSampleDescriptor: singleSampleDescriptor)
    }

    func uploadTransient(_ bytes: UnsafeRawBufferPointer) -> TransientBuffer {
        guard let frame else { preconditionFailure("uploadTransient outside a frame") }
        do {
            let allocation = try frame.ring.upload(bytes, alignment: 16)
            return TransientBuffer(buffer: allocation.chunk, offset: allocation.offset, length: bytes.count)
        } catch {
            preconditionFailure("\(error)")
        }
    }

    private static func vertexDescriptor(_ descriptor: PipelineDescriptor) -> MTLVertexDescriptor? {
        let layouts = [(descriptor.vertexLayout, 0), (descriptor.instanceLayout ?? .none, metalInstanceBufferIndex)]
        guard layouts.contains(where: { !$0.0.attributes.isEmpty }) else { return nil }
        let vertexDescriptor = MTLVertexDescriptor()
        for (layout, bufferIndex) in layouts where !layout.attributes.isEmpty {
            for attribute in layout.attributes {
                vertexDescriptor.attributes[attribute.location].format = attribute.format.metal
                vertexDescriptor.attributes[attribute.location].offset = attribute.offset
                vertexDescriptor.attributes[attribute.location].bufferIndex = bufferIndex
            }
            vertexDescriptor.layouts[bufferIndex].stride = layout.stride
            vertexDescriptor.layouts[bufferIndex].stepFunction = bufferIndex == 0 ? .perVertex : .perInstance
        }
        return vertexDescriptor
    }

    // MARK: - Frames

    func beginFrame(framebufferSize: (width: Int, height: Int), renderSize: (width: Int, height: Int)?) throws -> Bool {
        precondition(frame == nil, "beginFrame called twice without endFrame")
        guard framebufferSize.width > 0, framebufferSize.height > 0 else { return false }

        let size = CGSize(width: framebufferSize.width, height: framebufferSize.height)
        if layer.drawableSize != size { layer.drawableSize = size }
        // Reading the drawable back requires a non-framebuffer-only layer.
        let capture = captureNextFrame
        captureNextFrame = false
        layer.framebufferOnly = !(capture && (renderSize == nil || captureWindow))

        frameSemaphore.wait()
        guard let commandBuffer = queue.makeCommandBuffer() else {
            frameSemaphore.signal()
            return false
        }

        let slot = frameNumber % maxFramesInFlight
        let ring = transientRings[slot]
        ring.reset()
        resolveOcclusionQueries(slot: slot)
        frameNumber += 1
        try ensureScreenTargets(width: framebufferSize.width, height: framebufferSize.height)
        if let renderSize {
            try ensureSceneTargets(width: renderSize.width, height: renderSize.height, temporal: temporal(offscreen: true))
        } else {
            sceneTargets = nil
        }
        frame = FrameState(
            commandBuffer: commandBuffer, ring: ring, slot: slot, capture: capture, offscreen: renderSize != nil,
            windowSize: framebufferSize)
        return true
    }

    /// The texture the window is drawn into this frame, acquiring the drawable on first use.
    /// `nextDrawable()` blocks until the window server releases one, so everything recorded
    /// before it (shadow maps, an offscreen scene) is committed first: the GPU works on that
    /// while the CPU waits.
    private func acquireWindowTarget() -> MTLTexture {
        guard var frame else { preconditionFailure("Window target requested outside a frame") }
        if let target = frame.windowTarget { return target }
        commit(frame)
        guard let commandBuffer = queue.makeCommandBuffer() else { preconditionFailure("Failed to create Metal command buffer") }
        frame.commandBuffer = commandBuffer
        if let drawable = layer.nextDrawable() {
            frame.drawable = drawable
            frame.windowTarget = drawable.texture
        } else {
            // Timed out (e.g. the window is occluded): render the frame anyway and drop it.
            let size = frame.windowSize
            if fallbackWindowTarget?.width != size.width || fallbackWindowTarget?.height != size.height {
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: layer.pixelFormat, width: size.width, height: size.height, mipmapped: false)
                descriptor.usage = .renderTarget
                descriptor.storageMode = .private
                fallbackWindowTarget = device.makeTexture(descriptor: descriptor)
            }
            frame.windowTarget = fallbackWindowTarget
        }
        self.frame = frame
        guard let target = frame.windowTarget else { preconditionFailure("Failed to create a fallback window target") }
        return target
    }

    /// Commits the frame's current command buffer, adding its GPU time to the frame's span,
    /// then calling `completion` once the GPU is done with it.
    private func commit(_ frame: FrameState, completion: (@Sendable () -> Void)? = nil) {
        let span = frame.gpuSpan
        frame.commandBuffer.addCompletedHandler { commandBuffer in
            // A queue completes its command buffers in order, so these never run concurrently.
            if commandBuffer.gpuEndTime > commandBuffer.gpuStartTime {
                span.set(span.get() + commandBuffer.gpuEndTime - commandBuffer.gpuStartTime)
            }
            completion?()
        }
        frame.commandBuffer.commit()
    }

    /// Hands the slot's previous results to their query sets and clears what they used.
    private func resolveOcclusionQueries(slot: Int) {
        let batch = occlusionBatches[slot]
        let used = batch.count
        guard used > 0 else { return }
        let results = occlusionResults[slot].contents().assumingMemoryBound(to: UInt64.self)
        batch.resolve { results[$0] != 0 }
        memset(results, 0, used * MemoryLayout<UInt64>.size)
    }

    func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.depthAttachment.texture = (target as! MetalTexture).texture
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.clearDepth = Double(clearDepth)
        return beginPass(passDescriptor, timedAs: "depth")
    }

    func beginPass(target: GPURenderTarget, clearColor: Vec4, clearDepth: Float, label: String) -> RenderPass {
        let target = target as! MetalRenderTarget
        let descriptor = Self.colorDepthPass(
            msaa: target.msaa, target: target.resolved.texture, depth: target.depth, clearColor: clearColor, clearDepth: clearDepth)
        // Textures are hazard-tracked, so later reads of the result (in this or a later command
        // buffer of the queue) wait for this pass, and this pass waits for earlier frames' reads.
        return beginPass(descriptor, timedAs: label, singleSample: target.sampleCount == 1 && sampleCount > 1)
    }

    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginScreenPass outside a frame") }
        let descriptor = if frame.offscreen, let scene = sceneTargets {
            Self.colorDepthPass(
                msaa: scene.color, target: scene.resolved, depth: scene.depth, clearColor: clearColor, clearDepth: clearDepth)
        } else {
            Self.colorDepthPass(
                msaa: targets.color, target: acquireWindowTarget(), depth: targets.depth, clearColor: clearColor,
                clearDepth: clearDepth)
        }
        let motion = frame.offscreen ? sceneTargets?.motion : nil
        if let motion {
            // Temporal upscaling: motion vectors (0 where nothing is drawn) and depth are kept for the upscaler.
            let attachment = descriptor.colorAttachments[1]!
            attachment.texture = motion
            attachment.loadAction = .clear
            attachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            attachment.storeAction = .store
            descriptor.depthAttachment.storeAction = .store
        }
        descriptor.visibilityResultBuffer = occlusionResults[frame.slot]
        return beginPass(descriptor, timedAs: "scene", occlusion: occlusionBatches[frame.slot], motionVectors: motion != nil)
    }

    func beginWindowPass() -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginWindowPass outside a frame") }
        guard frame.offscreen, let scene = sceneTargets else {
            guard let currentPass else { preconditionFailure("beginWindowPass must follow beginScreenPass") }
            return currentPass
        }
        endPass()
        let image = (width: scene.resolved.width, height: scene.resolved.height)
        let rect = letterboxRect(image: image, window: frame.windowSize)
        let upscaled = upscale(scene, to: (rect.width, rect.height), commandBuffer: frame.commandBuffer)

        let pass = beginPass(Self.colorDepthPass(
            msaa: targets.color, target: acquireWindowTarget(), depth: targets.depth, clearColor: Vec4(0, 0, 0, 1), clearDepth: 1),
            timedAs: "window")
        let metalPass = pass as! MetalRenderPass
        if let upscaled {
            // Sharpen (or copy) the upscaled image 1:1 into its pixel-aligned rectangle.
            metalPass.setPipeline(rcasPipeline)
            metalPass.encoder.setViewport(MTLViewport(
                originX: Double(rect.x), originY: Double(rect.y), width: Double(rect.width), height: Double(rect.height),
                znear: 0, zfar: 1))
            metalPass.encoder.setFragmentTexture(upscaled, index: 0)
            metalPass.setPushConstants(RcasConstants(rect: rect, sharpness: upscaler.rcasSharpness))
            metalPass.draw(vertexCount: 3)
            metalPass.encoder.setViewport(MTLViewport(
                originX: 0, originY: 0, width: Double(frame.windowSize.width), height: Double(frame.windowSize.height),
                znear: 0, zfar: 1))
        } else {
            metalPass.setPipeline(blitPipeline)
            metalPass.encoder.setFragmentTexture(scene.resolved, index: 0)
            metalPass.encoder.setFragmentSamplerState(linearSampler, index: 0)
            metalPass.setPushConstants(BlitConstants(image: image, window: frame.windowSize))
            metalPass.draw(vertexCount: 3)
        }
        return pass
    }

    /// Runs the upscaler's first stage (FSR 1 EASU, TAAU or MetalFX) from the scene image into
    /// a texture of `size`, for the window pass to sharpen or copy. nil means bilinear.
    private func upscale(_ scene: SceneTargets, to size: (width: Int, height: Int),
                         commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard upscaler != .bilinear else { return nil }
        let input = (width: scene.resolved.width, height: scene.resolved.height)
        let targets: UpscaleTargets
        do {
            targets = try ensureUpscaleTargets(input: input, output: size)
        } catch {
            print("\(upscaler) unavailable, using bilinear: \(error)")
            upscaler = .bilinear
            return nil
        }
        // A fresh scaler or history has nothing to blend with yet.
        let reset = temporalInputs.resetHistory || !targets.hasHistory
        switch upscaler {
        case .bilinear:
            return nil
        case .fsr1:
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = targets.outputs[0]
            passDescriptor.colorAttachments[0].loadAction = .dontCare
            passDescriptor.colorAttachments[0].storeAction = .store
            time(passDescriptor, as: "upscale")
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return nil }
            encoder.setRenderPipelineState(easuPipeline)
            encoder.setFragmentTexture(scene.resolvedUnorm, index: 0)
            var constants = EasuConstants(input: input, output: size)
            encoder.setFragmentBytes(&constants, length: MemoryLayout<EasuConstants>.size, index: metalPushConstantIndex)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        case .metalFXSpatial:
            guard let scaler = targets.metalFX else { return nil }
            scaler.colorTexture = scene.resolvedUnorm
            scaler.outputTexture = targets.outputs[0]
            time("upscale", input: scene.resolvedUnorm, output: targets.outputs[0], commandBuffer: commandBuffer) { scaler.encode(commandBuffer: commandBuffer) }
        case .metalFXTemporal:
            guard let scaler = targets.metalFXTemporal, let motion = scene.motion else { return nil }
            scaler.colorTexture = scene.resolvedUnorm
            scaler.depthTexture = scene.depth
            scaler.motionTexture = motion
            scaler.outputTexture = targets.outputs[0]
            // Same convention as ours (render pixels, y down, how far the image moved). Checked against
            // a native render of a paused scene: the negated offset more than doubles the error.
            scaler.jitterOffsetX = temporalInputs.jitter.x
            scaler.jitterOffsetY = temporalInputs.jitter.y
            // Motion vectors are in UV units; MetalFX wants render pixels.
            scaler.motionVectorScaleX = Float(input.width)
            scaler.motionVectorScaleY = Float(input.height)
            scaler.isDepthReversed = temporalInputs.reversedDepth
            scaler.reset = reset
            time("upscale", input: scene.resolvedUnorm, output: targets.outputs[0], commandBuffer: commandBuffer) { scaler.encode(commandBuffer: commandBuffer) }
            upscaleTargets?.hasHistory = true
        case .taau:
            guard let motion = scene.motion else { return nil }
            let next = 1 - targets.current
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = targets.outputs[next]
            passDescriptor.colorAttachments[0].loadAction = .dontCare
            passDescriptor.colorAttachments[0].storeAction = .store
            time(passDescriptor, as: "upscale")
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return nil }
            encoder.setRenderPipelineState(taauPipeline)
            // Texture n matches set 2, binding 8 + n in taau.frag.
            encoder.setFragmentTexture(scene.resolvedUnorm, index: 1)
            encoder.setFragmentTexture(scene.depth, index: 2)
            encoder.setFragmentTexture(motion, index: 3)
            encoder.setFragmentTexture(targets.outputs[targets.current], index: 4)
            var constants = TaauConstants(input: input, output: size, inputs: temporalInputs, reset: reset)
            encoder.setFragmentBytes(&constants, length: MemoryLayout<TaauConstants>.size, index: metalPushConstantIndex)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            upscaleTargets?.current = next
            upscaleTargets?.hasHistory = true
            return targets.outputs[next]
        }
        return targets.outputs[0]
    }

    private func ensureUpscaleTargets(input: (width: Int, height: Int), output: (width: Int, height: Int)) throws -> UpscaleTargets {
        let stage = upscaler.firstStage
        if let targets = upscaleTargets, targets.stage == stage, targets.input == input,
           targets.outputs[0].width == output.width, targets.outputs[0].height == output.height {
            return targets
        }
        upscaleTargets = nil
        var usage: MTLTextureUsage = [.renderTarget, .shaderRead]
        var format = MTLPixelFormat.bgra8Unorm
        var spatial: MTLFXSpatialScaler?
        var temporal: MTLFXTemporalScaler?
        switch stage {
        case .metalFXSpatial:
            let descriptor = MTLFXSpatialScalerDescriptor()
            descriptor.inputWidth = input.width
            descriptor.inputHeight = input.height
            descriptor.outputWidth = output.width
            descriptor.outputHeight = output.height
            descriptor.colorTextureFormat = .bgra8Unorm
            descriptor.outputTextureFormat = .bgra8Unorm
            descriptor.colorProcessingMode = .perceptual
            guard let made = descriptor.makeSpatialScaler(device: device) else {
                throw GraphicsError("Failed to create a MetalFX spatial scaler")
            }
            spatial = made
            usage.formUnion(made.outputTextureUsage)
        case .metalFXTemporal:
            let descriptor = MTLFXTemporalScalerDescriptor()
            descriptor.inputWidth = input.width
            descriptor.inputHeight = input.height
            descriptor.outputWidth = output.width
            descriptor.outputHeight = output.height
            descriptor.colorTextureFormat = .bgra8Unorm
            descriptor.depthTextureFormat = screenDepthFormat
            descriptor.motionTextureFormat = motionVectorFormat
            descriptor.outputTextureFormat = .bgra8Unorm
            guard let made = descriptor.makeTemporalScaler(device: device) else {
                throw GraphicsError("Failed to create a MetalFX temporal scaler")
            }
            temporal = made
            usage.formUnion(made.outputTextureUsage)
        case .taau:
            // Color plus accumulated weight, with headroom so small blends don't stall in 8 bits.
            format = .rgba16Float
        case .none, .easu:
            break
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: output.width, height: output.height, mipmapped: false)
        descriptor.usage = usage
        descriptor.storageMode = .private
        let outputs = (0..<(stage == .taau ? 2 : 1)).compactMap { _ in device.makeTexture(descriptor: descriptor) }
        guard outputs.count == (stage == .taau ? 2 : 1) else {
            throw GraphicsError("Failed to create \(output.width)x\(output.height) upscale target")
        }
        let targets = UpscaleTargets(stage: stage, input: input, outputs: outputs, metalFX: spatial, metalFXTemporal: temporal)
        upscaleTargets = targets
        return targets
    }

    /// Color (resolved from `msaa` when multisampled) + depth, both cleared.
    private static func colorDepthPass(msaa: MTLTexture?, target: MTLTexture, depth: MTLTexture,
                                       clearColor: Vec4, clearDepth: Float) -> MTLRenderPassDescriptor {
        let passDescriptor = MTLRenderPassDescriptor()
        let color = passDescriptor.colorAttachments[0]!
        if let msaa {
            color.texture = msaa
            color.resolveTexture = target
            color.storeAction = .multisampleResolve
        } else {
            color.texture = target
            color.storeAction = .store
        }
        color.loadAction = .clear
        color.clearColor = MTLClearColor(
            red: Double(clearColor.x), green: Double(clearColor.y), blue: Double(clearColor.z), alpha: Double(clearColor.w))
        passDescriptor.depthAttachment.texture = depth
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .dontCare
        passDescriptor.depthAttachment.clearDepth = Double(clearDepth)
        return passDescriptor
    }

    private func beginPass(_ descriptor: MTLRenderPassDescriptor, timedAs name: String,
                           occlusion: OcclusionQueryBatch? = nil, motionVectors: Bool = false,
                           singleSample: Bool = false) -> RenderPass {
        guard let frame else { preconditionFailure("Render pass started outside a frame") }
        precondition(currentPass == nil, "Previous pass was not ended")
        time(descriptor, as: name)
        guard let encoder = frame.commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            preconditionFailure("Failed to create Metal render encoder")
        }
        let pass = MetalRenderPass(
            encoder: encoder, transient: frame.ring, comparisonSampler: comparisonSampler,
            targetSize: (descriptor.colorAttachments[0].texture?.width ?? 1, descriptor.colorAttachments[0].texture?.height ?? 1),
            occlusion: occlusion, motionVectors: motionVectors, singleSample: singleSample)
        currentPass = pass
        return pass
    }

    /// Samples GPU timestamps around the pass's vertex and fragment stages, for `gpuPassTimes`.
    /// A pass's time is the sum of the two stages. Measuring from vertex start to fragment end
    /// instead would include waits: on a tile GPU the fragment stage often waits for the previous
    /// pass to finish, or for the window server to release the drawable.
    private func time(_ descriptor: MTLRenderPassDescriptor, as name: String) {
        guard let frame, !passTimestamps.isEmpty, timedPasses.count < maxTimedPasses else { return }
        let attachment = descriptor.sampleBufferAttachments[0]!
        let first = timedPasses.count * 4
        attachment.sampleBuffer = passTimestamps[frame.slot]
        attachment.startOfVertexSampleIndex = first
        attachment.endOfVertexSampleIndex = first + 1
        attachment.startOfFragmentSampleIndex = first + 2
        attachment.endOfFragmentSampleIndex = first + 3
        timedPasses.append(TimedPass(name: name))
    }

    /// Times work encoded by `body` that isn't one of our render passes (MetalFX encodes its own
    /// compute passes), from reading `input` to writing `output`. One-thread compute passes
    /// before and after it sample the start and the end (an empty pass samples nothing). Each
    /// binds one of the textures, so hazard tracking orders it after the input's writer and
    /// after the work; unbound, the GPU may run the markers alongside it.
    private func time(_ name: String, input: MTLTexture, output: MTLTexture, commandBuffer: MTLCommandBuffer,
                      _ body: () -> Void) {
        guard let frame, let markerPipeline, !passTimestamps.isEmpty, timedPasses.count < maxTimedPasses else {
            return body()
        }
        let first = timedPasses.count * 4
        func marker(start: Int, end: Int, texture: MTLTexture) {
            let descriptor = MTLComputePassDescriptor()
            let attachment = descriptor.sampleBufferAttachments[0]!
            attachment.sampleBuffer = passTimestamps[frame.slot]
            attachment.startOfEncoderSampleIndex = start
            attachment.endOfEncoderSampleIndex = end
            guard let encoder = commandBuffer.makeComputeCommandEncoder(descriptor: descriptor) else { return }
            encoder.setComputePipelineState(markerPipeline)
            encoder.setTexture(texture, index: 0)
            encoder.dispatchThreads(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            encoder.endEncoding()
        }
        marker(start: first, end: MTLCounterDontSample, texture: input)
        body()
        marker(start: MTLCounterDontSample, end: first + 1, texture: output)
        timedPasses.append(TimedPass(name: name, span: true))
    }

    /// Converts the frame's pass timestamps to `lastPassTimes` once the GPU is done.
    private func resolvePassTimes(of commandBuffer: MTLCommandBuffer, slot: Int) {
        guard !timedPasses.isEmpty else { return }
        let passes = timedPasses
        timedPasses = []
        // Only read once the GPU is done with it, and not reused until this slot comes back around.
        nonisolated(unsafe) let sampleBuffer = passTimestamps[slot]
        let passTimes = lastPassTimes
        let device = device
        let origin = timestampOrigin
        commandBuffer.addCompletedHandler { _ in
            guard let data = try? sampleBuffer.resolveCounterRange(0..<passes.count * 4) else { return }
            // GPU ticks have no fixed unit: measure them against the CPU clock (nanoseconds) since startup.
            let now = device.sampleTimestamps()
            guard now.gpu > origin.gpu, now.cpu > origin.cpu else { return }
            let nanosecondsPerTick = Double(now.cpu - origin.cpu) / Double(now.gpu - origin.gpu)
            let times = data.withUnsafeBytes { raw in
                let ticks = raw.bindMemory(to: MTLCounterResultTimestamp.self)
                // A stage that didn't run (e.g. no draws) samples an error value or zeros.
                func stage(_ start: Int) -> UInt64 {
                    let begin = ticks[start].timestamp, end = ticks[start + 1].timestamp
                    guard begin != MTLCounterErrorValue, end != MTLCounterErrorValue, begin > 0, end > begin else { return 0 }
                    return end - begin
                }
                return passes.indices.map { i in
                    let busy = passes[i].span ? stage(i * 4) : stage(i * 4) + stage(i * 4 + 2)
                    return GPUPassTime(name: passes[i].name, seconds: Double(busy) * nanosecondsPerTick * 1e-9)
                }
            }
            passTimes.set(times)
        }
    }

    func endPass() {
        currentPass?.occlusion?.checkClosed()
        currentPass?.encoder.endEncoding()
        currentPass = nil
    }

    func endFrame() throws -> Image? {
        guard let frame else { return nil }
        endPass()
        self.frame = nil

        var readback: (buffer: MTLBuffer, width: Int, height: Int)?
        if frame.capture, let texture = frame.offscreen && !captureWindow ? sceneTargets?.resolved : frame.drawable?.texture {
            let bytesPerRow = texture.width * 4
            if let buffer = device.makeBuffer(length: bytesPerRow * texture.height, options: .storageModeShared),
               let blit = frame.commandBuffer.makeBlitCommandEncoder() {
                blit.copy(
                    from: texture, sourceSlice: 0, sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                    sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
                    to: buffer, destinationOffset: 0,
                    destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * texture.height)
                blit.endEncoding()
                readback = (buffer, texture.width, texture.height)
            }
        }

        resolvePassTimes(of: frame.commandBuffer, slot: frame.slot)
        if let drawable = frame.drawable { frame.commandBuffer.present(drawable) }
        let semaphore = frameSemaphore
        let gpuTime = lastGPUTime
        let span = frame.gpuSpan
        commit(frame) {
            gpuTime.set(span.get())
            semaphore.signal()
        }

        guard let readback else { return nil }
        frame.commandBuffer.waitUntilCompleted()
        let bytes = UnsafeRawBufferPointer(start: readback.buffer.contents(), count: readback.buffer.length)
        return Image(width: readback.width, height: readback.height, bgra: bytes, bytesPerRow: readback.width * 4)
    }

    func waitIdle() {
        // Commit an empty command buffer and wait: the queue executes in order.
        let commandBuffer = queue.makeCommandBuffer()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }

    func shutdown() {}

    /// Multisampled color (when MSAA is on) and depth matching the drawable size.
    private func ensureScreenTargets(width: Int, height: Int) throws {
        if let targets = screenTargets, targets.depth.width == width, targets.depth.height == height { return }
        screenTargets = (sampleCount > 1 ? try makeAttachment(layer.pixelFormat, width, height) : nil,
                         try makeAttachment(screenDepthFormat, width, height))
    }

    /// Offscreen scene targets at the render size. `temporal` adds motion vectors and keeps the depth.
    private func ensureSceneTargets(width: Int, height: Int, temporal: Bool) throws {
        if let targets = sceneTargets, targets.resolved.width == width, targets.resolved.height == height,
           (targets.motion != nil) == temporal {
            return
        }
        sceneTargets = nil  // free the old ones before allocating (they can be huge)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: layer.pixelFormat, width: width, height: height, mipmapped: false)
        // No `.pixelFormatView`: a view that only drops sRGB doesn't need it, and it disables lossless
        // compression, which made sampling this texture 3-4x slower.
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let resolved = device.makeTexture(descriptor: descriptor),
              let resolvedUnorm = resolved.makeTextureView(pixelFormat: .bgra8Unorm)
        else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        sceneTargets = SceneTargets(
            color: sampleCount > 1 ? try makeAttachment(layer.pixelFormat, width, height) : nil,
            depth: temporal ? try makeSampledTarget(screenDepthFormat, width, height)
                : try makeAttachment(screenDepthFormat, width, height),
            resolved: resolved,
            resolvedUnorm: resolvedUnorm,
            motion: temporal ? try makeSampledTarget(motionVectorFormat, width, height) : nil)
    }

    /// A single-sample render target that later passes read (temporal upscaler inputs).
    private func makeSampledTarget(_ format: MTLPixelFormat, _ width: Int, _ height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        return texture
    }

    /// A pass attachment that is never stored, with `samples` (default: the device's MSAA) samples.
    private func makeAttachment(_ format: MTLPixelFormat, _ width: Int, _ height: Int, samples: Int? = nil) throws -> MTLTexture {
        let samples = samples ?? sampleCount
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: width, height: height, mipmapped: false)
        descriptor.usage = .renderTarget
        // Tile memory is enough for attachments that are never stored (Apple GPUs only).
        descriptor.storageMode = device.supportsFamily(.apple1) ? .memoryless : .private
        if samples > 1 {
            descriptor.textureType = .type2DMultisample
            descriptor.sampleCount = samples
        }
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        return texture
    }
}

final class MetalRenderPass: RenderPass {
    let encoder: MTLRenderCommandEncoder
    private let transient: TransientRing<MetalBuffer>
    private let comparisonSampler: MTLSamplerState
    private var indexBuffer: (buffer: MTLBuffer, offset: Int, type: IndexType)?
    private let targetSize: (width: Int, height: Int)
    /// Set for passes with a visibility-result buffer (the screen pass).
    let occlusion: OcclusionQueryBatch?
    /// The pass has a motion-vector attachment (scene pass with temporal upscaling).
    let motionVectors: Bool
    /// A single-sample render target on a multisampled device: pipelines use their 1x variant.
    let singleSample: Bool

    init(encoder: MTLRenderCommandEncoder, transient: TransientRing<MetalBuffer>, comparisonSampler: MTLSamplerState,
         targetSize: (width: Int, height: Int), occlusion: OcclusionQueryBatch?, motionVectors: Bool = false,
         singleSample: Bool = false) {
        self.encoder = encoder
        self.targetSize = targetSize
        self.transient = transient
        self.comparisonSampler = comparisonSampler
        self.occlusion = occlusion
        self.motionVectors = motionVectors
        self.singleSample = singleSample
        encoder.setFrontFacing(.counterClockwise)
    }

    func setPipeline(_ pipeline: RenderPipeline) {
        let pipeline = pipeline as! MetalPipeline
        encoder.setRenderPipelineState(pipeline.state(motionVectors: motionVectors, singleSample: singleSample))
        encoder.setDepthStencilState(pipeline.depthState)
        encoder.setCullMode(pipeline.cullMode)
        let bias = pipeline.depthBias ?? DepthBias(constant: 0, slopeScale: 0)
        encoder.setDepthBias(bias.constant, slopeScale: bias.slopeScale, clamp: 0)
    }

    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        encoder.setVertexBuffer((buffer as! MetalBuffer).buffer, offset: offset, index: index)
    }

    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        let allocation = upload(bytes, alignment: 16)
        encoder.setVertexBuffer(allocation.chunk.buffer, offset: allocation.offset, index: index)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxUniformDataSize, "Uniform data exceeds \(maxUniformDataSize) bytes")
        let allocation = upload(bytes, alignment: 256)
        encoder.setVertexBuffer(allocation.chunk.buffer, offset: allocation.offset, index: metalUniformBufferIndex)
        encoder.setFragmentBuffer(allocation.chunk.buffer, offset: allocation.offset, index: metalUniformBufferIndex)
    }

    func setTexture(_ texture: GPUTexture) {
        encoder.setFragmentTexture((texture as! MetalTexture).texture, index: 0)
        encoder.setFragmentSamplerState(comparisonSampler, index: 0)
    }

    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(offset % uniformBufferOffsetAlignment == 0, "Uniform buffer offset must be a multiple of \(uniformBufferOffsetAlignment)")
        let buffer = (buffer as! MetalBuffer).buffer
        if stage.contains(.vertex) { encoder.setVertexBuffer(buffer, offset: offset, index: index) }
        if stage.contains(.fragment) { encoder.setFragmentBuffer(buffer, offset: offset, index: index) }
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        let allocation = upload(bytes, alignment: uniformBufferOffsetAlignment)
        if stage.contains(.vertex) { encoder.setVertexBuffer(allocation.chunk.buffer, offset: allocation.offset, index: index) }
        if stage.contains(.fragment) { encoder.setFragmentBuffer(allocation.chunk.buffer, offset: allocation.offset, index: index) }
    }

    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Texture index \(index) is outside \(textureIndices)")
        let texture = texture as! MetalTexture
        precondition(!texture.format.isDepth, "Depth textures are bound with setTexture(_:)")
        if stage.contains(.vertex) { encoder.setVertexTexture(texture.texture, index: index) }
        if stage.contains(.fragment) { encoder.setFragmentTexture(texture.texture, index: index) }
    }

    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Sampler index \(index) is outside \(textureIndices)")
        let state = (sampler as! MetalSampler).state
        if stage.contains(.vertex) { encoder.setVertexSamplerState(state, index: index) }
        if stage.contains(.fragment) { encoder.setFragmentSamplerState(state, index: index) }
    }

    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) {
        indexBuffer = ((buffer as! MetalBuffer).buffer, 0, type)
    }

    func setIndexData(_ bytes: UnsafeRawBufferPointer, type: IndexType) {
        let allocation = upload(bytes, alignment: 16)
        indexBuffer = (allocation.chunk.buffer, allocation.offset, type)
    }

    func setScissorRect(_ rect: ScissorRect?) {
        let r = (rect ?? ScissorRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
            .clamped(toWidth: targetSize.width, height: targetSize.height)
        encoder.setScissorRect(MTLScissorRect(x: r.x, y: r.y, width: r.width, height: r.height))
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        guard let base = bytes.baseAddress else { return }
        encoder.setVertexBytes(base, length: bytes.count, index: metalPushConstantIndex)
        encoder.setFragmentBytes(base, length: bytes.count, index: metalPushConstantIndex)
    }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        encoder.drawPrimitives(
            type: .triangle, vertexStart: firstVertex, vertexCount: vertexCount, instanceCount: instanceCount)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        guard let (buffer, offset, type) = indexBuffer else { preconditionFailure("drawIndexed without an index buffer") }
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: type == .uint16 ? .uint16 : .uint32,
            indexBuffer: buffer,
            indexBufferOffset: offset + firstIndex * type.size,
            instanceCount: instanceCount)
    }

    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.begin(set, index: index)
        encoder.setVisibilityResultMode(.boolean, offset: slot * MemoryLayout<UInt64>.size)
    }

    func endOcclusionQuery() {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        _ = occlusion.end()
        encoder.setVisibilityResultMode(.disabled, offset: 0)
    }

    private func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int) -> TransientRing<MetalBuffer>.Allocation {
        do {
            return try transient.upload(bytes, alignment: alignment)
        } catch {
            preconditionFailure("\(error)")
        }
    }
}

private extension SamplerFilter {
    var metal: MTLSamplerMinMagFilter { self == .nearest ? .nearest : .linear }
}

private extension VertexFormat {
    var metal: MTLVertexFormat {
        switch self {
        case .float: .float
        case .float2: .float2
        case .float3: .float3
        case .float4: .float4
        }
    }
}

private extension CompareFunction {
    var metal: MTLCompareFunction {
        switch self {
        case .never: .never
        case .less: .less
        case .lessEqual: .lessEqual
        case .equal: .equal
        case .greater: .greater
        case .greaterEqual: .greaterEqual
        case .always: .always
        }
    }
}
#endif
