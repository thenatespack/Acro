#if ENGINE_VULKAN
import CVulkan
import Foundation

/// With `ENGINE_VULKAN_VALIDATION=1`: a `VK_EXT_debug_utils` messenger that posts the validation
/// layer's warnings and errors to `EngineLog` (the editor's console), instead of the layer
/// printing them to standard output. One per process (the engine makes one instance).
enum VulkanDebugMessenger {
    nonisolated(unsafe) private static var messenger: VkDebugUtilsMessengerEXT?

    /// The instance extension the messenger needs, when the validation layer is on.
    static let extensionName = "VK_EXT_debug_utils"

    /// Creates the messenger on `instance` (made with `extensionName` enabled).
    static func install(on instance: VkInstance) {
        guard messenger == nil, let address = vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT") else { return }
        let create = unsafeBitCast(address, to: PFN_vkCreateDebugUtilsMessengerEXT.self)
        var info = VkDebugUtilsMessengerCreateInfoEXT()
        info.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
        info.messageSeverity = VkDebugUtilsMessageSeverityFlagsEXT(VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT.rawValue
            | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT.rawValue)
        info.messageType = VkDebugUtilsMessageTypeFlagsEXT(VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT.rawValue
            | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT.rawValue | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT.rawValue)
        info.pfnUserCallback = { severity, _, data, _ in
            let text = data?.pointee.pMessage.map { String(cString: $0) } ?? "(no message)"
            let isError = severity.rawValue & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT.rawValue != 0
            EngineLog.post(isError ? .error : .warning, "[Vulkan] Validation \(isError ? "error" : "warning"): \(text)")
            return VkBool32(VK_FALSE)
        }
        var handle: VkDebugUtilsMessengerEXT?
        if create(instance, &info, nil, &handle) == VK_SUCCESS { messenger = handle }
    }

    /// Destroys the messenger (before the instance).
    static func uninstall(from instance: VkInstance) {
        guard let handle = messenger,
              let address = vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT") else { return }
        unsafeBitCast(address, to: PFN_vkDestroyDebugUtilsMessengerEXT.self)(instance, handle, nil)
        messenger = nil
    }
}
#endif
