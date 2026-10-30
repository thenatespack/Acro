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
    /// Checks the arguments of `RenderDevice.makeTexture(pixels:...)`.
    func validateUpload(byteCount: Int, width: Int, height: Int, maxSize: Int) throws {
        guard !isDepth else { throw GraphicsError("Pixel data needs a color format, not \(self)") }
        guard width > 0, height > 0, width <= maxSize, height <= maxSize else {
            throw GraphicsError("Texture size \(width)x\(height) is outside 1...\(maxSize)")
        }
        guard byteCount == width * height * 4 else {
            throw GraphicsError("Expected \(width * height * 4) bytes of RGBA8 data for \(width)x\(height), got \(byteCount)")
        }
    }
}

/// CPU-side mip chain generation for RGBA8 images. Doing it here (instead of with
/// `generateMipmaps` / `vkCmdBlitImage`) keeps both backends byte-identical and needs no
/// blit or render usage on the texture.
enum MipChain {
    struct Level {
        var width: Int
        var height: Int
        var pixels: [UInt8]
    }

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
