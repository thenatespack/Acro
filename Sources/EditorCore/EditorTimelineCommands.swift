import Engine
import Foundation

/// The timeline builder tools: `timeline.new`, `timeline.get`, `timeline.set`, `timeline.edit`,
/// `timeline.sample`, `timeline.open`.
@MainActor
public enum EditorTimelineCommands {
    public static let all: [any EditorCommand.Type] = [
        TimelineNewCommand.self,
        TimelineGetCommand.self,
        TimelineSetCommand.self,
        TimelineEditCommand.self,
        TimelineSampleCommand.self,
        TimelineOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A timeline is a cutscene: `duration` (seconds), `loop`, `skippable`, `holdFade` (keep the last fade on screen after \
        the end; default it clears) and `tracks`. Each track: id (unique), kind \
        (camera | transform | animation | audio | particles | fade | event | dialogue), name, target (an entity Name or "Parent/Child" \
        path; empty = the active camera for camera tracks, unpositioned for audio, the world origin for particles, else the \
        entity holding the TimelinePlayer), muted, keys. Every key has `time` (s); continuous kinds blend from the previous key \
        with this key's `easing` (\(Easing.allCases.prefix(7).map(\.rawValue).joined(separator: ", ")), … default linear) \
        unless `cut` is true. camera keys: position [x,y,z], lookAt [x,y,z] | lookAtEntity "Name" | rotation [x,y,z] degrees, \
        fov (degrees; positions and aims are world space, also for a parented camera), cut, path [[x,y,z]…] (spline through position, these points and the next key's position until the next \
        key, constant speed), followPath (face the travel direction). transform keys: position, rotation (degrees), scale, cut. \
        animation keys: clip (Animator state or SpriteAnimator clip), blend (crossfade s), speed. audio keys: clip (audio file \
        or .sfx: path under Assets/ or asset:<id>), volume, pitch, loop, duration (s), position (offset). particles keys: effect \
        (.vfx or prefab path), duration (s; default the .vfx's), position, rotation. fade keys: amount (0 clear … 1 solid), \
        color [r,g,b] sRGB. event keys: name, value (game code reads TimelinePlayer.events / world.timelineEvents()). dialogue \
        keys: start the target's DialoguePlayer (or its first descendant's) conversation, or `dialogue` (a .dialogue file path or \
        asset:<id>) instead; node (start node), wait (hold the timeline until the conversation ends). Every key is optional. A TimelinePlayer component (timeline: the file's asset:<id> or path, playOnStart, speed, loop) plays it.
        """
}

extension EditorSession {
    /// Writes a timeline to "`name`.timeline" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createTimelineAsset(in folder: String, name: String = "New Timeline", timeline: Timeline = .starter()) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Timeline") else {
            log.error("New Timeline: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".timeline"))
        do {
            let id = try assets.createTimeline(timeline, at: path)
            log.info("Created timeline \(path)")
            return id
        } catch {
            log.error("New Timeline failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.timeline` file.
    public func isTimelineFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == TimelineImporter().name
    }

    /// Replaces the contents of the timeline `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyTimeline(_ timeline: Timeline, to id: AssetID, label: String = "Edit Timeline") -> [String]? {
        guard let assets, let old = assets.timeline(of: id) else {
            log.error("\(label): \(id) isn't a readable .timeline file")
            return nil
        }
        guard old != timeline else { return [] }
        let command = TimelineFileEditCommand(asset: id, old: old, new: timeline, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// Adds an entity named `name` with a `TimelinePlayer` for `id` to the scene (one undo step) and selects it.
    @discardableResult
    public func addTimelinePlayer(for id: AssetID, name: String? = nil, playOnStart: Bool = true) -> EntityID? {
        let stem = ((assets?.path(of: id) ?? "Timeline") as NSString).lastPathComponent
        let title = name ?? (stem as NSString).deletingPathExtension
        do {
            let command = try SpawnCommand(components: [Transform(), TimelinePlayer(timeline: AssetReference(id).description, playOnStart: playOnStart)],
                                           name: title, in: world, label: "Add Timeline Player")
            guard perform(command) else { return nil }
            selection.set(command.rootIDs)
            return command.rootIDs.first
        } catch {
            log.error("Add Timeline Player failed: \(error)")
            return nil
        }
    }
}

/// Makes timeline edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct TimelineFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: Timeline
    public let new: Timeline
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: Timeline, new: Timeline, in database: AssetDatabase, label: String = "Edit Timeline") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ timeline: Timeline) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeTimeline(timeline, to: asset)
    }
}

/// Arguments naming a `.timeline` file.
public protocol TimelineTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    func resolveTimeline(_ target: some TimelineTarget, _ title: String) throws -> (AssetID, Timeline) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isTimelineFile(id), let timeline = assets?.timeline(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .timeline file")
        }
        return (id, timeline)
    }
}

/// What the editing tools return.
public struct TimelineResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// What a `TimelinePlayer.timeline` field takes ("asset:<id>").
    public var key: String
    public var duration: Float
    /// Track ids in file order, with their kind and key count ("cam (camera, 3 keys)").
    public var tracks: [String]
    /// Problems (missing sounds and effects, keys past the end, unknown kinds…).
    public var warnings: [String]
    /// The entity with the TimelinePlayer (timeline.new with `place`).
    public var player: EntityID?
}

extension TimelineResult {
    @MainActor init(_ id: AssetID, _ timeline: Timeline, player: EntityID? = nil, in session: EditorSession) {
        let record = session.assets?.record(id)
        let problems = session.assets?.timelineProblems(timeline) ?? TimelineCheck.problems(timeline)
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", key: AssetReference(id).description, duration: timeline.duration,
                  tracks: timeline.tracks.map { "\($0.id) (\($0.kind), \($0.keys.count) key\($0.keys.count == 1 ? "" : "s"))" },
                  warnings: problems + (record?.importError.map { ["import failed: \($0)"] } ?? []), player: player)
    }
}

public enum TimelineNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Timeline" (the file gets ".timeline").
        public var name: String?
        /// Seconds (default 10). The starter is a camera track with a two-key dolly over it.
        public var duration: Float?
        /// The contents instead of the starter.
        public var timeline: Timeline?
        /// Also add an entity with a TimelinePlayer for it to the scene (undoable).
        public var place: Bool?
        public init(folder: String? = nil, name: String? = nil, duration: Float? = nil, timeline: Timeline? = nil, place: Bool? = nil) {
            self.folder = folder
            self.name = name
            self.duration = duration
            self.timeline = timeline
            self.place = place
        }
    }

    public static let id: CommandID = "timeline.new"
    public static let title = "New Timeline"
    public static let doc = "Writes a .timeline file (a cutscene) in `folder` (default: the Assets root) and imports it: the given `timeline`, else a starter of `duration` seconds with a camera track. `place` also adds an entity with a TimelinePlayer to the scene. Returns the asset, its key for TimelinePlayer.timeline, the tracks and problems. Change it with timeline.edit (tracks and keys) or timeline.set. " + EditorTimelineCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TimelineResult {
        var timeline = arguments.timeline ?? .starter(duration: arguments.duration ?? 10)
        if arguments.timeline != nil, let duration = arguments.duration { timeline.duration = duration }
        timeline = timeline.normalized()
        let id = try session.commands.require(session.createTimelineAsset(in: arguments.folder ?? "", name: arguments.name ?? "New Timeline",
                                                                          timeline: timeline), title)
        var player: EntityID?
        if arguments.place == true { player = try session.commands.require(session.addTimelinePlayer(for: id), title) }
        return TimelineResult(id, timeline, player: player, in: session)
    }
}

public enum TimelineGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TimelineTarget {
        /// The .timeline file.
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
        public var key: String
        public var timeline: Timeline
        public var warnings: [String]
    }

    public static let id: CommandID = "timeline.get"
    public static let title = "Get Timeline"
    public static let doc = "Reads a .timeline file: duration, loop, skippable and every track with its keys (only the fields set), its key for TimelinePlayer.timeline and problems found."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, timeline) = try session.resolveTimeline(arguments, title)
        let summary = TimelineResult(id, timeline, in: session)
        return Result(asset: id, path: summary.path, key: summary.key, timeline: timeline, warnings: summary.warnings)
    }
}

public enum TimelineSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TimelineTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var timeline: Timeline
        public init(asset: AssetReference? = nil, path: String? = nil, timeline: Timeline) {
            self.asset = asset
            self.path = path
            self.timeline = timeline
        }
    }

    public static let id: CommandID = "timeline.set"
    public static let title = "Set Timeline"
    public static let doc = "Replaces a .timeline file's whole contents (keys are sorted by time) and reimports it; playing TimelinePlayers pick it up. Undoable. For a few changes, timeline.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TimelineResult {
        let (id, _) = try session.resolveTimeline(arguments, title)
        let timeline = arguments.timeline.normalized()
        _ = try session.commands.require(session.applyTimeline(timeline, to: id, label: title), title)
        return TimelineResult(id, timeline, in: session)
    }
}

/// A key to add with timeline.edit: the key's fields plus the track it goes on.
public struct TimelineKeyAddition: Codable, Equatable, Sendable {
    public var track: String
    public var key: TimelineKey

    public init(track: String, key: TimelineKey) {
        self.track = track
        self.key = key
    }

    private enum CodingKeys: String, CodingKey { case track }

    public init(from decoder: any Decoder) throws {
        track = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .track)
        key = try TimelineKey(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        try key.encode(to: encoder)
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(track, forKey: .track)
    }
}

/// A key named by its track and its time (or its index in the track).
public struct TimelineKeyReference: Codable, Equatable, Sendable {
    public var track: String
    public var time: Float?
    public var index: Int?

    public init(track: String, time: Float? = nil, index: Int? = nil) {
        self.track = track
        self.time = time
        self.index = index
    }
}

/// Field changes for one key (timeline.edit `updateKeys`).
public struct TimelineKeyUpdate: Codable, Equatable, Sendable {
    public var track: String
    public var time: Float?
    public var index: Int?
    /// The fields to change, e.g. {"position": [0, 2, 4], "easing": "cubicOut"}; null clears a field.
    public var set: [String: JSONValue]

    public init(track: String, time: Float? = nil, index: Int? = nil, set: [String: JSONValue]) {
        self.track = track
        self.time = time
        self.index = index
        self.set = set
    }
}

public enum TimelineEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TimelineTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Tracks to remove by id.
        public var removeTracks: [String]?
        /// Tracks to add (an id already taken gets " 2"…; the result lists the final ids).
        public var addTracks: [TimelineTrack]?
        /// Changes to tracks: id → fields, e.g. {"cam": {"target": "Cutscene Camera", "muted": false}}. "id" renames.
        public var updateTracks: [String: JSONValue]?
        /// Keys to remove: {track, time} (within 0.5 ms) or {track, index}.
        public var removeKeys: [TimelineKeyReference]?
        /// Keys to add: the key's fields plus "track", e.g. {"track": "cam", "time": 2, "position": [0, 2, 5]}. A key
        /// already at that time on the track is replaced.
        public var addKeys: [TimelineKeyAddition]?
        /// Field changes for keys: {track, time | index, set: {field: value}}.
        public var updateKeys: [TimelineKeyUpdate]?
        public var duration: Float?
        public var loop: Bool?
        public var skippable: Bool?
        /// Keep the last screen fade on screen after the end (default: it clears).
        public var holdFade: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, removeTracks: [String]? = nil, addTracks: [TimelineTrack]? = nil,
                    updateTracks: [String: JSONValue]? = nil, removeKeys: [TimelineKeyReference]? = nil,
                    addKeys: [TimelineKeyAddition]? = nil, updateKeys: [TimelineKeyUpdate]? = nil, duration: Float? = nil,
                    loop: Bool? = nil, skippable: Bool? = nil, holdFade: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.removeTracks = removeTracks
            self.addTracks = addTracks
            self.updateTracks = updateTracks
            self.removeKeys = removeKeys
            self.addKeys = addKeys
            self.updateKeys = updateKeys
            self.duration = duration
            self.loop = loop
            self.skippable = skippable
            self.holdFade = holdFade
        }
    }

    public static let id: CommandID = "timeline.edit"
    public static let title = "Edit Timeline"
    public static let doc = "Changes part of a .timeline file in one undoable step, in this order: removeTracks, addTracks, updateTracks (id → fields; \"id\" renames), removeKeys ({track, time | index}), addKeys (key fields plus \"track\"; replaces a key at the same time), updateKeys ({track, time | index, set: {field: value, …}}), then duration / loop / skippable / holdFade. Keys are kept sorted by time. Returns the tracks and problems (e.g. a sound that doesn't exist)."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> TimelineResult {
        let (id, original) = try session.resolveTimeline(arguments, title)
        let timeline = try edited(original, with: arguments)
        _ = try session.commands.require(session.applyTimeline(timeline, to: id, label: title), title)
        return TimelineResult(id, timeline, in: session)
    }

    /// `timeline` with the edits of `arguments` applied (pure, for tests and the UI).
    public static func edited(_ timeline: Timeline, with arguments: Arguments) throws -> Timeline {
        var timeline = timeline
        if let ids = arguments.removeTracks, !ids.isEmpty {
            let missing = ids.filter { timeline.track(id: $0) == nil }
            guard missing.isEmpty else { throw CommandError.failed("No track \(missing.joined(separator: ", "))") }
            timeline.tracks.removeAll { ids.contains($0.id) }
        }
        for var track in arguments.addTracks ?? [] {
            guard track.trackKind != nil else {
                throw CommandError.failed("Track '\(track.id)': unknown kind '\(track.kind)' (use \(TimelineTrackKind.allCases.map(\.rawValue).joined(separator: ", ")))")
            }
            track.id = timeline.uniqueTrackID(track.id)
            timeline.tracks.append(track)
        }
        for (trackID, changes) in (arguments.updateTracks ?? [:]).sorted(by: { $0.key < $1.key }) {
            let index = try trackIndex(trackID, in: timeline)
            guard case .object(let fields) = changes else { throw CommandError.failed("updateTracks[\(trackID)] must be an object of fields") }
            let updated: TimelineTrack = try merged(timeline.tracks[index], fields, "updateTracks[\(trackID)]")
            if updated.id != trackID, timeline.track(id: updated.id) != nil { throw CommandError.failed("A track is already named \(updated.id)") }
            timeline.tracks[index] = updated
        }
        // Removals by index refer to the order before any removal.
        var removals: [Int: Set<Int>] = [:]
        for reference in arguments.removeKeys ?? [] {
            let t = try trackIndex(reference.track, in: timeline)
            removals[t, default: []].insert(try keyIndex(reference.track, reference.time, reference.index, in: timeline.tracks[t]))
        }
        for (t, indices) in removals {
            timeline.tracks[t].keys = timeline.tracks[t].keys.enumerated().filter { !indices.contains($0.offset) }.map(\.element)
        }
        for addition in arguments.addKeys ?? [] {
            let t = try trackIndex(addition.track, in: timeline)
            if let existing = timeline.tracks[t].keyIndex(at: addition.key.time) {
                timeline.tracks[t].keys[existing] = addition.key
            } else {
                timeline.tracks[t].keys.append(addition.key)
            }
            timeline.tracks[t].keys.sort { $0.time < $1.time }
        }
        for update in arguments.updateKeys ?? [] {
            let t = try trackIndex(update.track, in: timeline)
            let k = try keyIndex(update.track, update.time, update.index, in: timeline.tracks[t])
            timeline.tracks[t].keys[k] = try merged(timeline.tracks[t].keys[k], update.set, "updateKeys[\(update.track)]")
        }
        if let duration = arguments.duration { timeline.duration = duration }
        if let loop = arguments.loop { timeline.loop = loop }
        if let skippable = arguments.skippable { timeline.skippable = skippable }
        if let holdFade = arguments.holdFade { timeline.holdFade = holdFade }
        return timeline.normalized()
    }

    static func trackIndex(_ id: String, in timeline: Timeline) throws -> Int {
        guard let index = timeline.trackIndex(id: id) else {
            throw CommandError.failed("No track '\(id)' (tracks: \(timeline.tracks.map(\.id).joined(separator: ", ")))")
        }
        return index
    }

    static func keyIndex(_ track: String, _ time: Float?, _ index: Int?, in t: TimelineTrack) throws -> Int {
        if let index {
            guard t.keys.indices.contains(index) else { throw CommandError.failed("Track '\(track)' has no key \(index) (\(t.keys.count) keys)") }
            return index
        }
        guard let time else { throw CommandError.failed("Name a key of track '\(track)' by time or index") }
        guard let found = t.keyIndex(at: time) else {
            throw CommandError.failed("Track '\(track)' has no key at \(time) s (keys at \(t.keys.map { String(format: "%g", $0.time) }.joined(separator: ", ")))")
        }
        return found
    }

    /// `value` with `fields` written over its JSON (null removes a field).
    static func merged<T: Codable>(_ value: T, _ fields: [String: JSONValue], _ label: String) throws -> T {
        guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) else { return value }
        for (key, value) in fields {
            if case .null = value { current[key] = nil } else { current[key] = value }
        }
        do { return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
            throw CommandError.failed("\(label): \(error)")
        }
    }
}

public enum TimelineSampleCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TimelineTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Seconds from the start.
        public var time: Float
        public init(asset: AssetReference? = nil, path: String? = nil, time: Float) {
            self.asset = asset
            self.path = path
            self.time = time
        }
    }

    public struct TrackSample: Codable, Equatable, Sendable {
        public var track: String
        public var kind: String
        public var target: String
        public var position: Vec3?
        /// Euler degrees.
        public var rotation: Vec3?
        public var scale: Vec3?
        /// Camera tracks: vertical field of view, degrees.
        public var fov: Float?
        /// Fade tracks.
        public var fadeAmount: Float?
        public var fadeColor: Vec3?
        /// Whether the target exists in the open scene ("" targets: the default one).
        public var targetFound: Bool
    }

    public struct Result: Codable, Equatable, Sendable {
        public var time: Float
        /// Continuous tracks posed at `time`.
        public var tracks: [TrackSample]
        /// Discrete keys at or before `time` (what playback from the start has fired by then): "track @time: summary".
        public var fired: [String]
    }

    public static let id: CommandID = "timeline.sample"
    public static let title = "Sample Timeline"
    public static let doc = "Evaluates a .timeline at `time` seconds without playing it: each camera / transform / fade track's position, rotation (degrees), scale, fov and fade there (look-at entities resolve in the open scene), and the animation / audio / particles / event keys fired by then. Use it to check a camera move or timing."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (_, file) = try session.resolveTimeline(arguments, title)
        let timeline = file.normalized()
        let time = min(max(arguments.time, 0), timeline.duration)
        let world = session.world
        var samples: [TrackSample] = []
        for track in timeline.tracks where !track.muted {
            guard let kind = track.trackKind, kind.isContinuous else { continue }
            let found = track.target.isEmpty || TimelineEvaluator.find(track.target, in: world) != nil
            var sample = TrackSample(track: track.id, kind: track.kind, target: track.target, targetFound: found)
            switch kind {
            case .camera:
                let pose = TimelineEvaluator.cameraPose(track, at: time, in: world)
                sample.position = pose.position
                sample.rotation = pose.rotation?.eulerDegrees
                sample.fov = pose.fovDegrees
            case .transform:
                sample.position = track.vec3(\.position, at: time)
                sample.rotation = track.rotation(at: time)?.eulerDegrees
                sample.scale = track.vec3(\.scale, at: time)
            case .fade:
                let fade = track.fade(at: time)
                sample.fadeAmount = fade?.amount
                sample.fadeColor = fade?.color
            default:
                break
            }
            samples.append(sample)
        }
        let fired = timeline.firedKeys(from: nil, to: time).map { t, k -> String in
            let track = timeline.tracks[t]
            let key = track.keys[k]
            return "\(track.id) @\(String(format: "%g", key.time)): \(key.summary(kind: track.trackKind))"
        }
        return Result(time: time, tracks: samples, fired: fired)
    }
}

public enum TimelineOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, TimelineTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "timeline.open"
    public static let title = "Open in Timeline"
    public static let doc = "Opens a .timeline file in the editor's Timeline tab (a preview of the open scene posed by the timeline, seen through its camera, with transport, scrubbing, the track strip and the key form) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"timeline\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveTimeline(arguments, title)
        session.openTimeline = id
        session.onOpenTimeline?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
