import Foundation

/// Where an emitter spawns particles, in its entity's local space.
public enum ParticleEmitterShape: String, Codable, Sendable, CaseIterable {
    /// The entity's origin.
    case point
    /// Uniformly inside a sphere of radius `shapeSize.x`.
    case sphere
    /// Uniformly inside a box of half extents `shapeSize`.
    case box
    /// A disc in the local XZ plane of radius `shapeSize.x` and thickness `shapeSize.y`, optionally
    /// gathered into `spiralArms` arms.
    case disc
}

/// How particles combine with the scene (see `BlendMode`).
public enum ParticleBlend: String, Codable, Sendable, CaseIterable {
    /// Color × alpha is added: fire, sparks, magic. Order-independent up to rounding, so the
    /// stable slot order is enough.
    case additive
    /// Straight alpha over the scene: smoke, dust. Sorted back to front on the GPU, which
    /// limits the emitter to `ParticleEmitter.maxSortedCapacity` particles.
    case alpha

    var blendMode: BlendMode { self == .additive ? .additive : .alpha }
}

/// A color at a point of a particle's life (0 at birth, 1 at death).
public struct ParticleColorKey: Codable, Sendable, Equatable {
    public var time: Float
    /// Linear RGBA; alpha fades the particle out.
    public var color: Vec4

    public init(_ time: Float, _ color: Vec4) {
        self.time = time
        self.color = color
    }
}

/// A value at a point of a particle's life.
public struct ParticleCurveKey: Codable, Sendable, Equatable {
    public var time: Float
    public var value: Float

    public init(_ time: Float, _ value: Float) {
        self.time = time
        self.value = value
    }
}

/// A burst of `count` particles at `time` seconds into the emitter's life, repeated every
/// `interval` seconds `cycles` times (0: forever) when `interval` is positive.
public struct ParticleBurst: Codable, Sendable, Equatable {
    public var time: Float
    public var count: Int
    public var interval: Float
    public var cycles: Int

    public init(time: Float = 0, count: Int, interval: Float = 0, cycles: Int = 1) {
        self.time = time
        self.count = count
        self.interval = interval
        self.cycles = cycles
    }
}

/// GPU particles emitted from the entity's `GlobalTransform`, simulated in compute and drawn
/// by `SceneRenderer` (see `ParticleSystem`). Plain data: change any field at runtime; a new
/// `capacity`, `blend` or `seed` restarts the emitter.
///
/// Particles live in world space once spawned (moving the entity moves only the spawn point).
/// Speeds are in units per second, angles in radians.
public struct ParticleEmitter: Component, Codable, Equatable, Sendable {
    public static let componentName = "ParticleEmitter"
    /// Most particles an alpha-blended (sorted) emitter can hold.
    public static let maxSortedCapacity = 2048
    /// Most particles any emitter can hold.
    public static let maxCapacity = 1 << 20

    public static var fieldHints: [String: FieldHints] {
        ["capacity": FieldHints(range: 1...Double(maxCapacity), step: 256, tooltip: "Most live particles; spawning wraps around and replaces the oldest"),
         "rate": FieldHints(range: 0...1_000_000, step: 1, tooltip: "Particles per second"),
         "prewarm": FieldHints(range: 0...60, step: 0.1, tooltip: "Seconds simulated at once when the emitter starts"),
         "spread": FieldHints(range: 0...3.1416, step: 0.01, tooltip: "Half-angle of the emission cone around direction, radians"),
         "drag": FieldHints(range: 0...20, step: 0.01, tooltip: "Velocity damping per second"),
         "bounce": FieldHints(range: 0...1, step: 0.01), "friction": FieldHints(range: 0...1, step: 0.01),
         "stretch": FieldHints(range: 0...2, step: 0.01, tooltip: "Elongates particles along their velocity (seconds)"),
         "intensity": FieldHints(range: 0...1000, step: 0.1, tooltip: "Multiplies the color: HDR glow with bloom"),
         "brightnessVariation": FieldHints(range: 0...1, step: 0.01, tooltip: "Random per-particle dimming")]
    }

    public var isEmitting: Bool
    /// Most live particles (rounded up to a multiple of 256; at most `maxSortedCapacity` when
    /// `blend` is `.alpha`). New particles reuse the oldest slots once it is full.
    public var capacity: Int
    /// Particles per second while `isEmitting`.
    public var rate: Float
    public var bursts: [ParticleBurst]
    /// Seconds simulated at once when the emitter first runs, so it starts in its steady state.
    public var prewarm: Float
    /// Random lifetime range in seconds (x min, y max).
    public var lifetime: Vec2
    public var shape: ParticleEmitterShape
    public var shapeSize: Vec3
    /// Local emission direction, and the half-angle of the cone around it.
    public var direction: Vec3
    public var spread: Float
    /// Random initial speed range (x min, y max).
    public var speed: Vec2
    /// World-space acceleration.
    public var gravity: Vec3
    public var drag: Float
    /// Strength (acceleration) and spatial frequency of a swirling noise field.
    public var turbulence: Float
    public var turbulenceFrequency: Float
    /// Acceleration toward the entity's position per unit of distance (a spring: galaxies,
    /// vortices). Everything orbiting it has the same period, 2π / sqrt(attraction).
    public var attraction: Float
    /// Initial speed around the local Y axis: × the circular-orbit speed (sqrt(attraction) × radius)
    /// when `attraction` is set, else units per second.
    public var orbit: Float
    /// `.disc` only: spiral arms (0: a plain disc), their twist in radians per unit of radius and their width in radians.
    public var spiralArms: Int
    public var spiralTwist: Float
    public var armWidth: Float
    /// Random size range (half-width of the quad), × `sizeOverLife`.
    public var size: Vec2
    /// Random spin range in radians per second (±).
    public var spin: Float
    /// Size multiplier over life: up to 4 keys, piecewise linear.
    public var sizeOverLife: [ParticleCurveKey]
    /// Color over life: up to 4 keys, piecewise linear.
    public var color: [ParticleColorKey]
    /// HDR multiplier of the color.
    public var intensity: Float
    /// Each particle's color is dimmed by a random factor down to 1 − this.
    public var brightnessVariation: Float
    public var blend: ParticleBlend
    /// Elongates particles along their screen-space velocity: length × (1 + stretch × speed).
    public var stretch: Float
    /// Bounce off the plane y = `groundHeight`.
    public var collidesWithGround: Bool
    public var groundHeight: Float
    /// Fraction of the normal speed kept on impact.
    public var bounce: Float
    /// Fraction of the tangential speed lost on impact.
    public var friction: Float
    /// Random seed: emitters with the same seed and settings produce the same particles.
    public var seed: UInt32

    public init(capacity: Int = 4096, rate: Float = 200, bursts: [ParticleBurst] = [], prewarm: Float = 0,
                lifetime: Vec2 = Vec2(1, 2), shape: ParticleEmitterShape = .point, shapeSize: Vec3 = Vec3(0.5, 0.5, 0.5),
                direction: Vec3 = Vec3(0, 1, 0), spread: Float = 0.4, speed: Vec2 = Vec2(1, 2),
                gravity: Vec3 = .zero, drag: Float = 0, turbulence: Float = 0, turbulenceFrequency: Float = 1,
                attraction: Float = 0, orbit: Float = 0, spiralArms: Int = 0, spiralTwist: Float = 0, armWidth: Float = 0.5,
                size: Vec2 = Vec2(0.1, 0.1), spin: Float = 0,
                sizeOverLife: [ParticleCurveKey] = [ParticleCurveKey(0, 1)],
                color: [ParticleColorKey] = [ParticleColorKey(0, Vec4(1, 1, 1, 1)), ParticleColorKey(1, Vec4(1, 1, 1, 0))],
                intensity: Float = 1, brightnessVariation: Float = 0, blend: ParticleBlend = .additive, stretch: Float = 0,
                collidesWithGround: Bool = false, groundHeight: Float = 0, bounce: Float = 0.4, friction: Float = 0.2,
                seed: UInt32 = 1, isEmitting: Bool = true) {
        self.isEmitting = isEmitting
        self.capacity = capacity
        self.rate = rate
        self.bursts = bursts
        self.prewarm = prewarm
        self.lifetime = lifetime
        self.shape = shape
        self.shapeSize = shapeSize
        self.direction = direction
        self.spread = spread
        self.speed = speed
        self.gravity = gravity
        self.drag = drag
        self.turbulence = turbulence
        self.turbulenceFrequency = turbulenceFrequency
        self.attraction = attraction
        self.orbit = orbit
        self.spiralArms = spiralArms
        self.spiralTwist = spiralTwist
        self.armWidth = armWidth
        self.size = size
        self.spin = spin
        self.sizeOverLife = sizeOverLife
        self.color = color
        self.intensity = intensity
        self.brightnessVariation = brightnessVariation
        self.blend = blend
        self.stretch = stretch
        self.collidesWithGround = collidesWithGround
        self.groundHeight = groundHeight
        self.bounce = bounce
        self.friction = friction
        self.seed = seed
    }

    /// Missing fields take their defaults, so files from older versions keep loading.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ParticleEmitter()
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) throws -> T { try c.decodeIfPresent(T.self, forKey: key) ?? fallback }
        isEmitting = try value(.isEmitting, d.isEmitting)
        capacity = try value(.capacity, d.capacity)
        rate = try value(.rate, d.rate)
        bursts = try value(.bursts, d.bursts)
        prewarm = try value(.prewarm, d.prewarm)
        lifetime = try value(.lifetime, d.lifetime)
        shape = try value(.shape, d.shape)
        shapeSize = try value(.shapeSize, d.shapeSize)
        direction = try value(.direction, d.direction)
        spread = try value(.spread, d.spread)
        speed = try value(.speed, d.speed)
        gravity = try value(.gravity, d.gravity)
        drag = try value(.drag, d.drag)
        turbulence = try value(.turbulence, d.turbulence)
        turbulenceFrequency = try value(.turbulenceFrequency, d.turbulenceFrequency)
        attraction = try value(.attraction, d.attraction)
        orbit = try value(.orbit, d.orbit)
        spiralArms = try value(.spiralArms, d.spiralArms)
        spiralTwist = try value(.spiralTwist, d.spiralTwist)
        armWidth = try value(.armWidth, d.armWidth)
        size = try value(.size, d.size)
        spin = try value(.spin, d.spin)
        sizeOverLife = try value(.sizeOverLife, d.sizeOverLife)
        color = try value(.color, d.color)
        intensity = try value(.intensity, d.intensity)
        brightnessVariation = try value(.brightnessVariation, d.brightnessVariation)
        blend = try value(.blend, d.blend)
        stretch = try value(.stretch, d.stretch)
        collidesWithGround = try value(.collidesWithGround, d.collidesWithGround)
        groundHeight = try value(.groundHeight, d.groundHeight)
        bounce = try value(.bounce, d.bounce)
        friction = try value(.friction, d.friction)
        seed = try value(.seed, d.seed)
    }

    /// `capacity` as allocated: a multiple of the 256-slot workgroup, within the blend mode's limit.
    public var effectiveCapacity: Int {
        let limit = blend == .alpha ? Self.maxSortedCapacity : Self.maxCapacity
        return min(max((capacity + 255) / 256 * 256, 256), limit)
    }
}

extension ParticleSystem {
    /// Registers `ParticleEmitter` with `ComponentRegistry` (needed before loading scene files
    /// that use it into a world that hasn't stored one yet).
    public static func registerComponents() {
        ComponentRegistry.register(ParticleEmitter.self)
    }
}

/// When an emitter spawns, on the CPU: a deterministic function of the steps it is advanced by
/// (rate accumulation, bursts and requested bursts). The GPU only learns how many particles each
/// step spawns, into which ring slots, and their spawn indices (which seed their random numbers).
public struct ParticleSpawnSchedule: Sendable, Equatable {
    /// Seconds the emitter has run.
    public private(set) var time: Double = 0
    /// Fractional particles carried to the next step.
    public private(set) var carry: Double = 0
    /// Particles spawned so far: the next spawn index.
    public private(set) var spawned: UInt64 = 0
    /// Particles to add at the next step (`ParticleSystem.burst`).
    public var pendingBurst = 0

    public init() {}

    /// One step of `dt` seconds: how many particles it spawns (`emitting` gates the rate and
    /// timed bursts, not requested ones).
    public mutating func step(dt: Double, rate: Float, bursts: [ParticleBurst], emitting: Bool) -> Int {
        let start = time
        time += dt
        var count = pendingBurst
        pendingBurst = 0
        guard emitting else {
            carry = 0
            spawned += UInt64(count)
            return count
        }
        let exact = carry + Double(max(rate, 0)) * dt
        let whole = exact.rounded(.down)
        carry = exact - whole
        count += Int(whole)
        for burst in bursts { count += burst.firings(after: start, upTo: time) * max(burst.count, 0) }
        spawned += UInt64(count)
        return count
    }
}

extension ParticleBurst {
    /// How many times the burst fires in [start, end): at time + k × interval for k in 0..<cycles
    /// (every k when cycles is 0; only k = 0 without an interval).
    func firings(after start: Double, upTo end: Double) -> Int {
        let first = Double(time)
        guard interval > 0 else { return start <= first && first < end ? 1 : 0 }
        let step = Double(interval)
        let low = max(0, Int(((start - first) / step).rounded(.up)))
        var high = Int(((end - first) / step).rounded(.up)) - 1
        if cycles > 0 { high = min(high, cycles - 1) }
        return max(0, high - low + 1)
    }
}
