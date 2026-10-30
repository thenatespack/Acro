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
    /// Quality preset (overridable with `ENGINE_QUALITY=low|medium|high|ultra`).
    public var quality: RenderQuality
    /// MSAA samples for the screen pass (clamped to what the GPU supports). nil uses
    /// `quality.sampleCount`.
    public var sampleCount: Int?
    /// Size the scene renders at (overridable with `ENGINE_RESOLUTION=720p|4k|16k|1920x1080|performance|native…`).
    public var renderResolution: RenderResolution
    /// Scales an offscreen scene into the window (overridable with
    /// `ENGINE_UPSCALER=bilinear|fsr1|fsr1:<sharpness>|metalfx|metalfx-temporal|taau|taau:<sharpness>`).
    /// A temporal upscaler forces MSAA to 1x.
    public var upscaler: Upscaler
    /// Cap the frame rate at the display refresh rate (overridable with `ENGINE_VSYNC=0|1`).
    /// Turn it off to see how fast a scene really runs.
    public var vsync: Bool

    public init(
        title: String = "Game",
        width: Int = 1280,
        height: Int = 720,
        backend: GraphicsBackend? = nil,
        clearColor: Vec4 = Vec4(0.05, 0.05, 0.08, 1),
        showDebugOverlay: Bool = true,
        debugOverlayKey: Key? = .grave,
        quality: RenderQuality = .high,
        sampleCount: Int? = nil,
        renderResolution: RenderResolution = .native,
        upscaler: Upscaler = .bilinear,
        vsync: Bool = true
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.backend = backend
        self.clearColor = clearColor
        self.showDebugOverlay = showDebugOverlay
        self.debugOverlayKey = debugOverlayKey
        self.quality = quality
        self.sampleCount = sampleCount
        self.renderResolution = renderResolution
        self.upscaler = upscaler
        self.vsync = vsync
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

    /// Copies `elements` into transient memory once, for use by several passes this frame
    /// (e.g. instances drawn in both the shadow and the screen pass). Valid until the frame ends.
    public func upload<T: BitwiseCopyable>(_ elements: [T]) -> TransientBuffer {
        elements.withUnsafeBytes { device.uploadTransient($0) }
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
    /// The active quality preset. Games use it to size shadow maps, filters, etc.
    public let quality: RenderQuality
    /// Depth the screen pass clears to: 1 for standard depth, 0 for reversed-Z.
    public var clearDepth: Float = 1
    /// Size the scene renders at. Changes take effect next frame; a size larger than
    /// `device.maxTextureSize`, or too big for the MSAA memory budget at the current sample
    /// count, is rejected (printed) and the previous value kept.
    public var renderResolution: RenderResolution {
        didSet {
            if let error = validate(renderResolution) {
                print("Render resolution \(renderResolution) rejected: \(error)")
                renderResolution = oldValue
            }
        }
    }
    /// How an offscreen scene is scaled into the window. One the backend doesn't support is
    /// rejected (printed) and the previous value kept, as is a temporal upscaler when the
    /// device was created with MSAA (the sample count is fixed at startup: start with a
    /// temporal upscaler, or `sampleCount: 1`, to switch to one at runtime).
    public var upscaler: Upscaler {
        didSet {
            if let error = unsupported(upscaler) {
                print("Upscaler \(upscaler) rejected: \(error); keeping \(oldValue)")
                upscaler = oldValue
            } else {
                device.upscaler = upscaler
            }
        }
    }

    /// Whether `upscaler` can be selected now (see `upscaler`).
    public func supports(_ upscaler: Upscaler) -> Bool {
        unsupported(upscaler) == nil
    }

    private func unsupported(_ upscaler: Upscaler) -> String? {
        if !device.supports(upscaler) { return "not supported on \(device.backend.rawValue)" }
        if upscaler.isTemporal && device.sampleCount > 1 {
            return "temporal upscalers need 1x MSAA, and this device was created with \(device.sampleCount)x"
        }
        return nil
    }

    /// Whether a temporal upscaler is in use this frame (selected, and the scene renders
    /// offscreen). Then `jitter` is nonzero and the scene pass has a motion-vector attachment.
    public var temporalUpscaling: Bool {
        upscaler.isTemporal && renderResolution.size(window: window.framebufferSize) != nil
    }

    /// This frame's sub-pixel projection jitter in render pixels (Halton 2, 3; see
    /// `TemporalJitter`), or zero without temporal upscaling. Apply it with `jittered(_:)`.
    public var jitter: Vec2 {
        let window = window.framebufferSize
        guard upscaler.isTemporal, let render = renderResolution.size(window: window) else { return .zero }
        let output = letterboxRect(image: render, window: window)
        let phases = TemporalJitter.phaseCount(renderWidth: render.width, outputWidth: output.width)
        return TemporalJitter.offset(frame: frameCount, phaseCount: phases)
    }

    /// The jitter the previous frame was rendered with (zero if it had none).
    public private(set) var previousJitter: Vec2 = .zero

    /// `projection` (or a view-projection) shifted by this frame's `jitter`. Unchanged without
    /// temporal upscaling. Compute motion vectors from the unjittered matrices.
    public func jittered(_ projection: Mat4) -> Mat4 {
        let jitter = jitter
        guard jitter != .zero else { return projection }
        return projection.jittered(clipOffset: TemporalJitter.clipOffset(jitter, renderSize: renderSize))
    }

    /// Discards a temporal upscaler's accumulated history next frame. Call on camera cuts and
    /// scene switches; the engine does it itself when the render or window size, or the upscaler, changes.
    public func resetTemporalHistory() {
        historyResetRequested = true
    }

    private var historyResetRequested = true
    /// What the last frame's temporal history was accumulated for; a change resets it.
    private var lastTemporalSetup: (render: (width: Int, height: Int), window: (width: Int, height: Int), upscaler: Upscaler)?
    /// Wait for the display refresh before presenting. false renders as fast as possible
    /// (may tear on Vulkan when the surface only offers immediate presentation).
    public var vsync: Bool {
        get { device.vsync }
        set { device.vsync = newValue }
    }
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
    /// Receives window events during automated screenshots so stray keyboard/mouse input
    /// (e.g. the window grabbing focus mid-run) can't change the captured frame.
    private let ignoredInput = Input()
    private var fpsWindow = (frames: 0, elapsed: 0.0)
    private var pendingScreenshots: [URL] = []
    /// Set via ENGINE_SCREENSHOT=<path.png>: capture after ENGINE_SCREENSHOT_FRAME frames (default 60), then quit.
    private var automatedScreenshot: (url: URL, frame: Int)?
    /// Per-frame sums during an automated screenshot, printed as averages when it's saved.
    private var screenshotTotals = (frames: 0, frame: 0.0, update: 0.0, render: 0.0, gpu: 0.0, gpuFrames: 0, skipped: 0)
    /// Per-pass GPU time sums during an automated screenshot, in first-seen order.
    private var screenshotPassTotals: [(name: String, total: Double, count: Int)] = []

    private func printScreenshotAverages() {
        let t = screenshotTotals
        guard t.frames > 0 else { return }
        func ms(_ total: Double, _ count: Int) -> String { String(format: "%.2f ms", total / Double(count) * 1000) }
        let gpu = t.gpuFrames > 0 ? ms(t.gpu, t.gpuFrames) : "n/a"
        let fps = t.frame > 0 ? Double(t.frames) / t.frame : 0
        print("Averages over \(t.frames) frames: frame \(ms(t.frame, t.frames)) (\(Int(fps.rounded())) FPS), "
            + "update \(ms(t.update, t.frames)), render \(ms(t.render, t.frames)), "
            + "GPU \(gpu); last frame \(stats.drawCalls) draws, \(stats.triangles) triangles"
            + (t.skipped > 0 ? "; \(t.skipped) frames skipped (no drawable)" : ""))
        if !screenshotPassTotals.isEmpty {
            let passes = screenshotPassTotals.map { "\($0.name) \(ms($0.total, $0.count))" }
            let busy = screenshotPassTotals.reduce(0) { $0 + $1.total / Double($1.count) }
            print("GPU passes: " + passes.joined(separator: ", ") + String(format: " (sum %.2f ms)", busy * 1000))
        }
    }

    /// The window title. Changes are applied at most every `titleUpdateInterval`: setting a
    /// window title redraws the title bar, which waits for the display, so updating it every
    /// frame would cap the frame rate at the refresh rate even with vsync off.
    public var title: String {
        get { pendingTitle ?? window.title }
        set { pendingTitle = newValue }
    }
    private var pendingTitle: String?
    private var lastTitleUpdate = -Double.infinity
    static let titleUpdateInterval = 0.25

    private func applyPendingTitle() {
        guard let pendingTitle, time - lastTitleUpdate >= Self.titleUpdateInterval else { return }
        if pendingTitle != window.title { window.title = pendingTitle }
        self.pendingTitle = nil
        lastTitleUpdate = time
    }

    /// The size the scene renders at: the fixed or scaled render resolution, or the window's framebuffer.
    public var renderSize: (width: Int, height: Int) {
        let window = window.framebufferSize
        return renderResolution.size(window: window) ?? window
    }

    /// Render width / height. Use this for projection matrices.
    public var aspectRatio: Float {
        let size = renderSize
        return size.height > 0 ? Float(size.width) / Float(size.height) : 1
    }

    public init(config: EngineConfig = EngineConfig()) throws {
        let env = ProcessInfo.processInfo.environment["ENGINE_BACKEND"]?.lowercased()
        let backend = config.backend ?? env.flatMap(GraphicsBackend.init(rawValue:)) ?? .platformDefault
        clearColor = config.clearColor
        let envQuality = ProcessInfo.processInfo.environment["ENGINE_QUALITY"].flatMap { RenderQuality(rawValue: $0.lowercased()) }
        quality = envQuality ?? config.quality
        let envResolution = ProcessInfo.processInfo.environment["ENGINE_RESOLUTION"]
        let resolution = try envResolution.map {
            guard let resolution = RenderResolution($0) else { throw GraphicsError("Invalid ENGINE_RESOLUTION '\($0)'") }
            return resolution
        } ?? config.renderResolution
        renderResolution = resolution
        let envUpscaler = ProcessInfo.processInfo.environment["ENGINE_UPSCALER"]
        let upscaler = try envUpscaler.map {
            guard let upscaler = Upscaler($0) else { throw GraphicsError("Invalid ENGINE_UPSCALER '\($0)'") }
            return upscaler
        } ?? config.upscaler
        self.upscaler = upscaler
        // An explicit sample count wins unless ENGINE_QUALITY overrides the preset.
        var requestedSamples = envQuality == nil ? config.sampleCount ?? quality.sampleCount : quality.sampleCount
        if upscaler.isTemporal && requestedSamples > 1 {
            // Temporal upscalers anti-alias themselves and need single-sample depth and motion vectors.
            print("MSAA reduced from \(requestedSamples)x to 1x for the \(upscaler) upscaler")
            requestedSamples = 1
        }
        // Huge render sizes get fewer samples so the multisampled targets fit in memory.
        let sampleCount = resolution.affordableSampleCount(requestedSamples)
        if sampleCount < requestedSamples {
            print("MSAA reduced from \(requestedSamples)x to \(sampleCount)x to fit \(resolution) in memory")
        }
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
            device = try MetalRenderDevice(layer: appKitWindow.metalLayer, sampleCount: sampleCount)
            #else
            throw GraphicsError("The Metal backend is not available on this platform")
            #endif
        case .vulkan:
            #if ENGINE_VULKAN
            let glfwWindow = try GLFWWindow(title: config.title, width: config.width, height: config.height)
            window = glfwWindow
            device = try VulkanRenderDevice(window: glfwWindow, applicationName: config.title, sampleCount: sampleCount)
            #else
            throw GraphicsError("The Vulkan backend was not compiled in (install the Vulkan SDK and GLFW, then rebuild)")
            #endif
        }
        if let error = validate(resolution) { throw GraphicsError("Render resolution \(resolution): \(error)") }
        if let error = unsupported(upscaler) { throw GraphicsError("Upscaler \(upscaler): \(error)") }
        device.upscaler = upscaler
        device.vsync = ProcessInfo.processInfo.environment["ENGINE_VSYNC"].map { $0 != "0" } ?? config.vsync
        // Screenshots normally capture the scene at render resolution; `window` captures the
        // upscaled image the window shows instead.
        device.captureWindow = ProcessInfo.processInfo.environment["ENGINE_SCREENSHOT_SOURCE"]?.lowercased() == "window"
    }

    /// Why `resolution` can't be used on this device, or nil if it can.
    private func validate(_ resolution: RenderResolution) -> String? {
        guard let (width, height) = resolution.size else { return nil }
        if max(width, height) > device.maxTextureSize {
            return "exceeds this GPU's maximum texture size of \(device.maxTextureSize)"
        }
        if resolution.affordableSampleCount(device.sampleCount) < device.sampleCount {
            return "too large for \(device.sampleCount)x MSAA (start with this resolution, or lower quality, to reduce MSAA)"
        }
        return nil
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
            window.pollEvents(into: automatedScreenshot == nil ? input : ignoredInput)
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
            applyPendingTitle()
            stats.updateTime = Self.seconds(clock.now - updateStart)
            fpsWindow.frames += 1
            fpsWindow.elapsed += stats.frameTime
            if fpsWindow.elapsed >= 0.5 {
                stats.fps = Double(fpsWindow.frames) / fpsWindow.elapsed
                fpsWindow = (0, 0)
            }
            stats.gpuTime = device.gpuFrameTime
            stats.gpuPassTimes = device.gpuPassTimes

            if let shot = automatedScreenshot, frameCount == shot.frame {
                pendingScreenshots.append(shot.url)
            }
            device.captureNextFrame = !pendingScreenshots.isEmpty

            let framebufferSize = window.framebufferSize
            let renderSize = renderResolution.size(window: framebufferSize)
            let temporalInputs = nextTemporalInputs(renderSize: renderSize, window: framebufferSize)
            device.temporalInputs = temporalInputs
            if try device.beginFrame(framebufferSize: framebufferSize, renderSize: renderSize) {
                countingPass.resetCounts()
                let renderStart = clock.now
                game.renderOffscreen(engine: self, frame: Frame(device: device, counter: countingPass))
                // Starting the screen pass can block until the window has an image to draw into
                // (when it renders straight to the window); that wait isn't recording time.
                let screenPassStart = clock.now
                let pass = device.beginScreenPass(clearColor: clearColor, clearDepth: clearDepth)
                let windowWait = clock.now - screenPassStart
                countingPass.inner = pass
                game.render(engine: self, pass: countingPass)
                stats.renderTime = Self.seconds(clock.now - renderStart - windowWait)
                stats.drawCalls = countingPass.drawCalls
                stats.triangles = countingPass.triangles
                if automatedScreenshot != nil {
                    screenshotTotals.frames += 1
                    screenshotTotals.frame += stats.frameTime
                    screenshotTotals.update += stats.updateTime
                    screenshotTotals.render += stats.renderTime
                    if let gpu = stats.gpuTime {
                        screenshotTotals.gpu += gpu
                        screenshotTotals.gpuFrames += 1
                    }
                    var seen: [String: Int] = [:]
                    for pass in stats.gpuPassTimes {
                        // Repeated names (e.g. several depth passes) are numbered by occurrence.
                        let occurrence = seen[pass.name, default: 0]
                        seen[pass.name] = occurrence + 1
                        let name = occurrence == 0 ? pass.name : "\(pass.name)#\(occurrence + 1)"
                        if let i = screenshotPassTotals.firstIndex(where: { $0.name == name }) {
                            screenshotPassTotals[i].total += pass.seconds
                            screenshotPassTotals[i].count += 1
                        } else {
                            screenshotPassTotals.append((name, pass.seconds, 1))
                        }
                    }
                }

                // UI at window resolution (this also scales a fixed-resolution scene into the window).
                let windowPass = device.beginWindowPass()
                overlay?.record(stats)
                if showDebugOverlay, let overlay {
                    overlay.render(
                        pass: windowPass, stats: stats, time: time, framebufferSize: framebufferSize,
                        renderSize: renderSize, upscaler: upscaler, vsync: device.vsync, contentScale: window.contentScale,
                        backend: device.backend, deviceName: device.deviceName)
                }
                if let image = try device.endFrame() {
                    for url in pendingScreenshots { try image.writePNG(to: url) }
                    pendingScreenshots.removeAll()
                    if let shot = automatedScreenshot, frameCount >= shot.frame {
                        print("Saved screenshot to \(shot.url.path)")
                        printScreenshotAverages()
                        quit()
                    }
                }
                previousJitter = temporalInputs.jitter
                frameCount += 1
            } else {
                // Minimized or no drawable: don't spin the CPU. A reset that wasn't delivered stays pending.
                if temporalInputs.resetHistory { historyResetRequested = true }
                if automatedScreenshot != nil { screenshotTotals.skipped += 1 }
                Thread.sleep(forTimeInterval: 1.0 / 60.0)
            }
        }
    }

    /// This frame's temporal-upscaler inputs. Resets the history when asked to, and when the
    /// render size, window size or upscaler differ from the last frame that used one.
    private func nextTemporalInputs(renderSize: (width: Int, height: Int)?, window: (width: Int, height: Int)) -> TemporalInputs {
        guard upscaler.isTemporal, let renderSize else {
            lastTemporalSetup = nil
            return TemporalInputs()
        }
        let unchanged = lastTemporalSetup.map {
            $0.render == renderSize && $0.window == window && $0.upscaler == upscaler
        } ?? false
        let reset = historyResetRequested || !unchanged
        lastTemporalSetup = (renderSize, window, upscaler)
        historyResetRequested = false
        return TemporalInputs(jitter: jitter, resetHistory: reset, reversedDepth: clearDepth == 0)
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
