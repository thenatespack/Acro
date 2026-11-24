# WebAssembly spike (2026-11-23)

The question: how hard would a browser (WebGPU) export be? This spike builds the engine for
`wasm32-unknown-wasip1` with the official Swift Wasm SDK and runs an exported-style player
under a WASI runtime, to find what breaks before any WebGPU work.

**Result: the whole engine (every module under `Engine`, plus SampleGame) compiles, links and
runs on wasm32.** The player parses its arguments, registers components, mounts a cooked
pack, builds the game and its UI (fonts, shaders), and stops at
`The Vulkan backend was not compiled in`: the point where a WebGPU backend and a canvas
window would take over. No blocker was found below the graphics/window/audio layer.

## Reproducing

```sh
swiftly install 6.4.2                     # open-source toolchain (Xcode's can't use the SDK)
swift sdk install <swift-6.4.2-RELEASE_wasm.artifactbundle.tar.gz>   # from swift.org/install
ENGINE_WASM=1 ~/.swiftly/bin/swift build -c release --swift-sdk swift-6.4.2-RELEASE_wasm \
    --scratch-path .build-wasm --product WasmPlayer
B=$PWD/.build-wasm/out/Products/Release-webassembly-wasm32
wasmkit run --dir <pack dir> --dir $B/Acro_EngineCore.bundle \
    --env ENGINE_RESOURCES=$B/Acro_EngineCore.bundle $B/WasmPlayer.wasm --pack <pack dir>/Game.pack
```

`wasmkit` ships in the swiftly toolchain's `usr/bin`. `ENGINE_WASM=1` is a manifest switch
(the manifest runs on the host, so it can't see the target triple). Native builds ignore it.

## What had to change

| Problem | Change in the spike | Proper fix |
|---|---|---|
| No Dispatch, no threads (`wasip1`) | `concurrentPerform` runs in order; `JobSystem` is inline (0 workers); `runInBackground` runs inline; `FileWatcher` doesn't poll | Fine for v1. Threads later need `wasip1-threads` and cross-origin isolation (COOP/COEP) |
| `DispatchTime` | `monotonicNanoseconds()` (ContinuousClock) everywhere in the engine | Keep |
| Foundation doesn't re-export libc on WASI (`sinf`, ...) | `@_exported import WASILibc` in EngineCore | Keep |
| No signals | CrashReporter installs no handlers on WASI | Report traps from the JS side |
| No zlib in the sysroot | PNG writing and net snapshot compression are unavailable | Vendor zlib (or miniz) as a C target |
| astc-encoder needs `std::mutex` | CTextureCodec left out (encoding/decoding throw) | Fine: web builds load pre-encoded textures. Cook BC7 and ASTC, or uncompressed, per GPU |
| miniaudio needs pthreads | `CAudio` device functions are stubs on WASI | Web Audio (AudioWorklet) output pulling from the mixer |
| `.atomic` writes are unavailable | `Data.WritingOptions.engineAtomic` (`[]` on WASI) | Keep |
| MCP transports (sockets, stdio, URLSession) | Excluded from the target; GameMCP has no transport | Fine: not needed in a web game |
| Exporter / game-module builder and loader (`Process`, `dlopen`) | Excluded; `GameModuleError` moved to its own file | Fine: editor-side |
| **`Int` is 32-bit on wasm32** | Fixed a hash constant (MeshBuildSculpt) and the `mesh << 32 \| material` batch keys in ShadowMaps and RenderList: on 32-bit they silently became 0 and every batch would collide | **Audit**: only literals that overflow are compile errors. Shifts, byte counts and hash math can still be wrong without any warning |
| **Generated player `main.swift` traps** | `@_silgen_name("acro_module_v1")` declares the `@_cdecl` entry with Swift's calling convention; wasm traps on the signature mismatch (native tolerates it). Spike player uses `@_extern(c, …)` | Change GameExporter's template (needs the `Extern` experimental feature) |
| `Bundle.module` traps (it goes through `Bundle.main`) | `Bundle.engineResources` reads a folder named by `ENGINE_RESOURCES` | Ship engine resources inside the pack, or fetch them into a virtual filesystem |
| Foundation bug: `Bundle.url(forResource:withExtension:)` drops the extension's last character on WASI | `Bundle.engineResourceURL` builds paths directly on WASI (all 6 lookups) | Keep, and report upstream |

## Size

The release `WasmPlayer.wasm` with SampleGame is 117 MB unstripped and **70 MB stripped:
about 31 MB of code and 39 MB of data. That's 24.7 MB gzip or 15.7 MB brotli.** The data
section is probably mostly ICU tables pulled in through `import Foundation`
(FoundationInternationalization). Moving the runtime modules to `FoundationEssentials` should
remove most of it. `wasm-opt -Oz` and dead-code stripping of editor-only code would cut more.
A target of under 10 MB compressed looks realistic. Not measured: start-up time in a browser.

## What's left for a browser build

1. **WebGPU `RenderDevice`** (through JavaScriptKit), and a SPIR-V → WGSL step in
   `compile-shaders.sh` (Tint or Naga). Push constants become a small uniform buffer.
   `rgba16f` read-write storage images (FSR, some compute passes) need rework or a fallback.
2. **Main loop inversion**: `Engine.run` is a blocking `while` loop. The browser needs a
   per-frame `tick()` driven by `requestAnimationFrame`.
3. **Canvas `PlatformWindow`** and input (DOM keyboard and mouse events, the Gamepad API).
4. **Web Audio output.**
5. **Asset loading**: fetch the pack and engine resources into memory or a virtual filesystem
   instead of WASI preopened folders. Saves go to IndexedDB.
6. **Web export target** in GameExporter: Wasm build, `wasm-opt`, an HTML/JS loader with a
   WASI shim, and the pack. Includes the `@_extern(c)` entry-point fix.
7. Cleanup: vendored zlib, a FoundationEssentials-only runtime for size, the 32-bit `Int` audit.

None of this is blocked by the toolchain. The spike suggests about 3 roadmap waves:
(1) WebGPU backend and WGSL, (2) loop, window, input, audio and asset loading,
(3) export, size and the 32-bit audit.
