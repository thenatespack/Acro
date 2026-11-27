import EngineCore
import EngineGraphics

/// An item of the macOS app menu, above Quit (`Engine.setAppMenuItems`): "Settings…" with
/// Cmd+, for example. Other platforms have no app menu and ignore them.
public struct AppMenuItem {
    public var title: String
    /// The key, as typed ("," or "k"); "" for none. Its shortcut works while the window has focus.
    public var keyEquivalent: String
    public var modifiers: KeyModifiers
    public var action: @MainActor () -> Void

    public init(title: String, keyEquivalent: String = "", modifiers: KeyModifiers = .command, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
        self.action = action
    }
}

/// An OS window the engine renders into. Each graphics backend pairs with a
/// window implementation that can produce a surface for it
/// (AppKit + CAMetalLayer for Metal, GLFW + VkSurfaceKHR for Vulkan).
@MainActor
package protocol PlatformWindow: AnyObject {
    var shouldClose: Bool { get }
    /// Why `shouldClose` became true ("the window's close button was clicked"), for the
    /// line the engine logs when it quits.
    var closeReason: String? { get }
    var title: String { get set }
    /// Drawable size in pixels (accounts for HiDPI scaling).
    var framebufferSize: (width: Int, height: Int) { get }
    /// Framebuffer pixels per window point (2 on Retina).
    var contentScale: Float { get }
    /// Pumps the OS event queue and updates `input` (keys, buttons, position, raw mouse
    /// motion, scrolling, text, gamepads, and whether the window has focus).
    func pollEvents(into input: Input)
    /// Shows `cursor` over the window, and hides and locks it (relative mouse mode) while
    /// `captured`. Called every frame; implementations only touch the OS when something changed.
    func applyCursor(_ cursor: CursorShape, captured: Bool)
    /// Asks the main loop to end; `reason` is logged when it does.
    func requestClose(reason: String)
    /// Puts `items` in the app menu above Quit (macOS); a no-op elsewhere.
    func setAppMenuItems(_ items: [AppMenuItem])
    /// Shows `image` as the app (Dock) or window icon (`EngineConfig.icon`).
    func setIcon(_ image: Image)
    func destroy()

    /// Opens another OS window of the same kind that shares this one's event loop (an editor
    /// pop-out, `Engine.openWindow`): this window's `pollEvents` pumps its events into `input`,
    /// and its own `pollEvents(into: input)` (called after) only updates the state it polls
    /// (pointer position, focus). Its close button sets its `shouldClose`; it doesn't quit the
    /// app. nil where the platform has one window (the browser canvas).
    func makeSecondaryWindow(title: String, width: Int, height: Int, input: Input) throws -> PlatformWindow?
    /// Brings the window to the front and gives it the keyboard.
    func activate()
}

extension PlatformWindow {
    package func setAppMenuItems(_ items: [AppMenuItem]) {}
    package func makeSecondaryWindow(title: String, width: Int, height: Int, input: Input) throws -> PlatformWindow? { nil }
    package func activate() {}
}

#if canImport(AppKit)
import AppKit

/// Sets the Dock icon (`NSApp.applicationIconImage`): how macOS shows an app icon for a bare
/// executable without a bundle, under either backend.
@MainActor
func setMacAppIcon(_ image: Image) {
    guard let provider = CGDataProvider(data: Data(image.pixels) as CFData),
          let cgImage = CGImage(
              width: image.width, height: image.height, bitsPerComponent: 8, bitsPerPixel: 32,
              bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
              provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
          )
    else { return }
    NSApp.applicationIconImage = NSImage(cgImage: cgImage, size: NSSize(width: image.width, height: image.height))
}
#endif
