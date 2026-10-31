import Foundation

/// How a skeletal animation sampler interpolates between keys (glTF `interpolation`).
public enum SamplerInterpolation: String, Codable, Sendable {
    /// Straight lines; rotations are spherical (slerp along the shorter arc).
    case linear = "LINEAR"
    /// Holds each key's value until the next key's time.
    case step = "STEP"
    /// Cubic Hermite spline with an in-tangent, value and out-tangent per key (in that order in
    /// `values`), tangents in value units per second. Rotations are renormalized.
    case cubicSpline = "CUBICSPLINE"
}

/// Which property of a node an `AnimationChannel` drives.
public enum AnimationPath: String, Codable, Sendable {
    case translation, rotation, scale
}

/// Keyframes of one property: `times` in seconds (ascending) and the values flattened, 3
/// floats per value for translation and scale, 4 (x, y, z, w) for rotation; three values per
/// key with `.cubicSpline`. Sampling is pure, so the same time always gives the same value.
public struct AnimationSampler: Codable, Equatable, Sendable {
    public var interpolation: SamplerInterpolation
    public var times: [Float]
    public var values: [Float]

    public init(interpolation: SamplerInterpolation = .linear, times: [Float], values: [Float]) {
        self.interpolation = interpolation
        self.times = times
        self.values = values
    }

    /// The segment containing `time`: the last key at or before it (clamped to the keys) and
    /// the fraction of the way to the next key (0 before the first, 1 after the last).
    private func segment(_ time: Float) -> (key: Int, u: Float, dt: Float) {
        let n = times.count
        if n < 2 || time <= times[0] { return (0, 0, 0) }
        if time >= times[n - 1] { return (n - 1, 0, 0) }
        var lo = 0, hi = n - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if times[mid] <= time { lo = mid } else { hi = mid }
        }
        let dt = times[lo + 1] - times[lo]
        return (lo, dt > 0 ? (time - times[lo]) / dt : 0, dt)
    }

    private func vec3(_ i: Int) -> Vec3 { Vec3(values[i * 3], values[i * 3 + 1], values[i * 3 + 2]) }
    private func quat(_ i: Int) -> Quat { Quat(values[i * 4], values[i * 4 + 1], values[i * 4 + 2], values[i * 4 + 3]) }

    /// The value index of key `k` (the middle one of a cubic spline's triple).
    private func valueIndex(_ k: Int) -> Int { interpolation == .cubicSpline ? k * 3 + 1 : k }

    /// The 3-component value at `time` (translation, scale). Before the first key it is the
    /// first value, after the last the last one.
    public func sampleVec3(at time: Float) -> Vec3 {
        guard !times.isEmpty else { return .zero }
        let (k, u, dt) = segment(time)
        if u == 0 && dt == 0 || interpolation == .step { return vec3(valueIndex(k)) }
        switch interpolation {
        case .step, .linear:
            return Vec3.lerp(vec3(k), vec3(k + 1), u)
        case .cubicSpline:
            return Vec3.hermite(vec3(k * 3 + 1), vec3(k * 3 + 2), vec3(k * 3 + 4), vec3(k * 3 + 3), t: u, dt: dt)
        }
    }

    /// The rotation at `time`, normalized.
    public func sampleQuat(at time: Float) -> Quat {
        guard !times.isEmpty else { return .identity }
        let (k, u, dt) = segment(time)
        if u == 0 && dt == 0 || interpolation == .step { return quat(valueIndex(k)).normalized }
        switch interpolation {
        case .step, .linear:
            return Quat.slerp(quat(k).normalized, quat(k + 1).normalized, u).normalized
        case .cubicSpline:
            return Quat.hermite(quat(k * 3 + 1), quat(k * 3 + 2), quat(k * 3 + 4), quat(k * 3 + 3), t: u, dt: dt)
        }
    }

    /// The last key's time.
    public var endTime: Float { times.last ?? 0 }
}

/// One animated property of one target: `target` indexes `Animator.targets` (for imported
/// clips, the glTF node index).
public struct AnimationChannel: Codable, Equatable, Sendable {
    public var target: Int
    public var path: AnimationPath
    public var sampler: AnimationSampler

    public init(target: Int, path: AnimationPath, sampler: AnimationSampler) {
        self.target = target
        self.path = path
        self.sampler = sampler
    }
}

/// A named moment in a clip (a footstep, a hit frame), reported by the animation system when
/// playback crosses `time`.
public struct AnimationEvent: Codable, Equatable, Sendable {
    /// Seconds from the clip's start.
    public var time: Float
    public var name: String

    public init(time: Float, name: String) {
        self.time = time
        self.name = name
    }
}

/// A skeletal animation: channels of translation, rotation and scale keys over a set of
/// targets (bones or any nodes), plus events. Imported from glTF (`ImportedModel.animations`)
/// or built in code; register it with an `AnimationLibrary` to play it with an `Animator`.
public struct AnimationClip: Codable, Equatable, Sendable {
    public var name: String
    public var channels: [AnimationChannel]
    /// Seconds; the end of the longest channel by default.
    public var duration: Float
    public var events: [AnimationEvent]

    public init(name: String, channels: [AnimationChannel], duration: Float? = nil, events: [AnimationEvent] = []) {
        self.name = name
        self.channels = channels
        self.duration = duration ?? channels.map(\.sampler.endTime).max() ?? 0
        self.events = events.sorted { $0.time < $1.time }
    }

    /// Writes the clip's values at `time` (seconds, not wrapped) into `pose`. Channels whose
    /// target is outside the pose are skipped. Marks the written targets in `pose.animated`.
    public func sample(at time: Float, into pose: inout AnimationPose) {
        for channel in channels where channel.target >= 0 && channel.target < pose.count {
            switch channel.path {
            case .translation: pose.transforms[channel.target].position = channel.sampler.sampleVec3(at: time)
            case .rotation: pose.transforms[channel.target].rotation = channel.sampler.sampleQuat(at: time)
            case .scale: pose.transforms[channel.target].scale = channel.sampler.sampleVec3(at: time)
            }
            pose.animated[channel.target] = true
        }
    }

    /// The highest target index any channel drives, plus one.
    public var targetCount: Int { (channels.map(\.target).max() ?? -1) + 1 }
}

/// Names an `AnimationClip` registered with an `AnimationLibrary`. Encodes as its key.
public struct AnimationClipHandle: Hashable, Codable, Sendable, CustomStringConvertible {
    public var key: String

    public init(_ key: String) { self.key = key }

    public init(from decoder: Decoder) throws { key = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    public var description: String { "clip '\(key)'" }
}

/// The clips `Animator`s refer to by `AnimationClipHandle`. Clips are large and shared by
/// every character playing them, so components only hold the handle.
@MainActor
public final class AnimationLibrary {
    private var clips: [String: AnimationClip] = [:]

    public init() {}

    /// Registers `clip` under `key` (replacing an earlier clip with that key).
    @discardableResult
    public func register(_ clip: AnimationClip, key: String) -> AnimationClipHandle {
        clips[key] = clip
        return AnimationClipHandle(key)
    }

    public func clip(_ handle: AnimationClipHandle) -> AnimationClip? { clips[handle.key] }

    public subscript(handle: AnimationClipHandle) -> AnimationClip? { clips[handle.key] }

    /// Every registered key, sorted.
    public var keys: [String] { clips.keys.sorted() }
}

/// Local transforms for every target of an `Animator`, and which of them some clip drove.
public struct AnimationPose: Equatable, Sendable {
    public var transforms: [Transform]
    /// Targets written by a clip; only these are blended and applied.
    public var animated: [Bool]

    public init(_ transforms: [Transform]) {
        self.transforms = transforms
        animated = Array(repeating: false, count: transforms.count)
    }

    public var count: Int { transforms.count }

    /// `poses` blended by `weights` (which should sum to 1; they are normalized): translation
    /// and scale as weighted sums, rotations as a normalized weighted sum of quaternions, each
    /// flipped into the first one's hemisphere (exact for two poses up to the speed along the
    /// arc, and order independent for nearby rotations). `rest` supplies targets a pose didn't
    /// animate. A target is animated in the result when any pose animated it.
    public static func blend(_ poses: [AnimationPose], weights: [Float], rest: [Transform]) -> AnimationPose {
        var result = AnimationPose(rest)
        let total = weights.reduce(0, +)
        guard total > 0, !poses.isEmpty else { return result }
        for i in 0..<result.count where poses.contains(where: { i < $0.count && $0.animated[i] }) {
            var position = Vec3.zero, scale = Vec3.zero, rotation = Vec4.zero
            var reference: Vec4?
            for (pose, weight) in zip(poses, weights) where weight > 0 {
                let t = i < pose.count && pose.animated[i] ? pose.transforms[i] : rest[i]
                let w = weight / total
                position += t.position * w
                scale += t.scale * w
                var q = t.rotation.vector
                if let reference { if (reference * q).sum() < 0 { q = -q } } else { reference = q }
                rotation += q * w
            }
            result.transforms[i] = Transform(position: position, rotation: Quat(vector: rotation).normalized, scale: scale)
            result.animated[i] = true
        }
        return result
    }

    /// Adds `pose`'s difference from `reference` to this pose, scaled by `weight` (an additive
    /// layer: a breathing or leaning clip on top of locomotion). Translations add, rotations
    /// compose (`slerp(identity, pose · reference⁻¹, weight)` applied first in the parent's
    /// frame), scales multiply.
    public mutating func add(_ pose: AnimationPose, reference: AnimationPose, weight: Float) {
        for i in 0..<min(count, pose.count, reference.count) where pose.animated[i] {
            let delta = pose.transforms[i], base = reference.transforms[i]
            transforms[i].position += (delta.position - base.position) * weight
            let rotation = (delta.rotation * base.rotation.conjugate).normalized
            transforms[i].rotation = (Quat.slerp(.identity, rotation, weight) * transforms[i].rotation).normalized
            let ratio = Vec3(base.scale.x != 0 ? delta.scale.x / base.scale.x : 1, base.scale.y != 0 ? delta.scale.y / base.scale.y : 1,
                             base.scale.z != 0 ? delta.scale.z / base.scale.z : 1)
            transforms[i].scale *= Vec3.lerp(Vec3(1, 1, 1), ratio, weight)
            animated[i] = true
        }
    }
}
