import Testing
@testable import EngineGraphics

/// `Upscaler.choose`: an upscaler a backend can't run falls back (FSR 3 → TAAU → FSR 1 → bilinear)
/// instead of being refused.
@Suite struct UpscalerFallbackTests {
    /// What the web backends support: WebGPU everything but FSR 3 and MetalFX; WebGL 2 without
    /// float color buffers only bilinear and FSR 1.
    static func webGPU(_ upscaler: Upscaler) -> String? {
        switch upscaler {
        case .fsr3, .metalFXSpatial, .metalFXTemporal: "not supported on webgpu"
        default: nil
        }
    }

    static func webGL2WithoutFloat(_ upscaler: Upscaler) -> String? {
        switch upscaler {
        case .bilinear, .fsr1: nil
        default: "not supported on webgl2"
        }
    }

    @Test func upscalerFallbackFSR3PicksTAAUWithItsSharpness() {
        let (chosen, reason) = Upscaler.choose(.fsr3(sharpness: 0.3), unsupported: Self.webGPU)
        #expect(chosen == .taau(sharpness: 0.3))
        #expect(reason == "not supported on webgpu")
    }

    @Test func upscalerFallbackSkipsUnsupportedSteps() {
        #expect(Upscaler.choose(.fsr3(), unsupported: Self.webGL2WithoutFloat).upscaler == .fsr1(sharpness: 0.4))
        #expect(Upscaler.choose(.metalFXTemporal, unsupported: Self.webGL2WithoutFloat).upscaler == .fsr1())
        #expect(Upscaler.choose(.metalFXSpatial, unsupported: Self.webGPU).upscaler == .fsr1())
        #expect(Upscaler.choose(.metalFXTemporal, unsupported: Self.webGPU).upscaler == .taau())
        #expect(Upscaler.choose(.fsr1(), unsupported: { _ in "nothing runs" }).upscaler == .bilinear)
        #expect(Upscaler.choose(.fsr3(), unsupported: { _ in "nothing runs" }).upscaler == .bilinear)
    }

    @Test func upscalerFallbackKeepsSupportedRequest() {
        for upscaler in [Upscaler.bilinear, .fsr1(), .taau(sharpness: 1)] {
            let (chosen, reason) = Upscaler.choose(upscaler, unsupported: Self.webGPU)
            #expect(chosen == upscaler)
            #expect(reason == nil)
        }
    }

    @Test func upscalerFallbackChainsEndInBilinear() {
        for upscaler in [Upscaler.fsr3(), .metalFXTemporal, .metalFXSpatial, .taau(), .fsr1()] {
            #expect(upscaler.fallbacks.last == .bilinear)
            #expect(!upscaler.fallbacks.contains(upscaler))
        }
        #expect(Upscaler.bilinear.fallbacks.isEmpty)
    }
}
