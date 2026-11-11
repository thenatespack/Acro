# Cross-platform: mobile, web and consoles

How much work it would take to ship games built with the engine beyond macOS, Linux and Windows. The engine facts (file names, line counts, APIs) come from the code. The effort figures are estimates from reading it, not from trying builds. The fastest check is to build `Engine` for the iOS Simulator and see what breaks.

_Last updated 2026-11-01._

## Summary

| Platform | Graphics | Swift toolchain | Rough effort | Main blocker |
|---|---|---|---|---|
| iOS | Metal (exists) | Ships with Xcode | 1–2 weeks to first build | Main loop driven by `CADisplayLink` |
| Android | Vulkan (exists) | Official Swift SDK for Android (Swift 6.3+, early) | 2–4 weeks to first build | JNI/NativeActivity glue, `ANativeWindow`, assets in the APK |
| Web | New **WebGPU** backend | Official Swift Wasm SDK (swift.org) | 1–3 months | Third GPU backend, threads, no UDP |
| Xbox | New **Direct3D 12** backend | Swift for Windows + GDK | Months | D3D12 backend, GDK access (NDA) |
| Switch | Vulkan (supported) or NVN | **None**: needs a Swift port | Many months | Porting the Swift runtime + Foundation (NDA) |
| PlayStation | Sony's proprietary API | **None**: needs a Swift port | Many months | Swift port + a new backend (NDA) |

For scale: the Vulkan backend is about 4,200 lines and the Metal backend about 1,700. A new backend is roughly that much work plus its own shader path. Polish (GPU performance, input, store packaging) takes longer than any first build.

## Toolchain status

- **Android:** Swift 6.3 (March 2026) shipped the first official Swift SDK for Android, owned by the Swift project. It covers the language and core libraries only, and is still described as early for production. swift-java (Java interop) is pre-1.0.
- **WebAssembly:** Swift SDKs for Wasm are distributed on swift.org/install: one with the full standard library and Swift Testing, and an Embedded Swift subset. Swift 6.4 (September 2026) made JavaScriptKit's bridging much faster (BridgeJS).
- **Consoles:** no public Swift toolchain for Switch or PlayStation. Xbox runs a Windows-based OS, where Swift for Windows is the closest starting point.

Check swift.org before relying on these; they move quickly.

## What already works in our favor

- **Both GPU backends exist.** Metal runs on iOS and Vulkan runs on Android, and shaders already go through SPIR-V.
- **ASTC textures.** `TextureCodec` encodes ASTC LDR/HDR, and the cooker has `--gpu astc`, the format mobile GPUs use. Metal checks `supportsBCTextureCompression` for BC formats (`Backends/Metal/MetalRenderDevice.swift`).
- **Shipped games are statically linked.** Build Game links the game module into one executable with no `dlopen`, which iOS requires. Only the editor's hot reload (`GameModule/GameModuleLoader.swift`) uses `dlopen`.
- **Small platform layer.** `PlatformWindow` (`Platform/PlatformWindow.swift`) is a 47-line protocol. AppKit is imported in only a few files: `AppKitWindow.swift`, `AppKitTextView.swift`, `Clipboard.swift`, and the editor's `FilePicker.swift`.
- **Audio.** The vendored miniaudio supports CoreAudio (iOS) and AAudio/OpenSL ES (Android).
- **No macOS-only Metal APIs** (such as `.managed` storage) were found in the backend.

## Shared prerequisite: a per-frame tick

`Engine.run` (`Core/Engine.swift`) owns a blocking loop:

```swift
while !window.shouldClose {
    window.pollEvents(into: input)
    ...
}
```

On iOS, `UIApplicationMain` owns the main thread. On Android the OS drives the activity lifecycle. Split the loop body into a public `tick()` (events → update → render) that a platform driver calls: `CADisplayLink` on iOS, the native activity's loop or Choreographer on Android. The desktop `run` keeps calling `tick()` in its `while` loop. Do this first, since both ports depend on it.

## iOS

1. **Window:** a `UIView` backed by `CAMetalLayer` that implements `PlatformWindow`, about the size of `AppKitWindow.swift` (~300 lines). It reports `framebufferSize` and `contentScale` from the layer and handles safe areas.
2. **Main loop:** drive `tick()` from `CADisplayLink` (see above).
3. **Compile-time exclusions:** `GameModule/GameModuleBuilder.swift` and `GameModuleFastBuild.swift` use `Process()`, which doesn't exist on iOS, so they need `#if os(macOS) || os(Linux) || os(Windows)` guards. The game module loader and the MCP HTTP transport should also be desktop-only, or at least opt-in.
4. **UIKit counterparts:** clipboard (`UIPasteboard`), text input (`UITextInput` / keyboard), cursors become no-ops.
5. **Touch input:** `Input` models mouse, keyboard and gamepad only. Add touches (id, phase, position) and decide how UI widgets and `ActionMap` respond to them. A first step is mapping the primary touch to the mouse.
6. **Packaging:** an Xcode project (or a generated app bundle) that links the statically built game, embeds the `.pack` in the bundle, and handles code signing. `GamePlayer` already finds a `.pack` in the app's Resources.
7. **Lifecycle:** stop submitting GPU work in the background (`sceneDidEnterBackground`), and recreate drawables on resume and rotation.
8. **Gamepads:** the GameController framework, which the macOS gamepad source may already share.

## Android

1. **Toolchain:** the official Swift SDK for Android (Swift 6.3+). It's usable but young, so expect friction with Foundation and the C dependencies (zlib is available from the NDK; GLFW isn't needed).
2. **Entry point:** a NativeActivity or GameActivity (AGDK) shim calling into Swift over JNI, and a Gradle project that packages the engine/game `.so` and the pack into an APK/AAB.
3. **Window and surface:** replace GLFW with `ANativeWindow` and create the surface with `VK_KHR_android_surface`. Android destroys the surface on pause and recreates it on resume, so the Vulkan backend must tear down and rebuild the swapchain without losing other GPU state.
4. **Assets:** files inside the APK aren't on the file system. Read the pack through `AAssetManager` (or extract it on first launch). `UserData` / save games go to the app's internal storage path.
5. **Input:** touch and key events from `AInputEvent` (or GameActivity's input buffers), and gamepads through Android's input APIs or the AGDK Paddleboat library.
6. **Lifecycle:** pause, resume, focus changes, and low-memory callbacks.
7. **Driver variety:** mobile Vulkan drivers (Adreno, Mali, PowerVR) differ far more than lavapipe or MoltenVK do. CI on those won't catch device bugs, so test on real devices or a device farm.

## The long tail (mobile)

- **Tile-based GPUs:** check render pass load/store actions, avoid unnecessary render target resolves, and budget post-processing, shadows and particles. `low` / `medium` quality presets need to be tuned for mobile, and `ultra` won't hold up.
- **Thermals and battery:** frame rate caps, dynamic resolution (the render resolution and upscaling work helps here).
- **Memory limits:** iOS kills apps well before desktop limits. Watch texture budgets and the asset upload budget.
- **UI:** touch-sized widgets, on-screen controls, safe areas, orientation.
- **Distribution:** App Store / Play Store signing, entitlements, and store review requirements.

## Web (WebAssembly + WebGPU)

There's no NDA here, so this is the most practical of these four.

1. **Toolchain:** the official Swift Wasm SDK (WASI). JavaScriptKit/BridgeJS handles calls into browser APIs.
2. **Graphics:** browsers have neither Metal nor Vulkan. This needs a **WebGPU backend** implementing `RenderDevice`. WebGPU's model (explicit pipelines, bind groups, command encoders) is close to Metal/Vulkan, so the existing abstraction should fit. Shaders: translate the existing SPIR-V to WGSL at cook time (Tint or naga).
3. **Main loop:** drive the `tick()` refactor (see above) from `requestAnimationFrame`.
4. **Threads:** `JobSystem` uses worker threads. Wasm threads need `SharedArrayBuffer`, which requires the COOP/COEP HTTP headers, and Swift's Wasm thread support is still limited. Plan on a single-threaded fallback (run jobs inline).
5. **Foundation:** 162 of the engine's files import Foundation. The Wasm port of Foundation is incomplete, so expect gaps (file system, `Process`, sockets, some formatting).
6. **Files:** no file system. Fetch the `.pack` over HTTP into memory, and put save games in IndexedDB or `localStorage`.
7. **Audio:** Web Audio through an AudioWorklet. miniaudio's Web Audio backend targets Emscripten, not WASI, so this probably needs its own small bridge.
8. **Networking:** browsers can't open raw UDP. A `NetTransport` over WebSockets (TCP, easy) or WebRTC data channels (unreliable, closer to UDP, more setup).
9. **Download size:** Swift Wasm binaries are large, so use `-Osize`, `wasm-opt`, and strip unused code.

## Consoles

Consoles have a gate before any code. Each platform holder (Nintendo, Microsoft, Sony) must approve you as a developer, the SDKs and devkits are under NDA, and their details can't go in a public repo. Console code normally lives in a separate private repo or as a private module.

The second problem is **Swift itself**. The engine is Swift all the way down, and only Xbox has a Swift toolchain path today.

### Xbox (closest)

- The Xbox OS is Windows-based and uses the GDK. Swift for Windows exists, and the engine already has a (still-untested) Windows build, so the toolchain gap is smallest here.
- Xbox doesn't support Vulkan. It needs a **Direct3D 12 backend**, plus shaders as DXIL (SPIR-V → HLSL via SPIRV-Cross, then DXC).
- That D3D12 backend would also be useful on Windows PC.
- Also needed: GDK-specific input, users, saves, storage and certification requirements.
- The Microsoft Store/ID@Xbox program is the entry point.

### Nintendo Switch

- The Switch supports Vulkan, so the Vulkan backend may carry over (NVN, the native API, is faster).
- Swift doesn't target Horizon (Switch's OS). Porting the Swift runtime, standard library and Foundation (or the newer swift-foundation) to it is a toolchain project in its own right, and it must be done under NDA.
- An alternative is **Embedded Swift** (no runtime, no Foundation), but that would mean rewriting large parts of the engine away from Foundation and existentials.

### PlayStation

- Sony's graphics APIs are proprietary, so this needs a **new backend** and a shader path through Sony's compiler.
- Same toolchain problem as Switch: no Swift for the PlayStation OS (FreeBSD-based, Sony's Clang/LLVM toolchain). The Swift runtime and stdlib would have to be ported.
- Hardest of the four.

### Realistic options for consoles

1. **Partner with a porting studio** that already has devkits and toolchains. This is how most small engines and indie games ship on consoles.
2. **Xbox first**, through the D3D12 backend, which also helps Windows.
3. **Reduce the Foundation dependency** over time (it's the main thing that blocks every non-Apple/Linux/Windows target). Moving to swift-foundation, or isolating Foundation behind small engine APIs, makes future ports cheaper.

## Suggested order

1. Refactor `Engine.run` into `tick()` + a desktop driver (no behavior change; tests should still pass). Needed by iOS, Android and Web.
2. Build `Engine` for the iOS Simulator and fix the compile errors (`#if` guards).
3. UIKit window + `CADisplayLink` driver, then a demo scene on the simulator, then on a device. Then touch input.
4. Android: toolchain, NativeActivity shim, `ANativeWindow` surface, asset loading from the APK.
5. Web (WebGPU backend). It's the first new backend and has no NDA.
6. D3D12 backend for Windows, which then opens Xbox.
7. Switch / PlayStation only with a platform-holder agreement, ideally through a porting partner.
