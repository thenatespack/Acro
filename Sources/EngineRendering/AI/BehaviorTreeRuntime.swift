import Foundation
import EngineAssets
import EngineCore
import EnginePhysics
import EngineScene

// Runs `.behavior` trees on entities while the world's systems run (play mode, built games).
//
// - `BehaviorTreeRunner` (saved with scenes) names the tree, the target entity and per-entity
//   blackboard overrides.
// - `BehaviorTreeState` (not saved) is added by the system: the live blackboard, each node's
//   memory, and the status every node returned on the last tick, which the editor's Behavior
//   Tree tab highlights. Game code reads and writes the blackboard through it (or through
//   `World.blackboardValue` / `setBlackboardValue`) and reads `events` (attacks this frame).
// - `World.addBehaviorTrees(assets:physics:)` adds the "behaviorTrees" system in `.update`:
//   every frame it moves the entities their move / patrol / chase / flee leaves steer, and
//   ticks each tree from the root (every frame, or `tickRate` times a second). A tree that
//   finishes (success or failure) starts over on the next tick. The tree file is re-read when
//   it is reimported, so edits apply while playing.
// - Custom leaves: `BehaviorTreeLeaves.register("openDoor") { leaf in … return .success }`,
//   used by `{"type": "custom", "leaf": "openDoor"}` nodes.
//
// Movement is simple steering on the XZ plane (no navigation mesh): a `CharacterController`
// gets `moveVelocity`, a dynamic `RigidBody` its horizontal velocity, anything else has its
// `Transform.position` moved (for root entities; a parented entity's local position is moved
// as if it were world space). The entity turns to face where it walks (`turnSpeed`).

/// What a node returned on a tick.
public enum BehaviorStatus: String, Codable, Sendable {
    case success, failure, running
}

/// A blackboard value.
public enum BehaviorValue: Equatable, Sendable, CustomStringConvertible {
    case number(Double)
    case bool(Bool)
    case text(String)
    case vector(Vec3)
    case points([Vec3])
    case entity(Entity)

    /// A value from the file's JSON (nil for null and other shapes).
    public init?(json: JSONValue) {
        switch json {
        case .bool(let b): self = .bool(b)
        case .int, .double: self = .number(BehaviorJSON.number(json) ?? 0)
        case .string(let s): self = .text(s)
        case .entity(let e): self = .entity(e)
        case .array:
            if let v = BehaviorJSON.vector(json) { self = .vector(v) }
            else if let p = BehaviorJSON.points(json) { self = .points(p) }
            else { return nil }
        default: return nil
        }
    }

    public var json: JSONValue {
        switch self {
        case .number(let d): .double(d)
        case .bool(let b): .bool(b)
        case .text(let s): .string(s)
        case .vector(let v): BehaviorJSON.vectorValue(v)
        case .points(let p): .array(p.map(BehaviorJSON.vectorValue))
        case .entity(let e): .entity(e)
        }
    }

    public var number: Double? {
        switch self {
        case .number(let d): d
        case .bool(let b): b ? 1 : 0
        case .text(let s): Double(s)
        default: nil
        }
    }

    public var bool: Bool? {
        switch self {
        case .bool(let b): b
        case .number(let d): d != 0
        default: nil
        }
    }

    public var description: String {
        switch self {
        case .number(let d): BehaviorJSON.text(.double(d))
        case .bool(let b): b ? "true" : "false"
        case .text(let s): s
        case .vector(let v): "\(v.x), \(v.y), \(v.z)"
        case .points(let p): "\(p.count) points"
        case .entity(let e): "entity \(e.index)"
        }
    }
}

/// A blackboard value a runner sets for its entity, as text ("100", "true", "1, 0, 2", "Player").
public struct BehaviorBlackboardEntry: Codable, Equatable, Sendable {
    public var key: String
    public var value: String

    public init(key: String = "", value: String = "") {
        self.key = key
        self.value = value
    }
}

/// Runs a `.behavior` tree on its entity while the world's systems run (see the notes at the
/// top of BehaviorTreeRuntime.swift).
public struct BehaviorTreeRunner: Component, Codable, Equatable, Sendable {
    public static let componentName = "BehaviorTreeRunner"
    public static var fieldHints: [String: FieldHints] {
        ["tree": FieldHints(tooltip: "The .behavior asset (asset:<id> or a path under Assets/), or a tree registered with BehaviorTreeLibrary"),
         "target": FieldHints(tooltip: "What target-based leaves (can see, chase, attack…) aim at when the blackboard has no \"target\""),
         "isRunning": FieldHints(displayName: "Running"),
         "speed": FieldHints(range: 0...50, step: 0.1, tooltip: "Walking speed in m/s (0: the tree's)"),
         "blackboard": FieldHints(tooltip: "Starting blackboard values for this entity, over the tree's")]
    }

    public var tree: String
    public var target: EntityRef
    public var isRunning: Bool
    /// Walking speed (0: the tree's `speed`).
    public var speed: Float
    public var blackboard: [BehaviorBlackboardEntry]

    public init(tree: String = "", target: EntityRef = .none, isRunning: Bool = true, speed: Float = 0,
                blackboard: [BehaviorBlackboardEntry] = []) {
        self.tree = tree
        self.target = target
        self.isRunning = isRunning
        self.speed = speed
        self.blackboard = blackboard
    }

    private enum CodingKeys: String, CodingKey { case tree, target, isRunning, speed, blackboard }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tree = try c.decodeIfPresent(String.self, forKey: .tree) ?? ""
        target = try c.decodeIfPresent(EntityRef.self, forKey: .target) ?? .none
        isRunning = try c.decodeIfPresent(Bool.self, forKey: .isRunning) ?? true
        speed = try c.decodeIfPresent(Float.self, forKey: .speed) ?? 0
        blackboard = try c.decodeIfPresent([BehaviorBlackboardEntry].self, forKey: .blackboard) ?? []
    }
}

/// Something a tree did that game code may react to (read `BehaviorTreeState.events`).
public struct BehaviorEvent: Equatable, Sendable {
    /// "attack" for attack hits.
    public var name: String
    /// The node that raised it.
    public var node: String
    public var target: Entity?
    /// The damage, for attacks.
    public var amount: Double
}

/// One node's working memory, reset when the node finishes or is interrupted.
struct BehaviorNodeMemory: Sendable {
    var running = -1
    var count = 0
    var time: Double = 0
    var duration: Double = 0
    var started = false
    var waiting = false
    var results: [BehaviorStatus?] = []
    var scratch: [String: BehaviorValue] = [:]
}

/// Where the entity is walking.
struct BehaviorSteering: Sendable {
    var goal: Vec3
    var entity: Entity?
    var away = false
    var speed: Float
    var stopDistance: Float
}

/// The live state of an entity's tree: blackboard, node memory and the last tick's statuses.
/// Added and kept by the behavior tree system; not saved with scenes.
public struct BehaviorTreeState: Component, Sendable {
    public static let componentName = "BehaviorTreeState"
    public static var isSerialized: Bool { false }
    public static var fieldHints: [String: FieldHints] {
        ["status": FieldHints(readOnly: true), "running": FieldHints(readOnly: true), "blackboard": FieldHints(readOnly: true),
         "tree": FieldHints(readOnly: true), "ticks": FieldHints(readOnly: true)]
    }

    /// The shared values leaves read and write. Game code may change them.
    public var blackboard: [String: BehaviorValue] = [:]
    /// The tree reference this state was made for ("" until the system first runs it).
    public internal(set) var tree = ""
    /// Node ids in the compiled order, matching `statuses`.
    public internal(set) var nodeIDs: [String] = []
    /// What each node returned on the last tick (nil: not ticked then).
    public internal(set) var statuses: [BehaviorStatus?] = []
    /// What the root returned on the last tick.
    public internal(set) var rootStatus: BehaviorStatus?
    public internal(set) var tickCount = 0
    /// Events raised this frame (cleared at the start of each frame's run).
    public internal(set) var events: [BehaviorEvent] = []
    /// Problems met while running (a missing custom leaf, no target), most recent last.
    public internal(set) var problems: [String] = []

    var revision = -1
    var memory: [BehaviorNodeMemory] = []
    /// Times nodes (cooldown, attack) may run again, which survive interruptions.
    var readyAt: [Int: Double] = [:]
    var origin: Vec3?
    var steering: BehaviorSteering?
    var face: Vec3?
    var clock: Double = 0
    var lastTick: Double = -1
    var random: UInt64 = 0

    public init(blackboard: [String: BehaviorValue] = [:]) {
        self.blackboard = blackboard
    }

    /// What node `id` returned on the last tick.
    public func status(of id: String) -> BehaviorStatus? {
        guard let i = nodeIDs.firstIndex(of: id), statuses.indices.contains(i) else { return nil }
        return statuses[i]
    }

    /// The ids of the nodes that returned running on the last tick, root first.
    public var runningPath: [String] {
        zip(nodeIDs, statuses).compactMap { $0.1 == .running ? $0.0 : nil }
    }

    /// Every node's last status by id.
    public var statusByID: [String: BehaviorStatus] {
        var result: [String: BehaviorStatus] = [:]
        for (id, status) in zip(nodeIDs, statuses) { if let status { result[id] = status } }
        return result
    }

    private enum CodingKeys: String, CodingKey { case tree, status, running, blackboard, ticks }

    /// Encoded for the inspector and tools only (it isn't saved); decoding gives a fresh state.
    public init(from decoder: any Decoder) throws { self.init() }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tree, forKey: .tree)
        try c.encode(rootStatus?.rawValue ?? "", forKey: .status)
        try c.encode(runningPath.joined(separator: " › "), forKey: .running)
        try c.encode(blackboard.keys.sorted().map { "\($0) = \(blackboard[$0]!)" }.joined(separator: "; "), forKey: .blackboard)
        try c.encode(tickCount, forKey: .ticks)
    }
}

// MARK: Custom leaves and code trees

/// What a custom leaf gets: the entity, its node's parameters, the blackboard, the target and
/// steering helpers. Valid only during the call.
@MainActor
public final class BehaviorLeafContext {
    public let world: World
    public let entity: Entity
    public let node: BehaviorNode
    /// Seconds since the tree's last tick.
    public let dt: Float
    /// Whether the node is starting (it finished or was interrupted before, or never ran).
    public let isFirstTick: Bool
    fileprivate let ticker: BehaviorTicker
    fileprivate let index: Int

    fileprivate init(ticker: BehaviorTicker, index: Int, isFirstTick: Bool) {
        self.ticker = ticker
        self.index = index
        world = ticker.world
        entity = ticker.entity
        node = ticker.compiled.nodes[index]
        dt = Float(ticker.dt)
        self.isFirstTick = isFirstTick
    }

    /// A parameter of the node (the JSON key next to `type`), or null.
    public func param(_ name: String) -> JSONValue { node.params[name] ?? .null }
    public func number(_ name: String, default value: Double = 0) -> Double { BehaviorJSON.number(param(name)) ?? value }
    public func string(_ name: String, default value: String = "") -> String { BehaviorJSON.string(param(name)) ?? value }
    public func bool(_ name: String, default value: Bool = false) -> Bool { BehaviorJSON.bool(param(name)) ?? value }

    public subscript(blackboard key: String) -> BehaviorValue? {
        get { ticker.state.blackboard[key] }
        set { ticker.state.blackboard[key] = newValue }
    }

    /// Values the leaf keeps between ticks while it runs; cleared when it finishes.
    public subscript(memory key: String) -> BehaviorValue? {
        get { ticker.state.memory[index].scratch[key] }
        set { ticker.state.memory[index].scratch[key] = newValue }
    }

    /// The entity's world position.
    public var position: Vec3 { ticker.position(of: entity) }
    /// The target entity (blackboard "target", else the runner's target), if any.
    public var target: Entity? { ticker.target("target")?.entity }
    /// Where the target is, if there is one.
    public var targetPosition: Vec3? { ticker.target("target")?.position }

    /// Walks toward `point` until the next tick (call each tick to keep walking).
    public func walk(to point: Vec3, speed: Float? = nil) {
        ticker.state.steering = BehaviorSteering(goal: point, speed: speed ?? ticker.defaultSpeed, stopDistance: 0)
    }

    /// Walks away from `point` until the next tick.
    public func walk(awayFrom point: Vec3, speed: Float? = nil) {
        ticker.state.steering = BehaviorSteering(goal: point, away: true, speed: speed ?? ticker.defaultSpeed, stopDistance: 0)
    }

    /// Turns to face `point`.
    public func face(_ point: Vec3) { ticker.state.face = point - position }

    /// Records an event in `BehaviorTreeState.events`.
    public func raise(_ name: String, target: Entity? = nil, amount: Double = 0) {
        ticker.state.events.append(BehaviorEvent(name: name, node: node.id, target: target, amount: amount))
    }
}

/// A leaf written in game code: returns success, failure or running each tick.
public typealias BehaviorLeaf = @MainActor (BehaviorLeafContext) -> BehaviorStatus

/// Leaves game code adds, run by `{"type": "custom", "leaf": "<name>"}` nodes.
///
/// ```swift
/// BehaviorTreeLeaves.register("hasAmmo") { leaf in
///     (leaf[blackboard: "ammo"]?.number ?? 0) > 0 ? .success : .failure
/// }
/// ```
@MainActor
public enum BehaviorTreeLeaves {
    private static var leaves: [String: BehaviorLeaf] = [:]

    /// Adds (or replaces) the leaf `name`.
    public static func register(_ name: String, _ leaf: @escaping BehaviorLeaf) { leaves[name] = leaf }
    public static func unregister(_ name: String) { leaves[name] = nil }
    public static func leaf(named name: String) -> BehaviorLeaf? { leaves[name] }
    /// The registered names, sorted.
    public static var names: [String] { leaves.keys.sorted() }
}

/// Trees made in code, found by name before `.behavior` assets (a runner's `tree` is the name).
@MainActor
public enum BehaviorTreeLibrary {
    private static var trees: [String: (tree: BehaviorTree, revision: Int)] = [:]
    private static var nextRevision = 1

    /// Adds or replaces the tree `name`; runners using it pick up the new one.
    public static func register(_ tree: BehaviorTree, as name: String) {
        trees[name] = (tree, nextRevision)
        nextRevision += 1
    }

    public static func unregister(_ name: String) { trees[name] = nil }
    public static func tree(named name: String) -> (tree: BehaviorTree, revision: Int)? { trees[name] }
}

// MARK: Compiled tree

/// A tree with children resolved to indices: each node is reached once from the root (a second
/// parent or a cycle is dropped), unknown nodes fail.
final class CompiledBehaviorTree {
    let tree: BehaviorTree
    let nodes: [BehaviorNode]
    let kinds: [BehaviorNodeKind?]
    let children: [[Int]]
    let root: Int?

    init(_ tree: BehaviorTree) {
        self.tree = tree
        var order: [BehaviorNode] = []
        var children: [[Int]] = []
        var indexByID: [String: Int] = [:]
        var firstByID: [String: BehaviorNode] = [:]
        for node in tree.nodes where firstByID[node.id] == nil { firstByID[node.id] = node }
        func visit(_ id: String) -> Int? {
            guard indexByID[id] == nil, let node = firstByID[id] else { return nil }
            let i = order.count
            indexByID[id] = i
            order.append(node)
            children.append([])
            let isLeaf = node.kind?.isLeaf ?? true
            if !isLeaf { children[i] = node.children.compactMap(visit) }
            return i
        }
        root = tree.rootID.flatMap(visit)
        nodes = order
        kinds = order.map(\.kind)
        self.children = children
    }
}

// MARK: Ticking

/// Ticks one entity's tree.
@MainActor
final class BehaviorTicker {
    let world: World
    let entity: Entity
    let compiled: CompiledBehaviorTree
    let runner: BehaviorTreeRunner
    let physics: PhysicsWorld?
    var state: BehaviorTreeState
    var dt: Double = 0
    let names: () -> [String: Entity]

    init(world: World, entity: Entity, compiled: CompiledBehaviorTree, runner: BehaviorTreeRunner, state: BehaviorTreeState,
         physics: PhysicsWorld?, names: @escaping () -> [String: Entity]) {
        self.world = world
        self.entity = entity
        self.compiled = compiled
        self.runner = runner
        self.state = state
        self.physics = physics
        self.names = names
    }

    var defaultSpeed: Float { runner.speed > 0 ? runner.speed : Float(compiled.tree.speed) }

    func position(of entity: Entity) -> Vec3 {
        world.get(GlobalTransform.self, for: entity)?.position ?? world.get(Transform.self, for: entity)?.position ?? .zero
    }

    var position: Vec3 { position(of: entity) }

    /// The target a leaf's `target` key names: an entity (directly, by name) or a point.
    func target(_ key: String) -> (entity: Entity?, position: Vec3)? {
        let key = key.isEmpty ? "target" : key
        switch state.blackboard[key] {
        case .entity(let e)? where world.isAlive(e): return (e, position(of: e))
        case .text(let name)?: if let e = names()[name] { return (e, position(of: e)) }
        case .vector(let v)?: return (nil, v)
        default: break
        }
        if key == "target", let e = world.resolve(runner.target), e != entity { return (e, position(of: e)) }
        return nil
    }

    func note(_ problem: String) {
        guard !state.problems.contains(problem) else { return }
        state.problems.append(problem)
        if state.problems.count > 20 { state.problems.removeFirst() }
        EngineLog.warning("Behavior tree on entity \(entity.index): \(problem)")
    }

    func randomUnit() -> Double {
        state.random = state.random &* 6364136223846793005 &+ 1442695040888963407
        return Double(state.random >> 11) / Double(1 << 53)
    }

    func tickRoot() -> BehaviorStatus? {
        guard let root = compiled.root else { return nil }
        state.statuses = Array(repeating: nil, count: compiled.nodes.count)
        state.steering = nil
        state.face = nil
        let status = tick(root)
        state.rootStatus = status
        state.tickCount += 1
        return status
    }

    /// Resets the memory of `i` and everything under it (it was interrupted).
    func halt(_ i: Int) {
        state.memory[i] = BehaviorNodeMemory()
        for child in compiled.children[i] { halt(child) }
    }

    func tick(_ i: Int) -> BehaviorStatus {
        let status = run(i)
        state.statuses[i] = status
        if status != .running { state.memory[i] = BehaviorNodeMemory() }
        return status
    }

    /// Records `next` as the running child of `i`, halting the one that ran before if different.
    private func switchRunning(_ i: Int, to next: Int?) {
        let old = state.memory[i].running
        if old >= 0, old != next, compiled.children[i].indices.contains(old) { halt(compiled.children[i][old]) }
        state.memory[i].running = next ?? -1
    }

    private func run(_ i: Int) -> BehaviorStatus {
        guard let kind = compiled.kinds[i] else { return .failure }
        let node = compiled.nodes[i]
        let kids = compiled.children[i]
        let firstTick = !state.memory[i].started
        state.memory[i].started = true
        switch kind {
        case .sequence:
            guard !kids.isEmpty else { return .failure }
            let memory = node.bool("memory")
            let start = memory ? max(state.memory[i].running, 0) : 0
            for c in start..<kids.count {
                switch tick(kids[c]) {
                case .running:
                    switchRunning(i, to: c)
                    return .running
                case .failure:
                    switchRunning(i, to: c)
                    return .failure
                case .success: continue
                }
            }
            switchRunning(i, to: kids.count - 1)
            return .success
        case .selector:
            guard !kids.isEmpty else { return .failure }
            let memory = node.bool("memory")
            let start = memory ? max(state.memory[i].running, 0) : 0
            for c in start..<kids.count {
                switch tick(kids[c]) {
                case .running:
                    switchRunning(i, to: c)
                    return .running
                case .success:
                    switchRunning(i, to: c)
                    return .success
                case .failure: continue
                }
            }
            switchRunning(i, to: kids.count - 1)
            return .failure
        case .parallel:
            guard !kids.isEmpty else { return .failure }
            if state.memory[i].results.count != kids.count { state.memory[i].results = Array(repeating: nil, count: kids.count) }
            for (c, kid) in kids.enumerated() where state.memory[i].results[c] == nil {
                let s = tick(kid)
                if s != .running { state.memory[i].results[c] = s }
            }
            let results = state.memory[i].results
            let successes = results.filter { $0 == .success }.count
            let failures = results.filter { $0 == .failure }.count
            let succeedOnOne = node.string("succeedOn") == "one"
            let failOnAll = node.string("failOn") == "all"
            let outcome: BehaviorStatus? =
                (succeedOnOne ? successes > 0 : successes == kids.count) ? .success
                : (failOnAll ? failures == kids.count : failures > 0) ? .failure
                : (successes + failures == kids.count ? (succeedOnOne ? .failure : .success) : nil)
            guard let outcome else { return .running }
            for (c, kid) in kids.enumerated() where results[c] == nil { halt(kid) }
            return outcome
        case .invert:
            guard let kid = kids.first else { return .failure }
            switch tick(kid) {
            case .success: return .failure
            case .failure: return .success
            case .running: return .running
            }
        case .succeed:
            guard let kid = kids.first else { return .success }
            return tick(kid) == .running ? .running : .success
        case .repeat:
            guard let kid = kids.first else { return .failure }
            switch tick(kid) {
            case .running: return .running
            case .failure: return node.bool("untilFailure") ? .success : .failure
            case .success:
                state.memory[i].count += 1
                let count = Int(node.number("count"))
                if count > 0, state.memory[i].count >= count { return .success }
                halt(kid)
                return .running
            }
        case .cooldown:
            guard let kid = kids.first else { return .failure }
            if let ready = state.readyAt[i], state.clock < ready { return .failure }
            let s = tick(kid)
            if s != .running { state.readyAt[i] = state.clock + node.number("seconds") }
            return s
        case .canSeeTarget: return canSee(node)
        case .withinRange:
            guard let target = target(node.string("target")) else { return .failure }
            return flatDistance(position, target.position) <= Float(node.number("range")) ? .success : .failure
        case .healthBelow:
            return (state.blackboard[node.string("key")]?.number ?? 0) < node.number("value") ? .success : .failure
        case .checkBlackboard: return check(node)
        case .moveTo:
            let goal: Vec3
            let key = node.string("key")
            if !key.isEmpty {
                guard let target = target(key) else { return .failure }
                goal = target.position
            } else {
                goal = BehaviorJSON.vector(node.value("position")) ?? .zero
            }
            return steer(to: goal, speed: speed(node), arrive: Float(node.number("arriveDistance")))
        case .patrol: return patrol(i, node)
        case .chase:
            guard let target = target(node.string("target")) else { return .failure }
            let distance = flatDistance(position, target.position)
            let stop = Float(node.number("stopDistance"))
            if distance <= stop { return .success }
            let giveUp = Float(node.number("giveUpDistance"))
            if giveUp > 0, distance > giveUp { return .failure }
            state.steering = BehaviorSteering(goal: target.position, entity: target.entity, speed: speed(node), stopDistance: stop * 0.9)
            return .running
        case .flee:
            guard let target = target(node.string("target")) else { return .failure }
            if flatDistance(position, target.position) >= Float(node.number("safeDistance")) { return .success }
            state.steering = BehaviorSteering(goal: target.position, entity: target.entity, away: true, speed: speed(node), stopDistance: 0)
            return .running
        case .attack: return attack(i, node)
        case .wait:
            if firstTick { state.memory[i].duration = node.number("seconds") + node.number("randomness") * randomUnit() }
            else { state.memory[i].time += dt }
            return state.memory[i].time >= state.memory[i].duration ? .success : .running
        case .playAnimation:
            if firstTick {
                guard play(node.string("animation"), fade: Float(node.number("fade"))) else {
                    note("node '\(node.id)': the entity has no Animator or SpriteAnimator to play '\(node.string("animation"))'")
                    return .failure
                }
            } else {
                state.memory[i].time += dt
            }
            return state.memory[i].time >= node.number("duration") ? .success : .running
        case .setBlackboard:
            let key = node.string("key")
            guard !key.isEmpty else { return .failure }
            state.blackboard[key] = BehaviorValue(json: node.value("value"))
            return .success
        case .custom:
            let name = node.string("leaf")
            guard let leaf = BehaviorTreeLeaves.leaf(named: name) else {
                note("node '\(node.id)': no custom leaf '\(name)' is registered")
                return .failure
            }
            return leaf(BehaviorLeafContext(ticker: self, index: i, isFirstTick: firstTick))
        }
    }

    private func speed(_ node: BehaviorNode) -> Float {
        let s = Float(node.number("speed"))
        return s > 0 ? s : defaultSpeed
    }

    private func steer(to goal: Vec3, speed: Float, arrive: Float) -> BehaviorStatus {
        if flatDistance(position, goal) <= max(arrive, 0.01) { return .success }
        state.steering = BehaviorSteering(goal: goal, speed: speed, stopDistance: 0)
        return .running
    }

    private func patrol(_ i: Int, _ node: BehaviorNode) -> BehaviorStatus {
        let key = node.string("key")
        var points: [Vec3]
        if !key.isEmpty, case .points(let p)? = state.blackboard[key] { points = p }
        else { points = BehaviorJSON.points(node.value("points")) ?? [] }
        guard !points.isEmpty else { return .failure }
        if node.bool("relative") { points = points.map { $0 + (state.origin ?? .zero) } }
        var memory = state.memory[i]
        defer { state.memory[i] = memory }
        memory.count = min(memory.count, points.count - 1)
        if memory.waiting {
            memory.time += dt
            guard memory.time >= node.number("wait") else { return .running }
            memory.waiting = false
            memory.time = 0
            memory.count += 1
            if memory.count >= points.count {
                guard node.bool("loop") else { return .success }
                memory.count = 0
            }
        }
        let goal = points[memory.count]
        if flatDistance(position, goal) <= max(Float(node.number("arriveDistance")), 0.01) {
            if node.number("wait") > 0 {
                memory.waiting = true
                memory.time = 0
                return .running
            }
            memory.count += 1
            if memory.count >= points.count {
                guard node.bool("loop") else { return .success }
                memory.count = 0
            }
        }
        state.steering = BehaviorSteering(goal: points[memory.count], speed: speed(node), stopDistance: 0)
        return .running
    }

    private func attack(_ i: Int, _ node: BehaviorNode) -> BehaviorStatus {
        guard let target = target(node.string("target")) else { return .failure }
        guard flatDistance(position, target.position) <= Float(node.number("range")) else { return .failure }
        state.face = target.position - position
        if let ready = state.readyAt[i], state.clock < ready { return .running }
        state.readyAt[i] = state.clock + node.number("cooldown")
        let damage = node.number("damage")
        if let victim = target.entity, damage != 0 {
            let key = node.string("key")
            world.modify(BehaviorTreeState.self, for: victim) { other in
                other.blackboard[key] = .number((other.blackboard[key]?.number ?? 0) - damage)
            }
        }
        let animation = node.string("animation")
        if !animation.isEmpty { _ = play(animation, fade: 0.1) }
        state.events.append(BehaviorEvent(name: "attack", node: node.id, target: target.entity, amount: damage))
        return .success
    }

    private func canSee(_ node: BehaviorNode) -> BehaviorStatus {
        guard let target = target(node.string("target")) else { return .failure }
        let eye = Vec3(0, Float(node.number("eyeHeight")), 0)
        let from = position + eye
        let to = target.position + eye
        var offset = to - from
        let distance = length(offset)
        guard distance <= Float(node.number("range")) else { return .failure }
        if distance > 1e-4 {
            let rotation = world.get(Transform.self, for: entity)?.rotation ?? .identity
            let forward = rotation * Vec3(0, 0, -1)
            let flatForward = Vec3(forward.x, 0, forward.z)
            let flatOffset = Vec3(offset.x, 0, offset.z)
            if length(flatForward) > 1e-4, length(flatOffset) > 1e-4 {
                let cosine = dot(normalize(flatForward), normalize(flatOffset))
                let half = Float(node.number("fov")) * .pi / 360
                if cosine < cos(min(half, .pi)) { return .failure }
            }
            if node.bool("lineOfSight"), let physics {
                offset /= distance
                for hit in physics.raycastAll(Ray(origin: from, direction: offset), maxDistance: distance) {
                    guard let hitEntity = hit.entity else { continue }
                    if belongs(hitEntity, to: entity) { continue }
                    if let t = target.entity, belongs(hitEntity, to: t) { break }
                    if hit.distance < distance - 0.05 { return .failure }
                }
            }
        }
        state.blackboard["lastSeenPosition"] = .vector(target.position)
        return .success
    }

    /// Whether `e` is `owner` or under it.
    private func belongs(_ e: Entity, to owner: Entity) -> Bool {
        var current: Entity? = e
        while let c = current {
            if c == owner { return true }
            current = world.parent(of: c)
        }
        return false
    }

    private func check(_ node: BehaviorNode) -> BehaviorStatus {
        let value = state.blackboard[node.string("key")]
        let op = node.string("op")
        let expected = node.value("value")
        let result: Bool
        switch op {
        case "set": result = value != nil
        case "unset": result = value == nil
        case "<", "<=", ">", ">=":
            guard let a = value?.number, let b = BehaviorJSON.number(expected) else { return .failure }
            result = op == "<" ? a < b : op == "<=" ? a <= b : op == ">" ? a > b : a >= b
        default:
            let equal: Bool
            if let a = value?.number, let b = BehaviorJSON.number(expected) { equal = a == b }
            else if let value { equal = value == BehaviorValue(json: expected) }
            else { equal = expected == .null }
            result = op == "!=" ? !equal : equal
        }
        return result ? .success : .failure
    }

    private func play(_ name: String, fade: Float) -> Bool {
        guard !name.isEmpty else { return false }
        if world.has(Animator.self, for: entity) {
            world.modify(Animator.self, for: entity) { $0.play(name, fade: fade) }
            return true
        }
        if world.has(SpriteAnimator.self, for: entity) {
            world.modify(SpriteAnimator.self, for: entity) { $0.play(name) }
            return true
        }
        return false
    }

    // MARK: Movement

    /// Moves and turns the entity for one frame from the stored steering.
    func move(frameDt: Float, turnSpeed: Float) {
        var velocity = Vec3.zero
        let here = position
        if let steering = state.steering {
            let goal = steering.entity.flatMap { world.isAlive($0) ? position(of: $0) : nil } ?? steering.goal
            var offset = goal - here
            offset.y = 0
            let distance = length(offset)
            if steering.away {
                velocity = distance > 1e-4 ? -offset / distance * steering.speed : Vec3(steering.speed, 0, 0)
            } else if distance > steering.stopDistance + 1e-4 {
                let step = frameDt > 0 ? (distance - steering.stopDistance) / frameDt : steering.speed
                velocity = offset / distance * min(steering.speed, step)
            }
        }
        if world.has(CharacterController.self, for: entity) {
            world.modify(CharacterController.self, for: entity) { $0.moveVelocity = Vec3(velocity.x, 0, velocity.z) }
        } else if let body = world.get(RigidBody.self, for: entity), body.motion == .dynamic {
            world.modify(RigidBody.self, for: entity) { $0.linearVelocity = Vec3(velocity.x, $0.linearVelocity.y, velocity.z) }
        } else if velocity != .zero {
            world.modify(Transform.self, for: entity) { $0.position += velocity * frameDt }
        }
        let facing = length(velocity) > 1e-3 ? velocity : (state.face ?? .zero)
        guard turnSpeed > 0, length(Vec3(facing.x, 0, facing.z)) > 1e-4 else { return }
        world.modify(Transform.self, for: entity) { transform in
            let forward = transform.rotation * Vec3(0, 0, -1)
            let current = atan2(-forward.x, -forward.z)
            let wanted = atan2(-facing.x, -facing.z)
            var delta = wanted - current
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            let maxStep = turnSpeed * frameDt
            let yaw = current + max(-maxStep, min(maxStep, delta))
            transform.rotation = Quat(angle: yaw, axis: Vec3(0, 1, 0))
        }
    }
}

private func flatDistance(_ a: Vec3, _ b: Vec3) -> Float {
    let d = Vec3(a.x - b.x, 0, a.z - b.z)
    return length(d)
}

// MARK: System

public enum BehaviorTreeSystem {
    /// The default name of the system `addBehaviorTrees` adds.
    public static let name = "behaviorTrees"

    /// Registers the behavior tree components with `ComponentRegistry`.
    @MainActor public static func registerComponents() {
        ComponentRegistry.register(BehaviorTreeRunner.self, BehaviorTreeState.self)
    }
}

extension World {
    /// Adds the system that runs every `BehaviorTreeRunner` (see the notes at the top of
    /// BehaviorTreeRuntime.swift) in `.update`. Trees are found by name in `BehaviorTreeLibrary`,
    /// then as `.behavior` assets in `assets()`. `physics()` (optional) lets `canSeeTarget` test
    /// line of sight. Idempotent per name; remove it with `removeSystem(named:)`.
    @MainActor public func addBehaviorTrees(name: String = BehaviorTreeSystem.name, assets: @escaping () -> AssetDatabase? = { nil },
                                            physics: @escaping () -> PhysicsWorld? = { nil }) {
        guard !systemNames(in: .update).contains(name) else { return }
        BehaviorTreeSystem.registerComponents()
        var cache: [String: (key: String, revision: Int, compiled: CompiledBehaviorTree)] = [:]
        var missing = Set<String>()
        func compiled(_ reference: String) -> (key: String, revision: Int, compiled: CompiledBehaviorTree)? {
            let found: (key: String, revision: Int)?
            if let code = BehaviorTreeLibrary.tree(named: reference) {
                found = ("library:" + reference, code.revision)
            } else if let assets = assets(), let asset = assets.behaviorTreeRevision(reference) {
                found = (asset.id.description, asset.revision)
            } else {
                found = nil
            }
            guard let found else { cache[reference] = nil; return nil }
            if let hit = cache[reference], hit.key == found.key, hit.revision == found.revision { return hit }
            let tree: BehaviorTree?
            if let code = BehaviorTreeLibrary.tree(named: reference) { tree = code.tree }
            else if let id = AssetID(found.key) { tree = assets()?.behaviorTreeContents(of: id) }
            else { tree = nil }
            guard let tree else { return nil }
            let entry = (found.key, found.revision, CompiledBehaviorTree(tree))
            cache[reference] = entry
            return entry
        }
        addSystem(name, stage: .update) { world in
            guard world.count(of: BehaviorTreeRunner.self) > 0 else { return }
            Profiler.scope("behaviorTrees") {
                var runners: [(Entity, BehaviorTreeRunner)] = []
                world.query(BehaviorTreeRunner.self) { entity, runner in runners.append((entity, runner)) }
                var names: [String: Entity]?
                let lookup: () -> [String: Entity] = {
                    if let names { return names }
                    var found: [String: Entity] = [:]
                    world.query(Name.self) { entity, name in if found[name.value] == nil { found[name.value] = entity } }
                    names = found
                    return found
                }
                let frameDt = world.time.delta
                for (entity, runner) in runners {
                    guard world.isAlive(entity) else { continue }
                    guard runner.isRunning, let tree = compiled(runner.tree) else {
                        if !runner.isRunning { world.modify(CharacterController.self, for: entity) { $0.moveVelocity = .zero } }
                        else if missing.insert(runner.tree).inserted {
                            EngineLog.warning("BehaviorTreeRunner: no behavior tree '\(runner.tree)'")
                        }
                        continue
                    }
                    let existing = world.get(BehaviorTreeState.self, for: entity)
                    var state = existing ?? BehaviorTreeState()
                    if state.revision != tree.revision || state.tree != runner.tree {
                        state = World.prepare(state, tree.compiled, runner: runner, seed: UInt64(entity.index) &+ 1,
                                              origin: world.get(GlobalTransform.self, for: entity)?.position
                                                  ?? world.get(Transform.self, for: entity)?.position ?? .zero,
                                              fresh: existing == nil || state.tree != runner.tree)
                        state.revision = tree.revision
                        state.tree = runner.tree
                    }
                    state.events = []
                    state.clock += Double(frameDt)
                    let ticker = BehaviorTicker(world: world, entity: entity, compiled: tree.compiled, runner: runner, state: state,
                                                physics: physics(), names: lookup)
                    let rate = tree.compiled.tree.tickRate
                    if state.lastTick < 0 || rate <= 0 || state.clock - state.lastTick >= 1 / rate - 1e-9 {
                        ticker.dt = state.lastTick < 0 ? Double(frameDt) : state.clock - state.lastTick
                        ticker.state.lastTick = state.clock
                        if let status = ticker.tickRoot(), status != .running, let root = tree.compiled.root {
                            ticker.halt(root)  // finished: start over on the next tick
                        }
                    }
                    ticker.move(frameDt: frameDt, turnSpeed: Float(tree.compiled.tree.turnSpeed))
                    world.add(ticker.state, to: entity)
                }
            }
        }
    }

    /// `state` made ready for `tree`: node memory sized to it, the blackboard filled with the
    /// tree's values (and the runner's overrides) for keys it doesn't have yet (all keys when
    /// `fresh`, keeping only values game code set before the first tick).
    static func prepare(_ state: BehaviorTreeState, _ tree: CompiledBehaviorTree, runner: BehaviorTreeRunner, seed: UInt64,
                        origin: Vec3, fresh: Bool) -> BehaviorTreeState {
        var state = state
        var defaults: [String: BehaviorValue] = [:]
        for (key, value) in tree.tree.blackboard { defaults[key] = BehaviorValue(json: value) }
        for entry in runner.blackboard where !entry.key.isEmpty { defaults[entry.key] = BehaviorValue(json: BehaviorJSON.parse(entry.value)) }
        for (key, value) in defaults where state.blackboard[key] == nil { state.blackboard[key] = value }
        state.nodeIDs = tree.nodes.map(\.id)
        state.memory = Array(repeating: BehaviorNodeMemory(), count: tree.nodes.count)
        state.statuses = Array(repeating: nil, count: tree.nodes.count)
        state.readyAt = [:]
        state.steering = nil
        if fresh || state.origin == nil {
            state.origin = origin
            state.random = seed &* 0x9E3779B97F4A7C15
        }
        return state
    }

    /// The blackboard value `key` of `entity`'s tree (nil if unset or the entity runs none yet).
    public func blackboardValue(_ key: String, for entity: Entity) -> BehaviorValue? {
        get(BehaviorTreeState.self, for: entity)?.blackboard[key]
    }

    /// Sets (nil removes) a blackboard value of `entity`'s tree. Works before the first tick
    /// too: the value wins over the tree's starting value.
    public func setBlackboardValue(_ value: BehaviorValue?, forKey key: String, of entity: Entity) {
        guard isAlive(entity) else { return }
        if has(BehaviorTreeState.self, for: entity) {
            modify(BehaviorTreeState.self, for: entity) { $0.blackboard[key] = value }
        } else {
            var state = BehaviorTreeState()
            state.blackboard[key] = value
            add(state, to: entity)
        }
    }
}
