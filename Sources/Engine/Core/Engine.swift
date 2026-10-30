import Foundation

public struct EngineConfig: Sendable {
    public var title: String
    public var width: Int
    public var height: Int
    /// nil picks the `ENGINE_BACKEND` environment variable, then the platform default.
    public var backend: GraphicsBackend?
    public var clearColor: Vec4
    /// Show the performance overlay at startup (overridable with `ENGINE_OVERLAY=0|1`).
    public var showDebugOverlay: Bool
    /// Key that toggles the overlay; nil disables the shortcut.
    public var debugOverlayKey: Key?
    /// MSAA samples for the screen pass (clamped to what the GPU supports).
    public var sampleCount: Int

    public init(
        title: String = "Game",
        width: Int = 1280,
        height: Int = 720,
        backend: GraphicsBackend? = nil,
        clearColor: Vec4 = Vec4(0.05, 0.05, 0.08, 1),
        showDebugOverlay: Bool = true,
        debugOverlayKey: Key? = .grave,
        sampleCount: Int = 4
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.backend = backend
        self.clearColor = clearColor
        self.showDebugOverlay = showDebugOverlay
        self.debugOverlayKey = debugOverlayKey
        self.sampleCount = sampleCount
    }
}

/// Implement this to make a game. All callbacks run on the main thread.
@MainActor
public protocol Game: AnyObject {
    /// Create GPU resources here.
    func setup(engine: Engine) throws
    /// Advance simulation. `dt` is in seconds.
    func update(engine: Engine, dt: Float)
    /// Record offscreen passes (shadow maps, …) before the screen pass. Optional.
    func renderOffscreen(engine: Engine, frame: Frame)
    /// Record the screen pass.
    func render(engine: Engine, pass: RenderPass)
}

extension Game {
    public func renderOffscreen(engine: Engine, frame: Frame) {}
}

/// Offscreen work for the current frame; passes run in the order they're recorded.
@MainActor
public final class Frame {
    private let device: RenderDevice
    private let counter: CountingRenderPass

    init(device: RenderDevice, counter: CountingRenderPass) {
        self.device = device
        self.counter = counter
    }

    /// Renders depth-only geometry into `target` (e.g. a shadow map). Pipelines used here
    /// must have `target: .depthOnly`.
    public func depthPass(into target: GPUTexture, clearDepth: Float = 1, _ body: (RenderPass) -> Void) {
        counter.inner = device.beginDepthPass(target: target, clearDepth: clearDepth)
        body(counter)
        device.endPass()
    }
}

@MainActor
public final class Engine {
    public let device: RenderDevice
    public let input = Input()
    public var clearColor: Vec4
    /// Depth the screen pass clears to: 1 for standard depth, 0 for reversed-Z.
    public var clearDepth: Float = 1
    /// Seconds since `run` started.
    public private(set) var time: Double = 0
    public private(set) var frameCount = 0
    /// Timing and draw statistics for the previous frame.
    public private(set) var stats = FrameStats()
    public var showDebugOverlay: Bool
    public var debugOverlayKey: Key?

    let window: PlatformWindow
    private var overlay: DebugOverlay?
    private let countingPass = CountingRenderPass()
    private var fpsWindow = (frames: 0, elapsed: 0.0)
    private var pendingScreenshots: [URL] = []
    /// Set via ENGINE_SCREENSHOT=<path.png>: capture after ENGINE_SCREENSHOT_FRAME frames (default 60), then quit.
    private var automatedScreenshot: (url: URL, frame: Int)?

    public var title: String {
        get { window.title }
        set { window.title = newValue }
    }

    /// Framebuffer width / height.
    public var aspectRatio: Float {
        let size = window.framebufferSize
        return size.height > 0 ? Float(size.width) / Float(size.height) : 1
    }

    public init(config: EngineConfig = EngineConfig()) throws {
        let env = ProcessInfo.processInfo.environment["ENGINE_BACKEND"]?.lowercased()
        let backend = config.backend ?? env.flatMap(GraphicsBackend.init(rawValue:)) ?? .platformDefault
        clearColor = config.clearColor
        showDebugOverlay = ProcessInfo.processInfo.environment["ENGINE_OVERLAY"].map { $0 != "0" } ?? config.showDebugOverlay
        debugOverlayKey = config.debugOverlayKey
        if let path = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT"] {
            let frame = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT_FRAME"].flatMap(Int.init) ?? 60
            automatedScreenshot = (URL(fileURLWithPath: path), frame)
        }

        switch backend {
        case .metal:
            #if canImport(Metal) && canImport(AppKit)
            let appKitWindow = AppKitWindow(title: config.title, width: config.width, height: config.height)
            window = appKitWindow
            device = try MetalRenderDevice(layer: appKitWindow.metalLayer, sampleCount: config.sampleCount)
            #else
            throw GraphicsError("The Metal backend is not available on this platform")
            #endif
        case .vulkan:
            #if ENGINE_VULKAN
            let glfwWindow = try GLFWWindow(title: config.title, width: config.width, height: config.height)
            window = glfwWindow
            device = try VulkanRenderDevice(window: glfwWindow, applicationName: config.title, sampleCount: config.sampleCount)
            #else
            throw GraphicsError("The Vulkan backend was not compiled in (install the Vulkan SDK and GLFW, then rebuild)")
            #endif
        }
    }

    /// Runs the main loop until the window closes or `quit()` is called.
    public func run(_ game: Game) throws {
        defer {
            device.waitIdle()
            device.shutdown()
            window.destroy()
        }

        try game.setup(engine: self)
        do {
            overlay = try DebugOverlay(device: device)
        } catch {
            print("Debug overlay unavailable: \(error)")
        }

        let clock = ContinuousClock()
        let start = clock.now
        var last = start

        while !window.shouldClose {
            input.beginFrame()
            window.pollEvents(into: input)
            input.endEvents()

            let now = clock.now
            stats.frameTime = Self.seconds(now - last)
            var dt = min(stats.frameTime, 0.25)
            last = now
            if automatedScreenshot != nil {
                // Deterministic timing so screenshots are reproducible across runs and backends.
                dt = 1.0 / 60.0
                time += dt
            } else {
                time = Self.seconds(now - start)
            }

            if let key = debugOverlayKey, input.wasPressed(key) { showDebugOverlay.toggle() }

            let updateStart = clock.now
            game.update(engine: self, dt: Float(dt))
            stats.updateTime = Self.seconds(clock.now - updateStart)
            fpsWindow.frames += 1
            fpsWindow.elapsed += stats.frameTime
            if fpsWindow.elapsed >= 0.5 {
                stats.fps = Double(fpsWindow.frames) / fpsWindow.elapsed
                fpsWindow = (0, 0)
            }
            stats.gpuTime = device.gpuFrameTime

            if let shot = automatedScreenshot, frameCount == shot.frame {
                pendingScreenshots.append(shot.url)
            }
            device.captureNextFrame = !pendingScreenshots.isEmpty

            let framebufferSize = window.framebufferSize
            if try device.beginFrame(framebufferSize: framebufferSize) {
                countingPass.resetCounts()
                let renderStart = clock.now
                game.renderOffscreen(engine: self, frame: Frame(device: device, counter: countingPass))
                let pass = device.beginScreenPass(clearColor: clearColor, clearDepth: clearDepth)
                countingPass.inner = pass
                game.render(engine: self, pass: countingPass)
                stats.renderTime = Self.seconds(clock.now - renderStart)
                stats.drawCalls = countingPass.drawCalls
                stats.triangles = countingPass.triangles

                overlay?.record(stats)
                if showDebugOverlay, let overlay {
                    overlay.render(
                        pass: pass, stats: stats, time: time, framebufferSize: framebufferSize,
                        contentScale: window.contentScale, backend: device.backend, deviceName: device.deviceName)
                }
                if let image = try device.endFrame() {
                    for url in pendingScreenshots { try image.writePNG(to: url) }
                    pendingScreenshots.removeAll()
                    if let shot = automatedScreenshot, frameCount >= shot.frame {
                        print("Saved screenshot to \(shot.url.path)")
                        quit()
                    }
                }
                frameCount += 1
            } else {
                // Minimized or no drawable: don't spin the CPU.
                Thread.sleep(forTimeInterval: 1.0 / 60.0)
            }
        }
    }

    /// Saves the next rendered frame as a PNG.
    public func saveScreenshot(to url: URL) {
        pendingScreenshots.append(url)
    }

    public func quit() {
        window.requestClose()
    }

    private static func seconds(_ d: Duration) -> Double {
        let (s, attoseconds) = d.components
        return Double(s) + Double(attoseconds) * 1e-18
    }
}
