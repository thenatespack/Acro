import Engine
import Foundation

/// The UI / HUD Builder tools: `uiLayout.new`, `uiLayout.get`, `uiLayout.set`, `uiLayout.edit`, `uiLayout.open`.
@MainActor
public enum EditorUIBuildCommands {
    public static let all: [any EditorCommand.Type] = [
        UINewCommand.self,
        UIGetCommand.self,
        UISetCommand.self,
        UIEditCommand.self,
        UIOpenCommand.self,
        UIPlaceCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A .ui file is a game menu or HUD: `theme` (game|dark|light|highContrast), `colors` (theme color name → \
        "#RRGGBB[AA]"; names: \(UIBuild.themeColorNames.joined(separator: ", "))), `fontSize`, `safeArea` (points kept clear \
        of the screen edges), `size` (design screen size [w, h]), `scaleMode` (none|fit|fill|width|height: how \
        the whole layout scales with the screen from `size`; default none), `values` (sample values by key for the preview) and \
        `widgets`, a flat list. Each widget: `id` (unique), `type` (panel|vstack|hstack|label|image|button|bar|spacer|slider|toggle|textField), \
        `parent` (a container id; "" is the screen). The screen and panels place children by `anchor` (topLeft|top|topRight|left|\
        center|right|bottomLeft|bottom|bottomRight|fill) and `offset` [x, y] points in from the anchored edges; stacks line \
        them up (`spacing`, `align` auto|start|center|end|stretch, `justify` start|center|end|spaceBetween, children's `grow`). \
        Also: width/height (omit to fit content), padding, background/borderColor/color ("#hex" or a theme color name), \
        cornerRadius, opacity, hidden; label/button `text` with `{key}` placeholders, fontSize, textAlign, wrap, shadow; \
        image `image` (path under Assets/), fit fit|fill|stretch; bar value, max, kind progress|health, segments, trail; \
        button primary, event (default: the id); slider value, min, max, step; toggle text, on, toggleStyle checkbox|switch; \
        textField text, placeholder, maxLength. Animation: the layout's and any widget's `show` / `hide` transitions \
        ({kind: none|fade|slide|scale, duration, delay, easing, from: left|right|top|bottom, distance, scale}; a widget's \
        play when visibleWhen / hidden change, the layout's when the game shows or hides it) and a bar's, label's or \
        button's `tween` (seconds its numbers take to move to a new value). Gamepad / arrow-key focus: the layout's \
        `navigation` (widget ids that Down / Right step through, Up / Left back, wrapping) and `focus` (focused first); \
        a button's or input's navUp / navDown / navLeft / navRight override it. Sliders and toggles send their event when the player changes them, text \
        fields on Enter, with the new value. `bind` ties a widget to a value key (bar fill = value / max; label/button \
        text; image path; slider / toggle / text field value, written back as the player changes it) and `visibleWhen` \
        shows it only while a key is truthy ("!key": falsy). In a game, a UILayoutPlayer component (uiLayout.place) shows \
        a layout with no code; game code uses world.gameUI: set("health", 64), on("pause") { event, entity in ... }.
        """
}

extension EditorSession {
    /// Writes a layout to "`name`.ui" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createUIBuildAsset(in folder: String, name: String = "New UI", build: UIBuild = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New UI Layout") else {
            log.error("New UI Layout: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".ui"))
        do {
            let id = try assets.createUIBuild(build, at: path)
            log.info("Created UI layout \(path)")
            return id
        } catch {
            log.error("New UI Layout failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.ui` file.
    public func isUIBuildFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == UIBuildImporter().name
    }

    /// Replaces the contents of the layout `id` as one undo step (undo writes the old contents
    /// back). Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyUIBuild(_ build: UIBuild, to id: AssetID, label: String = "Edit UI Layout") -> [String]? {
        guard let assets, let old = assets.uiBuild(of: id) else {
            log.error("\(label): \(id) isn't a readable .ui file")
            return nil
        }
        guard old != build else { return [] }
        let command = UIBuildFileEditCommand(asset: id, old: old, new: build, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// Adds an entity with a `UILayoutPlayer` that shows the layout `id` over the game while it
    /// plays, as one undo step, and selects it. Returns its id.
    @discardableResult
    public func addUILayoutPlayer(for id: AssetID, name: String? = nil, order: Int = 0, focus: Bool = false, visible: Bool = true) -> EntityID? {
        let stem = ((assets?.path(of: id) ?? "UI") as NSString).lastPathComponent
        let title = name ?? (stem as NSString).deletingPathExtension
        do {
            // By id, so it survives renames and cooking follows it into built games.
            let player = UILayoutPlayer(layout: AssetReference(id).description, visible: visible, order: order, focus: focus)
            let command = try SpawnCommand(components: [Transform(), player], name: title, in: world, label: "Add UI Layout Player")
            guard perform(command) else { return nil }
            selection.set(command.rootIDs)
            return command.rootIDs.first
        } catch {
            log.error("Add UI Layout Player failed: \(error)")
            return nil
        }
    }

    /// The layout named by `asset` / `path` and its contents.
    func resolveUIBuild(_ asset: AssetReference?, path: String?, _ title: String) throws -> (AssetID, UIBuild) {
        let id = try resolveAsset(asset, path: path, title)
        guard isUIBuildFile(id), let build = assets?.uiBuild(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .ui file")
        }
        return (id, build)
    }
}

/// Makes layout edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct UIBuildFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: UIBuild
    public let new: UIBuild
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: UIBuild, new: UIBuild, in database: AssetDatabase, label: String = "Edit UI Layout") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ build: UIBuild) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeUIBuild(build, to: asset)
    }
}

/// What the editing tools return.
public struct UIBuildResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// Widget ids in file order, as "id (type, in parent)".
    public var widgets: [String]
    /// Value keys widgets read (bind, visibleWhen, {key} placeholders): what game code sets.
    public var valueKeys: [String]
    /// Events buttons send: what game code listens for.
    public var events: [String]
    /// Problems: duplicate ids, bad parents, colors, missing images, import failures.
    public var warnings: [String]
}

extension UIBuildResult {
    @MainActor init(_ id: AssetID, _ build: UIBuild, in session: EditorSession) {
        let record = session.assets?.record(id)
        let issues = session.assets?.uiBuildIssues(build) ?? build.validate()
        self.init(asset: id, path: record?.path ?? "",
                  widgets: build.widgets.map { "\($0.id) (\($0.type.rawValue)\($0.parent.isEmpty ? "" : ", in \($0.parent)"))" },
                  valueKeys: build.valueKeys, events: build.events,
                  warnings: issues.map(\.description) + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum UINewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New UI" (the file gets ".ui").
        public var name: String?
        /// What to start from: hud (default: health bar, score, pause button), menu (title and Play / Options / Quit), dialogue (a dialogue box for DialoguePlayer.uiLayout) or empty.
        public var preset: String?
        /// Widgets to add after the preset's (same fields as in the file).
        public var widgets: [UIBuildWidget]?
        public var theme: String?
        public init(folder: String? = nil, name: String? = nil, preset: String? = nil, widgets: [UIBuildWidget]? = nil, theme: String? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
            self.widgets = widgets
            self.theme = theme
        }
    }

    public static let id: CommandID = "uiLayout.new"
    public static let title = "New UI Layout"
    public static let doc = "Writes a .ui file (a game menu or HUD) in `folder` (default: the Assets root) from a `preset` (hud, menu, dialogue, empty) plus optional `widgets`, and imports it. Returns the widget ids, value keys, events and warnings. Change it with uiLayout.edit (add/update/move/remove widgets, bindings, sample values) or uiLayout.set. " + EditorUIBuildCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIBuildResult {
        let presetName = arguments.preset ?? "hud"
        guard var build = UIBuild.preset(presetName) else {
            throw CommandError.failed("\(title): unknown preset '\(presetName)' (one of \(UIBuild.presetNames.joined(separator: ", ")))")
        }
        do { build = try build.applying(UIBuildEdit(addWidgets: arguments.widgets, theme: arguments.theme)) } catch {
            throw CommandError.failed("\(title): \(error)")
        }
        let id = try session.commands.require(session.createUIBuildAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New UI", build: build), title)
        return UIBuildResult(id, build, in: session)
    }
}

public enum UIGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The .ui file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var layout: UIBuild
        public var valueKeys: [String]
        public var events: [String]
        public var warnings: [String]
    }

    public static let id: CommandID = "uiLayout.get"
    public static let title = "Get UI Layout"
    public static let doc = "Reads a .ui file: its theme, sample values and widgets as stored, the value keys and events game code uses, and the problems with it."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, build) = try session.resolveUIBuild(arguments.asset, path: arguments.path, title)
        let summary = UIBuildResult(id, build, in: session)
        return Result(asset: id, path: summary.path, layout: build, valueKeys: summary.valueKeys, events: summary.events,
                      warnings: summary.warnings)
    }
}

public enum UISetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var layout: UIBuild
        public init(asset: AssetReference? = nil, path: String? = nil, layout: UIBuild) {
            self.asset = asset
            self.path = path
            self.layout = layout
        }
    }

    public static let id: CommandID = "uiLayout.set"
    public static let title = "Set UI Layout"
    public static let doc = "Replaces a .ui file's whole contents and reimports it (running games show the new layout). Undoable. For a few changes, uiLayout.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIBuildResult {
        let (id, _) = try session.resolveUIBuild(arguments.asset, path: arguments.path, title)
        _ = try session.commands.require(session.applyUIBuild(arguments.layout, to: id, label: title), title)
        return UIBuildResult(id, arguments.layout, in: session)
    }
}

public enum UIEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Widget ids to remove (with everything inside them).
        public var removeWidgets: [String]?
        /// Widgets to add, in order; a later one may name an earlier one as `parent`. An empty id is made from the type.
        public var addWidgets: [UIBuildWidget]?
        /// Widget id → fields to change, e.g. {"score": {"text": "Points: {score}", "fontSize": 30}}; null resets a field; "id" renames.
        public var updateWidgets: [String: JSONValue]?
        /// Reparent / reorder: [{"id": "health", "parent": "status", "index": 0}] ("" parent is the screen; no index: last).
        public var moveWidgets: [UIBuildMove]?
        /// Widget id → the value key it shows, e.g. {"health": "playerHealth"} ("" removes the binding).
        public var bindings: [String: String]?
        /// Sample values by key for the preview, e.g. {"health": 40} (null removes one).
        public var values: [String: JSONValue]?
        public var theme: String?
        /// Theme colors by name, e.g. {"accent": "#33AAFF"} ("" restores the theme's).
        public var colors: [String: String]?
        public var fontSize: Float?
        /// Points kept clear of the screen edges (negative: the theme's).
        public var safeArea: Float?
        /// The design screen size [w, h].
        public var size: Vec2?
        /// How the whole layout scales with the screen from `size`: none|fit|fill|width|height.
        public var scaleMode: UIBuildScaleMode?
        /// The layout's show / hide transitions, e.g. {"kind": "slide", "from": "bottom", "duration": 0.3} (kind "none" removes one).
        public var show: UIBuildTransition?
        public var hide: UIBuildTransition?
        /// Keyboard / gamepad focus order: widget ids Down / Right step through ([] clears it).
        public var navigation: [String]?
        /// The widget focused first ("" clears it).
        public var focus: String?
        public init(asset: AssetReference? = nil, path: String? = nil, removeWidgets: [String]? = nil, addWidgets: [UIBuildWidget]? = nil,
                    updateWidgets: [String: JSONValue]? = nil, moveWidgets: [UIBuildMove]? = nil, bindings: [String: String]? = nil,
                    values: [String: JSONValue]? = nil, theme: String? = nil, colors: [String: String]? = nil, fontSize: Float? = nil,
                    safeArea: Float? = nil, size: Vec2? = nil, scaleMode: UIBuildScaleMode? = nil, show: UIBuildTransition? = nil,
                    hide: UIBuildTransition? = nil, navigation: [String]? = nil, focus: String? = nil) {
            self.navigation = navigation
            self.focus = focus
            self.scaleMode = scaleMode
            self.show = show
            self.hide = hide
            self.asset = asset
            self.path = path
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

        var edit: UIBuildEdit {
            UIBuildEdit(removeWidgets: removeWidgets, addWidgets: addWidgets, updateWidgets: updateWidgets, moveWidgets: moveWidgets,
                        bindings: bindings, values: values, theme: theme, colors: colors, fontSize: fontSize, safeArea: safeArea, size: size,
                        scaleMode: scaleMode, show: show, hide: hide, navigation: navigation, focus: focus)
        }
    }

    public static let id: CommandID = "uiLayout.edit"
    public static let title = "Edit UI Layout"
    public static let doc = "Changes part of a .ui file in one undoable step, in this order: removeWidgets, addWidgets, updateWidgets (id → fields; null resets; \"id\" renames), moveWidgets, bindings (widget id → value key), values (sample values), then theme / colors / fontSize / safeArea / size / scaleMode / show / hide / navigation / focus. Running games show the change. Returns widget ids, value keys, events and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> UIBuildResult {
        let (id, original) = try session.resolveUIBuild(arguments.asset, path: arguments.path, title)
        let build: UIBuild
        do { build = try original.applying(arguments.edit) } catch { throw CommandError.failed("\(title): \(error)") }
        _ = try session.commands.require(session.applyUIBuild(build, to: id, label: title), title)
        return UIBuildResult(id, build, in: session)
    }
}

public enum UIOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Preview screen size [w, h] in points (default: the layout's design size).
        public var previewSize: Vec2?
        /// Values to preview with (over the file's sample values; not saved).
        public var values: [String: JSONValue]?
        /// Select this widget.
        public var select: String?
        public init(asset: AssetReference? = nil, path: String? = nil, previewSize: Vec2? = nil, values: [String: JSONValue]? = nil,
                    select: String? = nil) {
            self.asset = asset
            self.path = path
            self.previewSize = previewSize
            self.values = values
            self.select = select
        }
    }

    public static let id: CommandID = "uiLayout.open"
    public static let title = "Open in UI Builder"
    public static let doc = "Opens a .ui file in the editor's UI Builder tab (live preview at a chosen screen size, widget tree with drag and drop, property form) and brings the tab to the front, optionally at `previewSize` with preview `values` and a widget selected. view.screenshot {source: \"panel\", panel: \"uiBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, build) = try session.resolveUIBuild(arguments.asset, path: arguments.path, title)
        if let select = arguments.select, build.widget(select) == nil { throw CommandError.failed("\(title): no widget \(select)") }
        session.openUIBuild = id
        session.uiPreviewRequest = UIPreviewRequest(size: arguments.previewSize, values: arguments.values, select: arguments.select)
        session.onOpenUIBuild?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum UIPlaceCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// The entity's name (default: the file's name).
        public var name: String?
        /// Drawing order between layouts: higher draws on top (default 0).
        public var order: Int?
        /// Give the layout keyboard / gamepad focus when it shows (menus; default false).
        public var focus: Bool?
        /// Shown when play starts (default true).
        public var visible: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, name: String? = nil, order: Int? = nil, focus: Bool? = nil,
                    visible: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.name = name
            self.order = order
            self.focus = focus
            self.visible = visible
        }
    }

    public static let id: CommandID = "uiLayout.place"
    public static let title = "Add UI Layout to Scene"
    public static let doc = "Adds an entity with a UILayoutPlayer to the open scene, so the .ui layout shows over the game while it plays (editor play mode, GameRunner, exported games) with no game code. Game code sets its values and handles its events through world.gameUI (set(key, value), on(event) { event, entity in }). Undoable; returns the new entity."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> EntitiesResult {
        let (id, _) = try session.resolveUIBuild(arguments.asset, path: arguments.path, title)
        let entity = try session.commands.require(session.addUILayoutPlayer(for: id, name: arguments.name, order: arguments.order ?? 0,
                                                                             focus: arguments.focus ?? false, visible: arguments.visible ?? true), title)
        return EntitiesResult(entities: [entity])
    }
}

/// Preview settings `uiLayout.open` hands to the UI Builder tab.
public struct UIPreviewRequest: Equatable, Sendable {
    public var size: Vec2?
    public var values: [String: JSONValue]?
    public var select: String?
}
