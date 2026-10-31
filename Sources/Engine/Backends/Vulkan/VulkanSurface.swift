#if ENGINE_VULKAN
import CVulkan
#if os(macOS)
import QuartzCore
#endif

/// What a `VulkanRenderDevice` presents to: a window (`GLFWWindow`), or on macOS a bare
/// `CAMetalLayer` (`MetalLayerSurface`).
@MainActor protocol VulkanSurfaceProvider {
    /// Instance extensions `createSurface` needs.
    var requiredInstanceExtensions: [String] { get }
    /// The size of the initial swapchain, in pixels.
    var framebufferSize: (width: Int, height: Int) { get }
    func createSurface(instance: VkInstance) throws -> VkSurfaceKHR
}

#if os(macOS)
/// A Vulkan surface on a `CAMetalLayer` that isn't in any window (`VK_EXT_metal_surface`), for
/// GPU tests: unlike a GLFW window it needs no `NSApplication` (GLFW's Cocoa initialization
/// stops the main run loop, which ends a test runner).
@MainActor final class MetalLayerSurface: VulkanSurfaceProvider {
    let layer = CAMetalLayer()
    let framebufferSize: (width: Int, height: Int)

    init(width: Int, height: Int) {
        framebufferSize = (width, height)
        layer.drawableSize = CGSize(width: width, height: height)
    }

    var requiredInstanceExtensions: [String] { ["VK_KHR_surface", "VK_EXT_metal_surface"] }

    /// `VkMetalSurfaceCreateInfoEXT`, declared here because CVulkan doesn't define VK_USE_PLATFORM_METAL_EXT.
    private struct CreateInfo {
        var sType = VkStructureType(rawValue: 1_000_217_000)  // VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT
        var pNext: UnsafeRawPointer?
        var flags: UInt32 = 0
        var pLayer: UnsafeRawPointer?
    }

    private typealias CreateMetalSurface = @convention(c) (
        VkInstance?, UnsafeRawPointer?, UnsafeRawPointer?, UnsafeMutablePointer<VkSurfaceKHR?>?) -> VkResult

    func createSurface(instance: VkInstance) throws -> VkSurfaceKHR {
        guard let function = vkGetInstanceProcAddr(instance, "vkCreateMetalSurfaceEXT") else {
            throw GraphicsError("vkCreateMetalSurfaceEXT is unavailable")
        }
        let create = unsafeBitCast(function, to: CreateMetalSurface.self)
        var info = CreateInfo(pLayer: UnsafeRawPointer(Unmanaged.passUnretained(layer).toOpaque()))
        var surface: VkSurfaceKHR?
        try vkCheck(create(instance, &info, nil, &surface), "vkCreateMetalSurfaceEXT")
        return surface!
    }
}
#endif
#endif
