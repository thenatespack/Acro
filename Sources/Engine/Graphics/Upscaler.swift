import Foundation

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

    /// Parses `bilinear`, `fsr1`, `fsr1:<sharpness>`, or `metalfx`.
    public init?(_ string: String) {
        let text = string.lowercased().trimmingCharacters(in: .whitespaces)
        switch text {
        case "bilinear": self = .bilinear
        case "fsr", "fsr1": self = .fsr1()
        case "metalfx": self = .metalFXSpatial
        default:
            let parts = text.split(separator: ":")
            guard parts.count == 2, parts[0] == "fsr1" || parts[0] == "fsr", let sharpness = Float(parts[1]), sharpness >= 0
            else { return nil }
            self = .fsr1(sharpness: sharpness)
        }
    }

    public var description: String {
        switch self {
        case .bilinear: "bilinear"
        case .fsr1(let sharpness): "FSR 1 (sharpness \(sharpness))"
        case .metalFXSpatial: "MetalFX spatial"
        }
    }
}

/// Push constants of `fsr_easu` (16 bytes).
struct EasuConstants {
    /// Input size / output size.
    var scale: Vec2
    /// Input size - 1, for clamping loads.
    var inputMax: SIMD2<Int32>

    init(input: (width: Int, height: Int), output: (width: Int, height: Int)) {
        scale = Vec2(Float(input.width) / Float(output.width), Float(input.height) / Float(output.height))
        inputMax = SIMD2(Int32(input.width - 1), Int32(input.height - 1))
    }
}

/// Push constants of `fsr_rcas` (24 bytes).
struct RcasConstants {
    /// Top-left of the output rectangle in the window, in pixels.
    var origin: SIMD2<Int32>
    var inputMax: SIMD2<Int32>
    /// exp2(-stops); 0 copies without sharpening.
    var sharpness: Float
    var padding: Float = 0

    init(rect: (x: Int, y: Int, width: Int, height: Int), sharpness: Float) {
        origin = SIMD2(Int32(rect.x), Int32(rect.y))
        inputMax = SIMD2(Int32(rect.width - 1), Int32(rect.height - 1))
        self.sharpness = sharpness
    }
}

extension Upscaler {
    /// The RCAS factor for the final window pass (0 = plain copy).
    var rcasSharpness: Float {
        if case .fsr1(let sharpness) = self { return exp2(-sharpness) }
        return 0
    }
}
