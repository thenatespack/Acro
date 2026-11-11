import Engine
import GameModuleTestLibrary

// The game half of a two-target game (GameModuleReloadTests): registers the library target's
// component and runs its code. The module links both targets' objects.

@_cdecl("acro_module_v1")
public func registerMultiTargetGame(_ module: UnsafeMutableRawPointer) -> Int32 {
    GameModule.register(module) { game in
        game.name = "MultiTargetGame"
        game.summary = "A game target and a library target"
        game.component(GameModuleReloadTestsSpinner.self) { GameModuleReloadTestsSpinner() }
        game.system("multitarget.spin") { world, _ in GameModuleReloadTestsSpinning.run(world) }
    }
}
