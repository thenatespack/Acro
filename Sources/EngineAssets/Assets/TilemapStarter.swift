#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene

/// A ready-to-paint tile set made in code, so a new tilemap shows something without outside art:
/// 32 tiles of 16 x 16 pixels in 8 columns. `tilemap.new` writes it next to the map when no tile
/// set is given.
///
/// - 0...15: dirt with grass on top, one tile per neighbor mask (N 1, E 2, S 4, W 8) for the
///   "Dirt" terrain set (`first: 0`); all collide.
/// - 16 stone, 17 brick (solid); 18 wooden platform (one-way, top); 19 / 20 ramps up / down;
///   21 spikes (tag "hazard"); 22...25 water (animated, tag "water"); 26 / 27 torch (animated);
///   28 coin (tag "pickup"); 29 grass tuft; 30 back wall; 31 ladder (tag "ladder").
public enum TilemapStarter {
    public static let tileSize = 16
    public static let columns = 8
    public static let count = 32

    /// The tile data matching `image()` (collision, tags, animations).
    public static var tiles: [TilemapTile] {
        var tiles = (0..<16).map { TilemapTile(index: $0, collision: .full) }
        tiles += [
            TilemapTile(index: 16, name: "stone", collision: .full),
            TilemapTile(index: 17, name: "brick", collision: .full),
            TilemapTile(index: 18, name: "platform", collision: .top, oneWay: true),
            TilemapTile(index: 19, name: "ramp up", collision: .slopeUp),
            TilemapTile(index: 20, name: "ramp down", collision: .slopeDown),
            TilemapTile(index: 21, name: "spikes", tags: ["hazard"], properties: ["damage": .int(1)]),
            TilemapTile(index: 22, name: "water", tags: ["water"], animation: TilemapAnimation(frames: [22, 23, 24, 25], fps: 4)),
            TilemapTile(index: 26, name: "torch", animation: TilemapAnimation(frames: [26, 27], fps: 6)),
            TilemapTile(index: 28, name: "coin", tags: ["pickup"], properties: ["value": .int(1)]),
            TilemapTile(index: 31, name: "ladder", tags: ["ladder"]),
        ]
        return tiles
    }

    /// The "Dirt" auto-tiling set (tiles 0...15 by edge mask).
    public static var terrain: TilemapTerrainSet { TilemapTerrainSet(name: "Dirt", mode: .edges, first: 0) }

    /// A tile set using the starter image at `path`.
    public static func tileset(imagePath path: String) -> TilemapTileset {
        TilemapTileset(source: .image(path: path), filter: "nearest", tiles: tiles)
    }

    /// The 128 x 64 tile set image.
    public static func image() -> Image {
        var canvas = Canvas(width: columns * tileSize, height: (count / columns) * tileSize)
        for mask in 0..<16 { canvas.dirt(tile: mask, mask: mask) }
        canvas.stone(tile: 16)
        canvas.brick(tile: 17)
        canvas.platform(tile: 18)
        canvas.ramp(tile: 19, up: true)
        canvas.ramp(tile: 20, up: false)
        canvas.spikes(tile: 21)
        for f in 0..<4 { canvas.water(tile: 22 + f, phase: f) }
        canvas.torch(tile: 26, tall: true)
        canvas.torch(tile: 27, tall: false)
        canvas.coin(tile: 28)
        canvas.tuft(tile: 29)
        canvas.wall(tile: 30)
        canvas.ladder(tile: 31)
        return Image(width: canvas.width, height: canvas.height, pixels: canvas.pixels)
    }

    /// A small pixel painter: tile-local coordinates, (0, 0) the tile's top-left pixel.
    struct Canvas {
        let width: Int, height: Int
        var pixels: [UInt8]
        var ox = 0, oy = 0

        init(width: Int, height: Int) {
            self.width = width
            self.height = height
            pixels = [UInt8](repeating: 0, count: width * height * 4)
        }

        mutating func tile(_ index: Int) {
            ox = (index % TilemapStarter.columns) * TilemapStarter.tileSize
            oy = (index / TilemapStarter.columns) * TilemapStarter.tileSize
        }

        mutating func set(_ x: Int, _ y: Int, _ c: (Int, Int, Int)) {
            let n = TilemapStarter.tileSize
            guard x >= 0, y >= 0, x < n, y < n else { return }
            let i = ((oy + y) * width + ox + x) * 4
            pixels[i] = UInt8(c.0); pixels[i + 1] = UInt8(c.1); pixels[i + 2] = UInt8(c.2); pixels[i + 3] = 255
        }

        mutating func rect(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ c: (Int, Int, Int)) {
            for y in y0...y1 { for x in x0...x1 { set(x, y, c) } }
        }

        /// A stable speckle pattern.
        func noise(_ x: Int, _ y: Int, _ salt: Int) -> Int {
            var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263 &+ salt &* 1_442_695_041)
            h = (h ^ (h >> 13)) &* 1_274_126_177
            return Int((h ^ (h >> 16)) % 100)
        }

        mutating func dirt(tile index: Int, mask: Int) {
            tile(index)
            let dirt = (139, 92, 56), dark = (92, 58, 34), speck = (160, 112, 72)
            let grass = (76, 168, 64), light = (124, 210, 96)
            for y in 0..<16 { for x in 0..<16 { set(x, y, noise(x, y, index) < 12 ? speck : dirt) } }
            if mask & 2 == 0 { rect(15, 0, 15, 15, dark) }
            if mask & 4 == 0 { rect(0, 15, 15, 15, dark) }
            if mask & 8 == 0 { rect(0, 0, 0, 15, dark) }
            if mask & 1 == 0 {
                rect(0, 0, 15, 3, grass)
                rect(0, 0, 15, 0, light)
                for x in stride(from: 1, to: 16, by: 3) { set(x, 4, grass) }
            }
        }

        mutating func stone(tile index: Int) {
            tile(index)
            for y in 0..<16 { for x in 0..<16 { set(x, y, noise(x, y, 7) < 15 ? (118, 118, 126) : (136, 136, 146)) } }
            rect(0, 0, 15, 0, (176, 176, 186)); rect(0, 0, 0, 15, (176, 176, 186))
            rect(0, 15, 15, 15, (84, 84, 92)); rect(15, 0, 15, 15, (84, 84, 92))
        }

        mutating func brick(tile index: Int) {
            tile(index)
            rect(0, 0, 15, 15, (150, 66, 48))
            let mortar = (200, 186, 160)
            for y in [3, 7, 11, 15] { rect(0, y, 15, y, mortar) }
            for row in 0..<4 { for x in (row % 2 == 0 ? [0, 8] : [4, 12]) { rect(x, row * 4, x, row * 4 + 2, mortar) } }
        }

        mutating func platform(tile index: Int) {
            tile(index)
            rect(0, 0, 15, 3, (168, 116, 64))
            rect(0, 0, 15, 0, (206, 150, 90))
            rect(0, 3, 15, 3, (110, 72, 38))
            rect(2, 4, 3, 6, (110, 72, 38)); rect(12, 4, 13, 6, (110, 72, 38))
        }

        mutating func ramp(tile index: Int, up: Bool) {
            tile(index)
            for y in 0..<16 {
                for x in 0..<16 {
                    let edge = up ? 15 - x : x  // the surface row at this column
                    if y > edge + 2 { set(x, y, noise(x, y, index) < 12 ? (160, 112, 72) : (139, 92, 56)) }
                    else if y >= edge { set(x, y, (76, 168, 64)) }
                }
            }
        }

        mutating func spikes(tile index: Int) {
            tile(index)
            for s in 0..<4 {
                for y in 8..<16 {
                    let half = (y - 8) / 2
                    for x in (s * 4)..<(s * 4 + 4) where abs(2 * x - (s * 8 + 3)) <= 2 * half + 1 {
                        set(x, y, x == s * 4 + 1 ? (220, 220, 230) : (150, 150, 160))
                    }
                }
            }
        }

        mutating func water(tile index: Int, phase: Int) {
            tile(index)
            rect(0, 0, 15, 15, (44, 104, 196))
            for x in 0..<16 {
                let wave = Int((sinf(Float(x + phase * 4) / 16 * 2 * .pi) * 1.5).rounded()) + 2
                set(x, wave, (150, 200, 255))
                set(x, wave + 1, (90, 150, 230))
            }
            for x in stride(from: (phase * 3) % 8, to: 16, by: 8) { set(x, 9, (90, 150, 230)); set(x + 1, 9, (90, 150, 230)) }
        }

        mutating func torch(tile index: Int, tall: Bool) {
            tile(index)
            rect(7, 9, 8, 15, (110, 72, 38))
            rect(6, 8, 9, 8, (80, 80, 90))
            let top = tall ? 2 : 4
            rect(6, top + 2, 9, 7, (240, 140, 40))
            rect(7, top, 8, 7, (255, 210, 80))
            set(tall ? 7 : 8, top - 1, (255, 240, 160))
        }

        mutating func coin(tile index: Int) {
            tile(index)
            for y in 0..<16 {
                for x in 0..<16 {
                    let dx = Float(x) - 7.5, dy = Float(y) - 7.5
                    let r = (dx * dx / 16 + dy * dy / 36).squareRoot()
                    if r < 0.8 { set(x, y, (250, 210, 60)) } else if r < 1 { set(x, y, (190, 140, 30)) }
                }
            }
            rect(7, 5, 8, 10, (255, 240, 150))
        }

        mutating func tuft(tile index: Int) {
            tile(index)
            for (x, h) in [(3, 5), (5, 8), (7, 6), (9, 9), (11, 5), (13, 7)] { rect(x, 16 - h, x, 15, (76, 168, 64)); set(x, 16 - h, (124, 210, 96)) }
        }

        mutating func wall(tile index: Int) {
            tile(index)
            for y in 0..<16 { for x in 0..<16 { set(x, y, noise(x, y, 30) < 10 ? (52, 48, 60) : (64, 58, 74)) } }
            rect(0, 7, 15, 7, (44, 40, 52)); rect(0, 15, 15, 15, (44, 40, 52))
            rect(7, 0, 7, 6, (44, 40, 52)); rect(15, 8, 15, 14, (44, 40, 52))
        }

        mutating func ladder(tile index: Int) {
            tile(index)
            rect(3, 0, 4, 15, (150, 100, 56)); rect(11, 0, 12, 15, (150, 100, 56))
            for y in [2, 6, 10, 14] { rect(5, y, 10, y, (186, 132, 80)) }
        }
    }
}
