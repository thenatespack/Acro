#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Relays a stdio client to a host already serving Streamable HTTP, so a client that launches
/// the host (`Editor --mcp`, from a project's `.mcp.json`) attaches to the one that's open
/// instead of starting another. Lines from standard input go out as POSTs: requests
/// concurrently (a long tool call doesn't hold up the rest), `initialize` (whose response
/// carries the session id) and notifications in order; responses and progress (JSON or an
/// event stream) come back as lines on standard output, and a GET event stream carries the
/// host's own notifications (tools changed, resource updates). At the end of standard input the
/// session is deleted and `run` returns.
public final class MCPStdioRelay: @unchecked Sendable {
    public let config: MCPConfigFile
    private let output: MCPOutput
    private let urlSession: URLSession
    private let lock = NSLock()
    private var sessionID: String?
    private var protocolVersion: String?
    private var streamDelegate: EventStreamDelegate?
    private let inFlight = DispatchGroup()

    init(config: MCPConfigFile, output: MCPOutput) {
        self.config = config
        self.output = output
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 24 * 60 * 60  // a tool call can take long (a build)
        configuration.timeoutIntervalForResource = 7 * 24 * 60 * 60
        configuration.connectionProxyDictionary = [:]
        urlSession = URLSession(configuration: configuration)
    }

    /// The host `mcp.json` at `url` describes, when its process is alive and answers with that
    /// token within `timeout` seconds; nil otherwise (no file, a stale one, a host that quit).
    public static func liveHost(configAt url: URL, timeout: TimeInterval = 2) -> MCPConfigFile? {
        guard let data = try? Data(contentsOf: url), let json = try? JSON(data: data),
              let address = json["url"]?.stringValue, let token = json["token"]?.stringValue,
              let endpoint = URL(string: address), let host = endpoint.host,
              MCPHTTPTransport.isLoopback(host: host) else { return nil }
        let pid = Int32(truncatingIfNeeded: json["pid"]?.intValue ?? 0)
        guard pid > 0 else { return nil }
        #if !os(Windows)
        guard kill(pid, 0) == 0 || errno == EPERM else { return nil }
        #endif
        // A request without a session: the host refuses it with 400 once the token checks out
        // (401 means another token, so another host on that port).
        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"jsonrpc":"2.0","id":0,"method":"ping"}"#.utf8)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [:]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        guard let (status, _, _) = perform(request, in: session), status == 400 else { return nil }
        return MCPConfigFile(url: address, token: token, pid: pid,
                             serverName: json["mcpServers"]?.objectValue?.keys.first ?? "")
    }

    /// Relays the process's standard input and output until the client closes standard input
    /// or the host goes away. Returns the exit code.
    public static func run(config: MCPConfigFile) -> Int32 {
        MCPStdioTransport.ignoreBrokenPipes()
        let output = LineOutput(handle: MCPStdioTransport.claimStandardOutput())
        let relay = MCPStdioRelay(config: config, output: output)
        MCPServer.logToStandardError("MCP: attached to the running host at \(config.url) (pid \(config.pid))")
        return relay.relay(input: .standardInput)
    }

    func relay(input: FileHandle) -> Int32 {
        var buffer = Data()
        while true {
            #if os(Windows)
            let chunk = input.availableData
            if chunk.isEmpty { break }
            #else
            guard let chunk = MCPStdioTransport.read(input.fileDescriptor) else { break }
            #endif
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = Data(buffer[buffer.startIndex..<newline])
                buffer = Data(buffer[buffer.index(after: newline)...])
                receive(line)
            }
        }
        if !buffer.isEmpty { receive(buffer) }
        inFlight.wait()
        closeSession()
        return 0
    }

    // MARK: Client → host

    private func receive(_ line: Data) {
        let trimmed = line.filter { $0 != UInt8(ascii: "\r") }
        guard !trimmed.allSatisfy({ $0 == UInt8(ascii: " ") || $0 == UInt8(ascii: "\t") }) else { return }
        guard let message = try? JSON(data: trimmed) else {
            output.send(["jsonrpc": "2.0", "id": nil, "error": ["code": -32700, "message": "Parse error"]])
            return
        }
        let messages: [JSON]
        if case .array(let batch) = message { messages = batch } else { messages = [message] }
        if messages.contains(where: { $0["method"]?.stringValue == "initialize" }) {
            // Synchronously: everything after it needs the session id.
            post(trimmed, requests: messages)
            openEventStream()
        } else if !messages.contains(where: { $0["method"] != nil && $0["id"] != nil }) {
            // Notifications and answers (202 right away), in order: `initialized` or a
            // cancellation must not be overtaken by the requests after it.
            post(trimmed, requests: messages)
        } else {
            inFlight.enter()
            Thread.detachNewThread { [self] in
                post(trimmed, requests: messages)
                inFlight.leave()
            }
        }
    }

    private func post(_ body: Data, requests messages: [JSON]) {
        var request = makeRequest(method: "POST")
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        guard let (status, headers, data) = Self.perform(request, in: urlSession) else {
            fail(messages, "The editor at \(config.url) went away")
            return
        }
        if let id = headers["mcp-session-id"] {
            lock.withLock { sessionID = id }
        }
        guard status == 200 else {
            if status != 202 {
                // A JSON-RPC error body when the host sent one, else a made-up one per request.
                if let json = try? JSON(data: data), json["error"] != nil, messages.count == 1 {
                    output.send(Self.withID(json, messages[0]["id"]))
                } else {
                    fail(messages, "The editor answered HTTP \(status): \(String(decoding: data, as: UTF8.self))")
                }
            }
            return
        }
        var replies: [JSON] = []
        if headers["content-type"]?.contains("text/event-stream") == true {
            replies = SSEParser.events(in: data)
        } else if let json = try? JSON(data: data) {
            replies = [json]
        }
        for reply in replies {
            if let version = reply["result"]?["protocolVersion"]?.stringValue, reply["result"]?["serverInfo"] != nil {
                lock.withLock { protocolVersion = version }
            }
            output.send(reply)
        }
    }

    private func makeRequest(method: String) -> URLRequest {
        var request = URLRequest(url: URL(string: config.url)!)
        request.httpMethod = method
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        let (session, version) = lock.withLock { (sessionID, protocolVersion) }
        if let session { request.setValue(session, forHTTPHeaderField: "Mcp-Session-Id") }
        if let version { request.setValue(version, forHTTPHeaderField: "MCP-Protocol-Version") }
        return request
    }

    /// An error response for each request in `messages` (notifications get none).
    private func fail(_ messages: [JSON], _ reason: String) {
        MCPServer.logToStandardError("MCP relay: \(reason)")
        for message in messages where message["method"] != nil {
            guard let id = message["id"] else { continue }
            output.send(["jsonrpc": "2.0", "id": id, "error": ["code": -32603, "message": .string(reason)]])
        }
    }

    private static func withID(_ error: JSON, _ id: JSON?) -> JSON {
        guard case .object(var object) = error else { return error }
        if object["id"] == nil || object["id"] == .null { object["id"] = id ?? .null }
        return .object(object)
    }

    private func closeSession() {
        streamDelegate?.cancel()
        guard lock.withLock({ sessionID }) != nil else { return }
        var request = makeRequest(method: "DELETE")
        request.timeoutInterval = 2
        _ = Self.perform(request, in: urlSession)
        urlSession.invalidateAndCancel()
    }

    // MARK: Host → client

    /// The session's GET event stream: the host's notifications, as they come.
    private func openEventStream() {
        guard lock.withLock({ sessionID }) != nil else { return }
        var request = makeRequest(method: "GET")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        let delegate = EventStreamDelegate(output: output)
        streamDelegate = delegate
        delegate.start(request)
    }

    /// Runs `request` to completion: status, lowercased headers and body; nil when it failed.
    static func perform(_ request: URLRequest, in session: URLSession) -> (Int, [String: String], Data)? {
        let box = ResultBox()
        let done = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse {
                var headers: [String: String] = [:]
                for (name, value) in http.allHeaderFields { headers[String(describing: name).lowercased()] = String(describing: value) }
                box.value = (http.statusCode, headers, data ?? Data())
            }
            done.signal()
        }.resume()
        done.wait()
        return box.value
    }

    private final class ResultBox: @unchecked Sendable {
        var value: (Int, [String: String], Data)?
    }
}

/// `data:` lines of a `text/event-stream` body, as JSON-RPC messages.
enum SSEParser {
    static func events(in data: Data) -> [JSON] {
        var parser = Incremental()
        return parser.feed(data)
    }

    /// Splits a stream that arrives in pieces into events.
    struct Incremental {
        private var buffer = Data()
        private var lines: [String] = []

        mutating func feed(_ chunk: Data) -> [JSON] {
            buffer.append(chunk)
            var events: [JSON] = []
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                var line = String(decoding: buffer[buffer.startIndex..<newline], as: UTF8.self)
                buffer = Data(buffer[buffer.index(after: newline)...])
                if line.hasSuffix("\r") { line.removeLast() }
                if line.isEmpty {
                    if !lines.isEmpty, let json = try? JSON(parsing: lines.joined(separator: "\n")) { events.append(json) }
                    lines = []
                } else if line.hasPrefix("data:") {
                    var value = line.dropFirst(5)
                    if value.first == " " { value = value.dropFirst() }
                    lines.append(String(value))
                }
            }
            return events
        }
    }
}

/// Reads the GET event stream as it arrives and forwards each event.
private final class EventStreamDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let output: MCPOutput
    private let lock = NSLock()
    private var parser = SSEParser.Incremental()
    private var session: URLSession?

    init(output: MCPOutput) {
        self.output = output
    }

    func start(_ request: URLRequest) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 24 * 60 * 60  // keepalives come every 15 s
        configuration.timeoutIntervalForResource = 365 * 24 * 60 * 60
        configuration.connectionProxyDictionary = [:]
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        lock.withLock { self.session = session }
        session.dataTask(with: request).resume()
    }

    func cancel() {
        lock.withLock { session }?.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let events = lock.withLock { parser.feed(data) }
        for event in events { output.send(event) }
    }
}
