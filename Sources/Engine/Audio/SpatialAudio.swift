import Foundation

// 3D positional audio, the math half. The game thread turns a listener pose and an emitter's
// position, velocity and settings into plain numbers (left/right gain, pitch, cutoffs) once per
// frame; the mixer only ever sees those and ramps toward them. `AudioSystem` applies this to
// voices (`play(_:at:)`, `Voice.worldPosition`) and the ECS components in AudioComponents.swift
// drive it from `GlobalTransform`s.

/// How a sound gets quieter with distance. All three hold their level up to `minDistance` and
/// stay at their `maxDistance` level beyond it.
public enum AudioRolloff: String, Codable, Sendable, CaseIterable {
    /// `min / (min + factor * (d - min))`: realistic, never reaches silence.
    case inverse
    /// `1 - factor * (d - min) / (max - min)`: reaches silence at `max` when `factor` is 1.
    case linear
    /// `(d / min) ^ -factor`.
    case exponential
}

/// How one emitter is heard: distance attenuation, cone, Doppler and the distance low-pass.
public struct SpatialSettings: Codable, Equatable, Sendable {
    public var minDistance: Float = 1
    public var maxDistance: Float = 50
    public var rolloff = AudioRolloff.inverse
    public var rolloffFactor: Float = 1
    /// Full angles in degrees. Inside the inner cone the sound is at full level, outside the
    /// outer cone at `coneOuterGain`, and in between it blends linearly. 360 / 360 is omnidirectional.
    public var coneInnerAngle: Float = 360
    public var coneOuterAngle: Float = 360
    public var coneOuterGain: Float = 0
    /// Scales the Doppler pitch shift (0 turns it off, 1 is physical).
    public var dopplerFactor: Float = 1
    /// Rolls high frequencies off with distance, from open at `minDistance` to `farCutoff` Hz at `maxDistance`.
    public var distanceLowPass = true
    public var farCutoff: Float = 2500

    public init() {}
}

/// Where the ears are. Set `AudioSystem.listener` (the ECS `AudioListener` does it from its transform).
public struct AudioListenerState: Equatable, Sendable {
    public var position = Vec3.zero
    /// Where the listener looks (-Z for an unrotated transform).
    public var forward = Vec3(0, 0, -1)
    public var up = Vec3(0, 1, 0)
    /// nil derives it from how the position changes between `AudioSystem.update` calls.
    public var velocity: Vec3?
    /// Master gain for every spatial voice.
    public var volume: Float = 1
    /// Meters per second.
    public var speedOfSound: Float = 343
    /// 0 ... 1: how much the far ear is muffled by the head (0 turns it off).
    public var headShadow: Float = 1

    public init() {}
}

/// What the mixer needs to play one spatial voice for one frame.
struct SpatialResult: Equatable {
    var distance: Float
    /// Attenuation and cone, 1 = unattenuated.
    var gain: Float
    /// -1 (left) ... 1 (right).
    var pan: Float
    var gainL: Float
    var gainR: Float
    var pitch: Float
    var cutoffL: Float
    var cutoffR: Float
}

public enum SpatialAudio {
    /// Doppler pitch stays within an octave either way.
    public static let dopplerRange: ClosedRange<Float> = 0.5...2

    /// Gain for a source `distance` away.
    public static func attenuation(distance: Float, minDistance: Float, maxDistance: Float, rolloff: AudioRolloff,
                                   factor: Float = 1) -> Float {
        let minD = max(minDistance, 1e-4)
        let maxD = max(maxDistance, minD)
        let d = min(max(distance, minD), maxD)
        let factor = max(factor, 0)
        switch rolloff {
        case .inverse: return minD / (minD + factor * (d - minD))
        case .linear: return maxD > minD ? max(1 - factor * (d - minD) / (maxD - minD), 0) : 1
        case .exponential: return powf(d / minD, -factor)
        }
    }

    /// Equal-power pan law: `pan` -1 ... 1 gives (left, right) with left² + right² = 1, so the
    /// loudness stays the same across the field (both are 0.707 in the center).
    public static func equalPowerGains(pan: Float) -> (left: Float, right: Float) {
        let angle = (min(max(pan, -1), 1) + 1) * Float.pi / 4
        return (cosf(angle), sinf(angle))
    }

    /// Pitch ratio for a source and a listener moving with the given velocities (OpenAL's model):
    /// `(c - f * vListener) / (c - f * vSource)`, each velocity projected on the line between them
    /// and kept under the speed of sound. Approaching raises the pitch.
    public static func doppler(listenerPosition: Vec3, listenerVelocity: Vec3, sourcePosition: Vec3,
                               sourceVelocity: Vec3, speedOfSound: Float = 343, factor: Float = 1) -> Float {
        let toListener = listenerPosition - sourcePosition
        let distance = length(toListener)
        guard factor > 0, distance > 1e-5, speedOfSound > 0 else { return 1 }
        let axis = toListener / distance
        let limit = speedOfSound / factor * 0.99
        let vl = min(dot(axis, listenerVelocity), limit)
        let vs = min(dot(axis, sourceVelocity), limit)
        let ratio = (speedOfSound - factor * vl) / (speedOfSound - factor * vs)
        return min(max(ratio, dopplerRange.lowerBound), dopplerRange.upperBound)
    }

    /// Cone gain for a listener `angle` radians off the emitter's axis.
    public static func coneGain(angle: Float, inner: Float, outer: Float, outerGain: Float) -> Float {
        guard inner < 360 || outer < 360 else { return 1 }
        let innerHalf = inner * .pi / 360, outerHalf = max(outer, inner) * .pi / 360
        if angle <= innerHalf { return 1 }
        if angle >= outerHalf { return outerGain }
        return 1 + (outerGain - 1) * (angle - innerHalf) / (outerHalf - innerHalf)
    }

    /// The gains, pitch and cutoffs for one emitter heard by `listener`. `volume` is the voice's own gain.
    static func compute(listener: AudioListenerState, listenerVelocity: Vec3, position: Vec3, velocity: Vec3,
                        direction: Vec3?, settings s: SpatialSettings, volume: Float) -> SpatialResult {
        let offset = position - listener.position
        let distance = length(offset)
        let toSource = distance > 1e-5 ? offset / distance : Vec3(0, 0, -1)

        var gain = attenuation(distance: distance, minDistance: s.minDistance, maxDistance: s.maxDistance,
                               rolloff: s.rolloff, factor: s.rolloffFactor)
        if let direction, length(direction) > 1e-5, distance > 1e-5 {
            let cosAngle = min(max(dot(normalize(direction), -toSource), -1), 1)
            gain *= coneGain(angle: acosf(cosAngle), inner: s.coneInnerAngle, outer: s.coneOuterAngle, outerGain: s.coneOuterGain)
        }

        // Lateral direction in the listener's frame; fades to the center inside minDistance so a
        // source passing through the listener doesn't swing from ear to ear.
        let forward = normalize(listener.forward)
        let right = normalize(cross(forward, listener.up))
        var pan = dot(toSource, right)
        pan *= min(distance / max(s.minDistance, 1e-4), 1)
        let (panL, panR) = equalPowerGains(pan: pan)
        let total = volume * listener.volume * gain

        var cutoff = StereoFilter.openCutoff
        if s.distanceLowPass, s.maxDistance > s.minDistance {
            let t = min(max((distance - s.minDistance) / (s.maxDistance - s.minDistance), 0), 1)
            cutoff = StereoFilter.openCutoff * powf(max(s.farCutoff, 20) / StereoFilter.openCutoff, t)
        }
        // The ear away from the source is muffled by the head: down to 10% of open at 90 degrees.
        let shadow = StereoFilter.openCutoff * powf(0.1, abs(pan) * min(max(listener.headShadow, 0), 1))
        let cutoffL = pan > 0 ? min(cutoff, shadow) : cutoff
        let cutoffR = pan < 0 ? min(cutoff, shadow) : cutoff

        let pitch = doppler(listenerPosition: listener.position, listenerVelocity: listenerVelocity, sourcePosition: position,
                            sourceVelocity: velocity, speedOfSound: listener.speedOfSound, factor: s.dopplerFactor)
        return SpatialResult(distance: distance, gain: gain, pan: pan, gainL: total * panL, gainR: total * panR,
                             pitch: pitch, cutoffL: cutoffL, cutoffR: cutoffR)
    }
}
