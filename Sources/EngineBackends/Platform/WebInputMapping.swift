import EngineCore

/// How browser input maps onto the engine's: `KeyboardEvent.code` to `Key`, wheel deltas to
/// points, the Gamepad API's standard layout to `GamepadSnapshot`, cursor shapes to CSS.
/// Plain Swift (no JavaScriptKit), so it builds and is unit-tested on every platform;
/// `CanvasWindow` and `WebGamepadSource` use it in WebAssembly builds.
package enum WebInputMapping {
    /// The engine key for a `KeyboardEvent.code` (the physical key, independent of layout,
    /// like GLFW's and AppKit's key codes). nil for keys the engine has no case for.
    package static func key(forCode code: String) -> Key? { keysByCode[code] }

    package static let keysByCode: [String: Key] = {
        var map: [String: Key] = [:]
        for key in Key.allCases {
            if let code = code(for: key) { map[code] = key }
        }
        // Aliases: the keypad's Enter, and the names older Firefox used for the Super keys.
        map["NumpadEnter"] = .enter
        map["OSLeft"] = .leftSuper
        map["OSRight"] = .rightSuper
        return map
    }()

    /// The `KeyboardEvent.code` of `key` (the main one where several map to it).
    package static func code(for key: Key) -> String? {
        switch key {
        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z:
            return "Key" + key.rawValue.uppercased()
        case .num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9:
            return "Digit" + String(key.rawValue.dropFirst(3))
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12:
            return key.rawValue.uppercased()
        case .space: return "Space"
        case .enter: return "Enter"
        case .escape: return "Escape"
        case .tab: return "Tab"
        case .backspace: return "Backspace"
        case .grave: return "Backquote"
        case .leftBracket: return "BracketLeft"
        case .rightBracket: return "BracketRight"
        case .comma: return "Comma"
        case .delete: return "Delete"
        case .home: return "Home"
        case .end: return "End"
        case .pageUp: return "PageUp"
        case .pageDown: return "PageDown"
        case .left: return "ArrowLeft"
        case .right: return "ArrowRight"
        case .up: return "ArrowUp"
        case .down: return "ArrowDown"
        case .leftShift: return "ShiftLeft"
        case .rightShift: return "ShiftRight"
        case .leftControl: return "ControlLeft"
        case .rightControl: return "ControlRight"
        case .leftAlt: return "AltLeft"
        case .rightAlt: return "AltRight"
        case .leftSuper: return "MetaLeft"
        case .rightSuper: return "MetaRight"
        }
    }

    package static func modifiers(shift: Bool, control: Bool, alt: Bool, meta: Bool) -> KeyModifiers {
        var modifiers: KeyModifiers = []
        if shift { modifiers.insert(.shift) }
        if control { modifiers.insert(.control) }
        if alt { modifiers.insert(.alt) }
        if meta { modifiers.insert(.command) }
        return modifiers
    }

    /// Whether the browser's default action for a key press is cancelled: keys that would
    /// scroll the page or move focus (arrows, space, Tab, Page Up / Down, Home / End, Backspace),
    /// and every other key the engine knows, so games get them. Never with Control or Command
    /// held (copy, reload, the browser's shortcuts keep working) and never function keys
    /// (F5 reload, F11 full screen, F12 developer tools).
    package static func preventsDefault(_ key: Key, modifiers: KeyModifiers) -> Bool {
        if modifiers.contains(.control) || modifiers.contains(.command) { return false }
        switch key {
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12: return false
        default: return true
        }
    }

    /// The text a key press types (`KeyboardEvent.key`), or nil: named keys ("Enter", "Dead",
    /// "Shift") are longer than one character, and with Control or Command held a press is a
    /// shortcut, not text. Alt (Option) still types, as it does on macOS.
    package static func typedText(key: String, modifiers: KeyModifiers) -> String? {
        if modifiers.contains(.control) && !modifiers.contains(.alt) { return nil }
        if modifiers.contains(.command) { return nil }
        guard key.count == 1 else { return nil }
        return key
    }

    /// `WheelEvent.deltaMode`.
    package enum WheelDeltaMode: Int {
        case pixel = 0, line = 1, page = 2
    }

    /// Points per wheel line, as AppKitWindow uses for classic wheels.
    package static let pointsPerLine: Float = 16

    /// A wheel event's delta in the engine's scroll convention: points, positive y scrolls up
    /// and positive x scrolls left (the DOM's deltas are the other way around). Pixel deltas
    /// are CSS pixels, which are window points; lines are `pointsPerLine`, pages `pageHeight`.
    package static func scroll(deltaX: Double, deltaY: Double, mode: Int, pageHeight: Float) -> Vec2 {
        let scale: Float = switch WheelDeltaMode(rawValue: mode) ?? .pixel {
        case .pixel: 1
        case .line: pointsPerLine
        case .page: max(pageHeight, 1)
        }
        return Vec2(-Float(deltaX), -Float(deltaY)) * scale
    }

    /// `MouseEvent.button` to the engine's buttons (3 and 4, back and forward, are ignored).
    package static func mouseButton(_ button: Int) -> MouseButton? {
        switch button {
        case 0: .left
        case 1: .middle
        case 2: .right
        default: nil
        }
    }

    /// The CSS `cursor` value for a shape.
    package static func cssCursor(_ shape: CursorShape) -> String {
        switch shape {
        case .arrow: "default"
        case .iBeam: "text"
        case .pointingHand: "pointer"
        case .resizeHorizontal: "ew-resize"
        case .resizeVertical: "ns-resize"
        case .crosshair: "crosshair"
        case .notAllowed: "not-allowed"
        case .hidden: "none"
        }
    }

    /// The Gamepad API's standard layout (https://w3c.github.io/gamepad/#remapping), by button index.
    package static let standardButtons: [GamepadButton?] = [
        .south, .east, .west, .north, .leftShoulder, .rightShoulder,
        nil, nil,  // 6 and 7 are the triggers, read as axes
        .back, .start, .leftStickClick, .rightStickClick,
        .dpadUp, .dpadDown, .dpadLeft, .dpadRight, .guide,
    ]

    /// A standard-layout pad's state as a snapshot: `pressed` and `values` per button index,
    /// `axes` as the API reports them (left x, left y, right x, right y; y down, so they are
    /// flipped to the engine's y up). The triggers are buttons 6 and 7's values.
    package static func gamepadSnapshot(id: Int, name: String, pressed: [Bool], values: [Double], axes: [Double]) -> GamepadSnapshot {
        var buttons = Set<GamepadButton>()
        for (index, button) in standardButtons.enumerated() where index < pressed.count && pressed[index] {
            if let button { buttons.insert(button) }
        }
        func axis(_ i: Int) -> Float { i < axes.count ? Float(axes[i]) : 0 }
        func value(_ i: Int) -> Float { i < values.count ? min(max(Float(values[i]), 0), 1) : 0 }
        return GamepadSnapshot(
            id: id, name: name, buttons: buttons,
            leftStick: Vec2(axis(0), -axis(1)), rightStick: Vec2(axis(2), -axis(3)),
            leftTrigger: value(6), rightTrigger: value(7))
    }
}
