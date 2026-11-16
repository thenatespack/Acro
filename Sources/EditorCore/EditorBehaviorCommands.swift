import Engine
import Foundation

/// The behavior tree tools: `behavior.new`, `behavior.get`, `behavior.set`, `behavior.edit`,
/// `behavior.assign`, `behavior.debug`, `behavior.navigation`, `behavior.open`.
@MainActor
public enum EditorBehaviorCommands {
    public static let all: [any EditorCommand.Type] = [
        BehaviorNewCommand.self,
        BehaviorGetCommand.self,
        BehaviorSetCommand.self,
        BehaviorEditCommand.self,
        BehaviorAssignCommand.self,
        BehaviorDebugCommand.self,
        BehaviorNavigationCommand.self,
        BehaviorOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A behavior tree (.behavior) is NPC AI as nodes: `nodes` is a flat list of {id, type, name?, children? [ids], \
        ...parameters}, `root` the root id (default: the first node nobody lists as a child), `blackboard` starting shared \
        values ({"health": 100, "home": [0, 0, 0]}), `speed` (m/s, default 3), `turnSpeed` (rad/s, 10) and `tickRate` (per \
        second, 0 = every frame). Types: composites sequence (memory: resume at running child, default true), selector \
        (re-checks from the first child every tick), parallel (succeedOn all|one, failOn one|all); decorators (one child) \
        invert, repeat (count, 0 = forever; untilFailure), cooldown (seconds), succeed; conditions canSeeTarget (range, fov \
        degrees about -Z, lineOfSight, eyeHeight), withinRange (range), healthBelow (key=health, value), checkBlackboard (key, \
        op == != < <= > >= set unset, value); actions moveTo (position [x,y,z] or key), patrol (points [[x,y,z]...], relative, \
        loop, wait), chase (stopDistance, giveUpDistance), flee (safeDistance), attack (range, damage, cooldown, key, animation), \
        wait (seconds, randomness), playAnimation (animation, fade, duration), setBlackboard (key, value), custom (leaf: a name \
        game code registered with BehaviorTreeLeaves.register). Move nodes take `speed`; target nodes take `target` (a \
        blackboard key, default "target": an entity name, else the BehaviorTreeRunner's target entity). Problems are reported \
        in `warnings`. An entity runs a tree with a BehaviorTreeRunner component (behavior.assign) while playing.
        """
}

extension EditorSession {
    /// Writes a behavior tree to "`name`.behavior" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createBehaviorAsset(in folder: String, name: String = "New Behavior", tree: BehaviorTree = .preset(.empty)) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Behavior Tree") else {
            log.error("New Behavior Tree: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".behavior"))
        do {
            let id = try assets.createBehaviorTree(tree, at: path)
            log.info("Created behavior tree \(path)")
            return id
        } catch {
            log.error("New Behavior Tree failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.behavior` file.
    public func isBehaviorFile(_ id: AssetID) -> Bool {
        assets?.isBehaviorTree(id) ?? false
    }

    /// Replaces the contents of the behavior tree `id` as one undo step (undo writes the old
    /// contents back). Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyBehavior(_ tree: BehaviorTree, to id: AssetID, label: String = "Edit Behavior Tree") -> [String]? {
        guard let assets, let old = assets.behaviorTreeContents(of: id) else {
            log.error("\(label): \(id) isn't a readable .behavior file")
            return nil
        }
        guard old != tree else { return [] }
        let command = BehaviorFileEditCommand(asset: id, old: old, new: tree, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// The behavior tree named by `target` and its contents.
    func resolveBehavior(_ target: some BehaviorTarget, _ title: String) throws -> (AssetID, BehaviorTree) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isBehaviorFile(id), let tree = assets?.behaviorTreeContents(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .behavior file")
        }
        return (id, tree)
    }

    /// The custom leaves game code registered (so unknown ones are reported).
    var behaviorWarnings: (BehaviorTree) -> [String] {
        { tree in tree.validate(customLeaves: BehaviorTreeLeaves.names.isEmpty ? nil : Set(BehaviorTreeLeaves.names)).map(\.description) }
    }
}

/// Makes behavior tree edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct BehaviorFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: BehaviorTree
    public let new: BehaviorTree
    /// The last write's import warnings.
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: BehaviorTree, new: BehaviorTree, in database: AssetDatabase, label: String = "Edit Behavior Tree") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ tree: BehaviorTree) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeBehaviorTree(tree, to: asset)
    }
}

/// Arguments naming a `.behavior` file.
public protocol BehaviorTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

/// What the editing tools return.
public struct BehaviorResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    public var root: String
    /// The tree as an indented outline ("selector root", "  sequence fight", …).
    public var outline: [String]
    public var nodeCount: Int
    public var blackboard: [String]
    public var warnings: [String]
}

extension BehaviorResult {
    @MainActor init(_ id: AssetID, _ tree: BehaviorTree, in session: EditorSession) {
        let record = session.assets?.record(id)
        self.init(asset: id, path: record?.path ?? "", root: tree.rootID ?? "",
                  outline: tree.outline().map { item in
                      let node = tree.node(item.id)
                      return String(repeating: "  ", count: item.depth) + "\(node?.type ?? "?") \(item.id)" + (node.map { $0.name.isEmpty ? "" : " (\($0.name))" } ?? "")
                  },
                  nodeCount: tree.nodes.count, blackboard: tree.blackboard.keys.sorted(),
                  warnings: session.behaviorWarnings(tree) + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum BehaviorNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Behavior" (the file gets ".behavior").
        public var name: String?
        /// empty (default), patrol, guard, chaser or coward.
        public var preset: BehaviorPreset?
        public init(folder: String? = nil, name: String? = nil, preset: BehaviorPreset? = nil) {
            self.folder = folder
            self.name = name
            self.preset = preset
        }
    }

    public static let id: CommandID = "behavior.new"
    public static let title = "New Behavior Tree"
    public static let doc = "Writes a .behavior file in `folder` (default: the Assets root) from a `preset` (empty: a selector with a wait; patrol: walks a square; guard: patrols, chases and attacks the target it sees, flees when hurt; chaser; coward) and imports it. Returns the outline and warnings. Change it with behavior.edit; run it on an entity with behavior.assign. " + EditorBehaviorCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> BehaviorResult {
        let preset = arguments.preset ?? .empty
        let tree = BehaviorTree.preset(preset)
        let name = arguments.name ?? (preset == .empty ? "New Behavior" : preset.rawValue.capitalized)
        let id = try session.commands.require(session.createBehaviorAsset(in: arguments.folder ?? "", name: name, tree: tree), title)
        return BehaviorResult(id, tree, in: session)
    }
}

public enum BehaviorGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, BehaviorTarget {
        /// The .behavior file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var tree: BehaviorTree
        public var outline: [String]
        public var warnings: [String]
    }

    public static let id: CommandID = "behavior.get"
    public static let title = "Get Behavior Tree"
    public static let doc = "Reads a .behavior file: its nodes, blackboard and settings as stored, an indented outline from the root, and its problems."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, tree) = try session.resolveBehavior(arguments, title)
        let summary = BehaviorResult(id, tree, in: session)
        return Result(asset: id, path: summary.path, tree: tree, outline: summary.outline, warnings: summary.warnings)
    }
}

public enum BehaviorSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, BehaviorTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var tree: BehaviorTree
        public init(asset: AssetReference? = nil, path: String? = nil, tree: BehaviorTree) {
            self.asset = asset
            self.path = path
            self.tree = tree
        }
    }

    public static let id: CommandID = "behavior.set"
    public static let title = "Set Behavior Tree"
    public static let doc = "Replaces a .behavior file's whole contents and reimports it (NPCs running it while playing switch to it). Undoable. For a few changes, behavior.edit is shorter. " + EditorBehaviorCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> BehaviorResult {
        let (id, _) = try session.resolveBehavior(arguments, title)
        _ = try session.commands.require(session.applyBehavior(arguments.tree, to: id, label: title), title)
        return BehaviorResult(id, arguments.tree, in: session)
    }
}

public enum BehaviorEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, BehaviorTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Node ids to delete (their links go; their children stay, unparented).
        public var removeNodes: [String]?
        /// Nodes to add: {id?, type, name?, children?, ...parameters}. An empty or taken id gets a fresh one (children naming added nodes follow).
        public var addNodes: [BehaviorNode]?
        /// Node id → fields to change: type, name, children, id (rename), or parameters (null resets one to its default).
        public var updateNodes: [String: JSONValue]?
        /// Links to remove: {parent, child}.
        public var disconnect: [BehaviorConnection]?
        /// Links to add: {parent, child, index?} puts child under parent (at index, default last), moving it from any other parent.
        public var connect: [BehaviorConnection]?
        /// The new root id.
        public var root: String?
        /// Blackboard keys to set (null removes one).
        public var blackboard: [String: JSONValue]?
        public var speed: Double?
        public var turnSpeed: Double?
        public var tickRate: Double?
        /// A preset to start from instead of the file's contents (the other changes apply on top).
        public var preset: BehaviorPreset?
        public init(asset: AssetReference? = nil, path: String? = nil, removeNodes: [String]? = nil, addNodes: [BehaviorNode]? = nil,
                    updateNodes: [String: JSONValue]? = nil, disconnect: [BehaviorConnection]? = nil, connect: [BehaviorConnection]? = nil,
                    root: String? = nil, blackboard: [String: JSONValue]? = nil, speed: Double? = nil, turnSpeed: Double? = nil,
                    tickRate: Double? = nil, preset: BehaviorPreset? = nil) {
            self.asset = asset
            self.path = path
            self.removeNodes = removeNodes
            self.addNodes = addNodes
            self.updateNodes = updateNodes
            self.disconnect = disconnect
            self.connect = connect
            self.root = root
            self.blackboard = blackboard
            self.speed = speed
            self.turnSpeed = turnSpeed
            self.tickRate = tickRate
            self.preset = preset
        }

        var edit: BehaviorTreeEdit {
            BehaviorTreeEdit(removeNodes: removeNodes, addNodes: addNodes, updateNodes: updateNodes, disconnect: disconnect,
                             connect: connect, root: root, blackboard: blackboard, speed: speed, turnSpeed: turnSpeed, tickRate: tickRate)
        }
    }

    public static let id: CommandID = "behavior.edit"
    public static let title = "Edit Behavior Tree"
    public static let doc = "Changes part of a .behavior file in one undoable step, in this order: preset (replace everything first), removeNodes, addNodes, updateNodes, disconnect, connect, root, blackboard, speed / turnSpeed / tickRate. NPCs running it while playing pick up the change. Returns the outline and warnings. Example: {\"addNodes\": [{\"id\": \"low\", \"type\": \"healthBelow\", \"value\": 20}, {\"id\": \"run\", \"type\": \"flee\"}, {\"id\": \"escape\", \"type\": \"sequence\", \"children\": [\"low\", \"run\"]}], \"connect\": [{\"parent\": \"root\", \"child\": \"escape\", \"index\": 0}]}. " + EditorBehaviorCommands.formatDoc
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> BehaviorResult {
        let (id, original) = try session.resolveBehavior(arguments, title)
        let tree: BehaviorTree
        do { tree = try (arguments.preset.map(BehaviorTree.preset) ?? original).applying(arguments.edit) } catch {
            throw CommandError.failed("\(title): \(error)")
        }
        _ = try session.commands.require(session.applyBehavior(tree, to: id, label: title), title)
        return BehaviorResult(id, tree, in: session)
    }
}

public enum BehaviorAssignCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, BehaviorTarget {
        /// The entity that runs the tree (gets a BehaviorTreeRunner if it has none).
        public var entity: EntityID
        public var asset: AssetReference?
        public var path: String?
        /// The entity target-based nodes aim at (can see, chase, attack…) unless the blackboard names one.
        public var target: EntityID?
        /// Walking speed for this entity (0: the tree's).
        public var speed: Float?
        /// Starting blackboard values for this entity, as text: {"health": "50", "home": "0, 0, 4"}.
        public var blackboard: [String: String]?
        public init(entity: EntityID, asset: AssetReference? = nil, path: String? = nil, target: EntityID? = nil, speed: Float? = nil,
                    blackboard: [String: String]? = nil) {
            self.entity = entity
            self.asset = asset
            self.path = path
            self.target = target
            self.speed = speed
            self.blackboard = blackboard
        }
    }

    public static let id: CommandID = "behavior.assign"
    public static let title = "Assign Behavior Tree"
    public static let doc = "Makes an entity run a .behavior tree while playing: adds or updates its BehaviorTreeRunner component (tree, optional target entity, speed and blackboard overrides) as one undoable step. Give it a CharacterController or dynamic RigidBody to move with physics; otherwise its Transform is moved."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveBehavior(arguments, title)
        let world = session.world
        let entity = try world.require(arguments.entity)
        var runner = world.get(BehaviorTreeRunner.self, for: entity) ?? BehaviorTreeRunner()
        runner.tree = AssetReference(id).description
        if let target = arguments.target {
            _ = try world.require(target)
            runner.target = EntityRef(target)
        }
        if let speed = arguments.speed { runner.speed = speed }
        if let blackboard = arguments.blackboard {
            for (key, value) in blackboard.sorted(by: { $0.key < $1.key }) {
                if let i = runner.blackboard.firstIndex(where: { $0.key == key }) { runner.blackboard[i].value = value }
                else { runner.blackboard.append(BehaviorBlackboardEntry(key: key, value: value)) }
            }
        }
        let command = try AddComponentCommand(entity, runner, in: world, label: title)
        try session.commands.check(session.perform(command), title)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}

public enum BehaviorDebugCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// The entity (default: the selected one, else the first entity running a tree).
        public var entity: EntityID?
        public init(entity: EntityID? = nil) { self.entity = entity }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entity: EntityID?
        public var tree: String
        public var playing: Bool
        /// What the root returned on the last tick ("" before the first).
        public var status: String
        /// Running nodes from the root down.
        public var runningPath: [String]
        /// Node id → success, failure or running, for the nodes ticked last time.
        public var nodes: [String: String]
        /// The blackboard, as text.
        public var blackboard: [String: String]
        public var ticks: Int
        public var problems: [String]
    }

    public static let id: CommandID = "behavior.debug"
    public static let title = "Debug Behavior Tree"
    public static let doc = "While playing: an entity's behavior tree state from the last tick (root status, the running path, each ticked node's status, the blackboard, problems such as a missing custom leaf). The Behavior Tree tab highlights the same path."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        let entity: Entity
        if let id = arguments.entity {
            entity = try world.require(id)
        } else if let selected = session.selection.primaryEntity(in: world), world.has(BehaviorTreeRunner.self, for: selected) {
            entity = selected
        } else {
            var first: Entity?
            world.query(BehaviorTreeRunner.self) { e, _ in if first == nil { first = e } }
            guard let first else { throw CommandError.failed("\(title): no entity has a BehaviorTreeRunner") }
            entity = first
        }
        let runner = world.get(BehaviorTreeRunner.self, for: entity)
        let state = world.get(BehaviorTreeState.self, for: entity)
        var nodes: [String: String] = [:]
        for (id, status) in state?.statusByID ?? [:] { nodes[id] = status.rawValue }
        var blackboard: [String: String] = [:]
        for (key, value) in state?.blackboard ?? [:] { blackboard[key] = value.description }
        return Result(entity: world.id(of: entity), tree: runner?.tree ?? "", playing: session.isPlaying,
                      status: state?.rootStatus?.rawValue ?? "", runningPath: state?.runningPath ?? [], nodes: nodes,
                      blackboard: blackboard, ticks: state?.tickCount ?? 0, problems: state?.problems ?? [])
    }
}

public enum BehaviorNavigationCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// Bake again even if the world has a grid (default: bake only when it has none).
        public var rebake: Bool?
        /// Find a path between these world points ([x, y, z]).
        public var from: Vec3?
        public var to: Vec3?
        /// Path to the reachable point nearest `to` when `to` can't be reached.
        public var partial: Bool?
        public init(rebake: Bool? = nil, from: Vec3? = nil, to: Vec3? = nil, partial: Bool? = nil) {
            self.rebake = rebake
            self.from = from
            self.to = to
            self.partial = partial
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Whether the world has a grid (false: no colliders to bake from).
        public var hasGrid: Bool
        public var baked: Bool
        public var cellSize: Float
        /// Cells along x and z.
        public var width: Int
        public var depth: Int
        public var walkableCells: Int
        /// Separate walkable areas (cells in different ones can't reach each other).
        public var areas: Int
        public var boundsMin: Vec3?
        public var boundsMax: Vec3?
        /// The path from `from` to `to` (empty when there is none or none was asked for).
        public var path: [Vec3]
        public var pathLength: Float
        public var pathFound: Bool
    }

    public static let id: CommandID = "behavior.navigation"
    public static let title = "Behavior Navigation"
    public static let doc = "The navigation grid behavior trees walk on (moveTo, patrol, chase and flee follow A* paths on it, straight-line steering where there is none): bakes it from the static colliders of the current world (the play world while playing) if it has none or `rebake`, reports its size and walkable areas, and with `from` and `to` returns the path between them. A NavigationArea component sets the baked box and the agent's radius, height, step and slope; without one the bake covers the static colliders around the agents. Game code: `world.bakeNavigation()`, `world.findPath(from:to:)`."
    public static let isReadOnly = true
    public static func isAvailable(in session: EditorSession) -> Bool { true }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let world = session.world
        var baked = false
        if arguments.rebake == true || world.navigation == nil {
            baked = world.bakeNavigation() != nil
        }
        guard let grid = world.navigation else {
            return Result(hasGrid: false, baked: false, cellSize: 0, width: 0, depth: 0, walkableCells: 0, areas: 0,
                          path: [], pathLength: 0, pathFound: false)
        }
        var path: [Vec3] = []
        if let from = arguments.from, let to = arguments.to {
            path = grid.findPath(from: from, to: to, partial: arguments.partial ?? false) ?? []
        } else if (arguments.from == nil) != (arguments.to == nil) {
            throw CommandError.failed("\(title): give both `from` and `to` for a path")
        }
        let bounds = grid.bounds
        return Result(hasGrid: true, baked: baked, cellSize: grid.cellSize, width: grid.width, depth: grid.depth,
                      walkableCells: grid.walkableCount, areas: grid.regionCount, boundsMin: bounds.min, boundsMax: bounds.max,
                      path: path, pathLength: NavigationGrid.length(of: path), pathFound: !path.isEmpty)
    }
}

public enum BehaviorOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, BehaviorTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "behavior.open"
    public static let title = "Open in Behavior Tree Builder"
    public static let doc = "Opens a .behavior file in the editor's Behavior Tree tab (the tree as an outline with a node form, presets and the blackboard; while playing it highlights the running path of the selected entity) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"behaviorTree\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveBehavior(arguments, title)
        session.openBehavior = id
        session.onOpenBehavior?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
