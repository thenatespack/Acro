import Foundation
import Testing
@testable import Engine
#if canImport(QuartzCore)
import QuartzCore
#endif

// BC7 / ASTC 4x4 textures: block math and validation, the encoders and decoders, the texture
// importer's `compression` setting and its caches, and uploads on every backend.

/// A test picture: smooth color gradients, a hard-edged disc and some noise in the alpha-less
/// bottom band, opaque.
private func testImage(width: Int, height: Int, seed: UInt32 = 1) -> Image {
    var pixels = [UInt8](repeating: 255, count: width * height * 4)
    var state = seed
    for y in 0..<height {
        for x in 0..<width {
            let i = (y * width + x) * 4
            let u = Float(x) / Float(max(width - 1, 1)), v = Float(y) / Float(max(height - 1, 1))
            var color = (u * 255, v * 255, (0.5 + 0.5 * sinf((u + v) * 6)) * 255)
            let dx = u - 0.35, dy = v - 0.4
            if dx * dx + dy * dy < 0.04 { color = (230, 40, 30) }
            if v > 0.8 {
                state = state &* 1_664_525 &+ 1_013_904_223
                let noise = Float(state >> 24) - 128
                color = (min(max(color.0 + noise * 0.25, 0), 255), color.1, color.2)
            }
            pixels[i] = UInt8(color.0)
            pixels[i + 1] = UInt8(color.1)
            pixels[i + 2] = UInt8(color.2)
        }
    }
    return Image(width: width, height: height, pixels: pixels)
}

/// Peak signal-to-noise ratio of `b` against `a` over RGBA, in dB, and the largest channel error.
private func compare(_ a: [UInt8], _ b: [UInt8]) -> (psnr: Double, maxError: Int) {
    precondition(a.count == b.count)
    var squared = 0.0, maxError = 0
    for (x, y) in zip(a, b) {
        let d = Int(x) - Int(y)
        squared += Double(d * d)
        maxError = max(maxError, abs(d))
    }
    let mse = squared / Double(a.count)
    return (mse == 0 ? .infinity : 10 * log10(255 * 255 / mse), maxError)
}

private func srgbToLinear(_ value: UInt8) -> Float {
    let c = Float(value) / 255
    return c <= 0.04045 ? c / 12.92 : powf((c + 0.055) / 1.055, 2.4)
}

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TextureCompressionTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Compression")
}

@Suite struct TextureCompressionTests {
    // MARK: Block math and validation

    @Test func blockSizesAndRowPitch() {
        for format in TextureFormat.compressedFormats {
            #expect(format.isCompressed && format.blockSize == 4 && format.bytesPerBlock == 16)
            #expect(format.bytesPerRow(width: 1) == 16)
            #expect(format.bytesPerRow(width: 4) == 16)
            #expect(format.bytesPerRow(width: 5) == 32)
            #expect(format.byteCount(width: 5, height: 3) == 32)  // 2 x 1 blocks
            #expect(format.byteCount(width: 1, height: 1) == 16)
            #expect(format.byteCount(width: 256, height: 128) == 256 * 128)  // 8 bits per texel
        }
        #expect(TextureFormat.rgba8Srgb.byteCount(width: 5, height: 3) == 60)
        #expect(TextureFormat.rgba16Float.bytesPerRow(width: 3) == 24)
        #expect(!TextureFormat.rgba8Unorm.isCompressed && TextureFormat.rgba8Unorm.blockSize == 1)
        #expect([TextureFormat.bc7Srgb, .astc4x4Srgb, .rgba8Srgb].allSatisfy { $0.isSRGB })
        #expect(![TextureFormat.bc7Unorm, .astc4x4Unorm, .rgba8Unorm].contains { $0.isSRGB })
        #expect(TextureFormat.bc7Srgb.decompressedFormat == .rgba8Srgb)
        #expect(TextureFormat.astc4x4Unorm.decompressedFormat == .rgba8Unorm)
        #expect(TextureCompression.bc7.format(srgb: false) == .bc7Unorm)
        #expect(TextureCompression.astc.format(srgb: true) == .astc4x4Srgb)
        #expect(TextureCompression.none.format(srgb: true) == nil)
        #expect(TextureCompression.auto.format(srgb: true)?.isCompressed == true)
    }

    @Test func compressedUploadsAreValidatedInBlocks() throws {
        let format = TextureFormat.bc7Srgb
        try format.validateUpload(byteCount: 32, width: 5, height: 3, maxSize: 64)
        #expect(throws: GraphicsError.self) { try format.validateUpload(byteCount: 60, width: 5, height: 3, maxSize: 64) }
        // A 6x6 chain: 6x6, 3x3, 1x1, each at least one block.
        try format.validateLevels([TextureMipLevel(width: 6, height: 6, pixels: .init(repeating: 0, count: 64)),
                                   TextureMipLevel(width: 3, height: 3, pixels: .init(repeating: 0, count: 16)),
                                   TextureMipLevel(width: 1, height: 1, pixels: .init(repeating: 0, count: 16))], maxSize: 64)
        // Updates: whole blocks, or partial blocks only at the level's right / bottom edge.
        try format.validateUpdate(TextureRegion(x: 4, y: 0, width: 4, height: 8), mipLevel: 0, byteCount: 32,
                                  width: 16, height: 16, mipLevelCount: 1)
        try format.validateUpdate(TextureRegion(x: 4, y: 4, width: 2, height: 2), mipLevel: 0, byteCount: 16,
                                  width: 6, height: 6, mipLevelCount: 1)
        #expect(throws: GraphicsError.self) {
            try format.validateUpdate(TextureRegion(x: 2, y: 0, width: 4, height: 4), mipLevel: 0, byteCount: 16,
                                      width: 16, height: 16, mipLevelCount: 1)
        }
        #expect(throws: GraphicsError.self) {
            try format.validateUpdate(TextureRegion(x: 0, y: 0, width: 6, height: 4), mipLevel: 0, byteCount: 32,
                                      width: 16, height: 16, mipLevelCount: 1)
        }
        #expect(throws: GraphicsError.self) {
            try format.validateUpdate(TextureRegion(x: 0, y: 0, width: 4, height: 4), mipLevel: 0, byteCount: 64,
                                      width: 16, height: 16, mipLevelCount: 1)
        }
    }

    // MARK: Encoders and decoders

    @Test(arguments: TextureFormat.compressedFormats)
    func roundTripStaysCloseToTheSource(format: TextureFormat) throws {
        let image = testImage(width: 64, height: 64)
        let levels = try TextureCodec.encode(image, format: format, mipmaps: true)
        #expect(levels.map(\.width) == [64, 32, 16, 8, 4, 2, 1])
        #expect(levels.allSatisfy { $0.pixels.count == format.byteCount(width: $0.width, height: $0.height) })
        let decoded = try TextureCodec.decode(levels[0], format: format)
        let (psnr, maxError) = compare(image.pixels, decoded.pixels)
        #expect(psnr > 38, "\(format): \(psnr) dB")
        #expect(maxError < 64, "\(format): max error \(maxError)")
        // Opaque stays opaque.
        #expect(stride(from: 3, to: decoded.pixels.count, by: 4).allSatisfy { decoded.pixels[$0] == 255 })
        // Lower levels decode close to the CPU mip chain they were made from (less so the
        // smaller ones, where the whole picture shares a few blocks).
        let mips = MipChain.generate(pixels: image.pixels, width: 64, height: 64, srgb: format.isSRGB)
        for (level, minimum) in [(1, 33.0), (2, 25.0)] {
            let decodedLevel = try TextureCodec.decode(levels[level], format: format)
            let psnr = compare(mips[level].pixels, decodedLevel.pixels).psnr
            #expect(psnr > minimum, "\(format) level \(level): \(psnr) dB")
        }
        // Encoding is deterministic, however the work was split between threads.
        #expect(try TextureCodec.encode(image, format: format, mipmaps: true).map(\.pixels) == levels.map(\.pixels))
    }

    @Test(arguments: [TextureFormat.bc7Unorm, .astc4x4Unorm])
    func sizesThatArentMultiplesOfFourAndAlphaRoundTrip(format: TextureFormat) throws {
        // Red ramps across, green down, and alpha across too, so blocks need the alpha modes.
        let (width, height) = (13, 7)
        var pixels = [UInt8](repeating: 100, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                pixels[i] = UInt8(x * 255 / (width - 1))
                pixels[i + 1] = UInt8(y * 255 / (height - 1))
                pixels[i + 3] = UInt8(x * 255 / (width - 1))
            }
        }
        let image = Image(width: width, height: height, pixels: pixels)
        let level = try #require(try TextureCodec.encode(image, format: format, mipmaps: false).first)
        #expect(level.pixels.count == 4 * 2 * 16)
        let decoded = try TextureCodec.decode(level, format: format)
        #expect(decoded.width == width && decoded.height == height)
        // The edge blocks (repeated last column / row) decode as well as the others.
        var worst = [0, 0, 0, 0]
        for (i, (a, b)) in zip(image.pixels, decoded.pixels).enumerated() { worst[i % 4] = max(worst[i % 4], abs(Int(a) - Int(b))) }
        #expect(worst.allSatisfy { $0 <= 32 }, "\(format): worst error per channel \(worst)")
        #expect(compare(image.pixels, decoded.pixels).psnr > 30, "\(format)")  // steep ramps: ~42 levels per texel
    }

    @Test func encoderRejectsBadInput() {
        #expect(throws: GraphicsError.self) {
            try TextureCodec.encode(levels: [TextureMipLevel(width: 4, height: 4, pixels: [0])], format: .bc7Srgb)
        }
        #expect(throws: GraphicsError.self) { try TextureCodec.encode(testImage(width: 4, height: 4), format: .rgba8Srgb) }
        #expect(throws: GraphicsError.self) {
            try TextureCodec.decode(TextureMipLevel(width: 8, height: 8, pixels: [UInt8](repeating: 0, count: 16)), format: .astc4x4Srgb)
        }
    }

    // MARK: Importer

    @MainActor @Test func importerCompressesCachesAndReusesEncodings() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let image = testImage(width: 40, height: 24)
        try image.pngData().write(to: project.assetsURL.appendingPathComponent("wall.png"))
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "wall.png"))
        let reference = AssetReference(id, subAsset: "texture")
        #expect(database.texture(reference)?.format == .rgba8Srgb)
        // Sidecars from before the setting decode with compression off.
        let old = try JSONDecoder().decode(TextureImporter.Settings.self, from: Data(#"{"sRGB": false}"#.utf8))
        #expect(old == TextureImporter.Settings(sRGB: false, mipmaps: true, compression: .none, compressionQuality: .normal))

        try database.setSettings(TextureImporter.Settings(compression: .bc7), for: id)
        let texture = try #require(database.texture(reference))
        #expect(texture.format == .bc7Srgb && texture.isSRGB && texture.generatesMipmaps)
        #expect(texture.width == 40 && texture.height == 24)
        let levels = try #require(texture.compressedLevels)
        #expect(levels.count == MipChain.levelCount(width: 40, height: 24))
        #expect(texture.gpuByteCount == levels.reduce(0) { $0 + $1.pixels.count })
        #expect(compare(image.pixels, texture.image.pixels).psnr > 30)

        // The Library cache keeps the compressed chain bit for bit.
        let reopened = AssetDatabase(project: project)
        reopened.scan()
        #expect(reopened.texture(reference)?.compressedLevels?.map(\.pixels) == levels.map(\.pixels))

        // The encoding is cached by inputs: a forced reimport reads it instead of encoding again.
        // Proof: a marked copy of the cached blocks comes back.
        let cacheFile = database.artifactsURL(id).appendingPathComponent("cache/bc7Srgb.bin")
        var cached = try Data(contentsOf: cacheFile)
        cached[cached.count - 1] ^= 0xFF
        try cached.write(to: cacheFile)
        database.reimport(id)
        let reimported = try #require(database.texture(reference)?.compressedLevels)
        #expect(reimported.last?.pixels.last == levels.last!.pixels.last! ^ 0xFF)

        // Other settings encode afresh: linear data, ASTC, no mipmaps.
        try database.setSettings(TextureImporter.Settings(sRGB: false, mipmaps: false, compression: .astc), for: id)
        let astc = try #require(database.texture(reference))
        #expect(astc.format == .astc4x4Unorm && !astc.generatesMipmaps && astc.compressedLevels?.count == 1)
        #expect(FileManager.default.fileExists(atPath: database.artifactsURL(id).appendingPathComponent("cache/astc4x4Unorm.bin").path))
        // Switching back to BC7 sRGB with mips finds the first encoding (still marked).
        try database.setSettings(TextureImporter.Settings(compression: .bc7), for: id)
        #expect(database.texture(reference)?.compressedLevels?.last?.pixels.last == levels.last!.pixels.last! ^ 0xFF)
        // A changed source misses the cache.
        try testImage(width: 40, height: 24, seed: 9).pngData().write(to: project.assetsURL.appendingPathComponent("wall.png"))
        database.reimport(id)
        #expect(database.texture(reference)?.compressedLevels?.last?.pixels.last == levels.last!.pixels.last!)
    }

    @MainActor @Test func hdrTexturesIgnoreCompressionWithAWarning() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        var hdr = Data("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 2\n".utf8)
        hdr.append(contentsOf: [128, 64, 32, 130, 0, 0, 0, 0])
        try hdr.write(to: project.assetsURL.appendingPathComponent("sky.hdr"))
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "sky.hdr"))
        try database.setSettings(TextureImporter.Settings(compression: .auto), for: id)
        #expect(database.texture(AssetReference(id, subAsset: "texture"))?.format == .rgba16Float)
        #expect(database.reimport(id).warnings.contains { $0.contains("HDR textures aren't compressed") })
    }

    // MARK: GPU

    /// Each backend samples compressed levels exactly as the CPU decoder decodes them (to within
    /// rounding: GPUs decode linear ASTC at 16-bit precision), takes block-aligned updates, and
    /// falls back to RGBA8 for formats it lacks.
    @MainActor @Test func uploadsSampleLikeTheCPUDecoderOnEveryBackend() throws {
        let image = testImage(width: 16, height: 12)
        let shader = try ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders")
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader)
            for format in TextureFormat.compressedFormats {
                let label = "\(device.backend) \(format)"
                let levels = try TextureCodec.encode(image, format: format)
                let texture = try device.makeTexture(compressedLevels: levels, format: format)
                guard device.supports(format) else {
                    #expect(texture.format == format.decompressedFormat, "\(label)")
                    #expect(throws: GraphicsError.self) { try device.makeTexture(levels: levels, format: format) }
                    continue
                }
                #expect(texture.format == format && texture.mipLevelCount == levels.count, "\(label)")

                // Rewrite the 4x4 block at (8, 4) with the matching block of another encoding.
                let other = try TextureCodec.encode(testImage(width: 16, height: 12, seed: 5).withRedSwappedForBlue(),
                                                    format: format, mipmaps: false)[0]
                let blockIndex = 1 * 4 + 2
                try device.updateTexture(texture, region: TextureRegion(x: 8, y: 4, width: 4, height: 4),
                                         pixels: Array(other.pixels[blockIndex * 16..<blockIndex * 16 + 16]))
                #expect(throws: GraphicsError.self) {
                    try device.updateTexture(texture, region: TextureRegion(x: 2, y: 4, width: 4, height: 4),
                                             pixels: [UInt8](repeating: 0, count: 16))
                }
                var expectedBlocks = levels[0].pixels
                expectedBlocks.replaceSubrange(blockIndex * 16..<blockIndex * 16 + 16, with: other.pixels[blockIndex * 16..<blockIndex * 16 + 16])
                let expected = try TextureCodec.decode(TextureMipLevel(width: 16, height: 12, pixels: expectedBlocks), format: format)

                let results = try device.makeBuffer(length: 16 * 12 * 16, usage: .storage)
                var values: [Float] = []
                try frames.run { frame in
                    frame.computePass(label: "copy") { pass in
                        pass.setPipeline(pipeline)
                        pass.setTexture(texture, index: 1)
                        pass.setStorageBuffer(results, index: 0)
                        pass.setPushConstants(SIMD2<UInt32>(16, 12))
                        pass.dispatch(threads: ComputeSize(16, 12), of: pipeline)
                    }
                    frame.readBack(results) { bytes in values = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
                }
                #expect(values.count == 16 * 12 * 4, "\(label)")
                guard values.count == 16 * 12 * 4 else { continue }
                var worst: Float = 0
                for (i, byte) in expected.pixels.enumerated() {
                    let want = format.isSRGB && i % 4 != 3 ? srgbToLinear(byte) : Float(byte) / 255
                    // sRGB values are compared in 8-bit sRGB steps around the expected one.
                    let tolerance = format.isSRGB && i % 4 != 3 ? abs(srgbToLinear(UInt8(min(Int(byte) + 1, 255))) - want) + 1e-4 : 1.5 / 255
                    worst = max(worst, abs(values[i] - want) / tolerance)
                }
                #expect(worst <= 1, "\(label): off by \(worst) tolerances")
            }
        }
    }
}

private extension Image {
    func withRedSwappedForBlue() -> Image {
        var copy = self
        for i in stride(from: 0, to: pixels.count, by: 4) { copy.pixels.swapAt(i, i + 2) }
        return copy
    }
}
