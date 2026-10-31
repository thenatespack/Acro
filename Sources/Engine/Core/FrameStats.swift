/// Timing and workload numbers for the most recent frame (all times in seconds).
public struct FrameStats: Sendable {
    /// Wall-clock time between the starts of the last two frames.
    public var frameTime: Double = 0
    /// Frames per second, averaged over the last ~0.5 s.
    public var fps: Double = 0
    /// CPU time spent in `Game.update`.
    public var updateTime: Double = 0
    /// CPU time spent in `Game.render` (command recording).
    public var renderTime: Double = 0
    /// GPU execution time of a recently completed frame, when the backend supports it.
    public var gpuTime: Double?
    /// That frame's GPU time per pass, in recording order (empty when unsupported).
    public var gpuPassTimes: [GPUPassTime] = []
    /// Draw calls and triangles submitted by the game in all passes (excludes the debug overlay).
    public var drawCalls = 0
    public var triangles = 0
    /// Descriptor pools allocated so far (`RenderDevice.descriptorPoolCount`; Vulkan only).
    public var descriptorPools: Int?

    public init() {}
}

/// Wraps the backend pass handed to `Game.render` to count draws.
@MainActor
final class CountingRenderPass: RenderPass {
    var inner: RenderPass!
    private(set) var drawCalls = 0
    private(set) var triangles = 0

    func resetCounts() {
        drawCalls = 0
        triangles = 0
    }

    func setPipeline(_ pipeline: RenderPipeline) { inner.setPipeline(pipeline) }
    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) { inner.setVertexBuffer(buffer, offset: offset, index: index) }
    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) { inner.setVertexData(bytes, index: index) }
    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) { inner.setIndexBuffer(buffer, type: type) }
    func setIndexData(_ bytes: UnsafeRawBufferPointer, type: IndexType) { inner.setIndexData(bytes, type: type) }
    func setScissorRect(_ rect: ScissorRect?) { inner.setScissorRect(rect) }
    func setUniformData(_ bytes: UnsafeRawBufferPointer) { inner.setUniformData(bytes) }
    func setTexture(_ texture: GPUTexture) { inner.setTexture(texture) }
    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        inner.setUniformBuffer(buffer, offset: offset, index: index, stage: stage)
    }
    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage) {
        inner.setUniformData(bytes, index: index, stage: stage)
    }
    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage) { inner.setTexture(texture, index: index, stage: stage) }
    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage) { inner.setSampler(sampler, index: index, stage: stage) }
    func setPushConstants(_ bytes: UnsafeRawBufferPointer) { inner.setPushConstants(bytes) }
    func setStorageBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        inner.setStorageBuffer(buffer, offset: offset, index: index, stage: stage)
    }
    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) { inner.beginOcclusionQuery(set, index: index) }
    func endOcclusionQuery() { inner.endOcclusionQuery() }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        drawCalls += 1
        triangles += vertexCount / 3 * instanceCount
        inner.draw(vertexCount: vertexCount, instanceCount: instanceCount, firstVertex: firstVertex)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        drawCalls += 1
        triangles += indexCount / 3 * instanceCount
        inner.drawIndexed(indexCount: indexCount, instanceCount: instanceCount, firstIndex: firstIndex)
    }

    /// Counts the call; the GPU decides the triangles, so they aren't counted.
    func drawIndirect(_ buffer: GPUBuffer, offset: Int) {
        drawCalls += 1
        inner.drawIndirect(buffer, offset: offset)
    }

    func drawIndexedIndirect(_ buffer: GPUBuffer, offset: Int) {
        drawCalls += 1
        inner.drawIndexedIndirect(buffer, offset: offset)
    }
}
