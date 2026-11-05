# Acro

Acro is a cross-platform 3D game engine and editor written in Swift. It uses Metal on macOS and Vulkan on Linux and Windows. The repository includes a runnable demo, a scene editor, an example game module, and tools for building distributable games.

## Quick start

### macOS

```sh
swift run -c release Demo
swift run -c release Editor
```

Metal is the default graphics backend. To build and run the Vulkan backend on macOS, install the Vulkan SDK components and GLFW:

```sh
brew install vulkan-loader vulkan-headers molten-vk glfw shaderc pkgconf
swift run -c release Demo --backend vulkan
```

### Linux

Install Swift, Vulkan, GLFW, zlib, and pkg-config development files, then run:

```sh
sudo apt install libvulkan-dev libglfw3-dev zlib1g-dev pkg-config glslc
swift run -c release Demo
swift run -c release Editor
```

### Windows

Windows builds use Vulkan and GLFW. The setup is documented in [Building on Windows](#windows); Windows support is configured but has not been validated on a Windows machine yet.

Use release builds for performance work. Debug builds have substantially slower per-frame CPU work.

## What’s included

- **Rendering:** a backend-neutral graphics API, Metal and Vulkan backends, physically based materials, directional and local lights, shadows, environment lighting, decals, reflections, HDR post-processing, and spatial and temporal upscaling.
- **Scene and gameplay:** an entity-component system, transform hierarchies, staged systems, undoable scene changes, animation, GPU particles, 3D and 2D physics, input actions, gamepads, and audio.
- **Assets:** glTF 2.0 / GLB and OBJ import, textures, materials, procedural textures, mesh arrays, prefabs and variants, asset tracking, file watching, and a Library cache.
- **Editor:** scene hierarchy and inspector, asset browser, viewport picking and transform gizmos, docking, game-module reload, project workflows, and MCP tools for editor commands.
- **Runtime and tools:** dynamically loaded Swift game modules, standalone game runner, settings and save games, networking, CPU profiling, debug overlays, and demo scenes.

## Run the demo

The demo is a collection of scenes for exploring engine features and checking rendering. List the available scenes or start a named scene:

```sh
swift run -c release Demo --list
swift run -c release Demo --scene shadows --quality ultra
```

Use `swift run -c release Demo --help` to see the command-line options. The demo supports backend selection, render quality and resolution, and upscaler configuration. On macOS the default backend is Metal; on Linux and Windows it is Vulkan. Set `ENGINE_BACKEND` to override the default where that backend is available.

## Use the editor

Launch the editor with an optional scene or project folder:

```sh
swift run -c release Editor [scene.json]
swift run -c release Editor --project path/to/project
```

To build and hot-reload the example game module while editing:

```sh
swift run Editor --game SampleGame --game-watch
```

The editor can expose its command registry as an MCP server. See the [MCP tool reference](docs/MCPTools.md) for available operations and schemas:

```sh
swift run -c release Editor --mcp
```

For a client that launches the editor over stdio, one example is:

```sh
claude mcp add acro -- swift run -c release Editor --mcp
```

## Make a game

Game code can be written as a type conforming to `Game`. The engine calls `setup` once, `update` each frame, and `render` to record the screen pass; `renderOffscreen` is available for work such as shadow maps.

```swift
import Engine

@MainActor
final class MyGame: Game {
    func setup(engine: Engine) throws {
        // Create game resources.
    }

    func update(engine: Engine, dt: Float) {
        // Advance the game by dt seconds.
    }

    func render(engine: Engine, pass: RenderPass) {
        // Record rendering for this frame.
    }
}

@main
enum Main {
    static func main() {
        Engine(config: EngineConfig(title: "My Game")).run(MyGame())
    }
}
```

See [Sources/SampleGame](Sources/SampleGame) for a game module with custom components and systems. Run it inside the editor or without the editor:

```sh
swift run Editor --game SampleGame
swift run GameRunner SampleGame
```

Game modules are dynamically built and loaded by the editor and `GameRunner`. The editor can watch source changes and reload game code while keeping the open scene. For project cooking and export, run `swift run Editor --help` and see the packaging options.

## Mesh Builder

Mesh Builder assets describe models as editable JSON parts, so props, vehicles, and machines can be created without a separate modeling tool. The importer produces a mesh and PBR material for each part and a prefab hierarchy; placed copies update when the source asset changes.

In the editor, use **New Mesh Build** in the asset browser, then double-click the file (or use **Open in Mesh Builder** in the inspector) to open the **Mesh Builder** tab next to the Scene view. It is a scene view of its own: the model alone on a grid, with its own camera (right-drag or middle-drag orbits, Shift pans, the wheel zooms). Click a part to select it, and drag the Move / Rotate / Scale gizmos (W / E / R) to place it; scaling grows the part's size. **Animate** previews animations live. The sidebar holds the shape buttons, part tree, per-part properties (shape, hierarchy, materials, textures) and motion buttons. Every change is saved to the file as one undo step. **Place in Scene** adds the built asset to the current scene. Mesh Builder files use the `.meshbuild` extension and live under the project’s `Assets/` folder.

The format supports boxes, spheres, hemispheres, cylinders, cones, capsules, tori, tubes, planes, wedges, pyramids, and groups. Parts can specify dimensions, local transforms, UV behavior, color, opacity, metallic and roughness values, emissive glow, and material or texture references. Animations can use authored keyframe tracks or built-in spin, bob, swing, pulse, and shake motions. Autoplay animations are compiled onto prefab parts and run in play mode.

Editor MCP clients can create and edit these assets with `meshBuild.new`, `meshBuild.edit`, `meshBuild.set`, and `meshBuild.get`, and show one in the Mesh Builder tab with `meshBuild.open`. See [docs/MCPTools.md](docs/MCPTools.md) for schemas and parameters.

## Building

The package uses Swift Package Manager. Build all products with:

```sh
swift build -c release
```

### macOS

Metal is available by default. The Vulkan backend is included when Vulkan headers are installed; set `ENGINE_DISABLE_VULKAN=1` to build without it.

### Linux

Vulkan, GLFW, zlib, and pkg-config development packages are required. On Debian or Ubuntu:

```sh
sudo apt install libvulkan-dev libglfw3-dev zlib1g-dev pkg-config glslc
```

### Windows

Windows builds require Swift for Windows, the LunarG Vulkan SDK, GLFW, and zlib. Set `VULKAN_SDK`, `GLFW_DIR`, and `ZLIB_DIR` to their install locations before building. The package uses the headers and libraries below those directories. The Windows path is configured but remains untested on a Windows machine.

```bat
set GLFW_DIR=C:\glfw-3.4.bin.WIN64
set ZLIB_DIR=C:\vcpkg\installed\x64-windows
swift build -c release
swift run -c release Demo
```

### As a package dependency

The package exports the `Engine` and `EngineMCP` libraries. Add Acro using SwiftPM, then import `Engine` in a target that depends on the `Engine` product. Windows builds currently use package-specific unsafe compiler and linker flags, so dependency use there is limited.

## Graphics backends and shaders

Game rendering uses the `RenderDevice`, `RenderPass`, and `ComputePass` APIs. Game code can share rendering logic between Metal and Vulkan without calling either native API directly. The backend can be selected in `EngineConfig.backend` or with `ENGINE_BACKEND` when supported.

Engine shaders are authored in GLSL. Generated SPIR-V and Metal shader files are committed, so ordinary package builds do not need shader compiler tools. After editing GLSL, regenerate the outputs with `Scripts/compile-shaders.sh`; this requires `glslc` and SPIRV-Cross. See the shader sections in the source documentation for binding conventions.

## Project layout

| Path | Contents |
|---|---|
| `Sources/Engine/` | Engine runtime: core, graphics, rendering, scene/ECS, assets, physics, audio, UI, text, animation, networking, and persistence |
| `Sources/Engine/Backends/` | Metal and Vulkan graphics backends |
| `Sources/EditorCore/`, `Sources/Editor/` | Editor implementation and executable |
| `Sources/Demo/` | Feature and rendering demo |
| `Sources/SampleGame/`, `Sources/GameRunner/` | Example game module and standalone runner |
| `Sources/EngineMCP/` | MCP protocol implementation |
| `Sources/C*`, `Windows/` | Vendored C libraries and system module maps |
| `Scripts/` | Shader, scene-rendering, CI, and packaging tools |
| `docs/` | MCP, networking, and scripting documentation |
| `Tests/` | Engine, editor, and MCP test suites |

## Further reading

- [Networking design and implementation](docs/Networking.md)
- [Scripting options and measurements](docs/Scripting.md)
- [Editor MCP tools](docs/MCPTools.md)
- [Cross-platform notes](cross-plat.md)

Useful commands:

```sh
swift run -c release Demo --help
swift run Editor --help
swift run GameRunner --help
Scripts/render-scenes.sh
swift test
```

## Sound Builder

Sound Builder assets (`.sfx`) generate game sound effects from synth parameters, the way procedural textures generate images: a waveform (square, saw, sine, noise), pitch slide, vibrato, arpeggio, a volume envelope (attack, sustain, decay), low-pass and high-pass filters, and bit crush. Presets (jump, coin, laser, explosion, hit, power-up, blip) come with **Randomize** and **Mutate**. The sound is rendered by pure-Swift DSP, so the same parameters and `seed` give identical samples on every platform.

In the editor, use **New Sound** in the asset browser, then double-click the file (or use **Open in Sound Builder** in the inspector) to open the **Sound Builder** tab next to the Scene view: a waveform view, a Play button (with Auto-play after each change), presets and the parameters form. Every change is saved to the file as one undo step. An `.sfx` file plays anywhere an audio file does: set an `AudioEmitter`'s `clip` to it, or load it with `AssetDatabase.loadSound`.

Editor MCP clients can use `sfx.new`, `sfx.get`, `sfx.set`, `sfx.edit` (preset, randomize, mutate, field changes), `sfx.play` (preview in the editor) and `sfx.open`. See [docs/MCPTools.md](docs/MCPTools.md) for schemas and parameters.
