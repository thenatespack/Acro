import Foundation
import EngineAssets
import EngineCore
import EngineScene

// Animator layers: additive or override, optionally masked to bone subtrees.
//
// A layer's `mask` names bones (targets' `Name`s); the layer then only touches those bones and
// everything below them, e.g. an upper-body wave (`mask: ["spine"]`) over a walk. Names are
// matched exactly, then without case, separators or a `prefix:`. The animation systems turn
// names into target indices (`maskTargets`) once the targets are bound.

/// How an animator layer combines with the pose below it.
public enum AnimationLayerBlend: String, Codable, Sendable, CaseIterable {
    /// Adds the clip's difference from its reference pose (breathing, leaning, recoil).
    case additive
    /// Replaces the bones the clip animates, mixed in by the layer's weight (a wave or an aim
    /// pose over locomotion, usually with a mask).
    case override
}

extension AnimationPose {
    /// Applies `layer` playing `clip` (at the layer's time) on top of this pose: additive or
    /// override, on the layer's `maskTargets` only when set. `rest` is the targets' rest pose.
    public mutating func apply(_ layer: AdditiveAnimationLayer, clip: AnimationClip, rest: [Transform]) {
        var pose = AnimationPose(rest)
        let t = layer.time.truncatingRemainder(dividingBy: clip.duration)
        clip.sample(at: t < 0 ? t + clip.duration : t, into: &pose)
        if let mask = layer.maskTargets {
            var keep = [Bool](repeating: false, count: pose.count)
            for i in mask where keep.indices.contains(i) { keep[i] = true }
            for i in pose.animated.indices where !keep[i] { pose.animated[i] = false }
        } else if layer.mask != nil {
            return  // a mask that isn't resolved yet (no targets bound): touch nothing
        }
        switch layer.blend ?? .additive {
        case .additive:
            var reference = AnimationPose(rest)
            clip.sample(at: layer.referenceTime, into: &reference)
            add(pose, reference: reference, weight: layer.weight)
        case .override:
            let w = min(max(layer.weight, 0), 1)
            for i in 0..<min(count, pose.count) where pose.animated[i] {
                let from = animated[i] ? transforms[i] : rest[i], to = pose.transforms[i]
                transforms[i] = Transform(position: Vec3.lerp(from.position, to.position, w), rotation: Quat.slerp(from.rotation, to.rotation, w),
                                          scale: Vec3.lerp(from.scale, to.scale, w))
                animated[i] = true
            }
        }
    }
}

extension Animator {
    /// Whether some layer has a mask still to resolve (and there are targets to resolve it on).
    public var needsLayerMasks: Bool {
        !targets.isEmpty && layers.contains { $0.mask != nil && $0.maskTargets == nil }
    }

    /// Works out each masked layer's `maskTargets` on `skeleton` (the targets' bones: names and
    /// parents, see `World.animationSkeleton(targets:restPose:)`): every bone named in the mask
    /// and the bones below it. Unknown names are left out.
    public mutating func resolveLayerMasks(_ skeleton: AnimationSkeleton) {
        for l in layers.indices {
            guard let mask = layers[l].mask else {
                layers[l].maskTargets = nil
                continue
            }
            layers[l].maskTargets = Self.maskTargets(mask, in: skeleton)
        }
    }

    /// The target indices of the subtrees of the bones named `names` in `skeleton`, sorted.
    public static func maskTargets(_ names: [String], in skeleton: AnimationSkeleton) -> [Int] {
        var result = Set<Int>()
        for name in names {
            let normalized = AnimationRetargetOptions.normalizedBoneName(name)
            guard let bone = skeleton.index(of: name)
                    ?? skeleton.bones.firstIndex(where: { AnimationRetargetOptions.normalizedBoneName($0.name) == normalized }) else { continue }
            result.formUnion(skeleton.subtree(of: bone))
        }
        return result.sorted()
    }

    /// This animator with its layer masks resolved on its targets in `world` when they need it.
    @MainActor public func withLayerMasks(in world: World) -> Animator {
        guard needsLayerMasks else { return self }
        var animator = self
        animator.resolveLayerMasks(world.animationSkeleton(targets: targets, restPose: restPose))
        return animator
    }
}
