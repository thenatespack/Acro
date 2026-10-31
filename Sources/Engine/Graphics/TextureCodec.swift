import CTextureCodec
import Foundation

/// The block compression the texture importer applies (`TextureImporter.Settings.compression`).
/// HDR images (`.hdr`) get the HDR format of the same family (`hdrFormat`): BC6H for `bc7` and
/// `bc5`, ASTC 4x4 HDR for `astc` and `astcRG`, and under `auto` the one this machine prefers.
public enum TextureCompression: String, Codable, Sendable, CaseIterable {
    /// RGBA8 (RGBA16F for HDR images) as decoded.
    case none
    /// The format this machine's GPUs prefer (`TextureCodec.autoFormat`): ASTC 4x4 on Apple
    /// silicon, BC7 elsewhere (HDR: ASTC 4x4 HDR, BC6H).
    case auto
    /// BC7 (`.bc7Srgb` / `.bc7Unorm`); BC6H (`.bc6hUfloat`) for HDR images.
    case bc7
    /// ASTC 4x4 (`.astc4x4Srgb` / `.astc4x4Unorm`); ASTC 4x4 HDR (`.astc4x4HDR`) for HDR images.
    case astc
    /// BC5 (`.bc5Unorm`, two channels) for normal maps, BC7 for everything else.
    case bc5
    /// Two-channel ASTC 4x4 (`.astc4x4RG`) for normal maps, ASTC 4x4 for everything else.
    case astcRG

    /// The compressed format for 8-bit pixels that are sRGB color or linear data; nil for `none`.
    /// Normal maps (`normalMap`) get a two-channel format under `auto`, `bc5` and `astcRG` (the
    /// mesh shader rebuilds Z), an RGB one under `bc7` and `astc`.
    public func format(srgb: Bool, normalMap: Bool = false) -> TextureFormat? {
        switch self {
        case .none: nil
        case .auto: normalMap ? TextureCodec.autoNormalMapFormat : TextureCodec.autoFormat(srgb: srgb)
        case .bc7: srgb ? .bc7Srgb : .bc7Unorm
        case .astc: srgb ? .astc4x4Srgb : .astc4x4Unorm
        case .bc5: normalMap ? .bc5Unorm : srgb ? .bc7Srgb : .bc7Unorm
        case .astcRG: normalMap ? .astc4x4RG : srgb ? .astc4x4Srgb : .astc4x4Unorm
        }
    }

    /// The compressed format for HDR (float) pixels; nil for `none`.
    public var hdrFormat: TextureFormat? {
        switch self {
        case .none: nil
        case .auto: TextureCodec.autoHDRFormat
        case .bc7, .bc5: .bc6hUfloat
        case .astc, .astcRG: .astc4x4HDR
        }
    }
}

/// How hard the encoders search (`TextureImporter.Settings.compressionQuality`). On an M5 (10
/// cores) the 12 levels of a 2048x2048 texture encode in about 0.2 / 0.4 / 0.9 s as BC7 and
/// 0.1 / 0.8 / 1.7 s as ASTC 4x4 (fast / normal / high), in debug builds too (the codecs are
/// always optimized). HDR: the 12 levels of a 2048x1024 environment map take 0.2 / 0.3 / 0.8 s
/// as ASTC 4x4 HDR and 1.6 / 8.5 / 17 s as BC6H (its kernels are vectorized with SSE2 on x86
/// only; on arm64 they run one block at a time).
public enum TextureCompressionQuality: String, Codable, Sendable, CaseIterable {
    case fast, normal, high

    var level: tc_quality {
        switch self {
        case .fast: 0
        case .normal: 1
        case .high: 2
        }
    }
}

/// CPU block compression with the vendored encoders (Sources/CTextureCodec): BC7 with bc7enc,
/// ASTC 4x4 (LDR and HDR) with Arm's astc-encoder, BC6H with Convection Texture Tools' kernels,
/// BC5 with the engine's own, and their decoders (for GPUs that lack a format, thumbnails and
/// tests). Thread-safe; encoding spreads each level over all cores.
///
/// sRGB formats are encoded with perceptual error weights; linear ones (normal maps, masks,
/// roughness) weight all four channels alike, so a normal's components keep equal precision.
public enum TextureCodec {
    /// What `TextureCompression.auto` picks: ASTC 4x4 on Apple GPUs (arm64 Apple platforms),
    /// BC7 elsewhere. A property of the machine rather than of a device, so a project's Library
    /// cache is the same for every backend; a GPU without the format still gets the texture
    /// (`RenderDevice.makeTexture(compressedLevels:format:)` decodes it).
    public static func autoFormat(srgb: Bool) -> TextureFormat {
        #if canImport(Darwin) && arch(arm64)
        srgb ? .astc4x4Srgb : .astc4x4Unorm
        #else
        srgb ? .bc7Srgb : .bc7Unorm
        #endif
    }

    /// What `TextureCompression.auto` picks for normal maps: two-channel ASTC 4x4 on Apple GPUs,
    /// BC5 elsewhere.
    public static var autoNormalMapFormat: TextureFormat {
        #if canImport(Darwin) && arch(arm64)
        .astc4x4RG
        #else
        .bc5Unorm
        #endif
    }

    /// What `TextureCompression.auto` picks for HDR images: ASTC 4x4 HDR on Apple GPUs (arm64
    /// Apple platforms; every Apple silicon Mac samples it), BC6H elsewhere.
    public static var autoHDRFormat: TextureFormat {
        #if canImport(Darwin) && arch(arm64)
        .astc4x4HDR
        #else
        .bc6hUfloat
        #endif
    }

    /// Bumped when the encoders' output changes, so cached encodings are redone.
    static let version = 1

    /// Encodes an RGBA8 image, with a full mip chain (built like `RenderDevice.makeTexture(image:)`
    /// builds it: box filter, in linear light for sRGB) when `mipmaps` is set.
    public static func encode(_ image: Image, format: TextureFormat, mipmaps: Bool = true,
                              quality: TextureCompressionQuality = .normal) throws -> [TextureMipLevel] {
        let levels = mipmaps
            ? MipChain.generate(pixels: image.pixels, width: image.width, height: image.height, srgb: format.isSRGB)
            : [TextureMipLevel(width: image.width, height: image.height, pixels: image.pixels)]
        return try encode(levels: levels, format: format, quality: quality)
    }

    /// Encodes a linear HDR image into `format` (one of `TextureFormat.hdrCompressedFormats`),
    /// with a full mip chain (box-filtered in float, as `RenderDevice.makeTexture(image:)` builds
    /// it for `.rgba16Float`) when `mipmaps` is set. Alpha is dropped (BC6H) or kept as LDR (ASTC).
    public static func encode(_ image: FloatImage, format: TextureFormat, mipmaps: Bool = true,
                              quality: TextureCompressionQuality = .normal) throws -> [TextureMipLevel] {
        guard format.isHDR else { throw GraphicsError("\(format) isn't an HDR compressed format") }
        let levels = MipChain.generateFloat(pixels: image.pixels, width: image.width, height: image.height, generateMipmaps: mipmaps)
        return try encode(levels: levels, format: format, quality: quality)
    }

    /// Encodes mip levels into `format`: RGBA8 levels for `TextureFormat.compressedFormats`,
    /// RGBA16F ones (little-endian half floats, `.rgba16Float`'s layout) for the HDR formats.
    public static func encode(levels: [TextureMipLevel], format: TextureFormat,
                              quality: TextureCompressionQuality = .normal) throws -> [TextureMipLevel] {
        guard format.isCompressed else { throw GraphicsError("\(format) isn't a compressed format") }
        let texel = format.decompressedFormat.bytesPerPixel
        for level in levels where level.width < 1 || level.height < 1 || level.pixels.count != level.width * level.height * texel {
            throw GraphicsError("A \(level.width)x\(level.height) level needs \(max(level.width * level.height * texel, 0)) "
                                + "\(format.decompressedFormat) bytes")
        }
        switch format {
        case .bc7Unorm, .bc7Srgb, .bc5Unorm, .bc6hUfloat:
            return levels.map { encodeBlockRows($0, format: format, quality: quality) }
        default:
            return try encodeASTC(levels, format: format, quality: quality)
        }
    }

    /// Decodes one compressed level to RGBA8 (sRGB data stays sRGB-encoded). HDR formats decode
    /// with `decodeFloat`.
    public static func decode(_ level: TextureMipLevel, format: TextureFormat) throws -> Image {
        guard format.isCompressed, !format.isHDR else {
            throw GraphicsError("\(format) isn't an 8-bit compressed format\(format.isHDR ? "; use decodeFloat" : "")")
        }
        guard level.pixels.count == format.byteCount(width: level.width, height: level.height) else {
            throw GraphicsError("A \(level.width)x\(level.height) \(format) level needs \(format.byteCount(width: level.width, height: level.height)) bytes")
        }
        var pixels = [UInt8](repeating: 0, count: level.width * level.height * 4)
        let ok = level.pixels.withUnsafeBufferPointer { blocks in
            pixels.withUnsafeMutableBufferPointer { out in
                switch format {
                case .bc7Unorm, .bc7Srgb:
                    tc_bc7_decode(blocks.baseAddress, Int32(level.width), Int32(level.height), out.baseAddress) != 0
                case .bc5Unorm:
                    { tc_bc5_decode(blocks.baseAddress, Int32(level.width), Int32(level.height), out.baseAddress); return true }()
                default:
                    tc_astc_decode(blocks.baseAddress, Int32(level.width), Int32(level.height), format.isSRGB ? 1 : 0,
                                   out.baseAddress) != 0
                }
            }
        }
        guard ok else { throw GraphicsError("Invalid \(format) data") }
        return Image(width: level.width, height: level.height, pixels: pixels)
    }

    /// Decodes one level of an HDR format (`TextureFormat.hdrCompressedFormats`) to linear float
    /// RGBA, as the GPU samples it (alpha 1 for BC6H).
    public static func decodeFloat(_ level: TextureMipLevel, format: TextureFormat) throws -> FloatImage {
        let half = try decodeHalf(level, format: format)
        return FloatImage(width: level.width, height: level.height, pixels: half.map { Half.value($0) })
    }

    /// Decodes every level to `format.decompressedFormat`: RGBA8, or RGBA16F bytes for the HDR formats.
    public static func decode(levels: [TextureMipLevel], format: TextureFormat) throws -> [TextureMipLevel] {
        try levels.map { level in
            if format.isHDR {
                let half = try decodeHalf(level, format: format)
                return TextureMipLevel(width: level.width, height: level.height, pixels: half.withUnsafeBytes { Array($0) })
            }
            let image = try decode(level, format: format)
            return TextureMipLevel(width: image.width, height: image.height, pixels: image.pixels)
        }
    }

    /// An HDR level as half-float bits, RGBA.
    private static func decodeHalf(_ level: TextureMipLevel, format: TextureFormat) throws -> [UInt16] {
        guard format.isHDR else { throw GraphicsError("\(format) isn't an HDR compressed format") }
        guard level.pixels.count == format.byteCount(width: level.width, height: level.height) else {
            throw GraphicsError("A \(level.width)x\(level.height) \(format) level needs \(format.byteCount(width: level.width, height: level.height)) bytes")
        }
        var half = [UInt16](repeating: 0, count: level.width * level.height * 4)
        let ok = level.pixels.withUnsafeBufferPointer { blocks in
            half.withUnsafeMutableBufferPointer { out in
                if format == .bc6hUfloat {
                    tc_bc6h_decode(blocks.baseAddress, Int32(level.width), Int32(level.height), out.baseAddress)
                    return true
                }
                return tc_astc_decode_hdr(blocks.baseAddress, Int32(level.width), Int32(level.height), out.baseAddress) != 0
            }
        }
        guard ok else { throw GraphicsError("Invalid \(format) data") }
        return half
    }

    // MARK: - Normal maps

    /// A tangent-space normal map (RGB = XYZ * 0.5 + 0.5) with every texel's vector rescaled to
    /// unit length, so X and Y alone determine it. Done before two-channel encoding, since the
    /// shader rebuilds Z as sqrt(1 - x² - y²). Alpha is kept; zero vectors become (0, 0, 1).
    public static func normalized(normalMap image: Image) -> Image {
        var pixels = image.pixels
        for i in stride(from: 0, to: pixels.count, by: 4) {
            var n = Vec3(Float(pixels[i]), Float(pixels[i + 1]), Float(pixels[i + 2])) * (2 / 255) - Vec3(1, 1, 1)
            let size = length(n)
            n = size > 1e-6 ? n / size : Vec3(0, 0, 1)
            for c in 0..<3 { pixels[i + c] = UInt8(((n[c] * 0.5 + 0.5) * 255).rounded()) }
        }
        return Image(width: image.width, height: image.height, pixels: pixels)
    }

    /// The unit normal a texel of a texture in `format`, decoded to RGBA8 (`decode`), stands
    /// for, as the mesh shader reads it: XYZ from RGB, or for the two-channel formats X and Y
    /// from red and green (BC5) or red and alpha (two-channel ASTC) with Z = sqrt(1 - x² - y²).
    public static func normal(_ pixels: [UInt8], at texel: Int, format: TextureFormat) -> Vec3 {
        let i = texel * 4
        func channel(_ c: Int) -> Float { Float(pixels[i + c]) / 255 * 2 - 1 }
        guard format.isTwoChannel else {
            let n = Vec3(channel(0), channel(1), channel(2))
            return length(n) > 1e-6 ? normalize(n) : Vec3(0, 0, 1)
        }
        let x = channel(0), y = channel(format == .astc4x4RG ? 3 : 1)
        return Vec3(x, y, max(1 - x * x - y * y, 0).squareRoot())
    }

    /// An RGBA8 normal map (X, Y, rebuilt Z, alpha 1) from a decoded two-channel level: what a
    /// GPU without the format gets instead (`makeTexture(compressedLevels:format:)`).
    static func expandTwoChannel(_ image: Image, format: TextureFormat) -> Image {
        var pixels = image.pixels
        for texel in 0..<image.width * image.height {
            let n = normal(image.pixels, at: texel, format: format)
            for c in 0..<3 { pixels[texel * 4 + c] = UInt8(((n[c] * 0.5 + 0.5) * 255).rounded()) }
            pixels[texel * 4 + 3] = 255
        }
        return Image(width: image.width, height: image.height, pixels: pixels)
    }

    // MARK: - Encoders

    /// BC7, BC5 or BC6H: bands of block rows on every core.
    private static func encodeBlockRows(_ level: TextureMipLevel, format: TextureFormat, quality: TextureCompressionQuality) -> TextureMipLevel {
        var blocks = [UInt8](repeating: 0, count: format.byteCount(width: level.width, height: level.height))
        let rows = (level.height + 3) / 4
        // Bands of block rows, a few per core so uneven bands even out.
        let bands = min(rows, ProcessInfo.processInfo.activeProcessorCount * 4)
        let perceptual: Int32 = format.isSRGB ? 1 : 0
        level.pixels.withUnsafeBufferPointer { source in
            blocks.withUnsafeMutableBufferPointer { out in
                // Linux's Dispatch requires a @Sendable closure, so the pointers go in through a box.
                let p = LevelPointers(source: source.baseAddress!, out: out.baseAddress!, count: out.count, encoder: nil)
                DispatchQueue.concurrentPerform(iterations: bands) { band in
                    let first = rows * band / bands, last = rows * (band + 1) / bands
                    if format == .bc6hUfloat {
                        tc_bc6h_encode(UnsafeRawPointer(p.source).assumingMemoryBound(to: UInt16.self), Int32(level.width),
                                       Int32(level.height), Int32(first), Int32(last - first), quality.level, p.out)
                    } else if format == .bc5Unorm {
                        tc_bc5_encode(p.source, Int32(level.width), Int32(level.height), Int32(first), Int32(last - first),
                                      quality.level, p.out)
                    } else {
                        tc_bc7_encode(p.source, Int32(level.width), Int32(level.height), Int32(first), Int32(last - first),
                                      quality.level, perceptual, p.out)
                    }
                }
            }
        }
        return TextureMipLevel(width: level.width, height: level.height, pixels: blocks)
    }

    private static func encodeASTC(_ levels: [TextureMipLevel], format: TextureFormat,
                                   quality: TextureCompressionQuality) throws -> [TextureMipLevel] {
        let threads = ProcessInfo.processInfo.activeProcessorCount
        let made = format == .astc4x4RG ? tc_astc_encoder_create_rg(quality.level, Int32(threads))
            : format == .astc4x4HDR ? tc_astc_encoder_create_hdr(quality.level, Int32(threads))
            : tc_astc_encoder_create(format.isSRGB ? 1 : 0, quality.level, Int32(threads))
        guard let encoder = made else {
            throw GraphicsError("The ASTC encoder couldn't be set up")
        }
        defer { tc_astc_encoder_destroy(encoder) }
        return try levels.map { level in
            var blocks = [UInt8](repeating: 0, count: format.byteCount(width: level.width, height: level.height))
            let failures = Atomic(0)
            level.pixels.withUnsafeBufferPointer { source in
                blocks.withUnsafeMutableBufferPointer { out in
                    let p = LevelPointers(source: source.baseAddress!, out: out.baseAddress!, count: out.count, encoder: encoder)
                    let hdr = format == .astc4x4HDR
                    DispatchQueue.concurrentPerform(iterations: threads) { thread in
                        let ok = hdr
                            ? tc_astc_encode_hdr(p.encoder, UnsafeRawPointer(p.source).assumingMemoryBound(to: UInt16.self),
                                                 Int32(level.width), Int32(level.height), p.out, p.count, Int32(thread))
                            : tc_astc_encode(p.encoder, p.source, Int32(level.width), Int32(level.height), p.out, p.count,
                                             Int32(thread))
                        if ok == 0 { failures.add(1) }
                    }
                }
            }
            tc_astc_encoder_reset(encoder)
            guard failures.value == 0 else { throw GraphicsError("ASTC encoding of a \(level.width)x\(level.height) level failed") }
            return TextureMipLevel(width: level.width, height: level.height, pixels: blocks)
        }
    }
}

/// A level's input and output for the encoder threads (each writes only its own blocks).
private struct LevelPointers: @unchecked Sendable {
    let source: UnsafePointer<UInt8>
    let out: UnsafeMutablePointer<UInt8>
    let count: Int
    let encoder: OpaquePointer?
}

/// A counter the encoder threads can bump.
private final class Atomic: @unchecked Sendable {
    private let lock = NSLock()
    private var count: Int
    init(_ value: Int) { count = value }
    func add(_ n: Int) { lock.lock(); count += n; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}

/// Formats already reported as unsupported by `makeTexture(compressedLevels:format:)`.
@MainActor private var reportedTextureFallbacks: Set<String> = []

extension RenderDevice {
    /// A texture from compressed mip levels (`TextureCodec.encode`). When the GPU can't sample
    /// `format` (`supports(_:)`), the levels are decoded on the CPU and uploaded as
    /// `format.decompressedFormat` (RGBA8, or RGBA16F for the HDR formats) instead, logged once
    /// per format and backend. A two-channel
    /// normal map then becomes an RGBA8 one with Z rebuilt (x, y, z, 1), which the mesh shader
    /// reads like any other.
    public func makeTexture(compressedLevels levels: [TextureMipLevel], format: TextureFormat) throws -> GPUTexture {
        if !format.isCompressed || supports(format) { return try makeTexture(levels: levels, format: format) }
        if reportedTextureFallbacks.insert("\(backend) \(format)").inserted {
            EngineLog.info("\(deviceName) (\(backend)) can't sample \(format) textures; decoding them to \(format.decompressedFormat)",
                           category: .rendering)
        }
        var decoded = try TextureCodec.decode(levels: levels, format: format)
        if format.isTwoChannel {
            // The mesh shader reads an RGBA8 normal map's Z from blue: rebuild it here.
            decoded = decoded.map {
                let image = TextureCodec.expandTwoChannel(Image(width: $0.width, height: $0.height, pixels: $0.pixels), format: format)
                return TextureMipLevel(width: image.width, height: image.height, pixels: image.pixels)
            }
        }
        return try makeTexture(levels: decoded, format: format.decompressedFormat)
    }
}
