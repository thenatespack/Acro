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

### Running a game in the browser (W2A)

On WASI `Engine.init` creates `CanvasWindow` (`acro.canvas`) and `WebGPURenderDevice(sampleCount:)`
(`acro.adapter/device/context/format`); `.webgpu` is the default backend there. The loader asks
for every feature and the largest limits the adapter has.

```sh
Editor --cook Projects/SampleGame --out /tmp/pack          # or any cooked .pack (--gpu bc for non-Apple GPUs)
Scripts/web-player.sh /tmp/pack/SampleGame.pack --release  # open http://localhost:8080/ (Chrome, Edge, Safari 26)
Scripts/web-player.sh --demo                                # the Demo; ?args=--scene,<n or name>
node Spikes/WebPlayerCheck/run.mjs .build-wasm/web-player <out dir> [--query ...]   # Playwright check
```

Page options: `?env=ENGINE_OVERLAY=1,ENGINE_QUALITY=high,...` sets environment variables,
`?args=...` passes player arguments. `ENGINE_SCREENSHOT=/s.png` works as natively (fixed 1/60 s
steps, quits after the capture); the image goes to `acro.onScreenshot` (the loader keeps it as a
PNG data URL in `acro.screenshots`). The player puts frame and GPU pass times on `acro.stats`.

Nothing blocks the main thread: a whole frame is one `requestAnimationFrame` callback, Web Audio
is pumped from `setInterval`, `waitIdle` only delivers finished readbacks, and captures come back
a frame or more late (`RenderDevice.capturesArriveLate`: the engine matches each image to its
request). The shim's `poll_oneoff` throws, and the loader warns when anything calls it.
The page also has an empty in-memory `/tmp` (`TMPDIR`).

Results (2026-11-23, Playwright Chromium with `--enable-unsafe-webgpu`, Apple M5 through Metal,
release builds): SampleGame and 47 of the 53 Demo scenes run with **0 WebGPU validation errors**.
The engine's `ENGINE_SCREENSHOT` frames match the native Metal run: SampleGame differs by a mean
of 0.05 / 255, and 13 Demo scenes checked (shadows, UI, widgets, text, glTF, PBR, post, sprites,
HUD, sky, particles, fog, probes) are pixel-identical. Frames run at the display's 60 Hz
(requestAnimationFrame intervals 16.67 ms, p95 under 18 ms); the frame's work in its callback is
0.4 ms for SampleGame and 0.5 to 3 ms for most Demo scenes. Crowd (446 draws, single-threaded in
wasm) takes 48 ms (13.7 ms and a steady 60 fps after W2.5C; see "Performance"). GPU pass times
on Apple look cumulative (each pass's end minus the frame's first begin: post's bloom passes read
2.85, 3.19, 3.35...), so `gpuTime` (their sum) overstates.

Known gaps (W2A): the Images, Net, Net Character and Compression scenes stopped (zlib and the
texture codec, W2C); Forest and Fur stopped (`AssetDatabase` found no files). All fixed in W2.5A,
see below. Packs are cooked for one GPU family (ASTC for Apple, `--gpu bc` for the rest).

### Content gaps (W2.5A)

- **The four stopped scenes** run with zlib and the texture codec built for WASI (W2C), unchanged:
  Images, Net, Net Character and Compression have 0 WebGPU errors and their `ENGINE_SCREENSHOT`
  frames match Metal (mean difference 0.07, 0.07, 0.10 and 0.00 / 255).
- **Folders listed empty** in the browser: browser_wasi_shim 0.3.0 gives every directory entry
  `d_ino` 0, and Swift's `FileManager.contentsOfDirectory` skips such entries as deleted, so an
  `AssetDatabase` in the shim's filesystem found no files. The loader wraps `fd_readdir` and gives
  entries a nonzero inode (their cookie). With that Forest and Fur import their assets at run time
  in the browser; Forest also needed a 32-bit fix (`MeshBuildPart.applyingLookUVs`: `Int(UInt32)`
  of a name hash trapped above `Int32.max`).
- **Material graphs on WebGPU.** `MaterialGraphCompiler` emits the graph's IR as WGSL as well and
  replaces the body of `graphSurface_u0028_` (naga's name for `graphSurface()`) in
  `mesh_graph.frag.wgsl`, `mesh_graph_depth.frag.wgsl` and `decal_graph.frag.wgsl` (the
  compile-shaders.sh output of the unoptimized templates), the way it already splices MSL. It's
  text, so it runs in the browser with no shader compiler; the template's globals (`gUV`,
  `graphValues`, the five textures, `materialSampler`, the `g*` outputs) keep their GLSL names in
  naga's output. `MaterialGraphProgram.wgslFragment` / `wgslDepthFragment` / `wgslDecalFragment`
  feed graph pipelines, masked graph shadows and depth, and graph decals. The terrain splat shader
  already had WGSL (fixed shader); terrain graph layers are ordinary graph materials, so they draw
  now too. MaterialGraphTests validates the WGSL of every preset in all three templates with naga
  when it is installed. Demo scene `graphs` (new, number 54): a sphere per preset on a splat terrain
  with a lava graph layer, imported by an `AssetDatabase` at start. In Chromium: 0 WebGPU errors,
  `ENGINE_SCREENSHOT` mean difference 0.065 / 255 from Metal (0.22% of pixels over 16).
- **Saves on IndexedDB.** On WASI `UserData.directory(app:)` is `/userdata/<app>`. `Web/saves.js`
  (`openUserData()`) reads every stored file from IndexedDB (database `acro-userdata`, store
  `files`, one record per path) into an in-memory folder the loader mounts at `/userdata` before
  the wasm starts. `SaveGames` and `SettingsStore` call `UserData.changed()` after writing or
  removing files; on the web `Engine` sets `UserData.onChange` to call `acro.onUserDataChange()`,
  and saves.js writes the folder's changes back (puts and deletes in one transaction, skipping
  `AtomicFile`'s temporary files), and again on `pagehide` / hidden. Without IndexedDB saves last
  for the session. `node Spikes/WebPlayerCheck/saves.mjs .build-wasm/web-demo` checks it in
  Playwright: the Demo's `character` scene finds no quick save, F5 saves, the page reloads
  (`[acro] user data: 1 file(s) from IndexedDB`), F9 loads it (largest distance from the save
  0.0001 m).
- **Keys.** `Key` has punctuation (`minus`, `equal`, `semicolon`, `apostrophe`, `backslash`,
  `period`, `slash`) and keypad cases (`numpad0`…`numpad9`, `numpadDecimal`, `numpadAdd`,
  `numpadSubtract`, `numpadMultiply`, `numpadDivide`, `numpadEqual`), mapped by physical key in
  `CanvasWindow` (`KeyboardEvent.code`), `AppKitWindow` and `GLFWWindow` (Windows, Linux); the
  keypad's Enter is `enter` everywhere. A test checks that each native window maps every case.

Results (2026-11-24, same setup, release): **all 54 Demo scenes run with 0 WebGPU validation
errors** (the 53 of W2A plus `graphs`; each run 4 s in Chromium with input). `ENGINE_SCREENSHOT`
frames against Metal at 1280x720: graphs 0.065, images 0.069, compression 0.000, net 0.066, net
character 0.099, fur 0.28 mean / 255. Forest differs by 1.95 (6% of pixels): same triangle counts,
but the leaf cards' silhouettes differ, also with wind off; native runs are identical to each
other, so something in the tree's import (likely the generated leaf texture or its compression)
comes out differently on wasm32. Not investigated further.

Remaining gaps: Forest's leaves (above). The Demo's F5 quick save is also the browser's reload key outside Playwright (a
real F5 reloads the page; the save usually lands first, but the scene should use other keys on
the web). IndexedDB writes are asynchronous, so a save made right before the tab is killed can be
lost. The web editor (W3) will need the same `fd_readdir` fix in its own loader if it doesn't
reuse `Web/loader.js`.

### Web export (W2B)

A project exports to the web like to any other platform: **Web** in the editor's Export Game
dialog, `game.build` with `platform: "web"` (MCP), or

```sh
swift run Editor --build-game Projects/SampleGame --platform web [--config debug] [--out <dir>]
Scripts/web-player.sh --export Projects/SampleGame [--release]     # the same, then serves it
```

The result, `<out>/<Name>/` (default `<project>/Build/web/<Name>/`), is a static folder in the
layout `Web/loader.js` reads: `index.html`, `loader.js`, `app/` (PackageToJS output),
`vendor/browser_wasi_shim/`, `engine/` (only `Shaders/*.wgsl` and `Fonts/`, listed in
`engine/manifest.json`), `game.pack`, `player.json` and a `README.txt` on hosting it (any static
server; `.wasm` as `application/wasm`; a WebGPU browser). `GameExporterWeb.swift` has the details:
the same generated player package as native exports (in `.build/game-export-web/<Target>`, with a
JavaScriptKit dependency for the `js` plugin), built with `ENGINE_WASM=1` by
`~/.swiftly/bin/swift package --swift-sdk swift-6.4.2-RELEASE_wasm js -c <cfg> --no-optimize`,
DWARF stripped at link time in release, then `wasm-opt -Oz` when binaryen is installed. The
generated `main.swift` now declares the entry point with `@_extern(c)` (and the `Extern` feature)
for every platform. A missing toolchain or SDK disables Web in the dialog with how to install it
(`ACRO_WASM_SWIFT`, `ACRO_WASM_SDK` and `ACRO_WASM_OPT` override the defaults).

SampleGame, release (2026-11-23): the first build takes about 11 minutes (all of Engine for
wasm32); the folder is 59 MB: a 54.5 MB `.wasm` (79.0 MB linked; `-Os` gives 55.0 MB),
**21.5 MB gzip -9, 14.2 MB brotli -q 11**, a 1.7 MB pack (BC textures, the Web default), 3 MB
of WGSL and fonts. After W2A the exported folder plays: served on localhost and run with
`Spikes/WebPlayerCheck/run.mjs` in Playwright Chromium (Apple M5), it starts in 0.85 s, renders
the scene at 60 Hz with 0 WebGPU errors, and every request (only `.wgsl` shaders) succeeds.

`Scripts/web-player.sh <pack>` still builds the spike's `WasmPlayer` (SampleGame linked in) with
a pack you cooked and copies the whole engine bundle (Metal and SPIR-V too); `--export` uses the
exporter instead.

### Download size (W2.5B)

The test case is the Racing project (one scene, 27 assets): its pack was 126.5 MB, 89.9 MB of it
meshes. Pack version 2 compresses blobs, for every platform (native players read the same packs):

- **Meshes** (`PackMeshCodec.swift`, encoding `mesh1`): positions on a power-of-two grid, 16 bits
  across the mesh's largest extent and never coarser than 2^-10 (about 1 mm); the grid is absolute,
  so meshes of similar size that share an edge round it the same way. Normals and tangents
  octahedral at 12 bits (under 0.05°), tangent w 16-bit with 0 kept as 0 (no tangents), UVs on a
  16-bit grid no coarser than 2^-14. Indices, skin joints and paint are exact, skin weights 16-bit.
  Each value is a stream of integers, delta coded, zigzagged and split into byte planes, then the
  whole payload is deflated (zlib: the system one natively, the vendored one in Wasm builds).
  Meshes the encoder can't quantize within those bounds (a zero normal, NaN, out-of-range weights)
  are deflated losslessly instead. A meshopt-style codec (meshoptimizer's vertex and index codecs
  on the same quantized data, then deflate) came out 9.7 MB against 8.9 MB for the byte planes, so
  there's no third-party codec.
- **Everything else** (textures, scenes, baked navmeshes and probes, audio) is deflated when that
  saves at least 10%. Racing's BC7 textures save 36%.
- `AssetPackBlob` gains `encoding` and `rawSize`; the hash is of the stored bytes. `AssetPack`
  decodes in `bytes(of:)`, so nothing above it changed. A pack with nothing compressed is still
  written as version 1 (`Editor --cook --uncompressed`, `CookOptions.compressesBlobs = false`), which
  older engines read; they refuse version 2 as "newer than this engine reads". An encoding the engine
  doesn't know fails when the pack opens, not when a level loads. The cooker compresses all blobs in
  parallel (Racing: 9 s for the whole cook, debug build).

Racing, web pack (BC textures), MB = 10^6; gzip -9 and brotli -q 11 of each kind's blobs as an HTTP
server would compress them:

| Kind | Before: raw | gzip | brotli | After: stored | gzip | brotli |
|---|---|---|---|---|---|---|
| Meshes (127) | 89.92 | 41.27 | 31.91 | **8.97** | 8.93 | 8.97 |
| Textures (33) | 35.21 | 22.41 | 19.81 | **22.60** | 22.37 | 22.11 |
| Scenes (1) | 1.17 | 0.09 | 0.06 | 0.09 | 0.09 | 0.09 |
| **Pack** | **126.5** | 63.8 | 51.8 | **31.9** | 31.6 | 31.4 |

There was no audio. Static hosts often don't compress `.pack` files at all, so the in-pack
compression is what counts: 4.0x smaller than before, and 1.6x smaller than the old pack with brotli
at its best. Textures with brotli would be 2.3 MB smaller than deflated in the pack; the engine has
no brotli decoder.

**Decode cost**, Racing's whole pack (90 MB of meshes and 30 MB of textures decoded): natively
(release, Apple M5) a run to the 60th frame takes 1.97 s against 1.88 s with the uncompressed pack
(medians of 3), so about 0.1 s. In Chromium (localhost, so no network time) the game starts in 1.93 s
against 1.68 s: about 0.25 s, which the 95 MB saved repays at any real download speed (at
50 Mbit/s the pack takes 5 s instead of 20 s, or 8 s with brotli).

**Quality**: `ENGINE_SCREENSHOT` frames of the race start with the uncompressed and the compressed
pack (the same player). Natively (2560x1440) they differ by a mean of 0.006 / 255; 0.05% of pixels
differ by more than 2 and 0.02% by more than 8. In Chromium (1280x720): mean 0.007 / 255, 0.06% and
0.02%. The differences are single pixels along silhouettes (edge coverage, the largest a taillight's
edge on a car); repeated runs of either pack are pixel-identical, and nothing shows at 1:1.

**The page** (`Web/loader.js`): the pack and the wasm download together under a progress bar
("Downloading… 67.3 MB of 89.4 MB", `acro.download = { loaded, total }`) instead of a blank canvas.
`player.json` has `packSize` and `wasmSize` (written by the exporter and `web-player.sh`), used as
totals because Content-Length is the size in transit when the server compresses (it's used when it
doesn't, and with neither the bar shows bytes only). The wasm compiles as it downloads
(`compileStreaming`; before, it was fetched only after the pack). The pack is kept in the Cache API
(`acro-packs`) under `packHash`, the hash in the pack's header (the table of contents', which covers
every blob's hash): a second visit loads it from there without a request, and a new export replaces
it. Pages that aren't on https or localhost have no Cache API and just download. Checked in
Playwright Chromium with the server throttled to 8 and 20 MB/s, with and without Content-Length:
the bar advances over 18 steps, and the second visit in the same browser makes no pack request and
starts in 1.6 s instead of 4.5 s. Racing's wasm is 57.6 MB here: Racing's code imports Foundation,
so ICU is linked (see below).

Not done: the wasm isn't cached by the page (the browser's HTTP cache and code cache handle it when
the host sends cache headers), and textures could shrink further with a block-aware layout before
deflate (BC7 endpoints and indices in separate streams).

### Game code and Foundation

If a game's own Swift code imports Foundation (`JSONSerialization`, `String(format:)`, and so on),
the Web export links all of Foundation, including ICU. That's about 35 MB more, or 10 MB
compressed, and the export log says so. To leave ICU out, import it like the engine does:

```swift
#if os(WASI)
import WASIFoundation   // FoundationEssentials plus the engine's shims (JSONSerialization, String(format:) without %@, ...)
#else
import Foundation
#endif
```

Games that don't import Foundation, or that import it only this way, are built without
Foundation autolinking (`GameExporter.importsFullFoundation`).

## What had to change

| Problem | Change in the spike | Proper fix |
|---|---|---|
| No Dispatch, no threads (`wasip1`) | `concurrentPerform` runs in order; `JobSystem` is inline (0 workers); `runInBackground` runs inline; `FileWatcher` doesn't poll | Fine for v1. Threads later need `wasip1-threads` and cross-origin isolation (COOP/COEP) |
| `DispatchTime` | `monotonicNanoseconds()` (ContinuousClock) everywhere in the engine | Keep |
| Foundation doesn't re-export libc on WASI (`sinf`, ...) | `@_exported import WASILibc` in EngineCore | Keep |
| No signals | CrashReporter installs no handlers on WASI | Report traps from the JS side |
| No zlib in the sysroot | PNG writing and net snapshot compression are unavailable | Done (W2C): zlib 1.3.1 vendored in `Sources/CZlibWasm`, built as `CZlib` in Wasm builds only |
| astc-encoder needs `std::mutex` | CTextureCodec left out (encoding/decoding throw) | Done (W2C): no-op `std::mutex` / `condition_variable` force-included on WASI (`CTextureCodec/wasi/wasi_threads_shim.h`); the codec builds and matches native output |
| miniaudio needs pthreads | `CAudio` device functions are stubs on WASI | Web Audio (AudioWorklet) output pulling from the mixer |
| `.atomic` writes are unavailable | `Data.WritingOptions.engineAtomic` (`[]` on WASI) | Keep |
| MCP transports (sockets, stdio, URLSession) | Excluded from the target; GameMCP has no transport | Fine: not needed in a web game |
| Exporter / game-module builder and loader (`Process`, `dlopen`) | Excluded; `GameModuleError` moved to its own file | Fine: editor-side |
| **`Int` is 32-bit on wasm32** | Fixed a hash constant (MeshBuildSculpt) and the `mesh << 32 \| material` batch keys in ShadowMaps and RenderList: on 32-bit they silently became 0 and every batch would collide | **Audit**: only literals that overflow are compile errors. Shifts, byte counts and hash math can still be wrong without any warning. Audited in W2C (see "Size" below for the list) |
| **Generated player `main.swift` traps** | `@_silgen_name("acro_module_v1")` declares the `@_cdecl` entry with Swift's calling convention; wasm traps on the signature mismatch (native tolerates it). Spike player uses `@_extern(c, …)` | Change GameExporter's template (needs the `Extern` experimental feature) |
| `Bundle.module` traps (it goes through `Bundle.main`) | `Bundle.engineResources` reads a folder named by `ENGINE_RESOURCES` | Ship engine resources inside the pack, or fetch them into a virtual filesystem |
| Foundation bug: `Bundle.url(forResource:withExtension:)` drops the extension's last character on WASI | `Bundle.engineResourceURL` builds paths directly on WASI (all 6 lookups) | Keep, and report upstream |

## Size

**The data section was ICU.** `import Foundation` on WASI links swift-corelibs-foundation,
FoundationInternationalization and `_FoundationICU`, whose `icudt76l` table is ~35 MB, even if
nothing from them is used: the import's autolink entries pull the libraries in whole. A
one-line test binary shows it: `import Foundation` and a `JSONEncoder` call is 51 MB stripped
(36 MB data); the same with `import FoundationEssentials` is 12 MB (2 MB data). An unused
`import class Foundation.Bundle` in one file is enough to bring the 36 MB back.

So in Wasm builds (W2C) the runtime modules (`EngineCore` … `Engine`, `EngineMCP`, `SampleGame`
and the `Spikes` targets) import **`WASIFoundation`** instead of Foundation:

```swift
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
```

`WASIFoundation` (`Sources/WASIFoundation`, a target only in `ENGINE_WASM=1` builds) re-exports
`FoundationEssentials` and `WASILibc` and adds the Foundation-only APIs the engine uses, with
Foundation's names so call sites stay the same: `NSLock` / `NSCondition` (no-ops; single thread),
`Thread.isMainThread`, `FileHandle` (on POSIX file descriptors), `CharacterSet` and
`trimmingCharacters(in:)`, `replacingOccurrences(of:with:)`, `range(of:)`, `String(format:)`
(through `vsnprintf`; no `%@`), `removingPercentEncoding`, `DateFormatter` (the
`yyyyMMdd-HHmmss` patterns only), `ISO8601DateFormatter`, `JSONSerialization.jsonObject`,
`Bundle` (by path), `URLResourceValues` and `FileManager.enumerator(at:...)`. Native builds don't
build it and are unchanged. `(path as NSString).lastPathComponent` and friends became
`path.pathLastComponent`, `pathFileExtension`, `pathDeletingExtension`,
`pathDeletingLastComponent` and `pathExpandingTilde` (EngineCore `PathString.swift`: NSString's
own functions natively).

One `import Foundation` remains: EngineCore's SwiftPM-generated `Bundle.module` accessor (it has
resources). It is unused on WASI and dead-stripped, so the manifest's `wasmFoundationSettings`
make it free: `-disable-autolink-library` for Foundation, FoundationInternationalization,
`_FoundationICU` and CoreFoundation in every module on top of EngineCore (Foundation would
otherwise be autolinked through EngineCore's swiftmodule), and `MemberImportVisibility` so
Foundation's extension members (`.whitespaces`, `String(format:)`) don't leak into files that
import WASIFoundation. Code that really used Foundation would now fail to link, not silently
add 35 MB. **New files under `Sources/Engine*` must use the import block above.**

Release `WasmPlayer.wasm` (SampleGame linked in), stripped; MB = 10^6 bytes:

| Step | Stripped | gzip -9 | brotli -q 11 | Code | Data |
|---|---|---|---|---|---|
| Spike / W1 baseline | 70.9 MB | 24.9 MB | 15.8 MB | 31.2 MB | 39.0 MB |
| WASIFoundation, no ICU (+ vendored zlib and the texture codec, ≤ 0.4 MB of it) | 30.2 MB | 9.6 MB | 6.1 MB | 26.2 MB | 3.5 MB |
| `wasm-opt -Oz` on top (binaryen 133) | 19.4 MB | 7.4 MB | 5.0 MB | 16.0 MB | 3.0 MB |

`Scripts/wasm-size.sh [--no-build] [--wasm-opt]` builds the release player, strips it, prints
these numbers and fails over its budgets (the second row plus ~10%: 33 MB stripped, 10.6 MB
gzip, 6.7 MB brotli, 3.9 MB data) or when ICU's data (`icudt`) is linked in. `wasm-opt -Oz` takes
about a minute and cuts another third; the web export should run it. Not measured: start-up
time in a browser.

**zlib and the texture codec on WASI.** `Spikes/WasmPortabilityCheck` encodes and decodes a test
image in every BC and ASTC format (LDR and HDR), writes a PNG to disk and reads it back,
round-trips zlib and prints the layouts of types stored in caches, with a hash per result. Its
output under Node's WASI (wasmkit can't run modules that import JavaScriptKit) is identical to
the native one (`ENGINE_WASM_CHECK=1 swift run WasmPortabilityCheck <png>`; see the file).

**32-bit `Int` audit (W2C).** Fixed: `GLTFReader` (`Int(UInt32.max)` trapped),
`BehaviorTreeRuntime.randomUnit` (`1 << 53` was 0 on 32-bit: a division by zero), the groom
geometry tag (hashed `Int` widths as 4 bytes on 32-bit, so web builds keyed fur meshes differently
from the cooker) and `LightProbeBakeCache` decoding (`Int(UInt32)` and `count * 4` could trap on a
bad file). Checked and fine: the pack format (`AssetPack`: fixed-width fields, offsets bounded by
the data), `AssetCache` (raw `MeshVertex` / `VertexPaint` / skin arrays: same strides on wasm32,
checked above), `EntityID` / `AssetID` (two `UInt64`s, hex strings in files), the net coder
(fixed-width, `exactly:` on decode), scene JSON (an `Int` over 2^31 fails to decode on wasm32
rather than wrapping), `monotonicNanoseconds` (`UInt64`), the other `<< 32` keys and 64-bit hash
mixers (all `UInt64` / `Int64`). Left as is: `Int(Float)` of huge coordinates and >2 GB files
would trap on wasm32, which can't hold them anyway.

## Performance (W2.5C)

The question: where does a CPU-heavy frame go in a single-threaded browser build, and what's
slow only because it's WebAssembly? Measured on the Crowd Demo scene (144 skinned foxes on a
navmesh, 640 rigid bodies, 2500 shadow casters) and the Racing game (`~/Games/Racing`, exported
with `Editor --build-game ... --platform web`), release builds, Playwright Chromium with WebGPU
on an Apple M5 (other agents' builds running at times, so before and after builds were run
alternately, 3-4 times each, and the medians are compared).

```sh
# Demo with a name section, so profiles show Swift functions:
ENGINE_WASM=1 ~/.swiftly/bin/swift package --swift-sdk swift-6.4.2-RELEASE_wasm --scratch-path .build-wasm \
    js --product Demo -c release --debug-info-format name
Scripts/web-player.sh --demo --release --no-build --no-serve
# Frames 300-600 at fixed 1/60 s steps (ENGINE_SCREENSHOT mode: the same work in every run);
# --profile adds Chrome's CPU profiler (CDP) with the top functions by self and total time:
node Spikes/WebPlayerCheck/profile.mjs .build-wasm/web-demo <out> --frames 300:600 [--profile] \
    --query 'args=--scene,crowd&env=ENGINE_SCREENSHOT=/s.png,ENGINE_SCREENSHOT_FRAME=100000'
```

A Web export keeps its name section with `ACRO_WASM_OPT=none` (wasm-opt drops it). The
`.cpuprofile` it writes opens in Chrome DevTools' Performance panel.

**What the profiles showed** (Crowd, before; ms per frame of a ~23 ms profiled frame):

- **Swift strings passed to JavaScript.** `setIndexBuffer` passed its index format as a Swift
  `String`, which JavaScriptKit converts to a new JS string on every call
  (`swjs_decode_string` plus a retain in its object heap): 2.7 ms in Crowd (~450 draws), and
  **6.2 of Racing's 10.9 ms**. Native builds have no such cost, so it never showed up there.
- **Allocation per draw** in the WebGPU backend's bind group code (key and offset arrays,
  closures, an empty dynamic-offset array converted to a JS array): ~1.3 ms.
- **Physics (10.8 ms)**: the narrowphase transformed both bodies' polyhedra into world space
  for every contact (three arrays each; 4400 contacts, 640 bodies), and GJK kept its simplex in
  arrays that grew and shrank each iteration. `malloc`, `free`, release and array destruction
  were ~2.5 ms of the frame. The solver itself (`solveContact`, ~3 ms) is plain float math.
- **No SIMD.** `Vec3` is `SIMD3<Float>`; without `-msimd128` every vector operation is
  scalarized.
- Not hot: ECS queries, unspecialized generics or existential calls (the ECS store and
  queries were already specialized and pointer-based), bounds checks. Copying `Body` structs
  (~0.5 ms, solver islands and the ECS sync) is by design.

**Fixes** (all general; native behavior unchanged, physics results bit-identical: a 120-body
pile's poses hash the same before and after, and the physics tests pass):

1. WebGPU: index formats are JS strings made once; bind groups are matched in scratch arrays
   without allocating, and groups without dynamic offsets pass none (281b79b).
2. Physics: each body in an active contact gets its world-space shape once per step (in
   parallel on native), reused by every contact it's in; GJK's simplex is fixed storage;
   `awakeBodyCount` / `touchingContactCount` count in place (1aca312).
3. Wasm builds compile the engine with WebAssembly SIMD (`-Xcc -msimd128`, which Swift's code
   generation takes from the Clang options): f32x4 instead of four scalar lanes (e02b1e2).
   Every WebGPU browser has SIMD128. **It changes the calling convention for
   `SIMD3<Float>` / `SIMD4<Float>`**, so game code must be built with it too: the Web export
   adds it to the game and player targets (76af63e); a mismatch traps at once with
   `signature_mismatch` (Racing did, before that). The 51 Demo scenes that run in the browser
   still run (Forest and Fur stop as before, editor-side assets).

**Results** (rAF callback = the whole engine frame in one `requestAnimationFrame`; update and
render are the engine's own CPU times; medians of 4 alternated runs, frames 300-600, ms):

| Crowd (fixed 1/60 s steps) | frame (rAF callback) | update | render |
|---|---|---|---|
| Before (wasm-spike 364581d) | 17.9 | 11.1 | 5.9 |
| + WebGPU strings and bind groups | 16.8 | 11.9 | 3.9 |
| + physics world shapes, GJK | 13.6 | 8.7 | 3.7 |
| + SIMD128 | **12.5** | **7.9** | **3.4** |

| Racing (fixed steps, frames 300-600) | frame | update | render |
|---|---|---|---|
| Before | 7.1 | 0.2 | 6.9 |
| After (all of the above) | **3.4** | 0.3 | 2.8 |

In real time (variable steps, what a player sees) Crowd went from 21.5 ms per frame
(~47 fps, p95 34 ms) to a steady **60 fps** (16.7 ms intervals, p95 18.6 ms; 13.7 ms of work
per frame). While the 640 bodies are still falling (frames 60-300) the frame is 19.2 → 14.1 ms.
The 48 ms measured in W2A was with the machine loaded by other builds. The Demo's `.wasm` is
1.1 MB smaller with SIMD.

**Wasm against native** (same work: Crowd, frames 300-600, after the fixes): the native
release build with `ENGINE_JOB_THREADS=1` spends 7.8-8.5 ms in update, the browser 7.9 ms, so
the simulation code itself runs at about native speed (the single-threaded native process may
be scheduled on efficiency cores; the browser's renderer isn't). With its job threads native
takes 4.9-6.2 ms. What made the browser slower was the JS bridge (render: 3.4 ms in the browser
against 1.8 ms natively) and allocation, not WebAssembly arithmetic.

**Left:** `endFrame` copies the frame's transient data into a new JS `Uint8Array` before
`queue.writeBuffer` (`swjs_create_typed_array`, ~0.5 ms in Crowd); writing straight from a view
of the wasm memory would avoid the copy but needs the loader to hand the memory over. Each draw
is still a few JS calls (`setVertexBuffer`, `setBindGroup` with its offsets array,
`drawIndexed`): render bundles or one call per batch through a small JS helper would cut that.
The solver (~2.8 ms) is real work. Racing's frame is now mostly WebGPU calls.

### Threads (estimate, not built)

What `wasm32-unknown-wasip1-threads` with cross-origin isolation would buy, and cost.

**What would run in parallel:** the job system's loops, the same as natively: the physics pair
search, world shapes, narrowphase and solver islands; animators; transform
propagation by root; camera and shadow-caster culling and shadow batches; background asset
imports and texture work. In the Crowd profile 6.3 of 14.2 ms per frame (45%) is inside
`JobSystem.parallelFor` / `parallelMap` (physics 5.0 ms, of which the solver can use at most
four threads: the scene has four piles, so four islands). WebGPU calls can't move: a
`GPUDevice` and every JS object belong to the thread that made them, so render submission
stays on one thread. Racing spends 0.3 ms in update; threads would give it nothing.

**Estimate:** natively, threads take Crowd's update from ~8.1 to ~5.5 ms (1.5x, with its default job threads).
The browser would see about the same, minus costs it doesn't have now: atomic reference
counting (the single-threaded runtime uses `swift_nonatomic_retain/release`; the threads
runtime uses atomic read-modify-writes on shared memory) and a locking `malloc`. So Crowd would
go from ~12.5 to ~10-10.5 ms per frame, ~15-20%, and it already runs at 60 fps. Worth it later
for games that are CPU-bound in the simulation, not now.

**Toolchain:** the swift.org 6.4.2 SDK we use has no threads variant (only `wasm32-unknown-wasip1`
and Embedded). The SwiftWasm SDK index (`swiftwasm/swift-sdk-index`) has a
`wasm32-unknown-wasip1-threads` SDK for 6.3.2 (built from a 6.3 snapshot) and none yet for
6.4.2 (checked 2026-11-24), so threads would mean another toolchain, or building the SDK.
JavaScriptKit 0.63 supports it: PackageToJS builds threaded products (shared memory, a
worker per `wasi-threads` thread), `WebWorkerTaskExecutor` runs Swift tasks on workers, and
`JSSending` moves JS objects between threads. The engine's `JobSystem` uses `Thread` and
`NSCondition`, which WASIFoundation stubs out; they would become pthreads (wasi-libc has
them in the threads target). The astc-encoder `std::mutex` shim and `NSLock` no-ops would go.

**Browser rules:** the main thread can't block (`Atomics.wait` throws there), and the engine
runs its frame on the main thread. So either `JobSystem.wait` and `parallelFor` spin on the
main thread while workers run jobs (simple; wastes the main core while waiting), or the whole
engine moves into a worker with an `OffscreenCanvas` (WebGPU works in dedicated workers) and
the page forwards input events to it: the bigger change, and the one that also keeps the page
responsive. Shared memory needs a maximum size up front (the pack is copied into it: Racing's
is 120 MB).

**Hosting:** `SharedArrayBuffer` needs cross-origin isolation: the page served with
`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` (or
`credentialless`), and every subresource same-origin or sent with
`Cross-Origin-Resource-Policy`. Our folder is all same-origin, so only the two headers. A
plain static host can't set headers (GitHub Pages; a service worker such as
coi-serviceworker can add them after a reload); itch.io has a SharedArrayBuffer option;
Netlify, Cloudflare Pages and nginx set them in config. An isolated page also can't embed
cross-origin iframes or popups that talk back (ads, some login flows). The export would need a
single-threaded fallback for hosts without the headers, so two `.wasm` files.

## What's left for a browser build

1. **WebGPU `RenderDevice`** (through JavaScriptKit), and a SPIR-V → WGSL step in
   `compile-shaders.sh` (Tint or Naga). Push constants become a small uniform buffer.
   `rgba16f` read-write storage images (FSR, some compute passes) need rework or a fallback.
2. **Main loop inversion**: `Engine.run` is a blocking `while` loop. The browser needs a
   per-frame `tick()` driven by `requestAnimationFrame`.
3. **Canvas `PlatformWindow`** and input (DOM keyboard and mouse events, the Gamepad API).
4. **Web Audio output.**
5. **Asset loading**: fetch the pack and engine resources into memory or a virtual filesystem
   instead of WASI preopened folders. Saves go to IndexedDB (done in W2.5A).
6. **Web export target** in GameExporter: Wasm build, `wasm-opt`, an HTML/JS loader with a
   WASI shim, and the pack. Includes the `@_extern(c)` entry-point fix.
7. Cleanup: vendored zlib, a FoundationEssentials-only runtime for size, the 32-bit `Int` audit
   (done in W2C, see "Size").

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

### Wave W2.5 (web polish)
- **W2.5A: Content gaps.** Re-run the Images, Net, Net Character and Compression Demo scenes in
  Chromium now that zlib and the texture codec build for WASI, and fix what still stops. A WGSL
  path for material-graph shaders and terrain splat (the material graph builder's previews need
  it too). Saves on IndexedDB (preload into the in-memory filesystem before start, write back
  after a save). `Key` cases for punctuation and numpad keys in `CanvasWindow` (and every other
  platform window that lacks them).
- **W2.5B: Download size.** Racing's pack is ~120 MB, 86 MB of it meshes; the `.wasm` is not
  the problem. Mesh quantization and meshopt-style compression in the pack (native players must
  read it too), streaming the pack with a progress bar on the page, and optionally caching it
  (Cache API) for repeat visits.
- **W2.5C: Single-thread performance.** Profile Crowd (~20 fps) and Racing in the browser and fix
  the worst Wasm hot spots (bounds checks, unspecialized generics, allocation in the frame loop).
  Measure whether `wasip1-threads` with cross-origin isolation would be worth it later; write up
  the numbers, don't build it.
