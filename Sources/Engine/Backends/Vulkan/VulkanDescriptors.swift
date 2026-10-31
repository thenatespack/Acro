#if ENGINE_VULKAN
import CVulkan
import Foundation

/// Descriptor strategy for game-bound resources (set 2 of the shared pipeline layout).
///
/// Sets 0 and 1 are engine-managed and long-lived: set 0 is a dynamic uniform buffer per
/// transient-ring chunk, set 1 a texture with its fixed sampler. Set 2 holds everything a game
/// binds with `setUniformBuffer` / `setUniformData(index:)` / `setTexture(index:)` / `setSampler`.
/// Its contents change from draw to draw, so a pass only records the bindings, and the first
/// draw after any change allocates a fresh set from the frame slot's `VulkanDescriptorArena`,
/// writes the bound descriptors into it and binds it. The arena's pools are reset wholesale
/// when the slot's fence has signaled, which frees every set the slot used in one call: no
/// per-set bookkeeping, no deletion queue, and nothing to update while the GPU may be reading.
/// (Push descriptors would avoid the allocation, but they are an extension that isn't
/// available everywhere; a pool reset is a cheap pointer reset in drivers.)
///
/// Layout of set 2, matching the table in `ShaderSource`: uniform buffer n at binding n,
/// texture n (sampled image) at binding 8 + n, sampler n at binding 16 + n, storage buffer n
/// at 24 + n, storage texture n at 32 + n. Compute passes use the same layout (and arenas).
let vulkanUniformBinding = 0
let vulkanTextureBinding = 8
let vulkanSamplerBinding = 16
let vulkanStorageBufferBinding = 24
let vulkanStorageImageBinding = 32
private let slotCount = 8

final class VulkanSampler: GPUSampler {
    let sampler: VkSampler
    let descriptor: SamplerDescriptor

    init(sampler: VkSampler, descriptor: SamplerDescriptor) {
        self.sampler = sampler
        self.descriptor = descriptor
    }
}

/// Long-lived descriptor sets: set 0 (a dynamic uniform buffer per transient-ring chunk) and
/// set 1 (a combined image sampler per depth texture, offscreen target and upscale image).
///
/// These live as long as the chunk or texture they describe and are freed one at a time, so
/// per-frame pools that reset wholesale (`VulkanDescriptorArena`, for set 2) don't fit. Instead
/// this is a list of free-able pools that grows on demand: an allocation tries the pool that
/// last had room, then the others (freed sets leave holes), and only when every pool is out of
/// memory (or too fragmented) adds a new one. `free` returns a set to the pool it came from.
/// A pool also counts as full once it holds `setsPerPool` live sets: drivers aren't required to
/// fail past a pool's limits (lavapipe keeps allocating), so the count, not the driver, decides.
/// Allocation is rare (a new ring chunk or texture), so the search costs nothing per frame,
/// and the device never runs out however many chunks a heavy frame needs (the `crowd` scene
/// once exhausted a single fixed pool). Thread-safe: textures may be made off the main thread.
final class VulkanDescriptorPools: @unchecked Sendable {
    private let device: VkDevice
    private let setsPerPool: Int
    private let lock = NSLock()
    private var pools: [VkDescriptorPool] = []
    /// The pool each live set came from.
    private var owners: [VkDescriptorSet: VkDescriptorPool] = [:]
    /// Live sets per pool, parallel to `pools`.
    private var liveCounts: [Int] = []
    /// The pool the last allocation came from (tried first).
    private var current = 0
    private var reportedGrowth = false

    /// Each pool holds `setsPerPool` sets of the engine's single-descriptor layouts, of either type.
    init(device: VkDevice, setsPerPool: Int = 256) {
        self.device = device
        self.setsPerPool = setsPerPool
    }

    var poolCount: Int { lock.withLock { pools.count } }
    var liveSetCount: Int { lock.withLock { owners.count } }

    func allocate(layout: VkDescriptorSetLayout) throws -> VkDescriptorSet {
        try lock.withLock {
            for attempt in 0..<pools.count {
                let index = (current + attempt) % pools.count
                guard liveCounts[index] < setsPerPool else { continue }
                if let set = try tryAllocate(layout: layout, from: pools[index]) {
                    current = index
                    owners[set] = pools[index]
                    liveCounts[index] += 1
                    return set
                }
            }
            let pool = try makePool()
            pools.append(pool)
            liveCounts.append(0)
            current = pools.count - 1
            if pools.count > 1 && !reportedGrowth {
                reportedGrowth = true
                EngineLog.info("Vulkan: descriptor pool full, adding another (\(pools.count) pools of \(setsPerPool) sets; "
                               + "\(owners.count) sets live). Further growth is not logged.", category: .rendering)
            }
            guard let set = try tryAllocate(layout: layout, from: pool) else {
                throw GraphicsError("vkAllocateDescriptorSets failed in a new, empty descriptor pool")
            }
            owners[set] = pool
            liveCounts[current] += 1
            return set
        }
    }

    /// Returns `set` to its pool. The GPU must be done with it.
    func free(_ set: VkDescriptorSet) {
        lock.withLock {
            guard let pool = owners.removeValue(forKey: set) else { return }
            if let index = pools.firstIndex(of: pool) { liveCounts[index] -= 1 }
            var set: VkDescriptorSet? = set
            vkFreeDescriptorSets(device, pool, 1, &set)
        }
    }

    func destroy() {
        lock.withLock {
            for pool in pools { vkDestroyDescriptorPool(device, pool, nil) }
            pools.removeAll()
            liveCounts.removeAll()
            owners.removeAll()
        }
    }

    /// Nil when the pool is out of memory or fragmented.
    private func tryAllocate(layout: VkDescriptorSetLayout, from pool: VkDescriptorPool) throws -> VkDescriptorSet? {
        var layout: VkDescriptorSetLayout? = layout
        var info = VkDescriptorSetAllocateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO
        info.descriptorPool = pool
        info.descriptorSetCount = 1
        var set: VkDescriptorSet?
        let result = withUnsafePointer(to: &layout) { layouts in
            info.pSetLayouts = layouts
            return vkAllocateDescriptorSets(device, &info, &set)
        }
        if result == VK_SUCCESS { return set! }
        guard result == VK_ERROR_OUT_OF_POOL_MEMORY || result == VK_ERROR_FRAGMENTED_POOL else {
            throw VulkanError(call: "vkAllocateDescriptorSets", result: result)
        }
        return nil
    }

    private func makePool() throws -> VkDescriptorPool {
        let count = UInt32(setsPerPool)
        let sizes = [
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, descriptorCount: count),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptorCount: count),
        ]
        var info = VkDescriptorPoolCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO
        info.flags = vkFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT)
        info.maxSets = count
        info.poolSizeCount = UInt32(sizes.count)
        var pool: VkDescriptorPool?
        let result = sizes.withUnsafeBufferPointer { sizes in
            info.pPoolSizes = sizes.baseAddress
            return vkCreateDescriptorPool(device, &info, nil, &pool)
        }
        try vkCheck(result, "vkCreateDescriptorPool")
        return pool!
    }
}

/// Descriptor sets that live for one use of a frame slot.
final class VulkanDescriptorArena {
    private let device: VkDevice
    private let layout: VkDescriptorSetLayout
    private var pools: [VkDescriptorPool] = []
    /// Pool new sets come from; earlier ones are full.
    private var current = 0
    /// Sets taken from `current` (a pool is full at `setsPerPool`, whatever the driver allows).
    private var usedInCurrent = 0

    private let setsPerPool: Int

    init(device: VkDevice, layout: VkDescriptorSetLayout, setsPerPool: Int = 256) {
        self.device = device
        self.layout = layout
        self.setsPerPool = setsPerPool
    }

    var poolCount: Int { pools.count }

    /// Frees every set allocated so far. Call once the GPU has finished with them.
    func reset() {
        for pool in pools { vkResetDescriptorPool(device, pool, 0) }
        current = 0
        usedInCurrent = 0
    }

    func allocate() throws -> VkDescriptorSet {
        while true {
            if usedInCurrent == setsPerPool {
                current += 1
                usedInCurrent = 0
            }
            if current == pools.count { pools.append(try makePool()) }
            var layout: VkDescriptorSetLayout? = layout
            var info = VkDescriptorSetAllocateInfo()
            info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO
            info.descriptorPool = pools[current]
            info.descriptorSetCount = 1
            var set: VkDescriptorSet?
            let result = withUnsafePointer(to: &layout) { layouts in
                info.pSetLayouts = layouts
                return vkAllocateDescriptorSets(device, &info, &set)
            }
            if result == VK_SUCCESS {
                usedInCurrent += 1
                return set!
            }
            // A full pool moves on to the next one (adding it on demand).
            guard result == VK_ERROR_OUT_OF_POOL_MEMORY || result == VK_ERROR_FRAGMENTED_POOL else {
                throw VulkanError(call: "vkAllocateDescriptorSets", result: result)
            }
            current += 1
            usedInCurrent = 0
        }
    }

    func destroy() {
        for pool in pools { vkDestroyDescriptorPool(device, pool, nil) }
        pools.removeAll()
    }

    private func makePool() throws -> VkDescriptorPool {
        let sets = UInt32(setsPerPool)
        let perSet = UInt32(slotCount)
        let sizes = [
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, descriptorCount: sets * perSet),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, descriptorCount: sets * perSet),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_SAMPLER, descriptorCount: sets * perSet),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, descriptorCount: sets * perSet),
            VkDescriptorPoolSize(type: VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, descriptorCount: sets * perSet),
        ]
        var info = VkDescriptorPoolCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO
        info.maxSets = sets
        info.poolSizeCount = UInt32(sizes.count)
        var pool: VkDescriptorPool?
        let result = sizes.withUnsafeBufferPointer { sizes in
            info.pPoolSizes = sizes.baseAddress
            return vkCreateDescriptorPool(device, &info, nil, &pool)
        }
        try vkCheck(result, "vkCreateDescriptorPool")
        return pool!
    }

    /// The layout of set 2: `slotCount` uniform buffers, sampled images, samplers, storage
    /// buffers and storage images, visible to every stage.
    static func makeLayout(device: VkDevice) throws -> VkDescriptorSetLayout {
        let stages = vkFlags(VK_SHADER_STAGE_VERTEX_BIT, VK_SHADER_STAGE_FRAGMENT_BIT, VK_SHADER_STAGE_COMPUTE_BIT)
        let groups: [(first: Int, type: VkDescriptorType)] = [
            (vulkanUniformBinding, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
            (vulkanTextureBinding, VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE),
            (vulkanSamplerBinding, VK_DESCRIPTOR_TYPE_SAMPLER),
            (vulkanStorageBufferBinding, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER),
            (vulkanStorageImageBinding, VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
        ]
        var bindings: [VkDescriptorSetLayoutBinding] = []
        for group in groups {
            for slot in 0..<slotCount {
                bindings.append(VkDescriptorSetLayoutBinding(
                    binding: UInt32(group.first + slot), descriptorType: group.type, descriptorCount: 1,
                    stageFlags: stages, pImmutableSamplers: nil))
            }
        }
        var info = VkDescriptorSetLayoutCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO
        info.bindingCount = UInt32(bindings.count)
        var layout: VkDescriptorSetLayout?
        let result = bindings.withUnsafeBufferPointer { bindings in
            info.pBindings = bindings.baseAddress
            return vkCreateDescriptorSetLayout(device, &info, nil, &layout)
        }
        try vkCheck(result, "vkCreateDescriptorSetLayout")
        return layout!
    }
}

/// What a pass has bound in set 2, written out as a descriptor set before the next draw or dispatch.
struct VulkanUserBindings {
    private var uniforms = [VkDescriptorBufferInfo?](repeating: nil, count: slotCount)
    private var textures = [(view: VkImageView, layout: VkImageLayout)?](repeating: nil, count: slotCount)
    private var samplers = [VkSampler?](repeating: nil, count: slotCount)
    private var storageBuffers = [VkDescriptorBufferInfo?](repeating: nil, count: slotCount)
    /// Storage images are always in the general layout.
    private var storageImages = [VkImageView?](repeating: nil, count: slotCount)
    private(set) var isDirty = false

    mutating func bindUniform(buffer: VkBuffer, offset: Int, range: Int, index: Int) {
        uniforms[index] = VkDescriptorBufferInfo(buffer: buffer, offset: VkDeviceSize(offset), range: VkDeviceSize(range))
        isDirty = true
    }

    /// `layout`: the one the image rests in (shader-read, or general for storage textures).
    mutating func bindTexture(_ view: VkImageView, layout: VkImageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, index: Int) {
        textures[index] = (view, layout)
        isDirty = true
    }

    mutating func bindStorageBuffer(buffer: VkBuffer, offset: Int, range: Int, index: Int) {
        storageBuffers[index] = VkDescriptorBufferInfo(buffer: buffer, offset: VkDeviceSize(offset), range: VkDeviceSize(range))
        isDirty = true
    }

    mutating func bindStorageImage(_ view: VkImageView, index: Int) {
        storageImages[index] = view
        isDirty = true
    }

    mutating func bindSampler(_ sampler: VkSampler, index: Int) {
        samplers[index] = sampler
        isDirty = true
    }

    /// Allocates a set holding the current bindings and clears the dirty flag. Only bound
    /// slots are written; shaders must not statically use the others.
    mutating func makeSet(from descriptors: VulkanDescriptorArena, device: VkDevice) throws -> VkDescriptorSet {
        isDirty = false
        let set = try descriptors.allocate()
        let arena = Arena()
        var writes: [VkWriteDescriptorSet] = []
        func write(binding: Int, type: VkDescriptorType) -> VkWriteDescriptorSet {
            var write = VkWriteDescriptorSet()
            write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET
            write.dstSet = set
            write.dstBinding = UInt32(binding)
            write.descriptorCount = 1
            write.descriptorType = type
            return write
        }
        for (slot, info) in uniforms.enumerated() {
            guard let info else { continue }
            var w = write(binding: vulkanUniformBinding + slot, type: VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER)
            w.pBufferInfo = arena.store(info)
            writes.append(w)
        }
        for (slot, texture) in textures.enumerated() {
            guard let texture else { continue }
            var w = write(binding: vulkanTextureBinding + slot, type: VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE)
            w.pImageInfo = arena.store(VkDescriptorImageInfo(sampler: nil, imageView: texture.view, imageLayout: texture.layout))
            writes.append(w)
        }
        for (slot, info) in storageBuffers.enumerated() {
            guard let info else { continue }
            var w = write(binding: vulkanStorageBufferBinding + slot, type: VK_DESCRIPTOR_TYPE_STORAGE_BUFFER)
            w.pBufferInfo = arena.store(info)
            writes.append(w)
        }
        for (slot, view) in storageImages.enumerated() {
            guard let view else { continue }
            var w = write(binding: vulkanStorageImageBinding + slot, type: VK_DESCRIPTOR_TYPE_STORAGE_IMAGE)
            w.pImageInfo = arena.store(VkDescriptorImageInfo(sampler: nil, imageView: view, imageLayout: VK_IMAGE_LAYOUT_GENERAL))
            writes.append(w)
        }
        for (slot, sampler) in samplers.enumerated() {
            guard let sampler else { continue }
            var w = write(binding: vulkanSamplerBinding + slot, type: VK_DESCRIPTOR_TYPE_SAMPLER)
            w.pImageInfo = arena.store(VkDescriptorImageInfo(
                sampler: sampler, imageView: nil, imageLayout: VK_IMAGE_LAYOUT_UNDEFINED))
            writes.append(w)
        }
        vkUpdateDescriptorSets(device, UInt32(writes.count), writes, 0, nil)
        return set
    }
}

extension VulkanRenderDevice {
    /// Maps a sampler descriptor to a Vulkan sampler. No mip clamping beyond the texture's
    /// own levels; `.none` pins sampling to level 0 (maxLod 0 with nearest mip mode, as
    /// Metal's `.notMipmapped` does).
    static func createSampler(device: VkDevice, descriptor: SamplerDescriptor) throws -> VkSampler {
        func filter(_ f: SamplerFilter) -> VkFilter { f == .nearest ? VK_FILTER_NEAREST : VK_FILTER_LINEAR }
        let mode: VkSamplerAddressMode = switch descriptor.addressMode {
        case .repeat: VK_SAMPLER_ADDRESS_MODE_REPEAT
        case .clampToEdge: VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE
        case .mirrorRepeat: VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT
        }
        var info = VkSamplerCreateInfo()
        info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO
        info.minFilter = filter(descriptor.minFilter)
        info.magFilter = filter(descriptor.magFilter)
        info.mipmapMode = descriptor.mipFilter == .linear ? VK_SAMPLER_MIPMAP_MODE_LINEAR : VK_SAMPLER_MIPMAP_MODE_NEAREST
        info.addressModeU = mode
        info.addressModeV = mode
        info.addressModeW = mode
        info.minLod = 0
        info.maxLod = descriptor.mipFilter == .none ? 0 : 1000  // VK_LOD_CLAMP_NONE
        var sampler: VkSampler?
        try vkCheck(vkCreateSampler(device, &info, nil, &sampler), "vkCreateSampler")
        return sampler!
    }
}
#endif
