import Foundation
import EngineCore
import EngineScene

// Macros: functions marked `macro`, inlined where they're used. When a body is prepared, every
// `function.call` of a macro is replaced by a copy of the macro's nodes (ids "<use>/<node>"),
// and the macro's entry and return pins become reroute junctions the compiler then joins
// (`VisualScriptReroute.resolve`): a flow wired into the use's exec input `p` continues at what
// the entry's `p` leads to, and what reaches the return's exec input `q` continues at what the
// use's `q` leads to. Data pins work the same way. Each use has its own copy, so latent nodes
// (delays) and stateful ones (gates, do-once) work per use, which functions (one call frame
// per call) can't do.

@MainActor
enum VisualScriptMacros {
    /// How deep macros may use macros before the rest are left alone (a macro using itself).
    static let maxDepth = 16

    static func expand(_ nodes: [VisualScriptNode], _ links: [VisualScriptLink], graph: VisualScriptGraph) -> ([VisualScriptNode], [VisualScriptLink]) {
        var nodes = nodes, links = links
        for _ in 0..<maxDepth {
            let uses = nodes.filter { node in
                node.type == "function.call" && node.configString("function").flatMap(graph.function)?.macro == true
            }
            guard !uses.isEmpty else { break }
            for use in uses { inline(use, graph.function(use.configString("function")!)!, nodes: &nodes, links: &links) }
        }
        return (nodes, links)
    }

    private static func inline(_ use: VisualScriptNode, _ macro: VisualScriptFunction, nodes: inout [VisualScriptNode], links: inout [VisualScriptLink]) {
        let prefix = use.id + "/"
        let entries = Set(macro.nodes.filter { $0.type == "function.entry" }.map(\.id))
        let returns = Set(macro.nodes.filter { $0.type == "function.return" }.map(\.id))
        func junctionIn(_ pin: String) -> String { prefix + ">" + pin }
        func junctionOut(_ pin: String) -> String { prefix + "<" + pin }

        nodes.removeAll { $0.id == use.id }
        for node in macro.nodes where !entries.contains(node.id) && !returns.contains(node.id) {
            var copy = node
            copy.id = prefix + node.id
            copy.breakpoint = false
            nodes.append(copy)
        }
        for pin in macro.inputs { nodes.append(VisualScriptNode(id: junctionIn(pin.name), type: VisualScriptReroute.type)) }
        for pin in macro.outputs { nodes.append(VisualScriptNode(id: junctionOut(pin.name), type: VisualScriptReroute.type)) }

        // Wires of the body to and from the use go to its junctions.
        var wiredInputs = Set<String>()
        links = links.map { link in
            var link = link
            if let to = link.target, to.node == use.id {
                link.to = junctionIn(to.pin) + ".in"
                wiredInputs.insert(to.pin)
            }
            if let from = link.source, from.node == use.id { link.from = junctionOut(from.pin) + ".out" }
            return link
        }
        // The macro's own wires, entry and return replaced by the junctions.
        for link in macro.links {
            guard let from = link.source, let to = link.target else { continue }
            let source = entries.contains(from.node) ? junctionIn(from.pin) + ".out" : prefix + link.from
            let target = returns.contains(to.node) ? junctionOut(to.pin) + ".in" : prefix + link.to
            links.append(VisualScriptLink(from: source, to: target))
            // A literal typed on the use's input reaches the pins its entry pin feeds.
            if entries.contains(from.node), !wiredInputs.contains(from.pin), !returns.contains(to.node), let value = use.inputs[from.pin],
               let i = nodes.firstIndex(where: { $0.id == prefix + to.node }) {
                nodes[i].inputs[to.pin] = value
            }
        }
    }
}
