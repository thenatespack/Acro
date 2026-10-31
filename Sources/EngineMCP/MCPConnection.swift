import Foundation

// Between transports (which run on their own threads) and the server (main actor): a
// transport posts what a client sent to the server's `MCPInbox` together with where the
// answers go (an `MCPOutput`), and the server drains the inbox in `MCPServer.pump()`.

/// Where the server's messages to a client go: a pipe, an HTTP response, an SSE stream.
/// `send` may be called from any thread and must not block for long.
public protocol MCPOutput: AnyObject, Sendable {
    func send(_ message: JSON)
    /// The server won't answer one of the requests this output was handed with (it was
    /// cancelled), so an output waiting for a number of responses stops waiting for it.
    func skip()
}

extension MCPOutput {
    public func skip() {}
}

/// One client: the process at the other end of stdio, or an HTTP `Mcp-Session-Id`.
public final class MCPClientSession: @unchecked Sendable, Hashable {
    public let id: String
    private let lock = NSLock()
    private var notificationOutput: (any MCPOutput)?

    public init(id: String = MCPClientSession.randomID(), notifications: (any MCPOutput)? = nil) {
        self.id = id
        notificationOutput = notifications
    }

    /// Where server-initiated notifications (list changes, resource updates) go; nil drops
    /// them (an HTTP client that hasn't opened its GET stream).
    public var notifications: (any MCPOutput)? {
        get { lock.withLock { notificationOutput } }
        set { lock.withLock { notificationOutput = newValue } }
    }

    /// 32 random hex digits.
    public static func randomID() -> String {
        var generator = SystemRandomNumberGenerator()
        return (0..<2).map { _ in
            let s = String(generator.next() as UInt64, radix: 16)
            return String(repeating: "0", count: 16 - s.count) + s
        }.joined()
    }

    public static func == (a: MCPClientSession, b: MCPClientSession) -> Bool { a === b }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

/// Something a transport hands the server.
public enum MCPEvent: Sendable {
    /// Messages a client sent at once (one, or a JSON-RPC batch), and where answers go.
    case messages([JSON], session: MCPClientSession, reply: any MCPOutput)
    /// The client went away (stdin closed, HTTP DELETE).
    case closed(MCPClientSession)
}

/// The thread-safe queue between transports and the server.
public final class MCPInbox: @unchecked Sendable {
    private let condition = NSCondition()
    private var events: [MCPEvent] = []
    private var wakeHandler: (@Sendable () -> Void)?

    public init() {}

    public func post(_ event: MCPEvent) {
        condition.lock()
        events.append(event)
        let wake = wakeHandler
        condition.signal()
        condition.unlock()
        wake?()
    }

    /// Called (on the posting thread) after each post, e.g. to wake an idle loop.
    public func onPost(_ handler: (@Sendable () -> Void)?) {
        condition.withLock { wakeHandler = handler }
    }

    /// Everything posted so far, oldest first.
    public func take() -> [MCPEvent] {
        condition.withLock {
            defer { events.removeAll() }
            return events
        }
    }

    public var isEmpty: Bool { condition.withLock { events.isEmpty } }

    /// Blocks until something is posted or `timeout` seconds pass; true if there is something.
    @discardableResult
    public func wait(timeout: Double) -> Bool {
        condition.lock()
        defer { condition.unlock() }
        let deadline = Date(timeIntervalSinceNow: timeout)
        while events.isEmpty {
            if !condition.wait(until: deadline) { break }
        }
        return !events.isEmpty
    }
}

/// An output that collects messages in memory (in-process clients and tests).
public final class MCPMemoryOutput: MCPOutput, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [JSON] = []
    private let handler: (@Sendable (JSON) -> Void)?

    /// `handler`, if given, also receives each message as it is sent (on the sending thread).
    public init(handler: (@Sendable (JSON) -> Void)? = nil) {
        self.handler = handler
    }

    public func send(_ message: JSON) {
        lock.withLock { messages.append(message) }
        handler?(message)
    }

    /// The messages sent since the last call.
    public func take() -> [JSON] {
        lock.withLock {
            defer { messages.removeAll() }
            return messages
        }
    }
}

/// A client in the same process, talking to the server through its inbox: what tests and
/// embedding hosts use instead of a pipe or socket. Answers and notifications collect in
/// `output`.
public final class MCPMemoryConnection: @unchecked Sendable {
    public let session: MCPClientSession
    public let output: MCPMemoryOutput
    private let inbox: MCPInbox

    public init(inbox: MCPInbox, handler: (@Sendable (JSON) -> Void)? = nil) {
        self.inbox = inbox
        output = MCPMemoryOutput(handler: handler)
        session = MCPClientSession(notifications: output)
    }

    /// Posts `message` (not processed until the server's next `pump()`).
    public func send(_ message: JSON) {
        inbox.post(.messages([message], session: session, reply: output))
    }

    public func close() {
        inbox.post(.closed(session))
    }
}
