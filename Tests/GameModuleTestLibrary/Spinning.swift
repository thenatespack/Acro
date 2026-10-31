import Engine

// The library half of a two-target game (GameModuleReloadTests): a component and the code
// that runs it, used by GameModuleTestMultiTarget. Linked into that game's module from its own
// objects (it isn't part of the host).

public struct GameModuleReloadTestsSpinner: Component, Equatable, Sendable {
    public static let componentName = "GameModuleReloadTestsSpinner"
    public var degreesPerFrame: Float = 10
    public var turned: Float = 0

    public init() {}
}

@MainActor
public enum GameModuleReloadTestsSpinning {
    /// Turns every spinner by its rate; counts the frames.
    public static func run(_ world: World) {
        frames += 1
        world.queryMutating(GameModuleReloadTestsSpinner.self) { _, spinner in spinner.turned += spinner.degreesPerFrame }
    }

    /// Frames run since the library was loaded (a static: starts over on every load).
    public static var frames = 0
}
