import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// The mesh build importer's looks and baked occlusion: look parts get look texture coordinates
// (MeshBuildLookMapping.swift) and a material with the look's textures (MeshBuildLooks.swift),
// added once per look and wear level to the import; with occlusion on, every mesh is tessellated
// and gets its occlusion in the tangents' w (MeshBuildAO.swift); worn look parts get edge
// coordinates in their tangents and `EdgeWear` in their material (MeshBuildEdgeWear.swift).

extension MeshBuildImporter {
    /// A look's textures as added to the import.
    struct LookMaterialTextures {
        var albedo: AssetReference
        var normal: AssetReference
        var orm: AssetReference
        var averageColor: Vec3
        var averageRoughness: Float
    }

    /// The look textures added to one import so far (one set per look and wear level).
    struct LookTextureRefs {
        private var made: [String: LookMaterialTextures] = [:]

        mutating func references(_ look: MeshBuildLook, wear: Float?, _ asset: inout ImportedAsset, _ namer: inout SubAssetNamer,
                                 _ context: inout ImportContext) -> LookMaterialTextures {
            let level = MeshBuildLookTextures.wearLevel(wear)
            let key = look.rawValue + (level > 0 ? " wear \(level)" : "")
            if let hit = made[key] { return hit }
            let textures = MeshBuildLookTextures.textures(look, wearLevel: level)
            func add(_ suffix: String, _ image: Image, sRGB: Bool) -> AssetReference {
                let id = namer.id(kind: "texture", name: "look \(key) \(suffix)", index: 0)
                asset.add(id, name: "look \(key) \(suffix)", .texture(TextureAsset(image: image, isSRGB: sRGB)))
                return context.reference(id)
            }
            let refs = LookMaterialTextures(albedo: add("albedo", textures.albedo, sRGB: true),
                                            normal: add("normal", textures.normal, sRGB: false),
                                            orm: add("orm", textures.orm, sRGB: false),
                                            averageColor: textures.averageColor, averageRoughness: textures.averageRoughness)
            made[key] = refs
            return refs
        }
    }

    /// The material of a part without a `material` asset, with its look's textures if it has one:
    /// the albedo times twice the part's color (its average color) or the look's own average,
    /// the ORM texture for occlusion, roughness and metalness, the normal map. A `texture`
    /// replaces the look's albedo; `roughness` (when not the default 0.5) sets the average roughness.
    /// `geometry`: the part's mesh, which sizes its edge wear.
    static func material(for part: MeshBuildPart, texture: AssetReference?, look: LookMaterialTextures?,
                         geometry: MeshGeometry? = nil) -> MaterialAsset {
        var material = material(for: part, texture: texture)
        guard let look, let kind = part.resolvedLook else { return material }
        let defaults = MeshBuildPart()
        let opacity = part.opacity == defaults.opacity ? kind.defaultOpacity : min(max(part.opacity, 0), 1)
        let color = part.color == defaults.color ? look.averageColor : MeshBuildColor.linear(fromSRGB: part.color)
        if texture == nil {
            material.texture = look.albedo
            material.baseColor = Vec4(color.x * 2, color.y * 2, color.z * 2, opacity)
        } else {
            material.baseColor.w = opacity
        }
        material.uvScale = Vec2(1, 1)  // look coordinates are already in tiles
        material.metallicRoughnessTexture = look.orm
        material.metallic = 1
        material.roughness = part.roughness == defaults.roughness ? 1
            : min(max(part.roughness, 0) / max(look.averageRoughness, 0.02), 4)
        material.normalTexture = look.normal
        material.normalScale = 1
        material.occlusionTexture = look.orm
        material.occlusionStrength = 1
        material.alphaMode = opacity < 1 ? .blend : .opaque
        if let geometry, wearsEdges(part) {
            let width = MeshBuildEdgeWear.bandWidth(size: geometry.bounds.halfExtent * 2, wear: part.wear ?? 0, look: kind)
            material.edgeWear = kind.edgeWear(average: color, width: width)
        }
        return material
    }

    /// Whether `part`'s convex edges wear: it has a look whose edges wear, `wear` above 0 and no `material`.
    static func wearsEdges(_ part: MeshBuildPart) -> Bool {
        guard let look = part.resolvedLook, let wear = part.wear, wear.isFinite, wear > 0,
              part.material.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return look.edgeWear(average: Vec3(repeating: 0.5), width: 0.01) != nil
    }

    /// Gives look parts their look texture coordinates and, with `occlusion`, tessellates every
    /// mesh and bakes the model's ambient occlusion into it (`build` is the expanded build,
    /// `geometries` its parts' meshes in their own spaces).
    /// About how many triangles splitting meshes for baked occlusion may bring a model to.
    static let occlusionTriangleBudget = 30_000

    static func finishSurfaces(_ build: MeshBuild, _ geometries: inout [MeshGeometry?], occlusion: Bool, firstIndex: [String: Int]) {
        let parts = build.parts
        let hasLooks = parts.contains { $0.resolvedLook != nil }
        guard occlusion || hasLooks else { return }
        // Each part's rest placement in the model (rotation, translation): parents first.
        var placements = [(Quat, Vec3)?](repeating: nil, count: parts.count)
        func place(_ i: Int, depth: Int) -> (Quat, Vec3) {
            if let p = placements[i] { return p }
            let part = parts[i]
            var parent = (Quat.identity, Vec3.zero)
            if !part.parent.isEmpty, let p = firstIndex[part.parent], p != i, depth < parts.count { parent = place(p, depth: depth + 1) }
            let placed = (parent.0 * Quat(eulerDegrees: part.rotation), parent.0 * part.position + parent.1)
            if depth == 0 || placements[i] == nil { placements[i] = placed }
            return placed
        }
        var lo = Vec3(repeating: .infinity), hi = Vec3(repeating: -.infinity)
        var meshCount = 0
        for i in parts.indices {
            guard let g = geometries[i], !g.indices.isEmpty else { continue }
            meshCount += 1
            let (q, t) = place(i, depth: 0)
            let b = g.bounds
            for corner in 0..<8 {
                let c = b.center + b.halfExtent * Vec3(corner & 1 == 0 ? -1 : 1, corner & 2 == 0 ? -1 : 1, corner & 4 == 0 ? -1 : 1)
                let p = q * c + t
                lo = pointwiseMin(lo, p)
                hi = pointwiseMax(hi, p)
            }
        }
        guard meshCount > 0 else { return }
        let extent = hi - lo
        let scale = MeshBuildAO.Scale(extent: max(extent.x, extent.y, extent.z, 0.01))
        // Splitting for occlusion adds at most about `occlusionTriangleBudget` triangles to the model,
        // shared between its meshes; meshes already over their share (sculpts, deformed parts) stay as they are.
        let budget = max(1500, occlusionTriangleBudget / meshCount)
        for i in parts.indices {
            guard var g = geometries[i], !g.indices.isEmpty else { continue }
            // Foliage cards keep their four corners (splitting them only adds triangles).
            if occlusion && parts[i].shape != .foliage { g = g.tessellated(maxEdge: scale.edge, maxTriangles: budget) }
            if parts[i].resolvedLook != nil && parts[i].material.trimmingCharacters(in: .whitespaces).isEmpty {
                g = parts[i].applyingLookUVs(to: g)
            }
            geometries[i] = g
        }
        guard occlusion else { return }
        let indices = parts.indices.filter { geometries[$0].map { !$0.indices.isEmpty } ?? false }
        let placed = indices.map { i in
            MeshBuildAO.Placed(geometry: geometries[i]!, rotation: placements[i]?.0 ?? .identity,
                               translation: placements[i]?.1 ?? .zero, wear: parts[i].wear ?? 0)
        }
        let baked = MeshBuildAO.bake(placed, scale: scale)
        for (k, i) in indices.enumerated() {
            guard var g = geometries[i] else { continue }
            MeshBuildAO.store(baked[k], in: &g)
            geometries[i] = g
        }
    }

    /// Edge coordinates (MeshBuildEdgeWear.swift) in the meshes of parts whose edges wear.
    static func finishEdgeWear(_ build: MeshBuild, _ geometries: inout [MeshGeometry?]) {
        for (i, part) in build.parts.enumerated() where wearsEdges(part) {
            guard var g = geometries[i], !g.indices.isEmpty, let look = part.resolvedLook else { continue }
            MeshBuildEdgeWear.apply(to: &g, wear: part.wear ?? 0, look: look)
            geometries[i] = g
        }
    }
}
