// WebAssembly spike (docs/wasm-spike.md): the `main.swift` GameExporter generates for a player,
// with SampleGame linked in statically. Only part of the package when ENGINE_WASM=1.
//
// Unlike the generated one, the entry point is declared with the C calling convention
// (`@_extern(c)`), as SampleGame defines it (`@_cdecl`). The generated `@_silgen_name`
// declaration uses Swift's convention, which on wasm32 adds parameters: native targets
// tolerate the mismatch, WebAssembly traps ("indirect call type mismatch").
import Engine
@_extern(c, "acro_module_v1") func gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32
GamePlayer.main(module: { gameModuleEntry($0) })

#if os(WASI)
import Foundation
import JavaScriptKit

// Spike-only check of the browser frame driver while there's no WebGPU device or canvas
// window to start the engine with: `acro.probeFrames = n` (`?probe=n` on the page) runs a
// stand-in `tick` from requestAnimationFrame n times, logging each frame's timestamp.
if !WebFrameDriver.isRunning, let count = WebHost.acro.probeFrames.number, count > 0 {
    // The engine resources the page fetched, read by URL from the WASI shim's memory filesystem.
    do {
        let font = try Font.bundledUI()
        let shader = try ShaderSource.load(compute: "particle_spawn", bundle: .engineResources)
        print("probe: engine resources from \(Bundle.engineResources.bundlePath): Inter-Regular.ttf line height \(font.lineHeight), "
              + "particle_spawn.comp.spv \(shader.spirvCompute?.count ?? 0) bytes")
    } catch {
        print("probe: engine resources failed: \(error)")
    }
    var frame = 0
    WebFrameDriver.start(tick: {
        frame += 1
        let now = JSObject.global.performance.object!.now!().number ?? 0
        print("probe tick \(frame) at \(now) ms")
        return frame < Int(count)
    }, finish: {
        print("probe finished after \(frame) frames")
    })
}
#endif
