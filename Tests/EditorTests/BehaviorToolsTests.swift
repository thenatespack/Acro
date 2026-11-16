import Foundation
import Testing
@testable import EditorCore
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Behavior trees as an agent uses them (behavior.* tools, JSON in and out) and as a user does
// (the Behavior Tree tab), including running one in play mode.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("BehaviorToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct BehaviorToolsTests {
    @MainActor private func project(_ folder: URL) throws -> EditorSession {
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return session
    }

    @Test func newEditGetAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)

        let created = try call(session, "behavior.new", ["preset": "patrol", "folder": "AI"])
        #expect(created["path"] as? String == "AI/Patrol.behavior")
        #expect(created["warnings"] as? [String] == [])
        #expect(created["outline"] as? [String] == ["sequence root", "  patrol patrol"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isBehaviorFile(id))

        let edited = try call(session, "behavior.edit", [
            "path": "AI/Patrol.behavior",
            "addNodes": [["id": "low", "type": "healthBelow", "value": 20], ["id": "run", "type": "flee", "safeDistance": 9],
                         ["id": "escape", "type": "sequence", "children": ["low", "run"]],
                         ["id": "bad", "type": "wait", "seconds": "later"]],
            "updateNodes": ["root": ["type": "selector"]],
            "connect": [["parent": "root", "child": "escape", "index": 0], ["parent": "root", "child": "bad"]],
            "blackboard": ["health": 100],
        ])
        #expect(edited["outline"] as? [String] == ["selector root", "  sequence escape", "    healthBelow low", "    flee run",
                                                   "  patrol patrol", "  wait bad"])
        #expect((edited["warnings"] as? [String])?.contains { $0.contains("node 'bad': seconds: expected a number") } == true)
        let tree = try #require(session.assets?.behaviorTreeContents(of: id))
        #expect(tree.node("run")?.params["safeDistance"] == .int(9))
        #expect(tree.blackboard["health"] == .int(100))

        #expect(throws: (any Error).self) { try call(session, "behavior.edit", ["asset": id.description, "removeNodes": ["ghost"]]) }
        #expect(throws: (any Error).self) {
            try call(session, "behavior.edit", ["asset": id.description, "connect": [["parent": "low", "child": "root"]]])
        }

        let got = try call(session, "behavior.get", ["asset": id.description])
        #expect(((got["tree"] as? [String: Any])?["nodes"] as? [Any])?.count == 6)

        #expect(session.performUndo())
        #expect(session.assets?.behaviorTreeContents(of: id) == BehaviorTree.preset(.patrol))

        let set = try call(session, "behavior.set", ["asset": id.description, "tree": ["nodes": [["id": "w", "type": "wait"]]]])
        #expect(set["root"] as? String == "w" && set["nodeCount"] as? Int == 1)
        let reset = try call(session, "behavior.edit", ["asset": id.description, "preset": "coward"])
        #expect(reset["nodeCount"] as? Int == BehaviorTree.preset(.coward).nodes.count)
        #expect(throws: (any Error).self) { try call(session, "behavior.get", ["path": "Missing.behavior"]) }
    }

    @Test func assignPlayAndDebug() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let created = try call(session, "behavior.new", ["name": "mover"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        try call(session, "behavior.set", ["asset": id.description, "tree": [
            "speed": 5,
            "nodes": [["id": "root", "type": "sequence", "children": ["go", "flag"]],
                      ["id": "go", "type": "moveTo", "position": [3, 0, 0], "arriveDistance": 0.02],
                      ["id": "flag", "type": "setBlackboard", "key": "arrived", "value": true]],
        ]])
        let npc = try #require((try call(session, "entity.create", ["template": "empty", "name": "NPC"])["entity"] as? String).flatMap { EntityID($0) })
        let target = try #require((try call(session, "entity.create", ["template": "empty", "name": "Hero"])["entity"] as? String).flatMap { EntityID($0) })
        try call(session, "behavior.assign", ["entity": npc.description, "asset": id.description, "target": target.description,
                                              "blackboard": ["mood": "calm"]])
        let entity = try session.world.require(npc)
        let runner = try #require(session.world.get(BehaviorTreeRunner.self, for: entity))
        #expect(runner.tree == AssetReference(id).description && runner.target == EntityRef(target))
        #expect(runner.blackboard == [BehaviorBlackboardEntry(key: "mood", value: "calm")])
        #expect(session.performUndo())
        #expect(!session.world.has(BehaviorTreeRunner.self, for: entity))
        #expect(session.performRedo())

        session.play()
        for _ in 0..<60 { session.tick(dt: 1.0 / 60) }
        let playing = try session.world.require(npc)
        #expect(abs((session.world.get(Transform.self, for: playing)?.position.x ?? 0) - 3) < 0.05)
        let debug = try call(session, "behavior.debug", [:])
        #expect(debug["entity"] as? String == npc.description)
        #expect(debug["playing"] as? Bool == true)
        #expect((debug["blackboard"] as? [String: String])?["arrived"] == "true")
        #expect((debug["blackboard"] as? [String: String])?["mood"] == "calm")
        #expect((debug["nodes"] as? [String: String])?["go"] != nil)
        session.stop()
        #expect(abs(session.world.get(Transform.self, for: try session.world.require(npc))?.position.x ?? 1) < 1e-4, "stop restores the scene")
        #expect(!session.world.systemNames(in: .update).contains(EditorSession.behaviorSystem))
    }

    @Test func workspaceEditsAndHighlightsWhilePlaying() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let id = try #require(session.createBehaviorAsset(in: "", name: "brain", tree: .preset(.empty)))

        let workspace = BehaviorTreeWorkspace(session: session)
        var opened: AssetID?
        session.onOpenBehavior = { opened = $0; workspace.open($0) }
        try call(session, "behavior.open", ["asset": id.description])
        #expect(opened == id && session.openBehavior == id && workspace.asset == id)
        workspace.update()
        #expect(workspace.selectedNode == "root")

        workspace.addNode(.patrol)
        #expect(workspace.hasPendingEdit)
        workspace.update()
        #expect(workspace.selectedNode == "patrol")
        #expect(session.assets?.behaviorTreeContents(of: id)?.node("root")?.children == ["idle", "patrol"])

        workspace.setParam("points", text: "[[0, 0, 0], [2, 0, 0]]")
        workspace.update()
        #expect(workspace.tree.node("patrol")?.params["points"] == .array([.array([.int(0), .int(0), .int(0)]), .array([.int(2), .int(0), .int(0)])]))
        workspace.setParam("wait", text: "0.5")
        workspace.update()
        #expect(workspace.tree.node("patrol")?.params["wait"] == .double(0.5))
        workspace.moveSelected(by: -1)
        workspace.update()
        #expect(workspace.tree.node("root")?.children == ["patrol", "idle"])
        workspace.renameSelected(to: "walk")
        workspace.update()
        #expect(workspace.selectedNode == "walk" && workspace.tree.node("root")?.children == ["walk", "idle"])
        workspace.setBlackboard("health", text: "75")
        workspace.update()
        #expect(workspace.tree.blackboard["health"] == .int(75))
        workspace.setType(.wait)
        workspace.update()
        #expect(workspace.tree.node("walk")?.type == "wait" && workspace.tree.node("walk")?.params.isEmpty == true)

        // Each edit was one undo step; the workspace follows undo.
        #expect(session.performUndo())
        workspace.update()
        #expect(workspace.tree.node("walk")?.type == "patrol")

        workspace.select("idle")
        workspace.deleteSelected()
        workspace.update()
        #expect(workspace.tree.node("idle") == nil && workspace.selectedNode == "root")

        // While playing, the debugged entity's statuses tint the canvas nodes.
        let npc = try #require(session.create(.empty, name: "Walker"))
        try call(session, "behavior.assign", ["entity": npc.description, "asset": id.description])
        session.play()
        session.tick(dt: 1.0 / 60)
        workspace.update()
        let entity = try session.world.require(npc)
        #expect(workspace.debugEntity == entity)
        #expect(workspace.shownStatuses["root"] == .running)
        #expect(workspace.shownStatuses["walk"] == .running)
        #expect(workspace.canvas.statuses["walk"] == .running)
        session.stop()
        workspace.update()
        #expect(workspace.debugEntity == nil && workspace.shownStatuses.isEmpty)

        workspace.applyPreset(.guardian)
        workspace.update()
        #expect(workspace.tree == BehaviorTree.preset(.guardian))
        workspace.close()
        #expect(workspace.asset == nil)
    }

    @Test func canvasLaysOutTheTreeAndDragsNodes() throws {
        // Layout: parents centered over their children, children left to right, loose nodes to the right.
        var tree = BehaviorTree.preset(.guardian)
        let layout = BehaviorTreeLayout(tree)
        let p = layout.positions
        #expect(p.count == tree.nodes.count && layout.loose.isEmpty && layout.looseStartX == nil)
        #expect(p["root"]!.y == 0 && p["retreat"]!.y == BehaviorTreeLayout.rowHeight && p["hurt"]!.y == 2 * BehaviorTreeLayout.rowHeight)
        #expect(p["retreat"]!.x < p["fight"]!.x && p["fight"]!.x < p["patrol"]!.x)
        #expect(p["see"]!.x < p["chase"]!.x && p["chase"]!.x < p["attack"]!.x)
        #expect(p["fight"]!.x == p["chase"]!.x)  // centered over its three children
        #expect(layout.edges.count == tree.nodes.count - 1)
        tree.nodes.append(BehaviorNode("stray", .wait))
        let withStray = BehaviorTreeLayout(tree)
        #expect(withStray.loose == ["stray"] && withStray.positions["stray"]!.x >= withStray.looseStartX!)

        // Drop targets: middle of a composite → child; edges → before / after; never into its own subtree.
        let canvas = BehaviorTreeCanvas()
        canvas.frame = UIRect(x: 0, y: 0, width: 1200, height: 600)
        canvas.tree = .preset(.guardian)
        canvas.pan = .zero
        func point(_ id: String, _ fx: Float) -> Vec2 {
            let r = canvas.rect(of: id)!
            return Vec2(r.x + r.width * fx, r.y + r.height / 2)
        }
        #expect(canvas.node(at: point("chase", 0.5)) == "chase")
        #expect(canvas.dropTarget(for: "patrol", at: point("retreat", 0.5)) == .child(of: "retreat"))
        #expect(canvas.dropTarget(for: "patrol", at: point("retreat", 0.1)) == .before("retreat"))
        #expect(canvas.dropTarget(for: "attack", at: point("see", 0.9)) == .after("see"))
        #expect(canvas.dropTarget(for: "attack", at: point("see", 0.3)) == .before("see"))
        #expect(canvas.dropTarget(for: "fight", at: point("chase", 0.5)) == nil)  // its own child
        #expect(canvas.dropTarget(for: "root", at: point("hurt", 0.5)) == nil)

        // Dragging with the pointer reports the drop; clicks select.
        var dropped: (String, BehaviorDropTarget)?
        var selected: String??
        canvas.onDrop = { dropped = ($0, $1) }
        canvas.onSelect = { selected = $0 }
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: point("patrol", 0.5))))
        #expect(selected == "patrol")
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: point("patrol", 0.5) + Vec2(-20, 10))))
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: point("retreat", 0.5))))
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: point("retreat", 0.5))))
        #expect(dropped?.0 == "patrol" && dropped?.1 == .child(of: "retreat"))
        // Dragging empty space pans.
        let before = canvas.pan
        _ = canvas.handleEvent(.pointerDown(PointerEvent(position: Vec2(1150, 580))))
        _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: Vec2(1100, 560))))
        _ = canvas.handleEvent(.pointerUp(PointerEvent(position: Vec2(1100, 560))))
        #expect(canvas.pan == before + Vec2(50, 20))

        // The workspace applies drops as undoable edits.
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let id = try #require(session.createBehaviorAsset(in: "", name: "guard", tree: .preset(.guardian)))
        let workspace = BehaviorTreeWorkspace(session: session)
        workspace.open(id)
        workspace.update()
        #expect(workspace.canvas.tree == .preset(.guardian))
        workspace.moveNode("patrol", to: .child(of: "retreat"))
        workspace.update()
        #expect(workspace.tree.node("retreat")?.children == ["hurt", "flee", "patrol"])
        #expect(workspace.tree.node("root")?.children == ["retreat", "fight"])
        #expect(workspace.selectedNode == "patrol" && workspace.canvas.selected == "patrol")
        workspace.moveNode("attack", to: .before("see"))
        workspace.update()
        #expect(workspace.tree.node("fight")?.children == ["attack", "see", "chase"])
        workspace.moveNode("attack", to: .after("chase"))
        workspace.update()
        #expect(workspace.tree.node("fight")?.children == ["see", "chase", "attack"])
        workspace.moveNode("root", to: .child(of: "fight"))  // a cycle: refused
        workspace.update()
        #expect(workspace.tree.rootID == "root")
        #expect(session.performUndo())
        workspace.update()
        #expect(workspace.tree.node("fight")?.children == ["attack", "see", "chase"])
        #expect(workspace.canvas.tree == workspace.tree)
        workspace.close()
    }
}
