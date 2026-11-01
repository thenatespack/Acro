import Engine
import Foundation

/// State for multi-line text / code editing: text stored as Characters, line starts, caret,
/// selection anchor, and an undo/redo stack.
public struct CodeEditBuffer: Equatable, Sendable {
    public private(set) var characters: [Character]
    public private(set) var caret: Int
    public private(set) var anchor: Int
    public private(set) var lineStarts: [Int]

    public struct Snapshot: Equatable, Sendable {
        public var characters: [Character]
        public var caret: Int
        public var anchor: Int

        public init(characters: [Character], caret: Int, anchor: Int) {
            self.characters = characters
            self.caret = caret
            self.anchor = anchor
        }
    }

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    public init(_ text: String = "") {
        characters = Array(text)
        caret = characters.count
        anchor = caret
        lineStarts = Self.computeLineStarts(characters)
    }

    public static func computeLineStarts(_ chars: [Character]) -> [Int] {
        var starts = [0]
        for i in 0..<chars.count {
            if chars[i] == "\n" {
                starts.append(i + 1)
            }
        }
        return starts
    }

    public var text: String { String(characters) }
    public var count: Int { characters.count }
    public var lineCount: Int { lineStarts.count }
    public var selection: Range<Int> { min(caret, anchor)..<max(caret, anchor) }
    public var hasSelection: Bool { caret != anchor }
    public var selectedText: String { String(characters[selection]) }

    public mutating func setText(_ text: String) {
        recordUndo()
        characters = Array(text)
        lineStarts = Self.computeLineStarts(characters)
        caret = characters.count
        anchor = caret
    }

    public func lineIndex(for charIndex: Int) -> Int {
        guard lineStarts.count > 1 else { return 0 }
        let clamped = min(max(charIndex, 0), characters.count)
        var low = 0, high = lineStarts.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if lineStarts[mid] <= clamped {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }

    public func lineLength(_ line: Int) -> Int {
        guard line >= 0, line < lineStarts.count else { return 0 }
        let start = lineStarts[line]
        let end: Int
        if line + 1 < lineStarts.count {
            end = max(start, lineStarts[line + 1] - 1)
        } else {
            end = characters.count
        }
        return max(0, end - start)
    }

    public func lineRange(_ line: Int) -> Range<Int> {
        guard line >= 0, line < lineStarts.count else { return 0..<0 }
        let start = lineStarts[line]
        let len = lineLength(line)
        return start..<(start + len)
    }

    public func lineString(_ line: Int) -> String {
        let r = lineRange(line)
        guard !r.isEmpty else { return "" }
        return String(characters[r])
    }

    public func columnIndex(for charIndex: Int) -> Int {
        let line = lineIndex(for: charIndex)
        return min(max(charIndex - lineStarts[line], 0), lineLength(line))
    }

    public func charIndex(line: Int, column: Int) -> Int {
        guard !lineStarts.isEmpty else { return 0 }
        let l = min(max(line, 0), lineStarts.count - 1)
        let col = min(max(column, 0), lineLength(l))
        return lineStarts[l] + col
    }

    public mutating func setCaret(_ index: Int, extend: Bool = false) {
        caret = min(max(index, 0), characters.count)
        if !extend { anchor = caret }
    }

    public mutating func select(_ range: Range<Int>) {
        anchor = min(max(range.lowerBound, 0), characters.count)
        caret = min(max(range.upperBound, 0), characters.count)
    }

    public mutating func selectAll() {
        select(0..<characters.count)
    }

    public mutating func selectWord(at index: Int) {
        guard !characters.isEmpty else { return }
        let i = min(max(index, 0), characters.count - 1)
        let kind = TextEditBuffer.isWord(characters[i])
        var start = i, end = i + 1
        while start > 0, TextEditBuffer.isWord(characters[start - 1]) == kind { start -= 1 }
        while end < characters.count, TextEditBuffer.isWord(characters[end]) == kind { end += 1 }
        select(start..<end)
    }

    public mutating func recordUndo() {
        undoStack.append(Snapshot(characters: characters, caret: caret, anchor: anchor))
        if undoStack.count > 120 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    public mutating func undo() -> Bool {
        guard let prev = undoStack.popLast() else { return false }
        redoStack.append(Snapshot(characters: characters, caret: caret, anchor: anchor))
        characters = prev.characters
        caret = min(prev.caret, characters.count)
        anchor = min(prev.anchor, characters.count)
        lineStarts = Self.computeLineStarts(characters)
        return true
    }

    public mutating func redo() -> Bool {
        guard let next = redoStack.popLast() else { return false }
        undoStack.append(Snapshot(characters: characters, caret: caret, anchor: anchor))
        characters = next.characters
        caret = min(next.caret, characters.count)
        anchor = min(next.anchor, characters.count)
        lineStarts = Self.computeLineStarts(characters)
        return true
    }

    @discardableResult
    public mutating func insert(_ text: String) -> Bool {
        let range = selection
        let before = String(characters[..<range.lowerBound]) + text
        let combined = before + String(characters[range.upperBound...])
        characters = Array(combined)
        caret = before.count
        anchor = caret
        lineStarts = Self.computeLineStarts(characters)
        return true
    }

    @discardableResult
    public mutating func deleteBackward() -> Bool {
        if hasSelection { return insert("") }
        guard caret > 0 else { return false }
        let col = columnIndex(for: caret)
        if col >= 4 && col % 4 == 0 {
            let start = caret - 4
            let slice = characters[start..<caret]
            if slice.allSatisfy({ $0 == " " }) {
                characters.removeSubrange(start..<caret)
                caret = start
                anchor = caret
                lineStarts = Self.computeLineStarts(characters)
                return true
            }
        }
        characters.remove(at: caret - 1)
        caret -= 1
        anchor = caret
        lineStarts = Self.computeLineStarts(characters)
        return true
    }

    @discardableResult
    public mutating func deleteForward() -> Bool {
        if hasSelection { return insert("") }
        guard caret < characters.count else { return false }
        characters.remove(at: caret)
        lineStarts = Self.computeLineStarts(characters)
        return true
    }

    @discardableResult
    public mutating func insertNewline() -> Bool {
        let line = lineIndex(for: caret)
        let currentLine = lineString(line)
        let leadingSpaces = String(currentLine.prefix(while: { $0 == " " || $0 == "\t" }))
        var extra = ""
        let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("{") || trimmed.hasSuffix(":") {
            extra = "    "
        }
        return insert("\n" + leadingSpaces + extra)
    }

    @discardableResult
    public mutating func indent() -> Bool {
        if hasSelection {
            let startLine = lineIndex(for: selection.lowerBound)
            let endLine = lineIndex(for: max(selection.upperBound - 1, selection.lowerBound))
            var offset = 0
            for l in startLine...endLine {
                let pos = lineStarts[l] + offset
                characters.insert(contentsOf: "    ", at: pos)
                offset += 4
            }
            lineStarts = Self.computeLineStarts(characters)
            caret += offset
            anchor = lineStarts[startLine]
            return true
        } else {
            return insert("    ")
        }
    }

    @discardableResult
    public mutating func dedent() -> Bool {
        let startLine = lineIndex(for: selection.lowerBound)
        let endLine = lineIndex(for: max(selection.upperBound - 1, selection.lowerBound))
        var offset = 0
        for l in startLine...endLine {
            let pos = lineStarts[l] - offset
            var removed = 0
            while removed < 4 && pos + removed < characters.count && characters[pos + removed] == " " {
                removed += 1
            }
            if removed > 0 {
                characters.removeSubrange(pos..<(pos + removed))
                offset += removed
            }
        }
        if offset > 0 {
            lineStarts = Self.computeLineStarts(characters)
            caret = max(lineStarts[startLine], caret - offset)
            anchor = caret
            return true
        }
        return false
    }

    public mutating func moveLeft(extend: Bool = false, byWord: Bool = false) {
        if hasSelection && !extend && !byWord {
            setCaret(selection.lowerBound)
            return
        }
        if byWord {
            var i = max(caret - 1, 0)
            while i > 0 && !TextEditBuffer.isWord(characters[i]) { i -= 1 }
            while i > 0 && TextEditBuffer.isWord(characters[i - 1]) { i -= 1 }
            setCaret(i, extend: extend)
        } else {
            setCaret(max(caret - 1, 0), extend: extend)
        }
    }

    public mutating func moveRight(extend: Bool = false, byWord: Bool = false) {
        if hasSelection && !extend && !byWord {
            setCaret(selection.upperBound)
            return
        }
        if byWord {
            var i = min(caret + 1, characters.count)
            while i < characters.count && !TextEditBuffer.isWord(characters[i]) { i += 1 }
            while i < characters.count && TextEditBuffer.isWord(characters[i]) { i += 1 }
            setCaret(i, extend: extend)
        } else {
            setCaret(min(caret + 1, characters.count), extend: extend)
        }
    }

    public mutating func moveUp(extend: Bool = false) {
        let line = lineIndex(for: caret)
        guard line > 0 else {
            setCaret(0, extend: extend)
            return
        }
        let col = columnIndex(for: caret)
        let target = charIndex(line: line - 1, column: col)
        setCaret(target, extend: extend)
    }

    public mutating func moveDown(extend: Bool = false) {
        let line = lineIndex(for: caret)
        guard line + 1 < lineCount else {
            setCaret(characters.count, extend: extend)
            return
        }
        let col = columnIndex(for: caret)
        let target = charIndex(line: line + 1, column: col)
        setCaret(target, extend: extend)
    }

    public mutating func moveToLineStart(extend: Bool = false) {
        let line = lineIndex(for: caret)
        setCaret(lineStarts[line], extend: extend)
    }

    public mutating func moveToLineEnd(extend: Bool = false) {
        let line = lineIndex(for: caret)
        let end = lineStarts[line] + lineLength(line)
        setCaret(end, extend: extend)
    }
}

/// Swift syntax tokenizer for code display.
public enum SwiftSyntaxTokenizer {
    public enum TokenKind: Sendable {
        case keyword, type, string, comment, number, attribute, plain
    }

    public struct Token: Sendable {
        public var text: String
        public var kind: TokenKind
        public var range: Range<Int>
    }

    private static let keywords: Set<String> = [
        "import", "func", "var", "let", "struct", "class", "public", "private", "internal",
        "fileprivate", "init", "deinit", "guard", "if", "else", "return", "switch", "case",
        "default", "for", "in", "while", "mutating", "override", "true", "false", "nil",
        "self", "Self", "try", "throw", "throws", "catch", "weak", "unowned", "enum",
        "protocol", "extension", "where", "typealias", "some", "any", "async", "await",
        "actor", "static", "open", "final", "as", "is", "repeat", "continue", "break"
    ]

    public static func tokenize(line: String) -> [Token] {
        guard !line.isEmpty else { return [] }
        var tokens: [Token] = []
        let chars = Array(line)
        var i = 0

        while i < chars.count {
            // Check for line comment //
            if i + 1 < chars.count && chars[i] == "/" && chars[i + 1] == "/" {
                let text = String(chars[i...])
                tokens.append(Token(text: text, kind: .comment, range: i..<chars.count))
                break
            }

            // String literal
            if chars[i] == "\"" {
                var j = i + 1
                while j < chars.count {
                    if chars[j] == "\\" && j + 1 < chars.count {
                        j += 2
                    } else if chars[j] == "\"" {
                        j += 1
                        break
                    } else {
                        j += 1
                    }
                }
                let text = String(chars[i..<j])
                tokens.append(Token(text: text, kind: .string, range: i..<j))
                i = j
                continue
            }

            // Attribute (@...)
            if chars[i] == "@" {
                var j = i + 1
                while j < chars.count && (TextEditBuffer.isWord(chars[j]) || chars[j] == "_") {
                    j += 1
                }
                let text = String(chars[i..<j])
                tokens.append(Token(text: text, kind: .attribute, range: i..<j))
                i = j
                continue
            }

            // Number
            if chars[i].isNumber {
                var j = i + 1
                while j < chars.count && (chars[j].isNumber || chars[j] == "." || chars[j] == "x" || chars[j] == "X") {
                    j += 1
                }
                let text = String(chars[i..<j])
                tokens.append(Token(text: text, kind: .number, range: i..<j))
                i = j
                continue
            }

            // Identifier or keyword
            if TextEditBuffer.isWord(chars[i]) {
                var j = i + 1
                while j < chars.count && TextEditBuffer.isWord(chars[j]) {
                    j += 1
                }
                let text = String(chars[i..<j])
                let kind: TokenKind
                if keywords.contains(text) {
                    kind = .keyword
                } else if let first = text.first, first.isUppercase {
                    kind = .type
                } else {
                    kind = .plain
                }
                tokens.append(Token(text: text, kind: kind, range: i..<j))
                i = j
                continue
            }

            // Whitespace or punctuation
            var j = i + 1
            while j < chars.count && !TextEditBuffer.isWord(chars[j]) && chars[j] != "\"" && chars[j] != "@" && !(chars[j] == "/" && j + 1 < chars.count && chars[j+1] == "/") {
                j += 1
            }
            let text = String(chars[i..<j])
            tokens.append(Token(text: text, kind: .plain, range: i..<j))
            i = j
        }

        return tokens
    }
}

/// A multi-line code editor widget with line numbers, syntax highlighting, selection,
/// undo/redo, auto-indentation, and scrolling integration.
public final class CodeEditorWidget: Widget {
    public private(set) var buffer: CodeEditBuffer
    public var onChange: ((String) -> Void)?
    public var onSave: (() -> Void)?
    public var isEditable: Bool = true

    private var lastActivity: Double = 0
    private var lineOffsetsCache: [Int: [Float]] = [:]
    private var tokensCache: [Int: [SwiftSyntaxTokenizer.Token]] = [:]

    public init(text: String = "", name: String = "codeEditor") {
        buffer = CodeEditBuffer(text)
        super.init(name: name)
        padding = EdgeInsets(top: 4, left: 0, bottom: 8, right: 8)
    }

    public var text: String {
        get { buffer.text }
        set {
            buffer.setText(newValue)
            lineOffsetsCache.removeAll()
            tokensCache.removeAll()
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public override var acceptsFocus: Bool { true }
    public override var wantsTextInput: Bool { true }
    public override var showsFocusRing: Bool { false }

    public var gutterWidth: Float {
        let digits = max(String(buffer.lineCount).count, 2)
        return Float(digits) * 9 + 20
    }

    public func effectiveLineHeight(_ theme: UITheme) -> Float {
        theme.lineHeight(theme.fontSize) + 2
    }

    private func touch() {
        lastActivity = context?.time ?? 0
        setNeedsDisplay()
    }

    private func edited() {
        touch()
        lineOffsetsCache.removeAll()
        tokensCache.removeAll()
        setNeedsLayout()
        onChange?(buffer.text)
    }

    private func offsets(for line: Int, size: Float, font: Font) -> [Float] {
        if let cached = lineOffsetsCache[line] { return cached }
        let str = buffer.lineString(line)
        let result = TextMetrics.caretOffsets(str, font: font, size: size)
        lineOffsetsCache[line] = result
        return result
    }

    private func tokens(for line: Int) -> [SwiftSyntaxTokenizer.Token] {
        if let cached = tokensCache[line] { return cached }
        let str = buffer.lineString(line)
        let result = SwiftSyntaxTokenizer.tokenize(line: str)
        tokensCache[line] = result
        return result
    }

    public override func measureContent(width: Float?) -> Vec2 {
        let size = theme.fontSize
        let h = Float(max(buffer.lineCount, 1)) * effectiveLineHeight(theme) + 40
        var maxW: Float = 320
        for i in 0..<buffer.lineCount {
            let str = buffer.lineString(i)
            if !str.isEmpty {
                let off = offsets(for: i, size: size, font: theme.font)
                if let last = off.last, last > maxW { maxW = last }
            }
        }
        return Vec2(maxW + gutterWidth + 40, h)
    }

    public override var textInputCaretRect: UIRect {
        let size = theme.fontSize
        let lh = effectiveLineHeight(theme)
        let line = buffer.lineIndex(for: buffer.caret)
        let col = buffer.columnIndex(for: buffer.caret)
        let off = offsets(for: line, size: size, font: theme.font)
        let colClamped = min(col, off.count - 1)
        let caretX = contentRect.x + gutterWidth + off[colClamped]
        let caretY = contentRect.y + Float(line) * lh
        return UIRect(x: caretX, y: caretY, width: 2, height: lh)
    }

    private func scrollToCaret() {
        let rect = textInputCaretRect
        let reveal = UIRect(x: rect.x - 30, y: rect.y - 10, width: 60, height: rect.height + 20)
        _ = parent?.scrollToReveal(reveal)
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            let lh = effectiveLineHeight(theme)
            let yRel = e.position.y - contentRect.y
            let line = min(max(Int((yRel / lh).rounded(.down)), 0), buffer.lineCount - 1)
            let xRel = e.position.x - contentRect.x - gutterWidth
            let off = offsets(for: line, size: theme.fontSize, font: theme.font)
            let col = TextMetrics.nearestBoundary(to: xRel, in: off)
            let charIdx = buffer.charIndex(line: line, column: col)

            if e.clickCount >= 3 {
                let start = buffer.lineStarts[line]
                let end = line + 1 < buffer.lineCount ? buffer.lineStarts[line + 1] : buffer.characters.count
                buffer.select(start..<end)
            } else if e.clickCount == 2 {
                buffer.selectWord(at: charIdx)
            } else {
                buffer.setCaret(charIdx, extend: e.modifiers.contains(.shift))
            }
            touch()
            return true

        case .pointerDrag(let e):
            if context?.capturedWidget === self && e.clickCount < 2 {
                let lh = effectiveLineHeight(theme)
                let yRel = e.position.y - contentRect.y
                let line = min(max(Int((yRel / lh).rounded(.down)), 0), buffer.lineCount - 1)
                let xRel = e.position.x - contentRect.x - gutterWidth
                let off = offsets(for: line, size: theme.fontSize, font: theme.font)
                let col = TextMetrics.nearestBoundary(to: xRel, in: off)
                let charIdx = buffer.charIndex(line: line, column: col)
                buffer.setCaret(charIdx, extend: true)
                touch()
                scrollToCaret()
            }
            return true

        case .pointerUp:
            return true

        case .text(let str):
            guard isEditable else { return true }
            if str == "\r" || str == "\n" {
                buffer.recordUndo()
                if buffer.insertNewline() { edited() }
                scrollToCaret()
                return true
            }
            if str == "\t" {
                buffer.recordUndo()
                if buffer.indent() { edited() }
                scrollToCaret()
                return true
            }
            buffer.recordUndo()
            if buffer.insert(str) { edited() }
            scrollToCaret()
            return true

        case .key(let e):
            return handleKey(e)

        default:
            return false
        }
    }

    private func handleKey(_ e: KeyEvent) -> Bool {
        let mods = e.modifiers
        let shift = mods.contains(.shift)
        let shortcut = mods.contains(KeyModifiers.shortcut)
        let word = mods.contains(TextField.wordModifier)
        #if os(macOS)
        let line = mods.contains(.command)
        #else
        let line = false
        #endif

        if shortcut {
            switch e.key {
            case .a:
                buffer.selectAll()
                touch()
                return true
            case .c:
                if buffer.hasSelection {
                    context?.clipboard.string = buffer.selectedText
                } else {
                    let l = buffer.lineIndex(for: buffer.caret)
                    context?.clipboard.string = buffer.lineString(l) + "\n"
                }
                return true
            case .x:
                guard isEditable else { return true }
                if buffer.hasSelection {
                    buffer.recordUndo()
                    context?.clipboard.string = buffer.selectedText
                    buffer.insert("")
                    edited()
                }
                return true
            case .v:
                guard isEditable else { return true }
                if let pasted = context?.clipboard.string {
                    buffer.recordUndo()
                    buffer.insert(pasted)
                    edited()
                }
                return true
            case .z:
                guard isEditable else { return true }
                if shift {
                    if buffer.redo() { edited() }
                } else {
                    if buffer.undo() { edited() }
                }
                scrollToCaret()
                return true
            case .y:
                guard isEditable else { return true }
                if buffer.redo() { edited() }
                scrollToCaret()
                return true
            case .s:
                onSave?()
                return true
            default:
                break
            }
        }

        switch e.key {
        case .left:
            if line { buffer.moveToLineStart(extend: shift) }
            else { buffer.moveLeft(extend: shift, byWord: word) }
            touch()
            scrollToCaret()
            return true
        case .right:
            if line { buffer.moveToLineEnd(extend: shift) }
            else { buffer.moveRight(extend: shift, byWord: word) }
            touch()
            scrollToCaret()
            return true
        case .up:
            buffer.moveUp(extend: shift)
            touch()
            scrollToCaret()
            return true
        case .down:
            buffer.moveDown(extend: shift)
            touch()
            scrollToCaret()
            return true
        case .home:
            buffer.moveToLineStart(extend: shift)
            touch()
            scrollToCaret()
            return true
        case .end:
            buffer.moveToLineEnd(extend: shift)
            touch()
            scrollToCaret()
            return true
        case .pageUp:
            for _ in 0..<15 { buffer.moveUp(extend: shift) }
            touch()
            scrollToCaret()
            return true
        case .pageDown:
            for _ in 0..<15 { buffer.moveDown(extend: shift) }
            touch()
            scrollToCaret()
            return true
        case .backspace:
            guard isEditable else { return true }
            buffer.recordUndo()
            if buffer.deleteBackward() { edited() }
            scrollToCaret()
            return true
        case .delete:
            guard isEditable else { return true }
            buffer.recordUndo()
            if buffer.deleteForward() { edited() }
            scrollToCaret()
            return true
        case .enter:
            guard isEditable else { return true }
            buffer.recordUndo()
            if buffer.insertNewline() { edited() }
            scrollToCaret()
            return true
        case .tab:
            guard isEditable else { return true }
            buffer.recordUndo()
            if shift {
                if buffer.dedent() { edited() }
            } else {
                if buffer.indent() { edited() }
            }
            scrollToCaret()
            return true
        default:
            return false
        }
    }

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let size = theme.fontSize
        let lh = effectiveLineHeight(theme)
        let gutter = gutterWidth
        let activeLine = buffer.lineIndex(for: buffer.caret)
        let font = theme.font

        // Draw background
        list.fillRect(frame, color: theme.fieldBackground)

        // Draw active line highlight
        let activeLineY = contentRect.y + Float(activeLine) * lh
        let activeLineRect = UIRect(x: contentRect.x + gutter, y: activeLineY, width: max(contentRect.width - gutter, 10), height: lh)
        list.fillRect(activeLineRect, color: theme.rowHover.withAlpha(0.25))

        // Draw gutter background & line
        let gutterRect = UIRect(x: frame.x, y: frame.y, width: gutter, height: frame.height)
        list.fillRect(gutterRect, color: theme.panelBackground.withAlpha(0.85))
        list.fillRect(UIRect(x: frame.x + gutter - 1, y: frame.y, width: 1, height: frame.height), color: theme.controlBorder)

        let visibleStart = max(0, Int(((frame.y - contentRect.y) / lh).rounded(.down)) - 2)
        let visibleEnd = min(buffer.lineCount, Int(((frame.maxY - contentRect.y) / lh).rounded(.up)) + 2)

        let sel = buffer.selection
        let isLight = theme.name == "Light"

        // Syntax colors
        let keywordColor = isLight ? UIColor(hex: 0xcf222e) : UIColor(hex: 0xff7b72)
        let typeColor = isLight ? UIColor(hex: 0x0550ae) : UIColor(hex: 0x79c0ff)
        let stringColor = isLight ? UIColor(hex: 0x116329) : UIColor(hex: 0x7ee787)
        let commentColor = isLight ? UIColor(hex: 0x6e7781) : UIColor(hex: 0x8b949e)
        let numberColor = isLight ? UIColor(hex: 0x8250df) : UIColor(hex: 0xd2a8ff)
        let attributeColor = isLight ? UIColor(hex: 0x953800) : UIColor(hex: 0xffa657)

        for l in visibleStart..<visibleEnd {
            let lineY = contentRect.y + Float(l) * lh
            let off = offsets(for: l, size: size, font: font)
            let lineStartChar = buffer.lineStarts[l]
            let lineLen = buffer.lineLength(l)
            let lineEndChar = lineStartChar + lineLen

            // Draw line number
            let lineNumStr = String(l + 1)
            let numColor = l == activeLine ? theme.textColor : theme.disabledTextColor
            let numWidth = Float(lineNumStr.count) * 8.5
            let numX = frame.x + gutter - 12 - numWidth
            list.drawText(lineNumStr, at: Vec2(numX, lineY), size: theme.smallFontSize, color: numColor, font: font)

            // Draw selection background if overlapping
            if buffer.hasSelection && sel.upperBound > lineStartChar && sel.lowerBound < lineEndChar {
                let selStartInLine = max(0, min(sel.lowerBound - lineStartChar, lineLen))
                let selEndInLine = max(0, min(sel.upperBound - lineStartChar, lineLen))
                if selStartInLine < selEndInLine && selEndInLine < off.count {
                    let selX0 = contentRect.x + gutter + off[selStartInLine]
                    let selX1 = contentRect.x + gutter + off[selEndInLine]
                    list.fillRect(UIRect(x: selX0, y: lineY, width: max(selX1 - selX0, 2), height: lh),
                                  color: theme.textSelection)
                }
            }

            // Draw tokens
            let tokList = tokens(for: l)
            for tok in tokList {
                let startInLine = tok.range.lowerBound
                guard startInLine < off.count else { continue }
                let tokX = contentRect.x + gutter + off[startInLine]
                let color: UIColor
                switch tok.kind {
                case .keyword: color = keywordColor
                case .type: color = typeColor
                case .string: color = stringColor
                case .comment: color = commentColor
                case .number: color = numberColor
                case .attribute: color = attributeColor
                case .plain: color = theme.textColor
                }
                list.drawText(tok.text, at: Vec2(tokX, lineY), size: size, color: color, font: font)
            }
        }

        // Draw caret
        if isFocused && caretVisible(theme) {
            let caretRect = textInputCaretRect
            list.fillRect(caretRect, color: theme.caret)
        }
    }

    private func caretVisible(_ theme: UITheme) -> Bool {
        let period = theme.caretBlinkPeriod
        guard period > 0, let time = context?.time else { return true }
        return (time - lastActivity).truncatingRemainder(dividingBy: period) < period / 2
    }
}
