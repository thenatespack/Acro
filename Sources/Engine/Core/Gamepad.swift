/// The buttons of the standard gamepad layout (an Xbox-style pad; PlayStation and Switch pads
/// map onto it by position, so `south` is Cross / B).
public enum GamepadButton: String, Hashable, Sendable, CaseIterable, Codable {
    /// Face buttons by position: south is A (Xbox) / Cross, east is B / Circle, west is X / Square,
    /// north is Y / Triangle.
    case south, east, west, north
    case leftShoulder, rightShoulder
    case leftStickClick, rightStickClick
    case dpadUp, dpadDown, dpadLeft, dpadRight
    /// Start / Menu / Options, Back / View / Share, and the logo button (not every pad or OS reports it).
    case start, back, guide
}

/// The analog axes of the standard layout. Sticks run -1 (left / down) to 1 (right / up); triggers 0 to 1.
public enum GamepadAxis: String, Hashable, Sendable, CaseIterable, Codable {
    case leftStickX, leftStickY, rightStickX, rightStickY
    case leftTrigger, rightTrigger
}

public enum GamepadStick: String, Hashable, Sendable, CaseIterable, Codable {
    case left, right
}

public enum GamepadEvent {
    case connected(Gamepad)
    case disconnected(Gamepad)
}

/// One pad's raw state as a platform reads it, before deadzones: sticks with y up, triggers 0 to 1.
public struct GamepadSnapshot: Sendable {
    public var id: Int
    public var name: String
    public var buttons: Set<GamepadButton>
    public var leftStick: Vec2
    public var rightStick: Vec2
    public var leftTrigger: Float
    public var rightTrigger: Float

    public init(id: Int, name: String = "Gamepad", buttons: Set<GamepadButton> = [], leftStick: Vec2 = .zero,
                rightStick: Vec2 = .zero, leftTrigger: Float = 0, rightTrigger: Float = 0) {
        self.id = id
        self.name = name
        self.buttons = buttons
        self.leftStick = leftStick
        self.rightStick = rightStick
        self.leftTrigger = leftTrigger
        self.rightTrigger = rightTrigger
    }
}

/// A connected gamepad with the standard layout. Buttons have the same edges as keys
/// (`isDown` / `wasPressed` / `wasReleased`); sticks and triggers are floats with a
/// configurable deadzone. State changes once per frame, when the platform window polls.
///
/// Reached through `Input.gamepads`. The properties here are post-deadzone; the `raw` ones
/// are what the device reported.
@MainActor
public final class Gamepad {
    /// Stable while the pad stays connected (never reused within a run for a different pad).
    public let id: Int
    public let name: String
    /// False once the pad has been unplugged; a held reference then reports nothing pressed.
    public private(set) var isConnected = true

    /// Radial deadzone of each stick, as a fraction of full deflection (0 to below 1).
    public var leftStickDeadzone: Float = 0.15
    public var rightStickDeadzone: Float = 0.15
    public var triggerDeadzone: Float = 0.05

    public private(set) var rawLeftStick = Vec2.zero
    public private(set) var rawRightStick = Vec2.zero
    public private(set) var rawLeftTrigger: Float = 0
    public private(set) var rawRightTrigger: Float = 0

    private var down = Set<GamepadButton>()
    private var pressed = Set<GamepadButton>()
    private var released = Set<GamepadButton>()

    /// A pad for platforms to fill, or for tests and games to drive by hand with `apply(_:)`.
    public init(id: Int, name: String = "Gamepad") {
        self.id = id
        self.name = name
    }

    public func isDown(_ button: GamepadButton) -> Bool { down.contains(button) }
    public func wasPressed(_ button: GamepadButton) -> Bool { pressed.contains(button) }
    public func wasReleased(_ button: GamepadButton) -> Bool { released.contains(button) }

    /// The left stick with its deadzone applied: x right, y up, length at most 1.
    public var leftStick: Vec2 { Self.applyDeadzone(rawLeftStick, deadzone: leftStickDeadzone) }
    public var rightStick: Vec2 { Self.applyDeadzone(rawRightStick, deadzone: rightStickDeadzone) }
    public var leftTrigger: Float { Self.applyDeadzone(rawLeftTrigger, deadzone: triggerDeadzone) }
    public var rightTrigger: Float { Self.applyDeadzone(rawRightTrigger, deadzone: triggerDeadzone) }

    public func stick(_ stick: GamepadStick) -> Vec2 {
        stick == .left ? leftStick : rightStick
    }

    /// An axis value with its deadzone applied.
    public func value(_ axis: GamepadAxis) -> Float {
        switch axis {
        case .leftStickX: leftStick.x
        case .leftStickY: leftStick.y
        case .rightStickX: rightStick.x
        case .rightStickY: rightStick.y
        case .leftTrigger: leftTrigger
        case .rightTrigger: rightTrigger
        }
    }

    /// A radial deadzone: inside `deadzone` the stick reads zero, outside the length is
    /// rescaled so it grows smoothly from 0 at the edge of the deadzone to 1 at full
    /// deflection (direction kept, so diagonals aren't distorted).
    nonisolated public static func applyDeadzone(_ v: Vec2, deadzone: Float) -> Vec2 {
        let length = (v.x * v.x + v.y * v.y).squareRoot()
        let dz = min(max(deadzone, 0), 0.999)
        guard length > dz, length > 0 else { return .zero }
        let scaled = min((length - dz) / (1 - dz), 1)
        return v * (scaled / length)
    }

    /// The same for one axis, keeping its sign.
    nonisolated public static func applyDeadzone(_ x: Float, deadzone: Float) -> Float {
        let dz = min(max(deadzone, 0), 0.999)
        let magnitude = abs(x)
        guard magnitude > dz else { return 0 }
        return (x < 0 ? -1 : 1) * min((magnitude - dz) / (1 - dz), 1)
    }

    /// Takes a new reading of the device, deriving this frame's button edges from the last one.
    public func apply(_ snapshot: GamepadSnapshot) {
        for button in snapshot.buttons.subtracting(down) { pressed.insert(button) }
        for button in down.subtracting(snapshot.buttons) { released.insert(button) }
        down = snapshot.buttons
        rawLeftStick = snapshot.leftStick
        rawRightStick = snapshot.rightStick
        rawLeftTrigger = snapshot.leftTrigger
        rawRightTrigger = snapshot.rightTrigger
    }

    /// Starts a frame: last frame's edges are forgotten.
    public func beginFrame() {
        pressed.removeAll(keepingCapacity: true)
        released.removeAll(keepingCapacity: true)
    }

    func disconnect() {
        isConnected = false
        down.removeAll()
        pressed.removeAll()
        released.removeAll()
        rawLeftStick = .zero
        rawRightStick = .zero
        rawLeftTrigger = 0
        rawRightTrigger = 0
    }
}
