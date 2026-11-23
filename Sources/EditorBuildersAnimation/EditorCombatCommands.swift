import EditorCore
import Engine
import Foundation

// Combat and interaction tools: hitbox tracks in .animgraph files (`animGraph.hitboxes`), a
// character's combat settings (`character.combat`), the scene's hitboxes, hurtboxes and health
// (`combat.inspect`), a simulated hit (`combat.simulateHit`), the Scene view overlay
// (`combat.overlay`), and interactables (`interaction.list`, `interaction.use`).

public enum AnimGraphHitboxesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Replace every hitbox with these.
        public var set: [HitboxTrack]?
        /// Add these (names made unique) or, when a hitbox has the name, change it: only the keys given.
        public var add: [JSONValue]?
        /// Names of hitboxes to remove.
        public var remove: [String]?
        public init(asset: AssetReference? = nil, path: String? = nil, set: [HitboxTrack]? = nil, add: [JSONValue]? = nil, remove: [String]? = nil) {
            self.asset = asset
            self.path = path
            self.set = set
            self.add = add
            self.remove = remove
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var hitboxes: [HitboxTrack]
        /// The graph's states (what `state` can name).
        public var states: [String]
        public var warnings: [String]
    }

    public static let id: CommandID = "animGraph.hitboxes"
    public static let title = "Animation Graph Hitboxes"
    public static let doc = "Reads or edits an .animgraph file's hitboxes: shapes on bones that deal damage while a state plays inside a window of its cycle (a swing). Each is {name, state (sub-machine states by path, \"Combat/Slash\"), clip (instead of state), bone, shape {kind: sphere | capsule | box, radius, from, to, size}, start, end (fractions 0...1 of the cycle), damage {amount, type, knockback}}. `set` replaces them all; `add` adds new ones or changes the named ones (only the keys given); `remove` deletes by name; one undo step. Animators playing the graph get them (Animator.hitboxes): in play mode each swing hits a victim's hurtboxes once. With no changes it lists them with the graph's states."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, original) = try session.resolveAnimationGraph(arguments, title)
        let graph = try edited(original, with: arguments)
        var warnings: [String] = []
        if graph != original {
            warnings = try session.commands.require(session.applyAnimationGraph(graph, to: id, label: title), title)
        }
        for problem in AnimationGraphCheck.problems(graph) where problem.contains("hitbox") && !warnings.contains(problem) { warnings.append(problem) }
        return Result(asset: id, path: session.assets?.path(of: id) ?? "", hitboxes: graph.hitboxes, states: graph.flattened().states.map(\.name),
                      warnings: warnings)
    }

    /// `graph` with the changes of `arguments` (pure, for tests and the tab).
    public static func edited(_ graph: AnimationGraph, with arguments: Arguments) throws -> AnimationGraph {
        var g = graph
        if let set = arguments.set { g.hitboxes = set }
        for name in arguments.remove ?? [] {
            guard g.hitboxes.contains(where: { $0.name == name }) else {
                throw CommandError.failed("remove: no hitbox named '\(name)' (hitboxes: \(g.hitboxes.map(\.name).joined(separator: ", ")))")
            }
            g.hitboxes.removeAll { $0.name == name }
        }
        for change in arguments.add ?? [] {
            guard case .object(let fields) = change else { throw CommandError.failed("add: each hitbox is an object") }
            let name = fields["name"].flatMap { if case .string(let s) = $0 { s } else { nil } }
            if let name, let i = g.hitboxes.firstIndex(where: { $0.name == name }) {
                g.hitboxes[i] = try merged(g.hitboxes[i], fields)
            } else {
                var track = try merged(HitboxTrack(), fields)
                track.name = g.uniqueHitboxName(name ?? "Hit")
                g.hitboxes.append(track)
            }
        }
        return g
    }

    /// `track` with the keys of `fields` (nested objects merged too).
    static func merged(_ track: HitboxTrack, _ fields: [String: JSONValue]) throws -> HitboxTrack {
        guard case .object(var base) = try AssetJSON.value(track) else { return track }
        for (key, value) in fields {
            if case .object(let inner) = value, case .object(var old)? = base[key] {
                for (k, v) in inner { old[k] = v }
                base[key] = .object(old)
            } else {
                base[key] = value
            }
        }
        do {
            return try AssetJSON.decoder().decode(HitboxTrack.self, from: AssetJSON.encode(JSONValue.object(base)))
        } catch {
            throw CommandError.failed("add: not a hitbox: \(error)")
        }
    }
}

/// One hurtbox the importer puts on a character's bone.
public struct CharacterHurtboxInfo: Codable, Equatable, Sendable {
    public var bone: String
    public var region: String
    public var multiplier: Float
    public var shape: HitShape
}

public enum CharacterCombatCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var asset: AssetReference?
        public var path: String?
        /// Health points (0 or less: the default 100).
        public var health: Float?
        public var team: String?
        /// Damage multipliers per type, merged (a negative value removes the entry).
        public var resistances: [String: Float]?
        /// Hurtboxes on the bones.
        public var hurtboxes: Bool?
        /// Damage multipliers per body region (head, torso, arm, leg, tail, wing), merged (negative removes).
        public var regions: [String: Float]?
        /// The Animator's hitbox tracks (replacing the file's); `defaultHitboxes` goes back to the template's.
        public var hitboxes: [HitboxTrack]?
        public var defaultHitboxes: Bool?
        /// Seconds after death until the character is removed.
        public var removeAfter: Float?
        /// Remove the combat section.
        public var remove: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, health: Float? = nil, team: String? = nil, resistances: [String: Float]? = nil,
                    hurtboxes: Bool? = nil, regions: [String: Float]? = nil, hitboxes: [HitboxTrack]? = nil, defaultHitboxes: Bool? = nil,
                    removeAfter: Float? = nil, remove: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.health = health
            self.team = team
            self.resistances = resistances
            self.hurtboxes = hurtboxes
            self.regions = regions
            self.hitboxes = hitboxes
            self.defaultHitboxes = defaultHitboxes
            self.removeAfter = removeAfter
            self.remove = remove
        }

        var changesFile: Bool {
            health != nil || team != nil || resistances != nil || hurtboxes != nil || regions != nil || hitboxes != nil || defaultHitboxes != nil
                || removeAfter != nil || remove != nil
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        /// The file's combat section (nil: none, so the prefab has no Health, hurtboxes or hitboxes).
        public var combat: CharacterCombat?
        /// What the importer makes of it.
        public var hurtboxes: [CharacterHurtboxInfo]
        public var hitboxes: [HitboxTrack]
        public var warnings: [String]
    }

    public static let id: CommandID = "character.combat"
    public static let title = "Character Combat"
    public static let doc = "Reads or changes a .character file's combat settings. With them the prefab's root gets a Health (`health`, `team`, `resistances` per damage type, `removeAfter` death), its bones Hurtboxes (capsules over the ragdoll bodies, a little fatter; damage multipliers per body region: head 2, torso 1, arm and leg 0.75 unless `regions` changes them) and its Animator hitbox tracks (`hitboxes`, by default the template's attack: the right hand during the attack clip's swing for a humanoid). Any argument adds the section; `remove` deletes it; one undo step. With no changes it lists the hurtboxes and hitboxes the importer makes."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, original) = try session.resolveCharacter(arguments.asset, path: arguments.path, title)
        let character = edited(original, with: arguments)
        var warnings: [String] = []
        if arguments.changesFile, character != original {
            warnings = try session.commands.require(session.applyCharacter(character, to: id, label: title), title)
        }
        let rig = character.rig
        if let combat = character.combat {
            for problem in rig.combatProblems(combat) where !warnings.contains(problem) { warnings.append(problem) }
        }
        let hurtboxes = character.combat.map { rig.hurtboxes($0) } ?? []
        return Result(asset: id, path: session.assets?.path(of: id) ?? "", combat: character.combat,
                      hurtboxes: hurtboxes.map { CharacterHurtboxInfo(bone: $0.bone, region: $0.hurtbox.region, multiplier: $0.hurtbox.multiplier, shape: $0.hurtbox.shape) },
                      hitboxes: character.combat.map { rig.hitboxes($0) } ?? [], warnings: warnings)
    }

    /// `character` with the combat changes of `arguments` (pure, for tests and the tab).
    public static func edited(_ character: CharacterBuild, with arguments: Arguments) -> CharacterBuild {
        var c = character
        if arguments.remove == true {
            c.combat = nil
            return c
        }
        guard arguments.changesFile else { return c }
        var combat = c.combat ?? CharacterCombat()
        if let v = arguments.health { combat.health = v > 0 ? v : nil }
        if let v = arguments.team { combat.team = v.isEmpty ? nil : v }
        for (type, value) in arguments.resistances ?? [:] { combat.resistances[type] = value < 0 ? nil : value }
        if let v = arguments.hurtboxes { combat.hurtboxes = v }
        for (region, value) in arguments.regions ?? [:] { combat.regions[region] = value < 0 ? nil : value }
        if let v = arguments.hitboxes { combat.hitboxes = v }
        if arguments.defaultHitboxes == true { combat.hitboxes = nil }
        if let v = arguments.removeAfter { combat.removeAfter = v > 0 ? v : nil }
        c.combat = combat
        return c
    }
}

// MARK: - The scene's combat

/// A hitbox or hurtbox as `combat.inspect` lists it.
public struct CombatVolumeInfo: Codable, Equatable, Sendable {
    public var name: String
    /// The entity it is attached to (a bone) and the one it belongs to (attacker or victim).
    public var entity: EntityID?
    public var owner: EntityID?
    public var bone: String
    public var kind: String
    /// World-space ends (a sphere: equal) or the box center, and the radius or half extents.
    public var from: Vec3
    public var to: Vec3
    public var radius: Float
    public var halfExtents: Vec3?
    /// Hitboxes: active now, and what they deal.
    public var active: Bool?
    public var damage: HitDamage?
    /// Hurtboxes: region and damage multiplier.
    public var region: String?
    public var multiplier: Float?
}

/// A `Health` as `combat.inspect` lists it.
public struct CombatHealthInfo: Codable, Equatable, Sendable {
    public var entity: EntityID?
    public var name: String
    public var current: Float
    public var max: Float
    public var dead: Bool
    public var team: String
    public var resistances: [String: Float]
}

/// A hit as the tools report it.
public struct CombatHitInfo: Codable, Equatable, Sendable {
    public var sequence: Int
    public var attacker: EntityID?
    public var victim: EntityID?
    public var victimName: String
    public var damage: Float
    public var type: String
    public var point: Vec3
    public var normal: Vec3
    public var bone: String
    public var region: String
    public var hitbox: String
    public var health: Float
    public var killed: Bool

    @MainActor init(_ event: HitEvent, in world: World) {
        sequence = event.sequence
        attacker = event.attacker.flatMap { world.id(of: $0) }
        victim = world.id(of: event.victim)
        victimName = world.get(Name.self, for: event.victim)?.value ?? ""
        damage = event.damage
        type = event.type
        point = event.point
        normal = event.normal
        bone = event.bone
        region = event.region
        hitbox = event.hitbox
        health = event.health
        killed = event.killed
    }
}

public enum CombatInspectCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Only this entity and its children (nil: the whole scene).
        public var entity: EntityID?
        /// Leave out hitboxes that aren't active now (default false: list them all).
        public var activeOnly: Bool?
        public init(entity: EntityID? = nil, activeOnly: Bool? = nil) {
            self.entity = entity
            self.activeOnly = activeOnly
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var health: [CombatHealthInfo]
        public var hitboxes: [CombatVolumeInfo]
        public var hurtboxes: [CombatVolumeInfo]
        /// The latest hits (up to 10), oldest first.
        public var recentHits: [CombatHitInfo]
        public var playing: Bool
    }

    public static let id: CommandID = "combat.inspect"
    public static let title = "Inspect Combat"
    public static let doc = "Lists the scene's damageable entities (Health: current, max, dead, team, resistances), hitboxes (Hitbox components and animator hitbox tracks: world-space shape, whether active now, damage) and hurtboxes (shape, region, multiplier), and the latest hits. `entity` limits it to one entity's subtree. Hitbox tracks are active only while playing (their state's window). See combat.overlay to draw them."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.gameWorld
        var root: Entity?
        if let id = arguments.entity { root = try world.require(id) }
        func inside(_ e: Entity) -> Bool {
            guard let root else { return true }
            var current: Entity? = e
            while let c = current {
                if c == root { return true }
                current = world.parent(of: c)
            }
            return false
        }
        var health: [CombatHealthInfo] = []
        world.query(Health.self) { e, h in
            guard inside(e) else { return }
            health.append(CombatHealthInfo(entity: world.id(of: e), name: world.get(Name.self, for: e)?.value ?? "", current: h.current, max: h.max,
                                           dead: h.dead, team: h.team, resistances: h.resistances))
        }
        func info(_ v: HitVolume) -> (String, Vec3, Vec3, Float, Vec3?) {
            v.kind == .box ? ("box", v.a, v.a, 0, v.halfExtents) : (v.a == v.b ? "sphere" : "capsule", v.a, v.b, v.radius, nil)
        }
        let hitboxes = CombatSystem.hitboxes(in: world, includeInactive: arguments.activeOnly != true)
            .filter { inside($0.bone) }
            .map { h -> CombatVolumeInfo in
                let (kind, from, to, radius, half) = info(h.volume)
                return CombatVolumeInfo(name: h.name, entity: world.id(of: h.bone), owner: world.id(of: h.attacker), bone: h.boneName, kind: kind,
                                        from: from, to: to, radius: radius, halfExtents: half, active: h.active, damage: h.damage)
            }
        let hurtboxes = CombatSystem.hurtboxes(in: world, includeDead: true)
            .filter { inside($0.entity) }
            .map { h -> CombatVolumeInfo in
                let (kind, from, to, radius, half) = info(h.volume)
                return CombatVolumeInfo(name: h.boneName, entity: world.id(of: h.entity), owner: world.id(of: h.victim), bone: h.boneName, kind: kind,
                                        from: from, to: to, radius: radius, halfExtents: half, region: h.region, multiplier: h.multiplier)
            }
        let hits = world.combat.events.suffix(10).filter { root == nil || inside($0.victim) || $0.attacker.map(inside) == true }
        return Result(health: health, hitboxes: hitboxes, hurtboxes: hurtboxes, recentHits: hits.map { CombatHitInfo($0, in: world) },
                      playing: session.isPlaying)
    }
}

public enum CombatSimulateHitCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The entity hit (it or its nearest ancestor with a Health takes the damage).
        public var victim: EntityID
        /// Who hits (nil: nobody; its team is spared).
        public var attacker: EntityID?
        /// Damage before multipliers (default 10).
        public var damage: Float?
        /// Damage type (default physical).
        public var type: String?
        /// A bone (entity name under the victim) to hit: its hurtbox's region multiplier applies and the hit lands there.
        public var bone: String?
        /// World-space hit point (default the bone's hurtbox, else 1 m above the victim).
        public var point: Vec3?
        /// Knockback impulse, N·s (default 3).
        public var knockback: Float?
        /// Frames to step afterwards (paused play) so the effects run (default 1).
        public var frames: Int?
        public init(victim: EntityID, attacker: EntityID? = nil, damage: Float? = nil, type: String? = nil, bone: String? = nil, point: Vec3? = nil,
                    knockback: Float? = nil, frames: Int? = nil) {
            self.victim = victim
            self.attacker = attacker
            self.damage = damage
            self.type = type
            self.bone = bone
            self.point = point
            self.knockback = knockback
            self.frames = frames
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// The hit, or nil when it did nothing (no Health, already dead, invulnerable, same team).
        public var hit: CombatHitInfo?
        public var health: CombatHealthInfo?
        /// The victim's Ragdoll mode after the effects (animated, partial, full), if it has one.
        public var ragdoll: String?
    }

    public static let id: CommandID = "combat.simulateHit"
    public static let title = "Simulate Hit"
    public static let doc = "While playing, hits `victim` as a hitbox would: `damage` of `type` from `attacker` at `bone` (its hurtbox's region multiplier applies) or `point`, then steps `frames` (default 1) so the combat system runs the effects: hit flash, hit stop, camera shake, VFX and sound, a partial ragdoll hit reaction, a full ragdoll on death, On Hit / On Death in visual scripts. Returns the hit (damage dealt after multipliers and resistances, killed), the victim's health and ragdoll mode."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        let target = try world.require(arguments.victim)
        let attacker = try arguments.attacker.map { try world.require($0) }
        guard let victim = world.damageable(target) else { throw CommandError.failed("\(title): the entity has no Health (nor does any ancestor)") }
        var point = arguments.point, multiplier: Float = 1, region = "", normal: Vec3?
        if let bone = arguments.bone {
            guard let boneEntity = CombatSystem.descendant(named: bone, of: victim, in: world) else {
                throw CommandError.failed("\(title): no entity named '\(bone)' under the victim")
            }
            if let hurtbox = CombatSystem.hurtboxes(in: world, includeDead: true).first(where: { $0.entity == boneEntity }) {
                multiplier = hurtbox.multiplier
                region = hurtbox.region
                if point == nil { point = hurtbox.volume.center }
            } else if point == nil {
                let m = world.worldMatrix(of: boneEntity)
                point = Vec3(m.c3.x, m.c3.y, m.c3.z)
            }
        }
        if let attacker, let point {
            let m = world.worldMatrix(of: attacker)
            let d = Vec3(m.c3.x, point.y, m.c3.z) - point
            if length(d) > 1e-4 { normal = normalize(d) }
        }
        let event = world.applyDamage(arguments.damage ?? 10, to: victim, type: arguments.type ?? "physical", from: attacker, point: point,
                                      normal: normal, bone: arguments.bone ?? "", region: region, multiplier: multiplier, hitbox: "combat.simulateHit",
                                      knockback: arguments.knockback ?? 3)
        let frames = max(arguments.frames ?? 1, 0)
        if frames > 0 { _ = session.step(frames: frames) }
        let health = world.get(Health.self, for: victim).map {
            CombatHealthInfo(entity: world.id(of: victim), name: world.get(Name.self, for: victim)?.value ?? "", current: $0.current, max: $0.max,
                             dead: $0.dead, team: $0.team, resistances: $0.resistances)
        }
        let ragdoll = VisualScriptNodes.findRagdollMode(from: victim, in: world)
        return Result(hit: event.map { CombatHitInfo($0, in: world) }, health: health, ragdoll: ragdoll)
    }
}

public enum CombatOverlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Show (default) or hide the overlay.
        public var show: Bool?
        public init(show: Bool? = nil) { self.show = show }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var shown: Bool
        public var hitboxes: Int
        public var hurtboxes: Int
    }

    static let overlayName = "combat"

    public static let id: CommandID = "combat.overlay"
    public static let title = "Show Hitboxes"
    public static let doc = "Shows or hides hitboxes and hurtboxes in the Scene view, drawn over the scene: hurtboxes blue (gray once dead), hitboxes dim yellow, active ones bright red and thicker, and arrows along the normals of the latest hits. While playing it follows the animation (hitbox tracks light up during their window). view.screenshot shows it with gizmos on."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let show = arguments.show ?? true
        if show {
            session.sceneOverlays[overlayName] = { draw, world in CombatSystem.drawDebug(world, into: draw) }
        } else {
            session.sceneOverlays[overlayName] = nil
        }
        let world = session.gameWorld
        return Result(shown: show, hitboxes: CombatSystem.hitboxes(in: world, includeInactive: true).count,
                      hurtboxes: CombatSystem.hurtboxes(in: world, includeDead: true).count)
    }
}

// MARK: - Interaction

/// An interactable as `interaction.list` reports it.
public struct InteractableInfo: Codable, Equatable, Sendable {
    public var entity: EntityID?
    public var name: String
    public var enabled: Bool
    public var action: InteractionAction
    /// The verb its prompt shows now ("Open", "Pull", "Pick up key").
    public var verb: String
    /// door, lever, container, pickup or custom.
    public var kind: String
    /// Door open / lever on / container open.
    public var state: Bool?
    public var uses: Int
}

/// An interactor as `interaction.list` reports it.
public struct InteractorInfo: Codable, Equatable, Sendable {
    public var entity: EntityID?
    public var name: String
    /// What it focuses now (while playing) and the prompt shown ("[E] Open").
    public var focus: EntityID?
    public var prompt: String?
    public var items: [String: Int]
}

public enum InteractionListCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public init() {}
    }

    public struct Result: Codable, Equatable, Sendable {
        public var interactables: [InteractableInfo]
        public var interactors: [InteractorInfo]
        /// The glyphs of the use and pick-up actions' current bindings (while playing).
        public var glyphs: [String: String]
        public var playing: Bool
    }

    public static let id: CommandID = "interaction.list"
    public static let title = "List Interactables"
    public static let doc = "Lists the scene's interactables (verb its prompt shows, use or pick-up action, enabled, door / lever / container state, times used) and interactors (what each focuses while playing, the prompt with the action's current input glyph, items carried)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func unavailableReason(in session: EditorSession) -> String? { nil }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.gameWorld
        var interactables: [InteractableInfo] = []
        world.query(Interactable.self) { e, i in
            var kind = "custom"
            var state: Bool?
            if let door = world.get(Door.self, for: e) { kind = "door"; state = door.open }
            else if let lever = world.get(Lever.self, for: e) { kind = "lever"; state = lever.on }
            else if let container = world.get(Container.self, for: e) { kind = "container"; state = container.open }
            else if world.has(Pickup.self, for: e) { kind = "pickup" }
            interactables.append(InteractableInfo(entity: world.id(of: e), name: world.get(Name.self, for: e)?.value ?? "", enabled: i.enabled,
                                                  action: i.action, verb: InteractionSystem.verb(for: e, interactor: nil, in: world), kind: kind,
                                                  state: state, uses: i.uses))
        }
        let interaction = world.gameplay?.interaction
        var interactors: [InteractorInfo] = []
        world.query(Interactor.self) { e, i in
            let focus = world.interactionFocus(of: e)
            interactors.append(InteractorInfo(entity: world.id(of: e), name: world.get(Name.self, for: e)?.value ?? "",
                                              focus: focus.flatMap { world.id(of: $0) }, prompt: interaction?.prompts[e], items: i.items))
        }
        var glyphs: [String: String] = [:]
        if let interaction { for action in ["use", "pickUp"] { glyphs[action] = interaction.glyph(for: action) } }
        return Result(interactables: interactables, interactors: interactors, glyphs: glyphs, playing: session.isPlaying)
    }
}

public enum InteractionUseCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The interactor (default: the first Interactor in the scene).
        public var interactor: EntityID?
        /// What to use (default: what the interactor focuses).
        public var target: EntityID?
        public init(interactor: EntityID? = nil, target: EntityID? = nil) {
            self.interactor = interactor
            self.target = target
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// What it did: opened, closed, locked, unlocked, on, off, looted, picked up, used.
        public var result: String
        public var verb: String
        public var items: [String: Int]
    }

    public static let id: CommandID = "interaction.use"
    public static let title = "Use Interactable"
    public static let doc = "While playing, makes an interactor use an interactable as if it pressed the action: a door opens or closes (a locked one needs its key item), a lever flips and toggles its target, a container opens and hands over its items, a pickup joins the interactor's items. Defaults: the first Interactor and what it focuses. Not recorded in playtests (press the use action there: input.action {action: \"use\"})."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        guard let interaction = world.gameplay?.interaction else { throw CommandError.failed("\(title): the gameplay systems aren't running") }
        var interactor = try arguments.interactor.map { try world.require($0) }
        if interactor == nil {
            var first: Entity?
            world.query(Interactor.self) { e, _ in if first == nil { first = e } }
            interactor = first
        }
        guard let interactor else { throw CommandError.failed("\(title): the scene has no Interactor") }
        guard let target = try arguments.target.map({ try world.require($0) }) ?? world.interactionFocus(of: interactor) else {
            throw CommandError.failed("\(title): the interactor focuses nothing (walk it closer, or pass target)")
        }
        guard let event = interaction.interact(interactor, with: target, in: world) else {
            throw CommandError.failed("\(title): it has no enabled Interactable")
        }
        return Result(result: event.result, verb: event.verb, items: world.get(Interactor.self, for: interactor)?.items ?? [:])
    }
}

extension VisualScriptNodes {
    /// The mode of the first Ragdoll at or under `entity`, if any.
    @MainActor static func findRagdollMode(from entity: Entity, in world: World) -> String? {
        var queue = [entity]
        var i = 0
        while i < queue.count {
            let e = queue[i]
            i += 1
            if let ragdoll = world.get(Ragdoll.self, for: e) { return ragdoll.mode.rawValue }
            queue += world.children(of: e)
        }
        return nil
    }
}
