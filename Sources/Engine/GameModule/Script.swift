import Foundation
import EngineAssets
import EngineAudio
import EngineBackends
import EngineCore
import EngineGraphics
import EngineNet
import EnginePhysics
import EngineRendering
import EngineScene
import EngineText
import EngineUI

/// A component with its own per-frame code: the simplest way to give entities behavior.
///
/// Declare the fields the inspector edits and an `update`, then register it with
/// `game.script(Spinner.self)` in the module's entry point. While the game plays, `update` runs
/// once per frame for every entity that has the component; changes to `self` are saved.
///
/// ```swift
/// public struct Spinner: Script, Equatable, Sendable {
///     public static let componentName = "Spinner"
///     public var speed: Float = 1
///
///     public init() {}
///
///     public mutating func update(_ context: ScriptContext) {
///         context.transform.rotation = Quat(angle: speed * context.dt, axis: Vec3(0, 1, 0)) * context.transform.rotation
///     }
/// }
/// ```
///
/// A script is an ordinary component and system underneath (`GameModule.component` plus a
/// `GameModule.system` named `script.<componentName>`); write those directly when a system has
/// to work over several component types at once or needs a specific order.
public protocol Script: Component {
    /// The component as Add Component creates it.
    init()

    /// Runs every frame while the game plays, once per entity that has this script. Read and
    /// change the entity through `context` (its transform, other components, input, time).
    /// Changing this same component through `context.world` is overwritten when `update`
    /// returns: change `self` instead.
    @MainActor mutating func update(_ context: ScriptContext)
}

/// What a `Script`'s `update` gets: its entity, the world, the frame's time and input.
@MainActor
public struct ScriptContext {
    /// The entity this script is on.
    public let entity: Entity
    /// The world the entity lives in.
    public let world: World
    /// The host's game services (input, log, scene switching).
    public let game: GameContext
    /// The script's component name, used to label log lines.
    public let scriptName: String

    public init(entity: Entity, world: World, game: GameContext, scriptName: String) {
        self.entity = entity
        self.world = world
        self.game = game
        self.scriptName = scriptName
    }

    /// Seconds since the last frame.
    public var dt: Float { world.time.delta }
    /// Seconds since play started.
    public var time: Float { Float(world.time.elapsed) }
    /// The game's input (keys, mouse, gamepads).
    public var input: Input { game.input }

    /// The entity's transform. Setting it adds one when the entity has none; reading it from an
    /// entity without one gives the identity transform.
    public var transform: Transform {
        get { world.get(Transform.self, for: entity) ?? Transform() }
        nonmutating set {
            if world.modify(Transform.self, for: entity, { $0 = newValue }) == nil { world.add(newValue, to: entity) }
        }
    }

    /// Another component of this entity, or nil when it has none.
    public func get<C: Component>(_ type: C.Type) -> C? { world.get(type, for: entity) }

    /// Edits another component of this entity in place; returns nil when it has none.
    @discardableResult
    public func modify<C: Component, R>(_ type: C.Type, _ body: (inout C) throws -> R) rethrows -> R? {
        try world.modify(type, for: entity, body)
    }

    /// Writes a line to the editor's console, labeled with the script's name.
    public func log(_ message: String) { game.log("[\(scriptName)] \(message)") }
}

extension GameModule {
    /// Registers a `Script`: its component (created with `init()` by Add Component, with an
    /// optional editor icon, see `icon(_:for:)`) and a system named `script.<componentName>` in
    /// `stage` that calls `update` on each entity that has it.
    public func script<S: Script>(_ type: S.Type, icon: String? = nil, stage: SystemStage = .update) {
        component(type) { S() }
        if let icon { self.icon(icon, for: S.componentName) }
        let name = S.componentName
        system("script.\(name)", stage: stage) { world, game in
            world.queryMutating(S.self) { entity, script in
                script.update(ScriptContext(entity: entity, world: world, game: game, scriptName: name))
            }
        }
    }
}
