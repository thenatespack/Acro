import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// A `PixelSprite` laid out as an atlas: every frame composited into one cell of a regular grid,
/// plus one clip per tag. Pure CPU data (EngineRendering turns it into a `SpriteAtlas` and
/// `SpriteClip`s with `SpriteAtlasImage(sheet:)` and `SpriteClip.clips(from:)`).
///
/// Indexing is stable: frame `i` of the sprite is atlas frame `i`, in cell `i` (reading order,
/// `columns` per row), whatever the tags. That also makes the sheet a tile set: tile `i` is
/// frame `i`. Each cell is the frame plus `extrude` pixels repeating its edge on every side, so
/// filtering at the edge never picks up a neighbor.
public struct SpriteSheet: Sendable {
    public struct Frame: Sendable, Equatable {
        public var name: String
        /// Pixel rectangle in `image`, top-left origin (extrusion excluded).
        public var x: Int, y: Int, width: Int, height: Int
        /// Milliseconds.
        public var duration: Int
    }

    /// A tag as a flipbook clip: atlas frame indices at a fixed rate. Frames longer than the
    /// shortest step repeat, so per-frame timing plays exactly at `fps`.
    public struct Clip: Sendable, Equatable {
        public var name: String
        public var frames: [Int]
        public var fps: Float
        public var mode: PixelSprite.TagMode
        /// Events by position in `frames` (a tag event on a repeated frame fires on its first step).
        public var events: [Event] = []

        public struct Event: Sendable, Equatable {
            public var step: Int
            public var name: String
        }
    }

    public var image: Image
    public var frames: [Frame]
    public var clips: [Clip]
    public var columns: Int
    public var rows: Int
    public var cellWidth: Int
    public var cellHeight: Int
    public var extrude: Int
    public var pivot: Vec2
    public var pixelsPerUnit: Float

    /// The atlas frame (= sprite frame = tile) index in grid cell (`column`, `row`).
    public func frameIndex(column: Int, row: Int) -> Int? {
        let i = row * columns + column
        return column >= 0 && column < columns && frames.indices.contains(i) ? i : nil
    }

    public func clip(named name: String) -> Clip? { clips.first { $0.name == name } }
}

extension PixelSprite {
    /// Columns of the atlas grid for `count` frames: a near-square layout.
    public static func sheetColumns(frameCount count: Int) -> Int {
        max(Int(Float(max(count, 1)).squareRoot().rounded(.up)), 1)
    }

    /// The sprite's frames laid out as an atlas (see `SpriteSheet`).
    public func sheet(extrude: Int = 1) -> SpriteSheet {
        let extrude = max(extrude, 0)
        let columns = Self.sheetColumns(frameCount: frames.count)
        let rows = (frames.count + columns - 1) / columns
        let cellW = width + 2 * extrude, cellH = height + 2 * extrude
        let atlasW = columns * cellW, atlasH = rows * cellH
        var pixels = [UInt8](repeating: 0, count: atlasW * atlasH * 4)
        var sheetFrames: [SpriteSheet.Frame] = []
        for f in frames.indices {
            let image = self.image(frame: f)
            let left = (f % columns) * cellW + extrude, top = (f / columns) * cellH + extrude
            for dy in -extrude..<(height + extrude) {
                let sy = min(max(dy, 0), height - 1)
                for dx in -extrude..<(width + extrude) {
                    let sx = min(max(dx, 0), width - 1)
                    let src = (sy * width + sx) * 4, dst = ((top + dy) * atlasW + left + dx) * 4
                    for c in 0..<4 { pixels[dst + c] = image.pixels[src + c] }
                }
            }
            sheetFrames.append(SpriteSheet.Frame(name: "frame\(f)", x: left, y: top, width: width, height: height,
                                                 duration: frames[f].duration))
        }
        return SpriteSheet(image: Image(width: atlasW, height: atlasH, pixels: pixels), frames: sheetFrames, clips: clips(),
                           columns: columns, rows: rows, cellWidth: cellW, cellHeight: cellH, extrude: extrude,
                           pivot: pivot, pixelsPerUnit: pixelsPerUnit)
    }

    /// One clip per valid tag (ranges clamped to the frames; tags without a name are skipped).
    /// Without tags, one looping clip "default" of every frame.
    public func clips() -> [SpriteSheet.Clip] {
        let ranges: [(String, ClosedRange<Int>, TagMode, [FrameEvent])] = tags.isEmpty
            ? [("default", 0...(frames.count - 1), .loop, [])]
            : tags.compactMap { tag in
                guard !tag.name.isEmpty else { return nil }
                let from = min(max(tag.from, 0), frames.count - 1), to = min(max(tag.to, from), frames.count - 1)
                return (tag.name, from...to, tag.mode, tag.events)
            }
        var seen = Set<String>()
        return ranges.compactMap { name, range, mode, events in
            guard seen.insert(name).inserted else { return nil }
            let durations = range.map { max(frames[$0].duration, 1) }
            let step = durations.reduce(0) { Self.gcd($0, $1) }
            let repeats = durations.map { $0 / step }
            // Repeat frames to keep their timing, unless that would make a very long list.
            var clip: SpriteSheet.Clip
            if repeats.reduce(0, +) <= 512 {
                clip = SpriteSheet.Clip(name: name, frames: zip(range, repeats).flatMap { Array(repeating: $0, count: $1) },
                                        fps: 1000 / Float(step), mode: mode)
            } else {
                let average = Float(durations.reduce(0, +)) / Float(durations.count)
                clip = SpriteSheet.Clip(name: name, frames: Array(range), fps: 1000 / average, mode: mode)
            }
            clip.events = events.compactMap { event in
                guard !event.name.isEmpty, let step = clip.frames.firstIndex(of: event.frame) else { return nil }
                return SpriteSheet.Clip.Event(step: step, name: event.name)
            }
            return clip
        }
    }

    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
}

/// Imports `.sprite` files (`PixelSprite`) as one `texture` sub-asset: the frames laid out as an
/// atlas grid (`PixelSprite.sheet()`), without mipmaps so pixels stay crisp. Game code gets
/// frames and clips from `AssetDatabase.spriteSheet(_:)` (EngineRendering's
/// `SpriteAssetLibrary` turns them into a `SpriteAtlas` and `SpriteClip`s and follows hot reload).
public struct PixelSpriteImporter: AssetImporter {
    public init() {}

    public var name: String { "sprite" }
    public var fileExtensions: [String] { ["sprite"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let sprite: PixelSprite
        do { sprite = try AssetJSON.decoder().decode(PixelSprite.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a pixel sprite: \(error)")
        }
        for problem in sprite.problems() { context.warn(problem) }
        var asset = ImportedAsset()
        asset.add("texture", name: ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension,
                  .texture(TextureAsset(image: sprite.sheet().image, isSRGB: true, generatesMipmaps: false)))
        return asset
    }
}

extension AssetDatabase {
    /// Writes `sprite` to a new `.sprite` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createPixelSprite(_ sprite: PixelSprite, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try sprite.fileData().write(to: url, options: .atomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.sprite` asset `id` (nil if it isn't one or can't be read). Works in a cooked pack too.
    public func pixelSprite(of id: AssetID) -> PixelSprite? {
        guard record(id)?.importer == PixelSpriteImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(PixelSprite.self, from: data)
    }

    /// Overwrites the `.sprite` asset `id` with `sprite` and reimports it. Returns the import's warnings.
    @discardableResult
    public func writePixelSprite(_ sprite: PixelSprite, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try sprite.fileData().write(to: project.url(forAssetPath: path), options: .atomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The `.sprite` asset `id` laid out as an atlas with its clips (nil when it isn't a readable
    /// `.sprite`). Built from the file on each call; `SpriteAssetLibrary` caches it per revision.
    public func spriteSheet(_ id: AssetID) -> SpriteSheet? {
        if pack == nil, record(id)?.importer == PixelSpriteImporter().name { _ = asset(id) }  // reimports if out of date
        return pixelSprite(of: id)?.sheet()
    }

    /// The sprite at `path` (relative to `Assets/`; a leading `Assets/` is allowed).
    public func spriteSheet(path: String) -> SpriteSheet? {
        let relative = path.hasPrefix("Assets/") ? String(path.dropFirst("Assets/".count)) : path
        return id(forPath: relative).flatMap { spriteSheet($0) }
    }
}
