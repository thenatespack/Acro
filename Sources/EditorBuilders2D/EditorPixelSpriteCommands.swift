import EditorCore
import Engine
import Foundation

/// The pixel sprite tools: `sprite.new`, `sprite.get`, `sprite.set`, `sprite.edit`, `sprite.draw`, `sprite.open`,
/// `sprite.importSheet`.
@MainActor
public enum EditorPixelSpriteCommands {
    public static let all: [any EditorCommand.Type] = [
        PixelSpriteNewCommand.self,
        PixelSpriteGetCommand.self,
        PixelSpriteSetCommand.self,
        PixelSpriteEditCommand.self,
        PixelSpriteDrawCommand.self,
        PixelSpriteOpenCommand.self,
        PixelSpriteImportSheetCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A .sprite file is pixel art (every key optional): width and height (1-256, default 16), palette (hex colors, up \
        to 62), layers (bottom first: name, visible, opacity 0-1, blend normal|multiply|add|screen|overlay, cels: one list of row strings per frame), frames \
        ({duration} in ms), tags ({name, from, to, mode loop|once|pingPong, events [{frame, name}]}: inclusive frame ranges, one animation clip \
        each, firing its events when it reaches those frames), pivot ([x, y] 0-1 from the bottom-left, default [0.5, 0]) and pixelsPerUnit (default 16). In a row string \
        each character is one pixel: "." is transparent and 0-9, a-z, A-Z are palette entries 0-61 ("0" is the first \
        color, "a" the 11th). It imports as a texture (sub-asset "texture"): the frames in a grid, frame i in cell i, so \
        indices stay stable for SpriteAnimator clips and tile sets. Palette presets: pico8, db16, db32, gameboy, grayscale.
        """
}

extension EditorSession {
    /// Writes a pixel sprite to "`name`.sprite" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createPixelSpriteAsset(in folder: String, name: String = "New Sprite", sprite: PixelSprite = PixelSprite()) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Sprite") else {
            log.error("New Sprite: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".sprite"))
        do {
            let id = try assets.createPixelSprite(sprite, at: path)
            log.info("Created sprite \(path)")
            return id
        } catch {
            log.error("New Sprite failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.sprite` file.
    public func isPixelSpriteFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == PixelSpriteImporter().name
    }

    /// Replaces the contents of the sprite `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyPixelSprite(_ sprite: PixelSprite, to id: AssetID, label: String = "Edit Sprite") -> [String]? {
        guard let assets, let old = assets.pixelSprite(of: id) else {
            log.error("\(label): \(id) isn't a readable .sprite file")
            return nil
        }
        guard old != sprite else { return [] }
        let command = PixelSpriteFileEditCommand(asset: id, old: old, new: sprite, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }
}

/// Makes sprite edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct PixelSpriteFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: PixelSprite
    public let new: PixelSprite
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: PixelSprite, new: PixelSprite, in database: AssetDatabase, label: String = "Edit Sprite") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ sprite: PixelSprite) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writePixelSprite(sprite, to: asset)
    }
}

/// Arguments naming a `.sprite` file.
public protocol PixelSpriteTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    /// The sprite named by `target` and its contents.
    func resolvePixelSprite(_ target: some PixelSpriteTarget, _ title: String) throws -> (AssetID, PixelSprite) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isPixelSpriteFile(id), let sprite = assets?.pixelSprite(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .sprite file")
        }
        return (id, sprite)
    }
}

/// A palette argument: a preset name ("pico8") or a list of hex colors.
enum PixelSpriteArguments {
    static func palette(_ value: JSONValue) throws -> [PixelColor] {
        switch value {
        case .string(let name):
            guard let preset = PixelPalette(rawValue: name) else {
                throw CommandError.failed("unknown palette '\(name)'; presets: \(PixelPalette.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            return preset.colors
        case .array(let items):
            return try items.map { item in
                guard case .string(let text) = item, let color = PixelColor(hex: text) else {
                    throw CommandError.failed("palette colors are hex strings like \"#ff004d\"")
                }
                return color
            }
        default:
            throw CommandError.failed("palette is a preset name or a list of hex colors")
        }
    }

    /// A pixel value from a color argument: a palette index (number), a row character ("3",
    /// "a", "." for transparent) or a hex color (added to the palette if missing).
    static func value(_ color: JSONValue?, in sprite: inout PixelSprite, warnings: inout [String]) throws -> UInt8 {
        guard let color else { throw CommandError.failed("give a `color`: a palette index, a row character or a hex color") }
        switch color {
        case .int(let i):
            guard i >= 0, i < sprite.palette.count, i < PixelSprite.maxColors else {
                throw CommandError.failed("palette index \(i) is out of range (the palette has \(sprite.palette.count) colors)")
            }
            return UInt8(i + 1)
        case .double(let d):
            return try value(.int(Int64(d)), in: &sprite, warnings: &warnings)
        case .string(let text) where text.count == 1:
            let ch = text.first!
            if ch == PixelSprite.transparentCharacter { return 0 }
            guard let v = PixelSprite.value(for: ch) else { throw CommandError.failed("'\(text)' isn't a palette character") }
            return v
        case .string(let text):
            guard let c = PixelColor(hex: text) else { throw CommandError.failed("'\(text)' isn't a color") }
            let had = sprite.palette.contains(c)
            guard let v = sprite.value(for: c) else { throw CommandError.failed("the palette is full (\(PixelSprite.maxColors) colors)") }
            if !had { warnings.append("added \(c) to the palette as entry \(v - 1) ('\(PixelSprite.character(for: v))')") }
            return v
        default:
            throw CommandError.failed("a color is a palette index, a row character or a hex color")
        }
    }

    /// A layer argument: an index or a name (default: the first layer).
    static func layer(_ value: JSONValue?, in sprite: PixelSprite) throws -> Int {
        switch value {
        case nil, .null?: return 0
        case .int(let i)?:
            guard sprite.layers.indices.contains(Int(i)) else { throw CommandError.failed("no layer \(i) (the sprite has \(sprite.layers.count))") }
            return Int(i)
        case .string(let name)?:
            guard let i = sprite.layerIndex(named: name) else {
                throw CommandError.failed("no layer '\(name)'; layers: \(sprite.layers.map(\.name).joined(separator: ", ")) (add one with sprite.edit addLayers)")
            }
            return i
        default: throw CommandError.failed("layer is an index or a name")
        }
    }

    static func frame(_ value: Int?, in sprite: PixelSprite) throws -> Int {
        let f = value ?? 0
        guard sprite.frames.indices.contains(f) else { throw CommandError.failed("no frame \(f) (the sprite has frames 0...\(sprite.frames.count - 1))") }
        return f
    }
}

/// What the sprite tools return.
public struct PixelSpriteResult: Codable, Equatable, Sendable {
    public struct LayerInfo: Codable, Equatable, Sendable {
        public var name: String
        public var visible: Bool
        public var opacity: Float
        public var blend: String
    }

    public struct ClipInfo: Codable, Equatable, Sendable {
        public var name: String
        /// Atlas frame indices (frames longer than the shortest one repeat).
        public var frames: [Int]
        public var fps: Float
        public var mode: String
        /// Events as "name@step" (step: position in `frames`).
        public var events: [String]?
    }

    public var asset: AssetID
    public var path: String
    /// The imported atlas texture ("asset:<id>#texture").
    public var texture: AssetReference
    public var width: Int
    public var height: Int
    public var palette: [String]
    public var layers: [LayerInfo]
    /// Frame durations in ms.
    public var frames: [Int]
    public var tags: [PixelSprite.Tag]
    /// The SpriteAnimator clips the tags become.
    public var clips: [ClipInfo]
    /// Columns of the atlas grid (frame i is in cell i).
    public var atlasColumns: Int
    /// The whole file (sprite.get, sprite.new, sprite.set).
    public var sprite: PixelSprite?
    /// The frame `preview` shows.
    public var previewFrame: Int?
    /// That frame's visible pixels as row strings (top visible layer wins).
    public var preview: [String]?
    public var warnings: [String]
    /// sprite.importSheet: how the sheet was read.
    public var sheet: SheetInfo?

    public struct SheetInfo: Codable, Equatable, Sendable {
        /// Whole cells found in the image.
        public var columns: Int
        public var rows: Int
        /// Distinct colors in the sliced frames.
        public var colorsFound: Int
        /// Whether colors were merged or mapped to the nearest palette entry.
        public var quantized: Bool
    }
}

extension PixelSpriteResult {
    @MainActor init(_ id: AssetID, _ sprite: PixelSprite, warnings: [String], full: Bool, previewFrame: Int? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let frame = previewFrame.flatMap { sprite.frames.indices.contains($0) ? $0 : nil }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", texture: AssetReference(id, subAsset: "texture"),
                  width: sprite.width, height: sprite.height, palette: sprite.palette.map(\.description),
                  layers: sprite.layers.map { LayerInfo(name: $0.name, visible: $0.visible, opacity: $0.opacity, blend: $0.blend.rawValue) },
                  frames: sprite.frames.map(\.duration), tags: sprite.tags,
                  clips: sprite.clips().map { clip in
                      ClipInfo(name: clip.name, frames: clip.frames, fps: clip.fps, mode: clip.mode.rawValue,
                               events: clip.events.isEmpty ? nil : clip.events.map { "\($0.name)@\($0.step)" })
                  },
                  atlasColumns: PixelSprite.sheetColumns(frameCount: sprite.frames.count),
                  sprite: full ? sprite : nil, previewFrame: frame, preview: frame.map { sprite.compositeRows(frame: $0) },
                  warnings: Array(Set(sprite.problems() + warnings)).sorted() + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum PixelSpriteNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Sprite" (the file gets ".sprite").
        public var name: String?
        /// Canvas size in pixels (1-256, default 16 x 16).
        public var width: Int?
        public var height: Int?
        /// A preset name (pico8, db16, db32, gameboy, grayscale; default pico8) or a list of hex colors.
        public var palette: JSONValue?
        /// Number of blank frames (default 1).
        public var frames: Int?
        /// Or the whole contents (overrides the other fields).
        public var sprite: PixelSprite?
        public init(folder: String? = nil, name: String? = nil, width: Int? = nil, height: Int? = nil, palette: JSONValue? = nil,
                    frames: Int? = nil, sprite: PixelSprite? = nil) {
            self.folder = folder
            self.name = name
            self.width = width
            self.height = height
            self.palette = palette
            self.frames = frames
            self.sprite = sprite
        }
    }

    public static let id: CommandID = "sprite.new"
    public static let title = "New Sprite"
    public static let doc = "Writes a .sprite file in `folder` (default: the Assets root): a blank `width` x `height` canvas with `palette` and `frames` blank frames, or `sprite`. Draw on it with sprite.draw, add frames, layers and tags with sprite.edit. Returns the asset, its texture reference, layers, frames, clips and warnings. " + EditorPixelSpriteCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        var sprite: PixelSprite
        if let given = arguments.sprite {
            sprite = given
            sprite.normalize()
        } else {
            sprite = PixelSprite(width: arguments.width ?? 16, height: arguments.height ?? 16,
                                 palette: try arguments.palette.map(PixelSpriteArguments.palette) ?? PixelPalette.pico8.colors,
                                 frameCount: max(arguments.frames ?? 1, 1))
        }
        let id = try session.commands.require(session.createPixelSpriteAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Sprite", sprite: sprite), title)
        return PixelSpriteResult(id, sprite, warnings: [], full: true, in: session)
    }
}

public enum PixelSpriteGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PixelSpriteTarget {
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        /// Also return this frame's visible pixels as `preview` rows.
        public var frame: Int?
        public init(asset: AssetReference? = nil, path: String? = nil, frame: Int? = nil) {
            self.asset = asset
            self.path = path
            self.frame = frame
        }
    }

    public static let id: CommandID = "sprite.get"
    public static let title = "Get Sprite"
    public static let doc = "Reads a .sprite file: the whole contents (`sprite`, cels as row strings), a summary (layers, frame durations, tags, the clips they become, atlas columns), the texture reference and warnings. With `frame`, also `preview`: that frame's visible pixels as rows."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        let (id, sprite) = try session.resolvePixelSprite(arguments, title)
        if let frame = arguments.frame { _ = try PixelSpriteArguments.frame(frame, in: sprite) }
        return PixelSpriteResult(id, sprite, warnings: [], full: true, previewFrame: arguments.frame, in: session)
    }
}

public enum PixelSpriteSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PixelSpriteTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var sprite: PixelSprite
        public init(asset: AssetReference? = nil, path: String? = nil, sprite: PixelSprite) {
            self.asset = asset
            self.path = path
            self.sprite = sprite
        }
    }

    public static let id: CommandID = "sprite.set"
    public static let title = "Set Sprite"
    public static let doc = "Replaces a .sprite file's whole contents and reimports it. Undoable. To draw, sprite.draw is shorter; for frames, layers, tags and the palette, sprite.edit."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        let (id, _) = try session.resolvePixelSprite(arguments, title)
        var sprite = arguments.sprite
        sprite.normalize()
        let warnings = try session.commands.require(session.applyPixelSprite(sprite, to: id, label: title), title)
        return PixelSpriteResult(id, sprite, warnings: warnings, full: true, in: session)
    }
}

public enum PixelSpriteEditCommand: EditorCommand {
    /// Changes to one layer, found by `name`.
    public struct LayerUpdate: Codable, Equatable, Sendable {
        public var name: String
        public var rename: String?
        public var visible: Bool?
        public var opacity: Float?
        /// normal, multiply, add, screen or overlay.
        public var blend: PixelSprite.BlendMode?
        public init(name: String, rename: String? = nil, visible: Bool? = nil, opacity: Float? = nil, blend: PixelSprite.BlendMode? = nil) {
            self.name = name
            self.rename = rename
            self.visible = visible
            self.opacity = opacity
            self.blend = blend
        }
    }

    /// A frame event on a tag.
    public struct TagEvent: Codable, Equatable, Sendable {
        public var tag: String
        public var frame: Int?
        public var name: String?
        public init(tag: String, frame: Int? = nil, name: String? = nil) {
            self.tag = tag
            self.frame = frame
            self.name = name
        }
    }

    /// Copies pixels from one cel to another (copy / paste between cels).
    public struct CelCopy: Codable, Equatable, Sendable {
        public var fromFrame: Int
        /// Layer index or name (default: the first layer).
        public var fromLayer: JSONValue?
        public var toFrame: Int
        /// Default: `fromLayer`.
        public var toLayer: JSONValue?
        /// The part to copy [x, y, width, height] (default: the whole cel).
        public var rect: PixelRect?
        /// Where its top-left goes (default: the same place).
        public var x: Int?
        public var y: Int?
        /// Copy the visible pixels of every layer of `fromFrame` instead of one layer.
        public var merged: Bool?
        /// Replace the target pixels, transparent ones included (default: transparent pixels don't cover).
        public var replace: Bool?
        public init(fromFrame: Int, fromLayer: JSONValue? = nil, toFrame: Int, toLayer: JSONValue? = nil, rect: PixelRect? = nil,
                    x: Int? = nil, y: Int? = nil, merged: Bool? = nil, replace: Bool? = nil) {
            self.fromFrame = fromFrame
            self.fromLayer = fromLayer
            self.toFrame = toFrame
            self.toLayer = toLayer
            self.rect = rect
            self.x = x
            self.y = y
            self.merged = merged
            self.replace = replace
        }
    }

    public struct Arguments: Codable, Equatable, Sendable, PixelSpriteTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Replace the palette: a preset name or a list of hex colors. Pixels keep their palette indices.
        public var palette: JSONValue?
        /// Hex colors to append to the palette (ones already in it are skipped).
        public var addColors: [String]?
        /// Resize the canvas (pixels stay put from the top-left).
        public var width: Int?
        public var height: Int?
        /// Layer names to add on top, in order.
        public var addLayers: [String]?
        public var removeLayers: [String]?
        public var updateLayers: [LayerUpdate]?
        /// Number of frames to add (blank, or copies of `copyFrame`) at `insertAt` (default: the end).
        public var addFrames: Int?
        public var insertAt: Int?
        public var copyFrame: Int?
        /// Frame indices to remove (tags shrink to the frames they keep).
        public var removeFrames: [Int]?
        /// Set every frame's duration (ms).
        public var duration: Int?
        /// Per-frame durations (ms) from frame 0; a shorter list leaves the rest.
        public var durations: [Int]?
        /// Copy pixels between cels (applied after the frame edits, so new frames can be targets).
        public var copyCels: [CelCopy]?
        /// Replace all tags.
        public var tags: [PixelSprite.Tag]?
        /// Add tags (replacing ones with the same name).
        public var addTags: [PixelSprite.Tag]?
        public var removeTags: [String]?
        /// Add frame events to tags: [{tag, frame, name}] (`frame` is the sprite frame, inside the tag).
        public var addEvents: [TagEvent]?
        /// Remove frame events: [{tag, frame, name}] (a missing `frame` or `name` matches any).
        public var removeEvents: [TagEvent]?
        public var pivot: Vec2?
        public var pixelsPerUnit: Float?
        public init(asset: AssetReference? = nil, path: String? = nil, palette: JSONValue? = nil, addColors: [String]? = nil,
                    width: Int? = nil, height: Int? = nil, addLayers: [String]? = nil, removeLayers: [String]? = nil,
                    updateLayers: [LayerUpdate]? = nil, addFrames: Int? = nil, insertAt: Int? = nil, copyFrame: Int? = nil,
                    removeFrames: [Int]? = nil, duration: Int? = nil, durations: [Int]? = nil, tags: [PixelSprite.Tag]? = nil,
                    addTags: [PixelSprite.Tag]? = nil, removeTags: [String]? = nil, pivot: Vec2? = nil, pixelsPerUnit: Float? = nil,
                    copyCels: [CelCopy]? = nil, addEvents: [TagEvent]? = nil, removeEvents: [TagEvent]? = nil) {
            self.copyCels = copyCels
            self.addEvents = addEvents
            self.removeEvents = removeEvents
            self.asset = asset
            self.path = path
            self.palette = palette
            self.addColors = addColors
            self.width = width
            self.height = height
            self.addLayers = addLayers
            self.removeLayers = removeLayers
            self.updateLayers = updateLayers
            self.addFrames = addFrames
            self.insertAt = insertAt
            self.copyFrame = copyFrame
            self.removeFrames = removeFrames
            self.duration = duration
            self.durations = durations
            self.tags = tags
            self.addTags = addTags
            self.removeTags = removeTags
            self.pivot = pivot
            self.pixelsPerUnit = pixelsPerUnit
        }
    }

    public static let id: CommandID = "sprite.edit"
    public static let title = "Edit Sprite"
    public static let doc = "Changes a .sprite file's structure in one undoable step, in this order: `palette` / `addColors`, canvas `width` / `height`, layers (`addLayers`, `removeLayers`, `updateLayers` [{name, rename, visible, opacity, blend normal|multiply|add|screen|overlay}]), frames (`addFrames` blank or copies of `copyFrame` at `insertAt`, `removeFrames`), timing (`duration` for all, `durations` per frame, ms), `copyCels` ([{fromFrame, fromLayer, toFrame, toLayer, rect [x, y, w, h], x, y, merged, replace}]: copy / paste pixels between cels; default the whole cel to the same place, transparent pixels don't cover unless `replace`), tags (`tags` replaces all, `addTags`, `removeTags`; a tag {name, from, to, mode loop|once|pingPong, events [{frame, name}]} becomes a SpriteAnimator clip whose events fire when it reaches those frames), frame events (`addEvents` / `removeEvents` [{tag, frame, name}]), then `pivot` and `pixelsPerUnit`. Returns the summary and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        let (id, original) = try session.resolvePixelSprite(arguments, title)
        let sprite = try edited(original, with: arguments)
        let warnings = try session.commands.require(session.applyPixelSprite(sprite, to: id, label: title), title)
        return PixelSpriteResult(id, sprite, warnings: warnings, full: false, in: session)
    }

    /// `sprite` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ original: PixelSprite, with arguments: Arguments) throws -> PixelSprite {
        var sprite = original
        if let palette = arguments.palette { sprite.palette = try PixelSpriteArguments.palette(palette) }
        for text in arguments.addColors ?? [] {
            guard let color = PixelColor(hex: text) else { throw CommandError.failed("'\(text)' isn't a hex color") }
            guard sprite.value(for: color) != nil else { throw CommandError.failed("the palette is full (\(PixelSprite.maxColors) colors)") }
        }
        if arguments.width != nil || arguments.height != nil {
            sprite = sprite.resized(width: arguments.width ?? sprite.width, height: arguments.height ?? sprite.height)
        }
        for name in arguments.addLayers ?? [] {
            guard sprite.layerIndex(named: name) == nil else { throw CommandError.failed("there is already a layer '\(name)'") }
            sprite.insertLayer(name: name)
        }
        for name in arguments.removeLayers ?? [] {
            guard let i = sprite.layerIndex(named: name) else { throw CommandError.failed("no layer '\(name)'") }
            sprite.removeLayer(i)
        }
        for update in arguments.updateLayers ?? [] {
            guard let i = sprite.layerIndex(named: update.name) else { throw CommandError.failed("no layer '\(update.name)'") }
            if let rename = update.rename {
                guard rename == update.name || sprite.layerIndex(named: rename) == nil else {
                    throw CommandError.failed("there is already a layer '\(rename)'")
                }
                sprite.layers[i].name = rename
            }
            if let visible = update.visible { sprite.layers[i].visible = visible }
            if let opacity = update.opacity { sprite.layers[i].opacity = min(max(opacity, 0), 1) }
            if let blend = update.blend { sprite.layers[i].blend = blend }
        }
        if let count = arguments.addFrames {
            guard count > 0, count <= 256 else { throw CommandError.failed("addFrames must be 1-256") }
            if let copy = arguments.copyFrame, !sprite.frames.indices.contains(copy) { throw CommandError.failed("no frame \(copy) to copy") }
            sprite.insertFrames(count, at: arguments.insertAt, copyOf: arguments.copyFrame)
        }
        if let remove = arguments.removeFrames { sprite.removeFrames(remove) }
        if let duration = arguments.duration {
            guard duration > 0 else { throw CommandError.failed("duration must be positive (ms)") }
            for f in sprite.frames.indices { sprite.frames[f].duration = duration }
        }
        for (f, duration) in (arguments.durations ?? []).enumerated() where sprite.frames.indices.contains(f) {
            guard duration > 0 else { throw CommandError.failed("durations must be positive (ms)") }
            sprite.frames[f].duration = duration
        }
        for copy in arguments.copyCels ?? [] {
            let from = try PixelSpriteArguments.frame(copy.fromFrame, in: sprite)
            let to = try PixelSpriteArguments.frame(copy.toFrame, in: sprite)
            let fromLayer = try PixelSpriteArguments.layer(copy.fromLayer, in: sprite)
            let toLayer = copy.toLayer == nil ? fromLayer : try PixelSpriteArguments.layer(copy.toLayer, in: sprite)
            let rect = copy.rect ?? PixelRect(x: 0, y: 0, width: sprite.width, height: sprite.height)
            let clip = copy.merged == true ? sprite.copyMerged(rect, frame: from) : sprite.copy(rect, frame: from, layer: fromLayer)
            guard let clip else { throw CommandError.failed("copyCels: rect [\(rect.x), \(rect.y), \(rect.width), \(rect.height)] is outside the canvas") }
            let r = rect.clamped(width: sprite.width, height: sprite.height)
            if copy.replace == true { sprite.clear(PixelRect(x: copy.x ?? r.x, y: copy.y ?? r.y, width: r.width, height: r.height), frame: to, layer: toLayer) }
            sprite.paste(clip, x: copy.x ?? r.x, y: copy.y ?? r.y, frame: to, layer: toLayer)
        }
        if let tags = arguments.tags { sprite.tags = tags }
        for tag in arguments.addTags ?? [] {
            if let i = sprite.tags.firstIndex(where: { $0.name == tag.name }) { sprite.tags[i] = tag } else { sprite.tags.append(tag) }
        }
        if let remove = arguments.removeTags { sprite.tags.removeAll { remove.contains($0.name) } }
        for event in arguments.addEvents ?? [] {
            guard let t = sprite.tags.firstIndex(where: { $0.name == event.tag }) else {
                throw CommandError.failed("addEvents: no tag '\(event.tag)'; tags: \(sprite.tags.map(\.name).joined(separator: ", "))")
            }
            let tag = sprite.tags[t]
            guard let frame = event.frame, let name = event.name, !name.isEmpty else { throw CommandError.failed("addEvents: give `frame` and `name`") }
            guard frame >= tag.from, frame <= tag.to else {
                throw CommandError.failed("addEvents: frame \(frame) is outside tag '\(tag.name)' (frames \(tag.from)...\(tag.to))")
            }
            let new = PixelSprite.FrameEvent(frame: frame, name: name)
            if !tag.events.contains(new) { sprite.tags[t].events.append(new) }
            sprite.tags[t].events.sort { $0.frame < $1.frame }
        }
        for event in arguments.removeEvents ?? [] {
            guard let t = sprite.tags.firstIndex(where: { $0.name == event.tag }) else { throw CommandError.failed("removeEvents: no tag '\(event.tag)'") }
            sprite.tags[t].events.removeAll { (event.frame == nil || $0.frame == event.frame) && (event.name == nil || $0.name == event.name) }
        }
        if let pivot = arguments.pivot { sprite.pivot = pivot }
        if let ppu = arguments.pixelsPerUnit {
            guard ppu > 0 else { throw CommandError.failed("pixelsPerUnit must be positive") }
            sprite.pixelsPerUnit = ppu
        }
        sprite.normalize()
        return sprite
    }
}

public enum PixelSpriteDrawCommand: EditorCommand {
    /// What an operation does: a drawing tool, or a selection edit (`move`, `copy`, `clear`).
    public enum Tool: String, Codable, CaseIterable, Sendable {
        case pencil, line, rect, fill, eraser, picker
        /// Cut the pixels in `rect` and paste them with their top-left at `to`.
        case move
        /// Paste the pixels in `rect` of cel (`fromFrame`, `fromLayer`) (default: this cel) with
        /// their top-left at `to` (default: the same place).
        case copy
        /// Erase the pixels in `rect`.
        case clear

        /// The drawing tool (nil for the selection edits).
        public var drawingTool: PixelTool? { PixelTool(rawValue: rawValue) }
    }

    /// One drawing operation.
    public struct Operation: Codable, Equatable, Sendable {
        /// pencil (points joined by lines), line, rect (first and last point), fill (flood fill at
        /// each point), eraser, picker (no edit); move, copy, clear (a `rect` selection).
        public var tool: Tool
        /// [[x, y], …] pixels from the top-left (drawing tools).
        public var points: [PixelPoint]?
        /// A palette index, a row character or a hex color (default: the call's `color`).
        public var color: JSONValue?
        /// rect: fill it instead of the outline.
        public var filled: Bool?
        /// move, copy, clear: the selection [x, y, width, height].
        public var rect: PixelRect?
        /// move, copy: where the selection's top-left goes [x, y].
        public var to: PixelPoint?
        /// copy: the cel to copy from (default: the one drawn on). A layer is an index or a name.
        public var fromFrame: Int?
        public var fromLayer: JSONValue?
        /// copy: take the visible pixels of every layer of `fromFrame` instead of one layer.
        public var merged: Bool?
        public init(tool: Tool, points: [PixelPoint]? = nil, color: JSONValue? = nil, filled: Bool? = nil, rect: PixelRect? = nil,
                    to: PixelPoint? = nil, fromFrame: Int? = nil, fromLayer: JSONValue? = nil, merged: Bool? = nil) {
            self.tool = tool
            self.points = points
            self.color = color
            self.filled = filled
            self.rect = rect
            self.to = to
            self.fromFrame = fromFrame
            self.fromLayer = fromLayer
            self.merged = merged
        }
    }

    public struct Arguments: Codable, Equatable, Sendable, PixelSpriteTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Frame index (default 0).
        public var frame: Int?
        /// Layer index or name (default: the first layer).
        public var layer: JSONValue?
        /// Row strings stamped with their top-left at (`x`, `y`): one character per pixel, "."
        /// leaves the pixel (or erases it with `clear`), 0-9 a-z A-Z are palette entries.
        public var pixels: [String]?
        public var x: Int?
        public var y: Int?
        /// Erase the cel first, and let "." in `pixels` erase.
        public var clear: Bool?
        /// Drawing operations applied after `pixels`.
        public var ops: [Operation]?
        /// Default color for `ops`.
        public var color: JSONValue?
        /// Mirror `ops` across the vertical axis (left-right) and/or the horizontal axis.
        public var mirrorX: Bool?
        public var mirrorY: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, frame: Int? = nil, layer: JSONValue? = nil, pixels: [String]? = nil,
                    x: Int? = nil, y: Int? = nil, clear: Bool? = nil, ops: [Operation]? = nil, color: JSONValue? = nil,
                    mirrorX: Bool? = nil, mirrorY: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.frame = frame
            self.layer = layer
            self.pixels = pixels
            self.x = x
            self.y = y
            self.clear = clear
            self.ops = ops
            self.color = color
            self.mirrorX = mirrorX
            self.mirrorY = mirrorY
        }
    }

    public static let id: CommandID = "sprite.draw"
    public static let title = "Draw Sprite"
    public static let doc = "Draws on one cel (`frame`, `layer`) of a .sprite file in one undoable step: `pixels` (row strings stamped at `x`, `y`; \".\" keeps the pixel, or erases with `clear`) then `ops` in order: drawing ({tool pencil|line|rect|fill|eraser, points [[x, y], …], color, filled}, optionally mirrored with `mirrorX` / `mirrorY`) and selections ({tool move, rect [x, y, w, h], to [x, y]} cuts and pastes; {tool copy, rect, to, fromFrame, fromLayer, merged} pastes pixels from this or another cel, `merged` takes the frame's visible pixels; {tool clear, rect} erases). Transparent pixels don't cover when pasted. A color is a palette index (0 = first), a row character (\"3\", \"a\", \".\" transparent) or a hex color (added to the palette if missing). Returns `preview`: the frame's visible pixels as rows. " + "Rows: \".\" transparent, 0-9 a-z A-Z palette entries 0-61."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        let (id, original) = try session.resolvePixelSprite(arguments, title)
        var warnings: [String] = []
        let sprite = try drawn(original, with: arguments, warnings: &warnings)
        let written = try session.commands.require(session.applyPixelSprite(sprite, to: id, label: title), title)
        return PixelSpriteResult(id, sprite, warnings: warnings + written, full: false, previewFrame: arguments.frame ?? 0, in: session)
    }

    /// `sprite` with the drawing of `arguments` applied (pure, for tests).
    public static func drawn(_ original: PixelSprite, with arguments: Arguments, warnings: inout [String]) throws -> PixelSprite {
        var sprite = original
        let frame = try PixelSpriteArguments.frame(arguments.frame, in: sprite)
        let layer = try PixelSpriteArguments.layer(arguments.layer, in: sprite)
        if arguments.pixels == nil && (arguments.ops ?? []).isEmpty && arguments.clear != true {
            throw CommandError.failed("nothing to draw: give `pixels` rows or `ops`")
        }
        if arguments.clear == true { sprite.clearCel(frame: frame, layer: layer) }
        if let rows = arguments.pixels {
            let unknown = sprite.stamp(rows: rows, x: arguments.x ?? 0, y: arguments.y ?? 0, frame: frame, layer: layer,
                                       clear: arguments.clear == true)
            if !unknown.isEmpty {
                warnings.append("skipped characters that aren't palette characters: \(String(unknown.sorted()))")
            }
            let longest = rows.map(\.count).max() ?? 0
            if (arguments.x ?? 0) + longest > sprite.width || (arguments.y ?? 0) + rows.count > sprite.height {
                warnings.append("pixels outside the \(sprite.width) x \(sprite.height) canvas were cut off")
            }
        }
        var mirror: PixelMirror = []
        if arguments.mirrorX == true { mirror.insert(.horizontal) }
        if arguments.mirrorY == true { mirror.insert(.vertical) }
        for op in arguments.ops ?? [] {
            guard let tool = op.tool.drawingTool else {
                try applySelectionOp(op, to: &sprite, frame: frame, layer: layer, warnings: &warnings)
                continue
            }
            guard let points = op.points, !points.isEmpty else { throw CommandError.failed("\(op.tool.rawValue): give at least one point") }
            let value: UInt8 = tool == .eraser || tool == .picker ? 0
                : try PixelSpriteArguments.value(op.color ?? arguments.color, in: &sprite, warnings: &warnings)
            sprite.draw(tool, points: points, value: value, frame: frame, layer: layer, filled: op.filled ?? false, mirror: mirror)
        }
        return sprite
    }

    /// move, copy and clear on cel (`frame`, `layer`).
    static func applySelectionOp(_ op: Operation, to sprite: inout PixelSprite, frame: Int, layer: Int, warnings: inout [String]) throws {
        guard let rect = op.rect, !rect.isEmpty else {
            throw CommandError.failed("\(op.tool.rawValue): give `rect` [x, y, width, height] (width and height at least 1)")
        }
        let r = rect.clamped(width: sprite.width, height: sprite.height)
        guard !r.isEmpty else {
            throw CommandError.failed("\(op.tool.rawValue): rect [\(rect.x), \(rect.y), \(rect.width), \(rect.height)] is outside the \(sprite.width) x \(sprite.height) canvas")
        }
        if r != rect { warnings.append("\(op.tool.rawValue): rect cut to the canvas: [\(r.x), \(r.y), \(r.width), \(r.height)]") }
        switch op.tool {
        case .clear:
            sprite.clear(r, frame: frame, layer: layer)
        case .move:
            guard let to = op.to else { throw CommandError.failed("move: give `to` [x, y], where the selection's top-left goes") }
            sprite.move(r, dx: to.x - r.x, dy: to.y - r.y, frame: frame, layer: layer)
        case .copy:
            let sourceFrame = try PixelSpriteArguments.frame(op.fromFrame ?? frame, in: sprite)
            let clip: PixelClip?
            if op.merged == true {
                clip = sprite.copyMerged(r, frame: sourceFrame)
            } else {
                let sourceLayer = op.fromLayer == nil ? layer : try PixelSpriteArguments.layer(op.fromLayer, in: sprite)
                clip = sprite.copy(r, frame: sourceFrame, layer: sourceLayer)
            }
            guard let clip else { return }
            let to = op.to ?? PixelPoint(r.x, r.y)
            sprite.paste(clip, x: to.x, y: to.y, frame: frame, layer: layer)
        default:
            break
        }
    }
}

public enum PixelSpriteOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, PixelSpriteTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "sprite.open"
    public static let title = "Open in Pixel Sprite Builder"
    public static let doc = "Opens a .sprite file in the editor's Pixel Sprite Builder tab (canvas with drawing tools, palette, layers, frames with onion skin, tags and an animation preview) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"spriteBuilder\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolvePixelSprite(arguments, title)
        session.openPixelSprite = id
        session.onOpenPixelSprite?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum PixelSpriteImportSheetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The sheet: an image asset in the project (PNG, JPEG, TGA)…
        public var image: AssetReference?
        /// …or its path relative to `Assets/`…
        public var imagePath: String?
        /// …or an image file anywhere (absolute, or relative to the working directory).
        public var file: String?
        /// Frame size in pixels (1-256). Or give `columns` / `rows` and it is worked out.
        public var frameWidth: Int?
        public var frameHeight: Int?
        public var columns: Int?
        public var rows: Int?
        /// Pixels around the sheet and between cells (default 0).
        public var margin: Int?
        public var spacing: Int?
        /// At most this many frames (default: every cell; empty cells at the end are dropped).
        public var frames: Int?
        /// A preset name or hex colors to map the pixels to (nearest color). Default: the sheet's own colors.
        public var palette: JSONValue?
        /// With the sheet's own colors, at most this many (median cut; default and maximum 62).
        public var maxColors: Int?
        /// Pixels less opaque than this (0-255, default 128) become transparent.
        public var alphaThreshold: Int?
        /// Frame duration in ms (default 100).
        public var duration: Int?
        public var tags: [PixelSprite.Tag]?
        public var pivot: Vec2?
        public var pixelsPerUnit: Float?
        /// Where the new .sprite goes (default: the image's folder, or the Assets root) and its name
        /// (default: the image's name).
        public var folder: String?
        public var name: String?
        /// Or an existing .sprite to replace (undoable).
        public var into: String?
        public init(image: AssetReference? = nil, imagePath: String? = nil, file: String? = nil, frameWidth: Int? = nil,
                    frameHeight: Int? = nil, columns: Int? = nil, rows: Int? = nil, margin: Int? = nil, spacing: Int? = nil,
                    frames: Int? = nil, palette: JSONValue? = nil, maxColors: Int? = nil, alphaThreshold: Int? = nil,
                    duration: Int? = nil, tags: [PixelSprite.Tag]? = nil, pivot: Vec2? = nil, pixelsPerUnit: Float? = nil,
                    folder: String? = nil, name: String? = nil, into: String? = nil) {
            self.image = image
            self.imagePath = imagePath
            self.file = file
            self.frameWidth = frameWidth
            self.frameHeight = frameHeight
            self.columns = columns
            self.rows = rows
            self.margin = margin
            self.spacing = spacing
            self.frames = frames
            self.palette = palette
            self.maxColors = maxColors
            self.alphaThreshold = alphaThreshold
            self.duration = duration
            self.tags = tags
            self.pivot = pivot
            self.pixelsPerUnit = pixelsPerUnit
            self.folder = folder
            self.name = name
            self.into = into
        }
    }

    public static let id: CommandID = "sprite.importSheet"
    public static let title = "Import Sprite Sheet"
    public static let doc = "Turns a sprite sheet image (`image` asset, `imagePath` under Assets/, or a `file` anywhere; PNG, JPEG or TGA) into a .sprite: cells of `frameWidth` x `frameHeight` (or the size that gives `columns` x `rows`), after `margin` around the sheet and `spacing` between cells, read left to right, top to bottom, become frames (at most `frames`; empty cells at the end are dropped). Pixels map to `palette` (a preset or hex colors, nearest color) or, by default, to the sheet's own colors, reduced to `maxColors` (default 62) by median cut. Pixels less opaque than `alphaThreshold` (default 128) become transparent. Every frame lasts `duration` ms (default 100); `tags`, `pivot` and `pixelsPerUnit` are set as given. Writes a new file (`folder`, `name`; default next to the image, named after it) or replaces the .sprite at `into` (undoable). Returns the sprite summary, `sheet` {columns, rows, colorsFound, quantized} and warnings."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PixelSpriteResult {
        guard let assets = session.assets else { throw CommandError.failed(noProjectReason) }
        // The image and the name / folder it suggests.
        let image: Image
        var suggested = (folder: "", name: "Sheet")
        if let file = arguments.file {
            guard let url = session.fileURL(forPath: file, title) else { throw CommandError.failed("\(title): \(file) is outside the allowed folders") }
            do { image = try ImageDecoder.decode(contentsOf: url) } catch { throw CommandError.failed("\(title): can't read \(file): \(error)") }
            suggested.name = url.deletingPathExtension().lastPathComponent
        } else {
            guard arguments.image != nil || arguments.imagePath != nil else {
                throw CommandError.failed("\(title): give the sheet as `image` (an asset), `imagePath` (under Assets/) or `file`")
            }
            let id = try session.resolveAsset(arguments.image, path: arguments.imagePath, title)
            let path = assets.path(of: id) ?? ""
            do { image = try ImageDecoder.decode(assets.fileData(of: id)) } catch {
                throw CommandError.failed("\(title): \(path) isn't a readable image: \(error)")
            }
            suggested = (EditorSession.parentFolder(of: path), ((path as NSString).lastPathComponent as NSString).deletingPathExtension)
        }

        let margin = max(arguments.margin ?? 0, 0), spacing = max(arguments.spacing ?? 0, 0)
        func size(_ given: Int?, _ count: Int?, _ total: Int, _ axis: String) throws -> Int {
            if let given { return given }
            if let count {
                guard count > 0 else { throw CommandError.failed("\(title): \(axis == "width" ? "columns" : "rows") must be at least 1") }
                return (total - 2 * margin + spacing) / count - spacing
            }
            throw CommandError.failed("\(title): give `frameWidth` and `frameHeight` (or `columns` and `rows`) for the \(image.width) x \(image.height) sheet")
        }
        let fw = try size(arguments.frameWidth, arguments.columns, image.width, "width")
        let fh = try size(arguments.frameHeight ?? (arguments.rows == nil ? arguments.frameWidth : nil), arguments.rows, image.height, "height")
        let slicing = PixelSheetSlicing(frameWidth: fw, frameHeight: fh, margin: margin, spacing: spacing, frameCount: arguments.frames)
        let imported: (sprite: PixelSprite, report: PixelSprite.SheetImportReport)
        do {
            imported = try PixelSprite.importingSheet(
                image, slicing: slicing, palette: try arguments.palette.map(PixelSpriteArguments.palette),
                maxColors: arguments.maxColors ?? PixelSprite.maxColors,
                alphaThreshold: UInt8(min(max(arguments.alphaThreshold ?? 128, 0), 255)), duration: arguments.duration ?? 100)
        } catch let error as PixelSheetImportError {
            throw CommandError.failed("\(title): \(error)")
        }
        var sprite = imported.sprite
        let report = imported.report
        if let tags = arguments.tags { sprite.tags = tags }
        if let pivot = arguments.pivot { sprite.pivot = pivot }
        if let ppu = arguments.pixelsPerUnit { sprite.pixelsPerUnit = ppu }

        let id: AssetID
        var warnings = report.warnings
        if let into = arguments.into {
            (id, _) = try session.resolvePixelSprite(PixelSpriteGetCommand.Arguments(path: into), title)
            warnings += try session.commands.require(session.applyPixelSprite(sprite, to: id, label: title), title)
        } else {
            id = try session.commands.require(session.createPixelSpriteAsset(
                in: arguments.folder ?? suggested.folder, name: arguments.name ?? suggested.name, sprite: sprite), title)
        }
        var result = PixelSpriteResult(id, sprite, warnings: warnings, full: false, previewFrame: 0, in: session)
        result.sheet = .init(columns: report.columns, rows: report.rows, colorsFound: report.colorsFound, quantized: report.quantized)
        return result
    }
}
