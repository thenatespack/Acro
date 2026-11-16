import Foundation
import EngineAssets
import EngineCore
import EngineScene

/// What a `PathFollower` does at the ends of its path.
public enum PathFollowMode: String, Codable, CaseIterable, Sendable {
    /// Stop at the end.
    case once
    /// Start over: a closed path carries on round, an open one jumps back to the start.
    case loop
    /// Turn around at each end.
    case pingPong
}

/// How a `PathFollower` turns its entity.
public enum PathFollowOrient: String, Codable, CaseIterable, Sendable {
    /// Leave the rotation alone.
    case none
    /// Face the direction of travel, staying upright (cars, walkers).
    case heading
    /// Face the direction of travel and tilt with the slope and banking (trains, coasters, cameras).
    case full
}

/// Where a `PathFollower` is in its run.
public enum PathFollowState: String, Codable, CaseIterable, Sendable {
    case stopped, playing, paused
    /// Reached the end in `once` mode.
    case finished
}

/// Something that happened at an end of the path during the last update.
public struct PathFollowerEvent: Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        /// Got to the far end (moving forward).
        case reachedEnd
        /// Got back to the start (moving backward, in `pingPong`).
        case reachedStart
        /// Went round again (`loop`), right after `reachedEnd`.
        case looped
        /// Stopped at the end (`once`).
        case finished
    }

    public var kind: Kind
    /// Meters along the path where it happened.
    public var distance: Float

    public init(_ kind: Kind, distance: Float) {
        self.kind = kind
        self.distance = distance
    }
}

/// Moves its entity along a `.path` at a steady speed: cars on a road, a train on its rails, a
/// boat down a river, a patrolling guard, a camera on a dolly.
///
/// ```swift
/// world.spawn(Name("Bus"), Transform(), PathFollower(path: "Roads/loop.path", speed: 8))
/// // later, in a system:
/// world.modify(PathFollower.self, for: bus) { $0.pause() }
/// for (bus, event) in world.pathFollowerEvents() where event.kind == .reachedEnd { arrive(bus) }
/// ```
///
/// The path's coordinates are in the follower's parent space: make it a child of the placed path
/// (or of whatever the path's points are relative to), or name the entity that places the path in
/// `placedAt`. `offset` moves it off the centerline in the path's frame (a lane to the right).
/// Terrain following is honored: the follower rides the same ground the path's geometry sits on.
///
/// Control it with `play(from:)`, `pause()`, `resume()`, `stop()` and `seek(to:)` through
/// `world.modify`; the system applies the request on its next update. `events` holds what
/// happened at the ends during the last update. Needs `world.addPathFollowers(assets:)`, which
/// the editor's play mode, exported games and `GameRunner` add. Runs in `.update`.
public struct PathFollower: Component, Equatable, Sendable {
    public static let componentName = "PathFollower"
    public static var fieldHints: [String: FieldHints] {
        ["path": FieldHints(tooltip: "The .path asset: a path under Assets/ or asset:<id>"),
         "speed": FieldHints(range: 0...1000, step: 0.1, tooltip: "Meters per second along the path"),
         "mode": FieldHints(tooltip: "At the end: stop (once), start over (loop) or turn around (pingPong)"),
         "orient": FieldHints(tooltip: "Turn to face along the path: not at all, heading only, or tilting with slope and bank"),
         "startOffset": FieldHints(range: 0...100_000, step: 0.1, tooltip: "Meters along the path to start at"),
         "offset": FieldHints(step: 0.05, tooltip: "[right, up, forward] meters from the centerline, in the path's frame"),
         "placedAt": FieldHints(tooltip: "The entity that places the path (its name); blank: the path is in this entity's parent space"),
         "playOnStart": FieldHints(tooltip: "Start moving as soon as the scene runs"),
         "reverse": FieldHints(tooltip: "Travel from the end toward the start")]
    }

    /// The `.path` asset: a path under `Assets/` or "asset:<id>".
    public var path: String
    /// Meters per second.
    public var speed: Float
    public var mode: PathFollowMode
    public var orient: PathFollowOrient
    /// Meters along the path to start at.
    public var startOffset: Float
    /// [right, up, forward] meters from the centerline in the path's frame.
    public var offset: Vec3
    /// The name of the entity that places the path; empty: the follower's parent space.
    public var placedAt: String
    public var playOnStart: Bool
    /// Travel toward the start.
    public var reverse: Bool

    // Runtime state, not coded.
    /// Meters along the path.
    public internal(set) var distance: Float = 0
    /// +1 forward, -1 backward.
    public internal(set) var direction: Float = 1
    public internal(set) var state: PathFollowState = .stopped
    /// The path's length in meters (0 until it loads).
    public internal(set) var length: Float = 0
    /// What happened at the ends during the last update.
    public internal(set) var events: [PathFollowerEvent] = []
    /// True for the update that stopped at the end (`once`).
    public internal(set) var didFinish = false
    var started = false
    var request: Request?

    enum Request: Equatable, Sendable {
        case play(from: Float?)
        case pause, resume, stop
        case seek(Float)
    }

    public init(path: String = "", speed: Float = 5, mode: PathFollowMode = .loop, orient: PathFollowOrient = .heading,
                startOffset: Float = 0, offset: Vec3 = .zero, placedAt: String = "", playOnStart: Bool = true, reverse: Bool = false) {
        self.path = path
        self.speed = speed
        self.mode = mode
        self.orient = orient
        self.startOffset = startOffset
        self.offset = offset
        self.placedAt = placedAt
        self.playOnStart = playOnStart
        self.reverse = reverse
    }

    public var isPlaying: Bool { state == .playing }

    /// Moves from `distance` meters (nil: from the start offset when stopped or finished, else carries on).
    public mutating func play(from distance: Float? = nil) { request = .play(from: distance) }
    public mutating func pause() { request = .pause }
    public mutating func resume() { request = .resume }
    /// Stops and goes back to the start offset.
    public mutating func stop() { request = .stop }
    /// Jumps to `distance` meters without firing end events (a stopped follower is placed there, paused).
    public mutating func seek(to distance: Float) { request = .seek(distance) }

    private enum CodingKeys: String, CodingKey { case path, speed, mode, orient, startOffset, offset, placedAt, playOnStart, reverse }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PathFollower()
        self.init(path: try c.decodeIfPresent(String.self, forKey: .path) ?? d.path,
                  speed: try c.decodeIfPresent(Float.self, forKey: .speed) ?? d.speed,
                  mode: try c.decodeIfPresent(PathFollowMode.self, forKey: .mode) ?? d.mode,
                  orient: try c.decodeIfPresent(PathFollowOrient.self, forKey: .orient) ?? d.orient,
                  startOffset: try c.decodeIfPresent(Float.self, forKey: .startOffset) ?? d.startOffset,
                  offset: try c.decodeIfPresent(Vec3.self, forKey: .offset) ?? d.offset,
                  placedAt: try c.decodeIfPresent(String.self, forKey: .placedAt) ?? d.placedAt,
                  playOnStart: try c.decodeIfPresent(Bool.self, forKey: .playOnStart) ?? d.playOnStart,
                  reverse: try c.decodeIfPresent(Bool.self, forKey: .reverse) ?? d.reverse)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(path, forKey: .path)
        try c.encode(speed, forKey: .speed)
        try c.encode(mode, forKey: .mode)
        try c.encode(orient, forKey: .orient)
        try c.encode(startOffset, forKey: .startOffset)
        try c.encode(offset, forKey: .offset)
        try c.encode(placedAt, forKey: .placedAt)
        try c.encode(playOnStart, forKey: .playOnStart)
        try c.encode(reverse, forKey: .reverse)
    }

    // MARK: Stepping

    /// Advances `distance` by `meters` (signed by `direction`) on a path `length` long, applying
    /// `mode` at the ends and recording `events`. On a closed path the end is the start, so
    /// `loop` carries on round seamlessly.
    mutating func advance(by meters: Float) {
        guard length > 0 else { return }
        var remaining = max(meters, 0)
        // Bounded so a huge step on a tiny path can't spin.
        var turns = 0
        while remaining > 0, turns < 64 {
            let target = distance + remaining * direction
            if direction > 0 && target >= length {
                remaining = target - length
                distance = length
                events.append(PathFollowerEvent(.reachedEnd, distance: length))
                switch mode {
                case .once:
                    finish()
                    return
                case .loop:
                    distance = 0
                    events.append(PathFollowerEvent(.looped, distance: 0))
                case .pingPong:
                    direction = -1
                }
            } else if direction < 0 && target <= 0 {
                remaining = -target
                distance = 0
                events.append(PathFollowerEvent(.reachedStart, distance: 0))
                switch mode {
                case .once:
                    finish()
                    return
                case .loop:
                    distance = length
                    events.append(PathFollowerEvent(.looped, distance: length))
                case .pingPong:
                    direction = 1
                }
            } else {
                distance = target
                remaining = 0
            }
            turns += 1
        }
    }

    private mutating func finish() {
        state = .finished
        didFinish = true
        events.append(PathFollowerEvent(.finished, distance: distance))
    }
}

// MARK: Assets

/// Where the path follower system gets curves: centerline samples of a `.path` (on its terrain)
/// with a revision, so edits reload. `database(_:)` reads them from an `AssetDatabase`.
public struct PathFollowerSource {
    /// The samples a `PathFollower.path` key names, whether the path loops, and a revision
    /// (0: unversioned, reread every frame).
    public var curve: @MainActor (String) -> (samples: [PathSample], closed: Bool, revision: Int)?

    public init(curve: @escaping @MainActor (String) -> (samples: [PathSample], closed: Bool, revision: Int)?) {
        self.curve = curve
    }

    /// Fixed paths by key (tests, previews).
    public static func fixed(_ paths: [String: PathBuild]) -> PathFollowerSource {
        PathFollowerSource(curve: { key in paths[key].map { ($0.samples(), $0.wraps, 1) } })
    }

    /// Loads from the database `assets` returns (nil: nothing loads). Paths reload when their file (or terrain) is reimported.
    @MainActor public static func database(_ assets: @escaping () -> AssetDatabase?) -> PathFollowerSource {
        final class Cache { var entries: [AssetID: (revision: Int, samples: [PathSample], closed: Bool)] = [:] }
        let cache = Cache()
        return PathFollowerSource(curve: { key in
            guard let assets = assets(), let id = assets.pathBuildID(forKey: key) else { return nil }
            if assets.pack == nil { _ = assets.asset(id) }  // reimports when the file or its terrain changed, bumping the revision
            let revision = assets.pack == nil ? assets.revision(of: id) + 1 : 1
            if let hit = cache.entries[id], hit.revision == revision { return (hit.samples, hit.closed, revision) }
            guard let curve = assets.pathSamples(of: id) else { return nil }
            cache.entries[id] = (revision, curve.samples, curve.closed)
            return (curve.samples, curve.closed, revision)
        })
    }
}

// MARK: System

/// The system `World.addPathFollowers` installs. `remove()` uninstalls it.
@MainActor
public final class PathFollowerSystem {
    public static let systemName = "builtin.pathFollower"
    public let world: World
    public var source: PathFollowerSource
    /// Called for every end event, after the update that produced it was applied to the component.
    public var onEvent: ((Entity, PathFollowerEvent) -> Void)?

    init(world: World, source: PathFollowerSource) {
        self.world = world
        self.source = source
    }

    public func remove() { world.removeSystem(named: Self.systemName) }

    func update() {
        guard world.count(of: PathFollower.self) > 0 else { return }
        var entities: [Entity] = []
        world.query(PathFollower.self) { entity, _ in entities.append(entity) }
        var fired: [(Entity, PathFollowerEvent)] = []
        for entity in entities {
            guard var follower = world.get(PathFollower.self, for: entity) else { continue }
            step(&follower, entity: entity)
            world.add(follower, to: entity)
            fired += follower.events.map { (entity, $0) }
        }
        if let onEvent { for (entity, event) in fired { onEvent(entity, event) } }
    }

    private func step(_ f: inout PathFollower, entity: Entity) {
        f.events.removeAll()
        f.didFinish = false
        guard let curve = source.curve(f.path), let total = curve.samples.last?.distance, total > 0 else { return }
        f.length = total
        let start = min(max(f.reverse ? total - f.startOffset : f.startOffset, 0), total)
        if !f.started {
            f.started = true
            f.direction = f.reverse ? -1 : 1
            f.distance = start
            if f.playOnStart, f.request == nil { f.state = .playing }
        }
        if let request = f.request {
            f.request = nil
            switch request {
            case .play(let from):
                if let from {
                    f.distance = min(max(from, 0), total)
                } else if f.state == .stopped || f.state == .finished {
                    f.distance = start
                    f.direction = f.reverse ? -1 : 1
                }
                f.state = .playing
            case .pause:
                if f.state == .playing { f.state = .paused }
            case .resume:
                if f.state == .paused { f.state = .playing }
            case .stop:
                f.state = .stopped
                f.distance = start
                f.direction = f.reverse ? -1 : 1
            case .seek(let d):
                f.distance = min(max(d, 0), total)
                if f.state == .stopped || f.state == .finished { f.state = .paused }
            }
        }
        f.distance = min(max(f.distance, 0), total)
        if f.state == .playing {
            f.advance(by: world.time.delta * max(f.speed, 0))
        }
        place(entity, f, curve.samples)
    }

    /// Puts `entity` at the follower's spot on the path.
    private func place(_ entity: Entity, _ f: PathFollower, _ samples: [PathSample]) {
        guard let s = PathBuild.sample(samples, atDistance: f.distance, closed: false) else { return }
        let travel = f.direction < 0 ? Float(-1) : 1
        var position = s.position + s.right * f.offset.x + s.up * f.offset.y + s.forward * f.offset.z
        var rotation: Quat?
        switch f.orient {
        case .none:
            break
        case .heading:
            let flat = Vec3(s.forward.x, 0, s.forward.z) * travel
            if EngineCore.length(flat) > 1e-5 { rotation = .lookRotation(forward: normalize(flat)) }
        case .full:
            let forward = s.forward * travel, up = s.up
            let right = normalize(cross(forward, up))
            rotation = Quat(rotationMatrix: Mat4(Vec4(right, 0), Vec4(up, 0), Vec4(-forward, 0), Vec4(0, 0, 0, 1))).normalized
        }
        // Path space -> the follower's parent space.
        let placer = f.placedAt.trimmingCharacters(in: .whitespaces)
        if !placer.isEmpty, let placed = TimelineEvaluator.find(placer, in: world), placed != entity {
            var toParent = world.worldMatrix(of: placed)
            if let parent = world.parent(of: entity) { toParent = world.worldMatrix(of: parent).inverse * toParent }
            let p = toParent * Vec4(position, 1)
            position = Vec3(p.x, p.y, p.z)
            if let r = rotation {
                // The placement's rotation only (scale removed).
                let c0 = Vec3(toParent.c0.x, toParent.c0.y, toParent.c0.z), c1 = Vec3(toParent.c1.x, toParent.c1.y, toParent.c1.z)
                let c2 = Vec3(toParent.c2.x, toParent.c2.y, toParent.c2.z)
                if EngineCore.length(c0) > 1e-6, EngineCore.length(c1) > 1e-6, EngineCore.length(c2) > 1e-6 {
                    let m = Mat4(Vec4(normalize(c0), 0), Vec4(normalize(c1), 0), Vec4(normalize(c2), 0), Vec4(0, 0, 0, 1))
                    rotation = (Quat(rotationMatrix: m) * r).normalized
                }
            }
        }
        world.modify(Transform.self, for: entity) { t in
            t.position = position
            if let rotation { t.rotation = rotation }
        }
    }
}

extension World {
    /// Installs the system that moves `PathFollower`s, loading paths from the database `assets`
    /// returns. Idempotent (returns nil when already installed).
    @discardableResult
    @MainActor public func addPathFollowers(assets: @escaping () -> AssetDatabase?) -> PathFollowerSystem? {
        addPathFollowers(source: .database(assets))
    }

    /// Installs the path follower system with its own source. nil when already installed.
    @discardableResult
    @MainActor public func addPathFollowers(source: PathFollowerSource) -> PathFollowerSystem? {
        guard !systemNames(in: .update).contains(PathFollowerSystem.systemName) else { return nil }
        let system = PathFollowerSystem(world: self, source: source)
        addSystem(PathFollowerSystem.systemName, stage: .update) { _ in system.update() }
        return system
    }

    /// What every `PathFollower` hit at the ends of its path during the last update, by entity.
    @MainActor public func pathFollowerEvents() -> [(entity: Entity, event: PathFollowerEvent)] {
        var out: [(entity: Entity, event: PathFollowerEvent)] = []
        query(PathFollower.self) { entity, follower in out += follower.events.map { (entity, $0) } }
        return out
    }
}
