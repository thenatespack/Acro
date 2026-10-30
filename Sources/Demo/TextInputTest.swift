import Engine

/// Debug harness for text input (F2 toggles it): echoes typed text, the IME composition and the
/// last key events in the window title. Escape leaves it. Not a scene.
@MainActor
struct TextInputTest {
    private var text = ""
    private var caret = 0
    private var lastKeys: [String] = []

    private mutating func insert(_ s: String) {
        text.insert(contentsOf: s, at: text.index(text.startIndex, offsetBy: caret))
        caret += s.count
    }

    /// Returns the window title to show while active, or nil when the test isn't running.
    mutating func update(_ input: Input) -> String? {
        if !input.isTextInputActive {
            guard input.wasPressed(.f2) else { return nil }
            input.startTextInput(rect: TextInputRect(x: 20, y: 20, width: 2, height: 20))
        }
        for event in input.textEvents {
            switch event {
            case .text(let s):
                insert(s)
            case .key(let e):
                let mods = e.modifiers.isEmpty ? "" : "+\(e.modifiers.rawValue)"
                lastKeys = Array((lastKeys + ["\(e.key)\(mods)\(e.isRepeat ? "*" : "")"]).suffix(4))
                switch e.key {
                case .backspace where caret > 0:
                    text.remove(at: text.index(text.startIndex, offsetBy: caret - 1))
                    caret -= 1
                case .delete where caret < text.count:
                    text.remove(at: text.index(text.startIndex, offsetBy: caret))
                case .left: caret = max(0, caret - 1)
                case .right: caret = min(text.count, caret + 1)
                case .home: caret = 0
                case .end: caret = text.count
                case .v where e.modifiers.contains(.shortcut): insert(Clipboard.string ?? "")
                case .c where e.modifiers.contains(.shortcut): Clipboard.string = text
                case .escape:
                    input.stopTextInput()
                    return nil
                default: break
                }
            }
        }
        let marked = input.composition.map { "[\($0.text)]" } ?? ""
        let keys = lastKeys.joined(separator: " ")
        return "TEXT INPUT (Esc exits): \(text.prefix(caret))\(marked)|\(text.dropFirst(caret))   keys: \(keys)"
    }
}
