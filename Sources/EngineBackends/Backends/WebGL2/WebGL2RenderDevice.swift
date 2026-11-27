#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

/// Passes per frame whose GPU time is measured (timer queries); later ones go untimed.
private let maxTimedPasses = 32

/// `RenderDevice` on browser WebGL 2 (WebAssembly builds): the fallback for browsers without
/// WebGPU, or the player's choice (see Web/loader.js, `acro.renderer`).
///
/// The page makes the context and Web/webgl2.js's helper (`acro.gl`, `acro.webgl`) before the
/// engine starts. Draws don't call WebGL one by one: each pass records its state changes and draws
/// as numbers into a command buffer in WebAssembly memory (`WebGL2Commands`), which webgl2.js runs
/// in one call, normally once a frame (also before anything that must see the frame's work so far:
/// buffer and texture updates, readbacks). `WebGL2BindState` keeps what is bound, so a draw records
/// only what changed. Per-draw data (uniforms, vertex and index data) goes into a transient ring of
/// buffers uploaded with one `bufferSubData` per buffer before the commands run; uniform ranges are
/// bound with `bindBufferRange`.
///
/// Shaders are the generated GLSL ES 3.00 (`ShaderSource.glesVertex` / `glesFragment`, see its
/// binding table): their header says which uniform block goes to which binding point and which
/// texture and sampler each sampler uniform combines, and each gets a texture unit per program.
///
/// Conventions: every pass renders into the device's own framebuffers, never into the canvas, and
/// their memory row 0 is the image's top, as in Metal, Vulkan and WebGPU (the GLSL's Vulkan clip
/// space with y pointing down, unflipped, does that in GL's window space with y pointing up). So
/// texture coordinates, `gl_FragCoord`, viewports, scissors and `readPixels` rows mean what they
/// mean elsewhere, and only two things change: front faces are clockwise in GL terms, and
/// presenting flips the image into the canvas (whose row 0 is its bottom). Clip-space z is mapped
/// from 0...1 to GL's -1...1 in the vertex shaders (SPIRV-Cross `fixup_clipspace`). MSAA renders
/// into multisampled renderbuffers resolved with `blitFramebuffer`.
///
/// Differences from the other backends:
/// - No compute, storage buffers, storage textures or indirect draws (`supportsCompute` and
///   `supportsStorageBuffers` are false). `makeComputePipeline` and storage textures throw; storage
///   buffers can be made (as plain buffers); bound, they feed only uniform blocks declared at a
///   storage buffer's binding (the material graph templates' GLSL ES reads its values that way,
///   binding point 8 + n); indirect draws are skipped with a warning. So GPU particles, light
///   probes (their bake and the probe-lit shader variants) and FSR 3 are unavailable; the engine
///   skips them with one warning each.
/// - HDR targets (`hdrScene`, `.rgba16Float` render targets, TAAU) need `EXT_color_buffer_float`.
/// - Compressed textures need `EXT_texture_compression_bptc` (BC7, BC6H), `_rgtc` (BC5) or
///   `WEBGL_compressed_texture_astc` (ASTC; HDR with its "hdr" profile).
/// - GPU pass times need `EXT_disjoint_timer_query_webgl2` (few browsers expose it): else none.
///   They come back a frame or more later, as do occlusion query results
///   (`ANY_SAMPLES_PASSED_CONSERVATIVE`).
/// - Captures and readbacks are synchronous (`readPixels`, `getBufferSubData`): a captured frame
///   comes back from its own `endFrame`.
/// - `vsync` has no effect (the browser presents with the display).
/// - Alpha-to-coverage only with MSAA (as on WebGPU). The shadow comparison sampler clamps to the edge.
/// Unsupported: MetalFX, FSR 3, everything that needs compute or storage buffers (above).
package final class WebGL2RenderDevice: RenderDevice {
    package let backend = GraphicsBackend.webgl2
    let helper: JSObject
    let canvas: JSObject
    package let sampleCount: Int
    package let maxTextureSize: Int
    package let deviceName: String
    /// The extensions webgl2.js enabled.
    let extensions: Set<String>
    private let astcHDR: Bool
    /// Float color attachments (`EXT_color_buffer_float`): HDR targets, TAAU, motion vectors.
    let colorBufferFloat: Bool
    private let timers: Bool
    /// Uniform range offsets are multiples of this (the device's alignment, at least the engine's).
    let uniformAlignment: Int
    package var captureNextFrame = false
    package var captureWindow = false
    package var vsync = true
    package var upscaler = Upscaler.bilinear
    package var temporalInputs = TemporalInputs()
    package var hdrScene = false
    package var supportsCompute: Bool { false }
    package var supportsStorageBuffers: Bool { false }
    package var sceneHDRTexture: GPUTexture? {
        guard let frame, frame.hdr, frame.sceneEnded else { return nil }
        return sceneTargets?.hdr
    }
    package var gpuFrameTime: Double? { lastPassTimes.isEmpty ? nil : lastPassTimes.reduce(0) { $0 + $1.seconds } }
    package var gpuPassTimes: [GPUPassTime] { lastPassTimes }

    // webgl2.js functions, looked up once.
    private let jsExecute, jsCreateBuffer, jsBufferSubData, jsGetBufferSubData, jsCreateTexture, jsTexSubImage,
                jsCreateRenderbuffer, jsCreateFramebuffer, jsCreateSampler, jsCreateProgram, jsBindUniformBlock,
                jsBindSamplerUnit, jsReadQueries, jsReadTimers, jsReadPixels, jsCopyEncoded, jsDeleteList: JSFunction

    let commands = WebGL2Commands()
    let bindState = WebGL2BindState()
    let comparisonSampler: WebGL2Sampler
    let linearSampler: WebGL2Sampler
    let pointSampler: WebGL2Sampler
    private let samplerCache = SamplerCache<WebGL2Sampler>()
    /// Bound for slots a program uses but the pass never bound.
    private(set) var placeholderUniform: WebGL2Buffer!
    private(set) var placeholderColor: WebGL2Texture!
    private(set) var placeholderDepth: WebGL2Texture!
    private var programs: [String: WebGL2Program] = [:]
    private var vertexLayouts: [String: WebGL2VertexLayout] = [:]
    private var framebuffers: [FramebufferKey: Int32] = [:]
    private var warned: Set<String> = []

    private var blitPipeline: WebGL2Pipeline!
    private var rcasPipeline: WebGL2Pipeline!
    private var easuPipeline: WebGL2Pipeline!
    private var taauPipeline: WebGL2Pipeline!

    /// Per-frame data: vertex and uniform data in one ring, index data in another (WebGL types a
    /// buffer by its first binding, and index buffers can't be bound as anything else).
    private var dataRing: TransientRing<WebGL2Buffer>!
    private var indexRing: TransientRing<WebGL2Buffer>!
    private var ringChunks: [WebGL2Buffer] = []
    private var frame: FrameState?
    private var currentPass: WebGL2RenderPass?
    private var windowTargets: WindowTargets?
    private var sceneTargets: SceneTargets?
    private var upscaleTargets: UpscaleTargets?
    private var freeQueries: [FrameQueries] = []
    private var queriesInFlight: [FrameQueries] = []
    private var lastPassTimes: [GPUPassTime] = []
    /// Buffer readbacks already read (synchronously), delivered at the next `beginFrame` or `waitIdle`.
    private var bufferReadbacks: [(bytes: [UInt8], completion: @MainActor ([UInt8]) -> Void)] = []
    private var targetReadbacks: [(target: WebGL2RenderTarget, completion: @MainActor (Image) -> Void)] = []
    /// Where webgl2.js writes query results.
    private let scratch = UnsafeMutableRawPointer.allocate(byteCount: maxOcclusionQueriesPerFrame + maxTimedPasses * 8 + 16, alignment: 16)

    private struct FramebufferKey: Hashable {
        var color0: Int32, color1: Int32, depth: Int32
    }

    private struct WindowTargets {
        /// The image the canvas shows (copied into it at the end of the frame), and what captures read.
        var color: WebGL2Texture
        var msaa: WebGL2Renderbuffer?
        var depth: WebGL2Renderbuffer
    }

    private struct SceneTargets {
        var color: WebGL2Renderbuffer?  // multisampled
        /// A renderbuffer, or a texture when a temporal upscaler reads it.
        var depth: Int32
        var depthTexture: WebGL2Texture?
        var depthBuffer: WebGL2Renderbuffer?
        /// Single-sample result in the window format: sampled by the window pass.
        var resolved: WebGL2Texture
        /// `resolved`'s bytes as `.rgba8Unorm` (upscalers work on gamma-encoded values; WebGL has no
        /// texture views, so it's a copy made when an upscaler needs it).
        var resolvedUnorm: WebGL2Texture?
        var motion: WebGL2Texture?
        var hdr: WebGL2Texture?
    }

    private struct UpscaleTargets {
        var stage: UpscalerStage
        var input: (width: Int, height: Int)
        var outputs: [WebGL2Texture]
        var current = 0
        var hasHistory = false
    }

    private struct FrameState {
        var queries: FrameQueries
        var capture: Bool
        var offscreen: Bool
        var scaled: Bool
        var hdr: Bool
        var sceneEnded = false
        var windowSize: (width: Int, height: Int)
    }

    /// Occlusion and timer queries of one frame (webgl2.js keeps the query objects by set id).
    @MainActor private final class FrameQueries {
        let occlusionSet = WebGL2IDs.make()
        let timerSet = WebGL2IDs.make()
        let batch = OcclusionQueryBatch()
        var timedPasses: [String] = []
        var age = 0
    }

    // MARK: - Creation

    /// The context the page made, from `globalThis.acro`: `{ gl, webgl, canvas, wasmMemory }`
    /// (Web/loader.js with Web/webgl2.js).
    package convenience init(sampleCount: Int) throws {
        guard let acro = JSObject.global.acro.object else {
            throw GraphicsError("globalThis.acro is not set: the page must create the WebGL 2 context before starting the engine")
        }
        guard let helper = acro.webgl.object, let canvas = acro.canvas.object else {
            throw GraphicsError("globalThis.acro needs the WebGL 2 helper (webgl, from Web/webgl2.js) and the canvas")
        }
        try self.init(helper: helper, canvas: canvas, sampleCount: sampleCount)
    }

    package init(helper: JSObject, canvas: JSObject, sampleCount requested: Int) throws {
        self.helper = helper
        self.canvas = canvas
        func function(_ name: String) throws -> JSFunction {
            guard let function = helper[name].function else { throw GraphicsError("Web/webgl2.js has no \(name): an older page?") }
            return function
        }
        jsExecute = try function("execute")
        jsCreateBuffer = try function("createBuffer")
        jsBufferSubData = try function("bufferSubData")
        jsGetBufferSubData = try function("getBufferSubData")
        jsCreateTexture = try function("createTexture")
        jsTexSubImage = try function("texSubImage")
        jsCreateRenderbuffer = try function("createRenderbuffer")
        jsCreateFramebuffer = try function("createFramebuffer")
        let jsCreateSampler = try function("createSampler")
        self.jsCreateSampler = jsCreateSampler
        jsCreateProgram = try function("createProgram")
        jsBindUniformBlock = try function("bindUniformBlock")
        jsBindSamplerUnit = try function("bindSamplerUnit")
        jsReadQueries = try function("readQueries")
        jsReadTimers = try function("readTimers")
        jsReadPixels = try function("readPixels")
        jsCopyEncoded = try function("copyEncoded")
        jsDeleteList = try function("deleteList")

        let info = try function("info")(this: helper)
        extensions = Set((info.extensions.string ?? "").split(separator: " ").map(String.init))
        astcHDR = info.astcHDR.boolean ?? false
        colorBufferFloat = extensions.contains("EXT_color_buffer_float")
        timers = extensions.contains("EXT_disjoint_timer_query_webgl2")
        maxTextureSize = Int(info.maxTextureSize.number ?? 4096)
        let maxSamples = Int(info.maxSamples.number ?? 4)
        sampleCount = requested >= 4 && maxSamples >= 4 ? 4 : 1
        uniformAlignment = max(uniformBufferOffsetAlignment, Int(info.uniformBufferOffsetAlignment.number ?? 256))
        let renderer = info.renderer.string ?? ""
        deviceName = renderer.isEmpty ? "WebGL 2" : "WebGL 2 (\(renderer))"
        if (JSObject.global.acro.glDebug.boolean ?? false) || ProcessInfo.processInfo.environment["ENGINE_GL_DEBUG"].map({ $0 != "0" }) == true {
            _ = try function("setDebug")(this: helper, true)
            EngineLog.info("WebGL 2: checking gl.getError() after every command (ENGINE_GL_DEBUG)", category: .rendering)
        }

        func sampler(_ descriptor: SamplerDescriptor, compare: Bool = false) -> WebGL2Sampler {
            let sampler = WebGL2Sampler(descriptor: descriptor)
            let (min, mag, wrap, maxLod) = Self.samplerParameters(descriptor)
            _ = jsCreateSampler(this: helper, Int(sampler.id), Int(min), Int(mag), Int(wrap), compare ? 1 : 0, maxLod)
            return sampler
        }
        comparisonSampler = sampler(SamplerDescriptor(filter: .linear), compare: true)
        linearSampler = sampler(SamplerDescriptor(filter: .linear))
        pointSampler = sampler(SamplerDescriptor(filter: .nearest))

        dataRing = TransientRing(minimumChunkSize: 1024 * 1024) { [unowned self] size in
            // The slack lets a uniform range start anywhere in the chunk.
            self.makeRingChunk(size: size, slack: maxUniformBufferSize, isIndex: false)
        }
        indexRing = TransientRing(minimumChunkSize: 256 * 1024) { [unowned self] size in
            self.makeRingChunk(size: size, slack: 0, isIndex: true)
        }
        placeholderUniform = makeGPUBuffer(bytes: nil, length: maxUniformBufferSize, isIndex: false)
        placeholderColor = try makeGPUTexture(format: .rgba8Unorm, width: 1, height: 1, levels: 1)
        placeholderDepth = try makeGPUTexture(format: .depth32Float, width: 1, height: 1, levels: 1)

        var blit = PipelineDescriptor(shader: try ShaderSource.load(named: "blit", bundle: .engineResources), vertexLayout: .none)
        blit.cullMode = .none
        blit.depthTest = false
        blit.depthWrite = false
        blitPipeline = try makePipeline(blit) as? WebGL2Pipeline
        var rcas = PipelineDescriptor(shader: try ShaderSource.load(named: "fsr_rcas", bundle: .engineResources), vertexLayout: .none)
        rcas.cullMode = .none
        rcas.depthTest = false
        rcas.depthWrite = false
        rcasPipeline = try makePipeline(rcas) as? WebGL2Pipeline
        easuPipeline = try makeUpscalePipeline("fsr_easu", format: .rgba8Unorm)
        taauPipeline = try makeUpscalePipeline("taau", format: .rgba16Float)
    }

    private func makeUpscalePipeline(_ name: String, format: TextureFormat) throws -> WebGL2Pipeline {
        var descriptor = PipelineDescriptor(shader: try ShaderSource.load(named: name, bundle: .engineResources), vertexLayout: .none)
        descriptor.target = .color(format)
        descriptor.cullMode = .none
        descriptor.depthTest = false
        descriptor.depthWrite = false
        return try buildPipeline(descriptor)
    }

    /// Logs `message` the first time `key` comes up.
    func warnOnce(_ key: String, _ message: String) {
        guard warned.insert(key).inserted else { return }
        EngineLog.warning("WebGL 2: \(message)", category: .rendering)
    }

    package func supports(_ upscaler: Upscaler) -> Bool {
        switch upscaler {
        case .bilinear, .fsr1: true
        // TAAU renders into RGBA16F and reads RG16F motion vectors.
        case .taau: colorBufferFloat
        // FSR 3 is compute; MetalFX is Metal's.
        case .fsr3, .metalFXSpatial, .metalFXTemporal: false
        }
    }

    package func supports(_ format: TextureFormat) -> Bool {
        switch format {
        case .bc7Unorm, .bc7Srgb, .bc6hUfloat: extensions.contains("EXT_texture_compression_bptc")
        case .bc5Unorm: extensions.contains("EXT_texture_compression_rgtc")
        case .astc4x4Unorm, .astc4x4Srgb, .astc4x4RG: extensions.contains("WEBGL_compressed_texture_astc")
        case .astc4x4HDR: astcHDR
        default: true
        }
    }

    private func temporal(offscreen: Bool) -> Bool {
        offscreen && upscaler.isTemporal && sampleCount == 1 && colorBufferFloat
    }

    // MARK: - Resources

    private func makeRingChunk(size: Int, slack: Int, isIndex: Bool) -> (WebGL2Buffer, UnsafeMutableRawPointer) {
        let chunk = makeGPUBuffer(bytes: nil, length: size, isIndex: isIndex, slack: slack)
        let staging = UnsafeMutableRawPointer.allocate(byteCount: roundUp(size, 4), alignment: 16)
        chunk.staging = staging
        ringChunks.append(chunk)
        return (chunk, staging)
    }

    private func makeGPUBuffer(bytes: UnsafeRawBufferPointer?, length: Int, isIndex: Bool, slack: Int = 0) -> WebGL2Buffer {
        let allocated = roundUp(max(length, 4), 16) + slack
        let buffer = WebGL2Buffer(length: length, allocatedLength: allocated, isIndex: isIndex)
        let pointer = bytes?.baseAddress.map { Int(bitPattern: $0) } ?? 0
        _ = jsCreateBuffer(this: helper, Int(buffer.id), isIndex ? 1 : 0, allocated, pointer, bytes?.count ?? 0)
        return buffer
    }

    package func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard bytes.count > 0 else { throw GraphicsError("Failed to create WebGL 2 buffer of 0 bytes") }
        return makeGPUBuffer(bytes: bytes, length: bytes.count, isIndex: usage == .index)
    }

    /// WebGL zero-initializes buffers.
    package func makeBuffer(length: Int, usage: BufferUsage) throws -> GPUBuffer {
        guard length > 0 else { throw GraphicsError("Failed to create WebGL 2 buffer of 0 bytes") }
        return makeGPUBuffer(bytes: nil, length: length, isIndex: usage == .index)
    }

    /// Runs the frame's commands so far, then writes the buffer: passes recorded before see the old data.
    package func updateBuffer(_ buffer: GPUBuffer, offset: Int, bytes: UnsafeRawBufferPointer) throws {
        guard frame != nil else { preconditionFailure("updateBuffer outside a frame") }
        precondition(currentPass == nil, "updateBuffer called inside a pass; call it between passes")
        let target = buffer as! WebGL2Buffer
        try validateBufferUpdate(bufferLength: target.length, offset: offset, byteCount: bytes.count)
        guard bytes.count > 0, let base = bytes.baseAddress else { return }
        flush()
        _ = jsBufferSubData(this: helper, Int(target.id), offset, Int(bitPattern: base), bytes.count)
    }

    package func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        if descriptor.storage {
            throw GraphicsError("WebGL 2 has no storage textures (compute needs the WebGPU renderer)")
        }
        guard descriptor.format == .depth32Float else {
            throw GraphicsError("Render targets must be .depth32Float; use makeTexture(pixels:...) for color textures")
        }
        return try makeGPUTexture(format: .depth32Float, width: descriptor.width, height: descriptor.height, levels: 1)
    }

    private func makeGPUTexture(format: TextureFormat, width: Int, height: Int, levels: Int) throws -> WebGL2Texture {
        guard let internalFormat = format.webGL2InternalFormat else { throw GraphicsError("WebGL 2 has no \(format) textures") }
        let texture = WebGL2Texture(format: format, internalFormat: internalFormat, width: width, height: height, mipLevelCount: levels)
        _ = jsCreateTexture(this: helper, Int(texture.id), Int(internalFormat), width, height, levels)
        return texture
    }

    package func makeTexture(levels: [TextureMipLevel], format: TextureFormat) throws -> GPUTexture {
        try format.validateLevels(levels, maxSize: maxTextureSize)
        guard supports(format) else { throw GraphicsError("This GPU can't sample \(format) textures") }
        let (width, height) = (levels[0].width, levels[0].height)
        if format.isCompressed, width % format.blockSize != 0 || height % format.blockSize != 0 {
            throw GraphicsError("WebGL 2 needs \(format) textures in whole blocks: \(width)x\(height) isn't a multiple of \(format.blockSize)")
        }
        let texture = try makeGPUTexture(format: format, width: width, height: height, levels: levels.count)
        for (level, mip) in levels.enumerated() {
            mip.pixels.withUnsafeBytes {
                writeTexture(texture, mipLevel: level, region: TextureRegion(x: 0, y: 0, width: mip.width, height: mip.height), bytes: $0)
            }
        }
        return texture
    }

    private func writeTexture(_ texture: WebGL2Texture, mipLevel: Int, region: TextureRegion, bytes: UnsafeRawBufferPointer) {
        guard let base = bytes.baseAddress else { return }
        let upload = texture.format.webGL2Upload
        _ = jsTexSubImage(this: helper, Int(texture.id), mipLevel, region.x, region.y, region.width, region.height,
                          Int(upload.format), Int(upload.type), Int(bitPattern: base), bytes.count)
    }

    /// Runs the frame's commands so far first: passes recorded before keep the old texels.
    package func updateTexture(_ texture: GPUTexture, region: TextureRegion, mipLevel: Int, bytes: UnsafeRawBufferPointer) throws {
        let target = texture as! WebGL2Texture
        try target.format.validateUpdate(
            region, mipLevel: mipLevel, byteCount: bytes.count,
            width: target.width, height: target.height, mipLevelCount: target.mipLevelCount)
        flush()
        writeTexture(target, mipLevel: mipLevel, region: region, bytes: bytes)
    }

    package func makeSampler(_ descriptor: SamplerDescriptor) throws -> GPUSampler {
        samplerCache.sampler(for: descriptor) { descriptor in
            let sampler = WebGL2Sampler(descriptor: descriptor)
            let (min, mag, wrap, maxLod) = Self.samplerParameters(descriptor)
            _ = jsCreateSampler(this: helper, Int(sampler.id), Int(min), Int(mag), Int(wrap), 0, maxLod)
            return sampler
        }
    }

    private static func samplerParameters(_ descriptor: SamplerDescriptor) -> (min: Int32, mag: Int32, wrap: Int32, maxLod: Double) {
        let linear = descriptor.minFilter == .linear
        let min: Int32 = switch descriptor.mipFilter {
        case .none: linear ? GL.linear : GL.nearest
        case .nearest: linear ? GL.linearMipmapNearest : GL.nearestMipmapNearest
        case .linear: linear ? GL.linearMipmapLinear : GL.nearestMipmapLinear
        }
        let wrap: Int32 = switch descriptor.addressMode {
        case .repeat: GL.repeatWrap
        case .clampToEdge: GL.clampToEdge
        case .mirrorRepeat: GL.mirroredRepeat
        }
        return (min, descriptor.magFilter == .linear ? GL.linear : GL.nearest, wrap, descriptor.mipFilter == .none ? 0 : -1)
    }

    package func makeRenderTarget(_ descriptor: RenderTargetDescriptor) throws -> GPURenderTarget {
        try descriptor.validate(maxSize: maxTextureSize)
        if descriptor.format == .rgba16Float && !colorBufferFloat {
            throw GraphicsError("This browser's WebGL 2 can't render into .rgba16Float (needs EXT_color_buffer_float)")
        }
        let (width, height) = (descriptor.width, descriptor.height)
        let samples = descriptor.multisampled ? sampleCount : 1
        let resolved = try makeGPUTexture(format: descriptor.format, width: width, height: height, levels: 1)
        return WebGL2RenderTarget(
            resolved: resolved,
            msaa: samples > 1 ? makeRenderbuffer(resolved.internalFormat, samples: samples, width: width, height: height) : nil,
            depth: descriptor.depth ? makeRenderbuffer(GL.depth32f, samples: samples, width: width, height: height) : nil)
    }

    private func makeRenderbuffer(_ internalFormat: Int32, samples: Int, width: Int, height: Int) -> WebGL2Renderbuffer {
        let renderbuffer = WebGL2Renderbuffer(width: width, height: height, samples: samples)
        _ = jsCreateRenderbuffer(this: helper, Int(renderbuffer.id), Int(internalFormat), samples, width, height)
        return renderbuffer
    }

    /// The framebuffer with these attachments (texture ids, renderbuffers negated, 0 for none), made on first use.
    private func framebuffer(color0: Int32, color1: Int32 = 0, depth: Int32 = 0) -> Int32 {
        let key = FramebufferKey(color0: color0, color1: color1, depth: depth)
        if let cached = framebuffers[key] { return cached }
        // Framebuffers of released targets pile up (ids aren't reused): start over now and then.
        if framebuffers.count >= 64 { dropFramebuffers() }
        let id = WebGL2IDs.make()
        let status = jsCreateFramebuffer(this: helper, Int(id), Int(color0), Int(color1), Int(depth))
        if Int32(status.number ?? 0) != GL.framebufferComplete {
            warnOnce("framebuffer \(status)", "a framebuffer is incomplete (status 0x\(String(Int(status.number ?? 0), radix: 16)))")
        }
        framebuffers[key] = id
        return id
    }

    private func dropFramebuffers() {
        webGL2PendingDeletes.append(contentsOf: framebuffers.values)
        framebuffers.removeAll()
    }

    // MARK: - Pipelines

    /// A fragment stage for depth-only pipelines without one (a GL program needs both stages).
    private static let emptyFragment = "#version 300 es\nprecision highp float;\nvoid main() {}\n"

    package func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        try buildPipeline(descriptor)
    }

    private func buildPipeline(_ descriptor: PipelineDescriptor) throws -> WebGL2Pipeline {
        guard let vertex = descriptor.shader.glesVertex else {
            throw GraphicsError("Shader has no GLSL ES vertex stage (WebGL 2 needs Scripts/compile-shaders.sh output; "
                                + "stages that read storage buffers have none)")
        }
        let depthOnly = descriptor.target == .depthOnly
        let fragment: String
        if !depthOnly || descriptor.depthOnlyFragment {
            guard let source = descriptor.shader.glesFragment else {
                throw GraphicsError("Shader has no GLSL ES fragment stage (stages that read storage buffers have none)")
            }
            fragment = source
        } else {
            fragment = Self.emptyFragment
        }
        let program = try self.program(vertex: vertex, fragment: fragment)
        let layouts = [descriptor.vertexLayout, descriptor.instanceLayout, descriptor.secondVertexLayout]
        let layoutKey = layouts.map { layout in
            layout.map { "\($0.stride):" + $0.attributes.map { "\($0.location),\($0.format),\($0.offset)" }.joined(separator: ";") } ?? "-"
        }.joined(separator: "|")
        let layout = vertexLayouts[layoutKey] ?? {
            let made = WebGL2VertexLayout(layouts)
            vertexLayouts[layoutKey] = made
            return made
        }()

        let isScreen = descriptor.target == .screen
        let hasDepth: Bool = if case .color = descriptor.target { false } else { true }
        let bias = descriptor.depthBias
        let factors = isScreen ? descriptor.blendMode.factors : nil
        let cull: Int32 = switch descriptor.cullMode {
        case .none: 0
        case .front: GL.front
        case .back: GL.back
        }
        let motion = descriptor.writesMotionVectors && descriptor.colorWrites && fragment.contains("layout(location = 1) out")
        let state: [Int32] = [
            cull,
            // Without a depth test the depth is still written when asked (WebGPU's "always"); GL
            // only writes depth with the test on.
            hasDepth ? 1 : 0,
            descriptor.depthTest ? descriptor.depthCompare.webGL2 : GL.always,
            hasDepth && descriptor.depthWrite ? 1 : 0,
            bias == nil ? 0 : 1,
            Int32(bitPattern: (bias?.constant ?? 0).bitPattern),
            Int32(bitPattern: (bias?.slopeScale ?? 0).bitPattern),
            factors == nil ? 0 : 1,
            factors?.sourceColor.webGL2 ?? GL.one, factors?.destinationColor.webGL2 ?? GL.zero,
            factors?.sourceAlpha.webGL2 ?? GL.one, factors?.destinationAlpha.webGL2 ?? GL.zero,
            descriptor.colorWrites && !depthOnly ? 1 : 0,
            isScreen && descriptor.alphaToCoverage ? 1 : 0,
            motion ? 1 : 0,
        ]
        return WebGL2Pipeline(program: program, layout: layout, state: state, colorWrites: descriptor.colorWrites,
                              writesMotionVectors: motion, depthOnly: depthOnly)
    }

    /// The linked program for these stages (made once), with its blocks bound to binding points
    /// and its samplers to texture units as the stages' headers say.
    private func program(vertex: String, fragment: String) throws -> WebGL2Program {
        let key = vertex + "\u{0}" + fragment
        if let cached = programs[key] { return cached }
        let id = WebGL2IDs.make()
        let log = jsCreateProgram(this: helper, Int(id), vertex, fragment).string ?? "unknown error"
        guard log.isEmpty else { throw GraphicsError("WebGL 2 couldn't build a program: \(log)") }
        let stages = [GLESInterface(source: vertex), GLESInterface(source: fragment)]
        var sizes: [Int32: Int] = [:]
        for block in stages.flatMap(\.uniformBlocks) {
            guard let point = block.bindingPoint else { throw GraphicsError("Uniform block \(block.name) is outside the binding table") }
            let size = Int(jsBindUniformBlock(this: helper, Int(id), block.name, point).number ?? -1)
            if size > 0 { sizes[Int32(point), default: 0] = max(sizes[Int32(point)] ?? 0, size) }
        }
        var samplers: [(unit: Int32, texture: Int, sampler: Int?, shadow: Bool)] = []
        var seen: Set<String> = []
        for sampler in stages.flatMap(\.samplers) where seen.insert(sampler.name).inserted {
            guard let texture = sampler.textureSlot else { throw GraphicsError("Sampler \(sampler.name) is outside the binding table") }
            let unit = Int32(samplers.count)
            guard jsBindSamplerUnit(this: helper, Int(id), sampler.name, Int(unit)).boolean == true else { continue }
            samplers.append((unit, texture, sampler.samplerSlot, sampler.shadow))
        }
        let program = WebGL2Program(id: id, uniformBlocks: sizes.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }, samplers: samplers)
        programs[key] = program
        return program
    }

    package func makeComputePipeline(_ descriptor: ComputePipelineDescriptor) throws -> ComputePipeline {
        throw GraphicsError("WebGL 2 has no compute shaders (they need the WebGPU renderer)")
    }

    // MARK: - Transient memory

    /// Copies `bytes` into the data ring: the chunk and offset they landed at.
    func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int) -> (buffer: WebGL2Buffer, offset: Int) {
        guard frame != nil else { preconditionFailure("Transient data uploaded outside a frame") }
        return allocate(bytes, alignment: alignment, ring: dataRing)
    }

    func uploadIndices(_ bytes: UnsafeRawBufferPointer) -> (buffer: WebGL2Buffer, offset: Int) {
        guard frame != nil else { preconditionFailure("Transient data uploaded outside a frame") }
        return allocate(bytes, alignment: 16, ring: indexRing)
    }

    private func allocate(_ bytes: UnsafeRawBufferPointer, alignment: Int, ring: TransientRing<WebGL2Buffer>) -> (buffer: WebGL2Buffer, offset: Int) {
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

    /// Uploads what the frame wrote into the rings since the last flush, then runs the recorded commands.
    func flush() {
        for chunk in ringChunks where chunk.dirtyEnd > chunk.flushedEnd {
            guard let staging = chunk.staging else { continue }
            let start = chunk.flushedEnd & ~3, end = min(roundUp(chunk.dirtyEnd, 4), roundUp(chunk.length, 4))
            _ = jsBufferSubData(this: helper, Int(chunk.id), start, Int(bitPattern: staging + start), end - start)
            chunk.flushedEnd = end
        }
        guard !commands.isEmpty else { return }
        _ = jsExecute(this: helper, Int(bitPattern: UnsafeRawPointer(commands.words)), commands.count)
        commands.reset()
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
        dataRing.reset()
        indexRing.reset()
        for chunk in ringChunks {
            chunk.dirtyEnd = 0
            chunk.flushedEnd = 0
        }
        let queries = freeQueries.popLast() ?? FrameQueries()
        try ensureWindowTargets(width: framebufferSize.width, height: framebufferSize.height)
        let hdr = hdrScene && colorBufferFloat
        if hdrScene && !colorBufferFloat {
            warnOnce("hdr", "this browser can't render into float targets (no EXT_color_buffer_float): no HDR scene")
        }
        if let sceneSize = renderSize ?? (hdr ? framebufferSize : nil) {
            try ensureSceneTargets(width: sceneSize.width, height: sceneSize.height, temporal: temporal(offscreen: renderSize != nil), hdr: hdr)
        } else {
            sceneTargets = nil
        }
        frame = FrameState(queries: queries, capture: capture, offscreen: renderSize != nil || hdr, scaled: renderSize != nil, hdr: hdr,
                           windowSize: framebufferSize)
        return true
    }

    /// Hands finished results (buffer readbacks, occlusion queries, pass times) to their owners, in order.
    private func deliverResults() {
        let readbacks = bufferReadbacks
        bufferReadbacks.removeAll()
        for readback in readbacks { readback.completion(readback.bytes) }
        while let first = queriesInFlight.first {
            let count = min(first.batch.count, maxOcclusionQueriesPerFrame)
            first.age += 1
            // Results that never come (a lost context) don't hold the others back forever.
            let expired = first.age > 30
            if count > 0, !expired, jsReadQueries(this: helper, Int(first.occlusionSet), count, Int(bitPattern: scratch)).number != 1 { break }
            let results = UnsafeRawBufferPointer(start: scratch, count: count)
            first.batch.resolve { expired || results[$0] != 0 }
            if !first.timedPasses.isEmpty, !expired {
                let pointer = scratch + maxOcclusionQueriesPerFrame
                let status = jsReadTimers(this: helper, Int(first.timerSet), first.timedPasses.count, Int(bitPattern: pointer)).number ?? -1
                if status == 0 { break }
                if status == 1 {
                    let nanoseconds = pointer.bindMemory(to: Double.self, capacity: first.timedPasses.count)
                    lastPassTimes = first.timedPasses.enumerated().map { GPUPassTime(name: $1, seconds: nanoseconds[$0] * 1e-9) }
                }
            }
            queriesInFlight.removeFirst()
            first.timedPasses = []
            first.age = 0
            freeQueries.append(first)
        }
    }

    private func beginPass(framebuffer: Int32, size: (width: Int, height: Int), colorCount: Int, clearColor: Vec4?, clearDepth: Float?,
                           samples: Int, resolve: (source: Int32, destination: Int32)? = nil, label: String,
                           occlusion: Bool = false) -> WebGL2RenderPass {
        guard let frame else { preconditionFailure("Render pass started outside a frame") }
        precondition(currentPass == nil, "Previous pass was not ended")
        let p = commands.append(12)
        p[0] = WebGL2Op.beginPass
        p[1] = framebuffer
        p[2] = Int32(size.width)
        p[3] = Int32(size.height)
        p[4] = Int32(colorCount)
        p[5] = clearColor == nil ? 0 : 1
        let color = clearColor ?? .zero
        p[6] = Int32(bitPattern: color.x.bitPattern)
        p[7] = Int32(bitPattern: color.y.bitPattern)
        p[8] = Int32(bitPattern: color.z.bitPattern)
        p[9] = Int32(bitPattern: color.w.bitPattern)
        p[10] = clearDepth == nil ? 0 : 1
        p[11] = Int32(bitPattern: (clearDepth ?? 1).bitPattern)
        var timed = false
        if timers, frame.queries.timedPasses.count < maxTimedPasses {
            commands.op(WebGL2Op.beginTimer, frame.queries.timerSet, Int32(frame.queries.timedPasses.count))
            frame.queries.timedPasses.append(label)
            timed = true
        }
        let pass = WebGL2RenderPass(device: self, commands: commands, targetSize: size, samples: samples,
                                    occlusion: occlusion ? frame.queries.batch : nil, occlusionSet: frame.queries.occlusionSet,
                                    resolve: resolve, timed: timed)
        currentPass = pass
        return pass
    }

    package func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let target = target as! WebGL2Texture
        return beginPass(framebuffer: framebuffer(color0: 0, depth: target.attachment), size: (target.width, target.height), colorCount: 0,
                         clearColor: nil, clearDepth: clearDepth, samples: 1, label: "depth")
    }

    package func beginPass(target: GPURenderTarget, clearColor: Vec4, clearDepth: Float, label: String) -> RenderPass {
        let target = target as! WebGL2RenderTarget
        let size = (target.width, target.height)
        guard let depth = target.depth else {
            return beginPass(framebuffer: framebuffer(color0: target.resolved.attachment), size: size, colorCount: 1,
                             clearColor: .zero, clearDepth: nil, samples: 1, label: label)
        }
        let resolve = target.msaa.map { (source: framebuffer(color0: $0.attachment, depth: depth.attachment),
                                         destination: framebuffer(color0: target.resolved.attachment)) }
        return beginPass(framebuffer: resolve?.source ?? framebuffer(color0: target.resolved.attachment, depth: depth.attachment),
                         size: size, colorCount: 1, clearColor: clearColor, clearDepth: clearDepth, samples: target.sampleCount,
                         resolve: resolve, label: label)
    }

    package func beginSceneOutputPass(label: String) -> RenderPass {
        guard let frame, frame.hdr, frame.sceneEnded, let scene = sceneTargets else {
            preconditionFailure("beginSceneOutputPass needs an hdrScene frame whose screen pass has ended")
        }
        return beginPass(framebuffer: framebuffer(color0: scene.resolved.attachment), size: (scene.resolved.width, scene.resolved.height),
                         colorCount: 1, clearColor: .zero, clearDepth: nil, samples: 1, label: label)
    }

    package func beginComputePass(label: String) -> ComputePass {
        warnOnce("compute", "WebGL 2 has no compute passes: '\(label)' records nothing")
        return WebGL2ComputePass()
    }

    package func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let frame, let window = windowTargets else { preconditionFailure("beginScreenPass outside a frame") }
        if frame.offscreen, let scene = sceneTargets {
            let target = scene.hdr ?? scene.resolved
            let size = (scene.resolved.width, scene.resolved.height)
            let motion = scene.motion?.attachment ?? 0
            let resolve = scene.color.map { (source: framebuffer(color0: $0.attachment, depth: scene.depth),
                                             destination: framebuffer(color0: target.attachment)) }
            return beginPass(framebuffer: resolve?.source ?? framebuffer(color0: target.attachment, color1: motion, depth: scene.depth),
                             size: size, colorCount: motion != 0 ? 2 : 1, clearColor: clearColor, clearDepth: clearDepth,
                             samples: sampleCount, resolve: resolve, label: "scene", occlusion: true)
        }
        return windowPass(window, size: frame.windowSize, clearColor: clearColor, clearDepth: clearDepth, label: "scene", occlusion: true)
    }

    private func windowPass(_ window: WindowTargets, size: (width: Int, height: Int), clearColor: Vec4, clearDepth: Float, label: String,
                            occlusion: Bool) -> WebGL2RenderPass {
        let resolve = window.msaa.map { (source: framebuffer(color0: $0.attachment, depth: window.depth.attachment),
                                         destination: framebuffer(color0: window.color.attachment)) }
        return beginPass(framebuffer: resolve?.source ?? framebuffer(color0: window.color.attachment, depth: window.depth.attachment),
                         size: size, colorCount: 1, clearColor: clearColor, clearDepth: clearDepth, samples: sampleCount,
                         resolve: resolve, label: label, occlusion: occlusion)
    }

    package func beginWindowPass() -> RenderPass {
        guard let frame, let window = windowTargets else { preconditionFailure("beginWindowPass outside a frame") }
        guard frame.offscreen, let scene = sceneTargets else {
            guard let currentPass else { preconditionFailure("beginWindowPass must follow beginScreenPass") }
            return currentPass
        }
        endPass()
        precondition(!frame.hdr || self.frame!.sceneEnded, "An hdrScene frame must draw beginSceneOutputPass before the window pass")
        let image = (width: scene.resolved.width, height: scene.resolved.height)
        let rect = letterboxRect(image: image, window: frame.windowSize)
        let upscaled = frame.scaled ? upscale(to: (rect.width, rect.height)) : nil

        let pass = windowPass(window, size: frame.windowSize, clearColor: Vec4(0, 0, 0, 1), clearDepth: 1, label: "window", occlusion: false)
        if let upscaled {
            // Sharpen (or copy) the upscaled image 1:1 into its pixel-aligned rectangle.
            pass.setPipeline(rcasPipeline)
            pass.setViewport(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
            pass.image = (upscaled, pointSampler)
            pass.setPushConstants(RcasConstants(rect: rect, sharpness: upscaler.rcasSharpness))
            pass.draw(vertexCount: 3)
            pass.setViewport(x: 0, y: 0, width: frame.windowSize.width, height: frame.windowSize.height)
        } else {
            pass.setPipeline(blitPipeline)
            pass.image = (scene.resolved, linearSampler)
            pass.setPushConstants(BlitConstants(image: image, window: frame.windowSize))
            pass.draw(vertexCount: 3)
        }
        pass.image = nil
        return pass
    }

    /// The scene image's bytes as `.rgba8Unorm` (gamma-encoded values, which upscalers work on),
    /// copied now: WebGL has no texture views.
    private func resolvedUnorm() -> WebGL2Texture? {
        guard var scene = sceneTargets else { return nil }
        if scene.resolvedUnorm == nil {
            scene.resolvedUnorm = try? makeGPUTexture(format: .rgba8Unorm, width: scene.resolved.width, height: scene.resolved.height, levels: 1)
            sceneTargets = scene
        }
        guard let unorm = scene.resolvedUnorm else { return nil }
        flush()
        _ = jsCopyEncoded(this: helper, Int(scene.resolved.id), Int(framebuffer(color0: scene.resolved.attachment)),
                          Int(framebuffer(color0: unorm.attachment)), unorm.width, unorm.height)
        return unorm
    }

    /// Runs the upscaler's first stage (FSR 1 EASU or TAAU) from the scene image into a texture of
    /// `size`, for the window pass to sharpen or copy. nil means bilinear.
    private func upscale(to size: (width: Int, height: Int)) -> WebGL2Texture? {
        guard upscaler != .bilinear, let scene = sceneTargets else { return nil }
        let input = (width: scene.resolved.width, height: scene.resolved.height)
        guard supports(upscaler) else {
            warnOnce("upscaler", "\(upscaler) is unavailable on WebGL 2, using bilinear")
            upscaler = .bilinear
            return nil
        }
        guard let targets = ensureUpscaleTargets(input: input, output: size), let source = resolvedUnorm() else { return nil }
        let reset = temporalInputs.resetHistory || !targets.hasHistory
        switch upscaler {
        case .fsr1:
            let pass = beginPass(framebuffer: framebuffer(color0: targets.outputs[0].attachment), size: size, colorCount: 1,
                                 clearColor: nil, clearDepth: nil, samples: 1, label: "upscale")
            pass.setPipeline(easuPipeline)
            pass.image = (source, pointSampler)
            pass.setPushConstants(EasuConstants(input: input, output: size))
            pass.draw(vertexCount: 3)
            endPass()
            return targets.outputs[0]
        case .taau:
            guard let motion = scene.motion, let depth = scene.depthTexture else { return nil }
            let next = 1 - targets.current
            let pass = beginPass(framebuffer: framebuffer(color0: targets.outputs[next].attachment), size: size, colorCount: 1,
                                 clearColor: nil, clearDepth: nil, samples: 1, label: "upscale")
            pass.setPipeline(taauPipeline)
            // Texture n matches set 2, binding 8 + n in taau.frag.
            pass.textures[1] = source
            pass.textures[2] = depth
            pass.textures[3] = motion
            pass.textures[4] = targets.outputs[targets.current]
            pass.samplers[1] = pointSampler
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

    private func ensureUpscaleTargets(input: (width: Int, height: Int), output: (width: Int, height: Int)) -> UpscaleTargets? {
        let stage = upscaler.firstStage
        if let targets = upscaleTargets, targets.stage == stage, targets.input == input,
           targets.outputs[0].width == output.width, targets.outputs[0].height == output.height {
            return targets
        }
        // TAAU: color plus accumulated weight, with headroom so small blends don't stall in 8 bits.
        let format: TextureFormat = stage == .taau ? .rgba16Float : .rgba8Unorm
        guard let outputs = try? (0..<(stage == .taau ? 2 : 1)).map({ _ in
            try makeGPUTexture(format: format, width: output.width, height: output.height, levels: 1)
        }) else { return nil }
        let targets = UpscaleTargets(stage: stage, input: input, outputs: outputs)
        upscaleTargets = targets
        return targets
    }

    package func endPass() {
        guard let pass = currentPass else { return }
        // Only the scene pass has occlusion queries.
        if pass.occlusion != nil { frame?.sceneEnded = true }
        pass.end()
        if pass.timed { commands.op(WebGL2Op.endTimer) }
        if let resolve = pass.resolve {
            commands.op(WebGL2Op.endPass, resolve.source, resolve.destination, Int32(pass.size.width), Int32(pass.size.height), GL.colorBufferBit)
        } else {
            commands.op(WebGL2Op.endPass, 0, 0, 0, 0, 0)
        }
        currentPass = nil
    }

    /// Reads the bytes at once (`getBufferSubData`, after the frame's commands so far ran); the
    /// completion runs at the next `beginFrame` or `waitIdle`.
    package func readBack(_ buffer: GPUBuffer, offset: Int, length: Int, completion: @escaping @MainActor ([UInt8]) -> Void) {
        guard frame != nil else { preconditionFailure("readBack outside a frame") }
        precondition(currentPass == nil, "readBack called inside a pass; call it between passes")
        validateBufferReadback(buffer, offset: offset, length: length)
        flush()
        var bytes = [UInt8](repeating: 0, count: length)
        bytes.withUnsafeMutableBytes {
            _ = jsGetBufferSubData(this: helper, Int((buffer as! WebGL2Buffer).id), offset, Int(bitPattern: $0.baseAddress!), length)
        }
        bufferReadbacks.append((bytes, completion))
    }

    /// Read in `endFrame`, which calls `completion` before it returns.
    package func readBack(_ target: GPURenderTarget, completion: @escaping @MainActor (Image) -> Void) {
        guard frame != nil else { preconditionFailure("readBack outside a frame") }
        targetReadbacks.append((target as! WebGL2RenderTarget, completion))
    }

    /// An 8-bit RGBA texture's texels, top row first.
    private func readPixels(_ texture: WebGL2Texture) -> Image {
        var pixels = [UInt8](repeating: 0, count: texture.width * texture.height * 4)
        pixels.withUnsafeMutableBytes {
            _ = jsReadPixels(this: helper, Int(framebuffer(color0: texture.attachment)), texture.width, texture.height,
                             Int(bitPattern: $0.baseAddress!))
        }
        return Image(width: texture.width, height: texture.height, pixels: pixels)
    }

    package func endFrame() throws -> Image? {
        guard let frame else { return nil }
        endPass()
        self.frame = nil
        flush()
        guard let window = windowTargets else { return nil }
        var captured: Image?
        if frame.capture, let texture = frame.scaled && !captureWindow ? sceneTargets?.resolved : window.color {
            captured = readPixels(texture)
        }
        let readbacks = targetReadbacks
        targetReadbacks.removeAll()
        for readback in readbacks { readback.completion(readPixels(readback.target.resolved)) }
        // Into the canvas, flipped (its row 0 is its bottom).
        _ = jsCopyEncoded(this: helper, Int(window.color.id), Int(framebuffer(color0: window.color.attachment)), 0,
                          frame.windowSize.width, frame.windowSize.height)
        queriesInFlight.append(frame.queries)
        if !webGL2PendingDeletes.isEmpty {
            let ids = webGL2PendingDeletes
            webGL2PendingDeletes.removeAll()
            ids.withUnsafeBufferPointer { _ = jsDeleteList(this: helper, Int(bitPattern: $0.baseAddress!), $0.count) }
        }
        return captured
    }

    /// Delivers what has finished; WebGL 2 work is in order, so nothing else waits.
    package func waitIdle() {
        if frame == nil {
            flush()
            deliverResults()
        }
    }

    package func shutdown() {
        waitIdle()
    }

    /// The canvas's image: single-sample color (copied into the canvas at the end of the frame),
    /// multisampled color when MSAA is on, and depth.
    private func ensureWindowTargets(width: Int, height: Int) throws {
        if let targets = windowTargets, targets.color.width == width, targets.color.height == height { return }
        windowTargets = nil
        dropFramebuffers()
        windowTargets = WindowTargets(
            color: try makeGPUTexture(format: .rgba8Srgb, width: width, height: height, levels: 1),
            msaa: sampleCount > 1 ? makeRenderbuffer(GL.srgb8Alpha8, samples: sampleCount, width: width, height: height) : nil,
            depth: makeRenderbuffer(GL.depth32f, samples: sampleCount, width: width, height: height))
    }

    /// Offscreen scene targets at the render size (see `MetalRenderDevice.ensureSceneTargets`).
    private func ensureSceneTargets(width: Int, height: Int, temporal: Bool, hdr: Bool) throws {
        if let targets = sceneTargets, targets.resolved.width == width, targets.resolved.height == height,
           (targets.motion != nil) == temporal, (targets.hdr != nil) == hdr {
            return
        }
        sceneTargets = nil
        dropFramebuffers()
        let depthTexture = temporal ? try makeGPUTexture(format: .depth32Float, width: width, height: height, levels: 1) : nil
        let depthBuffer = temporal ? nil : makeRenderbuffer(GL.depth32f, samples: sampleCount, width: width, height: height)
        sceneTargets = SceneTargets(
            color: sampleCount > 1 ? makeRenderbuffer(hdr ? GL.rgba16f : GL.srgb8Alpha8, samples: sampleCount, width: width, height: height) : nil,
            depth: depthTexture?.attachment ?? depthBuffer!.attachment,
            depthTexture: depthTexture, depthBuffer: depthBuffer,
            resolved: try makeGPUTexture(format: .rgba8Srgb, width: width, height: height, levels: 1),
            motion: temporal ? try makeGPUTexture(format: .rg16Float, width: width, height: height, levels: 1) : nil,
            hdr: hdr ? try makeGPUTexture(format: .rgba16Float, width: width, height: height, levels: 1) : nil)
    }
}
#endif
