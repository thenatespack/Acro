import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineRendering

/// A tiny skinned glTF: a 3-vertex triangle bound to two joints (a root and a child one unit
/// up), with inverse bind matrices and one animation using every interpolation mode.
func animationClipImportGLTF(clipName: String = "Bend", endAngle: Float = .pi / 2) -> Data {
    var bin: [UInt8] = []
    var views: [[String: Any]] = [], accessors: [[String: Any]] = []
    func add<T: BitwiseCopyable>(_ values: [T], componentType: Int, count: Int, type: String) -> Int {
        while bin.count % 4 != 0 { bin.append(0) }
        let bytes = values.withUnsafeBytes { Array($0) }
        views.append(["buffer": 0, "byteOffset": bin.count, "byteLength": bytes.count])
        bin += bytes
        accessors.append(["bufferView": views.count - 1, "componentType": componentType, "count": count, "type": type])
        return accessors.count - 1
    }
    let positions = add([Float](arrayLiteral: 0, 0, 0, 1, 0, 0, 0, 2, 0), componentType: 5126, count: 3, type: "VEC3")
    let joints = add([UInt8](arrayLiteral: 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0), componentType: 5121, count: 3, type: "VEC4")
    // Unnormalized on purpose: the reader normalizes to a sum of 1.
    let weights = add([Float](arrayLiteral: 2, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0), componentType: 5126, count: 3, type: "VEC4")
    let ibm: [Float] = Mat4.identity.clipImportColumns + Mat4.translation(Vec3(0, -1, 0)).clipImportColumns
    let inverseBind = add(ibm, componentType: 5126, count: 2, type: "MAT4")
    let times = add([Float](arrayLiteral: 0, 1), componentType: 5126, count: 2, type: "SCALAR")
        let rotations = add([Float](arrayLiteral: 0, 0, 0, 1, 0, sinf(endAngle / 2), 0, cosf(endAngle / 2)), componentType: 5126, count: 2, type: "VEC4")
    let translations = add([Float](arrayLiteral: 0, 1, 0, 0, 3, 0), componentType: 5126, count: 2, type: "VEC3")
    // In-tangent, value, out-tangent per key.
    let scales = add([Float](arrayLiteral: 0, 0, 0, 1, 1, 1, 2, 2, 2, 0, 0, 0, 3, 3, 3, 0, 0, 0), componentType: 5126, count: 6, type: "VEC3")
    let json: [String: Any] = [
        "asset": ["version": "2.0"],
        "scene": 0,
        "scenes": [["nodes": [0, 1]]],
        "nodes": [
            ["name": "Mesh", "mesh": 0, "skin": 0],
            ["name": "Root", "children": [2]],
            ["name": "Tip", "translation": [0, 1, 0]],
        ],
        "meshes": [["primitives": [["attributes": ["POSITION": positions, "JOINTS_0": joints, "WEIGHTS_0": weights]]]]],
        "skins": [["joints": [1, 2], "inverseBindMatrices": inverseBind, "skeleton": 1]],
        "animations": [[
            "name": clipName,
            "samplers": [
                ["input": times, "output": rotations],
                ["input": times, "output": translations, "interpolation": "STEP"],
                ["input": times, "output": scales, "interpolation": "CUBICSPLINE"],
            ],
            "channels": [
                ["sampler": 0, "target": ["node": 1, "path": "rotation"]],
                ["sampler": 1, "target": ["node": 2, "path": "translation"]],
                ["sampler": 2, "target": ["node": 2, "path": "scale"]],
            ],
        ]],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [["byteLength": bin.count, "uri": "data:application/octet-stream;base64," + Data(bin).base64EncodedString()]],
    ]
    return try! JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
}

private extension Mat4 {
    var clipImportColumns: [Float] { [c0, c1, c2, c3].flatMap { [$0.x, $0.y, $0.z, $0.w] } }
}


private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AnimationClipImportTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Clips")
}

private func approxQuat(_ a: Quat, _ b: Quat, _ eps: Float = 1e-4) -> Bool {
    let d = a.vector - b.vector, s = a.vector + b.vector
    return min((d * d).sum(), (s * s).sum()).squareRoot() <= eps
}

@Suite struct AnimationClipImportTests {
    @MainActor @Test func gltfClipsBecomeAnimationSubAssetsOnPrefabNodeNumbers() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.url(forAssetPath: "Models/rig.gltf")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try animationClipImportGLTF().write(to: url)
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "Models/rig.gltf"))
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        #expect(record.objects.contains { $0.id == "animation/Bend" && $0.kind == .animation && $0.name == "Bend" })
        #expect(database.references(of: .animation) == [AssetReference(id, subAsset: "animation/Bend")])

        let clip = try #require(database.animationClip(AssetReference(id, subAsset: "animation/Bend")))
        #expect(clip.duration == 1 && clip.channels.count == 3)
        // Two scene roots: a wrapper root is node 0, then Mesh 1, Root 2, Tip 3.
        #expect(clip.channels.map(\.target) == [2, 3, 3])
        #expect(database.animationClip(AssetReference(id)) == clip, "a whole-file reference means the first clip")
        #expect(database.animationClip(AssetReference(id, subAsset: "animation/Nope")) == nil)

        // The Library cache keeps the clip.
        let reopened = AssetDatabase(project: project)
        reopened.refresh()
        #expect(reopened.animationClip(AssetReference(id, subAsset: "animation/Bend")) == clip)
    }

    @MainActor @Test func sceneAnimationSystemPlaysAssetClipsOnAPrefabInstance() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let url = project.url(forAssetPath: "rig.gltf")
        try animationClipImportGLTF().write(to: url)
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "rig.gltf"))
        let prefab = try #require(database.prefab(AssetReference(id)))

        let world = World()
        let root = try #require(world.instantiate(prefab).first)
        let rig = world.animationRig(of: root)
        #expect(rig.targets.count == 4 && rig.targets[0] == root)
        #expect(rig.targets.map { world.get(Name.self, for: $0)?.value } == ["rig", "Mesh", "Root", "Tip"])
        let handle = AnimationClipHandle(AssetReference(id, subAsset: "animation/Bend").description)
        world.add(Animator(targets: rig.targets, restPose: rig.restPose, clip: handle, loops: false), to: root)
        // A second instance whose animator has no targets yet: bound from its subtree.
        let other = try #require(world.instantiate(prefab).first)
        world.add(Animator(targets: [], restPose: [], clip: handle, loops: false), to: other)

        let library = world.addSceneAnimationSystem(assets: { database })
        world.update(dt: 0.5)
        #expect(library.clip(handle) != nil)
        let quarter = Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))
        #expect(approxQuat(world.get(Transform.self, for: rig.targets[2])!.rotation, quarter))
        #expect(world.get(Transform.self, for: rig.targets[3])!.position == Vec3(0, 1, 0), "step translation holds the first key")
        let bound = try #require(world.get(Animator.self, for: other))
        #expect(bound.targets.count == 4)
        #expect(approxQuat(world.get(Transform.self, for: bound.targets[2])!.rotation, quarter))

        // Hot reload: the file changes, the clip is reloaded on the next frame.
        try animationClipImportGLTF(endAngle: .pi).write(to: url)
        database.refresh()
        world.update(dt: 0.5)
        #expect(approxQuat(world.get(Transform.self, for: rig.targets[2])!.rotation, Quat(angle: .pi, axis: Vec3(0, 1, 0))),
                "at the end of the reloaded clip: a half turn")
    }

    @MainActor @Test func codeDrivenAnimatorsAreLeftAlone() throws {
        let world = World()
        let target = world.spawn(Transform())
        let clip = AnimationClip(name: "Slide", channels: [AnimationChannel(
            target: 0, path: .translation, sampler: AnimationSampler(times: [0, 1], values: [0, 0, 0, 1, 0, 0]))])
        let animator = Animator(targets: [target], restPose: [Transform()], clip: AnimationClipHandle("Slide"))
        #expect(!animator.isSceneDriven && animator.clipHandles == [AnimationClipHandle("Slide")])
        world.add(animator, to: target)
        let library = world.addSceneAnimationSystem(assets: { nil })
        library.register(clip, key: "Slide")
        world.update(dt: 0.5)
        #expect(world.get(Transform.self, for: target)!.position == .zero, "not advanced by the scene system")
        #expect(library.resolveAssetClips([AnimationClipHandle("asset:nothing")]).isEmpty, "no database: nothing to resolve")
    }

    @MainActor @Test func animatorRoundTripsThroughASceneFile() throws {
        GamePlayer.registerEngineComponents()
        let world = World()
        let root = world.spawn(Transform(), Name("Root"))
        let child = world.spawn(Transform(position: Vec3(0, 1, 0)), Name("Child"))
        world.setParent(child, to: root)
        let rig = world.animationRig(of: root)
        world.add(Animator(targets: rig.targets, restPose: rig.restPose, clip: AnimationClipHandle("asset:0123456789abcdef0123456789abcdef#animation/Walk")), to: root)
        let data = try world.save()
        let loaded = World()
        let roots = try loaded.load(data)
        let animator = try #require(loaded.get(Animator.self, for: roots[0]))
        #expect(animator.targets.count == 2 && animator.targets[0] == roots[0])
        #expect(animator.targets[1] == loaded.children(of: roots[0]).first)
        #expect(animator.isSceneDriven)
    }
}
