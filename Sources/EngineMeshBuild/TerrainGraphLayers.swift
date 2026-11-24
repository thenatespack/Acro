#if os(WASI)
import WASIFoundation
#else
import Foundation
#endif
import EngineCore
import EngineScene
import EngineAssets

// Graph material layers: a terrain layer whose `material` is a `.material` file with a node graph
// (the Material Builder's). The graph is evaluated on the GPU by its own shader in a second,
// blended draw over the chunks where the layer is painted:
//
// - The layer's splat weights become a mask texture (`texture/<layer> mask`, R = weight, one
//   texel per height sample). The importer wraps the graph: every UV the graph reads (texture,
//   noise and scroll inputs left unlinked, and `uv` nodes) is remapped from the chunk mesh's
//   0...1 across the terrain to repeats of the layer's `tileSize` meters from the terrain's
//   center (like texture layers), and its opacity output is multiplied by the mask. The result
//   is `material/<layer> layer`, alpha-blended, its textures resolved like a `.material` file's.
// - Each chunk where the layer has any weight gets a child "<layer>" drawing the chunk's mesh
//   (and LOD meshes, swapped the same way) with that material, lifted a little along the normal
//   (2 cm at full detail, doubling per level) so it doesn't fight the ground's depth.
// - The ground leaves graph layers out of its per-pixel blend (the other layers' weights are
//   renormalized), so where a graph layer has weight w the result is ground x (1 - w) + graph x w.
//   The baked albedo (low quality) uses the layer's flat color under the overlay.
//
// The graph keeps its own lighting, normal output, time animation and textures, up to the
// five texture slots less the mask's one.
extension TerrainImporter {
    /// Meters the overlay of LOD level `lod` is lifted along the normal.
    static func overlayLift(lod: Int) -> Float { 0.02 * Float(1 << lod) }

    /// The graph material layers' overlay materials, by layer index (warnings for unusable ones).
    static func graphLayerMaterials(_ terrain: Terrain, namer: inout SubAssetNamer, asset: inout ImportedAsset,
                                    _ context: inout ImportContext) -> [Int: AssetReference] {
        var result: [Int: AssetReference] = [:]
        for (i, layer) in terrain.layers.enumerated() where !layer.material.isEmpty {
            guard var material = graphMaterial(layer.material, layer: layer.name, &context) else { continue }
            let maskID = namer.id(kind: "texture", name: "\(layer.name) mask", index: 10 + i)
            var mask = terrain.splatImage(firstLayer: i)
            for p in stride(from: 0, to: mask.pixels.count, by: 4) { mask.pixels[p + 1] = 0; mask.pixels[p + 2] = 0; mask.pixels[p + 3] = 255 }
            asset.add(maskID, name: "\(layer.name) mask", .texture(TextureAsset(image: mask, isSRGB: false, generatesMipmaps: false)))
            material.graph = layerGraph(material.graph!, terrain: terrain, tileSize: layer.tileSize, mask: context.reference(maskID))
            material.alphaMode = .blend
            MaterialFileImporter.compileGraph(&material, &context)
            if let program = MaterialGraphCompiler.compile(material.graph!).program,
               !program.textures.contains(context.reference(maskID)) {
                context.warn("layer '\(layer.name)': its graph uses every texture slot, so the layer's paint mask doesn't fit; it covers the whole terrain")
            }
            let id = namer.id(kind: "material", name: "\(layer.name) layer", index: 10 + i)
            asset.add(id, name: "\(layer.name) layer", .material(material))
            result[i] = context.reference(id)
        }
        return result
    }

    /// The `.material` file at `path` (under `Assets/`), if it has a graph.
    private static func graphMaterial(_ value: String, layer: String, _ context: inout ImportContext) -> MaterialAsset? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        let path = trimmed.hasPrefix("Assets/") ? String(trimmed.dropFirst("Assets/".count)) : trimmed
        let depth = context.assetPath.split(separator: "/").count - 1
        guard context.assetsByPath[path] != nil,
              let data = try? context.readDependency(relativePath: String(repeating: "../", count: depth) + path) else {
            context.warn("layer '\(layer)': no material file '\(value)'")
            return nil
        }
        guard let material = try? AssetJSON.decoder().decode(MaterialAsset.self, from: data), material.graph != nil else {
            context.warn("layer '\(layer)': '\(value)' isn't a graph material (only materials with a node graph can be layers)")
            return nil
        }
        return material
    }

    /// `graph` with its UVs in repeats of `tileSize` meters from the terrain's center and its
    /// opacity multiplied by the `mask` texture's red channel.
    static func layerGraph(_ graph: MaterialGraph, terrain: Terrain, tileSize: Float, mask: AssetReference) -> MaterialGraph {
        var g = graph
        func number(_ f: Float) -> JSONValue { .double(Double(f)) }
        func pair(_ a: Float, _ b: Float) -> JSONValue { .array([number(a), number(b)]) }
        let tile = max(tileSize, 0.01)
        let repeats = Vec2(terrain.size.x / tile, terrain.size.y / tile)
        let terrainUV = g.uniqueID("terrainUV")
        var added = [MaterialGraphNode(id: terrainUV, type: "uv", fields: ["scale": pair(repeats.x, repeats.y),
                                                                            "offset": pair(-repeats.x / 2, -repeats.y / 2)])]
        for i in g.nodes.indices {
            let node = g.nodes[i]
            if node.type == "uv" {
                // gUV x scale + offset, with gUV the terrain UV: a multiply and an add, under the same id.
                let scaled = g.uniqueID(node.id + "Scaled")
                added.append(MaterialGraphNode(id: scaled, type: "math", fields: ["op": .string("multiply"), "a": .string(terrainUV),
                                                                                   "b": node["scale"] ?? pair(1, 1)]))
                g.nodes[i] = MaterialGraphNode(id: node.id, type: "math", position: node.position,
                                               fields: ["op": .string("add"), "a": .string(scaled), "b": node["offset"] ?? pair(0, 0)])
                continue
            }
            for input in MaterialGraphNodeType.catalog[node.type]?.inputs ?? [] where input.defaultLink == "uv" && node[input.name] == nil {
                g.nodes[i][input.name] = .string(terrainUV)
            }
        }
        let res = Float(max(terrain.res, 2))
        let maskUV = g.uniqueID("terrainMaskUV"), maskNode = g.uniqueID("terrainMask"), opacity = g.uniqueID("terrainOpacity")
        added.append(MaterialGraphNode(id: maskUV, type: "uv", fields: ["scale": pair((res - 1) / res, (res - 1) / res),
                                                                         "offset": pair(0.5 / res, 0.5 / res)]))
        added.append(MaterialGraphNode(id: maskNode, type: "texture", fields: ["texture": .string(mask.description), "uv": .string(maskUV)]))
        added.append(MaterialGraphNode(id: opacity, type: "math", fields: ["op": .string("multiply"), "a": g.output["opacity"] ?? number(1),
                                                                            "b": .string(maskNode + ".x")]))
        g.output["opacity"] = .string(opacity)
        g.nodes += added
        return g
    }

    /// Chunk `(cx, cz)`'s mesh at `lod`, lifted along its normals for a graph layer overlay.
    static func overlayMesh(_ terrain: Terrain, _ cx: Int, _ cz: Int, lod: Int) -> MeshGeometry {
        var mesh = terrain.chunkMesh(cx, cz, lod: lod)
        let lift = overlayLift(lod: lod)
        for i in mesh.vertices.indices { mesh.vertices[i].position += mesh.vertices[i].normal * lift }
        return mesh
    }

    /// Whether layer `layer` has any weight on chunk `(cx, cz)`.
    static func chunkHasWeight(_ terrain: Terrain, layer: Int, _ cx: Int, _ cz: Int) -> Bool {
        let range = terrain.chunkRange(cx, cz)
        for z in range.z { for x in range.x where terrain.weight(layer: layer, x: x, z: z) > 0 { return true } }
        return false
    }
}
