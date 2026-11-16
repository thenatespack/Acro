import Foundation
import EngineCore
import EngineScene

/// The line on screen: who says what (localized, `{variables}` filled in).
public struct DialogueLine: Equatable, Sendable {
    public var node: String
    /// The speaker's id ("" for none) and, when listed, the speaker.
    public var speakerID: String
    public var speaker: DialogueSpeaker?
    public var text: String
    /// The localization key ("" for none).
    public var key: String
    /// Whether the line leads somewhere (false: continuing ends the conversation).
    public var hasNext: Bool
}

/// An option the player can pick.
public struct DialogueOption: Equatable, Sendable {
    /// What to pass to `DialogueRunner.choose(_:)`: the position among the shown options.
    public var index: Int
    /// The option's index in its node's `choices` (hidden options count).
    public var choice: Int
    public var text: String
    public var key: String
    public var next: String
}

/// The options on screen, with the node's optional prompt.
public struct DialogueChoices: Equatable, Sendable {
    public var node: String
    public var speakerID: String
    public var speaker: DialogueSpeaker?
    /// The prompt ("" for none).
    public var prompt: String
    public var options: [DialogueOption]
}

/// An `event` node reached: its name and arguments, for game code.
public struct DialogueEvent: Equatable, Sendable {
    public var name: String
    public var args: [String: JSONValue]
    /// The node that sent it.
    public var node: String

    public init(name: String, args: [String: JSONValue] = [:], node: String = "") {
        self.name = name
        self.args = args
        self.node = node
    }
}

/// One step of a conversation, for previews and logs.
public enum DialogueHistoryEntry: Equatable, Sendable {
    case line(DialogueLine)
    case chose(node: String, text: String)
    case event(DialogueEvent)
    case variable(name: String, value: DialogueValue)
    case ended
    case warning(String)
}

/// A handle for removing a listener (`DialogueRunner.removeListener(_:)`).
public struct DialogueListener: Hashable, Sendable {
    let id: Int
}

/// Plays a conversation: walks the graph from a start node, stops on lines (until `advance()`)
/// and choices (until `choose(_:)`), runs condition, set and event nodes on the way, and keeps
/// the variables. Game code reads and sets variables and listens for events:
///
/// ```swift
/// let runner = DialogueRunner(dialogue)
/// runner.setVariable("gold", 25)
/// runner.onEvent { event in if event.name == "openGate" { gate.open() } }
/// runner.start()
/// if case .line(let line) = runner.state { print(line.speaker?.displayName ?? "", line.text) }
/// runner.advance()
/// runner.choose(0)
/// ```
///
/// A UI shows `state` and answers with `advance()` / `choose(_:)` (see `DialoguePresenter`).
@MainActor
public final class DialogueRunner {
    public enum State: Equatable, Sendable {
        /// Not started (or stopped).
        case idle
        /// A line is shown; `advance()` continues.
        case line(DialogueLine)
        /// Options are shown; `choose(_:)` picks one.
        case choices(DialogueChoices)
        /// The conversation ended.
        case finished
    }

    public private(set) var dialogue: DialogueAsset
    public private(set) var state: State = .idle
    /// The node shown (line or choice), nil when idle or finished.
    public private(set) var currentNode: String?
    /// Every variable: the dialogue's declared ones plus any game code set.
    public private(set) var variables: [String: DialogueValue]
    /// What happened since `start`, oldest first (kept up to `historyLimit` entries).
    public private(set) var history: [DialogueHistoryEntry] = []
    public var historyLimit = 500
    /// Text for a localization key, given the key and the text written in the file; nil uses
    /// the file's text. See `useLocalization`.
    public var localize: ((_ key: String, _ text: String) -> String?)?
    /// Stops a graph that loops through condition / set / event nodes without reaching a line.
    public var maxStepsWithoutStopping = 1000

    private var nextListener = 0
    /// Bumped whenever the conversation jumps (start, stop, a new walk), so a walk notices a listener moved it.
    private var generation = 0
    private var stateListeners: [Int: (State) -> Void] = [:]
    private var eventListeners: [Int: (DialogueEvent) -> Void] = [:]
    private var variableListeners: [Int: (String, DialogueValue) -> Void] = [:]

    public init(_ dialogue: DialogueAsset, variables: [String: DialogueValue] = [:]) {
        self.dialogue = dialogue
        self.variables = dialogue.initialVariables.merging(variables) { _, given in given }
    }

    public var isActive: Bool {
        switch state {
        case .line, .choices: return true
        case .idle, .finished: return false
        }
    }

    // MARK: Listening

    /// Calls `handler` whenever `state` changes (a new line, options, the end).
    @discardableResult
    public func onStateChange(_ handler: @escaping (State) -> Void) -> DialogueListener {
        nextListener += 1
        stateListeners[nextListener] = handler
        return DialogueListener(id: nextListener)
    }

    /// Calls `handler` when an `event` node is reached.
    @discardableResult
    public func onEvent(_ handler: @escaping (DialogueEvent) -> Void) -> DialogueListener {
        nextListener += 1
        eventListeners[nextListener] = handler
        return DialogueListener(id: nextListener)
    }

    /// Calls `handler` when a variable changes (by a `set` node or `setVariable`).
    @discardableResult
    public func onVariableChange(_ handler: @escaping (String, DialogueValue) -> Void) -> DialogueListener {
        nextListener += 1
        variableListeners[nextListener] = handler
        return DialogueListener(id: nextListener)
    }

    public func removeListener(_ listener: DialogueListener) {
        stateListeners[listener.id] = nil
        eventListeners[listener.id] = nil
        variableListeners[listener.id] = nil
    }

    // MARK: Variables

    public func variable(_ name: String) -> DialogueValue? { variables[name] }
    public func number(_ name: String) -> Double? { variables[name]?.number }
    public func bool(_ name: String) -> Bool? { variables[name].map(\.isTruthy) }
    public func text(_ name: String) -> String? { variables[name]?.description }

    /// Sets a variable (converted to its declared type when the dialogue declares it). Doesn't
    /// re-show the current line; the next line reads the new value.
    public func setVariable(_ name: String, _ value: DialogueValue) {
        var value = value
        if let declared = dialogue.variable(name)?.type, let converted = value.converted(to: declared) { value = converted }
        guard variables[name] != value else { return }
        variables[name] = value
        record(.variable(name: name, value: value))
        for handler in variableListeners.values { handler(name, value) }
    }

    /// Sets several variables.
    public func setVariables(_ values: [String: DialogueValue]) {
        for (name, value) in values.sorted(by: { $0.key < $1.key }) { setVariable(name, value) }
    }

    /// Puts every variable back to the dialogue's starting values.
    public func resetVariables() {
        variables = dialogue.initialVariables
    }

    // MARK: Localization

    /// Looks keys up in `strings` (key → text).
    public func useLocalization(_ strings: [String: String]) {
        localize = { key, _ in strings[key] }
    }

    func localized(_ text: String, key: String) -> String {
        let base = key.isEmpty ? text : (localize?(key, text) ?? text)
        return DialogueText.fill(base) { [variables] in variables[$0]?.description }
    }

    // MARK: Playing

    /// Starts (or restarts) at `node` (default: the dialogue's start node). Variables keep their values.
    public func start(at node: String? = nil) {
        history.removeAll()
        guard let first = node.flatMap({ $0.isEmpty ? nil : $0 }) ?? dialogue.startNode else {
            record(.warning("the dialogue has no nodes"))
            finish()
            return
        }
        enter(first)
    }

    /// Continues past the current line. Does nothing unless a line is shown.
    public func advance() {
        guard case .line(let line) = state, let node = dialogue.node(line.node) else { return }
        go(node.next)
    }

    /// Picks the shown option at `index` (`DialogueOption.index`). Returns false when no options
    /// are shown or the index is out of range.
    @discardableResult
    public func choose(_ index: Int) -> Bool {
        guard case .choices(let choices) = state, choices.options.indices.contains(index) else { return false }
        let option = choices.options[index]
        record(.chose(node: choices.node, text: option.text))
        go(option.next)
        return true
    }

    /// Ends the conversation now (state becomes `.idle`).
    public func stop() {
        generation += 1
        currentNode = nil
        setState(.idle)
    }

    /// Swaps in a new version of the dialogue (hot reload). New variables get their starting
    /// values, existing ones keep theirs. A shown line or choice is shown again from the new
    /// version; if its node is gone the conversation finishes.
    public func replace(_ dialogue: DialogueAsset) {
        guard dialogue != self.dialogue else { return }
        self.dialogue = dialogue
        for (name, value) in dialogue.initialVariables where variables[name] == nil { variables[name] = value }
        guard let current = currentNode, isActive else { return }
        if dialogue.node(current) != nil { enter(current) } else { finish() }
    }

    private func go(_ target: String) {
        if target.isEmpty { finish() } else { enter(target) }
    }

    private func enter(_ start: String) {
        generation += 1
        let walk = generation
        var id = start
        for _ in 0..<maxStepsWithoutStopping {
            guard let node = dialogue.node(id) else {
                record(.warning("there is no node '\(id)'"))
                finish()
                return
            }
            switch node.type {
            case .line:
                let line = DialogueLine(node: node.id, speakerID: node.speaker, speaker: dialogue.speaker(node.speaker),
                                        text: localized(node.text, key: node.key), key: node.key, hasNext: !node.next.isEmpty)
                currentNode = node.id
                record(.line(line))
                setState(.line(line))
                return
            case .choice:
                var options: [DialogueOption] = []
                for (i, choice) in node.choices.enumerated() {
                    if !choice.condition.isEmpty {
                        guard let expression = try? DialogueExpression(choice.condition), expression.test({ self.variables[$0] }) else { continue }
                    }
                    options.append(DialogueOption(index: options.count, choice: i, text: localized(choice.text, key: choice.key),
                                                  key: choice.key, next: choice.next))
                }
                if options.isEmpty {
                    guard !node.next.isEmpty else { finish(); return }
                    id = node.next
                    continue
                }
                let choices = DialogueChoices(node: node.id, speakerID: node.speaker, speaker: dialogue.speaker(node.speaker),
                                              prompt: node.text.isEmpty ? "" : localized(node.text, key: node.key), options: options)
                currentNode = node.id
                setState(.choices(choices))
                return
            case .condition:
                let passed: Bool
                do { passed = try DialogueExpression(node.condition).test { self.variables[$0] } } catch {
                    record(.warning("node '\(node.id)': \(error)"))
                    passed = false
                }
                let target = passed ? node.next : node.elseNext
                guard !target.isEmpty else { finish(); return }
                id = target
            case .set:
                for change in node.changes { apply(change, in: node) }
                guard !node.next.isEmpty else { finish(); return }
                id = node.next
            case .event:
                let event = DialogueEvent(name: node.event, args: node.args, node: node.id)
                record(.event(event))
                for handler in eventListeners.values { handler(event) }
                // A listener may have stopped or restarted the conversation.
                guard generation == walk else { return }
                guard !node.next.isEmpty else { finish(); return }
                id = node.next
            case .end:
                finish()
                return
            }
        }
        record(.warning("stopped after \(maxStepsWithoutStopping) steps without a line or choice (a loop?)"))
        finish()
    }

    private func apply(_ change: DialogueChange, in node: DialogueNode) {
        let current = variables[change.variable] ?? DialogueValue.zero(dialogue.variable(change.variable)?.type ?? .number)
        let operand: DialogueValue
        if !change.expression.isEmpty {
            do { operand = try DialogueExpression(change.expression).evaluate { self.variables[$0] } } catch {
                record(.warning("node '\(node.id)': \(error)"))
                return
            }
        } else {
            operand = change.value.flatMap(DialogueValue.init(json:)) ?? .bool(true)
        }
        let result: DialogueValue
        switch change.op {
        case .set: result = operand
        case .add:
            if case .text(let s) = current { result = .text(s + operand.description) } else { result = .number((current.number ?? 0) + (operand.number ?? 0)) }
        case .subtract: result = .number((current.number ?? 0) - (operand.number ?? 0))
        case .toggle: result = .bool(!current.isTruthy)
        }
        setVariable(change.variable, result)
    }

    private func finish() {
        currentNode = nil
        record(.ended)
        setState(.finished)
    }

    private func setState(_ new: State) {
        state = new
        for handler in stateListeners.values { handler(new) }
    }

    private func record(_ entry: DialogueHistoryEntry) {
        history.append(entry)
        if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
    }
}
