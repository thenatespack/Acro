import EditorCore
import Engine
import Foundation

/// The Animation Graph Builder tools: `animGraph.new`, `animGraph.get`, `animGraph.set`,
/// `animGraph.edit`, `animGraph.assign`, `animGraph.open`.
@MainActor
public enum EditorAnimationGraphCommands {
    public static let all: [any EditorCommand.Type] = [
        AnimGraphNewCommand.self,
        AnimGraphGetCommand.self,
        AnimGraphSetCommand.self,
        AnimGraphEditCommand.self,
        AnimGraphAssignCommand.self,
        AnimGraphOpenCommand.self,
        AnimGraphBonesCommand.self,
        AnimGraphClipEventsCommand.self,
        AnimGraphSetClipEventsCommand.self,
    ]

    /// What the tool docs say about the file format, shared by the tools.
    static let formatDoc = """
        An animation graph (.animgraph) is an Animator state machine; every key is optional: `preview` (the model prefab the \
        builder previews on, an asset reference or path), `retarget` {boneMap {source bone: target bone}, matchNames \
        (default true), rotation world|local|copy, translation root|none|all, rootScale, sampleRate} (plays clips made for another \
        skeleton by matching bones by name; see animGraph.bones), `parameters` [{name, type float|bool|trigger, default}], `states` \
        [{name, clip (one clip) or blend {parameter (a float), clips [{clip, position}]} (a 1D blend space; add \
        parameterY (a second float) and give each clip a `y` for a 2D one, e.g. moveX / moveY for strafing), speed, \
        speedParameter (a float multiplying speed), loops, position [x,y] (node position in the editor)}], `transitions` \
        [{from (a state; omit or "*" for any state), to, conditions [{parameter, test greater|less|isTrue|isFalse|triggered, \
        value}], exitTime (normalized time of the source state, e.g. 0.9), duration (crossfade seconds), canTransitionToSelf}] \
        (checked in order, the first that applies fires), `layers` [{name, clip, weight, speed, referenceTime, blend additive|override \
        (override replaces the bones the clip animates), mask [bone names: the layer only touches their subtrees]}], \
        `initialState`, `ik` [{name, type twoBoneIK|aim|chainIK|footPlacement, bones (twoBoneIK: root, middle, end; aim and \
        chainIK: root to tip), weight 0-1, weightParameter (a float multiplying the weight), target [x,y,z] (world) or \
        targetEntity (an entity's Name), pole [x,y,z] (twoBoneIK: the way the middle joint bends, character space), aimAxis \
        (aim: the last bone's axis that points, default [0,0,1]), maxAngle (aim, degrees per bone), iterations / tolerance \
        (chainIK), legs [[hip, knee, ankle]…] and pelvis (footPlacement: rays against physics, the pelvis drops, feet align \
        and lock), rayHeight, maxStep, alignFeet, lockFeet}] run in order after the states and layers. A state with `machine` {states, transitions, initialState} instead of a clip is a sub-state machine: \
        entering it enters its initial state, its own transitions leave from any state inside, and transitions inside may go to \
        states outside it by name (edit inside with animGraph.edit `level`). Clips are imported glTF clips: "asset:<id>#animation/<name>" or "Models/hero.glb#animation/Walk" (paths \
        are turned into references). Put it on a model with animGraph.assign; scene animators follow the file when it changes.
        """
}

extension EditorSession {
    /// Writes a graph to "`name`.animgraph" (or "… 2") in `folder`. Returns its id.
    @discardableResult
    public func createAnimationGraphAsset(in folder: String, name: String = "New Animation Graph",
                                          graph: AnimationGraph = .starter()) -> AssetID? {
        guard let assets, checkAssetPaths([folder, name], "New Animation Graph") else {
            log.error("New Animation Graph: no project is open")
            return nil
        }
        let path = assets.uniquePath(Self.join(folder, name + ".animgraph"))
        do {
            let id = try assets.createAnimationGraph(graph, at: path)
            log.info("Created animation graph \(path)")
            return id
        } catch {
            log.error("New Animation Graph failed: \(error)")
            return nil
        }
    }

    /// Whether `id` is an `.animgraph` file.
    public func isAnimationGraphFile(_ id: AssetID) -> Bool {
        assets?.record(id)?.importer == AnimationGraphImporter().name
    }

    /// Replaces the contents of the graph `id` as one undo step. Returns the import's warnings, nil on failure.
    @discardableResult
    public func applyAnimationGraph(_ graph: AnimationGraph, to id: AssetID, label: String = "Edit Animation Graph") -> [String]? {
        guard let assets, let old = assets.animationGraph(of: id) else {
            log.error("\(label): \(id) isn't a readable .animgraph file")
            return nil
        }
        guard old != graph else { return [] }
        let command = AnimationGraphFileEditCommand(asset: id, old: old, new: graph, in: assets, label: label)
        guard perform(command) else { return nil }
        return command.warnings.value
    }

    /// `graph`'s problems, including clips that name nothing in the project.
    public func animationGraphProblems(_ graph: AnimationGraph) -> [String] {
        var problems = AnimationGraphCheck.problems(graph, clipExists: { [weak self] key in
            guard let reference = AssetReference(key) else { return true }  // a key registered in code
            return self?.assets?.animationClip(reference) != nil
        })
        // Mask bones the preview model doesn't have.
        if let skeleton = graph.preview.flatMap(AssetReference.init).flatMap({ assets?.animationSkeleton(of: $0) }) {
            for layer in graph.layers {
                for bone in layer.mask ?? [] where Animator.maskTargets([bone], in: skeleton).isEmpty {
                    problems.append("layer '\(layer.name)' masks bone '\(bone)', which the preview model doesn't have")
                }
            }
            // IK bones the preview model doesn't have.
            let names = Set(skeleton.names)
            for node in graph.ik {
                for bone in node.allBones where !names.contains(bone) {
                    problems.append("IK node '\(node.name)' uses bone '\(bone)', which the preview model doesn't have")
                }
            }
        }
        return problems
    }

    /// The clips a graph can use: the preview model's own first, then every other imported clip.
    public func animationClipChoices(for graph: AnimationGraph?) -> [String] {
        guard let assets else { return [] }
        let all = assets.animationClipKeys
        guard let preview = graph?.preview.flatMap(AssetReference.init) else { return all }
        let own = all.filter { AssetReference($0)?.asset == preview.asset }
        return own + all.filter { AssetReference($0)?.asset != preview.asset }
    }

    /// A short readable name for a clip key: "hero.glb › Walk".
    public func clipDisplayName(_ key: String) -> String {
        guard let reference = AssetReference(key), let assets else { return key.isEmpty ? "(none)" : key }
        let file = assets.path(of: reference.asset).map { ($0 as NSString).lastPathComponent } ?? "missing"
        let name = reference.subAsset.map { $0.hasPrefix("animation/") ? String($0.dropFirst(10)) : $0 } ?? "first clip"
        return "\(file) › \(name)"
    }

    /// `graph` with path-style clip and preview keys turned into asset references.
    func normalizedAnimationGraph(_ graph: AnimationGraph) -> AnimationGraph {
        guard let assets else { return graph }
        var graph = graph
        graph.preview = graph.preview.map { assets.normalizedAssetKey($0) }
        func normalize(_ states: inout [AnimationGraphState]) {
            for s in states.indices {
                states[s].clip = states[s].clip.map { assets.normalizedAssetKey($0) }
                if states[s].blend != nil {
                    for c in states[s].blend!.clips.indices {
                        states[s].blend!.clips[c].clip = assets.normalizedAssetKey(states[s].blend!.clips[c].clip)
                    }
                }
                if var machine = states[s].machine {
                    normalize(&machine.states)
                    states[s].machine = machine
                }
            }
        }
        normalize(&graph.states)
        for l in graph.layers.indices { graph.layers[l].clip = assets.normalizedAssetKey(graph.layers[l].clip) }
        return graph
    }
}

/// Makes graph edits undoable: performing writes `new` to the file, reverting writes `old` back.
public struct AnimationGraphFileEditCommand: UndoCommand {
    public var label: String
    public let asset: AssetID
    public let old: AnimationGraph
    public let new: AnimationGraph
    let warnings = Box<[String]>([])
    private weak var database: AssetDatabase?

    final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    public init(asset: AssetID, old: AnimationGraph, new: AnimationGraph, in database: AssetDatabase, label: String = "Edit Animation Graph") {
        self.asset = asset
        self.old = old
        self.new = new
        self.database = database
        self.label = label
    }

    public mutating func perform(in world: World) throws { try write(new) }
    public mutating func revert(in world: World) throws { try write(old) }

    private func write(_ graph: AnimationGraph) throws {
        guard let database else { throw AssetError.noSuchAsset(asset.description) }
        warnings.value = try database.writeAnimationGraph(graph, to: asset)
    }
}

/// Arguments naming an `.animgraph` file.
public protocol AnimGraphTarget {
    var asset: AssetReference? { get }
    var path: String? { get }
}

extension EditorSession {
    func resolveAnimationGraph(_ target: some AnimGraphTarget, _ title: String) throws -> (AssetID, AnimationGraph) {
        let id = try resolveAsset(target.asset, path: target.path, title)
        guard isAnimationGraphFile(id), let graph = assets?.animationGraph(of: id) else {
            throw CommandError.failed("\(title): \(assets?.path(of: id) ?? id.description) isn't a readable .animgraph file")
        }
        return (id, graph)
    }
}

/// What the editing tools return.
public struct AnimGraphResult: Codable, Equatable, Sendable {
    public var asset: AssetID
    public var path: String
    public var states: [String]
    /// "<index>: <from or *> -> <to>", in file order (indices for animGraph.edit).
    public var transitions: [String]
    public var parameters: [String]
    public var layers: [String]
    /// IK node names, in order (nil: none).
    public var ik: [String]?
    public var initialState: String?
    /// Problems: unknown states or parameters, wrong parameter types, missing clips…
    public var warnings: [String]
    /// Sub-state machines, as paths for `level` ("Combat", "Combat/Ranged").
    public var machines: [String]?
    /// The level `states`, `transitions` and `initialState` describe (nil: the top).
    public var level: String?
}

extension AnimGraphResult {
    @MainActor init(_ id: AssetID, _ graph: AnimationGraph, level path: [String] = [], in session: EditorSession) {
        let record = session.assets?.record(id)
        let shown = graph.level(at: path) ?? graph
        let machines = graph.machinePaths.map { $0.joined(separator: AnimationGraph.levelSeparator) }
        self.init(asset: id, path: session.assets?.path(of: id) ?? "", states: shown.states.map(\.name),
                  transitions: shown.transitions.enumerated().map { "\($0.offset): \($0.element.from ?? "*") -> \($0.element.to)" },
                  parameters: graph.parameters.map { "\($0.name) (\($0.type.rawValue))" }, layers: graph.layers.map(\.name),
                  ik: graph.ik.isEmpty ? nil : graph.ik.map { "\($0.name) (\($0.type.rawValue))" },
                  initialState: shown.initialState ?? shown.states.first?.name,
                  warnings: session.animationGraphProblems(graph) + (record?.importError.map { ["import failed: \($0)"] } ?? []),
                  machines: machines.isEmpty ? nil : machines,
                  level: path.isEmpty ? nil : path.joined(separator: AnimationGraph.levelSeparator))
    }
}

public enum AnimGraphNewCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable {
        public var folder: String?
        /// Default "New Animation Graph" (the file gets ".animgraph").
        public var name: String?
        /// The model to preview on (and take clips from): an asset reference or path of a glTF file / prefab.
        public var preview: String?
        /// The contents (default: an Idle state on the preview's first clip, plus a Move state and a `speed`
        /// parameter with a transition each way when it has two clips or more).
        public var graph: AnimationGraph?
        public init(folder: String? = nil, name: String? = nil, preview: String? = nil, graph: AnimationGraph? = nil) {
            self.folder = folder
            self.name = name
            self.preview = preview
            self.graph = graph
        }
    }

    public static let id: CommandID = "animGraph.new"
    public static let title = "New Animation Graph"
    public static let doc = "Writes an .animgraph file in `folder` (default: the Assets root) and imports it: `graph` contents, or a starter (Idle, plus Move on a `speed` parameter when the `preview` model has two clips or more, using its clips). Returns the states, transitions, parameters and warnings. " + EditorAnimationGraphCommands.formatDoc
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> AnimGraphResult {
        let preview = arguments.preview.map { session.assets?.normalizedAssetKey($0) ?? $0 }
        if let preview, AssetReference(preview).flatMap({ session.assets?.record($0.asset) }) == nil {
            throw CommandError.failed("\(title): no model '\(arguments.preview ?? "")'")
        }
        var graph: AnimationGraph
        if var given = arguments.graph {
            if let preview { given.preview = preview }
            graph = given
        } else {
            let clips = preview.flatMap(AssetReference.init).map { reference in
                (session.assets?.animationClipKeys ?? []).filter { AssetReference($0)?.asset == reference.asset }
            } ?? []
            graph = .starter(clips: clips, preview: preview)
        }
        graph = session.normalizedAnimationGraph(graph)
        let id = try session.commands.require(session.createAnimationGraphAsset(
            in: arguments.folder ?? "", name: arguments.name ?? "New Animation Graph", graph: graph), title)
        return AnimGraphResult(id, graph, in: session)
    }
}

public enum AnimGraphGetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        /// The .animgraph file.
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
        public var graph: AnimationGraph
        /// Clips the graph can use (the preview model's first), as asset references.
        public var clips: [String]
        public var warnings: [String]
    }

    public static let id: CommandID = "animGraph.get"
    public static let title = "Get Animation Graph"
    public static let doc = "Reads an .animgraph file: its parameters, states, transitions (in order), layers and preview model (every field, defaults included), the clips it can use, and problems found (unknown states or parameters, wrong parameter types, missing clips, transitions that can't fire)."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, graph) = try session.resolveAnimationGraph(arguments, title)
        let summary = AnimGraphResult(id, graph, in: session)
        return Result(asset: id, path: summary.path, graph: graph, clips: session.animationClipChoices(for: graph), warnings: summary.warnings)
    }
}

public enum AnimGraphSetCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The new contents. Omitted keys take their defaults, not the file's old values.
        public var graph: AnimationGraph
        public init(asset: AssetReference? = nil, path: String? = nil, graph: AnimationGraph) {
            self.asset = asset
            self.path = path
            self.graph = graph
        }
    }

    public static let id: CommandID = "animGraph.set"
    public static let title = "Set Animation Graph"
    public static let doc = "Replaces an .animgraph file's whole contents and reimports it; animators using it follow. Undoable. For a few changes, animGraph.edit is shorter."
    public static let isUndoable = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> AnimGraphResult {
        let (id, _) = try session.resolveAnimationGraph(arguments, title)
        let graph = session.normalizedAnimationGraph(arguments.graph)
        _ = try session.commands.require(session.applyAnimationGraph(graph, to: id, label: title), title)
        return AnimGraphResult(id, graph, in: session)
    }
}

public enum AnimGraphEditCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// Transitions to remove, by index in the file (as animGraph.get lists them).
        public var removeTransitions: [Int]?
        /// States to remove by name (their transitions go too).
        public var removeStates: [String]?
        /// Parameters to remove by name.
        public var removeParameters: [String]?
        /// Layers to remove by name.
        public var removeLayers: [String]?
        /// Parameters to add, or to replace when the name exists: [{name, type, default}].
        public var parameters: [AnimationGraphParameter]?
        /// States to add (a name already taken gets " 2"…; nodes without a position are placed in a row).
        public var addStates: [AnimationGraphState]?
        /// Changes to states: name → the fields to change, e.g. {"Run": {"speed": 1.2, "loops": true}}. A "name" key
        /// renames the state everywhere.
        public var updateStates: [String: JSONValue]?
        /// Transitions to add (appended: checked after the existing ones).
        public var addTransitions: [AnimationGraphTransition]?
        /// Changes to transitions: index (as a string) → the fields to change, e.g. {"0": {"duration": 0.1}}.
        public var updateTransitions: [String: JSONValue]?
        /// Layers to add (additive unless `blend` is "override"; `mask` limits them to bone subtrees).
        public var addLayers: [AnimationGraphLayer]?
        /// Changes to layers: name → fields.
        public var updateLayers: [String: JSONValue]?
        public var initialState: String?
        /// The preview model (asset reference or path).
        public var preview: String?
        /// Retarget options to set (replacing the old ones): clips made for another skeleton play by bone name.
        public var retarget: AnimationRetargetOptions?
        /// True turns retargeting off (clips play by node index).
        public var removeRetarget: Bool?
        /// The sub-state machine whose states, transitions and initial state the edits address, as a path of
        /// state names ("Combat", "Combat/Ranged"); default the top level.
        public var level: String?
        /// IK nodes to remove by name.
        public var removeIK: [String]?
        /// IK nodes to add (appended; a taken name gets " 2"…): {name, type, bones, weight, weightParameter, target, …}.
        public var addIK: [AnimationIKNode]?
        /// Changes to IK nodes: name → fields.
        public var updateIK: [String: JSONValue]?
        public init(asset: AssetReference? = nil, path: String? = nil, removeTransitions: [Int]? = nil, removeStates: [String]? = nil,
                    removeParameters: [String]? = nil, removeLayers: [String]? = nil, parameters: [AnimationGraphParameter]? = nil,
                    addStates: [AnimationGraphState]? = nil, updateStates: [String: JSONValue]? = nil,
                    addTransitions: [AnimationGraphTransition]? = nil, updateTransitions: [String: JSONValue]? = nil,
                    addLayers: [AnimationGraphLayer]? = nil, updateLayers: [String: JSONValue]? = nil, initialState: String? = nil,
                    preview: String? = nil, retarget: AnimationRetargetOptions? = nil, removeRetarget: Bool? = nil, level: String? = nil,
                    removeIK: [String]? = nil, addIK: [AnimationIKNode]? = nil, updateIK: [String: JSONValue]? = nil) {
            self.removeIK = removeIK
            self.addIK = addIK
            self.updateIK = updateIK
            self.asset = asset
            self.path = path
            self.removeTransitions = removeTransitions
            self.removeStates = removeStates
            self.removeParameters = removeParameters
            self.removeLayers = removeLayers
            self.parameters = parameters
            self.addStates = addStates
            self.updateStates = updateStates
            self.addTransitions = addTransitions
            self.updateTransitions = updateTransitions
            self.addLayers = addLayers
            self.updateLayers = updateLayers
            self.initialState = initialState
            self.preview = preview
            self.retarget = retarget
            self.removeRetarget = removeRetarget
            self.level = level
        }
    }

    public static let id: CommandID = "animGraph.edit"
    public static let title = "Edit Animation Graph"
    public static let doc = "Changes part of an .animgraph file in one undoable step, in this order: removeTransitions (indices), removeStates, removeParameters, removeLayers, parameters (add or replace by name), addStates, updateStates (name → fields; \"name\" renames everywhere), addTransitions, updateTransitions (index → fields), addLayers, updateLayers, initialState, preview, retarget / removeRetarget, removeIK, addIK, updateIK (name → fields). With `level` (a sub-state machine's path, e.g. \"Combat\"), the state and transition edits and initialState apply inside that machine, and its transitions may also go to states of enclosing levels (by name). Clip paths become asset references. Returns the states, numbered transitions, parameters and problems. " + EditorAnimationGraphCommands.formatDoc
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> AnimGraphResult {
        let (id, original) = try session.resolveAnimationGraph(arguments, title)
        let path = (arguments.level ?? "").split(separator: Character(AnimationGraph.levelSeparator)).map(String.init)
        guard let level = original.level(at: path) else {
            throw CommandError.failed("\(title): no sub-state machine '\(arguments.level ?? "")' (machines: \(original.machinePaths.map { $0.joined(separator: "/") }.joined(separator: ", ")))")
        }
        let outer = (0..<path.count).flatMap { original.level(at: Array(path.prefix($0)))?.states.map(\.name) ?? [] }
        let changed = try edited(level, with: arguments, outerStates: outer)
        guard let whole = original.replacingLevel(at: path, with: changed) else { throw CommandError.failed("\(title): the level vanished") }
        let graph = session.normalizedAnimationGraph(whole)
        _ = try session.commands.require(session.applyAnimationGraph(graph, to: id, label: title), title)
        return AnimGraphResult(id, graph, level: path, in: session)
    }

    /// `value` with the JSON object `changes` merged over its fields.
    static func merged<T: Codable>(_ value: T, with changes: JSONValue, _ what: String) throws -> T {
        guard case .object(let fields) = changes else { throw CommandError.failed("\(what) must be an object of fields") }
        guard case .object(var current) = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value)) else { return value }
        for (key, value) in fields { current[key] = value }
        do { return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(JSONValue.object(current))) } catch {
            throw CommandError.failed("\(what): \(error)")
        }
    }

    /// Where a new node goes: right of the rightmost node, on the first row.
    static func nextNodePosition(in graph: AnimationGraph) -> Vec2 {
        guard let right = graph.states.map(\.position.x).max() else { return .zero }
        return Vec2(right + 220, graph.states.map(\.position.y).min() ?? 0)
    }

    /// `graph` with the edits of `arguments` applied (pure, for tests and the UI).
    /// `outerStates` are the enclosing levels' states, which transitions inside a sub-state machine may go to.
    public static func edited(_ graph: AnimationGraph, with arguments: Arguments, outerStates: [String] = []) throws -> AnimationGraph {
        var graph = graph
        if let indices = arguments.removeTransitions, !indices.isEmpty {
            let bad = indices.filter { !graph.transitions.indices.contains($0) }
            guard bad.isEmpty else { throw CommandError.failed("No transition \(bad.map(String.init).joined(separator: ", ")) (there are \(graph.transitions.count))") }
            for index in Set(indices).sorted(by: >) { graph.transitions.remove(at: index) }
        }
        for name in arguments.removeStates ?? [] {
            guard graph.state(named: name) != nil else { throw CommandError.failed("No state named \(name)") }
            graph.removeState(name)
        }
        for name in arguments.removeParameters ?? [] {
            guard graph.parameter(named: name) != nil else { throw CommandError.failed("No parameter named \(name)") }
            graph.parameters.removeAll { $0.name == name }
        }
        for name in arguments.removeLayers ?? [] {
            guard graph.layers.contains(where: { $0.name == name }) else { throw CommandError.failed("No layer named \(name)") }
            graph.layers.removeAll { $0.name == name }
        }
        for parameter in arguments.parameters ?? [] {
            guard !parameter.name.isEmpty else { throw CommandError.failed("A parameter needs a name") }
            if let i = graph.parameters.firstIndex(where: { $0.name == parameter.name }) {
                graph.parameters[i] = parameter
            } else {
                graph.parameters.append(parameter)
            }
        }
        for var state in arguments.addStates ?? [] {
            state.name = graph.uniqueStateName(state.name)
            if state.position == .zero, !graph.states.isEmpty { state.position = nextNodePosition(in: graph) }
            graph.states.append(state)
        }
        for (name, changes) in (arguments.updateStates ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = graph.states.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No state named \(name)") }
            var updated = try merged(graph.states[index], with: changes, "updateStates[\(name)]")
            let newName = updated.name.trimmingCharacters(in: .whitespaces)
            updated.name = name
            graph.states[index] = updated
            if !newName.isEmpty, newName != name {
                guard graph.state(named: newName) == nil else { throw CommandError.failed("A state is already named \(newName)") }
                graph.renameState(name, to: newName)
            }
        }
        for transition in arguments.addTransitions ?? [] {
            if let from = transition.from, graph.state(named: from) == nil { throw CommandError.failed("No state named \(from) (transition from)") }
            guard graph.state(named: transition.to) != nil || outerStates.contains(transition.to) else {
                throw CommandError.failed("No state named \(transition.to) (transition to)")
            }
            graph.transitions.append(transition)
        }
        for (key, changes) in (arguments.updateTransitions ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = Int(key), graph.transitions.indices.contains(index) else { throw CommandError.failed("No transition \(key)") }
            graph.transitions[index] = try merged(graph.transitions[index], with: changes, "updateTransitions[\(key)]")
        }
        for var layer in arguments.addLayers ?? [] {
            layer.name = graph.uniqueLayerName(layer.name)
            graph.layers.append(layer)
        }
        for (name, changes) in (arguments.updateLayers ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = graph.layers.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No layer named \(name)") }
            graph.layers[index] = try merged(graph.layers[index], with: changes, "updateLayers[\(name)]")
        }
        if let initial = arguments.initialState {
            guard graph.state(named: initial) != nil else { throw CommandError.failed("No state named \(initial)") }
            graph.initialState = initial
        }
        if let preview = arguments.preview { graph.preview = preview.isEmpty ? nil : preview }
        if arguments.removeRetarget == true { graph.retarget = nil }
        if let retarget = arguments.retarget { graph.retarget = retarget }
        for name in arguments.removeIK ?? [] {
            guard graph.ik.contains(where: { $0.name == name }) else { throw CommandError.failed("No IK node named \(name)") }
            graph.ik.removeAll { $0.name == name }
        }
        for var node in arguments.addIK ?? [] {
            node.name = graph.uniqueIKName(node.name)
            graph.ik.append(node)
        }
        for (name, changes) in (arguments.updateIK ?? [:]).sorted(by: { $0.key < $1.key }) {
            guard let index = graph.ik.firstIndex(where: { $0.name == name }) else { throw CommandError.failed("No IK node named \(name)") }
            let updated = try merged(graph.ik[index], with: changes, "updateIK[\(name)]")
            if updated.name != name, graph.ik.contains(where: { $0.name == updated.name }) {
                throw CommandError.failed("An IK node is already named \(updated.name)")
            }
            graph.ik[index] = updated
        }
        return graph
    }
}

public enum AnimGraphAssignCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        public var asset: AssetReference?
        public var path: String?
        /// The entity (a placed model's root) that gets the Animator (default: the selected entity).
        public var entity: EntityID?
        public init(asset: AssetReference? = nil, path: String? = nil, entity: EntityID? = nil) {
            self.asset = asset
            self.path = path
            self.entity = entity
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        public var entity: EntityID
        public var graph: AssetReference
        /// How many entities of the model the animator drives.
        public var targets: Int
        public var warnings: [String]
    }

    public static let id: CommandID = "animGraph.assign"
    public static let title = "Assign Animation Graph"
    public static let doc = "Puts an Animator playing an .animgraph on an entity (default: the selection), usually a placed model's root: its targets are the entity and its descendants depth first, which is how imported clips address a model's nodes. Replaces an Animator already there. Undoable. The animator plays in play mode and in exported games, and follows the graph file when it changes."
    public static let isUndoable = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let (id, graph) = try session.resolveAnimationGraph(arguments, title)
        let world = session.world
        guard let entityID = arguments.entity ?? session.selection.primary else {
            throw CommandError.failed("\(title): pass `entity` or select one")
        }
        let entity = try world.require(entityID)
        let reference = AssetReference(id)
        var animator = Animator(graph: graph, reference: reference, rigOf: entity, in: world)
        if let old = world.get(Animator.self, for: entity) {
            animator.speed = old.speed
            animator.isPlaying = old.isPlaying
            _ = try session.commands.check(session.perform(try SetComponentCommand(entity, to: animator, in: world, label: title)), title)
        } else {
            _ = try session.commands.check(session.perform(try AddComponentCommand(entity, animator, in: world, label: title)), title)
        }
        return Result(entity: entityID, graph: reference, targets: animator.targets.count, warnings: session.animationGraphProblems(graph))
    }
}

public enum AnimGraphBonesCommand: EditorCommand {
    public struct Arguments: Codable, Equatable, Sendable, AnimGraphTarget {
        /// The .animgraph file whose preview model and retarget options to use (optional).
        public var asset: AssetReference?
        public var path: String?
        /// The model the clip plays on (a glTF file, prefab or .character; asset reference or path). Default: the graph's preview.
        public var model: String?
        /// The clip to check (asset reference or path, e.g. "Models/walk.glb#animation/Walk").
        public var clip: String
        /// Options to try instead of the graph's (or the defaults).
        public var retarget: AnimationRetargetOptions?
        public init(asset: AssetReference? = nil, path: String? = nil, model: String? = nil, clip: String,
                    retarget: AnimationRetargetOptions? = nil) {
            self.asset = asset
            self.path = path
            self.model = model
            self.clip = clip
            self.retarget = retarget
        }
    }

    public struct Result: Codable, Equatable, Sendable {
        /// Model bone → the clip's bone driving it.
        public var matched: [String: String]
        /// Model bones nothing in the clip drives (they keep their rest pose).
        public var unmatchedModelBones: [String]
        /// Animated clip bones that drive nothing on the model.
        public var unmatchedClipBones: [String]
        /// Whether the clip has to be retargeted to play on the model (the node layouts differ, or a bone map renames).
        public var needsRetarget: Bool
        public var modelBones: [String]
        public var clipBones: [String]
    }

    public static let id: CommandID = "animGraph.bones"
    public static let title = "Match Animation Bones"
    public static let doc = "Shows how a clip's bones pair with a model's when retargeted by name: matched pairs, model bones left at rest, and animated clip bones that drive nothing, under the graph's `retarget` options (or `retarget` given here). Use it to write a `boneMap` before setting `retarget` with animGraph.edit. `model` (a glTF file, prefab or .character) defaults to the graph's preview."
    public static let isReadOnly = true
    public static let isIdempotent = true
    public static func isAvailable(in session: EditorSession) -> Bool { hasProject(session) }
    public static func unavailableReason(in session: EditorSession) -> String? { noProjectReason }
    public static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        guard let assets = session.assets else { throw CommandError.failed(noProjectReason) }
        var graph: AnimationGraph?
        if arguments.asset != nil || arguments.path != nil { graph = try session.resolveAnimationGraph(arguments, title).1 }
        guard let modelKey = arguments.model.map({ assets.normalizedAssetKey($0) }) ?? graph?.preview else {
            throw CommandError.failed("\(title): pass `model`, or a graph with a preview model")
        }
        guard let modelReference = AssetReference(modelKey), let target = assets.animationSkeleton(of: modelReference) else {
            throw CommandError.failed("\(title): '\(arguments.model ?? modelKey)' isn't a model with a node tree or a .character")
        }
        guard let clipReference = AssetReference(assets.normalizedAssetKey(arguments.clip)),
              let clip = assets.animationClip(clipReference) else {
            throw CommandError.failed("\(title): no clip '\(arguments.clip)'")
        }
        guard let source = clip.skeleton else {
            throw CommandError.failed("\(title): '\(arguments.clip)' doesn't record its skeleton (reimport its model)")
        }
        let options = arguments.retarget ?? graph?.retarget ?? AnimationRetargetOptions()
        let map = AnimationRetargetMap(source: source, target: target, options: options)
        var matched: [String: String] = [:]
        for (t, s) in map.sourceOfTarget.enumerated() { if let s { matched[target.bones[t].name] = source.bones[s].name } }
        let animated = Set(clip.channels.map(\.target))
        let used = Set(map.sourceOfTarget.compactMap { $0 })
        return Result(matched: matched, unmatchedModelBones: map.unmatchedTargets,
                      unmatchedClipBones: source.bones.indices.filter { animated.contains($0) && !used.contains($0) }.map { source.bones[$0].name },
                      needsRetarget: AnimatorClipCache.needsRetarget(source: source, target: target, options: options),
                      modelBones: target.names, clipBones: source.names)
    }
}
