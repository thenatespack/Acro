import CZlib

/// Whole-buffer zlib streams (header, deflate, Adler-32) on CZlib: the system zlib natively, the
/// vendored copy in WebAssembly builds. Asset packs store compressed blobs with it (AssetPack.swift).
package enum Zlib {
    /// `bytes` compressed at `level` (0 to 9).
    package static func deflate(_ bytes: UnsafeRawBufferPointer, level: Int32 = 9) -> [UInt8] {
        var bound = compressBound(uLong(bytes.count))
        var out = [UInt8](repeating: 0, count: Int(bound))
        let status = out.withUnsafeMutableBufferPointer { o in
            compress2(o.baseAddress, &bound, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), uLong(bytes.count), level)
        }
        precondition(status == Z_OK, "compress2 failed (\(status))")
        out.removeSubrange(Int(bound)...)
        return out
    }

    package static func deflate(_ bytes: [UInt8], level: Int32 = 9) -> [UInt8] {
        bytes.withUnsafeBytes { deflate($0, level: level) }
    }

    /// The `size` bytes `stream` inflates to; nil when it is damaged or inflates to another size.
    package static func inflate(_ stream: UnsafeRawBufferPointer, size: Int) -> [UInt8]? {
        guard size >= 0 else { return nil }
        var out = [UInt8](repeating: 0, count: max(size, 1))
        var length = uLong(size)
        let status = out.withUnsafeMutableBufferPointer { o in
            uncompress(o.baseAddress, &length, stream.baseAddress?.assumingMemoryBound(to: UInt8.self), uLong(stream.count))
        }
        guard status == Z_OK, Int(length) == size else { return nil }
        if size == 0 { out.removeAll() }
        return out
    }
}
