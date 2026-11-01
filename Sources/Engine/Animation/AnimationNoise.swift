import Foundation

/// Deterministic hash noise for the data-driven animation components (`FieldAnimator`,
/// `LightFlicker`, `CameraPath`): pure functions of (seed, position), so the same time always
/// gives the same value, whatever the frame rate.
enum AnimationNoise {
    /// Seed mixed from a component's `seed` and the entity's slot, so identical components on
    /// different entities decorrelate, and the same scene always gives the same result.
    static func seed(_ seed: Int, entity: Entity) -> UInt64 {
        mix(UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(entity.index) &* 0xBF58_476D_1CE4_E5B9)
    }

    static func mix(_ x: UInt64) -> UInt64 {
        var z = x &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1) for lattice cell `i`.
    static func hash(_ seed: UInt64, _ i: Int) -> Float {
        Float(mix(seed ^ UInt64(bitPattern: Int64(i)) &* 0xD6E8_FEB8_6659_FD93) >> 40) / Float(1 << 24)
    }

    /// Smooth value noise in [-1, 1] (cubic-eased between random lattice values, one per unit of `x`).
    static func value(_ x: Float, seed: UInt64) -> Float {
        let cell = x.rounded(.down)
        let f = x - cell
        let i = Int(cell)
        let u = f * f * (3 - 2 * f)
        let a = hash(seed, i), b = hash(seed, i + 1)
        return (a + (b - a) * u) * 2 - 1
    }

    /// Two octaves of `value`, still within [-1, 1].
    static func fractal(_ x: Float, seed: UInt64) -> Float {
        (value(x, seed: seed) * 2 + value(x * 2.13 + 7.3, seed: seed ^ 0x5555)) / 3
    }
}
