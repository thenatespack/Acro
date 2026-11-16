import Foundation
import EngineCore
import EngineScene

// NPC AI as a node tree: the contents of a `.behavior` file (JSON, every key optional).
//
// ```json
// {
//   "root": "root",
//   "nodes": [
//     {"id": "root", "type": "selector", "children": ["fight", "patrol"]},
//     {"id": "fight", "type": "sequence", "children": ["see", "chase", "attack"]},
//     {"id": "see", "type": "canSeeTarget", "range": 12, "fov": 120},
//     {"id": "chase", "type": "chase", "stopDistance": 1.5},
//     {"id": "attack", "type": "attack", "damage": 10, "cooldown": 1},
//     {"id": "patrol", "type": "patrol", "points": [[-4, 0, 0], [4, 0, 0]], "relative": true, "wait": 1}
//   ],
//   "blackboard": {"health": 100},
//   "speed": 3, "turnSpeed": 10, "tickRate": 0
// }
// ```
//
// Nodes are a flat list; a composite or decorator names its children by id, in order. Every
// key of a node other than `id`, `type`, `name` and `children` is a parameter of its type
// (see `BehaviorNodeKind.params`). The root is `root`, or when that is empty the first node
// no other node lists as a child. The blackboard holds the starting shared values (numbers,
// booleans, text, [x, y, z] vectors, lists of vectors); a `BehaviorTreeRunner` can override
// them per entity and game code can read and write them while the tree runs.
//
// Problems (unknown types, missing children, nodes with two parents, cycles, wrong
// parameters) are kept and reported by `BehaviorTree.validate`; the runtime treats a broken
// node as one that fails.

/// What role a node type has in the tree.
public enum BehaviorNodeCategory: String, Codable, CaseIterable, Sendable {
    /// Runs its children by a rule (sequence, selector, parallel).
    case composite
    /// Changes the result of its one child.
    case decorator
    /// A leaf that checks something and succeeds or fails at once.
    case condition
    /// A leaf that does something, possibly over several ticks (running).
    case action
}

/// The kind of value a node parameter holds.
public enum BehaviorParamType: String, Codable, Sendable {
    case number, bool, text
    /// [x, y, z].
    case vector
    /// [[x, y, z], ...].
    case points
    /// The name of a blackboard key.
    case key
    /// One of the parameter's options.
    case choice
}

/// One parameter of a node type: its name, kind, default and what it does.
public struct BehaviorParamSpec: Sendable, Equatable {
    public var name: String
    public var type: BehaviorParamType
    public var defaultValue: JSONValue
    public var doc: String
    public var options: [String]

    public init(_ name: String, _ type: BehaviorParamType, _ defaultValue: JSONValue, _ doc: String, options: [String] = []) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.doc = doc
        self.options = options
    }

    init(_ name: String, _ type: BehaviorParamType, _ number: Double, _ doc: String) {
        self.init(name, type, .double(number), doc)
    }

    init(_ name: String, _ type: BehaviorParamType, _ flag: Bool, _ doc: String) {
        self.init(name, type, .bool(flag), doc)
    }

    init(_ name: String, _ type: BehaviorParamType, _ text: String, _ doc: String, options: [String] = []) {
        self.init(name, type, .string(text), doc, options: options)
    }
}

/// The built-in node types. A `custom` node runs a leaf game code registered by name
/// (`BehaviorTreeLeaves.register`).
public enum BehaviorNodeKind: String, Codable, CaseIterable, Sendable {
    // Composites.
    case sequence, selector, parallel
    // Decorators.
    case invert, `repeat`, cooldown, succeed
    // Conditions.
    case canSeeTarget, withinRange, healthBelow, checkBlackboard
    // Actions.
    case moveTo, patrol, chase, flee, attack, wait, playAnimation, setBlackboard, custom

    public var category: BehaviorNodeCategory {
        switch self {
        case .sequence, .selector, .parallel: .composite
        case .invert, .repeat, .cooldown, .succeed: .decorator
        case .canSeeTarget, .withinRange, .healthBelow, .checkBlackboard: .condition
        default: .action
        }
    }

    public var isLeaf: Bool { category == .condition || category == .action }

    /// One line on what the node does.
    public var doc: String {
        switch self {
        case .sequence: "Runs children in order until one fails (fails) or all succeed (succeeds). Resumes at the running child unless memory is off."
        case .selector: "Tries children in order until one succeeds or runs. Re-checks from the first child every tick (reactive) unless memory is on."
        case .parallel: "Runs every child each tick; succeeds when all (or one) succeed, fails when one (or all) fail."
        case .invert: "Swaps its child's success and failure."
        case .repeat: "Runs its child again each time it succeeds: count times (0 = forever), or until it fails when untilFailure."
        case .cooldown: "Fails without running its child for `seconds` after the child last finished."
        case .succeed: "Succeeds whatever its child does (running stays running)."
        case .canSeeTarget: "The target is within range, inside the field of view (degrees, about -Z) and, with physics, not hidden behind a collider. Writes lastSeenPosition."
        case .withinRange: "The target is within range meters."
        case .healthBelow: "The blackboard number at key (default health) is below value."
        case .checkBlackboard: "Compares the blackboard value at key with value (op: == != < <= > >= set unset)."
        case .moveTo: "Walks to position (or the vector or entity at key) and succeeds on arrival."
        case .patrol: "Walks the points in order, waiting at each; loops forever (running) unless loop is off."
        case .chase: "Walks toward the target; succeeds within stopDistance, fails if it gets farther than giveUpDistance (0: never) or there is no target."
        case .flee: "Walks away from the target; succeeds once farther than safeDistance."
        case .attack: "Within range of the target: faces it, then hits it every cooldown seconds (lowers the target's blackboard health by damage and records an attack event). Fails out of range."
        case .wait: "Waits seconds (plus up to randomness more), then succeeds."
        case .playAnimation: "Plays an Animator state or SpriteAnimator clip named animation; with duration, runs that long first."
        case .setBlackboard: "Sets the blackboard value at key to value, then succeeds."
        case .custom: "Runs the leaf game code registered with BehaviorTreeLeaves.register(leaf); its other parameters are passed along."
        }
    }

    /// The parameters it reads (other keys are reported as unknown, except on `custom`).
    public var params: [BehaviorParamSpec] {
        let target = BehaviorParamSpec("target", .key, "target", "Blackboard key holding the target (an entity name, entity or vector); \"target\" falls back to the runner's target entity")
        let speed = BehaviorParamSpec("speed", .number, 0, "Meters per second (0: the tree's speed)")
        switch self {
        case .sequence: return [BehaviorParamSpec("memory", .bool, true, "Resume at the running child (off: re-check from the first child every tick)")]
        case .selector: return [BehaviorParamSpec("memory", .bool, false, "Resume at the running child instead of re-checking earlier ones")]
        case .parallel:
            return [BehaviorParamSpec("succeedOn", .choice, "all", "Succeed when all or one child succeeds", options: ["all", "one"]),
                    BehaviorParamSpec("failOn", .choice, "one", "Fail when one or all children fail", options: ["one", "all"])]
        case .invert, .succeed: return []
        case .repeat:
            return [BehaviorParamSpec("count", .number, 0, "Times to run the child (0: forever)"),
                    BehaviorParamSpec("untilFailure", .bool, false, "Repeat until the child fails, then succeed")]
        case .cooldown: return [BehaviorParamSpec("seconds", .number, 1, "Time after the child finishes before it can run again")]
        case .canSeeTarget:
            return [target, BehaviorParamSpec("range", .number, 10, "Meters"),
                    BehaviorParamSpec("fov", .number, 120, "Field of view in degrees, centered on the entity's forward (-Z)"),
                    BehaviorParamSpec("lineOfSight", .bool, true, "With physics, a collider between the eyes and the target blocks the view"),
                    BehaviorParamSpec("eyeHeight", .number, 1, "Height of the eyes above the entity's origin")]
        case .withinRange: return [target, BehaviorParamSpec("range", .number, 2, "Meters")]
        case .healthBelow:
            return [BehaviorParamSpec("key", .key, "health", "Blackboard number to test"),
                    BehaviorParamSpec("value", .number, 30, "Threshold")]
        case .checkBlackboard:
            return [BehaviorParamSpec("key", .key, "", "Blackboard key"),
                    BehaviorParamSpec("op", .choice, "==", "Comparison", options: ["==", "!=", "<", "<=", ">", ">=", "set", "unset"]),
                    BehaviorParamSpec("value", .text, .null, "Value to compare with")]
        case .moveTo:
            return [BehaviorParamSpec("position", .vector, .array([.int(0), .int(0), .int(0)]), "World position to walk to"),
                    BehaviorParamSpec("key", .key, "", "Or a blackboard key holding a vector or entity (wins over position)"),
                    speed, BehaviorParamSpec("arriveDistance", .number, 0.3, "Meters from the goal that count as arrived")]
        case .patrol:
            return [BehaviorParamSpec("points", .points, .array([]), "Waypoints [[x, y, z], ...]"),
                    BehaviorParamSpec("key", .key, "", "Or a blackboard key holding the waypoints"),
                    BehaviorParamSpec("relative", .bool, false, "Points are offsets from where the entity started"),
                    BehaviorParamSpec("loop", .bool, true, "Start over after the last point (off: succeed there)"),
                    BehaviorParamSpec("wait", .number, 0, "Seconds to wait at each point"),
                    speed, BehaviorParamSpec("arriveDistance", .number, 0.3, "Meters from a point that count as arrived")]
        case .chase:
            return [target, speed, BehaviorParamSpec("stopDistance", .number, 1.5, "Succeed this close"),
                    BehaviorParamSpec("giveUpDistance", .number, 0, "Fail farther than this (0: never)")]
        case .flee:
            return [target, speed, BehaviorParamSpec("safeDistance", .number, 10, "Succeed this far away")]
        case .attack:
            return [target, BehaviorParamSpec("range", .number, 2, "Meters"),
                    BehaviorParamSpec("damage", .number, 10, "Taken off the target's blackboard health"),
                    BehaviorParamSpec("cooldown", .number, 1, "Seconds between hits"),
                    BehaviorParamSpec("key", .key, "health", "The target's blackboard key that damage lowers"),
                    BehaviorParamSpec("animation", .text, "", "Animator state or sprite clip to play on each hit")]
        case .wait:
            return [BehaviorParamSpec("seconds", .number, 1, "Time to wait"),
                    BehaviorParamSpec("randomness", .number, 0, "Up to this many extra seconds")]
        case .playAnimation:
            return [BehaviorParamSpec("animation", .text, "", "Animator state or SpriteAnimator clip"),
                    BehaviorParamSpec("fade", .number, 0.2, "Crossfade seconds (Animator)"),
                    BehaviorParamSpec("duration", .number, 0, "Seconds to stay running (0: succeed at once)")]
        case .setBlackboard:
            return [BehaviorParamSpec("key", .key, "", "Blackboard key"),
                    BehaviorParamSpec("value", .text, .null, "New value (number, bool, text, [x, y, z]; null removes it)")]
        case .custom:
            return [BehaviorParamSpec("leaf", .text, "", "Name the game registered the leaf under")]
        }
    }

    public func param(_ name: String) -> BehaviorParamSpec? { params.first { $0.name == name } }
}

/// One node: an id unique in the tree, a type, an optional label, child ids (composites and
/// decorators) and the type's parameters. In the file the parameters sit next to the other keys.
public struct BehaviorNode: Codable, Equatable, Sendable {
    public var id: String
    /// A `BehaviorNodeKind` raw value (kept as written, so an unknown type isn't lost).
    public var type: String
    /// A label for the editor ("" shows the type).
    public var name: String
    public var children: [String]
    public var params: [String: JSONValue]

    public init(id: String = "", type: String = BehaviorNodeKind.sequence.rawValue, name: String = "", children: [String] = [],
                params: [String: JSONValue] = [:]) {
        self.id = id
        self.type = type
        self.name = name
        self.children = children
        self.params = params
    }

    public init(_ id: String, _ kind: BehaviorNodeKind, name: String = "", children: [String] = [], _ params: [String: JSONValue] = [:]) {
        self.init(id: id, type: kind.rawValue, name: name, children: children, params: params)
    }

    public var kind: BehaviorNodeKind? { BehaviorNodeKind(rawValue: type) }

    /// The label shown in the editor.
    public var title: String { name.isEmpty ? (id.isEmpty ? type : id) : name }

    static let reservedKeys: Set<String> = ["id", "type", "name", "children"]

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: BehaviorNodeKey.self)
        id = try c.decodeIfPresent(String.self, forKey: BehaviorNodeKey("id")) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: BehaviorNodeKey("type")) ?? BehaviorNodeKind.sequence.rawValue
        name = try c.decodeIfPresent(String.self, forKey: BehaviorNodeKey("name")) ?? ""
        children = try c.decodeIfPresent([String].self, forKey: BehaviorNodeKey("children")) ?? []
        var params: [String: JSONValue] = [:]
        for key in c.allKeys where !Self.reservedKeys.contains(key.stringValue) {
            params[key.stringValue] = try c.decode(JSONValue.self, forKey: key)
        }
        self.params = params
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: BehaviorNodeKey.self)
        try c.encode(id, forKey: BehaviorNodeKey("id"))
        try c.encode(type, forKey: BehaviorNodeKey("type"))
        if !name.isEmpty { try c.encode(name, forKey: BehaviorNodeKey("name")) }
        if !children.isEmpty || kind.map({ !$0.isLeaf }) == true { try c.encode(children, forKey: BehaviorNodeKey("children")) }
        for (key, value) in params where !Self.reservedKeys.contains(key) { try c.encode(value, forKey: BehaviorNodeKey(key)) }
    }

    /// The parameter as given, else the type's default.
    public func value(_ name: String) -> JSONValue {
        params[name] ?? kind?.param(name)?.defaultValue ?? .null
    }

    public func number(_ name: String) -> Double { BehaviorJSON.number(value(name)) ?? 0 }
    public func bool(_ name: String) -> Bool { BehaviorJSON.bool(value(name)) ?? false }
    public func string(_ name: String) -> String { BehaviorJSON.string(value(name)) ?? "" }
}

private struct BehaviorNodeKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// JSON value helpers shared by the behavior tree code.
public enum BehaviorJSON {
    public static func number(_ value: JSONValue) -> Double? {
        switch value {
        case .int(let v): Double(v)
        case .double(let v): v
        case .string(let s): Double(s.trimmingCharacters(in: .whitespaces))
        default: nil
        }
    }

    public static func bool(_ value: JSONValue) -> Bool? {
        switch value {
        case .bool(let v): v
        case .string(let s): ["true", "yes", "on", "1"].contains(s.lowercased()) ? true : (["false", "no", "off", "0"].contains(s.lowercased()) ? false : nil)
        case .int(let v): v != 0
        default: nil
        }
    }

    public static func string(_ value: JSONValue) -> String? {
        if case .string(let s) = value { return s }
        return nil
    }

    public static func vector(_ value: JSONValue) -> Vec3? {
        guard case .array(let items) = value, items.count == 3 else { return nil }
        let numbers = items.compactMap(number)
        guard numbers.count == 3 else { return nil }
        return Vec3(Float(numbers[0]), Float(numbers[1]), Float(numbers[2]))
    }

    public static func points(_ value: JSONValue) -> [Vec3]? {
        guard case .array(let items) = value else { return nil }
        let points = items.compactMap(vector)
        return points.count == items.count ? points : nil
    }

    public static func vectorValue(_ v: Vec3) -> JSONValue { .array([.double(Double(v.x)), .double(Double(v.y)), .double(Double(v.z))]) }

    /// Text a person types turned into a value: a number, true/false, "x, y, z" or [x, y, z], null, or text.
    public static func parse(_ text: String) -> JSONValue {
        let t = text.trimmingCharacters(in: .whitespaces)
        if t.isEmpty || t == "null" { return .null }
        if let i = Int64(t) { return .int(i) }
        if let d = Double(t) { return .double(d) }
        if t == "true" { return .bool(true) }
        if t == "false" { return .bool(false) }
        if t.hasPrefix("["), let data = t.data(using: .utf8), let value = try? JSONDecoder().decode(JSONValue.self, from: data) { return value }
        let parts = t.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 3, let x = Double(parts[0]), let y = Double(parts[1]), let z = Double(parts[2]) {
            return .array([.double(x), .double(y), .double(z)])
        }
        return .string(t)
    }

    /// A value as a person reads and types it.
    public static func text(_ value: JSONValue) -> String {
        switch value {
        case .null: ""
        case .bool(let b): b ? "true" : "false"
        case .int(let i): "\(i)"
        case .double(let d): d == d.rounded() && abs(d) < 1e15 ? "\(Int64(d))" : "\(d)"
        case .string(let s): s
        case .array(let items):
            if items.allSatisfy({ number($0) != nil }) { items.map(text).joined(separator: ", ") }
            else { "[" + items.map { "[" + text($0) + "]" }.joined(separator: ", ") + "]" }
        default: AssetJSON.canonical(value)
        }
    }
}

/// The contents of a `.behavior` file.
public struct BehaviorTree: Codable, Equatable, Sendable {
    /// The root node's id ("" or unknown: the first node no other node lists as a child).
    public var root: String
    public var nodes: [BehaviorNode]
    /// Starting values of the shared blackboard (numbers, bools, text, [x, y, z], lists of points).
    public var blackboard: [String: JSONValue]
    /// Default walking speed (m/s) of move, patrol, chase and flee nodes.
    public var speed: Double
    /// How fast the entity turns to face where it walks (radians per second; 0: it doesn't turn).
    public var turnSpeed: Double
    /// Ticks per second (0: every frame). Movement still runs every frame.
    public var tickRate: Double

    public init(root: String = "", nodes: [BehaviorNode] = [], blackboard: [String: JSONValue] = [:], speed: Double = 3,
                turnSpeed: Double = 10, tickRate: Double = 0) {
        self.root = root
        self.nodes = nodes
        self.blackboard = blackboard
        self.speed = speed
        self.turnSpeed = turnSpeed
        self.tickRate = tickRate
    }

    private enum CodingKeys: String, CodingKey { case root, nodes, blackboard, speed, turnSpeed, tickRate }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        root = try c.decodeIfPresent(String.self, forKey: .root) ?? ""
        nodes = try c.decodeIfPresent([BehaviorNode].self, forKey: .nodes) ?? []
        blackboard = try c.decodeIfPresent([String: JSONValue].self, forKey: .blackboard) ?? [:]
        speed = try c.decodeIfPresent(Double.self, forKey: .speed) ?? 3
        turnSpeed = try c.decodeIfPresent(Double.self, forKey: .turnSpeed) ?? 10
        tickRate = try c.decodeIfPresent(Double.self, forKey: .tickRate) ?? 0
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    // MARK: Lookup

    public func index(of id: String) -> Int? { nodes.firstIndex { $0.id == id } }
    public func node(_ id: String) -> BehaviorNode? { index(of: id).map { nodes[$0] } }

    /// The id of the node that lists `id` as a child (the first, if several do).
    public func parent(of id: String) -> String? { nodes.first { $0.children.contains(id) }?.id }

    /// The root node's id, or nil for an empty tree.
    public var rootID: String? {
        if !root.isEmpty, index(of: root) != nil { return root }
        let children = Set(nodes.flatMap(\.children))
        return nodes.first { !children.contains($0.id) }?.id ?? nodes.first?.id
    }

    /// An id not used yet, from `base` ("chase", "chase2", …).
    public func uniqueID(_ base: String) -> String {
        let base = base.isEmpty ? "node" : base
        let ids = Set(nodes.map(\.id))
        guard ids.contains(base) else { return base }
        var n = 2
        while ids.contains("\(base)\(n)") { n += 1 }
        return "\(base)\(n)"
    }

    /// The nodes under the root in depth-first order with their depth (each node once, so
    /// cycles and repeated children stop).
    public func outline() -> [(id: String, depth: Int)] {
        guard let rootID else { return [] }
        var result: [(String, Int)] = []
        var seen = Set<String>()
        func walk(_ id: String, _ depth: Int) {
            guard seen.insert(id).inserted, let node = node(id) else { return }
            result.append((id, depth))
            for child in node.children { walk(child, depth + 1) }
        }
        walk(rootID, 0)
        return result
    }

    /// The ids `id` and every node under it.
    public func subtree(_ id: String) -> Set<String> {
        var result = Set<String>()
        var stack = [id]
        while let next = stack.popLast() {
            guard result.insert(next).inserted, let node = node(next) else { continue }
            stack += node.children
        }
        return result
    }
}

// MARK: Validation

/// A problem with a tree, on a node (`node`) or the whole tree.
public struct BehaviorTreeIssue: Equatable, Sendable, CustomStringConvertible {
    public var node: String?
    public var message: String

    public init(node: String? = nil, _ message: String) {
        self.node = node
        self.message = message
    }

    public var description: String { node.map { "node '\($0)': \(message)" } ?? message }
}

extension BehaviorTree {
    /// Everything wrong with the tree; the runtime treats broken nodes as failing.
    /// `customLeaves`, when given, are the registered custom leaf names (unknown ones are reported).
    public func validate(customLeaves: Set<String>? = nil) -> [BehaviorTreeIssue] {
        var issues: [BehaviorTreeIssue] = []
        if nodes.isEmpty { return [BehaviorTreeIssue("the tree has no nodes")] }
        var seen = Set<String>()
        for node in nodes {
            if node.id.isEmpty { issues.append(BehaviorTreeIssue("a \(node.type) node has no id")) }
            else if !seen.insert(node.id).inserted { issues.append(BehaviorTreeIssue(node: node.id, "the id is used more than once")) }
        }
        if !root.isEmpty, index(of: root) == nil { issues.append(BehaviorTreeIssue("root '\(root)' is not a node")) }
        var parents: [String: String] = [:]
        for node in nodes {
            guard let kind = node.kind else {
                issues.append(BehaviorTreeIssue(node: node.id, "unknown type '\(node.type)' (one of \(BehaviorNodeKind.allCases.map(\.rawValue).joined(separator: ", ")))"))
                continue
            }
            switch kind.category {
            case .composite where node.children.isEmpty:
                issues.append(BehaviorTreeIssue(node: node.id, "a \(kind.rawValue) needs children"))
            case .decorator where node.children.count != 1:
                issues.append(BehaviorTreeIssue(node: node.id, "a \(kind.rawValue) needs exactly one child (has \(node.children.count))"))
            case .condition, .action:
                if !node.children.isEmpty { issues.append(BehaviorTreeIssue(node: node.id, "a \(kind.rawValue) is a leaf; its children are ignored")) }
            default: break
            }
            for child in node.children {
                if index(of: child) == nil { issues.append(BehaviorTreeIssue(node: node.id, "no child node '\(child)'")); continue }
                if child == rootID { issues.append(BehaviorTreeIssue(node: node.id, "lists the root '\(child)' as a child")) }
                if let other = parents[child], other != node.id {
                    issues.append(BehaviorTreeIssue(node: child, "has two parents ('\(other)' and '\(node.id)'); only the first runs it"))
                } else if parents[child] == node.id {
                    issues.append(BehaviorTreeIssue(node: node.id, "lists '\(child)' twice"))
                }
                parents[child] = parents[child] ?? node.id
            }
            issues += paramIssues(node, kind, customLeaves: customLeaves)
        }
        // Cycles and unreachable nodes.
        if let rootID {
            var onPath = Set<String>()
            var done = Set<String>()
            func walk(_ id: String) {
                guard let node = node(id) else { return }
                if onPath.contains(id) { issues.append(BehaviorTreeIssue(node: id, "is its own ancestor (a cycle)")); return }
                guard done.insert(id).inserted else { return }
                onPath.insert(id)
                for child in node.children { walk(child) }
                onPath.remove(id)
            }
            walk(rootID)
            for node in nodes where !node.id.isEmpty && !done.contains(node.id) {
                issues.append(BehaviorTreeIssue(node: node.id, "is not connected to the root, so it never runs"))
            }
        }
        if speed < 0 { issues.append(BehaviorTreeIssue("speed is negative")) }
        if tickRate < 0 { issues.append(BehaviorTreeIssue("tickRate is negative")) }
        return issues
    }

    private func paramIssues(_ node: BehaviorNode, _ kind: BehaviorNodeKind, customLeaves: Set<String>?) -> [BehaviorTreeIssue] {
        var issues: [BehaviorTreeIssue] = []
        let specs = kind.params
        for (key, value) in node.params.sorted(by: { $0.key < $1.key }) {
            guard let spec = specs.first(where: { $0.name == key }) else {
                if kind != .custom {
                    issues.append(BehaviorTreeIssue(node: node.id, "unknown parameter '\(key)' for \(kind.rawValue) (has \(specs.isEmpty ? "none" : specs.map(\.name).joined(separator: ", ")))"))
                }
                continue
            }
            if let problem = Self.problem(value, spec) { issues.append(BehaviorTreeIssue(node: node.id, "\(key): \(problem)")) }
        }
        switch kind {
        case .custom:
            let leaf = node.string("leaf")
            if leaf.isEmpty { issues.append(BehaviorTreeIssue(node: node.id, "a custom node needs `leaf` (a name registered with BehaviorTreeLeaves.register)")) }
            else if let customLeaves, !customLeaves.contains(leaf) {
                issues.append(BehaviorTreeIssue(node: node.id, "no custom leaf '\(leaf)' is registered (game code registers it with BehaviorTreeLeaves.register)"))
            }
        case .checkBlackboard, .setBlackboard:
            if node.string("key").isEmpty { issues.append(BehaviorTreeIssue(node: node.id, "needs `key`")) }
        case .playAnimation:
            if node.string("animation").isEmpty { issues.append(BehaviorTreeIssue(node: node.id, "needs `animation`")) }
        case .patrol:
            if node.string("key").isEmpty, (BehaviorJSON.points(node.value("points")) ?? []).isEmpty {
                issues.append(BehaviorTreeIssue(node: node.id, "needs `points` (or a blackboard `key` holding them)"))
            }
        case .healthBelow:
            let key = node.string("key")
            if blackboard[key] == nil { issues.append(BehaviorTreeIssue(node: node.id, "the blackboard has no '\(key)' (it reads as 0 until set)")) }
        default: break
        }
        return issues
    }

    static func problem(_ value: JSONValue, _ spec: BehaviorParamSpec) -> String? {
        switch spec.type {
        case .number: return BehaviorJSON.number(value) == nil ? "expected a number" : nil
        case .bool: return BehaviorJSON.bool(value) == nil ? "expected true or false" : nil
        case .key: return BehaviorJSON.string(value) == nil ? "expected a blackboard key name" : nil
        case .text: return nil
        case .vector: return BehaviorJSON.vector(value) == nil ? "expected [x, y, z]" : nil
        case .points: return BehaviorJSON.points(value) == nil ? "expected [[x, y, z], ...]" : nil
        case .choice:
            guard let s = BehaviorJSON.string(value) else { return "expected one of \(spec.options.joined(separator: ", "))" }
            return spec.options.contains(s) ? nil : "'\(s)' is not one of \(spec.options.joined(separator: ", "))"
        }
    }
}

// MARK: Presets

/// Ready-made trees for `behavior.new {preset}` and the editor's preset picker.
public enum BehaviorPreset: String, Codable, CaseIterable, Sendable {
    /// A selector with one wait: a start to build on.
    case empty
    /// Walks between waypoints, pausing at each.
    case patrol
    /// Patrols; chases and attacks the target once it sees it; flees when hurt.
    case guardian = "guard"
    /// Chases the target when within range, otherwise waits.
    case chaser
    /// Runs away from the target when it comes close.
    case coward
}

extension BehaviorTree {
    public static func preset(_ preset: BehaviorPreset) -> BehaviorTree {
        let square: JSONValue = .array([.array([.int(-4), .int(0), .int(-4)]), .array([.int(4), .int(0), .int(-4)]), .array([.int(4), .int(0), .int(4)]), .array([.int(-4), .int(0), .int(4)])])
        switch preset {
        case .empty:
            return BehaviorTree(root: "root", nodes: [
                BehaviorNode("root", .selector, children: ["idle"]),
                BehaviorNode("idle", .wait, ["seconds": .int(1)]),
            ])
        case .patrol:
            return BehaviorTree(root: "root", nodes: [
                BehaviorNode("root", .sequence, children: ["patrol"]),
                BehaviorNode("patrol", .patrol, ["points": square, "relative": .bool(true), "wait": .int(1)]),
            ])
        case .guardian:
            return BehaviorTree(root: "root", nodes: [
                BehaviorNode("root", .selector, children: ["retreat", "fight", "patrol"]),
                BehaviorNode("retreat", .sequence, name: "Retreat when hurt", children: ["hurt", "flee"], ["memory": .bool(false)]),
                BehaviorNode("hurt", .healthBelow, ["value": .int(25)]),
                BehaviorNode("flee", .flee, ["safeDistance": .int(12)]),
                BehaviorNode("fight", .sequence, name: "Fight what it sees", children: ["see", "chase", "attack"], ["memory": .bool(false)]),
                BehaviorNode("see", .canSeeTarget, ["range": .int(10), "fov": .int(140)]),
                BehaviorNode("chase", .chase, ["stopDistance": .double(1.5), "speed": .int(4)]),
                BehaviorNode("attack", .attack, ["range": .int(2), "damage": .int(10), "cooldown": .int(1)]),
                BehaviorNode("patrol", .patrol, ["points": square, "relative": .bool(true), "wait": .int(1)]),
            ], blackboard: ["health": .int(100)])
        case .chaser:
            return BehaviorTree(root: "root", nodes: [
                BehaviorNode("root", .selector, children: ["hunt", "idle"]),
                BehaviorNode("hunt", .sequence, children: ["near", "chase"], ["memory": .bool(false)]),
                BehaviorNode("near", .withinRange, ["range": .int(12)]),
                BehaviorNode("chase", .chase, ["stopDistance": .double(1.2)]),
                BehaviorNode("idle", .wait, ["seconds": .double(0.5)]),
            ])
        case .coward:
            return BehaviorTree(root: "root", nodes: [
                BehaviorNode("root", .selector, children: ["escape", "idle"]),
                BehaviorNode("escape", .sequence, children: ["near", "flee"], ["memory": .bool(false)]),
                BehaviorNode("near", .withinRange, ["range": .int(6)]),
                BehaviorNode("flee", .flee, ["safeDistance": .int(10), "speed": .int(4)]),
                BehaviorNode("idle", .wait, ["seconds": .double(0.5)]),
            ])
        }
    }
}
