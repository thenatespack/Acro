import Foundation
import Testing
@testable import Engine

/// A 4x4 JPEG (red ramps along x, green along y, blue 128), made with a standard encoder.
private let tinyJPEG = Data(base64Encoded: "/9j/4AAQSkZJRgABAQAASABIAAD/4QBMRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABKADAAQAAAABAAAABAAAAAD/7QA4UGhvdG9zaG9wIDMuMAA4QklNBAQAAAAAAAA4QklNBCUAAAAAABDUHYzZjwCyBOmACZjs+EJ+/8AAEQgABAAEAwERAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/bAEMBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/dAAQAAf/aAAwDAQACEQMRAD8A/W/9lD/glR+xcfgr4ZP/AArTr5n/AC8WH/Pva/8AUJr+L/GH6Yfjv/r5mv8AxlX8v/LvE/8APyr/ANRy/X1Pov2bf09vpLf8Sm+H/wDxm3/P7/l3i/8AoCy3/qLP/9k=")!

@Test func pngRoundTripIsLossless() throws {
    var pixels: [UInt8] = []
    for y in 0..<5 { for x in 0..<7 { pixels += [UInt8(x * 30), UInt8(y * 50), UInt8(x * y), UInt8(255 - x * 20)] } }
    let image = Image(width: 7, height: 5, pixels: pixels)
    let decoded = try ImageDecoder.decode(image.pngData())
    #expect(decoded.width == 7 && decoded.height == 5)
    #expect(decoded.pixels == pixels)
    let size = try ImageDecoder.size(of: image.pngData())
    #expect(size.width == 7 && size.height == 5)
}

@Test func jpegDecodesToRGBA() throws {
    let image = try ImageDecoder.decode(tinyJPEG)
    #expect(image.width == 4 && image.height == 4)
    #expect(image.pixels.count == 64)
    // Lossy, so compare with a tolerance: top-left is (0, 0, 128), bottom-right (240, 240, 128).
    func close(_ x: Int, _ y: Int, _ r: Int, _ g: Int, _ b: Int) -> Bool {
        let i = (y * 4 + x) * 4
        return abs(Int(image.pixels[i]) - r) < 24 && abs(Int(image.pixels[i + 1]) - g) < 24
            && abs(Int(image.pixels[i + 2]) - b) < 24 && image.pixels[i + 3] == 255
    }
    #expect(close(0, 0, 0, 0, 128))
    #expect(close(3, 3, 240, 240, 128))
    #expect(close(3, 0, 240, 0, 128))
}

@Test func tgaDecodesTopLeftOrigin() throws {
    // 2x1, 24-bit uncompressed true color, descriptor bit 5 = top-left origin. BGR order.
    var tga = Data([0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 24, 0x20])
    tga.append(contentsOf: [0, 0, 255, 255, 0, 0])  // red, then blue
    let image = try ImageDecoder.decode(tga)
    #expect(image.pixels == [255, 0, 0, 255, 0, 0, 255, 255])
}

private func hdrFile(_ pixels: [[UInt8]], width: Int, height: Int) -> Data {
    var data = Data("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y \(height) +X \(width)\n".utf8)
    for pixel in pixels { data.append(contentsOf: pixel) }
    return data
}

@Test func hdrDecodesToFloatAndKeepsRange() throws {
    // RGBE (128, 64, 32, e = 130) is (128, 64, 32) / 256 * 2^(130 - 128) = (2, 1, 0.5).
    let data = hdrFile([[128, 64, 32, 130], [0, 0, 0, 0]], width: 2, height: 1)
    #expect(ImageDecoder.isHDR(data))
    #expect(!ImageDecoder.isHDR(tinyJPEG))
    let image = try ImageDecoder.decodeFloat(data)
    #expect(image.width == 2 && image.height == 1)
    #expect(abs(image.pixels[0] - 2) < 0.02 && abs(image.pixels[1] - 1) < 0.02 && abs(image.pixels[2] - 0.5) < 0.02)
    #expect(image.pixels[3] == 1)
    #expect(Array(image.pixels[4...6]) == [0, 0, 0])
    guard case .rgba32F(let any) = try ImageDecoder.decodeAny(data) else { Issue.record("expected float"); return }
    #expect(any.pixels == image.pixels)
    guard case .rgba8 = try ImageDecoder.decodeAny(tinyJPEG) else { Issue.record("expected 8-bit"); return }
}

@Test func garbageAndEmptyInputThrowReadableErrors() {
    #expect(throws: ImageDecodeError.self) { try ImageDecoder.decode(Data("this is not an image".utf8)) }
    #expect(throws: ImageDecodeError.self) { try ImageDecoder.decode(Data()) }
    #expect(throws: ImageDecodeError.self) { try ImageDecoder.decodeFloat(Data([1, 2, 3])) }
    #expect(throws: ImageDecodeError.self) { try ImageDecoder.size(of: Data([0x89, 0x50])) }
    // A PNG cut off in the middle.
    let png = Image(width: 8, height: 8, pixels: [UInt8](repeating: 7, count: 256)).pngData()
    do {
        _ = try ImageDecoder.decode(png.prefix(png.count / 2))
        Issue.record("truncated PNG should fail")
    } catch {
        #expect("\(error)".contains("Could not decode image"))
    }
}

@Test func decodingFromManyThreadsAtOnce() async throws {
    let png = Image(width: 16, height: 16, pixels: (0..<1024).map { UInt8($0 % 251) }).pngData()
    try await withThrowingTaskGroup(of: Bool.self) { group in
        for i in 0..<16 {
            group.addTask {
                // Half the tasks decode garbage so the thread-local error string is exercised too.
                if i % 2 == 0 { return try ImageDecoder.decode(png).pixels.count == 1024 }
                do { _ = try ImageDecoder.decode(Data("garbage".utf8)); return false } catch { return true }
            }
        }
        for try await ok in group { #expect(ok) }
    }
}

@Test func halfFloatConversionRoundTrips() {
    for value: Float in [0, 1, -1, 0.5, 2, 4, 1024, 65504, 0x1p-14] {
        #expect(Half.value(Half.bits(value)) == value)
    }
    #expect(Half.bits(1) == 0x3C00 && Half.bits(-2) == 0xC000)
    #expect(Half.bits(1e9) == 0x7C00)  // overflow -> +inf
    #expect(Half.value(Half.bits(.nan)).isNaN)
    #expect(abs(Half.value(Half.bits(0.1)) - 0.1) < 1e-4)
    // Smallest subnormal, and round-to-even on ties.
    #expect(Half.value(Half.bits(0x1p-24)) == 0x1p-24)
    #expect(Half.bits(1 + 0x1p-11) == 0x3C00)
    #expect(Half.bits(1 + 3 * 0x1p-11) == 0x3C02)
}

@Test func floatMipChainAveragesInLinearFloat() {
    // 2x2 with one very bright texel: the 1x1 level is the plain average, not clamped.
    var pixels = [Float](repeating: 0, count: 16)
    pixels[0] = 8
    pixels[3] = 1
    let levels = MipChain.generateFloat(pixels: pixels, width: 2, height: 2)
    #expect(levels.count == 2)
    #expect(levels[0].pixels.count == 16 * 2 && levels[1].pixels.count == 4 * 2)
    let top = (0..<4).map { Half.value(UInt16(levels[1].pixels[$0 * 2]) | UInt16(levels[1].pixels[$0 * 2 + 1]) << 8) }
    #expect(top == [2, 0, 0, 0.25])
    #expect(MipChain.generateFloat(pixels: pixels, width: 2, height: 2, generateMipmaps: false).count == 1)
}

@Test func mipChainSizesForNonSquareImages() {
    let pixels = [UInt8](repeating: 100, count: 13 * 5 * 4)
    let sizes = MipChain.generate(pixels: pixels, width: 13, height: 5, srgb: true).map { [$0.width, $0.height] }
    #expect(sizes == [[13, 5], [6, 2], [3, 1], [1, 1]])
}

@Test func srgbMipsAverageInLinearLight() {
    // Black and sRGB 188 (about 50% linear) average to 25% linear = sRGB ~137, not the naive 94.
    let pixels: [UInt8] = [0, 0, 0, 255, 188, 188, 188, 255, 188, 188, 188, 255, 0, 0, 0, 255]
    let srgb = MipChain.generate(pixels: pixels, width: 2, height: 2, srgb: true)[1].pixels
    let linear = MipChain.generate(pixels: pixels, width: 2, height: 2, srgb: false)[1].pixels
    #expect(abs(Int(srgb[0]) - 137) <= 2)
    #expect(linear[0] == 94)
    #expect(srgb[3] == 255 && linear[3] == 255)
}

@Test func textureUploadValidation() throws {
    try TextureFormat.rgba16Float.validateUpload(byteCount: 2 * 2 * 8, width: 2, height: 2, maxSize: 16)
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba16Float.validateUpload(byteCount: 16, width: 2, height: 2, maxSize: 16) }
    let level = { (w: Int, h: Int) in TextureMipLevel(width: w, height: h, pixels: [UInt8](repeating: 0, count: w * h * 4)) }
    try TextureFormat.rgba8Unorm.validateLevels([level(4, 2), level(2, 1)], maxSize: 16)
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba8Unorm.validateLevels([], maxSize: 16) }
    #expect(throws: GraphicsError.self) { try TextureFormat.rgba8Unorm.validateLevels([level(4, 2), level(3, 1)], maxSize: 16) }
    #expect(throws: GraphicsError.self) {
        try TextureFormat.rgba8Unorm.validateLevels([level(4, 2), level(2, 1), level(1, 1), level(1, 1)], maxSize: 16)
    }
}

@Test func textureUpdateValidation() throws {
    let region = TextureRegion(x: 2, y: 1, width: 2, height: 3)
    try TextureFormat.rgba8Unorm.validateUpdate(region, mipLevel: 0, byteCount: 24, width: 4, height: 4, mipLevelCount: 3)
    try TextureFormat.rgba16Float.validateUpdate(region, mipLevel: 0, byteCount: 48, width: 4, height: 4, mipLevelCount: 1)
    // Mip 1 of a 4x4 texture is 2x2: the region no longer fits.
    #expect(throws: GraphicsError.self) {
        try TextureFormat.rgba8Unorm.validateUpdate(region, mipLevel: 1, byteCount: 24, width: 4, height: 4, mipLevelCount: 3)
    }
    #expect(throws: GraphicsError.self) {
        try TextureFormat.rgba8Unorm.validateUpdate(region, mipLevel: 3, byteCount: 24, width: 4, height: 4, mipLevelCount: 3)
    }
    #expect(throws: GraphicsError.self) {
        try TextureFormat.rgba8Unorm.validateUpdate(region, mipLevel: 0, byteCount: 23, width: 4, height: 4, mipLevelCount: 3)
    }
    #expect(throws: GraphicsError.self) {
        try TextureFormat.rgba8Unorm.validateUpdate(
            TextureRegion(x: 3, y: 0, width: 2, height: 1), mipLevel: 0, byteCount: 8, width: 4, height: 4, mipLevelCount: 1)
    }
    #expect(throws: GraphicsError.self) {
        try TextureFormat.depth32Float.validateUpdate(region, mipLevel: 0, byteCount: 24, width: 4, height: 4, mipLevelCount: 1)
    }
}
