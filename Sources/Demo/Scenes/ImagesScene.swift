import Engine
import Foundation

/// Decoded images as textures. Nothing here is a file: each image is generated in code, encoded
/// (PNG with the engine's writer, Radiance HDR by hand), then decoded with `ImageDecoder` and
/// uploaded like a loaded asset would be.
///
/// - The floor and the two strips receding to the horizon are mipmapped (M toggles the floor's
///   mip filter). The strips hold the same black / mid-gray checker, one uploaded as sRGB color
///   and one as linear data, so they converge to different grays.
/// - The cubes show one picture as sRGB color (left) and as linear data (washed out), an HDR
///   gradient in `.rgba16Float` (values up to 4, tinted down to fit), and a texture whose
///   sub-rectangles are rewritten every frame with `updateTexture`.
final class ImagesScene: DemoScene {
    static let name = "images"
    static let summary = "decoded PNG/HDR textures: mip chains, sRGB vs linear, float format, partial updates (M toggles mips)"

    /// Matches `Params` in the textures shader.
    private struct Params {
        var uvScale: Vec4
        var tint: Vec4
    }

    /// Matches `FrameData` in the textures shader.
    private struct FrameData {
        var scroll: Vec4
    }

    private let renderer: Renderer
    private let pipeline: RenderPipeline
    private let floorTexture: GPUTexture
    private let checkerSRGB: GPUTexture
    private let checkerLinear: GPUTexture
    private let pictureSRGB: GPUTexture
    private let pictureLinear: GPUTexture
    private let hdr: GPUTexture
    private let live: GPUTexture
    private let trilinear: GPUSampler
    private let noMips: GPUSampler
    private let clamped: GPUSampler
    private let pixelated: GPUSampler
    private let floorParams: GPUBuffer
    private let stripParams: GPUBuffer
    private let faceParams: GPUBuffer
    private let hdrParams: GPUBuffer
    private var mipmapped = true
    private var blockPosition = (x: 0, y: 0)

    private static let liveSize = 32
    private static let blockSize = 8

    private let floor = [floorInstance(halfSize: 40)]
    private let strips = [
        Instance(.trs(Vec3(-9, -0.45, -20), scale: Vec3(3, 0.5, 40)), color: Vec3(1, 1, 1)),
        Instance(.trs(Vec3(15, -0.45, -20), scale: Vec3(3, 0.5, 40)), color: Vec3(1, 1, 1)),
    ]
    /// Face UVs are world-planar, so with centers on 3k + 1.5 each face shows exactly one repeat of its texture.
    private static func cube(_ x: Float) -> Instance {
        Instance(.trs(Vec3(x, 1.5, 4), scale: Vec3(repeating: 1.5)), color: Vec3(1, 1, 1))
    }

    init(renderer: Renderer) throws {
        self.renderer = renderer
        let device = renderer.device
        var descriptor = PipelineDescriptor(
            shader: try ShaderSource.load(named: "textures", bundle: .module),
            vertexLayout: Renderer.vertexLayout, instanceLayout: Renderer.instanceLayout)
        descriptor.cullMode = .back
        descriptor.writesMotionVectors = true
        pipeline = try device.makePipeline(descriptor)

        floorTexture = try device.makeTexture(image: try Self.roundTrip(Self.gridImage(size: 256)), srgb: true)
        let checker = try Self.roundTrip(Self.checkerImage(size: 64))
        checkerSRGB = try device.makeTexture(image: checker, srgb: true)
        checkerLinear = try device.makeTexture(image: checker, srgb: false)
        let picture = try Self.roundTrip(Self.pictureImage(size: 128))
        pictureSRGB = try device.makeTexture(image: picture, srgb: true)
        pictureLinear = try device.makeTexture(image: picture, srgb: false)
        hdr = try device.makeTexture(decoded: try ImageDecoder.decodeAny(Self.hdrGradientFile(width: 32, height: 16)), srgb: false)
        let size = Self.liveSize
        live = try device.makeTexture(
            pixels: Self.livePixels(size: size, block: blockPosition), width: size, height: size, format: .rgba8Unorm,
            generateMipmaps: false)

        trilinear = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat))
        noMips = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .none, addressMode: .repeat))
        clamped = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .repeat))
        pixelated = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .repeat))
        floorParams = try device.makeBuffer([Params(uvScale: Vec4(0.25, 0.25, 0, 0), tint: Vec4(1, 1, 1, 1))], usage: .uniform)
        stripParams = try device.makeBuffer([Params(uvScale: Vec4(0.0625, 0.0625, 0, 0), tint: Vec4(1, 1, 1, 1))], usage: .uniform)
        // One texture per cube face: 3 world units per texture.
        faceParams = try device.makeBuffer([Params(uvScale: Vec4(1.0 / 3, 1.0 / 3, 0, 0), tint: Vec4(1, 1, 1, 1))], usage: .uniform)
        hdrParams = try device.makeBuffer([Params(uvScale: Vec4(1.0 / 3, 1.0 / 3, 0, 0), tint: Vec4(0.25, 0.25, 0.25, 1))], usage: .uniform)
    }

    var initialView: OrbitView { OrbitView(yaw: 0.2, pitch: 0.28, distance: 26, target: Vec3(4.5, 1, 0)) }
    var lighting: Lighting { Lighting(fogDensity: 0.003) }
    var status: String { mipmapped ? "trilinear" : "no mipmaps" }

    func update(input: Input, dt: Float, time t: Float) {
        if input.wasPressed(.m) { mipmapped.toggle() }
        // Move the block around a circle and rewrite the rectangle covering its old and new
        // position in one update.
        let size = Self.liveSize, block = Self.blockSize
        let center = Float(size - block) / 2
        let next = (x: Int(center + center * cosf(t * 1.5) + 0.5), y: Int(center + center * sinf(t * 1.5) + 0.5))
        let x0 = min(blockPosition.x, next.x), y0 = min(blockPosition.y, next.y)
        let x1 = max(blockPosition.x, next.x) + block, y1 = max(blockPosition.y, next.y) + block
        let full = Self.livePixels(size: size, block: next)
        var rows: [UInt8] = []
        for y in y0..<y1 { rows += full[(y * size + x0) * 4..<(y * size + x1) * 4] }
        do {
            try renderer.device.updateTexture(live, region: TextureRegion(x: x0, y: y0, width: x1 - x0, height: y1 - y0), pixels: rows)
        } catch {
            print("Texture update failed: \(error)")
        }
        blockPosition = next
    }

    func drawShadowCasters(_ pass: RenderPass) {}

    func draw(_ pass: RenderPass) throws {
        pass.setPipeline(pipeline)
        pass.setUniformData(FrameData(scroll: Vec4(0, 0, 0, 0)), index: 3)

        pass.setUniformBuffer(floorParams, index: 2)
        pass.setTexture(floorTexture, index: 1)
        pass.setSampler(mipmapped ? trilinear : noMips, index: 1)
        renderer.draw(pass, renderer.cube, floor)

        pass.setUniformBuffer(stripParams, index: 2)
        pass.setSampler(mipmapped ? trilinear : noMips, index: 1)
        pass.setTexture(checkerSRGB, index: 1)
        renderer.draw(pass, renderer.cube, [strips[0]])
        pass.setTexture(checkerLinear, index: 1)
        renderer.draw(pass, renderer.cube, [strips[1]])

        pass.setUniformBuffer(faceParams, index: 2)
        pass.setSampler(clamped, index: 1)
        pass.setTexture(pictureSRGB, index: 1)
        renderer.draw(pass, renderer.cube, [Self.cube(-4.5)])
        pass.setTexture(pictureLinear, index: 1)
        renderer.draw(pass, renderer.cube, [Self.cube(1.5)])
        pass.setSampler(pixelated, index: 1)
        pass.setTexture(live, index: 1)
        renderer.draw(pass, renderer.cube, [Self.cube(13.5)])

        pass.setUniformBuffer(hdrParams, index: 2)
        pass.setSampler(clamped, index: 1)
        pass.setTexture(hdr, index: 1)
        renderer.draw(pass, renderer.cube, [Self.cube(7.5)])
    }

    // MARK: - Generated sources

    /// Encodes as PNG and decodes again, so the textures come from `ImageDecoder` like a loaded file.
    private static func roundTrip(_ image: Image) throws -> Image {
        try ImageDecoder.decode(image.pngData())
    }

    /// 32-pixel cells in two colors with dark grout and fine diagonal hatching.
    private static func gridImage(size: Int) -> Image {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                var color: (Int, Int, Int) = (x / 32 + y / 32) % 2 == 0 ? (236, 196, 64) : (48, 96, 206)
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
        return Image(width: size, height: size, pixels: pixels)
    }

    /// Single-pixel checker of black and mid-gray (188 is 50% in linear light when read as sRGB).
    private static func checkerImage(size: Int) -> Image {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let value: UInt8 = (x + y) % 2 == 0 ? 188 : 0
                let i = (y * size + x) * 4
                pixels[i] = value
                pixels[i + 1] = value
                pixels[i + 2] = value
            }
        }
        return Image(width: size, height: size, pixels: pixels)
    }

    /// A colorful gradient with a gray ramp across the bottom third and a mid-gray patch, where
    /// reading the bytes as sRGB or as linear differs the most.
    private static func pictureImage(size: Int) -> Image {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let i = (y * size + x) * 4
                if y >= size * 2 / 3 {
                    let ramp = UInt8(x * 255 / (size - 1))
                    pixels[i] = ramp
                    pixels[i + 1] = ramp
                    pixels[i + 2] = ramp
                } else {
                    let phase = Float(x + y) / Float(size) * Float.pi * 2
                    pixels[i] = UInt8(x * 255 / (size - 1))
                    pixels[i + 1] = UInt8(y * 255 / (size * 2 / 3))
                    pixels[i + 2] = UInt8(127.5 + 127.5 * sinf(phase))
                }
            }
        }
        return Image(width: size, height: size, pixels: pixels)
    }

    /// A Radiance HDR file (flat RGBE) whose red ramps from 0 to 4 along x and green from 0 to 1
    /// down y, so values above 1 only survive in a float texture.
    private static func hdrGradientFile(width: Int, height: Int) -> Data {
        var data = Data("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y \(height) +X \(width)\n".utf8)
        for y in 0..<height {
            for x in 0..<width {
                let r = 4 * Float(x) / Float(width - 1), g = Float(y) / Float(height - 1), b: Float = 0.25
                let peak = max(r, g, b)
                var mantissa = [UInt8](repeating: 0, count: 4)
                if peak > 1e-32 {
                    let exponent = Int(ceilf(log2f(peak + 1e-6)))
                    let scale = powf(2, Float(-exponent)) * 255.999
                    mantissa = [UInt8(r * scale), UInt8(g * scale), UInt8(b * scale), UInt8(exponent + 128)]
                }
                data.append(contentsOf: mantissa)
            }
        }
        return data
    }

    /// A dark blue-gray background with one bright block at `block`.
    private static func livePixels(size: Int, block: (x: Int, y: Int)) -> [UInt8] {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let inside = x >= block.x && x < block.x + blockSize && y >= block.y && y < block.y + blockSize
                let hatch = (x / 4 + y / 4) % 2 == 0
                let color: (UInt8, UInt8, UInt8) = inside ? (255, 120, 40) : hatch ? (40, 48, 70) : (30, 36, 54)
                let i = (y * size + x) * 4
                pixels[i] = color.0
                pixels[i + 1] = color.1
                pixels[i + 2] = color.2
            }
        }
        return pixels
    }
}
