import Foundation

/// Single-line text editing state: the text, a caret and a selection anchor, counted in
/// Characters (grapheme clusters), so an emoji or a letter with combining accents is one step.
/// `TextField` drives it from keys and the mouse; it is a value type so it can be tested alone.
public struct TextEditBuffer: Equatable, Sendable {
    public enum Granularity: Sendable {
        case character, word, line
    }

    public private(set) var characters: [Character]
    /// Caret position: the boundary before `characters[caret]`.
    public private(set) var caret: Int
    /// The other end of the selection (equal to `caret` when nothing is selected).
    public private(set) var anchor: Int
    /// Inserts are truncated to keep at most this many Characters.
    public var maxLength: Int?

    public init(_ text: String = "", maxLength: Int? = nil) {
        characters = Array(Self.sanitized(text))
        self.maxLength = maxLength
        if let maxLength, characters.count > maxLength { characters.removeSubrange(maxLength...) }
        caret = characters.count
        anchor = caret
    }

    public var text: String { String(characters) }
    public var count: Int { characters.count }
    public var selection: Range<Int> { min(caret, anchor)..<max(caret, anchor) }
    public var hasSelection: Bool { caret != anchor }
    public var selectedText: String { String(characters[selection]) }

    /// Replaces the text; the caret goes to the end.
    public mutating func setText(_ text: String) {
        self = TextEditBuffer(text, maxLength: maxLength)
    }

    /// Moves the caret to `index` (clamped); `extend` keeps the anchor (shift-click, shift-arrows).
    public mutating func setCaret(_ index: Int, extend: Bool = false) {
        caret = min(max(index, 0), characters.count)
        if !extend { anchor = caret }
    }

    public mutating func select(_ range: Range<Int>) {
        anchor = min(max(range.lowerBound, 0), characters.count)
        caret = min(max(range.upperBound, 0), characters.count)
    }

    public mutating func selectAll() { select(0..<characters.count) }

    /// Selects the word (or run of non-word characters) around boundary `index` (double click).
    public mutating func selectWord(at index: Int) {
        guard !characters.isEmpty else { return }
        let i = min(max(index, 0), characters.count - 1)
        let kind = Self.isWord(characters[i])
        var start = i, end = i + 1
        while start > 0, Self.isWord(characters[start - 1]) == kind { start -= 1 }
        while end < characters.count, Self.isWord(characters[end]) == kind { end += 1 }
        select(start..<end)
    }

    /// Replaces the selection with `text` (control characters and newlines removed). Returns
    /// whether the text changed.
    @discardableResult
    public mutating func insert(_ text: String) -> Bool {
        var insertion = Self.sanitized(text)
        let range = selection
        if let maxLength {
            let room = max(0, maxLength - (characters.count - range.count))
            if insertion.count > room { insertion = String(insertion.prefix(room)) }
        }
        if insertion.isEmpty && range.isEmpty { return false }
        // Rebuild through String so combining marks merge with what precedes them.
        let before = String(characters[..<range.lowerBound]) + insertion
        let combined = before + String(characters[range.upperBound...])
        characters = Array(combined)
        caret = min(before.count, characters.count)
        anchor = caret
        return true
    }

    /// Backspace: deletes the selection, or the Character / word / line start before the caret.
    @discardableResult
    public mutating func deleteBackward(by granularity: Granularity = .character) -> Bool {
        if hasSelection { return insert("") }
        guard caret > 0 else { return false }
        let start = boundary(before: caret, by: granularity)
        characters.removeSubrange(start..<caret)
        caret = start
        anchor = start
        return true
    }

    /// Forward delete: deletes the selection, or up to the next Character / word end / line end.
    @discardableResult
    public mutating func deleteForward(by granularity: Granularity = .character) -> Bool {
        if hasSelection { return insert("") }
        guard caret < characters.count else { return false }
        let end = boundary(after: caret, by: granularity)
        characters.removeSubrange(caret..<end)
        anchor = caret
        return true
    }

    /// Arrow left. Without `extend`, a selection collapses to its start instead of moving.
    public mutating func moveLeft(by granularity: Granularity = .character, extend: Bool = false) {
        if hasSelection && !extend && granularity == .character {
            setCaret(selection.lowerBound)
        } else {
            setCaret(boundary(before: caret, by: granularity), extend: extend)
        }
    }

    /// Arrow right. Without `extend`, a selection collapses to its end instead of moving.
    public mutating func moveRight(by granularity: Granularity = .character, extend: Bool = false) {
        if hasSelection && !extend && granularity == .character {
            setCaret(selection.upperBound)
        } else {
            setCaret(boundary(after: caret, by: granularity), extend: extend)
        }
    }

    public mutating func moveToStart(extend: Bool = false) { setCaret(0, extend: extend) }
    public mutating func moveToEnd(extend: Bool = false) { setCaret(characters.count, extend: extend) }

    /// The boundary a backward move by `granularity` from `index` reaches. Words: skip
    /// non-word characters, then the word (like option-left on macOS).
    public func boundary(before index: Int, by granularity: Granularity) -> Int {
        switch granularity {
        case .character: return max(index - 1, 0)
        case .line: return 0
        case .word:
            var i = min(index, characters.count)
            while i > 0, !Self.isWord(characters[i - 1]) { i -= 1 }
            while i > 0, Self.isWord(characters[i - 1]) { i -= 1 }
            return i
        }
    }

    /// The boundary a forward move by `granularity` from `index` reaches (end of the next word for `.word`).
    public func boundary(after index: Int, by granularity: Granularity) -> Int {
        switch granularity {
        case .character: return min(index + 1, characters.count)
        case .line: return characters.count
        case .word:
            var i = max(index, 0)
            while i < characters.count, !Self.isWord(characters[i]) { i += 1 }
            while i < characters.count, Self.isWord(characters[i]) { i += 1 }
            return i
        }
    }

    /// Letters, digits, marks and underscores make up words.
    public static func isWord(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
            || character.unicodeScalars.first.map { $0.properties.generalCategory == .nonspacingMark } == true
    }

    /// Removes newlines and other control characters (a single-line field can't hold them).
    static func sanitized(_ text: String) -> String {
        TextOffsets.sanitized(text.replacingOccurrences(of: "\r\n", with: " ").replacingOccurrences(of: "\n", with: " "))
    }
}

/// A single-line editable text field.
///
/// Mouse: click places the caret, drag selects, shift-click extends, double-click selects a
/// word, triple-click everything. Keys (macOS / elsewhere): arrows move (shift extends,
/// option / control jumps words, command / – jumps to the ends), Home/End/Up/Down jump to the
/// ends, Backspace/Delete (with the word modifier: by word), shortcut+A/C/X/V select all, copy,
/// cut, paste (through `UIContext.clipboard`), Enter calls `onSubmit`. Esc and Tab are left to
/// the context (unfocus, focus change). While focused it owns `Input` text input: the caret
/// rectangle is passed to `startTextInput` and an IME composition is drawn underlined at the caret.
public final class TextField: Widget {
    public private(set) var buffer: TextEditBuffer
    public var placeholder: String { didSet { setNeedsDisplay() } }
    /// Called after every edit by the user.
    public var onChange: ((String) -> Void)?
    /// Called on Enter.
    public var onSubmit: ((String) -> Void)?
    /// Called when the field loses focus.
    public var onEndEditing: ((String) -> Void)?
    /// Minimum width when measured (points).
    public var preferredWidth: Float = 160 { didSet { setNeedsLayout() } }

    private var scrollX: Float = 0
    private var lastActivity: Double = 0
    private var offsetsCache: (text: String, size: Float, offsets: [Float])?
    private var layoutCache = CachedTextLayout()
    private var placeholderCache = CachedTextLayout()

    public init(text: String = "", placeholder: String = "", name: String = "", onChange: ((String) -> Void)? = nil) {
        buffer = TextEditBuffer(text)
        self.placeholder = placeholder
        self.onChange = onChange
        super.init(name: name)
        padding = EdgeInsets(horizontal: 8, vertical: 0)
    }

    public var text: String {
        get { buffer.text }
        set {
            buffer.setText(newValue)
            setNeedsDisplay()
        }
    }

    /// Selects a Character range (e.g. to show a selection initially).
    public func select(_ range: Range<Int>) {
        buffer.select(range)
        touch()
    }

    public override var acceptsFocus: Bool { true }
    public override var accessibilityRole: UIAccessibilityRole { .textField }
    /// The placeholder names the field; the text is its value.
    public override var accessibilityText: String? { placeholder.isEmpty ? nil : placeholder }
    public override var accessibilityValue: String? { text }
    public override var wantsTextInput: Bool { true }
    public override var showsFocusRing: Bool { false }

    public override func measureContent(width: Float?) -> Vec2 {
        Vec2(preferredWidth, theme.controlHeight)
    }

    // MARK: Geometry

    /// What is drawn: the text with any IME composition in place of the selection.
    private var display: (text: String, composition: Range<Int>?, caret: Int) {
        if isFocused, let composition = context?.composition {
            let sel = buffer.selection
            let chars = buffer.characters
            let text = String(chars[..<sel.lowerBound]) + composition.text + String(chars[sel.upperBound...])
            let start = String(chars[..<sel.lowerBound]).count
            let length = composition.text.count
            return (text, start..<(start + length), start + min(composition.selection.upperBound, length))
        }
        return (buffer.text, nil, buffer.caret)
    }

    private func offsets(for text: String, size: Float) -> [Float] {
        if let cache = offsetsCache, cache.text == text, cache.size == size { return cache.offsets }
        let offsets = TextMetrics.caretOffsets(text, font: theme.font, size: size)
        offsetsCache = (text, size, offsets)
        return offsets
    }

    /// Scrolls horizontally so the caret stays inside the field.
    private func updateScroll(caretX: Float, textWidth: Float) {
        let visible = max(contentRect.width - 1, 0)
        if caretX - scrollX > visible { scrollX = caretX - visible }
        if caretX - scrollX < 0 { scrollX = caretX }
        scrollX = min(max(scrollX, 0), max(0, textWidth - visible))
    }

    private func caretRect(_ theme: UITheme) -> UIRect {
        let d = display
        let offsets = offsets(for: d.text, size: theme.fontSize)
        let caretX = offsets[min(d.caret, offsets.count - 1)]
        updateScroll(caretX: caretX, textWidth: offsets.last ?? 0)
        let content = contentRect
        let h = theme.lineHeight(theme.fontSize)
        return UIRect(x: snap(content.x + caretX - scrollX), y: snap(content.y + (content.height - h) / 2), width: 1, height: h)
    }

    public override var textInputCaretRect: UIRect { caretRect(theme) }

    /// The Character boundary closest to window x.
    public func characterIndex(atX x: Float) -> Int {
        let offsets = offsets(for: buffer.text, size: theme.fontSize)
        return TextMetrics.nearestBoundary(to: x - contentRect.x + scrollX, in: offsets)
    }

    // MARK: Editing

    private func touch() {
        lastActivity = context?.time ?? 0
        setNeedsDisplay()
    }

    private func edited(_ changed: Bool) {
        touch()
        if changed { onChange?(buffer.text) }
    }

    public override func focusChanged(_ focused: Bool) {
        touch()
        if !focused { onEndEditing?(buffer.text) }
    }

    public override func handleEvent(_ event: UIEvent) -> Bool {
        switch event {
        case .pointerDown(let e) where e.button == .left:
            let index = characterIndex(atX: e.position.x)
            if e.clickCount >= 3 {
                buffer.selectAll()
            } else if e.clickCount == 2 {
                buffer.selectWord(at: index)
            } else {
                buffer.setCaret(index, extend: e.modifiers.contains(.shift))
            }
            touch()
            return true
        case .pointerDrag(let e):
            if (context?.capturedWidget === self) && (e.clickCount < 2) {
                buffer.setCaret(characterIndex(atX: e.position.x), extend: true)
                touch()
            }
            return true
        case .pointerUp:
            return true
        case .text(let text):
            edited(buffer.insert(text))
            return true
        case .key(let e):
            return handleKey(e)
        default:
            return false
        }
    }

    /// The modifier that moves by words: option on macOS, control elsewhere.
    public static var wordModifier: KeyModifiers {
        #if os(macOS)
        .alt
        #else
        .control
        #endif
    }

    private func handleKey(_ e: KeyEvent) -> Bool {
        let mods = e.modifiers
        let shift = mods.contains(.shift)
        #if os(macOS)
        let line = mods.contains(.command)
        #else
        let line = false
        #endif
        let word = mods.contains(Self.wordModifier)
        let granularity: TextEditBuffer.Granularity = line ? .line : word ? .word : .character
        let shortcut = mods.contains(KeyModifiers.shortcut)
        switch e.key {
        case .left: buffer.moveLeft(by: granularity, extend: shift); touch()
        case .right: buffer.moveRight(by: granularity, extend: shift); touch()
        case .home, .up: buffer.moveToStart(extend: shift); touch()
        case .end, .down: buffer.moveToEnd(extend: shift); touch()
        case .backspace: edited(buffer.deleteBackward(by: granularity))
        case .delete: edited(buffer.deleteForward(by: granularity))
        case .a where shortcut: buffer.selectAll(); touch()
        case .c where shortcut:
            if buffer.hasSelection { context?.clipboard.string = buffer.selectedText }
        case .x where shortcut:
            if buffer.hasSelection {
                context?.clipboard.string = buffer.selectedText
                edited(buffer.insert(""))
            }
        case .v where shortcut:
            if let pasted = context?.clipboard.string { edited(buffer.insert(pasted)) }
        case .enter:
            onSubmit?(buffer.text)
        default:
            return false
        }
        return true
    }

    // MARK: Drawing

    public override func draw(_ list: UIDrawList, theme: UITheme) {
        let enabled = isEffectivelyEnabled
        let focused = isFocused
        let radii = UICornerRadii(theme.cornerRadius)
        list.fillRect(frame, color: enabled ? theme.fieldBackground : theme.fieldBackground.withAlpha(0.5), radii: radii)
        list.strokeRect(frame, color: focused ? theme.accent : isHovered ? theme.controlBorder.mixed(with: .white, 0.15)
                        : theme.controlBorder, width: focused ? theme.borderWidth + 0.5 : theme.borderWidth, radii: radii)

        let content = contentRect
        let size = theme.fontSize
        let d = display
        let offsets = offsets(for: d.text, size: size)
        let caret = caretRect(theme)  // also updates scrollX
        let textX = content.x - scrollX
        let lineHeight = theme.lineHeight(size)
        let textY = content.y + (content.height - lineHeight) / 2

        list.pushClip(UIRect(x: content.x - 1, y: frame.y, width: content.width + 2, height: frame.height))
        if d.text.isEmpty && !placeholder.isEmpty && d.composition == nil {
            let layout = placeholderCache.get(placeholder, font: theme.font, size: size)
            list.drawText(layout, font: theme.font, at: Vec2(content.x, textY), color: theme.placeholderColor)
        }
        // Selection behind the text.
        if focused, d.composition == nil, buffer.hasSelection {
            let sel = buffer.selection
            let x0 = textX + offsets[sel.lowerBound], x1 = textX + offsets[sel.upperBound]
            list.fillRect(UIRect(x: x0, y: textY, width: x1 - x0, height: lineHeight),
                          color: theme.textSelection, radii: UICornerRadii(2))
        } else if !focused, buffer.hasSelection {
            let sel = buffer.selection
            let x0 = textX + offsets[sel.lowerBound], x1 = textX + offsets[sel.upperBound]
            list.fillRect(UIRect(x: x0, y: textY, width: x1 - x0, height: lineHeight),
                          color: theme.textSelection.withAlpha(0.2), radii: UICornerRadii(2))
        }
        if !d.text.isEmpty {
            let layout = layoutCache.get(d.text, font: theme.font, size: size)
            list.drawText(layout, font: theme.font, at: Vec2(textX, textY),
                          color: enabled ? theme.textColor : theme.disabledTextColor)
        }
        // IME composition: underlined, with its own selection thicker.
        if let composition = d.composition {
            let x0 = textX + offsets[composition.lowerBound], x1 = textX + offsets[composition.upperBound]
            let underlineY = snap(textY + lineHeight - 2)
            list.fillRect(UIRect(x: x0, y: underlineY, width: x1 - x0, height: 1), color: theme.textColor)
            if let selection = context?.composition?.selection, !selection.isEmpty {
                let s0 = textX + offsets[composition.lowerBound + selection.lowerBound]
                let s1 = textX + offsets[composition.lowerBound + min(selection.upperBound, composition.count)]
                list.fillRect(UIRect(x: s0, y: underlineY - 1, width: s1 - s0, height: 2), color: theme.textColor)
            }
        }
        if focused && enabled && caretVisible(theme) {
            list.fillRect(caret, color: theme.caret)
        }
        list.popClip()
    }

    private func caretVisible(_ theme: UITheme) -> Bool {
        let period = theme.caretBlinkPeriod
        guard period > 0, let time = context?.time else { return true }
        return (time - lastActivity).truncatingRemainder(dividingBy: period) < period / 2
    }
}
