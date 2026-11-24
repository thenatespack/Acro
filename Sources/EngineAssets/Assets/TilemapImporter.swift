#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Imports `.tilemap` files (a `Tilemap` as JSON): `texture/tileset` (the tile set's pictures in
/// one texture), `material/<layer>` per layer (unlit, alpha-tested, nearest filtering by default),
/// `mesh/<layer> <cx>_<cy>` per non-empty layer chunk, and the main `prefab/<file name>`: a root
/// named after the file with a node per visible layer (its chunks as children, layers spaced
/// 0.01 units apart in z by draw order), a `Collision` node with one static `Collider2D` per
/// merged shape, and an `Objects` node with a named node per object point (areas with `trigger`
/// get a trigger box). A `.sprite` tile set lays out its frames as tiles and its tags become tile
/// animations. Animated tiles show the painted frame in the prefab; `TilemapSpriteDrawer` plays them.
public struct TilemapImporter: AssetImporter {
    public init() {}

    public var name: String { "tilemap" }
    public var fileExtensions: [String] { ["tilemap"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        var map: Tilemap
        do { map = try AssetJSON.decoder().decode(Tilemap.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a tilemap: \(error)")
        }
        let stem = context.assetPath.pathLastComponent.pathDeletingExtension
        var warnings: [String] = []
        var sprite: PixelSprite?
        let built = map.buildTileset(load: { path in Self.image(path, &context) },
                                     loadSprite: { path in sprite = Self.sprite(path, &context); return sprite }, warnings: &warnings)
        if let sprite { map = map.addingAnimations(Tilemap.spriteTagAnimations(sprite)) }
        warnings += map.validate(tileCount: built.layout.count)
        map.normalize()
        for warning in warnings { context.warn(warning) }

        var asset = ImportedAsset()
        var namer = SubAssetNamer()
        let textureID = namer.id(kind: "texture", name: "tileset", index: 0)
        asset.add(textureID, name: "tileset", .texture(TextureAsset(image: built.image, isSRGB: true, generatesMipmaps: false)))
        let texture = context.reference(textureID)
        let nearest = map.tileset.filter != "linear"

        var children: [PrefabNode] = []
        var meshIndex = 0
        for (li, layer) in map.layers.enumerated() where layer.visible {
            let opacity = min(max(layer.opacity, 0), 1)
            let materialID = namer.id(kind: "material", name: layer.name, index: li)
            asset.add(materialID, name: layer.name, .material(MaterialAsset(
                shading: .pbr, baseColor: Vec4(1, 1, 1, opacity), texture: texture, filter: nearest ? .nearest : .linear,
                mipFilter: .none, addressMode: .clampToEdge, emissive: 1, metallic: 0, roughness: 1,
                alphaMode: opacity < 1 ? .blend : .mask, alphaCutoff: 0.5, doubleSided: true)))
            let material = context.reference(materialID)
            // Animated tiles (with every frame in the tile set) get a node of their own per layer:
            // one mesh per frame, swapped by the node's TilemapMotion. The rest draw in chunks.
            var animated: [Int: TilemapAnimation] = [:]
            for tile in Set(layer.data.lazy.map { TileCell(encoded: $0) }.filter { !$0.isEmpty }.map(\.tile)) {
                if let animation = map.tileset.tile(tile)?.animation, animation.frames.count > 1,
                   animation.frames.allSatisfy(built.layout.contains) { animated[tile] = animation }
            }
            var chunks: [PrefabNode] = []
            let counts = map.chunkCounts
            for cy in 0..<counts.y {
                for cx in 0..<counts.x {
                    guard let geometry = map.chunkMesh(layer: li, cx: cx, cy: cy, layout: built.layout, skipping: Set(animated.keys)) else { continue }
                    let label = "\(layer.name) \(cx)_\(cy)"
                    let meshID = namer.id(kind: "mesh", name: label, index: meshIndex)
                    meshIndex += 1
                    asset.add(meshID, name: label, .mesh(geometry))
                    chunks.append(PrefabNode(name: "chunk \(cx)_\(cy)", mesh: context.reference(meshID), material: material))
                }
            }
            for (tile, animation) in animated.sorted(by: { $0.key < $1.key }) {
                // The painted tile shows until the animation runs (as in the chunks before).
                var meshes: [Int: AssetReference] = [:]
                for frame in [tile] + animation.frames where meshes[frame] == nil {
                    guard let geometry = map.tileMesh(layer: li, tile: tile, frame: frame, layout: built.layout) else { continue }
                    let label = "\(layer.name) tile \(tile) frame \(frame)"
                    let meshID = namer.id(kind: "mesh", name: label, index: meshIndex)
                    meshIndex += 1
                    asset.add(meshID, name: label, .mesh(geometry))
                    meshes[frame] = context.reference(meshID)
                }
                guard let painted = meshes[tile] else { continue }
                let steps = animation.frames.compactMap { meshes[$0].map { MeshHandle($0) } }
                chunks.append(PrefabNode(name: "tile \(tile)", mesh: painted, material: material,
                                         tilemapMotion: TilemapMotion(animation: animation, meshes: steps)))
            }
            let position = Vec3(0, 0, map.order(ofLayer: li) * 0.01)
            children.append(PrefabNode(name: layer.name, transform: Transform(position: position), children: chunks,
                                       tilemapMotion: layer.parallax == Vec2(1, 1) ? nil : TilemapMotion(parallax: layer.parallax, origin: position)))
        }

        let shapes = map.collisionShapes()
        if !shapes.isEmpty {
            children.append(PrefabNode(name: "Collision", children: shapes.map {
                PrefabNode(name: $0.name, transform: $0.transform(), collider2D: $0.collider)
            }))
        }
        if !map.objects.isEmpty {
            children.append(PrefabNode(name: "Objects", children: map.objects.map { object in
                let trigger = object.trigger && object.size.x > 0 && object.size.y > 0
                return PrefabNode(name: object.name, transform: Transform(position: Vec3(object.position.x, object.position.y, 0)),
                                  collider2D: trigger ? Collider2D(.box(halfExtents: object.size / 2), isTrigger: true) : nil)
            }))
        }
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: children)])))
        asset.main = prefab
        return asset
    }

    public static func normalized(_ value: String) -> String {
        let value = value.trimmingCharacters(in: .whitespaces)
        return value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
    }

    /// The path `path` (relative to `Assets/`) as seen from the importing file's folder.
    private static func relative(_ path: String, from assetPath: String) -> String {
        let depth = assetPath.split(separator: "/").count - 1
        return String(repeating: "../", count: depth) + path
    }

    /// A `.sprite` tile set, decoded (and recorded as a dependency, so editing it reimports the map).
    private static func sprite(_ value: String, _ context: inout ImportContext) -> PixelSprite? {
        let path = normalized(value)
        guard context.assetsByPath[path] != nil,
              let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)) else { return nil }
        return try? AssetJSON.decoder().decode(PixelSprite.self, from: data)
    }

    /// An image of the tile set, decoded (and recorded as a dependency, so editing it reimports the map).
    private static func image(_ value: String, _ context: inout ImportContext) -> Image? {
        let path = normalized(value)
        guard context.assetsByPath[path] != nil,
              let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)) else { return nil }
        if case .rgba8(let image)? = try? ImageDecoder.decodeAny(data) { return image }
        return nil
    }
}

extension Tilemap {
    /// The quads of layer `layer`'s chunk (`cx`, `cy`) in map space (bottom-left corner at the
    /// origin, facing +z), textured from the tile set; nil when it has no tiles. Tiles in
    /// `skipping` are left out (the importer gives animated tiles meshes of their own).
    public func chunkMesh(layer: Int, cx: Int, cy: Int, layout: TilesetLayout, skipping: Set<Int> = []) -> MeshGeometry? {
        guard layers.indices.contains(layer) else { return nil }
        return cellsMesh(layer: layer, xs: (cx * chunk)..<min((cx + 1) * chunk, cols), ys: (cy * chunk)..<min((cy + 1) * chunk, rowCount),
                         layout: layout) { skipping.contains($0) ? nil : $0 }
    }

    /// Every cell of layer `layer` holding tile `tile`, drawn with tile set picture `frame` (one
    /// frame of the tile's animation); nil when the layer has none.
    public func tileMesh(layer: Int, tile: Int, frame: Int, layout: TilesetLayout) -> MeshGeometry? {
        guard layers.indices.contains(layer) else { return nil }
        return cellsMesh(layer: layer, xs: 0..<cols, ys: 0..<rowCount, layout: layout) { $0 == tile ? frame : nil }
    }

    /// The quads of the cells in `xs` x `ys` of a layer; `picture` maps a cell's tile to the tile
    /// set picture it draws (nil: leave the cell out).
    private func cellsMesh(layer: Int, xs: Range<Int>, ys: Range<Int>, layout: TilesetLayout, picture: (Int) -> Int?) -> MeshGeometry? {
        var vertices: [MeshVertex] = []
        var indices: [UInt32] = []
        let size = cellSize
        let corners = [Vec2(0, 0), Vec2(1, 0), Vec2(1, 1), Vec2(0, 1)]
        for y in ys {
            for x in xs {
                let cell = self.cell(layer: layer, x: x, y: y)
                guard !cell.isEmpty, let tile = picture(cell.tile), layout.contains(tile) else { continue }
                let uv = layout.uv(tile, inset: 0.01)
                let origin = cellRect(x: x, y: y).min
                let base = UInt32(vertices.count)
                for c in corners {
                    // The tile's corner c (y up) lands at place(c) in the cell; v grows downward in the image.
                    let p = cell.place(c)
                    let texcoord = Vec2(c.x == 0 ? uv.min.x : uv.max.x, c.y == 0 ? uv.max.y : uv.min.y)
                    vertices.append(MeshVertex(position: Vec3(origin.x + p.x * size.x, origin.y + p.y * size.y, 0), normal: Vec3(0, 0, 1),
                                               uv: texcoord, tangent: Vec4(1, 0, 0, 1)))
                }
                // Mirroring reverses the winding; keep the front facing +z.
                if cell.flipX != cell.flipY {
                    indices.append(contentsOf: [base, base + 2, base + 1, base, base + 3, base + 2])
                } else {
                    indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
                }
            }
        }
        return indices.isEmpty ? nil : MeshGeometry(vertices: vertices, indices: indices)
    }
}

// MARK: - Database access

/// Game-code copies of `.tilemap` files by the revision they were read at.
@MainActor private var tilemapCache: [ObjectIdentifier: [AssetID: (revision: Int, map: Tilemap?)]] = [:]

extension AssetDatabase {
    /// Writes `map` to a new `.tilemap` file at `path` and imports it. Returns its id.
    @discardableResult
    public func createTilemap(_ map: Tilemap, at path: String) throws -> AssetID {
        let path = try Self.validated(path)
        let url = project.url(forAssetPath: path)
        if FileManager.default.fileExists(atPath: url.path) { throw AssetFileError.exists(path) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try map.fileData().write(to: url, options: .engineAtomic)
        refresh()
        guard let id = id(forPath: path) else { throw AssetError.noSuchAsset(path) }
        return id
    }

    /// The contents of the `.tilemap` asset `id` as written (nil if it isn't one or can't be read).
    public func tilemapContents(of id: AssetID) -> Tilemap? {
        guard record(id)?.importer == TilemapImporter().name, let data = try? fileData(of: id) else { return nil }
        return try? AssetJSON.decoder().decode(Tilemap.self, from: data)
    }

    /// Overwrites the `.tilemap` asset `id` with `map` and reimports it, so placed copies update.
    /// Returns the import's warnings and errors about it.
    @discardableResult
    public func writeTilemap(_ map: Tilemap, to id: AssetID) throws -> [String] {
        guard let path = path(of: id) else { throw AssetError.noSuchAsset(id.description) }
        try map.fileData().write(to: project.url(forAssetPath: path), options: .engineAtomic)
        let report = refresh()
        return report.warnings.filter { $0.hasPrefix(path + ": ") }.map { String($0.dropFirst(path.count + 2)) }
            + report.errors.filter { $0.path == path }.map { "import failed: \($0.message)" }
    }

    /// The tilemap `id` for game code (layers, tile data, objects), normalized. Cached until the
    /// file is reimported (hot reload while playing), so call this where you need it instead of
    /// keeping the result. nil when `id` isn't a readable `.tilemap`.
    public func tilemap(_ id: AssetID) -> Tilemap? {
        guard record(id)?.importer == TilemapImporter().name else { return nil }
        if pack == nil { _ = asset(id) }  // imports it if out of date, which bumps the revision
        let revision = pack == nil ? self.revision(of: id) : 0
        let key = ObjectIdentifier(self)
        if let cached = tilemapCache[key]?[id], cached.revision == revision { return cached.map }
        var map = tilemapContents(of: id)
        map?.normalize()
        if let sprite = map.flatMap({ tilesetSprite(of: $0) }) { map = map?.addingAnimations(Tilemap.spriteTagAnimations(sprite)) }
        tilemapCache[key, default: [:]][id] = (revision, map)
        return map
    }

    /// The tilemap at `path` (relative to `Assets/`; a leading `Assets/` is allowed).
    public func tilemap(path: String) -> Tilemap? {
        id(forPath: TilemapImporter.normalized(path)).flatMap { tilemap($0) }
    }

    /// The imported tile set texture of the tilemap `id` and where each tile sits in it.
    public func tileset(of id: AssetID) -> (image: Image, layout: TilesetLayout)? {
        guard let map = tilemap(id), let texture = texture(AssetReference(id, subAsset: "texture/tileset")),
              case .rgba8(let image) = texture.pixels else { return nil }
        return (image, map.tilesetLayout(imageWidth: image.width, imageHeight: image.height, tileCount: tilesetSprite(of: map)?.frames.count))
    }

    /// The Pixel Sprite a map's tile set comes from (nil unless its source is a readable `.sprite`).
    public func tilesetSprite(of map: Tilemap) -> PixelSprite? {
        guard case .sprite(let path) = map.tileset.source, let id = id(forPath: TilemapImporter.normalized(path)) else { return nil }
        return pixelSprite(of: id)
    }
}
