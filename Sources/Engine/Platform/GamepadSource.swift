#if canImport(GameController)
import GameController
#endif

/// Reads the connected gamepads from the OS, once per frame (`Input.updateGamepads`).
@MainActor
protocol GamepadSource: AnyObject {
    func snapshots() -> [GamepadSnapshot]
}

/// The gamepad source for this platform: GameController on Apple platforms (for both the AppKit
/// and the GLFW window), GLFW's joystick / gamepad API elsewhere. nil when there is none.
@MainActor
func makePlatformGamepadSource() -> GamepadSource? {
    #if canImport(GameController)
    return GameControllerSource()
    #elseif ENGINE_VULKAN
    return GLFWGamepadSource()
    #else
    return nil
    #endif
}

#if canImport(GameController)
/// GCController's extended gamepad profile, which maps Xbox, PlayStation, Switch and MFi pads
/// onto the standard layout. Controllers are polled from `GCController.controllers()` each frame,
/// so connections need no notification plumbing. Background events stay off: a pad only
/// reports while the app is active.
@MainActor
final class GameControllerSource: GamepadSource {
    private var ids: [ObjectIdentifier: Int] = [:]
    private var nextID = 0

    func snapshots() -> [GamepadSnapshot] {
        var result: [GamepadSnapshot] = []
        var live = Set<ObjectIdentifier>()
        for controller in GCController.controllers() {
            guard let pad = controller.extendedGamepad else { continue }
            let key = ObjectIdentifier(controller)
            live.insert(key)
            if ids[key] == nil {
                ids[key] = nextID
                nextID += 1
            }
            var buttons = Set<GamepadButton>()
            func add(_ button: GamepadButton, _ input: GCControllerButtonInput?) {
                if input?.isPressed == true { buttons.insert(button) }
            }
            add(.south, pad.buttonA)
            add(.east, pad.buttonB)
            add(.west, pad.buttonX)
            add(.north, pad.buttonY)
            add(.leftShoulder, pad.leftShoulder)
            add(.rightShoulder, pad.rightShoulder)
            add(.leftStickClick, pad.leftThumbstickButton)
            add(.rightStickClick, pad.rightThumbstickButton)
            add(.dpadUp, pad.dpad.up)
            add(.dpadDown, pad.dpad.down)
            add(.dpadLeft, pad.dpad.left)
            add(.dpadRight, pad.dpad.right)
            add(.start, pad.buttonMenu)
            add(.back, pad.buttonOptions)
            add(.guide, pad.buttonHome)
            result.append(GamepadSnapshot(
                id: ids[key]!, name: controller.vendorName ?? "Gamepad", buttons: buttons,
                leftStick: Vec2(pad.leftThumbstick.xAxis.value, pad.leftThumbstick.yAxis.value),
                rightStick: Vec2(pad.rightThumbstick.xAxis.value, pad.rightThumbstick.yAxis.value),
                leftTrigger: pad.leftTrigger.value, rightTrigger: pad.rightTrigger.value))
        }
        ids = ids.filter { live.contains($0.key) }
        return result
    }
}
#endif

#if ENGINE_VULKAN
import CGLFW

/// GLFW's gamepad API: joysticks with a mapping in GLFW's database (SDL_GameControllerDB format;
/// the common Xbox / PlayStation / Switch pads are built in) read in the standard layout.
/// Joystick numbers are the ids, so a pad keeps its id while connected.
@MainActor
final class GLFWGamepadSource: GamepadSource {
    private static let buttonMap: [(GamepadButton, Int32)] = [
        (.south, GLFW_GAMEPAD_BUTTON_A), (.east, GLFW_GAMEPAD_BUTTON_B), (.west, GLFW_GAMEPAD_BUTTON_X),
        (.north, GLFW_GAMEPAD_BUTTON_Y), (.leftShoulder, GLFW_GAMEPAD_BUTTON_LEFT_BUMPER),
        (.rightShoulder, GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER), (.back, GLFW_GAMEPAD_BUTTON_BACK),
        (.start, GLFW_GAMEPAD_BUTTON_START), (.guide, GLFW_GAMEPAD_BUTTON_GUIDE),
        (.leftStickClick, GLFW_GAMEPAD_BUTTON_LEFT_THUMB), (.rightStickClick, GLFW_GAMEPAD_BUTTON_RIGHT_THUMB),
        (.dpadUp, GLFW_GAMEPAD_BUTTON_DPAD_UP), (.dpadRight, GLFW_GAMEPAD_BUTTON_DPAD_RIGHT),
        (.dpadDown, GLFW_GAMEPAD_BUTTON_DPAD_DOWN), (.dpadLeft, GLFW_GAMEPAD_BUTTON_DPAD_LEFT),
    ]

    func snapshots() -> [GamepadSnapshot] {
        var result: [GamepadSnapshot] = []
        for jid in GLFW_JOYSTICK_1...GLFW_JOYSTICK_LAST {
            guard glfwJoystickIsGamepad(jid) == GLFW_TRUE else { continue }
            var state = GLFWgamepadstate()
            guard glfwGetGamepadState(jid, &state) == GLFW_TRUE else { continue }
            var buttons = Set<GamepadButton>()
            withUnsafeBytes(of: &state.buttons) { raw in
                for (button, index) in Self.buttonMap where raw[Int(index)] == UInt8(GLFW_PRESS) { buttons.insert(button) }
            }
            let axes = withUnsafeBytes(of: &state.axes) { Array($0.bindMemory(to: Float.self).prefix(6)) }
            // GLFW sticks have y down and triggers run -1 (released) to 1.
            result.append(GamepadSnapshot(
                id: Int(jid), name: glfwGetGamepadName(jid).map { String(cString: $0) } ?? "Gamepad", buttons: buttons,
                leftStick: Vec2(axes[Int(GLFW_GAMEPAD_AXIS_LEFT_X)], -axes[Int(GLFW_GAMEPAD_AXIS_LEFT_Y)]),
                rightStick: Vec2(axes[Int(GLFW_GAMEPAD_AXIS_RIGHT_X)], -axes[Int(GLFW_GAMEPAD_AXIS_RIGHT_Y)]),
                leftTrigger: (axes[Int(GLFW_GAMEPAD_AXIS_LEFT_TRIGGER)] + 1) / 2,
                rightTrigger: (axes[Int(GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER)] + 1) / 2))
        }
        return result
    }
}
#endif
