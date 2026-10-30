#if ENGINE_VULKAN
import CVulkan
import Foundation

private let maxFramesInFlight = 2
/// Passes per frame whose GPU time is measured; later ones go untimed.
private let maxTimedPasses = 16
/// Per frame slot: frame start and end, then a start/end pair per timed pass.
private let timestampsPerFrame = 2 + maxTimedPasses * 2
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
    /// Persistently mapped; nil for device-local buffers (static geometry), which are filled through staging.
    let mapped: UnsafeMutableRawPointer?

    init(buffer: VkBuffer, memory: VkDeviceMemory, length: Int, mapped: UnsafeMutableRawPointer?, deletionQueue: VulkanDeletionQueue) {
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
    let mipLevelCount: Int
    let view: VkImageView
    /// Depth render targets only.
    let framebuffer: VkFramebuffer?
    /// Depth render targets only: set 1 (combined image sampler) for sampling the texture.
    let descriptorSet: VkDescriptorSet?

    init(width: Int, height: Int, format: TextureFormat, mipLevelCount: Int = 1, image: VkImage, memory: VkDeviceMemory,
         view: VkImageView, framebuffer: VkFramebuffer? = nil, descriptorSet: VkDescriptorSet? = nil,
         deletionQueue: VulkanDeletionQueue) {
        self.width = width
        self.height = height
        self.format = format
        self.mipLevelCount = mipLevelCount
        self.view = view
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
    /// Set 2 descriptor sets for game-bound resources (see `VulkanDescriptorArena`).
    var descriptors: VulkanDescriptorArena
    /// Whether this slot's timestamp queries hold results from its previous submission.
    var timestampsWritten = false
    /// Names of the passes timed in this slot's last submission, in recording order.
    var timedPasses: [String] = []
    /// Occlusion queries issued by this slot's last submission (read back when it is reused).
    var occlusion = OcclusionQueryBatch()
    /// Leading queries of this slot's range to reset before reuse (all of them at first,
    /// since new query pools start out undefined).
    var occlusionQueriesToReset = maxOcclusionQueriesPerFrame
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

/// Scene targets at the render size when it differs from the window (see `RenderResolution`).
private struct OffscreenTargets {
    var extent: VkExtent2D
    var depth: ImageAllocation
    var msaaColor: ImageAllocation?
    /// Single-sample result: sampled by the window pass and read back for screenshots.
    var resolved: ImageAllocation
    var framebuffer: VkFramebuffer
    /// Set 1 binding of `resolved` with the linear sampler.
    var descriptorSet: VkDescriptorSet
    /// `resolved` read through a UNORM view (no sRGB decode), for upscalers. Nil when the
    /// swapchain format has no UNORM twin.
    var unormView: VkImageView?
    var unormDescriptorSet: VkDescriptorSet?
}

/// FSR 1 upscale output at the letterboxed window size (gamma-encoded UNORM).
private struct UpscaleTargets {
    var input: VkExtent2D
    var output: VkExtent2D
    var image: ImageAllocation
    var framebuffer: VkFramebuffer
    var descriptorSet: VkDescriptorSet
}

final class VulkanRenderDevice: RenderDevice {
    let backend = GraphicsBackend.vulkan
    let deviceName: String
    let sampleCount: Int
    let maxTextureSize: Int
    var captureNextFrame = false
    var captureWindow = false
    var vsync = true {
        didSet { if vsync != oldValue { needsSwapchainRebuild = true } }
    }
    var upscaler = Upscaler.bilinear
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
    /// Compatible with `screenRenderPass` (same attachments), but leaves the result shader-readable.
    private let offscreenRenderPass: VkRenderPass
    private let depthRenderPass: VkRenderPass
    private let uniformSetLayout: VkDescriptorSetLayout
    private let textureSetLayout: VkDescriptorSetLayout
    private let userSetLayout: VkDescriptorSetLayout
    private let samplerCache = SamplerCache<VulkanSampler>()
    private let pipelineLayout: VkPipelineLayout
    private let descriptorPool: VkDescriptorPool
    private let comparisonSampler: VkSampler
    private let linearSampler: VkSampler
    private var blitPipeline: VulkanPipeline!
    /// UNORM counterpart of the sRGB swapchain format (nil if there isn't one: no FSR then).
    private let unormFormat: VkFormat?
    /// Single color attachment in `unormFormat`, left shader-readable: the FSR upscale pass.
    private let upscaleRenderPass: VkRenderPass?
    private var easuPipeline: VulkanPipeline?
    private var rcasPipeline: VulkanPipeline?
    private var upscaleTargets: UpscaleTargets?
    private var offscreen: OffscreenTargets?
    private let commandPool: VkCommandPool
    private var frames: [FrameSync] = []
    private var swapchain: Swapchain?
    private var frameIndex = 0
    private var needsSwapchainRebuild = false
    private var current: (imageIndex: UInt32, capture: Bool, offscreen: Bool)?
    private var currentPass: VulkanRenderPass?
    private var inRenderPass: Bool { currentPass != nil }
    /// Timestamp query that `endPass` writes to close the current pass's timing, if timed.
    private var timedPassEnd: UInt32?
    /// Serial of the frame currently being recorded (increments every submitted frame).
    private var frameSerial: UInt64 = 0
    private let deletionQueue = VulkanDeletionQueue()
    private var readbackBuffer: VulkanBuffer?
    /// `timestampsPerFrame` timestamps per frame slot; nil when the queue can't time.
    private var timestampPool: VkQueryPool?
    private(set) var gpuPassTimes: [GPUPassTime] = []
    private var timestampPeriod: Double = 1
    /// `maxOcclusionQueriesPerFrame` occlusion queries per frame slot.
    private let occlusionPool: VkQueryPool

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
        let limits = properties.limits
        maxTextureSize = Int(min(limits.maxImageDimension2D, limits.maxFramebufferWidth, limits.maxFramebufferHeight))

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
        offscreenRenderPass = try Self.createScreenRenderPass(
            device: device, colorFormat: surfaceFormat.format, samples: samples, offscreen: true)
        depthRenderPass = try Self.createDepthRenderPass(device: device)
        unormFormat = switch surfaceFormat.format {
        case VK_FORMAT_B8G8R8A8_SRGB: VK_FORMAT_B8G8R8A8_UNORM
        case VK_FORMAT_R8G8B8A8_SRGB: VK_FORMAT_R8G8B8A8_UNORM
        default: nil
        }
        upscaleRenderPass = try unormFormat.map { try Self.createUpscaleRenderPass(device: device, format: $0) }
        uniformSetLayout = try Self.createSetLayout(device: device, type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, stages: allStages)
        textureSetLayout = try Self.createSetLayout(
            device: device, type: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, stages: vkFlags(VK_SHADER_STAGE_FRAGMENT_BIT))
        userSetLayout = try VulkanDescriptorArena.makeLayout(device: device)
        pipelineLayout = try Self.createPipelineLayout(device: device, setLayouts: [uniformSetLayout, textureSetLayout, userSetLayout])
        descriptorPool = try Self.createDescriptorPool(device: device)
        comparisonSampler = try Self.createComparisonSampler(device: device)
        linearSampler = try Self.createLinearSampler(device: device)

        var poolInfo = VkCommandPoolCreateInfo()
        poolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO
        poolInfo.flags = vkFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
        poolInfo.queueFamilyIndex = family
        var pool: VkCommandPool?
        try vkCheck(vkCreateCommandPool(device, &poolInfo, nil, &pool), "vkCreateCommandPool")
        commandPool = pool!

        var occlusionInfo = VkQueryPoolCreateInfo()
        occlusionInfo.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO
        occlusionInfo.queryType = VK_QUERY_TYPE_OCCLUSION
        occlusionInfo.queryCount = UInt32(maxFramesInFlight * maxOcclusionQueriesPerFrame)
        var occlusionPool: VkQueryPool?
        try vkCheck(vkCreateQueryPool(device, &occlusionInfo, nil, &occlusionPool), "vkCreateQueryPool")
        self.occlusionPool = occlusionPool!

        try createFrames()
        if canTime {
            var queryInfo = VkQueryPoolCreateInfo()
            queryInfo.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO
            queryInfo.queryType = VK_QUERY_TYPE_TIMESTAMP
            queryInfo.queryCount = UInt32(maxFramesInFlight * timestampsPerFrame)
            var pool: VkQueryPool?
            if vkCreateQueryPool(device, &queryInfo, nil, &pool) == VK_SUCCESS { timestampPool = pool }
        }
        let size = window.framebufferSize
        swapchain = try createSwapchain(width: size.width, height: size.height, old: nil)

        var blit = PipelineDescriptor(shader: try ShaderSource.load(named: "blit", bundle: .module), vertexLayout: .none)
        blit.cullMode = .none
        blit.depthTest = false
        blit.depthWrite = false
        blitPipeline = try makePipeline(blit) as? VulkanPipeline

        if let upscaleRenderPass {
            var easu = PipelineDescriptor(shader: try ShaderSource.load(named: "fsr_easu", bundle: .module), vertexLayout: .none)
            easu.cullMode = .none
            easu.depthTest = false
            easu.depthWrite = false
            easuPipeline = try createPipeline(easu, colorPass: upscaleRenderPass)
            var rcas = easu
            rcas.shader = try ShaderSource.load(named: "fsr_rcas", bundle: .module)
            rcasPipeline = try createPipeline(rcas)
        }
    }

    func supports(_ upscaler: Upscaler) -> Bool {
        switch upscaler {
        case .bilinear: true
        case .fsr1: upscaleRenderPass != nil
        case .metalFXSpatial: false
        }
    }

    // MARK: - Resources

    func makeBuffer(bytes: UnsafeRawBufferPointer, usage: BufferUsage) throws -> GPUBuffer {
        guard bytes.count > 0 else { throw GraphicsError("Cannot create an empty buffer") }
        let usageFlags = switch usage {
        case .vertex: vkFlags(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
        case .index: vkFlags(VK_BUFFER_USAGE_INDEX_BUFFER_BIT)
        case .uniform: vkFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT)
        }
        // Static buffers live in device-local memory, filled through a staging buffer. Falls back to
        // host-visible memory when the device has no device-local type usable for buffers.
        let length = bytes.count
        let raw: RawBuffer
        do {
            raw = try createRawBuffer(
                length: length, usage: usageFlags | vkFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT),
                properties: vkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT), mapped: false)
        } catch {
            let buffer = try createHostBuffer(length: length, usage: usageFlags)
            buffer.mapped!.copyMemory(from: bytes.baseAddress!, byteCount: length)
            return buffer
        }
        do {
            let staging = try createRawBuffer(
                length: length, usage: vkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
                properties: vkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, VK_MEMORY_PROPERTY_HOST_COHERENT_BIT), mapped: true)
            defer { destroy(staging) }
            staging.mapped!.copyMemory(from: bytes.baseAddress!, byteCount: length)
            try submitCopy(from: staging.buffer, to: raw.buffer, length: length)
        } catch {
            destroy(raw)
            throw error
        }
        return VulkanBuffer(buffer: raw.buffer, memory: raw.memory, length: length, mapped: nil, deletionQueue: deletionQueue)
    }

    /// Records and submits a one-shot copy and waits for it. Uploads happen at load time and are
    /// rare mid-frame, so a synchronous submit (rather than batching into the frame's command
    /// buffer) is the simplest correct option: it also makes the buffer usable by the frame being
    /// recorded, and lets the caller free the staging buffer right after.
    private func submitCopy(from source: VkBuffer, to destination: VkBuffer, length: Int) throws {
        var allocInfo = VkCommandBufferAllocateInfo()
        allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO
        allocInfo.commandPool = commandPool
        allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY
        allocInfo.commandBufferCount = 1
        var cmd: VkCommandBuffer?
        try vkCheck(vkAllocateCommandBuffers(device, &allocInfo, &cmd), "vkAllocateCommandBuffers")
        defer { vkFreeCommandBuffers(device, commandPool, 1, &cmd) }

        var beginInfo = VkCommandBufferBeginInfo()
        beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
        beginInfo.flags = vkFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
        try vkCheck(vkBeginCommandBuffer(cmd, &beginInfo), "vkBeginCommandBuffer")
        var region = VkBufferCopy(srcOffset: 0, dstOffset: 0, size: VkDeviceSize(length))
        vkCmdCopyBuffer(cmd, source, destination, 1, &region)
        // Make the copy visible to vertex input in later submissions.
        var barrier = VkMemoryBarrier()
        barrier.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER
        barrier.srcAccessMask = vkFlags(VK_ACCESS_TRANSFER_WRITE_BIT)
        barrier.dstAccessMask = vkFlags(VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT, VK_ACCESS_INDEX_READ_BIT)
        vkCmdPipelineBarrier(
            cmd, vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT), vkFlags(VK_PIPELINE_STAGE_VERTEX_INPUT_BIT), 0, 1, &barrier, 0, nil, 0, nil)
        try vkCheck(vkEndCommandBuffer(cmd), "vkEndCommandBuffer")

        var fenceInfo = VkFenceCreateInfo()
        fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO
        var fence: VkFence?
        try vkCheck(vkCreateFence(device, &fenceInfo, nil, &fence), "vkCreateFence")
        defer { vkDestroyFence(device, fence, nil) }
        var submit = VkSubmitInfo()
        submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO
        submit.commandBufferCount = 1
        try withUnsafePointer(to: &cmd) { buffers in
            submit.pCommandBuffers = buffers
            try vkCheck(vkQueueSubmit(queue, 1, &submit, fence), "vkQueueSubmit")
        }
        try vkCheck(vkWaitForFences(device, 1, &fence, VkBool32(VK_TRUE), UInt64.max), "vkWaitForFences")
    }

    func makeTexture(_ descriptor: TextureDescriptor) throws -> GPUTexture {
        guard descriptor.format == .depth32Float else {
            throw GraphicsError("Render targets must be .depth32Float; use makeTexture(pixels:...) for color textures")
        }
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

    func makeTexture(pixels: UnsafeRawBufferPointer, width: Int, height: Int, format: TextureFormat,
                     generateMipmaps: Bool) throws -> GPUTexture {
        try format.validateUpload(byteCount: pixels.count, width: width, height: height, maxSize: maxTextureSize)
        let srgb = format == .rgba8Srgb
        let levels = generateMipmaps
            ? MipChain.generate(pixels: Array(pixels), width: width, height: height, srgb: srgb)
            : [MipChain.Level(width: width, height: height, pixels: Array(pixels))]

        let extent = VkExtent2D(width: UInt32(width), height: UInt32(height))
        let allocation = try createImage(
            extent: extent, format: srgb ? VK_FORMAT_R8G8B8A8_SRGB : VK_FORMAT_R8G8B8A8_UNORM, samples: VK_SAMPLE_COUNT_1_BIT,
            usage: vkFlags(VK_IMAGE_USAGE_SAMPLED_BIT, VK_IMAGE_USAGE_TRANSFER_DST_BIT),
            aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), mipLevels: levels.count)
        // Wrapped right away so a failure below still frees the image.
        let texture = VulkanTexture(
            width: width, height: height, format: format, mipLevelCount: levels.count, image: allocation.image,
            memory: allocation.memory, view: allocation.view, deletionQueue: deletionQueue)

        // Every level goes through one staging buffer; the upload blocks until the GPU is done.
        let staging = try createHostBuffer(
            length: levels.reduce(0) { $0 + $1.pixels.count }, usage: vkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT))
        var regions: [VkBufferImageCopy] = []
        var offset = 0
        for (level, mip) in levels.enumerated() {
            mip.pixels.withUnsafeBytes { (staging.mapped + offset).copyMemory(from: $0.baseAddress!, byteCount: $0.count) }
            var region = VkBufferImageCopy()
            region.bufferOffset = VkDeviceSize(offset)
            region.imageSubresource = VkImageSubresourceLayers(
                aspectMask: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), mipLevel: UInt32(level), baseArrayLayer: 0, layerCount: 1)
            region.imageExtent = VkExtent3D(width: UInt32(mip.width), height: UInt32(mip.height), depth: 1)
            regions.append(region)
            offset += mip.pixels.count
        }
        let range = VkImageSubresourceRange(
            aspectMask: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), baseMipLevel: 0, levelCount: UInt32(levels.count),
            baseArrayLayer: 0, layerCount: 1)
        try submitAndWait { cmd in
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
                barrier.image = allocation.image
                barrier.subresourceRange = range
                vkCmdPipelineBarrier(cmd, srcStage, dstStage, 0, 0, nil, 0, nil, 1, &barrier)
            }
            barrier(from: VK_IMAGE_LAYOUT_UNDEFINED, to: VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                    srcAccess: 0, dstAccess: vkFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
                    srcStage: vkFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT), dstStage: vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT))
            vkCmdCopyBufferToImage(
                cmd, staging.buffer, allocation.image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, UInt32(regions.count), regions)
            barrier(from: VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, to: VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                    srcAccess: vkFlags(VK_ACCESS_TRANSFER_WRITE_BIT), dstAccess: vkFlags(VK_ACCESS_SHADER_READ_BIT),
                    srcStage: vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                    dstStage: vkFlags(VK_PIPELINE_STAGE_VERTEX_SHADER_BIT, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT))
        }
        return texture
    }

    /// Records `body` into a one-off command buffer, submits it and waits. For rare uploads
    /// (texture creation); per-frame work goes through the frame's command buffer.
    private func submitAndWait(_ body: (VkCommandBuffer) -> Void) throws {
        var allocInfo = VkCommandBufferAllocateInfo()
        allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO
        allocInfo.commandPool = commandPool
        allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY
        allocInfo.commandBufferCount = 1
        var cmd: VkCommandBuffer?
        try vkCheck(vkAllocateCommandBuffers(device, &allocInfo, &cmd), "vkAllocateCommandBuffers")
        defer { var cmd: VkCommandBuffer? = cmd; vkFreeCommandBuffers(device, commandPool, 1, &cmd) }

        var beginInfo = VkCommandBufferBeginInfo()
        beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
        beginInfo.flags = vkFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
        try vkCheck(vkBeginCommandBuffer(cmd, &beginInfo), "vkBeginCommandBuffer")
        body(cmd!)
        try vkCheck(vkEndCommandBuffer(cmd), "vkEndCommandBuffer")

        var buffers: VkCommandBuffer? = cmd
        var submit = VkSubmitInfo()
        submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO
        submit.commandBufferCount = 1
        try withUnsafePointer(to: &buffers) { buffers in
            submit.pCommandBuffers = buffers
            try vkCheck(vkQueueSubmit(queue, 1, &submit, nil), "vkQueueSubmit")
        }
        try vkCheck(vkQueueWaitIdle(queue), "vkQueueWaitIdle")
    }

    func makeSampler(_ descriptor: SamplerDescriptor) throws -> GPUSampler {
        try samplerCache.sampler(for: descriptor) {
            VulkanSampler(sampler: try Self.createSampler(device: device, descriptor: $0), descriptor: $0)
        }
    }

    func makePipeline(_ descriptor: PipelineDescriptor) throws -> RenderPipeline {
        try createPipeline(descriptor)
    }

    /// `colorPass` replaces the screen pass for `.screen` pipelines: a single-sample render
    /// pass with one color attachment (used by the FSR upscale pass).
    private func createPipeline(_ descriptor: PipelineDescriptor, colorPass: VkRenderPass? = nil) throws -> VulkanPipeline {
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
        multisample.rasterizationSamples = isScreen && colorPass == nil ? samples : VK_SAMPLE_COUNT_1_BIT

        var depthStencil = VkPipelineDepthStencilStateCreateInfo()
        depthStencil.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO
        depthStencil.depthTestEnable = VkBool32(descriptor.depthTest ? VK_TRUE : VK_FALSE)
        depthStencil.depthWriteEnable = VkBool32(descriptor.depthWrite ? VK_TRUE : VK_FALSE)
        depthStencil.depthCompareOp = descriptor.depthCompare.vulkan

        var blendAttachment = VkPipelineColorBlendAttachmentState()
        blendAttachment.colorWriteMask = descriptor.colorWrites ? vkFlags(
            VK_COLOR_COMPONENT_R_BIT, VK_COLOR_COMPONENT_G_BIT, VK_COLOR_COMPONENT_B_BIT, VK_COLOR_COMPONENT_A_BIT) : 0
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
        info.renderPass = isScreen ? colorPass ?? screenRenderPass : depthRenderPass
        info.subpass = 0

        var pipeline: VkPipeline?
        try vkCheck(vkCreateGraphicsPipelines(device, nil, 1, &info, nil, &pipeline), "vkCreateGraphicsPipelines")
        return VulkanPipeline(pipeline!, deletionQueue: deletionQueue)
    }

    func uploadTransient(_ bytes: UnsafeRawBufferPointer) -> TransientBuffer {
        precondition(current != nil, "uploadTransient outside a frame")
        do {
            let allocation = try frames[frameIndex].transient.upload(bytes, alignment: 16)
            return TransientBuffer(buffer: allocation.chunk.buffer, offset: allocation.offset, length: bytes.count)
        } catch {
            preconditionFailure("\(error)")
        }
    }

    // MARK: - Frames

    func beginFrame(framebufferSize: (width: Int, height: Int), renderSize: (width: Int, height: Int)?) throws -> Bool {
        precondition(current == nil, "beginFrame called twice without endFrame")
        guard framebufferSize.width > 0, framebufferSize.height > 0 else { return false }

        if needsSwapchainRebuild || swapchain.map({
            Int($0.extent.width) != framebufferSize.width || Int($0.extent.height) != framebufferSize.height
        }) ?? true {
            try rebuildSwapchain(width: framebufferSize.width, height: framebufferSize.height)
        }
        guard let swapchain else { return false }
        try ensureOffscreenTargets(renderSize)

        let frame = frames[frameIndex]
        var fence: VkFence? = frame.inFlight
        try vkCheck(vkWaitForFences(device, 1, &fence, VkBool32(VK_TRUE), UInt64.max), "vkWaitForFences")

        // This slot's fence covers frame (serial - maxFramesInFlight), so every earlier frame is done too.
        if frameSerial >= UInt64(maxFramesInFlight) {
            destroy(deletionQueue.collect(completedThrough: frameSerial - UInt64(maxFramesInFlight)))
        }
        deletionQueue.setCurrentSerial(frameSerial)
        if let timestampPool, frame.timestampsWritten {
            let count = 2 + frame.timedPasses.count * 2
            var ticks = [UInt64](repeating: 0, count: count)
            let result = vkGetQueryPoolResults(
                device, timestampPool, timestampBase, UInt32(count), count * MemoryLayout<UInt64>.size, &ticks, 8,
                vkFlags(VK_QUERY_RESULT_64_BIT))
            if result == VK_SUCCESS {
                let seconds = { (start: Int) in Double(ticks[start + 1] &- ticks[start]) * self.timestampPeriod * 1e-9 }
                if ticks[1] > ticks[0] { gpuFrameTime = seconds(0) }
                gpuPassTimes = frame.timedPasses.indices.compactMap { i in
                    ticks[3 + i * 2] > ticks[2 + i * 2] ? GPUPassTime(name: frame.timedPasses[i], seconds: seconds(2 + i * 2)) : nil
                }
            }
        }
        frames[frameIndex].timedPasses = []
        resolveOcclusionQueries(frame.occlusion)

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
            vkCmdResetQueryPool(cmd, timestampPool, timestampBase, UInt32(timestampsPerFrame))
            vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, timestampPool, timestampBase)
        }
        if frame.occlusionQueriesToReset > 0 {
            vkCmdResetQueryPool(cmd, occlusionPool, occlusionQueryBase, UInt32(frame.occlusionQueriesToReset))
            frames[frameIndex].occlusionQueriesToReset = 0
        }
        frame.transient.reset()
        frame.descriptors.reset()

        current = (imageIndex, captureNextFrame && (renderSize != nil || swapchain.supportsReadback), renderSize != nil)
        captureNextFrame = false
        return true
    }

    private var occlusionQueryBase: UInt32 { UInt32(frameIndex * maxOcclusionQueriesPerFrame) }
    private var timestampBase: UInt32 { UInt32(frameIndex * timestampsPerFrame) }

    /// Called once the slot's fence has signaled: hands its results to their query sets.
    private func resolveOcclusionQueries(_ batch: OcclusionQueryBatch) {
        guard batch.count > 0 else { return }
        var results = [UInt64](repeating: 0, count: batch.count)
        let status = vkGetQueryPoolResults(
            device, occlusionPool, occlusionQueryBase, UInt32(batch.count), results.count * MemoryLayout<UInt64>.size,
            &results, VkDeviceSize(MemoryLayout<UInt64>.size), vkFlags(VK_QUERY_RESULT_64_BIT))
        // Unavailable results (shouldn't happen after the fence) count as visible, the safe answer.
        batch.resolve { status != VK_SUCCESS || results[$0] != 0 }
    }

    func beginDepthPass(target: GPUTexture, clearDepth: Float) -> RenderPass {
        let texture = target as! VulkanTexture
        var clear = VkClearValue()
        clear.depthStencil = VkClearDepthStencilValue(depth: clearDepth, stencil: 0)
        let extent = VkExtent2D(width: UInt32(texture.width), height: UInt32(texture.height))
        return beginPass(
            renderPass: depthRenderPass, framebuffer: texture.framebuffer!, extent: extent, clearValues: [clear], timedAs: "depth")
    }

    func beginScreenPass(clearColor: Vec4, clearDepth: Float) -> RenderPass {
        guard let current, let swapchain else { preconditionFailure("beginScreenPass outside a frame") }
        if current.offscreen, let offscreen {
            return beginPass(
                renderPass: offscreenRenderPass, framebuffer: offscreen.framebuffer, extent: offscreen.extent,
                clearValues: Self.colorDepthClear(clearColor, clearDepth), timedAs: "scene",
                occlusionQueries: true)
        }
        return beginPass(
            renderPass: screenRenderPass, framebuffer: swapchain.framebuffers[Int(current.imageIndex)],
            extent: swapchain.extent, clearValues: Self.colorDepthClear(clearColor, clearDepth), timedAs: "scene",
                occlusionQueries: true)
    }

    func beginWindowPass() -> RenderPass {
        guard let current, let swapchain else { preconditionFailure("beginWindowPass outside a frame") }
        guard current.offscreen, let offscreen else {
            guard let currentPass else { preconditionFailure("beginWindowPass must follow beginScreenPass") }
            return currentPass
        }
        endPass()
        let image = (width: Int(offscreen.extent.width), height: Int(offscreen.extent.height))
        let window = (width: Int(swapchain.extent.width), height: Int(swapchain.extent.height))
        let rect = letterboxRect(image: image, window: window)
        let upscaled = upscale(offscreen, to: VkExtent2D(width: UInt32(rect.width), height: UInt32(rect.height)))

        let pass = beginPass(
            renderPass: screenRenderPass, framebuffer: swapchain.framebuffers[Int(current.imageIndex)],
            extent: swapchain.extent, clearValues: Self.colorDepthClear(Vec4(0, 0, 0, 1), 1), timedAs: "window")
            as! VulkanRenderPass
        if let upscaled, let rcasPipeline {
            // Sharpen the upscaled image 1:1 into its pixel-aligned rectangle.
            pass.setPipeline(rcasPipeline)
            var set: VkDescriptorSet? = upscaled
            vkCmdBindDescriptorSets(pass.commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 1, 1, &set, 0, nil)
            setViewport(pass.commandBuffer, x: rect.x, y: rect.y, width: rect.width, height: rect.height)
            pass.setPushConstants(RcasConstants(rect: rect, sharpness: upscaler.rcasSharpness))
            pass.draw(vertexCount: 3)
            setViewport(pass.commandBuffer, x: 0, y: 0, width: window.width, height: window.height)
        } else {
            pass.setPipeline(blitPipeline)
            var set: VkDescriptorSet? = offscreen.descriptorSet
            vkCmdBindDescriptorSets(pass.commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 1, 1, &set, 0, nil)
            pass.setPushConstants(letterboxScale(image: image, window: window))
            pass.draw(vertexCount: 3)
        }
        return pass
    }

    /// Flipped like every pass's viewport (y-up clip space), covering the given window pixels.
    private func setViewport(_ cmd: VkCommandBuffer, x: Int, y: Int, width: Int, height: Int) {
        var viewport = VkViewport(
            x: Float(x), y: Float(y + height), width: Float(width), height: -Float(height), minDepth: 0, maxDepth: 1)
        vkCmdSetViewport(cmd, 0, 1, &viewport)
    }

    /// Records the FSR 1 upscale pass from the scene image into a texture of `size`. Returns
    /// the descriptor set for sampling the result, or nil for bilinear.
    private func upscale(_ offscreen: OffscreenTargets, to size: VkExtent2D) -> VkDescriptorSet? {
        guard case .fsr1 = upscaler, let easuPipeline, let source = offscreen.unormDescriptorSet else { return nil }
        let targets: UpscaleTargets
        do {
            targets = try ensureUpscaleTargets(input: offscreen.extent, output: size)
        } catch {
            print("\(upscaler) unavailable, using bilinear: \(error)")
            upscaler = .bilinear
            return nil
        }
        let pass = beginPass(
            renderPass: upscaleRenderPass!, framebuffer: targets.framebuffer, extent: size, clearValues: [], timedAs: "upscale")
            as! VulkanRenderPass
        pass.setPipeline(easuPipeline)
        var set: VkDescriptorSet? = source
        vkCmdBindDescriptorSets(pass.commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 1, 1, &set, 0, nil)
        pass.setPushConstants(EasuConstants(
            input: (Int(offscreen.extent.width), Int(offscreen.extent.height)), output: (Int(size.width), Int(size.height))))
        pass.draw(vertexCount: 3)
        endPass()
        return targets.descriptorSet
    }

    private func ensureUpscaleTargets(input: VkExtent2D, output: VkExtent2D) throws -> UpscaleTargets {
        if let targets = upscaleTargets, targets.input.width == input.width, targets.input.height == input.height,
           targets.output.width == output.width, targets.output.height == output.height {
            return targets
        }
        if let old = upscaleTargets {
            vkDeviceWaitIdle(device)  // earlier frames may still read it
            destroy(old)
            upscaleTargets = nil
        }
        let image = try createImage(
            extent: output, format: unormFormat!, samples: VK_SAMPLE_COUNT_1_BIT,
            usage: vkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, VK_IMAGE_USAGE_SAMPLED_BIT),
            aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT))
        let targets = UpscaleTargets(
            input: input, output: output, image: image,
            framebuffer: try createFramebuffer(renderPass: upscaleRenderPass!, attachments: [image.view], extent: output),
            descriptorSet: try makeTextureDescriptorSet(view: image.view))
        upscaleTargets = targets
        return targets
    }

    private func destroy(_ targets: UpscaleTargets) {
        var set: VkDescriptorSet? = targets.descriptorSet
        vkFreeDescriptorSets(device, descriptorPool, 1, &set)
        vkDestroyFramebuffer(device, targets.framebuffer, nil)
        vkDestroyImageView(device, targets.image.view, nil)
        vkDestroyImage(device, targets.image.image, nil)
        vkFreeMemory(device, targets.image.memory, nil)
    }

    private static func colorDepthClear(_ color: Vec4, _ depth: Float) -> [VkClearValue] {
        var clearValues = [VkClearValue(), VkClearValue()]
        clearValues[0].color.float32 = (color.x, color.y, color.z, color.w)
        clearValues[1].depthStencil = VkClearDepthStencilValue(depth: depth, stencil: 0)
        return clearValues
    }

    private func beginPass(renderPass: VkRenderPass, framebuffer: VkFramebuffer, extent: VkExtent2D,
                           clearValues: [VkClearValue], timedAs name: String, occlusionQueries: Bool = false) -> RenderPass {
        precondition(current != nil, "Render pass started outside a frame")
        precondition(!inRenderPass, "Previous pass was not ended")
        let frame = frames[frameIndex]
        let cmd = frame.commandBuffer
        if let timestampPool, frame.timedPasses.count < maxTimedPasses {
            let query = timestampBase + 2 + UInt32(frame.timedPasses.count * 2)
            vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, timestampPool, query)
            frames[frameIndex].timedPasses.append(name)
            timedPassEnd = query + 1
        }

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

        // Flip Y in every pass so clip space is y-up and textures are laid out like Metal's.
        let width = Float(extent.width), height = Float(extent.height)
        var viewport = VkViewport(x: 0, y: height, width: width, height: -height, minDepth: 0, maxDepth: 1)
        vkCmdSetViewport(cmd, 0, 1, &viewport)
        var scissor = VkRect2D(offset: VkOffset2D(x: 0, y: 0), extent: extent)
        vkCmdSetScissor(cmd, 0, 1, &scissor)

        let pass = VulkanRenderPass(
            commandBuffer: cmd, device: device, layout: pipelineLayout, transient: frame.transient, descriptors: frame.descriptors,
            occlusion: occlusionQueries ? (occlusionPool, occlusionQueryBase, frame.occlusion) : nil)
        currentPass = pass
        return pass
    }

    func endPass() {
        guard inRenderPass else { return }
        currentPass?.occlusion?.batch.checkClosed()
        vkCmdEndRenderPass(frames[frameIndex].commandBuffer)
        if let timestampPool, let query = timedPassEnd {
            vkCmdWriteTimestamp(frames[frameIndex].commandBuffer, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, timestampPool, query)
            timedPassEnd = nil
        }
        currentPass = nil
    }

    func endFrame() throws -> Image? {
        guard let (imageIndex, capture, isOffscreen) = current, let swapchain else { return nil }
        endPass()
        current = nil
        let frame = frames[frameIndex]
        let cmd = frame.commandBuffer

        var readback: (buffer: VulkanBuffer, extent: VkExtent2D)?
        if capture, isOffscreen, !captureWindow, let offscreen {
            // The window pass sampled it last.
            readback = (try recordReadback(
                cmd: cmd, image: offscreen.resolved.image, extent: offscreen.extent,
                layout: VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, stage: vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
                access: vkFlags(VK_ACCESS_SHADER_READ_BIT)), offscreen.extent)
        } else if capture {
            readback = (try recordReadback(
                cmd: cmd, image: swapchain.images[Int(imageIndex)], extent: swapchain.extent,
                layout: VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, stage: vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                access: vkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)), swapchain.extent)
        }
        if let timestampPool {
            vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, timestampPool, timestampBase + 1)
            frames[frameIndex].timestampsWritten = true
        }
        frames[frameIndex].occlusionQueriesToReset = frame.occlusion.count
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
            image = try readImage(from: readback.buffer, extent: readback.extent)
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
        vkDestroyQueryPool(device, occlusionPool, nil)
        if let swapchain { destroy(swapchain, includingHandle: true) }
        swapchain = nil
        if let offscreen { destroy(offscreen) }
        offscreen = nil
        if let upscaleTargets { destroy(upscaleTargets) }
        upscaleTargets = nil
        easuPipeline = nil
        rcasPipeline = nil
        if let upscaleRenderPass { vkDestroyRenderPass(device, upscaleRenderPass, nil) }
        for frame in frames {
            vkDestroySemaphore(device, frame.imageAvailable, nil)
            vkDestroyFence(device, frame.inFlight, nil)
        }
        for frame in frames { frame.descriptors.destroy() }
        frames.removeAll()
        vkDestroyCommandPool(device, commandPool, nil)
        vkDestroySampler(device, comparisonSampler, nil)
        vkDestroySampler(device, linearSampler, nil)
        for sampler in samplerCache.all { vkDestroySampler(device, sampler.sampler, nil) }
        samplerCache.removeAll()
        vkDestroyDescriptorPool(device, descriptorPool, nil)
        vkDestroyPipelineLayout(device, pipelineLayout, nil)
        vkDestroyDescriptorSetLayout(device, uniformSetLayout, nil)
        vkDestroyDescriptorSetLayout(device, textureSetLayout, nil)
        vkDestroyDescriptorSetLayout(device, userSetLayout, nil)
        vkDestroyRenderPass(device, screenRenderPass, nil)
        vkDestroyRenderPass(device, offscreenRenderPass, nil)
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
        let portabilitySubset = available.contains(where: { vkString($0.extensionName) == "VK_KHR_portability_subset" })
        if portabilitySubset {
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
        #if os(macOS)
        if portabilitySubset {
            // Portability features are off unless requested; enable everything supported
            // (shadow maps need mutableComparisonSamplers).
            var portability = VkPhysicalDevicePortabilitySubsetFeaturesKHR()
            portability.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PORTABILITY_SUBSET_FEATURES_KHR
            var features = VkPhysicalDeviceFeatures2()
            features.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2
            withUnsafeMutablePointer(to: &portability) { pointer in
                features.pNext = UnsafeMutableRawPointer(pointer)
                vkGetPhysicalDeviceFeatures2(physicalDevice, &features)
            }
            portability.pNext = nil
            info.pNext = UnsafeRawPointer(arena.store(portability))
        }
        #endif

        var device: VkDevice?
        try vkCheck(vkCreateDevice(physicalDevice, &info, nil, &device), "vkCreateDevice")
        return device!
    }

    /// The scene pass. `offscreen` leaves the final image shader-readable (for the window pass
    /// and readback) instead of presentable; both variants are render-pass compatible.
    private static func createScreenRenderPass(device: VkDevice, colorFormat: VkFormat, samples: VkSampleCountFlagBits,
                                               offscreen: Bool = false) throws -> VkRenderPass {
        let arena = Arena()
        let multisampled = samples != VK_SAMPLE_COUNT_1_BIT
        let finalLayout = offscreen ? VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL : VK_IMAGE_LAYOUT_PRESENT_SRC_KHR

        var color = VkAttachmentDescription()
        color.format = colorFormat
        color.samples = samples
        color.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR
        // The multisampled image is resolved, never stored.
        color.storeOp = multisampled ? VK_ATTACHMENT_STORE_OP_DONT_CARE : VK_ATTACHMENT_STORE_OP_STORE
        color.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        color.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        color.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        color.finalLayout = multisampled ? VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL : finalLayout

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
            resolve.finalLayout = finalLayout
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
        // Dependencies are part of render-pass compatibility, so both variants use the set the
        // offscreen pass needs (slightly conservative for the window pass):
        // the previous frame's window pass and readback read the image this pass overwrites…
        dependency.srcStageMask |= vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT)
        // …and this pass's result is sampled / read back later in the frame.
        var after = VkSubpassDependency()
        after.srcSubpass = 0
        after.dstSubpass = UInt32.max
        after.srcStageMask = vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
        after.srcAccessMask = vkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
        after.dstStageMask = vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT)
        after.dstAccessMask = vkFlags(VK_ACCESS_SHADER_READ_BIT, VK_ACCESS_TRANSFER_READ_BIT)
        let dependencies = [dependency, after]

        return try createRenderPass(device: device, attachments: attachments, subpass: subpass, dependencies: dependencies)
    }

    /// One single-sample color attachment, fully overwritten, then sampled by the window pass.
    private static func createUpscaleRenderPass(device: VkDevice, format: VkFormat) throws -> VkRenderPass {
        let arena = Arena()
        var color = VkAttachmentDescription()
        color.format = format
        color.samples = VK_SAMPLE_COUNT_1_BIT
        color.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        color.storeOp = VK_ATTACHMENT_STORE_OP_STORE
        color.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE
        color.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE
        color.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
        color.finalLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL

        var subpass = VkSubpassDescription()
        subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS
        subpass.colorAttachmentCount = 1
        subpass.pColorAttachments = arena.store(
            VkAttachmentReference(attachment: 0, layout: VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL))

        // The previous frame's window pass read this image; this pass's result is read next.
        var before = VkSubpassDependency()
        before.srcSubpass = UInt32.max  // VK_SUBPASS_EXTERNAL
        before.dstSubpass = 0
        before.srcStageMask = vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
        before.srcAccessMask = 0
        before.dstStageMask = vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
        before.dstAccessMask = vkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
        var after = VkSubpassDependency()
        after.srcSubpass = 0
        after.dstSubpass = UInt32.max
        after.srcStageMask = vkFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT)
        after.srcAccessMask = vkFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT)
        after.dstStageMask = vkFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT)
        after.dstAccessMask = vkFlags(VK_ACCESS_SHADER_READ_BIT)
        return try createRenderPass(device: device, attachments: [color], subpass: subpass, dependencies: [before, after])
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

    /// Bilinear, clamp-to-edge: used to scale the offscreen scene image into the window.
    private static func createLinearSampler(device: VkDevice) throws -> VkSampler {
        var info = VkSamplerCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO
        info.magFilter = VK_FILTER_LINEAR
        info.minFilter = VK_FILTER_LINEAR
        info.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST
        info.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
        info.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
        info.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
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
                return (chunk, chunk.buffer.mapped!)
            }
            frames.append(FrameSync(
                commandBuffer: commandBuffer!, imageAvailable: try createSemaphore(), inFlight: fence!, transient: transient,
                descriptors: VulkanDescriptorArena(device: device, layout: userSetLayout)))
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

    /// FIFO (vsync, always supported), or without vsync MAILBOX (uncapped, no tearing) or
    /// IMMEDIATE (uncapped, may tear), whichever the surface supports.
    private func presentMode() throws -> VkPresentModeKHR {
        guard !vsync else { return VK_PRESENT_MODE_FIFO_KHR }
        let modes: [VkPresentModeKHR] = try vkEnumerate("vkGetPhysicalDeviceSurfacePresentModesKHR") {
            vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, $0, $1)
        }
        if let mode = [VK_PRESENT_MODE_MAILBOX_KHR, VK_PRESENT_MODE_IMMEDIATE_KHR].first(where: modes.contains) {
            return mode
        }
        print("This surface only supports vsync (FIFO) presentation; keeping vsync on")
        return VK_PRESENT_MODE_FIFO_KHR
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
        info.presentMode = try presentMode()
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

    // MARK: - Offscreen scene targets

    /// Creates, resizes or drops the offscreen targets to match `renderSize`.
    private func ensureOffscreenTargets(_ renderSize: (width: Int, height: Int)?) throws {
        let extent = renderSize.map { VkExtent2D(width: UInt32($0.width), height: UInt32($0.height)) }
        if offscreen?.extent.width == extent?.width && offscreen?.extent.height == extent?.height { return }
        if let old = offscreen {
            vkDeviceWaitIdle(device)
            destroy(old)
            offscreen = nil
        }
        guard let extent else { return }

        let resolved = try createImage(
            extent: extent, format: surfaceFormat.format, samples: VK_SAMPLE_COUNT_1_BIT,
            usage: vkFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT, VK_IMAGE_USAGE_SAMPLED_BIT, VK_IMAGE_USAGE_TRANSFER_SRC_BIT),
            aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT),
            flags: unormFormat != nil ? vkFlags(VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT) : 0)
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
        let attachments = msaaColor.map { [$0.view, depth.view, resolved.view] } ?? [resolved.view, depth.view]
        let framebuffer = try createFramebuffer(renderPass: offscreenRenderPass, attachments: attachments, extent: extent)

        let unormView = try unormFormat.map {
            try createImageView(resolved.image, format: $0, aspect: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT))
        }
        offscreen = OffscreenTargets(
            extent: extent, depth: depth, msaaColor: msaaColor, resolved: resolved, framebuffer: framebuffer,
            descriptorSet: try makeTextureDescriptorSet(view: resolved.view),
            unormView: unormView, unormDescriptorSet: try unormView.map { try makeTextureDescriptorSet(view: $0) })
    }

    /// A set-1 binding of `view` (in shader-read layout) with the linear sampler.
    private func makeTextureDescriptorSet(view: VkImageView) throws -> VkDescriptorSet {
        let set = try allocateDescriptorSet(layout: textureSetLayout)
        var imageInfo = VkDescriptorImageInfo(
            sampler: linearSampler, imageView: view, imageLayout: VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)
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
        return set
    }

    private func destroy(_ targets: OffscreenTargets) {
        for set in [targets.descriptorSet, targets.unormDescriptorSet].compactMap({ $0 }) {
            var set: VkDescriptorSet? = set
            vkFreeDescriptorSets(device, descriptorPool, 1, &set)
        }
        if let unormView = targets.unormView { vkDestroyImageView(device, unormView, nil) }
        vkDestroyFramebuffer(device, targets.framebuffer, nil)
        for allocation in [targets.resolved, targets.depth] + [targets.msaaColor].compactMap({ $0 }) {
            vkDestroyImageView(device, allocation.view, nil)
            vkDestroyImage(device, allocation.image, nil)
            vkFreeMemory(device, allocation.memory, nil)
        }
    }

    private func createImage(extent: VkExtent2D, format: VkFormat, samples: VkSampleCountFlagBits,
                             usage: VkImageUsageFlags, aspect: VkImageAspectFlags,
                             flags: VkImageCreateFlags = 0, mipLevels: Int = 1) throws -> ImageAllocation {
        var info = VkImageCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO
        info.flags = flags
        info.imageType = VK_IMAGE_TYPE_2D
        info.format = format
        info.extent = VkExtent3D(width: extent.width, height: extent.height, depth: 1)
        info.mipLevels = UInt32(mipLevels)
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
        // Attachments that never leave the render pass can live in lazily allocated memory
        // (tile memory on TBDR GPUs, e.g. memoryless textures under MoltenVK).
        let lazy = usage & vkFlags(VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT) != 0
            ? try? allocateMemory(requirements, properties: vkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT))
            : nil
        let memory = try lazy ?? allocateMemory(requirements, properties: vkFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT))
        try vkCheck(vkBindImageMemory(device, image, memory, 0), "vkBindImageMemory")
        let view = try createImageView(image!, format: format, aspect: aspect, mipLevels: mipLevels)
        return ImageAllocation(image: image!, memory: memory, view: view)
    }

    private func createImageView(_ image: VkImage, format: VkFormat, aspect: VkImageAspectFlags,
                                 mipLevels: Int = 1) throws -> VkImageView {
        var info = VkImageViewCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO
        info.image = image
        info.viewType = VK_IMAGE_VIEW_TYPE_2D
        info.format = format
        info.subresourceRange = VkImageSubresourceRange(
            aspectMask: aspect, baseMipLevel: 0, levelCount: UInt32(mipLevels), baseArrayLayer: 0, layerCount: 1)
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

    /// A buffer and its memory, not yet owned by a wrapper or the deletion queue.
    private struct RawBuffer {
        var buffer: VkBuffer
        var memory: VkDeviceMemory
        var mapped: UnsafeMutableRawPointer?
    }

    private func destroy(_ raw: RawBuffer) {
        vkDestroyBuffer(device, raw.buffer, nil)
        vkFreeMemory(device, raw.memory, nil)
    }

    private func createRawBuffer(length: Int, usage: VkBufferUsageFlags, properties: VkMemoryPropertyFlags, mapped map: Bool) throws -> RawBuffer {
        var info = VkBufferCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO
        info.size = VkDeviceSize(length)
        info.usage = usage
        info.sharingMode = VK_SHARING_MODE_EXCLUSIVE
        var buffer: VkBuffer?
        try vkCheck(vkCreateBuffer(device, &info, nil, &buffer), "vkCreateBuffer")

        var requirements = VkMemoryRequirements()
        vkGetBufferMemoryRequirements(device, buffer, &requirements)
        let memory: VkDeviceMemory
        do {
            memory = try allocateMemory(requirements, properties: properties)
        } catch {
            vkDestroyBuffer(device, buffer, nil)
            throw error
        }
        var mapped: UnsafeMutableRawPointer?
        do {
            try vkCheck(vkBindBufferMemory(device, buffer, memory, 0), "vkBindBufferMemory")
            if map { try vkCheck(vkMapMemory(device, memory, 0, VkDeviceSize(length), 0, &mapped), "vkMapMemory") }
        } catch {
            vkDestroyBuffer(device, buffer, nil)
            vkFreeMemory(device, memory, nil)
            throw error
        }
        return RawBuffer(buffer: buffer!, memory: memory, mapped: mapped)
    }

    /// Persistently mapped, host-visible buffer (per-frame ring chunks, readback).
    private func createHostBuffer(length: Int, usage: VkBufferUsageFlags) throws -> VulkanBuffer {
        let raw = try createRawBuffer(
            length: length, usage: usage,
            properties: vkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, VK_MEMORY_PROPERTY_HOST_COHERENT_BIT), mapped: true)
        return VulkanBuffer(buffer: raw.buffer, memory: raw.memory, length: length, mapped: raw.mapped, deletionQueue: deletionQueue)
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
                if let set {
                    var set: VkDescriptorSet? = set
                    vkFreeDescriptorSets(device, descriptorPool, 1, &set)
                }
                if let framebuffer { vkDestroyFramebuffer(device, framebuffer, nil) }
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

    /// Copies `image` (currently in `layout`, last used at `stage` with `access`) into the
    /// readback buffer and returns it to `layout`.
    private func recordReadback(cmd: VkCommandBuffer, image: VkImage, extent: VkExtent2D, layout: VkImageLayout,
                                stage: VkPipelineStageFlags, access: VkAccessFlags) throws -> VulkanBuffer {
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

        barrier(from: layout, to: VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                srcAccess: access, dstAccess: vkFlags(VK_ACCESS_TRANSFER_READ_BIT),
                srcStage: stage, dstStage: vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT))

        var region = VkBufferImageCopy()
        region.imageSubresource = VkImageSubresourceLayers(
            aspectMask: vkFlags(VK_IMAGE_ASPECT_COLOR_BIT), mipLevel: 0, baseArrayLayer: 0, layerCount: 1)
        region.imageExtent = VkExtent3D(width: extent.width, height: extent.height, depth: 1)
        vkCmdCopyImageToBuffer(cmd, image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, readback.buffer, 1, &region)

        barrier(from: VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, to: layout,
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
        let bytes = UnsafeRawBufferPointer(start: buffer.mapped!, count: width * height * 4)
        let isBGRA = surfaceFormat.format == VK_FORMAT_B8G8R8A8_SRGB || surfaceFormat.format == VK_FORMAT_B8G8R8A8_UNORM
        if isBGRA {
            return Image(width: width, height: height, bgra: bytes, bytesPerRow: width * 4)
        }
        return Image(width: width, height: height, pixels: Array(bytes))
    }
}


final class VulkanRenderPass: RenderPass {
    let commandBuffer: VkCommandBuffer
    private let device: VkDevice
    private let layout: VkPipelineLayout
    private let transient: TransientRing<VulkanTransientChunk>
    private let descriptors: VulkanDescriptorArena
    private var userBindings = VulkanUserBindings()
    /// The frame slot's query range (screen pass only).
    let occlusion: (pool: VkQueryPool, base: UInt32, batch: OcclusionQueryBatch)?

    init(commandBuffer: VkCommandBuffer, device: VkDevice, layout: VkPipelineLayout,
         transient: TransientRing<VulkanTransientChunk>, descriptors: VulkanDescriptorArena,
         occlusion: (pool: VkQueryPool, base: UInt32, batch: OcclusionQueryBatch)?) {
        self.commandBuffer = commandBuffer
        self.device = device
        self.layout = layout
        self.transient = transient
        self.descriptors = descriptors
        self.occlusion = occlusion
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

    func setUniformBuffer(_ buffer: GPUBuffer, offset: Int, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(offset % uniformBufferOffsetAlignment == 0, "Uniform buffer offset must be a multiple of \(uniformBufferOffsetAlignment)")
        precondition(offset < buffer.length, "Uniform buffer offset is past the end of the buffer")
        userBindings.bindUniform(
            buffer: (buffer as! VulkanBuffer).buffer, offset: offset, range: min(buffer.length - offset, maxUniformBufferSize),
            index: index)
    }

    func setUniformData(_ bytes: UnsafeRawBufferPointer, index: Int, stage: ShaderStage) {
        precondition(uniformBufferIndices.contains(index), "Uniform buffer index \(index) is outside \(uniformBufferIndices)")
        precondition(bytes.count <= maxUniformBufferSize, "Uniform data exceeds \(maxUniformBufferSize) bytes")
        let allocation = upload(bytes, alignment: uniformBufferOffsetAlignment, reserve: 0)
        userBindings.bindUniform(
            buffer: allocation.chunk.buffer.buffer, offset: allocation.offset, range: max(bytes.count, 1), index: index)
    }

    func setTexture(_ texture: GPUTexture, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Texture index \(index) is outside \(textureIndices)")
        let texture = texture as! VulkanTexture
        precondition(!texture.format.isDepth, "Depth textures are bound with setTexture(_:)")
        userBindings.bindTexture(texture.view, index: index)
    }

    func setSampler(_ sampler: GPUSampler, index: Int, stage: ShaderStage) {
        precondition(textureIndices.contains(index), "Sampler index \(index) is outside \(textureIndices)")
        userBindings.bindSampler((sampler as! VulkanSampler).sampler, index: index)
    }

    /// Writes and binds a new set 2 if any binding changed since the last draw.
    private func flushUserBindings() {
        guard userBindings.isDirty else { return }
        do {
            var set: VkDescriptorSet? = try userBindings.makeSet(from: descriptors, device: device)
            vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, layout, 2, 1, &set, 0, nil)
        } catch {
            preconditionFailure("\(error)")
        }
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
        flushUserBindings()
        vkCmdDraw(commandBuffer, UInt32(vertexCount), UInt32(instanceCount), UInt32(firstVertex), 0)
    }

    func drawIndexed(indexCount: Int, instanceCount: Int, firstIndex: Int) {
        flushUserBindings()
        vkCmdDrawIndexed(commandBuffer, UInt32(indexCount), UInt32(instanceCount), UInt32(firstIndex), 0, 0)
    }

    func beginOcclusionQuery(_ set: OcclusionQuerySet, index: Int) {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.batch.begin(set, index: index)
        vkCmdBeginQuery(commandBuffer, occlusion.pool, occlusion.base + UInt32(slot), 0)
    }

    func endOcclusionQuery() {
        guard let occlusion else { preconditionFailure("Occlusion queries are only supported in the screen pass") }
        let slot = occlusion.batch.end()
        vkCmdEndQuery(commandBuffer, occlusion.pool, occlusion.base + UInt32(slot))
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
