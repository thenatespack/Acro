# ``Engine``

Build cross-platform 3D games in Swift, rendered with Metal on macOS and Vulkan on Linux and Windows.

## Overview

`Engine` is the runtime of Acro: the window and main loop, a backend-neutral graphics API, a physically based scene renderer, an entity-component system, assets, physics, audio, input, networking, and packaging. Games are written in plain Swift, either as a standalone ``Game`` or as a game module that the Acro editor loads and hot-reloads.

To get started, see <doc:GettingStarted>. The [Acro repository](https://github.com/thenatespack/Acro) has build instructions, the editor, and example games.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:EntitiesAndSystems>
- ``Engine/Engine``
- ``Game``
- ``EngineConfig``

### Scenes and entities

- ``World``
- ``Entity``
- ``EntityID``
- ``Component``
- ``Transform``
- ``SystemStage``
- ``WorldTime``

### Rendering

- ``SceneRenderer``
- ``Camera``
- ``MeshRenderer``
- ``MeshHandle``
- ``Material``
- ``MaterialHandle``
- ``PostFXVolume``

### Graphics API

- ``RenderDevice``
- ``RenderPass``
- ``ComputePass``
- ``Frame``
- ``GPUBuffer``
- ``GPUTexture``
- ``ComputePipeline``
- ``ShaderSource``

### Assets

- ``AssetDatabase``
- ``AssetReference``
- ``PrefabNode``
- ``DataTable``
- ``Image``

### Effects, physics, and audio

- ``ParticleEmitter``
- ``RigidBody``
- ``AudioEmitter``

### Input

- ``InputActions``

### Game modules

- ``GameModule``
- ``GameSystem``
- ``GameContext``

### Concurrency

- ``JobSystem``
