import Foundation
import EngineAssets
import EngineCore
import EngineScene

// Animators in scene files: clips from the asset database and rigs bound from the hierarchy.
//
// A glTF file's clips are imported as `animation/<name>` sub-assets whose channel targets are the
// file's prefab node numbers (depth first, roots first). An `Animator` on an instance of that
// prefab plays them when its `targets` are the instance's entities in the same order
// (`World.animationRig(of:)`) and its clip handles are the clips' asset references:
//
// ```swift
// let root = world.instantiate(database.prefab(AssetReference(fox))!).first!
// let rig = world.animationRig(of: root)
// world.add(Animator(targets: rig.targets, restPose: rig.restPose,
//                    clip: AnimationClipHandle("asset:\(fox)#animation/Walk")), to: root)
// world.addSceneAnimationSystem(assets: { database })
// ```
//
// An `.animgraph` asset (Animation Graph Builder) supplies a whole state machine instead:
// `Animator.graph` names it, and the system applies it (`Animator.replaceGraph`) when it first
// sees the animator and after every reimport of the file.
//
// The editor's play mode, `ScenePlayback` (exported games, GameRunner) add the system, so a
// scene's animators play without game code.

extension World {
    /// The entities of `root`'s subtree, depth first with `root` first (the node order of the
    /// prefab `root` is an instance of, which imported clips target), and their current local
    /// transforms as the rest pose.
    public func animationRig(of root: Entity) -> (targets: [Entity], restPose: [Transform]) {
        var targets: [Entity] = [], rest: [Transform] = []
        func visit(_ entity: Entity) {
            targets.append(entity)
            rest.append(get(Transform.self, for: entity) ?? Transform())
            for child in children(of: entity) { visit(child) }
        }
        if isAlive(root) { visit(root) }
        return (targets, rest)
    }

    /// Adds the system that plays a scene's asset-driven animators: every `Animator` with a
    /// `graph` or a clip handle naming an asset (`"asset:<id>#animation/<name>"`). Each frame,
    /// on the main thread, it applies graphs that are new or were reimported (`replaceGraph`),
    /// binds animators with no `targets` to their entity's subtree
    /// (`animationRig(of:)`), loads their clips from `assets` into the returned library (again
    /// after a reimport: hot reload) and retargets them when asked. Then the animators advance
    /// by the frame's dt and sample their clips in parallel on `jobs` (each touches only its own
    /// copy and clips); poses are written to the targets' `Transform`s and events reported
    /// through `onEvent` in query order, so the result is the same for any thread count.
    ///
    /// Animators whose clips are all registered in code by other keys are left to the system of
    /// `addAnimationSystem(_:)`, so a game that runs its own isn't advanced twice.
    @discardableResult
    public func addSceneAnimationSystem(assets: @escaping () -> AssetDatabase?, name: String = "sceneAnimation",
                                        stage: SystemStage = .update, jobs: JobSystem = .shared,
                                        onEvent: ((Entity, FiredAnimationEvent) -> Void)? = nil) -> AnimationLibrary {
        let library = AnimationLibrary()
        let clipCache = AnimatorClipCache()
        var reported = Set<String>()
        var appliedGraphs: [Entity: (graph: AssetReference, revision: Int)] = [:]
        var entities: [Entity] = []
        var animators: [Animator] = []
        var clips: [[AnimationClipHandle: AnimationClip]] = []
        var poses: [AnimationPose] = []
        let ik = AnimationIKState()
        addSystem(name, stage: stage) { world in
            guard world.count(of: Animator.self) > 0 else { return }
            library.assets = assets()
            entities.removeAll(keepingCapacity: true)
            animators.removeAll(keepingCapacity: true)
            clips.removeAll(keepingCapacity: true)
            world.query(Animator.self) { entity, animator in
                if animator.isSceneDriven {
                    entities.append(entity)
                    animators.append(animator)
                }
            }
            guard !entities.isEmpty else { return }
            let dt = world.time.delta
            let database = library.assets
            // Main thread: graphs, binding, clip loading and retargeting.
            for i in entities.indices {
                let entity = entities[i]
                var animator = animators[i]
                if let reference = animator.graph, let database {
                    let revision = database.revision(of: reference.asset)
                    let applied = appliedGraphs[entity]
                    if applied?.graph != reference || applied?.revision != revision {
                        if let graph = database.animationGraph(reference) {
                            animator.apply(graph)
                        } else if reported.insert(reference.description).inserted {
                            EngineLog.warning("no animation graph '\(reference)'", category: .animation)
                        }
                        appliedGraphs[entity] = (reference, database.revision(of: reference.asset))
                    }
                }
                if animator.targets.isEmpty {
                    let rig = world.animationRig(of: entity)
                    animator.targets = rig.targets
                    animator.restPose = rig.restPose
                }
                animator = animator.withLayerMasks(in: world)
                for key in library.resolveAssetClips(animator.clipHandles) where reported.insert(key).inserted {
                    EngineLog.warning("no animation clip '\(key)'", category: .animation)
                }
                clips.append(clipCache.clips(for: entity, animator, in: world, library: library))
                animators[i] = animator
            }
            // Any thread: advance and sample.
            let count = animators.count
            poses = Array(repeating: AnimationPose([]), count: count)
            clips.withUnsafeBufferPointer { clips in
                animators.withUnsafeMutableBufferPointer { animators in
                    poses.withUnsafeMutableBufferPointer { poses in
                        jobs.parallelFor(0..<count, batchSize: 4, name: "sceneAnimators") { range in
                            for i in range {
                                let set = clips[i]
                                poses[i] = animators[i].update(dt: dt) { set[$0] }
                            }
                        }
                    }
                }
            }
            // Main thread, in order: poses, components, events.
            var fired: [(Entity, FiredAnimationEvent)] = []
            for i in 0..<count {
                let entity = entities[i], animator = animators[i]
                var pose = poses[i]
                // IK after the pose, before it reaches the bones (and skinning).
                if animator.ik != nil { world.applyIK(animator, on: entity, pose: &pose, state: ik) }
                for t in 0..<min(pose.count, animator.targets.count) where pose.animated[t] {
                    world.modify(Transform.self, for: animator.targets[t]) { $0 = pose.transforms[t] }
                }
                for event in animator.events { fired.append((entity, event)) }
                world.modify(Animator.self, for: entity) { $0 = animator }
            }
            clipCache.keepOnly(Set(entities))
            ik.keepOnly(Set(entities))
            if let onEvent { for (entity, event) in fired { onEvent(entity, event) } }
        }
        return library
    }
}

extension Animator {
    /// Every clip the state machine and layers refer to.
    public var clipHandles: [AnimationClipHandle] {
        var handles: [AnimationClipHandle] = []
        for state in stateMachine.states {
            handles += state.motion.clips
        }
        return handles + layers.map(\.clip)
    }

    /// Whether the scene animation system plays it: it has a graph or some clip names an asset.
    public var isSceneDriven: Bool {
        graph != nil || clipHandles.contains { $0.key.hasPrefix(AssetReference.scheme) }
    }

    /// Takes `graph`'s state machine, parameters and layers (`replaceGraph`), its retarget
    /// options, IK nodes and hitboxes.
    public mutating func apply(_ graph: AnimationGraph) {
        replaceGraph(graph.stateMachine, parameters: graph.parameterDefaults, layers: graph.additiveLayers)
        retarget = graph.retarget
        replaceIK(graph.ik)
        if !graph.hitboxes.isEmpty { hitboxes = graph.hitboxes }
    }

    /// An animator playing `graph` on `root`'s subtree (`World.animationRig(of:)`), with
    /// `graph` set to `reference` so it follows the file.
    @MainActor public init(graph: AnimationGraph, reference: AssetReference?, rigOf root: Entity, in world: World) {
        let rig = world.animationRig(of: root)
        self.init(targets: rig.targets, restPose: rig.restPose, stateMachine: graph.stateMachine,
                  parameters: graph.parameterDefaults, layers: graph.additiveLayers)
        self.graph = reference
        retarget = graph.retarget
        if !graph.ik.isEmpty { ik = graph.ik }
        if !graph.hitboxes.isEmpty { hitboxes = graph.hitboxes }
    }
}

extension AnimationGraph {
    /// The `Animator` state machine: states with their clips or blend spaces, transitions
    /// (`from` nil: any state), the initial state.
    /// Sub-state machines are flattened first (`flattened()`: states named by path, "Combat/Slash").
    public var stateMachine: AnimationStateMachine {
        if hasMachines { return flattened().stateMachine }
        let states = states.map { state -> AnimationState in
            let motion: AnimationMotion
            if let blend = state.blend, let y = blend.parameterY {
                motion = .blend2D(x: blend.parameter, y: y, entries: blend.clips.map {
                    BlendSpace2DEntry(clip: AnimationClipHandle($0.clip), x: $0.position, y: $0.y ?? 0)
                })
            } else if let blend = state.blend {
                motion = .blend1D(parameter: blend.parameter,
                                  entries: blend.clips.map { BlendSpaceEntry(clip: AnimationClipHandle($0.clip), position: $0.position) })
            } else {
                motion = .clip(AnimationClipHandle(state.clip ?? ""))
            }
            return AnimationState(state.name, motion, speed: state.speed, speedParameter: state.speedParameter, loops: state.loops)
        }
        let transitions = transitions.map { t in
            AnimationTransition(from: t.from, to: t.to, conditions: t.conditions.map(\.animationCondition), exitTime: t.exitTime,
                                duration: max(t.duration, 0), canTransitionToSelf: t.canTransitionToSelf)
        }
        return AnimationStateMachine(states: states, transitions: transitions, initialState: initialState)
    }

    /// The parameters at their default values.
    public var parameterDefaults: [String: AnimationParameter] {
        var values: [String: AnimationParameter] = [:]
        for parameter in parameters {
            switch parameter.type {
            case .float: values[parameter.name] = .float(parameter.defaultValue)
            case .bool: values[parameter.name] = .bool(parameter.defaultValue != 0)
            case .trigger: values[parameter.name] = .trigger(false)
            }
        }
        return values
    }

    public var additiveLayers: [AdditiveAnimationLayer] {
        layers.map {
            AdditiveAnimationLayer(clip: AnimationClipHandle($0.clip), weight: $0.weight, speed: $0.speed, referenceTime: $0.referenceTime,
                                   blend: $0.blend == .override ? .override : nil, mask: $0.mask)
        }
    }
}

extension AnimationGraphCondition {
    public var animationCondition: AnimationCondition {
        switch test {
        case .greater: .greater(parameter, value)
        case .less: .less(parameter, value)
        case .isTrue: .isTrue(parameter)
        case .isFalse: .isFalse(parameter)
        case .triggered: .triggered(parameter)
        }
    }
}
