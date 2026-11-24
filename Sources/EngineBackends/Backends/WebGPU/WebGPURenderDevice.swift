#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

/// Passes per frame whose GPU time is measured (timestamp queries); later ones go untimed.
private let maxTimedPasses = 32
private let depthFormat = "depth32float"
private let motionVectorFormat = "rg16float"
private let hdrFormat = "rgba16float"

/// `RenderDevice` on browser WebGPU, through JavaScriptKit (WebAssembly builds).
///
/// The adapter and device requests are Promises and the engine starts synchronously, so the
/// page creates them before starting the WebAssembly module and hands them over (see
/// `init(sampleCount:)`). The device configures the canvas context itself (its format plus an
/// sRGB view format, the window format of every `.screen` pipeline).
///
/// Bindings follow the table in `ShaderSource` (WGSL column): one bind group layout per group,
/// reflected from the pipeline's WGSL. Uniform buffers (groups 0, 2 and 3) use dynamic offsets,
/// so per-draw data in the transient ring only changes offsets, not bind groups.
///
/// Differences from Metal and Vulkan, all because WebGPU readbacks are asynchronous (`mapAsync`)
/// and nothing may block the browser's main thread:
/// - `endFrame` returns a frame captured with `captureNextFrame` one or more frames later (the
///   first `endFrame` after the copy has been mapped), not the same frame's.
/// - `readBack` completions, occlusion query results and `gpuPassTimes` arrive a frame or more
///   later, at a `beginFrame` after the GPU finished; the latency isn't fixed.
/// - `waitIdle` can't wait: it only delivers readbacks that are already mapped.
/// - `vsync` has no effect (the browser presents with the display).
/// Unsupported: MetalFX, FSR 3 (its storage-texture formats and one shader WGSL can't express),
/// ASTC HDR textures, alpha-to-coverage without MSAA, material-graph fragment shaders (no WGSL
/// is generated for them). The shadow comparison sampler clamps to the edge (WebGPU has no border color).
package final class WebGPURenderDevice: RenderDevice {
    package let backend = GraphicsBackend.webgpu
    let device: JSObject
    let queue: JSObject
    let context: JSObject
    let canvas: JSObject
    /// The canvas texture's format (`bgra8unorm` or `rgba8unorm`) and its sRGB view, the window
    /// format: `.screen` pipelines and `.rgba8Srgb` render targets use the latter.
    let canvasFormat: String
    let windowFormat: String
    package let sampleCount: Int
    package let maxTextureSize: Int
    package let deviceName: String
    /// The device's enabled features (`texture-compression-bc`, `timestamp-query`, ...).
    let features: Set<String>
    private let maxWorkgroupSize: (x: Int, y: Int, z: Int, invocations: Int)
    package var captureNextFrame = false
    package var captureWindow = false
    package var vsync = true
    package var upscaler = Upscaler.bilinear
    package var temporalInputs = TemporalInputs()
    package var hdrScene = false
    package var sceneHDRTexture: GPUTexture? {
        guard let frame, frame.hdr, frame.sceneEnded else { return nil }
        return sceneTargets?.hdr
    }
    package var gpuFrameTime: Double? { lastPassTimes.isEmpty ? nil : lastPassTimes.reduce(0) { $0 + $1.seconds } }
    package var gpuPassTimes: [GPUPassTime] { lastPassTimes }
    /// WebGPU errors reported so far (validation, out of memory); each is also logged.
    package private(set) var errorCount = 0

    let comparisonSampler: WebGPUSampler
    let linearSampler: WebGPUSampler
    private let pointSampler: WebGPUSampler
    private let samplerCache = SamplerCache<WebGPUSampler>()
    /// Bound for slots a shader uses but the pass never bound (WebGPU requires every binding).
    let placeholderUniform: WebGPUBuffer
    let placeholderStorage: WebGPUBuffer
    private var placeholderTextures: [WGSLTextureSampleType: WebGPUTexture] = [:]
    private var placeholderStorageTextures: [String: WebGPUTexture] = [:]
    private var shaderModules: [String: JSObject] = [:]
    private var bindGroupLayouts: [[WebGPULayoutEntry]: WebGPUBindGroupLayout] = [:]
    private var pipelineLayouts: [[Int]: JSObject] = [:]
    private var bindGroups: [[Int]: JSObject] = [:]
    private var errorListener: JSClosure?

    private var blitPipeline: WebGPUPipeline!
    private var rcasPipeline: WebGPUPipeline!
    private var easuPipeline: WebGPUPipeline!
    private var taauPipeline: WebGPUPipeline!
    private let easuFormat = "rgba8unorm"

    /// Per-frame data: one ring (WebGPU orders `writeBuffer` after earlier submissions, so the
    /// next frame can reuse it at once). Chunks are written on the CPU and copied to their GPU
    /// buffers before each submit.
    private var ring: TransientRing<WebGPUBuffer>!
    private var ringChunks: [WebGPUBuffer] = []
    private var frame: FrameState?
    private var currentPass: WebGPURenderPass?
    private var currentComputePass: WebGPUComputePass?
    private var screenTargets: (color: WebGPUTexture?, depth: WebGPUTexture)?
    private var sceneTargets: SceneTargets?
    private var upscaleTargets: UpscaleTargets?
    /// Query sets and readback buffers, one per frame until its results are mapped.
    private var freeQueries: [FrameQueries] = []
    private var queriesInFlight: [FrameQueries] = []
    private var lastPassTimes: [GPUPassTime] = []
    private var bufferReadbacks: [BufferReadback] = []
    /// Frames captured with `captureNextFrame`, returned by the first `endFrame` after they arrive.
    private var capturedImages: [Image] = []
    private var pendingCaptures = 0

    private struct SceneTargets {
        var color: WebGPUTexture?  // multisampled
        var depth: WebGPUTexture
        /// Single-sample result in the window format: sampled by the window pass.
        var resolved: WebGPUTexture
        /// `resolved` read without sRGB decoding: upscalers work on gamma-encoded values.
        var resolvedUnorm: WebGPUTexture
        var motion: WebGPUTexture?
        var hdr: WebGPUTexture?
    }

    private struct UpscaleTargets {
        var stage: UpscalerStage
        var input: (width: Int, height: Int)
        var outputs: [WebGPUTexture]
        var current = 0
        var hasHistory = false
    }

    private struct FrameState {
        var encoder: JSObject
        var queries: FrameQueries
        /// The canvas texture, acquired on first use.
        var windowTexture: WebGPUTexture?
        var capture: Bool
        var offscreen: Bool
        var scaled: Bool
        var hdr: Bool
        var sceneEnded = false
        var windowSize: (width: Int, height: Int)
    }

    /// Occlusion and timestamp queries of one frame, and the buffers they are read back through.
    private final class FrameQueries {
        let occlusionSet: JSObject
        let occlusionResolve: JSObject
        let occlusionReadback: JSObject
        let timestampSet: JSObject?
        let timestampResolve: JSObject?
        let timestampReadback: JSObject?
        let batch = OcclusionQueryBatch()
        var timedPasses: [String] = []
        var pendingMaps = 0
        var occlusionResults: [UInt64] = []
        var timestamps: [UInt64] = []

        init(device: JSObject, timestamps: Bool) {
            let occlusionBytes = webGPUMaxOcclusionQueries * 8
            occlusionSet = device.createQuerySet!(jsObject(["type": "occlusion", "count": webGPUMaxOcclusionQueries])).object!
            occlusionResolve = device.createBuffer!(jsObject(
                ["size": occlusionBytes, "usage": WebGPUBufferUsage.queryResolve | WebGPUBufferUsage.copySource])).object!
            occlusionReadback = device.createBuffer!(jsObject(
                ["size": occlusionBytes, "usage": WebGPUBufferUsage.mapRead | WebGPUBufferUsage.copyDestination])).object!
            if timestamps {
                let bytes = maxTimedPasses * 2 * 8
                timestampSet = device.createQuerySet!(jsObject(["type": "timestamp", "count": maxTimedPasses * 2])).object!
                timestampResolve = device.createBuffer!(jsObject(
                    ["size": bytes, "usage": WebGPUBufferUsage.queryResolve | WebGPUBufferUsage.copySource])).object!
                timestampReadback = device.createBuffer!(jsObject(
                    ["size": bytes, "usage": WebGPUBufferUsage.mapRead | WebGPUBufferUsage.copyDestination])).object!
            } else {
                timestampSet = nil
                timestampResolve = nil
                timestampReadback = nil
            }
        }
    }

    private final class BufferReadback {
        let buffer: JSObject
        let start: Int
        let length: Int
        let completion: @MainActor ([UInt8]) -> Void
        var bytes: [UInt8]?
        var failed = false

        init(buffer: JSObject, start: Int, length: Int, completion: @escaping @MainActor ([UInt8]) -> Void) {
            self.buffer = buffer
            self.start = start
            self.length = length
            self.completion = completion
        }
    }

    // MARK: - Creation

    /// The device and canvas the page created, from `globalThis.acro`:
    /// `{ adapter, device, context, format }` (`GPUAdapter`, `GPUDevice`, the canvas's
    /// `GPUCanvasContext`, `navigator.gpu.getPreferredCanvasFormat()`). Request the device with
    /// every feature the adapter has (BC / ASTC compression, timestamp queries, the storage
    /// texture tiers) for `supports(_:)` to report them.
    package convenience init(sampleCount: Int) throws {
        guard let acro = JSObject.global.acro.object else {
            throw GraphicsError("globalThis.acro is not set: the page must create the WebGPU device before starting the engine")
        }
        guard let device = acro.device.object, let context = acro.context.object else {
            throw GraphicsError("globalThis.acro needs a GPUDevice (device) and a canvas GPUCanvasContext (context)")
        }
        let format = acro["format"].string ?? "bgra8unorm"
        try self.init(device: device, context: context, format: format, adapter: acro.adapter.object, sampleCount: sampleCount)
    }

    /// A device on `device` presenting into `context`, configured here with `format` (the
    /// canvas format: `bgra8unorm` or `rgba8unorm`). `adapter` only names the GPU.
    package init(device: JSObject, context: JSObject, format: String, adapter: JSObject? = nil, sampleCount requested: Int) throws {
        self.device = device
        self.context = context
        queue = device.queue.object!
        guard let canvas = context.canvas.object else { throw GraphicsError("The GPUCanvasContext has no canvas") }
        self.canvas = canvas
        canvasFormat = format.replacingOccurrences(of: "-srgb", with: "")
        windowFormat = canvasFormat + "-srgb"
        // WebGPU has 1 and 4 samples.
        sampleCount = requested >= 4 ? 4 : 1
        let featureList = JSObject.global.Array.from(device.features)
        features = Set((0..<Int(featureList.length.number ?? 0)).compactMap { featureList[$0].string })
        let limits = device.limits
        maxTextureSize = Int(limits.maxTextureDimension2D.number ?? 8192)
        maxWorkgroupSize = (Int(limits.maxComputeWorkgroupSizeX.number ?? 256), Int(limits.maxComputeWorkgroupSizeY.number ?? 256),
                            Int(limits.maxComputeWorkgroupSizeZ.number ?? 64),
                            Int(limits.maxComputeInvocationsPerWorkgroup.number ?? 256))
        if let info = adapter?.info.object {
            let parts = [info["vendor"].string, info["architecture"].string, info["description"].string].compactMap { $0 }.filter { !$0.isEmpty }
            deviceName = parts.isEmpty ? "WebGPU" : "WebGPU (\(parts.joined(separator: " ")))"
        } else {
            deviceName = "WebGPU"
        }

        _ = context.configure!(jsObject([
            "device": device, "format": canvasFormat, "viewFormats": [windowFormat], "alphaMode": "opaque",
            "usage": WebGPUTextureUsage.renderAttachment | WebGPUTextureUsage.copySource,
        ]))

        func sampler(_ descriptor: [String: ConvertibleToJSValue]) -> WebGPUSampler {
            WebGPUSampler(object: device.createSampler!(jsObject(descriptor)).object!, descriptor: SamplerDescriptor())
        }
        comparisonSampler = sampler(["minFilter": "linear", "magFilter": "linear", "compare": "less-equal",
                                     "addressModeU": "clamp-to-edge", "addressModeV": "clamp-to-edge"])
        linearSampler = sampler(["minFilter": "linear", "magFilter": "linear"])
        pointSampler = sampler(["minFilter": "nearest", "magFilter": "nearest"])
        func placeholder(_ size: Int) -> WebGPUBuffer {
            WebGPUBuffer(object: device.createBuffer!(jsObject(["size": size, "usage": WebGPUBufferUsage.all])).object!,
                         length: size, allocatedLength: size)
        }
        placeholderUniform = placeholder(webGPUUniformWindow)
        placeholderStorage = placeholder(64 * 1024)

        ring = TransientRing(minimumChunkSize: 1024 * 1024) { [unowned self] size in
            // The slack lets a uniform window start anywhere in the chunk (see `webGPUUniformWindow`).
            let allocated = roundUp(size, 4) + webGPUUniformWindow
            let object = self.device.createBuffer!(jsObject(["size": allocated, "usage": WebGPUBufferUsage.all])).object!
            let chunk = WebGPUBuffer(object: object, length: size, allocatedLength: allocated)
            let staging = UnsafeMutableRawPointer.allocate(byteCount: roundUp(size, 4), alignment: 16)
            chunk.staging = staging
            self.ringChunks.append(chunk)
            return (chunk, staging)
        }

        let listener = JSClosure { [unowned self] arguments in
            let message = arguments.first?.error.message.string ?? "unknown error"
            MainActor.assumeIsolated {
                self.errorCount += 1
                if self.errorCount <= 20 { EngineLog.error("WebGPU: \(message)", category: .rendering) }
            }
            return .undefined
        }
        _ = device.addEventListener!("uncapturederror", listener)
        errorListener = listener

        var blit = PipelineDescriptor(shader: try ShaderSource.load(named: "blit", bundle: .engineResources), vertexLayout: .none)
        blit.cullMode = .none
        blit.depthTest = false
        blit.depthWrite = false
        blitPipeline = try makePipeline(blit) as? WebGPUPipeline
        var rcas = PipelineDescriptor(shader: try ShaderSource.load(named: "fsr_rcas", bundle: .engineResources), vertexLayout: .none)
        rcas.cullMode = .none
        rcas.depthTest = false
        rcas.depthWrite = false
        rcasPipeline = try makePipeline(rcas) as? WebGPUPipeline
        easuPipeline = try makeUpscalePipeline("fsr_easu", format: easuFormat)
        taauPipeline = try makeUpscalePipeline("taau", format: hdrFormat)
    }

    /// Renders into a single-sample color texture of `format` with no depth.
    private func makeUpscalePipeline(_ name: String, format: String) throws -> WebGPUPipeline {
        var descriptor = PipelineDescriptor(shader: try ShaderSource.load(named: name, bundle: .engineResources), vertexLayout: .none)
        descriptor.cullMode = .none
        descriptor.depthTest = false
        descriptor.depthWrite = false
        return try buildPipeline(descriptor, format: WebGPUPassFormat(color: format, samples: 1, depth: false), variants: false)
    }

    package func supports(_ upscaler: Upscaler) -> Bool {
        switch upscaler {
        case .bilinear, .fsr1, .taau: true
        // FSR 3 needs read-write r8 and write-only r16f / rg16f storage textures, and fsr3_clear has
        // no WGSL (format-less storage writes); MetalFX is Metal's.
        case .fsr3, .metalFXSpatial, .metalFXTemporal: false
        }
    }

    package func supports(_ format: TextureFormat) -> Bool {
        switch format {
        case .bc7Unorm, .bc7Srgb, .bc5Unorm, .bc6hUfloat: features.contains("texture-compression-bc")
        case .astc4x4Unorm, .astc4x4Srgb, .astc4x4RG: features.contains("texture-compression-astc")
        // WebGPU's ASTC formats are the LDR profile.
        case .astc4x4HDR: false
        default: true
        }
    }

    /// Whether WebGPU here can bind a storage texture of `format` (a WGSL format name) with `access`.
    func supportsStorage(format: String, access: String) -> Bool {
        if access == "read-write" {
            return format == "r32float" || (features.contains("texture-formats-tier2")
                && ["r8unorm", "rgba8unorm", "rgba16float", "r16float"].contains(format))
        }
        return ["rgba8unorm", "rgba16float", "r32float"].contains(format)
            || (features.contains("texture-formats-tier1") && ["r8unorm", "r16float", "rg16float"].contains(format))
    }

    private func temporal(offscreen: Bool) -> Bool {
        offscreen && upscaler.isTemporal && sampleCount == 1
    }

    // MARK: - Resources

    private func makeGPUBuffer(length: Int) -> WebGPUBuffer {
        let allocated = roundUp(max(length, 4), 4)
        let object = device.createBuffer!(jsObject(["size": allocated, "usage": WebGPUBufferUsage.all])).object!
        return WebGPUBuffer(object: object, length: length, allocatedLength: allocated)
    }

    /// `writeBuffer` runs on the queue at once, ahead of the frame's (later) submit.
    package func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard bytes.count > 0 else { throw GraphicsError("Failed to create WebGPU buffer of 0 bytes") }
        let buffer = makeGPUBuffer(length: bytes.count)
        writeBuffer(buffer.object, offset: 0, bytes: bytes)
        return buffer
    }

    /// WebGPU zero-initializes buffers.
    package func makeBuffer(length: Int, usage: BufferUsage) throws -> GPUBuffer {
        guard length > 0 else { throw GraphicsError("Failed to create WebGPU buffer of 0 bytes") }
        return makeGPUBuffer(length: length)
    }

    /// `writeBuffer` of `bytes`, padded to a multiple of 4 bytes as WebGPU requires.
    private func writeBuffer(_ buffer: JSObject, offset: Int, bytes: UnsafeRawBufferPointer) {
        if bytes.count % 4 == 0 {
            _ = queue.writeBuffer!(buffer, offset, jsBytes(bytes))
        } else {
            var padded = [UInt8](bytes)
            padded.append(contentsOf: repeatElement(0, count: roundUp(bytes.count, 4) - bytes.count))
            padded.withUnsafeBytes { _ = queue.writeBuffer!(buffer, offset, jsBytes($0)) }
        }
    }

    /// Copies from this frame's transient memory into the buffer at this point of the frame's encoder.
    package func updateBuffer(_ buffer: GPUBuffer, offset: Int, bytes: UnsafeRawBufferPointer) throws {
        guard let frame else { preconditionFailure("updateBuffer outside a frame") }
        precondition(currentPass == nil && currentComputePass == nil, "updateBuffer called inside a pass; call it between passes")
        let target = buffer as! WebGPUBuffer
        try validateBufferUpdate(bufferLength: target.length, offset: offset, byteCount: bytes.count)
        guard bytes.count > 0 else { return }
        guard offset % 4 == 0, bytes.count % 4 == 0 || offset + bytes.count == target.length else {
            throw GraphicsError("WebGPU buffer updates must start and end on 4-byte boundaries (offset \(offset), \(bytes.count) bytes)")
        }
        let (chunk, source) = upload(bytes, alignment: 16)
        _ = frame.encoder.copyBufferToBuffer!(chunk.object, source, target.object, offset, roundUp(bytes.count, 4))
    }

    package func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        if descriptor.storage {
            try descriptor.validateStorage(maxSize: maxTextureSize)
            let format = descriptor.format.webGPUFormat
            guard supportsStorage(format: format, access: "write-only") else {
                throw GraphicsError("This browser's WebGPU can't use \(format) storage textures (needs texture-formats-tier1)")
            }
            return makeGPUTexture(format: format, engineFormat: descriptor.format, width: descriptor.width, height: descriptor.height,
                                  usage: WebGPUTextureUsage.storageBinding | WebGPUTextureUsage.textureBinding
                                      | WebGPUTextureUsage.copySource | WebGPUTextureUsage.copyDestination)
        }
        guard descriptor.format == .depth32Float else {
            throw GraphicsError("Render targets must be .depth32Float; use makeTexture(pixels:...) for color textures")
        }
        return makeGPUTexture(format: depthFormat, engineFormat: .depth32Float, width: descriptor.width, height: descriptor.height,
                              usage: WebGPUTextureUsage.renderAttachment | WebGPUTextureUsage.textureBinding | WebGPUTextureUsage.copySource)
    }

    private func makeGPUTexture(format: String, engineFormat: TextureFormat, width: Int, height: Int, usage: Int,
                                samples: Int = 1, mipLevels: Int = 1, viewFormats: [String] = []) -> WebGPUTexture {
        let object = device.createTexture!(jsObject([
            "size": [width, height], "format": format, "usage": usage, "sampleCount": samples, "mipLevelCount": mipLevels,
            "viewFormats": viewFormats,
        ])).object!
        return WebGPUTexture(object: object, format: engineFormat, gpuFormat: format, width: width, height: height,
                             mipLevelCount: mipLevels, sampleCount: samples)
    }

    package func makeTexture(levels: [TextureMipLevel], format: TextureFormat) throws -> GPUTexture {
        try format.validateLevels(levels, maxSize: maxTextureSize)
        guard supports(format) else { throw GraphicsError("This GPU can't sample \(format) textures") }
        let (width, height) = (levels[0].width, levels[0].height)
        if format.isCompressed, width % format.blockSize != 0 || height % format.blockSize != 0 {
            throw GraphicsError("WebGPU needs \(format) textures in whole blocks: \(width)x\(height) isn't a multiple of \(format.blockSize)")
        }
        let texture = makeGPUTexture(format: format.webGPUFormat, engineFormat: format, width: width, height: height,
                                     usage: WebGPUTextureUsage.textureBinding | WebGPUTextureUsage.copyDestination
                                         | WebGPUTextureUsage.copySource, mipLevels: levels.count)
        for (level, mip) in levels.enumerated() {
            mip.pixels.withUnsafeBytes {
                writeTexture(texture, mipLevel: level, region: TextureRegion(x: 0, y: 0, width: mip.width, height: mip.height), bytes: $0)
            }
        }
        return texture
    }

    /// `writeTexture` of tightly packed rows; compressed copies cover whole blocks.
    private func writeTexture(_ texture: WebGPUTexture, mipLevel: Int, region: TextureRegion, bytes: UnsafeRawBufferPointer) {
        let format = texture.format, block = format.blockSize
        _ = queue.writeTexture!(
            jsObject(["texture": texture.object, "mipLevel": mipLevel, "origin": [region.x, region.y]]),
            jsBytes(bytes),
            jsObject(["offset": 0, "bytesPerRow": format.bytesPerRow(width: region.width),
                      "rowsPerImage": (region.height + block - 1) / block]),
            [roundUp(region.width, block), roundUp(region.height, block)])
    }

    /// `writeTexture` runs on the queue at once. Between passes the frame's commands so far are
    /// submitted first, so they keep the old texels; inside a pass the whole frame sees the new ones.
    package func updateTexture(_ texture: GPUTexture, region: TextureRegion, mipLevel: Int, bytes: UnsafeRawBufferPointer) throws {
        let target = texture as! WebGPUTexture
        try target.format.validateUpdate(
            region, mipLevel: mipLevel, byteCount: bytes.count,
            width: target.width, height: target.height, mipLevelCount: target.mipLevelCount)
        if frame != nil, currentPass == nil, currentComputePass == nil { submitPendingCommands() }
        writeTexture(target, mipLevel: mipLevel, region: region, bytes: bytes)
    }

    package func makeSampler(_ descriptor: SamplerDescriptor) throws -> GPUSampler {
        samplerCache.sampler(for: descriptor) { descriptor in
            let mode = switch descriptor.addressMode {
            case .repeat: "repeat"
            case .clampToEdge: "clamp-to-edge"
            case .mirrorRepeat: "mirror-repeat"
            }
            var entries: [String: ConvertibleToJSValue] = [
                "minFilter": descriptor.minFilter == .nearest ? "nearest" : "linear",
                "magFilter": descriptor.magFilter == .nearest ? "nearest" : "linear",
                "mipmapFilter": descriptor.mipFilter == .linear ? "linear" : "nearest",
                "addressModeU": mode, "addressModeV": mode,
            ]
            if descriptor.mipFilter == .none { entries["lodMaxClamp"] = 0 }
            return WebGPUSampler(object: device.createSampler!(jsObject(entries)).object!, descriptor: descriptor)
        }
    }

    package func makeRenderTarget(_ descriptor: RenderTargetDescriptor) throws -> GPURenderTarget {
        try descriptor.validate(maxSize: maxTextureSize)
        let (width, height) = (descriptor.width, descriptor.height)
        let samples = descriptor.multisampled ? sampleCount : 1
        let format = colorFormat(descriptor.format)
        let attachment = WebGPUTextureUsage.renderAttachment
        let resolved = makeGPUTexture(format: format, engineFormat: descriptor.format, width: width, height: height,
                                      usage: attachment | WebGPUTextureUsage.textureBinding | WebGPUTextureUsage.copySource)
        return WebGPURenderTarget(
            resolved: resolved,
            msaa: samples > 1 ? makeGPUTexture(format: format, engineFormat: descriptor.format, width: width, height: height,
                                               usage: attachment, samples: samples) : nil,
            depth: descriptor.depth ? makeGPUTexture(format: depthFormat, engineFormat: .depth32Float, width: width, height: height,
                                                     usage: attachment, samples: samples) : nil,
            format: WebGPUPassFormat(color: format, samples: samples, depth: descriptor.depth))
    }

    /// The format of color targets of `format` (`.rgba8Srgb` is the window's).
    private func colorFormat(_ format: TextureFormat) -> String {
        format == .rgba16Float ? hdrFormat : windowFormat
    }

    // MARK: - Pipelines

    private func shaderModule(_ source: String) -> JSObject {
        if let cached = shaderModules[source] { return cached }
        let module = device.createShaderModule!(jsObject(["code": source])).object!
        shaderModules[source] = module
        return module
    }

    /// The layout for the bindings `sources` use. `visibility` is the stages that see them; storage
    /// buffers that are written and storage textures are fragment-only in render pipelines.
    private func pipelineLayout(_ sources: [String], compute: Bool) -> WebGPUPipelineLayout {
        var merged: [Int: [Int: WGSLBinding.Kind]] = [:]
        for source in sources {
            for binding in WGSLReflection.bindings(source) {
                // A texture one stage samples and the other only loads is sampled.
                if case .texture(.unfilterableFloat) = binding.kind, merged[binding.group]?[binding.binding] != nil { continue }
                merged[binding.group, default: [:]][binding.binding] = binding.kind
            }
        }
        let groupCount = (merged.keys.max() ?? -1) + 1
        let groups = (0..<groupCount).map { group in
            let entries = (merged[group] ?? [:]).sorted { $0.key < $1.key }.map { binding, kind in
                var visibility = compute ? WebGPUShaderStage.compute : WebGPUShaderStage.vertex | WebGPUShaderStage.fragment
                if !compute {
                    switch kind {
                    case .storageBuffer(readOnly: false), .storageTexture: visibility = WebGPUShaderStage.fragment
                    default: break
                    }
                }
                return WebGPULayoutEntry(binding: binding, kind: kind, visibility: visibility)
            }
            return bindGroupLayout(entries)
        }
        let ids = groups.map(\.id)
        let object = pipelineLayouts[ids] ?? {
            let made = device.createPipelineLayout!(jsObject(["bindGroupLayouts": groups.map(\.object)])).object!
            pipelineLayouts[ids] = made
            return made
        }()
        return WebGPUPipelineLayout(groups: groups, object: object)
    }

    private func bindGroupLayout(_ entries: [WebGPULayoutEntry]) -> WebGPUBindGroupLayout {
        if let cached = bindGroupLayouts[entries] { return cached }
        let objects: [JSValue] = entries.map { entry in
            let resource = entry.kind.layoutEntry
            return ([
                "binding": entry.binding, "visibility": entry.visibility, resource.key: resource.value.jsValue,
            ] as [String: ConvertibleToJSValue]).jsValue
        }
        let layout = WebGPUBindGroupLayout(object: device.createBindGroupLayout!(jsObject(["entries": objects])).object!, entries: entries)
        bindGroupLayouts[entries] = layout
        return layout
    }

    /// A bind group for `key` (its layout and resources), made by `make` the first time.
    func bindGroup(key: [Int], make: () -> JSObject) -> JSObject {
        if let cached = bindGroups[key] { return cached }
        // Released resources leave stale entries behind (keys use ids, never reused): start over now and then.
        if bindGroups.count >= 4096 { bindGroups.removeAll(keepingCapacity: true) }
        let group = device.createBindGroup!(make()).object!
        bindGroups[key] = group
        return group
    }

    package func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        switch descriptor.target {
        case .screen:
            return try buildPipeline(descriptor, format: WebGPUPassFormat(color: windowFormat, samples: sampleCount), variants: true)
        case .depthOnly:
            return try buildPipeline(descriptor, format: nil, variants: false)
        case .color(let format):
            return try buildPipeline(descriptor, format: WebGPUPassFormat(color: colorFormat(format), samples: 1, depth: false),
                                     variants: false)
        }
    }

    /// A pipeline for passes of `format` (nil: depth-only), and with `variants`, for any other color
    /// pass with depth (built on first use there).
    private func buildPipeline(_ descriptor: PipelineDescriptor, format: WebGPUPassFormat?, variants: Bool) throws -> WebGPUPipeline {
        guard let vertexSource = descriptor.shader.wgslVertex else {
            throw GraphicsError("Shader has no WGSL vertex stage (the WebGPU backend needs Scripts/compile-shaders.sh output)")
        }
        let needsFragment = descriptor.target != .depthOnly || descriptor.depthOnlyFragment
        var fragmentSource: String?
        if needsFragment {
            guard let source = descriptor.shader.wgslFragment else { throw GraphicsError("Shader has no WGSL fragment stage") }
            fragmentSource = source
        }
        let layout = pipelineLayout([vertexSource] + (fragmentSource.map { [$0] } ?? []), compute: false)
        let vertexModule = shaderModule(vertexSource)
        let fragmentModule = fragmentSource.map(shaderModule)
        let outputs = fragmentSource.map(WGSLReflection.fragmentOutputs) ?? []

        var buffers: [ConvertibleToJSValue] = []
        for (slot, layout) in [descriptor.vertexLayout, descriptor.instanceLayout ?? .none, descriptor.secondVertexLayout ?? .none].enumerated() {
            guard !layout.attributes.isEmpty else {
                buffers.append(JSValue.null)
                continue
            }
            buffers.append([
                "arrayStride": layout.stride, "stepMode": slot == 1 ? "instance" : "vertex",
                "attributes": layout.attributes.map {
                    (["shaderLocation": $0.location, "format": $0.format.webGPU, "offset": $0.offset] as [String: ConvertibleToJSValue]).jsValue
                },
            ].jsValue)
        }
        while let last = buffers.last, last.jsValue.isNull { buffers.removeLast() }
        let cullMode = switch descriptor.cullMode {
        case .none: "none"
        case .front: "front"
        case .back: "back"
        }
        let isScreen = descriptor.target == .screen
        let device = device
        let make: (WebGPUPassFormat?) throws -> JSObject = { pass in
            var pipeline: [String: ConvertibleToJSValue] = [
                "layout": layout.object,
                "vertex": (["module": vertexModule, "entryPoint": "main", "buffers": buffers.jsValue] as [String: ConvertibleToJSValue]).jsValue,
                "primitive": (["topology": "triangle-list", "cullMode": cullMode, "frontFace": "ccw"] as [String: ConvertibleToJSValue]).jsValue,
                // WebGPU allows alpha-to-coverage only with MSAA.
                "multisample": (["count": pass?.samples ?? 1,
                                 "alphaToCoverageEnabled": isScreen && descriptor.alphaToCoverage && (pass?.samples ?? 1) > 1]
                    as [String: ConvertibleToJSValue]).jsValue,
            ]
            if pass?.depth ?? true {
                let bias = descriptor.depthBias ?? DepthBias(constant: 0, slopeScale: 0)
                pipeline["depthStencil"] = ([
                    "format": depthFormat, "depthWriteEnabled": descriptor.depthWrite,
                    "depthCompare": descriptor.depthTest ? descriptor.depthCompare.webGPU : "always",
                    "depthBias": Int(bias.constant.rounded()), "depthBiasSlopeScale": bias.slopeScale,
                ] as [String: ConvertibleToJSValue]).jsValue
            }
            if let fragmentModule {
                var targets: [ConvertibleToJSValue] = []
                if let color = pass?.color {
                    var target: [String: ConvertibleToJSValue] = ["format": color, "writeMask": descriptor.colorWrites ? 0xF : 0]
                    if isScreen, let factors = descriptor.blendMode.factors {
                        target["blend"] = ([
                            "color": (["srcFactor": factors.sourceColor.webGPU, "dstFactor": factors.destinationColor.webGPU,
                                      "operation": "add"] as [String: ConvertibleToJSValue]).jsValue,
                            "alpha": (["srcFactor": factors.sourceAlpha.webGPU, "dstFactor": factors.destinationAlpha.webGPU,
                                      "operation": "add"] as [String: ConvertibleToJSValue]).jsValue,
                        ] as [String: ConvertibleToJSValue]).jsValue
                    }
                    targets.append(target.jsValue)
                    if pass?.motionVectors == true {
                        let writes = descriptor.writesMotionVectors && descriptor.colorWrites && outputs.contains(1)
                        targets.append(["format": motionVectorFormat, "writeMask": writes ? 0x3 : 0].jsValue)
                    }
                }
                pipeline["fragment"] = (["module": fragmentModule, "entryPoint": "main", "targets": targets.jsValue] as [String: ConvertibleToJSValue]).jsValue
            }
            return device.createRenderPipeline!(jsObject(pipeline)).object!
        }
        return WebGPUPipeline(layout: layout, format: format, object: try make(format), makeVariant: variants ? { try make($0) } : nil)
    }

    package func makeComputePipeline(_ descriptor: ComputePipelineDescriptor) throws -> ComputePipeline {
        guard let source = descriptor.shader.wgslCompute else {
            throw GraphicsError("Compute shader has no WGSL (naga couldn't translate it, or it has no generated shaders)")
        }
        let size = try descriptor.resolvedWorkgroupSize()
        guard size.count > 0, size.x <= maxWorkgroupSize.x, size.y <= maxWorkgroupSize.y, size.z <= maxWorkgroupSize.z,
              size.count <= maxWorkgroupSize.invocations else {
            throw GraphicsError("Workgroup of \(size) exceeds this browser's WebGPU limits (\(maxWorkgroupSize.invocations) invocations)")
        }
        for binding in WGSLReflection.bindings(source) {
            if case .storageTexture(let format, let access) = binding.kind, !supportsStorage(format: format, access: access) {
                throw GraphicsError("This browser's WebGPU can't bind \(access) \(format) storage textures")
            }
        }
        let layout = pipelineLayout([source], compute: true)
        let object = device.createComputePipeline!(jsObject([
            "layout": layout.object, "compute": (["module": shaderModule(source), "entryPoint": "main"] as [String: ConvertibleToJSValue]).jsValue,
        ])).object!
        return WebGPUComputePipeline(layout: layout, object: object, workgroupSize: size)
    }

    // MARK: - Placeholders and transient memory

    func placeholderTexture(_ sampleType: WGSLTextureSampleType) -> WebGPUTexture {
        if let cached = placeholderTextures[sampleType] { return cached }
        let (format, engineFormat): (String, TextureFormat) = switch sampleType {
        case .depth: (depthFormat, .depth32Float)
        case .sint: ("rgba8sint", .rgba8Unorm)
        case .uint: ("rgba8uint", .rgba8Unorm)
        case .float, .unfilterableFloat: ("rgba8unorm", .rgba8Unorm)
        }
        let usage = WebGPUTextureUsage.textureBinding | (sampleType == .depth ? WebGPUTextureUsage.renderAttachment : 0)
        let texture = makeGPUTexture(format: format, engineFormat: engineFormat, width: 1, height: 1, usage: usage)
        placeholderTextures[sampleType] = texture
        return texture
    }

    func placeholderStorageTexture(_ format: String) -> WebGPUTexture {
        if let cached = placeholderStorageTextures[format] { return cached }
        let texture = makeGPUTexture(format: format, engineFormat: .rgba16Float, width: 1, height: 1,
                                     usage: WebGPUTextureUsage.storageBinding | WebGPUTextureUsage.textureBinding)
        placeholderStorageTextures[format] = texture
        return texture
    }

    /// Copies `bytes` into the transient ring: the chunk and offset they landed at.
    func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int) -> (WebGPUBuffer, Int) {
        guard frame != nil else { preconditionFailure("Transient data uploaded outside a frame") }
        do {
            let allocation = try ring.upload(bytes, alignment: alignment)
            allocation.chunk.dirtyEnd = max(allocation.chunk.dirtyEnd, allocation.offset + max(bytes.count, 1))
            return (allocation.chunk, allocation.offset)
        } catch {
            preconditionFailure("\(error)")
        }
    }

    package func uploadTransient(_ bytes: UnsafeRawBufferPointer) -> TransientBuffer {
        let (chunk, offset) = upload(bytes, alignment: 16)
        return TransientBuffer(buffer: chunk, offset: offset, length: bytes.count)
    }

    /// Copies what the frame wrote into the ring since the last flush to the GPU buffers.
    private func flushTransient() {
        for chunk in ringChunks where chunk.dirtyEnd > chunk.flushedEnd {
            guard let staging = chunk.staging else { continue }
            let start = chunk.flushedEnd & ~3, end = min(roundUp(chunk.dirtyEnd, 4), roundUp(chunk.length, 4))
            writeBuffer(chunk.object, offset: start, bytes: UnsafeRawBufferPointer(start: staging + start, count: end - start))
            chunk.flushedEnd = end
        }
    }

    /// Submits the frame's commands so far and continues in a new encoder (between passes only).
    private func submitPendingCommands() {
        guard var frame else { return }
        flushTransient()
        _ = queue.submit!([frame.encoder.finish!()])
        frame.encoder = device.createCommandEncoder!().object!
        self.frame = frame
    }

    // MARK: - Frames

    package func beginFrame(framebufferSize: (width: Int, height: Int), renderSize: (width: Int, height: Int)?) throws -> Bool {
        precondition(frame == nil, "beginFrame called twice without endFrame")
        guard framebufferSize.width > 0, framebufferSize.height > 0 else { return false }
        if Int(canvas.width.number ?? 0) != framebufferSize.width { canvas.width = .number(Double(framebufferSize.width)) }
        if Int(canvas.height.number ?? 0) != framebufferSize.height { canvas.height = .number(Double(framebufferSize.height)) }
        let capture = captureNextFrame
        captureNextFrame = false

        deliverResults()
        ring.reset()
        for chunk in ringChunks {
            chunk.dirtyEnd = 0
            chunk.flushedEnd = 0
        }
        let queries = freeQueries.popLast() ?? FrameQueries(device: device, timestamps: features.contains("timestamp-query"))
        try ensureScreenTargets(width: framebufferSize.width, height: framebufferSize.height)
        let hdr = hdrScene
        if let sceneSize = renderSize ?? (hdr ? framebufferSize : nil) {
            ensureSceneTargets(width: sceneSize.width, height: sceneSize.height, temporal: temporal(offscreen: renderSize != nil), hdr: hdr)
        } else {
            sceneTargets = nil
        }
        frame = FrameState(
            encoder: device.createCommandEncoder!().object!, queries: queries, capture: capture,
            offscreen: renderSize != nil || hdr, scaled: renderSize != nil, hdr: hdr, windowSize: framebufferSize)
        return true
    }

    /// This frame's canvas texture, acquired on first use.
    private func acquireWindowTexture() -> WebGPUTexture {
        guard var frame else { preconditionFailure("Window target requested outside a frame") }
        if let texture = frame.windowTexture { return texture }
        let object = context.getCurrentTexture!().object!
        let texture = WebGPUTexture(object: object, format: .rgba8Srgb, gpuFormat: windowFormat,
                                    width: frame.windowSize.width, height: frame.windowSize.height,
                                    view: object.createView!(jsObject(["format": windowFormat])).object!, owns: false)
        frame.windowTexture = texture
        self.frame = frame
        return texture
    }

    /// Hands mapped results (buffer readbacks, occlusion queries, pass times) to their owners, in order.
    private func deliverResults() {
        while let first = bufferReadbacks.first, first.bytes != nil || first.failed {
            bufferReadbacks.removeFirst()
            first.completion(first.bytes ?? [UInt8](repeating: 0, count: first.length))
        }
        while let first = queriesInFlight.first, first.pendingMaps == 0 {
            queriesInFlight.removeFirst()
            let results = first.occlusionResults
            // Queries past the query set's size weren't issued: visible.
            first.batch.resolve { $0 >= results.count || results[$0] != 0 }
            if !first.timedPasses.isEmpty, first.timestamps.count >= first.timedPasses.count * 2 {
                lastPassTimes = first.timedPasses.enumerated().map { i, name in
                    let begin = first.timestamps[i * 2], end = first.timestamps[i * 2 + 1]
                    return GPUPassTime(name: name, seconds: end > begin ? Double(end - begin) * 1e-9 : 0)
                }
            }
            first.timedPasses = []
            first.occlusionResults = []
            first.timestamps = []
            freeQueries.append(first)
        }
    }

    /// Timestamp writes for a pass named `name`, if the device can time passes and has room this frame.
    private func timestampWrites(_ name: String) -> [String: ConvertibleToJSValue]? {
        guard let frame, let set = frame.queries.timestampSet, frame.queries.timedPasses.count < maxTimedPasses else { return nil }
        let index = frame.queries.timedPasses.count
        frame.queries.timedPasses.append(name)
        return ["querySet": set, "beginningOfPassWriteIndex": index * 2, "endOfPassWriteIndex": index * 2 + 1]
    }

    private func beginPass(_ descriptor: [String: ConvertibleToJSValue], timedAs name: String, format: WebGPUPassFormat?,
                           size: (width: Int, height: Int), occlusion: Bool = false) -> WebGPURenderPass {
        guard let frame else { preconditionFailure("Render pass started outside a frame") }
        precondition(currentPass == nil && currentComputePass == nil, "Previous pass was not ended")
        var descriptor = descriptor
        descriptor["label"] = name
        if let writes = timestampWrites(name) { descriptor["timestampWrites"] = writes.jsValue }
        if occlusion { descriptor["occlusionQuerySet"] = frame.queries.occlusionSet }
        let encoder = frame.encoder.beginRenderPass!(jsObject(descriptor)).object!
        let pass = WebGPURenderPass(encoder: encoder, device: self, format: format, targetSize: size,
                                    occlusion: occlusion ? frame.queries.batch : nil)
        currentPass = pass
        return pass
    }

    /// Color (resolved from `msaa` when multisampled) and depth, both cleared.
    private static func colorDepthPass(msaa: WebGPUTexture?, target: WebGPUTexture, depth: WebGPUTexture, clearColor: Vec4,
                                       clearDepth: Float, storeDepth: Bool = false) -> [String: ConvertibleToJSValue] {
        var color: [String: ConvertibleToJSValue] = [
            "view": msaa?.view ?? target.view, "loadOp": "clear", "storeOp": msaa == nil ? "store" : "discard",
            "clearValue": (["r": clearColor.x, "g": clearColor.y, "b": clearColor.z, "a": clearColor.w] as [String: ConvertibleToJSValue]).jsValue,
        ]
        if msaa != nil { color["resolveTarget"] = target.view }
        return [
            "colorAttachments": [color.jsValue],
            "depthStencilAttachment": (["view": depth.view, "depthLoadOp": "clear", "depthClearValue": clearDepth,
                                       "depthStoreOp": storeDepth ? "store" : "discard"] as [String: ConvertibleToJSValue]).jsValue,
        ]
    }

    /// One single-sample color attachment that the pass overwrites completely.
    private static func colorOnlyPass(_ target: WebGPUTexture) -> [String: ConvertibleToJSValue] {
        ["colorAttachments": [(["view": target.view, "loadOp": "clear", "storeOp": "store"] as [String: ConvertibleToJSValue]).jsValue]]
    }

    package func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let target = target as! WebGPUTexture
        return beginPass([
            "colorAttachments": [ConvertibleToJSValue]().jsValue,
            "depthStencilAttachment": (["view": target.view, "depthLoadOp": "clear", "depthClearValue": clearDepth,
                                       "depthStoreOp": "store"] as [String: ConvertibleToJSValue]).jsValue,
        ], timedAs: "depth", format: nil, size: (target.width, target.height))
    }

    package func beginPass(target: GPURenderTarget, clearColor: Vec4, clearDepth: Float, label: String) -> RenderPass {
        let target = target as! WebGPURenderTarget
        let size = (target.width, target.height)
        guard let depth = target.depth else {
            return beginPass(Self.colorOnlyPass(target.resolved), timedAs: label, format: target.format, size: size)
        }
        return beginPass(Self.colorDepthPass(msaa: target.msaa, target: target.resolved, depth: depth, clearColor: clearColor,
                                             clearDepth: clearDepth),
                         timedAs: label, format: target.format, size: size)
    }

    package func beginSceneOutputPass(label: String) -> RenderPass {
        guard let frame, frame.hdr, frame.sceneEnded, let scene = sceneTargets else {
            preconditionFailure("beginSceneOutputPass needs an hdrScene frame whose screen pass has ended")
        }
        return beginPass(Self.colorOnlyPass(scene.resolved), timedAs: label,
                         format: WebGPUPassFormat(color: windowFormat, samples: 1, depth: false),
                         size: (scene.resolved.width, scene.resolved.height))
    }

    package func beginComputePass(label: String) -> ComputePass {
        guard let frame else { preconditionFailure("Compute pass started outside a frame") }
        precondition(currentPass == nil && currentComputePass == nil, "Previous pass was not ended")
        var descriptor: [String: ConvertibleToJSValue] = ["label": label]
        if let writes = timestampWrites(label) { descriptor["timestampWrites"] = writes.jsValue }
        let pass = WebGPUComputePass(encoder: frame.encoder.beginComputePass!(jsObject(descriptor)).object!, device: self)
        currentComputePass = pass
        return pass
    }

    package func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginScreenPass outside a frame") }
        let motion = frame.offscreen ? sceneTargets?.motion : nil
        var descriptor: [String: ConvertibleToJSValue]
        let size: (width: Int, height: Int)
        if frame.offscreen, let scene = sceneTargets {
            descriptor = Self.colorDepthPass(msaa: scene.color, target: scene.hdr ?? scene.resolved, depth: scene.depth,
                                             clearColor: clearColor, clearDepth: clearDepth, storeDepth: motion != nil)
            size = (scene.resolved.width, scene.resolved.height)
        } else {
            descriptor = Self.colorDepthPass(msaa: targets.color, target: acquireWindowTexture(), depth: targets.depth,
                                             clearColor: clearColor, clearDepth: clearDepth)
            size = frame.windowSize
        }
        if let motion {
            // Temporal upscaling: motion vectors (0 where nothing is drawn) and depth are kept for the upscaler.
            var attachments = descriptor["colorAttachments"] as! [JSValue]
            attachments.append(["view": motion.view, "loadOp": "clear", "storeOp": "store",
                                "clearValue": [0, 0, 0, 0]].jsValue)
            descriptor["colorAttachments"] = attachments
        }
        let format = WebGPUPassFormat(color: frame.hdr ? hdrFormat : windowFormat, samples: sampleCount, motionVectors: motion != nil)
        let pass = beginPass(descriptor, timedAs: "scene", format: format, size: size, occlusion: true)
        return pass
    }

    package func beginWindowPass() -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginWindowPass outside a frame") }
        guard frame.offscreen, let scene = sceneTargets else {
            guard let currentPass else { preconditionFailure("beginWindowPass must follow beginScreenPass") }
            return currentPass
        }
        endPass()
        precondition(!frame.hdr || self.frame!.sceneEnded, "An hdrScene frame must draw beginSceneOutputPass before the window pass")
        let image = (width: scene.resolved.width, height: scene.resolved.height)
        let rect = letterboxRect(image: image, window: frame.windowSize)
        let upscaled = frame.scaled ? upscale(scene, to: (rect.width, rect.height)) : nil

        let pass = beginPass(
            Self.colorDepthPass(msaa: targets.color, target: acquireWindowTexture(), depth: targets.depth,
                                clearColor: Vec4(0, 0, 0, 1), clearDepth: 1),
            timedAs: "window", format: WebGPUPassFormat(color: windowFormat, samples: sampleCount), size: frame.windowSize)
        if let upscaled {
            // Sharpen (or copy) the upscaled image 1:1 into its pixel-aligned rectangle.
            pass.setPipeline(rcasPipeline)
            pass.setViewport(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
            pass.bindings.image = (upscaled, pointSampler)
            pass.setPushConstants(RcasConstants(rect: rect, sharpness: upscaler.rcasSharpness))
            pass.draw(vertexCount: 3)
            pass.setViewport(x: 0, y: 0, width: frame.windowSize.width, height: frame.windowSize.height)
        } else {
            pass.setPipeline(blitPipeline)
            pass.bindings.image = (scene.resolved, linearSampler)
            pass.setPushConstants(BlitConstants(image: image, window: frame.windowSize))
            pass.draw(vertexCount: 3)
        }
        pass.bindings.image = nil
        return pass
    }

    /// Runs the upscaler's first stage (FSR 1 EASU or TAAU) from the scene image into a texture of
    /// `size`, for the window pass to sharpen or copy. nil means bilinear.
    private func upscale(_ scene: SceneTargets, to size: (width: Int, height: Int)) -> WebGPUTexture? {
        guard upscaler != .bilinear else { return nil }
        let input = (width: scene.resolved.width, height: scene.resolved.height)
        guard supports(upscaler) else {
            print("\(upscaler) unavailable on WebGPU, using bilinear")
            upscaler = .bilinear
            return nil
        }
        let targets = ensureUpscaleTargets(input: input, output: size)
        let reset = temporalInputs.resetHistory || !targets.hasHistory
        switch upscaler {
        case .fsr1:
            let pass = beginPass(Self.colorOnlyPass(targets.outputs[0]), timedAs: "upscale",
                                 format: WebGPUPassFormat(color: easuFormat, samples: 1, depth: false), size: size)
            pass.setPipeline(easuPipeline)
            pass.bindings.image = (scene.resolvedUnorm, pointSampler)
            pass.setPushConstants(EasuConstants(input: input, output: size))
            pass.draw(vertexCount: 3)
            endPass()
            return targets.outputs[0]
        case .taau:
            guard let motion = scene.motion else { return nil }
            let next = 1 - targets.current
            let pass = beginPass(Self.colorOnlyPass(targets.outputs[next]), timedAs: "upscale",
                                 format: WebGPUPassFormat(color: hdrFormat, samples: 1, depth: false), size: size)
            pass.setPipeline(taauPipeline)
            // Texture n matches group 2, binding 8 + n in taau.frag.
            pass.bindings.textures[1] = scene.resolvedUnorm
            pass.bindings.textures[2] = scene.depth
            pass.bindings.textures[3] = motion
            pass.bindings.textures[4] = targets.outputs[targets.current]
            pass.bindings.samplers[1] = pointSampler
            pass.setPushConstants(TaauConstants(input: input, output: size, inputs: temporalInputs, reset: reset))
            pass.draw(vertexCount: 3)
            endPass()
            upscaleTargets?.current = next
            upscaleTargets?.hasHistory = true
            return targets.outputs[next]
        case .bilinear, .fsr3, .metalFXSpatial, .metalFXTemporal:
            return nil
        }
    }

    private func ensureUpscaleTargets(input: (width: Int, height: Int), output: (width: Int, height: Int)) -> UpscaleTargets {
        let stage = upscaler.firstStage
        if let targets = upscaleTargets, targets.stage == stage, targets.input == input,
           targets.outputs[0].width == output.width, targets.outputs[0].height == output.height {
            return targets
        }
        // TAAU: color plus accumulated weight, with headroom so small blends don't stall in 8 bits.
        let format = stage == .taau ? hdrFormat : easuFormat
        let outputs = (0..<(stage == .taau ? 2 : 1)).map { _ in
            makeGPUTexture(format: format, engineFormat: stage == .taau ? .rgba16Float : .rgba8Unorm, width: output.width,
                           height: output.height, usage: WebGPUTextureUsage.renderAttachment | WebGPUTextureUsage.textureBinding)
        }
        let targets = UpscaleTargets(stage: stage, input: input, outputs: outputs)
        upscaleTargets = targets
        return targets
    }

    package func endPass() {
        if let compute = currentComputePass {
            compute.end()
            currentComputePass = nil
            return
        }
        guard let pass = currentPass else { return }
        // Only the scene pass has occlusion queries.
        if pass.occlusion != nil { frame?.sceneEnded = true }
        pass.end()
        currentPass = nil
    }

    /// Copies the range into a new mappable buffer in the frame's encoder; `beginFrame` hands it
    /// over once mapped (a frame or more later).
    package func readBack(_ buffer: GPUBuffer, offset: Int, length: Int, completion: @escaping @MainActor ([UInt8]) -> Void) {
        guard let frame else { preconditionFailure("readBack outside a frame") }
        precondition(currentPass == nil && currentComputePass == nil, "readBack called inside a pass; call it between passes")
        validateBufferReadback(buffer, offset: offset, length: length)
        let source = buffer as! WebGPUBuffer
        let start = offset & ~3, end = roundUp(offset + length, 4)
        let copy = device.createBuffer!(jsObject(["size": end - start, "usage": WebGPUBufferUsage.mapRead | WebGPUBufferUsage.copyDestination])).object!
        _ = frame.encoder.copyBufferToBuffer!(source.object, start, copy, 0, end - start)
        bufferReadbacks.append(BufferReadback(buffer: copy, start: offset - start, length: length, completion: completion))
    }

    package func readBack(_ target: GPURenderTarget, completion: @escaping @MainActor (Image) -> Void) {
        guard let frame else { preconditionFailure("readBack outside a frame") }
        let texture = (target as! WebGPURenderTarget).resolved
        copyImage(texture.object, format: texture.gpuFormat, width: texture.width, height: texture.height, encoder: frame.encoder,
                  completion: completion)
    }

    /// Copies a texture (8-bit RGBA or BGRA) into a mappable buffer; `completion` gets the image once mapped.
    private func copyImage(_ texture: JSObject, format: String, width: Int, height: Int, encoder: JSObject,
                           completion: @escaping @MainActor (Image) -> Void) {
        let bytesPerRow = roundUp(width * 4, 256)
        let buffer = device.createBuffer!(jsObject(["size": bytesPerRow * height,
                                                    "usage": WebGPUBufferUsage.mapRead | WebGPUBufferUsage.copyDestination])).object!
        _ = encoder.copyTextureToBuffer!(jsObject(["texture": texture]),
                                         jsObject(["buffer": buffer, "bytesPerRow": bytesPerRow, "rowsPerImage": height]),
                                         [width, height])
        let bgra = format.hasPrefix("bgra")
        imageCopies.append((buffer, {
            $0.withUnsafeBytes { bytes in
                if bgra { return Image(width: width, height: height, bgra: bytes, bytesPerRow: bytesPerRow) }
                var pixels = [UInt8](repeating: 0, count: width * height * 4)
                for y in 0..<height {
                    for x in 0..<width * 4 { pixels[y * width * 4 + x] = bytes[y * bytesPerRow + x] }
                }
                return Image(width: width, height: height, pixels: pixels)
            }
        }, completion))
    }

    /// Image copies recorded this frame, mapped after its submit.
    private var imageCopies: [(buffer: JSObject, convert: ([UInt8]) -> Image, completion: @MainActor (Image) -> Void)] = []

    package func endFrame() throws -> Image? {
        guard let frame else { return nil }
        endPass()
        self.frame = nil
        let encoder = frame.encoder

        if frame.capture, let texture = frame.scaled && !captureWindow ? sceneTargets?.resolved : frame.windowTexture {
            pendingCaptures += 1
            copyImage(texture.object, format: texture.gpuFormat, width: texture.width, height: texture.height, encoder: encoder) {
                [unowned self] image in
                pendingCaptures -= 1
                capturedImages.append(image)
            }
        }

        let queries = frame.queries
        let occlusionCount = min(queries.batch.count, webGPUMaxOcclusionQueries)
        if occlusionCount > 0 {
            _ = encoder.resolveQuerySet!(queries.occlusionSet, 0, occlusionCount, queries.occlusionResolve, 0)
            _ = encoder.copyBufferToBuffer!(queries.occlusionResolve, 0, queries.occlusionReadback, 0, occlusionCount * 8)
        }
        let timestampCount = queries.timedPasses.count * 2
        if timestampCount > 0, let set = queries.timestampSet, let resolve = queries.timestampResolve, let readback = queries.timestampReadback {
            _ = encoder.resolveQuerySet!(set, 0, timestampCount, resolve, 0)
            _ = encoder.copyBufferToBuffer!(resolve, 0, readback, 0, timestampCount * 8)
        }

        flushTransient()
        _ = queue.submit!([encoder.finish!()])

        // Map everything this frame copied, now that the copies are submitted.
        if occlusionCount > 0 {
            map(queries.occlusionReadback, size: occlusionCount * 8, queries: queries) { queries.occlusionResults = Self.uint64s($0) }
        }
        if timestampCount > 0, let readback = queries.timestampReadback {
            map(readback, size: timestampCount * 8, queries: queries) { queries.timestamps = Self.uint64s($0) }
        }
        queriesInFlight.append(queries)
        for readback in bufferReadbacks where readback.bytes == nil && !readback.failed && !mappedReadbacks.contains(ObjectIdentifier(readback)) {
            mappedReadbacks.insert(ObjectIdentifier(readback))
            whenSettled(readback.buffer.mapAsync!(1)) { [unowned self] ok in
                mappedReadbacks.remove(ObjectIdentifier(readback))
                if ok {
                    let bytes = Self.mappedBytes(readback.buffer)
                    readback.bytes = Array(bytes[readback.start..<(readback.start + readback.length)])
                } else {
                    readback.failed = true
                }
                _ = readback.buffer.destroy!()
            }
        }
        for copy in imageCopies {
            whenSettled(copy.buffer.mapAsync!(1)) { ok in
                if ok { copy.completion(copy.convert(Self.mappedBytes(copy.buffer))) }
                _ = copy.buffer.destroy!()
            }
        }
        imageCopies.removeAll()

        for object in webGPUPendingDestroys { _ = object.destroy!() }
        webGPUPendingDestroys.removeAll()
        return capturedImages.isEmpty ? nil : capturedImages.removeFirst()
    }

    private var mappedReadbacks: Set<ObjectIdentifier> = []

    /// Maps `buffer` and hands its first `size` bytes to `store`, counting it as pending on `queries`.
    private func map(_ buffer: JSObject, size: Int, queries: FrameQueries, store: @escaping @MainActor ([UInt8]) -> Void) {
        queries.pendingMaps += 1
        whenSettled(buffer.mapAsync!(1, 0, size)) { ok in
            if ok { store(Self.mappedBytes(buffer, size: size)) }
            queries.pendingMaps -= 1
        }
    }

    /// The contents of a mapped buffer (all of it, or its first `size` bytes), then unmaps it.
    private static func mappedBytes(_ buffer: JSObject, size: Int? = nil) -> [UInt8] {
        let range = size.map { buffer.getMappedRange!(0, $0) } ?? buffer.getMappedRange!()
        let array = JSTypedArray<UInt8>(unsafelyWrapping: JSObject.global.Uint8Array.function!.new(range))
        let bytes = array.withUnsafeBytes { Array($0) }
        _ = buffer.unmap!()
        return bytes
    }

    private static func uint64s(_ bytes: [UInt8]) -> [UInt64] {
        stride(from: 0, to: bytes.count - 7, by: 8).map { i in
            (0..<8).reduce(UInt64(0)) { $0 | UInt64(bytes[i + $1]) << (8 * UInt64($1)) }
        }
    }

    /// Can't block the browser's thread: only delivers what has already been mapped.
    package func waitIdle() {
        if frame == nil { deliverResults() }
    }

    package func shutdown() {
        if let errorListener {
            _ = device.removeEventListener!("uncapturederror", errorListener)
            errorListener.release()
            self.errorListener = nil
        }
    }

    /// Multisampled color (when MSAA is on) and depth matching the canvas size.
    private func ensureScreenTargets(width: Int, height: Int) throws {
        if let targets = screenTargets, targets.depth.width == width, targets.depth.height == height { return }
        let attachment = WebGPUTextureUsage.renderAttachment
        screenTargets = (sampleCount > 1 ? makeGPUTexture(format: windowFormat, engineFormat: .rgba8Srgb, width: width, height: height,
                                                          usage: attachment, samples: sampleCount) : nil,
                         makeGPUTexture(format: depthFormat, engineFormat: .depth32Float, width: width, height: height,
                                        usage: attachment, samples: sampleCount))
    }

    /// Offscreen scene targets at the render size (see `MetalRenderDevice.ensureSceneTargets`).
    private func ensureSceneTargets(width: Int, height: Int, temporal: Bool, hdr: Bool) {
        if let targets = sceneTargets, targets.resolved.width == width, targets.resolved.height == height,
           (targets.motion != nil) == temporal, (targets.hdr != nil) == hdr {
            return
        }
        sceneTargets = nil
        let attachment = WebGPUTextureUsage.renderAttachment, sampled = WebGPUTextureUsage.textureBinding
        let resolved = makeGPUTexture(format: windowFormat, engineFormat: .rgba8Srgb, width: width, height: height,
                                      usage: attachment | sampled | WebGPUTextureUsage.copySource, viewFormats: [canvasFormat])
        sceneTargets = SceneTargets(
            color: sampleCount > 1 ? makeGPUTexture(format: hdr ? hdrFormat : windowFormat, engineFormat: hdr ? .rgba16Float : .rgba8Srgb,
                                                    width: width, height: height, usage: attachment, samples: sampleCount) : nil,
            depth: makeGPUTexture(format: depthFormat, engineFormat: .depth32Float, width: width, height: height,
                                  usage: attachment | (temporal ? sampled : 0), samples: temporal ? 1 : sampleCount),
            resolved: resolved,
            resolvedUnorm: resolved.reinterpreted(as: canvasFormat, format: .rgba8Unorm),
            motion: temporal ? makeGPUTexture(format: motionVectorFormat, engineFormat: .rg16Float, width: width, height: height,
                                              usage: attachment | sampled) : nil,
            hdr: hdr ? makeGPUTexture(format: hdrFormat, engineFormat: .rgba16Float, width: width, height: height,
                                      usage: attachment | sampled) : nil)
    }
}
#endif
