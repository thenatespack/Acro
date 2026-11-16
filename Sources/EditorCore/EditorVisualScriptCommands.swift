import Engine
import Foundation

/// The visual script tools: `vscript.new`, `vscript.get`, `vscript.set`, `vscript.edit`,
/// `vscript.nodes`, `vscript.validate`, `vscript.attach`, `vscript.open`, `vscript.step`.
@MainActor
public enum EditorVisualScriptCommands {
    public static let all: [any EditorCommand.Type] = [
        VScriptNewCommand.self,
        VScriptGetCommand.self,
        VScriptSetCommand.self,
        VScriptEditCommand.self,
        VScriptNodesCommand.self,
        VScriptValidateCommand.self,
        VScriptAttachCommand.self,
        VScriptOpenCommand.self,
        VScriptStepCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        A .vscript file is a node graph run by the VisualScript component in play mode and built games (no game module \
        needed; edits apply while playing). `nodes`: {id, type, x, y, config {settings such as variable, component, field, \
        key, name}, inputs {literal values for unconnected input pins}}. `links`: {"from": "node.pin", "to": "node.pin"}, \
        always from an output pin to an input pin. Exec pins carry the flow (most nodes: input `in`, output `out`; branch: \
        `true`/`false`; loops: `body`/`done`); event nodes (event.start, event.update, event.keyPressed, \
        event.triggerEnter, event.custom…) start flows. Data pins are typed (bool, int, float, string, vec2, vec3, vec4, \
        color, quat, entity, asset, array, map, any) and convert automatically where it makes sense; an unconnected entity \
        input means the script's own entity. `variables`: {name, type, default, exposed}; `functions`: {name, inputs, outputs, \
        nodes, links} called with function.call (config.function), starting at function.entry and ending at function.return. \
        `actions`: input actions {"jump": ["key.space", "pad.south"]} for event.actionPressed. List node types and their \
        pins with vscript.nodes {search}.
        """
}

extension EditorSession {
    /// Writes a visual script to "`name`.vscript" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createVisualScriptAsset(in folder: String, name: String = "New Script", graph: VisualScriptGraph = VisualScriptTemplate.empty.graph) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Visual Script") else {
            log.error("New Visual Script: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".vscript"))
        do {
            let id = try assets.createVisualScript(graph, at: path)
            log.info("Created visual script \(path)")
            return id
        } catch {
            log.error("New Visual Script failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is a `.vscript` file.
    public func isVisualScriptFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == VisualScriptImporter().name
    }

    /// Replaces the graph in `id` as one undo step (undo writes the old graph back). Returns
    /// false on failure.
    @discardableResult
    public func applyVisualScript(_ graph: VisualScriptGraph, to id: AssetID, label: String = "Edit Visual Script") -> Bool {
        guard let assets, let old = assets.visualScript(of: id) else {
            log.error("\(label): \(id) isn't a readable .vscript file")
            return false
        }
        guard old != graph else { return true }
        return perform(VisualScriptFileEditCommand(asset: id, old: old, new: graph, in: assets, label: label))
    }

    /// Puts a `VisualScript` running `id` on `entity` (replacing one it has), with the graph's
    /// exposed variables listed at their defaults (values the entity already had are kept). One undo step.
    @discardableResult
    public func attachVisualScript(_ id: AssetID, to entity: EntityID) -> Bool {
        guard let target = world.entity(for: entity), let graph = assets?.visualScript(of: id) else {
            log.error("Attach Visual Script: no entity \(entity) or no graph \(id)")
            return false
        }
        var component = VisualScript(graph: AssetReference(id).description, defaults: graph)
        if let existing = world.get(VisualScript.self, for: target) {
            for (name, value) in existing.variables where component.variables[name] != nil { component.variables[name] = value }
        }
        do { return perform(try AddComponentCommand(target, component, in: world)) } catch {
            log.error("Attach Visual Script failed: \(error)")
            return false
        }
    }

    /// The visual scripts running in play mode (nil while editing).
    public var visualScriptRuntime: VisualScriptRuntime? { VisualScriptRuntime.runtime(for: world) }
}

/// Makes graph edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct VisualScriptFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: VisualScriptGraph
    public let new: VisualScriptGraph
    private weak var database: AssetDatabase?

    public init(asset: AssetID, old: VisualScriptGraph, new: VisualScriptGraph, in database: AssetDatabase, label: String = "Edit Visual Script") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ graph: VisualScriptGraph) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        try database.writeVisualScript(graph, to: asset)
    }
}

/// Arguments naming a `.vscript` file.
public protocol VScriptTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    func resolveVisualScript(_ target: some VScriptTarget, _ title: String) throws -> (AssetID, VisualScriptGraph) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isVisualScriptFile(id), let graph = assets?.visualScript(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .vscript file")
        }
        return (id, graph)
    }
}

/// What the editing tools return.
public struct VScriptResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    public var nodes: [String]
    public var variables: [String]
    public var functions: [String]
    /// Ids of nodes this call added (vscript.edit).
    public var added: [String]?
    /// The entity the graph was attached to (vscript.new with `target`).
    public var attachedTo: EntityID?
    /// Errors and warnings, as text ("node branch1.condition: required input 'condition' is not connected").
    public var warnings: [String]
}

extension VScriptResult {
    @MainActor init(_ id: AssetID, _ graph: VisualScriptGraph, in session: EditorSession, added: [String]? = nil, attachedTo: EntityID? = nil) {
        let record = session.assets?.record(id)
        let issues = VisualScriptValidator.validate(graph).filter { $0.severity != .info }
        self.init(asset: id, path: record?.path ?? "", nodes: graph.nodes.map(\.id), variables: graph.variables.map(\.name),
                  functions: graph.functions.map(\.name), added: added, attachedTo: attachedTo,
                  warnings: issues.map(\.description) + (record?.importError.map { ["import failed: \($0)"] } ?? []))
    }
}

public enum VScriptNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Script" (the file gets ".vscript").
        public var name: String?
        /// empty (default), spinner, mover, pickup, timer.
        public var template: VisualScriptTemplate?
        /// An entity to run the graph on (gets a VisualScript component).
        public var target: EntityID?
        public init(folder: String? = nil, name: String? = nil, template: VisualScriptTemplate? = nil, target: EntityID? = nil) {
            self.folder = folder
            self.name = name
            self.template = template
            self.target = target
        }
    }

    public static let id: CommandID = "vscript.new"
    public static let title = "New Visual Script"
    public static let doc = "Writes a .vscript graph in `folder` (default: the Assets root) from `template` (empty, spinner, mover, pickup, timer) and imports it; with `target` (an entity id) also puts a VisualScript component running it on that entity (undoable). Build it with vscript.edit (addNodes, connect, variables…), find nodes with vscript.nodes. " + EditorVisualScriptCommands.formatDoc
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VScriptResult {
        let template = arguments.template ?? .empty
        let graph = template.graph
        let id = try session.commands.require(session.createVisualScriptAsset(
            in: arguments.folder ?? "", name: arguments.name ?? (template == .empty ? "New Script" : template.rawValue.capitalized), graph: graph), title)
        if let target = arguments.target {
            guard session.attachVisualScript(id, to: target) else { throw CommandError.failed("\(title): couldn't attach it to \(target)") }
        }
        return VScriptResult(id, graph, in: session, attachedTo: arguments.target)
    }
}

public enum VScriptGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        /// The .vscript file.
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
        public var graph: VisualScriptGraph
        public var issues: [VisualScriptIssue]
    }

    public static let id: CommandID = "vscript.get"
    public static let title = "Get Visual Script"
    public static let doc = "Reads a .vscript graph as stored (variables, nodes, links, functions, comments, actions) and its problems."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, graph) = try session.resolveVisualScript(arguments, title)
        return Result(asset: id, path: session.assets?.path(of: id) ?? "", graph: graph, issues: VisualScriptValidator.validate(graph))
    }
}

public enum VScriptSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        public var asset: AssetReference?
        public var path: String?
        public var graph: VisualScriptGraph
        public init(asset: AssetReference? = nil, path: String? = nil, graph: VisualScriptGraph) {
            self.asset = asset
            self.path = path
            self.graph = graph
        }
    }

    public static let id: CommandID = "vscript.set"
    public static let title = "Set Visual Script"
    public static let doc = "Replaces a .vscript file's whole graph and reimports it (a running game picks it up next frame, keeping variables). Undoable. For a few changes, vscript.edit is shorter. " + EditorVisualScriptCommands.formatDoc
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VScriptResult {
        let (id, _) = try session.resolveVisualScript(arguments, title)
        guard session.applyVisualScript(arguments.graph, to: id, label: title) else { throw CommandError.failed("\(title) failed") }
        return VScriptResult(id, arguments.graph, in: session)
    }
}

public enum VScriptEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Edit the nodes and links of this function instead of the event graph.
        public var function: String?
        public var removeNodes: [String]?
        /// New nodes: {id?, type, x?, y?, config?, inputs?}.
        public var addNodes: [VisualScriptNode]?
        /// Changes by node id: {id, x?, y?, type?, config? (merged), inputs? (merged; null removes), comment?, breakpoint?}.
        public var updateNodes: [VisualScriptNodePatch]?
        /// Links to remove ({from, to}; empty `to` removes all from `from`).
        public var disconnect: [VisualScriptLink]?
        /// Links to add: {"from": "node.pin", "to": "node.pin"}.
        public var connect: [VisualScriptLink]?
        /// Variables to add or replace by name.
        public var variables: [VisualScriptVariable]?
        public var removeVariables: [String]?
        /// Functions to add or replace by name.
        public var functions: [VisualScriptFunction]?
        /// Change functions' pins keeping wires: {function, inputs?, outputs?, renamedInputs? {old: new}, renamedOutputs?}.
        public var signatures: [VisualScriptFunctionSignature]?
        public var removeFunctions: [String]?
        public var comments: [VisualScriptComment]?
        public var removeComments: [String]?
        /// Input actions to add or replace ([] removes).
        public var actions: [String: [String]]?

        public init(asset: AssetReference? = nil, path: String? = nil, function: String? = nil, removeNodes: [String]? = nil,
                    addNodes: [VisualScriptNode]? = nil, updateNodes: [VisualScriptNodePatch]? = nil, disconnect: [VisualScriptLink]? = nil,
                    connect: [VisualScriptLink]? = nil, variables: [VisualScriptVariable]? = nil, removeVariables: [String]? = nil,
                    functions: [VisualScriptFunction]? = nil, signatures: [VisualScriptFunctionSignature]? = nil,
                    removeFunctions: [String]? = nil, comments: [VisualScriptComment]? = nil,
                    removeComments: [String]? = nil, actions: [String: [String]]? = nil) {
            self.asset = asset
            self.path = path
            self.function = function
            self.removeNodes = removeNodes
            self.addNodes = addNodes
            self.updateNodes = updateNodes
            self.disconnect = disconnect
            self.connect = connect
            self.variables = variables
            self.removeVariables = removeVariables
            self.functions = functions
            self.signatures = signatures
            self.removeFunctions = removeFunctions
            self.comments = comments
            self.removeComments = removeComments
            self.actions = actions
        }

        var edit: VisualScriptEdit {
            VisualScriptEdit(function: function, removeNodes: removeNodes, addNodes: addNodes, updateNodes: updateNodes, disconnect: disconnect,
                             connect: connect, variables: variables, removeVariables: removeVariables, functions: functions,
                             signatures: signatures, removeFunctions: removeFunctions, comments: comments, removeComments: removeComments, actions: actions)
        }
    }

    public static let id: CommandID = "vscript.edit"
    public static let title = "Edit Visual Script"
    public static let doc = "Changes part of a .vscript graph in one undoable step, in this order: removeNodes, addNodes, updateNodes, disconnect, connect (in `function` when given), then variables, removeVariables, functions, signatures (a function's inputs and outputs, with renames: wires on its entry, return and call nodes follow, and those to removed pins go), removeFunctions, comments, removeComments, actions. New nodes without an id get one from their type (returned in `added`); nodes without x/y are placed right of the others. A link into a data input that has one replaces it. Returns node ids and problems (unconnected required inputs, type mismatches, unreachable nodes). " + EditorVisualScriptCommands.formatDoc
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VScriptResult {
        let (id, original) = try session.resolveVisualScript(arguments, title)
        let result: (graph: VisualScriptGraph, added: [String])
        do { result = try original.applying(arguments.edit) } catch { throw CommandError.failed("\(title): \(error)") }
        guard session.applyVisualScript(result.graph, to: id, label: title) else { throw CommandError.failed("\(title) failed") }
        return VScriptResult(id, result.graph, in: session, added: result.added)
    }
}

public enum VScriptNodesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        /// Words to find in node types, titles, categories and docs ("branch", "transform", "Light intensity").
        public var search: String?
        /// Only nodes with a pin of this type (as when dragging a wire from such a pin).
        public var pinType: VisualScriptType?
        /// A graph whose variables and functions give get/set/call nodes.
        public var asset: AssetReference?
        public var path: String?
        /// Include a get and a set node per reflected component field (default true).
        public var componentFields: Bool?
        /// Most entries to return (default 60).
        public var limit: Int?
        public init(search: String? = nil, pinType: VisualScriptType? = nil, asset: AssetReference? = nil, path: String? = nil,
                    componentFields: Bool? = nil, limit: Int? = nil) {
            self.search = search
            self.pinType = pinType
            self.asset = asset
            self.path = path
            self.componentFields = componentFields
            self.limit = limit
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Matching nodes before `limit`.
        public var matched: Int
        public var nodes: [VisualScriptNodes.CatalogEntry]
    }

    public static let id: CommandID = "vscript.nodes"
    public static let title = "Visual Script Nodes"
    public static let doc = "Lists the node types a .vscript graph can use, with their pins (name, type, default) and config settings: events, flow, math, vectors, logic, text, arrays, maps, variables, functions, world, transform, components (a get and a set node per reflected field of every registered component, e.g. type component.get with config {component: Light, field: intensity}), audio, effects, physics, scenes, tweens, data tables, and game modules' own nodes. Add one with vscript.edit {addNodes: [{type, config}]} using the entry's `type` and `config`."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        var graph = VisualScriptGraph()
        if arguments.asset != nil || arguments.path != nil { graph = try session.resolveVisualScript(arguments, title).1 }
        let all = VisualScriptNodes.catalog(search: arguments.search ?? "", graph: graph, pinType: arguments.pinType,
                                            includeComponentFields: arguments.componentFields ?? true)
        return Result(matched: all.count, nodes: Array(all.prefix(max(arguments.limit ?? 60, 0))))
    }
}

public enum VScriptValidateCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        public var asset: AssetReference?
        public var path: String?
        /// A graph to check instead of a file.
        public var graph: VisualScriptGraph?
        public init(asset: AssetReference? = nil, path: String? = nil, graph: VisualScriptGraph? = nil) {
            self.asset = asset
            self.path = path
            self.graph = graph
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var valid: Bool
        public var errors: Int
        public var warnings: Int
        public var issues: [VisualScriptIssue]
    }

    public static let id: CommandID = "vscript.validate"
    public static let title = "Validate Visual Script"
    public static let doc = "Checks a .vscript file (or a `graph` given inline): unknown node types, wires to missing pins or between incompatible types, several wires into one input, unconnected required inputs, literal values that don't fit their pin, unreachable nodes (info: unused pure nodes), unknown variables, functions and components, loops among data wires. `valid` means no errors."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let graph = try arguments.graph ?? session.resolveVisualScript(arguments, title).1
        let issues = VisualScriptValidator.validate(graph)
        let errors = issues.filter { $0.severity == .error }.count
        return Result(valid: errors == 0, errors: errors, warnings: issues.filter { $0.severity == .warning }.count, issues: issues)
    }
}

public enum VScriptAttachCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The entity to run the graph on.
        public var entity: EntityID
        public init(asset: AssetReference? = nil, path: String? = nil, entity: EntityID) {
            self.asset = asset
            self.path = path
            self.entity = entity
        }
    }

    public static let id: CommandID = "vscript.attach"
    public static let title = "Attach Visual Script"
    public static let doc = "Puts a VisualScript component running the .vscript graph on `entity` (replacing one it has), with the graph's exposed variables listed for per-entity values. Undoable."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VScriptResult {
        let (id, graph) = try session.resolveVisualScript(arguments, title)
        guard session.attachVisualScript(id, to: arguments.entity) else { throw CommandError.failed("\(title) failed") }
        return VScriptResult(id, graph, in: session, attachedTo: arguments.entity)
    }
}

public enum VScriptOpenCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, VScriptTarget {
        public var asset: AssetReference?
        public var path: String?
        public init(asset: AssetReference? = nil, path: String? = nil) {
            self.asset = asset
            self.path = path
        }
    }

    public static let id: CommandID = "vscript.open"
    public static let title = "Open in Visual Script Editor"
    public static let doc = "Shows a .vscript graph in the Visual Script tab next to the Scene view: nodes and wires on a canvas (drag to move, drag from a pin to wire, right-click or Space to search-add), problems drawn on their nodes and, while playing, the flow highlighted live."
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> VScriptResult {
        let (id, graph) = try session.resolveVisualScript(arguments, title)
        session.openVisualScript = id
        session.onOpenVisualScript?(id)
        return VScriptResult(id, graph, in: session)
    }
}

// MARK: Stepping

/// How `vscript.step` moves: a `VisualScriptStepMode`, or on with play.
public enum VScriptStepAction: String, Codable, Sendable, CaseIterable {
    case into, over, out
    /// Resume play (forgetting the trace).
    case `continue`
}

extension EditorSession {
    /// The trace step shown while paused at a visual script breakpoint.
    public var visualScriptTraceStep: VisualScriptTraceStep? {
        guard let index = visualScriptStep, let trace = visualScriptRuntime?.trace, trace.steps.indices.contains(index) else { return nil }
        return trace.steps[index]
    }

    /// Steps through the flow recorded after the breakpoint. Past the end of the recording, play
    /// resumes until the same entity's graph runs its next node, then pauses there. Returns false
    /// when not paused at a breakpoint.
    @discardableResult
    public func stepVisualScript(_ action: VScriptStepAction) -> Bool {
        guard isPlaying, let runtime = visualScriptRuntime else { return false }
        if action == .continue {
            runtime.clearTrace()
            visualScriptStep = nil
            setPaused(false)
            return true
        }
        guard let index = visualScriptStep, let trace = runtime.trace, trace.steps.indices.contains(index),
              let mode = VisualScriptStepMode(rawValue: action.rawValue) else { return false }
        if let next = trace.next(after: index, mode) {
            visualScriptStep = next
            changed()
        } else {
            runtime.breakAtNextNode(of: trace.steps[index].entity)
            visualScriptStep = nil
            setPaused(false)
        }
        return true
    }
}

/// One recorded node, as `vscript.step` reports it.
public struct VScriptStepInfo: Codable, Equatable, Sendable {
    public var graph: String
    public var entity: EntityID?
    /// The function the node is in (absent: the event graph).
    public var function: String?
    public var node: String
    public var depth: Int
    /// Values as text.
    public var inputs: [String: String]
    public var outputs: [String: String]
    public var variables: [String: String]
    public var error: String?
}

public enum VScriptStepCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        /// into, over, out or continue; omitted: report where play is paused without moving.
        public var mode: VScriptStepAction?
        public init(mode: VScriptStepAction? = nil) { self.mode = mode }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var playing: Bool
        public var paused: Bool
        /// Paused at a breakpoint with a recorded flow to step through.
        public var atBreakpoint: Bool
        /// The step shown, its index and how many the trace holds.
        public var step: VScriptStepInfo?
        public var index: Int?
        public var count: Int
        /// The trace stopped recording at its limit.
        public var truncated: Bool
    }

    public static let id: CommandID = "vscript.step"
    public static let title = "Step Visual Script"
    public static let doc = "While play is paused at a visual script breakpoint: `into` shows the next node of the flow (entering function calls), `over` the next one not inside a call made here, `out` the next one in the caller, `continue` resumes play. The flow from the breakpoint to the end of its event was recorded during the frame (scripts run inside the world's update and can't stop half way), so each step shows that node's inputs, outputs and the variables as it started; past the end, play resumes until the same entity's graph runs another node and pauses there. Without `mode`, reports the current step."
    public static func isAvailable(in session: EditorSession) -> Bool { session.isPlaying }
    public static func unavailableReason(in session: EditorSession) -> String? { "not playing (play.start first)" }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        if let mode = arguments.mode, !session.stepVisualScript(mode) {
            throw CommandError.failed("\(title): play isn't paused at a visual script breakpoint")
        }
        let trace = session.visualScriptRuntime?.trace
        let step = session.visualScriptTraceStep
        return Result(playing: session.isPlaying, paused: session.isPaused, atBreakpoint: step != nil,
                      step: step.map { step in
                          func text(_ values: [String: VisualScriptValue]) -> [String: String] { values.mapValues(\.asString) }
                          return VScriptStepInfo(graph: step.graph, entity: session.world.id(of: step.entity), function: step.function, node: step.node,
                                                 depth: step.depth, inputs: text(step.inputs), outputs: text(step.outputs),
                                                 variables: text(step.variables), error: step.error)
                      },
                      index: step == nil ? nil : session.visualScriptStep, count: step == nil ? 0 : trace?.steps.count ?? 0,
                      truncated: step == nil ? false : trace?.truncated ?? false)
    }
}
