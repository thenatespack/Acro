import Foundation
import EngineCore
import EngineScene

// Node types for visual scripts: what pins a node has and what it does. Built-in nodes are
// registered on first use (VisualScriptCoreNodes.swift, VisualScriptWorldNodes.swift); other
// modules and games add theirs with `VisualScriptNodes.register(_:)` (game modules through
// `game.scriptNode(...)`), so builders shipped later (dialogue, timeline…) plug their nodes in
// without touching the VM.

/// One pin of a node type.
public struct VisualScriptPin: Equatable, Sendable {
    public var name: String
    public var type: VisualScriptType
    /// What the editor shows (default: the name).
    public var title: String?
    /// The value of an unconnected input without a literal (default: the type's zero; an
    /// unconnected entity input means the script's own entity).
    public var defaultValue: VisualScriptValue?
    /// Validation reports an input that is neither connected nor given a literal.
    public var required: Bool
    public var doc: String?

    public init(_ name: String, _ type: VisualScriptType, title: String? = nil, default defaultValue: VisualScriptValue? = nil,
                required: Bool = false, doc: String? = nil) {
        self.name = name
        self.type = type
        self.title = title
        self.defaultValue = defaultValue
        self.required = required
        self.doc = doc
    }

    /// An exec pin (`in` / `out` by default).
    public static func exec(_ name: String, title: String? = nil) -> VisualScriptPin { VisualScriptPin(name, .exec, title: title) }

    public var displayName: String { title ?? name }
}

/// The pins of one node (they may depend on its config, e.g. a variable's type).
public struct VisualScriptSignature: Equatable, Sendable {
    public var inputs: [VisualScriptPin]
    public var outputs: [VisualScriptPin]

    public init(inputs: [VisualScriptPin] = [], outputs: [VisualScriptPin] = []) {
        self.inputs = inputs
        self.outputs = outputs
    }

    public func input(_ name: String) -> VisualScriptPin? { inputs.first { $0.name == name } }
    public func output(_ name: String) -> VisualScriptPin? { outputs.first { $0.name == name } }
}

/// What a node's signature can depend on.
public struct VisualScriptSignatureContext: Sendable {
    public var node: VisualScriptNode
    public var graph: VisualScriptGraph
    /// The function the node is in (nil: the event graph).
    public var function: VisualScriptFunction?

    public init(node: VisualScriptNode, graph: VisualScriptGraph, function: VisualScriptFunction? = nil) {
        self.node = node
        self.graph = graph
        self.function = function
    }
}

/// How a node takes part in the flow.
public enum VisualScriptNodeKind: String, Codable, Sendable {
    /// Starts flows when something happens (start, update, a key, a collision…); exec output only.
    case event
    /// Runs when the flow reaches it (exec input), then passes the flow on.
    case action
    /// No exec pins: computed when an input that uses it is read.
    case pure
}

/// A setting of a node type (`VisualScriptNode.config`).
public struct VisualScriptConfigKey: Equatable, Sendable {
    public var name: String
    public var type: VisualScriptType
    /// Allowed values, when there's a fixed list.
    public var options: [String]?
    public var doc: String?

    public init(_ name: String, _ type: VisualScriptType = .string, options: [String]? = nil, doc: String? = nil) {
        self.name = name
        self.type = type
        self.options = options
        self.doc = doc
    }
}

/// Where the flow goes after a node runs.
public enum VisualScriptFlow: Equatable, Sendable {
    /// Follow the exec output with this name.
    case out(String)
    /// The flow ends here (or the node passes it on itself, later or through `fire`).
    case stop

    /// Follow `out`.
    public static let next = VisualScriptFlow.out("out")
}

/// A problem a node reports while running; the flow stops and the message is logged.
public struct VisualScriptError: Error, CustomStringConvertible, Sendable {
    public var message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// A node type.
@MainActor
public final class VisualScriptNodeDefinition {
    public let id: String
    public let title: String
    /// Groups nodes in search ("Flow", "Math", "World"…).
    public let category: String
    public let doc: String
    public let kind: VisualScriptNodeKind
    public let config: [VisualScriptConfigKey]
    /// For event nodes: the event the runtime raises to run it (default: the id).
    public let event: String?
    /// Who registered it (nil: the engine; a game module's name).
    public var owner: String?
    let signature: @MainActor (VisualScriptSignatureContext) -> VisualScriptSignature
    let run: (@MainActor (VisualScriptNodeContext) throws -> VisualScriptFlow)?
    /// Extra validation (unknown variable, missing config…): messages about this node.
    let check: (@MainActor (VisualScriptSignatureContext) -> [String])?

    public init(id: String, title: String, category: String, doc: String = "", kind: VisualScriptNodeKind,
                config: [VisualScriptConfigKey] = [], event: String? = nil,
                signature: @escaping @MainActor (VisualScriptSignatureContext) -> VisualScriptSignature,
                check: (@MainActor (VisualScriptSignatureContext) -> [String])? = nil,
                run: (@MainActor (VisualScriptNodeContext) throws -> VisualScriptFlow)?) {
        self.id = id
        self.title = title
        self.category = category
        self.doc = doc
        self.kind = kind
        self.config = config
        self.event = kind == .event ? (event ?? id) : nil
        self.signature = signature
        self.check = check
        self.run = run
    }

    /// A node type with fixed pins. Action nodes get `in` / `out` exec pins added (first), unless
    /// `inputs` / `outputs` already have exec pins.
    public convenience init(id: String, title: String, category: String, doc: String = "", kind: VisualScriptNodeKind,
                            config: [VisualScriptConfigKey] = [], event: String? = nil,
                            inputs: [VisualScriptPin] = [], outputs: [VisualScriptPin] = [],
                            run: (@MainActor (VisualScriptNodeContext) throws -> VisualScriptFlow)?) {
        let signature = Self.standardSignature(kind: kind, inputs: inputs, outputs: outputs)
        self.init(id: id, title: title, category: category, doc: doc, kind: kind, config: config, event: event,
                  signature: { _ in signature }, run: run)
    }

    /// Adds the default exec pins to an action's (`in`, `out`) or an event's (`out`) pins.
    public static func standardSignature(kind: VisualScriptNodeKind, inputs: [VisualScriptPin], outputs: [VisualScriptPin]) -> VisualScriptSignature {
        var ins = inputs, outs = outputs
        switch kind {
        case .action:
            if !ins.contains(where: { $0.type == .exec }) { ins.insert(.exec("in"), at: 0) }
            if !outs.contains(where: { $0.type == .exec }) { outs.insert(.exec("out"), at: 0) }
        case .event:
            if !outs.contains(where: { $0.type == .exec }) { outs.insert(.exec("out"), at: 0) }
        case .pure: break
        }
        return VisualScriptSignature(inputs: ins, outputs: outs)
    }

    public func signature(for node: VisualScriptNode, in graph: VisualScriptGraph, function: VisualScriptFunction? = nil) -> VisualScriptSignature {
        signature(VisualScriptSignatureContext(node: node, graph: graph, function: function))
    }
}

/// The node types visual scripts can use, by id.
@MainActor
public enum VisualScriptNodes {
    private static var definitions: [String: VisualScriptNodeDefinition] = [:]
    private static var builtinsRegistered = false
    private static var providers: [(name: String, register: @MainActor () -> Void)] = []
    private static var providersRun: Set<String> = []

    /// Gives component get/set nodes a default value of a component type, to list its fields
    /// without an entity (the editor sets this to its Add Component factories). Without one a
    /// type that decodes from `{}` still works.
    public static var componentDefaults: ((String) -> (any Component)?)?

    /// Node type id → the custom event it listens for, for event node types made for one event
    /// (a game module's `scriptEvent`); `event.custom` names its event in its config instead.
    public static var customEventNames: [String: String] = [:]

    /// Adds or replaces a node type.
    public static func register(_ definition: VisualScriptNodeDefinition) {
        ensureBuiltins()
        definitions[definition.id] = definition
    }

    /// Removes node types (a game module's, when it unloads). Returns the ids removed.
    @discardableResult
    public static func unregister(_ ids: some Sequence<String>) -> [String] {
        ids.filter { definitions.removeValue(forKey: $0) != nil }
    }

    /// Removes every node type registered by `owner`.
    @discardableResult
    public static func unregister(owner: String) -> [String] {
        unregister(definitions.values.filter { $0.owner == owner }.map(\.id))
    }

    /// Registers more node types on first use (or now, when the built-ins are already in), once
    /// per `name`: how modules above the VM (rendering, other builders) add theirs.
    public static func addProvider(_ name: String, _ register: @escaping @MainActor () -> Void) {
        guard !providers.contains(where: { $0.name == name }) else { return }
        providers.append((name, register))
        if builtinsRegistered { runProviders() }
    }

    public static func definition(_ id: String) -> VisualScriptNodeDefinition? {
        ensureBuiltins()
        return definitions[id]
    }

    /// Every node type, by category then id.
    public static var all: [VisualScriptNodeDefinition] {
        ensureBuiltins()
        return definitions.values.sorted { ($0.category, $0.id) < ($1.category, $1.id) }
    }

    static func ensureBuiltins() {
        guard !builtinsRegistered else { return }
        builtinsRegistered = true
        for definition in VisualScriptCoreNodes.all() + VisualScriptWorldNodes.all() { definitions[definition.id] = definition }
        runProviders()
    }

    private static func runProviders() {
        for provider in providers where !providersRun.contains(provider.name) {
            providersRun.insert(provider.name)
            provider.register()
        }
    }

    /// A default value of the component named `name`, for listing its fields.
    public static func defaultComponent(named name: String) -> (any Component)? {
        if let made = componentDefaults?(name) { return made }
        guard let type = ComponentRegistry.type(named: name) else { return nil }
        func decodeEmpty<C: Component>(_: C.Type) -> (any Component)? { try? JSONValue.object([:]).decode(C.self) }
        return decodeEmpty(type)
    }
}
