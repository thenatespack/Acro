import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import WinSDK
#endif

// A blocking TCP socket over BSD sockets (macOS, Linux) or Winsock (Windows): just what a
// loopback HTTP server needs. Each connection is served by its own thread.

enum SocketError: Error, CustomStringConvertible {
    case failed(String, Int32)

    var description: String {
        switch self {
        case .failed(let call, let code): "\(call) failed (error \(code))"
        }
    }
}

struct Socket: @unchecked Sendable {
    #if os(Windows)
    typealias Handle = SOCKET
    static let invalid: Handle = SOCKET.max
    #else
    typealias Handle = Int32
    static let invalid: Handle = -1
    #endif

    let handle: Handle

    private static var lastError: Int32 {
        #if os(Windows)
        WSAGetLastError()
        #else
        errno
        #endif
    }

    /// A socket listening on 127.0.0.1:`port` (0: any free port).
    static func listen(port: UInt16) throws -> Socket {
        #if os(Windows)
        var wsa = WSADATA()
        _ = WSAStartup(0x0202, &wsa)
        let handle = WinSDK.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP.rawValue)
        #elseif canImport(Glibc) || canImport(Musl)
        let handle = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
        let handle = socket(AF_INET, SOCK_STREAM, 0)
        #endif
        guard handle != invalid else { throw SocketError.failed("socket", lastError) }
        let socket = Socket(handle: handle)
        #if !os(Windows)
        // Lets a restarted editor take its port back while old connections are in TIME_WAIT.
        // (On Windows SO_REUSEADDR would let another process steal a port in use.)
        var yes: Int32 = 1
        setsockopt(handle, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        #endif

        var address = sockaddr_in()
        #if canImport(Darwin)
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        #if os(Windows)
        address.sin_addr.S_un.S_addr = UInt32(0x7F00_0001).bigEndian
        #else
        address.sin_addr.s_addr = UInt32(0x7F00_0001).bigEndian
        #endif
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(handle, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0 else {
            let code = lastError
            socket.close()
            throw SocketError.failed("bind to 127.0.0.1:\(port)", code)
        }
        #if os(Windows)
        let listening = WinSDK.listen(handle, 64)
        #else
        let listening = cListen(handle, 64)
        #endif
        guard listening == 0 else {
            let code = lastError
            socket.close()
            throw SocketError.failed("listen", code)
        }
        return socket
    }

    /// The local port (after binding to port 0).
    var port: UInt16 {
        var address = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let result = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(handle, $0, &length) }
        }
        return result == 0 ? UInt16(bigEndian: address.sin_port) : 0
    }

    /// Waits for a connection; nil once the socket was closed.
    func accept() -> Socket? {
        #if os(Windows)
        let client = WinSDK.accept(handle, nil, nil)
        #else
        let client = cAccept(handle, nil, nil)
        #endif
        guard client != Self.invalid else { return nil }
        let socket = Socket(handle: client)
        #if canImport(Darwin)
        var yes: Int32 = 1
        setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &yes, socklen_t(MemoryLayout<Int32>.size))
        #endif
        return socket
    }

    /// Makes `receive` give up after `seconds` without data.
    func setReceiveTimeout(_ seconds: Int) {
        #if os(Windows)
        var milliseconds = DWORD(seconds * 1000)
        _ = withUnsafePointer(to: &milliseconds) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<DWORD>.size) {
                setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, $0, Int32(MemoryLayout<DWORD>.size))
            }
        }
        #else
        var timeout = timeval(tv_sec: seconds, tv_usec: 0)
        setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        #endif
    }

    /// Reads what is available (blocking until something is): nil at end of stream, on an
    /// error or after the receive timeout.
    func receive(maxLength: Int = 64 * 1024) -> Data? {
        var buffer = [UInt8](repeating: 0, count: maxLength)
        let count = buffer.withUnsafeMutableBytes { raw -> Int in
            #if os(Windows)
            Int(recv(handle, raw.baseAddress?.assumingMemoryBound(to: CChar.self), Int32(maxLength), 0))
            #else
            recv(handle, raw.baseAddress, maxLength, 0)
            #endif
        }
        return count > 0 ? Data(buffer[0..<count]) : nil
    }

    /// Writes all of `data`; false if the connection broke.
    @discardableResult
    func send(_ data: Data) -> Bool {
        data.withUnsafeBytes { raw -> Bool in
            var offset = 0
            while offset < raw.count {
                let pointer = raw.baseAddress! + offset
                #if os(Windows)
                let sent = Int(WinSDK.send(handle, pointer.assumingMemoryBound(to: CChar.self), Int32(raw.count - offset), 0))
                #elseif canImport(Glibc) || canImport(Musl)
                let sent = cSend(handle, pointer, raw.count - offset, Int32(MSG_NOSIGNAL))
                #else
                let sent = cSend(handle, pointer, raw.count - offset, 0)
                #endif
                if sent <= 0 { return false }
                offset += sent
            }
            return true
        }
    }

    func close() {
        #if os(Windows)
        _ = closesocket(handle)
        #else
        _ = shutdown(handle, Int32(SHUT_RDWR))
        _ = cClose(handle)
        #endif
    }
}

#if os(Windows)
private typealias socklen_t = Int32
private typealias sa_family_t = ADDRESS_FAMILY
#else
// The C functions under names that don't collide with `Socket`'s methods.
#if canImport(Darwin)
private let cListen = Darwin.listen
private let cAccept = Darwin.accept
private let cSend = Darwin.send
private let cClose = Darwin.close
#elseif canImport(Glibc)
private let cListen = Glibc.listen
private let cAccept = Glibc.accept
private let cSend = Glibc.send
private let cClose = Glibc.close
#elseif canImport(Musl)
private let cListen = Musl.listen
private let cAccept = Musl.accept
private let cSend = Musl.send
private let cClose = Musl.close
#endif
#endif
