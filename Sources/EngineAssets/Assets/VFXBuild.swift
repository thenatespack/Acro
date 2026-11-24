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

// A visual effect built from stacked particle emitters: the contents of a `.vfx` file (JSON,
// every key optional). `VFXBuildImporter` turns it into a prefab with one `ParticleEmitter`
// child per emitter, so an effect is placed, spawned and reimported like any model.
//
// ```json
// {
//   "duration": 3,
//   "emitters": [
//     {"name": "Flames", "rate": 700, "lifetime": [0.5, 1.1], "shape": "sphere", "gravity": [0, 2.2, 0],
//      "color": [{"time": 0, "color": [1, 0.8, 0.4, 0.9]}, {"time": 1, "color": [0.2, 0.03, 0, 0]}]},
//     {"name": "Smoke", "delay": 0.3, "position": [0, 1.2, 0], "blend": "alpha", "rate": 40,
//      "texture": "Textures/puff.png", "atlasColumns": 4, "atlasRows": 4},
//     {"name": "Sparks", "rate": 0, "subEmitters": [{"trigger": "death", "emitter": "Pops", "count": 6}]},
//     {"name": "Pops"}
//   ]
// }
// ```
//
// Textures: `texture` names an image, a `.proctex` or a `.sprite` by path relative to `Assets/`
// (or "asset:<id>"). An image or `.proctex` is a flipbook of `atlasColumns` x `atlasRows` cells; a
// `.sprite`'s frames (all of them, or the tag `spriteTag`) are baked by the importer into a
// texture of the effect, one frame per cell in play order, so the grid comes from the sprite.
//
// Sub-emitters: `subEmitters` link an emitter to others of the same effect by name. Each of its
// particles spawns `count` of the target's particles when it is born, dies or collides; the
// target then emits only that way (its own rate, bursts, delay and position are ignored).

/// One emitter of an effect: a curated view of `ParticleEmitter` plus its placement and `delay`.
/// Colors are linear RGBA; angles of `rotation` are degrees (the others follow `ParticleEmitter`,
/// radians for `spread`).
public struct VFXEmitter: Codable, Equatable, Sendable {
    public var name = "Emitter"
    /// Relative to the effect's origin, meters.
    public var position = Vec3.zero
    /// Euler degrees: turns the emission direction and shape.
    public var rotation = Vec3.zero
    /// Seconds after the effect starts before this emitter begins (rate and bursts).
    public var delay: Float = 0
    public var rate: Float = 100
    public var bursts: [ParticleBurst] = []
    public var capacity = 2048
    /// Seconds simulated at once at the start, so a continuous effect starts in its steady state.
    public var prewarm: Float = 0
    public var lifetime = Vec2(1, 2)
    public var shape = ParticleEmitterShape.point
    public var shapeSize = Vec3(0.5, 0.5, 0.5)
    public var direction = Vec3(0, 1, 0)
    public var spread: Float = 0.4
    public var speed = Vec2(1, 2)
    public var gravity = Vec3.zero
    public var drag: Float = 0
    public var turbulence: Float = 0
    public var turbulenceFrequency: Float = 1
    public var attraction: Float = 0
    public var orbit: Float = 0
    public var spiralArms = 0
    public var spiralTwist: Float = 0
    public var armWidth: Float = 0.5
    public var size = Vec2(0.1, 0.1)
    public var spin: Float = 0
    public var sizeOverLife = [ParticleCurveKey(0, 1)]
    public var color = [ParticleColorKey(0, Vec4(1, 1, 1, 1)), ParticleColorKey(1, Vec4(1, 1, 1, 0))]
    public var intensity: Float = 1
    public var brightnessVariation: Float = 0
    public var blend = ParticleBlend.additive
    public var stretch: Float = 0
    public var stretchMode = ParticleStretchMode.scaled
    public var collidesWithGround = false
    public var groundHeight: Float = 0
    public var bounce: Float = 0.4
    public var friction: Float = 0.2
    public var softness: Float = 0
    public var lit = false
    public var seed: UInt32 = 1
    /// A collision (ground) ends the particle's life (for collision sub-emitters: rain splashes).
    public var killOnCollision = false
    /// An image, `.proctex` or `.sprite` by path relative to `Assets/` (or "asset:<id>"); "" draws a soft disc.
    public var texture = ""
    /// A `.sprite` texture: the tag whose frames play ("": every frame).
    public var spriteTag = ""
    /// An image or `.proctex` texture: its flipbook grid, row by row from the top left.
    public var atlasColumns = 1
    public var atlasRows = 1
    /// Frames used (0: every cell; a `.sprite`: every frame of the tag).
    public var frameCount = 0
    /// Frames per second, looping; 0 plays the frames once over each particle's life.
    public var frameRate: Float = 0
    /// Each particle starts at a random frame (and loops).
    public var randomStartFrame = false
    /// Cross-fades each frame into the next.
    public var frameBlending = false
    /// Other emitters of the effect spawned by this one's particles (at most `ParticleEmitter.maxSubEmitters`).
    public var subEmitters: [VFXSubEmitter] = []

    public init() {}

    public static var fieldHints: [String: FieldHints] {
        var hints = ParticleEmitter.fieldHints
        hints["position"] = FieldHints(step: 0.05, tooltip: "Meters, relative to the effect's origin")
        hints["rotation"] = FieldHints(step: 1, tooltip: "Degrees: turns the emission")
        hints["delay"] = FieldHints(range: 0...60, step: 0.05, tooltip: "Seconds after the effect starts before this emitter begins")
        hints["lifetime"] = FieldHints(step: 0.05, tooltip: "Random lifetime range, seconds (min, max)")
        hints["speed"] = FieldHints(step: 0.1, tooltip: "Random initial speed range (min, max)")
        hints["size"] = FieldHints(step: 0.005, tooltip: "Random particle size range (half-width)")
        hints["texture"] = FieldHints(tooltip: "An image, .proctex or .sprite (empty: a soft disc). Its RGBA multiplies the color")
        hints["spriteTag"] = FieldHints(tooltip: "A .sprite texture: the tag whose frames play (empty: every frame)")
        hints["atlasColumns"] = FieldHints(range: 1...64, step: 1, tooltip: "Image textures: flipbook columns (a .sprite sets its own grid)")
        hints["atlasRows"] = FieldHints(range: 1...64, step: 1, tooltip: "Image textures: flipbook rows (a .sprite sets its own grid)")
        hints["killOnCollision"] = FieldHints(tooltip: "A ground collision ends the particle (pair it with a collision sub-emitter)")
        hints["subEmitters"] = FieldHints(tooltip: "Emitters of this effect spawned where this one's particles are born, die or collide (at most \(ParticleEmitter.maxSubEmitters))")
        hints["inheritVelocity"] = FieldHints(range: 0...2, step: 0.05, tooltip: "Fraction of the parent particle's velocity the new ones get")
        return hints
    }

    /// The engine emitter this describes (the transform comes from `position` and `rotation`).
    public func particleEmitter() -> ParticleEmitter {
        var e = ParticleEmitter()
        e.rate = rate
        e.bursts = bursts
        e.startDelay = max(delay, 0)
        e.capacity = capacity
        e.prewarm = prewarm
        e.lifetime = lifetime
        e.shape = shape
        e.shapeSize = shapeSize
        e.direction = direction
        e.spread = spread
        e.speed = speed
        e.gravity = gravity
        e.drag = drag
        e.turbulence = turbulence
        e.turbulenceFrequency = turbulenceFrequency
        e.attraction = attraction
        e.orbit = orbit
        e.spiralArms = spiralArms
        e.spiralTwist = spiralTwist
        e.armWidth = armWidth
        e.size = size
        e.spin = spin
        e.sizeOverLife = Array(sizeOverLife.prefix(4))
        e.color = Array(color.prefix(4))
        e.intensity = intensity
        e.brightnessVariation = brightnessVariation
        e.blend = blend
        e.stretch = stretch
        e.stretchMode = stretchMode
        e.collidesWithGround = collidesWithGround
        e.groundHeight = groundHeight
        e.bounce = bounce
        e.friction = friction
        e.softness = softness
        e.lit = lit
        e.seed = seed
        e.killOnCollision = killOnCollision
        e.atlasColumns = min(max(atlasColumns, 1), 64)
        e.atlasRows = min(max(atlasRows, 1), 64)
        e.frameCount = max(frameCount, 0)
        e.frameRate = max(frameRate, 0)
        e.randomStartFrame = randomStartFrame
        e.frameBlending = frameBlending
        return e
    }

    public var transform: Transform { Transform(position: position, rotation: Quat(eulerDegrees: rotation)) }

    private enum CodingKeys: String, CodingKey {
        case name, position, rotation, delay, rate, bursts, capacity, prewarm, lifetime, shape, shapeSize, direction, spread, speed,
             gravity, drag, turbulence, turbulenceFrequency, attraction, orbit, spiralArms, spiralTwist, armWidth, size, spin,
             sizeOverLife, color, intensity, brightnessVariation, blend, stretch, stretchMode, collidesWithGround, groundHeight,
             bounce, friction, softness, lit, seed, killOnCollision, texture, spriteTag, atlasColumns, atlasRows, frameCount,
             frameRate, randomStartFrame, frameBlending, subEmitters
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ field: inout T) throws {
            if let v = try c.decodeIfPresent(T.self, forKey: key) { field = v }
        }
        try read(.name, &name); try read(.position, &position); try read(.rotation, &rotation); try read(.delay, &delay)
        try read(.rate, &rate); try read(.bursts, &bursts); try read(.capacity, &capacity); try read(.prewarm, &prewarm)
        try read(.lifetime, &lifetime); try read(.shape, &shape); try read(.shapeSize, &shapeSize)
        try read(.direction, &direction); try read(.spread, &spread); try read(.speed, &speed); try read(.gravity, &gravity)
        try read(.drag, &drag); try read(.turbulence, &turbulence); try read(.turbulenceFrequency, &turbulenceFrequency)
        try read(.attraction, &attraction); try read(.orbit, &orbit); try read(.spiralArms, &spiralArms)
        try read(.spiralTwist, &spiralTwist); try read(.armWidth, &armWidth); try read(.size, &size); try read(.spin, &spin)
        try read(.sizeOverLife, &sizeOverLife); try read(.color, &color); try read(.intensity, &intensity)
        try read(.brightnessVariation, &brightnessVariation); try read(.blend, &blend); try read(.stretch, &stretch)
        try read(.stretchMode, &stretchMode); try read(.collidesWithGround, &collidesWithGround)
        try read(.groundHeight, &groundHeight); try read(.bounce, &bounce); try read(.friction, &friction)
        try read(.softness, &softness); try read(.lit, &lit); try read(.seed, &seed)
        try read(.killOnCollision, &killOnCollision); try read(.texture, &texture); try read(.spriteTag, &spriteTag)
        try read(.atlasColumns, &atlasColumns); try read(.atlasRows, &atlasRows); try read(.frameCount, &frameCount)
        try read(.frameRate, &frameRate); try read(.randomStartFrame, &randomStartFrame); try read(.frameBlending, &frameBlending)
        try read(.subEmitters, &subEmitters)
    }
}

/// A sub-emitter link of a `VFXEmitter`: each particle of the emitter spawns `count` particles of
/// the effect's emitter named `emitter` when the `trigger` happens to it, on the GPU
/// (`ParticleSubEmitter`). The target emits only that way: its rate, bursts, delay and position
/// are ignored; its shape and cone (turned by its rotation) are centered on each event. Targets
/// can't have sub-emitters of their own.
public struct VFXSubEmitter: Codable, Equatable, Sendable {
    public var trigger = ParticleSubEmitterTrigger.death
    /// The target emitter's name.
    public var emitter = ""
    /// Particles per event (1 to `ParticleEmitter.maxSubEmitterCount`).
    public var count = 8
    /// Fraction of the parent particle's velocity the new ones get.
    public var inheritVelocity: Float = 0

    public init(_ trigger: ParticleSubEmitterTrigger = .death, emitter: String = "", count: Int = 8, inheritVelocity: Float = 0) {
        self.trigger = trigger
        self.emitter = emitter
        self.count = count
        self.inheritVelocity = inheritVelocity
    }

    private enum CodingKeys: String, CodingKey { case trigger, emitter, count, inheritVelocity }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trigger = try c.decodeIfPresent(ParticleSubEmitterTrigger.self, forKey: .trigger) ?? .death
        emitter = try c.decodeIfPresent(String.self, forKey: .emitter) ?? ""
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 8
        inheritVelocity = try c.decodeIfPresent(Float.self, forKey: .inheritVelocity) ?? 0
    }
}

/// The contents of a `.vfx` file.
public struct VFXBuild: Codable, Equatable, Sendable {
    public var emitters: [VFXEmitter]
    /// Seconds one run of the effect lasts: the editor preview restarts after this when looping.
    public var duration: Float
    /// The preview's background color (sRGB 0...1).
    public var background: Vec3
    /// Whether the preview shows a ground plane.
    public var ground: Bool

    public init(emitters: [VFXEmitter] = [], duration: Float = 4, background: Vec3 = Vec3(0.07, 0.08, 0.1), ground: Bool = true) {
        self.emitters = emitters
        self.duration = duration
        self.background = background
        self.ground = ground
    }

    private enum CodingKeys: String, CodingKey { case emitters, duration, background, ground }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = VFXBuild()
        self.init(emitters: try c.decodeIfPresent([VFXEmitter].self, forKey: .emitters) ?? [],
                  duration: try c.decodeIfPresent(Float.self, forKey: .duration) ?? d.duration,
                  background: try c.decodeIfPresent(Vec3.self, forKey: .background) ?? d.background,
                  ground: try c.decodeIfPresent(Bool.self, forKey: .ground) ?? d.ground)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// The default for a new effect: a smoke plume.
    public static var starter: VFXBuild { preset("smoke") ?? VFXBuild(emitters: [VFXEmitter()]) }

    /// Renames emitter `old` to `new`, and the sub-emitter links that name it.
    public mutating func renameEmitter(_ old: String, to new: String) {
        for i in emitters.indices {
            if emitters[i].name == old { emitters[i].name = new }
            for j in emitters[i].subEmitters.indices where emitters[i].subEmitters[j].emitter == old {
                emitters[i].subEmitters[j].emitter = new
            }
        }
    }

    /// Removes the emitters named in `names`, and the sub-emitter links to them.
    public mutating func removeEmitters(named names: Set<String>) {
        emitters.removeAll { names.contains($0.name) }
        for i in emitters.indices { emitters[i].subEmitters.removeAll { names.contains($0.emitter) } }
    }

    /// Emitters spawned by another one's sub-emitter links (their own rate, bursts and delay don't run).
    public var subEmitterTargets: Set<String> {
        Set(emitters.flatMap { e in e.subEmitters.prefix(ParticleEmitter.maxSubEmitters).map(\.emitter) }.filter { !$0.isEmpty })
    }

    /// A name not used by any emitter: `base`, else "`base` 2"…
    public func uniqueEmitterName(_ base: String) -> String {
        let names = Set(emitters.map(\.name))
        guard names.contains(base) else { return base }
        var n = 2
        while names.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }
}

// MARK: Presets

extension VFXBuild {
    public static let presetNames = ["fire", "smoke", "sparks", "explosion", "magicHit", "rain", "snow", "dust", "portal"]

    private static func emitter(_ name: String, _ configure: (inout VFXEmitter) -> Void) -> VFXEmitter {
        var e = VFXEmitter()
        e.name = name
        configure(&e)
        return e
    }

    private static func keys(_ list: [(Float, [Float])]) -> [ParticleColorKey] {
        list.map { ParticleColorKey($0.0, Vec4($0.1[0], $0.1[1], $0.1[2], $0.1[3])) }
    }

    private static func curve(_ list: [(Float, Float)]) -> [ParticleCurveKey] { list.map { ParticleCurveKey($0.0, $0.1) } }

    /// A ready-made effect by name (case-insensitive; nil for an unknown name).
    public static func preset(_ name: String) -> VFXBuild? {
        switch name.lowercased() {
        case "fire":
            return VFXBuild(emitters: [
                emitter("Flames") { e in
                    e.rate = 700; e.capacity = 2048; e.prewarm = 2; e.lifetime = Vec2(0.5, 1.1)
                    e.shape = .sphere; e.shapeSize = Vec3(0.3, 0.1, 0.3); e.spread = 0.35; e.speed = Vec2(0.6, 1.4)
                    e.gravity = Vec3(0, 2.2, 0); e.drag = 0.8; e.turbulence = 4; e.turbulenceFrequency = 1.6
                    e.size = Vec2(0.16, 0.28); e.spin = 2
                    e.sizeOverLife = curve([(0, 0.7), (0.25, 1), (1, 0.25)])
                    e.color = keys([(0, [1, 0.85, 0.45, 0.9]), (0.3, [1, 0.42, 0.1, 0.8]), (0.7, [0.7, 0.12, 0.02, 0.45]), (1, [0.2, 0.03, 0, 0])])
                    e.intensity = 3.5; e.brightnessVariation = 0.4; e.seed = 11
                },
                emitter("Embers") { e in
                    e.rate = 28; e.capacity = 512; e.prewarm = 3; e.lifetime = Vec2(1.5, 3); e.position = Vec3(0, 0.3, 0)
                    e.shape = .sphere; e.shapeSize = Vec3(0.25, 0.1, 0.25); e.spread = 0.6; e.speed = Vec2(0.8, 1.8)
                    e.gravity = Vec3(0, 0.8, 0); e.turbulence = 3; e.turbulenceFrequency = 1.2; e.size = Vec2(0.012, 0.024)
                    e.color = keys([(0, [1, 0.8, 0.4, 1]), (0.6, [1, 0.35, 0.05, 0.9]), (1, [0.5, 0.05, 0, 0])])
                    e.intensity = 8; e.brightnessVariation = 0.5; e.seed = 12
                },
                emitter("Smoke") { e in
                    e.delay = 0.3; e.rate = 30; e.capacity = 512; e.prewarm = 5; e.position = Vec3(0, 1.1, 0)
                    e.lifetime = Vec2(3, 4.5); e.shape = .sphere; e.shapeSize = Vec3(0.2, 0.2, 0.2); e.spread = 0.3
                    e.speed = Vec2(0.4, 0.8); e.gravity = Vec3(0.2, 0.5, 0); e.drag = 0.4; e.turbulence = 0.8
                    e.turbulenceFrequency = 0.5; e.size = Vec2(0.4, 0.6); e.spin = 0.4; e.blend = .alpha
                    e.sizeOverLife = curve([(0, 0.5), (1, 2.6)])
                    e.color = keys([(0, [0.4, 0.38, 0.36, 0]), (0.15, [0.38, 0.36, 0.35, 0.5]), (0.6, [0.3, 0.3, 0.32, 0.3]), (1, [0.28, 0.28, 0.3, 0])])
                    e.brightnessVariation = 0.3; e.softness = 0.4; e.seed = 13
                },
            ], duration: 4)
        case "smoke":
            return VFXBuild(emitters: [
                emitter("Smoke") { e in
                    e.rate = 45; e.capacity = 1024; e.prewarm = 6; e.lifetime = Vec2(3.5, 5.5)
                    e.shape = .sphere; e.shapeSize = Vec3(0.25, 0.25, 0.25); e.spread = 0.3; e.speed = Vec2(0.5, 0.9)
                    e.gravity = Vec3(0.25, 0.5, 0); e.drag = 0.4; e.turbulence = 0.8; e.turbulenceFrequency = 0.5
                    e.size = Vec2(0.45, 0.7); e.spin = 0.4; e.blend = .alpha; e.sizeOverLife = curve([(0, 0.5), (1, 2.6)])
                    e.color = keys([(0, [0.5, 0.48, 0.46, 0]), (0.15, [0.48, 0.46, 0.45, 0.65]), (0.6, [0.42, 0.42, 0.44, 0.45]), (1, [0.4, 0.4, 0.42, 0])])
                    e.brightnessVariation = 0.3; e.softness = 0.5; e.seed = 21
                },
            ], duration: 6)
        case "sparks":
            return VFXBuild(emitters: [
                emitter("Sparks") { e in
                    e.rate = 120; e.bursts = [ParticleBurst(time: 0, count: 80, interval: 1.5, cycles: 0)]
                    e.capacity = 4096; e.prewarm = 1; e.lifetime = Vec2(1, 2); e.spread = 0.7; e.speed = Vec2(3, 7)
                    e.gravity = Vec3(0, -9.81, 0); e.drag = 0.15; e.size = Vec2(0.02, 0.04)
                    e.color = keys([(0, [1, 0.95, 0.7, 1]), (0.4, [1, 0.6, 0.15, 1]), (1, [0.8, 0.15, 0.02, 0])])
                    e.intensity = 9; e.stretch = 0.05; e.collidesWithGround = true; e.bounce = 0.45; e.friction = 0.3; e.seed = 31
                },
                emitter("Glow") { e in
                    e.rate = 6; e.capacity = 64; e.lifetime = Vec2(0.3, 0.5); e.size = Vec2(0.25, 0.35)
                    e.color = keys([(0, [1, 0.6, 0.25, 0.5]), (1, [1, 0.3, 0.05, 0])]); e.intensity = 2; e.seed = 32
                },
            ], duration: 3)
        case "explosion":
            return VFXBuild(emitters: [
                emitter("Flash") { e in
                    e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 4)]; e.capacity = 64; e.lifetime = Vec2(0.12, 0.2)
                    e.shape = .sphere; e.shapeSize = Vec3(0.2, 0.2, 0.2); e.spread = .pi; e.speed = Vec2(0, 0.5); e.size = Vec2(0.9, 1.3)
                    e.sizeOverLife = curve([(0, 0.6), (1, 1.5)])
                    e.color = keys([(0, [1, 0.95, 0.8, 1]), (1, [1, 0.5, 0.1, 0])]); e.intensity = 8; e.seed = 41
                },
                emitter("Fireball") { e in
                    e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 90)]; e.capacity = 512; e.lifetime = Vec2(0.5, 1)
                    e.shape = .sphere; e.shapeSize = Vec3(0.3, 0.3, 0.3); e.spread = .pi; e.speed = Vec2(2, 6); e.drag = 3
                    e.gravity = Vec3(0, 1.2, 0); e.turbulence = 3; e.size = Vec2(0.35, 0.6); e.spin = 2
                    e.sizeOverLife = curve([(0, 0.6), (0.4, 1.1), (1, 1.5)])
                    e.color = keys([(0, [1, 0.85, 0.45, 1]), (0.3, [1, 0.4, 0.08, 0.85]), (0.7, [0.5, 0.08, 0.02, 0.4]), (1, [0.1, 0.02, 0, 0])])
                    e.intensity = 3.5; e.brightnessVariation = 0.4; e.seed = 42
                },
                emitter("Smoke") { e in
                    e.delay = 0.1; e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 45)]; e.capacity = 256
                    e.lifetime = Vec2(2, 3.5); e.shape = .sphere; e.shapeSize = Vec3(0.4, 0.4, 0.4); e.spread = .pi
                    e.speed = Vec2(1, 3); e.drag = 1.5; e.gravity = Vec3(0, 0.6, 0); e.turbulence = 1; e.turbulenceFrequency = 0.6
                    e.size = Vec2(0.5, 0.8); e.spin = 0.5; e.blend = .alpha; e.sizeOverLife = curve([(0, 0.5), (1, 3)])
                    e.color = keys([(0, [0.12, 0.11, 0.1, 0.8]), (0.4, [0.2, 0.2, 0.21, 0.55]), (1, [0.25, 0.25, 0.27, 0])])
                    e.softness = 0.4; e.seed = 43
                },
                emitter("Sparks") { e in
                    e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 110)]; e.capacity = 512; e.lifetime = Vec2(0.8, 1.6)
                    e.shape = .sphere; e.shapeSize = Vec3(0.1, 0.1, 0.1); e.spread = .pi; e.speed = Vec2(6, 14)
                    e.gravity = Vec3(0, -9.81, 0); e.drag = 0.3; e.size = Vec2(0.02, 0.04)
                    e.color = keys([(0, [1, 0.95, 0.7, 1]), (0.4, [1, 0.55, 0.12, 1]), (1, [0.7, 0.1, 0.02, 0])])
                    e.intensity = 9; e.stretch = 0.05; e.collidesWithGround = true; e.bounce = 0.4; e.seed = 44
                },
            ], duration: 4)
        case "magichit", "magic hit", "magic_hit":
            return VFXBuild(emitters: [
                emitter("Flash") { e in
                    e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 2)]; e.capacity = 32; e.lifetime = Vec2(0.2, 0.3)
                    e.size = Vec2(0.6, 0.8); e.sizeOverLife = curve([(0, 0.4), (1, 1.6)])
                    e.color = keys([(0, [0.8, 0.9, 1, 1]), (1, [0.4, 0.3, 1, 0])]); e.intensity = 6; e.seed = 51
                },
                emitter("Burst") { e in
                    e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 70)]; e.capacity = 256; e.lifetime = Vec2(0.4, 0.8)
                    e.shape = .sphere; e.shapeSize = Vec3(0.1, 0.1, 0.1); e.spread = .pi; e.speed = Vec2(2, 5); e.drag = 3
                    e.size = Vec2(0.02, 0.05)
                    e.color = keys([(0, [0.85, 0.95, 1, 1]), (0.4, [0.4, 0.5, 1, 1]), (1, [0.4, 0.15, 1, 0])])
                    e.intensity = 7; e.stretch = 0.06; e.brightnessVariation = 0.4; e.seed = 52
                },
                emitter("Motes") { e in
                    e.delay = 0.1; e.rate = 0; e.bursts = [ParticleBurst(time: 0, count: 30)]; e.capacity = 128
                    e.lifetime = Vec2(0.8, 1.4); e.shape = .sphere; e.shapeSize = Vec3(0.35, 0.35, 0.35); e.spread = .pi
                    e.speed = Vec2(0.1, 0.5); e.gravity = Vec3(0, 1.2, 0); e.turbulence = 2; e.size = Vec2(0.015, 0.03)
                    e.color = keys([(0, [0.7, 0.8, 1, 0]), (0.2, [0.7, 0.8, 1, 1]), (1, [0.5, 0.3, 1, 0])])
                    e.intensity = 5; e.brightnessVariation = 0.5; e.seed = 53
                },
            ], duration: 2)
        case "rain":
            return VFXBuild(emitters: [
                emitter("Rain") { e in
                    e.rate = 1600; e.capacity = 4096; e.prewarm = 1; e.position = Vec3(0, 7, 0); e.lifetime = Vec2(0.6, 0.8)
                    e.shape = .box; e.shapeSize = Vec3(6, 0.1, 6); e.direction = Vec3(0, -1, 0); e.spread = 0.03
                    e.speed = Vec2(12, 15); e.gravity = Vec3(0.5, -6, 0); e.size = Vec2(0.006, 0.01)
                    e.color = keys([(0, [0.7, 0.8, 1, 0.5]), (1, [0.7, 0.8, 1, 0.5])])
                    e.intensity = 1.5; e.stretch = 0.03; e.stretchMode = .streak; e.brightnessVariation = 0.4; e.seed = 61
                },
                emitter("Splashes") { e in
                    e.rate = 120; e.capacity = 256; e.prewarm = 1; e.shape = .box; e.shapeSize = Vec3(6, 0.01, 6)
                    e.lifetime = Vec2(0.15, 0.3); e.spread = 0.8; e.speed = Vec2(0.4, 1); e.gravity = Vec3(0, -4, 0)
                    e.size = Vec2(0.01, 0.02); e.color = keys([(0, [0.8, 0.9, 1, 0.7]), (1, [0.8, 0.9, 1, 0])])
                    e.intensity = 1.5; e.seed = 62
                },
            ], duration: 4)
        case "snow":
            return VFXBuild(emitters: [
                emitter("Snow") { e in
                    e.rate = 350; e.capacity = 4096; e.prewarm = 9; e.position = Vec3(0, 5, 0); e.lifetime = Vec2(8, 10)
                    e.shape = .box; e.shapeSize = Vec3(6, 0.1, 6); e.direction = Vec3(0, -1, 0); e.spread = 0.4
                    e.speed = Vec2(0.3, 0.6); e.gravity = Vec3(0.05, -0.05, 0); e.turbulence = 0.7; e.turbulenceFrequency = 0.5
                    e.size = Vec2(0.02, 0.05); e.spin = 1; e.blend = .alpha
                    e.color = keys([(0, [1, 1, 1, 0]), (0.1, [1, 1, 1, 0.9]), (0.9, [1, 1, 1, 0.9]), (1, [1, 1, 1, 0])])
                    e.brightnessVariation = 0.3; e.seed = 71
                },
            ], duration: 8)
        case "dust":
            return VFXBuild(emitters: [
                emitter("Dust") { e in
                    e.rate = 45; e.capacity = 1024; e.prewarm = 7; e.position = Vec3(0, 1, 0); e.lifetime = Vec2(4, 7)
                    e.shape = .box; e.shapeSize = Vec3(3, 1, 3); e.spread = .pi; e.speed = Vec2(0.03, 0.15)
                    e.gravity = Vec3(0.08, 0.02, 0); e.turbulence = 0.3; e.turbulenceFrequency = 0.4
                    e.size = Vec2(0.012, 0.03); e.blend = .alpha
                    e.color = keys([(0, [0.85, 0.78, 0.65, 0]), (0.2, [0.85, 0.78, 0.65, 0.4]), (0.8, [0.85, 0.78, 0.65, 0.4]), (1, [0.85, 0.78, 0.65, 0])])
                    e.brightnessVariation = 0.5; e.seed = 81
                },
            ], duration: 7)
        case "portal":
            return VFXBuild(emitters: [
                emitter("Ring") { e in
                    e.rate = 600; e.capacity = 4096; e.prewarm = 3; e.position = Vec3(0, 1.4, 0); e.rotation = Vec3(90, 0, 0)
                    e.lifetime = Vec2(1.2, 2); e.shape = .disc; e.shapeSize = Vec3(1.1, 0.05, 0); e.spread = .pi
                    e.speed = Vec2(0, 0.1); e.attraction = 2.5; e.orbit = 1; e.spiralArms = 3; e.spiralTwist = 0.5; e.armWidth = 0.4
                    e.size = Vec2(0.015, 0.035)
                    e.color = keys([(0, [0.4, 0.8, 1, 0]), (0.15, [0.5, 0.9, 1, 1]), (0.7, [0.7, 0.35, 1, 0.8]), (1, [0.5, 0.15, 1, 0])])
                    e.intensity = 4; e.brightnessVariation = 0.6; e.seed = 91
                },
                emitter("Core") { e in
                    e.delay = 0.2; e.rate = 12; e.capacity = 64; e.prewarm = 2; e.position = Vec3(0, 1.4, 0)
                    e.rotation = Vec3(90, 0, 0); e.lifetime = Vec2(1, 1.6); e.size = Vec2(0.5, 0.7)
                    e.sizeOverLife = curve([(0, 0.4), (0.5, 1), (1, 0.6)])
                    e.color = keys([(0, [0.4, 0.3, 1, 0]), (0.4, [0.5, 0.4, 1, 0.25]), (1, [0.3, 0.1, 0.8, 0])])
                    e.intensity = 2; e.seed = 92
                },
                emitter("Sparkles") { e in
                    e.delay = 0.4; e.rate = 30; e.capacity = 256; e.prewarm = 2; e.position = Vec3(0, 1.4, 0)
                    e.lifetime = Vec2(0.8, 1.5); e.shape = .sphere; e.shapeSize = Vec3(0.9, 0.9, 0.2); e.spread = .pi
                    e.speed = Vec2(0.1, 0.4); e.turbulence = 2; e.size = Vec2(0.01, 0.02)
                    e.color = keys([(0, [0.8, 0.9, 1, 0]), (0.3, [0.8, 0.9, 1, 1]), (1, [0.6, 0.3, 1, 0])])
                    e.intensity = 6; e.brightnessVariation = 0.5; e.seed = 93
                },
            ], duration: 4)
        default:
            return nil
        }
    }
}

// MARK: Importer

/// Imports `.vfx` files as a prefab (`prefab/<file name>`): a root named after the file with one
/// child per emitter holding its `ParticleEmitter` and placement. Editing the file reimports it
/// and updates placed copies.
public struct VFXBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "vfx" }
    public var fileExtensions: [String] { ["vfx"] }
    public var version: Int { 2 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: VFXBuild
        do { build = try AssetJSON.decoder().decode(VFXBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a vfx file: \(error)")
        }
        let stem = context.assetPath.pathLastComponent.pathDeletingExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        for problem in VFXBuildCheck.problems(build) { context.warn(problem) }
        // Prefab node numbers: the root is 0, emitter i is i + 1 (the first of a name wins).
        var nodeByName: [String: Int] = [:]
        for (i, e) in build.emitters.enumerated() where nodeByName[e.name] == nil { nodeByName[e.name] = i + 1 }
        var nodes: [PrefabNode] = []
        for (i, e) in build.emitters.enumerated() {
            var particles = e.particleEmitter()
            if let texture = Self.texture(of: e, index: i, &particles, &asset, &namer, &context) {
                particles.texture = TextureHandle(texture)
            }
            let links = e.subEmitters.prefix(ParticleEmitter.maxSubEmitters).filter { !$0.emitter.isEmpty && $0.emitter != e.name }
            particles.subEmitters = links.map {
                ParticleSubEmitter($0.trigger, emitter: .none, count: min(max($0.count, 1), ParticleEmitter.maxSubEmitterCount),
                                   inheritVelocity: $0.inheritVelocity)
            }
            let targets = links.map { nodeByName[$0.emitter] ?? -1 }
            nodes.append(PrefabNode(name: e.name, transform: e.transform, particles: particles,
                                    subEmitterNodes: targets.isEmpty ? nil : targets))
        }
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: nodes)])))
        asset.main = prefab
        return asset
    }
}

extension VFXBuildImporter {
    /// The texture emitter `e` names, as a reference: an image's or `.proctex`'s own texture, or
    /// for a `.sprite` a texture of this asset with the frames baked into a grid (which also sets
    /// `particles`' atlas and frame count). nil (with a warning) when it can't be found.
    static func texture(of e: VFXEmitter, index: Int, _ particles: inout ParticleEmitter, _ asset: inout ImportedAsset,
                        _ namer: inout SubAssetNamer, _ context: inout ImportContext) -> AssetReference? {
        let value = e.texture.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        var id: AssetID?
        var subAsset: SubAssetID?
        var path: String?
        if value.hasPrefix(AssetReference.scheme) {
            if let reference = AssetReference(value) {
                id = reference.asset
                subAsset = reference.subAsset
                path = context.assetsByPath.first { $0.value == reference.asset }?.key
            }
        } else {
            let relative = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
            if let found = context.assetsByPath[relative] {
                id = found
                path = relative
            } else if let found = context.asset(atRelativePath: relative) {
                id = found
                path = context.assetsByPath.first { $0.value == found }?.key
            }
        }
        guard let id else {
            context.warn("emitter '\(e.name)': no texture '\(value)'")
            return nil
        }
        guard let path, path.pathFileExtension.lowercased() == "sprite" else {
            return AssetReference(id, subAsset: subAsset ?? "texture")
        }
        // A sprite: its frames (the tag's, in order) become a flipbook texture of this effect.
        let depth = context.assetPath.split(separator: "/").count - 1
        guard let data = try? context.readDependency(relativePath: String(repeating: "../", count: depth) + path),
              let sprite = try? AssetJSON.decoder().decode(PixelSprite.self, from: data), !sprite.frames.isEmpty,
              sprite.width > 0, sprite.height > 0 else {
            context.warn("emitter '\(e.name)': can't read the sprite '\(path)'")
            return nil
        }
        var frames = Array(sprite.frames.indices)
        let tagName = e.spriteTag.trimmingCharacters(in: .whitespaces)
        if !tagName.isEmpty {
            if let tag = sprite.tags.first(where: { $0.name == tagName }) {
                let from = min(max(tag.from, 0), sprite.frames.count - 1)
                frames = Array(from...min(max(tag.to, from), sprite.frames.count - 1))
            } else {
                context.warn("emitter '\(e.name)': the sprite '\(path)' has no tag '\(tagName)'; every frame plays")
            }
        }
        frames = Array(frames.prefix(64 * 64))
        let columns = min(PixelSprite.sheetColumns(frameCount: frames.count), 64)
        let rows = (frames.count + columns - 1) / columns
        let width = columns * sprite.width
        var pixels = [UInt8](repeating: 0, count: width * rows * sprite.height * 4)
        for (cell, frame) in frames.enumerated() {
            let image = sprite.image(frame: frame)
            let left = (cell % columns) * sprite.width, top = (cell / columns) * sprite.height
            for y in 0..<sprite.height {
                let src = y * sprite.width * 4, dst = ((top + y) * width + left) * 4
                pixels.replaceSubrange(dst..<(dst + sprite.width * 4), with: image.pixels[src..<(src + sprite.width * 4)])
            }
        }
        particles.atlasColumns = columns
        particles.atlasRows = rows
        particles.frameCount = frames.count
        let texture = namer.id(kind: "texture", name: e.name, index: index)
        asset.add(texture, name: e.name, .texture(TextureAsset(image: Image(width: width, height: rows * sprite.height, pixels: pixels),
                                                               isSRGB: true, generatesMipmaps: false)))
        return context.reference(texture)
    }
}

/// Problems with a `.vfx` file found without importing (the importer reports the same ones).
public enum VFXBuildCheck {
    public static func problems(_ build: VFXBuild) -> [String] {
        var problems: [String] = []
        if build.emitters.isEmpty { problems.append("the effect has no emitters") }
        let names = build.emitters.map(\.name)
        if Set(names).count != names.count { problems.append("some emitters share a name") }
        let targets = build.subEmitterTargets
        for e in build.emitters {
            if e.blend == .alpha && e.capacity > ParticleEmitter.maxSortedCapacity {
                problems.append("emitter '\(e.name)': alpha emitters hold at most \(ParticleEmitter.maxSortedCapacity) particles")
            }
            if e.color.count > 4 || e.sizeOverLife.count > 4 { problems.append("emitter '\(e.name)': only the first 4 color / size keys are used") }
            if e.lifetime.x > e.lifetime.y { problems.append("emitter '\(e.name)': lifetime min is above max") }
            if e.rate <= 0 && e.bursts.isEmpty && !targets.contains(e.name) { problems.append("emitter '\(e.name)' has no rate and no bursts, so it never emits") }
            if e.delay < 0 { problems.append("emitter '\(e.name)': delay is negative") }
            if e.subEmitters.count > ParticleEmitter.maxSubEmitters {
                problems.append("emitter '\(e.name)': only the first \(ParticleEmitter.maxSubEmitters) sub-emitters are used")
            }
            for link in e.subEmitters.prefix(ParticleEmitter.maxSubEmitters) {
                if link.emitter.isEmpty || link.emitter == e.name {
                    problems.append("emitter '\(e.name)': a sub-emitter link names no other emitter")
                } else if let target = build.emitters.first(where: { $0.name == link.emitter }) {
                    if !target.subEmitters.isEmpty {
                        problems.append("emitter '\(e.name)': sub-emitter '\(link.emitter)' has sub-emitters of its own, which don't run")
                    }
                } else {
                    problems.append("emitter '\(e.name)': no emitter '\(link.emitter)' for its sub-emitter")
                }
                if link.count < 1 || link.count > ParticleEmitter.maxSubEmitterCount {
                    problems.append("emitter '\(e.name)': sub-emitter count must be 1 to \(ParticleEmitter.maxSubEmitterCount)")
                }
            }
        }
        return problems
    }
}
