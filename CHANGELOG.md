# Changelog

Notable changes to Acro are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Version numbers are bumped automatically by `Scripts/version.sh`: MINOR when the public API of `Engine` or `EngineMCP` changes, PATCH for other source changes. While Acro is below 1.0, a MINOR release can contain breaking changes.

## [Unreleased]

## [0.16.0] - 2026-11-15

### Added

- Builder gap-fill: the "not done" lists of fifteen builders (see `Tools.md`), among them:
  - Pixel Sprite: selections and copy/paste, PNG sheet import (`sprite.importSheet`), tag frame events, blend modes, canvas shortcuts; the Scene and Game views draw `Sprite` components.
  - Tilemap: `.sprite` tile sets, `TilemapMotion` (animated tiles and parallax in placed maps), one-way platforms that follow rotation, canvas shortcuts.
  - GridMap: a piece import cache, multi-cell auto-join pieces, `.prefab` variants and built-in meshes as pieces, mirrored animations, shortcuts.
  - Path: `PathFollower`, click to add points, `path.flattenTerrain`, T and X junctions, miter correction.
  - Behavior Tree: a node-graph canvas, grid navigation (`NavigationArea`, `world.findPath`, `behavior.navigation`) used by moveTo, patrol, chase and flee.
  - UI / HUD: a runtime game UI layer (`UILayoutPlayer`, `world.gameUI`), screen scaling, sliders, toggles and text fields, transitions, gamepad navigation order, color pickers.
  - Dialogue: `.ui` layouts as the dialogue box (`DialogueView`, `DialogueLayoutPresenter`), portraits; conversations show in GameRunner and exported games with no game code.
  - Timeline: a dialogue track, a preview that plays clips, sounds and conversations, `holdFade`.
  - Animation Graph: retargeting (`AnimationClip.retargeted`, `animGraph.bones`), 2D blend spaces, layer masks and override layers, sub-state machines, glTF clip events, parallel animators.
  - Character: edit-mode animation (View › Animate in Scene View), retargeted glTF clips, per-part colors, clips in GameRunner.
  - Material: masked graphs in shadows and the depth prepass, graph decals, planar reflections on graphs, dragging links.
  - Visual Script: nodes for animation graphs, dialogue, timelines, behavior trees and UI layouts; a `Tag` component; step over / into / out (`vscript.step`); reroutes, groups and macros.
  - Terrain: runtime LOD switching (`MeshLOD`), per-pixel GPU splat blending with normal maps, graph materials as layers.
  - VFX: particle textures and flipbooks, sub-emitter links (with a new birth trigger).
  - Post-FX: depth of field, LUT grading (`.cube` and strip PNGs), a Scene view split preview (`view.scenePostFX`).

### Changed

- 2D physics simulates colliders at their world pose, so colliders under a parent follow it.
- The cooker ships files that timelines, visual scripts and UI layouts name by path, and keeps the sources of sprites, tilemaps, paths and terrains (`AssetCooker.keepsSource`).
- `Animator` and its blend-space and layer-mask code moved to EngineAssets; `AssetClipLoader` and `addAssetAnimationSystem` are removed (use `addSceneAnimationSystem`).

### Fixed

- The editor finishes background asset loads every frame, so a load started while a builder tab covers the Scene and Game views no longer stalls (and no longer holds MCP replies).
- Visual Script calls of pure functions computed nothing.
- Nil asset handles (such as `Decal.texture`) can be set through the inspector and `setField`.

## [0.14.1] - 2026-11-15

### Added

- The Script Editor checks scripts as you type: shortly after you stop typing, the game target is type-checked with the unsaved text (the cached `swiftc` plan replayed with `-typecheck`; nothing is built, saved or reloaded), and errors and warnings are marked in the gutter, underlined, and shown at the end of their lines. `GameModuleBuilder.typecheck(overrides:)`, `ScriptChecker`, and `GameBuildDiagnostic.severity` are new.
- Release workflow: pushing a `vX.Y.Z` tag builds the editor for macOS (`Editor.app`), Linux, and Windows (`Editor.exe`) (`Scripts/package-release.sh`, `Scripts/package-release.ps1`) and publishes them as a GitHub Release.
- Windows installer: releases include `Acro-<version>-windows-x64.msi`, which installs the editor into Program Files with Start Menu and desktop shortcuts (`Scripts\package-release.ps1 -Msi`, `Windows/Installer/Acro.wxs`, WiX v5).
- `PORTABLE=1 Scripts/make-editor-app.sh` builds an `Editor.app` without this checkout's paths, for distribution.
- `CONTRIBUTING.md`, `SECURITY.md`, issue forms, and a pull request template.
- Engine API reference built with DocC (`Scripts/build-docs.sh`, `Sources/Engine/Engine.docc`) and published to GitHub Pages by the Docs workflow.
- Windows: the editor and `GameRunner` load game modules, so Play runs game code there. A module links against the host's import library (`Editor.lib`, shipped next to `Editor.exe`) and is loaded with `LoadLibraryW`. Reloads use `swift build` and a link; the fast direct-`swiftc` rebuild is macOS and Linux only for now.
- `GameRunner --check` loads a game module, checks it shares the runner's Engine, and exits. Windows CI runs it on SampleGame.

### Changed

- Engine is split into twelve modules (EngineCore, EngineScene, EngineGraphics, EngineBackends, EngineText, EnginePhysics, EngineAudio, EngineAssets, EngineNet, EngineUI, EngineRendering, and `Engine`, which re-exports the rest), so release builds compile them in parallel: a release build of the editor takes about 96 s instead of 118 s, and after an edit in asset code 20 s instead of 68 s. `import Engine` and the `Engine` product are unchanged. The engine's resource bundle is now `Acro_EngineCore`, and `EngineVersion.swift` is in `Sources/EngineCore/Core/`. `SceneRenderer` takes a `SceneRenderHost` (`Engine` conforms) where it took an `Engine`.
- Windows: `Engine`'s library product is `.dynamic`, so Engine is compiled with its symbols exported and `swift build` also writes an `Engine.dll`.
- CI no longer renders the demo scenes; check rendering locally with `Scripts/render-scenes.sh`.
- Moved the cross-platform notes to `docs/cross-plat.md`.

### Fixed

- Windows: `Editor.exe` and `GameRunner.exe` started by double-clicking show startup errors in a message box, and on a crash a message box keeps the console window, with the error, open (`StartupErrors`). From a terminal they print as before.
- Windows release: the zip now includes the engine's resource bundle (`Acro_EngineCore.bundle`: shaders and fonts). Without it, `Editor.exe` exited as soon as it started. The packaging script only looked for Linux's `.resources` folder name.
- Windows: crash recovery files are written with the Windows `write` signature.
- Windows CI: the build links against vcpkg's zlib 1.3.2 and later, which names its import library `z.lib`.

## [0.8.4] - 2026-11-10

### Fixed

- Windows: the build no longer uses `getuid()` and `getgid()` in the Docker game exporter.
- A texture reimport test waits for loading instead of assuming a fixed number of frames.

## [0.8.3] - 2026-11-10

### Fixed

- Windows: the MCP stdio transport reads with `FileHandle.availableData`, because `fileDescriptor` is unavailable there.
- macOS CI runs on Xcode 27, the toolchain the engine is developed with.

## [0.8.2] - 2026-11-10

### Fixed

- The builder tabs compile with older Swift compilers: toolbar buttons no longer shadow the methods they call.
- Windows CI installs Swift 6.4.2.
- `docs/MCPTools.md` no longer embeds the engine version, so version bumps don't make it stale.

### Changed

- README reorganized, with builder documentation moved to `docs/Builders.md` and a continuous integration section.

## [0.8.1] - 2026-11-10

### Added

- README banner, social preview image, and the script that generates them.
- Mozilla Public License 2.0.

## [0.8.0] - 2026-11-10

### Changed

- The project is renamed Acro; remaining `swift-game-engine` identifiers now use the new name.

## [0.7.1] - 2026-11-04

### Fixed

- The editor icon test checks only built-in components.

## [0.7.0] - 2026-11-04

### Added

- Terrain Builder (`.terrain`): sculpted, painted heightmap terrain with scattered props, `terrain.*` MCP tools, and an editor tab.

## [0.6.0] - 2026-11-04

### Added

- Data Table Builder (`.table`): typed spreadsheets for game data, with validation, CSV import and export, typed runtime access, `table.*` MCP tools, and an editor tab.

## [0.5.0] - 2026-11-04

### Added

- Post-FX Builder (`.postfx`): saved camera looks with grading, vignette, chromatic aberration, and film grain; per-camera assignment and `PostFXVolume` blending; `postfx.*` MCP tools and an editor tab.

### Fixed

- `Scripts/version.sh` finds the repository root from its own path, so the pre-commit hook works in linked worktrees.

## [0.4.0] - 2026-11-04

### Added

- Sound Builder (`.sfx`): synthesized sound effects with presets, `sfx.*` MCP tools, and an editor tab.

## [0.3.0] - 2026-11-04

### Added

- VFX Builder (`.vfx`): effects made of stacked GPU particle emitters, with presets, `vfx.*` MCP tools, and an editor tab.

## [0.2.1] - 2026-11-04

### Fixed

- GitHub Actions builds across platforms.

## [0.2.0] - 2026-11-04

### Added

- Mesh Builder (`.meshbuild`): models built from primitive shapes, with materials, animation, `meshBuild.*` MCP tools, and an editor tab.
- `Tools.md` builder roadmap.

## [0.1.0] - 2026-11-04

First versioned release. Includes the Metal and Vulkan renderers, entity-component system, editor, MCP server, game modules with hot reload, asset pipeline, physics, audio, networking, packaging, decals, and planar reflections.

[Unreleased]: https://github.com/thenatespack/Acro/compare/v0.14.1...HEAD
[0.14.1]: https://github.com/thenatespack/Acro/compare/78f2983...v0.14.1
[0.8.4]: https://github.com/thenatespack/Acro/commit/78f2983
[0.8.3]: https://github.com/thenatespack/Acro/commit/e52e5d5
[0.8.2]: https://github.com/thenatespack/Acro/commit/aef9fc1
[0.8.1]: https://github.com/thenatespack/Acro/commit/b384435
[0.8.0]: https://github.com/thenatespack/Acro/commit/7a3a76a
[0.7.1]: https://github.com/thenatespack/Acro/commit/9458c71
[0.7.0]: https://github.com/thenatespack/Acro/commit/88e1878
[0.6.0]: https://github.com/thenatespack/Acro/commit/a800e39
[0.5.0]: https://github.com/thenatespack/Acro/commit/6eb4a2e
[0.4.0]: https://github.com/thenatespack/Acro/commit/8f1ef75
[0.3.0]: https://github.com/thenatespack/Acro/commit/913f10d
[0.2.1]: https://github.com/thenatespack/Acro/commit/ad3b9dc
[0.2.0]: https://github.com/thenatespack/Acro/commit/94f00f4
[0.1.0]: https://github.com/thenatespack/Acro/commit/c016ddb
