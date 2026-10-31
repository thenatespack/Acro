import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Play mode as an AI playtester uses it, without a window: pause, step and time scale; input
// injected over game time reaching game systems (a test system and the built-in
// KeyboardMover); physics in the play session; Stop restoring the scene file byte for byte;
// the same flow over MCP. Also the new catalog entries, the texture dropdown and engine
// messages reaching the console.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// An editor MCP server with an initialized in-memory client.
@MainActor private struct Client {
    let session = makeSession()
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init() {
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = call("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:]])
    }

    func call(_ method: String, _ params: JSON? = nil) -> JSON {
        let id = JSON.string(UUID().uuidString)
        var message: JSON = ["jsonrpc": "2.0", "id": id, "method": .string(method)]
        if let params { message["params"] = params }
        connection.send(message)
        mcp.pump()
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
    }

    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)",
                sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    func failure(_ name: String, _ arguments: JSON = [:]) -> String {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == true, "\(name) should fail")
        return result["content"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }
}

/// A test "game": a system moving `entity` along +X at 2 units per second while D is down,
/// counting the frames Space was seen down.
@MainActor private final class TestGame {
    var spaceFrames = 0

    init(session: EditorSession, entity: Entity) {
        let input = session.gameInput
        session.world.addSystem("test.player") { [unowned self] world in
            if input.isDown(.d) { world.modify(Transform.self, for: entity) { $0.position.x += 2 * world.time.delta } }
            if input.isDown(.space) { spaceFrames += 1 }
        }
    }
}

@MainActor @Suite struct PlayControlTests {
    @Test func pauseStepAndTimeScale() {
        let session = makeSession()
        session.play()
        session.tick(dt: 0.1)
        #expect(session.playFrame == 1 && abs(session.playTime - 0.1) < 1e-12)
        session.timeScale = 0.5
        session.tick(dt: 0.1)
        #expect(abs(session.playTime - 0.15) < 1e-12)
        session.setPaused(true)
        session.tick(dt: 0.1)
        #expect(session.playFrame == 2 && abs(session.playTime - 0.15) < 1e-12)
        // Steps pause, ignore the time scale and use the world's fixed step.
        session.setPaused(false)
        #expect(session.step(frames: 3))
        #expect(session.isPaused && session.playFrame == 5 && abs(session.playTime - (0.15 + 3.0 / 60)) < 1e-12)
        session.timeScale = 1000
        #expect(session.timeScale == 100)
        session.stop()
        #expect(!session.isPaused && !session.step())
    }

    @Test func injectedInputReachesGameSystemsDeterministically() throws {
        let session = makeSession()
        let entity = session.world.spawn(Transform(), Name("Player"))
        let game = TestGame(session: session, entity: entity)
        session.play(paused: true)
        // Hold D for one second, then tap Space.
        let seconds = try session.inputPlayer.enqueue([InputStep(key: .d, duration: 1), InputStep(key: .space)])
        #expect(abs(seconds - 1) < 1e-12)
        session.step(frames: 90)
        let x = session.world.get(Transform.self, for: entity)?.position.x ?? 0
        #expect(abs(x - 2) < 1e-4, "held for exactly 60 frames of 1/60 s: \(x)")
        #expect(game.spaceFrames == 1)
        #expect(!session.gameInput.isDown(.d) && session.inputPlayer.isIdle)
        // The editor's own input never sees it, and paused frames don't consume the script.
        try session.inputPlayer.enqueue([InputStep(key: .d, duration: 0.5)])
        session.tick(dt: 1)
        #expect(session.inputPlayer.pendingCount == 2)
        session.stop()
        #expect(session.world.get(Transform.self, for: entity)?.position.x == 0)
    }

    @Test func overlappingStepsAndExplicitPressRelease() throws {
        let session = makeSession()
        session.play(paused: true)
        try session.inputPlayer.enqueue([
            InputStep(keys: [.w, .d], down: true, wait: 0.5),
            InputStep(key: .d, down: false),
            InputStep(mouseTo: Vec2(10, 20), scroll: Vec2(0, 3)),
        ])
        session.step()
        #expect(session.gameInput.isDown(.w) && session.gameInput.isDown(.d))
        session.step(frames: 30)
        #expect(session.gameInput.isDown(.w) && !session.gameInput.isDown(.d))
        #expect(session.gameInput.mousePosition == Vec2(10, 20) && session.gameInput.scrollDelta == Vec2(0, 3))
        #expect(session.gameInput.mouseDelta == Vec2(10, 20))
        #expect(throws: InputScriptError.self) { try session.inputPlayer.enqueue([InputStep()]) }
        #expect(throws: InputScriptError.self) { try session.inputPlayer.enqueue([InputStep(key: .a, duration: -1)]) }
    }

    @Test func physicsRunsInPlayAndStopRestoresTheSceneByteForByte() throws {
        let session = makeSession()
        let id = try #require(session.create(.cube, at: Vec3(0, 5, 0), name: "Crate"))
        #expect(session.addComponent(named: "Collider", to: id) && session.addComponent(named: "RigidBody", to: id))
        let before = try session.world.save()
        let systems = SystemStage.allCases.map { session.world.systemNames(in: $0) }

        session.play()
        #expect(session.physics != nil && session.playStateResult.physics)
        for _ in 0..<30 { session.tick(dt: 1.0 / 60) }
        let entity = try #require(session.world.entity(for: id))
        let y = try #require(session.world.get(Transform.self, for: entity)?.position.y)
        #expect(y < 4.9, "the crate falls: \(y)")
        session.stop()

        #expect(session.physics == nil)
        #expect(SystemStage.allCases.map { session.world.systemNames(in: $0) } == systems)
        #expect(try session.world.save() == before)
    }

    @Test func physics2DRunsInPlayAndItsFieldsAreEditable() throws {
        let client = Client()
        let session = client.session
        let id = try #require(session.create(.cube, at: Vec3(0, 5, 0), name: "Box2D"))
        #expect(session.addComponent(named: "Collider2D", to: id) && session.addComponent(named: "RigidBody2D", to: id))
        // The inspector's reflection reaches the Vec2 and enum-payload fields.
        let collider = try #require(client.tool("component.types", ["component": "Collider2D"])["components"]?.arrayValue?.first)
        let paths = collider["fields"]?.arrayValue?.compactMap { $0["path"]?.stringValue } ?? []
        #expect(paths.contains("offset"), "\(paths)")
        client.tool("component.setField", ["entity": .string(id.description), "path": "Collider2D.offset.x", "value": 0.25])
        let entity = try #require(session.world.entity(for: id))
        #expect(session.world.get(Collider2D.self, for: entity)?.offset.x == 0.25)
        let before = try session.world.save()
        let systems = SystemStage.allCases.map { session.world.systemNames(in: $0) }

        session.play()
        #expect(session.physics2D != nil)
        for _ in 0..<30 { session.tick(dt: 1.0 / 60) }
        let y = try #require(session.world.get(Transform.self, for: entity)?.position.y)
        #expect(y < 4.9, "the box falls: \(y)")
        session.stop()

        #expect(session.physics2D == nil)
        #expect(SystemStage.allCases.map { session.world.systemNames(in: $0) } == systems)
        #expect(try session.world.save() == before)
    }

    @Test func playtestOverMCP() throws {
        let client = Client()
        let session = client.session
        let created = client.tool("entity.create", ["template": "cube", "name": "Hero"])
        let hero = try #require(created["entity"]?.stringValue)
        client.tool("component.add", ["entity": .string(hero), "component": "KeyboardMover"])
        let before = try session.world.save()

        #expect(client.failure("input.inject", ["steps": [["key": "w"]]]).contains("play.start first"))
        let started = client.tool("play.start", ["paused": true])
        #expect(started["playing"] == true && started["paused"] == true)
        let injected = client.tool("input.inject", ["steps": [["key": "w", "duration": 1], ["key": "d", "duration": 0.5]]])
        #expect(injected["seconds"]?.doubleValue == 1.5)
        let stepped = client.tool("play.step", ["frames": 60])
        #expect(stepped["frame"] == 60 && stepped["keys"] == ["w"])
        // Live state: entity.get reads the world as it is now (speed 3, one second of W).
        let position = client.tool("entity.get", ["entity": .string(hero)])["components"]?["Transform"]?["position"]
        #expect(abs((position?.arrayValue?[2].doubleValue ?? 0) + 3) < 1e-3, "\(position ?? nil)")
        client.tool("play.step", ["frames": 30])
        let moved = client.tool("entity.get", ["entity": .string(hero)])["components"]?["Transform"]?["position"]
        #expect(abs((moved?.arrayValue?[0].doubleValue ?? 0) - 1.5) < 1e-3, "\(moved ?? nil)")
        // Edits while playing apply to the live world.
        client.tool("component.setField", ["entity": .string(hero), "path": "Transform.position.y", "value": 7])
        #expect(client.tool("input.state")["pending"] == 1)
        let state = client.tool("play.setTimeScale", ["scale": 2])
        #expect(state["timeScale"]?.doubleValue == 2)
        #expect(client.tool("play.pause", ["paused": false])["paused"] == false)
        #expect(client.tool("view.gameCamera", ["enabled": false])["enabled"] == false)

        client.tool("play.stop")
        #expect(try session.world.save() == before)
        #expect(client.tool("play.state")["playing"] == false)
        #expect(client.failure("play.step").contains("not playing"))
    }

    @Test func newComponentsHaveCatalogDefaults() throws {
        _ = makeSession()
        let collider = EditorComponentCatalog.makeDefault(named: "Collider") as? Collider
        #expect(collider?.shape == .box(halfExtents: Vec3(0.5, 0.5, 0.5)))
        #expect((EditorComponentCatalog.makeDefault(named: "RigidBody") as? RigidBody)?.motion == .dynamic)
        #expect((EditorComponentCatalog.makeDefault(named: "Joint") as? Joint)?.kind == .ball)
        #expect((EditorComponentCatalog.makeDefault(named: "Sprite") as? Sprite)?.atlas == SpriteAtlasHandle("sprites"))
        #expect((EditorComponentCatalog.makeDefault(named: "SpriteAnimator") as? SpriteAnimator)?.current == "idle")
        #expect((EditorComponentCatalog.makeDefault(named: "KeyboardMover") as? KeyboardMover)?.speed == 3)
        for name in ["Collider", "RigidBody", "Joint", "CharacterController", "AudioListener", "AudioEmitter", "ParticleEmitter",
                     "RigidBody2D", "Collider2D", "Joint2D", "Sprite", "SpriteAnimator", "KeyboardMover"] {
            #expect(EditorComponentCatalog.addableNames.contains(name), "\(name)")
            #expect(ComponentRegistry.type(named: name) != nil, "\(name)")
        }
        // They round-trip through a scene file.
        let session = makeSession()
        let id = try #require(session.create(.sphere))
        for name in ["Collider", "RigidBody", "CharacterController", "AudioListener", "AudioEmitter", "ParticleEmitter", "RigidBody2D", "Collider2D", "Sprite",
                     "SpriteAnimator", "KeyboardMover"] {
            #expect(session.addComponent(named: name, to: id), "\(name)")
        }
        let data = try session.world.save()
        let copy = World()
        _ = try copy.load(data)
        #expect(try copy.save() == data)
    }

    @Test func textureFieldsGetADropdownWithNone() {
        _ = makeSession()
        let choices = AssetChoices(meshes: { ["cube"] }, materials: { ["default"] }, textures: { ["sky"] })
        #expect(choices.options(component: SceneEnvironment.componentName, path: "environmentMap") == ["", "sky"])
        #expect(AssetChoices.isTextureField(component: SceneEnvironment.componentName, path: "environmentMap"))
        #expect(!AssetChoices.isTextureField(component: SceneEnvironment.componentName, path: "sky"))
        #expect(choices.options(component: SceneEnvironment.componentName, path: "sky") == nil)
        #expect(choices.options(component: MeshRenderer.componentName, path: "mesh") == ["cube"])

        let inspector = InspectorPanel(session: makeSession())
        inspector.assetChoices = choices
        #expect(inspector.grid.stringChoiceTitle?(SceneEnvironment.componentName, "environmentMap", "") == "None")
        #expect(inspector.grid.stringChoiceTitle?(SceneEnvironment.componentName, "environmentMap", "sky") == "sky")
    }

    @Test func engineMessagesReachTheConsoleAndDiagnostics() throws {
        let session = makeSession()
        let inbox = EngineMessageInbox()
        inbox.install()
        defer { EngineLog.setHandler(nil) }
        EngineLog.post(.error, "[Vulkan] Validation error: VUID-vkCmdDraw-None-02699 test")
        inbox.drain(into: session.log)
        #expect(session.log.entries.last?.level == .error)
        let diagnostics = try session.commands.run(DiagnosticsGetCommand.self, NoArguments())
        #expect(diagnostics.validation.last?.message.contains("VUID-vkCmdDraw") == true)
    }

    @Test func pauseAndStepShortcuts() {
        let mac = EditorShortcuts(shortcutModifier: .command)
        #expect(mac.action(for: KeyEvent(key: .p, modifiers: [.command, .shift])) == .togglePause)
        #expect(mac.action(for: KeyEvent(key: .p, modifiers: [.command, .alt])) == .step)
        #expect(mac.action(for: KeyEvent(key: .p, modifiers: .command)) == .togglePlay)
        #expect(mac.shortcutText(for: .step) == "⌥⌘P")
    }

    @Test func gameMCPHelpers() throws {
        var json: JSON = ["position": [1, 2, 3], "name": "a"]
        #expect(GameMCP.replace(&json, at: ["position", "1"], with: 5))
        #expect(json["position"] == [1, 5, 3])
        #expect(!GameMCP.replace(&json, at: ["missing"], with: 1))
        let world = World()
        let entity = world.spawn(Name("x"))
        let text = GameMCP.idString(entity, in: world)
        #expect(try GameMCP.entity(text, in: world) == entity)
    }
}
