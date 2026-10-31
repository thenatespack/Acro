import Foundation
import Testing
@testable import Engine

/// Feeds synthetic input one frame at a time and runs the action map after each.
@MainActor private final class Rig {
    let input = Input()
    let actions: InputActions

    init(_ bindings: InputBindings) { actions = InputActions(bindings: bindings) }

    func frame(down keys: [Key] = [], mouse: [MouseButton] = [], pad: GamepadSnapshot? = nil) {
        input.beginFrame()
        for key in Key.allCases { input.setKey(key, down: keys.contains(key)) }
        for button in MouseButton.allCases { input.setButton(button, down: mouse.contains(button)) }
        input.updateGamepads(pad.map { [$0] } ?? [])
        actions.update(input)
    }
}

private func sampleBindings() -> InputBindings {
    var map = InputBindings()
    map.buttons.append(.init("jump", [.key(.space), .gamepadButton(.south)]))
    map.buttons.append(.init("fire", [.mouseButton(.left), .gamepadAxis(.rightTrigger, .positive)]))
    map.axes.append(.init("turn", [.composite(negative: .key(.q), positive: .key(.e)), .source(input: .gamepadAxis(.rightStickX, .full))]))
    map.vectors.append(.init("move", [.composite(up: .key(.w), down: .key(.s), left: .key(.a), right: .key(.d)), .stick(stick: .left)]))
    return map
}

@MainActor @Test func buttonActionsFollowAnyBindingWithEdges() {
    let rig = Rig(sampleBindings())
    rig.frame()
    #expect(!rig.actions.isPressed("jump"))
    rig.frame(down: [.space])
    #expect(rig.actions.isPressed("jump") && rig.actions.wasPressed("jump") && !rig.actions.wasReleased("jump"))
    rig.frame(down: [.space])
    #expect(rig.actions.isPressed("jump") && !rig.actions.wasPressed("jump"))
    // Handing over to the second binding doesn't release and re-press it.
    rig.frame(down: [.space], pad: GamepadSnapshot(id: 0, buttons: [.south]))
    #expect(rig.actions.isPressed("jump") && !rig.actions.wasPressed("jump"))
    rig.frame(pad: GamepadSnapshot(id: 0, buttons: [.south]))
    #expect(rig.actions.isPressed("jump") && !rig.actions.wasReleased("jump"))
    rig.frame()
    #expect(!rig.actions.isPressed("jump") && rig.actions.wasReleased("jump"))
    rig.frame()
    #expect(!rig.actions.wasReleased("jump"))
    #expect(!rig.actions.isPressed("nonexistent") && rig.actions.value("nonexistent") == 0)
}

@MainActor @Test func analogSourcesPressButtonsPastTheThreshold() {
    let rig = Rig(sampleBindings())
    rig.frame(pad: GamepadSnapshot(id: 0, rightTrigger: 0.3))
    #expect(!rig.actions.isPressed("fire"))
    #expect(rig.actions.value("fire") > 0.2 && rig.actions.value("fire") < 0.3)  // deadzoned strength
    rig.frame(pad: GamepadSnapshot(id: 0, rightTrigger: 0.9))
    #expect(rig.actions.wasPressed("fire") && rig.actions.value("fire") > 0.8)
    rig.frame(mouse: [.left])
    #expect(rig.actions.wasReleased("fire") == false && rig.actions.isPressed("fire"))
}

@MainActor @Test func compositeVectorsAreNormalized() {
    let rig = Rig(sampleBindings())
    rig.frame(down: [.d])
    #expect(rig.actions.vector("move") == Vec2(1, 0))
    rig.frame(down: [.w, .d])
    let diagonal = rig.actions.vector("move")
    #expect(abs(diagonal.x - 0.70710678) < 1e-5 && abs(diagonal.y - 0.70710678) < 1e-5)
    // Opposites cancel.
    rig.frame(down: [.a, .d, .s])
    #expect(rig.actions.vector("move") == Vec2(0, -1))
    rig.frame(down: [.a, .d])
    #expect(rig.actions.vector("move") == .zero)
}

@MainActor @Test func vectorTakesTheStrongestBindingAndAxesTakeTheStrongest() {
    let rig = Rig(sampleBindings())
    // The stick (deadzoned, y up) alone.
    rig.frame(pad: GamepadSnapshot(id: 0, leftStick: Vec2(0, 0.6)))
    let v = rig.actions.vector("move")
    #expect(v.x == 0 && abs(v.y - 0.45 / 0.85) < 1e-5)
    // Keys beat a weak stick.
    rig.frame(down: [.a], pad: GamepadSnapshot(id: 0, leftStick: Vec2(0, 0.6)))
    #expect(rig.actions.vector("move") == Vec2(-1, 0))
    // 1D axis: composite keys and a stick, strongest wins, clamped to -1...1.
    rig.frame(down: [.q])
    #expect(rig.actions.value("turn") == -1)
    rig.frame(down: [.q, .e])
    #expect(rig.actions.value("turn") == 0)
    rig.frame(pad: GamepadSnapshot(id: 0, rightStick: Vec2(1, 0)))
    #expect(rig.actions.value("turn") == 1)
}

@MainActor @Test func listeningCapturesTheNextPressAndIgnoresTheCurrentOne() {
    let rig = Rig(sampleBindings())
    var reported: (RebindTarget, InputSource)?
    rig.actions.onRebind = { reported = ($0, $1) }
    rig.frame(down: [.r])  // the key that starts listening
    #expect(rig.actions.listen(for: .button("jump", slot: 0)))
    rig.frame(down: [.r])  // the frame after: ignored
    #expect(rig.actions.listeningTarget != nil)
    rig.frame()
    rig.frame(down: [.k])
    #expect(rig.actions.listeningTarget == nil)
    #expect(rig.actions.bindings.buttons[0].bindings == [.key(.k), .gamepadButton(.south)])
    #expect(reported?.0 == .button("jump", slot: 0) && reported?.1 == .key(.k))
    // The new binding works, the old one doesn't.
    rig.frame(down: [.k])
    #expect(rig.actions.isPressed("jump"))
    rig.frame(down: [.space])
    #expect(!rig.actions.isPressed("jump"))
}

@MainActor @Test func listeningTakesMouseGamepadButtonsAndAxesPastTheThreshold() {
    let rig = Rig(sampleBindings())
    rig.frame()
    rig.actions.listen(for: .button("jump", slot: 2))  // appends
    rig.frame()
    rig.frame(mouse: [.right])
    #expect(rig.actions.bindings.buttons[0].bindings.count == 3)
    #expect(rig.actions.bindings.buttons[0].bindings.last == .mouseButton(.right))

    rig.actions.listen(for: .button("jump", slot: 1))
    rig.frame()
    rig.frame(pad: GamepadSnapshot(id: 0))
    rig.frame(pad: GamepadSnapshot(id: 0, buttons: [.north]))
    #expect(rig.actions.bindings.buttons[0].bindings[1] == .gamepadButton(.north))

    // An axis below the threshold is ignored; past it, the direction is captured.
    rig.actions.listen(for: .button("fire", slot: 0))
    rig.frame()
    rig.frame(pad: GamepadSnapshot(id: 0, leftStick: Vec2(0.4, 0)))
    #expect(rig.actions.listeningTarget != nil)
    rig.frame(pad: GamepadSnapshot(id: 0, leftStick: Vec2(-1, 0)))
    #expect(rig.actions.bindings.buttons[1].bindings[0] == .gamepadAxis(.leftStickX, .negative))
}

@MainActor @Test func axisHeldWhenListeningStartsIsNotCaptured() {
    let rig = Rig(sampleBindings())
    let held = GamepadSnapshot(id: 0, leftStick: Vec2(1, 0))
    rig.frame(pad: held)
    rig.actions.listen(for: .button("jump", slot: 0))
    rig.frame(pad: held)
    rig.frame(pad: held)
    #expect(rig.actions.listeningTarget != nil)
    rig.frame(pad: GamepadSnapshot(id: 0))
    rig.frame(pad: GamepadSnapshot(id: 0, leftStick: Vec2(0, 1)))
    #expect(rig.actions.bindings.buttons[0].bindings[0] == .gamepadAxis(.leftStickY, .positive))
}

@MainActor @Test func escapeCancelsListening() {
    let rig = Rig(sampleBindings())
    let before = rig.actions.bindings
    rig.actions.listen(for: .button("jump", slot: 0))
    rig.frame()
    rig.frame(down: [.escape])
    #expect(rig.actions.listeningTarget == nil && rig.actions.bindings == before)
    // Disabling the cancel key lets Esc be bound.
    rig.actions.cancelKey = nil
    rig.actions.listen(for: .button("jump", slot: 0))
    rig.frame()
    rig.frame(down: [.escape])
    #expect(rig.actions.bindings.buttons[0].bindings[0] == .key(.escape))
}

@MainActor @Test func rebindingCompositePartsAndSticks() {
    let rig = Rig(sampleBindings())
    #expect(rig.actions.rebind(.vector("move", slot: 0, part: .up), to: .key(.i)))
    #expect(rig.actions.source(at: .vector("move", slot: 0, part: .up)) == .key(.i))
    rig.frame(down: [.i])
    #expect(rig.actions.vector("move") == Vec2(0, 1))
    #expect(rig.actions.rebind(.axis("turn", slot: 0, part: .positive), to: .key(.p)))
    rig.frame(down: [.p])
    #expect(rig.actions.value("turn") == 1)
    // A whole-stick target takes a stick axis (either axis of it), nothing else.
    #expect(!rig.actions.rebind(.vector("move", slot: 1, part: .whole), to: .key(.x)))
    #expect(!rig.actions.rebind(.vector("move", slot: 1, part: .whole), to: .gamepadAxis(.leftTrigger, .positive)))
    #expect(rig.actions.rebind(.vector("move", slot: 1, part: .whole), to: .gamepadAxis(.rightStickY, .negative)))
    #expect(rig.actions.bindings.vectors[0].bindings[1] == .stick(stick: .right))
    // A whole 1D axis takes gamepad axes as the full signed value.
    #expect(rig.actions.rebind(.axis("turn", slot: 1, part: .whole), to: .gamepadAxis(.leftStickX, .negative)))
    #expect(rig.actions.bindings.axes[0].bindings[1] == .source(input: .gamepadAxis(.leftStickX, .full)))
    // Bad targets.
    #expect(!rig.actions.listen(for: .button("nope", slot: 0)))
    #expect(!rig.actions.listen(for: .button("jump", slot: 5)))
    #expect(!rig.actions.rebind(.axis("turn", slot: 0, part: .up), to: .key(.p)))
}

@MainActor @Test func bindingsRoundTripThroughJSON() throws {
    var map = sampleBindings()
    map.buttons.append(.init("pad", GamepadButton.allCases.map { .gamepadButton($0) }
        + Key.allCases.prefix(5).map { .key($0) } + [.gamepadAxis(.leftTrigger, .positive), .gamepadAxis(.leftStickY, .negative)]))
    let data = try map.json()
    let decoded = try InputBindings(json: data)
    #expect(decoded == map)
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"key.space\"") && text.contains("\"axis.leftTrigger+\"") && text.contains("\"pad.south\""))
    #expect(try map.json() == data)  // stable output
    // A loaded map behaves like the original.
    let rig = Rig(decoded)
    rig.frame(down: [.w, .d])
    #expect(rig.actions.vector("move").y > 0.7)
    // Unknown sources are rejected rather than ignored.
    let bad = text.replacingOccurrences(of: "key.space", with: "key.nope")
    #expect(throws: DecodingError.self) { try InputBindings(json: Data(bad.utf8)) }
}

@Test func everySourceRoundTripsAndHasAName() {
    var sources: [InputSource] = Key.allCases.map { .key($0) } + MouseButton.allCases.map { .mouseButton($0) }
        + GamepadButton.allCases.map { .gamepadButton($0) }
    for axis in GamepadAxis.allCases {
        for side in [AxisSide.full, .positive, .negative] { sources.append(.gamepadAxis(axis, side)) }
    }
    for source in sources {
        #expect(InputSource.parse(source.encoded) == source)
        #expect(!source.displayName.isEmpty)
    }
    #expect(InputSource.key(.w).displayName == "W" && InputSource.key(.leftShift).displayName == "Left Shift")
    #expect(InputSource.key(.num3).displayName == "3" && InputSource.gamepadButton(.south).displayName == "Pad South")
}
