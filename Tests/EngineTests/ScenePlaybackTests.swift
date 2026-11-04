import Foundation
import Testing
@testable import Engine

// Scene switching from game code (`GameContext.loadScene`, ABI 1.4) in `ScenePlayback`, the
// host exported games and GameRunner play scenes with: the request waits for the frame to end,
// the world's entities are replaced, the module's systems keep running on the new scene, and a
// bad scene leaves the current one playing.

@MainActor private func sceneData(_ names: [String]) throws -> Data {
    let world = World()
    for name in names { _ = world.spawn(Transform(), Name(name)) }
    return try world.save()
}

@MainActor private func names(in world: World) -> [String] {
    var names: [String] = []
    world.query(Name.self) { _, name in names.append(name.value) }
    return names.sorted()
}

@MainActor
@Suite struct ScenePlaybackTests {
    /// A module whose system counts frames and asks for `next` on the first frame it sees `trigger`.
    final class Probe {
        var frames = 0
        var next: String?
    }

    func makePlayback(scenes: [String: Data], probe: Probe) -> ScenePlayback {
        let module = GameModule()
        module.system("test.switcher") { world, context in
            probe.frames += 1
            if let next = probe.next {
                context.loadScene(next)
                probe.next = nil
            }
        }
        return ScenePlayback(module: module, context: GameContext(input: Input()), log: { _ in }) { path in
            guard let data = scenes[path] else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
    }

    @Test func switchesScenesBetweenFrames() throws {
        let probe = Probe()
        let playback = makePlayback(scenes: ["Menu.scene": try sceneData(["Title", "Start"]),
                                             "Level1.scene": try sceneData(["Player"])], probe: probe)
        try playback.load("Menu.scene")
        #expect(names(in: playback.world) == ["Start", "Title"])
        #expect(playback.context.scene == "Menu.scene")

        probe.next = "Level1.scene"
        playback.world.update(dt: 1.0 / 60)
        // Still the menu: the switch happens between updates.
        #expect(names(in: playback.world) == ["Start", "Title"])
        #expect(playback.context.pendingScene == "Level1.scene")
        #expect(playback.applyPendingScene())
        #expect(names(in: playback.world) == ["Player"])
        #expect(playback.context.scene == "Level1.scene")
        #expect(playback.context.pendingScene == nil)

        // The module's systems run on the new scene, once per frame (not added twice).
        let before = probe.frames
        playback.world.update(dt: 1.0 / 60)
        #expect(probe.frames == before + 1)
        #expect(!playback.applyPendingScene())

        // reloadScene starts the scene over.
        _ = playback.world.spawn(Transform(), Name("Spawned"))
        playback.context.reloadScene()
        #expect(playback.applyPendingScene())
        #expect(names(in: playback.world) == ["Player"])
    }

    @Test func failedLoadKeepsTheCurrentScene() throws {
        let probe = Probe()
        let playback = makePlayback(scenes: ["A.scene": try sceneData(["A"]), "Broken.scene": Data("not json".utf8)], probe: probe)
        try playback.load("A.scene")
        playback.context.loadScene("Missing.scene")
        #expect(!playback.applyPendingScene())
        playback.context.loadScene("Broken.scene")
        #expect(!playback.applyPendingScene())
        #expect(names(in: playback.world) == ["A"])
        #expect(playback.context.scene == "A.scene")
        playback.world.update(dt: 1.0 / 60)
        #expect(probe.frames == 1)
    }

    @Test func physicsFollowsTheScene() throws {
        let withCollider = World()
        _ = withCollider.spawn(Transform(), Name("Box"), Collider(.box(Vec3(0.5, 0.5, 0.5))))
        let playback = makePlayback(scenes: ["Physics.scene": try withCollider.save(), "Empty.scene": try sceneData(["Nothing"])],
                                    probe: Probe())
        try playback.load("Physics.scene")
        #expect(playback.physics != nil)
        playback.context.loadScene("Empty.scene")
        playback.applyPendingScene()
        #expect(playback.physics == nil)
    }
}
