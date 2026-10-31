import Foundation
import Testing
@testable import Engine

private func approx(_ a: Float, _ b: Float, _ eps: Float = 1e-5) -> Bool { abs(a - b) <= eps }
private func approx(_ a: Vec3, _ b: Vec3, _ eps: Float = 1e-4) -> Bool { length(a - b) <= eps }
private func approx(_ a: Quat, _ b: Quat, _ eps: Float = 1e-4) -> Bool {
    min(length4(a.vector - b.vector), length4(a.vector + b.vector)) <= eps
}
private func length4(_ v: Vec4) -> Float { (v * v).sum().squareRoot() }

/// A tiny skinned glTF: a 3-vertex triangle bound to two joints (a root and a child one unit
/// up), with inverse bind matrices and one animation using every interpolation mode.
private func skinnedGLTF() -> Data {
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
    let ibm: [Float] = Mat4.identity.columns + Mat4.translation(Vec3(0, -1, 0)).columns
    let inverseBind = add(ibm, componentType: 5126, count: 2, type: "MAT4")
    let times = add([Float](arrayLiteral: 0, 1), componentType: 5126, count: 2, type: "SCALAR")
    let half = sinf(.pi / 4)
    let rotations = add([Float](arrayLiteral: 0, 0, 0, 1, 0, half, 0, half), componentType: 5126, count: 2, type: "VEC4")
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
            "name": "Bend",
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
    var columns: [Float] { [c0, c1, c2, c3].flatMap { [$0.x, $0.y, $0.z, $0.w] } }
}

/// A clip moving target 0 along x from `from` to `to` over `duration` seconds.
private func slide(_ name: String, from: Float, to: Float, duration: Float, events: [AnimationEvent] = []) -> AnimationClip {
    AnimationClip(name: name, channels: [AnimationChannel(
        target: 0, path: .translation,
        sampler: AnimationSampler(times: [0, duration], values: [from, 0, 0, to, 0, 0]))], events: events)
}

@MainActor
private func library(_ clips: [AnimationClip]) -> AnimationLibrary {
    let library = AnimationLibrary()
    for clip in clips { library.register(clip, key: clip.name) }
    return library
}

@Suite struct SkinningTests {
    @Test func importsSkinsJointsAndAnimations() throws {
        let model = try GLTFReader.read(data: skinnedGLTF())
        #expect(model.warnings.isEmpty)
        #expect(model.skins.count == 1 && model.skins[0].joints == [1, 2] && model.skins[0].skeleton == 1)
        #expect(model.skins[0].inverseBindMatrices[1] == Mat4.translation(Vec3(0, -1, 0)))
        #expect(model.nodes[0].skin == 0)
        // No normals: flat normals unweld the vertices, and the influences follow them.
        let geometry = model.meshes[0].primitives[0].geometry
        let skin = try #require(geometry.skin)
        #expect(skin.count == geometry.vertices.count)
        for (vertex, influence) in zip(geometry.vertices, skin) {
            #expect(approx(influence.weights.sum(), 1))
            if vertex.position.y == 2 {
                #expect(influence.joints == SIMD4(1, 0, 0, 0) && influence.weights == Vec4(0.5, 0.5, 0, 0))
            } else {
                #expect(influence.joints.x == 0 && influence.weights == Vec4(1, 0, 0, 0))
            }
        }
        let clip = try #require(model.animations.first)
        #expect(clip.name == "Bend" && clip.duration == 1 && clip.channels.count == 3)
        #expect(clip.channels.map(\.sampler.interpolation) == [.linear, .step, .cubicSpline])
        #expect(clip.channels.map(\.target) == [1, 2, 2])
    }

    @MainActor @Test func instantiateBindsSkinsAndAnimates() throws {
        let model = try GLTFReader.read(data: skinnedGLTF())
        let world = World()
        let instance = model.instantiate(in: world, mesh: { _, _ in .cube }, material: { _ in .default })
        let meshEntity = try #require(instance.nodes[0])
        let skin = try #require(world.get(Skin.self, for: meshEntity))
        #expect(skin.joints == [instance.nodes[1]!, instance.nodes[2]!])

        let clips = library(model.animations)
        world.addAnimationSystem(clips)
        let rig = model.animationTargets(of: instance)
        world.add(Animator(targets: rig.targets, restPose: rig.restPose, clip: AnimationClipHandle("Bend"), loops: false),
                  to: instance.roots[0])
        world.update(dt: 0.5)
        // Root turned 45° about Y; the tip's step translation holds the first key.
        let root = try #require(world.get(Transform.self, for: instance.nodes[1]!))
        #expect(approx(root.rotation, Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))))
        #expect(world.get(Transform.self, for: instance.nodes[2]!)!.position == Vec3(0, 1, 0))
        // The mesh node isn't animated, so its transform is untouched.
        #expect(world.get(Transform.self, for: meshEntity)! == model.nodes[0].transform)

        // Joint matrices: the root's turn applies to vertices bound to it.
        let joints = SkinPose.joints(of: skin, meshWorld: .identity, jointCount: 2) { world.get(GlobalTransform.self, for: $0)?.matrix }
        let p = joints[0] * Vec4(1, 0, 0, 1)
        #expect(approx(Vec3(p.x, p.y, p.z), Quat(angle: .pi / 4, axis: Vec3(0, 1, 0)) * Vec3(1, 0, 0)))
        // Posed bounds contain every posed vertex.
        let geometry = model.meshes[0].primitives[0].geometry
        let bounds = try #require(SkinPose.bounds(geometry.jointBounds, joints: joints))
        for (vertex, influence) in zip(geometry.vertices, geometry.skin!) {
            var q = Vec4.zero
            for k in 0..<4 { q += (joints[Int(influence.joints[k])] * Vec4(vertex.position, 1)) * influence.weights[k] }
            let o = Vec3(q.x, q.y, q.z) - bounds.center
            let d = Vec3(abs(o.x), abs(o.y), abs(o.z)) - bounds.halfExtent
            #expect(d.max() <= 1e-4)
        }
    }

    @Test func samplerInterpolation() {
        let linear = AnimationSampler(times: [1, 3], values: [0, 0, 0, 4, 8, 0])
        #expect(linear.sampleVec3(at: 0) == Vec3(0, 0, 0))
        #expect(linear.sampleVec3(at: 2) == Vec3(2, 4, 0))
        #expect(linear.sampleVec3(at: 5) == Vec3(4, 8, 0))
        let step = AnimationSampler(interpolation: .step, times: [0, 1, 2], values: [1, 1, 1, 2, 2, 2, 3, 3, 3])
        #expect(step.sampleVec3(at: 0.99) == Vec3(1, 1, 1) && step.sampleVec3(at: 1) == Vec3(2, 2, 2))
        // Cubic spline: p(t) = h00 v0 + h10 dt b0 + h01 v1 + h11 dt a1.
        let cubic = AnimationSampler(interpolation: .cubicSpline, times: [0, 2],
                                     values: [9, 9, 9, 0, 0, 0, 1, 0, 0, -1, 0, 0, 4, 0, 0, 9, 9, 9])
        let t: Float = 0.25, dt: Float = 2
        let expected = (2 * t * t * t - 3 * t * t + 1) * 0 + (t * t * t - 2 * t * t + t) * dt * 1
            + (-2 * t * t * t + 3 * t * t) * 4 + (t * t * t - t * t) * dt * -1
        #expect(approx(cubic.sampleVec3(at: 0.5).x, expected))
        #expect(cubic.sampleVec3(at: 2) == Vec3(4, 0, 0))
        // Rotation: slerp along the shorter arc, normalized.
        let q90 = Quat(angle: .pi / 2, axis: Vec3(0, 1, 0))
        let rotation = AnimationSampler(times: [0, 1], values: [0, 0, 0, 1] + [-q90.x, -q90.y, -q90.z, -q90.w])
        #expect(approx(rotation.sampleQuat(at: 0.5), Quat(angle: .pi / 4, axis: Vec3(0, 1, 0))))
        let spline = AnimationSampler(interpolation: .cubicSpline, times: [0, 1],
                                      values: [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0] + [0, 0, 0, 0] + q90.vector.array + [0, 0, 0, 0])
        #expect(approx(spline.sampleQuat(at: 1), q90) && approx(spline.sampleQuat(at: 0.5).length, 1))
    }

    @MainActor @Test func crossfadeWeights() {
        let clips = library([slide("A", from: 0, to: 0, duration: 1), slide("B", from: 10, to: 10, duration: 1)])
        let machine = AnimationStateMachine(states: [AnimationState("A", .clip(AnimationClipHandle("A"))),
                                                     AnimationState("B", .clip(AnimationClipHandle("B")))])
        var animator = Animator(targets: [.invalid], restPose: [Transform()], stateMachine: machine)
        _ = animator.update(dt: 0.1) { clips.clip($0) }
        animator.play("B", fade: 1)
        var pose = animator.update(dt: 0.25) { clips.clip($0) }
        #expect(animator.isInTransition && animator.playbacks.map(\.weight) == [0.75, 0.25])
        #expect(approx(pose.transforms[0].position.x, 2.5))
        pose = animator.update(dt: 0.5) { clips.clip($0) }
        #expect(approx(pose.transforms[0].position.x, 7.5))
        // Interrupted halfway back: weights keep summing to 1.
        animator.play("A", fade: 0.5)
        _ = animator.update(dt: 0.25) { clips.clip($0) }
        #expect(animator.playbacks.map(\.state) == [0, 1, 0])
        #expect(approx(animator.playbacks.map(\.weight).reduce(0, +), 1))
        pose = animator.update(dt: 0.25) { clips.clip($0) }
        #expect(!animator.isInTransition && animator.currentState == "A" && pose.transforms[0].position.x == 0)
    }

    @MainActor @Test func blendSpace() {
        #expect(AnimationMotion.blendWeights(positions: [0, 1, 2.5], value: -1) == [1, 0, 0])
        #expect(AnimationMotion.blendWeights(positions: [0, 1, 2.5], value: 1.75) == [0, 0.5, 0.5])
        #expect(AnimationMotion.blendWeights(positions: [2.5, 0, 1], value: 0.25) == [0, 0.75, 0.25])
        #expect(AnimationMotion.blendWeights(positions: [0, 1], value: 9) == [0, 1])
        // Clips of 1 s and 3 s blended half and half advance at the average rate (one cycle per 2 s).
        let clips = library([slide("Walk", from: 0, to: 1, duration: 1), slide("Run", from: 0, to: 3, duration: 3)])
        let entries = [BlendSpaceEntry(clip: AnimationClipHandle("Walk"), position: 1), BlendSpaceEntry(clip: AnimationClipHandle("Run"), position: 3)]
        var animator = Animator(targets: [.invalid], restPose: [Transform()],
                                stateMachine: AnimationStateMachine(states: [AnimationState("Move", .blend1D(parameter: "speed", entries: entries))]),
                                parameters: ["speed": .float(2)])
        let pose = animator.update(dt: 0.5) { clips.clip($0) }
        #expect(approx(animator.normalizedTime, 0.25))
        // Walk at 0.25 cycles is 0.25, Run is 0.75: blended 0.5.
        #expect(approx(pose.transforms[0].position.x, 0.5))
    }

    @MainActor @Test func stateMachineTransitions() {
        let clips = library([slide("Idle", from: 0, to: 0, duration: 1), slide("Walk", from: 1, to: 1, duration: 1),
                             slide("Jump", from: 5, to: 5, duration: 0.5)])
        let machine = AnimationStateMachine(
            states: [AnimationState("Idle", .clip(AnimationClipHandle("Idle"))), AnimationState("Walk", .clip(AnimationClipHandle("Walk"))),
                     AnimationState("Jump", .clip(AnimationClipHandle("Jump")), loops: false)],
            transitions: [
                AnimationTransition(from: "Idle", to: "Walk", conditions: [.greater("speed", 0.1)], duration: 0.2),
                AnimationTransition(from: "Walk", to: "Idle", conditions: [.less("speed", 0.1)], exitTime: 0.5, duration: 0),
                AnimationTransition(from: nil, to: "Jump", conditions: [.triggered("jump")], duration: 0),
                AnimationTransition(from: "Jump", to: "Idle", exitTime: 1, duration: 0),
            ],
            initialState: "Idle")
        var animator = Animator(targets: [.invalid], restPose: [Transform()], stateMachine: machine, parameters: ["speed": .float(0)])
        let lookup = { (handle: AnimationClipHandle) in clips.clip(handle) }
        _ = animator.update(dt: 0.1, clip: lookup)
        #expect(animator.currentState == "Idle")
        animator.setFloat("speed", 1)
        _ = animator.update(dt: 0.1, clip: lookup)
        #expect(animator.currentState == "Walk" && animator.isInTransition)
        _ = animator.update(dt: 0.2, clip: lookup)
        #expect(!animator.isInTransition)
        // Back to idle only when the walk cycle passes its exit time 0.5.
        animator.setFloat("speed", 0)
        _ = animator.update(dt: 0.1, clip: lookup)  // walk at 0.3
        #expect(animator.currentState == "Walk")
        _ = animator.update(dt: 0.25, clip: lookup)  // 0.55: crossed 0.5
        #expect(animator.currentState == "Idle")
        // A trigger fires once and is consumed; the one-shot state returns at its end.
        animator.setTrigger("jump")
        let pose = animator.update(dt: 0.1, clip: lookup)
        #expect(animator.currentState == "Jump" && animator.parameters["jump"] == .trigger(false))
        #expect(pose.transforms[0].position.x == 5)  // a transition without fade shows its state at once
        _ = animator.update(dt: 0.3, clip: lookup)
        #expect(animator.currentState == "Jump")
        _ = animator.update(dt: 0.3, clip: lookup)
        #expect(animator.currentState == "Idle")
    }

    @MainActor @Test func eventsAndDeterminism() {
        let clips = library([slide("Walk", from: 0, to: 2, duration: 1,
                                   events: [AnimationEvent(time: 0, name: "left"), AnimationEvent(time: 0.5, name: "right")])])
        func run(_ steps: [Float]) -> (poses: [AnimationPose], events: [String]) {
            var animator = Animator(targets: [.invalid], restPose: [Transform()], clip: AnimationClipHandle("Walk"))
            var poses: [AnimationPose] = [], events: [String] = []
            for dt in steps {
                poses.append(animator.update(dt: dt) { clips.clip($0) })
                events += animator.events.map(\.name)
            }
            return (poses, events)
        }
        let steps = (0..<147).map { Float(1 + $0 % 3) / 60 }
        let a = run(steps), b = run(steps)
        #expect(a.poses == b.poses && a.events == b.events)
        // 147 steps of 1–3 frames: 4.9 s, so five cycles of left + right (the first left at time 0).
        #expect(a.events == Array(repeating: ["left", "right"], count: 5).flatMap { $0 })
    }

    @MainActor @Test func skinnedItemsGetTheirOwnBatches() {
        func item(_ i: Int, skin: Int) -> RenderItem {
            RenderItem(entity: Entity(index: UInt32(i), generation: 0), mesh: 0, material: 0,
                       instance: MeshInstance(model: .identity, previousModel: .identity, color: Vec4(1, 1, 1, 1), params: .zero),
                       bounds: Bounds(center: .zero, halfExtent: Vec3(1, 1, 1)), castsShadows: true, transparent: false, skin: skin)
        }
        let items = [item(0, skin: -1), item(1, skin: 0), item(2, skin: -1), item(3, skin: 1)]
        var list = RenderList()
        let frustum = Frustum(viewProjection: Mat4.perspective(fovY: 1, aspect: 1, near: 0.1, far: 100) * Mat4.translation(Vec3(0, 0, -5)))
        list.build(items: items, view: frustum, cameraPosition: Vec3(0, 0, 5), shadows: nil)
        #expect(list.opaque.map(\.count) == [2, 1, 1] && list.opaque.map(\.skin) == [-1, 0, 1])
        var casters = ShadowCasterBatches()
        casters.build(items: items, tiles: [ShadowTileCulling(frustum: frustum)])
        #expect(casters.batches.map(\.skin) == [-1, 0, 1] && casters.batches.map(\.count) == [2, 1, 1])
    }
}

private extension SIMD4<Float> {
    var array: [Float] { [x, y, z, w] }
}
