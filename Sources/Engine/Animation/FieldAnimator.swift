import Foundation

/// How a track's value moves.
public enum TrackMode: String, Codable, CaseIterable, Sendable {
    /// `from` to `to` over `duration`, shaped by `easing`, repeated per `loop`.
    case fromTo
    /// `offset + amplitude * wave(frequency * t + phase)`.
    case wave
    /// An `AnimationCurve` of the track's `curve` evaluated at the track's time (its own `wrap` loops it).
    case curve
}

/// What a `fromTo` track does after `duration`.
public enum AnimationLoop: String, Codable, CaseIterable, Sendable {
    /// Holds `to`.
    case once
    /// Jumps back to `from` and repeats.
    case loop
    /// Runs back and forth.
    case pingPong
}

/// Waveform of a `wave` track, over one cycle per unit of its argument.
public enum AnimationWave: String, Codable, CaseIterable, Sendable {
    case sine, triangle, square, sawtooth
    /// Smooth random values (deterministic from `seed` and the entity), one lattice value per cycle.
    case noise
}

/// One animated value of a `FieldAnimator`: a float field (or one lane of a vector field)
/// named by `target`, and how it moves. All numbers are in the field's own units.
public struct AnimationTrack: Codable, Equatable, Sendable {
    /// `Component.field` or `Component.field.lane`: `Transform.position.y`, `PointLight.intensity`,
    /// `PointLight.color.r`, `MeshRenderer.opacity`. Lanes are `x y z w` or `r g b a`.
    /// `Transform.rotation.x/y/z` rotate by that many degrees (always relative). Built-in
    /// fields are fast; any other registered component's float or vector field works through
    /// reflection (slower: fine for a few entities).
    public var target: String
    public var mode: TrackMode
    /// Adds the animated value to the field (changing it by the difference each frame, so it
    /// composes with other systems moving the same field) instead of overwriting it.
    public var additive: Bool
    public var from: Float
    public var to: Float
    public var easing: Easing
    public var loop: AnimationLoop
    public var wave: AnimationWave
    public var amplitude: Float
    /// Cycles per second.
    public var frequency: Float
    /// Offset into the cycle, in cycles (0.25 = a quarter turn).
    public var phase: Float
    public var offset: Float
    /// Keys in seconds of track time; `from` / `to` / `wave` fields are ignored in `curve` mode.
    public var curve: AnimationCurve<Float>
    /// Seconds a `fromTo` run lasts.
    public var duration: Float
    /// Seconds before the track starts (it holds its first value meanwhile).
    public var delay: Float
    /// Multiplies this track's time.
    public var speed: Float
    /// Decorrelates `noise` waves between tracks.
    public var seed: Int

    public init(target: String = "", mode: TrackMode = .wave, additive: Bool = true, from: Float = 0, to: Float = 1,
                easing: Easing = .linear, loop: AnimationLoop = .pingPong, wave: AnimationWave = .sine,
                amplitude: Float = 1, frequency: Float = 1, phase: Float = 0, offset: Float = 0,
                curve: AnimationCurve<Float> = .linear(from: 0, to: 1, duration: 1), duration: Float = 1,
                delay: Float = 0, speed: Float = 1, seed: Int = 0) {
        self.target = target
        self.mode = mode
        self.additive = additive
        self.from = from
        self.to = to
        self.easing = easing
        self.loop = loop
        self.wave = wave
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
        self.offset = offset
        self.curve = curve
        self.duration = duration
        self.delay = delay
        self.speed = speed
        self.seed = seed
    }

    /// A `from` to `to` track.
    public static func fromTo(_ target: String, from: Float, to: Float, duration: Float = 1, easing: Easing = .sineInOut,
                              loop: AnimationLoop = .pingPong, additive: Bool = true) -> AnimationTrack {
        AnimationTrack(target: target, mode: .fromTo, additive: additive, from: from, to: to, easing: easing, loop: loop,
                       duration: duration)
    }

    /// A waveform track.
    public static func wave(_ target: String, _ wave: AnimationWave = .sine, amplitude: Float, frequency: Float = 1,
                            phase: Float = 0, offset: Float = 0, additive: Bool = true) -> AnimationTrack {
        AnimationTrack(target: target, mode: .wave, additive: additive, wave: wave, amplitude: amplitude,
                       frequency: frequency, phase: phase, offset: offset)
    }

    private enum CodingKeys: String, CodingKey {
        case target, mode, additive, from, to, easing, loop, wave, amplitude, frequency, phase, offset, curve, duration, delay, speed, seed
    }

    /// Missing fields take their defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AnimationTrack()
        self.init(target: try c.decodeIfPresent(String.self, forKey: .target) ?? d.target,
                  mode: try c.decodeIfPresent(TrackMode.self, forKey: .mode) ?? d.mode,
                  additive: try c.decodeIfPresent(Bool.self, forKey: .additive) ?? d.additive,
                  from: try c.decodeIfPresent(Float.self, forKey: .from) ?? d.from,
                  to: try c.decodeIfPresent(Float.self, forKey: .to) ?? d.to,
                  easing: try c.decodeIfPresent(Easing.self, forKey: .easing) ?? d.easing,
                  loop: try c.decodeIfPresent(AnimationLoop.self, forKey: .loop) ?? d.loop,
                  wave: try c.decodeIfPresent(AnimationWave.self, forKey: .wave) ?? d.wave,
                  amplitude: try c.decodeIfPresent(Float.self, forKey: .amplitude) ?? d.amplitude,
                  frequency: try c.decodeIfPresent(Float.self, forKey: .frequency) ?? d.frequency,
                  phase: try c.decodeIfPresent(Float.self, forKey: .phase) ?? d.phase,
                  offset: try c.decodeIfPresent(Float.self, forKey: .offset) ?? d.offset,
                  curve: try c.decodeIfPresent(AnimationCurve<Float>.self, forKey: .curve) ?? d.curve,
                  duration: try c.decodeIfPresent(Float.self, forKey: .duration) ?? d.duration,
                  delay: try c.decodeIfPresent(Float.self, forKey: .delay) ?? d.delay,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? d.speed,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed)
    }

    /// The track's value `time` seconds after the animator started (pure; `noiseSeed` is the
    /// entity-mixed seed).
    public func value(at time: Float, noiseSeed: UInt64 = 0) -> Float {
        let t = max(time - delay, 0) * speed
        switch mode {
        case .fromTo:
            let x = t / max(duration, 1e-4)
            let p: Float
            switch loop {
            case .once: p = min(x, 1)
            case .loop: p = x - x.rounded(.down)
            case .pingPong:
                let m = x.truncatingRemainder(dividingBy: 2)
                p = m <= 1 ? m : 2 - m
            }
            return from + (to - from) * easing(p)
        case .wave:
            let x = frequency * t + phase
            let f = x - x.rounded(.down)
            let w: Float
            switch wave {
            case .sine: w = sinf(2 * .pi * x)
            case .triangle:
                let g = f + 0.25
                w = 1 - 4 * abs(g - g.rounded(.down) - 0.5)
            case .square: w = f < 0.5 ? 1 : -1
            case .sawtooth: w = 2 * f - 1
            case .noise: w = AnimationNoise.value(x, seed: noiseSeed ^ UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9)
            }
            return offset + amplitude * w
        case .curve:
            return curve.evaluate(at: t)
        }
    }
}

/// Animates fields of the entity's own components over time, with no code: each track names a
/// float field (or one lane of a vector field or color) and moves it with a from/to ease, a
/// waveform (sine, triangle, square, sawtooth, noise) or a keyframed curve. Bob a mesh
/// (`Transform.position.y`), pulse a light (`PointLight.intensity`), breathe a scale, sweep a
/// color, rock about an axis (`Transform.rotation.z`).
///
/// Runs in `.update` from `World.addBuiltinAnimationSystems()` (the editor's play mode,
/// `GamePlayer` and `GameRunner` add it), so scenes need no game module. The fixed-step dt in
/// screenshot mode makes it deterministic. Additive tracks change a field by the difference
/// between this frame's value and last frame's, so they compose with other systems; the
/// bookkeeping lives in the component, which the editor's play snapshot restores on Stop
/// (it is not saved to scene files).
public struct FieldAnimator: Component, Equatable, Sendable {
    public static let componentName = "FieldAnimator"
    public static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(range: 0...20, step: 0.05, tooltip: "Multiplies the animator's clock"),
         "tracks.*.target": FieldHints(tooltip: "Component.field[.lane], e.g. Transform.position.y or PointLight.color.r"),
         "tracks.*.amplitude": FieldHints(step: 0.01), "tracks.*.frequency": FieldHints(step: 0.05, tooltip: "Cycles per second"),
         "tracks.*.phase": FieldHints(step: 0.01, tooltip: "Cycles"), "tracks.*.speed": FieldHints(step: 0.05),
         "tracks.*.duration": FieldHints(range: 0.001...3600, step: 0.05), "tracks.*.delay": FieldHints(range: 0...3600, step: 0.05)]
    }

    public var tracks: [AnimationTrack]
    public var enabled: Bool
    public var speed: Float

    // Runtime state, not coded.
    var time: Double = 0
    var applied: [Float] = []
    var rotationApplied = Vec3.zero

    public init(tracks: [AnimationTrack] = [], enabled: Bool = true, speed: Float = 1) {
        self.tracks = tracks
        self.enabled = enabled
        self.speed = speed
    }

    private enum CodingKeys: String, CodingKey { case tracks, enabled, speed }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(tracks: try c.decodeIfPresent([AnimationTrack].self, forKey: .tracks) ?? [],
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? 1)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tracks, forKey: .tracks)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(speed, forKey: .speed)
    }
}

extension World {
    /// Advances every `FieldAnimator`; `addBuiltinAnimationSystems()` registers this.
    @MainActor func runFieldAnimators() {
        guard count(of: FieldAnimator.self) > 0 else { return }
        let dt = time.delta
        var entities: [Entity] = []
        query(FieldAnimator.self) { entity, _ in entities.append(entity) }
        for entity in entities {
            modify(FieldAnimator.self, for: entity) { animator in
                guard animator.enabled else { return }
                animator.time += Double(dt * animator.speed)
                if animator.applied.count != animator.tracks.count {
                    animator.applied = [Float](repeating: 0, count: animator.tracks.count)
                }
                let t = Float(animator.time)
                var rotation = Vec3.zero
                var hasRotation = false
                for (i, track) in animator.tracks.enumerated() {
                    guard let lane = FieldLanes.lane(for: track.target) else { continue }
                    let value = track.value(at: t, noiseSeed: AnimationNoise.seed(track.seed, entity: entity))
                    if let axis = lane.rotationAxis {
                        rotation[axis] += value
                        hasRotation = true
                    } else if track.additive {
                        let delta = value - animator.applied[i]
                        animator.applied[i] = value
                        if delta != 0, let current = lane.get(self, entity) { lane.set(self, entity, current + delta) }
                    } else {
                        lane.set(self, entity, value)
                    }
                }
                if hasRotation {
                    let previous = animator.rotationApplied
                    animator.rotationApplied = rotation
                    if previous != rotation {
                        modify(Transform.self, for: entity) { transform in
                            transform.rotation = (transform.rotation * Quat(eulerDegrees: previous).inverse
                                                  * Quat(eulerDegrees: rotation)).normalized
                        }
                    }
                }
            }
        }
    }
}
