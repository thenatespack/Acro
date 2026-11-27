#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineBackends
import EngineCore
import EngineGraphics
import EngineUI

/// Another OS window next to the main one, for UI (an editor's popped-out panel). It has its
/// own `input` (its events only) and its own `ui` draw list, which the engine draws into the
/// window at the end of each frame, presented with the main window. Open one with
/// `Engine.openWindow`; it stays open until `close()`, even after its close button is
/// clicked (`closeRequested`).
///
/// A headless window (`init(headlessSize:)`) has no OS window: tests and `--headless` runs
/// drive its `input` and read its `ui` as if it were on screen.
@MainActor
public final class EngineWindow {
    /// This window's keyboard and mouse, in its points (top-left origin). Updated every frame
    /// before `Game.update`; set `cursor` on it as on `Engine.input`.
    public let input: Input
    /// Drawn into the window after the main window's UI. Filled during `Game.update`.
    public let ui = UIDrawList()
    /// What the window shows where `ui` draws nothing.
    public var clearColor = Vec4(0, 0, 0, 1)
    /// Whether `close()` was called.
    public private(set) var isClosed = false

    let platform: PlatformWindow?
    var surface: WindowSurface?
    weak var engine: Engine?
    private var headless: (size: (width: Int, height: Int), scale: Float, title: String)

    /// `input` is the one `platform`'s events go to (`PlatformWindow.makeSecondaryWindow`).
    init(platform: PlatformWindow, surface: WindowSurface, engine: Engine, input: Input) {
        self.input = input
        self.platform = platform
        self.surface = surface
        self.engine = engine
        headless = ((0, 0), 1, platform.title)
    }

    /// A window without an OS window, `size` points at `scale` pixels per point.
    public init(headlessSize size: Vec2, scale: Float = 1, title: String = "") {
        input = Input()
        platform = nil
        headless = ((Int((size.x * scale).rounded()), Int((size.y * scale).rounded())), scale, title)
        ui.beginFrame(framebufferSize: headless.size, scale: scale)
    }

    public var title: String {
        get { platform?.title ?? headless.title }
        set {
            if let platform { if platform.title != newValue { platform.title = newValue } } else { headless.title = newValue }
        }
    }

    /// The drawable size, in pixels.
    public var framebufferSize: (width: Int, height: Int) { platform?.framebufferSize ?? headless.size }
    /// Pixels per point (2 on Retina).
    public var contentScale: Float { platform?.contentScale ?? headless.scale }
    /// The size in points.
    public var size: Vec2 {
        let pixels = framebufferSize
        return Vec2(Float(pixels.width), Float(pixels.height)) / max(contentScale, 0.01)
    }

    /// Whether the user clicked the window's close button (or the system asked it to close).
    /// The window stays until `close()`.
    public var closeRequested: Bool { platform?.shouldClose ?? headlessCloseRequested }
    private var headlessCloseRequested = false

    /// Sets `closeRequested`, as the window's close button does.
    public func requestClose() {
        if let platform { platform.requestClose(reason: "requestClose() was called") } else { headlessCloseRequested = true }
    }

    /// Resizes a headless window (no effect on an OS window).
    public func resizeHeadless(to size: Vec2, scale: Float? = nil) {
        guard platform == nil else { return }
        let scale = scale ?? headless.scale
        headless.size = (Int((size.x * scale).rounded()), Int((size.y * scale).rounded()))
        headless.scale = scale
    }

    /// Brings the window to the front with the keyboard focus.
    public func activate() {
        platform?.activate()
    }

    /// Closes the window. Call it between frames (in `Game.update`), not while rendering.
    public func close() {
        guard !isClosed else { return }
        isClosed = true
        engine?.windowClosed(self)
        if let surface, let device = engine?.device as? WindowSurfaceRendering { device.destroyWindowSurface(surface) }
        surface = nil
        platform?.destroy()
    }
}

extension Engine {
    /// Whether `openWindow` can open OS windows here: Metal and Vulkan desktop builds (not in a
    /// browser).
    public var supportsWindows: Bool {
        #if os(WASI)
        false
        #else
        device is WindowSurfaceRendering
        #endif
    }

    /// Opens another OS window of `width` x `height` points, centered on the main window (later
    /// ones step down and to the right). nil where `supportsWindows` is false.
    public func openWindow(title: String, width: Int, height: Int) throws -> EngineWindow? {
        guard supportsWindows, let device = device as? WindowSurfaceRendering else { return nil }
        let input = Input()
        guard let platform = try window.makeSecondaryWindow(title: title, width: width, height: height, input: input) else {
            return nil
        }
        let surface: WindowSurface
        do {
            surface = try device.makeWindowSurface(for: platform)
        } catch {
            platform.destroy()
            throw error
        }
        let opened = EngineWindow(platform: platform, surface: surface, engine: self, input: input)
        opened.clearColor = clearColor
        extraWindows.append(opened)
        return opened
    }
}
