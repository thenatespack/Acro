import Testing
@testable import Engine

@Test func radialDeadzoneZeroesTheCentreAndRescalesTheRest() {
    #expect(Gamepad.applyDeadzone(Vec2(0.1, 0.1), deadzone: 0.2) == .zero)  // length 0.14 < 0.2
    // Just past the edge reads near zero, full deflection reads 1, direction is kept.
    let edge = Gamepad.applyDeadzone(Vec2(0.21, 0), deadzone: 0.2)
    #expect(edge.x > 0 && edge.x < 0.02 && edge.y == 0)
    let full = Gamepad.applyDeadzone(Vec2(0, -1), deadzone: 0.2)
    #expect(abs(full.y + 1) < 1e-6 && full.x == 0)
    // Halfway between the deadzone and the rim reads 0.5; a diagonal keeps its angle.
    let half = Gamepad.applyDeadzone(Vec2(0.6, 0), deadzone: 0.2)
    #expect(abs(half.x - 0.5) < 1e-6)
    let diagonal = Gamepad.applyDeadzone(Vec2(0.6, 0.6), deadzone: 0.2)
    #expect(abs(diagonal.x - diagonal.y) < 1e-6)
    // Corners of the raw square (length > 1) clamp to the unit circle.
    let corner = Gamepad.applyDeadzone(Vec2(1, 1), deadzone: 0.2)
    #expect(abs((corner.x * corner.x + corner.y * corner.y).squareRoot() - 1) < 1e-5)
    // Zero deadzone passes through.
    #expect(Gamepad.applyDeadzone(Vec2(0.3, -0.4), deadzone: 0) == Vec2(0.3, -0.4))
}

@Test func axisDeadzoneKeepsSign() {
    #expect(Gamepad.applyDeadzone(Float(0.04), deadzone: 0.05) == 0)
    #expect(Gamepad.applyDeadzone(Float(-0.55), deadzone: 0.1) < 0)
    #expect(abs(Gamepad.applyDeadzone(Float(1), deadzone: 0.1) - 1) < 1e-6)
}

@MainActor @Test func padAppliesConfigurableDeadzones() {
    let pad = Gamepad(id: 0)
    pad.apply(GamepadSnapshot(id: 0, leftStick: Vec2(0.1, 0), rightStick: Vec2(0.1, 0), leftTrigger: 0.04, rightTrigger: 0.5))
    #expect(pad.leftStick == .zero && pad.rightStick == .zero)
    #expect(pad.rawLeftStick == Vec2(0.1, 0))
    #expect(pad.leftTrigger == 0 && pad.rightTrigger > 0.4)
    pad.leftStickDeadzone = 0.05
    #expect(pad.leftStick.x > 0.04)
    #expect(pad.rightStick == .zero)
    #expect(pad.value(.leftStickX) == pad.leftStick.x)
    #expect(pad.value(.rightTrigger) == pad.rightTrigger)
}

@MainActor @Test func buttonsHaveKeyLikeEdges() {
    let pad = Gamepad(id: 0)
    pad.apply(GamepadSnapshot(id: 0, buttons: [.south, .dpadUp]))
    #expect(pad.isDown(.south) && pad.wasPressed(.south) && !pad.wasReleased(.south))
    // Next frame, still held: down, no edge.
    pad.beginFrame()
    pad.apply(GamepadSnapshot(id: 0, buttons: [.south]))
    #expect(pad.isDown(.south) && !pad.wasPressed(.south))
    #expect(!pad.isDown(.dpadUp) && pad.wasReleased(.dpadUp))
    pad.beginFrame()
    pad.apply(GamepadSnapshot(id: 0, buttons: []))
    #expect(!pad.isDown(.south) && pad.wasReleased(.south))
    pad.beginFrame()
    #expect(!pad.wasReleased(.south))
}

@MainActor @Test func inputTracksConnectionsAndDisconnections() {
    let input = Input()
    input.beginFrame()
    input.updateGamepads([GamepadSnapshot(id: 3, name: "Pad A", buttons: [.start])])
    #expect(input.gamepads.count == 1 && input.gamepad?.name == "Pad A")
    #expect(input.gamepad?.wasPressed(.start) == true)
    guard case .connected(let pad)? = input.gamepadEvents.first else { Issue.record("no connect event"); return }
    // A second pad joins; the first keeps its identity and edges are per frame.
    input.beginFrame()
    input.updateGamepads([GamepadSnapshot(id: 3, buttons: [.start]), GamepadSnapshot(id: 5, name: "Pad B")])
    #expect(input.gamepads.map(\.id) == [3, 5])
    #expect(input.gamepads[0] === pad && !pad.wasPressed(.start) && pad.isDown(.start))
    // The first is unplugged: it reports nothing afterwards.
    input.beginFrame()
    input.updateGamepads([GamepadSnapshot(id: 5)])
    #expect(input.gamepads.map(\.id) == [5] && input.gamepad?.name == "Pad B")
    #expect(!pad.isConnected && !pad.isDown(.start))
    guard case .disconnected(let gone)? = input.gamepadEvents.first else { Issue.record("no disconnect event"); return }
    #expect(gone === pad)
    input.beginFrame()
    #expect(input.gamepadEvents.isEmpty)
}
