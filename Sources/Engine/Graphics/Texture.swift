import Foundation

/// Which shader stages see a binding. Vulkan binds every stage at once, so there it only
/// documents intent; Metal binds per stage.
public struct ShaderStage: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let vertex = ShaderStage(rawValue: 1)
    public static let fragment = ShaderStage(rawValue: 2)
    public static let all: ShaderStage = [.vertex, .fragment]
}

public enum SamplerFilter: Sendable {
    case nearest, linear
}

/// How a sampler picks between mip levels.
public enum SamplerMipFilter: Sendable {
    /// Always samples level 0, even if the texture has mips.
    case none
    /// Samples the nearest level.
    case nearest
    /// Blends the two nearest levels (trilinear when the min/mag filter is linear).
    case linear
}

public enum SamplerAddressMode: Sendable {
    case `repeat`, clampToEdge, mirrorRepeat
}

/// Sampler state. Identical descriptors share one sampler (see `RenderDevice.makeSampler`).
public struct SamplerDescriptor: Hashable, Sendable {
    public var minFilter: SamplerFilter
    public var magFilter: SamplerFilter
    public var mipFilter: SamplerMipFilter
    /// Applies to both U and V.
    public var addressMode: SamplerAddressMode

    public init(minFilter: SamplerFilter = .linear, magFilter: SamplerFilter = .linear,
                mipFilter: SamplerMipFilter = .none, addressMode: SamplerAddressMode = .clampToEdge) {
        self.minFilter = minFilter
        self.magFilter = magFilter
        self.mipFilter = mipFilter
        self.addressMode = addressMode
    }

    /// Both filters set to `filter`.
    public init(filter: SamplerFilter, mipFilter: SamplerMipFilter = .none, addressMode: SamplerAddressMode = .clampToEdge) {
        self.init(minFilter: filter, magFilter: filter, mipFilter: mipFilter, addressMode: addressMode)
    }
}

/// Sampler state shared by every pass. Samplers are cached by descriptor and live as long
/// as the device, so there is nothing to release.
@MainActor public protocol GPUSampler: AnyObject {
    var descriptor: SamplerDescriptor { get }
}

/// Hands out one sampler object per distinct descriptor.
@MainActor
final class SamplerCache<Sampler: AnyObject> {
    private var samplers: [SamplerDescriptor: Sampler] = [:]

    var count: Int { samplers.count }
    var all: [Sampler] { Array(samplers.values) }

    func sampler(for descriptor: SamplerDescriptor, make: (SamplerDescriptor) throws -> Sampler) rethrows -> Sampler {
        if let cached = samplers[descriptor] { return cached }
        let sampler = try make(descriptor)
        samplers[descriptor] = sampler
        return sampler
    }

    func removeAll() { samplers.removeAll() }
}

extension TextureFormat {
    /// Checks a texture's size and the byte count of its first level.
    func validateUpload(byteCount: Int, width: Int, height: Int, maxSize: Int) throws {
        guard isUploadable else { throw GraphicsError("Pixel data needs .rgba8Unorm, .rgba8Srgb or .rgba16Float, not \(self)") }
        guard width > 0, height > 0, width <= maxSize, height <= maxSize else {
            throw GraphicsError("Texture size \(width)x\(height) is outside 1...\(maxSize)")
        }
        guard byteCount == width * height * bytesPerPixel else {
            throw GraphicsError(
                "Expected \(width * height * bytesPerPixel) bytes of \(self) data for \(width)x\(height), got \(byteCount)")
        }
    }

    /// Checks the levels passed to `RenderDevice.makeTexture(levels:format:)`: a chain starting
    /// at level 0 that halves each time (down to at most 1x1), with tightly packed pixels.
    func validateLevels(_ levels: [TextureMipLevel], maxSize: Int) throws {
        guard let first = levels.first else { throw GraphicsError("A texture needs at least one mip level") }
        try validateUpload(byteCount: first.pixels.count, width: first.width, height: first.height, maxSize: maxSize)
        guard levels.count <= MipChain.levelCount(width: first.width, height: first.height) else {
            throw GraphicsError("\(levels.count) mip levels is more than a \(first.width)x\(first.height) texture has")
        }
        for (index, level) in levels.enumerated() {
            let expected = MipChain.size(width: first.width, height: first.height, level: index)
            guard level.width == expected.width, level.height == expected.height else {
                throw GraphicsError("Mip level \(index) is \(level.width)x\(level.height), expected \(expected.width)x\(expected.height)")
            }
            guard level.pixels.count == level.width * level.height * bytesPerPixel else {
                throw GraphicsError("Mip level \(index) has \(level.pixels.count) bytes, expected \(level.width * level.height * bytesPerPixel)")
            }
        }
    }

    /// Checks the arguments of `RenderDevice.updateTexture`.
    func validateUpdate(_ region: TextureRegion, mipLevel: Int, byteCount: Int,
                        width: Int, height: Int, mipLevelCount: Int) throws {
        guard isUploadable else { throw GraphicsError("\(self) textures can't be updated from the CPU") }
        guard mipLevel >= 0, mipLevel < mipLevelCount else {
            throw GraphicsError("Mip level \(mipLevel) is outside 0..<\(mipLevelCount)")
        }
        let level = MipChain.size(width: width, height: height, level: mipLevel)
        guard region.width > 0, region.height > 0, region.x >= 0, region.y >= 0,
              region.x + region.width <= level.width, region.y + region.height <= level.height
        else {
            throw GraphicsError("Region \(region.width)x\(region.height) at (\(region.x), \(region.y)) is outside the \(level.width)x\(level.height) mip level")
        }
        guard byteCount == region.width * region.height * bytesPerPixel else {
            throw GraphicsError("Expected \(region.width * region.height * bytesPerPixel) bytes for the region, got \(byteCount)")
        }
    }
}

/// A sub-rectangle of a texture mip level in texels, origin at the top left.
public struct TextureRegion: Sendable, Equatable {
    public var x, y, width, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// The pixels of one mip level, tightly packed, top row first, in the texture's format.
public struct TextureMipLevel: Sendable {
    public var width: Int
    public var height: Int
    public var pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

/// CPU-side mip chain generation for RGBA8 images. Doing it here (instead of with
/// `generateMipmaps` / `vkCmdBlitImage`) keeps both backends byte-identical and needs no
/// blit or render usage on the texture.
enum MipChain {
    typealias Level = TextureMipLevel

    /// Levels in a full chain down to 1x1: floor(log2(max(width, height))) + 1.
    static func levelCount(width: Int, height: Int) -> Int {
        precondition(width > 0 && height > 0, "Texture size must be positive")
        return Int.bitWidth - max(width, height).leadingZeroBitCount
    }

    /// Size of level `level` (each level halves, rounding down, never below 1).
    static func size(width: Int, height: Int, level: Int) -> (width: Int, height: Int) {
        (max(width >> level, 1), max(height >> level, 1))
    }

    /// Full chain including level 0. A 2x2 box filter, in linear light for sRGB color
    /// (alpha is always linear). Odd sizes clamp the 2x2 footprint at the edge.
    static func generate(pixels: [UInt8], width: Int, height: Int, srgb: Bool) -> [Level] {
        precondition(pixels.count == width * height * 4, "Pixel data must be width * height * 4 bytes")
        var levels = [Level(width: width, height: height, pixels: pixels)]
        for level in 1..<levelCount(width: width, height: height) {
            let previous = levels[level - 1]
            let (w, h) = size(width: width, height: height, level: level)
            var out = [UInt8](repeating: 0, count: w * h * 4)
            for y in 0..<h {
                let y0 = min(y * 2, previous.height - 1), y1 = min(y * 2 + 1, previous.height - 1)
                for x in 0..<w {
                    let x0 = min(x * 2, previous.width - 1), x1 = min(x * 2 + 1, previous.width - 1)
                    for c in 0..<4 {
                        let taps = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)].map { x, y in
                            previous.pixels[(y * previous.width + x) * 4 + c]
                        }
                        out[(y * w + x) * 4 + c] = average(taps, srgb: srgb && c < 3)
                    }
                }
            }
            levels.append(Level(width: w, height: h, pixels: out))
        }
        return levels
    }

    /// Full chain for linear RGBA32F pixels, converted to RGBA16F bytes per level. A plain 2x2
    /// box filter on all four channels; filtering happens in float, so no precision is lost
    /// before the final conversion.
    static func generateFloat(pixels: [Float], width: Int, height: Int, generateMipmaps: Bool = true) -> [Level] {
        precondition(pixels.count == width * height * 4, "Pixel data must be width * height * 4 floats")
        var levels = [Level(width: width, height: height, pixels: Half.encode(pixels))]
        guard generateMipmaps else { return levels }
        var previous = pixels, previousWidth = width, previousHeight = height
        for level in 1..<levelCount(width: width, height: height) {
            let (w, h) = size(width: width, height: height, level: level)
            var out = [Float](repeating: 0, count: w * h * 4)
            for y in 0..<h {
                let y0 = min(y * 2, previousHeight - 1), y1 = min(y * 2 + 1, previousHeight - 1)
                for x in 0..<w {
                    let x0 = min(x * 2, previousWidth - 1), x1 = min(x * 2 + 1, previousWidth - 1)
                    for c in 0..<4 {
                        let sum = previous[(y0 * previousWidth + x0) * 4 + c] + previous[(y0 * previousWidth + x1) * 4 + c]
                            + previous[(y1 * previousWidth + x0) * 4 + c] + previous[(y1 * previousWidth + x1) * 4 + c]
                        out[(y * w + x) * 4 + c] = sum / 4
                    }
                }
            }
            levels.append(Level(width: w, height: h, pixels: Half.encode(out)))
            previous = out
            previousWidth = w
            previousHeight = h
        }
        return levels
    }

    private static func average(_ taps: [UInt8], srgb: Bool) -> UInt8 {
        if !srgb { return UInt8((taps.reduce(0) { $0 + Int($1) } + 2) / 4) }
        let linear = taps.reduce(Float(0)) { $0 + srgbToLinear[Int($1)] } / 4
        return linearToSRGB(linear)
    }

    private static let srgbToLinear: [Float] = (0..<256).map { i in
        let c = Float(i) / 255
        return c <= 0.04045 ? c / 12.92 : powf((c + 0.055) / 1.055, 2.4)
    }

    private static func linearToSRGB(_ value: Float) -> UInt8 {
        let c = min(max(value, 0), 1)
        let encoded = c <= 0.0031308 ? c * 12.92 : 1.055 * powf(c, 1 / 2.4) - 0.055
        return UInt8(min(max(encoded * 255 + 0.5, 0), 255))
    }
}

/// IEEE 754 binary16 conversion (`Float16` isn't available on every platform we build for).
enum Half {
    /// Round-to-nearest-even; overflow becomes infinity, NaN stays NaN.
    static func bits(_ value: Float) -> UInt16 {
        let f = value.bitPattern
        let sign = UInt16((f >> 16) & 0x8000)
        let exponent = Int((f >> 23) & 0xFF)
        let mantissa = f & 0x7F_FFFF
        if exponent == 0xFF { return sign | 0x7C00 | (mantissa != 0 ? 0x200 : 0) }
        let e = exponent - 127 + 15
        if e >= 0x1F { return sign | 0x7C00 }
        if e <= 0 {
            if e < -10 { return sign }
            // Subnormal: shift the implicit-one mantissa into place.
            let full = mantissa | 0x80_0000
            let shift = UInt32(14 - e)
            var half = full >> shift
            let remainder = full & ((1 << shift) - 1), halfway = UInt32(1) << (shift - 1)
            if remainder > halfway || (remainder == halfway && half & 1 == 1) { half += 1 }
            return sign | UInt16(half)
        }
        var half = UInt32(e) << 10 | mantissa >> 13
        let remainder = mantissa & 0x1FFF
        if remainder > 0x1000 || (remainder == 0x1000 && half & 1 == 1) { half += 1 }  // a carry into the exponent is correct
        return sign | UInt16(half)
    }

    static func value(_ bits: UInt16) -> Float {
        let sign = UInt32(bits & 0x8000) << 16
        let exponent = Int((bits >> 10) & 0x1F)
        let mantissa = UInt32(bits & 0x3FF)
        if exponent == 0x1F { return Float(bitPattern: sign | 0x7F80_0000 | mantissa << 13) }
        if exponent == 0 {
            let magnitude = Float(mantissa) * 0x1p-24
            return sign == 0 ? magnitude : -magnitude
        }
        return Float(bitPattern: sign | UInt32(exponent - 15 + 127) << 23 | mantissa << 13)
    }

    /// Little-endian binary16 bytes, the in-memory layout of `.rgba16Float` texels.
    static func encode(_ values: [Float]) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: values.count * 2)
        for (i, value) in values.enumerated() {
            let half = bits(value)
            bytes[i * 2] = UInt8(half & 0xFF)
            bytes[i * 2 + 1] = UInt8(half >> 8)
        }
        return bytes
    }
}
