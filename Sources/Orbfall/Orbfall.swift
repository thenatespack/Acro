import Engine
import Foundation

// Orbfall: a peg-clearing arcade game as a game module. The level (walls, pegs, launcher,
// bucket) is authored in the editor; this module supplies the components and the rules.
//
// Controls: Left / Right (or A / D) aim, hold Shift to aim finely, Space fires, R restarts.
// Light every orange peg to win. Green pegs give an extra ball, so does the moving bucket.

// MARK: Components

public enum PegKind: String, Codable, CaseIterable, Sendable {
    case normal, target, bonus

    var points: Int {
        switch self {
        case .normal: 10
        case .target: 100
        case .bonus: 50
        }
    }

    var color: Vec3 {
        switch self {
        case .normal: Vec3(0.18, 0.42, 1.0)
        case .target: Vec3(1.0, 0.45, 0.08)
        case .bonus: Vec3(0.2, 0.85, 0.3)
        }
    }
}

/// A peg: lights up when the ball touches it, vanishes when the shot ends.
public struct Peg: Component, Equatable, Sendable {
    public static let componentName = "Peg"
    public static var fieldHints: [String: FieldHints] {
        ["kind": FieldHints(tooltip: "normal: 10 pts. target: 100 pts, clear them all to win. bonus: 50 pts and an extra ball"),
         "shape": FieldHints(tooltip: "round: circle collider; brick: box collider. Sized from the Transform's scale"),
         "lit": FieldHints(tooltip: "Runtime: hit this shot"),
         "cleared": FieldHints(tooltip: "Runtime: removed from the board")]
    }

    public var kind: PegKind = .normal
    public var shape: PegShape = .round
    public var lit = false
    public var cleared = false
    /// Seconds into its vanish animation; nil when not vanishing.
    public var vanish: Float?
    /// Taken from the Transform / Collider2D on the first frame, to restore on restart.
    public var baseScale: Vec3?
    public var baseLayer: UInt32?
    public var baseMask: UInt32?
    /// The glow sprite behind it while lit.
    public var halo: Entity?

    public init(kind: PegKind = .normal) { self.kind = kind }
}

public enum PegShape: String, Codable, CaseIterable, Sendable {
    /// A circle collider (diameter: the Transform's x scale).
    case round
    /// A box collider (the Transform's x / y scale), turned with the Transform's z rotation.
    case brick
}

public enum OrbfallPhase: String, Codable, CaseIterable, Sendable {
    case aiming, flying, clearing, won, lost
}

/// The launcher and the game's state. One per level.
public struct Launcher: Component, Equatable, Sendable {
    public static let componentName = "Launcher"
    public static var fieldHints: [String: FieldHints] {
        ["angle": FieldHints(tooltip: "Radians from straight down; positive aims right"),
         "maxAngle": FieldHints(range: 0...1.57, step: 0.01),
         "aimSpeed": FieldHints(range: 0...5, step: 0.05, tooltip: "Radians per second"),
         "launchSpeed": FieldHints(range: 1...40, step: 0.5, tooltip: "m/s"),
         "startingBalls": FieldHints(range: 1...30, step: 1),
         "ballRadius": FieldHints(range: 0.05...1, step: 0.01),
         "killY": FieldHints(tooltip: "A ball below this is out")]
    }

    // Tuning.
    public var angle: Float = 0
    public var maxAngle: Float = 1.45
    public var aimSpeed: Float = 1.4
    public var launchSpeed: Float = 13
    public var startingBalls = 10
    public var ballRadius: Float = 0.22
    public var killY: Float = -11
    /// Look of what the launcher spawns (the ball, aim dots, HUD): a flat quad mesh and
    /// unlit sprite materials, set in the editor.
    public var spriteMesh = MeshHandle.sphere
    public var ballMaterial = MaterialHandle.default
    public var dotMaterial = MaterialHandle.default
    public var barMaterial = MaterialHandle.default
    public var glowMaterial = MaterialHandle.default

    // Runtime state.
    public var phase: OrbfallPhase = .aiming
    public var ballsLeft = 10
    public var score = 0
    public var shotScore = 0
    public var shotHits = 0
    public var targetsTotal = 0
    public var ball: Entity?
    public var slowTime: Float = 0
    public var started = false

    public init() {}

    var aimDirection: Vec2 { Vec2(sinf(angle), -cosf(angle)) }
}

/// Glides left and right along the bottom; a ball that drops into it is a free ball.
public struct Bucket: Component, Equatable, Sendable {
    public static let componentName = "Bucket"
    public static var fieldHints: [String: FieldHints] {
        ["range": FieldHints(range: 0...20, step: 0.1, tooltip: "Units either side of where it starts"),
         "speed": FieldHints(range: 0...20, step: 0.1, tooltip: "Units per second"),
         "halfWidth": FieldHints(range: 0.1...5, step: 0.05, tooltip: "Catch zone half width")]
    }

    public var range: Float = 5
    public var speed: Float = 3.5
    public var halfWidth: Float = 1.0
    public var origin: Vec3?

    public init() {}
}

/// Marks the live ball (spawned by the launcher).
public struct Orb: Component, Equatable, Sendable {
    public static let componentName = "Orb"
    public init() {}
}

/// Play-time decorations the launcher spawns: aim dots and the balls-left / progress HUD.
public struct OrbfallHUD: Component, Equatable, Sendable {
    public static let componentName = "OrbfallHUD"
    public enum Role: String, Codable, CaseIterable, Sendable { case aimDot, ballIcon, meterFill }
    public var role: Role = .aimDot
    public var index = 0
    public init() {}
    init(_ role: Role, _ index: Int) {
        self.role = role
        self.index = index
    }
}

// MARK: Module

@_cdecl("swift_game_engine_module_v1")
public func registerOrbfall(_ module: UnsafeMutableRawPointer) -> Int32 {
    GameModule.register(module) { game in
        game.name = "Orbfall"
        game.summary = "Peg-clearing arcade: aim, fire, light every orange peg"
        game.component(Peg.self, icon: #"<circle cx="12" cy="12" r="6"/>"#) { Peg() }
        game.component(Launcher.self, icon: #"<path d="M12 3v10"/><circle cx="12" cy="17" r="4"/>"#) { Launcher() }
        game.component(Bucket.self, icon: #"<path d="M4 8h16l-2 11H6z"/>"#) { Bucket() }
        game.component(Orb.self, icon: "circle") { Orb() }
        game.component(OrbfallHUD.self, icon: #"<circle cx="12" cy="12" r="3"/>"#) { OrbfallHUD() }
        game.system("orbfall.bucket") { world, _ in OrbfallSystems.moveBuckets(world) }
        game.system("orbfall.game", after: "orbfall.bucket") { world, context in
            OrbfallSystems.run(world, input: context.input, log: context.log)
        }
        game.system("orbfall.pegs", after: "orbfall.game") { world, _ in OrbfallSystems.animatePegs(world) }
        game.component(Pulse.self, icon: "heart") { Pulse() }
        game.system("orbfall.pulse") { world, _ in PulseSystem.run(world) }
    }
}

// MARK: Systems

@MainActor
enum OrbfallSystems {
    static let aimDots = 22
    /// Tints over 1 push the unlit sprites into HDR: they glow (and bloom).
    static let litTint = Vec3(2.0, 2.0, 2.0)
    static let maxIcons = 20

    // MARK: Bucket

    static func moveBuckets(_ world: World) {
        let t = Float(world.time.elapsed)
        world.queryMutating(Transform.self, Bucket.self) { _, transform, bucket in
            let origin = bucket.origin ?? transform.position
            bucket.origin = origin
            guard bucket.range > 0 else { return }
            // Triangle wave: constant speed, turning at the ends.
            let period = 4 * bucket.range / max(bucket.speed, 0.01)
            let u = (t / period).truncatingRemainder(dividingBy: 1)
            let s = u < 0.5 ? 4 * u - 1 : 3 - 4 * u
            transform.position.x = origin.x + s * bucket.range
        }
    }

    // MARK: Game

    static func run(_ world: World, input: Input, log: (String) -> Void) {
        var launcherEntity: Entity?
        world.query(Launcher.self) { entity, _ in if launcherEntity == nil { launcherEntity = entity } }
        guard let entity = launcherEntity, var launcher = world.get(Launcher.self, for: entity),
              let launcherTransform = world.get(Transform.self, for: entity) else { return }
        let dt = world.time.delta

        if !launcher.started {
            start(world, launcher: &launcher, log: log)
        }
        if input.wasPressed(.r) {
            restart(world, launcher: &launcher, log: log)
        }

        let pivot = Vec2(launcherTransform.position.x, launcherTransform.position.y)
        let tip = pivot + launcher.aimDirection * 1.25

        switch launcher.phase {
        case .aiming:
            var turn: Float = 0
            if input.isDown(Key.left) || input.isDown(.a) { turn -= 1 }
            if input.isDown(Key.right) || input.isDown(.d) { turn += 1 }
            let fine: Float = input.isDown(.leftShift) || input.isDown(.rightShift) ? 0.2 : 1
            launcher.angle = min(max(launcher.angle + turn * launcher.aimSpeed * fine * dt, -launcher.maxAngle), launcher.maxAngle)
            if input.wasPressed(.space) || input.wasPressed(.enter) {
                fire(world, launcher: &launcher, from: tip)
            }
        case .flying:
            fly(world, launcher: &launcher, log: log)
        case .clearing:
            if !anyVanishing(world) { finishTurn(world, launcher: &launcher, log: log) }
        case .won, .lost:
            break
        }

        world.modify(Transform.self, for: entity) { $0.rotation = Quat(angle: launcher.angle, axis: Vec3(0, 0, 1)) }
        updateHUD(world, launcher: launcher, tip: tip, z: launcherTransform.position.z)
        world.modify(Launcher.self, for: entity) { $0 = launcher }
    }

    private static func start(_ world: World, launcher: inout Launcher, log: (String) -> Void) {
        launcher.started = true
        launcher.ballsLeft = launcher.startingBalls
        launcher.score = 0
        launcher.phase = .aiming
        var targets = 0
        world.query(Peg.self) { _, peg in if peg.kind == .target { targets += 1 } }
        launcher.targetsTotal = targets
        spawnHUD(world, launcher: launcher)
        log("Orbfall: \(targets) orange pegs, \(launcher.ballsLeft) balls. Left/Right aim (Shift: fine), Space fires, R restarts.")
    }

    private static func restart(_ world: World, launcher: inout Launcher, log: (String) -> Void) {
        if let ball = launcher.ball { world.despawn(ball) }
        launcher.ball = nil
        var pegs: [Entity] = []
        world.query(Peg.self) { entity, _ in pegs.append(entity) }
        for entity in pegs {
            guard var peg = world.get(Peg.self, for: entity) else { continue }
            removeHalo(world, &peg)
            peg.lit = false
            peg.cleared = false
            peg.vanish = nil
            if let scale = peg.baseScale { world.modify(Transform.self, for: entity) { $0.scale = scale } }
            world.modify(Collider2D.self, for: entity) { collider in
                collider.layer = peg.baseLayer ?? collider.layer
                collider.mask = peg.baseMask ?? collider.mask
            }
            world.modify(MeshRenderer.self, for: entity) {
                $0.isVisible = true
                $0.tint = Vec3(1, 1, 1)
            }
            world.add(peg, to: entity)
        }
        launcher.ballsLeft = launcher.startingBalls
        launcher.score = 0
        launcher.angle = 0
        launcher.phase = .aiming
        log("Orbfall: restarted. \(launcher.ballsLeft) balls.")
    }

    private static func fire(_ world: World, launcher: inout Launcher, from tip: Vec2) {
        let r = launcher.ballRadius
        let velocity = launcher.aimDirection * launcher.launchSpeed
        let ball = world.spawn(
            Name("Orb"),
            Transform(position: Vec3(tip.x, tip.y, 0.05), scale: Vec3(repeating: r * 2)),
            MeshRenderer(mesh: launcher.spriteMesh, material: launcher.ballMaterial, castsShadows: false),
            RigidBody2D(.dynamic, linearVelocity: velocity, fixedRotation: true),
            Collider2D(.circle(radius: r), friction: 0.1, restitution: 0.72, density: 2, layer: 2),
            Orb())
        launcher.ball = ball
        launcher.ballsLeft -= 1
        launcher.shotHits = 0
        launcher.shotScore = 0
        launcher.slowTime = 0
        launcher.phase = .flying
    }

    private static func fly(_ world: World, launcher: inout Launcher, log: (String) -> Void) {
        guard let ball = launcher.ball, let transform = world.get(Transform.self, for: ball) else {
            endShot(world, launcher: &launcher, caught: false, log: log)
            return
        }
        let p = Vec2(transform.position.x, transform.position.y)
        let reach = launcher.ballRadius + 0.06

        // Light the pegs the ball touches.
        var newlyLit: [(Entity, PegKind)] = []
        world.query(Transform.self, Peg.self, Collider2D.self) { entity, pegTransform, peg, collider in
            guard !peg.lit, !peg.cleared else { return }
            if touches(p, reach: reach, transform: pegTransform, collider: collider) { newlyLit.append((entity, peg.kind)) }
        }
        for (entity, kind) in newlyLit {
            let halo = spawnHalo(world, launcher: launcher, peg: entity, kind: kind)
            world.modify(Peg.self, for: entity) {
                $0.lit = true
                $0.halo = halo
            }
            world.modify(MeshRenderer.self, for: entity) { $0.tint = Self.litTint }
            let multiplier = scoreMultiplier(world, launcher: launcher)
            launcher.shotHits += 1
            launcher.shotScore += kind.points * multiplier
            if kind == .bonus {
                launcher.ballsLeft += 1
                log("Orbfall: green peg! Extra ball (\(launcher.ballsLeft) left).")
            }
            if kind == .target, remainingTargets(world) == 0 {
                log("Orbfall: last orange peg lit!")
            }
        }

        // A ball resting on pegs: clear the lit ones early so it falls on.
        let speed = (world.get(RigidBody2D.self, for: ball)?.linearVelocity).map { ($0 * $0).sum().squareRoot() } ?? 0
        launcher.slowTime = speed < 0.4 ? launcher.slowTime + world.time.delta : 0
        if launcher.slowTime > 1.2 {
            launcher.slowTime = 0
            startVanishing(world)
        }

        // Caught by the bucket?
        var caught = false
        world.query(Transform.self, Bucket.self) { _, bucketTransform, bucket in
            let dx = abs(p.x - bucketTransform.position.x)
            let dy = p.y - bucketTransform.position.y
            if dx < bucket.halfWidth, dy < 0.35, dy > -0.6 { caught = true }
        }
        if caught || p.y < launcher.killY {
            endShot(world, launcher: &launcher, caught: caught, log: log)
        }
    }

    private static func spawnHalo(_ world: World, launcher: Launcher, peg: Entity, kind: PegKind) -> Entity? {
        guard let t = world.get(Transform.self, for: peg) else { return nil }
        let size = max(t.scale.x, t.scale.y) * 2.6
        return world.spawn(Name("Halo"), Transform(position: Vec3(t.position.x, t.position.y, t.position.z - 0.02), scale: Vec3(size, size, 1)),
                           MeshRenderer(mesh: launcher.spriteMesh, material: launcher.glowMaterial, tint: kind.color * 2.2, castsShadows: false))
    }

    static func removeHalo(_ world: World, _ peg: inout Peg) {
        if let halo = peg.halo { world.despawn(halo) }
        peg.halo = nil
    }

    private static func endShot(_ world: World, launcher: inout Launcher, caught: Bool, log: (String) -> Void) {
        if let ball = launcher.ball { world.despawn(ball) }
        launcher.ball = nil
        if caught { launcher.ballsLeft += 1 }
        launcher.score += launcher.shotScore
        var line = "Orbfall: \(launcher.shotHits) pegs, +\(launcher.shotScore). Score \(launcher.score)."
        if caught { line += " Bucket: free ball!" }
        line += " Balls \(launcher.ballsLeft), orange left \(remainingTargets(world))."
        log(line)
        startVanishing(world)
        launcher.phase = .clearing
    }

    private static func finishTurn(_ world: World, launcher: inout Launcher, log: (String) -> Void) {
        if remainingTargets(world) == 0 {
            let bonus = launcher.ballsLeft * 1000
            launcher.score += bonus
            launcher.phase = .won
            log("Orbfall: YOU WIN! \(launcher.ballsLeft) balls left (+\(bonus)). Final score \(launcher.score). Press R to play again.")
        } else if launcher.ballsLeft <= 0 {
            launcher.phase = .lost
            log("Orbfall: out of balls with \(remainingTargets(world)) orange left. Score \(launcher.score). Press R to retry.")
        } else {
            launcher.phase = .aiming
        }
    }

    // MARK: Pegs

    /// Whether a ball at `p` is within `reach` of the peg's collider.
    static func touches(_ p: Vec2, reach: Float, transform: Transform, collider: Collider2D) -> Bool {
        let angle = 2 * atan2f(transform.rotation.z, transform.rotation.w)
        let (s, c) = (sinf(angle), cosf(angle))
        let center = Vec2(transform.position.x, transform.position.y)
            + Vec2(c * collider.offset.x - s * collider.offset.y, s * collider.offset.x + c * collider.offset.y)
        let d = p - center
        switch collider.shape {
        case .circle(let radius):
            return (d * d).sum() < (radius + reach) * (radius + reach)
        case .box(let half):
            let a = -(angle + collider.rotation)
            let local = Vec2(cosf(a) * d.x - sinf(a) * d.y, sinf(a) * d.x + cosf(a) * d.y)
            let q = Vec2(max(abs(local.x) - half.x, 0), max(abs(local.y) - half.y, 0))
            return (q * q).sum() < reach * reach
        case .capsule(let radius, let halfHeight):
            let a = -(angle + collider.rotation)
            let local = Vec2(cosf(a) * d.x - sinf(a) * d.y, sinf(a) * d.x + cosf(a) * d.y)
            let q = Vec2(local.x, local.y - min(max(local.y, -halfHeight), halfHeight))
            return (q * q).sum() < (radius + reach) * (radius + reach)
        default:
            return false
        }
    }

    static func startVanishing(_ world: World) {
        var lit: [Entity] = []
        world.query(Peg.self) { entity, peg in
            if peg.lit, !peg.cleared, peg.vanish == nil { lit.append(entity) }
        }
        for (i, entity) in lit.enumerated() {
            world.modify(Peg.self, for: entity) { $0.vanish = -Float(i) * 0.04 }
            // Stop colliding right away.
            world.modify(Collider2D.self, for: entity) {
                $0.layer = 0
                $0.mask = 0
            }
        }
    }

    static func anyVanishing(_ world: World) -> Bool {
        var any = false
        world.query(Peg.self) { _, peg in if peg.vanish != nil { any = true } }
        return any
    }

    static func remainingTargets(_ world: World) -> Int {
        var n = 0
        world.query(Peg.self) { _, peg in if peg.kind == .target, !peg.lit, !peg.cleared { n += 1 } }
        return n
    }

    static func scoreMultiplier(_ world: World, launcher: Launcher) -> Int {
        guard launcher.targetsTotal > 0 else { return 1 }
        let done = Float(launcher.targetsTotal - remainingTargets(world)) / Float(launcher.targetsTotal)
        return done >= 0.9 ? 10 : done >= 0.7 ? 5 : done >= 0.5 ? 3 : done >= 0.3 ? 2 : 1
    }

    /// Gives each new peg a collider matching what it looks like (a sphere: a circle, anything
    /// else: a box, both from the Transform's scale and z rotation) and remembers its size.
    static func preparePegs(_ world: World) {
        var fresh: [Entity] = []
        world.query(Peg.self) { entity, peg in if peg.baseScale == nil { fresh.append(entity) } }
        for entity in fresh {
            guard let transform = world.get(Transform.self, for: entity) else { continue }
            let round = world.get(Peg.self, for: entity)?.shape != .brick
            let shape: ColliderShape2D = round
                ? .circle(radius: max(transform.scale.x, transform.scale.y) / 2)
                : .box(halfExtents: Vec2(transform.scale.x / 2, transform.scale.y / 2))
            let old = world.get(Collider2D.self, for: entity)
            let collider = Collider2D(shape, friction: 0.2, restitution: 0.55, layer: old?.layer ?? 1, mask: old?.mask ?? .max)
            world.add(collider, to: entity)
            world.modify(Peg.self, for: entity) { peg in
                peg.baseScale = transform.scale
                peg.baseLayer = collider.layer
                peg.baseMask = collider.mask
            }
        }
    }

    /// Remembers each peg's look, pulses lit pegs and shrinks vanishing ones.
    static func animatePegs(_ world: World) {
        let t = Float(world.time.elapsed)
        let dt = world.time.delta
        var phase = OrbfallPhase.aiming
        world.query(Launcher.self) { _, launcher in phase = launcher.phase }

        preparePegs(world)
        world.queryMutating(Transform.self, Peg.self) { entity, transform, peg in
            let base = peg.baseScale ?? transform.scale
            if peg.cleared { return }
            if let v = peg.vanish {
                let next = v + dt
                if next >= 0.25 {
                    removeHalo(world, &peg)
                    peg.vanish = nil
                    peg.cleared = true
                    peg.lit = false
                    transform.scale = base
                } else {
                    peg.vanish = next
                    let k = 1 - max(next, 0) / 0.25
                    transform.scale = base * (1 + 0.4 * (1 - k)) * k
                    if let halo = peg.halo {
                        world.modify(MeshRenderer.self, for: halo) { $0.opacity = k }
                    }
                }
            } else if peg.lit {
                transform.scale = base * (1.1 + 0.05 * sinf(t * 14))
            } else {
                transform.scale = base
            }
        }

        // Tints and visibility (MeshRenderer is a separate store, so a second pass).
        world.queryMutating(Peg.self, MeshRenderer.self) { _, peg, renderer in
            renderer.isVisible = !peg.cleared
            if peg.lit || peg.vanish != nil { return }
            switch phase {
            case .won:
                renderer.tint = Vec3(1, 1, 1) + rainbow(t * 0.5 + Float(peg.kind.points) * 0.01) * 0.8
            case .lost:
                renderer.tint = Vec3(repeating: 0.35)
            default:
                renderer.tint = Vec3(1, 1, 1)
            }
        }
    }

    // MARK: HUD

    static func spawnHUD(_ world: World, launcher: Launcher) {
        let mesh = launcher.spriteMesh
        for i in 0..<aimDots {
            _ = world.spawn(Name("Aim Dot \(i)"), Transform(position: Vec3(0, 0, 0.03), scale: Vec3(repeating: 0.26)),
                            MeshRenderer(mesh: mesh, material: launcher.dotMaterial, opacity: 0.9, castsShadows: false), OrbfallHUD(.aimDot, i))
        }
        for i in 0..<maxIcons {
            _ = world.spawn(Name("Ball Icon \(i)"), Transform(position: Vec3(-8.4, 8.6 - Float(i) * 0.7, 0), scale: Vec3(repeating: 0.55)),
                            MeshRenderer(mesh: mesh, material: launcher.ballMaterial, castsShadows: false), OrbfallHUD(.ballIcon, i))
        }
        _ = world.spawn(Name("Meter Back"), Transform(position: Vec3(8.4, -0.5, 0), scale: Vec3(0.7, 18.4, 1)),
                        MeshRenderer(mesh: mesh, material: launcher.barMaterial, tint: Vec3(0.12, 0.07, 0.22), castsShadows: false),
                        OrbfallHUD(.meterFill, -1))
        _ = world.spawn(Name("Meter Fill"), Transform(position: Vec3(8.4, -9.5, 0.02), scale: Vec3(0.5, 0.01, 1)),
                        MeshRenderer(mesh: mesh, material: launcher.barMaterial, tint: Vec3(1.6, 0.6, 0.1), castsShadows: false),
                        OrbfallHUD(.meterFill, 0))
    }

    static func updateHUD(_ world: World, launcher: Launcher, tip: Vec2, z: Float) {
        // Aim preview: the arc the ball would follow, up to the first peg or wall it meets.
        let showAim = launcher.phase == .aiming
        let gravity = Vec2(0, -9.81)
        let v0 = launcher.aimDirection * launcher.launchSpeed
        var blockedFrom = aimDots
        var obstacles: [(Transform, Collider2D)] = []
        if showAim {
            world.query(Transform.self, Collider2D.self) { entity, transform, collider in
                if collider.mask != 0, !world.has(Orb.self, for: entity) { obstacles.append((transform, collider)) }
            }
        }
        var points: [Vec2] = []
        for i in 0..<aimDots {
            let time = Float(i + 1) * 0.05
            let p = tip + v0 * time + gravity * (0.5 * time * time)
            points.append(p)
            if showAim, blockedFrom == aimDots,
               obstacles.contains(where: { touches(p, reach: launcher.ballRadius, transform: $0.0, collider: $0.1) }) {
                blockedFrom = i
            }
        }
        let fraction = launcher.targetsTotal > 0
            ? Float(launcher.targetsTotal - remainingTargets(world)) / Float(launcher.targetsTotal) : 0
        world.queryMutating(Transform.self, OrbfallHUD.self, MeshRenderer.self) { _, transform, hud, renderer in
            switch hud.role {
            case .aimDot:
                let p = points[hud.index]
                transform.position = Vec3(p.x, p.y, 0.03)
                renderer.isVisible = showAim && hud.index < blockedFrom
                renderer.opacity = 1 - Float(hud.index) / Float(aimDots) * 0.6
            case .ballIcon:
                renderer.isVisible = hud.index < launcher.ballsLeft
            case .meterFill:
                guard hud.index == 0 else { return }
                let h = max(18 * fraction, 0.01)
                transform.scale.y = h
                transform.position.y = -9.5 + h / 2
            }
        }
    }

    static func mix(_ a: Vec3, _ b: Vec3, _ t: Float) -> Vec3 { a + (b - a) * t }

    static func rainbow(_ h: Float) -> Vec3 {
        let x = h - floorf(h)
        func channel(_ o: Float) -> Float { 0.5 + 0.5 * cosf(2 * .pi * (x + o)) }
        return Vec3(channel(0), channel(0.33), channel(0.67))
    }
}
