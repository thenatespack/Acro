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
    /// clip handle naming an asset (`"asset:<id>#animation/<name>"`). Each frame, on the main
    /// thread, it binds animators with no `targets` to their entity's subtree
    /// (`animationRig(of:)`), loads their clips from `assets` into the returned library (again
    /// after a reimport: hot reload), advances them by the frame's dt and writes the animated
    /// targets' `Transform`s, then reports events through `onEvent`.
    ///
    /// Animators whose clips are all registered in code by other keys are left to the system of
    /// `addAnimationSystem(_:)`, so a game that runs its own isn't advanced twice.
    @discardableResult
    public func addSceneAnimationSystem(assets: @escaping () -> AssetDatabase?, name: String = "sceneAnimation",
                                        stage: SystemStage = .update,
                                        onEvent: ((Entity, FiredAnimationEvent) -> Void)? = nil) -> AnimationLibrary {
        let library = AnimationLibrary()
        var reported = Set<String>()
        addSystem(name, stage: stage) { world in
            guard world.count(of: Animator.self) > 0 else { return }
            library.assets = assets()
            var driven: [(Entity, Animator)] = []
            world.query(Animator.self) { entity, animator in
                if animator.isSceneDriven { driven.append((entity, animator)) }
            }
            guard !driven.isEmpty else { return }
            let dt = world.time.delta
            var fired: [(Entity, FiredAnimationEvent)] = []
            for (entity, var animator) in driven {
                if animator.targets.isEmpty {
                    let rig = world.animationRig(of: entity)
                    animator.targets = rig.targets
                    animator.restPose = rig.restPose
                }
                for key in library.resolveAssetClips(animator.clipHandles) where reported.insert(key).inserted {
                    EngineLog.warning("no animation clip '\(key)'", category: .animation)
                }
                let pose = animator.update(dt: dt) { library.clip($0) }
                for i in 0..<min(pose.count, animator.targets.count) where pose.animated[i] {
                    world.modify(Transform.self, for: animator.targets[i]) { $0 = pose.transforms[i] }
                }
                for event in animator.events { fired.append((entity, event)) }
                world.modify(Animator.self, for: entity) { $0 = animator }
            }
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
            switch state.motion {
            case .clip(let clip): handles.append(clip)
            case .blend1D(_, let entries): handles += entries.map(\.clip)
            }
        }
        return handles + layers.map(\.clip)
    }

    /// Whether the scene animation system plays it: some clip names an asset.
    public var isSceneDriven: Bool {
        clipHandles.contains { $0.key.hasPrefix(AssetReference.scheme) }
    }
}
