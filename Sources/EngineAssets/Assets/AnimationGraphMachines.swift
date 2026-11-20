import Foundation
import EngineCore

// Sub-state machines in `.animgraph` files.
//
// A state with a `machine` holds its own states, transitions, initial state and Any State node:
//
// ```json
// {"name": "Combat", "machine": {
//    "initialState": "Ready",
//    "states": [{"name": "Ready", "clip": "…"}, {"name": "Slash", "clip": "…", "loops": false}],
//    "transitions": [{"from": "Ready", "to": "Slash", "conditions": [{"parameter": "attack", "test": "triggered"}]},
//                    {"from": "Slash", "to": "Ready", "exitTime": 1},
//                    {"from": "Slash", "to": "Idle", "conditions": [{"parameter": "armed", "test": "isFalse"}]}]}}
// ```
//
// - A transition into the state enters its initial state (and that one's, when it is a machine too).
// - The state's own transitions (in the level that holds it) leave from whichever of its states plays.
// - Inside, `to` names a state of the same machine, or else of an enclosing level (the nearest
//   one with that name), which is how a sub-machine exits. Its Any State node means any state
//   inside the machine.
// - Parameters and layers are the graph's, shared by every level.
//
// The `Animator` plays a flat state machine (`flattened()`): leaf states named by their path
// ("Combat/Slash"), each level's transitions expanded onto the leaves, the levels' transitions
// in order with a level's before those of the machines inside it.

/// A nested state machine (`AnimationGraphState.machine`).
public struct AnimationGraphMachine: Codable, Equatable, Sendable {
    public var states: [AnimationGraphState]
    public var transitions: [AnimationGraphTransition]
    /// Where the machine starts when entered (its first state when nil or unknown).
    public var initialState: String?
    /// Where its Any State node sits in the graph editor.
    public var anyStatePosition: Vec2

    public init(states: [AnimationGraphState] = [], transitions: [AnimationGraphTransition] = [], initialState: String? = nil,
                anyStatePosition: Vec2 = Vec2(0, -120)) {
        self.states = states
        self.transitions = transitions
        self.initialState = initialState
        self.anyStatePosition = anyStatePosition
    }

    private enum CodingKeys: String, CodingKey { case states, transitions, initialState, anyStatePosition }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        states = try c.decodeIfPresent([AnimationGraphState].self, forKey: .states) ?? []
        transitions = try c.decodeIfPresent([AnimationGraphTransition].self, forKey: .transitions) ?? []
        initialState = try c.decodeIfPresent(String.self, forKey: .initialState)
        anyStatePosition = try c.decodeIfPresent(Vec2.self, forKey: .anyStatePosition) ?? Vec2(0, -120)
    }
}

extension AnimationGraph {
    /// Separates the levels in flattened state names ("Combat/Slash").
    public static let levelSeparator = "/"

    /// The graph as seen from the sub-state machine at `path` (state names from the root, e.g.
    /// ["Combat"]): its states, transitions, initial state and Any State position, with the
    /// graph's parameters, layers and other settings. Nil when `path` names no sub-machine.
    /// Edit it like a graph and write it back with `replacingLevel(at:with:)`.
    public func level(at path: [String]) -> AnimationGraph? {
        guard !path.isEmpty else { return self }
        var states = states
        var machine: AnimationGraphMachine?
        for name in path {
            guard let next = states.first(where: { $0.name == name })?.machine else { return nil }
            machine = next
            states = next.states
        }
        guard let machine else { return nil }
        var level = self
        level.states = machine.states
        level.transitions = machine.transitions
        level.initialState = machine.initialState
        level.anyStatePosition = machine.anyStatePosition
        return level
    }

    /// This graph with the sub-state machine at `path` replaced by `level`'s states,
    /// transitions, initial state and Any State position, and the graph-wide settings
    /// (parameters, layers, preview, retarget, ik) taken from `level`. Nil when `path` names no
    /// sub-machine.
    public func replacingLevel(at path: [String], with level: AnimationGraph) -> AnimationGraph? {
        guard !path.isEmpty else { return level }
        var graph = self
        graph.parameters = level.parameters
        graph.layers = level.layers
        graph.preview = level.preview
        graph.retarget = level.retarget
        graph.ik = level.ik
        let machine = AnimationGraphMachine(states: level.states, transitions: level.transitions, initialState: level.initialState,
                                            anyStatePosition: level.anyStatePosition)
        func replace(_ states: inout [AnimationGraphState], _ path: ArraySlice<String>) -> Bool {
            guard let name = path.first, let i = states.firstIndex(where: { $0.name == name }), var inner = states[i].machine else { return false }
            if path.count == 1 {
                states[i].machine = machine
                return true
            }
            guard replace(&inner.states, path.dropFirst()) else { return false }
            states[i].machine = inner
            return true
        }
        return replace(&graph.states, path[...]) ? graph : nil
    }

    /// Every sub-state machine's path, depth first.
    public var machinePaths: [[String]] {
        var paths: [[String]] = []
        func visit(_ states: [AnimationGraphState], _ path: [String]) {
            for state in states {
                guard let machine = state.machine else { continue }
                paths.append(path + [state.name])
                visit(machine.states, path + [state.name])
            }
        }
        visit(states, [])
        return paths
    }

    /// Whether some state is a sub-state machine.
    public var hasMachines: Bool { states.contains { $0.machine != nil } }

    /// The graph with its sub-state machines flattened into one level (see the notes at the top
    /// of this file): leaf states named by path, transitions expanded onto the leaves. A graph
    /// without sub-machines comes back unchanged. Transitions that name no state are dropped
    /// (`AnimationGraphCheck` reports them).
    public func flattened() -> AnimationGraph {
        guard hasMachines else { return self }
        typealias Scope = (prefix: String, states: [AnimationGraphState])
        let sep = Self.levelSeparator
        var outStates: [AnimationGraphState] = []
        var outTransitions: [AnimationGraphTransition] = []

        /// The leaf a transition into `state` (full name `full`) lands on.
        func entry(_ full: String, _ state: AnimationGraphState, depth: Int = 0) -> String? {
            guard let machine = state.machine else { return full }
            guard depth < 64 else { return nil }
            let name = machine.initialState.flatMap { n in machine.states.contains { $0.name == n } ? n : nil } ?? machine.states.first?.name
            guard let name, let inner = machine.states.first(where: { $0.name == name }) else { return nil }
            return entry(full + sep + name, inner, depth: depth + 1)
        }
        /// Every leaf under `state`.
        func leaves(_ full: String, _ state: AnimationGraphState) -> [String] {
            guard let machine = state.machine else { return [full] }
            return machine.states.flatMap { leaves(full + sep + $0.name, $0) }
        }

        func flatten(_ states: [AnimationGraphState], _ transitions: [AnimationGraphTransition], scopes: [Scope]) {
            let here = scopes[0]
            var nested: [(String, AnimationGraphMachine)] = []
            for state in states {
                let full = here.prefix + state.name
                if let machine = state.machine {
                    nested.append((full, machine))
                    continue
                }
                var leaf = state
                leaf.name = full
                outStates.append(leaf)
            }
            for transition in transitions {
                // `to`: this level first, then the enclosing ones.
                var target: String?
                for scope in scopes {
                    if let state = scope.states.first(where: { $0.name == transition.to }) {
                        target = entry(scope.prefix + state.name, state)
                        break
                    }
                }
                guard let target else { continue }
                let sources: [String?]
                if let from = transition.from {
                    guard let state = here.states.first(where: { $0.name == from }) else { continue }
                    sources = leaves(here.prefix + from, state)
                } else if here.prefix.isEmpty {
                    sources = [nil]
                } else {
                    sources = here.states.flatMap { leaves(here.prefix + $0.name, $0) }
                }
                // A leaf's transition to itself: as written for a plain state, else only when allowed.
                let explicitSelf = transition.from.flatMap { from in here.states.first { $0.name == from } }?.machine == nil
                    && transition.from == transition.to
                for source in sources {
                    if let source, source == target, !explicitSelf, !transition.canTransitionToSelf { continue }
                    var flat = transition
                    flat.from = source
                    flat.to = target
                    outTransitions.append(flat)
                }
            }
            for (full, machine) in nested {
                flatten(machine.states, machine.transitions, scopes: [(full + sep, machine.states)] + scopes)
            }
        }

        flatten(states, transitions, scopes: [("", states)])
        var flat = self
        flat.states = outStates
        flat.transitions = outTransitions
        let initial = initialState.flatMap { n in states.first { $0.name == n } } ?? states.first
        flat.initialState = initial.flatMap { entry($0.name, $0) }
        return flat
    }

    /// The state at `path` in this level or a sub-machine's ("Combat/Slash" → ["Combat", "Slash"]).
    public func state(atPath path: [String]) -> AnimationGraphState? {
        guard let last = path.last else { return nil }
        return level(at: Array(path.dropLast()))?.state(named: last)
    }
}
