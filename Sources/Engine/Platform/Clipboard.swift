#if canImport(AppKit)
import AppKit
#elseif ENGINE_VULKAN
import CGLFW
#endif

/// The system clipboard, as plain text.
@MainActor
public enum Clipboard {
    #if canImport(AppKit)
    public static var string: String? {
        get { NSPasteboard.general.string(forType: .string) }
        set {
            NSPasteboard.general.clearContents()
            if let newValue { NSPasteboard.general.setString(newValue, forType: .string) }
        }
    }
    #elseif ENGINE_VULKAN
    /// Needs the engine's window to exist (GLFW must be initialized).
    public static var string: String? {
        get { glfwGetClipboardString(nil).map { String(cString: $0) } }
        set { glfwSetClipboardString(nil, newValue ?? "") }
    }
    #else
    /// No system clipboard without AppKit or GLFW: an in-process one.
    public static var string: String?
    #endif
}
