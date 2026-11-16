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

// The Material Builder as an agent uses it (materialGraph.* tools, JSON in and out), including undo.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

private func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("MaterialGraphToolsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @discardableResult
private func call(_ session: EditorSession, _ command: CommandID, _ arguments: [String: Any] = [:]) throws -> [String: Any] {
    let data = try session.commands.run(command, json: JSONSerialization.data(withJSONObject: arguments))
    return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
}

@MainActor
@Suite struct MaterialGraphToolsTests {
    @Test func newEditUndoAndGet() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])

        let created = try call(session, "materialGraph.new", ["name": "Lava", "folder": "Materials", "preset": "lava"])
        #expect(created["path"] as? String == "Materials/Lava.material")
        #expect((created["warnings"] as? [String])?.isEmpty == true)
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        #expect(session.isMaterialFile(id))
        let lava = try #require(session.assets?.materialFile(of: id)?.graph)
        #expect(lava == MaterialGraph.preset("lava"))

        // Water drives opacity: the preset material blends.
        let water = try call(session, "materialGraph.new", ["name": "Water", "preset": "water"])
        #expect(water["alphaMode"] as? String == "blend")

        // Add, connect, set params and remove in one step.
        let edited = try call(session, "materialGraph.edit", [
            "path": "Materials/Lava.material",
            "addNodes": [["type": "fresnel", "power": 3], ["id": "rimColor", "type": "color", "value": [0, 0.5, 2, 1]]],
            "params": ["heat": ["scale": 9]],
            "connect": [["from": "fresnel", "to": "output.metallic"], ["from": 0.25, "to": "rough.a"]],
            "removeNodes": ["crust"],
        ])
        #expect(edited["added"] as? [String] == ["fresnel", "rimColor"])
        #expect((edited["warnings"] as? [String])?.isEmpty == true)
        let graph = try #require(session.assets?.materialFile(of: id)?.graph)
        #expect(graph.node("crust") == nil && graph.output["baseColor"] == nil, "removing a node resets links to it")
        #expect(graph.node("heat")?["scale"] == .int(9))
        #expect(graph.output["metallic"] == .string("fresnel"))
        #expect(graph.node("rough")?["a"] == .double(0.25))
        #expect(graph.node("fresnel")?.position != nil)

        // One undo step takes the whole edit back.
        #expect(session.performUndo())
        #expect(session.assets?.materialFile(of: id)?.graph == lava)
        #expect(session.performRedo())
        #expect(session.assets?.materialFile(of: id)?.graph == graph)

        // Problems come back as warnings; bad targets are errors.
        let broken = try call(session, "materialGraph.edit", ["path": "Materials/Lava.material", "params": ["heat": ["kind": "plaid"]]])
        #expect((broken["warnings"] as? [String])?.contains { $0.contains("unknown noise kind 'plaid'") } == true)
        #expect(throws: (any Error).self) {
            try call(session, "materialGraph.edit", ["path": "Materials/Lava.material", "output": ["emissive": "nothing.rgb"]])
        }
        #expect(throws: (any Error).self) {
            try call(session, "materialGraph.edit", ["path": "Materials/Lava.material", "connect": [["from": "nope", "to": "heat.uv"]]])
        }
        #expect(throws: (any Error).self) {
            try call(session, "materialGraph.edit", ["path": "Materials/Lava.material", "connect": [["from": "heat", "to": "heat.frobs"]]])
        }
        #expect(throws: (any Error).self) {
            try call(session, "materialGraph.edit", ["path": "Materials/Lava.material", "addNodes": [["type": "wobble"]]])
        }

        let fetched = try call(session, "materialGraph.get", ["asset": id.description, "code": true])
        #expect((fetched["code"] as? String)?.contains("gEmissive = ") == true)
        #expect(fetched["graph"] != nil)

        // set replaces the graph; clear removes it.
        try call(session, "materialGraph.set", ["path": "Materials/Lava.material", "preset": "stone"])
        #expect(session.assets?.materialFile(of: id)?.graph == MaterialGraph.preset("stone"))
        try call(session, "materialGraph.set", ["path": "Materials/Lava.material", "clear": true, "settings": ["doubleSided": true]])
        let cleared = try #require(session.assets?.materialFile(of: id))
        #expect(cleared.graph == nil && cleared.doubleSided)
        // The existing material.get still reads it.
        #expect(try call(session, "material.get", ["asset": AssetReference(id).description])["material"] != nil)
    }

    @Test func editAddsAGraphToAPlainMaterialAndNodesListsTypes() throws {
        var plain = MaterialAsset(baseColor: Vec4(1, 0, 0, 1), roughness: 0.3)
        plain.emissiveColor = Vec3(0, 1, 0)
        let converted = graphFromFixedFields(plain)
        #expect(converted.output["roughness"] == .double(Double(Float(0.3))))
        #expect(MaterialGraphCompiler.compile(converted).warnings.isEmpty)

        let (edited, added) = try MaterialGraphEditCommand.edited(plain, with: .init(addNodes: [MaterialGraphNode(id: "", type: "noise")],
                                                                                      output: ["roughness": .string("noise")]))
        #expect(added == ["noise"] && edited.graph?.output["roughness"] == .string("noise"))

        let session = makeSession()
        let nodes = try call(session, "materialGraph.nodes")
        let types = (nodes["nodes"] as? [[String: Any]])?.compactMap { $0["type"] as? String } ?? []
        #expect(types.contains("triplanar") && types.contains("noise") && types.contains("fresnel"))
        #expect((nodes["presets"] as? [String]) == MaterialGraph.presetNames)
    }

    @Test func assignSetsMeshRenderersAndOpenShowsTheTab() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "materialGraph.new", ["name": "Glow", "preset": "pulse"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })

        let parent = session.world.spawn(Transform(), Name("Model"), MeshRenderer(mesh: .cube))
        let child = session.world.spawn(Transform(), Name("Part"), MeshRenderer(mesh: .sphere))
        session.world.setParent(child, to: parent)
        let parentID = try #require(session.world.ensureID(of: parent))
        let result = try call(session, "materialGraph.assign", ["path": "Glow.material", "entity": parentID.description, "children": true])
        #expect((result["entities"] as? [Any])?.count == 2)
        let key = AssetReference(id, subAsset: "material").description
        #expect(session.world.get(MeshRenderer.self, for: child)?.material.key == key)
        #expect(session.performUndo())
        #expect(session.world.get(MeshRenderer.self, for: child)?.material.key == MaterialHandle.default.key)

        // A decal paints the graph (Decal.material); undo clears it again.
        let decal = session.world.spawn(Transform(), Name("Paint"), Decal())
        let decalID = try #require(session.world.ensureID(of: decal))
        let painted = try call(session, "materialGraph.assign", ["path": "Glow.material", "entity": decalID.description])
        #expect((painted["entities"] as? [Any])?.count == 1)
        #expect(session.world.get(Decal.self, for: decal)?.material?.key == key)
        #expect(session.performUndo())
        #expect(session.world.get(Decal.self, for: decal)?.material == nil)
        let bare = try #require(session.world.ensureID(of: session.world.spawn(Transform(), Name("Empty"))))
        #expect(throws: (any Error).self) { try call(session, "materialGraph.assign", ["path": "Glow.material", "entity": bare.description]) }
        // The inspector offers materials for it.
        let choices = AssetChoices(meshes: { [] }, materials: { ["checker"] }, textures: { [] })
        #expect(choices.options(component: Decal.componentName, path: "material") == ["", "checker"])

        var opened: AssetID?
        session.onOpenMaterialGraph = { opened = $0 }
        try call(session, "materialGraph.open", ["path": "Glow.material", "shape": "cube", "light": "rim"])
        #expect(opened == id && session.materialPreviewRequest?.shape == .cube && session.materialPreviewRequest?.light == .rim)
        #expect(throws: (any Error).self) { try call(session, "materialGraph.open", ["path": "Glow.material", "shape": "teapot"]) }

        // The workspace opens it and edits through the form as undo steps.
        let workspace = MaterialBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.applyRequest(from: session)
        #expect(workspace.shape == .cube && workspace.light == .rim)
        workspace.edit("Test Edit") { $0.graph?.output["roughness"] = .double(0.9) }
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(session.assets?.materialFile(of: id)?.graph?.output["roughness"] == .double(0.9))
        #expect(session.performUndo())
        #expect(session.assets?.materialFile(of: id)?.graph?.output["roughness"] == MaterialGraph.preset("pulse")?.output["roughness"])
    }

    /// Dragging links on the canvas: from an output port onto an input row links them, a linked
    /// input's port picked up and dropped on nothing deletes the link (or moves it onto another
    /// input), and links that would make a cycle are refused. The workspace applies them as undo steps.
    @Test func canvasDragsAndDeletesLinks() throws {
        let canvas = MaterialGraphCanvas()
        canvas.graph = MaterialGraph(nodes: [MaterialGraphNode(id: "c", type: "color"), MaterialGraphNode(id: "m", type: "math")],
                                     output: ["baseColor": .string("c.rgb")])
        canvas.layout(in: UIRect(x: 0, y: 0, width: 900, height: 400))
        var links: [(String, String?, String?)] = []
        canvas.onLink = { links.append(($0, $1, $2)) }
        func rect(_ id: String) throws -> UIRect { try #require(canvas.nodeRects().first { $0.id == id }?.rect) }
        func drag(_ from: Vec2, _ to: Vec2) {
            _ = canvas.handleEvent(.pointerDown(PointerEvent(position: from)))
            _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: (from + to) / 2)))
            _ = canvas.handleEvent(.pointerDrag(PointerEvent(position: to)))
            _ = canvas.handleEvent(.pointerUp(PointerEvent(position: to)))
        }
        let m = try rect("m"), c = try rect("c"), outputs = canvas.outputsRect
        let baseColorRow = try #require(MaterialGraph.outputs.firstIndex { $0.name == "baseColor" })
        let emissiveRow = try #require(MaterialGraph.outputs.firstIndex { $0.name == "emissive" })
        // c's output port onto the middle of m's first input row ("a").
        drag(MaterialGraphCanvas.outputPort(c), MaterialGraphCanvas.inputPort(m, 0) + Vec2(40, 0))
        #expect(links.count == 1 && links.last?.0 == "c" && links.last?.1 == "m.a" && links.last?.2 == nil)
        // The output's baseColor link, dropped on nothing: deleted (swizzle kept as the source).
        drag(MaterialGraphCanvas.inputPort(outputs, baseColorRow), Vec2(outputs.x - 60, 380))
        #expect(links.count == 2 && links.last?.0 == "c.rgb" && links.last?.1 == nil && links.last?.2 == "output.baseColor")
        // ... and moved onto emissive.
        drag(MaterialGraphCanvas.inputPort(outputs, baseColorRow), MaterialGraphCanvas.inputPort(outputs, emissiveRow))
        #expect(links.count == 3 && links.last?.1 == "output.emissive" && links.last?.2 == "output.baseColor")
        // Refused: into its own input, a new link dropped on nothing, an unlinked input's port.
        drag(MaterialGraphCanvas.outputPort(m), MaterialGraphCanvas.inputPort(m, 1))
        drag(MaterialGraphCanvas.outputPort(m), Vec2(outputs.x - 60, 380))
        #expect(links.count == 3 && canvas.linkDrag == nil)

        // The workspace writes each one as an undo step.
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "materialGraph.new", ["name": "Linked", "graph": [
            "nodes": [["id": "c", "type": "color"], ["id": "m", "type": "math"]], "output": ["baseColor": "c.rgb"]]])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let workspace = MaterialBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.canvas.onLink?("c", "m.a", nil)
        workspace.update(input: nil, dt: 1.0 / 60)
        workspace.canvas.onLink?("c.rgb", "output.emissive", "output.baseColor")
        workspace.update(input: nil, dt: 1.0 / 60)
        let graph = try #require(session.assets?.materialFile(of: id)?.graph)
        #expect(graph.node("m")?["a"] == .string("c") && graph.output["emissive"] == .string("c.rgb") && graph.output["baseColor"] == nil)
        workspace.canvas.onLink?("c.rgb", nil, "output.emissive")
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(session.assets?.materialFile(of: id)?.graph?.output["emissive"] == nil)
        #expect(session.performUndo())
        #expect(session.assets?.materialFile(of: id)?.graph?.output["emissive"] == .string("c.rgb"))
    }

    /// The Selected preview shape shows every mesh of the selection (children included) at its
    /// scene scale and arrangement, centered, with the camera fitted; without a selection it
    /// falls back to the sphere and the default camera.
    @Test func selectedPreviewShowsTheWholeSelectionAtScale() throws {
        let folder = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let session = makeSession()
        try call(session, "project.new", ["path": folder.appendingPathComponent("Game").path])
        let created = try call(session, "materialGraph.new", ["name": "Sel", "preset": "stone"])
        let id = try #require((created["asset"] as? String).flatMap { AssetID($0) })
        let world = session.world
        let a = world.spawn(Transform(position: Vec3(10, 0, 0), scale: Vec3(4, 4, 4)), Name("Big"), MeshRenderer(mesh: .cube))
        let b = world.spawn(Transform(position: Vec3(20, 0, 0)), Name("Group"))
        let child = world.spawn(Transform(position: Vec3(0, 2, 0)), Name("Child"), MeshRenderer(mesh: .sphere))
        world.setParent(child, to: b)
        world.propagateTransforms()
        session.selection.set([try #require(world.ensureID(of: a)), try #require(world.ensureID(of: b))])

        let workspace = MaterialBuilderWorkspace(session: session)
        #expect(workspace.open(id))
        workspace.setPreview(shape: .selected)
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.selectionParts.count == 2)
        let meshes = workspace.selectionParts.compactMap { workspace.world.get(MeshRenderer.self, for: $0) }
        #expect(Set(meshes.map(\.mesh.key)) == ["cube", "sphere"])
        #expect(meshes.allSatisfy { $0.material.key == workspace.materialKey })
        // Bounds x 8...20.5 (the cube 4 wide at 10, the sphere 1 wide at 20), y -2...2.5: centered there.
        let globals = workspace.selectionParts.compactMap { workspace.world.get(GlobalTransform.self, for: $0)?.matrix }
        let cube = try #require(globals.first { abs($0.c0.x - 4) < 1e-4 })
        #expect(abs(cube.c3.x - (10 - 14.25)) < 1e-3 && abs(cube.c3.y - (0 - 0.25)) < 1e-3)
        #expect(workspace.viewport.camera.distance > 10)
        // Nothing selected: the sphere again.
        session.selection.clear()
        workspace.update(input: nil, dt: 1.0 / 60)
        #expect(workspace.selectionParts.isEmpty && workspace.viewport.camera.distance == 3.2)
        var previewMeshes: [String] = []
        workspace.world.query(MeshRenderer.self) { _, renderer in previewMeshes.append(renderer.mesh.key) }
        #expect(previewMeshes == ["sphere"])
    }
}
