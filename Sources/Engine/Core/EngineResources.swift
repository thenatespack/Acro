import Foundation

extension Bundle {
    /// The engine's resource bundle: shaders under `Shaders/`, fonts under `Fonts/`. The engine
    /// is several modules, but its resources live in this one, so code in any of them loads
    /// them through this rather than its own `Bundle.module`.
    package static var engineResources: Bundle { .module }
}
