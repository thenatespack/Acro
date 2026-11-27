#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

/// Per-pixel terrain layer blending: a material drawn with mesh_terrain.frag, which samples the
/// splat map and blends up to `maxLayers` layers' textures and normal maps on the GPU (see
/// terrain_splat.glsl). The `MaterialAsset` holding it puts the layer albedo atlas in its base
/// color texture, the normal map atlas in its normal texture and the splat weights of layers 0-3
/// and 4-7 in its metallic-roughness and emissive textures; `metallic`, `roughness`,
/// `normalScale` and the sampler settings still apply. The renderer draws it through the material
/// graph path (`Material.graph`) with this shader in place of a compiled graph.
///
/// The `.terrain` importer makes one (`material/terrain`) unless the terrain has more layers than
/// that, and keeps the layers baked into one albedo (`material/terrain baked`) for low quality.
public struct TerrainSplat: Codable, Equatable, Sendable {
    /// Layers the shader blends.
    public static let maxLayers = 8
    /// Atlas columns (rows: layers / columns, rounded up).
    public static let atlasColumns = 4

    /// Meters per texture repeat, per layer (1...`maxLayers` entries).
    public var tileSizes: [Float]
    /// Layers with a normal map cell in the normal atlas.
    public var normalLayers: [Bool]
    /// The terrain's size in meters (mesh UVs 0...1 span it).
    public var size: Vec2
    /// Height samples per side: the splat textures have one texel per sample.
    public var resolution: Int
    /// Texels per side of an atlas cell (a power of two).
    public var cellSize: Int

    public init(tileSizes: [Float], normalLayers: [Bool] = [], size: Vec2, resolution: Int, cellSize: Int) {
        self.tileSizes = tileSizes
        self.normalLayers = normalLayers
        self.size = size
        self.resolution = resolution
        self.cellSize = cellSize
    }

    public var layerCount: Int { min(max(tileSizes.count, 1), Self.maxLayers) }
    public var atlasRows: Int { (layerCount + Self.atlasColumns - 1) / Self.atlasColumns }

    /// The shader's `graphValues.values` (layout in terrain_splat.glsl).
    public func values(metallic: Float, roughness: Float, normalScale: Float) -> [Vec4] {
        var mask = 0
        for (i, on) in normalLayers.prefix(Self.maxLayers).enumerated() where on { mask |= 1 << i }
        let res = Float(max(resolution, 2))
        var repeats = [Float](repeating: 1, count: 8)
        for (i, tile) in tileSizes.prefix(Self.maxLayers).enumerated() { repeats[i] = 1 / max(tile, 0.01) }
        return [Vec4(Float(layerCount), Float(mask), (res - 1) / res, 0.5 / res),
                Vec4(size.x, size.y, normalScale, roughness),
                Vec4(metallic, Float(Self.atlasColumns), Float(atlasRows), Float(max(cellSize, 1))),
                Vec4(repeats[0], repeats[1], repeats[2], repeats[3]),
                Vec4(repeats[4], repeats[5], repeats[6], repeats[7])]
    }

    /// The material graph program that draws it (nil when the shader isn't in the engine's resources).
    public func program(metallic: Float, roughness: Float, normalScale: Float) -> MaterialGraphProgram? {
        guard let shaders = Self.shaders else { return nil }
        let values = values(metallic: metallic, roughness: roughness, normalScale: normalScale)
        var program = MaterialGraphProgram(
            key: "terrain-splat", metalFragment: shaders.metal, metalFragmentColor0: shaders.metalColor0,
            spirvFragment: shaders.spirv, values: values, textures: [], usesTime: false, code: "// terrain_splat.glsl")
        program.wgslFragment = shaders.wgsl
        // WebGL 2: the uniform-block variant, its array sized to the values (always 5).
        program.glesFragment = shaders.gles.flatMap { MaterialGraphCompiler.glesSettingValueCount($0, values.count) }
        return program
    }

    private static let shaders: (metal: String, metalColor0: String?, spirv: [UInt8], wgsl: String?, gles: String?)? = {
        let bundle = Bundle.engineResources
        func url(_ ext: String) -> URL? { bundle.engineResourceURL("mesh_terrain", withExtension: ext, subdirectory: "Shaders") }
        guard let metalURL = url("frag.metal"), let spirvURL = url("frag.spv"),
              let metal = try? String(contentsOf: metalURL, encoding: .utf8), let spirv = try? Data(contentsOf: spirvURL) else {
            print("TerrainSplat: mesh_terrain.frag.metal / .spv missing from the engine's resources")
            return nil
        }
        func text(_ ext: String) -> String? { url(ext).flatMap { try? String(contentsOf: $0, encoding: .utf8) } }
        return (metal, text("frag.color0.metal"), Array(spirv), text("frag.wgsl"), text("frag.gles"))
    }()

    /// Packs `images` (nil: a cell of `colors[i]`, display sRGB 0...1) into an atlas of
    /// `cellSize` cells, `atlasColumns` across, resampling each image to the cell (bilinear,
    /// wrapping, so a cell repeats seamlessly when its image does).
    public static func atlas(images: [Image?], colors: [Vec3], cellSize: Int) -> Image {
        let count = min(max(images.count, colors.count, 1), maxLayers)
        let rows = (count + atlasColumns - 1) / atlasColumns
        let width = cellSize * atlasColumns, height = cellSize * rows
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        for layer in 0..<count {
            let ox = (layer % atlasColumns) * cellSize, oy = (layer / atlasColumns) * cellSize
            let image = layer < images.count ? images[layer].flatMap { $0.width > 0 && $0.height > 0 ? $0 : nil } : nil
            let color = layer < colors.count ? colors[layer] : Vec3(0.5, 0.5, 0.5)
            for y in 0..<cellSize {
                for x in 0..<cellSize {
                    let o = ((oy + y) * width + ox + x) * 4
                    guard let image else {
                        pixels[o] = UInt8(min(max(color.x, 0), 1) * 255 + 0.5)
                        pixels[o + 1] = UInt8(min(max(color.y, 0), 1) * 255 + 0.5)
                        pixels[o + 2] = UInt8(min(max(color.z, 0), 1) * 255 + 0.5)
                        continue
                    }
                    let sx = (Float(x) + 0.5) / Float(cellSize) * Float(image.width) - 0.5
                    let sy = (Float(y) + 0.5) / Float(cellSize) * Float(image.height) - 0.5
                    let x0 = Int(sx.rounded(.down)), y0 = Int(sy.rounded(.down))
                    let fx = sx - Float(x0), fy = sy - Float(y0)
                    func texel(_ tx: Int, _ ty: Int, _ c: Int) -> Float {
                        let wx = ((tx % image.width) + image.width) % image.width, wy = ((ty % image.height) + image.height) % image.height
                        return Float(image.pixels[(wy * image.width + wx) * 4 + c])
                    }
                    for c in 0..<3 {
                        let top = texel(x0, y0, c) * (1 - fx) + texel(x0 + 1, y0, c) * fx
                        let bottom = texel(x0, y0 + 1, c) * (1 - fx) + texel(x0 + 1, y0 + 1, c) * fx
                        pixels[o + c] = UInt8(min(max(top * (1 - fy) + bottom * fy, 0), 255) + 0.5)
                    }
                }
            }
        }
        return Image(width: width, height: height, pixels: pixels)
    }

    /// A cell size for layer images: the largest image side, as a power of two in 16...512 (64 with none).
    public static func cellSize(for images: [Image?]) -> Int {
        let largest = images.compactMap { $0.map { max($0.width, $0.height) } }.max() ?? 64
        var size = 16
        while size < min(largest, 512) { size *= 2 }
        return size
    }
}
