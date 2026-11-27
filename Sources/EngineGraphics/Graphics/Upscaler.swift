#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// How an offscreen scene image (see `RenderResolution`) is scaled into the window.
public enum Upscaler: Equatable, Sendable, CustomStringConvertible {
    /// One bilinear tap per pixel. Cheap, soft when enlarging.
    case bilinear
    /// AMD FidelityFX Super Resolution 1: edge-adaptive upsampling (EASU) followed by
    /// contrast-adaptive sharpening (RCAS). `sharpness` is in stops: 0 is the sharpest,
    /// each +1 halves the sharpening. Works on every backend.
    case fsr1(sharpness: Float = 0.2)
    /// Apple's MetalFX spatial scaler (Metal backend only).
    case metalFXSpatial
    /// Apple's MetalFX temporal scaler (Metal backend only). Temporal: see `isTemporal`.
    case metalFXTemporal
    /// Temporal anti-aliasing upsample: accumulates jittered frames into a history at the
    /// output size, reprojected with motion vectors and clamped to the current frame's
    /// neighborhood, then sharpened with RCAS (`sharpness` in stops, as for `fsr1`). Works on
    /// every backend. Temporal: see `isTemporal`.
    case taau(sharpness: Float = 0.5)
    /// AMD FidelityFX Super Resolution 3.1's upscaler (compute; not frame generation): depth- and
    /// motion-based reprojection with disocclusion, shading-change and thin-feature (lock)
    /// detection, Lanczos accumulation at the output size, then RCAS (`sharpness` in stops, as for
    /// `fsr1`; 0.4 is the SDK sample's 0.8). Works on every backend. Temporal: see `isTemporal`.
    case fsr3(sharpness: Float = 0.4)

    /// Parses `bilinear`, `fsr1`, `fsr1:<sharpness>`, `metalfx` (spatial), `metalfx-temporal`,
    /// `taau`, `taau:<sharpness>`, `fsr3` or `fsr3:<sharpness>`.
    public init?(_ string: String) {
        let text = string.lowercased().trimmingCharacters(in: .whitespaces)
        switch text {
        case "bilinear": self = .bilinear
        case "fsr", "fsr1": self = .fsr1()
        case "metalfx", "metalfx-spatial": self = .metalFXSpatial
        case "metalfx-temporal": self = .metalFXTemporal
        case "taau": self = .taau()
        case "fsr3": self = .fsr3()
        default:
            let parts = text.split(separator: ":")
            guard parts.count == 2, let sharpness = Float(parts[1]), sharpness >= 0 else { return nil }
            switch parts[0] {
            case "fsr1", "fsr": self = .fsr1(sharpness: sharpness)
            case "taau": self = .taau(sharpness: sharpness)
            case "fsr3": self = .fsr3(sharpness: sharpness)
            default: return nil
            }
        }
    }

    /// Temporal upscalers accumulate detail over frames. They need the game to jitter its
    /// projection (`Engine.jittered(_:)`) and write motion vectors
    /// (`PipelineDescriptor.writesMotionVectors`); the engine keeps the scene's depth for them
    /// and renders the scene without MSAA.
    public var isTemporal: Bool {
        switch self {
        case .metalFXTemporal, .taau, .fsr3: true
        case .bilinear, .fsr1, .metalFXSpatial: false
        }
    }

    public var description: String {
        switch self {
        case .bilinear: "bilinear"
        case .fsr1(let sharpness): "FSR 1 (sharpness \(sharpness))"
        case .metalFXSpatial: "MetalFX spatial"
        case .metalFXTemporal: "MetalFX temporal"
        case .taau(let sharpness): "TAAU (sharpness \(sharpness))"
        case .fsr3(let sharpness): "FSR 3 (sharpness \(sharpness))"
        }
    }
}

/// Push constants of `fsr_easu` (16 bytes).
package struct EasuConstants: BitwiseCopyable  {
    /// Input size / output size.
    var scale: Vec2
    /// Input size - 1, for clamping loads.
    var inputMax: SIMD2<Int32>

    package init(input: (width: Int, height: Int), output: (width: Int, height: Int)) {
        scale = Vec2(Float(input.width) / Float(output.width), Float(input.height) / Float(output.height))
        inputMax = SIMD2(Int32(input.width - 1), Int32(input.height - 1))
    }
}

/// Push constants of `fsr_rcas` (24 bytes).
package struct RcasConstants: BitwiseCopyable {
    /// Top-left of the output rectangle in the window, in pixels.
    var origin: SIMD2<Int32>
    var inputMax: SIMD2<Int32>
    /// exp2(-stops); 0 copies without sharpening.
    var sharpness: Float
    var padding: Float = 0

    package init(rect: (x: Int, y: Int, width: Int, height: Int), sharpness: Float) {
        origin = SIMD2(Int32(rect.x), Int32(rect.y))
        inputMax = SIMD2(Int32(rect.width - 1), Int32(rect.height - 1))
        self.sharpness = sharpness
    }
}

extension Upscaler {
    /// The RCAS factor for the final window pass (0 = plain copy). FSR 3 sharpens in its own RCAS pass.
    package var rcasSharpness: Float {
        switch self {
        case .fsr1(let sharpness), .taau(let sharpness): exp2(-sharpness)
        case .bilinear, .metalFXSpatial, .metalFXTemporal, .fsr3: 0
        }
    }

    /// What renders into the upscale target before the window pass, ignoring parameters.
    package var firstStage: UpscalerStage {
        switch self {
        case .bilinear: .none
        case .fsr1: .easu
        case .metalFXSpatial: .metalFXSpatial
        case .metalFXTemporal: .metalFXTemporal
        case .taau: .taau
        case .fsr3: .fsr3
        }
    }
}

extension Upscaler {
    /// What to try, in order, when this upscaler can't run: FSR 3 and MetalFX temporal fall back
    /// to TAAU, then FSR 1, then bilinear; MetalFX spatial and TAAU to FSR 1, then bilinear.
    /// Sharpness carries over (all three use RCAS stops).
    package var fallbacks: [Upscaler] {
        switch self {
        case .fsr3(let sharpness): [.taau(sharpness: sharpness), .fsr1(sharpness: sharpness), .bilinear]
        case .metalFXTemporal: [.taau(), .fsr1(), .bilinear]
        case .taau(let sharpness): [.fsr1(sharpness: sharpness), .bilinear]
        case .metalFXSpatial: [.fsr1(), .bilinear]
        case .fsr1: [.bilinear]
        case .bilinear: []
        }
    }

    /// `requested` if `unsupported` returns nil for it (no reason it can't run), else the first of
    /// its `fallbacks` that can, with the reason the requested one couldn't (nil when it ran).
    /// Bilinear always runs, so this never fails.
    package static func choose(_ requested: Upscaler, unsupported: (Upscaler) -> String?)
        -> (upscaler: Upscaler, reason: String?) {
        guard let reason = unsupported(requested) else { return (requested, nil) }
        let chosen = requested.fallbacks.first { unsupported($0) == nil } ?? .bilinear
        return (chosen, reason)
    }
}

/// The first stage of an upscaler (see `Upscaler.firstStage`); backends key their targets on it.
package enum UpscalerStage: Equatable {
    case none, easu, metalFXSpatial, metalFXTemporal, taau, fsr3
}
