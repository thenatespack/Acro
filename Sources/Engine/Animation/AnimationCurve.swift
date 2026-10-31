import Foundation

/// A value that can be interpolated by `AnimationCurve` and `Tween`: `Float`, `Vec2`, `Vec3`,
/// `Vec4` (component-wise) and `Quat` (spherical for `lerp`; Hermite blends the components and
/// renormalizes, taking the shorter arc).
public protocol Animatable: Sendable {
    static var zero: Self { get }
    /// Linear interpolation: `a` at `t` = 0, `b` at 1 (not clamped).
    static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self
    /// Cubic Hermite spline between `p0` and `p1` over a segment `dt` seconds long, with
    /// tangents `m0` / `m1` in value units per second and `t` = 0...1 along the segment.
    static func hermite(_ p0: Self, _ m0: Self, _ p1: Self, _ m1: Self, t: Float, dt: Float) -> Self
    /// The average rate of change from `a` to `b` over `dt` seconds (an automatic tangent).
    static func slope(from a: Self, to b: Self, dt: Float) -> Self
}

private func hermiteBasis(_ t: Float) -> (h00: Float, h10: Float, h01: Float, h11: Float) {
    let t2 = t * t, t3 = t2 * t
    return (2 * t3 - 3 * t2 + 1, t3 - 2 * t2 + t, -2 * t3 + 3 * t2, t3 - t2)
}

extension Float: Animatable {
    public static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
    public static func hermite(_ p0: Float, _ m0: Float, _ p1: Float, _ m1: Float, t: Float, dt: Float) -> Float {
        let h = hermiteBasis(t)
        return h.h00 * p0 + h.h10 * dt * m0 + h.h01 * p1 + h.h11 * dt * m1
    }
    public static func slope(from a: Float, to b: Float, dt: Float) -> Float { dt > 0 ? (b - a) / dt : 0 }
}

extension SIMD2<Float>: Animatable {}
extension SIMD3<Float>: Animatable {}
extension SIMD4<Float>: Animatable {}

extension SIMD where Scalar == Float {
    public static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self { a + (b - a) * t }
    public static func hermite(_ p0: Self, _ m0: Self, _ p1: Self, _ m1: Self, t: Float, dt: Float) -> Self {
        let h = hermiteBasis(t)
        return p0 * h.h00 + m0 * (h.h10 * dt) + p1 * h.h01 + m1 * (h.h11 * dt)
    }
    public static func slope(from a: Self, to b: Self, dt: Float) -> Self { dt > 0 ? (b - a) / dt : .zero }
}

extension Quat: Animatable {
    public static let zero = Quat(0, 0, 0, 0)
    public static func lerp(_ a: Quat, _ b: Quat, _ t: Float) -> Quat { slerp(a, b, t) }
    public static func hermite(_ p0: Quat, _ m0: Quat, _ p1: Quat, _ m1: Quat, t: Float, dt: Float) -> Quat {
        let end = (p0.vector * p1.vector).sum() < 0 ? -p1.vector : p1.vector
        let h = hermiteBasis(t)
        let v = p0.vector * h.h00 + m0.vector * (h.h10 * dt) + end * h.h01 + m1.vector * (h.h11 * dt)
        return Quat(vector: v).normalized
    }
    public static func slope(from a: Quat, to b: Quat, dt: Float) -> Quat {
        let end = (a.vector * b.vector).sum() < 0 ? -b.vector : b.vector
        return Quat(vector: dt > 0 ? (end - a.vector) / dt : .zero)
    }
}

/// How a curve segment is interpolated, set per keyframe for the segment that starts there.
public enum KeyInterpolation: String, Codable, Sendable {
    /// Straight line to the next key.
    case linear
    /// Holds this key's value until the next key's time.
    case step
    /// Cubic Hermite spline. Tangents the keys don't set come from their neighbors (Catmull-Rom).
    case hermite
}

/// What a curve does outside its first and last key times.
public enum CurveWrap: String, Codable, Sendable {
    /// Holds the first / last value.
    case clamp
    /// Repeats from the start (first key's time) after the end.
    case loop
    /// Plays forward, then backward, and so on.
    case pingPong
}

public struct Keyframe<Value: Animatable>: Sendable {
    public var time: Float
    public var value: Value
    /// For the segment from this key to the next.
    public var interpolation: KeyInterpolation
    /// Value units per second arriving at / leaving this key (`hermite` only). nil is automatic.
    public var inTangent: Value?
    public var outTangent: Value?

    public init(_ time: Float, _ value: Value, interpolation: KeyInterpolation = .linear,
                inTangent: Value? = nil, outTangent: Value? = nil) {
        self.time = time
        self.value = value
        self.interpolation = interpolation
        self.inTangent = inTangent
        self.outTangent = outTangent
    }
}

extension Keyframe: Equatable where Value: Equatable {}
extension Keyframe: Codable where Value: Codable {}

/// Keyframed values over time, for `Float`, `Vec2`, `Vec3`, `Vec4` and `Quat`. Keys are kept
/// sorted by time; `evaluate(at:)` is pure, so the same time always gives the same value.
public struct AnimationCurve<Value: Animatable>: Sendable {
    public private(set) var keys: [Keyframe<Value>]
    public var wrap: CurveWrap

    public init(keys: [Keyframe<Value>] = [], wrap: CurveWrap = .clamp) {
        self.keys = keys.sorted { $0.time < $1.time }
        self.wrap = wrap
    }

    /// A two-key curve from `from` at time 0 to `to` at `duration`.
    public static func linear(from: Value, to: Value, duration: Float) -> AnimationCurve {
        AnimationCurve(keys: [Keyframe(0, from), Keyframe(duration, to)])
    }

    /// Inserts a key in time order (after existing keys at the same time).
    public mutating func add(_ key: Keyframe<Value>) {
        let index = keys.firstIndex { $0.time > key.time } ?? keys.count
        keys.insert(key, at: index)
    }

    public var startTime: Float { keys.first?.time ?? 0 }
    public var endTime: Float { keys.last?.time ?? 0 }
    public var duration: Float { endTime - startTime }

    /// The value at `time`, after applying `wrap`. `Value.zero` for a curve without keys.
    public func evaluate(at time: Float) -> Value {
        guard let first = keys.first, let last = keys.last else { return .zero }
        guard keys.count > 1, last.time > first.time else { return first.value }
        let t = wrapped(time)
        if t <= first.time { return first.value }
        if t >= last.time { return last.value }
        // The segment [lo, lo + 1] containing t (binary search for the last key at or before t).
        var lo = 0, hi = keys.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if keys[mid].time <= t { lo = mid } else { hi = mid }
        }
        let a = keys[lo], b = keys[lo + 1]
        let dt = b.time - a.time
        let u = dt > 0 ? (t - a.time) / dt : 1
        switch a.interpolation {
        case .step: return a.value
        case .linear: return Value.lerp(a.value, b.value, u)
        case .hermite:
            return Value.hermite(a.value, a.outTangent ?? autoTangent(at: lo),
                                 b.value, b.inTangent ?? autoTangent(at: lo + 1), t: u, dt: dt)
        }
    }

    private func wrapped(_ time: Float) -> Float {
        let start = startTime, length = duration
        switch wrap {
        case .clamp:
            return time
        case .loop:
            if time >= start && time <= endTime { return time }
            let m = (time - start).truncatingRemainder(dividingBy: length)
            return start + (m < 0 ? m + length : m)
        case .pingPong:
            let m = (time - start).truncatingRemainder(dividingBy: 2 * length)
            let p = m < 0 ? m + 2 * length : m
            return start + (p <= length ? p : 2 * length - p)
        }
    }

    /// Catmull-Rom: the slope between the neighbors (one-sided at the ends).
    private func autoTangent(at i: Int) -> Value {
        let prev = keys[max(i - 1, 0)], next = keys[min(i + 1, keys.count - 1)]
        return Value.slope(from: prev.value, to: next.value, dt: next.time - prev.time)
    }
}

extension AnimationCurve: Equatable where Value: Equatable {}
extension AnimationCurve: Codable where Value: Codable {}
