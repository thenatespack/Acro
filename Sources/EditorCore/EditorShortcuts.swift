import Engine

/// What a keyboard shortcut asks the editor to do.
public enum EditorAction: Equatable, Sendable {
    case undo, redo, save, duplicate, delete, focusSelection, clearSelection, togglePlay, importAsset
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
/// | Shift+Cmd/Ctrl+I | import files into the current assets folder |
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
        case .i where shortcut && shift: action = .importAsset
        case .delete, .backspace: action = plain || mods == shortcutModifier ? .delete : nil
        case .f where plain: action = .focusSelection
        case .escape where plain: action = .clearSelection
        default: action = nil
        }
        guard let action else { return nil }
        if event.isRepeat && action != .undo && action != .redo { return nil }
        return action
    }

    /// The key press that performs `action` (its first binding), for showing in tooltips. Every
    /// result maps back to `action` through `action(for:)`.
    public func binding(for action: EditorAction) -> KeyEvent {
        switch action {
        case .undo: KeyEvent(key: .z, modifiers: shortcutModifier)
        case .redo: KeyEvent(key: .z, modifiers: [shortcutModifier, .shift])
        case .save: KeyEvent(key: .s, modifiers: shortcutModifier)
        case .duplicate: KeyEvent(key: .d, modifiers: shortcutModifier)
        case .togglePlay: KeyEvent(key: .p, modifiers: shortcutModifier)
        case .importAsset: KeyEvent(key: .i, modifiers: [shortcutModifier, .shift])
        case .delete: KeyEvent(key: .delete)
        case .focusSelection: KeyEvent(key: .f)
        case .clearSelection: KeyEvent(key: .escape)
        }
    }

    /// How `action`'s key combination reads: "⌘Z", "⇧⌘Z" on macOS, "Ctrl+Z", "Ctrl+Shift+Z" elsewhere.
    public func shortcutText(for action: EditorAction) -> String {
        let event = binding(for: action)
        let key: String
        switch event.key {
        case .delete: key = "Delete"
        case .escape: key = "Esc"
        default: key = String(describing: event.key).uppercased()
        }
        let mods = event.modifiers
        if isMac {
            return (mods.contains(.control) ? "⌃" : "") + (mods.contains(.alt) ? "⌥" : "") + (mods.contains(.shift) ? "⇧" : "")
                + (mods.contains(.command) ? "⌘" : "") + key
        }
        var parts: [String] = []
        if mods.contains(.control) { parts.append("Ctrl") }
        if mods.contains(.alt) { parts.append("Alt") }
        if mods.contains(.shift) { parts.append("Shift") }
        if mods.contains(.command) { parts.append("Win") }
        return (parts + [key]).joined(separator: "+")
    }

    /// `title` followed by the action's shortcut in parentheses: "Undo Rename (⌘Z)".
    public func tooltip(_ title: String, for action: EditorAction) -> String {
        "\(title) (\(shortcutText(for: action)))"
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
