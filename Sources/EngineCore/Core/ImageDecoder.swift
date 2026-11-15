import CStbImage
import Foundation

/// Linear floating-point RGBA pixels (RGBA32F), rows top to bottom. What HDR images decode to.
public struct FloatImage: Sendable {
    public var width: Int
    public var height: Int
    /// `width * height * 4` floats: R, G, B, A per pixel.
    public var pixels: [Float]

    public init(width: Int, height: Int, pixels: [Float]) {
        precondition(pixels.count == width * height * 4)
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

/// The result of `ImageDecoder.decodeAny`.
public enum DecodedImage: Sendable {
    /// PNG, JPEG, TGA: 8-bit RGBA, with the file's encoding (usually sRGB for color, linear for data).
    case rgba8(Image)
    /// Radiance HDR: linear float RGBA.
    case rgba32F(FloatImage)

    public var width: Int {
        switch self {
        case .rgba8(let image): image.width
        case .rgba32F(let image): image.width
        }
    }

    public var height: Int {
        switch self {
        case .rgba8(let image): image.height
        case .rgba32F(let image): image.height
        }
    }
}

public struct ImageDecodeError: Error, CustomStringConvertible, Sendable {
    public var description: String
    public init(_ description: String) { self.description = description }
}

/// Decodes PNG, JPEG, TGA and Radiance HDR files (stb_image, vendored in `CStbImage`) from
/// memory. Everything expands to four channels: gray, gray + alpha and RGB become RGBA, with
/// alpha 255 (1.0) when the file has none. 16-bit PNGs are reduced to 8 bits.
///
/// Pure CPU work with no shared state (the engine never touches stb_image's global options,
/// and its error string is thread-local), so it is safe to call from any thread, e.g. several
/// background loaders at once. Upload the result with `RenderDevice.makeTexture(image:...)`
/// on the main thread.
public enum ImageDecoder {
    /// Decodes any supported file to 8-bit RGBA. An HDR file is clamped to 0...1; use
    /// `decodeFloat` or `decodeAny` to keep its range.
    public static func decode(_ data: Data) throws -> Image {
        var width: Int32 = 0, height: Int32 = 0, channels: Int32 = 0
        let pixels: UnsafeMutablePointer<UInt8>? = data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress, let count = Int32(exactly: raw.count)
            else { return nil }
            return stbi_load_from_memory(base, count, &width, &height, &channels, 4)
        }
        guard let pixels else { throw failure(data) }
        defer { stbi_image_free(pixels) }
        let count = Int(width) * Int(height) * 4
        return Image(width: Int(width), height: Int(height), pixels: Array(UnsafeBufferPointer(start: pixels, count: count)))
    }

    /// Decodes any supported file to linear float RGBA. 8-bit formats are converted the way
    /// stb_image does (a plain 2.2 gamma on color); prefer `decode` for those.
    public static func decodeFloat(_ data: Data) throws -> FloatImage {
        var width: Int32 = 0, height: Int32 = 0, channels: Int32 = 0
        let pixels: UnsafeMutablePointer<Float>? = data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress, let count = Int32(exactly: raw.count)
            else { return nil }
            return stbi_loadf_from_memory(base, count, &width, &height, &channels, 4)
        }
        guard let pixels else { throw failure(data) }
        defer { stbi_image_free(pixels) }
        let count = Int(width) * Int(height) * 4
        return FloatImage(width: Int(width), height: Int(height), pixels: Array(UnsafeBufferPointer(start: pixels, count: count)))
    }

    /// Decodes an HDR file to `.rgba32F` and everything else to `.rgba8`.
    public static func decodeAny(_ data: Data) throws -> DecodedImage {
        try isHDR(data) ? .rgba32F(decodeFloat(data)) : .rgba8(decode(data))
    }

    /// Reads the file at `url` and decodes it like `decodeAny`.
    public static func decodeAny(contentsOf url: URL) throws -> DecodedImage {
        try decodeAny(Data(contentsOf: url))
    }

    /// Reads the file at `url` and decodes it to 8-bit RGBA.
    public static func decode(contentsOf url: URL) throws -> Image {
        try decode(Data(contentsOf: url))
    }

    /// True if `data` looks like a Radiance HDR file (by its header, not its extension).
    public static func isHDR(_ data: Data) -> Bool {
        data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress, let count = Int32(exactly: raw.count)
            else { return false }
            return stbi_is_hdr_from_memory(base, count) != 0
        }
    }

    /// Width and height from the header only, without decoding the pixels.
    public static func size(of data: Data) throws -> (width: Int, height: Int) {
        var width: Int32 = 0, height: Int32 = 0, channels: Int32 = 0
        let ok: Int32 = data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress, let count = Int32(exactly: raw.count)
            else { return 0 }
            return stbi_info_from_memory(base, count, &width, &height, &channels)
        }
        guard ok != 0 else { throw failure(data) }
        return (Int(width), Int(height))
    }

    private static func failure(_ data: Data) -> ImageDecodeError {
        if data.isEmpty { return ImageDecodeError("Image data is empty") }
        let reason = stbi_failure_reason().map { String(cString: $0) } ?? "unknown error"
        return ImageDecodeError("Could not decode image: \(reason)")
    }
}
