import Engine
import Foundation

/// The dialogue tools: `dialogue.new`, `dialogue.get`, `dialogue.set`, `dialogue.edit`,
/// `dialogue.play`, `dialogue.open`.
@MainActor
public enum EditorDialogueCommands {
    public static let all: [any EditorCommand.Type] = [
        DialogueNewCommand.self,
        DialogueGetCommand.self,
        DialogueSetCommand.self,
        DialogueEditCommand.self,
        DialoguePlayCommand.self,
        DialogueOpenCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A .dialogue file is a branching conversation: `start` (node id), `speakers` [{id, name, portrait (texture path), \
        color "#RRGGBB"}], `variables` [{name, type number|bool|text, default}] and `nodes` [{id, type, ...}]. Node types: \
        line {speaker, text, key, next}; choice {speaker?, text? (prompt), choices [{text, key, next, condition}], next \
        (used when no option is available)}; condition {condition, next (true), else (false)}; set {changes [{variable, \
        op set|add|subtract|toggle, value | expression}], next}; event {event, args {}, next}; end. An empty next ends the \
        conversation. Text fills in {variable}. Conditions/expressions: `gold >= 10 && !paid`, `visits + 1` (== != < <= > \
        >= && || ! and or not + - * / parentheses, "strings"). `key` is a localization key per line/option. `position` \
        [x, y] places the node in the graph view (omitted: placed automatically). Problems (missing nodes, unknown \
        speakers/variables, bad conditions, unreachable nodes) come back as `warnings`. In game a DialoguePlayer component \
        {dialogue: path, startNode, autoStart} plays it; game code uses world.dialogues?.start(entity), \
        world.dialogue(for:)?.setVariable / .variable, and world.dialogues?.onEvent.
        """
}

extension EditorSession {
    /// Writes a dialogue to "`name`.dialogue" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createDialogueAsset(in folder: String, name: String = "New Dialogue", dialogue: DialogueAsset = .starter) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Dialogue") else {
            log.error("New Dialogue: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".dialogue"))
        do {
            let id = try assets.createDialogue(dialogue, at: path)
            log.info("Created dialogue \(path)")
            return id
        } catch {
            log.error("New Dialogue failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.dialogue` file.
    public func isDialogueFile(_ id: AssetID) -> Bool { assets?.isDialogue(id) ?? false }

    /// Replaces the contents of the dialogue `id` as one undo step. Returns the import's
    /// warnings, nil on failure.
    @discardableResult
    public func applyDialogue(_ dialogue: DialogueAsset, to id: AssetID, label: String = "Edit Dialogue") -> [String]? {
        guard let assets, let old = assets.dialogueContents(of: id) else {
            log.error("\(label): \(id) isn't a readable .dialogue file")
            return nil
        }
        guard old != dialogue else { return [] }
        let command = DialogueFileEditCommand(asset: id, old: old, new: dialogue, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// The dialogue named by `target` and its contents.
    func resolveDialogue(_ target: some DialogueTarget, _ title: String) throws -> (AssetID, DialogueAsset) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isDialogueFile(id), let dialogue = assets?.dialogueContents(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .dialogue file")
        }
        return (id, dialogue)
    }

    /// Problems with `dialogue` as the project sees it (portraits checked).
    func dialogueWarnings(_ dialogue: DialogueAsset) -> [String] {
        (assets?.dialogueIssues(dialogue) ?? dialogue.validate()).map(\.description)
    }
}

/// Makes dialogue edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct DialogueFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: DialogueAsset
    public let new: DialogueAsset
    let warnings = TableFileEditCommand.Box<[String]>([])
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: DialogueAsset, new: DialogueAsset, in database: AssetDatabase, label: String = "Edit Dialogue") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ dialogue: DialogueAsset) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeDialogue(dialogue, to: asset)
    }
}

/// Arguments naming a `.dialogue` file.
public protocol DialogueTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

/// What the editing tools return.
public struct DialogueResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    /// The node conversations start at.
    public var start: String
    /// "id (type): summary" per node, in file order.
    public var nodes: [String]
    public var speakers: [String]
    public var variables: [String]
    /// Problems: links to missing nodes, unknown speakers or variables, bad conditions, unreachable nodes, import failures.
    public var warnings: [String]
}

extension DialogueResult {
    @MainActor init(_ id: AssetID, _ dialogue: DialogueAsset, in session: EditorSession) {
        let record = session.assets?.record(id)
        self.init(asset: id, path: record?.path ?? "", start: dialogue.startNode ?? "",
                  nodes: dialogue.nodes.map { "\($0.id) (\($0.type.rawValue)): \($0.summary)" },
                  speakers: dialogue.speakers.map(\.id), variables: dialogue.variables.map { "\($0.name): \($0.type.rawValue)" },
                  warnings: session.dialogueWarnings(dialogue) + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum DialogueNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Dialogue" (the file gets ".dialogue").
        public var name: String?
        /// The contents. Omitted: a small starter conversation (a greeting, a choice, an end), unless `empty` is true.
        public var dialogue: DialogueAsset?
        /// Start with no nodes instead of the starter.
        public var empty: Bool?
        public init(folder: String? = nil, name: String? = nil, dialogue: DialogueAsset? = nil, empty: Bool? = nil) {
            self.folder = folder
            self.name = name
            self.dialogue = dialogue
            self.empty = empty
        }
    }

    public static let id: CommandID = "dialogue.new"
    public static let title = "New Dialogue"
    public static let doc = "Writes a .dialogue file in `folder` (default: the Assets root) and imports it: `dialogue` as given, else a starter conversation (or nothing with empty: true). Returns the asset, node summaries and warnings. Build it up with dialogue.edit {addNodes, connect, variables, speakers}, try it with dialogue.play. " + EditorDialogueCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> DialogueResult {
        var dialogue = arguments.dialogue ?? (arguments.empty == true ? DialogueAsset() : .starter)
        dialogue.placeUnpositionedNodes()
        let id = try session.commands.require(session.createDialogueAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Dialogue", dialogue: dialogue), title)
        return DialogueResult(id, dialogue, in: session)
    }
}

public enum DialogueGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, DialogueTarget {
        /// The .dialogue file.
        public var asset: AssetReference?
        /// Or its path relative to `Assets/`.
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var asset: AssetID
        public var path: String
        public var dialogue: DialogueAsset
        public var warnings: [String]
        /// Every localization key with its text (lines, prompts, options).
        public var localizationKeys: [String: String]
    }

    public static let id: CommandID = "dialogue.get"
    public static let title = "Get Dialogue"
    public static let doc = "Reads a .dialogue file: speakers, variables and nodes as stored, its problems, and its localization keys with their text."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, dialogue) = try session.resolveDialogue(arguments, title)
        let summary = DialogueResult(id, dialogue, in: session)
        var keys: [String: String] = [:]
        for entry in dialogue.localizationEntries { keys[entry.key] = entry.text }
        return Result(asset: id, path: summary.path, dialogue: dialogue, warnings: summary.warnings, localizationKeys: keys)
    }
}

public enum DialogueSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, DialogueTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var dialogue: DialogueAsset
        public init(asset: AssetReference? = nil, path: String? = nil, dialogue: DialogueAsset) {
            self.asset = asset
            self.path = path
            self.dialogue = dialogue
        }
    }

    public static let id: CommandID = "dialogue.set"
    public static let title = "Set Dialogue"
    public static let doc = "Replaces a .dialogue file's whole contents and reimports it (running games pick it up). Undoable. Nodes without a position are placed automatically. For a few changes, dialogue.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> DialogueResult {
        let (id, _) = try session.resolveDialogue(arguments, title)
        var dialogue = arguments.dialogue
        dialogue.placeUnpositionedNodes()
        _ = try session.commands.require(session.applyDialogue(dialogue, to: id, label: title), title)
        return DialogueResult(id, dialogue, in: session)
    }
}

public enum DialogueEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, DialogueTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Speakers to add or replace by id: {id, name, portrait, color}.
        public var speakers: [DialogueSpeaker]?
        public var removeSpeakers: [String]?
        /// Variables to add or replace by name: {name, type number|bool|text, default}.
        public var variables: [DialogueVariable]?
        public var removeVariables: [String]?
        /// Node ids to remove (links to them are cleared).
        public var removeNodes: [String]?
        /// Nodes to add (see the format); a missing or taken id gets the type's name plus a number.
        public var addNodes: [DialogueNode]?
        /// Node id → fields to change, e.g. {"hello": {"text": "Hi!"}}; null resets a field; "id" renames (links follow).
        public var updateNodes: [String: JSONValue]?
        /// Links: {from, to} sets next; {from, to, choice: 1} sets an option's next; {from, to, text: "Leave"} adds an option to a choice node; {from, to, branch: "else"} for conditions; empty `to` unlinks.
        public var connect: [DialogueConnection]?
        /// The start node.
        public var start: String?
        /// Fill in missing localization keys with this prefix ("" for none): "<prefix>.<node>" and "<prefix>.<node>.<option>".
        public var generateKeys: String?
        /// Re-place every node in columns by distance from the start.
        public var layout: Bool?
        public init(asset: AssetReference? = nil, path: String? = nil, speakers: [DialogueSpeaker]? = nil, removeSpeakers: [String]? = nil,
                    variables: [DialogueVariable]? = nil, removeVariables: [String]? = nil, removeNodes: [String]? = nil,
                    addNodes: [DialogueNode]? = nil, updateNodes: [String: JSONValue]? = nil, connect: [DialogueConnection]? = nil,
                    start: String? = nil, generateKeys: String? = nil, layout: Bool? = nil) {
            self.asset = asset
            self.path = path
            self.speakers = speakers
            self.removeSpeakers = removeSpeakers
            self.variables = variables
            self.removeVariables = removeVariables
            self.removeNodes = removeNodes
            self.addNodes = addNodes
            self.updateNodes = updateNodes
            self.connect = connect
            self.start = start
            self.generateKeys = generateKeys
            self.layout = layout
        }

        var edit: DialogueEdit {
            DialogueEdit(speakers: speakers, removeSpeakers: removeSpeakers, variables: variables, removeVariables: removeVariables,
                         removeNodes: removeNodes, addNodes: addNodes, updateNodes: updateNodes, connect: connect, start: start,
                         generateKeys: generateKeys, layout: layout)
        }
    }

    public static let id: CommandID = "dialogue.edit"
    public static let title = "Edit Dialogue"
    public static let doc = "Changes part of a .dialogue file in one undoable step, in this order: speakers, removeSpeakers, variables, removeVariables, removeNodes, addNodes, updateNodes, connect, start, generateKeys, layout. Returns node summaries and warnings."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> DialogueResult {
        let (id, original) = try session.resolveDialogue(arguments, title)
        let dialogue: DialogueAsset
        do { dialogue = try original.applying(arguments.edit) } catch { throw CommandError.failed("\(title): \(error)") }
        _ = try session.commands.require(session.applyDialogue(dialogue, to: id, label: title), title)
        return DialogueResult(id, dialogue, in: session)
    }
}

public enum DialoguePlayCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, DialogueTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The node to start at (default: the dialogue's start).
        public var start: String?
        /// Variables to set before starting, e.g. {"gold": 25, "paid": false}.
        public var variables: [String: JSONValue]?
        /// The options to pick at each choice, in order (indices among the shown options). The
        /// play-through stops at the first choice with none left.
        public var choices: [Int]?
        /// Localization key → text to play with (e.g. one language's strings).
        public var strings: [String: String]?
        /// The most lines to step through (default 200).
        public var maxLines: Int?
    }

    public struct Step: Codable, Equatable, Sendable {
        /// line, choices, chose, event, variable, end, warning.
        public var kind: String
        public var node: String?
        public var speaker: String?
        public var text: String?
        /// For a choices step: the options shown.
        public var options: [String]?
        public var event: String?
        public var args: [String: JSONValue]?
        public var variable: String?
        public var value: JSONValue?
    }

    public struct Result: Codable, Equatable, Sendable {
        /// What happened, in order.
        public var transcript: [Step]
        /// finished, or waiting (at a choice with no `choices` left, or after maxLines).
        public var state: String
        /// The node it stopped at (when waiting).
        public var node: String?
        /// Every variable's value at the end.
        public var variables: [String: JSONValue]
        /// The events sent, in order.
        public var events: [String]
    }

    public static let id: CommandID = "dialogue.play"
    public static let title = "Play Dialogue"
    public static let doc = "Plays a .dialogue file through without the game: lines are continued automatically, choices are picked from `choices` in order, variables start from the file's defaults plus `variables`. Returns the transcript (lines with speaker and filled-in text, options shown, picks, events, variable changes), where it stopped and the final variables. Use it to test branches and conditions."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (_, dialogue) = try session.resolveDialogue(arguments, title)
        return play(dialogue, arguments)
    }

    /// The play-through (pure, for tests).
    static func play(_ dialogue: DialogueAsset, _ arguments: Arguments) -> Result {
        var given: [String: DialogueValue] = [:]
        for (name, value) in arguments.variables ?? [:] { if let v = DialogueValue(json: value) { given[name] = v } }
        let runner = DialogueRunner(dialogue)
        runner.setVariables(given)
        if let strings = arguments.strings { runner.useLocalization(strings) }
        var transcript: [Step] = []
        var events: [String] = []
        var picks = arguments.choices ?? []
        var lines = 0
        let maxLines = max(arguments.maxLines ?? 200, 1)
        var logged = 0
        func drain() {
            for entry in runner.history.dropFirst(logged) {
                switch entry {
                case .line(let line):
                    transcript.append(Step(kind: "line", node: line.node, speaker: line.speaker?.displayName ?? (line.speakerID.isEmpty ? nil : line.speakerID),
                                           text: line.text))
                case .chose(let node, let text): transcript.append(Step(kind: "chose", node: node, text: text))
                case .event(let event):
                    events.append(event.name)
                    transcript.append(Step(kind: "event", node: event.node, event: event.name, args: event.args.isEmpty ? nil : event.args))
                case .variable(let name, let value): transcript.append(Step(kind: "variable", variable: name, value: value.json))
                case .ended: transcript.append(Step(kind: "end"))
                case .warning(let message): transcript.append(Step(kind: "warning", text: message))
                }
            }
            logged = runner.history.count
        }
        runner.start(at: arguments.start)
        var waitingAt: String?
        loop: while true {
            drain()
            switch runner.state {
            case .line:
                lines += 1
                if lines >= maxLines { waitingAt = runner.currentNode; break loop }
                runner.advance()
            case .choices(let choices):
                transcript.append(Step(kind: "choices", node: choices.node, speaker: choices.speaker?.displayName,
                                       text: choices.prompt.isEmpty ? nil : choices.prompt, options: choices.options.map(\.text)))
                guard !picks.isEmpty else { waitingAt = choices.node; break loop }
                let pick = picks.removeFirst()
                if !runner.choose(pick) {
                    transcript.append(Step(kind: "warning", text: "option \(pick) isn't shown (\(choices.options.count) options)"))
                    waitingAt = choices.node
                    break loop
                }
            case .idle, .finished:
                break loop
            }
        }
        drain()
        var variables: [String: JSONValue] = [:]
        for (name, value) in runner.variables { variables[name] = value.json }
        return Result(transcript: transcript, state: waitingAt == nil ? "finished" : "waiting", node: waitingAt, variables: variables, events: events)
    }
}

public enum DialogueOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, DialogueTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "dialogue.open"
    public static let title = "Open in Dialogue Builder"
    public static let doc = "Opens a .dialogue file in the editor's Dialogue tab (graph view, node form and a play-through preview that tracks variables) and brings the tab to the front. view.screenshot {source: \"panel\", panel: \"dialogue\"} shows it."
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> PathResult {
        let (id, _) = try session.resolveDialogue(arguments, title)
        session.openDialogue = id
        session.onOpenDialogue?(id)
        return PathResult(path: session.assets?.path(of: id) ?? "")
    }
}
