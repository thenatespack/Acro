import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// The `.proctex` noise generators (fbm, ridged, voronoi, cells, woodRings, streaks) and the
// height-to-normal-map output, on the tileable noise of TileNoise.swift (shared with the mesh
// build looks). See the notes on `ProceduralTexture`.

extension ProceduralTexture {
    /// Whether `generator` is one of the noise kinds (a value 0...1 per pixel).
    var isNoiseGenerator: Bool {
        switch generator {
        case .fbm, .ridged, .voronoi, .cells, .woodRings, .streaks: true
        default: false
        }
    }

    /// A starting point for the noise kinds.
    mutating func applyNoisePreset() {
        switch generator {
        case .fbm:
            colorA = Vec3(0.2, 0.2, 0.2); colorB = Vec3(0.85, 0.85, 0.85); scale = 4; octaves = 5
        case .ridged:
            colorA = Vec3(0.15, 0.14, 0.13); colorB = Vec3(0.8, 0.78, 0.74); scale = 3; octaves = 5
        case .voronoi:
            colorA = Vec3(0.95, 0.95, 0.95); colorB = Vec3(0.1, 0.1, 0.12); scale = 8
        case .cells:
            colorA = Vec3(0.42, 0.41, 0.4); colorB = Vec3(0.62, 0.58, 0.52); colorC = Vec3(0.15, 0.13, 0.11); scale = 6
            margin = 0.08
        case .woodRings:
            colorA = Vec3(0.78, 0.6, 0.4); colorB = Vec3(0.5, 0.32, 0.18); rows = 16; scale = 2; variation = 1
        case .streaks:
            colorA = Vec3(0.45, 0.45, 0.47); colorB = Vec3(0.8, 0.8, 0.82); columns = 120; angle = 0
        default:
            break
        }
        normalStrength = 1
    }

    /// The noise kinds' value 0...1 at (u, v) (nil for the other generators).
    func noiseValueSampler() -> (@Sendable (Float, Float) -> Float)? {
        let period = min(max(scale, 1), 256), octaves = min(max(octaves, 1), 8), seed = seed
        switch generator {
        case .fbm:
            return { u, v in min(max(TileNoise.fbm(u, v, period, period, octaves: octaves, seed: seed) * 0.6 + 0.5, 0), 1) }
        case .ridged:
            return { u, v in TileNoise.ridged(u, v, period, period, octaves: octaves, seed: seed) }
        case .voronoi:
            return { u, v in min(TileNoise.cells(u, v, period, period, seed: seed).f1 / 0.75, 1) }
        case .cells:
            let border = min(max(margin, 0), 0.5)
            return { u, v in
                let c = TileNoise.cells(u, v, period, period, seed: seed)
                guard border > 0 else { return 1 }
                return TileNoise.smoothstep(border * 0.5, border, c.f2 - c.f1)
            }
        case .woodRings:
            let lines = Float(max(rows, 1)), warp = variation
            return { u, v in
                let bend = TileNoise.fbm(u, v, max(period / 2, 1), period, octaves: 3, seed: seed) * warp * 2
                let r = TileNoise.fract(v * lines + bend)
                return TileNoise.smoothstep(0.55, 0.88, r) * (1 - TileNoise.smoothstep(0.9, 1.0, r))
            }
        case .streaks:
            let across = min(max(columns, 1), 2048), thin = min(max(fraction, 0), 1)
            // 0, 45, 90 or 135 degrees: whole-tile shears keep the noise tileable.
            let step = Int(((angle.truncatingRemainder(dividingBy: 180) + 180).truncatingRemainder(dividingBy: 180) / 45).rounded()) % 4
            return { u, v in
                let (a, b): (Float, Float) = switch step {
                case 1: (u + v, v)       // along the diagonal
                case 2: (v, u)           // vertical
                case 3: (u - v, v)
                default: (u, v)          // horizontal
                }
                let n = TileNoise.fbm(a, b, 2, across, octaves: 3, seed: seed)
                guard thin > 0 else { return min(max(n * 0.7 + 0.5, 0), 1) }
                // Scratches: thin lines where the noise crosses zero, masked down to `fraction`.
                let line = 1 - TileNoise.smoothstep(0, 0.06, abs(n))
                let mask = TileNoise.perlin(u, v, 4, 4, seed: seed &+ 9) * 0.5 + 0.5 < thin ? Float(1) : 0
                return line * mask
            }
        default:
            return nil
        }
    }

    /// The color sampler of a noise kind (`cells`: a shade per cell with `colorC` borders).
    func noiseColorSampler() -> @Sendable (Float, Float) -> Vec3 {
        let colorA = colorA, colorB = colorB, colorC = colorC
        if generator == .cells {
            let period = min(max(scale, 1), 256), seed = seed, border = min(max(margin, 0), 0.5)
            return { u, v in
                let c = TileNoise.cells(u, v, period, period, seed: seed)
                let shade = Float(c.id & 0xFFFF) / 65_535
                let fill = colorA + (colorB - colorA) * shade
                guard border > 0 else { return fill }
                let t = TileNoise.smoothstep(border * 0.5, border, c.f2 - c.f1)
                return colorC + (fill - colorC) * t
            }
        }
        let value = noiseValueSampler() ?? { _, _ in 0 }
        return { u, v in colorA + (colorB - colorA) * value(u, v) }
    }

    /// The texture's height, 0...1 per pixel (see the notes on `ProceduralTexture`).
    func renderHeight() -> [Float] {
        let w = min(max(width, 1), Self.maxSize), h = min(max(height, 1), Self.maxSize)
        let height: @Sendable (Float, Float) -> Float
        if let value = noiseValueSampler() {
            height = value
        } else if generator == .bricks {
            let rows = max(rows, 1), columns = max(columns, 1), margin = min(max(margin, 0), 0.5) / 2
            height = { u, v in
                let fv = v * Float(rows)
                let row = fv.rounded(.down)
                let fu = u * Float(columns) + (Int(row) & 1 == 1 ? 0.5 : 0)
                let lu = fu - fu.rounded(.down), lv = fv - row
                // Distance into the brick from the mortar, eased so the edges bevel.
                let d = min(lu - margin, 1 - margin - lu, (lv - margin) * Float(columns) / Float(rows),
                            (1 - margin - lv) * Float(columns) / Float(rows))
                return TileNoise.smoothstep(0, 0.06, d)
            }
        } else {
            var flat = self
            flat.width = w
            flat.height = h
            let image = flat.render()
            return (0..<(w * h)).map { i in
                (0.2126 * Float(image.pixels[i * 4]) + 0.7152 * Float(image.pixels[i * 4 + 1]) + 0.0722 * Float(image.pixels[i * 4 + 2])) / 255
            }
        }
        return TileNoise.parallelRows(h, w, initial: Float(0)) { y, row in
            let v = (Float(y) + 0.5) / Float(h)
            for x in 0..<w { row[x] = height((Float(x) + 0.5) / Float(w), v) }
        }
    }

    /// A linear tangent-space normal map of `renderHeight()`, `normalStrength` steep (the
    /// importer's `normal` texture).
    public func renderNormalMap() -> Image {
        let w = min(max(width, 1), Self.maxSize), h = min(max(height, 1), Self.maxSize)
        let strength = max(normalStrength, 0) * 0.05
        return Image(width: w, height: h, pixels: TileNoise.normalMap(height: renderHeight(), width: w, height: h, strength: strength))
    }
}
