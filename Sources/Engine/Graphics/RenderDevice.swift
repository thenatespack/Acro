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

/// Records draw commands for one render pass.
///
/// Shader binding slots (MSL ↔ GLSL):
/// - vertex buffer 0 / 1 (per-vertex / per-instance): `[[buffer(0)]]`/`[[buffer(1)]]` ↔ bindings 0 / 1
/// - uniform data: `constant T& [[buffer(15)]]` ↔ `layout(set = 0, binding = 0) uniform`
/// - texture: `[[texture(0)]]` + `[[sampler(0)]]` ↔ `layout(set = 1, binding = 0) uniform sampler2DShadow`
/// - push constants: `constant T& [[buffer(16)]]` ↔ `layout(push_constant) uniform`
@MainActor public protocol RenderPass: AnyObject {
    func setPipeline(_ pipeline: RenderPipeline)
    /// `index` 0 is per-vertex data, 1 is per-instance data.
    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int)
    /// Copies `bytes` into per-frame transient memory and binds it as vertex buffer `index`.
    /// Use for data that changes every frame (UI, debug lines, particles, instances).
    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int)
    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType)
    /// Copies up to `maxUniformDataSize` bytes into transient memory and binds them as the
    /// uniform block visible to both shader stages.
    func setUniformData(_ bytes: UnsafeRawBufferPointer)
    /// Binds a texture (with its format's sampler) to the fragment stage.
    func setTexture(_ texture: GPUTexture)
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

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer
    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture
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
}

public struct GraphicsError: Error, CustomStringConvertible {
    public var description: String
    public init(_ description: String) { self.description = description }
}
