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
node Spikes/WebPlayerCheck/run.mjs .build-wasm/web-player <out dir> [--query ...]   # Playwright check (--no-webgpu, --count-calls: see WebGL 2 below)
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
`engine/manifest.json`), a pack per texture family (`game.bc.pack`, `game.astc.pack`: see "Texture
families (W2.6C)"; `game.pack` when the export has one family), `player.json` and a `README.txt` on hosting it (any static
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
**21.5 MB gzip -9, 14.2 MB brotli -q 11**, a 1.7 MB pack (BC textures, then the Web default; since W2.6C a pack per family), 3 MB
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

### Texture families (W2.6C)

A page is opened from any device, so a Web export no longer ships one GPU family's textures. It
has **a pack per family**, `game.bc.pack` (BC7, BC5 normal maps, BC6H HDR) and `game.astc.pack`
(ASTC 4x4, two-channel ASTC normal maps, ASTC HDR), and the page downloads one:

- **Design.** Each is a complete, ordinary pack (version 2, no format change), so native players
  read either and nothing in `AssetPack` changed. The alternative, a shared pack plus per-family
  texture packs (or per-family sections fetched with Range requests), would have needed a pack
  that spans files (a new version that every reader handles), and Range requests aren't served by
  every static host (Python's `http.server` doesn't). A browser downloads exactly as much either
  way; the cost is hosting the shared blobs (meshes, scenes, audio) twice. The export cooks the
  families one after the other, sharing compressed blobs (`AssetPackFormat.PreparedBlobs`), so
  meshes are quantized and deflated once.
- **player.json** lists them: `"packs": { "bc": { "file", "size", "hash" }, "astc": {...} }`, with
  `pack` / `packSize` / `packHash` the first family's. An export with one family (`--gpu bc|astc`,
  `game.build` `textureFamily`) has a single `game.pack` as before. `Editor --cook` still writes one
  pack (`--gpu all` is for `--build-game --platform web`); the project's `build.textureFamily` is
  for native builds only.
- **The loader chooses** (`pickTextureFamily` in `Web/loader.js`), from what the render devices read
  too: the WebGPU device's `texture-compression-bc` / `-astc` features (the loader requests every
  adapter feature), or the extensions `webgl2.js` enabled (`EXT_texture_compression_bptc`, `_rgtc`,
  `WEBGL_compressed_texture_astc` and its `hdr` profile). The family with the most of its 8-bit
  formats (color, normal maps) sampled wins, then the most formats overall (HDR breaks ties), BC
  first on a tie: WebGPU has BC6H but never ASTC HDR, and with neither family BC7 decodes several
  times faster than ASTC. `TextureFamily.choose` is the same rule in Swift (tested in
  `TextureFamilyPacksTests`). `?textures=bc|astc` overrides it. The console says what it picked:
  `[acro] textures: bc (WebGPU texture-compression-bc, texture-compression-astc)`, a warning when it
  has to decode. `acro.textureFamily` is the choice. The Cache API keeps each pack under its own
  path.
- **Decode fallback.** `RenderDevice.makeTexture(compressedLevels:format:)` is the one place that
  decides, from `RenderDevice.supports(_:)`: a texture the GPU can't sample is decoded by
  CTextureCodec when it loads (`TextureCodec.decodeForUpload`) to RGBA8 (sRGB for the sRGB
  formats), RGBA16F for BC6H and ASTC HDR, two-channel normal maps expanded with Z rebuilt, with one
  warning per format. At startup the player also logs whether the pack's formats are sampled as
  cooked (`GamePlayer.textureSupportNote`, a warning listing the ones it will decode).

**Checked** (2026-11-26, Playwright Chromium on an Apple M5, release SampleGame export,
`Spikes/WebPlayerCheck/textures.mjs`, which hides formats by patching `GPUAdapter.prototype.features`
and `WebGL2RenderingContext.prototype.getExtension`; ENGINE_SCREENSHOT frames, 1280x720, compared
with the run where nothing is hidden on the same renderer; mean difference / 255, `ENGINE_GL_DEBUG=1`
on WebGL 2):

| Renderer | GPU has | Pack downloaded | Decoded | Errors | vs normal (mean / max) |
|---|---|---|---|---|---|
| WebGPU | BC and ASTC | game.bc.pack | none | 0 | reference |
| WebGPU | BC only | game.bc.pack | none | 0 | 0.000 / 0 |
| WebGPU | ASTC only | game.astc.pack | none | 0 | 0.171 / 108 |
| WebGPU | neither | game.bc.pack | bc7Srgb, bc7Unorm, bc5Unorm | 0 | 0.001 / 28 |
| WebGL 2 | BPTC, RGTC, ASTC (hdr) | game.bc.pack | none | 0 | reference (0.002 vs WebGPU) |
| WebGL 2 | BPTC, RGTC | game.bc.pack | none | 0 | 0.000 / 0 |
| WebGL 2 | ASTC (hdr) | game.astc.pack | none | 0 | 0.171 / 116 |
| WebGL 2 | none | game.bc.pack | bc7Srgb, bc7Unorm, bc5Unorm | 0 | 0.001 / 28 |

Each run downloads one pack and starts in 1.5-2.6 s. The ASTC runs differ from the BC ones by
their encodings (0.003% of channels off by more than 8); decoded BC matches the GPU's own decoding
to within rounding. **Sizes**, SampleGame (5 assets, 1.42 MB of textures raw): before, one BC pack of 526,454
bytes; now `game.bc.pack`, byte for byte the same file, and `game.astc.pack`, 558,929 bytes (6%
more), of which a browser downloads one (the folder holds both: +0.56 MB hosted). The wasm is
17.8 MB (6.6 MB gzip, 4.6 MB brotli).

The Demo's `compression` scene (every 8-bit format encoded at run time, `--query
args=--scene,compression`) draws all of them in the same 8 runs with 0 errors: with BC hidden it
decodes bc7Srgb, bc7Unorm and bc5Unorm, with ASTC hidden the three ASTC formats, with both hidden
all six, one warning each, and the tiles look the same (the frames differ by 0.2-0.3 / 255,
mostly the scene's "decoded" labels and the debug overlay's timings). A native player (debug
macOS export of SampleGame, Metal) plays both web packs with `--pack`: the ASTC one's frame is
identical to its own pack's, the BC one's differs by 0.17 / 255 (the encodings).

Not done: a texture decoded at load counts against the renderer's upload budget at its compressed
size (it takes 4x, or 8x for HDR, in GPU memory), and decoding runs on the main thread when the
texture is first drawn. SampleGame has no HDR textures, so ASTC HDR on WebGPU was only exercised
by the unit tests.

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

## WebGL 2 renderer (2026-11-26)

Browsers without WebGPU (older Safari and Firefox, Chrome with WebGPU blocklisted) get WebGL 2
instead of an error, and a player can pick either renderer.

### Picking and switching

The loader (`Web/loader.js`) picks, in order: the page option `?renderer=webgpu|webgl2|auto`, the
player's saved choice (localStorage `acro.renderer`), then `renderer` in `player.json` (default
`auto`). `auto` is WebGPU when an adapter and a device come up, else WebGL 2; the console says which
and why (`[acro] renderer: WebGL 2 (auto; WebGPU is unavailable: ...)`). A renderer that fails
falls back to the other one (a canvas that already has a WebGPU context is replaced by a fresh
one), and the page shows an error only when neither works. `globalThis.acro.renderer` is the one
that started; `acro.renderers` lists what the browser seems to have; `acro.setRenderer(name)` saves
the choice (`auto` clears it) and reloads (replacing `?renderer=` in the address when it's there).
From Swift (a game's settings menu): `WebHost.renderer`, `WebHost.availableRenderers` and
`WebHost.setRenderer(.webgl2)`. On WASI `Engine` creates the device that matches `acro.renderer`
(`GraphicsBackend.webgl2`, `WebGL2RenderDevice`).

A Web export writes `renderer` into `player.json`: the Export Game dialog's **Renderer** (Web
only), `game.build`'s `renderer`, `Editor --build-game ... --platform web --renderer
auto|webgpu|webgl2` (`GameExportOptions.webRenderer`, `WebRenderer`). Exports and
`Scripts/web-player.sh` ship `webgl2.js` and the `.gles` shaders next to the `.wgsl`.

### Shaders

`Scripts/compile-shaders.sh` also writes `<name>.vert.gles` / `<name>.frag.gles` (GLSL ES 3.00) with
SPIRV-Cross (`Scripts/spirv-to-gles.c`): combined image samplers, push constants as a std140
uniform block, z mapped from 0..1 to -1..1 (`fixup_clipspace`), `gl_InstanceIndex` as
`gl_InstanceID`, only the *active* resources (so non-probe mesh shaders don't carry probes.glsl's
storage buffer). GLSL ES 3.00 has no binding qualifiers and links by name, so everything is named
deterministically: varyings `acro_v<location>`, uniform blocks `acro_<vs|fs>_u<set>_<binding>` and
`acro_<vs|fs>_push` (per stage, so blocks that differ between stages never collide), samplers
`acro_t<set>_<binding>_s<set>_<binding>` (a texture with the sampler it's used with) or
`acro_t<set>_<binding>` (combined in the GLSL, or texelFetch without a sampler). A header after
`#version 300 es` (WebGL wants that on the first line) lists them (`// acro-ubo name set binding`,
`// acro-sampler name tset tbinding sset sbinding shadow`); the device reads it (`GLESInterface`) to
bind blocks to binding points (0 frame, 1 push constants, n for uniform buffer n) and give each
sampler a texture unit. Fixes in the driver: `bitfieldReverse` (env_prefilter) gets a polyfill
(ES 3.10 has it), and `noperspective` varyings (debug_line; ES 3.00 has none) are emulated (W2.6A):
the vertex stage writes `v * gl_Position.w` and an extra varying `acro_vnpw = gl_Position.w` at the
end of `main`, the fragment stage reads `(v / acro_vnpw)`; perspective-correct interpolation of
both gives the screen-linear `v`. With glslangValidator installed every output is validated.
Stages whose active resources need storage buffers or images get no `.gles` (listed at the end of
the run, like the WGSL step; only a test shader now). A shader marked `// compile-shaders: gles
<glslc flags>` gets its `.gles` from a second compile with those flags: the material graph
templates and terrain splatting (`-DGRAPH_VALUES_UNIFORM=1024`, see "No compute"), the probe-lit
mesh shaders and probe_debug (`-DPROBE_DATA_TEXTURE`) and the particle vertex shaders
(`-DPARTICLES_INSTANCED`), see "Particles and light probes (W2.7A)". No GLSL ES is generated for compute. The binding table in
`ShaderSource` has a WebGL 2 column; `WebGL2ShaderTests` checks every output is current and
inside the table.

### The device

`Sources/EngineBackends/Backends/WebGL2/` plus `Web/webgl2.js`:

- **Commands, not calls.** A draw doesn't call WebGL. The pass writes what changed (pipeline
  state, vertex array and attribute offsets, uniform ranges, texture and sampler per unit) and the
  draw into an Int32 command buffer in WebAssembly memory; `webgl2.js` runs the whole buffer with
  one `execute(ptr, count)` call, normally once a frame (also before anything that must see the
  frame's work so far: buffer and texture updates, readbacks). The device keeps what is bound, so
  an unchanged draw is its draw command alone; nothing per draw makes strings, JS objects or
  allocations. Objects have numeric ids the device assigns (`webgl2.js` keeps them in a Map).
  Creation, uploads and readbacks are direct calls with pointers into WebAssembly memory
  (`acro.wasmMemory()`), so data isn't copied into JS arrays first.
- **Per-frame data** (uniforms, push constants, vertex and index data) goes into transient
  rings, uploaded with one `bufferSubData` per buffer before the commands run; uniform ranges
  are bound with `bindBufferRange` at the device's offset alignment. Index data has its own ring:
  WebGL types a buffer by its first binding, and index buffers can't be bound as anything else.
- **Convention.** Every pass renders into the device's own framebuffers, whose memory row 0 is
  the image's top, as in Metal, Vulkan and WebGPU: the GLSL's Vulkan clip space (y down) is left
  unflipped, which in GL's window space (y up) puts the image's top at row 0. So texture
  coordinates, `gl_FragCoord`, viewports, scissors and `readPixels` rows mean what they mean on
  the other backends, and only two things change: front faces are clockwise in GL terms
  (`frontFace(CW)`), and presenting flips the image into the canvas. (So `flip_vert_y` is *not*
  used: flipping in the shader would put the image's bottom at row 0.)
- **Presenting.** The window image is an SRGB8_ALPHA8 texture. Blitting it into the canvas would
  decode its sRGB (ANGLE does; `webgl2.js` tests it once), so the canvas gets a fullscreen draw
  that reads it with texelFetch, encodes it again and flips it; where blits keep the bytes, a
  y-swapped `blitFramebuffer`. The same copy (unflipped) gives the upscalers the scene image's
  gamma-encoded bytes (WebGPU uses an unorm view; WebGL has no texture views).
- MSAA: multisampled renderbuffers, resolved with `blitFramebuffer` at the end of the pass.
  Samplers are sampler objects; shadow maps DEPTH_COMPONENT32F with a less-or-equal comparison
  sampler. Depth (and 32-bit float) textures read with texelFetch get a nearest sampler (a
  filtering one would make them incomplete). Depth bias is `polygonOffset`. A pipeline without a
  depth test that writes depth tests with ALWAYS (GL only writes depth with the test on).
- Motion vectors (TAAU): pipelines that don't write them draw with
  `drawBuffers([COLOR_ATTACHMENT0, NONE])`, so the attachment keeps "no motion".
- Occlusion queries: `ANY_SAMPLES_PASSED_CONSERVATIVE`, read a frame or more later. GPU pass
  times with `EXT_disjoint_timer_query_webgl2` (Chromium on macOS has it), else none.
- Captures and readbacks are synchronous (`readPixels`, `getBufferSubData`):
  `capturesArriveLate` is false.
- Compressed textures: BC7 / BC6H with `EXT_texture_compression_bptc`, BC5 with `_rgtc`, ASTC
  with `WEBGL_compressed_texture_astc` (ASTC HDR with its `hdr` profile). HDR targets need
  `EXT_color_buffer_float`. Upscalers: bilinear, FSR 1 and TAAU; asking for FSR 3 gives TAAU (FSR 1 without
  `EXT_color_buffer_float`), see "Rendering parity (W2.6B)".
- `ENGINE_GL_DEBUG=1` (`?env=ENGINE_GL_DEBUG=1`) checks `gl.getError()` after every command and
  names it in the console (`[acro] WebGL error 0x502 after END_PASS (...)`); it's slow.

**No compute.** WebGL 2 has no compute shaders, storage buffers, storage textures or indirect
draws. `RenderDevice.supportsCompute` and `supportsStorageBuffers` (default true) stay false.
GPU particles simulate on the CPU and light probes read their data from a texture (W2.7A, below);
FSR 3 falls back to TAAU. Still GPU-only: particle collisions against the depth buffer
(`collidesWithDepth`, off with a warning while particles simulate on the CPU).
`makeComputePipeline` and storage textures throw; `beginComputePass` returns a pass that records
nothing; indirect draws are skipped.

**Material graphs (W2.6A).** The graph templates (`mesh_graph.frag`, `mesh_graph_depth.frag`,
`decal_graph.frag`) and terrain splatting (`mesh_terrain.frag`) read the graph's values from
storage buffer 0. Their GLSL ES comes from a `GRAPH_VALUES_UNIFORM` variant that declares the same
set and binding (2, 24) as a std140 uniform block `vec4 values[1024]` (16 KB, what WebGL 2
guarantees per block); spirv-to-gles allows uniform blocks at bindings 24-31, and the device binds
`setStorageBuffer(_:index: n)` to binding point 8 + n for them. `MaterialGraphCompiler` emits the
graph's IR as GLSL ES and replaces `graphSurface()`'s body in the three templates' `.gles`, as for
MSL and WGSL (text, no compiler in the browser): `MaterialGraphProgram.glesFragment` /
`glesDepthFragment` / `glesDecalFragment` feed graph pipelines, masked graph shadows and depth,
and graph decals. The textures are the template's combined samplers (`acro_t2_<9 + slot>_s2_17`,
found in its header). The block's array is cut to the slots the code reads
(`MaterialGraphCompiler.glesSettingValueCount`; terrain splatting's five), so it matches the bound
buffer. A graph with more than `MaterialGraphCompiler.maxUniformValues` (1024) values gets no GLSL
ES and a compile warning, and on WebGL 2 is registered without the graph (drawn with its plain
surface) with one warning, the only graphs still skipped.

**Particles and light probes (W2.7A).**
- *Particles.* Without compute `ParticleSystem` simulates on the CPU (`simulatesOnCPU`,
  `ParticleCPUSimulation.swift`): particle_simulate / _spawn / _events / _compact and the sort as
  Swift, slot for slot, from the same `SimulationUniforms`, spawn schedule and pcg hash, so the same
  particles spawn with the same random numbers; integration, ground plane and analytic colliders,
  sub-emitter events (death, collision, birth; in slot order, `maxEvents`, the child's ring cursor
  and spawn counter) and the draw order (live slots in slot order; sorted emitters far to near by
  the same keys: inverted distance bits, then the slot). Differences: plain multiply-adds instead
  of the shaders' `fma` (fused multiply-add is a slow libc call in Wasm) and libc sin / cos / pow,
  so positions drift by rounding (a unit test bounds it: under 0.02 after 40 steps with
  turbulence and bounces, against Metal and Vulkan compute); no depth-buffer collisions (the
  scene's depth stays on the GPU; a warning). Each frame the live particles in draw order go into
  transient memory (`ParticleRecord`, 48 bytes) and are drawn instanced (6 vertices, one instance
  each) with particle.vert / particle_lit.vert's `PARTICLES_INSTANCED` GLSL ES, which reads them
  from instance attributes 0-2 instead of storage buffers; particle.frag is unchanged. Emitters
  above `cpuMaxCapacity` (65536) simulate every n-th spawn index (n a power of two, so the 32-bit
  indices keep the pattern; the step's dt spread uses the original offsets) and additive ones are
  drawn n times brighter, with a warning: the Demo's 128k galaxy simulates every 2nd particle.
  `ParticleSystem.Stats.cpuMilliseconds`; the `particles` scene's title shows "CPU x ms".
- *Light probes.* The probe-lit shaders' GLSL ES (`PROBE_DATA_TEXTURE`) reads the probe buffer's
  words from an RGBA32UI texture at the storage buffer's set and binding (2, 25), 1024 uvec4s per
  row (`PROBE_WORDS(i)` in probes.glsl; the SPIR-V for the other backends is unchanged).
  spirv-to-gles allows textures at bindings 24-31 (`GLESInterface.Sampler.storageSlot`). The WebGL 2
  device turns `setStorageBuffer(_:index: n)` into that texture for such a sampler
  (`storageTexture`): made on first use and copied from the buffer on the GPU (a
  `PIXEL_UNPACK_BUFFER` `texSubImage2D`, Web/webgl2.js `copyBufferToTexture`) whenever
  `updateBuffer` wrote it since (a version per buffer); read with a nearest sampler. The bake renders
  as before (faces, equirect, SH projection and prefilter are fragment passes); only probe_store.comp
  was compute: without it each SH row and prefiltered level is read back at once
  (`RenderDevice.readFloatTexels`, `readPixels` as floats; nil on the other backends) and packed into
  the buffer from the CPU as the compute shader does (`updateBuffer`), so the next bounce and the
  frame see it. The final readback for the cache is the usual synchronous `getBufferSubData`.

### Results (2026-11-26)

Playwright Chromium (Apple M5; WebGL 2 is ANGLE on Metal), release Demo, `?renderer=webgl2` with
`ENGINE_GL_DEBUG=1`, each scene 4 s with input:

- **All 54 Demo scenes and SampleGame run, with 0 WebGL errors.** Degraded (feature skipped with
  its warning) until W2.7A: `particles` and `rain` (GPU particles), `probes` (light probes); `graphs` drew its
  material graphs and splat terrain with plain materials until W2.6A (below). Two bugs the run found are fixed
  (debug_line's `noperspective`; a framebuffer's read buffer set on the wrong binding).
- `ENGINE_SCREENSHOT` frames (1280x720, overlay off) against the WebGPU run, mean difference / 255:

| Scene | Mean | | Scene | Mean |
|---|---|---|---|---|
| SampleGame | 0.002 | | hud | 0.000 |
| shadows | 0.000 | | widgets | 0.000 |
| shadows2 | 0.000 | | images | 0.000 |
| ui | 0.000 | | textures | 0.000 |
| text | 0.000 | | skinning | 0.000 |
| gltf | 0.000 | | lights | 0.000 |
| pbr | 0.003 | | transparency | 0.000 |
| post | 0.000 | | decals | 0.000 |
| sprites | 0.000 | | reflections | 0.005 |
| sky | 0.001 | | instancing | 0.001 |
| fog | 0.000 | | | |

  No pixel differs by more than 16 in any of them. The canvas itself (the presented frame,
  `text` scene) is identical to WebGPU's too.
- **Fallback:** with `navigator.gpu` removed the page starts WebGL 2 on its own; with WebGL 2
  removed as well it shows the "needs WebGPU or WebGL 2" message with both reasons.
  `acro.setRenderer("webgl2")` reloads into WebGL 2, a fresh load keeps it, `?renderer=webgpu`
  overrides it, and `setRenderer("auto")` goes back to WebGPU.
- **Crowd** (446-456 draws, frames 300-600 at fixed steps, 3 alternated runs each, ms):

| Crowd | rAF callback | update | render |
|---|---|---|---|
| WebGPU | 14.0 (13.8-14.1) | 8.0 | 3.7 |
| WebGL 2 | 12.4 (12.0-12.7) | 7.8 | 2.1 |

  The render part is ~40% cheaper than WebGPU's: WebGL 2 crosses into JavaScript about 10 times a
  frame for ~443 draws (one `execute`, six ring `bufferSubData`s, the present and two timer
  reads), where WebGPU makes several calls per draw (`setPipeline`, `setVertexBuffer`,
  `setIndexBuffer`, `setBindGroup`, `drawIndexed`).

**W2.6A (material graphs, `noperspective`), same setup, release Demo, `?renderer=webgl2` with
`ENGINE_GL_DEBUG=1`, `ENGINE_SCREENSHOT` frames (1280x720, `ENGINE_OVERLAY=0`) against WebGPU:**
`graphs` (every preset, the splat terrain and its lava graph layer, all drawn with their graphs
now; no "skipped" warning) has 0 WebGL errors and matches WebGPU exactly (mean difference 0.000 /
255, 0.00% of pixels over 16). With a masked graph cube (shadow and depth prepass path) and a lava
graph decal added to the scene for a run (not committed): 0 WebGL errors, also 0.000 (the decal and the cube's striped cut-out shadow look as on WebGPU). Scenes with
debug lines (`gizmos`, `navmesh`, `physics`, `camerarigs`): 0 errors, 0.000 each. Regression
check: `decals` 0.000, `pbr` 0.002, `shadows` 0.000, `forest` 0.002, `transparency` 0.000,
`reflections` 0.003; no pixel over 16 in any of them.

**W2.7A (particles, light probes), same setup, release Demo, `ENGINE_SCREENSHOT` frames (1280x720,
`ENGINE_OVERLAY=0`) on WebGL 2 with `ENGINE_GL_DEBUG=1` against WebGPU:** 0 WebGL errors and no
"unavailable" warnings in each.

| Scene | Mean / 255 | Pixels over 16 |
|---|---|---|
| probes | 0.000 | 0.00% |
| rain | 0.010 | 0.00% |
| particles | 0.457 | 0.95% |

`probes` bakes on WebGL 2 (1 reflection probe, 90 irradiance probes, 2 bounces: 4.7 s once at
startup, WebGPU 1.2 s; each probe's synchronous readbacks stall the GPU) and its frame matches
WebGPU exactly. `particles` logs its two expected warnings (no depth-buffer collisions; the galaxy
simulates every 2nd of its 128k slots). Its residual: the sparks that bounce off the floor and the
ball diverge by rounding over their seconds of bouncing, the sparks pass through the block behind
the pillar (a depth collision on the GPU) and flash less, and the thinned galaxy is grainier at the
same brightness. Fire, smoke, mist and fireworks look the same.
CPU cost (frames 300-600 at fixed steps, `profile.mjs`, Apple M5): `particles` simulates ~62k live
particles in 3.7 ms a frame (rAF callback 4.5 ms; WebGPU 2.1 ms with 0.55 ms of compute); with the
whole galaxy (118k live, `cpuMaxCapacity` raised) 4.8 ms (callback 7.2 ms). `rain` (16k-slot
emitters) costs nothing measurable: callback 1.2 ms on both renderers. Regression check: `pbr`
0.002, `reflections` 0.003, `graphs` 0.000; no pixel over 16. Metal and Vulkan frames of
`particles`, `rain` and `probes` are byte-identical before and after (the SPIR-V didn't change).

**Known gaps:** compute itself (FSR 3 gives way to TAAU) and particle collisions against the depth
buffer (GPU-only: off with a warning on WebGL 2); emitters above 65536 slots are thinned on the
CPU; material graphs with more than 1024 values (a 16 KB uniform block) draw plain on WebGL 2. Firefox and
WebKit: see "Firefox and Safari (W2.7B)".

## Rendering parity (W2.6B, 2026-11-26)

Three places where the web renderers depended on something only Metal and Vulkan have:

- **Alpha-to-coverage without MSAA.** WebGPU refuses `alphaToCoverageEnabled` with one sample,
  and WebGL 2 ignores `SAMPLE_ALPHA_TO_COVERAGE` on single-sample framebuffers, so the fur
  scene's hair cards (`PipelineDescriptor.alphaToCoverage`, the only user today) drew every
  fragment above the shader's 0.03 cutoff at full coverage. Natively one sample with
  alpha-to-coverage is an alpha test at one half. `AlphaToCoverageFallback` (EngineBackends,
  builds everywhere) rewrites a fragment stage's generated code into one that discards below
  0.5: in naga's WGSL each `return` of the `@fragment` entry point becomes
  `{ let acroCoverage = ...; if (acroCoverage.<location 0>.w < 0.5) { discard; } return acroCoverage; }`;
  in the GLSL ES, `main` is renamed and wrapped by one that checks the location-0 output. The
  WebGPU device builds `.screen` alpha-to-coverage pipelines' one-sample variants with it (MSAA
  variants keep real alpha-to-coverage); the WebGL 2 pipeline carries a second program that
  single-sample passes use. Text rewriting, no shader compiler in the browser and no shader
  variants to generate. `AlphaToCoverageFallbackTests` checks the fur shader's rewrite with naga
  and glslangValidator (when installed) and that every generated color fragment stage can be
  rewritten.
- **Shadow edges.** WebGPU and WebGL 2 have no border color, so the comparison sampler clamps to
  the edge texel where Metal and Vulkan read a white ("lit") border. `SceneRenderer`'s
  `shadows.glsl` never relied on it (each cascade, spot and point face returns lit outside its
  tile, and PCF taps are clamped inside the tile). The Demo's own `lit.frag` (the `shadows` scene)
  did: its taps now return lit outside 0...1 themselves (`shadowTap`). Native output is unchanged
  (Metal and Vulkan `shadows` / `shadows2` frames byte-identical before and after).
- **Upscaler fallback.** An upscaler a device can't run is no longer an error at startup (or
  ignored at run time): `Engine` picks the first of `Upscaler.fallbacks` that runs (FSR 3 and
  MetalFX temporal → TAAU → FSR 1 → bilinear; MetalFX spatial and TAAU → FSR 1 → bilinear;
  sharpness carries over) and logs one line, e.g. `Upscaler FSR 3 (sharpness 0.4) can't run (not
  supported on webgpu); using TAAU (sharpness 0.4) instead`. The same applies to temporal
  upscalers on a device created with MSAA. Natively too (MetalFX on Vulkan gives TAAU).
  `UpscalerFallbackTests` covers the choice.

Results (Playwright Chromium, Apple M5, release Demo, `ENGINE_SCREENSHOT` at 2560x1440 (1280x720
at DPR 2) against Metal, mean difference / 255 and pixels over 16):

| Scene | WebGPU | WebGL 2 |
|---|---|---|
| shadows (high, 4x MSAA) | 0.000, 0.00% | 0.000, 0.00% |
| shadows2 (high, 4x MSAA) | 0.000, 0.00% | 0.000, 0.00% |
| fur (low: 1 sample, hair cards alpha-tested) | 0.001, 0.00% | 0.001, 0.00% |

0 WebGPU validation errors and 0 WebGL errors (`ENGINE_GL_DEBUG=1`) in each, and in `shadows2`
with `ENGINE_UPSCALER=fsr3,ENGINE_RESOLUTION=performance`, which runs TAAU with the log line above
on both renderers. Neither shadow scene's screenshot frame reaches a shadow map's edge, so they
matched before as well; the change removes the dependency rather than fixing a visible frame.

Gaps: falling back from a temporal upscaler to a spatial one (FSR 1) at startup still leaves
MSAA at 1x (the sample count is chosen before the device exists, and the device answers what it
supports). The rewrite relies on naga's and spirv-to-gles' output style; a shader it can't parse
keeps its stage unchanged (no alpha test) rather than failing.

## Firefox and Safari (W2.7B, 2026-11-26)

Every Demo scene and SampleGame, in Playwright's Firefox and WebKit as well as Chromium, on every
renderer each browser offers:

```sh
Scripts/web-player.sh --demo --release --no-serve                 # .build-wasm/web-demo
Scripts/web-player.sh --export Projects/SampleGame --release --no-serve
node Spikes/WebPlayerCheck/browsers.mjs .build-wasm/web-demo <out> --browsers chromium
ACRO_WEBTOOLS=<playwright 1.59 dir> node Spikes/WebPlayerCheck/browsers.mjs .build-wasm/web-demo <out> --browsers firefox,webkit
node Spikes/WebPlayerCheck/browsers.mjs .build-wasm/web-export/SampleGame <out2> --scenes none ...
node Spikes/WebPlayerCheck/browsers.mjs <site> <out> --compare-only     # the table below, from all of them
node Spikes/WebPlayerCheck/browsers.mjs <site> <out3> --extras ...     # audio, saves, renderer switch, fallback, pack cache
```

`browsers.mjs` first asks each browser what it has (WebGPU: `navigator.gpu`, an adapter and a
device with every adapter feature; WebGL 2: `getContext('webgl2')`, its renderer string and
extensions), then runs each scene on each renderer it has (`?renderer=webgpu|webgl2`) plus one
`?renderer=auto` run, each in a fresh browser context (empty storage), with `ENGINE_SCREENSHOT`,
`ENGINE_OVERLAY=0` and on WebGL 2 `ENGINE_GL_DEBUG=1`. It records the renderer and texture family
the page picked, startup, console errors and warnings (the engine's log lines by their own level),
WebGPU validation errors and WebGL errors, rAF callback times and intervals, the engine's frame
and the canvas after the engine quits (the presented frame). Frames are compared with
Chromium's on the same renderer (mean difference / 255, % of pixels with a channel off by more than 16).

**Getting the browsers to run** (macOS 27.2, Apple M5):

- Playwright 1.56 (`~/.acro-webtools`) wants `firefox-1495` / `webkit-2215`; the installed
  `firefox-1511` / `webkit-2272` belong to Playwright 1.59. `npx playwright install firefox webkit`
  fetched the 1.56 ones. **Neither of Playwright's own Firefox builds starts on macOS 27**: the
  process spins at startup (also outside Playwright, `firefox -headless --screenshot`, and with its
  sandboxes off) and Playwright's launch times out. So the Firefox runs use the installed
  **Firefox 160** (`/Applications/Firefox.app`) over WebDriver BiDi (`firefox.launch({ channel:
  'moz-firefox' })`), which needs **Playwright 1.59**; it was installed in a scratch folder and passed
  as `ACRO_WEBTOOLS` (WebKit ran from it too: WebKit 26.4, `webkit-2272`; Chromium stayed on 1.56's
  Chromium 141, the reference of earlier sections).
- **Headless Firefox has no WebGPU adapter** (`navigator.gpu` is there, `requestAdapter()` returns
  null), so Firefox runs headed. With `dom.webgpu.enabled` (and `gfx.webgpu.ignore-blocklist`) set
  through `firefoxUserPrefs` it is the same: Firefox 160 has WebGPU on by default on macOS, the prefs
  change nothing (`--browsers firefox-webgpu`). Headless, the page falls back to WebGL 2 on its own.
- **Playwright's WebKit has no WebGPU** (no `navigator.gpu`, headless or headed), so WebKit ran WebGL 2
  only, which the page picks by itself (`auto`).

What each offers:

| Browser | WebGPU | WebGL 2 | Texture compression | Notes |
|---|---|---|---|---|
| Chromium 141 | yes (Apple metal-3) | ANGLE on Metal | BC, ASTC (WebGPU); BPTC, RGTC, ASTC+HDR (WebGL) | `EXT_disjoint_timer_query_webgl2` |
| Firefox 160 (headed) | yes, by default | ANGLE on Metal ("Apple M1, or similar": renderer masked) | BC, ASTC; BPTC, RGTC, ASTC+HDR | no timer queries, `KHR_parallel_shader_compile` or `EXT_color_buffer_half_float` (has `_float`); `performance.now()` in 1 ms steps |
| WebKit 26.4 | no | Apple GPU (ANGLE on Metal) | BPTC, RGTC, ASTC+HDR | no timer queries; 1 ms `performance.now()` |

All three have AudioWorklet, IndexedDB, the Cache API and `WebAssembly.compileStreaming`. Every
page picked the BC pack (SampleGame) on every renderer.

**Results** (release builds, 1280x720, DPR 1). "Clean" is: started, the engine's frame arrived, no
page error, no error on the splash, 0 WebGPU validation errors / 0 WebGL errors:

| Browser | Renderer | Demo scenes clean | SampleGame | Frames vs Chromium (same renderer) | `auto` picks |
|---|---|---|---|---|---|
| Chromium 141 | WebGPU | 54/54 | clean | reference | WebGPU |
| Chromium 141 | WebGL 2 | 54/54 | clean | reference | |
| Firefox 160 | WebGPU | 54/54 (see below) | clean | 52 identical, worst 0.001 mean, 0% over 16 | WebGPU |
| Firefox 160 | WebGL 2 | 54/54 | clean | 53 identical, worst 0.005 (`reflections`), 0% over 16 | |
| WebKit 26.4 | WebGL 2 | 54/54 | clean | 53 identical, worst 0.005 (`reflections`), 0% over 16 | WebGL 2 (no `navigator.gpu`) |

The only warnings anywhere are the expected ones on WebGL 2 (`particles`, `rain`: GPU particles
skipped; `probes`: light probes skipped; W2.7A). One Firefox WebGPU run of `graphs` (the last scene of
the first full pass) never got its first frame in 150 s (its rAF ran at 100 ms intervals, as for a
hidden window); it passed in the four runs after it, standalone and in a batch, and in the second
full pass, so it's counted as a flake of the headed window, not a bug. The presented canvas
(7 scenes per browser) matches Chromium's exactly where the scene is still, and on WebGL 2
everywhere (worst 0.005); on Firefox WebGPU, animated scenes' canvases differ (0.59 mean in `shadows`)
only because the engine quits one or two frames later there (WebGPU captures arrive a frame or more
late, Firefox's later than Chromium's: 63-64 frames against 62), so the last presented frame is a
later one.

Same frame on all three engines' paths is expected on this machine: Chromium, Firefox and WebKit all
run WebGL 2 through ANGLE on Metal, and Chromium (Dawn) and Firefox (wgpu) WebGPU both on Metal.

**Other checks** (`--extras`, each passed in each browser unless noted):

- Audio (`audio` scene): the AudioContext runs, the worklet loads from its Blob URL and reports,
  ~146k frames sent at 48 kHz in 2.5 s, 0 underruns. Autoplay can't be checked under automation:
  every browser started the context before a click, also Chromium with
  `--autoplay-policy=user-gesture-required` and Firefox with autoplay blocked by prefs; the resume
  on a gesture is unexercised outside a real browser.
- Keyboard input and saves (`character` scene): F9 finds no save, F5 saves into IndexedDB, the page
  reloads (`[acro] user data: 1 file(s) from IndexedDB`), F9 loads it (0.0000 m from the save).
- `acro.setRenderer('webgl2')` reloads into WebGL 2 and `setRenderer('auto')` back to WebGPU
  (Chromium, Firefox; WebKit has nothing to switch to). With `navigator.gpu` hidden, Chromium and
  Firefox fall back to WebGL 2 with the reason in the console.
- Pack cache (SampleGame export): the second visit reads the pack from the Cache API in Chromium and
  Firefox. **Not in Playwright's WebKit**: the pack is stored, but the next navigation finds the
  cache empty. A five-line page that puts two entries and navigates loses them too, also with a
  persistent profile, so it's the Playwright WebKit build's storage, not the loader. Safari not
  checked.

**Frame time** (a second full pass without `ENGINE_GL_DEBUG`, browsers one after the other; rAF
callback p50 / p95 in ms over the screenshot run's ~62 fixed-step frames; Firefox and WebKit round
`performance.now()` to 1 ms). Every browser presents at 60 Hz (interval p50 16.7 ms) and the median
scene takes about 1 ms per frame in each. Heavier scenes:

| Scene | Chromium WebGPU | Firefox WebGPU | Chromium WebGL 2 | Firefox WebGL 2 | WebKit WebGL 2 |
|---|---|---|---|---|---|
| shadows | 1.3 / 2.7 | 1 / 2 | 0.7 / 1.1 | 1 / 2 | 1 / 1 |
| instancing | 1.6 / 4.2 | 2 / 4 | 1.2 / 3.4 | 1 / 3 | 1 / 3 |
| pbr | 1.3 / 1.9 | 1 / 2 | 0.7 / 1.2 | 1 / 3 | 1 / 5 |
| post | 1.3 / 2.0 | 2 / 2 | 0.9 / 1.5 | 2 / 4 | 2 / 5 |
| forest | 2.2 / 2.9 | 3 / 5 | 3.4 / 5.9 | 3 / 6 | 1 / 3 |
| graphs | 0.8 / 2.0 | 1 / 3 | 0.7 / 1.2 | 1 / 3 | 1 / 3 |
| crowd | 7.1 / 9.4 | 9 / 11 | 6.6 / 8.0 | 23 / 39 | 6 / 8 |

Crowd (450 draws, 1.06 M triangles) is the outlier: in real time Firefox's WebGL 2 runs it at ~30
fps (frame 29-32 ms, of which the engine's update is 10-11 ms and its render 2-3 ms), against 60 in
Chromium. The rest of the frame is outside the engine's update and render, most likely waiting on
Firefox's GPU process, which runs its WebGL (Chromium's timer queries put the scene pass at 11 ms
of GPU time; Firefox has no timer queries to confirm it). Not investigated further. One lead:
every instanced draw re-specifies its attributes (about 10 `bindBuffer`, `vertexAttribPointer`,
`enableVertexAttribArray` and `vertexAttribDivisor` calls each, ~4,500 a frame); caching vertex
array objects per mesh and instance-buffer offset would remove most of them. Not done here (the
WebGL 2 device's draw path; W2.7A is in it).

`ENGINE_GL_DEBUG=1` costs a lot in Chromium (median scene 21 ms per callback: `getError` after every
command is a round trip to its GPU process) and less in Firefox (13) and WebKit (6).

**Fixed:** nothing in the renderers, the loader's fallback, saves or audio needed changing. The
WebGPU "no adapter" message named `chrome://gpu` in every browser; it names `about:support` in
Firefox, `edge://gpu` in Edge, `chrome://gpu` in Chrome and nothing elsewhere.

**What this means for Safari.** Playwright's WebKit is WebKit's own MiniBrowser build with
Playwright's patches, not Safari: it has no WebGPU (Safari 26 ships it on by default), and its
storage differs (the Cache API above). So the WebKit result is strong for Safari's **WebGL 2** path
(same WebKit, same ANGLE-on-Metal backend Safari uses) and says nothing about Safari's **WebGPU**,
which is what Safari 26 will pick on `auto`. Safari's WebGPU (WebKit's own implementation on Metal,
not Dawn or wgpu) is the largest untested path; checking it needs Safari itself (`safaridriver`
with Develop › Allow Remote Automation turned on, which this run didn't do). Firefox was tested as
the shipping browser, so its results carry over, except that all of it is macOS on Apple GPUs:
Firefox on Windows (WebGPU on D3D12, WebGL on ANGLE/D3D11) and Linux were not run.

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

### Waves W2.6 and W2.7 (renderer parity)

Planned 2026-11-26 from the gaps listed under "WebGL 2 renderer" and in `WebGPURenderDevice`'s
doc comment.

**Not fixable in a browser (kept, documented):** late readbacks (`mapAsync` is asynchronous and
the main thread can't block, so captures, `readBack`, occlusion queries and GPU pass times stay a
frame or more late on WebGPU; `waitIdle` can't wait) and `vsync` (the browser presents on
`requestAnimationFrame`). WebGL 2 readbacks are already synchronous. FSR 3 on WebGL 2 is
compute-only: it falls back to another upscaler instead of being refused.

**Wave W2.6**
- **W2.6A: WebGL 2 material graphs.** A GLSL ES variant of the graph templates (`mesh_graph`,
  `mesh_graph_depth`, `decal_graph`) with the graph values in a uniform block instead of a storage
  buffer, and `MaterialGraphCompiler` splicing the graph's code into it as it does for MSL and WGSL.
  Terrain splatting comes with it. `noperspective` in `spirv-to-gles.c`: pass `v * w` and `w` and
  divide in the fragment shader (debug_line). Done: see "Material graphs (W2.6A)" under the
  WebGL 2 renderer.
- **W2.6B: WebGPU and shared rendering parity.** Alpha-to-coverage without MSAA (alpha test at 0.5
  in the shader, what one sample gives natively). Shadow lookups outside the map return lit in the
  shader, so no backend needs a border colour (WebGPU and WebGL 2 have none). Upscaler choice
  falls back (FSR 3 → TAAU) when the device can't run it, on every backend. Done: see "Rendering
  parity (W2.6B, 2026-11-26)".
- **W2.6C: Packs for every GPU family.** Web export cooks textures for ASTC and BC; the loader
  fetches the set the adapter (WebGPU features or WebGL extensions) supports. Textures in a format
  the device can't sample (no BC or ASTC at all, ASTC HDR on WebGPU) are decoded at load with
  CTextureCodec (rgba8 / rgba16f). Done: a Web export ships `game.bc.pack` and `game.astc.pack`
  and the page downloads one; see "Texture families (W2.6C)".

**Wave W2.7**
- **W2.7A: WebGL 2 GPU particles and light probes.** Particles simulate on the CPU when
  `supportsCompute` is false and draw from instance attributes; probe data moves to textures read
  with `texelFetch` in GLSL ES variants, with a fragment-pass or CPU bake. Done: see "Particles and
  light probes (W2.7A)" under the WebGL 2 renderer.
- **W2.7B: Firefox and Safari.** Playwright Firefox and WebKit (installed in `~/.acro-webtools`):
  all Demo scenes and SampleGame on each renderer each browser offers, fix what breaks, record
  results here. Done: all 54 Demo scenes and SampleGame run clean on Firefox 160 (WebGPU and
  WebGL 2) and WebKit 26.4 (WebGL 2; no WebGPU in Playwright's build), frames within 0.005 / 255 of
  Chromium's; see "Firefox and Safari (W2.7B, 2026-11-26)".
