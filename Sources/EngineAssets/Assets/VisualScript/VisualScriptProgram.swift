#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

// A graph prepared for the VM: node types looked up, pins resolved to indices and wires to
// (node, pin) pairs. Building one is a single pass over the file (no code generation), done
// whenever the file's revision changes, so edits apply on the next frame of a running game.

/// One node of a prepared body.
@MainActor
struct VSCompiledNode {
    let id: String
    let source: VisualScriptNode
    let definition: VisualScriptNodeDefinition?
    let inputs: [VisualScriptPin]
    let outputs: [VisualScriptPin]
    let inputIndex: [String: Int]
    let outputIndex: [String: Int]
    /// Per input: the output feeding it.
    var dataSource: [(node: Int, pin: Int)?]
    /// Per input: the literal from the file.
    var literal: [VisualScriptValue?]
    /// Per output (exec ones): the exec input it leads to.
    var next: [(node: Int, pin: Int)?]

    /// Computed when read: pure nodes, and nodes without exec pins (calls of pure functions).
    var isPure: Bool {
        definition?.kind == .pure
            || (definition?.kind == .action && !inputs.contains { $0.type == .exec } && !outputs.contains { $0.type == .exec })
    }
}

/// The event graph or one function, prepared.
@MainActor
final class VSCompiledBody {
    let name: String
    let function: VisualScriptFunction?
    var nodes: [VSCompiledNode] = []
    var index: [String: Int] = [:]
    /// The `function.entry` node of a function.
    var entry: Int?

    init(name: String, function: VisualScriptFunction?) {
        self.name = name
        self.function = function
    }
}

/// A `.vscript` graph ready to run. Shared by every entity that uses the graph.
@MainActor
public final class VisualScriptProgram {
    public let graph: VisualScriptGraph
    /// A name for log lines and the profiler (the file's path).
    public let name: String
    let main: VSCompiledBody
    let functions: [String: VSCompiledBody]
    /// Event name → event nodes of the event graph that run on it.
    let events: [String: [Int]]
    /// The graph's input actions, as bindings.
    let actionBindings: InputBindings?

    public init(graph: VisualScriptGraph, name: String = "graph") {
        self.graph = graph
        self.name = name
        main = Self.compile(graph.nodes, graph.links, graph: graph, function: nil)
        var functions: [String: VSCompiledBody] = [:]
        for function in graph.functions where functions[function.name] == nil {
            functions[function.name] = Self.compile(function.nodes, function.links, graph: graph, function: function)
        }
        self.functions = functions
        var events: [String: [Int]] = [:]
        for (i, node) in main.nodes.enumerated() {
            if let event = node.definition?.event { events[event, default: []].append(i) }
        }
        self.events = events
        if graph.actions.isEmpty {
            actionBindings = nil
        } else {
            var bindings = InputBindings()
            for name in graph.actions.keys.sorted() {
                let sources = graph.actions[name]!.compactMap(InputSource.init(code:))
                bindings.buttons.append(.init(name, sources))
            }
            actionBindings = bindings
        }
    }

    /// Whether any event node listens for `event`.
    public func handles(_ event: String) -> Bool { events[event] != nil }

    /// The ids of the event graph's nodes.
    public var nodeIDs: [String] { main.nodes.map(\.id) }

    static func compile(_ nodes: [VisualScriptNode], _ links: [VisualScriptLink], graph: VisualScriptGraph,
                        function: VisualScriptFunction?) -> VSCompiledBody {
        let (expandedNodes, expandedLinks) = VisualScriptMacros.expand(nodes, links, graph: graph)
        let (nodes, links) = VisualScriptReroute.resolve(expandedNodes, expandedLinks)
        let body = VSCompiledBody(name: function?.name ?? "", function: function)
        for source in nodes where body.index[source.id] == nil {
            let definition = VisualScriptNodes.definition(source.type)
            let signature = definition?.signature(for: source, in: graph, function: function) ?? VisualScriptSignature()
            var inputIndex: [String: Int] = [:]
            for (i, pin) in signature.inputs.enumerated() where inputIndex[pin.name] == nil { inputIndex[pin.name] = i }
            var outputIndex: [String: Int] = [:]
            for (i, pin) in signature.outputs.enumerated() where outputIndex[pin.name] == nil { outputIndex[pin.name] = i }
            let literal: [VisualScriptValue?] = signature.inputs.map { pin in
                source.inputs[pin.name].flatMap { VisualScriptValue(json: $0, as: pin.type) }
            }
            body.index[source.id] = body.nodes.count
            if source.type == "function.entry", body.entry == nil { body.entry = body.nodes.count }
            body.nodes.append(VSCompiledNode(
                id: source.id, source: source, definition: definition, inputs: signature.inputs, outputs: signature.outputs,
                inputIndex: inputIndex, outputIndex: outputIndex,
                dataSource: Array(repeating: nil, count: signature.inputs.count), literal: literal,
                next: Array(repeating: nil, count: signature.outputs.count)))
        }
        for link in links {
            guard let from = link.source, let to = link.target, let a = body.index[from.node], let b = body.index[to.node],
                  let outPin = body.nodes[a].outputIndex[from.pin], let inPin = body.nodes[b].inputIndex[to.pin] else { continue }
            let outType = body.nodes[a].outputs[outPin].type, inType = body.nodes[b].inputs[inPin].type
            guard outType.converts(to: inType) else { continue }
            if outType == .exec {
                body.nodes[a].next[outPin] = (b, inPin)
            } else {
                body.nodes[b].dataSource[inPin] = (a, outPin)
            }
        }
        return body
    }
}

extension InputSource {
    /// Parses the codes `InputSource` encodes to ("key.space", "mouse.left", "pad.south", "axis.leftX+").
    init?(code: String) {
        guard let data = try? JSONEncoder().encode(code), let source = try? JSONDecoder().decode(InputSource.self, from: data) else { return nil }
        self = source
    }
}
