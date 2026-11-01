import Foundation

/// How a `LightFlicker` modulates its light.
public enum FlickerStyle: String, Codable, CaseIterable, Sendable {
    /// Candle / fire: smooth random wander between min and max.
    case smooth
    /// Neon tube: mostly at max with a faint buzz, and sudden short dropouts down to min.
    case neonBuzz
    /// Broken fixture: random on / off cells (`speed` per second); a `dropout` share of cells go to min, a few more are half-lit.
    case strobe
}

/// Modulates the intensity of the entity's `PointLight` and / or `SpotLight`: candles, neon,
/// failing bulbs. Intensity = the light's base intensity (remembered when the flicker first
/// runs, so editing the light before Play sets it) times a factor between `minIntensity` and
/// `maxIntensity`. Deterministic: a function of the animator's clock, `seed` and the entity.
/// Runs from `World.addBuiltinAnimationSystems()`.
public struct LightFlicker: Component, Equatable, Sendable {
    public static let componentName = "LightFlicker"
    public static var fieldHints: [String: FieldHints] {
        ["minIntensity": FieldHints(range: 0...4, step: 0.01, tooltip: "Lowest intensity, as a multiple of the light's own intensity"),
         "maxIntensity": FieldHints(range: 0...4, step: 0.01, tooltip: "Highest intensity, as a multiple of the light's own intensity"),
         "speed": FieldHints(range: 0...100, step: 0.1, tooltip: "Changes per second (smooth: noise cycles per second)"),
         "dropout": FieldHints(range: 0...1, step: 0.01, tooltip: "Neon / strobe: chance a cell is a dropout")]
    }

    public var style: FlickerStyle
    public var minIntensity: Float
    public var maxIntensity: Float
    public var speed: Float
    /// Neon buzz and strobe: the chance that a time cell is dark.
    public var dropout: Float
    public var seed: Int
    public var enabled: Bool

    // Runtime state, not coded.
    var time: Double = 0
    var baseIntensity: Float?

    public init(style: FlickerStyle = .smooth, minIntensity: Float = 0.4, maxIntensity: Float = 1, speed: Float = 6,
                dropout: Float = 0.15, seed: Int = 0, enabled: Bool = true) {
        self.style = style
        self.minIntensity = minIntensity
        self.maxIntensity = maxIntensity
        self.speed = speed
        self.dropout = dropout
        self.seed = seed
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey { case style, minIntensity, maxIntensity, speed, dropout, seed, enabled }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = LightFlicker()
        self.init(style: try c.decodeIfPresent(FlickerStyle.self, forKey: .style) ?? d.style,
                  minIntensity: try c.decodeIfPresent(Float.self, forKey: .minIntensity) ?? d.minIntensity,
                  maxIntensity: try c.decodeIfPresent(Float.self, forKey: .maxIntensity) ?? d.maxIntensity,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? d.speed,
                  dropout: try c.decodeIfPresent(Float.self, forKey: .dropout) ?? d.dropout,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? d.enabled)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(style, forKey: .style)
        try c.encode(minIntensity, forKey: .minIntensity)
        try c.encode(maxIntensity, forKey: .maxIntensity)
        try c.encode(speed, forKey: .speed)
        try c.encode(dropout, forKey: .dropout)
        try c.encode(seed, forKey: .seed)
        try c.encode(enabled, forKey: .enabled)
    }

    /// The brightness factor in 0...1 (0 = `minIntensity`, 1 = `maxIntensity`) at `time` seconds.
    public func level(at time: Float, noiseSeed: UInt64) -> Float {
        let x = time * speed
        switch style {
        case .smooth:
            return min(max(0.5 + 0.5 * AnimationNoise.fractal(x * 0.5, seed: noiseSeed) * 1.4, 0), 1)
        case .neonBuzz:
            // Dropouts: each half-unit cell is dark for its first part with chance `dropout`.
            let cell = x.rounded(.down)
            let local = x - cell
            let buzz = 0.93 + 0.07 * AnimationNoise.value(x * 9, seed: noiseSeed ^ 0xB22)
            if AnimationNoise.hash(noiseSeed, Int(cell)) < dropout {
                let length = 0.15 + 0.35 * AnimationNoise.hash(noiseSeed ^ 0xD0, Int(cell))
                if local < length { return local < length * 0.35 ? 0 : 0.25 }
            }
            return buzz
        case .strobe:
            let cell = Int(x.rounded(.down))
            let h = AnimationNoise.hash(noiseSeed, cell)
            if h < dropout { return 0 }
            return h < dropout + 0.15 ? 0.5 : 1
        }
    }
}

extension World {
    /// Advances every `LightFlicker`; `addBuiltinAnimationSystems()` registers this.
    @MainActor func runLightFlickers() {
        guard count(of: LightFlicker.self) > 0 else { return }
        let dt = Double(time.delta)
        var entities: [Entity] = []
        query(LightFlicker.self) { entity, _ in entities.append(entity) }
        for entity in entities {
            modify(LightFlicker.self, for: entity) { flicker in
                guard flicker.enabled else { return }
                flicker.time += dt
                if flicker.baseIntensity == nil {
                    flicker.baseIntensity = get(PointLight.self, for: entity)?.intensity ?? get(SpotLight.self, for: entity)?.intensity
                }
                guard let base = flicker.baseIntensity else { return }
                let f = flicker.level(at: Float(flicker.time), noiseSeed: AnimationNoise.seed(flicker.seed, entity: entity))
                let intensity = base * (flicker.minIntensity + (flicker.maxIntensity - flicker.minIntensity) * f)
                modify(PointLight.self, for: entity) { $0.intensity = intensity }
                modify(SpotLight.self, for: entity) { $0.intensity = intensity }
            }
        }
    }
}
