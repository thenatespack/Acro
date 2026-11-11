# Contributing to Acro

Thanks for your interest in improving Acro. This guide covers how to set up a working copy, the checks a change needs to pass, and how to send it.

## Before you start

- **Bugs:** open an issue using the bug report template. Include your platform, graphics backend (Metal or Vulkan), and steps to reproduce.
- **Features and larger changes:** open an issue first to discuss the design. That avoids work on something that doesn't fit the engine's direction.
- **Security problems:** don't open a public issue; follow [SECURITY.md](SECURITY.md).

## Set up

You need Swift 6.4 (Xcode 27 on macOS). See [Building](README.md#building) for each platform's dependencies, then:

```sh
git clone <your fork>
cd Acro
Scripts/version.sh install   # once per clone: version-bump pre-commit hook and merge driver
swift build
```

Use release builds (`-c release`) when you run the demo or editor, or measure performance. Debug builds are much slower per frame.

## Making a change

### Code

- Follow the style of the surrounding code: the same naming, comment style, and file organization.
- Keep game-facing rendering code backend-neutral: use `RenderDevice`, `RenderPass`, and `ComputePass` rather than Metal or Vulkan directly.
- Guard platform-specific code with `#if os(...)` or `#if canImport(...)`. CI builds on macOS, Linux, and Windows, so a POSIX-only call such as `getuid()` breaks the Windows build.
- Avoid local variables that shadow a method of the same name (for example `let close = Button(...) { close() }`). Some compiler versions resolve the call to the variable. Call `self.close()` and name the variable `closeButton`.

### Tests

Tests use Swift Testing and live in `Tests/EngineTests`, `Tests/EditorTests`, and `Tests/EngineMCPTests`.

- Add or update tests for the behavior you change.
- Run the suites your change touches with `swift test --filter <SuiteName>`, and the full `swift test` before you open a pull request.
- Tests that wait on background work (asset loading, job systems) should wait for a condition with a timeout, not a fixed number of frames. CI runners are slower than development machines.
- `Scripts/test-suites-alone.sh` runs every suite on its own. Use it when a suite passes in the full run but might depend on state another suite sets up.

### Generated files

Some committed files are generated. Regenerate them when you change their source; CI fails if they're out of date.

| When you change | Run |
|---|---|
| Editor commands (names, parameters, docs) | `swift run Editor --mcp-tool-docs > docs/MCPTools.md`, or `UPDATE_TOOL_DOCS=1 swift test --filter ToolReferenceTests` |
| GLSL shaders (`*.vert`, `*.frag`, `*.comp`) | `Scripts/compile-shaders.sh` (needs `glslc` and SPIRV-Cross) |

### Documentation

Public API in `Engine` is documented with `///` comments, which become the [API reference](https://thenatespack.github.io/Acro/documentation/engine/). Its landing page and articles live in `Sources/Engine/Engine.docc`. Document new public symbols, and check the result locally:

```sh
Scripts/build-docs.sh            # writes the site to .build/docs
Scripts/build-docs.sh --preview  # serves it at http://localhost:8080/documentation/engine
```

The Docs workflow builds the reference for every pull request and publishes it from `main`.

### Rendering changes

Render the demo scenes on every available backend and check that they match:

```sh
Scripts/render-scenes.sh
```

CI doesn't render scenes, so this local check is the only one for rendering changes.

### Versions and the changelog

The pre-commit hook installed by `Scripts/version.sh install` bumps the engine version automatically: MINOR when the public API of `Engine` or `EngineMCP` changes, PATCH for other source changes. Don't edit `Sources/Engine/Core/EngineVersion.swift` or `.engine-version` by hand. A MAJOR bump is a maintainer decision (`Scripts/version.sh major`).

Add a line describing user-visible changes under **Unreleased** in [CHANGELOG.md](CHANGELOG.md).

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your change, with tests and regenerated files.
3. Run `swift test` and fix any failures.
4. Open a pull request and fill in the template. Keep each pull request to one change; separate refactors from behavior changes.

CI runs on macOS, Linux, and Windows for every pull request. A maintainer will review once it passes.

## License

Acro is licensed under the [Mozilla Public License 2.0](LICENSE). By contributing, you agree that your contributions are licensed under the same terms.
