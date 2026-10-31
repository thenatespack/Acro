import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Scene and entity tools: the same edits through the UI (hierarchy and inspector panels) and
// through MCP tool calls give the same scene, undo / redo restore it exactly, queries return
// what the panels show, world-space and element field paths, and batches as one undo step that
// rolls back on failure.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

@MainActor private func id(_ name: String, _ session: EditorSession) -> EntityID {
    var found: Entity?
    session.world.query(Name.self) { entity, n in if n.value == name { found = entity } }
    return session.world.id(of: found!)!
}

/// An editor MCP server with an initialized in-memory client.
@MainActor private struct Client {
    let session: EditorSession
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init(session: EditorSession = makeSession()) {
        self.session = session
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = call("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:]])
    }

    @discardableResult
    func call(_ method: String, _ params: JSON? = nil) -> JSON {
        var message: JSON = ["jsonrpc": "2.0", "id": .string(UUID().uuidString), "method": .string(method)]
        if let params { message["params"] = params }
        connection.send(message)
        mcp.pump()
        let id = message["id"]
        let reply = connection.output.take().first { $0["id"] == id } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
    }

    /// Calls a tool and returns its structured result, failing the test on a tool error.
    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)",
                sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    func failingTool(_ name: String, _ arguments: JSON = [:]) -> String {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == true, "\(name) should fail")
        return result["content"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }

    func resource(_ uri: String) -> String {
        call("resources/read", ["uri": .string(uri)])["contents"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }
}

/// The scene file without entity ids (`uid`), which differ between sessions; references
/// between entities are by position in the file, so they stay.
@MainActor private func sceneWithoutIDs(_ world: World) throws -> JSON {
    func strip(_ json: JSON) -> JSON {
        switch json {
        case .object(var members):
            members["uid"] = nil
            return .object(members.mapValues(strip))
        case .array(let items): return .array(items.map(strip))
        default: return json
        }
    }
    return strip(try JSON(data: world.save()))
}

@MainActor private func undoAll(_ session: EditorSession) {
    while session.commands.isAvailable(EditUndoCommand.self) { session.run(EditUndoCommand.self) }
}

@MainActor private func redoAll(_ session: EditorSession) {
    while session.commands.isAvailable(EditRedoCommand.self) { session.run(EditRedoCommand.self) }
}

@MainActor @Suite struct SceneToolsTests {
    // MARK: UI and MCP give the same scene

    /// The hierarchy and inspector panels in a UI context, as the editor builds them.
    @MainActor private final class Panels {
        let ui = UIContext()
        let hierarchy: HierarchyPanel
        let inspector: InspectorPanel

        init(session: EditorSession) {
            hierarchy = HierarchyPanel(session: session)
            inspector = InspectorPanel(session: session)
            ui.root.addChildren([hierarchy.view, inspector.view])
            hierarchy.spawnPosition = { Vec3(1, 0.5, 2) }
        }

        func button(_ name: String, in view: Widget) -> Button { view.descendant(named: name) as! Button }

        /// Opens a popup menu with `button` and picks `item`.
        func choose(_ item: String, from button: Button) {
            button.action?()
            let menu = ui.overlays.last as! PopupMenu
            menu.onSelect?(menu.items.firstIndex(of: item)!)
            ui.dismissOverlay(menu)
        }

        /// An inspector gesture from `old` to `new` (a drag: began, a live change, ended).
        func edit(_ entity: Entity, _ component: String, _ path: String, from old: FieldValue, to new: FieldValue) {
            for (phase, value) in [(PropertyEditPhase.began, old), (.changed, new), (.ended, new)] {
                inspector.recorder.handle(PropertyEdit(entity: entity, componentName: component, path: path, oldValue: old,
                                                       newValue: value, phase: phase))
            }
        }
    }

    @Test func uiAndMCPEditsGiveTheSameSceneAndUndoRedoRestoreIt() throws {
        // Through the panels.
        let ui = makeSession()
        let initial = try ui.world.save()
        let panels = Panels(session: ui)
        panels.choose("Cube", from: panels.button("create", in: panels.hierarchy.view))
        let crate = try #require(ui.selection.primary)
        panels.hierarchy.sync()
        #expect(panels.hierarchy.tree.onRename?(panels.hierarchy.node(for: crate)!, "Crate") == true)
        #expect(panels.hierarchy.tree.onMove?([panels.hierarchy.node(for: crate)!], panels.hierarchy.node(for: id("Spinner", ui)), 1) == true)
        let crateEntity = ui.world.entity(for: crate)!
        panels.inspector.refresh()
        let start = ui.world.get(Transform.self, for: crateEntity)!.position
        panels.edit(crateEntity, "Transform", "position", from: .vec3(start), to: .vec3(Vec3(0.5, 1, -1)))
        panels.choose("Spin", from: panels.button("addComponent", in: panels.inspector.view))
        panels.edit(crateEntity, "Spin", "speed", from: .float(1), to: .float(2.5))
        panels.inspector.grid.onRemoveComponent?(crateEntity, "MeshRenderer")
        ui.selection.set([crate])
        panels.button("duplicate", in: panels.hierarchy.view).action?()
        let copy = try #require(ui.selection.primary)
        #expect(copy != crate)
        panels.button("delete", in: panels.hierarchy.view).action?()  // no confirmation without the app
        #expect(ui.world.entity(for: copy) == nil)
        panels.hierarchy.sync()
        let uiEdited = try ui.world.save()

        // The same through MCP tools.
        let client = Client()
        let mcp = client.session
        let mcpInitial = try mcp.world.save()
        let created = client.tool("entity.create", ["template": "cube", "position": [1, 0.5, 2]])
        let mcpCrate = try #require(created["entity"]?.stringValue)
        client.tool("entity.rename", ["entity": .string(mcpCrate), "name": "Crate"])
        client.tool("entity.reparent", ["entities": [.string(mcpCrate)], "parent": .string(id("Spinner", mcp).description), "index": 1])
        client.tool("component.setField", ["entity": .string(mcpCrate), "component": "Transform", "path": "position",
                                           "value": [0.5, 1, -1]])
        client.tool("component.add", ["entity": .string(mcpCrate), "component": "Spin"])
        client.tool("component.setField", ["entity": .string(mcpCrate), "path": "Spin.speed", "value": 2.5])
        client.tool("component.remove", ["entity": .string(mcpCrate), "component": "MeshRenderer"])
        let copies = client.tool("entity.duplicate", ["entities": [.string(mcpCrate)]])
        let mcpCopy = try #require(copies["entities"]?.arrayValue?.first)
        client.tool("entity.delete", ["entities": [mcpCopy]])

        #expect(try sceneWithoutIDs(ui.world) == sceneWithoutIDs(mcp.world))
        #expect(ui.undo.undoHistory.map { "AI: " + $0 } == mcp.undo.undoHistory)  // the same steps, labeled as the AI's
        #expect(ui.undo.undoDepth == 9)

        // Undo takes both back to the starter scene exactly; redo brings the edits back exactly.
        let mcpEdited = try mcp.world.save()
        undoAll(ui)
        #expect(try ui.world.save() == initial)
        redoAll(ui)
        #expect(try ui.world.save() == uiEdited)
        undoAll(mcp)
        #expect(try mcp.world.save() == mcpInitial)
        redoAll(mcp)
        #expect(try mcp.world.save() == mcpEdited)
    }

    // MARK: Queries

    @Test func hierarchyFindAndGetMatchThePanels() throws {
        let client = Client()
        let session = client.session
        let tree = client.tool("scene.hierarchy")["entities"]?.arrayValue ?? []
        #expect(tree.compactMap { $0["name"]?.stringValue } == session.world.roots.map(session.displayName(of:)))
        let spinner = try #require(tree.first { $0["name"] == "Spinner" })
        #expect(spinner["children"]?.arrayValue?.compactMap { $0["name"]?.stringValue } == ["Hub", "Arm A", "Arm B"])
        #expect(spinner["components"]?.arrayValue?.contains("Spin") == true)

        let shallow = client.tool("scene.hierarchy", ["root": .string(id("Spinner", session).description), "depth": 0])
        #expect(shallow["entities"]?[0]?["children"] == [])
        #expect(shallow["entities"]?[0]?["more"] == 3)

        let arms = client.tool("entity.find", ["name": "arm"])["entities"]?.arrayValue ?? []
        #expect(arms.compactMap { $0["path"]?.stringValue } == ["Spinner/Arm A", "Spinner/Arm B"])
        let cameras = client.tool("entity.find", ["component": "Camera"])["entities"]?.arrayValue ?? []
        #expect(cameras.compactMap { $0["name"]?.stringValue } == ["Main Camera"])
        let hub = id("Hub", session).description
        let byID = client.tool("entity.find", ["id": .string(String(hub.prefix(8)))])["entities"]?.arrayValue ?? []
        #expect(byID.first?["id"]?.stringValue == hub)
        #expect(client.tool("entity.find", ["name": "Arm", "exact": true])["entities"] == [])

        let arm = client.tool("entity.get", ["entity": .string(id("Arm A", session).description)])
        #expect(arm["name"] == "Arm A")
        #expect(arm["parent"]?.stringValue == id("Spinner", session).description)
        #expect(arm["components"]?["Transform"]?["position"]?[0]?.doubleValue.map { abs($0 - 1.1) < 1e-5 } == true)
        let worldX = try #require(arm["world"]?["position"]?[0]?.doubleValue)
        #expect(abs(worldX - 3.6) < 1e-4)  // Spinner at x 2.5, the arm 1.1 further.
        #expect(arm["components"]?["MeshRenderer"]?["mesh"] != nil)
        #expect(client.failingTool("entity.get", ["entity": "00000000000000000000000000000001"]).contains("No entity"))

        // The same as the resource.
        let resource = try JSON(parsing: client.resource("editor://entity/\(id("Arm A", session).description)"))
        #expect(resource == arm)
    }

    @Test func componentTypesListFieldsAndSchemas() throws {
        let client = Client()
        let types = client.tool("component.types")["components"]?.arrayValue ?? []
        let names = types.compactMap { $0["name"]?.stringValue }
        #expect(names.contains("Transform") && names.contains("MeshRenderer") && names.contains("Spin"))
        #expect(!names.contains("GlobalTransform"))
        let transform = try #require(types.first { $0["name"] == "Transform" })
        #expect(transform["addable"] == true)
        let position = transform["fields"]?.arrayValue?.first { $0["path"] == "position" }
        #expect(position?["kind"] == "vec3")
        #expect(position?["defaultValue"] == [0, 0, 0])
        #expect(transform["schema"]?["properties"]?["position"] != nil)
        let spin = try #require(client.tool("component.types", ["component": "Spin"])["components"]?[0])
        #expect(spin["fields"]?.arrayValue?.first { $0["path"] == "speed" }?["tooltip"] == "Radians per second")
        #expect(client.failingTool("component.types", ["component": "Nope"]).contains("Unknown component"))
    }

    @Test func selectionGetAndSceneFileResource() throws {
        let client = Client()
        let session = client.session
        let hub = id("Hub", session), arm = id("Arm A", session)
        client.tool("selection.set", ["entities": [.string(hub.description), .string(arm.description)], "primary": .string(hub.description)])
        let selection = client.tool("selection.get")
        #expect(selection["entities"] == [.string(hub.description), .string(arm.description)])
        #expect(selection["primary"]?.stringValue == hub.description)
        #expect(client.resource("editor://scene/file") == String(decoding: try session.world.save(), as: UTF8.self))
    }

    // MARK: Field paths and world space

    @Test func elementPathsAndWorldSpace() throws {
        let client = Client()
        let session = client.session
        let arm = id("Arm A", session)
        let entity = session.world.entity(for: arm)!
        // One element, the component in the path.
        client.tool("component.setField", ["entity": .string(arm.description), "path": "Transform.position.y", "value": 2])
        #expect(session.world.get(Transform.self, for: entity)?.position == Vec3(1.1, 2, 0))
        #expect(session.undo.undoLabel == "AI: Edit position")  // steps an MCP client made say so

        // World space under a rotated, scaled parent.
        let spinner = session.world.entity(for: id("Spinner", session))!
        session.world.modify(Transform.self, for: spinner) {
            $0.rotation = Quat(angle: .pi / 3, axis: Vec3(0, 1, 0))
            $0.scale = Vec3(repeating: 2)
        }
        session.world.propagateTransforms()
        client.tool("component.setField", ["entity": .string(arm.description), "component": "Transform", "path": "position",
                                           "value": [4, 3, -2], "space": "world"])
        session.world.propagateTransforms()
        let world = session.world.worldMatrix(of: entity).translation
        #expect(length(world - Vec3(4, 3, -2)) < 1e-4)
        client.tool("component.setField", ["entity": .string(arm.description), "path": "Transform.position.x", "value": 1, "space": "world"])
        session.world.propagateTransforms()
        #expect(length(session.world.worldMatrix(of: entity).translation - Vec3(1, 3, -2)) < 1e-4)
        let rotation = Quat(angle: .pi / 4, axis: Vec3(1, 0, 0))
        client.tool("component.setField", ["entity": .string(arm.description), "path": "Transform.rotation",
                                           "value": .array([rotation.vector.x, rotation.vector.y, rotation.vector.z, rotation.vector.w]
                                               .map { JSON.double(Double($0)) }), "space": "world"])
        let decomposed = Transform(matrix: session.world.worldMatrix(of: entity)).rotation
        #expect(abs(abs((decomposed.vector * rotation.vector).sum()) - 1) < 1e-4)

        #expect(client.failingTool("component.setField", ["entity": .string(arm.description), "component": "MeshRenderer",
                                                          "path": "tint", "value": [1, 0, 0], "space": "world"]).contains("World space"))
        #expect(client.failingTool("component.setField", ["entity": .string(arm.description), "path": "position", "value": 1])
            .contains("component"))
    }

    // MARK: Batches

    @Test func batchIsOneUndoStepAndUsesEarlierResults() throws {
        let client = Client()
        let session = client.session
        let before = try session.world.save()
        let depth = session.undo.undoDepth
        let result = client.tool("edit.batch", ["label": "Build a table", "calls": [
            ["command": "entity.create", "arguments": ["template": "cube", "position": [0, 1, 0], "name": "Top"]],
            ["command": "entity.create", "arguments": ["template": "cube", "name": "Leg", "parent": "$0.entity"]],
            ["command": "component.setField", "arguments": ["entity": "$1.entity", "path": "Transform.scale", "value": [0.1, 1, 0.1]]],
            ["command": "entity.find", "arguments": ["name": "Leg"]],
        ]])
        let leg = try #require(result["results"]?[1]?["entity"]?.stringValue)
        #expect(result["results"]?[3]?["entities"]?[0]?["path"] == "Top/Leg")
        #expect(session.undo.undoDepth == depth + 1)
        #expect(session.undo.undoLabel == "AI: Build a table")
        #expect(session.world.get(Transform.self, for: session.world.entity(for: EntityID(leg)!)!)?.scale == Vec3(0.1, 1, 0.1))
        let after = try session.world.save()
        client.tool("edit.undo")
        #expect(try session.world.save() == before)
        client.tool("edit.redo")
        #expect(try session.world.save() == after)
    }

    @Test func failingBatchRollsBackEverything() throws {
        let client = Client()
        let session = client.session
        let hub = id("Hub", session)
        session.selection.set([hub])
        let before = try session.world.save()
        let depth = session.undo.undoDepth
        let message = client.failingTool("edit.batch", ["label": "Oops", "calls": [
            ["command": "entity.create", "arguments": ["template": "sphere"]],
            ["command": "entity.rename", "arguments": ["entity": .string(hub.description), "name": "Renamed"]],
            ["command": "component.setField", "arguments": ["entity": "$0.entity", "path": "Transform.nothing", "value": 1]],
        ]])
        #expect(message.contains("call 2 (component.setField) failed"))
        #expect(message.contains("No field"))
        #expect(try session.world.save() == before)
        #expect(session.undo.undoDepth == depth)
        #expect(session.selection.ids == [hub])
        #expect(!session.undo.isGrouping)
        // A reference to a call that hasn't run.
        #expect(client.failingTool("edit.batch", ["label": "Ahead", "calls": [
            ["command": "entity.rename", "arguments": ["entity": "$1.entity", "name": "x"]],
        ]]).contains("hasn't run yet"))
    }

    @Test func beginAndEndBatchAcrossCalls() throws {
        let client = Client()
        let session = client.session
        let before = try session.world.save()
        let depth = session.undo.undoDepth
        client.tool("edit.beginBatch", ["label": "Arrange"])
        #expect(client.failingTool("edit.beginBatch", ["label": "Again"]).contains("already open"))
        let cube = client.tool("entity.create", ["template": "cube"])["entity"]!
        client.tool("component.setField", ["entity": cube, "path": "Transform.position.x", "value": 3])
        #expect(client.failingTool("edit.undo").contains("a batch is open"))
        #expect(client.tool("edit.endBatch") == ["label": "Arrange", "recorded": true])
        #expect(session.undo.undoDepth == depth + 1 && session.undo.undoLabel == "AI: Arrange")
        client.tool("edit.undo")
        #expect(try session.world.save() == before)

        // Cancelled: nothing stays.
        client.tool("edit.beginBatch", ["label": "Try"])
        client.tool("entity.create", ["template": "plane"])
        #expect(client.tool("edit.endBatch", ["cancel": true])["recorded"] == false)
        #expect(try session.world.save() == before)
        #expect(client.failingTool("edit.endBatch").contains("no batch is open"))
    }

    @Test func duplicateDeleteAndFrameTakeEntities() throws {
        let client = Client()
        let session = client.session
        let hub = id("Hub", session)
        #expect(session.selection.isEmpty)
        // The UI's enabled state still follows the selection.
        #expect(!session.commands.isAvailable(EntityDuplicateCommand.id))
        let copies = client.tool("entity.duplicate", ["entities": [.string(hub.description)]])["entities"]?.arrayValue ?? []
        #expect(copies.count == 1)
        #expect(client.tool("entity.delete", ["entities": .array(copies)]) == ["count": 1])
        #expect(client.failingTool("entity.delete").contains("nothing is selected"))
        #expect(client.failingTool("view.frameSelection", ["entities": [.string(hub.description)]]).contains("editor window"))
        let named = client.tool("entity.create", ["template": "empty", "name": "Marker", "parent": .string(hub.description)])
        let marker = session.world.entity(for: EntityID(named["entity"]!.stringValue!)!)!
        #expect(session.world.parent(of: marker) == session.world.entity(for: hub))
        #expect(session.displayName(of: marker) == "Marker")
    }
}

extension JSON {
    /// Element `index` of an array.
    fileprivate subscript(index: Int) -> JSON? {
        guard let items = arrayValue, items.indices.contains(index) else { return nil }
        return items[index]
    }
}
