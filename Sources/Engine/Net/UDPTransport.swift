#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// Networking prototype (card 624): a non-blocking IPv4 UDP socket (POSIX; macOS and Linux).
// No encryption, no connection handshake: a prototype transport for LAN tests and for
// measuring, not for shipping (see docs/Networking.md, "Transport").

#if canImport(Darwin) || canImport(Glibc)
public final class UDPTransport: NetTransport {
    public enum Failure: Error, Equatable {
        case socket(Int32)
        case bind(Int32)
        case address(String)
    }

    private let fd: Int32
    /// The port bound (useful after binding port 0).
    public let port: UInt16
    private var peers: [PeerKey: PeerID] = [:]
    private var addresses: [PeerID: sockaddr_in] = [:]
    private var nextPeer: UInt64 = 1
    private var buffer = [UInt8](repeating: 0, count: 65536)

    private struct PeerKey: Hashable {
        var address: UInt32
        var port: UInt16
    }

    /// Binds `host:port` (port 0: any free port). Servers bind a known port; clients bind 0.
    public init(host: String = "127.0.0.1", port: UInt16 = 0) throws {
        #if canImport(Darwin)
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        #else
        let fd = socket(AF_INET, Int32(SOCK_DGRAM.rawValue), Int32(IPPROTO_UDP))
        #endif
        guard fd >= 0 else { throw Failure.socket(errno) }
        var address = try Self.address(host: host, port: port)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bound == 0 else {
            let error = errno
            close(fd)
            throw Failure.bind(error)
        }
        _ = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK)
        var actual = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &actual) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) }
        }
        self.fd = fd
        self.port = UInt16(bigEndian: actual.sin_port)
    }

    deinit { close(fd) }

    /// The peer for `host:port`, registering it if new: a client's handle to its server.
    public func peer(host: String, port: UInt16) throws -> PeerID {
        peerID(for: try Self.address(host: host, port: port))
    }

    public func send(_ bytes: [UInt8], to peer: PeerID) {
        guard var address = addresses[peer] else { return }
        _ = bytes.withUnsafeBytes { buffer in
            withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(fd, buffer.baseAddress, buffer.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
    }

    public func receive() -> [NetDatagram] {
        var received: [NetDatagram] = []
        let fd = fd
        while true {
            var from = sockaddr_in()
            var length = socklen_t(MemoryLayout<sockaddr_in>.size)
            let count = buffer.withUnsafeMutableBytes { raw in
                withUnsafeMutablePointer(to: &from) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { recvfrom(fd, raw.baseAddress, raw.count, 0, $0, &length) }
                }
            }
            guard count >= 0 else { break } // EAGAIN: nothing left (or an error: try again next poll)
            received.append(NetDatagram(from: peerID(for: from), bytes: Array(buffer[0..<count])))
        }
        return received
    }

    private func peerID(for address: sockaddr_in) -> PeerID {
        let key = PeerKey(address: address.sin_addr.s_addr, port: address.sin_port)
        if let id = peers[key] { return id }
        let id = PeerID(nextPeer)
        nextPeer += 1
        peers[key] = id
        addresses[id] = address
        return id
    }

    private static func address(host: String, port: UInt16) throws -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else { throw Failure.address(host) }
        #if canImport(Darwin)
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        return address
    }
}
#endif
