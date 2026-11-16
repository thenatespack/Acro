import Foundation
import EngineCore
import EngineScene

/// Gives an entity (an NPC, a sign, a quest giver) a conversation from a `.dialogue` file.
/// While the game plays, the dialogue system (`World.addDialogueSystem`) keeps a
/// `DialogueRunner` for it, starts it when `autoStart` is set, follows hot reloads of the file
/// and shows the active conversation in the `DialogueDirector`'s presenter (the default
/// `DialogueBox` widget, or a UI of your own).
///
/// Game code:
///
/// ```swift
/// world.dialogues?.start(npc)                          // talk to this NPC
/// world.dialogue(for: npc)?.setVariable("gold", 25)    // read / set its variables
/// world.dialogues?.setVariable("questDone", true)      // or every dialogue's at once
/// world.dialogues?.onEvent { entity, event in          // events from `event` nodes
///     if event.name == "openGate" { ... }
/// }
/// ```
public struct DialoguePlayer: Component, Codable, Equatable, Sendable {
    public static let componentName = "DialoguePlayer"
    public static var fieldHints: [String: FieldHints] {
        ["dialogue": FieldHints(tooltip: "A .dialogue file: a path under Assets/ or asset:<id>"),
         "startNode": FieldHints(tooltip: "The node to start at (empty: the dialogue's start)"),
         "autoStart": FieldHints(tooltip: "Start the conversation when play begins")]
    }

    /// The `.dialogue` file: a path under `Assets/` or "asset:<id>".
    public var dialogue: String
    /// The node to start at ("" uses the dialogue's start).
    public var startNode: String
    /// Starts when the game starts playing.
    public var autoStart: Bool

    public init(dialogue: String = "", startNode: String = "", autoStart: Bool = false) {
        self.dialogue = dialogue
        self.startNode = startNode
        self.autoStart = autoStart
    }

    private enum CodingKeys: String, CodingKey { case dialogue, startNode, autoStart }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(dialogue: try c.decodeIfPresent(String.self, forKey: .dialogue) ?? "",
                  startNode: try c.decodeIfPresent(String.self, forKey: .startNode) ?? "",
                  autoStart: try c.decodeIfPresent(Bool.self, forKey: .autoStart) ?? false)
    }
}

/// Shows a conversation. The default is the `DialogueBox` widget; a `.ui` layout or a game's
/// own UI can conform instead. `present` is called with the runner whenever its state changes
/// (nil when nothing is shown); the presenter answers with `runner.advance()` and
/// `runner.choose(_:)`.
@MainActor
public protocol DialoguePresenter: AnyObject {
    func present(_ runner: DialogueRunner?)
}

/// The runtime side of `DialoguePlayer`s in one world: a `DialogueRunner` per entity, variables
/// shared between them, event listeners, and the presenter that shows the active conversation.
/// Made by `World.addDialogueSystem(assets:)`; reach it with `world.dialogues`.
@MainActor
public final class DialogueDirector {
    public static let systemName = "dialogue.players"

    /// Where dialogue files load from.
    public var assets: () -> AssetDatabase?
    /// Shows the active conversation (set it to a `DialogueBox` added to your UI).
    public var presenter: (any DialoguePresenter)? {
        didSet {
            oldValue?.present(nil)
            presenter?.present(activeRunner)
        }
    }
    /// Variables every dialogue starts with and writes back to, so state carries between
    /// conversations and NPCs (a dialogue's declared defaults apply only to names not here).
    public private(set) var variables: [String: DialogueValue] = [:]
    /// The entity whose conversation is shown (the last one started that is still going).
    public private(set) var activeEntity: Entity?

    private weak var world: World?
    private var players: [Entity: Player] = [:]
    private var eventListeners: [Int: (Entity, DialogueEvent) -> Void] = [:]
    private var nextListener = 0

    private struct Player {
        var runner: DialogueRunner
        var source: String
        var asset: AssetID?
        var revision: Int
        var autoStarted: Bool
    }

    private static var byWorld: [ObjectIdentifier: Weak] = [:]
    private struct Weak { weak var director: DialogueDirector? }

    init(world: World, assets: @escaping () -> AssetDatabase?) {
        self.world = world
        self.assets = assets
    }

    static func director(for world: World) -> DialogueDirector? { byWorld[ObjectIdentifier(world)]?.director }

    static func set(_ director: DialogueDirector?, for world: World) {
        byWorld = byWorld.filter { $0.value.director != nil }
        byWorld[ObjectIdentifier(world)] = director.map { Weak(director: $0) }
    }

    /// The active conversation's runner.
    public var activeRunner: DialogueRunner? { activeEntity.flatMap { players[$0]?.runner } }

    /// The runner of `entity`'s `DialoguePlayer` (loaded now if needed); nil when it has none or
    /// its dialogue can't be read.
    public func runner(for entity: Entity) -> DialogueRunner? {
        sync(entity)
        return players[entity]?.runner
    }

    /// Starts `entity`'s conversation (at `node`, default the component's `startNode` or the
    /// dialogue's start) and makes it the one shown. Returns its runner.
    @discardableResult
    public func start(_ entity: Entity, at node: String? = nil) -> DialogueRunner? {
        guard let runner = runner(for: entity) else { return nil }
        let component = world?.get(DialoguePlayer.self, for: entity)
        activeEntity = entity
        runner.start(at: node ?? component.flatMap { $0.startNode.isEmpty ? nil : $0.startNode })
        presenter?.present(runner.isActive ? runner : nil)
        return runner
    }

    /// Stops `entity`'s conversation (default: the active one).
    public func stop(_ entity: Entity? = nil) {
        guard let entity = entity ?? activeEntity, let runner = players[entity]?.runner else { return }
        runner.stop()
    }

    /// Sets a variable in the shared store and in every loaded dialogue.
    public func setVariable(_ name: String, _ value: DialogueValue) {
        variables[name] = value
        for player in players.values { player.runner.setVariable(name, value) }
    }

    public func variable(_ name: String) -> DialogueValue? { variables[name] }

    /// Calls `handler` when any dialogue reaches an `event` node, with the entity it belongs to.
    @discardableResult
    public func onEvent(_ handler: @escaping (Entity, DialogueEvent) -> Void) -> DialogueListener {
        nextListener += 1
        eventListeners[nextListener] = handler
        return DialogueListener(id: nextListener)
    }

    public func removeListener(_ listener: DialogueListener) { eventListeners[listener.id] = nil }

    /// The system's per-frame work: loads runners for new `DialoguePlayer`s, follows file
    /// changes, auto-starts, and drops runners of removed entities.
    public func update() {
        guard let world else { return }
        var seen = Set<Entity>()
        var autoStart: [Entity] = []
        world.query(DialoguePlayer.self) { entity, component in
            seen.insert(entity)
            if component.autoStart, players[entity]?.autoStarted != true { autoStart.append(entity) }
        }
        for entity in seen { sync(entity) }
        for entity in players.keys where !seen.contains(entity) {
            if activeEntity == entity { activeEntity = nil; presenter?.present(nil) }
            players[entity] = nil
        }
        for entity in autoStart where players[entity] != nil {
            players[entity]?.autoStarted = true
            start(entity)
        }
    }

    /// Loads or reloads `entity`'s runner to match its component and the file.
    private func sync(_ entity: Entity) {
        guard let world, let component = world.get(DialoguePlayer.self, for: entity), let assets = assets() else { return }
        let id = assets.assetID(forTableValue: component.dialogue)
        if let id, assets.pack == nil { _ = assets.asset(id) }  // reimports when out of date
        let revision = id.map { assets.pack == nil ? assets.revision(of: $0) : 0 } ?? -1
        if let player = players[entity], player.source == component.dialogue, player.asset == id {
            guard player.revision != revision, let id, let fresh = assets.dialogueContents(of: id) else { return }
            players[entity]?.revision = revision
            player.runner.replace(fresh)
            return
        }
        guard let id, let dialogue = assets.dialogueContents(of: id) else {
            players[entity] = nil
            return
        }
        let runner = DialogueRunner(dialogue)
        for (name, value) in variables where dialogue.variable(name) != nil { runner.setVariable(name, value) }
        runner.onVariableChange { [weak self] name, value in self?.variables[name] = value }
        runner.onEvent { [weak self] event in
            guard let self else { return }
            for handler in eventListeners.values { handler(entity, event) }
        }
        runner.onStateChange { [weak self, weak runner] state in
            guard let self, activeEntity == entity else { return }
            switch state {
            case .line, .choices: presenter?.present(runner)
            case .idle, .finished:
                activeEntity = nil
                presenter?.present(nil)
            }
        }
        let autoStarted = players[entity]?.autoStarted ?? false
        players[entity] = Player(runner: runner, source: component.dialogue, asset: id, revision: revision, autoStarted: autoStarted)
    }
}

extension World {
    /// Adds the system that runs `DialoguePlayer` components (see `DialogueDirector`), loading
    /// dialogue files from `assets`. Returns the director (also `world.dialogues`). Calling it
    /// again replaces the previous one.
    @MainActor @discardableResult
    public func addDialogueSystem(assets: @escaping () -> AssetDatabase?) -> DialogueDirector {
        ComponentRegistry.register(DialoguePlayer.self)
        removeDialogueSystem()
        let director = DialogueDirector(world: self, assets: assets)
        DialogueDirector.set(director, for: self)
        addSystem(DialogueDirector.systemName, stage: .update) { _ in director.update() }
        return director
    }

    /// Removes the dialogue system (hiding its conversation).
    @MainActor public func removeDialogueSystem() {
        if let old = DialogueDirector.director(for: self) { old.presenter = nil }
        DialogueDirector.set(nil, for: self)
        removeSystem(named: DialogueDirector.systemName)
    }

    /// The dialogue system, when one was added.
    @MainActor public var dialogues: DialogueDirector? { DialogueDirector.director(for: self) }

    /// The runner of `entity`'s `DialoguePlayer`.
    @MainActor public func dialogue(for entity: Entity) -> DialogueRunner? { dialogues?.runner(for: entity) }
}
