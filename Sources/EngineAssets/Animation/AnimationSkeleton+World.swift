import Foundation
import EngineCore
import EngineScene

// Lives beside `Animator` (EngineAssets), which resolves layer masks with it.

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
