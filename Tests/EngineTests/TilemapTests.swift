import Foundation
import Testing
@testable import Engine
@testable import EngineCore
@testable import EngineScene
@testable import EngineGraphics
@testable import EngineBackends
@testable import EngineText
@testable import EnginePhysics
@testable import EngineAudio
@testable import EngineAssets
@testable import EngineMeshBuild
@testable import EngineNet
@testable import EngineUI
@testable import EngineRendering

// Tilemaps: cells and transforms, the file format, brushes and auto-tiling, merged collision,
// the .tilemap importer and drawing through a SpriteBatch.

private func makeProject() throws -> Project {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TilemapTests-\(UUID().uuidString)", isDirectory: true)
    return try Project.create(at: url, name: "Tilemap")
}

@MainActor private final class TilemapTestsTexture: GPUTexture {
    let width = 128, height = 64
    let format = TextureFormat.rgba8Srgb
    let mipLevelCount = 1
}

private func blank(_ columns: Int = 8, _ rows: Int = 6, layers: [String] = ["Ground"]) -> Tilemap {
    var map = Tilemap(columns: columns, rows: rows, tileset: TilemapStarter.tileset(imagePath: "Tiles/starter.png"),
                      layers: layers.map { TilemapLayer(name: $0) }, terrains: [TilemapStarter.terrain])
    map.normalize()
    return map
}

@Suite struct TilemapTests {
    @Test func cellsEncodeTileAndTransform() {
        let cell = TileCell(tile: 21, flipX: true, flipY: false, rotation: 3)
        #expect(cell.encoded == 21 + 65536 + 3 * 262144)
        #expect(TileCell(encoded: cell.encoded) == cell)
        #expect(TileCell(encoded: -1).isEmpty && TileCell.empty.encoded == -1)
        #expect(TileCell(tile: 2, rotation: 5).rotation == 1)
        // A quarter turn clockwise takes the top-left corner to the top-right; a flip mirrors first.
        #expect(TileCell(tile: 0, rotation: 1).place(Vec2(0, 1)) == Vec2(1, 1))
        #expect(TileCell(tile: 0, flipX: true).place(Vec2(0, 0)) == Vec2(1, 0))
        #expect(TileCell(tile: 0, flipX: true, rotation: 1).place(Vec2(0, 0)) == Vec2(0, 0))
    }

    @Test func fileRoundTripsWithRowsAndSparseFilesDecode() throws {
        var map = blank(4, 3)
        map.setCell(layer: 0, x: 1, y: 2, TileCell(tile: 5, flipY: true))
        map.objects = [TilemapObject(name: "Spawn", type: "spawn", position: Vec2(1, 1))]
        let data = try map.fileData()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"cells\""), "layers are written as rows")
        #expect(try AssetJSON.decoder().decode(Tilemap.self, from: data) == map)

        let sparse = try AssetJSON.decoder().decode(Tilemap.self, from: Data("{}".utf8))
        #expect(sparse.cols == 32 && sparse.rowCount == 18 && sparse.tileW == 16 && sparse.layers.isEmpty)
        #expect(sparse.cellSize == Vec2(1, 1), "a tile is one unit wide by default")
        let flat = try AssetJSON.decoder().decode(Tilemap.self, from: Data("""
            {"size": [2, 2], "tileset": {"source": "a.png"}, "layers": [{"name": "L", "data": [0, 1, -1, 3]}]}
            """.utf8))
        #expect(flat.layers[0].data == [0, 1, -1, 3] && flat.tileset.source == .image(path: "a.png"))
        let future = try AssetJSON.decoder().decode(Tilemap.self, from: Data(#"{"tileset": {"source": {"kind": "aseprite", "file": "a.aseprite"}}}"#.utf8))
        #expect(future.tileset.source.kind == "aseprite")
        var warnings: [String] = []
        _ = future.buildTileset(load: { _ in nil }, warnings: &warnings)
        #expect(warnings.contains { $0.contains("'aseprite'") })
        let reencoded = try AssetJSON.decoder().decode(Tilemap.self, from: future.fileData())
        #expect(reencoded.tileset.source == future.tileset.source, "unknown sources are kept as written")
    }

    @Test func worldAndCellCoordinates() {
        var map = blank(10, 5)
        map.pixelsPerUnit = 8   // 16 px tiles: 2 units
        #expect(map.cellSize == Vec2(2, 2) && map.worldSize == Vec2(20, 10))
        #expect(map.cellCenter(x: 0, y: 4) == Vec2(1, 1), "the bottom-left cell")
        #expect(map.cellCenter(x: 0, y: 0) == Vec2(1, 9), "row 0 is the top")
        #expect(map.cell(atWorld: Vec2(3, 9.5))! == (1, 0))
        #expect(map.cell(atWorld: Vec2(-1, 1)) == nil)
        map.resize(columns: 12, rows: 6, anchorBottom: true)
        #expect(map.layers[0].data.count == 72)
    }

    @Test func brushesPaintFillAndErase() {
        var map = blank()
        #expect(map.paint(layer: 0, cells: [(0, 0), (1, 0), (99, 99)], TileCell(tile: 16)) == 2)
        #expect(map.cell(layer: 0, x: 1, y: 0).tile == 16)
        #expect(map.paint(layer: 0, cells: map.rectCells(3, 3, 1, 1), TileCell(tile: 17)) == 9)
        // Flood fill replaces the empty region around (7, 5), not the painted cells.
        let filled = map.floodFill(layer: 0, x: 7, y: 5, TileCell(tile: 30))
        #expect(filled == 48 - 11)
        #expect(map.cell(layer: 0, x: 2, y: 2).tile == 17 && map.cell(layer: 0, x: 7, y: 0).tile == 30)
        #expect(map.paint(layer: 0, cells: [(1, 0)], .empty) == 1 && map.cell(layer: 0, x: 1, y: 0).isEmpty)

        var a = blank(), b = blank()
        a.paintRandom(layer: 0, cells: a.rectCells(0, 0, 7, 5), tiles: [22, 28, 29], seed: 4)
        b.paintRandom(layer: 0, cells: b.rectCells(0, 0, 7, 5), tiles: [22, 28, 29], seed: 4)
        #expect(a == b, "stable per seed")
        #expect(Set(a.layers[0].data).count == 3)
    }

    @Test func terrainPaintingPicksEdgeTiles() {
        var map = blank(8, 6)
        map.terrains[0].edgesConnect = false
        map.paintTerrain(layer: 0, terrain: 0, cells: map.rectCells(2, 2, 4, 4))
        func tile(_ x: Int, _ y: Int) -> Int { map.cell(layer: 0, x: x, y: y).tile }
        #expect(tile(3, 3) == 15, "surrounded: every side")
        #expect(tile(3, 2) == 2 | 4 | 8, "top middle: no north neighbor, so it gets grass")
        #expect(tile(2, 2) == 2 | 4, "top-left corner: east and south")
        #expect(tile(4, 4) == 1 | 8, "bottom-right corner")
        // Erasing re-picks the neighbors.
        map.paintTerrain(layer: 0, terrain: 0, cells: [(3, 3)], erase: true)
        #expect(map.cell(layer: 0, x: 3, y: 3).isEmpty)
        #expect(tile(3, 2) == 2 | 8 && tile(2, 3) == 1 | 4)

        var connected = blank(4, 2)
        connected.paintTerrain(layer: 0, terrain: 0, cells: connected.rectCells(0, 1, 3, 1))
        #expect(connected.cell(layer: 0, x: 0, y: 1).tile == 2 | 4 | 8, "the map's edge counts as ground")

        let blob = TilemapTerrainSet(name: "B", mode: .blob, tiles: ["255": 1, "85": 2, "0": 3])
        #expect(blob.tile(for: 255) == 1)
        #expect(blob.tile(for: 0b0101_0111) == 2, "no exact entry: the sides-only entry")
        #expect(TilemapTerrainSet.reduced(0b0000_0011, mode: .blob) == 1, "a corner without both sides doesn't count")
    }

    @MainActor @Test func collisionMergesTilesIntoFewShapes() throws {
        var map = blank(8, 6)
        // A solid floor two rows deep, a one-way platform of 3 tiles, a ramp.
        map.paint(layer: 0, cells: map.rectCells(0, 4, 7, 5), TileCell(tile: 16))
        map.paint(layer: 0, cells: map.rectCells(2, 1, 4, 1), TileCell(tile: 18))
        map.paint(layer: 0, cells: [(6, 3)], TileCell(tile: 19))
        map.paint(layer: 0, cells: [(0, 0)], TileCell(tile: 29))   // decoration: no collision
        let shapes = map.collisionShapes()
        #expect(shapes.count == 3, "\(shapes.map(\.name))")
        let floor = try #require(shapes.first { $0.cellCount == 16 })
        #expect(floor.shape == .box(halfExtents: Vec2(4, 1)) && floor.position == Vec2(4, 1) && !floor.isOneWay)
        let platform = try #require(shapes.first { $0.isOneWay })
        #expect(platform.cellCount == 3 && platform.shape == .box(halfExtents: Vec2(1.5, 0.125)))
        #expect(abs(platform.position.y - 4.875) < 1e-5 && platform.position.x == 3.5)
        let ramp = try #require(shapes.first { if case .polygon = $0.shape { true } else { false } })
        #expect(ramp.position == Vec2(6.5, 2.5))
        // Layers can opt out.
        map.layers[0].collision = false
        #expect(map.collisionShapes().isEmpty)

        let world = World()
        map.layers[0].collision = true
        let colliders = world.spawnTilemapColliders(map, at: Vec2(10, 0))
        #expect(colliders.count == 3 && world.get(Transform.self, for: colliders[0])?.position.x == 14)
    }

    @Test func turnedTilesTurnTheirCollision() throws {
        var map = blank(3, 1)
        map.paint(layer: 0, cells: [(0, 0)], TileCell(tile: 18, rotation: 2))   // the platform strip upside down
        let shapes = map.collisionShapes()
        #expect(shapes.count == 1 && abs(shapes[0].position.y - 0.125) < 1e-5)
        // The upside-down platform faces down: its box is turned half way round.
        #expect(shapes[0].isOneWay && abs(abs(shapes[0].angle) - .pi) < 1e-5 && shapes[0].shape == .box(halfExtents: Vec2(0.5, 0.125)))
        // A platform turned a quarter clockwise is a strip on the cell's right side whose landing side faces right.
        map.paint(layer: 0, cells: [(0, 0)], TileCell(tile: 18, rotation: 1))
        let side = try #require(map.collisionShapes().first)
        #expect(abs(side.position.x - 0.875) < 1e-5 && abs(side.position.y - 0.5) < 1e-5 && abs(side.angle + .pi / 2) < 1e-5)
        #expect(side.shape == .box(halfExtents: Vec2(0.5, 0.125)), "laid out in its own (turned) frame")
        // Flipping in x keeps an upright platform upright; plain solid tiles never turn.
        map.paint(layer: 0, cells: [(0, 0)], TileCell(tile: 18, flipX: true))
        #expect(map.collisionShapes().first?.angle == 0)
        map.paint(layer: 0, cells: [(0, 0)], TileCell(tile: 16, rotation: 1))
        #expect(map.collisionShapes().first?.angle == 0)
    }

    /// A one-way tile turned on its side stops bodies coming from its landing side only.
    @MainActor @Test func turnedOneWayPlatformsFollowTheirTurn() {
        var map = blank(3, 3)
        // A wall of right-facing platforms in the middle column.
        map.paint(layer: 0, cells: [(1, 0), (1, 1), (1, 2)], TileCell(tile: 18, rotation: 1))
        func run(from x: Float, speed: Float) -> Float {
            let world = World()
            let physics = PhysicsWorld2D()
            physics.gravity = .zero
            world.addPhysics2D(physics)
            world.spawnTilemapColliders(map)
            let ball = world.spawn(Transform(position: Vec3(x, 1.5, 0)), Collider2D(.circle(radius: 0.2)), RigidBody2D(linearVelocity: Vec2(speed, 0)))
            for _ in 0..<60 { world.update(dt: 1.0 / 60) }
            return world.get(Transform.self, for: ball)!.position.x
        }
        // From the right, moving left: lands on the platform's right face (x 2) and stays right of it.
        #expect(run(from: 2.8, speed: -3) > 1.9)
        // From the left, moving right: passes through.
        #expect(run(from: 0.3, speed: 3) > 2.5)
    }

    @MainActor @Test func importsLayersCollisionAndObjectsAndHotReloads() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let tilesURL = project.url(forAssetPath: "Tiles/starter.png")
        try FileManager.default.createDirectory(at: tilesURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try TilemapStarter.image().pngData().write(to: tilesURL)
        let database = AssetDatabase(project: project)
        database.refresh()

        var map = blank(40, 6, layers: ["Back", "Ground"])
        map.chunkSize = 16
        map.layers[0].collision = false
        map.layers[0].opacity = 0.5
        map.paint(layer: 0, cells: map.rectCells(0, 0, 39, 3), TileCell(tile: 30))
        map.paintTerrain(layer: 1, terrain: 0, cells: map.rectCells(0, 4, 39, 5))
        map.paint(layer: 1, cells: [(5, 2)], TileCell(tile: 22))
        map.objects = [TilemapObject(name: "Player", type: "spawn", position: Vec2(2, 3)),
                       TilemapObject(name: "Goal", type: "trigger", position: Vec2(38, 3), size: Vec2(2, 2), trigger: true)]
        let id = try database.createTilemap(map, at: "Levels/one.tilemap")
        let record = try #require(database.record(id))
        #expect(record.importer == "tilemap" && record.importError == nil)
        #expect(record.objects.filter { $0.kind == .mesh }.count == 6 + 4, "3 chunks across on each layer, plus the water's 4 frames")
        let tileset = try #require(database.tileset(of: id))
        #expect(tileset.layout.count == 32 && tileset.layout.columns == 8 && tileset.image.width == 128)
        let material = try #require(database.material(AssetReference(id, subAsset: "material/Back")))
        #expect(material.alphaMode == .blend && material.baseColor.w == 0.5 && material.filter == .nearest && material.emissive == 1)

        let prefab = try #require(database.prefab(AssetReference(id)))
        let root = try #require(prefab.roots.first)
        #expect(root.name == "one" && root.children.map(\.name) == ["Back", "Ground", "Collision", "Objects"])
        #expect(root.children[1].transform.position.z > root.children[0].transform.position.z, "later layers in front")
        #expect(root.children[2].children.count == 1, "the ground strip merges into one box")
        #expect(root.children[3].children.map(\.name) == ["Player", "Goal"])
        #expect(root.children[3].children[1].collider2D?.isTrigger == true && root.children[3].children[0].collider2D == nil)

        let mesh = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Ground 0_0")))
        #expect(mesh.vertices.count == 16 * 2 * 4, "one quad per painted cell of the chunk (the animated water has its own)")
        let b = mesh.bounds
        #expect(b.center.x - b.halfExtent.x == 0 && b.center.x + b.halfExtent.x == 16 && b.center.y + b.halfExtent.y <= 6)

        let world = World()
        #expect(world.instantiate(prefab).count == 1)
        #expect(world.count(of: Collider2D.self) == 2)
        #expect(world.count(of: MeshRenderer.self) == 7, "6 chunks and the water")

        // Game code reads the map by path, following hot reload.
        let runtime = try #require(database.tilemap(path: "Assets/Levels/one.tilemap"))
        #expect(runtime.object(named: "Player")?.type == "spawn")
        #expect(runtime.hasTag("water", atWorld: runtime.cellCenter(x: 5, y: 2)))
        var edited = map
        edited.objects.removeAll()
        let revision = database.revision(of: id)
        let warnings = try database.writeTilemap(edited, to: id)
        #expect(warnings.isEmpty, "\(warnings)")
        #expect(database.revision(of: id) > revision)
        #expect(database.tilemap(id)?.objects.isEmpty == true)
        #expect(database.prefab(AssetReference(id))?.roots[0].children.map(\.name) == ["Back", "Ground", "Collision"])
    }

    @MainActor @Test func importWarnsAboutMissingImagesAndUnknownTiles() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let dir = project.url(forAssetPath: "Tiles/a.png").deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Image(width: 8, height: 8, pixels: [UInt8](repeating: 200, count: 256)).pngData().write(to: project.url(forAssetPath: "Tiles/a.png"))
        try Image(width: 8, height: 4, pixels: [UInt8](repeating: 90, count: 128)).pngData().write(to: project.url(forAssetPath: "Tiles/b.png"))
        database.refresh()

        var map = Tilemap(tileWidth: 8, tileHeight: 8, columns: 4, rows: 2,
                          tileset: TilemapTileset(source: .images(["Tiles/a.png", "Tiles/b.png", "Tiles/c.png"])),
                          layers: [TilemapLayer(name: "L")])
        map.normalize()
        map.paint(layer: 0, cells: [(0, 0), (1, 0), (2, 0)], TileCell(tile: 1))
        map.setCell(layer: 0, x: 3, y: 0, TileCell(tile: 9))
        let id = try database.createTilemap(map, at: "m.tilemap")
        map.background = Vec4(0, 0, 0, 1)   // a change, so the write reimports
        let warnings = try database.writeTilemap(map, to: id)
        #expect(warnings.contains { $0.contains("'Tiles/c.png'") })
        #expect(warnings.contains { $0.contains("8 x 4") })
        #expect(warnings.contains { $0.contains("tile 9") })
        let tileset = try #require(database.tileset(of: id))
        #expect(tileset.layout.count == 3 && tileset.image.width == 16 && tileset.image.height == 16, "packed 2 x 2")
    }

    @MainActor @Test func spriteDrawerCullsChunksAndAnimates() {
        var map = blank(64, 4)
        map.chunkSize = 8
        map.paint(layer: 0, cells: map.rectCells(0, 3, 63, 3), TileCell(tile: 16))
        map.paint(layer: 0, cells: [(0, 2)], TileCell(tile: 22, flipX: true, rotation: 1))
        let layout = TilesetLayout(imageWidth: 128, imageHeight: 64, tileWidth: 16, tileHeight: 16)
        let atlas = SpriteAtlas(texture: TilemapTestsTexture(), frames: SpriteAtlas.frames(for: layout), pixelsPerUnit: 16)
        #expect(atlas.frameCount == 32 && atlas.frames[9].x == 16 && atlas.frames[9].y == 16)
        let drawer = TilemapSpriteDrawer(tilemap: map, atlas: atlas)
        let batch = SpriteBatch()
        #expect(drawer.draw(into: batch) == 65, "no camera: everything")
        #expect(batch.prepare().draws.count == 1, "one atlas, one draw")
        batch.clear()

        // A 10-unit-wide view at the left edge sees chunks 0 and 1 only.
        let camera = SpriteCamera(position: Vec2(5, 2), zoom: 10, viewport: Vec2(100, 40))
        #expect(drawer.draw(into: batch, camera: camera) == 17)
        #expect(drawer.lastChunkCount == 2)
        batch.clear()

        // Animated water steps through its frames (4 fps: frame 2 at 0.5 s); its quad is flipped and turned.
        drawer.draw(into: batch, camera: camera, time: 0.5)
        let data = batch.prepare()
        let water = SpriteAtlas.frames(for: layout)[24]
        let uvs = data.vertices.map(\.uv)
        #expect(uvs.contains { abs($0.x - water.uvMin.x) < 1e-6 && abs($0.y - water.uvMin.y) < 1e-6 })
        batch.clear()

        // Parallax 0 keeps a layer with the camera: far to the right, the same cells are in view.
        drawer.tilemap.layers[0].parallax = Vec2(0, 0)
        let near = drawer.draw(into: batch, camera: camera)
        batch.clear()
        let far = SpriteCamera(position: Vec2(500, 2), zoom: 10, viewport: Vec2(100, 40))
        #expect(near == 9 && drawer.draw(into: batch, camera: far) == near)
    }

    @Test func animationsStepLikeSpriteClips() {
        let animation = TilemapAnimation(frames: [4, 5, 6], fps: 2, mode: "pingPong")
        let clip = animation.clip
        for t in stride(from: Float(0), to: 4, by: 0.25) { #expect(animation.frame(at: t) == clip.frame(at: t)) }
        #expect(TilemapAnimation(frames: [1, 2], fps: 10).frame(at: 0.15) == 2)
    }

    /// A 3-frame 8 x 8 sprite, frame f filled with palette color f + 1, frames 1-2 tagged "Flicker".
    private func flickerSprite() -> PixelSprite {
        var sprite = PixelSprite(width: 8, height: 8, frameCount: 3, tags: [PixelSprite.Tag("Flicker", from: 1, to: 2, mode: .pingPong)])
        for f in 0..<3 { sprite.layers[0].cels[f] = [UInt8](repeating: UInt8(f + 1), count: 64) }
        sprite.frames[1].duration = 200
        sprite.frames[2].duration = 200
        return sprite
    }

    @MainActor @Test func spriteTilesetUsesFramesAndTags() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        let spriteID = try database.createPixelSprite(flickerSprite(), at: "Tiles/tiles.sprite")

        var map = Tilemap(tileWidth: 8, tileHeight: 8, columns: 4, rows: 2,
                          tileset: TilemapTileset(source: TilesetSource(path: "Tiles/tiles.sprite")), layers: [TilemapLayer(name: "L")])
        #expect(map.tileset.source == .sprite(path: "Tiles/tiles.sprite"))
        map.normalize()
        map.paint(layer: 0, cells: [(0, 0), (1, 0)], TileCell(tile: 1))
        map.setCell(layer: 0, x: 2, y: 0, TileCell(tile: 0))
        let text = String(decoding: try map.fileData(), as: UTF8.self)
        #expect(text.contains("\"sprite\""))
        #expect(try AssetJSON.decoder().decode(Tilemap.self, from: map.fileData()).tileset.source == map.tileset.source)

        let id = try database.createTilemap(map, at: "Levels/sprite.tilemap")
        let record = try #require(database.record(id))
        #expect(record.importError == nil)
        let tileset = try #require(database.tileset(of: id))
        // 3 frames in a 2 x 2 grid of 10 px cells (8 px plus a pixel of edge on each side); the last cell is empty.
        #expect(tileset.layout.count == 3 && tileset.layout.columns == 2)
        #expect(tileset.image.width == 20 && tileset.image.height == 20)
        let color = try #require(flickerSprite().color(of: 2))   // frame 1 is filled with value 2
        let p = (1 * 20 + 11) * 4   // frame 1 (cell 1 of row 0), top-left pixel
        #expect(Array(tileset.image.pixels[p..<p + 4]) == [color.r, color.g, color.b, color.a], "\(Array(tileset.image.pixels[p..<p + 4])) \(color)")
        // The tag animates the tile of its first frame, at the frames' 200 ms (5 fps).
        let runtime = try #require(database.tilemap(id))
        let animation = try #require(runtime.tileset.tile(1)?.animation)
        #expect(animation.frames == [1, 2] && animation.fps == 5 && animation.mode == "pingPong")
        #expect(runtime.tileset.tile(0)?.animation == nil)

        // A tile's own animation wins over the tag.
        let own = TilemapAnimation(frames: [1, 0], fps: 3)
        #expect(map.addingAnimations([1: animation]).tileset.tile(1)?.animation == animation)
        var withOwn = map
        withOwn.tileset.setTile(TilemapTile(index: 1, animation: own))
        #expect(withOwn.addingAnimations([1: animation]).tileset.tile(1)?.animation == own)

        // Editing the sprite reimports the map (a dependency).
        let revision = database.revision(of: id)
        var sprite = flickerSprite()
        sprite.tags = []
        try database.writePixelSprite(sprite, to: spriteID)
        _ = database.asset(id)
        #expect(database.revision(of: id) > revision)
        #expect(database.tilemap(id)?.tileset.tile(1)?.animation == nil)

        // A missing sprite warns.
        var missing = map
        missing.tileset.source = .sprite(path: "Tiles/none.sprite")
        var warnings: [String] = []
        _ = missing.buildTileset(load: { _ in nil }, warnings: &warnings)
        #expect(warnings.contains { $0.contains("'Tiles/none.sprite'") })
    }

    @MainActor @Test func cookedGamesReadTheTilemapAndItsSpriteTags() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let database = AssetDatabase(project: project)
        try database.createPixelSprite(flickerSprite(), at: "Tiles/tiles.sprite")
        var map = Tilemap(tileWidth: 8, tileHeight: 8, columns: 4, rows: 2,
                          tileset: TilemapTileset(source: .sprite(path: "Tiles/tiles.sprite")), layers: [TilemapLayer(name: "L")])
        map.normalize()
        map.paint(layer: 0, cells: [(0, 1), (1, 1)], TileCell(tile: 0))
        map.objects = [TilemapObject(name: "Spawn", type: "spawn", position: Vec2(1, 1))]
        let id = try database.createTilemap(map, at: "Levels/one.tilemap")
        let scene = project.url(forAssetPath: "Scenes/Main.scene")
        try FileManager.default.createDirectory(at: scene.deletingLastPathComponent(), withIntermediateDirectories: true)
        try World().save().write(to: scene)
        database.scan()

        let report = try AssetCooker.plan(database: database, options: CookOptions(scenes: ["Scenes/Main.scene"], include: ["Levels/one.tilemap"]))
            .run(to: project.root.appendingPathComponent("out"))
        let assets = AssetDatabase(mounting: try AssetPack(url: URL(fileURLWithPath: report.packPath)))
        let cooked = try #require(assets.tilemap(path: "Assets/Levels/one.tilemap"))
        #expect(cooked.object(named: "Spawn")?.type == "spawn")
        #expect(cooked.tileset.tile(1)?.animation?.frames == [1, 2], "the sprite ships too, for its tags")
        #expect(assets.prefab(AssetReference(id)) != nil)
    }

    /// 2D physics simulates parented colliders at their world pose (a placed tilemap prefab's colliders).
    @MainActor @Test func parentedCollidersUseTheirWorldPose() throws {
        let world = World()
        let physics = PhysicsWorld2D()
        world.addPhysics2D(physics)
        // A level placed at x 10: its floor is a child at local (0, -0.5).
        let level = world.spawn(Transform(position: Vec3(10, 0, 0)), Name("Level"))
        let floor = world.spawn(Transform(position: Vec3(0, -0.5, 0)), Collider2D(.box(halfExtents: Vec2(3, 0.5))))
        world.setParent(floor, to: level)
        // A root box above the placed floor and a box parented under a rig at x 5.
        let box = world.spawn(Transform(position: Vec3(10, 3, 0)), Collider2D(.box(halfExtents: Vec2(0.5, 0.5))), RigidBody2D())
        let rig = world.spawn(Transform(position: Vec3(5, 0, 0)))
        let child = world.spawn(Transform(position: Vec3(6, 4, 1)), Collider2D(.box(halfExtents: Vec2(0.5, 0.5))), RigidBody2D())
        world.setParent(child, to: rig)
        for _ in 0..<120 { world.update(dt: 1.0 / 60) }

        let floorBody = try #require(physics.body(for: floor))
        let floorPose = try #require(physics.pose(of: floorBody))
        #expect(floorPose.position == Vec2(10, -0.5))
        let t = try #require(world.get(Transform.self, for: box))
        #expect(abs(t.position.y - 0.5) < 0.06 && abs(t.position.x - 10) < 0.05)
        // The parented body lands at world (11, 0.5) and writes back a local Transform (z kept).
        let c = try #require(world.get(Transform.self, for: child))
        #expect(abs(c.position.y - 0.5) < 0.06 && abs(c.position.x - 6) < 0.05 && c.position.z == 1)

        // Moving the parent moves its colliders.
        world.modify(Transform.self, for: level) { $0.position = Vec3(20, 0, 0) }
        world.update(dt: 1.0 / 60)
        #expect(physics.pose(of: floorBody)?.position == Vec2(20, -0.5))

        // A placed tilemap prefab's colliders follow the prefab root.
        var map = blank(4, 2)
        map.paint(layer: 0, cells: map.rectCells(0, 1, 3, 1), TileCell(tile: 16))
        let placed = world.spawnTilemapColliders(map, at: .zero)
        try #require(placed.count == 1)
        let root = world.spawn(Transform(position: Vec3(0, 100, 0)))
        for e in placed { world.setParent(e, to: root) }
        world.update(dt: 1.0 / 60)
        let stripBody = try #require(physics.body(for: placed[0]))
        let strip = try #require(physics.pose(of: stripBody))
        #expect(strip.position.y > 100 && strip.position.y < 102)
    }

    /// Placed prefabs play animated tiles and apply layer parallax (TilemapMotion).
    @MainActor @Test func placedPrefabsAnimateTilesAndApplyParallax() throws {
        let project = try makeProject()
        defer { try? FileManager.default.removeItem(at: project.root) }
        let tilesURL = project.url(forAssetPath: "Tiles/starter.png")
        try FileManager.default.createDirectory(at: tilesURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try TilemapStarter.image().pngData().write(to: tilesURL)
        let database = AssetDatabase(project: project)
        database.refresh()

        var map = blank(8, 4, layers: ["Sky", "Ground"])
        map.layers[0].parallax = Vec2(0.5, 0.25)
        map.paint(layer: 0, cells: map.rectCells(0, 0, 7, 1), TileCell(tile: 16))
        map.paint(layer: 1, cells: [(1, 3), (2, 3)], TileCell(tile: 22))                 // water: frames 22-25 at 4 fps
        map.paint(layer: 1, cells: [(4, 3)], TileCell(tile: 26, flipX: true))           // torch: 26, 27 at 6 fps
        map.paint(layer: 1, cells: [(5, 3)], TileCell(tile: 16))
        let id = try database.createTilemap(map, at: "Levels/moving.tilemap")
        let prefab = try #require(database.prefab(AssetReference(id)))
        let ground = try #require(prefab.roots.first?.children.first { $0.name == "Ground" })
        #expect(ground.children.map(\.name) == ["chunk 0_0", "tile 22", "tile 26"])
        let water = try #require(ground.children[1].tilemapMotion)
        #expect(water.animation?.frames == [22, 23, 24, 25] && water.meshes.count == 4 && water.parallax == Vec2(1, 1))
        #expect(ground.children[1].mesh.map { MeshHandle($0) } == water.meshes[0], "the painted frame shows before play")
        let waterMesh = try #require(database.mesh(AssetReference(id, subAsset: "mesh/Ground tile 22 frame 23")))
        #expect(waterMesh.vertices.count == 2 * 4, "both water cells")
        let sky = try #require(prefab.roots.first?.children.first { $0.name == "Sky" })
        #expect(sky.tilemapMotion?.parallax == Vec2(0.5, 0.25) && ground.tilemapMotion == nil)

        // Placed at (100, 0), with a camera at (104, 2): the sky follows the camera by half (x) and three quarters (y)
        // of its offset from the map's origin; the tiles step through their frames.
        let world = World()
        world.addBuiltinAnimationSystems()
        let root = try #require(world.instantiate(prefab).first)
        world.modify(Transform.self, for: root) { $0.position = Vec3(100, 0, 0) }
        world.spawn(Transform(position: Vec3(104, 2, 10)), Camera())
        func entity(_ name: String) -> Entity? {
            var found: Entity?
            world.query(Name.self) { e, n in if n.value == name { found = e } }
            return found
        }
        let skyEntity = try #require(entity("Sky")), waterEntity = try #require(entity("tile 22"))
        world.update(dt: 0.1)
        let skyPosition = try #require(world.get(Transform.self, for: skyEntity)).position
        #expect(abs(skyPosition.x - 2) < 1e-4 && abs(skyPosition.y - 1.5) < 1e-4 && skyPosition.z == sky.transform.position.z)
        #expect(world.get(MeshRenderer.self, for: waterEntity)?.mesh == water.meshes[0])
        world.update(dt: 0.2)   // 0.3 s at 4 fps: frame 1
        #expect(world.get(MeshRenderer.self, for: waterEntity)?.mesh == water.meshes[1])
        world.update(dt: 0.8)   // 1.1 s: frame 0 again (loops every second)
        #expect(world.get(MeshRenderer.self, for: waterEntity)?.mesh == water.meshes[0])
        #expect(try JSONDecoder().decode(TilemapMotion.self, from: JSONEncoder().encode(water)) == water)
    }
}
