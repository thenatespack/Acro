import Testing
@testable import Engine
#if canImport(AppKit)
import AppKit
#endif

// "a", e + combining acute (2 UTF-16 units, 1 Character), a family emoji (ZWJ sequence, 8 units,
// 1 Character), a flag (4 units), then "z".
private let tricky = "a" + "e\u{301}" + "👨‍👩‍👧" + "🇯🇵" + "z"

@Test func utf16OffsetsCountCharactersByTheirCodeUnits() {
    #expect(tricky.count == 5)
    #expect(tricky.utf16.count == 1 + 2 + 8 + 4 + 1)
    #expect(TextOffsets.utf16Offset(ofCharacter: 0, in: tricky) == 0)
    #expect(TextOffsets.utf16Offset(ofCharacter: 2, in: tricky) == 3)
    #expect(TextOffsets.utf16Offset(ofCharacter: 3, in: tricky) == 11)
    #expect(TextOffsets.utf16Offset(ofCharacter: 5, in: tricky) == 16)
    #expect(TextOffsets.utf16Offset(ofCharacter: 99, in: tricky) == 16)
}

@Test func characterOffsetsRoundInsideClusters() {
    // Offset 2 is between "e" and its combining accent.
    #expect(TextOffsets.characterOffset(ofUTF16: 2, in: tricky, roundUp: false) == 1)
    #expect(TextOffsets.characterOffset(ofUTF16: 2, in: tricky, roundUp: true) == 2)
    // Boundaries map exactly, whichever way they round.
    #expect(TextOffsets.characterOffset(ofUTF16: 3, in: tricky, roundUp: false) == 2)
    #expect(TextOffsets.characterOffset(ofUTF16: 3, in: tricky, roundUp: true) == 2)
    // Inside the surrogate pair / ZWJ sequence of the family emoji.
    #expect(TextOffsets.characterOffset(ofUTF16: 4, in: tricky, roundUp: false) == 2)
    #expect(TextOffsets.characterOffset(ofUTF16: 7, in: tricky, roundUp: true) == 3)
    #expect(TextOffsets.characterOffset(ofUTF16: 16, in: tricky, roundUp: true) == 5)
    #expect(TextOffsets.characterOffset(ofUTF16: 500, in: tricky, roundUp: true) == 5)
    #expect(TextOffsets.characterOffset(ofUTF16: 0, in: "", roundUp: true) == 0)
}

@Test func characterRangeCoversPartiallySelectedClusters() {
    #expect(TextOffsets.characterRange(ofUTF16: 0..<1, in: tricky) == 0..<1)
    #expect(TextOffsets.characterRange(ofUTF16: 2..<3, in: tricky) == 1..<2)   // just the accent
    #expect(TextOffsets.characterRange(ofUTF16: 4..<6, in: tricky) == 2..<3)   // inside the emoji
    #expect(TextOffsets.characterRange(ofUTF16: 6..<12, in: tricky) == 2..<4)  // emoji tail + flag head
    #expect(TextOffsets.characterRange(ofUTF16: 5..<5, in: tricky) == 2..<2)   // empty stays empty
    #expect(TextOffsets.characterRange(ofUTF16: 0..<500, in: tricky) == 0..<5)
}

@Test func utf16RangeAndSubstringRoundTrip() {
    #expect(TextOffsets.utf16Range(ofCharacters: 1..<3, in: tricky) == 1..<11)
    let (text, actual) = TextOffsets.substring(ofUTF16: 2..<4, in: tricky)  // inside e+accent and the emoji
    #expect(text == "e\u{301}👨‍👩‍👧")
    #expect(actual == 1..<11)
    #expect(TextOffsets.substring(ofUTF16: 20..<30, in: tricky).text == "")
    for count in 0...tricky.count {
        let units = TextOffsets.utf16Offset(ofCharacter: count, in: tricky)
        #expect(TextOffsets.characterOffset(ofUTF16: units, in: tricky, roundUp: false) == count)
    }
}

@Test func sanitizingDropsControlAndFunctionKeyCharacters() {
    #expect(TextOffsets.sanitized("a\r\n\t\u{7f}\u{1b}b") == "ab")
    #expect(TextOffsets.sanitized("\u{F700}\u{F728}é👍") == "é👍")
    #expect(TextOffsets.sanitized("e\u{301}") == "e\u{301}")
}

@MainActor @Test func inactiveTextInputIgnoresEverything() {
    let input = Input()
    input.commitText("x")
    input.setComposition("x", selectedUTF16: 0..<0)
    input.textKeyEvent(.backspace, modifiers: [], isRepeat: false)
    #expect(input.textEvents.isEmpty && input.composition == nil)
    input.setKey(.w, down: true)
    #expect(input.isDown(.w) && input.wasPressed(.w))
}

@MainActor @Test func textEventsKeepOrderAndMergeAdjacentText() {
    let input = Input()
    input.startTextInput()
    input.commitText("a")
    input.commitText("b")
    input.textKeyEvent(.backspace, modifiers: [], isRepeat: false)
    input.textKeyEvent(.backspace, modifiers: [], isRepeat: true)
    input.commitText("c")
    #expect(input.textEvents == [
        .text("ab"), .key(KeyEvent(key: .backspace)), .key(KeyEvent(key: .backspace, isRepeat: true)), .text("c"),
    ])
    #expect(input.committedText == "abc")
    #expect(input.keyEvents.map(\.isRepeat) == [false, true])
    input.beginFrame()
    #expect(input.textEvents.isEmpty)
}

@MainActor @Test func keyRoutingSeparatesShortcutsFromTypedCharacters() {
    let input = Input()
    input.startTextInput()
    input.textKeyEvent(.a, modifiers: [], isRepeat: false)                  // typed: arrives as text instead
    input.textKeyEvent(.a, modifiers: [.shift], isRepeat: false)
    input.textKeyEvent(.e, modifiers: [.alt], isRepeat: false)              // dead key
    input.textKeyEvent(.a, modifiers: [.control, .alt], isRepeat: false)    // AltGr
    input.textKeyEvent(.leftShift, modifiers: [.shift], isRepeat: false)
    #expect(input.textEvents.isEmpty)
    input.textKeyEvent(.a, modifiers: [.command], isRepeat: false)
    input.textKeyEvent(.z, modifiers: [.control, .shift], isRepeat: false)
    input.textKeyEvent(.left, modifiers: [.shift, .alt], isRepeat: true)
    input.textKeyEvent(.enter, modifiers: [], isRepeat: false)
    input.textKeyEvent(.f5, modifiers: [], isRepeat: false)
    #expect(input.keyEvents.map(\.key) == [.a, .z, .left, .enter, .f5])
    #expect(input.keyEvents[2] == KeyEvent(key: .left, modifiers: [.shift, .alt], isRepeat: true))
}

@MainActor @Test func activeTextInputHidesKeysFromGameInput() {
    let input = Input()
    input.setKey(.leftShift, down: true)
    input.setKey(.d, down: true)             // held before the text field got focus
    input.startTextInput()
    input.setKey(.w, down: true)
    input.setKey(.backspace, down: true)
    #expect(!input.isDown(.w) && !input.wasPressed(.w) && !input.wasPressed(.backspace))
    #expect(input.isDown(.d))                // keeps reporting until released
    #expect(input.isDown(.leftShift) && input.modifiers == [.shift])
    input.setKey(.d, down: false)
    #expect(input.wasReleased(.d))
    input.stopTextInput()
    input.setKey(.w, down: true)
    #expect(input.isDown(.w))
}

@MainActor @Test func compositionTracksSelectionInCharactersAndCommitClearsIt() {
    let input = Input()
    input.startTextInput()
    // Japanese preedit with the selection on the second character; offsets are UTF-16.
    input.setComposition("にほん", selectedUTF16: 1..<2)
    #expect(input.composition == Composition(text: "にほん", selection: 1..<2))
    // Emoji: UTF-16 selection 2..<2 sits inside the 4-unit flag.
    input.setComposition("🇯🇵a", selectedUTF16: 4..<5)
    #expect(input.composition?.selection == 1..<2)
    input.setComposition("", selectedUTF16: 0..<0)
    #expect(input.composition == nil)

    input.setComposition("日本", selectedUTF16: 2..<2)
    input.commitText("日本")
    #expect(input.composition == nil && input.committedText == "日本")

    input.setComposition("x", selectedUTF16: 1..<1)
    input.commitComposition()
    #expect(input.committedText == "日本x")
    input.setComposition("y", selectedUTF16: 1..<1)
    input.stopTextInput()
    #expect(input.composition == nil && input.textEvents.isEmpty && !input.isTextInputActive)
}

#if canImport(AppKit)
@MainActor @Test func appKitClientHandlesDeadKeysAndInputMethods() {
    let input = Input()
    let view = GameView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    view.input = input

    // Inactive: the client reports nothing and ignores text.
    view.insertText("x", replacementRange: NSRange(location: NSNotFound, length: 0))
    #expect(!view.hasMarkedText() && input.textEvents.isEmpty)

    input.startTextInput(rect: TextInputRect(x: 100, y: 50, width: 2, height: 20))
    // Option+e, e: dead key composes "´", then insertText replaces it with "é".
    view.setMarkedText("´", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
    #expect(view.hasMarkedText())
    #expect(view.markedRange() == NSRange(location: 0, length: 1))
    view.insertText("é", replacementRange: NSRange(location: NSNotFound, length: 0))
    #expect(!view.hasMarkedText() && input.committedText == "é")

    // An input method composing with an emoji and an attributed string, selection after the emoji.
    let marked = NSAttributedString(string: "👍e\u{301}x")
    view.setMarkedText(marked, selectedRange: NSRange(location: 2, length: 2), replacementRange: NSRange(location: NSNotFound, length: 0))
    #expect(input.composition == Composition(text: "👍e\u{301}x", selection: 1..<2))
    #expect(view.markedRange() == NSRange(location: 0, length: 5))
    #expect(view.selectedRange() == NSRange(location: 2, length: 2))
    var actual = NSRange()
    let sub = view.attributedSubstring(forProposedRange: NSRange(location: 3, length: 1), actualRange: &actual)
    #expect(sub?.string == "e\u{301}" && actual == NSRange(location: 2, length: 2))
    // Out-of-range requests clamp instead of trapping.
    #expect(view.attributedSubstring(forProposedRange: NSRange(location: 40, length: 5), actualRange: nil)?.string == "")
    // Not composing: no document.
    view.unmarkText()
    #expect(input.committedText == "é👍e\u{301}x" && !view.hasMarkedText())
    #expect(view.attributedSubstring(forProposedRange: NSRange(location: 0, length: 1), actualRange: nil) == nil)
    #expect(view.selectedRange().location == NSNotFound)

    // Candidate window rect: caret rect flipped into AppKit's bottom-left coordinates.
    let rect = view.firstRect(forCharacterRange: NSRange(location: 0, length: 0), actualRange: nil)
    #expect(rect == NSRect(x: 100, y: 600 - 70, width: 2, height: 20))

    // Deactivating discards the composition; a late unmarkText must not commit it.
    view.setMarkedText("か", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: NSNotFound, length: 0))
    input.stopTextInput()
    view.unmarkText()
    #expect(input.textEvents.isEmpty && !view.hasMarkedText())
}
#endif
