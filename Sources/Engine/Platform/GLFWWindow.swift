#if ENGINE_VULKAN
import CGLFW
import CVulkan

/// GLFW window used with the Vulkan backend (Linux, Windows, and macOS via MoltenVK).
@MainActor
final class GLFWWindow: PlatformWindow, VulkanSurfaceProvider {
    let handle: OpaquePointer
    private var currentTitle: String
    /// The input that char/key/scroll callbacks feed. Callbacks only run inside `glfwPollEvents`, where it is set.
    private var textTarget: Input?
    /// The capture state and cursor last applied, standard cursors created so far, and the
    /// last (virtual, unbounded) cursor position while captured.
    private var captured = false
    private var appliedCursor: CursorShape = .arrow
    private var cursors: [CursorShape: OpaquePointer] = [:]
    private var lastCapturedPosition: Vec2?
    private let gamepads = makePlatformGamepadSource()

    /// `visible` false creates a hidden window (GPU tests that need a Vulkan surface).
    init(title: String, width: Int, height: Int, visible: Bool = true, minimumSize: (width: Int, height: Int)? = nil) throws {
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
        glfwWindowHint(GLFW_VISIBLE, visible ? GLFW_TRUE : GLFW_FALSE)
        guard let handle = glfwCreateWindow(Int32(width), Int32(height), title, nil, nil) else {
            glfwTerminate()
            throw GraphicsError("glfwCreateWindow failed")
        }
        self.handle = handle
        currentTitle = title
        if let minimumSize {
            // Screen coordinates (points on macOS), like the size the window was created with.
            glfwSetWindowSizeLimits(handle, Int32(minimumSize.width), Int32(minimumSize.height), GLFW_DONT_CARE, GLFW_DONT_CARE)
        }
        installTextCallbacks()
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

    var requiredInstanceExtensions: [String] { Self.requiredInstanceExtensions() }

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
        textTarget = input
        glfwPollEvents()
        textTarget = nil
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
        let position = Vec2(Float(x), Float(y))
        if captured {
            // GLFW_CURSOR_DISABLED: the position is virtual and unbounded; its change is the motion.
            if let last = lastCapturedPosition { input.addMouseMotion(position - last) }
            lastCapturedPosition = position
        } else {
            lastCapturedPosition = nil
            input.mousePosition = position
        }
        input.setWindowFocused(glfwGetWindowAttrib(handle, GLFW_FOCUSED) == GLFW_TRUE)
        input.updateGamepads(gamepads?.snapshots() ?? [])
    }

    func applyCursor(_ cursor: CursorShape, captured: Bool) {
        if captured != self.captured {
            self.captured = captured
            // Disabled hides the cursor and locks it to the window; raw motion skips OS acceleration where available.
            glfwSetInputMode(handle, GLFW_CURSOR, captured ? GLFW_CURSOR_DISABLED : GLFW_CURSOR_NORMAL)
            if glfwRawMouseMotionSupported() == GLFW_TRUE {
                glfwSetInputMode(handle, GLFW_RAW_MOUSE_MOTION, captured ? GLFW_TRUE : GLFW_FALSE)
            }
            if !captured { appliedCursor = .arrow }  // normal mode shows the default cursor again
        }
        guard !captured, cursor != appliedCursor else { return }
        if cursor == .hidden || appliedCursor == .hidden {
            glfwSetInputMode(handle, GLFW_CURSOR, cursor == .hidden ? GLFW_CURSOR_HIDDEN : GLFW_CURSOR_NORMAL)
        }
        appliedCursor = cursor
        guard cursor != .hidden else { return }
        glfwSetCursor(handle, standardCursor(cursor))  // nil is the default arrow
    }

    /// GLFW's standard cursor for `shape`, created on first use. nil (the arrow) when this GLFW
    /// doesn't have it: `notAllowed` needs GLFW 3.4.
    private func standardCursor(_ shape: CursorShape) -> OpaquePointer? {
        if let cursor = cursors[shape] { return cursor }
        // GLFW 3.3 names (3.4 keeps them as aliases); GLFW_NOT_ALLOWED_CURSOR is 0x0003600A in 3.4.
        let id: Int32 = switch shape {
        case .arrow, .hidden: GLFW_ARROW_CURSOR
        case .iBeam: GLFW_IBEAM_CURSOR
        case .pointingHand: GLFW_HAND_CURSOR
        case .resizeHorizontal: GLFW_HRESIZE_CURSOR
        case .resizeVertical: GLFW_VRESIZE_CURSOR
        case .crosshair: GLFW_CROSSHAIR_CURSOR
        case .notAllowed: 0x0003_600A
        }
        guard let cursor = glfwCreateStandardCursor(id) else { return nil }
        cursors[shape] = cursor
        return cursor
    }

    func requestClose(reason: String) {
        if !shouldClose { requestedCloseReason = reason }
        glfwSetWindowShouldClose(handle, GLFW_TRUE)
    }

    private var requestedCloseReason: String?

    var closeReason: String? {
        shouldClose ? requestedCloseReason ?? "the window was closed (its close button, or the window system)" : nil
    }

    func destroy() {
        for cursor in cursors.values { glfwDestroyCursor(cursor) }
        cursors.removeAll()
        glfwDestroyWindow(handle)
        glfwTerminate()
    }

    // Text input. GLFW's char callback delivers committed text (it handles dead keys itself) and
    // the key callback delivers presses with modifiers and repeats. GLFW 3.4 has no preedit (IME
    // composition) API, so input methods that compose (CJK) only report their final text.
    private func installTextCallbacks() {
        glfwSetWindowUserPointer(handle, Unmanaged.passUnretained(self).toOpaque())
        glfwSetCharCallback(handle) { window, codepoint in
            guard let window, let scalar = Unicode.Scalar(codepoint) else { return }
            MainActor.assumeIsolated {
                GLFWWindow.from(window)?.textTarget?.commitText(String(Character(scalar)))
            }
        }
        glfwSetKeyCallback(handle) { window, code, _, action, mods in
            guard let window, action != GLFW_RELEASE, let key = GLFWWindow.reverseKeyMap[code] else { return }
            MainActor.assumeIsolated {
                var modifiers: KeyModifiers = []
                if mods & GLFW_MOD_SHIFT != 0 { modifiers.insert(.shift) }
                if mods & GLFW_MOD_CONTROL != 0 { modifiers.insert(.control) }
                if mods & GLFW_MOD_ALT != 0 { modifiers.insert(.alt) }
                if mods & GLFW_MOD_SUPER != 0 { modifiers.insert(.command) }
                let target = GLFWWindow.from(window)?.textTarget
                target?.recordKeyPress(key, modifiers: modifiers, isRepeat: action == GLFW_REPEAT)
                target?.textKeyEvent(key, modifiers: modifiers, isRepeat: action == GLFW_REPEAT)
            }
        }
        glfwSetScrollCallback(handle) { window, x, y in
            guard let window else { return }
            MainActor.assumeIsolated {
                // GLFW reports lines (on macOS it divides precise trackpad deltas by 10).
                #if os(macOS)
                let points: Float = 10
                #else
                let points: Float = 40
                #endif
                GLFWWindow.from(window)?.textTarget?.addScroll(Vec2(Float(x), Float(y)) * points)
            }
        }
    }

    private static func from(_ window: OpaquePointer) -> GLFWWindow? {
        glfwGetWindowUserPointer(window).map { Unmanaged<GLFWWindow>.fromOpaque($0).takeUnretainedValue() }
    }

    private static let reverseKeyMap: [Int32: Key] = Dictionary(uniqueKeysWithValues: keyMap.map { ($0.1, $0.0) })

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
        (.leftBracket, GLFW_KEY_LEFT_BRACKET), (.rightBracket, GLFW_KEY_RIGHT_BRACKET),
        (.f1, GLFW_KEY_F1), (.f2, GLFW_KEY_F2), (.f3, GLFW_KEY_F3), (.f4, GLFW_KEY_F4), (.f5, GLFW_KEY_F5),
        (.f6, GLFW_KEY_F6), (.f7, GLFW_KEY_F7), (.f8, GLFW_KEY_F8), (.f9, GLFW_KEY_F9), (.f10, GLFW_KEY_F10),
        (.f11, GLFW_KEY_F11), (.f12, GLFW_KEY_F12),
        (.delete, GLFW_KEY_DELETE), (.home, GLFW_KEY_HOME), (.end, GLFW_KEY_END),
        (.pageUp, GLFW_KEY_PAGE_UP), (.pageDown, GLFW_KEY_PAGE_DOWN),
        (.left, GLFW_KEY_LEFT), (.right, GLFW_KEY_RIGHT), (.up, GLFW_KEY_UP), (.down, GLFW_KEY_DOWN),
        (.leftShift, GLFW_KEY_LEFT_SHIFT), (.rightShift, GLFW_KEY_RIGHT_SHIFT),
        (.leftControl, GLFW_KEY_LEFT_CONTROL), (.rightControl, GLFW_KEY_RIGHT_CONTROL),
        (.leftAlt, GLFW_KEY_LEFT_ALT), (.rightAlt, GLFW_KEY_RIGHT_ALT),
        (.leftSuper, GLFW_KEY_LEFT_SUPER), (.rightSuper, GLFW_KEY_RIGHT_SUPER),
    ]
}
#endif
