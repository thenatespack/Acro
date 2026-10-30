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


    /// Encodes as a compressed PNG (zlib + adaptive row filters; see PNGEncoder).
    public func pngData() -> Data {
        var data = Data()
        // The sink never throws, so neither does the encode.
        try! pixels.withUnsafeBufferPointer { px in
            try PNGEncoder.encode(width: width, height: height, pixels: px) { data.append(contentsOf: $0) }
        }
        return data
    }

    /// Streams the PNG to disk row batch by row batch, so huge images need no extra full-size copy.
    public func writePNG(to url: URL) throws {
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try pixels.withUnsafeBufferPointer { px in
            try PNGEncoder.encode(width: width, height: height, pixels: px) { try handle.write(contentsOf: Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: $0.baseAddress!), count: $0.count, deallocator: .none)) }
        }
    }
}
