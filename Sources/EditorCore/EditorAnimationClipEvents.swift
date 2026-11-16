import Engine
import Foundation

// Editing the events of imported clips (Animation Graph Builder): glTF files have no events, so
// a model's clip events live in its import settings (`GLTFImporter.Settings.clipEvents`) and
// the importer adds them to the clips. `animGraph.clipEvents` reads them,
// `animGraph.setClipEvents` replaces them (undoable), and the tab edits the selected state's.

extension EditorSession {
    /// The model and clip sub-asset of `key` when its events can be edited: a clip imported from
    /// a glTF file (`asset:<id>#animation/<name>`, or the file's first clip for a whole-file key).
    public func editableClip(_ key: String) -> (model: AssetID, clip: SubAssetID)? {
        guard let assets, let reference = AssetReference(assets.normalizedAssetKey(key)),
              let record = assets.record(reference.asset), record.importer == GLTFImporter().name else { return nil }
        let clip = reference.subAsset ?? record.objects.first { $0.kind == .animation }?.id
        guard let clip, record.objects.contains(where: { $0.id == clip && $0.kind == .animation }) else { return nil }
        return (reference.asset, clip)
    }

    /// The events of the clip `key` (sorted by time); nil when there is no such clip.
    public func clipEvents(_ key: String) -> [AnimationEvent]? {
        guard let assets, let reference = AssetReference(assets.normalizedAssetKey(key)) else { return nil }
        return assets.animationClip(reference)?.events
    }

    /// Replaces the events of the imported clip `key` as one undo step and reimports its model.
    @discardableResult
    public func setClipEvents(_ events: [AnimationEvent], of key: String, label: String = "Edit Clip Events") -> Bool {
        guard let assets, let (model, clip) = editableClip(key),
              let old = assets.settings(of: model, as: GLTFImporter.Settings.self) else {
            log.error("\(label): '\(key)' isn't a clip of an imported glTF model")
            return false
        }
        var new = old
        let sorted = events.sorted { $0.time < $1.time }
        new.clipEvents[clip] = sorted.isEmpty ? nil : sorted
        guard new != old else { return true }
        return perform(ClipEventsEditCommand(asset: model, old: old, new: new, in: assets, label: label))
    }
}

/// Makes clip event edits undoable: writes the model's import settings and reimports it.
public struct ClipEventsEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: GLTFImporter.Settings
    public let new: GLTFImporter.Settings
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: GLTFImporter.Settings, new: GLTFImporter.Settings, in database: AssetDatabase,
                label: String = "Edit Clip Events") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ settings: GLTFImporter.Settings) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        try database.setSettings(settings, for: asset)
    }
}

/// What the clip event tools return.
public struct ClipEventsResult: Codable, Equatable, Sendable {
    /// The clip, as an asset reference.
    public var clip: String
    /// Seconds.
    public var duration: Float
    public var events: [AnimationEvent]
    /// Whether animGraph.setClipEvents can change them (clips imported from glTF files).
    public var editable: Bool
}

extension ClipEventsResult {
    @MainActor init(_ key: String, in session: EditorSession) throws {
        guard let assets = session.assets, let reference = AssetReference(assets.normalizedAssetKey(key)),
              let clip = assets.animationClip(reference) else { throw CommandError.failed("No clip '\(key)'") }
        self.init(clip: reference.description, duration: clip.duration, events: clip.events, editable: session.editableClip(key) != nil)
    }
}

public enum AnimGraphClipEventsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The clip: an asset reference or path ("Models/hero.glb#animation/Walk").
        public var clip: String
        public init(clip: String) { self.clip = clip }
    }

    public static let id: CommandID = "animGraph.clipEvents"
    public static let title = "Get Clip Events"
    public static let doc = "Lists an animation clip's events ({time (seconds), name}, by time) and its duration. Animators report events as their clip plays past them (FiredAnimationEvent, VisualScript animation events); `editable` says whether animGraph.setClipEvents can change them."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ClipEventsResult {
        try ClipEventsResult(arguments.clip, in: session)
    }
}

public enum AnimGraphSetClipEventsCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The clip: an asset reference or path of a glTF clip ("Models/hero.glb#animation/Walk").
        public var clip: String
        /// The new events, replacing the old ones: [{time (seconds from the clip's start), name}]. Empty removes them all.
        public var events: [AnimationEvent]
        public init(clip: String, events: [AnimationEvent]) {
            self.clip = clip
            self.events = events
        }
    }

    public static let id: CommandID = "animGraph.setClipEvents"
    public static let title = "Set Clip Events"
    public static let doc = "Replaces the events of a clip imported from a glTF file ({time, name}; footsteps, hits, sounds). They are kept in the model's import settings, so they survive reimports and apply wherever the clip plays. Undoable. Times outside the clip are clamped to it."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> ClipEventsResult {
        guard session.editableClip(arguments.clip) != nil else {
            throw CommandError.failed("\(title): '\(arguments.clip)' isn't a clip of an imported glTF model")
        }
        let duration = try ClipEventsResult(arguments.clip, in: session).duration
        for event in arguments.events where event.name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw CommandError.failed("\(title): an event at \(event.time) s has no name")
        }
        let events = arguments.events.map { AnimationEvent(time: min(max($0.time, 0), duration), name: $0.name) }
        try session.commands.check(session.setClipEvents(events, of: arguments.clip, label: title), title)
        return try ClipEventsResult(arguments.clip, in: session)
    }
}
