import Engine
import Foundation

// The editor's UI as tools: see it as an accessibility tree and drive it with clicks, typing,
// keys, drags and scrolls, through the same `UIContext` event path real input takes (see
// UIAccessibility.swift in the engine). It is the fallback that keeps AI clients at parity
// with the user for UI that has no command yet (a new panel, a plugin) and makes UI tests
// possible. The panel tools open, close, focus and dock the dock's panels.
//
// ```text
// ui.snapshot                          → elements: path, role, label, value, rect, command…
// ui.click {label: "Create"}           → the Create menu opens; "opened" lists its items
// ui.click {path: "menu/item:Cube"}    → a cube is created (entity.create, an "AI: " undo step)
// ui.type {label: "Position X", text: "2", submit: true}
// ui.key {keys: ["mod+z"]}             → the shortcut runs edit.undo
// ui.drag {from: {label: "Crate"}, to: {label: "Floor", role: "treeItem"}}
// ```
//
// Elements are named by `path` (stable while the tree is), or found by `label` (exact,
// case-insensitive, else the only one containing it; `role` and `index` narrow it), or a
// `point` in window points. Each action first brings the panels up to date with the session
// (as a frame would), reveals a scrolled-out element, refuses disabled ones (with why their
// command is unavailable), acts, and updates the panels again, so the next snapshot shows the
// result. Every widget reports the command it runs (`command`), so an agent learns the tool
// to call next time. Points on the 3D viewport (which lets the pointer through to the scene)
// go to the viewport's own input handling (`ViewportController`): a click there picks like
// the user's. Native file dialogs never open while an AI drives the UI (Import… shows its
// path field).
//
// The tools need the editor's UI: the window, or `Editor --headless` (which builds the panels
// without a GPU at 1440x900 points). Plain sessions (tests without an `EditorApp`) don't have it.

/// The UI and panel tools.
@MainActor
public enum EditorUICommands {
    public static let all: [any EditorCommand.Type] = [
        UISnapshotCommand.self, UIFindCommand.self, UIClickCommand.self, UITypeCommand.self, UIKeyCommand.self,
        UIDragCommand.self, UIScrollCommand.self, UIHoverCommand.self,
        PanelListCommand.self, PanelOpenCommand.self, PanelCloseCommand.self, PanelFocusCommand.self, PanelDockCommand.self,
    ]
}

extension EditorSession {
    /// The app showing the editor's panels, if there is one (a window, or `setupWithoutWindow`).
    var uiApp: EditorApp? {
        guard let app = host as? EditorApp, app.ui != nil else { return nil }
        return app
    }
}

private let noUIReason = "the editor's UI isn't running (start the editor with a window, or Editor --headless)"

// MARK: Shared types

/// An element to act on: a path from `ui.snapshot`, a label, or a point.
public struct UITarget: Codable, Equatable, Sendable {
    /// The element's path from ui.snapshot ("editorRoot/toolbar/save", "menu/item:Cube").
    public var path: String?
    /// Its label: exact (ignoring case), else the only element whose label contains it.
    public var label: String?
    /// Narrows `label` to one role ("button", "treeItem", "textField"…).
    public var role: UIAccessibilityRole?
    /// Which match, when `label` matches several (0-based, in snapshot order).
    public var index: Int?
    /// A point in window points [x, y] instead of an element.
    public var point: Vec2?

    public init(path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil, index: Int? = nil, point: Vec2? = nil) {
        self.path = path
        self.label = label
        self.role = role
        self.index = index
        self.point = point
    }

    var isEmpty: Bool { path == nil && label == nil && point == nil }
}

/// One element of the UI (see `UIAccessibilityElement`).
public struct UIElement: Codable, Equatable, Sendable {
    public var path: String
    /// Nesting below the snapshot's top (elements left out of a compact snapshot don't count).
    public var depth: Int
    public var role: UIAccessibilityRole
    public var label: String?
    public var value: String?
    /// [x, y, width, height] in window points.
    public var rect: [Float]
    /// Present (false) only when disabled.
    public var enabled: Bool?
    /// Present (true) only when set.
    public var focused: Bool?
    public var selected: Bool?
    public var hovered: Bool?
    /// Scrolled out of view or clipped (actions scroll it into view first).
    public var offscreen: Bool?
    public var tooltip: String?
    /// The command it runs: the tool to call instead of clicking.
    public var command: String?

    @MainActor init(_ element: UIAccessibilityElement, depth: Int) {
        path = element.path
        self.depth = depth
        role = element.role
        label = element.label
        value = element.value
        rect = [element.frame.x, element.frame.y, element.frame.width, element.frame.height].map { ($0 * 10).rounded() / 10 }
        enabled = element.isEnabled ? nil : false
        focused = element.isFocused ? true : nil
        selected = element.isSelected ? true : nil
        hovered = element.isHovered ? true : nil
        offscreen = element.isOnScreen ? nil : true
        tooltip = element.tooltip == element.label ? nil : element.tooltip
        command = element.command
    }
}

/// What a UI action did.
public struct UIActionResult: Codable, Equatable, Sendable {
    /// The element acted on (nil for a bare point).
    public var target: UIElement?
    /// Where, in window points.
    public var point: Vec2
    /// The 3D viewport took the pointer (picking, gizmos, the camera).
    public var viewport: Bool?
    /// The focused element afterwards.
    public var focused: String?
    /// A popup or dialog the action opened, with its items (click one by path next).
    public var opened: [UIElement]?
    /// The tooltip at the point (ui.hover).
    public var tooltip: String?
}

/// The modifier names tools accept: shift, ctrl / control, alt / option, cmd / command / super,
/// and mod (Cmd on macOS, Ctrl elsewhere: the editor's shortcut key).
enum UIKeyParsing {
    static func modifiers(_ names: [String]) throws -> KeyModifiers {
        var result: KeyModifiers = []
        for name in names { result.insert(try modifier(name)) }
        return result
    }

    static func modifier(_ name: String) throws -> KeyModifiers {
        switch name.lowercased() {
        case "shift": .shift
        case "ctrl", "control": .control
        case "alt", "option", "opt": .alt
        case "cmd", "command", "super", "meta", "win": .command
        case "mod", "shortcut", "primary": .shortcut
        default: throw CommandError.failed("Unknown modifier '\(name)' (shift, ctrl, alt, cmd or mod)")
        }
    }

    /// "mod+shift+z", "enter", "f2", "1" → a key press.
    static func chord(_ text: String) throws -> KeyEvent {
        var parts = text.split(separator: "+", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        if text.hasSuffix("+") { parts = parts.dropLast(2) + ["+"] }  // "shift++"
        guard let keyName = parts.popLast(), !keyName.isEmpty else { throw CommandError.failed("Empty key '\(text)'") }
        return KeyEvent(key: try key(keyName), modifiers: try modifiers(parts))
    }

    static func key(_ name: String) throws -> Key {
        let lower = name.lowercased()
        let aliases: [String: Key] = [
            "return": .enter, "esc": .escape, "del": .delete, "forwarddelete": .delete, "bksp": .backspace,
            "pgup": .pageUp, "pageup": .pageUp, "pgdn": .pageDown, "pagedown": .pageDown, "arrowleft": .left,
            "arrowright": .right, "arrowup": .up, "arrowdown": .down, "`": .grave, "[": .leftBracket, "]": .rightBracket,
            " ": .space,
        ]
        if let key = aliases[lower] { return key }
        if lower.count == 1, let digit = lower.first?.wholeNumberValue, let key = Key(rawValue: "num\(digit)") { return key }
        if let key = Key.allCases.first(where: { $0.rawValue.lowercased() == lower }) { return key }
        throw CommandError.failed("Unknown key '\(name)' (letters, digits, enter, escape, tab, space, backspace, delete, arrows, f1…f12, home, end, pageUp, pageDown)")
    }
}

// MARK: Driving

/// Resolves targets and runs synthetic input against the app's UI.
@MainActor
struct EditorUIDriver {
    let app: EditorApp
    let session: EditorSession
    var ui: UIContext { app.ui }

    init(_ session: EditorSession, _ title: String) throws {
        guard let app = session.uiApp else { throw CommandError.failed("\(title): \(noUIReason)") }
        self.app = app
        self.session = session
    }

    /// The UI's elements, with the panels brought up to date first (as a frame would).
    func elements() -> [UIAccessibilityElement] {
        app.syncPanels()
        return ui.accessibilityElements()
    }

    func fail(_ message: String) -> CommandError {
        session.log.warning(message)
        return CommandError.failed(message)
    }

    /// The element `target` names and the point to act at; reveals a scrolled-out element.
    func resolve(_ target: UITarget, _ title: String, requireEnabled: Bool = true) throws -> (UIAccessibilityElement?, Vec2) {
        if target.path == nil && target.label == nil, let point = target.point {
            let element = elements().last { $0.itemKey == nil && $0.widget === ui.hitTest(point) }
            return (element, point)
        }
        guard var element = try find(target, title) else { throw fail("\(title): give a path, a label or a point") }
        if !element.isOnScreen {
            reveal(element)
            if let again = elements().first(where: { $0.path == element.path }) { element = again }
        }
        if requireEnabled && !element.isEnabled {
            let reason = element.command.flatMap { session.commands.unavailableReason(CommandID($0)) }
            throw fail("\(title): '\(element.label ?? element.path)' is disabled" + (reason.map { " (\($0))" } ?? ""))
        }
        guard element.isOnScreen else {
            throw fail("\(title): '\(element.label ?? element.path)' isn't on screen (a hidden tab or a collapsed panel?)")
        }
        return (element, element.clickPoint)
    }

    private func find(_ target: UITarget, _ title: String) throws -> UIAccessibilityElement? {
        let all = elements()
        if let path = target.path {
            if let element = all.first(where: { $0.path == path }) { return element }
            let last = path.split(separator: "/").last.map(String.init) ?? path
            let similar = all.filter { $0.path.hasSuffix("/" + last) || $0.path == last }.prefix(5).map(\.path)
            throw fail("\(title): no element at '\(path)'" + (similar.isEmpty ? " (run ui.snapshot for paths)" : "; did you mean \(similar.joined(separator: ", "))?"))
        }
        guard let label = target.label?.lowercased() else { return nil }
        var candidates = all.filter { ($0.label?.lowercased() == label) && (target.role == nil || $0.role == target.role) }
        if candidates.isEmpty {
            candidates = all.filter { ($0.label?.lowercased().contains(label) ?? false) && (target.role == nil || $0.role == target.role) }
        }
        if target.role == nil, candidates.contains(where: { $0.role.isInteractive }) {
            candidates = candidates.filter { $0.role.isInteractive }
        }
        if candidates.count > 1, target.index == nil {
            let visible = candidates.filter { $0.isOnScreen && $0.isEnabled }
            if visible.count == 1 { return visible[0] }
        }
        guard !candidates.isEmpty else {
            throw fail("\(title): nothing labeled '\(target.label!)'" + (target.role.map { " with role \($0.rawValue)" } ?? "")
                + " (run ui.snapshot or ui.find)")
        }
        if let index = target.index {
            guard candidates.indices.contains(index) else {
                throw fail("\(title): only \(candidates.count) element(s) match '\(target.label!)'")
            }
            return candidates[index]
        }
        guard candidates.count == 1 else {
            let options = candidates.prefix(8).map { "\($0.path) (\($0.role.rawValue))" }.joined(separator: ", ")
            throw fail("\(title): \(candidates.count) elements match '\(target.label!)': \(options); pass `path`, `role` or `index`")
        }
        return candidates[0]
    }

    /// Scrolls `element` into view: its scroll views, or a list's row.
    private func reveal(_ element: UIAccessibilityElement) {
        guard let key = element.itemKey else {
            ui.reveal(element.widget)
            return
        }
        if let list = element.widget as? RowListView, key.hasPrefix("row:") {
            let rows = elements().filter { $0.parentPath == element.parentPath && $0.itemKey?.hasPrefix("row:") == true }
            if let row = rows.firstIndex(where: { $0.path == element.path }) { list.revealRow(row) }
        }
        // A menu cut short by the window scrolls its items.
        if let menu = element.widget as? PopupMenu { _ = menu.scrollToReveal(element.frame) }
        ui.reveal(element.widget)
    }

    /// Runs `body` (synthetic input), then updates the panels and reports what changed.
    func act(_ element: UIAccessibilityElement?, at point: Vec2, viewport: Bool = false, _ body: () throws -> Void) rethrows -> UIActionResult {
        let overlaysBefore = ui.overlays.map(ObjectIdentifier.init)
        let suppressed = FilePicker.isSuppressed
        FilePicker.isSuppressed = true
        defer { FilePicker.isSuppressed = suppressed }
        try body()
        let after = elements()
        var result = UIActionResult(target: element.map { UIElement($0, depth: 0) }, point: point)
        result.viewport = viewport ? true : nil
        result.focused = after.first { $0.isFocused }?.path
        if let top = ui.overlays.last, !overlaysBefore.contains(ObjectIdentifier(top)),
           let root = after.first(where: { $0.widget === top && $0.itemKey == nil }) {
            result.opened = after.filter { $0.path == root.path || $0.path.hasPrefix(root.path + "/") }
                .filter { $0.role != .group || $0.label != nil }
                .map { UIElement($0, depth: $0.depth - root.depth) }
        }
        return result
    }

    func click(_ target: UITarget, button: MouseButton, count: Int, modifiers: KeyModifiers, _ title: String) throws -> UIActionResult {
        var (element, point) = try resolve(target, title)
        // A toolbar button in the More menu: open the menu, then click its entry.
        if let found = element, let row = found.widget as? ToolbarRow, let key = found.itemKey, key.hasPrefix("overflow:"),
           let name = key.split(separator: ":", maxSplits: 1).last,
           let index = row.overflowed.firstIndex(where: { $0.name == name }), let menu = row.showOverflowMenu() {
            ui.layoutIfNeeded()
            let items = elements().filter { $0.widget === menu && $0.role == .menuItem }
            guard items.indices.contains(index) else { throw fail("\(title): the More menu didn't open") }
            if !items[index].isOnScreen { _ = menu.scrollToReveal(items[index].frame) }
            element = elements().first { $0.path == items[index].path } ?? items[index]
            point = element!.clickPoint
        }
        if app.isViewportPoint(point) {
            return try act(element, at: point, viewport: true) {
                var frames: [EditorApp.ViewportFrame] = []
                for _ in 0..<max(count, 1) {
                    frames.append(.init(position: point, pressed: [button], down: [button]))
                    frames.append(.init(position: point, released: [button]))
                }
                try app.viewportPointer(frames, modifiers: modifiers)
            }
        }
        return act(element, at: point) {
            ui.synthesizeClick(at: point, button: button, count: count, modifiers: modifiers)
        }
    }
}

// MARK: Snapshot

public enum UISnapshotCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only this element and what is inside it (a path from an earlier snapshot, e.g. a panel).
        public var root: String?
        /// Levels below the top (or `root`) to include.
        public var maxDepth: Int?
        /// Also unlabeled groups, separators and spacers (a compact snapshot leaves them out).
        public var all: Bool?
        public init(root: String? = nil, maxDepth: Int? = nil, all: Bool? = nil) {
            self.root = root
            self.maxDepth = maxDepth
            self.all = all
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The window (the UI's viewport) [width, height] in points.
        public var window: [Float]
        public var focused: String?
        public var hovered: String?
        /// Paths of open popups and dialogs (topmost last): they take the pointer and the keys.
        public var overlays: [String]
        /// Depth first; `path` says where each element is.
        public var elements: [UIElement]
    }

    public static let id: CommandID = "ui.snapshot"
    public static let title = "UI Snapshot"
    public static let doc = "The editor's widget tree as an accessibility snapshot: each element's path, role (button, textField, numberField, dropdown, treeItem, tab, menuItem…), label, value, rect [x, y, w, h] in window points, state (disabled, focused, selected, offscreen), tooltip and the command it runs. Tree rows, tabs, menu items and asset cells are elements too. Act on elements with ui.click, ui.type, ui.key, ui.drag, ui.scroll and ui.hover by path or label; prefer the command when an element names one. `root` limits it to a subtree (a panel: \"editorRoot/dock/…\"), `maxDepth` to levels; `all` keeps unlabeled groups."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let driver = try EditorUIDriver(session, title)
        let all = driver.elements()
        if let root = arguments.root, !all.contains(where: { $0.path == root }) {
            throw driver.fail("\(title): no element at '\(root)'")
        }
        let elements = Self.compact(all, root: arguments.root, maxDepth: arguments.maxDepth, keepAll: arguments.all ?? false)
        let ui = driver.ui
        return Result(window: [ui.viewport.width, ui.viewport.height], focused: all.first { $0.isFocused }?.path,
                      hovered: all.last { $0.isHovered }?.path,
                      overlays: ui.overlays.compactMap { overlay in all.first { $0.widget === overlay && $0.itemKey == nil }?.path },
                      elements: elements)
    }

    /// The elements under `root`, without unlabeled plain groups and separators unless
    /// `keepAll`; depths count only the elements kept.
    @MainActor static func compact(_ all: [UIAccessibilityElement], root: String?, maxDepth: Int?, keepAll: Bool) -> [UIElement] {
        var keptDepth: [String: Int] = [:]
        var result: [UIElement] = []
        for element in all {
            if let root, element.path != root, !element.path.hasPrefix(root + "/") { continue }
            let parentDepth = element.parentPath.flatMap { path in Self.nearestKept(path, in: keptDepth) }
            let keep = keepAll || element.path == root || Self.isWorthShowing(element)
            guard keep else { continue }
            let depth = parentDepth.map { $0 + 1 } ?? 0
            if let maxDepth, depth > maxDepth { continue }
            keptDepth[element.path] = depth
            result.append(UIElement(element, depth: depth))
        }
        return result
    }

    private static func nearestKept(_ path: String, in kept: [String: Int]) -> Int? {
        var current = Substring(path)
        while true {
            if let depth = kept[String(current)] { return depth }
            guard let slash = current.lastIndex(of: "/") else { return nil }
            current = current[..<slash]
        }
    }

    @MainActor private static func isWorthShowing(_ element: UIAccessibilityElement) -> Bool {
        switch element.role {
        case .separator: return false
        case .group, .scrollView, .splitView:
            // Named containers (panels, toolbars) structure the tree; anonymous stacks don't.
            return element.command != element.widget.parent?.effectiveCommand
                || !(element.widget.name.isEmpty || element.widget.name == "separator")
        default:
            return true
        }
    }
}

public enum UIFindCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Elements whose label contains this (ignoring case).
        public var label: String?
        public var role: UIAccessibilityRole?
        /// Elements that run this command ("entity.create").
        public var command: String?
        /// Only inside this path.
        public var root: String?
        public init(label: String? = nil, role: UIAccessibilityRole? = nil, command: String? = nil, root: String? = nil) {
            self.label = label
            self.role = role
            self.command = command
            self.root = root
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var elements: [UIElement]
    }

    public static let id: CommandID = "ui.find"
    public static let title = "Find UI Elements"
    public static let doc = "UI elements whose label contains `label` (ignoring case), with `role`, running `command` and/or inside `root`, as ui.snapshot lists them (paths to act on)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let driver = try EditorUIDriver(session, title)
        let label = arguments.label?.lowercased()
        let matches = driver.elements().filter { element in
            (label.map { element.label?.lowercased().contains($0) ?? false } ?? true)
                && (arguments.role.map { element.role == $0 } ?? true)
                && (arguments.command.map { element.command == $0 } ?? true)
                && (arguments.root.map { element.path == $0 || element.path.hasPrefix($0 + "/") } ?? true)
        }
        return Result(elements: matches.prefix(200).map { UIElement($0, depth: 0) })
    }
}

// MARK: Pointer

public enum UIClickCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String?
        public var label: String?
        public var role: UIAccessibilityRole?
        public var index: Int?
        public var point: Vec2?
        /// left (default), right (context menus) or middle.
        public var button: MouseButton?
        /// 2 for a double click.
        public var count: Int?
        /// Held while clicking: shift, ctrl, alt, cmd, mod (Cmd on macOS, Ctrl elsewhere).
        public var modifiers: [String]?

        public init(path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil, index: Int? = nil,
                    point: Vec2? = nil, button: MouseButton? = nil, count: Int? = nil, modifiers: [String]? = nil) {
            self.path = path
            self.label = label
            self.role = role
            self.index = index
            self.point = point
            self.button = button
            self.count = count
            self.modifiers = modifiers
        }

        var target: UITarget { UITarget(path: path, label: label, role: role, index: index, point: point) }
    }

    public static let id: CommandID = "ui.click"
    public static let title = "Click"
    public static let doc = "Clicks a UI element (by `path`, `label` with optional `role` / `index`, or a `point`) as the user would: `button` right opens context menus, `count` 2 double-clicks (rename a tree row, open a folder), `modifiers` [\"shift\"] / [\"mod\"] extend selections. Returns the element, the focused element and any popup it opened with its items. A point on the 3D viewport picks like a click there."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        return try driver.click(arguments.target, button: arguments.button ?? .left, count: min(max(arguments.count ?? 1, 1), 3),
                                modifiers: try UIKeyParsing.modifiers(arguments.modifiers ?? []), title)
    }
}

public enum UIDragCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var from: UITarget
        public var to: UITarget
        /// Pointer moves between press and release (default 12).
        public var steps: Int?
        public var button: MouseButton?
        public var modifiers: [String]?
        public init(from: UITarget, to: UITarget, steps: Int? = nil, button: MouseButton? = nil, modifiers: [String]? = nil) {
            self.from = from
            self.to = to
            self.steps = steps
            self.button = button
            self.modifiers = modifiers
        }
    }

    public static let id: CommandID = "ui.drag"
    public static let title = "Drag"
    public static let doc = "Drags from one UI element or point to another: press at `from`, move in `steps`, release at `to`. Reorders and reparents hierarchy rows, moves assets onto folders, drops assets into the viewport, the hierarchy or inspector fields, moves dock tabs, scrubs number fields and drags gizmos in the viewport."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        let (element, start) = try driver.resolve(arguments.from, title)
        let (_, end) = try driver.resolve(arguments.to, title, requireEnabled: false)
        let button = arguments.button ?? .left
        let modifiers = try UIKeyParsing.modifiers(arguments.modifiers ?? [])
        let steps = min(max(arguments.steps ?? 12, 1), 200)
        let app = driver.app
        if app.isViewportPoint(start) {
            return try driver.act(element, at: start, viewport: true) {
                var frames: [EditorApp.ViewportFrame] = [.init(position: start, pressed: [button], down: [button])]
                for step in 1...steps {
                    frames.append(.init(position: start + (end - start) * (Float(step) / Float(steps)), down: [button]))
                }
                frames.append(.init(position: end, released: [button]))
                try app.viewportPointer(frames, modifiers: modifiers)
            }
        }
        return driver.act(element, at: start) {
            driver.ui.synthesizeDrag(from: start, to: end, steps: steps, button: button, modifiers: modifiers)
        }
    }
}

public enum UIScrollCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String?
        public var label: String?
        public var role: UIAccessibilityRole?
        public var index: Int?
        public var point: Vec2?
        /// Wheel units, as the mouse wheel reports them: positive dy scrolls up / zooms in.
        public var dx: Float?
        public var dy: Float?
        public init(path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil, index: Int? = nil,
                    point: Vec2? = nil, dx: Float? = nil, dy: Float? = nil) {
            self.path = path
            self.label = label
            self.role = role
            self.index = index
            self.point = point
            self.dx = dx
            self.dy = dy
        }
    }

    public static let id: CommandID = "ui.scroll"
    public static let title = "Scroll"
    public static let doc = "Scrolls with the pointer over a UI element or point by `dx` / `dy` wheel units (negative dy scrolls a list down; over the viewport it zooms)."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        let target = UITarget(path: arguments.path, label: arguments.label, role: arguments.role, index: arguments.index,
                              point: arguments.point)
        let (element, point) = try driver.resolve(target, title, requireEnabled: false)
        let delta = Vec2(arguments.dx ?? 0, arguments.dy ?? 0)
        if driver.app.isViewportPoint(point) {
            return try driver.act(element, at: point, viewport: true) {
                try driver.app.viewportPointer([.init(position: point, scroll: delta)], modifiers: [])
            }
        }
        return driver.act(element, at: point) { driver.ui.synthesizeScroll(at: point, by: delta) }
    }
}

public enum UIHoverCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var path: String?
        public var label: String?
        public var role: UIAccessibilityRole?
        public var index: Int?
        public var point: Vec2?
        public init(path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil, index: Int? = nil, point: Vec2? = nil) {
            self.path = path
            self.label = label
            self.role = role
            self.index = index
            self.point = point
        }
    }

    public static let id: CommandID = "ui.hover"
    public static let title = "Hover"
    public static let doc = "Moves the pointer over a UI element or point and returns the tooltip shown there (without waiting for the delay)."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        let target = UITarget(path: arguments.path, label: arguments.label, role: arguments.role, index: arguments.index,
                              point: arguments.point)
        let (element, point) = try driver.resolve(target, title, requireEnabled: false)
        var tooltip: String?
        var result = driver.act(element, at: point) { tooltip = driver.ui.synthesizeHover(at: point) }
        result.tooltip = tooltip
        return result
    }
}

// MARK: Keyboard

public enum UITypeCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The field to type into (clicked first); default: the focused one.
        public var path: String?
        public var label: String?
        public var role: UIAccessibilityRole?
        public var index: Int?
        public var text: String
        /// Select the field's text first, so `text` replaces it (default true when a field is given).
        public var replace: Bool?
        /// Press Enter afterwards (commits number fields, renames, path fields).
        public var submit: Bool?
        public init(path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil, index: Int? = nil,
                    text: String, replace: Bool? = nil, submit: Bool? = nil) {
            self.path = path
            self.label = label
            self.role = role
            self.index = index
            self.text = text
            self.replace = replace
            self.submit = submit
        }
    }

    public static let id: CommandID = "ui.type"
    public static let title = "Type"
    public static let doc = "Types `text` into a text or number field (clicked first when given by `path` / `label`; else the focused one). `replace` (default true with a field) selects its text first; `submit` presses Enter afterwards, which commits a number field, a rename or a path field."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        let target = UITarget(path: arguments.path, label: arguments.label, role: arguments.role, index: arguments.index)
        let ui = driver.ui
        var element: UIAccessibilityElement?
        var point = ui.pointerPosition
        if !target.isEmpty {
            (element, point) = try driver.resolve(target, title)
            // A number field starts typing on a click (its text all selected); a text field takes focus.
            if !(ui.focusedWidget.map { $0 === element?.widget || $0.isDescendant(of: element!.widget) } ?? false) {
                ui.synthesizeClick(at: point)
            }
        }
        guard let focused = ui.focusedWidget, focused.wantsTextInput else {
            throw driver.fail("\(title): nothing that takes text has focus (give the field's path or label)")
        }
        return driver.act(element, at: point) {
            if arguments.replace ?? !target.isEmpty, let field = focused as? TextField {
                field.select(0..<field.buffer.count)
            }
            ui.synthesizeText(arguments.text)
            if arguments.submit == true { driver.app.pressKey(KeyEvent(key: .enter)) }
        }
    }
}

public enum UIKeyCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Key presses in order: "enter", "escape", "tab", "f2", "delete", "mod+z" (Cmd on macOS,
        /// Ctrl elsewhere), "shift+mod+z", "ctrl+y", "down"…
        public var keys: [String]
        /// Click this element first (to focus it).
        public var path: String?
        public var label: String?
        public var role: UIAccessibilityRole?
        public init(keys: [String], path: String? = nil, label: String? = nil, role: UIAccessibilityRole? = nil) {
            self.keys = keys
            self.path = path
            self.label = label
            self.role = role
        }
    }

    public static let id: CommandID = "ui.key"
    public static let title = "Press Keys"
    public static let doc = "Presses keys as the user would: the focused widget or open popup gets each first, then the editor's shortcuts (\"mod+z\" undo, \"mod+s\" save, \"mod+d\" duplicate, \"delete\" (asks first), \"f\" frame, \"escape\"…; mod is Cmd on macOS, Ctrl elsewhere). Optionally clicks an element first to focus it."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIActionResult {
        let driver = try EditorUIDriver(session, title)
        let events = try arguments.keys.map(UIKeyParsing.chord)
        let target = UITarget(path: arguments.path, label: arguments.label, role: arguments.role)
        var element: UIAccessibilityElement?
        var point = driver.ui.pointerPosition
        if !target.isEmpty {
            (element, point) = try driver.resolve(target, title)
            driver.ui.synthesizeClick(at: point)
        }
        return driver.act(element, at: point) {
            for event in events { driver.app.pressKey(event) }
        }
    }
}

// MARK: Panels

/// A dock panel as `panel.list` reports it.
public struct PanelInfo: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var open: Bool
    /// Its tab is the selected one of its group (its content is on screen).
    public var selected: Bool
    public var floating: Bool
    public var closable: Bool
    /// [x, y, width, height] of its content in window points, when on screen.
    public var rect: [Float]?
}

public enum PanelListCommand: EditorCommand {
    public struct Result: Codable, Equatable, Sendable {
        public var panels: [PanelInfo]
    }

    public static let id: CommandID = "panel.list"
    public static let title = "Panels"
    public static let doc = "The editor's dock panels (viewport, hierarchy, inspector, assets, console, activity, stats): open, selected (its tab in front), floating, closable and the content's rect."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: NoArguments, in session: EditorSession) throws -> Result {
        let app = try EditorUIDriver(session, title).app
        app.ui.layoutIfNeeded()
        let dock = app.dock
        let layout = dock.layout
        let ids = EditorLayout.panelIDs + dock.panels.keys.filter { !EditorLayout.panelIDs.contains($0) }.sorted()
        return Result(panels: ids.compactMap { id in
            guard let panel = dock.panel(id) else { return nil }
            let open = dock.isOpen(id)
            let selected = open && EditorLayout.activePanel(in: layout, groupOf: id) == id
            let frame = panel.content.frame
            return PanelInfo(id: id, title: panel.title, open: open, selected: selected,
                             floating: layout.floating.contains { $0.panels.contains(id) }, closable: panel.isClosable,
                             rect: selected && !panel.content.isHidden ? [frame.x, frame.y, frame.width, frame.height] : nil)
        })
    }
}

/// Where `panel.open` / `panel.dock` put a panel.
public struct PanelPlacement: Codable, Equatable, Sendable {
    /// As a tab beside this panel.
    public var tabWith: String?
    /// In a new group on this side of `beside` (or of the whole dock without `beside`).
    public var edge: DockEdge?
    public var beside: String?
    /// The share of the space it takes (0.05…0.95; default 0.25 at an edge, 0.5 beside a panel).
    public var fraction: Float?
    /// In a floating window [x, y, width, height] (points from the dock's top-left).
    public var floating: [Float]?

    public init(tabWith: String? = nil, edge: DockEdge? = nil, beside: String? = nil, fraction: Float? = nil, floating: [Float]? = nil) {
        self.tabWith = tabWith
        self.edge = edge
        self.beside = beside
        self.fraction = fraction
        self.floating = floating
    }

    var isEmpty: Bool { tabWith == nil && edge == nil && beside == nil && floating == nil }

    /// The dock position, checking the panels it names exist.
    @MainActor func position(in dock: DockSpace, _ title: String, session: EditorSession) throws -> DockPosition {
        if let floating {
            guard floating.count == 4 else { throw CommandError.failed("\(title): floating needs [x, y, width, height]") }
            return .floating(UIRect(x: floating[0], y: floating[1], width: floating[2], height: floating[3]))
        }
        for id in [tabWith, beside].compactMap({ $0 }) where !dock.isOpen(id) {
            throw CommandError.failed("\(title): panel '\(id)' isn't open")
        }
        if let tabWith { return .tab(with: tabWith) }
        let edge = self.edge ?? .right
        if let beside { return .split(beside: beside, edge: edge, fraction: min(max(fraction ?? 0.5, 0.05), 0.95)) }
        return .edge(edge, fraction: min(max(fraction ?? 0.25, 0.05), 0.95))
    }
}

/// Checks the panel id and returns the app.
@MainActor private func panelApp(_ id: String, _ session: EditorSession, _ title: String) throws -> EditorApp {
    let app = try EditorUIDriver(session, title).app
    guard app.dock.panel(id) != nil else {
        let known = app.dock.panels.keys.sorted().joined(separator: ", ")
        throw CommandError.failed("\(title): no panel '\(id)' (\(known))")
    }
    return app
}

public enum PanelOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The panel id (panel.list).
        public var panel: String
        /// Where, when it is closed (default: where the default layout has it).
        public var placement: PanelPlacement?
        public init(panel: String, placement: PanelPlacement? = nil) {
            self.panel = panel
            self.placement = placement
        }
    }

    public static let id: CommandID = "panel.open"
    public static let title = "Open Panel"
    public static let doc = "Opens a closed panel (where the default layout has it, or at `placement`) and brings it to the front; an open one just comes to the front."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let app = try panelApp(arguments.panel, session, title)
        let dock = app.dock
        if !dock.isOpen(arguments.panel) {
            if let placement = arguments.placement, !placement.isEmpty {
                dock.dock(arguments.panel, at: try placement.position(in: dock, title, session: session))
            } else {
                dock.dock(arguments.panel, at: EditorLayout.defaultPosition(of: arguments.panel, in: dock))
            }
        }
        dock.focusPanel(arguments.panel)
        app.syncPanels()
        return NoResult()
    }
}

public enum PanelCloseCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var panel: String
        public init(panel: String) { self.panel = panel }
    }

    public static let id: CommandID = "panel.close"
    public static let title = "Close Panel"
    public static let doc = "Closes a panel (its tab's close button); panel.open or layout.reset bring it back. The viewport can't be closed."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let app = try panelApp(arguments.panel, session, title)
        guard app.dock.panel(arguments.panel)?.isClosable == true else {
            throw CommandError.failed("\(title): the \(arguments.panel) panel can't be closed")
        }
        app.dock.closePanel(arguments.panel)
        app.syncPanels()
        return NoResult()
    }
}

public enum PanelFocusCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var panel: String
        public init(panel: String) { self.panel = panel }
    }

    public static let id: CommandID = "panel.focus"
    public static let title = "Show Panel"
    public static let doc = "Brings a panel's tab to the front (opening it where the default layout has it when closed), as clicking its tab does."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        try PanelOpenCommand.run(.init(panel: arguments.panel), in: session)
    }
}

public enum PanelDockCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var panel: String
        /// As a tab beside this panel.
        public var tabWith: String?
        /// In a new group on this side of `beside`, or of the whole dock.
        public var edge: DockEdge?
        public var beside: String?
        public var fraction: Float?
        /// In a floating window [x, y, width, height].
        public var floating: [Float]?
        public init(panel: String, tabWith: String? = nil, edge: DockEdge? = nil, beside: String? = nil, fraction: Float? = nil,
                    floating: [Float]? = nil) {
            self.panel = panel
            self.tabWith = tabWith
            self.edge = edge
            self.beside = beside
            self.fraction = fraction
            self.floating = floating
        }
    }

    public static let id: CommandID = "panel.dock"
    public static let title = "Dock Panel"
    public static let doc = "Moves a panel (as dragging its tab does): as a tab with `tabWith`, to an `edge` (left, right, top, bottom) of `beside` or of the whole dock taking `fraction`, or into a `floating` window. The layout is saved; layout.reset restores the default."
    public static func isAvailable(in session: EditorSession) -> Bool { session.uiApp != nil }
    public static func unavailableReason(in session: EditorSession) -> String? { noUIReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> NoResult {
        let app = try panelApp(arguments.panel, session, title)
        let placement = PanelPlacement(tabWith: arguments.tabWith, edge: arguments.edge, beside: arguments.beside,
                                       fraction: arguments.fraction, floating: arguments.floating)
        guard !placement.isEmpty else { throw CommandError.failed("\(title): give tabWith, edge (with beside) or floating") }
        guard placement.tabWith != arguments.panel, placement.beside != arguments.panel else {
            throw CommandError.failed("\(title): a panel can't be docked beside itself")
        }
        app.dock.dock(arguments.panel, at: try placement.position(in: app.dock, title, session: session))
        app.syncPanels()
        return NoResult()
    }
}

extension EditorLayout {
    /// Where a closed panel goes back to: with an open panel of its default tab group, else
    /// the side the default layout has it on.
    @MainActor public static func defaultPosition(of id: String, in dock: DockSpace) -> DockPosition {
        let bottom = [assets, console, activity, stats]
        if bottom.contains(id) {
            if let other = bottom.first(where: { $0 != id && dock.isOpen($0) }) { return .tab(with: other) }
            return dock.isOpen(viewport) ? .split(beside: viewport, edge: .bottom, fraction: 0.36) : .edge(.bottom, fraction: 0.36)
        }
        switch id {
        case hierarchy: return .edge(.left, fraction: 0.19)
        case inspector: return .edge(.right, fraction: 0.24)
        default: return .edge(.right)
        }
    }
}
