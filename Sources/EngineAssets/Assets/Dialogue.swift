#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

// Branching conversations: the contents of a `.dialogue` file (JSON, every key optional).
//
// ```json
// {
//   "start": "hello",
//   "speakers": [{"id": "guard", "name": "Gate Guard", "portrait": "Art/guard.png", "color": "#E0A040"}],
//   "variables": [{"name": "gold", "type": "number", "default": 5}, {"name": "paid", "type": "bool"}],
//   "nodes": [
//     {"id": "hello", "type": "line", "speaker": "guard", "text": "Halt! The toll is 10 gold. You have {gold}.", "key": "gate.hello", "next": "ask"},
//     {"id": "ask", "type": "choice", "choices": [
//       {"text": "Pay the toll", "next": "pay", "condition": "gold >= 10"},
//       {"text": "Leave", "next": "bye"}]},
//     {"id": "pay", "type": "set", "changes": [{"variable": "gold", "op": "subtract", "value": 10},
//                                             {"variable": "paid", "value": true}], "next": "open"},
//     {"id": "open", "type": "event", "event": "openGate", "next": "bye"},
//     {"id": "bye", "type": "end"}
//   ]
// }
// ```
//
// Node types:
// - `line`: a `speaker` says `text` (with `{variable}` filled in); the player continues to `next`.
// - `choice`: the player picks one of `choices` (each with `text`, `next` and an optional
//   `condition`; options whose condition is false are hidden). Optional `speaker` / `text` is a
//   prompt shown above them. With no option available it goes to `next` (or ends).
// - `condition`: goes to `next` when `condition` is true, else to `else`.
// - `set`: applies `changes` to variables (set, add, subtract, toggle), then goes to `next`.
// - `event`: tells game code `event` happened (with `args`), then goes to `next`.
// - `end`: ends the conversation (so does an empty `next`).
//
// Conditions and change expressions use `DialogueExpression` (`gold >= 10 && !paid`). Each line
// and choice can have a localization `key`; `DialogueRunner.localize` looks text up by it.
// `position` is where the editor's graph view draws the node.

/// What a node does (see the file comment).
public enum DialogueNodeType: String, Codable, CaseIterable, Sendable {
    case line, choice, condition, set, event, end
}

/// Someone who speaks lines: an id nodes use, a display name, a portrait image and a name color.
public struct DialogueSpeaker: Codable, Equatable, Sendable {
    public var id: String
    /// Shown above the line (default: the id).
    public var name: String
    /// A texture asset (path under `Assets/` or "asset:<id>"); "" for none.
    public var portrait: String
    /// The name's color, "#RRGGBB"; "" for the theme's.
    public var color: String

    public init(id: String = "", name: String = "", portrait: String = "", color: String = "") {
        self.id = id
        self.name = name
        self.portrait = portrait
        self.color = color
    }

    private enum CodingKeys: String, CodingKey { case id, name, portrait, color }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try c.decodeIfPresent(String.self, forKey: .id) ?? "",
                  name: try c.decodeIfPresent(String.self, forKey: .name) ?? "",
                  portrait: try c.decodeIfPresent(String.self, forKey: .portrait) ?? "",
                  color: try c.decodeIfPresent(String.self, forKey: .color) ?? "")
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        if !name.isEmpty { try c.encode(name, forKey: .name) }
        if !portrait.isEmpty { try c.encode(portrait, forKey: .portrait) }
        if !color.isEmpty { try c.encode(color, forKey: .color) }
    }

    /// The name to show.
    public var displayName: String { name.isEmpty ? id : name }

    /// `color` as sRGB RGBA 0...1, nil when empty or not "#RRGGBB[AA]".
    public var parsedColor: Vec4? { DialogueSpeaker.parseHex(color) }

    static func parseHex(_ text: String) -> Vec4? {
        var hex = text.trimmingCharacters(in: .whitespaces)
        guard hex.hasPrefix("#") else { return nil }
        hex.removeFirst()
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
        let rgba = hex.count == 6 ? (value << 8) | 0xFF : value
        return Vec4(Float((rgba >> 24) & 0xFF) / 255, Float((rgba >> 16) & 0xFF) / 255, Float((rgba >> 8) & 0xFF) / 255, Float(rgba & 0xFF) / 255)
    }
}

/// What a variable holds.
public enum DialogueVariableType: String, Codable, CaseIterable, Sendable {
    case number, bool, text
}

/// A variable the conversation reads and changes, with its starting value.
public struct DialogueVariable: Codable, Equatable, Sendable {
    public var name: String
    public var type: DialogueVariableType
    /// The starting value; nil: 0, false or "".
    public var defaultValue: JSONValue?

    public init(name: String = "", type: DialogueVariableType = .number, defaultValue: JSONValue? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    private enum CodingKeys: String, CodingKey { case name, type, defaultValue = "default" }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let value = try c.decodeIfPresent(JSONValue.self, forKey: .defaultValue).flatMap { $0 == .null ? nil : $0 }
        // Without a type, guess it from the default.
        var type = try c.decodeIfPresent(DialogueVariableType.self, forKey: .type)
        if type == nil, let value { type = DialogueValue(json: value)?.type }
        self.init(name: try c.decodeIfPresent(String.self, forKey: .name) ?? "", type: type ?? .number, defaultValue: value)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(defaultValue, forKey: .defaultValue)
    }

    /// The value it starts with: the default converted to the type, else the type's zero.
    public var initialValue: DialogueValue {
        defaultValue.flatMap(DialogueValue.init(json:))?.converted(to: type) ?? DialogueValue.zero(type)
    }
}

/// One option of a `choice` node.
public struct DialogueChoice: Codable, Equatable, Sendable {
    public var text: String
    /// Localization key.
    public var key: String
    /// The node it leads to ("" ends the conversation).
    public var next: String
    /// Shown only while this is true ("" always).
    public var condition: String

    public init(text: String = "", key: String = "", next: String = "", condition: String = "") {
        self.text = text
        self.key = key
        self.next = next
        self.condition = condition
    }

    private enum CodingKeys: String, CodingKey { case text, key, next, condition }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(text: try c.decodeIfPresent(String.self, forKey: .text) ?? "",
                  key: try c.decodeIfPresent(String.self, forKey: .key) ?? "",
                  next: try c.decodeIfPresent(String.self, forKey: .next) ?? "",
                  condition: try c.decodeIfPresent(String.self, forKey: .condition) ?? "")
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text)
        if !key.isEmpty { try c.encode(key, forKey: .key) }
        try c.encode(next, forKey: .next)
        if !condition.isEmpty { try c.encode(condition, forKey: .condition) }
    }
}

/// One variable change of a `set` node.
public struct DialogueChange: Codable, Equatable, Sendable {
    public enum Operation: String, Codable, CaseIterable, Sendable {
        /// variable = value
        case set
        /// variable += value (numbers; text appends)
        case add
        /// variable -= value
        case subtract
        /// variable = !variable (bools)
        case toggle
    }

    public var variable: String
    public var op: Operation
    /// The operand as a JSON value (number, bool or text).
    public var value: JSONValue?
    /// Or an expression computing it (`gold * 2`); used instead of `value` when set.
    public var expression: String

    public init(variable: String = "", op: Operation = .set, value: JSONValue? = nil, expression: String = "") {
        self.variable = variable
        self.op = op
        self.value = value
        self.expression = expression
    }

    private enum CodingKeys: String, CodingKey { case variable, op, value, expression }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(variable: try c.decodeIfPresent(String.self, forKey: .variable) ?? "",
                  op: try c.decodeIfPresent(Operation.self, forKey: .op) ?? .set,
                  value: try c.decodeIfPresent(JSONValue.self, forKey: .value).flatMap { $0 == .null ? nil : $0 },
                  expression: try c.decodeIfPresent(String.self, forKey: .expression) ?? "")
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(variable, forKey: .variable)
        if op != .set { try c.encode(op, forKey: .op) }
        try c.encodeIfPresent(value, forKey: .value)
        if !expression.isEmpty { try c.encode(expression, forKey: .expression) }
    }
}

/// A node of the conversation graph. Which fields matter depends on `type` (see the file comment).
public struct DialogueNode: Codable, Equatable, Sendable {
    public var id: String
    public var type: DialogueNodeType
    /// line, choice (prompt): a speaker id.
    public var speaker: String
    /// line: what is said; choice: an optional prompt.
    public var text: String
    /// Localization key of `text`.
    public var key: String
    /// The node after this one ("" ends). For a condition, where it goes when true.
    public var next: String
    /// condition: where it goes when false.
    public var elseNext: String
    /// choice: the options.
    public var choices: [DialogueChoice]
    /// condition: the test.
    public var condition: String
    /// set: the changes, in order.
    public var changes: [DialogueChange]
    /// event: its name.
    public var event: String
    /// event: extra values for game code.
    public var args: [String: JSONValue]
    /// Where the graph view draws it (top-left, in graph points); nil: placed automatically.
    public var position: Vec2?
    /// A note for writers (not shown in game).
    public var comment: String

    public init(id: String = "", type: DialogueNodeType = .line, speaker: String = "", text: String = "", key: String = "",
                next: String = "", elseNext: String = "", choices: [DialogueChoice] = [], condition: String = "",
                changes: [DialogueChange] = [], event: String = "", args: [String: JSONValue] = [:], position: Vec2? = nil,
                comment: String = "") {
        self.id = id
        self.type = type
        self.speaker = speaker
        self.text = text
        self.key = key
        self.next = next
        self.elseNext = elseNext
        self.choices = choices
        self.condition = condition
        self.changes = changes
        self.event = event
        self.args = args
        self.position = position
        self.comment = comment
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, speaker, text, key, next, elseNext = "else", choices, condition, changes, event, args, position, comment
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let position = try c.decodeIfPresent([Float].self, forKey: .position)
        self.init(id: try c.decodeIfPresent(String.self, forKey: .id) ?? "",
                  type: try c.decodeIfPresent(DialogueNodeType.self, forKey: .type) ?? .line,
                  speaker: try c.decodeIfPresent(String.self, forKey: .speaker) ?? "",
                  text: try c.decodeIfPresent(String.self, forKey: .text) ?? "",
                  key: try c.decodeIfPresent(String.self, forKey: .key) ?? "",
                  next: try c.decodeIfPresent(String.self, forKey: .next) ?? "",
                  elseNext: try c.decodeIfPresent(String.self, forKey: .elseNext) ?? "",
                  choices: try c.decodeIfPresent([DialogueChoice].self, forKey: .choices) ?? [],
                  condition: try c.decodeIfPresent(String.self, forKey: .condition) ?? "",
                  changes: try c.decodeIfPresent([DialogueChange].self, forKey: .changes) ?? [],
                  event: try c.decodeIfPresent(String.self, forKey: .event) ?? "",
                  args: try c.decodeIfPresent([String: JSONValue].self, forKey: .args) ?? [:],
                  position: position.flatMap { $0.count >= 2 ? Vec2($0[0], $0[1]) : nil },
                  comment: try c.decodeIfPresent(String.self, forKey: .comment) ?? "")
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        if !speaker.isEmpty { try c.encode(speaker, forKey: .speaker) }
        if !text.isEmpty { try c.encode(text, forKey: .text) }
        if !key.isEmpty { try c.encode(key, forKey: .key) }
        if !next.isEmpty { try c.encode(next, forKey: .next) }
        if !elseNext.isEmpty { try c.encode(elseNext, forKey: .elseNext) }
        if !choices.isEmpty { try c.encode(choices, forKey: .choices) }
        if !condition.isEmpty { try c.encode(condition, forKey: .condition) }
        if !changes.isEmpty { try c.encode(changes, forKey: .changes) }
        if !event.isEmpty { try c.encode(event, forKey: .event) }
        if !args.isEmpty { try c.encode(args, forKey: .args) }
        if let position { try c.encode([position.x.rounded(), position.y.rounded()], forKey: .position) }
        if !comment.isEmpty { try c.encode(comment, forKey: .comment) }
    }

    /// The nodes this one can go to, with a label for each link ("next", "else", "choice 0"…), in order.
    public var links: [(label: String, target: String)] {
        var out: [(String, String)] = []
        switch type {
        case .choice:
            for (i, choice) in choices.enumerated() where !choice.next.isEmpty { out.append(("choice \(i)", choice.next)) }
            if !next.isEmpty { out.append(("next", next)) }
        case .condition:
            if !next.isEmpty { out.append(("next", next)) }
            if !elseNext.isEmpty { out.append(("else", elseNext)) }
        case .end:
            break
        default:
            if !next.isEmpty { out.append(("next", next)) }
        }
        return out
    }

    /// A one-line summary for lists and the graph view.
    public var summary: String {
        switch type {
        case .line: return text.isEmpty ? "(no text)" : text
        case .choice: return choices.isEmpty ? "(no options)" : choices.map { $0.text.isEmpty ? "…" : $0.text }.joined(separator: " / ")
        case .condition: return condition.isEmpty ? "(no condition)" : "if \(condition)"
        case .set: return changes.isEmpty ? "(no changes)" : changes.map(\.summary).joined(separator: ", ")
        case .event: return event.isEmpty ? "(no event)" : "event \(event)"
        case .end: return "end"
        }
    }
}

extension DialogueChange {
    public var summary: String {
        let operand = expression.isEmpty ? (value.map { DialogueValue(json: $0)?.description ?? "?" } ?? "") : expression
        switch op {
        case .set: return "\(variable) = \(operand)"
        case .add: return "\(variable) += \(operand)"
        case .subtract: return "\(variable) -= \(operand)"
        case .toggle: return "toggle \(variable)"
        }
    }
}

/// A problem found by `DialogueAsset.validate`.
public struct DialogueIssue: Codable, Equatable, Sendable, CustomStringConvertible {
    /// The node it is about (nil for the whole dialogue).
    public var node: String?
    public var message: String

    public init(node: String? = nil, _ message: String) {
        self.node = node
        self.message = message
    }

    public var description: String { node.map { "node '\($0)': \(message)" } ?? message }
}

public struct DialogueError: Error, CustomStringConvertible, Equatable, Sendable {
    public var message: String
    public init(_ message: String) { self.message = message }
    public var description: String { message }
}

/// A conversation graph: the contents of a `.dialogue` file.
public struct DialogueAsset: Codable, Equatable, Sendable {
    /// The node a conversation starts at ("" means the first node).
    public var start: String
    public var speakers: [DialogueSpeaker]
    public var variables: [DialogueVariable]
    public var nodes: [DialogueNode]
    /// The `.ui` layout that shows this dialogue (a path under `Assets/` or "asset:<id>"; it
    /// uses the `DialogueLayoutKeys`); "" uses the default `DialogueBox`. A `DialoguePlayer`'s
    /// own `uiLayout` wins over it.
    public var uiLayout: String

    public init(start: String = "", speakers: [DialogueSpeaker] = [], variables: [DialogueVariable] = [], nodes: [DialogueNode] = [],
                uiLayout: String = "") {
        self.start = start
        self.speakers = speakers
        self.variables = variables
        self.nodes = nodes
        self.uiLayout = uiLayout
    }

    private enum CodingKeys: String, CodingKey { case start, uiLayout, speakers, variables, nodes }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        start = try c.decodeIfPresent(String.self, forKey: .start) ?? ""
        speakers = try c.decodeIfPresent([DialogueSpeaker].self, forKey: .speakers) ?? []
        variables = try c.decodeIfPresent([DialogueVariable].self, forKey: .variables) ?? []
        nodes = try c.decodeIfPresent([DialogueNode].self, forKey: .nodes) ?? []
        uiLayout = try c.decodeIfPresent(String.self, forKey: .uiLayout) ?? ""
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if !start.isEmpty { try c.encode(start, forKey: .start) }
        if !uiLayout.isEmpty { try c.encode(uiLayout, forKey: .uiLayout) }
        try c.encode(speakers, forKey: .speakers)
        try c.encode(variables, forKey: .variables)
        try c.encode(nodes, forKey: .nodes)
    }

    /// A new dialogue: one speaker, a greeting, a choice and an end.
    public static var starter: DialogueAsset {
        DialogueAsset(start: "hello",
                      speakers: [DialogueSpeaker(id: "npc", name: "Stranger")],
                      variables: [DialogueVariable(name: "talked", type: .bool)],
                      nodes: [
                        DialogueNode(id: "hello", type: .line, speaker: "npc", text: "Hello there, traveler.", next: "ask",
                                     position: Vec2(0, 0)),
                        DialogueNode(id: "ask", type: .choice, choices: [
                            DialogueChoice(text: "Who are you?", next: "who"),
                            DialogueChoice(text: "Goodbye.", next: "bye"),
                        ], position: Vec2(260, 0)),
                        DialogueNode(id: "who", type: .line, speaker: "npc", text: "Just someone passing through.", next: "bye",
                                     position: Vec2(520, -70)),
                        DialogueNode(id: "bye", type: .set, changes: [DialogueChange(variable: "talked", value: .bool(true))],
                                     position: Vec2(520, 90)),
                      ])
    }

    public static func decode(_ data: Data) throws -> DialogueAsset {
        try AssetJSON.decoder().decode(DialogueAsset.self, from: data)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    public func nodeIndex(_ id: String) -> Int? { nodes.firstIndex { $0.id == id } }
    public func node(_ id: String) -> DialogueNode? { nodeIndex(id).map { nodes[$0] } }
    public func speaker(_ id: String) -> DialogueSpeaker? { speakers.first { $0.id == id } }
    public func variable(_ name: String) -> DialogueVariable? { variables.first { $0.name == name } }

    /// The node a conversation starts at: `start`, else the first node.
    public var startNode: String? { start.isEmpty ? nodes.first?.id : start }

    /// A node id not used yet: `base`, else "`base`2", "`base`3"…
    public func uniqueNodeID(_ base: String) -> String {
        let base = base.isEmpty ? "node" : base
        if nodeIndex(base) == nil { return base }
        var n = 2
        while nodeIndex("\(base)\(n)") != nil { n += 1 }
        return "\(base)\(n)"
    }

    /// Every variable's starting value.
    public var initialVariables: [String: DialogueValue] {
        var out: [String: DialogueValue] = [:]
        for variable in variables where !variable.name.isEmpty { out[variable.name] = variable.initialValue }
        return out
    }

    /// The localization keys of every line, prompt and option, with their text, in node order.
    public var localizationEntries: [(key: String, text: String)] {
        var out: [(String, String)] = []
        for node in nodes {
            if !node.key.isEmpty { out.append((node.key, node.text)) }
            for choice in node.choices where !choice.key.isEmpty { out.append((choice.key, choice.text)) }
        }
        return out
    }

    /// Problems: a missing start, duplicate or empty ids, links to missing nodes, unknown
    /// speakers or variables, unparsable conditions, nodes without what their type needs,
    /// nodes no path reaches, and (when `assetExists` is given) missing portraits.
    public func validate(assetExists: ((String) -> Bool)? = nil) -> [DialogueIssue] {
        var issues: [DialogueIssue] = []
        if nodes.isEmpty { issues.append(DialogueIssue("there are no nodes")) }
        if !start.isEmpty, nodeIndex(start) == nil { issues.append(DialogueIssue("the start node '\(start)' doesn't exist")) }
        if let assetExists, !uiLayout.isEmpty, !assetExists(uiLayout) {
            issues.append(DialogueIssue("no asset '\(uiLayout)' for the UI layout (the default box is used)"))
        }
        var seen = Set<String>()
        for node in nodes {
            if node.id.isEmpty { issues.append(DialogueIssue("a \(node.type.rawValue) node has no id")) }
            else if !seen.insert(node.id).inserted { issues.append(DialogueIssue(node: node.id, "the id is used by more than one node")) }
        }
        var speakerIDs = Set<String>()
        for speaker in speakers {
            if speaker.id.isEmpty { issues.append(DialogueIssue("a speaker has no id")) }
            else if !speakerIDs.insert(speaker.id).inserted { issues.append(DialogueIssue("speaker '\(speaker.id)' is listed twice")) }
            if !speaker.color.isEmpty, speaker.parsedColor == nil {
                issues.append(DialogueIssue("speaker '\(speaker.id)': color '\(speaker.color)' isn't #RRGGBB"))
            }
            if let assetExists, !speaker.portrait.isEmpty, !assetExists(speaker.portrait) {
                issues.append(DialogueIssue("speaker '\(speaker.id)': no asset '\(speaker.portrait)' for the portrait"))
            }
        }
        var types: [String: DialogueVariableType] = [:]
        for variable in variables {
            if variable.name.isEmpty { issues.append(DialogueIssue("a variable has no name")); continue }
            if !DialogueExpression.isIdentifier(variable.name) {
                issues.append(DialogueIssue("variable '\(variable.name)': names are letters, digits, _ and . (not starting with a digit)"))
            }
            if types[variable.name] != nil { issues.append(DialogueIssue("variable '\(variable.name)' is declared twice")) }
            types[variable.name] = variable.type
            if let value = variable.defaultValue, DialogueValue(json: value)?.type != variable.type {
                issues.append(DialogueIssue("variable '\(variable.name)': the default isn't a \(variable.type.rawValue)"))
            }
        }

        func link(_ node: DialogueNode, _ target: String, _ label: String) {
            if !target.isEmpty, nodeIndex(target) == nil { issues.append(DialogueIssue(node: node.id, "\(label) goes to '\(target)', which doesn't exist")) }
        }
        func expression(_ node: DialogueNode, _ text: String, _ label: String) {
            do {
                let parsed = try DialogueExpression(text)
                for name in parsed.variableNames.sorted() where types[name] == nil {
                    issues.append(DialogueIssue(node: node.id, "\(label) uses '\(name)', which isn't a declared variable"))
                }
            } catch {
                issues.append(DialogueIssue(node: node.id, "\(label) '\(text)': \(error)"))
            }
        }
        func speakerAndText(_ node: DialogueNode) {
            if !node.speaker.isEmpty, !speakerIDs.contains(node.speaker) {
                issues.append(DialogueIssue(node: node.id, "speaker '\(node.speaker)' isn't in the speakers list"))
            }
            for name in DialogueText.placeholders(in: node.text) where types[name] == nil {
                issues.append(DialogueIssue(node: node.id, "the text uses {\(name)}, which isn't a declared variable"))
            }
        }

        for node in nodes {
            switch node.type {
            case .line:
                if node.text.isEmpty { issues.append(DialogueIssue(node: node.id, "the line has no text")) }
                speakerAndText(node)
                link(node, node.next, "next")
            case .choice:
                speakerAndText(node)
                if node.choices.isEmpty { issues.append(DialogueIssue(node: node.id, "the choice has no options")) }
                for (i, choice) in node.choices.enumerated() {
                    if choice.text.isEmpty { issues.append(DialogueIssue(node: node.id, "option \(i) has no text")) }
                    link(node, choice.next, "option \(i)")
                    if !choice.condition.isEmpty { expression(node, choice.condition, "option \(i)'s condition") }
                    for name in DialogueText.placeholders(in: choice.text) where types[name] == nil {
                        issues.append(DialogueIssue(node: node.id, "option \(i) uses {\(name)}, which isn't a declared variable"))
                    }
                }
                link(node, node.next, "next")
            case .condition:
                if node.condition.isEmpty { issues.append(DialogueIssue(node: node.id, "the condition is empty")) }
                else { expression(node, node.condition, "the condition") }
                link(node, node.next, "next")
                link(node, node.elseNext, "else")
            case .set:
                if node.changes.isEmpty { issues.append(DialogueIssue(node: node.id, "there are no changes")) }
                for change in node.changes {
                    guard let type = types[change.variable] else {
                        issues.append(DialogueIssue(node: node.id, "'\(change.variable)' isn't a declared variable"))
                        continue
                    }
                    if change.op == .toggle, type != .bool { issues.append(DialogueIssue(node: node.id, "toggle needs a bool, '\(change.variable)' is a \(type.rawValue)")) }
                    if change.op == .subtract, type != .number { issues.append(DialogueIssue(node: node.id, "subtract needs a number, '\(change.variable)' is a \(type.rawValue)")) }
                    if change.op == .add, type == .bool { issues.append(DialogueIssue(node: node.id, "add needs a number or text, '\(change.variable)' is a bool")) }
                    if !change.expression.isEmpty {
                        expression(node, change.expression, "the change to '\(change.variable)'")
                    } else if change.op != .toggle {
                        if let value = change.value {
                            if let v = DialogueValue(json: value), v.type != type, !(change.op == .add && type == .text) {
                                issues.append(DialogueIssue(node: node.id, "'\(change.variable)' is a \(type.rawValue) but gets \(v.description)"))
                            }
                        } else {
                            issues.append(DialogueIssue(node: node.id, "the change to '\(change.variable)' has no value"))
                        }
                    }
                }
                link(node, node.next, "next")
            case .event:
                if node.event.isEmpty { issues.append(DialogueIssue(node: node.id, "the event has no name")) }
                link(node, node.next, "next")
            case .end:
                break
            }
        }

        // Reachability from the start.
        if let first = startNode, nodeIndex(first) != nil {
            var reached: Set<String> = [first]
            var queue = [first]
            while let id = queue.popLast() {
                guard let node = node(id) else { continue }
                for (_, target) in node.links where !reached.contains(target) && nodeIndex(target) != nil {
                    reached.insert(target)
                    queue.append(target)
                }
            }
            for node in nodes where !node.id.isEmpty && !reached.contains(node.id) {
                issues.append(DialogueIssue(node: node.id, "no path from the start reaches it"))
            }
        }
        return issues
    }
}

/// `{name}` placeholders in line text.
public enum DialogueText {
    /// The variable names `text` uses as `{name}`, in order (repeats removed).
    public static func placeholders(in text: String) -> [String] {
        var out: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{") {
            let after = rest[rest.index(after: open)...]
            guard let close = after.firstIndex(of: "}") else { break }
            let name = after[..<close].trimmingCharacters(in: .whitespaces)
            if DialogueExpression.isIdentifier(name), !out.contains(name) { out.append(name) }
            rest = after[after.index(after: close)...]
        }
        return out
    }

    /// `text` with each `{name}` replaced by `value(name)` (left as is when that gives nil).
    public static func fill(_ text: String, _ value: (String) -> String?) -> String {
        guard text.contains("{") else { return text }
        var out = ""
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{") {
            out += rest[..<open]
            let after = rest[rest.index(after: open)...]
            guard let close = after.firstIndex(of: "}") else { out += rest[open...]; return out }
            let name = after[..<close].trimmingCharacters(in: .whitespaces)
            if let replacement = value(name) { out += replacement } else { out += rest[open...close] }
            rest = after[after.index(after: close)...]
        }
        return out + rest
    }
}
