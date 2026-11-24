#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineAssets

// Mesh build looks: a part's `look` ("wood", "rustyMetal", "brick"…) gives it a realistic surface
// made of generated, tileable textures instead of a flat color:
//
// - albedo (sRGB): the surface's color detail, normalized so its average is 0.5 per channel; the
//   material's base color (2 x the part's color, or 2 x the look's natural average color when the
//   part keeps the default color) brings it back, so `color` sets the average color: a stain for
//   wood, the paint of painted metal.
// - normal (linear, tangent space): from the look's height field.
// - ORM (linear): occlusion (cavities of the height field) in R, roughness in G, metalness in B,
//   used as both the metallic-roughness and the occlusion texture.
//
// Textures are generated on the CPU, on all cores, once per look, wear level and resolution per
// process (`MeshBuildLookTextures.textures`), then stored with the import in the Library like any
// imported texture. Every generator works in tile coordinates with integer frequencies
// (TileNoise.swift), so textures repeat seamlessly; a part's look coordinates are in meters
// divided by `lookScale` (see MeshBuildLookMapping.swift), offset per part so neighbors differ.
//
// Grain, brushing, planks and bark furrows run along the texture's U axis, which the mapping
// lays along the part's `grain` axis.

/// A ready-made surface for a mesh build part (`MeshBuildPart.look`).
public enum MeshBuildLook: String, Codable, CaseIterable, Sendable {
    case wood, paintedWood, planks, bark
    case brushedMetal, polishedMetal, paintedMetal, rustyMetal, gold, copper, brass
    case stone, cobblestone, concrete, brick, ceramic
    case plastic, rubber, glass, fabric, leather
    case dirt, grass

    /// What the docs and the editor call it.
    public var title: String {
        switch self {
        case .paintedWood: "Painted wood"
        case .brushedMetal: "Brushed metal"
        case .polishedMetal: "Polished metal"
        case .paintedMetal: "Painted metal"
        case .rustyMetal: "Rusty metal"
        case .dirt: "Dirt (ground)"
        default: rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    /// Meters one texture tile covers by default (`MeshBuildPart.lookScale`).
    public var defaultScale: Float {
        switch self {
        case .wood: 1.0
        case .paintedWood: 1.0
        case .planks: 1.2
        case .bark: 0.8
        case .brushedMetal: 0.6
        case .polishedMetal: 1.5
        case .paintedMetal: 1.0
        case .rustyMetal: 1.0
        case .gold, .copper, .brass: 0.6
        case .stone: 1.2
        case .cobblestone: 1.2
        case .concrete: 2.0
        case .brick: 0.9
        case .ceramic: 0.6
        case .plastic: 0.5
        case .rubber: 0.3
        case .glass: 1.0
        case .fabric: 0.25
        case .leather: 0.3
        case .dirt: 1.6
        case .grass: 1.0
        }
    }

    /// Height range of the look's bumps in meters at its default scale (the normal map's depth).
    var bumpDepth: Float {
        switch self {
        case .wood: 0.0008
        case .paintedWood: 0.0005
        case .planks: 0.004
        case .bark: 0.03
        case .brushedMetal: 0.00012
        case .polishedMetal, .glass: 0.00005
        case .paintedMetal: 0.0003
        case .rustyMetal: 0.004
        case .gold, .copper, .brass: 0.0002
        case .stone: 0.02
        case .cobblestone: 0.03
        case .concrete: 0.004
        case .brick: 0.012
        case .ceramic: 0.0004
        case .plastic: 0.00015
        case .rubber: 0.0004
        case .fabric: 0.0012
        case .leather: 0.0007
        case .dirt: 0.012
        case .grass: 0.006
        }
    }

    /// A look that is see-through (its parts blend at `defaultOpacity` unless `opacity` is set).
    public var defaultOpacity: Float { self == .glass ? 0.25 : 1 }

    /// Natural grain direction matters for this look (wood, planks, bark, brushed metal).
    public var hasGrain: Bool { self == .wood || self == .paintedWood || self == .planks || self == .bark || self == .brushedMetal }

    /// A metal (brushed, polished, rusty, gold, copper, brass).
    public var isMetal: Bool { wearKind == .metal }

    /// How wear shows: paint chips off, metal scratches, or surfaces just get grimy.
    enum WearKind { case paint, metal, smooth, rough }

    var wearKind: WearKind {
        switch self {
        case .paintedWood, .paintedMetal: .paint
        case .brushedMetal, .polishedMetal, .rustyMetal, .gold, .copper, .brass: .metal
        case .plastic, .ceramic, .glass, .rubber, .leather: .smooth
        default: .rough
        }
    }

    /// The look named `name`, ignoring case, spaces, dashes and underscores ("painted metal",
    /// "Painted-Metal"), plus a few aliases (ground, metal, steel, iron, bricks, cloth, wooden).
    public static func named(_ name: String) -> MeshBuildLook? {
        let key = name.lowercased().filter { $0.isLetter }
        if let look = allCases.first(where: { $0.rawValue.lowercased() == key }) { return look }
        switch key {
        case "ground", "soil", "mud": return .dirt
        case "metal", "steel", "aluminium", "aluminum": return .brushedMetal
        case "iron", "rust", "rusty": return .rustyMetal
        case "chrome", "mirror": return .polishedMetal
        case "bricks": return .brick
        case "cloth", "canvas": return .fabric
        case "wooden": return .wood
        case "plank", "boards", "floorboards": return .planks
        case "cobbles", "cobble": return .cobblestone
        case "rock": return .stone
        case "porcelain": return .ceramic
        case "bronze": return .brass
        default: return nil
        }
    }

    /// "wood, paintedWood, …" for warnings and docs.
    public static var nameList: String { allCases.map(\.rawValue).joined(separator: ", ") }
}

/// One look's generated textures (see the notes at the top of this file).
public struct MeshBuildLookTextures: Sendable {
    public var look: MeshBuildLook
    /// 0 (none) ... `MeshBuildLookTextures.wearLevels` - 1.
    public var wearLevel: Int
    public var resolution: Int
    /// sRGB; average 0.5 per channel before wear.
    public var albedo: Image
    /// Linear tangent-space normal map.
    public var normal: Image
    /// Linear: occlusion R, roughness G, metalness B.
    public var orm: Image
    /// The look's average color before wear, linear (what albedo x 2 x this gives on average).
    public var averageColor: Vec3
    /// The look's average roughness.
    public var averageRoughness: Float

    /// Wear is quantized to this many levels (0, ¼, ½, ¾, 1), so parts share textures.
    public static let wearLevels = 5
    /// The resolution the importer generates (pixels per side).
    public static let defaultResolution = 512

    public static func wearLevel(_ wear: Float?) -> Int {
        guard let wear, wear.isFinite else { return 0 }
        return Int((min(max(wear, 0), 1) * Float(wearLevels - 1)).rounded())
    }

    // MARK: Cache

    private struct Key: Hashable {
        var look: MeshBuildLook
        var wear: Int
        var resolution: Int
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [Key: MeshBuildLookTextures] = [:]
    nonisolated(unsafe) private static var generating: [Key: NSCondition] = [:]
    nonisolated(unsafe) private static var generatedCount = 0
    nonisolated(unsafe) private static var averages: [MeshBuildLook: (Vec3, Float)] = [:]

    /// How many texture sets have been generated in this process (tests check caching with it).
    public static var generations: Int {
        lock.lock()
        defer { lock.unlock() }
        return generatedCount
    }

    /// Drops every cached set (tests).
    public static func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }

    /// The textures of `look` at `wearLevel` and `resolution`: from the cache, else generated now
    /// (once, even when several imports ask at the same time).
    public static func textures(_ look: MeshBuildLook, wearLevel: Int = 0, resolution: Int = defaultResolution) -> MeshBuildLookTextures {
        let key = Key(look: look, wear: min(max(wearLevel, 0), wearLevels - 1), resolution: min(max(resolution, 8), 4096))
        while true {
            lock.lock()
            if let hit = cache[key] {
                lock.unlock()
                return hit
            }
            if let pending = generating[key] {
                // Another thread is making it: wait, then look again.
                pending.lock()
                lock.unlock()
                pending.wait()
                pending.unlock()
                continue
            }
            let condition = NSCondition()
            generating[key] = condition
            generatedCount += 1
            lock.unlock()
            let made = generate(key.look, wearLevel: key.wear, resolution: key.resolution)
            lock.lock()
            if cache.count > 96 { cache.removeAll() }
            cache[key] = made
            generating[key] = nil
            lock.unlock()
            condition.lock()
            condition.broadcast()
            condition.unlock()
            return made
        }
    }

    /// The look's average color (linear) and roughness without wear, from a small sample.
    public static func average(_ look: MeshBuildLook) -> (color: Vec3, roughness: Float) {
        lock.lock()
        if let hit = averages[look] {
            lock.unlock()
            return hit
        }
        lock.unlock()
        let n = 64
        var sum = (r: 0.0, g: 0.0, b: 0.0, rough: 0.0)
        forEachIndex(0..<n) { y in
            forEachIndex(0..<n) { x in
                let t = MeshBuildLookSampler.sample(look, (Float(x) + 0.5) / Float(n), (Float(y) + 0.5) / Float(n), wear: 0)
                sum.r += Double(t.r); sum.g += Double(t.g); sum.b += Double(t.b); sum.rough += Double(t.rough)
            }
        }
        let count = Double(n * n)
        let result = (Vec3(Float(sum.r / count), Float(sum.g / count), Float(sum.b / count)), Float(sum.rough / count))
        lock.lock()
        averages[look] = result
        lock.unlock()
        return result
    }

    // MARK: Generation

    /// Makes the textures (all rows in parallel).
    static func generate(_ look: MeshBuildLook, wearLevel: Int, resolution n: Int) -> MeshBuildLookTextures {
        let wear = Float(wearLevel) / Float(wearLevels - 1)
        let (average, averageRoughness) = Self.average(look)
        // Pass 1: every texel's surface, 6 floats each.
        let texels = TileNoise.parallelRows(n, n * 6, initial: Float(0)) { y, out in
            let v = (Float(y) + 0.5) / Float(n)
            // Counted loops here and below: they run per texel (ForEachIndex.swift).
            forEachIndex(0..<n) { x in
                let t = MeshBuildLookSampler.sample(look, (Float(x) + 0.5) / Float(n), v, wear: wear)
                out[x * 6] = t.r; out[x * 6 + 1] = t.g; out[x * 6 + 2] = t.b
                out[x * 6 + 3] = t.h; out[x * 6 + 4] = t.rough; out[x * 6 + 5] = t.metal
            }
        }
        var height = [Float](repeating: 0, count: n * n)
        forEachIndex(0..<(n * n)) { i in height[i] = texels[i * 6 + 3] }
        // Cavities: how far below its blurred surroundings each texel is.
        let blurred = TileNoise.blur(height, width: n, height: n, radius: max(n / 64, 1))
        let cavityGain: Float = look == .cobblestone || look == .brick || look == .bark || look == .planks ? 2.2 : 1.4

        let scale = (r: 0.5 / max(average.x, 1e-4), g: 0.5 / max(average.y, 1e-4), b: 0.5 / max(average.z, 1e-4))
        let albedo = texels.withUnsafeBufferPointer { t in
            let t = SharedPointer(t.baseAddress!)
            return TileNoise.parallelRows(n, n * 4, initial: UInt8(255)) { y, out in
                forEachIndex(0..<n) { x in
                    let i = (y * n + x) * 6
                    out[x * 4] = srgbByte(t[i] * scale.r)
                    out[x * 4 + 1] = srgbByte(t[i + 1] * scale.g)
                    out[x * 4 + 2] = srgbByte(t[i + 2] * scale.b)
                }
            }
        }
        let orm = texels.withUnsafeBufferPointer { t in
            blurred.withUnsafeBufferPointer { b in
                let t = SharedPointer(t.baseAddress!), b = SharedPointer(b.baseAddress!)
                return TileNoise.parallelRows(n, n * 4, initial: UInt8(255)) { y, out in
                    forEachIndex(0..<n) { x in
                        let p = y * n + x, i = p * 6
                        let cavity = max(b[p] - t[i + 3], 0) * cavityGain
                        out[x * 4] = TileNoise.unitByte(1 - min(cavity, 0.75))
                        out[x * 4 + 1] = TileNoise.unitByte(t[i + 4])
                        out[x * 4 + 2] = TileNoise.unitByte(t[i + 5])
                    }
                }
            }
        }
        let strength = look.bumpDepth / look.defaultScale
        let normal = TileNoise.normalMap(height: height, width: n, height: n, strength: strength)
        return MeshBuildLookTextures(look: look, wearLevel: wearLevel, resolution: n,
                                     albedo: Image(width: n, height: n, pixels: albedo),
                                     normal: Image(width: n, height: n, pixels: normal),
                                     orm: Image(width: n, height: n, pixels: orm),
                                     averageColor: average, averageRoughness: averageRoughness)
    }

    @inline(__always) static func srgbByte(_ linear: Float) -> UInt8 {
        let x = min(max(linear, 0), 1)
        return TileNoise.unitByte(x <= 0.0031308 ? x * 12.92 : 1.055 * powf(x, 1 / 2.4) - 0.055)
    }
}

/// One texel of a look: linear albedo, height 0...1, roughness, metalness.
struct MeshBuildLookTexel {
    var r: Float
    var g: Float
    var b: Float
    var h: Float
    var rough: Float
    var metal: Float

    init(_ c: (Float, Float, Float), h: Float, rough: Float, metal: Float = 0) {
        r = c.0; g = c.1; b = c.2
        self.h = h
        self.rough = rough
        self.metal = metal
    }

    var color: (Float, Float, Float) {
        get { (r, g, b) }
        set { (r, g, b) = newValue }
    }
}

/// The looks' generators: every look is a function of tile coordinates (u along the grain).
enum MeshBuildLookSampler {
    typealias RGB = (Float, Float, Float)

    // MARK: Helpers

    @inline(__always) static func lin(_ r: Float, _ g: Float, _ b: Float) -> RGB { (lin(r), lin(g), lin(b)) }
    @inline(__always) static func lin(_ c: Float) -> Float { c <= 0.04045 ? c / 12.92 : powf((c + 0.055) / 1.055, 2.4) }
    @inline(__always) static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB {
        (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t)
    }
    @inline(__always) static func mul(_ a: RGB, _ k: Float) -> RGB { (a.0 * k, a.1 * k, a.2 * k) }
    @inline(__always) static func mul(_ a: RGB, _ b: RGB) -> RGB { (a.0 * b.0, a.1 * b.1, a.2 * b.2) }
    @inline(__always) static func clamp01(_ x: Float) -> Float { min(max(x, 0), 1) }

    @inline(__always) static func fbm(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, octaves: Int, seed: Int) -> Float {
        TileNoise.fbm(u, v, fx, fy, octaves: octaves, seed: seed)
    }
    @inline(__always) static func perlin(_ u: Float, _ v: Float, _ fx: Int, _ fy: Int, seed: Int) -> Float {
        TileNoise.perlin(u, v, fx, fy, seed: seed)
    }
    @inline(__always) static func smoothstep(_ a: Float, _ b: Float, _ x: Float) -> Float { TileNoise.smoothstep(a, b, x) }
    @inline(__always) static func fract(_ x: Float) -> Float { TileNoise.fract(x) }

    static func seed(_ look: MeshBuildLook, _ k: Int) -> Int {
        seedBase(look) &+ k &* 104_729
    }

    /// `seed(look, 0)`.
    static func seedBase(_ look: MeshBuildLook) -> Int {
        (lookOrder[look] ?? 0) &* 7919 &+ 17
    }

    /// Each look's position in `allCases` (its seeds' base): looked up per texel, where building
    /// `allCases` and searching it each time cost more than the noise.
    private static let lookOrder: [MeshBuildLook: Int] =
        Dictionary(uniqueKeysWithValues: MeshBuildLook.allCases.enumerated().map { ($0.element, $0.offset) })

    // MARK: Looks

    static func sample(_ look: MeshBuildLook, _ u: Float, _ v: Float, wear: Float) -> MeshBuildLookTexel {
        // The look's seeds, from one lookup of its position per texel.
        let base = seedBase(look)
        let s = { (k: Int) in base &+ k &* 104_729 }
        var t: MeshBuildLookTexel
        switch look {
        case .wood:
            t = wood(u, v, seed: s(0))
        case .paintedWood:
            let grain = wood(u, v, seed: s(0))
            let peel = fbm(u, v, 48, 48, octaves: 2, seed: s(1))
            t = MeshBuildLookTexel(mul(lin(0.86, 0.86, 0.82), 1 - (0.62 - grain.h) * 0.12 + peel * 0.01),
                                   h: grain.h * 0.6 + peel * 0.05 + 0.3, rough: 0.5 + peel * 0.03)
            if wear > 0 {
                // Chips through the paint show the wood, worst along the grain.
                let chip = fbm(u, v, 6, 10, octaves: 5, seed: s(2)) * 0.5 + 0.5 + (0.6 - grain.h) * 0.3
                let m = smoothstep(1.02 - wear * 0.32, 1.06 - wear * 0.32, chip)
                t.color = mix(t.color, mul(grain.color, 0.9), m)
                t.h -= m * 0.25
                t.rough = TileNoise.mix(t.rough, grain.rough, m)
            }
        case .planks:
            t = planks(u, v, seed: s(0))
        case .bark:
            t = bark(u, v, seed: s(0))
        case .brushedMetal:
            let streak = fbm(u, v, 1, 220, octaves: 3, seed: s(0)) + fbm(u, v, 3, 600, octaves: 2, seed: s(1)) * 0.6
            let cloud = fbm(u, v, 2, 2, octaves: 3, seed: s(2))
            t = MeshBuildLookTexel(mul(lin(0.66, 0.67, 0.69), 1 + streak * 0.07 + cloud * 0.04), h: 0.5 + streak * 0.35,
                                   rough: 0.3 + streak * 0.05 + cloud * 0.04, metal: 1)
        case .polishedMetal:
            let smudge = fbm(u, v, 3, 3, octaves: 4, seed: s(0))
            t = MeshBuildLookTexel(mul(lin(0.86, 0.86, 0.87), 1 + smudge * 0.02), h: 0.5 + smudge * 0.2,
                                   rough: 0.07 + max(smudge, 0) * 0.08, metal: 1)
        case .paintedMetal:
            let peel = fbm(u, v, 40, 40, octaves: 2, seed: s(0))
            let cloud = fbm(u, v, 2, 2, octaves: 3, seed: s(1))
            t = MeshBuildLookTexel(mul(lin(0.34, 0.42, 0.5), 1 + cloud * 0.04), h: 0.6 + peel * 0.15, rough: 0.42 + cloud * 0.05)
            if wear > 0 {
                let chip = fbm(u, v, 5, 5, octaves: 5, seed: s(2)) * 0.5 + 0.5
                let m = smoothstep(0.98 - wear * 0.3, 1.0 - wear * 0.3, chip)
                let bare = MeshBuildLookTexel(lin(0.5, 0.5, 0.5), h: 0.3, rough: 0.35, metal: 1)
                t = blend(t, bare, m)
                // Rust creeping in at the chips' edges.
                let edge = smoothstep(0.93 - wear * 0.3, 0.98 - wear * 0.3, chip) * (1 - m)
                t.color = mix(t.color, lin(0.4, 0.2, 0.09), edge * 0.6 * wear)
            }
        case .rustyMetal:
            t = rust(u, v, seed: s(0))
        case .gold:
            t = polishedAlloy(u, v, (1.0, 0.71, 0.29), seed: s(0))
        case .copper:
            t = polishedAlloy(u, v, (0.93, 0.6, 0.49), seed: s(0))
        case .brass:
            t = polishedAlloy(u, v, (0.86, 0.71, 0.38), seed: s(0))
        case .stone:
            t = stone(u, v, seed: s(0))
        case .cobblestone:
            t = cobblestone(u, v, seed: s(0))
        case .concrete:
            t = concrete(u, v, seed: s(0))
        case .brick:
            t = brick(u, v, seed: s(0))
        case .ceramic:
            let wave = fbm(u, v, 3, 3, octaves: 3, seed: s(0))
            let speck = perlin(u, v, 96, 96, seed: s(1))
            t = MeshBuildLookTexel(mul(lin(0.9, 0.89, 0.86), 1 + wave * 0.015 - max(speck - 0.75, 0) * 0.6), h: 0.5 + wave * 0.5,
                                   rough: 0.12 + wave * 0.03)
        case .plastic:
            let stipple = fbm(u, v, 64, 64, octaves: 2, seed: s(0))
            let cloud = fbm(u, v, 2, 2, octaves: 3, seed: s(1))
            t = MeshBuildLookTexel(mul(lin(0.8, 0.8, 0.8), 1 + cloud * 0.02), h: 0.5 + stipple * 0.4, rough: 0.38 + stipple * 0.04)
        case .rubber:
            let stipple = fbm(u, v, 48, 48, octaves: 3, seed: s(0))
            let cloud = fbm(u, v, 2, 2, octaves: 3, seed: s(1))
            t = MeshBuildLookTexel(mul(lin(0.1, 0.1, 0.1), 1 + cloud * 0.08 + stipple * 0.05), h: 0.5 + stipple * 0.5,
                                   rough: 0.82 + stipple * 0.05)
        case .glass:
            let smudge = fbm(u, v, 3, 3, octaves: 4, seed: s(0))
            t = MeshBuildLookTexel(lin(0.92, 0.95, 0.95), h: 0.5, rough: 0.03 + smoothstep(0.2, 0.7, smudge) * 0.12)
        case .fabric:
            t = fabric(u, v, seed: s(0))
        case .leather:
            t = leather(u, v, seed: s(0))
        case .dirt:
            t = dirt(u, v, seed: s(0))
        case .grass:
            t = grass(u, v, seed: s(0))
        }
        if wear > 0 { applyWear(&t, look, u, v, wear: wear, seed: s(50)) }
        t.rough = clamp01(t.rough)
        t.metal = clamp01(t.metal)
        return t
    }

    static func blend(_ a: MeshBuildLookTexel, _ b: MeshBuildLookTexel, _ m: Float) -> MeshBuildLookTexel {
        var t = a
        t.color = mix(a.color, b.color, m)
        t.h = TileNoise.mix(a.h, b.h, m)
        t.rough = TileNoise.mix(a.rough, b.rough, m)
        t.metal = TileNoise.mix(a.metal, b.metal, m)
        return t
    }

    /// Grime in low spots and patches, scratches on hard surfaces, at `wear` 0...1.
    static func applyWear(_ t: inout MeshBuildLookTexel, _ look: MeshBuildLook, _ u: Float, _ v: Float, wear: Float, seed: Int) {
        // Dirt: patchy, gathering where the surface is low (mortar, grain, cracks).
        let patch = fbm(u, v, 3, 3, octaves: 4, seed: seed) * 0.5 + 0.5
        let low = clamp01((0.55 - t.h) * 2)
        let dirt = clamp01(smoothstep(0.75 - wear * 0.45, 1.05 - wear * 0.35, patch + low * 0.35) * (0.4 + 0.6 * wear))
        let grime = lin(0.36, 0.3, 0.22)
        t.color = mix(t.color, mul(t.color, (grime.0 * 1.6, grime.1 * 1.6, grime.2 * 1.6)), dirt * 0.8)
        t.rough = TileNoise.mix(t.rough, max(t.rough, 0.85), dirt * 0.6)
        t.metal *= 1 - dirt * 0.5
        guard look.wearKind != .rough else { return }
        // Scratches: thin lines where sheared noise crosses zero, thinned out by a mask.
        var line: Float = 0
        forEachIndex(0..<3) { k in
            let n = perlin(u + v * Float(k == 1 ? 1 : 0), v + u * Float(k == 2 ? 1 : 0), 6 + k * 3, 40 + k * 17, seed: seed &+ 11 &+ k)
            let mask = smoothstep(0.35 - wear * 0.25, 0.6 - wear * 0.25, perlin(u, v, 4, 4, seed: seed &+ 21 &+ k) * 0.5 + 0.5)
            line = max(line, (1 - smoothstep(0.0, 0.035, abs(n))) * mask)
        }
        line *= wear
        switch look.wearKind {
        case .metal:
            t.color = mul(t.color, 1 + line * 0.25)
            t.rough = TileNoise.mix(t.rough, t.rough * 0.6 + 0.2, line)
        case .paint:
            t.color = mix(t.color, lin(0.55, 0.55, 0.55), line * 0.5)
            t.metal = max(t.metal, look == .paintedMetal ? line : 0)
            t.h -= line * 0.1
        default:
            t.color = mul(t.color, 1 + line * 0.15)
            t.rough = TileNoise.mix(t.rough, min(t.rough + 0.25, 1), line)
        }
    }

    /// Flat-sawn wood: growth lines across V with darker latewood, warped by slow noise, fine
    /// fibers and pores along U.
    static func wood(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        // Growth lines run along U; slow warps bend them into gentle arches, and their spacing
        // varies (rings of fast and slow years).
        let warp = fbm(u, v, 1, 2, octaves: 2, seed: seed) * 0.9 + fbm(u, v, 1, 6, octaves: 2, seed: seed &+ 1) * 0.25
        let rings = v * 20 + warp + fbm(u, v, 1, 4, octaves: 2, seed: seed &+ 6) * 0.5
        let r = fract(rings)
        let late = smoothstep(0.55, 0.88, r) * (1 - smoothstep(0.9, 1.0, r))
        let fibers = fbm(u, v, 2, 180, octaves: 3, seed: seed &+ 2)
        let fine = perlin(u, v + warp * 0.01, 3, 90, seed: seed &+ 5)
        let pores = clamp01((perlin(u, v, 24, 340, seed: seed &+ 3) - 0.5) * 3)
        let tone = fbm(u, v, 1, 3, octaves: 3, seed: seed &+ 4)
        let darkness = clamp01(late * 0.45 + fibers * 0.16 + fine * 0.1 + 0.2)
        var c = mix(lin(0.7, 0.5, 0.32), lin(0.42, 0.25, 0.13), darkness)
        c = mul(c, (1 + tone * 0.16) * (1 - pores * 0.2))
        return MeshBuildLookTexel(c, h: 0.6 - late * 0.25 + fibers * 0.1 + fine * 0.05 - pores * 0.3,
                                  rough: 0.6 + late * 0.08 + pores * 0.1)
    }

    /// Boards along U, 5 across a tile, each with its own grain and shade; staggered end joints.
    static func planks(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let rows = 5
        let fv = v * Float(rows)
        let row = Int(fv.rounded(.down))
        let r = TileNoise.wrap(row, rows)
        let lv = fv - Float(row)
        // One end joint per board row per tile, at a random place: boards as long as a tile.
        let joint = TileNoise.hash01(seed, r, 0, 1)
        let lu = fract(u - joint)
        let shift = TileNoise.hash01(seed, r, 1, 2)
        var t = wood(u, v + shift * 0.37 + Float(r) * 0.13, seed: seed &+ 7)
        let shade = 0.82 + 0.3 * TileNoise.hash01(seed, r, 3, 3)
        t.color = mul(t.color, shade)
        // Gaps with slightly rounded board edges.
        let gapV = min(lv, 1 - lv) * 1.2 / Float(rows)   // meters-ish in tile units
        let gapU = min(lu, 1 - lu) * 1.2
        let edge = min(gapV, gapU)
        let open = smoothstep(0.0015, 0.006, edge)
        t.h = t.h * 0.35 + 0.6 * open
        t.color = mix(lin(0.08, 0.06, 0.04), t.color, smoothstep(0.0008, 0.003, edge))
        t.rough = TileNoise.mix(0.9, t.rough, open)
        return t
    }

    /// Rough bark: deep furrows along U between gray-brown plates, cracked across.
    static func bark(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        // Long plates along U between narrow, deep fissures (zero lines of strongly stretched
        // noise), broken across here and there.
        let wv = v + fbm(u, v, 1, 2, octaves: 2, seed: seed) * 0.04
        let n = perlin(u, wv, 1, 11, seed: seed &+ 1) + 0.5 * perlin(u, wv, 3, 22, seed: seed &+ 2)
        let fissure = 1 - smoothstep(0.0, 0.16, abs(n))
        let across = 1 - smoothstep(0.0, 0.1, abs(perlin(u, wv, 10, 4, seed: seed &+ 3)))
        let crack = across * smoothstep(0.2, 0.5, perlin(u, wv, 5, 14, seed: seed &+ 4))
        let plateTop = smoothstep(0.1, 0.7, abs(n))
        let detail = fbm(u, v, 6, 48, octaves: 3, seed: seed &+ 5)
        let height = clamp01((1 - fissure) * (0.5 + plateTop * 0.4 + detail * 0.12) - crack * 0.3)
        var c = mix(lin(0.14, 0.1, 0.075), lin(0.42, 0.36, 0.3), smoothstep(0.15, 0.85, height))
        c = mul(c, 1 + detail * 0.18)
        let lichen = smoothstep(0.62, 0.8, fbm(u, v, 3, 3, octaves: 4, seed: seed &+ 6) * 0.5 + 0.5) * smoothstep(0.5, 0.8, height)
        c = mix(c, lin(0.45, 0.48, 0.36), lichen * 0.4)
        return MeshBuildLookTexel(c, h: height, rough: 0.9 + detail * 0.05)
    }

    /// Steel with patches of flaking rust.
    static func rust(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let big = fbm(u, v, 3, 3, octaves: 5, seed: seed)
        let fine = fbm(u, v, 24, 24, octaves: 3, seed: seed &+ 1)
        let m = smoothstep(-0.2, 0.15, big + fine * 0.25)
        let tone = fbm(u, v, 8, 8, octaves: 3, seed: seed &+ 2)
        let rustColor = mix(lin(0.5, 0.24, 0.09), lin(0.26, 0.12, 0.05), clamp01(tone * 0.6 + 0.5))
        let steel = mul(lin(0.4, 0.39, 0.38), 1 + fine * 0.1)
        let flake = clamp01(TileNoise.ridged(u, v, 12, 12, octaves: 3, seed: seed &+ 3))
        return MeshBuildLookTexel(mix(steel, mul(rustColor, 0.85 + flake * 0.3), m),
                                  h: 0.35 + m * (0.3 + flake * 0.3) + fine * 0.05,
                                  rough: TileNoise.mix(0.42 + fine * 0.05, 0.9, m), metal: 1 - m)
    }

    /// A polished alloy (gold, copper, brass): faint polishing swirls and smudges.
    static func polishedAlloy(_ u: Float, _ v: Float, _ color: RGB, seed: Int) -> MeshBuildLookTexel {
        let smudge = fbm(u, v, 3, 3, octaves: 4, seed: seed)
        let micro = fbm(u, v, 60, 60, octaves: 2, seed: seed &+ 1)
        return MeshBuildLookTexel(mul(color, 1 + smudge * 0.04), h: 0.5 + micro * 0.3 + smudge * 0.2,
                                  rough: 0.2 + max(smudge, 0) * 0.1 + micro * 0.02, metal: 1)
    }

    /// Weathered stone: mottled gray with grains, gentle relief.
    static func stone(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        // Weathered stone: mottled tones, mineral grains, faint veins, rough relief.
        let f = fbm(u, v, 4, 4, octaves: 6, seed: seed)
        let ridge = TileNoise.ridged(u, v, 3, 3, octaves: 6, seed: seed &+ 1)
        let grain = perlin(u, v, 140, 140, seed: seed &+ 2)
        let speck = smoothstep(0.45, 0.7, grain) - smoothstep(0.5, 0.75, -grain) * 0.8
        let vein = 1 - smoothstep(0.0, 0.05, abs(fbm(u, v, 2, 3, octaves: 4, seed: seed &+ 3)))
        let patch = fbm(u, v, 2, 2, octaves: 3, seed: seed &+ 4)
        var c = mix(lin(0.5, 0.49, 0.46), lin(0.6, 0.56, 0.5), clamp01(patch + 0.5))
        c = mul(c, 0.82 + f * 0.28 + speck * 0.14 - vein * 0.12)
        return MeshBuildLookTexel(c, h: ridge * 0.55 + f * 0.3 + grain * 0.05 - vein * 0.15, rough: 0.84 + f * 0.06)
    }

    /// Rounded stones of mixed shades set in dark grit, about 5 x 5 per tile.
    static func cobblestone(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let warpU = u + fbm(u, v, 4, 4, octaves: 2, seed: seed) * 0.02, warpV = v + fbm(u, v, 4, 4, octaves: 2, seed: seed &+ 1) * 0.02
        let c = TileNoise.cells(warpU, warpV, 5, 5, seed: seed &+ 2, jitter: 0.7)
        let edge = c.f2 - c.f1
        let dome = smoothstep(0.02, 0.32, edge)
        let shade = Float(c.id & 0xFF) / 255, hue = Float((c.id >> 8) & 0xFF) / 255
        let detail = fbm(u, v, 24, 24, octaves: 3, seed: seed &+ 3)
        var stoneColor = mix(lin(0.42, 0.41, 0.4), lin(0.56, 0.52, 0.46), hue)
        stoneColor = mul(stoneColor, 0.72 + shade * 0.4 + detail * 0.08)
        let grit = mul(lin(0.2, 0.18, 0.15), 1 + detail * 0.3)
        let stoneMask = smoothstep(0.03, 0.07, edge)
        return MeshBuildLookTexel(mix(grit, stoneColor, stoneMask), h: dome * 0.85 + detail * 0.06,
                                  rough: TileNoise.mix(0.95, 0.78 + detail * 0.05, stoneMask))
    }

    /// Cast concrete: pale gray, faint stains, small air pores.
    static func concrete(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let stain = fbm(u, v, 2, 2, octaves: 5, seed: seed)
        let mid = fbm(u, v, 10, 10, octaves: 3, seed: seed &+ 1)
        let fine = perlin(u, v, 160, 160, seed: seed &+ 2)
        let pores = TileNoise.cells(u, v, 64, 64, seed: seed &+ 3)
        let pore = (1 - smoothstep(0.08, 0.16, pores.f1)) * (TileNoise.hash01(seed, Int(pores.id & 0xFFFF)) < 0.12 ? 1 : 0)
        let c = mul(lin(0.6, 0.59, 0.56), 1 + stain * 0.09 + mid * 0.04 + fine * 0.03 - pore * 0.2)
        return MeshBuildLookTexel(c, h: 0.6 + mid * 0.15 + fine * 0.06 - pore * 0.45, rough: 0.88 + fine * 0.04)
    }

    /// Running-bond brick: 4 bricks along a 0.9 m tile row, 12 rows; varied brick colors,
    /// recessed mortar.
    static func brick(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let rows = 12, columns = 4
        let fv = v * Float(rows)
        let row = Int(fv.rounded(.down))
        let fu = u * Float(columns) + (row & 1 == 1 ? 0.5 : 0)
        let col = Int(fu.rounded(.down))
        let lu = fu - Float(col), lv = fv - Float(row)
        let r = TileNoise.wrap(row, rows), cIndex = TileNoise.wrap(col, columns)
        // Distance to the mortar line in tile units (a brick is 1/4 x 1/12 of the tile).
        let du = min(lu, 1 - lu) / Float(columns), dv = min(lv, 1 - lv) / Float(rows)
        let wobble = fbm(u, v, 16, 16, octaves: 2, seed: seed) * 0.0025
        let d = min(du, dv) + wobble
        let mortarHalf: Float = 0.0065
        let brickMask = smoothstep(mortarHalf, mortarHalf + 0.004, d)
        let pick = TileNoise.hash01(seed, cIndex, r, 4), tone = TileNoise.hash01(seed, cIndex, r, 5)
        var brickColor = mix(lin(0.6, 0.27, 0.17), lin(0.45, 0.19, 0.12), tone)
        if pick < 0.12 { brickColor = lin(0.33, 0.17, 0.12) }
        if pick > 0.9 { brickColor = lin(0.66, 0.38, 0.25) }
        let detail = fbm(u, v, 40, 40, octaves: 3, seed: seed &+ 1)
        let blotch = fbm(u, v, 8, 8, octaves: 2, seed: seed &+ 2)
        brickColor = mul(brickColor, 1 + detail * 0.12 + blotch * 0.08)
        let mortar = mul(lin(0.6, 0.58, 0.54), 1 + detail * 0.1)
        let rounded = smoothstep(mortarHalf, mortarHalf + 0.01, d)
        return MeshBuildLookTexel(mix(mortar, brickColor, brickMask), h: 0.25 + rounded * 0.65 + detail * 0.05,
                                  rough: TileNoise.mix(0.95, 0.82 + detail * 0.04, brickMask))
    }

    /// Plain weave: threads along U and V passing over and under, 80 per tile.
    static func fabric(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let threads = 80
        let tu = u * Float(threads), tv = v * Float(threads)
        let i = Int(tu.rounded(.down)), j = Int(tv.rounded(.down))
        let wx = tu - Float(i), wy = tv - Float(j)
        let warpOnTop = (i + j) & 1 == 0
        let warp = sinf(.pi * wy) * (warpOnTop ? 1 : 0.55)   // thread along U: round across V
        let weft = sinf(.pi * wx) * (warpOnTop ? 0.55 : 1)
        let h = max(warp, weft)
        let fuzz = fbm(u, v, 128, 128, octaves: 2, seed: seed)
        let slub = fbm(u, v, 2, 40, octaves: 2, seed: seed &+ 1) * 0.06 + fbm(u, v, 40, 2, octaves: 2, seed: seed &+ 2) * 0.06
        let c = mul(lin(0.32, 0.38, 0.52), 0.8 + h * 0.3 + fuzz * 0.04 + slub)
        return MeshBuildLookTexel(c, h: h * 0.9 + fuzz * 0.05, rough: 0.9 + fuzz * 0.04)
    }

    /// Pebbled leather grain with creases.
    static func leather(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let wu = u + fbm(u, v, 6, 6, octaves: 2, seed: seed) * 0.008, wv = v + fbm(u, v, 6, 6, octaves: 2, seed: seed &+ 1) * 0.008
        let c = TileNoise.cells(wu, wv, 36, 36, seed: seed &+ 2)
        let crease = smoothstep(0.0, 0.22, c.f2 - c.f1)
        let macro = fbm(u, v, 3, 3, octaves: 4, seed: seed &+ 3)
        let color = mul(lin(0.42, 0.24, 0.13), 0.8 + crease * 0.25 + macro * 0.12)
        return MeshBuildLookTexel(color, h: crease * 0.7 + macro * 0.15, rough: 0.62 - crease * 0.1 + max(-macro, 0) * 0.1)
    }

    /// Packed earth: brown with damp patches, small pebbles.
    static func dirt(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        let f = fbm(u, v, 3, 3, octaves: 6, seed: seed)
        let crumbs = fbm(u, v, 48, 48, octaves: 2, seed: seed &+ 3)
        let damp = smoothstep(0.1, 0.5, fbm(u, v, 2, 2, octaves: 3, seed: seed &+ 1))
        // Scattered irregular pebbles of different sizes, in clusters.
        let wu = u + fbm(u, v, 32, 32, octaves: 2, seed: seed &+ 5) * 0.008
        let wv = v + fbm(u, v, 32, 32, octaves: 2, seed: seed &+ 6) * 0.008
        let p = TileNoise.cells(wu, wv, 30, 30, seed: seed &+ 2)
        let pick = TileNoise.hash01(seed, Int(p.id & 0xFFFF), 7)
        let cluster = smoothstep(0.35, 0.75, fbm(u, v, 3, 3, octaves: 2, seed: seed &+ 4) * 0.5 + 0.5)
        let size = 0.15 + 0.3 * TileNoise.hash01(seed, Int(p.id >> 16), 8)
        let pebble = pick < cluster * 0.55 ? 1 - smoothstep(size * 0.55, size, p.f1) : 0
        let tint = Float((p.id >> 8) & 0xFF) / 255
        var c = mul(lin(0.4, 0.31, 0.22), 0.8 + f * 0.3 + crumbs * 0.12)
        c = mul(c, 1 - damp * 0.3)
        c = mix(c, mul(lin(0.5, 0.46, 0.4), 0.7 + tint * 0.45 + crumbs * 0.1), pebble)
        return MeshBuildLookTexel(c, h: 0.4 + f * 0.3 + crumbs * 0.08 + pebble * 0.3, rough: 0.95 - pebble * 0.12 - damp * 0.15)
    }

    /// Short grass seen from above: many thin blades in a few directions, drier patches.
    static func grass(_ u: Float, _ v: Float, seed: Int) -> MeshBuildLookTexel {
        var blade: Float = 0
        // Sheared, stretched noise: whole-tile shears keep it tileable.
        forEachIndex(0..<4) { k in
            let su = u + (k == 1 ? v : k == 2 ? -v : 0), sv = v + (k == 3 ? u : 0)
            let n = perlin(su, sv, k & 1 == 0 ? 90 : 12, k & 1 == 0 ? 12 : 90, seed: seed &+ k)
            blade = max(blade, 1 - smoothstep(0.0, 0.3, abs(n)))
        }
        let dry = smoothstep(0.15, 0.6, fbm(u, v, 3, 3, octaves: 4, seed: seed &+ 9))
        let clump = fbm(u, v, 12, 12, octaves: 2, seed: seed &+ 10)
        var c = mix(lin(0.1, 0.19, 0.05), lin(0.3, 0.46, 0.14), blade * 0.8 + clump * 0.1)
        c = mix(c, lin(0.48, 0.45, 0.22), dry * 0.55 * blade)
        return MeshBuildLookTexel(c, h: blade * 0.6 + clump * 0.2 + 0.2, rough: 0.82 + (1 - blade) * 0.1)
    }
}
