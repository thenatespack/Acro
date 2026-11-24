// Damage: health, damage types and resistances, hitboxes and hurtboxes, and hit events.
//
// - `Health` on an entity makes it damageable: `max` / `current`, per-type `resistances`
//   (multipliers; missing types take full damage), a `team` (no friendly fire), invulnerability
//   after a hit, and what happens on death (ragdoll, removal).
// - `Hurtbox` shapes (on bones or any entity under a `Health`) are where it can be hit; a
//   region multiplier makes head shots hurt more.
// - `Hitbox` shapes deal damage while `active` (a sword, a spike trap); `HitboxTrack`s on an
//   `Animator` (`Animator.hitboxes`, from `.animgraph` files or `.character` combat settings)
//   switch hitboxes on bones on during part of a state's clip (a swing).
// - `World.applyDamage` applies a hit and logs a `HitEvent` (attacker, victim, damage, type,
//   point, normal, bone…) in `World.combat`. The play-mode combat system (Engine,
//   Gameplay/Combat.swift) finds hitbox / hurtbox overlaps (one hit per victim per swing) and
//   turns events into effects: VFX, sound, hit flash, hit stop, camera shake, ragdoll hit
//   reactions and death.
//
// Every key of these components is optional in scene files.
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore

/// What a type of damage does beyond the number: knockback, game feel and effects. Every key
/// optional; unset values use the built-in type of the same name, else the defaults.
public struct DamageType: Codable, Equatable, Sendable {
    public var name: String
    /// Multiplies hitboxes' knockback impulse.
    public var knockback: Float?
    /// Seconds game time freezes on a hit (hit stop); a kill doubles it.
    public var hitStop: Float?
    /// Camera shake per hit (trauma 0...1).
    public var shake: Float?
    /// The color the victim flashes (linear RGB multiplier of its tint); nil: none.
    public var flash: Vec3?
    /// A `.vfx` (or prefab) spawned at the hit point; a sound (`.sfx` or audio file) played there.
    public var vfx: String?
    public var sound: String?
    /// How much of a partial ragdoll's pose shows in a hit reaction (0...1).
    public var reaction: Float?

    public init(name: String, knockback: Float? = nil, hitStop: Float? = nil, shake: Float? = nil, flash: Vec3? = nil,
                vfx: String? = nil, sound: String? = nil, reaction: Float? = nil) {
        self.name = name
        self.knockback = knockback
        self.hitStop = hitStop
        self.shake = shake
        self.flash = flash
        self.vfx = vfx
        self.sound = sound
        self.reaction = reaction
    }

    private enum CodingKeys: String, CodingKey { case name, knockback, hitStop, shake, flash, vfx, sound, reaction }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        knockback = try c.decodeIfPresent(Float.self, forKey: .knockback)
        hitStop = try c.decodeIfPresent(Float.self, forKey: .hitStop)
        shake = try c.decodeIfPresent(Float.self, forKey: .shake)
        flash = try c.decodeIfPresent(Vec3.self, forKey: .flash)
        vfx = try c.decodeIfPresent(String.self, forKey: .vfx)
        sound = try c.decodeIfPresent(String.self, forKey: .sound)
        reaction = try c.decodeIfPresent(Float.self, forKey: .reaction)
    }

    /// This type with the unset values taken from `base`.
    public func merged(over base: DamageType) -> DamageType {
        DamageType(name: name, knockback: knockback ?? base.knockback, hitStop: hitStop ?? base.hitStop, shake: shake ?? base.shake,
                   flash: flash ?? base.flash, vfx: vfx ?? base.vfx, sound: sound ?? base.sound, reaction: reaction ?? base.reaction)
    }

    /// The built-in types: physical, slash, blunt, pierce, fire, ice, electric, poison.
    public static let builtIns: [String: DamageType] = {
        let white = Vec3(3, 3, 3)
        let list = [
            DamageType(name: "physical", knockback: 1, hitStop: 0.05, shake: 0.25, flash: white, reaction: 0.6),
            DamageType(name: "slash", knockback: 0.8, hitStop: 0.06, shake: 0.3, flash: white, reaction: 0.6),
            DamageType(name: "blunt", knockback: 1.6, hitStop: 0.08, shake: 0.45, flash: white, reaction: 0.8),
            DamageType(name: "pierce", knockback: 0.5, hitStop: 0.04, shake: 0.2, flash: white, reaction: 0.4),
            DamageType(name: "fire", knockback: 0.3, hitStop: 0.02, shake: 0.15, flash: Vec3(4, 1.6, 0.4), reaction: 0.3),
            DamageType(name: "ice", knockback: 0.3, hitStop: 0.1, shake: 0.15, flash: Vec3(0.8, 2, 4), reaction: 0.3),
            DamageType(name: "electric", knockback: 0.4, hitStop: 0.12, shake: 0.35, flash: Vec3(2.5, 2.5, 4), reaction: 0.7),
            DamageType(name: "poison", knockback: 0, hitStop: 0, shake: 0, flash: Vec3(0.8, 3, 0.6), reaction: 0),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.name, $0) })
    }()
}

/// Makes an entity damageable (see the notes at the top of Damage.swift).
public struct Health: Component, Equatable, Sendable {
    public static let componentName = "Health"
    public static var fieldHints: [String: FieldHints] {
        ["max": FieldHints(range: 0...100_000, step: 1, tooltip: "Full health"),
         "current": FieldHints(range: 0...100_000, step: 1, tooltip: "Health now (0: dead)"),
         "resistances": FieldHints(tooltip: "Damage multiplier per damage type (fire: 0.5 takes half, 0 is immune, 2 double); missing types take full damage"),
         "team": FieldHints(tooltip: "Hitboxes don't hurt their own team (empty: everyone can hurt it)"),
         "invulnerableTime": FieldHints(range: 0...10, step: 0.05, tooltip: "Seconds after a hit when it takes no damage"),
         "invulnerableRemaining": FieldHints(hidden: true),
         "ragdollOnDeath": FieldHints(tooltip: "A Ragdoll goes limp on death (else the Animator's die trigger fires, if it has one)"),
         "hitReactions": FieldHints(tooltip: "Hits make a Ragdoll flinch (partial ragdoll), else fire the Animator's hit trigger"),
         "removeAfter": FieldHints(range: 0...600, step: 0.5, tooltip: "Seconds after death until the entity is removed (0: it stays)"),
         "dead": FieldHints(readOnly: true, tooltip: "Health reached 0")]
    }

    public var max: Float
    public var current: Float
    public var resistances: [String: Float]
    public var team: String
    public var invulnerableTime: Float
    public var invulnerableRemaining: Float
    public var ragdollOnDeath: Bool
    public var hitReactions: Bool
    public var removeAfter: Float
    public var dead: Bool

    public init(max: Float = 100, current: Float? = nil, resistances: [String: Float] = [:], team: String = "", invulnerableTime: Float = 0,
                ragdollOnDeath: Bool = true, hitReactions: Bool = true, removeAfter: Float = 0) {
        self.max = max
        self.current = current ?? max
        self.resistances = resistances
        self.team = team
        self.invulnerableTime = invulnerableTime
        invulnerableRemaining = 0
        self.ragdollOnDeath = ragdollOnDeath
        self.hitReactions = hitReactions
        self.removeAfter = removeAfter
        dead = (current ?? max) <= 0
    }

    private enum CodingKeys: String, CodingKey {
        case max, current, resistances, team, invulnerableTime, invulnerableRemaining, ragdollOnDeath, hitReactions, removeAfter, dead
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let maximum = try c.decodeIfPresent(Float.self, forKey: .max) ?? 100
        self.init(max: maximum, current: try c.decodeIfPresent(Float.self, forKey: .current),
                  resistances: try c.decodeIfPresent([String: Float].self, forKey: .resistances) ?? [:],
                  team: try c.decodeIfPresent(String.self, forKey: .team) ?? "",
                  invulnerableTime: try c.decodeIfPresent(Float.self, forKey: .invulnerableTime) ?? 0,
                  ragdollOnDeath: try c.decodeIfPresent(Bool.self, forKey: .ragdollOnDeath) ?? true,
                  hitReactions: try c.decodeIfPresent(Bool.self, forKey: .hitReactions) ?? true,
                  removeAfter: try c.decodeIfPresent(Float.self, forKey: .removeAfter) ?? 0)
        invulnerableRemaining = try c.decodeIfPresent(Float.self, forKey: .invulnerableRemaining) ?? 0
        dead = try c.decodeIfPresent(Bool.self, forKey: .dead) ?? (current <= 0)
    }

    /// The multiplier for `type` (1 when it has no resistance to it).
    public func resistance(to type: String) -> Float { resistances[type] ?? 1 }
    /// `current / max`, 0...1.
    public var fraction: Float { max > 0 ? Swift.min(Swift.max(current / max, 0), 1) : 0 }
}

/// Where an entity can be hit: a shape on a bone (or any entity at or under a `Health`).
public struct Hurtbox: Component, Equatable, Sendable {
    public static let componentName = "Hurtbox"
    public static var fieldHints: [String: FieldHints] {
        ["shape": FieldHints(tooltip: "In this entity's space: a sphere at from, a capsule from from to to, a box centered on from with half extents size"),
         "region": FieldHints(tooltip: "Body region reported with hits: head, torso, arm, leg…"),
         "multiplier": FieldHints(range: 0...10, step: 0.05, tooltip: "Damage multiplier (head 2, limbs 0.75)")]
    }

    public var shape: HitShape
    public var region: String
    public var multiplier: Float
    public var enabled: Bool

    public init(shape: HitShape = HitShape(kind: .capsule, radius: 0.3, from: Vec3(0, 0.3, 0), to: Vec3(0, 1.5, 0)), region: String = "",
                multiplier: Float = 1, enabled: Bool = true) {
        self.shape = shape
        self.region = region
        self.multiplier = multiplier
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey { case shape, region, multiplier, enabled }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Hurtbox()
        self.init(shape: try c.decodeIfPresent(HitShape.self, forKey: .shape) ?? d.shape,
                  region: try c.decodeIfPresent(String.self, forKey: .region) ?? "",
                  multiplier: try c.decodeIfPresent(Float.self, forKey: .multiplier) ?? 1,
                  enabled: try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true)
    }
}

/// What a hitbox deals: shared by `Hitbox` components and animation `HitboxTrack`s.
public struct HitDamage: Codable, Equatable, Sendable {
    public var amount: Float
    /// A `DamageType` name (built in: physical, slash, blunt, pierce, fire, ice, electric, poison).
    public var type: String
    /// Impulse pushing the victim (N·s; times the type's knockback).
    public var knockback: Float

    public init(amount: Float = 10, type: String = "physical", knockback: Float = 3) {
        self.amount = amount
        self.type = type
        self.knockback = knockback
    }

    private enum CodingKeys: String, CodingKey { case amount, type, knockback }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = try c.decodeIfPresent(Float.self, forKey: .amount) ?? 10
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "physical"
        knockback = try c.decodeIfPresent(Float.self, forKey: .knockback) ?? 3
    }
}

/// A shape that deals damage while `active`: a weapon, a trap, a projectile. The attacker is the
/// nearest entity at or above it with a `Health` or an `Animator` (else its root). It hits each
/// victim once per activation (turn `active` off and on for the next swing), or again every
/// `rehitInterval` seconds while it stays inside.
public struct Hitbox: Component, Equatable, Sendable {
    public static let componentName = "Hitbox"
    public static var fieldHints: [String: FieldHints] {
        ["shape": FieldHints(tooltip: "In this entity's space: a sphere at from, a capsule from from to to, a box centered on from with half extents size"),
         "active": FieldHints(tooltip: "Deals damage while on; each activation is one swing (a victim is hit once per swing)"),
         "rehitInterval": FieldHints(range: 0...10, step: 0.05, tooltip: "Seconds before it can hit the same victim again while active (0: once per activation)"),
         "team": FieldHints(tooltip: "Doesn't hurt this team (empty: the attacker's Health team)")]
    }

    public var shape: HitShape
    public var active: Bool
    public var damage: HitDamage
    public var rehitInterval: Float
    public var team: String

    public init(shape: HitShape = HitShape(kind: .sphere, radius: 0.3), active: Bool = true, damage: HitDamage = HitDamage(),
                rehitInterval: Float = 0, team: String = "") {
        self.shape = shape
        self.active = active
        self.damage = damage
        self.rehitInterval = rehitInterval
        self.team = team
    }

    private enum CodingKeys: String, CodingKey { case shape, active, damage, rehitInterval, team }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Hitbox()
        self.init(shape: try c.decodeIfPresent(HitShape.self, forKey: .shape) ?? d.shape,
                  active: try c.decodeIfPresent(Bool.self, forKey: .active) ?? true,
                  damage: try c.decodeIfPresent(HitDamage.self, forKey: .damage) ?? d.damage,
                  rehitInterval: try c.decodeIfPresent(Float.self, forKey: .rehitInterval) ?? 0,
                  team: try c.decodeIfPresent(String.self, forKey: .team) ?? "")
    }
}

/// A hitbox on a bone that is active during part of an animation state (a swing): in an
/// `.animgraph` file's `hitboxes`, a `.character`'s combat settings, or `Animator.hitboxes`.
///
/// ```json
/// {"name": "Slash", "state": "attack", "bone": "hand.R", "start": 0.3, "end": 0.55,
///  "shape": {"kind": "capsule", "radius": 0.1, "from": [0, 0, 0], "to": [0, -0.6, 0]},
///  "damage": {"amount": 25, "type": "slash", "knockback": 4}}
/// ```
public struct HitboxTrack: Codable, Equatable, Sendable {
    public var name: String
    /// The state it belongs to (a sub-state machine's states by path, "Combat/Slash"); nil or
    /// empty: any state playing `clip`.
    public var state: String?
    /// The clip key it belongs to when no state is given.
    public var clip: String?
    /// The bone (an entity `Name` under the animator) the shape is attached to.
    public var bone: String
    public var shape: HitShape
    /// When it is active, as fractions (0...1) of the state's cycle.
    public var start: Float
    public var end: Float
    public var damage: HitDamage

    public init(name: String = "Hit", state: String? = nil, clip: String? = nil, bone: String = "", shape: HitShape = HitShape(kind: .sphere, radius: 0.15),
                start: Float = 0.3, end: Float = 0.6, damage: HitDamage = HitDamage()) {
        self.name = name
        self.state = state
        self.clip = clip
        self.bone = bone
        self.shape = shape
        self.start = start
        self.end = end
        self.damage = damage
    }

    private enum CodingKeys: String, CodingKey { case name, state, clip, bone, shape, start, end, damage }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = HitboxTrack()
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? d.name,
                  state: try c.decodeIfPresent(String.self, forKey: .state),
                  clip: try c.decodeIfPresent(String.self, forKey: .clip),
                  bone: try c.decodeIfPresent(String.self, forKey: .bone) ?? "",
                  shape: try c.decodeIfPresent(HitShape.self, forKey: .shape) ?? d.shape,
                  start: try c.decodeIfPresent(Float.self, forKey: .start) ?? d.start,
                  end: try c.decodeIfPresent(Float.self, forKey: .end) ?? d.end,
                  damage: try c.decodeIfPresent(HitDamage.self, forKey: .damage) ?? d.damage)
    }

    /// Whether it is active at `fraction` (0...1) of its state's cycle.
    public func isActive(at fraction: Float) -> Bool { fraction >= start && fraction <= end }

    /// Problems with the track (empty bone or name, a window outside 0...1, no damage).
    public var problems: [String] {
        var found: [String] = []
        let label = "hitbox '\(name)'"
        if name.trimmingCharacters(in: .whitespaces).isEmpty { found.append("a hitbox has no name") }
        if bone.isEmpty { found.append("\(label) has no bone") }
        if (state ?? "").isEmpty && (clip ?? "").isEmpty { found.append("\(label) names neither a state nor a clip") }
        if !(start >= 0 && end <= 1 && start <= end) { found.append("\(label): start and end must be fractions 0...1 with start ≤ end") }
        if !(shape.radius >= 0) || (shape.kind != .box && shape.radius == 0) { found.append("\(label): radius must be above 0") }
        return found
    }
}

/// One hit: what `World.applyDamage` did (see the notes at the top of Damage.swift).
public struct HitEvent: Codable, Equatable, Sendable {
    /// Increases by one per event in a world (`World.combat.events(after:)`).
    public var sequence: Int
    public var attacker: Entity?
    public var victim: Entity
    /// Damage dealt after multipliers and resistances (negative heals).
    public var damage: Float
    /// What the hit asked for before multipliers and resistances.
    public var rawDamage: Float
    public var type: String
    /// World-space point of the hit and the surface normal there (out of the victim, toward the attacker).
    public var point: Vec3
    public var normal: Vec3
    /// The hurtbox's bone (entity name) and region, if a hurtbox was hit.
    public var bone: String
    public var region: String
    /// The hitbox or hitbox track that hit ("" for direct damage).
    public var hitbox: String
    /// Impulse pushing the victim, N·s (along -normal).
    public var knockback: Float
    /// Health after the hit, and whether this hit killed it.
    public var health: Float
    public var killed: Bool
}

/// The combat state of a world: the hit log and the damage types. `World.combat`.
@MainActor
public final class CombatState {
    /// Damage types by name, on top of the built-ins (`DamageType.builtIns`).
    public var damageTypes: [String: DamageType] = [:]
    /// The most recent hits, oldest first (up to `capacity`).
    public private(set) var events: [HitEvent] = []
    public var capacity = 256
    /// The sequence number the next hit gets.
    public private(set) var nextSequence = 1

    /// The damage type `name`: the world's, over the built-in of that name, over "physical".
    public func damageType(_ name: String) -> DamageType {
        let builtIn = DamageType.builtIns[name] ?? DamageType.builtIns["physical"]!.renamed(name)
        if let custom = damageTypes[name] { return custom.merged(over: builtIn) }
        return builtIn
    }

    /// Hits logged after the one numbered `sequence`.
    public func events(after sequence: Int) -> ArraySlice<HitEvent> {
        guard let first = events.firstIndex(where: { $0.sequence > sequence }) else { return [] }
        return events[first...]
    }

    /// The sequence number of the latest hit (0: none yet).
    public var lastSequence: Int { nextSequence - 1 }

    func record(_ event: HitEvent) -> HitEvent {
        var event = event
        event.sequence = nextSequence
        nextSequence += 1
        events.append(event)
        if events.count > capacity { events.removeFirst(events.count - capacity) }
        return event
    }

    /// Forgets the log (sequence numbers keep counting).
    public func clear() { events.removeAll() }
}

extension DamageType {
    fileprivate func renamed(_ name: String) -> DamageType {
        var copy = self
        copy.name = name
        return copy
    }
}

/// Which `CombatState` belongs to each `World` (weak).
@MainActor
enum CombatAttachment {
    private struct Entry {
        weak var world: World?
        let state: CombatState
    }

    private static var entries: [ObjectIdentifier: Entry] = [:]

    static func state(for world: World) -> CombatState {
        let key = ObjectIdentifier(world)
        if let entry = entries[key], entry.world === world { return entry.state }
        entries = entries.filter { $0.value.world != nil }
        let state = CombatState()
        entries[key] = Entry(world: world, state: state)
        return state
    }
}

extension World {
    /// The world's hit log and damage types.
    public var combat: CombatState { CombatAttachment.state(for: self) }

    /// The entity whose `Health` a hit on `entity` damages: it or its nearest ancestor with one.
    public func damageable(_ entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let e = current, isAlive(e) {
            if has(Health.self, for: e) { return e }
            current = parent(of: e)
        }
        return nil
    }

    /// Damages `target` (or its nearest ancestor with a `Health`) by `amount` of `type` from
    /// `attacker`, times `multiplier` and the victim's resistance to `type`, and logs the hit
    /// (`combat.events`). Returns nil, changing nothing, when there is no `Health`, it is
    /// already dead or invulnerable, or attacker and victim are on the same team. Negative
    /// damage (or a negative resistance) heals, up to `max`. Reaching 0 sets `dead` and the
    /// event's `killed`. `point` defaults to the victim's position (1 m up), `normal` to the
    /// way toward the attacker.
    @discardableResult
    public func applyDamage(_ amount: Float, to target: Entity, type: String = "physical", from attacker: Entity? = nil,
                            point: Vec3? = nil, normal: Vec3? = nil, bone: String = "", region: String = "", multiplier: Float = 1,
                            hitbox: String = "", knockback: Float = 0, team: String? = nil) -> HitEvent? {
        guard amount.isFinite, let victim = damageable(target), var health = get(Health.self, for: victim), !health.dead else { return nil }
        if health.invulnerableRemaining > 0 && amount > 0 { return nil }
        let attackerTeam = team ?? attacker.flatMap { damageable($0) }.flatMap { get(Health.self, for: $0)?.team } ?? ""
        if !attackerTeam.isEmpty, attackerTeam == health.team { return nil }
        if let attacker, damageable(attacker) == victim, amount > 0 { return nil }
        let dealt = amount * multiplier * health.resistance(to: type)
        health.current = Swift.min(Swift.max(health.current - dealt, 0), health.max)
        let killed = health.current <= 0
        if killed { health.dead = true }
        if dealt > 0 { health.invulnerableRemaining = health.invulnerableTime }
        add(health, to: victim)
        let victimPosition = worldMatrix(of: victim) * Vec4(0, 0, 0, 1)
        let at = point ?? Vec3(victimPosition.x, victimPosition.y + 1, victimPosition.z)
        var away = normal ?? .zero
        if normal == nil, let attacker, isAlive(attacker) {
            let a = worldMatrix(of: attacker) * Vec4(0, 0, 0, 1)
            let d = Vec3(a.x - victimPosition.x, 0, a.z - victimPosition.z)
            away = length(d) > 1e-5 ? normalize(d) : Vec3(0, 1, 0)
        } else if normal == nil {
            away = Vec3(0, 1, 0)
        }
        return combat.record(HitEvent(sequence: 0, attacker: attacker, victim: victim, damage: dealt, rawDamage: amount, type: type,
                                      point: at, normal: away, bone: bone, region: region, hitbox: hitbox, knockback: knockback,
                                      health: health.current, killed: killed))
    }

    /// Heals `target` (or its nearest ancestor with a `Health`) by `amount`, up to `max`; returns
    /// the health after, nil without a `Health`. Doesn't bring the dead back (set `current` and
    /// `dead` for that) and logs nothing.
    @discardableResult
    public func heal(_ amount: Float, _ target: Entity) -> Float? {
        guard let victim = damageable(target), var health = get(Health.self, for: victim) else { return nil }
        guard !health.dead else { return health.current }
        health.current = Swift.min(health.current + Swift.max(amount, 0), health.max)
        add(health, to: victim)
        return health.current
    }

    /// Counts down every `Health`'s invulnerability by `dt` (the combat system does it each frame).
    public func tickInvulnerability(_ dt: Float) {
        queryMutating(Health.self) { _, health in
            if health.invulnerableRemaining > 0 { health.invulnerableRemaining = Swift.max(health.invulnerableRemaining - dt, 0) }
        }
    }
}
