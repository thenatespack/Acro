import Foundation
import EngineAudio
import EngineCore
import EngineGraphics
import EnginePhysics
import EngineScene

// The mesh build importer's leaf looks: a part with a leaf look (foliage, or a ribbon or plane
// whose `look` names one, MeshBuildLeafLooks.swift) gets an alpha-cutout, double-sided material
// with the look's albedo, normal and ORM textures, added once per look to the import.

extension MeshBuildImporter {
    /// A leaf look's textures as added to the import.
    struct LeafMaterialTextures {
        var look: MeshBuildLeafLook
        var albedo: AssetReference
        var normal: AssetReference
        var orm: AssetReference
        var averageColor: Vec3
    }

    /// The leaf textures added to one import so far (one set per leaf look).
    struct LeafTextureRefs {
        private var made: [MeshBuildLeafLook: LeafMaterialTextures] = [:]

        mutating func references(_ look: MeshBuildLeafLook, _ asset: inout ImportedAsset, _ namer: inout SubAssetNamer,
                                 _ context: inout ImportContext) -> LeafMaterialTextures {
            if let hit = made[look] { return hit }
            let textures = MeshBuildLeafTextures.textures(look)
            func add(_ suffix: String, _ image: Image, sRGB: Bool) -> AssetReference {
                let id = namer.id(kind: "texture", name: "leaves \(look.rawValue) \(suffix)", index: 0)
                asset.add(id, name: "leaves \(look.rawValue) \(suffix)", .texture(TextureAsset(image: image, isSRGB: sRGB)))
                return context.reference(id)
            }
            let refs = LeafMaterialTextures(look: look, albedo: add("albedo", textures.albedo, sRGB: true),
                                            normal: add("normal", textures.normal, sRGB: false),
                                            orm: add("orm", textures.orm, sRGB: false), averageColor: textures.averageColor)
            made[look] = refs
            return refs
        }
    }

    /// How much light leaf materials let through (`MaterialAsset.translucency`).
    static let leafTranslucency: Float = 0.5

    /// The material of a part with a leaf look: alpha-cutout at the look's cutoff, double-sided,
    /// the look's textures, its color the part's `color` over the look's average (so `color` sets
    /// the average; the default color keeps the look's own). A `texture` replaces the albedo (its
    /// alpha cuts out); `roughness` (when not the default 0.5) sets the average.
    static func leafMaterial(for part: MeshBuildPart, texture: AssetReference?, leaf: LeafMaterialTextures) -> MaterialAsset {
        var material = material(for: part, texture: texture)
        let defaults = MeshBuildPart()
        if texture == nil {
            var tint = Vec3(1, 1, 1)
            if part.color != defaults.color {
                let c = MeshBuildColor.linear(fromSRGB: part.color)
                tint = Vec3(min(c.x / max(leaf.averageColor.x, 1e-3), 6), min(c.y / max(leaf.averageColor.y, 1e-3), 6),
                            min(c.z / max(leaf.averageColor.z, 1e-3), 6))
            }
            material.texture = leaf.albedo
            material.baseColor = Vec4(tint.x, tint.y, tint.z, 1)
        } else {
            material.baseColor.w = 1
        }
        material.uvScale = Vec2(1, 1)
        material.metallicRoughnessTexture = leaf.orm
        material.metallic = 1  // the ORM's metalness is 0
        material.roughness = part.roughness == defaults.roughness ? 1
            : min(max(part.roughness, 0) / max(leaf.look.roughness, 0.02), 4)
        material.normalTexture = leaf.normal
        material.normalScale = 1
        material.occlusionTexture = leaf.orm
        material.occlusionStrength = 1
        material.alphaMode = .mask
        material.alphaCutoff = leaf.look.alphaCutoff
        material.doubleSided = true
        // Sunlight through the leaves, and foliage cards keep their bent normals on both sides.
        material.translucency = leafTranslucency
        return material
    }
}
