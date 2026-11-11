# Getting started

Create a window, run a game loop, and record rendering for each frame.

## Overview

A game is a class that conforms to ``Game``. ``Engine/Engine`` owns the window, the graphics device, and the main loop, and calls your game at each step of a frame:

1. ``Game/setup(engine:)`` once, before the first frame. Create GPU resources here.
2. ``Game/update(engine:dt:)`` every frame, with the elapsed time in seconds.
3. ``Game/renderOffscreen(engine:frame:)`` to record passes that run before the screen pass, such as shadow maps. It's optional.
4. ``Game/render(engine:pass:)`` to record the screen pass.

All callbacks run on the main actor.

## Add Acro to a package

Add the Acro package as a dependency and depend on the `Engine` product:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/thenatespack/Acro", branch: "main"),
],
targets: [
    .executableTarget(name: "MyGame", dependencies: [
        .product(name: "Engine", package: "Acro"),
    ]),
]
```

On Windows the package currently needs unsafe compiler and linker flags, so it can only be built as a root package there.

## Write the game

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

``EngineConfig`` also selects the graphics backend. By default it's Metal on macOS and Vulkan elsewhere; the `ENGINE_BACKEND` environment variable overrides it where that backend is available.

## Render a scene

Most games don't record draw calls by hand. Instead they keep their entities in a ``World`` and draw it with ``SceneRenderer``, which handles materials, lights, shadows, and post-processing. See <doc:EntitiesAndSystems> for how to populate a world and update it each frame.

The `SampleGame` target in the Acro repository is a complete example: a world of props drawn with ``SceneRenderer``, updated by two custom systems.

## Use the editor

The same code can run inside the Acro editor as a game module. The editor builds the module, offers its components in the inspector, runs its systems in play mode, and reloads the code when you change it while keeping the open scene. See ``GameModule`` and the repository's README.
