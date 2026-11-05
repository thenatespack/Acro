import Foundation

/// Moves its entity (usually the `Camera`) along a smooth path through waypoints: a slow dolly,
/// a fly-through, a showcase orbit. The path is a Catmull-Rom spline through `waypoints` (the
/// world positions of entities) or, with none, through `points` (positions in the entity's
/// parent space, world space for a root entity). Speed along the path is constant unless
/// `constantSpeed` is off (then it follows the spline's own parameterization).
///
/// The entity faces the `lookAtTarget` entity or the `lookAtPoint`, or its direction of travel
/// with `followTangent`, else keeps the rotation it had. `handheld` and `handheldRotation` add
/// deterministic smooth noise to the position (units) and aim (degrees) for a hand-held feel.
///
/// Positions and aim are computed in the entity's parent space, so keep a camera on a path
/// unparented (or under an identity parent). Runs in `.lateUpdate` from
/// `World.addBuiltinAnimationSystems()`, after gameplay systems moved things.
public struct CameraPath: Component, Equatable, Sendable {
    public static let componentName = "CameraPath"
    public static var fieldHints: [String: FieldHints] {
        ["duration": FieldHints(range: 0.01...36000, step: 0.1, tooltip: "Seconds to travel the whole path once"),
         "delay": FieldHints(range: 0...3600, step: 0.1),
         "points": FieldHints(tooltip: "Used when there are no waypoint entities; parent-space positions"),
         "waypoints": FieldHints(tooltip: "Entities whose world positions form the path (override points)"),
         "closed": FieldHints(tooltip: "Join the last point back to the first (smooth with loop)"),
         "lookAtPoint": FieldHints(tooltip: "Aim at this point (when there is no look-at entity)"),
         "handheld": FieldHints(range: 0...2, step: 0.005, tooltip: "Positional shake amplitude, in units"),
         "handheldRotation": FieldHints(range: 0...10, step: 0.05, tooltip: "Aim shake amplitude, in degrees"),
         "handheldSpeed": FieldHints(range: 0...20, step: 0.05)]
    }

    public var points: [Vec3]
    public var waypoints: [EntityRef]
    public var duration: Float
    public var delay: Float
    public var loop: AnimationLoop
    public var easing: Easing
    public var closed: Bool
    public var constantSpeed: Bool
    public var lookAtTarget: EntityRef
    public var lookAtPoint: Vec3?
    public var followTangent: Bool
    public var handheld: Float
    public var handheldRotation: Float
    public var handheldSpeed: Float
    public var seed: Int
    public var enabled: Bool

    // Runtime state, not coded.
    var time: Double = 0
    var baseRotation: Quat?

    public init(points: [Vec3] = [Vec3(0, 2, 10), Vec3(0, 2, 0)], waypoints: [EntityRef] = [], duration: Float = 10,
                delay: Float = 0, loop: AnimationLoop = .once, easing: Easing = .linear, closed: Bool = false,
                constantSpeed: Bool = true, lookAtTarget: EntityRef = .none, lookAtPoint: Vec3? = nil,
                followTangent: Bool = false, handheld: Float = 0, handheldRotation: Float = 0, handheldSpeed: Float = 1.5,
                seed: Int = 0, enabled: Bool = true) {
        self.points = points
        self.waypoints = waypoints
        self.duration = duration
        self.delay = delay
        self.loop = loop
        self.easing = easing
        self.closed = closed
        self.constantSpeed = constantSpeed
        self.lookAtTarget = lookAtTarget
        self.lookAtPoint = lookAtPoint
        self.followTangent = followTangent
        self.handheld = handheld
        self.handheldRotation = handheldRotation
        self.handheldSpeed = handheldSpeed
        self.seed = seed
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey {
        case points, waypoints, duration, delay, loop, easing, closed, constantSpeed, lookAtTarget, lookAtPoint, followTangent
        case handheld, handheldRotation, handheldSpeed, seed, enabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = CameraPath()
        self.init(points: try c.decodeIfPresent([Vec3].self, forKey: .points) ?? d.points,
                  waypoints: try c.decodeIfPresent([EntityRef].self, forKey: .waypoints) ?? d.waypoints,
                  duration: try c.decodeIfPresent(Float.self, forKey: .duration) ?? d.duration,
                  delay: try c.decodeIfPresent(Float.self, forKey: .delay) ?? d.delay,
                  loop: try c.decodeIfPresent(AnimationLoop.self, forKey: .loop) ?? d.loop,
                  easing: try c.decodeIfPresent(Easing.self, forKey: .easing) ?? d.easing,
                  closed: try c.decodeIfPresent(Bool.self, forKey: .closed) ?? d.closed,
                  constantSpeed: try c.decodeIfPresent(Bool.self, forKey: .constantSpeed) ?? d.constantSpeed,
                  lookAtTarget: try c.decodeIfPresent(EntityRef.self, forKey: .lookAtTarget) ?? d.lookAtTarget,
                  lookAtPoint: try c.decodeIfPresent(Vec3.self, forKey: .lookAtPoint),
                  followTangent: try c.decodeIfPresent(Bool.self, forKey: .followTangent) ?? d.followTangent,
                  handheld: try c.decodeIfPresent(Float.self, forKey: .handheld) ?? d.handheld,
                  handheldRotation: try c.decodeIfPresent(Float.self, forKey: .handheldRotation) ?? d.handheldRotation,
                  handheldSpeed: try c.decodeIfPresent(Float.self, forKey: .handheldSpeed) ?? d.handheldSpeed,
                  seed: try c.decodeIfPresent(Int.self, forKey: .seed) ?? d.seed,
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? d.enabled)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(points, forKey: .points)
        try c.encode(waypoints, forKey: .waypoints)
        try c.encode(duration, forKey: .duration)
        try c.encode(delay, forKey: .delay)
        try c.encode(loop, forKey: .loop)
        try c.encode(easing, forKey: .easing)
        try c.encode(closed, forKey: .closed)
        try c.encode(constantSpeed, forKey: .constantSpeed)
        try c.encode(lookAtTarget, forKey: .lookAtTarget)
        try c.encodeIfPresent(lookAtPoint, forKey: .lookAtPoint)
        try c.encode(followTangent, forKey: .followTangent)
        try c.encode(handheld, forKey: .handheld)
        try c.encode(handheldRotation, forKey: .handheldRotation)
        try c.encode(handheldSpeed, forKey: .handheldSpeed)
        try c.encode(seed, forKey: .seed)
        try c.encode(enabled, forKey: .enabled)
    }

    // MARK: Spline

    /// The path's control points: the waypoint entities' world positions (those that exist), else `points`.
    @MainActor public func controlPoints(in world: World) -> [Vec3] {
        guard !waypoints.isEmpty else { return points }
        let resolved = waypoints.compactMap { ref in world.resolve(ref).map { Self.worldPosition(of: $0, in: world) } }
        return resolved.isEmpty ? points : resolved
    }

    @MainActor static func worldPosition(of entity: Entity, in world: World) -> Vec3 {
        let m = world.worldMatrix(of: entity)
        return Vec3(m.c3.x, m.c3.y, m.c3.z)
    }

    private static func catmullRom(_ p0: Vec3, _ p1: Vec3, _ p2: Vec3, _ p3: Vec3, _ t: Float) -> Vec3 {
        let t2 = t * t, t3 = t2 * t
        let a = p1 * 2
        let b = (p2 - p0) * t
        let c = (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
        let d = (p1 * 3 - p0 - p2 * 3 + p3) * t3
        return (a + b + c + d) * 0.5
    }

    private static func segmentCount(_ n: Int, closed: Bool) -> Int { n < 2 ? 0 : (closed && n > 2 ? n : n - 1) }

    /// The spline at parameter `u` in 0...segments (one unit per segment).
    public func position(at u: Float, controlPoints p: [Vec3]) -> Vec3 {
        let n = p.count
        guard n > 0 else { return .zero }
        let segments = Self.segmentCount(n, closed: closed)
        guard segments > 0 else { return p[0] }
        let wraps = closed && n > 2
        let clamped = min(max(u, 0), Float(segments))
        let i = min(Int(clamped.rounded(.down)), segments - 1)
        let t = clamped - Float(i)
        func point(_ k: Int) -> Vec3 { wraps ? p[((k % n) + n) % n] : p[min(max(k, 0), n - 1)] }
        return Self.catmullRom(point(i - 1), point(i), point(i + 1), point(i + 2), t)
    }

    /// Samples of the path for drawing, `perSegment` per segment plus the end.
    @MainActor public func previewPoints(in world: World, perSegment: Int = 16) -> [Vec3] {
        let p = controlPoints(in: world)
        let segments = Self.segmentCount(p.count, closed: closed)
        guard segments > 0 else { return p }
        return (0...(segments * perSegment)).map { position(at: Float($0) / Float(perSegment), controlPoints: p) }
    }

    /// Maps a distance fraction 0...1 to the spline parameter, so equal steps cover equal distance.
    private func parameter(forDistanceFraction s: Float, controlPoints p: [Vec3]) -> Float {
        let segments = Self.segmentCount(p.count, closed: closed)
        guard segments > 0 else { return 0 }
        guard constantSpeed else { return s * Float(segments) }
        let perSegment = 12
        let steps = segments * perSegment
        var cumulative = [Float](repeating: 0, count: steps + 1)
        var previous = position(at: 0, controlPoints: p)
        for k in 1...steps {
            let point = position(at: Float(k) / Float(perSegment), controlPoints: p)
            cumulative[k] = cumulative[k - 1] + length(point - previous)
            previous = point
        }
        let total = cumulative[steps]
        guard total > 0 else { return s * Float(segments) }
        let target = s * total
        var lo = 0, hi = steps
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if cumulative[mid] <= target { lo = mid } else { hi = mid }
        }
        let span = cumulative[hi] - cumulative[lo]
        let f = span > 0 ? (target - cumulative[lo]) / span : 0
        return (Float(lo) + f) / Float(perSegment)
    }

    /// Position, travel direction and the fraction travelled for the clock `time`.
    func sample(time: Float, controlPoints p: [Vec3]) -> (position: Vec3, forward: Vec3)? {
        guard !p.isEmpty else { return nil }
        let x = max(time - delay, 0) / max(duration, 1e-4)
        let progress: Float
        var reverse = false
        switch loop {
        case .once: progress = min(x, 1)
        case .loop: progress = x - x.rounded(.down)
        case .pingPong:
            let m = x.truncatingRemainder(dividingBy: 2)
            reverse = m > 1
            progress = reverse ? 2 - m : m
        }
        let s = easing(progress)
        let segments = Float(Self.segmentCount(p.count, closed: closed))
        let u = parameter(forDistanceFraction: min(max(s, 0), 1), controlPoints: p)
        let here = position(at: u, controlPoints: p)
        let eps: Float = 0.02
        var ahead = position(at: min(u + eps, segments), controlPoints: p)
        var behind = position(at: max(u - eps, 0), controlPoints: p)
        if closed, segments > 0 {
            ahead = position(at: u + eps > segments ? u + eps - segments : u + eps, controlPoints: p)
            behind = position(at: u - eps < 0 ? u - eps + segments : u - eps, controlPoints: p)
        }
        var forward = ahead - behind
        if reverse { forward = -forward }
        return (here, forward)
    }
}

extension World {
    /// Moves every `CameraPath` entity; `addBuiltinAnimationSystems()` registers this.
    @MainActor func runCameraPaths() {
        guard count(of: CameraPath.self) > 0 else { return }
        let dt = Double(time.delta)
        var entities: [Entity] = []
        query(CameraPath.self) { entity, _ in entities.append(entity) }
        for entity in entities {
            guard var path = get(CameraPath.self, for: entity), path.enabled, let transform = get(Transform.self, for: entity) else { continue }
            path.time += dt
            defer { add(path, to: entity) }
            let controls = path.controlPoints(in: self)
            let t = Float(path.time)
            guard let sampled = path.sample(time: t, controlPoints: controls) else { continue }
            var position = sampled.position
            var aim: Quat?
            let up = Vec3(0, 1, 0)
            func facing(_ direction: Vec3) -> Quat? {
                let l = length(direction)
                guard l > 1e-5, abs(dot(direction / l, up)) < 0.9999 else { return nil }
                return .lookRotation(forward: direction / l, up: up)
            }
            if let target = resolve(path.lookAtTarget) {
                aim = facing(CameraPath.worldPosition(of: target, in: self) - position)
            } else if let point = path.lookAtPoint {
                aim = facing(point - position)
            } else if path.followTangent {
                aim = facing(sampled.forward)
            }
            if aim == nil, path.handheldRotation > 0 {
                if path.baseRotation == nil { path.baseRotation = transform.rotation }
                aim = path.baseRotation
            }
            var rotation = aim ?? transform.rotation
            let noiseSeed = AnimationNoise.seed(path.seed, entity: entity)
            let x = t * path.handheldSpeed
            func shake(_ k: UInt64) -> Float { AnimationNoise.fractal(x + Float(k) * 17.3, seed: noiseSeed ^ (k &* 0x9E37)) }
            if path.handheld > 0 {
                position += rotation * Vec3(shake(1), shake(2), shake(3)) * path.handheld
            }
            if path.handheldRotation > 0 {
                rotation = (rotation * Quat(eulerDegrees: Vec3(shake(4), shake(5), shake(6)) * path.handheldRotation)).normalized
            }
            modify(Transform.self, for: entity) { $0.position = position; $0.rotation = rotation }
        }
    }
}
