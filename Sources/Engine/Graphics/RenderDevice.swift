import Foundation

public enum GraphicsBackend: String, Sendable, CaseIterable {
    case metal, vulkan

    /// Metal on Apple platforms, Vulkan everywhere else.
    public static var platformDefault: GraphicsBackend {
        #if os(macOS)
        .metal
        #else
        .vulkan
        #endif
    }

    /// Backends compiled into this build.
    public static var available: [GraphicsBackend] {
        var result: [GraphicsBackend] = []
        #if canImport(Metal) && canImport(AppKit)
        result.append(.metal)
        #endif
        #if ENGINE_VULKAN
        result.append(.vulkan)
        #endif
        return result
    }
}

public enum BufferUsage: Sendable {
    case vertex, index
    /// Bound with `RenderPass.setUniformBuffer`.
    case uniform
}

/// A rectangle of a render target in pixels, origin at the top left.
public struct ScissorRect: Sendable, Equatable {
    public var x, y, width, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// This rectangle clipped to a `width` x `height` target, at least 1x1 and inside it
    /// (backends reject empty or out-of-range scissors).
    func clamped(toWidth targetWidth: Int, height targetHeight: Int) -> ScissorRect {
        let left = min(max(x, 0), max(targetWidth - 1, 0)), top = min(max(y, 0), max(targetHeight - 1, 0))
        let right = min(max(x + width, left + 1), targetWidth), bottom = min(max(y + height, top + 1), targetHeight)
        return ScissorRect(x: left, y: top, width: max(right - left, 1), height: max(bottom - top, 1))
    }
}

public enum IndexType: Sendable {
    case uint16, uint32

    var size: Int { self == .uint16 ? 2 : 4 }
}

public enum VertexFormat: Sendable {
    case float, float2, float3, float4
}

public struct VertexAttribute: Sendable {
    /// Shader input location: `[[attribute(n)]]` in MSL, `layout(location = n)` in GLSL.
    public var location: Int
    public var format: VertexFormat
    /// Byte offset within the vertex.
    public var offset: Int

    public init(location: Int, format: VertexFormat, offset: Int) {
        self.location = location
        self.format = format
        self.offset = offset
    }
}

public struct VertexLayout: Sendable {
    public var stride: Int
    public var attributes: [VertexAttribute]

    public init(stride: Int, attributes: [VertexAttribute]) {
        self.stride = stride
        self.attributes = attributes
    }

    /// No vertex input (e.g. a fullscreen triangle generated from the vertex index).
    public static let none = VertexLayout(stride: 0, attributes: [])
}

public enum CullMode: Sendable {
    case none, front, back
}

public enum CompareFunction: Sendable {
    case never, less, lessEqual, equal, greater, greaterEqual, always
}

public struct DepthBias: Sendable {
    public var constant: Float
    public var slopeScale: Float

    public init(constant: Float, slopeScale: Float) {
        self.constant = constant
        self.slopeScale = slopeScale
    }
}

/// What kind of pass a pipeline renders into.
public enum PipelineTarget: Sendable, Equatable {
    /// The main screen pass (swapchain color + depth, multisampled per `RenderDevice.sampleCount`).
    /// Also draws into the HDR scene pass (`RenderDevice.hdrScene`), the window pass and
    /// render targets with depth: backends build the variant each pass needs on first use.
    case screen
    /// A depth-only offscreen pass (e.g. a shadow map). Only the vertex stage runs, unless the
    /// pipeline sets `depthOnlyFragment`.
    case depthOnly
    /// A single-sample pass with one color attachment of this format and no depth (fullscreen
    /// post-processing): color-only render targets (`RenderTargetDescriptor.depth` false) and
    /// `RenderDevice.beginSceneOutputPass` (`.rgba8Srgb`, the window's format). Formats:
    /// `.rgba16Float` and `.rgba8Srgb`. No depth test, blending or motion vectors.
    case color(TextureFormat)
}

public struct PipelineDescriptor: Sendable {
    public var shader: ShaderSource
    /// Per-vertex data from vertex buffer slot 0.
    public var vertexLayout: VertexLayout
    /// Per-instance data from vertex buffer slot 1.
    public var instanceLayout: VertexLayout?
    public var target: PipelineTarget = .screen
    /// Front faces are counter-clockwise on both backends.
    public var cullMode: CullMode = .back
    public var depthTest: Bool = true
    public var depthWrite: Bool = true
    public var depthCompare: CompareFunction = .less
    public var depthBias: DepthBias?
    /// Standard (non-premultiplied) alpha blending.
    public var alphaBlending: Bool = false
    /// false leaves the color target untouched (e.g. occlusion-query proxies, depth prepasses).
    public var colorWrites: Bool = true
    /// The fragment shader writes screen-space motion vectors to its second output
    /// (`float2 [[color(1)]]` / `layout(location = 1) out vec2`; see `TemporalUpscaling.swift`
    /// for the convention). The scene pass only has that RG16F attachment while a temporal
    /// upscaler is active; otherwise the output is discarded. Pipelines without this flag
    /// leave the attachment at 0 (no motion), as do those with `colorWrites` off. Never blended.
    public var writesMotionVectors: Bool = false
    /// For `.depthOnly` pipelines: also run the shader's fragment stage. It has no color
    /// outputs; use it to `discard` (alpha-tested shadow casters). Costs early depth testing.
    public var depthOnlyFragment: Bool = false

    public init(shader: ShaderSource, vertexLayout: VertexLayout, instanceLayout: VertexLayout? = nil) {
        self.shader = shader
        self.vertexLayout = vertexLayout
        self.instanceLayout = instanceLayout
    }
}

public enum TextureFormat: Sendable, Equatable {
    /// 32-bit float depth. Render target for depth passes; sampled in shaders with a
    /// linear-filtered comparison sampler (hardware PCF), clamped to a border of 1.
    case depth32Float
    /// 8-bit RGBA, sampled as-is (data, normal maps, masks).
    case rgba8Unorm
    /// 8-bit RGBA with sRGB-encoded color channels: sampling returns linear values.
    case rgba8Srgb
    /// 16-bit float RGBA (8 bytes per texel), linear: HDR images and data that needs range
    /// beyond 0...1. Uploaded as IEEE half floats, little-endian.
    case rgba16Float

    var isDepth: Bool { self == .depth32Float }

    /// Bytes per texel of a color format (depth formats are never uploaded from the CPU).
    var bytesPerPixel: Int {
        switch self {
        case .depth32Float, .rgba8Unorm, .rgba8Srgb: 4
        case .rgba16Float: 8
        }
    }
}

public struct TextureDescriptor: Sendable {
    public var width: Int
    public var height: Int
    public var format: TextureFormat

    public init(width: Int, height: Int, format: TextureFormat) {
        self.width = width
        self.height = height
        self.format = format
    }
}

/// An offscreen color + depth target for game code (see `RenderTarget`).
public struct RenderTargetDescriptor: Sendable, Equatable {
    public var width: Int
    public var height: Int
    /// Render with the device's MSAA sample count (`RenderDevice.sampleCount`) and resolve
    /// into `texture` at the end of each pass. false renders single-sampled.
    public var multisampled: Bool
    /// `.rgba8Srgb` (the window's format) or `.rgba16Float`. Only `.rgba8Srgb` targets can have depth.
    public var format: TextureFormat
    /// false makes a color-only target (single-sample, no depth) for `.color(format)` pipelines:
    /// post-processing passes, which draw over every pixel. Its color is not cleared, so a
    /// pass into it starts with undefined contents.
    public var depth: Bool

    public init(width: Int, height: Int, multisampled: Bool = true, format: TextureFormat = .rgba8Srgb, depth: Bool = true) {
        self.width = width
        self.height = height
        self.multisampled = multisampled
        self.format = format
        self.depth = depth
    }

    /// A single-sample color-only target (see `depth`).
    public static func color(width: Int, height: Int, format: TextureFormat) -> RenderTargetDescriptor {
        RenderTargetDescriptor(width: width, height: height, multisampled: false, format: format, depth: false)
    }
}

/// GPU side of an offscreen render target: an sRGB color image in the window's format (so
/// every `.screen` pipeline can draw into it), a depth buffer that only lives during the pass,
/// and, when multisampled, the MSAA color image resolved into `texture`. Released like `GPUBuffer`.
@MainActor public protocol GPURenderTarget: AnyObject {
    var width: Int { get }
    var height: Int { get }
    /// 1, or the device's sample count.
    var sampleCount: Int { get }
    /// The single-sample result (`.rgba8Srgb`: sampling returns linear values). Bind it with
    /// `setTexture(_:index:)` or `UIDrawList.drawImage` in any later pass of the frame. It keeps
    /// its own memory alive, so a draw list may hold it after the target is resized.
    var texture: GPUTexture { get }
}

/// GPU memory holding vertex or index data. Released when the last reference goes
/// away; backends defer the actual free until in-flight frames no longer use it.
@MainActor public protocol GPUBuffer: AnyObject {
    var length: Int { get }
}

/// An image the GPU renders into and/or samples. Released like `GPUBuffer`.
@MainActor public protocol GPUTexture: AnyObject {
    var width: Int { get }
    var height: Int { get }
    var format: TextureFormat { get }
    /// 1 unless created with mipmaps.
    var mipLevelCount: Int { get }
}

/// Data copied into the current frame's transient memory (see `Frame.upload`). Bind it in
/// any pass of that frame; it must not be used after the frame ends.
public struct TransientBuffer {
    public let buffer: GPUBuffer
    public let offset: Int
    public let length: Int
}

/// Compiled shaders + fixed-function state. Released like `GPUBuffer`.
@MainActor public protocol RenderPipeline: AnyObject {}

/// Maximum size of push-constant data (the Vulkan-guaranteed minimum).
public let maxPushConstantSize = 128
/// Maximum size of one `setUniformData` block.
public let maxUniformDataSize = 2048
/// Largest range of one uniform buffer binding (the Vulkan-guaranteed minimum).
public let maxUniformBufferSize = 16384
/// Alignment of `setUniformBuffer` offsets (the largest any GPU we target requires).
public let uniformBufferOffsetAlignment = 256
/// Valid `index` values for uniform buffers. 0 and 1 are the vertex buffer slots.
public let uniformBufferIndices = 2..<8
/// Valid `index` values for textures and samplers. 0 is the shadow-map slot (`setTexture(_:)`).
public let textureIndices = 1..<8

/// Records draw commands for one render pass.
///
/// Shader binding slots (MSL ↔ GLSL); see `ShaderSource` for the full table:
/// - vertex buffer 0 / 1 (per-vertex / per-instance): `[[buffer(0)]]`/`[[buffer(1)]]` ↔ bindings 0 / 1
/// - uniform data: `constant T& [[buffer(15)]]` ↔ `layout(set = 0, binding = 0) uniform`
/// - shadow-map texture: `[[texture(0)]]` + `[[sampler(0)]]` ↔ `layout(set = 1, binding = 0) uniform sampler2DShadow`
/// - uniform buffer n (2...7), texture n (1...7), sampler n (1...7): see `ShaderSource`
/// - push constants: `constant T& [[buffer(16)]]` ↔ `layout(push_constant) uniform`
@MainActor public protocol RenderPass: AnyObject {
    func setPipeline(_ pipeline: RenderPipeline)
    /// `index` 0 is per-vertex data, 1 is per-instance data.
    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int)
    /// Copies `bytes` into per-frame transient memory and binds it as vertex buffer `index`.
    /// Use for data that changes every frame (UI, debug lines, particles, instances).
    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int)
    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType)
    /// Copies `bytes` into per-frame transient memory and binds them as the index buffer, like
    /// `setVertexData`. `firstIndex` in `drawIndexed` counts from the start of these bytes.
    func setIndexData(_ bytes: UnsafeRawBufferPointer, type: IndexType)
    /// Restricts drawing to a rectangle of the pass's target, in pixels with the origin at the
    /// top left (clamped to the target). nil draws to the whole target again. Passes start
    /// without a scissor; it persists until changed.
    func setScissorRect(_ rect: ScissorRect?)
    /// Copies up to `maxUniformDataSize` bytes into transient memory and binds them as the
    /// uniform block visible to both shader stages.
    func setUniformData(_ bytes: UnsafeRawBufferPointer)
    /// Binds a depth texture (a shadow map) with a hardware-comparison sampler to the fragment stage.
    func setTexture(_ texture: GPUTexture)
    /// Binds `buffer` (created with `.uniform` usage) from `offset` (a multiple of
    /// `uniformBufferOffsetAlignment`) as uniform buffer `index` (`uniformBufferIndices`),
    /// at most `maxUniformBufferSize` bytes of it. Bindings persist until replaced.
    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage)
    /// Copies `bytes` into per-frame transient memory and binds them as uniform buffer
    /// `index`, like `setVertexData`. For small data that changes every frame or draw.
    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage)
    /// Binds a color texture (`.rgba8Unorm` / `.rgba8Srgb`) as texture `index` (`textureIndices`).
    /// Pair it with `setSampler` at the same index.
    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage)
    /// Binds a sampler as sampler `index` (`textureIndices`).
    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage)
    /// Small per-draw data visible to both shader stages (≤ `maxPushConstantSize` bytes).
    func setPushConstants(_ bytes: UnsafeRawBufferPointer)
    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int)
    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int)
    /// Starts counting samples that pass the depth test into `set.results[index]` (see
    /// `OcclusionQuerySet`). Screen pass only; one query open at a time, closed before the pass ends.
    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int)
    func endOcclusionQuery()
}

extension RenderPass {
    public func setVertexBuffer(_ buffer: GPUBuffer) {
        setVertexBuffer(buffer, offset: 0, index: 0)
    }

    public func setVertexBuffer(_ buffer: GPUBuffer, index: Int) {
        setVertexBuffer(buffer, offset: 0, index: index)
    }

    public func setVertexBuffer(_ transient: TransientBuffer, index: Int) {
        setVertexBuffer(transient.buffer, offset: transient.offset, index: index)
    }

    public func setVertexData<T: BitwiseCopyable>(_ vertices: [T], index: Int = 0) {
        vertices.withUnsafeBytes { setVertexData($0, index: index) }
    }

    public func setIndexData(_ indices: [UInt32]) {
        indices.withUnsafeBytes { setIndexData($0, type: .uint32) }
    }

    public func setUniformBuffer(_ buffer: GPUBuffer, index: Int, stage: ShaderStage = .all) {
        setUniformBuffer(buffer, offset: 0, index: index, stage: stage)
    }

    public func setUniformData<T: BitwiseCopyable>(_ value: T, index: Int, stage: ShaderStage = .all) {
        withUnsafeBytes(of: value) { setUniformData($0, index: index, stage: stage) }
    }

    public func setTexture(_ texture: GPUTexture, index: Int) {
        setTexture(texture, index: index, stage: .fragment)
    }

    public func setSampler(_ sampler: GPUSampler, index: Int) {
        setSampler(sampler, index: index, stage: .fragment)
    }

    public func setUniforms<T: BitwiseCopyable>(_ value: T) {
        withUnsafeBytes(of: value) { setUniformData($0) }
    }

    public func setPushConstants<T: BitwiseCopyable>(_ value: T) {
        withUnsafeBytes(of: value) { setPushConstants($0) }
    }

    public func draw(vertexCount: Int, instanceCount: Int = 1) {
        draw(vertexCount: vertexCount, instanceCount: instanceCount, firstVertex: 0)
    }

    public func drawIndexed(indexCount: Int, instanceCount: Int = 1) {
        drawIndexed(indexCount: indexCount, instanceCount: instanceCount, firstIndex: 0)
    }
}

/// A graphics backend. Resources it creates are freed when released (or, at the
/// latest, when the device shuts down).
///
/// Frame structure: `beginFrame` → any number of `beginDepthPass` / `beginPass(target:…)` +
/// `endPass` → `beginScreenPass` → `beginWindowPass` → `endFrame`. Games normally use `Frame` instead.
@MainActor public protocol RenderDevice: AnyObject {
    var backend: GraphicsBackend { get }
    /// Human-readable GPU name.
    var deviceName: String { get }
    /// MSAA sample count of the screen pass.
    var sampleCount: Int { get }
    /// Largest supported texture / render-target dimension.
    var maxTextureSize: Int { get }
    /// GPU execution time of a recently completed frame, in seconds (nil if unsupported).
    var gpuFrameTime: Double? { get }
    /// GPU time of each pass of a recently completed frame, in recording order (empty if
    /// unsupported). Unlike `gpuFrameTime`, this excludes time the GPU spends waiting, e.g.
    /// for the window server to release a drawable.
    var gpuPassTimes: [GPUPassTime] { get }

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer
    /// Replaces `bytes.count` bytes of a buffer from `makeBuffer`, starting at `offset`.
    ///
    /// The bytes are copied immediately (the caller's memory need not outlive the call) into
    /// the frame's transient memory, and a GPU copy into `buffer` is recorded at this point in
    /// the frame. Nothing waits: the GPU executes it in order with the frame's passes, after
    /// the reads of earlier frames that may still be in flight (the queue's submission order
    /// plus a barrier on Vulkan, in-order encoders and hazard tracking on Metal).
    ///
    /// Visibility: passes begun after this call, and every later frame, see the new data. Passes
    /// already recorded this frame (and earlier frames) still see the old data, so updating a
    /// buffer that an earlier pass of the same frame drew from is well-defined.
    ///
    /// Must be called between `beginFrame` and `endFrame` while no pass is open (e.g. in
    /// `Game.renderOffscreen` via `Frame.updateBuffer`, not inside a `depthPass` body or `render`);
    /// otherwise it traps, since a copy can't be recorded inside a render pass. Throws if the
    /// range isn't inside the buffer. Intended for occasional edits (a few KiB to MiB per
    /// frame); the data passes through transient memory, so don't use it for bulk streaming.
    func updateBuffer(_ buffer: GPUBuffer, offset: Int, bytes: UnsafeRawBufferPointer) throws
    /// An offscreen render target (currently `.depth32Float` only).
    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture
    /// A 2D color texture from explicit mip levels (`TextureMipLevel`, level 0 first, each half
    /// the size of the previous, at least one). The data is copied; the texture is freed like
    /// a `GPUBuffer`. Most code wants `makeTexture(pixels:...)` or `makeTexture(image:...)`,
    /// which build the levels.
    func makeTexture(levels: [TextureMipLevel], format: TextureFormat) throws -> GPUTexture
    /// Overwrites a sub-rectangle of one mip level of a texture from `makeTexture` with tightly
    /// packed texels in the texture's format (`region.width * region.height * bytesPerPixel`
    /// bytes, top row first). Other levels are not regenerated.
    ///
    /// Synchronous and callable at any time, even inside a pass: the new texels are visible to
    /// every pass recorded after the call. On Vulkan it runs on its own command buffer with the
    /// image transitions it needs and waits for the queue, so it is safe against frames still in
    /// flight but costs a stall; batch changes into one call (the glyph atlas uploads one
    /// bounding rectangle per page). On Metal it blits from a staging buffer on its own command
    /// buffer, ordered after frames already submitted (no stall). Either way, frames in flight
    /// keep sampling the old texels.
    func updateTexture(_ texture: GPUTexture, region: TextureRegion, mipLevel: Int, bytes: UnsafeRawBufferPointer) throws
    /// A sampler for `descriptor`. Identical descriptors return the same object.
    func makeSampler(_ descriptor: SamplerDescriptor) throws -> GPUSampler
    func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline
    /// Copies `bytes` into this frame's transient memory (between `beginFrame` and `endFrame`).
    func uploadTransient(_ bytes: UnsafeRawBufferPointer) -> TransientBuffer

    /// Acquires the next drawable. Returns false when there is nothing to draw into
    /// (e.g. the window is minimized); skip the frame in that case.
    ///
    /// With a `renderSize`, the screen pass renders offscreen at that size and
    /// `beginWindowPass` scales the result into the window. nil renders straight to the window.
    func beginFrame(framebufferSize: (width: Int, height: Int), renderSize: (width: Int, height: Int)?) throws -> Bool
    /// Starts a depth-only pass into `target` (a `.depth32Float` texture).
    func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass
    /// An offscreen color target with depth (see `RenderTargetDescriptor`). Its texture starts
    /// out shader-readable with undefined contents.
    func makeRenderTarget(_ descriptor: RenderTargetDescriptor) throws -> GPURenderTarget
    /// Starts a pass into `target` (color and depth cleared), timed as `label`. Any number may be
    /// recorded before the screen pass; each one's result is readable by every later pass of the
    /// frame (the window pass included). Takes `.screen` pipelines; there is no motion-vector
    /// attachment and no occlusion queries.
    func beginPass(target: GPURenderTarget, clearColor: Vec4, clearDepth: Float, label: String) -> RenderPass
    /// Starts the pass the scene renders into (the window, or the offscreen render target).
    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass
    /// Render the scene pass into a linear RGBA16F image instead of the window's sRGB format,
    /// for post-processing (see `PostProcessor`). Read in `beginFrame`. The scene then always
    /// renders offscreen (at the window size when there is no render resolution), and after it
    /// the frame must end the screen pass (`endPass`), may run passes that read
    /// `sceneHDRTexture`, and must draw the displayed image in `beginSceneOutputPass` before
    /// `beginWindowPass`, which upscales or copies that image as usual.
    var hdrScene: Bool { get set }
    /// This frame's HDR scene image (`.rgba16Float`, single-sample, at the render size) once the
    /// screen pass has ended; nil when the frame isn't `hdrScene`.
    var sceneHDRTexture: GPUTexture? { get }
    /// With `hdrScene`, after the screen pass: a single-sample pass into the sRGB scene image
    /// that the window pass shows (and screenshots capture), for `.color(.rgba8Srgb)` pipelines.
    /// Its contents start undefined; draw every pixel. Timed as `label`.
    func beginSceneOutputPass(label: String) -> RenderPass
    /// Call right after the screen pass. Returns a pass at window resolution for UI that
    /// uses `.screen` pipelines. With a render size, this ends the screen pass and draws
    /// the scene image into the window (letterboxed) first; otherwise it simply returns
    /// the still-open screen pass.
    func beginWindowPass() -> RenderPass
    func endPass()
    /// Submits and presents. Returns the frame's pixels (at render resolution, without
    /// window-pass UI when a render size is set) when `captureNextFrame` was set before `beginFrame`.
    func endFrame() throws -> Image?
    /// When true, the next frame is read back and returned by `endFrame`. Resets after.
    var captureNextFrame: Bool { get set }
    /// Reads `target`'s color (an `.rgba8Srgb` target) back once this frame's passes ran:
    /// `endFrame` waits for the GPU, like a captured frame, and calls `completion` with the
    /// pixels (RGBA8, top row first). Call it inside a frame, after the passes into `target`.
    func readBack(_ target: GPURenderTarget, completion: @escaping @MainActor (Image) -> Void)
    /// Capture the window image (after upscaling and window-pass UI) instead of the scene at
    /// render resolution.
    var captureWindow: Bool { get set }
    /// Wait for the display's refresh before presenting (no tearing, frame rate capped at the
    /// refresh rate). false presents as fast as the GPU can render.
    var vsync: Bool { get set }
    /// Scales an offscreen scene into the window in `beginWindowPass`.
    var upscaler: Upscaler { get set }
    func supports(_ upscaler: Upscaler) -> Bool
    /// Jitter, history reset and depth convention for a temporal upscaler, read in
    /// `beginWindowPass`. While one is active (with a render size), the scene pass also has a
    /// motion-vector attachment and keeps its depth.
    var temporalInputs: TemporalInputs { get set }

    func waitIdle()
    func shutdown()
}

extension RenderDevice {
    public func beginFrame(framebufferSize: (width: Int, height: Int)) throws -> Bool {
        try beginFrame(framebufferSize: framebufferSize, renderSize: nil)
    }

    public func makeBuffer<T: BitwiseCopyable>(_ elements: [T], usage: BufferUsage) throws -> GPUBuffer {
        try elements.withUnsafeBytes { try makeBuffer(bytes: $0, usage: usage) }
    }

    /// A texture from a decoded 8-bit image (see `ImageDecoder`), with a full mip chain unless
    /// `generateMipmaps` is false. `srgb` picks how the bytes are interpreted: true for color
    /// (albedo, emissive, UI), which samples as linear light and is averaged in linear light
    /// when building mips; false for data (normal, roughness, metalness, masks).
    ///
    /// Decoding is CPU-only and can run on any thread, but this creates the GPU texture, so call
    /// it on the main thread; on Vulkan it blocks until the upload has finished.
    public func makeTexture(image: Image, srgb: Bool, generateMipmaps: Bool = true) throws -> GPUTexture {
        try makeTexture(pixels: image.pixels, width: image.width, height: image.height,
                        format: srgb ? .rgba8Srgb : .rgba8Unorm, generateMipmaps: generateMipmaps)
    }

    /// An `.rgba16Float` texture from a decoded HDR image, with a full mip chain (filtered in
    /// float) unless `generateMipmaps` is false. Same threading as `makeTexture(image:srgb:)`.
    public func makeTexture(image: FloatImage, generateMipmaps: Bool = true) throws -> GPUTexture {
        try TextureFormat.rgba16Float.validateUpload(
            byteCount: image.width * image.height * 8, width: image.width, height: image.height, maxSize: maxTextureSize)
        return try makeTexture(
            levels: MipChain.generateFloat(pixels: image.pixels, width: image.width, height: image.height,
                                           generateMipmaps: generateMipmaps),
            format: .rgba16Float)
    }

    /// A texture from either kind of decoded image. `srgb` applies to 8-bit images only
    /// (HDR is always linear).
    public func makeTexture(decoded: DecodedImage, srgb: Bool, generateMipmaps: Bool = true) throws -> GPUTexture {
        switch decoded {
        case .rgba8(let image): try makeTexture(image: image, srgb: srgb, generateMipmaps: generateMipmaps)
        case .rgba32F(let image): try makeTexture(image: image, generateMipmaps: generateMipmaps)
        }
    }

    /// `updateTexture(_:region:mipLevel:bytes:)` with the bytes as an array.
    public func updateTexture(_ texture: GPUTexture, region: TextureRegion, mipLevel: Int = 0, pixels: [UInt8]) throws {
        try pixels.withUnsafeBytes { try updateTexture(texture, region: region, mipLevel: mipLevel, bytes: $0) }
    }

    /// Replaces the start of `buffer` (or `offset` bytes in) with `elements`; see `updateBuffer(_:offset:bytes:)`.
    public func updateBuffer<T: BitwiseCopyable>(_ buffer: GPUBuffer, offset: Int = 0, elements: [T]) throws {
        try elements.withUnsafeBytes { try updateBuffer(buffer, offset: offset, bytes: $0) }
    }

    /// A 2D color texture from tightly packed pixels (`width * height * bytesPerPixel` bytes,
    /// top row first; RGBA8 for `.rgba8Unorm` / `.rgba8Srgb`, half floats for `.rgba16Float`).
    /// `generateMipmaps` builds a full chain on the CPU (a box filter, in linear light for
    /// `.rgba8Srgb`; not supported for `.rgba16Float`, use `makeTexture(image: FloatImage)` for
    /// HDR mips). The data is copied; the texture is freed like a `GPUBuffer`.
    public func makeTexture(pixels: UnsafeRawBufferPointer, width: Int, height: Int, format: TextureFormat,
                            generateMipmaps: Bool) throws -> GPUTexture {
        try format.validateUpload(byteCount: pixels.count, width: width, height: height, maxSize: maxTextureSize)
        guard generateMipmaps else {
            return try makeTexture(levels: [TextureMipLevel(width: width, height: height, pixels: Array(pixels))], format: format)
        }
        guard format != .rgba16Float else {
            throw GraphicsError("Mip generation for .rgba16Float needs the float source: use makeTexture(image: FloatImage)")
        }
        return try makeTexture(
            levels: MipChain.generate(pixels: Array(pixels), width: width, height: height, srgb: format == .rgba8Srgb),
            format: format)
    }

    public func makeTexture(pixels: [UInt8], width: Int, height: Int, format: TextureFormat = .rgba8Srgb,
                            generateMipmaps: Bool = false) throws -> GPUTexture {
        try pixels.withUnsafeBytes {
            try makeTexture(pixels: $0, width: width, height: height, format: format, generateMipmaps: generateMipmaps)
        }
    }
}

public struct GraphicsError: Error, CustomStringConvertible {
    public var description: String
    public init(_ description: String) { self.description = description }
}

/// GPU time of one pass: `depth` (`beginDepthPass`), `scene` (`beginScreenPass`), post-processing
/// passes by their label (`bloom`, `exposure`, `tonemap`), `upscale`
/// (an upscaler's first stage: EASU, TAAU or MetalFX), `window` (`beginWindowPass` when
/// rendering offscreen) or a render target pass's label.
public struct GPUPassTime: Sendable {
    public var name: String
    public var seconds: Double
}
