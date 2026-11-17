import Foundation
import Testing
@testable import EngineMCP

// `Editor --mcp` attaching to a running host: the relay between a stdio client (pipes here)
// and the host's Streamable HTTP transport on a real loopback socket.

@MainActor private final class EchoTools: MCPToolProvider {
    var tools: [MCPTool] { [MCPTool(name: "echo", description: "Returns its arguments.")] }
    func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        context.progress(1, total: 1, message: "echoing")
        return .result(.success(arguments))
    }
}

/// Collects what the relay writes to the client.
private final class Collected: MCPOutput, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [JSON] = []
    var all: [JSON] { lock.withLock { messages } }
    func send(_ message: JSON) { lock.withLock { messages.append(message) } }
}

@MainActor @Suite(.serialized) struct MCPStdioRelayTests {
    /// The server holds its tool provider weakly.
    private let tools = EchoTools()

    private func host() throws -> (MCPServer, MCPHTTPTransport, URL) {
        let server = MCPServer(info: .init(name: "relay-test", version: "1"))
        server.log = { _ in }
        server.tools = tools
        let transport = try MCPHTTPTransport.start(inbox: server.inbox, port: 0, token: MCPHTTPTransport.makeToken())
        transport.log = { _ in }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("relay-\(UUID().uuidString)/mcp.json")
        try MCPConfigFile(url: transport.url, token: transport.token, serverName: "acro").write(to: file)
        return (server, transport, file)
    }

    /// Pumps `server` until `done` or a few seconds pass.
    private func pump(_ server: MCPServer, until done: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(10)
        while !done() && Date() < deadline {
            server.pump()
            try await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    @Test func findsOnlyALiveHost() async throws {
        let (server, transport, file) = try host()
        defer { transport.stop() }
        let found = Task.detached { MCPStdioRelay.liveHost(configAt: file) }
        try await pump(server) { false == false }
        #expect(await found.value?.url == transport.url)

        // Another token (another host on the port), a dead pid, a detached file, no file.
        try MCPConfigFile(url: transport.url, token: MCPHTTPTransport.makeToken(), serverName: "acro").write(to: file)
        #expect(MCPStdioRelay.liveHost(configAt: file) == nil)
        try MCPConfigFile(url: transport.url, token: transport.token, pid: 0, serverName: "acro").write(to: file)
        #expect(MCPStdioRelay.liveHost(configAt: file) == nil)
        try MCPConfigFile(url: transport.url, token: transport.token, pid: Int32.max - 1, serverName: "acro").write(to: file)
        #expect(MCPStdioRelay.liveHost(configAt: file) == nil)
        #expect(MCPStdioRelay.liveHost(configAt: file.deletingLastPathComponent().appendingPathComponent("none.json")) == nil)
    }

    @Test func relaysAClientToTheHost() async throws {
        let (server, transport, file) = try host()
        defer { transport.stop() }
        let config = try #require(MCPStdioRelay.liveHost(configAt: file))
        let collected = Collected()
        let relay = MCPStdioRelay(config: config, output: collected)
        let input = Pipe()
        let finished = Task.detached { relay.relay(input: input.fileHandleForReading) }
        func write(_ message: JSON) { input.fileHandleForWriting.write(message.data() + Data("\n".utf8)) }

        write(["jsonrpc": "2.0", "id": 1, "method": "initialize",
               "params": ["protocolVersion": "2025-06-18", "capabilities": [:], "clientInfo": ["name": "t", "version": "1"]]])
        try await pump(server) { collected.all.count >= 1 }
        #expect(collected.all.first?["result"]?["protocolVersion"] == "2025-06-18")

        // Right after the notification: it must reach the host first.
        write(["jsonrpc": "2.0", "method": "notifications/initialized"])
        write(["jsonrpc": "2.0", "id": 2, "method": "tools/call",
               "params": ["name": "echo", "arguments": ["hello": "world"], "_meta": ["progressToken": 7]]])
        try await pump(server) { collected.all.contains { $0["id"] == 2 } }
        let call = collected.all.dropFirst()
        #expect(call.map { $0["method"] } == ["notifications/progress", nil])
        #expect(call.last?["result"]?["structuredContent"] == ["hello": "world"])

        // The host's own notifications arrive over the event stream.
        let before = collected.all.count
        try await pump(server) {
            server.toolsChanged()
            return collected.all.count > before
        }
        #expect(collected.all.last?["method"] == "notifications/tools/list_changed")

        // End of input: the relay deletes the session and returns.
        input.fileHandleForWriting.closeFile()
        let code = Task.detached { await finished.value }
        try await pump(server) { false == false }
        #expect(await code.value == 0)
    }
}
