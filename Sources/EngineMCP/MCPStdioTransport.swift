#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
// Glibc declares `stdout` as a mutable global, which Swift 6 rejects; @preconcurrency allows
// it, but only when this import comes before Foundation's (which re-exports Glibc).
@preconcurrency import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
#endif
import Foundation

/// The stdio transport: the client launched this process and speaks newline-delimited JSON-RPC
/// on its standard input and output. Standard output belongs to the protocol, so
/// `claimStandardOutput()` points file descriptor 1 at standard error first: every `print`
/// (the engine's, the editor log's, a C library's) then lands in stderr, where clients show
/// logs, and only the transport writes to the real stdout.
public final class MCPStdioTransport: @unchecked Sendable {
    /// The one client.
    public let session: MCPClientSession
    private let output: LineOutput
    private let input: FileHandle
    private let inbox: MCPInbox
    private let lock = NSLock()
    private var closed = false

    /// Reads `input` on a background thread, posting messages to `inbox`; answers are written
    /// to `output`, one line each.
    public init(inbox: MCPInbox, input: FileHandle, output: FileHandle) {
        self.inbox = inbox
        self.input = input
        self.output = LineOutput(handle: output)
        session = MCPClientSession(id: "stdio", notifications: self.output)
    }

    /// The process's stdin and (claimed) stdout, reading started.
    public static func start(inbox: MCPInbox) -> MCPStdioTransport {
        ignoreBrokenPipes()
        let transport = MCPStdioTransport(inbox: inbox, input: .standardInput, output: claimStandardOutput())
        transport.start()
        return transport
    }

    /// Starts the reading thread.
    public func start() {
        let thread = Thread { [self] in readLoop() }
        thread.name = "MCP stdio"
        thread.start()
    }

    /// The client closed its end (stdin reached EOF): time to quit.
    public var isClosed: Bool { lock.withLock { closed } }

    private func readLoop() {
        var buffer = Data()
        while true {
            // Plain read(2): FileHandle's reads wait for the whole count on a pipe.
            guard let chunk = Self.read(input.fileDescriptor) else { break }
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = buffer[buffer.startIndex..<newline]
                buffer = Data(buffer[buffer.index(after: newline)...])
                receive(Data(line))
            }
        }
        if !buffer.isEmpty { receive(buffer) }
        lock.withLock { closed = true }
        inbox.post(.closed(session))
    }

    private func receive(_ line: Data) {
        var line = line
        while let last = line.last, last == UInt8(ascii: "\r") || last == UInt8(ascii: " ") || last == UInt8(ascii: "\t") {
            line.removeLast()
        }
        guard !line.isEmpty else { return }
        do {
            let message = try JSON(data: line)
            if case .array(let batch) = message {
                inbox.post(.messages(batch, session: session, reply: output))
            } else {
                inbox.post(.messages([message], session: session, reply: output))
            }
        } catch {
            output.send(["jsonrpc": "2.0", "id": nil, "error": ["code": -32700, "message": "Parse error"]])
        }
    }

    /// What is available on `descriptor` (blocking until something is); nil at EOF or on an error.
    static func read(_ descriptor: Int32) -> Data? {
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let count = buffer.withUnsafeMutableBytes { raw -> Int in
                #if os(Windows)
                Int(_read(descriptor, raw.baseAddress, UInt32(raw.count)))
                #else
                cRead(descriptor, raw.baseAddress, raw.count)
                #endif
            }
            if count > 0 { return Data(buffer[0..<count]) }
            #if !os(Windows)
            if count < 0 && errno == EINTR { continue }
            #endif
            return nil
        }
    }

    /// Duplicates the process's standard output for the protocol and points descriptor 1 at
    /// standard error. Returns the protocol's handle.
    public static func claimStandardOutput() -> FileHandle {
        fflush(stdout)
        #if os(Windows)
        let saved = _dup(1)
        _ = _dup2(2, 1)
        #else
        let saved = dup(1)
        _ = dup2(2, 1)
        #endif
        // Descriptor 1 is no terminal now, so stdio would buffer whole blocks: flush per line
        // so logs show up as they happen.
        setvbuf(stdout, nil, _IOLBF, 0)
        return FileHandle(fileDescriptor: saved, closeOnDealloc: true)
    }

    /// Writing to a pipe or socket whose reader went away raises SIGPIPE, which kills the
    /// process by default; transports want the EPIPE error instead.
    static func ignoreBrokenPipes() {
        #if !os(Windows)
        signal(SIGPIPE, SIG_IGN)
        #endif
    }
}

/// Writes each message as one line (JSON text never contains a raw newline).
final class LineOutput: MCPOutput, @unchecked Sendable {
    private let handle: FileHandle
    private let lock = NSLock()
    private var failed = false

    init(handle: FileHandle) {
        self.handle = handle
    }

    func send(_ message: JSON) {
        var data = message.data()
        data.append(UInt8(ascii: "\n"))
        lock.withLock {
            guard !failed else { return }
            do {
                try handle.write(contentsOf: data)
            } catch {
                failed = true
            }
        }
    }
}

// read(2) under a name that doesn't collide with `MCPStdioTransport.read`.
#if canImport(Darwin)
private let cRead = Darwin.read
#elseif canImport(Glibc)
private let cRead = Glibc.read
#elseif canImport(Musl)
private let cRead = Musl.read
#endif
