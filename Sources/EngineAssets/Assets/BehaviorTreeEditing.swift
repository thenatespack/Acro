import Foundation
import EngineCore
import EngineScene

/// A link between a parent node and a child: `connect` puts `child` under `parent` (at
/// `index`, default the end), moving it from any other parent; `disconnect` removes the link.
public struct BehaviorConnection: Codable, Equatable, Sendable {
    public var parent: String
    public var child: String
    public var index: Int?

    public init(parent: String, child: String, index: Int? = nil) {
        self.parent = parent
        self.child = child
        self.index = index
    }
}

/// Changes to a tree, applied in this order: removeNodes, addNodes, updateNodes, disconnect,
/// connect, root, blackboard, settings. What `behavior.edit` takes.
public struct BehaviorTreeEdit: Codable, Equatable, Sendable {
    /// Node ids to delete (with their links; their children stay, unparented).
    public var removeNodes: [String]?
    /// Nodes to add (an empty or taken id gets a fresh one from the type). Their `children` may
    /// name other added nodes; ids renamed on the way are followed.
    public var addNodes: [BehaviorNode]?
    /// Node id → fields to change: `type`, `name`, `children`, `id` (renames; links follow) or
    /// any parameter (null removes it, back to the default).
    public var updateNodes: [String: JSONValue]?
    public var disconnect: [BehaviorConnection]?
    public var connect: [BehaviorConnection]?
    /// The new root id.
    public var root: String?
    /// Blackboard keys to set (null removes a key).
    public var blackboard: [String: JSONValue]?
    public var speed: Double?
    public var turnSpeed: Double?
    public var tickRate: Double?

    public init(removeNodes: [String]? = nil, addNodes: [BehaviorNode]? = nil, updateNodes: [String: JSONValue]? = nil,
                disconnect: [BehaviorConnection]? = nil, connect: [BehaviorConnection]? = nil, root: String? = nil,
                blackboard: [String: JSONValue]? = nil, speed: Double? = nil, turnSpeed: Double? = nil, tickRate: Double? = nil) {
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
    }
}

public enum BehaviorTreeEditError: Error, CustomStringConvertible, Equatable {
    case noNode(String)
    case idTaken(String)
    case cycle(parent: String, child: String)
    case badField(String)

    public var description: String {
        switch self {
        case .noNode(let id): "no node '\(id)'"
        case .idTaken(let id): "the id '\(id)' is already used"
        case .cycle(let parent, let child): "putting '\(child)' under '\(parent)' would make a cycle"
        case .badField(let message): message
        }
    }
}

extension BehaviorTree {
    /// The tree with `edit` applied. Throws (changing nothing) when it names a missing node,
    /// renames onto a taken id or would make a cycle.
    public func applying(_ edit: BehaviorTreeEdit) throws -> BehaviorTree {
        var tree = self
        for id in edit.removeNodes ?? [] {
            guard tree.index(of: id) != nil else { throw BehaviorTreeEditError.noNode(id) }
            tree.removeNode(id)
        }
        var renamed: [String: String] = [:]
        var added: [Int] = []
        for var node in edit.addNodes ?? [] {
            let wanted = node.id
            node.id = tree.uniqueID(node.id.isEmpty ? node.type : node.id)
            if !wanted.isEmpty, wanted != node.id { renamed[wanted] = node.id }
            tree.nodes.append(node)
            added.append(tree.nodes.count - 1)
        }
        for i in added { tree.nodes[i].children = tree.nodes[i].children.map { renamed[$0] ?? $0 } }
        func resolve(_ id: String) -> String { renamed[id] ?? id }

        for (id, fields) in (edit.updateNodes ?? [:]).sorted(by: { $0.key < $1.key }) {
            let id = resolve(id)
            guard let i = tree.index(of: id) else { throw BehaviorTreeEditError.noNode(id) }
            guard case .object(let object) = fields else { throw BehaviorTreeEditError.badField("updateNodes.\(id) must be an object") }
            for (key, value) in object.sorted(by: { $0.key < $1.key }) {
                switch key {
                case "id":
                    guard let new = BehaviorJSON.string(value), !new.isEmpty else { throw BehaviorTreeEditError.badField("id must be text") }
                    try tree.renameNode(tree.nodes[i].id, to: new)
                case "type":
                    guard let type = BehaviorJSON.string(value) else { throw BehaviorTreeEditError.badField("type must be text") }
                    tree.nodes[i].type = type
                case "name": tree.nodes[i].name = BehaviorJSON.string(value) ?? ""
                case "children":
                    guard case .array(let items) = value else { throw BehaviorTreeEditError.badField("children must be a list of ids") }
                    tree.nodes[i].children = items.compactMap(BehaviorJSON.string).map(resolve)
                default:
                    if value == .null { tree.nodes[i].params[key] = nil } else { tree.nodes[i].params[key] = value }
                }
            }
        }
        for link in edit.disconnect ?? [] {
            guard let p = tree.index(of: resolve(link.parent)) else { throw BehaviorTreeEditError.noNode(link.parent) }
            tree.nodes[p].children.removeAll { $0 == resolve(link.child) }
        }
        for link in edit.connect ?? [] {
            try tree.connect(resolve(link.child), to: resolve(link.parent), at: link.index)
        }
        if let root = edit.root {
            let root = resolve(root)
            guard root.isEmpty || tree.index(of: root) != nil else { throw BehaviorTreeEditError.noNode(root) }
            tree.root = root
        }
        for (key, value) in edit.blackboard ?? [:] {
            if value == .null { tree.blackboard[key] = nil } else { tree.blackboard[key] = value }
        }
        if let speed = edit.speed { tree.speed = speed }
        if let turnSpeed = edit.turnSpeed { tree.turnSpeed = turnSpeed }
        if let tickRate = edit.tickRate { tree.tickRate = tickRate }
        return tree
    }

    /// Deletes the node `id` and every link to it (its children stay, unparented).
    public mutating func removeNode(_ id: String) {
        nodes.removeAll { $0.id == id }
        for i in nodes.indices { nodes[i].children.removeAll { $0 == id } }
        if root == id { root = "" }
    }

    /// Deletes `id` and everything under it that no other node outside the subtree uses.
    public mutating func removeSubtree(_ id: String) {
        let doomed = subtree(id)
        nodes.removeAll { doomed.contains($0.id) }
        for i in nodes.indices { nodes[i].children.removeAll { doomed.contains($0) } }
        if doomed.contains(root) { root = "" }
    }

    /// Renames a node; links and the root follow.
    public mutating func renameNode(_ id: String, to new: String) throws {
        guard id != new else { return }
        guard let i = index(of: id) else { throw BehaviorTreeEditError.noNode(id) }
        guard index(of: new) == nil else { throw BehaviorTreeEditError.idTaken(new) }
        nodes[i].id = new
        for k in nodes.indices { nodes[k].children = nodes[k].children.map { $0 == id ? new : $0 } }
        if root == id { root = new }
    }

    /// Puts `child` under `parent` at `index` (default the end), taking it from any other parent.
    public mutating func connect(_ child: String, to parent: String, at index: Int? = nil) throws {
        guard let p = self.index(of: parent) else { throw BehaviorTreeEditError.noNode(parent) }
        guard self.index(of: child) != nil else { throw BehaviorTreeEditError.noNode(child) }
        guard !subtree(child).contains(parent) else { throw BehaviorTreeEditError.cycle(parent: parent, child: child) }
        var at = index ?? nodes[p].children.count
        if let old = nodes[p].children.firstIndex(of: child), old < at { at -= 1 }
        for k in nodes.indices { nodes[k].children.removeAll { $0 == child } }
        nodes[p].children.insert(child, at: max(0, min(at, nodes[p].children.count)))
        if root == child { root = "" }
    }

    /// Adds a node of `kind` under `parent` (or as the root when the tree is empty) and returns its id.
    @discardableResult
    public mutating func addNode(_ kind: BehaviorNodeKind, under parent: String?, at index: Int? = nil) -> String {
        let id = uniqueID(kind.rawValue)
        nodes.append(BehaviorNode(id, kind))
        if let parent, (try? connect(id, to: parent, at: index)) != nil { return id }
        if rootID == nil || nodes.count == 1 { root = id }
        return id
    }

    /// Moves `id` one place up (-1) or down (+1) among its siblings.
    public mutating func moveNode(_ id: String, by offset: Int) {
        guard let parent = parent(of: id), let p = index(of: parent), let i = nodes[p].children.firstIndex(of: id) else { return }
        let j = i + offset
        guard nodes[p].children.indices.contains(j) else { return }
        nodes[p].children.swapAt(i, j)
    }
}
