import Foundation
import Testing
@testable import EngineMCP

// The protocol over the in-memory transport and a real stdio pipe: initialize and version
// negotiation, tools, resources and subscriptions, notifications, cancellation, progress.

@MainActor private final class FakeTools: MCPToolProvider, MCPResourceProvider {
    var tools: [MCPTool] = [
        MCPTool(name: "math.add", title: "Add", description: "Adds a and b.",
                inputSchema: ["type": "object", "properties": ["a": ["type": "number"], "b": ["type": "number"]]],
                annotations: MCPToolAnnotations(readOnlyHint: true)),
        MCPTool(name: "slow", description: "Finishes after `steps` polls."),
    ]
    var counter = "1"
    var polls = 0

    func callTool(_ name: String, arguments: JSON, context: MCPCallContext) -> MCPToolOutcome {
        switch name {
        case "math.add":
            guard let a = arguments["a"]?.doubleValue, let b = arguments["b"]?.doubleValue else {
                return .result(.error("a and b must be numbers"))
            }
            return .result(.success(["sum": .double(a + b)]))
        default:
            let steps = arguments["steps"]?.intValue ?? 3
            return .pending { [unowned self] context in
                polls += 1
                if polls >= steps { return .success(["polls": .int(Int64(polls))]) }
                context.progress(Double(polls), total: Double(steps), message: "step \(polls)")
                return nil
            }
        }
    }

    var resources: [MCPResource] { [MCPResource(uri: "test://counter", name: "counter", mimeType: "text/plain")] }
    var resourceTemplates: [MCPResourceTemplate] { [MCPResourceTemplate(uriTemplate: "test://item/{id}", name: "item")] }

    func readResource(_ uri: String) -> [MCPResourceContents]? {
        uri == "test://counter" ? [MCPResourceContents(uri: uri, mimeType: "text/plain", text: counter)] : nil
    }
}

@MainActor private struct Harness {
    let server = MCPServer(info: .init(name: "test", version: "1.0"), instructions: "Use it.")
    let provider = FakeTools()
    let client: MCPMemoryConnection
    var nextID: Int64 = 0

    init() {
        server.log = { _ in }
        server.tools = provider
        server.resources = provider
        client = MCPMemoryConnection(inbox: server.inbox)
    }

    /// Sends a request, pumps once and returns everything that came back (notifications, then the response).
    mutating func request(_ method: String, _ params: JSON? = nil) -> [JSON] {
        nextID += 1
        var message: JSON = ["jsonrpc": "2.0", "id": .int(nextID), "method": .string(method)]
        if let params { message["params"] = params }
        client.send(message)
        server.pump()
        return client.output.take()
    }

    /// The response's `result` (or `error`).
    mutating func call(_ method: String, _ params: JSON? = nil) -> JSON {
        let reply = request(method, params).last { $0["id"] != nil } ?? nil
        return reply["result"] ?? reply["error"] ?? nil
    }

    mutating func initialize(_ version: String = MCPProtocol.v2025_06_18) -> JSON {
        let result = call("initialize", ["protocolVersion": .string(version), "capabilities": [:],
                                         "clientInfo": ["name": "tests", "version": "1"]])
        client.send(["jsonrpc": "2.0", "method": "notifications/initialized"])
        server.pump()
        return result
    }
}

@MainActor @Suite struct MCPServerTests {
    @Test func initializeNegotiatesTheProtocolVersion() {
        var h = Harness()
        let result = h.initialize()
        #expect(result["protocolVersion"] == "2025-06-18")
        #expect(result["serverInfo"]?["name"] == "test")
        #expect(result["instructions"] == "Use it.")
        #expect(result["capabilities"]?["tools"]?["listChanged"] == true)
        #expect(result["capabilities"]?["resources"]?["subscribe"] == true)
        // Older revisions we know are kept; unknown ones get the newest.
        for (asked, answered) in [("2024-11-05", "2024-11-05"), ("2025-03-26", "2025-03-26"), ("2099-01-01", MCPProtocol.latest)] {
            var other = Harness()
            #expect(other.initialize(asked)["protocolVersion"] == .string(answered))
        }
    }

    @Test func pingAndUnknownMethods() {
        var h = Harness()
        _ = h.initialize()
        #expect(h.call("ping") == .object([:]))
        #expect(h.call("nope")["code"] == -32601)
        // Malformed messages get JSON-RPC errors.
        h.client.send(["jsonrpc": "2.0", "id": 9, "method": 5])
        h.client.send(["jsonrpc": "1.0", "id": 10, "method": "ping"])
        h.server.pump()
        #expect(h.client.output.take().map { $0["error"]?["code"] } == [-32600, -32600])
    }

    @Test func listsAndCallsTools() {
        var h = Harness()
        _ = h.initialize()
        let tools = h.call("tools/list")["tools"]?.arrayValue ?? []
        #expect(tools.map { $0["name"] } == ["math.add", "slow"])
        #expect(tools[0]["title"] == "Add")
        #expect(tools[0]["annotations"]?["readOnlyHint"] == true)
        #expect(tools[0]["inputSchema"]?["properties"]?["a"] == ["type": "number"])

        let sum = h.call("tools/call", ["name": "math.add", "arguments": ["a": 2, "b": 3.5]])
        #expect(sum["isError"] == false)
        #expect(sum["structuredContent"] == ["sum": 5.5])
        #expect(sum["content"]?.arrayValue?.first?["type"] == "text")

        let failed = h.call("tools/call", ["name": "math.add", "arguments": ["a": "x"]])
        #expect(failed["isError"] == true)
        #expect(failed["content"]?.arrayValue?.first?["text"] == "a and b must be numbers")
        #expect(h.call("tools/call", ["name": "missing"])["code"] == -32602)
        #expect(h.call("tools/call", ["name": "math.add", "arguments": [1, 2]])["code"] == -32602)
    }

    @Test func oldClientsGetNoStructuredContentOrOutputSchema() {
        var h = Harness()
        h.provider.tools[0].outputSchema = ["type": "object"]
        _ = h.initialize("2025-03-26")
        #expect(h.call("tools/list")["tools"]?.arrayValue?.first?["outputSchema"] == nil)
        let sum = h.call("tools/call", ["name": "math.add", "arguments": ["a": 1, "b": 1]])
        #expect(sum["structuredContent"] == nil)
        #expect(sum["content"]?.arrayValue?.first?["text"]?.stringValue?.contains("2") == true)
    }

    @Test func pendingCallsReportProgressUntilDone() {
        var h = Harness()
        _ = h.initialize()
        h.client.send(["jsonrpc": "2.0", "id": "slow-1", "method": "tools/call",
                       "params": ["name": "slow", "arguments": ["steps": 3], "_meta": ["progressToken": "p"]]])
        h.server.pump()
        var messages = h.client.output.take()
        #expect(messages.count == 1)
        #expect(messages[0]["method"] == "notifications/progress")
        #expect(messages[0]["params"] == ["progressToken": "p", "progress": 1.0, "total": 3.0, "message": "step 1"])
        #expect(h.server.hasPendingCalls)
        h.server.pump()
        h.server.pump()
        messages = h.client.output.take()
        #expect(messages.map { $0["method"] } == ["notifications/progress", nil])
        #expect(messages.last?["id"] == "slow-1")
        #expect(messages.last?["result"]?["structuredContent"] == ["polls": 3])
        #expect(!h.server.hasPendingCalls)
    }

    @Test func cancellationDropsQueuedAndPendingRequests() {
        var h = Harness()
        _ = h.initialize()
        // Queued and cancelled before the pump: never runs, never answered.
        h.client.send(["jsonrpc": "2.0", "id": 50, "method": "tools/call", "params": ["name": "math.add", "arguments": ["a": 1, "b": 2]]])
        h.client.send(["jsonrpc": "2.0", "method": "notifications/cancelled", "params": ["requestId": 50]])
        h.server.pump()
        #expect(h.client.output.take().isEmpty)
        // Pending, then cancelled: stops being polled.
        h.client.send(["jsonrpc": "2.0", "id": 51, "method": "tools/call", "params": ["name": "slow", "arguments": ["steps": 100]]])
        h.server.pump()
        #expect(h.server.hasPendingCalls)
        h.client.send(["jsonrpc": "2.0", "method": "notifications/cancelled", "params": ["requestId": 51, "reason": "bored"]])
        h.server.pump()
        #expect(!h.server.hasPendingCalls)
        #expect(h.client.output.take().isEmpty)
    }

    @Test func resourcesAndSubscriptions() {
        var h = Harness()
        _ = h.initialize()
        #expect(h.call("resources/list")["resources"] == [["uri": "test://counter", "name": "counter", "mimeType": "text/plain"]])
        #expect(h.call("resources/templates/list")["resourceTemplates"]?.arrayValue?.first?["uriTemplate"] == "test://item/{id}")
        #expect(h.call("resources/read", ["uri": "test://counter"])["contents"]?.arrayValue?.first?["text"] == "1")
        #expect(h.call("resources/read", ["uri": "test://nope"])["code"] == -32002)

        #expect(h.call("resources/subscribe", ["uri": "test://counter"]) == .object([:]))
        #expect(h.server.subscribedResources == ["test://counter"])
        h.server.resourceUpdated("test://counter")
        h.server.resourceUpdated("test://other")
        #expect(h.client.output.take() == [["jsonrpc": "2.0", "method": "notifications/resources/updated",
                                            "params": ["uri": "test://counter"]]])
        _ = h.call("resources/unsubscribe", ["uri": "test://counter"])
        h.server.resourceUpdated("test://counter")
        #expect(h.client.output.take().isEmpty)
    }

    @Test func listChangesAreBroadcastToEveryClient() {
        var h = Harness()
        _ = h.initialize()
        let second = MCPMemoryConnection(inbox: h.server.inbox)
        second.send(["jsonrpc": "2.0", "id": 1, "method": "initialize", "params": ["protocolVersion": "2025-06-18"]])
        h.server.pump()
        _ = second.output.take()
        h.server.toolsChanged()
        h.server.resourcesChanged()
        let expected: [JSON] = [["jsonrpc": "2.0", "method": "notifications/tools/list_changed"],
                                ["jsonrpc": "2.0", "method": "notifications/resources/list_changed"]]
        #expect(h.client.output.take() == expected)
        #expect(second.output.take() == expected)
        // A client that went away gets nothing.
        second.close()
        h.server.pump()
        h.server.toolsChanged()
        #expect(second.output.take().isEmpty)
        #expect(h.server.clientCount == 1)
    }

    @Test func batchesAreAnsweredMessageByMessage() {
        let h = Harness()
        h.server.inbox.post(.messages([["jsonrpc": "2.0", "id": 1, "method": "ping"], ["jsonrpc": "2.0", "id": 2, "method": "tools/list"]],
                                      session: h.client.session, reply: h.client.output))
        h.server.pump()
        #expect(h.client.output.take().map { $0["id"] } == [1, 2])
    }

    @Test func toolNames() {
        #expect(MCPTool.isValidName("entity.create"))
        #expect(MCPTool.isValidName("a_b-c.D9"))
        #expect(!MCPTool.isValidName(""))
        #expect(!MCPTool.isValidName("has space"))
        #expect(!MCPTool.isValidName("slash/name"))
        #expect(!MCPTool.isValidName(String(repeating: "a", count: 129)))
    }

    @Test func jsonRoundTripsAndIsCompactAndSorted() throws {
        let value: JSON = ["b": [1, 2.5, "x", nil, true], "a": ["nested": "a/b"]]
        #expect(value.text == #"{"a":{"nested":"a/b"},"b":[1,2.5,"x",null,true]}"#)
        #expect(try JSON(parsing: value.text) == value)
        #expect(JSON.double(.nan).text == "null")
    }

    /// The stdio transport over real pipes: newline-delimited JSON both ways, EOF closes the session.
    @Test func stdioTransportOverAPipe() throws {
        let server = MCPServer(info: .init(name: "pipe", version: "1"))
        server.log = { _ in }
        let provider = FakeTools()
        server.tools = provider
        let toServer = Pipe(), fromServer = Pipe()
        let transport = MCPStdioTransport(inbox: server.inbox, input: toServer.fileHandleForReading,
                                          output: fromServer.fileHandleForWriting)
        transport.start()
        let received = ReceivedData()
        fromServer.fileHandleForReading.readabilityHandler = { handle in received.append(handle.availableData) }
        defer { fromServer.fileHandleForReading.readabilityHandler = nil }

        let requests = [
            #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{}}}"#,
            #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#,
            #"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#,
            #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"math.add","arguments":{"a":20,"b":22}}}"#,
            "not json",
        ]
        try toServer.fileHandleForWriting.write(contentsOf: Data((requests.joined(separator: "\n") + "\r\n").utf8))

        var lines: [JSON] = []
        var pending = Data()
        let deadline = Date(timeIntervalSinceNow: 10)
        while lines.count < 4 && Date() < deadline {
            server.inbox.wait(timeout: 0.05)
            server.pump()
            pending.append(received.take())
            while let newline = pending.firstIndex(of: UInt8(ascii: "\n")) {
                lines.append(try JSON(data: Data(pending[pending.startIndex..<newline])))
                pending = Data(pending[pending.index(after: newline)...])
            }
        }
        try #require(lines.count == 4)
        // The parse error is answered by the reading thread, maybe before the pump answers the rest.
        let answers = Dictionary(lines.map { ($0["id"] ?? nil, $0) }, uniquingKeysWith: { first, _ in first })
        #expect(answers[1]?["result"]?["protocolVersion"] == "2025-06-18")
        #expect(answers[2]?["result"]?["tools"]?.arrayValue?.count == 2)
        #expect(answers[3]?["result"]?["structuredContent"] == ["sum": 42])
        #expect(answers[nil]?["error"]?["code"] == -32700)

        try toServer.fileHandleForWriting.close()
        let closedBy = Date(timeIntervalSinceNow: 5)
        while !transport.isClosed && Date() < closedBy { server.inbox.wait(timeout: 0.05) }
        #expect(transport.isClosed)
    }
}

/// Bytes collected from a pipe's readability handler.
private final class ReceivedData: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) { lock.withLock { data.append(chunk) } }

    func take() -> Data {
        lock.withLock {
            defer { data = Data() }
            return data
        }
    }
}
