import Foundation

/// Rotates its entity about `axis` at `speed` radians per second while the world's systems run
/// (play mode, built games). The starter scene uses it so that pressing Play visibly does
/// something. Runs from `World.addBuiltinAnimationSystems()`.
public struct Spin: Component, Equatable, Sendable {
    public static let componentName = "Spin"
    public static var fieldHints: [String: FieldHints] {
        ["speed": FieldHints(step: 0.05, tooltip: "Radians per second"), "axis": FieldHints(step: 0.1)]
    }

    public var axis: Vec3
    public var speed: Float

    public init(axis: Vec3 = Vec3(0, 1, 0), speed: Float = 1) {
        self.axis = axis
        self.speed = speed
    }
}

extension World {
    /// Registers the data-driven animation systems: `Spin`, `FieldAnimator`, `LightFlicker`
    /// (all in `.update`) and `CameraPath` (`.lateUpdate`, after gameplay moved its targets).
    /// They need no game module, so every host that runs a scene's systems calls this: the
    /// editor's play mode (`addEditorSystems`), `GamePlayer` (built games) and `GameRunner`.
    /// Idempotent. Scenes without those components pay one count check per system per frame.
    @MainActor public func addBuiltinAnimationSystems() {
        guard !systemNames(in: .update).contains("builtin.spin") else { return }
        addSystem("builtin.spin", stage: .update) { world in
            let dt = world.time.delta
            world.queryMutating(Transform.self, Spin.self) { _, transform, spin in
                guard spin.speed != 0, length(spin.axis) > 0 else { return }
                transform.rotation = (Quat(angle: spin.speed * dt, axis: normalize(spin.axis)) * transform.rotation).normalized
            }
        }
        addSystem("builtin.fieldAnimator", stage: .update) { world in world.runFieldAnimators() }
        addSystem("builtin.lightFlicker", stage: .update) { world in world.runLightFlickers() }
        addSystem("builtin.cameraPath", stage: .lateUpdate) { world in world.runCameraPaths() }
    }
}
