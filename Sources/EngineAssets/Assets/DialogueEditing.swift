import Foundation
import EngineCore
import EngineScene

/// A link to make: from a node to another. For a `choice` node, `choice` picks the option whose
/// `next` is set; with no `choice` but a `text`, a new option is added. For a `condition` node
/// `branch: "else"` sets where it goes when false. Otherwise it sets `next`. An empty `to`
/// removes the link.
public struct DialogueConnection: Codable, Equatable, Sendable {
    public var from: String
    public var to: String
    /// The option index of a choice node.
    public var choice: Int?
    /// The text of a new option (choice nodes, when `choice` is omitted).
    public var text: String?
    /// "next" (default) or "else".
    public var branch: String?

    public init(from: String, to: String, choice: Int? = nil, text: String? = nil, branch: String? = nil) {
        self.from = from
        self.to = to
        self.choice = choice
        self.text = text
        self.branch = branch
    }
}

/// A batch of changes to a dialogue, applied in the order of the fields.
public struct DialogueEdit: Codable, Equatable, Sendable {
    /// Speakers to add, or replace by id.
    public var speakers: [DialogueSpeaker]?
    public var removeSpeakers: [String]?
    /// Variables to add, or replace by name.
    public var variables: [DialogueVariable]?
    public var removeVariables: [String]?
    /// Node ids to remove (links to them are cleared).
    public var removeNodes: [String]?
    /// Nodes to add. An empty or taken id gets a fresh one (the type's name plus a number);
    /// nodes without a `position` are placed right of what links to them.
    public var addNodes: [DialogueNode]?
    /// Node id → fields to change, e.g. {"hello": {"text": "Hi!", "next": "ask"}}. An "id" key
    /// renames the node (links follow); null resets a field.
    public var updateNodes: [String: JSONValue]?
    /// Links to make (see `DialogueConnection`).
    public var connect: [DialogueConnection]?
    /// The start node.
    public var start: String?
    /// Fill in missing localization keys as "<prefix>.<node>" and "<prefix>.<node>.<option>".
    public var generateKeys: String?
    /// Place every node again in columns by distance from the start.
    public var layout: Bool?

    public init(speakers: [DialogueSpeaker]? = nil, removeSpeakers: [String]? = nil, variables: [DialogueVariable]? = nil,
                removeVariables: [String]? = nil, removeNodes: [String]? = nil, addNodes: [DialogueNode]? = nil,
                updateNodes: [String: JSONValue]? = nil, connect: [DialogueConnection]? = nil, start: String? = nil,
                generateKeys: String? = nil, layout: Bool? = nil) {
        self.speakers = speakers
        self.removeSpeakers = removeSpeakers
        self.variables = variables
        self.removeVariables = removeVariables
        self.removeNodes = removeNodes
        self.addNodes = addNodes
        self.updateNodes = updateNodes
        self.connect = connect
        self.start = start
        self.generateKeys = generateKeys
        self.layout = layout
    }
}

extension DialogueAsset {
    /// Column and row spacing of automatic placement, in graph points.
    public static let layoutSpacing = Vec2(260, 120)

    /// This dialogue with `edit` applied. Throws for edits that can't apply (an unknown node to
    /// update or connect, a rename onto a taken id, a bad field value).
    public func applying(_ edit: DialogueEdit) throws -> DialogueAsset {
        var d = self
        for speaker in edit.speakers ?? [] {
            if let i = d.speakers.firstIndex(where: { $0.id == speaker.id }) { d.speakers[i] = speaker } else { d.speakers.append(speaker) }
        }
        if let remove = edit.removeSpeakers { d.speakers.removeAll { remove.contains($0.id) } }
        for variable in edit.variables ?? [] {
            if let i = d.variables.firstIndex(where: { $0.name == variable.name }) { d.variables[i] = variable } else { d.variables.append(variable) }
        }
        if let remove = edit.removeVariables { d.variables.removeAll { remove.contains($0.name) } }
        if let remove = edit.removeNodes, !remove.isEmpty {
            let gone = Set(remove)
            d.nodes.removeAll { gone.contains($0.id) }
            d.retarget { gone.contains($0) ? "" : $0 }
            if gone.contains(d.start) { d.start = "" }
        }
        for var node in edit.addNodes ?? [] {
            if node.id.isEmpty || d.nodeIndex(node.id) != nil { node.id = d.uniqueNodeID(node.id.isEmpty ? node.type.rawValue : node.id) }
            d.nodes.append(node)
        }
        for (id, fields) in (edit.updateNodes ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let i = d.nodeIndex(id) else { throw DialogueError("no node '\(id)' to update") }
            guard case .object(let changes) = fields else { throw DialogueError("updateNodes['\(id)'] must be an object of fields") }
            var object: [String: JSONValue]
            if case .object(let current)? = try? AssetJSON.value(d.nodes[i]) { object = current } else { object = [:] }
            for (key, value) in changes {
                if value == .null { object[key] = nil } else { object[key] = value }
            }
            object["id"] = object["id"] ?? .string(id)
            let updated: DialogueNode
            do { updated = try AssetJSON.decode(DialogueNode.self, from: .object(object)) } catch {
                throw DialogueError("node '\(id)': \(Self.describe(error))")
            }
            if updated.id != id {
                guard !updated.id.isEmpty, d.nodeIndex(updated.id) == nil else { throw DialogueError("can't rename '\(id)' to '\(updated.id)': empty or taken") }
                d.nodes[i] = updated
                d.retarget { $0 == id ? updated.id : $0 }
                if d.start == id { d.start = updated.id }
            } else {
                d.nodes[i] = updated
            }
        }
        for connection in edit.connect ?? [] { try d.connect(connection) }
        if let start = edit.start {
            guard start.isEmpty || d.nodeIndex(start) != nil else { throw DialogueError("no node '\(start)' to start at") }
            d.start = start
        }
        if let prefix = edit.generateKeys { d.generateKeys(prefix: prefix) }
        if edit.layout == true { for i in d.nodes.indices { d.nodes[i].position = nil } }
        d.placeUnpositionedNodes()
        return d
    }

    /// Makes one link (see `DialogueConnection`).
    public mutating func connect(_ connection: DialogueConnection) throws {
        guard let i = nodeIndex(connection.from) else { throw DialogueError("no node '\(connection.from)' to connect from") }
        guard connection.to.isEmpty || nodeIndex(connection.to) != nil else { throw DialogueError("no node '\(connection.to)' to connect to") }
        switch nodes[i].type {
        case .choice where connection.choice != nil:
            let k = connection.choice!
            guard nodes[i].choices.indices.contains(k) else { throw DialogueError("node '\(connection.from)' has no option \(k)") }
            nodes[i].choices[k].next = connection.to
            if let text = connection.text { nodes[i].choices[k].text = text }
        case .choice where connection.text != nil:
            nodes[i].choices.append(DialogueChoice(text: connection.text ?? "", next: connection.to))
        case .condition where connection.branch == "else":
            nodes[i].elseNext = connection.to
        case .end:
            throw DialogueError("node '\(connection.from)' is an end node: it has no links")
        default:
            guard connection.branch == nil || connection.branch == "next" else {
                throw DialogueError("branch '\(connection.branch!)' only applies to condition nodes (\"else\")")
            }
            nodes[i].next = connection.to
        }
    }

    /// Changes every link target with `map`.
    mutating func retarget(_ map: (String) -> String) {
        for i in nodes.indices {
            nodes[i].next = map(nodes[i].next)
            nodes[i].elseNext = map(nodes[i].elseNext)
            for k in nodes[i].choices.indices { nodes[i].choices[k].next = map(nodes[i].choices[k].next) }
        }
    }

    /// Fills in missing localization keys: "<prefix>.<node>" for lines and prompts,
    /// "<prefix>.<node>.<option>" for options. An empty prefix leaves the prefix out.
    public mutating func generateKeys(prefix: String) {
        let lead = prefix.isEmpty ? "" : prefix + "."
        for i in nodes.indices {
            let id = nodes[i].id
            if nodes[i].key.isEmpty, !nodes[i].text.isEmpty, nodes[i].type == .line || nodes[i].type == .choice { nodes[i].key = lead + id }
            for k in nodes[i].choices.indices where nodes[i].choices[k].key.isEmpty { nodes[i].choices[k].key = "\(lead)\(id).\(k)" }
        }
    }

    /// Gives each node without a position one: in a column by its distance (in links) from the
    /// start, below the column's other nodes.
    public mutating func placeUnpositionedNodes() {
        guard nodes.contains(where: { $0.position == nil }) else { return }
        var depth: [String: Int] = [:]
        var queue: [String] = []
        if let first = startNode, nodeIndex(first) != nil { depth[first] = 0; queue.append(first) }
        // Unreached nodes start their own trees, in file order.
        var cursor = 0
        var pending = nodes.map(\.id)
        while true {
            while cursor < queue.count {
                let id = queue[cursor]
                cursor += 1
                guard let node = node(id) else { continue }
                for (_, target) in node.links where depth[target] == nil && nodeIndex(target) != nil {
                    depth[target] = depth[id]! + 1
                    queue.append(target)
                }
            }
            pending.removeAll { depth[$0] != nil }
            guard let next = pending.first else { break }
            // Root an unreached node right of its positioned parent, else at column 0.
            let parent = nodes.first { n in n.links.contains { $0.target == next } && depth[n.id] != nil }
            depth[next] = parent.map { depth[$0.id]! + 1 } ?? 0
            queue.append(next)
        }
        let spacing = Self.layoutSpacing
        var bottom: [Int: Float] = [:]
        for node in nodes {
            guard let p = node.position else { continue }
            let column = Int((p.x / spacing.x).rounded())
            bottom[column] = max(bottom[column] ?? -.infinity, p.y + spacing.y)
        }
        for i in nodes.indices where nodes[i].position == nil {
            let column = depth[nodes[i].id] ?? 0
            let y = bottom[column] ?? 0
            nodes[i].position = Vec2(Float(column) * spacing.x, y)
            bottom[column] = y + spacing.y
        }
    }

    static func describe(_ error: Error) -> String {
        if let error = error as? DecodingError {
            switch error {
            case .typeMismatch(_, let c), .valueNotFound(_, let c), .dataCorrupted(let c):
                let path = c.codingPath.map(\.stringValue).joined(separator: ".")
                return path.isEmpty ? c.debugDescription : "\(path): \(c.debugDescription)"
            case .keyNotFound(let key, _): return "missing \(key.stringValue)"
            @unknown default: return "\(error)"
            }
        }
        return "\(error)"
    }
}
