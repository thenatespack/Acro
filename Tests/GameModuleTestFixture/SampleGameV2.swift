import Engine

// SampleGame after a code change, for GameModuleTests' reload test: `Bobber` renamed a field
// (amplitude → height), changed one's type (speed: Float → String) and gained one (wobble);
// `Orbiter` is gone; `GameModuleTestsPulser` is new; the bob system does something else.

public struct Bobber: Component, Equatable, Sendable {
    public static let componentName = "Bobber"
    public var height: Float = 2
    public var speed: String = "fast"
    public var phase: Float = 0
    public var wobble: Float = 0.25
    public var origin: Vec3?

    public init() {}
}

public struct GameModuleTestsPulser: Component, Equatable, Sendable {
    public static let componentName = "GameModuleTestsPulser"
    public var rate: Float = 3

    public init() {}
}

@_cdecl("swift_game_engine_module_v1")
public func registerSampleGameV2(_ module: UnsafeMutableRawPointer) -> Int32 {
    GameModule.register(module) { game in
        game.name = "SampleGame"
        game.summary = "Version 2"
        game.component(Bobber.self) { Bobber() }
        game.component(GameModuleTestsPulser.self) { GameModuleTestsPulser() }
        // Lifts every bobber to origin + height, so a test can tell the new code runs.
        game.system("sample.bob") { world, _ in
            world.queryMutating(Transform.self, Bobber.self) { _, transform, bobber in
                let origin = bobber.origin ?? transform.position
                bobber.origin = origin
                transform.position.y = origin.y + bobber.height
            }
        }
    }
}
