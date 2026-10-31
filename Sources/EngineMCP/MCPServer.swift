import Foundation

// A Model Context Protocol server (https://modelcontextprotocol.io): JSON-RPC 2.0 messages
// carrying `initialize`, `ping`, `tools/*`, `resources/*` and notifications. Foundation only,
// so a game can embed it as well as the editor.
//
// ```swift
// let server = MCPServer(info: .init(name: "my-game", version: "1.0"))
// server.tools = myToolProvider               // MCPToolProvider
// let stdio = try MCPStdioTransport.start(inbox: server.inbox)
// // every frame, on the main actor:
// server.pump()
// ```
//
// ## Threading
//
// Transports read on their own threads and post what arrives to `inbox`; nothing touches the
// host's state there. The host calls `pump()` on the main actor between frames: it handles
// everything queued, in order, calling the providers synchronously, so tools see a consistent
// world and the UI never waits on a client. Answers go back through the transport's
// `MCPOutput`, which writes from any thread. A call that takes longer than a frame returns
// `.pending` and is polled every pump (reporting progress through its `MCPCallContext`), so
// the frame loop keeps running meanwhile.
//
// ## Protocol coverage
//
// `initialize` (version negotiation: `MCPProtocol.supportedVersions`, else the newest),
// `ping`, `tools/list`, `tools/call`, `resources/list`, `resources/templates/list`,
// `resources/read`, `resources/subscribe` / `unsubscribe`; incoming
// `notifications/initialized` and `notifications/cancelled` (a queued request that was
// cancelled is dropped, a pending call stops being polled); outgoing
// `notifications/tools/list_changed`, `notifications/resources/list_changed`,
// `notifications/resources/updated` and `notifications/progress` (for requests with a
// `progressToken`). JSON-RPC batches (2025-03-26) are accepted. Lists aren't paginated.

/// Runs the protocol; see the notes at the top of this file.
@MainActor
public final class MCPServer {
    /// What `initialize` reports as `serverInfo`.
    public struct Info: Sendable {
        public var name: String
        public var title: String?
        public var version: String

        public init(name: String, title: String? = nil, version: String) {
            self.name = name
            self.title = title
            self.version = version
        }
    }

    private struct SessionState {
        let client: MCPClientSession
        var protocolVersion = MCPProtocol.latest
        var clientName: String?
        var initialized = false
        var subscriptions: Set<String> = []
    }

    private struct PendingCall {
        let context: MCPCallContext
        let poll: @MainActor (MCPCallContext) -> MCPToolResult?
    }

    private struct RequestKey: Hashable {
        var session: String
        var id: JSON
    }

    public let info: Info
    /// Sent with `initialize` (how to use the server, for the model).
    public var instructions: String?
    public weak var tools: (any MCPToolProvider)?
    public weak var resources: (any MCPResourceProvider)?
    /// Where transports post what clients send.
    public let inbox = MCPInbox()
    /// Diagnostics (connections, protocol errors). Default: standard error, never standard
    /// output (that is the stdio transport's channel).
    public var log: (String) -> Void = { MCPServer.logToStandardError($0) }

    private var sessions: [MCPClientSession: SessionState] = [:]
    private var pending: [PendingCall] = []

    public init(info: Info, instructions: String? = nil) {
        self.info = info
        self.instructions = instructions
    }

    /// Clients that have sent `initialize`.
    public var clientCount: Int { sessions.count }

    /// The names clients gave in `initialize` (`clientInfo.name`), sorted.
    public var clientNames: [String] { sessions.values.compactMap(\.clientName).sorted() }

    /// The name `session`'s client gave in `initialize`, if any.
    public func clientName(of session: MCPClientSession) -> String? { sessions[session]?.clientName }

    /// The resource URIs some client is subscribed to (what the host should watch).
    public var subscribedResources: Set<String> {
        sessions.values.reduce(into: []) { $0.formUnion($1.subscriptions) }
    }

    /// Whether a tool call is still running (`.pending`).
    public var hasPendingCalls: Bool { !pending.isEmpty }

    // MARK: Pump

    /// Handles everything the transports queued, then polls pending calls. Call it on the main
    /// actor, between frames.
    public func pump() {
        let events = inbox.take()
        // Cancellations first: a request queued before its own cancellation (both arriving
        // since the last pump) is dropped instead of run.
        var cancelled: Set<RequestKey> = []
        for case .messages(let messages, let session, _) in events {
            for message in messages where message["method"]?.stringValue == "notifications/cancelled" {
                if let id = message["params"]?["requestId"] { cancelled.insert(RequestKey(session: session.id, id: id)) }
            }
        }
        for event in events {
            switch event {
            case .messages(let messages, let session, let reply):
                for message in messages {
                    if let id = message["id"], message["method"] != nil, cancelled.contains(RequestKey(session: session.id, id: id)) {
                        reply.skip()
                        continue
                    }
                    handle(message, session: session, reply: reply)
                }
            case .closed(let session):
                sessions[session] = nil
                pending.removeAll { $0.context.session === session }
                log("MCP: client \(session.id.prefix(8)) disconnected")
            }
        }
        pollPending()
    }

    private func pollPending() {
        guard !pending.isEmpty else { return }
        var still: [PendingCall] = []
        for call in pending {
            if call.context.isCancelled {
                call.context.reply.skip()
            } else if let result = call.poll(call.context) {
                respond(call.context.requestID, result: result.json(protocolVersion: call.context.protocolVersion),
                        to: call.context.reply)
            } else {
                still.append(call)
            }
        }
        pending = still
    }

    // MARK: Notifications

    /// Tells every client the tool list changed (`notifications/tools/list_changed`).
    public func toolsChanged() {
        broadcast("notifications/tools/list_changed")
    }

    /// Tells every client the resource list changed (`notifications/resources/list_changed`).
    public func resourcesChanged() {
        broadcast("notifications/resources/list_changed")
    }

    /// Tells clients subscribed to `uri` that it changed (`notifications/resources/updated`).
    public func resourceUpdated(_ uri: String) {
        for state in sessions.values where state.subscriptions.contains(uri) {
            state.client.notifications?.send(Self.notification("notifications/resources/updated", ["uri": .string(uri)]))
        }
    }

    private func broadcast(_ method: String) {
        for state in sessions.values { state.client.notifications?.send(Self.notification(method)) }
    }

    // MARK: Messages

    /// Handles one message from `session`, answering through `reply`.
    func handle(_ message: JSON, session: MCPClientSession, reply: any MCPOutput) {
        guard case .object = message else {
            respond(.null, error: .invalidRequest("Expected a JSON-RPC object"), to: reply)
            return
        }
        let id = message["id"]
        guard let method = message["method"]?.stringValue else {
            // A response to a request of ours (we send none) or garbage.
            if id == nil || message["result"] == nil && message["error"] == nil {
                respond(id ?? .null, error: .invalidRequest(), to: reply)
            }
            return
        }
        let params = message["params"] ?? .object([:])
        guard let id else {
            handleNotification(method, params: params, session: session)
            return
        }
        switch id {
        case .string, .int: break
        default:
            respond(.null, error: .invalidRequest("The id must be a string or an integer"), to: reply)
            return
        }
        if message["jsonrpc"] != "2.0" {
            respond(id, error: .invalidRequest("Expected \"jsonrpc\": \"2.0\""), to: reply)
            return
        }
        do {
            if let result = try handleRequest(method, id: id, params: params, session: session, reply: reply) {
                respond(id, result: result, to: reply)
            }
        } catch let error as MCPError {
            respond(id, error: error, to: reply)
        } catch {
            respond(id, error: .internalError(String(describing: error)), to: reply)
        }
    }

    private func handleNotification(_ method: String, params: JSON, session: MCPClientSession) {
        switch method {
        case "notifications/initialized":
            sessions[session]?.initialized = true
        case "notifications/cancelled":
            // Queued requests were dropped in `pump`; a pending call stops here.
            if let id = params["requestId"] {
                for call in pending where call.context.session === session && call.context.requestID == id {
                    call.context.isCancelled = true
                }
            }
        default:
            break  // progress, roots/list_changed…: nothing to do.
        }
    }

    /// The result of a request, or nil when it is answered later (a pending tool call).
    private func handleRequest(_ method: String, id: JSON, params: JSON, session: MCPClientSession,
                               reply: any MCPOutput) throws -> JSON? {
        if method != "initialize" && sessions[session] == nil {
            // A client that skipped `initialize` (a quick script): speak the newest revision.
            sessions[session] = SessionState(client: session)
        }
        switch method {
        case "initialize":
            return initialize(params, session: session)
        case "ping":
            return .object([:])
        case "tools/list":
            let version = sessions[session]?.protocolVersion ?? MCPProtocol.latest
            return ["tools": .array((tools?.tools ?? []).map { $0.json(protocolVersion: version) })]
        case "tools/call":
            return try callTool(params, id: id, session: session, reply: reply)
        case "resources/list":
            return ["resources": .array((resources?.resources ?? []).map(\.json))]
        case "resources/templates/list":
            return ["resourceTemplates": .array((resources?.resourceTemplates ?? []).map(\.json))]
        case "resources/read":
            guard let uri = params["uri"]?.stringValue else { throw MCPError.invalidParams("Missing 'uri'") }
            guard let contents = resources?.readResource(uri) else { throw MCPError.resourceNotFound(uri) }
            return ["contents": .array(contents.map(\.json))]
        case "resources/subscribe", "resources/unsubscribe":
            guard let uri = params["uri"]?.stringValue else { throw MCPError.invalidParams("Missing 'uri'") }
            if method == "resources/subscribe" {
                sessions[session]?.subscriptions.insert(uri)
            } else {
                sessions[session]?.subscriptions.remove(uri)
            }
            return .object([:])
        default:
            throw MCPError.methodNotFound(method)
        }
    }

    private func initialize(_ params: JSON, session: MCPClientSession) -> JSON {
        var state = SessionState(client: session)
        state.protocolVersion = MCPProtocol.negotiate(params["protocolVersion"]?.stringValue)
        state.clientName = params["clientInfo"]?["name"]?.stringValue
        sessions[session] = state
        log("MCP: \(state.clientName ?? "a client") connected (protocol \(state.protocolVersion))")

        var serverInfo: [String: JSON] = ["name": .string(info.name), "version": .string(info.version)]
        if let title = info.title { serverInfo["title"] = .string(title) }
        var result: [String: JSON] = [
            "protocolVersion": .string(state.protocolVersion),
            "capabilities": [
                "tools": ["listChanged": true],
                "resources": ["subscribe": true, "listChanged": true],
            ],
            "serverInfo": .object(serverInfo),
        ]
        if let instructions { result["instructions"] = .string(instructions) }
        return .object(result)
    }

    private func callTool(_ params: JSON, id: JSON, session: MCPClientSession, reply: any MCPOutput) throws -> JSON? {
        guard let name = params["name"]?.stringValue else { throw MCPError.invalidParams("Missing tool 'name'") }
        guard let tools, tools.tools.contains(where: { $0.name == name }) else {
            throw MCPError.invalidParams("Unknown tool: \(name)")
        }
        let arguments = params["arguments"] ?? .object([:])
        guard case .object = arguments else { throw MCPError.invalidParams("'arguments' must be an object") }
        let version = sessions[session]?.protocolVersion ?? MCPProtocol.latest
        let context = MCPCallContext(requestID: id, progressToken: params["_meta"]?["progressToken"], session: session,
                                     reply: reply, protocolVersion: version)
        switch tools.callTool(name, arguments: arguments, context: context) {
        case .result(let result):
            return result.json(protocolVersion: version)
        case .pending(let poll):
            // Polled at the end of this pump and every pump after.
            pending.append(PendingCall(context: context, poll: poll))
            return nil
        }
    }

    private func respond(_ id: JSON, result: JSON, to reply: any MCPOutput) {
        reply.send(["jsonrpc": "2.0", "id": id, "result": result])
    }

    private func respond(_ id: JSON, error: MCPError, to reply: any MCPOutput) {
        var object: [String: JSON] = ["code": .int(Int64(error.code)), "message": .string(error.message)]
        if let data = error.data { object["data"] = data }
        reply.send(["jsonrpc": "2.0", "id": id, "error": .object(object)])
    }

    static func notification(_ method: String, _ params: JSON? = nil) -> JSON {
        var object: [String: JSON] = ["jsonrpc": "2.0", "method": .string(method)]
        if let params { object["params"] = params }
        return .object(object)
    }

    /// Writes `message` and a newline to standard error.
    nonisolated public static func logToStandardError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}

/// One tool call in progress: its request, where to report progress, whether it was cancelled.
@MainActor
public final class MCPCallContext {
    public let requestID: JSON
    /// The client's `_meta.progressToken`; nil if it doesn't want progress.
    public let progressToken: JSON?
    public let session: MCPClientSession
    /// The negotiated protocol revision.
    public let protocolVersion: String
    /// The client sent `notifications/cancelled` for this call: stop and return anything.
    public internal(set) var isCancelled = false
    let reply: any MCPOutput
    private var lastProgress: Double = -.infinity

    init(requestID: JSON, progressToken: JSON?, session: MCPClientSession, reply: any MCPOutput, protocolVersion: String) {
        self.requestID = requestID
        self.progressToken = progressToken
        self.session = session
        self.reply = reply
        self.protocolVersion = protocolVersion
    }

    /// Sends `notifications/progress` if the client asked for progress. `progress` must
    /// increase between calls (calls that don't are dropped); `total` may be unknown.
    public func progress(_ progress: Double, total: Double? = nil, message: String? = nil) {
        guard let progressToken, progress > lastProgress else { return }
        lastProgress = progress
        var params: [String: JSON] = ["progressToken": progressToken, "progress": .double(progress)]
        if let total { params["total"] = .double(total) }
        if let message, protocolVersion >= MCPProtocol.v2025_03_26 { params["message"] = .string(message) }
        reply.send(MCPServer.notification("notifications/progress", .object(params)))
    }
}
