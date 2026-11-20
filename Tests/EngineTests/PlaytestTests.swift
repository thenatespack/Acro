import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering
import EngineMCP

// Agent playtesting without the editor: the playtest format, the driver (input actions by name,
// the virtual gamepad, assertions, recording) over a plain world, record → replay giving the
// same checks, and the committed SampleGame playtest played headless as GameRunner --playtest
// does, plus the headless MCP server's tools.

private let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// A component the test game moves.
struct PlaytestTestsMover: Component, Equatable {
    static let componentName = "PlaytestTests.Mover"
    var speed: Float = 2
    var jumps = 0
}

/// A minimal host: a world whose system moves `PlaytestTestsMover`s right while D (or the pad's
/// left stick) is pushed and counts Space presses, with frames run on demand.
@MainActor
private final class Rig {
    let world = World()
    let input = Input()
    var inputPlayer = InputPlayer()
    var frame = 0
    var time: Double = 0
    var driver: PlaytestDriver!
    let player: Entity

    init(record: Bool = false, actions: [String: [String]] = ["right": ["key.d", "axis.leftStickX+"], "jump": ["key.space", "pad.south"]]) {
        ComponentRegistry.register(PlaytestTestsMover.self)
        player = world.spawn(Transform(position: Vec3(0, 0, 0)), Name("Player"), PlaytestTestsMover())
        world.spawn(Transform(position: Vec3(5, 0, 0)), Name("Goal"))
        let input = input
        world.addSystem("playtestTests.mover") { world in
            let stick = input.gamepads.first?.leftStick.x ?? 0
            let push = max(input.isDown(.d) ? 1 : 0, stick)
            world.queryMutating(Transform.self, PlaytestTestsMover.self) { _, transform, mover in
                transform.position.x += push * mover.speed * world.time.delta
                if input.wasPressed(.space) || input.gamepads.contains(where: { $0.wasPressed(.south) }) { mover.jumps += 1 }
            }
        }
        let target = PlaytestTarget(world: { [unowned self] in world }, input: { [unowned self] in self.input },
                                    inputPlayer: { [unowned self] in inputPlayer }, frame: { [unowned self] in frame },
                                    time: { [unowned self] in time }, fixedStep: { 1.0 / 60 },
                                    runFrames: { [unowned self] count, dt in run(count, dt: dt) })
        driver = PlaytestDriver(target: target, name: "rig", scene: "Rig.scene", actions: actions, record: record)
    }

    func run(_ count: Int, dt: Double? = nil) {
        let dt = dt ?? 1.0 / 60
        for _ in 0..<count {
            input.beginFrame()
            inputPlayer.apply(to: input)
            driver.applyFrameInput(to: input)
            input.endEvents()
            world.update(dt: dt)
            inputPlayer.advance(by: dt)
            frame += 1
            time += dt
        }
    }

    var x: Float { world.get(Transform.self, for: player)!.position.x }
}

@MainActor
@Suite struct PlaytestTests {
    // MARK: Format

    @Test func fileRoundTripsAndRejectsOtherFormats() throws {
        let playtest = Playtest(name: "walk", scene: "Scenes/Main.scene", steps: [
            .frames(2), .action("right", duration: 0.5), PlaytestStep(gamepad: PlaytestGamepadInput(axis: .leftStickX, value: 0.5)),
            PlaytestStep(input: [InputStep(key: .w, duration: 1)]),
            .assert(PlaytestAssertion(entity: "Player", field: "position.x", min: 1, near: nil)),
            .assert(PlaytestAssertion(entity: "Player", component: "Health", field: "points", equals: 3)),
        ])
        let again = try Playtest(json: playtest.json())
        #expect(again == playtest)
        #expect(again.frameCount == 2 && again.assertionCount == 2)
        // Only `steps` is needed; format and version default.
        #expect(try Playtest(json: Data(#"{"steps": [{"frames": 3}]}"#.utf8)).frameCount == 3)
        #expect(throws: PlaytestError.self) { try Playtest(json: Data(#"{"format": "Acro.Scene", "steps": []}"#.utf8)) }
        #expect(throws: PlaytestError.self) { try Playtest(json: Data(#"{"version": 9, "steps": []}"#.utf8)) }
    }

    // MARK: Driver

    @Test func actionsByNameDriveTheGame() throws {
        let rig = Rig()
        try rig.driver.perform(.action("right", duration: 1))
        try rig.driver.perform(.action("jump"))
        try rig.driver.perform(.frames(90))
        #expect(abs(rig.x - 2) < 0.05)
        #expect(rig.world.get(PlaytestTestsMover.self, for: rig.player)?.jumps == 1)
        // Pressed and released explicitly.
        try rig.driver.perform(.action("right", down: true))
        try rig.driver.perform(.frames(30))
        #expect(rig.input.isDown(.d))
        try rig.driver.perform(.action("right", down: false))
        try rig.driver.perform(.frames(30))
        #expect(!rig.input.isDown(.d) && abs(rig.x - 3) < 0.05)
        // An unknown action is an error, kept in the result.
        #expect(throws: PlaytestError.self) { try rig.driver.perform(.action("fly")) }
        #expect(rig.driver.result.errors.count == 1 && !rig.driver.result.passed)
        #expect(rig.driver.knownActions.map(\.name) == ["jump", "right"])
    }

    @Test func analogValuesAndTheVirtualGamepad() throws {
        let rig = Rig()
        // "right" has an axis source: value 0.5 sets the stick to half for one second.
        try rig.driver.perform(.action("right", duration: 1, value: 0.5))
        try rig.driver.perform(.frames(60))
        let afterHalf = rig.x
        #expect(rig.input.gamepads.count == 1 && rig.input.gamepads[0].name == "Playtest Pad")
        #expect(afterHalf > 0.4 && afterHalf < 1)  // half the stick, less the deadzone's rescale
        try rig.driver.perform(.frames(10))
        #expect(rig.x == afterHalf)
        // A pad button tapped counts once.
        try rig.driver.perform(PlaytestStep(gamepad: PlaytestGamepadInput(button: .south)))
        try rig.driver.perform(.frames(5))
        #expect(rig.world.get(PlaytestTestsMover.self, for: rig.player)?.jumps == 1)
        // An axis held until released.
        try rig.driver.perform(PlaytestStep(gamepad: PlaytestGamepadInput(axis: .leftStickX, value: 1)))
        try rig.driver.perform(.frames(30))
        #expect(abs(rig.x - afterHalf - 1) < 0.05)
        try rig.driver.perform(PlaytestStep(down: false, gamepad: PlaytestGamepadInput(axis: .leftStickX, value: 0)))
        try rig.driver.perform(.frames(10))
        #expect(abs(rig.x - afterHalf - 1) < 0.05)
        #expect(throws: PlaytestError.self) { try rig.driver.perform(PlaytestStep(gamepad: PlaytestGamepadInput(axis: .leftTrigger, value: -1))) }
    }

    @Test func assertionsCheckEntitiesFieldsTransformsAndCounts() throws {
        let rig = Rig()
        try rig.driver.perform(.action("right", duration: 1))
        try rig.driver.perform(.frames(60))
        func check(_ assertion: PlaytestAssertion) -> PlaytestCheck { rig.driver.check(assertion) }
        #expect(check(PlaytestAssertion(entity: "Player")).passed)
        #expect(check(PlaytestAssertion(entity: "player")).passed)  // any case
        #expect(check(PlaytestAssertion(entity: "Ghost", exists: false)).passed)
        #expect(!check(PlaytestAssertion(entity: "Ghost")).passed)
        #expect(check(PlaytestAssertion(entity: "Player", field: "position.x", min: 1.9, max: 2.1)).passed)
        #expect(check(PlaytestAssertion(entity: "Player", field: "position", near: [2, 0, 0], tolerance: 0.05)).passed)
        #expect(check(PlaytestAssertion(entity: "Player", component: "PlaytestTests.Mover", field: "speed", equals: 2)).passed)
        #expect(check(PlaytestAssertion(count: PlaytestCountQuery(component: "PlaytestTests.Mover"), equals: 1)).passed)
        #expect(check(PlaytestAssertion(count: PlaytestCountQuery(name: "Goal"), min: 1)).passed)
        let far = check(PlaytestAssertion(label: "reached the goal", entity: "Player", field: "position", near: [5, 0, 0]))
        #expect(!far.passed && far.label == "reached the goal" && far.message.contains("from [5, 0, 0]"))
        #expect(far.actual?.arrayValue?.count == 3 && far.frame == 60)
        let missing = check(PlaytestAssertion(entity: "Player", component: "RigidBody", field: "mass", min: 1))
        #expect(!missing.passed && missing.message.contains("has no RigidBody"))
        let notNumber = check(PlaytestAssertion(entity: "Player", field: "position", min: 1))
        #expect(!notNumber.passed && notNumber.message.contains("not a number"))
        let result = rig.driver.result
        #expect(result.checks.count == 12 && result.failedCount == 4 && !result.passed)
        #expect(result.report.contains("FAIL [frame 60] reached the goal"))
    }

    @Test func recordingReplaysWithTheSameChecks() throws {
        let rig = Rig(record: true)
        try rig.driver.perform(.frames(1))
        try rig.driver.perform(.action("right", duration: 0.5))
        rig.run(20)  // frames the host ran itself (real time): recorded as a frames step
        try rig.driver.perform(PlaytestStep(input: [InputStep(key: .space)]))
        try rig.driver.perform(.frames(40, dt: 1.0 / 30))
        try rig.driver.perform(.assert(PlaytestAssertion(entity: "Player", field: "position.x", min: 0.9)))
        try rig.driver.perform(.assert(PlaytestAssertion(entity: "Player", component: "PlaytestTests.Mover", field: "jumps", equals: 1)))
        try rig.driver.perform(.assert(PlaytestAssertion(label: "a failing one", entity: "Goal", exists: false)))
        let recording = rig.driver.finishedRecording()
        #expect(recording.steps.map { $0.frames } == [1, nil, 20, nil, 40, nil, nil, nil])
        #expect(recording.steps[4].dt == 1.0 / 30 && recording.steps[2].dt == nil)
        #expect(recording.scene == "Rig.scene" && recording.actions?["right"] != nil)
        let original = rig.driver.result

        let replay = Rig()
        let result = replay.driver.run(try Playtest(json: recording.json()))
        #expect(result.checks.map(\.passed) == original.checks.map(\.passed))
        #expect(result.checks.map(\.actual) == original.checks.map(\.actual))
        #expect(result.checks.map(\.frame) == original.checks.map(\.frame))
        #expect(!result.passed && result.failedCount == 1 && result.errors.isEmpty)
        #expect(replay.x == rig.x)
    }

    // MARK: Headless

    @Test func sampleGamePlaytestPassesHeadless() throws {
        let file = packageRoot.appendingPathComponent("Projects/SampleGame/Playtests/PlayerMoves.playtest.json")
        let playtest = try Playtest(contentsOf: file)
        let scene = PlaytestHeadlessHost.resolve(try #require(playtest.scene), from: file)
        #expect(scene.path.hasSuffix("Projects/SampleGame/Assets/Scenes/Main.scene"))
        let host = try PlaytestHeadlessHost(module: GameModule(), sceneURL: scene, log: { _ in })
        let result = host.run(playtest)
        #expect(result.passed, "\(result.report)")
        #expect(result.checks.count == playtest.assertionCount && result.frames == playtest.frameCount)
        // A changed expectation fails, with the value it saw.
        var broken = playtest
        broken.steps.append(.assert(PlaytestAssertion(label: "teleported", entity: "Player", field: "position.x", min: 10)))
        let failed = host.run(broken)
        #expect(!failed.passed && failed.failedCount == 1 && failed.checks.last?.actual?.doubleValue.map { abs($0 - 1) < 0.1 } == true)
    }

    @Test func headlessMCPServerRecordsAndReplays() throws {
        let scene = packageRoot.appendingPathComponent("Projects/SampleGame/Assets/Scenes/Main.scene")
        let host = try PlaytestHeadlessHost(module: GameModule(), sceneURL: scene, log: { _ in })
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PlaytestTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let mcp = PlaytestMCP(host: host, folder: folder)
        #expect(mcp.tools.map(\.name).contains("playtest.assert"))
        for tool in mcp.tools { #expect(tool.inputSchema["type"] == "object", "\(tool.name)") }
        _ = try mcp.call("playtest.start", ["name": "mcp walk"])
        _ = try mcp.call("play.step", ["frames": 1])
        let actions = try mcp.call("input.actions")["actions"]?.arrayValue?.compactMap { $0["name"]?.stringValue }
        #expect(actions == ["jump", "left", "right"])
        _ = try mcp.call("input.action", ["action": "right", "duration": 0.5])
        let state = try mcp.call("play.step", ["frames": 45])
        #expect(state["frame"]?.intValue == 46)
        let player = try mcp.call("entity.get", ["entity": "Player"])
        #expect(player["position"]?.arrayValue?.first?.doubleValue.map { abs($0 - 1) < 0.05 } == true)
        #expect(player["variables"]?["speed"]?.doubleValue == 2)
        let check = try mcp.call("playtest.assert", ["entity": "Player", "field": "position.x", "near": [1], "tolerance": 0.05])
        #expect(check["passed"] == true)
        let saved = try mcp.call("playtest.save", ["path": "walk"])
        #expect(saved["path"]?.stringValue?.hasSuffix("walk.playtest.json") == true && saved["assertions"]?.intValue == 1)
        let replay = try mcp.call("playtest.run", ["path": "walk.playtest.json"])
        #expect(replay["passed"] == true && replay["passedCount"]?.intValue == 1)
        #expect(throws: (any Error).self) { try mcp.call("input.action", ["action": "fly"]) }
    }
}
