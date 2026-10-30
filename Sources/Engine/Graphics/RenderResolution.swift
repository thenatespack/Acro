import Foundation

/// The size the scene is rendered at. `.native` renders at the window's framebuffer size;
/// `.fixed` renders offscreen at that size and scales the result into the window
/// (letterboxed). Screenshots are taken at the render resolution, so a fixed size can
/// be far larger than any window (up to `RenderDevice.maxTextureSize`: 16384 on most GPUs,
/// 32768 on Apple10-family GPUs such as M5). `.scaled` renders at the window size divided
/// by a factor and lets the `Upscaler` bring it back up.
public enum RenderResolution: Equatable, Sendable, CustomStringConvertible {
    case native
    case fixed(width: Int, height: Int)
    /// The window's framebuffer size divided by `factor` (> 1 renders fewer pixels).
    case scaled(Float)

    /// Upscaling modes by name, as FSR and similar upscalers define them.
    public static let scaleModes: [(name: String, factor: Float)] = [
        ("quality", 1.5), ("balanced", 1.7), ("performance", 2), ("ultraperformance", 3),
    ]

    /// Named sizes, smallest first (all 16:9 except where the name implies otherwise).
    public static let presets: [(name: String, resolution: RenderResolution)] = [
        ("144p", .fixed(width: 256, height: 144)),
        ("240p", .fixed(width: 426, height: 240)),
        ("360p", .fixed(width: 640, height: 360)),
        ("480p", .fixed(width: 854, height: 480)),
        ("540p", .fixed(width: 960, height: 540)),
        ("720p", .fixed(width: 1280, height: 720)),
        ("1080p", .fixed(width: 1920, height: 1080)),
        ("1440p", .fixed(width: 2560, height: 1440)),
        ("4k", .fixed(width: 3840, height: 2160)),
        ("5k", .fixed(width: 5120, height: 2880)),
        ("8k", .fixed(width: 7680, height: 4320)),
        ("12k", .fixed(width: 11520, height: 6480)),
        ("16k", .fixed(width: 15360, height: 8640)),
    ]

    /// Parses `native`, a preset name, `<height>p` (16:9), `<n>k` (n × 960 wide, 16:9),
    /// `<width>x<height>`, a scale mode name (`quality`, `balanced`, `performance`,
    /// `ultraperformance`), or `<factor>x` (e.g. `1.5x`: window size / 1.5).
    public init?(_ string: String) {
        let text = string.lowercased().trimmingCharacters(in: .whitespaces)
        if text == "native" {
            self = .native
            return
        }
        if let preset = Self.presets.first(where: { $0.name == text }) {
            self = preset.resolution
            return
        }
        if let mode = Self.scaleModes.first(where: { $0.name == text.replacingOccurrences(of: "-", with: "") }) {
            self = .scaled(mode.factor)
            return
        }
        if text.hasSuffix("x"), let factor = Float(text.dropLast()), factor >= 1 {
            self = .scaled(factor)
            return
        }
        let parts = text.split(separator: "x")
        if parts.count == 2, let width = Int(parts[0]), let height = Int(parts[1]), width > 0, height > 0 {
            self = .fixed(width: width, height: height)
            return
        }
        if text.hasSuffix("p"), let height = Int(text.dropLast()), height > 0 {
            // Round the width to an even number, as video sizes do (480p → 854).
            self = .fixed(width: (height * 16 + 8) / 9 / 2 * 2, height: height)
            return
        }
        if text.hasSuffix("k"), let n = Int(text.dropLast()), n > 0 {
            self = .fixed(width: n * 960, height: n * 540)
            return
        }
        return nil
    }

    public var description: String {
        switch self {
        case .native: "native"
        case .fixed(let width, let height):
            Self.presets.first { $0.resolution == self }.map { "\($0.name) (\(width)x\(height))" } ?? "\(width)x\(height)"
        case .scaled(let factor):
            Self.scaleModes.first { $0.factor == factor }.map { "\($0.name) (1/\(factor))" } ?? "1/\(factor)"
        }
    }

    /// The fixed size, or nil for `.native` and `.scaled` (which depend on the window).
    public var size: (width: Int, height: Int)? {
        if case .fixed(let width, let height) = self { return (width, height) }
        return nil
    }

    /// The offscreen render size for a window of `window` pixels, or nil for `.native`.
    public func size(window: (width: Int, height: Int)) -> (width: Int, height: Int)? {
        switch self {
        case .native: nil
        case .fixed(let width, let height): (width, height)
        case .scaled(let factor):
            (max(1, Int((Float(window.width) / factor).rounded())), max(1, Int((Float(window.height) / factor).rounded())))
        }
    }

    /// Bytes of multisampled color + depth per pixel per sample (BGRA8 + Depth32F).
    static let bytesPerSample = 8
    /// Memory allowed for the multisampled scene targets; MSAA is reduced to fit.
    static let msaaBudget = 4 << 30

    /// The largest sample count ≤ `requested` whose scene targets fit `msaaBudget`.
    func affordableSampleCount(_ requested: Int) -> Int {
        guard let (width, height) = size else { return requested }
        let perSample = width * height * Self.bytesPerSample
        return [8, 4, 2, 1].first { $0 <= requested && perSample * $0 <= Self.msaaBudget } ?? 1
    }
}

/// The largest pixel-aligned rectangle inside `window` with the image's aspect ratio, centered.
/// Upscalers render into exactly this rectangle so output pixels map 1:1 onto it.
func letterboxRect(image: (width: Int, height: Int), window: (width: Int, height: Int))
    -> (x: Int, y: Int, width: Int, height: Int) {
    var width = window.width, height = window.height
    if width * image.height > height * image.width {
        width = max(1, (height * image.width + image.height / 2) / image.height)
    } else {
        height = max(1, (width * image.height + image.width / 2) / image.width)
    }
    return ((window.width - width) / 2, (window.height - height) / 2, width, height)
}

/// Clip-space scale that fits an image of `image` size inside `window`, keeping its aspect ratio.
func letterboxScale(image: (width: Int, height: Int), window: (width: Int, height: Int)) -> Vec2 {
    let imageAspect = Float(image.width) / Float(image.height)
    let windowAspect = Float(window.width) / Float(window.height)
    return windowAspect > imageAspect ? Vec2(imageAspect / windowAspect, 1) : Vec2(1, windowAspect / imageAspect)
}
