import Foundation

/// MCP's Streamable HTTP transport (2025-03-26 / 2025-06-18) on 127.0.0.1, so a client can
/// attach to an editor that is already running.
///
/// One endpoint, `/mcp`:
/// - `POST` carries a JSON-RPC message (or batch). Notifications get `202 Accepted`. Requests
///   get their answer as `application/json`, or as a `text/event-stream` (progress
///   notifications, then the response) when the client accepts one.
/// - `GET` with `Accept: text/event-stream` opens the session's stream for server-initiated
///   notifications (list changes, resource updates). One per session; a new one replaces it.
/// - `DELETE` ends the session.
///
/// `initialize` creates a session; its response carries `Mcp-Session-Id`, which every later
/// request must send. An `MCP-Protocol-Version` header naming a revision the server doesn't
/// support is refused.
///
/// ## Security
///
/// - The socket binds 127.0.0.1 only: nothing off the machine can connect.
/// - Every request needs `Authorization: Bearer <token>`. The token is 256 random bits,
///   printed at startup and written (owner-only) to `mcp.json` (`MCPConfigFile`), so other
///   local users and web pages can't drive the editor.
/// - DNS rebinding (a web page whose host name resolves to 127.0.0.1) is blocked by
///   requiring the `Host` header to be a loopback name and, when a browser sends `Origin`,
///   that to be a loopback origin too. There are no CORS headers, so browsers can't read
///   responses from other origins either.
public final class MCPHTTPTransport: @unchecked Sendable {
    /// The endpoint's path.
    public static let path = "/mcp"
    /// How long a connection may sit idle between requests.
    static let idleTimeout = 60
    /// Requests larger than this are refused.
    static let maxBodySize = 16 * 1024 * 1024

    public let port: UInt16
    public let token: String
    private let inbox: MCPInbox
    private let listener: Socket
    private let lock = NSLock()
    private var sessions: [String: MCPClientSession] = [:]
    private var stopped = false
    /// Diagnostics, called from connection threads.
    public var log: @Sendable (String) -> Void = { MCPServer.logToStandardError($0) }

    /// Listens on 127.0.0.1:`port` (0: any free port; taken: the next `fallbackPorts` ports,
    /// then any free one) and starts accepting connections.
    public static func start(inbox: MCPInbox, port: UInt16, fallbackPorts: Int = 8, token: String) throws -> MCPHTTPTransport {
        MCPStdioTransport.ignoreBrokenPipes()
        var candidates: [UInt16] = port == 0 ? [] : (0...fallbackPorts).compactMap { UInt16(exactly: Int(port) + $0) }
        candidates.append(0)
        var lastError: (any Error)?
        for candidate in candidates {
            do {
                let socket = try Socket.listen(port: candidate)
                let transport = MCPHTTPTransport(inbox: inbox, listener: socket, token: token)
                transport.startAccepting()
                return transport
            } catch {
                lastError = error
            }
        }
        throw lastError ?? SocketError.failed("listen", 0)
    }

    private init(inbox: MCPInbox, listener: Socket, token: String) {
        self.inbox = inbox
        self.listener = listener
        self.token = token
        port = listener.port
    }

    /// `http://127.0.0.1:<port>/mcp`.
    public var url: String { "http://127.0.0.1:\(port)\(Self.path)" }

    /// Closes the listening socket. Open connections finish what they are doing.
    public func stop() {
        let wasStopped = lock.withLock {
            defer { stopped = true }
            return stopped
        }
        if !wasStopped { listener.close() }
    }

    /// A new random token: 64 hex digits.
    public static func makeToken() -> String {
        MCPClientSession.randomID() + MCPClientSession.randomID()
    }

    private func startAccepting() {
        let thread = Thread { [self] in
            while let connection = listener.accept() {
                let worker = Thread { [self] in serve(connection) }
                worker.name = "MCP HTTP connection"
                worker.start()
            }
        }
        thread.name = "MCP HTTP"
        thread.start()
    }

    // MARK: Connections

    private func serve(_ socket: Socket) {
        socket.setReceiveTimeout(Self.idleTimeout)
        var reader = HTTPRequestReader(socket: socket)
        defer { socket.close() }
        while true {
            let request: HTTPRequest
            switch reader.next() {
            case .request(let r): request = r
            case .closed: return
            case .malformed(let status, let message):
                HTTPResponse(status: status, body: Data(message.utf8), contentType: "text/plain").write(to: socket, keepAlive: false)
                return
            }
            let keepAlive = request.header("connection")?.lowercased() != "close" && request.version != "HTTP/1.0"
            switch respond(to: request, on: socket) {
            case .response(let response):
                guard response.write(to: socket, keepAlive: keepAlive), keepAlive else { return }
            case .streamed:
                return  // An event stream ends the connection.
            }
        }
    }

    private enum Outcome {
        case response(HTTPResponse)
        case streamed
    }

    private func respond(to request: HTTPRequest, on socket: Socket) -> Outcome {
        if let refusal = refusal(for: request) { return .response(refusal) }
        switch request.method {
        case "POST": return post(request, on: socket)
        case "GET": return get(request, on: socket)
        case "DELETE":
            switch session(for: request) {
            case .refused(let response): return .response(response)
            case .found(let session):
                lock.withLock { sessions[session.id] = nil }
                session.notifications = nil
                inbox.post(.closed(session))
                return .response(HTTPResponse(status: 200))
            }
        default:
            return .response(HTTPResponse(status: 405, headers: [("Allow", "GET, POST, DELETE")]))
        }
    }

    /// Why `request` is refused before looking at it: wrong path, a non-loopback host or origin
    /// (DNS rebinding), a missing or wrong token, an unsupported protocol version.
    private func refusal(for request: HTTPRequest) -> HTTPResponse? {
        guard request.path == Self.path else { return HTTPResponse(status: 404) }
        guard let host = request.header("host"), Self.isLoopback(host: host) else {
            log("MCP HTTP: refused a request for host \(request.header("host") ?? "(none)")")
            return HTTPResponse(status: 403, body: Data("Forbidden host".utf8), contentType: "text/plain")
        }
        if let origin = request.header("origin"), !Self.isLoopback(origin: origin) {
            log("MCP HTTP: refused a request from origin \(origin)")
            return HTTPResponse(status: 403, body: Data("Forbidden origin".utf8), contentType: "text/plain")
        }
        guard let authorization = request.header("authorization"), Self.isValid(authorization: authorization, token: token) else {
            return HTTPResponse(status: 401, headers: [("WWW-Authenticate", "Bearer")],
                                body: Data("Missing or wrong bearer token (see mcp.json)".utf8), contentType: "text/plain")
        }
        if let version = request.header("mcp-protocol-version"), !MCPProtocol.supportedVersions.contains(version) {
            return .jsonRPCError(400, .invalidRequest("Unsupported MCP-Protocol-Version \(version)"))
        }
        return nil
    }

    private enum SessionLookup {
        case found(MCPClientSession)
        case refused(HTTPResponse)
    }

    private func session(for request: HTTPRequest) -> SessionLookup {
        guard let id = request.header("mcp-session-id") else {
            return .refused(.jsonRPCError(400, .invalidRequest("Missing Mcp-Session-Id header (send initialize first)")))
        }
        guard let session = lock.withLock({ sessions[id] }) else {
            return .refused(.jsonRPCError(404, .invalidRequest("Unknown or expired session")))
        }
        return .found(session)
    }

    private func post(_ request: HTTPRequest, on socket: Socket) -> Outcome {
        let parsed: JSON
        do {
            parsed = try JSON(data: request.body)
        } catch {
            return .response(.jsonRPCError(400, .parseError()))
        }
        let messages: [JSON]
        if case .array(let batch) = parsed { messages = batch } else { messages = [parsed] }
        guard !messages.isEmpty else { return .response(.jsonRPCError(400, .invalidRequest("Empty batch"))) }

        let isInitialize = messages.contains { $0["method"]?.stringValue == "initialize" }
        let session: MCPClientSession
        if isInitialize {
            session = MCPClientSession()
            lock.withLock { sessions[session.id] = session }
        } else {
            switch self.session(for: request) {
            case .refused(let response): return .response(response)
            case .found(let s): session = s
            }
        }
        let requestCount = messages.filter { $0["method"] != nil && $0["id"] != nil }.count
        guard requestCount > 0 else {
            inbox.post(.messages(messages, session: session, reply: DiscardingOutput()))
            return .response(HTTPResponse(status: 202))
        }

        let reply = HTTPReplyStream(expectedResponses: requestCount)
        inbox.post(.messages(messages, session: session, reply: reply))
        var headers = [("Mcp-Session-Id", session.id)]
        let accept = request.header("accept") ?? ""
        if accept.contains("text/event-stream") {
            // Stream: progress notifications as they come, then the responses.
            headers += [("Content-Type", "text/event-stream"), ("Cache-Control", "no-cache")]
            guard HTTPResponse.writeHead(status: 200, headers: headers, to: socket) else { return .streamed }
            while let message = reply.next() {
                if !socket.send(SSE.event(message)) { break }
            }
            return .streamed
        }
        // JSON: only the responses (a client that can't take a stream doesn't get progress).
        var responses: [JSON] = []
        while let message = reply.next() {
            if message["method"] == nil { responses.append(message) }
        }
        let body: JSON = messages.count == 1 && responses.count == 1 && !isBatch(parsed) ? responses[0] : .array(responses)
        if isInitialize && responses.first?["error"] != nil {
            lock.withLock { sessions[session.id] = nil }
        }
        return .response(HTTPResponse(status: 200, headers: headers, body: body.data(), contentType: "application/json"))
    }

    private func isBatch(_ json: JSON) -> Bool {
        if case .array = json { return true }
        return false
    }

    private func get(_ request: HTTPRequest, on socket: Socket) -> Outcome {
        guard request.header("accept")?.contains("text/event-stream") == true else {
            return .response(HTTPResponse(status: 405, headers: [("Allow", "GET, POST, DELETE")]))
        }
        let session: MCPClientSession
        switch self.session(for: request) {
        case .refused(let response): return .response(response)
        case .found(let s): session = s
        }
        let stream = SSEStream()
        session.notifications = stream
        defer {
            if session.notifications === stream { session.notifications = nil }
        }
        let headers = [("Content-Type", "text/event-stream"), ("Cache-Control", "no-cache"), ("Mcp-Session-Id", session.id)]
        guard HTTPResponse.writeHead(status: 200, headers: headers, to: socket) else { return .streamed }
        // Until the client goes away (a write fails) or another GET replaces this stream.
        while session.notifications === stream {
            let messages = stream.wait(timeout: 15)
            let data = messages.isEmpty ? Data(": keepalive\n\n".utf8) : messages.reduce(into: Data()) { $0 += SSE.event($1) }
            if !socket.send(data) { break }
        }
        return .streamed
    }

    // MARK: Checks

    /// Whether a `Host` header names this machine's loopback interface (any port).
    static func isLoopback(host: String) -> Bool {
        let name: Substring
        if host.hasPrefix("[") {
            name = host.dropFirst().prefix { $0 != "]" }
        } else {
            name = host.prefix { $0 != ":" }
        }
        return ["127.0.0.1", "localhost", "::1"].contains(name.lowercased())
    }

    /// Whether an `Origin` header is a loopback origin (`http://localhost:1234`…).
    static func isLoopback(origin: String) -> Bool {
        guard let url = URL(string: origin), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host else { return false }
        return isLoopback(host: host.hasPrefix("[") || !host.contains(":") ? host : "[\(host)]")
    }

    /// Whether `authorization` is `Bearer <token>`, compared in constant time.
    static func isValid(authorization: String, token: String) -> Bool {
        let parts = authorization.split(separator: " ", maxSplits: 1)
        guard parts.count == 2, parts[0].lowercased() == "bearer" else { return false }
        let given = Array(parts[1].trimmingCharacters(in: .whitespaces).utf8), expected = Array(token.utf8)
        guard given.count == expected.count, !expected.isEmpty else { return false }
        return zip(given, expected).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

// MARK: Outputs

/// Answers for one POST: the connection thread takes messages until every request in it was
/// answered (or skipped).
final class HTTPReplyStream: MCPOutput, @unchecked Sendable {
    private let condition = NSCondition()
    private var queue: [JSON] = []
    private var remaining: Int

    init(expectedResponses: Int) {
        remaining = expectedResponses
    }

    func send(_ message: JSON) {
        condition.withLock {
            queue.append(message)
            if message["method"] == nil { remaining -= 1 }
            condition.signal()
        }
    }

    func skip() {
        condition.withLock {
            remaining -= 1
            condition.signal()
        }
    }

    /// The next message, waiting for it; nil once all responses were taken.
    func next() -> JSON? {
        condition.lock()
        defer { condition.unlock() }
        while queue.isEmpty {
            if remaining <= 0 { return nil }
            condition.wait()
        }
        return queue.removeFirst()
    }
}

/// A session's GET stream: notifications queue here until the connection thread writes them.
final class SSEStream: MCPOutput, @unchecked Sendable {
    private let condition = NSCondition()
    private var queue: [JSON] = []

    func send(_ message: JSON) {
        condition.withLock {
            queue.append(message)
            condition.signal()
        }
    }

    /// What was sent, waiting up to `timeout` seconds for something.
    func wait(timeout: Double) -> [JSON] {
        condition.lock()
        defer { condition.unlock() }
        let deadline = Date(timeIntervalSinceNow: timeout)
        while queue.isEmpty {
            if !condition.wait(until: deadline) { break }
        }
        defer { queue.removeAll() }
        return queue
    }
}

/// For POSTs of notifications only (nothing is answered).
final class DiscardingOutput: MCPOutput {
    func send(_ message: JSON) {}
}

enum SSE {
    static func event(_ message: JSON) -> Data {
        Data("event: message\ndata: \(message.text)\n\n".utf8)
    }
}

// MARK: HTTP/1.1

struct HTTPRequest {
    var method: String
    var path: String
    var version: String
    /// Lowercased names.
    var headers: [String: String]
    var body: Data

    func header(_ name: String) -> String? { headers[name] }
}

struct HTTPResponse {
    var status: Int
    var headers: [(String, String)] = []
    var body = Data()
    var contentType: String?

    static func jsonRPCError(_ status: Int, _ error: MCPError) -> HTTPResponse {
        let body: JSON = ["jsonrpc": "2.0", "id": nil,
                          "error": ["code": .int(Int64(error.code)), "message": .string(error.message)]]
        return HTTPResponse(status: status, body: body.data(), contentType: "application/json")
    }

    static func reason(_ status: Int) -> String {
        switch status {
        case 200: "OK"
        case 202: "Accepted"
        case 400: "Bad Request"
        case 401: "Unauthorized"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 405: "Method Not Allowed"
        case 411: "Length Required"
        case 413: "Content Too Large"
        default: "Error"
        }
    }

    @discardableResult
    func write(to socket: Socket, keepAlive: Bool) -> Bool {
        var all = headers
        if let contentType { all.append(("Content-Type", contentType)) }
        all.append(("Content-Length", String(body.count)))
        all.append(("Connection", keepAlive ? "keep-alive" : "close"))
        var data = Self.head(status: status, headers: all)
        data.append(body)
        return socket.send(data)
    }

    /// The status line and headers of a streamed response (no length; the connection closes
    /// at its end).
    static func writeHead(status: Int, headers: [(String, String)], to socket: Socket) -> Bool {
        socket.send(head(status: status, headers: headers + [("Connection", "close")]))
    }

    private static func head(status: Int, headers: [(String, String)]) -> Data {
        var text = "HTTP/1.1 \(status) \(reason(status))\r\n"
        for (name, value) in headers { text += "\(name): \(value)\r\n" }
        text += "\r\n"
        return Data(text.utf8)
    }
}

/// Reads requests off a connection (keep-alive: one after another).
struct HTTPRequestReader {
    enum Next {
        case request(HTTPRequest)
        case closed
        case malformed(Int, String)
    }

    let socket: Socket
    private var buffer = Data()
    private static let headerEnd = Data("\r\n\r\n".utf8)
    private static let maxHeaderSize = 64 * 1024

    init(socket: Socket) {
        self.socket = socket
    }

    mutating func next() -> Next {
        var headEnd: Range<Data.Index>?
        while true {
            headEnd = buffer.range(of: Self.headerEnd)
            if headEnd != nil { break }
            if buffer.count > Self.maxHeaderSize { return .malformed(400, "Headers too large") }
            guard let chunk = socket.receive() else { return .closed }
            buffer.append(chunk)
        }
        guard let headEnd, let head = String(data: buffer[buffer.startIndex..<headEnd.lowerBound], encoding: .utf8) else {
            return .malformed(400, "Bad request head")
        }
        var lines = head.components(separatedBy: "\r\n")
        let requestLine = lines.removeFirst().split(separator: " ")
        guard requestLine.count == 3 else { return .malformed(400, "Bad request line") }
        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            headers[name] = headers[name].map { "\($0), \(value)" } ?? value
        }
        if headers["transfer-encoding"] != nil { return .malformed(411, "Send a Content-Length, not chunked encoding") }
        let length = Int(headers["content-length"] ?? "0") ?? -1
        guard length >= 0 else { return .malformed(400, "Bad Content-Length") }
        guard length <= MCPHTTPTransport.maxBodySize else { return .malformed(413, "Request too large") }
        buffer = Data(buffer[headEnd.upperBound...])
        while buffer.count < length {
            guard let chunk = socket.receive() else { return .closed }
            buffer.append(chunk)
        }
        let body = Data(buffer.prefix(length))
        buffer = Data(buffer.dropFirst(length))
        var path = String(requestLine[1])
        if let query = path.firstIndex(of: "?") { path = String(path[..<query]) }
        return .request(HTTPRequest(method: String(requestLine[0]), path: path, version: String(requestLine[2]),
                                    headers: headers, body: body))
    }
}
