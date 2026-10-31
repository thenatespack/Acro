# Gameplay scripting: Swift game modules vs embedded Lua / Wasm

Decision record for card 606 (epic #548). What we have: game code in Swift, built as a game
module and hot-reloaded by the editor (README › Game modules and hot reload). The question: is
that enough, or should the engine embed a scripting runtime (Lua, or a WebAssembly runtime such
as wasm3 / WAMR / Wasmtime) for gameplay code?

## Measured: Swift game modules

M5 MacBook Air, debug build, editor playing the starter scene with SampleGame's components; a
one-line change in `SampleGame.swift`, then `game.reload` (five runs):

| Step | Time |
|---|---|
| `swift build --target SampleGame` (one file recompiled) | 1.26–1.41 s (0.9 s when nothing changed: mostly swift-build planning) |
| Link the target's objects into a module | 0.16–0.24 s |
| Load (copy, `dlopen` binding ~Engine symbols, register) | 0.12–0.15 s |
| Swap (serialize game components, unload, re-register, restore; scene and snapshot) | < 1 ms |
| **Command to new code running** | **1.57–1.71 s** |

The game kept playing through the reload with its state (positions, components' runtime fields,
physics) intact. A compile error leaves the old code running and puts the diagnostics in the
console. Build time grows with the game target's size (Swift compiles a module's changed files
plus whatever their types touch); a game split into several targets would rebuild only the one
that changed but needs one module per target (not supported yet).

## Comparison

Swift figures are measured above; Lua and Wasm figures are typical published ones, not measured in this engine.

| | Swift game modules (built) | Lua (e.g. Lua 5.4 / LuaJIT) | Wasm runtime |
|---|---|---|---|
| Iteration (one-line change) | ~1.7 s, with play state kept | ~10–50 ms to re-run a chunk; state kept only if the script is written for it (tables survive, closures don't) | compile to Wasm (Rust/AssemblyScript/C: 0.2–2 s) + instantiate (ms); state lives in linear memory, lost on re-instantiate unless serialized |
| Safety | None: game code runs in-process with full access; a crash or `fatalError` takes the editor down (no scene loss on disk, but unsaved edits go) | Sandboxed by construction (only what we bind); errors are catchable; infinite loops need instruction hooks | Strong sandbox (linear memory, explicit imports), fuel/epoch interruption; traps are catchable |
| Debugging | Full: Xcode / lldb attach to the editor, breakpoints in game code, Swift types, the same profiler | Separate debugger (mobdebug / VS Code adapters), print debugging in practice; no engine-side types | Poor in-engine: DWARF in Wasm is patchy across runtimes; mostly logging |
| Performance | Native, same as engine code; direct access to `World` queries, no marshalling | Interpreter 10–50× slower than Swift for math-heavy code (LuaJIT 2–5×, but no iOS JIT); every ECS access crosses a binding | Interpreted (wasm3) ~5–15× slower; JIT/AOT runtimes near native, but every host call marshals across the boundary and component data must be copied into linear memory |
| Engine API surface | All of Engine, typed, nothing to maintain | Hand-written or generated bindings for every type and call; reflection (`FieldDescriptor`, Codable) helps for components only | Same binding problem as Lua, plus a memory-layout ABI for shared data |
| Platforms | macOS, Linux (Windows untested). **iOS/tvOS: no** — loading code at run time is forbidden, so shipping builds link the game statically (fine) and on-device hot reload is impossible | Everywhere, including iOS (interpreted) and consoles | Everywhere with an interpreter; JITs not on iOS |
| Ship path | Link the game target into the app normally; the module ABI is only for the editor | Ship scripts as assets; patchable without an app update (store policies permitting) | Ship `.wasm` as assets; same |
| MCP / agent friendliness | Good: agents already edit Swift files, `game.reload` returns compiler errors and a structured report; the type checker catches mistakes before they run | Agents write Lua well, errors only at run time; reload is near-instant so the loop is fast; needs docs for our bindings | Agents must also drive a second toolchain; slowest loop of the three |
| Cost to build | Done (this card) | Weeks: runtime, bindings, ECS bridge, inspector integration, debugger story | More than Lua: runtime choice, ABI, toolchain per language |

## Recommendation

Stay Swift-only for gameplay code, with game modules and hot reload as built. The iteration loop
(~1.7 s, state preserved) is already in the range where scripting's advantage is small, while
Swift keeps the things a scripting layer would cost: native performance, the whole typed engine
API with no bindings to maintain, one debugger, one language for engine and game, and compile
errors an agent can read before anything runs. The two real gaps are safety (game code can crash
the editor) and run-time code on iOS; neither needs a second language yet.

Revisit embedding a runtime (Wasm before Lua, for its sandbox and language choice) only if one of
these becomes a requirement: modding / user-generated content, downloadable gameplay updates on
iOS or consoles, or running untrusted code (e.g. agent-written code in a shared editor).

## Follow-up card suggestions

1. **Faster rebuilds:** call `swift build` less: keep a long-lived build service or invoke
   `swiftc` for the game target directly with the flags SwiftPM used (planning is most of the 1.3 s).
2. **Crash isolation for game code:** run play mode's game systems in a child process (or at
   least catch `fatalError` via a signal handler that autosaves the scene first).
3. **Multi-target games:** several modules (or a module per target) so large games rebuild less.
4. **State that survives reload:** a hook (`GameModule.willUnload` / `didLoad`) to hand non-ECS
   game state (singletons, caches) to the new code as Codable.
5. **Keep undo across reloads:** store component values in undo steps as JSON, so the history no
   longer needs clearing.
6. **Windows support** for game modules (DLL import libraries make `dynamic_lookup` impossible:
   would need Engine as a real DLL).
7. **Only if needed:** a Wasm scripting spike (WAMR or wasm3) for sandboxed mods, behind the same
   `GameModule` registration shape.
