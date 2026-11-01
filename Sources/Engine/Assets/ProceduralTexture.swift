import Foundation

/// A texture described by a generator and its parameters, rendered on the CPU to an `Image`.
/// It is the contents of a `.proctex` file (JSON, every key optional; `ProceduralTextureImporter`
/// imports it as one `texture` sub-asset that materials reference like any texture) and can be
/// used straight from code: `ProceduralTexture.windowGrid(...)`, `.checker(...)`, `.gradient(...)`,
/// `.noise(...)`, `.bricks(...)`, `.stripes(...)`, or `texture.render()`.
///
/// Colors are display (sRGB) values 0...1; the default import is sRGB, so they come out unchanged.
/// Output is deterministic (integer hashing from `seed`), identical on every machine, and tiles
/// seamlessly (noise wraps at its period). Generators and the fields they read (all take `width`,
/// `height`, `seed` where random):
///
/// - `windowGrid`: `columns` x `rows` cells, each a window inset by `margin` (fraction of the cell,
///   0...0.5) inside a `colorA` frame; `fraction` of the windows are lit (`colorB`, varied by up
///   to `variation` per channel), the rest are dark glass (`colorC`). Use as an emissive texture
///   on a facade (frame and unlit glass nearly black).
/// - `checker`: `columns` x `rows` tiles alternating `colorA` / `colorB`.
/// - `gradient`: `colorA` to `colorB` along `angle` degrees (0: left to right, 90: top to bottom).
/// - `noise`: fractal value noise of `scale` base cells and `octaves` octaves, mapped `colorA` to `colorB`.
/// - `bricks`: `rows` rows of `columns` bricks (odd rows shifted half a brick), `colorA` bricks
///   darkened by up to `variation`, `colorB` mortar of `margin` cell fraction.
/// - `stripes`: `columns` stripes along `angle` degrees (0: vertical), `fraction` of each `colorA`, the rest `colorB`.
public struct ProceduralTexture: Codable, Equatable, Sendable {
    public enum Generator: String, Codable, CaseIterable, Sendable {
        case windowGrid, checker, gradient, noise, bricks, stripes
    }

    public static let maxSize = 4096

    public var generator: Generator
    public var width: Int
    public var height: Int
    public var seed: Int
    public var colorA: Vec3
    public var colorB: Vec3
    public var colorC: Vec3
    public var columns: Int
    public var rows: Int
    public var margin: Float
    public var fraction: Float
    public var variation: Float
    public var scale: Int
    public var octaves: Int
    public var angle: Float

    public static var fieldHints: [String: FieldHints] {
        ["width": FieldHints(range: 1...Double(maxSize), step: 1), "height": FieldHints(range: 1...Double(maxSize), step: 1),
         "colorA": FieldHints(color: true, tooltip: "windowGrid: frame. checker/gradient/noise: first color. bricks: brick. stripes: stripe"),
         "colorB": FieldHints(color: true, tooltip: "windowGrid: lit window. bricks: mortar. Otherwise the second color"),
         "colorC": FieldHints(color: true, tooltip: "windowGrid: unlit glass"),
         "columns": FieldHints(range: 1...512, step: 1), "rows": FieldHints(range: 1...512, step: 1),
         "margin": FieldHints(range: 0...0.5, step: 0.01, tooltip: "windowGrid: frame width, bricks: mortar width (fraction of a cell)"),
         "fraction": FieldHints(range: 0...1, step: 0.01, tooltip: "windowGrid: lit fraction. stripes: width of colorA"),
         "variation": FieldHints(range: 0...1, step: 0.01, tooltip: "Random color variation per window / brick"),
         "scale": FieldHints(range: 1...256, step: 1, tooltip: "noise: base cells across the texture"),
         "octaves": FieldHints(range: 1...8, step: 1), "angle": FieldHints(range: -180...180, step: 1, tooltip: "Degrees")]
    }

    public init(generator: Generator = .windowGrid, width: Int = 256, height: Int = 256, seed: Int = 1,
                colorA: Vec3 = Vec3(0.03, 0.03, 0.04), colorB: Vec3 = Vec3(1, 0.82, 0.45), colorC: Vec3 = Vec3(0.02, 0.03, 0.05),
                columns: Int = 8, rows: Int = 8, margin: Float = 0.2, fraction: Float = 0.5, variation: Float = 0.25,
                scale: Int = 4, octaves: Int = 4, angle: Float = 0) {
        self.generator = generator
        self.width = width
        self.height = height
        self.seed = seed
        self.colorA = colorA
        self.colorB = colorB
        self.colorC = colorC
        self.columns = columns
        self.rows = rows
        self.margin = margin
        self.fraction = fraction
        self.variation = variation
        self.scale = scale
        self.octaves = octaves
        self.angle = angle
    }

    /// Every key is optional.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ProceduralTexture()
        self.init(generator: try c.decodeIfPresent(Generator.self, forKey: .generator) ?? d.generator,
                  width: try c.decodeIfPresent(Int.self, forKey: .width) ?? d.width,
                  height: try c.decodeIfPresent(Int.self, forKey: .height) ?? d.height,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  colorA: try c.decodeIfPresent(Vec3.self, forKey: .colorA) ?? d.colorA,
                  colorB: try c.decodeIfPresent(Vec3.self, forKey: .colorB) ?? d.colorB,
                  colorC: try c.decodeIfPresent(Vec3.self, forKey: .colorC) ?? d.colorC,
                  columns: try c.decodeIfPresent(Int.self, forKey: .columns) ?? d.columns,
                  rows: try c.decodeIfPresent(Int.self, forKey: .rows) ?? d.rows,
                  margin: try c.decodeIfPresent(Float.self, forKey: .margin) ?? d.margin,
                  fraction: try c.decodeIfPresent(Float.self, forKey: .fraction) ?? d.fraction,
                  variation: try c.decodeIfPresent(Float.self, forKey: .variation) ?? d.variation,
                  scale: try c.decodeIfPresent(Int.self, forKey: .scale) ?? d.scale,
                  octaves: try c.decodeIfPresent(Int.self, forKey: .octaves) ?? d.octaves,
                  angle: try c.decodeIfPresent(Float.self, forKey: .angle) ?? d.angle)
    }

    /// A sensible starting point for `generator` (colors and counts that look like what it is named for).
    public static func preset(_ generator: Generator) -> ProceduralTexture {
        var t = ProceduralTexture(generator: generator)
        switch generator {
        case .windowGrid:
            break
        case .checker:
            t.colorA = Vec3(0.85, 0.85, 0.85); t.colorB = Vec3(0.15, 0.15, 0.15)
        case .gradient:
            t.colorA = Vec3(0.05, 0.1, 0.4); t.colorB = Vec3(0.95, 0.6, 0.3); t.angle = 90
        case .noise:
            t.colorA = Vec3(0.1, 0.1, 0.1); t.colorB = Vec3(0.9, 0.9, 0.9)
        case .bricks:
            t.colorA = Vec3(0.6, 0.25, 0.18); t.colorB = Vec3(0.7, 0.7, 0.68); t.rows = 12; t.columns = 6; t.margin = 0.06
        case .stripes:
            t.colorA = Vec3(0.9, 0.8, 0.1); t.colorB = Vec3(0.1, 0.1, 0.1); t.columns = 8; t.angle = 45
        }
        return t
    }

    /// Renders the texture (sizes clamp to 1...`maxSize`).
    public func render() -> Image {
        let w = min(max(width, 1), Self.maxSize), h = min(max(height, 1), Self.maxSize)
        let columns = max(columns, 1), rows = max(rows, 1)
        let colorA = colorA, colorB = colorB, colorC = colorC
        let seed = seed, margin = margin, fraction = fraction, variation = variation
        let sample: (Float, Float) -> Vec3
        var samples = 2
        switch generator {
        case .windowGrid:
            sample = { u, v in
                let fu = u * Float(columns), fv = v * Float(rows)
                let cx = Int(fu.rounded(.down)), cy = Int(fv.rounded(.down))
                let lu = fu - Float(cx), lv = fv - Float(cy)
                let m = min(max(margin, 0), 0.5)
                guard lu >= m, lu <= 1 - m, lv >= m, lv <= 1 - m else { return colorA }
                let wx = ((cx % columns) + columns) % columns, wy = ((cy % rows) + rows) % rows
                let lit = Hash32.unit(seed, wx, wy, 0) < fraction
                return Self.varied(lit ? colorB : colorC, variation, seed, wx, wy)
            }
        case .checker:
            sample = { u, v in
                let cx = Int((u * Float(columns)).rounded(.down)), cy = Int((v * Float(rows)).rounded(.down))
                return (cx + cy) & 1 == 0 ? colorA : colorB
            }
        case .gradient:
            samples = 1
            let a = angle * .pi / 180, dx = cosf(a), dy = sinf(a)
            sample = { u, v in
                let t = min(max((u - 0.5) * dx + (v - 0.5) * dy + 0.5, 0), 1)
                return colorA + (colorB - colorA) * t
            }
        case .noise:
            samples = 1
            let period = min(max(scale, 1), 256), octaves = min(max(octaves, 1), 8)
            sample = { u, v in
                var sum: Float = 0, amplitude: Float = 1, total: Float = 0
                var p = period
                for o in 0..<octaves {
                    sum += amplitude * Self.valueNoise(u * Float(p), v * Float(p), period: p, seed: seed &+ o)
                    total += amplitude
                    amplitude *= 0.5
                    p *= 2
                }
                return colorA + (colorB - colorA) * (sum / total)
            }
        case .bricks:
            sample = { u, v in
                let fv = v * Float(rows)
                let row = Int(fv.rounded(.down))
                let fu = u * Float(columns) + (row & 1 == 1 ? 0.5 : 0)
                let col = Int(fu.rounded(.down))
                let lu = fu - Float(col), lv = fv - Float(row)
                let m = min(max(margin, 0), 0.5) / 2
                guard lu >= m, lu <= 1 - m, lv >= m, lv <= 1 - m else { return colorB }
                let r = ((row % rows) + rows) % rows, c = ((col % columns) + columns) % columns
                return Self.varied(colorA, variation, seed, c, r)
            }
        case .stripes:
            let a = angle * .pi / 180, dx = cosf(a), dy = sinf(a)
            sample = { u, v in
                let t = (u * dx + v * dy) * Float(columns)
                return t - t.rounded(.down) < fraction ? colorA : colorB
            }
        }
        var pixels = [UInt8](repeating: 255, count: w * h * 4)
        let n = Float(samples * samples)
        for y in 0..<h {
            for x in 0..<w {
                var sum = Vec3.zero
                for sy in 0..<samples {
                    for sx in 0..<samples {
                        sum += sample((Float(x) + (Float(sx) + 0.5) / Float(samples)) / Float(w),
                                      (Float(y) + (Float(sy) + 0.5) / Float(samples)) / Float(h))
                    }
                }
                let c = sum / n
                let i = (y * w + x) * 4
                pixels[i] = Self.byte(c.x)
                pixels[i + 1] = Self.byte(c.y)
                pixels[i + 2] = Self.byte(c.z)
            }
        }
        return Image(width: w, height: h, pixels: pixels)
    }

    private static func byte(_ v: Float) -> UInt8 { UInt8(min(max(v, 0), 1) * 255 + 0.5) }

    /// `color` darkened per channel by up to `amount`, from the cell's hash.
    private static func varied(_ color: Vec3, _ amount: Float, _ seed: Int, _ x: Int, _ y: Int) -> Vec3 {
        guard amount > 0 else { return color }
        return color * Vec3(1 - amount * Hash32.unit(seed, x, y, 1), 1 - amount * Hash32.unit(seed, x, y, 2),
                            1 - amount * Hash32.unit(seed, x, y, 3))
    }

    /// Smooth value noise in 0...1 on a lattice that wraps every `period` cells.
    private static func valueNoise(_ x: Float, _ y: Float, period: Int, seed: Int) -> Float {
        let x0 = Int(x.rounded(.down)), y0 = Int(y.rounded(.down))
        let fx = x - Float(x0), fy = y - Float(y0)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        func lattice(_ i: Int, _ j: Int) -> Float {
            Hash32.unit(seed, ((i % period) + period) % period, ((j % period) + period) % period, 7)
        }
        let top = lattice(x0, y0) + (lattice(x0 + 1, y0) - lattice(x0, y0)) * sx
        let bottom = lattice(x0, y0 + 1) + (lattice(x0 + 1, y0 + 1) - lattice(x0, y0 + 1)) * sx
        return top + (bottom - top) * sy
    }

    // MARK: Plain Swift API

    /// A facade: `columns` x `rows` windows, `litFraction` of them lit.
    public static func windowGrid(width: Int = 256, height: Int = 256, columns: Int = 8, rows: Int = 8, margin: Float = 0.2,
                                  litFraction: Float = 0.5, seed: Int = 1, variation: Float = 0.25,
                                  frame: Vec3 = Vec3(0.03, 0.03, 0.04), lit: Vec3 = Vec3(1, 0.82, 0.45),
                                  unlit: Vec3 = Vec3(0.02, 0.03, 0.05)) -> Image {
        ProceduralTexture(generator: .windowGrid, width: width, height: height, seed: seed, colorA: frame, colorB: lit, colorC: unlit,
                          columns: columns, rows: rows, margin: margin, fraction: litFraction, variation: variation).render()
    }

    public static func checker(width: Int = 256, height: Int = 256, columns: Int = 8, rows: Int = 8,
                               a: Vec3 = Vec3(0.85, 0.85, 0.85), b: Vec3 = Vec3(0.15, 0.15, 0.15)) -> Image {
        ProceduralTexture(generator: .checker, width: width, height: height, colorA: a, colorB: b, columns: columns, rows: rows).render()
    }

    public static func gradient(width: Int = 256, height: Int = 256, from a: Vec3, to b: Vec3, angle: Float = 90) -> Image {
        ProceduralTexture(generator: .gradient, width: width, height: height, colorA: a, colorB: b, angle: angle).render()
    }

    public static func noise(width: Int = 256, height: Int = 256, scale: Int = 4, octaves: Int = 4, seed: Int = 1,
                             a: Vec3 = Vec3(0.1, 0.1, 0.1), b: Vec3 = Vec3(0.9, 0.9, 0.9)) -> Image {
        ProceduralTexture(generator: .noise, width: width, height: height, seed: seed, colorA: a, colorB: b,
                          scale: scale, octaves: octaves).render()
    }

    public static func bricks(width: Int = 256, height: Int = 256, columns: Int = 6, rows: Int = 12, mortar: Float = 0.06,
                              seed: Int = 1, variation: Float = 0.25, brick: Vec3 = Vec3(0.6, 0.25, 0.18),
                              mortarColor: Vec3 = Vec3(0.7, 0.7, 0.68)) -> Image {
        ProceduralTexture(generator: .bricks, width: width, height: height, seed: seed, colorA: brick, colorB: mortarColor,
                          columns: columns, rows: rows, margin: mortar, variation: variation).render()
    }

    public static func stripes(width: Int = 256, height: Int = 256, count: Int = 8, angle: Float = 45, fraction: Float = 0.5,
                               a: Vec3 = Vec3(0.9, 0.8, 0.1), b: Vec3 = Vec3(0.1, 0.1, 0.1)) -> Image {
        ProceduralTexture(generator: .stripes, width: width, height: height, colorA: a, colorB: b, columns: count,
                          fraction: fraction, angle: angle).render()
    }

    /// The `.proctex` file contents (sorted keys, like sidecars).
    public func fileData() throws -> Data { try AssetJSON.encode(self) }
}

/// Imports `.proctex` files (a `ProceduralTexture` as JSON, every key optional) as one `texture`
/// sub-asset, rendered at import time; editing the file (or the project's Procedural Texture
/// inspector) reimports it. `sRGB` and `mipmaps` as for `TextureImporter`.
public struct ProceduralTextureImporter: AssetImporter {
    public struct Settings: Codable, Equatable, Sendable {
        public var sRGB: Bool = true
        public var mipmaps: Bool = true

        public init(sRGB: Bool = true, mipmaps: Bool = true) {
            self.sRGB = sRGB
            self.mipmaps = mipmaps
        }

        private enum CodingKeys: String, CodingKey { case sRGB, mipmaps }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            sRGB = try c.decodeIfPresent(Bool.self, forKey: .sRGB) ?? true
            mipmaps = try c.decodeIfPresent(Bool.self, forKey: .mipmaps) ?? true
        }
    }

    public init() {}

    public var name: String { "proctex" }
    public var fileExtensions: [String] { ["proctex"] }
    public var version: Int { 1 }
    public var defaultSettings: Settings { Settings() }

    public func importAsset(_ context: inout ImportContext, settings: Settings) throws -> ImportedAsset {
        let spec: ProceduralTexture
        do { spec = try AssetJSON.decoder().decode(ProceduralTexture.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a procedural texture: \(error)")
        }
        var asset = ImportedAsset()
        asset.add("texture", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .texture(TextureAsset(image: spec.render(), isSRGB: settings.sRGB, generatesMipmaps: settings.mipmaps)))
        return asset
    }
}
