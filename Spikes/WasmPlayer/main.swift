// WebAssembly spike (docs/wasm-spike.md): the `main.swift` GameExporter generates for a player,
// with SampleGame linked in statically. Only part of the package when ENGINE_WASM=1.
//
// Unlike the generated one, the entry point is declared with the C calling convention
// (`@_extern(c)`), as SampleGame defines it (`@_cdecl`). The generated `@_silgen_name`
// declaration uses Swift's convention, which on wasm32 adds parameters: native targets
// tolerate the mismatch, WebAssembly traps ("indirect call type mismatch").
import Engine
@_extern(c, "acro_module_v1") func gameModuleEntry(_ module: UnsafeMutableRawPointer) -> Int32
GamePlayer.main(module: { gameModuleEntry($0) })
