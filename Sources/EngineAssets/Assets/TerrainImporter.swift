import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

/// Imports `.terrain` files (a `Terrain` as JSON): `mesh/chunk <x>_<z>` per chunk (plus
/// `… lod<n>` for the extra detail levels), `material/terrain` (per-pixel layer blending, see
/// `TerrainSplat`, with `texture/layers`, `texture/layer normals`, `texture/splat 0` and `splat 1`),
/// `material/terrain baked` with `texture/albedo` (the painted layers baked together, drawn on low
/// quality through each chunk's `MeshLOD`) and the main `prefab/<file name>`: a root named after the file with one node
/// per chunk (mesh, material and a triangle-mesh `Collider`) and a `Scatter` node holding the
/// props of every scatter rule. Props sharing a mesh and material draw as one instanced batch.
public struct TerrainImporter: AssetImporter {
    public init() {}

    public var name: String { "terrain" }
    public var fileExtensions: [String] { ["terrain"] }
    public var version: Int { 3 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        var terrain: Terrain
        do { terrain = try AssetJSON.decoder().decode(Terrain.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a terrain: \(error)")
        }
        terrain.resolution = terrain.res
        if !terrain.heightData.isEmpty && terrain.heightData.count != terrain.res * terrain.res {
            context.warn("height data has \(terrain.heightData.count) samples but resolution \(terrain.res) needs \(terrain.res * terrain.res); padded")
        }
        terrain.normalizeData()
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()

        // The layers' textures, baked into one albedo (drawn on low quality, or always with more
        // layers than the per-pixel shader blends) and packed for per-pixel blending.
        var images: [Image?] = [], normals: [Image?] = []
        for layer in terrain.layers {
            images.append(layer.texture.isEmpty ? nil : Self.image(layer.texture, layer: layer.name, &context))
            normals.append(layer.normalMap.isEmpty ? nil : Self.image(layer.normalMap, layer: layer.name, &context))
        }
        let textureID = namer.id(kind: "texture", name: "albedo", index: 0)
        asset.add(textureID, name: "albedo", .texture(TextureAsset(image: terrain.bakeAlbedo(images: images))))
        let baked = MaterialAsset(shading: .pbr, baseColor: Vec4(1, 1, 1, 1), texture: context.reference(textureID), metallic: 0,
                                  roughness: 0.95)
        let perPixel = terrain.layers.count <= TerrainSplat.maxLayers
        if !perPixel {
            context.warn("\(terrain.layers.count) layers: only \(TerrainSplat.maxLayers) blend per pixel, so the layers are baked into one texture")
        }
        let materialID = namer.id(kind: "material", name: "terrain", index: 0)
        var lowQuality: MaterialHandle?
        if perPixel {
            let layers = terrain.layers.isEmpty ? [TerrainLayer()] : terrain.layers
            let cell = TerrainSplat.cellSize(for: images + normals)
            let atlasID = namer.id(kind: "texture", name: "layers", index: 1)
            asset.add(atlasID, name: "layers", .texture(TextureAsset(image: TerrainSplat.atlas(images: images, colors: layers.map(\.color),
                                                                                                cellSize: cell))))
            var normalID: SubAssetID?
            if normals.contains(where: { $0 != nil }) {
                let id = namer.id(kind: "texture", name: "layer normals", index: 2)
                let flat = Vec3(0.5, 0.5, 1)
                asset.add(id, name: "layer normals", .texture(TextureAsset(
                    image: TerrainSplat.atlas(images: normals, colors: layers.map { _ in flat }, cellSize: cell), isSRGB: false)))
                normalID = id
            }
            let splatA = namer.id(kind: "texture", name: "splat 0", index: 3)
            asset.add(splatA, name: "splat 0", .texture(TextureAsset(image: terrain.splatImage(firstLayer: 0), isSRGB: false,
                                                                     generatesMipmaps: false)))
            var splatB: SubAssetID?
            if layers.count > 4 {
                let id = namer.id(kind: "texture", name: "splat 1", index: 4)
                asset.add(id, name: "splat 1", .texture(TextureAsset(image: terrain.splatImage(firstLayer: 4), isSRGB: false,
                                                                     generatesMipmaps: false)))
                splatB = id
            }
            var splat = baked
            splat.texture = context.reference(atlasID)
            splat.metallicRoughnessTexture = context.reference(splatA)
            splat.normalTexture = normalID.map { context.reference($0) }
            splat.emissiveTexture = splatB.map { context.reference($0) }
            splat.terrain = TerrainSplat(tileSizes: layers.map(\.tileSize), normalLayers: normals.map { $0 != nil }, size: terrain.size,
                                         resolution: terrain.res, cellSize: cell)
            asset.add(materialID, name: "terrain", .material(splat))
            let bakedID = namer.id(kind: "material", name: "terrain baked", index: 1)
            asset.add(bakedID, name: "terrain baked", .material(baked))
            lowQuality = MaterialHandle(context.reference(bakedID))
        } else {
            asset.add(materialID, name: "terrain", .material(baked))
        }
        let material = context.reference(materialID)

        var chunks: [PrefabNode] = []
        let counts = terrain.chunkCounts
        var index = 0
        for cz in 0..<counts.z {
            for cx in 0..<counts.x {
                let label = "chunk \(cx)_\(cz)"
                let meshID = namer.id(kind: "mesh", name: label, index: index)
                // With several levels every level hangs skirts, so neighbors at different levels don't crack.
                let skirt = terrain.skirtDepth(cx, cz)
                asset.add(meshID, name: label, .mesh(terrain.chunkMesh(cx, cz, skirt: skirt)))
                var levels: [MeshHandle] = []
                for lod in 1..<max(min(terrain.lods, 4), 1) {
                    let lodLabel = "\(label) lod\(lod)"
                    let lodID = namer.id(kind: "mesh", name: lodLabel, index: index)
                    asset.add(lodID, name: lodLabel, .mesh(terrain.chunkMesh(cx, cz, lod: lod, skirt: skirt)))
                    levels.append(MeshHandle(context.reference(lodID)))
                }
                let lod = levels.isEmpty && lowQuality == nil ? nil
                    : MeshLOD(meshes: levels, distances: levels.isEmpty ? [] : terrain.lodDistances, lowQualityMaterial: lowQuality)
                chunks.append(PrefabNode(name: label, mesh: context.reference(meshID), material: material,
                                         collider: terrain.collider ? terrain.chunkCollider(cx, cz) : nil, lod: lod))
                index += 1
            }
        }

        var scatterNodes: [PrefabNode] = []
        var budget = Terrain.maxScatterInstances
        for rule in terrain.scatter {
            guard let prop = Self.prop(rule, &context) else { continue }
            if !rule.layer.isEmpty && terrain.layerIndex(named: rule.layer) == nil {
                context.warn("scatter '\(rule.name)': no layer named '\(rule.layer)'")
            }
            var instances = terrain.instances(of: rule)
            if instances.count > budget {
                context.warn("scatter '\(rule.name)': more than \(Terrain.maxScatterInstances) props in total; the rest are dropped")
                instances = Array(instances.prefix(budget))
            }
            budget -= instances.count
            let single = prop.count == 1 && prop[0].transform == Transform()
            let nodes = instances.enumerated().map { i, instance -> PrefabNode in
                let transform = Transform(position: instance.position, rotation: instance.rotation,
                                          scale: Vec3(repeating: instance.scale))
                if single { return PrefabNode(name: "\(rule.name) \(i)", transform: transform, mesh: prop[0].mesh, material: prop[0].material) }
                return PrefabNode(name: "\(rule.name) \(i)", transform: transform, children: prop.map {
                    PrefabNode(name: $0.name, transform: $0.transform, mesh: $0.mesh, material: $0.material)
                })
            }
            scatterNodes.append(PrefabNode(name: rule.name, children: nodes))
        }
        var children = chunks
        if !scatterNodes.isEmpty { children.append(PrefabNode(name: "Scatter", children: scatterNodes)) }
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: children)])))
        asset.main = prefab
        return asset
    }

    /// The path `path` (relative to `Assets/`) as seen from the importing file's folder.
    private static func relative(_ path: String, from assetPath: String) -> String {
        let depth = assetPath.split(separator: "/").count - 1
        return String(repeating: "../", count: depth) + path
    }

    private static func normalized(_ value: String) -> String {
        let value = value.trimmingCharacters(in: .whitespaces)
        return value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
    }

    /// A layer's texture as pixels: a `.proctex` is rendered, an image decoded.
    private static func image(_ value: String, layer: String, _ context: inout ImportContext) -> Image? {
        let path = normalized(value)
        guard context.assetsByPath[path] != nil,
              let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)) else {
            context.warn("layer '\(layer)': no texture file '\(value)'")
            return nil
        }
        if path.lowercased().hasSuffix(".proctex") {
            guard let texture = try? AssetJSON.decoder().decode(ProceduralTexture.self, from: data) else {
                context.warn("layer '\(layer)': '\(value)' isn't a procedural texture")
                return nil
            }
            return texture.render()
        }
        if case .rgba8(let image)? = try? ImageDecoder.decodeAny(data) { return image }
        context.warn("layer '\(layer)': can't read '\(value)' as an 8-bit image")
        return nil
    }

    /// One drawable piece of a scattered prop.
    struct PropPart {
        var name: String
        var transform: Transform
        var mesh: AssetReference
        var material: AssetReference?
    }

    /// The pieces `rule.asset` names: a mesh reference (one piece), or every part of a `.meshbuild`.
    static func prop(_ rule: TerrainScatter, _ context: inout ImportContext) -> [PropPart]? {
        let value = rule.asset.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else {
            context.warn("scatter '\(rule.name)' has no asset")
            return nil
        }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            let mesh = reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "mesh") : reference
            return [PropPart(name: rule.name, transform: Transform(), mesh: mesh, material: materialReference(rule.material, &context))]
        }
        let path = normalized(value)
        guard let id = context.assetsByPath[path] else {
            context.warn("scatter '\(rule.name)': no asset '\(value)'")
            return nil
        }
        guard path.lowercased().hasSuffix(".meshbuild"),
              let data = try? context.readDependency(relativePath: relative(path, from: context.assetPath)),
              let build = try? AssetJSON.decoder().decode(MeshBuild.self, from: data) else {
            context.warn("scatter '\(rule.name)': '\(value)' isn't a mesh build; use a .meshbuild or an asset:<id>#mesh/<name> reference")
            return nil
        }
        // The sub-asset names the mesh build importer gave its parts.
        var meshNamer = SubAssetNamer(), materialNamer = SubAssetNamer()
        var firstIndex: [String: Int] = [:]
        for (i, part) in build.parts.enumerated() where firstIndex[part.name] == nil { firstIndex[part.name] = i }
        func local(_ i: Int, _ depth: Int = 0) -> Transform {
            let part = build.parts[i]
            guard depth < build.parts.count, !part.parent.isEmpty, let p = firstIndex[part.parent], p != i else { return part.transform }
            let parent = local(p, depth + 1)
            return Transform(position: parent.position + parent.rotation * part.position, rotation: parent.rotation * part.transform.rotation)
        }
        var pieces: [PropPart] = []
        for (i, part) in build.parts.enumerated() {
            guard let geometry = part.geometry(), !geometry.indices.isEmpty else { continue }
            let meshID = meshNamer.id(kind: "mesh", name: part.name, index: i)
            var material: AssetReference?
            if part.material.isEmpty {
                material = AssetReference(id, subAsset: materialNamer.id(kind: "material", name: part.name, index: i))
            } else {
                material = materialReference(part.material, &context)
            }
            pieces.append(PropPart(name: part.name, transform: local(i), mesh: AssetReference(id, subAsset: meshID), material: material))
        }
        if pieces.isEmpty { context.warn("scatter '\(rule.name)': '\(value)' has no shapes") }
        return pieces.isEmpty ? nil : pieces
    }

    private static func materialReference(_ value: String, _ context: inout ImportContext) -> AssetReference? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            return reference.subAsset == nil ? AssetReference(reference.asset, subAsset: "material") : reference
        }
        if let id = context.assetsByPath[normalized(value)] { return AssetReference(id, subAsset: "material") }
        context.warn("no material asset '\(value)'")
        return nil
    }
}
