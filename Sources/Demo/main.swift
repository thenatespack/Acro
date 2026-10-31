import Engine
import Foundation

/// Hosts the test scenes: owns the orbit camera, the shadow pass and scene switching.
///
/// Controls: 1–9 and 0 (scene 10) switch scenes, ] / [ step to the next / previous scene (wrapping, for
/// scenes past 10), Tab / Shift-Tab cycle the render resolution, U cycles the
/// upscaler (bilinear, FSR 1, MetalFX spatial/temporal on Metal, TAAU, FSR 3; the temporal ones only
/// without MSAA), V toggles vsync, Space pauses
/// animation, arrows/WASD or left-drag orbit, Q/E zoom, Esc quits. Scenes add their own
/// keys (see each scene's doc comment). While a scene's widgets want the pointer or keyboard
/// (`UIContext.wantsPointer` / `wantsKeyboard`), the camera and these keys leave it alone.
final class DemoGame: Game {
    private let initialScene: Int
    private var renderer: Renderer!
    private var scene: (any DemoScene)!
    private var sceneIndex = 0
    private var view = OrbitView()
    private var camera = ViewCamera(eye: .zero, target: .zero)
    private var paused = false
    private var animationTime: Float = 0
    private var engineInfo = ""
    /// Position in `resolutionCycle` (nil when started at a size that isn't in it).
    private var resolutionIndex: Int?
    private static let resolutionCycle: [RenderResolution] =
        [.native] + ["quality", "performance", "144p", "360p", "720p", "1080p", "4k", "8k", "16k"].compactMap { RenderResolution($0) }

    private var textTest = TextInputTest()

    init(initialScene: Int) {
        self.initialScene = initialScene
    }

    func setup(engine: Engine) throws {
        renderer = try Renderer(device: engine.device, quality: engine.quality)
        engineInfo = "\(engine.quality.rawValue) quality, \(engine.device.sampleCount)x MSAA · "
            + "\(engine.device.backend.rawValue) on \(engine.device.deviceName)"
        resolutionIndex = Self.resolutionCycle.firstIndex(of: engine.renderResolution)
        try openScene(initialScene)
        // DEMO_INPUT_SCRIPT: a JSON array of `InputStep`s (inline, or a file path) played from
        // the first frame, e.g. to drive a scene in a screenshot run.
        if let script = ProcessInfo.processInfo.environment["DEMO_INPUT_SCRIPT"], !script.isEmpty {
            let data = FileManager.default.fileExists(atPath: script) ? try Data(contentsOf: URL(fileURLWithPath: script)) : Data(script.utf8)
            _ = try engine.inputPlayer.enqueue(JSONDecoder().decode([InputStep].self, from: data))
        }
        // ENGINE_MCP=1: the entity tools act on the open scene's World, whichever property holds it.
        engine.mcp?.world = { [unowned self] in
            scene.map { Mirror(reflecting: $0).children.lazy.compactMap { $0.value as? World }.first } ?? nil
        }
    }

    private func openScene(_ index: Int, input: Input? = nil) throws {
        if let input { scene?.uiContext?.resign(input: input) }
        scene?.willClose()
        sceneIndex = index
        scene = try allScenes[index].init(renderer: renderer)
        renderer.resetMotion()
        view = scene.initialView
        animationTime = 0
    }

    func update(engine: Engine, dt: Float) {
        let input = engine.input
        let ui = scene.uiContext
        // F2: text input debug mode.
        if let title = textTest.update(input, canStart: !(ui?.wantsKeyboard ?? false)) { engine.title = title; return }
        // Widgets see input first; what they take, the camera and shortcuts don't.
        ui?.update(engine: engine, dt: dt)
        let keyboardFree = !(ui?.wantsKeyboard ?? false) && !scene.wantsKeyboard
        let pointerFree = !(ui?.wantsPointer ?? false)
        if keyboardFree { handleShortcuts(engine: engine) }

        if keyboardFree {
            view.yaw += input.axis(negative: .left, positive: .right) * 2 * dt
            view.yaw += input.axis(negative: .a, positive: .d) * 2 * dt
            view.pitch += input.axis(negative: .down, positive: .up) * 2 * dt
            view.pitch += input.axis(negative: .s, positive: .w) * 2 * dt
            view.distance *= 1 - input.axis(negative: .e, positive: .q) * 1.2 * dt
        }
        if pointerFree && input.isDown(.left as MouseButton) {
            view.yaw -= input.mouseDelta.x * 0.01
            view.pitch += input.mouseDelta.y * 0.01
        }
        view.pitch = min(max(view.pitch, -1.45), 1.45)
        view.distance = min(max(view.distance, 2), 300)

        let sceneDt = paused ? 0 : dt
        animationTime += sceneDt
        scene.update(engine: engine, dt: sceneDt, time: animationTime)

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

    /// Global keys: quit, pause, vsync, upscaler, resolution and scene switching.
    private func handleShortcuts(engine: Engine) {
        let input = engine.input
        if input.wasPressed(.escape) { engine.quit() }
        if input.wasPressed(.space) { paused.toggle() }
        if input.wasPressed(.v) { engine.vsync.toggle() }
        if input.wasPressed(.u) {
            let upscalers = [Upscaler.bilinear, .fsr1(), .metalFXSpatial, .metalFXTemporal, .taau(), .fsr3()].filter { engine.supports($0) }
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
        let numberKeys: [Key] = [.num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9, .num0]
        var target: Int?
        for (i, key) in numberKeys.prefix(allScenes.count).enumerated() where input.wasPressed(key) { target = i }
        if input.wasPressed(.rightBracket) { target = (sceneIndex + 1) % allScenes.count }
        if input.wasPressed(.leftBracket) { target = (sceneIndex + allScenes.count - 1) % allScenes.count }
        if let target, target != sceneIndex {
            do { try openScene(target, input: input) } catch { print("Failed to open scene \(allScenes[target].name): \(error)") }
            engine.resetTemporalHistory()  // a camera cut
            engine.postProcess = nil  // scenes with a SceneRenderer set it again from their world
        }
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        scene.renderOffscreen(engine: engine, frame: frame)
        frame.depthPass(into: renderer.shadowMap) { pass in
            pass.setPipeline(renderer.shadowPipeline)
            renderer.bind(pass)
            scene.drawShadowCasters(pass)
        }
    }

    func render(engine: Engine, pass: RenderPass) {
        renderer.targetSize = engine.renderSize
        renderer.bind(pass)
        pass.setTexture(renderer.shadowMap)
        do {
            try scene.draw(pass)
        } catch {
            print("Scene \(allScenes[sceneIndex].name) failed to draw: \(error)")
            engine.quit()
        }
        scene.drawUI(engine.ui)
    }
}

// MARK: - Command line

@MainActor func usage() -> String {
    var text = """
        Usage: Demo [--scene <name|number>] [--quality low|medium|high|ultra] [--resolution <res>]
                    [--window <width>x<height>] [--backend metal|vulkan] [--list]

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
    case "--window":
        // In points, like EngineConfig (a Retina display doubles it in pixels).
        let parts = value().split(separator: "x").compactMap { Int($0) }
        guard parts.count == 2, parts[0] > 0, parts[1] > 0 else { fail("--window takes <width>x<height> in points") }
        config.width = parts[0]
        config.height = parts[1]
        config.allowsWindowLargerThanScreen = true
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
