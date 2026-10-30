public enum Key: Hashable, Sendable, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    case num0, num1, num2, num3, num4, num5, num6, num7, num8, num9
    case space, enter, escape, tab, backspace, grave
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case delete, home, end, pageUp, pageDown
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

    // MARK: Text input

    /// Whether a text field has focus (between `startTextInput` and `stopTextInput`).
    public private(set) var isTextInputActive = false
    /// The caret rectangle last passed to `startTextInput`.
    public private(set) var textInputRect = TextInputRect.zero
    /// The IME composition in progress, if any. Persists across frames until committed or cancelled.
    public private(set) var composition: Composition?
    /// This frame's text input, in the order it happened. Empty unless text input is active.
    public private(set) var textEvents: [TextInputEvent] = []

    /// This frame's committed text (all `.text` events joined).
    public var committedText: String {
        textEvents.reduce(into: "") { if case .text(let t) = $1 { $0 += t } }
    }
    /// This frame's editing and shortcut key events (including auto-repeats).
    public var keyEvents: [KeyEvent] {
        textEvents.compactMap { if case .key(let e) = $0 { e } else { nil } }
    }

    /// Modifier keys currently held.
    public var modifiers: KeyModifiers {
        var m: KeyModifiers = []
        if isDown(.leftShift) || isDown(.rightShift) { m.insert(.shift) }
        if isDown(.leftControl) || isDown(.rightControl) { m.insert(.control) }
        if isDown(.leftAlt) || isDown(.rightAlt) { m.insert(.alt) }
        if isDown(.leftSuper) || isDown(.rightSuper) { m.insert(.command) }
        return m
    }

    /// Routes typing to text input: committed text, IME composition and editing keys start
    /// arriving in `textEvents` / `composition`, and `rect` (the caret, in window points) tells
    /// the OS where to put the IME candidate window. Call again to move the caret.
    ///
    /// While active, character, editing and navigation keys no longer show up in
    /// `isDown` / `wasPressed` (so typing "w" doesn't also move the camera). Modifier keys and
    /// the mouse are unaffected, and keys already held when it starts keep reporting until released.
    public func startTextInput(rect: TextInputRect = .zero) {
        isTextInputActive = true
        textInputRect = rect
    }

    /// Ends text input: pending events and any composition are discarded and keys go back to `isDown` / `wasPressed`.
    public func stopTextInput() {
        isTextInputActive = false
        composition = nil
        textEvents.removeAll()
    }

    func commitText(_ text: String) {
        guard isTextInputActive else { return }
        composition = nil
        let text = TextOffsets.sanitized(text)
        if text.isEmpty { return }
        if case .text(let previous)? = textEvents.last {
            textEvents[textEvents.count - 1] = .text(previous + text)
        } else {
            textEvents.append(.text(text))
        }
    }

    /// Updates the composition. `selection` is a UTF-16 range inside `text`; empty text cancels it.
    func setComposition(_ text: String, selectedUTF16 selection: Range<Int>) {
        guard isTextInputActive else { return }
        let text = TextOffsets.sanitized(text)
        composition = text.isEmpty ? nil
            : Composition(text: text, selection: TextOffsets.characterRange(ofUTF16: selection, in: text))
    }

    /// Commits the marked text as it is (the IME confirmed it without replacing it).
    func commitComposition() {
        if let text = composition?.text { commitText(text) }
    }

    /// Queues a key for the active text input; platforms call this for every key down / repeat.
    func textKeyEvent(_ key: Key, modifiers: KeyModifiers, isRepeat: Bool) {
        guard isTextInputActive, KeyEvent.isRoutedAsKey(key, modifiers: modifiers) else { return }
        textEvents.append(.key(KeyEvent(key: key, modifiers: modifiers, isRepeat: isRepeat)))
    }

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
        textEvents.removeAll(keepingCapacity: true)
        buttonsPressed.removeAll(keepingCapacity: true)
        buttonsReleased.removeAll(keepingCapacity: true)
    }

    func endEvents() {
        mouseDelta = lastMousePosition.map { mousePosition - $0 } ?? .zero
        lastMousePosition = mousePosition
    }

    func setKey(_ key: Key, down: Bool) {
        if down {
            if isTextInputActive && !key.isModifier { return }  // owned by text input (see startTextInput)
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
