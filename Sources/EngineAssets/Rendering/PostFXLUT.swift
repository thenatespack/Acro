#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineGraphics

// LUT grading (`PostProcessSettings.lut`): a 3D color lookup table applied in the tonemap pass,
// after tonemapping and before lift / gamma / gain (so a `ScreenFade`, which folds into those,
// still fades to its exact color).
//
// A LUT of size N is stored as a horizontal strip, N² wide and N high: slice b (blue) is the
// N x N square at x = b·N, red runs along x and green along y inside it. Inputs and outputs are
// sRGB-encoded display values (what grading tools export): the shader encodes the tonemapped
// color, looks it up with trilinear interpolation (8 exact texel loads, the same on every
// backend), decodes the result and mixes it in by `lutIntensity`.
//
// Sources, imported by `LUTImporter` ("lut") into a linear, unmipmapped texture:
// - `.cube` files (Adobe / Resolve 3D LUTs: `LUT_3D_SIZE`, then N³ lines "r g b", red fastest);
// - strip images (PNG and the other image formats, N² x N, e.g. a neutral strip graded in an
//   image editor): give the file's sidecar `"importer": "lut"` (otherwise it imports as a
//   color texture, which works too but may be compressed when cooking, which ruins it).

public enum PostFXLUT {
    /// The sizes a LUT may have (2...64: a 64 strip is 4096 wide).
    public static let sizes = 2...64

    /// An identity strip of size `n` (output = input): a starting point for grading in an image editor.
    public static func identity(size n: Int) -> FloatImage {
        var pixels = [Float](repeating: 1, count: n * n * n * 4)
        let scale = 1 / Float(n - 1)
        for b in 0..<n {
            for g in 0..<n {
                for r in 0..<n {
                    let i = (g * n * n + b * n + r) * 4
                    pixels[i] = Float(r) * scale
                    pixels[i + 1] = Float(g) * scale
                    pixels[i + 2] = Float(b) * scale
                }
            }
        }
        return FloatImage(width: n * n, height: n, pixels: pixels)
    }

    /// The LUT size of a strip `width` x `height`, or nil if it isn't one.
    public static func size(width: Int, height: Int) -> Int? {
        sizes.contains(height) && width == height * height ? height : nil
    }

    /// A parsed `.cube` file as a strip, plus problems that didn't stop it.
    public static func parseCube(_ text: String) throws -> (strip: FloatImage, warnings: [String]) {
        var size: Int?
        var values: [Float] = []
        var warnings: [String] = []
        var domainMin: [Float] = [0, 0, 0], domainMax: [Float] = [1, 1, 1]
        for (number, raw) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            switch parts[0].uppercased() {
            case "TITLE": continue
            case "LUT_1D_SIZE": throw AssetError.unreadable("1D LUTs (LUT_1D_SIZE) aren't supported; export a 3D LUT")
            case "LUT_3D_SIZE":
                guard parts.count == 2, let n = Int(parts[1]), sizes.contains(n) else {
                    throw AssetError.unreadable("line \(number + 1): LUT_3D_SIZE must be \(sizes.lowerBound)...\(sizes.upperBound)")
                }
                size = n
            case "DOMAIN_MIN", "DOMAIN_MAX":
                let v = parts.dropFirst().compactMap(Float.init)
                guard v.count == 3 else { throw AssetError.unreadable("line \(number + 1): \(parts[0]) needs three numbers") }
                if parts[0].uppercased() == "DOMAIN_MIN" { domainMin = v } else { domainMax = v }
            case "LUT_3D_INPUT_RANGE", "LUT_1D_INPUT_RANGE":
                warnings.append("\(parts[0]) is ignored (inputs are taken as 0...1)")
            default:
                let v = parts.compactMap(Float.init)
                guard v.count == 3, parts.count == 3 else {
                    if Float(parts[0]) == nil {
                        warnings.append("line \(number + 1): unknown keyword \(parts[0]) ignored")
                        continue
                    }
                    throw AssetError.unreadable("line \(number + 1): expected three numbers")
                }
                values.append(contentsOf: v)
            }
        }
        guard let n = size else { throw AssetError.unreadable("no LUT_3D_SIZE line") }
        guard values.count == n * n * n * 3 else {
            throw AssetError.unreadable("LUT_3D_SIZE \(n) needs \(n * n * n) entries, the file has \(values.count / 3)")
        }
        if domainMin != [0, 0, 0] || domainMax != [1, 1, 1] { warnings.append("DOMAIN_MIN / DOMAIN_MAX other than 0...1 are ignored") }
        var pixels = [Float](repeating: 1, count: n * n * n * 4)
        for b in 0..<n {
            for g in 0..<n {
                for r in 0..<n {
                    let source = ((b * n + g) * n + r) * 3  // red fastest, then green, then blue
                    let target = (g * n * n + b * n + r) * 4
                    pixels[target] = values[source]
                    pixels[target + 1] = values[source + 1]
                    pixels[target + 2] = values[source + 2]
                }
            }
        }
        return (FloatImage(width: n * n, height: n, pixels: pixels), warnings)
    }

    /// A strip from an imported texture (a `.cube` import is float already; an 8-bit image's
    /// codes become 0...1), or nil if its size isn't a strip's.
    public static func strip(from texture: TextureAsset) -> FloatImage? {
        let image: FloatImage
        switch texture.pixels {
        case .rgbaFloat(let float): image = float
        default:
            let bytes = texture.image
            image = FloatImage(width: bytes.width, height: bytes.height, pixels: bytes.pixels.map { Float($0) / 255 })
        }
        return size(width: image.width, height: image.height) == nil ? nil : image
    }

    static func srgbEncode(_ x: Float) -> Float { x <= 0.0031308 ? x * 12.92 : 1.055 * powf(x, 1 / 2.4) - 0.055 }
    static func srgbDecode(_ x: Float) -> Float { x <= 0.04045 ? x / 12.92 : powf((x + 0.055) / 1.055, 2.4) }

    /// `color` (linear, 0...1) through the strip `lut` as the tonemap pass does it: encoded to
    /// sRGB, looked up trilinearly, decoded, mixed in by `intensity`.
    public static func apply(_ color: Vec3, lut: FloatImage, intensity: Float) -> Vec3 {
        let n = lut.height
        func clamp01(_ v: Float) -> Float { min(max(v, 0), 1) }
        let s = [color.x, color.y, color.z].map { clamp01(srgbEncode(clamp01($0))) * Float(n - 1) }
        let i0 = s.map { min(Int($0.rounded(.down)), n - 2) }
        let f = zip(s, i0).map { $0 - Float($1) }
        func texel(_ r: Int, _ g: Int, _ b: Int) -> Vec3 {
            let i = (g * lut.width + b * n + r) * 4
            return Vec3(lut.pixels[i], lut.pixels[i + 1], lut.pixels[i + 2])
        }
        func lerp(_ a: Vec3, _ b: Vec3, _ t: Float) -> Vec3 { a + (b - a) * t }
        let (r, g, b) = (i0[0], i0[1], i0[2])
        let c00 = lerp(texel(r, g, b), texel(r + 1, g, b), f[0])
        let c10 = lerp(texel(r, g + 1, b), texel(r + 1, g + 1, b), f[0])
        let c01 = lerp(texel(r, g, b + 1), texel(r + 1, g, b + 1), f[0])
        let c11 = lerp(texel(r, g + 1, b + 1), texel(r + 1, g + 1, b + 1), f[0])
        let graded = lerp(lerp(c00, c10, f[1]), lerp(c01, c11, f[1]), f[2])
        let decoded = Vec3(srgbDecode(clamp01(graded.x)), srgbDecode(clamp01(graded.y)), srgbDecode(clamp01(graded.z)))
        return lerp(color, decoded, clamp01(intensity))
    }
}

/// Imports `.cube` LUTs, and strip images whose sidecar names this importer, as a LUT strip
/// texture (linear, no mipmaps; see `PostFXLUT`).
public struct LUTImporter: AssetImporter {
    public init() {}

    public var name: String { "lut" }
    public var fileExtensions: [String] { ["cube"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let data = try context.data()
        let texture: TextureAsset
        if context.assetPath.pathFileExtension.lowercased() == "cube" {
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                throw AssetError.unreadable("not a text file")
            }
            let (strip, warnings) = try PostFXLUT.parseCube(text)
            for warning in warnings { context.warn(warning) }
            texture = TextureAsset(floatImage: strip, generatesMipmaps: false)
        } else {
            let image = try ImageDecoder.decode(data)
            guard PostFXLUT.size(width: image.width, height: image.height) != nil else {
                throw AssetError.unreadable("a LUT strip is N² x N pixels (N = 2...64), this image is \(image.width) x \(image.height)")
            }
            texture = TextureAsset(image: image, isSRGB: false, generatesMipmaps: false)
        }
        var asset = ImportedAsset()
        asset.add("texture", name: context.assetPath.pathLastComponent.pathDeletingExtension, .texture(texture))
        asset.main = "texture"
        return asset
    }
}
