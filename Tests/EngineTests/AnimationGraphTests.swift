import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineRendering

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AnimationGraphTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Graphs")
}

/// A clip moving target 0 along x from `from` to `to` over one second.
private func slide(_ from: Float, _ to: Float) -> AnimationClip {
    AnimationClip(name: "slide", channels: [AnimationChannel(target: 0, path: .translation,
                                                            sampler: AnimationSampler(times: [0, 1], values: [from, 0, 0, to, 0, 0]))])
}

private func locomotion() -> AnimationGraph {
    AnimationGraph(
        parameters: [AnimationGraphParameter(name: "speed"), AnimationGraphParameter(name: "jump", type: .trigger),
                     AnimationGraphParameter(name: "grounded", type: .bool, defaultValue: 1)],
        states: [AnimationGraphState(name: "Idle", clip: "idle"),
                 AnimationGraphState(name: "Move", blend: AnimationGraphBlend(parameter: "speed", clips: [
                    AnimationGraphBlendClip(clip: "walk", position: 1), AnimationGraphBlendClip(clip: "run", position: 3)])),
                 AnimationGraphState(name: "Jump", clip: "idle", loops: false)],
        transitions: [AnimationGraphTransition(from: "Idle", to: "Move", conditions: [AnimationGraphCondition(parameter: "speed", test: .greater, value: 0.5)], duration: 0),
                      AnimationGraphTransition(from: nil, to: "Jump", conditions: [AnimationGraphCondition(parameter: "jump", test: .triggered)], duration: 0),
                      AnimationGraphTransition(from: "Jump", to: "Idle", exitTime: 1, duration: 0)],
        layers: [AnimationGraphLayer(name: "Breathe", clip: "idle", weight: 0.5)],
        initialState: "Idle")
}

@Suite struct AnimationGraphTests {
    @Test func fileRoundTripsAndSparseFilesDecode() throws {
        let graph = locomotion()
        let decoded = try AssetJSON.decoder().decode(AnimationGraph.self, from: graph.fileData())
        #expect(decoded == graph)
        let empty = try AssetJSON.decoder().decode(AnimationGraph.self, from: Data("{}".utf8))
        #expect(empty == AnimationGraph())
        let sparse = try AssetJSON.decoder().decode(AnimationGraph.self, from: Data("""
            {"parameters": [{"name": "on", "type": "bool", "default": true}],
             "states": [{"name": "A", "clip": "a"}, {"name": "B"}],
             "transitions": [{"from": "*", "to": "B", "conditions": [{"parameter": "on", "test": "isTrue"}]}]}
            """.utf8))
        #expect(sparse.parameters[0].defaultValue == 1 && sparse.states[1].loops && sparse.states[1].speed == 1)
        #expect(sparse.transitions[0].isAnyState && sparse.transitions[0].duration == 0.25)
        #expect(AnimationGraphCheck.problems(sparse) == ["state 'B' has no clip"])
    }

    @Test func checkFindsProblems() {
        var graph = locomotion()
        #expect(AnimationGraphCheck.problems(graph).isEmpty)
        graph.transitions.append(AnimationGraphTransition(from: "Idle", to: "Nowhere"))
        graph.transitions.append(AnimationGraphTransition(from: "Move", to: "Idle", conditions: [AnimationGraphCondition(parameter: "jump", test: .greater)]))
        graph.states.append(AnimationGraphState(name: "Idle", clip: "x"))
        graph.initialState = "Missing"
        let problems = AnimationGraphCheck.problems(graph, clipExists: { $0 != "run" })
        #expect(problems.contains("two states are named 'Idle'"))
        #expect(problems.contains("the initial state 'Missing' doesn't exist"))
        #expect(problems.contains { $0.contains("goes to a state that doesn't exist") })
        #expect(problems.contains { $0.contains("never fires") })
        #expect(problems.contains { $0.contains("needs a float parameter, but 'jump' is a trigger") })
        #expect(problems.contains("clip 'run' doesn't exist"))
    }

    @Test func renamesFollowEverywhere() {
        var graph = locomotion()
        graph.renameState("Idle", to: "Rest")
        #expect(graph.initialState == "Rest" && graph.transitions[0].from == "Rest" && graph.transitions[2].to == "Rest")
        graph.renameParameter("speed", to: "velocity")
        #expect(graph.states[1].blend?.parameter == "velocity" && graph.transitions[0].conditions[0].parameter == "velocity")
        graph.removeState("Jump")
        #expect(graph.transitions.count == 1)
        #expect(graph.clipKeys == ["idle", "walk", "run"])
    }

    @MainActor @Test func stateMachineDrivesAnAnimator() {
        let graph = locomotion()
        let machine = graph.stateMachine
        #expect(machine.states.map(\.name) == ["Idle", "Move", "Jump"] && machine.initialState == "Idle")
        #expect(machine.transitions[1].from == nil && machine.transitions[1].conditions == [.triggered("jump")])
        #expect(graph.parameterDefaults["grounded"] == .bool(true) && graph.parameterDefaults["jump"] == .trigger(false))

        let library = AnimationLibrary()
        library.register(slide(0, 0), key: "idle")
        library.register(slide(0, 1), key: "walk")
        library.register(slide(0, 3), key: "run")
        let world = World()
        let target = world.spawn(Transform())
        var animator = Animator(targets: [target], restPose: [Transform()], stateMachine: machine, parameters: graph.parameterDefaults)
        _ = animator.update(dt: 0.1) { library.clip($0) }
        #expect(animator.currentState == "Idle")
        animator.setFloat("speed", 2)
        _ = animator.update(dt: 0.1) { library.clip($0) }
        #expect(animator.currentState == "Move")
        animator.setTrigger("jump")
        _ = animator.update(dt: 0.1) { library.clip($0) }
        #expect(animator.currentState == "Jump")
        #expect(animator.parameters["jump"] == .trigger(false), "the trigger is consumed")

        // Reloading a changed graph keeps the state and parameter values.
        var changed = graph
        changed.states[2].speed = 2
        animator.apply(changed)
        #expect(animator.currentState == "Jump" && animator.float("speed") == 2 && animator.stateMachine.states[2].speed == 2)
        changed.removeState("Jump")
        animator.apply(changed)
        _ = animator.update(dt: 0.01) { library.clip($0) }
        #expect(animator.currentState == "Idle" || animator.currentState == "Move", "a removed state restarts in the initial state")
    }

    @MainActor @Test func importsAndHotReloadsIntoSceneAnimators() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let gltf = project.url(forAssetPath: "rig.gltf")
        try animationClipImportGLTF().write(to: gltf)
        let database = AssetDatabase(project: project)
        database.refresh()
        let model = try #require(database.id(forPath: "rig.gltf"))
        #expect(database.normalizedAssetKey("rig.gltf#animation/Bend") == "asset:\(model)#animation/Bend")
        #expect(database.normalizedAssetKey("someCodeKey") == "someCodeKey")
        #expect(database.animationClipKeys == ["asset:\(model)#animation/Bend"])

        let bend = "asset:\(model)#animation/Bend"
        var graph = AnimationGraph(preview: "asset:\(model)", states: [AnimationGraphState(name: "Bend", clip: bend, loops: false)])
        let id = try database.createAnimationGraph(graph, at: "Anim/rig.animgraph")
        let record = try #require(database.record(id))
        #expect(record.importer == "animgraph" && record.objects.map(\.kind) == [.animationGraph] && record.objects[0].id == "animgraph/rig")
        #expect(database.animationGraph(AssetReference(id)) == graph)
        #expect(database.animationGraph(of: id) == graph)

        let world = World()
        let root = try #require(world.instantiate(database.prefab(AssetReference(model))!).first)
        var animator = Animator(targets: [], restPose: [], stateMachine: AnimationStateMachine(states: []))
        animator.graph = AssetReference(id)
        #expect(animator.isSceneDriven)
        world.add(animator, to: root)
        world.addSceneAnimationSystem(assets: { database })
        world.update(dt: 0.5)
        let playing = try #require(world.get(Animator.self, for: root))
        #expect(playing.currentState == "Bend" && playing.targets.count == 4)

        // Edit the file: a new state and parameter arrive in the playing animator.
        graph.parameters = [AnimationGraphParameter(name: "go", type: .bool)]
        graph.states.append(AnimationGraphState(name: "Hold", clip: bend))
        graph.transitions = [AnimationGraphTransition(from: "Bend", to: "Hold", conditions: [AnimationGraphCondition(parameter: "go", test: .isTrue)], duration: 0)]
        let warnings = try database.writeAnimationGraph(graph, to: id)
        #expect(warnings.isEmpty)
        world.update(dt: 0.1)
        var reloaded = try #require(world.get(Animator.self, for: root))
        #expect(reloaded.stateMachine.states.map(\.name) == ["Bend", "Hold"] && reloaded.bool("go") == false)
        #expect(reloaded.currentState == "Bend", "kept the state it was in")
        reloaded.setBool("go", true)
        world.add(reloaded, to: root)
        world.update(dt: 0.1)
        #expect(world.get(Animator.self, for: root)?.currentState == "Hold")

        // A broken file still imports, with warnings.
        let broken = try database.writeAnimationGraph(AnimationGraph(states: [AnimationGraphState(name: "A")]), to: id)
        #expect(broken == ["state 'A' has no clip"])
    }
}
