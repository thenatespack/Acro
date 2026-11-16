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
}
