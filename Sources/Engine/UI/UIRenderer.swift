import Foundation

/// Draws a `UIDrawList` into the window pass: one vertex and one index upload, then one
/// indexed draw per batch with the batch's texture, sampler and scissor.
@MainActor
final class UIRenderer {
    private let pipeline: RenderPipeline
    private let whiteTexture: GPUTexture
    private let defaultSampler: GPUSampler

    init(device: RenderDevice) throws {
        var descriptor = PipelineDescriptor(
            shader: try ShaderSource.load(named: "ui", bundle: .module), vertexLayout: UIVertex.layout)
        descriptor.cullMode = .none
        descriptor.depthTest = false
        descriptor.depthWrite = false
        descriptor.alphaBlending = true
        pipeline = try device.makePipeline(descriptor)
        whiteTexture = try device.makeTexture(
            pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm, generateMipmaps: false)
        defaultSampler = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .clampToEdge))
    }

    func render(_ list: UIDrawList, into pass: RenderPass) {
        guard !list.batches.isEmpty else { return }
        pass.setPipeline(pipeline)
        pass.setPushConstants(Vec2(Float(list.framebufferSize.width), Float(list.framebufferSize.height)))
        pass.setVertexData(list.vertices)
        pass.setIndexData(list.indices)

        var clip: UIPixelRect?
        var texture: GPUTexture?
        var sampler: GPUSampler?
        for batch in list.batches {
            if clip != batch.clip {
                pass.setScissorRect(batch.clip.scissor)
                clip = batch.clip
            }
            let batchTexture = batch.texture ?? whiteTexture
            if texture !== batchTexture {
                pass.setTexture(batchTexture, index: 1)
                texture = batchTexture
            }
            let batchSampler = batch.sampler ?? defaultSampler
            if sampler !== batchSampler {
                pass.setSampler(batchSampler, index: 1)
                sampler = batchSampler
            }
            pass.drawIndexed(indexCount: batch.indexCount, instanceCount: 1, firstIndex: batch.firstIndex)
        }
        pass.setScissorRect(nil)
    }
}
