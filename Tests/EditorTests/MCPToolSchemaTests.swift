import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import EditorBuildersAnimation
@testable import EditorBuildersMesh
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

// The command registry as MCP tools: one tool per command with schemas derived from its
// Codable types (snapshots below), annotations, calls through a client, errors, list changes
// and the editor's resources.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// An editor MCP server with an initialized in-memory client.
@MainActor private final class Client {
    let session = makeSession()
    let mcp: EditorMCP
    let connection: MCPMemoryConnection
    var nextID: Int64 = 0

    init() {
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = call("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:]])
    }

    /// Notifications that arrived with a reply (see `call`).
    var notifications: [JSON] = []

    /// Sends a request, pumps, and returns its result (notifications sent alongside go to `notifications`).
    @discardableResult
    func call(_ method: String, _ params: JSON? = nil) -> JSON {
        var message: JSON = ["jsonrpc": "2.0", "id": .string(UUID().uuidString), "method": .string(method)]
        if let params { message["params"] = params }
        connection.send(message)
        mcp.pump()
        let id = message["id"]
        let output = connection.output.take()
        // Notifications sent in the same pump (a throttled resource check can land there) are kept.
        notifications += output.filter { $0["id"] == nil }
        let reply = output.first { $0["id"] == id } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
    }

    func tool(_ name: String, _ arguments: JSON = [:]) -> JSON {
        call("tools/call", ["name": .string(name), "arguments": arguments])
    }

    func resource(_ uri: String) throws -> JSON {
        try JSON(parsing: call("resources/read", ["uri": .string(uri)])["contents"]?.arrayValue?.first?["text"]?.stringValue ?? "")
    }
}

/// A command added in a test: it should become a tool with no MCP code.
private enum GreetCommand: EditorCommand {
    struct Arguments: Codable {
        enum Style: String, Codable, CaseIterable { case plain, loud }
        var who: String
        var style: Style?
        var times: Int?
    }

    struct Result: Codable {
        var greeting: String
    }

    static let id: CommandID = "test.greet"
    static let title = "Greet"
    static let doc = "Greets `who`."
    static let isReadOnly = true
    static let isIdempotent = true
    static func run(_ arguments: Arguments, in session: EditorSession) throws -> Result {
        let text = "Hello, \(arguments.who)" + (arguments.style == .loud ? "!" : ".")
        return Result(greeting: Array(repeating: text, count: arguments.times ?? 1).joined(separator: " "))
    }
}

@MainActor @Suite struct MCPToolSchemaTests {
    @Test func everyCommandIsAToolWithObjectSchemas() {
        let client = Client()
        let tools = client.mcp.tools
        #expect(tools.map(\.name) == client.session.commands.all.map(\.id.rawValue))
        for tool in tools {
            #expect(MCPTool.isValidName(tool.name))
            #expect(tool.inputSchema["type"] == "object", "\(tool.name)")
            #expect(tool.outputSchema?["type"] == "object", "\(tool.name)")
            #expect(!tool.description.isEmpty)
        }
        let listed = client.call("tools/list")["tools"]?.arrayValue ?? []
        #expect(listed.count == tools.count)
    }

    @Test func annotationsComeFromCommandMetadata() {
        let client = Client()
        func annotations(_ name: String) -> MCPToolAnnotations? { client.mcp.tools.first { $0.name == name }?.annotations }
        #expect(annotations("entity.create") == MCPToolAnnotations(title: "Create Entity", readOnlyHint: false, destructiveHint: false,
                                                                    idempotentHint: false, openWorldHint: false))
        #expect(annotations("asset.delete")?.destructiveHint == true)
        #expect(annotations("scene.new")?.destructiveHint == true)
        #expect(annotations("selection.set")?.idempotentHint == true)
        #expect(client.mcp.tools.first { $0.name == "entity.rename" }?.description.contains("Undoable") == true)
    }

    // MARK: Schema snapshots

    private func schema(_ name: String) -> String {
        Client().mcp.tools.first { $0.name == name }?.inputSchema.text ?? "missing"
    }

    private func output(_ name: String) -> String {
        Client().mcp.tools.first { $0.name == name }?.outputSchema?.text ?? "missing"
    }

    @Test func entityCreateSchema() {
        #expect(schema("entity.create") == SNAPSHOT_ENTITY_CREATE)
        #expect(output("entity.create") == SNAPSHOT_ENTITY_CREATE_OUT)
    }

    @Test func noArgumentsSchema() {
        #expect(schema("edit.undo") == #"{"properties":{},"type":"object"}"#)
        #expect(output("edit.undo") == #"{"properties":{},"type":"object"}"#)
    }

    @Test func transformSetSchema() {
        #expect(schema("transform.set") == SNAPSHOT_TRANSFORM_SET)
    }

    @Test func componentSetFieldSchema() {
        #expect(schema("component.setField") == SNAPSHOT_SET_FIELD)
    }

    @Test func assetSchemas() {
        #expect(schema("asset.instantiate") == SNAPSHOT_INSTANTIATE)
        #expect(schema("asset.assign") == SNAPSHOT_ASSIGN)
        #expect(output("asset.newMaterial") == SNAPSHOT_NEW_MATERIAL_OUT)
    }

    @Test func materialSetSchema() {
        #expect(schema("material.set") == SNAPSHOT_MATERIAL_SET)
    }

    @Test func perceptionAndQuerySchemas() throws {
        let tools = Client().mcp.tools
        let screenshot = try #require(tools.first { $0.name == "view.screenshot" })
        #expect(screenshot.annotations?.readOnlyHint == true)
        #expect(screenshot.inputSchema["properties"]?["source"] == [
            "type": "string", "enum": ["viewport", "game", "camera", "window", "panel", "thumbnail"],
        ])
        #expect(screenshot.outputSchema?["properties"]?["image"]?["required"] == ["mimeType", "width", "height"])
        #expect(output("view.pick") == SNAPSHOT_PICK_OUT)
        // Recursive results state their schema instead of being probed 24 levels deep.
        let hierarchy = try #require(tools.first { $0.name == "scene.hierarchy" })
        #expect(hierarchy.outputSchema?["properties"]?["entities"]?["items"] == HierarchyNode.jsonSchema)
        let batch = try #require(tools.first { $0.name == "edit.batch" })
        #expect(batch.inputSchema["required"] == ["label", "calls"])
        #expect(batch.inputSchema["properties"]?["calls"]?["items"]?["required"] == ["command"])
    }

    // MARK: Calls

    @Test func callsRunCommandsAndReturnStructuredResults() throws {
        let client = Client()
        let created = client.tool("entity.create", ["template": "sphere", "position": [1, 2, 3]])
        #expect(created["isError"] == false)
        let entity = try #require(created["structuredContent"]?["entity"]?.stringValue)
        #expect(created["content"]?.arrayValue?.first?["text"]?.stringValue?.contains(entity) == true)
        #expect(client.session.selection.ids.map(\.description) == [entity])

        let renamed = client.tool("entity.rename", ["entity": .string(entity), "name": "Probe"])
        #expect(renamed["structuredContent"] == .object([:]))
        #expect(renamed["content"]?.arrayValue?.first?["text"] == "Rename: done.")

        let read = try client.resource("editor://entity/\(entity)")
        #expect(read["name"] == "Probe")
        #expect(read["components"]?["Transform"]?["position"] == [1, 2, 3])
        #expect(read["components"]?["MeshRenderer"] != nil)

        client.tool("edit.undo")
        #expect(try client.resource("editor://entity/\(entity)")["name"] == "Sphere")
    }

    @Test func failuresAreToolErrorsWithReasons() {
        let client = Client()
        let unavailable = client.tool("entity.duplicate")
        #expect(unavailable["isError"] == true)
        #expect(unavailable["content"]?.arrayValue?.first?["text"] == "'entity.duplicate' isn't available now: nothing is selected (run selection.set first)")
        let noProject = client.tool("asset.newFolder")
        #expect(noProject["content"]?.arrayValue?.first?["text"]?.stringValue?.contains("no project is open") == true)
        let noWindow = client.tool("layout.reset")
        #expect(noWindow["content"]?.arrayValue?.first?["text"]?.stringValue?.contains("editor window") == true)
        let bad = client.tool("entity.create", ["template": "pyramid"])
        #expect(bad["isError"] == true)
        #expect(bad["content"]?.arrayValue?.first?["text"]?.stringValue?.contains("Invalid arguments") == true)
        let missing = client.tool("entity.rename", ["name": "x"])
        #expect(missing["content"]?.arrayValue?.first?["text"]?.stringValue?.contains("missing 'entity'") == true)
        #expect(client.call("tools/call", ["name": "no.such.tool"])["code"] == -32602)
    }

    @Test func newCommandsBecomeToolsAndAnnounceIt() throws {
        let client = Client()
        _ = client.connection.output.take()
        client.session.commands.register(GreetCommand.self)
        client.mcp.pump()
        #expect(client.connection.output.take() == [["jsonrpc": "2.0", "method": "notifications/tools/list_changed"]])

        let tool = try #require(client.mcp.tools.first { $0.name == "test.greet" })
        #expect(tool.description == "Greets `who`.")
        #expect(tool.annotations?.readOnlyHint == true)
        #expect(tool.inputSchema == [
            "type": "object",
            "properties": ["who": ["type": "string"], "style": ["type": "string", "enum": ["plain", "loud"]], "times": ["type": "integer"]],
            "required": ["who"],
        ])
        #expect(tool.outputSchema == ["type": "object", "properties": ["greeting": ["type": "string"]], "required": ["greeting"]])
        let result = client.tool("test.greet", ["who": "MCP", "style": "loud", "times": 2])
        #expect(result["structuredContent"] == ["greeting": "Hello, MCP! Hello, MCP!"])
    }

    @Test func openingAProjectAnnouncesAListChange() throws {
        let client = Client()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MCPToolSchemaTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        client.mcp.workspaceRoot = FileManager.default.temporaryDirectory  // AI clients only touch files in it
        _ = client.connection.output.take()
        let result = client.tool("project.new", ["path": .string(folder.path)])
        #expect(result["isError"] == false)
        client.mcp.pump()
        #expect(client.connection.output.take().contains(["jsonrpc": "2.0", "method": "notifications/tools/list_changed"]))
        #expect(try client.resource("editor://assets")["project"] != nil)
        #expect(client.tool("asset.newFolder", ["name": "Props"])["structuredContent"] == ["path": "Props"])
    }

    @Test func sceneAndLogResources() throws {
        let client = Client()
        let resources = client.call("resources/list")["resources"]?.arrayValue?.compactMap { $0["uri"]?.stringValue }
        #expect(resources == ["editor://scene", "editor://scene/file", "editor://assets", "editor://log", "editor://stats",
                              "editor://diagnostics"])
        let templates = client.call("resources/templates/list")["resourceTemplates"]?.arrayValue?.compactMap { $0["uriTemplate"]?.stringValue }
        #expect(templates == ["editor://entity/{id}", "editor://asset/{id}", "editor://log/{level}"])
        let scene = try client.resource("editor://scene")
        let names = scene["entities"]?.arrayValue?.compactMap { $0["name"]?.stringValue } ?? []
        #expect(names.contains("Main Camera"))
        #expect(scene["scene"]?["playing"] == false)
        let log = try client.resource("editor://log")
        #expect(log.arrayValue?.contains { $0["message"] == "New scene" } == true)
        #expect(client.call("resources/read", ["uri": "editor://entity/nope"])["code"] == -32002)
    }

    @Test func subscribedResourcesReportUpdates() throws {
        // Resource checks are throttled by wall-clock time (5 a second), so whether one ran in a
        // given pump depended on how long the calls took: on a busy machine the update came with
        // the tool's reply, on a quiet one only in a later pump. Checking in every pump makes it
        // deterministic: the subscribe's pump records what the client has seen, and the pump that
        // runs the change reports it with its reply.
        let client = Client()
        client.mcp.resourceCheckInterval = .zero
        client.call("resources/subscribe", ["uri": "editor://scene"])
        client.mcp.pump()
        #expect(client.notifications.isEmpty && client.connection.output.take().isEmpty, "nothing changed")
        client.tool("entity.create", ["template": "cube"])
        let update: JSON = ["jsonrpc": "2.0", "method": "notifications/resources/updated", "params": ["uri": "editor://scene"]]
        #expect(client.notifications == [update])
        client.notifications = []
        client.mcp.pump()
        #expect(client.connection.output.take().isEmpty, "reported once")
        // Read-only calls change nothing.
        client.tool("scene.hierarchy")
        #expect(client.notifications.isEmpty)
        // With the default throttle a check waits for the interval, then reports what changed since.
        client.mcp.resourceCheckInterval = .seconds(3600)
        client.tool("entity.create", ["template": "sphere"])
        #expect(client.notifications.isEmpty, "throttled")
        client.mcp.resourceCheckInterval = .zero
        client.mcp.pump()
        #expect(client.connection.output.take() == [update])
    }
}

// Snapshots (compact JSON, sorted keys). Update them when a command's arguments change on purpose.

private let SNAPSHOT_ENTITY_CREATE = #"{"properties":{"name":{"type":"string"},"parent":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"position":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"template":{"enum":["empty","cube","sphere","plane","cylinder","capsule","cone","torus"],"type":"string"}},"required":["template"],"type":"object"}"#
private let SNAPSHOT_ENTITY_CREATE_OUT = #"{"properties":{"entity":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"}},"required":["entity"],"type":"object"}"#
private let SNAPSHOT_TRANSFORM_SET = #"{"properties":{"changes":{"items":{"properties":{"entity":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"previous":{"properties":{"position":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"rotation":{"description":"A rotation quaternion [x, y, z, w]; [0, 0, 0, 1] is none.","items":{"type":"number"},"maxItems":4,"minItems":4,"type":"array"},"scale":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"required":["position","rotation","scale"],"type":"object"},"transform":{"properties":{"position":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"rotation":{"description":"A rotation quaternion [x, y, z, w]; [0, 0, 0, 1] is none.","items":{"type":"number"},"maxItems":4,"minItems":4,"type":"array"},"scale":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"required":["position","rotation","scale"],"type":"object"}},"required":["entity","transform"],"type":"object"},"type":"array"},"label":{"type":"string"}},"required":["changes"],"type":"object"}"#
private let SNAPSHOT_SET_FIELD = #"{"properties":{"component":{"type":"string"},"entity":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"label":{"type":"string"},"path":{"type":"string"},"previous":{"description":"Any JSON value."},"space":{"enum":["local","world"],"type":"string"},"transient":{"type":"boolean"},"value":{"description":"Any JSON value."}},"required":["entity","path","value"],"type":"object"}"#
private let SNAPSHOT_INSTANTIATE = #"{"properties":{"asset":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"parent":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"position":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"required":["asset"],"type":"object"}"#
private let SNAPSHOT_ASSIGN = #"{"properties":{"asset":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"entity":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"kind":{"enum":["mesh","material","texture","prefab","animation","animationGraph"],"type":"string"}},"required":["entity","asset"],"type":"object"}"#
private let SNAPSHOT_NEW_MATERIAL_OUT = #"{"properties":{"asset":{"description":"An asset id: 32 hex digits, with or without the \"asset:\" prefix (see the editor://assets resource).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}$","type":"string"},"path":{"type":"string"}},"required":["asset","path"],"type":"object"}"#
private let SNAPSHOT_MATERIAL_SET = #"{"properties":{"asset":{"description":"An asset id: 32 hex digits, with or without the \"asset:\" prefix (see the editor://assets resource).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}$","type":"string"},"label":{"type":"string"},"material":{"properties":{"addressMode":{"enum":["repeat","clampToEdge","mirrorRepeat"],"type":"string"},"alphaCutoff":{"type":"number"},"alphaMode":{"enum":["opaque","mask","blend"],"type":"string"},"baseColor":{"description":"Linear [r, g, b, a].","items":{"type":"number"},"maxItems":4,"minItems":4,"type":"array"},"checker":{"type":"boolean"},"doubleSided":{"type":"boolean"},"edgeWear":{"properties":{"color":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"crisp":{"type":"number"},"metallic":{"type":"number"},"noiseFrequency":{"type":"number"},"roughness":{"type":"number"}},"required":["color","roughness","metallic","noiseFrequency","crisp"],"type":"object"},"emissive":{"type":"number"},"emissiveColor":{"description":"Linear [r, g, b].","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"emissiveStrength":{"type":"number"},"emissiveTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"filter":{"enum":["linear","nearest"],"type":"string"},"fur":{"properties":{"flowImage":{"properties":{"height":{"type":"integer"},"pixels":{"type":"string"},"width":{"type":"integer"}},"required":["width","height","pixels"],"type":"object"},"groom":{"properties":{"cardSegments":{"type":"integer"},"cardWidth":{"type":"number"},"clumping":{"type":"number"},"colorNoise":{"type":"number"},"comb":{"items":{"properties":{"center":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"direction":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"radius":{"type":"number"},"strength":{"type":"number"}},"type":"object"},"type":"array"},"combDirection":{"type":"string"},"combStrength":{"type":"number"},"curl":{"type":"number"},"cut":{"items":{"properties":{"center":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"length":{"type":"number"},"radius":{"type":"number"},"strength":{"type":"number"}},"type":"object"},"type":"array"},"density":{"type":"number"},"flowTexture":{"type":"string"},"frizz":{"type":"number"},"gravity":{"type":"number"},"length":{"type":"number"},"lengthVariation":{"type":"number"},"lod":{"properties":{"cards":{"items":{"type":"number"},"type":"array"},"distances":{"items":{"type":"number"},"type":"array"},"shells":{"items":{"type":"integer"},"type":"array"}},"type":"object"},"mask":{"properties":{"invert":{"type":"boolean"},"parts":{"items":{"type":"string"},"type":"array"},"texture":{"type":"string"},"vertexPaint":{"type":"string"}},"type":"object"},"previewMesh":{"type":"string"},"rootColor":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"seed":{"type":"integer"},"shells":{"type":"integer"},"specular":{"type":"number"},"stiffness":{"type":"number"},"strandsPerCard":{"type":"integer"},"style":{"enum":["shell","cards","strands"],"type":"string"},"thickness":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"tipColor":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"wind":{"type":"number"}},"type":"object"},"maskImage":{"properties":{"height":{"type":"integer"},"pixels":{"type":"string"},"width":{"type":"integer"}},"required":["width","height","pixels"],"type":"object"}},"type":"object"},"metallic":{"type":"number"},"metallicRoughnessTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"mipFilter":{"enum":["linear","nearest","none"],"type":"string"},"normalScale":{"type":"number"},"normalTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"occlusionStrength":{"type":"number"},"occlusionTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"roughness":{"type":"number"},"shading":{"enum":["pbr","blinnPhong"],"type":"string"},"shininess":{"type":"number"},"specular":{"type":"number"},"texture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"translucency":{"type":"number"},"uvOffset":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"uvRotation":{"type":"number"},"uvScale":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"wind":{"properties":{"bend":{"type":"number"},"flutter":{"type":"number"},"height":{"type":"number"},"origin":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"up":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"type":"object"}},"type":"object"},"previous":{"properties":{"addressMode":{"enum":["repeat","clampToEdge","mirrorRepeat"],"type":"string"},"alphaCutoff":{"type":"number"},"alphaMode":{"enum":["opaque","mask","blend"],"type":"string"},"baseColor":{"description":"Linear [r, g, b, a].","items":{"type":"number"},"maxItems":4,"minItems":4,"type":"array"},"checker":{"type":"boolean"},"doubleSided":{"type":"boolean"},"edgeWear":{"properties":{"color":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"crisp":{"type":"number"},"metallic":{"type":"number"},"noiseFrequency":{"type":"number"},"roughness":{"type":"number"}},"required":["color","roughness","metallic","noiseFrequency","crisp"],"type":"object"},"emissive":{"type":"number"},"emissiveColor":{"description":"Linear [r, g, b].","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"emissiveStrength":{"type":"number"},"emissiveTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"filter":{"enum":["linear","nearest"],"type":"string"},"fur":{"properties":{"flowImage":{"properties":{"height":{"type":"integer"},"pixels":{"type":"string"},"width":{"type":"integer"}},"required":["width","height","pixels"],"type":"object"},"groom":{"properties":{"cardSegments":{"type":"integer"},"cardWidth":{"type":"number"},"clumping":{"type":"number"},"colorNoise":{"type":"number"},"comb":{"items":{"properties":{"center":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"direction":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"radius":{"type":"number"},"strength":{"type":"number"}},"type":"object"},"type":"array"},"combDirection":{"type":"string"},"combStrength":{"type":"number"},"curl":{"type":"number"},"cut":{"items":{"properties":{"center":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"length":{"type":"number"},"radius":{"type":"number"},"strength":{"type":"number"}},"type":"object"},"type":"array"},"density":{"type":"number"},"flowTexture":{"type":"string"},"frizz":{"type":"number"},"gravity":{"type":"number"},"length":{"type":"number"},"lengthVariation":{"type":"number"},"lod":{"properties":{"cards":{"items":{"type":"number"},"type":"array"},"distances":{"items":{"type":"number"},"type":"array"},"shells":{"items":{"type":"integer"},"type":"array"}},"type":"object"},"mask":{"properties":{"invert":{"type":"boolean"},"parts":{"items":{"type":"string"},"type":"array"},"texture":{"type":"string"},"vertexPaint":{"type":"string"}},"type":"object"},"previewMesh":{"type":"string"},"rootColor":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"seed":{"type":"integer"},"shells":{"type":"integer"},"specular":{"type":"number"},"stiffness":{"type":"number"},"strandsPerCard":{"type":"integer"},"style":{"enum":["shell","cards","strands"],"type":"string"},"thickness":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"tipColor":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"wind":{"type":"number"}},"type":"object"},"maskImage":{"properties":{"height":{"type":"integer"},"pixels":{"type":"string"},"width":{"type":"integer"}},"required":["width","height","pixels"],"type":"object"}},"type":"object"},"metallic":{"type":"number"},"metallicRoughnessTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"mipFilter":{"enum":["linear","nearest","none"],"type":"string"},"normalScale":{"type":"number"},"normalTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"occlusionStrength":{"type":"number"},"occlusionTexture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"roughness":{"type":"number"},"shading":{"enum":["pbr","blinnPhong"],"type":"string"},"shininess":{"type":"number"},"specular":{"type":"number"},"texture":{"description":"An asset: \"asset:<id>\" (a bare id works too) for a file, \"asset:<id>#<object>\" for one object in it (see editor://assets).","pattern":"^(asset:)?[0-9a-fA-F-]{32,36}(#.+)?$","type":"string"},"translucency":{"type":"number"},"uvOffset":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"uvRotation":{"type":"number"},"uvScale":{"description":"[x, y]","items":{"type":"number"},"maxItems":2,"minItems":2,"type":"array"},"wind":{"properties":{"bend":{"type":"number"},"flutter":{"type":"number"},"height":{"type":"number"},"origin":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"up":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"type":"object"}},"type":"object"},"reset":{"type":"boolean"},"transient":{"type":"boolean"}},"required":["asset","material"],"type":"object"}"#
private let SNAPSHOT_PICK_OUT = #"{"properties":{"direction":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"distance":{"type":"number"},"entity":{"description":"An entity id: 32 lowercase hex digits (see the editor://scene resource).","pattern":"^[0-9a-f]{32}$","type":"string"},"hit":{"type":"boolean"},"name":{"type":"string"},"normal":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"origin":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"},"point":{"description":"[x, y, z]","items":{"type":"number"},"maxItems":3,"minItems":3,"type":"array"}},"required":["hit","origin","direction"],"type":"object"}"#
