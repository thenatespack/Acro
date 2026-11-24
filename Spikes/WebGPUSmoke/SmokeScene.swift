// The smoke test's scene and frame loop, on any `RenderDevice` (no JavaScriptKit here, so the
// same code can render a reference image with Metal): a textured cube and a metal sphere lit by a
// shadowing sun and a point light, GPU particles (compute, indirect draws), cubes with BC7 and
// ASTC textures, UI text, an MSAA render target drawn into the UI, occlusion queries, and a buffer
// update, buffer and render-target readbacks and a frame capture along the way.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene
import EngineGraphics
import EngineAssets
import EngineRendering
import EngineText
import EngineUI

@MainActor final class SmokeHost: SceneRenderHost {
    let device: RenderDevice
    var quality = RenderQuality.high
    let debugDraw = DebugDraw()
    var renderSize = (width: 1, height: 1)
    var aspectRatio: Float { Float(renderSize.width) / Float(renderSize.height) }
    var clearColor = Vec4(0, 0, 0, 1)
    var clearDepth: Float = 1
    var postProcess: PostProcessSettings?
    var postProcessor: PostProcessor?

    init(device: RenderDevice) {
        self.device = device
    }

    func jittered(_ projection: Mat4) -> Mat4 { projection }
}

@MainActor final class SmokeScene {
    let device: RenderDevice
    let host: SmokeHost
    let world = World()
    let sceneRenderer: SceneRenderer
    let ui: UIRenderer
    let list = UIDrawList()
    let counter = CountingRenderPass()
    let mode: String
    var frameIndex = 0
    var readbackCount = 0
    var capturedSize: (Int, Int)?
    var probe: GPUBuffer?
    /// An MSAA render target with UI drawn into it, shown in the window's UI.
    let panel: GPURenderTarget
    let panelList = UIDrawList()
    /// Query 0 wraps the scene's draws (visible), query 1 nothing (hidden).
    let occlusion = OcclusionQuerySet(count: 2)

    /// MSAA samples the device should have for `mode` (temporal upscalers need 1).
    static func sampleCount(mode: String) -> Int { ["fsr1", "taau"].contains(mode) ? 1 : 4 }

    init(device: RenderDevice, mode: String) throws {
        self.mode = mode
        self.device = device
        switch mode {
        case "fsr1": device.upscaler = .fsr1()
        case "taau": device.upscaler = .taau()
        default: device.upscaler = .bilinear
        }
        host = SmokeHost(device: device)
        if mode == "hdr" {
            host.postProcessor = try PostProcessor(device: device)
            _ = world.spawn(PostProcess(tonemapper: .neutral, bloom: true, bloomIntensity: 0.06))
        }
        sceneRenderer = try SceneRenderer(device: device, quality: .high)
        ui = try UIRenderer(device: device)

        // A checker texture with mips, a brick-ish normal-free material, and a plain floor.
        let size = 64
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let on = ((x / 8) + (y / 8)) % 2 == 0
                let i = (y * size + x) * 4
                pixels[i] = on ? 230 : 40
                pixels[i + 1] = on ? 120 : 60
                pixels[i + 2] = on ? 40 : 150
            }
        }
        let checker = try device.makeTexture(pixels: pixels, width: size, height: size, format: .rgba8Srgb, generateMipmaps: true)
        try sceneRenderer.registerMaterial(
            Material(baseColor: Vec4(1, 1, 1, 1), texture: checker,
                     sampler: SamplerDescriptor(minFilter: .linear, magFilter: .linear, mipFilter: .linear, addressMode: .repeat),
                     roughness: 0.5), key: "checker")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.6, 0.62, 0.66, 1), roughness: 0.8), key: "floor")
        try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.9, 0.9, 0.95, 1), metallic: 1, roughness: 0.25), key: "metal")
        try sceneRenderer.registerMesh(.sphere(radius: 0.5, segments: 48, rings: 24), key: "sphere")
        // Block-compressed textures, built by hand (TextureCodec can't encode on WebAssembly): an
        // 8x8 BC7 image of solid magenta and an ASTC 4x4 one of solid green.
        for (key, format, block) in [("bc7", TextureFormat.bc7Srgb, Self.bc7Block(r: 255, g: 40, b: 200)),
                                     ("astc", TextureFormat.astc4x4Srgb, Self.astcBlock(r: 40, g: 220, b: 90))] {
            guard device.supports(format) else {
                print("smoke: \(format) unsupported")
                try sceneRenderer.registerMaterial(Material(baseColor: Vec4(0.2, 0.2, 0.2, 1)), key: key)
                continue
            }
            let pixels = Array([[UInt8]](repeating: block, count: 4).joined())
            let texture = try device.makeTexture(levels: [TextureMipLevel(width: 8, height: 8, pixels: pixels)], format: format)
            try sceneRenderer.registerMaterial(Material(baseColor: Vec4(1, 1, 1, 1), texture: texture, roughness: 0.6), key: key)
        }
        panel = try device.makeRenderTarget(RenderTargetDescriptor(width: 256, height: 96))

        _ = world.spawn(Transform.looking(from: Vec3(3.5, 3, 6), at: Vec3(0, 0.8, 0)),
                        Camera(fovY: .pi / 3.2, near: 0.1, far: 100, clearColor: Vec4(0.45, 0.6, 0.8, 1)))
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.35))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.5, 0.8, 0.4)))),
                        DirectionalLight(intensity: 1.6, shadowExtent: 8, shadowCenter: Vec3(0, 0.5, 0)))
        _ = world.spawn(Transform(position: Vec3(-1.5, 1.2, 1.5)), PointLight(color: Vec3(1, 0.5, 0.2), intensity: 6, range: 6))
        _ = world.spawn(Transform(position: Vec3(0, -0.5, 0), scale: Vec3(12, 1, 12)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("floor"), castsShadows: false))
        _ = world.spawn(Transform(position: Vec3(0, 0.75, 0), rotation: Quat(angle: 0.6, axis: Vec3(0, 1, 0)), scale: Vec3(repeating: 1.5)),
                        Name("Cube"), MeshRenderer(mesh: .cube, material: MaterialHandle("checker")))
        _ = world.spawn(Transform(position: Vec3(1.8, 0.5, 0.8)), MeshRenderer(mesh: MeshHandle("sphere"), material: MaterialHandle("metal")))
        _ = world.spawn(Transform(position: Vec3(-0.2, 0.3, 2.2), scale: Vec3(repeating: 0.6)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("bc7")))
        _ = world.spawn(Transform(position: Vec3(0.9, 0.3, 2.4), scale: Vec3(repeating: 0.6)),
                        MeshRenderer(mesh: .cube, material: MaterialHandle("astc")))
        _ = world.spawn(Transform(position: Vec3(-1.5, 0.2, 1.5)), Name("Fire"), ParticleEmitter(
            capacity: 2048, rate: 500, prewarm: 1, lifetime: Vec2(0.5, 1.0), shape: .sphere, shapeSize: Vec3(0.2, 0.2, 0.2),
            spread: 0.35, speed: Vec2(0.6, 1.2), gravity: Vec3(0, 2, 0), drag: 0.8, size: Vec2(0.12, 0.22),
            color: [ParticleColorKey(0, Vec4(1, 0.85, 0.45, 0.9)), ParticleColorKey(1, Vec4(0.6, 0.1, 0.02, 0))],
            intensity: 3, seed: 7))
        world.propagateTransforms()
    }

    /// A BC7 block (mode 6) of one opaque color: equal endpoints, every index 0.
    static func bc7Block(r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        var bits: [Bool] = [false, false, false, false, false, false, true]  // mode 6
        func put(_ value: Int, _ count: Int) { for i in 0..<count { bits.append(value >> i & 1 == 1) } }
        for channel in [r, g, b, 255] {  // endpoints 0 and 1: the top 7 bits
            put(Int(channel) >> 1, 7)
            put(Int(channel) >> 1, 7)
        }
        put(1, 1)  // p-bits: every channel's low bit (one per endpoint, shared by the channels)
        put(1, 1)
        while bits.count < 128 { bits.append(false) }
        return (0..<16).map { byte in (0..<8).reduce(UInt8(0)) { $0 | (bits[byte * 8 + $1] ? 1 << $1 : 0) } }
    }

    /// An ASTC void-extent block: one constant color (UNORM16 channels) for the whole block.
    static func astcBlock(r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        var block: [UInt8] = [0xFC, 0xFD, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        for channel in [r, g, b, 255] { block += [channel, channel] }  // 8-bit c as 16-bit c * 257
        return block
    }

    /// Renders one frame at `width` x `height`; returns what `endFrame` returned (a capture).
    @discardableResult
    func frame(width: Int, height: Int) -> Image? {
        var captured: Image?
        let render: (width: Int, height: Int)? = ["fsr1", "taau", "bilinear"].contains(mode) ? (width * 2 / 3, height * 2 / 3) : nil
        host.renderSize = render ?? (width, height)
        device.hdrScene = mode == "hdr"
        if frameIndex == 5 { device.captureNextFrame = true }
        do {
            guard try device.beginFrame(framebufferSize: (width, height), renderSize: render) else { return nil }
            let frame = Frame(device: device, counter: counter)
            if frameIndex == 0 { probe = try device.makeBuffer([UInt32](0..<64), usage: .storage) }
            if let probe, frameIndex == 2 {
                try device.updateBuffer(probe, offset: 16, elements: [UInt32(1000), 1001])
                device.readBack(probe, offset: 12, length: 16) { bytes in
                    let values = bytes.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
                    print("smoke: buffer readback \(values)")
                }
            }
            sceneRenderer.renderOffscreen(world: world, engine: host, frame: frame)
            panelList.beginFrame(framebufferSize: (panel.width, panel.height), scale: 1)
            panelList.fillRect(UIRect(x: 8, y: 8, width: 240, height: 80), color: UIColor(0.1, 0.5, 0.3, 1), radii: UICornerRadii(12))
            panelList.drawText("render target \(frameIndex)", at: Vec2(20, 34), size: 22, color: .white)
            frame.renderPass(into: panel, clearColor: Vec4(0.9, 0.85, 0.2, 1), label: "panel") { ui.render(panelList, into: $0) }
            if frameIndex == 3 {
                device.readBack(panel) { image in
                    let i = (image.height / 2 * image.width + 12) * 4
                    print("smoke: render target readback \(image.width)x\(image.height), pixel \(image.pixels[i..<i + 4].map { $0 })")
                }
            }
            let pass = device.beginScreenPass(clearColor: host.clearColor, clearDepth: host.clearDepth)
            counter.inner = pass
            counter.beginOcclusionQuery(occlusion, index: 0)
            sceneRenderer.draw(counter)
            counter.endOcclusionQuery()
            counter.beginOcclusionQuery(occlusion, index: 1)
            counter.endOcclusionQuery()
            if frameIndex == 20 { print("smoke: occlusion results \(occlusion.results)") }
            if mode == "hdr", let postProcessor = host.postProcessor {
                let settings = host.postProcess ?? .passthrough
                device.endPass()
                guard let scene = device.sceneHDRTexture else { preconditionFailure("no HDR scene texture") }
                let inputs = postProcessor.render(scene: scene, settings: settings, dt: 1.0 / 60)
                let output = device.beginSceneOutputPass(label: "tonemap")
                postProcessor.drawOutput(into: output, scene: scene, settings: settings, inputs: inputs)
                device.endPass()
            }
            let window = device.beginWindowPass()
            list.beginFrame(framebufferSize: (width, height), scale: 1)
            list.fillRect(UIRect(x: 16, y: 16, width: 420, height: 64), color: UIColor(0, 0, 0, 0.55), radii: UICornerRadii(10))
            list.drawText("Smoke (\(device.backend.rawValue)): \(mode), frame \(frameIndex)", at: Vec2(28, 26), size: 20, color: .white)
            let times = device.gpuPassTimes.map { "\($0.name) \(String(format: "%.2f", $0.seconds * 1000))" }.joined(separator: "  ")
            list.drawText(times.isEmpty ? "GPU times pending" : "GPU ms: \(times)", at: Vec2(28, 52), size: 13,
                          color: UIColor(0.8, 0.9, 1, 1))
            list.drawImage(panel.texture, in: UIRect(x: 16, y: 92, width: 256, height: 96))
            ui.render(list, into: window)
            if let image = try device.endFrame() {
                captured = image
                capturedSize = (image.width, image.height)
                let center = (image.height / 2 * image.width + image.width / 2) * 4
                print("smoke: captured \(image.width)x\(image.height), center pixel \(image.pixels[center..<center + 4].map { $0 })")
            }
        } catch {
            print("smoke: frame \(frameIndex) failed: \(error)")
        }
        frameIndex += 1
        return captured
    }
}
