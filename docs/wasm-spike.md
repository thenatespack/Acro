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

### In a browser (W1B)

```sh
Scripts/web-player.sh <game.pack> [--release] [--port 8080]   # then open http://localhost:8080/
```

It packages WasmPlayer with PackageToJS (`swift package ... js --product WasmPlayer`), assembles
`Web/index.html` + `Web/loader.js`, the PackageToJS output (`app/`), the WASI shim (`vendor/`),
the engine resources (`engine/` + `manifest.json`) and the pack in `.build-wasm/web-player`, and
serves it. The loader sets up WebGPU (`globalThis.acro = { adapter, device, context, format, canvas }`),
fetches the pack (handed to Swift as `acro.pack`, opened with `AssetPack(data:)`) and the engine
resources (put in the shim's in-memory filesystem at `/engine`, so `Bundle.engineResourceURL`
works unchanged), and runs `main`. On WASI `GamePlayer.main` calls `Engine.start` and returns
(PackageToJS builds a WASI reactor, so the instance stays alive; `exit` would end it);
`WebFrameDriver` then calls `Engine.tick` from `requestAnimationFrame` and `finish` at the end.
Errors go to the console and `acro.onError` (shown on the page). `?probe=<n>` (spike only) runs a
stand-in tick n times when the engine can't start.

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

## Waves

Each wave is three lanes that don't edit the same code. Agents work in their own worktrees and
are merged into `wasm-spike` one at a time.

**Shared rules:**
- Build with `ENGINE_WASM=1 ~/.swiftly/bin/swift build --swift-sdk swift-6.4.2-RELEASE_wasm --scratch-path .build-wasm`.
- JavaScriptKit 0.63.0 is already a dependency of EngineBackends and EngineAudio in Wasm builds.
  Its `js` plugin (`swift package ... js --product X`) packages a product with its JS glue.
- Browser tests use Playwright's Chromium from `~/.acro-webtools` (`import { chromium } from 'playwright'`,
  `chromium.launch({ channel: 'chromium', args: ['--enable-unsafe-webgpu'] })`, page served from
  `http://localhost`). That gives a real Apple Metal WebGPU adapter with BC and ASTC.
- WebGPU's adapter and device requests are Promises, and the engine starts synchronously. So the
  page's JS gets the `GPUDevice` and canvas before starting the wasm and passes them in through
  globals (`globalThis.acro = { device, canvas, ... }`). Swift reads them synchronously.

### Wave W1
- **W1A: WebGPU render device.** `Sources/EngineBackends/Backends/WebGPU/` implements
  `RenderDevice` through JavaScriptKit. `GraphicsBackend.webgpu`. WGSL fields in `ShaderSource`.
  `compile-shaders.sh` adds a SPIR-V → WGSL step (naga-cli) and commits the `.wgsl` files.
  Push constants become a uniform buffer. Fallbacks for anything WebGPU lacks.
- **W1B: Web runtime host.** `Engine.run` split into `start` / `tick` / `finish` (native `run`
  unchanged on top of them). A `requestAnimationFrame` driver for WASI. The page and JS loader
  (PackageToJS output, WebGPU device and canvas setup, fetching the pack and engine resources
  into memory). `AssetPack` loading from memory. Engine resources without a WASI preopened folder.
- **W1C: Canvas window, input and audio.** `CanvasWindow: PlatformWindow` (size, devicePixelRatio,
  keyboard, mouse, wheel, pointer lock, cursor, focus). A Gamepad API `GamepadSource`.
  `WebAudioDevice: AudioDevice` (AudioWorklet fed from the main thread; no SharedArrayBuffer
  needed).

### Wave W2
- **W2A: Integration.** `Engine` picks WebGPU and `CanvasWindow` on WASI. SampleGame and Demo
  scenes run in Chromium. Screenshots compared with Metal. Fix what breaks.
- **W2B: Web export.** A "Web" target in GameExporter and the editor (Wasm build, `wasm-opt`,
  loader, pack, the `@_extern(c)` entry point). One folder that a static file server can host.
- **W2C: Size and robustness.** Runtime modules on `FoundationEssentials` (drop ICU), vendored
  zlib, CTextureCodec without threads (astc-encoder `std::mutex` shim, for the web editor),
  the 32-bit `Int` audit, a size budget check.
