import Engine
import Foundation

/// Hosts the test scenes: owns the orbit camera, the shadow pass and scene switching.
///
/// Controls: 1–8 switch scenes, Tab / Shift-Tab cycle the render resolution, U cycles the
/// upscaler (bilinear, FSR 1, MetalFX spatial/temporal on Metal, TAAU; the temporal ones only
/// without MSAA), V toggles vsync, Space pauses
/// animation, arrows/WASD or left-drag orbit, Q/E zoom, Esc quits. Scenes add their own
/// keys (see each scene's doc comment).
final class DemoGame: Game {
    private let initialScene: Int
    private var renderer: Renderer!
    private var scene: (any DemoScene)!
    private var sceneIndex = 0
    private var view = OrbitView()
    private var camera = Camera(eye: .zero, target: .zero)
    private var paused = false
    private var animationTime: Float = 0
    private var engineInfo = ""
    /// Position in `resolutionCycle` (nil when started at a size that isn't in it).
    private var resolutionIndex: Int?
    private static let resolutionCycle: [RenderResolution] =
        [.native] + ["quality", "performance", "144p", "360p", "720p", "1080p", "4k", "8k", "16k"].compactMap { RenderResolution($0) }

    init(initialScene: Int) {
        self.initialScene = initialScene
    }

    func setup(engine: Engine) throws {
        renderer = try Renderer(device: engine.device, quality: engine.quality)
        engineInfo = "\(engine.quality.rawValue) quality, \(engine.device.sampleCount)x MSAA · "
            + "\(engine.device.backend.rawValue) on \(engine.device.deviceName)"
        resolutionIndex = Self.resolutionCycle.firstIndex(of: engine.renderResolution)
        try openScene(initialScene)
    }

    private func openScene(_ index: Int) throws {
        sceneIndex = index
        scene = try allScenes[index].init(renderer: renderer)
        renderer.resetMotion()
        view = scene.initialView
        animationTime = 0
    }

    func update(engine: Engine, dt: Float) {
        let input = engine.input
        if input.wasPressed(.escape) { engine.quit() }
        if input.wasPressed(.space) { paused.toggle() }
        if input.wasPressed(.v) { engine.vsync.toggle() }
        if input.wasPressed(.u) {
            let upscalers = [Upscaler.bilinear, .fsr1(), .metalFXSpatial, .metalFXTemporal, .taau()].filter { engine.supports($0) }
            let index = upscalers.firstIndex(of: engine.upscaler) ?? 0
            engine.upscaler = upscalers[(index + 1) % upscalers.count]
        }
        if input.wasPressed(.tab) {
            let step = input.isDown(.leftShift) || input.isDown(.rightShift) ? -1 : 1
            let count = Self.resolutionCycle.count
            let next = ((resolutionIndex ?? 0) + step + count) % count
            engine.renderResolution = Self.resolutionCycle[next]
            if engine.renderResolution == Self.resolutionCycle[next] { resolutionIndex = next }
        }
        let numberKeys: [Key] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9]
        for (i, key) in numberKeys.prefix(allScenes.count).enumerated() where input.wasPressed(key) && i != sceneIndex {
            do { try openScene(i) } catch { print("Failed to open scene \(allScenes[i].name): \(error)") }
            engine.resetTemporalHistory()  // a camera cut
        }

        view.yaw += input.axis(negative: .left, positive: .right) * 2 * dt
        view.yaw += input.axis(negative: .a, positive: .d) * 2 * dt
        view.pitch += input.axis(negative: .down, positive: .up) * 2 * dt
        view.pitch += input.axis(negative: .s, positive: .w) * 2 * dt
        view.distance *= 1 - input.axis(negative: .e, positive: .q) * 1.2 * dt
        if input.isDown(.left as MouseButton) {
            view.yaw -= input.mouseDelta.x * 0.01
            view.pitch += input.mouseDelta.y * 0.01
        }
        view.pitch = min(max(view.pitch, -1.45), 1.45)
        view.distance = min(max(view.distance, 2), 300)

        let sceneDt = paused ? 0 : dt
        animationTime += sceneDt
        scene.update(input: input, dt: sceneDt, time: animationTime)

        let orbit = Vec3(cosf(view.pitch) * sinf(view.yaw), sinf(view.pitch), cosf(view.pitch) * cosf(view.yaw))
        camera = scene.camera(orbitEye: view.target + orbit * view.distance, target: view.target)
        let lighting = scene.lighting
        engine.clearColor = Vec4(lighting.fogColor, 1)
        engine.clearDepth = camera.reversedZ ? 0 : 1
        renderer.prepare(camera: camera, lighting: lighting, aspect: engine.aspectRatio, time: animationTime,
                         jitter: { engine.jittered($0) })

        let type = allScenes[sceneIndex]
        var title = "\(sceneIndex + 1)/\(allScenes.count) \(type.name)"
        if !scene.status.isEmpty { title += " (\(scene.status))" }
        if paused { title += " [paused]" }
        let size = engine.renderSize
        title += " · \(size.width)x\(size.height)"
            + (engine.renderResolution == .native ? " native" : " \(engine.upscaler) to window")
        title += ", \(engineInfo)" + (engine.vsync ? "" : " · vsync off")
        if engine.title != title { engine.title = title }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        scene.renderOffscreen(frame: frame)
        frame.depthPass(into: renderer.shadowMap) { pass in
            pass.setPipeline(renderer.shadowPipeline)
            renderer.bind(pass)
            scene.drawShadowCasters(pass)
        }
    }

    func render(engine: Engine, pass: RenderPass) {
        renderer.bind(pass)
        pass.setTexture(renderer.shadowMap)
        do {
            try scene.draw(pass)
        } catch {
            print("Scene \(allScenes[sceneIndex].name) failed to draw: \(error)")
            engine.quit()
        }
    }
}

// MARK: - Command line

@MainActor func usage() -> String {
    var text = """
        Usage: Demo [--scene <name|number>] [--quality low|medium|high|ultra] [--resolution <res>]
                    [--backend metal|vulkan] [--list]

        Resolutions: native (default), \(RenderResolution.presets.map(\.name).joined(separator: ", ")),
                     any <height>p or <n>k (16:9), or <width>x<height>

        Scenes:

        """
    for (i, scene) in allScenes.enumerated() {
        text += "  \(i + 1). \(scene.name.padding(toLength: 13, withPad: " ", startingAt: 0)) \(scene.summary)\n"
    }
    return text
}

@MainActor func fail(_ message: String) -> Never {
    print(message)
    print(usage())
    exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
var config = EngineConfig(title: "Demo")
var sceneIndex = 0
var i = 0
while i < arguments.count {
    let argument = arguments[i]
    func value() -> String {
        guard i + 1 < arguments.count else { fail("Missing value for \(argument)") }
        i += 1
        return arguments[i]
    }
    switch argument {
    case "--scene":
        let name = value()
        if let n = Int(name), allScenes.indices.contains(n - 1) {
            sceneIndex = n - 1
        } else if let index = allScenes.firstIndex(where: { $0.name == name }) {
            sceneIndex = index
        } else {
            fail("Unknown scene '\(name)'")
        }
    case "--quality":
        let name = value()
        guard let quality = RenderQuality(rawValue: name) else {
            fail("Unknown quality '\(name)'. Available: \(RenderQuality.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        config.quality = quality
    case "--resolution":
        let name = value()
        guard let resolution = RenderResolution(name) else { fail("Unknown resolution '\(name)'") }
        config.renderResolution = resolution
    case "--backend":
        let name = value()
        guard let backend = GraphicsBackend(rawValue: name) else {
            fail("Unknown backend '\(name)'. Available: \(GraphicsBackend.available.map(\.rawValue).joined(separator: ", "))")
        }
        config.backend = backend
    case "--list":
        // One name per line, for scripts.
        for scene in allScenes { print(scene.name) }
        exit(0)
    case "--help", "-h":
        print(usage())
        exit(0)
    default:
        fail("Unknown argument '\(argument)'")
    }
    i += 1
}

do {
    let engine = try Engine(config: config)
    let size = engine.renderSize
    print("Running \(allScenes[sceneIndex].name) on \(engine.device.backend.rawValue) (\(engine.device.deviceName)), "
        + "\(engine.quality.rawValue) quality, \(engine.device.sampleCount)x MSAA, rendering at \(size.width)x\(size.height)")
    try engine.run(DemoGame(initialScene: sceneIndex))
} catch {
    print("Fatal: \(error)")
    exit(1)
}
