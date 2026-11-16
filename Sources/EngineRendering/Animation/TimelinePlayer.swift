import Foundation
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene
import EngineText

/// Where a `TimelinePlayer` is in its timeline.
public enum TimelinePlaybackState: String, Codable, CaseIterable, Sendable {
    /// Not started, or stopped (`stop()`): nothing is posed.
    case stopped
    case playing
    /// Frozen at `time`, still posing the scene.
    case paused
    /// Reached the end (or was skipped); the last pose holds.
    case finished
}

/// An event key that playback passed.
public struct TimelineFiredEvent: Equatable, Sendable {
    public var name: String
    public var value: String
    /// The key's time in seconds.
    public var time: Float
    /// The id of the track it is on.
    public var track: String

    public init(name: String, value: String = "", time: Float, track: String) {
        self.name = name
        self.value = value
        self.time = time
        self.track = track
    }
}

/// Plays a `.timeline` cutscene on the scene: moves the camera and entities, plays animations,
/// sounds and effects, fades the screen and fires events for game code. The timeline names its
/// targets by entity name, so one file can play in any scene that has them.
///
/// ```swift
/// world.spawn(Name("Intro"), TimelinePlayer(timeline: "Cutscenes/intro.timeline"))
/// // later, in a system:
/// world.modify(TimelinePlayer.self, for: intro) { $0.skip() }        // the player pressed Esc
/// for (_, event) in world.timelineEvents() where event.name == "introDone" { startLevel() }
/// ```
///
/// Control it with `play(from:)`, `pause()`, `resume()`, `stop()`, `skip()` and `seek(to:)`
/// through `world.modify`; the system applies the request on its next update. `events` holds
/// the event keys passed during the last update and `didFinish` is true for the update that
/// reached the end. `skip()` jumps to the end: it fires the event keys not reached yet and the
/// last animation key of each track, stops the sounds and effects the timeline started and
/// poses the final frame (only when the timeline is `skippable`).
///
/// Needs `world.addTimelinePlayers(assets:)`, which the editor's play mode, exported games and
/// `GameRunner` add. Runs in `.lateUpdate`, after gameplay and `CameraPath`.
public struct TimelinePlayer: Component, Equatable, Sendable {
    public static let componentName = "TimelinePlayer"
    public static var fieldHints: [String: FieldHints] {
        ["timeline": FieldHints(tooltip: "The .timeline asset: a path under Assets/ or asset:<id>"),
         "playOnStart": FieldHints(tooltip: "Start playing as soon as the scene runs"),
         "speed": FieldHints(range: 0...10, step: 0.05, tooltip: "Playback speed multiplier"),
         "loop": FieldHints(tooltip: "Start over at the end even if the timeline doesn't loop")]
    }

    /// The `.timeline` asset: a path under `Assets/` or "asset:<id>".
    public var timeline: String
    public var playOnStart: Bool
    public var speed: Float
    /// Loop even when the file doesn't.
    public var loop: Bool

    // Runtime state, not coded.
    /// Seconds into the timeline.
    public internal(set) var time: Float = 0
    public internal(set) var state: TimelinePlaybackState = .stopped
    /// Event keys passed during the last update.
    public internal(set) var events: [TimelineFiredEvent] = []
    /// True for the update that reached the end (or skipped there).
    public internal(set) var didFinish = false
    var started = false
    /// Keys at or before this time have fired this run (nil: none yet).
    var firedThrough: Float?
    var request: Request?
    var spawned: [Spawn] = []

    enum Request: Equatable, Sendable {
        case play(from: Float?)
        case pause, resume, stop, skip
        case seek(Float)
    }

    struct Spawn: Equatable, Sendable {
        var entity: Entity
        /// World clock time to despawn at (nil: when its sound ends).
        var until: Double?
    }

    public init(timeline: String = "", playOnStart: Bool = true, speed: Float = 1, loop: Bool = false) {
        self.timeline = timeline
        self.playOnStart = playOnStart
        self.speed = speed
        self.loop = loop
    }

    public var isPlaying: Bool { state == .playing }

    /// Plays from `time` seconds (nil: from the start when stopped or finished, else carries on).
    public mutating func play(from time: Float? = nil) { request = .play(from: time) }
    public mutating func pause() { request = .pause }
    public mutating func resume() { request = .resume }
    /// Stops, despawns the sounds and effects it started and clears its screen fade.
    public mutating func stop() { request = .stop }
    /// Jumps to the end (see the type's notes). Ignored when the timeline isn't skippable.
    public mutating func skip() { request = .skip }
    /// Moves the playhead without firing the keys in between (a stopped or finished player
    /// pauses there, posing the scene: scrubbing).
    public mutating func seek(to time: Float) { request = .seek(time) }

    private enum CodingKeys: String, CodingKey { case timeline, playOnStart, speed, loop }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TimelinePlayer()
        self.init(timeline: try c.decodeIfPresent(String.self, forKey: .timeline) ?? d.timeline,
                  playOnStart: try c.decodeIfPresent(Bool.self, forKey: .playOnStart) ?? d.playOnStart,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? d.speed,
                  loop: try c.decodeIfPresent(Bool.self, forKey: .loop) ?? d.loop)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(timeline, forKey: .timeline)
        try c.encode(playOnStart, forKey: .playOnStart)
        try c.encode(speed, forKey: .speed)
        try c.encode(loop, forKey: .loop)
    }
}

// MARK: Assets

/// What the timeline system loads: timelines (with a revision, so edits reload), sound keys for
/// `AudioEmitter.clip` and effect prefabs. `database(_:)` reads them from an `AssetDatabase`.
public struct TimelineAssetSource {
    /// The timeline a `TimelinePlayer.timeline` key names, and its revision (0: unversioned,
    /// prepared again every frame; others are prepared once per revision).
    public var timeline: @MainActor (String) -> (timeline: Timeline, revision: Int)?
    /// An `AudioEmitter.clip` key for a key's `clip`.
    public var sound: @MainActor (String) -> String?
    /// The prefab of a key's `effect` and how long it lasts by default.
    public var effect: @MainActor (String) -> (prefab: PrefabAsset, duration: Float)?

    public init(timeline: @escaping @MainActor (String) -> (timeline: Timeline, revision: Int)?,
                sound: @escaping @MainActor (String) -> String? = { AssetReference($0) != nil ? $0 : nil },
                effect: @escaping @MainActor (String) -> (prefab: PrefabAsset, duration: Float)? = { _ in nil }) {
        self.timeline = timeline
        self.sound = sound
        self.effect = effect
    }

    /// Fixed timelines by key (tests, previews).
    public static func fixed(_ timelines: [String: Timeline]) -> TimelineAssetSource {
        TimelineAssetSource(timeline: { key in timelines[key].map { ($0, 0) } })
    }

    /// Loads from the database `assets` returns (nil: nothing loads). Timelines reload when their file is reimported.
    @MainActor public static func database(_ assets: @escaping () -> AssetDatabase?) -> TimelineAssetSource {
        final class Cache { var entries: [AssetID: (revision: Int, timeline: Timeline)] = [:] }
        let cache = Cache()
        return TimelineAssetSource(
            timeline: { key in
                guard let assets = assets(), let id = assets.timelineID(forKey: key) else { return nil }
                if assets.pack == nil { _ = assets.asset(id) }  // reimports when the file changed, bumping the revision
                let revision = assets.pack == nil ? assets.revision(of: id) + 1 : 1
                if let hit = cache.entries[id], hit.revision == revision { return (hit.timeline, revision) }
                guard let timeline = assets.timeline(of: id) else { return nil }
                cache.entries[id] = (revision, timeline)
                return (timeline, revision)
            },
            sound: { key in
                guard let assets = assets(), let id = assets.assetID(forTableValue: key) else { return nil }
                return AssetReference(id).description
            },
            effect: { key in
                guard let assets = assets(), let id = assets.assetID(forTableValue: key),
                      let prefab = assets.prefab(AssetReference(id)) else { return nil }
                return (prefab, assets.pack == nil ? (assets.vfx(of: id)?.duration ?? 4) : 4)
            })
    }
}

// MARK: Evaluation

/// A camera track's pose at a moment (nil fields: no key sets them).
public struct TimelineCameraPose: Equatable, Sendable {
    public var position: Vec3?
    public var rotation: Quat?
    public var fovDegrees: Float?
}

/// Timeline math shared by the runtime system, the editor preview and the tools: poses of
/// continuous tracks at a time, and applying them to a world.
@MainActor
public enum TimelineEvaluator {
    /// The entity `target` names in `world`: a "Parent/Child" path of names from a root, or the
    /// first entity (lowest index) with that `Name`. nil for "" or when nothing matches.
    public static func find(_ target: String, in world: World) -> Entity? {
        let target = target.trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty else { return nil }
        func name(_ e: Entity) -> String? { world.get(Name.self, for: e)?.value }
        if target.contains("/") {
            let parts = target.split(separator: "/").map(String.init)
            var level = world.roots.filter { name($0) == parts[0] }
            for part in parts.dropFirst() {
                level = level.flatMap { world.children(of: $0) }.filter { name($0) == part }
            }
            return level.min { $0.index < $1.index }
        }
        var best: Entity?
        world.query(Name.self) { entity, n in
            if n.value == target, best == nil || entity.index < best!.index { best = entity }
        }
        return best
    }

    /// The camera track's pose at `time`. `world` resolves `lookAtEntity` (skipped without one).
    public static func cameraPose(_ track: TimelineTrack, at time: Float, in world: World?,
                                  resolve: ((String) -> Entity?)? = nil) -> TimelineCameraPose {
        var pose = TimelineCameraPose()
        var forward: Vec3?
        if let s = track.span(at: time, where: { $0.position != nil }), let a = track.keys[s.from].position {
            let from = track.keys[s.from]
            if s.to != s.from, let b = track.keys[s.to].position, let path = from.path, !path.isEmpty {
                // A spline move, with CameraPath's constant-speed Catmull-Rom (eased by the later key).
                let spline = CameraPath(points: [a] + path + [b], duration: 1, easing: .linear, constantSpeed: true)
                if let sampled = spline.sample(time: s.progress, controlPoints: spline.points) {
                    pose.position = sampled.position
                    if from.followPath == true { forward = sampled.forward }
                }
            } else if s.to != s.from, let b = track.keys[s.to].position {
                pose.position = a + (b - a) * s.progress
            } else {
                pose.position = a
            }
        }
        pose.fovDegrees = track.float(\.fov, at: time)
        let eye = pose.position
        func aim(_ key: TimelineKey) -> Quat? {
            func facing(_ point: Vec3) -> Quat? {
                guard let eye else { return nil }
                let d = point - eye
                let l = length(d)
                guard l > 1e-5, abs(dot(d / l, Vec3(0, 1, 0))) < 0.9999 else { return nil }
                return .lookRotation(forward: d / l)
            }
            if let name = key.lookAtEntity, !name.isEmpty, let world,
               let entity = resolve?(name) ?? find(name, in: world) {
                let m = world.get(GlobalTransform.self, for: entity)?.matrix ?? world.worldMatrix(of: entity)
                if let q = facing(Vec3(m.c3.x, m.c3.y, m.c3.z)) { return q }
            }
            if let point = key.lookAt, let q = facing(point) { return q }
            if let euler = key.rotation { return Quat(eulerDegrees: euler) }
            return nil
        }
        let aims = { (key: TimelineKey) in (key.lookAtEntity.map { !$0.isEmpty } ?? false) || key.lookAt != nil || key.rotation != nil }
        if let s = track.span(at: time, where: aims), let qa = aim(track.keys[s.from]) {
            if s.to != s.from, let qb = aim(track.keys[s.to]) {
                pose.rotation = Quat.slerp(qa, qb, s.progress).normalized
            } else {
                pose.rotation = qa
            }
        }
        if let forward, length(forward) > 1e-5, abs(dot(normalize(forward), Vec3(0, 1, 0))) < 0.9999 {
            // followPath wins over the keys' aim while on the path, unless a look-at is set there.
            let from = track.span(at: time, where: { $0.position != nil }).map { track.keys[$0.from] }
            if from?.lookAt == nil, (from?.lookAtEntity ?? "").isEmpty { pose.rotation = .lookRotation(forward: normalize(forward)) }
        }
        return pose
    }

    /// Poses every continuous track (camera, transform, fade) of `timeline` at `time`. `owner`
    /// is the default target of transform tracks and holds the `ScreenFade` of fade tracks (no
    /// fade without one). `resolve` finds targets (default `find`).
    public static func pose(_ timeline: Timeline, at time: Float, in world: World, owner: Entity?,
                            resolve: ((String) -> Entity?)? = nil) {
        let resolve = resolve ?? { find($0, in: world) }
        var fade: (color: Vec3, amount: Float)?
        var hasFadeTrack = false
        for track in timeline.tracks where !track.muted {
            switch track.trackKind {
            case .camera:
                let entity = track.target.isEmpty ? RenderPrep.findCamera(in: world)?.entity : resolve(track.target)
                guard let entity, world.has(Transform.self, for: entity) else { continue }
                let pose = cameraPose(track, at: time, in: world, resolve: resolve)
                world.modify(Transform.self, for: entity) { t in
                    if let p = pose.position { t.position = p }
                    if let r = pose.rotation { t.rotation = r }
                }
                if let fov = pose.fovDegrees, world.has(Camera.self, for: entity) {
                    world.modify(Camera.self, for: entity) { $0.fovY = min(max(fov, 1), 179) * .pi / 180 }
                }
            case .transform:
                guard let entity = track.target.isEmpty ? owner : resolve(track.target), world.has(Transform.self, for: entity) else { continue }
                let position = track.vec3(\.position, at: time), rotation = track.rotation(at: time), scale = track.vec3(\.scale, at: time)
                world.modify(Transform.self, for: entity) { t in
                    if let position { t.position = position }
                    if let rotation { t.rotation = rotation }
                    if let scale { t.scale = scale }
                }
            case .fade:
                hasFadeTrack = true
                if let f = track.fade(at: time), f.amount >= (fade?.amount ?? 0) { fade = f }
            default:
                continue
            }
        }
        if let owner, hasFadeTrack {
            world.add(ScreenFade(color: fade?.color ?? Vec3(0, 0, 0), amount: fade?.amount ?? 0), to: owner)
        }
    }
}

// MARK: System

/// The timeline system `World.addTimelinePlayers` installs. `remove()` uninstalls it.
@MainActor
public final class TimelinePlayerSystem {
    public static let systemName = "builtin.timelinePlayer"
    public let world: World
    public var source: TimelineAssetSource
    /// Called for every event key passed, after the update that passed it was applied to the component.
    public var onEvent: ((Entity, TimelineFiredEvent) -> Void)?
    private var cache: [String: (timeline: Timeline, revision: Int)] = [:]

    init(world: World, source: TimelineAssetSource) {
        self.world = world
        self.source = source
    }

    public func remove() { world.removeSystem(named: Self.systemName) }

    /// The timeline `key` names, normalized (keys sorted), reloaded when its revision changes.
    func timeline(_ key: String) -> Timeline? {
        guard !key.isEmpty, let loaded = source.timeline(key) else { return nil }
        // Revision 0 (fixed sources) is normalized every time; others once per revision.
        if loaded.revision != 0, let cached = cache[key], cached.revision == loaded.revision { return cached.timeline }
        let normalized = loaded.timeline.normalized()
        cache[key] = (normalized, loaded.revision)
        return normalized
    }

    func update() {
        guard world.count(of: TimelinePlayer.self) > 0 else { return }
        var entities: [Entity] = []
        world.query(TimelinePlayer.self) { entity, _ in entities.append(entity) }
        var fired: [(Entity, TimelineFiredEvent)] = []
        for entity in entities {
            guard var player = world.get(TimelinePlayer.self, for: entity) else { continue }
            step(&player, entity: entity)
            world.add(player, to: entity)
            fired += player.events.map { (entity, $0) }
        }
        if let onEvent { for (entity, event) in fired { onEvent(entity, event) } }
    }

    private func step(_ p: inout TimelinePlayer, entity: Entity) {
        p.events.removeAll()
        p.didFinish = false
        let now = world.time.elapsed
        let timeline = timeline(p.timeline)
        var resolved: [String: Entity] = [:]
        let resolve: (String) -> Entity? = { [world] name in
            if let e = resolved[name] { return e }
            let e = TimelineEvaluator.find(name, in: world)
            if let e { resolved[name] = e }
            return e
        }

        if !p.started {
            p.started = true
            if p.playOnStart, p.request == nil { p.request = .play(from: 0) }
        }
        if let request = p.request {
            p.request = nil
            switch request {
            case .play(let from):
                if let from {
                    p.time = min(max(from, 0), timeline?.duration ?? from)
                    p.firedThrough = p.time > 0 ? p.time : nil
                } else if p.state == .stopped || p.state == .finished {
                    p.time = 0
                    p.firedThrough = nil
                }
                p.state = .playing
            case .pause:
                if p.state == .playing { p.state = .paused }
            case .resume:
                if p.state == .paused { p.state = .playing }
            case .stop:
                p.state = .stopped
                p.time = 0
                p.firedThrough = nil
                despawnAll(&p)
                world.remove(ScreenFade.self, from: entity)
            case .seek(let t):
                p.time = min(max(t, 0), timeline?.duration ?? t)
                p.firedThrough = p.time > 0 ? p.time : nil
                if p.state == .stopped || p.state == .finished { p.state = .paused }
            case .skip:
                if let timeline, timeline.skippable, p.state == .playing || p.state == .paused {
                    skipToEnd(&p, timeline, entity: entity, resolve: resolve)
                }
            }
        }
        // Effects and sounds that ran their course.
        p.spawned.removeAll { spawn in
            guard world.isAlive(spawn.entity) else { return true }
            let done = spawn.until.map { now >= $0 } ?? (world.get(AudioEmitter.self, for: spawn.entity)?.isPlaying == false)
            if done { world.despawn(spawn.entity) }
            return done
        }
        guard let timeline else { return }
        if p.state == .playing {
            let duration = timeline.duration
            var t = p.time + world.time.delta * max(p.speed, 0)
            if t >= duration {
                fire(timeline, from: p.firedThrough, to: duration, into: &p, entity: entity, resolve: resolve, now: now)
                if timeline.loop || p.loop {
                    t = duration > 0 ? t.truncatingRemainder(dividingBy: duration) : 0
                    p.firedThrough = nil
                    fire(timeline, from: nil, to: t, into: &p, entity: entity, resolve: resolve, now: now)
                } else {
                    t = duration
                    p.state = .finished
                    p.didFinish = true
                }
            } else {
                fire(timeline, from: p.firedThrough, to: t, into: &p, entity: entity, resolve: resolve, now: now)
            }
            p.time = t
            p.firedThrough = t
        }
        if p.state != .stopped {
            TimelineEvaluator.pose(timeline, at: p.time, in: world, owner: entity, resolve: resolve)
        }
    }

    private func skipToEnd(_ p: inout TimelinePlayer, _ timeline: Timeline, entity: Entity, resolve: (String) -> Entity?) {
        let keys = timeline.firedKeys(from: p.firedThrough, to: timeline.duration)
        var lastAnimation: [Int: Int] = [:]
        for (t, k) in keys {
            let track = timeline.tracks[t]
            switch track.trackKind {
            case .event:
                let key = track.keys[k]
                p.events.append(TimelineFiredEvent(name: key.name ?? "", value: key.value ?? "", time: key.time, track: track.id))
            case .animation:
                lastAnimation[t] = k
            default:
                break
            }
        }
        for (t, k) in lastAnimation.sorted(by: { $0.key < $1.key }) {
            playAnimation(timeline.tracks[t], timeline.tracks[t].keys[k], owner: entity, resolve: resolve)
        }
        despawnAll(&p)
        p.time = timeline.duration
        p.firedThrough = timeline.duration
        p.state = .finished
        p.didFinish = true
    }

    private func despawnAll(_ p: inout TimelinePlayer) {
        for spawn in p.spawned where world.isAlive(spawn.entity) { world.despawn(spawn.entity) }
        p.spawned.removeAll()
    }

    private func fire(_ timeline: Timeline, from: Float?, to: Float, into p: inout TimelinePlayer, entity: Entity,
                      resolve: (String) -> Entity?, now: Double) {
        for (t, k) in timeline.firedKeys(from: from, to: to) {
            let track = timeline.tracks[t]
            let key = track.keys[k]
            switch track.trackKind {
            case .event:
                p.events.append(TimelineFiredEvent(name: key.name ?? "", value: key.value ?? "", time: key.time, track: track.id))
            case .animation:
                playAnimation(track, key, owner: entity, resolve: resolve)
            case .audio:
                if let spawn = playSound(track, key, resolve: resolve, now: now) { p.spawned.append(spawn) }
            case .particles:
                if let spawn = spawnEffect(track, key, resolve: resolve, now: now) { p.spawned.append(spawn) }
            default:
                break
            }
        }
    }

    /// Plays the key's clip on the target's `Animator` (or `SpriteAnimator`), or the first descendant's that has one.
    private func playAnimation(_ track: TimelineTrack, _ key: TimelineKey, owner: Entity, resolve: (String) -> Entity?) {
        guard let clip = key.clip, !clip.isEmpty, let root = track.target.isEmpty ? owner : resolve(track.target) else { return }
        var queue = [root]
        while !queue.isEmpty {
            let e = queue.removeFirst()
            if world.has(Animator.self, for: e) {
                world.modify(Animator.self, for: e) { animator in
                    animator.play(clip, fade: max(key.blend ?? 0.25, 0))
                    if let speed = key.speed { animator.speed = speed }
                }
                return
            }
            if world.has(SpriteAnimator.self, for: e) {
                world.modify(SpriteAnimator.self, for: e) { $0.play(clip, restart: true) }
                return
            }
            queue += world.children(of: e)
        }
    }

    private func playSound(_ track: TimelineTrack, _ key: TimelineKey, resolve: (String) -> Entity?, now: Double) -> TimelinePlayer.Spawn? {
        guard let clip = key.clip, !clip.isEmpty, let sound = source.sound(clip) else { return nil }
        // Unpositioned sounds ride on the listener (else the camera), so they are heard at full level.
        var parent = track.target.isEmpty ? nil : resolve(track.target)
        if parent == nil {
            var listener: Entity?
            world.query(AudioListener.self) { e, _ in if listener == nil || e.index < listener!.index { listener = e } }
            parent = listener ?? RenderPrep.findCamera(in: world)?.entity
        }
        let emitter = AudioEmitter(clip: sound, volume: key.volume ?? 1, pitch: key.pitch ?? 1, loop: key.loop ?? false, isPlaying: true)
        let e = world.spawn(Transform(position: key.position ?? .zero), Name("Timeline Sound"), emitter)
        if let parent { world.setParent(e, to: parent) }
        let until = key.duration.flatMap { $0 > 0 ? now + Double($0) : nil }
        // A looping sound with no duration plays until the timeline stops.
        return TimelinePlayer.Spawn(entity: e, until: until ?? ((key.loop ?? false) ? .infinity : nil))
    }

    private func spawnEffect(_ track: TimelineTrack, _ key: TimelineKey, resolve: (String) -> Entity?, now: Double) -> TimelinePlayer.Spawn? {
        guard let effect = key.effect, !effect.isEmpty, let loaded = source.effect(effect) else { return nil }
        let parent = track.target.isEmpty ? nil : resolve(track.target)
        guard let root = world.instantiate(loaded.prefab, under: parent).first else { return nil }
        world.modify(Transform.self, for: root) { t in
            if let p = key.position { t.position = p }
            if let r = key.rotation { t.rotation = Quat(eulerDegrees: r) }
        }
        let life = key.duration.flatMap { $0 > 0 ? $0 : nil } ?? max(loaded.duration, 0.1)
        return TimelinePlayer.Spawn(entity: root, until: now + Double(life))
    }
}

extension World {
    /// Installs the system that plays `TimelinePlayer`s, loading timelines, sounds and effects
    /// from the database `assets` returns. Idempotent (returns nil when already installed).
    @discardableResult
    @MainActor public func addTimelinePlayers(assets: @escaping () -> AssetDatabase?) -> TimelinePlayerSystem? {
        addTimelinePlayers(source: .database(assets))
    }

    /// Installs the timeline system with its own asset source. nil when already installed.
    @discardableResult
    @MainActor public func addTimelinePlayers(source: TimelineAssetSource) -> TimelinePlayerSystem? {
        guard !systemNames(in: .lateUpdate).contains(TimelinePlayerSystem.systemName) else { return nil }
        let system = TimelinePlayerSystem(world: self, source: source)
        addSystem(TimelinePlayerSystem.systemName, stage: .lateUpdate) { _ in system.update() }
        return system
    }

    /// The event keys every `TimelinePlayer` passed during the last update, by player entity.
    @MainActor public func timelineEvents() -> [(entity: Entity, event: TimelineFiredEvent)] {
        var out: [(entity: Entity, event: TimelineFiredEvent)] = []
        query(TimelinePlayer.self) { entity, player in out += player.events.map { (entity, $0) } }
        return out
    }
}
