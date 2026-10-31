import Foundation

/// Easing functions: they map normalized time 0...1 to progress, with `f(0) = 0` and
/// `f(1) = 1` exactly. `.back` and `.elastic` overshoot (go outside 0...1 in between) and
/// `.bounce` bounces off the end value; every other curve is monotonic. Pure math, so tweens
/// are deterministic given dt. Names are what scene files and `Tween` store (`"cubicInOut"`).
public enum Easing: String, Codable, CaseIterable, Sendable {
    case linear
    case quadIn, quadOut, quadInOut
    case cubicIn, cubicOut, cubicInOut
    case quartIn, quartOut, quartInOut
    case sineIn, sineOut, sineInOut
    case expoIn, expoOut, expoInOut
    case backIn, backOut, backInOut
    case elasticIn, elasticOut, elasticInOut
    case bounceIn, bounceOut, bounceInOut

    /// Progress at normalized time `t` (clamped to 0...1).
    public func callAsFunction(_ t: Float) -> Float {
        let t = min(max(t, 0), 1)
        if t == 0 || t == 1 { return t }
        switch self {
        case .linear: return t
        case .quadIn: return t * t
        case .quadOut: return 1 - (1 - t) * (1 - t)
        case .quadInOut: return t < 0.5 ? 2 * t * t : 1 - powf(-2 * t + 2, 2) / 2
        case .cubicIn: return t * t * t
        case .cubicOut: return 1 - powf(1 - t, 3)
        case .cubicInOut: return t < 0.5 ? 4 * t * t * t : 1 - powf(-2 * t + 2, 3) / 2
        case .quartIn: return powf(t, 4)
        case .quartOut: return 1 - powf(1 - t, 4)
        case .quartInOut: return t < 0.5 ? 8 * powf(t, 4) : 1 - powf(-2 * t + 2, 4) / 2
        case .sineIn: return 1 - cosf(t * .pi / 2)
        case .sineOut: return sinf(t * .pi / 2)
        case .sineInOut: return -(cosf(.pi * t) - 1) / 2
        case .expoIn: return powf(2, 10 * t - 10)
        case .expoOut: return 1 - powf(2, -10 * t)
        case .expoInOut: return t < 0.5 ? powf(2, 20 * t - 10) / 2 : (2 - powf(2, -20 * t + 10)) / 2
        case .backIn: return Self.backC3 * t * t * t - Self.backC1 * t * t
        case .backOut: return 1 + Self.backC3 * powf(t - 1, 3) + Self.backC1 * powf(t - 1, 2)
        case .backInOut:
            let c2 = Self.backC1 * 1.525
            return t < 0.5
                ? powf(2 * t, 2) * ((c2 + 1) * 2 * t - c2) / 2
                : (powf(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
        case .elasticIn: return -powf(2, 10 * t - 10) * sinf((t * 10 - 10.75) * (2 * .pi / 3))
        case .elasticOut: return powf(2, -10 * t) * sinf((t * 10 - 0.75) * (2 * .pi / 3)) + 1
        case .elasticInOut:
            let c5 = 2 * Float.pi / 4.5
            return t < 0.5
                ? -(powf(2, 20 * t - 10) * sinf((20 * t - 11.125) * c5)) / 2
                : powf(2, -20 * t + 10) * sinf((20 * t - 11.125) * c5) / 2 + 1
        case .bounceIn: return 1 - Self.bounce(1 - t)
        case .bounceOut: return Self.bounce(t)
        case .bounceInOut:
            return t < 0.5 ? (1 - Self.bounce(1 - 2 * t)) / 2 : (1 + Self.bounce(2 * t - 1)) / 2
        }
    }

    private static let backC1: Float = 1.70158
    private static let backC3: Float = 2.70158

    private static func bounce(_ t: Float) -> Float {
        let n: Float = 7.5625, d: Float = 2.75
        if t < 1 / d { return n * t * t }
        if t < 2 / d { let t = t - 1.5 / d; return n * t * t + 0.75 }
        if t < 2.5 / d { let t = t - 2.25 / d; return n * t * t + 0.9375 }
        let t = t - 2.625 / d
        return n * t * t + 0.984375
    }
}
