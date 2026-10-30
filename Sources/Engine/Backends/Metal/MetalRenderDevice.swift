#if canImport(Metal) && canImport(AppKit)
import Foundation
import Metal
import QuartzCore

// MSL buffer indices; see `RenderPass` for the full binding table.
let metalInstanceBufferIndex = 1
let metalUniformBufferIndex = 15
let metalPushConstantIndex = 16
private let maxFramesInFlight = 3
private let screenDepthFormat = MTLPixelFormat.depth32Float

final class MetalBuffer: GPUBuffer {
    let buffer: MTLBuffer
    var length: Int { buffer.length }
    init(_ buffer: MTLBuffer) { self.buffer = buffer }
}

final class MetalTexture: GPUTexture {
    let texture: MTLTexture
    let format: TextureFormat
    var width: Int { texture.width }
    var height: Int { texture.height }

    init(_ texture: MTLTexture, format: TextureFormat) {
        self.texture = texture
        self.format = format
    }
}

final class MetalPipeline: RenderPipeline {
    let state: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let cullMode: MTLCullMode
    let depthBias: DepthBias?

    init(state: MTLRenderPipelineState, depthState: MTLDepthStencilState, cullMode: MTLCullMode, depthBias: DepthBias?) {
        self.state = state
        self.depthState = depthState
        self.cullMode = cullMode
        self.depthBias = depthBias
    }
}

final class MetalRenderDevice: RenderDevice {
    let backend = GraphicsBackend.metal
    let device: MTLDevice
    let sampleCount: Int
    let maxTextureSize: Int
    var captureNextFrame = false
    var deviceName: String { device.name }
    var gpuFrameTime: Double? { lastGPUTime.get() }

    private let queue: MTLCommandQueue
    private let layer: CAMetalLayer
    private let comparisonSampler: MTLSamplerState
    private let linearSampler: MTLSamplerState
    private var blitPipeline: MetalPipeline!
    private let frameSemaphore = DispatchSemaphore(value: maxFramesInFlight)
    private let lastGPUTime = LockedValue<Double?>(nil)
    // One transient ring per frame in flight; the semaphore guarantees the GPU is done
    // with ring N when frame N + maxFramesInFlight begins.
    private var transientRings: [TransientRing<MetalBuffer>] = []
    /// Per frame slot: the screen pass's visibility-result buffer (8 bytes per query) and
    /// which query sets its entries belong to. Same reuse guarantee as `transientRings`.
    private var occlusionResults: [MTLBuffer] = []
    private var occlusionBatches: [OcclusionQueryBatch] = []
    private var frameNumber = 0
    private var screenTargets: (color: MTLTexture?, depth: MTLTexture)?
    /// Scene targets at the render size when it differs from the window (see `RenderResolution`).
    private var sceneTargets: SceneTargets?

    private struct SceneTargets {
        var color: MTLTexture?  // multisampled, memoryless
        var depth: MTLTexture
        /// Single-sample result: sampled by the window pass and read back for screenshots.
        var resolved: MTLTexture
    }

    private var frame: (commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable, ring: TransientRing<MetalBuffer>,
                        slot: Int, capture: Bool, offscreen: Bool, windowSize: (width: Int, height: Int))?
    private var currentPass: MetalRenderPass?

    init(layer: CAMetalLayer, sampleCount requestedSamples: Int) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw GraphicsError("No Metal device available") }
        guard let queue = device.makeCommandQueue() else { throw GraphicsError("Failed to create Metal command queue") }
        self.device = device
        self.queue = queue
        self.layer = layer
        sampleCount = [8, 4, 2, 1].first { $0 <= requestedSamples && device.supportsTextureSampleCount($0) } ?? 1
        maxTextureSize = Self.maxTextureSize(device)
        layer.device = device
        layer.pixelFormat = .bgra8Unorm_srgb
        layer.framebufferOnly = true

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.compareFunction = .lessEqual
        samplerDescriptor.sAddressMode = .clampToBorderColor
        samplerDescriptor.tAddressMode = .clampToBorderColor
        samplerDescriptor.borderColor = .opaqueWhite
        guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw GraphicsError("Failed to create comparison sampler")
        }
        comparisonSampler = sampler

        let linearDescriptor = MTLSamplerDescriptor()
        linearDescriptor.minFilter = .linear
        linearDescriptor.magFilter = .linear
        linearDescriptor.sAddressMode = .clampToEdge
        linearDescriptor.tAddressMode = .clampToEdge
        guard let linear = device.makeSamplerState(descriptor: linearDescriptor) else {
            throw GraphicsError("Failed to create linear sampler")
        }
        linearSampler = linear

        transientRings = (0..<maxFramesInFlight).map { _ in
            TransientRing { size in
                guard let buffer = device.makeBuffer(length: size, options: .storageModeShared) else {
                    throw GraphicsError("Failed to allocate \(size) bytes of transient memory")
                }
                return (MetalBuffer(buffer), buffer.contents())
            }
        }

        for _ in 0..<maxFramesInFlight {
            let length = maxOcclusionQueriesPerFrame * MemoryLayout<UInt64>.size
            guard let buffer = device.makeBuffer(length: length, options: .storageModeShared) else {
                throw GraphicsError("Failed to allocate the occlusion query buffer")
            }
            memset(buffer.contents(), 0, length)
            occlusionResults.append(buffer)
            occlusionBatches.append(OcclusionQueryBatch())
        }

        var blit = PipelineDescriptor(shader: try ShaderSource.load(named: "blit", bundle: .module), vertexLayout: .none)
        blit.cullMode = .none
        blit.depthTest = false
        blit.depthWrite = false
        blitPipeline = try makePipeline(blit) as? MetalPipeline
    }

    /// Metal has no query for this; values from the Metal feature set tables (exceeding it
    /// asserts in validation rather than failing gracefully).
    private static func maxTextureSize(_ device: MTLDevice) -> Int {
        if #available(macOS 26.0, *), device.supportsFamily(.apple10) { return 32768 }
        return device.supportsFamily(.apple3) || device.supportsFamily(.mac2) ? 16384 : 8192
    }

    // MARK: - Resources

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard let base = bytes.baseAddress, bytes.count > 0,
              let buffer = device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        else { throw GraphicsError("Failed to create Metal buffer of \(bytes.count) bytes") }
        return MetalBuffer(buffer)
    }

    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float, width: descriptor.width, height: descriptor.height, mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw GraphicsError("Failed to create \(descriptor.width)x\(descriptor.height) texture")
        }
        return MetalTexture(texture, format: descriptor.format)
    }

    func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        guard let source = descriptor.shader.metalSource else {
            throw GraphicsError("Shader has no Metal source")
        }
        let library = try device.makeLibrary(source: source, options: nil)
        guard let vertexFunction = library.makeFunction(name: "vertex_main") else {
            throw GraphicsError("Metal shader must define vertex_main")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.vertexDescriptor = Self.vertexDescriptor(descriptor)

        switch descriptor.target {
        case .screen:
            guard let fragmentFunction = library.makeFunction(name: "fragment_main") else {
                throw GraphicsError("Metal shader must define fragment_main")
            }
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.depthAttachmentPixelFormat = screenDepthFormat
            pipelineDescriptor.rasterSampleCount = sampleCount
            let color = pipelineDescriptor.colorAttachments[0]!
            color.pixelFormat = layer.pixelFormat
            color.writeMask = descriptor.colorWrites ? .all : []
            if descriptor.alphaBlending {
                color.isBlendingEnabled = true
                color.sourceRGBBlendFactor = .sourceAlpha
                color.destinationRGBBlendFactor = .oneMinusSourceAlpha
                color.sourceAlphaBlendFactor = .one
                color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
        case .depthOnly:
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            pipelineDescriptor.rasterSampleCount = 1
        }
        let state = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = descriptor.depthTest ? descriptor.depthCompare.metal : .always
        depthDescriptor.isDepthWriteEnabled = descriptor.depthWrite
        guard let depthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            throw GraphicsError("Failed to create depth-stencil state")
        }

        let cull: MTLCullMode = switch descriptor.cullMode {
        case .none: .none
        case .front: .front
        case .back: .back
        }
        return MetalPipeline(state: state, depthState: depthState, cullMode: cull, depthBias: descriptor.depthBias)
    }

    func uploadTransient(_ bytes: UnsafeRawBufferPointer) -> TransientBuffer {
        guard let frame else { preconditionFailure("uploadTransient outside a frame") }
        do {
            let allocation = try frame.ring.upload(bytes, alignment: 16)
            return TransientBuffer(buffer: allocation.chunk, offset: allocation.offset, length: bytes.count)
        } catch {
            preconditionFailure("\(error)")
        }
    }

    private static func vertexDescriptor(_ descriptor: PipelineDescriptor) -> MTLVertexDescriptor? {
        let layouts = [(descriptor.vertexLayout, 0), (descriptor.instanceLayout ?? .none, metalInstanceBufferIndex)]
        guard layouts.contains(where: { !$0.0.attributes.isEmpty }) else { return nil }
        let vertexDescriptor = MTLVertexDescriptor()
        for (layout, bufferIndex) in layouts where !layout.attributes.isEmpty {
            for attribute in layout.attributes {
                vertexDescriptor.attributes[attribute.location].format = attribute.format.metal
                vertexDescriptor.attributes[attribute.location].offset = attribute.offset
                vertexDescriptor.attributes[attribute.location].bufferIndex = bufferIndex
            }
            vertexDescriptor.layouts[bufferIndex].stride = layout.stride
            vertexDescriptor.layouts[bufferIndex].stepFunction = bufferIndex == 0 ? .perVertex : .perInstance
        }
        return vertexDescriptor
    }

    // MARK: - Frames

    func beginFrame(framebufferSize: (width: Int, height: Int), renderSize: (width: Int, height: Int)?) throws -> Bool {
        precondition(frame == nil, "beginFrame called twice without endFrame")
        guard framebufferSize.width > 0, framebufferSize.height > 0 else { return false }

        let size = CGSize(width: framebufferSize.width, height: framebufferSize.height)
        if layer.drawableSize != size { layer.drawableSize = size }
        // Reading the drawable back requires a non-framebuffer-only layer.
        let capture = captureNextFrame
        captureNextFrame = false
        layer.framebufferOnly = !(capture && renderSize == nil)

        frameSemaphore.wait()
        guard let drawable = layer.nextDrawable(), let commandBuffer = queue.makeCommandBuffer() else {
            frameSemaphore.signal()
            return false
        }
        let semaphore = frameSemaphore
        let gpuTime = lastGPUTime
        commandBuffer.addCompletedHandler { commandBuffer in
            if commandBuffer.gpuEndTime > commandBuffer.gpuStartTime {
                gpuTime.set(commandBuffer.gpuEndTime - commandBuffer.gpuStartTime)
            }
            semaphore.signal()
        }

        let slot = frameNumber % maxFramesInFlight
        let ring = transientRings[slot]
        ring.reset()
        resolveOcclusionQueries(slot: slot)
        frameNumber += 1
        try ensureScreenTargets(width: framebufferSize.width, height: framebufferSize.height)
        if let renderSize {
            try ensureSceneTargets(width: renderSize.width, height: renderSize.height)
        } else {
            sceneTargets = nil
        }
        frame = (commandBuffer, drawable, ring, slot, capture, renderSize != nil, framebufferSize)
        return true
    }

    /// Hands the slot's previous results to their query sets and clears what they used.
    private func resolveOcclusionQueries(slot: Int) {
        let batch = occlusionBatches[slot]
        let used = batch.count
        guard used > 0 else { return }
        let results = occlusionResults[slot].contents().assumingMemoryBound(to: UInt64.self)
        batch.resolve { results[$0] != 0 }
        memset(results, 0, used * MemoryLayout<UInt64>.size)
    }

    func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.depthAttachment.texture = (target as! MetalTexture).texture
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.clearDepth = Double(clearDepth)
        return beginPass(passDescriptor)
    }

    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginScreenPass outside a frame") }
        let descriptor = if frame.offscreen, let scene = sceneTargets {
            Self.colorDepthPass(
                msaa: scene.color, target: scene.resolved, depth: scene.depth, clearColor: clearColor, clearDepth: clearDepth)
        } else {
            Self.colorDepthPass(
                msaa: targets.color, target: frame.drawable.texture, depth: targets.depth, clearColor: clearColor, clearDepth: clearDepth)
        }
        descriptor.visibilityResultBuffer = occlusionResults[frame.slot]
        return beginPass(descriptor, occlusion: occlusionBatches[frame.slot])
    }

    func beginWindowPass() -> RenderPass {
        guard let frame, let targets = screenTargets else { preconditionFailure("beginWindowPass outside a frame") }
        guard frame.offscreen, let scene = sceneTargets else {
            guard let currentPass else { preconditionFailure("beginWindowPass must follow beginScreenPass") }
            return currentPass
        }
        endPass()
        let pass = beginPass(Self.colorDepthPass(
            msaa: targets.color, target: frame.drawable.texture, depth: targets.depth, clearColor: Vec4(0, 0, 0, 1), clearDepth: 1))
        let metalPass = pass as! MetalRenderPass
        metalPass.setPipeline(blitPipeline)
        metalPass.encoder.setFragmentTexture(scene.resolved, index: 0)
        metalPass.encoder.setFragmentSamplerState(linearSampler, index: 0)
        metalPass.setPushConstants(letterboxScale(image: (scene.resolved.width, scene.resolved.height), window: frame.windowSize))
        metalPass.draw(vertexCount: 3)
        return pass
    }

    /// Color (resolved from `msaa` when multisampled) + depth, both cleared.
    private static func colorDepthPass(msaa: MTLTexture?, target: MTLTexture, depth: MTLTexture,
                                       clearColor: Vec4, clearDepth: Float) -> MTLRenderPassDescriptor {
        let passDescriptor = MTLRenderPassDescriptor()
        let color = passDescriptor.colorAttachments[0]!
        if let msaa {
            color.texture = msaa
            color.resolveTexture = target
            color.storeAction = .multisampleResolve
        } else {
            color.texture = target
            color.storeAction = .store
        }
        color.loadAction = .clear
        color.clearColor = MTLClearColor(
            red: Double(clearColor.x), green: Double(clearColor.y), blue: Double(clearColor.z), alpha: Double(clearColor.w))
        passDescriptor.depthAttachment.texture = depth
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .dontCare
        passDescriptor.depthAttachment.clearDepth = Double(clearDepth)
        return passDescriptor
    }

    private func beginPass(_ descriptor: MTLRenderPassDescriptor, occlusion: OcclusionQueryBatch? = nil) -> RenderPass {
        guard let frame else { preconditionFailure("Render pass started outside a frame") }
        precondition(currentPass == nil, "Previous pass was not ended")
        guard let encoder = frame.commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            preconditionFailure("Failed to create Metal render encoder")
        }
        let pass = MetalRenderPass(
            encoder: encoder, transient: frame.ring, comparisonSampler: comparisonSampler, occlusion: occlusion)
        currentPass = pass
        return pass
    }

    func endPass() {
        currentPass?.occlusion?.checkClosed()
        currentPass?.encoder.endEncoding()
        currentPass = nil
    }

    func endFrame() throws -> Image? {
        guard let frame else { return nil }
        endPass()
        self.frame = nil

        var readback: (buffer: MTLBuffer, width: Int, height: Int)?
        if frame.capture {
            let texture = frame.offscreen ? sceneTargets!.resolved : frame.drawable.texture
            let bytesPerRow = texture.width * 4
            if let buffer = device.makeBuffer(length: bytesPerRow * texture.height, options: .storageModeShared),
               let blit = frame.commandBuffer.makeBlitCommandEncoder() {
                blit.copy(
                    from: texture, sourceSlice: 0, sourceLevel: 0,
                    sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                    sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
                    to: buffer, destinationOffset: 0,
                    destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * texture.height)
                blit.endEncoding()
                readback = (buffer, texture.width, texture.height)
            }
        }

        frame.commandBuffer.present(frame.drawable)
        frame.commandBuffer.commit()

        guard let readback else { return nil }
        frame.commandBuffer.waitUntilCompleted()
        let bytes = UnsafeRawBufferPointer(start: readback.buffer.contents(), count: readback.buffer.length)
        return Image(width: readback.width, height: readback.height, bgra: bytes, bytesPerRow: readback.width * 4)
    }

    func waitIdle() {
        // Commit an empty command buffer and wait: the queue executes in order.
        let commandBuffer = queue.makeCommandBuffer()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }

    func shutdown() {}

    /// Multisampled color (when MSAA is on) and depth matching the drawable size.
    private func ensureScreenTargets(width: Int, height: Int) throws {
        if let targets = screenTargets, targets.depth.width == width, targets.depth.height == height { return }
        screenTargets = (sampleCount > 1 ? try makeAttachment(layer.pixelFormat, width, height) : nil,
                         try makeAttachment(screenDepthFormat, width, height))
    }

    /// Offscreen scene targets at the render size.
    private func ensureSceneTargets(width: Int, height: Int) throws {
        if let targets = sceneTargets, targets.resolved.width == width, targets.resolved.height == height { return }
        sceneTargets = nil  // free the old ones before allocating (they can be huge)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: layer.pixelFormat, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let resolved = device.makeTexture(descriptor: descriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        sceneTargets = SceneTargets(
            color: sampleCount > 1 ? try makeAttachment(layer.pixelFormat, width, height) : nil,
            depth: try makeAttachment(screenDepthFormat, width, height),
            resolved: resolved)
    }

    /// A screen-pass attachment that is never stored (multisampled when MSAA is on).
    private func makeAttachment(_ format: MTLPixelFormat, _ width: Int, _ height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: format, width: width, height: height, mipmapped: false)
        descriptor.usage = .renderTarget
        // Tile memory is enough for attachments that are never stored (Apple GPUs only).
        descriptor.storageMode = device.supportsFamily(.apple1) ? .memoryless : .private
        if sampleCount > 1 {
            descriptor.textureType = .type2DMultisample
            descriptor.sampleCount = sampleCount
        }
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw GraphicsError("Failed to create \(width)x\(height) render target")
        }
        return texture
    }
}

final class MetalRenderPass: RenderPass {
    let encoder: MTLRenderCommandEncoder
    private let transient: TransientRing<MetalBuffer>
    private let comparisonSampler: MTLSamplerState
    private var indexBuffer: (buffer: MTLBuffer, type: IndexType)?
    /// Set for passes with a visibility-result buffer (the screen pass).
    let occlusion: OcclusionQueryBatch?

    init(encoder: MTLRenderCommandEncoder, transient: TransientRing<MetalBuffer>, comparisonSampler: MTLSamplerState,
         occlusion: OcclusionQueryBatch?) {
        self.encoder = encoder
        self.transient = transient
        self.comparisonSampler = comparisonSampler
        self.occlusion = occlusion
        encoder.setFrontFacing(.counterClockwise)
    }

    func setPipeline(_ pipeline: RenderPipeline) {
        let pipeline = pipeline as! MetalPipeline
        encoder.setRenderPipelineState(pipeline.state)
        encoder.setDepthStencilState(pipeline.depthState)
        encoder.setCullMode(pipeline.cullMode)
        let bias = pipeline.depthBias ?? DepthBias(constant: 0, slopeScale: 0)
        encoder.setDepthBias(bias.constant, slopeScale: bias.slopeScale, clamp: 0)
    }

    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        encoder.setVertexBuffer((buffer as! MetalBuffer).buffer, offset: offset, index: index)
    }

    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        let allocation = upload(bytes, alignment: 16)
        encoder.setVertexBuffer(allocation.chunk.buffer, offset: allocation.offset, index: index)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxUniformDataSize, "Uniform data exceeds \(maxUniformDataSize) bytes")
        let allocation = upload(bytes, alignment: 256)
        encoder.setVertexBuffer(allocation.chunk.buffer, offset: allocation.offset, index: metalUniformBufferIndex)
        encoder.setFragmentBuffer(allocation.chunk.buffer, offset: allocation.offset, index: metalUniformBufferIndex)
    }

    func setTexture(_ texture: GPUTexture) {
        encoder.setFragmentTexture((texture as! MetalTexture).texture, index: 0)
        encoder.setFragmentSamplerState(comparisonSampler, index: 0)
    }

    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) {
        indexBuffer = ((buffer as! MetalBuffer).buffer, type)
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        guard let base = bytes.baseAddress else { return }
        encoder.setVertexBytes(base, length: bytes.count, index: metalPushConstantIndex)
        encoder.setFragmentBytes(base, length: bytes.count, index: metalPushConstantIndex)
    }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        encoder.drawPrimitives(
            type: .triangle, vertexStart: firstVertex, vertexCount: vertexCount, instanceCount: instanceCount)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        guard let (buffer, type) = indexBuffer else { preconditionFailure("drawIndexed without an index buffer") }
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: indexCount,
            indexType: type == .uint16 ? .uint16 : .uint32,
            indexBuffer: buffer,
            indexBufferOffset: firstIndex * type.size,
            instanceCount: instanceCount)
    }

    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.begin(set, index: index)
        encoder.setVisibilityResultMode(.boolean, offset: slot * MemoryLayout<UInt64>.size)
    }

    func endOcclusionQuery() {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        _ = occlusion.end()
        encoder.setVisibilityResultMode(.disabled, offset: 0)
    }

    private func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int) -> TransientRing<MetalBuffer>.Allocation {
        do {
            return try transient.upload(bytes, alignment: alignment)
        } catch {
            preconditionFailure("\(error)")
        }
    }
}

private extension VertexFormat {
    var metal: MTLVertexFormat {
        switch self {
        case .float: .float
        case .float2: .float2
        case .float3: .float3
        case .float4: .float4
        }
    }
}

private extension CompareFunction {
    var metal: MTLCompareFunction {
        switch self {
        case .never: .never
        case .less: .less
        case .lessEqual: .lessEqual
        case .equal: .equal
        case .greater: .greater
        case .greaterEqual: .greaterEqual
        case .always: .always
        }
    }
}
#endif
