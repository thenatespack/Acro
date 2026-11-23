import Foundation
import EngineCore
import EngineGraphics
import EngineScene
import EngineAssets

/// Imports `.groom` files (a `GroomBuild` as JSON, see GroomBuild.swift):
/// - `material/fur`: the fur material a `GroomRenderer` names (`GroomRenderer.material(ofGroom:)`):
///   a `MaterialAsset` whose `fur` carries the groom and its mask and flow maps (downsampled, so
///   fur meshes can be built from them anywhere), with the full mask texture in the
///   metallic-roughness slot (the fragment shader cuts strands by it);
/// - `prefab/<file name>`: a preview, the groom on its `previewMesh` (a sphere by default, or the
///   parts of a `.meshbuild`, masked by `mask.parts`), so a `.groom` can be placed to look at;
/// - `mesh/preview` and `material/preview` for a built-in preview shape.
/// Problems (`GroomCheck`, missing textures) are warnings.
public struct GroomImporter: AssetImporter {
    public init() {}

    public var name: String { BuiltInImporterName.groom }
    public var fileExtensions: [String] { ["groom"] }
    public var version: Int { 1 }

    public func importAsset(_ context: inout ImportContext, settings: NoImportSettings) throws -> ImportedAsset {
        let build: GroomBuild
        do { build = try AssetJSON.decoder().decode(GroomBuild.self, from: context.data()) } catch {
            throw AssetError.unreadable("not a groom: \(error)")
        }
        for problem in GroomCheck.problems(build) { context.warn(problem) }
        let stem = ((context.assetPath as NSString).lastPathComponent as NSString).deletingPathExtension
        var asset = ImportedAsset()
        var namer = SubAssetNamer()

        // The fur material.
        let mask = Self.texture(build.mask.texture, label: "mask.texture", &context)
        let flow = Self.texture(build.flowTexture, label: "flowTexture", &context)
        let root = build.linearRootColor
        var material = MaterialAsset(shading: .pbr, baseColor: Vec4(root.x, root.y, root.z, 1), metallic: 0, roughness: 0.8,
                                     doubleSided: build.drawnStyle == .cards)
        material.metallicRoughnessTexture = mask?.reference
        material.fur = MaterialFur(groom: build, maskImage: mask?.image.map { GroomImage(downsampling: $0) },
                                   flowImage: flow?.image.map { GroomImage(downsampling: $0) })
        if let image = mask?.image, !image.pixels.isEmpty {
            var lit = false
            var i = 0
            while i < image.pixels.count {
                let r = image.pixels[i]
                if build.mask.invert ? r < 250 : r > 5 { lit = true; break }
                i += 4
            }
            if !lit { context.warn("mask.texture '\(build.mask.texture)' is black everywhere: the mask covers nothing, so no fur grows") }
        }
        let materialID = namer.id(kind: "material", name: "fur", index: 0)
        precondition(materialID == GroomRenderer.furSubAsset)
        asset.add(materialID, name: "fur", .material(material))
        let groom = GroomRenderer(groom: MaterialHandle(context.reference(materialID)))

        // The preview prefab.
        var nodes: [PrefabNode] = []
        let preview = build.previewMesh.trimmingCharacters(in: .whitespaces)
        if preview.lowercased().hasSuffix(".meshbuild") || preview.hasPrefix(AssetReference.scheme) {
            if let parts = TerrainImporter.prop(TerrainScatter(name: "previewMesh", asset: preview), &context) {
                let masked = build.mask.parts.isEmpty ? nil : Set(build.mask.parts)
                if let masked, !parts.contains(where: { masked.contains($0.name) }) {
                    context.warn("mask.parts names no part of '\(preview)' (\(parts.map(\.name).joined(separator: ", "))): the mask covers nothing")
                }
                nodes = parts.map { part in
                    var node = PrefabNode(name: part.name, transform: part.transform, mesh: part.mesh, material: part.material)
                    if masked?.contains(part.name) ?? true { node.groom = groom }
                    return node
                }
            }
        }
        if nodes.isEmpty {
            let geometry = Self.previewGeometry(preview)
            if geometry == nil, !preview.isEmpty, preview.lowercased() != "sphere" {
                context.warn("previewMesh '\(preview)' isn't sphere, cube, capsule, plane or a .meshbuild; the preview uses a sphere")
            }
            let meshID = namer.id(kind: "mesh", name: "preview", index: 0)
            asset.add(meshID, name: "preview", .mesh(geometry ?? .sphere(radius: 0.5, segments: 48, rings: 24)))
            let skinID = namer.id(kind: "material", name: "preview", index: 0)
            let skin = root * 0.6
            asset.add(skinID, name: "preview", .material(MaterialAsset(shading: .pbr, baseColor: Vec4(skin.x, skin.y, skin.z, 1), roughness: 0.9)))
            var node = PrefabNode(name: "Preview", transform: Transform(position: Vec3(0, 0.5, 0)), mesh: context.reference(meshID),
                                  material: context.reference(skinID))
            node.groom = groom
            nodes = [node]
        }
        let prefab = namer.id(kind: "prefab", name: stem, index: 0)
        asset.add(prefab, name: stem, .prefab(PrefabAsset(roots: [PrefabNode(name: stem, children: nodes)])))
        asset.main = prefab
        return asset
    }

    /// A built-in preview shape by name (nil for anything else).
    static func previewGeometry(_ name: String) -> MeshGeometry? {
        switch name.lowercased() {
        case "", "sphere": .sphere(radius: 0.5, segments: 48, rings: 24)
        case "cube", "box": .cube()
        case "capsule": MeshGeometry.builtin(.capsule)
        case "plane", "ground": .plane(size: 2, segments: 16)
        default: nil
        }
    }

    /// The texture `value` names (path under `Assets/` or "asset:<id>"), decoded, and its reference
    /// for a material slot; nil for "" (warned when it can't be found or read).
    static func texture(_ value: String, label: String, _ context: inout ImportContext) -> (reference: AssetReference?, image: Image?)? {
        let value = value.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }
        var path = value.hasPrefix("Assets/") ? String(value.dropFirst("Assets/".count)) : value
        if value.hasPrefix(AssetReference.scheme), let reference = AssetReference(value) {
            guard let found = context.assetsByPath.first(where: { $0.value == reference.asset })?.key else {
                context.warn("\(label): no asset '\(value)'")
                return nil
            }
            path = found
        }
        guard let id = context.assetsByPath[path] else {
            context.warn("\(label): no texture '\(value)'")
            return nil
        }
        let reference = AssetReference(id, subAsset: "texture")
        let depth = context.assetPath.split(separator: "/").count - 1
        guard let data = try? context.readDependency(relativePath: String(repeating: "../", count: depth) + path) else {
            context.warn("\(label): can't read '\(value)'")
            return (reference, nil)
        }
        if path.lowercased().hasSuffix(".proctex") {
            guard let texture = try? AssetJSON.decoder().decode(ProceduralTexture.self, from: data) else {
                context.warn("\(label): '\(value)' isn't a procedural texture")
                return nil
            }
            return (reference, texture.render())
        }
        if case .rgba8(let image)? = try? ImageDecoder.decodeAny(data) { return (reference, image) }
        context.warn("\(label): can't read '\(value)' as an 8-bit image")
        return (reference, nil)
    }
}
