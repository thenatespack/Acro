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

/// Fades the whole picture toward `color` by `amount` (0 = clear, 1 = solid color). Timeline
/// fade tracks set it on the `TimelinePlayer`'s entity; game code can add one itself. The
/// strongest fade in the world wins. It is applied in the post pass's color grading (after
/// tonemapping, so `color` is the displayed sRGB color), switching post-processing on with a
/// pass-through look when the scene has none. Not saved with scenes.
public struct ScreenFade: Component, Equatable, Sendable {
    public static let componentName = "ScreenFade"
    public static var isSerialized: Bool { false }

    /// sRGB 0...1.
    public var color: Vec3
    /// 0...1.
    public var amount: Float

    public init(color: Vec3 = Vec3(0, 0, 0), amount: Float = 0) {
        self.color = color
        self.amount = amount
    }

    /// The strongest fade in `world` (nil when none is above 0).
    @MainActor public static func strongest(in world: World) -> ScreenFade? {
        guard world.count(of: ScreenFade.self) > 0 else { return nil }
        var best: ScreenFade?
        world.query(ScreenFade.self) { _, fade in
            if fade.amount > (best?.amount ?? 0) { best = fade }
        }
        return best
    }

    /// `settings` (nil: none) with this fade folded into its lift and gain, so the graded color
    /// `c` becomes `c · (1 - amount) + color · amount` (exact while gamma is 1).
    public func applied(to settings: PostProcessSettings?) -> PostProcessSettings? {
        let a = min(max(amount, 0), 1)
        guard a > 0 else { return settings }
        var s = settings ?? .passthrough
        // Grading maps x to x·(gain - lift) + lift; fading that result keeps the same form.
        let lift = s.lift * (1 - a) + color * a
        let slope = (s.gain - s.lift) * (1 - a)
        s.lift = lift
        s.gain = slope + lift
        return s
    }
}
