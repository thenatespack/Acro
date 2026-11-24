// Footstep, impact and scrape effects from physics materials (PhysicsMaterial.swift): the
// "physics.surfaceEffects" system plays each material's sound (a one-shot `AudioEmitter`
// entity) and spawns its VFX (a prefab) where things touch.
//
// - Impacts: `collisionBegan` events faster than either material's `minImpactSpeed`; the
//   volume grows with the speed (full at four times the threshold).
// - Scrapes: touching contacts sliding faster than `minScrapeSpeed`, at most every
//   `scrapeInterval` seconds per pair.
// - Footsteps: a `CharacterController` walking on the ground, every `stride` meters (its height
//   times 0.42 by default), and when it lands. The pair is the character's own surface (a
//   `PhysicsSurface` on it, else "default") and the ground's material under its feet.
// The pair's effect comes from `PhysicsMaterialLibrary.effect`. Spawned entities are named
// "Footstep", "Impact" or "Scrape" and removed after `lifetime` seconds (sounds when they end).
#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EnginePhysics
import EngineScene

/// One effect the system played (`PhysicsSurfaceEffects.recent`).
public struct SurfaceEffectEvent: Equatable, Sendable {
    public var kind: PhysicsEffectKind
    /// The two materials: the mover's (a character, body A) and the surface's.
    public var materials: [String]
    public var position: Vec3
    public var sound: String?
    public var vfx: String?
    public var volume: Float
    /// The character (footsteps) or the bodies' entities.
    public var entities: [Entity]
}

/// The state of the "physics.surfaceEffects" system (see PhysicsSurfaceEffects.swift).
@MainActor
public final class PhysicsSurfaceEffects {
    public static let systemName = "physics.surfaceEffects"

    public var enabled = true
    /// Meters between footsteps; nil: each character's height × 0.42.
    public var stride: Float?
    /// Seconds between scrape effects of one pair.
    public var scrapeInterval: Float = 0.25
    /// Seconds a spawned VFX lives (sounds go when they end, at the latest after this × 4).
    public var lifetime: Float = 3
    /// What played in the last update (for tests, tools and game code).
    public private(set) var recent: [SurfaceEffectEvent] = []
    /// Every effect played since the system started, by kind.
    public private(set) var counts: [PhysicsEffectKind: Int] = [:]

    let physics: PhysicsWorld
    let assets: () -> AssetDatabase?
    private struct Walker {
        var last: Vec3
        var distance: Float
        var grounded: Bool
    }
    private var walkers: [Entity: Walker] = [:]
    private var scrapes: [UInt64: Float] = [:]
    private var spawned: [(entity: Entity, remaining: Float, sound: Bool)] = []

    init(physics: PhysicsWorld, assets: @escaping () -> AssetDatabase?) {
        self.physics = physics
        self.assets = assets
    }

    func update(_ world: World) {
        recent.removeAll(keepingCapacity: true)
        let dt = world.time.delta
        expire(world, dt)
        guard enabled else { return }
        let library = physics.materials

        // Impacts.
        for event in physics.events where event.kind == .collisionBegan && event.speed > 0 {
            let a = physics.surfaceMaterialName(of: event.bodyA, at: event.point)
            let b = physics.surfaceMaterialName(of: event.bodyB, at: event.point)
            let threshold = max(library.resolved(a).minImpactSpeed ?? PhysicsMaterial.defaultMinImpactSpeed,
                                library.resolved(b).minImpactSpeed ?? PhysicsMaterial.defaultMinImpactSpeed)
            guard event.speed >= threshold, let effect = library.effect(.impact, a, b) else { continue }
            let loudness = min(max(event.speed / max(threshold * 4, 1e-3), 0.25), 1)
            play(.impact, effect, [a, b], at: event.point, loudness: loudness, entities: [event.entityA, event.entityB].compactMap { $0 },
                 in: world)
        }

        // Scrapes.
        for key in scrapes.keys.sorted() {
            scrapes[key]! -= dt
            if scrapes[key]! <= 0 { scrapes[key] = nil }
        }
        for slide in physics.slidingContacts(minSpeed: 0.05) {
            let key = UInt64(slide.bodyA.index) << 32 | UInt64(slide.bodyB.index)
            guard scrapes[key] == nil else { continue }
            let a = physics.surfaceMaterialName(of: slide.bodyA, at: slide.point)
            let b = physics.surfaceMaterialName(of: slide.bodyB, at: slide.point)
            let threshold = max(library.resolved(a).minScrapeSpeed ?? PhysicsMaterial.defaultMinScrapeSpeed,
                                library.resolved(b).minScrapeSpeed ?? PhysicsMaterial.defaultMinScrapeSpeed)
            guard slide.speed >= threshold, let effect = library.effect(.scrape, a, b) else { continue }
            scrapes[key] = scrapeInterval
            let loudness = min(max(slide.speed / max(threshold * 4, 1e-3), 0.25), 1)
            play(.scrape, effect, [a, b], at: slide.point, loudness: loudness, entities: [slide.entityA, slide.entityB].compactMap { $0 },
                 in: world)
        }

        // Footsteps.
        var characters: [(Entity, CharacterController)] = []
        world.query(CharacterController.self) { e, c in characters.append((e, c)) }
        var alive: Set<Entity> = []
        for (entity, controller) in characters {
            guard let feet = world.get(Transform.self, for: entity)?.position else { continue }
            alive.insert(entity)
            let onGround = controller.isGrounded && controller.mode == .walking
            var walker = walkers[entity] ?? Walker(last: feet, distance: 0, grounded: onGround)
            let step = stride ?? controller.height * 0.42
            var due = false
            if onGround {
                walker.distance += length(Vec3(feet.x - walker.last.x, 0, feet.z - walker.last.z))
                if !walker.grounded || walker.distance >= step {
                    due = true
                    walker.distance = 0
                }
            }
            walker.last = feet
            walker.grounded = onGround
            walkers[entity] = walker
            guard due else { continue }
            let own = physics.surface(for: entity, in: world).map { $0.material.isEmpty ? "default" : $0.material } ?? "default"
            let ground = controller.groundBody.map { physics.surfaceMaterialName(of: $0, at: feet) }
                ?? physics.materialUnder(feet, maxDistance: 0.3, filter: QueryFilter(mask: controller.collisionMask,
                                                                       excluding: physics.body(for: entity).map { [$0] } ?? []))?.name ?? "default"
            guard let effect = library.effect(.footstep, own, ground) else { continue }
            play(.footstep, effect, [own, ground], at: feet, loudness: 1, entities: [entity], in: world)
        }
        for entity in walkers.keys where !alive.contains(entity) { walkers[entity] = nil }
    }

    private func play(_ kind: PhysicsEffectKind, _ effect: PhysicsMaterialEffect, _ materials: [String], at position: Vec3, loudness: Float,
                      entities: [Entity], in world: World) {
        let volume = (effect.volume ?? 1) * loudness
        recent.append(SurfaceEffectEvent(kind: kind, materials: materials, position: position, sound: effect.sound, vfx: effect.vfx,
                                         volume: volume, entities: entities))
        counts[kind, default: 0] += 1
        let name = kind.rawValue.prefix(1).uppercased() + kind.rawValue.dropFirst()
        let database = assets()
        if let sound = effect.sound, !sound.isEmpty, let id = database?.assetID(forScriptValue: sound) {
            AudioSystem.registerComponents()
            let emitter = AudioEmitter(clip: AssetReference(id).description, volume: volume, pitch: effect.pitch ?? 1, loop: false, isPlaying: true)
            let e = world.spawn(Transform(position: position), Name(name), emitter)
            spawned.append((e, lifetime * 4, true))
        }
        if let vfx = effect.vfx, !vfx.isEmpty, let database, let id = database.assetID(forScriptValue: vfx) {
            let reference = database.asset(id)?.main.map { AssetReference(id, subAsset: $0) }
                ?? database.references(of: .prefab).first { $0.asset == id }
            if let reference, let prefab = database.prefab(reference) {
                let root = world.spawn(Transform(position: position), Name(name))
                world.instantiate(prefab, under: root)
                spawned.append((root, lifetime, false))
            }
        }
    }

    private func expire(_ world: World, _ dt: Float) {
        guard !spawned.isEmpty else { return }
        var kept: [(entity: Entity, remaining: Float, sound: Bool)] = []
        for var item in spawned where world.isAlive(item.entity) {
            item.remaining -= dt
            let ended = item.sound && world.get(AudioEmitter.self, for: item.entity).map { !$0.isPlaying } == true
            if item.remaining <= 0 || ended {
                world.despawn(item.entity)
            } else {
                kept.append(item)
            }
        }
        spawned = kept
    }
}

extension World {
    /// Plays physics materials' footstep, impact and scrape effects (see
    /// PhysicsSurfaceEffects.swift) and lets `physics` load `.physmat` files from `assets`:
    /// adds the `.update` system "physics.surfaceEffects" after "physics.events". `removePhysics`
    /// removes it too. Hosts call this on play after `addPhysics`.
    @discardableResult
    public func addSurfaceEffects(_ physics: PhysicsWorld, assets: @escaping () -> AssetDatabase?) -> PhysicsSurfaceEffects {
        physics.materials.load(from: assets)
        let effects = PhysicsSurfaceEffects(physics: physics, assets: assets)
        removeSystem(named: PhysicsSurfaceEffects.systemName)
        addSystem(PhysicsSurfaceEffects.systemName, stage: .update, after: "physics.events") { world in effects.update(world) }
        return effects
    }
}
