import Foundation

// Accessibility-style introspection of a widget tree, and synthetic input through the same
// event path real input takes. UI tests and AI agents use it to see and drive any UI, including
// panels nobody wrote a command for.
//
// ```swift
// let elements = ui.accessibilityElements()            // depth first: path, role, label, value, frame…
// let save = ui.accessibilityElement(path: "editorRoot/toolbar/save")!
// ui.synthesizeClick(at: save.frame.center)            // pointerMoved, pointerButton down / up
// ui.synthesizeText("Crate"); ui.synthesizeKey(KeyEvent(key: .enter))
// ```
//
// ## Elements
//
// Every visible widget is an element: its `accessibilityRole` (button, textField, tree…), a
// label (`accessibilityLabel`, else `accessibilityText`, the tooltip, then the name made
// readable), `accessibilityValue`, its frame, whether it is enabled, focused, hovered and on
// screen (not scrolled or clipped away), its tooltip, and `command`: the id of the action it
// runs, inherited from ancestors (an editor sets its command ids on widgets). Parts a widget
// draws itself (tree rows, tabs and their close buttons, menu items, asset cells) are
// `accessibilityItems`, listed as children of their widget. An item's command is its own, else
// the nearest `itemCommands[kind]` up the tree (`kind` is the part of its key before ":").
//
// ## Paths
//
// A path names an element by the segments from the root down, joined with "/": a widget's
// `name`, or its role when unnamed, with "[n]" appended to the n-th later sibling with the
// same segment; an item's key ("row:Cube"). Overlays (menus, dialogs) are top-level like the
// root's children. Paths stay the same while the tree does, so a snapshot's paths can be
// clicked later: `editorRoot/toolbar/save`, `menu/item:Cube`, `…/hierarchyTree/row:Blue Sphere`.
//
// ## Synthetic input
//
// `synthesizeClick`, `synthesizeDrag`, `synthesizeScroll`, `synthesizeKey` and `synthesizeText`
// call the context's event methods (`pointerMoved`, `pointerButton`, `scrolled`, `keyPressed`,
// `textEntered`) exactly as `update(input:)` does for real input, laying out between steps, so
// widgets can't tell them apart. They run at once: a click is a press and a release at the same
// point, a drag a press, `steps` moves and a release.

/// What kind of control an element is.
public enum UIAccessibilityRole: String, Codable, Sendable, CaseIterable {
    case group, label, button, checkbox, radioButton, toggle, slider, textField, numberField, dropdown
    case menu, menuItem, list, listItem, tree, treeItem, tabGroup, tab, scrollView, splitView, separator
    case header, colorWell, dialog, progressBar, viewport, image

    /// Whether the user can act on it (click, type, pick).
    public var isInteractive: Bool {
        switch self {
        case .button, .checkbox, .radioButton, .toggle, .slider, .textField, .numberField, .dropdown, .menuItem,
             .listItem, .treeItem, .tab, .header, .colorWell:
            true
        default:
            false
        }
    }
}

/// A part of a widget that acts like a control of its own (a row, a tab, a menu item).
public struct UIAccessibilityItem: Sendable, Equatable {
    /// "<kind>:<name>", unique within the widget where possible ("row:Cube", "tab:console").
    public var key: String
    public var role: UIAccessibilityRole
    public var label: String
    public var value: String?
    /// Window points.
    public var frame: UIRect
    public var isSelected: Bool
    public var isEnabled: Bool
    public var tooltip: String?
    public var command: String?

    public init(key: String, role: UIAccessibilityRole, label: String, value: String? = nil, frame: UIRect,
                isSelected: Bool = false, isEnabled: Bool = true, tooltip: String? = nil, command: String? = nil) {
        self.key = key
        self.role = role
        self.label = label
        self.value = value
        self.frame = frame
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.tooltip = tooltip
        self.command = command
    }

    /// The part of the key before ":" ("row").
    public var kind: String { key.split(separator: ":", maxSplits: 1).first.map(String.init) ?? key }
}

/// One element of `UIContext.accessibilityElements()`: a widget or one of its items.
@MainActor
public struct UIAccessibilityElement {
    public var path: String
    /// The path of the element it belongs to (nil at the top level).
    public var parentPath: String?
    public var depth: Int
    public var role: UIAccessibilityRole
    public var label: String?
    public var value: String?
    /// Window points (the context's coordinates).
    public var frame: UIRect
    public var isEnabled: Bool
    public var isFocused: Bool
    public var isSelected: Bool
    public var isHovered: Bool
    /// Whether some of it is visible: inside the viewport and not clipped by a scroll view.
    public var isOnScreen: Bool
    public var tooltip: String?
    public var command: String?
    /// The widget (for an item, the widget that draws it).
    public let widget: Widget
    /// The item's key, nil for a widget.
    public var itemKey: String?

    /// The point a click aims at: the middle of the visible part.
    public var clickPoint: Vec2 { frame.center }
}

extension Widget {
    /// The label tools show: `accessibilityLabel`, else `accessibilityText`, the tooltip, for a
    /// control the nearest ancestor's `accessibilityLabel` (a property grid row labels its
    /// editor), or the name made readable ("scenePath" → "Scene path"); nil when there is none.
    public var effectiveAccessibilityLabel: String? {
        if let accessibilityLabel, !accessibilityLabel.isEmpty { return accessibilityLabel }
        if let text = accessibilityText, !text.isEmpty { return text }
        if let tooltip, !tooltip.isEmpty { return tooltip }
        if accessibilityRole.isInteractive {
            var node = parent
            while let current = node {
                if let label = current.accessibilityLabel, !label.isEmpty { return label }
                node = current.parent
            }
        }
        return Self.readableName(name)
    }

    /// The command this widget runs: its own, else the nearest ancestor's.
    public var effectiveCommand: String? {
        var node: Widget? = self
        while let current = node {
            if let command = current.command { return command }
            node = current.parent
        }
        return nil
    }

    /// The command of an item of `kind` drawn by this widget: the nearest `itemCommands[kind]`.
    public func itemCommand(_ kind: String) -> String? {
        var node: Widget? = self
        while let current = node {
            if let command = current.itemCommands[kind] { return command }
            node = current.parent
        }
        return nil
    }

    /// "scenePath" → "Scene path", "deleteAsset" → "Delete asset", "Light.intensity" →
    /// "Light intensity"; nil for empty names.
    static func readableName(_ name: String) -> String? {
        guard !name.isEmpty else { return nil }
        var words: [String] = []
        var current = ""
        for character in name {
            if !(character.isLetter || character.isNumber) {
                if !current.isEmpty { words.append(current) }
                current = ""
                continue
            }
            if character.isUppercase, !current.isEmpty, current.last?.isUppercase == false {
                words.append(current)
                current = ""
            }
            current.append(character)
        }
        if !current.isEmpty { words.append(current) }
        guard !words.isEmpty else { return nil }
        let text = words.map { $0.lowercased() }.joined(separator: " ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}

extension UIContext {
    // MARK: Introspection

    /// Every element (widgets and their items), depth first, parents before children; the
    /// root's children first, then the overlays. Hidden widgets are left out unless `includeHidden`.
    public func accessibilityElements(includeHidden: Bool = false) -> [UIAccessibilityElement] {
        layoutIfNeeded()
        var elements: [UIAccessibilityElement] = []
        let viewport = self.viewport

        func intersection(_ a: UIRect, _ b: UIRect) -> UIRect? {
            let x0 = max(a.x, b.x), y0 = max(a.y, b.y), x1 = min(a.maxX, b.maxX), y1 = min(a.maxY, b.maxY)
            return x1 > x0 && y1 > y0 ? UIRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0) : nil
        }

        /// Appends `"[n]"` to repeats of a segment among siblings.
        func uniqueSegments(_ segments: [String]) -> [String] {
            var seen: [String: Int] = [:]
            return segments.map { segment in
                let n = seen[segment, default: 0]
                seen[segment] = n + 1
                return n == 0 ? segment : "\(segment)[\(n)]"
            }
        }

        func visit(_ widget: Widget, segment: String, parentPath: String?, depth: Int, clip: UIRect?) {
            guard includeHidden || !widget.isHidden else { return }
            let path = parentPath.map { "\($0)/\(segment)" } ?? segment
            let visible = clip.flatMap { intersection(widget.frame, $0) }
            elements.append(UIAccessibilityElement(
                path: path, parentPath: parentPath, depth: depth, role: widget.accessibilityRole,
                label: widget.effectiveAccessibilityLabel, value: widget.accessibilityValue, frame: widget.frame,
                isEnabled: widget.isEffectivelyEnabled, isFocused: focusedWidget === widget, isSelected: false,
                isHovered: hoveredWidget === widget, isOnScreen: visible != nil && widget.isEffectivelyVisible,
                tooltip: widget.tooltip, command: widget.effectiveCommand, widget: widget, itemKey: nil))
            let childClip = widget.clipsContent ? clip.flatMap { intersection(widget.frame, $0) } : clip
            let items = widget.accessibilityItems
            for (item, key) in zip(items, uniqueSegments(items.map(\.key))) {
                elements.append(UIAccessibilityElement(
                    path: "\(path)/\(key)", parentPath: path, depth: depth + 1, role: item.role, label: item.label,
                    value: item.value, frame: item.frame, isEnabled: item.isEnabled && widget.isEffectivelyEnabled,
                    isFocused: false, isSelected: item.isSelected, isHovered: false,
                    isOnScreen: childClip.flatMap { intersection(item.frame, $0) } != nil && widget.isEffectivelyVisible,
                    tooltip: item.tooltip, command: item.command ?? widget.itemCommand(item.kind), widget: widget,
                    itemKey: item.key))
            }
            let children = widget.children.filter { includeHidden || !$0.isHidden }
            // Children are clipped where the widget clips them (a tab view: below its tab bar).
            let clipForChildren = widget.clipsContent ? clip.flatMap { intersection(widget.childClipRect, $0) } : clip
            for (child, childSegment) in zip(children, uniqueSegments(children.map(Self.segment))) {
                visit(child, segment: childSegment, parentPath: path, depth: depth + 1, clip: clipForChildren)
            }
        }

        let tops = root.children.filter { includeHidden || !$0.isHidden } + overlays
        for (widget, segment) in zip(tops, uniqueSegments(tops.map(Self.segment))) {
            visit(widget, segment: segment, parentPath: nil, depth: 0, clip: viewport)
        }
        return elements
    }

    /// The element at `path` (see the notes at the top of this file), if it is shown.
    public func accessibilityElement(path: String) -> UIAccessibilityElement? {
        accessibilityElements().first { $0.path == path }
    }

    /// The element for `widget` (shown), if any.
    public func accessibilityElement(for widget: Widget) -> UIAccessibilityElement? {
        accessibilityElements().first { $0.widget === widget && $0.itemKey == nil }
    }

    private static func segment(_ widget: Widget) -> String {
        widget.name.isEmpty ? widget.accessibilityRole.rawValue : widget.name.replacingOccurrences(of: "/", with: "∕")
    }

    /// The tooltip the pointer at its current position would show (at once, without the
    /// delay): the nearest enabled, visible widget from the hovered one up that has one.
    public var tooltipUnderPointer: String? {
        var node = capturedWidget ?? hoveredWidget
        while let current = node {
            if current.isEffectivelyEnabled, current.isEffectivelyVisible,
               let text = current.tooltip(at: pointerPosition), !text.isEmpty {
                return text
            }
            node = current.parent
        }
        return nil
    }

    // MARK: Synthetic input

    /// Clicks (`count` presses and releases, 2 for a double click) at `point` in window points,
    /// holding `modifiers`, through the same event path real input takes.
    public func synthesizeClick(at point: Vec2, button: MouseButton = .left, count: Int = 1, modifiers: KeyModifiers = []) {
        withModifiers(modifiers) {
            layoutIfNeeded()
            resetClickCount()
            pointerMoved(to: point)
            for _ in 0..<max(count, 1) {
                pointerButton(button, down: true)
                layoutIfNeeded()
                pointerButton(button, down: false)
                layoutIfNeeded()
            }
        }
    }

    /// Presses at `start`, moves to `end` in `steps` moves and releases there.
    public func synthesizeDrag(from start: Vec2, to end: Vec2, steps: Int = 8, button: MouseButton = .left,
                               modifiers: KeyModifiers = []) {
        withModifiers(modifiers) {
            layoutIfNeeded()
            resetClickCount()
            pointerMoved(to: start)
            pointerButton(button, down: true)
            layoutIfNeeded()
            let count = max(steps, 1)
            for step in 1...count {
                let t = Float(step) / Float(count)
                pointerMoved(to: start + (end - start) * t)
                layoutIfNeeded()
            }
            pointerButton(button, down: false)
            layoutIfNeeded()
        }
    }

    /// Scrolls by `delta` (wheel units, as `Input.scrollDelta`) with the pointer at `point`.
    public func synthesizeScroll(at point: Vec2, by delta: Vec2) {
        layoutIfNeeded()
        pointerMoved(to: point)
        scrolled(by: delta)
        layoutIfNeeded()
    }

    /// Moves the pointer to `point` and returns the tooltip that would show there.
    public func synthesizeHover(at point: Vec2) -> String? {
        layoutIfNeeded()
        pointerMoved(to: point)
        layoutIfNeeded()
        return tooltipUnderPointer
    }

    /// A key press for the focused widget (or the topmost overlay), as `keyPressed`.
    public func synthesizeKey(_ key: KeyEvent) {
        layoutIfNeeded()
        withModifiers(key.modifiers) { keyPressed(key) }
        layoutIfNeeded()
    }

    /// Typed text for the focused widget, as `textEntered`.
    public func synthesizeText(_ text: String) {
        layoutIfNeeded()
        textEntered(text)
        layoutIfNeeded()
    }

    private func withModifiers(_ held: KeyModifiers, _ body: () -> Void) {
        let before = modifiers
        setModifiers(held)
        body()
        setModifiers(before)
    }
}
