// WebGPU backend smoke test: renders a lit, textured, shadowed scene with GPU particles and UI
// through `WebGPURenderDevice` in a browser, driving the frame loop itself (no `Engine`).
//
// Build and run (macOS, Chromium from Playwright in ~/.acro-webtools):
//   Spikes/WebGPUSmoke/web/run.sh [mode ...]
// Modes (`globalThis.acroSmokeMode`, set by the page from `?mode=`): msaa (default), fsr1, taau,
// hdr (post-processing), bilinear. The page (web/index.html) creates the WebGPU device and canvas,
// sets `globalThis.acro = { adapter, device, context, format }`, mounts the engine's shaders and
// fonts at /engine, and calls `globalThis.acroSmokeFrame()` from requestAnimationFrame.
import JavaScriptKit
import EngineCore
import EngineGraphics
import EngineBackends

do {
    let mode = JSObject.global.acroSmokeMode.string ?? "msaa"
    let device = try WebGPURenderDevice(sampleCount: SmokeScene.sampleCount(mode: mode))
    let smoke = try SmokeScene(device: device, mode: mode)
    print("smoke: \(device.deviceName), \(device.sampleCount)x MSAA, max texture \(device.maxTextureSize), "
        + "BC \(device.supports(.bc7Unorm)), ASTC \(device.supports(.astc4x4Unorm)), fsr3 \(device.supports(.fsr3()))")
    let tick = JSClosure { _ in
        MainActor.assumeIsolated {
            smoke.frame(width: Int(JSObject.global.acroCanvasWidth.number ?? 960),
                        height: Int(JSObject.global.acroCanvasHeight.number ?? 540))
            JSObject.global.acroSmokePassTimes = .string(device.gpuPassTimes.map { "\($0.name)=\($0.seconds)" }.joined(separator: ","))
            JSObject.global.acroSmokeErrors = .number(Double(device.errorCount))
        }
        return .undefined
    }
    JSObject.global.acroSmokeFrame = .object(tick)
} catch {
    print("smoke: setup failed: \(error)")
    JSObject.global.acroSmokeFailed = .string("\(error)")
}
