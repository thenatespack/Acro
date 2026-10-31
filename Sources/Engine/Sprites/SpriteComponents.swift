import Foundation

/// Names a `SpriteAtlas` registered with a `SpriteRenderer` (`registerAtlas(_:key:)`).
/// Encodes as its key string, like `MeshHandle`.
public struct SpriteAtlasHandle: Hashable, Codable, Sendable, CustomStringConvertible {
    public var key: String

    public init(_ key: String) { self.key = key }

    public init(from decoder: Decoder) throws { key = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(key)
    }

    public var description: String { "sprite atlas '\(key)'" }
}

/// Draws one frame of a sprite atlas at the entity's `GlobalTransform` (the quad lies in the
/// entity's local XY plane, `pivot` at the origin, facing +Z). `SpriteRenderer.draw(world:)`
/// queues every sprite entity; a `SpriteAnimator` on the same entity drives `frame`.
public struct Sprite: Component, Codable, Equatable, Sendable {
    public static let componentName = "Sprite"
    public static var fieldHints: [String: FieldHints] {
        ["order": FieldHints(tooltip: "Draw order: larger is in front"),
         "size": FieldHints(tooltip: "World size (nil: the frame's pixel size / pixels per unit)"),
         "pivot": FieldHints(tooltip: "0...1 from the bottom-left (nil: the frame's)")]
    }

    public var atlas: SpriteAtlasHandle
    /// Index into the atlas's frames.
    public var frame: Int
    /// Linear RGBA multiplied with the texture.
    public var tint: Vec4
    public var flipX: Bool
    public var flipY: Bool
    public var order: Float
    public var blend: SpriteBlend
    public var size: Vec2?
    public var pivot: Vec2?
    public var visible: Bool

    public init(atlas: SpriteAtlasHandle, frame: Int = 0, tint: Vec4 = Vec4(1, 1, 1, 1), flipX: Bool = false,
                flipY: Bool = false, order: Float = 0, blend: SpriteBlend = .alpha, size: Vec2? = nil,
                pivot: Vec2? = nil, visible: Bool = true) {
        self.atlas = atlas
        self.frame = frame
        self.tint = tint
        self.flipX = flipX
        self.flipY = flipY
        self.order = order
        self.blend = blend
        self.size = size
        self.pivot = pivot
        self.visible = visible
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        atlas = try c.decode(SpriteAtlasHandle.self, forKey: .atlas)
        frame = try c.decodeIfPresent(Int.self, forKey: .frame) ?? 0
        tint = try c.decodeIfPresent(Vec4.self, forKey: .tint) ?? Vec4(1, 1, 1, 1)
        flipX = try c.decodeIfPresent(Bool.self, forKey: .flipX) ?? false
        flipY = try c.decodeIfPresent(Bool.self, forKey: .flipY) ?? false
        order = try c.decodeIfPresent(Float.self, forKey: .order) ?? 0
        blend = try c.decodeIfPresent(SpriteBlend.self, forKey: .blend) ?? .alpha
        size = try c.decodeIfPresent(Vec2.self, forKey: .size)
        pivot = try c.decodeIfPresent(Vec2.self, forKey: .pivot)
        visible = try c.decodeIfPresent(Bool.self, forKey: .visible) ?? true
    }

    var flip: SpriteFlip {
        var flip: SpriteFlip = []
        if flipX { flip.insert(.horizontal) }
        if flipY { flip.insert(.vertical) }
        return flip
    }
}

// MARK: - Flipbook animation

public enum SpriteLoopMode: String, Codable, Sendable {
    /// Wraps from the last frame to the first.
    case loop
    /// Plays through once and holds the last frame.
    case once
    /// Plays forward, then backward without repeating the end frames, and so on.
    case pingPong
}

/// A named event that fires when a clip reaches the frame at position `step` in its list.
public struct SpriteClipEvent: Codable, Equatable, Sendable {
    public var step: Int
    public var name: String

    public init(step: Int, name: String) {
        self.step = step
        self.name = name
    }
}

/// A flipbook clip: atlas frame indices played at `fps`. Stepping is pure arithmetic on time
/// (frame number = floor(time * fps)), so it is deterministic and independent of the dt split.
public struct SpriteClip: Codable, Equatable, Sendable {
    public var name: String
    /// Atlas frame indices in playing order (see `SpriteAtlas.frameIndices(prefix:)`).
    public var frames: [Int]
    public var fps: Float
    public var mode: SpriteLoopMode
    public var events: [SpriteClipEvent]

    public init(_ name: String, frames: [Int], fps: Float = 12, mode: SpriteLoopMode = .loop, events: [SpriteClipEvent] = []) {
        self.name = name
        self.frames = frames
        self.fps = fps
        self.mode = mode
        self.events = events
    }

    /// Ticks (frame durations) after which the pattern repeats: all frames for `loop`, forward
    /// and back for `pingPong`.
    var cycleLength: Int {
        mode == .pingPong ? max(2 * frames.count - 2, 1) : max(frames.count, 1)
    }

    /// The tick (frame number since the start) at `time` seconds.
    public func tick(at time: Float) -> Int {
        fps > 0 ? Int((max(time, 0) * fps).rounded(.down)) : 0
    }

    /// The position in `frames` shown during `tick`.
    public func step(atTick tick: Int) -> Int {
        let n = frames.count
        guard n > 1 else { return 0 }
        switch mode {
        case .loop: return tick % n
        case .once: return min(tick, n - 1)
        case .pingPong:
            let p = tick % cycleLength
            return p < n ? p : cycleLength - p
        }
    }

    /// The atlas frame shown at `time` seconds.
    public func frame(at time: Float) -> Int? {
        frames.isEmpty ? nil : frames[step(atTick: tick(at: time))]
    }

    /// Whether a `once` clip has played every frame by `time` (loops never finish).
    public func isFinished(at time: Float) -> Bool {
        mode == .once && tick(at: time) >= frames.count
    }

    /// Seconds for one pass: all frames for `once` and `loop`, forward and back for `pingPong`.
    public var duration: Float { fps > 0 ? Float(cycleLength) / fps : 0 }
}

/// Plays `SpriteClip`s on the entity's `Sprite`: `SpriteAnimator.update(world:dt:)` (or the
/// system from `World.addSpriteAnimationSystem()`) advances `time` and sets `Sprite.frame`.
///
/// Read `events` (the clip events reached during the last update), `justFinished` (a `once`
/// clip ended in the last update) and `isFinished` from your own systems, or pass an
/// `onEvent` closure to the animation system. Switch clips with `play(_:)`.
public struct SpriteAnimator: Component, Codable, Equatable, Sendable {
    public static let componentName = "SpriteAnimator"

    public var clips: [SpriteClip]
    /// Name of the playing clip.
    public var current: String?
    /// Seconds into the current clip.
    public var time: Float
    /// Playback rate multiplier.
    public var speed: Float
    public var isPlaying: Bool
    /// A `once` clip has played to its end (held on the last frame until `play` restarts it).
    public private(set) var isFinished = false
    /// A `once` clip finished during the last update.
    public private(set) var justFinished = false
    /// Names of the clip events reached during the last update, in order.
    public private(set) var events: [String] = []
    private var lastTick = -1

    public init(clips: [SpriteClip], current: String? = nil, speed: Float = 1, isPlaying: Bool = true) {
        self.clips = clips
        self.current = current ?? clips.first?.name
        self.time = 0
        self.speed = speed
        self.isPlaying = isPlaying
    }

    private enum CodingKeys: String, CodingKey { case clips, current, time, speed, isPlaying }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clips = try c.decodeIfPresent([SpriteClip].self, forKey: .clips) ?? []
        current = try c.decodeIfPresent(String.self, forKey: .current) ?? clips.first?.name
        time = try c.decodeIfPresent(Float.self, forKey: .time) ?? 0
        speed = try c.decodeIfPresent(Float.self, forKey: .speed) ?? 1
        isPlaying = try c.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? true
        // The ticks up to `time` were already played, so events don't refire on load.
        lastTick = currentClip.map { $0.tick(at: time) - 1 } ?? -1
    }

    public var currentClip: SpriteClip? { clips.first { $0.name == current } }

    /// Starts clip `name` from its first frame. A clip that is already playing is left alone
    /// unless `restart` is true.
    public mutating func play(_ name: String, restart: Bool = false) {
        if current == name && !restart && !isFinished { return }
        current = name
        time = 0
        lastTick = -1
        isFinished = false
        justFinished = false
        events.removeAll()
        isPlaying = true
    }

    /// Advances the current clip by `dt * speed` seconds and returns the atlas frame to show
    /// (nil without a clip or frames).
    @discardableResult
    public mutating func advance(dt: Float) -> Int? {
        events.removeAll()
        justFinished = false
        guard let clip = currentClip, !clip.frames.isEmpty else { return nil }
        if isPlaying && !isFinished { time += dt * speed }
        let tick = clip.tick(at: time)
        // A `once` clip stays on its last frame, so its events fire only once; a long step
        // fires the events of at most the last cycle of frames it skipped.
        let last = clip.mode == .once ? min(tick, clip.frames.count - 1) : tick
        if last > lastTick {
            for t in max(lastTick + 1, last - clip.cycleLength + 1)...last {
                let step = clip.step(atTick: t)
                for event in clip.events where event.step == step { events.append(event.name) }
            }
            lastTick = last
        }
        if !isFinished && clip.isFinished(at: time) {
            isFinished = true
            justFinished = true
        }
        return clip.frames[clip.step(atTick: tick)]
    }

    /// Advances every animator in `world` by `dt` and writes the frame to the entity's
    /// `Sprite`. `onEvent` is called for each clip event once all animators have advanced, so
    /// it may change components (a flash tween on the sprite, switching a clip).
    @MainActor
    public static func update(world: World, dt: Float, onEvent: ((Entity, String) -> Void)? = nil) {
        var fired: [(Entity, String)] = []
        world.queryMutating(SpriteAnimator.self, Sprite.self) { entity, animator, sprite in
            if let frame = animator.advance(dt: dt) { sprite.frame = frame }
            if onEvent != nil { fired.append(contentsOf: animator.events.map { (entity, $0) }) }
        }
        if let onEvent { for (entity, name) in fired { onEvent(entity, name) } }
    }
}

extension World {
    /// Advances every `SpriteAnimator` each frame in the `.update` stage (by the frame's dt).
    public func addSpriteAnimationSystem(name: String = "spriteAnimation", onEvent: ((Entity, String) -> Void)? = nil) {
        addSystem(name) { world in SpriteAnimator.update(world: world, dt: world.time.delta, onEvent: onEvent) }
    }
}
