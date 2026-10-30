#if ENGINE_VULKAN
import CGLFW
import CVulkan

/// GLFW window used with the Vulkan backend (Linux, Windows, and macOS via MoltenVK).
@MainActor
final class GLFWWindow: PlatformWindow {
    let handle: OpaquePointer
    private var currentTitle: String

    init(title: String, width: Int, height: Int) throws {
        #if os(macOS)
        // Hand GLFW the loader we link against so it doesn't need to dlopen one itself.
        glfwInitVulkanLoader(vkGetInstanceProcAddr)
        #endif
        guard glfwInit() == GLFW_TRUE else { throw GraphicsError("glfwInit failed") }
        guard glfwVulkanSupported() == GLFW_TRUE else {
            glfwTerminate()
            throw GraphicsError("GLFW could not find a Vulkan loader")
        }
        glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API)
        glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE)
        guard let handle = glfwCreateWindow(Int32(width), Int32(height), title, nil, nil) else {
            glfwTerminate()
            throw GraphicsError("glfwCreateWindow failed")
        }
        self.handle = handle
        currentTitle = title
    }

    var shouldClose: Bool { glfwWindowShouldClose(handle) == GLFW_TRUE }

    var title: String {
        get { currentTitle }
        set {
            currentTitle = newValue
            glfwSetWindowTitle(handle, newValue)
        }
    }

    var framebufferSize: (width: Int, height: Int) {
        var width: Int32 = 0, height: Int32 = 0
        glfwGetFramebufferSize(handle, &width, &height)
        return (Int(width), Int(height))
    }

    var contentScale: Float {
        var x: Float = 1, y: Float = 1
        glfwGetWindowContentScale(handle, &x, &y)
        return x
    }

    /// Instance extensions required to create a surface for this window.
    static func requiredInstanceExtensions() -> [String] {
        var count: UInt32 = 0
        guard let names = glfwGetRequiredInstanceExtensions(&count) else { return [] }
        return (0..<Int(count)).compactMap { names[$0].map { String(cString: $0) } }
    }

    func createSurface(instance: VkInstance) throws -> VkSurfaceKHR {
        var surface: VkSurfaceKHR?
        let result = glfwCreateWindowSurface(instance, handle, nil, &surface)
        guard result == VK_SUCCESS, let surface else {
            throw GraphicsError("glfwCreateWindowSurface failed (\(result.rawValue))")
        }
        return surface
    }

    func pollEvents(into input: Input) {
        glfwPollEvents()
        // Polling state (rather than callbacks) keeps this free of C-callback plumbing.
        for (key, code) in Self.keyMap {
            input.setKey(key, down: glfwGetKey(handle, code) == GLFW_PRESS)
        }
        for (button, code) in Self.buttonMap {
            input.setButton(button, down: glfwGetMouseButton(handle, code) == GLFW_PRESS)
        }
        // Cursor position is reported in screen coordinates (points), top-left origin.
        var x = 0.0, y = 0.0
        glfwGetCursorPos(handle, &x, &y)
        input.mousePosition = Vec2(Float(x), Float(y))
    }

    func requestClose() {
        glfwSetWindowShouldClose(handle, GLFW_TRUE)
    }

    func destroy() {
        glfwDestroyWindow(handle)
        glfwTerminate()
    }

    private static let buttonMap: [(MouseButton, Int32)] = [
        (.left, GLFW_MOUSE_BUTTON_LEFT), (.right, GLFW_MOUSE_BUTTON_RIGHT), (.middle, GLFW_MOUSE_BUTTON_MIDDLE),
    ]

    private static let keyMap: [(Key, Int32)] = [
        (.a, GLFW_KEY_A), (.b, GLFW_KEY_B), (.c, GLFW_KEY_C), (.d, GLFW_KEY_D), (.e, GLFW_KEY_E),
        (.f, GLFW_KEY_F), (.g, GLFW_KEY_G), (.h, GLFW_KEY_H), (.i, GLFW_KEY_I), (.j, GLFW_KEY_J),
        (.k, GLFW_KEY_K), (.l, GLFW_KEY_L), (.m, GLFW_KEY_M), (.n, GLFW_KEY_N), (.o, GLFW_KEY_O),
        (.p, GLFW_KEY_P), (.q, GLFW_KEY_Q), (.r, GLFW_KEY_R), (.s, GLFW_KEY_S), (.t, GLFW_KEY_T),
        (.u, GLFW_KEY_U), (.v, GLFW_KEY_V), (.w, GLFW_KEY_W), (.x, GLFW_KEY_X), (.y, GLFW_KEY_Y),
        (.z, GLFW_KEY_Z),
        (.num0, GLFW_KEY_0), (.num1, GLFW_KEY_1), (.num2, GLFW_KEY_2), (.num3, GLFW_KEY_3), (.num4, GLFW_KEY_4),
        (.num5, GLFW_KEY_5), (.num6, GLFW_KEY_6), (.num7, GLFW_KEY_7), (.num8, GLFW_KEY_8), (.num9, GLFW_KEY_9),
        (.space, GLFW_KEY_SPACE), (.enter, GLFW_KEY_ENTER), (.escape, GLFW_KEY_ESCAPE),
        (.tab, GLFW_KEY_TAB), (.backspace, GLFW_KEY_BACKSPACE), (.grave, GLFW_KEY_GRAVE_ACCENT),
        (.f1, GLFW_KEY_F1), (.f2, GLFW_KEY_F2), (.f3, GLFW_KEY_F3), (.f4, GLFW_KEY_F4), (.f5, GLFW_KEY_F5),
        (.f6, GLFW_KEY_F6), (.f7, GLFW_KEY_F7), (.f8, GLFW_KEY_F8), (.f9, GLFW_KEY_F9), (.f10, GLFW_KEY_F10),
        (.f11, GLFW_KEY_F11), (.f12, GLFW_KEY_F12),
        (.left, GLFW_KEY_LEFT), (.right, GLFW_KEY_RIGHT), (.up, GLFW_KEY_UP), (.down, GLFW_KEY_DOWN),
        (.leftShift, GLFW_KEY_LEFT_SHIFT), (.rightShift, GLFW_KEY_RIGHT_SHIFT),
        (.leftControl, GLFW_KEY_LEFT_CONTROL), (.rightControl, GLFW_KEY_RIGHT_CONTROL),
        (.leftAlt, GLFW_KEY_LEFT_ALT), (.rightAlt, GLFW_KEY_RIGHT_ALT),
        (.leftSuper, GLFW_KEY_LEFT_SUPER), (.rightSuper, GLFW_KEY_RIGHT_SUPER),
    ]
}
#endif
