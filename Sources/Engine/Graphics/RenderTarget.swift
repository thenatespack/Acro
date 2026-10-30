/// The size of a resizable render target in pixels, kept within `1...maxSize` on both axes.
/// The CPU side of `RenderTarget` (unit-tested on its own).
public struct RenderTargetSizing: Sendable, Equatable {
    public private(set) var width: Int
    public private(set) var height: Int
    public let maxSize: Int

    public init(width: Int, height: Int, maxSize: Int) {
        self.maxSize = max(maxSize, 1)
        self.width = Self.clamp(width, self.maxSize)
        self.height = Self.clamp(height, self.maxSize)
    }

    /// Takes the new size (clamped). Returns whether it differs from the current one, i.e.
    /// whether the GPU target has to be recreated.
    public mutating func update(width: Int, height: Int) -> Bool {
        let w = Self.clamp(width, maxSize), h = Self.clamp(height, maxSize)
        guard w != self.width || h != self.height else { return false }
        self.width = w
        self.height = h
        return true
    }

    /// The pixel size of a `size` in points at `scale` pixels per point (rounded to whole
    /// pixels), e.g. a UI panel's frame. Matches how `UIDrawList` snaps a rect whose origin is
    /// on the pixel grid, so the image maps 1:1 onto the panel's pixels.
    public static func pixels(points size: Vec2, scale: Float) -> (width: Int, height: Int) {
        (Int((size.x * scale).rounded()), Int((size.y * scale).rounded()))
    }

    private static func clamp(_ value: Int, _ maxSize: Int) -> Int { min(max(value, 1), maxSize) }
}

extension RenderTargetDescriptor {
    /// Throws unless both sizes are in `1...maxSize`.
    func validate(maxSize: Int) throws {
        guard (1...maxSize).contains(width), (1...maxSize).contains(height) else {
            throw GraphicsError("Render target size \(width)x\(height) is outside 1...\(maxSize)")
        }
    }
}

/// An offscreen color + depth target that game code renders into and then samples, e.g. an
/// editor viewport shown inside the UI:
///
/// ```swift
/// let target = try RenderTarget(device: engine.device, width: 640, height: 360, label: "editor")
/// // renderOffscreen:
/// try target.resize(toPoints: panel.size, scale: engine.ui.scale)
/// frame.renderPass(into: target, clearColor: sky) { pass in … }
/// // update / render:
/// engine.ui.drawImage(target.texture, in: panel)
/// ```
///
/// Passes into it take `.screen` pipelines (color in the window's sRGB format, depth, and the
/// device's MSAA unless `multisampled` is false). `resize` recreates the GPU target only when
/// the size changes; the old one is freed once no frame in flight uses it, and a texture
/// already queued in a draw list stays valid for that frame.
@MainActor
public final class RenderTarget {
    public let device: RenderDevice
    /// Names this target's passes in GPU timings (`GPUPassTime`).
    public var label: String
    public let multisampled: Bool
    public private(set) var gpu: GPURenderTarget
    public private(set) var sizing: RenderTargetSizing
    /// Counts recreations (resizes), e.g. to notice that `texture` changed.
    public private(set) var generation = 0

    public var width: Int { sizing.width }
    public var height: Int { sizing.height }
    public var aspectRatio: Float { Float(width) / Float(height) }
    /// The color result to sample (see `GPURenderTarget.texture`).
    public var texture: GPUTexture { gpu.texture }

    /// Sizes are clamped to `1...device.maxTextureSize`.
    public init(device: RenderDevice, width: Int, height: Int, multisampled: Bool = true, label: String = "target") throws {
        self.device = device
        self.label = label
        self.multisampled = multisampled
        sizing = RenderTargetSizing(width: width, height: height, maxSize: device.maxTextureSize)
        gpu = try device.makeRenderTarget(
            RenderTargetDescriptor(width: sizing.width, height: sizing.height, multisampled: multisampled))
    }

    /// Recreates the target at a new size (clamped); does nothing when the size is unchanged.
    /// Returns whether it was recreated. On failure the old target and size are kept.
    @discardableResult
    public func resize(width: Int, height: Int) throws -> Bool {
        var next = sizing
        guard next.update(width: width, height: height) else { return false }
        gpu = try device.makeRenderTarget(
            RenderTargetDescriptor(width: next.width, height: next.height, multisampled: multisampled))
        sizing = next
        generation += 1
        return true
    }

    /// Resizes to cover `size` points at `scale` pixels per point (e.g. `engine.ui.scale`).
    @discardableResult
    public func resize(toPoints size: Vec2, scale: Float) throws -> Bool {
        let pixels = RenderTargetSizing.pixels(points: size, scale: scale)
        return try resize(width: pixels.width, height: pixels.height)
    }
}
