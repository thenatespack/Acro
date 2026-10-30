/// An OS window the engine renders into. Each graphics backend pairs with a
/// window implementation that can produce a surface for it
/// (AppKit + CAMetalLayer for Metal, GLFW + VkSurfaceKHR for Vulkan).
@MainActor
protocol PlatformWindow: AnyObject {
    var shouldClose: Bool { get }
    var title: String { get set }
    /// Drawable size in pixels (accounts for HiDPI scaling).
    var framebufferSize: (width: Int, height: Int) { get }
    /// Framebuffer pixels per window point (2 on Retina).
    var contentScale: Float { get }
    /// Pumps the OS event queue and updates `input`.
    func pollEvents(into input: Input)
    func requestClose()
    func destroy()
}
