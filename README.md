# SwiftGameEngine

A small cross-platform game engine in Swift: **Metal on macOS, Vulkan everywhere else**.

```
Sources/
  Engine/
    Core/            Engine loop, Game protocol, math (Mat4/Vec*), Input, FrameStats, Image (PNG writer)
    Debug/           Performance overlay + built-in 5x7 bitmap font
    Shaders/         Engine-owned shaders (overlay)
    Graphics/        Backend-agnostic API: RenderDevice, RenderPass, GPUBuffer, PipelineDescriptor, ShaderSource
    Platform/        Windows: AppKitWindow (CAMetalLayer) and GLFWWindow (Vulkan surface)
    Backends/Metal/  MetalRenderDevice
    Backends/Vulkan/ VulkanRenderDevice (+ helpers)
  CVulkan, CGLFW/    System-library module maps
  Demo/              Test scenes (Renderer + Scenes/) and their shaders
Scripts/compile-shaders.sh   GLSL -> SPIR-V
Scripts/render-scenes.sh     Render every demo scene on every backend and compare
```

## How it fits together

- Games implement `Game` (`setup` / `update` / `render`) and call `Engine(config:).run(game)`.
- Rendering goes through `RenderDevice` / `RenderPass`. Each backend implements them; game code never touches Metal or Vulkan directly.
- The backend is picked by `EngineConfig.backend`, then the `ENGINE_BACKEND` env var, then the platform default (Metal on macOS, Vulkan otherwise).
- Metal pairs with a native AppKit window; Vulkan pairs with GLFW.
- Resources (`GPUBuffer`, `RenderPipeline`) are freed when you drop the last reference. Metal relies on ARC plus command buffers retaining what they use. On Vulkan, `deinit` hands the handles to a deletion queue, and they are destroyed once the fence of the last frame that could use them has signaled. Anything still alive at shutdown is destroyed with the device.
- Per-frame data (UI, debug geometry, particles) goes through `pass.setVertexData(_:)`, which copies into a per-frame ring buffer. No buffer management needed. Data that several passes draw (e.g. instances for both the shadow and the screen pass) can be copied once with `frame.upload(_:)` in `renderOffscreen`, then bound in each pass with `pass.setVertexBuffer(_:index:)`.
- Both backends use the same conventions so one set of math works everywhere: right-handed, column-major matrices, clip depth in [0, 1], y-up clip space (Vulkan flips the viewport), counter-clockwise front faces, sRGB BGRA8 swapchains.

### Shaders

Each shader ships in two forms that follow shared binding conventions (see `ShaderSource`):

| | Metal (`name.metal`) | Vulkan (`name.vert` / `name.frag` → `.spv`) |
|---|---|---|
| Entry points | `vertex_main`, `fragment_main` | `main` |
| Vertex attribute *n* | `[[attribute(n)]]` | `layout(location = n) in` |
| Push constants (≤128 B) | `constant T& [[buffer(16)]]` | `layout(push_constant) uniform` |

MSL is compiled at runtime. GLSL must be compiled to SPIR-V with `Scripts/compile-shaders.sh` (needs `glslc`), and the `.spv` files are committed.

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
sudo apt install libvulkan-dev libglfw3-dev pkg-config glslc
swift run -c release Demo
```

### Windows

Not yet wired up. `systemLibrary` targets rely on pkg-config, and the Vulkan import library there is `vulkan-1`. It will likely need a modulemap variant plus `-L` flags pointing at the Vulkan SDK and GLFW.

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
| `ENGINE_RESOLUTION=720p\|4k\|16k\|1920x1080\|native…` | Override `EngineConfig.renderResolution` |
| `ENGINE_SCREENSHOT=out.png` | Run with a fixed timestep, ignore keyboard/mouse input, save frame `ENGINE_SCREENSHOT_FRAME` (default 60) and quit, printing average update / render / GPU times over the run (a quick benchmark). Useful for golden-image tests. With `ENGINE_OVERLAY=0`, Metal and Vulkan currently produce byte-identical output for every demo scene at every quality level, except `occlusion`, where about 100 pixels differ by one level of shading rounding. Its culling is exact on both backends: the image with culling on matches the one with culling off byte for byte. (The overlay shows live timings, so it differs run to run.) |
| `ENGINE_VULKAN_VALIDATION=1` | Enable `VK_LAYER_KHRONOS_validation`. On macOS with Homebrew, also set `VK_LAYER_PATH=$(brew --prefix vulkan-validationlayers)/share/vulkan/explicit_layer.d` and `DYLD_LIBRARY_PATH=$(brew --prefix vulkan-validationlayers)/lib`. Launch the binary directly, because SIP-protected wrappers such as `timeout` strip `DYLD_*`. |

`engine.saveScreenshot(to:)` captures the next frame from game code.

### Performance overlay

On by default and toggled with the backtick key (`` ` ``). Configure it with `EngineConfig.showDebugOverlay` / `debugOverlayKey` or `ENGINE_OVERLAY=0|1`. It shows FPS and average frame time, min/max over the last 120 frames, CPU time (update + render recording), GPU time (Metal command-buffer timing / Vulkan timestamp queries), draw calls and triangles, backend/GPU and resolution, plus a frame-time graph with a 60 FPS line. Bars are green under ~18 ms, yellow under ~36 ms, red above. The same numbers are available to game code as `engine.stats`.

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

`RenderResolution("…")` accepts `native`, the presets `144p 240p 360p 480p 540p 720p 1080p 1440p 4k 5k 8k 12k 16k`, any `<height>p` or `<n>k` (16:9), or `<width>x<height>`. Use `engine.renderSize` / `engine.aspectRatio` for projections.

Limits:
- Sizes above `device.maxTextureSize` are rejected with an error. That limit is 16384 on most GPUs and 32768 on Apple10-family GPUs such as M5, so `32k` works there.
- MSAA is reduced at startup so the multisampled targets fit in 4 GiB (16K drops to 4x, 32K to 1x). A runtime change that wouldn't fit at the current sample count is rejected with a message.
- Downscaling a huge image to the window is a single bilinear tap, so the preview shimmers. The screenshot is the real output.
- The PNG writer doesn't compress, so a 16K screenshot is about 530 MB and a 32K one about 2.1 GB.

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

Everywhere: **1–7** switch scenes, **Tab / Shift-Tab** cycle the render resolution (native, 144p … 16k), **Space** pauses animation, arrows/WASD or left-drag orbit, **Q/E** zoom, **Esc** quits. The window title shows the scene, its state, the render size, the quality and the backend.

`Scripts/render-scenes.sh [quality]` renders every scene on each available backend, writes PNGs to `.build/scene-shots/<quality>[-<resolution>]/`, and fails if the backends differ. Set `ENGINE_RESOLUTION` to render at a fixed size. Set `VALIDATE=1` to run Vulkan under the validation layers, which also fails on validation errors.

## Current limitations / next steps

- Static buffers are immutable after creation (use `setVertexData` for dynamic data), and Vulkan buffers live in host-visible memory (no staging upload yet).
- Per-draw data goes through push constants only: no uniform buffers, textures or samplers yet.
- One render pass per frame into the swapchain, with no offscreen targets.
- Two shader sources per shader. A single-source pipeline (e.g. Slang → SPIR-V + MSL) would remove the duplication.
