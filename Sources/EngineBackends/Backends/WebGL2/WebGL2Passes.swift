#if canImport(JavaScriptKit)
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import JavaScriptKit
import EngineCore
import EngineGraphics

/// A render pass: what it has bound (the engine's slots), turned into WebGL 2 bindings at each
/// draw for the current program, as commands (`WebGL2Commands`). The device keeps what the
/// commands have bound so far (`WebGL2BindState`) and only records changes, so an unchanged
/// draw is its draw command alone.
final class WebGL2RenderPass: RenderPass {
    private unowned let device: WebGL2RenderDevice
    private let commands: WebGL2Commands
    /// The target's size in pixels.
    let size: (width: Int, height: Int)
    private let samples: Int
    /// Set for the scene pass (`beginScreenPass`), the only one with occlusion queries.
    let occlusion: OcclusionQueryBatch?
    let occlusionSet: Int32
    /// What `endPass` records: a multisample resolve (source and destination framebuffers).
    let resolve: (source: Int32, destination: Int32)?
    let timed: Bool

    private var pipeline: WebGL2Pipeline?
    private var pipelineRecorded = false
    /// Vertex buffers 0...2 (buffer, offset) and the index buffer.
    private var vertexBuffers: [(buffer: WebGL2Buffer, offset: Int)?] = [nil, nil, nil]
    private var indexBuffer: (buffer: WebGL2Buffer, type: Int32, size: Int, offset: Int)?
    // Bindings by engine slot.
    var frameUniform: (buffer: WebGL2Buffer, offset: Int)?
    var pushConstants: (buffer: WebGL2Buffer, offset: Int)?
    var uniforms = [(buffer: WebGL2Buffer, offset: Int)?](repeating: nil, count: 8)
    /// Storage buffers 0...7, read as uniform blocks (binding points 8...15) by the stages that
    /// declare one there (the material graph templates' GLSL ES).
    var storageBuffers = [(buffer: WebGL2Buffer, offset: Int)?](repeating: nil, count: 8)
    var textures = [WebGL2Texture?](repeating: nil, count: 8)
    var samplers = [WebGL2Sampler?](repeating: nil, count: 8)
    var shadowMap: WebGL2Texture?
    /// The backend's own blit and upscale passes: an image and its sampler (set 1).
    var image: (texture: WebGL2Texture, sampler: WebGL2Sampler)?

    init(device: WebGL2RenderDevice, commands: WebGL2Commands, targetSize: (width: Int, height: Int), samples: Int,
         occlusion: OcclusionQueryBatch?, occlusionSet: Int32, resolve: (source: Int32, destination: Int32)?, timed: Bool) {
        self.device = device
        self.commands = commands
        size = targetSize
        self.samples = samples
        self.occlusion = occlusion
        self.occlusionSet = occlusionSet
        self.resolve = resolve
        self.timed = timed
    }

    func setPipeline(_ pipeline: RenderPipeline) {
        let pipeline = pipeline as! WebGL2Pipeline
        guard pipeline !== self.pipeline else { return }
        self.pipeline = pipeline
        pipelineRecorded = false
    }

    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        vertexBuffers[index] = (buffer as! WebGL2Buffer, offset)
    }

    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        vertexBuffers[index] = device.upload(bytes, alignment: 16)
    }

    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) {
        indexBuffer = (buffer as! WebGL2Buffer, type == .uint16 ? GL.unsignedShort : GL.unsignedInt, type.size, 0)
    }

    func setIndexData(_ bytes: UnsafeRawBufferPointer, type: IndexType) {
        let (chunk, offset) = device.uploadIndices(bytes)
        indexBuffer = (chunk, type == .uint16 ? GL.unsignedShort : GL.unsignedInt, type.size, offset)
    }

    /// Engine scissors have their origin at the top left of the image, and so do WebGL 2's here:
    /// the device's images have their top row at y = 0 (see `WebGL2RenderDevice`).
    func setScissorRect(_ rect: ScissorRect?) {
        guard let rect else {
            commands.op(WebGL2Op.scissor, 0, 0, 0, 0, 0)
            return
        }
        let r = rect.clamped(toWidth: size.width, height: size.height)
        commands.op(WebGL2Op.scissor, 1, Int32(r.x), Int32(r.y), Int32(r.width), Int32(r.height))
    }

    /// The backend's own passes: draw into part of the target.
    func setViewport(x: Int, y: Int, width: Int, height: Int) {
        commands.op(WebGL2Op.viewport, Int32(x), Int32(y), Int32(width), Int32(height))
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxUniformDataSize, "Uniform data exceeds \(maxUniformDataSize) bytes")
        frameUniform = device.upload(bytes, alignment: device.uniformAlignment)
    }

    func setTexture(_ texture: GPUTexture) {
        shadowMap = (texture as! WebGL2Texture)
    }

    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(offset % uniformBufferOffsetAlignment == 0, "Uniform buffer offset must be a multiple of \(uniformBufferOffsetAlignment)")
        uniforms[index] = (buffer as! WebGL2Buffer, offset)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(bytes.count <= maxUniformBufferSize, "Uniform data exceeds \(maxUniformBufferSize) bytes")
        uniforms[index] = device.upload(bytes, alignment: device.uniformAlignment)
    }

    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Texture index \(index) is outside \(textureIndices)")
        textures[index] = (texture as! WebGL2Texture)
    }

    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Sampler index \(index) is outside \(textureIndices)")
        samplers[index] = (sampler as! WebGL2Sampler)
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        pushConstants = device.upload(bytes, alignment: device.uniformAlignment)
    }

    /// WebGL 2 has no storage buffers (`RenderDevice.supportsStorageBuffers` is false): shaders
    /// that read them have no GLSL ES, except the material graph templates, whose GLSL ES reads
    /// storage buffer 0 as a uniform block (binding point 8 + index, at most
    /// `maxUniformBufferSize` bytes of it).
    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        validateStorageBinding(buffer, offset: offset, index: index)
        storageBuffers[index] = (buffer as! WebGL2Buffer, offset)
    }

    /// Records what the draw needs that isn't bound yet: the pipeline's state, its vertex array
    /// and attribute offsets, uniform ranges, textures and samplers.
    private func prepareDraw() -> Bool {
        guard let pipeline else { preconditionFailure("draw without a pipeline") }
        let state = device.bindState
        // Alpha-to-coverage does nothing on single-sample framebuffers: alpha-test instead.
        let program = samples == 1 ? pipeline.alphaTestProgram ?? pipeline.program : pipeline.program
        if !pipelineRecorded {
            let p = commands.append(17)
            p[0] = WebGL2Op.pipeline
            p[1] = program.id
            pipeline.state.withUnsafeBufferPointer { words in
                for i in 0..<15 { p[2 + i] = words[i] }
            }
            if samples == 1 { p[15] = 0 }
            pipelineRecorded = true
        }
        state.bindVertexArray(layout: pipeline.layout, buffers: vertexBuffers, index: indexBuffer?.buffer, commands: commands)
        for block in program.uniformBlocks {
            let bound: (buffer: WebGL2Buffer, offset: Int)? = switch block.point {
            case 0: frameUniform
            case 1: pushConstants
            case 8...15: storageBuffers[Int(block.point) - 8]
            default: uniforms[Int(block.point)]
            }
            let (buffer, offset) = bound ?? (device.placeholderUniform!, 0)
            let size = min(block.size, buffer.allocatedLength - offset)
            state.bindUniform(point: block.point, buffer: buffer.id, offset: Int32(offset), size: Int32(size), commands: commands)
        }
        for sampler in program.samplers {
            var texture: WebGL2Texture
            var object: WebGL2Sampler
            if sampler.texture == 0 {
                if sampler.shadow {
                    texture = shadowMap ?? device.placeholderDepth
                    object = device.comparisonSampler
                } else {
                    texture = image?.texture ?? shadowMap ?? device.placeholderColor
                    object = image?.sampler ?? device.linearSampler
                }
            } else {
                texture = textures[sampler.texture] ?? device.placeholderColor
                object = sampler.sampler.flatMap { samplers[$0] } ?? device.linearSampler
                if sampler.shadow { object = device.comparisonSampler }
            }
            // Depth (and 32-bit float) textures can't be filtered: they are read with texelFetch, and
            // a filtering sampler would make them incomplete.
            if !sampler.shadow, texture.format == .depth32Float || texture.format == .r32Float { object = device.pointSampler }
            if sampler.shadow, texture.format != .depth32Float { texture = device.placeholderDepth }
            state.bindTexture(unit: sampler.unit, texture: texture.id, sampler: object.id, commands: commands)
        }
        return true
    }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        guard vertexCount > 0, instanceCount > 0, prepareDraw() else { return }
        commands.op(WebGL2Op.draw, Int32(firstVertex), Int32(vertexCount), Int32(instanceCount))
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        guard indexCount > 0, instanceCount > 0, let index = indexBuffer else { return }
        guard prepareDraw() else { return }
        commands.op(WebGL2Op.drawIndexed, Int32(indexCount), index.type, Int32(index.offset + firstIndex * index.size), Int32(instanceCount))
    }

    /// WebGL 2 has no indirect draws (the arguments live in GPU memory a compute pass wrote, and
    /// there is no compute): skipped, with one warning.
    func drawIndirect(_ buffer: GPUBuffer, offset: Int) {
        device.warnOnce("drawIndirect", "WebGL 2 has no indirect draws: skipped")
    }

    func drawIndexedIndirect(_ buffer: GPUBuffer, offset: Int) {
        device.warnOnce("drawIndirect", "WebGL 2 has no indirect draws: skipped")
    }

    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.begin(set, index: index)
        commands.op(WebGL2Op.beginQuery, occlusionSet, Int32(slot))
    }

    func endOcclusionQuery() {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        _ = occlusion.end()
        commands.op(WebGL2Op.endQuery)
    }

    func end() {
        occlusion?.checkClosed()
    }
}

/// What the recorded commands have bound so far (vertex array and its attribute offsets, uniform
/// ranges, textures and samplers per unit), so draws only record changes. Valid across passes
/// and frames: Web/webgl2.js's direct calls leave these bindings alone.
@MainActor final class WebGL2BindState {
    /// A vertex array per layout and buffers, with the offsets its attributes point at now.
    @MainActor final class VertexArray {
        let id = WebGL2IDs.make()
        var offsets: [Int] = [-1, -1, -1]
    }

    struct VertexArrayKey: Hashable {
        var layout: Int
        var buffer0: Int32, buffer1: Int32, buffer2: Int32, index: Int32
    }

    private var vertexArrays: [VertexArrayKey: VertexArray] = [:]
    private var currentKey: VertexArrayKey?
    private var current: VertexArray?
    private var uniforms = [(buffer: Int32, offset: Int32, size: Int32)](repeating: (0, 0, 0), count: 16)
    private var units = [(texture: Int32, sampler: Int32)](repeating: (0, 0), count: 32)

    /// Forget everything (after Web/webgl2.js changed bindings itself).
    func reset() {
        currentKey = nil
        current = nil
        for i in uniforms.indices { uniforms[i] = (0, 0, 0) }
        for i in units.indices { units[i] = (0, 0) }
    }

    func bindVertexArray(layout: WebGL2VertexLayout, buffers: [(buffer: WebGL2Buffer, offset: Int)?], index: WebGL2Buffer?,
                         commands: WebGL2Commands) {
        // Only the slots the layout reads (a buffer left bound in another slot doesn't matter).
        func id(_ slot: Int) -> Int32 { layout.slots[slot].attributes.isEmpty ? 0 : buffers[slot]?.buffer.id ?? 0 }
        let key = VertexArrayKey(layout: layout.id, buffer0: id(0), buffer1: id(1), buffer2: id(2), index: index?.id ?? 0)
        let vertexArray: VertexArray
        if let current, key == currentKey {
            vertexArray = current
        } else if let cached = vertexArrays[key] {
            vertexArray = cached
            commands.op(WebGL2Op.vao, cached.id)
        } else {
            // Vertex arrays of deleted buffers pile up (ids aren't reused): start over now and then.
            if vertexArrays.count >= 2048 {
                for old in vertexArrays.values { webGL2PendingDeletes.append(old.id) }
                vertexArrays.removeAll(keepingCapacity: true)
            }
            vertexArray = VertexArray()
            vertexArrays[key] = vertexArray
            commands.op(WebGL2Op.createVAO, vertexArray.id)
            if let index { commands.op(WebGL2Op.index, index.id) }
        }
        currentKey = key
        current = vertexArray
        for slot in 0..<3 {
            let attributes = layout.slots[slot]
            guard !attributes.attributes.isEmpty, let bound = buffers[slot], vertexArray.offsets[slot] != bound.offset else { continue }
            vertexArray.offsets[slot] = bound.offset
            for attribute in attributes.attributes {
                commands.op(WebGL2Op.attrib, attribute.location, bound.buffer.id, attribute.size, attributes.stride,
                            Int32(bound.offset + attribute.offset), attributes.divisor)
            }
        }
    }

    func bindUniform(point: Int32, buffer: Int32, offset: Int32, size: Int32, commands: WebGL2Commands) {
        let bound = uniforms[Int(point)]
        guard bound.buffer != buffer || bound.offset != offset || bound.size != size else { return }
        uniforms[Int(point)] = (buffer, offset, size)
        commands.op(WebGL2Op.ubo, point, buffer, offset, size)
    }

    func bindTexture(unit: Int32, texture: Int32, sampler: Int32, commands: WebGL2Commands) {
        let bound = units[Int(unit)]
        guard bound.texture != texture || bound.sampler != sampler else { return }
        units[Int(unit)] = (texture, sampler)
        commands.op(WebGL2Op.texture, unit, texture, sampler)
    }
}

/// WebGL 2 has no compute: `beginComputePass` hands out this pass, which records nothing (the
/// systems that compute check `RenderDevice.supportsCompute` first).
final class WebGL2ComputePass: ComputePass {
    func setPipeline(_ pipeline: ComputePipeline) {}
    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {}
    func setStorageTexture(_ texture: GPUTexture, index: Int) {}
    func setTexture(_ texture: GPUTexture, index: Int) {}
    func setSampler(_ sampler: GPUSampler, index: Int) {}
    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {}
    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int) {}
    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {}
    func dispatch(groups: ComputeSize) {}
    func dispatchIndirect(buffer: GPUBuffer, offset: Int) {}
}
#endif
