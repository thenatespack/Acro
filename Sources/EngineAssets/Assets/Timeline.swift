import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// `.timeline` files: sequenced cutscenes (JSON, every key optional). A timeline has a
// `duration` and `tracks`; each track has a `kind`, a `target` entity (by name or "Parent/Child"
// path) and `keys` at times in seconds. Continuous tracks (camera, transform, fade) blend
// between keys with the later key's `easing`; discrete tracks (animation, audio, particles,
// event) fire each key once when playback passes its time.
//
// {"duration": 8, "tracks": [
//   {"id": "cam", "kind": "camera", "keys": [
//     {"time": 0, "position": [0, 2, 10], "lookAt": [0, 1, 0], "fov": 50},
//     {"time": 4, "position": [6, 3, 4], "lookAt": [0, 1, 0], "easing": "cubicInOut"},
//     {"time": 4.01, "position": [0, 1.6, 2], "rotation": [0, 0, 0], "cut": true}]},
//   {"id": "boom", "kind": "particles", "keys": [{"time": 2, "effect": "FX/Explosion.vfx", "position": [0, 1, 0]}]},
//   {"id": "fade", "kind": "fade", "keys": [{"time": 7, "amount": 0}, {"time": 8, "amount": 1, "color": [0, 0, 0]}]},
//   {"id": "done", "kind": "event", "keys": [{"time": 8, "name": "introDone"}]}]}
//
// `TimelinePlayer` (EngineRendering) plays one at runtime; the Timeline Builder tab edits it.

/// What a track drives. Stored as a string in the file, so files from a newer engine with more
/// kinds still load (unknown kinds are reported and skipped).
public enum TimelineTrackKind: String, Codable, CaseIterable, Sendable {
    /// Moves a camera: position, aim (`lookAt`, `lookAtEntity` or `rotation`), field of view,
    /// cuts and spline moves (`path`, played with `CameraPath`'s spline).
    case camera
    /// Moves an entity: position, rotation, scale in its parent's space.
    case transform
    /// Plays an `Animator` state or `SpriteAnimator` clip (`clip`) on the target.
    case animation
    /// Plays a sound (`clip`: an audio file or `.sfx`) at the target, or unpositioned without one.
    case audio
    /// Spawns an effect (`effect`: a `.vfx` or other prefab) at the target for `duration` seconds.
    case particles
    /// Fades the screen to `color` by `amount` (0 clear, 1 solid).
    case fade
    /// Fires a named event (`name`, `value`) for game code.
    case event

    /// Kinds whose keys blend over time (the rest fire once per key).
    public var isContinuous: Bool { self == .camera || self == .transform || self == .fade }

    public var title: String {
        switch self {
        case .camera: "Camera"
        case .transform: "Transform"
        case .animation: "Animation"
        case .audio: "Audio"
        case .particles: "Particles"
        case .fade: "Screen Fade"
        case .event: "Event"
        }
    }

    /// The key fields this kind reads (besides `time`).
    public var keyFields: [String] {
        switch self {
        case .camera: ["easing", "position", "lookAt", "lookAtEntity", "rotation", "fov", "cut", "path", "followPath"]
        case .transform: ["easing", "position", "rotation", "scale", "cut"]
        case .animation: ["clip", "blend", "speed"]
        case .audio: ["clip", "volume", "pitch", "loop", "duration", "position"]
        case .particles: ["effect", "duration", "position", "rotation"]
        case .fade: ["easing", "amount", "color", "cut"]
        case .event: ["name", "value"]
        }
    }
}

/// One key of a track. Every field but `time` is optional and only the fields of the track's
/// kind are read (see `TimelineTrackKind.keyFields`), so one shape serves all kinds.
public struct TimelineKey: Codable, Equatable, Sendable {
    /// Seconds from the start.
    public var time: Float
    /// The curve from the previous key to this one (continuous tracks; default linear).
    public var easing: Easing?
    /// Camera / transform: position (parent space). Audio / particles: offset from the target.
    public var position: Vec3?
    /// Camera / transform / particles: rotation as Euler angles in degrees.
    public var rotation: Vec3?
    /// Transform: scale.
    public var scale: Vec3?
    /// Camera: aim at this world point (wins over `rotation`).
    public var lookAt: Vec3?
    /// Camera: aim at this entity, by name or path (wins over `lookAt`).
    public var lookAtEntity: String?
    /// Camera: vertical field of view in degrees.
    public var fov: Float?
    /// Camera / transform / fade: jump to this key at its time instead of blending from the previous one.
    public var cut: Bool?
    /// Camera: travel along a smooth spline through `position`, these points and the next key's
    /// position, from this key's time to the next key's.
    public var path: [Vec3]?
    /// Camera: while on a `path`, face the direction of travel (when there's no look-at).
    public var followPath: Bool?
    /// Animation: the `Animator` state or `SpriteAnimator` clip. Audio: the sound, a path under
    /// `Assets/` or "asset:<id>" (audio file or `.sfx`).
    public var clip: String?
    /// Animation: crossfade seconds (default 0.25).
    public var blend: Float?
    /// Animation: playback speed multiplier.
    public var speed: Float?
    /// Audio: gain (default 1).
    public var volume: Float?
    /// Audio: pitch multiplier (default 1).
    public var pitch: Float?
    /// Audio: repeat until `duration` ends (or the timeline stops).
    public var loop: Bool?
    /// Audio: seconds before the sound is stopped (none: until it ends). Particles: seconds the
    /// effect lives (none: the `.vfx` file's duration).
    public var duration: Float?
    /// Particles: the effect, a `.vfx` (or any prefab asset) path under `Assets/` or "asset:<id>".
    public var effect: String?
    /// Fade: 0 = clear, 1 = solid `color`.
    public var amount: Float?
    /// Fade: sRGB color (default black).
    public var color: Vec3?
    /// Event: its name.
    public var name: String?
    /// Event: an optional payload.
    public var value: String?

    public init(time: Float = 0, easing: Easing? = nil, position: Vec3? = nil, rotation: Vec3? = nil, scale: Vec3? = nil,
                lookAt: Vec3? = nil, lookAtEntity: String? = nil, fov: Float? = nil, cut: Bool? = nil, path: [Vec3]? = nil,
                followPath: Bool? = nil, clip: String? = nil, blend: Float? = nil, speed: Float? = nil, volume: Float? = nil,
                pitch: Float? = nil, loop: Bool? = nil, duration: Float? = nil, effect: String? = nil, amount: Float? = nil,
                color: Vec3? = nil, name: String? = nil, value: String? = nil) {
        self.time = time
        self.easing = easing
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.lookAt = lookAt
        self.lookAtEntity = lookAtEntity
        self.fov = fov
        self.cut = cut
        self.path = path
        self.followPath = followPath
        self.clip = clip
        self.blend = blend
        self.speed = speed
        self.volume = volume
        self.pitch = pitch
        self.loop = loop
        self.duration = duration
        self.effect = effect
        self.amount = amount
        self.color = color
        self.name = name
        self.value = value
    }

    private enum CodingKeys: String, CodingKey {
        case time, easing, position, rotation, scale, lookAt, lookAtEntity, fov, cut, path, followPath, clip, blend, speed
        case volume, pitch, loop, duration, effect, amount, color, name, value
    }

    /// Every key is optional (`time` defaults to 0).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(time: try c.decodeIfPresent(Float.self, forKey: .time) ?? 0)
        easing = try c.decodeIfPresent(Easing.self, forKey: .easing)
        position = try c.decodeIfPresent(Vec3.self, forKey: .position)
        rotation = try c.decodeIfPresent(Vec3.self, forKey: .rotation)
        scale = try c.decodeIfPresent(Vec3.self, forKey: .scale)
        lookAt = try c.decodeIfPresent(Vec3.self, forKey: .lookAt)
        lookAtEntity = try c.decodeIfPresent(String.self, forKey: .lookAtEntity)
        fov = try c.decodeIfPresent(Float.self, forKey: .fov)
        cut = try c.decodeIfPresent(Bool.self, forKey: .cut)
        path = try c.decodeIfPresent([Vec3].self, forKey: .path)
        followPath = try c.decodeIfPresent(Bool.self, forKey: .followPath)
        clip = try c.decodeIfPresent(String.self, forKey: .clip)
        blend = try c.decodeIfPresent(Float.self, forKey: .blend)
        speed = try c.decodeIfPresent(Float.self, forKey: .speed)
        volume = try c.decodeIfPresent(Float.self, forKey: .volume)
        pitch = try c.decodeIfPresent(Float.self, forKey: .pitch)
        loop = try c.decodeIfPresent(Bool.self, forKey: .loop)
        duration = try c.decodeIfPresent(Float.self, forKey: .duration)
        effect = try c.decodeIfPresent(String.self, forKey: .effect)
        amount = try c.decodeIfPresent(Float.self, forKey: .amount)
        color = try c.decodeIfPresent(Vec3.self, forKey: .color)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        value = try c.decodeIfPresent(String.self, forKey: .value)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(time, forKey: .time)
        try c.encodeIfPresent(easing, forKey: .easing)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(rotation, forKey: .rotation)
        try c.encodeIfPresent(scale, forKey: .scale)
        try c.encodeIfPresent(lookAt, forKey: .lookAt)
        try c.encodeIfPresent(lookAtEntity, forKey: .lookAtEntity)
        try c.encodeIfPresent(fov, forKey: .fov)
        try c.encodeIfPresent(cut, forKey: .cut)
        try c.encodeIfPresent(path, forKey: .path)
        try c.encodeIfPresent(followPath, forKey: .followPath)
        try c.encodeIfPresent(clip, forKey: .clip)
        try c.encodeIfPresent(blend, forKey: .blend)
        try c.encodeIfPresent(speed, forKey: .speed)
        try c.encodeIfPresent(volume, forKey: .volume)
        try c.encodeIfPresent(pitch, forKey: .pitch)
        try c.encodeIfPresent(loop, forKey: .loop)
        try c.encodeIfPresent(duration, forKey: .duration)
        try c.encodeIfPresent(effect, forKey: .effect)
        try c.encodeIfPresent(amount, forKey: .amount)
        try c.encodeIfPresent(color, forKey: .color)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(value, forKey: .value)
    }

    /// A short description for lists and the timeline strip.
    public func summary(kind: TimelineTrackKind?) -> String {
        switch kind {
        case .animation: return clip ?? "(no clip)"
        case .audio: return ((clip ?? "(no sound)") as NSString).lastPathComponent
        case .particles: return ((effect ?? "(no effect)") as NSString).lastPathComponent
        case .event: return name ?? "(unnamed)"
        case .fade: return String(format: "%.0f%%", (amount ?? 0) * 100)
        case .camera: return cut == true ? "cut" : (path != nil ? "path" : "")
        default: return ""
        }
    }
}

/// One track of a timeline.
public struct TimelineTrack: Codable, Equatable, Sendable {
    /// Unique in the timeline; tools name tracks by it.
    public var id: String
    /// A `TimelineTrackKind` raw value (kept as written, so unknown kinds survive a round trip).
    public var kind: String
    /// Display name ("" shows the id).
    public var name: String
    /// The entity it drives, by `Name` or a "Parent/Child" path. Empty: the active camera
    /// (camera), unpositioned (audio), the world origin (particles), else the entity holding the
    /// `TimelinePlayer`.
    public var target: String
    /// Muted tracks are skipped.
    public var muted: Bool
    /// Keys in time order (`Timeline.normalized()` sorts them).
    public var keys: [TimelineKey]

    public init(id: String, kind: TimelineTrackKind, name: String = "", target: String = "", muted: Bool = false,
                keys: [TimelineKey] = []) {
        self.init(id: id, kindName: kind.rawValue, name: name, target: target, muted: muted, keys: keys)
    }

    public init(id: String, kindName: String, name: String = "", target: String = "", muted: Bool = false, keys: [TimelineKey] = []) {
        self.id = id
        self.kind = kindName
        self.name = name
        self.target = target
        self.muted = muted
        self.keys = keys
    }

    public var trackKind: TimelineTrackKind? { TimelineTrackKind(rawValue: kind) }
    public var displayName: String { name.isEmpty ? id : name }

    private enum CodingKeys: String, CodingKey { case id, kind, name, target, muted, keys }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? TimelineTrackKind.event.rawValue
        self.init(id: try c.decodeIfPresent(String.self, forKey: .id) ?? kind, kindName: kind,
                  name: try c.decodeIfPresent(String.self, forKey: .name) ?? "",
                  target: try c.decodeIfPresent(String.self, forKey: .target) ?? "",
                  muted: try c.decodeIfPresent(Bool.self, forKey: .muted) ?? false,
                  keys: try c.decodeIfPresent([TimelineKey].self, forKey: .keys) ?? [])
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        if !name.isEmpty { try c.encode(name, forKey: .name) }
        if !target.isEmpty { try c.encode(target, forKey: .target) }
        if muted { try c.encode(muted, forKey: .muted) }
        try c.encode(keys, forKey: .keys)
    }

    /// The index of the key at `time` (within `tolerance` seconds), if any.
    public func keyIndex(at time: Float, tolerance: Float = 0.0005) -> Int? {
        keys.firstIndex { abs($0.time - time) <= tolerance }
    }
}

/// The contents of a `.timeline` file.
public struct Timeline: Codable, Equatable, Sendable {
    /// Seconds the timeline lasts.
    public var duration: Float
    /// Start over after `duration`.
    public var loop: Bool
    /// Whether `TimelinePlayer.skip()` may end it early.
    public var skippable: Bool
    public var tracks: [TimelineTrack]

    public init(duration: Float = 10, loop: Bool = false, skippable: Bool = true, tracks: [TimelineTrack] = []) {
        self.duration = duration
        self.loop = loop
        self.skippable = skippable
        self.tracks = tracks
    }

    private enum CodingKeys: String, CodingKey { case duration, loop, skippable, tracks }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Timeline()
        self.init(duration: try c.decodeIfPresent(Float.self, forKey: .duration) ?? d.duration,
                  loop: try c.decodeIfPresent(Bool.self, forKey: .loop) ?? d.loop,
                  skippable: try c.decodeIfPresent(Bool.self, forKey: .skippable) ?? d.skippable,
                  tracks: try c.decodeIfPresent([TimelineTrack].self, forKey: .tracks) ?? [])
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    /// A new timeline: `duration` seconds with a camera track holding a two-key dolly.
    public static func starter(duration: Float = 10) -> Timeline {
        let d = max(duration, 0.1)
        return Timeline(duration: d, tracks: [
            TimelineTrack(id: "camera", kind: .camera, name: "Camera", keys: [
                TimelineKey(time: 0, position: Vec3(0, 2, 10), lookAt: Vec3(0, 1, 0), fov: 50),
                TimelineKey(time: d, easing: .sineInOut, position: Vec3(4, 2.5, 6), lookAt: Vec3(0, 1, 0), fov: 50),
            ]),
        ])
    }

    public func trackIndex(id: String) -> Int? { tracks.firstIndex { $0.id == id } }
    public func track(id: String) -> TimelineTrack? { trackIndex(id: id).map { tracks[$0] } }

    /// A track id not used yet: `base`, else "`base` 2"…
    public func uniqueTrackID(_ base: String) -> String {
        let base = base.isEmpty ? "track" : base
        guard track(id: base) != nil else { return base }
        var n = 2
        while track(id: "\(base) \(n)") != nil { n += 1 }
        return "\(base) \(n)"
    }

    /// Keys sorted by time (stable), negative times clamped to 0 and the duration at least 0.1 s.
    public func normalized() -> Timeline {
        var copy = self
        copy.duration = max(duration.isFinite ? duration : 10, 0.1)
        for i in copy.tracks.indices {
            for k in copy.tracks[i].keys.indices where !(copy.tracks[i].keys[k].time >= 0) { copy.tracks[i].keys[k].time = 0 }
            copy.tracks[i].keys = copy.tracks[i].keys.enumerated()
                .sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }.map(\.element)
        }
        return copy
    }

    /// The (track, key) indices of discrete keys (animation, audio, particles, event) passed when
    /// playback moves from `from` (exclusive; nil: from before the start, so keys at 0 fire) to
    /// `to` (inclusive), in time order. Muted and unknown tracks are skipped. No wrapping.
    public func firedKeys(from: Float?, to: Float) -> [(track: Int, key: Int)] {
        var fired: [(track: Int, key: Int, time: Float)] = []
        for (t, track) in tracks.enumerated() {
            guard !track.muted, let kind = track.trackKind, !kind.isContinuous else { continue }
            for (k, key) in track.keys.enumerated() where key.time <= to && (from.map { key.time > $0 } ?? true) {
                fired.append((t, k, key.time))
            }
        }
        return fired.sorted { ($0.time, $0.track, $0.key) < ($1.time, $1.track, $1.key) }.map { ($0.track, $0.key) }
    }
}

// MARK: Sampling (pure)

/// How a continuous track blends between two keys at a moment.
public struct TimelineSpan: Equatable, Sendable {
    /// The key at or before the moment (the first key when before it).
    public var from: Int
    /// The key after it (== `from` when holding).
    public var to: Int
    /// Eased progress 0...1 from `from` to `to` (0 when holding).
    public var progress: Float
}

extension TimelineTrack {
    /// Between which keys that have the field `has` the moment `time` falls, and how far along
    /// (eased by the later key's `easing`; a later key with `cut` holds until its time). nil when
    /// no key has the field.
    public func span(at time: Float, where has: (TimelineKey) -> Bool) -> TimelineSpan? {
        let indices = keys.indices.filter { has(keys[$0]) }
        guard let first = indices.first else { return nil }
        guard time > keys[first].time else { return TimelineSpan(from: first, to: first, progress: 0) }
        var previous = first
        for i in indices.dropFirst() {
            let key = keys[i]
            if time < key.time {
                let a = keys[previous].time
                let length = key.time - a
                if key.cut == true || length <= 0 { return TimelineSpan(from: previous, to: previous, progress: 0) }
                let u = (time - a) / length
                return TimelineSpan(from: previous, to: i, progress: (key.easing ?? .linear)(u))
            }
            previous = i
        }
        return TimelineSpan(from: previous, to: previous, progress: 0)
    }

    /// The blended value of a vector field at `time` (nil when no key sets it).
    public func vec3(_ field: KeyPath<TimelineKey, Vec3?>, at time: Float) -> Vec3? {
        guard let s = span(at: time, where: { $0[keyPath: field] != nil }),
              let a = keys[s.from][keyPath: field], let b = keys[s.to][keyPath: field] else { return nil }
        return a + (b - a) * s.progress
    }

    /// The blended value of a scalar field at `time` (nil when no key sets it).
    public func float(_ field: KeyPath<TimelineKey, Float?>, at time: Float) -> Float? {
        guard let s = span(at: time, where: { $0[keyPath: field] != nil }),
              let a = keys[s.from][keyPath: field], let b = keys[s.to][keyPath: field] else { return nil }
        return a + (b - a) * s.progress
    }

    /// The blended rotation (Euler degrees per key, slerped) at `time`.
    public func rotation(at time: Float) -> Quat? {
        guard let s = span(at: time, where: { $0.rotation != nil }),
              let a = keys[s.from].rotation, let b = keys[s.to].rotation else { return nil }
        let qa = Quat(eulerDegrees: a), qb = Quat(eulerDegrees: b)
        return s.progress == 0 ? qa : Quat.slerp(qa, qb, s.progress).normalized
    }

    /// The screen fade at `time`: sRGB color and amount 0...1 (nil without fade keys).
    public func fade(at time: Float) -> (color: Vec3, amount: Float)? {
        guard let s = span(at: time, where: { $0.amount != nil || $0.color != nil }) else { return nil }
        let a = keys[s.from], b = keys[s.to]
        let black = Vec3(0, 0, 0)
        let ca = a.color ?? black, cb = b.color ?? ca
        let amount = (a.amount ?? 0) + ((b.amount ?? a.amount ?? 0) - (a.amount ?? 0)) * s.progress
        return (ca + (cb - ca) * s.progress, min(max(amount, 0), 1))
    }
}

// MARK: Problems

/// Problems with a timeline found without a scene (the importer reports the same ones).
/// `assetExists` (when given) checks the sounds and effects keys name.
public enum TimelineCheck {
    public static func problems(_ timeline: Timeline, assetExists: ((String) -> Bool)? = nil) -> [String] {
        var problems: [String] = []
        if !(timeline.duration > 0) { problems.append("duration must be above 0") }
        let ids = timeline.tracks.map(\.id)
        if Set(ids).count != ids.count { problems.append("some tracks share an id") }
        for track in timeline.tracks {
            let label = "track '\(track.id)'"
            guard let kind = track.trackKind else {
                problems.append("\(label): unknown kind '\(track.kind)' (known: \(TimelineTrackKind.allCases.map(\.rawValue).joined(separator: ", "))); it is skipped")
                continue
            }
            if track.keys.isEmpty { problems.append("\(label) has no keys") }
            for (i, key) in track.keys.enumerated() {
                let at = "\(label) key \(i) (\(Self.format(key.time)) s)"
                if key.time > timeline.duration + 0.0005 { problems.append("\(at) is after the end (\(Self.format(timeline.duration)) s)") }
                if i > 0, key.time < track.keys[i - 1].time { problems.append("\(at) is out of time order") }
                switch kind {
                case .animation:
                    if (key.clip ?? "").isEmpty { problems.append("\(at) has no clip") }
                case .audio:
                    if let clip = key.clip, !clip.isEmpty {
                        if let assetExists, !assetExists(clip) { problems.append("\(at): no sound '\(clip)'") }
                    } else {
                        problems.append("\(at) has no clip")
                    }
                case .particles:
                    if let effect = key.effect, !effect.isEmpty {
                        if let assetExists, !assetExists(effect) { problems.append("\(at): no effect '\(effect)'") }
                    } else {
                        problems.append("\(at) has no effect")
                    }
                case .event:
                    if (key.name ?? "").isEmpty { problems.append("\(at) has no name") }
                case .fade:
                    if let amount = key.amount, amount < 0 || amount > 1 { problems.append("\(at): amount \(amount) is outside 0...1") }
                case .camera:
                    if let fov = key.fov, fov <= 1 || fov >= 179 { problems.append("\(at): fov \(fov) is outside 1...179 degrees") }
                    if key.path != nil, key.position == nil { problems.append("\(at): a path needs a position to start from") }
                case .transform:
                    break
                }
            }
        }
        return problems
    }

    static func format(_ x: Float) -> String { String(format: "%g", x) }
}

// MARK: Importer

/// Imports `.timeline` files. A timeline makes no engine objects (it plays on scene entities),
/// so the import only checks it (problems become warnings, missing sounds and effects included)
/// and records the revision `TimelinePlayer`s follow: editing the file while a game runs
/// changes the cutscene from the next frame. Cooked games ship the file as it is.
public struct TimelineImporter: AssetImporter {
    public init() {}

    public var name: String { "timeline" }
    public var fileExtensions: [String] { ["timeline"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let timeline: Timeline
        do { timeline = try AssetJSON.decoder().decode(Timeline.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a timeline: \(error)")
        }
        let paths = context.assetsByPath
        for problem in TimelineCheck.problems(timeline, assetExists: { DataTableImporter.exists($0, in: paths) }) {
            context.warn(problem)
        }
        return ImportedAsset()
    }
}

extension AssetDatabase {
    /// Writes `timeline` to a new `.timeline` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createTimeline(_ timeline: Timeline, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try timeline.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.timeline` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func timeline(of id: AssetID) -> Timeline? {
        guard record(id)?.importer == TimelineImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(Timeline.self, from: data)
    }

    /// The timeline a key names: "asset:<id>" or a path under `Assets/` (a leading `Assets/` is allowed).
    public func timelineID(forKey key: String) -> AssetID? {
        guard let id = assetID(forTableValue: key.trimmingCharacters(in: .whitespaces)),
              record(id)?.importer == TimelineImporter().name else { return nil }
        return id
    }

    /// Overwrites the `.timeline` asset `id` and reimports it. Returns the import's warnings about it.
    @discardableResult
    public func writeTimeline(_ timeline: Timeline, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try timeline.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// Problems with `timeline`, with sounds and effects checked against the project.
    public func timelineProblems(_ timeline: Timeline) -> [String] {
        TimelineCheck.problems(timeline, assetExists: { [unowned self] in assetID(forTableValue: $0) != nil })
    }
}
