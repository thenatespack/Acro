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
public enum PipelineTarget: Sendable {
    /// The main screen pass (swapchain color + depth, multisampled per `RenderDevice.sampleCount`).
    case screen
    /// A depth-only offscreen pass (e.g. a shadow map). Only the vertex stage runs.
    case depthOnly
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

    public init(shader: ShaderSource, vertexLayout: VertexLayout, instanceLayout: VertexLayout? = nil) {
        self.shader = shader
        self.vertexLayout = vertexLayout
        self.instanceLayout = instanceLayout
    }
}

public enum TextureFormat: Sendable {
    /// 32-bit float depth. Render target for depth passes; sampled in shaders with a
    /// linear-filtered comparison sampler (hardware PCF), clamped to a border of 1.
    case depth32Float
    /// 8-bit RGBA, sampled as-is (data, normal maps, masks).
    case rgba8Unorm
    /// 8-bit RGBA with sRGB-encoded color channels: sampling returns linear values.
    case rgba8Srgb

    var isDepth: Bool { self == .depth32Float }
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
/// Frame structure: `beginFrame` → any number of `beginDepthPass`/`endPass` →
/// `beginScreenPass` → `beginWindowPass` → `endFrame`. Games normally use `Frame` instead.
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
    /// A 2D color texture from tightly packed RGBA8 pixels (`width * height * 4` bytes, top
    /// row first). `generateMipmaps` builds a full chain on the CPU (a box filter, in linear
    /// light for `.rgba8Srgb`). The data is copied; the texture is freed like a `GPUBuffer`.
    func makeTexture(pixels: UnsafeRawBufferPointer, width: Int, height: Int, format: TextureFormat,
                     generateMipmaps: Bool) throws -> GPUTexture
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
    /// Starts the pass the scene renders into (the window, or the offscreen render target).
    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass
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

    /// Replaces the start of `buffer` (or `offset` bytes in) with `elements`; see `updateBuffer(_:offset:bytes:)`.
    public func updateBuffer<T: BitwiseCopyable>(_ buffer: GPUBuffer, offset: Int = 0, elements: [T]) throws {
        try elements.withUnsafeBytes { try updateBuffer(buffer, offset: offset, bytes: $0) }
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

/// GPU time of one pass: `depth` (`beginDepthPass`), `scene` (`beginScreenPass`), `upscale`
/// (an upscaler's first stage: EASU, TAAU or MetalFX) or `window` (`beginWindowPass` when
/// rendering offscreen).
public struct GPUPassTime: Sendable {
    public var name: String
    public var seconds: Double
}
