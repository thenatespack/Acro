# Web editor plan

The goal is the Acro editor running in a browser. This builds on the web player work
(`docs/wasm-spike.md`): waves W1 (WebGPU device, web runtime host, canvas window/input/audio)
and W2 (integration, web export, size and robustness) come first. The web editor is wave W3,
plus a W4 for hardening.

## Starting point (2026-11-23, `wasm-spike` after wave W1)

- **What already works.** The editor is about 66k lines (EditorCore 28.6k, five builder modules
  of 5.3–7.6k each, a 159-line `Editor` executable). Its whole UI is drawn by EngineUI, so it
  renders through whatever device the engine has. Once games run in the browser (W2A), the
  editor's panels, scene view, gizmos, inspectors and builders need no new rendering work.
- **Platform-specific code is limited.** 14 files use platform-specific APIs:

  | API | Uses |
  |---|---|
  | `GameModuleBuilder` | 20 |
  | `GameExporter` | 11 |
  | `FileWatcher` | 5 |
  | `DispatchQueue` | 4 |
  | `GameModuleLoader` | 3 |
  | `NSOpenPanel` / `NSSavePanel` | 2 |
  | `Process()` | 2 |

## What works, what needs a substitute, what doesn't

| Editor feature | In the browser |
|---|---|
| Scene editing, inspectors, mesh/world/2D/animation/logic builders, visual scripting, play mode | Works as is (ordinary engine code). |
| Opening and saving projects | Needs a project file-system layer (see W3A). |
| Asset import | Works with fixes. Imports run on one thread, so large ones are slower. |
| Texture compression (BC7/ASTC encoding) | Needs CTextureCodec built without threads. astc-encoder uses `std::mutex` and `condition_variable`. Planned for W2C. |
| Hot reload (`FileWatcher`) | Replaced by change notifications from the project file-system layer. |
| **Swift gameplay code** (`GameModuleBuilder`, game-module loading) | **Not possible in the browser**: there's no Swift compiler, and Wasm can't load code at run time like `dlopen`. See "Swift game code" below. |
| Export (`GameExporter`) | Web export of content-only games works: just cook a new pack for a prebuilt player. Native exports and games with Swift code need a build server. |
| MCP / agent tooling | Not available, unless a WebSocket bridge to a local relay is added later. |

## Swift game code

The core limit. Options, in order of effort:

1. **Content-only games (W3 scope).** Components, prefabs, scenes and visual scripts. Fully
   editable and playable in the browser.
2. **Compiled-in game module.** A project's Swift module is linked into its own web editor
   build (as `Spikes/WasmPlayer` links SampleGame). Editing and play mode work; changing code
   means rebuilding and redeploying the editor.
3. **Build server (later, optional).** The browser sends code to a server that runs the Swift
   Wasm toolchain and returns a new build. The page reloads and restores the editor state.
   Needs hosting and security work.

## Waves

### W3: Web editor
- **W3A: Project file-system layer.**
  - An abstraction for project storage (read, write, list, watch, pick a folder) with three backends:
    - native (FileManager and FileWatcher, as today)
    - the File System Access API (Chromium: edits a real folder on disk)
    - OPFS (all browsers, including Safari), with zip import and export of a project
  - Moves `AssetDatabase`, project scaffolding, prefs and the open/save dialogs onto it.
  - Watch out: Swift code reads files by URL in many places. Keeping URL-based reads working
    through the WASI in-memory file system, synced with the browser storage, may be the least
    invasive approach (as W1B did for engine resources).
- **W3B: Web editor target.**
  - An `EditorWeb` executable for `ENGINE_WASM=1`.
  - `Web/editor.html` and its loader.
  - Editor-only code that can't work in the browser (`GameModuleBuilder`, `GameModuleLoader`,
    `Process`, native export, MCP transports) is behind `#if !os(WASI)`, with clear "not
    available in the browser" UI states.
  - Clipboard through the async Clipboard API.
  - The app menu becomes an in-page menu bar.
  - Keyboard shortcuts that the browser reserves (⌘W, ⌘T, ⌘N) are remapped or documented.
- **W3C: Play mode and content-only workflow.**
  - Play and stop in the browser for games without Swift code.
  - Visual scripts.
  - Web export of content-only games from inside the web editor (cook a pack, download a zip
    holding the prebuilt player).
  - The compiled-in-module option (2 above) for SampleGame, as a demo.

### W4: Hardening
- **Performance:**
  - Builder operations that freeze the UI on one thread need to be split across frames (yield
    to the frame loop) or run in a Web Worker.
  - Consider `wasip1-threads` with cross-origin isolation if Worker offloading isn't enough.
- **Browsers:** Safari (OPFS only, WebGPU in Safari 26) and Firefox testing.
- **Limits:**
  - Size budget for the editor build (expect about 25–30 MB compressed before the
    FoundationEssentials work).
  - Memory: wasm32 caps memory at 4 GB, so large projects need care.
- **Optional:** the build server (option 3) and a WebSocket MCP bridge.

## Depends on (from W1/W2)
- WebGPU device and WGSL shaders (W1A).
- The `start` / `tick` / `finish` loop and the page/loader (W1B).
- Canvas window and input (W1C). The editor needs real pointer lock and IME, which were only
  stub-tested or are missing.
- Integration (W2A) and size work (W2C).
- Missing `Key` cases for punctuation and numpad keys (W1C gap). Editor shortcuts need these.
- Material-graph shaders have no WGSL path yet (W1A gap). The material graph builder needs one
  for its previews.
