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
    /// Draw calls and triangles submitted by the game in all passes (excludes the debug overlay).
    public var drawCalls = 0
    public var triangles = 0

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
    func setUniformData(_ bytes: UnsafeRawBufferPointer) { inner.setUniformData(bytes) }
    func setTexture(_ texture: GPUTexture) { inner.setTexture(texture) }
    func setPushConstants(_ bytes: UnsafeRawBufferPointer) { inner.setPushConstants(bytes) }

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
}
