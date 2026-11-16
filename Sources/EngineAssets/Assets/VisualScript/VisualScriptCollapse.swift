import Foundation
import EngineCore
import EngineScene

extension VisualScriptGraph {
    /// Moves the event graph's nodes `ids` into a new function `name` and puts a
    /// `function.call` node in their place: wires coming in become the function's inputs,
    /// wires going out its outputs, and the flow enters at the one exec input wired from
    /// outside and leaves at the one exec output wired to the outside. When no exec wire leaves
    /// the selection, the flow ends inside and the call's outputs are what is wired into the
    /// function's Return when it ends (see `VisualScriptRuntime.call`). Nodes without exec pins
    /// make a pure function. Throws when that doesn't fit (event nodes selected, flow
    /// entering at several places).
    @MainActor
    public func collapsingToFunction(_ ids: Set<String>, name: String) throws -> VisualScriptGraph {
        guard !ids.isEmpty else { throw VisualScriptEditError("select the nodes to collapse") }
        guard !name.isEmpty, function(name) == nil else { throw VisualScriptEditError("a function needs a new name ('\(name)' is taken)") }
        let selected = nodes.filter { ids.contains($0.id) }
        guard selected.count == ids.count else { throw VisualScriptEditError("some selected nodes don't exist") }
        for node in selected where VisualScriptNodes.definition(node.type)?.kind == .event {
            throw VisualScriptEditError("event node '\(node.id)' can't go into a function")
        }
        func type(_ ref: VisualScriptPinRef?, output: Bool) -> VisualScriptType {
            guard let ref, let node = node(ref.node), let definition = VisualScriptNodes.definition(node.type) else { return .any }
            let signature = definition.signature(for: node, in: self)
            return (output ? signature.output(ref.pin) : signature.input(ref.pin))?.type ?? .any
        }
        func isIn(_ ref: VisualScriptPinRef?) -> Bool { ref.map { ids.contains($0.node) } ?? false }
        let inside = links.filter { isIn($0.source) && isIn($0.target) }
        let incoming = links.filter { !isIn($0.source) && isIn($0.target) }
        let outgoing = links.filter { isIn($0.source) && !isIn($0.target) }
        let execIn = incoming.filter { type($0.target, output: false) == .exec }
        let execOut = outgoing.filter { type($0.source, output: true) == .exec }
        guard Set(execIn.map(\.to)).count <= 1 else { throw VisualScriptEditError("the flow enters the selection at several places") }
        guard Set(execOut.map(\.from)).count <= 1 else { throw VisualScriptEditError("the flow leaves the selection at several places") }
        let hasActions = selected.contains { VisualScriptNodes.definition($0.type)?.kind == .action }
        if hasActions && execIn.isEmpty { throw VisualScriptEditError("nothing runs the selected nodes: wire the flow into them first") }

        var function = VisualScriptFunction(name: name, nodes: selected, links: inside, pure: !hasActions)
        var used: Set<String> = ["in", "out"]
        func unique(_ base: String) -> String {
            var candidate = base, n = 2
            while used.contains(candidate) { candidate = "\(base)\(n)"; n += 1 }
            used.insert(candidate)
            return candidate
        }
        let minX = selected.map(\.x).min() ?? 0, maxX = selected.map(\.x).max() ?? 0
        let midY = selected.map(\.y).reduce(0, +) / Float(max(selected.count, 1))
        function.nodes.append(VisualScriptNode(id: "entry", type: "function.entry", x: minX - 260, y: midY))
        function.nodes.append(VisualScriptNode(id: "return", type: "function.return", x: maxX + 260, y: midY))
        let callID = uniqueNodeID("call")
        var outside = links.filter { !isIn($0.source) && !isIn($0.target) }

        if let target = execIn.first?.to {
            function.links.append(VisualScriptLink(from: "entry.out", to: target))
            for link in execIn { outside.append(VisualScriptLink(from: link.from, to: "\(callID).in")) }
        } else {
            function.links.append(VisualScriptLink(from: "entry.out", to: "return.in"))
        }
        if let source = execOut.first?.from {
            function.links.append(VisualScriptLink(from: source, to: "return.in"))
            for link in execOut { outside.append(VisualScriptLink(from: "\(callID).out", to: link.to)) }
        }
        var parameterFor: [String: String] = [:]
        for link in incoming where type(link.target, output: false) != .exec {
            let parameter: String
            if let existing = parameterFor[link.from] {
                parameter = existing
            } else {
                parameter = unique(link.target!.pin)
                parameterFor[link.from] = parameter
                function.inputs.append(VisualScriptParameter(name: parameter, type: type(link.target, output: false)))
                outside.append(VisualScriptLink(from: link.from, to: "\(callID).\(parameter)"))
            }
            function.links.append(VisualScriptLink(from: "entry.\(parameter)", to: link.to))
        }
        var resultFor: [String: String] = [:]
        for link in outgoing where type(link.source, output: true) != .exec {
            let result: String
            if let existing = resultFor[link.from] {
                result = existing
            } else {
                result = unique(link.source!.pin)
                resultFor[link.from] = result
                function.outputs.append(VisualScriptParameter(name: result, type: type(link.source, output: true)))
                function.links.append(VisualScriptLink(from: link.from, to: "return.\(result)"))
            }
            outside.append(VisualScriptLink(from: "\(callID).\(result)", to: link.to))
        }

        var graph = self
        graph.functions.append(function)
        graph.nodes.removeAll { ids.contains($0.id) }
        graph.nodes.append(VisualScriptNode(id: callID, type: "function.call", x: (minX + maxX) / 2, y: midY, config: ["function": .string(name)]))
        graph.links = outside
        return graph
    }
}
