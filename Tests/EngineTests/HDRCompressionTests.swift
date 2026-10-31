import Foundation
import Testing
@testable import Engine

// BC6H / ASTC 4x4 HDR: the formats, encoders and decoders, the texture importer's HDR path,
// uploads on every backend (or the RGBA16F fallback), and image-based lighting precomputed from
// a compressed environment map.

/// A small studio environment like the `sky` scene's: a dim room (0.01 ... 0.2) with a bright
/// warm softbox (16), a cool fill, an overhead strip and a thin rim light, edges softened over a
/// texel or two. Linear radiance, alpha 1.
private func studio(width: Int, height: Int) -> FloatImage {
    let boxes: [(center: Vec2, size: Vec2, radiance: Vec3)] = [
        (Vec2(0.4, 0.3), Vec2(0.07, 0.12), Vec3(16, 14.5, 12.5)),
        (Vec2(0.78, 0.38), Vec2(0.12, 0.08), Vec3(2.4, 2.9, 3.6)),
        (Vec2(0.5, 0.06), Vec2(0.5, 0.02), Vec3(3, 3, 3)),
        (Vec2(0.02, 0.42), Vec2(0.012, 0.2), Vec3(9, 8.5, 8)),
    ]
    let soft = 1.5 / Float(height)
    func edge(_ distance: Float) -> Float { min(max(0.5 - distance / soft, 0), 1) }
    var pixels = [Float](repeating: 1, count: width * height * 4)
    for y in 0..<height {
        let v = (Float(y) + 0.5) / Float(height)
        let up = max(0.5 - v, 0) * 2
        var base = Vec3(0.09, 0.1, 0.12) * (1 - up) + Vec3(0.05, 0.055, 0.07) * up
        base += Vec3(0.12, 0.08, 0.05) * expf(-powf((v - 0.5) / 0.035, 2))
        if v > 0.5 { base = base * 0.3 + Vec3(0.035, 0.03, 0.028) * min((v - 0.5) * 20, 1) }
        for x in 0..<width {
            let u = (Float(x) + 0.5) / Float(width)
            var color = base
            for box in boxes {
                var du = abs(u - box.center.x)
                du = min(du, 1 - du)
                let inside = edge(du - box.size.x / 2) * edge(abs(v - box.center.y) - box.size.y / 2)
                color = color + (box.radiance - color) * inside
            }
            let i = (y * width + x) * 4
            pixels[i] = color.x
            pixels[i + 1] = color.y
            pixels[i + 2] = color.z
        }
    }
    return FloatImage(width: width, height: height, pixels: pixels)
}

/// Errors in log2(1 + x) over the RGB channels (stops on bright texels, absolute error on dark
/// ones): their RMSE and the largest, and the mean relative error of luminance.
private func compare(_ a: FloatImage, _ b: FloatImage) -> (logRMSE: Double, maxLog: Double, meanRelative: Double) {
    precondition(a.pixels.count == b.pixels.count)
    var squared = 0.0, worst = 0.0, relative = 0.0
    for texel in 0..<a.width * a.height {
        let i = texel * 4
        var la = 0.0, lb = 0.0
        for c in 0..<3 {
            let d = log2(1 + Double(max(a.pixels[i + c], 0))) - log2(1 + Double(max(b.pixels[i + c], 0)))
            squared += d * d
            worst = max(worst, abs(d))
            let w = [0.2126, 0.7152, 0.0722][c]
            la += w * Double(a.pixels[i + c])
            lb += w * Double(b.pixels[i + c])
        }
        relative += abs(la - lb) / max(la, 1e-3)
    }
    let texels = Double(a.width * a.height)
    return ((squared / (texels * 3)).squareRoot(), worst, relative / texels)
}

/// Rounds every value to half precision, as an `.rgba16Float` texture stores it.
private func asHalf(_ image: FloatImage) -> FloatImage {
    FloatImage(width: image.width, height: image.height, pixels: image.pixels.map { Half.value(Half.bits($0)) })
}

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("HDRCompressionTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "HDRCompression")
}

/// A Radiance file (uncompressed scanlines) of `image`.
private func radianceFile(_ image: FloatImage) -> Data {
    var data = Data("#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y \(image.height) +X \(image.width)\n".utf8)
    for texel in 0..<image.width * image.height {
        let rgb = (0..<3).map { image.pixels[texel * 4 + $0] }
        let largest = rgb.max()!
        guard largest > 1e-32 else {
            data.append(contentsOf: [0, 0, 0, 0])
            continue
        }
        let exponent = frexp(Double(largest)).1  // largest = m * 2^exponent, m in [0.5, 1)
        let scale = 256 / pow(2, Double(exponent))
        data.append(contentsOf: rgb.map { UInt8(min(Double($0) * scale, 255)) } + [UInt8(exponent + 128)])
    }
    return data
}

@Suite struct HDRCompressionTests {
    // MARK: Formats

    @Test func formatsAndSettings() {
        for format in TextureFormat.hdrCompressedFormats {
            #expect(format.isHDR && format.isCompressed && !format.isSRGB && !format.isTwoChannel)
            #expect(format.blockSize == 4 && format.bytesPerBlock == 16)
            #expect(format.decompressedFormat == .rgba16Float)
            // A quarter of RGBA16F (8 bytes per texel) without mips.
            #expect(format.byteCount(width: 2048, height: 1024) * 8 == TextureFormat.rgba16Float.byteCount(width: 2048, height: 1024))
            #expect(!TextureFormat.compressedFormats.contains(format))
        }
        #expect(!TextureFormat.compressedFormats.contains { $0.isHDR })
        #expect(TextureCompression.none.hdrFormat == nil)
        #expect(TextureCompression.bc7.hdrFormat == .bc6hUfloat && TextureCompression.bc5.hdrFormat == .bc6hUfloat)
        #expect(TextureCompression.astc.hdrFormat == .astc4x4HDR && TextureCompression.astcRG.hdrFormat == .astc4x4HDR)
        #expect(TextureCompression.auto.hdrFormat == TextureCodec.autoHDRFormat)
        #if canImport(Darwin) && arch(arm64)
        #expect(TextureCodec.autoHDRFormat == .astc4x4HDR)
        #else
        #expect(TextureCodec.autoHDRFormat == .bc6hUfloat)
        #endif
    }

    // MARK: Encoders and decoders

    @Test(arguments: TextureFormat.hdrCompressedFormats)
    func roundTripStaysCloseInLogSpace(format: TextureFormat) throws {
        let image = studio(width: 128, height: 64)
        let levels = try TextureCodec.encode(image, format: format)
        #expect(levels.map(\.width) == [128, 64, 32, 16, 8, 4, 2, 1])
        #expect(levels.allSatisfy { $0.pixels.count == format.byteCount(width: $0.width, height: $0.height) })
        let decoded = try TextureCodec.decodeFloat(levels[0], format: format)
        let error = compare(image, decoded)
        #expect(error.logRMSE < 0.02, "\(format): log RMSE \(error.logRMSE)")
        #expect(error.meanRelative < 0.03, "\(format): mean relative error \(error.meanRelative)")
        // Opaque, and no texel lost or blown up (texels mixing the 16x softbox with the dim room
        // are the hardest).
        #expect(stride(from: 3, to: decoded.pixels.count, by: 4).allSatisfy { decoded.pixels[$0] == 1 })
        #expect(error.maxLog < 0.5, "\(format): worst texel off by \(error.maxLog) in log2(1 + x)")
        // decode(levels:) gives the RGBA16F bytes of the same values, a level at a time.
        let half = try TextureCodec.decode(levels: levels, format: format)
        #expect(half.map(\.pixels.count) == levels.map { $0.width * $0.height * 8 })
        #expect(half[0].pixels == Half.encode(decoded.pixels))
        // Lower levels decode close to the float mip chain they were made from.
        let mips = MipChain.generateFloat(pixels: image.pixels, width: 128, height: 64)
        let mip2 = try TextureCodec.decodeFloat(levels[2], format: format)
        let reference = mips[2].pixels.withUnsafeBytes { Array($0.bindMemory(to: UInt16.self)) }.map(Half.value)
        #expect(compare(FloatImage(width: 32, height: 16, pixels: reference), mip2).logRMSE < 0.03, "\(format) level 2")
        // Deterministic, however the work was split between threads.
        #expect(try TextureCodec.encode(image, format: format).map(\.pixels) == levels.map(\.pixels))
    }

    @Test(arguments: TextureFormat.hdrCompressedFormats)
    func oddSizesNegativeAndOutOfRangeValues(format: TextureFormat) throws {
        // 13x7: partial edge blocks. Values: negative (clamped to 0 by BC6H), tiny, and very
        // large (60000 is near half's largest finite value), plus infinity (largest finite).
        var pixels = [Float](repeating: 1, count: 13 * 7 * 4)
        for texel in 0..<13 * 7 {
            let x = texel % 13, y = texel / 13
            pixels[texel * 4] = powf(2, Float(x) - 6)  // 1/64 ... 64
            pixels[texel * 4 + 1] = Float(y) * 0.1
            pixels[texel * 4 + 2] = 0.5
        }
        pixels[0] = -3
        pixels[4] = 60000
        pixels[8] = .infinity
        let image = FloatImage(width: 13, height: 7, pixels: pixels)
        let level = try #require(try TextureCodec.encode(image, format: format, mipmaps: false).first)
        #expect(level.pixels.count == 4 * 2 * 16)
        let decoded = try TextureCodec.decodeFloat(level, format: format)
        #expect(decoded.width == 13 && decoded.height == 7)
        #expect(decoded.pixels.allSatisfy { $0.isFinite && $0 >= 0 }, "\(format)")
        #expect(decoded.pixels[4] > 20000 && decoded.pixels[8] > 20000, "\(format): \(decoded.pixels[4]), \(decoded.pixels[8])")
        // Away from the extreme first block, the ramps survive.
        var clean = image, cleaned = decoded
        for texel in 0..<13 * 7 where texel % 13 < 4 && texel / 13 < 4 {
            for c in 0..<4 {
                clean.pixels[texel * 4 + c] = 0
                cleaned.pixels[texel * 4 + c] = 0
            }
        }
        let rampError = compare(clean, cleaned)
        #expect(rampError.logRMSE < 0.1, "\(format): \(rampError)")  // red doubles from texel to texel
    }

    @Test func badInputIsRejected() {
        #expect(throws: GraphicsError.self) { try TextureCodec.encode(studio(width: 8, height: 4), format: .bc7Unorm) }
        #expect(throws: GraphicsError.self) {
            // RGBA8-sized level for an HDR format.
            try TextureCodec.encode(levels: [TextureMipLevel(width: 4, height: 4, pixels: [UInt8](repeating: 0, count: 64))],
                                    format: .bc6hUfloat)
        }
        #expect(throws: GraphicsError.self) {
            try TextureCodec.decode(TextureMipLevel(width: 4, height: 4, pixels: [UInt8](repeating: 0, count: 16)), format: .bc6hUfloat)
        }
        #expect(throws: GraphicsError.self) {
            try TextureCodec.decodeFloat(TextureMipLevel(width: 4, height: 4, pixels: [UInt8](repeating: 0, count: 16)), format: .bc7Unorm)
        }
        #expect(throws: GraphicsError.self) {
            try TextureCodec.decodeFloat(TextureMipLevel(width: 8, height: 8, pixels: [UInt8](repeating: 0, count: 16)), format: .astc4x4HDR)
        }
    }

    /// The numbers for the README: an equirectangular studio map at a typical size, every
    /// level, at each quality, one encode at a time (printed; the asserts only bound quality).
    /// Times are the codecs' alone (they are always optimized).
    /// About a minute, so only with HDR_COMPRESSION_BENCHMARK=1.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["HDR_COMPRESSION_BENCHMARK"] == "1"))
    func environmentMapSizeTimeAndError() throws {
        let image = studio(width: 2048, height: 1024)
        let reference = asHalf(image)
        // The float mip chain is built first: in a debug build its Swift loops would dominate.
        let mips = MipChain.generateFloat(pixels: image.pixels, width: 2048, height: 1024)
        let halfBytes = mips.reduce(0) { $0 + $1.pixels.count }
        for format in TextureFormat.hdrCompressedFormats {
        for quality in TextureCompressionQuality.allCases {
            let start = DispatchTime.now().uptimeNanoseconds
            let levels = try TextureCodec.encode(levels: mips, format: format, quality: quality)
            let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e9
            let bytes = levels.reduce(0) { $0 + $1.pixels.count }
            let error = compare(reference, try TextureCodec.decodeFloat(levels[0], format: format))
            print("HDR \(format) \(quality) 2048x1024 + mips: " + String(format: "%.2f s, %.1f MB (RGBA16F %.1f MB), ", seconds,
                  Double(bytes) / 1e6, Double(halfBytes) / 1e6)
                  + String(format: "log2(1+x) RMSE %.4f (worst %.3f), mean relative luminance error %.3f%%", error.logRMSE,
                           error.maxLog, error.meanRelative * 100))
            // An eighth (but for the smallest levels, which take a whole block).
            #expect(bytes * 8 >= halfBytes && bytes * 8 < halfBytes + 1024)
            #expect(error.logRMSE < 0.02 && error.meanRelative < 0.03, "\(format) \(quality)")
        }
        }
    }

    // MARK: Importer

    @MainActor @Test func importerCompressesHDRImagesAndCachesThem() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let image = studio(width: 64, height: 32)
        try radianceFile(image).write(to: project.assetsURL.appendingPathComponent("studio.hdr"))
        let database = AssetDatabase(project: project)
        database.refresh()
        let id = try #require(database.id(forPath: "studio.hdr"))
        let reference = AssetReference(id, subAsset: "texture")
        let plain = try #require(database.texture(reference))
        #expect(plain.format == .rgba16Float && plain.isHDR)
        let source = try #require(plain.floatImage)

        for (compression, format) in [(TextureCompression.auto, TextureCodec.autoHDRFormat), (.bc7, .bc6hUfloat), (.astc, .astc4x4HDR)] {
            try database.setSettings(TextureImporter.Settings(compression: compression), for: id)
            #expect(!database.reimport(id).warnings.contains { $0.contains("HDR") })
            let texture = try #require(database.texture(reference))
            #expect(texture.format == format && texture.isHDR && !texture.isSRGB, "\(compression)")
            #expect(texture.compressedLevels?.count == MipChain.levelCount(width: 64, height: 32))
            #expect(texture.gpuByteCount == texture.compressedLevels!.reduce(0) { $0 + $1.pixels.count })
            // floatImage decodes level 0 (what CPU-side precomputation would read).
            let decoded = try #require(texture.floatImage)
            #expect(compare(source, decoded).logRMSE < 0.03, "\(compression)")
            #expect(texture.image.width == 64)
            #expect(FileManager.default.fileExists(atPath: database.artifactsURL(id).appendingPathComponent("cache/\(format.rawValue).bin").path))
            // The Library cache keeps the blocks bit for bit.
            let reopened = AssetDatabase(project: project)
            reopened.scan()
            #expect(reopened.texture(reference)?.compressedLevels?.map(\.pixels) == texture.compressedLevels?.map(\.pixels))
        }
        // No mipmaps: one level.
        try database.setSettings(TextureImporter.Settings(mipmaps: false, compression: .bc7), for: id)
        #expect(database.texture(reference)?.compressedLevels?.count == 1)
        // Off again: float pixels.
        try database.setSettings(TextureImporter.Settings(compression: .none), for: id)
        #expect(database.texture(reference)?.format == .rgba16Float)
    }

    // MARK: GPU

    /// Each backend samples HDR blocks as the CPU decoder decodes them (both are exact: the
    /// formats decode to half floats), or falls back to RGBA16F when it lacks the format.
    @MainActor @Test func uploadsSampleLikeTheCPUDecoderOnEveryBackend() throws {
        let image = studio(width: 16, height: 12)
        let shader = try ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders")
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader)
            for format in TextureFormat.hdrCompressedFormats {
                let label = "\(device.backend) \(format)"
                let levels = try TextureCodec.encode(image, format: format)
                let texture = try device.makeTexture(compressedLevels: levels, format: format)
                print("HDRCompressionTests: \(label) \(device.supports(format) ? "sampled natively" : "decoded to rgba16Float")")
                if device.supports(format) {
                    #expect(texture.format == format && texture.mipLevelCount == levels.count, "\(label)")
                } else {
                    #expect(texture.format == .rgba16Float && texture.mipLevelCount == levels.count, "\(label)")
                    #expect(throws: GraphicsError.self) { try device.makeTexture(levels: levels, format: format) }
                }
                let expected = try TextureCodec.decodeFloat(levels[0], format: format)
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
                #expect(values == expected.pixels, "\(label)")
            }
        }
    }

    /// Image-based lighting precomputed from a compressed map (the GPU passes sample it like any
    /// texture) stays close to the one from the RGBA16F map: the prefiltered levels in log
    /// space, and the SH9 irradiance coefficients.
    @MainActor @Test func imageBasedLightingFromACompressedMap() throws {
        let image = studio(width: 512, height: 256)
        let shader = try ShaderSource.load(compute: "test_copy", bundle: .module, subdirectory: "Resources/Shaders")
        try TestDevices.forEachBackend { device, frames in
            let pipeline = try device.makeComputePipeline(shader: shader)
            let white = try device.makeTexture(pixels: [255, 255, 255, 255], width: 1, height: 1, format: .rgba8Unorm)
            @MainActor func atlas(of map: GPUTexture) throws -> FloatImage {
                let lighting = try EnvironmentLighting(device: device, placeholder: white)
                lighting.prepare(SceneEnvironment(sky: .map), map: map, toLight: Vec3(0, 1, 0), lightColor: Vec3(1, 1, 1))
                let (w, h) = (EnvironmentAtlas.width, EnvironmentAtlas.height)
                let results = try device.makeBuffer(length: w * h * 16, usage: .storage)
                var values: [Float] = []
                try frames.run { frame in
                    lighting.render()
                    frame.computePass(label: "copy") { pass in
                        pass.setPipeline(pipeline)
                        pass.setTexture(lighting.atlasTexture!, index: 1)
                        pass.setStorageBuffer(results, index: 0)
                        pass.setPushConstants(SIMD2<UInt32>(UInt32(w), UInt32(h)))
                        pass.dispatch(threads: ComputeSize(w, h), of: pipeline)
                    }
                    frame.readBack(results) { bytes in values = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) } }
                }
                return FloatImage(width: w, height: h, pixels: values)
            }
            func region(_ image: FloatImage, _ r: (x: Int, y: Int, width: Int, height: Int)) -> FloatImage {
                var pixels: [Float] = []
                for y in r.y..<r.y + r.height {
                    pixels += image.pixels[((y * image.width + r.x) * 4)..<((y * image.width + r.x + r.width) * 4)]
                }
                return FloatImage(width: r.width, height: r.height, pixels: pixels)
            }
            let reference = try atlas(of: device.makeTexture(image: image))
            for format in TextureFormat.hdrCompressedFormats {
                let label = "\(device.backend) \(format)"
                let compressed = try atlas(of: device.makeTexture(compressedLevels: TextureCodec.encode(image, format: format), format: format))
                var report: [String] = []
                for (level, rect) in EnvironmentAtlas.levels.enumerated() {
                    let error = compare(region(reference, rect), region(compressed, rect))
                    report.append(String(format: "level %d %.4f", level, error.logRMSE))
                    #expect(error.logRMSE < 0.02, "\(label) level \(level): log RMSE \(error.logRMSE)")
                }
                let sh = region(reference, (EnvironmentAtlas.sh.x, EnvironmentAtlas.sh.y, 9, 1))
                let shCompressed = region(compressed, (EnvironmentAtlas.sh.x, EnvironmentAtlas.sh.y, 9, 1))
                // Error of each coefficient relative to the DC term (the average irradiance).
                let dc = Double(max(sh.pixels[0], sh.pixels[1], sh.pixels[2]))
                let worst = zip(sh.pixels, shCompressed.pixels).enumerated().filter { $0.offset % 4 != 3 }
                    .map { abs(Double($0.element.0 - $0.element.1)) / dc }.max() ?? 0
                print("HDRCompressionTests: IBL from \(label): log2 RMSE " + report.joined(separator: ", ")
                      + String(format: "; SH9 worst coefficient off by %.3f%% of DC", worst * 100))
                #expect(worst < 0.01, "\(label): SH coefficient off by \(worst) of DC")
            }
        }
    }
}
