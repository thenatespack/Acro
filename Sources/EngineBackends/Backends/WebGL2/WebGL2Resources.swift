#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

/// The GL enums the WebGL 2 device passes to Web/webgl2.js (numbers, so nothing is converted per call).
enum GL {
    static let none: Int32 = 0, one: Int32 = 1, zero: Int32 = 0
    static let front: Int32 = 0x0404, back: Int32 = 0x0405
    static let never: Int32 = 0x0200, less: Int32 = 0x0201, equal: Int32 = 0x0202, lessEqual: Int32 = 0x0203,
               greater: Int32 = 0x0204, greaterEqual: Int32 = 0x0206, always: Int32 = 0x0207
    static let sourceAlpha: Int32 = 0x0302, oneMinusSourceAlpha: Int32 = 0x0303, destinationColor: Int32 = 0x0306
    static let unsignedShort: Int32 = 0x1403, unsignedInt: Int32 = 0x1405, unsignedByte: Int32 = 0x1401,
               float: Int32 = 0x1406, halfFloat: Int32 = 0x140B
    static let nearest: Int32 = 0x2600, linear: Int32 = 0x2601, nearestMipmapNearest: Int32 = 0x2700,
               linearMipmapNearest: Int32 = 0x2701, nearestMipmapLinear: Int32 = 0x2702, linearMipmapLinear: Int32 = 0x2703
    static let repeatWrap: Int32 = 0x2901, clampToEdge: Int32 = 0x812F, mirroredRepeat: Int32 = 0x8370
    static let colorBufferBit: Int32 = 0x4000, framebufferComplete: Int32 = 0x8CD5
    static let rgba: Int32 = 0x1908, rg: Int32 = 0x8227, red: Int32 = 0x1903, depthComponent: Int32 = 0x1902
    static let rgba8: Int32 = 0x8058, srgb8Alpha8: Int32 = 0x8C43, rgba16f: Int32 = 0x881A, rg16f: Int32 = 0x822F,
               r16f: Int32 = 0x822D, r8: Int32 = 0x8229, r32f: Int32 = 0x822E, depth32f: Int32 = 0x8CAC
    static let bc7: Int32 = 0x8E8C, bc7Srgb: Int32 = 0x8E8D, bc6hUfloat: Int32 = 0x8E8F, bc5: Int32 = 0x8DBD,
               astc4x4: Int32 = 0x93B0, astc4x4Srgb: Int32 = 0x93D0
}

/// Command opcodes and their lengths in words (opcode included): keep in sync with Web/webgl2.js.
enum WebGL2Op {
    static let beginPass: Int32 = 1, endPass: Int32 = 2, pipeline: Int32 = 3, vao: Int32 = 4, attrib: Int32 = 5, index: Int32 = 6,
               ubo: Int32 = 7, texture: Int32 = 8, scissor: Int32 = 9, viewport: Int32 = 10, draw: Int32 = 11, drawIndexed: Int32 = 12,
               beginQuery: Int32 = 13, endQuery: Int32 = 14, beginTimer: Int32 = 15, endTimer: Int32 = 16, createVAO: Int32 = 17
}

/// A frame's commands, as Int32 words (floats by bit pattern) in WebAssembly memory, run by
/// Web/webgl2.js's `execute` in one call. Writing them allocates nothing once the buffer has grown.
@MainActor final class WebGL2Commands {
    private(set) var words: UnsafeMutablePointer<Int32>
    private(set) var count = 0
    private var capacity: Int

    init() {
        capacity = 16 * 1024
        words = .allocate(capacity: capacity)
    }

    var isEmpty: Bool { count == 0 }

    func reset() { count = 0 }

    /// Room for `n` more words; returns where they go and counts them.
    @inline(__always) func append(_ n: Int) -> UnsafeMutablePointer<Int32> {
        if count + n > capacity {
            let grown = UnsafeMutablePointer<Int32>.allocate(capacity: max(capacity * 2, count + n))
            grown.update(from: words, count: count)
            words.deallocate()
            words = grown
            capacity = max(capacity * 2, count + n)
        }
        let p = words + count
        count += n
        return p
    }

    @inline(__always) func op(_ code: Int32) { append(1)[0] = code }

    @inline(__always) func op(_ code: Int32, _ a: Int32) {
        let p = append(2)
        p[0] = code; p[1] = a
    }

    @inline(__always) func op(_ code: Int32, _ a: Int32, _ b: Int32) {
        let p = append(3)
        p[0] = code; p[1] = a; p[2] = b
    }

    @inline(__always) func op(_ code: Int32, _ a: Int32, _ b: Int32, _ c: Int32) {
        let p = append(4)
        p[0] = code; p[1] = a; p[2] = b; p[3] = c
    }

    @inline(__always) func op(_ code: Int32, _ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32) {
        let p = append(5)
        p[0] = code; p[1] = a; p[2] = b; p[3] = c; p[4] = d
    }

    @inline(__always) func op(_ code: Int32, _ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ e: Int32) {
        let p = append(6)
        p[0] = code; p[1] = a; p[2] = b; p[3] = c; p[4] = d; p[5] = e
    }

    @inline(__always) func op(_ code: Int32, _ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ e: Int32, _ f: Int32) {
        let p = append(7)
        p[0] = code; p[1] = a; p[2] = b; p[3] = c; p[4] = d; p[5] = e; p[6] = f
    }
}

/// Ids of the device's WebGL objects (Web/webgl2.js keeps the objects by id). Never reused, so
/// caches keyed by ids can't confuse a new object with a deleted one.
@MainActor enum WebGL2IDs {
    private static var next: Int32 = 0
    static func make() -> Int32 {
        next += 1
        return next
    }
}

/// Objects released by Swift, deleted at the end of the frame that may still use them.
/// `deinit` is nonisolated; WebAssembly here is single-threaded, so a plain global is safe.
nonisolated(unsafe) var webGL2PendingDeletes: [Int32] = []

final class WebGL2Buffer: GPUBuffer {
    let id = WebGL2IDs.make()
    let length: Int
    /// The WebGL buffer's size (`length` rounded up, plus slack for transient chunks).
    let allocatedLength: Int
    /// An index buffer: WebGL binds it as nothing else.
    let isIndex: Bool
    /// Transient ring chunks: the CPU copy the ring writes into, and how much of it was written
    /// this frame / already uploaded (`WebGL2RenderDevice.flushTransient`).
    var staging: UnsafeMutableRawPointer?
    var dirtyEnd = 0
    var flushedEnd = 0

    init(length: Int, allocatedLength: Int, isIndex: Bool) {
        self.length = length
        self.allocatedLength = allocatedLength
        self.isIndex = isIndex
    }

    isolated deinit {
        webGL2PendingDeletes.append(id)
        staging?.deallocate()
    }
}

final class WebGL2Texture: GPUTexture {
    let id: Int32
    let format: TextureFormat
    let internalFormat: Int32
    let width: Int
    let height: Int
    let mipLevelCount: Int
    /// false for a texture of the page (none yet) that the device doesn't delete.
    private let owns: Bool

    init(id: Int32 = WebGL2IDs.make(), format: TextureFormat, internalFormat: Int32, width: Int, height: Int, mipLevelCount: Int = 1,
         owns: Bool = true) {
        self.id = id
        self.format = format
        self.internalFormat = internalFormat
        self.width = width
        self.height = height
        self.mipLevelCount = mipLevelCount
        self.owns = owns
    }

    /// Framebuffer attachment id (textures positive, renderbuffers negative).
    var attachment: Int32 { id }

    isolated deinit {
        if owns { webGL2PendingDeletes.append(id) }
    }
}

/// A multisampled (or depth-only) attachment that is never sampled.
@MainActor final class WebGL2Renderbuffer {
    let id = WebGL2IDs.make()
    let width: Int
    let height: Int
    let samples: Int

    init(width: Int, height: Int, samples: Int) {
        self.width = width
        self.height = height
        self.samples = samples
    }

    var attachment: Int32 { -id }

    isolated deinit {
        webGL2PendingDeletes.append(id)
    }
}

final class WebGL2Sampler: GPUSampler {
    let id = WebGL2IDs.make()
    let descriptor: SamplerDescriptor

    init(descriptor: SamplerDescriptor) {
        self.descriptor = descriptor
    }
}

/// See `GPURenderTarget`.
final class WebGL2RenderTarget: GPURenderTarget {
    let resolved: WebGL2Texture
    let msaa: WebGL2Renderbuffer?
    let depth: WebGL2Renderbuffer?
    var width: Int { resolved.width }
    var height: Int { resolved.height }
    var sampleCount: Int { msaa?.samples ?? 1 }
    var texture: GPUTexture { resolved }

    init(resolved: WebGL2Texture, msaa: WebGL2Renderbuffer?, depth: WebGL2Renderbuffer?) {
        self.resolved = resolved
        self.msaa = msaa
        self.depth = depth
    }
}

/// A linked program and where its resources bind: uniform blocks to binding points (with the size
/// a bound range must have), samplers to texture units. Shared by every pipeline with the same shaders.
@MainActor final class WebGL2Program {
    let id: Int32
    /// Binding point and the largest block size bound there (both stages').
    let uniformBlocks: [(point: Int32, size: Int)]
    /// Texture unit, the engine's texture slot (0: set 1) and sampler slot (nil: none), and
    /// whether it is a shadow sampler.
    let samplers: [(unit: Int32, texture: Int, sampler: Int?, shadow: Bool)]

    init(id: Int32, uniformBlocks: [(point: Int32, size: Int)], samplers: [(unit: Int32, texture: Int, sampler: Int?, shadow: Bool)]) {
        self.id = id
        self.uniformBlocks = uniformBlocks
        self.samplers = samplers
    }
}

/// The vertex buffer layouts of a pipeline (slots 0, 1 and 2), shared by pipelines with equal
/// layouts so they share vertex arrays.
@MainActor final class WebGL2VertexLayout {
    let id = Int(WebGL2IDs.make())
    /// Per slot: (location, components, offset) of each attribute, the stride, and the divisor.
    let slots: [(attributes: [(location: Int32, size: Int32, offset: Int)], stride: Int32, divisor: Int32)]

    init(_ layouts: [VertexLayout?]) {
        slots = layouts.enumerated().map { slot, layout in
            let attributes = (layout?.attributes ?? []).map { attribute -> (location: Int32, size: Int32, offset: Int) in
                let size: Int32 = switch attribute.format {
                case .float: 1
                case .float2: 2
                case .float3: 3
                case .float4: 4
                }
                return (Int32(attribute.location), size, attribute.offset)
            }
            return (attributes, Int32(layout?.stride ?? 0), slot == 1 ? 1 : 0)
        }
    }
}

final class WebGL2Pipeline: RenderPipeline {
    let program: WebGL2Program
    let layout: WebGL2VertexLayout
    /// The PIPELINE command's words after the opcode and program (see Web/webgl2.js `applyPipeline`).
    let state: [Int32]
    let colorWrites: Bool
    let writesMotionVectors: Bool
    let depthOnly: Bool

    init(program: WebGL2Program, layout: WebGL2VertexLayout, state: [Int32], colorWrites: Bool, writesMotionVectors: Bool, depthOnly: Bool) {
        self.program = program
        self.layout = layout
        self.state = state
        self.colorWrites = colorWrites
        self.writesMotionVectors = writesMotionVectors
        self.depthOnly = depthOnly
    }
}

/// Compute is WebGPU's (and Metal's and Vulkan's): `makeComputePipeline` throws, so this is never made.
final class WebGL2ComputePipeline: ComputePipeline {
    let workgroupSize = ComputeSize(1, 1, 1)
}

extension TextureFormat {
    /// The sized internal format of this format's textures, nil without one in WebGL 2.
    var webGL2InternalFormat: Int32? {
        switch self {
        case .depth32Float: GL.depth32f
        case .rgba8Unorm: GL.rgba8
        case .rgba8Srgb: GL.srgb8Alpha8
        case .rgba16Float: GL.rgba16f
        case .r8Unorm: GL.r8
        case .r16Float: GL.r16f
        case .rg16Float: GL.rg16f
        case .r32Float: GL.r32f
        case .bc7Unorm: GL.bc7
        case .bc7Srgb: GL.bc7Srgb
        case .bc5Unorm: GL.bc5
        case .bc6hUfloat: GL.bc6hUfloat
        case .astc4x4Unorm, .astc4x4RG, .astc4x4HDR: GL.astc4x4
        case .astc4x4Srgb: GL.astc4x4Srgb
        }
    }

    /// The `format` and `type` of `texSubImage2D` uploads (type 0: compressed).
    var webGL2Upload: (format: Int32, type: Int32) {
        switch self {
        case .rgba8Unorm, .rgba8Srgb: (GL.rgba, GL.unsignedByte)
        case .rgba16Float: (GL.rgba, GL.halfFloat)
        case .r8Unorm: (GL.red, GL.unsignedByte)
        case .r16Float: (GL.red, GL.halfFloat)
        case .rg16Float: (GL.rg, GL.halfFloat)
        case .r32Float: (GL.red, GL.float)
        case .depth32Float: (GL.depthComponent, GL.float)
        default: (webGL2InternalFormat ?? 0, 0)
        }
    }
}

extension CompareFunction {
    var webGL2: Int32 {
        switch self {
        case .never: GL.never
        case .less: GL.less
        case .lessEqual: GL.lessEqual
        case .equal: GL.equal
        case .greater: GL.greater
        case .greaterEqual: GL.greaterEqual
        case .always: GL.always
        }
    }
}

extension BlendFactor {
    var webGL2: Int32 {
        switch self {
        case .zero: GL.zero
        case .one: GL.one
        case .sourceAlpha: GL.sourceAlpha
        case .oneMinusSourceAlpha: GL.oneMinusSourceAlpha
        case .destinationColor: GL.destinationColor
        }
    }
}
#endif
