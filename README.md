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
  Demo/              Spinning cubes sample + shaders
Scripts/compile-shaders.sh   GLSL -> SPIR-V
```

## How it fits together

- Games implement `Game` (`setup` / `update` / `render`) and call `Engine(config:).run(game)`.
- Rendering goes through `RenderDevice` / `RenderPass`. Each backend implements them; game code never touches Metal or Vulkan directly.
- The backend is picked by `EngineConfig.backend`, then the `ENGINE_BACKEND` env var, then the platform default (Metal on macOS, Vulkan otherwise).
- Metal pairs with a native AppKit window; Vulkan pairs with GLFW.
- Resources (`GPUBuffer`, `RenderPipeline`) are freed when you drop the last reference. Metal relies on ARC plus command buffers retaining what they use. On Vulkan, `deinit` hands the handles to a deletion queue, and they are destroyed once the fence of the last frame that could use them has signaled. Anything still alive at shutdown is destroyed with the device.
- Per-frame data (UI, debug geometry, particles) goes through `pass.setVertexData(_:)`, which copies into a per-frame ring buffer. No buffer management needed.
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
swift run Demo                      # Metal
swift run Demo --backend vulkan     # Vulkan via MoltenVK (if the Vulkan SDK is installed)
```

The Vulkan backend is compiled on macOS only when Vulkan headers are found. To get it:
`brew install vulkan-loader vulkan-headers molten-vk glfw shaderc pkgconf`.
Set `ENGINE_DISABLE_VULKAN=1` to build Metal-only.

### Linux

```sh
sudo apt install libvulkan-dev libglfw3-dev pkg-config glslc
swift run Demo
```

### Windows

Not yet wired up. `systemLibrary` targets rely on pkg-config, and the Vulkan import library there is `vulkan-1`. It will likely need a modulemap variant plus `-L` flags pointing at the Vulkan SDK and GLFW.

## Debugging aids

| Env var | Effect |
|---|---|
| `ENGINE_BACKEND=metal\|vulkan` | Force a backend |
| `ENGINE_SCREENSHOT=out.png` | Run with a fixed timestep, save frame `ENGINE_SCREENSHOT_FRAME` (default 60) and quit. Useful for golden-image tests; With `ENGINE_OVERLAY=0`, Metal and Vulkan currently produce byte-identical output for the demo (the overlay shows live timings, so it differs run to run). |
| `ENGINE_VULKAN_VALIDATION=1` | Enable `VK_LAYER_KHRONOS_validation`. On macOS with Homebrew, also set `VK_LAYER_PATH=$(brew --prefix vulkan-validationlayers)/share/vulkan/explicit_layer.d` and `DYLD_LIBRARY_PATH=$(brew --prefix vulkan-validationlayers)/lib`. Launch the binary directly, because SIP-protected wrappers such as `timeout` strip `DYLD_*`. |

`engine.saveScreenshot(to:)` captures the next frame from game code.

### Performance overlay

On by default and toggled with the backtick key (`` ` ``). Configure it with `EngineConfig.showDebugOverlay` / `debugOverlayKey` or `ENGINE_OVERLAY=0|1`. It shows FPS and average frame time, min/max over the last 120 frames, CPU time (update + render recording), GPU time (Metal command-buffer timing / Vulkan timestamp queries), draw calls and triangles, backend/GPU and resolution, plus a frame-time graph with a 60 FPS line. Bars are green under ~18 ms, yellow under ~36 ms, red above. The same numbers are available to game code as `engine.stats`.

The demo also rebuilds its mesh when you press **R**, which exercises resource release mid-run.

## Current limitations / next steps

- Static buffers are immutable after creation (use `setVertexData` for dynamic data), and Vulkan buffers live in host-visible memory (no staging upload yet).
- Per-draw data goes through push constants only: no uniform buffers, textures or samplers yet.
- One render pass per frame into the swapchain, with no offscreen targets.
- Two shader sources per shader. A single-source pipeline (e.g. Slang → SPIR-V + MSL) would remove the duplication.
