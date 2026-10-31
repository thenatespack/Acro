import Engine
import Foundation

/// Block-compressed textures: the same three images uploaded as RGBA8, BC7 and ASTC 4x4 (each
/// with its full mip chain), side by side. Rows: the Khronos BoomBox's base color (sRGB, JPEG)
/// and normal map (linear: equal channel weights), and a generated picture of hard edges,
/// one-texel lines, gradients and a gray ramp, the worst case for 4x4 blocks. Each image is
/// shown minified with trilinear filtering (sampling the mips) next to a magnified, nearest-
/// sampled crop where the blocks show. Column headers give the GPU memory of the three
/// textures; the title gives encode times. A GPU without a format draws the decoded RGBA8
/// fallback (`makeTexture(compressedLevels:format:)`), marked "decoded".
///
/// The last row lights a crop of the normal map with `SceneRenderer`'s mesh shader (a grazing
/// sun on a glossy plane, rendered into small targets): RGBA8 next to the map itself, then the
/// RGB encodings (BC7, ASTC 4x4) next to the two-channel ones (BC5, two-channel ASTC), whose Z
/// the shader rebuilds. Labels give each encoding's mean (and largest) angular error.
///
/// The UI is drawn in the window pass, like the `ui` scene.
final class CompressionScene: DemoScene {
    static let name = "compression"
    static let summary = "BC7, ASTC 4x4 and two-channel normal-map textures (BC5, ASTC RG; Z rebuilt in the mesh shader) next to RGBA8"

    private struct Column {
        var title: String
        var textures: [GPUTexture]
        var bytes: Int
        var note: String
        /// Per image: level 0's PSNR against the source, in dB (empty for RGBA8).
        var psnr: [Double] = []
    }

    private let columns: [Column]
    private let rowLabels = ["BoomBox base color (sRGB)", "BoomBox normal map (linear)", "Lines, edges, ramps (sRGB)"]
    private let trilinear: GPUSampler
    private let pixelated: GPUSampler
    let status: String

    /// The lit row: one plane per normal-map variant, each rendered into its own target.
    private struct LitPanel {
        var title: String
        var target: RenderTarget
        var view: SceneView
    }
    private let world = World()
    private let sceneRenderer: SceneRenderer
    /// Per column: the left and right lit panels (the RGBA8 column has one; its right slot shows
    /// the normal map crop).
    private var litPanels: [[LitPanel]] = []
    private var litLabels: [String] = []
    /// The part of the normal map the lit planes show (UV).
    private static let litCrop = UIRect(x: 0.36, y: 0.30, width: 0.25, height: 0.25)

    private static let panel = UIColor(hex: 0x1d2330)
    private static let line = UIColor(hex: 0x39425a)
    private static let text = UIColor(hex: 0xe6e9f0)
    private static let dim = UIColor(hex: 0x9aa3b5)

    init(renderer: Renderer) throws {
        let device = renderer.device
        let (baseColor, normal) = try Self.boomBoxImages()
        let sources: [(image: Image, srgb: Bool)] = [(baseColor, true), (normal, false), (Self.pictureImage(size: 256), true)]

        var columns = [Column(title: "RGBA8", textures: try sources.map { try device.makeTexture(image: $0.image, srgb: $0.srgb) },
                              bytes: sources.reduce(0) { $0 + Self.rgba8Bytes($1.image) }, note: "")]
        var times: [String] = []
        for (title, compression) in [("BC7", TextureCompression.bc7), ("ASTC 4x4", .astc)] {
            var textures: [GPUTexture] = [], bytes = 0, seconds = 0.0, decoded = false, psnr: [Double] = []
            for source in sources {
                let format = compression.format(srgb: source.srgb)!
                let start = Date()
                let levels = try TextureCodec.encode(source.image, format: format)
                seconds += Date().timeIntervalSince(start)
                textures.append(try device.makeTexture(compressedLevels: levels, format: format))
                bytes += levels.reduce(0) { $0 + $1.pixels.count }
                decoded = decoded || !device.supports(format)
                psnr.append(Self.psnr(source.image.pixels, try TextureCodec.decode(levels[0], format: format).pixels))
            }
            columns.append(Column(title: title, textures: textures, bytes: bytes, note: decoded ? "decoded: GPU lacks it" : "",
                                  psnr: psnr))
            times.append("\(title) \(Int((seconds * 1000).rounded())) ms")
        }
        self.columns = columns

        // Two-channel normal maps: X and Y of the normalized map, Z rebuilt by the shader.
        let reference = TextureCodec.normalized(normalMap: normal)
        var normalMaps: [(title: String, texture: GPUTexture, error: (mean: Double, max: Double))] = [
            ("RGBA8", columns[0].textures[1], (0, 0)),
        ]
        for (i, format) in [TextureFormat.bc7Unorm, .bc5Unorm, .astc4x4Unorm, .astc4x4RG].enumerated() {
            let title = ["BC7", "BC5", "ASTC", "ASTC RG"][i]
            let start = Date()
            let levels = try TextureCodec.encode(format.isTwoChannel ? reference : normal, format: format)
            if format.isTwoChannel { times.append("\(title) \(Int((Date().timeIntervalSince(start) * 1000).rounded())) ms") }
            let texture = format.isTwoChannel
                ? try device.makeTexture(compressedLevels: levels, format: format) : columns[1 + i / 2].textures[1]
            normalMaps.append((title, texture, Self.angularError(reference, try TextureCodec.decode(levels[0], format: format), format: format)))
        }
        status = "encoded " + times.joined(separator: ", ") + " (\(sources.map { "\($0.image.width)²" }.joined(separator: ", ")), normal quality)"
        trilinear = try device.makeSampler(SamplerDescriptor(filter: .linear, mipFilter: .linear, addressMode: .clampToEdge))
        pixelated = try device.makeSampler(SamplerDescriptor(filter: .nearest, mipFilter: .none, addressMode: .clampToEdge))

        // The lit row: a glossy gray plane per normal map, 10 units apart, each seen head-on by an
        // orthographic camera that it fills; a low sun from the upper left rakes across the bumps.
        sceneRenderer = try SceneRenderer(device: device, quality: renderer.quality)
        _ = world.spawn(SceneEnvironment(ambientIntensity: 0.25, fogDensity: 0))
        _ = world.spawn(Transform(rotation: .lookRotation(forward: -normalize(Vec3(-0.75, 0.45, 0.35)))),
                        DirectionalLight(intensity: 2.2))
        var panels: [LitPanel] = []
        for (i, map) in normalMaps.enumerated() {
            try sceneRenderer.registerMaterial(Material(
                baseColor: Vec4(0.5, 0.5, 0.52, 1), uvScale: Vec2(Self.litCrop.width, Self.litCrop.height),
                uvOffset: Vec2(Self.litCrop.x, Self.litCrop.y), roughness: 0.35, normalTexture: map.texture), key: "lit \(i)")
            let center = Vec3(Float(i) * 10, 0, 0)
            _ = world.spawn(Transform(position: center, rotation: Quat(angle: .pi / 2, axis: Vec3(1, 0, 0)), scale: Vec3(2.02, 1, 2.02)),
                            MeshRenderer(mesh: .plane, material: MaterialHandle("lit \(i)"), castsShadows: false))
            let view = SceneView(view: Mat4.lookAt(eye: center + Vec3(0, 0, 3), target: center),
                                 projection: Mat4.orthographic(left: -1, right: 1, bottom: -1, top: 1, near: 0.1, far: 10))
            panels.append(LitPanel(title: map.title, target: try RenderTarget(device: device, width: 128, height: 128,
                                                                               multisampled: false, label: "lit \(i)"), view: view))
        }
        world.propagateTransforms()
        litPanels = [[panels[0]], [panels[1], panels[2]], [panels[3], panels[4]]]
        func error(_ i: Int) -> String {
            String(format: "%@ %.2f°/%.0f°", normalMaps[i].title, normalMaps[i].error.mean, normalMaps[i].error.max)
        }
        litLabels = ["Lit by the mesh shader | its normal map", error(1) + " | " + error(2) + " mean/max",
                     error(3) + " | " + error(4)]
    }

    func renderOffscreen(engine: Engine, frame: Frame) {
        sceneRenderer.beginViews(world: world, frame: frame)
        for panel in litPanels.joined() {
            do {
                try panel.target.resize(toPoints: Vec2(Self.imageSize, Self.imageSize), scale: engine.ui.scale)
            } catch {
                print("compression: resizing a target failed: \(error)")
            }
            sceneRenderer.renderView(panel.view, into: panel.target, frame: frame)
        }
    }

    var lighting: Lighting { Lighting(fogColor: Vec3(0.004, 0.005, 0.009)) }
    var initialView: OrbitView { OrbitView(distance: 10) }

    func drawShadowCasters(_ pass: RenderPass) {}
    func draw(_ pass: RenderPass) throws {}

    func drawUI(_ ui: UIDrawList) {
        let canvas = UIRect(x: 0, y: 0, width: 1280, height: 720)
        let origin = Vec2(max((ui.size.x - canvas.width) / 2, 0), max((ui.size.y - canvas.height) / 2, 0))
        func at(_ x: Float, _ y: Float, _ w: Float, _ h: Float) -> UIRect {
            UIRect(x: origin.x + x, y: origin.y + y, width: w, height: h)
        }
        let image = Self.imageSize, gap: Float = 12, columnWidth: Float = 2 * image + 3 * gap
        let left: Float = (canvas.width - 3 * columnWidth - 2 * 16) / 2
        for (c, column) in columns.enumerated() {
            let x = left + Float(c) * (columnWidth + 16)
            ui.fillRect(at(x, 16, columnWidth, 688), color: Self.panel, radii: UICornerRadii(10))
            ui.strokeRect(at(x, 16, columnWidth, 688), color: Self.line, width: 1, radii: UICornerRadii(10))
            ui.drawText(column.title, at: Vec2(origin.x + x + gap, origin.y + 26), size: 20, color: Self.text)
            let size = String(format: "%.2f MiB", Double(column.bytes) / 1_048_576)
                + (c == 0 ? "" : String(format: " (%.0f%%)", 100 * Double(column.bytes) / Double(columns[0].bytes)))
            ui.drawText(size, at: Vec2(origin.x + x + gap, origin.y + 52), size: 15, color: Self.dim)
            if !column.note.isEmpty {
                ui.drawText(column.note, at: Vec2(origin.x + x + 180, origin.y + 30), size: 13, color: UIColor(hex: 0xff9f0a))
            }
            for (r, texture) in column.textures.enumerated() {
                let y = 84 + Float(r) * Self.rowPitch
                let quality = r < column.psnr.count ? String(format: ", %.1f dB", column.psnr[r]) : ""
                ui.drawText(rowLabels[r] + quality, at: Vec2(origin.x + x + gap, origin.y + y), size: 13, color: Self.dim)
                // Whole image, minified (trilinear: the mip chain), and a crop magnified with
                // nearest sampling, where the 4x4 blocks show.
                ui.drawImage(texture, in: at(x + gap, y + 20, image, image), sampler: trilinear)
                let crop = Self.crops[r]
                ui.drawImage(texture, in: at(x + 2 * gap + image, y + 20, image, image), uv: crop, sampler: pixelated)
                ui.strokeRect(at(x + gap + crop.x * image, y + 20 + crop.y * image, crop.width * image, crop.height * image),
                              color: UIColor(hex: 0xffd60a).withAlpha(0.8), width: 1)
                if r == 1 {
                    // Where the lit row's crop comes from.
                    let lit = Self.litCrop
                    ui.strokeRect(at(x + gap + lit.x * image, y + 20 + lit.y * image, lit.width * image, lit.height * image),
                                  color: UIColor(hex: 0x64d2ff).withAlpha(0.8), width: 1)
                }
            }
            // The lit row: the mesh shader's view of the normal maps.
            let y = 84 + 3 * Self.rowPitch
            ui.drawText(litLabels[c], at: Vec2(origin.x + x + gap, origin.y + y), size: 12, color: Self.dim)
            for (p, panel) in litPanels[c].enumerated() {
                ui.drawImage(panel.target.texture, in: at(x + gap + Float(p) * (image + gap), y + 20, image, image))
            }
            if litPanels[c].count == 1 {
                ui.drawImage(column.textures[1], in: at(x + 2 * gap + image, y + 20, image, image), uv: Self.litCrop, sampler: trilinear)
            }
        }
    }

    /// Size of each image and distance between rows, in canvas points.
    private static let imageSize: Float = 128
    private static let rowPitch: Float = 154

    /// Mean and largest angle in degrees between the normals of `reference` (RGB) and those a
    /// decoded `format` level stands for, as the mesh shader reads them.
    private static func angularError(_ reference: Image, _ decoded: Image, format: TextureFormat) -> (mean: Double, max: Double) {
        var total = 0.0, worst = 0.0
        for texel in 0..<reference.width * reference.height {
            let a = TextureCodec.normal(reference.pixels, at: texel, format: .rgba8Unorm)
            let b = TextureCodec.normal(decoded.pixels, at: texel, format: format)
            let angle = Double(acosf(min(max(dot(a, b), -1), 1))) * 180 / .pi
            total += angle
            worst = max(worst, angle)
        }
        return (total / Double(reference.width * reference.height), worst)
    }

    /// The magnified region of each row's image (in UV).
    private static let crops = [
        UIRect(x: 0.23, y: 0.47, width: 0.06, height: 0.06),
        UIRect(x: 0.45, y: 0.45, width: 0.08, height: 0.08),
        UIRect(x: 0.30, y: 0.06, width: 0.09, height: 0.09),
    ]

    /// Peak signal-to-noise ratio of `b` against `a` over RGBA, in dB.
    private static func psnr(_ a: [UInt8], _ b: [UInt8]) -> Double {
        var squared = 0.0
        for (x, y) in zip(a, b) {
            let d = Double(Int(x) - Int(y))
            squared += d * d
        }
        return squared == 0 ? 99 : 10 * log10(255 * 255 * Double(a.count) / squared)
    }

    /// RGBA8 bytes of an image with its full mip chain.
    private static func rgba8Bytes(_ image: Image) -> Int {
        var (width, height, total) = (image.width, image.height, 0)
        while true {
            total += width * height * 4
            if width == 1 && height == 1 { return total }
            (width, height) = (max(width / 2, 1), max(height / 2, 1))
        }
    }

    /// The BoomBox's base color and normal map, decoded.
    private static func boomBoxImages() throws -> (baseColor: Image, normal: Image) {
        guard let url = Bundle.module.url(forResource: "BoomBox", withExtension: "glb", subdirectory: "Models") else {
            throw GraphicsError("Models/BoomBox.glb is missing from the Demo bundle")
        }
        let model = try GLTFReader.read(contentsOf: url)
        let material = try model.materials.first.unwrap("BoomBox has no material")
        func image(_ texture: Int?) throws -> Image {
            let index = try texture.flatMap { model.textures[$0].image }.unwrap("BoomBox texture missing")
            return try ImageDecoder.decode(model.images[index].data)
        }
        return (try image(material.baseColorTexture?.texture), try image(material.normalTexture?.texture))
    }

    /// Color gradients, one-texel lines in several colors, a hard-edged checker, a disc and a
    /// gray ramp: everything 4x4 blocks with two endpoints find hard.
    private static func pictureImage(size: Int) -> Image {
        var pixels = [UInt8](repeating: 255, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let u = Float(x) / Float(size - 1), v = Float(y) / Float(size - 1)
                var c: (Float, Float, Float) = (u, v, 0.5 + 0.5 * sinf((u - v) * 9))
                if y >= size * 3 / 4 {
                    c = (u, u, u)
                } else if x % 16 == 0 {
                    c = (1, 0.1, 0.1)
                } else if y % 16 == 0 {
                    c = (0.1, 0.3, 1)
                } else if (x + y) % 32 == 5 {
                    c = (1, 1, 1)
                } else if x < size / 4 && y > size / 2 {
                    c = ((x / 4 + y / 4) % 2 == 0) ? (0.05, 0.05, 0.05) : (0.95, 0.8, 0.2)
                }
                let dx = u - 0.68, dy = v - 0.35
                if dx * dx + dy * dy < 0.02 { c = (0.2, 0.8, 0.3) }
                let i = (y * size + x) * 4
                pixels[i] = UInt8(c.0 * 255)
                pixels[i + 1] = UInt8(c.1 * 255)
                pixels[i + 2] = UInt8(c.2 * 255)
            }
        }
        return Image(width: size, height: size, pixels: pixels)
    }
}

private extension Optional {
    func unwrap(_ message: String) throws -> Wrapped {
        guard let value = self else { throw GraphicsError(message) }
        return value
    }
}

extension TextureCompression {
    /// `DEMO_TEXTURE_COMPRESSION` (`none`, `auto`, `bc7`, `astc`, `bc5`, `astcRG`): how the `pbr`
    /// and `gltf` scenes compress their glTF textures. Off by default.
    @MainActor static let demoSetting: TextureCompression = {
        guard let value = ProcessInfo.processInfo.environment["DEMO_TEXTURE_COMPRESSION"] else { return .none }
        guard let setting = TextureCompression(rawValue: value) else {
            print("DEMO_TEXTURE_COMPRESSION=\(value) isn't one of \(TextureCompression.allCases.map(\.rawValue)); not compressing")
            return .none
        }
        return setting
    }()
}
