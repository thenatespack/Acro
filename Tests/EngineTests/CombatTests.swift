import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EnginePhysics
@testable import EngineAssets
@testable import EngineRendering

// Hitboxes, hurtboxes, damage and hit effects (EngineScene/Gameplay/Damage.swift, HitShapes.swift;
// Engine/Gameplay/Combat.swift, GameFeel.swift), and the combat Visual Script nodes.

@MainActor
@Suite struct CombatTests {
    private func step(_ world: World, _ frames: Int = 1) {
        for _ in 0..<frames { world.update(dt: 1.0 / 60.0) }
    }

    // MARK: Shapes

    @Test func shapesOverlapWithPointAndNormal() throws {
        let a = HitShape.sphere(radius: 0.5).volume(Mat4.translation(Vec3(0, 0, 0)))
        let b = HitShape.capsule(from: Vec3(0, -1, 0), to: Vec3(0, 1, 0), radius: 0.3).volume(Mat4.translation(Vec3(0.7, 0, 0)))
        let hit = try #require(a.contact(with: b))
        // The normal points out of `b` toward `a`; the point is on `b`'s surface.
        #expect(length(hit.normal - Vec3(-1, 0, 0)) < 1e-4)
        #expect(length(hit.point - Vec3(0.4, 0, 0)) < 1e-4)
        #expect(abs(hit.depth - 0.1) < 1e-4)
        let far = HitShape.sphere(radius: 0.5).volume(Mat4.translation(Vec3(2, 0, 0)))
        #expect(far.contact(with: b) == nil)

        // Scale grows spheres; boxes turn with their entity.
        let scaled = HitShape.sphere(radius: 0.5).volume(Mat4.scale(Vec3(2, 1, 1)))
        #expect(scaled.radius == 1)
        let box = HitShape.box(halfExtents: Vec3(1, 0.1, 0.1)).volume(Mat4(translation: .zero, rotation: Quat(angle: .pi / 2, axis: Vec3(0, 0, 1)), scale: .one))
        #expect(HitShape.sphere(radius: 0.2).volume(Mat4.translation(Vec3(0, 1, 0))).contact(with: box) != nil)
        #expect(HitShape.sphere(radius: 0.2).volume(Mat4.translation(Vec3(1, 0, 0))).contact(with: box) == nil)
        let other = HitShape.box(halfExtents: Vec3(0.2, 0.2, 0.2)).volume(Mat4.translation(Vec3(0, 1.1, 0)))
        #expect(box.contact(with: other) != nil)
        #expect(box.contact(with: HitShape.box(halfExtents: Vec3(0.2, 0.2, 0.2)).volume(Mat4.translation(Vec3(0.5, 0, 0)))) == nil)
    }

    @Test func filesDecodeWithEveryKeyOptional() throws {
        let decoder = AssetJSON.decoder()
        let health = try decoder.decode(Health.self, from: Data(#"{"max": 50, "resistances": {"fire": 0.5}}"#.utf8))
        #expect(health.current == 50 && health.resistance(to: "fire") == 0.5 && health.resistance(to: "ice") == 1 && !health.dead)
        let track = try decoder.decode(HitboxTrack.self, from: Data(#"{"bone": "hand.R", "state": "attack", "shape": {"kind": "capsule", "to": [0, -0.5, 0]}}"#.utf8))
        #expect(track.shape.kind == .capsule && track.shape.radius == 0.1 && track.damage == HitDamage())
        #expect(track.problems.isEmpty)
        #expect(try decoder.decode(Hurtbox.self, from: Data("{}".utf8)) == Hurtbox())
        #expect(try decoder.decode(Hitbox.self, from: Data("{}".utf8)) == Hitbox())
        #expect(try decoder.decode(DamageType.self, from: Data(#"{"hitStop": 0.2}"#.utf8)).hitStop == 0.2)
    }

    // MARK: Damage

    @Test func damageUsesResistancesTeamsInvulnerabilityAndKills() throws {
        let world = World()
        let ogre = world.spawn(Transform(), Name("CombatTests.Ogre"), Health(max: 100, resistances: ["fire": 0.5, "poison": 0], team: "monsters", invulnerableTime: 0.5))
        let arm = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("arm"))
        _ = world.setParent(arm, to: ogre)
        let hero = world.spawn(Transform(position: Vec3(0, 0, 3)), Name("CombatTests.Hero"), Health(team: "heroes"))
        let goblin = world.spawn(Transform(), Health(team: "monsters"))

        // A hit on a child damages the nearest Health; resistance halves fire.
        let hit = try #require(world.applyDamage(40, to: arm, type: "fire", from: hero, multiplier: 1.5))
        #expect(hit.victim == ogre && hit.damage == 30 && hit.health == 70 && !hit.killed)
        #expect(length(hit.normal - Vec3(0, 0, 1)) < 1e-4)
        #expect(world.combat.events.last == hit && hit.sequence == world.combat.lastSequence)
        // Invulnerable right after; then immune to poison; same team can't hurt it.
        #expect(world.applyDamage(10, to: ogre, from: hero) == nil)
        world.tickInvulnerability(1)
        #expect(world.applyDamage(10, to: ogre, type: "poison", from: hero)?.damage == 0)
        world.tickInvulnerability(1)
        #expect(world.applyDamage(10, to: ogre, from: goblin) == nil)
        #expect(world.applyDamage(10, to: ogre, from: ogre) == nil)
        // Kill: dead once, then ignored; heal doesn't revive.
        world.tickInvulnerability(1)
        let kill = try #require(world.applyDamage(500, to: ogre, from: hero))
        #expect(kill.killed && kill.health == 0 && world.get(Health.self, for: ogre)?.dead == true)
        #expect(world.applyDamage(5, to: ogre) == nil)
        #expect(world.heal(10, ogre) == 0)
        // Healing the living caps at max; negative damage heals too.
        _ = world.applyDamage(30, to: hero)
        #expect(world.heal(100, hero) == 100)
        #expect(world.get(Health.self, for: hero)?.current == 100)
        // Custom damage types merge over built-ins.
        world.combat.damageTypes["slash"] = DamageType(name: "slash", hitStop: 0.5)
        #expect(world.combat.damageType("slash").hitStop == 0.5 && world.combat.damageType("slash").shake == DamageType.builtIns["slash"]?.shake)
        #expect(world.combat.damageType("acid").name == "acid")
    }

    @Test func hitboxHitsOncePerSwingAndPrefersTheHead() throws {
        let world = World()
        world.addGameplay(input: nil)
        let dummy = world.spawn(Transform(position: Vec3(0, 0, 0)), Name("CombatTests.Dummy"), Health(max: 100))
        let body = world.spawn(Transform(), Name("body"), Hurtbox(shape: .capsule(from: Vec3(0, 0.2, 0), to: Vec3(0, 1.4, 0), radius: 0.3), region: "torso"))
        let head = world.spawn(Transform(position: Vec3(0, 1.6, 0)), Name("head"), Hurtbox(shape: .sphere(radius: 0.2), region: "head", multiplier: 2))
        _ = world.setParent(body, to: dummy)
        _ = world.setParent(head, to: dummy)
        let attacker = world.spawn(Transform(position: Vec3(0, 0, 1)), Name("CombatTests.Attacker"), Health(max: 50))
        // A sword touching both the head and the chest.
        let sword = world.spawn(Transform(position: Vec3(0, 1.5, -0.7)), Name("Sword"),
                                Hitbox(shape: .capsule(from: Vec3(0, -0.4, 0), to: Vec3(0, 0.2, 0), radius: 0.15), active: true,
                                       damage: HitDamage(amount: 10, type: "slash", knockback: 0)))
        _ = world.setParent(sword, to: attacker)
        step(world, 3)
        var health = try #require(world.get(Health.self, for: dummy))
        #expect(health.current == 80, "one hit, on the head (x2): \(health.current)")
        let hit = try #require(world.combat.events.last)
        #expect(hit.bone == "head" && hit.region == "head" && hit.attacker == attacker && hit.hitbox == "Sword")
        #expect(world.gameplay?.combat.recent.isEmpty == true)  // effects ran in the frame of the hit
        // A new swing hits again.
        world.modify(Hitbox.self, for: sword) { $0.active = false }
        step(world)
        world.modify(Hitbox.self, for: sword) { $0.active = true }
        step(world, 2)
        health = try #require(world.get(Health.self, for: dummy))
        #expect(health.current == 60)
        // The attacker's own hurtboxes never count; re-hits every interval while it stays.
        world.modify(Hitbox.self, for: sword) { $0.rehitInterval = 0.1 }
        step(world, 13)
        #expect(world.get(Health.self, for: dummy)!.current < 60)
        #expect(world.get(Health.self, for: attacker)?.current == 50)
    }

    @Test func animationTrackIsActiveInItsWindowOnItsBone() throws {
        let world = World()
        let root = world.spawn(Transform(), Name("CombatTests.Fighter"), Health(team: "a"))
        let hand = world.spawn(Transform(position: Vec3(0.3, 1.2, 0.4)), Name("hand.R"))
        _ = world.setParent(hand, to: root)
        var animator = Animator(targets: [root, hand], restPose: [Transform(), Transform()], clip: AnimationClipHandle("attack"), loops: true,
                                normalizedTime: 0.4)
        animator.hitboxes = [HitboxTrack(name: "Punch", state: "attack", bone: "hand.R", shape: .sphere(radius: 0.1), start: 0.3, end: 0.6),
                             HitboxTrack(name: "Kick", state: "kick", bone: "hand.R", start: 0, end: 1),
                             HitboxTrack(name: "ByClip", clip: "attack", bone: "hand.R", start: 0.5, end: 0.9)]
        world.add(animator, to: root)
        let active = CombatSystem.hitboxes(in: world)
        #expect(active.map(\.name) == ["Punch"])
        let punch = try #require(active.first)
        #expect(punch.bone == hand && punch.attacker == root && punch.team == "a")
        #expect(length(punch.volume.a - Vec3(0.3, 1.2, 0.4)) < 1e-5)
        #expect(CombatSystem.hitboxes(in: world, includeInactive: true).count == 3)
        world.add(Animator(targets: [root, hand], restPose: [Transform(), Transform()], clip: AnimationClipHandle("attack"), normalizedTime: 1.55)
            .withHitboxes(animator.hitboxes!), to: root)
        #expect(CombatSystem.hitboxes(in: world).map(\.name) == ["Punch", "ByClip"])
    }

    @Test func hitEffectsDriveRagdollsHitStopShakeAndDeath() throws {
        let rig = IKTestsRig()
        let world = rig.world
        let physics = PhysicsWorld()
        world.addPhysics(physics)
        let gameplay = world.addGameplay(input: nil, physics: { physics })
        let camera = world.spawn(Transform(position: Vec3(0, 1.5, 4)), Camera())
        world.add(CharacterRig(template: .humanoid).ragdoll(CharacterRagdoll()), to: rig.root)
        world.add(Health(max: 30), to: rig.root)
        let mesh = world.spawn(Transform(), MeshRenderer(mesh: .cube))
        _ = world.setParent(mesh, to: rig.root)
        rig.step(2)

        // A hit: partial ragdoll on the bone, hit stop freezes game time, the camera shakes, the mesh flashes.
        _ = world.applyDamage(10, to: rig.root, type: "blunt", from: camera, point: Vec3(0, 1.4, 0.1), normal: Vec3(0, 0, 1), bone: "spine", knockback: 4)
        rig.step()
        #expect(world.get(Ragdoll.self, for: rig.root)?.mode == .partial)
        #expect(world.hitStopRemaining > 0)
        #expect(gameplay.feel.trauma > 0)
        #expect(world.get(MeshRenderer.self, for: mesh)?.tint != Vec3(1, 1, 1))
        let before = world.time.elapsed
        rig.step()
        #expect(world.time.elapsed - before < 1.0 / 60.0 * 0.1, "hit stop slows game time")
        #expect(gameplay.feel.currentOffset != .zero)
        rig.step(30)
        #expect(world.hitStopRemaining == 0)
        #expect(world.get(MeshRenderer.self, for: mesh)?.tint == Vec3(1, 1, 1))

        // Death: full ragdoll.
        let kill = try #require(world.applyDamage(100, to: rig.root, from: camera))
        #expect(kill.killed)
        rig.step()
        #expect(world.get(Ragdoll.self, for: rig.root)?.mode == .full)

        // Stopping puts time and the camera back.
        world.removeGameplay()
        #expect(world.hitStopRemaining == 0 && world.timeScale == 1)
        #expect(world.get(Transform.self, for: camera)?.position == Vec3(0, 1.5, 4))
    }

    @Test func noRagdollFiresAnimatorTriggersAndRemovesTheDead() throws {
        let world = World()
        world.addGameplay(input: nil)
        let root = world.spawn(Transform(), Health(max: 10, removeAfter: 0.1))
        world.add(Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: []),
                           parameters: ["hit": .trigger(false), "die": .trigger(false)]), to: root)
        _ = world.applyDamage(1, to: root)
        step(world)
        if case .trigger(let set)? = world.get(Animator.self, for: root)?.parameters["hit"] { #expect(set) } else { Issue.record("no hit trigger") }
        _ = world.applyDamage(100, to: root)
        step(world)
        if case .trigger(let set)? = world.get(Animator.self, for: root)?.parameters["die"] { #expect(set) } else { Issue.record("no die trigger") }
        step(world, 40)
        #expect(!world.isAlive(root))
    }

    @Test func hitStopScalesDtAndTimeScaleMultiplies() {
        let world = World()
        var deltas: [Float] = []
        world.addSystem("CombatTests.dt") { w in deltas.append(w.time.delta) }
        world.timeScale = 0.5
        world.update(dt: 0.1)
        world.hitStop(0.15, scale: 0)
        world.update(dt: 0.1)
        world.update(dt: 0.1)
        world.update(dt: 0.1)
        #expect(deltas.map { ($0 * 1000).rounded() / 1000 } == [0.05, 0, 0, 0.05])
        #expect(world.time.unscaledDelta == 0.1)
        world.resetTimeScale()
        #expect(world.timeScale == 1)
    }

    // MARK: Characters

    @Test func characterCombatMakesHurtboxesPerRegionAndTheAttackHitbox() {
        let rig = CharacterRig(template: .humanoid)
        let boxes = rig.hurtboxes(CharacterCombat(regions: ["head": 3]))
        #expect(boxes.count == rig.ragdollBones().count)
        #expect(boxes.first { $0.bone == "head" }?.hurtbox.multiplier == 3)
        #expect(boxes.first { $0.bone == "spine" }?.hurtbox.region == "torso")
        #expect(boxes.first { $0.bone == "lowerLeg.L" }?.hurtbox.multiplier == 0.75)
        #expect(boxes.first { $0.bone == "upperArm.R" }?.hurtbox.region == "arm")
        #expect(rig.hitboxes(CharacterCombat()).map(\.bone) == ["hand.R"])
        #expect(rig.hitboxes(CharacterCombat(hitboxes: [])).isEmpty)
        #expect(rig.hurtboxes(CharacterCombat(hurtboxes: false)).isEmpty)
        var build = CharacterBuild()
        build.combat = CharacterCombat(health: 0, hitboxes: [HitboxTrack(name: "X", state: "attack", bone: "tail")])
        #expect(build.problems.contains { $0.contains("health must be above 0") })
        #expect(build.problems.contains { $0.contains("no bone 'tail'") })
        for template in CharacterTemplate.allCases {
            let r = CharacterRig(template: template)
            #expect(!r.hurtboxes().isEmpty && !r.hitboxes(CharacterCombat()).isEmpty, "\(template)")
        }
    }

    @Test func graphHitboxesRoundTripAndReachTheAnimator() throws {
        var graph = AnimationGraph.starter()
        graph.states = [AnimationGraphState(name: "Swing", clip: "x")]
        #expect(!(try graph.fileData().string.contains("hitboxes")))
        graph.hitboxes = [HitboxTrack(name: "Slash", state: "Swing", bone: "hand.R"), HitboxTrack(name: "Slash", state: "Nope", bone: "hand.R")]
        let decoded = try AssetJSON.decoder().decode(AnimationGraph.self, from: graph.fileData())
        #expect(decoded.hitboxes == graph.hitboxes)
        let problems = AnimationGraphCheck.problems(graph)
        #expect(problems.contains("two hitboxes are named 'Slash'"))
        #expect(problems.contains { $0.contains("names state 'Nope'") })
        #expect(graph.uniqueHitboxName("Slash") == "Slash 2")
        var animator = Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: []))
        animator.apply(graph)
        #expect(animator.hitboxes?.count == 2)
    }

    // MARK: Visual scripts

    @Test func visualScriptNodesApplyDamageAndHearHitsAndDeaths() throws {
        let world = World()
        world.addGameplay(input: nil)
        VisualScriptNodes.registerEngineNodes()
        for id in ["combat.applyDamage", "combat.heal", "combat.health", "combat.hitStop", "combat.shake", "interaction.setEnabled",
                   "interaction.use", "interaction.focus", "event.hit", "event.hitDealt", "event.death", "event.interact"] {
            #expect(VisualScriptNodes.definition(id) != nil, "\(id)")
        }
        let host = VisualScriptHost()
        var lines: [String] = []
        host.log = { lines.append($0) }
        let runtime = world.addVisualScripts(host: host)
        VisualScriptEngineNodes.addEventSources(to: runtime)
        let victim = world.spawn(Transform(), Name("CombatTests.Victim"), Health(max: 30))
        let attacker = world.spawn(Transform(position: Vec3(0, 0, 2)), Name("CombatTests.Striker"))
        func node(_ id: String, _ type: String, inputs: [String: JSONValue] = [:]) -> VisualScriptNode { VisualScriptNode(id: id, type: type, inputs: inputs) }
        runtime.graphs["CombatTests.victim"] = VisualScriptGraph(
            nodes: [node("hit", "event.hit"), node("logHit", "debug.log"), node("death", "event.death"), node("logDeath", "debug.log", inputs: ["message": .string("died")])],
            links: [VisualScriptLink(from: "hit.out", to: "logHit.in"), VisualScriptLink(from: "hit.damage", to: "logHit.message"),
                    VisualScriptLink(from: "death.out", to: "logDeath.in")])
        runtime.graphs["CombatTests.striker"] = VisualScriptGraph(
            nodes: [node("s", "event.start"), node("v", "world.findByName", inputs: ["name": .string("CombatTests.Victim")]),
                    node("d", "combat.applyDamage", inputs: ["amount": .double(40), "type": .string("slash")])],
            links: [VisualScriptLink(from: "s.out", to: "d.in"), VisualScriptLink(from: "v.entity", to: "d.entity")])
        world.add(VisualScript(graph: "CombatTests.victim"), to: victim)
        world.add(VisualScript(graph: "CombatTests.striker"), to: attacker)
        step(world, 3)
        #expect(world.get(Health.self, for: victim)?.dead == true, "\(lines)")
        #expect(lines.contains { $0.contains("40") }, "\(lines)")
        #expect(lines.contains { $0.hasSuffix("died") }, "\(lines)")
    }
}

private extension Animator {
    func withHitboxes(_ tracks: [HitboxTrack]) -> Animator {
        var copy = self
        copy.hitboxes = tracks
        return copy
    }
}

private extension Data {
    var string: String { String(decoding: self, as: UTF8.self) }
}
