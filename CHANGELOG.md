# Changelog

Notable changes to Acro are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Version numbers are bumped automatically by `Scripts/version.sh`: MINOR when the public API of `Engine` or `EngineMCP` changes, PATCH for other source changes. While Acro is below 1.0, a MINOR release can contain breaking changes.

## [Unreleased]

### Added

- `CONTRIBUTING.md`, `SECURITY.md`, issue forms, and a pull request template.
- Engine API reference built with DocC (`Scripts/build-docs.sh`, `Sources/Engine/Engine.docc`) and published to GitHub Pages by the Docs workflow.

### Changed

- CI no longer renders the demo scenes; check rendering locally with `Scripts/render-scenes.sh`.
- Moved the cross-platform notes to `docs/cross-plat.md`.

### Fixed

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

[Unreleased]: https://github.com/thenatespack/Acro/compare/78f2983...HEAD
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
