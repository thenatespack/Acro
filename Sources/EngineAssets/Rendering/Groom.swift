/// Fur and hair at run time: a `GroomRenderer` on an entity that has a `MeshRenderer` grows the
/// fur of a groom (`.groom` file, GroomBuild.swift) on that entity's mesh.
///
/// The groom reaches the renderer as a material: the `.groom` importer's `material/fur`, whose
/// `MaterialFur` carries the whole groom (and its mask and flow images, small enough to sample
/// on the CPU). `SceneRenderer` builds the fur meshes from the entity's mesh the first time it
/// draws the pair (GroomGeometry.swift; skinned meshes keep their skin, so fur follows animated
/// characters) and draws:
/// - shell fur: the shell mesh once per shell, as instances of one draw (each instance a shell
///   height), cut to strands in mesh_fur.frag;
/// - hair cards: the card mesh, with alpha-to-coverage;
/// - both: an opaque undercoat shell in the fur's root color just above the surface, which is
///   all that is drawn past the groom's last detail distance.
/// Wind (`SceneEnvironment.wind` x `GroomBuild.wind`) and a spring per bone (skinned) or per
/// entity bend the strands; fur doesn't cast shadows (the mesh under it does).
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

public struct GroomRenderer: Component, Codable, Equatable, Sendable {
    public static let componentName = "GroomRenderer"
    public static var fieldHints: [String: FieldHints] {
        ["groom": FieldHints(tooltip: "A .groom file's fur material (asset:<id>#material/fur); groom.apply sets it"),
         "tint": FieldHints(color: true, tooltip: "Multiplies the groom's colors (linear)"),
         "receivesShadows": FieldHints(tooltip: "Darken the fur in shadows"),
         "isVisible": FieldHints(tooltip: "Draw the fur")]
    }

    /// The groom's fur material ("asset:<id>#material/fur", or a key registered in code).
    public var groom: MaterialHandle
    /// Linear RGB multiplied with the groom's colors.
    public var tint: Vec3
    public var receivesShadows: Bool
    public var isVisible: Bool

    public init(groom: MaterialHandle = MaterialHandle(""), tint: Vec3 = Vec3(1, 1, 1), receivesShadows: Bool = true, isVisible: Bool = true) {
        self.groom = groom
        self.tint = tint
        self.receivesShadows = receivesShadows
        self.isVisible = isVisible
    }

    private enum CodingKeys: String, CodingKey { case groom, tint, receivesShadows, isVisible }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(groom: try c.decodeIfPresent(MaterialHandle.self, forKey: .groom) ?? MaterialHandle(""),
                  tint: try c.decodeIfPresent(Vec3.self, forKey: .tint) ?? Vec3(1, 1, 1),
                  receivesShadows: try c.decodeIfPresent(Bool.self, forKey: .receivesShadows) ?? true,
                  isVisible: try c.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true)
    }

    /// The fur material of the `.groom` asset `id` (what `GroomImporter` names `material/fur`).
    public static func material(ofGroom id: AssetID) -> MaterialHandle { MaterialHandle(AssetReference(id, subAsset: furSubAsset)) }

    /// The sub-asset id of a groom's fur material.
    public static let furSubAsset = "material/fur"

    /// The key a derived fur mesh is registered under: `kind` ("shell", "cards" or "cards1", "cards2"…
    /// for card detail levels), the groom's geometry `tag` and the base mesh key.
    public static func meshKey(_ kind: String, tag: String, base: String) -> String { "groom:\(kind):\(tag)|\(base)" }
}

/// A small RGBA8 image carried inside a material (a groom's mask or flow map, downsampled), so
/// fur geometry can sample it on the CPU wherever it is built. Encoded as base64.
public struct GroomImage: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int
    /// RGBA rows, top to bottom.
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// `image` box-filtered down to at most `maxSide` texels on its longer side.
    public init(downsampling image: Image, maxSide: Int = 128) {
        let scale = max(1, Int((Float(max(image.width, image.height)) / Float(max(maxSide, 1))).rounded(.up)))
        let w = max(1, image.width / scale), h = max(1, image.height / scale)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                var sum = SIMD4<Int>(repeating: 0), n = 0
                for sy in (y * scale)..<min((y + 1) * scale, image.height) {
                    for sx in (x * scale)..<min((x + 1) * scale, image.width) {
                        let i = (sy * image.width + sx) * 4
                        sum &+= SIMD4(Int(image.pixels[i]), Int(image.pixels[i + 1]), Int(image.pixels[i + 2]), Int(image.pixels[i + 3]))
                        n += 1
                    }
                }
                let o = (y * w + x) * 4
                for c in 0..<4 { out[o + c] = UInt8(sum[c] / max(n, 1)) }
            }
        }
        self.init(width: w, height: h, pixels: out)
    }

    /// The color at `uv` (repeating, bilinear), 0...1 per channel.
    public func sample(_ uv: Vec2) -> Vec4 {
        guard width > 0, height > 0, pixels.count >= width * height * 4 else { return Vec4(1, 1, 1, 1) }
        let fx = (uv.x - uv.x.rounded(.down)) * Float(width) - 0.5
        let fy = (uv.y - uv.y.rounded(.down)) * Float(height) - 0.5
        let x0 = Int(fx.rounded(.down)), y0 = Int(fy.rounded(.down))
        let tx = fx - Float(x0), ty = fy - Float(y0)
        func texel(_ x: Int, _ y: Int) -> Vec4 {
            let xx = ((x % width) + width) % width, yy = ((y % height) + height) % height
            let i = (yy * width + xx) * 4
            return Vec4(Float(pixels[i]), Float(pixels[i + 1]), Float(pixels[i + 2]), Float(pixels[i + 3])) / 255
        }
        let a = texel(x0, y0) * (1 - tx) + texel(x0 + 1, y0) * tx
        let b = texel(x0, y0 + 1) * (1 - tx) + texel(x0 + 1, y0 + 1) * tx
        return a * (1 - ty) + b * ty
    }

    private enum CodingKeys: String, CodingKey { case width, height, pixels }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        width = try c.decode(Int.self, forKey: .width)
        height = try c.decode(Int.self, forKey: .height)
        pixels = Array(Data(base64Encoded: try c.decode(String.self, forKey: .pixels)) ?? Data())
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encode(Data(pixels).base64EncodedString(), forKey: .pixels)
    }
}

/// A material that draws fur (`Material.fur`, `MaterialAsset.fur`): the groom, plus its mask and
/// flow maps as small images. The material's base color texture slot holds nothing; the
/// metallic-roughness slot holds the full mask texture (its red channel cuts strands per pixel).
public struct MaterialFur: Codable, Equatable, Sendable {
    public var groom: GroomBuild
    /// The mask texture, downsampled: per-vertex length (GroomGeometry.swift).
    public var maskImage: GroomImage?
    /// The flow texture, downsampled: per-vertex comb direction.
    public var flowImage: GroomImage?
    /// A short hash of everything the fur geometry depends on (part of the derived mesh keys, so
    /// an edited groom builds new meshes).
    public private(set) var tag: String

    public init(groom: GroomBuild, maskImage: GroomImage? = nil, flowImage: GroomImage? = nil) {
        self.groom = groom
        self.maskImage = maskImage
        self.flowImage = flowImage
        tag = ""
        tag = Self.tag(of: self)
    }

    private enum CodingKeys: String, CodingKey { case groom, maskImage, flowImage }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(groom: try c.decodeIfPresent(GroomBuild.self, forKey: .groom) ?? GroomBuild(),
                  maskImage: try c.decodeIfPresent(GroomImage.self, forKey: .maskImage),
                  flowImage: try c.decodeIfPresent(GroomImage.self, forKey: .flowImage))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(groom, forKey: .groom)
        try c.encodeIfPresent(maskImage, forKey: .maskImage)
        try c.encodeIfPresent(flowImage, forKey: .flowImage)
    }

    /// FNV-1a of the geometry-relevant fields, as 16 hex digits.
    private static func tag(of fur: MaterialFur) -> String {
        var g = fur.groom
        // Shading-only fields don't change the meshes.
        g.rootColor = .zero; g.tipColor = .zero; g.colorNoise = 0; g.specular = 0; g.wind = 0; g.previewMesh = ""
        g.thickness = .zero; g.lod.distances = []
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ bytes: some Sequence<UInt8>) { for b in bytes { h = (h ^ UInt64(b)) &* 0x100_0000_01b3 } }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        mix((try? encoder.encode(g)) ?? Data())
        // Widths as Int64, so 32-bit (wasm32) builds compute the same tag.
        if let m = fur.maskImage { mix(m.pixels); mix(withUnsafeBytes(of: Int64(m.width).littleEndian) { Array($0) }) }
        if let f = fur.flowImage { mix(f.pixels); mix(withUnsafeBytes(of: Int64(f.width).littleEndian) { Array($0) }) }
        return String(h, radix: 16)
    }

    /// What `RenderPrep` needs to pick detail levels.
    public var traits: FurTraits {
        FurTraits(style: groom.drawnStyle, shellLevels: groom.shellLevels, cardLevels: groom.cardLevels,
                  distances: groom.lodDistances, length: groom.clampedLength, tag: tag)
    }
}

/// The CPU side of a fur material (`MaterialTraits.fur`): its detail levels and geometry tag.
public struct FurTraits: Equatable, Sendable {
    public var style: GroomStyle
    public var shellLevels: [Int]
    public var cardLevels: [Float]
    /// Meters from the camera where level 1, 2… start; past `distances[levels - 1]` (or the last
    /// entry) only the undercoat is drawn.
    public var distances: [Float]
    /// Strand length in meters (bounds grow by it).
    public var length: Float
    public var tag: String

    public init(style: GroomStyle, shellLevels: [Int], cardLevels: [Float], distances: [Float], length: Float, tag: String) {
        self.style = style
        self.shellLevels = shellLevels
        self.cardLevels = cardLevels
        self.distances = distances
        self.length = length
        self.tag = tag
    }

    /// The level count (shells or card fractions) for this style.
    public var levelCount: Int { style == .shell ? shellLevels.count : cardLevels.count }

    /// The detail level at `distance` meters: 0...levelCount - 1, or `levelCount` for undercoat only.
    public func level(distance: Float) -> Int {
        var level = 0
        for d in distances.prefix(levelCount) where distance >= d { level += 1 }
        return min(level, levelCount)
    }
}
