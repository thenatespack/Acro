import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// Leaf looks: generated textures for foliage cards and leafy ribbons (`look` on a `foliage` part,
// or on an open `sweep`). Unlike the tiling looks (MeshBuildLooks.swift) a leaf look is a picture
// with alpha: four variants of a sprig (a cluster of leaves on a stem, a fern frond, a tuft of
// grass…) in the quadrants of one texture, each with its stem's base at the bottom middle of its
// quadrant and drawn in slightly different shades, so cards picking different quadrants vary.
//
// - albedo (sRGB, alpha = coverage): the leaves' own colors (not normalized like the tiling looks,
//   so flowers keep white petals on green leaves); transparent texels carry the nearest leaf color
//   (push-pull fill), so filtering and mipmaps don't darken the edges.
// - normal (linear): each leaf's dome, midrib and veins.
// - ORM (linear): occlusion (leaves under others darker), roughness, metalness 0.
//
// The material is alpha-cutout (`AlphaMode.mask`, `alphaCutoff`) and double-sided, so cards cut
// out their leaves in the lit pass, the depth prepass and the shadow maps alike. `color` tints a
// leaf look to that average color (the material's base color is the color over the look's own
// average), leave it out for the look's natural colors.

/// A leaf texture for foliage cards and ribbons (`MeshBuildPart.look`; see the notes at the top of this file).
public enum MeshBuildLeafLook: String, Codable, CaseIterable, Sendable {
    /// Oval leaves alternating along a twig (most deciduous trees and shrubs).
    case broadleaf
    /// Lobed oak leaves.
    case oakLeaves
    /// Five-pointed maple leaves.
    case mapleLeaves
    /// A conifer twig with needles (pine, spruce, fir).
    case pineNeedles
    /// A fern frond: leaflets along a curving stem.
    case fern
    /// A tuft of grass blades.
    case grassBlades
    /// Small five-petaled flowers on leafy stems.
    case flowers
    /// Glossy three-lobed ivy leaves on a vine.
    case ivy

    public var title: String {
        switch self {
        case .broadleaf: "Broadleaf"
        case .oakLeaves: "Oak leaves"
        case .mapleLeaves: "Maple leaves"
        case .pineNeedles: "Pine needles"
        case .fern: "Fern"
        case .grassBlades: "Grass blades"
        case .flowers: "Flowers"
        case .ivy: "Ivy"
        }
    }

    /// A card's side in meters by default (`MeshBuildPart.cardSize`).
    public var defaultCardSize: Float {
        switch self {
        case .broadleaf: 0.45
        case .oakLeaves: 0.5
        case .mapleLeaves: 0.55
        case .pineNeedles: 0.45
        case .fern: 0.6
        case .grassBlades: 0.35
        case .flowers: 0.35
        case .ivy: 0.35
        }
    }

    /// Plants that grow up from the ground: a foliage volume of them stands crossed cards (tufts)
    /// upright on its floor instead of covering its surface.
    public var isUpright: Bool { self == .grassBlades || self == .flowers || self == .fern }

    /// Texels whose alpha is below this are cut out. A little under half, so the thin parts of
    /// distant (mipmapped) cards don't thin away.
    public var alphaCutoff: Float { self == .pineNeedles || self == .grassBlades ? 0.35 : 0.42 }

    /// The look's surface roughness (its ORM green, about).
    var roughness: Float {
        switch self {
        case .ivy: 0.6
        case .pineNeedles: 0.8
        case .grassBlades: 0.85
        default: 0.8
        }
    }

    /// The look named `name`, ignoring case, spaces, dashes and underscores, plus a few aliases
    /// (leaves, oak, maple, pine, needles, conifer, spruce, fir, frond, tall grass, wildflowers, vine).
    public static func named(_ name: String) -> MeshBuildLeafLook? {
        let key = name.lowercased().filter { $0.isLetter }
        if let look = allCases.first(where: { $0.rawValue.lowercased() == key }) { return look }
        switch key {
        case "leaves", "leaf", "leafy", "broadleaves", "foliage": return .broadleaf
        case "oak", "oakleaf": return .oakLeaves
        case "maple", "mapleleaf": return .mapleLeaves
        case "pine", "needles", "pineneedle", "conifer", "spruce", "fir", "evergreen": return .pineNeedles
        case "ferns", "frond", "fernfrond", "fronds": return .fern
        case "grassblade", "blades", "tallgrass", "grasstuft", "grasstufts": return .grassBlades
        case "flower", "wildflowers", "wildflower", "blossoms": return .flowers
        case "vine", "vines", "ivyleaves": return .ivy
        default: return nil
        }
    }

    public static var nameList: String { allCases.map(\.rawValue).joined(separator: ", ") }
}

/// A leaf look's generated textures (see the notes at the top of this file).
public struct MeshBuildLeafTextures: Sendable {
    public var look: MeshBuildLeafLook
    public var resolution: Int
    /// sRGB color, alpha = coverage.
    public var albedo: Image
    /// Linear tangent-space normal map.
    public var normal: Image
    /// Linear: occlusion R, roughness G, metalness B (0).
    public var orm: Image
    /// The leaves' average color (linear, over the covered texels).
    public var averageColor: Vec3
    /// How much of the texture the leaves cover (0...1).
    public var coverage: Float

    /// Pixels per side of the whole texture (four variants of half that).
    public static let defaultResolution = 512
    /// Variants per side: the texture is a `variantGrid` x `variantGrid` grid of sprigs.
    public static let variantGrid = 2

    /// The UV rectangle (origin, size) of variant `index` (0..<4).
    public static func variantRect(_ index: Int) -> (origin: Vec2, size: Vec2) {
        let g = variantGrid, k = ((index % (g * g)) + g * g) % (g * g)
        let size = 1 / Float(g)
        return (Vec2(Float(k % g) * size, Float(k / g) * size), Vec2(size, size))
    }

    // MARK: Cache

    private struct Key: Hashable {
        var look: MeshBuildLeafLook
        var resolution: Int
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [Key: MeshBuildLeafTextures] = [:]
    nonisolated(unsafe) private static var generating: [Key: NSCondition] = [:]

    /// The textures of `look`: cached per process, generated once even when several imports ask at once.
    public static func textures(_ look: MeshBuildLeafLook, resolution: Int = defaultResolution) -> MeshBuildLeafTextures {
        let key = Key(look: look, resolution: min(max(resolution, 32), 2048))
        while true {
            lock.lock()
            if let hit = cache[key] {
                lock.unlock()
                return hit
            }
            if let pending = generating[key] {
                pending.lock()
                lock.unlock()
                pending.wait()
                pending.unlock()
                continue
            }
            let condition = NSCondition()
            generating[key] = condition
            lock.unlock()
            let made = MeshBuildLeafPainter.paint(key.look, resolution: key.resolution)
            lock.lock()
            cache[key] = made
            generating[key] = nil
            lock.unlock()
            condition.lock()
            condition.broadcast()
            condition.unlock()
            return made
        }
    }
}

// MARK: - Painting

/// Draws the leaf looks: each variant is a list of shapes (stems, leaves, petals) painted back to
/// front into its quadrant with antialiased edges.
enum MeshBuildLeafPainter {
    typealias RGB = (Float, Float, Float)

    /// One variant's canvas: linear color, coverage, height (for the normal map) and occlusion.
    struct Canvas {
        let size: Int
        var r: [Float], g: [Float], b: [Float], a: [Float], h: [Float], ao: [Float]

        init(size: Int) {
            self.size = size
            let n = size * size
            r = [Float](repeating: 0, count: n); g = r; b = r; a = r
            h = [Float](repeating: 0.5, count: n)
            ao = [Float](repeating: 1, count: n)
        }

        /// Paints coverage `alpha` of a texel with a color, height and occlusion ("over").
        @inline(__always) mutating func put(_ i: Int, _ alpha: Float, _ c: RGB, height: Float, occlusion: Float) {
            guard alpha > 0 else { return }
            // Straight (not premultiplied) values: the new one over what is there.
            let k = min(alpha, 1)
            let below = a[i] * (1 - k), total = k + below
            let wNew = k / total, wOld = below / total
            r[i] = c.0 * wNew + r[i] * wOld
            g[i] = c.1 * wNew + g[i] * wOld
            b[i] = c.2 * wNew + b[i] * wOld
            h[i] = height * wNew + h[i] * wOld
            ao[i] = occlusion * wNew + ao[i] * wOld
            a[i] = total
        }
    }

    /// A leaf's outline: its half width (fraction of the leaf's width) at `s` (0 at the stem, 1 at the tip).
    enum Outline {
        case oval, lance, oak, blade, needle, pinna

        func halfWidth(_ s: Float) -> Float {
            guard s >= 0, s <= 1 else { return 0 }
            switch self {
            case .oval:
                // Round-based, pointed tip.
                return powf(sinf(.pi * powf(s, 0.8)), 0.75) * (1 - 0.1 * s)
            case .lance:
                return powf(sinf(.pi * powf(s, 0.65)), 0.9)
            case .oak:
                // Rounded lobes, narrow at the base, widest past the middle.
                let body = powf(sinf(.pi * powf(s, 0.7)), 0.8)
                let lobes = 0.55 + 0.45 * powf(abs(cosf(.pi * 3.5 * s)), 0.6)
                return body * (s < 0.12 ? 0.45 + 4.5 * s : lobes)
            case .blade:
                return powf(max(1 - s, 0), 0.7) * (s < 0.03 ? 0.7 + 10 * s : 1)
            case .needle:
                return s < 0.92 ? 1 : max((1 - s) / 0.08, 0)
            case .pinna:
                // A fern leaflet: a lance with small rounded lobes.
                let body = powf(sinf(.pi * powf(s, 0.7)), 0.85)
                return body * (0.8 + 0.2 * abs(cosf(.pi * 6 * s)))
            }
        }
    }

    /// A star-like outline around a center (`r` of the radius at angle `phi` from the leaf's axis).
    enum Polar {
        case maple, ivy, petal

        func radius(_ phi: Float) -> Float {
            // phi: radians from the leaf's axis (the stem direction is ±π).
            switch self {
            case .maple:
                // Five pointed lobes (center, two sides, two low) with a notch at the stem, serrated.
                let lobes: [(Float, Float)] = [(0, 1), (1.1, 0.9), (-1.1, 0.9), (2.15, 0.55), (-2.15, 0.55)]
                var best: Float = 0.3
                for (angle, length) in lobes {
                    let d = abs(remainderf(phi - angle, 2 * .pi))
                    best = max(best, length * max(1 - powf(d / 0.78, 1.4), 0))
                }
                return best * (1 - 0.07 * abs(sinf(phi * 20))) + 0.1
            case .ivy:
                // Five pointed lobes (a long middle one) and a heart-shaped base.
                let lobes: [(Float, Float)] = [(0, 1), (1.3, 0.72), (-1.3, 0.72), (2.35, 0.5), (-2.35, 0.5)]
                var best: Float = 0.42
                for (angle, length) in lobes {
                    let d = abs(remainderf(phi - angle, 2 * .pi))
                    best = max(best, length * max(1 - powf(d / 0.95, 1.3), 0))
                }
                let d0 = abs(remainderf(phi, 2 * .pi))
                return best * (d0 > 2.85 ? max(1 - (d0 - 2.85) * 2.2, 0.35) : 1)
            case .petal:
                // Five round petals.
                return 0.45 + 0.55 * powf(abs(cosf(2.5 * phi)), 0.7)
            }
        }
    }

    /// Seeded random numbers (SplitMix64).
    struct Random {
        var state: UInt64
        init(_ seed: Int) { state = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15 &+ 0x1234_5678 }
        mutating func next() -> Float {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z ^= z >> 31
            return Float(z >> 40) / Float(1 << 24)
        }
        mutating func range(_ lo: Float, _ hi: Float) -> Float { lo + (hi - lo) * next() }
    }

    // MARK: Primitives

    /// A stem along `points` (canvas pixels), `w0` wide at its start to `w1` at its end.
    static func stem(_ c: inout Canvas, _ points: [Vec2], _ w0: Float, _ w1: Float, _ color: RGB, layer: Float) {
        guard points.count >= 2 else { return }
        var total: Float = 0
        var lengths: [Float] = [0]
        for i in 1..<points.count { total += length(points[i] - points[i - 1]); lengths.append(total) }
        for i in 1..<points.count {
            let p = points[i - 1], q = points[i]
            let wa = w0 + (w1 - w0) * lengths[i - 1] / max(total, 1e-4), wb = w0 + (w1 - w0) * lengths[i] / max(total, 1e-4)
            let half = max(wa, wb) / 2 + 1.5
            let lo = pointwiseMin(p, q) - Vec2(half, half), hi = pointwiseMax(p, q) + Vec2(half, half)
            let d = q - p, len2 = max(dot(d, d), 1e-6)
            for y in max(Int(lo.y), 0)...min(Int(hi.y), c.size - 1) {
                for x in max(Int(lo.x), 0)...min(Int(hi.x), c.size - 1) {
                    let pt = Vec2(Float(x) + 0.5, Float(y) + 0.5)
                    let t = min(max(dot(pt - p, d) / len2, 0), 1)
                    let dist = length(pt - (p + d * t))
                    let w = (wa + (wb - wa) * t) / 2
                    let cover = min(max(w - dist + 0.5, 0), 1)
                    guard cover > 0 else { continue }
                    let across = min(dist / max(w, 0.5), 1)
                    let shade = 1.1 - 0.35 * across * across
                    c.put(y * c.size + x, cover, (color.0 * shade, color.1 * shade, color.2 * shade),
                          height: 0.62 + 0.12 * (1 - across * across), occlusion: 0.8 + 0.2 * layer)
                }
            }
        }
    }

    /// A leaf from `base` pointing at `angle` (radians, 0 = up the canvas), `length` x `width` pixels.
    static func leaf(_ c: inout Canvas, base: Vec2, angle: Float, length L: Float, width W: Float, outline: Outline,
                     color: RGB, veins: Float = 7, bend: Float = 0, layer: Float) {
        let dir = Vec2(sinf(angle), -cosf(angle)), side = Vec2(-dir.y, dir.x)
        let reach = L + W
        let lo = base - Vec2(reach, reach), hi = base + Vec2(reach, reach)
        let halfMax = W / 2
        let vein = (min(color.0 * 1.35 + 0.02, 1), min(color.1 * 1.25 + 0.02, 1), min(color.2 * 1.1, 1))
        for y in max(Int(lo.y), 0)...min(Int(hi.y), c.size - 1) {
            for x in max(Int(lo.x), 0)...min(Int(hi.x), c.size - 1) {
                let rel = Vec2(Float(x) + 0.5, Float(y) + 0.5) - base
                var along = dot(rel, dir), across = dot(rel, side)
                // A gentle curve: the midrib bends sideways with the square of the distance.
                across -= bend * along * along / max(L, 1)
                let s = along / L
                guard s >= -0.02, s <= 1.02 else { continue }
                let hw = halfMax * outline.halfWidth(min(max(s, 0), 1))
                let margin = hw - abs(across)
                let cover = min(max(margin + 0.5, 0), 1) * min(max((along + 0.5), 0), 1) * min(max((L - along) + 0.5, 0), 1)
                guard cover > 0 else { continue }
                let t = hw > 0.5 ? min(abs(across) / hw, 1) : 1
                let midrib = expf(-(across * across) / max(0.6 + W * 0.004, 0.36))
                let phase = s * veins - t * 0.8
                let ribbed: Float = outline == .needle || outline == .blade ? 0 : 1
                let wave: Float = powf(max(cosf(2 * Float.pi * phase), 0), 14)
                let veinLine: Float = ribbed * wave * (1 - t) * smoothstep(0.05, 0.2, s)
                let tipFade: Float = smoothstep(0.75, 1.0, s) * 0.08
                let rootShade: Float = outline == .blade ? 0.55 + 0.45 * smoothstep(0, 0.45, s) : 1
                let edge: Float = (0.86 + 0.14 * (1 - t * t)) * rootShade
                var col = mix(color, vein, min(midrib * 0.7 + veinLine * 0.45, 1))
                let warm: Float = edge * (1 + tipFade), cool: Float = edge * (1 - tipFade)
                col = (col.0 * warm, col.1 * edge, col.2 * cool)
                let dome: Float = 0.22 * (1 - t * t)
                let height: Float = 0.5 + dome - 0.1 * midrib - 0.05 * veinLine
                c.put(y * c.size + x, cover, col, height: height, occlusion: 0.72 + 0.28 * layer - 0.08 * t * t)
            }
        }
    }

    /// A star-shaped leaf or flower around `center`, `radius` pixels, its axis at `angle`.
    static func polar(_ c: inout Canvas, center: Vec2, angle: Float, radius R: Float, shape: Polar, color: RGB, layer: Float,
                      lobeVeins: [Float] = [0, 1.05, -1.05, 2.05, -2.05]) {
        let lo = center - Vec2(R * 1.5, R * 1.5), hi = center + Vec2(R * 1.5, R * 1.5)
        let vein = (min(color.0 * 1.35 + 0.02, 1), min(color.1 * 1.25 + 0.02, 1), min(color.2 * 1.1, 1))
        for y in max(Int(lo.y), 0)...min(Int(hi.y), c.size - 1) {
            for x in max(Int(lo.x), 0)...min(Int(hi.x), c.size - 1) {
                let rel = Vec2(Float(x) + 0.5, Float(y) + 0.5) - center
                let dist = length(rel)
                // Angle from the leaf's axis (axis = direction `angle`, 0 = up).
                let phi = atan2f(rel.x, -rel.y) - angle
                let edgeR = R * shape.radius(phi)
                let cover = min(max(edgeR - dist + 0.5, 0), 1)
                guard cover > 0 else { continue }
                let t = min(dist / max(edgeR, 0.5), 1)
                var veinLine: Float = 0
                if shape != .petal {
                    for v in lobeVeins {
                        let d = abs(remainderf(phi - v, 2 * .pi)) * dist
                        veinLine = max(veinLine, expf(-d * d / 0.8))
                    }
                }
                let edge = 0.86 + 0.14 * (1 - t * t)
                var col = mix(color, vein, veinLine * 0.6)
                col = (col.0 * edge, col.1 * edge, col.2 * edge)
                let height = 0.5 + 0.2 * (1 - t * t) - 0.08 * veinLine
                c.put(y * c.size + x, cover, col, height: height, occlusion: 0.75 + 0.25 * layer - 0.06 * t)
            }
        }
    }

    /// A round dot (a flower's center).
    static func disc(_ c: inout Canvas, center: Vec2, radius R: Float, color: RGB, layer: Float) {
        let lo = center - Vec2(R + 1, R + 1), hi = center + Vec2(R + 1, R + 1)
        for y in max(Int(lo.y), 0)...min(Int(hi.y), c.size - 1) {
            for x in max(Int(lo.x), 0)...min(Int(hi.x), c.size - 1) {
                let d = length(Vec2(Float(x) + 0.5, Float(y) + 0.5) - center)
                let cover = min(max(R - d + 0.5, 0), 1)
                guard cover > 0 else { continue }
                let t = min(d / R, 1)
                c.put(y * c.size + x, cover, (color.0 * (1 - 0.25 * t), color.1 * (1 - 0.25 * t), color.2 * (1 - 0.25 * t)),
                      height: 0.7 - 0.1 * t, occlusion: 0.85 + 0.15 * layer)
            }
        }
    }

    @inline(__always) static func lin(_ r: Float, _ g: Float, _ b: Float) -> RGB {
        (MeshBuildLookSampler.lin(r), MeshBuildLookSampler.lin(g), MeshBuildLookSampler.lin(b))
    }
    @inline(__always) static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB { MeshBuildLookSampler.mix(a, b, t) }
    @inline(__always) static func scale(_ a: RGB, _ k: (Float, Float, Float)) -> RGB { (a.0 * k.0, a.1 * k.1, a.2 * k.2) }
    @inline(__always) static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float { TileNoise.smoothstep(a, b, x) }

    /// The four variants' color shifts: as is, a sunnier yellow-green, a deeper blue-green, a paler one.
    static let variantTints: [(Float, Float, Float)] = [(1, 1, 1), (1.22, 1.12, 0.78), (0.8, 0.9, 1.0), (1.08, 1.1, 1.05)]

    /// A point on a quadratic curve from `a` through control `c` to `b`.
    static func curve(_ a: Vec2, _ c: Vec2, _ b: Vec2, _ t: Float) -> Vec2 {
        a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t)
    }

    // MARK: Looks

    /// Paints variant `v` of `look` on a `size` canvas.
    static func paintVariant(_ look: MeshBuildLeafLook, _ v: Int, size n: Int) -> Canvas {
        var c = Canvas(size: n)
        var rng = Random(MeshBuildLeafLook.allCases.firstIndex(of: look)! * 7919 + v * 104_729 + 11)
        let S = Float(n)
        let tint = variantTints[v % variantTints.count]
        let baseY = S * 0.97, midX = S * 0.5
        let stemColor = lin(0.33, 0.27, 0.16)

        /// A sprig: a stem curving up from the bottom with leaves alternating along it (and at its tip).
        func sprig(count: Int, outline: Outline, green: RGB, leafLength: Float, leafWidth: Float, spread: Float, veins: Float,
                   stemWidth: Float) {
            let lean = rng.range(-0.25, 0.25)
            let top = Vec2(midX + S * lean * 0.6, S * 0.08)
            let control = Vec2(midX + S * rng.range(-0.18, 0.18), S * 0.5)
            let base = Vec2(midX, baseY)
            let samples = (0...16).map { curve(base, control, top, Float($0) / 16) }
            stem(&c, samples, stemWidth, stemWidth * 0.35, stemColor, layer: 0.2)
            // Leaves from the base up, alternating sides; the later (higher) ones on top.
            for k in 0..<count {
                let t = 0.18 + 0.8 * Float(k) / Float(max(count - 1, 1))
                let p = curve(base, control, top, min(t, 1))
                let ahead = curve(base, control, top, min(t + 0.02, 1)) - p
                let stemAngle = atan2f(ahead.x, -ahead.y)
                let sideSign: Float = k % 2 == 0 ? 1 : -1
                let isTip = k == count - 1
                let angle = isTip ? stemAngle + rng.range(-0.15, 0.15) : stemAngle + sideSign * (spread + rng.range(-0.25, 0.25))
                let size = (isTip ? 1.05 : 0.8 + 0.3 * rng.next()) * (1 - 0.25 * max(t - 0.6, 0))
                let shade = 0.8 + 0.35 * rng.next()
                let col = scale(green, (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                leaf(&c, base: p, angle: angle, length: S * leafLength * size, width: S * leafWidth * size, outline: outline,
                     color: col, veins: veins, bend: rng.range(-0.25, 0.25), layer: 0.3 + 0.7 * Float(k) / Float(count))
            }
        }

        switch look {
        case .broadleaf:
            sprig(count: 11, outline: .oval, green: lin(0.25, 0.42, 0.12), leafLength: 0.34, leafWidth: 0.17, spread: 1.0, veins: 7,
                  stemWidth: S * 0.016)
        case .oakLeaves:
            sprig(count: 7, outline: .oak, green: lin(0.22, 0.36, 0.11), leafLength: 0.36, leafWidth: 0.2, spread: 0.85, veins: 5,
                  stemWidth: S * 0.016)
        case .mapleLeaves:
            // Long-stalked palmate leaves fanning from a short twig.
            let base = Vec2(midX, baseY)
            stem(&c, [base, Vec2(midX + S * rng.range(-0.05, 0.05), S * 0.66)], S * 0.018, S * 0.01, stemColor, layer: 0.2)
            let count = 7
            for k in 0..<count {
                // Back row first (wide fan), then the front row (narrower, lower).
                let front = k >= 4
                let slot = front ? Float(k - 4) / 2 : Float(k) / 3
                let angle = (front ? -0.75 + 1.5 * slot : -1.25 + 2.5 * slot) + rng.range(-0.12, 0.12)
                let start = Vec2(midX, S * (front ? 0.7 : 0.64))
                let reach = S * (front ? rng.range(0.08, 0.11) : rng.range(0.13, 0.17))
                let tip = start + Vec2(sinf(angle), -cosf(angle)) * reach
                stem(&c, [start, tip], S * 0.008, S * 0.006, lin(0.45, 0.3, 0.15), layer: 0.3)
                let radius = S * (front ? rng.range(0.17, 0.2) : rng.range(0.19, 0.23))
                let center = tip + Vec2(sinf(angle), -cosf(angle)) * radius * 0.82
                let shade = 0.8 + 0.35 * rng.next()
                let col = scale(lin(0.26, 0.42, 0.1), (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                polar(&c, center: center, angle: angle, radius: radius, shape: .maple, color: col, layer: 0.3 + 0.7 * Float(k) / Float(count))
            }
        case .pineNeedles:
            // A twig with side shoots, every shoot a bottlebrush of needles.
            let base = Vec2(midX, baseY)
            let top = Vec2(midX + S * rng.range(-0.1, 0.1), S * 0.05)
            var shoots: [(Vec2, Vec2)] = [(base, top)]
            for k in 0..<4 {
                let t = 0.25 + 0.17 * Float(k)
                let p = base + (top - base) * t
                let sideSign: Float = k % 2 == 0 ? 1 : -1
                let angle = sideSign * rng.range(0.6, 0.95)
                shoots.append((p, p + Vec2(sinf(angle), -cosf(angle)) * S * rng.range(0.25, 0.36)))
            }
            for (i, shoot) in shoots.enumerated() {
                stem(&c, [shoot.0, shoot.1], S * (i == 0 ? 0.016 : 0.01), S * 0.005, lin(0.32, 0.24, 0.15), layer: 0.15)
            }
            for (i, shoot) in shoots.enumerated() {
                let d = shoot.1 - shoot.0, len = length(d)
                let dirAngle = atan2f(d.x, -d.y)
                let needles = Int(len / (S * 0.008))
                for k in 0..<needles {
                    let t = Float(k) / Float(max(needles, 1))
                    let p = shoot.0 + d * t
                    let sideSign: Float = k % 2 == 0 ? 1 : -1
                    let angle = dirAngle + sideSign * rng.range(0.55, 0.95)
                    let shade = 0.75 + 0.4 * rng.next()
                    let col = scale(lin(0.13, 0.27, 0.13), (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                    let needleLength = S * rng.range(0.07, 0.1) * (0.7 + 0.3 * (1 - abs(t - 0.5) * 2)) * (i == 0 ? 1.1 : 1)
                    leaf(&c, base: p, angle: angle, length: needleLength, width: S * 0.0085, outline: .needle, color: col,
                         veins: 0, bend: rng.range(-0.1, 0.1), layer: 0.3 + 0.7 * t)
                }
            }
        case .fern:
            // One frond filling the quadrant: leaflets along a curving stem, longest a third of the way up.
            let base = Vec2(midX, baseY)
            let top = Vec2(midX + S * rng.range(-0.08, 0.08), S * 0.03)
            let control = Vec2(midX + S * rng.range(-0.12, 0.12), S * 0.5)
            stem(&c, (0...16).map { curve(base, control, top, Float($0) / 16) }, S * 0.014, S * 0.004, lin(0.3, 0.38, 0.14), layer: 0.2)
            let pairs = 15
            for k in 0..<pairs {
                let t = 0.1 + 0.88 * Float(k) / Float(pairs - 1)
                let p = curve(base, control, top, t)
                let ahead = curve(base, control, top, min(t + 0.02, 1)) - p
                let stemAngle = atan2f(ahead.x, -ahead.y)
                let envelope = sinf(.pi * min(powf(t, 0.75), 1)) * 0.95 + 0.08
                for sideSign: Float in [-1, 1] {
                    let shade = 0.85 + 0.25 * rng.next()
                    let col = scale(lin(0.2, 0.4, 0.1), (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                    leaf(&c, base: p, angle: stemAngle + sideSign * rng.range(1.05, 1.3), length: S * 0.26 * envelope,
                         width: S * 0.055 * envelope + 2, outline: .pinna, color: col, veins: 9, bend: sideSign * 0.18, layer: 0.4 + 0.6 * t)
                }
            }
        case .grassBlades:
            // Blades fanning up from the bottom middle, back ones darker.
            let blades = 13
            for k in 0..<blades {
                let x = midX + S * rng.range(-0.12, 0.12)
                let angle = rng.range(-0.55, 0.55)
                let shade = 0.65 + 0.5 * Float(k) / Float(blades) + 0.15 * rng.next()
                let dry = rng.next() < 0.18
                let green = dry ? lin(0.5, 0.48, 0.24) : lin(0.24, 0.42, 0.11)
                let col = scale(green, (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                leaf(&c, base: Vec2(x, baseY + S * 0.02), angle: angle, length: S * rng.range(0.62, 0.93), width: S * rng.range(0.035, 0.05),
                     outline: .blade, color: col, veins: 0, bend: (angle > 0 ? 1 : -1) * rng.range(0.1, 0.45), layer: Float(k) / Float(blades))
            }
        case .flowers:
            // Three or four leafy stems, each with a flower: white, yellow, pink or violet by variant.
            let petals: [RGB] = [lin(0.93, 0.92, 0.88), lin(0.98, 0.82, 0.2), lin(0.93, 0.55, 0.7), lin(0.62, 0.5, 0.9)]
            let petal = petals[v % petals.count]
            let stems = 3 + v % 2
            var heads: [(Vec2, Float)] = []
            for k in 0..<stems {
                let x = midX + S * (Float(k) - Float(stems - 1) / 2) * 0.12 + S * rng.range(-0.03, 0.03)
                let top = Vec2(x + S * rng.range(-0.15, 0.15), S * rng.range(0.12, 0.35))
                let base = Vec2(midX + S * rng.range(-0.04, 0.04), baseY)
                let control = Vec2((x + base.x) / 2 + S * rng.range(-0.05, 0.05), S * 0.6)
                stem(&c, (0...12).map { curve(base, control, top, Float($0) / 12) }, S * 0.011, S * 0.007, lin(0.25, 0.4, 0.12), layer: 0.2)
                for j in 0..<3 {
                    let t = 0.2 + 0.2 * Float(j)
                    let p = curve(base, control, top, t)
                    let sideSign: Float = (j + k) % 2 == 0 ? 1 : -1
                    let col = scale(lin(0.22, 0.4, 0.11), (0.85 + 0.3 * rng.next(), 1, 1))
                    leaf(&c, base: p, angle: sideSign * rng.range(0.6, 1.1), length: S * rng.range(0.14, 0.2), width: S * 0.05,
                         outline: .lance, color: col, veins: 5, bend: sideSign * 0.2, layer: 0.4)
                }
                heads.append((top, S * rng.range(0.07, 0.1)))
            }
            for (center, radius) in heads {
                let shade = 0.9 + 0.15 * rng.next()
                polar(&c, center: center, angle: rng.range(0, 1.2), radius: radius, shape: .petal,
                      color: (petal.0 * shade, petal.1 * shade, petal.2 * shade), layer: 1)
                disc(&c, center: center, radius: radius * 0.3, color: lin(0.85, 0.62, 0.1), layer: 1)
            }
        case .ivy:
            // A vine winding up with glossy leaves on short stalks.
            let base = Vec2(midX, baseY)
            let top = Vec2(midX + S * rng.range(-0.15, 0.15), S * 0.06)
            let control = Vec2(midX + S * rng.range(-0.25, 0.25), S * 0.5)
            stem(&c, (0...16).map { curve(base, control, top, Float($0) / 16) }, S * 0.014, S * 0.008, lin(0.35, 0.3, 0.2), layer: 0.2)
            let count = 6
            for k in 0..<count {
                let t = 0.12 + 0.86 * Float(k) / Float(count - 1)
                let p = curve(base, control, top, t)
                let sideSign: Float = k % 2 == 0 ? 1 : -1
                let angle = sideSign * rng.range(0.5, 1.1) + rng.range(-0.2, 0.2)
                let stalk = p + Vec2(sinf(angle), -cosf(angle)) * S * 0.07
                stem(&c, [p, stalk], S * 0.007, S * 0.006, lin(0.3, 0.32, 0.15), layer: 0.3)
                let radius = S * rng.range(0.14, 0.17) * (1 - 0.2 * t)
                let center = stalk + Vec2(sinf(angle), -cosf(angle)) * radius * 0.75
                let shade = 0.8 + 0.3 * rng.next()
                let col = scale(lin(0.1, 0.26, 0.07), (tint.0 * shade, tint.1 * shade, tint.2 * shade))
                polar(&c, center: center, angle: angle, radius: radius, shape: .ivy, color: col, layer: 0.3 + 0.7 * Float(k) / Float(count),
                      lobeVeins: [0, 1.2, -1.2, 2.2, -2.2])
            }
        }
        return c
    }

    // MARK: Textures

    /// The look's textures: four variants in a grid, transparent texels filled with nearby colors.
    static func paint(_ look: MeshBuildLeafLook, resolution: Int) -> MeshBuildLeafTextures {
        let g = MeshBuildLeafTextures.variantGrid
        let n = resolution, q = n / g
        // A margin around each variant so filtering never reaches the next one's leaves.
        let margin = max(q / 64, 2)
        let inner = q - 2 * margin
        final class Results: @unchecked Sendable {
            let lock = NSLock()
            var canvases: [Int: Canvas] = [:]
        }
        let results = Results()
        DispatchQueue.concurrentPerform(iterations: g * g) { v in
            let canvas = paintVariant(look, v, size: inner)
            results.lock.lock()
            results.canvases[v] = canvas
            results.lock.unlock()
        }
        let painted = (0..<(g * g)).map { results.canvases[$0]! }
        var r = [Float](repeating: 0, count: n * n), gg = r, b = r, a = r, ao = [Float](repeating: 1, count: n * n)
        var h = [Float](repeating: 0.5, count: n * n)
        for v in 0..<(g * g) {
            let ox = (v % g) * q + margin, oy = (v / g) * q + margin
            let c = painted[v]
            for y in 0..<inner {
                for x in 0..<inner {
                    let src = y * inner + x, dst = (oy + y) * n + ox + x
                    r[dst] = c.r[src]; gg[dst] = c.g[src]; b[dst] = c.b[src]; a[dst] = c.a[src]
                    h[dst] = c.h[src]; ao[dst] = c.ao[src]
                }
            }
        }
        // Average color over the leaves.
        var sum = (0.0, 0.0, 0.0, 0.0)
        for i in 0..<(n * n) where a[i] > 0.5 {
            sum.0 += Double(r[i]); sum.1 += Double(gg[i]); sum.2 += Double(b[i]); sum.3 += 1
        }
        let count = max(sum.3, 1)
        let average = Vec3(Float(sum.0 / count), Float(sum.1 / count), Float(sum.2 / count))
        // Fill the transparent texels (color, height, occlusion) from their surroundings.
        let filled = pushPullFill([r, gg, b, h, ao], alpha: a, size: n)
        var albedo = [UInt8](repeating: 255, count: n * n * 4), orm = albedo
        let rough = look.roughness
        for i in 0..<(n * n) {
            albedo[i * 4] = MeshBuildLookTextures.srgbByte(filled[0][i])
            albedo[i * 4 + 1] = MeshBuildLookTextures.srgbByte(filled[1][i])
            albedo[i * 4 + 2] = MeshBuildLookTextures.srgbByte(filled[2][i])
            albedo[i * 4 + 3] = TileNoise.unitByte(a[i])
            orm[i * 4] = TileNoise.unitByte(filled[4][i])
            orm[i * 4 + 1] = TileNoise.unitByte(rough * (0.92 + 0.16 * (1 - filled[3][i])))
            orm[i * 4 + 2] = 0
        }
        let normal = TileNoise.normalMap(height: filled[3], width: n, height: n, strength: 0.022 * 512 / Float(n))
        return MeshBuildLeafTextures(look: look, resolution: n, albedo: Image(width: n, height: n, pixels: albedo),
                                     normal: Image(width: n, height: n, pixels: normal), orm: Image(width: n, height: n, pixels: orm),
                                     averageColor: average, coverage: Float(sum.3) / Float(n * n))
    }

    /// `channels` with their transparent texels (alpha 0) filled with the average of the nearest
    /// covered ones (a pull-push pyramid); covered texels keep their values (partly covered ones
    /// blend toward the fill).
    static func pushPullFill(_ channels: [[Float]], alpha: [Float], size n: Int) -> [[Float]] {
        // Down: alpha-weighted sums.
        var levels: [(size: Int, w: [Float], c: [[Float]])] = [(n, alpha, channels.map { ch in zip(ch, alpha).map { $0 * $1 } })]
        while levels.last!.size > 1 {
            let prev = levels.last!, m = prev.size / 2
            var w = [Float](repeating: 0, count: m * m)
            var c = channels.map { _ in [Float](repeating: 0, count: m * m) }
            for y in 0..<m {
                for x in 0..<m {
                    let i = y * m + x
                    for (dy, dx) in [(0, 0), (0, 1), (1, 0), (1, 1)] {
                        let j = (2 * y + dy) * prev.size + 2 * x + dx
                        w[i] += prev.w[j]
                        for k in c.indices { c[k][i] += prev.c[k][j] }
                    }
                }
            }
            levels.append((m, w, c))
        }
        // Up: each level's normalized values, falling back to the coarser level where it has no weight.
        var fill: [[Float]] = levels.last!.c.enumerated().map { k, ch in
            let w = levels.last!.w[0]
            return [w > 0 ? ch[0] / w : (k == 3 ? 0.5 : k == 4 ? 1 : 0)]
        }
        for level in levels.dropLast().reversed() {
            let m = level.size, half = max(m / 2, 1)
            var next = channels.map { _ in [Float](repeating: 0, count: m * m) }
            for y in 0..<m {
                for x in 0..<m {
                    let i = y * m + x
                    let coarse = min(y / 2, half - 1) * half + min(x / 2, half - 1)
                    let w = level.w[i]
                    let own = min(w, 1)
                    for k in next.indices {
                        let value = w > 0 ? level.c[k][i] / w : 0
                        next[k][i] = value * own + fill[k][coarse] * (1 - own)
                    }
                }
            }
            fill = next
        }
        // Keep covered texels exact.
        return channels.indices.map { k in
            (0..<(n * n)).map { i in alpha[i] >= 1 ? channels[k][i] : channels[k][i] * alpha[i] + fill[k][i] * (1 - alpha[i]) }
        }
    }
}

@inline(__always) private func dot(_ a: Vec2, _ b: Vec2) -> Float { a.x * b.x + a.y * b.y }
@inline(__always) private func length(_ v: Vec2) -> Float { (v.x * v.x + v.y * v.y).squareRoot() }
