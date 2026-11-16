import Foundation
import EngineCore
import EngineScene

// Game menus and HUDs: the contents of a `.ui` file (JSON, every key optional). Widgets are a
// flat list; each names its `parent` ("" is the screen), and siblings keep the list's order.
// The screen and `panel`s place their children by `anchor` + `offset`; `vstack` / `hstack`
// line them up. Game code shows a layout with `UIBuildView` (Engine module), sets values by
// key and listens for button events.
//
// ```json
// {
//   "theme": "game", "colors": {"accent": "#FFAA33"}, "size": [1280, 720],
//   "values": {"health": 72, "score": 1200},
//   "widgets": [
//     {"id": "status", "type": "vstack", "anchor": "topLeft", "spacing": 6},
//     {"id": "health", "type": "bar", "parent": "status", "kind": "health", "bind": "health", "max": 100, "width": 220},
//     {"id": "score", "type": "label", "anchor": "topRight", "text": "Score: {score}", "fontSize": 24, "shadow": true},
//     {"id": "pause", "type": "button", "anchor": "bottomRight", "text": "Pause", "event": "pause"}
//   ]
// }
// ```
//
// Colors are "#RRGGBB[AA]" (sRGB) or a theme color name (`UIBuild.themeColorNames`: "accent",
// "text", "panel", "health"…). Text may hold `{key}` placeholders, filled from the values game
// code sets (and the file's `values` until it does). `bind` ties a widget to one value: a bar's
// fill (value / `max`), a label's or button's whole text, an image's path. `visibleWhen` shows a
// widget only while a value is truthy ("!key": while it is falsy).

/// What a widget is.
public enum UIBuildWidgetType: String, Codable, CaseIterable, Sendable {
    /// A box that places its children by anchor and offset (optionally with a background).
    case panel
    /// Children top to bottom.
    case vstack
    /// Children left to right.
    case hstack
    /// A line (or wrapped paragraph) of text.
    case label
    /// A project image (path under `Assets/`).
    case image
    /// A push button that sends an event.
    case button
    /// A progress / health bar.
    case bar
    /// Empty space that grows in a stack.
    case spacer

    /// Whether children can hang from it.
    public var isContainer: Bool { self == .panel || self == .vstack || self == .hstack }
}

/// Where a widget sits in a panel (or the screen). `fill` stretches it over the parent, `offset` in from every edge.
public enum UIBuildAnchor: String, Codable, CaseIterable, Sendable {
    case topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight, fill
}

/// Where a stack's children sit across it; `auto` is the stack's default (stretch in a vstack, center in an hstack).
public enum UIBuildAlign: String, Codable, CaseIterable, Sendable {
    case auto, start, center, end, stretch
}

/// How a stack spreads its children along itself when they don't fill it.
public enum UIBuildJustify: String, Codable, CaseIterable, Sendable {
    case start, center, end, spaceBetween
}

public enum UIBuildTextAlign: String, Codable, CaseIterable, Sendable {
    case left, center, right
}

/// How an image fills its box.
public enum UIBuildImageFit: String, Codable, CaseIterable, Sendable {
    /// Whole image, aspect kept.
    case fit
    /// Covers the box, aspect kept, cropped.
    case fill
    /// Stretched to the box.
    case stretch
}

/// A bar's colors: the accent, or green → warning → danger as it empties.
public enum UIBuildBarKind: String, Codable, CaseIterable, Sendable {
    case progress, health
}

/// One widget of a `.ui` layout. Fields that don't apply to its type are ignored.
public struct UIBuildWidget: Codable, Equatable, Sendable {
    /// Unique in the layout: bindings, events, edits and `UIBuildView.widget(_:)` use it.
    public var id: String
    public var type: UIBuildWidgetType
    /// The container it hangs from ("" is the screen).
    public var parent: String

    // Placement: inside a panel or the screen (ignored in a stack, which lines children up).
    public var anchor: UIBuildAnchor
    /// Points in from the anchored edges (a centered axis moves by it).
    public var offset: Vec2
    /// Fixed size in points; nil fits the content.
    public var width: Float?
    public var height: Float?
    /// Share of a stack's free space along the stack.
    public var grow: Float

    // Containers.
    public var padding: Float
    /// Gap between a stack's children.
    public var spacing: Float
    public var align: UIBuildAlign
    public var justify: UIBuildJustify

    // Look.
    /// Fill color ("" none; a bar's track).
    public var background: String
    public var borderColor: String
    public var cornerRadius: Float
    public var opacity: Float
    public var hidden: Bool

    // Text: label, button, bar.
    /// May hold `{key}` placeholders.
    public var text: String
    /// Points (0: the theme's size).
    public var fontSize: Float
    /// Text color (label, button), fill (bar), tint (image).
    public var color: String
    public var textAlign: UIBuildTextAlign
    /// Wrap a label to its width.
    public var wrap: Bool
    /// Soft drop shadow under a label (reads over the game).
    public var shadow: Bool

    // Image.
    /// Path under `Assets/` ("UI/heart.png") or "asset:<id>".
    public var image: String
    public var fit: UIBuildImageFit

    // Bar.
    /// The fill shown without a binding (0...max).
    public var value: Float
    /// The value that fills the bar.
    public var max: Float
    public var kind: UIBuildBarKind
    /// Tick marks dividing the bar into this many parts.
    public var segments: Int
    /// Show recently lost value as a draining trail.
    public var trail: Bool

    // Button.
    /// Accent-colored (the main action).
    public var primary: Bool
    /// The event name a press sends ("" sends the id).
    public var event: String

    // Bindings.
    /// The value key this widget shows: a bar's fill, a label's / button's text (unless the text has `{…}` placeholders), an image's path.
    public var bind: String
    /// Shown only while this value is truthy ("!key": while it is falsy); "" always.
    public var visibleWhen: String

    public init(id: String = "", type: UIBuildWidgetType = .panel, parent: String = "", anchor: UIBuildAnchor = .topLeft,
                offset: Vec2 = .zero, width: Float? = nil, height: Float? = nil, grow: Float = 0, padding: Float = 0,
                spacing: Float = 8, align: UIBuildAlign = .auto, justify: UIBuildJustify = .start, background: String = "",
                borderColor: String = "", cornerRadius: Float = 0, opacity: Float = 1, hidden: Bool = false, text: String = "",
                fontSize: Float = 0, color: String = "", textAlign: UIBuildTextAlign = .left, wrap: Bool = false,
                shadow: Bool = false, image: String = "", fit: UIBuildImageFit = .fit, value: Float = 1, max: Float = 1,
                kind: UIBuildBarKind = .progress, segments: Int = 0, trail: Bool = false, primary: Bool = false,
                event: String = "", bind: String = "", visibleWhen: String = "") {
        self.id = id
        self.type = type
        self.parent = parent
        self.anchor = anchor
        self.offset = offset
        self.width = width
        self.height = height
        self.grow = grow
        self.padding = padding
        self.spacing = spacing
        self.align = align
        self.justify = justify
        self.background = background
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.hidden = hidden
        self.text = text
        self.fontSize = fontSize
        self.color = color
        self.textAlign = textAlign
        self.wrap = wrap
        self.shadow = shadow
        self.image = image
        self.fit = fit
        self.value = value
        self.max = max
        self.kind = kind
        self.segments = segments
        self.trail = trail
        self.primary = primary
        self.event = event
        self.bind = bind
        self.visibleWhen = visibleWhen
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id, type, parent, anchor, offset, width, height, grow, padding, spacing, align, justify, background, borderColor,
             cornerRadius, opacity, hidden, text, fontSize, color, textAlign, wrap, shadow, image, fit, value, max, kind, segments,
             trail, primary, event, bind, visibleWhen
    }

    /// Every key is optional.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var w = UIBuildWidget()
        func read<T: Decodable>(_ key: CodingKeys, _ field: inout T) throws {
            if let value = try c.decodeIfPresent(T.self, forKey: key) { field = value }
        }
        try read(.id, &w.id); try read(.type, &w.type); try read(.parent, &w.parent); try read(.anchor, &w.anchor)
        try read(.offset, &w.offset)
        w.width = try c.decodeIfPresent(Float.self, forKey: .width)
        w.height = try c.decodeIfPresent(Float.self, forKey: .height)
        try read(.grow, &w.grow); try read(.padding, &w.padding); try read(.spacing, &w.spacing); try read(.align, &w.align)
        try read(.justify, &w.justify); try read(.background, &w.background); try read(.borderColor, &w.borderColor)
        try read(.cornerRadius, &w.cornerRadius); try read(.opacity, &w.opacity); try read(.hidden, &w.hidden)
        try read(.text, &w.text); try read(.fontSize, &w.fontSize); try read(.color, &w.color); try read(.textAlign, &w.textAlign)
        try read(.wrap, &w.wrap); try read(.shadow, &w.shadow); try read(.image, &w.image); try read(.fit, &w.fit)
        try read(.value, &w.value); try read(.max, &w.max); try read(.kind, &w.kind); try read(.segments, &w.segments)
        try read(.trail, &w.trail); try read(.primary, &w.primary); try read(.event, &w.event); try read(.bind, &w.bind)
        try read(.visibleWhen, &w.visibleWhen)
        self = w
    }

    /// Writes only what differs from the defaults (plus `id` and `type`), so files stay short.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let d = UIBuildWidget()
        func write<T: Encodable & Equatable>(_ key: CodingKeys, _ value: T, _ initial: T) throws {
            if value != initial { try c.encode(value, forKey: key) }
        }
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try write(.parent, parent, d.parent); try write(.anchor, anchor, d.anchor); try write(.offset, offset, d.offset)
        try c.encodeIfPresent(width, forKey: .width); try c.encodeIfPresent(height, forKey: .height)
        try write(.grow, grow, d.grow); try write(.padding, padding, d.padding); try write(.spacing, spacing, d.spacing)
        try write(.align, align, d.align); try write(.justify, justify, d.justify); try write(.background, background, d.background)
        try write(.borderColor, borderColor, d.borderColor); try write(.cornerRadius, cornerRadius, d.cornerRadius)
        try write(.opacity, opacity, d.opacity); try write(.hidden, hidden, d.hidden); try write(.text, text, d.text)
        try write(.fontSize, fontSize, d.fontSize); try write(.color, color, d.color); try write(.textAlign, textAlign, d.textAlign)
        try write(.wrap, wrap, d.wrap); try write(.shadow, shadow, d.shadow); try write(.image, image, d.image)
        try write(.fit, fit, d.fit); try write(.value, value, d.value); try write(.max, max, d.max); try write(.kind, kind, d.kind)
        try write(.segments, segments, d.segments); try write(.trail, trail, d.trail); try write(.primary, primary, d.primary)
        try write(.event, event, d.event); try write(.bind, bind, d.bind); try write(.visibleWhen, visibleWhen, d.visibleWhen)
    }

    /// The event a press of this button sends.
    public var eventName: String { event.isEmpty ? id : event }

    /// The value keys the widget reads: `bind`, `visibleWhen` and the text's `{key}` placeholders.
    public var valueKeys: [String] {
        var keys: [String] = []
        if !bind.isEmpty { keys.append(bind) }
        let visible = visibleWhen.hasPrefix("!") ? String(visibleWhen.dropFirst()) : visibleWhen
        if !visible.isEmpty { keys.append(visible) }
        for key in UIBuild.placeholders(in: text) where !keys.contains(key) { keys.append(key) }
        return keys
    }
}

/// A problem with a layout: what is wrong and, when it is about one widget, which.
public struct UIBuildIssue: Equatable, Sendable, CustomStringConvertible {
    public var widget: String?
    public var message: String

    public init(widget: String? = nil, _ message: String) {
        self.widget = widget
        self.message = message
    }

    public var description: String { widget.map { "\($0): \(message)" } ?? message }
}

public struct UIBuildError: Error, CustomStringConvertible, Equatable, Sendable {
    public var message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// A game menu or HUD: the contents of a `.ui` file.
public struct UIBuild: Codable, Equatable, Sendable {
    /// The base theme: "game" (default), "dark", "light" or "highContrast".
    public var theme: String
    /// Theme colors to change, by name (see `themeColorNames`): "#RRGGBB[AA]".
    public var colors: [String: String]
    /// The theme's body text size in points (0: the theme's).
    public var fontSize: Float
    /// Points the screen's children keep clear of its edges (nil: the theme's HUD safe area).
    public var safeArea: Float?
    /// The screen size the layout is designed at (the editor previews it first), points.
    public var size: Vec2
    /// Sample values by key: shown in the preview, and in the game until code sets the key.
    public var values: [String: JSONValue]
    public var widgets: [UIBuildWidget]

    public init(theme: String = "game", colors: [String: String] = [:], fontSize: Float = 0, safeArea: Float? = nil,
                size: Vec2 = Vec2(1280, 720), values: [String: JSONValue] = [:], widgets: [UIBuildWidget] = []) {
        self.theme = theme
        self.colors = colors
        self.fontSize = fontSize
        self.safeArea = safeArea
        self.size = size
        self.values = values
        self.widgets = widgets
    }

    private enum CodingKeys: String, CodingKey { case theme, colors, fontSize, safeArea, size, values, widgets }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = UIBuild()
        self.init(theme: try c.decodeIfPresent(String.self, forKey: .theme) ?? d.theme,
                  colors: try c.decodeIfPresent([String: String].self, forKey: .colors) ?? [:],
                  fontSize: try c.decodeIfPresent(Float.self, forKey: .fontSize) ?? 0,
                  safeArea: try c.decodeIfPresent(Float.self, forKey: .safeArea),
                  size: try c.decodeIfPresent(Vec2.self, forKey: .size) ?? d.size,
                  values: try c.decodeIfPresent([String: JSONValue].self, forKey: .values) ?? [:],
                  widgets: try c.decodeIfPresent([UIBuildWidget].self, forKey: .widgets) ?? [])
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(theme, forKey: .theme)
        if !colors.isEmpty { try c.encode(colors, forKey: .colors) }
        if fontSize != 0 { try c.encode(fontSize, forKey: .fontSize) }
        try c.encodeIfPresent(safeArea, forKey: .safeArea)
        try c.encode(size, forKey: .size)
        if !values.isEmpty { try c.encode(values, forKey: .values) }
        try c.encode(widgets, forKey: .widgets)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// The base theme names.
    public static let themeNames = ["game", "dark", "light", "highContrast"]

    /// Theme colors a layout can change (in `colors`) and that widget colors can name.
    public static let themeColorNames = [
        "text", "secondaryText", "accent", "accentText", "panel", "panelBorder", "control", "controlHover", "barBackground",
        "health", "warning", "danger", "hudText", "hudShadow",
    ]

    /// A HUD to start from: a health bar and score at the top, a pause button.
    public static var starter: UIBuild {
        UIBuild(values: ["health": .int(72), "maxHealth": .int(100), "score": .int(1200)], widgets: [
            UIBuildWidget(id: "status", type: .vstack, anchor: .topLeft, spacing: 6, align: .start),
            UIBuildWidget(id: "healthLabel", type: .label, parent: "status", text: "Health {health} / {maxHealth}", shadow: true),
            UIBuildWidget(id: "health", type: .bar, parent: "status", width: 240, max: 100, kind: .health, bind: "health"),
            UIBuildWidget(id: "score", type: .label, anchor: .topRight, text: "Score: {score}", fontSize: 26, shadow: true),
            UIBuildWidget(id: "pause", type: .button, anchor: .bottomRight, text: "Pause", event: "pause"),
        ])
    }

    /// A main menu: a title and Play / Options / Quit buttons in a centered panel.
    public static var menu: UIBuild {
        UIBuild(values: ["title": .string("My Game")], widgets: [
            UIBuildWidget(id: "menu", type: .vstack, anchor: .center, width: 320, padding: 24, spacing: 12, background: "panel",
                          cornerRadius: 14),
            UIBuildWidget(id: "title", type: .label, parent: "menu", fontSize: 34, textAlign: .center, bind: "title"),
            UIBuildWidget(id: "play", type: .button, parent: "menu", text: "Play", primary: true, event: "play"),
            UIBuildWidget(id: "options", type: .button, parent: "menu", text: "Options", event: "options"),
            UIBuildWidget(id: "quit", type: .button, parent: "menu", text: "Quit", event: "quit"),
        ])
    }

    /// Layouts to start from by name: "hud" (`starter`), "menu", "dialogue" (DialogueLayout.swift), "empty".
    public static func preset(_ name: String) -> UIBuild? {
        switch name {
        case "hud": starter
        case "menu": menu
        case "dialogue": dialogue
        case "empty": UIBuild()
        default: nil
        }
    }

    public static let presetNames = ["hud", "menu", "dialogue", "empty"]

    // MARK: Lookup

    public func index(of id: String) -> Int? { widgets.firstIndex { $0.id == id } }
    public func widget(_ id: String) -> UIBuildWidget? { index(of: id).map { widgets[$0] } }

    /// The widgets hanging from `parent` ("" the screen), in order.
    public func children(of parent: String) -> [UIBuildWidget] { widgets.filter { $0.parent == parent } }

    /// `id` and everything under it.
    public func subtree(of id: String) -> Set<String> {
        var result: Set<String> = [id]
        var grew = true
        while grew {
            grew = false
            for w in widgets where !result.contains(w.id) && result.contains(w.parent) {
                result.insert(w.id)
                grew = true
            }
        }
        return result
    }

    /// An id not used yet: `base`, else "`base`2", "`base`3"…
    public func uniqueID(_ base: String) -> String {
        let base = base.isEmpty ? "widget" : base
        let ids = Set(widgets.map(\.id))
        guard ids.contains(base) else { return base }
        var n = 2
        while ids.contains("\(base)\(n)") { n += 1 }
        return "\(base)\(n)"
    }

    /// Every value key a widget reads, sorted.
    public var valueKeys: [String] { Array(Set(widgets.flatMap(\.valueKeys))).sorted() }

    /// Every event a button sends, sorted.
    public var events: [String] { Array(Set(widgets.filter { $0.type == .button }.map(\.eventName))).sorted() }

    // MARK: Text

    /// The `{key}` placeholder names in `text`, in order.
    public static func placeholders(in text: String) -> [String] {
        var keys: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{"), let close = rest[open...].firstIndex(of: "}") {
            let key = rest[rest.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
            if !key.isEmpty, !keys.contains(key) { keys.append(key) }
            rest = rest[rest.index(after: close)...]
        }
        return keys
    }

    /// `text` with each `{key}` replaced by its value (missing keys become "").
    public static func fill(_ text: String, values: [String: JSONValue]) -> String {
        guard text.contains("{") else { return text }
        var result = ""
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{"), let close = rest[open...].firstIndex(of: "}") {
            result += rest[..<open]
            let key = rest[rest.index(after: open)..<close].trimmingCharacters(in: .whitespaces)
            result += values[key].map(display) ?? ""
            rest = rest[rest.index(after: close)...]
        }
        return result + rest
    }

    /// A value as text: whole numbers without decimals, others with up to two.
    public static func display(_ value: JSONValue) -> String {
        switch value {
        case .null: return ""
        case .bool(let b): return b ? "true" : "false"
        case .int(let n): return String(n)
        case .double(let d):
            if d.isFinite, d == d.rounded(), abs(d) < 1e15 { return String(Int64(d)) }
            var text = String(format: "%.2f", d)
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
            return text
        case .string(let s): return s
        default: return ""
        }
    }

    /// A value as a number (bools are 0 / 1, numeric text is parsed).
    public static func number(_ value: JSONValue?) -> Double? {
        switch value {
        case .int(let n): return Double(n)
        case .double(let d): return d.isFinite ? d : nil
        case .bool(let b): return b ? 1 : 0
        case .string(let s): return Double(s.trimmingCharacters(in: .whitespaces))
        default: return nil
        }
    }

    /// Whether a value counts as on: true, a non-zero number, non-empty text other than "false" / "0".
    public static func truthy(_ value: JSONValue?) -> Bool {
        switch value {
        case .bool(let b): return b
        case .int(let n): return n != 0
        case .double(let d): return d != 0
        case .string(let s): return !s.isEmpty && s != "false" && s != "0"
        case .array(let a): return !a.isEmpty
        case .object: return true
        default: return false
        }
    }

    /// Whether a widget with `visibleWhen` shows for `values`.
    public static func isVisible(_ visibleWhen: String, values: [String: JSONValue]) -> Bool {
        guard !visibleWhen.isEmpty else { return true }
        if visibleWhen.hasPrefix("!") { return !truthy(values[String(visibleWhen.dropFirst())]) }
        return truthy(values[visibleWhen])
    }

    // MARK: Colors

    /// sRGB RGBA 0...1 of "#RGB", "#RRGGBB" or "#RRGGBBAA"; nil for anything else (theme names included).
    public static func hexColor(_ text: String) -> Vec4? {
        DataTableValues.color(.string(text))
    }

    /// Whether `text` is usable as a color: empty, hex or a theme color name.
    public static func isValidColor(_ text: String) -> Bool {
        text.isEmpty || hexColor(text) != nil || themeColorNames.contains(text)
    }

    // MARK: Validation

    /// Problems with the layout. `imageExists` checks image paths (nil: not checked).
    public func validate(imageExists: ((String) -> Bool)? = nil) -> [UIBuildIssue] {
        var issues: [UIBuildIssue] = []
        if !Self.themeNames.contains(theme) {
            issues.append(UIBuildIssue("unknown theme '\(theme)' (one of \(Self.themeNames.joined(separator: ", "))); using game"))
        }
        for (name, color) in colors.sorted(by: { $0.key < $1.key }) {
            if !Self.themeColorNames.contains(name) { issues.append(UIBuildIssue("colors: unknown theme color '\(name)'")) }
            if Self.hexColor(color) == nil { issues.append(UIBuildIssue("colors.\(name): '\(color)' isn't a #RRGGBB[AA] color")) }
        }
        if size.x < 1 || size.y < 1 { issues.append(UIBuildIssue("size must be positive")) }
        var seen: Set<String> = []
        let types = Dictionary(widgets.map { ($0.id, $0.type) }, uniquingKeysWith: { first, _ in first })
        for w in widgets {
            let name = w.id.isEmpty ? "(no id)" : w.id
            if w.id.isEmpty { issues.append(UIBuildIssue(widget: name, "a widget needs an id")) }
            if !w.id.isEmpty, !seen.insert(w.id).inserted { issues.append(UIBuildIssue(widget: name, "duplicate id (the first one wins)")) }
            if !w.parent.isEmpty {
                if let parentType = types[w.parent] {
                    if !parentType.isContainer {
                        issues.append(UIBuildIssue(widget: name, "parent '\(w.parent)' is a \(parentType.rawValue), which can't hold widgets"))
                    }
                } else {
                    issues.append(UIBuildIssue(widget: name, "no parent '\(w.parent)' (shown on the screen instead)"))
                }
            }
            for (field, color) in [("background", w.background), ("borderColor", w.borderColor), ("color", w.color)]
                where !Self.isValidColor(color) {
                issues.append(UIBuildIssue(widget: name, "\(field) '\(color)' isn't a #RRGGBB[AA] color or theme color name"))
            }
            if w.type == .bar, w.max <= 0 { issues.append(UIBuildIssue(widget: name, "max must be above 0")) }
            if w.type == .image, w.image.isEmpty, w.bind.isEmpty { issues.append(UIBuildIssue(widget: name, "no image set")) }
            if w.type == .image, !w.image.isEmpty, let imageExists, !imageExists(w.image) {
                issues.append(UIBuildIssue(widget: name, "no image asset '\(w.image)'"))
            }
            if let width = w.width, width < 0 { issues.append(UIBuildIssue(widget: name, "width can't be negative")) }
            if let height = w.height, height < 0 { issues.append(UIBuildIssue(widget: name, "height can't be negative")) }
        }
        // Cycles: a parent chain that comes back to the widget.
        for w in widgets where !w.parent.isEmpty {
            var current = w.parent
            var steps = 0
            while !current.isEmpty, steps <= widgets.count, let next = widget(current) {
                if next.id == w.id {
                    issues.append(UIBuildIssue(widget: w.id, "is inside itself (parent cycle); shown on the screen instead"))
                    break
                }
                current = next.parent
                steps += 1
            }
        }
        return issues
    }

    /// The parent a widget is actually shown in: its `parent` when that is a container and the
    /// widget isn't on a parent cycle, else "" (the screen).
    public func effectiveParent(of w: UIBuildWidget) -> String {
        guard !w.parent.isEmpty, let parent = widget(w.parent), parent.type.isContainer else { return "" }
        var current = parent
        var steps = 0
        while !current.parent.isEmpty, steps <= widgets.count, let next = widget(current.parent) {
            if next.id == w.id { return "" }  // on a parent cycle
            current = next
            steps += 1
        }
        return w.parent
    }
}

/// A batch of changes to a layout, applied by `UIBuild.applying` (the `uiLayout.edit` tool and the
/// editor use the same code). Order: removeWidgets, addWidgets, updateWidgets, moveWidgets,
/// bindings, values, then the layout's own fields.
public struct UIBuildEdit: Codable, Equatable, Sendable {
    /// Widget ids to remove (with everything inside them).
    public var removeWidgets: [String]?
    /// Widgets to add, in order (a later one may hang from an earlier one). An empty id gets
    /// one from its type; a taken id gets a number.
    public var addWidgets: [UIBuildWidget]?
    /// Widget id → fields to change, e.g. {"score": {"text": "Points: {score}", "fontSize": 30}}; "id" renames (children follow).
    public var updateWidgets: [String: JSONValue]?
    /// Reparent / reorder: each moves `id` into `parent` ("" the screen) at `index` among its siblings (default: last).
    public var moveWidgets: [UIBuildMove]?
    /// Widget id → the value key it shows ("" removes the binding).
    public var bindings: [String: String]?
    /// Sample values to set by key (null removes one).
    public var values: [String: JSONValue]?
    public var theme: String?
    /// Theme colors to set by name ("" removes one).
    public var colors: [String: String]?
    public var fontSize: Float?
    public var safeArea: Float?
    public var size: Vec2?

    public init(removeWidgets: [String]? = nil, addWidgets: [UIBuildWidget]? = nil, updateWidgets: [String: JSONValue]? = nil,
                moveWidgets: [UIBuildMove]? = nil, bindings: [String: String]? = nil, values: [String: JSONValue]? = nil,
                theme: String? = nil, colors: [String: String]? = nil, fontSize: Float? = nil, safeArea: Float? = nil, size: Vec2? = nil) {
        self.removeWidgets = removeWidgets
        self.addWidgets = addWidgets
        self.updateWidgets = updateWidgets
        self.moveWidgets = moveWidgets
        self.bindings = bindings
        self.values = values
        self.theme = theme
        self.colors = colors
        self.fontSize = fontSize
        self.safeArea = safeArea
        self.size = size
    }
}

/// Moves a widget to another parent and / or position among its siblings.
public struct UIBuildMove: Codable, Equatable, Sendable {
    public var id: String
    /// "" is the screen; nil keeps the current parent.
    public var parent: String?
    /// Position among the new siblings (0 first); nil puts it last.
    public var index: Int?

    public init(id: String, parent: String? = nil, index: Int? = nil) {
        self.id = id
        self.parent = parent
        self.index = index
    }
}

extension UIBuild {
    /// This layout with `edit` applied. Throws when it names a widget that doesn't exist or a
    /// change that can't be made (a parent cycle, a parent that can't hold widgets).
    public func applying(_ edit: UIBuildEdit) throws -> UIBuild {
        var build = self
        if let ids = edit.removeWidgets, !ids.isEmpty {
            let missing = ids.filter { build.index(of: $0) == nil }
            guard missing.isEmpty else { throw UIBuildError("No widget \(missing.joined(separator: ", "))") }
            var doomed: Set<String> = []
            for id in ids { doomed.formUnion(build.subtree(of: id)) }
            build.widgets.removeAll { doomed.contains($0.id) }
        }
        for var widget in edit.addWidgets ?? [] {
            widget.id = build.uniqueID(widget.id.isEmpty ? widget.type.rawValue : widget.id)
            if !widget.parent.isEmpty {
                guard let parent = build.widget(widget.parent) else { throw UIBuildError("\(widget.id): no parent widget '\(widget.parent)'") }
                guard parent.type.isContainer else {
                    throw UIBuildError("\(widget.id): '\(widget.parent)' is a \(parent.type.rawValue), which can't hold widgets")
                }
            }
            build.widgets.append(widget)
        }
        for (id, changes) in (edit.updateWidgets ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard case .object(let fields) = changes else { throw UIBuildError("updateWidgets[\(id)] must be an object of fields") }
            try build.update(id, fields: fields)
        }
        for move in edit.moveWidgets ?? [] {
            try build.move(move.id, to: move.parent, index: move.index)
        }
        for (id, key) in (edit.bindings ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let i = build.index(of: id) else { throw UIBuildError("No widget \(id)") }
            build.widgets[i].bind = key.trimmingCharacters(in: .whitespaces)
        }
        for (key, value) in edit.values ?? [:] {
            build.values[key] = value == .null ? nil : value
        }
        if let theme = edit.theme { build.theme = theme }
        for (name, color) in edit.colors ?? [:] { build.colors[name] = color.isEmpty ? nil : color }
        if let fontSize = edit.fontSize { build.fontSize = Swift.max(fontSize, 0) }
        if let safeArea = edit.safeArea { build.safeArea = safeArea < 0 ? nil : safeArea }
        if let size = edit.size { build.size = Vec2(Swift.max(size.x, 1), Swift.max(size.y, 1)) }
        return build
    }

    /// Changes fields of widget `id` (JSON names as in the file; null resets a field to its default). "id" renames it.
    public mutating func update(_ id: String, fields: [String: JSONValue]) throws {
        guard let index = index(of: id) else { throw UIBuildError("No widget \(id)") }
        let unknown = fields.keys.filter { UIBuildWidget.CodingKeys(rawValue: $0) == nil }.sorted()
        guard unknown.isEmpty else { throw UIBuildError("\(id): unknown field \(unknown.joined(separator: ", "))") }
        guard case .object(var current) = try AssetJSON.value(widgets[index]) else { return }
        for (key, value) in fields { current[key] = value == .null ? nil : value }
        let updated: UIBuildWidget
        do { updated = try AssetJSON.decode(UIBuildWidget.self, from: .object(current)) } catch {
            throw UIBuildError("\(id): \(Self.describe(error))")
        }
        if updated.id != id {
            guard !updated.id.isEmpty, self.index(of: updated.id) == nil else { throw UIBuildError("\(id): the id '\(updated.id)' is empty or taken") }
        }
        if updated.parent != widgets[index].parent {
            try checkParent(updated.parent, for: id)
        }
        widgets[index] = updated
        if updated.id != id {
            for i in widgets.indices where widgets[i].parent == id { widgets[i].parent = updated.id }
        }
    }

    /// Moves widget `id` into `parent` (nil keeps its parent; "" the screen) at `index` among its new siblings (nil: last).
    public mutating func move(_ id: String, to parent: String?, index: Int?) throws {
        guard let from = self.index(of: id) else { throw UIBuildError("No widget \(id)") }
        var widget = widgets[from]
        let target = parent ?? widget.parent
        if target != widget.parent { try checkParent(target, for: id) }
        widget.parent = target
        widgets.remove(at: from)
        let siblings = widgets.indices.filter { widgets[$0].parent == target }
        let position: Int
        if let index, index >= 0, index < siblings.count {
            position = siblings[index]
        } else {
            position = siblings.last.map { $0 + 1 } ?? widgets.count
        }
        widgets.insert(widget, at: position)
    }

    private func checkParent(_ parent: String, for id: String) throws {
        guard !parent.isEmpty else { return }
        guard let target = widget(parent) else { throw UIBuildError("\(id): no parent widget '\(parent)'") }
        guard target.type.isContainer else { throw UIBuildError("\(id): '\(parent)' is a \(target.type.rawValue), which can't hold widgets") }
        guard !subtree(of: id).contains(parent) else { throw UIBuildError("\(id) can't go inside itself") }
    }

    static func describe(_ error: any Error) -> String {
        if case DecodingError.typeMismatch(_, let context) = error { return context.debugDescription + " at " + context.codingPath.map(\.stringValue).joined(separator: ".") }
        if case DecodingError.dataCorrupted(let context) = error { return context.debugDescription + " at " + context.codingPath.map(\.stringValue).joined(separator: ".") }
        return "\(error)"
    }
}

/// Imports a `.ui` file: it checks that the JSON decodes and warns about problems (duplicate
/// ids, bad parents, colors, missing images). A layout has no objects; game code shows it with
/// `UIBuildView`, which reads the file again whenever it is reimported, so edits show up while a
/// game runs. A cooked game keeps the file as it is.
public struct UIBuildImporter: AssetImporter {
    public init() {}

    public var name: String { "ui" }
    public var fileExtensions: [String] { ["ui"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: UIBuild
        do { build = try AssetJSON.decoder().decode(UIBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a UI layout: \(UIBuild.describe(error))")
        }
        let paths = context.assetsByPath
        for issue in build.validate(imageExists: { DataTableImporter.exists($0, in: paths) }) {
            context.warn(issue.description)
        }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `build` to a new `.ui` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createUIBuild(_ build: UIBuild, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try build.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.ui` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func uiBuild(of id: AssetID) -> UIBuild? {
        guard record(id)?.importer == UIBuildImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(UIBuild.self, from: data)
    }

    /// The layout at `path` (relative to `Assets/`; a leading `Assets/` is allowed).
    public func uiBuild(path: String) -> UIBuild? {
        id(forPath: DataTableImporter.relativePath(path)).flatMap { uiBuild(of: $0) }
    }

    /// The layout `id` with the revision it was read at, importing it first if it is out of date
    /// (for `UIBuildView`'s hot reload). The revision is 0 in a cooked pack.
    public func uiBuildForGame(_ id: AssetID) -> (build: UIBuild, revision: Int)? {
        guard record(id)?.importer == UIBuildImporter().name else { return nil }
        if pack == nil { _ = asset(id) }
        guard let build = uiBuild(of: id) else { return nil }
        return (build, pack == nil ? revision(of: id) : 0)
    }

    /// Overwrites the `.ui` asset `id` with `build` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writeUIBuild(_ build: UIBuild, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try build.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// Problems with `build`, with image paths checked against the project.
    public func uiBuildIssues(_ build: UIBuild) -> [UIBuildIssue] {
        build.validate(imageExists: { [unowned self] in assetID(forTableValue: $0) != nil })
    }
}
