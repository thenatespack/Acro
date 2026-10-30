/// Modifier keys held during a key event.
public struct KeyModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = KeyModifiers(rawValue: 1)
    public static let control = KeyModifiers(rawValue: 2)
    /// Option on macOS.
    public static let alt = KeyModifiers(rawValue: 4)
    /// Command on macOS, the Windows/Super key elsewhere.
    public static let command = KeyModifiers(rawValue: 8)

    /// The modifier of the platform's editing shortcuts (copy, paste, select all...):
    /// Command on macOS, Control elsewhere.
    public static var shortcut: KeyModifiers {
        #if os(macOS)
        .command
        #else
        .control
        #endif
    }
}

extension Key {
    /// A modifier key (shift, control, alt, super).
    public var isModifier: Bool {
        switch self {
        case .leftShift, .rightShift, .leftControl, .rightControl, .leftAlt, .rightAlt, .leftSuper, .rightSuper: true
        default: false
        }
    }

    /// Keys that type a character (letters, digits, space, grave). They reach text input as
    /// committed text; only with control or command held do they become a `KeyEvent` (a shortcut).
    public var producesText: Bool {
        switch self {
        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z,
             .num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9, .space, .grave: true
        default: false
        }
    }
}

/// A key press (or auto-repeat) delivered to an active text input: editing and navigation keys
/// (backspace, delete, arrows, home/end, enter, tab, escape, function keys) and shortcuts
/// (control/command plus a character key, e.g. `.a` with `.shortcut` for select all).
public struct KeyEvent: Equatable, Sendable {
    public var key: Key
    public var modifiers: KeyModifiers
    /// True for OS key repeats while the key is held, false for the initial press.
    public var isRepeat: Bool

    public init(key: Key, modifiers: KeyModifiers = [], isRepeat: Bool = false) {
        self.key = key
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }

    /// Whether the platform should deliver this key to a text input as a `KeyEvent` rather than as text.
    static func isRoutedAsKey(_ key: Key, modifiers: KeyModifiers) -> Bool {
        if key.isModifier { return false }
        if !key.producesText { return true }
        // Control+Alt is AltGr on Windows/Linux layouts and types characters.
        return (modifiers.contains(.control) && !modifiers.contains(.alt)) || modifiers.contains(.command)
    }
}

/// One entry of the ordered stream a text field consumes each frame.
public enum TextInputEvent: Equatable, Sendable {
    /// Text the user committed (typed characters, a finished IME composition, a dead-key result).
    case text(String)
    case key(KeyEvent)
}

/// An in-progress IME composition (marked text). Draw `text` underlined at the caret and the
/// `selection` highlighted. It stays valid across frames until it is committed or cancelled.
public struct Composition: Equatable, Sendable {
    public var text: String
    /// The IME's selection inside `text`, in Characters (an empty range is the IME's caret).
    public var selection: Range<Int>
}

/// Where a text field's caret is, in window points with the origin at the top-left (the same
/// space as `Input.mousePosition`). The OS uses it to place the IME candidate window.
public struct TextInputRect: Equatable, Sendable {
    public var x: Float, y: Float, width: Float, height: Float
    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    public static let zero = TextInputRect(x: 0, y: 0, width: 0, height: 0)
}

/// UTF-16 <-> Character offset conversions. Platform text APIs (NSTextInputClient) count UTF-16
/// code units, while Swift strings and text fields count Characters (grapheme clusters), so a
/// single emoji or an e plus a combining accent spans several units.
enum TextOffsets {
    /// Number of UTF-16 code units in the first `count` Characters of `string`.
    static func utf16Offset(ofCharacter count: Int, in string: String) -> Int {
        var units = 0
        for (i, ch) in string.enumerated() {
            if i >= count { break }
            units += ch.utf16.count
        }
        return units
    }

    /// Character offset for a UTF-16 offset. An offset inside a Character rounds down
    /// (`roundUp: false`) or up to the next boundary; offsets past the end clamp to the count.
    static func characterOffset(ofUTF16 offset: Int, in string: String, roundUp: Bool) -> Int {
        var units = 0
        var index = 0
        for ch in string {
            if units >= offset { return index }
            let next = units + ch.utf16.count
            if offset < next { return roundUp ? index + 1 : index }
            units = next
            index += 1
        }
        return index
    }

    /// The smallest Character range covering a UTF-16 range (partially covered Characters are included).
    static func characterRange(ofUTF16 range: Range<Int>, in string: String) -> Range<Int> {
        let lower = characterOffset(ofUTF16: range.lowerBound, in: string, roundUp: false)
        let upper = range.isEmpty ? lower : characterOffset(ofUTF16: range.upperBound, in: string, roundUp: true)
        return lower..<max(lower, upper)
    }

    static func utf16Range(ofCharacters range: Range<Int>, in string: String) -> Range<Int> {
        utf16Offset(ofCharacter: range.lowerBound, in: string)..<utf16Offset(ofCharacter: range.upperBound, in: string)
    }

    /// The text covered by a UTF-16 range (clamped to the string and widened to Character
    /// boundaries) and the UTF-16 range actually returned.
    static func substring(ofUTF16 range: Range<Int>, in string: String) -> (text: String, actual: Range<Int>) {
        let chars = characterRange(ofUTF16: range, in: string)
        let text = String(string.dropFirst(chars.lowerBound).prefix(chars.count))
        return (text, utf16Range(ofCharacters: chars, in: string))
    }

    /// Drops control characters (return, tab, delete, escape...) and the private-use code points
    /// macOS uses for function keys. Those arrive as key events, not as text.
    static func sanitized(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars
        where scalar.properties.generalCategory != .control && !(0xF700...0xF8FF).contains(scalar.value) {
            scalars.append(scalar)
        }
        return String(scalars)
    }
}
