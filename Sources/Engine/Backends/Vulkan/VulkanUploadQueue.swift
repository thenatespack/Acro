#if ENGINE_VULKAN
import CVulkan
import Foundation

/// The copies that fill new static resources (`makeBuffer(bytes:)`, `makeTexture(levels:)`)
/// and the first layout transitions of new images, recorded into a command buffer of their own
/// instead of a blocking one-off submit.
///
/// - **Recording:** any thread may record (textures are made on loader threads too). The data is
///   copied into staging memory first (outside the lock), then the copy and its barriers are
///   recorded into the open batch under the lock; each batch has its own command pool, so the
///   lock is the only synchronization the pool needs.
/// - **Submission:** the device closes the open batch and submits it on the render thread right
///   before the frame's command buffer (`endFrame`), and before any other submission (one-off
///   submits, `waitIdle`). Everything recorded before a resource is handed out is therefore
///   earlier in queue submission order than any command that uses it, and the batch ends with a
///   barrier from its transfers to every later command, so first use is ordered after the copy.
/// - **Staging memory** is sub-allocated from host-visible chunks (large uploads get a buffer of
///   their own) and given back when the frame that submitted the batch has completed (its fence,
///   which also covers earlier submissions), or after a device-wide wait.
/// - **Lifetime:** a resource dropped before its upload ran is destroyed by the deletion queue
///   after the frame it was released in, which is never earlier than the batch holding its copy.
final class VulkanUploadQueue: @unchecked Sendable {
    struct StagingBuffer {
        var buffer: VkBuffer
        var memory: VkDeviceMemory
        var mapped: UnsafeMutableRawPointer
    }

    /// A chunk of staging memory handed out front to back; reset once no batch uses it.
    fileprivate final class Chunk {
        let staging: StagingBuffer
        let capacity: Int
        var used = 0
        /// Staged uploads whose batch hasn't completed.
        var users = 0

        init(staging: StagingBuffer, capacity: Int) {
            self.staging = staging
            self.capacity = capacity
        }
    }

    fileprivate enum Owner {
        case chunk(Chunk)
        case dedicated(StagingBuffer)
    }

    /// Where an upload's bytes wait for the GPU copy: `buffer` at `offset`.
    struct Staging {
        let buffer: VkBuffer
        let offset: Int
        fileprivate let owner: Owner
    }

    private final class Batch {
        let pool: VkCommandPool
        let commandBuffer: VkCommandBuffer
        var staging: [Owner] = []
        var uploads = 0
        /// The frame whose fence covers this batch once submitted.
        var serial: UInt64 = 0

        init(pool: VkCommandPool, commandBuffer: VkCommandBuffer) {
            self.pool = pool
            self.commandBuffer = commandBuffer
        }
    }

    /// Counters for tests and the profiler overlay.
    struct Statistics: Equatable {
        /// Uploads recorded since the device was made.
        var uploads = 0
        /// Batches submitted since the device was made.
        var batches = 0
        /// Uploads recorded but not submitted yet.
        var openUploads = 0
        /// Batches submitted whose staging memory hasn't been given back.
        var batchesInFlight = 0
        /// Staging chunks alive (in use or kept for reuse) and dedicated staging buffers in flight.
        var chunks = 0
        var dedicatedBuffers = 0
    }

    private let device: VkDevice
    private let queueFamily: UInt32
    private let memoryProperties: VkPhysicalDeviceMemoryProperties
    /// Bytes per staging chunk; uploads over half of it get their own buffer.
    let chunkSize: Int
    /// Idle chunks kept for reuse (the rest are freed).
    private let maxIdleChunks = 4
    private let lock = NSLock()
    private var current: Chunk?
    private var idleChunks: [Chunk] = []
    private var open: Batch?
    private var inFlight: [Batch] = []
    private var idleBatches: [Batch] = []
    private var stats = Statistics()
    private var isShutDown = false

    /// Staging memory is made here rather than by the (main-actor) device, since `stage` runs
    /// on any thread.
    init(device: VkDevice, queueFamily: UInt32, memoryProperties: VkPhysicalDeviceMemoryProperties, chunkSize: Int = 8 << 20) {
        self.device = device
        self.queueFamily = queueFamily
        self.memoryProperties = memoryProperties
        self.chunkSize = chunkSize
    }

    var statistics: Statistics { lock.withLock { stats } }

    // MARK: Recording (any thread)

    /// Staging memory for `length` bytes, filled by `write` (called without the lock held).
    /// Hand it to `record`, or to `discard` if the upload is abandoned.
    func stage(_ length: Int, write: (UnsafeMutableRawPointer) -> Void) throws -> Staging {
        // 16-byte offsets suit every format's texel or block size and the 4-byte copy alignment.
        let size = (max(length, 1) + 15) & ~15
        if size > chunkSize / 2 {
            let buffer = try createStaging(size)
            write(buffer.mapped)
            lock.withLock { stats.dedicatedBuffers += 1 }
            return Staging(buffer: buffer.buffer, offset: 0, owner: .dedicated(buffer))
        }
        let (chunk, offset) = try lock.withLock { () throws -> (Chunk, Int) in
            if let chunk = current, chunk.used + size <= chunk.capacity {
                defer { chunk.used += size; chunk.users += 1 }
                return (chunk, chunk.used)
            }
            if let full = current {
                current = nil
                retire(full)
            }
            let chunk: Chunk
            if let idle = idleChunks.popLast() {
                chunk = idle
            } else {
                chunk = Chunk(staging: try createStaging(chunkSize), capacity: chunkSize)
                stats.chunks += 1
            }
            current = chunk
            chunk.used = size
            chunk.users = 1
            return (chunk, 0)
        }
        write(chunk.staging.mapped + offset)
        return Staging(buffer: chunk.staging.buffer, offset: offset, owner: .chunk(chunk))
    }

    /// Records `body` (copies out of `staging`, layout transitions of new images) into the open
    /// batch, which keeps `staging` until it has run.
    func record(_ staging: Staging?, _ body: (VkCommandBuffer) -> Void) throws {
        try lock.withLock {
            precondition(!isShutDown, "Vulkan upload after the device shut down")
            let batch: Batch
            if let open {
                batch = open
            } else {
                batch = try idleBatches.popLast() ?? makeBatch()
                var info = VkCommandBufferBeginInfo()
                info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
                info.flags = vkFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
                try vkCheck(vkBeginCommandBuffer(batch.commandBuffer, &info), "vkBeginCommandBuffer")
                open = batch
            }
            body(batch.commandBuffer)
            if let staging { batch.staging.append(staging.owner) }
            batch.uploads += 1
            stats.uploads += 1
            stats.openUploads += 1
        }
    }

    /// Gives back staging memory of an upload that won't be recorded.
    func discard(_ staging: Staging) {
        lock.withLock { release(staging.owner) }
    }

    // MARK: Submission and completion (render thread)

    /// Ends the open batch (if any) with a barrier from its transfers to everything after it and
    /// returns its command buffer to submit now; it counts as in flight until frame `serial`
    /// completes (or `complete(through: nil)`).
    func close(serial: UInt64) throws -> VkCommandBuffer? {
        try lock.withLock {
            guard let batch = open else { return nil }
            open = nil
            var barrier = VkMemoryBarrier()
            barrier.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER
            barrier.srcAccessMask = vkFlags(VK_ACCESS_TRANSFER_WRITE_BIT)
            barrier.dstAccessMask = vkFlags(VK_ACCESS_MEMORY_READ_BIT, VK_ACCESS_MEMORY_WRITE_BIT)
            vkCmdPipelineBarrier(batch.commandBuffer, vkFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                 vkFlags(VK_PIPELINE_STAGE_ALL_COMMANDS_BIT), 0, 1, &barrier, 0, nil, 0, nil)
            try vkCheck(vkEndCommandBuffer(batch.commandBuffer), "vkEndCommandBuffer")
            batch.serial = serial
            inFlight.append(batch)
            stats.batches += 1
            stats.batchesInFlight += 1
            stats.openUploads -= batch.uploads
            return batch.commandBuffer
        }
    }

    /// Gives back the staging memory and command buffers of batches submitted for frames up to
    /// `serial` (all of them when nil, after a device-wide wait).
    func complete(through serial: UInt64?) {
        lock.withLock {
            var remaining: [Batch] = []
            for batch in inFlight {
                guard serial.map({ batch.serial <= $0 }) ?? true else {
                    remaining.append(batch)
                    continue
                }
                for owner in batch.staging { release(owner) }
                batch.staging.removeAll()
                batch.uploads = 0
                vkResetCommandPool(device, batch.pool, 0)
                idleBatches.append(batch)
                stats.batchesInFlight -= 1
            }
            inFlight = remaining
        }
    }

    /// Frees everything (after a device-wide wait). Later uploads trap.
    func destroy() {
        lock.withLock {
            isShutDown = true
            let batches = inFlight + idleBatches + (open.map { [$0] } ?? [])
            for batch in batches {
                for owner in batch.staging { release(owner) }
                vkDestroyCommandPool(device, batch.pool, nil)
            }
            inFlight.removeAll()
            idleBatches.removeAll()
            open = nil
            if let current { retire(current) }
            current = nil
            for chunk in idleChunks { destroyStaging(chunk.staging) }
            idleChunks.removeAll()
        }
    }

    // MARK: Staging buffers (thread-safe Vulkan calls)

    /// A persistently mapped, host-visible and coherent transfer source of `length` bytes.
    private func createStaging(_ length: Int) throws -> StagingBuffer {
        var info = VkBufferCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO
        info.size = VkDeviceSize(length)
        info.usage = vkFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
        info.sharingMode = VK_SHARING_MODE_EXCLUSIVE
        var buffer: VkBuffer?
        try vkCheck(vkCreateBuffer(device, &info, nil, &buffer), "vkCreateBuffer")
        var requirements = VkMemoryRequirements()
        vkGetBufferMemoryRequirements(device, buffer, &requirements)
        let wanted = vkFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
        let types = withUnsafeBytes(of: memoryProperties.memoryTypes) { Array($0.bindMemory(to: VkMemoryType.self)) }
        guard let typeIndex = (0..<Int(memoryProperties.memoryTypeCount)).first(where: {
            requirements.memoryTypeBits & (1 << $0) != 0 && types[$0].propertyFlags & wanted == wanted
        }) else {
            vkDestroyBuffer(device, buffer, nil)
            throw GraphicsError("No host-visible Vulkan memory for staging")
        }
        var allocate = VkMemoryAllocateInfo()
        allocate.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO
        allocate.allocationSize = requirements.size
        allocate.memoryTypeIndex = UInt32(typeIndex)
        var memory: VkDeviceMemory?
        var mapped: UnsafeMutableRawPointer?
        do {
            try vkCheck(vkAllocateMemory(device, &allocate, nil, &memory), "vkAllocateMemory")
            try vkCheck(vkBindBufferMemory(device, buffer, memory, 0), "vkBindBufferMemory")
            try vkCheck(vkMapMemory(device, memory, 0, VkDeviceSize(length), 0, &mapped), "vkMapMemory")
        } catch {
            vkDestroyBuffer(device, buffer, nil)
            if let memory { vkFreeMemory(device, memory, nil) }
            throw error
        }
        return StagingBuffer(buffer: buffer!, memory: memory!, mapped: mapped!)
    }

    private func destroyStaging(_ staging: StagingBuffer) {
        vkDestroyBuffer(device, staging.buffer, nil)
        vkFreeMemory(device, staging.memory, nil)  // implicitly unmaps
    }

    // MARK: Private (lock held)

    private func makeBatch() throws -> Batch {
        var info = VkCommandPoolCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO
        info.flags = vkFlags(VK_COMMAND_POOL_CREATE_TRANSIENT_BIT)
        info.queueFamilyIndex = queueFamily
        var pool: VkCommandPool?
        try vkCheck(vkCreateCommandPool(device, &info, nil, &pool), "vkCreateCommandPool")
        var allocate = VkCommandBufferAllocateInfo()
        allocate.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO
        allocate.commandPool = pool
        allocate.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY
        allocate.commandBufferCount = 1
        var commandBuffer: VkCommandBuffer?
        let result = vkAllocateCommandBuffers(device, &allocate, &commandBuffer)
        guard result == VK_SUCCESS, let commandBuffer else {
            vkDestroyCommandPool(device, pool, nil)
            throw GraphicsError("vkAllocateCommandBuffers failed: \(result)")
        }
        return Batch(pool: pool!, commandBuffer: commandBuffer)
    }

    private func release(_ owner: Owner) {
        switch owner {
        case .dedicated(let buffer):
            destroyStaging(buffer)
            stats.dedicatedBuffers -= 1
        case .chunk(let chunk):
            chunk.users -= 1
            guard chunk.users == 0 else { return }
            if chunk === current {
                chunk.used = 0  // keep filling it from the start
            } else {
                retire(chunk)
            }
        }
    }

    /// A chunk that is no longer the one being filled: reused once idle, freed beyond the cap.
    private func retire(_ chunk: Chunk) {
        guard chunk.users == 0 else { return }  // its last batch gives it back
        chunk.used = 0
        if idleChunks.count < maxIdleChunks && !isShutDown {
            idleChunks.append(chunk)
        } else {
            destroyStaging(chunk.staging)
            stats.chunks -= 1
        }
    }
}
#endif
