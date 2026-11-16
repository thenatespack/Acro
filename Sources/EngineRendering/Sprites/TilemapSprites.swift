import Foundation
import EngineAssets
import EngineCore
import EngineGraphics
import EngineScene

// Drawing a `.tilemap` in a sprite game: its tile set becomes a `SpriteAtlas` (frame n is tile n),
// and `TilemapSpriteDrawer` queues the visible chunks of every visible layer into a `SpriteBatch`
// each frame, with parallax, opacity, flips and turns, and animated tiles played as `SpriteClip`s.
//
// ```swift
// let drawer = try TilemapSpriteDrawer(assets: assets, path: "Levels/level1.tilemap", device: device)
// // each frame:
// drawer?.draw(into: sprites.batch, camera: camera, time: world.time.elapsed)
// sprites.render(into: pass, viewProjection: camera.viewProjection)
// ```

extension TilemapAnimation {
    /// The animation as a sprite clip (frames are tile set indices, which are the atlas frames).
    public var clip: SpriteClip {
        SpriteClip("tile", frames: frames, fps: fps, mode: SpriteLoopMode(rawValue: mode) ?? .loop)
    }
}

extension SpriteAtlas {
    /// One frame per tile of `layout`, named "tile<n>", pivot centered.
    public static func frames(for layout: TilesetLayout) -> [SpriteFrame] {
        (0..<layout.count).map { i in
            let r = layout.rect(i)
            return SpriteAtlasBuilder.makeFrame(name: "tile\(i)", x: r.x, y: r.y, width: r.width, height: r.height, inset: 0,
                                                pivot: Vec2(0.5, 0.5), atlasWidth: layout.imageWidth, atlasHeight: layout.imageHeight)
        }
    }

    /// Uploads a tilemap's tile set (`AssetDatabase.tileset(of:)`) as an atlas whose frame n is tile n.
    public convenience init(device: RenderDevice, tileset image: Image, layout: TilesetLayout, filter: SamplerFilter = .nearest,
                            pixelsPerUnit: Float = 1) throws {
        let texture = try device.makeTexture(image: image, srgb: true, generateMipmaps: false)
        let sampler = try device.makeSampler(SamplerDescriptor(filter: filter, mipFilter: .none, addressMode: .clampToEdge))
        self.init(texture: texture, frames: Self.frames(for: layout), sampler: sampler, pixelsPerUnit: pixelsPerUnit)
    }
}

/// Queues a tilemap's tiles into a `SpriteBatch`, a chunk at a time: only chunks that overlap the
/// camera's view (after each layer's parallax) are drawn, and empty chunks cost nothing.
@MainActor
public final class TilemapSpriteDrawer {
    /// The map (set it again after a hot reload; chunks are rebuilt).
    public var tilemap: Tilemap { didSet { rebuild() } }
    public let atlas: SpriteAtlas
    /// Where the map's bottom-left corner is in the world.
    public var origin: Vec2 = .zero
    /// Added to every layer's draw order (`Tilemap.order(ofLayer:)`), so sprites can go between layers.
    public var baseOrder: Float = 0
    /// Tiles queued by the last `draw`.
    public private(set) var lastTileCount = 0
    /// Chunks drawn by the last `draw`.
    public private(set) var lastChunkCount = 0

    /// Per layer, per chunk: the indices of its painted cells.
    private var chunks: [[[Int32]]] = []
    private var clips: [Int: SpriteClip] = [:]

    public init(tilemap: Tilemap, atlas: SpriteAtlas) {
        var map = tilemap
        map.normalize()
        self.tilemap = map
        self.atlas = atlas
        rebuild()
    }

    /// The tilemap asset `path` with its imported tile set uploaded to `device` (nil if it isn't a readable tilemap).
    public convenience init?(assets: AssetDatabase, path: String, device: RenderDevice) throws {
        guard let id = assets.id(forPath: TilemapImporter.normalized(path)) else { return nil }
        try self.init(assets: assets, id: id, device: device)
    }

    public convenience init?(assets: AssetDatabase, id: AssetID, device: RenderDevice) throws {
        guard let map = assets.tilemap(id), let tileset = assets.tileset(of: id) else { return nil }
        let atlas = try SpriteAtlas(device: device, tileset: tileset.image, layout: tileset.layout,
                                    filter: map.tileset.filter == "linear" ? .linear : .nearest, pixelsPerUnit: 1 / map.unitsPerPixel)
        self.init(tilemap: map, atlas: atlas)
    }

    private func rebuild() {
        if tilemap.layers.contains(where: { $0.data.count != tilemap.cols * tilemap.rowCount }) { tilemap.normalize() }
        let map = tilemap
        let counts = map.chunkCounts
        let size = map.chunk
        chunks = map.layers.map { layer in
            var lists = [[Int32]](repeating: [], count: counts.x * counts.y)
            for (i, value) in layer.data.enumerated() where value >= 0 {
                let x = i % map.cols, y = i / map.cols
                lists[(y / size) * counts.x + x / size].append(Int32(i))
            }
            return lists
        }
        clips = [:]
        for tile in map.tileset.tiles {
            if let animation = tile.animation, !animation.frames.isEmpty { clips[tile.index] = animation.clip }
        }
    }

    /// The world rectangle a camera sees (grown to cover a rotated view).
    static func visibleRect(_ camera: SpriteCamera) -> (min: Vec2, max: Vec2) {
        var half = camera.viewport / (2 * max(camera.zoom, 0.0001))
        if camera.rotation != 0 { half = Vec2(repeating: (half.x * half.x + half.y * half.y).squareRoot()) }
        return (camera.position - half, camera.position + half)
    }

    /// Queues the visible tiles. `camera` nil draws every chunk with no parallax; `time` (seconds)
    /// steps animated tiles. Returns the number of tiles queued.
    @discardableResult
    public func draw(into batch: SpriteBatch, camera: SpriteCamera? = nil, time: Float = 0) -> Int {
        let map = tilemap
        let cell = map.cellSize
        let counts = map.chunkCounts
        let chunkWorld = cell * Float(map.chunk)
        let rows = map.rowCount
        var tiles = 0, drawnChunks = 0
        for (li, layer) in map.layers.enumerated() where layer.visible && layer.opacity > 0 && li < chunks.count {
            var offset = origin
            if let camera { offset = offset + camera.position * (Vec2(1, 1) - layer.parallax) }
            // Chunk columns and rows (rows from the top) the view overlaps.
            var cx0 = 0, cx1 = counts.x - 1, cy0 = 0, cy1 = counts.y - 1
            if let camera {
                let view = Self.visibleRect(camera)
                let lo = view.min - offset, hi = view.max - offset
                cx0 = max(Int((lo.x / chunkWorld.x).rounded(.down)), 0)
                cx1 = min(Int((hi.x / chunkWorld.x).rounded(.down)), counts.x - 1)
                // y up in the world; chunk row 0 holds the top cells.
                let top = Float(rows) * cell.y
                cy0 = max(Int(((top - hi.y) / chunkWorld.y).rounded(.down)), 0)
                cy1 = min(Int(((top - lo.y) / chunkWorld.y).rounded(.down)), counts.y - 1)
            }
            guard cx0 <= cx1, cy0 <= cy1 else { continue }
            let order = baseOrder + map.order(ofLayer: li)
            let tint = Vec4(1, 1, 1, min(max(layer.opacity, 0), 1))
            for cy in cy0...cy1 {
                for cx in cx0...cx1 {
                    let list = chunks[li][cy * counts.x + cx]
                    guard !list.isEmpty else { continue }
                    drawnChunks += 1
                    for index in list {
                        let i = Int(index)
                        let c = TileCell(encoded: layer.data[i])
                        let frame = clips[c.tile]?.frame(at: time) ?? c.tile
                        let x = i % map.cols, y = i / map.cols
                        let center = offset + Vec2((Float(x) + 0.5) * cell.x, (Float(rows - 1 - y) + 0.5) * cell.y)
                        var flip: SpriteFlip = []
                        if c.flipX { flip.insert(.horizontal) }
                        if c.flipY { flip.insert(.vertical) }
                        let transform = Mat4(translation: Vec3(center.x, center.y, 0),
                                             rotation: Quat(angle: -Float(c.rotation) * .pi / 2, axis: Vec3(0, 0, 1)), scale: .one)
                        batch.draw(atlas, frame: frame, transform: transform, size: cell, pivot: Vec2(0.5, 0.5), tint: tint,
                                   flip: flip, order: order)
                        tiles += 1
                    }
                }
            }
        }
        lastTileCount = tiles
        lastChunkCount = drawnChunks
        return tiles
    }
}
