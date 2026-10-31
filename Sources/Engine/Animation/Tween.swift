import Foundation

/// One running animation of a value over time: after `delay` seconds it plays `duration`
/// seconds from the start value to the end value through `ease`, then repeats `repeatCount`
/// more times (`yoyo` plays every other repeat backward, ending back at the start when the
/// total number of plays is even). Created through `TweenSystem`, which advances it.
///
/// Time only moves through `advance(_:)`, so a tween is deterministic given its dt sequence,
/// and one large dt crosses delays and repeat boundaries correctly. The value is applied
/// through a closure with the eased progress (it can overshoot 0...1 for `.back` / `.elastic`).
@MainActor
public final class Tween {
    public var duration: Float
    public var delay: Float
    public var ease: Easing
    /// Plays after the first: 0 plays once, 2 plays three times, -1 repeats forever.
    public var repeatCount: Int
    public var yoyo: Bool
    /// Multiplies dt (0 holds the tween, 2 runs it twice as fast).
    public var timeScale: Float = 1
    public var isPaused = false
    /// Called once when the tween has played its last repeat (not after `cancel()`).
    public var onComplete: (() -> Void)?
    /// Called after every update that applied a value, with the eased progress.
    public var onUpdate: ((Float) -> Void)?

    /// Seconds advanced so far, delay included.
    public private(set) var elapsed: Float = 0
    public private(set) var isFinished = false
    /// Whether the value was applied (and the start value captured) at least once.
    public private(set) var hasStarted = false

    private let begin: () -> Void
    private let apply: (Float) -> Void
    /// Cancels the tween when it returns false (e.g. its entity was despawned).
    var isTargetAlive: (() -> Bool)?

    /// `begin` runs once when the delay is over, before the first `apply` (to read the start value).
    init(duration: Float, delay: Float, ease: Easing, repeatCount: Int, yoyo: Bool,
         begin: @escaping () -> Void, apply: @escaping (Float) -> Void) {
        self.duration = max(duration, 0)
        self.delay = max(delay, 0)
        self.ease = ease
        self.repeatCount = repeatCount
        self.yoyo = yoyo
        self.begin = begin
        self.apply = apply
    }

    /// Total playing time (delay excluded), nil when it repeats forever.
    public var totalDuration: Float? {
        repeatCount < 0 ? nil : duration * Float(repeatCount + 1)
    }

    /// Stops the tween where it is; `onComplete` is not called.
    public func cancel() { isFinished = true }

    /// Jumps to the end value and finishes (calls `onComplete`). Does nothing for infinite tweens.
    public func complete() {
        guard let total = totalDuration, !isFinished else { return }
        elapsed = delay + total
        advance(0)
    }

    /// Moves time forward by `dt * timeScale` seconds and applies the value for the new time.
    /// Returns true once the tween has finished.
    @discardableResult
    public func advance(_ dt: Float) -> Bool {
        guard !isFinished else { return true }
        if let isTargetAlive, !isTargetAlive() {
            isFinished = true
            return true
        }
        guard !isPaused else { return false }
        elapsed += dt * timeScale
        let local = elapsed - delay
        guard local >= 0 else { return false }
        if !hasStarted {
            hasStarted = true
            begin()
        }
        var iteration = 0
        var fraction: Float = 1
        var done = true
        if duration > 0 {
            let cycles = local / duration
            if repeatCount >= 0 && cycles >= Float(repeatCount + 1) {
                iteration = repeatCount
            } else {
                iteration = Int(cycles.rounded(.down))
                fraction = cycles - Float(iteration)
                done = false
            }
        }
        let reversed = yoyo && iteration % 2 == 1
        let progress = ease(reversed ? 1 - fraction : fraction)
        apply(progress)
        onUpdate?(progress)
        if done {
            isFinished = true
            onComplete?()
        }
        return isFinished
    }
}

/// Owns running tweens and advances them. Create tweens with the `tween` functions (a closure,
/// a key path on a class, or a key path on a component), and call `update(dt:)` every frame,
/// or `world.addTweenSystem(_:)` to do that from the world's `.update` stage.
///
/// ```swift
/// let tweens = TweenSystem()
/// tweens.tween(from: 0, to: 1, duration: 0.5, ease: .backOut) { fade = $0 }
/// tweens.tween(\Transform.position, of: entity, in: world, to: Vec3(0, 2, 0), duration: 1, ease: .cubicInOut)
/// ```
/// A tween's start value is read when its delay ends (the `to:`-only forms), so tweens queued
/// back to back start from where the previous one left the value.
@MainActor
public final class TweenSystem {
    public private(set) var tweens: [Tween] = []

    public init() {}

    public var count: Int { tweens.count }

    /// Tweens from `from` to `to`, calling `apply` with every value (and `to` at the end).
    @discardableResult
    public func tween<V: Animatable>(
        from: V, to: V, duration: Float, delay: Float = 0, ease: Easing = .linear, repeatCount: Int = 0, yoyo: Bool = false,
        apply: @escaping (V) -> Void
    ) -> Tween {
        add(Tween(duration: duration, delay: delay, ease: ease, repeatCount: repeatCount, yoyo: yoyo,
                  begin: {}, apply: { apply(V.lerp(from, to, $0)) }))
    }

    /// Tweens from the value `get` returns when the delay ends to `to`.
    @discardableResult
    public func tween<V: Animatable>(
        to: V, duration: Float, delay: Float = 0, ease: Easing = .linear, repeatCount: Int = 0, yoyo: Bool = false,
        get: @escaping () -> V, apply: @escaping (V) -> Void
    ) -> Tween {
        var start = to
        return add(Tween(duration: duration, delay: delay, ease: ease, repeatCount: repeatCount, yoyo: yoyo,
                         begin: { start = get() }, apply: { apply(V.lerp(start, to, $0)) }))
    }

    /// Tweens a property of an object: `tween(sprite, \.alpha, to: 0, duration: 1)`.
    @discardableResult
    public func tween<Root: AnyObject, V: Animatable>(
        _ root: Root, _ keyPath: ReferenceWritableKeyPath<Root, V>, to: V, duration: Float, delay: Float = 0,
        ease: Easing = .linear, repeatCount: Int = 0, yoyo: Bool = false
    ) -> Tween {
        tween(to: to, duration: duration, delay: delay, ease: ease, repeatCount: repeatCount, yoyo: yoyo,
              get: { root[keyPath: keyPath] }, apply: { root[keyPath: keyPath] = $0 })
    }

    /// Tweens a field of an entity's component: `tween(\Transform.position, of: e, in: world, to: ...)`.
    /// The tween ends (without `onComplete`) if the entity is despawned or loses the component.
    @discardableResult
    public func tween<C: Component, V: Animatable>(
        _ keyPath: WritableKeyPath<C, V>, of entity: Entity, in world: World, to: V, duration: Float, delay: Float = 0,
        ease: Easing = .linear, repeatCount: Int = 0, yoyo: Bool = false
    ) -> Tween {
        let tween = tween(
            to: to, duration: duration, delay: delay, ease: ease, repeatCount: repeatCount, yoyo: yoyo,
            get: { world.get(C.self, for: entity)?[keyPath: keyPath] ?? to },
            apply: { value in world.modify(C.self, for: entity) { $0[keyPath: keyPath] = value } })
        tween.isTargetAlive = { world.has(C.self, for: entity) }
        return tween
    }

    /// Plays `curve` from its start time to its end time (scaled by `speed`), calling `apply`
    /// with each sampled value. `ease` reshapes the time (`.linear` plays at constant speed).
    @discardableResult
    public func play<V: Animatable>(
        _ curve: AnimationCurve<V>, speed: Float = 1, delay: Float = 0, ease: Easing = .linear, repeatCount: Int = 0,
        yoyo: Bool = false, apply: @escaping (V) -> Void
    ) -> Tween {
        let start = curve.startTime, length = curve.duration
        return add(Tween(duration: length / max(speed, 1e-6), delay: delay, ease: ease, repeatCount: repeatCount, yoyo: yoyo,
                         begin: {}, apply: { apply(curve.evaluate(at: start + $0 * length)) }))
    }

    /// Advances every tween by `dt` seconds and drops the finished ones. Tweens started from
    /// completion callbacks begin next update.
    public func update(dt: Float) {
        for tween in tweens { tween.advance(dt) }
        tweens.removeAll { $0.isFinished }
    }

    public func cancelAll() {
        for tween in tweens { tween.cancel() }
        tweens.removeAll()
    }

    private func add(_ tween: Tween) -> Tween {
        tweens.append(tween)
        return tween
    }
}

extension World {
    /// Advances `tweens` every frame in the `.update` stage by the frame's dt.
    public func addTweenSystem(_ tweens: TweenSystem, name: String = "tweens") {
        addSystem(name) { world in tweens.update(dt: world.time.delta) }
    }
}
