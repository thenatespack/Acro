#if ENGINE_VULKAN
import CVulkan
import Foundation

private let maxFramesInFlight = 2
private let depthFormat = VK_FORMAT_D32_SFLOAT
private let allStages = vkFlags(VK_SHADER_STAGE_VERTEX_BIT, VK_SHADER_STAGE_FRAGMENT_BIT)
/// Layout depth textures are kept in between passes (written as attachments, read as samplers).
private let depthReadLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL

final class VulkanBuffer: GPUBuffer {
    private let resource: VulkanResource
    private let deletionQueue: VulkanDeletionQueue
    let buffer: VkBuffer
    let memory: VkDeviceMemory
    let length: Int
    /// Persistently mapped (all buffers live in host-visible, coherent memory).
    let mapped: UnsafeMutableRawPointer

    init(buffer: VkBuffer, memory: VkDeviceMemory, length: Int, mapped: UnsafeMutableRawPointer, deletionQueue: VulkanDeletionQueue) {
        self.buffer = buffer
        self.memory = memory
        self.length = length
        self.mapped = mapped
        self.deletionQueue = deletionQueue
        resource = .buffer(buffer, memory)
        deletionQueue.register(resource)
    }

    deinit {
        deletionQueue.release(resource)
    }
}

final class VulkanTexture: GPUTexture {
    private let resource: VulkanResource
    private let deletionQueue: VulkanDeletionQueue
    let width: Int
    let height: Int
    let format: TextureFormat
    let framebuffer: VkFramebuffer
    /// Descriptor set 1 (combined image sampler) for sampling this texture.
    let descriptorSet: VkDescriptorSet

    init(width: Int, height: Int, format: TextureFormat, image: VkImage, memory: VkDeviceMemory, view: VkImageView,
         framebuffer: VkFramebuffer, descriptorSet: VkDescriptorSet, deletionQueue: VulkanDeletionQueue) {
        self.width = width
        self.height = height
        self.format = format
        self.framebuffer = framebuffer
        self.descriptorSet = descriptorSet
        self.deletionQueue = deletionQueue
        resource = .texture(image, memory, view, framebuffer, descriptorSet)
        deletionQueue.register(resource)
    }

    deinit {
        deletionQueue.release(resource)
    }
}

final class VulkanPipeline: RenderPipeline {
    private let resource: VulkanResource
    private let deletionQueue: VulkanDeletionQueue
    let pipeline: VkPipeline

    init(_ pipeline: VkPipeline, deletionQueue: VulkanDeletionQueue) {
        self.pipeline = pipeline
        self.deletionQueue = deletionQueue
        resource = .pipeline(pipeline)
        deletionQueue.register(resource)
    }

    deinit {
        deletionQueue.release(resource)
    }
}

/// A transient-ring chunk plus the dynamic-uniform descriptor set pointing at it.
final class VulkanTransientChunk {
    let buffer: VulkanBuffer
    let uniformSet: VkDescriptorSet

    init(buffer: VulkanBuffer, uniformSet: VkDescriptorSet) {
        self.buffer = buffer
        self.uniformSet = uniformSet
    }
}

private struct FrameSync {
    var commandBuffer: VkCommandBuffer
    var imageAvailable: VkSemaphore
    var inFlight: VkFence
    var transient: TransientRing<VulkanTransientChunk>
    /// Whether this slot's timestamp queries hold results from its previous submission.
    var timestampsWritten = false
}

private struct ImageAllocation {
    var image: VkImage
    var memory: VkDeviceMemory
    var view: VkImageView
}

private struct Swapchain {
    var handle: VkSwapchainKHR
    var extent: VkExtent2D
    var images: [VkImage]
    var views: [VkImageView]
    var framebuffers: [VkFramebuffer]
    /// One per swapchain image: presentation may still be using it after the frame's fence signals.
    var renderFinished: [VkSemaphore]
    var depth: ImageAllocation
    /// Multisampled color target resolved into the swapchain image (nil without MSAA).
    var msaaColor: ImageAllocation?
    var supportsReadback: Bool
}

final class VulkanRenderDevice: RenderDevice {
    let backend = GraphicsBackend.vulkan
    let deviceName: String
    let sampleCount: Int
    var captureNextFrame = false
    private(set) var gpuFrameTime: Double?

    private let instance: VkInstance
    private let surface: VkSurfaceKHR
    private let physicalDevice: VkPhysicalDevice
    private let device: VkDevice
    private let queue: VkQueue
    private let queueFamily: UInt32
    private let memoryProperties: VkPhysicalDeviceMemoryProperties
    private let surfaceFormat: VkSurfaceFormatKHR
    private let samples: VkSampleCountFlagBits
    private let screenRenderPass: VkRenderPass
    private let depthRenderPass: VkRenderPass
    private let uniformSetLayout: VkDescriptorSetLayout
    private let textureSetLayout: VkDescriptorSetLayout
    private let pipelineLayout: VkPipelineLayout
    private let descriptorPool: VkDescriptorPool
    private let comparisonSampler: VkSampler
    private let commandPool: VkCommandPool
    private var frames: [FrameSync] = []
    private var swapchain: Swapchain?
    private var frameIndex = 0
    private var needsSwapchainRebuild = false
    private var current: (imageIndex: UInt32, capture: Bool)?
    private var inRenderPass = false
    /// Serial of the frame currently being recorded (increments every submitted frame).
    private var frameSerial: UInt64 = 0
    private let deletionQueue = VulkanDeletionQueue()
    private var readbackBuffer: VulkanBuffer?
    /// Two timestamps (start, end) per frame slot; nil when the queue can't time.
    private var timestampPool: VkQueryPool?
    private var timestampPeriod: Double = 1

    init(window: GLFWWindow, applicationName: String, sampleCount requestedSamples: Int) throws {
        let instance = try Self.createInstance(applicationName: applicationName)
        let surface = try window.createSurface(instance: instance)
        self.instance = instance
        self.surface = surface

        let (physicalDevice, family) = try Self.pickPhysicalDevice(instance: instance, surface: surface)
        self.physicalDevice = physicalDevice
        queueFamily = family

        var properties = VkPhysicalDeviceProperties()
        vkGetPhysicalDeviceProperties(physicalDevice, &properties)
        deviceName = vkString(properties.deviceName)

        let supportedSamples = properties.limits.framebufferColorSampleCounts & properties.limits.framebufferDepthSampleCounts
        sampleCount = [8, 4, 2, 1].first { $0 <= requestedSamples && supportedSamples & VkFlags($0) != 0 } ?? 1
        samples = VkSampleCountFlagBits(rawValue: .init(sampleCount))

        let families: [VkQueueFamilyProperties] = vkEnumerate {
            vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, $0, $1)
        }
        let canTime = properties.limits.timestampComputeAndGraphics != 0 && families[Int(family)].timestampValidBits > 0
        timestampPeriod = Double(properties.limits.timestampPeriod)

        var memoryProperties = VkPhysicalDeviceMemoryProperties()
        vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memoryProperties)
        self.memoryProperties = memoryProperties

        let device = try Self.createDevice(physicalDevice: physicalDevice, queueFamily: family)
        self.device = device
        var queue: VkQueue?
        vkGetDeviceQueue(device, family, 0, &queue)
        self.queue = queue!

        let formats: [VkSurfaceFormatKHR] = try vkEnumerate("vkGetPhysicalDeviceSurfaceFormatsKHR") {
            vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, $0, $1)
        }
        // Match Metal's bgra8Unorm_srgb so both backends produce identical output.
        surfaceFormat = formats.first {
            $0.format == VK_FORMAT_B8G8R8A8_SRGB && $0.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR
        } ?? formats[0]

        screenRenderPass = try Self.createScreenRenderPass(device: device, colorFormat: surfaceFormat.format, samples: samples)
        depthRenderPass = try Self.createDepthRenderPass(device: device)
        uniformSetLayout = try Self.createSetLayout(device: device, type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, stages: allStages)
        textureSetLayout = try Self.createSetLayout(
            device: device, type: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages: vkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
        pipelineLayout = try Self.createPipelineLayout(device: device, setLayouts: [uniformSetLayout, textureSetLayout])
        descriptorPool = try Self.createDescriptorPool(device: device)
        comparisonSampler = try Self.createComparisonSampler(device: device)

        var poolInfo = VkCommandPoolCreateInfo()
        poolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO
        poolInfo.flags = vkFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
        poolInfo.queueFamilyIndex = family
        var pool: VkCommandPool?
        try vkCheck(vkCreateCommandPool(device, &poolInfo, nil, &pool), "vkCreateCommandPool")
        commandPool = pool!

        try createFrames()
        if canTime {
            var queryInfo = VkQueryPoolCreateInfo()
            queryInfo.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO
            queryInfo.queryType = VK_QUERY_TYPE_TIMESTAMP
            queryInfo.queryCount = UInt32(maxFramesInFlight * 2)
            var pool: VkQueryPool?
            if vkCreateQueryPool(device, &queryInfo, nil, &pool) == VK_SUCCESS { timestampPool = pool }
        }
        let size = window.framebufferSize
        swapchain = try createSwapchain(width: size.width, height: size.height, old: nil)
    }

    // MARK: - Resources

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard bytes.count > 0 else { throw GraphicsError("Cannot create an empty buffer") }
        let usageFlags = switch usage {
        case .vertex: vkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
        case .index: vkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT)
        }
        // Host-visible memory keeps uploads trivial; a staging path into device-local memory is a future optimization.
        let buffer = try createHostBuffer(length: bytes.count, usage: usageFlags)
        buffer.mapped.copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        return buffer
    }

    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        let extent = VkExtent2D(width: UInt32(descriptor.width), height: UInt32(descriptor.height))
        let allocation = try createImage(
            extent: extent, format: depthFormat, samples: VK_SAMPLE_COUNT_1_BIT,
            usage: vkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_IMAGE_USAGE_SAMPLED_BIT),
            aspect: vkFlags(VK_IMAGE_ASPECT_DEPTH_BIT))
        let framebuffer = try createFramebuffer(renderPass: depthRenderPass, attachments: [allocation.view], extent: extent)

        let set = try allocateDescriptorSet(layout: textureSetLayout)
        var imageInfo = VkDescriptorImageInfo(sampler: comparisonSampler, imageView: allocation.view, imageLayout: depthReadLayout)
        var write = VkWriteDescriptorSet()
        write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET
        write.dstSet = set
        write.dstBinding = 0
        write.descriptorCount = 1
        write.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
        withUnsafePointer(to: &imageInfo) { info in
            write.pImageInfo = info
            vkUpdateDescriptorSets(device, 1, &write, 0, nil)
        }

        return VulkanTexture(
            width: descriptor.width, height: descriptor.height, format: descriptor.format,
            image: allocation.image, memory: allocation.memory, view: allocation.view,
            framebuffer: framebuffer, descriptorSet: set, deletionQueue: deletionQueue)
    }

    func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        let isScreen = descriptor.target == .screen
        guard let vertexCode = descriptor.shader.spirvVertex else {
            throw GraphicsError("Shader has no SPIR-V vertex stage (run Scripts/compile-shaders.sh)")
        }
        let vertexModule = try createShaderModule(vertexCode)
        defer { vkDestroyShaderModule(device, vertexModule, nil) }
        var fragmentModule: VkShaderModule?
        if isScreen {
            guard let fragmentCode = descriptor.shader.spirvFragment else {
                throw GraphicsError("Shader has no SPIR-V fragment stage (run Scripts/compile-shaders.sh)")
            }
            fragmentModule = try createShaderModule(fragmentCode)
        }
        defer { if let fragmentModule { vkDestroyShaderModule(device, fragmentModule, nil) } }

        let arena = Arena()
        let entryPoint = arena.cString("main")

        var vertexStage = VkPipelineShaderStageCreateInfo()
        vertexStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO
        vertexStage.stage = VK_SHADER_STAGE_VERTEX_BIT
        vertexStage.module = vertexModule
        vertexStage.pName = entryPoint
        var stages = [vertexStage]
        if let fragmentModule {
            var fragmentStage = vertexStage
            fragmentStage.stage = VK_SHADER_STAGE_FRAGMENT_BIT
            fragmentStage.module = fragmentModule
            stages.append(fragmentStage)
        }

        var bindings: [VkVertexInputBindingDescription] = []
        var attributes: [VkVertexInputAttributeDescription] = []
        let layouts = [(descriptor.vertexLayout, VK_VERTEX_INPUT_RATE_VERTEX), (descriptor.instanceLayout ?? .none, VK_VERTEX_INPUT_RATE_INSTANCE)]
        for (binding, (layout, rate)) in layouts.enumerated() where !layout.attributes.isEmpty {
            bindings.append(VkVertexInputBindingDescription(binding: UInt32(binding), stride: UInt32(layout.stride), inputRate: rate))
            attributes += layout.attributes.map {
                VkVertexInputAttributeDescription(
                    location: UInt32($0.location), binding: UInt32(binding), format: $0.format.vulkan, offset: UInt32($0.offset))
            }
        }
        var vertexInput = VkPipelineVertexInputStateCreateInfo()
        vertexInput.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO
        vertexInput.vertexBindingDescriptionCount = UInt32(bindings.count)
        vertexInput.pVertexBindingDescriptions = arena.array(bindings)
        vertexInput.vertexAttributeDescriptionCount = UInt32(attributes.count)
        vertexInput.pVertexAttributeDescriptions = arena.array(attributes)

        var inputAssembly = VkPipelineInputAssemblyStateCreateInfo()
        inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO
        inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST

        var viewportState = VkPipelineViewportStateCreateInfo()
        viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO
        viewportState.viewportCount = 1
        viewportState.scissorCount = 1

        var rasterization = VkPipelineRasterizationStateCreateInfo()
        rasterization.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO
        rasterization.polygonMode = VK_POLYGON_MODE_FILL
        rasterization.cullMode = switch descriptor.cullMode {
        case .none: vkFlags(VK_CULL_MODE_NONE)
        case .front: vkFlags(VK_CULL_MODE_FRONT_BIT)
        case .back: vkFlags(VK_CULL_MODE_BACK_BIT)
        }
        // With the flipped (negative-height) viewport this matches Metal's winding.
        rasterization.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE
        rasterization.lineWidth = 1
        if let bias = descriptor.depthBias {
            rasterization.depthBiasEnable = VkBool32(VK_TRUE)
            rasterization.depthBiasConstantFactor = bias.constant
            rasterization.depthBiasSlopeFactor = bias.slopeScale
        }

        var multisample = VkPipelineMultisampleStateCreateInfo()
        multisample.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO
        multisample.rasterizationSamples = isScreen ? samples : VK_SAMPLE_COUNT_1_BIT

        var depthStencil = VkPipelineDepthStencilStateCreateInfo()
        depthStencil.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO
        depthStencil.depthTestEnable = VkBool32(descriptor.depthTest ? VK_TRUE : VK_FALSE)
        depthStencil.depthWriteEnable = VkBool32(descriptor.depthWrite ? VK_TRUE : VK_FALSE)
        depthStencil.depthCompareOp = descriptor.depthCompare.vulkan

        var blendAttachment = VkPipelineColorBlendAttachmentState()
        blendAttachment.colorWriteMask = vkFlags(
            VK_COLOR_COMPONENT_R_BIT, VK_COLOR_COMPONENT_G_BIT, VK_COLOR_COMPONENT_B_BIT, VK_COLOR_COMPONENT_A_BIT)
        if descriptor.alphaBlending {
            blendAttachment.blendEnable = VkBool32(VK_TRUE)
            blendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA
            blendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA
            blendAttachment.colorBlendOp = VK_BLEND_OP_ADD
            blendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE
            blendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA
            blendAttachment.alphaBlendOp = VK_BLEND_OP_ADD
        }
        var colorBlend = VkPipelineColorBlendStateCreateInfo()
        colorBlend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO
        colorBlend.attachmentCount = isScreen ? 1 : 0
        colorBlend.pAttachments = isScreen ? arena.store(blendAttachment) : nil

        let dynamicStates = [VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR]
        var dynamicState = VkPipelineDynamicStateCreateInfo()
        dynamicState.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO
        dynamicState.dynamicStateCount = UInt32(dynamicStates.count)
        dynamicState.pDynamicStates = arena.array(dynamicStates)

        var info = VkGraphicsPipelineCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO
        info.stageCount = UInt32(stages.count)
        info.pStages = arena.array(stages)
        info.pVertexInputState = arena.store(vertexInput)
        info.pInputAssemblyState = arena.store(inputAssembly)
        info.pViewportState = arena.store(viewportState)
        info.pRasterizationState = arena.store(rasterization)
        info.pMultisampleState = arena.store(multisample)
        info.pDepthStencilState = arena.store(depthStencil)
        info.pColorBlendState = arena.store(colorBlend)
        info.pDynamicState = arena.store(dynamicState)
        info.layout = pipelineLayout
        info.renderPass = isScreen ? screenRenderPass : depthRenderPass
        info.subpass = 0

        var pipeline: VkPipeline?
        try vkCheck(vkCreateGraphicsPipelines(device, nil, 1, &info, nil, &pipeline), "vkCreateGraphicsPipelines")
        return VulkanPipeline(pipeline!, deletionQueue: deletionQueue)
    }

    // MARK: - Frames

    func beginFrame(framebufferSize: (width: Int, height: Int)) throws -> Bool {
        precondition(current == nil, "beginFrame called twice without endFrame")
        guard framebufferSize.width > 0, framebufferSize.height > 0 else { return false }

        if needsSwapchainRebuild || swapchain.map({
            Int($0.extent.width) != framebufferSize.width || Int($0.extent.height) != framebufferSize.height
        }) ?? true {
            try rebuildSwapchain(width: framebufferSize.width, height: framebufferSize.height)
        }
        guard let swapchain else { return false }

        let frame = frames[frameIndex]
        var fence: VkFence? = frame.inFlight
        try vkCheck(vkWaitForFences(device, 1, &fence, VkBool32(VK_TRUE), UInt64.max), "vkWaitForFences")

        // This slot's fence covers frame (serial - maxFramesInFlight), so every earlier frame is done too.
        if frameSerial >= UInt64(maxFramesInFlight) {
            destroy(deletionQueue.collect(completedThrough: frameSerial - UInt64(maxFramesInFlight)))
        }
        deletionQueue.setCurrentSerial(frameSerial)
        if let timestampPool, frame.timestampsWritten {
            var ticks: (UInt64, UInt64) = (0, 0)
            let result = vkGetQueryPoolResults(
                device, timestampPool, UInt32(frameIndex * 2), 2, MemoryLayout.size(ofValue: ticks), &ticks, 8,
                vkFlags(VK_QUERY_RESULT_64_BIT))
            if result == VK_SUCCESS, ticks.1 > ticks.0 {
                gpuFrameTime = Double(ticks.1 - ticks.0) * timestampPeriod * 1e-9
            }
        }

        var imageIndex: UInt32 = 0
        let acquire = vkAcquireNextImageKHR(device, swapchain.handle, UInt64.max, frame.imageAvailable, nil, &imageIndex)
        if acquire == VK_ERROR_OUT_OF_DATE_KHR {
            needsSwapchainRebuild = true
            return false
        }
        if acquire != VK_SUBOPTIMAL_KHR { try vkCheck(acquire, "vkAcquireNextImageKHR") }
        try vkCheck(vkResetFences(device, 1, &fence), "vkResetFences")

        let cmd = frame.commandBuffer
        try vkCheck(vkResetCommandBuffer(cmd, 0), "vkResetCommandBuffer")
        var beginInfo = VkCommandBufferBeginInfo()
        beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
        beginInfo.flags = vkFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
        try vkCheck(vkBeginCommandBuffer(cmd, &beginInfo), "vkBeginCommandBuffer")
        if let timestampPool {
            vkCmdResetQueryPool(cmd, timestampPool, UInt32(frameIndex * 2), 2)
            vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, timestampPool, UInt32(frameIndex * 2))
        }
        frame.transient.reset()

        current = (imageIndex, captureNextFrame && swapchain.supportsReadback)
        captureNextFrame = false
        return true
    }

    func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let texture = target as! VulkanTexture
        var clear = VkClearValue()
        clear.depthStencil = VkClearDepthStencilValue(depth: clearDepth, stencil: 0)
        let extent = VkExtent2D(width: UInt32(texture.width), height: UInt32(texture.height))
        return beginPass(renderPass: depthRenderPass, framebuffer: texture.framebuffer, extent: extent, clearValues: [clear])
    }

    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let current, let swapchain else { preconditionFailure("beginScreenPass outside a frame") }
        var clearValues = [VkClearValue(), VkClearValue()]
        clearValues[0].color.float32 = (clearColor.x, clearColor.y, clearColor.z, clearColor.w)
        clearValues[1].depthStencil = VkClearDepthStencilValue(depth: clearDepth, stencil: 0)
        return beginPass(
            renderPass: screenRenderPass, framebuffer: swapchain.framebuffers[Int(current.imageIndex)],
            extent: swapchain.extent, clearValues: clearValues)
    }

    private func beginPass(renderPass: VkRenderPass, framebuffer: VkFramebuffer, extent: VkExtent2D,
                           clearValues: [VkClearValue]) -> RenderPass {
        precondition(current != nil, "Render pass started outside a frame")
        precondition(!inRenderPass, "Previous pass was not ended")
        let frame = frames[frameIndex]
        let cmd = frame.commandBuffer

        var passInfo = VkRenderPassBeginInfo()
        passInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO
        passInfo.renderPass = renderPass
        passInfo.framebuffer = framebuffer
        passInfo.renderArea = VkRect2D(offset: VkOffset2D(x: 0, y: 0), extent: extent)
        passInfo.clearValueCount = UInt32(clearValues.count)
        clearValues.withUnsafeBufferPointer { values in
            passInfo.pClearValues = values.baseAddress
            vkCmdBeginRenderPass(cmd, &passInfo, VK_SUBPASS_CONTENTS_INLINE)
        }
        inRenderPass = true

        // Flip Y in every pass so clip space is y-up and textures are laid out like Metal's.
        let width = Float(extent.width), height = Float(extent.height)
        var viewport = VkViewport(x: 0, y: height, width: width, height: -height, minDepth: 0, maxDepth: 1)
        vkCmdSetViewport(cmd, 0, 1, &viewport)
        var scissor = VkRect2D(offset: VkOffset2D(x: 0, y: 0), extent: extent)
        vkCmdSetScissor(cmd, 0, 1, &scissor)

        return VulkanRenderPass(commandBuffer: cmd, layout: pipelineLayout, transient: frame.transient)
    }

    func endPass() {
        guard inRenderPass else { return }
        vkCmdEndRenderPass(frames[frameIndex].commandBuffer)
        inRenderPass = false
    }

    func endFrame() throws -> Image? {
        guard let (imageIndex, capture) = current, let swapchain else { return nil }
        endPass()
        current = nil
        let frame = frames[frameIndex]
        let cmd = frame.commandBuffer

        var readback: VulkanBuffer?
        if capture {
            readback = try recordReadback(cmd: cmd, image: swapchain.images[Int(imageIndex)], extent: swapchain.extent)
        }
        if let timestampPool {
            vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, timestampPool, UInt32(frameIndex * 2 + 1))
            frames[frameIndex].timestampsWritten = true
        }
        try vkCheck(vkEndCommandBuffer(cmd), "vkEndCommandBuffer")

        var waitSemaphore: VkSemaphore? = frame.imageAvailable
        var waitStage = vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
        var signalSemaphore: VkSemaphore? = swapchain.renderFinished[Int(imageIndex)]
        var commandBuffer: VkCommandBuffer? = cmd
        var submit = VkSubmitInfo()
        submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO
        submit.waitSemaphoreCount = 1
        submit.commandBufferCount = 1
        submit.signalSemaphoreCount = 1
        let submitResult = withUnsafePointer(to: &waitSemaphore) { wait in
            withUnsafePointer(to: &waitStage) { stage in
                withUnsafePointer(to: &signalSemaphore) { signal in
                    withUnsafePointer(to: &commandBuffer) { buffers in
                        submit.pWaitSemaphores = wait
                        submit.pWaitDstStageMask = stage
                        submit.pSignalSemaphores = signal
                        submit.pCommandBuffers = buffers
                        return vkQueueSubmit(queue, 1, &submit, frame.inFlight)
                    }
                }
            }
        }
        try vkCheck(submitResult, "vkQueueSubmit")
        frameSerial += 1
        deletionQueue.setCurrentSerial(frameSerial)

        var image: Image?
        if let readback {
            var fence: VkFence? = frame.inFlight
            try vkCheck(vkWaitForFences(device, 1, &fence, VkBool32(VK_TRUE), UInt64.max), "vkWaitForFences")
            image = try readImage(from: readback, extent: swapchain.extent)
        }

        var swapchainHandle: VkSwapchainKHR? = swapchain.handle
        var index = imageIndex
        var present = VkPresentInfoKHR()
        present.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR
        present.waitSemaphoreCount = 1
        present.swapchainCount = 1
        let presentResult = withUnsafePointer(to: &signalSemaphore) { wait in
            withUnsafePointer(to: &swapchainHandle) { swapchains in
                withUnsafePointer(to: &index) { indices in
                    present.pWaitSemaphores = wait
                    present.pSwapchains = swapchains
                    present.pImageIndices = indices
                    return vkQueuePresentKHR(queue, &present)
                }
            }
        }
        if presentResult == VK_ERROR_OUT_OF_DATE_KHR || presentResult == VK_SUBOPTIMAL_KHR {
            needsSwapchainRebuild = true
        } else {
            try vkCheck(presentResult, "vkQueuePresentKHR")
        }

        frameIndex = (frameIndex + 1) % maxFramesInFlight
        return image
    }

    func waitIdle() {
        vkDeviceWaitIdle(device)
        destroy(deletionQueue.collect(completedThrough: nil))
    }

    func shutdown() {
        vkDeviceWaitIdle(device)
        readbackBuffer = nil
        // Destroys everything: released resources and ones the game still references
        // (those wrappers become inert; their deinit is a no-op after this).
        destroy(deletionQueue.shutdown())
        if let timestampPool { vkDestroyQueryPool(device, timestampPool, nil) }
        if let swapchain { destroy(swapchain, includingHandle: true) }
        swapchain = nil
        for frame in frames {
            vkDestroySemaphore(device, frame.imageAvailable, nil)
            vkDestroyFence(device, frame.inFlight, nil)
        }
        frames.removeAll()
        vkDestroyCommandPool(device, commandPool, nil)
        vkDestroySampler(device, comparisonSampler, nil)
        vkDestroyDescriptorPool(device, descriptorPool, nil)
        vkDestroyPipelineLayout(device, pipelineLayout, nil)
        vkDestroyDescriptorSetLayout(device, uniformSetLayout, nil)
        vkDestroyDescriptorSetLayout(device, textureSetLayout, nil)
        vkDestroyRenderPass(device, screenRenderPass, nil)
        vkDestroyRenderPass(device, depthRenderPass, nil)
        vkDestroyDevice(device, nil)
        vkDestroySurfaceKHR(instance, surface, nil)
        vkDestroyInstance(instance, nil)
    }

    private static func createInstance(applicationName: String) throws -> VkInstance {
        let arena = Arena()
        var extensions = GLFWWindow.requiredInstanceExtensions()
        var flags: VkInstanceCreateFlags = 0

        let available: [VkExtensionProperties] = try vkEnumerate("vkEnumerateInstanceExtensionProperties") {
            vkEnumerateInstanceExtensionProperties(nil, $0, $1)
        }
        let availableNames = Set(available.map { vkString($0.extensionName) })
        // Portability drivers such as MoltenVK are only enumerated when explicitly requested.
        if availableNames.contains("VK_KHR_portability_enumeration") {
            extensions.append("VK_KHR_portability_enumeration")
            flags |= vkFlags(VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR)
        }
        if availableNames.contains("VK_KHR_get_physical_device_properties2") {
            extensions.append("VK_KHR_get_physical_device_properties2")
        }

        var layers: [String] = []
        if ProcessInfo.processInfo.environment["ENGINE_VULKAN_VALIDATION"] == "1" {
            let availableLayers: [VkLayerProperties] = try vkEnumerate("vkEnumerateInstanceLayerProperties") {
                vkEnumerateInstanceLayerProperties($0, $1)
            }
            if availableLayers.contains(where: { vkString($0.layerName) == "VK_LAYER_KHRONOS_validation" }) {
                layers.append("VK_LAYER_KHRONOS_validation")
            } else {
                print("[Vulkan] ENGINE_VULKAN_VALIDATION=1 but VK_LAYER_KHRONOS_validation is not installed")
            }
        }

        var appInfo = VkApplicationInfo()
        appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO
        appInfo.pApplicationName = arena.cString(applicationName)
        appInfo.applicationVersion = vkMakeVersion(1, 0, 0)
        appInfo.pEngineName = arena.cString("SwiftGameEngine")
        appInfo.engineVersion = vkMakeVersion(0, 1, 0)
        appInfo.apiVersion = vkMakeVersion(1, 1, 0)

        var info = VkInstanceCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
        info.flags = flags
        info.pApplicationInfo = arena.store(appInfo)
        info.enabledExtensionCount = UInt32(extensions.count)
        info.ppEnabledExtensionNames = arena.cStrings(extensions)
        info.enabledLayerCount = UInt32(layers.count)
        info.ppEnabledLayerNames = arena.cStrings(layers)

        var instance: VkInstance?
        try vkCheck(vkCreateInstance(&info, nil, &instance), "vkCreateInstance")
        return instance!
    }

    private static func pickPhysicalDevice(instance: VkInstance, surface: VkSurfaceKHR) throws -> (VkPhysicalDevice, UInt32) {
        let devices: [VkPhysicalDevice?] = try vkEnumerate("vkEnumeratePhysicalDevices") {
            vkEnumeratePhysicalDevices(instance, $0, $1)
        }
        var best: (device: VkPhysicalDevice, family: UInt32, score: Int)?
        for case let device? in devices {
            let extensions: [VkExtensionProperties] = try vkEnumerate("vkEnumerateDeviceExtensionProperties") {
                vkEnumerateDeviceExtensionProperties(device, nil, $0, $1)
            }
            guard extensions.contains(where: { vkString($0.extensionName) == "VK_KHR_swapchain" }) else { continue }

            let families: [VkQueueFamilyProperties] = vkEnumerate {
                vkGetPhysicalDeviceQueueFamilyProperties(device, $0, $1)
            }
            let family = families.indices.first { index in
                var presentSupport: VkBool32 = 0
                vkGetPhysicalDeviceSurfaceSupportKHR(device, UInt32(index), surface, &presentSupport)
                return families[index].queueFlags & vkFlags(VK_QUEUE_GRAPHICS_BIT) != 0 && presentSupport != 0
            }
            guard let family else { continue }

            var properties = VkPhysicalDeviceProperties()
            vkGetPhysicalDeviceProperties(device, &properties)
            guard properties.apiVersion >= vkMakeVersion(1, 1, 0) else { continue }
            let score = switch properties.deviceType {
            case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: 3
            case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: 2
            default: 1
            }
            if score > best?.score ?? 0 { best = (device, UInt32(family), score) }
        }
        guard let best else { throw GraphicsError("No Vulkan 1.1 GPU with graphics + present support found") }
        return (best.device, best.family)
    }

    private static func createDevice(physicalDevice: VkPhysicalDevice, queueFamily: UInt32) throws -> VkDevice {
        let arena = Arena()
        var extensions = ["VK_KHR_swapchain"]
        let available: [VkExtensionProperties] = try vkEnumerate("vkEnumerateDeviceExtensionProperties") {
            vkEnumerateDeviceExtensionProperties(physicalDevice, nil, $0, $1)
        }
        // Required by the spec when the implementation exposes it (MoltenVK does).
        if available.contains(where: { vkString($0.extensionName) == "VK_KHR_portability_subset" }) {
            extensions.append("VK_KHR_portability_subset")
        }

        var queueInfo = VkDeviceQueueCreateInfo()
        queueInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO
        queueInfo.queueFamilyIndex = queueFamily
        queueInfo.queueCount = 1
        queueInfo.pQueuePriorities = arena.store(Float(1))

        var info = VkDeviceCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO
        info.queueCreateInfoCount = 1
        info.pQueueCreateInfos = arena.store(queueInfo)
        info.enabledExtensionCount = UInt32(extensions.count)
        info.ppEnabledExtensionNames = arena.cStrings(extensions)
        info.pEnabledFeatures = arena.store(VkPhysicalDeviceFeatures())

        var device: VkDevice?
        try vkCheck(vkCreateDevice(physicalDevice, &info, nil, &device), "vkCreateDevice")
        return device!
    }

    private static func createScreenRenderPass(device: VkDevice, colorFormat: VkFormat, samples: VkSampleCountFlagBits) throws -> VkRenderPass {
        let arena = Arena()
        let multisampled = samples != VK_SAMPLE_COUNT_1_BIT

        var color = VkAttachmentDescription()
        color.format = colorFormat
        color.samples = samples
        color.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR
        // The multisampled image is resolved, never stored.
        color.storeOp = multisampled ? VK_ATTACHMENT_STORE_OP_DONT_CARE : VK_ATTACHMENT_STORE_OP_STORE
        color.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        color.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        color.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        color.finalLayout = multisampled ? VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL : VK_IMAGE_LAYOUT_PRESENT_SRC_KHR

        var depth = VkAttachmentDescription()
        depth.format = depthFormat
        depth.samples = samples
        depth.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR
        depth.storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        depth.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        depth.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        depth.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        depth.finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL

        var attachments = [color, depth]
        var subpass = VkSubpassDescription()
        subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS
        subpass.colorAttachmentCount = 1
        subpass.pColorAttachments = arena.store(
            VkAttachmentReference(attachment: 0, layout: VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL))
        subpass.pDepthStencilAttachment = arena.store(
            VkAttachmentReference(attachment: 1, layout: VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL))
        if multisampled {
            var resolve = VkAttachmentDescription()
            resolve.format = colorFormat
            resolve.samples = VK_SAMPLE_COUNT_1_BIT
            resolve.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
            resolve.storeOp = VK_ATTACHMENT_STORE_OP_STORE
            resolve.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
            resolve.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
            resolve.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
            resolve.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
            attachments.append(resolve)
            subpass.pResolveAttachments = arena.store(
                VkAttachmentReference(attachment: 2, layout: VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL))
        }

        var dependency = VkSubpassDependency()
        dependency.srcSubpass = UInt32.max  // VK_SUBPASS_EXTERNAL
        dependency.dstSubpass = 0
        dependency.srcStageMask = vkFlags(
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT)
        dependency.srcAccessMask = vkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
        dependency.dstStageMask = vkFlags(
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT)
        dependency.dstAccessMask = vkFlags(
            VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT, VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)

        return try createRenderPass(device: device, attachments: attachments, subpass: subpass, dependencies: [dependency])
    }

    /// Depth-only pass for shadow maps: written as an attachment, then sampled by later passes.
    private static func createDepthRenderPass(device: VkDevice) throws -> VkRenderPass {
        let arena = Arena()
        var depth = VkAttachmentDescription()
        depth.format = depthFormat
        depth.samples = VK_SAMPLE_COUNT_1_BIT
        depth.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR
        depth.storeOp = VK_ATTACHMENT_STORE_OP_STORE
        depth.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        depth.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        depth.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        depth.finalLayout = depthReadLayout

        var subpass = VkSubpassDescription()
        subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS
        subpass.pDepthStencilAttachment = arena.store(
            VkAttachmentReference(attachment: 0, layout: VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL))

        let depthTests = vkFlags(VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT, VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT)
        let depthAccess = vkFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT, VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT)
        var before = VkSubpassDependency()  // previous frame's sampling → this write
        before.srcSubpass = UInt32.max
        before.dstSubpass = 0
        before.srcStageMask = vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT)
        before.srcAccessMask = vkFlags(VK_ACCESS_SHADER_READ_BIT)
        before.dstStageMask = depthTests
        before.dstAccessMask = depthAccess
        var after = VkSubpassDependency()  // this write → sampling in later passes
        after.srcSubpass = 0
        after.dstSubpass = UInt32.max
        after.srcStageMask = depthTests
        after.srcAccessMask = depthAccess
        after.dstStageMask = vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT)
        after.dstAccessMask = vkFlags(VK_ACCESS_SHADER_READ_BIT)

        return try createRenderPass(device: device, attachments: [depth], subpass: subpass, dependencies: [before, after])
    }

    private static func createRenderPass(device: VkDevice, attachments: [VkAttachmentDescription],
                                         subpass: VkSubpassDescription, dependencies: [VkSubpassDependency]) throws -> VkRenderPass {
        let arena = Arena()
        var info = VkRenderPassCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO
        info.attachmentCount = UInt32(attachments.count)
        info.pAttachments = arena.array(attachments)
        info.subpassCount = 1
        info.pSubpasses = arena.store(subpass)
        info.dependencyCount = UInt32(dependencies.count)
        info.pDependencies = arena.array(dependencies)
        var renderPass: VkRenderPass?
        try vkCheck(vkCreateRenderPass(device, &info, nil, &renderPass), "vkCreateRenderPass")
        return renderPass!
    }

    private static func createSetLayout(device: VkDevice, type: VkDescriptorType, stages: VkShaderStageFlags) throws -> VkDescriptorSetLayout {
        var binding = VkDescriptorSetLayoutBinding(
            binding: 0, descriptorType: type, descriptorCount: 1, stageFlags: stages, pImmutableSamplers: nil)
        var info = VkDescriptorSetLayoutCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO
        info.bindingCount = 1
        var layout: VkDescriptorSetLayout?
        let result = withUnsafePointer(to: &binding) { binding in
            info.pBindings = binding
            return vkCreateDescriptorSetLayout(device, &info, nil, &layout)
        }
        try vkCheck(result, "vkCreateDescriptorSetLayout")
        return layout!
    }

    /// One layout shared by every pipeline: set 0 = uniforms, set 1 = texture, plus push constants.
    private static func createPipelineLayout(device: VkDevice, setLayouts: [VkDescriptorSetLayout]) throws -> VkPipelineLayout {
        let arena = Arena()
        var info = VkPipelineLayoutCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO
        info.setLayoutCount = UInt32(setLayouts.count)
        info.pSetLayouts = arena.array(setLayouts.map { Optional($0) })
        info.pushConstantRangeCount = 1
        info.pPushConstantRanges = arena.store(
            VkPushConstantRange(stageFlags: allStages, offset: 0, size: UInt32(maxPushConstantSize)))
        var layout: VkPipelineLayout?
        try vkCheck(vkCreatePipelineLayout(device, &info, nil, &layout), "vkCreatePipelineLayout")
        return layout!
    }

    private static func createDescriptorPool(device: VkDevice) throws -> VkDescriptorPool {
        let sizes = [
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, descriptorCount: 256),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptorCount: 256),
        ]
        var info = VkDescriptorPoolCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO
        info.flags = vkFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT)
        info.maxSets = 512
        info.poolSizeCount = UInt32(sizes.count)
        var pool: VkDescriptorPool?
        let result = sizes.withUnsafeBufferPointer { sizes in
            info.pPoolSizes = sizes.baseAddress
            return vkCreateDescriptorPool(device, &info, nil, &pool)
        }
        try vkCheck(result, "vkCreateDescriptorPool")
        return pool!
    }

    /// Linear-filtered depth comparison (hardware PCF), white border = "lit" outside the map.
    private static func createComparisonSampler(device: VkDevice) throws -> VkSampler {
        var info = VkSamplerCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO
        info.magFilter = VK_FILTER_LINEAR
        info.minFilter = VK_FILTER_LINEAR
        info.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST
        info.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
        info.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
        info.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
        info.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE
        info.compareEnable = VkBool32(VK_TRUE)
        info.compareOp = VK_COMPARE_OP_LESS_OR_EQUAL
        var sampler: VkSampler?
        try vkCheck(vkCreateSampler(device, &info, nil, &sampler), "vkCreateSampler")
        return sampler!
    }

    private func allocateDescriptorSet(layout: VkDescriptorSetLayout) throws -> VkDescriptorSet {
        var layout: VkDescriptorSetLayout? = layout
        var info = VkDescriptorSetAllocateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO
        info.descriptorPool = descriptorPool
        info.descriptorSetCount = 1
        var set: VkDescriptorSet?
        let result = withUnsafePointer(to: &layout) { layouts in
            info.pSetLayouts = layouts
            return vkAllocateDescriptorSets(device, &info, &set)
        }
        try vkCheck(result, "vkAllocateDescriptorSets")
        return set!
    }

    private func createFrames() throws {
        var allocInfo = VkCommandBufferAllocateInfo()
        allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO
        allocInfo.commandPool = commandPool
        allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY
        allocInfo.commandBufferCount = UInt32(maxFramesInFlight)
        var commandBuffers = [VkCommandBuffer?](repeating: nil, count: maxFramesInFlight)
        try vkCheck(vkAllocateCommandBuffers(device, &allocInfo, &commandBuffers), "vkAllocateCommandBuffers")

        var fenceInfo = VkFenceCreateInfo()
        fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO
        fenceInfo.flags = vkFlags(VK_FENCE_CREATE_SIGNALED_BIT)

        for commandBuffer in commandBuffers {
            var fence: VkFence?
            try vkCheck(vkCreateFence(device, &fenceInfo, nil, &fence), "vkCreateFence")
            let transient = TransientRing<VulkanTransientChunk> { [unowned self] size in
                let chunk = try createTransientChunk(size: size)
                return (chunk, chunk.buffer.mapped)
            }
            frames.append(FrameSync(
                commandBuffer: commandBuffer!, imageAvailable: try createSemaphore(), inFlight: fence!, transient: transient))
        }
    }

    private func createTransientChunk(size: Int) throws -> VulkanTransientChunk {
        let buffer = try createHostBuffer(
            length: size,
            usage: vkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_BUFFER_USAGE_INDEX_BUFFER_BIT, VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT))
        let set = try allocateDescriptorSet(layout: uniformSetLayout)
        var bufferInfo = VkDescriptorBufferInfo(buffer: buffer.buffer, offset: 0, range: VkDeviceSize(maxUniformDataSize))
        var write = VkWriteDescriptorSet()
        write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET
        write.dstSet = set
        write.dstBinding = 0
        write.descriptorCount = 1
        write.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC
        withUnsafePointer(to: &bufferInfo) { info in
            write.pBufferInfo = info
            vkUpdateDescriptorSets(device, 1, &write, 0, nil)
        }
        // The set is freed with the pool at shutdown, alongside the chunk's buffer.
        return VulkanTransientChunk(buffer: buffer, uniformSet: set)
    }

    private func createSemaphore() throws -> VkSemaphore {
        var info = VkSemaphoreCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO
        var semaphore: VkSemaphore?
        try vkCheck(vkCreateSemaphore(device, &info, nil, &semaphore), "vkCreateSemaphore")
        return semaphore!
    }

    // MARK: - Swapchain

    private func rebuildSwapchain(width: Int, height: Int) throws {
        vkDeviceWaitIdle(device)
        let old = swapchain
        if let old { destroy(old, includingHandle: false) }
        swapchain = try createSwapchain(width: width, height: height, old: old?.handle)
        if let old { vkDestroySwapchainKHR(device, old.handle, nil) }
        needsSwapchainRebuild = false
    }

    private func createSwapchain(width: Int, height: Int, old: VkSwapchainKHR?) throws -> Swapchain {
        var caps = VkSurfaceCapabilitiesKHR()
        try vkCheck(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &caps), "vkGetPhysicalDeviceSurfaceCapabilitiesKHR")

        var extent = caps.currentExtent
        if extent.width == UInt32.max {
            extent.width = UInt32(width).clamped(caps.minImageExtent.width, caps.maxImageExtent.width)
            extent.height = UInt32(height).clamped(caps.minImageExtent.height, caps.maxImageExtent.height)
        }

        var imageCount = caps.minImageCount + 1
        if caps.maxImageCount > 0 { imageCount = min(imageCount, caps.maxImageCount) }

        let compositeAlpha = [
            VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR, VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
            VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR, VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
        ].first { caps.supportedCompositeAlpha & vkFlags($0) != 0 } ?? VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR

        let supportsReadback = caps.supportedUsageFlags & vkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT) != 0
        var usage = vkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
        if supportsReadback { usage |= vkFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT) }

        var info = VkSwapchainCreateInfoKHR()
        info.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR
        info.surface = surface
        info.minImageCount = imageCount
        info.imageFormat = surfaceFormat.format
        info.imageColorSpace = surfaceFormat.colorSpace
        info.imageExtent = extent
        info.imageArrayLayers = 1
        info.imageUsage = usage
        info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE
        info.preTransform = caps.currentTransform
        info.compositeAlpha = compositeAlpha
        info.presentMode = VK_PRESENT_MODE_FIFO_KHR  // vsync; always supported
        info.clipped = VkBool32(VK_TRUE)
        info.oldSwapchain = old

        var handle: VkSwapchainKHR?
        try vkCheck(vkCreateSwapchainKHR(device, &info, nil, &handle), "vkCreateSwapchainKHR")
        let images: [VkImage?] = try vkEnumerate("vkGetSwapchainImagesKHR") {
            vkGetSwapchainImagesKHR(device, handle, $0, $1)
        }

        let views = try images.map {
            try createImageView($0!, format: surfaceFormat.format, aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT))
        }
        let depth = try createImage(
            extent: extent, format: depthFormat, samples: samples,
            usage: vkFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT),
            aspect: vkFlags(VK_IMAGE_ASPECT_DEPTH_BIT))
        var msaaColor: ImageAllocation?
        if samples != VK_SAMPLE_COUNT_1_BIT {
            msaaColor = try createImage(
                extent: extent, format: surfaceFormat.format, samples: samples,
                usage: vkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT),
                aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT))
        }

        let framebuffers = try views.map { view in
            let attachments = msaaColor.map { [$0.view, depth.view, view] } ?? [view, depth.view]
            return try createFramebuffer(renderPass: screenRenderPass, attachments: attachments, extent: extent)
        }

        return Swapchain(
            handle: handle!, extent: extent, images: images.map { $0! }, views: views, framebuffers: framebuffers,
            renderFinished: try images.map { _ in try createSemaphore() },
            depth: depth, msaaColor: msaaColor, supportsReadback: supportsReadback)
    }

    private func destroy(_ swapchain: Swapchain, includingHandle: Bool) {
        for framebuffer in swapchain.framebuffers { vkDestroyFramebuffer(device, framebuffer, nil) }
        for view in swapchain.views { vkDestroyImageView(device, view, nil) }
        for semaphore in swapchain.renderFinished { vkDestroySemaphore(device, semaphore, nil) }
        for allocation in [swapchain.depth] + [swapchain.msaaColor].compactMap({ $0 }) {
            vkDestroyImageView(device, allocation.view, nil)
            vkDestroyImage(device, allocation.image, nil)
            vkFreeMemory(device, allocation.memory, nil)
        }
        if includingHandle { vkDestroySwapchainKHR(device, swapchain.handle, nil) }
    }

    private func createImage(extent: VkExtent2D, format: VkFormat, samples: VkSampleCountFlagBits,
                             usage: VkImageUsageFlags, aspect: VkImageAspectFlags) throws -> ImageAllocation {
        var info = VkImageCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO
        info.imageType = VK_IMAGE_TYPE_2D
        info.format = format
        info.extent = VkExtent3D(width: extent.width, height: extent.height, depth: 1)
        info.mipLevels = 1
        info.arrayLayers = 1
        info.samples = samples
        info.tiling = VK_IMAGE_TILING_OPTIMAL
        info.usage = usage
        info.sharingMode = VK_SHARING_MODE_EXCLUSIVE
        info.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        var image: VkImage?
        try vkCheck(vkCreateImage(device, &info, nil, &image), "vkCreateImage")

        var requirements = VkMemoryRequirements()
        vkGetImageMemoryRequirements(device, image, &requirements)
        let memory = try allocateMemory(requirements, properties: vkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
        try vkCheck(vkBindImageMemory(device, image, memory, 0), "vkBindImageMemory")
        let view = try createImageView(image!, format: format, aspect: aspect)
        return ImageAllocation(image: image!, memory: memory, view: view)
    }

    private func createImageView(_ image: VkImage, format: VkFormat, aspect: VkImageAspectFlags) throws -> VkImageView {
        var info = VkImageViewCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO
        info.image = image
        info.viewType = VK_IMAGE_VIEW_TYPE_2D
        info.format = format
        info.subresourceRange = VkImageSubresourceRange(
            aspectMask: aspect, baseMipLevel: 0, levelCount: 1, baseArrayLayer: 0, layerCount: 1)
        var view: VkImageView?
        try vkCheck(vkCreateImageView(device, &info, nil, &view), "vkCreateImageView")
        return view!
    }

    private func createFramebuffer(renderPass: VkRenderPass, attachments: [VkImageView], extent: VkExtent2D) throws -> VkFramebuffer {
        var views = attachments.map { Optional($0) }
        var info = VkFramebufferCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO
        info.renderPass = renderPass
        info.attachmentCount = UInt32(views.count)
        info.width = extent.width
        info.height = extent.height
        info.layers = 1
        var framebuffer: VkFramebuffer?
        let result = views.withUnsafeMutableBufferPointer { views in
            info.pAttachments = UnsafePointer(views.baseAddress)
            return vkCreateFramebuffer(device, &info, nil, &framebuffer)
        }
        try vkCheck(result, "vkCreateFramebuffer")
        return framebuffer!
    }

    // MARK: - Memory

    private func allocateMemory(_ requirements: VkMemoryRequirements, properties: VkMemoryPropertyFlags) throws -> VkDeviceMemory {
        let types = withUnsafeBytes(of: memoryProperties.memoryTypes) { Array($0.bindMemory(to: VkMemoryType.self)) }
        let typeIndex = (0..<Int(memoryProperties.memoryTypeCount)).first {
            requirements.memoryTypeBits & (1 << $0) != 0 && types[$0].propertyFlags & properties == properties
        }
        guard let typeIndex else { throw GraphicsError("No suitable Vulkan memory type") }

        var info = VkMemoryAllocateInfo()
        info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO
        info.allocationSize = requirements.size
        info.memoryTypeIndex = UInt32(typeIndex)
        var memory: VkDeviceMemory?
        try vkCheck(vkAllocateMemory(device, &info, nil, &memory), "vkAllocateMemory")
        return memory!
    }

    private func createHostBuffer(length: Int, usage: VkBufferUsageFlags) throws -> VulkanBuffer {
        var info = VkBufferCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO
        info.size = VkDeviceSize(length)
        info.usage = usage
        info.sharingMode = VK_SHARING_MODE_EXCLUSIVE
        var buffer: VkBuffer?
        try vkCheck(vkCreateBuffer(device, &info, nil, &buffer), "vkCreateBuffer")

        var requirements = VkMemoryRequirements()
        vkGetBufferMemoryRequirements(device, buffer, &requirements)
        let memory = try allocateMemory(
            requirements,
            properties: vkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))
        try vkCheck(vkBindBufferMemory(device, buffer, memory, 0), "vkBindBufferMemory")
        var mapped: UnsafeMutableRawPointer?
        try vkCheck(vkMapMemory(device, memory, 0, VkDeviceSize(length), 0, &mapped), "vkMapMemory")
        return VulkanBuffer(buffer: buffer!, memory: memory, length: length, mapped: mapped!, deletionQueue: deletionQueue)
    }

    private func destroy(_ resources: [VulkanResource]) {
        for resource in resources {
            switch resource {
            case .buffer(let buffer, let memory):
                vkDestroyBuffer(device, buffer, nil)
                vkFreeMemory(device, memory, nil)  // implicitly unmaps
            case .pipeline(let pipeline):
                vkDestroyPipeline(device, pipeline, nil)
            case .texture(let image, let memory, let view, let framebuffer, let set):
                var set: VkDescriptorSet? = set
                vkFreeDescriptorSets(device, descriptorPool, 1, &set)
                vkDestroyFramebuffer(device, framebuffer, nil)
                vkDestroyImageView(device, view, nil)
                vkDestroyImage(device, image, nil)
                vkFreeMemory(device, memory, nil)
            }
        }
    }

    private func createShaderModule(_ code: [UInt8]) throws -> VkShaderModule {
        guard code.count % 4 == 0 else { throw GraphicsError("SPIR-V size is not a multiple of 4") }
        // Copy into [UInt32] to guarantee the alignment Vulkan requires.
        let words = [UInt32](unsafeUninitializedCapacity: code.count / 4) { buffer, count in
            code.withUnsafeBytes { UnsafeMutableRawBufferPointer(buffer).copyMemory(from: $0) }
            count = code.count / 4
        }
        var info = VkShaderModuleCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO
        info.codeSize = code.count
        var module: VkShaderModule?
        let result = words.withUnsafeBufferPointer { words in
            info.pCode = words.baseAddress
            return vkCreateShaderModule(device, &info, nil, &module)
        }
        try vkCheck(result, "vkCreateShaderModule")
        return module!
    }

    // MARK: - Readback

    private func recordReadback(cmd: VkCommandBuffer, image: VkImage, extent: VkExtent2D) throws -> VulkanBuffer {
        let length = Int(extent.width * extent.height * 4)
        if readbackBuffer.map({ $0.length < length }) ?? true {
            // The old buffer (if any) goes through the deletion queue.
            readbackBuffer = try createHostBuffer(length: length, usage: vkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT))
        }
        let readback = readbackBuffer!
        let colorRange = VkImageSubresourceRange(
            aspectMask: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), baseMipLevel: 0, levelCount: 1, baseArrayLayer: 0, layerCount: 1)

        func barrier(from: VkImageLayout, to: VkImageLayout, srcAccess: VkAccessFlags, dstAccess: VkAccessFlags,
                     srcStage: VkPipelineStageFlags, dstStage: VkPipelineStageFlags) {
            var barrier = VkImageMemoryBarrier()
            barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER
            barrier.oldLayout = from
            barrier.newLayout = to
            barrier.srcAccessMask = srcAccess
            barrier.dstAccessMask = dstAccess
            barrier.srcQueueFamilyIndex = UInt32.max  // VK_QUEUE_FAMILY_IGNORED
            barrier.dstQueueFamilyIndex = UInt32.max
            barrier.image = image
            barrier.subresourceRange = colorRange
            vkCmdPipelineBarrier(cmd, srcStage, dstStage, 0, 0, nil, 0, nil, 1, &barrier)
        }

        barrier(from: VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, to: VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                srcAccess: vkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT), dstAccess: vkFlags(VK_ACCESS_TRANSFER_READ_BIT),
                srcStage: vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT), dstStage: vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT))

        var region = VkBufferImageCopy()
        region.imageSubresource = VkImageSubresourceLayers(
            aspectMask: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), mipLevel: 0, baseArrayLayer: 0, layerCount: 1)
        region.imageExtent = VkExtent3D(width: extent.width, height: extent.height, depth: 1)
        vkCmdCopyImageToBuffer(cmd, image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, readback.buffer, 1, &region)

        barrier(from: VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, to: VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                srcAccess: vkFlags(VK_ACCESS_TRANSFER_READ_BIT), dstAccess: 0,
                srcStage: vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT), dstStage: vkFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT))

        let hostBarrier = VkBufferMemoryBarrier(
            sType: VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER, pNext: nil,
            srcAccessMask: vkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), dstAccessMask: vkFlags(VK_ACCESS_HOST_READ_BIT),
            srcQueueFamilyIndex: UInt32.max, dstQueueFamilyIndex: UInt32.max,
            buffer: readback.buffer, offset: 0, size: VkDeviceSize(length))
        withUnsafePointer(to: hostBarrier) {
            vkCmdPipelineBarrier(cmd, vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT), vkFlags(VK_PIPELINE_STAGE_HOST_BIT),
                                 0, 0, nil, 1, $0, 0, nil)
        }
        return readback
    }

    private func readImage(from buffer: VulkanBuffer, extent: VkExtent2D) throws -> Image {
        let width = Int(extent.width), height = Int(extent.height)
        let bytes = UnsafeRawBufferPointer(start: buffer.mapped, count: width * height * 4)
        let isBGRA = surfaceFormat.format == VK_FORMAT_B8G8R8A8_SRGB || surfaceFormat.format == VK_FORMAT_B8G8R8A8_UNORM
        if isBGRA {
            return Image(width: width, height: height, bgra: bytes, bytesPerRow: width * 4)
        }
        return Image(width: width, height: height, pixels: Array(bytes))
    }
}


final class VulkanRenderPass: RenderPass {
    let commandBuffer: VkCommandBuffer
    private let layout: VkPipelineLayout
    private let transient: TransientRing<VulkanTransientChunk>

    init(commandBuffer: VkCommandBuffer, layout: VkPipelineLayout, transient: TransientRing<VulkanTransientChunk>) {
        self.commandBuffer = commandBuffer
        self.layout = layout
        self.transient = transient
    }

    func setPipeline(_ pipeline: RenderPipeline) {
        vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, (pipeline as! VulkanPipeline).pipeline)
    }

    func setVertexBuffer(_ buffer: GPUBuffer, offset: Int, index: Int) {
        var handle: VkBuffer? = (buffer as! VulkanBuffer).buffer
        var offset = VkDeviceSize(offset)
        vkCmdBindVertexBuffers(commandBuffer, UInt32(index), 1, &handle, &offset)
    }

    func setVertexData(_ bytes: UnsafeRawBufferPointer, index: Int) {
        let allocation = upload(bytes, alignment: 16, reserve: 0)
        var handle: VkBuffer? = allocation.chunk.buffer.buffer
        var offset = VkDeviceSize(allocation.offset)
        vkCmdBindVertexBuffers(commandBuffer, UInt32(index), 1, &handle, &offset)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxUniformDataSize, "Uniform data exceeds \(maxUniformDataSize) bytes")
        // The descriptor's range is fixed at maxUniformDataSize, so keep that much addressable.
        let allocation = upload(bytes, alignment: 256, reserve: maxUniformDataSize)
        var set: VkDescriptorSet? = allocation.chunk.uniformSet
        var dynamicOffset = UInt32(allocation.offset)
        vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, layout, 0, 1, &set, 1, &dynamicOffset)
    }

    func setTexture(_ texture: GPUTexture) {
        var set: VkDescriptorSet? = (texture as! VulkanTexture).descriptorSet
        vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, layout, 1, 1, &set, 0, nil)
    }

    func setIndexBuffer(_ buffer: GPUBuffer, type: IndexType) {
        vkCmdBindIndexBuffer(
            commandBuffer, (buffer as! VulkanBuffer).buffer, 0,
            type == .uint16 ? VK_INDEX_TYPE_UINT16 : VK_INDEX_TYPE_UINT32)
    }

    func setPushConstants(_ bytes: UnsafeRawBufferPointer) {
        precondition(bytes.count <= maxPushConstantSize, "Push constants exceed \(maxPushConstantSize) bytes")
        vkCmdPushConstants(commandBuffer, layout, allStages, 0, UInt32(bytes.count), bytes.baseAddress)
    }

    func draw(vertexCount: Int, instanceCount: Int, firstVertex: Int) {
        vkCmdDraw(commandBuffer, UInt32(vertexCount), UInt32(instanceCount), UInt32(firstVertex), 0)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        vkCmdDrawIndexed(commandBuffer, UInt32(indexCount), UInt32(instanceCount), UInt32(firstIndex), 0, 0)
    }

    private func upload(_ bytes: UnsafeRawBufferPointer, alignment: Int, reserve: Int) -> TransientRing<VulkanTransientChunk>.Allocation {
        do {
            return try transient.upload(bytes, alignment: alignment, reserve: reserve)
        } catch {
            preconditionFailure("\(error)")
        }
    }
}

private extension VertexFormat {
    var vulkan: VkFormat {
        switch self {
        case .float: VK_FORMAT_R32_SFLOAT
        case .float2: VK_FORMAT_R32G32_SFLOAT
        case .float3: VK_FORMAT_R32G32B32_SFLOAT
        case .float4: VK_FORMAT_R32G32B32A32_SFLOAT
        }
    }
}

private extension CompareFunction {
    var vulkan: VkCompareOp {
        switch self {
        case .never: VK_COMPARE_OP_NEVER
        case .less: VK_COMPARE_OP_LESS
        case .lessEqual: VK_COMPARE_OP_LESS_OR_EQUAL
        case .equal: VK_COMPARE_OP_EQUAL
        case .greater: VK_COMPARE_OP_GREATER
        case .greaterEqual: VK_COMPARE_OP_GREATER_OR_EQUAL
        case .always: VK_COMPARE_OP_ALWAYS
        }
    }
}

private extension UInt32 {
    func clamped(_ low: UInt32, _ high: UInt32) -> UInt32 { Swift.min(Swift.max(self, low), high) }
}
#endif
