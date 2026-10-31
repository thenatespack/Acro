import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Tool ergonomics from the agent evals (Evals/results.md): asset ids and references accepted
// interchangeably and interpolated in batches, transform.lookAt and Euler degrees, scene.new's
// empty template, material.set merging (and naming asset.extractMaterials for imported
// materials), play.step's `until`, and scene.save asking for `confirm` only when it overwrites
// another file.

private let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

private func workspaceFolder() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ToolErgonomicsTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url.resolvingSymlinksInPath()
}

/// An editor MCP server with an initialized in-memory client; its sandbox is `workspace`.
@MainActor private struct Client {
    let session: EditorSession
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init(workspace: URL = workspaceFolder()) {
        let log = EditorLog()
        log.echoesToStandardOutput = false
        session = EditorSession(document: EditorDocument(), log: log)
        session.newDocument()
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        mcp.workspaceRoot = workspace
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = request("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "ergonomics"]])
    }

    func request(_ method: String, _ params: JSON) -> JSON {
        let id = JSON.string(UUID().uuidString)
        connection.send(["jsonrpc": "2.0", "id": id, "method": .string(method), "params": params])
        for _ in 0..<5000 {
            mcp.pump()
            if let reply = connection.output.take().first(where: { $0["id"] == id }) { return reply["result"] ?? reply["error"] ?? nil }
            Thread.sleep(forTimeInterval: 0.002)
        }
        return nil
    }

    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = request("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)", sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    /// The error text of a call that should fail.
    func failure(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> String {
        let result = request("tools/call", ["name": .string(name), "arguments": arguments])
        #expect(result["isError"] == true, "\(name) should have failed", sourceLocation: sourceLocation)
        return result["content"]?.arrayValue?.compactMap { $0["text"]?.stringValue }.joined(separator: "\n") ?? ""
    }

    func newProject() {
        tool("project.new", ["path": "."])
    }

    func create(_ template: String, _ name: String, at position: [Double] = [0, 0, 0]) -> String {
        tool("entity.create", ["template": .string(template), "name": .string(name), "position": .array(position.map(JSON.double))])["entity"]?.stringValue ?? ""
    }

    func field(_ entity: String, _ path: String) -> JSON {
        let parts = path.split(separator: ".", maxSplits: 1).map(String.init)
        return tool("entity.get", ["entity": .string(entity)])["components"]?[parts[0]]?[parts[1]] ?? nil
    }

    func worldTransform(_ entity: String) -> JSON {
        session.world.propagateTransforms()
        return tool("entity.get", ["entity": .string(entity)])["world"] ?? nil
    }

    func worldPosition(_ entity: String) -> [Double] {
        (worldTransform(entity)["position"]?.arrayValue ?? []).compactMap { $0.doubleValue }
    }
}

private func dot(_ a: [Double], _ b: [Double]) -> Double { zip(a, b).map(*).reduce(0, +) }
private func normalized(_ v: [Double]) -> [Double] {
    let length = dot(v, v).squareRoot()
    return v.map { $0 / length }
}

/// A quaternion [x, y, z, w] rotating (0, 0, -1), the forward direction.
private func forward(_ q: [Double]) -> [Double] {
    let (x, y, z, w) = (q[0], q[1], q[2], q[3])
    // Rotate v = (0, 0, -1): v + 2w(u x v) + 2 u x (u x v), u = (x, y, z).
    let v = [0.0, 0.0, -1.0]
    func cross(_ a: [Double], _ b: [Double]) -> [Double] {
        [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    }
    let u = [x, y, z]
    let t = cross(u, v).map { 2 * $0 }
    let c = cross(u, t)
    return (0..<3).map { v[$0] + w * t[$0] + c[$0] }
}

@MainActor
@Suite struct ToolErgonomicsTests {
    // MARK: Batches

    @Test func batchInterpolatesResultsInsideStrings() {
        let client = Client()
        let result = client.tool("edit.batch", ["label": "Name it", "calls": [
            ["command": "entity.create", "arguments": ["template": "cube", "name": "Box"]],
            ["command": "entity.rename", "arguments": ["entity": "$0.entity", "name": "Box {$0.entity} and {$x} {$"]],
        ]])
        let id = result["results"]?.arrayValue?[0]["entity"]?.stringValue ?? ""
        #expect(client.tool("entity.get", ["entity": .string(id)])["name"] == .string("Box \(id) and {$x} {$"))
        // A reference to a call that hasn't run is an error, and the batch rolls back.
        let failed = client.failure("edit.batch", ["label": "x", "calls": [
            ["command": "entity.create", "arguments": ["template": "cube", "name": "Late {$3.entity}"]],
        ]])
        #expect(failed.contains("hasn't run yet"))
    }

    // MARK: Asset ids and references

    @Test func assetToolsTakeIdsAndReferences() {
        let client = Client()
        client.newProject()
        let material = client.tool("asset.newMaterial", ["name": "Crate", "material": ["roughness": 0.8]])["asset"]?.stringValue ?? ""
        #expect(material.count == 32)
        // material.set takes an id or a reference; material.get, asset.get and asset.assign take a reference or an id.
        client.tool("material.set", ["asset": .string(material), "material": ["metallic": 1]])
        client.tool("material.set", ["asset": .string("asset:\(material)"), "material": ["specular": 0.9]])
        #expect(client.tool("material.get", ["asset": .string(material)])["material"]?["metallic"] == 1)
        #expect(client.tool("material.get", ["asset": .string("asset:\(material)")])["material"]?["metallic"] == 1)
        #expect(client.tool("asset.get", ["asset": .string(material)])["asset"]?["id"] == .string(material))
        let entity = client.create("cube", "Crate")
        client.tool("asset.assign", ["entity": .string(entity), "asset": .string(material), "kind": "material"])
        #expect(client.field(entity, "MeshRenderer.material").stringValue?.hasPrefix("asset:\(material)") == true)
        // A sub-asset reference where only a file is meant is still an error.
        #expect(client.failure("material.set", ["asset": .string("asset:\(material)#material"), "material": [:]]).contains("Invalid arguments"))
        // Schemas state both forms.
        let schema = client.mcp.tools.first { $0.name == "material.set" }?.inputSchema["properties"]?["asset"]
        #expect(schema?["pattern"]?.stringValue?.contains("(asset:)?") == true)
    }

    @Test func batchBuildsAssetReferencesFromResults() {
        let client = Client()
        client.newProject()
        let result = client.tool("edit.batch", ["label": "Crate", "calls": [
            ["command": "asset.newMaterial", "arguments": ["name": "Wood", "material": ["roughness": 0.3]]],
            ["command": "entity.create", "arguments": ["template": "cube", "name": "Crate"]],
            ["command": "asset.assign", "arguments": ["entity": "$1.entity", "asset": "asset:{$0.asset}", "kind": "material"]],
        ]])
        let material = result["results"]?.arrayValue?[0]["asset"]?.stringValue ?? ""
        let entity = result["results"]?.arrayValue?[1]["entity"]?.stringValue ?? ""
        #expect(client.field(entity, "MeshRenderer.material").stringValue?.hasPrefix("asset:\(material)") == true)
    }

    // MARK: Materials

    @Test func materialSetMergesAndResets() {
        let client = Client()
        client.newProject()
        let id = client.tool("asset.newMaterial", ["name": "M"])["asset"]?.stringValue ?? ""
        client.tool("material.set", ["asset": .string(id), "material": ["baseColor": [1, 0, 0, 1], "metallic": 1]])
        client.tool("material.set", ["asset": .string(id), "material": ["roughness": 0.2]])
        var material = client.tool("material.get", ["asset": .string(id)])["material"]
        #expect(material?["baseColor"] == [1, 0, 0, 1] && material?["metallic"] == 1 && material?["roughness"]?.doubleValue == 0.2)
        // One undo step per call; undo goes back to the previous merge.
        client.tool("edit.undo")
        material = client.tool("material.get", ["asset": .string(id)])["material"]
        #expect(material?["metallic"] == 1 && material?["roughness"]?.doubleValue == 0.5)
        // reset starts from the defaults.
        client.tool("material.set", ["asset": .string(id), "material": ["roughness": 0.9], "reset": true])
        material = client.tool("material.get", ["asset": .string(id)])["material"]
        #expect(material?["metallic"] == 0 && material?["roughness"]?.doubleValue == 0.9)
        // null clears a texture; unknown fields are an error naming the valid ones.
        let error = client.failure("material.set", ["asset": .string(id), "material": ["colour": [1, 0, 0, 1]]])
        #expect(error.contains("Unknown material field 'colour'") && error.contains("baseColor"))
    }

    @Test func importedMaterialsNameExtractMaterials() throws {
        let workspace = workspaceFolder()
        try FileManager.default.copyItem(at: repository.appendingPathComponent("Tests/EngineTests/Resources/glTF/Box.glb"),
                                         to: workspace.appendingPathComponent("Box.glb"))
        let client = Client(workspace: workspace)
        client.newProject()
        // Import through the registry: imports finish on frames, which this client doesn't run.
        let importArguments: JSON = ["sources": [.string(workspace.appendingPathComponent("Box.glb").path)]]
        let waitArguments: JSON = ["timeout": 60]
        _ = try client.session.commands.run("asset.import", json: importArguments.data())
        _ = try client.session.commands.run("asset.waitForImports", json: waitArguments.data())
        let model = client.tool("asset.get", ["path": "Box.glb"])["asset"]?["id"]?.stringValue ?? ""
        let error = client.failure("material.set", ["asset": .string(model), "material": ["metallic": 1]])
        #expect(error.contains("asset.extractMaterials") && error.contains("read-only"))
        let extracted = client.tool("asset.extractMaterials", ["asset": .string("asset:\(model)")])["materials"]?.arrayValue ?? []
        guard let first = extracted.first else {
            Issue.record("no materials extracted")
            return
        }
        client.tool("material.set", ["asset": first, "material": ["metallic": 1]])
    }

    // MARK: Aiming

    @Test func lookAtAimsEntitiesAtPointsAndEntities() {
        let client = Client()
        let camera = client.create("empty", "Camera", at: [0, 3, 7])
        client.tool("transform.lookAt", ["entity": .string(camera), "target": [0, 0, 0]])
        let aim = normalized([0, -3, -7])
        var rotation = client.field(camera, "Transform.rotation").arrayValue?.compactMap { $0.doubleValue } ?? []
        #expect(dot(forward(rotation), aim) > 0.999, "\(rotation)")
        // Another entity as the target, under a rotated parent: the world direction is what counts.
        let target = client.create("cube", "Target", at: [4, 0, 0])
        let parent = client.create("empty", "Parent")
        client.tool("component.setField", ["entity": .string(parent), "path": "Transform.rotation", "value": ["eulerDegrees": [0, 90, 0]]])
        client.tool("entity.reparent", ["entities": [.string(camera)], "parent": .string(parent)])
        client.tool("transform.lookAt", ["entity": .string(camera), "target": .string(target)])
        let world = client.worldTransform(camera)
        rotation = world["rotation"]?.arrayValue?.compactMap { $0.doubleValue } ?? []
        let position = world["position"]?.arrayValue?.compactMap { $0.doubleValue } ?? []
        #expect(dot(forward(rotation), normalized(zip([4, 0, 0], position).map { $0 - $1 })) > 0.999, "\(rotation)")
        // Straight down (parallel to up) works; a target at the entity is an error; it is one undo step.
        let sun = client.create("empty", "Sun", at: [0, 5, 0])
        client.tool("transform.lookAt", ["entity": .string(sun), "target": [0, 0, 0]])
        rotation = client.field(sun, "Transform.rotation").arrayValue?.compactMap { $0.doubleValue } ?? []
        #expect(dot(forward(rotation), [0, -1, 0]) > 0.999, "\(rotation)")
        #expect(client.failure("transform.lookAt", ["entity": .string(sun), "target": [0, 5, 0]]).contains("nothing to look at"))
        client.tool("edit.undo")
        #expect(client.field(sun, "Transform.rotation").arrayValue?.compactMap { $0.doubleValue } == [0, 0, 0, 1])
        #expect(client.failure("transform.lookAt", ["entity": .string(sun), "target": "nope"]).contains("Invalid arguments"))
    }

    @Test func eulerDegreesWhereverAQuaternionGoes() {
        let client = Client()
        let entity = client.create("cube", "Cube")
        client.tool("component.setField", ["entity": .string(entity), "path": "Transform.rotation", "value": ["eulerDegrees": [0, 90, 0]]])
        let q = client.field(entity, "Transform.rotation").arrayValue?.compactMap { $0.doubleValue } ?? []
        let half = 0.5.squareRoot()
        #expect(zip(q, [0, half, 0, half]).allSatisfy { abs($0 - $1) < 1e-5 }, "\(q)")
        // Pitch down 30 degrees tilts forward below the horizon.
        client.tool("component.setField", ["entity": .string(entity), "component": "Transform", "path": "rotation",
                                           "value": ["eulerDegrees": [-30, 0, 0]]])
        let pitched = client.field(entity, "Transform.rotation").arrayValue?.compactMap { $0.doubleValue } ?? []
        #expect(forward(pitched)[1] < -0.49)
        // World space too, and bad shapes are errors.
        client.tool("component.setField", ["entity": .string(entity), "path": "Transform.rotation", "space": "world",
                                           "value": ["eulerDegrees": [0, 180, 0]]])
        #expect(client.failure("component.setField", ["entity": .string(entity), "path": "Transform.rotation",
                                                      "value": ["eulerDegrees": [1, 2]]]).isEmpty == false)
        #expect(client.failure("component.setField", ["entity": .string(entity), "path": "Transform.position",
                                                      "value": ["eulerDegrees": [1, 2, 3]]]).isEmpty == false)
    }

    // MARK: Scenes

    @Test func sceneNewTemplates() {
        let client = Client()
        #expect(client.session.world.roots.count > 3)
        client.tool("scene.new", ["template": "empty", "confirm": true])
        #expect(client.session.world.roots.isEmpty)
        #expect(!client.session.document.isDirty)
        client.tool("scene.new", ["confirm": true])
        #expect(client.session.world.roots.count > 3)
        client.tool("scene.new", ["template": "starter", "confirm": true])
        #expect(client.session.world.roots.count > 3)
        #expect(client.failure("scene.new", ["template": "city", "confirm": true]).contains("starter"))
        // The typed run (the New button) still makes the starter scene.
        client.session.run(SceneNewCommand.self, .init(template: "empty"))
        #expect(client.session.world.roots.isEmpty)
        client.session.run(SceneNewCommand.self)
        #expect(client.session.world.roots.count > 3)
    }

    @Test func sceneSaveConfirmsOnlyWhenOverwritingAnotherFile() throws {
        let workspace = workspaceFolder()
        let client = Client(workspace: workspace)
        func tools(_ name: String) -> MCPTool? { client.mcp.tools.first { $0.name == name } }
        // The schemas say confirm is optional and when it is needed.
        for name in ["scene.save", "scene.saveAs"] {
            let tool = try #require(tools(name))
            #expect(tool.inputSchema["required"]?.arrayValue?.contains("confirm") != true)
            #expect(tool.inputSchema["properties"]?["confirm"] != nil && tool.annotations?.destructiveHint == true)
            #expect(tool.description.contains("confirm: true"))
        }
        #expect(try #require(tools("scene.new")).inputSchema["required"]?.arrayValue?.contains("confirm") == true)

        // A new file, then its own file again: no confirm.
        client.tool("scene.saveAs", ["path": "level.json"])
        client.tool("scene.save")
        client.tool("scene.saveAs", ["path": "level.json"])
        client.tool("scene.saveAs", ["path": "./level.json"])
        // Another file that exists: refused until confirmed.
        client.tool("scene.saveAs", ["path": "other.json"])
        client.tool("scene.saveAs", ["path": "level.json", "confirm": true])
        let refused = client.failure("scene.saveAs", ["path": "other.json"])
        #expect(refused.contains("confirm: true") && refused.contains("scene.saveAs"))
        #expect(client.session.document.url?.lastPathComponent == "level.json")
        client.tool("scene.saveAs", ["path": "other.json", "confirm": true])
        // An unsaved scene saved with a path: confirm only over an existing file.
        client.tool("scene.new", ["confirm": true])
        #expect(client.failure("scene.save", ["path": "level.json"]).contains("confirm: true"))
        client.tool("scene.save", ["path": "fresh.json"])
        #expect(FileManager.default.fileExists(atPath: workspace.appendingPathComponent("fresh.json").path))
        // Inside a batch the same rule applies per call.
        client.tool("scene.new", ["confirm": true])
        let batch = client.failure("edit.batch", ["label": "x", "calls": [["command": "scene.saveAs", "arguments": ["path": "other.json"]]]])
        #expect(batch.contains("confirm: true"))
    }

    // MARK: Playtesting

    @Test func playStepUntilStopped() {
        let client = Client()
        let hero = client.create("cube", "Hero", at: [0, 0.5, 0])
        client.tool("component.add", ["entity": .string(hero), "component": "KeyboardMover"])
        client.tool("play.start", ["paused": true])
        client.tool("input.inject", ["steps": [["key": "w", "duration": 1]]])
        let stepped = client.tool("play.step", ["until": ["entity": .string(hero), "stopped": true], "maxFrames": 600])
        #expect(stepped["reason"] == "stopped")
        let frames = stepped["stepped"]?.intValue ?? 0
        // One second of walking (60 frames), then the window of 10 still frames.
        #expect(frames >= 65 && frames <= 80, "\(frames)")
        #expect(stepped["frame"]?.intValue == frames)
        #expect(abs(client.worldPosition(hero)[2] + 3) < 0.1)

        // Still moving when the frames run out.
        client.tool("input.inject", ["steps": [["key": "s", "duration": 5]], "replace": true])
        let capped = client.tool("play.step", ["until": ["entity": .string(hero), "stopped": true, "window": 5], "maxFrames": 20])
        #expect(capped["reason"] == "maxFrames" && capped["stepped"] == 20)
        // A tolerance: with a big epsilon a slow walk counts as stopped at once.
        let loose = client.tool("play.step", ["until": ["entity": .string(hero), "stopped": true, "epsilon": 10], "maxFrames": 100])
        #expect(loose["reason"] == "stopped" && loose["stepped"]?.intValue == 10, "\(loose)")
        // Plain steps report what they ran.
        let plain = client.tool("play.step", ["frames": 3])
        #expect(plain["stepped"] == 3 && plain["reason"] == "frames")
        // Errors: frames with until, maxFrames without, unknown entity.
        #expect(client.failure("play.step", ["frames": 3, "until": ["entity": .string(hero), "stopped": true]]).contains("maxFrames"))
        #expect(client.failure("play.step", ["maxFrames": 3]).contains("until"))
        #expect(client.failure("play.step", ["until": ["entity": "00000000000000000000000000000001", "stopped": true]]).isEmpty == false)
        #expect(client.failure("play.step", ["until": ["entity": .string(hero), "stopped": false]]).contains("stopped: true"))
        client.tool("play.stop")
    }
}
