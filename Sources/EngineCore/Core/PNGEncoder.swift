import CZlib
import Dispatch
import Foundation

/// Streaming PNG encoder for 8-bit RGBA images.
///
/// Compression uses the system zlib (CZlib): it is present on macOS and effectively every Linux
/// distro, is what libpng itself uses (so the output is a standard zlib stream: header, deflate,
/// Adler-32), and is far smaller and faster than a hand-rolled deflate. Apple's Compression
/// framework was rejected because it is Darwin-only and its "zlib" is a raw deflate stream that
/// would need a hand-built header and Adler-32 anyway. A future Windows port needs zlib available
/// (vcpkg/system package); this is the only place that depends on it.
///
/// Each row gets the adaptive filter (None/Sub/Up/Average/Paeth) with the lowest sum of absolute
/// values (libpng's heuristic). Rows are filtered in parallel in small batches, then deflated in
/// order, so memory use beyond the source pixels is a few MB regardless of image size, and the
/// IDAT data is emitted as many ~256 KB chunks. The result is deterministic: identical pixels
/// always give identical bytes (fixed zlib parameters, and the filter choice is a pure function
/// of the row and the row above it, with ties broken by filter order).
enum PNGEncoder {
    private static let bytesPerPixel = 4
    private static let rowBatch = 64
    private static let idatChunkSize = 256 * 1024
    /// zlib level 4 with Z_FILTERED (as libpng does for filtered data) is a good size/speed balance
    /// for rendered images; level 6+ costs much more time for ~1% smaller files.
    private static let compressionLevel: Int32 = 4

    static func encode(
        width: Int, height: Int, pixels: UnsafeBufferPointer<UInt8>,
        write: (UnsafeRawBufferPointer) throws -> Void
    ) throws {
        precondition(pixels.count == width * height * bytesPerPixel)
        try signature.withUnsafeBytes { try write($0) }

        var header = [UInt8]()
        header += bigEndian(UInt32(width))
        header += bigEndian(UInt32(height))
        header += [8, 6, 0, 0, 0]  // 8-bit depth, RGBA, deflate, adaptive filtering, no interlace
        try writeChunk("IHDR", header, write)

        try compress(width: width, height: height, pixels: pixels, write: write)
        try writeChunk("IEND", [], write)
    }

    private static let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    // MARK: Compression

    private static func compress(
        width: Int, height: Int, pixels: UnsafeBufferPointer<UInt8>,
        write: (UnsafeRawBufferPointer) throws -> Void
    ) throws {
        let rowBytes = width * bytesPerPixel
        let stride = rowBytes + 1  // filter type byte + row
        guard height > 0, rowBytes > 0, let base = pixels.baseAddress else { return }

        var stream = z_stream()
        let status = deflateInit2_(
            &stream, compressionLevel, Z_DEFLATED, 15, 9, Z_FILTERED,
            zlibVersion(), Int32(MemoryLayout<z_stream>.size))
        precondition(status == Z_OK, "deflateInit2 failed")
        defer { deflateEnd(&stream) }

        // IDAT chunk buffer: 8-byte header (length, type) + data + 4-byte CRC.
        let out = UnsafeMutablePointer<UInt8>.allocate(capacity: 8 + idatChunkSize + 4)
        defer { out.deallocate() }
        out[4] = 0x49; out[5] = 0x44; out[6] = 0x41; out[7] = 0x54  // "IDAT"

        func flush(_ count: Int) throws {
            guard count > 0 else { return }
            storeBigEndian(UInt32(count), out)
            let crc = crc32(crc32(0, out + 4, 4), out + 8, UInt32(count))
            storeBigEndian(UInt32(crc), out + 8 + count)
            try write(UnsafeRawBufferPointer(start: out, count: 12 + count))
        }

        // Filtered batch of rows, plus an all-zero row standing in for "the row above" at y = 0.
        let batch = UnsafeMutablePointer<UInt8>.allocate(capacity: stride * rowBatch)
        let zeroRow = UnsafeMutablePointer<UInt8>.allocate(capacity: rowBytes)
        zeroRow.initialize(repeating: 0, count: rowBytes)
        defer { batch.deallocate(); zeroRow.deallocate() }
        // Scratch for filter candidates, one set per concurrent worker (indexed by row within batch).
        let scratchSize = rowBytes * 4
        let scratchPool = UnsafeMutablePointer<UInt8>.allocate(capacity: scratchSize * rowBatch)
        defer { scratchPool.deallocate() }

        var y = 0
        while y < height {
            let rows = min(rowBatch, height - y)
            let firstRow = y
            // Each worker reads shared source rows and writes only its own batch/scratch slices.
            // Linux's Dispatch requires a @Sendable closure, so the pointers go in through a box.
            let p = RowPointers(base: base, zeroRow: zeroRow, batch: batch, scratchPool: scratchPool)
            DispatchQueue.concurrentPerform(iterations: rows) { i in
                let row = firstRow + i
                let cur = p.base + row * rowBytes
                let prev = row == 0 ? UnsafePointer(p.zeroRow) : UnsafePointer(p.base + (row - 1) * rowBytes)
                filterRow(cur, prev, rowBytes, p.batch + i * stride, p.scratchPool + i * scratchSize)
            }

            stream.next_in = batch
            stream.avail_in = UInt32(rows * stride)
            let last = firstRow + rows == height
            repeat {
                stream.next_out = out + 8
                stream.avail_out = UInt32(idatChunkSize)
                let r = deflate(&stream, last ? Z_FINISH : Z_NO_FLUSH)
                precondition(r == Z_OK || r == Z_STREAM_END || r == Z_BUF_ERROR, "deflate failed (\(r))")
                try flush(idatChunkSize - Int(stream.avail_out))
            } while stream.avail_in > 0 || stream.avail_out == 0
            y += rows
        }
    }

    // MARK: Filtering

    /// Writes the filter type byte then the best-filtered row to `dst`.
    private static func filterRow(
        _ cur: UnsafePointer<UInt8>, _ prev: UnsafePointer<UInt8>, _ n: Int,
        _ dst: UnsafeMutablePointer<UInt8>, _ scratch: UnsafeMutablePointer<UInt8>
    ) {
        let bpp = bytesPerPixel
        // Candidates 1...4 (Sub, Up, Average, Paeth); candidate 0 (None) is the source row itself.
        let sub = scratch, up = scratch + n, avg = scratch + 2 * n, paeth = scratch + 3 * n

        @inline(__always) func cost(_ v: UInt8) -> Int {
            let s = Int(Int8(bitPattern: v))
            return s < 0 ? -s : s
        }
        var cNone = 0, cSub = 0, cUp = 0, cAvg = 0, cPaeth = 0
        for i in 0..<n {
            let x = cur[i], b = prev[i]
            let a = i >= bpp ? cur[i - bpp] : 0
            let c = i >= bpp ? prev[i - bpp] : 0
            let s = x &- a
            let u = x &- b
            let av = x &- UInt8((Int(a) + Int(b)) >> 1)
            let p = Int(a) + Int(b) - Int(c)
            let pa = abs(p - Int(a)), pb = abs(p - Int(b)), pc = abs(p - Int(c))
            let pred = (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c)
            let pt = x &- pred
            sub[i] = s; up[i] = u; avg[i] = av; paeth[i] = pt
            cNone += cost(x); cSub += cost(s); cUp += cost(u); cAvg += cost(av); cPaeth += cost(pt)
        }
        var best = 0, bestCost = cNone, src = cur
        if cSub < bestCost { best = 1; bestCost = cSub; src = UnsafePointer(sub) }
        if cUp < bestCost { best = 2; bestCost = cUp; src = UnsafePointer(up) }
        if cAvg < bestCost { best = 3; bestCost = cAvg; src = UnsafePointer(avg) }
        if cPaeth < bestCost { best = 4; src = UnsafePointer(paeth) }
        dst[0] = UInt8(best)
        (dst + 1).update(from: src, count: n)
    }

    // MARK: Chunks

    private static func writeChunk(
        _ type: String, _ data: [UInt8], _ write: (UnsafeRawBufferPointer) throws -> Void
    ) throws {
        let body = Array(type.utf8) + data
        let crc = body.withUnsafeBufferPointer { UInt32(crc32(0, $0.baseAddress, UInt32($0.count))) }
        let bytes = bigEndian(UInt32(data.count)) + body + bigEndian(crc)
        try bytes.withUnsafeBytes(write)
    }

    private static func bigEndian(_ value: UInt32) -> [UInt8] {
        [UInt8(value >> 24), UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private static func storeBigEndian(_ value: UInt32, _ p: UnsafeMutablePointer<UInt8>) {
        p[0] = UInt8(value >> 24); p[1] = UInt8((value >> 16) & 0xFF)
        p[2] = UInt8((value >> 8) & 0xFF); p[3] = UInt8(value & 0xFF)
    }
}

/// Pointers shared by the row-filter workers. Unchecked: workers only read `base`/`zeroRow`
/// and write disjoint slices of `batch`/`scratchPool`.
private struct RowPointers: @unchecked Sendable {
    let base: UnsafePointer<UInt8>
    let zeroRow: UnsafeMutablePointer<UInt8>
    let batch: UnsafeMutablePointer<UInt8>
    let scratchPool: UnsafeMutablePointer<UInt8>
}
