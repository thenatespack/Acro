#if ENGINE_VULKAN
import CVulkan
import Foundation

/// A Vulkan object owned by a Swift wrapper. Handles are plain pointers; the
/// queue's lock serializes all access.
enum VulkanResource: @unchecked Sendable {
    case buffer(VkBuffer, VkDeviceMemory)
    case pipeline(VkPipeline)
    case texture(VkImage, VkDeviceMemory, VkImageView, VkFramebuffer?, VkDescriptorSet?)

    var key: Int {
        switch self {
        case .buffer(let buffer, _): Int(bitPattern: buffer)
        case .pipeline(let pipeline): Int(bitPattern: pipeline)
        case .texture(let image, _, _, _, _): Int(bitPattern: image)
        }
    }
}

/// Defers destruction of released resources until the GPU can no longer be using them.
///
/// Wrappers register on creation and call `release` from `deinit` (which may run on any
/// thread). A release is tagged with the serial of the frame being recorded; the device
/// destroys it once that frame's fence has been waited on. Anything still alive at
/// shutdown is destroyed then, and later releases become no-ops.
final class VulkanDeletionQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var live: [Int: VulkanResource] = [:]
    private var pending: [(serial: UInt64, resource: VulkanResource)] = []
    private var serial: UInt64 = 0
    private var isShutDown = false

    func register(_ resource: VulkanResource) {
        lock.withLock { live[resource.key] = resource }
    }

    func release(_ resource: VulkanResource) {
        lock.withLock {
            guard !isShutDown, live.removeValue(forKey: resource.key) != nil else { return }
            pending.append((serial, resource))
        }
    }

    /// Called when a new frame starts recording.
    func setCurrentSerial(_ serial: UInt64) {
        lock.withLock { self.serial = serial }
    }

    /// Removes and returns released resources last usable in frames up to `serial`
    /// (or all of them when nil, e.g. after a device-wide wait).
    func collect(completedThrough serial: UInt64?) -> [VulkanResource] {
        lock.withLock {
            guard let serial else {
                defer { pending.removeAll() }
                return pending.map(\.resource)
            }
            let ready = pending.filter { $0.serial <= serial }.map(\.resource)
            pending.removeAll { $0.serial <= serial }
            return ready
        }
    }

    /// Returns every pending and live resource and ignores later releases.
    func shutdown() -> [VulkanResource] {
        lock.withLock {
            isShutDown = true
            defer {
                pending.removeAll()
                live.removeAll()
            }
            return pending.map(\.resource) + Array(live.values)
        }
    }

    var liveCount: Int { lock.withLock { live.count } }
    var pendingCount: Int { lock.withLock { pending.count } }
}
#endif
