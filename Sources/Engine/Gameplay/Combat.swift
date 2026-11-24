#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// The play-mode combat system ("combat", `.lateUpdate`, after animation, IK and ragdoll poses):
//
// 1. Finds the active hitboxes: `Hitbox` components with `active` on, and each `Animator`'s
//    `hitboxes` tracks whose state is playing inside their start...end window (on the named
//    bone's current pose). Each activation is a swing: turning on, entering the window, or a
//    looping state's next cycle.
// 2. Tests them against every enabled `Hurtbox` of a living `Health` (not the attacker's own,
//    not its team) and applies one hit per victim per swing (`World.applyDamage`), choosing the
//    victim's touching hurtbox with the highest multiplier (head shots count).
// 3. Turns new hit events (also those from `World.applyDamage` in game code and scripts) into
//    effects: the damage type's VFX and sound (else the victim's physics material impact effect),
//    hit flash, hit stop and camera shake (GameFeel.swift), and ragdolls: a partial hit reaction
//    on the bone that was hit, full ragdoll on death (else the Animator's `hit` / `die` triggers);
//    dynamic bodies get the knockback impulse. Dead entities with `removeAfter` are removed later.

/// A hitbox in world space, as the combat system and the debug overlay see it.
public struct HitboxInfo: Equatable, Sendable {
    /// The `Hitbox` component's name, or the track's.
    public var name: String
    /// The entity that deals the damage (nearest with a `Health` or `Animator`, else the root).
    public var attacker: Entity
    /// The entity with the `Hitbox`, or the `Animator` with the track.
    public var source: Entity
    /// The track's index in `Animator.hitboxes` (-1 for a `Hitbox` component).
    public var track: Int
    /// The entity the shape is attached to and its name.
    public var bone: Entity
    public var boneName: String
    public var volume: HitVolume
    public var damage: HitDamage
    public var team: String
    public var rehitInterval: Float
    public var active: Bool
    /// A looping state's cycle (a new cycle is a new swing).
    var cycle: Int
}

/// A hurtbox in world space.
public struct HurtboxInfo: Equatable, Sendable {
    public var entity: Entity
    /// The entity whose `Health` it damages.
    public var victim: Entity
    public var boneName: String
    public var region: String
    public var multiplier: Float
    public var volume: HitVolume
}

/// The state of the "combat" system (see Combat.swift). `World.gameplay?.combat` while playing.
@MainActor
public final class CombatSystem {
    public static let systemName = "combat"

    public var enabled = true
    /// Effects of hits (VFX, sound, flash, hit stop, shake, ragdolls); off: damage only.
    public var effects = true
    /// Seconds a spawned VFX lives (sounds go when they end).
    public var effectLifetime: Float = 2
    /// The hitboxes active in the last update.
    public private(set) var active: [HitboxInfo] = []
    /// Hits that got effects in the last update.
    public private(set) var recent: [HitEvent] = []

    let feel: GameFeel
    let assets: () -> AssetDatabase?
    let physics: () -> PhysicsWorld?

    private struct SwingKey: Hashable {
        var source: Entity
        var track: Int
    }
    private struct Swing {
        var id: Int
        var cycle: Int
        /// Victims hit this swing → seconds since.
        var hit: [Entity: Float] = [:]
    }
    private var swings: [SwingKey: Swing] = [:]
    private var nextSwing = 1
    private var processed: Int
    private var removals: [(entity: Entity, remaining: Float)] = []
    private var spawned: [(entity: Entity, remaining: Float, sound: Bool)] = []

    init(feel: GameFeel, assets: @escaping () -> AssetDatabase?, physics: @escaping () -> PhysicsWorld?, startingAfter sequence: Int) {
        self.feel = feel
        self.assets = assets
        self.physics = physics
        processed = sequence
    }

    // MARK: Finding hitboxes and hurtboxes

    /// The entity named `name` at or below `root` (breadth first).
    public static func descendant(named name: String, of root: Entity, in world: World) -> Entity? {
        var queue = [root]
        var i = 0
        while i < queue.count {
            let e = queue[i]
            i += 1
            if world.get(Name.self, for: e)?.value == name { return e }
            queue += world.children(of: e)
        }
        return nil
    }

    /// Who deals a hitbox's damage: the nearest entity at or above `entity` with a `Health` or an
    /// `Animator`, else its root.
    static func attacker(of entity: Entity, in world: World) -> Entity {
        var current: Entity? = entity
        var last = entity
        while let e = current {
            if world.has(Health.self, for: e) || world.has(Animator.self, for: e) { return e }
            last = e
            current = world.parent(of: e)
        }
        return last
    }

    /// Every hitbox in `world`: `Hitbox` components and animator tracks, with whether each is
    /// active now (tracks: their state plays inside their window). Inactive ones only with
    /// `includeInactive` (the debug overlay draws them dimmed).
    public static func hitboxes(in world: World, includeInactive: Bool = false) -> [HitboxInfo] {
        var result: [HitboxInfo] = []
        var components: [(Entity, Hitbox)] = []
        world.query(Hitbox.self) { e, h in components.append((e, h)) }
        for (e, hitbox) in components where hitbox.active || includeInactive {
            let attacker = attacker(of: e, in: world)
            let team = hitbox.team.isEmpty ? (world.damageable(attacker).flatMap { world.get(Health.self, for: $0)?.team } ?? "") : hitbox.team
            result.append(HitboxInfo(name: world.get(Name.self, for: e)?.value ?? "Hitbox", attacker: attacker, source: e, track: -1, bone: e,
                                     boneName: world.get(Name.self, for: e)?.value ?? "", volume: hitbox.shape.volume(world.worldMatrix(of: e)),
                                     damage: hitbox.damage, team: team, rehitInterval: hitbox.rehitInterval, active: hitbox.active, cycle: 0))
        }
        var animators: [(Entity, Animator)] = []
        world.query(Animator.self) { e, a in if a.hitboxes?.isEmpty == false { animators.append((e, a)) } }
        for (e, animator) in animators {
            let state = animator.currentState
            let index = state.flatMap { animator.stateMachine.index(of: $0) }
            let loops = index.map { animator.stateMachine.states[$0].loops } ?? true
            let time = animator.normalizedTime
            let fraction = loops ? time - time.rounded(.down) : min(max(time, 0), 1)
            let clips = index.map { animator.stateMachine.states[$0].motion.clips.map(\.key) } ?? []
            let team = world.damageable(e).flatMap { world.get(Health.self, for: $0)?.team } ?? ""
            for (i, track) in (animator.hitboxes ?? []).enumerated() {
                let inState: Bool
                if let wanted = track.state, !wanted.isEmpty {
                    inState = state == wanted
                } else if let clip = track.clip, !clip.isEmpty {
                    inState = clips.contains(clip)
                } else {
                    inState = false
                }
                let on = animator.isPlaying && inState && track.isActive(at: fraction)
                guard on || includeInactive, let bone = descendant(named: track.bone, of: e, in: world) else { continue }
                result.append(HitboxInfo(name: track.name, attacker: e, source: e, track: i, bone: bone, boneName: track.bone,
                                         volume: track.shape.volume(world.worldMatrix(of: bone)), damage: track.damage, team: team,
                                         rehitInterval: 0, active: on, cycle: loops ? Int(time.rounded(.down)) : 0))
            }
        }
        return result
    }

    /// Every enabled hurtbox of a living `Health` in `world`, in world space.
    public static func hurtboxes(in world: World, includeDead: Bool = false) -> [HurtboxInfo] {
        var result: [HurtboxInfo] = []
        var found: [(Entity, Hurtbox)] = []
        world.query(Hurtbox.self) { e, h in if h.enabled { found.append((e, h)) } }
        for (e, hurtbox) in found {
            guard let victim = world.damageable(e), let health = world.get(Health.self, for: victim), includeDead || !health.dead else { continue }
            result.append(HurtboxInfo(entity: e, victim: victim, boneName: world.get(Name.self, for: e)?.value ?? "", region: hurtbox.region,
                                      multiplier: hurtbox.multiplier, volume: hurtbox.shape.volume(world.worldMatrix(of: e))))
        }
        return result
    }

    // MARK: Update

    func update(_ world: World) {
        let dt = world.time.delta
        recent.removeAll(keepingCapacity: true)
        world.tickInvulnerability(dt)
        expire(world, world.time.unscaledDelta)
        guard enabled else {
            active = []
            processed = world.combat.lastSequence
            return
        }
        detectHits(world, dt: dt)
        let events = Array(world.combat.events(after: processed))
        processed = world.combat.lastSequence
        for event in events {
            recent.append(event)
            if effects { applyEffects(of: event, in: world) }
            if event.killed, let health = world.get(Health.self, for: event.victim), health.removeAfter > 0 {
                removals.append((event.victim, health.removeAfter))
            }
        }
    }

    private func detectHits(_ world: World, dt: Float) {
        active = Self.hitboxes(in: world)
        // Swings: a source's track that wasn't active last update (or started a new cycle) starts over.
        var live: [SwingKey: Swing] = [:]
        for info in active {
            let key = SwingKey(source: info.source, track: info.track)
            if var swing = swings[key], swing.cycle == info.cycle {
                for victim in swing.hit.keys { swing.hit[victim]! += dt }
                live[key] = swing
            } else {
                live[key] = Swing(id: nextSwing, cycle: info.cycle)
                nextSwing += 1
            }
        }
        swings = live
        guard !active.isEmpty else { return }
        let hurtboxes = Self.hurtboxes(in: world)
        guard !hurtboxes.isEmpty else { return }
        for info in active {
            let key = SwingKey(source: info.source, track: info.track)
            let attackerVictim = world.damageable(info.attacker)
            // The best touching hurtbox per victim: highest multiplier, then deepest.
            var best: [Entity: (HurtboxInfo, Vec3, Vec3, Float)] = [:]
            var order: [Entity] = []
            for hurtbox in hurtboxes {
                if hurtbox.victim == attackerVictim || hurtbox.victim == info.attacker { continue }
                if !info.team.isEmpty, world.get(Health.self, for: hurtbox.victim)?.team == info.team { continue }
                if let since = swings[key]?.hit[hurtbox.victim], info.rehitInterval <= 0 || since < info.rehitInterval { continue }
                guard let contact = info.volume.contact(with: hurtbox.volume) else { continue }
                if let current = best[hurtbox.victim] {
                    if hurtbox.multiplier < current.0.multiplier || (hurtbox.multiplier == current.0.multiplier && contact.depth <= current.3) { continue }
                } else {
                    order.append(hurtbox.victim)
                }
                best[hurtbox.victim] = (hurtbox, contact.point, contact.normal, contact.depth)
            }
            for victim in order {
                guard let (hurtbox, point, normal, _) = best[victim] else { continue }
                let event = world.applyDamage(info.damage.amount, to: victim, type: info.damage.type, from: info.attacker, point: point,
                                              normal: normal, bone: hurtbox.boneName, region: hurtbox.region, multiplier: hurtbox.multiplier,
                                              hitbox: info.name, knockback: info.damage.knockback, team: info.team)
                if event != nil || world.get(Health.self, for: victim)?.invulnerableRemaining ?? 0 > 0 {
                    swings[key]?.hit[victim] = 0
                }
            }
        }
    }

    // MARK: Effects

    private func applyEffects(of event: HitEvent, in world: World) {
        guard world.isAlive(event.victim) else { return }
        let type = world.combat.damageType(event.type)
        guard event.damage > 0 else { return }
        let kill: Float = event.killed ? 2 : 1
        if let stop = type.hitStop, stop > 0 { world.hitStop(Double(stop * kill), scale: 0.02) }
        if let amount = type.shake, amount > 0 { feel.shake(amount * (event.killed ? 1.5 : 1)) }
        if let color = type.flash { feel.flash(event.victim, color: color, duration: 0.12, in: world) }
        spawnEffects(event, type, in: world)

        let push = -event.normal * event.knockback * (type.knockback ?? 1)
        let health = world.get(Health.self, for: event.victim)
        if let ragdollEntity = VisualScriptEngineSupport.find(Ragdoll.self, from: event.victim, in: world),
           let ragdoll = world.get(Ragdoll.self, for: ragdollEntity) {
            let names = Set(ragdoll.bones.map(\.bone))
            let bone = names.contains(event.bone) ? event.bone : (ragdoll.bones.first { $0.bone == "spine" } ?? ragdoll.bones.first)?.bone ?? event.bone
            if event.killed, health?.ragdollOnDeath ?? true {
                world.modify(Ragdoll.self, for: ragdollEntity) {
                    $0.goLimp()
                    $0.applyImpulse(bone: bone, impulse: push * 1.5 + Vec3(0, event.knockback * 0.3, 0), at: event.point)
                }
            } else if !event.killed, health?.hitReactions ?? true, ragdoll.mode != .full {
                world.modify(Ragdoll.self, for: ragdollEntity) {
                    $0.hit(bone: bone, impulse: push, at: event.point, weight: type.reaction ?? 0.6, duration: 0.5)
                }
            }
        } else if let animatorEntity = VisualScriptEngineSupport.find(Animator.self, from: event.victim, in: world) {
            let trigger = event.killed ? "die" : "hit"
            if event.killed || health?.hitReactions ?? true {
                world.modify(Animator.self, for: animatorEntity) { animator in
                    if case .trigger? = animator.parameters[trigger] { animator.setTrigger(trigger) }
                }
            }
        }
        if let physics = physics(), length(push) > 0, let body = physics.body(for: event.victim),
           world.get(RigidBody.self, for: event.victim)?.motion == .dynamic {
            physics.applyImpulse(body, push, at: event.point)
        }
    }

    private func spawnEffects(_ event: HitEvent, _ type: DamageType, in world: World) {
        var sound = type.sound, vfx = type.vfx, volume: Float = 1, pitch: Float = 1
        if sound == nil && vfx == nil, let physics = physics() {
            // The victim's physics material: its impact effect against the default material.
            let material = physics.surface(for: event.victim, in: world).map { $0.material.isEmpty ? "default" : $0.material } ?? "default"
            if let effect = physics.materials.effect(.impact, "default", material) {
                sound = effect.sound
                vfx = effect.vfx
                volume = effect.volume ?? 1
                pitch = effect.pitch ?? 1
            }
        }
        let database = assets()
        if let sound, !sound.isEmpty, let id = database?.assetID(forScriptValue: sound) {
            AudioSystem.registerComponents()
            let emitter = AudioEmitter(clip: AssetReference(id).description, volume: volume, pitch: pitch, loop: false, isPlaying: true)
            spawned.append((world.spawn(Transform(position: event.point), Name("Hit Sound"), emitter), effectLifetime * 4, true))
        }
        if let vfx, !vfx.isEmpty, let database, let id = database.assetID(forScriptValue: vfx) {
            let reference = database.asset(id)?.main.map { AssetReference(id, subAsset: $0) }
                ?? database.references(of: .prefab).first { $0.asset == id }
            if let reference, let prefab = database.prefab(reference) {
                let root = world.spawn(Transform(position: event.point, rotation: .lookRotation(forward: event.normal)), Name("Hit Effect"))
                world.instantiate(prefab, under: root)
                spawned.append((root, effectLifetime, false))
            }
        }
    }

    private func expire(_ world: World, _ dt: Float) {
        if !spawned.isEmpty {
            var kept: [(entity: Entity, remaining: Float, sound: Bool)] = []
            for var item in spawned where world.isAlive(item.entity) {
                item.remaining -= dt
                let ended = item.sound && world.get(AudioEmitter.self, for: item.entity).map { !$0.isPlaying } == true
                if item.remaining <= 0 || ended { world.despawn(item.entity) } else { kept.append(item) }
            }
            spawned = kept
        }
        if !removals.isEmpty {
            var kept: [(entity: Entity, remaining: Float)] = []
            for var item in removals where world.isAlive(item.entity) {
                item.remaining -= dt
                if item.remaining <= 0 { world.despawn(item.entity) } else { kept.append(item) }
            }
            removals = kept
        }
    }

    // MARK: Debug drawing

    /// Draws hurtboxes (blue), inactive hitboxes (dim yellow) and active ones (red) into `draw`,
    /// on top of the scene: the Scene view's combat overlay (`combat.overlay`).
    public static func drawDebug(_ world: World, into draw: DebugDraw) {
        let style = DebugDraw.Style(width: 1.5, depth: .onTop)
        for hurtbox in hurtboxes(in: world, includeDead: true) {
            let dead = world.get(Health.self, for: hurtbox.victim)?.dead ?? false
            drawVolume(hurtbox.volume, color: dead ? Vec4(0.45, 0.45, 0.5, 0.6) : Vec4(0.3, 0.65, 1, 0.9), style: style, into: draw)
        }
        for hitbox in hitboxes(in: world, includeInactive: true) {
            drawVolume(hitbox.volume, color: hitbox.active ? Vec4(1, 0.2, 0.15, 1) : Vec4(1, 0.85, 0.3, 0.45),
                 style: DebugDraw.Style(width: hitbox.active ? 3 : 1.5, depth: .onTop), into: draw)
        }
        for event in world.combat.events.suffix(8) {
            draw.arrow(from: event.point, to: event.point + event.normal * 0.35, color: Vec4(1, 0.4, 0.3, 1), headSize: 0.08, style: style)
        }
    }

    /// One volume as lines: a capsule as two spheres and four side lines, a box as its edges.
    public static func drawVolume(_ volume: HitVolume, color: Vec4, style: DebugDraw.Style, into draw: DebugDraw) {
        switch volume.kind {
        case .box:
            let rotation = Quat(rotationMatrix: Mat4(Vec4(volume.axes[0], 0), Vec4(volume.axes[1], 0), Vec4(volume.axes[2], 0), Vec4(0, 0, 0, 1)))
            draw.box(center: volume.a, halfExtent: volume.halfExtents, rotation: rotation, color: color, style: style)
        case .capsule:
            draw.sphere(center: volume.a, radius: volume.radius, color: color, segments: 16, style: style)
            let axis = volume.b - volume.a
            guard length(axis) > 1e-4 else { return }
            draw.sphere(center: volume.b, radius: volume.radius, color: color, segments: 16, style: style)
            let n = normalize(axis)
            let side = normalize(abs(n.y) < 0.9 ? cross(n, Vec3(0, 1, 0)) : cross(n, Vec3(1, 0, 0)))
            let up = cross(side, n)
            for offset in [side, -side, up, -up] {
                draw.line(volume.a + offset * volume.radius, volume.b + offset * volume.radius, color: color, style: style)
            }
        }
    }
}
