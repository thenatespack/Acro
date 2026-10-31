import EngineMCP
import Foundation
import Testing
@testable import EditorCore
@testable import Engine

// Perception tools without a window: screenshots through a host that "renders" on the CPU (one
// pick per pixel), so the place → screenshot → pick flow runs end to end; picking in every
// view, raycasts, the console with filters, stats and diagnostics, and what headless says.

@MainActor private func makeSession() -> EditorSession {
    let log = EditorLog()
    log.echoesToStandardOutput = false
    let session = EditorSession(document: EditorDocument(), log: log)
    session.newDocument()
    return session
}

/// A host whose screenshots are drawn by casting a ray through every pixel: the entity
/// `highlight` is red, anything else gray, nothing black. Captures finish on `renderFrame()`,
/// like the app's at the end of a frame.
@MainActor private final class CPUHost: EditorHost {
    unowned let session: EditorSession
    var highlight: EntityID?
    var pending: [(request: ScreenshotRequest, future: CommandFuture<Image>)] = []
    var viewport: SceneView

    init(session: EditorSession) {
        self.session = session
        viewport = SceneView(view: Mat4.lookAt(eye: Vec3(7, 4.5, 9), target: Vec3(0, 1, 0)),
                             projection: Mat4.perspective(fovY: 1, aspect: 64.0 / 48, near: 0.05, far: 500))
    }

    func resetLayout() {}
    func frameSelection() {}
    var viewportView: (view: SceneView, width: Int, height: Int)? { (viewport, 64, 48) }
    var frameStats: EditorStatsSnapshot? {
        var stats = EditorStatsSnapshot()
        stats.frame.fps = 120
        stats.frame.gpuTime = 0.002
        stats.frame.gpuPassTimes = [GPUPassTime(name: "viewport", seconds: 0.0015)]
        stats.backend = "metal"
        stats.viewportSize = (64, 48)
        return stats
    }

    func capture(_ request: ScreenshotRequest) -> CommandFuture<Image>? {
        guard request.source == .viewport || request.source == .game || request.source == .camera else { return nil }
        let future = CommandFuture<Image>()
        pending.append((request, future))
        return future
    }

    func renderFrame() {
        for (request, future) in pending {
            let view = request.view ?? viewport
            let projection = ViewportProjection(view, size: Vec2(Float(request.width), Float(request.height)))
            var pixels: [UInt8] = []
            for y in 0..<request.height {
                for x in 0..<request.width {
                    let hit = session.pick(projection.ray(through: Vec2(Float(x) + 0.5, Float(y) + 0.5)))
                    let color: [UInt8] = !hit.hit ? [0, 0, 0, 255] : hit.entity == highlight ? [255, 0, 0, 255] : [128, 128, 128, 255]
                    pixels += color
                }
            }
            future.resolve(Image(width: request.width, height: request.height, pixels: pixels))
        }
        pending.removeAll()
    }
}

/// An editor MCP server with an initialized in-memory client.
@MainActor private struct Client {
    let session = makeSession()
    let mcp: EditorMCP
    let connection: MCPMemoryConnection

    init() {
        mcp = EditorMCP(session: session)
        mcp.server.log = { _ in }
        connection = MCPMemoryConnection(inbox: mcp.server.inbox)
        _ = call("initialize", ["protocolVersion": "2025-06-18", "capabilities": [:]])
    }

    /// Sends a request and pumps; returns its reply's result, or nil while it is pending.
    @discardableResult
    func call(_ method: String, _ params: JSON? = nil, id: String = UUID().uuidString) -> JSON? {
        var message: JSON = ["jsonrpc": "2.0", "id": .string(id), "method": .string(method)]
        if let params { message["params"] = params }
        connection.send(message)
        mcp.pump()
        return reply(id)
    }

    func reply(_ id: String) -> JSON? {
        guard let reply = connection.output.take().first(where: { $0["id"] == .string(id) }) else { return nil }
        return reply["result"] ?? reply["error"] ?? nil
    }

    @discardableResult
    func tool(_ name: String, _ arguments: JSON = [:], sourceLocation: SourceLocation = #_sourceLocation) -> JSON {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments]) ?? nil
        #expect(result["isError"] == false, "\(name): \(result["content"]?.arrayValue?.first?["text"] ?? nil)",
                sourceLocation: sourceLocation)
        return result["structuredContent"] ?? nil
    }

    func failingTool(_ name: String, _ arguments: JSON = [:]) -> String {
        let result = call("tools/call", ["name": .string(name), "arguments": arguments]) ?? nil
        #expect(result["isError"] == true, "\(name) should fail")
        return result["content"]?.arrayValue?.first?["text"]?.stringValue ?? ""
    }
}

@MainActor @Suite struct PerceptionToolsTests {
    @Test func placeScreenshotAndPick() throws {
        let client = Client()
        let host = CPUHost(session: client.session)
        client.session.host = host

        // Place an object where the viewport camera looks.
        let placed = client.tool("entity.create", ["template": "cube", "position": [0, 2.5, 0], "name": "Target"])
        let target = try #require(placed["entity"]?.stringValue.flatMap(EntityID.init))
        host.highlight = target
        client.session.tick(dt: 0)

        // The screenshot answers after the frame that renders it, not before.
        let requestID = "shot"
        #expect(client.call("tools/call", ["name": "view.screenshot", "arguments": [:]], id: requestID) == nil)
        client.mcp.pump()
        #expect(client.reply(requestID) == nil)
        host.renderFrame()
        client.mcp.pump()
        let result = try #require(client.reply(requestID))
        #expect(result["isError"] == false)
        let content = result["content"]?.arrayValue ?? []
        let image = try #require(content.first { $0["type"] == "image" })
        #expect(image["mimeType"] == "image/png")
        // The structured result describes the image without repeating its data.
        #expect(result["structuredContent"]?["image"] == ["mimeType": "image/png", "width": 64, "height": 48])
        #expect(result["structuredContent"]?["source"] == "viewport")
        let png = try #require(image["data"]?.stringValue.flatMap { Data(base64Encoded: $0) })
        let decoded = try ImageDecoder.decode(png)
        #expect(decoded.width == 64 && decoded.height == 48)

        // Find the red pixels and pick one of them: it is the placed cube.
        var red: [(Int, Int)] = []
        for y in 0..<decoded.height {
            for x in 0..<decoded.width where decoded.pixels[(y * decoded.width + x) * 4] == 255 { red.append((x, y)) }
        }
        let (x, y) = try #require(red.isEmpty ? nil : red[red.count / 2])
        let pick = client.tool("view.pick", ["x": .double(Double(x) + 0.5), "y": .double(Double(y) + 0.5)])
        #expect(pick["hit"] == true)
        #expect(pick["entity"]?.stringValue == target.description)
        #expect(pick["name"] == "Target")
        let point = try #require(pick["point"]?.arrayValue?.compactMap { $0.doubleValue })
        #expect(abs(point[1] - 2.5) <= 0.5 + 1e-4)  // on the unit cube around (0, 2.5, 0)

        // The same view scaled down: pixel coordinates follow the smaller image.
        let small = "small"
        client.call("tools/call", ["name": "view.screenshot", "arguments": ["maxSize": 32]], id: small)
        host.renderFrame()
        client.mcp.pump()
        #expect(client.reply(small)?["structuredContent"]?["image"] == ["mimeType": "image/png", "width": 32, "height": 24])
        let halfPick = client.tool("view.pick", ["x": .double((Double(x) + 0.5) / 2), "y": .double((Double(y) + 0.5) / 2), "maxSize": 32])
        #expect(halfPick["entity"]?.stringValue == target.description)
    }

    @Test func cameraViewsPickHeadless() throws {
        let client = Client()
        let session = client.session
        #expect(client.failingTool("view.screenshot").contains("headless"))
        #expect(client.failingTool("view.pick", ["x": 1, "y": 1]).contains("viewport needs the editor window"))

        let placed = client.tool("entity.create", ["template": "sphere", "position": [40, 1, 40]])
        session.tick(dt: 0)
        let sphere = placed["entity"]?.stringValue
        // A camera that doesn't move the user's view: the center pixel is the sphere.
        let center = client.tool("view.pick", ["source": "camera", "eye": [40, 1, 30], "target": [40, 1, 40], "width": 200,
                                               "height": 100, "x": 100, "y": 50])
        #expect(center["entity"]?.stringValue == sphere)
        let point = try #require(center["point"]?.arrayValue?.compactMap { $0.doubleValue })
        #expect(abs(point[2] - 39.5) < 0.02)  // the near side of a unit sphere at z 40
        let normal = try #require(center["normal"]?.arrayValue?.compactMap { $0.doubleValue })
        #expect(normal[2] < -0.99)
        let corner = client.tool("view.pick", ["source": "camera", "eye": [40, 1, 30], "target": [40, 1, 40], "width": 200,
                                               "height": 100, "x": 0, "y": 0])
        #expect(corner["hit"] == false)

        // The game camera's center ray is the same as a raycast along it.
        let game = client.tool("view.pick", ["source": "game", "x": 640, "y": 360])
        let origin = try #require(game["origin"]), direction = try #require(game["direction"])
        let ray = client.tool("scene.raycast", ["origin": origin, "direction": direction])
        #expect(ray["entity"] == game["entity"] && ray["hit"] == true)
        #expect(client.tool("scene.raycast", ["origin": origin, "direction": direction, "maxDistance": 0.01])["hit"] == false)
        #expect(client.failingTool("view.pick", ["source": "camera", "x": 0, "y": 0]).contains("needs `eye` and `target`"))
    }

    @Test func consoleStatsAndDiagnostics() throws {
        let client = Client()
        let session = client.session
        session.log.warning("Something odd")
        session.log.error("Validation Error: [ VUID-test ] made up")
        let all = client.tool("log.read")
        #expect(all["entries"]?.arrayValue?.contains { $0["message"] == "New scene" } == true)
        let errors = client.tool("log.read", ["level": "error"])["entries"]?.arrayValue ?? []
        #expect(errors.compactMap { $0["message"]?.stringValue } == ["Validation Error: [ VUID-test ] made up"])
        let next = try #require(all["next"]?.intValue)
        session.log.info("Later")
        let later = client.tool("log.read", ["since": .int(Int64(next))])["entries"]?.arrayValue ?? []
        #expect(later.compactMap { $0["message"]?.stringValue } == ["Later"])
        #expect(client.tool("log.read", ["contains": "ODD"])["entries"]?.arrayValue?.count == 1)
        let warnings = try JSON(parsing: client.call("resources/read", ["uri": "editor://log/warning"])?["contents"]?
            .arrayValue?.first?["text"]?.stringValue ?? "")
        #expect(warnings.arrayValue?.compactMap { $0["level"]?.stringValue } == ["warn", "error"])

        // Headless: no frame numbers.
        let headless = client.tool("stats.get")
        #expect(headless["fps"] == nil && headless["entities"] == .int(Int64(session.world.entityCount)))
        let host = CPUHost(session: session)
        session.host = host
        let stats = client.tool("stats.get")
        #expect(stats["fps"] == 120 && stats["gpuMilliseconds"] == 2 && stats["backend"] == "metal")
        #expect(stats["gpuPasses"] == [["name": "viewport", "milliseconds": 1.5]])
        #expect(stats["viewport"] == [64, 48])

        let diagnostics = client.tool("diagnostics.get")
        #expect(diagnostics["validation"]?.arrayValue?.count == 1)
        #expect(diagnostics["problems"]?.arrayValue?.count == 2)
        #expect(diagnostics["importErrors"] == [])
    }

    @Test func diagnosticsListImportErrors() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PerceptionToolsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let client = Client()
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Assets"), withIntermediateDirectories: true)
        try Data("not a png".utf8).write(to: folder.appendingPathComponent("Assets/broken.png"))
        #expect(client.session.newProject(path: folder.path))
        client.session.assets?.waitForAll()
        client.session.assets?.pump()
        let diagnostics = client.tool("diagnostics.get")
        let problems = diagnostics["importErrors"]?.arrayValue ?? []
        #expect(problems.compactMap { $0["path"]?.stringValue } == ["broken.png"])
        #expect(problems.first?["message"]?.stringValue?.isEmpty == false)
        let resource = try JSON(parsing: client.call("resources/read", ["uri": "editor://diagnostics"])?["contents"]?
            .arrayValue?.first?["text"]?.stringValue ?? "")
        #expect(resource["importErrors"] == diagnostics["importErrors"])
        // Thumbnails need the window's renderer.
        #expect(client.failingTool("view.screenshot", ["source": "thumbnail", "asset": "asset:00000000000000000000000000000001"])
            .contains("headless"))
    }
}
