import Foundation
import EngineCore
import EngineScene

// Game logic as a node graph: the contents of a `.vscript` file (JSON, every key optional).
// Event nodes start flows (start, update, a key press, a collision…); exec wires carry the flow
// from node to node; data wires carry values into input pins. Unconnected inputs use the
// literal in the node's `inputs`, else the pin's default. Interpreted by `VisualScriptRuntime`
// with no compile step, so edits apply while the game runs.
//
// ```json
// {
//   "variables": [{"name": "speed", "type": "float", "default": 90}],
//   "nodes": [
//     {"id": "tick", "type": "event.update", "x": 0, "y": 0},
//     {"id": "speed", "type": "var.get", "config": {"variable": "speed"}, "x": 0, "y": 120},
//     {"id": "mul", "type": "math.multiply", "x": 200, "y": 100},
//     {"id": "turn", "type": "transform.rotate", "x": 400, "y": 0, "inputs": {"axis": [0, 1, 0]}}
//   ],
//   "links": [
//     {"from": "tick.out", "to": "turn.in"},
//     {"from": "tick.dt", "to": "mul.a"}, {"from": "speed.value", "to": "mul.b"},
//     {"from": "mul.result", "to": "turn.degrees"}
//   ],
//   "functions": [{"name": "heal", "inputs": [{"name": "amount", "type": "float"}], "nodes": [], "links": []}],
//   "comments": [{"text": "Spin", "x": -20, "y": -40, "width": 640, "height": 240}],
//   "actions": {"jump": ["key.space", "pad.south"]}
// }
// ```
//
// A pin is named "<node id>.<pin name>": links go from an output pin to an input pin. Exec
// pins are `in` (input) and `out` (output) on most nodes; `vscript.nodes` lists every node's
// pins. Node ids and pin names can't contain ".".

/// A pin's value type. `exec` pins carry the flow, the rest carry values.
public enum VisualScriptType: String, Codable, CaseIterable, Sendable {
    case exec
    /// Takes any value (converted where it is used).
    case any
    case bool, int, float, string
    case vec2, vec3, vec4
    /// RGBA, linear 0...1 (a vec4 underneath).
    case color
    case quat
    case entity
    /// A project asset: "asset:<id>" or a path under `Assets/`.
    case asset
    case array
    /// String keys to values.
    case map

    /// Whether a value of type `self` can feed a pin of type `target` (directly or through the
    /// automatic conversion the VM applies).
    public func converts(to target: VisualScriptType) -> Bool {
        if self == .exec || target == .exec { return self == target }
        if self == target || self == .any || target == .any { return true }
        switch (self, target) {
        case (_, .string): return true
        case (.int, .float), (.float, .int), (.bool, .int), (.bool, .float), (.int, .bool), (.float, .bool): return true
        case (.vec4, .color), (.color, .vec4), (.vec3, .vec2), (.vec2, .vec3), (.vec3, .vec4), (.vec3, .color), (.vec4, .vec3),
             (.color, .vec3): return true
        case (.string, .asset): return true
        case (.entity, .bool): return true
        case (.int, .vec3), (.float, .vec3), (.int, .vec2), (.float, .vec2): return true
        default: return false
        }
    }
}

/// A graph variable: typed, with a default; `exposed` ones show (and can be changed per
/// entity) in the `VisualScript` component's `variables`.
public struct VisualScriptVariable: Codable, Equatable, Sendable {
    public var name: String
    public var type: VisualScriptType
    public var defaultValue: JSONValue?
    public var exposed: Bool
    public var tooltip: String?

    public init(name: String, type: VisualScriptType = .float, defaultValue: JSONValue? = nil, exposed: Bool = true, tooltip: String? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.exposed = exposed
        self.tooltip = tooltip
    }

    private enum CodingKeys: String, CodingKey { case name, type, defaultValue = "default", exposed, tooltip }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try c.decodeIfPresent(VisualScriptType.self, forKey: .type) ?? .float
        defaultValue = try c.decodeIfPresent(JSONValue.self, forKey: .defaultValue)
        exposed = try c.decodeIfPresent(Bool.self, forKey: .exposed) ?? true
        tooltip = try c.decodeIfPresent(String.self, forKey: .tooltip)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(defaultValue, forKey: .defaultValue)
        if !exposed { try c.encode(exposed, forKey: .exposed) }
        try c.encodeIfPresent(tooltip, forKey: .tooltip)
    }
}

/// A function's parameter or result.
public struct VisualScriptParameter: Codable, Equatable, Sendable {
    public var name: String
    public var type: VisualScriptType

    public init(name: String, type: VisualScriptType = .float) {
        self.name = name
        self.type = type
    }

    private enum CodingKeys: String, CodingKey { case name, type }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try c.decodeIfPresent(VisualScriptType.self, forKey: .type) ?? .float
    }
}

/// One node: its type (`vscript.nodes` lists them), position in the editor, settings that
/// shape its pins (`config`: which variable, component, key…) and literal values for its
/// unconnected inputs.
public struct VisualScriptNode: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var x: Float
    public var y: Float
    public var config: [String: JSONValue]
    public var inputs: [String: JSONValue]
    /// A note shown on the node.
    public var comment: String?
    /// Pause play mode after the frame in which this node runs (editor play mode).
    public var breakpoint: Bool
    /// Drawn as a small title-only box.
    public var collapsed: Bool

    public init(id: String, type: String, x: Float = 0, y: Float = 0, config: [String: JSONValue] = [:],
                inputs: [String: JSONValue] = [:], comment: String? = nil, breakpoint: Bool = false, collapsed: Bool = false) {
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

    private enum CodingKeys: String, CodingKey { case id, type, x, y, config, inputs, comment, breakpoint, collapsed }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? ""
        x = try c.decodeIfPresent(Float.self, forKey: .x) ?? 0
        y = try c.decodeIfPresent(Float.self, forKey: .y) ?? 0
        config = try c.decodeIfPresent([String: JSONValue].self, forKey: .config) ?? [:]
        inputs = try c.decodeIfPresent([String: JSONValue].self, forKey: .inputs) ?? [:]
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        breakpoint = try c.decodeIfPresent(Bool.self, forKey: .breakpoint) ?? false
        collapsed = try c.decodeIfPresent(Bool.self, forKey: .collapsed) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        if !config.isEmpty { try c.encode(config, forKey: .config) }
        if !inputs.isEmpty { try c.encode(inputs, forKey: .inputs) }
        try c.encodeIfPresent(comment, forKey: .comment)
        if breakpoint { try c.encode(breakpoint, forKey: .breakpoint) }
        if collapsed { try c.encode(collapsed, forKey: .collapsed) }
    }

    public func configString(_ key: String) -> String? {
        if case .string(let s)? = config[key] { return s }
        return nil
    }
}

/// A pin of a node: "<node id>.<pin name>".
public struct VisualScriptPinRef: Hashable, Sendable, CustomStringConvertible {
    public var node: String
    public var pin: String

    public init(node: String, pin: String) {
        self.node = node
        self.pin = pin
    }

    /// Parses "node.pin" (split at the first ".").
    public init?(_ text: String) {
        guard let dot = text.firstIndex(of: "."), dot != text.startIndex, text.index(after: dot) != text.endIndex else { return nil }
        node = String(text[..<dot])
        pin = String(text[text.index(after: dot)...])
    }

    public var description: String { "\(node).\(pin)" }
}

/// A wire from an output pin to an input pin. Written `{"from": "a.out", "to": "b.in"}`
/// (or `["a.out", "b.in"]`).
public struct VisualScriptLink: Codable, Hashable, Sendable {
    public var from: String
    public var to: String

    public init(from: String, to: String) {
        self.from = from
        self.to = to
    }

    public var source: VisualScriptPinRef? { VisualScriptPinRef(from) }
    public var target: VisualScriptPinRef? { VisualScriptPinRef(to) }

    private enum CodingKeys: String, CodingKey { case from, to }

    public init(from decoder: any Decoder) throws {
        if var list = try? decoder.unkeyedContainer() {
            from = try list.decode(String.self)
            to = try list.decode(String.self)
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        from = try c.decodeIfPresent(String.self, forKey: .from) ?? ""
        to = try c.decodeIfPresent(String.self, forKey: .to) ?? ""
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(from, forKey: .from)
        try c.encode(to, forKey: .to)
    }
}

/// A box with text drawn behind nodes, to label and group a part of the graph.
public struct VisualScriptComment: Codable, Equatable, Sendable {
    public var id: String
    public var text: String
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    /// "#RRGGBB" tint.
    public var color: String?

    public init(id: String = "", text: String = "", x: Float = 0, y: Float = 0, width: Float = 300, height: Float = 160, color: String? = nil) {
        self.id = id
        self.text = text
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.color = color
    }

    private enum CodingKeys: String, CodingKey { case id, text, x, y, width, height, color }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        x = try c.decodeIfPresent(Float.self, forKey: .x) ?? 0
        y = try c.decodeIfPresent(Float.self, forKey: .y) ?? 0
        width = try c.decodeIfPresent(Float.self, forKey: .width) ?? 300
        height = try c.decodeIfPresent(Float.self, forKey: .height) ?? 160
        color = try c.decodeIfPresent(String.self, forKey: .color)
    }
}

/// A reusable sub-graph, called with a `function.call` node (`config.function`). Its nodes
/// start at a `function.entry` node (outputs: the parameters) and end at `function.return`
/// (inputs: the results). A `pure` function has no exec pins on its call node.
public struct VisualScriptFunction: Codable, Equatable, Sendable {
    public var name: String
    public var inputs: [VisualScriptParameter]
    public var outputs: [VisualScriptParameter]
    public var nodes: [VisualScriptNode]
    public var links: [VisualScriptLink]
    public var pure: Bool
    /// A macro: its nodes are copied into every node using it (`function.call`) when the graph
    /// is prepared, so each use keeps its own state (gates, do-once, delays), and its inputs and
    /// outputs may include several exec pins (flows enter and leave where they're wired).
    public var macro: Bool

    public init(name: String, inputs: [VisualScriptParameter] = [], outputs: [VisualScriptParameter] = [],
                nodes: [VisualScriptNode] = [], links: [VisualScriptLink] = [], pure: Bool = false, macro: Bool = false) {
        self.name = name
        self.inputs = inputs
        self.outputs = outputs
        self.nodes = nodes
        self.links = links
        self.pure = pure
        self.macro = macro
    }

    private enum CodingKeys: String, CodingKey { case name, inputs, outputs, nodes, links, pure, macro }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        inputs = try c.decodeIfPresent([VisualScriptParameter].self, forKey: .inputs) ?? []
        outputs = try c.decodeIfPresent([VisualScriptParameter].self, forKey: .outputs) ?? []
        nodes = try c.decodeIfPresent([VisualScriptNode].self, forKey: .nodes) ?? []
        links = try c.decodeIfPresent([VisualScriptLink].self, forKey: .links) ?? []
        pure = try c.decodeIfPresent(Bool.self, forKey: .pure) ?? false
        macro = try c.decodeIfPresent(Bool.self, forKey: .macro) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(inputs, forKey: .inputs)
        try c.encode(outputs, forKey: .outputs)
        try c.encode(nodes, forKey: .nodes)
        try c.encode(links, forKey: .links)
        if pure { try c.encode(pure, forKey: .pure) }
        if macro { try c.encode(macro, forKey: .macro) }
    }
}

/// The node graph of one body: the event graph or a function's.
public protocol VisualScriptBody {
    var nodes: [VisualScriptNode] { get set }
    var links: [VisualScriptLink] { get set }
}

extension VisualScriptFunction: VisualScriptBody {}

/// The contents of a `.vscript` file.
public struct VisualScriptGraph: Codable, Equatable, Sendable, VisualScriptBody {
    public var variables: [VisualScriptVariable]
    public var nodes: [VisualScriptNode]
    public var links: [VisualScriptLink]
    public var functions: [VisualScriptFunction]
    public var comments: [VisualScriptComment]
    /// Input actions the graph's `event.actionPressed` / `input.action` nodes use: action name →
    /// sources ("key.space", "mouse.left", "pad.south", "axis.leftTrigger").
    public var actions: [String: [String]]

    public init(variables: [VisualScriptVariable] = [], nodes: [VisualScriptNode] = [], links: [VisualScriptLink] = [],
                functions: [VisualScriptFunction] = [], comments: [VisualScriptComment] = [], actions: [String: [String]] = [:]) {
        self.variables = variables
        self.nodes = nodes
        self.links = links
        self.functions = functions
        self.comments = comments
        self.actions = actions
    }

    private enum CodingKeys: String, CodingKey { case variables, nodes, links, functions, comments, actions }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        variables = try c.decodeIfPresent([VisualScriptVariable].self, forKey: .variables) ?? []
        nodes = try c.decodeIfPresent([VisualScriptNode].self, forKey: .nodes) ?? []
        links = try c.decodeIfPresent([VisualScriptLink].self, forKey: .links) ?? []
        functions = try c.decodeIfPresent([VisualScriptFunction].self, forKey: .functions) ?? []
        comments = try c.decodeIfPresent([VisualScriptComment].self, forKey: .comments) ?? []
        actions = try c.decodeIfPresent([String: [String]].self, forKey: .actions) ?? [:]
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if !variables.isEmpty { try c.encode(variables, forKey: .variables) }
        try c.encode(nodes, forKey: .nodes)
        try c.encode(links, forKey: .links)
        if !functions.isEmpty { try c.encode(functions, forKey: .functions) }
        if !comments.isEmpty { try c.encode(comments, forKey: .comments) }
        if !actions.isEmpty { try c.encode(actions, forKey: .actions) }
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    public static func decode(_ data: Data) throws -> VisualScriptGraph {
        try AssetJSON.decoder().decode(VisualScriptGraph.self, from: data)
    }

    public func variable(_ name: String) -> VisualScriptVariable? { variables.first { $0.name == name } }
    public func function(_ name: String) -> VisualScriptFunction? { functions.first { $0.name == name } }
}

extension VisualScriptBody {
    public func node(_ id: String) -> VisualScriptNode? { nodes.first { $0.id == id } }
    public func nodeIndex(_ id: String) -> Int? { nodes.firstIndex { $0.id == id } }

    /// A node id not used yet: `base` followed by the first free number ("branch1", "branch2"…).
    public func uniqueNodeID(_ base: String) -> String {
        var stem = base.split(separator: ".").last.map(String.init) ?? "node"
        stem = String(stem.filter { $0.isLetter || $0.isNumber || $0 == "_" })
        if stem.isEmpty { stem = "node" }
        let used = Set(nodes.map(\.id))
        var n = 1
        while used.contains("\(stem)\(n)") { n += 1 }
        return "\(stem)\(n)"
    }
}
