public enum Key: Hashable, Sendable, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    case num0, num1, num2, num3, num4, num5, num6, num7, num8, num9
    case space, enter, escape, tab, backspace, grave, leftBracket, rightBracket
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case delete, home, end, pageUp, pageDown
    case left, right, up, down
    case leftShift, rightShift, leftControl, rightControl, leftAlt, rightAlt, leftSuper, rightSuper
}

public enum MouseButton: Hashable, Sendable, CaseIterable {
    case left, right, middle
}

/// The mouse cursor's look over the window (`Input.cursor`).
public enum CursorShape: Hashable, Sendable, CaseIterable {
    case arrow
    /// Text insertion (over text fields).
    case iBeam
    /// Links and clickable items.
    case pointingHand
    /// Dragging a vertical edge or splitter left / right.
    case resizeHorizontal
    /// Dragging a horizontal edge or splitter up / down.
    case resizeVertical
    case crosshair
    case notAllowed
    /// No cursor over the window (it still moves; see `Input.isMouseCaptured` to lock it).
    case hidden
}

/// Relative ("captured") mouse mode, as a state machine: the game asks for it, and it is only
/// active while the window has focus. Losing focus or pressing Esc ends it, and the game has
/// to ask again (so a click back into the window never grabs the mouse by surprise).
public struct MouseCapture: Equatable, Sendable {
    /// The game wants the mouse captured.
    public private(set) var requested = false
    /// The window has keyboard focus.
    public private(set) var focused = true

    public init() {}

    /// Captured right now: the platform hides and locks the cursor and reports raw motion.
    public var isActive: Bool { requested && focused }

    /// Asks for (or ends) capture. Ignored while the window doesn't have focus.
    public mutating func request(_ captured: Bool) {
        requested = captured && focused
    }

    public mutating func setFocused(_ focused: Bool) {
        self.focused = focused
        if !focused { requested = false }
    }

    /// Esc while captured ends the capture. Returns whether it did (the key is then swallowed).
    public mutating func escapePressed() -> Bool {
        guard isActive else { return false }
        requested = false
        return true
    }
}

/// Turns cursor positions and raw motion into a per-frame delta (the CPU side of
/// `Input.mouseDelta`). Uncaptured, the delta is the position change since the last frame;
/// captured, the cursor doesn't move and the delta is the sum of the platform's raw motion,
/// unbounded by the screen edges. The frame capture starts or ends in reports no motion, so
/// a cursor warped by the platform doesn't jump the camera.
public struct MouseMotion: Sendable {
    private var lastPosition: Vec2?
    private var raw = Vec2.zero
    private var wasCaptured = false

    public init() {}

    /// Platforms report motion from every mouse-move event, in points (y down).
    public mutating func addRaw(_ delta: Vec2) {
        raw += delta
    }

    /// The delta for the frame whose events have all been reported.
    public mutating func endFrame(position: Vec2, captured: Bool) -> Vec2 {
        defer {
            raw = .zero
            lastPosition = position
            wasCaptured = captured
        }
        if captured != wasCaptured { return .zero }
        if captured { return raw }
        return lastPosition.map { position - $0 } ?? .zero
    }
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

    /// Cursor position in window points, origin at the top-left. It stays put while the mouse
    /// is captured.
    public internal(set) var mousePosition: Vec2 = .zero
    /// Cursor movement since the previous frame, in window points (y down). While the mouse is
    /// captured this is the raw motion, unbounded by the screen edges (fly cameras).
    public private(set) var mouseDelta: Vec2 = .zero
    private var motion = MouseMotion()
    private(set) var capture = MouseCapture()
    /// Esc released the capture and is down: its press and repeats are not reported.
    private var escapeSwallowed = false

    /// The cursor's shape over the window this frame. Reset to `.arrow` at the start of every
    /// frame, so set it every frame while it should differ (e.g. while hovering a splitter).
    /// Hidden while the mouse is captured, whatever this says.
    public var cursor: CursorShape = .arrow

    /// Relative mouse mode for fly cameras and drags: the cursor is hidden and locked in place,
    /// and `mouseDelta` reports raw, unbounded motion. Setting it is a request: it is ignored
    /// while the window is not focused, and capture ends by itself when the window loses focus
    /// or (with `escapeReleasesCapture`) when Esc is pressed. Read it back to see whether the
    /// mouse is captured now. Ignored during ENGINE_SCREENSHOT runs.
    public var isMouseCaptured: Bool {
        get { capture.isActive }
        set { capture.request(newValue) }
    }
    /// Esc ends a capture, and that press isn't reported to the game (a safety exit).
    public var escapeReleasesCapture = true
    /// Scroll wheel / trackpad movement this frame, in points. Positive y scrolls up (towards
    /// the top of a document, i.e. content moves down), positive x scrolls left. Trackpads report
    /// precise deltas; a mouse wheel notch is about 10–40 points depending on the platform.
    public private(set) var scrollDelta: Vec2 = .zero
    /// This frame's key presses and OS auto-repeats, in order, with the modifiers held. Every
    /// non-modifier key is reported, whether or not text input is active (unlike `wasPressed`),
    /// so UI keyboard navigation (arrows on a focused slider, Tab between widgets) gets repeats.
    public private(set) var keyPresses: [KeyEvent] = []

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
        guard isTextInputActive, KeyEvent.isRoutedAsKey(key, modifiers: modifiers), !swallowsEscape(key) else { return }
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
        cursor = .arrow
        keysPressed.removeAll(keepingCapacity: true)
        keysReleased.removeAll(keepingCapacity: true)
        textEvents.removeAll(keepingCapacity: true)
        keyPresses.removeAll(keepingCapacity: true)
        scrollDelta = .zero
        buttonsPressed.removeAll(keepingCapacity: true)
        buttonsReleased.removeAll(keepingCapacity: true)
    }

    func endEvents() {
        mouseDelta = motion.endFrame(position: mousePosition, captured: capture.isActive)
    }

    /// Platforms report the motion of every mouse-move event, in points (used while captured).
    func addMouseMotion(_ delta: Vec2) {
        motion.addRaw(delta)
    }

    /// Platforms report whether the window has keyboard focus every frame.
    func setWindowFocused(_ focused: Bool) {
        capture.setFocused(focused)
    }

    /// Whether Esc going down should only end the capture (and be swallowed until released).
    private func swallowsEscape(_ key: Key) -> Bool {
        guard key == .escape else { return false }
        if escapeSwallowed { return true }
        guard escapeReleasesCapture, capture.escapePressed() else { return false }
        escapeSwallowed = true
        return true
    }

    func setKey(_ key: Key, down: Bool) {
        if key == .escape && !down { escapeSwallowed = false }
        if down {
            if swallowsEscape(key) { return }
            if isTextInputActive && !key.isModifier { return }  // owned by text input (see startTextInput)
            if keysDown.insert(key).inserted { keysPressed.insert(key) }
        } else if keysDown.remove(key) != nil {
            keysReleased.insert(key)
        }
    }

    func addScroll(_ delta: Vec2) {
        scrollDelta += delta
    }

    /// Platforms call this for every key down and auto-repeat (see `keyPresses`).
    func recordKeyPress(_ key: Key, modifiers: KeyModifiers, isRepeat: Bool) {
        guard !key.isModifier, !swallowsEscape(key) else { return }
        keyPresses.append(KeyEvent(key: key, modifiers: modifiers, isRepeat: isRepeat))
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
