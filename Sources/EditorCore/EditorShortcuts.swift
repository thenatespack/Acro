import Engine

/// What a keyboard shortcut asks the editor to do.
public enum EditorAction: Equatable, Sendable {
    case undo, redo, save, duplicate, delete, focusSelection, clearSelection, togglePlay
}

/// Maps key presses to editor actions:
///
/// | Keys | Action |
/// |---|---|
/// | Cmd/Ctrl+Z | undo |
/// | Shift+Cmd/Ctrl+Z, and Ctrl+Y off macOS | redo |
/// | Cmd/Ctrl+S | save |
/// | Cmd/Ctrl+D | duplicate selection |
/// | Cmd/Ctrl+P | play / stop |
/// | Delete or Backspace (also with Cmd/Ctrl) | delete selection |
/// | F | frame the selection in the viewport |
/// | Esc | clear the selection |
///
/// (Cmd on macOS, Ctrl elsewhere: `KeyModifiers.shortcut`.) Undo and redo follow key repeat;
/// the others ignore repeats. Routing respects the UI: see `actions(for:focus:)`.
public struct EditorShortcuts: Sendable {
    /// The editing modifier: `.command` on macOS, `.control` elsewhere.
    public var shortcutModifier: KeyModifiers

    public init(shortcutModifier: KeyModifiers = .shortcut) {
        self.shortcutModifier = shortcutModifier
    }

    private var isMac: Bool { shortcutModifier == .command }

    /// The action for one key press, ignoring focus.
    public func action(for event: KeyEvent) -> EditorAction? {
        let mods = event.modifiers
        let shortcut = mods.contains(shortcutModifier)
        let shift = mods.contains(.shift)
        let plain = mods.isEmpty
        let action: EditorAction?
        switch event.key {
        case .z where shortcut: action = shift ? .redo : .undo
        case .y where !isMac && mods == .control: action = .redo
        case .s where shortcut && !shift: action = .save
        case .d where shortcut && !shift: action = .duplicate
        case .p where shortcut && !shift: action = .togglePlay
        case .delete, .backspace: action = plain || mods == shortcutModifier ? .delete : nil
        case .f where plain: action = .focusSelection
        case .escape where plain: action = .clearSelection
        default: action = nil
        }
        guard let action else { return nil }
        if event.isRepeat && action != .undo && action != .redo { return nil }
        return action
    }

    /// What the UI is doing with the keyboard, sampled around `UIContext.update`.
    public struct Focus: Sendable, Equatable {
        /// A text editor has focus (a `TextField`, a number being typed, a tree row being
        /// renamed) or text input is active, before or after the UI handled this frame's keys.
        public var textEditing: Bool
        /// A popup (menu, color picker) is open: keys belong to it.
        public var overlayOpen: Bool
        /// Some widget had keyboard focus when the keys arrived (Esc then only unfocuses it).
        public var widgetFocused: Bool

        public init(textEditing: Bool = false, overlayOpen: Bool = false, widgetFocused: Bool = false) {
            self.textEditing = textEditing
            self.overlayOpen = overlayOpen
            self.widgetFocused = widgetFocused
        }
    }

    /// This frame's actions. Nothing while text is being edited or a popup is open (so
    /// Backspace edits text, Cmd+Z undoes typing in the field, Esc closes the popup). Esc
    /// clears the selection only when no widget had focus: otherwise it just unfocuses.
    /// Other shortcuts work while a non-text widget (a tree, a button) has focus.
    public func actions(for events: [KeyEvent], focus: Focus) -> [EditorAction] {
        guard !focus.textEditing, !focus.overlayOpen else { return [] }
        return events.compactMap { event in
            guard let action = action(for: event) else { return nil }
            if action == .clearSelection && focus.widgetFocused { return nil }
            return action
        }
    }
}

/// The window cursor for a `UICursor` the widgets ask for (`UIContext.desiredCursor` →
/// `Input.cursor`). The window has no diagonal-resize or move shapes yet, so window corners
/// use the crosshair and moving a floating panel the pointing hand.
public func cursorShape(for cursor: UICursor) -> CursorShape {
    switch cursor {
    case .arrow: .arrow
    case .pointingHand: .pointingHand
    case .resizeLeftRight: .resizeHorizontal
    case .resizeUpDown: .resizeVertical
    case .resizeDiagonal, .resizeAntiDiagonal: .crosshair
    case .move: .pointingHand
    }
}
