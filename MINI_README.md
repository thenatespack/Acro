# SwiftGameEngine (mini)

A small cross-platform game engine in Swift: **Metal on macOS, Vulkan everywhere else**. It includes an in-engine editor, an ECS, physics (3D and 2D), GPU particles, skeletal animation, audio, UI, networking, and hot-reloadable game modules. See [README.md](README.md) for the full docs.

## Quick start

```sh
# macOS (Metal). For Vulkan: brew install vulkan-loader vulkan-headers molten-vk glfw shaderc pkgconf
swift run -c release Demo
swift run -c release Demo --backend vulkan

# Linux
sudo apt install libvulkan-dev libglfw3-dev zlib1g-dev pkg-config glslc
swift run -c release Demo
```

Use `-c release` for anything performance-related. Windows builds are set up but untested (see README.md → Building → Windows).

## Common commands

```sh
swift run -c release Demo --list                      # list demo scenes
swift run -c release Demo --scene shadows --quality ultra
swift run -c release Editor [scene.json] [--project <folder>]
swift run Editor --game SampleGame --game-watch       # editor + hot-reloaded game module
swift run GameRunner SampleGame [scene.json]          # run a game module without the editor
swift run Editor --build-game Projects/SampleGame     # cook assets and build a shippable app
swift test
```

## MCP

The editor exposes every command as an MCP tool:

```sh
claude mcp add swift-engine -- swift run -c release Editor --mcp
```

The tool reference is in [docs/MCPTools.md](docs/MCPTools.md).

## Layout

| Path | What's there |
|---|---|
| `Sources/Engine/` | The engine: core loop, graphics API + Metal/Vulkan backends, scene/ECS, rendering, physics, audio, UI, text, net, assets, packaging |
| `Sources/EditorCore/`, `Sources/Editor/` | The editor (library + thin executable) |
| `Sources/Demo/` | Demo/test scenes |
| `Sources/SampleGame/`, `Sources/GameRunner/` | An example game module and its standalone runner |
| `Sources/EngineMCP/` | Model Context Protocol server |
| `Sources/C*/` | Vendored C libraries and system module maps |
| `Scripts/` | Shader compilation, scene rendering/compare, Linux CI helpers |
| `docs/` | MCP tool reference, scripting and networking design notes |
| `Tests/` | Engine and editor tests |
