import Foundation
import EngineAssets
import EngineCore
import EngineScene

// The clips one animator plays, as the scene animation system and the Animation Graph Builder's
// preview hand them to `Animator.update`: the library's clips, retargeted onto the animator's
// skeleton when `Animator.retarget` is set (bones matched by name, see AnimationRetarget.swift).

extension World {
    /// The skeleton of an animator's `targets`: each target's `Name`, its nearest ancestor among
    /// the targets as its parent, and `restPose` (the targets' current transforms when it is
    /// shorter) as the rest pose. Dead targets get empty names.
    public func animationSkeleton(targets: [Entity], restPose: [Transform] = []) -> AnimationSkeleton {
        var indexOf: [Entity: Int] = [:]
        for (i, entity) in targets.enumerated() where indexOf[entity] == nil { indexOf[entity] = i }
        var bones: [AnimationSkeleton.Bone] = []
        bones.reserveCapacity(targets.count)
        for (i, entity) in targets.enumerated() {
            guard isAlive(entity) else {
                bones.append(AnimationSkeleton.Bone(name: "", rest: restPose.indices.contains(i) ? restPose[i] : Transform()))
                continue
            }
            var parent: Int?
            var up = self.parent(of: entity), steps = 0
            while let ancestor = up, steps < 4096 {
                if let index = indexOf[ancestor] { parent = index; break }
                up = self.parent(of: ancestor)
                steps += 1
            }
            let rest = restPose.indices.contains(i) ? restPose[i] : (get(Transform.self, for: entity) ?? Transform())
            bones.append(AnimationSkeleton.Bone(name: get(Name.self, for: entity)?.value ?? "", parent: parent, rest: rest))
        }
        return AnimationSkeleton(bones: bones)
    }
}

/// Per animator, the clips it plays: from an `AnimationLibrary`, retargeted onto the animator's
/// skeleton when its `retarget` is set. Rebuilt only when the library's clips, the animator's
/// targets, retarget options or clip handles change. Main thread only; the returned dictionaries
/// are plain values, safe to read from jobs.
@MainActor
public final class AnimatorClipCache {
    private struct Entry {
        var generation: Int
        var targets: [Entity]
        var retarget: AnimationRetargetOptions?
        var handles: [AnimationClipHandle]
        var skeleton: AnimationSkeleton?
        var clips: [AnimationClipHandle: AnimationClip]
    }

    private var entries: [Entity: Entry] = [:]

    public init() {}

    /// The clips `animator` (on `entity`) plays, by handle: missing clips are absent.
    public func clips(for entity: Entity, _ animator: Animator, in world: World, library: AnimationLibrary) -> [AnimationClipHandle: AnimationClip] {
        let handles = animator.clipHandles
        if let entry = entries[entity], entry.generation == library.generation, entry.targets == animator.targets,
           entry.retarget == animator.retarget, entry.handles == handles {
            return entry.clips
        }
        var skeleton: AnimationSkeleton?
        if let entry = entries[entity], entry.targets == animator.targets { skeleton = entry.skeleton }
        var clips: [AnimationClipHandle: AnimationClip] = [:]
        for handle in handles where clips[handle] == nil {
            guard var clip = library.clip(handle) else { continue }
            if let options = animator.retarget, let source = clip.skeleton {
                if skeleton == nil { skeleton = world.animationSkeleton(targets: animator.targets, restPose: animator.restPose) }
                if let skeleton, Self.needsRetarget(source: source, target: skeleton, options: options) {
                    clip = clip.retargeted(from: source, to: skeleton, options: options)
                }
            }
            clips[handle] = clip
        }
        entries[entity] = Entry(generation: library.generation, targets: animator.targets, retarget: animator.retarget, handles: handles,
                                skeleton: skeleton, clips: clips)
        return clips
    }

    /// The skeleton of `entity`'s animator, as last built (nil until a clip needed it).
    public func skeleton(for entity: Entity) -> AnimationSkeleton? { entries[entity]?.skeleton }

    /// Whether a clip for `source` must be rewritten to play on `target`: the layouts differ by
    /// name, or a bone map renames bones.
    public nonisolated static func needsRetarget(source: AnimationSkeleton, target: AnimationSkeleton, options: AnimationRetargetOptions) -> Bool {
        !options.boneMap.isEmpty || source.names != target.names
    }

    public func remove(_ entity: Entity) { entries[entity] = nil }

    /// Forgets animators not in `alive`.
    public func keepOnly(_ alive: Set<Entity>) {
        if entries.keys.contains(where: { !alive.contains($0) }) { entries = entries.filter { alive.contains($0.key) } }
    }

    public func removeAll() { entries.removeAll() }
}
