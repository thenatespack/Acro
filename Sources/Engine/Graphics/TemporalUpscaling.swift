import Foundation

// Conventions shared by the temporal upscalers (see `Upscaler.isTemporal`):
//
// - Jitter is in render-target pixels, x right and y down, each axis in [-0.5, 0.5). A jitter
//   of (jx, jy) shifts the rendered image by that much: the projection is offset by
//   (2 jx / width, -2 jy / height) in NDC (`Mat4.jittered(clipOffset:)`).
// - Motion vectors are written by the scene pass into a second color attachment (RG16F,
//   `[[color(1)]]` / `layout(location = 1) out`). Each is the previous frame's texture
//   coordinate of the surface minus the current one (UV units: [0, 1] across the render
//   target, y down), computed from unjittered positions:
//   `(prevClip.xy / prevClip.w - clip.xy / clip.w) * (0.5, -0.5)`. 0 means "didn't move".
// - Depth is the scene's depth buffer, standard (near 0) or reversed-Z (near 1).

/// Sub-pixel camera jitter for temporal upscalers: a Halton (2, 3) sequence, so each phase
/// lands between the earlier ones and every few frames cover the pixel evenly.
public enum TemporalJitter {
    /// Element `index` (≥ 1) of the Halton sequence in `base`, in [0, 1).
    public static func halton(_ index: Int, base: Int) -> Float {
        var f: Float = 1, result: Float = 0, i = index
        while i > 0 {
            f /= Float(base)
            result += f * Float(i % base)
            i /= base
        }
        return result
    }

    /// Phases before the sequence repeats: 8 × (output / render width)², at least 8, so each
    /// output pixel receives about 8 samples per cycle (as FSR 2 does).
    public static func phaseCount(renderWidth: Int, outputWidth: Int) -> Int {
        let ratio = Float(outputWidth) / Float(max(renderWidth, 1))
        return max(8, Int((8 * ratio * ratio).rounded(.up)))
    }

    /// The jitter of frame `frame` in render pixels, each axis in [-0.5, 0.5).
    public static func offset(frame: Int, phaseCount: Int) -> Vec2 {
        let index = frame % max(phaseCount, 1) + 1
        return Vec2(halton(index, base: 2) - 0.5, halton(index, base: 3) - 0.5)
    }

    /// `pixels` of jitter as an NDC offset for a render target of `renderSize` (y flips: NDC is y-up).
    public static func clipOffset(_ pixels: Vec2, renderSize: (width: Int, height: Int)) -> Vec2 {
        Vec2(2 * pixels.x / Float(renderSize.width), -2 * pixels.y / Float(renderSize.height))
    }
}

extension Mat4 {
    /// This projection (or view-projection) with its output shifted by `clipOffset` in NDC.
    /// Adds `clipOffset * w` to clip x and y, so the shift is the same at every depth.
    public func jittered(clipOffset: Vec2) -> Mat4 {
        Mat4.translation(Vec3(clipOffset.x, clipOffset.y, 0)) * self
    }
}

/// Per-frame inputs of a temporal upscaler, set by `Engine` before `beginFrame`.
public struct TemporalInputs: Sendable, Equatable {
    /// This frame's projection jitter in render pixels (`Engine.jitter`).
    public var jitter: Vec2
    /// Discard the accumulated history: camera cut, resize, scene switch, upscaler change.
    public var resetHistory: Bool
    /// Reversed-Z depth (near = 1, cleared to 0).
    public var reversedDepth: Bool

    public init(jitter: Vec2 = .zero, resetHistory: Bool = true, reversedDepth: Bool = false) {
        self.jitter = jitter
        self.resetHistory = resetHistory
        self.reversedDepth = reversedDepth
    }
}

/// Push constants of `taau` (56 bytes).
struct TaauConstants {
    /// Render pixels per output pixel, and the reverse.
    var inputPerOutput: Vec2
    var outputPerInput: Vec2
    var jitter: Vec2
    var outputSize: Vec2
    var inputMax: SIMD2<Int32>
    var outputMax: SIMD2<Int32>
    /// 1 ignores the history (nothing valid accumulated yet).
    var reset: Float
    var reversedDepth: Float

    init(input: (width: Int, height: Int), output: (width: Int, height: Int), inputs: TemporalInputs, reset: Bool) {
        let inputSize = Vec2(Float(input.width), Float(input.height))
        outputSize = Vec2(Float(output.width), Float(output.height))
        inputPerOutput = inputSize / outputSize
        outputPerInput = outputSize / inputSize
        jitter = inputs.jitter
        inputMax = SIMD2(Int32(input.width - 1), Int32(input.height - 1))
        outputMax = SIMD2(Int32(output.width - 1), Int32(output.height - 1))
        self.reset = reset ? 1 : 0
        reversedDepth = inputs.reversedDepth ? 1 : 0
    }
}
