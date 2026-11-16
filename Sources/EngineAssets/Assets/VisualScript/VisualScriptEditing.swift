import Foundation
import EngineCore
import EngineScene

/// Changes to one node, by id: every field optional; `config` and `inputs` are merged (a null
/// value removes the key).
public struct VisualScriptNodePatch: Codable, Equatable, Sendable {
    public var id: String
    public var type: String?
    public var x: Float?
    public var y: Float?
    public var config: [String: JSONValue]?
    public var inputs: [String: JSONValue]?
    public var comment: String?
    public var breakpoint: Bool?
    public var collapsed: Bool?

    public init(id: String, type: String? = nil, x: Float? = nil, y: Float? = nil, config: [String: JSONValue]? = nil,
                inputs: [String: JSONValue]? = nil, comment: String? = nil, breakpoint: Bool? = nil, collapsed: Bool? = nil) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.config = config
        self.inputs = inputs
        self.comment = comment
        self.breakpoint = breakpoint
        self.collapsed = collapsed
    }
}

/// A function's new input and output pins (`VisualScriptEdit.signatures`). Wires and literal
/// values on the function's entry and return nodes and on every node calling it follow renamed
/// pins and are dropped for removed ones.
public struct VisualScriptFunctionSignature: Codable, Equatable, Sendable {
    public var function: String
    /// The new inputs (entry outputs, call inputs), in order; nil keeps them.
    public var inputs: [VisualScriptParameter]?
    /// The new outputs (return inputs, call outputs), in order; nil keeps them.
    public var outputs: [VisualScriptParameter]?
    /// Old name → new name of renamed inputs, and of renamed outputs.
    public var renamedInputs: [String: String]?
    public var renamedOutputs: [String: String]?

    public init(function: String, inputs: [VisualScriptParameter]? = nil, outputs: [VisualScriptParameter]? = nil,
                renamedInputs: [String: String]? = nil, renamedOutputs: [String: String]? = nil) {
        self.function = function
        self.inputs = inputs
        self.outputs = outputs
        self.renamedInputs = renamedInputs
        self.renamedOutputs = renamedOutputs
    }
}

/// A batch of changes to a graph, applied in this order: removeNodes, addNodes, updateNodes,
/// disconnect, connect (in the event graph, or in `function` when given), then variables,
/// removeVariables, functions, signatures, removeFunctions, comments, removeComments, actions.
public struct VisualScriptEdit: Codable, Equatable, Sendable {
    /// Edit the nodes and links of this function instead of the event graph.
    public var function: String?
    public var removeNodes: [String]?
    /// New nodes; an empty `id` gets one from the type ("branch1"). Nodes at (0, 0) are placed
    /// right of the existing ones.
    public var addNodes: [VisualScriptNode]?
    public var updateNodes: [VisualScriptNodePatch]?
    /// Links to remove; one with an empty `to` removes every link from `from`, an empty `from` every link into `to`.
    public var disconnect: [VisualScriptLink]?
    /// Links to add. A wire into a data input (or out of an exec output) that already has one replaces it.
    public var connect: [VisualScriptLink]?
    /// Variables to add or replace (by name).
    public var variables: [VisualScriptVariable]?
    public var removeVariables: [String]?
    /// Functions to add or replace (by name).
    public var functions: [VisualScriptFunction]?
    /// Changes to functions' input and output pins, keeping wires (see `VisualScriptFunctionSignature`).
    public var signatures: [VisualScriptFunctionSignature]?
    public var removeFunctions: [String]?
    /// Comment boxes to add or replace (by id; an empty id gets one).
    public var comments: [VisualScriptComment]?
    public var removeComments: [String]?
    /// Input actions to add or replace; an empty list removes one.
    public var actions: [String: [String]]?

    public init(function: String? = nil, removeNodes: [String]? = nil, addNodes: [VisualScriptNode]? = nil,
                updateNodes: [VisualScriptNodePatch]? = nil, disconnect: [VisualScriptLink]? = nil, connect: [VisualScriptLink]? = nil,
                variables: [VisualScriptVariable]? = nil, removeVariables: [String]? = nil, functions: [VisualScriptFunction]? = nil,
                signatures: [VisualScriptFunctionSignature]? = nil, removeFunctions: [String]? = nil, comments: [VisualScriptComment]? = nil, removeComments: [String]? = nil,
                actions: [String: [String]]? = nil) {
        self.function = function
        self.removeNodes = removeNodes
        self.addNodes = addNodes
        self.updateNodes = updateNodes
        self.disconnect = disconnect
        self.connect = connect
        self.variables = variables
        self.removeVariables = removeVariables
        self.functions = functions
        self.signatures = signatures
        self.removeFunctions = removeFunctions
        self.comments = comments
        self.removeComments = removeComments
        self.actions = actions
    }
}

public struct VisualScriptEditError: Error, CustomStringConvertible, Sendable {
    public var description: String
    public init(_ description: String) { self.description = description }
}

extension VisualScriptGraph {
    /// The graph with `edit` applied, and the ids of the added nodes (in order). Throws for
    /// edits that can't apply (an unknown node or function, a malformed pin).
    @MainActor
    public func applying(_ edit: VisualScriptEdit) throws -> (graph: VisualScriptGraph, added: [String]) {
        var graph = self
        var added: [String] = []
        if let name = edit.function {
            guard let index = graph.functions.firstIndex(where: { $0.name == name }) else { throw VisualScriptEditError("no function named '\(name)'") }
            var body = graph.functions[index]
            added = try Self.apply(edit, to: &body, graph: graph, function: graph.functions[index])
            graph.functions[index] = body
        } else {
            var body = graph
            added = try Self.apply(edit, to: &body, graph: graph, function: nil)
            graph.nodes = body.nodes
            graph.links = body.links
        }
        for variable in edit.variables ?? [] {
            guard !variable.name.isEmpty else { throw VisualScriptEditError("a variable needs a name") }
            if let i = graph.variables.firstIndex(where: { $0.name == variable.name }) { graph.variables[i] = variable } else { graph.variables.append(variable) }
        }
        for name in edit.removeVariables ?? [] { graph.variables.removeAll { $0.name == name } }
        for function in edit.functions ?? [] {
            guard !function.name.isEmpty else { throw VisualScriptEditError("a function needs a name") }
            if let i = graph.functions.firstIndex(where: { $0.name == function.name }) { graph.functions[i] = function } else { graph.functions.append(function) }
        }
        for signature in edit.signatures ?? [] { graph = try graph.setting(signature) }
        for name in edit.removeFunctions ?? [] { graph.functions.removeAll { $0.name == name } }
        for var comment in edit.comments ?? [] {
            if comment.id.isEmpty {
                var n = 1
                while graph.comments.contains(where: { $0.id == "comment\(n)" }) { n += 1 }
                comment.id = "comment\(n)"
            }
            if let i = graph.comments.firstIndex(where: { $0.id == comment.id }) { graph.comments[i] = comment } else { graph.comments.append(comment) }
        }
        for id in edit.removeComments ?? [] { graph.comments.removeAll { $0.id == id } }
        for (name, sources) in edit.actions ?? [:] { graph.actions[name] = sources.isEmpty ? nil : sources }
        return (graph, added)
    }

    /// The graph with a function's pins changed (`VisualScriptFunctionSignature`).
    public func setting(_ signature: VisualScriptFunctionSignature) throws -> VisualScriptGraph {
        guard let index = functions.firstIndex(where: { $0.name == signature.function }) else {
            throw VisualScriptEditError("no function named '\(signature.function)'")
        }
        let old = functions[index]
        let inputs = signature.inputs ?? old.inputs, outputs = signature.outputs ?? old.outputs
        for (side, list) in [("input", inputs), ("output", outputs)] {
            var seen = Set<String>()
            for parameter in list {
                let name = parameter.name
                guard !name.isEmpty, !name.contains("."), name != "in", name != "out" else {
                    throw VisualScriptEditError("function \(old.name): '\(name)' can't name an \(side) (empty, \"in\", \"out\" or with \".\")")
                }
                guard parameter.type != .exec else { throw VisualScriptEditError("function \(old.name): \(side) '\(name)' can't be exec") }
                guard seen.insert(name).inserted else { throw VisualScriptEditError("function \(old.name): two \(side)s named '\(name)'") }
            }
        }
        /// Where a pin of the old signature goes: its new name, or nil when it was removed.
        func mapper(_ renames: [String: String]?, _ new: [VisualScriptParameter], exec: String) -> (String) -> String? {
            let names = Set(new.map(\.name))
            return { pin in
                if pin == exec { return pin }
                let renamed = renames?[pin] ?? pin
                return names.contains(renamed) ? renamed : nil
            }
        }
        let mapInputsOut = mapper(signature.renamedInputs, inputs, exec: "out")   // entry outputs
        let mapInputsIn = mapper(signature.renamedInputs, inputs, exec: "in")     // call inputs
        let mapOutputsIn = mapper(signature.renamedOutputs, outputs, exec: "in")  // return inputs
        let mapOutputsOut = mapper(signature.renamedOutputs, outputs, exec: "out") // call outputs

        func rewrite(_ nodes: inout [VisualScriptNode], _ links: inout [VisualScriptLink], inFunction: Bool) {
            var outputMap: [String: (String) -> String?] = [:], inputMap: [String: (String) -> String?] = [:]
            for i in nodes.indices {
                let node = nodes[i]
                if inFunction && node.type == "function.entry" {
                    outputMap[node.id] = mapInputsOut
                } else if inFunction && node.type == "function.return" {
                    inputMap[node.id] = mapOutputsIn
                } else if node.type == "function.call", node.configString("function") == old.name {
                    inputMap[node.id] = mapInputsIn
                    outputMap[node.id] = mapOutputsOut
                } else {
                    continue
                }
                if let map = inputMap[node.id] {
                    var literals: [String: JSONValue] = [:]
                    for (pin, value) in node.inputs { if let moved = map(pin) { literals[moved] = value } }
                    nodes[i].inputs = literals
                }
            }
            links = links.compactMap { link in
                guard let from = link.source, let to = link.target else { return link }
                var link = link
                if let map = outputMap[from.node] {
                    guard let pin = map(from.pin) else { return nil }
                    link.from = from.node + "." + pin
                }
                if let map = inputMap[to.node] {
                    guard let pin = map(to.pin) else { return nil }
                    link.to = to.node + "." + pin
                }
                return link
            }
        }
        var graph = self
        rewrite(&graph.nodes, &graph.links, inFunction: false)
        for i in graph.functions.indices {
            var nodes = graph.functions[i].nodes, links = graph.functions[i].links
            rewrite(&nodes, &links, inFunction: i == index)
            graph.functions[i].nodes = nodes
            graph.functions[i].links = links
        }
        graph.functions[index].inputs = inputs
        graph.functions[index].outputs = outputs
        return graph
    }

    @MainActor
    private static func apply<Body: VisualScriptBody>(_ edit: VisualScriptEdit, to body: inout Body, graph: VisualScriptGraph,
                                                      function: VisualScriptFunction?) throws -> [String] {
        for id in edit.removeNodes ?? [] {
            guard body.node(id) != nil else { throw VisualScriptEditError("no node '\(id)'") }
            body.nodes.removeAll { $0.id == id }
            body.links.removeAll { $0.source?.node == id || $0.target?.node == id }
        }
        var added: [String] = []
        var placed = 0
        let right = (body.nodes.map(\.x).max() ?? -260) + 260
        let top = body.nodes.map(\.y).min() ?? 0
        for var node in edit.addNodes ?? [] {
            guard !node.type.isEmpty else { throw VisualScriptEditError("a new node needs a type") }
            if node.id.isEmpty { node.id = body.uniqueNodeID(node.type) }
            guard !node.id.contains(".") else { throw VisualScriptEditError("node ids can't contain \".\" ('\(node.id)')") }
            guard body.node(node.id) == nil else { throw VisualScriptEditError("a node '\(node.id)' already exists") }
            if node.x == 0 && node.y == 0 && !body.nodes.isEmpty {
                node.x = right + Float(placed / 4) * 260
                node.y = top + Float(placed % 4) * 140
                placed += 1
            }
            body.nodes.append(node)
            added.append(node.id)
        }
        for patch in edit.updateNodes ?? [] {
            guard let i = body.nodeIndex(patch.id) else { throw VisualScriptEditError("no node '\(patch.id)'") }
            var node = body.nodes[i]
            if let type = patch.type { node.type = type }
            if let x = patch.x { node.x = x }
            if let y = patch.y { node.y = y }
            for (key, value) in patch.config ?? [:] { node.config[key] = value == .null ? nil : value }
            for (key, value) in patch.inputs ?? [:] { node.inputs[key] = value == .null ? nil : value }
            if let comment = patch.comment { node.comment = comment.isEmpty ? nil : comment }
            if let breakpoint = patch.breakpoint { node.breakpoint = breakpoint }
            if let collapsed = patch.collapsed { node.collapsed = collapsed }
            body.nodes[i] = node
        }
        for link in edit.disconnect ?? [] {
            if link.to.isEmpty { body.links.removeAll { $0.from == link.from } } else if link.from.isEmpty { body.links.removeAll { $0.to == link.to } } else {
                body.links.removeAll { $0 == link }
            }
        }
        for link in edit.connect ?? [] {
            guard let from = link.source, let to = link.target else { throw VisualScriptEditError("link \(link.from) → \(link.to): pins are written \"node.pin\"") }
            guard let a = body.node(from.node) else { throw VisualScriptEditError("link \(link.from) → \(link.to): no node '\(from.node)'") }
            guard let b = body.node(to.node) else { throw VisualScriptEditError("link \(link.from) → \(link.to): no node '\(to.node)'") }
            let outType = VisualScriptNodes.definition(a.type)?.signature(for: a, in: graph, function: function).output(from.pin)?.type
            let inType = VisualScriptNodes.definition(b.type)?.signature(for: b, in: graph, function: function).input(to.pin)?.type
            if outType == .exec {
                body.links.removeAll { $0.from == link.from }
            } else if inType != nil && inType != .exec {
                body.links.removeAll { $0.to == link.to }
            }
            if !body.links.contains(link) { body.links.append(link) }
        }
        return added
    }
}

/// Starting points for new graphs (`vscript.new {template}`).
public enum VisualScriptTemplate: String, Codable, CaseIterable, Sendable {
    /// Start and update events, nothing else.
    case empty
    /// Turns the entity around Y at `speed` degrees per second.
    case spinner
    /// Moves the entity with WASD / arrows at `speed` meters per second.
    case mover
    /// A trigger pickup: plays a sound, counts, and removes itself when something enters.
    case pickup
    /// Logs a message every `interval` seconds.
    case timer

    public var graph: VisualScriptGraph {
        func n(_ id: String, _ type: String, _ x: Float, _ y: Float, config: [String: JSONValue] = [:], inputs: [String: JSONValue] = [:]) -> VisualScriptNode {
            VisualScriptNode(id: id, type: type, x: x, y: y, config: config, inputs: inputs)
        }
        func l(_ a: String, _ b: String) -> VisualScriptLink { VisualScriptLink(from: a, to: b) }
        switch self {
        case .empty:
            return VisualScriptGraph(nodes: [n("start", "event.start", 0, 0), n("update", "event.update", 0, 160)])
        case .spinner:
            return VisualScriptGraph(
                variables: [VisualScriptVariable(name: "speed", type: .float, defaultValue: .int(90), tooltip: "Degrees per second")],
                nodes: [n("update", "event.update", 0, 0), n("speed", "var.get", 0, 140, config: ["variable": .string("speed")]),
                        n("mul", "math.multiply", 220, 100), n("rotate", "transform.rotate", 440, 0, inputs: ["axis": .array([.int(0), .int(1), .int(0)])])],
                links: [l("update.out", "rotate.in"), l("update.dt", "mul.a"), l("speed.value", "mul.b"), l("mul.result", "rotate.degrees")])
        case .mover:
            return VisualScriptGraph(
                variables: [VisualScriptVariable(name: "speed", type: .float, defaultValue: .int(4), tooltip: "Meters per second")],
                nodes: [n("update", "event.update", 0, 0), n("input", "input.wasd", 0, 140), n("split", "vec2.break", 200, 140),
                        n("neg", "math.negate", 380, 200), n("dir", "vec3.make", 540, 140),
                        n("speed", "var.get", 540, 300, config: ["variable": .string("speed")]), n("mul", "math.multiply", 720, 160),
                        n("dt", "math.multiply", 880, 160), n("move", "transform.translate", 1060, 0)],
                links: [l("update.out", "move.in"), l("input.vector", "split.vector"), l("split.x", "dir.x"), l("split.y", "neg.value"),
                        l("neg.result", "dir.z"), l("dir.vector", "mul.a"), l("speed.value", "mul.b"), l("mul.result", "dt.a"),
                        l("update.dt", "dt.b"), l("dt.result", "move.offset")])
        case .pickup:
            return VisualScriptGraph(
                variables: [VisualScriptVariable(name: "sound", type: .asset, defaultValue: .string(""), tooltip: "Played on pickup (an audio file or .sfx)")],
                nodes: [n("enter", "event.triggerEnter", 0, 0), n("sound", "var.get", 0, 160, config: ["variable": .string("sound")]),
                        n("hasSound", "string.length", 200, 160), n("check", "compare.greater", 380, 160),
                        n("branch", "flow.branch", 560, 0), n("play", "audio.play", 760, -80),
                        n("send", "event.send", 980, 0, config: ["name": .string("pickup")]), n("destroy", "world.destroy", 1200, 0)],
                links: [l("enter.out", "branch.in"), l("sound.value", "hasSound.text"), l("hasSound.length", "check.a"),
                        l("check.result", "branch.condition"), l("branch.true", "play.in"), l("sound.value", "play.sound"),
                        l("play.out", "send.in"), l("branch.false", "send.in"), l("enter.other", "send.value"), l("send.out", "destroy.in")])
        case .timer:
            return VisualScriptGraph(
                nodes: [n("timer", "event.timer", 0, 0, config: ["interval": .int(1)]),
                        n("time", "time.elapsed", 0, 140), n("fmt", "string.format", 200, 120, inputs: ["format": .string("Tick at {a} s")]),
                        n("log", "debug.log", 420, 0)],
                links: [l("timer.out", "log.in"), l("time.time", "fmt.a"), l("fmt.text", "log.message")])
        }
    }
}
