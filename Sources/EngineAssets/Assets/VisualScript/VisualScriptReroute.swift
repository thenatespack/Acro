import Foundation
import EngineCore
import EngineScene

// Reroute points: `reroute` nodes, small dots that bend a wire (exec or data) so busy graphs
// stay readable. A reroute takes the type of the wire coming into it (exec, or the data type).
// They cost nothing at run time: the compiler joins the wires through them into direct wires
// (`VisualScriptReroute.resolve`), so a flow or a value passes as if the reroute weren't there.

@MainActor
public enum VisualScriptReroute {
    /// The node type of reroute points.
    public static let type = "reroute"

    static func definitions() -> [VSDef] {
        [
            VSDef(id: type, title: "Reroute", category: "Flow",
                  doc: "A point that bends a wire (exec or data); it takes the type of the wire coming in. Drop one on a wire, or wire through it.",
                  kind: .pure,
                  signature: { context in
                      let type = pinType(of: context.node.id, nodes: context.function?.nodes ?? context.graph.nodes,
                                         links: context.function?.links ?? context.graph.links, graph: context.graph, function: context.function)
                      if type == .exec { return VisualScriptSignature(inputs: [.exec("in")], outputs: [.exec("out")]) }
                      return VisualScriptSignature(inputs: [VSPin("in", type)], outputs: [VSPin("out", type)])
                  },
                  run: { c in
                      // Only reached if something runs a reroute directly (the compiler removes them).
                      c.set("out", try c.input("in"))
                      return .stop
                  }),
        ]
    }

    /// The type of reroute `id`: the type of the output wired into it (through other reroutes),
    /// else of the input it feeds, else `any`.
    static func pinType(of id: String, nodes: [VisualScriptNode], links: [VisualScriptLink], graph: VisualScriptGraph,
                        function: VisualScriptFunction?) -> VisualScriptType {
        let byID = Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        func signature(_ node: VisualScriptNode) -> VisualScriptSignature? {
            VisualScriptNodes.definition(node.type)?.signature(for: node, in: graph, function: function)
        }
        var seen: Set<String> = []
        // Upstream: follow the wire into the reroute.
        var current = id
        while seen.insert(current).inserted {
            guard let link = links.first(where: { $0.target?.node == current && $0.target?.pin == "in" }),
                  let source = link.source, let node = byID[source.node] else { break }
            if node.type == type { current = node.id; continue }
            if let pin = signature(node)?.output(source.pin) { return pin.type }
            break
        }
        // Downstream: the first non-reroute input it feeds.
        var queue = [id]
        seen = []
        while let next = queue.popLast() {
            guard seen.insert(next).inserted else { continue }
            for link in links where link.source?.node == next && link.source?.pin == "out" {
                guard let target = link.target, let node = byID[target.node] else { continue }
                if node.type == type { queue.append(node.id); continue }
                if let pin = signature(node)?.input(target.pin) { return pin.type }
            }
        }
        return .any
    }

    /// `nodes` and `links` with reroutes removed and the wires through them joined: every source
    /// wired into a reroute (through chains of them) is wired to every target the reroute feeds.
    static func resolve(_ nodes: [VisualScriptNode], _ links: [VisualScriptLink]) -> ([VisualScriptNode], [VisualScriptLink]) {
        let reroutes = Set(nodes.filter { $0.type == type }.map(\.id))
        guard !reroutes.isEmpty else { return (nodes, links) }
        var into: [String: [String]] = [:]  // reroute id → the `from`s wired into it
        for link in links { if let target = link.target, reroutes.contains(target.node) { into[target.node, default: []].append(link.from) } }
        func sources(_ from: String, _ visiting: Set<String> = []) -> [String] {
            guard let node = VisualScriptPinRef(from)?.node, reroutes.contains(node) else { return [from] }
            guard !visiting.contains(node) else { return [] }
            return (into[node] ?? []).flatMap { sources($0, visiting.union([node])) }
        }
        var resolved: [VisualScriptLink] = []
        for link in links {
            guard let target = link.target, !reroutes.contains(target.node) else { continue }
            for from in sources(link.from) where !resolved.contains(VisualScriptLink(from: from, to: link.to)) {
                resolved.append(VisualScriptLink(from: from, to: link.to))
            }
        }
        return (nodes.filter { !reroutes.contains($0.id) }, resolved)
    }
}
