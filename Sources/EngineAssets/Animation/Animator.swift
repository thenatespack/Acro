import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// A clip placed at a position along a 1D blend space's parameter.
public struct BlendSpaceEntry: Codable, Equatable, Sendable {
    public var clip: AnimationClipHandle
    public var position: Float

    public init(clip: AnimationClipHandle, position: Float) {
        self.clip = clip
        self.position = position
    }
}

/// What an animation state plays.
public enum AnimationMotion: Codable, Equatable, Sendable {
    /// One clip.
    case clip(AnimationClipHandle)
    /// A 1D blend space: clips at positions along the float `parameter` (e.g. idle at 0, walk
    /// at 1, run at 2.5 by speed). The two clips around the parameter's value are mixed
    /// linearly (the value is clamped to the first and last positions), and all clips play in
    /// step: they share one normalized time, which advances at the weighted average of their
    /// rates, so a walk and a run blend without their feet drifting apart.
    case blend1D(parameter: String, entries: [BlendSpaceEntry])
    /// A 2D blend space: clips at points on the plane of float parameters `x` and `y`, mixed
    /// by `blendWeights2D` and played in step like a 1D blend space (BlendSpace2D.swift).
    case blend2D(x: String, y: String, entries: [BlendSpace2DEntry])

    /// Each entry's weight for `value` (entries in any order; equal positions share).
    public static func blendWeights(positions: [Float], value: Float) -> [Float] {
        var weights = [Float](repeating: 0, count: positions.count)
        guard !positions.isEmpty else { return weights }
        let order = positions.indices.sorted { positions[$0] < positions[$1] || positions[$0] == positions[$1] && $0 < $1 }
        let first = order.first!, last = order.last!
        if value <= positions[first] { weights[first] = 1; return weights }
        if value >= positions[last] { weights[last] = 1; return weights }
        for k in 0..<(order.count - 1) {
            let a = order[k], b = order[k + 1]
            guard value >= positions[a], value <= positions[b] else { continue }
            let span = positions[b] - positions[a]
            let u = span > 0 ? (value - positions[a]) / span : 0
            weights[a] = 1 - u
            weights[b] = u
            break
        }
        return weights
    }
}

/// An `Animator` parameter: transitions test them, blend spaces read floats.
public enum AnimationParameter: Codable, Equatable, Sendable {
    case float(Float)
    case bool(Bool)
    /// Set by `Animator.setTrigger`, cleared when a transition that tests it fires.
    case trigger(Bool)
}

/// A test of one parameter. A missing parameter (or one of another kind) fails every test.
public struct AnimationCondition: Codable, Equatable, Sendable {
    public enum Test: Codable, Equatable, Sendable {
        case greater(Float), less(Float), isTrue, isFalse, triggered
    }

    public var parameter: String
    public var test: Test

    public init(_ parameter: String, _ test: Test) {
        self.parameter = parameter
        self.test = test
    }

    public static func greater(_ parameter: String, _ value: Float) -> AnimationCondition { .init(parameter, .greater(value)) }
    public static func less(_ parameter: String, _ value: Float) -> AnimationCondition { .init(parameter, .less(value)) }
    public static func isTrue(_ parameter: String) -> AnimationCondition { .init(parameter, .isTrue) }
    public static func isFalse(_ parameter: String) -> AnimationCondition { .init(parameter, .isFalse) }
    public static func triggered(_ parameter: String) -> AnimationCondition { .init(parameter, .triggered) }

    func holds(_ parameters: [String: AnimationParameter]) -> Bool {
        switch (test, parameters[parameter]) {
        case (.greater(let v), .float(let x)?): return x > v
        case (.less(let v), .float(let x)?): return x < v
        case (.isTrue, .bool(let b)?): return b
        case (.isFalse, .bool(let b)?): return !b
        case (.triggered, .trigger(let set)?): return set
        default: return false
        }
    }
}

/// A state of an `AnimationStateMachine`.
public struct AnimationState: Codable, Equatable, Sendable {
    public var name: String
    public var motion: AnimationMotion
    /// Playback rate (1 is the clips' own speed).
    public var speed: Float
    /// Multiplies `speed` by this float parameter's value, if set.
    public var speedParameter: String?
    /// Repeats; otherwise holds the last frame once played through.
    public var loops: Bool

    public init(_ name: String, _ motion: AnimationMotion, speed: Float = 1, speedParameter: String? = nil, loops: Bool = true) {
        self.name = name
        self.motion = motion
        self.speed = speed
        self.speedParameter = speedParameter
        self.loops = loops
    }
}

/// A move from one state to another, crossfading over `duration` seconds once every condition
/// holds and, with `exitTime`, when the current state's normalized time reaches it (for a
/// looping state, each time its cycle passes that fraction: 0.9 fires near the end of every
/// loop; values above 1 wait for that many loops first). A transition needs conditions or an
/// exit time; with neither it never fires.
public struct AnimationTransition: Codable, Equatable, Sendable {
    /// The source state; nil for any state.
    public var from: String?
    public var to: String
    public var conditions: [AnimationCondition]
    public var exitTime: Float?
    /// Crossfade length in seconds (0 switches at once).
    public var duration: Float
    /// Whether an any-state transition may restart the state it targets.
    public var canTransitionToSelf: Bool

    public init(from: String?, to: String, conditions: [AnimationCondition] = [], exitTime: Float? = nil, duration: Float = 0.25,
                canTransitionToSelf: Bool = false) {
        self.from = from
        self.to = to
        self.conditions = conditions
        self.exitTime = exitTime
        self.duration = duration
        self.canTransitionToSelf = canTransitionToSelf
    }
}

/// States and the transitions between them. Transitions are checked in order once per update
/// (only from the current state, plus the any-state ones); the first that applies fires.
public struct AnimationStateMachine: Codable, Equatable, Sendable {
    public var states: [AnimationState]
    public var transitions: [AnimationTransition]
    /// Where playback starts; the first state when nil or unknown.
    public var initialState: String?

    public init(states: [AnimationState], transitions: [AnimationTransition] = [], initialState: String? = nil) {
        self.states = states
        self.transitions = transitions
        self.initialState = initialState
    }

    public func index(of state: String) -> Int? { states.firstIndex { $0.name == state } }
}

/// An `AnimationEvent` reached during the last update.
public struct FiredAnimationEvent: Codable, Equatable, Sendable {
    public var name: String
    /// The state and clip that played it.
    public var state: String
    public var clip: AnimationClipHandle
}

/// One state being played: the current one, or one fading out.
public struct AnimationPlayback: Codable, Equatable, Sendable {
    /// Index into the state machine's states.
    public var state: Int
    /// Cycles played so far (not wrapped): the fractional part is the position in a loop.
    public var normalizedTime: Float
    public var weight: Float
    /// The weight when the current crossfade began.
    var fadeStart: Float
}

/// A layer on top of the state machine's pose. Additive (the default): `clip`'s difference from
/// its pose at `referenceTime` is added, scaled by `weight` (see `AnimationPose.add`). Override:
/// the clip's pose replaces the bones it animates, mixed in by `weight`. `mask` limits either
/// to some bones' subtrees (AnimatorLayers.swift).
public struct AdditiveAnimationLayer: Codable, Equatable, Sendable {
    public var clip: AnimationClipHandle
    public var weight: Float
    public var speed: Float
    /// Seconds into the clip (wrapped when it loops).
    public var time: Float
    public var referenceTime: Float
    /// How the layer combines with the pose below; nil is `.additive`.
    public var blend: AnimationLayerBlend?
    /// Bone (target `Name`) whose subtrees the layer affects; nil affects every target.
    public var mask: [String]?
    /// `mask` as target indices, worked out from the targets' names and hierarchy
    /// (`Animator.resolveLayerMasks`); nil until then.
    public var maskTargets: [Int]?

    public init(clip: AnimationClipHandle, weight: Float = 1, speed: Float = 1, time: Float = 0, referenceTime: Float = 0,
                blend: AnimationLayerBlend? = nil, mask: [String]? = nil) {
        self.clip = clip
        self.weight = weight
        self.speed = speed
        self.time = time
        self.referenceTime = referenceTime
        self.blend = blend
        self.mask = mask
    }
}

/// Plays skeletal animation on a set of target entities (bones, or any nodes): a state machine
/// of clips and blend spaces with crossfading transitions on parameters, additive layers on top,
/// and events. `world.addAnimationSystem(library)` advances every animator by the frame's dt and
/// writes the animated targets' `Transform`s (targets no clip drives are left alone).
///
/// ```swift
/// let clips = model.registerAnimations(in: library, keyPrefix: "fox")      // Survey, Walk, Run
/// let rig = model.animationTargets(of: instance)
/// world.add(Animator(targets: rig.targets, restPose: rig.restPose, clip: clips[1]), to: instance.roots[0])
/// ```
///
/// Everything advances only through `update(dt:clip:)`, in a fixed order, so the same dt
/// sequence always gives the same poses. All state (current states, times, fades, parameters)
/// is in the component, so it is saved with scenes and restored with snapshots.
public struct Animator: Component, Equatable, Sendable {
    public static let componentName = "Animator"
    public static var fieldHints: [String: FieldHints] {
        ["targets": FieldHints(readOnly: true, tooltip: "The entities the clips drive (bound from this entity's subtree when empty)"),
         "restPose": FieldHints(hidden: true), "playbacks": FieldHints(hidden: true), "events": FieldHints(hidden: true),
         "fadeDuration": FieldHints(hidden: true), "fadeElapsed": FieldHints(hidden: true),
         "graph": FieldHints(tooltip: "An .animgraph asset: its states, transitions, parameters and layers replace this animator's (hot reloaded)"),
         "retarget": FieldHints(hidden: true)]
    }

    /// The entity each channel `target` index drives (for imported clips, by glTF node index;
    /// `Entity.invalid` where a node wasn't instantiated).
    public var targets: [Entity]
    /// Local transforms of the targets when no clip drives them (blend spaces and crossfades
    /// between clips that animate different targets fall back to these).
    public var restPose: [Transform]
    public var stateMachine: AnimationStateMachine
    public var parameters: [String: AnimationParameter]
    public var layers: [AdditiveAnimationLayer]
    /// Multiplies dt.
    public var speed: Float
    public var isPlaying: Bool
    /// An `.animgraph` asset (Animation Graph Builder). When set, the scene animation system
    /// (`World.addSceneAnimationSystem`) replaces `stateMachine` and `layers` with the graph's
    /// and adds its parameters, again whenever the file is reimported.
    public var graph: AssetReference?
    /// Plays clips made for another skeleton by matching bones by name: the scene animation
    /// system retargets each clip whose `skeleton` differs from this animator's targets (their
    /// `Name`s) onto them (`AnimationClip.retargeted(to:options:)`). Nil plays clips as they
    /// are, by target index. A graph's `retarget` replaces it.
    public var retarget: AnimationRetargetOptions?

    /// The current state last, states fading out before it.
    public private(set) var playbacks: [AnimationPlayback] = []
    public private(set) var fadeDuration: Float = 0
    public private(set) var fadeElapsed: Float = 0
    /// Events reached during the last update.
    public private(set) var events: [FiredAnimationEvent] = []

    public init(targets: [Entity], restPose: [Transform], stateMachine: AnimationStateMachine,
                parameters: [String: AnimationParameter] = [:], layers: [AdditiveAnimationLayer] = [], speed: Float = 1,
                isPlaying: Bool = true) {
        self.targets = targets
        self.restPose = restPose
        self.stateMachine = stateMachine
        self.parameters = parameters
        self.layers = layers
        self.speed = speed
        self.isPlaying = isPlaying
    }

    /// Plays one clip (a state machine with a single state named after the clip's key),
    /// starting `normalizedTime` cycles in.
    public init(targets: [Entity], restPose: [Transform], clip: AnimationClipHandle, loops: Bool = true, speed: Float = 1,
                normalizedTime: Float = 0) {
        self.init(targets: targets, restPose: restPose,
                  stateMachine: AnimationStateMachine(states: [AnimationState(clip.key, .clip(clip), loops: loops)]), speed: speed)
        playbacks = [AnimationPlayback(state: 0, normalizedTime: normalizedTime, weight: 1, fadeStart: 1)]
    }

    /// Replaces the state machine and layers (an `.animgraph` reload), adding `parameters`
    /// that are missing or of another kind (values already set are kept; others stay). Playback carries on
    /// in the state of the same name, or restarts in the new initial state when it is gone.
    public mutating func replaceGraph(_ machine: AnimationStateMachine, parameters defaults: [String: AnimationParameter],
                                      layers newLayers: [AdditiveAnimationLayer]) {
        let current = currentState
        let time = normalizedTime
        stateMachine = machine
        for (name, value) in defaults {
            switch (parameters[name], value) {
            case (.float?, .float), (.bool?, .bool), (.trigger?, .trigger): break
            default: parameters[name] = value
            }
        }
        // Keep each layer's running time when the clip is the same.
        layers = newLayers.enumerated().map { i, layer in
            var layer = layer
            if layers.indices.contains(i), layers[i].clip == layer.clip { layer.time = layers[i].time }
            return layer
        }
        if let current, let index = machine.index(of: current) {
            playbacks = [AnimationPlayback(state: index, normalizedTime: time, weight: 1, fadeStart: 1)]
        } else {
            playbacks = []
        }
        fadeDuration = 0
        fadeElapsed = 0
    }

    // MARK: Parameters

    public mutating func setFloat(_ name: String, _ value: Float) { parameters[name] = .float(value) }
    public mutating func setBool(_ name: String, _ value: Bool) { parameters[name] = .bool(value) }
    /// Sets a trigger; the next transition that tests it fires and clears it.
    public mutating func setTrigger(_ name: String) { parameters[name] = .trigger(true) }
    public mutating func resetTrigger(_ name: String) { parameters[name] = .trigger(false) }

    public func float(_ name: String) -> Float? {
        if case .float(let v)? = parameters[name] { return v }
        return nil
    }

    public func bool(_ name: String) -> Bool? {
        if case .bool(let v)? = parameters[name] { return v }
        return nil
    }

    // MARK: Playback

    /// The state being played or faded into.
    public var currentState: String? { playbacks.last.map { stateMachine.states[$0.state].name } }
    /// The current state's normalized time (cycles played).
    public var normalizedTime: Float { playbacks.last?.normalizedTime ?? 0 }
    public var isInTransition: Bool { playbacks.count > 1 }

    /// Crossfades to `state` over `fade` seconds (at once for 0), from `normalizedTime`.
    /// Unknown states are ignored.
    public mutating func play(_ state: String, fade: Float = 0.25, normalizedTime: Float = 0) {
        guard let index = stateMachine.index(of: state) else { return }
        start(index, fade: fade, normalizedTime: normalizedTime)
    }

    private mutating func start(_ state: Int, fade: Float, normalizedTime: Float) {
        if fade <= 0 || playbacks.isEmpty {
            playbacks = [AnimationPlayback(state: state, normalizedTime: normalizedTime, weight: 1, fadeStart: 1)]
            fadeDuration = 0
            fadeElapsed = 0
            return
        }
        for i in playbacks.indices { playbacks[i].fadeStart = playbacks[i].weight }
        playbacks.removeAll { $0.weight <= 0 }
        playbacks.append(AnimationPlayback(state: state, normalizedTime: normalizedTime, weight: 0, fadeStart: 0))
        fadeDuration = fade
        fadeElapsed = 0
    }

    /// The clips a state plays and their weights at the current parameters.
    func clips(of state: AnimationState) -> [(clip: AnimationClipHandle, weight: Float)] {
        switch state.motion {
        case .clip(let clip):
            return [(clip, 1)]
        case .blend1D(let parameter, let entries):
            let weights = AnimationMotion.blendWeights(positions: entries.map(\.position), value: float(parameter) ?? 0)
            return zip(entries, weights).map { ($0.clip, $1) }
        case .blend2D(let x, let y, let entries):
            let weights = AnimationMotion.blendWeights2D(points: entries.map { Vec2($0.x, $0.y) }, value: Vec2(float(x) ?? 0, float(y) ?? 0))
            return zip(entries, weights).map { ($0.clip, $1) }
        }
    }

    /// Advances playback by `dt` seconds (times `speed`): times, crossfades, events, then at most
    /// one transition. Returns the blended pose of all targets (`animated` marks the ones some
    /// clip drives). `clip` looks up clips (an `AnimationLibrary`); missing clips animate nothing.
    public mutating func update(dt: Float, clip lookup: (AnimationClipHandle) -> AnimationClip?) -> AnimationPose {
        events.removeAll()
        if playbacks.isEmpty, !stateMachine.states.isEmpty {
            let initial = stateMachine.initialState.flatMap { stateMachine.index(of: $0) } ?? 0
            playbacks = [AnimationPlayback(state: initial, normalizedTime: 0, weight: 1, fadeStart: 1)]
        }
        let step = isPlaying ? max(dt, 0) * speed : 0
        if step != 0, !playbacks.isEmpty {
            // Times.
            var previousTime: Float = 0
            for i in playbacks.indices {
                let state = stateMachine.states[playbacks[i].state]
                let clips = clips(of: state)
                let duration = clips.reduce(Float(0)) { $0 + (lookup($1.clip)?.duration ?? 0) * $1.weight }
                let rate = state.speed * (state.speedParameter.flatMap { float($0) } ?? 1)
                if i == playbacks.count - 1 { previousTime = playbacks[i].normalizedTime }
                if duration > 0 { playbacks[i].normalizedTime += step * rate / duration }
            }
            fireEvents(from: previousTime, lookup: lookup)
            // Crossfade.
            if playbacks.count > 1 {
                fadeElapsed += step
                let f = fadeDuration > 0 ? min(fadeElapsed / fadeDuration, 1) : 1
                for i in playbacks.indices.dropLast() { playbacks[i].weight = playbacks[i].fadeStart * (1 - f) }
                playbacks[playbacks.count - 1].weight = f
                if f >= 1 {
                    playbacks.removeFirst(playbacks.count - 1)
                    playbacks[0].weight = 1
                }
            }
            checkTransitions(previousTime: previousTime)
            for i in layers.indices { layers[i].time += step * layers[i].speed }
        } else if !playbacks.isEmpty, isPlaying {
            checkTransitions(previousTime: playbacks[playbacks.count - 1].normalizedTime)
        }
        return pose(lookup: lookup)
    }

    private mutating func fireEvents(from previous: Float, lookup: (AnimationClipHandle) -> AnimationClip?) {
        guard let current = playbacks.last else { return }
        let state = stateMachine.states[current.state]
        // The dominant clip of a blend space reports its events (the first on ties).
        guard let main = clips(of: state).enumerated().max(by: { $0.element.weight < $1.element.weight || $0.element.weight == $1.element.weight && $0.offset > $1.offset })?.element,
              main.weight > 0, let clip = lookup(main.clip), clip.duration > 0, !clip.events.isEmpty else { return }
        let now = current.normalizedTime
        for event in clip.events {
            let e = event.time / clip.duration
            if state.loops {
                // Every cycle k with previous <= k + e < now.
                var k = (previous - e).rounded(.up)
                while k + e < now {
                    events.append(FiredAnimationEvent(name: event.name, state: state.name, clip: main.clip))
                    k += 1
                }
            } else if e < 1 ? previous <= e && e < now : previous < 1 && now >= 1 {
                events.append(FiredAnimationEvent(name: event.name, state: state.name, clip: main.clip))
            }
        }
    }

    private mutating func checkTransitions(previousTime: Float) {
        guard let current = playbacks.last else { return }
        let name = stateMachine.states[current.state].name
        let loops = stateMachine.states[current.state].loops
        let now = current.normalizedTime
        for transition in stateMachine.transitions {
            guard transition.from == nil || transition.from == name,
                  let target = stateMachine.index(of: transition.to),
                  target != current.state || (transition.from == nil && transition.canTransitionToSelf) || transition.from == name,
                  !(transition.conditions.isEmpty && transition.exitTime == nil),
                  transition.conditions.allSatisfy({ $0.holds(parameters) }) else { continue }
            if let exit = transition.exitTime {
                let reached = loops
                    ? now >= exit && (previousTime - exit).rounded(.down) < (now - exit).rounded(.down)
                    : now >= exit
                guard reached else { continue }
            }
            for condition in transition.conditions where condition.test == .triggered {
                parameters[condition.parameter] = .trigger(false)
            }
            start(target, fade: transition.duration, normalizedTime: 0)
            return
        }
    }

    /// The blended pose of every playback, plus the additive layers.
    func pose(lookup: (AnimationClipHandle) -> AnimationClip?) -> AnimationPose {
        var poses: [AnimationPose] = [], weights: [Float] = []
        for playback in playbacks where playback.weight > 0 {
            let state = stateMachine.states[playback.state]
            let phase = state.loops ? playback.normalizedTime - playback.normalizedTime.rounded(.down) : min(playback.normalizedTime, 1)
            var clipPoses: [AnimationPose] = [], clipWeights: [Float] = []
            for (handle, weight) in clips(of: state) where weight > 0 {
                guard let clip = lookup(handle) else { continue }
                var pose = AnimationPose(restPose)
                clip.sample(at: phase * clip.duration, into: &pose)
                clipPoses.append(pose)
                clipWeights.append(weight)
            }
            poses.append(clipPoses.count == 1 ? clipPoses[0] : AnimationPose.blend(clipPoses, weights: clipWeights, rest: restPose))
            weights.append(playback.weight)
        }
        var result = poses.count == 1 ? poses[0] : AnimationPose.blend(poses, weights: weights, rest: restPose)
        for layer in layers where layer.weight > 0 {
            guard let clip = lookup(layer.clip), clip.duration > 0 else { continue }
            result.apply(layer, clip: clip, rest: restPose)
        }
        return result
    }
}

extension World {
    /// Adds a system (in `stage`, `.update` by default) that advances every `Animator` by the
    /// frame's dt with clips from `library` and writes the animated targets' `Transform`s, then
    /// reports the events reached through `onEvent`. Transform propagation later in the frame
    /// moves skinned meshes' joints (see `Skin`).
    ///
    /// Animators advance and sample their clips in parallel on `jobs` (each touches only its
    /// own component and pose; the library is only read); poses are then written, events
    /// reported and missing clips warned about in storage order, so the result is the same for
    /// any thread count.
    public func addAnimationSystem(_ library: AnimationLibrary, name: String = "animation", stage: SystemStage = .update,
                                   jobs: JobSystem = .shared, onEvent: ((Entity, FiredAnimationEvent) -> Void)? = nil) {
        var reported = Set<String>()
        var animators: [Animator] = []
        var poses: [AnimationPose] = []
        var missing: [[String]] = []
        addSystem(name, stage: stage) { world in
            let dt = world.time.delta
            animators.removeAll(keepingCapacity: true)
            world.query(Animator.self) { _, animator in animators.append(animator.withLayerMasks(in: world)) }
            let count = animators.count
            poses = Array(repeating: AnimationPose([]), count: count)
            missing = Array(repeating: [], count: count)
            animators.withUnsafeMutableBufferPointer { animators in
                poses.withUnsafeMutableBufferPointer { poses in
                    missing.withUnsafeMutableBufferPointer { missing in
                        jobs.parallelFor(0..<count, batchSize: 8, name: "animators") { range in
                            for i in range {
                                poses[i] = animators[i].update(dt: dt) { handle in
                                    if let clip = library.clip(handle) { return clip }
                                    missing[i].append(handle.key)
                                    return nil
                                }
                            }
                        }
                    }
                }
            }
            var fired: [(Entity, FiredAnimationEvent)] = []
            var index = 0
            world.queryMutating(Animator.self) { entity, animator in
                animator = animators[index]
                let pose = poses[index]
                for key in missing[index] where reported.insert(key).inserted {
                    EngineLog.warning("no animation clip registered as '\(key)'", category: .animation)
                }
                index += 1
                for i in 0..<min(pose.count, animator.targets.count) where pose.animated[i] {
                    world.modify(Transform.self, for: animator.targets[i]) { $0 = pose.transforms[i] }
                }
                for event in animator.events { fired.append((entity, event)) }
            }
            if let onEvent { for (entity, event) in fired { onEvent(entity, event) } }
        }
    }
}
