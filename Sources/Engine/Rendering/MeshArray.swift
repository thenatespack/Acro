/// Draws its entity's `MeshRenderer` mesh as a grid of copies, all from one entity: the copies are
/// expanded into `RenderItem`s when the frame is gathered (no entities are created), so a facade's
/// hundreds of window quads cost one entity, one `GlobalTransform` and one `MeshArray`.
///
/// Copy `(x, y, z)` sits at `(x, y, z) * spacing` along the entity's rotated axes, in world units,
/// starting at the entity origin, or centered on it with `centered`; the whole grid moves and
/// rotates with the entity, while the entity's scale sizes each copy and not the spacing (so a
/// quad scaled to 0.8 with `spacing` 1.5 leaves a 0.7 gap). Every copy uses the renderer's mesh, material, `castsShadows`, `receivesShadows`
/// and `opacity`, and a tint derived from `MeshRenderer.tint`, so all of them share a batch (one
/// instanced draw per pass) unless the material or opacity makes them transparent (then they are
/// sorted back to front like any transparent item). Each copy is culled on its own bounds.
///
/// Variation is deterministic: a function of `seed` and the copy's index (`x + countX * (y + countY * z)`),
/// so it is the same every frame, on both backends and across runs. `tintVariation` darkens each
/// color channel of a copy by up to that fraction (independent channels, so hue varies too);
/// `offFraction` of the copies are "off": hidden, or drawn with the tint multiplied by `offTint`.
/// Tint changes the base color only; a material's emissive light is not affected by it, so for
/// lit versus unlit windows use `offFraction` with `hidden` (the facade's own texture then shows
/// where a copy is missing) or an emissive texture on the wall.
///
/// Limits: at most `maxInstances` copies per entity; picking and selection outlines treat the entity
/// as its single `MeshRenderer` mesh at the grid origin.
public struct MeshArray: Component, Codable, Equatable, Sendable {
    public static let componentName = "MeshArray"
    public static var fieldHints: [String: FieldHints] {
        ["countX": FieldHints(range: 1...4096, step: 1), "countY": FieldHints(range: 1...4096, step: 1),
         "countZ": FieldHints(range: 1...4096, step: 1),
         "spacing": FieldHints(tooltip: "Distance between copies along the entity's local axes"),
         "centered": FieldHints(tooltip: "Center the grid on the entity instead of starting at its origin"),
         "seed": FieldHints(tooltip: "Seeds the random tint and off choices"),
         "tintVariation": FieldHints(range: 0...1, step: 0.01, tooltip: "Each copy's color channels are darkened by up to this fraction"),
         "offFraction": FieldHints(range: 0...1, step: 0.01, tooltip: "Fraction of copies that are off"),
         "offMode": FieldHints(tooltip: "hidden: off copies are not drawn. tinted: they are drawn with the tint times offTint"),
         "offTint": FieldHints(color: true, tooltip: "Tint multiplier of off copies (offMode tinted)")]
    }

    /// What happens to the copies chosen by `offFraction`.
    public enum OffMode: String, Codable, CaseIterable, Sendable {
        case hidden
        case tinted
    }

    /// The most copies one entity expands to (the counts are scaled down to stay under it).
    public static let maxInstances = 1 << 20

    public var countX: Int
    public var countY: Int
    public var countZ: Int
    public var spacing: Vec3
    public var centered: Bool
    public var seed: Int
    public var tintVariation: Float
    public var offFraction: Float
    public var offMode: OffMode
    public var offTint: Vec3

    public init(countX: Int = 1, countY: Int = 1, countZ: Int = 1, spacing: Vec3 = Vec3(1, 1, 1), centered: Bool = false,
                seed: Int = 1, tintVariation: Float = 0, offFraction: Float = 0, offMode: OffMode = .hidden,
                offTint: Vec3 = Vec3(0.1, 0.1, 0.1)) {
        self.countX = countX
        self.countY = countY
        self.countZ = countZ
        self.spacing = spacing
        self.centered = centered
        self.seed = seed
        self.tintVariation = tintVariation
        self.offFraction = offFraction
        self.offMode = offMode
        self.offTint = offTint
    }

    /// Every field is optional, so files written with fewer fields take defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = MeshArray()
        self.init(countX: try c.decodeIfPresent(Int.self, forKey: .countX) ?? d.countX,
                  countY: try c.decodeIfPresent(Int.self, forKey: .countY) ?? d.countY,
                  countZ: try c.decodeIfPresent(Int.self, forKey: .countZ) ?? d.countZ,
                  spacing: try c.decodeIfPresent(Vec3.self, forKey: .spacing) ?? d.spacing,
                  centered: try c.decodeIfPresent(Bool.self, forKey: .centered) ?? d.centered,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  tintVariation: try c.decodeIfPresent(Float.self, forKey: .tintVariation) ?? d.tintVariation,
                  offFraction: try c.decodeIfPresent(Float.self, forKey: .offFraction) ?? d.offFraction,
                  offMode: try c.decodeIfPresent(OffMode.self, forKey: .offMode) ?? d.offMode,
                  offTint: try c.decodeIfPresent(Vec3.self, forKey: .offTint) ?? d.offTint)
    }

    /// The grid dimensions after clamping to at least 1 and scaling down to `maxInstances`.
    var dimensions: (x: Int, y: Int, z: Int) {
        var x = max(countX, 0), y = max(countY, 0), z = max(countZ, 0)
        while x * y * z > Self.maxInstances {
            if x >= y && x >= z { x = x * 3 / 4 } else if y >= z { y = y * 3 / 4 } else { z = z * 3 / 4 }
        }
        return (x, y, z)
    }

    /// How many copies are expanded (before the off ones are dropped).
    public var instanceCount: Int {
        let d = dimensions
        return d.x * d.y * d.z
    }

    /// Whether copy `index` is off.
    func isOff(_ index: Int) -> Bool {
        offFraction > 0 && Hash32.unit(seed, index, 1) < offFraction
    }

    /// The tint multiplier of copy `index`: `variation` darkening and, for an off copy in
    /// `.tinted` mode, `offTint`.
    func tintFactor(_ index: Int) -> Vec3 {
        var factor = Vec3(1, 1, 1)
        if tintVariation > 0 {
            factor = Vec3(1 - tintVariation * Hash32.unit(seed, index, 2),
                          1 - tintVariation * Hash32.unit(seed, index, 3),
                          1 - tintVariation * Hash32.unit(seed, index, 4))
        }
        if offMode == .tinted, isOff(index) { factor = factor * offTint }
        return factor
    }

    /// `model` moved by `offset` along its own axes, ignoring its scale.
    static func offset(_ model: Mat4, by offset: Vec3) -> Mat4 {
        let x = normalize(Vec3(model.c0.x, model.c0.y, model.c0.z)), y = normalize(Vec3(model.c1.x, model.c1.y, model.c1.z)),
            z = normalize(Vec3(model.c2.x, model.c2.y, model.c2.z))
        var result = model
        result.c3 += Vec4(x * offset.x + y * offset.y + z * offset.z, 0)
        return result
    }

    /// The copies' offsets along the entity's axes paired with their tint factors, in index
    /// order, without the hidden ones.
    func placements() -> [(offset: Vec3, tint: Vec3)] {
        let d = dimensions
        let origin = centered ? Vec3(Float(d.x - 1), Float(d.y - 1), Float(d.z - 1)) * spacing * -0.5 : .zero
        var result: [(offset: Vec3, tint: Vec3)] = []
        result.reserveCapacity(d.x * d.y * d.z)
        var index = 0
        for z in 0..<d.z {
            for y in 0..<d.y {
                for x in 0..<d.x {
                    defer { index += 1 }
                    if offMode == .hidden, isOff(index) { continue }
                    result.append((origin + Vec3(Float(x), Float(y), Float(z)) * spacing, tintFactor(index)))
                }
            }
        }
        return result
    }
}

/// A small integer hash for deterministic variation (integer-only, so identical everywhere).
enum Hash32 {
    static func hash(_ a: Int, _ b: Int, _ c: Int, _ d: Int = 0) -> UInt32 {
        var x = UInt32(truncatingIfNeeded: a) &* 0x9E37_79B1
        x ^= UInt32(truncatingIfNeeded: b) &* 0x85EB_CA6B
        x ^= UInt32(truncatingIfNeeded: c) &* 0xC2B2_AE35
        x ^= UInt32(truncatingIfNeeded: d) &* 0x27D4_EB2F
        x ^= x >> 16
        x = x &* 0x7FEB_352D
        x ^= x >> 15
        x = x &* 0x846C_A68B
        x ^= x >> 16
        return x
    }

    /// In [0, 1).
    static func unit(_ a: Int, _ b: Int, _ c: Int, _ d: Int = 0) -> Float {
        Float(hash(a, b, c, d) >> 8) / 16_777_216
    }
}
