import EngineCore
import EngineGraphics

/// A secondary window's drawing surface on a device (`WindowSurfaceRendering`).
@MainActor package protocol WindowSurface: AnyObject {}

/// A device that also draws into secondary OS windows (`PlatformWindow.makeSecondaryWindow`,
/// `Engine.openWindow`): Metal (AppKit windows) and Vulkan (GLFW windows, a swapchain each).
/// Their passes are part of the main window's frame and present with it.
@MainActor package protocol WindowSurfaceRendering: RenderDevice {
    /// A surface for `window`, a secondary window of the device's own window's kind.
    func makeWindowSurface(for window: PlatformWindow) throws -> WindowSurface
    /// After the main window pass, before `endFrame`: a pass into `surface` at `size` pixels
    /// for `.screen` pipelines (UI), cleared to `clearColor` and presented with the frame. Ends
    /// the pass that is open. nil when the window has nothing to draw into this frame
    /// (minimized, zero-sized, or its swapchain is being rebuilt).
    func beginWindowPass(on surface: WindowSurface, size: (width: Int, height: Int), clearColor: Vec4) -> RenderPass?
    /// Releases the surface once the GPU is done with it. Call outside a frame.
    func destroyWindowSurface(_ surface: WindowSurface)
}
