import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineText

// Interactables, focus, prompts with input glyphs, and doors, levers, containers and pickups
// (EngineScene/Gameplay/Interaction.swift, Engine/Gameplay/InteractionSystem.swift).

@MainActor
@Suite struct InteractionTests {
    @MainActor private struct Scene {
        let world = World()
        let input = Input()
        let player: Entity
        let systems: GameplaySystems

        init() {
            player = world.spawn(Transform(), Name("InteractionTests.Player"), Interactor(range: 3, maxAngle: 60))
            systems = world.addGameplay(input: input)
        }

        /// One frame; `keys` are held during it (pressed this frame if they weren't).
        func frame(holding keys: Set<Key> = []) {
            input.beginFrame()
            for key in [Key.e, .f, .k] {
                if keys.contains(key) && !input.isDown(key) { input.inject(.key(key, down: true)) }
                if !keys.contains(key) && input.isDown(key) { input.inject(.key(key, down: false)) }
            }
            input.endEvents()
            world.update(dt: 1.0 / 60.0)
        }

        func press(_ key: Key) {
            frame(holding: [key])
            frame()
        }
    }

    @Test func focusPicksByDistanceAndViewAngle() {
        let s = Scene()
        let near = s.world.spawn(Transform(position: Vec3(0.5, 0, -2)), Name("near"), Interactable())
        let nearest = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Name("nearest"), Interactable())
        let behind = s.world.spawn(Transform(position: Vec3(0, 0, 0.8)), Name("behind"), Interactable())
        let far = s.world.spawn(Transform(position: Vec3(0, 0, -5)), Name("far"), Interactable())
        #expect(InteractionSystem.bestTarget(for: s.player, in: s.world) == nearest)
        s.world.modify(Interactable.self, for: nearest) { $0.enabled = false }
        #expect(InteractionSystem.bestTarget(for: s.player, in: s.world) == near)
        // Turned around, the one behind is in view.
        s.world.modify(Transform.self, for: s.player) { $0.rotation = Quat(angle: .pi, axis: Vec3(0, 1, 0)) }
        #expect(InteractionSystem.bestTarget(for: s.player, in: s.world) == behind)
        // Any direction with 180 degrees; nothing out of range.
        s.world.modify(Interactor.self, for: s.player) { $0.maxAngle = 180; $0.range = 0.5 }
        #expect(InteractionSystem.bestTarget(for: s.player, in: s.world) == nil)
        _ = far
        s.frame()
        #expect(s.world.interactionFocus() == nil)
    }

    @Test func doorOpensOnTheUseKeyWithAPromptAndHighlight() throws {
        let s = Scene()
        let door = s.world.spawn(Transform(position: Vec3(0, 0, -1.5)), Name("InteractionTests.Door"), Interactable(), Door(),
                                 MeshRenderer(mesh: .cube, tint: Vec3(0.5, 0.5, 0.5)))
        s.frame()
        #expect(s.world.interactionFocus() == door)
        #expect(s.systems.interaction.prompts[s.player] == "[E] Open")
        let prompt = try #require(s.world.firstEntity(named: "Interaction Prompt"))
        #expect(s.world.get(TextMesh.self, for: prompt)?.text == "[E] Open" && s.world.get(TextMesh.self, for: prompt)?.isVisible == true)
        #expect(s.world.get(MeshRenderer.self, for: door)?.tint != Vec3(0.5, 0.5, 0.5))
        s.press(.e)
        #expect(s.world.get(Door.self, for: door)?.open == true)
        #expect(s.systems.interaction.events.last?.result == "opened")
        #expect(s.world.get(Interactable.self, for: door)?.uses == 1)
        for _ in 0..<90 { s.frame() }
        let door2 = try #require(s.world.get(Door.self, for: door))
        #expect(door2.motion.progress == 1)
        let angle = 2 * acos(min(abs(s.world.get(Transform.self, for: door)!.rotation.w), 1)) * 180 / .pi
        #expect(abs(angle - 95) < 0.5, "\(angle)")
        #expect(s.systems.interaction.prompts[s.player] == "[E] Close")
        // Walking away: no focus, highlight restored, prompt hidden.
        s.world.modify(Transform.self, for: s.player) { $0.position = Vec3(0, 0, 10) }
        s.frame()
        #expect(s.world.interactionFocus() == nil)
        #expect(s.world.get(MeshRenderer.self, for: door)?.tint == Vec3(0.5, 0.5, 0.5))
        #expect(s.world.get(TextMesh.self, for: prompt)?.isVisible == false)
    }

    @Test func promptGlyphFollowsRebindingAndTheGamepad() {
        let s = Scene()
        _ = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(prompt: "Talk"))
        s.frame()
        #expect(s.systems.interaction.prompts[s.player] == "[E] Talk")
        #expect(s.systems.interaction.actions.rebind(.button("use", slot: 0), to: .key(.k)))
        s.frame()
        #expect(s.systems.interaction.prompts[s.player] == "[K] Talk")
        s.systems.interaction.prefersGamepad = true
        s.frame()
        #expect(s.systems.interaction.prompts[s.player] == "[Pad West] Talk")
        s.systems.interaction.prefersGamepad = false
        // The rebound key uses it.
        s.press(.k)
        #expect(s.systems.interaction.events.count == 1)
    }

    @Test func leverContainerPickupAndLockedDoor() throws {
        let s = Scene()
        s.world.modify(Interactor.self, for: s.player) { $0.maxAngle = 180 }
        let gate = s.world.spawn(Transform(position: Vec3(10, 0, 0)), Name("InteractionTests.Gate"), Door())
        let lever = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(), Lever(target: "InteractionTests.Gate"))
        #expect(s.systems.interaction.interact(s.player, with: lever, in: s.world)?.result == "on")
        #expect(s.world.get(Lever.self, for: lever)?.on == true && s.world.get(Door.self, for: gate)?.open == true)

        let chest = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(), Container(items: ["key": 1, "coin": 5]))
        let lid = s.world.spawn(Transform(position: Vec3(0, 0.5, -0.3)), Name("Lid"))
        _ = s.world.setParent(lid, to: chest)
        #expect(InteractionSystem.verb(for: chest, interactor: s.player, in: s.world) == "Open")
        #expect(s.systems.interaction.interact(s.player, with: chest, in: s.world)?.result == "looted")
        #expect(s.world.get(Interactor.self, for: s.player)?.items == ["key": 1, "coin": 5])
        #expect(s.world.get(Interactable.self, for: chest)?.enabled == false)
        for _ in 0..<60 { s.frame() }
        #expect(s.world.get(Transform.self, for: lid)?.rotation != .identity)

        let locked = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(), Door(locked: true, key: "gold key"))
        #expect(InteractionSystem.verb(for: locked, interactor: s.player, in: s.world) == "Locked")
        #expect(s.systems.interaction.interact(s.player, with: locked, in: s.world)?.result == "locked")
        let pickup = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(action: .pickUp), Pickup(item: "gold key"))
        #expect(InteractionSystem.verb(for: pickup, interactor: s.player, in: s.world) == "Pick up gold key")
        // The pick-up action (F) takes it; the use key doesn't.
        s.world.modify(Interactable.self, for: lever) { $0.enabled = false }
        s.world.modify(Interactable.self, for: locked) { $0.enabled = false }
        s.frame()
        #expect(s.world.interactionFocus() == pickup)
        s.press(.e)
        #expect(s.world.isAlive(pickup))
        s.press(.f)
        #expect(!s.world.isAlive(pickup))
        #expect(s.world.get(Interactor.self, for: s.player)?.count(of: "gold key") == 1)
        s.world.modify(Interactable.self, for: locked) { $0.enabled = true }
        #expect(s.systems.interaction.interact(s.player, with: locked, in: s.world)?.result == "unlocked")
        #expect(s.world.get(Door.self, for: locked)?.open == true)
        // Once: disabled after a use.
        let button = s.world.spawn(Transform(), Interactable(once: true))
        _ = s.systems.interaction.interact(s.player, with: button, in: s.world)
        #expect(s.world.get(Interactable.self, for: button)?.enabled == false)
        #expect(s.systems.interaction.interact(s.player, with: button, in: s.world) == nil)
    }

    @Test func onInteractRunsTheTargetsScriptAndStopRestores() {
        let s = Scene()
        VisualScriptNodes.registerEngineNodes()
        let host = VisualScriptHost()
        var lines: [String] = []
        host.log = { lines.append($0) }
        let runtime = s.world.addVisualScripts(host: host)
        VisualScriptEngineNodes.addEventSources(to: runtime)
        runtime.graphs["InteractionTests.door"] = VisualScriptGraph(
            nodes: [VisualScriptNode(id: "i", type: "event.interact"), VisualScriptNode(id: "log", type: "debug.log"),
                    VisualScriptNode(id: "off", type: "interaction.setEnabled", inputs: ["enabled": .bool(false)])],
            links: [VisualScriptLink(from: "i.out", to: "log.in"), VisualScriptLink(from: "i.result", to: "log.message"),
                    VisualScriptLink(from: "log.out", to: "off.in")])
        let door = s.world.spawn(Transform(position: Vec3(0, 0, -1)), Interactable(), Door(), MeshRenderer(mesh: .cube),
                                 VisualScript(graph: "InteractionTests.door"))
        s.frame()
        s.press(.e)
        s.frame()
        #expect(lines.count == 1 && lines.first?.hasSuffix("opened") == true, "\(lines)")
        #expect(s.world.get(Interactable.self, for: door)?.enabled == false)
        s.world.removeGameplay()
        #expect(s.world.firstEntity(named: "Interaction Prompt") == nil)
        #expect(s.world.get(MeshRenderer.self, for: door)?.tint == Vec3(1, 1, 1))
    }
}
