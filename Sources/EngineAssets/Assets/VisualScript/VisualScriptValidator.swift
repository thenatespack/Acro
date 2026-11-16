import Foundation
import EngineCore
import EngineScene

/// A problem with a graph, shown on its node in the editor and returned by the tools.
public struct VisualScriptIssue: Codable, Equatable, Sendable, CustomStringConvertible {
    public enum Severity: String, Codable, Sendable {
        /// The graph can't run this part (unknown node, bad wire).
        case error
        /// Probably a mistake (unconnected required input, unreachable node).
        case warning
        /// Worth knowing (an unused pure node).
        case info
    }

    public var severity: Severity
    /// The function the node is in (nil: the event graph).
    public var function: String?
    public var node: String?
    public var pin: String?
    public var message: String

    public init(_ severity: Severity, function: String? = nil, node: String? = nil, pin: String? = nil, _ message: String) {
        self.severity = severity
        self.function = function
        self.node = node
        self.pin = pin
        self.message = message
    }

    public var description: String {
        var parts: [String] = []
        if let function { parts.append("function \(function)") }
        if let node { parts.append("node \(node)" + (pin.map { ".\($0)" } ?? "")) }
        return (parts.isEmpty ? "" : parts.joined(separator: ", ") + ": ") + message
    }
}

/// Checks graphs: unknown node types, wires to missing pins or between incompatible types,
/// unconnected required inputs, literals that don't fit their pin, unreachable nodes, unknown
/// variables and functions.
public enum VisualScriptValidator {
    /// Every problem with `graph`.
    @MainActor
    public static func validate(_ graph: VisualScriptGraph) -> [VisualScriptIssue] {
        var issues = structuralIssues(graph)
        var names = Set<String>()
        for variable in graph.variables {
            if variable.name.isEmpty { issues.append(VisualScriptIssue(.error, "a variable has no name")) }
            if !names.insert(variable.name).inserted { issues.append(VisualScriptIssue(.error, "variable '\(variable.name)' is declared twice")) }
            if variable.type == .exec { issues.append(VisualScriptIssue(.error, "variable '\(variable.name)' can't be of type exec")) }
            if let value = variable.defaultValue, !VisualScriptValue.isLiteral(value, of: variable.type) {
                issues.append(VisualScriptIssue(.warning, "variable '\(variable.name)': default doesn't fit type \(variable.type.rawValue)"))
            }
        }
        issues += bodyIssues(graph, graph.nodes, graph.links, function: nil)
        for function in graph.functions {
            issues += bodyIssues(graph, function.nodes, function.links, function: function)
            if !function.nodes.contains(where: { $0.type == "function.entry" }) {
                issues.append(VisualScriptIssue(.warning, function: function.name, "has no function.entry node: calls do nothing"))
            }
        }
        return issues
    }

    /// Problems that don't need the node types: ids, links' form, duplicate names. Safe off the main actor.
    public static func structuralIssues(_ graph: VisualScriptGraph) -> [VisualScriptIssue] {
        var issues: [VisualScriptIssue] = []
        func body(_ nodes: [VisualScriptNode], _ links: [VisualScriptLink], _ function: String?) {
            var ids = Set<String>()
            for node in nodes {
                if node.id.isEmpty { issues.append(VisualScriptIssue(.error, function: function, "a \(node.type) node has no id")) }
                if node.id.contains(".") { issues.append(VisualScriptIssue(.error, function: function, node: node.id, "ids can't contain \".\"")) }
                if !ids.insert(node.id).inserted { issues.append(VisualScriptIssue(.error, function: function, node: node.id, "id used by two nodes")) }
                if node.type.isEmpty { issues.append(VisualScriptIssue(.error, function: function, node: node.id, "no type")) }
            }
            for link in links {
                guard let from = link.source, let to = link.target else {
                    issues.append(VisualScriptIssue(.error, function: function, "link \(link.from) → \(link.to): pins are written \"node.pin\""))
                    continue
                }
                if !ids.contains(from.node) { issues.append(VisualScriptIssue(.error, function: function, "link \(link.from) → \(link.to): no node '\(from.node)'")) }
                if !ids.contains(to.node) { issues.append(VisualScriptIssue(.error, function: function, "link \(link.from) → \(link.to): no node '\(to.node)'")) }
            }
        }
        body(graph.nodes, graph.links, nil)
        var functionNames = Set<String>()
        for function in graph.functions {
            if function.name.isEmpty { issues.append(VisualScriptIssue(.error, "a function has no name")) }
            if !functionNames.insert(function.name).inserted { issues.append(VisualScriptIssue(.error, "function '\(function.name)' is declared twice")) }
            body(function.nodes, function.links, function.name)
        }
        return issues
    }

    @MainActor
    private static func bodyIssues(_ graph: VisualScriptGraph, _ nodes: [VisualScriptNode], _ links: [VisualScriptLink],
                                   function: VisualScriptFunction?) -> [VisualScriptIssue] {
        let fn = function?.name
        var issues: [VisualScriptIssue] = []
        var signatures: [String: VisualScriptSignature] = [:]
        var definitions: [String: VisualScriptNodeDefinition] = [:]
        for node in nodes where signatures[node.id] == nil {
            guard let definition = VisualScriptNodes.definition(node.type) else {
                if !node.type.isEmpty { issues.append(VisualScriptIssue(.error, function: fn, node: node.id, "unknown node type '\(node.type)'")) }
                continue
            }
            definitions[node.id] = definition
            let context = VisualScriptSignatureContext(node: node, graph: graph, function: function)
            let signature = definition.signature(context)
            signatures[node.id] = signature
            if function != nil, definition.kind == .event {
                issues.append(VisualScriptIssue(.error, function: fn, node: node.id, "event nodes only work in the event graph"))
            }
            if function == nil, node.type == "function.entry" || node.type == "function.return" {
                issues.append(VisualScriptIssue(.error, node: node.id, "\(node.type) only works inside a function"))
            }
            for message in definition.check?(context) ?? [] { issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, message)) }
            for (name, value) in node.inputs.sorted(by: { $0.key < $1.key }) {
                guard let pin = signature.input(name) else {
                    issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, pin: name, "no input named '\(name)'"))
                    continue
                }
                if pin.type == .exec || pin.type == .entity {
                    issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, pin: name, "\(pin.type.rawValue) inputs take a wire, not a value"))
                } else if !VisualScriptValue.isLiteral(value, of: pin.type) {
                    issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, pin: name, "value doesn't fit type \(pin.type.rawValue)"))
                }
            }
        }

        var dataInto: [VisualScriptPinRef: Int] = [:]
        var execFrom: [VisualScriptPinRef: Int] = [:]
        var execInto = Set<String>()
        var dataEdges: [String: Set<String>] = [:]  // consumer → producers
        var execEdges: [String: Set<String>] = [:]  // producer → consumers
        for link in links {
            guard let from = link.source, let to = link.target, let a = signatures[from.node], let b = signatures[to.node] else { continue }
            let label = "link \(link.from) → \(link.to)"
            guard let out = a.output(from.pin) else {
                let hint = a.input(from.pin) != nil ? " ('\(from.pin)' is an input; links go from an output to an input)" : ""
                issues.append(VisualScriptIssue(.error, function: fn, node: from.node, pin: from.pin, "\(label): no output named '\(from.pin)'\(hint)"))
                continue
            }
            guard let input = b.input(to.pin) else {
                let hint = b.output(to.pin) != nil ? " ('\(to.pin)' is an output; links go from an output to an input)" : ""
                issues.append(VisualScriptIssue(.error, function: fn, node: to.node, pin: to.pin, "\(label): no input named '\(to.pin)'\(hint)"))
                continue
            }
            if (out.type == .exec) != (input.type == .exec) {
                issues.append(VisualScriptIssue(.error, function: fn, node: to.node, pin: to.pin, "\(label): can't wire an exec pin to a data pin"))
                continue
            }
            if !out.type.converts(to: input.type) {
                issues.append(VisualScriptIssue(.error, function: fn, node: to.node, pin: to.pin,
                                                "\(label): type mismatch (\(out.type.rawValue) can't feed \(input.type.rawValue))"))
                continue
            }
            if out.type == .exec {
                execFrom[from, default: 0] += 1
                execInto.insert(to.node)
                execEdges[from.node, default: []].insert(to.node)
            } else {
                dataInto[to, default: 0] += 1
                dataEdges[to.node, default: []].insert(from.node)
            }
        }
        for (pin, count) in dataInto where count > 1 {
            issues.append(VisualScriptIssue(.error, function: fn, node: pin.node, pin: pin.pin, "\(count) wires into one input (only the last is used)"))
        }
        for (pin, count) in execFrom where count > 1 {
            issues.append(VisualScriptIssue(.error, function: fn, node: pin.node, pin: pin.pin,
                                            "\(count) wires from one exec output (only the last is used; use a sequence)"))
        }

        // Required inputs.
        for node in nodes {
            guard let signature = signatures[node.id] else { continue }
            for pin in signature.inputs where pin.required && pin.type != .exec {
                let wired = dataInto[VisualScriptPinRef(node: node.id, pin: pin.name)] != nil
                let literal = node.inputs[pin.name].map { if case .null = $0 { return false } else { return true } } ?? false
                if !wired && !literal {
                    issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, pin: pin.name, "required input '\(pin.name)' is not connected"))
                }
            }
        }

        // Reachability: flows start at event nodes (or a function's entry) and follow exec wires;
        // pure nodes count when something reachable reads them.
        var reached = Set<String>()
        var queue = nodes.filter { definitions[$0.id]?.kind == .event || $0.type == "function.entry" }.map(\.id)
        while let id = queue.popLast() {
            guard reached.insert(id).inserted else { continue }
            queue += execEdges[id] ?? []
        }
        var used = reached
        var pending = Array(reached)
        while let id = pending.popLast() {
            for producer in dataEdges[id] ?? [] where used.insert(producer).inserted { pending.append(producer) }
        }
        for node in nodes {
            guard let definition = definitions[node.id] else { continue }
            switch definition.kind {
            case .action where !reached.contains(node.id):
                let why = execInto.contains(node.id) ? "unreachable: no event leads here" : "never runs: nothing is wired to its exec input"
                issues.append(VisualScriptIssue(.warning, function: fn, node: node.id, why))
            case .pure where !used.contains(node.id) && node.type != "function.entry":
                issues.append(VisualScriptIssue(.info, function: fn, node: node.id, "unused: nothing that runs reads it"))
            default: break
            }
        }

        // Loops among pure nodes can't be computed.
        var state: [String: Int] = [:]  // 1 visiting, 2 done
        var cyclic = Set<String>()
        func visit(_ id: String) {
            if state[id] == 2 { return }
            if state[id] == 1 { cyclic.insert(id); return }
            state[id] = 1
            for producer in dataEdges[id] ?? [] where definitions[producer]?.kind == .pure { visit(producer) }
            state[id] = 2
        }
        for node in nodes where definitions[node.id]?.kind == .pure { visit(node.id) }
        for id in cyclic.sorted() { issues.append(VisualScriptIssue(.error, function: fn, node: id, "data wires form a loop")) }
        return issues
    }
}
