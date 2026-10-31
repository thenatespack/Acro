import Foundation
import Testing
@testable import EngineMCP
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// The Streamable HTTP transport on a real loopback socket: authentication, DNS-rebinding
// checks, sessions, JSON and event-stream responses.

@MainActor private final class EchoTools: MCPToolProvider {
    var tools: [MCPTool] { [MCPTool(name: "echo", description: "Returns its arguments.")] }
    func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        context.progress(1, total: 1, message: "echoing")
        return .result(.success(arguments))
    }
}

/// Pumps `server` on the main actor until `body` finishes (the transport waits for answers).
@MainActor private func pumping<T: Sendable>(_ server: MCPServer, _ body: @escaping @Sendable () async throws -> T) async throws -> T {
    let task = Task.detached { try await body() }
    let done = Flag()
    Task.detached {
        _ = try? await task.value
        done.set()
    }
    while !done.isSet {
        server.pump()
        try await Task.sleep(nanoseconds: 2_000_000)
    }
    return try await task.value
}

private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    var isSet: Bool { lock.withLock { value } }
    func set() { lock.withLock { value = true } }
}

private struct Reply: Sendable {
    var status: Int
    var headers: [String: String]
    var body: Data
    var json: JSON? { try? JSON(data: body) }
}

private func send(_ url: String, method: String = "POST", body: JSON? = nil, headers: [String: String]) async throws -> Reply {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = method
    request.httpBody = body?.data()
    for (name, value) in headers { request.setValue(value, forHTTPHeaderField: name) }
    let (data, response) = try await URLSession.shared.data(for: request)
    let http = response as! HTTPURLResponse
    var lowered: [String: String] = [:]
    for (name, value) in http.allHeaderFields { lowered[String(describing: name).lowercased()] = String(describing: value) }
    return Reply(status: http.statusCode, headers: lowered, body: data)
}

@MainActor @Suite(.serialized) struct MCPHTTPTransportTests {
    @Test func servesSessionsBehindABearerToken() async throws {
        let server = MCPServer(info: .init(name: "http-test", version: "1"))
        server.log = { _ in }
        let tools = EchoTools()
        server.tools = tools
        let token = MCPHTTPTransport.makeToken()
        let transport = try MCPHTTPTransport.start(inbox: server.inbox, port: 0, token: token)
        transport.log = { _ in }
        defer { transport.stop() }
        let url = transport.url
        #expect(url.hasPrefix("http://127.0.0.1:"))
        let auth = ["Authorization": "Bearer \(token)", "Content-Type": "application/json", "Accept": "application/json, text/event-stream"]
        let initialize: JSON = ["jsonrpc": "2.0", "id": 1, "method": "initialize",
                                "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "t", "version": "1"]]]

        // No token, a wrong token, a foreign origin: refused before the server sees anything.
        #expect(try await send(url, body: initialize, headers: ["Accept": "application/json"]).status == 401)
        #expect(try await send(url, body: initialize, headers: ["Authorization": "Bearer nope"]).status == 401)
        var foreign = auth
        foreign["Origin"] = "https://evil.example"
        #expect(try await send(url, body: initialize, headers: foreign).status == 403)
        var local = auth
        local["Origin"] = "http://localhost:3000"
        local["Accept"] = "application/json"

        // initialize (JSON response) creates a session.
        let reply = try await pumping(server) { [local] in try await send(url, body: initialize, headers: local) }
        #expect(reply.status == 200)
        #expect(reply.json?["result"]?["protocolVersion"] == "2025-06-18")
        let sessionID = try #require(reply.headers["mcp-session-id"])

        var session = auth
        session["Mcp-Session-Id"] = sessionID
        session["MCP-Protocol-Version"] = "2025-06-18"
        let initialized = try await send(url, body: ["jsonrpc": "2.0", "method": "notifications/initialized"], headers: session)
        #expect(initialized.status == 202)

        // A request without the session, with an unknown one, with an unsupported version.
        #expect(try await send(url, body: ["jsonrpc": "2.0", "id": 2, "method": "ping"], headers: auth).status == 400)
        var unknown = session
        unknown["Mcp-Session-Id"] = "0123"
        #expect(try await send(url, body: ["jsonrpc": "2.0", "id": 2, "method": "ping"], headers: unknown).status == 404)
        var future = session
        future["MCP-Protocol-Version"] = "2099-01-01"
        #expect(try await send(url, body: ["jsonrpc": "2.0", "id": 2, "method": "ping"], headers: future).status == 400)

        // tools/call as an event stream: the progress notification, then the response.
        let call: JSON = ["jsonrpc": "2.0", "id": 3, "method": "tools/call",
                          "params": ["name": "echo", "arguments": ["hello": "world"], "_meta": ["progressToken": 7]]]
        let streamed = try await pumping(server) { [session] in try await send(url, body: call, headers: session) }
        #expect(streamed.status == 200)
        #expect(streamed.headers["content-type"] == "text/event-stream")
        let events = String(decoding: streamed.body, as: UTF8.self).components(separatedBy: "\n")
            .filter { $0.hasPrefix("data: ") }.compactMap { try? JSON(parsing: String($0.dropFirst(6))) }
        #expect(events.map { $0["method"] } == ["notifications/progress", nil])
        #expect(events.last?["result"]?["structuredContent"] == ["hello": "world"])

        // DELETE ends the session.
        let deleted = try await pumping(server) { [session] in try await send(url, method: "DELETE", headers: session) }
        #expect(deleted.status == 200)
        #expect(try await send(url, body: ["jsonrpc": "2.0", "id": 4, "method": "ping"], headers: session).status == 404)
    }

    @Test func loopbackChecks() {
        #expect(MCPHTTPTransport.isLoopback(host: "127.0.0.1:7333"))
        #expect(MCPHTTPTransport.isLoopback(host: "localhost"))
        #expect(MCPHTTPTransport.isLoopback(host: "[::1]:80"))
        #expect(!MCPHTTPTransport.isLoopback(host: "evil.example:7333"))
        #expect(!MCPHTTPTransport.isLoopback(host: "127.0.0.1.evil.example"))
        #expect(MCPHTTPTransport.isLoopback(origin: "http://localhost:5173"))
        #expect(MCPHTTPTransport.isLoopback(origin: "http://[::1]:5173"))
        #expect(!MCPHTTPTransport.isLoopback(origin: "null"))
        #expect(!MCPHTTPTransport.isLoopback(origin: "https://attacker.example"))
        #expect(MCPHTTPTransport.isValid(authorization: "Bearer abc", token: "abc"))
        #expect(MCPHTTPTransport.isValid(authorization: "bearer abc", token: "abc"))
        #expect(!MCPHTTPTransport.isValid(authorization: "Bearer abd", token: "abc"))
        #expect(!MCPHTTPTransport.isValid(authorization: "Basic abc", token: "abc"))
        #expect(!MCPHTTPTransport.isValid(authorization: "Bearer ", token: ""))
    }

    @Test func configFileKeepsItsToken() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mcp-\(UUID().uuidString)/mcp.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let token = MCPHTTPTransport.makeToken()
        try MCPConfigFile(url: "http://127.0.0.1:1/mcp", token: token, serverName: "x").write(to: url)
        #expect(MCPConfigFile.existingToken(at: url) == token)
        let json = try JSON(data: Data(contentsOf: url))
        #expect(json["mcpServers"]?["x"]?["headers"]?["Authorization"] == .string("Bearer \(token)"))
        #if !os(Windows)
        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        #expect(permissions == 0o600)
        #endif
    }
}
