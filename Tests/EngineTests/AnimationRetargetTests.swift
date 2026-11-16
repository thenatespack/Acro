import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineRendering

private func near(_ a: Vec3, _ b: Vec3, _ tolerance: Float = 1e-3) -> Bool { length(a - b) < tolerance }
private func near(_ a: Quat, _ b: Quat, _ tolerance: Float = 1e-3) -> Bool { abs(abs((a.vector * b.vector).sum()) - 1) < tolerance }

/// Hips (1 m up) → Spine → Arm, the arm resting rotated 90° about Z (a glTF-style rig).
private func sourceSkeleton(armRest: Quat = Quat(angle: .pi / 2, axis: Vec3(0, 0, 1))) -> AnimationSkeleton {
    AnimationSkeleton(bones: [
        .init(name: "mixamorig:Hips", rest: Transform(position: Vec3(0, 1, 0))),
        .init(name: "mixamorig:Spine", parent: 0, rest: Transform(position: Vec3(0, 0.2, 0))),
        .init(name: "mixamorig:LeftArm", parent: 1, rest: Transform(position: Vec3(0.2, 0.2, 0), rotation: armRest)),
    ])
}

/// The same bones in another order, with other names and rest rotations, 2 m tall at the hips.
private func targetSkeleton() -> AnimationSkeleton {
    AnimationSkeleton(bones: [
        .init(name: "Root"),
        .init(name: "upperArm.L", parent: 3, rest: Transform(position: Vec3(0.4, 0.4, 0))),
        .init(name: "hips", parent: 0, rest: Transform(position: Vec3(0, 2, 0))),
        .init(name: "spine", parent: 2, rest: Transform(position: Vec3(0, 0.4, 0))),
    ])
}

/// Over one second the hips move 1 m along x and the arm turns a further 90° about X.
private func sourceClip(armRest: Quat = Quat(angle: .pi / 2, axis: Vec3(0, 0, 1))) -> AnimationClip {
    let turned = (armRest * Quat(angle: .pi / 2, axis: Vec3(1, 0, 0))).normalized
    return AnimationClip(name: "wave", channels: [
        AnimationChannel(target: 0, path: .translation, sampler: AnimationSampler(times: [0, 1], values: [0, 1, 0, 1, 1, 0])),
        AnimationChannel(target: 2, path: .rotation, sampler: AnimationSampler(times: [0, 1], values: [
            armRest.x, armRest.y, armRest.z, armRest.w, turned.x, turned.y, turned.z, turned.w])),
    ], events: [AnimationEvent(time: 0.5, name: "wave")], skeleton: sourceSkeleton(armRest: armRest))
}

private func pose(_ clip: AnimationClip, on skeleton: AnimationSkeleton, at time: Float) -> [Transform] {
    var pose = AnimationPose(skeleton.bones.map(\.rest))
    clip.sample(at: time, into: &pose)
    return skeleton.modelTransforms(pose.transforms)
}

@Suite struct AnimationRetargetTests {
    @Test func bonesPairByMapThenExactThenNormalizedName() {
        let map = AnimationRetargetMap(source: sourceSkeleton(), target: targetSkeleton(),
                                       options: AnimationRetargetOptions(boneMap: ["LeftArm": "upperArm.L"]))
        #expect(map.sourceOfTarget == [nil, 2, 0, 1])
        #expect(map.unmatchedTargets == ["Root"] && map.unmatchedSources.isEmpty && map.matchedCount == 3)
        let noNames = AnimationRetargetMap(source: sourceSkeleton(), target: targetSkeleton(),
                                           options: AnimationRetargetOptions(boneMap: ["mixamorig:Hips": "spine"], matchNames: false))
        #expect(noNames.sourceOfTarget == [nil, nil, nil, 0])
        #expect(AnimationRetargetOptions.normalizedBoneName("mixamorig:Left_Arm") == "leftarm")
        let humanoid = AnimationRetargetMap(source: sourceSkeleton(), target: CharacterRig(template: .humanoid).animationSkeleton,
                                            options: AnimationRetargetOptions(boneMap: AnimationRetargetOptions.mixamoHumanoid))
        #expect(humanoid.matchedCount == 3, "mixamo names reach the humanoid's hips, spine and upperArm.L")
    }

    @Test func worldModeCarriesModelSpaceMotionAcrossRestOrientations() {
        let target = targetSkeleton()
        let clip = sourceClip().retargeted(to: target, options: AnimationRetargetOptions(boneMap: ["LeftArm": "upperArm.L"]))
        #expect(clip.skeleton == target && clip.duration == 1 && clip.events.map(\.name) == ["wave"])
        #expect(Set(clip.channels.map(\.target)) == [1, 2], "the spine never moves, so it gets no channel")
        let source = sourceSkeleton(), sourceRest = source.modelTransforms(), targetRest = target.modelTransforms()
        for time: Float in [0, 0.5, 1] {
            let s = pose(sourceClip(), on: source, at: time), t = pose(clip, on: target, at: time)
            // The arm turns by the same model-space rotation from its rest, whatever its rest rotation.
            let sourceDelta = s[2].rotation * sourceRest[2].rotation.conjugate
            let targetDelta = t[1].rotation * targetRest[1].rotation.conjugate
            #expect(near(sourceDelta, targetDelta), "t=\(time)")
            // The hips move twice as far (the target is twice as tall at the hips).
            #expect(near(t[2].position, Vec3(2 * time, 2, 0)), "t=\(time): \(t[2].position)")
        }
    }

    @Test func localModeRemapsRestRotationsAndKeepsKeys() {
        let target = targetSkeleton()
        let options = AnimationRetargetOptions(boneMap: ["LeftArm": "upperArm.L"], rotation: .local, translation: .none)
        let clip = sourceClip().retargeted(to: target, options: options)
        let arm = clip.channels.first { $0.target == 1 && $0.path == .rotation }
        #expect(arm?.sampler.times == [0, 1], "keys are kept, not resampled")
        // At the first key the source arm is at rest, so the target arm is at its own rest.
        #expect(near(arm!.sampler.sampleQuat(at: 0), .identity))
        #expect(near(arm!.sampler.sampleQuat(at: 1), Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))), "the arm's local X turn is a turn about the parent's Y")
        #expect(!clip.channels.contains { $0.path == .translation })
    }

    @Test func allTranslationsAndCopyMode() {
        let target = targetSkeleton()
        let copy = sourceClip().retargeted(to: target, options: AnimationRetargetOptions(rotation: .copy, translation: .all, rootScale: 1))
        // Without the map the arm isn't found ("LeftArm" vs "upperArm.L"); the hips' keys are copied.
        #expect(copy.channels.map(\.target) == [2])
        #expect(copy.channels[0].sampler.values == [0, 1, 0, 1, 1, 0])
        // A clip that doesn't know its skeleton is returned unchanged.
        var plain = sourceClip()
        plain.skeleton = nil
        #expect(plain.retargeted(to: target) == plain)
    }

    @Test func importedModelAndCharacterSkeletons() {
        var model = ImportedModel()
        model.nodes = [ImportedNode(name: "Hips", transform: Transform(position: Vec3(0, 1, 0)), children: [1]),
                       ImportedNode(name: nil, transform: Transform(), parent: 0)]
        let skeleton = AnimationSkeleton(model: model)
        #expect(skeleton.names == ["Hips", "node1"] && skeleton.bones[1].parent == 0)
        let rig = CharacterRig(template: .humanoid)
        #expect(rig.animationSkeleton.names == rig.bones.map(\.name))
        #expect(rig.animationSkeleton.subtree(of: 0).count == rig.bones.count)
    }

    @Test @MainActor func animatorRetargetsOnTheFlyThroughTheClipCache() {
        let world = World()
        // The target rig: Root › hips › spine › upperArm.L, bound depth first.
        let root = world.spawn(Transform(), Name("Root"))
        let hips = world.spawn(Transform(position: Vec3(0, 2, 0)), Name("hips"))
        let spine = world.spawn(Transform(position: Vec3(0, 0.4, 0)), Name("spine"))
        let arm = world.spawn(Transform(position: Vec3(0.4, 0.4, 0)), Name("upperArm.L"))
        world.setParent(hips, to: root)
        world.setParent(spine, to: hips)
        world.setParent(arm, to: spine)
        let rig = world.animationRig(of: root)
        let library = AnimationLibrary()
        let handle = library.register(sourceClip(), key: "AnimationRetargetTests.wave")
        var animator = Animator(targets: rig.targets, restPose: rig.restPose, clip: handle)
        let cache = AnimatorClipCache()
        // Without retarget the clip plays by index: target 0 (Root) gets the hips' keys.
        var clips = cache.clips(for: root, animator, in: world, library: library)
        #expect(clips[handle]?.channels.map(\.target) == [0, 2])
        animator.retarget = AnimationRetargetOptions(boneMap: ["LeftArm": "upperArm.L"])
        clips = cache.clips(for: root, animator, in: world, library: library)
        #expect(cache.skeleton(for: root)?.names == ["Root", "hips", "spine", "upperArm.L"])
        #expect(Set(clips[handle]?.channels.map(\.target) ?? []) == [1, 3])
        let pose = animator.update(dt: 0.5) { clips[$0] }
        #expect(near(pose.transforms[1].position, Vec3(1, 2, 0)), "\(pose.transforms[1].position)")
        // Cached until something changes.
        #expect(cache.clips(for: root, animator, in: world, library: library) == clips)
        cache.keepOnly([])
        #expect(cache.skeleton(for: root) == nil)
    }

    @Test func graphFilesCarryRetargetOptions() throws {
        let graph = try AssetJSON.decoder().decode(AnimationGraph.self, from: Data("""
            {"retarget": {"boneMap": {"mixamorig:Spine1": "chest"}, "rotation": "local"}}
            """.utf8))
        #expect(graph.retarget == AnimationRetargetOptions(boneMap: ["mixamorig:Spine1": "chest"], rotation: .local))
        #expect(try AssetJSON.decoder().decode(AnimationGraph.self, from: graph.fileData()) == graph)
        var animator = Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: []))
        animator.apply(graph)
        #expect(animator.retarget == graph.retarget)
    }
}
