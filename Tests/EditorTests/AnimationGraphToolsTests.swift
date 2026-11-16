import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineAssets
@testable import EngineUI
@testable import EngineRendering

// The animation graph builder as an agent uses it (animGraph.* tools, JSON in and out), undo,
// and the builder tab's preview driven by hand.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("AnimationGraphToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

/// A glTF with one root node and two clips ("Idle" turns it a little, "Walk" moves it along x).
private func twoClipGLTF() -> Data {
    var bin: [UInt8] = []
    var views: [[String: Any]] = [], accessors: [[String: Any]] = []
    func add(_ values: [Float], count: Int, type: String) -> Int {
        let bytes = values.withUnsafeBytes { Array($0) }
        views.append(["buffer": 0, "byteOffset": bin.count, "byteLength": bytes.count])
        bin += bytes
        accessors.append(["bufferView": views.count - 1, "componentType": 5126, "count": count, "type": type])
        return accessors.count - 1
    }
    let times = add([0, 1], count: 2, type: "SCALAR")
    let moves = add([0, 0, 0, 2, 0, 0], count: 2, type: "VEC3")
    let turns = add([0, 0, 0, 1, 0, 0.1, 0, 0.995], count: 2, type: "VEC4")
    let json: [String: Any] = [
        "asset": ["version": "2.0"], "scene": 0, "scenes": [["nodes": [0]]],
        "nodes": [["name": "Body"]],
        "animations": [
            ["name": "Idle", "samplers": [["input": times, "output": turns]], "channels": [["sampler": 0, "target": ["node": 0, "path": "rotation"]]]],
            ["name": "Walk", "samplers": [["input": times, "output": moves]], "channels": [["sampler": 0, "target": ["node": 0, "path": "translation"]]]],
        ],
        "accessors": accessors, "bufferViews": views,
        "buffers": [["byteLength": bin.count, "uri": "data:application/octet-stream;base64," + Data(bin).base64EncodedString()]],
    ]
    return try! JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
}

@MainActor
@Suite struct AnimationGraphToolsTests {
    private func project(_ session: EditorSession, _ folder: URL) throws -> AssetID {
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let assets = try #require(session.assets)
        let url = assets.project.url(forAssetPath: "Models/hero.gltf")
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try twoClipGLTF().write(to: url)
        assets.refresh()
        return try #require(assets.id(forPath: "Models/hero.gltf"))
    }

    @Test func newEditGetSetAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        let model = try project(session, folder)

        let created = try call(session, "animGraph.new", ["name": "Hero", "folder": "Anim", "preview": "Models/hero.gltf"])
        #expect(created["path"] as? String == "Anim/Hero.animgraph")
        #expect(created["states"] as? [String] == ["Idle", "Move"])
        #expect(created["parameters"] as? [String] == ["speed (float)"])
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isAnimationGraphFile(id))
        let graph = try #require(session.assets?.animationGraph(of: id))
        #expect(graph.preview == "asset:\(model)")
        #expect(graph.states[0].clip == "asset:\(model)#animation/Idle" && graph.states[1].clip == "asset:\(model)#animation/Walk")

        let edited = try call(session, "animGraph.edit", [
            "path": "Anim/Hero.animgraph",
            "parameters": [["name": "jump", "type": "trigger"], ["name": "speed", "type": "float", "default": 0.5]],
            "addStates": [["name": "Jump", "clip": "Models/hero.gltf#animation/Idle", "loops": false],
                          ["name": "Locomotion", "blend": ["parameter": "speed", "clips": [
                            ["clip": "Models/hero.gltf#animation/Idle", "position": 0], ["clip": "Models/hero.gltf#animation/Walk", "position": 2]]]]],
            "addTransitions": [["to": "Jump", "conditions": [["parameter": "jump", "test": "triggered"]], "duration": 0.1],
                               ["from": "Jump", "to": "Idle", "exitTime": 0.9]],
            "updateStates": ["Move": ["name": "Walk", "speed": 1.5]],
            "updateTransitions": ["0": ["duration": 0.05]],
            "addLayers": [["name": "Lean", "clip": "Models/hero.gltf#animation/Idle", "weight": 0.3]],
            "initialState": "Locomotion",
        ])
        #expect(edited["states"] as? [String] == ["Idle", "Walk", "Jump", "Locomotion"])
        #expect(edited["transitions"] as? [String] == ["0: Idle -> Walk", "1: Walk -> Idle", "2: * -> Jump", "3: Jump -> Idle"])
        #expect((edited["warnings"] as? [String])?.isEmpty == true, "\(edited["warnings"] ?? "")")
        let after = try #require(session.assets?.animationGraph(of: id))
        #expect(after.state(named: "Walk")?.speed == 1.5 && after.transitions[0].duration == 0.05)
        #expect(after.state(named: "Locomotion")?.blend?.clips[1].clip == "asset:\(model)#animation/Walk", "paths become references")
        #expect(after.parameter(named: "speed")?.defaultValue == 0.5 && after.initialState == "Locomotion")
        #expect(after.layers.map(\.name) == ["Lean"])
        #expect(after.state(named: "Jump")!.position != .zero, "new nodes are placed beside the others")

        let got = try call(session, "animGraph.get", ["asset": "asset:\(id)"])
        #expect((got["clips"] as? [String]) == ["asset:\(model)#animation/Idle", "asset:\(model)#animation/Walk"])
        #expect(((got["graph"] as? [String: Any])?["states"] as? [Any])?.count == 4)

        #expect(throws: (any Error).self) { try call(session, "animGraph.edit", ["path": "Anim/Hero.animgraph", "addTransitions": [["to": "Nowhere"]]]) }
        #expect(throws: (any Error).self) { try call(session, "animGraph.edit", ["path": "Anim/Hero.animgraph", "removeTransitions": [9]]) }
        let bad = try call(session, "animGraph.edit", ["path": "Anim/Hero.animgraph", "removeParameters": ["jump"], "addStates": [["name": "Lost", "clip": "asset:\(model)#animation/Nope"]]])
        let warnings = try #require(bad["warnings"] as? [String])
        #expect(warnings.contains { $0.contains("'jump', which doesn't exist") })
        #expect(warnings.contains("clip 'asset:\(model)#animation/Nope' doesn't exist"))

        session.performUndo()
        #expect(session.assets?.animationGraph(of: id) == after, "one undo step per edit")
        session.performUndo()
        #expect(session.assets?.animationGraph(of: id) == graph)
        session.performRedo()
        #expect(session.assets?.animationGraph(of: id) == after)

        let set = try call(session, "animGraph.set", ["path": "Anim/Hero.animgraph", "graph": ["states": [["name": "Only", "clip": "Models/hero.gltf#animation/Walk"]]]])
        #expect(set["states"] as? [String] == ["Only"])
        #expect(session.assets?.animationGraph(of: id)?.preview == nil, "set replaces everything")
    }

    @Test func assignPutsAnAnimatorOnAPlacedModel() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        let model = try project(session, folder)
        let created = try call(session, "animGraph.new", ["name": "Hero", "preview": "asset:\(model)"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let placed = try #require(session.instantiate(.asset(model), at: .zero).first)
        session.selection.clear()
        #expect(throws: (any Error).self) { try call(session, "animGraph.assign", ["asset": "asset:\(id)"]) }  // nothing selected
        session.selection.select(placed)
        let assigned = try call(session, "animGraph.assign", ["asset": "asset:\(id)"])
        #expect(assigned["targets"] as? Int == 1)
        let entity = try #require(session.world.entity(for: placed))
        let animator = try #require(session.world.get(Animator.self, for: entity))
        #expect(animator.graph == AssetReference(id) && animator.stateMachine.states.map(\.name) == ["Idle", "Move"])
        // Assigning again replaces it (one undo step each).
        try call(session, "animGraph.assign", ["asset": "asset:\(id)", "entity": placed.description])
        session.performUndo()
        #expect(session.world.get(Animator.self, for: entity) != nil)
        session.performUndo()
        #expect(session.world.get(Animator.self, for: entity) == nil)
    }

    @Test func workspacePreviewFollowsParametersAndEdits() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        let model = try project(session, folder)
        let created = try call(session, "animGraph.new", ["name": "Hero", "preview": "Models/hero.gltf"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        let workspace = AnimationGraphWorkspace(session: session)
        var opened: AssetID?
        session.onOpenAnimationGraph = { opened = $0; workspace.open($0) }
        try call(session, "animGraph.open", ["path": "Hero.animgraph"])
        #expect(opened == id && workspace.asset == id)
        workspace.update(input: nil, dt: 0.1)
        #expect(workspace.previewRoot != nil && workspace.animator?.currentState == "Idle")
        #expect(workspace.form?.canvas.activeState == "Idle")

        workspace.setParameter("speed", .float(1))
        workspace.update(input: nil, dt: 0.1)
        workspace.update(input: nil, dt: 0.3)
        #expect(workspace.animator?.currentState == "Move")
        // The walk clip moves the body along x.
        let body = try #require(workspace.previewRoot)
        #expect((workspace.world.get(Transform.self, for: body)?.position.x ?? 0) > 0)

        // An edit through the form is one undo step, and the preview takes the new graph.
        let form = try #require(workspace.form)
        form.addState()
        workspace.update(input: nil, dt: 0.1)
        #expect(session.assets?.animationGraph(of: id)?.states.map(\.name) == ["Idle", "Move", "State"])
        #expect(workspace.animator?.stateMachine.states.count == 3)
        #expect(workspace.animator?.float("speed") == 1, "hand-set values survive a reload")
        #expect(form.selection == .state("State"))
        form.canvas.onConnect?("State", "Idle")
        workspace.update(input: nil, dt: 0.1)
        #expect(session.assets?.animationGraph(of: id)?.transitions.last?.from == "State")
        session.performUndo()
        workspace.update(input: nil, dt: 0.1)
        #expect(session.assets?.animationGraph(of: id)?.transitions.count == 2)
        #expect(form.graph.transitions.count == 2, "the form rereads the file after undo")
        _ = model
    }

    @Test func retargetOptionsAndBoneMatching() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        _ = try project(session, folder)
        // Another model whose "Body" sits under a "Root": node 0 is Root there, not Body.
        let assets = try #require(session.assets)
        try Data(#"{"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "Root", "children": [1]}, {"name": "Body", "translation": [0, 1, 0]}]}"#.utf8)
            .write(to: assets.project.url(forAssetPath: "Models/rig.gltf"))
        assets.refresh()

        let bones = try call(session, "animGraph.bones", ["model": "Models/rig.gltf", "clip": "Models/hero.gltf#animation/Walk"])
        #expect(bones["matched"] as? [String: String] == ["Body": "Body"])
        #expect(bones["unmatchedModelBones"] as? [String] == ["Root"] && bones["needsRetarget"] as? Bool == true)
        #expect(bones["modelBones"] as? [String] == ["Root", "Body"] && bones["clipBones"] as? [String] == ["Body"])

        try call(session, "animGraph.new", ["name": "Rig", "preview": "Models/rig.gltf"])
        try call(session, "animGraph.edit", ["path": "Rig.animgraph", "retarget": ["boneMap": ["Body": "Root"], "translation": "none"]])
        var graph = try #require(try call(session, "animGraph.get", ["path": "Rig.animgraph"])["graph"] as? [String: Any])
        let retarget = try #require(graph["retarget"] as? [String: Any])
        #expect(retarget["boneMap"] as? [String: String] == ["Body": "Root"] && retarget["translation"] as? String == "none")
        // The graph's options apply: the map wins over the matching name.
        let mapped = try call(session, "animGraph.bones", ["path": "Rig.animgraph", "clip": "Models/hero.gltf#animation/Walk"])
        #expect(mapped["matched"] as? [String: String] == ["Root": "Body"])
        try call(session, "animGraph.edit", ["path": "Rig.animgraph", "removeRetarget": true])
        graph = try #require(try call(session, "animGraph.get", ["path": "Rig.animgraph"])["graph"] as? [String: Any])
        #expect(graph["retarget"] == nil)
        session.performUndo()
        let id = try #require(assets.id(forPath: "Rig.animgraph"))
        #expect(session.assets?.animationGraph(of: id)?.retarget != nil)
        // The tab lays out its Retarget section with the bone map.
        let form = try #require(AnimationGraphView(session: session, asset: id))
        #expect(form.graph.retarget?.boneMap == ["Body": "Root"])
        #expect(throws: (any Error).self) { try call(session, "animGraph.bones", ["clip": "Models/hero.gltf#animation/Walk"]) }  // no model
    }
}
