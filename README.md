# SwiftGameEngine

A small cross-platform game engine in Swift: **Metal on macOS, Vulkan everywhere else**.

```
Sources/
  Engine/
    Core/            Engine loop, Game protocol, math (Mat4/Vec*), Input, FrameStats, Image/PNGEncoder (compressed PNG writer)
    Debug/           Performance overlay + built-in 5x7 bitmap font
    Shaders/         Engine-owned shaders (overlay)
    Graphics/        Backend-agnostic API: RenderDevice, RenderPass, GPUBuffer, PipelineDescriptor, ShaderSource
    Platform/        Windows: AppKitWindow (CAMetalLayer) and GLFWWindow (Vulkan surface)
    Backends/Metal/  MetalRenderDevice
    Backends/Vulkan/ VulkanRenderDevice (+ helpers)
  CVulkan, CGLFW/    System-library module maps
  Demo/              Test scenes (Renderer + Scenes/) and their shaders
Scripts/compile-shaders.sh   GLSL -> SPIR-V -> MSL (+ spirv-to-msl.c, the SPIRV-Cross driver)
Scripts/render-scenes.sh     Render every demo scene on every backend and compare
```

## How it fits together

- Games implement `Game` (`setup` / `update` / `render`) and call `Engine(config:).run(game)`.
- Rendering goes through `RenderDevice` / `RenderPass`. Each backend implements them; game code never touches Metal or Vulkan directly.
- The backend is picked by `EngineConfig.backend`, then the `ENGINE_BACKEND` env var, then the platform default (Metal on macOS, Vulkan otherwise).
- Metal pairs with a native AppKit window; Vulkan pairs with GLFW.
- Resources (`GPUBuffer`, `GPUTexture`, `RenderPipeline`) are freed when you drop the last reference. Metal relies on ARC plus command buffers retaining what they use. On Vulkan, `deinit` hands the handles to a deletion queue, and they are destroyed once the fence of the last frame that could use them has signaled. Anything still alive at shutdown is destroyed with the device.
- Static buffers and textures are uploaded once at creation. On Vulkan they live in device-local memory and are filled through a staging buffer; creation blocks until the copy has finished, so create them up front rather than every frame.
- Static buffers can be edited later with `frame.updateBuffer(buffer, offset:, elements:)` (or `device.updateBuffer`) between passes, e.g. in `renderOffscreen`. The bytes are copied into the frame's transient memory and a GPU copy is recorded into the current frame, ordered after the reads of earlier frames still in flight (a barrier on Vulkan, a blit encoder on Metal). Passes begun after the call and all later frames see the new data; earlier passes of the same frame still see the old data. Calling it inside a pass traps, and a range outside the buffer throws. It is meant for occasional edits, not bulk streaming.
- Per-frame data (UI, debug geometry, particles) goes through `pass.setVertexData(_:)`, which copies into a per-frame ring buffer. No buffer management needed. Data that several passes draw (e.g. instances for both the shadow and the screen pass) can be copied once with `frame.upload(_:)` in `renderOffscreen`, then bound in each pass with `pass.setVertexBuffer(_:index:)`.
- Metal acquires the window's drawable only when the first pass that draws into the window begins. It commits everything recorded before that point first, so the GPU renders shadow maps (and an offscreen scene) while the CPU waits for the window server to hand over a drawable.
- Both backends use the same conventions so one set of math works everywhere: right-handed, column-major matrices, clip depth in [0, 1], y-up clip space (Vulkan vertex shaders end with `gl_Position.y = -gl_Position.y;` and the viewport is not flipped: a flipped viewport makes MoltenVK feed Metal mirrored geometry, which breaks bit-exactness with native Metal), counter-clockwise front faces, sRGB BGRA8 swapchains.

### Shaders

Shaders are written once, in GLSL (`name.vert` / `name.frag`). `Scripts/compile-shaders.sh` (needs `glslc` and SPIRV-Cross: `brew install shaderc spirv-cross`) regenerates everything from them:

1. `glslc` compiles each stage to SPIR-V (`name.vert.spv`), which the Vulkan backend loads.
2. `Scripts/spirv-to-msl.c`, a small driver for the SPIRV-Cross C API that the script builds into `.build/`, cross-compiles each SPIR-V stage to MSL (`name.vert.metal`, `name.frag.metal`), which the Metal backend compiles at runtime. Generated files start with a "do not edit" header and a hash of their SPIR-V. A test (`generatedMetalMatchesSPIRV`) fails if the `.metal` is stale. A fragment shader with outputs beyond `[[color(0)]]` (motion vectors) also gets `name.frag.color0.metal` with the others dropped, which the Metal backend uses for pipelines whose pass has no attachment for them. MoltenVK drops unconsumed outputs the same way, and it matters for bit-exactness: with an unconsumed output, Apple's compiler emits a different color-0 epilogue, and blending without MSAA then rounds differently.

All outputs are committed, so building the package needs neither tool. Rerun the script after editing any GLSL. MoltenVK runs our SPIR-V on Metal by converting it with the same SPIRV-Cross, so native Metal runs essentially the MSL that Vulkan-on-MoltenVK runs. This keeps the backends byte-identical. The driver differs from a plain `spirv-cross --msl` in three ways:
- It renames the entry points to `vertex_main` / `fragment_main`. The stages stay in separate files (SPIRV-Cross names its per-stage types and helpers independently, so they can't simply be concatenated). `ShaderSource.metalFragmentSource` carries the fragment file.
- It remaps resources to the Metal column of the table below. The `spirv-cross` CLI can't remap descriptor sets or push constants, hence the driver. A resource outside the table is an error.
- It undoes the Vulkan y flip with SPIRV-Cross's `flip_vert_y`, which negates `gl_Position.y` again at the end of the vertex shader (MoltenVK does the same).

Binding conventions (see `ShaderSource`). The GLSL column is what you write. Hand-written MSL (one `name.metal` with both entry points, loaded in preference to generated files) must follow the Metal column:

| | Metal | Vulkan GLSL |
|---|---|---|
| Entry points | `vertex_main`, `fragment_main` | `main` |
| Vertex attribute *n* | `[[attribute(n)]]` | `layout(location = n) in` |
| Push constants (≤128 B) | `constant T& [[buffer(16)]]` | `layout(push_constant) uniform` |
| Per-frame uniform block | `constant T& [[buffer(15)]]` | `layout(set = 0, binding = 0, std140) uniform` |
| Shadow map / image 0 | `[[texture(0)]]`, `[[sampler(0)]]` | `layout(set = 1, binding = 0) uniform sampler2DShadow` (or `sampler2D`) |
| Uniform buffer *n* (2–7) | `constant T& [[buffer(n)]]` | `layout(set = 2, binding = n, std140) uniform` |
| Texture *n* (1–7) | `texture2d<float> [[texture(n)]]` | `layout(set = 2, binding = 8 + n) uniform texture2D` |
| Sampler *n* (1–7) | `sampler [[sampler(n)]]` | `layout(set = 2, binding = 16 + n) uniform sampler` |
| Motion vectors | `[[color(1)]]` | `layout(location = 1) out` |

Buffer indices 0 and 1 are vertex buffers. On Vulkan, textures and samplers are separate descriptors: sample with `texture(sampler2D(tex, samp), uv)`. GLSL vertex shaders must end with `gl_Position.y = -gl_Position.y;` (see above).

### Textures, samplers and uniform buffers

- `device.makeTexture(pixels:width:height:format:generateMipmaps:)` creates a 2D `.rgba8Unorm` or `.rgba8Srgb` texture. Mipmaps are generated on the CPU (box filter, in linear light for sRGB), so both backends sample identical data.
- `device.makeSampler(SamplerDescriptor(filter:mipFilter:addressMode:))` returns a cached sampler (nearest/linear, mip none/nearest/linear, repeat/clamp/mirror).
- In a pass: `setTexture(_:index:)`, `setSampler(_:index:)`, `setUniformBuffer(_:index:)` for a static buffer created with `.uniform` usage, or `setUniformData(_:index:)` to copy per-draw data (≤16 KiB) into the frame's ring buffer. Pass `stage:` to bind to the vertex and/or fragment stage.
- On Vulkan, bindings are collected per pass and written into a descriptor set (set 2) allocated from the frame slot's pool on the first draw after a change. The pool is reset when that slot's fence signals.

## Building

### macOS

```sh
swift run -c release Demo                      # Metal
swift run -c release Demo --backend vulkan     # Vulkan via MoltenVK (if the Vulkan SDK is installed)
```

Use `-c release` for anything performance-related. Debug Swift is several times slower at the per-frame CPU work the scenes do (building tens of thousands of instances). In the `occlusion` scene it took 56 ms per frame in debug versus a vsync-capped 16.7 ms in release.

The Vulkan backend is compiled on macOS only when Vulkan headers are found. To get it:
`brew install vulkan-loader vulkan-headers molten-vk glfw shaderc pkgconf`.
Set `ENGINE_DISABLE_VULKAN=1` to build Metal-only.

### Linux

```sh
sudo apt install libvulkan-dev libglfw3-dev zlib1g-dev pkg-config glslc
swift run -c release Demo
```

### Windows

**Untested so far:** the setup below has not been built on a Windows machine yet. CI (`.github/workflows/windows.yml`, build only) is set up but has not run.

Needs Swift for Windows, the LunarG Vulkan SDK (sets `VULKAN_SDK`), GLFW (the prebuilt `glfw-3.4.bin.WIN64` zip works: copy `lib-vc2022` to `lib`) and zlib (e.g. `vcpkg install zlib:x64-windows`; `zlib1.dll` must be on `PATH` to run).

```bat
set GLFW_DIR=C:\glfw-3.4.bin.WIN64
set ZLIB_DIR=C:\vcpkg\installed\x64-windows
swift build -c release
swift run -c release Demo
```

`Package.swift` uses the module maps in `Windows/` (linking `vulkan-1`, `glfw3`, `zlib`) and adds `-I`/`-L` flags from `VULKAN_SDK`, `GLFW_DIR` and `ZLIB_DIR` (`include\` and `lib\` under each; the SDK uses `Include` and `Lib`). These use unsafeFlags, so on Windows the package can't be used as a dependency of another package. Recompile shaders with `Scripts\compile-shaders.ps1` (glslc and SPIRV-Cross from the SDK, clang from the Swift toolchain; untested). `Scripts/render-scenes.sh` is bash-only (use Git Bash or WSL).

### Occlusion queries

`OcclusionQuerySet(count:)` holds the results of hardware occlusion queries. In the screen pass, wrap a draw in `pass.beginOcclusionQuery(set, index:)` / `pass.endOcclusionQuery()`. `set.results[index]` then says whether any sample of that draw passed the depth test (nil until the first result arrives). The usual pattern, used by the `occlusion` demo scene:

1. Draw the big occluders, then every object whose last result wasn't `false`.
2. Draw a bounding box per object with a pipeline set to `colorWrites = false`, `depthWrite = false`, `cullMode = .none`, wrapped in a query.

Results are read back when the frame slot is reused: 3 frames later on Metal (visibility-result buffer) and 2 on Vulkan (`VK_QUERY_TYPE_OCCLUSION` pool). So an object coming into view can show up a few frames late. Padding the proxy boxes hides most of that. Treat the result as stale (e.g. draw the object) when the camera is inside or right next to its box, because the near plane can clip the proxy away. Each frame can issue at most `maxOcclusionQueriesPerFrame` (8192) queries. Skip objects outside the view first with `Frustum(viewProjection:).intersects(center:halfExtent:)`, and call `set.invalidate(index)` for them so a stale "hidden" can't arrive after they come back into view. Don't cull the shadow pass with these results: an object hidden from the camera can still cast a visible shadow. Instead, skip casters whose shadow can't reach the view. Sweep the caster's box along the light direction down to the lowest receiver and test that with `frustum.intersects(center:halfExtent:sweptBy:)`.

## Debugging aids

| Env var | Effect |
|---|---|
| `ENGINE_BACKEND=metal\|vulkan` | Force a backend |
| `ENGINE_QUALITY=low\|medium\|high\|ultra` | Override `EngineConfig.quality` |
| `ENGINE_RESOLUTION=720p\|4k\|16k\|1920x1080\|performance\|native…` | Override `EngineConfig.renderResolution` |
| `ENGINE_UPSCALER=bilinear\|fsr1\|fsr1:<sharpness>\|metalfx\|metalfx-temporal\|taau\|taau:<sharpness>` | Override `EngineConfig.upscaler` |
| `ENGINE_VSYNC=0\|1` | Override `EngineConfig.vsync`. `0` removes the frame-rate cap (Metal: `displaySyncEnabled = false`; Vulkan: mailbox, else immediate presentation) |
| `ENGINE_SCREENSHOT_SOURCE=window` | Screenshots capture the window image (after upscaling and the overlay) instead of the scene at render resolution |
| `ENGINE_SCREENSHOT=out.png` | Run with a fixed timestep, ignore keyboard/mouse input, save frame `ENGINE_SCREENSHOT_FRAME` (default 60) and quit, printing average update / render / GPU times and GPU time per pass over the run (a quick benchmark; add `ENGINE_VSYNC=0`). Useful for golden-image tests. With `ENGINE_OVERLAY=0`, Metal and Vulkan produce byte-identical output for every demo scene at every quality level. Culling in `occlusion` is exact on both backends: the image with culling on matches the one with culling off byte for byte. (The overlay shows live timings, so it differs run to run.) |
| `ENGINE_VULKAN_VALIDATION=1` | Enable `VK_LAYER_KHRONOS_validation`. On macOS with Homebrew, also set `VK_LAYER_PATH=$(brew --prefix vulkan-validationlayers)/share/vulkan/explicit_layer.d` and `DYLD_LIBRARY_PATH=$(brew --prefix vulkan-validationlayers)/lib`. Launch the binary directly, because SIP-protected wrappers such as `timeout` strip `DYLD_*`. |

`engine.saveScreenshot(to:)` captures the next frame from game code.

### Performance overlay

On by default and toggled with the backtick key (`` ` ``). Configure it with `EngineConfig.showDebugOverlay` / `debugOverlayKey` or `ENGINE_OVERLAY=0|1`. It shows FPS and average frame time, min/max over the last 120 frames, CPU time (update + render recording), GPU time and GPU time per pass (see below), draw calls and triangles, backend/GPU and vsync state, and resolution (native size, or render size → upscaled output size with the scale factor and upscaler, plus the window size when letterboxed), plus a frame-time graph with a 60 FPS line. Bars are green under ~18 ms, yellow under ~36 ms, red above. The same numbers are available to game code as `engine.stats`.

GPU time is measured per pass: `depth` (each `beginDepthPass`), `scene`, `upscale` and `window` (the last two only when rendering offscreen). Metal samples timestamps at the start and end of each pass's vertex and fragment stages, and adds the two stage durations. Vulkan writes timestamps around each render pass. The frame's GPU time is the sum of its passes on Metal and the span of its command buffer on Vulkan. On Metal, a command buffer's own span (the fallback on GPUs that can't sample at stage boundaries) also counts time spent waiting for the window server to release a drawable, which can be more than the rendering itself.

Reading the numbers:
- With vsync on, the GPU clocks down when it has headroom, so pass times read higher than with `ENGINE_VSYNC=0`.
- On macOS, even with vsync off, the window server limits how fast a window can present (120 or 240 FPS depending on the display, and it varies between runs). Most demo scenes hit that limit long before the GPU is busy. Compare GPU time with frame time to see how much headroom is left.
- The window pass's cost is the texel reads of the scene image. When downscaling it box-filters the whole footprint: on an M5 about 2–3 ms from 8K and about 20 ms from 16K (a single-tap blit was about 0.4 ms from 8K). Upscaling and native rendering are unaffected. (On Metal, the scene image deliberately has no `.pixelFormatView` usage: the flag turns off Apple GPUs' lossless compression, which made this pass 3–4x slower. Views that only drop sRGB don't need it.)

## Render quality

`EngineConfig.quality` (or `ENGINE_QUALITY`) picks a `RenderQuality` preset. The engine applies its MSAA sample count, unless `EngineConfig.sampleCount` is set explicitly. Games read the other settings from `engine.quality`:

| | low | medium | high (default) | ultra |
|---|---|---|---|---|
| MSAA (clamped to GPU support) | 1x | 2x | 4x | 8x |
| `shadowMapSize` | 1024 | 2048 | 2048 | 4096 |
| `shadowFilterRadius` (PCF taps) | 0 (1) | 1 (3x3) | 1 (3x3) | 2 (5x5) |

## Render resolution

`EngineConfig.renderResolution` (or `ENGINE_RESOLUTION`, or `engine.renderResolution` at runtime) sets the size the scene renders at, independent of the window:

- `.native` (default) renders straight to the window, as before.
- `.fixed(width:height:)` renders offscreen at that size. `beginWindowPass()` then scales the image into the window (bilinear, letterboxed to keep the aspect ratio), and the overlay is drawn at window resolution on top. Screenshots are taken at the render resolution, without the overlay.

`.scaled(factor)` renders at the window size divided by `factor` and lets the upscaler (below) bring it back up. These are the FSR-style modes `quality` (1.5), `balanced` (1.7), `performance` (2) and `ultraperformance` (3), or any `<factor>x`.

`RenderResolution("…")` accepts `native`, the presets `144p 240p 360p 480p 540p 720p 1080p 1440p 4k 5k 8k 12k 16k`, any `<height>p` or `<n>k` (16:9), or `<width>x<height>`. Use `engine.renderSize` / `engine.aspectRatio` for projections.

Limits:
- Sizes above `device.maxTextureSize` are rejected with an error. That limit is 16384 on most GPUs and 32768 on Apple10-family GPUs such as M5, so `32k` works there.
- MSAA is reduced at startup so the multisampled targets fit in 4 GiB (16K drops to 4x, 32K to 1x). A runtime change that wouldn't fit at the current sample count is rejected with a message.
- Downscaling to the window (render size above the window) box-filters the scene image in linear light: each window pixel averages the texels under it with exact area weights, up to 8 texels per axis, and 4 spread taps per axis beyond that. The result is byte-identical on Metal and Vulkan. The screenshot is the real output.
- Screenshots are compressed PNGs (system zlib, adaptive row filters, streamed in chunks): a 4K screenshot is typically 1–2 MB and a 16K one about 10 MB (scene-dependent). Encoding a 16K image takes a few seconds.

## Upscaling

`EngineConfig.upscaler` (or `ENGINE_UPSCALER`, or `engine.upscaler` at runtime) picks how an offscreen scene is scaled into the window:

| | Backends | How |
|---|---|---|
| `.bilinear` (default) | all | One bilinear tap per pixel |
| `.fsr1(sharpness:)` | all | AMD FSR 1: edge-adaptive upsampling (EASU) into a texture at the window size, then contrast-adaptive sharpening (RCAS) into the window. `sharpness` is in stops: 0 is the sharpest, default 0.2 |
| `.metalFXSpatial` | Metal | Apple's MetalFX spatial scaler, then a plain copy into the window |
| `.metalFXTemporal` | Metal | Apple's MetalFX temporal scaler, then a plain copy into the window. Temporal (see below) |
| `.taau(sharpness:)` | all | Temporal anti-aliasing upsample: accumulates jittered frames into a history at the window size (reprojected with motion vectors, clamped to the current neighborhood in YCoCg), then RCAS. Default sharpness 0.5. Temporal |

Notes:
- **Gamma:** the upscalers work on gamma-encoded values. They read the sRGB scene image through a UNORM view, and the last pass converts back to linear for the sRGB window.
- **Pixel alignment:** the output goes into a pixel-aligned letterbox rectangle, so upscaled pixels map 1:1 onto the window.
- **Cross-backend checks:** FSR 1 loads texels directly instead of using gathers, so Metal and Vulkan produce byte-identical results. Run `ENGINE_RESOLUTION=performance ENGINE_UPSCALER=fsr1 Scripts/render-scenes.sh` to check.
- **Cost:** measured in isolation on an M5 at 1280x720 → 2560x1440, FSR 1 takes about 0.9 ms (upscale) + 0.23 ms (sharpen), and MetalFX spatial about 0.77 ms + 0.23 ms (copy). That only pays off when per-pixel work costs more than that, i.e. with expensive shading or high-resolution displays. Shadow maps and vertex work don't shrink with the render size.
- **Temporal upscalers** (`metalfx-temporal`, `taau`) need three things from the game:
  - Jitter the projection with `engine.jittered(projection)` (Halton 2,3 sub-pixel offsets; `engine.jitter` / `engine.previousJitter` in render pixels, zero when inactive).
  - Write motion vectors: set `PipelineDescriptor.writesMotionVectors` and output `float2` to `[[color(1)]]` / `layout(location = 1)`. The value is previous UV − current UV from unjittered clip positions, `(prev.xy/prev.w − cur.xy/cur.w) * (0.5, −0.5)`. Pipelines without the flag leave 0 there.
  - Call `engine.resetTemporalHistory()` on camera cuts. The engine resets on resolution, window or upscaler changes.

  The engine then stores the scene's depth for the upscaler (reversed-Z follows `clearDepth`) and adds an RG16F motion attachment to the scene pass.
- **MSAA:** a temporal upscaler forces MSAA to 1x. The sample count is fixed at startup, so start with `ENGINE_UPSCALER=taau` (or `--quality low`) to be able to switch to one at runtime.
- **TAAU across backends:** it loads texels directly, so Metal and Vulkan match byte for byte (`ENGINE_RESOLUTION=performance ENGINE_UPSCALER=taau Scripts/render-scenes.sh`). On Vulkan it needs `independentBlend`.
- **Demo motion:** objects animated on the CPU have no object motion vectors and can trail slightly at fast edges; vertex-animated ones (the `occlusion` cubes) don't. Transparent pipelines don't write motion. TAAU has no depth-based disocclusion test and relies on the clamp.
- **Temporal cost** at 1280x720 → 2560x1440 on an M5: TAAU about 2 ms, MetalFX temporal about 3 ms. The MetalFX spatial timing reported under `upscale` is currently unreliably low.

## Demo scenes

```sh
swift run -c release Demo --scene shadows --quality ultra --resolution 4k   # --list prints scene names, --help describes everything
```

| # | Scene | Tests | Keys |
|---|---|---|---|
| 1 | `shadows` | Shadow mapping + PCF, static and per-frame instancing | **L** pause sun, **R** rebuild pillars (releases a buffer mid-run) |
| 2 | `instancing` | 3.6k–40k instances per draw, large transient uploads | **I** cycle grid size |
| 3 | `transparency` | Alpha blending, depth writes off, back-to-front sorting | **O** toggle sorting |
| 4 | `depth` | Depth precision from 0.05 m to 50 km | **Z** toggle standard / reversed-Z |
| 5 | `culling` | Back / front / no culling, counter-clockwise winding | |
| 6 | `churn` | Buffers, textures and pipelines created and dropped while in flight | |
| 7 | `occlusion` | Frustum, occlusion and shadow-caster culling: 169 clusters of 125 cubes in a city grid, hardware queries on bounding-box proxies, cubes animated in the vertex shader from a static buffer | **O** toggle culling, **B** show culled clusters through walls |
| 8 | `textures` | Procedural mipmapped sRGB texture with a repeat/trilinear sampler, a nearest-sampled linear texture, static and per-frame uniform buffers | **M** toggle mipmapping |

Everywhere: **1–8** switch scenes, **Tab / Shift-Tab** cycle the render resolution (native, quality, performance, 144p … 16k), **U** cycles the upscaler (temporal ones only without MSAA), **V** toggles vsync, **Space** pauses animation, arrows/WASD or left-drag orbit, **Q/E** zoom, **Esc** quits. The window title shows the scene, its state, the render size, the quality and the backend.

`Scripts/render-scenes.sh [quality]` renders every scene on each available backend, writes PNGs to `.build/scene-shots/<quality>[-<resolution>]/`, and fails if the backends differ. Set `ENGINE_RESOLUTION` to render at a fixed size. Set `ENGINE_UPSCALER` as well to compare upscaled window images. Set `VALIDATE=1` to run Vulkan under the validation layers, which also fails on validation errors.

## Current limitations / next steps

The full roadmap (ECS, assets, physics, audio, UI, in-engine editor) lives on the project task board.

- Static buffers and textures are immutable after creation (use `setVertexData` / `setUniformData` for dynamic data), and creating them on Vulkan blocks on the upload.
- Textures are RGBA8 2D only: no compressed formats, cube maps, arrays, render-to-texture for game code, or image loading from files yet.
