import Foundation

/// One image inside a sprite atlas: its pixel rectangle, UV rectangle and pivot.
public struct SpriteFrame: Sendable, Equatable {
    public var name: String
    /// Pixel rectangle of the image inside the atlas texture, top-left origin (padding and
    /// extrusion excluded).
    public var x: Int, y: Int, width: Int, height: Int
    /// Texture coordinates of the top-left and bottom-right corners (v grows downward, like
    /// image rows). Inset by `SpriteAtlasImage.grid(inset:)` for sheets without padding.
    public var uvMin: Vec2, uvMax: Vec2
    /// Where the sprite's position is within the frame: (0, 0) is the bottom-left corner,
    /// (0.5, 0.5) the center, (0.5, 0) the bottom middle (a character's feet).
    public var pivot: Vec2

    public var size: Vec2 { Vec2(Float(width), Float(height)) }
}

/// Images packed into one page, ready to become a `SpriteAtlas`. Pure CPU data, so packing
/// can run (and be tested) without a GPU.
public struct SpriteAtlasImage: Sendable {
    public var image: Image
    public var frames: [SpriteFrame]

    public init(image: Image, frames: [SpriteFrame]) {
        self.image = image
        self.frames = frames
    }

    /// Slices a sprite sheet laid out as a regular grid into `columns` x `rows` frames named
    /// `"\(namePrefix)0"`, `"\(namePrefix)1"`, … in reading order. `margin` is the border around
    /// the sheet and `spacing` the gap between cells, in pixels. `inset` pulls every UV
    /// rectangle in by that many pixels on each side: use 0.5 with linear filtering and no
    /// padding between cells so neighbors don't bleed in; 0 with nearest filtering.
    public static func grid(image: Image, columns: Int, rows: Int, margin: Int = 0, spacing: Int = 0,
                            inset: Float = 0, namePrefix: String = "", pivot: Vec2 = Vec2(0.5, 0.5)) -> SpriteAtlasImage {
        precondition(columns > 0 && rows > 0, "A grid needs at least one cell")
        let cellW = (image.width - 2 * margin - spacing * (columns - 1)) / columns
        let cellH = (image.height - 2 * margin - spacing * (rows - 1)) / rows
        precondition(cellW > 0 && cellH > 0, "The grid cells don't fit the image")
        var frames: [SpriteFrame] = []
        for row in 0..<rows {
            for column in 0..<columns {
                let x = margin + column * (cellW + spacing), y = margin + row * (cellH + spacing)
                frames.append(SpriteAtlasBuilder.makeFrame(
                    name: "\(namePrefix)\(frames.count)", x: x, y: y, width: cellW, height: cellH, inset: inset,
                    pivot: pivot, atlasWidth: image.width, atlasHeight: image.height))
            }
        }
        return SpriteAtlasImage(image: image, frames: frames)
    }
}

public enum SpriteAtlasError: Error, CustomStringConvertible {
    case doesNotFit(maxSize: Int)
    case duplicateName(String)

    public var description: String {
        switch self {
        case .doesNotFit(let size): "The images don't fit in a \(size) x \(size) atlas page"
        case .duplicateName(let name): "Two atlas images are named '\(name)'"
        }
    }
}

/// Packs images into one atlas page at runtime. Add images, then `pack()`, then make a
/// `SpriteAtlas` from the result.
///
/// Every image is surrounded by `extrude` pixels that repeat its edge pixels (so bilinear
/// filtering and rotation at the edge sample the image's own color, not a neighbor or
/// transparent black) and followed by `spacing` empty pixels, on the right and bottom. The
/// page is the smallest power-of-two square (up to `maxSize`) the shelf packer fits them in.
/// The result is deterministic: images are placed tallest first, ties in the order added.
public struct SpriteAtlasBuilder {
    public var extrude: Int
    public var spacing: Int
    public var maxSize: Int
    private var entries: [(name: String, image: Image, pivot: Vec2)] = []

    public init(extrude: Int = 1, spacing: Int = 1, maxSize: Int = 4096) {
        self.extrude = max(extrude, 0)
        self.spacing = max(spacing, 0)
        self.maxSize = maxSize
    }

    public var count: Int { entries.count }

    /// Adds an image under `name` (unique); frames keep the order they were added in.
    public mutating func add(name: String, image: Image, pivot: Vec2 = Vec2(0.5, 0.5)) {
        entries.append((name, image, pivot))
    }

    public func pack() throws -> SpriteAtlasImage {
        var seen = Set<String>()
        for entry in entries where !seen.insert(entry.name).inserted { throw SpriteAtlasError.duplicateName(entry.name) }
        let cellSize = { (image: Image) in (w: image.width + 2 * extrude + spacing, h: image.height + 2 * extrude + spacing) }
        let order = entries.indices.sorted {
            let a = entries[$0].image.height, b = entries[$1].image.height
            return a != b ? a > b : $0 < $1
        }
        var size = 16
        var origins: [Int: (x: Int, y: Int)] = [:]
        search: while true {
            var packer = ShelfPacker(width: size, height: size)
            origins.removeAll(keepingCapacity: true)
            for i in order {
                let cell = cellSize(entries[i].image)
                guard let origin = packer.pack(width: cell.w, height: cell.h) else {
                    guard size < maxSize else { throw SpriteAtlasError.doesNotFit(maxSize: maxSize) }
                    size = min(size * 2, maxSize)
                    continue search
                }
                origins[i] = origin
            }
            break
        }

        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        var frames: [SpriteFrame] = []
        for (i, entry) in entries.enumerated() {
            let image = entry.image, origin = origins[i]!
            let left = origin.x + extrude, top = origin.y + extrude
            // The image plus its extruded border: each destination pixel takes the nearest source pixel.
            for dy in -extrude..<(image.height + extrude) {
                let sy = min(max(dy, 0), image.height - 1)
                for dx in -extrude..<(image.width + extrude) {
                    let sx = min(max(dx, 0), image.width - 1)
                    let src = (sy * image.width + sx) * 4, dst = ((top + dy) * size + left + dx) * 4
                    for c in 0..<4 { pixels[dst + c] = image.pixels[src + c] }
                }
            }
            frames.append(Self.makeFrame(
                name: entry.name, x: left, y: top, width: image.width, height: image.height, inset: 0,
                pivot: entry.pivot, atlasWidth: size, atlasHeight: size))
        }
        return SpriteAtlasImage(image: Image(width: size, height: size, pixels: pixels), frames: frames)
    }

    static func makeFrame(name: String, x: Int, y: Int, width: Int, height: Int, inset: Float, pivot: Vec2,
                          atlasWidth: Int, atlasHeight: Int) -> SpriteFrame {
        let w = Float(atlasWidth), h = Float(atlasHeight)
        return SpriteFrame(
            name: name, x: x, y: y, width: width, height: height,
            uvMin: Vec2((Float(x) + inset) / w, (Float(y) + inset) / h),
            uvMax: Vec2((Float(x + width) - inset) / w, (Float(y + height) - inset) / h), pivot: pivot)
    }
}

/// A texture with named, indexed frames: the unit sprites are drawn from. Sprites of one
/// atlas share a texture and so batch into the same draw call.
///
/// Make one from packed images (`SpriteAtlasBuilder.pack()`), from a grid sheet
/// (`SpriteAtlasImage.grid`) or from your own texture and frames. The texture has no mip
/// chain (sprites are drawn near 1:1; mips would bleed neighbors into each other).
@MainActor
public final class SpriteAtlas {
    public let texture: GPUTexture
    /// nil draws with the renderer's linear, clamp-to-edge sampler.
    public let sampler: GPUSampler?
    public private(set) var frames: [SpriteFrame]
    /// Texture pixels per world unit: a sprite is drawn `frame.size / pixelsPerUnit` units big.
    public var pixelsPerUnit: Float
    private var indexByName: [String: Int] = [:]

    public init(texture: GPUTexture, frames: [SpriteFrame], sampler: GPUSampler? = nil, pixelsPerUnit: Float = 1) {
        self.texture = texture
        self.frames = frames
        self.sampler = sampler
        self.pixelsPerUnit = pixelsPerUnit
        for (i, frame) in frames.enumerated() where indexByName[frame.name] == nil { indexByName[frame.name] = i }
    }

    /// Uploads `packed` as a texture. `srgb` (the default) treats the pixels as sRGB colors.
    /// `filter` .nearest keeps pixel art crisp when scaled.
    public convenience init(device: RenderDevice, packed: SpriteAtlasImage, srgb: Bool = true,
                            filter: SamplerFilter = .linear, pixelsPerUnit: Float = 1) throws {
        let texture = try device.makeTexture(image: packed.image, srgb: srgb, generateMipmaps: false)
        let sampler = try device.makeSampler(SamplerDescriptor(filter: filter, mipFilter: .none, addressMode: .clampToEdge))
        self.init(texture: texture, frames: packed.frames, sampler: sampler, pixelsPerUnit: pixelsPerUnit)
    }

    public var frameCount: Int { frames.count }

    public func index(named name: String) -> Int? { indexByName[name] }

    public func frame(named name: String) -> SpriteFrame? { indexByName[name].map { frames[$0] } }

    /// Indices of the frames whose names start with `prefix`, in atlas order (`"walk_"` gives
    /// the frames of a clip named `walk_0`, `walk_1`, …).
    public func frameIndices(prefix: String) -> [Int] {
        frames.indices.filter { frames[$0].name.hasPrefix(prefix) }
    }
}
