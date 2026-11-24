#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

// WebGPU enum flags (GPUBufferUsage, GPUTextureUsage, GPUShaderStage, GPUMapMode).
enum WebGPUBufferUsage {
    static let mapRead = 0x1, copySource = 0x4, copyDestination = 0x8, index = 0x10, vertex = 0x20, uniform = 0x40,
               storage = 0x80, indirect = 0x100, queryResolve = 0x200
    /// Every engine buffer can be any of these (see `BufferUsage`).
    static let all = copySource | copyDestination | index | vertex | uniform | storage | indirect
}

enum WebGPUTextureUsage {
    static let copySource = 0x1, copyDestination = 0x2, textureBinding = 0x4, storageBinding = 0x8, renderAttachment = 0x10
}

enum WebGPUShaderStage {
    static let vertex = 0x1, fragment = 0x2, compute = 0x4
}

/// Size of every uniform buffer binding window (`maxUniformBufferSize`). Uniform bindings use
/// dynamic offsets, so a bind group is reused for any offset into the same buffer; the transient
/// ring's buffers have this much slack past their end so a window at any offset fits.
let webGPUUniformWindow = maxUniformBufferSize

/// Hands out ids that key the bind group cache (JS objects have no cheap identity in Swift).
@MainActor enum WebGPUIDs {
    private static var next = 1
    static func make() -> Int {
        next += 1
        return next
    }
}

/// GPU objects released by Swift, destroyed after the frame that may still use them is submitted.
/// `deinit` is nonisolated; WebAssembly here is single-threaded, so a plain global is safe.
nonisolated(unsafe) var webGPUPendingDestroys: [JSObject] = []

/// WebGPU's largest query set: occlusion queries past this many in a frame aren't issued and
/// report visible (the engine allows `maxOcclusionQueriesPerFrame`).
let webGPUMaxOcclusionQueries = 4096

func roundUp(_ value: Int, _ multiple: Int) -> Int { (value + multiple - 1) / multiple * multiple }

/// A JS object from Swift values.
func jsObject(_ entries: [String: ConvertibleToJSValue]) -> JSObject {
    entries.jsValue.object!
}

/// A JS `Uint8Array` holding a copy of `bytes`.
func jsBytes(_ bytes: UnsafeRawBufferPointer) -> JSObject {
    JSTypedArray<UInt8>(buffer: bytes.bindMemory(to: UInt8.self)).jsObject
}

/// Calls `body(true)` when `promise` resolves, `body(false)` if it rejects.
@MainActor func whenSettled(_ promise: JSValue, _ body: @escaping @MainActor (Bool) -> Void) {
    final class Callbacks {
        var closures: [JSClosure] = []
        var done = false
    }
    let callbacks = Callbacks()
    let settle: (Bool) -> JSValue = { ok in
        guard !callbacks.done else { return .undefined }
        callbacks.done = true
        MainActor.assumeIsolated { body(ok) }
        for closure in callbacks.closures { closure.release() }
        callbacks.closures = []
        return .undefined
    }
    callbacks.closures = [JSClosure { _ in settle(true) }, JSClosure { _ in settle(false) }]
    _ = promise.object!.then!(callbacks.closures[0], callbacks.closures[1])
}

final class WebGPUBuffer: GPUBuffer {
    let object: JSObject
    let length: Int
    /// The JS buffer's size: `length` rounded up to 4 (and, for transient chunks, plus slack).
    let allocatedLength: Int
    let id = WebGPUIDs.make()
    /// Transient ring chunks: the CPU copy the ring writes into, and how much of it was written
    /// this frame / already copied to the GPU buffer (`WebGPURenderDevice.flushTransient`).
    var staging: UnsafeMutableRawPointer?
    var dirtyEnd = 0
    var flushedEnd = 0

    init(object: JSObject, length: Int, allocatedLength: Int) {
        self.object = object
        self.length = length
        self.allocatedLength = allocatedLength
    }

    isolated deinit {
        webGPUPendingDestroys.append(object)
        staging?.deallocate()
    }
}

final class WebGPUTexture: GPUTexture {
    let object: JSObject
    let format: TextureFormat
    /// The WebGPU format string of `object` (`.rgba8Srgb` render targets use the window's format).
    let gpuFormat: String
    let width: Int
    let height: Int
    let mipLevelCount: Int
    let sampleCount: Int
    /// The view bindings and attachments use.
    let view: JSObject
    let id = WebGPUIDs.make()
    /// false for a second view of another texture's object (it doesn't destroy it).
    private let owns: Bool

    init(object: JSObject, format: TextureFormat, gpuFormat: String, width: Int, height: Int, mipLevelCount: Int = 1,
         sampleCount: Int = 1, view: JSObject? = nil, owns: Bool = true) {
        self.object = object
        self.format = format
        self.gpuFormat = gpuFormat
        self.width = width
        self.height = height
        self.mipLevelCount = mipLevelCount
        self.sampleCount = sampleCount
        self.view = view ?? object.createView!().object!
        self.owns = owns
    }

    /// The same texture seen through a view of `viewFormat` (e.g. an sRGB image read as unorm).
    func reinterpreted(as viewFormat: String, format: TextureFormat) -> WebGPUTexture {
        WebGPUTexture(object: object, format: format, gpuFormat: viewFormat, width: width, height: height,
                      mipLevelCount: mipLevelCount, sampleCount: sampleCount,
                      view: object.createView!(jsObject(["format": viewFormat])).object!, owns: false)
    }

    isolated deinit {
        if owns { webGPUPendingDestroys.append(object) }
    }
}

final class WebGPUSampler: GPUSampler {
    let object: JSObject
    let descriptor: SamplerDescriptor
    let id = WebGPUIDs.make()

    init(object: JSObject, descriptor: SamplerDescriptor) {
        self.object = object
        self.descriptor = descriptor
    }
}

/// See `GPURenderTarget`.
final class WebGPURenderTarget: GPURenderTarget {
    let resolved: WebGPUTexture
    let msaa: WebGPUTexture?
    let depth: WebGPUTexture?
    let format: WebGPUPassFormat
    var width: Int { resolved.width }
    var height: Int { resolved.height }
    var sampleCount: Int { msaa?.sampleCount ?? 1 }
    var texture: GPUTexture { resolved }

    init(resolved: WebGPUTexture, msaa: WebGPUTexture?, depth: WebGPUTexture?, format: WebGPUPassFormat) {
        self.resolved = resolved
        self.msaa = msaa
        self.depth = depth
        self.format = format
    }
}

/// The attachments of a pass; a pipeline draws in it with the variant built for them.
struct WebGPUPassFormat: Hashable {
    /// The color attachment's format, nil for depth-only passes.
    var color: String?
    var samples: Int
    /// A motion-vector attachment at location 1 (`rg16float`, temporal upscaling).
    var motionVectors = false
    var depth = true
}

/// One entry of a bind group layout: a binding the pipeline's shaders use.
struct WebGPULayoutEntry: Hashable {
    var binding: Int
    var kind: WGSLBinding.Kind
    var visibility: Int
}

/// A bind group layout, shared by every pipeline whose shaders use the same bindings in a group.
@MainActor final class WebGPUBindGroupLayout {
    let object: JSObject
    let entries: [WebGPULayoutEntry]
    let id = WebGPUIDs.make()

    init(object: JSObject, entries: [WebGPULayoutEntry]) {
        self.object = object
        self.entries = entries
    }
}

/// The bind group layouts of a pipeline, groups 0...3 (empty ones in between still need a group).
@MainActor final class WebGPUPipelineLayout {
    let groups: [WebGPUBindGroupLayout]
    let object: JSObject

    init(groups: [WebGPUBindGroupLayout], object: JSObject) {
        self.groups = groups
        self.object = object
    }
}

final class WebGPUPipeline: RenderPipeline {
    let layout: WebGPUPipelineLayout
    /// The pass format `object` was built for (nil: depth-only).
    let format: WebGPUPassFormat?
    let object: JSObject
    /// `.screen` pipelines: builds the variant for another color pass (HDR scene, render
    /// targets, a motion-vector attachment) on first use there.
    private let makeVariant: ((WebGPUPassFormat) throws -> JSObject)?
    private var variants: [WebGPUPassFormat: JSObject] = [:]

    init(layout: WebGPUPipelineLayout, format: WebGPUPassFormat?, object: JSObject,
         makeVariant: ((WebGPUPassFormat) throws -> JSObject)?) {
        self.layout = layout
        self.format = format
        self.object = object
        self.makeVariant = makeVariant
    }

    func object(for pass: WebGPUPassFormat?) -> JSObject {
        guard let pass, pass != format else { return object }
        if let cached = variants[pass] { return cached }
        guard pass.depth, let makeVariant else {
            preconditionFailure("This pipeline can't draw in this pass (\(pass)); check its PipelineTarget")
        }
        do {
            let made = try makeVariant(pass)
            variants[pass] = made
            return made
        } catch {
            preconditionFailure("Failed to create a variant of a pipeline for \(pass): \(error)")
        }
    }
}

final class WebGPUComputePipeline: ComputePipeline {
    let layout: WebGPUPipelineLayout
    let object: JSObject
    let workgroupSize: ComputeSize

    init(layout: WebGPUPipelineLayout, object: JSObject, workgroupSize: ComputeSize) {
        self.layout = layout
        self.object = object
        self.workgroupSize = workgroupSize
    }
}

extension TextureFormat {
    /// The WebGPU format of sampled (uploaded) textures and storage textures of this format.
    var webGPUFormat: String {
        switch self {
        case .depth32Float: "depth32float"
        case .rgba8Unorm: "rgba8unorm"
        case .rgba8Srgb: "rgba8unorm-srgb"
        case .rgba16Float: "rgba16float"
        case .r8Unorm: "r8unorm"
        case .r16Float: "r16float"
        case .rg16Float: "rg16float"
        case .r32Float: "r32float"
        case .bc7Unorm: "bc7-rgba-unorm"
        case .bc7Srgb: "bc7-rgba-unorm-srgb"
        case .astc4x4Unorm, .astc4x4RG: "astc-4x4-unorm"
        case .astc4x4Srgb: "astc-4x4-unorm-srgb"
        case .bc5Unorm: "bc5-rg-unorm"
        case .bc6hUfloat: "bc6h-rgb-ufloat"
        // WebGPU's ASTC formats are LDR only; `supports` reports this one unsupported.
        case .astc4x4HDR: "astc-4x4-unorm"
        }
    }
}

extension VertexFormat {
    var webGPU: String {
        switch self {
        case .float: "float32"
        case .float2: "float32x2"
        case .float3: "float32x3"
        case .float4: "float32x4"
        }
    }
}

extension CompareFunction {
    var webGPU: String {
        switch self {
        case .never: "never"
        case .less: "less"
        case .lessEqual: "less-equal"
        case .equal: "equal"
        case .greater: "greater"
        case .greaterEqual: "greater-equal"
        case .always: "always"
        }
    }
}

extension BlendFactor {
    var webGPU: String {
        switch self {
        case .zero: "zero"
        case .one: "one"
        case .sourceAlpha: "src-alpha"
        case .oneMinusSourceAlpha: "one-minus-src-alpha"
        case .destinationColor: "dst"
        }
    }
}

extension WGSLBinding.Kind {
    /// The bind group layout entry's resource part (`buffer`, `sampler`, `texture`, `storageTexture`).
    var layoutEntry: (key: String, value: [String: ConvertibleToJSValue]) {
        switch self {
        case .uniformBuffer: ("buffer", ["type": "uniform", "hasDynamicOffset": true])
        case .storageBuffer(let readOnly): ("buffer", ["type": readOnly ? "read-only-storage" : "storage"])
        case .sampler(let comparison): ("sampler", ["type": comparison ? "comparison" : "filtering"])
        case .texture(let sampleType): ("texture", ["sampleType": sampleType.rawValue, "viewDimension": "2d"])
        case .storageTexture(let format, let access): ("storageTexture", ["format": format, "access": access, "viewDimension": "2d"])
        }
    }
}
#endif
