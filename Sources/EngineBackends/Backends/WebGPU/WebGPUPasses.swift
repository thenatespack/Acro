#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

/// Encoder methods, looked up once on the prototypes (a dynamic member call costs a lookup per call).
@MainActor final class WebGPUEncoderFunctions {
    static let render = WebGPUEncoderFunctions(JSObject.global.GPURenderPassEncoder.object!.prototype.object!)
    static let compute = WebGPUEncoderFunctions(JSObject.global.GPUComputePassEncoder.object!.prototype.object!)

    let setPipeline, setBindGroup, end: JSFunction
    let setVertexBuffer, setIndexBuffer, setScissorRect, setViewport, draw, drawIndexed, drawIndirect, drawIndexedIndirect,
        beginOcclusionQuery, endOcclusionQuery: JSFunction?
    let dispatchWorkgroups, dispatchWorkgroupsIndirect: JSFunction?

    private init(_ prototype: JSObject) {
        func function(_ name: String) -> JSFunction? { prototype[name].function }
        setPipeline = function("setPipeline")!
        setBindGroup = function("setBindGroup")!
        end = function("end")!
        setVertexBuffer = function("setVertexBuffer")
        setIndexBuffer = function("setIndexBuffer")
        setScissorRect = function("setScissorRect")
        setViewport = function("setViewport")
        draw = function("draw")
        drawIndexed = function("drawIndexed")
        drawIndirect = function("drawIndirect")
        drawIndexedIndirect = function("drawIndexedIndirect")
        beginOcclusionQuery = function("beginOcclusionQuery")
        endOcclusionQuery = function("endOcclusionQuery")
        dispatchWorkgroups = function("dispatchWorkgroups")
        dispatchWorkgroupsIndirect = function("dispatchWorkgroupsIndirect")
    }
}

/// What a pass has bound (the engine's slots), turned into bind groups at each draw or dispatch
/// for the current pipeline's layout. Slots a shader uses but the pass never bound get a
/// placeholder resource, as WebGPU requires every binding of a layout to be bound.
@MainActor final class WebGPUBindings {
    private unowned let device: WebGPURenderDevice
    /// Group 0, binding 0 (`setUniformData(_:)`).
    var frameUniform: (buffer: WebGPUBuffer, offset: Int)?
    /// Group 1: the shadow map (with the comparison sampler), or an image and sampler for the
    /// backend's own blit and upscale passes.
    var shadowMap: WebGPUTexture?
    var image: (texture: WebGPUTexture, sampler: WebGPUSampler)?
    /// Group 2, by engine index.
    var uniforms = [(buffer: WebGPUBuffer, offset: Int)?](repeating: nil, count: 8)
    var textures = [WebGPUTexture?](repeating: nil, count: 8)
    var samplers = [WebGPUSampler?](repeating: nil, count: 8)
    var storageBuffers = [(buffer: WebGPUBuffer, offset: Int)?](repeating: nil, count: 8)
    var storageTextures = [WebGPUTexture?](repeating: nil, count: 8)
    /// Group 3, binding 0 (`setPushConstants`).
    var pushConstants: (buffer: WebGPUBuffer, offset: Int)?
    /// What each group index has bound in the encoder (layout and resources, dynamic offsets).
    private var current: [(key: [Int], offsets: [Int])?] = [nil, nil, nil, nil]

    init(device: WebGPURenderDevice) {
        self.device = device
    }

    /// Binds the groups of `layout` from the current slots, skipping groups that haven't changed.
    func apply(_ layout: WebGPUPipelineLayout, encoder: JSObject, functions: WebGPUEncoderFunctions) {
        for (index, group) in layout.groups.enumerated() {
            var key = [group.id]
            var offsets: [Int] = []
            var resources: [(binding: Int, resource: () -> ConvertibleToJSValue)] = []
            for entry in group.entries {
                let resolved = resource(group: index, entry: entry)
                key.append(contentsOf: resolved.key)
                if let offset = resolved.dynamicOffset { offsets.append(offset) }
                resources.append((entry.binding, resolved.make))
            }
            if let bound = current[index], bound.key == key, bound.offsets == offsets { continue }
            let bindGroup = device.bindGroup(key: key) {
                jsObject(["layout": group.object, "entries": resources.map { ["binding": $0.binding, "resource": $0.resource()].jsValue }])
            }
            _ = functions.setBindGroup(this: encoder, index, bindGroup, offsets)
            current[index] = (key, offsets)
        }
    }

    /// The resource for one layout entry: its cache key, dynamic offset (uniform buffers) and JS value.
    private func resource(group: Int, entry: WebGPULayoutEntry)
        -> (key: [Int], dynamicOffset: Int?, make: () -> ConvertibleToJSValue) {
        let binding = entry.binding
        switch entry.kind {
        case .uniformBuffer:
            var bound: (buffer: WebGPUBuffer, offset: Int)?
            switch group {
            case 0: bound = frameUniform
            case 2 where uniformBufferIndices.contains(binding): bound = uniforms[binding]
            case 3: bound = pushConstants
            default: break
            }
            let (buffer, offset) = bound ?? (device.placeholderUniform, 0)
            let size = min(webGPUUniformWindow, buffer.allocatedLength - offset)
            return ([buffer.id, size], offset, { jsObject(["buffer": buffer.object, "offset": 0, "size": size]) })
        case .storageBuffer:
            let index = binding - 24
            let (buffer, offset) = (group == 2 && storageBufferIndices.contains(index) ? storageBuffers[index] : nil)
                ?? (device.placeholderStorage, 0)
            return ([buffer.id, offset], nil, {
                jsObject(["buffer": buffer.object, "offset": offset, "size": buffer.allocatedLength - offset])
            })
        case .sampler(let comparison):
            let sampler: WebGPUSampler
            if comparison {
                sampler = device.comparisonSampler
            } else if group == 1 {
                sampler = image?.sampler ?? device.linearSampler
            } else {
                let index = binding - 16
                sampler = (textureIndices.contains(index) ? samplers[index] : nil) ?? device.linearSampler
            }
            return ([sampler.id], nil, { sampler.object })
        case .texture(let sampleType):
            var texture: WebGPUTexture?
            if group == 1 {
                texture = sampleType == .depth ? shadowMap : image?.texture
            } else if group == 2, textureIndices.contains(binding - 8) {
                texture = textures[binding - 8]
            }
            let bound = texture ?? device.placeholderTexture(sampleType)
            return ([bound.id], nil, { bound.view })
        case .storageTexture(let format, _):
            let index = binding - 32
            let bound = (group == 2 && storageTextureIndices.contains(index) ? storageTextures[index] : nil)
                ?? device.placeholderStorageTexture(format)
            return ([bound.id], nil, { bound.view })
        }
    }
}

final class WebGPURenderPass: RenderPass {
    let encoder: JSObject
    private unowned let device: WebGPURenderDevice
    private let functions = WebGPUEncoderFunctions.render
    /// The pass's attachments, which pick each pipeline's variant (nil: a depth-only pass).
    let format: WebGPUPassFormat?
    private let targetSize: (width: Int, height: Int)
    /// Set for the scene pass (`beginScreenPass`), the only one with occlusion queries.
    let occlusion: OcclusionQueryBatch?
    let bindings: WebGPUBindings
    private var pipeline: WebGPUPipeline?

    init(encoder: JSObject, device: WebGPURenderDevice, format: WebGPUPassFormat?, targetSize: (width: Int, height: Int),
         occlusion: OcclusionQueryBatch?) {
        self.encoder = encoder
        self.device = device
        self.format = format
        self.targetSize = targetSize
        self.occlusion = occlusion
        bindings = WebGPUBindings(device: device)
    }

    func setPipeline(_ pipeline: RenderPipeline) {
        let pipeline = pipeline as! WebGPUPipeline
        _ = functions.setPipeline(this: encoder, pipeline.object(for: format))
        self.pipeline = pipeline
    }

    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        let buffer = buffer as! WebGPUBuffer
        _ = functions.setVertexBuffer!(this: encoder, index, buffer.object, offset)
    }

    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        let (chunk, offset) = device.upload(bytes, alignment: 16)
        _ = functions.setVertexBuffer!(this: encoder, index, chunk.object, offset, max(bytes.count, 4))
    }

    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) {
        _ = functions.setIndexBuffer!(this: encoder, (buffer as! WebGPUBuffer).object, type.webGPU)
    }

    func setIndexData(_ bytes: UnsafeRawBufferPointer, type: IndexType) {
        let (chunk, offset) = device.upload(bytes, alignment: 16)
        _ = functions.setIndexBuffer!(this: encoder, chunk.object, type.webGPU, offset, roundUp(max(bytes.count, 4), 4))
    }

    func setScissorRect(_ rect: ScissorRect?) {
        let r = (rect ?? ScissorRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
            .clamped(toWidth: targetSize.width, height: targetSize.height)
        _ = functions.setScissorRect!(this: encoder, r.x, r.y, r.width, r.height)
    }

    /// The backend's own passes: draw into part of the target.
    func setViewport(x: Int, y: Int, width: Int, height: Int) {
        _ = functions.setViewport!(this: encoder, x, y, width, height, 0, 1)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxUniformDataSize, "Uniform data exceeds \(maxUniformDataSize) bytes")
        bindings.frameUniform = device.upload(bytes, alignment: uniformBufferOffsetAlignment)
    }

    func setTexture(_ texture: GPUTexture) {
        bindings.shadowMap = (texture as! WebGPUTexture)
    }

    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(offset % uniformBufferOffsetAlignment == 0, "Uniform buffer offset must be a multiple of \(uniformBufferOffsetAlignment)")
        bindings.uniforms[index] = (buffer as! WebGPUBuffer, offset)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(bytes.count <= maxUniformBufferSize, "Uniform data exceeds \(maxUniformBufferSize) bytes")
        bindings.uniforms[index] = device.upload(bytes, alignment: uniformBufferOffsetAlignment)
    }

    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Texture index \(index) is outside \(textureIndices)")
        bindings.textures[index] = (texture as! WebGPUTexture)
    }

    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Sampler index \(index) is outside \(textureIndices)")
        bindings.samplers[index] = (sampler as! WebGPUSampler)
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        bindings.pushConstants = device.upload(bytes, alignment: uniformBufferOffsetAlignment)
    }

    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        validateStorageBinding(buffer, offset: offset, index: index)
        bindings.storageBuffers[index] = (buffer as! WebGPUBuffer, offset)
    }

    /// Binds this frame's groups for the pipeline; every draw calls it.
    private func prepareDraw() {
        guard let pipeline else { preconditionFailure("draw without a pipeline") }
        bindings.apply(pipeline.layout, encoder: encoder, functions: functions)
    }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        prepareDraw()
        _ = functions.draw!(this: encoder, vertexCount, instanceCount, firstVertex, 0)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        prepareDraw()
        _ = functions.drawIndexed!(this: encoder, indexCount, instanceCount, firstIndex, 0, 0)
    }

    func drawIndirect(_ buffer: GPUBuffer, offset: Int) {
        prepareDraw()
        _ = functions.drawIndirect!(this: encoder, (buffer as! WebGPUBuffer).object, offset)
    }

    func drawIndexedIndirect(_ buffer: GPUBuffer, offset: Int) {
        prepareDraw()
        _ = functions.drawIndexedIndirect!(this: encoder, (buffer as! WebGPUBuffer).object, offset)
    }

    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.begin(set, index: index)
        if slot < webGPUMaxOcclusionQueries { _ = functions.beginOcclusionQuery!(this: encoder, slot) }
    }

    func endOcclusionQuery() {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        if occlusion.end() < webGPUMaxOcclusionQueries { _ = functions.endOcclusionQuery!(this: encoder) }
    }

    func end() {
        occlusion?.checkClosed()
        _ = functions.end(this: encoder)
    }
}

/// See `ComputePass`. WebGPU orders dispatches and passes and makes their writes visible itself.
final class WebGPUComputePass: ComputePass {
    let encoder: JSObject
    private unowned let device: WebGPURenderDevice
    private let functions = WebGPUEncoderFunctions.compute
    private let bindings: WebGPUBindings
    private var pipeline: WebGPUComputePipeline?

    init(encoder: JSObject, device: WebGPURenderDevice) {
        self.encoder = encoder
        self.device = device
        bindings = WebGPUBindings(device: device)
    }

    func setPipeline(_ pipeline: ComputePipeline) {
        let pipeline = pipeline as! WebGPUComputePipeline
        _ = functions.setPipeline(this: encoder, pipeline.object)
        self.pipeline = pipeline
    }

    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        validateStorageBinding(buffer, offset: offset, index: index)
        bindings.storageBuffers[index] = (buffer as! WebGPUBuffer, offset)
    }

    func setStorageTexture(_ texture: GPUTexture, index: Int) {
        precondition(storageTextureIndices.contains(index), "Storage texture index \(index) is outside \(storageTextureIndices)")
        bindings.storageTextures[index] = (texture as! WebGPUTexture)
    }

    func setTexture(_ texture: GPUTexture, index: Int) {
        precondition(textureIndices.contains(index), "Texture index \(index) is outside \(textureIndices)")
        bindings.textures[index] = (texture as! WebGPUTexture)
    }

    func setSampler(_ sampler: GPUSampler, index: Int) {
        precondition(textureIndices.contains(index), "Sampler index \(index) is outside \(textureIndices)")
        bindings.samplers[index] = (sampler as! WebGPUSampler)
    }

    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(offset % uniformBufferOffsetAlignment == 0, "Uniform buffer offset must be a multiple of \(uniformBufferOffsetAlignment)")
        bindings.uniforms[index] = (buffer as! WebGPUBuffer, offset)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(bytes.count <= maxUniformBufferSize, "Uniform data exceeds \(maxUniformBufferSize) bytes")
        bindings.uniforms[index] = device.upload(bytes, alignment: uniformBufferOffsetAlignment)
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        bindings.pushConstants = device.upload(bytes, alignment: uniformBufferOffsetAlignment)
    }

    func dispatch(groups: ComputeSize) {
        guard let pipeline else { preconditionFailure("dispatch without a compute pipeline") }
        guard groups.count > 0 else { return }
        bindings.apply(pipeline.layout, encoder: encoder, functions: functions)
        _ = functions.dispatchWorkgroups!(this: encoder, groups.x, groups.y, groups.z)
    }

    func dispatchIndirect(buffer: GPUBuffer, offset: Int) {
        guard let pipeline else { preconditionFailure("dispatch without a compute pipeline") }
        validateDispatchIndirect(buffer, offset: offset)
        bindings.apply(pipeline.layout, encoder: encoder, functions: functions)
        _ = functions.dispatchWorkgroupsIndirect!(this: encoder, (buffer as! WebGPUBuffer).object, offset)
    }

    func end() {
        _ = functions.end(this: encoder)
    }
}

extension IndexType {
    var webGPU: String { self == .uint16 ? "uint16" : "uint32" }
}
#endif
