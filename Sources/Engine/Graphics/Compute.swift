import Foundation

/// A 3D count: threads per workgroup, workgroups, or threads of a dispatch.
public struct ComputeSize: Sendable, Equatable, CustomStringConvertible {
    public var x, y, z: Int

    public init(_ x: Int, _ y: Int = 1, _ z: Int = 1) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var count: Int { x * y * z }
    public var description: String { "\(x)x\(y)x\(z)" }

    /// Workgroups of `workgroup` needed to cover `self` threads (rounded up per axis).
    func groups(of workgroup: ComputeSize) -> ComputeSize {
        ComputeSize((x + workgroup.x - 1) / workgroup.x, (y + workgroup.y - 1) / workgroup.y, (z + workgroup.z - 1) / workgroup.z)
    }
}

public struct ComputePipelineDescriptor: Sendable {
    /// A compute shader: `ShaderSource.load(compute:)` (GLSL `.comp` compiled by
    /// Scripts/compile-shaders.sh), or hand-written MSL defining `compute_main` plus SPIR-V.
    public var shader: ShaderSource
    /// Threads per workgroup. nil reads the GLSL `layout(local_size_x = …)` from the SPIR-V
    /// (Metal needs it at dispatch time; SPIR-V and the generated MSL bake it in).
    public var workgroupSize: ComputeSize?

    public init(shader: ShaderSource, workgroupSize: ComputeSize? = nil) {
        self.shader = shader
        self.workgroupSize = workgroupSize
    }

    /// `workgroupSize`, or the size declared in the SPIR-V.
    func resolvedWorkgroupSize() throws -> ComputeSize {
        if let workgroupSize { return workgroupSize }
        guard let spirv = shader.spirvCompute, let size = ShaderSource.workgroupSize(spirv: spirv) else {
            throw GraphicsError("Compute shader has no SPIR-V with a local size; set ComputePipelineDescriptor.workgroupSize")
        }
        return size
    }
}

/// A compiled compute shader. Released like `GPUBuffer`.
@MainActor public protocol ComputePipeline: AnyObject {
    /// Threads per workgroup (`local_size` in GLSL).
    var workgroupSize: ComputeSize { get }
}

/// Records compute dispatches (`Frame.computePass`, `RenderDevice.beginComputePass`).
///
/// Ordering and visibility are handled for you, on both backends:
/// - The pass starts after everything recorded before it in the frame (render passes, buffer
///   updates, earlier compute passes, and earlier frames' work still in flight) and sees what
///   they wrote; nothing it overwrites is still being read.
/// - Dispatches within a pass run in order, each seeing the previous ones' writes (a
///   compute-to-compute barrier between dispatches on Vulkan; a serial encoder with hazard
///   tracking on Metal), so multi-pass algorithms (prefix sums, reductions, FSR-style chains)
///   can be written as consecutive dispatches.
/// - Passes recorded after it (vertex input, indirect arguments, any shader stage, copies)
///   see its writes.
/// On Vulkan this is a full memory barrier before and after each pass (resources aren't
/// tracked individually); on Metal, encoders and hazard-tracked resources order themselves.
///
/// Bindings follow the graphics table (see `ShaderSource`) plus storage resources:
/// - storage buffer n (`storageBufferIndices`): GLSL `layout(set = 2, binding = 24 + n, std430) buffer`, MSL `[[buffer(20 + n)]]`
/// - storage texture n (`storageTextureIndices`): GLSL `layout(set = 2, binding = 32 + n, rgba16f) uniform image2D`
///   (or `rgba8`, `r8`, `r16f`, `rg16f`, `r32f`: the texture's format), MSL `[[texture(8 + n)]]`
/// - uniform buffers 2...7, textures and samplers 1...7, push constants: as for render passes.
///   Sets 0 and 1 (`setUniformData(_:)`, the shadow map) are graphics-only.
/// Bindings persist across dispatches until replaced; a shader must only use slots the pass has bound.
@MainActor public protocol ComputePass: AnyObject {
    func setPipeline(_ pipeline: ComputePipeline)
    /// Binds `buffer` (`.storage` usage) from `offset` (a multiple of `storageBufferOffsetAlignment`)
    /// as storage buffer `index`, read and written by the shader.
    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int)
    /// Binds a storage texture (`TextureDescriptor.storage`) as storage texture `index`.
    func setStorageTexture(_ texture: GPUTexture, index: Int)
    /// Binds a color texture for sampling or `texelFetch` (texture `index` in `textureIndices`),
    /// or a `.depth32Float` texture an earlier depth pass rendered (`texelFetch`, depth in .r).
    func setTexture(_ texture: GPUTexture, index: Int)
    func setSampler(_ sampler: GPUSampler, index: Int)
    /// Binds `buffer` (`.uniform` or `.storage` usage) as uniform buffer `index` (`uniformBufferIndices`).
    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int)
    /// Copies up to `maxUniformBufferSize` bytes into the frame's transient memory and binds
    /// them as uniform buffer `index`.
    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int)
    /// ≤ `maxPushConstantSize` bytes, `layout(push_constant)` / `[[buffer(16)]]`.
    func setPushConstants(_ bytes: UnsafeRawBufferPointer)
    /// Runs `groups` workgroups of the pipeline's `workgroupSize`.
    func dispatch(groups: ComputeSize)
    /// Runs as many workgroups as `buffer` holds at `offset` (`DispatchIndirectArguments`: x, y, z
    /// as three UInt32s; any of them 0 runs nothing), read when the dispatch executes, so earlier
    /// dispatches of this pass (or earlier passes) can compute it. `buffer` needs `.storage`
    /// usage and `offset` must be a multiple of 4.
    func dispatchIndirect(buffer: GPUBuffer, offset: Int)
}

/// What `ComputePass.dispatchIndirect(buffer:offset:)` reads: workgroup counts per axis
/// (`VkDispatchIndirectCommand` and `MTLDispatchThreadgroupsIndirectArguments` alike).
public struct DispatchIndirectArguments: Sendable, Equatable, BitwiseCopyable {
    public var groupsX: UInt32
    public var groupsY: UInt32
    public var groupsZ: UInt32

    public init(groupsX: UInt32, groupsY: UInt32 = 1, groupsZ: UInt32 = 1) {
        self.groupsX = groupsX
        self.groupsY = groupsY
        self.groupsZ = groupsZ
    }
}

extension ComputePass {
    public func setStorageBuffer(_ buffer: GPUBuffer, index: Int) {
        setStorageBuffer(buffer, offset: 0, index: index)
    }

    public func setUniformData<T: BitwiseCopyable>(_ value: T, index: Int) {
        withUnsafeBytes(of: value) { setUniformData($0, index: index) }
    }

    public func setPushConstants<T: BitwiseCopyable>(_ value: T) {
        withUnsafeBytes(of: value) { setPushConstants($0) }
    }

    /// Enough workgroups of `pipeline` to cover `threads` (the last ones partially: shaders
    /// must skip invocations past the end).
    public func dispatch(threads: ComputeSize, of pipeline: ComputePipeline) {
        dispatch(groups: threads.groups(of: pipeline.workgroupSize))
    }
}

extension ShaderSource {
    /// The `LocalSize` execution mode of a compute shader's SPIR-V (`layout(local_size_x = …)`),
    /// nil if it has none.
    static func workgroupSize(spirv: [UInt8]) -> ComputeSize? {
        guard spirv.count >= 20, spirv.count % 4 == 0 else { return nil }
        let words = spirv.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
        guard words[0] == 0x0723_0203 else { return nil }  // SPIR-V magic, little-endian
        var i = 5  // after the header
        while i < words.count {
            let count = Int(words[i] >> 16), opcode = words[i] & 0xffff
            guard count > 0, i + count <= words.count else { return nil }
            // OpExecutionMode %entry LocalSize x y z
            if opcode == 16, count == 6, words[i + 2] == 17 {
                return ComputeSize(Int(words[i + 3]), Int(words[i + 4]), Int(words[i + 5]))
            }
            i += count
        }
        return nil
    }
}

/// Checks a storage buffer binding (`setStorageBuffer`).
@MainActor func validateStorageBinding(_ buffer: GPUBuffer, offset: Int, index: Int) {
    precondition(storageBufferIndices.contains(index), "Storage buffer index \(index) is outside \(storageBufferIndices)")
    precondition(offset % storageBufferOffsetAlignment == 0 && offset >= 0 && offset < buffer.length,
                 "Storage buffer offset must be inside the buffer and a multiple of \(storageBufferOffsetAlignment)")
}

/// Checks an indirect dispatch's argument range (`dispatchIndirect(buffer:offset:)`).
@MainActor func validateDispatchIndirect(_ buffer: GPUBuffer, offset: Int) {
    precondition(offset >= 0 && offset % 4 == 0 && offset + MemoryLayout<DispatchIndirectArguments>.size <= buffer.length,
                 "Indirect dispatch arguments at offset \(offset) must be 4-byte aligned and inside the buffer's \(buffer.length) bytes")
}

/// Checks a readback range (`readBack(_:offset:length:completion:)`).
@MainActor func validateBufferReadback(_ buffer: GPUBuffer, offset: Int, length: Int) {
    precondition(length > 0 && (try? validateBufferUpdate(bufferLength: buffer.length, offset: offset, byteCount: length)) != nil,
                 "Buffer readback of \(length) bytes at offset \(offset) is outside the buffer's \(buffer.length) bytes")
}
