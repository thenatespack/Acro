#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// Installs the gameplay systems a host runs while playing: interaction (InteractionSystem.swift),
// combat (Combat.swift) and game feel (GameFeel.swift). The editor's play mode and
// `ScenePlayback` (GameRunner, exported games) add them; demos and game code can too.

/// The gameplay systems of one world (`World.gameplay`).
@MainActor
public final class GameplaySystems {
    public let combat: CombatSystem
    public let interaction: InteractionSystem
    public let feel: GameFeel

    init(combat: CombatSystem, interaction: InteractionSystem, feel: GameFeel) {
        self.combat = combat
        self.interaction = interaction
        self.feel = feel
    }

    /// The system names `addGameplay` adds.
    public static let systemNames = [InteractionSystem.systemName, InteractionSystem.devicesSystemName, CombatSystem.systemName, GameFeel.systemName]
}

/// Which gameplay systems each `World` runs (weak).
@MainActor
enum GameplayAttachment {
    private struct Entry {
        weak var world: World?
        let systems: GameplaySystems
    }

    private static var entries: [ObjectIdentifier: Entry] = [:]

    static func set(_ systems: GameplaySystems?, for world: World) {
        entries = entries.filter { $0.value.world != nil }
        entries[ObjectIdentifier(world)] = systems.map { Entry(world: world, systems: $0) }
    }

    static func systems(for world: World) -> GameplaySystems? {
        guard let entry = entries[ObjectIdentifier(world)], entry.world === world else { return nil }
        return entry.systems
    }
}

extension World {
    /// Adds the gameplay systems: "interaction" and "interaction.devices" (`.update`: focus,
    /// prompts and uses from `input`; doors, levers and lids swinging), "combat" and "gameFeel"
    /// (`.lateUpdate`, after animation and ragdoll poses: hitboxes against hurtboxes, hit
    /// effects, camera shake). `assets` resolves effect VFX and sounds, `physics` gives impact
    /// effects of physics materials and knockback on rigid bodies. Replaces systems added before.
    @discardableResult
    public func addGameplay(input: Input?, assets: @escaping () -> AssetDatabase? = { nil },
                            physics: @escaping () -> PhysicsWorld? = { nil }) -> GameplaySystems {
        removeGameplay()
        GameplayComponents.register()
        let feel = GameFeel()
        let systems = GameplaySystems(combat: CombatSystem(feel: feel, assets: assets, physics: physics, startingAfter: combat.lastSequence),
                                      interaction: InteractionSystem(input: input), feel: feel)
        addSystem(InteractionSystem.systemName, stage: .update) { world in systems.interaction.update(world) }
        addSystem(InteractionSystem.devicesSystemName, stage: .update) { world in systems.interaction.updateDevices(world) }
        addSystem(CombatSystem.systemName, stage: .lateUpdate) { world in systems.combat.update(world) }
        addSystem(GameFeel.systemName, stage: .lateUpdate) { world in systems.feel.update(world) }
        GameplayAttachment.set(systems, for: self)
        return systems
    }

    /// Removes the gameplay systems, restoring highlights, the shaken camera and the time scale.
    public func removeGameplay() {
        if let systems = gameplay {
            systems.interaction.reset(self)
            systems.feel.reset(self)
        }
        for name in GameplaySystems.systemNames { removeSystem(named: name) }
        GameplayAttachment.set(nil, for: self)
        resetTimeScale()
    }

    /// The gameplay systems `addGameplay` installed, if any.
    public var gameplay: GameplaySystems? { GameplayAttachment.systems(for: self) }

    /// The interactable `interactor` focuses now (the first `Interactor`'s when nil), for hosts
    /// that outline it.
    public func interactionFocus(of interactor: Entity? = nil) -> Entity? {
        guard let interaction = gameplay?.interaction else { return nil }
        if let interactor { return interaction.focus[interactor] }
        return interaction.focus.sorted { $0.key.index < $1.key.index }.first?.value
    }
}
