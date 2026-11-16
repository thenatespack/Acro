import Foundation
import EngineCore
import EngineScene

// The `.animgraph` file (Animation Graph Builder): an `Animator` state machine as JSON.
//
// ```json
// {
//   "preview": "asset:<id>",
//   "parameters": [{"name": "speed", "type": "float"}, {"name": "jump", "type": "trigger"}],
//   "initialState": "Locomotion",
//   "states": [
//     {"name": "Locomotion", "position": [0, 0],
//      "blend": {"parameter": "speed", "clips": [{"clip": "asset:<id>#animation/Idle", "position": 0},
//                                                {"clip": "asset:<id>#animation/Run", "position": 3}]}},
//     {"name": "Jump", "clip": "asset:<id>#animation/Jump", "loops": false, "position": [240, 0]}
//   ],
//   "transitions": [
//     {"from": "Locomotion", "to": "Jump", "conditions": [{"parameter": "jump", "test": "triggered"}], "duration": 0.1},
//     {"from": "Jump", "to": "Locomotion", "exitTime": 0.9}
//   ],
//   "layers": [{"name": "Breathe", "clip": "asset:<id>#animation/Breathe", "weight": 0.5}]
// }
// ```
//
// Every key is optional. Clips are `AnimationClipHandle` keys: asset references to imported clips
// (a glTF file's `animation/<name>` sub-assets) or keys registered in code. The importer makes an
// `.animationGraph` object; `Animator.graph` points at it and the scene animation system applies
// it (EngineRendering's `AnimationGraph.stateMachine`), again after every reimport.

/// The kind of an `AnimationGraphParameter`.
public enum AnimationGraphParameterType: String, Codable, Sendable, CaseIterable {
    case float, bool, trigger
}

/// A parameter the transitions test and blend spaces read.
public struct AnimationGraphParameter: Codable, Equatable, Sendable {
    public var name: String
    public var type: AnimationGraphParameterType
    /// The starting value: a float's value, 0 or 1 for a bool (triggers start unset).
    public var defaultValue: Float

    public init(name: String, type: AnimationGraphParameterType = .float, defaultValue: Float = 0) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    private enum CodingKeys: String, CodingKey { case name, type, defaultValue = "default" }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "param"
        type = try c.decodeIfPresent(AnimationGraphParameterType.self, forKey: .type) ?? .float
        if let b = try? c.decodeIfPresent(Bool.self, forKey: .defaultValue) {
            defaultValue = b ? 1 : 0
        } else {
            defaultValue = try c.decodeIfPresent(Float.self, forKey: .defaultValue) ?? 0
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        switch type {
        case .float: try c.encode(defaultValue, forKey: .defaultValue)
        case .bool: try c.encode(defaultValue != 0, forKey: .defaultValue)
        case .trigger: break
        }
    }
}

/// A clip at a position along a blend space's parameter.
public struct AnimationGraphBlendClip: Codable, Equatable, Sendable {
    public var clip: String
    public var position: Float

    public init(clip: String, position: Float) {
        self.clip = clip
        self.position = position
    }

    private enum CodingKeys: String, CodingKey { case clip, position }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clip = try c.decodeIfPresent(String.self, forKey: .clip) ?? ""
        position = try c.decodeIfPresent(Float.self, forKey: .position) ?? 0
    }
}

/// A 1D blend space: clips mixed by a float parameter (`AnimationMotion.blend1D`).
public struct AnimationGraphBlend: Codable, Equatable, Sendable {
    public var parameter: String
    public var clips: [AnimationGraphBlendClip]

    public init(parameter: String, clips: [AnimationGraphBlendClip] = []) {
        self.parameter = parameter
        self.clips = clips
    }

    private enum CodingKeys: String, CodingKey { case parameter, clips }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        parameter = try c.decodeIfPresent(String.self, forKey: .parameter) ?? ""
        clips = try c.decodeIfPresent([AnimationGraphBlendClip].self, forKey: .clips) ?? []
    }
}

/// A state: one clip, or a blend space when `blend` is set.
public struct AnimationGraphState: Codable, Equatable, Sendable {
    public var name: String
    public var clip: String?
    public var blend: AnimationGraphBlend?
    public var speed: Float
    /// Multiplies `speed` by this float parameter.
    public var speedParameter: String?
    public var loops: Bool
    /// Where the node sits in the graph editor (points).
    public var position: Vec2

    public init(name: String, clip: String? = nil, blend: AnimationGraphBlend? = nil, speed: Float = 1, speedParameter: String? = nil,
                loops: Bool = true, position: Vec2 = .zero) {
        self.name = name
        self.clip = clip
        self.blend = blend
        self.speed = speed
        self.speedParameter = speedParameter
        self.loops = loops
        self.position = position
    }

    private enum CodingKeys: String, CodingKey { case name, clip, blend, speed, speedParameter, loops, position }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "State"
        clip = try c.decodeIfPresent(String.self, forKey: .clip)
        blend = try c.decodeIfPresent(AnimationGraphBlend.self, forKey: .blend)
        speed = try c.decodeIfPresent(Float.self, forKey: .speed) ?? 1
        speedParameter = try c.decodeIfPresent(String.self, forKey: .speedParameter)
        loops = try c.decodeIfPresent(Bool.self, forKey: .loops) ?? true
        position = try c.decodeIfPresent(Vec2.self, forKey: .position) ?? .zero
    }

    /// Every clip it plays.
    public var clips: [String] { blend.map { $0.clips.map(\.clip) } ?? clip.map { [$0] } ?? [] }
}

/// The test of an `AnimationGraphCondition`.
public enum AnimationGraphTest: String, Codable, Sendable, CaseIterable {
    case greater, less, isTrue, isFalse, triggered

    /// The parameter type the test reads.
    public var parameterType: AnimationGraphParameterType {
        switch self {
        case .greater, .less: .float
        case .isTrue, .isFalse: .bool
        case .triggered: .trigger
        }
    }
}

/// One test of a parameter (`AnimationCondition`).
public struct AnimationGraphCondition: Codable, Equatable, Sendable {
    public var parameter: String
    public var test: AnimationGraphTest
    /// The threshold of `greater` and `less`.
    public var value: Float

    public init(parameter: String, test: AnimationGraphTest = .greater, value: Float = 0) {
        self.parameter = parameter
        self.test = test
        self.value = value
    }

    private enum CodingKeys: String, CodingKey { case parameter, test, value }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        parameter = try c.decodeIfPresent(String.self, forKey: .parameter) ?? ""
        test = try c.decodeIfPresent(AnimationGraphTest.self, forKey: .test) ?? .greater
        value = try c.decodeIfPresent(Float.self, forKey: .value) ?? 0
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(parameter, forKey: .parameter)
        try c.encode(test, forKey: .test)
        if test == .greater || test == .less { try c.encode(value, forKey: .value) }
    }
}

/// A transition (`AnimationTransition`): from a state (nil or "*": any state) to another, when
/// every condition holds and, with `exitTime`, once the source state's normalized time reaches it.
public struct AnimationGraphTransition: Codable, Equatable, Sendable {
    public var from: String?
    public var to: String
    public var conditions: [AnimationGraphCondition]
    public var exitTime: Float?
    /// Crossfade seconds.
    public var duration: Float
    public var canTransitionToSelf: Bool

    public init(from: String?, to: String, conditions: [AnimationGraphCondition] = [], exitTime: Float? = nil, duration: Float = 0.25,
                canTransitionToSelf: Bool = false) {
        self.from = from
        self.to = to
        self.conditions = conditions
        self.exitTime = exitTime
        self.duration = duration
        self.canTransitionToSelf = canTransitionToSelf
    }

    private enum CodingKeys: String, CodingKey { case from, to, conditions, exitTime, duration, canTransitionToSelf }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let source = try c.decodeIfPresent(String.self, forKey: .from)
        from = source == "*" || source == "" ? nil : source
        to = try c.decodeIfPresent(String.self, forKey: .to) ?? ""
        conditions = try c.decodeIfPresent([AnimationGraphCondition].self, forKey: .conditions) ?? []
        exitTime = try c.decodeIfPresent(Float.self, forKey: .exitTime)
        duration = try c.decodeIfPresent(Float.self, forKey: .duration) ?? 0.25
        canTransitionToSelf = try c.decodeIfPresent(Bool.self, forKey: .canTransitionToSelf) ?? false
    }

    /// Whether it starts from any state.
    public var isAnyState: Bool { from == nil }
}

/// An additive layer (`AdditiveAnimationLayer`): a clip's difference from its pose at
/// `referenceTime`, added on top of the state machine's pose.
public struct AnimationGraphLayer: Codable, Equatable, Sendable {
    public var name: String
    public var clip: String
    public var weight: Float
    public var speed: Float
    public var referenceTime: Float

    public init(name: String, clip: String, weight: Float = 1, speed: Float = 1, referenceTime: Float = 0) {
        self.name = name
        self.clip = clip
        self.weight = weight
        self.speed = speed
        self.referenceTime = referenceTime
    }

    private enum CodingKeys: String, CodingKey { case name, clip, weight, speed, referenceTime }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Layer"
        clip = try c.decodeIfPresent(String.self, forKey: .clip) ?? ""
        weight = try c.decodeIfPresent(Float.self, forKey: .weight) ?? 1
        speed = try c.decodeIfPresent(Float.self, forKey: .speed) ?? 1
        referenceTime = try c.decodeIfPresent(Float.self, forKey: .referenceTime) ?? 0
    }
}

/// An `.animgraph` file: parameters, states, transitions and additive layers of an `Animator`,
/// plus the model the editor previews it on. See the notes at the top of this file.
public struct AnimationGraph: Codable, Equatable, Sendable {
    /// The prefab (a glTF model, a character…) the Animation Graph Builder previews on, as an
    /// asset reference; editor only.
    public var preview: String?
    public var parameters: [AnimationGraphParameter]
    public var states: [AnimationGraphState]
    public var transitions: [AnimationGraphTransition]
    public var layers: [AnimationGraphLayer]
    /// Where playback starts (the first state when nil or unknown).
    public var initialState: String?
    /// Where the Any State node sits in the graph editor.
    public var anyStatePosition: Vec2

    public init(preview: String? = nil, parameters: [AnimationGraphParameter] = [], states: [AnimationGraphState] = [],
                transitions: [AnimationGraphTransition] = [], layers: [AnimationGraphLayer] = [], initialState: String? = nil,
                anyStatePosition: Vec2 = Vec2(0, -120)) {
        self.preview = preview
        self.parameters = parameters
        self.states = states
        self.transitions = transitions
        self.layers = layers
        self.initialState = initialState
        self.anyStatePosition = anyStatePosition
    }

    private enum CodingKeys: String, CodingKey { case preview, parameters, states, transitions, layers, initialState, anyStatePosition }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        preview = try c.decodeIfPresent(String.self, forKey: .preview)
        parameters = try c.decodeIfPresent([AnimationGraphParameter].self, forKey: .parameters) ?? []
        states = try c.decodeIfPresent([AnimationGraphState].self, forKey: .states) ?? []
        transitions = try c.decodeIfPresent([AnimationGraphTransition].self, forKey: .transitions) ?? []
        layers = try c.decodeIfPresent([AnimationGraphLayer].self, forKey: .layers) ?? []
        initialState = try c.decodeIfPresent(String.self, forKey: .initialState)
        anyStatePosition = try c.decodeIfPresent(Vec2.self, forKey: .anyStatePosition) ?? Vec2(0, -120)
    }

    public func fileData() throws -> Data { try AssetJSON.encode(self) }

    public func state(named name: String) -> AnimationGraphState? { states.first { $0.name == name } }
    public func parameter(named name: String) -> AnimationGraphParameter? { parameters.first { $0.name == name } }

    /// `base`, or `base 2`, `base 3`… so it is unused among the state names.
    public func uniqueStateName(_ base: String) -> String {
        Self.unique(base.isEmpty ? "State" : base, taken: Set(states.map(\.name)))
    }

    public func uniqueParameterName(_ base: String) -> String {
        Self.unique(base.isEmpty ? "param" : base, taken: Set(parameters.map(\.name)))
    }

    public func uniqueLayerName(_ base: String) -> String {
        Self.unique(base.isEmpty ? "Layer" : base, taken: Set(layers.map(\.name)))
    }

    static func unique(_ base: String, taken: Set<String>) -> String {
        guard taken.contains(base) else { return base }
        var n = 2
        while taken.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// Renames a state everywhere it is named (transitions, the initial state).
    public mutating func renameState(_ old: String, to new: String) {
        guard let i = states.firstIndex(where: { $0.name == old }) else { return }
        states[i].name = new
        for t in transitions.indices {
            if transitions[t].from == old { transitions[t].from = new }
            if transitions[t].to == old { transitions[t].to = new }
        }
        if initialState == old { initialState = new }
    }

    /// Removes a state and the transitions to or from it.
    public mutating func removeState(_ name: String) {
        states.removeAll { $0.name == name }
        transitions.removeAll { $0.from == name || $0.to == name }
        if initialState == name { initialState = nil }
    }

    /// Renames a parameter everywhere it is used (conditions, blend spaces, speed parameters).
    public mutating func renameParameter(_ old: String, to new: String) {
        guard let i = parameters.firstIndex(where: { $0.name == old }) else { return }
        parameters[i].name = new
        for s in states.indices {
            if states[s].speedParameter == old { states[s].speedParameter = new }
            if states[s].blend?.parameter == old { states[s].blend?.parameter = new }
        }
        for t in transitions.indices {
            for c in transitions[t].conditions.indices where transitions[t].conditions[c].parameter == old {
                transitions[t].conditions[c].parameter = new
            }
        }
    }

    /// Every clip key the states and layers use, in order, without repeats.
    public var clipKeys: [String] {
        var seen = Set<String>(), keys: [String] = []
        for key in states.flatMap(\.clips) + layers.map(\.clip) where !key.isEmpty && seen.insert(key).inserted { keys.append(key) }
        return keys
    }

    /// A new graph: an Idle state (and a Move state with a speed transition each way when
    /// `locomotion`), clips taken in order from `clips`.
    public static func starter(clips: [String] = [], preview: String? = nil) -> AnimationGraph {
        var graph = AnimationGraph(preview: preview)
        graph.states = [AnimationGraphState(name: "Idle", clip: clips.first, position: Vec2(0, 0))]
        if clips.count > 1 {
            graph.parameters = [AnimationGraphParameter(name: "speed")]
            graph.states.append(AnimationGraphState(name: "Move", clip: clips[1], position: Vec2(260, 0)))
            graph.transitions = [
                AnimationGraphTransition(from: "Idle", to: "Move", conditions: [AnimationGraphCondition(parameter: "speed", test: .greater, value: 0.1)]),
                AnimationGraphTransition(from: "Move", to: "Idle", conditions: [AnimationGraphCondition(parameter: "speed", test: .less, value: 0.1)]),
            ]
        }
        graph.initialState = "Idle"
        return graph
    }
}

/// Problems in an `AnimationGraph`, as warnings (the importer and the editor tools report them).
public enum AnimationGraphCheck {
    /// Structural problems; with `clipExists`, also clips that name nothing.
    public static func problems(_ graph: AnimationGraph, clipExists: ((String) -> Bool)? = nil) -> [String] {
        var problems: [String] = []
        if graph.states.isEmpty { problems.append("the graph has no states") }
        var names = Set<String>()
        for state in graph.states {
            if state.name.isEmpty { problems.append("a state has no name") }
            if !names.insert(state.name).inserted { problems.append("two states are named '\(state.name)'") }
        }
        var parameterNames = Set<String>()
        for parameter in graph.parameters where !parameterNames.insert(parameter.name).inserted {
            problems.append("two parameters are named '\(parameter.name)'")
        }
        func checkParameter(_ name: String, _ type: AnimationGraphParameterType, _ what: String) {
            guard let parameter = graph.parameter(named: name) else {
                problems.append("\(what) uses parameter '\(name)', which doesn't exist")
                return
            }
            if parameter.type != type { problems.append("\(what) needs a \(type.rawValue) parameter, but '\(name)' is a \(parameter.type.rawValue)") }
        }
        for state in graph.states {
            let what = "state '\(state.name)'"
            if let blend = state.blend {
                checkParameter(blend.parameter, .float, "\(what)'s blend space")
                if blend.clips.isEmpty { problems.append("\(what)'s blend space has no clips") }
                if blend.clips.contains(where: { $0.clip.isEmpty }) { problems.append("\(what)'s blend space has an entry without a clip") }
            } else if state.clip?.isEmpty ?? true {
                problems.append("\(what) has no clip")
            }
            if let parameter = state.speedParameter { checkParameter(parameter, .float, "\(what)'s speed") }
        }
        if let initial = graph.initialState, graph.state(named: initial) == nil {
            problems.append("the initial state '\(initial)' doesn't exist")
        }
        for (i, transition) in graph.transitions.enumerated() {
            let what = "transition \(i + 1) (\(transition.from ?? "any state") → \(transition.to))"
            if let from = transition.from, graph.state(named: from) == nil { problems.append("\(what) starts from a state that doesn't exist") }
            if graph.state(named: transition.to) == nil { problems.append("\(what) goes to a state that doesn't exist") }
            if transition.conditions.isEmpty && transition.exitTime == nil {
                problems.append("\(what) has no conditions and no exit time, so it never fires")
            }
            for condition in transition.conditions {
                checkParameter(condition.parameter, condition.test.parameterType, "\(what)'s \(condition.test.rawValue) condition")
            }
        }
        for layer in graph.layers where layer.clip.isEmpty { problems.append("layer '\(layer.name)' has no clip") }
        if let clipExists {
            for key in graph.clipKeys where !clipExists(key) { problems.append("clip '\(key)' doesn't exist") }
        }
        return problems
    }
}

/// Imports `.animgraph` files as one `.animationGraph` object (`animgraph/<file name>`), with
/// `AnimationGraphCheck` problems as warnings.
public struct AnimationGraphImporter: AssetImporter {
    public init() {}

    public var name: String { "animgraph" }
    public var fileExtensions: [String] { ["animgraph"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let graph: AnimationGraph
        do { graph = try AssetJSON.decoder().decode(AnimationGraph.self, from: context.data()) } catch {
            throw AssetError.unreadable("not an animgraph file: \(error)")
        }
        for problem in AnimationGraphCheck.problems(graph) { context.warn(problem) }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        let id = namer.id(kind: "animgraph", name: stem, index: 0)
        asset.add(id, name: stem, .animationGraph(graph))
        asset.main = id
        return asset
    }
}
