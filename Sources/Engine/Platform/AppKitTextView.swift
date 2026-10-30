#if canImport(AppKit)
import AppKit

/// The window's content view. Besides hosting the Metal layer it is the text input client the
/// system talks to for dead keys, the press-and-hold accent popup and input methods (CJK etc.).
/// It forwards everything to `input`, which is only set while the window pumps events.
///
/// The client has no access to the text field's contents. Its document is just the marked
/// text, which is enough for composition; reconversion of already committed text is not supported.
@MainActor
final class GameView: NSView, @preconcurrency NSTextInputClient {
    weak var input: Input?

    override var acceptsFirstResponder: Bool { true }

    private var active: Input? {
        guard let input, input.isTextInputActive else { return nil }
        return input
    }

    private var markedText: String { input?.composition?.text ?? "" }

    // MARK: NSTextInputClient

    func insertText(_ string: Any, replacementRange: NSRange) {
        active?.commitText(Self.plainString(string))
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        let text = Self.plainString(string)
        let range = Self.utf16Range(selectedRange, length: text.utf16.count) ?? text.utf16.count..<text.utf16.count
        active?.setComposition(text, selectedUTF16: range)
    }

    func unmarkText() {
        active?.commitComposition()
    }

    func hasMarkedText() -> Bool { active?.composition != nil }

    func markedRange() -> NSRange {
        guard hasMarkedText() else { return NSRange(location: NSNotFound, length: 0) }
        return NSRange(location: 0, length: markedText.utf16.count)
    }

    func selectedRange() -> NSRange {
        guard let composition = active?.composition else { return NSRange(location: NSNotFound, length: 0) }
        let r = TextOffsets.utf16Range(ofCharacters: composition.selection, in: composition.text)
        return NSRange(location: r.lowerBound, length: r.count)
    }

    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        guard hasMarkedText(), let proposed = Self.utf16Range(range, length: markedText.utf16.count) else { return nil }
        let (text, actual) = TextOffsets.substring(ofUTF16: proposed, in: markedText)
        actualRange?.pointee = NSRange(location: actual.lowerBound, length: actual.count)
        return NSAttributedString(string: text)
    }

    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }

    /// Screen rectangle of the caret, where the system puts the candidate window.
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        let r = input?.textInputRect ?? .zero
        // The input rect is in window points from the top-left; AppKit views are bottom-left.
        let local = NSRect(x: CGFloat(r.x), y: bounds.height - CGFloat(r.y + r.height),
                           width: CGFloat(r.width), height: CGFloat(r.height))
        guard let window else { return local }
        return window.convertToScreen(convert(local, to: nil))
    }

    func characterIndex(for point: NSPoint) -> Int { NSNotFound }

    /// Selectors for keys the system didn't turn into text (arrows, backspace...). Those are
    /// delivered as `KeyEvent`s directly by the window, so there is nothing to do here.
    override func doCommand(by selector: Selector) {}

    // MARK: Helpers

    static func plainString(_ value: Any) -> String {
        (value as? NSAttributedString)?.string ?? (value as? String) ?? ""
    }

    /// An NSRange as a clamped UTF-16 range; nil for `NSNotFound` locations.
    static func utf16Range(_ range: NSRange, length: Int) -> Range<Int>? {
        guard range.location != NSNotFound else { return nil }
        let lower = min(max(range.location, 0), length)
        return lower..<min(max(range.location + range.length, lower), length)
    }
}
#endif
