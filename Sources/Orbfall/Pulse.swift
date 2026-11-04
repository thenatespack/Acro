import Engine
import Foundation

/// Test component: makes its entity throb by scaling it around the scale it had when play started.
public struct Pulse: Component, Equatable, Sendable {
    public static let componentName = "Pulse"
    public static var fieldHints: [String: FieldHints] {
        ["amount": FieldHints(range: 0...1, step: 0.01, tooltip: "Fraction of the base scale added and removed"),
         "speed": FieldHints(range: 0...20, step: 0.1, tooltip: "Pulses per second"),
         "baseScale": FieldHints(tooltip: "Set when play starts")]
    }

    public var amount: Float = 0.25
    public var speed: Float = 2
    /// The scale it pulses around; taken from the transform on the first frame.
    public var baseScale: Vec3?

    public init(amount: Float = 0.25, speed: Float = 2) {
        self.amount = amount
        self.speed = speed
    }
}

@MainActor
enum PulseSystem {
    static func run(_ world: World) {
        let t = Float(world.time.elapsed)
        world.queryMutating(Transform.self, Pulse.self) { _, transform, pulse in
            let base = pulse.baseScale ?? transform.scale
            pulse.baseScale = base
            let factor = 1 + sinf(t * pulse.speed * 2 * .pi) * pulse.amount
            transform.scale = base * factor
        }
    }
}
