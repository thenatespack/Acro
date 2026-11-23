import Foundation
import EngineCore
import EnginePhysics
import EngineScene

// The `.character` file's `combat` section (Character Builder):
//
// ```json
// "combat": {"health": 100, "team": "enemies", "resistances": {"fire": 0.5},
//            "regions": {"head": 2.5}, "hitboxes": [{"name": "Punch", "state": "attack", "bone": "hand.R",
//            "start": 0.3, "end": 0.55, "damage": {"amount": 15, "type": "blunt"}}]}
// ```
//
// Every key is optional. With the section, the importer puts a `Health` on the prefab's root,
// `Hurtbox`es on the bones (capsules sized like the ragdoll's bodies, `CharacterRig.hurtboxes`)
// with a damage multiplier per body region (head 2, torso 1, arms and legs 0.75 by default), and
// hitbox tracks on its `Animator` (by default the right hand during the attack clip's swing).

/// A character's combat settings (see the notes at the top of CharacterCombat.swift).
public struct CharacterCombat: Codable, Equatable, Sendable {
    /// Health points; nil: 100.
    public var health: Float?
    public var team: String?
    /// Damage multipliers per damage type (`Health.resistances`).
    public var resistances: [String: Float]
    /// Hurtboxes on the bones (default true).
    public var hurtboxes: Bool
    /// Damage multipliers per body region (head, torso, arm, leg, tail, wing), over the defaults.
    public var regions: [String: Float]
    /// Hitbox tracks for the Animator; nil: the template's default (`CharacterRig.defaultHitboxes`), [] none.
    public var hitboxes: [HitboxTrack]?
    /// Seconds after death until the character is removed (0: it stays).
    public var removeAfter: Float?

    public init(health: Float? = nil, team: String? = nil, resistances: [String: Float] = [:], hurtboxes: Bool = true,
                regions: [String: Float] = [:], hitboxes: [HitboxTrack]? = nil, removeAfter: Float? = nil) {
        self.health = health
        self.team = team
        self.resistances = resistances
        self.hurtboxes = hurtboxes
        self.regions = regions
        self.hitboxes = hitboxes
        self.removeAfter = removeAfter
    }

    private enum CodingKeys: String, CodingKey { case health, team, resistances, hurtboxes, regions, hitboxes, removeAfter }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        health = try c.decodeIfPresent(Float.self, forKey: .health)
        team = try c.decodeIfPresent(String.self, forKey: .team)
        resistances = try c.decodeIfPresent([String: Float].self, forKey: .resistances) ?? [:]
        hurtboxes = try c.decodeIfPresent(Bool.self, forKey: .hurtboxes) ?? true
        regions = try c.decodeIfPresent([String: Float].self, forKey: .regions) ?? [:]
        hitboxes = try c.decodeIfPresent([HitboxTrack].self, forKey: .hitboxes)
        removeAfter = try c.decodeIfPresent(Float.self, forKey: .removeAfter)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(health, forKey: .health)
        try c.encodeIfPresent(team, forKey: .team)
        if !resistances.isEmpty { try c.encode(resistances, forKey: .resistances) }
        if !hurtboxes { try c.encode(hurtboxes, forKey: .hurtboxes) }
        if !regions.isEmpty { try c.encode(regions, forKey: .regions) }
        try c.encodeIfPresent(hitboxes, forKey: .hitboxes)
        try c.encodeIfPresent(removeAfter, forKey: .removeAfter)
    }

    /// The default damage multiplier of each body region.
    public static let defaultRegions: [String: Float] = ["head": 2, "torso": 1, "arm": 0.75, "leg": 0.75, "tail": 0.5, "wing": 0.75]

    /// `region`'s multiplier: the file's, else the default, else 1.
    public func multiplier(_ region: String) -> Float { regions[region] ?? Self.defaultRegions[region] ?? 1 }

    /// The `Health` for the root.
    public var healthComponent: Health {
        Health(max: max(health ?? 100, 0), resistances: resistances, team: team ?? "", removeAfter: max(removeAfter ?? 0, 0))
    }
}

/// One hurtbox the importer puts on a bone.
public struct CharacterHurtbox: Equatable, Sendable {
    public var bone: String
    public var hurtbox: Hurtbox
}

extension CharacterRig {
    /// The body region a bone belongs to (head, torso, arm, leg, tail, wing).
    public func region(of bone: String) -> String {
        let name = bone.lowercased()
        if name.hasPrefix("head") || name.hasPrefix("neck") { return "head" }
        if name.contains("arm") || name.hasPrefix("hand") { return "arm" }
        if name.contains("leg") || name.hasPrefix("foot") || name.hasPrefix("shin") || name.contains("upper") || name.contains("lower") { return "leg" }
        if name.hasPrefix("tail") { return "tail" }
        if name.hasPrefix("wing") { return "wing" }
        return "torso"
    }

    /// Hurtboxes over the ragdoll's bodies (`ragdollBones`): a capsule from each bone to its end
    /// bone (or along +Y), a little fatter than the body, with `combat`'s region multipliers.
    public func hurtboxes(_ combat: CharacterCombat = CharacterCombat()) -> [CharacterHurtbox] {
        guard combat.hurtboxes else { return [] }
        return ragdollBones().compactMap { body in
            guard let i = index(of: body.bone) else { return nil }
            var end = Vec3(0, body.length, 0)
            if let name = body.end, let j = index(of: name) { end = bones[j].position - bones[i].position }
            let radius = body.radius * 1.15
            let shape: HitShape = length(end) < 1e-4 ? .sphere(radius: radius) : .capsule(from: .zero, to: end, radius: radius)
            let region = region(of: body.bone)
            return CharacterHurtbox(bone: body.bone, hurtbox: Hurtbox(shape: shape, region: region, multiplier: combat.multiplier(region)))
        }
    }

    /// The template's attack hitbox: the striking limb during the attack clip's swing.
    public var defaultHitboxes: [HitboxTrack] {
        let s = proportions.height
        switch template {
        case .humanoid:
            return [HitboxTrack(name: "Attack", state: "attack", bone: "hand.R", shape: .sphere(radius: 0.12 * s, at: Vec3(0, -0.04 * s, 0)),
                                start: 0.28, end: 0.55, damage: HitDamage(amount: 20, type: "blunt", knockback: 4))]
        case .quadruped:
            return [HitboxTrack(name: "Bite", state: "attack", bone: "head", shape: .sphere(radius: 0.14 * s, at: Vec3(0, 0, 0.12 * s)),
                                start: 0.3, end: 0.6, damage: HitDamage(amount: 15, type: "pierce", knockback: 2))]
        case .bird:
            return [HitboxTrack(name: "Peck", state: "attack", bone: "head", shape: .sphere(radius: 0.08 * s, at: Vec3(0, 0, 0.06 * s)),
                                start: 0.3, end: 0.6, damage: HitDamage(amount: 5, type: "pierce", knockback: 1))]
        case .blob:
            return [HitboxTrack(name: "Slam", state: "attack", bone: "body", shape: .sphere(radius: 0.4 * s, at: Vec3(0, 0.2 * s, 0.2 * s)),
                                start: 0.35, end: 0.6, damage: HitDamage(amount: 10, type: "blunt", knockback: 5))]
        }
    }

    /// The hitbox tracks for `combat` (its own, else the default), keeping those on existing bones.
    public func hitboxes(_ combat: CharacterCombat) -> [HitboxTrack] {
        (combat.hitboxes ?? defaultHitboxes).filter { index(of: $0.bone) != nil }
    }

    /// Problems with `combat`: hitboxes on bones the template lacks, bad tracks, bad numbers.
    public func combatProblems(_ combat: CharacterCombat) -> [String] {
        var problems: [String] = []
        if let h = combat.health, !(h > 0) { problems.append("combat: health must be above 0") }
        for (region, value) in combat.regions.sorted(by: { $0.key < $1.key }) where !(value >= 0) {
            problems.append("combat: region '\(region)' multiplier must be 0 or more")
        }
        for track in combat.hitboxes ?? [] {
            problems += track.problems.map { "combat: " + $0 }
            if index(of: track.bone) == nil, !track.bone.isEmpty {
                problems.append("combat: hitbox '\(track.name)': no bone '\(track.bone)' in the \(template.rawValue) template")
            }
        }
        return problems
    }
}
