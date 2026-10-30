import Engine
import Foundation

/// Textures, samplers and uniform buffers. A procedural tile texture (no asset files) repeats
/// across the floor with a trilinear sampler, so it stays smooth toward the horizon; a small
/// linear-format data texture is magnified with a nearest sampler on a row of cubes. M toggles
/// the floor's mip filter to show the difference.
final class TexturesScene: DemoScene {
    static let name = "textures"
    static let summary = "sRGB + linear textures, repeat/mipmapped samplers, static and per-frame uniform buffers (M toggles mips)"

    /// Matches `Params` in the shaders: bound with `setUniformBuffer` from a static `GPUBuffer`.
    private struct Params {
        /// xy: world-to-UV scale, zw: unused.
        var uvScale: Vec4
        var tint: Vec4
    }

    /// Matches `FrameData`: copied into transient memory every frame with `setUniformData`.
    private struct FrameData {
        /// xy: UV scroll offset.
        var scroll: Vec4
    }

    private let renderer: Renderer
    private let pipeline: RenderPipeline
    private let tiles: GPUTexture
    private let gradient: GPUTexture
    private let trilinear: GPUSampler
    private let noMips: GPUSampler
    private let pixelated: GPUSampler
    private let floorParams: GPUBuffer
    private let cubeParams: GPUBuffer
    private var floor: [Instance] = [floorInstance(halfSize: 26)]
    private var cubes: [Instance] = []
    private var mipmapped = true
    private var time: Float = 0

    init(renderer: Renderer) throws {
        self.renderer = renderer
        let device = renderer.device
        var descriptor = PipelineDescriptor(
            shader: try ShaderSource.load(named: "textures", bundle: .module),
            vertexLayout: Renderer.vertexLayout, instanceLayout: Renderer.instanceLayout)
        descriptor.cullMode = .back
        pipeline = try device.makePipeline(descriptor)

        let size = 256
        tiles = try device.makeTexture(
            pixels: Self.tilePixels(size: size), width: size, height: size, format: .rgba8Srgb, generateMipmaps: true)
        gradient = try device.makeTexture(
            pixels: Self.gradientPixels(size: 8), width: 8, height: 8, format: .rgba8Unorm, generateMipmaps: false)
        trilinear = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat))
        noMips = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .repeat))
        pixelated = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .repeat))
        floorParams = try device.makeBuffer(
            [Params(uvScale: Vec4(0.25, 0.25, 0, 0), tint: Vec4(1, 1, 1, 1))], usage: .uniform)
        cubeParams = try device.makeBuffer(
            [Params(uvScale: Vec4(0.5, 0.5, 0, 0), tint: Vec4(1, 1, 1, 1))], usage: .uniform)

        for i in 0..<5 {
            let scale = 0.8 + Float(i % 3) * 0.3
            cubes.append(Instance(.trs(Vec3(Float(i - 2) * 4.5, scale, 2), scale: Vec3(repeating: scale)), color: Vec3(1, 1, 1)))
        }
    }

    var initialView: OrbitView { OrbitView(yaw: 0.45, pitch: 0.3, distance: 30, target: Vec3(0, 1, 0)) }
    var lighting: Lighting { Lighting(fogDensity: 0.004) }
    var status: String { mipmapped ? "trilinear" : "no mipmaps" }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.m) { mipmapped.toggle() }
        time = t
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(pipeline)
        pass.setUniformData(FrameData(scroll: Vec4(time * 0.03, 0, 0, 0)), index: 3)

        pass.setUniformBuffer(floorParams, index: 2)
        pass.setTexture(tiles, index: 1)
        pass.setSampler(mipmapped ? trilinear : noMips, index: 1)
        renderer.draw(pass, renderer.cube, floor)

        pass.setUniformBuffer(cubeParams, index: 2)
        pass.setTexture(gradient, index: 1)
        pass.setSampler(pixelated, index: 1)
        renderer.draw(pass, renderer.cube, cubes)
    }

    /// 32-pixel cells in two colors with dark grout, plus 1-pixel diagonal hatching: fine
    /// detail that shimmers without mipmaps. Integer math only, so it is deterministic.
    private static func tilePixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let checker = (x / 32 + y / 32) % 2 == 0
                var color: (Int, Int, Int) = checker ? (236, 196, 64) : (48, 96, 206)
                if x % 32 < 2 || y % 32 < 2 {
                    color = (28, 28, 34)
                } else if (x + y) % 4 == 0 {
                    color = (color.0 * 6 / 10, color.1 * 6 / 10, color.2 * 6 / 10)
                }
                let i = (y * size + x) * 4
                pixels[i] = UInt8(color.0)
                pixels[i + 1] = UInt8(color.1)
                pixels[i + 2] = UInt8(color.2)
            }
        }
        return pixels
    }

    /// Data (not color) values: red ramps along x, green along y.
    private static func gradientPixels(size: Int) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let i = (y * size + x) * 4
                pixels[i] = UInt8(x * 255 / (size - 1))
                pixels[i + 1] = UInt8(y * 255 / (size - 1))
                pixels[i + 2] = UInt8(((x + y) % 2) * 80 + 60)
            }
        }
        return pixels
    }
}
