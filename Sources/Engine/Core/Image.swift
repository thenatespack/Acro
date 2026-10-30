import Foundation

/// 8-bit RGBA pixels, rows top to bottom.
public struct Image: Sendable {
    public var width: Int
    public var height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(pixels.count == width * height * 4)
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// Builds an image from BGRA rows (the swapchain byte order on both backends).
    init(width: Int, height: Int, bgra: UnsafeRawBufferPointer, bytesPerRow: Int) {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let src = y * bytesPerRow + x * 4
                let dst = (y * width + x) * 4
                pixels[dst] = bgra[src + 2]
                pixels[dst + 1] = bgra[src + 1]
                pixels[dst + 2] = bgra[src]
                pixels[dst + 3] = bgra[src + 3]
            }
        }
        self.init(width: width, height: height, pixels: pixels)
    }

    /// Encodes as an uncompressed PNG (no zlib dependency).
    public func pngData() -> Data {
        // Raw scanlines, each prefixed with filter type 0.
        var raw = [UInt8]()
        raw.reserveCapacity((width * 4 + 1) * height)
        for y in 0..<height {
            raw.append(0)
            raw.append(contentsOf: pixels[(y * width * 4)..<((y + 1) * width * 4)])
        }

        // zlib stream made of "stored" deflate blocks (max 65535 bytes each).
        var zlib: [UInt8] = [0x78, 0x01]
        var offset = 0
        repeat {
            let count = min(65535, raw.count - offset)
            let isFinal: UInt8 = offset + count == raw.count ? 1 : 0
            zlib.append(isFinal)
            zlib.append(contentsOf: [UInt8(count & 0xFF), UInt8(count >> 8), UInt8(~count & 0xFF), UInt8((~count >> 8) & 0xFF)])
            zlib.append(contentsOf: raw[offset..<(offset + count)])
            offset += count
        } while offset < raw.count
        zlib.append(contentsOf: Self.bigEndian(Self.adler32(raw)))

        var header = Self.bigEndian(UInt32(width)) + Self.bigEndian(UInt32(height))
        header += [8, 6, 0, 0, 0]  // 8-bit depth, RGBA, deflate, no filter, no interlace

        var png: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        png += Self.chunk("IHDR", header)
        png += Self.chunk("IDAT", zlib)
        png += Self.chunk("IEND", [])
        return Data(png)
    }

    public func writePNG(to url: URL) throws {
        try pngData().write(to: url)
    }

    private static func chunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
        let body = Array(type.utf8) + data
        return bigEndian(UInt32(data.count)) + body + bigEndian(crc32(body))
    }

    private static func bigEndian(_ value: UInt32) -> [UInt8] {
        [UInt8(value >> 24), UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private static let crcTable: [UInt32] = (0..<256).map { n in
        var c = UInt32(n)
        for _ in 0..<8 { c = c & 1 != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    private static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in bytes { c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }

    private static func adler32(_ bytes: [UInt8]) -> UInt32 {
        var a: UInt32 = 1, b: UInt32 = 0
        for byte in bytes {
            a = (a + UInt32(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }
}
