public enum Key: Hashable, Sendable, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    case num0, num1, num2, num3, num4, num5, num6, num7, num8, num9
    case space, enter, escape, tab, backspace, grave
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case left, right, up, down
    case leftShift, rightShift, leftControl, rightControl, leftAlt, rightAlt, leftSuper, rightSuper
}

public enum MouseButton: Hashable, Sendable, CaseIterable {
    case left, right, middle
}

/// Per-frame input state. Platform windows report raw up/down state; this type
/// derives the "pressed this frame" / "released this frame" edges.
@MainActor
public final class Input {
    private var keysDown = Set<Key>()
    private var keysPressed = Set<Key>()
    private var keysReleased = Set<Key>()
    private var buttonsDown = Set<MouseButton>()
    private var buttonsPressed = Set<MouseButton>()
    private var buttonsReleased = Set<MouseButton>()

    /// Cursor position in window points, origin at the top-left.
    public internal(set) var mousePosition: Vec2 = .zero
    /// Cursor movement since the previous frame, in window points.
    public private(set) var mouseDelta: Vec2 = .zero
    private var lastMousePosition: Vec2?

    public func isDown(_ key: Key) -> Bool { keysDown.contains(key) }
    public func wasPressed(_ key: Key) -> Bool { keysPressed.contains(key) }
    public func wasReleased(_ key: Key) -> Bool { keysReleased.contains(key) }

    public func isDown(_ button: MouseButton) -> Bool { buttonsDown.contains(button) }
    public func wasPressed(_ button: MouseButton) -> Bool { buttonsPressed.contains(button) }
    public func wasReleased(_ button: MouseButton) -> Bool { buttonsReleased.contains(button) }

    /// -1, 0 or 1 depending on which of the two keys are held.
    public func axis(negative: Key, positive: Key) -> Float {
        (isDown(positive) ? 1 : 0) - (isDown(negative) ? 1 : 0)
    }

    func beginFrame() {
        keysPressed.removeAll(keepingCapacity: true)
        keysReleased.removeAll(keepingCapacity: true)
        buttonsPressed.removeAll(keepingCapacity: true)
        buttonsReleased.removeAll(keepingCapacity: true)
    }

    func endEvents() {
        mouseDelta = lastMousePosition.map { mousePosition - $0 } ?? .zero
        lastMousePosition = mousePosition
    }

    func setKey(_ key: Key, down: Bool) {
        if down {
            if keysDown.insert(key).inserted { keysPressed.insert(key) }
        } else if keysDown.remove(key) != nil {
            keysReleased.insert(key)
        }
    }

    func setButton(_ button: MouseButton, down: Bool) {
        if down {
            if buttonsDown.insert(button).inserted { buttonsPressed.insert(button) }
        } else if buttonsDown.remove(button) != nil {
            buttonsReleased.insert(button)
        }
    }

    func releaseAll() {
        for key in keysDown { setKey(key, down: false) }
        for button in buttonsDown { setButton(button, down: false) }
    }
}
