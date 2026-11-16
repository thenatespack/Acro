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

// Visual scripts as an agent uses them (vscript.* tools, JSON in and out), in play mode, and in the Visual Script tab.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("VisualScriptToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct VisualScriptToolsTests {
    @MainActor private func project(_ folder: URL) throws -> EditorSession {
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        return session
    }

    @Test func newAttachPlayAndHotEdit() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let cube = try #require(session.create(.cube))

        let created = try call(session, "vscript.new", ["name": "spin", "folder": "Scripts", "template": "spinner", "target": cube.description])
        #expect(created["path"] as? String == "Scripts/spin.vscript")
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        let asset = try #require(created["asset"] as? String)
        let entity = try #require(session.world.entity(for: cube))
        let component = try #require(session.world.get(VisualScript.self, for: entity))
        #expect(component.graph == "asset:" + asset)
        #expect(component.variables["speed"] == .int(90))

        session.play(paused: true)
        session.step(frames: 30, dt: 1.0 / 30)  // one second at 90°/s
        let yaw = session.world.get(Transform.self, for: entity)!.rotation.eulerDegrees.y
        #expect(abs(yaw - 90) < 1)

        // Change the speed variable's use while playing: multiply by 2 more.
        try call(session, "vscript.edit", ["path": "Scripts/spin.vscript",
                                           "addNodes": [["id": "twice", "type": "math.multiply", "inputs": ["b": 0]]],
                                           "updateNodes": [["id": "twice", "inputs": ["b": 0]]],
                                           "connect": [["from": "mul.result", "to": "twice.a"], ["from": "twice.result", "to": "rotate.degrees"]]])
        session.step(frames: 30, dt: 1.0 / 30)
        let after = session.world.get(Transform.self, for: entity)!.rotation.eulerDegrees.y
        #expect(abs(after - yaw) < 1, "multiplied by 0 now: no more turning")
        session.stop()
        #expect(session.visualScriptRuntime == nil)
        #expect(!session.world.systemNames(in: .update).contains("vscript.update"))
    }

    @Test func editValidateNodesAndUndo() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let created = try call(session, "vscript.new", ["name": "logic"])
        let path = try #require(created["path"] as? String)

        let edited = try call(session, "vscript.edit", [
            "path": path,
            "variables": [["name": "count", "type": "int", "default": 0]],
            "addNodes": [["type": "flow.branch"], ["type": "debug.log", "inputs": ["message": "big"]],
                         ["id": "count", "type": "var.get", "config": ["variable": "count"]], ["id": "gt", "type": "compare.greater", "inputs": ["b": 3]]],
            "connect": [["from": "update.out", "to": "branch1.in"], ["from": "branch1.true", "to": "log1.in"],
                        ["from": "count.value", "to": "gt.a"], ["from": "gt.result", "to": "branch1.condition"]],
        ])
        #expect(edited["added"] as? [String] == ["branch1", "log1", "count", "gt"])
        #expect((edited["warnings"] as? [String])?.isEmpty == true, "\(edited["warnings"] ?? "")")

        // A bad wire is reported.
        let bad = try call(session, "vscript.edit", ["path": path, "connect": [["from": "start.out", "to": "gt.a"]]])
        #expect((bad["warnings"] as? [String])?.contains { $0.contains("exec pin to a data pin") } == true)
        let validation = try call(session, "vscript.validate", ["path": path])
        #expect(validation["valid"] as? Bool == false)
        try session.undo.undo()
        let fixed = try call(session, "vscript.validate", ["path": path])
        #expect(fixed["valid"] as? Bool == true)

        let got = try call(session, "vscript.get", ["path": path])
        let graph = try #require(got["graph"] as? [String: Any])
        #expect((graph["nodes"] as? [[String: Any]])?.count == 6)

        let nodes = try call(session, "vscript.nodes", ["search": "branch"])
        #expect((nodes["nodes"] as? [[String: Any]])?.contains { $0["type"] as? String == "flow.branch" } == true)
        let lights = try call(session, "vscript.nodes", ["search": "PointLight intensity", "limit": 5])
        let entries = try #require(lights["nodes"] as? [[String: Any]])
        #expect(entries.contains { ($0["config"] as? [String: Any])?["field"] as? String == "intensity" && $0["type"] as? String == "component.set" })
        let vars = try call(session, "vscript.nodes", ["path": path, "search": "count"])
        #expect((vars["nodes"] as? [[String: Any]])?.contains { $0["title"] as? String == "Set count" } == true)
        let filtered = try call(session, "vscript.nodes", ["pinType": "entity", "search": "destroy"])
        #expect((filtered["nodes"] as? [[String: Any]])?.first?["type"] as? String == "world.destroy")
    }

    @Test func breakpointPausesPlay() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let id = try #require(session.create(.empty))
        let created = try call(session, "vscript.new", ["name": "tick", "template": "timer", "target": id.description])
        try call(session, "vscript.edit", ["asset": "asset:" + (created["asset"] as! String),
                                           "updateNodes": [["id": "log", "breakpoint": true]]])
        session.play()
        for _ in 0..<90 { session.tick(dt: 1.0 / 60) }
        #expect(session.isPaused)
        #expect(session.visualScriptRuntime?.lastBreak?.node == "log")
        session.stop()
    }

    @Test func stepThroughTheFlowAfterABreakpoint() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let id = try #require(session.create(.empty))
        let created = try call(session, "vscript.new", ["name": "steps", "target": id.description])
        let asset = "asset:" + (created["asset"] as! String)
        let graph: [String: Any] = [
            "variables": [["name": "n", "type": "int"], ["name": "ticks", "type": "int"]],
            "nodes": [["id": "start", "type": "event.start"],
                      ["id": "a", "type": "var.set", "config": ["variable": "n"], "inputs": ["value": 1], "breakpoint": true],
                      ["id": "call", "type": "function.call", "config": ["function": "twice"], "inputs": ["x": 4]],
                      ["id": "b", "type": "var.set", "config": ["variable": "n"]],
                      ["id": "tick", "type": "event.update"],
                      ["id": "count", "type": "var.set", "config": ["variable": "ticks"], "inputs": ["value": 7]]],
            "links": [["from": "start.out", "to": "a.in"], ["from": "a.out", "to": "call.in"], ["from": "call.out", "to": "b.in"],
                      ["from": "call.y", "to": "b.value"], ["from": "tick.out", "to": "count.in"]],
            "functions": [["name": "twice", "inputs": [["name": "x", "type": "int"]], "outputs": [["name": "y", "type": "int"]],
                           "nodes": [["id": "entry", "type": "function.entry"], ["id": "mul", "type": "math.multiply", "inputs": ["b": 2]],
                                     ["id": "ret", "type": "function.return"]],
                           "links": [["from": "entry.out", "to": "ret.in"], ["from": "entry.x", "to": "mul.a"], ["from": "mul.result", "to": "ret.y"]]]],
        ]
        try call(session, "vscript.set", ["asset": asset, "graph": graph])
        let workspace = VisualScriptWorkspace(session: session)
        #expect(workspace.open(try #require(AssetID(created["asset"] as! String))))
        workspace.update()

        #expect(throws: (any Error).self) { try call(session, "vscript.step", ["mode": "over"]) }
        session.play()
        session.tick(dt: 1.0 / 60)
        #expect(session.isPaused)
        var state = try call(session, "vscript.step")
        #expect(state["atBreakpoint"] as? Bool == true && state["count"] as? Int == 4)
        #expect((state["step"] as? [String: Any])?["node"] as? String == "a")
        workspace.update()
        #expect(workspace.canvas.pausedAt == "a")

        state = try call(session, "vscript.step", ["mode": "into"])
        #expect((state["step"] as? [String: Any])?["node"] as? String == "call")
        #expect((state["step"] as? [String: Any])?["outputs"] as? [String: String] == ["y": "8"])
        state = try call(session, "vscript.step", ["mode": "into"])
        #expect((state["step"] as? [String: Any])?["function"] as? String == "twice")
        workspace.update()
        #expect(workspace.function == "twice" && workspace.canvas.pausedAt == "ret", "the tab opens the function")
        state = try call(session, "vscript.step", ["mode": "out"])
        #expect((state["step"] as? [String: Any])?["node"] as? String == "b")
        workspace.update()
        #expect(workspace.function == nil && workspace.canvas.pausedAt == "b")

        // F10 past the end resumes; the next frame pauses at the update flow's first node.
        #expect(workspace.handleKey(KeyEvent(key: .f10)))
        #expect(!session.isPaused && session.visualScriptStep == nil)
        session.tick(dt: 1.0 / 60)
        #expect(session.isPaused)
        state = try call(session, "vscript.step")
        #expect((state["step"] as? [String: Any])?["node"] as? String == "count")
        state = try call(session, "vscript.step", ["mode": "continue"])
        #expect(state["paused"] as? Bool == false && state["atBreakpoint"] as? Bool == false)
        session.tick(dt: 1.0 / 60)
        #expect(!session.isPaused)
        session.stop()
    }

    @Test func workspaceEditsAreUndoSteps() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = try project(folder)
        let created = try call(session, "vscript.new", ["name": "tab"])
        let asset = try #require(AssetID(created["asset"] as! String))
        let workspace = VisualScriptWorkspace(session: session)
        #expect(workspace.open(asset))
        workspace.update()
        #expect(workspace.canvas.nodes.map(\.id).sorted() == ["start", "update"])

        // Drag a wire from start.out onto empty space, pick Log.
        workspace.canvas.onRequestAdd?(Vec2(300, 0), ("start.out", true, .exec))
        let added = try #require(workspace.addNode(type: "debug.log"))
        workspace.update()
        var graph = try #require(session.assets?.visualScript(of: asset))
        #expect(graph.links.contains(VisualScriptLink(from: "start.out", to: "\(added).in")))

        // Move it with the canvas; one undo step each.
        workspace.canvas.onMove?([added: Vec2(500, 80)])
        workspace.update()
        graph = try #require(session.assets?.visualScript(of: asset))
        #expect(graph.node(added)?.x == 500)
        try session.undo.undo()
        workspace.update()
        #expect(session.assets?.visualScript(of: asset)?.node(added)?.x == 300)
        try session.undo.undo()
        workspace.update()
        #expect(session.assets?.visualScript(of: asset)?.node(added) == nil)
        #expect(workspace.canvas.nodes.count == 2)

        // Copy / paste and collapse to a function.
        try session.undo.redo()
        workspace.update()
        workspace.canvas.onSelect?([added])
        _ = workspace.handleKey(KeyEvent(key: .c, modifiers: .command))
        _ = workspace.handleKey(KeyEvent(key: .v, modifiers: .command))
        workspace.update()
        #expect(session.assets?.visualScript(of: asset)?.nodes.count == 4)
        workspace.canvas.onSelect?([added])
        workspace.collapseSelection(name: "say")
        workspace.update()
        graph = try #require(session.assets?.visualScript(of: asset))
        #expect(graph.function("say")?.nodes.contains { $0.type == "debug.log" } == true)
        #expect(graph.nodes.contains { $0.type == "function.call" })
        #expect(VisualScriptValidator.validate(graph).filter { $0.severity == .error }.isEmpty)
    }
}
