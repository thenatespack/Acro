import Foundation

// Project runtime settings: how the project's game runs, wherever it runs. They are kept in
// `Project.json` under `"runtime"`:
//
// ```json
// "runtime" : {
//   "window" : { "title" : "Neon Alley", "width" : 1600, "height" : 900, "vsync" : true, "quality" : "high",
//                "renderResolution" : "1080p", "upscaler" : "fsr1", "upscalerSharpness" : 0.2, "msaa" : 4,
//                "backend" : "metal", "minWidth" : 640, "minHeight" : 360 },
//   "physics" : { "gravity" : [0, -9.81, 0], "fixedTimestep" : 0.016666 }
// }
// ```
//
// Every field is optional: nil keeps the engine's default. They apply in three places:
// - editor play mode (`EditorSession`): physics gravity and the fixed timestep;
// - exported games: Build Game copies them into the asset pack (`AssetPackManifest.runtime`),
//   and `GamePlayer` applies the window settings to its `EngineConfig` and the physics ones to
//   its worlds; command-line options (`--size`) still win;
// - code: `apply(to:)` for an `EngineConfig`, a `World`, a `PhysicsWorld` or a `PhysicsWorld2D`.

extension RenderQuality: Codable {}
extension GraphicsBackend: Codable {}

/// How the project's game runs (`ProjectSettings.runtime`); see the notes at the top of this file.
public struct ProjectRuntimeSettings: Equatable, Sendable, Codable {
    /// The game window.
    public struct Window: Equatable, Sendable, Codable {
        /// The window title; default: the game's name.
        public var title: String?
        /// The size the window opens at, in points (default 1280 x 720).
        public var width: Int?
        public var height: Int?
        /// Cap the frame rate at the display's refresh rate (default true).
        public var vsync: Bool?
        /// The render quality preset: low, medium, high (default) or ultra.
        public var quality: RenderQuality?
        /// Show the performance overlay at startup (default false in exported games).
        public var showDebugOverlay: Bool?
        /// The size the scene renders at, as `RenderResolution` parses it: `native` (default), a
        /// preset (`720p`, `1080p`, `4k`…), `<w>x<h>`, a scale mode (`quality`, `balanced`,
        /// `performance`, `ultraperformance`) or `<factor>x`.
        public var renderResolution: String?
        /// How a non-native render resolution is scaled into the window, as `Upscaler` parses it:
        /// `bilinear` (default), `fsr1`, `metalfx`, `metalfx-temporal`, `taau` or `fsr3`.
        public var upscaler: String?
        /// Sharpening for `fsr1`, `taau` and `fsr3`, in stops (0 is the sharpest); default: the upscaler's own.
        public var upscalerSharpness: Float?
        /// MSAA samples: 1, 2, 4 or 8; default: the quality preset's. Temporal upscalers force 1.
        public var msaa: Int?
        /// The graphics API; default: Metal on macOS, Vulkan elsewhere. `--backend` wins.
        public var backend: GraphicsBackend?
        /// The smallest size the player can resize the window to, in points; default: no limit.
        public var minWidth: Int?
        public var minHeight: Int?
        /// Keep the window at `width` x `height` even when that is larger than the screen (macOS); default false.
        public var allowLargerThanScreen: Bool?

        public init(title: String? = nil, width: Int? = nil, height: Int? = nil, vsync: Bool? = nil, quality: RenderQuality? = nil,
                    showDebugOverlay: Bool? = nil, renderResolution: String? = nil, upscaler: String? = nil,
                    upscalerSharpness: Float? = nil, msaa: Int? = nil, backend: GraphicsBackend? = nil,
                    minWidth: Int? = nil, minHeight: Int? = nil, allowLargerThanScreen: Bool? = nil) {
            self.title = title
            self.width = width
            self.height = height
            self.vsync = vsync
            self.quality = quality
            self.showDebugOverlay = showDebugOverlay
            self.renderResolution = renderResolution
            self.upscaler = upscaler
            self.upscalerSharpness = upscalerSharpness
            self.msaa = msaa
            self.backend = backend
            self.minWidth = minWidth
            self.minHeight = minHeight
            self.allowLargerThanScreen = allowLargerThanScreen
        }

        /// `renderResolution` parsed; nil when unset or invalid.
        public var parsedRenderResolution: RenderResolution? { renderResolution.flatMap { RenderResolution($0) } }

        /// `upscaler` parsed, with `upscalerSharpness` applied; nil when unset or invalid.
        public var parsedUpscaler: Upscaler? {
            guard let text = upscaler, var result = Upscaler(text) else { return nil }
            if let sharpness = upscalerSharpness {
                switch result {
                case .fsr1: result = .fsr1(sharpness: sharpness)
                case .taau: result = .taau(sharpness: sharpness)
                case .fsr3: result = .fsr3(sharpness: sharpness)
                case .bilinear, .metalFXSpatial, .metalFXTemporal: break
                }
            }
            return result
        }

        public var isEmpty: Bool { self == Window() }
    }

    /// The physics simulation.
    public struct Physics: Equatable, Sendable, Codable {
        /// 3D gravity in m/s² (default [0, -9.81, 0]).
        public var gravity: Vec3?
        /// 2D gravity in m/s² (default [0, -9.81]).
        public var gravity2D: Vec2?
        /// Seconds per fixed update step (default 1/60).
        public var fixedTimestep: Double?

        public init(gravity: Vec3? = nil, gravity2D: Vec2? = nil, fixedTimestep: Double? = nil) {
            self.gravity = gravity
            self.gravity2D = gravity2D
            self.fixedTimestep = fixedTimestep
        }

        public var isEmpty: Bool { self == Physics() }
    }

    public var window: Window?
    public var physics: Physics?

    public init(window: Window? = nil, physics: Physics? = nil) {
        self.window = window
        self.physics = physics
    }

    /// Whether nothing is set (then `Project.json` leaves `runtime` out).
    public var isEmpty: Bool { (window?.isEmpty ?? true) && (physics?.isEmpty ?? true) }

    /// The allowed window sizes and fixed timesteps.
    public static let windowSizeRange = 64...16384
    /// The allowed MSAA sample counts.
    public static let msaaCounts = [1, 2, 4, 8]
    public static let fixedTimestepRange: ClosedRange<Double> = (1.0 / 1000)...(1.0 / 5)

    /// Why these settings can't be used, or nil when they can.
    public func validationError() -> String? {
        if let width = window?.width, !Self.windowSizeRange.contains(width) {
            return "runtime.window.width must be in \(Self.windowSizeRange.lowerBound)...\(Self.windowSizeRange.upperBound)"
        }
        if let height = window?.height, !Self.windowSizeRange.contains(height) {
            return "runtime.window.height must be in \(Self.windowSizeRange.lowerBound)...\(Self.windowSizeRange.upperBound)"
        }
        if let text = window?.renderResolution, RenderResolution(text) == nil {
            return "runtime.window.renderResolution '\(text)' isn't a resolution (native, 720p, 1080p, 4k, 1920x1080, quality, balanced, performance, ultraperformance, 1.5x…)"
        }
        if let size = window?.parsedRenderResolution?.size,
           !(Self.windowSizeRange.contains(size.width) && Self.windowSizeRange.contains(size.height)) {
            return "runtime.window.renderResolution must be \(Self.windowSizeRange.lowerBound)...\(Self.windowSizeRange.upperBound) on each side"
        }
        if case .scaled(let factor)? = window?.parsedRenderResolution, !(factor.isFinite && factor >= 1 && factor <= 8) {
            return "runtime.window.renderResolution scale factor must be 1x...8x"
        }
        if let text = window?.upscaler, Upscaler(text) == nil {
            return "runtime.window.upscaler '\(text)' isn't an upscaler (bilinear, fsr1, metalfx, metalfx-temporal, taau, fsr3)"
        }
        if let sharpness = window?.upscalerSharpness, !(sharpness.isFinite && (0...4).contains(sharpness)) {
            return "runtime.window.upscalerSharpness must be between 0 and 4"
        }
        if let msaa = window?.msaa, !Self.msaaCounts.contains(msaa) { return "runtime.window.msaa must be 1, 2, 4 or 8" }
        if let width = window?.minWidth, !Self.windowSizeRange.contains(width) {
            return "runtime.window.minWidth must be in \(Self.windowSizeRange.lowerBound)...\(Self.windowSizeRange.upperBound)"
        }
        if let height = window?.minHeight, !Self.windowSizeRange.contains(height) {
            return "runtime.window.minHeight must be in \(Self.windowSizeRange.lowerBound)...\(Self.windowSizeRange.upperBound)"
        }
        if let step = physics?.fixedTimestep, !(step.isFinite && Self.fixedTimestepRange.contains(step)) {
            return "runtime.physics.fixedTimestep must be between 0.001 and 0.2 seconds"
        }
        if let g = physics?.gravity, !(g.x.isFinite && g.y.isFinite && g.z.isFinite) { return "runtime.physics.gravity must be finite" }
        if let g = physics?.gravity2D, !(g.x.isFinite && g.y.isFinite) { return "runtime.physics.gravity2D must be finite" }
        return nil
    }

    /// Lays the window settings over `config`.
    public func apply(to config: inout EngineConfig) {
        guard let window else { return }
        if let title = window.title, !title.isEmpty { config.title = title }
        if let width = window.width { config.width = width }
        if let height = window.height { config.height = height }
        if let vsync = window.vsync { config.vsync = vsync }
        if let quality = window.quality { config.quality = quality }
        if let overlay = window.showDebugOverlay { config.showDebugOverlay = overlay }
        if let resolution = window.parsedRenderResolution { config.renderResolution = resolution }
        if let upscaler = window.parsedUpscaler { config.upscaler = upscaler }
        if let msaa = window.msaa { config.sampleCount = msaa }
        if let backend = window.backend { config.backend = backend }
        if window.minWidth != nil || window.minHeight != nil {
            config.minimumWindowSize = (window.minWidth ?? Self.windowSizeRange.lowerBound, window.minHeight ?? Self.windowSizeRange.lowerBound)
        }
        if let larger = window.allowLargerThanScreen { config.allowsWindowLargerThanScreen = larger }
    }

    /// Sets `world`'s fixed timestep.
    @MainActor
    public func apply(to world: World) {
        if let step = physics?.fixedTimestep, step.isFinite, step > 0 { world.fixedTimestep = step }
    }

    /// Sets `physics`' gravity.
    @MainActor
    public func apply(to physics: PhysicsWorld) {
        if let gravity = self.physics?.gravity { physics.gravity = gravity }
    }

    /// Sets `physics`' gravity.
    @MainActor
    public func apply(to physics: PhysicsWorld2D) {
        if let gravity = self.physics?.gravity2D { physics.gravity = gravity }
    }
}
