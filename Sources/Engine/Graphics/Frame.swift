import Foundation

/// Offscreen work for the current frame; passes run in the order they're recorded.
@MainActor
public final class Frame {
    private let device: RenderDevice
    private let counter: CountingRenderPass

    init(device: RenderDevice, counter: CountingRenderPass) {
        self.device = device
        self.counter = counter
    }

    /// Copies `elements` into transient memory once, for use by several passes this frame
    /// (e.g. instances drawn in both the shadow and the screen pass). Valid until the frame ends.
    public func upload<T: BitwiseCopyable>(_ elements: [T]) -> TransientBuffer {
        elements.withUnsafeBytes { device.uploadTransient($0) }
    }

    /// Replaces part of a static buffer's contents; later passes of this frame and all later
    /// frames see the new data. Call it between passes, not inside a pass body. See
    /// `RenderDevice.updateBuffer(_:offset:bytes:)` for the full semantics.
    public func updateBuffer<T: BitwiseCopyable>(_ buffer: GPUBuffer, offset: Int = 0, elements: [T]) throws {
        try device.updateBuffer(buffer, offset: offset, elements: elements)
    }

    /// Renders depth-only geometry into `target` (e.g. a shadow map). Pipelines used here
    /// must have `target: .depthOnly`.
    public func depthPass(into target: GPUTexture, clearDepth: Float = 1, _ body: (RenderPass) -> Void) {
        counter.inner = device.beginDepthPass(target: target, clearDepth: clearDepth)
        body(counter)
        device.endPass()
    }

    /// Renders into an offscreen color target (color and depth cleared first), timed under
    /// `target.label`. Pipelines used here must have `target: .screen`. Later passes of this
    /// frame, the window pass included, can sample `target.texture`.
    public func renderPass(into target: RenderTarget, clearColor: Vec4, clearDepth: Float = 1, _ body: (RenderPass) -> Void) {
        renderPass(into: target.gpu, clearColor: clearColor, clearDepth: clearDepth, label: target.label, body)
    }

    /// `renderPass(into:)` for a target made with `RenderDevice.makeRenderTarget`.
    public func renderPass(into target: GPURenderTarget, clearColor: Vec4, clearDepth: Float = 1, label: String = "target",
                           _ body: (RenderPass) -> Void) {
        counter.inner = device.beginPass(target: target, clearColor: clearColor, clearDepth: clearDepth, label: label)
        body(counter)
        device.endPass()
    }

    /// Records a compute pass (see `ComputePass`), timed under `label`. Passes recorded after
    /// it, this frame's screen pass included, see what it wrote.
    public func computePass(label: String = "compute", _ body: (ComputePass) -> Void) {
        let pass = device.beginComputePass(label: label)
        body(pass)
        device.endPass()
    }

    /// Copies part of `buffer` at this point of the frame and calls `completion` with the bytes
    /// once the GPU has finished the frame, without waiting for it (a few frames later, or in
    /// `device.waitIdle()`). See `RenderDevice.readBack(_:offset:length:completion:)`.
    public func readBack(_ buffer: GPUBuffer, offset: Int = 0, length: Int? = nil,
                         completion: @escaping @MainActor ([UInt8]) -> Void) {
        device.readBack(buffer, offset: offset, length: length ?? buffer.length - offset, completion: completion)
    }

    /// Reads `target` back once this frame's passes ran (call it after rendering into it):
    /// `completion` gets its pixels (RGBA8, top row first) when the frame ends, after the CPU
    /// waited for the GPU to finish the frame. For screenshots and tests.
    public func readBack(_ target: RenderTarget, completion: @escaping @MainActor (Image) -> Void) {
        device.readBack(target.gpu, completion: completion)
    }
}
