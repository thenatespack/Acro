import CZlib
import Foundation
import Testing
@testable import Engine

/// Minimal PNG reader for 8-bit RGBA: checks chunk CRCs, inflates the concatenated IDATs with zlib
/// and undoes the row filters. Written independently of the encoder.
private struct DecodedPNG {
    var width = 0, height = 0
    var idatCount = 0
    var filtersUsed = Set<UInt8>()
    var pixels: [UInt8] = []
}

private func decodePNG(_ data: Data) -> DecodedPNG? {
    let b = [UInt8](data)
    guard b.count > 8, Array(b[0..<8]) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] else { return nil }
    func u32(_ o: Int) -> Int { Int(b[o]) << 24 | Int(b[o + 1]) << 16 | Int(b[o + 2]) << 8 | Int(b[o + 3]) }
    var out = DecodedPNG()
    var idat = [UInt8]()
    var pos = 8
    var sawEnd = false
    while pos + 12 <= b.count {
        let len = u32(pos)
        guard pos + 12 + len <= b.count else { return nil }
        let type = String(decoding: b[(pos + 4)..<(pos + 8)], as: UTF8.self)
        let body = Array(b[(pos + 8)..<(pos + 8 + len)])
        var crc = crc32(0, nil, 0)
        crc = b.withUnsafeBufferPointer { crc32(crc, $0.baseAddress! + pos + 4, UInt32(4 + len)) }
        guard Int(crc) == u32(pos + 8 + len) else { return nil }
        switch type {
        case "IHDR":
            out.width = u32(pos + 8); out.height = u32(pos + 12)
            guard Array(body[8...]) == [8, 6, 0, 0, 0] else { return nil }
        case "IDAT": idat += body; out.idatCount += 1
        case "IEND": sawEnd = true
        default: break
        }
        pos += 12 + len
    }
    guard sawEnd, pos == b.count else { return nil }

    let stride = out.width * 4 + 1
    var raw = [UInt8](repeating: 0, count: stride * out.height)
    var zs = z_stream()
    guard inflateInit_(&zs, zlibVersion(), Int32(MemoryLayout<z_stream>.size)) == Z_OK else { return nil }
    defer { inflateEnd(&zs) }
    let status: Int32 = idat.withUnsafeMutableBufferPointer { src in
        raw.withUnsafeMutableBufferPointer { dst in
            zs.next_in = src.baseAddress; zs.avail_in = UInt32(src.count)
            zs.next_out = dst.baseAddress; zs.avail_out = UInt32(dst.count)
            return inflate(&zs, Z_FINISH)
        }
    }
    guard status == Z_STREAM_END, zs.avail_out == 0, zs.avail_in == 0 else { return nil }  // Adler-32 verified by inflate

    let rowBytes = out.width * 4
    out.pixels = [UInt8](repeating: 0, count: rowBytes * out.height)
    for y in 0..<out.height {
        let f = raw[y * stride]
        out.filtersUsed.insert(f)
        for i in 0..<rowBytes {
            let x = Int(raw[y * stride + 1 + i])
            let a = i >= 4 ? Int(out.pixels[y * rowBytes + i - 4]) : 0
            let up = y > 0 ? Int(out.pixels[(y - 1) * rowBytes + i]) : 0
            let c = (i >= 4 && y > 0) ? Int(out.pixels[(y - 1) * rowBytes + i - 4]) : 0
            let v: Int
            switch f {
            case 0: v = x
            case 1: v = x + a
            case 2: v = x + up
            case 3: v = x + (a + up) / 2
            case 4:
                let p = a + up - c
                let pa = abs(p - a), pb = abs(p - up), pc = abs(p - c)
                v = x + ((pa <= pb && pa <= pc) ? a : (pb <= pc ? up : c))
            default: return nil
            }
            out.pixels[y * rowBytes + i] = UInt8(truncatingIfNeeded: v)
        }
    }
    return out
}

private struct LCG {
    var state: UInt64
    mutating func next() -> UInt8 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return UInt8(truncatingIfNeeded: state >> 33)
    }
}

private func testImage(width: Int, height: Int, noise: Bool) -> Image {
    var rng = LCG(state: 42)
    var px = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let i = (y * width + x) * 4
            if noise {
                for k in 0..<4 { px[i + k] = rng.next() }
            } else {
                // Smooth gradients, a diagonal edge and a few noisy rows to exercise several filters.
                px[i] = UInt8(truncatingIfNeeded: x * 3)
                px[i + 1] = UInt8(truncatingIfNeeded: y * 2)
                px[i + 2] = (x + y) % 40 < 20 ? 200 : UInt8(truncatingIfNeeded: x ^ y)
                px[i + 3] = y % 17 == 0 ? rng.next() : 255
            }
        }
    }
    return Image(width: width, height: height, pixels: px)
}

@Test(arguments: [(1, 1), (2, 2), (37, 150), (301, 65), (64, 64), (5, 129)])
func pngRoundTripsPixels(size: (Int, Int)) throws {
    for noise in [false, true] {
        let image = testImage(width: size.0, height: size.1, noise: noise)
        let decoded = try #require(decodePNG(image.pngData()))
        #expect(decoded.width == size.0 && decoded.height == size.1)
        #expect(decoded.pixels == image.pixels)
    }
}

@Test func pngCompressesAndUsesAdaptiveFilters() throws {
    let image = testImage(width: 256, height: 256, noise: false)
    let data = image.pngData()
    #expect(data.count < image.pixels.count / 4)
    let decoded = try #require(decodePNG(data))
    #expect(decoded.filtersUsed.count > 1)
    #expect(decoded.pixels == image.pixels)
}

@Test func pngSplitsLargeStreamsIntoMultipleIDATs() throws {
    let image = testImage(width: 600, height: 300, noise: true)  // incompressible, ~720 KB
    let decoded = try #require(decodePNG(image.pngData()))
    #expect(decoded.idatCount > 1)
    #expect(decoded.pixels == image.pixels)
}

@Test func pngEncodingIsDeterministic() {
    let image = testImage(width: 200, height: 150, noise: false)
    #expect(image.pngData() == image.pngData())
}

@Test func writePNGMatchesPNGData() throws {
    let image = testImage(width: 90, height: 70, noise: false)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("engine-png-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    try image.writePNG(to: url)
    #expect(try Data(contentsOf: url) == image.pngData())
}
