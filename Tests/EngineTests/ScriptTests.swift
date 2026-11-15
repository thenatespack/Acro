import Foundation
import Testing
@testable import Engine

@MainActor @Suite struct ScriptTests {
    /// Counts its frames and moves its entity up by `speed` per second.
    struct Riser: Script, Equatable, Sendable {
        static let componentName = "ScriptTestsRiser"
        var speed: Float = 2
        var frames = 0

        init() {}

        mutating func update(_ context: ScriptContext) {
            frames += 1
            context.transform.position.y += speed * context.dt
            if frames == 2 { context.log("two frames") }
        }
    }

    @Test func registeredScriptRunsEveryFramePerEntity() throws {
        let module = GameModule()
        module.script(Riser.self, icon: "arrow-up")
        #expect(module.componentNames == ["ScriptTestsRiser"])
        #expect(module.systems.map(\.name) == ["script.ScriptTestsRiser"])
        #expect(module.componentIcons["ScriptTestsRiser"] == "arrow-up")
        #expect(module.components.first?.makeDefault() as? Riser == Riser())

        let world = World()
        var lines: [String] = []
        #expect(module.addSystems(to: world, context: GameContext(input: Input()) { lines.append($0) }).isEmpty)
        let placed = world.spawn(Transform(position: Vec3(0, 1, 0)), Riser())
        let bare = world.spawn(Riser())  // no transform: setting one adds it
        world.update(dt: 0.5)
        world.update(dt: 0.5)

        #expect(world.get(Riser.self, for: placed)?.frames == 2)
        #expect(world.get(Transform.self, for: placed)?.position.y == 3)
        #expect(world.get(Transform.self, for: bare)?.position.y == 2)
        #expect(lines == ["[ScriptTestsRiser] two frames", "[ScriptTestsRiser] two frames"])
    }
}
